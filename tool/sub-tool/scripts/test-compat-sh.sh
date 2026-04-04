#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
SUBTOOL="${SUBTOOL:-}"
UA="${UA:-AsusWRT|koolcenter|GS7|102_58273_koolcenter|fancyss|mtk|full|3.5.10|curl|v2rayN}"
TIMEOUT="${TIMEOUT:-10}"
OUT_BASE="${OUT_BASE:-/tmp/subtool_compat_runs}"
GROUP_NAME="${GROUP_NAME:-compat-test}"
SOURCE_TAG="${SOURCE_TAG:-compat}"
MODE_VALUE="${MODE_VALUE:-2}"
PKG_TYPE="${PKG_TYPE:-full}"
SUB_AI="${SUB_AI:-0}"
HY2_TFO_SWITCH="${HY2_TFO_SWITCH:-2}"
HY2_CG_OPT="${HY2_CG_OPT:-bbr}"
LIMIT="${LIMIT:-0}"
KEEP_SAMPLES="${KEEP_SAMPLES:-1}"
SAMPLE_CAP="${SAMPLE_CAP:-80}"

INPUT_FILE=""
FETCHER=""
OUT_DIR=""
WORK_DIR=""
SAMPLES_DIR=""
RESULTS_TSV=""
TYPE_IDS_FILE=""
INSPECT_KINDS_FILE=""
PARSE_FAIL_KINDS_FILE=""
PARSE_FAIL_HOSTS_FILE=""
SAVED_SAMPLES=0

usage() {
	cat <<-'EOF'
	Usage:
	  sh ./tool/sub-tool/scripts/test-compat-sh.sh --input <file> [--out-dir <dir>] [--limit <n>] [--fetcher curl|wget]

	Input file formats:
	  1. Plain URL list: one http/https URL per line
	  2. Historical statistics file: lines like "序号 | 链接 | 下载状态 | ..."

	Environment overrides:
	  SUBTOOL          Path to sub-tool binary
	  OUT_BASE         Base output directory, default /tmp/subtool_compat_runs
	  TIMEOUT          Download timeout seconds, default 10
	  KEEP_SAMPLES     Save failed payload samples, default 1
	  SAMPLE_CAP       Max saved failure samples, default 80
	EOF
}

log() {
	printf '%s\n' "$*"
}

trim_spaces() {
	printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

find_subtool() {
	if [ -n "$SUBTOOL" ] && [ -x "$SUBTOOL" ]; then
		return 0
	fi
	if command -v sub-tool >/dev/null 2>&1; then
		SUBTOOL="$(command -v sub-tool)"
		return 0
	fi
	if [ -x "/koolshare/bin/sub-tool" ]; then
		SUBTOOL="/koolshare/bin/sub-tool"
		return 0
	fi
	if [ -x "$ROOT_DIR/zig-out/bin/sub-tool" ]; then
		SUBTOOL="$ROOT_DIR/zig-out/bin/sub-tool"
		return 0
	fi
	log "error: sub-tool not found"
	exit 1
}

detect_fetcher() {
	if [ -n "$FETCHER" ]; then
		return 0
	fi
	if command -v curl >/dev/null 2>&1; then
		FETCHER="curl"
		return 0
	fi
	if command -v wget >/dev/null 2>&1; then
		FETCHER="wget"
		return 0
	fi
	log "error: curl/wget not found"
	exit 1
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
			--input)
				INPUT_FILE="$2"
				shift 2
				;;
			--out-dir)
				OUT_DIR="$2"
				shift 2
				;;
			--limit)
				LIMIT="$2"
				shift 2
				;;
			--fetcher)
				FETCHER="$2"
				shift 2
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				log "error: unknown arg: $1"
				usage
				exit 1
				;;
		esac
	done

	if [ -z "$INPUT_FILE" ]; then
		log "error: --input is required"
		usage
		exit 1
	fi
	if [ ! -f "$INPUT_FILE" ]; then
		log "error: input file not found: $INPUT_FILE"
		exit 1
	fi
}

prepare_dirs() {
	now="$(date '+%Y%m%d%H%M%S')"
	if [ -z "$OUT_DIR" ]; then
		OUT_DIR="$OUT_BASE/subtool_compat_sh_$now"
	fi
	WORK_DIR="$OUT_DIR/work"
	SAMPLES_DIR="$OUT_DIR/samples"
	RESULTS_TSV="$OUT_DIR/results.tsv"
	TYPE_IDS_FILE="$OUT_DIR/type_ids.txt"
	INSPECT_KINDS_FILE="$OUT_DIR/inspect_kinds.txt"
	PARSE_FAIL_KINDS_FILE="$OUT_DIR/parse_fail_kinds.txt"
	PARSE_FAIL_HOSTS_FILE="$OUT_DIR/parse_fail_hosts.txt"
	mkdir -p "$OUT_DIR" "$WORK_DIR" "$SAMPLES_DIR"
	: > "$RESULTS_TSV"
	: > "$TYPE_IDS_FILE"
	: > "$INSPECT_KINDS_FILE"
	: > "$PARSE_FAIL_KINDS_FILE"
	: > "$PARSE_FAIL_HOSTS_FILE"
}

