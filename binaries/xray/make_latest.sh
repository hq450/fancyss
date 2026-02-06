#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "$BASH_SOURCE[0]")" && pwd)"
base_dir="${DIR}/.build_xray"
mkdir -p "${base_dir}"

GO_VERSION="1.25.6"

BUILD_REF="tag" # tag | main
case "${1-}" in
	--main|main)
		BUILD_REF="main"
		shift
		;;
	--help|-h)
		cat <<-EOF
		Usage:
		  $(basename "$0")            # build latest tag (full build)
		  $(basename "$0") --main     # build latest commit of main (full build)
		EOF
		exit 0
		;;
esac

echo "-----------------------------------------------------------------"

# prepare golang (local toolchain under .build_xray/)
if [ ! -x "${base_dir}/go/bin/go" ]; then
	[ ! -f "${base_dir}/go${GO_VERSION}.linux-amd64.tar.gz" ] && \
		wget "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz" -O "${base_dir}/go${GO_VERSION}.linux-amd64.tar.gz"
	tar -C "${base_dir}" -xzf "${base_dir}/go${GO_VERSION}.linux-amd64.tar.gz"
fi

export PATH="${base_dir}/go/bin:${PATH}"
go version

echo "-----------------------------------------------------------------"

# get Xray-core
if [ ! -d "${base_dir}/Xray-core/.git" ]; then
	echo "Clone XTLS/Xray-core repo..."
	git clone https://github.com/XTLS/Xray-core.git "${base_dir}/Xray-core"
fi

cd "${base_dir}/Xray-core"
git reset --hard
git clean -fdqx

git checkout -f main
git fetch --prune origin || true
git fetch --tags origin || true
git pull --ff-only || git pull || echo "WARNING: git pull failed, continue with existing local repo state..."

if [ "${BUILD_REF}" = "tag" ]; then
	# Latest tag, version-sort aware (v26.1.13 > v25.12.8)
	VERSIONTAG="$(git tag -l 'v*' --sort=-v:refname | head -n 1)"
	[ -z "${VERSIONTAG}" ] && VERSIONTAG="$(git describe --abbrev=0 --tags)"
	echo "Checkout latest tag: ${VERSIONTAG}"
	git checkout -f "${VERSIONTAG}"
else
	echo "Checkout latest main commit"
	git checkout -f main
	git pull --ff-only || git pull || echo "WARNING: git pull failed, continue with existing local repo state..."
	# For folder naming, still use the nearest tag as the version prefix.
	VERSIONTAG="$(git tag -l 'v*' --sort=-v:refname | head -n 1)"
	[ -z "${VERSIONTAG}" ] && VERSIONTAG="$(git describe --abbrev=0 --tags 2>/dev/null || true)"
	[ -z "${VERSIONTAG}" ] && VERSIONTAG="v0.0.0"
fi

COMMITHASH="$(git rev-parse --short=7 HEAD)"
OUTDIR="${VERSIONTAG}-${COMMITHASH}"

echo "Build ref   : ${BUILD_REF}"
echo "Version tag : ${VERSIONTAG}"
echo "Commit hash : ${COMMITHASH}"
echo "Output dir  : ${OUTDIR}"

rm -rf "${base_dir:?}/${OUTDIR}"
mkdir -p "${base_dir:?}/${OUTDIR}"

# build xray (full build)
build_one() {
	local arch="$1"
	local GOARM=""
	local GOARCH=""

	case "${arch}" in
		armv5)
			GOARM=5
			GOARCH=arm
			;;
		armv7)
			GOARM=7
			GOARCH=arm
			;;
		arm64)
			GOARM=""
			GOARCH=arm64
			;;
		*)
			echo "Unknown arch: ${arch}" >&2
			exit 1
			;;
	esac

	local TMP
	TMP="$(mktemp -d)"
	trap 'rm -rf "${TMP}"' RETURN

	local LDFLAGS="-s -w -buildid="
	echo "Compile xray ${arch} GOARM=${GOARM:-} GOARCH=${GOARCH}..."
	env CGO_ENABLED=0 GOOS=linux GOARM="${GOARM}" GOARCH="${GOARCH}" \
		go build -v -o "${TMP}/xray_${arch}" -trimpath -ldflags "${LDFLAGS}" ./main

	cp -f "${TMP}/xray_${arch}" "${base_dir}/${OUTDIR}/"
}

compress_and_finalize() {
	echo "-----------------------------------------------------------------"
	ls -l "${base_dir}/${OUTDIR}/"*
	echo "-----------------------------------------------------------------"

	# Keep existing UPX policy:
	# - arm64/armv7: upx-5.0.2
	# - armv5:       upx-4.2.4
	upx-5.0.2 --lzma --ultra-brute "${base_dir}/${OUTDIR}/xray_arm64"
	upx-5.0.2 --lzma --ultra-brute "${base_dir}/${OUTDIR}/xray_armv7"
	upx-4.2.4 --lzma --ultra-brute "${base_dir}/${OUTDIR}/xray_armv5"

	upx-5.0.2 -t "${base_dir}/${OUTDIR}/xray_arm64"
	upx-5.0.2 -t "${base_dir}/${OUTDIR}/xray_armv7"
	upx-4.2.4 -t "${base_dir}/${OUTDIR}/xray_armv5"

	(
		cd "${base_dir}/${OUTDIR}"
		md5sum * > md5sum.txt
	)

	rm -rf "${DIR:?}/${OUTDIR}"
	mv -f "${base_dir}/${OUTDIR}" "${DIR}/"

	# Keep existing convention file name, but store the folder name.
	# NOTE: This becomes "vX.Y.Z-<sha>" (as requested).
	if [ "${BUILD_REF}" = "tag" ]; then
		echo -n "${OUTDIR}" > "${DIR}/latest_2.txt"
	else
		echo -n "${OUTDIR}" > "${DIR}/latest_2_main.txt"
	fi
}

build_one armv5
build_one armv7
build_one arm64
compress_and_finalize

echo "done: ${DIR}/${OUTDIR}"
