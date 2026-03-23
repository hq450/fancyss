#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
CURRENT=$(fss_get_current_node_id)
CURRENT_NAME=$(fss_get_node_field_plain "${CURRENT}" name)
HEART_STATUS=$(dbus get ss_heart_beat)
eval $(dbus export ss_failover_enable)
CHN_TEST_SITE="${ss_basic_curl}"
FRN_TEST_SITE="${ss_basic_furl}"
PROXY_IPV6=$(dbus get ss_basic_proxy_ipv6)
[ -z "${CHN_TEST_SITE}" ] && CHN_TEST_SITE="$(get_fancyss_default_curl)"
[ -z "${FRN_TEST_SITE}" ] && FRN_TEST_SITE="$(get_fancyss_default_furl)"
SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|trojan|naive|tuic|hysteria"|head -n1)
REDIRC_OPEN=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -Eo "ss-redir|sslocal|v2ray|xray|trojan|ipt2socks|hysteria"|head -n1)

run(){
	env -i PATH=${PATH} "$@"
}

cleanup_status_probes(){
	[ -n "${STATUS_PROBE_DIR}" ] && rm -rf "${STATUS_PROBE_DIR}" >/dev/null 2>&1
}

get_foreign_probe_mode(){
	if [ "${PROXY_IPV6}" == "1" ];then
		echo "direct"
	else
		echo "socks5"
	fi
}

set_waiting_status(){
	if [ "${PROXY_IPV6}" == "1" ];then
		log1="国外IPv4 【${LOGTIME}】：等待..."
		log3="国外IPv6 【${LOGTIME}】：等待..."
	else
		log1="国外链接 【${LOGTIME}】：等待..."
		log3=""
	fi
	log2="国内链接 【${LOGTIME}】：等待..."
}

