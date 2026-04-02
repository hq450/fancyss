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
- `v0.2.1` is bundled without UPX; GS7 rejected the UPX-packed binary with `PROT_EXEC|PROT_WRITE failed`
