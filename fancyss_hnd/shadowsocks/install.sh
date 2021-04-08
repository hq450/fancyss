#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=
UI_TYPE=ASUSWRT
FW_TYPE_CODE=
FW_TYPE_NAME=
DIR=$(cd $(dirname $0); pwd)
module=${DIR##*/}

get_model(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		MODEL="${ODMPID}"
	else
		MODEL="${PRODUCTID}"
	fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			FW_TYPE_CODE="2"
			FW_TYPE_NAME="koolshare官改固件"
		else
			FW_TYPE_CODE="4"
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			FW_TYPE_CODE="3"
			FW_TYPE_NAME="梅林原版固件"
		else
			FW_TYPE_CODE="1"
			FW_TYPE_NAME="华硕官方固件"
		fi
	fi
}

platform_test(){
	local LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	if [ -d "/koolshare" -a -f "/usr/bin/skipd" -a "${LINUX_VER}" -ge "41" ];then
		echo_date 机型："${MODEL} ${FW_TYPE_NAME} 符合安装要求，开始安装插件！"
	else
		exit_install 1
	fi
}

get_ui_type(){
	# default value
	[ "${MODEL}" == "RT-AC86U" ] && local ROG_RTAC86U=0
	[ "${MODEL}" == "GT-AC2900" ] && local ROG_GTAC2900=1
	[ "${MODEL}" == "GT-AC5300" ] && local ROG_GTAC5300=1
	[ "${MODEL}" == "GT-AX11000" ] && local ROG_GTAX11000=1
	[ "${MODEL}" == "GT-AXE11000" ] && local ROG_GTAXE11000=1
	local KS_TAG=$(nvram get extendno|grep koolshare)
	local EXT_NU=$(nvram get extendno)
	local EXT_NU=$(echo ${EXT_NU%_*} | grep -Eo "^[0-9]{1,10}$")
	local BUILDNO=$(nvram get buildno)
	[ -z "${EXT_NU}" ] && EXT_NU="0" 
	# RT-AC86U
	if [ -n "${KS_TAG}" -a "${MODEL}" == "RT-AC86U" -a "${EXT_NU}" -lt "81918" -a "${BUILDNO}" != "386" ];then
		# RT-AC86U的官改固件，在384_81918之前的固件都是ROG皮肤，384_81918及其以后的固件（包括386）为ASUSWRT皮肤
		ROG_RTAC86U=1
	fi
	# GT-AC2900
	if [ "${MODEL}" == "GT-AC2900" ] && [ "${FW_TYPE_CODE}" == "3" -o "${FW_TYPE_CODE}" == "4" ];then
		# GT-AC2900从386.1开始已经支持梅林固件，其UI是ASUSWRT
		ROG_GTAC2900=0
	fi
	# GT-AX11000
	if [ "${MODEL}" == "GT-AX11000" -o "${MODEL}" == "GT-AX11000_BO4" ] && [ "${FW_TYPE_CODE}" == "3" -o "${FW_TYPE_CODE}" == "4" ];then
		# GT-AX11000从386.2开始已经支持梅林固件，其UI是ASUSWRT
		ROG_GTAX11000=0
	fi
	# ROG UI
	if [ "${ROG_GTAC5300}" == "1" -o "${ROG_RTAC86U}" == "1" -o "${ROG_GTAC2900}" == "1" -o "${ROG_GTAX11000}" == "1" -o "${ROG_GTAXE11000}" == "1" ];then
		# GT-AC5300、RT-AC86U部分版本、GT-AC2900部分版本、GT-AX11000部分版本、GT-AXE11000全部版本，骚红皮肤
		UI_TYPE="ROG"
	fi
	# TUF UI
	if [ "${MODEL}" == "TUF-AX3000" ];then
		# 官改固件，橙色皮肤
		UI_TYPE="TUF"
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台！"
			echo_date "你的固件平台不能安装！！!"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/rogsoft#rogsoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

install_now(){
	# default value
	local TITLE="科学上网"
	local DESCR="科学上网 for merlin hnd platform"
	local PLVER=$(cat ${DIR}/ss/version)

	# stop first
	local ENABLE=$(dbus get ss_basic_enable)
	if [ "${ENABLE}" == "1" -a -f "/koolshare/ss/ssconfig.sh" ];then
		echo_date "安装前先关闭${TITLE}插件，保证文件更新成功！"
		sh /koolshare/ss/ssconfig.sh stop >/dev/null 2>&1
	fi

	# backup some file first
	if [ -n "$(ls /koolshare/ss/postscripts/P*.sh 2>/dev/null)" ];then
		echo_date "备份触发脚本!"
		mkdir /tmp/ss_backup
		find /koolshare/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
	fi

	# remove some file first
	echo_date "清理旧文件"
	rm -rf /koolshare/ss/*
	rm -rf /koolshare/scripts/ss_*
	rm -rf /koolshare/webs/Module_shadowsocks*
	rm -rf /koolshare/bin/ss-redir
	rm -rf /koolshare/bin/ss-tunnel
	rm -rf /koolshare/bin/ss-local
	rm -rf /koolshare/bin/rss-redir
	rm -rf /koolshare/bin/rss-tunnel
	rm -rf /koolshare/bin/rss-local
	rm -rf /koolshare/bin/obfs-local
	rm -rf /koolshare/bin/koolgame
	rm -rf /koolshare/bin/pdu
	rm -rf /koolshare/bin/haproxy
	rm -rf /koolshare/bin/dnscrypt-proxy
	rm -rf /koolshare/bin/dns2socks
	rm -rf /koolshare/bin/client_linux_arm*
	rm -rf /koolshare/bin/cdns
	rm -rf /koolshare/bin/chinadns
	rm -rf /koolshare/bin/chinadns1
	rm -rf /koolshare/bin/chinadns-ng
	rm -rf /koolshare/bin/smartdns
	rm -rf /koolshare/bin/resolveip
	rm -rf /koolshare/bin/speederv1
	rm -rf /koolshare/bin/speederv2
	rm -rf /koolshare/bin/udp2raw
	rm -rf /koolshare/bin/v2ray
	rm -rf /koolshare/bin/v2ctl
	rm -rf /koolshare/bin/v2ray-plugin
	rm -rf /koolshare/bin/https_dns_proxy
	rm -rf /koolshare/bin/httping
	rm -rf /koolshare/bin/haveged
	rm -rf /koolshare/res/icon-shadowsocks.png
	rm -rf /koolshare/res/ss-menu.js
	rm -rf /koolshare/res/qrcode.js
	rm -rf /koolshare/res/tablednd.js
	rm -rf /koolshare/res/all.png
	rm -rf /koolshare/res/gfw.png
	rm -rf /koolshare/res/chn.png
	rm -rf /koolshare/res/game.png
	rm -rf /koolshare/res/shadowsocks.css
	find /koolshare/init.d/ -name "*shadowsocks.sh" | xargs rm -rf >/dev/null 2>&1
	find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf >/dev/null 2>&1

	# legacy files should be removed
	rm -rf /koolshare/bin/dnsmasq >/dev/null 2>&1
	rm -rf /koolshare/bin/Pcap_DNSProxy >/dev/null 2>&1

	# 386固件全面使用openssl1.1.1，弃用了openssl1.0.0，所以判断使用openssl1.1.1的使用新版本的httping
	if [ -f "/usr/lib/libcrypto.so.1.1" ];then
		mv /tmp/shadowsocks/bin/httping_openssl_1.1.1 /tmp/shadowsocks/bin/httping
	else
		rm -rf /tmp/shadowsocks/bin/httping_openssl_1.1.1
	fi

	# 梅林386.2 引入了jitterentropy-rngd用以提高系统熵，所以haveged不再需要安装了
	if [ -n "$(which jitterentropy-rngd)" ];then
		rm -rf /tmp/shadowsocks/bin/haveged
	fi

	# 对于jffs分区过小的插件，删除某些功能的二进制文件，比如RT-AX56U_V2的jffs只有15MB，所以移除一些功能
	JFFS_TOTAL=$(df|grep -Ew "/jffs" | awk '{print $2}')
	if [ "${JFFS_TOTAL}" -le "20000" ];then
		echo_date "-------------------------------------------------------------"
		echo_date "重要提示："
		echo_date "检测到你的机型${MODEL} jffs分区大小为${JFFS_TOTAL}，小于20MB！"
		echo_date "为了你的机型能顺利安装fancyss_hnd，部分功能的二进制文件将不会安装！"
		echo_date "安装后以下功能将无法使用，即使界面上显示有该功能"
		echo_date "1. v2ray 功能"
		echo_date "2. koolgame 功能"
		echo_date "3. kcptun 功能"
		echo_date "4. shadowsocks-libev v2ray plugin 功能"
		echo_date "5. shadowsocks-libev obfs plugin 功能"
		echo_date "6. smartdns、chinadns1、chinadns2 功能"
		echo_date "7. udp加速内的所有功能：udp2raw、speederv1、speederv2"
		echo_date "8. 负载均衡功能"
		echo_date "其它功能，如ss、ssr、dns、负载均衡等功能不受影响！"
		echo_date "-------------------------------------------------------------"
		rm -rf /tmp/shadowsocks/bin/v2ray
		rm -rf /tmp/shadowsocks/bin/v2ctl
		rm -rf /tmp/shadowsocks/bin/v2ray-plugin
		rm -rf /tmp/shadowsocks/bin/client_linux_arm7
		rm -rf /tmp/shadowsocks/bin/koolgame
		rm -rf /tmp/shadowsocks/bin/pdu
		rm -rf /tmp/shadowsocks/bin/speederv1
		rm -rf /tmp/shadowsocks/bin/speederv2
		rm -rf /tmp/shadowsocks/bin/udp2raw
		rm -rf /tmp/shadowsocks/bin/haproxy
		rm -rf /tmp/shadowsocks/bin/obfs-local
		rm -rf /tmp/shadowsocks/bin/smartdns
		rm -rf /tmp/shadowsocks/bin/chinadns1
		rm -rf /tmp/shadowsocks/bin/smartdns
		rm -rf /tmp/shadowsocks/scripts/ss_lb_config.sh
		rm -rf /tmp/shadowsocks/webs/Module_shadowsocks_lb.asp
		sed -i 's/\, \[\"13\"\, \"SmartDNS\"\]//' /tmp/shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"9\"\, \"SmartDNS\"\]//' /tmp/shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"5\"\, \"chinadns1\"\]//' /tmp/shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \[\"2\"\, \"chinadns2\"\]//' /tmp/shadowsocks/webs/Module_shadowsocks.asp
		sed -i 's/\, \"负载均衡设置\"//g' /tmp/shadowsocks/res/ss-menu.js
		sed -i 's/\, \"Module_shadowsocks_lb\.asp\"//g' /tmp/shadowsocks/res/ss-menu.js
		echo ".show-btn5, .show-btn6{display: none;}" >> /tmp/shadowsocks/res/shadowsocks.css
	fi
	sync

	# 检测储存空间是否足够
	echo_date "检测jffs分区剩余空间..."
	SPACE_AVAL=$(df|grep jffs | awk '{print $4}')
	SPACE_NEED=$(du -s /tmp/shadowsocks | awk '{print $1}')
	if [ "$SPACE_AVAL" -gt "$SPACE_NEED" ];then
		echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装大概需要"$SPACE_NEED" KB，空间满足，继续安装！
	else
		echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装大概需要"$SPACE_NEED" KB，空间不足！
		echo_date 退出安装！
		exit 1
	fi

	# isntall file
	echo_date "开始复制文件！"
	cd /tmp

	echo_date "复制相关二进制文件！此步时间可能较长！"
	cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/
	
	echo_date "复制相关的脚本文件！"
	cp -rf /tmp/shadowsocks/ss /koolshare/
	cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
	cp -rf /tmp/shadowsocks/install.sh /koolshare/scripts/ss_install.sh
	cp -rf /tmp/shadowsocks/uninstall.sh /koolshare/scripts/uninstall_shadowsocks.sh
	
	echo_date "复制相关的网页文件！"
	cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
	cp -rf /tmp/shadowsocks/res/* /koolshare/res/

	sync

	# Permissions
	echo_date "为新安装文件赋予执行权限..."
	chmod 755 /koolshare/ss/rules/* >/dev/null 2>&1
	chmod 755 /koolshare/ss/* >/dev/null 2>&1
	chmod 755 /koolshare/scripts/ss* >/dev/null 2>&1
	chmod 755 /koolshare/bin/* >/dev/null 2>&1

	# intall different UI
	get_ui_type
	if [ "${UI_TYPE}" == "ROG" ];then
		echo_date "为插件安装ROG UI..."
		cp -rf /tmp/shadowsocks/rog/res/shadowsocks.css /koolshare/res/
	fi
	
	if [ "${UI_TYPE}" == "TUF" ];then
		echo_date "为插件安装TUF UI..."
		sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /tmp/shadowsocks/rog/res/shadowsocks.css >/dev/null 2>&1
		cp -rf /tmp/shadowsocks/rog/res/shadowsocks.css /koolshare/res/
	fi

	if [ "${UI_TYPE}" == "ASUSWRT" ];then
		echo_date "为插件安装ASUSWRT UI..."
	fi

	# restore backup
	if [ -n "$(ls /tmp/ss_backup/P*.sh 2>/dev/null)" ];then
		echo_date "恢复触发脚本!"
		mkdir -p /koolshare/ss/postscripts
		find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /koolshare/ss/postscripts
	fi

	# soft links
	echo_date "创建一些二进制文件的软链接！"
	[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel
	[ ! -L "/koolshare/init.d/S99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/S99shadowsocks.sh
	[ ! -L "/koolshare/init.d/N99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/N99shadowsocks.sh
	[ ! -L "/koolshare/init.d/S99socks5.sh" ] && ln -sf /koolshare/scripts/ss_socks5.sh /koolshare/init.d/S99socks5.sh

	# default values
	echo_date "设置一些默认值..."
	[ -z "$(dbus get ss_dns_china)" ] && dbus set ss_dns_china=11
	[ -z "$(dbus get ss_dns_foreign)" ] && dbus set ss_dns_foreign=1
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=1
	[ -z "$(dbus get ss_acl_default_port)" ] && dbus set ss_acl_default_port=all
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2

	# 设置v2ray 版本号
	dbus set ss_basic_v2ray_version="v4.22.0"

	# dbus value
	echo_date "设置插件安装参数..."
	dbus set ss_basic_version_local="${PLVER}"
	dbus set softcenter_module_${module}_version="${PLVER}"
	dbus set softcenter_module_${module}_install="4"
	dbus set softcenter_module_${module}_name="${module}"
	dbus set softcenter_module_${module}_title="${TITLE}"
	dbus set softcenter_module_${module}_description="${DESCR}"
	
	# finish
	echo_date "${TITLE}插件安装安装成功！"

	# restart
	if [ "${ENABLE}" == "1" -a -f "/koolshare/ss/ssconfig.sh" ];then
		echo_date 重启科学上网插件！
		sh /koolshare/ss/ssconfig.sh restart
	fi

	echo_date "更新完毕，请等待网页自动刷新！"
	
	exit_install
}

install(){
	get_model
	get_fw_type
	platform_test
	install_now
}

install
