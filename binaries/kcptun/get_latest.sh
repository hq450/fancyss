#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

PROJECT="xtaci/kcptun"
BIN_NAME="kcptun"
BIN_NAME_IN_ARCHIVE_PATTERN="client_linux_{file_arch}"
FILE_NAME_PATTERN="kcptun-linux-{file_arch}-{version}.tar.gz"

extract_archive() {
  tar -xvf "$1" "$2"
}

. ../scripts/update_include.sh

make(){
  set_latest_release_version
  update arm5 armv5
  update arm7 armv7
  update arm64 arm64
  md5_binaries
  echo -n "v$LATEST_VERSION" > latest.txt
}

make