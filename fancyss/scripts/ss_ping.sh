#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
TMP1=/tmp/fancyss_ping
TMP2=/tmp/fancyss_webtest

run(){
	env -i PATH=${PATH} "$@"
}

start_ping(){
	touch /tmp/ss_ping.lock
	eval $(dbus export ss_basic_ping)
	[ -z "${ss_basic_ping_method}" ] && ss_basic_ping_method="2"

	mkdir -p $TMP1
	rm -rf $TMP1/*

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
		echo BEGN_NODE $BEGN_NODE >$TMP1/log.txt
	else
		BEGN_NODE=$((${CURR_NODE} - 10))
	fi

	# get all servers in json
	dbus list ssconf_basic_ | grep _json_ | grep -v _use_json_ | while read line
	do
		local _NU=$(echo "${line}" | awk -F "=" '{print $1}' | awk -F "_" '{print $NF}')
		local _SERVER_1=$(echo "${line}" | sed 's/^ssconf_basic_\w\+_[0-9]\?\+=//' | base64_decode | run jq -r .outbounds[0].settings.vnext[0].address)
		local _SERVER_2=$(echo "${line}" | sed 's/^ssconf_basic_\w\+_[0-9]\?\+=//' | base64_decode | run jq -r .outbounds[0].settings.servers[0].address)
		if [ -n "${_SERVER_1}" ];then
			local _SERVER=${_SERVER_1}
		else
			if [ -n "${_SERVER_2}" ];then
				local _SERVER=${_SERVER_2}
			else
				local _SERVER=""
			fi
		fi
		if [ -n "${_SERVER}" -a -n "${_NU}" ];then
			echo ssconf_basic_server_${_NU}=${_SERVER} >> ${TMP1}/all_servers.txt
		fi
	done

	if [ "${BEGN_NODE}" -gt "1" ];then
		# get all server 1
		dbus list ssconf_basic_ | grep _server_ | grep -v "server_ip" | grep -E "_[0-9]+=" >> ${TMP1}/all_servers.txt
		sort -n -t "_" -k 4 ${TMP1}/all_servers.txt | run sponge ${TMP1}/all_servers.txt
		sed -n "1,${BEGN_NODE}p" ${TMP1}/all_servers.txt > ${TMP1}/all_servers_1.txt
		sed "1,${BEGN_NODE}d" ${TMP1}/all_servers.txt >> ${TMP1}/all_servers_2.txt
		cat ${TMP1}/all_servers_2.txt ${TMP1}/all_servers_1.txt > ${TMP1}/all_servers_new.txt
	else
		dbus list ssconf_basic_ | grep _server_ | grep -v "server_ip" | grep -E "_[0-9]+=" >> ${TMP1}/all_servers.txt
		sort -n -t "_" -k 4 ${TMP1}/all_servers.txt > ${TMP1}/all_servers_new.txt
	fi

	# 清空 ping.txt文件
	true > /tmp/upload/ping.txt

	# 告诉web ping_test，可以轮询ping.txt拿结果了
	http_response "ok"
	
	cat ${TMP1}/all_servers_new.txt | xargs -n "${MAX_THREAD}" | while read line
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
	if [ -f "${TMP1}/ts.txt" ];then
		rm -rf ${TMP1}/ts.txt
	fi

	# 5. remove ping result file
	if [ -f "/tmp/upload/ping.txt" ];then
		rm -rf /tmp/upload/ping.txt
	fi
}

# ----------------------------------------------------------------------
# webtest
# 0: ss: ss, ss + simpple obfs, ss + v2ray plugin
# 1: ssr
# 3: v2ray
# 4: xray
# 5: trojan
# 6: naive

# 1. 先分类，ss分4类（ss, ss+simple, ss+v2ray, ss2022），ssr一类，v2ray + xray + trojan一类，naive一类，总共7类
# 2. 按照类别分别进行测试，而不是按照节点顺序测试，这样可以避免v2ray，xray等线程过多导致路由器资源耗尽，每个类的线程数不一样
# 3. 每个类别的测试，不同机型给到不同的线程数量，比如RT-AX56U_V2这种小内存机器，给一个线程即可
# 4. ss测试需要判断加密方式是否为2022AEAD，如果是，则需要判断是否存在sslocal，（不存在则返回不支持）
# 4. ss测试需要判断是否启用了插件，如果是v2ray-plugin插件，则测试线程应该降低，fancyss_lite不测试（返回不支持）
# 5. v2ray的配置文件（一般为vmess）由xray进行测试，因为fancyss_lite不带v2ray二进制
# 6. 二进制启动目标为开socks5端口，然后用httping通过该端口进行落地延迟测试
# 7. ss ssr这类以开多个二进制来增加线程，xray测试则使用一个线程 + 开多个socks5端口的配置文件来进行测试
# 8. 运行测试的时候，需要将各个二进制改名后运行，以免ssconfig.sh的启停将某个测试进程杀掉

start_webtest(){
	# 1. 清除文件
	mkdir -p ${TMP2}
	rm -rf ${TMP2}/*

	# 2. 分类
	sort_nodes

	# 3. 测试
	test_nodes
}

sort_nodes(){
	mkdir -p ${TMP2}
	rm -rf ${TMP2}/*
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids

	# 1.给所有节点分类
	# 根据节点类型不通进行分类
	# 01_ss.txt	ss
	# 02_ss.txt	ss + simple obfs
	# 03_ss.txt	ss + v2ray plugin
	# 04_ss.txt	ss 2022AEAD
	# 05_ss.txt	ss 2022AEAD + simple obfs
	# 06_ss.txt	ss 2022AEAD + v2ray plugin
	# 07_sr.txt
	# 08_vr.txt
	# 09_xr.txt
	# 10_tj.txt
	# 11_nv.txt
	dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -n | xargs -n 8 | while read nus
	do
		for nu in $nus
		do
			{
				local _type=$(dbus get ssconf_basic_type_${nu})
				if [ "${_type}" == "0" ];then
					local _obfs=$(dbus get ssconf_basic_ss_obfs)
					local _v2ray=$(dbus get ssconf_basic_ss_v2ray)
					local _method=$(dbus get ssconf_basic_method_${nu})
					local ss_2022=$(echo ${_method} | grep "2022-blake")
					if [ -z "${_obfs}" -o "${_obfs}" == "0" ];then
						local _obfs_enable="0"
					fi
					if [ -z "${_v2ray}" -o "${_v2ray}" == "0" ];then
						local _v2ray_enable="0"
					fi
					if [ -z "${ss_2022}" ];then
						if [ "${_obfs_enable}" == "0" -a "${_v2ray_enable}" == "0" ];then
							echo ${nu} >>${TMP2}/01_ss.txt
						elif [ "${_obfs_enable}" == "1" -a "${_v2ray_enable}" == "0" ];then
							echo ${nu} >>${TMP2}/02_ss.txt
						elif [ "${_obfs_enable}" == "0" -a "${_v2ray_enable}" == "1" ];then
							echo ${nu} >>${TMP2}/03_ss.txt
						fi
					else
						if [ "${_obfs_enable}" == "0" -a "${_v2ray_enable}" == "0" ];then
							echo ${nu} >>${TMP2}/04_ss.txt
						elif [ "${_obfs_enable}" == "1" -a "${_v2ray_enable}" == "0" ];then
							echo ${nu} >>${TMP2}/05_ss.txt
						elif [ "${_obfs_enable}" == "0" -a "${_v2ray_enable}" == "1" ];then
							echo ${nu} >>${TMP2}/06_ss.txt
						fi

					fi
				elif [ "${_type}" == "1" ];then
					echo ${nu} >>${TMP2}/07_sr.txt
				elif [ "${_type}" == "3" ];then
					echo ${nu} >>${TMP2}/08_vr.txt
				elif [ "${_type}" == "4" ];then
					echo ${nu} >>${TMP2}/09_xr.txt
				elif [ "${_type}" == "5" ];then
					echo ${nu} >>${TMP2}/10_tj.txt
				elif [ "${_type}" == "6" ];then
					echo ${nu} >>${TMP2}/11_nv.txt
				fi
			} &
		done
		wait
	done
	wait
}

test_nodes(){
	if [ -f "${TMP2}/01_ss.txt" ];then
		ln -sf /koolshare/bin/ss-local ${TMP2}/wtsl
		ln -sf /koolshare/bin/httping ${TMP2}/wthp
		local base_port=50600
		cat ${TMP2}/01_ss.txt | xargs -n 8 | while read nus; do
			for nu in $nus; do
				{
					# 1. gen ss config
					local new_port=$(($base_port + $nu))
					cat >${TMP2}/conf/${nu}.json <<-EOF
						{
						    "server":"$(dbus get ssconf_basic_server_${nu})",
						    "server_port":$(dbus get ssconf_basic_port_${nu}),
						    "local_address":"0.0.0.0",
						    "local_port":${new_port},
						    "password":"$(dbus get ssconf_basic_password_${nu} | base64_decode)",
						    "method":"$(dbus get ssconf_basic_method_${nu})"
						}
					EOF

					# 2. start ss-local
					${TMP2}/wtsl -c ${TMP2}/conf/${nu}.json -f ${TMP2}/pids/${nu}.pid

					sleep 1

					# 3. start httping
					# local ret=$(${TMP2}/wthp -s -Z -c2 -t 3 -5x 127.0.0.1:${new_port} developer.google.cn/generate_204 | grep -E "^connected" | sed -n '$p' 2>/dev/null)
					local ret=$(${TMP2}/wthp -s -Z -c2 -t 3 -5x 127.0.0.1:${new_port} www.google.com.tw | sponge |grep -E "^connected" | sed -n '$p')
					
					# 4. show result
					echo "$nu: $ret"
					
					# 4. stop ss-local
					kill -9 $(cat ${TMP2}/pids/${nu}.pid)
				} &
			done
			wait
		done
		wait
		rm -rf ${TMP2}/pids/*
		rm -rf ${TMP2}/conf/*

	fi

	exit

	# 多线程ping，一次ping $MAX_THREAD 个; armv7比较渣渣，线程数给少点
	CORES=$(cat /proc/cpuinfo | grep -Ec "processor")
	ARCH=$(uname -m)
	MAX_THREAD="100"
	case $ARCH in
	aarch64)
		BASE_RATE=10
		;;
	armv7l)
		BASE_RATE=5
		;;
	esac
	MAX_THREAD=$(($CORES * $BASE_RATE))
	
	dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -n | xargs -n "${MAX_THREAD}" | while read nus
	do
		for nu in $nus
		do
			# get server type
			node_webtest $nu
		done
		wait
	done
	wait
}

GET_NODES_TYPE(){
	local TYPE
	local NUBS
	local STATUS=$(dbus list ssconf_basic_type_ | grep -E "_[0-9]+=" | sed 's/^ssconf_basic_type_//;s/=/ /' |awk -F "=" '{print $NF}' | sort -n | uniq -c | sed 's/^[[:space:]]\+//g' | sed 's/[[:space:]]/|/g')
	for line in ${STATUS}
	do
		TYPE=$(echo $line | awk -F"|" '{print $2}')
		NUBS=$(echo $line | awk -F"|" '{print $1}')
		RESULT="${RESULT}$(GET_TYPE_NAME ${TYPE})节点 ${NUBS}个 | "
	done
	RESULT=$(echo ${RESULT} | sed 's/|$//g')
	echo ${RESULT}
}

gen_confs(){
	mkdir -p $TMP
	rm -rf $TMP/*

	# 多线程ping，一次ping $MAX_THREAD 个; armv7比较渣渣，线程数给少点
	CORES=$(cat /proc/cpuinfo | grep -Ec "processor")
	ARCH=$(uname -m)
	MAX_THREAD="100"
	case $ARCH in
	aarch64)
		BASE_RATE=10
		;;
	armv7l)
		BASE_RATE=5
		;;
	esac
	MAX_THREAD=$(($CORES * $BASE_RATE))
	
	
	dbus list ssconf_basic_server_ | grep -E "_[0-9]+=" | grep -v "server_ip" | sed 's/^ssconf_basic_server_//' | awk -F"=" '{print $1}' | sort -n > ${TMP}/all_servers_nu.txt
	cat ${TMP}/all_servers_nu.txt | xargs -n "${MAX_THREAD}" | while read nus
	do
		for nu in $nus
		do
			# get server type
			node_webtest $nu
		done
		wait
	done
	wait
}

node_webtest(){
	gen_jsons $nu
	run_xray
	httping_test
}

gen_jsons(){
	local nu=$1
	local type=$(dbus get ssconf_basic_type_${nu})
	case $type in
		0)
			gen_outbound_ss $nu
			gen_inbound $nu
			gen_routing $nu
			;;
		1)
			gen_outbound_ssr $nu
			gen_inbound $nu
			gen_routing $nu
			;;					
		3)
			gen_outbound_v2ray $nu
			gen_inbound $nu
			gen_routing $nu
			;;	
		4)
			gen_outbound_xray $nu
			gen_inbound $nu
			gen_routing $nu
			;;
		5)
			gen_outbound_trojan $nu
			gen_inbound $nu
			gen_routing $nu
			;;
	esac
}

gen_outbound_ss(){
	local node=$1

}


run_xray(){
	echo 123
}
httping_test(){
	echo 123
}

# ----------------------------------------------------------------------

case $1 in
1)
	start_webtest
	;;
esac


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
web_webtest)
	# 当用户进入插件，插件列表渲染好后开始调用本脚本进行ping
	webtest
	;;
manual_webtest)
	echo XU6J03M6
	http_response $1
	;;
esac