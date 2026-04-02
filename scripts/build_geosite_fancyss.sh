#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${REPO_ROOT}/rules_ng2/site"
OUT_DIR="${REPO_ROOT}/rules_ng2/dat"
PKG_DIR="${REPO_ROOT}/fancyss/ss/rules_ng2/dat"
OUT_FILE="${OUT_DIR}/geosite.dat"
BASE_DIR="${REPO_ROOT}/.build_geodata"
WORK_DIR="${BASE_DIR}/domain-list-community"
DLC_REPO="https://github.com/v2fly/domain-list-community.git"
GO_BIN="$("${SCRIPT_DIR}/ensure_local_go.sh")"

command -v git >/dev/null 2>&1 || { echo "missing dependency: git" >&2; exit 1; }
[ -d "${SRC_DIR}" ] || { echo "missing source dir: ${SRC_DIR}" >&2; exit 1; }
[ -x "${GO_BIN}" ] || { echo "missing go toolchain: ${GO_BIN}" >&2; exit 1; }

mkdir -p "${OUT_DIR}" "${PKG_DIR}" "${BASE_DIR}"

if [ ! -d "${WORK_DIR}/.git" ]; then
	git clone "${DLC_REPO}" "${WORK_DIR}" >/dev/null 2>&1
fi
cd "${WORK_DIR}"
git fetch --prune origin >/dev/null 2>&1 || true
git checkout -f master >/dev/null 2>&1 || true
git reset --hard origin/master >/dev/null 2>&1 || git reset --hard >/dev/null 2>&1
git clean -fdqx >/dev/null 2>&1 || true
mkdir -p "${BASE_DIR}/geosite_data"
rm -f "${BASE_DIR}/geosite_data/"*.txt
for src in "${SRC_DIR}"/*.txt
do
	[ -f "${src}" ] || continue
	cp -f "${src}" "${BASE_DIR}/geosite_data/$(basename "${src}" .txt)"
done
(
	cd "${WORK_DIR}"
	PATH="$(dirname "${GO_BIN}"):${PATH}" "${GO_BIN}" run ./ --datapath="${BASE_DIR}/geosite_data" --outputdir="${OUT_DIR}" --outputname="geosite.dat" >/dev/null
)
cp -f "${OUT_FILE}" "${PKG_DIR}/geosite.dat"

echo "built ${OUT_FILE}"
