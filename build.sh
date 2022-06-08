#!/usr/bin/env bash

MODULE=shadowsocks
VERSION=$(cat ./fancyss/ss/version|sed -n 1p)
TITLE="科学上网"
DESCRIPTION="科学上网"
HOME_URL=Module_shadowsocks.asp
CURR_PATH="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

cp_rules(){
	cp -rf ${CURR_PATH}/rules/gfwlist.conf ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/chnroute.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/cdn.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/cdn_test.txt ${CURR_PATH}/fancyss/ss/rules/
	cp -rf ${CURR_PATH}/rules/rules.json.js ${CURR_PATH}/fancyss/ss/rules/rules.json.js
}

sync_binary(){
	# hnd & qca (RT-AC86U, TUF-AX3000, RT-AX86U, GT-AX6000, RT-AX89X ...)
	local v2ray_version=$(cat ${CURR_PATH}/binaries/v2ray/latest.txt)
	local xray_version=$(cat ${CURR_PATH}/binaries/xray/latest.txt)
	cp -rf ${CURR_PATH}/binaries/v2ray/${v2ray_version}/v2ray_armv7 ${CURR_PATH}/fancyss/bin-hnd/v2ray
	cp -rf ${CURR_PATH}/binaries/v2ray/${v2ray_version}/v2ray_armv7 ${CURR_PATH}/fancyss/bin-qca/v2ray
	cp -rf ${CURR_PATH}/binaries/v2ray/${v2ray_version}/v2ray_armv5 ${CURR_PATH}/fancyss/bin-arm/v2ray
	cp -rf ${CURR_PATH}/binaries/xray/${xray_version}/xray_armv7 ${CURR_PATH}/fancyss/bin-hnd/xray
	cp -rf ${CURR_PATH}/binaries/xray/${xray_version}/xray_armv7 ${CURR_PATH}/fancyss/bin-qca/xray
	cp -rf ${CURR_PATH}/binaries/xray/${xray_version}/xray_armv5 ${CURR_PATH}/fancyss/bin-arm/xray
}

