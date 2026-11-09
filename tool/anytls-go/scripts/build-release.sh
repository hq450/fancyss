#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
GO="${GO:-go}"
targets=()
for arg in "$@"; do
  case "$arg" in
    --no-upx) ;;
    --upx) echo "UPX is not used for the Go runtime" >&2; exit 1 ;;
    aarch64|armv5te|armv7a|armv7hf|x86_64) targets+=("$arg") ;;
    *) echo "unsupported argument: $arg" >&2; exit 1 ;;
  esac
done
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=(aarch64 armv5te armv7a armv7hf x86_64)
fi
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
cd "$ROOT_DIR"
for target in "${targets[@]}"; do
  arch=arm
  arm=7
  case "$target" in
    aarch64) arch=arm64 ;;
    armv5te) arm=5 ;;
    armv7a) arm=7,softfloat ;;
    armv7hf) arm=7,hardfloat ;;
    x86_64) arch=amd64 ;;
  esac
  output="$OUT_DIR/anytls-go-v$VERSION-linux-$target"
  env CGO_ENABLED=0 GOOS=linux GOARCH="$arch" GOARM="$arm" GOAMD64=v1 \
    "$GO" build -mod=readonly -trimpath -ldflags="-s -w -buildid= -X main.version=$VERSION" -o "$output" .
  printf 'built %s\n' "$output"
done
cd "$OUT_DIR"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum anytls-go-v"$VERSION"-linux-* > "SHA256SUMS-v$VERSION"
else
  shasum -a 256 anytls-go-v"$VERSION"-linux-* > "SHA256SUMS-v$VERSION"
fi
