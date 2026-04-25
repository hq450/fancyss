#! /bin/sh

# fancyss script for asuswrt/merlin based router with software center

remove_dbus_prefix(){
	local prefix="$1"
	local line key
	dbus list "${prefix}" | while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		key=${line%%=*}
		[ -n "${key}" ] || continue
		case "${key}" in
			ssid_*|ssserver_*)
				continue
				;;
		esac
		dbus remove "${key}" >/dev/null 2>&1
	done
}

purge_fancyss_dbus(){
	remove_dbus_prefix ss
	remove_dbus_prefix ssconf
	remove_dbus_prefix fss
	remove_dbus_prefix softcenter_module_shadowsocks
}

remove_fancyss_cron(){
	cru d ssupdate >/dev/null 2>&1
	cru d ss_reboot >/dev/null 2>&1
	cru d ssnode >/dev/null 2>&1
	cru d sswebtest >/dev/null 2>&1
	cru d fancyss_webtest >/dev/null 2>&1
	cru d fancyss_subscribe >/dev/null 2>&1
	sed -i '/ssconfig\.sh/d;/ss_rule_update\.sh/d;/ss_node_subscribe\.sh/d;/ss_webtest\.sh/d;/fancyss/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
}

# stop process
sh /koolshare/ss/ssconfig.sh stop >/dev/null 2>&1

# stop websockted
killall websocketd >/dev/null 2>&1

# remove configure
sh /koolshare/scripts/ss_conf.sh koolshare 3 >/dev/null 2>&1
purge_fancyss_dbus
remove_fancyss_cron

# remove websockted
rm -rf /koolshare/bin/websocketd >/dev/null 2>&1

# remove files
rm -rf /koolshare/scripts/ss_*
rm -rf /koolshare/webs/Module_shadowsocks*
rm -rf /koolshare/bin/rss-tunnel
rm -rf /koolshare/bin/rss-local
rm -rf /koolshare/bin/obfs-local
rm -rf /koolshare/bin/kcptun
rm -rf /koolshare/bin/chinadns-ng
rm -rf /koolshare/bin/smartdns
rm -rf /koolshare/bin/speederv1
rm -rf /koolshare/bin/speederv2
rm -rf /koolshare/bin/udp2raw
rm -rf /koolshare/bin/trojan
rm -rf /koolshare/bin/tuic-client
rm -rf /koolshare/bin/xray
rm -rf /koolshare/bin/v2ray
rm -rf /koolshare/bin/curl-fancyss
rm -rf /koolshare/bin/hysteria2
rm -rf /koolshare/bin/haveged
rm -rf /koolshare/bin/naive
rm -rf /koolshare/bin/ipt2socks
rm -rf /koolshare/bin/dnsclient
rm -rf /koolshare/bin/sslocal
rm -rf /koolshare/bin/node-tool
rm -rf /koolshare/bin/xapi-tool
rm -rf /koolshare/bin/sub-tool
rm -rf /koolshare/bin/geotool
rm -rf /koolshare/bin/webtest-tool
rm -rf /koolshare/bin/webtestctl
rm -rf /koolshare/bin/status-tool
rm -rf /koolshare/bin/statusctl

# 如果系统里有jq，删掉/koolshare/bin/jq
if [ -n /usr/bin/jq ];then
	rm -rf /koolshare/bin/jq >/dev/null 2>&1
fi

rm -rf /koolshare/res/icon-shadowsocks.png
rm -rf /koolshare/res/arrow-down.gif
rm -rf /koolshare/res/arrow-up.gif
rm -rf /koolshare/res/ss-menu.js
rm -rf /koolshare/res/qrcode.js
rm -rf /koolshare/res/tablednd.js

# some file may exist in /data
rm -rf /data/xray >/dev/null 2>&1
rm -rf /data/v2ray >/dev/null 2>&1
rm -rf /data/hysteria2 >/dev/null 2>&1
rm -rf /data/naive >/dev/null 2>&1
rm -rf /data/sslocal >/dev/null 2>&1
rm -rf /data/rss-local >/dev/null 2>&1
rm -rf /data/rss-redir >/dev/null 2>&1
rm -rf /data/ss-local >/dev/null 2>&1
rm -rf /data/ss-redir >/dev/null 2>&1
rm -rf /data/ss-tunnel >/dev/null 2>&1

# folder renmove
rm -rf /koolshare/ss
rm -rf /koolshare/configs/fancyss
rm -rf /koolshare/.valid

rm -rf /koolshare/res/shadowsocks.css
rm -rf /koolshare/res/fancyss.css
find /koolshare/init.d/ -name "*shadowsocks.sh" | xargs rm -rf
find /koolshare/init.d/ -name "*socks5.sh" | xargs rm -rf

# optional file maybe exist should be removed
rm -rf /koolshare/bin/sslocal
rm -rf /koolshare/bin/dig

# legacy file should be removed for sure
rm -rf /koolshare/bin/v2ray-plugin
rm -rf /koolshare/bin/haproxy
rm -rf /koolshare/bin/dohclient
rm -rf /koolshare/bin/dohclient-cache
rm -rf /koolshare/bin/dns2socks
rm -rf /koolshare/bin/dns2tcp
rm -rf /koolshare/bin/dns-ecs-forcer
rm -rf /koolshare/bin/uredir
rm -rf /koolshare/bin/v2ctl
rm -rf /koolshare/bin/dnsmasq
rm -rf /koolshare/bin/Pcap_DNSProxy
rm -rf /koolshare/bin/client_linux_arm*
rm -rf /koolshare/bin/cdns
rm -rf /koolshare/bin/chinadns
rm -rf /koolshare/bin/chinadns1
rm -rf /koolshare/bin/https_dns_proxy
rm -rf /koolshare/bin/pdu
rm -rf /koolshare/bin/koolgame
rm -rf /koolshare/bin/dnscrypt-proxy
rm -rf /koolshare/bin/resolveip
rm -rf /koolshare/bin/httping
rm -rf /koolshare/bin/ss-redir
rm -rf /koolshare/bin/ss-tunnel
rm -rf /koolshare/bin/ss-local
rm -rf /koolshare/bin/rss-redir
rm -rf /koolshare/res/all.png
rm -rf /koolshare/res/gfw.png
rm -rf /koolshare/res/chn.png
rm -rf /koolshare/res/game.png

# maybe used by other plugin, do not remove
# rm -rf /koolshare/bin/sponge >/dev/null 2>&1
# rm -rf /koolshare/bin/isutf8 >/dev/null 2>&1
purge_fancyss_dbus

rm -rf /tmp/fancyss_* >/dev/null 2>&1
rm -rf /tmp/ss_conf_* >/dev/null 2>&1
rm -rf /tmp/ss_backup >/dev/null 2>&1
rm -f /tmp/upload/ss_log.txt \
	/tmp/upload/ss_status.txt \
	/tmp/upload/ssc_status.txt \
	/tmp/upload/ssf_status.txt \
	/tmp/upload/webtest.txt \
	/tmp/upload/webtest_bakcup.txt \
	/tmp/upload/webtest_backup.txt \
	/tmp/upload/websocketd.log >/dev/null 2>&1
