#! /bin/sh

# shadowsocks script for koolshare merlin armv7l 384/386 router with kernel 2.6.36.4

source /koolshare/scripts/base.sh
eval $(dbus export ss)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
odmpid=$(nvram get odmpid)
productid=$(nvram get productid)
[ -n "${odmpid}" ] && MODEL="${odmpid}" || MODEL="${productid}"
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
mkdir -p /koolshare/ss
mkdir -p /tmp/upload

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n "${FWTYPE}" ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于【koolshare merlin armv7l 384/386】固件平台！"
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

# 判断路由架构和平台
if [ -d "/koolshare" -a -f "/usr/bin/skipd" -a "${LINUX_VER}" -eq "26" ];then
	echo_date 机型：${MODEL} $(_get_type) 符合安装要求，开始安装插件！
else
	exit_install 1
fi

# 先关闭fancyss
if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭科学上网插件，保证文件更新成功!
	[ -f "/koolshare/ss/stop.sh" ] && sh /koolshare/ss/stop.sh stop_all || sh /koolshare/ss/ssconfig.sh stop
fi

if [ -n "$(ls /koolshare/ss/postscripts/P*.sh 2>/dev/null)" ];then
	echo_date 备份触发脚本!
	find /koolshare/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
fi

# 如果dnsmasq是mounted状态，先恢复
MOUNTED=$(mount|grep -o dnsmasq)
if [ -n "$MOUNTED" ];then
	echo_date 恢复dnsmasq-fastlookup为原版dnsmasq
	killall dnsmasq >/dev/null 2>&1
	umount /usr/sbin/dnsmasq
	service restart_dnsmasq >/dev/null 2>&1
fi

echo_date 清理旧文件
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
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/chinadns1
rm -rf /koolshare/bin/resolveip
rm -rf /koolshare/bin/speederv1
rm -rf /koolshare/bin/speederv2
rm -rf /koolshare/bin/udp2raw
rm -rf /koolshare/bin/v2ray
rm -rf /koolshare/bin/v2ctl
rm -rf /koolshare/bin/v2ray-plugin
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/haveged
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/httping
rm -rf /koolshare/bin/dnsmassq
rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/qrcode.js
rm -rf /koolshare/res/tablednd.js
rm -rf /koolshare/res/shadowsocks.css
find /koolshare/init.d/ -name "*shadowsocks.sh" | xargs rm -rf
find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf

# 检测储存空间是否足够
echo_date 检测jffs分区剩余空间...
SPACE_AVAL=$(df|grep jffs | awk '{print $4}')
SPACE_NEED=$(du -s /tmp/shadowsocks | awk '{print $1}')
if [ "$SPACE_AVAL" -gt "$SPACE_NEED" ];then
	echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装大概需要"$SPACE_NEED" KB，空间满足，继续安装！
else
	echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装大概需要"$SPACE_NEED" KB，空间不足！
	echo_date 退出安装！
	exit 1
fi

echo_date 开始复制文件！
cd /tmp

echo_date 复制相关二进制文件！此步时间可能较长！
cp -rf /tmp/shadowsocks/bin/* /koolshare/bin/

echo_date 复制相关的脚本文件！
cp -rf /tmp/shadowsocks/ss/* /koolshare/ss/
cp -rf /tmp/shadowsocks/scripts/* /koolshare/scripts/
cp -rf /tmp/shadowsocks/install.sh /koolshare/scripts/ss_install.sh
cp -rf /tmp/shadowsocks/uninstall.sh /koolshare/scripts/uninstall_shadowsocks.sh

echo_date 复制相关的网页文件！
cp -rf /tmp/shadowsocks/webs/* /koolshare/webs/
cp -rf /tmp/shadowsocks/res/* /koolshare/res/

echo_date 为新安装文件赋予执行权限...
chmod 755 /koolshare/ss/rules/*
chmod 755 /koolshare/ss/*
chmod 755 /koolshare/scripts/ss*
chmod 755 /koolshare/bin/*

if [ -n "$(ls /tmp/ss_backup/P*.sh 2>/dev/null)" ];then
	echo_date 恢复触发脚本!
	mkdir -p /koolshare/ss/postscripts
	find /tmp/ss_backup -name "P*.sh" | xargs -i mv {} -f /koolshare/ss/postscripts
fi

echo_date 创建一些二进制文件的软链接！
[ ! -L "/koolshare/bin/rss-tunnel" ] && ln -sf /koolshare/bin/rss-local /koolshare/bin/rss-tunnel
[ ! -L "/koolshare/init.d/S99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/S99shadowsocks.sh
[ ! -L "/koolshare/init.d/N99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/N99shadowsocks.sh
[ ! -L "/koolshare/init.d/S99socks5.sh" ] && ln -sf /koolshare/scripts/ss_socks5.sh /koolshare/init.d/S99socks5.sh

# 设置一些默认值
echo_date 设置一些默认值
[ -z "$ss_dns_china" ] && dbus set ss_dns_china=11
[ -z "$ss_dns_foreign" ] && dbus set ss_dns_foreign=1
[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode=1
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all
[ -z "$ss_basic_interval" ] && dbus set ss_basic_interval=2

# 离线安装时设置软件中心内储存的版本号和连接
CUR_VERSION=$(cat /koolshare/ss/version)
dbus set ss_basic_version_local="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_install="4"
dbus set softcenter_module_shadowsocks_version="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_title="科学上网"
dbus set softcenter_module_shadowsocks_description="科学上网 for merlin armv7l 384"

# 设置v2ray 版本号
dbus set ss_basic_v2ray_version="v4.21.3"

echo_date 一点点清理工作...
rm -rf /tmp/shadowsocks* >/dev/null 2>&1

echo_date 科学上网插件安装成功！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启科学上网插件！
	sh /koolshare/ss/ssconfig.sh restart
fi

echo_date 更新完毕，请等待网页自动刷新！
