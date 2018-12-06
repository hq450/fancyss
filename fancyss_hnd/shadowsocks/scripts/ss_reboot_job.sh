#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
# -------------------

remove_ss_reboot_job(){
	if [ -n "`cru l|grep ss_reboot`" ]; then
		echo_date 【科学上网】：删除插件自动重启定时任务...
		sed -i '/ss_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_reboot_job(){
	if [[ "${ss_reboot_check}" == "0" ]]; then
		remove_ss_reboot_job
	elif [[ "${ss_reboot_check}" == "1" ]]; then
		echo_date 【科学上网】：设置每天${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "2" ]]; then
		echo_date 【科学上网】：设置每周${ss_basic_week}的${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * "${ss_basic_week}" /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "3" ]]; then
		echo_date 【科学上网】：设置每月${ss_basic_day}日${ss_basic_time_hour}时${ss_basic_time_min}分重启插件...
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour} ${ss_basic_day}" * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "4" ]]; then
		if [[ "${ss_basic_inter_pre}" == "1" ]]; then
			echo_date 【科学上网】：设置每隔${ss_basic_inter_min}分钟重启插件...
			cru a ss_reboot "*/"${ss_basic_inter_min}" * * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "2" ]]; then
			echo_date 【科学上网】：设置每隔${ss_basic_inter_hour}小时重启插件...
			cru a ss_reboot "0 */"${ss_basic_inter_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "3" ]]; then
			echo_date 【科学上网】：设置每隔${ss_basic_inter_day}天${ss_basic_inter_hour}小时${ss_basic_time_min}分钟重启插件...
			cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" */"${ss_basic_inter_day} " * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		fi
	elif [[ "${ss_reboot_check}" == "5" ]]; then
		check_custom_time=`dbus get ss_basic_custom | base64_decode`
		echo_date 【科学上网】：设置每天${check_custom_time}时的${ss_basic_time_min}分重启插件...
		cru a ss_reboot ${ss_basic_time_min} ${check_custom_time}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	fi
}

# -------------------

remove_ss_trigger_job(){
	if [ -n "`cru l|grep ss_tri_check`" ]; then
		echo_date 删除插件触发重启定时任务...
		sed -i '/ss_tri_check/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	else
		echo_date 插件触发重启定时任务已经删除...
	fi
}

set_ss_trigger_job(){
	if [ "$ss_basic_tri_reboot_time" == "0" ];then
		remove_ss_trigger_job
	else
		if [ "$ss_basic_tri_reboot_policy" == "1" ];then
			echo_date 设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启科学上网插件...
			
		else
			echo_date 设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启dnsmasq...
		fi
		echo_date 科学上网插件触发重启功能的日志将显示再系统日志内。
		cru d ss_tri_check  >/dev/null 2>&1
		cru a ss_tri_check "*/$ss_basic_tri_reboot_time * * * * /koolshare/scripts/ss_reboot_job.sh check_ip"
	fi
}

get_server_resolver(){
	if [ "$ss_basic_server_resolver" == "1" ];then
		if [ -n "$IFIP_DNS1" ];then
			RESOLVER="$ISP_DNS1"
		else
			RESOLVER="114.114.114.114"
		fi
	fi
	[ "$ss_basic_server_resolver" == "2" ] && RESOLVER="223.5.5.5"
	[ "$ss_basic_server_resolver" == "3" ] && RESOLVER="223.6.6.6"
	[ "$ss_basic_server_resolver" == "4" ] && RESOLVER="114.114.114.114"
	[ "$ss_basic_server_resolver" == "5" ] && RESOLVER="114.114.115.115"
	[ "$ss_basic_server_resolver" == "6" ] && RESOLVER="1.2.4.8"
	[ "$ss_basic_server_resolver" == "7" ] && RESOLVER="210.2.4.8"
	[ "$ss_basic_server_resolver" == "8" ] && RESOLVER="117.50.11.11"
	[ "$ss_basic_server_resolver" == "9" ] && RESOLVER="117.50.22.22"
	[ "$ss_basic_server_resolver" == "10" ] && RESOLVER="180.76.76.76"
	[ "$ss_basic_server_resolver" == "11" ] && RESOLVER="119.29.29.29"
	[ "$ss_basic_server_resolver" == "12" ] && {
		[ -n "$ss_basic_server_resolver_user" ] && RESOLVER="$ss_basic_server_resolver_user" || RESOLVER="114.114.114.114"
	}
	echo $RESOLVER
}

