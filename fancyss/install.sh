#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=
FW_TYPE_NAME=
DIR=$(cd $(dirname $0); pwd)
module=${DIR##*/}
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')

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
	local KS_TAG=$(nvram get extendno|grep -E "_kool")
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			FW_TYPE_NAME="koolshare官改固件"
		else
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			FW_TYPE_NAME="梅林原版固件"
		else
			FW_TYPE_NAME="华硕官方固件"
		fi
	fi
}

platform_test(){
	# 带koolshare文件夹，有httpdb和skipdb的固件位支持固件
	if [ -d "/koolshare" -a -x "/koolshare/bin/httpdb" -a -x "/usr/bin/skipd" ];then
		echo_date "机型：${MODEL} ${FW_TYPE_NAME} 符合安装要求，开始安装插件！"
	else
		exit_install 1
	fi

	# 继续判断各个固件的内核和架构
	local PKG_ARCH=$(cat ${DIR}/.valid)
	local ROT_ARCH=$(uname -m)
	local KEL_VERS=$(uname -r)
	if [ ! -x "/tmp/shadowsocks/bin/v2ray" ];then
		PKG_TYPE="lite"
		PKG_NAME="fancyss_${PKG_ARCH}_lite"
	else
		PKG_TYPE="full"
		PKG_NAME="fancyss_${PKG_ARCH}_full"
	fi

	# fancyss_arm
	if [ "${PKG_ARCH}" == "arm" ];then
		if [ "${LINUX_VER}" == "26" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# ok
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_arm_${PKG_TYPE}！"
			else
				# maybe mipsel, RT-AC66U... 
				echo_date "架构：${ROT_ARCH}，fancyss_arm_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			# RT-AC86U, RT-AX86U, RT-AX56U, GT-AX6000, XT12...
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_arm_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
			exit_install 1
		elif [ "${LINUX_VER}" == "44" ];then
			# RT-AX89X
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_arm_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"		
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
		else
			# future model
			echo_date "内核：${KEL_VERS}，fancyss_arm_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi
	
	# fancyss_hnd
	if [ "${PKG_ARCH}" == "hnd" ];then
		if [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			if [ "${ROT_ARCH}" == "armv7l" ];then
				# RT-AX56U, XT8, TUF-AX3000_V2
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_hnd_${PKG_TYPE}！"
			elif  [ "${ROT_ARCH}" == "aarch64" ];then
				# RT-AX86U, RT-AX88U
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_hnd_${PKG_TYPE}！"
			else
				# no such model, yet.
				echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该架构！退出！"
				exit_install 1
			fi
		elif [ "${LINUX_VER}" == "26" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
			
		elif [ "${LINUX_VER}" == "44" ];then
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_qca_full或者fancyss_qca_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_qca"
			exit_install 1
			
		else
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_hnd_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi
	
	# fancyss_qca
	if [ "${PKG_ARCH}" == "qca" ];then
		if [ "${LINUX_VER}" == "44" ];then
			# RT-AX89X
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，安装fancyss_qca_${PKG_TYPE}！"
		elif [ "${LINUX_VER}" == "26" ];then
			# RT-AC68U, RT-AC88U, RT-AC3100, RT-AC5300
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_qca_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_arm_full或者fancyss_arm_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_arm"
			exit_install 1
			
		elif [ "${LINUX_VER}" == "41" -o "${LINUX_VER}" == "419" ];then
			# RT-AC86U, RT-AX86U, RT-AX56U, GT-AX6000, XT12...
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_qca_${PKG_TYPE}不适用于该内核版本！"
			echo_date "建议使用fancyss_hnd_full或者fancyss_hnd_lite！"
			echo_date "下载地址：https://github.com/hq450/fancyss_history_package/tree/master/fancyss_hnd"
			exit_install 1
			
		else
			# no such model, yet.
			echo_date "内核：${KEL_VERS}，架构：${ROT_ARCH}，fancyss_qca_${PKG_TYPE}不适用于该内核版本！"
			exit_install 1
		fi
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css|head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	
	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

exit_install(){
	local state=$1
	local PKG_ARCH=$(cat ${DIR}/.valid)
	case $state in
		1)
			echo_date "fancyss项目地址：https://github.com/hq450/fancyss"
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
	local PLVER=$(cat ${DIR}/ss/version)

	# print message
	local TITLE="科学上网 ${PKG_TYPE}"
	local DESCR="科学上网 ${PKG_TYPE} for merlin hnd platform"
	echo_date "安装版本：${PKG_NAME}_${PLVER}"
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
	rm -rf /koolshare/bin/kcptun
	rm -rf /koolshare/bin/cdns
	rm -rf /koolshare/bin/chinadns
	rm -rf /koolshare/bin/chinadns1
	rm -rf /koolshare/bin/chinadns-ng
	rm -rf /koolshare/bin/smartdns
	rm -rf /koolshare/bin/resolveip
	rm -rf /koolshare/bin/speederv1
	rm -rf /koolshare/bin/speederv2
	rm -rf /koolshare/bin/udp2raw
	rm -rf /koolshare/bin/trojan
	rm -rf /koolshare/bin/xray
	rm -rf /koolshare/bin/v2ray
	rm -rf /koolshare/bin/v2ray-plugin
	rm -rf /koolshare/bin/https_dns_proxy
	rm -rf /koolshare/bin/httping
	rm -rf /koolshare/bin/isutf8
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
	rm -rf /koolshare/bin/v2ctl >/dev/null 2>&1
	rm -rf /koolshare/bin/dnsmasq >/dev/null 2>&1
	rm -rf /koolshare/bin/Pcap_DNSProxy >/dev/null 2>&1
	rm -rf /koolshare/bin/client_linux_arm*

	# optional files should keep
	# rm -rf /koolshare/bin/sslocal >/dev/null 2>&1

	# these file maybe used by others plugin
	# rm -rf /koolshare/bin/sponge >/dev/null 2>&1
	# rm -rf /koolshare/bin/jq >/dev/null 2>&1

	# small jffs router should remove more
	if [ "${MODEL}" == "RT-AX56U_V2" ];then
		rm -rf /jffs/syslog.log
		rm -rf /jffs/syslog.log-1
		rm -rf /jffs/wglist
		rm -rf /jffs/uu.tar.gz*
		echo 1 > /proc/sys/vm/drop_caches
		sync
	fi

	# 检测储存空间是否足够
	echo_date "检测jffs分区剩余空间..."
	SPACE_AVAL=$(df | grep -w "/jffs" | awk '{print $4}')
	SPACE_NEED=$(du -s /tmp/shadowsocks | awk '{print $1}')
	if [ "$SPACE_AVAL" -gt "$SPACE_NEED" ];then
		echo_date "当前jffs分区剩余${SPACE_AVAL}KB, 插件安装大概需要${SPACE_NEED}KB，空间满足，继续安装！"
	else
		echo_date "当前jffs分区剩余${SPACE_AVAL}KB, 插件安装大概需要${SPACE_NEED}KB，空间不足！"
		echo_date "退出安装！"
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
	set_skin

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
	# 1.9.15：国内DNS默认使用运营商DNS
	[ -z "$(dbus get ss_dns_china)" ] && dbus set ss_dns_china=1
	# 1.9.15：国外dns解析设置为chinadns-ng，并默认丢掉AAAA记录
	[ -z "$(dbus get ss_foreign_dns)" ] && dbus set ss_foreign_dns=10
	[ -z "$(dbus get ss_disable_aaaa)" ] && dbus set ss_disable_aaaa=1
	# others
	[ -z "$(dbus get ss_acl_default_mode)" ] && dbus set ss_acl_default_mode=1
	[ -z "$(dbus get ss_acl_default_port)" ] && dbus set ss_acl_default_port=all
	[ -z "$(dbus get ss_basic_interval)" ] && dbus set ss_basic_interval=2
	# lite
	if [ ! -x "/tmp/shadowsocks/bin/v2ray" ];then
		ss_basic_vcore=1
	fi
	if [ ! -x "/tmp/shadowsocks/bin/trojan" ];then
		ss_basic_tcore=1
	fi
	
	if [ ! -x "/tmp/shadowsocks/bin/smartdns" ];then
		local SFD=$(dbus get ss_foreign_dns)
		local SDC=$(dbus get ss_dns_china)
		if [ "${SFD}" != "3" -o "${SFD}" != "6" -o "${SFD}" != "7" -o "${SFD}" != "8" -o "${SFD}" != "10" ];then
			dbus set ss_foreign_dns=10
			dbus set ss_disable_aaaa=1
		fi
		if [ "${SDC}" -gt "15" ];then
			dbus set ss_dns_china=1
		fi
	fi

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
