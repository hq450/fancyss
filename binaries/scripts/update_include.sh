#!/usr/bin/env bash

set_latest_release_version() {
  local LATEST_URL="https://github.com/$PROJECT/releases/latest"
  local LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' ${LATEST_URL})
  LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/; s/v//g; s/ //g')
}

set_latest_prerelease_version() {
  local LATEST_URL="https://api.github.com/repos/$PROJECT/releases"
  local LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' ${LATEST_URL})
  LATEST_VERSION=$(echo $LATEST_RELEASE | jq -r '.[0].tag_name' | sed 's/^v//g;')
}

set_latest_release_version_download_url() {
  URL="https://github.com/$PROJECT/releases/download/v$LATEST_VERSION/$1"
}

# $1 pattern
# $2 arch
# $3 file_arch
# $4 version
pattern_replace() {
  local replaced="$1"
  replaced=$(echo "$replaced" | sed "s/{arch}/$2/")
  replaced=$(echo "$replaced" | sed "s/{file_arch}/$3/")
  replaced=$(echo "$replaced" | sed "s/{version}/$4/")
  echo "$replaced"
}

update(){
  local FILE_NAME=$(pattern_replace "$FILE_NAME_PATTERN" "$2" "$1" "$LATEST_VERSION")
  echo "file name: $FILE_NAME"
  local dir="v$LATEST_VERSION"
  local bin_file_name="${BIN_NAME}_$2"

  mkdir -p "$dir"
  if [ -e "$dir/${bin_file_name}" ]; then
    echo "latest release already downloaded for $2"
    return
  fi

  set_latest_release_version_download_url "$FILE_NAME"

  echo "downloading latest release from $URL"

  rm -f "$FILE_NAME"

  wget -O "$FILE_NAME" "$URL"

  local bin_name_in_archive=$(pattern_replace "$BIN_NAME_IN_ARCHIVE_PATTERN" "$2" "$1" "$LATEST_VERSION")
  extract_archive "$FILE_NAME" "$bin_name_in_archive"

  rm "$FILE_NAME"
  if [ "$3" = "best" ];then
  	upx-4.0.2 --best "$bin_name_in_archive"
  else
  	upx-4.0.2 --lzma --ultra-brute "$bin_name_in_archive"
  fi
  mv "$bin_name_in_archive" "$dir/${bin_file_name}"
}

md5_binaries() {
  cd "v$LATEST_VERSION"
  rm -f md5sum.txt
  md5sum * > md5sum.txt
  cd ..
}