# Bounded AnyTLS Go Runtime Integration

## Contract And Scope

The Go wrapper in `tool/anytls-go` explicitly implements the existing
`anytls-zig` command-line contract, rather than substituting an incompatible
upstream CLI. Its installed filename remains `anytls-zig`: compiled webtest
and status tools hardcode that name, as do process detection and shutdown.
`--version` identifies the real backend as `anytls-go`, not Zig. The process
status page retains the compatibility name and displays the backend's version
without labeling every backend as Zig.

Production startup continues to pass `-server`, `-l`, optional `-sni`, and
exactly one of `--verify` or `--insecure`. Passwords are passed only through
`--password-file`, never as command-line values. `/tmp/anytls_pass` is recreated
under `umask 077` (mode 0600 before contents are written); noclobber refuses a
raced-in file or symlink, and a write failure stops startup. The file remains
available for client startup/restart; this is not a new credential store.

Only production AnyTLS and its associated ipt2socks use `run_bg_detached`:
`env -i PATH=... nohup ... </dev/null >/dev/null 2>&1 &`. Other protocols retain
their existing `run_bg` behavior. No firewall, subscription format, web UI,
webtest/status binary, or global background-launch behavior is redesigned.

The redundant `fss_refresh_airport_special_runtime_domain_files` call after
`fss_airport_dns_override_load` is removed from
`refresh_node_direct_domain_file`, applying the one-line fix from PR33902.

## Package Selection

`build.sh` defaults `ANYTLS_BACKEND` to `go`. It invokes
`tool/anytls-go/scripts/build-release.sh aarch64 armv7a armv7hf --no-upx` once
from binary synchronization; it does not build once per package variant.
Go artifacts are not UPX-compressed. The release script also supports named
targets and defaults to all its targets when none are supplied.

| Package platform | Default backend | Target |
| --- | --- | --- |
| mtk, hnd_v8, ipq64 | Go | aarch64 |
| ipq32, qca | Go | armv7a |
| hnd | Go | armv7hf |
| arm (legacy Linux 2.6) | Original Zig | armv5te |

The Go artifact naming contract is
`tool/anytls-go/dist/anytls-go-v0.1.0-linux-{aarch64,armv5te,armv7a,armv7hf,x86_64}`,
with version read from `tool/anytls-go/VERSION` (initially `0.1.0`). The wrapper
is copied to each selected package's `anytls-zig` path. armv5te and x86_64 Go
build targets do not imply that legacy arm packages switch to Go or that an
x86 package is introduced.

The existing Zig assets and architecture mapping remain the fallback source.
`ANYTLS_BACKEND=zig` selects Zig on every package platform and does not invoke
the Go build script. An unknown backend or failed Go build aborts packaging;
there is no silent fallback. Binary verification compares each executable
against the selected backend's artifact, including legacy arm's Zig artifact,
instead of comparing Go package contents against Zig assets.

## Kernel Compatibility And Rollback

The Go wrapper is a bounded modern-platform replacement, not a promise of
Linux 2.6 compatibility. Legacy arm keeps the original Zig runtime regardless
of backend selection. Successful cross-compilation alone does not establish
compatibility with a router's kernel, CPU, firmware, or available memory.

For a maintainer-controlled fallback package build, set `ANYTLS_BACKEND=zig`
in the existing packaging environment. Rebuild and verify the package with that
same selection; do not merely rename an arbitrary upstream executable.
Returning to the default Go build requires clearing that override (or setting
it to `go`). Restoring a previously validated offline package through the
normal installation workflow is the operational rollback; no live router
installation or rollback is performed by this change.

## Verification Boundary

`python3 tests/test_anytls_integration.py -v` runs extracted shell functions
against temporary fixtures, without sourcing build metadata or the build entry
point. It checks platform mapping, one mocked Go build invocation, Zig opt-out,
failure propagation, backend-aware binary verification, private password-file
creation, unchanged CLI/TLS arguments, and detached launch behavior. Shell
syntax checks cover the changed scripts. These fixtures are not real package
builds or production router tests.

Go unit tests cover admission/release, negotiation/setup/write deadlines,
certificate verification/SNI, cancellation and blocked relay cleanup. Black-box
tests cover 64/128 simultaneous healthy tunnels, 256/257 saturation, reconnect,
idle forwarding and short paced churn. Linux CI additionally verifies that idle
session file descriptors return to baseline after the 30-second idle timeout
and 6-second cleanup sweep. Hardware validation on the supported platform
families and a 24-hour stability run remain pending. No live deployment,
hardware compatibility, or 24-hour reliability result is claimed here.
