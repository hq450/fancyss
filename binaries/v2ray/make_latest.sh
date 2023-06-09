#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p $DIR/.build_v2ray
base_dir=$DIR/.build_v2ray
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

# get v2ray-core
if [ ! -d ${base_dir}/v2ray-core ];then
	echo "Clone v2fly/v2ray-core repo..."
	git clone https://github.com/v2fly/v2ray-core.git
	cd ${base_dir}/v2ray-core
	go mod download
else
	cd ${base_dir}/v2ray-core
	git reset --hard && git clean -fdqx
	git checkout master
	git pull
fi
VERSIONTAG=$(git describe --abbrev=0 --tags)
rm -rf ${base_dir}/${VERSIONTAG}
mkdir -p ${base_dir}/${VERSIONTAG}
rm -rf ${base_dir}/armv5
rm -rf ${base_dir}/armv7
rm -rf ${base_dir}/armv64
git checkout $VERSIONTAG

# build v2ray
build_v2() {
	TMP=$(mktemp -d)
	BUILDNAME=$NOW
	case $1 in
		armv5)
			GOARM=5
			GOARCH=arm
			;;		
		armv7)
			GOARM=7
			GOARCH=arm
			;;
		arm64)
			GOARM=
			GOARCH=arm64
			;;
	esac
	cd ${base_dir}/v2ray-core

	local VERSION=$(git describe --abbrev=0 --tags | sed 's/v//')

	LDFLAGS="-s -w -buildid= -X github.com/v2fly/v2ray-core/v5.codename=${CODENAME} -X github.com/v2fly/v2ray-core/v5.build=${BUILDNAME} -X github.com/v2fly/v2ray-core/v5.version=${VERSION}"

	echo "Compile v2ray $1 GOARM=${GOARM} GOARCH=${GOARCH}..."
	env CGO_ENABLED=0 GOARM=$GOARM GOARCH=$GOARCH go build -o "${TMP}/v2ray_${1}" -ldflags "$LDFLAGS" ./main

	cp ${TMP}/v2ray_${1} ${base_dir}/${VERSIONTAG}/
	rm -rf ${TMP}
}

compress_binary(){
	echo "-----------------------------------------------------------------"
	ls -l ${base_dir}/${VERSIONTAG}/*
	echo "-----------------------------------------------------------------"
	${base_dir}/upx --lzma --ultra-brute ${base_dir}/${VERSIONTAG}/*

	${base_dir}/upx -t ${base_dir}/${VERSIONTAG}/*

	cd ${base_dir}/${VERSIONTAG}/
	md5sum * >md5sum.txt
	
	cd ${base_dir}
	rm -rf ../${VERSIONTAG}
	mv -f ${VERSIONTAG} ..

	echo -n "$VERSIONTAG" > latest_v5.txt
}

build_v2 armv5
build_v2 armv7
build_v2 arm64
compress_binary


