#!/bin/sh

# shadowsocks script for koolshare merlin armv7l 384 router with kernel 2.6.36.4

source /koolshare/scripts/ss_base.sh
ISP_DNS1=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 1p)
ISP_DNS2=$(nvram get wan0_dns|sed 's/ /\n/g'|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p)
IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`

remove_ss_reboot_job(){
	if [ -n "`cru l|grep ss_reboot`" ]; then
		echo_date "【科学上网】：删除插件自动重启定时任务..."
		sed -i '/ss_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_reboot_job(){
	if [[ "${ss_reboot_check}" == "0" ]]; then
		remove_ss_reboot_job
	elif [[ "${ss_reboot_check}" == "1" ]]; then
		echo_date "【科学上网】：设置每天${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "2" ]]; then
		echo_date "【科学上网】：设置每周${ss_basic_week}的${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * "${ss_basic_week}" /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "3" ]]; then
		echo_date "【科学上网】：设置每月${ss_basic_day}日${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour} ${ss_basic_day}" * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "4" ]]; then
		if [[ "${ss_basic_inter_pre}" == "1" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_min}分钟重启插件..."
			cru a ss_reboot "*/"${ss_basic_inter_min}" * * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "2" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_hour}小时重启插件..."
			cru a ss_reboot "0 */"${ss_basic_inter_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "3" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_day}天${ss_basic_inter_hour}小时${ss_basic_time_min}分钟重启插件..."
			cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" */"${ss_basic_inter_day} " * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		fi
	elif [[ "${ss_reboot_check}" == "5" ]]; then
		check_custom_time=`dbus get ss_basic_custom | base64_decode`
		echo_date "【科学上网】：设置每天${check_custom_time}时的${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${check_custom_time}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	fi
}

remove_ss_trigger_job(){
	if [ -n "`cru l|grep ss_tri_check`" ]; then
		echo_date "删除插件触发重启定时任务..."
		sed -i '/ss_tri_check/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	else
		echo_date "插件触发重启定时任务已经删除..."
	fi
}

set_ss_trigger_job(){
	if [ "$ss_basic_tri_reboot_time" == "0" ];then
		remove_ss_trigger_job
	else
		echo_date "设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启科学上网插件..."
		echo_date "科学上网插件触发重启功能的日志将显示再系统日志内。"
		cru d ss_tri_check  >/dev/null 2>&1
		cru a ss_tri_check "*/$ss_basic_tri_reboot_time * * * * /koolshare/scripts/ss_reboot_job.sh check_ip"
	fi
}

#-------------------

__valid_ip(){
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4=`echo "$1"|grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	local format_6=`echo "$1"|grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*'`
	if [ -n "$format_4" ] && [ -z "$format_6" ];then
		echo "$format_4"
		return 0
	elif [ -z "$format_4" ] && [ -n "$format_6" ];then
		echo "$format_6"
		return 0
	else
		echo ""
		return 1
	fi
}

__get_server_resolver(){
	local value_1="$ss_basic_server_resolver"
	local value_2="$ss_basic_server_resolver_user"
	local res
	if [ "$value_1" == "1" ];then
		if [ -n "$IFIP_DNS1" ];then
			res="$ISP_DNS1"
		else
			res="114.114.114.114"
		fi
	fi
	[ "$value_1" == "2" ] && res="223.5.5.5"
	[ "$value_1" == "3" ] && res="223.6.6.6"
	[ "$value_1" == "4" ] && res="114.114.114.114"
	[ "$value_1" == "5" ] && res="114.114.115.115"
	[ "$value_1" == "6" ] && res="1.2.4.8"
	[ "$value_1" == "7" ] && res="210.2.4.8"
	[ "$value_1" == "8" ] && res="117.50.11.11"
	[ "$value_1" == "9" ] && res="117.50.22.22"
	[ "$value_1" == "10" ] && res="180.76.76.76"
	[ "$value_1" == "11" ] && res="119.29.29.29"
	if [ "$value_1" == "12" ];then
		if [ -n "$value_2" ];then
			res=$(__valid_ip "$value_2")
			[ -z "$res" ] && res="114.114.114.114"
		else
			res="114.114.114.114"
		fi
	fi
	echo $res
}

__get_server_resolver_port(){
	local port
	if [ "$ss_basic_server_resolver" == "12" ];then
		if [ -n "$ss_basic_server_resolver_user" ];then
			port=`echo "$ss_basic_server_resolver_user"|awk -F"#|:" '{print $2}'`
			[ -z "$port" ] && port="53"
		else
			port="53"
		fi
	else
		port="53"
	fi
	echo $port
}

__resolve_ip(){
	local domain1=`echo "$1"|grep -E "^https://|^http://|/"`
	local domain2=`echo "$1"|grep -E "\."`
	if [ -n "$domain1" ] || [ -z "$domain2" ];then
		# not ip, not domain
		echo ""
		return 2
	else
		# domain format
		SERVER_IP=`nslookup "$1" $(__get_server_resolver):$(__get_server_resolver_port) | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}' 2>/dev/null`
		SERVER_IP=$(__valid_ip $SERVER_IP)
		if [ -n "$SERVER_IP" ];then
			# success resolved
			echo "$SERVER_IP"
			return 0
		else
			# resolve failed
			echo ""
			return 1
		fi
	fi
}

__get_type_abbr_name() {
	case "$ss_basic_type" in
		0)
			echo "ss"
		;;
		1)
			echo "ssr"
		;;
		2)
			echo "koolgame"
		;;
		3)
			echo "v2ray"
		;;
	esac
}

