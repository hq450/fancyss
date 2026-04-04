#!/usr/bin/env python3
from __future__ import annotations

import concurrent.futures
import dataclasses
import datetime as dt
import json
import os
import shutil
import ssl
import subprocess
import sys
import tempfile
import threading
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
HISTORICAL_STATS = ROOT / "statistics_20260114174817.txt"
SUBTOOL = Path(__file__).resolve().parents[1] / "tool" / "sub-tool" / "zig-out" / "bin" / "sub-tool"
UA = "AsusWRT|koolcenter|GS7|102_58273_koolcenter|fancyss|mtk|full|3.5.10|curl|v2rayN"
TIMEOUT = 10
MAX_BYTES = 12 * 1024 * 1024
MAX_WORKERS = 12


@dataclasses.dataclass
class HistoricalRow:
    index: int
    url: str
    download_status: str
    parse_status: str
    raw_fields: list[str]


def load_historical_rows() -> list[HistoricalRow]:
    rows: list[HistoricalRow] = []
    with HISTORICAL_STATS.open("r", encoding="utf-8", errors="ignore") as fh:
        next(fh, None)
        for line in fh:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = [p.strip() for p in line.split(" | ")]
            if len(parts) < 4:
                continue
            try:
                idx = int(parts[0])
            except ValueError:
                continue
            url = parts[1]
            if not url.startswith(("http://", "https://")):
                continue
            rows.append(
                HistoricalRow(
                    index=idx,
                    url=url,
                    download_status=parts[2],
                    parse_status=parts[3],
                    raw_fields=parts,
                )
            )
    return rows


def sniff_payload_kind(raw: bytes) -> str:
    head = raw[:4096].decode("utf-8", errors="ignore").lstrip()
    lower = head.lower()
    if lower.startswith("<!doctype html") or lower.startswith("<html") or "<html" in lower:
        return "html"
    if "proxies:" in head:
        return "clash-yaml"
    if lower.startswith("{") or lower.startswith("["):
        return "json-like"
    if ":// " in head:
        return "uri-like"
    if "://" in head:
        return "uri-like"
    return "unknown"


def build_request(url: str) -> urllib.request.Request:
    return urllib.request.Request(
        url,
        headers={
            "User-Agent": UA,
            "Accept": "*/*",
            "Connection": "close",
        },
    )


def fetch_url(url: str) -> tuple[bytes | None, str | None, str | None]:
    ctx = ssl._create_unverified_context()
    try:
        with urllib.request.urlopen(build_request(url), timeout=TIMEOUT, context=ctx) as resp:
            status = getattr(resp, "status", None)
            final_url = resp.geturl()
            data = resp.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                return None, final_url, f"payload_too_large>{MAX_BYTES}"
            if status and status >= 400:
                return None, final_url, f"http_{status}"
            return data, final_url, None
    except urllib.error.HTTPError as e:
        return None, e.geturl(), f"http_{e.code}"
    except urllib.error.URLError as e:
        return None, None, f"urlerror:{e.reason}"
    except Exception as e:  # noqa: BLE001
        return None, None, f"exception:{type(e).__name__}:{e}"


def run_subtool(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False)


