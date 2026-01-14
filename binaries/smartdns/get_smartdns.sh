#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

UPX5="${UPX5:-upx-5.0.2}"
UPX4="${UPX4:-upx-4.2.4}"

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "error: missing command: $1" >&2
		exit 127
	fi
}

require_cmd curl
require_cmd md5sum
require_cmd awk
require_cmd sed
require_cmd "${UPX5}"
require_cmd "${UPX4}"

API_URL="${API_URL:-https://api.github.com/repos/pymumu/smartdns/releases/latest}"

echo "fetching latest smartdns release info ..."
JSON="$(curl -fsSL --retry 3 --retry-delay 1 "${API_URL}")"

TAG="$(printf '%s' "${JSON}" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
if [ -z "${TAG}" ]; then
	echo "error: failed to parse tag_name from GitHub API response" >&2
	exit 1
fi

VER="${TAG}"
VER="${VER#Release}"
VER="${VER#v}"
if [ -z "${VER}" ]; then
	VER="${TAG}"
fi

OUT_DIR="v${VER}"
if [ -d "${OUT_DIR}" ]; then
	echo "already exists: ${SCRIPT_DIR}/${OUT_DIR}"
	exit 0
fi

get_asset_url() {
	local asset_name="$1"
	printf '%s\n' "${JSON}" | awk -v name="${asset_name}" '
		$0 ~ ("\"name\": \"" name "\"") { found=1; next }
		found && /"browser_download_url":/ {
			sub(/.*"browser_download_url":[[:space:]]*"/, "");
			sub(/".*/, "");
			print;
			exit
		}
	'
}

URL_AARCH64="$(get_asset_url "smartdns-aarch64")"
URL_ARM="$(get_asset_url "smartdns-arm")"

if [ -z "${URL_AARCH64}" ] || [ -z "${URL_ARM}" ]; then
	echo "error: failed to locate asset download urls (smartdns-aarch64 / smartdns-arm)" >&2
	exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

echo "downloading smartdns-aarch64 ..."
curl -fL --retry 3 --retry-delay 1 --progress-bar -o "${TMP_DIR}/smartdns-aarch64" "${URL_AARCH64}"
echo "downloading smartdns-arm ..."
curl -fL --retry 3 --retry-delay 1 --progress-bar -o "${TMP_DIR}/smartdns-arm" "${URL_ARM}"

chmod +x "${TMP_DIR}/smartdns-aarch64" "${TMP_DIR}/smartdns-arm"

mkdir -p "${OUT_DIR}"

cp -f "${TMP_DIR}/smartdns-aarch64" "${OUT_DIR}/smartdns_arm64"
cp -f "${TMP_DIR}/smartdns-arm" "${OUT_DIR}/smartdns_armv7"
cp -f "${TMP_DIR}/smartdns-arm" "${OUT_DIR}/smartdns_armv5"

chmod +x "${OUT_DIR}/smartdns_arm64" "${OUT_DIR}/smartdns_armv7" "${OUT_DIR}/smartdns_armv5"

echo "compressing with ${UPX5}: smartdns_arm64"
"${UPX5}" --lzma --ultra-brute "${OUT_DIR}/smartdns_arm64"
echo "compressing with ${UPX5}: smartdns_armv7"
"${UPX5}" --lzma --ultra-brute "${OUT_DIR}/smartdns_armv7"
echo "compressing with ${UPX4}: smartdns_armv5"
"${UPX4}" --lzma --ultra-brute "${OUT_DIR}/smartdns_armv5"

(cd "${OUT_DIR}" && md5sum smartdns_arm64 smartdns_armv7 smartdns_armv5 > md5sum.txt)

echo "done: ${SCRIPT_DIR}/${OUT_DIR}"