check_ip_now(){
	local HOST OLD_IP NEW_IP SERVER_INFO ADDR_INFO INFO_LINE tmp1
	if [ "$ss_lb_enable" == "1" ] && [ `dbus get ss_basic_server | grep -o "127.0.0.1"` ] && [ `dbus get ss_basic_port` == `dbus get ss_lb_port` ];then
		#负载均衡模式下检查/koolshare/configs/haproxy.cfg
		logger "【科学上网插件触发重启功能】========================================================"
		logger "【科学上网插件触发重启功能】：当前处于负载均衡状态，使用DNS:$(__get_server_resolver):$(__get_server_resolver_port)检查负载均衡节点IP是否更换..."
		if [ -f /koolshare/configs/haproxy.cfg ] && [ -n `pidof haproxy` ];then
			SERVER_INFO=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $2}')
			ADDR_INFO=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $4}')
			INFO_LINE=$(cat /koolshare/configs/haproxy.cfg | grep -E "^\s\s\s\sserver"|sed 's/:/ /g'|awk '{print $2" "$4}'|wc -l)
			local i=1
			local j=1
			while [ $i -le $INFO_LINE ]
			do
				HOST=`echo $SERVER_INFO | cut -d " " -f $i`
				OLD_IP=`echo $ADDR_INFO | cut -d " " -f $i`
				tmp1=$(__valid_ip "$HOST")
				if [ $? == 0 ];then
					logger "【科学上网插件触发重启功能】：负载均衡节点：【$HOST】已经是IP格式！不进行任何操作！"
				else
					NEW_IP=$(__resolve_ip "$HOST")
					case $? in
					0)
						# server is domain format and success resolved.
						if [ "$OLD_IP"x == "$NEW_IP"x ];then
							logger "【科学上网插件触发重启功能】：负载均衡节点：【$HOST】的ip地址：【$OLD_IP】未发生变化，不进行任何操作！"
						else
							logger "【科学上网插件触发重启功能】：负载均衡节点：$HOST的ip地址发生变化，旧ip：【$OLD_IP】，新ip：【$NEW_IP】"
							let j+=1
						fi
						;;
					1)
						# server is domain format and failed to resolve.
						logger "【科学上网插件触发重启功能】：负载均衡节点服务器：【$HOST】解析失败！不进行任何进一步操作！"
						;;
					2)
						# server is not ip either domain!
						logger "【科学上网插件触发重启功能】：负载均衡节点服务器：【$HOST】无法解析！因为它不是IP格式也不是域名格式！"
						;;
					esac
				fi
				let i+=1
			done

			if [ $j -gt 1 ];then
				logger "【科学上网插件触发重启功能】：重启负载均衡脚本，以应用新的ip"
				sh /koolshare/scripts/ss_lb_config.sh
			fi
		else
			logger "【科学上网插件触发重启功能】：检测失败！可能是haproxy未运行导致？"
		fi
		logger "【科学上网插件触发重启功能】========================================================"
	else
		logger "【科学上网插件触发重启功能】========================================================"
		logger "【科学上网插件触发重启功能】：使用DNS:$(__get_server_resolver):$(__get_server_resolver_port)检查$(__get_type_abbr_name)服务器IP是否更换..."
		if [ -f "/tmp/ss_host.conf" ];then
			HOST=`cat /tmp/ss_host.conf | cut -d "/" -f2`
			OLD_IP=`cat /tmp/ss_host.conf | cut -d "/" -f3`
			if [ -n "$HOST" ] && [ -n "$OLD_IP" ];then
				NEW_IP=$(__resolve_ip "$HOST")
				case $? in
				0)
					# server is domain format and success resolved.
					if [ "$OLD_IP"x == "$NEW_IP"x ];then
						logger "【科学上网插件触发重启功能】：$(__get_type_abbr_name)服务器：【$HOST】的ip地址：【$OLD_IP】未发生变化，不进行任何操作！"
					else
						logger "【科学上网插件触发重启功能】：$(__get_type_abbr_name)服务器：【$HOST】的ip地址发生变化，旧ip：【$OLD_IP】，新ip：【$NEW_IP】"
						#写入新的解析文件，用于下次比较
						echo "address=/$HOST/$NEW_IP" > /tmp/ss_host.conf
						logger "【科学上网插件触发重启功能】：重启插件，以应用新的ip"
						start-stop-daemon -S -q -x /koolshare/ss/ssconfig.sh -- restart
					fi
					;;
				1)
					# server is domain format and failed to resolve.
					logger "【科学上网插件触发重启功能】：$(__get_type_abbr_name)服务器域名解析失败！！不进行任何进一步操作！"
					;;
				2)
					# server is not ip either domain!
					logger "【科学上网插件触发重启功能】：$(__get_type_abbr_name)服务器域名服务器：【$HOST】无法解析！因为它不是IP格式也不是域名格式！"
					;;
				esac
			else
				logger "【科学上网插件触发重启功能】：未找到你当前节点的$(__get_type_abbr_name)服务器地址，可能插件提交时未正确解析！"
				logger "【科学上网插件触发重启功能】：请尝试直接使用ip地址作为$(__get_type_abbr_name)服务器地址！"
			fi
		else
			if [ -n "$ss_basic_server_ip" ];then
				temp2=$(__valid_ip "$ss_basic_server_ip")
				logger "【科学上网插件触发重启功能】：当前$(__get_type_abbr_name)服务器地址已经是IP格式：$temp2！不进行任何操作！"
			else
				logger "【科学上网插件触发重启功能】：未找到你当前节点的$(__get_type_abbr_name)服务器地址，可能已是IP格式！不进行任何操作！"
			fi
		fi
		logger "【科学上网插件触发重启功能】========================================================"
	fi
}
# -------------------

case "$1" in
	check_ip)
		check_ip_now
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