def parse_output_counts(output_path: Path) -> dict[str, int]:
    counts: dict[str, int] = {}
    if not output_path.exists():
        return counts
    with output_path.open("r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                counts["_json_error"] = counts.get("_json_error", 0) + 1
                continue
            type_id = str(obj.get("type", ""))
            counts[type_id] = counts.get(type_id, 0) + 1
    return counts


def count_lines(path: Path) -> int:
    if not path.exists():
        return 0
    with path.open("r", encoding="utf-8", errors="ignore") as fh:
        return sum(1 for _ in fh if _.strip())


def save_failure_artifacts(base_dir: Path, index: int, raw: bytes | None, inspect_stdout: str | None, parse_stderr: str | None) -> None:
    sample_dir = base_dir / "samples"
    sample_dir.mkdir(parents=True, exist_ok=True)
    if raw is not None:
        (sample_dir / f"{index}.bin").write_bytes(raw)
    if inspect_stdout:
        (sample_dir / f"{index}.inspect.json").write_text(inspect_stdout, encoding="utf-8")
    if parse_stderr:
        (sample_dir / f"{index}.parse.stderr.txt").write_text(parse_stderr, encoding="utf-8")


def test_one(row: HistoricalRow, out_dir: Path) -> dict[str, Any]:
    result: dict[str, Any] = {
        "index": row.index,
        "url": row.url,
        "historical_download": row.download_status,
        "historical_parse": row.parse_status,
    }
    raw, final_url, fetch_error = fetch_url(row.url)
    result["final_url"] = final_url
    if fetch_error:
        result["status"] = "download_fail"
        result["reason"] = fetch_error
        return result
    assert raw is not None
    result["status"] = "download_ok"
    result["bytes"] = len(raw)
    result["sniff"] = sniff_payload_kind(raw)

    with tempfile.TemporaryDirectory(prefix=f"subtool_airport_{row.index}_") as td:
        raw_path = Path(td) / "payload.bin"
        out_path = Path(td) / "parsed.jsonl"
        raw_path.write_bytes(raw)

        inspect_proc = run_subtool([str(SUBTOOL), "inspect", "--input", str(raw_path)])
        result["inspect_rc"] = inspect_proc.returncode
        if inspect_proc.stdout.strip():
            try:
                result["inspect"] = json.loads(inspect_proc.stdout)
            except json.JSONDecodeError:
                result["inspect_raw"] = inspect_proc.stdout.strip()
        if inspect_proc.returncode != 0:
            result["status"] = "inspect_fail"
            result["reason"] = inspect_proc.stderr.strip() or "inspect_nonzero"
            save_failure_artifacts(out_dir, row.index, raw, inspect_proc.stdout.strip(), inspect_proc.stderr.strip())
            return result

        parse_cmd = [
            str(SUBTOOL),
            "parse-uri-lines",
            "--input",
            str(raw_path),
            "--output",
            str(out_path),
            "--format",
            "fancyss",
            "--group",
            "compat-test",
            "--source-tag",
            "compat",
            "--mode",
            "2",
            "--pkg-type",
            "full",
            "--sub-ai",
            "0",
            "--hy2-tfo-switch",
            "2",
            "--hy2-cg-opt",
            "bbr",
            "--log-level",
            "none",
            "--include-raw",
        ]
        parse_proc = run_subtool(parse_cmd)
        result["parse_rc"] = parse_proc.returncode
        if parse_proc.returncode != 0:
            result["status"] = "parse_fail"
            result["reason"] = parse_proc.stderr.strip() or "parse_nonzero"
            save_failure_artifacts(out_dir, row.index, raw, inspect_proc.stdout.strip(), parse_proc.stderr.strip())
            return result

        node_count = count_lines(out_path)
        counts = parse_output_counts(out_path)
        result["node_count"] = node_count
        result["type_counts"] = counts
        if node_count > 0:
            result["status"] = "parse_ok"
        else:
            result["status"] = "parse_zero"
            save_failure_artifacts(out_dir, row.index, raw, inspect_proc.stdout.strip(), parse_proc.stderr.strip())
    return result


def summarize(results: list[dict[str, Any]]) -> dict[str, Any]:
    summary: dict[str, Any] = {
        "total_candidates": len(results),
        "download_fail": 0,
        "download_ok": 0,
        "inspect_fail": 0,
        "parse_fail": 0,
        "parse_zero": 0,
        "parse_ok": 0,
        "historical_parse_fail_now_fixed": 0,
        "historical_zero_now_nonzero": 0,
    }
    type_totals: dict[str, int] = {}
    inspect_kind_totals: dict[str, int] = {}
    parse_fail_kind_totals: dict[str, int] = {}
    parse_fail_host_totals: dict[str, int] = {}
    for item in results:
        status = item["status"]
        summary[status] = summary.get(status, 0) + 1
        if status != "download_fail":
            summary["download_ok"] += 1
        inspect = item.get("inspect")
        inspect_kind = ""
        if isinstance(inspect, dict):
            inspect_kind = str(inspect.get("kind", "") or "")
        if inspect_kind:
            inspect_kind_totals[inspect_kind] = inspect_kind_totals.get(inspect_kind, 0) + 1
        if status == "parse_fail" and inspect_kind:
            parse_fail_kind_totals[inspect_kind] = parse_fail_kind_totals.get(inspect_kind, 0) + 1
            host = urllib.parse.urlparse(item.get("url", "")).netloc
            key = f"{inspect_kind}|{host}"
            parse_fail_host_totals[key] = parse_fail_host_totals.get(key, 0) + 1
        for type_id, count in item.get("type_counts", {}).items():
            type_totals[type_id] = type_totals.get(type_id, 0) + count
        hist_parse = item.get("historical_parse", "")
        if hist_parse == "解析失败" and status == "parse_ok":
            summary["historical_parse_fail_now_fixed"] += 1
        if hist_parse.startswith("解析成功") and item.get("node_count", -1) > 0:
            raw_fields = item.get("historical_fields")
        if hist_parse.startswith("解析成功") and item.get("status") == "parse_ok":
            pass
    summary["type_totals"] = type_totals
    summary["inspect_kind_totals"] = inspect_kind_totals
    summary["parse_fail_kind_totals"] = parse_fail_kind_totals
    summary["parse_fail_host_totals"] = dict(sorted(parse_fail_host_totals.items(), key=lambda kv: (-kv[1], kv[0]))[:30])
    return summary


def main() -> int:
    if not SUBTOOL.exists():
        print(f"sub-tool binary not found: {SUBTOOL}", file=sys.stderr)
        return 2

    historical_rows = load_historical_rows()
    candidates = [r for r in historical_rows if r.download_status == "下载成功"]

    now = dt.datetime.now().strftime("%Y%m%d%H%M%S")
    out_dir = ROOT / f"subtool_compat_{now}"
    out_dir.mkdir(parents=True, exist_ok=True)

    results: list[dict[str, Any]] = []
    lock = threading.Lock()

    def worker(row: HistoricalRow) -> dict[str, Any]:
        res = test_one(row, out_dir)
        res["historical_fields"] = row.raw_fields
        return res

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as ex:
        future_map = {ex.submit(worker, row): row for row in candidates}
        done = 0
        total = len(future_map)
        for fut in concurrent.futures.as_completed(future_map):
            row = future_map[fut]
            try:
                res = fut.result()
            except Exception as e:  # noqa: BLE001
                res = {
                    "index": row.index,
                    "url": row.url,
                    "historical_download": row.download_status,
                    "historical_parse": row.parse_status,
                    "status": "worker_error",
                    "reason": f"{type(e).__name__}:{e}",
                }
            with lock:
                results.append(res)
                done += 1
                if done % 25 == 0 or done == total:
                    print(f"[{done}/{total}] tested", flush=True)

    results.sort(key=lambda x: x["index"])
    jsonl_path = out_dir / "results.jsonl"
    with jsonl_path.open("w", encoding="utf-8") as fh:
        for item in results:
            fh.write(json.dumps(item, ensure_ascii=False) + "\n")

    summary = summarize(results)
    summary["timestamp"] = now
    summary["candidate_basis"] = "historically download-success urls from statistics_20260114174817.txt"
    summary["candidate_count"] = len(candidates)
    summary_path = out_dir / "summary.json"
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    lines: list[str] = []
    lines.append(f"timestamp: {now}")
    lines.append(f"candidate_basis: 历史上下载成功的链接")
    lines.append(f"candidate_count: {len(candidates)}")
    for key in ["download_fail", "inspect_fail", "parse_fail", "parse_zero", "parse_ok"]:
        lines.append(f"{key}: {summary.get(key, 0)}")
    lines.append("type_totals:")
    for key, value in sorted(summary.get("type_totals", {}).items()):
        lines.append(f"  type_{key}: {value}")
    lines.append("inspect_kind_totals:")
    for key, value in sorted(summary.get("inspect_kind_totals", {}).items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"  {key}: {value}")
    lines.append("parse_fail_kind_totals:")
    for key, value in sorted(summary.get("parse_fail_kind_totals", {}).items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"  {key}: {value}")
    lines.append("parse_fail_host_totals:")
    for key, value in summary.get("parse_fail_host_totals", {}).items():
        kind, host = key.split("|", 1)
        lines.append(f"  {kind} | {host}: {value}")

    parse_fail_samples = [x for x in results if x["status"] == "parse_fail"][:50]
    parse_zero_samples = [x for x in results if x["status"] == "parse_zero"][:50]
    download_fail_samples = [x for x in results if x["status"] == "download_fail"][:50]
    parse_fail_by_kind: dict[str, list[dict[str, Any]]] = {}
    for item in results:
        if item["status"] != "parse_fail":
            continue
        inspect_kind = ""
        inspect = item.get("inspect")
        if isinstance(inspect, dict):
            inspect_kind = inspect.get("kind", "") or ""
        parse_fail_by_kind.setdefault(inspect_kind or "(empty)", []).append(item)

    lines.append("")
    lines.append("parse_fail_samples:")
    for item in parse_fail_samples:
        inspect_kind = ""
        inspect = item.get("inspect")
        if isinstance(inspect, dict):
            inspect_kind = inspect.get("kind", "")
        lines.append(f"  - {item['index']} | {item['url']} | inspect={inspect_kind} sniff={item.get('sniff','')} | {item.get('reason','')}")
    lines.append("")
    lines.append("parse_fail_samples_by_kind:")
    for kind, items in sorted(parse_fail_by_kind.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        lines.append(f"  [{kind}] count={len(items)}")
        for item in items[:8]:
            lines.append(f"    - {item['index']} | {item['url']} | sniff={item.get('sniff','')} | {item.get('reason','')}")
    lines.append("")
    lines.append("parse_zero_samples:")
    for item in parse_zero_samples:
        inspect_kind = ""
        inspect = item.get("inspect")
        if isinstance(inspect, dict):
            inspect_kind = inspect.get("kind", "")
        lines.append(f"  - {item['index']} | {item['url']} | inspect={inspect_kind} sniff={item.get('sniff','')}")
    lines.append("")
    lines.append("download_fail_samples:")
    for item in download_fail_samples:
        lines.append(f"  - {item['index']} | {item['url']} | {item.get('reason','')}")

    (out_dir / "summary.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"results_dir={out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
