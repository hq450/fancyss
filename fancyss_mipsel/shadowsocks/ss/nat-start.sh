#!/bin/sh
eval `dbus export ss`
lan_ipaddr=$(nvram get lan_ipaddr)
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'
	
flush_nat(){
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
}

flush_ipset(){
	echo_date 先清空已存在的ipset名单，防止重复添加
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_ip >/dev/null 2>&1 && ipset -X white_ip >/dev/null 2>&1
	ipset -F white_cidr >/dev/null 2>&1 && ipset -X white_cidr >/dev/null 2>&1
	ipset -F black_ip >/dev/null 2>&1 && ipset -X black_ip >/dev/null 2>&1
	ipset -F black_cidr >/dev/null 2>&1 && ipset -X black_cidr >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
}

# creat ipset rules
creat_ipset(){
	echo_date 创建ipset名单
	ipset -N white_ip iphash
	ipset -N white_cidr nethash
	ipset -N black_ip iphash
	ipset -N black_cidr nethash
	ipset -N gfwlist iphash
	ipset -N router iphash
	#ipset -N chnroute nethash
	sed -e "s/^/-A chnroute &/g" -e "1 i\-N chnroute nethash --hashsize 81920" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

add_white_black_ip(){
	# black cidr for telegram
	ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
	for ip in $ip_tg
	do
		ipset -A black_cidr $ip >/dev/null 2>&1
	done
	# black ip/cidr for user defined in the web
	if [ -n "$ss_wan_black_ip" ];then
		#ss_wan_black_ip=`dbus get ss_wan_black_ip|base64_decode|sed '/\#/d'`
		ip_format=`echo $ss_wan_black_ip|base64_decode|sed '/\#/d'|grep -v "/"`
		cidr_format=`echo $ss_wan_black_ip|base64_decode|sed '/\#/d'|grep "/"`

		if [ -n "$ip_format" ];then
			echo_date 应用IP黑名单
			for ip in "$ip_format"
			do
				ipset -A black_ip "$ip" >/dev/null 2>&1
			done
		fi

		if [ -n "$cidr_format" ];then
			echo_date 应用CIDR黑名单
			for cidr in "$cidr_format"
			do
				ipset -A black_cidr "$cidr" >/dev/null 2>&1
			done
		fi
	fi
	
	# white ip/cidr
	ip1=$(nvram get wan0_ipaddr | cut -d"." -f1,2)
	[ -n "$ss_basic_server_ip" ] && SERVER_IP=$ss_basic_server_ip || SERVER_IP=""
	ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
	ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
	
	cidr_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 $ip1.0.0/16"
	ip_lan="$SERVER_IP 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 $ISP_DNS1 $ISP_DNS2"
	for ip in $ip_lan
	do
		ipset -A white_ip $ip >/dev/null 2>&1
	done

	for cidr in $cidr_lan
	do
		ipset -A white_cidr $cidr >/dev/null 2>&1
	done

	# white ip/cidr for user defined in the web
	if [ -n "$ss_wan_white_ip" ];then
		ip_format=`echo $ss_wan_white_ip|base64_decode|sed '/\#/d'|grep -v "/"`
		cidr_format=`echo $ss_wan_white_ip|base64_decode|sed '/\#/d'|grep "/"`

		if [ -n "$ip_format" ];then
			echo_date 应用IP白名单
			for ip in "$ip_format"
			do
				ipset -A white_ip "$ip" >/dev/null 2>&1
			done
		fi

		if [ -n "$cidr_format" ];then
			echo_date 应用CIDR白名单
			for cidr in "$cidr_format"
			do
				ipset -A white_cidr "$cidr" >/dev/null 2>&1
			done
		fi
	fi
}

get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "SHADOWSOCKS_GFW"
		;;
		2)
			echo "SHADOWSOCKS_CHN"
		;;
		5)
			echo "SHADOWSOCKS_GLO"
		;;
		6)
			echo "SHADOWSOCKS_HOM"
		;;
	esac
}

