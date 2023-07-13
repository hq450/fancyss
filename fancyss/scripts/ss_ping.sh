#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
TMP=/tmp/fancyss_ping

start_ping(){
	touch /tmp/ss_ping.lock
	eval $(dbus export ss_basic_ping)
	[ -z "${ss_basic_ping_method}" ] && ss_basic_ping_method="2"

	mkdir -p $TMP
	rm -rf $TMP/*

	# 多线程ping，一次ping $MAX_THREAD 个; armv7比较渣渣，线程数给少点
	CORES=$(cat /proc/cpuinfo | grep -Ec "processor")
	ARCH=$(uname -m)
	MAX_THREAD="100"
	case $ARCH in
	aarch64)
		[ "${ss_basic_ping_method}" == "1" ] && BASE_RATE=40
		[ "${ss_basic_ping_method}" == "2" ] && BASE_RATE=35
		[ "${ss_basic_ping_method}" == "3" ] && BASE_RATE=30
		[ "${ss_basic_ping_method}" == "4" ] && BASE_RATE=25
		;;
	armv7l)
		[ "${ss_basic_ping_method}" == "1" ] && BASE_RATE=30
		[ "${ss_basic_ping_method}" == "2" ] && BASE_RATE=25
		[ "${ss_basic_ping_method}" == "3" ] && BASE_RATE=20
		[ "${ss_basic_ping_method}" == "4" ] && BASE_RATE=15
		;;
	esac

	# 例如：RT-AX86U Pro，4核心 armv8，当只ping一次的时候，最大ping线程数为：4 * 40 = 160
	# 例如：TUF-AX3000，3核心 armv7L，当只ping一次的时候，最大ping线程数为：3 * 30 = 90
	MAX_THREAD=$(($CORES * $BASE_RATE))

	# 计算开始ping的节点
	CURR_NODE=$(dbus get ssconf_basic_node)
	[ -z "${CURR_NODE}" ] && CURR_NODE=1

	MAX_SHOW=$(dbus get ss_basic_row)
	if [ "${MAX_SHOW}" -gt "1" ];then 
		BEGN_NODE=$(awk -v x=${CURR_NODE} -v y=${MAX_SHOW} 'BEGIN { printf "%.0f\n", (x-y/2)}')
		echo BEGN_NODE $BEGN_NODE >$TMP/log.txt
	else
		BEGN_NODE=$((${CURR_NODE} - 10))
	fi

	if [ "${BEGN_NODE}" -gt "1" ];then
		dbus list ssconf_basic_ | grep _server_ | grep -v "server_ip" | sort -n -t "_" -k 4 > ${TMP}/all_servers.txt
		sed -n "1,${BEGN_NODE}p" ${TMP}/all_servers.txt > ${TMP}/all_servers_1.txt
		sed "1,${BEGN_NODE}d" ${TMP}/all_servers.txt >> ${TMP}/all_servers_2.txt
		cat ${TMP}/all_servers_2.txt ${TMP}/all_servers_1.txt > ${TMP}/all_servers_new.txt
	else
		dbus list ssconf_basic_ | grep _server_ | grep -v "server_ip" | sort -n -t "_" -k 4 > ${TMP}/all_servers_new.txt
	fi

	# 清空 ping.txt文件
	true > /tmp/upload/ping.txt

	# 告诉web ping_test，可以轮询ping.txt拿结果了
	http_response "ok"
	
	cat ${TMP}/all_servers_new.txt | xargs -n "${MAX_THREAD}" | while read line
	do
		for node in $line
		do
			{
				node_nu=$(echo ${node}|cut -d "=" -f1|awk -F"_" '{print $NF}')
				node_doamin=$(echo ${node}|cut -d "=" -f2)
				[ "${ss_basic_ping_method}" == "1" ] && ping_text=$(ping -4 ${node_doamin} -c 1 -w 1 -q)
				[ "${ss_basic_ping_method}" == "2" ] && ping_text=$(ping -4 ${node_doamin} -c 5 -w 5 -q)
				[ "${ss_basic_ping_method}" == "3" ] && ping_text=$(ping -4 ${node_doamin} -c 10 -w 10 -q)
				[ "${ss_basic_ping_method}" == "4" ] && ping_text=$(ping -4 ${node_doamin} -c 20 -w 20 -q)
				ping_time=$(echo ${ping_text}|awk -F '/' '{print $4}')
				[ -z "${ping_time}" ] && ping_time="failed"
				ping_loss=$(echo ${ping_text}|grep loss|awk -F ', ' '{print $3}'|awk '{print $1}')
				echo "${node_nu}>${ping_time}>${ping_loss}" >>/tmp/upload/ping.txt
			} &
		done
		wait
	done
	wait
	local TS_LOG=$(date -r /tmp/upload/ping.txt "+%Y/%m/%d %X")
	dbus set ss_basic_ping_ts="${TS_LOG}"
	rm -rf /tmp/ss_ping.lock
}

ping_web(){
	# 1. 如果没有结果文件，需要去获取ping
	if [ ! -f "/tmp/upload/ping.txt" ];then
		clean_ping
		start_ping
		return 0
	fi

	# 2. 如果有结果文件，但是lock 存在，说明正在ping，那么告诉web自己去拿结果吧
	if [ -f "/tmp/ss_ping.lock" ];then
		http_response "ok"
		return 0
	fi

	# 3. 如果有结果该文件，且没有lock（ping完成了的），需要检测下节点数量和ping数量是否一致，避免新增节点没有ping
	local ping_nu=$(cat /tmp/upload/ping.txt | wc -l)
	local node_nu=$(dbus list ssconf_basic_ | grep _server_ | grep -v "server_ip" | wc -l)
	if [ "${ping_nu}" -ne "${node_nu}" ];then
		clean_ping
		start_ping
		return 0
	fi

	# 4. 如果有结果该文件，且没有lock（ping完成了的），且节点数和ping结果数一致，比较下上次ping结果生成的时间，如果是10分钟以内，则不需要重新ping
	date -r ping.txt "+%s"
	TS_LST=$(date -r /tmp/upload/ping.txt "+%s")
	TS_NOW=$(date +%s)
	TS_DUR=$((${TS_NOW} - ${TS_LST}))
	if [ "${TS_DUR}" -lt "600" ];then
		http_response "ok"
	else
		clean_ping
		start_ping
	fi
}

clean_ping(){
	# 当用户手动点击ping按钮的时候，不论是否有正在进行的任务，不论是否在在时限内，强制开始ping
	# 1. killall ping
	local PING_PIDS=$(pidof ping)
	if [ -n "${PING_PIDS}" ];then
		for PING_PID in $PING_PIDS
		do
			kill -9 $PING_PID >/dev/null 2>&1
		done
	fi

	# 2. kill all other ss_ping.sh
	local current_pid=$$
	local ss_ping_pids=$(ps|grep -E "ss_ping\.sh"|awk '{print $1}'|grep -v ${current_pid})
	if [ -n "${ss_ping_pids}" ];then
		for ss_ping_pid in ${ss_ping_pids}
		do
			kill -9 ${ss_ping_pid} >/dev/null 2>&1
		done
	fi

	# 3. remove lock file if exist
	if [ -f "/tmp/ss_ping.lock" ];then
		rm -rf /tmp/ss_ping.lock
	fi

	# 4. remove tmistamp log file
	if [ -f "${TMP}/ts.txt" ];then
		rm -rf ${TMP}/ts.txt
	fi

	# 5. remove ping result file
	if [ -f "/tmp/upload/ping.txt" ];then
		rm -rf /tmp/upload/ping.txt
	fi
}

case $2 in
web_ping)
	# 当用户进入插件，插件列表渲染好后开始调用本脚本进行ping
	ping_web
	;;
manual_ping)
	# 用户点击开始ping按钮，只需要帮助清理掉可能的干扰即可
	clean_ping
	# tell web: you can start ping now
	http_response $1
	;;
web_test)
	echo XU6J03M6
	;;
esac