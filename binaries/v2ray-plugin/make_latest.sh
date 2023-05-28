#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p $DIR/.build_v2ray-plugin
base_dir=$DIR/.build_v2ray-plugin
cd ${base_dir}
GO_VERSION="1.20.4"
CODENAME="hq450@fancyss"

echo "-----------------------------------------------------------------"

# prepare golang
if [ ! -x ${base_dir}/go/bin/go ];then
	[ ! -f "go${GO_VERSION}.linux-amd64.tar.gz" ] && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C ${base_dir} -xzf go${GO_VERSION}.linux-amd64.tar.gz
fi
export PATH=${base_dir}/go/bin:$PATH
go version
echo "-----------------------------------------------------------------"

# get upx
if [ ! -x ${base_dir}/upx ];then
	[ ! -f "upx-4.0.2-amd64_linux.tar.xz" ] && wget https://github.com/upx/upx/releases/download/v4.0.2/upx-4.0.2-amd64_linux.tar.xz
	tar xf upx-4.0.2-amd64_linux.tar.xz
	cp ${base_dir}/upx-4.0.2-amd64_linux/upx ${base_dir}/
fi
${base_dir}/upx -V
echo "-----------------------------------------------------------------"

# get v2ray-plugin
if [ ! -d ${base_dir}/v2ray-plugin ];then
	echo "Clone teddysun/v2ray-plugin repo..."
	git clone https://github.com/teddysun/v2ray-plugin.git
	cd ${base_dir}/v2ray-plugin
else
	cd ${base_dir}/v2ray-plugin
	git reset --hard && git clean -fdqx
	git checkout master
	git pull
fi

VERSION=$(git describe --abbrev=0 --tags)
rm -rf ${base_dir}/${VERSION}
rm -rf ${DIR}/${VERSION}
mkdir -p ${base_dir}/${VERSION}
git checkout $VERSION
LDFLAGS="-X main.VERSION=$VERSION -s -w -buildid="

# ARM5
echo "-----------------------------------------------------------------"
env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=5 go build -v -trimpath -ldflags "$LDFLAGS" -o ${base_dir}/${VERSION}/v2ray-plugin_armv5

# ARM5
echo "-----------------------------------------------------------------"
env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 go build -v -trimpath -ldflags "$LDFLAGS" -o ${base_dir}/${VERSION}/v2ray-plugin_armv7

# ARM64 (ARMv8 or aarch64)
echo "-----------------------------------------------------------------"
env CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -v -trimpath -ldflags "$LDFLAGS" -o ${base_dir}/${VERSION}/v2ray-plugin_arm64

# upx
echo "-----------------------------------------------------------------"
${base_dir}/upx --lzma --ultra-brute ${base_dir}/${VERSION}/*


mv ${base_dir}/${VERSION} ${DIR}
md5sum ${DIR}/${VERSION}/* >${DIR}/${VERSION}/md5sum.txt
echo ${VERSION} >latest.txt
