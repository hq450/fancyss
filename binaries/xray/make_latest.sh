#!/usr/bin/env bash

set -e
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"
mkdir -p $DIR/.build_xray
base_dir=$DIR/.build_xray
cd ${base_dir}
GO_VERSION="1.22.2"
UPX_VERSION="4.2.3"
CODENAME="hq450@fancyss"

echo "-----------------------------------------------------------------"

# prepare golang
if [ ! -x ${base_dir}/go/bin/go ];then
	#[ ! -f "go${GO_VERSION}.linux-amd64.tar.gz" ] && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
	[ ! -f "go${GO_VERSION}.linux-amd64.tar.gz" ] && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C ${base_dir} -xzf go${GO_VERSION}.linux-amd64.tar.gz
fi
export PATH=${base_dir}/go/bin:$PATH
go version
echo "-----------------------------------------------------------------"

# get upx
if [ ! -x ${base_dir}/upx ];then
	[ ! -f "upx-${UPX_VERSION}-amd64_linux.tar.xz" ] && wget https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz
	tar xf upx-${UPX_VERSION}-amd64_linux.tar.xz
	cp ${base_dir}/upx-${UPX_VERSION}-amd64_linux/upx ${base_dir}/
fi
${base_dir}/upx -V
echo "-----------------------------------------------------------------"

# get Xray-core
if [ ! -d ${base_dir}/Xray-core ];then
	echo "Clone v2fly/Xray-core repo..."
	git clone https://github.com/XTLS/Xray-core.git
	cd ${base_dir}/Xray-core
	go mod download
else
	cd ${base_dir}/Xray-core
	git reset --hard && git clean -fdqx
	git checkout main
	git pull
fi

VERSIONTAG=$(git describe --abbrev=0 --tags)
rm -rf ${base_dir}/${VERSIONTAG}
mkdir -p ${base_dir}/${VERSIONTAG}
rm -rf ${base_dir}/armv5
rm -rf ${base_dir}/armv7
rm -rf ${base_dir}/armv64
git checkout $VERSIONTAG

# remove some features from xray
# sed -i '/toml/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/yaml/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/observatory/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/confloader/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/httpupgrade/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/commander/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/log\/command/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/proxyman\/command/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/stats\/command/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/proxy\/dns/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/proxy\/loopback/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/headers\/noop/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/internet\/domainsocket/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/fakedns/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/metrics/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/policy/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/reverse/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/router/d' ${base_dir}/Xray-core/main/distro/all/all.go
# sed -i '/app\/stats/d' ${base_dir}/Xray-core/main/distro/all/all.go

# build xray
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
	cd ${base_dir}/Xray-core

	local VERSION=$(git describe --abbrev=0 --tags | sed 's/v//')

	LDFLAGS="-s -w -buildid="

	echo "Compile xray $1 GOARM=${GOARM} GOARCH=${GOARCH}..."
	env CGO_ENABLED=0 GOOS=linux GOARM=$GOARM GOARCH=$GOARCH go build -v -o "${TMP}/xray_${1}" -trimpath -ldflags "$LDFLAGS" ./main

	cp ${TMP}/xray_${1} ${base_dir}/${VERSIONTAG}/
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

	echo -n "$VERSIONTAG" > latest_2.txt
}

build_v2 armv5
build_v2 armv7
build_v2 arm64
compress_binary