extract_urls() {
	awk '
	function trim(s) {
		sub(/^[ \t\r\n]+/, "", s)
		sub(/[ \t\r\n]+$/, "", s)
		return s
	}
	{
		line = trim($0)
		if (line ~ /^https?:\/\//) {
			if (!seen[line]++) print line
			next
		}
		n = split($0, parts, /\|/)
		if (n >= 2) {
			url = trim(parts[2])
			if (url ~ /^https?:\/\// && !seen[url]++) print url
		}
	}
	' "$INPUT_FILE"
}

url_host() {
	printf '%s' "$1" | sed 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##; s#/.*$##'
}

sniff_payload_kind() {
	file="$1"
	head_text="$(LC_ALL=C head -c 4096 "$file" 2>/dev/null | tr '\r' '\n')"
	lower_text="$(printf '%s' "$head_text" | tr 'A-Z' 'a-z')"
	case "$lower_text" in
		*'<!doctype html'*|*'<html'*)
			printf '%s\n' "html"
			return 0
			;;
	esac
	case "$head_text" in
		*'proxies:'*)
			printf '%s\n' "clash-yaml"
			return 0
			;;
		\{*|\[*)
			printf '%s\n' "json-like"
			return 0
			;;
		*'://'*)
			printf '%s\n' "uri-like"
			return 0
			;;
	esac
	printf '%s\n' "unknown"
}

json_field_string() {
	key="$1"
	file="$2"
	sed -n "s/.*\"$key\":\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n 1
}

