#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
LOCAL_CACHE_BASE="${LOCAL_CACHE_BASE:-$ROOT_DIR/.zig-cache/release}"
GLOBAL_CACHE_DIR="${GLOBAL_CACHE_DIR:-$ROOT_DIR/.zig-cache/release-global}"
WITH_UPX=1
UPX_BIN=""

print_usage() {
    cat <<'EOF'
Usage:
  bash ./scripts/build-release.sh [--no-upx] [target...]

Targets:
  x86_64 armv5te armv7a armv7hf aarch64

Options:
  --no-upx      Build without UPX compression
  --upx         Build with UPX compression
  -h, --help    Show this help
EOF
}

find_latest_zig() {
    local candidates=()
    local path
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

find_upx_bin() {
    local candidate=""
    local version=""
    if [[ -n "${UPX_BIN:-}" && -x "${UPX_BIN}" ]]; then
        printf '%s\n' "${UPX_BIN}"
        return 0
    fi
    if command -v upx >/dev/null 2>&1; then
        candidate="$(command -v upx)"
        version="$("$candidate" -V 2>/dev/null | awk '/^UPX / {print $2; exit}')"
        if [[ -n "${version}" ]] && [[ "${version}" =~ ^([0-9]+)\. ]]; then
            if (( BASH_REMATCH[1] >= 5 )); then
                printf '%s\n' "${candidate}"
                return 0
            fi
        fi
    fi
    echo "error: UPX >= 5 not found; rerun with --no-upx or set UPX_BIN=/path/to/upx" >&2
    exit 1
}

build_target() {
    local name="$1"
    local zig_target="$2"
    local cpu="$3"
    local output="$OUT_DIR/sub-tool-v${VERSION}-linux-$name"
    local local_cache_dir="$LOCAL_CACHE_BASE/$name"

    mkdir -p "$OUT_DIR" "$local_cache_dir" "$GLOBAL_CACHE_DIR"
    rm -f "$output"

    ZIG_LOCAL_CACHE_DIR="$local_cache_dir" \
    ZIG_GLOBAL_CACHE_DIR="$GLOBAL_CACHE_DIR" \
    "$ZIG_BIN" build-exe "$ROOT_DIR/src/main.zig" \
        -O ReleaseSmall \
        -fstrip \
        -fsingle-threaded \
        -lc \
        -target "$zig_target" \
        -mcpu="$cpu" \
        -femit-bin="$output"

    if [[ "$WITH_UPX" == "1" ]]; then
        "$UPX_BIN" --lzma --ultra-brute "$output"
    fi

    file "$output"
    stat -c '%n %s bytes' "$output"
}

TARGETS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-upx)
            WITH_UPX=0
            shift
            ;;
        --upx)
            WITH_UPX=1
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            TARGETS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    TARGETS=(x86_64 armv5te armv7a armv7hf aarch64)
fi

ZIG_BIN="$(find_latest_zig)"
if [[ "$WITH_UPX" == "1" ]]; then
    UPX_BIN="$(find_upx_bin)"
fi
mkdir -p "$OUT_DIR"

for target in "${TARGETS[@]}"; do
    case "$target" in
        x86_64) build_target x86_64 x86_64-linux-musl baseline ;;
        armv5te) build_target armv5te arm-linux-musleabi arm926ej_s ;;
        armv7a) build_target armv7a arm-linux-musleabi mpcorenovfp ;;
        armv7hf) build_target armv7hf arm-linux-musleabihf cortex_a9 ;;
        aarch64) build_target aarch64 aarch64-linux-musl generic ;;
        *) echo "unsupported target: $target" >&2; exit 1 ;;
    esac
    echo
done

(
    cd "$OUT_DIR"
    sha256sum "sub-tool-v${VERSION}-linux-"* > "SHA256SUMS-v${VERSION}"
)
