#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
BASE_DIR="${REPO_ROOT}/.build_geodata"
GO_VERSION="1.25.6"
OS_NAME="$(uname -s | tr 'A-Z' 'a-z')"
ARCH_NAME="$(uname -m)"
GO_ARCH=""
GO_TARBALL=""
GO_ROOT="${BASE_DIR}/go"
GO_BIN="${GO_ROOT}/bin/go"

case "${OS_NAME}" in
linux)
	;;
*)
	echo "unsupported host OS: ${OS_NAME}" >&2
	exit 1
	;;
esac

case "${ARCH_NAME}" in
x86_64|amd64)
	GO_ARCH="amd64"
	;;
aarch64|arm64)
	GO_ARCH="arm64"
	;;
*)
	echo "unsupported host arch: ${ARCH_NAME}" >&2
	exit 1
	;;
esac

mkdir -p "${BASE_DIR}"
GO_TARBALL="${BASE_DIR}/go${GO_VERSION}.${OS_NAME}-${GO_ARCH}.tar.gz"

if [ ! -x "${GO_BIN}" ]; then
	if [ ! -f "${GO_TARBALL}" ]; then
		curl -fsSL --connect-timeout 20 --retry 3 --retry-delay 1 \
			"https://dl.google.com/go/go${GO_VERSION}.${OS_NAME}-${GO_ARCH}.tar.gz" \
			-o "${GO_TARBALL}"
	fi
	rm -rf "${GO_ROOT}"
	tar -C "${BASE_DIR}" -xzf "${GO_TARBALL}"
fi

printf '%s\n' "${GO_BIN}"