normalize_reason() {
	file="$1"
	if [ ! -s "$file" ]; then
		printf '%s\n' ""
		return 0
	fi
	tr '\r\n' ' ' < "$file" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

save_failure_sample() {
	index="$1"
	payload="$2"
	inspect_json="$3"
	parse_stderr="$4"

	if [ "$KEEP_SAMPLES" != "1" ]; then
		return 0
	fi
	if [ "$SAVED_SAMPLES" -ge "$SAMPLE_CAP" ]; then
		return 0
	fi
	[ -f "$payload" ] && cp "$payload" "$SAMPLES_DIR/$index.bin"
	[ -s "$inspect_json" ] && cp "$inspect_json" "$SAMPLES_DIR/$index.inspect.json"
	[ -s "$parse_stderr" ] && cp "$parse_stderr" "$SAMPLES_DIR/$index.parse.stderr.txt"
	SAVED_SAMPLES=$((SAVED_SAMPLES + 1))
}

fetch_with_curl() {
	url="$1"
	payload="$2"
	headers="$3"
	stderr_file="$4"

	curl -L -k -A "$UA" --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" \
		-D "$headers" -o "$payload" -sS "$url" > /dev/null 2>"$stderr_file" || return 1
	return 0
}

fetch_with_wget() {
	url="$1"
	payload="$2"
	headers="$3"
	stderr_file="$4"
	ext_opt=""
	case "$url" in
		https://*)
			ext_opt="--no-check-certificate"
			;;
	esac
	wget -q -T "$TIMEOUT" -t 1 --max-redirect=5 --server-response -U "$UA" \
		$ext_opt -O "$payload" "$url" 2>"$headers" > "$stderr_file" || return 1
	return 0
}

last_http_code() {
	file="$1"
	awk '
		/^[[:space:]]*HTTP\// { code = $2 }
		END {
			if (code == "") code = 0
			print code
		}
	' "$file"
}

append_type_ids() {
	jsonl="$1"
	if [ ! -s "$jsonl" ]; then
		return 0
	fi
	sed -n 's/.*"type":[[:space:]]*"\{0,1\}\([0-9][0-9]*\)"\{0,1\}.*/\1/p' "$jsonl" >> "$TYPE_IDS_FILE"
}

count_nonempty_lines() {
	file="$1"
	awk 'NF { c++ } END { print c + 0 }' "$file"
}

write_result_row() {
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
		"$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" >> "$RESULTS_TSV"
}

run_one() {
	index="$1"
	url="$2"

	payload="$WORK_DIR/payload.bin"
	headers="$WORK_DIR/headers.txt"
	fetch_stderr="$WORK_DIR/fetch.stderr.txt"
	inspect_json="$WORK_DIR/inspect.json"
	inspect_stderr="$WORK_DIR/inspect.stderr.txt"
	parsed_jsonl="$WORK_DIR/parsed.jsonl"
	parse_stderr="$WORK_DIR/parse.stderr.txt"

	: > "$payload"
	: > "$headers"
	: > "$fetch_stderr"
	: > "$inspect_json"
	: > "$inspect_stderr"
	: > "$parsed_jsonl"
	: > "$parse_stderr"

	log "[$index] fetch: $url"
	if [ "$FETCHER" = "curl" ]; then
		if ! fetch_with_curl "$url" "$payload" "$headers" "$fetch_stderr"; then
			reason="$(normalize_reason "$fetch_stderr")"
			write_result_row "$index" "$url" "download_fail" "" "" "${reason:-fetch_failed}" "0" "0"
			return 0
		fi
	else
		if ! fetch_with_wget "$url" "$payload" "$headers" "$fetch_stderr"; then
			reason="$(normalize_reason "$headers")"
			write_result_row "$index" "$url" "download_fail" "" "" "${reason:-fetch_failed}" "0" "0"
			return 0
		fi
	fi

	http_code="$(last_http_code "$headers")"
	case "$http_code" in
		''|0)
			http_code="0"
			;;
	esac
	if [ "$http_code" -ge 400 ] 2>/dev/null; then
		write_result_row "$index" "$url" "download_fail" "" "" "http_$http_code" "0" "$http_code"
		return 0
	fi

	sniff_kind="$(sniff_payload_kind "$payload")"
	if ! "$SUBTOOL" inspect --input "$payload" > "$inspect_json" 2>"$inspect_stderr"; then
		reason="$(normalize_reason "$inspect_stderr")"
		save_failure_sample "$index" "$payload" "$inspect_json" "$inspect_stderr"
		write_result_row "$index" "$url" "inspect_fail" "" "$sniff_kind" "${reason:-inspect_failed}" "0" "$http_code"
		return 0
	fi

	inspect_kind="$(json_field_string "kind" "$inspect_json")"
	if [ -n "$inspect_kind" ]; then
		printf '%s\n' "$inspect_kind" >> "$INSPECT_KINDS_FILE"
	fi

	if ! "$SUBTOOL" parse-uri-lines \
		--input "$payload" \
		--output "$parsed_jsonl" \
		--format fancyss \
		--group "$GROUP_NAME" \
		--source-tag "$SOURCE_TAG" \
		--mode "$MODE_VALUE" \
		--pkg-type "$PKG_TYPE" \
		--sub-ai "$SUB_AI" \
		--hy2-tfo-switch "$HY2_TFO_SWITCH" \
		--hy2-cg-opt "$HY2_CG_OPT" \
		--log-level none \
		--include-raw > /dev/null 2>"$parse_stderr"
	then
		reason="$(normalize_reason "$parse_stderr")"
		if [ -n "$inspect_kind" ]; then
			printf '%s\n' "$inspect_kind" >> "$PARSE_FAIL_KINDS_FILE"
			host="$(url_host "$url")"
			printf '%s | %s\n' "$inspect_kind" "$host" >> "$PARSE_FAIL_HOSTS_FILE"
		fi
		save_failure_sample "$index" "$payload" "$inspect_json" "$parse_stderr"
		write_result_row "$index" "$url" "parse_fail" "$inspect_kind" "$sniff_kind" "${reason:-parse_failed}" "0" "$http_code"
		return 0
	fi

	node_count="$(count_nonempty_lines "$parsed_jsonl")"
	append_type_ids "$parsed_jsonl"
	if [ "$node_count" -gt 0 ] 2>/dev/null; then
		write_result_row "$index" "$url" "parse_ok" "$inspect_kind" "$sniff_kind" "" "$node_count" "$http_code"
	else
		if [ -n "$inspect_kind" ]; then
			printf '%s\n' "$inspect_kind" >> "$PARSE_FAIL_KINDS_FILE"
			host="$(url_host "$url")"
			printf '%s | %s\n' "$inspect_kind" "$host" >> "$PARSE_FAIL_HOSTS_FILE"
		fi
		save_failure_sample "$index" "$payload" "$inspect_json" "$parse_stderr"
		write_result_row "$index" "$url" "parse_zero" "$inspect_kind" "$sniff_kind" "" "$node_count" "$http_code"
	fi
}

