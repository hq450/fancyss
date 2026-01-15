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

update_armv5_upx424() {
  # Keep the same update() workflow, but force armv5 to be packed by upx-4.2.4
  # by temporarily shadowing upx-5.0.2 in PATH for this call only.
  (
  local tmp_path
  tmp_path="$(mktemp -d)"
  trap 'rm -rf "${tmp_path}"' EXIT
  cat > "${tmp_path}/upx-5.0.2" <<'EOF'
#!/usr/bin/env sh
exec upx-4.2.4 "$@"
EOF
  chmod +x "${tmp_path}/upx-5.0.2"
  PATH="${tmp_path}:${PATH}" update "$@"
  )
}

make(){
  set_latest_release_version
  update openwrt-aarch64_cortex-a53-static arm64
  # use --lzma --ultra-brute to compress armv5 armnv7
  update_armv5_upx424 openwrt-arm_cortex-a9-static armv5
  update openwrt-arm_cortex-a9-static armv7
  md5_binaries
  echo -n "v$LATEST_VERSION" > latest.txt
}

make
