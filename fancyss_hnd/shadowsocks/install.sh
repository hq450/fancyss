#! /bin/sh

eval `dbus export ss`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
mkdir -p /koolshare/ss

# 判断路由架构和平台
case $(uname -m) in
  aarch64)
	if [ "`uname -o|grep Merlin`" ] && [ -d "/koolshare" ];then
		echo_date 固件平台【koolshare merlin aarch64】符合安装要求，开始安装插件！
	else
		echo_date 本插件适用于【koolshare merlin aarch64】固件平台，你的平台不能安装！！！
		exit 1
	fi
    ;;
  *)
  	echo_date 本插件适用于koolshare merlin aarch64固件平台，你的平台：$(uname -m)不能安装！！！
  	echo_date 退出安装！
    exit 1
    ;;
esac

# 先关闭ss
if [ "$ss_basic_enable" == "1" ];then
	echo_date 先关闭科学上网插件，保证文件更新成功!
	[ -f "/koolshare/ss/stop.sh" ] && sh /koolshare/ss/stop.sh stop_all || sh /koolshare/ss/ssconfig.sh stop
fi

if [ -n "`ls /koolshare/ss/postscripts/P*.sh 2>/dev/null`" ];then
	echo_date 备份触发脚本!
	find /koolshare/ss/postscripts -name "P*.sh" | xargs -i mv {} -f /tmp/ss_backup
fi

# 如果dnsmasq是mounted状态，先恢复
MOUNTED=`mount|grep -o dnsmasq`
if [ -n "$MOUNTED" ];then
	echo_date 恢复dnsmasq-fastlookup为原版dnsmasq
	killall dnsmasq >/dev/null 2>&1
	umount /usr/sbin/dnsmasq
	service restart_dnsmasq >/dev/null 2>&1
fi

#升级前先删除无关文件
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
rm -rf /koolshare/bin/Pcap_DNSProxy
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
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/haveged
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/dnsmassq
rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfw.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png
rm -rf /koolshare/res/shadowsocks.css
find /koolshare/init.d/ -name "*shadowsocks.sh" | xargs rm -rf
find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf

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
if [ "`nvram get model`" == "GT-AC5300" ] || [ -n "`nvram get extendno | grep koolshare`" -a "`nvram get productid`" == "RT-AC86U" ];then
	cp -rf /tmp/shadowsocks/GT-AC5300/webs/* /koolshare/webs/
	cp -rf /tmp/shadowsocks/GT-AC5300/res/* /koolshare/res/
fi

echo_date 为新安装文件赋予执行权限...
chmod 755 /koolshare/ss/rules/*
chmod 755 /koolshare/ss/*
chmod 755 /koolshare/scripts/ss*
chmod 755 /koolshare/bin/*

if [ -n "`ls /tmp/ss_backup/P*.sh 2>/dev/null`" ];then
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
[ -z "$ss_acl_default_mode" ] && [ -n "$ss_basic_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode"
[ -z "$ss_acl_default_mode" ] && [ -z "$ss_basic_mode" ] && dbus set ss_acl_default_mode=1
[ -z "$ss_acl_default_port" ] && dbus set ss_acl_default_port=all
[ "$ss_basic_v2ray_network" == "ws_hd" ] && dbus set ss_basic_v2ray_network="ws"

# 离线安装时设置软件中心内储存的版本号和连接
CUR_VERSION=`cat /koolshare/ss/version`
dbus set ss_basic_version_local="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_install="4"
dbus set softcenter_module_shadowsocks_version="$CUR_VERSION"
dbus set softcenter_module_shadowsocks_title="科学上网"
dbus set softcenter_module_shadowsocks_description="科学上网"

# 设置v2ray 版本号
dbus set ss_basic_v2ray_version="v3.39"
dbus set ss_basic_v2ray_date="20180906"

echo_date 一点点清理工作...
rm -rf /tmp/shadowsocks* >/dev/null 2>&1

echo_date 科学上网插件安装成功！

if [ "$ss_basic_enable" == "1" ];then
	echo_date 重启ss！
	sh /koolshare/ss/ssconfig.sh restart
fi

echo_date 更新完毕，请等待网页自动刷新！

