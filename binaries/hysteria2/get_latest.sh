#!/usr/bin/env bash

get_latest_release_version() {
  local LATEST_URL="https://github.com/apernet/hysteria/releases/latest"
  local LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/apernet/hysteria/releases/latest)
  LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/; s/v//g; s/ //g; s/app\///g')
  echo "latest $BIN_NAME version is $LATEST_VERSION"
}

get_latest_release_version

if [ -d "v${LATEST_VERSION}" ];then
	echo "already have lateset!"
	exit
fi

mkdir -p v${LATEST_VERSION}

cd v${LATEST_VERSION}
echo "download hysteria2_armv5"
wget -O hysteria2_armv5 "https://github.com/apernet/hysteria/releases/download/app%2Fv${LATEST_VERSION}/hysteria-linux-armv5" >/dev/null 2>&1

echo "download hysteria2_armv7"
wget -O hysteria2_armv7 "https://github.com/apernet/hysteria/releases/download/app%2Fv${LATEST_VERSION}/hysteria-linux-arm" >/dev/null 2>&1

echo "download hysteria2_arm64"
wget -O hysteria2_arm64 "https://github.com/apernet/hysteria/releases/download/app%2Fv${LATEST_VERSION}/hysteria-linux-arm64" >/dev/null 2>&1

chmod +x *
upx-5.0.2 --lzma --ultra-brute *