gen_folder(){
	local platform=$1
	local pkgtype=$2
	cd ${CURR_PATH}
	rm -rf shadowsocks
	cp -rf fancyss shadowsocks

	# different platform
	if [ "${platform}" == "hnd" ];then
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-qca
		mv shadowsocks/bin-hnd ./shadowsocks/bin
		echo hnd > ./shadowsocks/.valid
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_hnd_full/g' ./shadowsocks/webs/Module_shadowsocks.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_hnd_lite/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "qca" ];then
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-arm
		rm -rf ./shadowsocks/bin-hnd
		mv shadowsocks/bin-qca ./shadowsocks/bin
		echo qca > ./shadowsocks/.valid
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_qca_full/g' ./shadowsocks/webs/Module_shadowsocks.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_qca_lite/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	if [ "${platform}" == "arm" ];then
		rm -rf ./shadowsocks/bin-hnd_v8
		rm -rf ./shadowsocks/bin-hnd
		rm -rf ./shadowsocks/bin-qca
		mv shadowsocks/bin-arm ./shadowsocks/bin
		echo arm > ./shadowsocks/.valid
		sed -i '/fancyss-hnd/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_mcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_tfo\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		[ "${pkgtype}" == "full" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_arm_full/g' ./shadowsocks/webs/Module_shadowsocks.asp
		[ "${pkgtype}" == "lite" ] && sed -i 's/ 科学上网插件/ 科学上网插件 - fancyss_arm_lite/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi
	
	if [ "${pkgtype}" == "full" ];then
		# remove tag mark
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/[ \t]*\/\/fancyss-koolgame//g' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove comment
		sed -i 's/#@//g' ./shadowsocks/scripts/ss_proc_status.sh
		# modify asp page
		sed -i 's/科学上网插件\s\-\sFull/科学上网插件/g' ./shadowsocks/webs/Module_shadowsocks.asp
	fi

	if [ "${pkgtype}" == "lite" ];then
		# remove binaries
		rm -rf ./shadowsocks/bin/v2ray
		rm -rf ./shadowsocks/bin/v2ray-plugin
		rm -rf ./shadowsocks/bin/kcptun
		rm -rf ./shadowsocks/bin/trojan
		rm -rf ./shadowsocks/bin/ss-tunnel
		rm -rf ./shadowsocks/bin/trojan
		rm -rf ./shadowsocks/bin/koolgame
		rm -rf ./shadowsocks/bin/pdu
		rm -rf ./shadowsocks/bin/speederv1
		rm -rf ./shadowsocks/bin/speederv2
		rm -rf ./shadowsocks/bin/udp2raw
		rm -rf ./shadowsocks/bin/haproxy
		rm -rf ./shadowsocks/bin/smartdns
		rm -rf ./shadowsocks/bin/cdns
		rm -rf ./shadowsocks/bin/chinadns
		rm -rf ./shadowsocks/bin/chinadns1
		rm -rf ./shadowsocks/bin/smartdns
		rm -rf ./shadowsocks/bin/haveged
		# remove scripts
		rm -rf ./shadowsocks/scripts/ss_lb_config.sh
		rm -rf ./shadowsocks/scripts/ss_v2ray.sh
		rm -rf ./shadowsocks/scripts/ss_rust_update.sh
		rm -rf ./shadowsocks/scripts/ss_socks5.sh
		rm -rf ./shadowsocks/scripts/ss_udp_status.sh
		# remove rules
		rm -rf ./shadowsocks/ss/rules/chn.acl
		rm -rf ./shadowsocks/ss/rules/gfwlist.acl
		rm -rf ./shadowsocks/ss/rules/cdns.json
		rm -rf ./shadowsocks/ss/rules/smartdns_template.conf
		# remove pages
		rm -rf ./shadowsocks/webs/Module_shadowsocks_lb.asp
		rm -rf ./shadowsocks/webs/Module_shadowsocks_local.asp
		# remove line
		sed -i '/fancyss-full/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss-full/d' ./shadowsocks/res/ss-menu.js
		sed -i '/fancyss-koolgame/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/#@/d' ./shadowsocks/scripts/ss_proc_status.sh
		sed -i '/#@/d' ./shadowsocks/scripts/ss_conf.sh
		sed -i '/koolgame/d' ./shadowsocks/res/ss-menu.js
		# remove lines
		sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i '/fancyss_koolgame_1/,/fancyss_koolgame_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove dns option
		sed -i 's/\, \[\"1\"\, \"cdns\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"2\"\, \"chinadns2\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"4\"\, \"ss-tunnel\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"5\"\, \"chinadns1\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"9\"\, \"SmartDNS\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"13\"\, \"SmartDNS\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
		# remove strings from page
		sed -i 's/\,\s\"ss_basic_vcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_tcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_rust\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_v2ray\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_v2ray_opts\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"use_kcp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_server\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_port\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_parameter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_method\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_encrypt\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_rcvwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_conn\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_extra\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_sndwnd\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_software\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_node\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_nu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_duplicate_time\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_jitter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_report\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_drop\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_fec\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_timeout\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_report\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_jitter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_interval\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_drop\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_other\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rserver\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rport\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_password\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_rawmode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_ciphermode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_authmode\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_lowerlevel\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_other\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_upstream_mtu_value\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_kcp_nocomp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp_boost_enable\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv1_disable_filter\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disableobscure\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udpv2_disablechecksum\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_boost_enable\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_a\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_basic_udp2raw_keeprule\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"koolgame_udp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/ || koolgame_on//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_game2_dns_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\,\s\"ss_game2_dns2ss_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \"负载均衡设置\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Socks5设置\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Module_shadowsocks_lb\.asp\"//g' ./shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Module_shadowsocks_local\.asp\"//g' ./shadowsocks/res/ss-menu.js
		# modify words
		sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/六种客户端/五种客户端/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/16\.67/20/g' ./shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/六种客户端/五种客户端/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/ss\/ssr\/koolgame\/v2ray/ss\/ssr\/v2ray/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./shadowsocks/res/ss-menu.js
		sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./shadowsocks/res/ss-menu.js
		# add css
		echo ".show-btn5, .show-btn6{display: none; !important}" >> ./shadowsocks/res/shadowsocks.css
	fi
	
	# remove all comment line from page
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/res/ss-menu.js

	# when develop in other branch
	# master/fancyss_hnd
	# local CURRENT_BRANCH=$(git branch | head -n1 |awk '{print $2}')
	# if [ "${CURRENT_BRANCH}" != "master" ];then
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./shadowsocks/webs/Module_shadowsocks.asp
	# 	sed -i "s/master\/fancyss_hnd/${CURRENT_BRANCH}\/fancyss_hnd/g" ./shadowsocks/res/ss-menu.js
	# fi
}

build_pkg() {
	local platform=$1
	local pkgtype=$2
	# different platform
	echo "打包：fancyss_${platform}_${pkgtype}.tar.gz"
	tar -zcf ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz shadowsocks >/dev/null
	md5value=$(md5sum ${CURR_PATH}/packages/fancyss_${platform}_${pkgtype}.tar.gz|tr " " "\n"|sed -n 1p)
	cat >>${CURR_PATH}/packages/version_tmp.json.js <<-EOF
		,"md5_${platform}_${pkgtype}":"${md5value}"
	EOF
}

do_backup(){
	local platform=$1
	local pkgtype=$2
	cd ${CURR_PATH}
	HISTORY_DIR="${CURR_PATH}/../fancyss_history_package/fancyss_${platform}"
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
}

papare(){
	rm -f ${CURR_PATH}/packages/*
	cp_rules
	sync_binary
	cat >${CURR_PATH}/packages/version_tmp.json.js <<-EOF
	{
	"name":"fancyss"
	,"version":"${VERSION}"
	EOF
}
finish(){
	echo "}" >>${CURR_PATH}/packages/version_tmp.json.js
	cat ${CURR_PATH}/packages/version_tmp.json.js | jq . >${CURR_PATH}/packages/version.json.js
	rm -rf ${CURR_PATH}/packages/version_tmp.json.js
}


pack(){
	gen_folder $1 $2
	build_pkg $1 $2
	do_backup  $1 $2
	rm -rf ${CURR_PATH}/shadowsocks/
}

make(){
	papare
	pack hnd full
	pack hnd lite
	pack qca full
	pack qca lite
	pack arm full
	pack arm lite
	finish
}


make

