#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
ss_basic_enable=$(dbus get ss_basic_enable)
LOCK_FILE=/var/lock/fancyss.lock
SCHEMA2_POSTSAVE_IDS_KEY="fss_node_postsave_ids"

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

	local postsave_ids=""
	postsave_ids="$(dbus get ${SCHEMA2_POSTSAVE_IDS_KEY})"
	if [ -n "${postsave_ids}" ] && [ -x "/koolshare/scripts/ss_node_postsave.sh" ];then
		sh /koolshare/scripts/ss_node_postsave.sh rebuild "${postsave_ids}" >/dev/null 2>&1 || true
		dbus remove ${SCHEMA2_POSTSAVE_IDS_KEY}
	fi
}

start_fancyss(){
	# start fancyss
	sh /koolshare/ss/ssconfig.sh restart
}

start_fancyss_shunt_hot(){
	if [ "$(dbus get ss_basic_shunt_hot_reload)" = "1" ] && [ -x "/koolshare/scripts/ss_shunt_hot_reload.sh" ]; then
		echo_date "[hot-reload] 尝试通过 Xray API 热更新节点分流规则..."
		if sh /koolshare/scripts/ss_shunt_hot_reload.sh apply; then
			return 0
		fi
		echo_date "[hot-reload] 热更新失败，回退到完整重启。"
	fi
	start_fancyss
}

# call by ws
case $1 in
start)
	set_lock
	true > /tmp/upload/ss_log.txt
	pre_start
	start_fancyss 2>&1 | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
start_shunt_hot)
	set_lock
	true > /tmp/upload/ss_log.txt
	pre_start
	start_fancyss_shunt_hot 2>&1 | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
start_by_ws)
	set_lock
	true > /tmp/upload/ss_log.txt
	pre_start
	start_fancyss 2>&1 | tee -a /tmp/upload/ss_log.txt
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
stop)
	# 为了避免ss_config.sh本身也卡住，所以stop过程不使用文件锁，强行关闭
	true > /tmp/upload/ss_log.txt
	pre_stop
	stop_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	rm -rf ${LOCK_FILE}
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
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
start_shunt_hot)
	set_lock
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	pre_start
	start_fancyss_shunt_hot | tee -a /tmp/upload/ss_log.txt 2>&1
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
start_by_ws)
	set_lock
	true > /tmp/upload/ss_log.txt
	pre_start
	start_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	unset_lock
	;;
stop)
	# 为了避免ss_config.sh本身也卡住，所以stop过程不使用文件锁，强行关闭
	true > /tmp/upload/ss_log.txt
	http_response "$1"
	pre_stop
	stop_fancyss | tee -a /tmp/upload/ss_log.txt 2>&1
	echo XU6J03M6 | tee -a /tmp/upload/ss_log.txt
	rm -rf ${LOCK_FILE}
	;;
test)
	sleep 100
	;;
esac
