#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
LOCAL_CACHE_BASE="${LOCAL_CACHE_BASE:-$ROOT_DIR/.zig-cache/release}"
GLOBAL_CACHE_DIR="${GLOBAL_CACHE_DIR:-$ROOT_DIR/.zig-cache/release-global}"
WITH_UPX=1

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

find_required_command() {
    local env_value="$1"
    local command_name="$2"
    local label="$3"

    if [[ -n "$env_value" ]]; then
        printf '%s\n' "$env_value"
        return 0
    fi

    if command -v "$command_name" >/dev/null 2>&1; then
        command -v "$command_name"
        return 0
    fi

    echo "error: ${label} not found. Set the environment variable or add ${command_name} to PATH." >&2
    exit 1
}

require_executable() {
    local path="$1"
    local name="$2"
    if [[ ! -x "$path" ]]; then
        echo "error: ${name} not found or not executable: $path" >&2
        exit 1
    fi
}

require_upx_version() {
    local path="$1"
    local expected="$2"
    local actual

    actual="$("$path" --version | sed -n '1s/^upx //p')"
    if [[ "$actual" != "$expected" ]]; then
        echo "error: expected UPX $expected at $path, got ${actual:-unknown}" >&2
        exit 1
    fi
}

build_target() {
    local name="$1"
    local zig_target="$2"
    local cpu="$3"
    local output="$OUT_DIR/sub-tool-v${VERSION}-linux-$name"
    local local_cache_dir="$LOCAL_CACHE_BASE/$name"
    local upx_bin=""

    mkdir -p "$OUT_DIR" "$local_cache_dir" "$GLOBAL_CACHE_DIR"
    rm -f "$output"

    echo "==> building $name ($zig_target, cpu=$cpu)"
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
        case "$name" in
            armv5te) upx_bin="$UPX_4_2_4" ;;
            *) upx_bin="$UPX_5_0_2" ;;
        esac
        echo "==> packing $name with $(basename "$upx_bin")"
        "$upx_bin" --lzma --ultra-brute "$output"
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
    UPX_4_2_4="$(find_required_command "${UPX_4_2_4:-}" "upx-4.2.4" "UPX 4.2.4")"
    UPX_5_0_2="$(find_required_command "${UPX_5_0_2:-}" "upx-5.0.2" "UPX 5.0.2")"
    require_executable "$UPX_4_2_4" "UPX 4.2.4"
    require_executable "$UPX_5_0_2" "UPX 5.0.2"
    require_upx_version "$UPX_4_2_4" "4.2.4"
    require_upx_version "$UPX_5_0_2" "5.0.2"
fi
mkdir -p "$OUT_DIR"

echo "Version: $VERSION"
echo "Using Zig: $ZIG_BIN ($("$ZIG_BIN" version))"
if [[ "$WITH_UPX" == "1" ]]; then
    echo "Using UPX 4.2.4: $UPX_4_2_4"
    echo "Using UPX 5.0.2: $UPX_5_0_2"
else
    echo "UPX: disabled (--no-upx)"
fi
echo

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
