#!/bin/sh
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'

echo_date ----------------------- shadowsocks 启动前触发脚本 -----------------------
lb_enable=`dbus get ss_lb_enable`
if [ "$lb_enable" == "1" ];then
	if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
	echo_date ss启动前触发:触发启动负载均衡功能！
		#start haproxy
		sh /koolshare/scripts/ss_lb_config.sh
		#start kcptun
		lb_node=`dbus list ssconf_basic_use_lb_|sed 's/ssconf_basic_use_lb_//g' |cut -d "=" -f 1 | sort -n`
		for node in $lb_node
		do	
			name=`dbus get ssconf_basic_name_$node`
			kcp=`dbus get ssconf_basic_use_kcp_$node`
			kcp_server=`dbus get ssconf_basic_server_$node`
			# marked for change in future 
			server_ip=`nslookup "$kcp_server" 119.29.29.29 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			kcp_port=`dbus get ss_basic_kcp_port`
			kcp_para=`dbus get ss_basic_kcp_parameter`
			if [ "$kcp" == "1" ];then
				export GOGC=40
				start-stop-daemon -S -q -b -m -p /tmp/var/kcp.pid -x /koolshare/bin/client_linux_arm5 -- -l 127.0.0.1:1091 -r $server_ip:$kcp_port $kcp_para
			fi
		done
	else
		echo_date ss启动前触发:未选择负载均衡节点，不触发负载均衡启动！
	fi
else
	if [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
		echo_date ss启动前触发【警告】：你选择了负载均衡节点，但是负载均衡开关未启用！！
	else
		echo_date ss启动前触发：你选择了普通节点，不触发负载均衡启动！.
	fi
fi