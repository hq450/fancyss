#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

UPX5="${UPX5:-upx-5.0.2}"
UPX4="${UPX4:-upx-4.2.4}"
API_URL="${API_URL:-https://api.github.com/repos/Itsusinn/tuic/releases/latest}"

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "error: missing command: $1" >&2
		exit 127
	fi
}

require_cmd curl
require_cmd python3
require_cmd md5sum
require_cmd "${UPX5}"
require_cmd "${UPX4}"

echo "fetching latest tuic release info ..."
JSON="$(curl -fsSL --retry 3 --retry-delay 1 "${API_URL}")"

TAG="$(JSON_PAYLOAD="${JSON}" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_PAYLOAD"])
print(data["tag_name"])
PY
)"

if [ -z "${TAG}" ]; then
	echo "error: failed to parse tag_name from GitHub API response" >&2
	exit 1
fi

VER="${TAG#v}"
OUT_DIR="v${VER}"

get_asset_url() {
	local asset_name="$1"
	JSON_PAYLOAD="${JSON}" ASSET_NAME="${asset_name}" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["JSON_PAYLOAD"])
name = os.environ["ASSET_NAME"]

for asset in data.get("assets", []):
    if asset.get("name") == name:
        print(asset.get("browser_download_url", ""))
        break
PY
}

ASSET_ARM64="tuic-client-aarch64-linux-musl"
ASSET_ARMV7="tuic-client-armv7-linux-musl"

URL_ARM64="$(get_asset_url "${ASSET_ARM64}")"
URL_ARMV7="$(get_asset_url "${ASSET_ARMV7}")"

if [ -z "${URL_ARM64}" ] || [ -z "${URL_ARMV7}" ]; then
	echo "error: failed to locate one or more tuic-client asset download urls" >&2
	exit 1
fi

if [ -d "${OUT_DIR}" ]; then
	echo "already exists: ${SCRIPT_DIR}/${OUT_DIR}"
	echo -n "${OUT_DIR}" > latest.txt
	exit 0
fi

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

echo "downloading ${ASSET_ARM64} ..."
curl -fL --retry 3 --retry-delay 1 --progress-bar -o "${TMP_DIR}/tuic-client_arm64" "${URL_ARM64}"
echo "downloading ${ASSET_ARMV7} ..."
curl -fL --retry 3 --retry-delay 1 --progress-bar -o "${TMP_DIR}/tuic-client_armv7" "${URL_ARMV7}"

chmod +x "${TMP_DIR}/tuic-client_arm64" "${TMP_DIR}/tuic-client_armv7"

mkdir -p "${OUT_DIR}"
cp -f "${TMP_DIR}/tuic-client_arm64" "${OUT_DIR}/tuic-client_arm64"
cp -f "${TMP_DIR}/tuic-client_armv7" "${OUT_DIR}/tuic-client_armv7"

echo "compressing with ${UPX5}: tuic-client_arm64"
"${UPX5}" --lzma --ultra-brute "${OUT_DIR}/tuic-client_arm64"
echo "compressing with ${UPX4}: tuic-client_armv7"
"${UPX4}" --lzma --ultra-brute "${OUT_DIR}/tuic-client_armv7"

"${UPX5}" -t "${OUT_DIR}/tuic-client_arm64" >/dev/null
"${UPX4}" -t "${OUT_DIR}/tuic-client_armv7" >/dev/null

(cd "${OUT_DIR}" && md5sum tuic-client_arm64 tuic-client_armv7 > md5sum.txt)

echo -n "${OUT_DIR}" > latest.txt
echo "done: ${SCRIPT_DIR}/${OUT_DIR}"
