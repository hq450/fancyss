# status-tool binaries

Source project:

- `tool/status-tool`

Purpose:

- native HTTP status probe tool for fancyss
- intended to replace the heavy shell + curl based `ss_status.sh` / `ss_status_main.sh` path
- includes `statusctl`, a thin Unix socket control client for `status-tool serve`

Artifacts in this directory are generated from:

```bash
make -C binaries update_status_tool
```
