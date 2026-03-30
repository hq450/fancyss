# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fancyss is a VPN/proxy plugin for ASUS routers running asuswrt/merlin-based firmware with software center support. It enables GFW bypass with 8 proxy protocols (SS, SSR, VMess, VLess, Trojan, NaiveProxy, TuicV5, Hysteria2). The codebase is primarily in Bash and JavaScript, with Chinese-language comments and UI text throughout.

## Build Commands

```bash
# Full build: sync binaries + build all 14 release packages + 7 debug packages
./build.sh

# Or via make (also updates binaries from binaries/ subdir first)
make
```

Build output goes to `packages/` as `fancyss_{platform}_{full|lite}.tar.gz` plus `version.json.js` with MD5 checksums. There is no test suite or linter.

## Build Pipeline

`build.sh` flow: `papare()` → per-platform `pack()` → `finish()`

1. **papare()**: Cleans packages/, copies rules from `rules_ng/` and `rules_ng2/`, syncs latest binaries from `binaries/`
2. **gen_folder(platform, pkgtype, release_type)**: Copies `fancyss/` → `shadowsocks/`, keeps only `bin-{platform}/` (renamed to `bin/`), patches `PKG_ARCH` in the ASP file. For lite: removes extra binaries (naive, tuic-client, ipt2socks) and strips full-only UI sections. For release: strips comments and empty lines.
3. **build_pkg()**: Creates tar.gz, computes MD5, appends to version JSON
4. **finish()**: Validates JSON with jq, writes final `version.json.js`

## Platforms

7 platforms, each built as full + lite:

| Platform | Arch | CPU Examples |
|----------|------|-------------|
| arm | armv5 | BCM4708/4709 |
| hnd | armv7 | BCM6750/6755/6756 |
| hnd_v8 | armv8 | BCM4906/4908/4912/4916 |
| qca | armv7 | IPQ8074 |
| mtk | armv8 | MT7986A/MT7988D |
| ipq32 | armv7 | IPQ5322 (ZenWiFi BD4) |
| ipq64 | armv8 | IPQ5322 64-bit OS (TUF-BE6500) |

Note: ipq64 reuses `bin-mtk/` binaries; ipq32 and ipq64 skip jq/curl-fancyss (already in firmware).

## Architecture

### Core Scripts (`fancyss/scripts/`)

- **ss_base.sh** — Base library sourced by all other scripts. Sets up paths, aliases, dbus config reads, utility functions. This is the main import point.
- **ssconfig.sh** (`fancyss/ss/`) — Main runtime engine (~7000 lines). Generates Xray JSON configs, DNS configs (SmartDNS/ChinaDNS-NG), iptables rules, and firewall marks based on dbus settings.
- **ss_conf.sh** — Configuration backup/restore, export to JSON or legacy bash format.
- **ss_node_common.sh** — Node data structures and manipulation for all protocol types.
- **ss_node_subscribe.sh** — Subscription URL parsing, base64/v2rayN decoding, node import.
- **ss_node_shunt.sh** — Advanced traffic routing (shunt) by domain/IP rules.
- **ss_webtest.sh / ss_webtest_gen.sh** — Node latency testing with caching and batch support.
- **ss_proc_status.sh** — Process health monitoring for proxy daemons.

### Web UI

- **Module_shadowsocks.asp** (`fancyss/webs/`) — Single-page ASP interface (~459KB). Contains embedded JavaScript and build-time placeholders (`PKG_ARCH`, `PKG_TYPE`, `PKG_EXTA`).
- **ss-menu.js** (`fancyss/res/`) — Main UI logic, event handlers, dbus read/write operations.

### Full vs Lite Conditional Code

The codebase uses markers for build-time stripping:
- `//fancyss-full` — Comment lines removed in release builds
- `<!--fancyss_full_1-->...<!--fancyss_full_2-->` — HTML blocks removed in lite builds
- `#@` prefix in shell scripts — Uncommented only in full builds (via `sed -i 's/#@//g'`)
- `/fancyss-full/d` — Lines containing this marker are deleted in lite builds

### Configuration Storage

All runtime config is stored in dbus (nvram-like) with `ss_` prefix (e.g., `ss_basic_mode`, `ssnode_*`, `ssconf_*`). Scripts read/write these via dbus commands.

### Rules System

- `rules_ng/` — Source rule files (gfwlist, chnlist, chnroute, adslist, etc.)
- `rules_ng2/` — Next-gen shunt routing rules
- Copied into `fancyss/ss/rules/` and `fancyss/ss/rules_ng2/` during build

### Binary Management

Pre-compiled binaries live in `binaries/` with version tracking (`latest.txt`, `latest_2.txt`). `sync_binary()` copies the correct architecture variant (arm64/armv7/armv5) into each `bin-{platform}/` directory. Key binaries: xray, naive, ipt2socks, tuic-client, chinadns-ng.

## Key Conventions

- Version is stored in `fancyss/ss/version` (currently read by build.sh)
- The build creates a temporary `shadowsocks/` directory (cleaned up after each platform pack)
- Shell scripts use `source` / `.` to import `ss_base.sh` as a shared library
- Lock-based synchronization prevents concurrent config changes at runtime
- Router skin/theme auto-detection adapts CSS colors (ROG=red, TUF=orange, etc.)
