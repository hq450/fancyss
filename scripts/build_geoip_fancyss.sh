#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${REPO_ROOT}/rules_ng2/ip"
OUT_DIR="${REPO_ROOT}/rules_ng2/dat"
PKG_DIR="${REPO_ROOT}/fancyss/ss/rules_ng2/dat"
OUT_FILE="${OUT_DIR}/geoip.dat"
BASE_DIR="${REPO_ROOT}/.build_geodata"
WORK_DIR="${BASE_DIR}/geoip"
GEOIP_REPO="https://github.com/v2fly/geoip.git"
GO_BIN="$("${SCRIPT_DIR}/ensure_local_go.sh")"

command -v git >/dev/null 2>&1 || { echo "missing dependency: git" >&2; exit 1; }
[ -d "${SRC_DIR}" ] || { echo "missing source dir: ${SRC_DIR}" >&2; exit 1; }
[ -x "${GO_BIN}" ] || { echo "missing go toolchain: ${GO_BIN}" >&2; exit 1; }

mkdir -p "${OUT_DIR}" "${PKG_DIR}" "${BASE_DIR}"

if [ ! -d "${WORK_DIR}/.git" ]; then
	git clone "${GEOIP_REPO}" "${WORK_DIR}" >/dev/null 2>&1
fi
cd "${WORK_DIR}"
git fetch --prune origin >/dev/null 2>&1 || true
git checkout -f master >/dev/null 2>&1 || true
git reset --hard origin/master >/dev/null 2>&1 || git reset --hard >/dev/null 2>&1
git clean -fdqx >/dev/null 2>&1 || true
mkdir -p "${WORK_DIR}/data"
rm -f "${WORK_DIR}/data/"*.txt
for src in "${SRC_DIR}"/*.txt
do
	[ -f "${src}" ] || continue
	cp -f "${src}" "${WORK_DIR}/data/$(basename "${src}" .txt).txt"
done
cat > "${WORK_DIR}/config.fancyss.json" <<-EOF
{
  "input": [
    {
      "type": "text",
      "action": "add",
      "args": {
        "inputDir": "./data"
      }
    }
  ],
  "output": [
    {
      "type": "v2rayGeoIPDat",
      "action": "output",
      "args": {
        "outputDir": "${OUT_DIR}",
        "outputName": "geoip.dat"
      }
    }
  ]
}
EOF
(
	cd "${WORK_DIR}"
	PATH="$(dirname "${GO_BIN}"):${PATH}" "${GO_BIN}" run ./ -c ./config.fancyss.json >/dev/null
)
cp -f "${OUT_FILE}" "${PKG_DIR}/geoip.dat"

echo "built ${OUT_FILE}"
