#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

# 此脚本用以在插件启动完毕后删掉/jffs/configs/dnsmasq.d/ss_host.conf
# 以免使用相同一级域名的二级域名的其它二级域名解析出现问题
# 同时避免因SS服务器IP地址更换后，仍然解析到老的ip

remove_dnsmasq_restart_delay(){
	if [ -L "/jffs/configs/dnsmasq.d/ss_host.conf" ];then
		rm -rf /jffs/configs/dnsmasq.d/ss_host.conf
		service restart_dnsmasq >/dev/null 2>&1
	fi
	#cru	d ss_dnsmasq_restart >/dev/null 2>&1
	sed -i '/ss_dnsmasq_restart/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
}

case "$1" in
	restart)
		remove_dnsmasq_restart_delay
	;;
esac

# =================================
# 4.0.1版本使用了该功能

# 4.0.2后删除此功能，因为在v2ray服务器填域名时，删除ss_host.conf会造成解析错误而导致问题

# 脚本暂时保留，以待后期观察
# =================================
