#!/bin/sh

MODULE=shadowsocks
VERSION=$(cat ./fancyss/ss/version|sed -n 1p)
TITLE=科学上网
DESCRIPTION=科学上网
HOME_URL=Module_shadowsocks.asp
DIR="$( cd "$( dirname "$BASH_SOURCE[0]" )" && pwd )"

cp_rules(){
	cp -rf ../rules/gfwlist.conf fancyss/ss/rules/
	cp -rf ../rules/chnroute.txt fancyss/ss/rules/
	cp -rf ../rules/cdn.txt fancyss/ss/rules/
	cp -rf ../rules/version1 fancyss/ss/rules/version
}

sync_binary(){
	v2ray_version=$(cat ../v2ray_binary/latest.txt)
	local md5_v2ray_latest=$(md5sum ../v2ray_binary/$v2ray_version/v2ray_armv7 | sed 's/ /\n/g'| sed -n 1p)
	local md5_v2ray_curren=$(md5sum fancyss/bin/v2ray | sed 's/ /\n/g'| sed -n 1p)
	if [ "$md5_v2ray_latest"x != "$md5_v2ray_curren"x ]; then
		echo update v2ray binary！
		cp -rf ../v2ray_binary/$v2ray_version/v2ray_armv7 fancyss/bin/v2ray
	fi

	xray_version=$(cat ../xray_binary/latest.txt)
	md5_xray_latest=$(md5sum ../xray_binary/$xray_version/xray | sed 's/ /\n/g'| sed -n 1p)
	md5_xray_curren=$(md5sum fancyss/bin/xray | sed 's/ /\n/g'| sed -n 1p)
	if [ "$md5_xray_latest"x != "$md5_xray_curren"x ]; then
		echo update xray binary！
		cp -rf ../xray_binary/$xray_version/xray fancyss/bin/xray
	fi
}

gen_folder_full(){
	cd $DIR
	rm -rf shadowsocks
	cp -rf fancyss shadowsocks
	sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/[ \t]*\/\/fancyss-full//g' ./shadowsocks/res/ss-menu.js
	sed -i 's/[ \t]*\/\/fancyss-koolgame//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/#@//g' ./shadowsocks/scripts/ss_proc_status.sh
	sed -i 's/科学上网插件\s\-\sFull/科学上网插件/g' ./shadowsocks/webs/Module_shadowsocks.asp
	# remove all comment line
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/res/ss-menu.js
}

gen_folder_lite(){
	cd $DIR
	rm -rf shadowsocks
	cp -rf fancyss shadowsocks
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
	# remove dns option
	sed -i 's/\, \[\"13\"\, \"SmartDNS\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\, \[\"9\"\, \"SmartDNS\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\, \[\"5\"\, \"chinadns1\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\, \[\"2\"\, \"chinadns2\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\, \[\"4\"\, \"ss-tunnel\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\, \[\"1\"\, \"cdns\"\]//' ./shadowsocks/webs/Module_shadowsocks.asp
	# remove strings from page
	sed -i '/fancyss-full/d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/fancyss-full/d' ./shadowsocks/res/ss-menu.js
	sed -i 's/\,\s\"ss_basic_vcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\,\s\"ss_basic_tcore\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\,\s\"ss_basic_rust\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\,\s\"ss_v2ray\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\,\s\"ss_v2ray_opts\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/ss_v2ray/d' ./shadowsocks/webs/Module_shadowsocks.asp
	# remove block
	sed -i '/fancyss_full_1/,/fancyss_full_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/fancyss_koolgame_1/,/fancyss_koolgame_2/d' ./shadowsocks/webs/Module_shadowsocks.asp
	# remove kcp udp
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
	# modify
	sed -i 's/ss\/ssr\/trojan/ss\/ssr/g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/ss\/ssr\/koolgame\/v2ray/ss\/ssr\/v2ray/g' ./shadowsocks/res/ss-menu.js
	sed -i 's/shadowsocks_2/shadowsocks_lite_2/g' ./shadowsocks/res/ss-menu.js
	sed -i 's/科学上网插件 - Full/科学上网插件 - Lite/g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/config\.json\.js/config_lite\.json\.js/g' ./shadowsocks/res/ss-menu.js
	# remove page
	rm -rf ./shadowsocks/webs/Module_shadowsocks_lb.asp
	rm -rf ./shadowsocks/webs/Module_shadowsocks_local.asp
	sed -i 's/\, \"负载均衡设置\"//g' ./shadowsocks/res/ss-menu.js
	sed -i 's/\, \"Module_shadowsocks_lb\.asp\"//g' ./shadowsocks/res/ss-menu.js
	sed -i 's/\, \"Socks5设置\"//g' ./shadowsocks/res/ss-menu.js
	sed -i 's/\, \"Module_shadowsocks_local\.asp\"//g' ./shadowsocks/res/ss-menu.js
	echo ".show-btn5, .show-btn6{display: none; !important}" >> ./shadowsocks/res/shadowsocks.css
	# remove from script
	sed -i '/#@/d' ./shadowsocks/scripts/ss_proc_status.sh
	sed -i '/#@/d' ./shadowsocks/scripts/ss_conf.sh
	# remove koolgame support
	sed -i 's/\,\s\"koolgame_udp\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/fancyss-koolgame/d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/ || koolgame_on//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/六种客户端/五种客户端/g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/16\.67/20/g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/六种客户端/五种客户端/g' ./shadowsocks/res/ss-menu.js
	sed -i '/koolgame/d' ./shadowsocks/res/ss-menu.js
	sed -i 's/\,\s\"ss_game2_dns_foreign\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i 's/\,\s\"ss_game2_dns2ss_user\"//g' ./shadowsocks/webs/Module_shadowsocks.asp
	# remove all comment line
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/webs/Module_shadowsocks.asp
	sed -i '/^[ \t]*\/\//d' ./shadowsocks/res/ss-menu.js
}

