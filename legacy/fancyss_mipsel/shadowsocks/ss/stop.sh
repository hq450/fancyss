#!/bin/sh
#--------------------------------------------------------------------------
# Variable definitions
# source /koolshare/configs/ss.sh
eval `dbus export shadowsocks`
eval `dbus export ss`
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'
redsocks2=$(ps | grep "redsocks2" | grep -v "grep")
dnscrypt=$(ps | grep "dnscrypt-proxy" | grep -v "grep")
sokcs5=$(ps|grep ss-local|grep -vw rss-local|grep -v 23456|cut -d " " -f 1)
ssredir=$(ps | grep "ss-redir" | grep -v "grep" | grep -vw "rss-redir")
rssredir=$(ps | grep "rss-redir" | grep -v "grep" | grep -vw "ss-redir")
sstunnel=$(ps | grep "ss-tunnel" | grep -v "grep" | grep -vw "rss-tunnel")
rsstunnel=$(ps | grep "rss-tunnel" | grep -v "grep" | grep -vw "ss-tunnel")
pdnsd=$(ps | grep "pdnsd" | grep -v "grep")
chinadns=$(ps | grep "chinadns" | grep -v "grep")
DNS2SOCK=$(ps | grep "dns2socks" | grep -v "grep")
koolgame=$(ps | grep "koolgame" | grep -v "grep"|grep -v "pdu")
client_linux_mipsel=$(ps | grep "client_linux_mipsel" | grep -v "grep")
haproxy=$(ps | grep "haproxy" | grep -v "grep")
obfsLocal=$(ps | grep "obfs-local" | grep -v "grep")
lan_ipaddr=$(nvram get lan_ipaddr)
ip_rule_exist=`/usr/sbin/ip rule show | grep "fwmark 0x1/0x1 lookup 310" | grep -c 310`
nvram set ss_mode=0
dbus set dns2socks=0
nvram commit

#--------------------------------------------------------------------------

restore_conf(){
	# restore dnsmasq conf file
	if [ -f /jffs/configs/dnsmasq.conf.add ]; then
		echo_date 恢复dnsmasq配置文件.
		rm -f /jffs/configs/dnsmasq.conf.add
	fi
	#--------------------------------------------------------------------------
	# delete dnsmasq postconf file
	if [ -f /jffs/scripts/dnsmasq.postconf ]; then
		echo_date 删除/jffs/scripts/dnsmasq.postconf
		rm -f /jffs/scripts/dnsmasq.postconf
	fi
	#--------------------------------------------------------------------------
	# delete custom.conf
	if [ -f /jffs/configs/dnsmasq.d/custom.conf ];then
		echo_date 删除 /jffs/configs/dnsmasq.d/custom.conf
		rm -rf /jffs/configs/dnsmasq.d/custom.conf
	fi	
}

bring_up_dnsmasq(){
	# Bring up dnsmasq
	echo_date 重启dnsmasq服务...
	service restart_dnsmasq >/dev/null 2>&1
}

restore_nat(){
	echo_date 尝试先清除已存在的iptables规则，防止重复添加
	# flush rules and set if any
	iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS >/dev/null 2>&1
	sleep 1
	iptables -t nat -F SHADOWSOCKS > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GFW > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GFW > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_CHN > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_CHN > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GLO > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GLO > /dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_HOM > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_HOM > /dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m set --set router dst -j REDIRECT --to-ports 3333 >/dev/null 2>&1
	iptables -t nat -D PREROUTING -p udp --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
	
	#ip route del local 0.0.0.0/0 dev lo table 300  >/dev/null 2>&1
	/usr/sbin/ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
	
	
	
	if [ ! -z "ip_rule_exist" ];then
		until [ "$ip_rule_exist" = 0 ]
		do 
			#ip rule del fwmark 0x01/0x01 table 310
			/usr/sbin/ip rule del fwmark 0x01/0x01 table 310 pref 789
			ip_rule_exist=`expr $ip_rule_exist - 1`
		done
	fi
	
}

destory_ipset(){
	# flush and destory ipset
	ipset -F router >/dev/null 2>&1
	ipset -F chnroute >/dev/null 2>&1
	ipset -F white_ip >/dev/null 2>&1
	ipset -F white_cidr >/dev/null 2>&1
	ipset -F black_ip >/dev/null 2>&1
	ipset -F black_cidr >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1
	
	ipset -X router >/dev/null 2>&1
	ipset -X chnroute >/dev/null 2>&1
	ipset -X white_ip >/dev/null 2>&1
	ipset -X white_cidr >/dev/null 2>&1
	ipset -X black_ip >/dev/null 2>&1
	ipset -X black_cidr >/dev/null 2>&1
	ipset -X gfwlist >/dev/null 2>&1
}

