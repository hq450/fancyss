#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
LOCAL_CACHE_BASE="${LOCAL_CACHE_BASE:-$ROOT_DIR/.zig-cache/release}"
GLOBAL_CACHE_DIR="${GLOBAL_CACHE_DIR:-$ROOT_DIR/.zig-cache/release-global}"

find_latest_zig() {
    local candidates=()
    if [[ -n "${ZIG:-}" ]]; then
        candidates+=("$ZIG")
    fi
    if command -v zig >/dev/null 2>&1; then
        candidates+=("$(command -v zig)")
    fi
    while IFS= read -r path; do
        candidates+=("$path")
    done < <(find /tmp/zig "$HOME/.local/zig" -maxdepth 3 -type f -name zig 2>/dev/null | sort -V)
    [[ ${#candidates[@]} -gt 0 ]] || { echo "error: Zig not found" >&2; exit 1; }
    printf '%s\n' "${candidates[@]}" | awk 'NF' | tail -n 1
}

build_target() {
    local name="$1"
    local zig_target="$2"
    local cpu="$3"
    local local_cache_dir="$LOCAL_CACHE_BASE/$name"

    mkdir -p "$OUT_DIR" "$local_cache_dir" "$GLOBAL_CACHE_DIR"
    rm -rf "$ROOT_DIR/zig-out"

    ZIG_LOCAL_CACHE_DIR="$local_cache_dir" \
    ZIG_GLOBAL_CACHE_DIR="$GLOBAL_CACHE_DIR" \
    "$ZIG_BIN" build \
        -Dtarget="$zig_target" \
        -Dcpu="$cpu" \
        -Doptimize=ReleaseSmall

    cp -f "$ROOT_DIR/zig-out/bin/webtest-tool" "$OUT_DIR/webtest-tool-v${VERSION}-linux-$name"
    cp -f "$ROOT_DIR/zig-out/bin/webtestctl" "$OUT_DIR/webtestctl-v${VERSION}-linux-$name"
}

TARGETS=("$@")
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=(armv5te armv7a armv7hf aarch64 x86_64)
fi

ZIG_BIN="$(find_latest_zig)"

for target in "${TARGETS[@]}"; do
    case "$target" in
        x86_64) build_target x86_64 x86_64-linux-musl baseline ;;
        armv5te) build_target armv5te arm-linux-musleabi arm1176jzf_s ;;
        armv7a) build_target armv7a arm-linux-musleabi mpcorenovfp ;;
        armv7hf) build_target armv7hf arm-linux-musleabihf cortex_a9 ;;
        aarch64) build_target aarch64 aarch64-linux-musl generic ;;
        *) echo "unsupported target: $target" >&2; exit 1 ;;
    esac
done
