# sub-tool binaries

Source project:
- `tool/sub-tool`

Current bundled version:
- `v0.1.8`

Purpose:
- lightweight subscription parsing / filtering / diff tool for fancyss
- used by `ss_node_subscribe.sh` to offload subscription hot paths

Bundled architectures:
- `aarch64`
- `armv7a`
- `armv7hf`
- `armv5te`
- `x86_64`

Packaging note:
- release artifacts should be built by `tool/sub-tool/scripts/build-release.sh`
- UPX is enabled by default
- `armv5te` should use `UPX 4.2.4`
- other targets should use `UPX 5.0.2`

Current build chain integration:
- `build.sh` copies the bundled binaries into `fancyss/bin-*`
- router-side package export in `ss_conf.sh` will include `/koolshare/bin/sub-tool` when present