get_mode_name() {
	case "$1" in
		0)
			echo "不通过SS"
		;;
		1)
			echo "gfwlist模式"
		;;
		2)
			echo "大陆白名单模式"
		;;
		5)
			echo "全局模式"
		;;
		6)
			echo "回国模式"
		;;
	esac
}

factor(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

get_jump_mode(){
	case "$1" in
		0)
			echo "j"
		;;
		*)
			echo "g"
		;;
	esac
}

lan_acess_control(){
	# lan access control
	acl_nu=`dbus list ss_acl_mode|sed 1d|sort -n -t "=" -k 2|cut -d "=" -f 1 | cut -d "_" -f 4`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get ss_acl_ip_$acl`
			ports=`dbus get ss_acl_port_$acl`
			[ "$ports" == "all" ] && ports=""
			proxy_mode=`dbus get ss_acl_mode_$acl`
			proxy_name=`dbus get ss_acl_name_$acl`
			[ "$ports" == "" ] && echo_date 加载ACL规则：$ipaddr:all模式为：$(get_mode_name $proxy_mode) || echo_date 加载ACL规则：$ipaddr:$ports模式为：$(get_mode_name $proxy_mode)
			iptables -t nat -A SHADOWSOCKS $(factor $ipaddr "-s") -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			[ "$proxy_mode" == "3" ] || [ "$proxy_mode" == "4" ] && \
			iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
		done

		if [ -n "ss_acl_default_mode=" ];then
			echo_date 加载ACL规则：其余主机模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：其余主机模式为：$(get_mode_name $ss_basic_mode)
			dbus set ss_acl_default_mode="$ss_basic_mode"
		fi
	else
		ss_acl_default_mode=$ss_basic_mode
		echo_date 加载ACL规则：所有模式为：$(get_mode_name $ss_basic_mode)
	fi
}

apply_nat_rules(){
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	iptables -t nat -N SHADOWSOCKS
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --set white_ip dst -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --set white_cidr dst -j RETURN
	#-----------------------FOR GLOABLE---------------------
	iptables -t nat -N SHADOWSOCKS_GLO
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	#-----------------------FOR GFWLIST---------------------
	iptables -t nat -N SHADOWSOCKS_GFW
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --set black_ip dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --set black_cidr dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --set gfwlist dst -j REDIRECT --to-ports 3333
	#-----------------------FOR CHNMODE---------------------
	iptables -t nat -N SHADOWSOCKS_CHN
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --set black_ip dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --set black_cidr dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set ! --set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR HOMEMODE---------------------
	iptables -t nat -N SHADOWSOCKS_HOM
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --set black_ip dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --set black_cidr dst -j REDIRECT --to-ports 3333
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR ROUTER---------------------
	[ "$ss_basic_mode" != "6" ] && iptables -t nat -A OUTPUT -p tcp -m set --set router dst -j REDIRECT --to-ports 3333
	#-------------------------------------------------------
	# 局域网黑名单（不走ss）/局域网黑名单（走ss）
	lan_acess_control
	# 把最后剩余流量重定向到相应模式的nat表中对对应的主模式的链
	[ "$ss_acl_default_port" == "all" ] && ss_acl_default_port=""
	iptables -t nat -A SHADOWSOCKS -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	# 重定所有流量到 SHADOWSOCKS
	iptables -t nat -I PREROUTING 1 -p tcp -j SHADOWSOCKS
}

chromecast(){
	LOG1=开启chromecast功能（DNS劫持功能）
	LOG2=chromecast功能未开启，建议开启~
	if [ "$ss_basic_chromecast" == "1" ];then
		IPT_ACTION="-A"
		echo_date $LOG1
	else
		IPT_ACTION="-D"
		echo_date $LOG2
	fi
	iptables -t nat $IPT_ACTION PREROUTING -p udp --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
}


case $1 in
start_all)
	flush_nat
	flush_ipset
	creat_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
	;;
add_new_ip)
	add_white_black_ip
	;;
start_part_for_addon)
	#ss_basic_action=4
	flush_nat
	chromecast
	apply_nat_rules
	;;
*)
	echo "Usage: $0 (start_all|restart_wb_list)"
	exit 1
	;;
esac
