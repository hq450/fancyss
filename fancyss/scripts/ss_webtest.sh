#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
source /koolshare/scripts/ss_webtest_gen.sh
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
TMP2=/tmp/fancyss_webtest
WT_SERVER_RESOLV_MODE=$(dbus get ss_basic_server_resolv_mode)
[ "${WT_SERVER_RESOLV_MODE}" = "2" ] || WT_SERVER_RESOLV_MODE="1"

wt_node_get() {
	fss_get_node_field_legacy "$2" "$1"
}

wt_node_get_plain() {
	fss_get_node_field_plain "$2" "$1"
}

wt_node_count() {
	fss_get_node_count
}

run(){
	env -i PATH=${PATH} "$@"
}

wt_server_resolv_mode_is_dynamic() {
	[ "${WT_SERVER_RESOLV_MODE}" = "1" ]
}

wt_server_resolv_mode_is_preresolve() {
	[ "${WT_SERVER_RESOLV_MODE}" = "2" ]
}

wt_refresh_node_direct_dns_if_needed() {
	local dns_plan=""

	fss_refresh_node_direct_cache >/dev/null 2>&1
	wt_server_resolv_mode_is_dynamic || return 0
	[ "$(dbus get ss_basic_enable)" = "1" ] || return 0
	dns_plan=$(dbus get ss_basic_dns_plan)
	case "${dns_plan}" in
	1|2)
			;;
	*)
		return 0
		;;
	esac
	fss_node_direct_cache_differs_from_runtime || return 0
	/bin/sh /koolshare/ss/ssconfig.sh refresh_node_direct_dns >/dev/null 2>&1
}

detect_perf(){
	WT_ARCH=$(uname -m)
	WT_CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
	WT_MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
	WT_LOW_END=0

	# 低端机型： armv7l设备，或者aarch64设备，内存小于1G
	# 高端机型： aarch64设备，且内存1G及其以上
	if [ "${WT_ARCH}" == "armv7l" ];then
		WT_LOW_END=1
	elif [ "${WT_ARCH}" == "aarch64" ];then
		if [ "${WT_CPU_CORES}" -le 2 -o "${WT_MEM_MB}" -lt 768 ];then
			WT_LOW_END=1
		fi
	else
		WT_LOW_END=1
	fi

	if [ "${WT_LOW_END}" == "1" ];then
		WT_XRAY_THREADS=1
		WT_SSR_THREADS=1
		if [ "$(nvram get odmpid)" == "RT-AX89X" ];then
			WT_XRAY_THREADS=4
			WT_SSR_THREADS=2
		fi
	else
		if [ "${WT_CPU_CORES}" -ge 3 -a "${WT_MEM_MB}" -ge 1024 ];then
			# aarch64 4cores + 2G内存
			WT_XRAY_THREADS=8
			WT_SSR_THREADS=4
		else
			# aarch64 4cores + 1G内存
			WT_XRAY_THREADS=4
			WT_SSR_THREADS=2
		fi
	fi
}

ensure_latency_batch(){
	if [ -z "${ss_basic_latency_batch}" ];then
		detect_perf
		if [ "${WT_LOW_END}" == "1" ];then
			dbus set ss_basic_latency_batch="0"
			ss_basic_latency_batch="0"
		else
			dbus set ss_basic_latency_batch="1"
			ss_basic_latency_batch="1"
		fi
	fi
}

update_webtest_file(){
	if [ "${WT_SINGLE}" == "1" ];then
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat >> /tmp/upload/webtest.txt
	else
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > /tmp/upload/webtest.txt
	fi
}

