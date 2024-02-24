#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
CURRENT=$(dbus get ssconf_basic_node)
HEART_STATUS=$(dbus get ss_heart_beat)
eval $(dbus export ss_failover_enable)
CHN_TEST_SITE=$(dbus get ss_basic_wt_curl)
FRN_TEST_SITE=$(dbus get ss_basic_wt_furl)
[ -z "${CHN_TEST_SITE}" ] && CHN_TEST_SITE="http://www.baidu.com"
[ -z "${FRN_TEST_SITE}" ] && FRN_TEST_SITE="http://www.google.com.tw"
SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|trojan|naive|tuic|hysteria")
REDIRC_OPEN=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -Eo "ss-redir|sslocal|v2ray|xray|trojan|ipt2socks|hysteria")

run(){
	env -i PATH=${PATH} "$@"
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

get_china_status(){
	# get result by curl
	local ret0=$(run curl-fancyss -o /dev/null -s -I --connect-timeout 5 -m 5 -w "%{time_total}|%{response_code}|%{remote_ip}\n" ${CHN_TEST_SITE} 2>/dev/null)
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')

	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK 🧮$1"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found 🧮$1"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed 🧮$1"
	fi
	[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_C}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		log2='国内链接 【'${LOGTIME}'】 ✓&nbsp;&nbsp;'${ret_time_ext}''
	else
		log2='国内链接 【'${LOGTIME}'】 <font color='#FF0000'>X</font>'
	fi
}
get_foreign_status(){
	# get result by curl
	if [ -n "${SOCKS5_OPEN}" -a "${REDIRC_OPEN}" ];then
		# get foreign status through 23456 socks5 port (resolve test server domain in local)
		local ret0=$(run curl-fancyss -o /dev/null -s -I -x socks5://127.0.0.1:23456 --connect-timeout 5 -m 5 -w "%{time_total}|%{response_code}|%{remote_ip}\n" ${FRN_TEST_SITE} 2>/dev/null)
	else
		log1='国外链接 【'${LOGTIME}'】 <font color='#FF0000'>X</font>'
		local ret1="${LOGTIME1} ➡️ $(get_domain_name ${FRN_TEST_SITE}) ⏱ --- ms 🌎 001 failed ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
		[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}
		return 0
	fi
	
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')
	if [ "${ret_addr}" == "127.0.0.1" ];then
		local ret_addr=$(get_domain_name ${FRN_TEST_SITE})
	fi
	
	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	fi
	[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		log1='国外链接 【'${LOGTIME}'】 ✓&nbsp;&nbsp;'${ret_time_ext}''
	else
		log1='国外链接 【'${LOGTIME}'】 <font color='#FF0000'>X</font>'
	fi
}

prepare(){
	# 1. exit when fancyss not enabled
	local fancyss_enable=$(dbus get ss_basic_enable)
	if [ "${fancyss_enable}" != "1" ];then
		exit
	fi
	
	# 2. exit when ssconfig.sh is running
	local _ssconfig=$(ps | grep "ssconfig.sh" | grep -v grep)
	if [ -n "${_ssconfig}" ];then
		exit
	fi

	# 3. kill all other ss_status.sh process if exist
	local current_pid=$$
	local ss_status_pids=$(ps | grep -E "ss_status\.sh" | awk '{print $1}'| grep -v ${current_pid})
	if [ -n "${ss_status_pids}" ];then
		for ss_status_pid in ${ss_status_pids}
		do
			kill -9 ${ss_status_pid} >/dev/null 2>&1
		done
	fi

	# 4. killall curl-fancyss
	killall curl-fancyss
	local fancyss_pids=$(ps | grep "curl-fancyss" | grep -v "grep" | grep -E "${CHN_TEST_SITE}|${FRN_TEST_SITE}" | awk '{print $1}')
	if [ -n "${fancyss_pids}" ];then
		for fancyss_pid in ${fancyss_pids}
		do
			kill -9 ${fancyss_pid} >/dev/null 2>&1
		done
	fi
}

case $1 in
	ws)
		if [ "$(dbus get ss_basic_wait)" == "1" ];then
			log1="国外链接 【${LOGTIME}】：等待..."
			log2="国内链接 【${LOGTIME}】：等待..."
		else
			get_china_status $1
			get_foreign_status $1
		fi
		echo "${log1}@@${log2}"
	;;
	*)
		if [ "${ss_failover_enable}" == "1" ];then
			get_china_status $1
			get_foreign_status $1
			echo -e -n  "${log1}@@${log2}@@${HEART_STATUS}\n" >/tmp/upload/ss_status.txt
		else
			if [ "$(dbus get ss_basic_wait)" == "1" ];then
				log1="国外链接 【${LOGTIME}】：等待..."
				log2="国内链接 【${LOGTIME}】：等待..."
			else
				get_china_status $1
				get_foreign_status $1
			fi
			http_response $(echo "${log1}@@${log2}")
		fi
	;;
esac

