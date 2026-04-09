# websocketd binaries

Source project:

- `tool/ws-tool`

Current bundled version:

- `v0.1.0`

Purpose:

- lightweight Zig replacement for upstream `websocketd`
- covers the fancyss websocket usage model:
  - `websocketd --port=803 /koolshare/ss/websocket`
  - text frame -> child stdin line
  - child stdout/stderr line -> websocket text frame
  - CGI/HTTP env compatibility for `/koolshare/ss/websocket`

Bundled architectures:

- `aarch64`
- `armv7a`
- `armv7hf`
- `x86_64`

Packaging note:

- release artifacts should be built by `tool/ws-tool/scripts/build-release.sh`
- `x86_64` currently skips UPX
- other bundled targets use `UPX 5.0.2`
