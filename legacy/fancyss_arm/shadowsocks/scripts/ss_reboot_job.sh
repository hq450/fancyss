#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com)	from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

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

check_ip(){
	if [ -f "/tmp/ss_host.conf" ];then
		HOST=`cat /tmp/ss_host.conf | cut -d "/" -f2`
		OLD_IP=`cat /tmp/ss_host.conf | cut -d "/" -f3`
		if [ -n "$HOST" ] && [ -n "$OLD_IP" ];then
			NEW_IP=`nslookup "$HOST" 114.114.114.114 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			if [ "$?" == "0" ];then
				NEW_IP=`echo $NEW_IP|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			else
				logger 【科学上网插件触发重启功能】：SS服务器域名解析失败！
			fi

			if [ "$OLD_IP"x == "$NEW_IP"x ];then
				logger 【科学上网插件触发重启功能】：服务器ip地址未发生变化，不进行任何操作！
			else
				logger 【科学上网插件触发重启功能】：服务器ip地址发生变化，旧ip：【"$OLD_IP"】，新ip：【"$NEW_IP"】
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
		else
			logger 【科学上网插件触发重启功能】：未找到你当前节点的服务器地址，可能插件提交时未正确解析！
			logger 【科学上网插件触发重启功能】：请尝试直接使用ip地址作为服务器地址！
		fi
	else
		if [ -n "$ss_basic_server_ip" ];then
			IFIP=`echo $ss_basic_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			logger 【科学上网插件触发重启功能】：当前节点的服务器地址已经是IP格式！不进行任何操作！
		else
			logger 【科学上网插件触发重启功能】：未找到你当前节点的服务器地址，可能已是IP格式！不进行任何操作！
		fi
	fi
}
# -------------------

case "$1" in
	check_ip)
		# 开始检查IP
		check_ip
	;;
	*)
		# web提交操作，设定【插件定时重启设定】和【插件触发重启设定】
		if [ "$ss_basic_reboot_action" == "1" ];then
			set_ss_reboot_job
			dbus remove ss_basic_reboot_action
		elif [ "$ss_basic_reboot_action" == "2" ];then
			set_ss_trigger_job
			dbus remove ss_basic_reboot_action
		fi
	;;
esac