get_status_payload(){
	if [ "${PROXY_IPV6}" == "1" ];then
		echo "${log1}@@${log3}@@${log2}"
	else
		echo "${log1}@@${log2}"
	fi
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

prepare_status_probes(){
	STATUS_PROBE_DIR="/tmp/ss_status.$$"
	rm -rf "${STATUS_PROBE_DIR}" >/dev/null 2>&1
	mkdir -p "${STATUS_PROBE_DIR}"
	CHINA_PROBE_FILE="${STATUS_PROBE_DIR}/china"
	FOREIGN4_PROBE_FILE="${STATUS_PROBE_DIR}/foreign4"
	FOREIGN6_PROBE_FILE="${STATUS_PROBE_DIR}/foreign6"
}

launch_probe(){
	local outfile="$1"
	local url="$2"
	shift 2
	(
		run /tmp/curl-status -o /dev/null "$@" --connect-timeout 5 -m 5 -w "%{time_total}|%{response_code}|%{remote_ip}\n" "${url}" 2>/dev/null >"${outfile}"
	) &
	echo $!
}

mark_probe_unavailable(){
	echo "__UNAVAILABLE__" >"$1"
}

start_status_probes(){
	prepare_status_probes
	CHINA_PROBE_PID=$(launch_probe "${CHINA_PROBE_FILE}" "${CHN_TEST_SITE}" -4 -sk -I)

	if [ "${PROXY_IPV6}" == "1" ];then
		if [ -n "${REDIRC_OPEN}" ];then
			FOREIGN4_PROBE_PID=$(launch_probe "${FOREIGN4_PROBE_FILE}" "${FRN_TEST_SITE}" -4 -sk -I)
			FOREIGN6_PROBE_PID=$(launch_probe "${FOREIGN6_PROBE_FILE}" "${FRN_TEST_SITE}" -6 -sk -I)
		else
			mark_probe_unavailable "${FOREIGN4_PROBE_FILE}"
			mark_probe_unavailable "${FOREIGN6_PROBE_FILE}"
		fi
	else
		if [ -n "${SOCKS5_OPEN}" -a -n "${REDIRC_OPEN}" ];then
			FOREIGN4_PROBE_PID=$(launch_probe "${FOREIGN4_PROBE_FILE}" "${FRN_TEST_SITE}" -4 -sk -I -x socks5://127.0.0.1:23456)
		else
			mark_probe_unavailable "${FOREIGN4_PROBE_FILE}"
		fi
	fi
}

wait_status_probes(){
	[ -n "${CHINA_PROBE_PID}" ] && wait "${CHINA_PROBE_PID}" >/dev/null 2>&1
	[ -n "${FOREIGN4_PROBE_PID}" ] && wait "${FOREIGN4_PROBE_PID}" >/dev/null 2>&1
	[ -n "${FOREIGN6_PROBE_PID}" ] && wait "${FOREIGN6_PROBE_PID}" >/dev/null 2>&1
}

read_probe_result(){
	[ -f "$1" ] && cat "$1"
}

get_china_status(){
	local ret0="$2"
	[ -z "${ret0}" ] && ret0=$(read_probe_result "${CHINA_PROBE_FILE}")
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')

	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK 🧮$1"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found 🧮$1"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed 🧮$1"
	fi
	[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_C}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		log2='国内链接 【'${LOGTIME}'】 ✓&nbsp;&nbsp;'${ret_time_ext}''
	else
		log2='国内链接 【'${LOGTIME}'】 <font color='#FF0000'>X</font>'
	fi
}

get_foreign_status_by_family(){
	local family="$1"
	local label="$2"
	local log_var="$3"
	local write_history="$4"
	local request_tag="$5"
	local ret0="$6"
	local probe_file="${FOREIGN4_PROBE_FILE}"
	[ "${family}" == "6" ] && probe_file="${FOREIGN6_PROBE_FILE}"
	[ -z "${ret0}" ] && ret0=$(read_probe_result "${probe_file}")

	if [ "${ret0}" == "__UNAVAILABLE__" ];then
		eval ${log_var}="'${label} 【${LOGTIME}】 <font color=\"#FF0000\">X</font>'"
		local ret1="${LOGTIME1} ➡️ $(get_domain_name ${FRN_TEST_SITE}) ⏱ --- ms 🌎 001 failed ✈️ ${CURRENT_NAME} 🧮${request_tag}"
		[ "${ss_failover_enable}" == "1" -a "${write_history}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}
		return 0
	fi
	
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')
	if [ "${ret_addr}" == "127.0.0.1" ];then
		local ret_addr=$(get_domain_name ${FRN_TEST_SITE})
	fi
	
	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK ✈️ ${CURRENT_NAME} 🧮${request_tag}"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found ✈️ ${CURRENT_NAME} 🧮${request_tag}"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed ✈️ ${CURRENT_NAME} 🧮${request_tag}"
	fi
	[ "${ss_failover_enable}" == "1" -a "${write_history}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		eval ${log_var}="'${label} 【${LOGTIME}】 ✓&nbsp;&nbsp;${ret_time_ext}'"
	else
		eval ${log_var}="'${label} 【${LOGTIME}】 <font color=\"#FF0000\">X</font>'"
	fi
}

get_foreign_status(){
	if [ "${PROXY_IPV6}" == "1" ];then
		get_foreign_status_by_family "4" "国外IPv4" "log1" "1" "$1" "$(read_probe_result "${FOREIGN4_PROBE_FILE}")"
		get_foreign_status_by_family "6" "国外IPv6" "log3" "0" "$1" "$(read_probe_result "${FOREIGN6_PROBE_FILE}")"
	else
		get_foreign_status_by_family "4" "国外链接" "log1" "1" "$1" "$(read_probe_result "${FOREIGN4_PROBE_FILE}")"
	fi
}

prepare(){
	# 1. exit when fancyss not enabled
	local fancyss_enable=$(dbus get ss_basic_enable)
	if [ "${fancyss_enable}" != "1" ];then
		set_waiting_status
		exit
	fi
	
	# 2. exit when ssconfig.sh is running
	local _ssconfig=$(ps | grep "ssconfig.sh" | grep -v grep)
	if [ -n "${_ssconfig}" ];then
		set_waiting_status
		exit
	fi

	if [ ! -L "/tmp/curl-status" ];then
		ln -sf /koolshare/bin/curl-fancyss /tmp/curl-status
	fi
	
	# # 3. kill all other ss_status.sh process if exist
	# local current_pid=$$
	# local ss_status_pids=$(ps | grep -E "ss_status\.sh" | awk '{print $1}'| grep -v ${current_pid})
	# if [ -n "${ss_status_pids}" ];then
	# 	for ss_status_pid in ${ss_status_pids}
	# 	do
	# 		kill -9 ${ss_status_pid} >/dev/null 2>&1
	# 	done
	# fi

	# # 4. killall curl-status
	# killall curl-status
	# local fancyss_pids=$(ps | grep "curl-status" | grep -v "grep" | grep -E "${CHN_TEST_SITE}|${FRN_TEST_SITE}" | awk '{print $1}')
	# if [ -n "${fancyss_pids}" ];then
	# 	for fancyss_pid in ${fancyss_pids}
	# 	do
	# 		kill -9 ${fancyss_pid} >/dev/null 2>&1
	# 	done
	# fi
}

if [ -z "$1" -a -z "$2" ];then
	prepare
	start_status_probes
	wait_status_probes
	get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
	get_foreign_status $1
	cleanup_status_probes
	echo "$(get_status_payload)"
	exit
fi

case $1 in
	ws)
		if [ "$(dbus get ss_basic_wait)" == "1" ];then
			set_waiting_status
		else
			prepare
			start_status_probes
			wait_status_probes
			get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
			get_foreign_status $1
			cleanup_status_probes
		fi
		echo "$(get_status_payload)"
	;;
	*)
		if [ "${ss_failover_enable}" == "1" ];then
			prepare
			start_status_probes
			wait_status_probes
			get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
			get_foreign_status $1
			cleanup_status_probes
			echo -e -n  "$(get_status_payload)@@${HEART_STATUS}\n" >/tmp/upload/ss_status.txt
		else
			if [ "$(dbus get ss_basic_wait)" == "1" ];then
				set_waiting_status
			else
				prepare
				start_status_probes
				wait_status_probes
				get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
				get_foreign_status $1
				cleanup_status_probes
			fi
			http_response "$(get_status_payload)"
		fi
	;;
esac
