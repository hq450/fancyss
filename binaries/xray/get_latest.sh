#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

PROJECT="XTLS/Xray-core"
BIN_NAME="xray"
BIN_NAME_IN_ARCHIVE_PATTERN="$BIN_NAME"
FILE_NAME_PATTERN="Xray-linux-{file_arch}.zip"

extract_archive() {
  unzip -o "$1" "$2"
}

. ../scripts/update_include.sh

make(){
  set_latest_prerelease_version
  update arm32-v5 armv5
  update arm32-v7a armv7
  update arm64-v8a arm64
  md5_binaries
  echo -n "v$LATEST_VERSION" > latest_2.txt
}

make