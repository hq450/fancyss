#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '\r\n' < "$ROOT_DIR/VERSION")"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"
FANCYSS_BINARIES_ROOT="${FANCYSS_BINARIES_ROOT:-}"
LOCAL_CACHE_BASE="${LOCAL_CACHE_BASE:-$ROOT_DIR/.zig-cache/release}"
GLOBAL_CACHE_DIR="${GLOBAL_CACHE_DIR:-$ROOT_DIR/.zig-cache/release-global}"
WITH_UPX=1
BUILT_FILES=()

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

resolve_fancyss_binaries_dir() {
    local subdir="$1"
    local fancyss_root=""

    if [[ -n "${FANCYSS_BINARIES_ROOT:-}" ]]; then
        printf '%s/%s\n' "${FANCYSS_BINARIES_ROOT%/}" "$subdir"
        return 0
    fi

    fancyss_root="$(cd "$ROOT_DIR/../.." && pwd)"
    if [[ -d "$fancyss_root/binaries" ]]; then
        printf '%s/binaries/%s\n' "$fancyss_root" "$subdir"
        return 0
    fi

    return 1
}

sync_built_files_to_binaries() {
    local subdir="$1"
    shift
    local binaries_dir=""
    local artifact=""
    local prefix=""
    local checksum="SHA256SUMS-v${VERSION}"
    local checksum_tmp=""
    local existing_artifacts=()
    local known_artifacts=()
    local filename=""
    local seen=0

    binaries_dir="$(resolve_fancyss_binaries_dir "$subdir")" || return 0
    mkdir -p "$binaries_dir"

    for artifact in "${BUILT_FILES[@]}"; do
        cp -f "$OUT_DIR/$artifact" "$binaries_dir/"
        chmod 0755 "$binaries_dir/$artifact"
    done

    if [[ -f "$binaries_dir/$checksum" ]]; then
        while read -r _ filename; do
            [[ -n "${filename:-}" && -f "$binaries_dir/$filename" ]] && existing_artifacts+=("$filename")
        done < "$binaries_dir/$checksum"
    fi

    for prefix in "$@"; do
        while IFS= read -r artifact; do
            known_artifacts+=("$artifact")
        done < <(find "$binaries_dir" -maxdepth 1 -type f -name "${prefix}-v${VERSION}-linux-*" -printf '%f\n' | sort)
    done

    checksum_tmp="$(mktemp "$binaries_dir/.${checksum}.tmp.XXXXXX")"
    (
        cd "$binaries_dir"
        for artifact in "${existing_artifacts[@]}"; do
            sha256sum "$artifact"
        done
        for artifact in "${known_artifacts[@]}"; do
            seen=0
            for filename in "${existing_artifacts[@]}"; do
                if [[ "$artifact" == "$filename" ]]; then
                    seen=1
                    break
                fi
            done
            if [[ "$seen" == "0" ]]; then
                sha256sum "$artifact"
            fi
        done
    ) > "$checksum_tmp"
    mv -f "$checksum_tmp" "$binaries_dir/$checksum"

    echo "Synced final artifacts to: $binaries_dir"
}

build_target() {
    local name="$1"
    local zig_target="$2"
    local cpu="$3"
    local output="$OUT_DIR/webtest-tool-v${VERSION}-linux-$name"
    local ctl_output="$OUT_DIR/webtestctl-v${VERSION}-linux-$name"
    local local_cache_dir="$LOCAL_CACHE_BASE/$name"
    local upx_bin=""

    mkdir -p "$OUT_DIR" "$local_cache_dir" "$GLOBAL_CACHE_DIR"
    rm -f "$output" "$ctl_output"
    rm -rf "$ROOT_DIR/zig-out"

    echo "==> building $name ($zig_target, cpu=$cpu)"
    ZIG_LOCAL_CACHE_DIR="$local_cache_dir" \
    ZIG_GLOBAL_CACHE_DIR="$GLOBAL_CACHE_DIR" \
    "$ZIG_BIN" build \
        -Dtarget="$zig_target" \
        -Dcpu="$cpu" \
        -Doptimize=ReleaseSmall

    cp -f "$ROOT_DIR/zig-out/bin/webtest-tool" "$output"
    cp -f "$ROOT_DIR/zig-out/bin/webtestctl" "$ctl_output"

    if [[ "$WITH_UPX" == "1" ]]; then
        if [[ "$name" == "x86_64" ]]; then
            echo "==> skipping UPX for $name (host helper only)"
        else
            upx_bin="$UPX_BIN"
            echo "==> packing $name with $(basename "$upx_bin")"
            "$upx_bin" --lzma --ultra-brute "$output"
            "$upx_bin" --lzma --ultra-brute "$ctl_output"
        fi
    fi

    file "$output"
    stat -c '%n %s bytes' "$output"
    file "$ctl_output"
    stat -c '%n %s bytes' "$ctl_output"
    BUILT_FILES+=("$(basename "$output")" "$(basename "$ctl_output")")
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
    TARGETS=(armv5te armv7a armv7hf aarch64 x86_64)
fi

ZIG_BIN="$(find_latest_zig)"
if [[ "$WITH_UPX" == "1" ]]; then
    if [[ -n "${UPX:-}" ]]; then
        UPX_BIN="$UPX"
    elif command -v upx-5.0.2 >/dev/null 2>&1; then
        UPX_BIN="$(command -v upx-5.0.2)"
    elif command -v upx >/dev/null 2>&1; then
        UPX_BIN="$(command -v upx)"
    else
        echo "error: UPX not found. Use --no-upx to skip compression." >&2
        exit 1
    fi
fi

mkdir -p "$OUT_DIR"
echo "Version: $VERSION"
echo "Using Zig: $ZIG_BIN ($("$ZIG_BIN" version))"
if [[ "$WITH_UPX" == "1" ]]; then
    echo "Using UPX: $UPX_BIN ($("$UPX_BIN" --version | sed -n '1p'))"
else
    echo "UPX: disabled (--no-upx)"
fi
echo

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

(
    cd "$OUT_DIR"
    sha256sum "${BUILT_FILES[@]}" > "SHA256SUMS-v${VERSION}"
)

sync_built_files_to_binaries "webtest-tool" "webtest-tool" "webtestctl"