do_build_full() {
	# for fancyss
	rm -f shadowsocks.tar.gz
	rm -f fancyss_hnd_full.tar.gz
	tar -zcvf fancyss_hnd_full.tar.gz ${MODULE}
	md5value=$(md5sum fancyss_hnd_full.tar.gz|tr " " "\n"|sed -n 1p)
	cat > ./version_full <<-EOF
	$VERSION
	$md5value
	EOF
	cat version_full
	
	DATE=$(date +%Y-%m-%d_%H:%M:%S)
	cat > ./config_full.json.js <<-EOF
	{
	"build_date":"$DATE",
	"description":"$DESCRIPTION",
	"home_url":"$HOME_URL",
	"md5":"$md5value",
	"name":"$MODULE",
	"tar_url": "https://raw.githubusercontent.com/hq450/fancyss/master/fancyss_hnd/fancyss_hnd_full.tar.gz", 
	"title":"$TITLE",
	"version":"$VERSION"
	}
	EOF
	
	# for old
	rm -rf shadowsocks.tar.gz
	cp -rf fancyss_hnd_full.tar.gz shadowsocks.tar.gz

	cat > ./version <<-EOF
	$VERSION
	$md5value
	EOF
	cat version
	
	cat > ./config.json.js <<-EOF
	{
	"build_date":"$DATE",
	"description":"$DESCRIPTION",
	"home_url":"$HOME_URL",
	"md5":"$md5value",
	"name":"$MODULE",
	"tar_url": "https://raw.githubusercontent.com/hq450/fancyss/master/fancyss_hnd/shadowsocks.tar.gz", 
	"title":"$TITLE",
	"version":"$VERSION"
	}
	EOF
}

do_build_lite() {
	rm -f fancyss_hnd_lite.tar.gz
	tar -zcvf fancyss_hnd_lite.tar.gz ${MODULE}
	md5value=$(md5sum fancyss_hnd_lite.tar.gz|tr " " "\n"|sed -n 1p)
	cat > ./version_lite <<-EOF
	$VERSION
	$md5value
	EOF
	cat version_lite
	
	DATE=$(date +%Y-%m-%d_%H:%M:%S)
	cat > ./config_lite.json.js <<-EOF
	{
	"build_date":"$DATE",
	"description":"${DESCRIPTION} lite",
	"home_url":"$HOME_URL",
	"md5":"$md5value",
	"name":"$MODULE",
	"tar_url": "https://raw.githubusercontent.com/hq450/fancyss/master/fancyss_hnd/fancyss_hnd_lite.tar.gz", 
	"title":"$TITLE",
	"version":"$VERSION"
	}
	EOF
}

do_backup_full(){
	cd ${DIR}
	HISTORY_DIR="../../fancyss_history_package/fancyss_hnd"
	# backup latested package after pack
	local backup_version=$(cat ${DIR}/version | sed -n 1p)
	local backup_tar_md5=$(cat ${DIR}/version | sed -n 2p)
	echo backup VERSION FULL: ${backup_version}
	cp fancyss_hnd_full.tar.gz $HISTORY_DIR/fancyss_hnd_full_${backup_version}.tar.gz
	sed -i "/fancyss_hnd_full_$backup_version/d" ${HISTORY_DIR}/md5sum.txt
	echo ${backup_tar_md5} fancyss_hnd_full_${backup_version}.tar.gz >> "${HISTORY_DIR}"/md5sum.txt
}

do_backup_lite(){
	cd ${DIR}
	HISTORY_DIR="../../fancyss_history_package/fancyss_hnd"
	# backup latested package after pack
	local backup_version=$(cat ${DIR}/version_lite | sed -n 1p)
	local backup_tar_md5=$(cat ${DIR}/version_lite | sed -n 2p)
	echo backup VERSION LITE: ${backup_version}
	cp fancyss_hnd_lite.tar.gz $HISTORY_DIR/fancyss_hnd_lite_${backup_version}.tar.gz
	sed -i "/fancyss_hnd_lite_${backup_version}/d" ${HISTORY_DIR}/md5sum.txt
	echo ${backup_tar_md5} fancyss_hnd_lite_${backup_version}.tar.gz >> "${HISTORY_DIR}"/md5sum.txt
}

pack_full(){
	cp_rules
	sync_binary
	gen_folder_full
	do_build_old
	do_build_full
	do_backup_full
	rm -rf ${DIR}/shadowsocks/
}

pack_lite(){
	cp_rules
	sync_binary
	gen_folder_lite
	do_build_lite
	do_backup_lite
	rm -rf ${DIR}/shadowsocks/
}

pack_full
pack_lite