restore_start_file(){
	echo_date 清除nat-start, wan-start中相关的SS启动命令...
	
	# restore nat-start file if any
	sed -i '/source/,/warning/d' /jffs/scripts/nat-start >/dev/null 2>&1
	sed -i '/nat-start/d' /jffs/scripts/nat-start >/dev/null 2>&1
	sed -i '/koolshare/d' /jffs/scripts/nat-start >/dev/null 2>&1
	sed -i '/sleep 5/d' /jffs/scripts/nat-start >/dev/null 2>&1
	
	# clear start up command line in wan-start
	sed -i '/start.sh/d' /jffs/scripts/wan-start >/dev/null 2>&1
	sed -i '/ssconfig/d' /jffs/scripts/wan-start >/dev/null 2>&1
	sed -i '/koolshare/d' /jffs/scripts/wan-start >/dev/null 2>&1
	sed -i '/sleep/d' /jffs/scripts/wan-start >/dev/null 2>&1
	sed -i '/sleep/d' /jffs/scripts/nat-start >/dev/null 2>&1	
}

kill_process(){
	#--------------------------------------------------------------------------
	# kill dnscrypt-proxy
	if [ ! -z "$dnscrypt" ]; then 
		echo_date 关闭dnscrypt-proxy进程...
		killall dnscrypt-proxy
	fi
	#--------------------------------------------------------------------------
	# kill redsocks2
	if [ ! -z "$redsocks2" ]; then 
		echo_date 关闭redsocks2进程...
		killall redsocks2
	fi
	#--------------------------------------------------------------------------
	# kill ss-redir
	if [ ! -z "$ssredir" ];then 
		echo_date 关闭ss-redir进程...
		killall ss-redir
	fi


	if [ ! -z "$rssredir" ];then 
		echo_date 关闭ssr-redir进程...
		killall rss-redir
	fi
	#--------------------------------------------------------------------------
	# kill ss-local
	sslocal=`ps | grep ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ ! -z "$sslocal" ];then 
		echo_date 关闭ss-local进程:23456端口...
		kill $sslocal  >/dev/null 2>&1
	fi


	ssrlocal=`ps | grep rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ ! -z "$ssrlocal" ];then 
		echo_date 关闭ssr-local进程:23456端口...
		kill $ssrlocal  >/dev/null 2>&1
	fi

	#--------------------------------------------------------------------------
	# kill ss-tunnel
	if [ ! -z "$sstunnel" ];then 
		echo_date 关闭ss-tunnel进程...
		killall ss-tunnel
	fi
	
	if [ ! -z "$rsstunnel" ];then 
		echo_date 关闭rss-tunnel进程...
		killall rss-tunnel
	fi
	
	#--------------------------------------------------------------------------
	# kill pdnsd
	if [ ! -z "$pdnsd" ];then 
	echo_date 关闭pdnsd进程...
	killall pdnsd
	fi
	#--------------------------------------------------------------------------
	# kill chinadns
	if [ ! -z "$chinadns" ];then 
		echo_date 关闭chinadns进程...
		killall chinadns
	fi
	#--------------------------------------------------------------------------
	# kill dns2socks
	if [ ! -z "$DNS2SOCK" ];then 
		echo_date 关闭dns2socks进程...
		killall dns2socks
	fi
	# kill all koolgame
	if [ ! -z "$koolgame" ];then 
		echo_date 关闭koolgame进程...
		killall koolgame >/dev/null 2>&1
	fi
	
	if [ ! -z "$client_linux_mipsel" ];then 
		echo_date 关闭kcp协议进程...
		killall client_linux_arm5 >/dev/null 2>&1
	fi
	
	if [ ! -z "$haproxy" ];then 
		echo_date 关闭haproxy进程...
		killall haproxy >/dev/null 2>&1
	fi

    [ -n "$obfsLocal" ] && echo_date 关闭obfs-local进程... && killall obfs-local >/dev/null 2>&1
}

kill_cron_job(){
	# kill crontab job
	echo_date 删除ss规则更新计划任务.
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
}


remove_conf_and_settings(){
	echo_date 删除ss相关的名单配置文件.
	# remove conf under /jffs/configs/dnsmasq.d
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /jffs/configs/dnsmasq.conf.add

	# remove ss state
	dbus remove ss_basic_state_china
	dbus remove ss_basic_state_foreign
}

case $1 in
stop_all)
	#KCP_basic_action=0 应用所有设置
	echo_date =============== 梅林固件 - shadowsocks by sadoneli\&Xiaobao ===============
	echo_date
	echo_date -------------------------- 关闭Shadowsocks ------------------------------
	restore_conf
	remove_conf_and_settings
	bring_up_dnsmasq
	restore_nat
	destory_ipset
	restore_start_file
	kill_process
	kill_cron_job
	echo_date -------------------------- Shadowsocks已关闭 -----------------------------
	;;

*)
	echo "Usage: $0 (stop_all|stop_part)"
	exit 1
	;;
esac
