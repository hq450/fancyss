#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
source /koolshare/ss/ssconfig.sh
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

case "$2" in
	1)
		true > /tmp/upload/ss_log.txt
		http_response "$1"
		set_ss_reboot_job >> /tmp/upload/ss_log.txt
		echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac
