#!/usr/bin/env python3
# coding=utf-8
#
# Generate a domain list from gfwlist (for dnsmasq/ipset rules generation)
#
# Copyright (C) 2014 http://www.shuyz.com
# Ref https://code.google.com/p/autoproxy-gfwlist/wiki/Rules

import base64
import io
import re
import sys
from urllib.request import Request, urlopen


def _usage() -> None:
    print("usage: update_gfwlist.py <outfile>", file=sys.stderr)


def _decode_gfwlist(raw: bytes) -> str:
    try:
        decoded = base64.b64decode(raw)
        text = decoded.decode("utf-8", "ignore")
        if text.lstrip().startswith("[AutoProxy"):
            return text
    except Exception:
        pass
    return raw.decode("utf-8", "ignore")


def main(argv) -> int:
    if len(argv) != 2:
        _usage()
        return 2

    outfile = argv[1]

    baseurl = "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
    comment_re = re.compile(r"^\!|\[|^@@|^\d+\.\d+\.\d+\.\d+")
    domain_re = re.compile(r"([\w\-\_]+\.[\w\.\-\_]+)[\/\*]*")

    print("fetching list...")
    try:
        request = Request(baseurl, headers={"User-Agent": "fancyss-update-gfwlist/1.0"})
        with urlopen(request, timeout=15) as response:
            content = _decode_gfwlist(response.read())
    except Exception as exc:
        print(f"error: failed to fetch gfwlist: {exc}", file=sys.stderr)
        return 1

    print("page content fetched, analysis...")
    seen = set()
    with io.open(outfile, "w", encoding="utf-8", newline="\n") as out_fp:
        for line in content.splitlines():
            if comment_re.search(line):
                continue
            matches = domain_re.findall(line)
            if not matches:
                continue
            domain = matches[0]
            if domain in seen:
                continue
            seen.add(domain)
            out_fp.write(f"{domain}\n")

    print("saving to file:", outfile)
    print("done!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
