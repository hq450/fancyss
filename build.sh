#!/usr/bin/env bash

MODULE=shadowsocks
VERSION=$(cat ./fancyss/ss/version|sed -n 1p)
TITLE="科学上网"
DESCRIPTION="科学上网"
HOME_URL=Module_shadowsocks.asp
CURR_PATH="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

cp_rules(){
	local target=${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules_ng/gfwlist.gz ${target}
	cp -rf ${CURR_PATH}/rules_ng/chnlist.gz ${target}
	cp -rf ${CURR_PATH}/rules_ng/adslist.gz ${target}
	cp -rf ${CURR_PATH}/rules_ng/udplist.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/rotlist.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/white_list.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/black_list.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/block_list.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/apple_china.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/google_china.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/cdn_test.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/chnroute.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/chnroute6.txt ${target}
	cp -rf ${CURR_PATH}/rules_ng/rules.json.js ${target}
}

cp_rules_ng2(){
	local src=${CURR_PATH}/rules_ng2
	local target=${CURR_PATH}/fancyss/ss/rules_ng2
	rm -rf ${target}
	if [ -d "${src}" ];then
		mkdir -p ${CURR_PATH}/fancyss/ss
		cp -rf ${src} ${target}
	fi
}

prepare_geodata_assets(){
	echo ">>> refresh rules_ng2 manifest and package mirror"
	${CURR_PATH}/scripts/update_geodata_assets.sh --no-fetch
	echo ">>> build geosite/geoip dat assets"
	${CURR_PATH}/scripts/build_geodata_fancyss.sh
}

sync_binary(){
	# BINS_REMOVE="naive"
	# for BIN_REMOVE in $BINS_REMOVE;
	# do
	# 	echo ">>> remove old bin $BIN_REMOVE"
	# 	rm -rf ${CURR_PATH}/fancyss/bin-mtk/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-hnd_v8/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-hnd/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-qca/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-arm/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-ipq32/${BIN_REMOVE}
	# 	rm -rf ${CURR_PATH}/fancyss/bin-ipq64/${BIN_REMOVE}
	# done

	# update to latest binary
	BINS_COPY="xray naive ipt2socks"
	for BIN in $BINS_COPY;
	do
		local VERSION_FLAG="latest.txt"

		if [ "${BIN}" == "xray" ];then
			local VERSION_FLAG="latest_2.txt"
		fi

		local version=$(cat ${CURR_PATH}/binaries/${BIN}/${VERSION_FLAG})
		echo ">>> start to copy latest ${BIN}, version: ${version}"
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_arm64 ${CURR_PATH}/fancyss/bin-mtk/${BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_arm64 ${CURR_PATH}/fancyss/bin-hnd_v8/${BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_armv7 ${CURR_PATH}/fancyss/bin-ipq32/${BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_armv7 ${CURR_PATH}/fancyss/bin-hnd/${BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_armv7 ${CURR_PATH}/fancyss/bin-qca/${BIN}
		cp -rf ${CURR_PATH}/binaries/${BIN}/${version}/${BIN}_armv5 ${CURR_PATH}/fancyss/bin-arm/${BIN}
	done

	local TUIC_VERSION=$(cat ${CURR_PATH}/binaries/tuic-client/latest.txt)
	echo ">>> start to copy latest tuic-client, version: ${TUIC_VERSION}"
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_arm64 ${CURR_PATH}/fancyss/bin-mtk/tuic-client
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_arm64 ${CURR_PATH}/fancyss/bin-hnd_v8/tuic-client
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_armv7 ${CURR_PATH}/fancyss/bin-ipq32/tuic-client
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_armv7 ${CURR_PATH}/fancyss/bin-hnd/tuic-client
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_armv7 ${CURR_PATH}/fancyss/bin-qca/tuic-client
	cp -rf ${CURR_PATH}/binaries/tuic-client/${TUIC_VERSION}/tuic-client_armv7 ${CURR_PATH}/fancyss/bin-arm/tuic-client

	local upx=".upx"
	
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto$upx ${CURR_PATH}/fancyss/bin-mtk/chinadns-ng
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto$upx ${CURR_PATH}/fancyss/bin-hnd_v8/chinadns-ng
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@arm-linux-musleabi@generic+v7a@fast+lto$upx ${CURR_PATH}/fancyss/bin-ipq32/chinadns-ng
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@arm-linux-musleabi@generic+v7a@fast+lto$upx ${CURR_PATH}/fancyss/bin-hnd/chinadns-ng
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@arm-linux-musleabi@generic+v7a@fast+lto$upx ${CURR_PATH}/fancyss/bin-qca/chinadns-ng
	cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@arm-linux-musleabi@generic+v5te+soft_float@fast+lto$upx ${CURR_PATH}/fancyss/bin-arm/chinadns-ng

	local GEOTOOL_VER="v1.3"
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/geotool
	cp -rf ${CURR_PATH}/binaries/geotool/geotool-${GEOTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/geotool

	local XAPITOOL_VER="v0.2.1"
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/xapi-tool
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/xapi-tool
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/xapi-tool
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/xapi-tool
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/xapi-tool
	cp -rf ${CURR_PATH}/binaries/xapi-tool/xapi-tool-${XAPITOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/xapi-tool

	local SUBTOOL_VER="v0.1.9"
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/sub-tool
	cp -rf ${CURR_PATH}/binaries/sub-tool/sub-tool-${SUBTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/sub-tool

	local NODETOOL_VER="v0.1.1"
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/node-tool
	cp -rf ${CURR_PATH}/binaries/node-tool/node-tool-${NODETOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/node-tool

	local WEBSOCKETD_VER="v0.1.1"
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/websocketd
	cp -rf ${CURR_PATH}/binaries/websocketd/websocketd-${WEBSOCKETD_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/websocketd

	local STATUSTOOL_VER="v0.1.0"
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/status-tool-${STATUSTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/status-tool
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/statusctl
	cp -rf ${CURR_PATH}/binaries/status-tool/statusctl-${STATUSTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/statusctl

	local WEBTESTTOOL_VER="v0.1.0"
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtest-tool-${WEBTESTTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/webtest-tool
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-mtk/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-hnd_v8/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-aarch64 ${CURR_PATH}/fancyss/bin-ipq64/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-ipq32/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-armv7hf ${CURR_PATH}/fancyss/bin-hnd/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-armv7a ${CURR_PATH}/fancyss/bin-qca/webtestctl
	cp -rf ${CURR_PATH}/binaries/webtest-tool/webtestctl-${WEBTESTTOOL_VER}-linux-armv5te ${CURR_PATH}/fancyss/bin-arm/webtestctl
}

gen_folder(){
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	cd ${CURR_PATH}
	rm -rf shadowsocks
	cp -rf fancyss shadowsocks

	# different platform	
	if [ "${platform}" == "hnd" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-hnd ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		echo hnd > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "hnd_v8" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-hnd_v8 ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		echo hnd_v8 > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"hnd_v8\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "qca" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-qca ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		echo qca > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"qca\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "arm" ];then
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-arm ./shadowsocks/bin
		echo arm > ./shadowsocks/.valid
		sed -i '/fancyss-hnd/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/ss_basic_mcore/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/ss_basic_tfo/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"arm\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "mtk" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-mtk ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		rm -rf ./shadowsocks/bin/README.md
		echo ipq64 > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"mtk\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "ipq32" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-mtk
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-ipq32 ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		rm -rf ./shadowsocks/bin/README.md
		# bd4 already include jq and curl with proxy support
		rm -rf ./shadowsocks/bin/jq
		rm -rf ./shadowsocks/bin/curl-fancyss
		# bd4 jffs2 space to small, use xray run ss
		echo ipq32 > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"ipq32\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "ipq64" ];then
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-qca
		rm -rf ./shadowsocks/bin-ipq32
		rm -rf ./shadowsocks/bin-ipq64
		mv ./shadowsocks/bin-mtk ./shadowsocks/bin
		rm -rf ./shadowsocks/bin/uredir
		rm -rf ./shadowsocks/bin/README.md
		# tuf-be6500 already include jq and curl with proxy support
		rm -rf ./shadowsocks/bin/jq
		rm -rf ./shadowsocks/bin/curl-fancyss
		echo mtk > ./shadowsocks/.valid
		sed -i 's/PKG_ARCH=\"unknown\"/PKG_ARCH=\"ipq64\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	
	# remove some binary because it's not default provide by install packages
	# find ./shadowsocks/bin -name "tuic-client" | xargs rm -rf
	# find ./shadowsocks/bin -name "naive" | xargs rm -rf

	# use debug version of chinadns-ng for aarch64 platform
	# if [ "${platform}" == "hnd_v8" -o "${platform}" == "mtk" -o "${platform}" == "ipq64" ];then
	# 	if [ "${pkgtype}" == "full" -a "${release_type}" == "debug" ];then
	# 		cp -rf ${CURR_PATH}/binaries/chinadns-ng/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@debug ./shadowsocks/bin/chinadns-ng
	# 	fi
	# fi
	
	# wirte type string
	if [ "${release_type}" != "debug" ];then
		sed -i 's/PKG_EXTA=\"_debug\"/PKG_EXTA=\"\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	
	if [ "${pkgtype}" == "lite" ];then
		sed -i 's/var PKG_TYPE=\"full\"/var PKG_TYPE=\"lite\"/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	
	if [ "${pkgtype}" == "full" ];then
		# remove marked comment
		sed -i 's/#@//g' ./shadowsocks/scripts/ss_proc_status.sh
		sed -i 's/#@//g' ./shadowsocks/scripts/ss_conf.sh
	elif [ "${pkgtype}" == "lite" ];then
		# remove binaries
		rm -rf ./shadowsocks/bin/naive
		rm -rf ./shadowsocks/bin/tuic-client
		rm -rf ./shadowsocks/bin/ipt2socks
		rm -rf ./shadowsocks/bin/haveged

		# remove scripts
		rm -rf ./shadowsocks/scripts/ss_v2ray.sh
		# remove rules
		rm -rf ./shadowsocks/ss/rules/chn.acl
		rm -rf ./shadowsocks/ss/rules/gfwlist.acl
		# remove line
		sed -i '/fancyss-full/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss-full/d' ./shadowsocks/res/ss-menu.js
		sed -i '/fancyss-dns/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/naiveproxy/d' ./shadowsocks/res/ss-menu.js
		sed -i '/naiveproxy/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/tuic/d' ./shadowsocks/res/ss-menu.js
		# remove lines bewteen matchs
		sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_naive_1/,/fancyss_naive_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_tuic_1/,/fancyss_tuic_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove strings from page
		sed -i 's/\,\s\"naive_prot\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_prot\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_server\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_port\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_pass\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"naive_json\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"tuic_json\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_vcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		# modify words
		# trojan 用xray运行，所以trojan多核心功能删除
		sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/八种协议/六种协议/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/科学上网工具/科学上网、游戏加速工具/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/14\.286/20/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\s\&\&\s\!\snaive_on//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./shadowsocks/res/ss-menu.js
	fi

	if [ "${release_type}" == "release" ];then
		# 移除注释
		# remove match words: //fancyss-full //fancyss-full_1 //fancyss-full_2
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/res/ss-menu.js

		# remove match words: <!--fancyss-full-->
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/[ \t]*<!--fancyss-full-->//g' ./shadowsocks/res/ss-menu.js

		# remove line contain: <!--fancyss_full_1--> <!--fancyss_full_1-->
		sed -i 's/[ \t]*<!--fancyss_full_[1-2]-->//g' ./shadowsocks/webs/Module_shadowsocks.asp
		
		# remove line start of: //
		sed -i '/^[ \t]*\/\//d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/^[ \t]*\/\//d' ./shadowsocks/res/ss-menu.js

		# remove line <!-- ?? -->
		sed -i 's/<!--.*-->//g' ./shadowsocks/webs/Module_shadowsocks.asp

		# remove empty line
		sed -i '/^[[:space:]]*$/d' ./shadowsocks/webs/Module_shadowsocks.asp

		# icon
		rm -rf ./shadowsocks/res/icon-shadowsocks_debug.png
	else
		mv -f ./shadowsocks/res/icon-shadowsocks_debug.png ./shadowsocks/res/icon-shadowsocks.png
	fi

	# 有些功能还没准备好，先去掉
	# 1. 广告过滤规则
	# rm -rf ./shadowsocks/bin/smartdns
	rm -rf ./shadowsocks/ss/rules/adslist.gz
	# rm -rf ./shadowsocks/ss/rules/smartdns_smrt*
	# sed -i '/fancyss_todo/d' ./shadowsocks/webs/Module_shadowsocks.asp
}

build_pkg() {
	local platform=$1
	local pkgtype=$2
	local release_type=$3
	# different platform
	if [ ${release_type} == "release" ];then
		echo "打包：fancyss_${platform}_${pkgtype}.tar.gz"
		tar -zcf ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz shadowsocks >/dev/null
		md5value=$(md5sum ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz|tr " " "\n"|sed -n 1p)
		cat >>${CURR_PATH}/packages/version_tmp.json.js <<-EOF
			,"md5_${platform}_${pkgtype}":"${md5value}"
		EOF
	elif [ ${release_type} == "debug" ];then
		echo "打包：fancyss_${platform}_${pkgtype}_${release_type}.tar.gz"
		tar -zcf ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}_${release_type}.tar.gz shadowsocks >/dev/null
	fi
}

do_backup(){
	if [ "${CURR_PATH}/../fancyss_history_package" ];then
		local platform=$1
		local pkgtype=$2
		local release_type=$3
		if [ ${release_type} == "release" ];then
			cd ${CURR_PATH}
			HISTORY_DIR="${CURR_PATH}/../fancyss_history_package/fancyss_${platform}"
			mkdir -p ${HISTORY_DIR}
			# backup latested package after pack
			local backup_version=${VERSION}
			local backup_tar_md5=${md5value}
			
			echo "备份：fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz"
			cp ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz ${HISTORY_DIR}/fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz
			sed -i "/fancyss_${platform}_${pkgtype}_${backup_version}/d" ${HISTORY_DIR}/md5sum.txt
			if [ ! -f ${HISTORY_DIR}/md5sum.txt ];then
				touch ${HISTORY_DIR}/md5sum.txt
			fi
			echo ${backup_tar_md5} fancyss_${platform}_${pkgtype}_${backup_version}.tar.gz >> ${HISTORY_DIR}/md5sum.txt
		fi
	fi
}

papare(){
	rm -f ${CURR_PATH}/packages/*
	cp_rules
	prepare_geodata_assets
	cp_rules_ng2
	sync_binary
	cat >${CURR_PATH}/packages/version_tmp.json.js <<-EOF
	{
	"name":"fancyss"
	,"version":"${VERSION}"
	EOF
}

finish(){
	echo "}" >>${CURR_PATH}/packages/version_tmp.json.js
	cat ${CURR_PATH}/packages/version_tmp.json.js | jq '.' >${CURR_PATH}/packages/version.json.js
	rm -rf ${CURR_PATH}/packages/version_tmp.json.js
	echo "完成！生成的离线安装包在：${CURR_PATH}/packages"
}

pack(){
	gen_folder $1 $2 $3
	build_pkg $1 $2 $3
	if [ "$3" == "release" ];then
		do_backup  $1 $2 $3
	fi
	rm -rf ${CURR_PATH}/shadowsocks/
}

make(){
	papare
	# --- for release ---
	pack hnd full release
	pack hnd lite release
	pack hnd_v8 full release
	pack hnd_v8 lite release
	pack hnd lite release
	pack qca full release
	pack qca lite release
	pack arm full release
	pack arm lite release
	pack mtk full release
	pack mtk lite release
	pack ipq32 full release
	pack ipq32 lite release
	pack ipq64 full release
	pack ipq64 lite release
	# --- for debug ---
	pack hnd full debug
	pack hnd_v8 full debug
	pack qca full debug
	pack arm full debug
	pack mtk full debug
	pack ipq32 full debug
	pack ipq64 full debug
	finish
}

make
