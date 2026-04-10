#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_failover)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGFILE=/tmp/upload/ss_log.txt

stop_status(){
	kill -9 $(pidof ss_status_main.sh) >/dev/null 2>&1
	kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
	ps w | grep -F "sh /koolshare/scripts/ss_status_main.sh" | grep -v grep | awk '{print $1}' | while read -r pid; do
		kill -9 "${pid}" >/dev/null 2>&1
	done
	ps w | grep -F "sh /koolshare/scripts/ss_status.sh" | grep -v grep | awk '{print $1}' | while read -r pid; do
		kill -9 "${pid}" >/dev/null 2>&1
	done
	killall curl-status >/dev/null 2>&1
	sh /koolshare/scripts/ss_status_daemon.sh stop >/dev/null 2>&1
	rm -rf /tmp/upload/ss_status.txt
	rm -rf /tmp/curl-status
}

check_status(){
	if [ "$ss_failover_enable" == "1" ];then
		sh /koolshare/scripts/ss_status_daemon.sh restart >/dev/null 2>&1
		echo "=========================================== 故障检测脚本重启 ==========================================" >> $LOGFILE_F
		echo "=========================================== 故障检测脚本重启 ==========================================" >> $LOGFILE_C
		sh /koolshare/scripts/ss_status_main.sh >/dev/null 2>&1 &
	else
		sh /koolshare/scripts/ss_status_daemon.sh restart >/dev/null 2>&1
	fi
}


true > $LOGFILE
http_response "$1"
usleep 200000
if [ "$ss_failover_enable" == "1" ];then
	echo_date "重启故障转移功能" >> $LOGFILE
	stop_status
	check_status
	echo_date "完成！" >> $LOGFILE
else
	echo_date "关闭故障转移功能，切换为前台按需检测" >> $LOGFILE
	stop_status
	check_status
	echo_date "完成！" >> $LOGFILE
fi
echo XU6J03M6 >> $LOGFILE
