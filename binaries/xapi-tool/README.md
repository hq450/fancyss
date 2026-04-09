# xapi-tool binaries

Source project:
- `tool/xapi-tool`

Current bundled version:
- `v0.2.1`

Purpose:
- lightweight Xray API client for fancyss hot paths
- first targets are `StatsService.QueryStats` and selected routing / handler commands
- intended to replace slow one-shot `xray api ...` calls

Packaging note:
- `bin-arm` is not bundled yet
- armv5 / old arm builds still fall back to `xray api`
- current bundled `v0.2.1` artifacts are UPX-packed
- verified on GS7 (`aarch64`) and TUF-AX3000 (`armv7a` / `armv7hf`) that the bundled binaries can start normally
