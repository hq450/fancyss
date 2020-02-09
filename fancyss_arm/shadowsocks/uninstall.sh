#! /bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

sh /koolshare/ss/ssconfig.sh stop
sh /koolshare/scripts/ss_conf_remove.sh
sleep 1

# 如果dnsmasq是mounted状态，先恢复
MOUNTED=`mount|grep -o dnsmasq`
if [ -n "$MOUNTED" ];then
	echo_date 恢复dnsmasq-fastlookup为原版dnsmasq
	killall dnsmasq >/dev/null 2>&1
	umount /usr/sbin/dnsmasq
	service restart_dnsmasq >/dev/null 2>&1
fi

rm -rf /koolshare/ss/*
rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Main_Ss*
rm -rf /koolshare/bin/ss-redir
rm -rf /koolshare/bin/ss-tunnel
rm -rf /koolshare/bin/ss-local
rm -rf /koolshare/bin/rss-redir
rm -rf /koolshare/bin/rss-tunnel
rm -rf /koolshare/bin/rss-local
rm -rf /koolshare/bin/obfs-local
rm -rf /koolshare/bin/v2ray-plugin
rm -rf /koolshare/bin/koolgame
rm -rf /koolshare/bin/pdu
rm -rf /koolshare/bin/haproxy
rm -rf /koolshare/bin/pdnsd
rm -rf /koolshare/bin/Pcap_DNSProxy
rm -rf /koolshare/bin/dnscrypt-proxy
rm -rf /koolshare/bin/dns2socks
rm -rf /koolshare/bin/cdns
rm -rf /koolshare/bin/client_linux_arm5
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/chinadns1
rm -rf /koolshare/bin/resolveip
rm -rf /koolshare/bin/udp2raw
rm -rf /koolshare/bin/speeder*
rm -rf /koolshare/bin/v2ray
rm -rf /koolshare/bin/v2ctl
rm -rf /koolshare/bin/jitterentropy-rngd
rm -rf /koolshare/bin/haveged
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/dnsmasq
rm -rf /koolshare/res/layer
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfwlist.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png
rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/gameV2.png
rm -rf /koolshare/res/ss_proc_status.htm
rm -rf /koolshare/init.d/S89Socks5.sh

# remove start up command
sed -i '/ssconfig.sh/d' /koolshare/scripts/wan-start >/dev/null 2>&1
sed -i '/ssconfig.sh/d' /koolshare/scripts/nat-start >/dev/null 2>&1

dbus remove softcenter_module_shadowsocks_home_url
dbus remove softcenter_module_shadowsocks_install
dbus remove softcenter_module_shadowsocks_md5
dbus remove softcenter_module_shadowsocks_version

dbus remove ss_basic_enable
dbus remove ss_basic_version_local
dbus remove ss_basic_version_web
