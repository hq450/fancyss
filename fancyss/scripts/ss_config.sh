#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
ss_basic_enable=$(dbus get ss_basic_enable)
LOCK_FILE=/var/lock/fancyss.lock

set_lock(){
	exec 1000>${LOCK_FILE}
	flock -n 1000 || {
		# bring back to original log
		http_response "$ACTION"
		# echo_date "$BASH $ARGS" | tee -a ${LOG_FILE}
		exit 1
	}
}

unset_lock() {
	flock -u 1000
	rm -rf ${LOCK_FILE}
}

pre_stop(){
	local current_pid=$$
	local ss_config_pids=$(ps|grep -E "ss_config\.sh"|awk '{print $1}'|grep -v ${current_pid})
	if [ -n "${ss_config_pids}" ];then
		for ss_config_pid in ${ss_config_pids}; do
			echo kill ${ss_config_pid}
			kill -9 ${ss_config_pid} >/dev/null 2>&1
		done
	fi

	local ssconfig_pids=$(ps|grep ssconfig.sh|grep -v grep|awk '{print $1}')
	if [ -n "${ssconfig_pids}" ];then
		for ssconfig_pid in ${ssconfig_pids}; do
			kill -9 ${ssconfig_pid} >/dev/null 2>&1
		done
	fi

	if [ -f "/var/lock/koolss.lock" ];then
		rm -rf /var/lock/koolss.lock
	fi
	
	if [ -f "/var/lock/fancyss.lock" ];then
		rm -rf /var/lock/fancyss.lock
	fi
}

stop_fancyss(){
	# start fancyss
	sh /koolshare/ss/ssconfig.sh stop
	echo XU6J03M6
}

pre_start(){
	# 计数器
	local flag_count=0
	
	# 主脚本开启前，进行检查，看是否有ssconfig.sh进程卡住的
	local ssconfig_pids=$(ps|grep ssconfig.sh|grep -v grep|awk '{print $1}')
	if [ -n "${ssconfig_pids}" ];then
		echo "${ssconfig_pids}"
		for ssconfig_pid in ${ssconfig_pids}; do
			kill -9 ${ssconfig_pid} >/dev/null 2>&1
		done
		let flag_count+=1
	fi

	# 移除ssconfig.sh的文件锁
	if [ -f "/var/lock/koolss.lock" ];then
		rm -rf /var/lock/koolss.lock
		let flag_count+=1
	fi

	if [ "${flag_count}" -gt "0" ];then
		dbus set ss_basic_status="1"
	fi
}

start_fancyss(){
	# start fancyss
	sh /koolshare/ss/ssconfig.sh restart
	echo XU6J03M6
}

# call by ws
case $1 in
start)
	set_lock
	true > /tmp/upload/ss_log.txt
	pre_start
	start_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	unset_lock
	;;
start_by_ws)
	set_lock
	pre_start
	start_fancyss
	unset_lock
	;;
stop)
	# 为了避免ss_config.sh本身也卡住，所以stop过程不使用文件锁，强行关闭
	true > /tmp/upload/ss_log.txt
	pre_stop
	stop_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	;;
test)
	sleep 100
	;;
esac

# call by httpdb
case $2 in
start)
	set_lock
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	pre_start
	start_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	unset_lock
	;;
start_by_ws)
	set_lock
	pre_start
	start_fancyss
	unset_lock
	;;
stop)
	# 为了避免ss_config.sh本身也卡住，所以stop过程不使用文件锁，强行关闭
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	pre_stop
	stop_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	;;
test)
	sleep 100
	;;
esac