render_counter_file() {
	title="$1"
	file="$2"
	if [ ! -s "$file" ]; then
		return 0
	fi
	printf '%s\n' "$title" >> "$OUT_DIR/summary.txt"
	sort "$file" | uniq -c | sort -nr | while read -r count rest; do
		printf '  %s: %s\n' "$rest" "$count" >> "$OUT_DIR/summary.txt"
	done
}

render_type_totals() {
	if [ ! -s "$TYPE_IDS_FILE" ]; then
		return 0
	fi
	printf '%s\n' "type_totals:" >> "$OUT_DIR/summary.txt"
	sort "$TYPE_IDS_FILE" | uniq -c | sort -n | while read -r count type_id; do
		printf '  type_%s: %s\n' "$type_id" "$count" >> "$OUT_DIR/summary.txt"
	done
}

render_status_counts() {
	status="$1"
	count="$(awk -F '\t' -v target="$status" '$3 == target { c++ } END { print c + 0 }' "$RESULTS_TSV")"
	printf '%s: %s\n' "$status" "$count" >> "$OUT_DIR/summary.txt"
}

render_parse_fail_samples() {
	printf '\n%s\n' "parse_fail_samples:" >> "$OUT_DIR/summary.txt"
	awk -F '\t' '
		$3 == "parse_fail" {
			printf "  - %s | %s | inspect=%s sniff=%s | %s\n", $1, $2, $4, $5, $6
			count++
			if (count >= 50) exit
		}
	' "$RESULTS_TSV" >> "$OUT_DIR/summary.txt"
}

render_download_fail_samples() {
	printf '\n%s\n' "download_fail_samples:" >> "$OUT_DIR/summary.txt"
	awk -F '\t' '
		$3 == "download_fail" {
			printf "  - %s | %s | %s\n", $1, $2, $6
			count++
			if (count >= 50) exit
		}
	' "$RESULTS_TSV" >> "$OUT_DIR/summary.txt"
}

render_samples_by_kind() {
	printf '\n%s\n' "parse_fail_samples_by_kind:" >> "$OUT_DIR/summary.txt"
	if [ ! -s "$PARSE_FAIL_KINDS_FILE" ]; then
		return 0
	fi
	sort "$PARSE_FAIL_KINDS_FILE" | uniq -c | sort -nr | while read -r count kind; do
		printf '  [%s] count=%s\n' "$kind" "$count" >> "$OUT_DIR/summary.txt"
		awk -F '\t' -v target="$kind" '
			$3 == "parse_fail" && $4 == target {
				printf "    - %s | %s | sniff=%s | %s\n", $1, $2, $5, $6
				count++
				if (count >= 8) exit
			}
		' "$RESULTS_TSV" >> "$OUT_DIR/summary.txt"
	done
}

write_summary() {
	{
		printf 'timestamp: %s\n' "$(date '+%Y%m%d%H%M%S')"
		printf 'input_file: %s\n' "$INPUT_FILE"
		printf 'fetcher: %s\n' "$FETCHER"
		printf 'subtool: %s\n' "$SUBTOOL"
		printf 'candidate_count: %s\n' "$(awk 'END { print NR + 0 }' "$OUT_DIR/urls.txt")"
	} > "$OUT_DIR/summary.txt"

	render_status_counts "download_fail"
	render_status_counts "inspect_fail"
	render_status_counts "parse_fail"
	render_status_counts "parse_zero"
	render_status_counts "parse_ok"
	render_type_totals
	render_counter_file "inspect_kind_totals:" "$INSPECT_KINDS_FILE"
	render_counter_file "parse_fail_kind_totals:" "$PARSE_FAIL_KINDS_FILE"
	render_counter_file "parse_fail_host_totals:" "$PARSE_FAIL_HOSTS_FILE"
	render_parse_fail_samples
	render_samples_by_kind
	render_download_fail_samples
}

main() {
	parse_args "$@"
	find_subtool
	detect_fetcher
	prepare_dirs

	extract_urls > "$OUT_DIR/urls_all.txt"
	if [ "$LIMIT" -gt 0 ] 2>/dev/null; then
		head -n "$LIMIT" "$OUT_DIR/urls_all.txt" > "$OUT_DIR/urls.txt"
	else
		cp "$OUT_DIR/urls_all.txt" "$OUT_DIR/urls.txt"
	fi

	index=0
	while IFS= read -r url; do
		[ -n "$url" ] || continue
		index=$((index + 1))
		run_one "$index" "$url"
	done < "$OUT_DIR/urls.txt"

	write_summary
	log "results_dir=$OUT_DIR"
	log "summary_file=$OUT_DIR/summary.txt"
}

main "$@"
