# AnyTLS Go Compatibility Runtime

GPL-3.0-or-later. This runtime uses the pinned GPL-compatible
[`sing-anytls v0.0.13`](https://github.com/anytls/sing-anytls/tree/v0.0.13)
library, not the stock sample executable with hardcoded certificate bypass.

The package installs this adapter as `anytls-zig` to preserve the CLI/process
contract used by existing shell and compiled fancyss helpers. `--version`
reports `anytls-go` and the library version explicitly. No source Zig binary
is misidentified as a newer release.

## Runtime Guarantees And Limits

- Go network polling replaces the old 32 whole-session native-worker ceiling.
- At most 256 local connections and 256 tracked upstream transports by default.
  There is no unbounded application accept queue or thread-per-connection stack.
  Excess sockets are closed immediately. This is a finite capacity, not an
  unlimited-concurrency promise.
- Local SOCKS greeting and CONNECT parsing share a 10-second deadline.
- DNS, TCP and TLS setup share a context-aware 10-second transport deadline,
  using Go's resolver even in native builds.
- Both relay directions have a 10-second blocked-write deadline. Library control
  deadline clears cannot erase the hard bound of a write already in progress.
  Upstream session bootstrap
  writes also use that limit; the library's whole CreateProxy operation is not
  claimed to be one end-to-end 10-second transaction.
- Established idle reads have no short handshake timeout. TCP keepalive is
  enabled. An otherwise healthy, silent established tunnel may remain admitted
  until its peer closes or the configured total capacity is reached.
- The library reuses sessions, expires idle sessions after 30 seconds (checks
  every 6 seconds), and retains no minimum idle sessions. `-dr` disables reuse
  for controlled comparisons; it is not assumed to be a stability fix.
- Shutdown cancels setup, closes listeners/local sockets/all tracked transports,
  joins handlers, and closes the session client again after concurrent setup
  has drained. Relay completion interrupts the opposite copy direction.
  As in the existing Zig relay, TCP half-close is treated as full tunnel close;
  protocols that depend on a delayed response after a local half-close are not
  claimed as newly supported.
- The CLI sets a 64 MiB Go **soft GC target**, not a hard RSS guarantee. Admission
  limits are the hard connection bounds. Native/race builds have different RSS.
- Only TCP SOCKS CONNECT is supported. Existing fancyss UDP policy is unchanged.

Certificates are verified by default. `--verify` explicitly selects strict
verification; `--insecure` is the only certificate-bypass switch and does not
discard SNI. fancyss continues to pass its existing per-node TLS policy.
Passwords are loaded from the existing mode-0600 file; no password is logged
or required in process arguments. URI/inline-password options exist only for
compatibility; production startup uses `--password-file`.

## Build And Test

```sh
go test -race -count=1 ./...
go vet ./...
go build -o dist/anytls-zig-native .
python3 ../../tests/test_anytls_runtime.py -v
bash scripts/build-release.sh --no-upx
```

The black-box tests require Python with TLS 1.3 and OpenSSL on PATH. They use
only ephemeral loopback TLS peers, not accounts, subscriptions, or the router.
`ANYTLS_SOAK_SECONDS` controls the short CI soak duration, not a 24-hour result.
The Linux-only resource test waits for real idle-session cleanup and checks FD
recovery. CI also runs the black-box workloads with a race-instrumented binary.

Cross-builds require a maintained Go toolchain (CI pins Go 1.26.3) and disable
CGO. They target modern Linux; legacy Linux 2.6 packages retain original Zig.
See `doc/implementation/anytls_go_runtime.md` for package selection/rollback.
Router/kernel compatibility and a 24-hour real-node run still require separate
validation. This branch does not install anything on the live router.
