#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh
eval $(dbus export ss_failover)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGFILE=/tmp/upload/ss_log.txt

stop_status(){
	kill -9 $(pidof ss_status_main.sh) >/dev/null 2>&1
	kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
	killall curl >/dev/null 2>&1
	killall httping >/dev/null 2>&1
	rm -rf /tmp/upload/ss_status.txt
}

check_status(){
	if [ "$ss_failover_enable" == "1" ];then
		echo "=========================================== 故障检测脚本重启 ==========================================" >> $LOGFILE_F
		echo "=========================================== 故障检测脚本重启 ==========================================" >> $LOGFILE_C
		start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status_main.sh
	fi
}


echo " " > $LOGFILE
http_response "$1"
usleep 200000
if [ "$ss_failover_enable" == "1" ];then
	echo_date "重启故障转移功能" >> $LOGFILE
	stop_status
	check_status
	echo_date "完成！" >> $LOGFILE
else
	echo_date "关闭故障转移功能" >> $LOGFILE
	stop_status
	echo_date "完成！" >> $LOGFILE
fi
echo XU6J03M6 >> $LOGFILE