resolve_ip(){
	domain1=`echo $1|grep -E "^https://|^http://|/"`
	domain2=`echo $1|grep -E "\."`
	domian3=`echo $1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	if [ -n "$domian3" ];then
		# ip format
		echo $SERVER
	elif [ -n "$domain1" ] || [ -z "$domain2" ];then
		# not ip, not domain
		echo ""
	else
		# domain format
		SERVER_IP=`nslookup $1 $(get_server_resolver) | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}' 2>/dev/null`
		if [ "$?" == "0" ];then
			SERVER_IP=`echo $SERVER_IP|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			echo "$SERVER_IP"
		else
			echo ""
		fi
	fi
}

check_ip(){
	if [ "$ss_lb_enable" == "1" ] && [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
		#负载均衡模式下检查/koolshare/configs/haproxy.cfg
		logger ===========================================================================
		logger 【科学上网插件触发重启功能】：当前处于负载均衡状态，使用DNS:$(get_server_resolver)检查负载均衡节点IP是否更换...
		if [ -f /koolshare/configs/haproxy.cfg ] && [ -n `pidof haproxy` ];then
			SERVER_INFO=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $2}')
			ADDR_INFO=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $4}')
			INFO_LINE=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $2" "$4}'|wc -l)
			i=1
			j=1
			while [ $i -le $INFO_LINE ]
			do
				local HOST=`echo $SERVER_INFO | cut -d " " -f $i`
				local OLD_IP=`echo $ADDR_INFO | cut -d " " -f $i`
				local NEW_IP=$(resolve_ip "$HOST")
				if [ -z "$NEW_IP" ];then
					logger 【科学上网插件触发重启功能】：负载均衡节点服务器：$HOST解析失败！不进行任何进一步操作！
				else
					if [ "$OLD_IP"x == "$NEW_IP"x ];then
						logger 【科学上网插件触发重启功能】：负载均衡节点：$HOST的ip地址："$NEW_IP"未发生变化，不进行任何操作！
					else
						logger 【科学上网插件触发重启功能】：负载均衡节点：$HOST的ip地址发生变化，旧ip：【"$OLD_IP"】，新ip：【"$NEW_IP"】
						let j+=1
					fi
				fi
				let i+=1
			done

			if [ $j -gt 1 ];then
				logger 【科学上网插件触发重启功能】：重启负载均衡脚本，以应用新的ip
				sh /koolshare/scripts/ss_lb_config.sh
			fi
		else
			logger 【科学上网插件触发重启功能】：检测失败！可能是haproxy未运行导致？
		fi
		logger ===========================================================================
	else
		logger ===========================================================================
		logger 【科学上网插件触发重启功能】：使用DNS:$(get_server_resolver)检查服务器IP是否更换...
		if [ -f "/tmp/ss_host.conf" ];then
			HOST=`cat /tmp/ss_host.conf | cut -d "/" -f2`
			OLD_IP=`cat /tmp/ss_host.conf | cut -d "/" -f3`
			if [ -n "$HOST" ] && [ -n "$OLD_IP" ];then
				NEW_IP=$(resolve_ip "$HOST")
				if [ -z "$NEW_IP" ];then
					logger 【科学上网插件触发重启功能】：SS服务器域名解析失败！
				else
					if [ "$OLD_IP"x == "$NEW_IP"x ];then
						logger 【科学上网插件触发重启功能】：服务器：$HOST的ip地址："$NEW_IP"未发生变化，不进行任何操作！
					else
						logger 【科学上网插件触发重启功能】：服务器：$HOST的ip地址发生变化，旧ip：【"$OLD_IP"】，新ip：【"$NEW_IP"】
						#写入新的解析文件
						echo "address=/$HOST/$NEW_IP" > /tmp/ss_host.conf
						if [ "$ss_basic_tri_reboot_policy" == "1" ];then
							logger 【科学上网插件触发重启功能】：重启整个插件，以应用新的ip
							sh /koolshare/ss/ssconfig.sh restart
						else
							logger 【科学上网插件触发重启功能】：重启dnsmasq，以应用新的ip
							[ -L "/jffs/configs/dnsmasq.d/ss_host.conf" ] && rm -rf /jffs/configs/dnsmasq.d/ss_host.conf
							service restart_dnsmasq >/dev/null 2>&1
						fi
					fi
				fi
			else
				logger 【科学上网插件触发重启功能】：未找到你当前节点的服务器地址，可能插件提交时未正确解析！
				logger 【科学上网插件触发重启功能】：请尝试直接使用ip地址作为服务器地址！
			fi
		else
			if [ -n "$ss_basic_server_ip" ];then
				IFIP=`echo $ss_basic_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
				logger 【科学上网插件触发重启功能】：当前节点的服务器地址已经是IP格式：$IFIP！不进行任何操作！
			else
				logger 【科学上网插件触发重启功能】：未找到你当前节点的服务器地址，可能已是IP格式！不进行任何操作！
			fi
		fi
		logger ===========================================================================
	fi
}
# -------------------

case "$1" in
	check_ip)
		# 开始检查IP
		check_ip
	;;
esac

case "$2" in
	1)
		echo " " > /tmp/upload/ss_log.txt
		http_response "$1"
		set_ss_reboot_job >> /tmp/upload/ss_log.txt
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
	2)
		echo " " > /tmp/upload/ss_log.txt
		http_response "$1"
		set_ss_trigger_job >> /tmp/upload/ss_log.txt
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac