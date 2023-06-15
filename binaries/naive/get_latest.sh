#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"

PROJECT="klzgrad/naiveproxy"
BIN_NAME="naive"
BIN_NAME_IN_ARCHIVE_PATTERN="$BIN_NAME"
FILE_NAME_PATTERN="naiveproxy-v{version}-{file_arch}.tar.xz"

extract_archive() {
  tar -xvf "$1" --wildcards "*/$2"
  find . -name "naive" -type f | xargs -I file mv file ./
  find . -name "naiveproxy-v*" -type d|xargs rm -rf
}

. ../scripts/update_include.sh

make(){
  set_latest_release_version
  update openwrt-aarch64_cortex-a53-static arm64
  # use --best to compress armv5 armnv7
  update openwrt-arm_cortex-a9-static armv5 best
  update openwrt-arm_cortex-a9-static armv7 best
  md5_binaries
  echo -n "v$LATEST_VERSION" > latest.txt
}

make