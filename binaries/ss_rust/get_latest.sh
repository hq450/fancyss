#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

PROJECT="shadowsocks/shadowsocks-rust"
BIN_NAME="sslocal"
BIN_NAME_IN_ARCHIVE_PATTERN="$BIN_NAME"
FILE_NAME_PATTERN="shadowsocks-v{version}.{file_arch}.tar.xz"

extract_archive() {
  tar -xvf "$1" "$2"
}

. ../scripts/update_include.sh

make(){
  set_latest_release_version
  update arm-unknown-linux-musleabi armv5
  # Currently no official stable release for armv7-unknown-linux-musleabihf,
  # should use armv7-unknown-linux-musleabihf for armv7 once there is one.
  update arm-unknown-linux-musleabihf armv7
  update aarch64-unknown-linux-musl arm64
  md5_binaries
  echo -n "v$LATEST_VERSION" > latest.txt
}

make