get_webtest_usable_count(){
	local webtest_file="$1"
	[ -f "${webtest_file}" ] || {
		echo 0
		return 0
	}
	awk -F '>' '
		$1 != "stop" && ($2 == "failed" || $2 == "timeout" || $2 == "ns" || $2 ~ /^[0-9]+$/) {count++}
		END {print count + 0}
	' "${webtest_file}" 2>/dev/null
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
# 6. 二进制启动目标为开socks5端口，然后用curl通过该端口进行落地延迟测试
# 7. ss ssr这类以开多个二进制来增加线程，xray测试则使用一个线程 + 开多个socks5端口的配置文件来进行测试
# 8. 运行测试的时候，需要将各个二进制改名后运行，以免ssconfig.sh的启停将某个测试进程杀掉

webtest_web(){
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		http_response "batch_disabled"
		return 0
	fi
	# 1. 如果没有结果文件，需要去获取webtest
	if [ ! -f "/tmp/upload/webtest.txt" ];then
		local backup_usable=$(get_webtest_usable_count /tmp/upload/webtest_bakcup.txt)
		if [ "${backup_usable}" -gt "0" ];then
			http_response "ok3, partial cache exists, keep it"
			return 0
		fi
		clean_webtest
		start_webtest
		return 0
	fi

	# 2. 如果有结果文件，且lock 存在，说明正在webtest，那么告诉web自己去拿结果吧
	if [ -f "/tmp/webtest.lock" ];then
		http_response "ok1, lock exist, webtest is running..."
		return 0
	fi

	# 3. 如果有结果该文件，且没有lock（webtest完成了的），需要检测下节点数量和webtest数量是否一致，避免新增节点没有webtest
	local webtest_nu=$(cat /tmp/upload/webtest.txt | awk -F ">" '{print $1}' | sort -un | sed '/stop/d' | wc -l)
	local node_nu=$(wt_node_count)
	if [ "${webtest_nu}" -ne "${node_nu}" ];then
		local backup_usable=$(get_webtest_usable_count /tmp/upload/webtest_bakcup.txt)
		if [ "${backup_usable}" -gt "0" ];then
			http_response "ok3, partial cache exists, keep it"
			return 0
		fi
		clean_webtest
		start_webtest
		return 0
	fi

	# 4. 如果有结果该文件，且没有lock（webtest完成了的），且节点数和webtest结果数一致，比较下上次webtest结果生成的时间，如果是15分钟以内，则不需要重新webtest
	TS_LST=$(/bin/date -r /tmp/upload/webtest.txt "+%s")
	TS_NOW=$(/bin/date +%s)
	TS_DUR=$((${TS_NOW} - ${TS_LST}))
	if [ "${TS_DUR}" -lt "1800" ];then
		http_response "ok2, webtest result in 30min, do not refresh!"
	else
		clean_webtest
		start_webtest
	fi
}

start_webtest(){
	# create lock
	touch /tmp/webtest.lock
	WT_SINGLE=0
	WT_SKIP_DNS=0
	wt_refresh_node_direct_dns_if_needed
	ensure_latency_batch
	
	# 1. prepare
	mkdir -p ${TMP2}
	rm -rf ${TMP2}/*
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	ln -sf /koolshare/bin/curl-fancyss ${TMP2}/curl-webtest

	# 2. 分类
	sort_nodes

	# 3. 测试
	test_nodes

	# 4. remove lock
	rm -rf /tmp/webtest.lock
}

sort_nodes(){
	# 1.给所有节点分类
	# 00_01 ss 
	# 00_02 ss + obfs
	# 00_03 ss + v2ray					# deprecated since 3.3.6
	# 00_04 ss2022
	# 00_05 ss2022 + obfs
	# 00_06 ss2022 + v2ray				# deprecated since 3.3.6
	# 01 ssr
	# 02 koolgame (deleted in 3.0.4)
	# 03 v2ray
	# 04 xray
	# 05 trojan
	# 06 naive
	# 07 tuic
	# 08 hysteria2

	# sort by type first
	local count=1
	local prev_type=""
	local group_file=""
	: >${TMP2}/nodes_index.txt
	fss_list_node_ids | while read node_id
	do
		[ -z "${node_id}" ] && continue
		printf "%s %02d\n" "${node_id}" "$(wt_node_get type ${node_id})" >>${TMP2}/nodes_index.txt
	done
	sort -t " " -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt
	while read node_id node_type
	do
		[ -z "${node_id}" ] && continue
		[ -z "${node_type}" ] && continue
		if [ "${node_type}" != "${prev_type}" ];then
			group_file="${TMP2}/wt_${count}_${node_type}.txt"
			: > "${group_file}"
			count=$((count + 1))
			prev_type="${node_type}"
		fi
		echo "${node_id}" >> "${group_file}"
	done < ${TMP2}/nodes_index.txt

	# then sort shadowsocks
	local wt_flies=$(find ${TMP2}/wt_*.txt|sort -t "/" -nk5)
	for file in ${wt_flies}
	do
		local file_name=${file##*/}
		local node_type=${file_name##*_}
		local node_type=${node_type%%.*}
		local pref_name=${file_name%_*}
		if [ ${node_type} == "00" ];then
			# echo $file
			# echo $file_name
			# echo $node_type
			# echo $pref_name
			cat $file | while read ss_nu
			do
				# echo $ss_nu
				local _obfs=$(wt_node_get ss_obfs ${ss_nu})
				local _method=$(wt_node_get method ${ss_nu})
				local ss_2022=$(echo ${_method} | grep "2022-blake")
				if [ -z "${_obfs}" -o "${_obfs}" == "0" ];then
					local _obfs_enable="0"
				else
					local _obfs_enable="1"
				fi
				if [ -z "${ss_2022}" ];then
					if [ "${_obfs_enable}" == "0" ];then
						echo ${ss_nu} >>${TMP2}/${pref_name}_00_01.txt
					elif [ "${_obfs_enable}" == "1" ];then
						echo ${ss_nu} >>${TMP2}/${pref_name}_00_02.txt
					fi
				else
					if [ "${_obfs_enable}" == "0" ];then
						echo ${ss_nu} >>${TMP2}/${pref_name}_00_04.txt
					elif [ "${_obfs_enable}" == "1" ];then
						echo ${ss_nu} >>${TMP2}/${pref_name}_00_05.txt
					fi
				fi
			done
			rm -rf $file
		fi
	done
}

test_nodes(){
	# define
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	detect_perf

	# 优先测试当前节点及其附近的同类型节点，重排生成节点序号储存文件
	local CURR_NODE=$(fss_get_current_node_id)
	[ -z "${CURR_NODE}" ] && CURR_NODE=$(fss_get_first_node_id)
	MAX_SHOW=$(dbus get ss_basic_row)
	if [ "${MAX_SHOW}" -gt "1" ];then 
		BEGN_NODE=$(awk -v x=${CURR_NODE} -v y=${MAX_SHOW} 'BEGIN { printf "%.0f\n", (x-y/2)}')
	else
		BEGN_NODE=$((${CURR_NODE} - 10))
	fi

	local CURR_FILE=$(find ${TMP2}/ -name "wt_*.txt" | xargs grep -Ew "^${CURR_NODE}" | awk -F ":" '{print $1}')
	if [ -f "${CURR_FILE}" ];then
		local FIRST_BGN=$(cat ${CURR_FILE}|sed -n '1p')
		if [ -f "${CURR_FILE}" -a "${BEGN_NODE}" -gt "${FIRST_BGN}" ];then
			sed -n "/${BEGN_NODE}/,\$p" ${CURR_FILE} > ${TMP2}/re-arrange-1.txt 
			sed -n "1,/^${BEGN_NODE}\$/p" ${CURR_FILE} | sed '$d' > ${TMP2}/re-arrange-2.txt
			cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${CURR_FILE}
			rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
		fi
	fi

	# tell web, you can start to get result now...
	true >/tmp/upload/webtest.txt
	http_response "ok4, webtest.txt generating..."

	# 优先测试当前节点所属的节点类型
	find ${TMP2}/wt_*.txt|sort -t"/" -n > ${TMP2}/nodes_file_name.txt
	local CURR_FILE=$(find ${TMP2} -name "wt_*.txt" | xargs grep -Ew "^${CURR_NODE}" | awk -F ":" '{print $1}')
	local CURR_FILE=${CURR_FILE##*/}
	local CURR_FILE=${CURR_FILE%%.*}
	local TOTA_LINE=$(cat ${TMP2}/nodes_file_name.txt | wc -l)
	local CURR_LINE=$(sed -n "/${CURR_FILE}/=" ${TMP2}/nodes_file_name.txt)
	if [ "${CURR_LINE}" -gt "1" ];then
		sed -n "${CURR_LINE},\$p" ${TMP2}/nodes_file_name.txt > ${TMP2}/nodes_file_name-1.txt
		sed -n "1,${CURR_LINE}p" ${TMP2}/nodes_file_name.txt | sed '$d' > ${TMP2}/nodes_file_name-2.txt
		cat ${TMP2}/nodes_file_name-1.txt ${TMP2}/nodes_file_name-2.txt > ${TMP2}/nodes_file_name.txt
		rm -f ${TMP2}/nodes_file_name-1.txt ${TMP2}/nodes_file_name-2.txt	
	fi
	
	#echo CURR_LINE $CURR_LINE
	#echo CURR_FILE $CURR_FILE
	#echo BEGN_NODE $BEGN_NODE

	# merge all xray-core capable nodes into one file for batch testing
	local XRAY_GROUP_FILE="${TMP2}/wt_xray_group.txt"
	local XRAY_GROUP_NAME="wt_xray_group.txt"
	rm -rf ${XRAY_GROUP_FILE}
	find ${TMP2}/wt_*.txt|sort -t"/" -n | while read xfile; do
		local xfile_name=${xfile##*/}
		local xnode_type=${xfile_name#wt_*_}
		local xnode_type=${xnode_type%%.*}
		case ${xnode_type} in
		00_01|00_02|00_04|00_05|03|04|05|08)
			cat ${xfile} >> ${XRAY_GROUP_FILE}
			;;
		esac
	done
	if [ -s "${XRAY_GROUP_FILE}" ];then
		local XR_CURR=$(grep -Ew "^${CURR_NODE}$" ${XRAY_GROUP_FILE})
		if [ -n "${XR_CURR}" ];then
			local XR_FIRST=$(cat ${XRAY_GROUP_FILE} | sed -n '1p')
			if [ "${BEGN_NODE}" -gt "${XR_FIRST}" ];then
				sed -n "/${BEGN_NODE}/,\$p" ${XRAY_GROUP_FILE} > ${TMP2}/re-arrange-1.txt
				sed -n "1,/^${BEGN_NODE}\$/p" ${XRAY_GROUP_FILE} | sed '$d' > ${TMP2}/re-arrange-2.txt
				cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${XRAY_GROUP_FILE}
				rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
			fi
		fi
	fi
	
	local xray_group_done=0
	cat ${TMP2}/nodes_file_name.txt | while read test_file
	do
		local file_name=${test_file##*/}
		local node_type=${file_name#wt_*_}
		local node_type=${node_type%%.*}
		local pref_name=${file_name%_*}

		#echo -----------------
		#echo test_file $test_file
		#echo file_name $file_name
		#echo node_type $node_type
		#echo pref_name $pref_name
		#echo -----------------
		# 00_01 ss
		# 00_02 ss + obfs
		# 00_03 ss + v2ray					# deprecated since 3.3.6
		# 00_04 ss2022
		# 00_05 ss2022 + obfs
		# 00_06 ss2022 + v2ray				# deprecated since 3.3.6
		# 01 ssr
		# 02 koolgame (deleted in 3.0.4)
		# 03 v2ray
		# 04 xray
		# 05 trojan
		# 06 naive
		# 07 tuic
		# 08 hysteria2
		case $node_type in
		00_01|00_02|00_04|00_05|03|04|05|08)
			if [ "${xray_group_done}" != "1" -a -s "${XRAY_GROUP_FILE}" ];then
				test_xray_group ${XRAY_GROUP_NAME} xg
				xray_group_done=1
			fi
			;;
		01)
			test_07_sr $file_name $node_type
			;;
		06)
			test_11_nv $file_name $node_type
			;;
		07)
			test_12_tc $file_name $node_type
			;;
		esac
	done
	
	# finish mark
	find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > /tmp/upload/webtest.txt
	echo -en "stop>stop\n" >>/tmp/upload/webtest.txt

	# record timestamp
	local TS_LOG=$(date -r /tmp/upload/webtest.txt "+%Y/%m/%d %X")
	dbus set ss_basic_webtest_ts="${TS_LOG}"

	# copy webtest.txt for other useage
	cp -rf /tmp/upload/webtest.txt /tmp/upload/webtest_bakcup.txt

	# we shold remove test tmp file
	
}

test_xray_group(){
	# test nodes by single xray instance
	local file=$1
	local mark=$2
	[ -z "${WT_XRAY_THREADS}" ] && WT_XRAY_THREADS=1
	[ ! -f "${TMP2}/${file}" ] && return 0
	local count=$(cat ${TMP2}/${file} | wc -l)
	[ "${count}" -lt 1 ] && return 0
	local JQ_BIN="/koolshare/bin/jq"
	if [ ! -x "${JQ_BIN}" ];then
		JQ_BIN="$(command -v jq 2>/dev/null)"
	fi
	[ -z "${JQ_BIN}" ] && JQ_BIN="/usr/bin/jq"

	# show info to web as soon as possible
	cat ${TMP2}/${file} | xargs -n ${WT_XRAY_THREADS} | sed -n '1p' | while read nus; do
		for nu in $nus; do
			echo -en "${nu}>testing...\n" >>/tmp/upload/webtest.txt
		done
	done

	# prepare
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	ln -sf /koolshare/bin/xray ${TMP2}/wt-xray
	ln -sf /koolshare/bin/obfs-local ${TMP2}/wt-obfs
	mkdir -p ${TMP2}/conf_${mark}
	mkdir -p ${TMP2}/json_${mark}
	mkdir -p ${TMP2}/bash_${mark}
	mkdir -p ${TMP2}/logs_${mark}
	rm -rf ${TMP2}/conf_${mark}/*
	rm -rf ${TMP2}/json_${mark}/*
	rm -rf ${TMP2}/bash_${mark}/*
	rm -rf ${TMP2}/logs_${mark}/*
	rm -f ${TMP2}/socsk5_ports.txt

	# gen xray json for all nodes
	cat ${TMP2}/${file} | while read nu; do
		local node_type=$(wt_node_get type ${nu})
		case ${node_type} in
		0)
			wt_gen_ss_outbound ${nu} ${mark}
			;;
		3)
			wt_gen_vmess_outbound ${nu} ${mark}
			;;
		4)
			wt_gen_vless_outbound ${nu} ${mark}
			;;
		5)
			wt_gen_trojan_outbound ${nu} ${mark}
			;;
		8)
			wt_gen_hy2_outbound ${nu} ${mark}
			;;
		esac
		wt_write_inbound_routing ${nu} ${mark}
	done

	# merge all xray json
	find ${TMP2}/conf_${mark} -name "*_inbounds.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{ inbounds: [ inputs.inbounds[0] ] }' >${TMP2}/json_${mark}/00_inbounds.json
	find ${TMP2}/conf_${mark} -name "*_outbounds.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{ outbounds: [ inputs.outbounds[0] ] }' >${TMP2}/json_${mark}/01_outbounds.json
	find ${TMP2}/conf_${mark} -name "*_routing.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{routing: { rules: [ inputs.routing.rules[0] ] }}' >${TMP2}/json_${mark}/02_routing.json
	if [ ! -s "${TMP2}/json_${mark}/00_inbounds.json" -o ! -s "${TMP2}/json_${mark}/01_outbounds.json" -o ! -s "${TMP2}/json_${mark}/02_routing.json" ];then
		cat ${TMP2}/${file} | while read nu; do
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
		done
		update_webtest_file
		return 0
	fi

	# now we can start xray to host multiple outbounds
	run ${TMP2}/wt-xray run -confdir ${TMP2}/json_${mark}/ >${TMP2}/logs_${mark}/log.txt 2>&1 &
	local xray_pid=$!

	# make sure xray is runing, otherwise output error
	wait_program2 wt-xray ${TMP2}/logs_${mark}/log.txt started
	if ! pidof wt-xray >/dev/null 2>&1;then
		cat ${TMP2}/${file} | while read nu; do
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
		done
		update_webtest_file
		return 0
	fi

	if [ -f "${TMP2}/socsk5_ports.txt" ];then
		eval $(cat ${TMP2}/socsk5_ports.txt)
	fi

	# test in multiple process (FIFO semaphore)
	local count=$(cat ${TMP2}/${file} | wc -l)
	[ "${count}" -lt 1 ] && return 0
	if [ "${WT_XRAY_THREADS}" -gt "${count}" ];then
		WT_XRAY_THREADS=${count}
	fi

	local fifo="${TMP2}/fd1_${mark}"
	[ -e "${fifo}" ] || mknod "${fifo}" p
	exec 3<>"${fifo}"
	rm -f "${fifo}"

	local i=0
	while [ ${i} -lt ${WT_XRAY_THREADS} ]; do
		echo >&3
		i=$((i+1))
	done

	local pids=""
	while read -r nu; do
		[ -z "${nu}" ] && continue
		read -r _ <&3
		{
			trap 'echo >&3' EXIT
			# 0. testing info
			echo -en "${nu}>testing...\n" >>/tmp/upload/webtest.txt

			# 1. start obfs-local if needed
			if [ -x "${TMP2}/bash_${mark}/start_${nu}.sh" ];then
				sh ${TMP2}/bash_${mark}/start_${nu}.sh
			fi

			# 2. start curl test
			local socks5_port=$(eval echo \$socks5_port_${nu})
			if [ -z "${socks5_port}" ];then
				echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
				# 4. update result to web file
				cat ${TMP2}/results/${nu}.txt >> /tmp/upload/webtest.txt
				exit 0
			fi
			curl_test ${nu} ${socks5_port}

			# 3. stop obfs-local if needed
			if [ -x "${TMP2}/bash_${mark}/stop_${nu}.sh" ];then
				sh ${TMP2}/bash_${mark}/stop_${nu}.sh
			fi

			# 4. update result to web file
			if [ -f "${TMP2}/results/${nu}.txt" ];then
				cat ${TMP2}/results/${nu}.txt >> /tmp/upload/webtest.txt
			fi
		} &
		pids="${pids} $!"
	done < ${TMP2}/${file}
	if [ -n "${pids}" ]; then
		wait ${pids}
	fi

	exec 3<&-
	exec 3>&-

	# finished kill xray
	if [ -n "${xray_pid}" ]; then
		kill ${xray_pid} >/dev/null 2>&1
	fi
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1

	# finished
	rm -rf ${TMP2}/wt-xray
	rm -rf ${TMP2}/wt-obfs
}

test_07_sr(){
	local file=$1
	local mark=$2
	
	# alisa binary
	killall wt-rss-local >/dev/null 2>&1
	ln -sf /koolshare/bin/rss-local ${TMP2}/wt-rss-local
	mkdir -p ${TMP2}/conf_${mark}
	rm -rf ${TMP2}/conf_${mark}/*

	cat ${TMP2}/${file} | xargs -n 8 | while read nus; do
		for nu in $nus; do
			{
				# 0. testing info
				echo -en "${nu}>testing...\n" >>/tmp/upload/webtest.txt
				
				# 1. resolve server
				local _server_ip=$(_get_server_ip $(wt_node_get server ${nu}))
				if [ -z "${_server_ip}" ];then
					# use domain
					_server_ip=$(wt_node_get server ${nu})
				fi

				# 2. gen json conf
				local socks5_port=$(get_rand_port)
				cat >${TMP2}/conf_${mark}/${nu}.json <<-EOF
					{
					    "server":"${_server_ip}",
					    "server_port":$(wt_node_get port ${nu}),
					    "local_address":"0.0.0.0",
					    "local_port":${socks5_port},
					    "password":"$(wt_node_get password ${nu} | base64_decode)",
					    "timeout":600,
					    "protocol":"$(wt_node_get rss_protocol ${nu})",
					    "protocol_param":"$(wt_node_get rss_protocol_param ${nu})",
					    "obfs":"$(wt_node_get rss_obfs ${nu})",
					    "obfs_param":"$(wt_node_get rss_obfs_param ${nu})",
					    "method":"$(wt_node_get method ${nu})"
					}
				EOF

				# 3. start rss-local
				run ${TMP2}/wt-rss-local -c ${TMP2}/conf_${mark}/${nu}.json -f ${TMP2}/pids/${nu}.pid >/dev/null 2>&1
				sleep 1

				# 4. start curl test
				curl_test ${nu} ${socks5_port}

				# 5. stop rss-local
				if [ -f "${TMP2}/pids/${nu}.pid" ];then
					kill -9 $(cat ${TMP2}/pids/${nu}.pid) >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > /tmp/upload/webtest.txt
	done

	rm -rf ${TMP2}/wt-ss-local
}

test_11_nv(){
	local file=$1

	# alisa binary
	ln -sf /koolshare/bin/naive ${TMP2}/wt-naive
	killall wt-naive >/dev/null 2>&1

	cat ${TMP2}/${file} | xargs -n 1 | while read nus; do
		for nu in $nus; do
			{
				# 1. resolve server
				local _server_ip=$(_get_server_ip $(wt_node_get naive_server ${nu}))

				# 2. start naiveproxy
				local socks5_port=$(get_rand_port)
				if [ -z "${_server_ip}" ];then
					run ${TMP2}/wt-naive --listen=socks://127.0.0.1:${socks5_port} --proxy=$(wt_node_get naive_prot ${nu})://$(wt_node_get naive_user ${nu}):$(wt_node_get naive_pass ${nu} | base64_decode)@$(wt_node_get naive_server ${nu}):$(wt_node_get naive_port ${nu}) >/dev/null 2>&1 &
				else
					run ${TMP2}/wt-naive --listen=socks://127.0.0.1:${socks5_port} --proxy=$(wt_node_get naive_prot ${nu})://$(wt_node_get naive_user ${nu}):$(wt_node_get naive_pass ${nu} | base64_decode)@$(wt_node_get naive_server ${nu}):$(wt_node_get naive_port ${nu}) --host-resolver-rules="MAP $(wt_node_get naive_server ${nu}) ${_server_ip}" >/dev/null 2>&1 &
				fi

				sleep 2

				# 4. start curl test
				curl_test ${nu} ${socks5_port}

				# 5. stop naive
				local _pid=$(ps | grep wt-naive | grep ${socks5_port} | awk '{print $1}')
				if [ -n "${_pid}" ];then
					kill -9 ${_pid} >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		update_webtest_file
	done
	
	killall wt-naive >/dev/null 2>&1
	rm -rf ${TMP2}/wt-naive
}

test_12_tc(){
	local file=$1

	# alisa binary
	ln -sf /koolshare/bin/tuic-client ${TMP2}/wt-tuic
	killall wt-tuic >/dev/null 2>&1

	cat ${TMP2}/${file} | xargs -n 1 | while read nus; do
		for nu in $nus; do
			{
				# 1. gen json
				local socks5_port=$(get_rand_port)
				local new_addr="127.0.0.1:${socks5_port}"
				local tuic_json_file="${TMP2}/conf/tuic-${socks5_port}.json"
				local relay_server_raw=""
				local relay_host=""
				local relay_ip=""
				wt_node_get tuic_json ${nu} | base64_decode | run jq --arg addr "$new_addr" '.local.server = $addr' >${tuic_json_file}
				relay_server_raw=$(cat ${tuic_json_file} | run jq -r '.relay.server // empty' 2>/dev/null)
				{
					read -r relay_host
					read -r _
				} <<-EOF
				$(fss_extract_tuic_server_host_port "${relay_server_raw}")
				EOF
				relay_ip=$(_get_server_ip "${relay_host}")
				if [ -n "${relay_ip}" ];then
					cat ${tuic_json_file} | run jq --arg ip "${relay_ip}" '.relay.ip = $ip' | run sponge ${tuic_json_file}
				else
					cat ${tuic_json_file} | run jq 'del(.relay.ip)' | run sponge ${tuic_json_file}
				fi

				# 2. start tuic
				run ${TMP2}/wt-tuic -c ${tuic_json_file} >/dev/null 2>&1 &

				sleep 2

				# 4. start curl test
				curl_test ${nu} ${socks5_port}

				# 5. stop tuic
				local _pid=$(ps | grep "wt-tuic" | grep -v grep | grep ${socks5_port} | awk '{print $1}')
				if [ -n "${_pid}" ];then
					kill -9 ${_pid} >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		update_webtest_file
	done
	
	killall wt-tuic >/dev/null 2>&1
	rm -rf ${TMP2}/wt-tuic
}

creat_trojan_json(){
	local nu=$1
	local trojan_server=$(wt_node_get server ${nu})
	local trojan_port=$(wt_node_get port ${nu})
	local trojan_uuid=$(wt_node_get trojan_uuid ${nu})
	local trojan_sni=$(wt_node_get trojan_sni ${nu})
	local trojan_ai=$(wt_node_get trojan_ai ${nu})
	local trojan_ai_global=$(dbus get ss_basic_tjai${nu})
	if [ "${trojan_ai_global}" == "1" ];then
		local trojan_ai="1"
	fi
	local trojan_tfo=$(wt_node_get trojan_tfo ${nu})
	local _server_ip=$(_get_server_ip ${trojan_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${trojan_server}
	fi

	
	# outbounds area
	cat >>${TMP2}/conf/${nu}_outbounds.json <<-EOF
		{
		"outbounds": [
			{
				"tag": "proxy${nu}",
				"protocol": "trojan",
				"settings": {
					"servers": [{
					"address": "${_server_ip}",
					"port": ${trojan_port},
					"password": "${trojan_uuid}"
					}]
				},
				"streamSettings": {
					"network": "tcp",
					"security": "tls",
					"tlsSettings": {
						"serverName": $(get_value_null ${trojan_sni}),
						"allowInsecure": $(get_function_switch ${trojan_ai})
    				}
    				,"sockopt": {"tcpFastOpen": $(get_function_switch ${trojan_tfo})}
    			}
  			}
  		]
  		}
	EOF
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf/${nu}_outbounds.json
	fi
	# inbounds
	local socks5_port=$(get_rand_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >>${TMP2}/conf/${nu}_inbounds.json <<-EOF
		{
		  "inbounds": [
		    {
		      "port": ${socks5_port},
		      "protocol": "socks",
		      "settings": {
		        "auth": "noauth",
		        "udp": true
		      },
		      "tag": "socks${nu}"
		    }
		  ]
		}
	EOF
	# routing
	cat >>${TMP2}/conf/${nu}_routing.json <<-EOF
		{
		  "routing": {
		    "rules": [
		      {
		        "type": "field",
		        "inboundTag": ["socks${nu}"],
		        "outboundTag": "proxy${nu}"
		      }
		    ]
		  }
		}
	EOF
}

creat_hy2_yaml(){
	local nu=$1
	local mark=$2
	if [ -z "$(wt_node_get hy2_sni ${nu})" ];then
		__valid_ip_silent "$(wt_node_get hy2_server ${nu})"
		if [ "$?" != "0" ];then
			# not ip, should be a domain
			local hy2_sni=$(wt_node_get hy2_server ${nu})
		else
			local hy2_sni=""
		fi
	else
		local hy2_sni="$(wt_node_get hy2_sni ${nu})"
	fi

	local _server_ip=$(_get_server_ip $(wt_node_get hy2_server ${nu}))
	if [ -z "${_server_ip}" ];then
		# use domain
		_server_ip=$(wt_node_get hy2_server ${nu})
		#echo -en "${nu}:\t解析失败！\n"
		#continue
	fi

	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		server: ${_server_ip}:$(wt_node_get hy2_port ${nu})
		
		auth: $(wt_node_get hy2_pass ${nu})

		tls:
		  sni: ${hy2_sni}
		  insecure: $(get_function_switch $(wt_node_get hy2_ai ${nu}))
		
		fastOpen: $(get_function_switch $(wt_node_get hy2_tfo ${nu}))
		
	EOF
	
	if [ -n "$(wt_node_get hy2_up ${nu})" -o -n "$(wt_node_get hy2_dl ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			bandwidth: 
			  up: $(wt_node_get hy2_up ${nu}) mbps
			  down: $(wt_node_get hy2_dl ${nu}) mbps
			
		EOF
	fi

	if [ "$(wt_node_get hy2_obfs ${nu})" == "1" -a -n "$(wt_node_get hy2_obfs_pass ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			obfs:
			  type: salamander
			  salamander:
			    password: "$(wt_node_get hy2_obfs_pass ${nu})"
			
		EOF
	fi

	local socks5_port=$(get_rand_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		transport:
		  udp:
		    hopInterval: 30s
		
		socks5:
		  listen: 127.0.0.1:${socks5_port}
	EOF
}

curl_test(){
	local nu=$1
	local port=$2

	# curl-fancyss -o /dev/null -s -I -x socks5h://127.0.0.1:23456 --connect-timeout 5 -m 10 -w "%{time_total}|%{response_code}\n" http://www.google.com.tw

	# single node: dual-protocol staggered test
	# round1: socks5h + socks5 (5s timeout), round2 after 1s: socks5h + socks5 (4s timeout)
	# pick the best result, max wait about 5s
	# multi node: sequential 4 runs (4s/4s/3s/3s), pick the best result
	local ret=""
	local has_timeout=0
	local tdir="${TMP2}/curl_${nu}"
	rm -rf ${tdir}
	mkdir -p ${tdir}

	run_curl_once(){
		local idx=$1
		local t=$2
		local proto=$3
		local out=$(__timeout_run ${t} ${TMP2}/curl-webtest -o /dev/null -s -I -x ${proto}://127.0.0.1:${port} --connect-timeout ${t} -m ${t} -w "%{time_total}|%{response_code}\n" ${ss_basic_furl} 2>/dev/null)
		local rc=$?
		echo "${rc}|${out}" > ${tdir}/run${idx}.txt
	}

	if [ "${WT_SINGLE}" == "1" ];then
		local pids=""
		run_curl_once 1a 3 socks5h &
		pids="${pids} $!"
		run_curl_once 1b 3 socks5 &
		pids="${pids} $!"
		sleep 2
		run_curl_once 2a 3 socks5h &
		pids="${pids} $!"
		run_curl_once 2b 3 socks5 &
		pids="${pids} $!"

		wait ${pids}
		set -- ${tdir}/run1a.txt ${tdir}/run1b.txt ${tdir}/run2a.txt ${tdir}/run2b.txt

	else
		run_curl_once 1a 3 socks5h
		run_curl_once 1b 3 socks5
		run_curl_once 2a 3 socks5h
		run_curl_once 2b 3 socks5
		set -- ${tdir}/run1a.txt ${tdir}/run1b.txt ${tdir}/run2a.txt ${tdir}/run2b.txt
	fi

	for f in "$@"; do
		[ -f "${f}" ] || continue
		local rc=$(cut -d"|" -f1 ${f})
		local out=$(cut -d"|" -f2- ${f})
		if [ "${rc}" = "124" -o "${rc}" = "28" ];then
			has_timeout=1
			continue
		fi
		if echo "${out}" | grep -q "|"; then
			if [ -n "${ret}" ];then
				ret="${ret}@${out}"
			else
				ret="${out}"
			fi
		fi
	done
	rm -rf ${tdir}
	if [ -n "${ret}" ];then
		local best=$(echo ${ret} | sed 's/@/\n/g' | sort -n | sed -n '1p')
		local ret_time=$(echo $best | awk -F "|" '{printf "%.0f\n", $1 * 1000}')
		local ret_code=$(echo $best | awk -F "|" '{print $2}')
		if [ "${ret_code}" == "200" -o "${ret_code}" == "204" ];then
			if [ "${ret_time}" -gt 5000 ];then
				echo -en "${nu}>timeout\n" >>${TMP2}/results/${nu}.txt
			else
				echo -en "${nu}>${ret_time}\n" >>${TMP2}/results/${nu}.txt
			fi
		else
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
		fi
	else
		if [ "${has_timeout}" = "1" ];then
			echo -en "${nu}>timeout\n" >>${TMP2}/results/${nu}.txt
		else
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
		fi
	fi
}

single_test_node(){
	local test_node="$1"
	if [ -z "${test_node}" ];then
		return 1
	fi

	WT_SINGLE=1
	WT_SKIP_DNS=0
	wt_refresh_node_direct_dns_if_needed
	detect_perf
	WT_XRAY_THREADS=1
	WT_SSR_THREADS=1

	mkdir -p ${TMP2}
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	rm -rf ${TMP2}/conf/*
	rm -rf ${TMP2}/pids/*
	rm -rf ${TMP2}/results/*
	ln -sf /koolshare/bin/curl-fancyss ${TMP2}/curl-webtest

	echo -en "${test_node}>testing...\n" >>/tmp/upload/webtest.txt

	local single_file="wt_single_${test_node}.txt"
	echo "${test_node}" > ${TMP2}/${single_file}
	local node_type=$(wt_node_get type ${test_node})
	case ${node_type} in
	0|3|4|5|8)
		test_xray_group ${single_file} xg
		;;
	1)
		test_07_sr ${single_file} single
		;;
	6)
		test_11_nv ${single_file}
		;;
	7)
		test_12_tc ${single_file}
		;;
	*)
		echo -en "${test_node}>failed\n" >>/tmp/upload/webtest.txt
		;;
	esac

	# 避免内部测速函数复用局部变量名后把原节点序号冲掉。
	update_single_backup "${test_node}"
	echo -en "stop>stop\n" >>/tmp/upload/webtest.txt
}

update_single_backup(){
	local nu="$1"
	[ -z "${nu}" ] && return 0
	local new_line=$(grep "^${nu}>" /tmp/upload/webtest.txt | tail -n 1)
	[ -z "${new_line}" ] && return 0
	mkdir -p /tmp/upload ${TMP2}
	local tmp_file="${TMP2}/webtest_bakcup.tmp"
	: > ${tmp_file}
	if [ -f "/tmp/upload/webtest_bakcup.txt" ];then
		grep -v -E "^${nu}>|^stop>" /tmp/upload/webtest_bakcup.txt > ${tmp_file} || true
	else
		grep -v -E "^${nu}>|^stop>" /tmp/upload/webtest.txt > ${tmp_file} || true
	fi
	echo "${new_line}" >> ${tmp_file}
	echo "stop>stop" >> ${tmp_file}
	mv -f ${tmp_file} /tmp/upload/webtest_bakcup.txt
}

_get_server_ip() {
	local SERVER_IP
	if [ "${WT_SKIP_DNS}" = "1" ];then
		SERVER_IP=$(__valid_ip $1)
		if [ -n "${SERVER_IP}" ]; then
			echo $SERVER_IP
		else
			echo $1
		fi
		return 0
	fi
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		echo "$1 不是域名也不是ip" >>${TMP2}/webtest_log.txt
		echo ""
		return 2
	fi

	SERVER_IP=$(__valid_ip $1)
	if [ -n "${SERVER_IP}" ]; then
		echo "$1 已经是ip，跳过解析！" >>${TMP2}/webtest_log.txt
		echo $SERVER_IP
		return 0
	fi

	wt_server_resolv_mode_is_dynamic && {
		echo ""
		return 0
	}

	local ss_basic_server_resolv=$(dbus get ss_basic_server_resolv)
	[ -n "${ss_basic_server_resolv}" ] || ss_basic_server_resolv="-1"

	if [ "${ss_basic_server_resolv}" -le "0" ];then
		local count=0
		local current=$(dbus get ss_basic_lastru)
		if [ $(number_test ${current}) != "0" ];then
			if [ "${ss_basic_server_resolv}" == "0" ];then
				current=$(shuf -i 1-18 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				current=$(shuf -i 1-8 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				current=$(shuf -i 11-18 -n 1)
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "0" ];then
			if [ ${current} -gt 8 -a ${current} -lt 11 ];then
				current=11
			fi
			if [ ${current} -lt 1 -o ${current} -gt 18 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-1" ];then
			if [ ${current} -lt 1 -o ${current} -gt 8 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-2" ];then
			if [ ${current} -lt 11 -o ${current} -gt 18 ];then
				current=11
			fi
		fi
		until [ ${count} -eq 18 ]; do
			SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${current}) -t 2 -i 1 @$(__get_server_resolver ${current}) $1 2>/dev/null | head -n1)
			__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
			if [ "$?" != "0" -a "$?" != "1" ]; then
				SERVER_IP=""
			fi
			if [ -n "${SERVER_IP}" -a "${SERVER_IP}" != "127.0.0.1" ]; then
				dbus set ss_basic_lastru=${current}
				break
			fi
			let current++
			if [ "${ss_basic_server_resolv}" == "0" ];then
				if [ ${current} -gt 8 -a ${current} -lt 11 ];then
					current=11
				fi
				if [ ${current} -lt 1 -o ${current} -gt 18 ];then
					current=1
				fi
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				if [ ${current} -lt 1 -o ${current} -gt 8 ];then
					current=1
				fi
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				if [ ${current} -lt 11 -o ${current} -gt 18 ];then
					current=11
				fi
			fi
			let count++
		done
	elif [ "${ss_basic_server_resolv}" == "99" ];then
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
	else
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
	fi

	# resolve failed
	if [ -z "${SERVER_IP}" ]; then
		#echo "$1 域名解析失败！" >>${TMP2}/webtest_log.txt
		echo ""
		return 1
	fi

	# resolve failed
	if [ "${SERVER_IP}" == "127.0.0.1" ]; then
		#echo "$1 解析结果为127.0.0.1，域名解析失败！" >>${TMP2}/webtest_log.txt
		echo ""
		return 1
	fi
	
	# success resolved
	#echo "$1 域名解析成功，解析结果：${SERVER_IP}" >>${TMP2}/webtest_log.txt
	echo $SERVER_IP
	return 0
}

__get_server_resolver() {
	local idx=$1
	local res
	# tcp/udp servers
	# ------------------ 国内 -------------------
	# 阿里dns
	[ "${idx}" == "1" ] && res="223.5.5.5"
	# DNSPod dns
	[ "${idx}" == "2" ] && res="119.29.29.29"
	# 114 dns
	[ "${idx}" == "3" ] && res="114.114.114.114"
	# oneDNS 拦截版
	[ "${idx}" == "4" ] && res="52.80.66.66"
	# 360安全DNS 电信/铁通/移动
	[ "${idx}" == "5" ] && res="218.30.118.6"
	# 360安全DNS 联通
	[ "${idx}" == "6" ] && res="123.125.81.6"
	# 清华大学TUNA DNS
	[ "${idx}" == "7" ] && res="101.6.6.6"
	# 百度DNS
	[ "${idx}" == "8" ] && res="180.76.76.76"
	# ------------------ 国外 -------------------
	# Google DNS
	[ "${idx}" == "11" ] && res="8.8.8.8"
	# Cloudflare DNS
	[ "${idx}" == "12" ] && res="1.1.1.1"
	# Quad9 Secured 
	[ "${idx}" == "13" ] && res="9.9.9.11"
	# OpenDNS
	[ "${idx}" == "14" ] && res="208.67.222.222"
	# DNS.SB
	[ "${idx}" == "15" ] && res="185.222.222.222"
	# AdGuard Default servers
	[ "${idx}" == "16" ] && res="94.140.14.14"
	# Quad 101 (TaiWan Province)
	[ "${idx}" == "17" ] && res="101.101.101.101"
	# CleanBrowsing
	[ "${idx}" == "18" ] && res="185.228.168.9"
	if [ "${idx}" == "99" ]; then
		local user_content=$(dbus get ss_basic_server_resolv_user)
		if [ -n "${user_content}" ];then
			local res_ip=$(echo "${user_content}"|awk -F"#|:" '{print $1}')
			local res_ip=$(__valid_ip ${res_ip})
			if [ -n "${res_ip}" ];then
				res="${res_ip}"
			else
				res="114.114.114.114"
			fi
		else
			res="114.114.114.114"
		fi
	fi
	echo ${res}
}

__get_server_resolver_port() {
	local idx=$1
	local res
	if [ "${idx}" == "99" ]; then
		local user_content=$(dbus get ss_basic_server_resolv_user)
		if [ -n "${user_content}" ];then
			local res_port=$(echo "${user_content}"|awk -F"#|:" '{print $2}')
			local res_port=$(__valid_port ${res_port})
			if [ -n "${res_port}" ];then
				res="${res_port}"
			else
				res="53"
			fi
		else
			res="53"
		fi
	elif [ "${idx}" == "7" -o "${idx}" == "14" ]; then
		res="5353"
	else
		res="53"
	fi
	echo ${res}
}

wait_program(){
	local BINNAME=$1
	local PID1
	local i=40
	until [ -n "${PID1}" ]; do
		usleep 250000
		i=$(($i - 1))
		PID1=$(pidof ${BINNAME})
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	usleep 500000
}

wait_program2(){
	local BINNAME=$1
	local LOGFILE=$2
	local CONTENT=$3
	local MATCH
	local PID1
	# wait for 4s
	local i=16
	# until [ -n "${PID1}" ]; do
	# 	usleep 250000
	# 	i=$(($i - 1))
	# 	PID1=$(pidof ${BINNAME})
	# 	if [ "$i" -lt 1 ]; then
	# 		return 1
	# 	fi
	# done
	
	until [ -n "${MATCH}" ]; do
		usleep 250000
		i=$(($i - 1))
		local MATCH=$(cat $LOGFILE 2>/dev/null | grep -w $CONTENT)
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	usleep 500000
	return 0
}

get_path_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"/\"]
	fi
}


get_host_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"\"]
	fi
}

get_function_switch() {
	case "$1" in
	1)
		echo "true"
		;;
	0 | *)
		echo "false"
		;;
	esac
}

get_grpc_multimode(){
	case "$1" in
	multi)
		echo true
		;;
	gun|*)
		echo false
		;;
	esac
}

get_ws_header() {
	if [ -n "$1" ]; then
		echo {\"Host\": \"$1\"}
	else
		echo null
	fi
}

get_host() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo null
	fi
}


get_value_null(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo null
	fi
}

get_value_empty(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo \"\"
	fi
}

clean_webtest(){
	# 当用户手动点击web test按钮的时候，不论是否有正在进行的任务，不论是否在在时限内，强制开始webtest
	# 1. killall program
	killall wt-ss >/dev/null 2>&1
	killall wt-ss-local >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	killall wt-rss-local >/dev/null 2>&1
	killall wt-v2ray >/dev/null 2>&1
	killall wt-xray >/dev/null 2>&1
	killall wt-trojan >/dev/null 2>&1
	killall wt-naive >/dev/null 2>&1
	killall wt-tuic >/dev/null 2>&1
	killall wt-hy2 >/dev/null 2>&1
	killall curl-fancyss >/dev/null 2>&1
	killall curl-webtest >/dev/null 2>&1

	# 2. kill all other ss_webtest.sh
	local current_pid=$$
	local ss_webtest_pids=$(ps|grep -E "ss_webtest\.sh"|awk '{print $1}'|grep -v ${current_pid})
	if [ -n "${ss_webtest_pids}" ];then
		for ss_webtest_pid in ${ss_webtest_pids}
		do
			kill -9 ${ss_webtest_pid} >/dev/null 2>&1
		done
	fi

	# 3. remove lock file if exist
	rm -rf /tmp/webtest.lock >/dev/null 2>&1

	# 4. remove webtest result file
	rm -rf /tmp/upload/webtest.txt
	rm -rf ${TMP2}/*
}

set_latency_job() {
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ]; then
		echo_date "批量web延迟测试已关闭!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		return 0
	fi
	if [ "${ss_basic_lt_cru_opts}" == "0" ]; then
		echo_date "定时测试节点延迟未开启!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	elif [ "${ss_basic_lt_cru_opts}" == "1" ]; then
		echo_date "设置每隔${ss_basic_lt_cru_time}分钟对所有节点进行web延迟检测..."
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		cru a sslatencyjob "*/${ss_basic_lt_cru_time} * * * * /koolshare/scripts/ss_webtest.sh 2"
	fi
}

case $1 in
2)
	# start webtest by cron
	clean_webtest
	start_webtest
	;;
3)
	set_latency_job
	;;
esac


case $2 in
web_webtest)
	# 当用户进入插件，插件列表渲染好后开始调用本脚本进行webtest
	webtest_web
	;;
clear_webtest)
	if [ -f "/tmp/webtest.lock" ];then
		http_response "busy"
		exit 0
	fi
	http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	rm -f /tmp/upload/webtest_bakcup.txt
	;;
single_test)
	if [ -f "/tmp/webtest.lock" ];then
		http_response "busy"
		exit 0
	fi
	http_response $1
	single_test_node $3
	;;
manual_webtest)
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		http_response "batch_disabled"
		exit 0
	fi
	clean_webtest
	http_response $1
	;;
close_latency_test)
	http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	;;
0)
	http_response $1
	set_latency_job
	;;
1)
	# webtest foreign url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
	fi
	set_latency_job
	;;
2)
	# webtest china url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
3)
	# webtest foreign + china url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
esac
