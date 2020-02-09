#!/bin/sh

# shadowsocks script for LEDE/OPENWRT firmware modified by fw867 from koolshare
# by sadog (sadoneli@gmail.com) from koolshare.cn
#--------------------------------------------------------------------------------------
# Variable definitions
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
source $KSROOT/bin/helper.sh
eval `dbus export ss`
alias echo_date='echo 【$(date +%Y年%m月%d日\ %X)】:'
DNS_PORT=7913
CONFIG_FILE=$KSROOT/ss/ss.json
game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`
[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && mangle=1
lan_ipaddr=`uci get network.lan.ipaddr`
lan_ipaddr_prefix=`uci get network.lan.ipaddr`
LOCK_FILE=/var/lock/koolss.lock
ISP_DNS1=`cat /tmp/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|grep ^[1-9]|sed -n 1p`
ISP_DNS2=`cat /tmp/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|grep ^[1-9]|sed -n 2p`
IFIP=`echo $ss_basic_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
ARG_OBFS=""
# triggher shell
ONSTART=`ps -l|grep $PPID|grep -v grep|grep "S99koolss"`
#ONMWAN3=`ps -l|grep $PPID|grep -v grep|grep "mwan3.user"`
#ONFIRES=`ps -l|grep $PPID|grep -v grep|grep "firewall includes"`

# define SPECIAL_ARG when kcp enabled
if [ "$ss_kcp_enable" == "1" ] && [ "$ss_kcp_node" == "$ss_basic_node" ];then
	SPECIAL_ARG="-s 127.0.0.1 -p 11183"
else
	SPECIAL_ARG=""
fi

#--------------------------------------------------------------------------

