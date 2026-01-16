#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_BASE="$(cd "${SRC_DIR}/.." && pwd)"

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "error: missing command: $1" >&2
		exit 127
	fi
}

require_cmd make
require_cmd md5sum
require_cmd upx-4.2.4
require_cmd upx-5.0.2

GIT_SHA="nogit"
if command -v git >/dev/null 2>&1; then
	REPO_ROOT="$(git -C "${SRC_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"
	if [ -n "${REPO_ROOT}" ]; then
		GIT_SHA="$(git -C "${REPO_ROOT}" rev-parse --short=7 HEAD 2>/dev/null || echo nogit)"
	fi
fi
BUILD_DATE="$(date +%Y%m%d)"
OUT_DIR="${OUT_BASE}/v${BUILD_DATE}-${GIT_SHA}"

COMMON_CFLAGS="-Os -pipe -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables -Wall"
COMMON_LDFLAGS="-Wl,--gc-sections -s"

mkdir -p "${OUT_DIR}"

build_one() {
	local name="$1"
	local toolchain_base="$2"
	local toolchain_prefix="$3"
	local out_name="$4"
	local upx_bin="$5"
	local extra_ldflags="${6-}"
	local extra_env="${7-}"

	local cc="${toolchain_base}/${toolchain_prefix}-gcc"
	if [ ! -x "${cc}" ]; then
		echo "error: compiler not found: ${cc}" >&2
		exit 1
	fi

	echo "== build ${name} (${out_name}) =="
	(
		cd "${SRC_DIR}"
		eval "${extra_env:-:}"
		make clean
		make CC="${cc}" CFLAGS="${COMMON_CFLAGS}" LDFLAGS="${COMMON_LDFLAGS} ${extra_ldflags}"
		cp -f dnsclient "${OUT_DIR}/${out_name}"
	)

	chmod +x "${OUT_DIR}/${out_name}"
	local upx_out=""
	if ! upx_out="$("${upx_bin}" --lzma --ultra-brute "${OUT_DIR}/${out_name}" 2>&1)"; then
		# Very small binaries may be reported as NotCompressible by UPX; keep original.
		if echo "${upx_out}" | grep -q "NotCompressibleException"; then
			echo "warning: ${out_name} not compressible by ${upx_bin}, keep original"
		else
			echo "${upx_out}" >&2
			exit 1
		fi
	else
		"${upx_bin}" -t "${OUT_DIR}/${out_name}" >/dev/null
	fi
}

# arm (uclibc) - upx-4.2.4
build_one \
	arm \
	/opt/brcm-arm/bin \
	arm-brcm-linux-uclibcgnueabi \
	dnsclient_arm \
	upx-4.2.4 \
	"" \
	'export LD_LIBRARY_PATH="/opt/brcm-arm/lib:/opt/brcm-arm/arm-brcm-linux-uclibcgnueabi/lib"'

# hnd (glibc) - upx-5.0.2
build_one \
	hnd \
	/opt/toolchains/crosstools-arm-gcc-5.3-linux-4.1-glibc-2.22-binutils-2.25/usr/bin \
	arm-buildroot-linux-gnueabi \
	dnsclient_hnd \
	upx-5.0.2

# hndv8 (aarch64 glibc, prefer static) - upx-5.0.2
build_one \
	hndv8 \
	/opt/toolchains/crosstools-aarch64-gcc-5.3-linux-4.1-glibc-2.22-binutils-2.25/usr/bin \
	aarch64-buildroot-linux-gnu \
	dnsclient_hndv8 \
	upx-5.0.2 \
	"-static"

# mtk (aarch64 musl) - upx-5.0.2
build_one \
	mtk \
	/opt/openwrt-gcc840_musl.aarch64/bin \
	aarch64-openwrt-linux-musl \
	dnsclient_mtk \
	upx-5.0.2 \
	"" \
	'export STAGING_DIR=/opt/openwrt-gcc840_musl.aarch64'

# qca (arm uclibc) - upx-5.0.2
build_one \
	qca \
	/opt/openwrt-gcc463.arm/bin \
	arm-openwrt-linux-uclibcgnueabi \
	dnsclient_qca \
	upx-5.0.2 \
	"" \
	'export STAGING_DIR=/opt/openwrt-gcc463.arm'

# ipq32 (arm musl) - upx-5.0.2
build_one \
	ipq32 \
	/opt/openwrt-gcc750_musl1124.arm/bin \
	arm-openwrt-linux \
	dnsclient_ipq32 \
	upx-5.0.2 \
	"" \
	'export STAGING_DIR=/opt/openwrt-gcc750_musl1124.arm'

# ipq64 (aarch64 musl) - upx-5.0.2
build_one \
	ipq64 \
	/opt/openwrt-gcc750_musl1124.aarch64/bin \
	aarch64-openwrt-linux \
	dnsclient_ipq64 \
	upx-5.0.2 \
	"" \
	'export STAGING_DIR=/opt/openwrt-gcc750_musl1124.aarch64'

(cd "${OUT_DIR}" && md5sum dnsclient_* > md5sum.txt)
echo -n "$(basename "${OUT_DIR}")" > "${OUT_BASE}/latest.txt"

echo "done: ${OUT_DIR}"
