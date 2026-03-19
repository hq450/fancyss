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
CHN_TEST_SITE=$(dbus get ss_basic_curl)
FRN_TEST_SITE=$(dbus get ss_basic_furl)
PROXY_IPV6=$(dbus get ss_basic_proxy_ipv6)
[ -z "${CHN_TEST_SITE}" ] && CHN_TEST_SITE="http://connectivitycheck.platform.hicloud.com/generate_204"
[ -z "${FRN_TEST_SITE}" ] && FRN_TEST_SITE="http://www.gstatic.com/generate_204"
SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|trojan|naive|tuic|hysteria"|head -n1)
REDIRC_OPEN=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -Eo "ss-redir|sslocal|v2ray|xray|trojan|ipt2socks|hysteria"|head -n1)

run(){
	env -i PATH=${PATH} "$@"
}

get_foreign_curl_ip_flag(){
	if [ "${PROXY_IPV6}" == "1" ];then
		echo ""
	else
		echo "-4"
	fi
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

get_china_status(){
	# get result by curl
	local ret0=$(run /tmp/curl-status -o /dev/null -4sk -I --connect-timeout 5 -m 5 -w "%{time_total}|%{response_code}|%{remote_ip}\n" ${CHN_TEST_SITE} 2>/dev/null)
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
get_foreign_status(){
	local CURL_IP_FLAG=$(get_foreign_curl_ip_flag)
	# get result by curl
	# local dns_safe=$(cat /etc/dnsmasq.conf | grep -Eo "7913")
	# local iptables_safe1=$(iptables -t nat -nvL OUTPUT | grep -Eo "router")
	# local iptables_safe2=$(iptables -t mangle -nvL OUTPUT | grep -Eo "router")
	# local ipset_safe=$(ipset -L router|grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$"|head -n1)
	# if [ -n "${SOCKS5_OPEN}" -a -n "${REDIRC_OPEN}" -a -n "${dns_safe}" -a -n "${iptables_safe1}" -a -n "${iptables_safe2}" -a -n "${ipset_safe}" ];then
	if [ -n "${SOCKS5_OPEN}" -a -n "${REDIRC_OPEN}" ];then
		# get foreign status through 23456 socks5 port (resolve test server domain in local)
		local ret0=$(run /tmp/curl-status -o /dev/null ${CURL_IP_FLAG} -sk -I -x socks5://127.0.0.1:23456 --connect-timeout 5 -m 5 -w "%{time_total}|%{response_code}|%{remote_ip}\n" ${FRN_TEST_SITE} 2>/dev/null)
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
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed ✈️ $(dbus get ssconf_basic_name_${CURRENT}) 🧮$1"
	fi
	[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
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
		log1="国外链接 【${LOGTIME}】：等待..."
		log2="国内链接 【${LOGTIME}】：等待..."
		exit
	fi
	
	# 2. exit when ssconfig.sh is running
	local _ssconfig=$(ps | grep "ssconfig.sh" | grep -v grep)
	if [ -n "${_ssconfig}" ];then
		log1="国外链接 【${LOGTIME}】：等待..."
		log2="国内链接 【${LOGTIME}】：等待..."
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
	get_china_status $1
	get_foreign_status $1
	echo "${log1}@@${log2}"
	exit
fi

case $1 in
	ws)
		if [ "$(dbus get ss_basic_wait)" == "1" ];then
			log1="国外链接 【${LOGTIME}】：等待..."
			log2="国内链接 【${LOGTIME}】：等待..."
		else
			prepare
			get_china_status $1
			get_foreign_status $1
		fi
		echo "${log1}@@${log2}"
	;;
	*)
		if [ "${ss_failover_enable}" == "1" ];then
			prepare
			get_china_status $1
			get_foreign_status $1
			echo -e -n  "${log1}@@${log2}@@${HEART_STATUS}\n" >/tmp/upload/ss_status.txt
		else
			if [ "$(dbus get ss_basic_wait)" == "1" ];then
				log1="国外链接 【${LOGTIME}】：等待..."
				log2="国内链接 【${LOGTIME}】：等待..."
			else
				prepare
				get_china_status $1
				get_foreign_status $1
			fi
			http_response $(echo "${log1}@@${log2}")
		fi
	;;
esac