get_lan_cidr(){
   	netmask=`uci get network.lan.netmask`
   	# Assumes there's no "255." after a non-255 byte in the mask
   	local x=${netmask##*255.}
   	set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
   	x=${1%%$3*}
   	suffix=$(( $2 + (${#x}/4) ))
   	prefix=`uci get network.lan.ipaddr | cut -d "." -f1,2,3`
   	echo $prefix.0/$suffix
}

calculate_wans_nu(){
	rm -rf /tmp/wan_names.txt
	interface_nu=`ubus call network.interface dump|jq '.interface|length'`
	if [ -z "$interface_nu" ];then
		echo_date "没有找到任何可用网络接口"
	else
		j=0
		wans_nu=0
		until [ "$j" == "$interface_nu" ]
		do
			lan_addr_prefix=`uci -q get network.lan.ipaddr|cut -d . -f1,2,3`
			WAN_EXIST=`ubus call network.interface dump|jq .interface[$j]|grep nexthop|grep -v "$lan_addr_prefix."|grep -v 127.0.0.1|sed 's/"nexthop"://g'|grep -v :`
			if [ -n "$WAN_EXIST" ];then
				wan_name=`ubus call network.interface dump|jq .interface[$j].interface|sed 's/"//g'`
				wan_gw=`ubus call network.interface dump|jq .interface[$j].route[0].nexthop|sed 's/"//g'`
				wan_ifname_l3=`ubus call network.interface dump|jq .interface[$j].l3_device|sed 's/"//g'`
				wan_up=`ubus call network.interface dump|jq .interface[$j].up|sed 's/"//g'`
				if [ "$wan_up" == "true" ];then
					#echo "[ \"$wan_ifname_l3\", \"$wan_name\" ]" >> /tmp/wan_names.txt
					echo "[ \"$j\", \"$wan_name\" ]" >> /tmp/wan_names.txt
					wans_nu=$(($wans_nu+1))
					if [ -z "$default_wan_if" ];then
						default_wan_if=`ubus call network.interface dump|jq .interface[$j].l3_device|sed 's/"//g'`
					fi
				fi
			fi
			j=$(($j+1))
		done
		echo_date "当前共有 $wans_nu个wan启用..."
		if [ "$wans_nu" == "1" ];then
			echo_date "默认wan出口: $default_wan_if"
		fi
	fi
}

restore_dnsmasq_conf(){
	# delete server setting in dnsmasq.conf
	pc_delete "server=" "/etc/dnsmasq.conf"
	pc_delete "all-servers" "/etc/dnsmasq.conf"
	pc_delete "no-resolv" "/etc/dnsmasq.conf"
	pc_delete "no-poll" "/etc/dnsmasq.conf"

	echo_date 删除ss相关的名单配置文件.
	rm -rf /tmp/dnsmasq.d/gfwlist.conf
	rm -rf /tmp/dnsmasq.d/output.conf
	rm -rf /tmp/dnsmasq.d/cdn.conf
	rm -rf /tmp/dnsmasq.d/sscdn.conf
	rm -rf /tmp/dnsmasq.d/custom.conf
	rm -rf /tmp/dnsmasq.d/wblist.conf
	rm -rf /tmp/dnsmasq.d/ssserver.conf
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf

	echo_date 删除出口路由表设定.
	if [ -f "/tmp/route_del" ];then
		source /tmp/route_del >/dev/null 2>&1
		rm -f /tmp/route_del >/dev/null 2>&1
	fi
}

restore_start_file(){
	echo_date 清除koolss防火墙配置...
	
	uci -q batch <<-EOT
	  delete firewall.ks_koolss
	  commit firewall
	EOT
}

kill_process(){
	#--------------------------------------------------------------------------
	# kill dnscrypt-proxy
	if [ -n "`pidof dnscrypt-proxy`" ]; then 
		echo_date 关闭dnscrypt-proxy进程...
		killall dnscrypt-proxy
	fi
	# kill ss-redir
	if [ -n "`pidof ss-redir`" ];then
		echo_date 关闭ss-redir进程...
		killall ss-redir
	fi
	# kill ssr-redir
	if [ -n "`pidof ssr-redir`" ];then
		echo_date 关闭ssr-redir进程...
		killall ssr-redir
	fi
	# kill ss-local
	sslocal=`ps | grep ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ -n "$sslocal" ];then 
		echo_date 关闭ss-local进程:23456端口...
		kill -9 $sslocal  >/dev/null 2>&1
	fi
	ssrlocal=`ps | grep ssr-local | grep -v "grep" | grep -w "23456" | awk '{print $1}'`
	if [ -n "$ssrlocal" ];then 
		echo_date 关闭ssr-local进程:23456端口...
		kill -9 $ssrlocal  >/dev/null 2>&1
	fi
	# kill ss-tunnel
	if [ -n "`pidof ss-tunnel`" ];then
		echo_date 关闭ss-tunnel进程...
		killall ss-tunnel
	fi
	# kill ssr-tunnel
	if [ -n "`pidof ssr-tunnel`" ];then
		echo_date 关闭ssr-tunnel进程...
		killall ssr-tunnel
	fi
	# kill pdnsd
	if [ -n "`pidof pdnsd`" ];then
		echo_date 关闭pdnsd进程...
		killall pdnsd
	fi
	# kill Pcap_DNSProxy
	if [ -n "`pidof Pcap_DNSProxy`" ];then
		echo_date 关闭Pcap_DNSProxy进程...
		killall Pcap_DNSProxy >/dev/null 2>&1
	fi
	# kill chinadns
	if [ -n "`pidof chinadns`" ];then
		echo_date 关闭chinadns进程...
		killall chinadns
	fi
	# kill chinadns2
	if [ -n "`pidof chinadns2`" ];then
		echo_date 关闭chinadns2进程...
		killall chinadns2
	fi
	# kill dns2socks
	if [ -n "`pidof dns2socks`" ];then
		echo_date 关闭dns2socks进程...
		killall dns2socks
	fi
	# kill haproxy
	if [ -n "`pidof haproxy`" ];then
		echo_date 关闭haproxy进程...
		killall haproxy
	fi
	# kill kcptun
	if [ -n "`pidof kcpclient`" ];then
		echo_date 关闭haproxy进程...
		killall kcpclient
	fi
	# kill cdns
	if [ -n "`pidof cdns`" ];then
		echo_date 关闭cdns进程...
		killall cdns
	fi
}

kill_cron_job(){
	echo_date 删除ss规则定时更新任务.
	sed -i '/ssupdate/d' /etc/crontabs/root >/dev/null 2>&1
}

# ==========================================================================================
route_add(){
	devnu="$1"
	routeip="$2"
	cleanfile=/tmp/route_del
	if [ "$devnu" == "0" ];then
		echo_date "【出口设定】 不指定 $routeip 的出口"
	else
		GW=`ubus call network.interface dump|jq .interface["$devnu"].route[0].nexthop|sed 's/"//g'`
		l3_name=`ubus call network.interface dump|jq .interface["$devnu"].l3_device|sed 's/"//g'`
		#devname=`ubus call network.interface dump|jq .interface["$devnu"].device|sed 's/"//g'`
		if [ -n "$GW" ];then
			ip route add $routeip via $GW dev $l3_name >/dev/null 2>&1
			echo_date "【出口设定】设置 $routeip 出口为 $l3_name"
			if [ ! -f $cleanfile ];then
				cat	> $cleanfile <<-EOF
				#!/bin/sh
				EOF
			fi
			chmod +x $cleanfile
			echo "ip route del $routeip via $GW dev $l3_name" >> /tmp/route_del
		else
			echo_date "【出口设定】设置 $routeip 出口为 $l3_name 失败, 因为$l3_name 已经离线!!! $routeip将会自动选择出口！"
		fi
	fi
}

resolv_server_ip(){
	if [ -z "$IFIP" ];then
		# 先尝试解析
		echo_date 尝试解析SS服务器的ip地址
		server_ip=`nslookup "$ss_basic_server" 114.114.114.114 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
		if [ "$?" == "0" ]; then
			echo_date SS服务器的ip地址解析成功：$server_ip.
		else
			echo_date SS服务器域名解析失败！
			echo_date 尝试用resolveip方式解析...
			server_ip=`resolveip -4 -t 2 $ss_basic_server|awk 'NR==1{print}'`
			if [ "$?" == "0" ]; then
		    	echo_date SS服务器的ip地址解析成功：$server_ip.
			else
				echo_date 使用resolveip方式SS服务器域名解析失败！建议使用手动更换域名为IP地址！
			fi
		fi

		if [ -n "$server_ip" ];then
			# 解析成功，储存起来
			ss_basic_server="$server_ip"
			ss_basic_server_ip="$server_ip"
			dbus set ss_basic_server_ip="$server_ip"
			echo_date 将解析结果储存到skipd数据库...
			if [ "$ss_basic_type"  == "1" ];then
				[ -z "$ssconf_basic_max_node" ] && SSR_NODE="$ssconf_basic_max_node" || SSR_NODE=`expr $ss_basic_node - $ssconf_basic_max_node`
				dbus set ssrconf_basic_server_ip_$SSR_NODE="$server_ip"
			elif [ "$ss_basic_type"  == "0" ];then
				dbus set ssconf_basic_server_ip_$ss_basic_node="$server_ip"
			fi
		else
			# 解析不成功，查找下上次是否有储存
			echo_date 尝试获取上次储存的解析结果...
			if [ "$ss_basic_type"  == "1" ];then
				[ -z "$ssconf_basic_max_node" ] && SSR_NODE="$ssconf_basic_max_node" || SSR_NODE=`expr $ss_basic_node - $ssconf_basic_max_node`
				ss_basic_server=`dbus get ssrconf_basic_server_ip_$SSR_NODE`
			elif [ "$ss_basic_type"  == "0" ];then
				ss_basic_server=`dbus get ssconf_basic_server_ip_$ss_basic_node`
			fi
			[ -n "$ss_basic_server" ] && ss_basic_server_ip="$ss_basic_server"
			[ -n "$ss_basic_server" ] && echo_date 成功获取到上次储存的解析结果：$ss_basic_server
			[ -z "$ss_basic_server" ] && ss_basic_server=`dbus get ss_basic_server` && echo_date SS服务器的ip地址解析失败，将由ss-redir自己解析.
		fi
	else
		# 已经是IP地址了，还解析个毛啊
		echo_date 检测到你的SS服务器已经是IP格式：$ss_basic_server,跳过解析... 
		dbus set ss_basic_server_ip="$ss_basic_server"
		ss_basic_server_ip="$ss_basic_server"
	fi

	# 用户指定出口
	[ "$ss_mwan_vps_ip_dst" != "0" ] && [ -n "$ss_basic_server_ip" ] && [ "$ss_basic_server_ip" != "127.0.0.1" ] && route_add $ss_mwan_vps_ip_dst $ss_basic_server_ip
}

start_kcp(){
	# Start kcp
	if [ "$ss_kcp_enable" == "1" ] && [ "$ss_kcp_node" == "$ss_basic_node" ];then
		if [ "$ss_kcp_compon" == "1" ];then
			COMP="--nocomp"
		else
			COMP=""
		fi
		echo_date 启动KCPTUN.
		start-stop-daemon -S -q -b -m \
		-p /tmp/run/kcp.pid \
		-x /koolshare/bin/kcpclient \
		-- -l 127.0.0.1:11183 \
		-r $ss_kcp_server:$ss_kcp_port \
		--key $ss_kcp_password \
		--crypt $ss_kcp_crypt \
		--mode $ss_kcp_mode $ss_kcp_config \
		--conn $ss_kcp_conn \
		--mtu $ss_kcp_mtu \
		--sndwnd $ss_kcp_sndwnd \
		--rcvwnd $ss_kcp_rcvwnd \
		$COMP
	fi
}

ss_arg(){
	if [ "$ss_basic_ss_obfs_host" != "" ];then
		if [ "$ss_basic_ss_obfs" == "obfs-http" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http;obfs-host=$ss_basic_ss_obfs_host"
		elif [ "$ss_basic_ss_obfs" == "obfs-tls" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls;obfs-host=$ss_basic_ss_obfs_host"
		elif [ "$ss_basic_ss_obfs" == "v2ray-http" ];then
			ARG_OBFS="--plugin v2ray-plugin"
		elif [ "$ss_basic_ss_obfs" == "v2ray-tls" ];then
			ARG_OBFS="--plugin v2ray-plugin --plugin-opts tls;host=$ss_basic_ss_obfs_host"
		elif [ "$ss_basic_ss_obfs" == "v2ray-quic" ];then
			ARG_OBFS="--plugin v2ray-plugin --plugin-opts mode=quic;host=$ss_basic_ss_obfs_host"
		else
			ARG_OBFS=""
		fi
	else
		if [ "$ss_basic_ss_obfs" == "obfs-http" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http"
		elif [ "$ss_basic_ss_obfs" == "obfs-tls" ];then
			ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls"
		elif [ "$ss_basic_ss_obfs" == "v2ray-http" ];then
			ARG_OBFS="--plugin v2ray-plugin"
		else
			ARG_OBFS=""
		fi
	fi
}
# create koolss config file...
creat_ss_json(){
	# creat normal ss json
	echo_date 创建SS配置文件到$CONFIG_FILE
	if [ "$ss_basic_type" == "0" ];then
		local mptcpmod
		if [ "$ss_basic_mptcp" == "0" ]; then
			mptcpmod="false"
		else
			mptcpmod="true"
		fi
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "local_address": "0.0.0.0",
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "mptcp": $mptcpmod,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "1" ];then
		cat > $CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "local_address": "0.0.0.0",
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocal",
			    "protocol_param":"$ss_basic_rss_protocal_para",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_para",
			    "method":"$ss_basic_method"
			}
		EOF
	fi
}

ha_resolved_action(){
	dest_if="$1"
	# store in skipd
	if [ "$ss_lb_type" == 1 ];then
		dbus set ssconf_basic_server_ip_$node="$lb_server_ip"
	else
		dbus set ssrconf_basic_server_ip_$node="$lb_server_ip"
	fi
	# add to return list
	ipset -! add white_list $lb_server_ip >/dev/null 2>&1
	# add route
	[ -z "$dest_if" ] && dest_if="1"
	[ -n "$dest_if" ] && route_add $dest_if $lb_server_ip
}

start_haproxy(){
	echo_date 生成haproxy配置文件到/koolshare/configs目录.
	mkdir -p /koolshare/configs
	cat > /koolshare/configs/haproxy.cfg <<-EOF
		global
		    log         127.0.0.1 local2
		    chroot      /usr/bin
		    pidfile     /var/run/haproxy.pid
		    maxconn     4000
		    user        nobody
		    daemon
		defaults
		    mode                    tcp
		    log                     global
		    option                  tcplog
		    option                  dontlognull
		    option http-server-close
		    #option forwardfor      except 127.0.0.0/8
		    option                  redispatch
		    retries                 2
		    timeout http-request    10s
		    timeout queue           1m
		    timeout connect         3s                                   
		    timeout client          1m
		    timeout server          1m
		    timeout http-keep-alive 10s
		    timeout check           10s
		    maxconn                 3000
		listen admin_status
		    bind 0.0.0.0:1188
		    mode http                
		    stats refresh 30s    
		    stats uri  /
		    stats auth $ss_lb_account:$ss_lb_password
		    #stats hide-version  
		    stats admin if TRUE
		resolvers mydns
		    nameserver dns1 119.29.29.29:53
		    nameserver dns2 114.114.114.114:53
		    resolve_retries       3
		    timeout retry         2s
		    hold valid           10s
		listen shadowscoks_balance_load
		    bind 0.0.0.0:$ss_lb_port
		    mode tcp
		    balance roundrobin
	EOF
	
	if [ "$ss_lb_type" == 1 ];then
		lb_node=`dbus list ssconf_basic_lb_enable|cut -d "=" -f 1| cut -d "_" -f 5 | sort -n | sed '/^$/d'`
	else
		lb_node=`dbus list ssrconf_basic_lb_enable|cut -d "=" -f 1| cut -d "_" -f 5 | sort -n | sed '/^$/d'`
	fi
	
	for node in $lb_node
	do
		up=`dbus get ss_lb_up`
		down=`dbus get ss_lb_down`
		interval=`dbus get ss_lb_interval`
		if [ "$ss_lb_type" == 1 ];then
			nick_name=`dbus get ssconf_basic_name_$node`
			port=`dbus get ssconf_basic_port_$node`
			name=`dbus get ssconf_basic_server_$node`:$port
			lb_server=`dbus get ssconf_basic_server_$node`
			weight=`dbus get ssconf_basic_lb_weight_$node`
			mode=`dbus get ssconf_basic_lb_policy_$node`
			lb_dest=`dbus get ssconf_basic_lb_dest_$node`
		else
			nick_name=`dbus get ssrconf_basic_name_$node`
			port=`dbus get ssrconf_basic_port_$node`
			name=`dbus get ssrconf_basic_server_$node`:$port
			lb_server=`dbus get ssrconf_basic_server_$node`
			weight=`dbus get ssrconf_basic_lb_weight_$node`
			mode=`dbus get ssrconf_basic_lb_policy_$node`
			lb_dest=`dbus get ssrconf_basic_lb_dest_$node`
		fi
		
		IFIP2=`echo $lb_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		if [ -z "$IFIP2" ];then
			echo_date 检测到【"$nick_name"】节点域名格式，将尝试进行解析...
			lb_server_ip=`resolveip -4 -t 2 "$lb_server"|awk 'NR==1{print}'`
			if [ -z "$lb_server_ip" ];then
				echo_date 解析失败，更换方案再次尝试！
				lb_server_ip=`nslookup "$lb_server" localhost | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
				if [ -n "$lb_server_ip" ];then
					echo_date 【"$nick_name"】节点ip地址解析成功：$lb_server_ip
					lb_server="$lb_server_ip"
					ha_resolved_action $lb_dest
				else
					echo_date 【"$nick_name"】节点ip解析失败，尝试获取以前储存的ip.
					if [ "ss_lb_type" == 1 ];then
						lb_server_ip=`dbus get ssconf_basic_server_ip_$node`
					else
						lb_server_ip=`dbus get ssrconf_basic_server_ip_$node`
					fi
					if [ -z "$lb_server_ip" ];then
						echo_date 【"$nick_name"】没有获取到以前储存的ip，将由haproxy自己尝试解析.
						if [ "ss_lb_type" == 1 ];then
							lb_server=`dbus get ssconf_basic_server_$node`
						else
							lb_server=`dbus get ssrconf_basic_server_$node`
						fi
					else
						echo_date 【"$nick_name"】成功获取到以前储存的ip.
						lb_server="$lb_server_ip"
						ha_resolved_action $lb_dest
					fi
				fi
			else
				echo_date 【"$nick_name"】节点ip地址解析成功：$lb_server_ip
				lb_server="$lb_server_ip"
				ha_resolved_action $lb_dest
			fi
		else
			ipset -! add white_list $lb_server >/dev/null 2>&1
			echo_date 检测到【"$nick_name"】节点已经是IP格式，跳过解析... 
			lb_server_ip="$lb_server"
			ha_resolved_action $lb_dest
		fi

		if [ "$mode" == "3" ];then
			echo_date 载入【"$nick_name"】作为备用节点...
			if [ "$ss_lb_heartbeat" == "1" ];then
				echo_date 启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight rise $up fall $down check inter $interval resolvers mydns backup
				EOF
			else
				echo_date 不启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight resolvers mydns backup
				EOF
			fi
		elif [ "$mode" == "2" ];then
			echo_date 载入【"$nick_name"】作为主用节点...
			if [ "$ss_lb_heartbeat" == "1" ];then
				echo_date 启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight check inter $interval rise $up fall $down resolvers mydns 
				EOF
			else
				echo_date 不启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight resolvers mydns 
				EOF
			fi
		else
			echo_date 载入【"$nick_name"】作为负载均衡节点...
			if [ "$ss_lb_heartbeat" == "1" ];then
				echo_date 启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight check inter $interval rise $up fall $down resolvers mydns 
				EOF
			else
				echo_date 不启用故障转移心跳...
				cat >> /koolshare/configs/haproxy.cfg <<-EOF
				    server $name $lb_server:$port weight $weight resolvers mydns 
				EOF
			fi
		fi
	done

	if [ -z "`pidof haproxy`" ];then
		echo_date ┏启动haproxy主进程...
		echo_date ┣如果此处等待过久，可能服务器域名解析失败造成的！可以刷新页面后关闭一次SS!
		echo_date ┣然后进入附加设置-SS服务器地址解析，更改解析dns或者更换解析方式！
		echo_date ┗启动haproxy主进程...
		haproxy -f /koolshare/configs/haproxy.cfg
	fi
}

start_sslocal(){
	if [ "$ss_basic_type" == "1" ];then
		echo_date 开启ssr-local，提供socks5端口：23456
		ssr-local $SPECIAL_ARG -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
	elif  [ "$ss_basic_type" == "0" ];then
		echo_date 开启ss-local，提供socks5端口：23456
		if [ "$ss_basic_ss_obfs" == "0" ];then
			ss-local $SPECIAL_ARG -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		else
			ss-local $SPECIAL_ARG -l 23456 -c $CONFIG_FILE -u $ARG_OBFS -f /var/run/sslocal1.pid >/dev/null 2>&1
		fi
	fi
}

start_dns(){
	# Start DNS2SOCKS
	start_sslocal
	if [ "1" == "$ss_dns_foreign" ] || [ -z "$ss_dns_foreign" ]; then
		echo_date 开启dns2socks，监听端口：23456
		#dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNS_PORT > /dev/null 2>&1 &
		start-stop-daemon -S -q -b -m \
			-p /tmp/run/dns2socks.pid \
			-x /koolshare/bin/dns2socks \
			-- 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNS_PORT
	fi

	# Start ss-tunnel
	if [ "2" == "$ss_dns_foreign" ];then
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-tunnel...
			ssr-tunnel -s $ss_basic_server -p $ss_basic_port -c $CONFIG_FILE -l $DNS_PORT -L "$ss_sstunnel_user" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-tunnel...
			ss-tunnel -s $ss_basic_server -p $ss_basic_port -c $CONFIG_FILE -l $DNS_PORT -L "$ss_sstunnel_user" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-tunnel -s $ss_basic_server -p $ss_basic_port -c $CONFIG_FILE -l $DNS_PORT -L "$ss_sstunnel_user" -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			else
				ss-tunnel -s $ss_basic_server -p $ss_basic_port -c $CONFIG_FILE -l $DNS_PORT -L "$ss_sstunnel_user" -u $ARG_OBFS -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		fi
	fi

	# Start dnscrypt-proxy
	if [ "3" == "$ss_dns_foreign" ];then
		echo_date 开启 dnscrypt-proxy，你选择了"$ss_opendns"节点.
		#dnscrypt-proxy -a 127.0.0.1:$DNS_PORT -d -L $KSROOT/ss/rules/dnscrypt-resolvers.csv -R $ss_opendns >/dev/null 2>&1 &
		start-stop-daemon -S -q -b -m \
			-p /tmp/run/dnscrypt-proxy.pid \
			-x /koolshare/bin/dnscrypt-proxy \
			-- -a 127.0.0.1:$DNS_PORT -d -L $KSROOT/ss/rules/dnscrypt-resolvers.csv -R $ss_opendns
	fi
	
	# Start pdnsd
	if [ "4" == "$ss_dns_foreign"  ]; then
		echo_date 开启 pdnsd，pdnsd进程可能会不稳定，请自己斟酌.
		echo_date 创建$KSROOT/ss/pdnsd文件夹.
		[ -z "$ss_pdnsd_user" ] && ss_pdnsd_user="8.8.8.8:53"
		mkdir -p $KSROOT/ss/pdnsd
		if [ "$ss_pdnsd_method" == "1" ];then
			echo_date 创建pdnsd配置文件到$KSROOT/ss/pdnsd/pdnsd.conf
			echo_date 你选择了-仅udp查询-，需要开启上游dns服务，以防止dns污染.
			cat > $KSROOT/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="$KSROOT/ss/pdnsd/";
					run_as="root";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=udp_only;
					min_ttl=24h;
					max_ttl=1w;
					timeout=10;
				}
				
				server {
					label= "OPENWRT-X64"; 
					ip = 127.0.0.1;
					port = 1099;
					root_server = on;   
					uptest = none;    
				}
				EOF
				
				echo_date 开启dns2socks作为pdnsd的上游服务器.
				#dns2socks 127.0.0.1:23456 "$ss_pdnsd_user" 127.0.0.1:1099 > /dev/null 2>&1 &
				start-stop-daemon -S -q -b -m \
					-p /tmp/run/dns2socks.pid \
					-x /koolshare/bin/dns2socks \
					-- 127.0.0.1:23456 "$ss_pdnsd_user" 127.0.0.1:1099

		elif [ "$ss_pdnsd_method" == "2" ];then
			echo_date 创建pdnsd配置文件到$KSROOT/ss/pdnsd/pdnsd.conf
			ss_pdnsd_server_ip=`echo $ss_pdnsd_user|cut -d ":" -f1`
			ss_pdnsd_server_port=`echo $ss_pdnsd_user|cut -d ":" -f2`
			echo_date 你选择了-仅tcp查询-，使用"$ss_pdnsd_server_ip":"$ss_pdnsd_server_port"进行tcp查询.
			cat > $KSROOT/ss/pdnsd/pdnsd.conf <<-EOF
				global {
					perm_cache=2048;
					cache_dir="$KSROOT/ss/pdnsd/";
					run_as="root";
					server_port = $DNS_PORT;
					server_ip = 127.0.0.1;
					status_ctl = on;
					query_method=tcp_only;
					min_ttl=24h;
					max_ttl=1w;
					timeout=10;
				}
				
				server {
					label= "RT-AC68U"; 
					ip = $ss_pdnsd_server_ip;
					port = $ss_pdnsd_server_port;
					root_server = on;   
					uptest = none;    
				}
			EOF
		fi
		
		chmod 644 $KSROOT/ss/pdnsd/pdnsd.conf
		CACHEDIR=$KSROOT/ss/pdnsd
		CACHE=$KSROOT/ss/pdnsd/pdnsd.cache
		USER=root
		GROUP=nogroup
	
		if ! test -f "$CACHE"; then
			echo_date 创建pdnsd缓存文件.
			dd if=/dev/zero of=$KSROOT/ss/pdnsd/pdnsd.cache bs=1 count=4 2> /dev/null
			chown -R $USER.$GROUP $CACHEDIR 2> /dev/null
		fi

		echo_date 启动pdnsd进程...
		pdnsd --daemon -c $KSROOT/ss/pdnsd/pdnsd.conf -p /var/run/pdnsd.pid
	fi

	# Start chinadns
	if [ "5" == "$ss_dns_foreign" ];then
		if [ "$ss_chinadns_method" == "1" ] || [ -z "$ss_chinadns_method" ];then
			#dns2socks 127.0.0.1:23456 "$ss_chinadns_user" 127.0.0.1:1055 >/dev/null 2>&1 &
			start-stop-daemon -S -q -b -m \
				-p /tmp/run/dns2socks.pid \
				-x /koolshare/bin/dns2socks \
				-- 127.0.0.1:23456 "$ss_chinadns_user" 127.0.0.1:1055
			#chinadns -p $DNS_PORT -s "$CDN",127.0.0.1:1055 -m -d -c $KSROOT/ss/rules/chnroute.txt >/dev/null 2>&1 &
			start-stop-daemon -S -q -b -m \
				-p /tmp/run/chinadns.pid \
				-x /koolshare/bin/chinadns \
				-- -p $DNS_PORT -s "$CDN",127.0.0.1:1055 -m -d -c $KSROOT/ss/rules/chnroute.txt
		elif [ "$ss_chinadns_method" == "2" ];then
			echo_date 开启EDNS版chinadns，用于dns解析...
			clinet_ip="114.114.114.114"
			public_ip=`curl --connect-timeout 4 -s 'http://members.3322.org/dyndns/getip'`
			if [ "$?" == "0" ] && [ -n "$public_ip" ];then
				echo_date 你的公网ip地址是：$public_ip
				dbus set ss_basic_publicip="$public_ip"
				clinet_ip=$public_ip
			else
				[ -n "$ss_basic_publicip" ] && clinet_ip=$ss_basic_publicip
			fi

			if [ -n "$ss_basic_server_ip" ];then
				ipset test chnroute $ss_basic_server_ip > /dev/null 2>&1
				if [ "$?" != "0" ];then
					# ss服务器是国外IP
					ss_real_server_ip="$ss_basic_server_ip"
				else
					# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
					ss_real_server_ip="8.8.8.8"
				fi
			else
				# ss服务器可能是域名，并且没有得到解析结果，用8.8.8.8替换之
				ss_real_server_ip="8.8.8.8"
			fi
			#chinadns2 -p $DNS_PORT -s 8.8.8.8:53 -e $clinet_ip,$ss_real_server_ip -c /koolshare/ss/rules/chnroute.txt >/dev/null 2>&1 &
			start-stop-daemon -S -q -b -m \
				-p /tmp/run/chinadns2.pid \
				-x /koolshare/bin/chinadns2 \
				-- -p $DNS_PORT -s 8.8.8.8:53 -e $clinet_ip,$ss_real_server_ip -c /koolshare/ss/rules/chnroute.txt
		fi
	fi

	# Start Pcap_DNSProxy
	if [ "6" == "$ss_dns_foreign"  ]; then
		echo_date 开启Pcap_DNSProxy..
		#sed -i "/^Listen Port/c Listen Port = $DNS_PORT" $KSROOT/ss/dns/Config.ini
		sed -i 's/119.29.29.29:53/114.114.114.114:53/' $KSROOT/ss/dns/Config.ini
		change=`echo $ISP_DNS1|sed -e 's/$/:53/'`
		echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:" >> /dev/null;[ "$?" == "0" ] && sed -i 's/223.6.6.6:53/'"$change"'/' $KSROOT/ss/dns/Config.ini || sed -i 's/223.6.6.6:53/114.114.114.115:53/' $KSROOT/ss/dns/Config.ini
		Pcap_DNSProxy -c /koolshare/ss/dns
	fi
	
	# Start cdns
	if [ "7" == "$ss_dns_foreign" ]; then
		echo_date 开启cdns，用于dns解析...
		#cdns -c /koolshare/ss/rules/cdns.json > /dev/null 2>&1 &
		start-stop-daemon -S -q -b -m \
			-p /tmp/run/cdns.pid \
			-x /koolshare/bin/cdns \
			-- -c /koolshare/ss/rules/cdns.json
	fi
}

create_dnsmasq_conf(){
	if [ "$ss_dns_china" == "1" ];then
		IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		if [ -n "$IFIP_DNS1" ];then
			# 用chnroute去判断运营商DNS是否为局域网(国外)ip地址，有些二级路由的是局域网ip地址，会被ChinaDNS 判断为国外dns服务器，这个时候用取代之
			ipset test chnroute $ISP_DNS1 > /dev/null 2>&1
			if [ "$?" != "0" ];then
				# 运营商DNS：ISP_DNS1是局域网(国外)ip
				CDN="114.114.114.114"
			else
				# 运营商DNS：ISP_DNS1是国内ip
				CDN="$ISP_DNS1"
			fi
		else
			# 运营商DNS：ISP_DNS1不是ip格式，用114取代之
			CDN="114.114.114.114"
		fi

		if [ -n "$IFIP_DNS2" ];then
			# 用chnroute去判断运营商DNS是否为局域网(国外)ip地址，有些二级路由的是局域网ip地址，会被ChinaDNS 判断为国外dns服务器，这个时候用取代之
			ipset test chnroute $ISP_DNS2 > /dev/null 2>&1
			if [ "$?" != "0" ];then
				# 运营商DNS：ISP_DNS2是局域网(国外)ip
				CDN2="114.114.115.115"
			else
				# 运营商DNS：ISP_DNS2是国内ip
				CDN2="$ISP_DNS2"
			fi
		else
			# 运营商DNS：ISP_DNS2不是ip格式，用114取代之
			CDN2="114.114.115.115"
		fi		
	fi
	[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
	[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
	[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
	[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
	[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
	[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
	[ "$ss_dns_china" == "8" ] && CDN="112.124.47.27"
	[ "$ss_dns_china" == "9" ] && CDN="114.215.126.16"
	[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
	[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
	[ "$ss_dns_china" == "12" ] && {
		[ -n "$ss_dns_china_user" ] && CDN="$ss_dns_china_user" || CDN="114.114.114.114"
	}
	# append china site
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	
	echo_date 生成cdn加速列表到/tmp/sscdn.conf，加速用的dns：$CDN
	echo "#for china site CDN acclerate" >> /tmp/sscdn.conf
	cat $KSROOT/ss/rules/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/sscdn.conf

	# append user defined china site
	if [ -n "$ss_isp_website_web" ];then
		cdnsites=$(echo $ss_isp_website_web | base64_decode)
		echo_date 生成自定义cdn加速域名到/tmp/sscdn.conf
		echo "#for user defined china site CDN acclerate" >> /tmp/sscdn.conf
		for cdnsite in $cdnsites
		do
			echo "$cdnsite" | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" >> /tmp/sscdn.conf
		done
	fi
	
	if [ -n "$ss_dnsmasq" ];then
		echo_date 添加自定义dnsmasq设置到/tmp/custom.conf
		echo "$ss_dnsmasq" | base64_decode | sort -u >> /tmp/custom.conf
	fi

	# append white domain list, bypass ss
	rm -rf /tmp/wblist.conf
	# github and some other site need to go ss
	echo "#for router itself" >> /tmp/wblist.conf
	echo "server=/.google.com.tw/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.google.com.tw/router" >> /tmp/wblist.conf
	echo "server=/.google.com.ncr/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.google.com.ncr/router" >> /tmp/wblist.conf
	echo "server=/.github.com/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.github.com/router" >> /tmp/wblist.conf
	echo "server=/.github.io/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.github.io/router" >> /tmp/wblist.conf
	echo "server=/.raw.githubusercontent.com/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.raw.githubusercontent.com/router" >> /tmp/wblist.conf
	echo "server=/.apnic.net/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.apnic.net/router" >> /tmp/wblist.conf
	echo "server=/.openwrt.org/127.0.0.1#7913" >> /tmp/wblist.conf
	echo "ipset=/.openwrt.org/router" >> /tmp/wblist.conf		
	# append white domain list,not through ss
	wanwhitedomain=$(echo $ss_wan_white_domain | base64_decode)
	if [ -n "$ss_wan_white_domain" ];then
		echo_date 应用域名白名单
		echo "#for white_domain" >> //tmp/wblist.conf
		for wan_white_domain in $wanwhitedomain
		do 
			echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
			echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
		done
	fi
	# apple 和microsoft不能走ss
	echo "#for special site" >> //tmp/wblist.conf
	for wan_white_domain2 in "apple.com" "microsoft.com"
	do 
		echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#53/g" >> /tmp/wblist.conf
		echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/wblist.conf
	done
	
	# append black domain list,through ss
	wanblackdomain=$(echo $ss_wan_black_domain | base64_decode)
	if [ -n "$ss_wan_black_domain" ];then
		echo_date 应用域名黑名单
		echo "#for black_domain" >> /tmp/wblist.conf
		for wan_black_domain in $wanblackdomain
		do 
			echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/wblist.conf
			echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >> /tmp/wblist.conf
		done
	fi
	# custom dnsmasq
	rm -rf /tmp/dnsmasq.d/custom.conf
	rm -rf /tmp/dnsmasq.d/wblist.conf
	rm -rf /tmp/dnsmasq.d/cdn.conf
	
	# ln conf
	if [ -f /tmp/custom.conf ];then
		echo_date 创建域自定义dnsmasq配置文件软链接到/tmp/dnsmasq.d/custom.conf
		mv /tmp/custom.conf /tmp/dnsmasq.d/custom.conf
	fi
	if [ -f /tmp/wblist.conf ];then
		echo_date 创建域名黑/白名单软链接到/tmp/dnsmasq.d/wblist.conf
		mv /tmp/wblist.conf /tmp/dnsmasq.d/wblist.conf
	fi
	if [ -f /tmp/sscdn.conf ];then
		echo_date 创建cdn加速列表软链接/tmp/dnsmasq.d/cdn.conf
		mv /tmp/sscdn.conf /tmp/dnsmasq.d/cdn.conf
	fi
	echo_date 创建gfwlist的软连接到/tmp/dnsmasq.d/文件夹.
	[ ! -L "/tmp/dnsmasq.d/gfwlist.conf" ] && ln -sf $KSROOT/ss/rules/gfwlist.conf /tmp/dnsmasq.d/gfwlist.conf
	
	echo "no-resolv" >> /tmp/dnsmasq.d/ssserver.conf
	gfw_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "1"`
	chn_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "2|3"`
	all_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "4"`
	if [ "$ss_basic_mode" == "1" ] && [ -z "$chn_on" ] && [ -z "$all_on" ];then
		if [ "$ss_dns_china" == "1" ];then
			#echo_date DNS解析方案国内优先，使用运营商DNS优先解析国内DNS.
			echo "all-servers" >> /tmp/dnsmasq.d/ssserver.conf
			echo "server=$CDN#53" >> /tmp/dnsmasq.d/ssserver.conf
			echo "server=$CDN2#53" >> /tmp/dnsmasq.d/ssserver.conf
		else
			#echo_date DNS解析方案国内优先，使用自定义DNS：$CDN进行解析国内DNS.
			echo "server=$CDN#53" >> /tmp/dnsmasq.d/ssserver.conf
		fi

	else
		#echo_date DNS解析方案国外优先，优先解析国外DNS.
		echo "server=127.0.0.1#7913" >> /tmp/dnsmasq.d/ssserver.conf
	fi
	[ "$ss_mwan_china_dns_dst" != "0" ] && [ -n "$CDN" ] && route_add $ss_mwan_china_dns_dst $CDN
	[ "$ss_mwan_china_dns_dst" != "0" ] && [ -n "$CDN2" ] && [ "$CDN" != "$CDN2" ] && route_add $ss_mwan_china_dns_dst $CDN2
}

#--------------------------------------------------------------------------------------
auto_start(){
	# nat start
	echo_date 添加koolss防火墙规则
	uci -q batch <<-EOT
	  delete firewall.ks_koolss
	  set firewall.ks_koolss=include
	  set firewall.ks_koolss.type=script
	  set firewall.ks_koolss.path=/koolshare/ss/ssstart.sh
	  set firewall.ks_koolss.family=any
	  set firewall.ks_koolss.reload=1
	  commit firewall
	EOT

	[ ! -L "/etc/rc.d/S99koolss.sh" ] && ln -sf $KSROOT/init.d/S99koolss.sh /etc/rc.d/S99koolss.sh

	# cron job
	sed -i '/ssruleupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$ss_basic_rule_update" = "1" ];then
		if [ "$ss_basic_rule_update_day" = "7" ];then
			echo "0 $ss_basic_rule_update_hr * * * /koolshare/scripts/ss_rule_update.sh #ssupdate#" >> /etc/crontabs/root
			echo_date "设置SS规则自动更在每天 $ss_basic_rule_update_hr 点。"
		else
			echo "0 $ss_basic_rule_update_hr * * $ss_basic_rule_update_day /koolshare/scripts/ss_rule_update.sh #ssupdate#" >> /etc/crontabs/root
			echo_date "设置SS规则自动更新在星期 $ss_basic_rule_update_day 的 $ss_basic_rule_update_hr 点。"
		fi
	else
		echo_date "关闭SS规则自动更新."
	fi
	sed -i '/ssnodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ];then
		if [ "$ss_basic_node_update_day" = "7" ];then
			echo "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh #ssnodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在每天 $ss_basic_node_update_hr 点。"
		else
			echo "0 $ss_basic_node_update_hr * * $ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh #ssnodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。"
		fi
	fi
}

#=======================================================================================
start_ss_redir(){
	# start another ss-redir for udp when game mode under kcp enable
	if [ "$ss_kcp_enable" == "1" ] && [ "$ss_kcp_node" == "$ss_basic_node" ] && [ "$mangle" == "1" ];then
		# ONLY TCP
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-redir进程，用于透明代理.
			ssr-redir $SPECIAL_ARG -c $CONFIG_FILE -f /var/run/koolss.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-redir进程，用于透明代理.
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-redir $SPECIAL_ARG -c $CONFIG_FILE -f /var/run/koolss.pid >/dev/null 2>&1
			else
				ss-redir $SPECIAL_ARG -c $CONFIG_FILE $ARG_OBFS -f /var/run/koolss.pid >/dev/null 2>&1
			fi
		fi
		# ONLY UDP
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-redir第二进程，用于kcp模式下udp的透明代理.
			ssr-redir -c $CONFIG_FILE -U -f /var/run/koolss.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-redir第二进程，用于kcp模式下udp的透明代理.
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-redir -c $CONFIG_FILE -U -f /var/run/koolss.pid >/dev/null 2>&1
			else
				ss-redir -c $CONFIG_FILE -U $ARG_OBFS -f /var/run/koolss.pid >/dev/null 2>&1
			fi
		fi
	else
		# Start ss-redir for nornal use
		if [ "$ss_basic_type" == "1" ];then
			echo_date 开启ssr-redir进程，用于透明代理.
			ssr-redir $SPECIAL_ARG -c $CONFIG_FILE -u -f /var/run/koolss.pid >/dev/null 2>&1
		elif  [ "$ss_basic_type" == "0" ];then
			echo_date 开启ss-redir进程，用于透明代理.
			if [ "$ss_basic_ss_obfs" == "0" ];then
				ss-redir $SPECIAL_ARG -c $CONFIG_FILE -u -f /var/run/koolss.pid >/dev/null 2>&1
			else
				ss-redir $SPECIAL_ARG -c $CONFIG_FILE -u $ARG_OBFS -f /var/run/koolss.pid >/dev/null 2>&1
			fi
		fi
	fi
}

# =======================================================================================================
flush_nat(){
	echo_date 尝试先清除已存在的iptables规则，防止重复添加
	# flush iptables rules
	iptables -t nat -D OUTPUT -j SHADOWSOCKS > /dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333 > /dev/null 2>&1
	nat_indexs=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/SHADOWSOCKS/='|sort -r`
	for nat_index in $nat_indexs
	do
		iptables -t nat -D PREROUTING $nat_index >/dev/null 2>&1
	done
	iptables -t nat -F SHADOWSOCKS > /dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS > /dev/null 2>&1
	mangle_indexs=`iptables -nvL PREROUTING -t mangle |sed 1,2d | sed -n '/SHADOWSOCKS/='|sort -r`
	for mangle_index in $mangle_indexs
	do
		iptables -t mangle -D PREROUTING $mangle_index >/dev/null 2>&1
	done
	
	iptables -t mangle -F SHADOWSOCKS > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS > /dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GFW > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GFW > /dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_CHN > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_CHN > /dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GAM > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GAM > /dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GLO > /dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GLO > /dev/null 2>&1

	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
	[ `dbus get koolproxy_enable` -ne 1 ] && iptables -t nat -D PREROUTING $chromecast_nu >/dev/null 2>&1

	#flush_ipset
	echo_date 先清空已存在的ipset名单，防止重复添加
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1

	#remove_redundant_rule
	ip_rule_exist=`ip rule show | grep "fwmark 0x1/0x1 lookup 310" | grep -c 310`
	if [ ! -z "ip_rule_exist" ];then
		echo_date 清除重复的ip rule规则.
		until [ "$ip_rule_exist" = 0 ]
		do 
			#ip rule del fwmark 0x07 table 310
			ip rule del fwmark 0x07 table 310 pref 789
			ip_rule_exist=`expr $ip_rule_exist - 1`
		done
	fi

	# remove_route_table
	echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}

# creat ipset rules
creat_ipset(){
	echo_date 创建ipset名单
	ipset -! create white_list nethash && ipset flush white_list
	ipset -! create black_list nethash && ipset flush black_list
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" $KSROOT/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

add_white_black_ip(){
	# black ip/cidr
	ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
	for ip in $ip_tg
	do
		ipset -! add black_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $ss_wan_black_ip ];then
		ss_wan_black_ip=`dbus get ss_wan_black_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR黑名单
		for ip in $ss_wan_black_ip
		do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi
	# white ip/cidr
	[ ! -z "$ss_basic_server_ip" ] && SERVER_IP=$ss_basic_server_ip || SERVER_IP=""
	IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	[ -n "$IFIP_DNS1" ] && ISP_DNS_a="$ISP_DNS1" || ISP_DNS_a=""
	[ -n "$IFIP_DNS2" ] && ISP_DNS_b="$ISP_DNS2" || ISP_DNS_b=""
	
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 $SERVER_IP 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 $ISP_DNS_a $ISP_DNS_b"
	for ip in $ip_lan
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $ss_wan_white_ip ];then
		ss_wan_white_ip=`echo $ss_wan_white_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR白名单
		for ip in $ss_wan_white_ip
		do
			ipset -! add white_list $ip >/dev/null 2>&1
		done
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
		3)
			echo "SHADOWSOCKS_GAM"
		;;
		4)
			echo "SHADOWSOCKS_GLO"
		;;
	esac
}

get_mode_name() {
	case "$1" in
		0)
			echo "不通过代理"
		;;
		1)
			echo "gfwlist模式"
		;;
		2)
			echo "大陆白名单模式"
		;;
		3)
			echo "游戏模式"
		;;
		4)
			echo "全局模式"
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
	acl_nu=`dbus list ss_acl_mode|sort -n -t "=" -k 2|cut -d "=" -f 1 | cut -d "_" -f 4`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get ss_acl_ip_$acl`
			proxy_mode=`dbus get ss_acl_mode_$acl`
			proxy_name=`dbus get ss_acl_name_$acl`
			mac=`dbus get ss_acl_mac_$acl`
			ports=`dbus get ss_acl_port_$acl`
			ports_user=`dbus get ss_acl_port_user_$acl`
			if [ "$ports" == "all" ]; then
				ports=""
				[ -n "$ipaddr" ] && [ -z "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【全部端口】模式为：$(get_mode_name $proxy_mode)
				[ -z "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$mac】【全部端口】模式为：$(get_mode_name $proxy_mode)
				[ -n "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$mac】【全部端口】模式为：$(get_mode_name $proxy_mode)
			elif [ "$ports" == "0" ]; then
				ports=$ports_user
				[ -n "$ipaddr" ] && [ -z "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)
				[ -z "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$mac】【$ports】模式为：$(get_mode_name $proxy_mode)
				[ -n "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$mac】【$ports】模式为：$(get_mode_name $proxy_mode)
			else
				[ -n "$ipaddr" ] && [ -z "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)
				[ -z "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$mac】【$ports】模式为：$(get_mode_name $proxy_mode)
				[ -n "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$mac】【$ports】模式为：$(get_mode_name $proxy_mode)
			fi

			# acl in koolss for mangle
			iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			[ "$proxy_mode" == "3" ] && iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			[ `dbus get ss_acl_default_mode` == "3" ] && iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
		done
		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port="" 
		elif [ "$ss_acl_default_port" == "0" ];then
			ss_acl_default_port=$ss_acl_default_port_user 
		fi
		echo_date 加载ACL规则：【剩余主机】模式为：$(get_mode_name $ss_acl_default_mode)
	else
		ss_acl_default_mode="$ss_basic_mode"
		if [ "$ss_acl_default_port" == "all" ];then
			ss_acl_default_port="" 
			echo_date 加载ACL规则：【全部主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		elif [ "$ss_acl_default_port" == "0" ];then
			ss_acl_default_port=$ss_acl_default_port_user 
			echo_date 加载ACL规则：【全部主机】【$ss_acl_default_port_user】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【全部主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	fi
}

apply_nat_rules(){
	# DEFINE bypass ARG_OBFS
	if [ "$ss_basic_bypass" == "2" ];then
		echo_date 使用geoip分流...
	else
		echo_date 使用chnroute分流...
	fi
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到mangle表中...
	# 创建SHADOWSOCKS mangle rule
	iptables -t mangle -N SHADOWSOCKS
	iptables -t mangle -A PREROUTING -j SHADOWSOCKS
	# IP/cidr/白域名 白名单控制（不走ss） for SHADOWSOCKS
	iptables -t mangle -A SHADOWSOCKS -m set --match-set white_list dst -j RETURN
	#-----------------------FOR GLOABLE---------------------
	# 创建全局模式mangle rule
	iptables -t mangle -N SHADOWSOCKS_GLO
	# 所有IP 全局模式（走ss）
	iptables -t mangle -A SHADOWSOCKS_GLO -p tcp -j TTL --ttl-set 188
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式mangle rule
	iptables -t mangle -N SHADOWSOCKS_GFW
	# IP/CIDR/黑域名 黑名单控制（走ss）
	iptables -t mangle -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	# IP黑名单控制-gfwlist（走ss）
	iptables -t mangle -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j TTL --ttl-set 188
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式mangle rule
	iptables -t mangle -N SHADOWSOCKS_CHN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t mangle -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	# cidr黑名单控制-chnroute（走ss）
	if [ "$ss_basic_bypass" == "2" ];then
		iptables -t mangle -A SHADOWSOCKS_CHN -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
	else
		iptables -t mangle -A SHADOWSOCKS_CHN -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
	fi
	
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式mangle rule
	iptables -t mangle -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t mangle -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	# cidr黑名单控制-chnroute（走ss）
	if [ "$ss_basic_bypass" == "2" ];then
		iptables -t mangle -A SHADOWSOCKS_GAM -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
	else
		iptables -t mangle -A SHADOWSOCKS_GAM -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
	fi
	
	# 游戏模式UDP
	ip rule add fwmark 0x07 table 310 pref 789
	ip route add local 0.0.0.0/0 dev lo table 310
	iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（走ss）
	if [ "$ss_basic_bypass" == "2" ];then
		iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m geoip ! --destination-country CN -j TPROXY --on-port 3333 --tproxy-mark 0x07
	else
		iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	fi
	#-------------------------------------------------------
	# 局域网黑名单（不走ss）/局域网黑名单（走ss）
	lan_acess_control
	# 其余主机默认模式
	iptables -t mangle -A SHADOWSOCKS -j $(get_action_chain $ss_acl_default_mode)
	# 重定所有流量到透明代理端口
	iptables -t nat -N SHADOWSOCKS
	iptables -t nat -A SHADOWSOCKS -p tcp -m ttl --ttl-eq 188 -j REDIRECT --to 3333
	# 重定所有流量到 SHADOWSOCKS
	KP_INDEX=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/KOOLPROXY/='|head -n1`
	if [ -n "$KP_INDEX" ]; then
		let KP_INDEX+=1
		#开启了KP，这把规则放在KOOLPROXY下面
		iptables -t nat -I PREROUTING $KP_INDEX -p tcp -j SHADOWSOCKS
	else
		#KP没有运行，确保添加到prerouting_rule规则之后
		PR_INDEX=`iptables -t nat -L PREROUTING|tail -n +3|sed -n -e '/^prerouting_rule/='`
		if [ -z "$PR_INDEX" ]; then
			PR_INDEX=1
		else
			let PR_INDEX+=1
		fi	
		iptables -t nat -I PREROUTING $PR_INDEX -p tcp -j SHADOWSOCKS
	fi
	# router itself
	iptables -t nat -I OUTPUT -j SHADOWSOCKS
	iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
}

chromecast(){
	LOG1=开启chromecast功能（DNS劫持功能）
	LOG2=chromecast功能未开启，建议开启~
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
	is_right_lanip=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53" |grep "$lan_ipaddr"`
	if [ "$ss_basic_chromecast" == "1" ];then
		if [ -z "$chromecast_nu" ]; then
			iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
			echo_date $LOG1
		else
			if [ -z "$is_right_lanip" ]; then
				echo_date 黑名单模式开启DNS劫持
				iptables -t nat -D PREROUTING $chromecast_nu >/dev/null 2>&1
				iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
			else
				echo_date DNS劫持规则已经添加，跳过~
			fi
		fi
	fi
}
# =======================================================================================================
load_nat(){
	echo_date "开始加载nat规则!"
	#flush_nat
	#creat_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
}

restart_dnsmasq(){
	# Restart dnsmasq
	echo_date 重启dnsmasq服务...
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}

write_numbers(){
	dbus set ss_version=`cat /koolshare/ss/version`
	
	ipset_numbers=`cat $KSROOT/ss/rules/gfwlist.conf | grep -c ipset`
	chnroute_numbers=`cat $KSROOT/ss/rules/chnroute.txt | grep -c .`
	cdn_numbers=`cat $KSROOT/ss/rules/cdn.txt | grep -c .`
	pcap_routing_nu=`cat $KSROOT/ss/dns/Routing.txt |grep -c /`
	pcap_white_nu=`cat $KSROOT/ss/dns/WhiteList.txt |grep -Ec "^\.\*"`
	
	update_ipset=`cat $KSROOT/ss/rules/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
	update_chnroute=`cat $KSROOT/ss/rules/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
	update_cdn=`cat $KSROOT/ss/rules/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
	update_pcap_routing=`cat $KSROOT/ss/rules/version | sed -n 5p | sed 's/#/\n/g'| sed -n 1p`
	update_pcap_white=`cat $KSROOT/ss/rules/version | sed -n 6p | sed 's/#/\n/g'| sed -n 1p`

	dbus set ss_gfw_status="$ipset_numbers 条，最后更新版本： $update_ipset "
	dbus set ss_chn_status="$chnroute_numbers 条，最后更新版本： $update_chnroute "
	dbus set ss_cdn_status="$cdn_numbers 条，最后更新版本： $update_cdn "
	dbus set ss_pcap_routing="$pcap_routing_nu 条，最后更新版本： $update_pcap_routing "
	dbus set ss_pcap_whitelist="$pcap_white_nu 条，最后更新版本： $update_pcap_white "
}


detect_koolss(){
	[ -f "/etc/config/shadowsocks" ] && koolss_enable=`uci get shadowsocks.@global[0].global_server`
	SS_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/SHADOWSOCKS/='` 2>/dev/null
	if [ -n "$SS_NU" ] && [ "$koolss_enable" != "nil" ];then
		echo_date 检测到你开启了koolss！！！
		echo_date 插件版本ss不能和koolss混用，如需使用插件ss，请关闭koolss！！
	else
		start_ok=1
	fi

	KOOLGAME_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/KOOLGAME/='` 2>/dev/null
	if [ -n "$KOOLGAME_NU" ];then
		echo_date 检测到你开启了KOOLGAME！！！
		echo_date koolss不能和KOOLGAME混用，请关闭KOOLGAME后启用本插件！！
	else
		start_ok=1
	fi

	if [ "$start_ok" == "1" ];then
		echo_date koolss插件符合启动条件！~
	else
		echo_date 退出插件启动...
		dbus set ss_basic_enable=0
		echo_date ---------------------- 退出启动 LEDE koolss -----------------------
		sleep 5
		echo XU6J03M6
		exit 1
	fi
}

# for debug
get_status(){
	echo =========================================================
	echo `date` 123
	echo "PID of this script: $$"
	echo "PPID of this script: $PPID"
	echo ------------------------------------
	ps -l|grep $$|grep -v grep
	echo ------------------------------------
	ps -l|grep $PPID|grep -v grep
	echo ------------------------------------
}

restart_by_fw(){
	# get_status >> /tmp/ss_start.txt
	# for nat
	exec 1000>"$LOCK_FILE"
	flock -x 1000
	echo_date ----------------------------- LEDE 固件 koolss -------------------------------------
	#[ -n "$ONMWAN3" ] && echo_date mwan3重启触发koolss重启！ 
	echo_date 防火墙重启触发koolss重启！
	echo_date ---------------------------------------------------------------------------------------
	detect_koolss
	calculate_wans_nu
	restore_dnsmasq_conf
	[ "$ss_lb_enable" == "1" ] && [ "$ss_basic_node" == "0" ] && [ -n "$ss_lb_node_max" ] && restart_dnsmasq
	kill_process
	flush_nat
	creat_ipset
	load_nat
	start_ss_redir
	start_kcp
	[ "$ss_lb_enable" == "1" ] && [ -n "$ss_lb_node_max" ] && start_haproxy
	start_dns
	create_dnsmasq_conf
	restart_dnsmasq
	echo_date ------------------------- koolss 重启完毕 -------------------------
	echo XU6J03M6
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

case $1 in
restart)
	# get_status >> /tmp/ss_start.txt
	# used by web for start/restart; or by system for startup by S99koolss.sh in rc.d
	exec 1000>"$LOCK_FILE"
	flock -x 1000
	echo_date ----------------------------- LEDE 固件 koolss -------------------------------------
	[ -n "$ONSTART" ] && echo_date 路由器开机触发koolss启动！ || echo_date web提交操作触发koolss启动！
	echo_date ---------------------------------------------------------------------------------------
	# stop first
	restore_dnsmasq_conf
	#if [ -z "$IFIP" ] && [ -z "$ONSTART" ];then
	if [ -z "$IFIP" ] && [ -z "$ONSTART" ];then
		restart_dnsmasq
	else
		[ "$ss_dns_foreign" == "5" ] && [ "$ss_chinadns_method" == "2" ] && restart_dnsmasq
		[ "$ss_lb_enable" == "1" ] && [ "$ss_basic_node" == "0" ] && [ -n "$ss_lb_node_max" ] && restart_dnsmasq
	fi
	flush_nat
	restore_start_file
	kill_process
	kill_cron_job
	echo_date ---------------------------------------------------------------------------------------
	# start
	detect_koolss
	calculate_wans_nu
	resolv_server_ip
	ss_arg
	[ -z "$ONSTART" ] && creat_ss_json
	creat_ipset
	create_dnsmasq_conf
	auto_start
	start_ss_redir
	start_kcp
	load_nat
	[ "$ss_lb_enable" == "1" ] && [ "$ss_basic_node" == "0" ] && [ -n "$ss_lb_node_max" ] && start_haproxy
	start_dns
	restart_dnsmasq
	write_numbers
	echo_date ------------------------- koolss 启动完毕 -------------------------
	flock -u 1000
	rm -rf "$LOCK_FILE"
	;;
stop)
	exec 1000>"$LOCK_FILE"
	flock -x 1000
	#only used by web stop
	echo_date ---------------------- LEDE 固件 koolss -----------------------
	restore_dnsmasq_conf
	restart_dnsmasq
	flush_nat
	restore_start_file
	kill_process
	kill_cron_job
	echo_date ------------------------- koolss 成功关闭 -------------------------
	flock -u 1000
	rm -rf "$LOCK_FILE"
	;;
lb_restart)
	[ -n "`pidof haproxy`" ] && echo_date 关闭haproxy进程... && killall haproxy
	[ "$ss_lb_enable" == "1" ] && [ "$ss_basic_node" == "0" ] && [ -n "$ss_lb_node_max" ] && start_haproxy
	;;
*)
	restart_by_fw > /tmp/upload/ss_log.txt
	;;
esac

