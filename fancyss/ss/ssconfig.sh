#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
#-----------------------------------------------
# Variable definitions
THREAD=$(grep -c '^processor' /proc/cpuinfo)
dbus set ss_basic_version_local=$(cat /koolshare/ss/version)
LOG_FILE=/tmp/upload/ss_log.txt
CONFIG_FILE=/koolshare/ss/ssr.json
LOCK_FILE=/var/lock/koolss.lock
DNSC_PORT=53
ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
ISP_DNS2=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 2p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
lan_ipaddr=$(nvram get lan_ipaddr)
ip_prefix_hex=$(nvram get lan_ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}')
WAN_ACTION=$(ps | grep /jffs/scripts/wan-start | grep -v grep)
NAT_ACTION=$(ps | grep /jffs/scripts/nat-start | grep -v grep)
WEB_ACTION=$(ps | grep "ss_config.sh" | grep -v grep)
ARG_OBFS=""
OUTBOUNDS="[]"
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')

#-----------------------------------------------

set_lock() {
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}

unset_lock() {
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

get_model_name(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		echo "${ODMPID}"
	else
		echo "${PRODUCTID}"
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null|head -n1)
	local ROG_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "2071044")
	local TUF_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "D0982C")
	local WRT_FLAG=$(cat /www/form_style.css|grep -A1 ".tab_NW:hover{"|grep "background"|sed 's/,//g'|grep -o "4F5B5F")
	if [ -n "${TS_FLAG}" ];then
		UI_TYPE="TS"
	else
		if [ -n "${TUF_FLAG}" ];then
			UI_TYPE="TUF"
		fi
		if [ -n "${ROG_FLAG}" ];then
			UI_TYPE="ROG"
		fi
		if [ -n "${WRT_FLAG}" ];then
			UI_TYPE="ASUSWRT"
		fi
	fi
	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

get_time(){
	local src=$1
	local debug=$2
	# Automatically Updates System Time According to the NIST Atomic Clock in a Linux Environment
	nistTime=$(run curl-fancyss -4skI --connect-timeout 2 --max-time 2 "${src}" | grep "Date")
	if [ -z "${nistTime}" ]; then
		return 1
	fi
	dateString=$(echo $nistTime | cut -d' ' -f2-7)
	dayString=$(echo $nistTime | cut -d' ' -f2-2)
	dateValue=$(echo $nistTime | cut -d' ' -f3-3)
	monthValue=$(echo $nistTime | cut -d' ' -f4-4)
	yearValue=$(echo $nistTime | cut -d' ' -f5-5)
	timeValue=$(echo $nistTime | cut -d' ' -f6-6)
	timeZoneValue=$(echo $nistTime | cut -d' ' -f7-7)
	#echo $dateString
		case $monthValue in
			"Jan")
				monthValue="01"
			;;
		"Feb")
			monthValue="02"
			;;
		"Mar")
			monthValue="03"
			;;
		"Apr")
			monthValue="04"
			;;
		"May")
			monthValue="05"
			;;
		"Jun")
			monthValue="06"
			;;
		"Jul")
			monthValue="07"
			;;
		"Aug")
			monthValue="08"
			;;
		"Sep")
			monthValue="09"
			;;
		"Oct")
			monthValue="10"
			;;
		"Nov")
			monthValue="11"
			;;
			"Dec")
				monthValue="12"
				;;
			*)
				return 1
				;;
		esac
	local UTCTIME="$yearValue.$monthValue.$dateValue-$timeValue"
	local SERVER_TIMESTAMP=$(date +%s --utc ${UTCTIME})
	if [ -n "${debug}" ];then
		local ROUTER_TIME=$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})
		echo_date "实际时间：${ROUTER_TIME}，来源：${src}"
	else
		echo ${SERVER_TIMESTAMP}
	fi
}

compare_time(){
	local TIMESTAMP_SOURCE=$1
	local SERVER_TIMESTAMP=$2
	local ROUTER_TIMESTAMP=$(date +%s)
	if [ -z "${SERVER_TIMESTAMP}" ];then
		return 1
	fi
	local TIME_DIFF=$((${SERVER_TIMESTAMP} - ${ROUTER_TIMESTAMP}))
	local TIME_DIFF=${TIME_DIFF#-}
	echo_date "实际时间：$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})，来源：${TIMESTAMP_SOURCE}"
	echo_date "路由时间：$(date +'%Y-%m-%d %H:%M:%S' -d @${ROUTER_TIMESTAMP})，来源：$(get_model_name)"
	if [ "${TIME_DIFF}" -ge "60" ];then
		echo_date "*路由器时间和实际时间相差${TIME_DIFF}秒，重新设置路由器时间为：$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})！"
		date -s @${SERVER_TIMESTAMP} >/dev/null 2>&1
		echo_date "路由器时间更新成功！"
	elif [ "${TIME_DIFF}" -eq "0" ];then
		echo_date "路由器时间和实际时间相同，继续！"
	else
		echo_date "路由器时间和实际时间相差${TIME_DIFF}秒，在允许误差范围60秒内！"
	fi
}

test_xray_conf(){
	#uset _test_ret
	local conf=$1
	local xray_asset_dir=""
	echo_date "测试xray配置文件..."
	if [ "$(get_runtime_proxy_mode)" = "7" ] && type fss_shunt_xray_asset_dir >/dev/null 2>&1; then
		xray_asset_dir="$(fss_shunt_xray_asset_dir 2>/dev/null || true)"
	fi
	if [ -n "${xray_asset_dir}" ]; then
		local test_ret=$(run env "xray.location.asset=${xray_asset_dir}" /koolshare/bin/xray run -config="${conf}" -test 2>&1)
	else
		local test_ret=$(run /koolshare/bin/xray run -config="${conf}" -test 2>&1)
	fi
	local ret_1=$(echo "$test_ret" | grep "Configuration OK.")
	local ret_2=$(echo "$test_ret" | grep "does not support fingerprint")
	#local ret_2=$(echo $test_ret | grep "Old version of XTLS does not support fingerprint")
	if [ -n "${ret_1}" ]; then
		# test OK
		_test_ret=${ret_1}
		return 0
	elif [ -n "${ret_2}" ];then
		# fingerprint should be deleted
		_test_ret=${ret_2}
		return 2
	else
		# test faild
		_test_ret=${test_ret}
		return 1
	fi
}

check_time(){
	# 因为vmess代理协议要求本地时间和服务器时间一致才能工作，所以检测下路由器时间是否设置正确
	# 时间检测优先从worldtimeapi.org获取，如果获取成功，能同时得到公网出口ipv4地址
	# 如果所有检测方式用光了还无法获取时间，说明可能是DNS无法获取到解析通造成的
	echo_date "检测路由器本地时间是否正确..."

	# debug use
	# get_time "www.weibo.com" debug
	# get_time "www.baidu.com" debug
	# get_time "www.qq.com" debug
	# get_time "www.taobao.com" debug
	# get_time "www.zhihu.com" debug
	# get_time "www.jd.com" debug
	# get_time "https://nist.time.gov/" debug
	
	local RET=$(run curl-fancyss -4sk --connect-timeout 2 --max-time 2 "http://worldtimeapi.org/api/timezone/Asia/Shanghai")
	if [ -n "${RET}" ];then
		if [ "${ss_basic_nochnipcheck}" != "1" ];then
			REMOTE_IP_OUT_SRC="worldtimeapi.org"
			REMOTE_IP_OUT=$(echo ${RET}|run jq -r '.client_ip')
		fi
		local TIMESTAMP_SOURCE="worldtimeapi.org"
		local SERVER_TIMESTAMP=$(echo ${RET}|run jq -r '.unixtime')
		if [ "${SERVER_TIMESTAMP}" == "null" ];then
			local SERVER_TIMESTAMP=""
		fi
		compare_time "worldtimeapi.org" ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.weibo.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.baidu.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.qq.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.taobao.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.jd.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="https://nist.time.gov/"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+            经多种方法尝试，均无法从服务器获取当前实际时间!            +"
		echo_date "+                 这可能是路由器DNS不通造成的!                      +"
		echo_date "+                请尝试更正此问题后重新启动插件!                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
}

check_internet4(){
	# 开启插件之前必须检查网络，如果网络不通，则插件不予开启
	# 考虑到本插件可能的国外环境用户，最后添加8.8.8.8的检测
	echo_date "➡️ ipv4网络连通性检测..."
	if [ -z "${PING4_RET}" ];then
		local PING4_SRC="223.5.5.5"
		local PING4_RET=$(ping -c 1 -w 1 ${PING4_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING4_RET}" ];then
		local PING4_SRC="119.29.29.29"
		local PING4_RET=$(ping -c 1 -w 1 ${PING4_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING4_RET}" ];then
		local PING4_SRC="114.114.114.114"
		local PING4_RET=$(ping -c 1 -w 1 ${PING4_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING4_RET}" ];then
		local PING4_SRC="1.2.4.8"
		local PING4_RET=$(ping -c 1 -w 1 ${PING4_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING4_RET}" ];then
		local PING4_SRC="8.8.8.8"
		local PING4_RET=$(ping -c 1 -w 1 ${PING4_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -n "${PING4_RET}" ];then
		echo_date "✅️ 检测到路由器可以正常访问ipv4公网，检测源：${PING4_SRC}，延迟：${PING4_RET}s，继续！"
	else
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+               检测到路由器无法正常访问ipv4公网！                     +"
		echo_date "+                 请配置好你的路由器网络后重试！                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
}

check_internet6(){
	# 开启插件之前必须检查网络，如果网络不通，则插件不予开启
	# 考虑到本插件可能的国外环境用户，最后添加2001:de4::101和2001:4860:4860::8888的检测
	echo_date "➡️ ipv6网络连通性检测..."
	if [ -z "${PING6_RET}" ];then
		local PING6_SRC="2400:3200::1"
		local PING6_RET=$(ping -c 1 -w 1 ${PING6_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING6_RET}" ];then
		local PING6_SRC="2402:4e00:: 2"
		local PING6_RET=$(ping -c 1 -w 1 ${PING6_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING6_RET}" ];then
		local PING6_SRC="2400:7fc0:849e:200::8"
		local PING6_RET=$(ping -c 1 -w 1 ${PING6_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING6_RET}" ];then
		local PING6_SRC="2001:de4::101"
		local PING6_RET=$(ping -c 1 -w 1 ${PING6_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING6_RET}" ];then
		local PING6_SRC="2001:4860:4860::8888"
		local PING6_RET=$(ping -c 1 -w 1 ${PING6_SRC} 2>/dev/null|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -n "${PING6_RET}" ];then
		echo_date "✅️ 检测到路由器可以正常访问ipv6公网，检测源：${PING6_SRC}，延迟：${PING6_RET}s，继续！"
		INTERNET6=1
	else
		#echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		#echo_date "+               检测到路由器无法正常访问ipv6公网！                     +"
		#echo_date "+                 请配置好你的路由器网络后重试！                     +"
		#echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		INTERNET6=0
	fi
}
check_internet6_pre(){
	# ipv6预检查
	if [ $(nvram get ipv6_service) == "disabled" ];then
		INTERNET6=0
		return 1
	fi

	local ipv6_addr=$(ip addr|grep -A3 -E "eth0|ppp0"|grep "scope global"|grep "inet6"|awk '{print $2}'|awk -F"/" '{print $1}')
	if [ -z "${ipv6_addr}" ];then
		INTERNET6=0
		return 1
	fi

	INTERNET6=1
	
}

check_internet(){
	# 预先检查先ipv6开关和ip地址，用于后面的DNS解析过滤
	check_internet6_pre
	
	if [ "${ss_basic_nonetcheck}" == "1" ];then
		# 用户关闭了连通性检测
		return 1
	fi
	
	check_internet4

	if [ "${INTERNET6}" == "1" ];then
		check_internet6
	fi
}

ipv6_proxy_enabled() {
	[ "${ss_basic_proxy_ipv6}" == "1" ]
}

ipv6_proxy_supported() {
	case "${ss_basic_type}" in
	0|1|3|4|5|6|7|8|9)
		return 0
		;;
	esac

	[ "${ss_basic_v2ray_use_json}" == "1" ] && return 0
	[ "${ss_basic_xray_use_json}" == "1" ] && return 0

	return 1
}

check_ipv6_proxy_prerequisites() {
	ipv6_proxy_enabled || return 0
	echo_date "➡️ IPv6透明代理预检查..."
	if ! ipv6_proxy_supported; then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+ 当前节点类型暂不支持IPv6透明代理，本次将自动回退到IPv4模式！ +"
		echo_date "+ 并强制开启代理域名IPv6过滤，避免代理域名解析到IPv6后直连。 +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	if [ "$(nvram get ipv6_service)" == "disabled" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+ 检测到路由器系统未开启IPv6，请先到【高级设置】-【IPv6】完成配置！ +"
		echo_date "+ 页面路径：/Advanced_IPv6_Content.asp                          +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	if [ ! -f "/usr/lib/xtables/libip6t_REDIRECT.so" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+ 当前固件iptables缺少libip6t_REDIRECT扩展，无法启用ipv6代理！ +"
		echo_date "+           请尝试将固件升级到最新版本后再启用此功能！         +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	check_internet6_pre
	if [ "${INTERNET6}" != "1" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+ 检测到路由器当前没有可用的IPv6全局地址，无法开启IPv6透明代理！ +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	check_internet6
	if [ "${INTERNET6}" != "1" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+ 检测到路由器当前无法正常访问IPv6公网，无法开启IPv6透明代理！ +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	if ! ip6tables -t nat -L PREROUTING >/dev/null 2>&1; then
		echo_date "错误：当前系统不支持ip6tables nat表，无法开启IPv6透明代理！"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi
	if ! ip6tables -t mangle -L PREROUTING >/dev/null 2>&1; then
		echo_date "错误：当前系统不支持ip6tables mangle表，无法开启IPv6透明代理！"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi
	if ! ip6tables -t filter -L FORWARD >/dev/null 2>&1; then
		echo_date "错误：当前系统不支持ip6tables filter表，无法开启IPv6透明代理！"
		disable_ipv6_proxy_runtime
		echo_date "↪ 已自动关闭IPv6代理开关，回退到纯IPv4代理模式继续运行。"
		return 0
	fi

	echo_date "✅️ IPv6透明代理预检查通过，继续！"
}

sync_dns_ipv6_policy() {
	set_default "ss_basic_dns_plan" "1"
	set_default "ss_basic_chng_ipv6_drop_proxy" "1"
	if [ "${ss_basic_dns_plan}" == "1" ];then
		if ipv6_proxy_enabled; then
			return 0
		fi
		if [ "${ss_basic_chng_ipv6_drop_proxy}" != "1" ];then
			echo_date "⚠️检测到当前使用chinadns-ng且未开启IPv6代理，但【过滤代理】未勾选。"
			echo_date "🔁为避免代理域名解析到IPv6地址后直连访问，本次自动启用【过滤代理】。"
			ss_basic_chng_ipv6_drop_proxy="1"
			dbus set ss_basic_chng_ipv6_drop_proxy="1"
		fi
		return 0
	fi

	if [ "${ss_basic_dns_plan}" == "2" ];then
		if ipv6_proxy_enabled; then
			echo_date "ℹ️检测到当前使用smartdns且已开启IPv6代理，SmartDNS将保留代理域名的AAAA解析。"
		else
			echo_date "ℹ️检测到当前使用smartdns且未开启IPv6代理，SmartDNS将按当前代理模式动态抑制需要代理域名的AAAA解析。"
		fi
	fi
}

check_chn_public_ip(){
	# 5.1 检测路由器公网出口IPV4地址
	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT_SRC="http://ip.ddnsto.com"
		REMOTE_IP_OUT=$(detect_ip ${REMOTE_IP_OUT_SRC} 5 0)
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT_SRC="https://ip.clang.cn"
		REMOTE_IP_OUT=$(detect_ip ${REMOTE_IP_OUT_SRC} 5 0)
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT_SRC="whatismyip.akamai.com"
		REMOTE_IP_OUT=$(detect_ip ${REMOTE_IP_OUT_SRC} 5 0)
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT=$(run curl-fancyss -4sk --connect-timeout 2 http://api.myip.com 2>&1 | grep -v "Terminated" | run jq -r '.ip' | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
		REMOTE_IP_OUT_SRC="api.myip.com"
	fi

	if [ -z "${REMOTE_IP_OUT}" -o "${REMOTE_IP_OUT}" == "null" ];then
		REMOTE_IP_OUT=$(nvram get wan0_realip_ip)
		REMOTE_IP_OUT_SRC="nvram: wan0_realip_ip"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+            经多种方法尝试，均无法检测到本机国内出口IP!               +"
		echo_date "+                 这可能是路由器DNS不通造成的!                      +"
		echo_date "+                请尝试更正此问题后重新启动插件！                    +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi

	# 5.2 检测路由器WAN口IPV4地址
	echo_date "检测[公网出口IPV4地址]和[路由器WAN口IPV4地址]..."
	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(nvram get wan0_ipaddr)
		local ROUTER_IP_WAN_SRC="nvram get wan0_ipaddr"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ifconfig ppp0|sed -n '2p'|grep -Eo 'inet addr:([0-9]{1,3}[\.]){3}[0-9]{1,3}'|awk -F":" '{print $2}')
		local ROUTER_IP_WAN_SRC="ipconfig ppp0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ip addr show ppp0|grep -w inet|awk '{print $2}'|awk -F "/" '{print $1}')
		local ROUTER_IP_WAN_SRC="ip addr show ppp0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ifconfig eth0|sed -n '2p'|grep -Eo 'inet addr:([0-9]{1,3}[\.]){3}[0-9]{1,3}'|awk -F":" '{print $2}')
		local ROUTER_IP_WAN_SRC="ipconfig eth0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ip addr show eth0|grep -w inet|awk '{print $2}')|awk -F "/" '{print $1}'
		local ROUTER_IP_WAN_SRC="ip addr show eth0"
	fi
	
	if [ -z "${ROUTER_IP_WAN}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+             经多种方法尝试，均无法检测到本机WAN口IP!                +"
		echo_date "+                请尝试更正此问题后重新启动插件!                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
	
	# 5.3 判断
	local ISCHN_OUT=$(awk -F'[./]' -v ip=${REMOTE_IP_OUT} '{for (i=1;i<=int($NF/8);i++){a=a$i"."} if (index(ip, a)==1){split( ip, A, ".");b=int($NF/8);if (A[b+1]<($(NF+b-4)+2^(8-$NF%8))&&A[b+1]>=$(NF+b-4)) print ip,"belongs to",$0} a=""}' /koolshare/ss/rules/chnroute.txt)
	if [ -n "${ISCHN_OUT}" ];then
		# 大陆地址
		echo_date "公网出口IPV4地址：${REMOTE_IP_OUT}，属地：大陆，来源：${REMOTE_IP_OUT_SRC}"
	else
		# 海外地址
		# 为日志输出标准，此处属地海外表示的是：中国外且包含港澳台地址，后同，并没有任何分裂国家的表达意思。
		echo_date "公网出口IPV4地址：${REMOTE_IP_OUT}，属地：海外，来源：${REMOTE_IP_OUT_SRC}"
	fi

	if [ "${ROUTER_IP_WAN}" == "${REMOTE_IP_OUT}" ];then
		if [ -z "${ISCHN_OUT}" ];then
			echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址相同，为海外公网IPV4地址！"
			if [ "${ss_basic_mode}" != "6" ];then
				echo_date "检测到路由器公网出口IPV4地址为海外地址，可能是以下情况："
				echo_date "-------------------------------"
				echo_date "1. 检测到路由器使用环境在海外，如果确实是这种情况，建议使用回国代理 + 回国模式"
				echo_date "2. 可能你身在大陆，但是chnroute.txt没有收录你的公网出口IPV4地址，你可以自行将该IPV4地址加入到IP/CIDR黑名单"
				echo_date "-------------------------------"
			fi
		else
			echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址相同，为大陆公网IPV4地址！"
		fi
	else
		echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址不同，为私网（局域网）IPV4地址"
		if [ -z "${ISCHN_OUT}" ];then
			if [ "${ss_basic_mode}" != "6" ];then
				echo_date "检测到路由器公网出口IPV4地址为海外地址，可能是以下情况："
				echo_date "-------------------------------"
				echo_date "1. 可能你身在大陆，但是你的网络经过了多层代理，请检查是否有上游路由器开启了代理，特别是全局代理"
				echo_date "2. 可能你身在海外，如果是这种情况，建议使用回国代理 + 回国模式"
				echo_date "3. 可能你身在大陆，但是chnroute.txt没有收录你的公网出口IPV4地址，你可以自行将该IPV4地址加入到IP/CIDR黑名单"
				echo_date "-------------------------------"
			fi
		fi
	fi
}

prepare_system() {
	# prepare system
	echo_date "🛠️ 一些准备工作，请稍后..."
	# Default enabled in UI: block QUIC to avoid HTTP/3 direct-connect bypassing TCP-only proxy.
	set_default "ss_basic_block_quic" "1"
	set_default "ss_basic_proxy_ipv6" "0"
	set_default "ss_basic_server_resolv_mode" "1"
	
	# 0. set skin, 不管是否能启动成功，都检测下皮肤是否正确，如果不对，则设置下皮肤
	set_skin
	
	# 1. 检测是否是路由模式，科学上网插件工作方式为透明代理 + NAT（iptables），而非路由模式是没有NAT的，所以无法工作！
	local ROUTER_MODE=$(nvram get sw_mode)
	if [ "$(nvram get sw_mode)" != "1" ]; then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+          无法启用插件，因为当前路由器工作在非无线路由器模式下          +"
		echo_date "+     科学上网插件工作方式为透明代理，需要在NAT下，即路由模式下才能工作    +"
		echo_date "+            请前往【系统管理】- 【系统设置】去切换路由模式！           +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five
	fi
	
	# 2. 检测jffs2_script是否开启，如果没有开启，将会影响插件的自启和DNS部分（dnsmasq.postconf）
	# 判断为非官改固件的，即merlin固件，需要开启jffs2_scripts，官改固件不需要开启
	if [ -z "$(nvram get extendno | grep koolshare)" ]; then
		if [ "$(nvram get jffs2_scripts)" != "1" ]; then
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+     发现你未开启Enable JFFS custom scripts and configs选项！     +"
			echo_date "+    【软件中心】和【科学上网】插件都需要此项开启才能正常使用！！         +"
			echo_date "+     请前往【系统管理】- 【系统设置】去开启，并重启路由器后重试！！      +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			close_in_five
		fi
	fi

	# 3. use different xtables libdir
	if [ -d "/tmp/.xt" ];then
		export XTABLES_LIBDIR=/tmp/.xt
	fi

	# 兼容，仅chatgpt删除掉了（3.4.13），ss_basic_udpoff和ss_basic_udpall必须有一个等于1
	if [ "${ss_basic_udpoff}" != "1" -a "${ss_basic_udpall}" != "1" ];then
		ss_basic_udpoff=1
		ss_basic_udpall=0
		dbus set ss_basic_udpoff=1
		dbus set ss_basic_udpall=0
	fi
	
	# 检查端口占用情况
	# 3333 3334 23456 7913 1051 1052 1055-1070 2055 2056 1091 1092 1093
	kill_used_port

	# 3. internet detect
	check_internet
	check_ipv6_proxy_prerequisites
	sync_dns_ipv6_policy

	# 4. 检测路由器时间是否正确，只有vmess协议节点需要检测时间正确否
	if [ "${ss_basic_type}" == "3" ];then
		if [ "${ss_basic_v2ray_use_json}" == "0" ];then
			check_time
		elif [ "${ss_basic_v2ray_use_json}" == "1" ];then
			local _ret_vmess=$(echo "$ss_basic_v2ray_json" | base64_decode | grep protocol | grep -Eo "vmess")
			if [ -n "${_ret_vmess}" ];then
				check_time
			fi
		fi
	fi

	if [ "${ss_basic_type}" == "4" ];then
		if [ "${ss_basic_xray_use_json}" == "1" ];then
			local _ret_vmess=$(echo "$ss_basic_xray_json" | base64_decode | grep protocol | grep -Eo "vmess")
			if [ -n "${_ret_vmess}" ];then
				check_time
			fi
		fi
	fi
	
	# 检测路由器公网出口IPV4地址
	if [ "${ss_basic_nochnipcheck}" != "1" ];then
		check_chn_public_ip
	fi
	
	# 6. set_ulimit
	ulimit -n 16384

	# 7. clean mem
	echo 1 >/proc/sys/vm/overcommit_memory

	# 8. more entropy
	# use command `cat /proc/sys/kernel/random/entropy_avail` to check current entropy
	# few scenario should be noticed below:
	# 1. from merlin fw 386.2, jitterentropy-rngd has been intergrated into fw, so haveged form fancyss should not be used
	# 2. from merlin fw 386.4, jitterentropy-rngd was replaced by haveged, so havege form fancyss should not be used
	# 3. newer asus fw or asus_ks_mod fw like GT-AX6000 use jitterentropy-rngd, so havege form fancyss should not be used
	# 4. older merlin or asus_ks_mod fw do not have jitterentropy-rngd or haveged, so havege form fancyss should be used
	if [ -z "$(pidof jitterentropy-rngd)" -a -z "$(pidof haveged)" -a -f "/koolshare/bin/haveged" ];then
		# run haveged form fancyss when there are not entropy software running
		echo_date "启动haveged，为系统提供更多的可用熵！"
		run /koolshare/bin/haveged -w 1024 >/dev/null 2>&1
	fi

	# 9. 用户自定义的dns不需要，新固件这里已经不管用了
	if [ -n "$(nvram get dhcp_dns1_x)" ]; then
		nvram unset dhcp_dns1_x
		nvram commit
	fi
	if [ -n "$(nvram get dhcp_dns2_x)" ]; then
		nvram unset dhcp_dns2_x
		nvram commit
	fi
	# 这些值，如果等1，则重设置为0
	if [ "$(nvram get dns_fwd_local)" == "1" ]; then
		nvram set dns_fwd_local=0
		nvram commit
	fi
	if [ "$(nvram get dns_norebind)" == "1" ]; then
		nvram set dns_norebind=0
		nvram commit
	fi
	if [ "$(nvram get dnssec_enable)" == "1" ]; then
		nvram set dnssec_enable=0
		nvram commit
	fi
	if [ "$(nvram get dnspriv_enable)" == "1" ]; then
		nvram set dnspriv_enable=0
		nvram commit
	fi

	if [ "${ss_basic_type}" == "0" ];then
		echo_date "ℹ️使用Xray-core运行ss协议节点..."
		SS_CONFIG_TEMP="/tmp/xray_tmp.json"
		SS_CONFIG_FILE="/koolshare/ss/xray.json"
	fi

	
	if [ "${ss_basic_type}" == "3" ];then
		echo_date "ℹ️使用Xray-core运行vmess协议节点..."
		VCORE_NAME=Xray
		VMESS_CONFIG_TEMP="/tmp/xray_tmp.json"
		VMESS_CONFIG_FILE="/koolshare/ss/xray.json"
	fi

	if [ "${ss_basic_type}" == "4" ];then
		VLESS_CONFIG_TEMP="/tmp/xray_tmp.json"
		VLESS_CONFIG_FILE="/koolshare/ss/xray.json"
	fi

	# 11. set tcore (trojan core) name
	if [ "${ss_basic_type}" == "5" ];then
		echo_date "ℹ️使用Xray-core运行trojan协议节点..."
		TROJAN_CONFIG_TEMP="/tmp/xray_tmp.json"
		TROJAN_CONFIG_FILE="/koolshare/ss/xray.json"
	fi

	# 11. set hy2 core name
	if [ "${ss_basic_type}" == "8" ];then
		echo_date "ℹ️使用Xray-core运行hysteia2协议节点..."
		HY2_CONFIG_TEMP="/tmp/xray_tmp.json"
		HY2_CONFIG_FILE="/koolshare/ss/xray.json"
	fi

	if [ "${ss_basic_type}" == "6" -a "${ss_basic_mode}" == "3" ];then
		echo_date "NaïveProxy不支持udp代理，因此不支持游戏模式，自动切换为大陆白名单模式！"
		ss_basic_mode="2"
		fss_set_current_node_field_plain mode "2"
	fi

	# 把当前节点名写入文件，下次启动进行对比就知道是否更换了节点
	if [ -f "/tmp/upload/fancyss_node_name.txt" ];then
		last_node_name=$(cat /tmp/upload/fancyss_node_name.txt | sed -n '1p' | base64_decode | tr -d '\r')
		last_node_hash=$(cat /tmp/upload/fancyss_node_name.txt | sed -n '2p')
		last_node_indx=$(cat /tmp/upload/fancyss_node_name.txt | sed -n '3p')
		last_node_index=$(cat /tmp/upload/fancyss_node_name.txt | sed -n '4p')
	else
		last_node_name=""
		last_node_hash=""
		last_node_indx=""
		last_node_index=""
	fi
	curr_node_name=$(printf "%s" "${ss_basic_name}" | tr -d '\r')
	curr_node_hash=$(printf "%s" "${curr_node_name}" | md5sum | awk '{print $1}')
	curr_node_index="${ssconf_basic_node}"

	local _same_node="0"
	if [ -n "${last_node_index}" -a "${last_node_index}" = "${curr_node_index}" ];then
		_same_node="1"
	elif [ "${curr_node_hash}" = "${last_node_hash}" ];then
		_same_node="1"
	elif [ -n "${last_node_name}" -a "${curr_node_name}" = "${last_node_name}" ];then
		_same_node="1"
	fi

	if [ "${_same_node}" = "1" ];then
		if [ "${ss_basic_status}" == "1" ];then
			echo_date "🟠重启节点：【${ss_basic_name}】"
		else
			echo_date "🟠继续使用节点：【${ss_basic_name}】"
		fi
		_node_change_status="0"
	else
		if [ -n "${last_node_name}" ];then
			echo_date "🟠切换节点：【${last_node_name}】 ---→ 【${ss_basic_name}】"
			_node_change_status="1"
		else
			echo_date "🟠启用节点：【${ss_basic_name}】"
			_node_change_status="2"
		fi
	fi
	
	echo "${ss_basic_name}" | base64_encode | sed 's/$/\n/' >/tmp/upload/fancyss_node_name.txt
	echo "${curr_node_hash}" >>/tmp/upload/fancyss_node_name.txt
	echo "${ss_basic_smrt}" >>/tmp/upload/fancyss_node_name.txt
	echo "${curr_node_index}" >>/tmp/upload/fancyss_node_name.txt
}

get_lan_cidr() {
	local netmask=$(nvram get lan_netmask)
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(((${#netmask} - ${#x}) * 2)) ${x%%.*}
	x=${1%%$3*}
	suffix=$(($2 + (${#x} / 4)))
	#prefix=`nvram get lan_ipaddr | cut -d "." -f1,2,3`
	echo $lan_ipaddr/$suffix
}

get_wan0_cidr() {
	local netmask=$(nvram get wan0_netmask)
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(((${#netmask} - ${#x}) * 2)) ${x%%.*}
	x=${1%%$3*}
	suffix=$(($2 + (${#x} / 4)))
	prefix=$(nvram get wan0_ipaddr)
	if [ -n "$prefix" -a -n "$netmask" ]; then
		echo $prefix/$suffix
	else
		echo ""
	fi
}

__get_type_abbr_name() {
	case "${ss_basic_type}" in
	0)
		echo "SS"
		;;
	1)
		echo "SSR"
		;;
	3)
		echo "Vmess"
		;;
	4)
		echo "Vless"
		;;
	5)
		echo "Trojan"
		;;
	6)
		echo "Naïve"
		;;
	7)
		echo "Tuic"
		;;
	8)
		echo "Hysteria2"
		;;
	esac
}

get_tproxy_port4() {
	echo "3333"
}

get_tproxy_port6() {
	echo "3333"
}

normalize_server_resolv_mode() {
	case "${ss_basic_server_resolv_mode}" in
	1|2)
		;;
	*)
		ss_basic_server_resolv_mode="1"
		dbus set ss_basic_server_resolv_mode="1"
		;;
	esac
}

server_resolv_mode_is_dynamic() {
	[ "${ss_basic_server_resolv_mode}" = "1" ]
}

server_resolv_mode_is_preresolve() {
	[ "${ss_basic_server_resolv_mode}" = "2" ]
}

clear_current_node_host_snapshot() {
	rm -f /tmp/ss_host.conf
}

write_current_node_host_snapshot() {
	[ -n "${ss_basic_server_orig}" ] || return 1
	[ -n "${ss_basic_server_ip}" ] || return 1
	echo "address=/${ss_basic_server_orig}/${ss_basic_server_ip}" >/tmp/ss_host.conf
}

clear_current_node_server_ip() {
	unset ss_basic_server_ip
	dbus remove ss_basic_server_ip
	fss_set_current_node_field_plain server_ip ""
}

record_current_node_server_ip() {
	local server_ip="$1"
	[ -n "${server_ip}" ] || {
		clear_current_node_server_ip
		return 1
	}
	ss_basic_server_ip="${server_ip}"
	dbus set ss_basic_server_ip="${server_ip}"
	fss_set_current_node_field_plain server_ip "${server_ip}"
	return 0
}

extract_tuic_server_host_port() {
	local tuic_server_raw="$1"
	local tuic_server=""
	local tuic_port=""

	case "${tuic_server_raw}" in
	\[*\]:*)
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]:*}"
		tuic_port="${tuic_server_raw##*\]:}"
		;;
	\[*\])
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]}"
		;;
	*:* )
		tuic_server="${tuic_server_raw%:*}"
		tuic_port="${tuic_server_raw##*:}"
		;;
	*)
		tuic_server="${tuic_server_raw}"
		;;
	esac

	printf '%s\n%s\n' "${tuic_server}" "${tuic_port}"
}

extract_xray_like_server_field_from_json_text() {
	local json_text="$1"
	local field="$2"

	printf '%s' "${json_text}" | run jq -r --arg field "${field}" '
		(.outbound // (.outbounds[0] // {})) as $ob
		| ($ob.protocol // "") as $protocol
		| if ($protocol == "vmess" or $protocol == "vless") then
			if $field == "host" then
				($ob.settings.vnext[0].address // "")
			else
				(($ob.settings.vnext[0].port // "") | tostring)
			end
		elif ($protocol == "socks" or $protocol == "shadowsocks" or $protocol == "trojan") then
			if $field == "host" then
				($ob.settings.servers[0].address // "")
			else
				(($ob.settings.servers[0].port // "") | tostring)
			end
		else
			""
		end
	' 2>/dev/null
}

resolve_current_node_server_meta() {
	local host="" port="" json_text="" relay_server=""

	case "${ss_basic_type}" in
	0|1|5)
		host="${ss_basic_server}"
		port="${ss_basic_port}"
		;;
	3)
		if [ "${ss_basic_v2ray_use_json}" = "1" ]; then
			json_text="$(printf '%s' "${ss_basic_v2ray_json}" | base64_decode 2>/dev/null)"
			host="$(extract_xray_like_server_field_from_json_text "${json_text}" host)"
			port="$(extract_xray_like_server_field_from_json_text "${json_text}" port)"
		else
			host="${ss_basic_server}"
			port="${ss_basic_port}"
		fi
		;;
	4)
		if [ "${ss_basic_xray_use_json}" = "1" ]; then
			json_text="$(printf '%s' "${ss_basic_xray_json}" | base64_decode 2>/dev/null)"
			host="$(extract_xray_like_server_field_from_json_text "${json_text}" host)"
			port="$(extract_xray_like_server_field_from_json_text "${json_text}" port)"
		else
			host="${ss_basic_server}"
			port="${ss_basic_port}"
		fi
		;;
	6)
		host="${ss_basic_naive_server}"
		port="${ss_basic_naive_port}"
		;;
	7)
		json_text="$(printf '%s' "${ss_basic_tuic_json}" | base64_decode 2>/dev/null)"
		relay_server="$(printf '%s' "${json_text}" | run jq -r '.relay.server // empty' 2>/dev/null)"
		{
			read -r host
			read -r port
		} <<-EOF
		$(extract_tuic_server_host_port "${relay_server}")
		EOF
		;;
	8)
		host="${ss_basic_hy2_server}"
		port="${ss_basic_hy2_port}"
		;;
	*)
		host="${ss_basic_server}"
		port="${ss_basic_port}"
		;;
	esac

	CURRENT_NODE_SERVER_HOST="${host}"
	CURRENT_NODE_SERVER_PORT="${port}"
	__valid_ip46 "${host}" >/dev/null 2>&1
	CURRENT_NODE_SERVER_IS_IP="$?"
}

current_node_server_is_domain_target() {
	resolve_current_node_server_meta
	[ -n "${CURRENT_NODE_SERVER_HOST}" ] || return 1
	[ -n "$(is_domain "${CURRENT_NODE_SERVER_HOST}")" ]
}

current_node_server_uses_runtime_dns() {
	normalize_server_resolv_mode
	server_resolv_mode_is_dynamic || return 1
	current_node_server_is_domain_target || return 1
	return 0
}

refresh_node_direct_domain_file() {
	if server_resolv_mode_is_dynamic; then
		fss_refresh_node_direct_cache
		fss_airport_dns_override_load >/dev/null 2>&1 || true
		if [ "${AIRPORT_DNS_ACTIVE}" = "1" ];then
			fss_refresh_airport_special_runtime_domain_files >/dev/null 2>&1 || true
			if [ -s "${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}" ];then
				cp -f "${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}" "${FSS_NODE_DIRECT_RUNTIME_FILE}"
			else
				rm -f "${FSS_NODE_DIRECT_RUNTIME_FILE}"
			fi
		else
			rm -f "${FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE}" "${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}" "${FSS_NODE_DIRECT_RUNTIME_AIRPORT_DNS_FILE}" >/dev/null 2>&1
			fss_sync_node_direct_runtime
		fi
	else
		rm -f "${FSS_NODE_DIRECT_RUNTIME_FILE}"
		rm -f "${FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE}" "${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}" "${FSS_NODE_DIRECT_RUNTIME_AIRPORT_DNS_FILE}" >/dev/null 2>&1
	fi
}

refresh_node_direct_dns() {
	refresh_node_direct_domain_file || return 1
	server_resolv_mode_is_dynamic || return 0
	[ "${ss_basic_enable}" = "1" ] || return 0
	case "${ss_basic_dns_plan}" in
	1|2)
		;;
	*)
		return 0
		;;
	esac
	stop_dns_process
	restart_dnsmasq
	start_dns_x
}

refresh_current_node_server_ip_runtime() {
	local resolved_ip=""
	local attempt=1
	[ -n "${ss_basic_server_orig}" ] || return 1
	[ -n "$(is_domain "${ss_basic_server_orig}")" ] || return 1
	while [ "${attempt}" -le 3 ]; do
		resolved_ip=$(run dnsclient -46 -p 53 -t 2 -i 1 @127.0.0.1 "${ss_basic_server_orig}" 2>/dev/null | head -n1)
		__valid_ip46 "${resolved_ip}" >/dev/null 2>&1
		if [ "$?" = "0" -o "$?" = "1" ]; then
			break
		fi
		resolved_ip=""
		[ "${attempt}" -lt 3 ] && sleep 1
		attempt=$((attempt + 1))
	done
	[ -n "${resolved_ip}" ] || return 1
	record_current_node_server_ip "${resolved_ip}" || return 1
	echo_date "节点服务器域名运行时解析成功：${ss_basic_server_orig} -> ${resolved_ip}"
	return 0
}

should_bootstrap_dns_before_proxy() {
	server_resolv_mode_is_dynamic || return 1
	[ -n "${ss_basic_server_orig}" ] || return 1
	[ -n "$(is_domain "${ss_basic_server_orig}")" ] || return 1
	return 0
}

rewrite_xray_like_outbound_server() {
	local config_file="$1"
	local target_addr="$2"
	local tmp_file="${config_file}.server"
	local protocol=""

	[ -f "${config_file}" ] || return 1
	[ -n "${target_addr}" ] || return 0

	protocol=$(cat "${config_file}" | run jq -r '.outbounds[0].protocol // empty' 2>/dev/null)
	case "${protocol}" in
	vmess|vless)
		cat "${config_file}" | run jq --arg addr "${target_addr}" '.outbounds[0].settings.vnext[0].address = $addr' > "${tmp_file}" || return 1
		;;
	socks|shadowsocks|trojan)
		cat "${config_file}" | run jq --arg addr "${target_addr}" '.outbounds[0].settings.servers[0].address = $addr' > "${tmp_file}" || return 1
		;;
	*)
		return 0
		;;
	esac

	mv -f "${tmp_file}" "${config_file}"
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
		local user_content=${ss_basic_server_resolv_user}
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
		local user_content=${ss_basic_server_resolv_user}
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

__resolve_server_domain() {
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		# not ip, not domain
		return 2
	fi

	if [ -z "${ss_basic_server_resolv}" ];then
		ss_basic_server_resolv="-1"
		dbus set ss_basic_server_resolv="-1"
	fi

	# start to resolv, udp dns lookup
	if [ "${ss_basic_server_resolv}" -le "0" ];then
		local count=0
		local current=${ss_basic_lastru}
		if [ $(number_test ${current}) != "0" ];then
			# 如果上次解析成功的DNS不存在，则随机一个
			if [ "${ss_basic_server_resolv}" == "0" ];then
				local current=$(shuf -i 1-18 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				local current=$(shuf -i 1-8 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				local current=$(shuf -i 11-18 -n 1)
			fi
		fi
		# check current value
		if [ "${ss_basic_server_resolv}" == "0" ];then
			# 国内 + 国外自动选择，区间为 1-7和11-18
			if [ ${current} -gt 8 -a ${current} -lt 11 ];then
				current=11
			fi
			if [ ${current} -lt 1 -o ${current} -gt 18 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-1" ];then
			# 国内自动选择，区间为 1-7
			if [ ${current} -lt 1 -o ${current} -gt 8 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-2" ];then
			# 国外自动选择，区间为 11-18
			if [ ${current} -lt 11 -o ${current} -gt 18 ];then
				current=11
			fi
		fi
		# 只解析一轮
		until [ ${count} -eq 18 ]; do
			echo_date "尝试解析$(__get_type_abbr_name)服务器域名，自动选取DNS-${current}：$(__get_server_resolver ${current}):$(__get_server_resolver_port ${current})"
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
					echo_date "解析失败！自动切换到国外组列表第一个DNS服务器！"
					current=11
				fi
				if [ ${current} -lt 1 -o ${current} -gt 18 ];then
					current=1
					echo_date "解析失败！自动切换到国内组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到下一个DNS服务器！"
				fi
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				if [ ${current} -lt 1 -o ${current} -gt 8 ];then
					current=1
					echo_date "解析失败！自动切换到国内组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到国内组列表下一个DNS服务器！"
				fi
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				if [ ${current} -lt 11 -o ${current} -gt 18 ];then
					current=11
					echo_date "解析失败！自动切换到国外组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到国外组列表下一个DNS服务器！"
				fi
			fi
			
			let count++
		done
	elif [ "${ss_basic_server_resolv}" == "99" ];then
		# 自定义udp解析服务器
		echo_date "尝试解析$(__get_type_abbr_name)服务器域名，使用自定义DNS服务器：$(__get_server_resolver ${ss_basic_server_resolv}):$(__get_server_resolver_port ${ss_basic_server_resolv})"
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
		if [ -z "${SERVER_IP}" -o "${SERVER_IP}" == "127.0.0.1" ]; then
			echo_date "解析失败！请选择其它DNS服务器 或 其它节点域名解析方案！"
		fi
	else
		# 指定udp解析服务器
		if [ -z "${ss_basic_server_resolv}" ];then
			ss_basic_server_resolv=3
		fi
		if [ "${ss_basic_server_resolv}" == "2" -a -z "${ISP_DNS2}" ];then
			# 如果ISPDNS-2不存在，强制使用ISPDNS-1
			ss_basic_server_resolv=1
		fi
		if [ "${ss_basic_server_resolv}" == "1" -a -z "${ISP_DNS1}" ];then
			# 如果ISPDNS-1不存在，强制使用公共DNS：223.5.5.5
			ss_basic_server_resolv=3
		fi
		echo_date "尝试解析$(__get_type_abbr_name)服务器域名，使用指定DNS-${ss_basic_server_resolv}：$(__get_server_resolver ${ss_basic_server_resolv}):$(__get_server_resolver_port ${ss_basic_server_resolv})"
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
		if [ -z "${SERVER_IP}" -o "${SERVER_IP}" == "127.0.0.1" ]; then
			echo_date "解析失败！请选择其它DNS服务器 或 其它节点域名解析方案！"
		fi
	fi

	# resolve failed
	if [ -z "${SERVER_IP}" ]; then
		return 1
	fi

	# resolve failed
	if [ "${SERVER_IP}" == "127.0.0.1" ]; then
		return 1
	fi
	
	# success resolved
	return 0
}

# ================================= ss stop ===============================

restore_conf() {
	echo_date "删除fancyss相关的名单配置文件..."
	rm -f /jffs/configs/dnsmasq.d/custom.conf
	rm -f /jffs/configs/dnsmasq.d/ss_host.conf
	rm -f /jffs/configs/dnsmasq.d/ss_server.conf
	rm -f /jffs/configs/dnsmasq.d/ss_domain.conf
	rm -f /jffs/scripts/dnsmasq.postconf
	rm -f /jffs/scripts/dnsmasq-sdn.postconf
	rm -f /tmp/custom.conf
	rm -f /tmp/ss_host.conf
	rm -f /tmp/gfwlist.txt
	rm -f /tmp/chnlist.txt
	rm -f /tmp/ss_node_domains.txt
	rm -f /tmp/black_list.txt
	rm -f /tmp/white_list.txt
	rm -f /tmp/block_list.txt

	if [ -z "${WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			return 0
		fi
	else
		rm -f /koolshare/ss/xray.json
		rm -f /koolshare/ss/v2ray.json
		rm -f /koolshare/ss/ssr.json
		rm -f /koolshare/ss/tuic.json
	fi
}

kill_process() {
	local v2ray_process=$(pidof v2ray)
	if [ -n "$v2ray_process" ]; then
		echo_date "关闭V2Ray进程..."
		# 有时候killall杀不了v2ray进程，所以用不同方式杀两次
		killall v2ray >/dev/null 2>&1
		kill -9 "$v2ray_process" >/dev/null 2>&1
	fi

	local xray_process=$(pidof xray)
	if [ -n "$xray_process" ]; then
		echo_date "关闭xray进程..."
		if [ -d "/koolshare/perp/xray" ];then
			perpctl d xray >/dev/null 2>&1
			rm -rf /koolshare/perp/xray >/dev/null 2>&1
		fi
		killall xray >/dev/null 2>&1
		kill -9 "$xray_process" >/dev/null 2>&1
	fi

	local rssredir=$(pidof rss-redir)
	if [ -n "$rssredir" ]; then
		echo_date "关闭ssr-redir进程..."
		killall rss-redir >/dev/null 2>&1
	fi

	local ssrlocal=$(ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}')
	if [ -n "$ssrlocal" ]; then
		echo_date "关闭ssr-local进程:23456端口..."
		kill $ssrlocal >/dev/null 2>&1
	fi

	local sstunnel=$(pidof ss-tunnel)
	if [ -n "$sstunnel" ]; then
		echo_date "关闭进程..."
		killall ss-tunnel >/dev/null 2>&1
	fi

	local CHNG_PID=$(pidof chinadns-ng)
	if [ -n "${CHNG_PID}" ];then
		echo_date "关闭chinadns-ng进程..."
		if [ -d "/koolshare/perp/chinadns-ng" ];then
			perpctl d chinadns-ng >/dev/null 2>&1
			rm -rf /koolshare/perp/chinadns-ng >/dev/null 2>&1
		fi
		killall chinadns-ng >/dev/null 2>&1
		kill -9 ${CHNG_PID} >/dev/null 2>&1
	fi

	local smartdns_process=$(pidof smartdns)
	if [ -n "$smartdns_process" ]; then
		echo_date "关闭smartdns进程..."
		killall smartdns >/dev/null 2>&1
	fi

	# only close haveged form fancyss, not haveged from system
	local haveged_pid=$(ps |grep "/koolshare/bin/haveged"|grep -v grep|awk '{print $1}')
	if [ -n "${haveged_pid}" ]; then
		echo_date "关闭haveged进程..."
		killall -9 ${haveged_pid} >/dev/null 2>&1
	fi

	local SOCAT_PID=$(ps | grep -E "socat" | grep -E "2055|2056" | awk '{print $1}')
	if [ -n "${SOCAT_PID}" ];then
		echo_date "关闭socat进程..."
		kill -9 ${SOCAT_PID}
	fi

	local IPT2SOCKS_PID=$(ps | grep "ipt2socks" | grep -v grep | awk '{print $1}')
	if [ -n "${IPT2SOCKS_PID}" ];then
		echo_date "关闭ipt2socks进程..."
		killall ipt2socks
	fi	

	local NAIVE_PID=$(ps | grep "naive" | grep -v grep | awk '{print $1}')
	if [ -n "${NAIVE_PID}" ];then
		echo_date "关闭naive进程..."
		killall naive
	fi

	local TUIC_PID=$(ps | grep "tuic-client" | grep -v grep | awk '{print $1}')
	if [ -n "${TUIC_PID}" ];then
		echo_date "关闭tuic-client进程..."
		killall tuic-client
	fi

	local OBFSLOCAL_PID=$(ps | grep "obfs-local" | grep -v grep | awk '{print $1}')
	if [ -n "${OBFSLOCAL_PID}" ];then
		echo_date "关闭obfs-local进程..."
		killall obfs-local
	fi
	
	# close tcp_fastopen
	if [ "${LINUX_VER}" != "26" ]; then
		echo 1 >/proc/sys/net/ipv4/tcp_fastopen
	fi
}

shunt_hot_restart_eligible() {
	[ "${ss_basic_status}" = "1" ] || return 1
	[ "${ss_basic_mode}" = "7" ] || return 1
	[ "${ss_basic_shunt_hot_reload}" = "1" ] || return 1
	[ -x "/koolshare/scripts/ss_shunt_hot_reload.sh" ] || return 1
	[ -s "/koolshare/ss/xray.json" ] || return 1
	pidof xray >/dev/null 2>&1 || return 1
	return 0
}

shunt_configs_equivalent() {
	local old_file="$1"
	local new_file="$2"
	local jq_bin=""
	local old_norm=""
	local new_norm=""

	[ -s "${old_file}" ] || return 1
	[ -s "${new_file}" ] || return 1
	if type fss_pick_jq_bin >/dev/null 2>&1; then
		jq_bin="$(fss_pick_jq_bin 2>/dev/null)"
	fi
	[ -n "${jq_bin}" ] || jq_bin="$(command -v jq 2>/dev/null)"
	if [ -n "${jq_bin}" ]; then
		old_norm="${old_file}.norm.$$"
		new_norm="${new_file}.norm.$$"
		"${jq_bin}" -S . "${old_file}" > "${old_norm}" 2>/dev/null || {
			rm -f "${old_norm}" "${new_norm}" >/dev/null 2>&1
			return 1
		}
		"${jq_bin}" -S . "${new_file}" > "${new_norm}" 2>/dev/null || {
			rm -f "${old_norm}" "${new_norm}" >/dev/null 2>&1
			return 1
		}
		cmp -s "${old_norm}" "${new_norm}"
		local ret=$?
		rm -f "${old_norm}" "${new_norm}" >/dev/null 2>&1
		return "${ret}"
	fi
	cmp -s "${old_file}" "${new_file}"
}
# ================================= ss start ==============================

init_current_node_server_state() {
	normalize_server_resolv_mode
	clear_current_node_host_snapshot
	clear_current_node_server_ip
	resolve_current_node_server_meta
	fss_airport_dns_override_load

	ss_basic_server_orig="${CURRENT_NODE_SERVER_HOST}"
	ss_basic_server="${CURRENT_NODE_SERVER_HOST}"

	if [ -n "${CURRENT_NODE_SERVER_HOST}" ]; then
		case "${ss_basic_type}_${ss_basic_v2ray_use_json}_${ss_basic_xray_use_json}" in
		3_1_*|4_*_1)
			fss_set_current_node_field_plain server "${CURRENT_NODE_SERVER_HOST}"
			;;
		esac
	fi

	case "${CURRENT_NODE_SERVER_IS_IP}" in
	0|1)
		record_current_node_server_ip "${CURRENT_NODE_SERVER_HOST}"
		;;
	esac

	return 0
}

resolv_server_ip() {
	init_current_node_server_state
	refresh_node_direct_domain_file

	if [ -z "${ss_basic_server_orig}" ]; then
		return 1
	fi

	case "${CURRENT_NODE_SERVER_IS_IP}" in
	0|1)
		echo_date "检测到你的$(__get_type_abbr_name)服务器已经是IP格式：${ss_basic_server_orig}，跳过解析... "
		return 0
		;;
	esac

	echo_date "检测到你的$(__get_type_abbr_name)服务器：【${ss_basic_server_orig}】不是ip格式！"
	if server_resolv_mode_is_dynamic; then
		echo_date "当前使用【动态解析】模式，保留域名写入配置，并交由DNS方案中的直连上游解析。"
		return 0
	fi

	__resolve_server_domain "${ss_basic_server_orig}"
	case $? in
	0)
		echo_date "$(__get_type_abbr_name)服务器【${ss_basic_server_orig}】的ip地址解析成功：${SERVER_IP}"
		ss_basic_server="${SERVER_IP}"
		record_current_node_server_ip "${SERVER_IP}"
		write_current_node_host_snapshot >/dev/null 2>&1
		;;
	1)
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "$(__get_type_abbr_name)服务器的ip地址解析失败，预解析模式将回退为写入原始域名继续运行！"
		echo_date "请尝试在【DNS设定】-【预解析所用DNS方案】处更换节点服务器的解析方案后重试！"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		clear_current_node_server_ip
		ss_basic_server="${ss_basic_server_orig}"
		;;
	2)
		echo_date "错误2！！检测到你设置的服务器:${ss_basic_server_orig}既不是ip地址，也不是域名格式！"
		echo_date "请更正你的错误然后重试！！"
		close_in_five flag
		;;
	esac
}

# create shadowsocks config file...
creat_ssr_json() {
	if [ -z "${WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建$(__get_type_abbr_name)配置文件到${CONFIG_FILE}"
	fi

	cat >${CONFIG_FILE} <<-EOF
		{
		    "server":"${ss_basic_server}",
		    "server_port":${ss_basic_port},
		    "local_address":"$(if ipv6_proxy_enabled; then echo '::'; else echo '0.0.0.0'; fi)",
		    "local_port":3333,
		    "password":"${ss_basic_password}",
		    "timeout":600,
		    "protocol":"$ss_basic_rss_protocol",
		    "protocol_param":"$ss_basic_rss_protocol_param",
		    "obfs":"$ss_basic_rss_obfs",
		    "obfs_param":"$ss_basic_rss_obfs_param",
		    "method":"$ss_basic_method"
		}
	EOF
}

get_proxy_server_ip(){
	# 获取代理服务器ip地址
	# 在代理程序启动前获取，不一定是真实的代理服务器ip，比如中转节点
	if [ -n "${ss_real_server_ip}" ]; then
		return
	fi

	if [ -n "${ss_basic_server_ip}" ]; then
		__valid_ip46 "${ss_basic_server_ip}"
		if [ "$?" == "0" ]; then
			# ipv4
			ipset test chnroute ${ss_basic_server_ip} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# ss服务器是国外IP
				ss_real_server_ip="${ss_basic_server_ip}"
				echo_date "检测到节点服务器的ip地址为：${ss_basic_server_ip}，是国外IP"
			else
				# ss服务器是国内ip （可能用了国内中转）
				ss_real_server_ip=""
				echo_date "检测到代理服务器的ip地址为：${ss_basic_server_ip}，是国内IP，可能是国内中转节点！"
			fi
		elif [ "$?" == "1" ]; then
			# ipv6
			ipset test chnroute6 ${ss_basic_server_ip} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# ss服务器是国外IP
				ss_real_server_ip="${ss_basic_server_ip}"
				echo_date "检测到节点服务器的ip地址为：${ss_basic_server_ip}，是国外IP"
			else
				# ss服务器是国内ip （可能用了国内中转）
				ss_real_server_ip=""
				echo_date "检测到代理服务器的ip地址为：${ss_basic_server_ip}，是国内IP，可能是国内中转节点！"
			fi
		else
			# 不是ip
			ss_real_server_ip=""
		fi
	else
		# ss服务器可能是域名且没有正确解析
		ss_real_server_ip=""
	fi
}

start_ssr_local() {
	if [ -n "$(ps|grep rss-local|grep 23456)" ];then
		return
	fi

	echo_date "开启ssr-local，提供socks5代理端口：23456"
	run_bg rss-local -b 127.0.0.1 -l 23456 -c ${CONFIG_FILE} -u -f /var/run/ssrlocal.pid
	detect_running_status rss-local "/var/run/ssrlocal.pid"
}

dbus_dset(){
	# set key when value exist, delete when empty
	if [ -n "$2" ];then
		dbus set $1=$2
	else
		dbus remove $1
	fi
}

dbus_eset(){
	# set key when value exist
	if [ -n "$2" ];then
		dbus set $1=$2
	fi
}

start_dns_x(){
	set_default "ss_basic_dns_plan" "1"
	set_default "ss_basic_dns_serverx" "0"
	local runtime_mode="$(get_runtime_proxy_mode)"
	local dns_plan_runtime="${ss_basic_dns_plan}"
	local special_smartdns_label=""
	if [ "${AIRPORT_DNS_CURRENT_MATCHED}" = "1" ] && [ "${AIRPORT_DNS_PREFERRED_PLAN}" = "smartdns" ];then
		[ "${ss_basic_dns_plan}" != "2" ] && echo_date "ℹ️检测到机场【${AIRPORT_DNS_AIRPORT_LABEL:-${AIRPORT_DNS_AIRPORT_IDENTITY}}】需要专属节点DNS，本次临时切换为smartdns方案。"
		dns_plan_runtime="2"
	else
		special_smartdns_label="$(fss_airport_special_active_label_by_plan "smartdns" 2>/dev/null)"
		if [ -n "${special_smartdns_label}" ];then
			[ "${ss_basic_dns_plan}" != "2" ] && echo_date "ℹ️检测到机场【${special_smartdns_label}】需要使用smartdns，为保证使用节点和测速正常，将强制使用smartdns。"
			dns_plan_runtime="2"
		fi
	fi
	if [ "${ss_basic_type}" = "6" ];then
		local trust_udp_fallback=""
		local n=""
		for n in 1 2 3
		do
			if [ "$(eval echo \$ss_basic_chng_trust_dns_${n}_chk)" = "1" ] && [ "$(get_dns_selected_net trust "${n}")" = "udp" ];then
				trust_udp_fallback="1"
			fi
		done
		if [ -n "${trust_udp_fallback}" ];then
			echo_date "⚠️检测到 NaïveProxy 不支持 UDP 代理，chinadns-ng 的可信 UDP DNS 将在运行时按 TCP 上游处理。"
		fi
		if [ -n "$(smartdns_iter_gfw_udp_relays 2>/dev/null | sed -n '1p')" ];then
			echo_date "⚠️检测到 NaïveProxy 不支持 UDP 代理，smartdns gfw 组中的 UDP DNS 将在运行时按 TCP 上游处理。"
		fi
	fi
	if [ "${dns_plan_runtime}" == "1" ];then
		# DNS分流模式和iptables分流需要匹配，不然效果不好，这里需要检测用户当前代理模式和当前DNS模式
		if [ "${runtime_mode}" == "1" ];then
			if [ "${ss_basic_chng}" == "2" ];then
				echo_date "⚠️警告：当前代理模式GFW黑名单与当前DNS模式：[国外优先]不匹配！"
				echo_date "🔁建议使用：[国内优先/智能判断]，本次自动将当前DNS模式改为：[国内优先]！"
				ss_basic_chng="1"
				dbus set ss_basic_chng="1"
			fi
		elif [ "${runtime_mode}" == "2" -o "${runtime_mode}" == "3" ];then
			if [ "${ss_basic_chng}" == "1" ];then
				echo_date "⚠️警告：当前代理模式与当前DNS模式：[国内优先]不匹配！"
				echo_date "🔁建议使用：[国外优先/智能判断]，本次自动将当前DNS模式改为：[国外优先]！"
				ss_basic_chng="2"
				dbus set ss_basic_chng="2"
			fi
		fi
	
		start_chinadns_ng
	elif [ "${dns_plan_runtime}" == "2" ];then
		# DNS分流模式和iptables分流需要匹配，不然效果不好，这里需要检测用户当前代理模式和当前DNS模式
		if [ "${runtime_mode}" == "1" ];then
			if [ "${ss_basic_smrt}" == "2" ];then
				echo_date "⚠️警告：当前代理模式GFW黑名单与当前DNS模式：[国外优先]不匹配！"
				echo_date "🔁建议使用：[国内优先/智能判断]，本次自动将当前DNS模式改为：[国内优先]！"
				ss_basic_smrt="1"
				dbus set ss_basic_smrt="1"
			fi
		elif [ "${runtime_mode}" == "2" -o "${runtime_mode}" == "3" ];then
			if [ "${ss_basic_smrt}" == "1" ];then
				echo_date "⚠️警告：当前代理模式与当前DNS模式：[国内优先]不匹配！"
				echo_date "🔁建议使用：[国外优先/智能判断]，本次自动将当前DNS模式改为：[国外优先]！"
				ss_basic_smrt="2"
				dbus set ss_basic_smrt="2"
			fi
		fi
	
		echo_date "start smartdns"
		start_smartdns ${ss_basic_smrt}
	fi
}

smartdns_format_addr() {
	local addr="$1"
	local port="$2"
	if [ -z "${port}" ] || [ "${port}" = "53" ];then
		echo "${addr}"
		return
	fi
	case "${addr}" in
	*:* )
		echo "[${addr}]:${port}"
		;;
	*)
		echo "${addr}:${port}"
		;;
	esac
}

smartdns_server_flags() {
	local mode="$1"
	local scope="$2"
	case "${mode}_${scope}" in
	1_chn_group)
		echo "-group chn -blacklist-ip"
		;;
	1_gfw_group)
		echo "-group gfw -exclude-default-group"
		;;
	2_chn_group)
		echo "-group chn -blacklist-ip -exclude-default-group"
		;;
	2_gfw_group)
		echo "-group gfw"
		;;
	3_chn_group)
		echo "-group chn -blacklist-ip -exclude-default-group"
		;;
	3_gfw_group)
		echo "-group gfw -blacklist-ip -exclude-default-group"
		;;
	3_chn_default)
		echo "-whitelist-ip -blacklist-ip"
		;;
	3_gfw_default)
		echo "-blacklist-ip"
		;;
	esac
}

smartdns_append_server_line() {
	local outfile="$1"
	local proto="$2"
	local addr="$3"
	local port="$4"
	local host="$5"
	local host_ip="$6"
	local flags="$7"
	local use_proxy="$8"
	local line=""
	local extras="${flags}"
	if [ "${use_proxy}" = "1" ];then
		extras="${extras} -proxy fancy_proxy"
	fi
	case "${proto}" in
	udp)
		line="server $(smartdns_format_addr "${addr}" "${port}")"
		;;
	tcp)
		line="server-tcp $(smartdns_format_addr "${addr}" "${port}")"
		;;
	dot)
		line="server-tls ${host}"
		;;
	*)
		return 0
		;;
	esac
	[ -n "${extras}" ] && line="${line} ${extras}"
	if [ "${proto}" = "dot" ];then
		line="${line} -host-ip ${host_ip}"
		if [ -n "${port}" ] && [ "${port}" != "853" ];then
			line="${line} -port ${port}"
		fi
	fi
	echo "${line}" >> "${outfile}"
}

smartdns_append_group_servers() {
	local outfile="$1"
	local mode="$2"
	local group="$3"
	local scope="$4"
	local relay_idx=0
	local flags="$(smartdns_server_flags "${mode}" "${scope}")"
	local use_proxy="0"
	local sep="$(printf '\037')"
	[ "${group}" = "gfw" ] && use_proxy="1"
	while IFS="${sep}" read -r id proto provider description kind slot addr port host host_ip isp net
	do
		if [ "${group}" = "gfw" ] && [ "${ss_basic_type}" = "6" ] && [ "${proto}" = "udp" ];then
			proto="tcp"
		fi
		local target_addr="${addr}"
		local target_port="${port}"
		local target_proxy="${use_proxy}"
		if [ "${group}" = "gfw" ] && [ "${proto}" = "udp" ];then
			relay_idx=$((relay_idx + 1))
			target_addr="127.0.0.1"
			target_port=$((SMARTDNS_RELAY_PORT_BASE + relay_idx - 1))
			target_proxy="0"
		fi
		smartdns_append_server_line "${outfile}" "${proto}" "${target_addr}" "${target_port}" "${host}" "${host_ip}" "${flags}" "${target_proxy}"
	done <<-EOF
$(smartdns_group_items_tsv "${group}")
EOF
}

smartdns_append_node_direct_servers() {
	local outfile="$1"
	local sep="$(printf '\037')"
	while IFS="${sep}" read -r id proto provider description kind slot addr port host host_ip isp net
	do
		smartdns_append_server_line "${outfile}" "${proto}" "${addr}" "${port}" "${host}" "${host_ip}" "-group node_direct -exclude-default-group" "0"
	done <<-EOF
$(smartdns_group_items_tsv chn)
EOF
}

smartdns_airport_group_name() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	printf 'airport_%s\n' "${airport_identity}"
}

smartdns_airport_dns_group_name() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	printf 'airport_dns_%s\n' "${airport_identity}"
}

smartdns_append_airport_node_servers_by_identity() {
	local outfile="$1"
	local airport_identity="$2"
	local sep="$(printf '\037')"
	local proto raw addr port host host_ip
	local group_name=""
	[ -n "${airport_identity}" ] || return 0
	group_name="$(smartdns_airport_group_name "${airport_identity}" 2>/dev/null)" || return 0
	fss_airport_runtime_iter_dns_items_tsv_by_identity "${airport_identity}" 2>/dev/null | while IFS="${sep}" read -r proto raw addr port host host_ip
	do
		[ -n "${proto}" ] || continue
		case "${proto}" in
		udp)
			[ -n "${addr}" ] || continue
			[ -n "${port}" ] || port="53"
			echo "server $(smartdns_format_addr "${addr}" "${port}") -group ${group_name} -exclude-default-group" >> "${outfile}"
			;;
		tcp)
			[ -n "${addr}" ] || continue
			[ -n "${port}" ] || port="53"
			echo "server-tcp $(smartdns_format_addr "${addr}" "${port}") -group ${group_name} -exclude-default-group" >> "${outfile}"
			;;
		tls)
			[ -n "${raw}" ] || continue
			echo "server-tls ${raw#tls://} -group ${group_name} -exclude-default-group" >> "${outfile}"
			;;
		https)
			[ -n "${raw}" ] || continue
			echo "server-https ${raw} -group ${group_name} -exclude-default-group" >> "${outfile}"
			;;
		quic)
			[ -n "${raw}" ] || continue
			echo "server-quic ${raw} -group ${group_name} -exclude-default-group" >> "${outfile}"
			;;
		esac
	done
}

smartdns_append_ipv6_policy() {
	local outfile="$1"
	local mode="$2"
	local has_node_direct="0"
	local airport_identity=""
	local airport_dns_group=""
	local airport_dns_file=""
	[ -s /tmp/ss_node_domains.txt ] && has_node_direct="1"
	smartdns_append_airport_dns_ipv6_lines() {
		while IFS="$(printf '\037')" read -r airport_identity _airport_label _airport_plan
		do
			[ -n "${airport_identity}" ] || continue
			airport_dns_group="$(smartdns_airport_dns_group_name "${airport_identity}" 2>/dev/null)" || continue
			airport_dns_file="$(fss_airport_special_runtime_dns_file "${airport_identity}" 2>/dev/null)" || continue
			[ -s "${airport_dns_file}" ] && echo "address /domain-set:${airport_dns_group}/-6" >> "${outfile}"
		done <<-EOF
$(fss_airport_special_iter_active_tsv 2>/dev/null)
		EOF
	}
	if [ "${ss_basic_proxy_ipv6}" = "1" ];then
		cat >> "${outfile}" <<-'EOF'
force-AAAA-SOA no
EOF
		if [ "${has_node_direct}" = "1" ];then
			echo "address /domain-set:node_direct/-6" >> "${outfile}"
		fi
		smartdns_append_airport_dns_ipv6_lines
		return
	fi
	case "${mode}" in
	1)
		cat >> "${outfile}" <<-'EOF'
force-AAAA-SOA no
address /domain-set:gfwlist/#6
address /domain-set:black_list/#6
address /domain-set:rotlist/#6
EOF
		if [ "${has_node_direct}" = "1" ];then
			echo "address /domain-set:node_direct/-6" >> "${outfile}"
		fi
		smartdns_append_airport_dns_ipv6_lines
		;;
	2|3)
		cat >> "${outfile}" <<-'EOF'
force-AAAA-SOA yes
address /domain-set:chnlist/-6
address /domain-set:white_list/-6
EOF
		if [ "${has_node_direct}" = "1" ];then
			echo "address /domain-set:node_direct/-6" >> "${outfile}"
		fi
		smartdns_append_airport_dns_ipv6_lines
		;;
	5)
		cat >> "${outfile}" <<-'EOF'
force-AAAA-SOA yes
address /domain-set:white_list/-6
EOF
		if [ "${has_node_direct}" = "1" ];then
			echo "address /domain-set:node_direct/-6" >> "${outfile}"
		fi
		smartdns_append_airport_dns_ipv6_lines
		;;
	*)
		cat >> "${outfile}" <<-'EOF'
force-AAAA-SOA no
EOF
		if [ "${has_node_direct}" = "1" ];then
			echo "address /domain-set:node_direct/-6" >> "${outfile}"
		fi
		smartdns_append_airport_dns_ipv6_lines
		;;
	esac
}

smartdns_generate_runtime_conf() {
	local outfile="$1"
	local mode="$2"
	local listen_port="7913"
	local airport_identity=""
	local airport_label=""
	local airport_plan=""
	local airport_group=""
	local airport_dns_group=""
	local airport_domain_file=""
	local airport_dns_file=""
	[ "${ss_basic_dns_serverx}" = "1" ] && listen_port="53"
	: > "${outfile}"
	[ "${mode}" = "3" ] && generate_smartdns_whitelist_file /tmp/whitelist_ip.txt
	cat > "${outfile}" <<-EOF
# Auto-generated by fancyss.
bind [::]:${listen_port}

domain-set -name chnlist -file /tmp/chnlist.txt
domain-set -name gfwlist -file /tmp/gfwlist.txt
domain-set -name rotlist -file /koolshare/ss/rules/rotlist.txt
domain-set -name white_list -file /tmp/white_list.txt
domain-set -name black_list -file /tmp/black_list.txt
EOF
	while IFS="$(printf '\037')" read -r airport_identity airport_label airport_plan
	do
		[ -n "${airport_identity}" ] || continue
		airport_group="$(smartdns_airport_group_name "${airport_identity}" 2>/dev/null)" || continue
		airport_dns_group="$(smartdns_airport_dns_group_name "${airport_identity}" 2>/dev/null)" || continue
		airport_domain_file="$(fss_airport_special_runtime_domain_file "${airport_identity}" 2>/dev/null)" || continue
		airport_dns_file="$(fss_airport_special_runtime_dns_file "${airport_identity}" 2>/dev/null)" || continue
		[ -s "${airport_dns_file}" ] && echo "domain-set -name ${airport_dns_group} -file ${airport_dns_file}" >> "${outfile}"
		[ -s "${airport_domain_file}" ] && echo "domain-set -name ${airport_group} -file ${airport_domain_file}" >> "${outfile}"
	done <<-EOF
$(fss_airport_special_iter_active_tsv 2>/dev/null)
	EOF
	[ -s /tmp/ss_node_domains.txt ] && echo "domain-set -name node_direct -file /tmp/ss_node_domains.txt" >> "${outfile}"
	[ "${ss_basic_block_resov}" = "1" ] && echo "domain-set -name block_list -file /tmp/block_list.txt" >> "${outfile}"

	local shunt_proxy_file=""
	if [ "$(get_runtime_proxy_mode)" = "7" ] && type fss_shunt_get_proxy_domain_file >/dev/null 2>&1; then
		shunt_proxy_file="$(fss_shunt_get_proxy_domain_file 2>/dev/null)"
		[ -n "${shunt_proxy_file}" ] && [ -s "${shunt_proxy_file}" ] && echo "domain-set -name shunt_proxy -file ${shunt_proxy_file}" >> "${outfile}"
	fi

	[ "${mode}" = "3" ] && echo "conf-file /tmp/whitelist_ip.txt" >> "${outfile}"
	cat >> "${outfile}" <<-'EOF'

EOF
	while IFS="$(printf '\037')" read -r airport_identity airport_label airport_plan
	do
		[ -n "${airport_identity}" ] || continue
		airport_group="$(smartdns_airport_group_name "${airport_identity}" 2>/dev/null)" || continue
		airport_dns_group="$(smartdns_airport_dns_group_name "${airport_identity}" 2>/dev/null)" || continue
		airport_domain_file="$(fss_airport_special_runtime_domain_file "${airport_identity}" 2>/dev/null)" || continue
		airport_dns_file="$(fss_airport_special_runtime_dns_file "${airport_identity}" 2>/dev/null)" || continue
		[ -s "${airport_dns_file}" ] && echo "domain-rules /domain-set:${airport_dns_group}/ -p #4:chnlist,#6:chnlist6 -c ping,tcp:80,tcp:443 -r first-ping -d yes -n chn" >> "${outfile}"
		[ -s "${airport_domain_file}" ] && echo "domain-rules /domain-set:${airport_group}/ -c none -n ${airport_group}" >> "${outfile}"
	done <<-EOF
$(fss_airport_special_iter_active_tsv 2>/dev/null)
	EOF
	[ -s /tmp/ss_node_domains.txt ] && echo "domain-rules /domain-set:node_direct/ -p #4:chnlist,#6:chnlist6 -c ping,tcp:80,tcp:443 -r first-ping -d yes -n chn" >> "${outfile}"
	cat >> "${outfile}" <<-'EOF'

domain-rules /domain-set:chnlist/ -p #4:chnlist,#6:chnlist6 -c ping,tcp:80,tcp:443 -r first-ping -d yes -n chn
domain-rules /domain-set:white_list/ -p #4:white_list,#6:white_list6 -c ping,tcp:80,tcp:443 -r first-ping -d yes -n chn
EOF
	if [ "$(get_runtime_proxy_mode)" = "7" ] && [ -n "${shunt_proxy_file}" ] && [ -s "${shunt_proxy_file}" ]; then
		echo "domain-rules /domain-set:shunt_proxy/ -p #4:gfwlist,#6:gfwlist6 -c none -n gfw" >> "${outfile}"
	fi
	cat >> "${outfile}" <<-'EOF'
domain-rules /domain-set:gfwlist/ -p #4:gfwlist,#6:gfwlist6 -c none -n gfw
domain-rules /domain-set:black_list/ -p #4:black_list,#6:black_list6 -c none -n gfw
domain-rules /domain-set:rotlist/ -p #4:router,#6:router6 -c none -n gfw
EOF
	[ "${ss_basic_block_resov}" = "1" ] && echo "domain-rules /domain-set:block_list/ -a #" >> "${outfile}"
	case "${mode}" in
	1)
		cat >> "${outfile}" <<-'EOF'
speed-check-mode ping,tcp:80,tcp:443
response-mode first-ping
dualstack-ip-selection yes
dualstack-ip-selection-threshold 10
EOF
		;;
	2)
		cat >> "${outfile}" <<-'EOF'
speed-check-mode none
EOF
		;;
	3)
		cat >> "${outfile}" <<-'EOF'
speed-check-mode ping,tcp:80,tcp:443
response-mode fastest-ip
dualstack-ip-selection yes
dualstack-ip-selection-threshold 10
EOF
		;;
	esac
	cat >> "${outfile}" <<-EOF
cache-persist yes
cache-file /tmp/smartdns_${mode}.cache
prefetch-domain yes
EOF
	if [ "${mode}" = "3" ];then
		echo "serve-expired no" >> "${outfile}"
	else
		echo "serve-expired yes" >> "${outfile}"
	fi
	cat >> "${outfile}" <<-'EOF'
serve-expired-ttl 259200
serve-expired-reply-ttl 3
cache-checkpoint-time 86400
EOF
	smartdns_append_ipv6_policy "${outfile}" "${mode}"
	cat >> "${outfile}" <<-'EOF'
force-qtype-SOA 65
log-level info
log-file /tmp/smartdns_log.txt
log-size 2M
log-num 1
audit-enable yes
audit-file /tmp/smartdns_audit.txt
audit-size 2M
audit-num 1
ca-file /etc/ssl/certs/ca-certificates.crt
blacklist-ip 10.0.0.0/8
proxy-server socks5://127.0.0.1:23456 -name fancy_proxy
EOF
	while IFS="$(printf '\037')" read -r airport_identity airport_label airport_plan
	do
		[ -n "${airport_identity}" ] || continue
		airport_domain_file="$(fss_airport_special_runtime_domain_file "${airport_identity}" 2>/dev/null)" || continue
		[ -s "${airport_domain_file}" ] || continue
		echo "" >> "${outfile}"
		echo "# airport special upstreams: ${airport_label:-${airport_identity}}" >> "${outfile}"
		smartdns_append_airport_node_servers_by_identity "${outfile}" "${airport_identity}"
	done <<-EOF
$(fss_airport_special_iter_active_tsv 2>/dev/null)
	EOF
	echo "" >> "${outfile}"
	echo "# chn group upstreams" >> "${outfile}"
	smartdns_append_group_servers "${outfile}" "${mode}" "chn" "chn_group"
	echo "" >> "${outfile}"
	echo "# gfw group upstreams" >> "${outfile}"
	smartdns_append_group_servers "${outfile}" "${mode}" "gfw" "gfw_group"
	if [ "${mode}" = "3" ];then
		echo "" >> "${outfile}"
		echo "# default group upstreams" >> "${outfile}"
		smartdns_append_group_servers "${outfile}" "${mode}" "chn" "chn_default"
		smartdns_append_group_servers "${outfile}" "${mode}" "gfw" "gfw_default"
	fi
}

start_smartdns(){
	local idx=$1
	local smartdns_conf=/tmp/smartdns_fancyss.conf

	rm -rf /tmp/smartdns_log.txt
	rm -rf /tmp/smartdns_audit.txt

	if [ "${_node_change_status}" == "1" ];then
		if [ -f "/tmp/smartdns_${last_node_indx}.cache" ];then
			echo_date "smartdns缓存：检测到上次节点【${last_node_name}】上次使用的缓存，备份以备下次切换回使用。"
			mv /tmp/smartdns_${last_node_indx}.cache /tmp/smartdns_${last_node_indx}_${last_node_hash}.cache
		fi
		if [ -f "/tmp/smartdns_${idx}_${curr_node_hash}.cache" ];then
			echo_date "smartdns缓存：检测到节点【${ss_basic_name}】上次使用的缓存，加载到/tmp/smartdns_${idx}.cache..."
			mv /tmp/smartdns_${idx}_${curr_node_hash}.cache /tmp/smartdns_${idx}.cache
		else
			echo_date "smartdns缓存：没有检测到节点【${ss_basic_name}】上次使用的缓存"
		fi
	elif [ "${_node_change_status}" == "0" ];then
		if [ -f "/tmp/smartdns_${last_node_indx}.cache" ];then
			echo_date "smartdns缓存：检测到节点未切换，保留smartdns缓存文件..."
		else
			echo_date "smartdns缓存：检测到节点未切换，新建smartdns缓存文件..."
		fi
	elif [ "${_node_change_status}" == "2" ];then
		if [ -f "/tmp/smartdns_${idx}_${curr_node_hash}.cache" ];then
			echo_date "smartdns缓存：检测到节点【${ss_basic_name}】上次使用的缓存，加载到/tmp/smartdns_${idx}.cache...."
			mv /tmp/smartdns_${idx}_${curr_node_hash}.cache /tmp/smartdns_${idx}.cache
		else
			echo_date "smartdns缓存：没有检测到节点【${ss_basic_name}】上次使用的缓存!"
		fi
	fi

	echo_date "生成smartdns运行时配置：${smartdns_conf}"
	smartdns_generate_runtime_conf "${smartdns_conf}" "${idx}"

	echo_date "启动smartdns，使用smartdns配置文件：${smartdns_conf}"
	run_bg smartdns -c ${smartdns_conf}
	detect_running_status3 "smartdns" "53|7913" "0"

	local caches=$(head /tmp/smartdns_log.txt 2>/dev/null | grep "load cache file" | awk '{print $(NF-1)}')
	if [ -n "${caches}" ];then
		echo_date "smartdns启动成功，成功加载缓存：${caches}条"
	else
		echo_date "smartdns启动成功!"
	fi
}

start_chinadns_ng(){
	# 0. set default var
	local CDNS_LINE=""
	local FDNS_LINE=""
	local CHINA_DNS_1=""
	local CHINA_DNS_2=""
	local CHINA_DNS_3=""
	local TRUST_DNS_1=""
	local TRUST_DNS_2=""
	local TRUST_DNS_3=""
	local DNS_REPEATS=""
	local ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")

	# 1. set default value incase of ssconfig.sh restart after upgrade form old verison below 3.3.8
	set_default "ss_basic_chng" "3"
	set_default "ss_basic_smrt" "3"
	
	set_default "ss_basic_chng_china_dns_1_chk" "1"
	set_default "ss_basic_chng_china_dns_2_chk" "1"
	set_default "ss_basic_chng_china_dns_3_chk" "1"
	set_default "ss_basic_chng_china_net_1_typ" "udp"
	set_default "ss_basic_chng_china_net_2_typ" "tcp"
	set_default "ss_basic_chng_china_net_3_typ" "dot"

	if [ -n "${ISP_DNS1}" ]; then
		set_default "ss_basic_chng_china_udp_1_opt" "${ISP_DNS1}"
	else
		set_default "ss_basic_chng_china_udp_1_opt" "223.5.5.5"
	fi
	set_default "ss_basic_chng_china_udp_1_usr" "114.114.114.114"
	set_default "ss_basic_chng_china_udp_2_opt" "223.5.5.5"
	set_default "ss_basic_chng_china_udp_2_usr" "114.114.115.115"
	set_default "ss_basic_chng_china_udp_3_opt" "223.5.5.5"
	set_default "ss_basic_chng_china_udp_3_usr" "114.114.115.115"
	
	set_default "ss_basic_chng_china_tcp_1_opt" "119.28.28.28"
	set_default "ss_basic_chng_china_tcp_1_usr" "114.114.114.114"
	set_default "ss_basic_chng_china_tcp_2_opt" "119.28.28.28"
	set_default "ss_basic_chng_china_tcp_2_usr" "114.114.115.115"
	set_default "ss_basic_chng_china_tcp_3_opt" "119.28.28.28"
	set_default "ss_basic_chng_china_tcp_3_usr" "114.114.115.115"

	set_default "ss_basic_chng_china_dot_1_opt" "dns.alidns.com@223.5.5.5"
	set_default "ss_basic_chng_china_dot_1_usr" "114.114.114.114"
	set_default "ss_basic_chng_china_dot_2_opt" "dns.alidns.com@223.5.5.5"
	set_default "ss_basic_chng_china_dot_2_usr" "114.114.115.115"
	set_default "ss_basic_chng_china_dot_3_opt" "dns.alidns.com@223.5.5.5"
	set_default "ss_basic_chng_china_dot_3_usr" "114.114.115.115"
	
	set_default "ss_basic_chng_trust_dns_1_chk" "1"
	set_default "ss_basic_chng_trust_dns_2_chk" "1"
	set_default "ss_basic_chng_trust_dns_3_chk" "1"
	set_default "ss_basic_chng_trust_net_1_typ" "udp"
	set_default "ss_basic_chng_trust_net_2_typ" "tcp"
	set_default "ss_basic_chng_trust_net_3_typ" "dot"

	set_default "ss_basic_chng_trust_udp_1_opt" "8.8.8.8"
	set_default "ss_basic_chng_trust_udp_1_usr" "8.8.8.8:53"
	set_default "ss_basic_chng_trust_udp_2_opt" "1.1.1.1"
	set_default "ss_basic_chng_trust_udp_2_usr" "8.8.8.8:53"
	set_default "ss_basic_chng_trust_udp_3_opt" "9.9.9.9"
	set_default "ss_basic_chng_trust_udp_3_usr" "8.8.8.8:53"
	
	set_default "ss_basic_chng_trust_tcp_1_opt" "1.1.1.1"
	set_default "ss_basic_chng_trust_tcp_1_usr" "8.8.8.8:53"
	set_default "ss_basic_chng_trust_tcp_2_opt" "8.8.8.8"
	set_default "ss_basic_chng_trust_tcp_2_usr" "8.8.8.8:53"
	set_default "ss_basic_chng_trust_tcp_3_opt" "9.9.9.9"
	set_default "ss_basic_chng_trust_tcp_3_usr" "8.8.8.8:53"

	set_default "ss_basic_chng_trust_dot_1_opt" "dns.google.com@8.8.8.8"
	set_default "ss_basic_chng_trust_dot_1_usr" "dns.google.com@8.8.8.8"
	set_default "ss_basic_chng_trust_dot_2_opt" "dns.google.com@8.8.8.8"
	set_default "ss_basic_chng_trust_dot_2_usr" "dns.google.com@8.8.8.8"
	set_default "ss_basic_chng_trust_dot_3_opt" "dns.google.com@8.8.8.8"
	set_default "ss_basic_chng_trust_dot_3_usr" "dns.google.com@8.8.8.8"

	set_default "ss_basic_chng_ipv6_drop_direc" "0"
	set_default "ss_basic_chng_ipv6_drop_proxy" "1"
	set_default "ss_basic_chng_dns_query_times" "1"

	echo_date "----------------------- start chinadns-ng -----------------------"
	echo_date "💾 生成chinadns-ng配置文件，用于国内外DNS分流..."

	check_fix_isp(){
		local dns_para=$1
		local dns_seq=$2
		local dns_default=$3
		local dns_addr dns_port dns_explicit

		if [ "${dns_para}" == "99" ];then
			return 0
		fi

		{
			read -r dns_addr
			read -r dns_port
			read -r dns_explicit
		} <<-EOF
		$(parse_dns_addr_port "${dns_para}")
		EOF
		
		__valid_ip46 "${dns_addr}"
		if [ "$?" == "0" ]; then
			# ipv4
			ipset test chnroute "${dns_addr}" >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 不是国内ip
				ipset test ignlist "${dns_addr}" >/dev/null 2>&1
				if [ "$?" != "0" ]; then
					# 不是局域网地址
					echo_date "⚠️ 检测到中国DNS-${dns_seq}的udp DNS：${dns_para}不是国内ip，切换为${dns_default}！"
					eval "ss_basic_chng_china_udp_${dns_seq}_opt=\$dns_default"
					dbus set "ss_basic_chng_china_udp_${dns_seq}_opt=$dns_default"
				fi
			fi
		elif [ "$?" == "1" ]; then
			# ipv6
			ipset test chnroute6 "${dns_addr}" >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 不是国内ip
				ipset test ignlist6 "${dns_addr}" >/dev/null 2>&1
				if [ "$?" != "0" ]; then
					echo_date "⚠️ 检测到中国DNS-${dns_seq}的udp DNS：${dns_para}不是国内ip，切换为${dns_default}！"
					eval "ss_basic_chng_china_udp_${dns_seq}_opt=\$dns_default"
					dbus set "ss_basic_chng_china_udp_${dns_seq}_opt=$dns_default"
				fi
			fi
		else
			# 不是ip，帮忙纠正
			echo_date "⚠️ 检测到中国DNS-${dns_seq}的udp DNS：${dns_para}不是正确的ip，切换为${dns_default}！"
			eval "ss_basic_chng_china_udp_${dns_seq}_opt=\$dns_default"
			dbus set "ss_basic_chng_china_udp_${dns_seq}_opt=$dns_default"
		fi
	}

	# 非回国模式下，检测用户的isp dns是否为国外dns（是否在中国dns-1/-2/-3中使用了国外dns）
	if [ "${ss_basic_mode}" != "6" ]; then
		if [ "${ss_basic_chng_china_dns_1_chk}" == "1" -a "${ss_basic_chng_china_net_1_typ}" == "udp" ];then
			check_fix_isp ${ss_basic_chng_china_udp_1_opt} 1 223.5.5.5
		fi
		if [ "${ss_basic_chng_china_dns_2_chk}" == "1" -a "${ss_basic_chng_china_net_2_typ}" == "udp" ];then
			check_fix_isp ${ss_basic_chng_china_udp_2_opt} 2 223.6.6.6
		fi
		if [ "${ss_basic_chng_china_dns_3_chk}" == "1" -a "${ss_basic_chng_china_net_3_typ}" == "udp" ];then
			check_fix_isp ${ss_basic_chng_china_udp_3_opt} 3 119.29.29.29
		fi
	fi

	check_user_dns(){
		local dns_para=$1
		local dns_seq=$2
		local dns_default=$3
		local dns_type=$4
		local addr port explicit_port

		{
			read -r addr
			read -r port
			read -r explicit_port
		} <<-EOF
		$(parse_dns_addr_port "${dns_para}")
		EOF

		__valid_ip46 "${addr}"
		if [ "$?" == "0" ]; then
			# ipv4
			ipset test chnroute ${addr} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 不是国内ip
				ipset test ignlist ${addr} >/dev/null 2>&1
				if [ "$?" != "0" ]; then
					echo_date "⚠️ 检测到中国DNS-${dns_seq}的${dns_type} DNS：${dns_para}不是国内ip，切换为${dns_default}！"
					eval "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=\$dns_default"
					dbus set "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=$dns_default"
				fi
			fi
		elif [ "$?" == "1" ]; then
			# ipv6
			ipset test chnroute6 ${addr} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 不是国内ip
				ipset test ignlist6 ${addr} >/dev/null 2>&1
				if [ "$?" != "0" ]; then
					echo_date "⚠️ 检测到中国DNS-${dns_seq}的${dns_type} DNS：${dns_para}不是国内ip，切换为${dns_default}！"
					eval "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=\$dns_default"
					dbus set "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=$dns_default"
				fi
			fi
		else
			# 不是ip，帮忙纠正
			echo_date "⚠️ 检测到中国DNS-${dns_seq}的${dns_type} DNS：${dns_para}不是正确的ip，切换为${dns_default}！"
			eval "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=\$dns_default"
			dbus set "ss_basic_chng_china_${dns_type}_${dns_seq}_usr=$dns_default"
		fi
	}
	
	# 检测用户设置的中国udp/tcp DNS-1/-2/-3，自定义dns是否为国外dns
	if [ "${ss_basic_mode}" != "6" ]; then
		# udp
		if [ "${ss_basic_chng_china_dns_1_chk}" == "1" -a "${ss_basic_chng_china_net_1_typ}" == "udp" -a "${ss_basic_chng_china_udp_1_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_udp_1_usr} 1 223.5.5.5 udp
		fi
		if [ "${ss_basic_chng_china_dns_2_chk}" == "1" -a "${ss_basic_chng_china_net_2_typ}" == "udp" -a "${ss_basic_chng_china_udp_2_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_udp_2_usr} 2 223.6.6.6 udp
		fi
		if [ "${ss_basic_chng_china_dns_3_chk}" == "1" -a "${ss_basic_chng_china_net_3_typ}" == "udp" -a "${ss_basic_chng_china_udp_3_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_udp_3_usr} 3 119.29.29.29 udp
		fi

		# tcp
		if [ "${ss_basic_chng_china_dns_1_chk}" == "1" -a "${ss_basic_chng_china_net_1_typ}" == "tcp" -a "${ss_basic_chng_china_tcp_1_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_tcp_1_usr} 1 223.5.5.5 tcp
		fi
		if [ "${ss_basic_chng_china_dns_2_chk}" == "1" -a "${ss_basic_chng_china_net_2_typ}" == "tcp" -a "${ss_basic_chng_china_tcp_2_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_tcp_2_usr} 2 223.6.6.6 tcp
		fi
		if [ "${ss_basic_chng_china_dns_3_chk}" == "1" -a "${ss_basic_chng_china_net_3_typ}" == "tcp" -a "${ss_basic_chng_china_tcp_3_opt}" == "99" ];then
			check_user_dns ${ss_basic_chng_china_tcp_3_usr} 3 119.28.28.28 tcp
		fi
		
	fi

	# 1. 避免用户乱设置给关掉，强制要求中国DNS不能三个都不选
	if [ "${ss_basic_chng_china_dns_1_chk}" != "1" -a "${ss_basic_chng_china_dns_2_chk}" != "1" -a "${ss_basic_chng_china_dns_3_chk}" != "1" ];then
		echo_date "⚠️ 检测到中国DNS-1、中国DNS-2和中国DNS-3均未开启，至少需要指定一个国内上游DNS！"
		echo_date "⤴️ 自动开启中国DNS-1和中国DNS-2！"
		ss_basic_chng_china_dns_1_chk=1
		dbus set ss_basic_chng_china_dns_1_chk=1
		ss_basic_chng_china_dns_2_chk=1
		dbus set ss_basic_chng_china_dns_2_chk=1
	fi

	# 2. 避免用户乱设置给关掉，强制要求可信DNS不能三个都不选
	if [ "${ss_basic_chng_trust_dns_1_chk}" != "1" -a "${ss_basic_chng_trust_dns_2_chk}" != "1" -a "${ss_basic_chng_trust_dns_3_chk}" != "1" ];then
		echo_date "⚠️ 检测到可信DNS-1、可信DNS-2和可信DNS-3均未开启，至少需要指定一个可信上游DNS！"
		echo_date "⤴️ 自动开启可信DNS-1和可信DNS-2！"
		ss_basic_chng_trust_dns_1_chk="1"
		dbus set ss_basic_chng_trust_dns_1_chk="1"
		ss_basic_chng_trust_dns_2_chk="1"
		dbus set ss_basic_chng_trust_dns_2_chk="1"
	fi
	
	# 3. chinadns-ng的启动参数检查
	# if [ -n "${ss_basic_chng_dns_query_times}" ];then
	# 	if [ $(number_test ${ss_basic_chng_dns_query_times}) != "0" ];then
	# 		echo_date "⚠️ chinadns-ng重复发包次数填写错误，自动更正为1！"
	# 		ss_basic_chng_dns_query_times="1"
	# 		dbus set ss_basic_chng_dns_query_times="1"
	# 	fi
	# 	if [ ${ss_basic_chng_dns_query_times} -gt "3" ];then
	# 		echo_date "⚠️ chinadns-ng重复发包次数填为${ss_basic_chng_dns_query_times}！建议此处设置不超过3！继续！"
	# 	fi
	# 	local DNS_REPEATS="repeat-times ${ss_basic_chng_dns_query_times}"
	# fi

	# 4. 生成chinadns-ng的国内DNS
	# 中国DNS-1 (直连) 🌏
	if [ "${ss_basic_chng_china_dns_1_chk}" == "1" ];then
		local CDNS_1=$(get_dns china 1)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (china) → ${CDNS_1%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (china) → ${CDNS_1%%\?*}"
		fi
	fi

	# 中国DNS-2 (直连) 🌏
	if [ "${ss_basic_chng_china_dns_2_chk}" == "1" ];then
		local CDNS_2=$(get_dns china 2)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (china) → ${CDNS_2%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (china) → ${CDNS_2%%\?*}"
		fi
	fi

	# 中国DNS-3 (直连) 🌏
	if [ "${ss_basic_chng_china_dns_3_chk}" == "1" ];then
		local CDNS_3=$(get_dns china 3)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (china) → ${CDNS_3%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (china) → ${CDNS_3%%\?*}"
		fi
	fi

	if [ "$CDNS_1" == "$CDNS_2" ] && [ "$CDNS_2" == "$CDNS_3" ]; then
		# 三个变量都相同
		if [ -n "$CDNS_1" ]; then
			#三个变量都相同，且都是非空
			echo_date "⚠️检测到三个中国DNS设置相同！请更改设置，本次仅使用第一个，关闭其余两个！"
			dbus set ss_basic_chng_china_dns_2_chk=0
			dbus set ss_basic_chng_china_dns_3_chk=0
			unset CDNS_2
			unset CDNS_3
		fi
	elif [ "$CDNS_1" == "$CDNS_2" ]; then
		# 第1和第2变量相同，但与第3不同
		if [ -n "$CDNS_1" ]; then
			echo_date "⚠️ 检测到中国DNS-1和中国DNS-2设置相同，自动关闭中国DNS-2！"
			dbus set ss_basic_chng_china_dns_2_chk=0
			unset CDNS_2
		fi
	elif [ "$CDNS_1" == "$CDNS_3" ]; then
		# 第1和第3变量相同，但与第2不同
		if [ -n "$CDNS_1" ]; then
			echo_date "⚠️ 检测到中国DNS-1和中国DNS-3设置相同，自动关闭中国DNS-3！"
			dbus set ss_basic_chng_china_dns_3_chk=0
			unset CDNS_3
		fi
	elif [ "$CDNS_2" == "$CDNS_3" ]; then
		# 第2和第3变量相同，但与第1不同
		if [ -n "$CDNS_2" ]; then
			echo_date "⚠️ 检测到中国DNS-2和中国DNS-3设置相同，自动关闭中国DNS-3！"
			dbus set ss_basic_chng_china_dns_3_chk=0
			unset CDNS_3
		fi
	fi

	# 5. 生成chinadns-ng的可信DNS
	# 可信DNS-1 (代理) 🚀
	if [ "${ss_basic_chng_trust_dns_1_chk}" == "1" ];then
		local FDNS_1=$(get_dns trust 1)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 1)") → ${FDNS_1%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 1)") → ${FDNS_1%%\?*}"
		fi
	fi

	# 可信DNS-2 (代理) 🚀
	if [ "${ss_basic_chng_trust_dns_2_chk}" == "1" ];then
		local FDNS_2=$(get_dns trust 2)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 2)") → ${FDNS_2%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 2)") → ${FDNS_2%%\?*}"
		fi
	fi

	# 可信DNS-3 (代理) 🚀
	if [ "${ss_basic_chng_trust_dns_3_chk}" == "1" ];then
		local FDNS_3=$(get_dns trust 3)
		if [ "${ss_basic_dns_serverx}" == "1" ];then
			echo_date "🔍️ → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 3)") → ${FDNS_3%%\?*}"
		else
			echo_date "🔍️ → dnsmasq → chinadns-ng (trust) → $(get_proxy_type "$(get_dns_effective_net trust 3)") → ${FDNS_3%%\?*}"
		fi
	fi

	if [ "$FDNS_1" == "$FDNS_2" ] && [ "$FDNS_2" == "$FDNS_3" ]; then
		# 三个变量都相同
		if [ -n "$FDNS_1" ]; then
			#三个变量都相同，且都是非空
			echo_date "⚠️ 检测到三个可信DNS设置相同！请更改设置，本次仅使用第一个，关闭其余两个！"
			dbus set ss_basic_chng_trust_dns_2_chk=0
			dbus set ss_basic_chng_trust_dns_3_chk=0
			unset FDNS_2
			unset FDNS_3
		fi
	elif [ "$FDNS_1" == "$FDNS_2" ]; then
		# 第1和第2变量相同，但与第3不同
		if [ -n "$FDNS_1" ]; then
			echo_date "⚠️ 检测到可信DNS-1和可信DNS-2设置相同，自动关闭可信DNS-2！"
			dbus set ss_basic_chng_trust_dns_2_chk=0
			unset FDNS_2
		fi
	elif [ "$FDNS_1" == "$FDNS_3" ]; then
		# 第1和第3变量相同，但与第2不同
		if [ -n "$FDNS_1" ]; then
			echo_date "⚠️ 检测到可信DNS-1和可信DNS-3设置相同，自动关闭可信DNS-3！"
			dbus set ss_basic_chng_trust_dns_3_chk=0
			unset FDNS_3
		fi
	elif [ "$FDNS_2" == "$FDNS_3" ]; then
		# 第2和第3变量相同，但与第1不同
		if [ -n "$FDNS_2" ]; then
			echo_date "⚠️ 检测到可信DNS-2和可信DNS-3设置相同，自动关闭可信DNS-3！"
			dbus set ss_basic_chng_trust_dns_3_chk=0
			unset FDNS_3
		fi
	fi

	# [ -n "$CDNS_1" ] && echo_date "CDNS_1: $CDNS_1"
	# [ -n "$CDNS_2" ] && echo_date "CDNS_2: $CDNS_2"
	# [ -n "$CDNS_3" ] && echo_date "CDNS_3: $CDNS_3"
	# [ -n "$FDNS_1" ] && echo_date "FDNS_1: $FDNS_1"
	# [ -n "$FDNS_2" ] && echo_date "FDNS_2: $FDNS_2"
	# [ -n "$FDNS_3" ] && echo_date "FDNS_3: $FDNS_3"


	if [ -n "${CDNS_1}" -a -n "${CDNS_2}" -a -n "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_1},${CDNS_2},${CDNS_3}
	elif [ -n "${CDNS_1}" -a -n "${CDNS_2}" -a -z "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_1},${CDNS_2}
	elif [ -n "${CDNS_1}" -a -z "${CDNS_2}" -a -n "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_1},${CDNS_3}
	elif [ -z "${CDNS_1}" -a -n "${CDNS_2}" -a -n "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_2},${CDNS_3}
	elif [ -n "${CDNS_1}" -a -z "${CDNS_2}" -a -z "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_1}
	elif [ -z "${CDNS_1}" -a -n "${CDNS_2}" -a -z "${CDNS_3}" ]; then
		local CDNS_LINE=${CDNS_2}
	elif [ -z "${CDNS_1}" -a -z "${CDNS_2}" -a -n "$CDN{}S_3" ]; then
		local CDNS_LINE=${CDNS_3}
	fi
	
	if [ -n "${FDNS_1}" -a -n "${FDNS_2}" -a -n "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_1},${FDNS_2},${FDNS_3}
	elif [ -n "${FDNS_1}" -a -n "${FDNS_2}" -a -z "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_1},${FDNS_2}
	elif [ -n "${FDNS_1}" -a -z "${FDNS_2}" -a -n "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_1},${FDNS_3}
	elif [ -z "${FDNS_1}" -a -n "${FDNS_2}" -a -n "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_2},${FDNS_3}
	elif [ -n "${FDNS_1}" -a -z "${FDNS_2}" -a -z "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_1}
	elif [ -z "${FDNS_1}" -a -n "${FDNS_2}" -a -z "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_2}
	elif [ -z "${FDNS_1}" -a -z "${FDNS_2}" -a -n "${FDNS_3}" ]; then
		local FDNS_LINE=${FDNS_3}
	fi

	# 3. 给出警告，可信DNS里至少需要一个tcp/dot服务器（避免因全部使用udp服务器，而服务器不支持udp导致问题）
	local F_RET=$(echo ${FDNS_LINE} | grep -E "tcp|tls")
	if [ -z "${F_RET}" ];then
		echo_date "⚠️ 警告：建议可信DNS里至少启用一个tcp/dot服务器，以避免代理节点不支持udp"
	fi

	if [ "${ss_basic_dns_serverx}" == "1" ];then
		local chng_bind_port=53
	else
		local chng_bind_port=7913
	fi

	# gen chinadns-ng conf
	rm -rf /tmp/chinadns_ng.conf
	cat >>"/tmp/chinadns_ng.conf" <<-EOF
		# 监听地址和端口
		bind-addr ::
		bind-port ${chng_bind_port}@udp

		proxy-server socks5://127.0.0.1:23456
		proxy-group gfw,black,router
		proxy-protocol tcp,tls
		
	EOF

	echo "# 国内上游" >>/tmp/chinadns_ng.conf
	[ -n "$CDNS_1" ] && echo "china-dns $CDNS_1" >>/tmp/chinadns_ng.conf
	[ -n "$CDNS_2" ] && echo "china-dns $CDNS_2" >>/tmp/chinadns_ng.conf
	[ -n "$CDNS_3" ] && echo "china-dns $CDNS_3" >>/tmp/chinadns_ng.conf
	echo "" >>/tmp/chinadns_ng.conf
	echo "# 可信上游" >>/tmp/chinadns_ng.conf
	[ -n "$FDNS_1" ] && echo "trust-dns $FDNS_1" >>/tmp/chinadns_ng.conf
	[ -n "$FDNS_2" ] && echo "trust-dns $FDNS_2" >>/tmp/chinadns_ng.conf
	[ -n "$FDNS_3" ] && echo "trust-dns $FDNS_3" >>/tmp/chinadns_ng.conf
		
	if [ "${ss_basic_chng}" == "1" ];then
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			
			# 国内优先：gfwlist黑名单模式
			chnlist-file /koolshare/ss/rules/chnlist.gz
			gfwlist-file /koolshare/ss/rules/gfwlist.gz
			default-tag chn
						
			# 收集 tag:gfw 域名的 IP，用于走代理
			add-tagchn-ip chnlist,chnlist6
			add-taggfw-ip gfwlist,gfwlist6
			
		EOF
	elif [ "${ss_basic_chng}" == "2" ];then
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			
			# 国外优先：chnlist白名单模式
			chnlist-file /koolshare/ss/rules/chnlist.gz
			gfwlist-file /koolshare/ss/rules/gfwlist.gz
			default-tag gfw
						
			# 收集 tag:chn域名的 IP，用于不走代理
			add-tagchn-ip chnlist,chnlist6
			add-taggfw-ip gfwlist,gfwlist6
			
		EOF
	elif [ "${ss_basic_chng}" == "3" ];then
		# 智能判断：chnroute模式
		# 1. 先匹配chnlist.txt内域名，用国内上游解析，并将解析ip结果存于ipset:chnlist,chnlist6中，此部分流量走直连（即使解析到海外ip）
		# 2. 再匹配gfwlist.txt内域名，用可信上游解析，并将解析ip结果存于ipset:gfwlist,gfwlist6中，此部分流量走代理（即使解析到大陆ip）
		# 3. 其余域名请求，即chnlist和gfwlist均为匹配上的，同时用国内和可信上游解析，解析结果如果是大陆ip，则走直连，如果是海外ip则走代理
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			
			# 智能判断：chnroute模式
			chnlist-file /koolshare/ss/rules/chnlist.gz
			gfwlist-file /koolshare/ss/rules/gfwlist.gz
			chnlist-first
			
			# 收集 tag:chn、tag:gfw 域名的 IP
			add-tagchn-ip chnlist,chnlist6
			add-taggfw-ip gfwlist,gfwlist6
			
		EOF
	fi
	
	# defalut
	cat >>"/tmp/chinadns_ng.conf" <<-EOF
		# 当前节点服务器域名直连解析
	EOF
	if [ -s /tmp/ss_node_domains.txt ];then
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			group node
			group-dnl /tmp/ss_node_domains.txt
			group-upstream ${CDNS_LINE}

		EOF
	fi

	cat >>"/tmp/chinadns_ng.conf" <<-EOF
		# 域名白名单
		group white
		group-dnl /tmp/white_list.txt
		group-upstream ${CDNS_LINE}
		group-ipset white_list,white_list6

		# 域名黑名单
		group black
		group-dnl /tmp/black_list.txt
		group-upstream ${FDNS_LINE}
		group-ipset black_list,black_list6

		# 控制路由器内部哪些域名需要走代理
		group router
		group-dnl /koolshare/ss/rules/rotlist.txt
		group-upstream ${FDNS_LINE}
		group-ipset router,router6
		
	EOF

	if [ "${ss_basic_block_resov}" == "1" ]; then
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			group null
			group-dnl /tmp/block_list.txt
			
		EOF
	fi

	# 未匹配域名判决
	cat >>"/tmp/chinadns_ng.conf" <<-EOF
		# 测试 tag:none 域名的 IP (针对国内上游)
		ipset-name4 chnroute
		ipset-name6 chnroute6
		
	EOF
	
	if [ "${INTERNET6}" == "0" ];then
		# 检测到系统未开启ipv6功能，默认关闭所有ipv6解析
		dbus set ss_basic_internet6_flag=0
		cat >>"/tmp/chinadns_ng.conf" <<-EOF
			# ipv6请求行为：全部过滤
			no-ipv6
		EOF
	else
		dbus set ss_basic_internet6_flag=1
		local chng_drop_direc="${ss_basic_chng_ipv6_drop_direc}"
		local chng_drop_proxy="${ss_basic_chng_ipv6_drop_proxy}"
		if ipv6_proxy_enabled; then
			chng_drop_proxy="0"
			echo_date "检测到IPv6透明代理已开启，代理域名的AAAA过滤将自动关闭。"
		fi
		if [ "${chng_drop_direc}" == "0" -a "${chng_drop_proxy}" == "1" ];then
			cat >>"/tmp/chinadns_ng.conf" <<-EOF
				# ipv6请求行为，过滤代理域名
				no-ipv6 tag:gfw,tag:router,tag:black,tag:none@ip:non_china
			EOF
		elif [ "${chng_drop_direc}" == "1" -a "${chng_drop_proxy}" == "1" ];then
			cat >>"/tmp/chinadns_ng.conf" <<-EOF
				# ipv6请求行为：过滤全部业务域名，保留节点服务器域名直连解析
				no-ipv6 tag:chn,tag:white,tag:gfw,tag:router,tag:black,tag:none@ip:china,tag:none@ip:non_china
			EOF
		elif [ "${chng_drop_direc}" == "1" -a "${chng_drop_proxy}" == "0" ];then
			cat >>"/tmp/chinadns_ng.conf" <<-EOF
				# ipv6请求行为：全部直连域名
				no-ipv6 tag:chn,tag:white,tag:none@ip:china
			EOF
		fi
	fi

	# for hosts file
	cp -rf /tmp/etc/hosts /tmp/etc/chng_hosts
	sed -i 's/\.[[:space:]]/ /g' /etc/chng_hosts
	
	cat >>"/tmp/chinadns_ng.conf" <<-EOF
	
		# 过滤dns
		filter-qtype 64,65

		# hosts
		hosts /etc/chng_hosts
		
		# dns 缓存
		cache 8192
		cache-stale 86400
		cache-refresh 20
		cache-ignore asuscomm.com
		#cache-db /tmp/chinadns_cache.db
		
		# verdict 缓存 (用于 tag:none 域名)
		verdict-cache 8192
		verdict-cache-db /tmp/chinadns_verdict_cache.db
		
		# dns重复发包
		${DNS_REPEATS}
		
		# 详细日志
		#verbose
	EOF
	echo_date "🆗 chinadns-ng配置文件生成完毕，位于/tmp/chinadns_ng.conf"
	echo_date "⚡️ 开启chinadns-ng，用于所有域名的DNS解析..."
	rm -rf /tmp/chinadns@cache.db >/dev/null 2>&1
	rm -rf /tmp/chinadns@verdict-cache.db >/dev/null 2>&1
	rm -rf /tmp/chinadns_log.txt >/dev/null 2>&1

	local pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_exta=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_EXTA=.+"|awk -F "=" '{print $2}'|sed 's/"//g')

	if [ "${pkg_arch}" == "hnd_v8" -o "${pkg_arch}" == "mtk" -o "${pkg_arch}" == "ipq64" ];then
		if [ "${pkg_type}" == "full" -a "${pkg_exta}" == "_debug" ];then
			echo_date "⚡️ 开启chinadns-ng debug模式..."
			local _debug_mode=1
			#sed -i 's/#verbose/verbose/g' /tmp/chinadns_ng.conf
			#sed -i 's/#cache-db \/tmp\/chinadns_cache.db/cache-db \/tmp\/chinadns_cache.db/g' /tmp/chinadns_ng.conf
		fi
	fi
	
	if [ "${_debug_mode}" == "1" ];then
		ulimit -c unlimited
		cd /tmp
		env -i PATH=${PATH} chinadns-ng -C /tmp/chinadns_ng.conf >/tmp/chinadns_log.txt 2>&1 &
	else
		env -i PATH=${PATH} chinadns-ng -C /tmp/chinadns_ng.conf >/dev/null 2>&1 &
	fi
	
	detect_running_status chinadns-ng
	echo_date "---------------------------------------------------------"
}

parse_dns_addr_port(){
	local dns_raw="$1"
	local default_port="${2:-53}"
	local addr=""
	local port="${default_port}"
	local explicit_port="0"

	case "${dns_raw}" in
	*#*)
		addr="${dns_raw%#*}"
		port="${dns_raw##*#}"
		explicit_port="1"
		;;
	\[*\]:*)
		addr="${dns_raw%\]:*}"
		addr="${addr#\[}"
		port="${dns_raw##*\]:}"
		explicit_port="1"
		;;
	*)
		if echo "${dns_raw}" | grep -Eq '^([0-9]{1,3}[.]){3}[0-9]{1,3}:[0-9]+$'; then
			addr="${dns_raw%:*}"
			port="${dns_raw##*:}"
			explicit_port="1"
		else
			addr="${dns_raw}"
		fi
		;;
	esac

	addr="${addr#\[}"
	addr="${addr%\]}"
	printf '%s\n%s\n%s\n' "${addr}" "${port}" "${explicit_port}"
}

format_dns_endpoint(){
	local dns_raw="$1"
	local default_port="${2:-53}"
	local addr port explicit_port

	{
		read -r addr
		read -r port
		read -r explicit_port
	} <<-EOF
	$(parse_dns_addr_port "${dns_raw}" "${default_port}")
	EOF

	__valid_ip46 "${addr}"
	case "$?" in
	0)
		[ "${explicit_port}" = "1" ] && echo "${addr}#${port}" || echo "${addr}"
		;;
	1)
		[ "${explicit_port}" = "1" ] && echo "${addr}#${port}" || echo "${addr}"
		;;
	*)
		echo "${dns_raw}"
		;;
	esac
}

detect_domain() {
	domain1=$(echo $1 | grep -E "^https://|^http://|/")
	domain2=$(echo $1 | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		# url
		return 1
	else
		# domain
		return 0
	fi
}

is_domain(){
	[ -n "$1" ] || return 1
	__valid_ip46 "$1" >/dev/null 2>&1
	case "$?" in
	0|1)
		return 1
		;;
	esac
	echo $1 | awk 'BEGIN {regex = "^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$"} $0 ~ regex { print }'
}

get_proxy_type(){
	case "$1" in
	udp)
		echo "udp-relay"
		;;
	tcp|dot)
		echo "socks5"
		;;
	esac
}

get_dns_selected_net(){
	local type="$1"
	local numb="$2"
	eval echo \$ss_basic_chng_${type}_net_${numb}_typ
}

get_dns_effective_net(){
	local type="$1"
	local numb="$2"
	local net="$(get_dns_selected_net "${type}" "${numb}")"
	if [ "${type}" = "trust" ] && [ "${ss_basic_type}" = "6" ] && [ "${net}" = "udp" ];then
		echo "tcp"
	else
		echo "${net}"
	fi
}

get_dns_para(){
	local type=$1
	local numb=$2
	local para=$3
	local addr="8.8.8.8"
	local port="53"
	local explicit_port=""

	# udp, tcp, dot
	local net="$(get_dns_selected_net "${type}" "${numb}")"
	
	local dns_opt=$(eval echo \$ss_basic_chng_${type}_${net}_${numb}_opt)
	local dns_usr=$(eval echo \$ss_basic_chng_${type}_${net}_${numb}_usr)
	
	if [ "${dns_opt}" == "99" ];then
		{
			read -r addr
			read -r port
			read -r explicit_port
		} <<-EOF
		$(parse_dns_addr_port "${dns_usr}")
		EOF
		[ -n "${addr}" ] || addr="8.8.8.8"
	else
		local addr="${dns_opt}"
	fi

	if [ "${para}" == "addr" ];then
		echo ${addr}
	elif [ "${para}" == "port" ];then
		echo ${port}
	fi
	
}

iter_dns_udp_relay_targets(){
	local sep="$(printf '\037')"
	if [ "${ss_basic_dns_plan}" = "1" ];then
		local numb=""
		for numb in 1 2 3
		do
			local chk="$(eval echo \$ss_basic_chng_trust_dns_${numb}_chk)"
			local net="$(get_dns_selected_net trust "${numb}")"
			if [ "${chk}" = "1" ] && [ "${net}" = "udp" ] && [ "${ss_basic_type}" != "6" ];then
				printf '%s\037%s\037%s\037%s\037%s\n' "$((SMARTDNS_RELAY_PORT_BASE + numb - 1))" "$(get_dns_para trust "${numb}" addr)" "$(get_dns_para trust "${numb}" port)" "chinadns-ng trust DNS ${numb}" ""
			fi
		done
	elif [ "${ss_basic_dns_plan}" = "2" ] && [ "${ss_basic_type}" != "6" ];then
		smartdns_iter_gfw_udp_relays
	fi
}

has_dns_udp_relay_targets(){
	[ -n "$(iter_dns_udp_relay_targets | sed -n '1p')" ]
}

gen_xray_dns_inbound(){
	local config_file="$1"
	local sep="$(printf '\037')"
	local relay_port addr port provider description

	[ -n "${config_file}" ] || return 1
	has_dns_udp_relay_targets || return 0

	while IFS="${sep}" read -r relay_port addr port provider description
	do
		[ -n "${relay_port}" ] || continue
		cat >>"${config_file}" <<-EOF
			{
				"tag": "dns_udp_${relay_port}",
				"listen": "127.0.0.1",
				"port": ${relay_port},
				"protocol": "dokodemo-door",
				"settings": {
					"address": "${addr}",
					"port": ${port},
					"network": "udp",
					"timeout": 0,
					"followRedirect": false
				}
			},
		EOF
	done <<-EOF
$(iter_dns_udp_relay_targets)
EOF
	return 0
}

append_xray_dns_relay_inbounds(){
	local config_file="$1"
	local tmp_file="${config_file}.dnsrelay"
	local add_file="${config_file}.dnsrelay.add"
	local sep="$(printf '\037')"
	local relay_port addr port provider description
	local entry_count=0

	[ -f "${config_file}" ] || return 1
	has_dns_udp_relay_targets || return 0

	cat > "${add_file}" <<-'EOF'
[]
EOF
	while IFS="${sep}" read -r relay_port addr port provider description
	do
		[ -n "${relay_port}" ] || continue
		if cat "${config_file}" | run jq -e --argjson port "${relay_port}" '.inbounds[]? | select(.protocol == "dokodemo-door" and .port == $port)' >/dev/null 2>&1; then
			continue
		fi
		if [ "${entry_count}" -eq 0 ];then
			cat > "${add_file}" <<-EOF
[
  {
    "tag": "dns_udp_${relay_port}",
    "listen": "127.0.0.1",
    "port": ${relay_port},
    "protocol": "dokodemo-door",
    "settings": {
      "address": "${addr}",
      "port": ${port},
      "network": "udp",
      "timeout": 0,
      "followRedirect": false
    }
  }
]
EOF
		else
			if ! cat "${add_file}" | run jq '. += [{
				"tag": "dns_udp_'"${relay_port}"'",
				"listen": "127.0.0.1",
				"port": '"${relay_port}"',
				"protocol": "dokodemo-door",
				"settings": {
					"address": "'"${addr}"'",
					"port": '"${port}"',
					"network": "udp",
					"timeout": 0,
					"followRedirect": false
				}
			}]' > "${add_file}.tmp"; then
				rm -rf "${add_file}" "${add_file}.tmp" >/dev/null 2>&1
				return 1
			fi
			mv -f "${add_file}.tmp" "${add_file}"
		fi
		entry_count=$((entry_count + 1))
	done <<-EOF
$(iter_dns_udp_relay_targets)
EOF

	if [ "${entry_count}" -eq 0 ];then
		rm -rf "${add_file}" >/dev/null 2>&1
		return 0
	fi
	if ! cat "${config_file}" | run jq --slurpfile relays "${add_file}" '.inbounds += $relays[0]' > "${tmp_file}"; then
		rm -rf "${tmp_file}" "${add_file}" >/dev/null 2>&1
		return 1
	fi
	mv -f "${tmp_file}" "${config_file}"
	rm -rf "${add_file}" >/dev/null 2>&1
	return 0
}

append_xray_ipv6_tproxy_inbound() {
	local config_file="$1"
	local tmp_file="${config_file}.ipv6"
	ipv6_proxy_enabled || return 0
	[ -f "${config_file}" ] || return 1
	# Reuse the existing 3333 transparent proxy inbound for both IPv4 and IPv6.
	if cat "${config_file}" | run jq -e '.inbounds[]? | select(.protocol == "dokodemo-door" and .port == 3333)' >/dev/null 2>&1; then
		return 0
	fi
	if ! cat "${config_file}" | run jq '.inbounds += [{"listen":"0.0.0.0","port":3333,"protocol":"dokodemo-door","settings":{"network":"tcp,udp","followRedirect":true}}]' >"${tmp_file}"; then
		rm -rf "${tmp_file}" >/dev/null 2>&1
		return 1
	fi
	mv "${tmp_file}" "${config_file}"
}

get_dns(){
	local type=$1
	local numb=$2

	# udp, tcp, dot
	local net="$(get_dns_selected_net "${type}" "${numb}")"
	local eff_net="$(get_dns_effective_net "${type}" "${numb}")"
	
	local dns_opt=$(eval echo \$ss_basic_chng_${type}_${net}_${numb}_opt)
	local dns_usr=$(eval echo \$ss_basic_chng_${type}_${net}_${numb}_usr)

	if [ "${eff_net}" == "dot" ];then
		eff_net=tls
	fi

	if [ "${net}_${type}_${numb}" == "udp_trust_1" ];then
		local _port=1055
	elif [ "${net}_${type}_${numb}" == "udp_trust_2" ];then
		local _port=1056
	elif [ "${net}_${type}_${numb}" == "udp_trust_3" ];then
		local _port=1057
	fi
	
	if [ "${dns_opt}" == "99" ];then
		dns_usr=$(format_dns_endpoint "${dns_usr}")

		if [ "${eff_net}" == "udp" ];then
			if [ "${type}" == "trust" ];then
				echo "udp://127.0.0.1#${_port}?count=0?life=0"
			else
				echo "udp://${dns_usr}?count=0?life=0"
			fi
		else
			echo "${eff_net}://${dns_usr}"
		fi
	else
		if [ "${eff_net}" == "udp" ];then
			if [ "${type}" == "trust" ];then
				echo "udp://127.0.0.1#${_port}?count=0?life=0"
			else
				echo "udp://${dns_opt}?count=0?life=0"
			fi
		else
			echo "${eff_net}://${dns_opt}"
		fi
	fi
}

add_white_black() {
	# 白名单： 
	# 1. ignlist	 (ipv4 + ipv6保留地址, host地址如: router.asuscomm.com)
	# 2. chnlist	 (大陆域名，由网络整理，由fancyss更新推送)
	# 3. chnlist_ext (大陆域名-扩展，由fancyss整理 + 推送)
	# 4. chnroute   （ip/cidr, ，由网络整理，由fancyss更新推送）
	# 4. white_list （doamin, user define）
	# 5. white_list （ip/cidr, user define）
	
	# 黑名单： 
	# 1. gfwlist	 (被墙域名，来自网络整理，由fancyss更新推送)
	# 2. gfwlist_ext (被墙名单-扩展：包括ip、域名，由fancyss更新推送)
	# 3. black_list （doamin, user define）
	# 4. black_list （ip/cidr, user define）
	#
	# 黑名单-机内
	# 1. router		 (在nat output中单独处理，控制机内走tcp代理的名单)
	# ----------------------------------------------------------------------
	# 1.  gfw黑名单模式 ：
	#     构想：{gfwlist}走代理，其他走直连
	#     加黑：{gfwlist,black_list}走代理，其他走直连
	#     加白：{white_list}走直连，{gfwlist,black_list}走代理，其他走直连（white black冲突的话，以white为优先）
	#           {white_list}需要在{gfwlist}之前，不然不能达到{white_list}不走代理的目的
	#	  问题：{ignlist}理论上不需要处理，但是{gfwlist,black_list}是有可能解析到127.0.0.1的，会导致出问题，所以还是需要处理下：
	#     修正：{ignlist,white_list}走直连，{gfwlist,black_list}走代理，其他走直连
	#      DNS：{white_list domain}走chinadns-ng dnl组1解析，添加解析到ipset：white_list，{white_list ip}直接加入到ipset：white_list
	#           {black_list domain}走chinadns-ng dnl组2解析，添加解析到ipset：black_list，{black_list ip}直接加入到ipset：black_list
	#
	# 2.  大陆白名单模式（白名单优先模式，fancyss一直采用的方式）：
	#     构想：{ignlist,chnlist,chnroute}走直连，其余走代理
	#           先匹配白名单不走代理，再匹配黑名单走代理，目的先保证国内访问正常，再去翻墙。
	#			但是如果某个域名的三级域名aaa.gfw.com被墙，二级域名gfw.com没有被墙
	#			此时，gfw.com和aaa.gfw.com都会被{chnlist}匹配到，如果在iptables中，使用白名单优先模式，则都会走直连。
	#     设计：{black_list}走代理，{ignlist,chnlist,chnroute,white_list}走直连，其余走代理
	#	  问题：{ignlist}理论上在{black_list}之后，但是{black_list}是有可能解析到127.0.0.1，导致出问题，所以还是需要处理下：
	#     修正：{ignlist}走直连，{black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	#           1. 修正后：如果不存在black_list，则与原设计一样
	#           2. 修正后：如果不存在black_list和white_list，则与原构想一样
	#
	# 3.  大陆白名单模式（黑名单优先模式，ss-tproxy采用的方式）：
	#     构想：{gfwlist}走代理，{ignlist,chnlist,chnroute}走直连，其余走代理
	#           目的保证走代理的域名，比如aaa.gfw.com被墙，但是gfw.com没有被墙
	#           此时aaa.gfw.com被{gfwlist}匹配后顺利走代理，gfw.com被{chnlist}匹配后不走代理
	#     设计：{gfwlist,black_list}走代理，{ignlist,chnlist,chnroute,white_list}走直连，其余走代理
	#	  问题：{ignlist}理论上在{gfwlist}之后，但是{gfwlist}是有可能解析到127.0.0.1，导致出问题，所以还是需要处理下：
	#     修正：{ignlist}走直连，{gfwlist,black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	#
	#     大陆白名单模式总结：
	# 2   修正：{ignlist}走直连，{black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	# 3   修正：{ignlist}走直连，{gfwlist,black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	# 			修正两者差别仅仅在于3.1黑名单模式优先情况下多了gfwlist的一次匹配
	# 			但是如果某个{white_list}域名存在于{gfwlist}中，则会导致用户白名单失效
	#			而2.1白名单优先情况下不存在此问题，所以2.1效果最好
	# 			
	# 2.1 最终：SHADOWSOCKS链: 访问控制 ──┬─── SHADOWSOCKS_CHN链: {ignlist}走直连，{black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	# 			                          ├─── SHADOWSOCKS_GFW链: {ignlist,white_list}走直连，{gfwlist,black_list}走代理，其他走直连
	#									  └─── SHADOWSOCKS_GLO链: {ignlist}走直连，其他走代理
	#
	# 			稍作调整，可以把{ignlist}全部调到前面
	#
	# 2.1 最终：SHADOWSOCKS链: {ignlist} -访问控制 ──┬─── SHADOWSOCKS_CHN链: {black_list}走代理，{chnlist,chnroute,white_list}走直连，其余走代理
	# 			                          			 ├─── SHADOWSOCKS_GFW链: {white_list}走直连，{gfwlist,black_list}走代理，其他走直连
	#									  			 ├─── SHADOWSOCKS_GLO链: {white_list}走直连，其他走代理
	#									  			 └─── SHADOWSOCKS_HOM链: {black_list}走代理，{gfwlist,white_list}走直连，其他走代理
	# 			
	# note-1：大陆白名单模式时，{black_list domain}走chinadns-ng dnl组1解析，{black_list ip}直接加入到ipset，{white_list domain}走chinadns-ng dnl组2解析
	# 4.  全局模式：{ignlist}走直连，其他走代理
	# ----------------------------------------------------------------------
	#
	# 回国模式：
	# 在国外访问大陆网站时，可能会出现ip区域限制等问题，导致无法正常使用大陆网络服务
	# 此时可以使用"回国模式"，通过代理回到国内，摆脱ip区域限制等问题，原理与翻墙类似
	# 1. 回国模式1 ：{black_list}走代理，{gfwlist,white_list}走直连，其他走代理
	#    {gfwlist,white_list}用国外当地DNS解析，其他走可信DNS解析（为了cdn）
	#	 {black_list}  dln1  可信DNS
	#	 {white_list}  dln2  本地DNS
	#	 {gfwlist} 	   gfw   本地DNS
	#	 default tag   chn   可信DNS
	# 2. 回国模式2 ：{white_list}走直连，{chnlist,black_list}走代理，其他走直连
	#    {chnlist,black_list}可信度DNS解析（为了cdn），其余用国外当地DNS解析
	#	 {white_list}  dln1  本地DNS
	#	 {black_list}  dln2  可信DNS
	#	 {chnlist} 	   chn   可信DNS
	#	 default tag   gfw   本地DNS

	# remove 
	rm -rf /tmp/black_list.txt
	rm -rf /tmp/white_list.txt
	rm -rf /tmp/block_list.txt
	rm -rf /tmp/chnlist.txt
	rm -rf /tmp/gfwlist.txt
	rm -rf /tmp/chnroute.txt
	rm -rf /tmp/chnroute6.txt

	# copy gfwlist.txt & chnlist.txt to tmp
	echo_date "创建/tmp/chnlist.txt 和 /tmp/gfwlist.txt！"
	if [ "${ss_basic_mode}" = "7" ] && type fss_shunt_export_runtime_base_rules >/dev/null 2>&1; then
		if fss_shunt_export_runtime_base_rules; then
			echo_date "通过geotool批量导出基础规则：chnlist / gfwlist / chnroute / chnroute6。"
		else
			echo_date "geotool批量导出基础规则失败，回退使用内置txt/gz规则。"
			gzip -d -c /koolshare/ss/rules/chnlist.gz >/tmp/chnlist.txt
			gzip -d -c /koolshare/ss/rules/gfwlist.gz >/tmp/gfwlist.txt
		fi
	else
		gzip -d -c /koolshare/ss/rules/chnlist.gz >/tmp/chnlist.txt
		gzip -d -c /koolshare/ss/rules/gfwlist.gz >/tmp/gfwlist.txt
	fi
	#cp -rf /koolshare/ss/rules/chnlist.txt /tmp/chnlist.txt
	#cp -rf /koolshare/ss/rules/gfwlist.txt /tmp/gfwlist.txt
	
	# {router} foreign dns ip go proxy inside router
	ipset -! add router 8.8.8.8 >/dev/null 2>&1
	ipset -! add router 8.8.4.4 >/dev/null 2>&1
	ipset -! add router 1.1.1.1 >/dev/null 2>&1
	ipset -! add router 9.9.9.9 >/dev/null 2>&1
	ipset -! add router 9.9.9.10 >/dev/null 2>&1
	ipset -! add router 9.9.9.11 >/dev/null 2>&1
	ipset -! add router 149.112.112.112 >/dev/null 2>&1
	ipset -! add router 149.112.112.11 >/dev/null 2>&1
	ipset -! add router 149.112.112.10 >/dev/null 2>&1

	# {ignlist},ip: reserve ip
	local ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 192.18.0.0/15 224.0.0.0/4 240.0.0.0/4 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 117.50.11.11 117.50.22.22 180.76.76.76 119.29.29.29"
	echo_date "应用ignlist"
	for ip in ${ip_lan}
	do
		ipset -! add ignlist $ip >/dev/null 2>&1
	done

	ipset -! add ignlist6 ::1/128 >/dev/null 2>&1
	ipset -! add ignlist6 fe80::/10 >/dev/null 2>&1
	
	# {black_list}, telegram ip
	if [ "${ss_basic_mode}" != "6" ]; then
		ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
		for ip in ${ip_tg}; do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi

	# {black_list}, black ip
	if [ -n "${ss_wan_black_ip}" ]; then
		ss_wan_black_ip=$(echo ${ss_wan_black_ip} | base64_decode | sed '/\#/d')
		echo_date "应用IP/CIDR黑名单"
		for ip in ${ss_wan_black_ip}; do
			ipset -! add black_list ${ip} >/dev/null 2>&1
		done
	fi

	# {black_list}, black domain
	local shunt_proxy_file=""
	echo_date "生成域名黑名单！"
	if [ "${ss_basic_mode}" = "7" ]; then
		shunt_proxy_file="$(fss_shunt_get_proxy_domain_file 2>/dev/null)"
	fi
	{
		printf '%s\n' ip.sb api.skk.moe ip.skk.moe ipinfo.io ip-api.com us.ip111.cn
		[ -n "${ss_wan_black_domain}" ] && fss_b64_decode "${ss_wan_black_domain}"
		[ "${ss_basic_proxy_newb}" = "1" ] && printf '%s\n' "bing.com"
		[ -n "${shunt_proxy_file}" ] && [ -s "${shunt_proxy_file}" ] && cat "${shunt_proxy_file}"
	} | awk '
		{
			gsub(/\r/, "")
			sub(/#.*/, "")
			for (i = 1; i <= NF; i++) {
				domain = tolower($i)
				gsub(/^[*.]+/, "", domain)
				if (domain ~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/ && !seen[domain]++) {
					print domain
				}
			}
		}
	' > /tmp/black_list.txt

	# {white_list}, white ip
	[ -n "${ss_basic_server_ip}" ] && SBSI="${ss_basic_server_ip}" || SBSI=""
	[ -n "${ISP_DNS1}" ] && ISP_DNS_a="${ISP_DNS1}" || ISP_DNS_a=""
	[ -n "${IFIP_DNS2}" ] && ISP_DNS_b="${ISP_DNS2}" || ISP_DNS_b=""
	local ALL_NODE_DOMAINS=$(dbus list ssconf|grep _server_|awk -F"=" '{print $NF}'|sort -u|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	ss_wan_white_ip=$(echo ${ss_wan_white_ip} | base64_decode | sed '/\#/d')
	echo_date "应用IP/CIDR白名单"
	for ip in ${ss_wan_white_ip} ${ALL_NODE_DOMAINS}
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done

	# {white_list}, white domain
	true >/tmp/white_list.txt
	echo_date "生成域名白名单！"
	local ALL_NODE_DOMAINS=$(dbus list ssconf|grep _server_|awk -F"=" '{print $NF}'|sort -u|grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	local wanwhitedomains=$(echo ${ss_wan_white_domain} | base64_decode | sed '/^#/d' | grep "." | sort -u)
	local ALL_WHITE_DOMAINS=$(echo ${wanwhitedomains} ${ALL_NODE_DOMAINS})
	if [ -n "${ALL_WHITE_DOMAINS} " ]; then
		for wan_white_domain in ${ALL_WHITE_DOMAINS}; do
			if [ -n "$(is_domain ${wan_white_domain})" ]; then
				echo ${wan_white_domain} >>/tmp/white_list.txt
			fi
		done
	fi	

	for wan_white_domain2 in "apple.com" "microsoft.com" "dns.msftncsi.com" "worldtimeapi.org"; do
		echo "${wan_white_domain2}" >>/tmp/white_list.txt
	done

	# {block_list}
	cp -rf /koolshare/ss/rules/block_list.txt /tmp
}

create_dnsmasq_conf() {
	# 0. delete pre settings
	rm -rf /tmp/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/scripts/dnsmasq.postconf
	rm -rf /jffs/scripts/dnsmasq-sdn.postconf

	# 2. custom dnsmasq settings by user
	if [ -n "${ss_dnsmasq}" ]; then
		echo_date "添加自定义dnsmasq设置到/tmp/custom.conf"
		echo "${ss_dnsmasq}" | base64_decode | sort -u >>/tmp/custom.conf
	fi

	#ln_conf
	if [ -f /tmp/custom.conf ]; then
		#echo_date 创建域自定义dnsmasq配置文件软链接到/jffs/configs/dnsmasq.d/custom.conf
		ln -sf /tmp/custom.conf /jffs/configs/dnsmasq.d/custom.conf
	fi

	# echo_date 创建dnsmasq.postconf软连接到/jffs/scripts/文件夹.
	[ ! -L "/jffs/scripts/dnsmasq.postconf" ] && ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq.postconf

	VLAN_NU=$(ifconfig | grep -E "^br"|grep -v "br0"|wc -l)
	if [ "${VLAN_NU}" -ge "1" ]; then
		ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq-sdn.postconf
	fi
}

auto_start() {
	[ ! -L "/koolshare/init.d/S99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/S99shadowsocks.sh
	[ ! -L "/koolshare/init.d/N99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/N99shadowsocks.sh
}

start_ssr_redir() {
	echo_date "开启ssr-redir进程，用于透明代理."
	BIN=rss-redir
	ARG_OBFS=""
	if [ "${mangle}" == "1" ]; then
		# tcp udp go ss
		echo_date "${BIN}的 tcp 走${BIN}."
		echo_date "${BIN}的 udp 走${BIN}."
		fire_redir "rss-redir -c ${CONFIG_FILE} -u"
	else
		# tcp only go ss
		echo_date "${BIN}的 tcp 走${BIN}."
		echo_date "${BIN}的 udp 未开启."
		fire_redir "rss-redir -c ${CONFIG_FILE}"
	fi
	echo_date "${BIN} 启动完毕！"

	# start socks5，socks5端口默认提供，但目前监听在127.0.0.1，所有协议都需要开socks5端口，以前适用于dns tcp远程解析，未来用户开放给用户
	start_ssr_local
}

fire_redir() {
	local ARG_1 ARG_2 ARG_3
	if [ "$ss_basic_mcore" == "1" -a "${LINUX_VER}" != "26" ]; then
		echo_date "$BIN开启$THREAD线程支持."
		local i=1
		while [ $i -le $THREAD ]; do
			run_bg $1 $ARG_1 $ARG_2 $ARG_3 -f /var/run/ssr_$i.pid
			let i++
		done
	else
		run_bg $1 -f /var/run/ssr.pid
	fi
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

get_reverse_switch() {
	case "$1" in
	1)
		echo "false"
		;;
	0|*)
		echo "true"
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

get_value_speed(){
	if [ -n "$1" ]; then
		echo \"${1}mbps\"
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

get_value_congestion(){
	if [ -n "${ss_basic_hy2_up}" -a -n "${ss_basic_hy2_dl}" ]; then
		if [ -z "${ss_basic_hy2_cg}" ];then
			# 之前的版本没有开放此选项，帮用户设置为brutal
			echo \"brutal\"
		else
			# 上下行都设置了且正确，此时可以使用用户选择的congestion
			echo \"$1\"
		fi
	elif [ -z "${ss_basic_hy2_up}" -a -z "${ss_basic_hy2_dl}" ]; then
		echo \"bbr\"
	fi
}

get_hy2_port(){
	local _match1=$(echo $1 | grep -Eo ",")
	local _match2=$(echo $1 | grep -Eo "-")
	if [ -z "${_match1}" -a -z "${_match2}" ]; then
		# single port
		echo "$1"
	else
		# multi port or port range
		echo null
	fi
}

get_hy2_udphop_port(){
	local _match1=$(echo $1 | grep -Eo ",")
	local _match2=$(echo $1 | grep -Eo "-")
	if [ -z "${_match1}" -a -z "${_match2}" ]; then
		# single port
		echo \"\"
	else
		# multi port or port range
		echo \"$1\"
	fi
}

creat_vmess_json() {
	if [ -z "{WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建vmess配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建vmess配置文件到${VMESS_CONFIG_FILE}"
	fi
	
	rm -rf "${VMESS_CONFIG_TEMP}"
	rm -rf "${VMESS_CONFIG_FILE}"
	if [ "${ss_basic_v2ray_use_json}" != "1" ]; then
		echo_date 生成vmess协议配置文件...
		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"

		if [ "$ss_basic_v2ray_mux_enable" == "1" -a -z "$ss_basic_v2ray_mux_concurrency" ];then
			local ss_basic_v2ray_mux_concurrency=8
		fi

		if [ "$ss_basic_v2ray_mux_enable" != "1" ];then
			local ss_basic_v2ray_mux_concurrency="-1"
		fi
		
		if [ -z "$ss_basic_v2ray_network_security" ];then
			local ss_basic_v2ray_network_security="none"
		fi

		if [ "$ss_basic_v2ray_network_security" == "none" ];then
			ss_basic_v2ray_network_security_ai=""
			ss_basic_v2ray_network_security_alpn_h2=""
			ss_basic_v2ray_network_security_alpn_http=""
			ss_basic_v2ray_network_security_sni=""
		fi

		local alpn_h2=${ss_basic_v2ray_network_security_alpn_h2}
		local alpn_ht=${ss_basic_v2ray_network_security_alpn_http}

		if [ "${alpn_h2}" == "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"h2\",\"http/1.1\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"http/1.1\"]"
		elif [ "${alpn_h2}" == "1" -a "${alpn_ht}" != "1" ];then
			local apln="[\"h2\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" != "1" ];then
			local apln="null"
		fi

		# 如果sni空，host不空，用host代替
		if [ -z "${ss_basic_v2ray_network_security_sni}" ];then
			if [ -n "${ss_basic_v2ray_network_host}" ];then
				local ss_basic_v2ray_network_security_sni="${ss_basic_v2ray_network_host}"
			else
				local ss_basic_v2ray_network_security_sni=""
			fi
		fi

		# 如果sni空，host空，用server domain代替
		if [ -z "${ss_basic_v2ray_network_security_sni}" -a -z "${ss_basic_v2ray_network_host}" ];then
			# 判断是否域名，是就填入
			tmp=$(__valid_ip "${ss_basic_server_orig}")
			if [ $? == 0 ]; then
				# server is ip address format
				local ss_basic_v2ray_network_security_sni=""
			else
				# likely to be domain
				local ss_basic_v2ray_network_security_sni="${ss_basic_server_orig}"
			fi
		fi

		if [ "${ss_basic_v2ray_network_security}" == "tls" ];then
			local tls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_v2ray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_v2ray_network_security_sni)
					}"
		else
			local tls="null"
		fi

		# incase multi-domain input
		if [ "$(echo $ss_basic_v2ray_network_host | grep ",")" ]; then
			ss_basic_v2ray_network_host=$(echo $ss_basic_v2ray_network_host | sed 's/,/", "/g')
		fi

		case "$ss_basic_v2ray_network" in
		tcp)
			if [ "$ss_basic_v2ray_headtype_tcp" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(get_path_empty $ss_basic_v2ray_network_path)
					,\"headers\": {
					\"Host\": $(get_host_empty $ss_basic_v2ray_network_host),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$ss_basic_v2ray_headtype_kcp\"
				}
				,\"seed\": $(get_value_null $ss_basic_v2ray_kcp_seed)
				}"
			;;
		ws)
			if [ -z "$ss_basic_v2ray_network_path" -a -z "$ss_basic_v2ray_network_host" ]; then
				local ws="{}"
			elif [ -z "$ss_basic_v2ray_network_path" -a -n "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"headers\": $(get_ws_header $ss_basic_v2ray_network_host)
					}"
			elif [ -n "$ss_basic_v2ray_network_path" -a -z "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_v2ray_network_path)
					}"
			elif [ -n "$ss_basic_v2ray_network_path" -a -n "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_v2ray_network_path),
					\"headers\": $(get_ws_header $ss_basic_v2ray_network_host)
					}"
			fi
			;;
		h2)

			local h2="{
				\"path\": $(get_value_empty $ss_basic_v2ray_network_path)
				,\"host\": $(get_host $ss_basic_v2ray_network_host)
				}"
			;;
		quic)
			local qc="{
				\"security\": $(get_value_empty $ss_basic_v2ray_network_host),
				\"key\": $(get_value_empty $ss_basic_v2ray_network_path),
				\"header\": {
				\"type\": \"${ss_basic_v2ray_headtype_quic}\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(get_value_empty $ss_basic_v2ray_network_path),
				\"authority\": $(get_value_empty $ss_basic_v2ray_grpc_authority),
				\"multiMode\": $(get_grpc_multimode ${ss_basic_v2ray_grpc_mode})
				}"
			;;
		esac
		# log area
		cat >"${VMESS_CONFIG_TEMP}" <<-EOF
			{
			"log": {
				"access": "none",
				"error": "none",
				"loglevel": "none"
			},
		EOF
		
		# inbounds area (23456 for socks5)
		cat >>"$VMESS_CONFIG_TEMP" <<-EOF
			"inbounds": [
		EOF

		# when user use udp trust dns in chinadns-ng
		gen_xray_dns_inbound ${VMESS_CONFIG_TEMP}
		
		cat >>"$VMESS_CONFIG_TEMP" <<-EOF
				{
					"port": 23456,
					"listen": "127.0.0.1",
					"protocol": "socks",
					"settings": {
						"auth": "noauth",
						"udp": true,
						"ip": "127.0.0.1"
					}
				},
				{
					"listen": "0.0.0.0",
					"port": 3333,
					"protocol": "dokodemo-door",
					"settings": {
						"network": "tcp,udp",
						"followRedirect": true
					}
				}
			],
		EOF
		# outbounds area
		cat >>"$VMESS_CONFIG_TEMP" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "vmess",
					"settings": {
						"vnext": [
							{
								"address": "${ss_basic_server}",
								"port": $ss_basic_port,
								"users": [
									{
										"id": "$ss_basic_v2ray_uuid"
										,"alterId": $ss_basic_v2ray_alterid
										,"security": "$ss_basic_v2ray_security"
									}
								]
							}
						]
					},
					"streamSettings": {
						"network": "$ss_basic_v2ray_network"
						,"security": "$ss_basic_v2ray_network_security"
						,"tlsSettings": $tls
						,"tcpSettings": $tcp
						,"kcpSettings": $kcp
						,"wsSettings": $ws
						,"httpSettings": $h2
						,"quicSettings": $qc
						,"grpcSettings": $gr
					},
					"mux": {
						"enabled": $(get_function_switch $ss_basic_v2ray_mux_enable),
						"concurrency": $ss_basic_v2ray_mux_concurrency
					}
				}
			]
			}
		EOF
		echo_date "解析vmess协议配置文件..."
		run jq 'del(.. | nulls)' ${VMESS_CONFIG_TEMP} > /tmp/jq_strip_tmp.txt 2>/dev/null && mv /tmp/jq_strip_tmp.txt ${VMESS_CONFIG_TEMP}
		run jq --tab . ${VMESS_CONFIG_TEMP} >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . $VMESS_CONFIG_TEMP >"${VMESS_CONFIG_FILE}"
		echo_date "$vmess协议配置文件写入成功到${VMESS_CONFIG_FILE}"
		if ! append_xray_ipv6_tproxy_inbound "${VMESS_CONFIG_FILE}"; then
			echo_date "错误：追加IPv6透明代理入口到${VCORE_NAME}配置文件失败！"
			close_in_five flag
		fi
	else
		echo_date "使用自定义的${VCORE_NAME} json配置文件..."
		echo "$ss_basic_v2ray_json" | base64_decode >"$VMESS_CONFIG_TEMP"
		local OB=$(cat "$VMESS_CONFIG_TEMP" | run jq .outbound)
		local OBS=$(cat "$VMESS_CONFIG_TEMP" | run jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$VMESS_CONFIG_TEMP" | run jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$VMESS_CONFIG_TEMP" | run jq .outbounds[0])
		fi
		local TEMPLATE="{
							\"log\": {
								\"access\": \"none\",
								\"error\": \"none\",
								\"loglevel\": \"none\"
							},
							\"inbounds\": [
								{
									\"port\": 23456,
									\"listen\": \"127.0.0.1\",
									\"protocol\": \"socks\",
									\"settings\": {
										\"auth\": \"noauth\",
										\"udp\": true,
										\"ip\": \"127.0.0.1\",
										\"clients\": null
									},
									\"streamSettings\": null
								},
								{
									\"listen\": \"0.0.0.0\",
									\"port\": 3333,
									\"protocol\": \"dokodemo-door\",
									\"settings\": {
										\"network\": \"tcp,udp\",
										\"followRedirect\": true
									}
								}
							]
						}"
		echo_date "解析${VCORE_NAME}配置文件..."
		echo ${TEMPLATE} | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"$VMESS_CONFIG_FILE"
		echo_date "${VCORE_NAME}配置文件写入成功到$VMESS_CONFIG_FILE"
		if [ -n "${ss_basic_server}" ];then
			rewrite_xray_like_outbound_server "${VMESS_CONFIG_FILE}" "${ss_basic_server}"
		fi
		if ! append_xray_dns_relay_inbounds "${VMESS_CONFIG_FILE}"; then
			echo_date "错误：追加DNS UDP relay入口到${VCORE_NAME}配置文件失败！"
			close_in_five flag
		fi
		if ! append_xray_ipv6_tproxy_inbound "${VMESS_CONFIG_FILE}"; then
			echo_date "错误：追加IPv6透明代理入口到${VCORE_NAME}配置文件失败！"
			close_in_five flag
		fi

		if [ -n "${ss_basic_server_orig}" ]; then
			fss_set_current_node_field_plain server "${ss_basic_server_orig}"
		else
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+       没有检测到你的${VCORE_NAME}服务器地址，如果你确定你的配置是正确的        +"
			echo_date "+   请自行将${VCORE_NAME}服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用   +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		fi
	fi

	# test v2ray Configuration generated from user json then run by xray
	echo_date "测试${VCORE_NAME}配置文件...."
	test_xray_conf $VMESS_CONFIG_FILE
	case $? in
	0)
		echo_date "测试结果：${_test_ret}"
		echo_date "${VCORE_NAME}配置文件通过测试!!!"
		;;
	2)
		echo_date "测试结果：${_test_ret}"
		echo_date "${VCORE_NAME}配置文件没有通过测试，尝试删除fingerprint配置后重试！"
		run jq 'del(.. | .fingerprint?)' $VMESS_CONFIG_FILE | run sponge $VMESS_CONFIG_FILE
		test_xray_conf $VMESS_CONFIG_FILE
		case $? in
		0)
			echo_date "测试结果：${_test_ret}"
			echo_date "${VCORE_NAME}配置文件通过测试!!!"
			;;
		*)
			echo_date "测试结果：${_test_ret}"
			echo_date "${VCORE_NAME}配置文件没有通过测试，请检查设置!!!"
			rm -rf "$VMESS_CONFIG_TEMP"
			rm -rf "$VMESS_CONFIG_FILE"
			close_in_five flag
			;;
		esac
		;;
	*)
		echo_date "测试结果：${_test_ret}"
		echo_date "${VCORE_NAME}配置文件没有通过测试，请检查设置!!!"
		rm -rf "$VMESS_CONFIG_TEMP"
		rm -rf "$VMESS_CONFIG_FILE"
		close_in_five flag
		;;
	esac
}

creat_xray_ss_json() {
	if [ -z "${WEB_ACTION}" ]; then
		# 非web提交
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建$(__get_type_abbr_name)节点配置文件到${VLESS_CONFIG_FILE}"
	fi

	# log area
	cat >"${SS_CONFIG_TEMP}" <<-EOF
		{
		"log": {
			"access": "none",
			"error": "none",
			"loglevel": "none"
		},
	EOF
	
	# inbounds area (23456 for socks5)
	cat >>"${SS_CONFIG_TEMP}" <<-EOF
		"inbounds": [
	EOF

	# when user use udp trust dns in chinadns-ng
	gen_xray_dns_inbound ${SS_CONFIG_TEMP}
	
	cat >>"${SS_CONFIG_TEMP}" <<-EOF
			{
				"port": 23456,
				"listen": "127.0.0.1",
				"protocol": "socks",
				"settings": {
					"auth": "noauth",
					"udp": true,
					"ip": "127.0.0.1"
				}
			},
			{
				"listen": "0.0.0.0",
				"port": 3333,
				"protocol": "dokodemo-door",
				"settings": {
					"network": "tcp,udp",
					"followRedirect": true
				}
			}
		],
	EOF
	# outbounds area
	if [ "${ss_basic_ss_obfs}" == "http" -o "${ss_basic_ss_obfs}" == "tls" ]; then
		# start obfs-local first
		echo_date "开启simple-obfs混淆..."

		if [ "${ss_basic_tfo}" == "1" -a "${LINUX_VER}" != "26" ]; then
			local OBFS_ARG="--fast-open"
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			local OBFS_ARG=""
		fi

		local obfs_port=$(get_rand_port)
		if [ -n "${ss_basic_ss_obfs_host}" ]; then
			run_bg obfs-local -s ${ss_basic_server} -p ${ss_basic_port} -l ${obfs_port} --obfs ${ss_basic_ss_obfs} --obfs-host ${ss_basic_ss_obfs_host} ${OBFS_ARG} -f /var/run/obfs_local.pid
		else
			run_bg obfs-local -s ${ss_basic_server} -p ${ss_basic_port} -l ${obfs_port} --obfs ${ss_basic_ss_obfs} ${OBFS_ARG} -f /var/run/obfs_local.pid
		fi
		detect_running_status obfs-local /var/run/obfs_local.pid
		# gen xray outbound
		cat >>"${SS_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "shadowsocks",
					"settings": {
						"servers": [
							{
								"address": "127.0.0.1"
								,"port": ${obfs_port}
								,"password": "${ss_basic_password}"
								,"method": "${ss_basic_method}"
								,"uot": true
							}
						]
					},
					"streamSettings": {
						"network": "raw"
					},
					"sockopt": {
						"tcpFastOpen": $(get_function_switch ${ss_basic_tfo}),
						"tcpMptcp": false,
						"tcpcongestion": "bbr"
					}
				}
			]
			}
		EOF
	else
		# gen xray outbound
		cat >>"${SS_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "shadowsocks",
					"settings": {
						"servers": [
							{
								"address": "${ss_basic_server}"
								,"port": ${ss_basic_port}
								,"password": "${ss_basic_password}"
								,"method": "${ss_basic_method}"
								,"uot": false
							}
						]
					},
					"streamSettings": {
						"network": "raw"
					},
					"sockopt": {
						"tcpFastOpen": $(get_function_switch ${ss_basic_tfo}),
						"tcpMptcp": false,
						"tcpcongestion": "bbr"
					}			
				}
			]
			}
		EOF
	fi
	
	echo_date "解析Xray配置文件..."
	run jq 'del(.. | nulls)' ${SS_CONFIG_TEMP} > /tmp/jq_strip_tmp.txt 2>/dev/null && mv /tmp/jq_strip_tmp.txt ${SS_CONFIG_TEMP}
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${SS_CONFIG_TEMP} 2>/dev/null
	fi
	run jq --tab . $SS_CONFIG_TEMP >/tmp/jq_para_tmp.txt 2>&1
	if [ "$?" != "0" ];then
		echo_date "json配置解析错误，错误信息如下："
		echo_date $(cat /tmp/jq_para_tmp.txt) 
		echo_date "请更正你的错误然后重试！！"
		rm -rf /tmp/jq_para_tmp.txt
		close_in_five flag
	fi
	run jq --tab . ${SS_CONFIG_TEMP} >${SS_CONFIG_FILE}
	echo_date "Xray配置文件写入成功到${SS_CONFIG_FILE}"
	if ! append_xray_ipv6_tproxy_inbound "${SS_CONFIG_FILE}"; then
		echo_date "错误：追加IPv6透明代理入口到Xray配置文件失败！"
		close_in_five flag
	fi
}

creat_vless_json() {
	if [ -z "{WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建$(__get_type_abbr_name)节点配置文件到${VLESS_CONFIG_FILE}"
	fi

	local tmp xray_server_ip
	rm -rf "${VLESS_CONFIG_TEMP}"
	rm -rf "${VLESS_CONFIG_FILE}"
	if [ "${ss_basic_xray_use_json}" != "1" ]; then
		echo_date "生成Xray配置文件..."
		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"
		local reali="null"
		local xht="null"
		local htup="null"

		if [ -z "$ss_basic_xray_network_security" ];then
			local ss_basic_xray_network_security="none"
		fi
		[ -z "${ss_basic_xray_prot}" ] && ss_basic_xray_prot="vless"
		[ -z "${ss_basic_xray_encryption}" ] && ss_basic_xray_encryption="none"

		if [ "${ss_basic_xray_network_security}" == "none" ];then
			if [ "${ss_basic_xray_prot}" != "vless" ] || [ "${ss_basic_xray_encryption}" = "none" ];then
				ss_basic_xray_flow=""
			fi
			ss_basic_xray_network_security_ai=""
			ss_basic_xray_network_security_alpn_h2=""
			ss_basic_xray_network_security_alpn_http=""
			ss_basic_xray_network_security_sni=""
		fi

		#if [ "${ss_basic_xray_network_security}" == "tls" ];then
		#	ss_basic_xray_flow=""
		#fi

		local alpn_h2=${ss_basic_xray_network_security_alpn_h2}
		local alpn_ht=${ss_basic_xray_network_security_alpn_http}
		if [ "${alpn_h2}" == "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"h2\",\"http/1.1\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"http/1.1\"]"
		elif [ "${alpn_h2}" == "1" -a "${alpn_ht}" != "1" ];then
			local apln="[\"h2\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" != "1" ];then
			local apln="null"
		fi

		# 如果sni空，host不空，用host代替
		if [ -z "${ss_basic_xray_network_security_sni}" ];then
			if [ -n "${ss_basic_xray_network_host}" ];then
				local ss_basic_xray_network_security_sni="${ss_basic_xray_network_host}"
			else
				local ss_basic_xray_network_security_sni=""
			fi
		fi

		# 如果sni空，host空，用server domain代替
		if [ -z "${ss_basic_xray_network_security_sni}" -a -z "${ss_basic_xray_network_host}" ];then
			# 判断是否域名，是就填入
			tmp=$(__valid_ip "${ss_basic_server_orig}")
			if [ $? == 0 ]; then
				# server is ip address format
				local ss_basic_xray_network_security_sni=""
			else
				# likely to be domain
				local ss_basic_xray_network_security_sni="${ss_basic_server_orig}"
			fi
		fi

		if [ "${ss_basic_xray_network_security}" == "tls" ];then
			if [ -z "${ss_basic_xray_fingerprint}" ];then
				echo_date "fingerprint为空，默认使用chrome作为指纹"
				ss_basic_xray_fingerprint="chrome"
				fss_set_current_node_field_plain xray_fingerprint "chrome"
			fi
			# !!! warning: from 2026.06.1, allowInsecure will be removed, please use pcs and vcn as soon as possible.
			if [ "${ss_basic_xray_network_security_ai}" != "1" ];then
				local tls="{
						\"alpn\": ${apln}
						,\"serverName\": $(get_value_null ${ss_basic_xray_network_security_sni})
						,\"fingerprint\": $(get_value_empty ${ss_basic_xray_fingerprint})
						,\"pinnedPeerCertSha256\": $(get_value_empty ${ss_basic_xray_pcs})
						,\"verifyPeerCertByName\": $(get_value_empty ${ss_basic_xray_vcn})
						}"
			else
				local tls="{
						\"allowInsecure\": true
						,\"alpn\": ${apln}
						,\"serverName\": $(get_value_null ${ss_basic_xray_network_security_sni})
						,\"fingerprint\": $(get_value_empty ${ss_basic_xray_fingerprint})
						}"
			fi
		else
			local tls="null"
		fi

		if [ "${ss_basic_xray_network_security}" == "reality" ];then
			local reali="{
					\"show\": $(get_function_switch $ss_basic_xray_show)
					,\"fingerprint\": $(get_value_empty $ss_basic_xray_fingerprint)
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					,\"publicKey\": $(get_value_null $ss_basic_xray_publickey)
					,\"shortId\": $(get_value_empty $ss_basic_xray_shortid)
					,\"spiderX\": $(get_value_empty $ss_basic_xray_spiderx)
					}"
		else
			local reali="null"		
		fi
		# incase multi-domain input
		if [ "$(echo $ss_basic_xray_network_host | grep ",")" ]; then
			ss_basic_xray_network_host=$(echo ${ss_basic_xray_network_host} | sed 's/,/", "/g')
		fi

		case "${ss_basic_xray_network}" in
		tcp)
			if [ "${ss_basic_xray_headtype_tcp}" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(get_path_empty $ss_basic_xray_network_path)
					,\"headers\": {
					\"Host\": $(get_host_empty $ss_basic_xray_network_host),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$ss_basic_xray_headtype_kcp\"
				}
				,\"seed\": $(get_value_null $ss_basic_xray_kcp_seed)
				}"
			;;
		ws)
			if [ -z "$ss_basic_xray_network_path" -a -z "$ss_basic_xray_network_host" ]; then
				local ws="{}"
			elif [ -z "$ss_basic_xray_network_path" -a -n "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"headers\": $(get_ws_header $ss_basic_xray_network_host)
					}"
			elif [ -n "$ss_basic_xray_network_path" -a -z "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_xray_network_path)
					}"
			elif [ -n "$ss_basic_xray_network_path" -a -n "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_xray_network_path),
					\"headers\": $(get_ws_header $ss_basic_xray_network_host)
					}"
			fi
			;;
		h2)
			local h2="{
				\"path\": $(get_value_empty $ss_basic_xray_network_path)
				,\"host\": $(get_host $ss_basic_xray_network_host)
				}"
			;;
		quic)
			local qc="{
				\"security\": $(get_value_empty $ss_basic_xray_network_host),
				\"key\": $(get_value_empty $ss_basic_xray_network_path),
				\"header\": {
				\"type\": \"${ss_basic_xray_headtype_quic}\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(get_value_empty $ss_basic_xray_network_path),
				\"authority\": $(get_value_empty $ss_basic_xray_grpc_authority),
				\"multiMode\": $(get_grpc_multimode ${ss_basic_xray_grpc_mode})
				}"
			;;
		xhttp)
			local xht="{
				\"path\": $(get_value_empty $ss_basic_xray_network_path)
				,\"host\": $(get_value_empty $ss_basic_xray_network_host)
				,\"mode\": \"${ss_basic_xray_xhttp_mode}\"
				}"
			;;
		httpupgrade)
			local htup="{
				\"path\": $(get_value_empty $ss_basic_xray_network_path)
				,\"host\": $(get_value_empty $ss_basic_xray_network_host)
				}"
			;;
		esac
		# log area
		cat >"${VLESS_CONFIG_TEMP}" <<-EOF
			{
			"log": {
				"access": "none",
				"error": "none",
				"loglevel": "none"
			},
		EOF
		
		# inbounds area (23456 for socks5)
		cat >>"${VLESS_CONFIG_TEMP}" <<-EOF
			"inbounds": [
		EOF

		# when user use udp trust dns in chinadns-ng
		gen_xray_dns_inbound ${VLESS_CONFIG_TEMP}

		# continue
		cat >>"${VLESS_CONFIG_TEMP}" <<-EOF
				{
					"port": 23456,
					"listen": "127.0.0.1",
					"protocol": "socks",
					"settings": {
						"auth": "noauth",
						"udp": true,
						"ip": "127.0.0.1"
					}
				},
				{
					"listen": "0.0.0.0",
					"port": 3333,
					"protocol": "dokodemo-door",
					"settings": {
						"network": "tcp,udp",
						"followRedirect": true
					}
				}
			],
		EOF
		
		# outbounds area
		local xray_user_json
		if [ "${ss_basic_xray_prot}" = "vless" ];then
			xray_user_json=$(cat <<-EOF
									"id": "$ss_basic_xray_uuid"
									,"encryption": "$ss_basic_xray_encryption"
									,"flow": $(get_value_null $ss_basic_xray_flow)
			EOF
			)
		else
			[ -z "${ss_basic_xray_encryption}" -o "${ss_basic_xray_encryption}" = "none" ] && ss_basic_xray_encryption="auto"
			xray_user_json=$(cat <<-EOF
									"id": "$ss_basic_xray_uuid"
									,"security": "$ss_basic_xray_encryption"
			EOF
			)
		fi
		cat >>"${VLESS_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "${ss_basic_xray_prot}",
					"settings": {
						"vnext": [
							{
								"address": "${ss_basic_server}",
								"port": ${ss_basic_port},
								"users": [
									{
${xray_user_json}
									}
								]
							}
						]
					},
					"streamSettings": {
						"network": "$ss_basic_xray_network"
						,"security": "$ss_basic_xray_network_security"
						,"tlsSettings": $tls
						,"realitySettings": $reali
						,"tcpSettings": $tcp
						,"kcpSettings": $kcp
						,"wsSettings": $ws
						,"httpSettings": $h2
						,"quicSettings": $qc
						,"grpcSettings": $gr
						,"httpupgradeSettings": $htup
						,"xhttpSettings": $xht
						,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_tfo})}
					},
					"mux": {
						"enabled": false,
						"concurrency": -1
					}
				}
			]
			}
		EOF
		echo_date "解析Xray配置文件..."
		run jq 'del(.. | nulls)' ${VLESS_CONFIG_TEMP} > /tmp/jq_strip_tmp.txt 2>/dev/null && mv /tmp/jq_strip_tmp.txt ${VLESS_CONFIG_TEMP}
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' ${VLESS_CONFIG_TEMP} 2>/dev/null
		fi
		run jq --tab . $VLESS_CONFIG_TEMP >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . ${VLESS_CONFIG_TEMP} >${VLESS_CONFIG_FILE}
		echo_date "Xray配置文件写入成功到${VLESS_CONFIG_FILE}"
		if ! append_xray_ipv6_tproxy_inbound "${VLESS_CONFIG_FILE}"; then
			echo_date "错误：追加IPv6透明代理入口到Xray配置文件失败！"
			close_in_five flag
		fi
	else
		echo_date "使用自定义的Xray json配置文件..."
		echo "$ss_basic_xray_json" | base64_decode >"$VLESS_CONFIG_TEMP"
		local OB=$(cat "$VLESS_CONFIG_TEMP" | run jq .outbound)
		local OBS=$(cat "$VLESS_CONFIG_TEMP" | run jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$VLESS_CONFIG_TEMP" | run jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$VLESS_CONFIG_TEMP" | run jq .outbounds[0])
		fi
		local TEMPLATE="{
							\"log\": {
								\"access\": \"none\",
								\"error\": \"none\",
								\"loglevel\": \"none\"
							},
							\"inbounds\": [
								{
									\"port\": 23456,
									\"listen\": \"127.0.0.1\",
									\"protocol\": \"socks\",
									\"settings\": {
										\"auth\": \"noauth\",
										\"udp\": true,
										\"ip\": \"127.0.0.1\",
										\"clients\": null
									},
									\"streamSettings\": null
								},
								{
									\"listen\": \"0.0.0.0\",
									\"port\": 3333,
									\"protocol\": \"dokodemo-door\",
									\"settings\": {
										\"network\": \"tcp,udp\",
										\"followRedirect\": true
									}
								}
							]
						}"
		
		echo_date "解析Xray配置文件..."
		echo ${TEMPLATE} | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"${VLESS_CONFIG_FILE}"
		echo_date "Xray配置文件写入成功到${VLESS_CONFIG_FILE}"
		if [ -n "${ss_basic_server}" ];then
			rewrite_xray_like_outbound_server "${VLESS_CONFIG_FILE}" "${ss_basic_server}"
		fi
		if ! append_xray_dns_relay_inbounds "${VLESS_CONFIG_FILE}"; then
			echo_date "错误：追加DNS UDP relay入口到Xray配置文件失败！"
			close_in_five flag
		fi
		if ! append_xray_ipv6_tproxy_inbound "${VLESS_CONFIG_FILE}"; then
			echo_date "错误：追加IPv6透明代理入口到Xray配置文件失败！"
			close_in_five flag
		fi

		if [ -n "${ss_basic_server_orig}" ]; then
			fss_set_current_node_field_plain server "${ss_basic_server_orig}"
		else
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+       没有检测到你的Xray服务器地址，如果你确定你的配置是正确的        +"
			echo_date "+   请自行将Xray服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用   +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		fi
	fi
	
	# test xray Configuration run by xray
	test_xray_conf $VLESS_CONFIG_FILE
	case $? in
	0)
		echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件通过测试!!!"
		;;
	2)
		#echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件没有通过测试，尝试删除fingerprint配置后重试！"
		run jq 'del(.. | .fingerprint?)' $VLESS_CONFIG_FILE | run sponge $VLESS_CONFIG_FILE
		test_xray_conf $VLESS_CONFIG_FILE
		case $? in
		0)
			echo_date "测试结果：${_test_ret}"
			echo_date "Xray配置文件通过测试!!!"
			;;
		*)
			echo_date "测试结果：${_test_ret}"
			echo_date "Xray配置文件没有通过测试，请检查设置!!!"
			rm -rf "$VLESS_CONFIG_TEMP"
			rm -rf "$VLESS_CONFIG_FILE"
			close_in_five flag
			;;
		esac
		;;
	*)
		echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件没有通过测试，请检查设置!!!"
		rm -rf "$VLESS_CONFIG_TEMP"
		rm -rf "$VLESS_CONFIG_FILE"
		close_in_five flag
		;;
	esac
}

creat_shunt_json() {
	local current_id=""
	local shunt_config="/koolshare/ss/xray.json"

	current_id="$(fss_shunt_get_default_node_id)"
	[ -n "${current_id}" ] || current_id="${ssconf_basic_node}"
	echo_date "创建xray分流配置文件到${shunt_config}"
	rm -f "${shunt_config}"
	fss_shunt_build_xray_config "${shunt_config}" "${current_id}" || {
		echo_date "错误：xray分流配置生成失败，请检查兜底节点和分流规则设置。"
		close_in_five flag
	}
	test_xray_conf "${shunt_config}"
	case "$?" in
	0)
		echo_date "测试结果：${_test_ret}"
		echo_date "xray分流配置文件通过测试。"
		;;
	2)
		echo_date "测试结果：${_test_ret}"
		echo_date "检测到当前Xray-core版本不支持fingerprint，自动移除后重试。"
		run jq 'del(.. | .fingerprint?)' "${shunt_config}" | run sponge "${shunt_config}"
		test_xray_conf "${shunt_config}"
		case "$?" in
		0)
			echo_date "测试结果：${_test_ret}"
			echo_date "xray分流配置文件通过测试。"
			;;
		*)
			echo_date "测试结果：${_test_ret}"
			echo_date "xray分流配置文件没有通过测试，请检查当前节点和分流规则。"
			rm -f "${shunt_config}"
			close_in_five flag
			;;
		esac
		;;
	*)
		echo_date "测试结果：${_test_ret}"
		echo_date "xray分流配置文件没有通过测试，请检查当前节点和分流规则。"
		rm -f "${shunt_config}"
		close_in_five flag
		;;
	esac
}

start_xray() {
	# tfo start
	if [ "${LINUX_VER}" != "26" ]; then
		if [ "$ss_basic_tfo" == "1" ]; then
			echo_date "开启tcp fast open支持."
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			echo 1 >/proc/sys/net/ipv4/tcp_fastopen
		fi
	fi
	# xray start
	echo_date "开启Xray主进程..."
	cd /koolshare/bin
	local xray_asset_dir=""
	if [ "$(get_runtime_proxy_mode)" = "7" ] && type fss_shunt_xray_asset_dir >/dev/null 2>&1; then
		xray_asset_dir="$(fss_shunt_xray_asset_dir 2>/dev/null || true)"
	fi
	if [ -n "${xray_asset_dir}" ]; then
		run_bg env "xray.location.asset=${xray_asset_dir}" /koolshare/bin/xray run -c /koolshare/ss/xray.json
	else
		run_bg /koolshare/bin/xray run -c /koolshare/ss/xray.json
	fi
	detect_running_status3 xray 23456 0 force
}

creat_trojan_json(){
	# do not create json file on start
	if [ -z "${WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建xray的trojan配置文件到${TROJAN_CONFIG_FILE}"
	fi

	# trojan协议由xray来运行
	rm -rf "${TROJAN_CONFIG_TEMP}"
	rm -rf "${TROJAN_CONFIG_FILE}"
	# log area
	cat >"${TROJAN_CONFIG_TEMP}" <<-EOF
		{
		"log": {
			"access": "none",
			"error": "none",
			"loglevel": "none"
		},
	EOF

	# inbounds area (23456 for socks5)
	cat >>"$TROJAN_CONFIG_TEMP" <<-EOF
		"inbounds": [
	EOF

	# when user use udp trust dns in chinadns-ng
	gen_xray_dns_inbound ${TROJAN_CONFIG_TEMP}
	
	cat >>"$TROJAN_CONFIG_TEMP" <<-EOF
			{
				"port": 23456,
				"listen": "127.0.0.1",
				"protocol": "socks",
				"settings": {
					"auth": "noauth",
					"udp": true,
					"ip": "127.0.0.1"
				}
			},
			{
				"listen": "0.0.0.0",
				"port": 3333,
				"protocol": "dokodemo-door",
				"settings": {
					"network": "tcp,udp",
					"followRedirect": true
				}
			}
		],
	EOF
	
	if [ -n "${ss_basic_trojan_plugin}" -a "${ss_basic_trojan_plugin}" == "obfs-local" -a "${ss_basic_trojan_obfs}" == "websocket" ];then
		echo_date "检测到该trojan节点为obfs-local WebSocket伪装，继续！"
		local _trojan_network="ws"
		local _trojan_ws="{
						 	\"path\": \"${ss_basic_trojan_obfsuri}\",
						 	\"headers\": {
						 		\"Host\": \"${ss_basic_trojan_obfshost}\"
						 	}
						 }"
	else
		local _trojan_network="tcp"
		local _trojan_ws=null
	fi
	
	# outbounds area
	cat >>"${TROJAN_CONFIG_TEMP}" <<-EOF
		"outbounds": [
			{
				"protocol": "trojan",
				"settings": {
					"servers": [{
					"address": "${ss_basic_server}",
					"port": ${ss_basic_port},
					"password": "${ss_basic_trojan_uuid}"
					}]
				},
				"streamSettings": {
					"network": "${_trojan_network}",
					"security": "tls",
					"tlsSettings": {
						"serverName": $(get_value_null ${ss_basic_trojan_sni}),
						"pinnedPeerCertSha256": $(get_value_empty ${ss_basic_trojan_pcs}),
						"verifyPeerCertByName": $(get_value_empty ${ss_basic_trojan_vcn}),
						"allowInsecure": $(get_function_switch ${ss_basic_trojan_ai})
					}
					,"wsSettings": ${_trojan_ws}
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_trojan_tfo})}
				}
			}
		]
		}
	EOF
	echo_date "解析xray的trojan配置文件..."
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TROJAN_CONFIG_TEMP} 2>/dev/null
	fi
	run jq --tab . ${TROJAN_CONFIG_TEMP} >/tmp/trojan_para_tmp.txt 2>&1
	if [ "$?" != "0" ];then
		echo_date "json配置解析错误，错误信息如下："
		echo_date $(cat /tmp/trojan_para_tmp.txt) 
		echo_date "请更正你的错误然后重试！！"
		rm -rf /tmp/trojan_para_tmp.txt
		close_in_five flag
	fi
	run jq --tab . ${TROJAN_CONFIG_TEMP} >${TROJAN_CONFIG_FILE}
	echo_date "解析成功！xray的trojan配置文件成功写入到${TROJAN_CONFIG_FILE}"
	if ! append_xray_ipv6_tproxy_inbound "${TROJAN_CONFIG_FILE}"; then
		echo_date "错误：追加IPv6透明代理入口到Xray配置文件失败！"
		close_in_five flag
	fi
}

start_trojan(){
	# tfo
	if [ "${LINUX_VER}" != "26" ]; then
		if [ "${ss_basic_trojan_tfo}" == "1" ]; then
			echo_date Trojan协议开启tcp fast open支持.
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			echo 1 >/proc/sys/net/ipv4/tcp_fastopen
		fi
	fi

	echo_date "开启Xray主进程，用以运行trojan协议节点..."
	cd /koolshare/bin
	run_bg /koolshare/bin/xray run -c $TROJAN_CONFIG_FILE
	detect_running_status3 xray 23456 0 force
}

creat_hy2_json(){
	# do not create json file on start
	if [ -z "${WEB_ACTION}" ]; then
		if [ -n "${WAN_ACTION}" ]; then
			echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
			return 0
		fi
	else
		echo_date "创建xray的hysteria2配置文件到${HY2_CONFIG_FILE}"
	fi

	# hysteria2协议由xray来运行
	rm -rf "${HY2_CONFIG_TEMP}"
	rm -rf "${HY2_CONFIG_FILE}"
	
	# log area
	cat >"${HY2_CONFIG_TEMP}" <<-EOF
		{
		"log": {
			"access": "none",
			"error": "none",
			"loglevel": "none"
		},
	EOF
	
	# inbounds area (23456 for socks5)
	cat >>"$HY2_CONFIG_TEMP" <<-EOF
		"inbounds": [
	EOF

	# when user use udp trust dns in chinadns-ng
	gen_xray_dns_inbound ${HY2_CONFIG_TEMP}
	
	# continue
	cat >>"$HY2_CONFIG_TEMP" <<-EOF
			{
				"port": 23456,
				"listen": "127.0.0.1",
				"protocol": "socks",
				"settings": {
					"auth": "noauth",
					"udp": true,
					"ip": "127.0.0.1"
				}
			},
			{
				"listen": "0.0.0.0",
				"port": 3333,
				"protocol": "dokodemo-door",
				"settings": {
					"network": "tcp,udp",
					"followRedirect": true
				}
			}
		],
	EOF

	if [ -z "${ss_basic_hy2_sni}" ];then
		__valid_ip_silent "${ss_basic_hy2_server}"
		if [ "$?" != "0" ];then
			# not ip, should be a domain
			ss_basic_hy2_sni=${ss_basic_hy2_server}
		else
			ss_basic_hy2_sni=""
		fi
	else
		ss_basic_hy2_sni="${ss_basic_hy2_sni}"
	fi

	# 避免用户输入单位，检测下是否是纯数值
	if [ $(number_test ${ss_basic_hy2_up}) != "0" ];then
		echo_date "错误！当前hysteria2节点上行速度设置不正确，请输入纯数字！"
		close_in_five
	fi
	if [ $(number_test ${ss_basic_hy2_dl}) != "0" ];then
		echo_date "错误！当前hysteria2节点下行速度设置不正确，请输入纯数字！"
		close_in_five
	fi

	# 默认情况：有 up/down 时 brutal，无 up/down 时 bbr: https://github.com/XTLS/Xray-core/issues/5546
	if [ -n "${ss_basic_hy2_up}" -a -z "${ss_basic_hy2_dl}" ]; then
		echo_date "错误！当前hysteria2节点设置了上行速度未设置下行！请更正！"
		close_in_five
	elif [ -z "${ss_basic_hy2_up}" -a -n "${ss_basic_hy2_dl}" ]; then
		echo_date "错误！当前hysteria2节点设置了下行速度未设置下行！请更正！"
		close_in_five
	elif [ -z "${ss_basic_hy2_up}" -a -z "${ss_basic_hy2_dl}" ]; then
		# 未设置上下行可以允许，但是congestion必须设置为bbr，设置逻辑在：get_value_congestion
		if [ -z "${ss_basic_hy2_cg}" ];then
			echo_date "提醒！hysteria2协议未设置上行和下行速度，拥塞算法将采用：bbr！"
		else
			echo_date "提醒！hysteria2协议未设置上行和下行速度，拥塞算法将采用：bbr，而不是你设置的：${ss_basic_hy2_cg}"
		fi
	elif [ -n "${ss_basic_hy2_up}" -a -n "${ss_basic_hy2_dl}" ]; then
		if [ -z "${ss_basic_hy2_cg}" ];then
			# 之前的版本没有开放此选项，帮用户设置为brutal
			echo_date "hysteria2协议拥塞算法将采用有上下行情况下的默认设置：brutal"
		else
			# 上下行都设置了且正确，此时可以使用用户选择的congestion
			echo_date "hysteria2协议拥塞算法将采用你设置的：${ss_basic_hy2_cg}"
		fi
	fi
	
	# outbounds area
	cat >>"${HY2_CONFIG_TEMP}" <<-EOF
		"outbounds": [
			{
				"protocol": "hysteria",
				"settings": {
					"version": 2,
					"address": "${ss_basic_server}",
					"port": $(get_hy2_port ${ss_basic_hy2_port})
				},
				"streamSettings": {
					"network": "hysteria",
					"hysteriaSettings": {
						"version": 2
						,"auth": $(get_value_empty ${ss_basic_hy2_pass})
						,"congestion": $(get_value_empty ${ss_basic_hy2_cg})
						,"up": $(get_value_speed ${ss_basic_hy2_up})
						,"down": $(get_value_speed ${ss_basic_hy2_dl})
						,"udphop": {
							"port": $(get_hy2_udphop_port ${ss_basic_hy2_port}),
							"interval": 30
						}
					}
					,"security": "tls"
					,"tlsSettings": {
						"serverName": "${ss_basic_hy2_sni}"
	EOF

	# !!! warning: from 2026.06.1, allowInsecure will be removed, please use pcs and vcn as soon as possible.
	if [ "${ss_basic_hy2_ai}" != "1" ];then
		cat >>"${HY2_CONFIG_TEMP}" <<-EOF
							,"pinnedPeerCertSha256": $(get_value_empty ${ss_basic_hy2_pcs})
							,"verifyPeerCertByName": $(get_value_empty ${ss_basic_hy2_vcn})
		EOF
	else
		cat >>"${HY2_CONFIG_TEMP}" <<-EOF
							,"allowInsecure": true
		EOF
	fi
	
	cat >>"${HY2_CONFIG_TEMP}" <<-EOF
						,"alpn": ["h3"]
					}
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_hy2_tfo})}
	EOF

	if [ "${ss_basic_hy2_obfs}" == "1" -a -n "${ss_basic_hy2_obfs_pass}" ];then
		cat >>"${HY2_CONFIG_TEMP}" <<-EOF
					,"finalmask": {
						"udp": [
						{
							"type": "salamander",
							"settings": {
								"password": "${ss_basic_hy2_obfs_pass}"
							}
						}]
					}
		EOF
	fi
					
	cat >>"${HY2_CONFIG_TEMP}" <<-EOF
				}
			}
		]
		}
	EOF
	echo_date "解析xray的hysteria2配置文件..."
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${HY2_CONFIG_TEMP} 2>/dev/null
	fi
	run jq --tab . ${HY2_CONFIG_TEMP} >/tmp/hy2_para_tmp.txt 2>&1
	if [ "$?" != "0" ];then
		echo_date "json配置解析错误，错误信息如下："
		echo_date $(cat /tmp/hy2_para_tmp.txt) 
		echo_date "请更正你的错误然后重试！！"
		#rm -rf /tmp/hy2_para_tmp.txt
		close_in_five flag
	fi
	run jq --tab . ${HY2_CONFIG_TEMP} >${HY2_CONFIG_FILE}
	echo_date "解析成功！xray的hysteria2配置文件成功写入到${HY2_CONFIG_FILE}"
	if ! append_xray_ipv6_tproxy_inbound "${HY2_CONFIG_FILE}"; then
		echo_date "错误：追加IPv6透明代理入口到Xray配置文件失败！"
		close_in_five flag
	fi
}

start_hy2(){
	# tfo
	if [ "${LINUX_VER}" != "26" ]; then
		if [ "${ss_basic_hy2_tfo}" == "1" ]; then
			echo_date "hysteria2协议开启tcp fast open支持"
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			echo 1 >/proc/sys/net/ipv4/tcp_fastopen
		fi
	fi

	echo_date "开启Xray主进程，用以运行hysteria2协议节点..."
	cd /koolshare/bin
	run_bg /koolshare/bin/xray run -c $HY2_CONFIG_FILE
	detect_running_status3 xray 23456 0 force
}


start_naive(){
	if [ -f "/koolshare/bin/naive" ];then
		chmod +x /koolshare/bin/naive
		local ret=$(run /koolshare/bin/naive --version 2>&1)
		if [ -z "${ret}" ];then
			echo_date "检测到/koolshare/bin/目录下存在naive文件，但是无法运行！"
			echo_date "请确保你下载了正确的二进制文件！"
			close_in_five flag
		fi
	else
		local pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
		echo_date ""
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date ""
		echo_date "重要提醒！！"
		echo_date ""
		echo_date "检测到你需要使用naive！但是本插件默认没有提供相关的二进制文件！"
		echo_date "请前往下面的链接下载naive二进制，并将其放置在路由器的/koolshare/bin目录后重启插件！"
		echo_date "https://raw.githubusercontent.com/hq450/fancyss/3.0/fancyss/bin-${pkg_arch}/naive"
		echo_date ""
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date ""
		close_in_five flag
	fi
	
	echo_date "开启ipt2socks进程..."
	run_bg ipt2socks -p 23456 -l 3333 -b 0.0.0.0 -B :: -n 10000 -R
	detect_running_status2 ipt2socks 23456
	
	echo_date "开启NaïveProxy主进程..."
	if server_resolv_mode_is_preresolve && [ -n "${ss_basic_server_ip}" ] && [ -n "$(is_domain "${ss_basic_server_orig}")" ];then
		run_bg naive --listen=socks://127.0.0.1:23456 --proxy=${ss_basic_naive_prot}://${ss_basic_naive_user}:${ss_basic_password}@${ss_basic_server_orig}:${ss_basic_naive_port} --host-resolver-rules="MAP ${ss_basic_server_orig} ${ss_basic_server_ip}"
	else
		run_bg naive --listen=socks://127.0.0.1:23456 --proxy=${ss_basic_naive_prot}://${ss_basic_naive_user}:${ss_basic_password}@${ss_basic_server}:${ss_basic_naive_port}
	fi
	detect_running_status2 naive 23456
}

start_tuic(){
	if [ -f "/koolshare/bin/tuic-client" ];then
		chmod +x /koolshare/bin/tuic-client
		local ret=$(run /koolshare/bin/tuic-client --help 2>&1)
		if [ -z "${ret}" ];then
			echo_date "检测到/koolshare/bin/目录下存在tuic-client文件，但是无法运行！"
			echo_date "请确保你下载了正确的二进制文件！"
			close_in_five flag
		fi
	else
		local pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
		echo_date ""
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date ""
		echo_date "重要提醒！！"
		echo_date ""
		echo_date "检测到你需要使用tuic-client！但是当前/koolshare/bin目录下缺少此二进制文件！"
		echo_date "请前往下面的链接下载对应平台的tuic-client，并将其放置在路由器的/koolshare/bin目录后重启插件！"
		echo_date "https://raw.githubusercontent.com/hq450/fancyss/3.0/fancyss/bin-${pkg_arch}/tuic-client"
		echo_date ""
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date ""
		close_in_five flag
	fi
	
	rm -rf /koolshare/ss/tuic.json 2>/dev/null
	echo "${ss_basic_tuic_json}" | base64_decode >/tmp/tuic_tmp_1.json
	local RELAY=$(cat /tmp/tuic_tmp_1.json | run jq '.relay')

	echo_date "解析tuic配置文件..."
	echo "{\"local\": {\"server\": \"127.0.0.1:23456\"},\"log_level\": \"warn\"}" | run jq --argjson args "$RELAY" '. + {relay: $args}' >/koolshare/ss/tuic.json

	# 检测用户是否配置了ip地址
	local tuic_server_raw=$(cat /koolshare/ss/tuic.json | run jq -r '.relay.server')
	local tuic_server=""
	case "${tuic_server_raw}" in
	\[*\]:*)
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]:*}"
		;;
	\[*\])
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]}"
		;;
	*:* )
		tuic_server="${tuic_server_raw%:*}"
		;;
	*)
		tuic_server="${tuic_server_raw}"
		;;
	esac
	if [ -z "${tuic_server}" -o "${tuic_server}" == "null" ];then
		echo_date "检测到你的tuic配置文件未配置服务器地址/域名，请修改配置，退出！"
		close_in_five
	fi

	local tuic_server_is_domain=""
	[ -n "$(is_domain "${tuic_server}")" ] && tuic_server_is_domain="1"
	if [ -n "${tuic_server_is_domain}" ] && server_resolv_mode_is_preresolve && [ -n "${ss_basic_server_ip}" ];then
		echo_date "检测到tuic节点使用【预解析】模式，写入 relay.ip：${ss_basic_server_ip}"
		cat /koolshare/ss/tuic.json | run jq --arg addr "${ss_basic_server_ip}" '.relay.ip = $addr' | run sponge /koolshare/ss/tuic.json
	else
		cat /koolshare/ss/tuic.json | run jq 'del(.relay.ip)' | run sponge /koolshare/ss/tuic.json
		if [ -n "${tuic_server_is_domain}" ];then
			if server_resolv_mode_is_dynamic; then
				echo_date "检测到tuic节点使用【动态解析】模式，移除 relay.ip，保留 relay.server 域名直连解析。"
			else
				echo_date "检测到tuic节点未拿到有效的预解析结果，移除 relay.ip，保留 relay.server 继续启动。"
			fi
		else
			echo_date "检测到tuic配置server已直接使用ip地址：${tuic_server}，跳过域名解析。"
		fi
	fi
	
	echo_date "开启ipt2socks进程..."
	run_bg ipt2socks -p 23456 -l 3333 -b 0.0.0.0 -B :: -n 10000 -R
	detect_running_status2 ipt2socks 23456
	
	echo_date "开启tuic-client主进程..."
	run_bg tuic-client -c /koolshare/ss/tuic.json
	detect_running_status tuic-client
}

write_cron_job() {
	# 定时规则更新
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "${ss_basic_rule_update}" ]; then
		echo_date "⏰️fancyss规则定时更新任务启用，每天${ss_basic_rule_update_time}点自动检测更新规则."
		cru a ssupdate "0 ${ss_basic_rule_update_time} * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date "❎️fancyss规则定时更新任务未启用！"
	fi
	
	# 定时订阅
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "${ss_basic_node_update}" == "1" ]; then
		if [ "${ss_basic_node_update_day}" == "0" ]; then
			cru a ssnodeupdate "0 ${ss_basic_node_update_hr} * * * /koolshare/scripts/ss_node_subscribe.sh fancyss 3"
			echo_date "⏰️fancyss规则定时更新任务启用，每天${ss_basic_node_update_hr}点自动更新订阅。"
		else
			cru a ssnodeupdate "0 ${ss_basic_node_update_hr} * * ${ss_basic_node_update_day} /koolshare/scripts/ss_node_subscribe.sh fancyss 3"
			echo_date "⏰️fancyss规则定时更新任务启用，每周${ss_basic_node_update_day}的${ss_basic_node_update_hr}点自动更新订阅。"
		fi
	else
		echo_date "❎️fancyss定时更新订阅节点任务未启用！"
	fi
	
	# 定时webtest
	sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "${ss_basic_lt_cru_opts}" == "1" ]; then
		echo_date "⏰️fancyss 节点web落地延迟检测任务启用，设置每隔${ss_basic_lt_cru_time}分钟检测一次..."
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		cru a sslatencyjob "*/${ss_basic_lt_cru_time} * * * * /koolshare/scripts/ss_webtest.sh 2"
	else
		echo_date "❎️fancyss节点web落地延迟检测任务未启用！"
	fi
}

kill_cron_job() {
	if [ -n "$(cru l | grep ssupdate)" ]; then
		echo_date "删除fancyss规则定时更新任务..."
		sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	if [ -n "$(cru l | grep ssnodeupdate)" ]; then
		echo_date "删除定时订阅任务..."
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	if [ -n "$(cru l | grep sslatencyjob)" ]; then
		echo_date 删除SSR定时订阅任务...
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}
#--------------------------------------nat part begin------------------------------------------------
load_tproxy() {
	MODULES="xt_TPROXY xt_socket xt_comment"
	for MODULE in ${MODULES}
	do
		lsmod | grep ${MODULE} &>/dev/null
		if [ "$?" != "0" ]; then
			echo_date "加载${MODULE}模块..."
			modprobe ${MODULE}.ko
		else
			echo_date "${MODULE}模块已加载..."
		fi
	done
}

flush_ipset() {
	# flush ipset
	echo_date "清除ipset规则集..."
	ipset -F ignlist >/dev/null 2>&1 && ipset -X ignlist >/dev/null 2>&1
	ipset -F ignlist6 >/dev/null 2>&1 && ipset -X ignlist6 >/dev/null 2>&1
	
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F white_list6 >/dev/null 2>&1 && ipset -X white_list6 >/dev/null 2>&1
	
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F black_list6 >/dev/null 2>&1 && ipset -X black_list6 >/dev/null 2>&1

	ipset -F chnlist >/dev/null 2>&1 && ipset -X chnlist >/dev/null 2>&1
	ipset -F chnlist6 >/dev/null 2>&1 && ipset -X chnlist6 >/dev/null 2>&1
	
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F gfwlist6 >/dev/null 2>&1 && ipset -X gfwlist6 >/dev/null 2>&1
	
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
	ipset -F router6 >/dev/null 2>&1 && ipset -X router6 >/dev/null 2>&1

	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F chnroute6 >/dev/null 2>&1 && ipset -X chnroute6 >/dev/null 2>&1
	#remove_redundant_rule
	local ip_rule_exist=$(ip rule show | grep "lookup 310" | grep -c 310)
	if [ -n "${ip_rule_exist}" ]; then
		#echo_date 清除重复的ip rule规则.
		until [ "${ip_rule_exist}" == "0" ]; do
			IP_ARG=$(ip rule show | grep "lookup 310" | head -n 1 | cut -d " " -f3,4,5,6)
			ip rule del $IP_ARG
			ip_rule_exist=$(expr $ip_rule_exist - 1)
		done
	fi
	#remove_route_table
	#echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}

# creat ipset rules
creat_ipset() {
	echo_date "创建ipset名单"
	local chnroute4_file="/koolshare/ss/rules/chnroute.txt"
	local chnroute6_file="/koolshare/ss/rules/chnroute6.txt"
	if [ "${ss_basic_mode}" = "7" ] && type fss_shunt_get_runtime_chnroute4_file >/dev/null 2>&1; then
		local runtime_chnroute4=""
		local runtime_chnroute6=""
		runtime_chnroute4="$(fss_shunt_get_runtime_chnroute4_file 2>/dev/null || true)"
		runtime_chnroute6="$(fss_shunt_get_runtime_chnroute6_file 2>/dev/null || true)"
		[ -n "${runtime_chnroute4}" ] && chnroute4_file="${runtime_chnroute4}"
		[ -n "${runtime_chnroute6}" ] && chnroute6_file="${runtime_chnroute6}"
	fi

	# 使用ipset restore批量创建/清空并导入网段，减少大量 ipset 子进程调用，加快启动速度
	{
		echo "create ignlist nethash -exist"
		echo "flush ignlist"
		echo "create ignlist6 nethash family inet6 -exist"
		echo "flush ignlist6"

		echo "create white_list nethash -exist"
		echo "flush white_list"
		echo "create white_list6 nethash family inet6 -exist"
		echo "flush white_list6"

		echo "create black_list nethash -exist"
		echo "flush black_list"
		echo "create black_list6 nethash family inet6 -exist"
		echo "flush black_list6"

		echo "create chnlist nethash -exist"
		echo "flush chnlist"
		echo "create chnlist6 nethash family inet6 -exist"
		echo "flush chnlist6"

		echo "create gfwlist nethash -exist"
		echo "flush gfwlist"
		echo "create gfwlist6 nethash family inet6 -exist"
		echo "flush gfwlist6"

		echo "create router nethash -exist"
		echo "flush router"
		echo "create router6 nethash family inet6 -exist"
		echo "flush router6"

		echo "create chnroute nethash -exist"
		echo "flush chnroute"
		sed -e "s/^/add chnroute &/g" "${chnroute4_file}"

		echo "create chnroute6 nethash family inet6 -exist"
		echo "flush chnroute6"
		sed -e "s/^/add chnroute6 &/g" "${chnroute6_file}"

		echo "COMMIT"
	} | ipset -R
}

get_action_chain() {
	case "$1" in
	0)
		echo "RETURN"
		;;
	1)
		echo "SHADOWSOCKS_GFW"
		;;
	2)
		echo "SHADOWSOCKS_CHN"
		;;
	3)
		echo "SHADOWSOCKS_GAM"
		;;
	5)
		echo "SHADOWSOCKS_GLO"
		;;
	6)
		echo "SHADOWSOCKS_HOM"
		;;
	7)
		if [ "${ss_basic_mode}" = "7" ]; then
			echo "SHADOWSOCKS_SHU"
		else
			get_action_chain "$(get_runtime_proxy_mode)"
		fi
		;;
	esac
}

get_action_chain6() {
	case "$1" in
	0)
		echo "RETURN"
		;;
	1)
		echo "SHADOWSOCKS6_GFW"
		;;
	2)
		echo "SHADOWSOCKS6_CHN"
		;;
	3)
		echo "SHADOWSOCKS6_GAM"
		;;
	5)
		echo "SHADOWSOCKS6_GLO"
		;;
	6)
		echo "SHADOWSOCKS6_HOM"
		;;
	7)
		if [ "${ss_basic_mode}" = "7" ]; then
			echo "SHADOWSOCKS6_SHU"
		else
			get_action_chain6 "$(get_runtime_proxy_mode)"
		fi
		;;
	esac
}

get_mode_name() {
	case "$1" in
	0)
		echo "不通过代理"
		;;
	1)
		echo "gfwlist模式"
		;;
	2)
		echo "大陆白名单模式"
		;;
	3)
		echo "游戏模式"
		;;
	5)
		echo "全局模式"
		;;
	6)
		echo "回国模式"
		;;
	7)
		echo "xray分流模式"
		;;
	esac
}

factor() {
	if [ -z "$1" -o -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

get_jump_mode() {
	case "$1" in
	0)
		echo "j"
		;;
	*)
		echo "g"
		;;
	esac
}

acl_proxy_supports_udp() {
	[ "${ss_basic_type}" == "6" ] && return 1
	return 0
}

note_acl_udp_unsupported_once() {
	if [ "${ACL_UDP_UNSUPPORTED_NOTICE}" != "1" ]; then
		echo_date "⚠️因Naïve协议不支持UDP代理，访问控制中的UDP代理开关将被忽略，并默认屏蔽对应规则的QUIC流量。"
		ACL_UDP_UNSUPPORTED_NOTICE="1"
	fi
}

note_acl_quic_forced_once() {
	if [ "${ACL_QUIC_FORCED_NOTICE}" != "1" ]; then
		echo_date "⚠️检测到访问控制存在“UDP代理关闭且未屏蔽QUIC”的组合，已自动按“屏蔽QUIC”处理。"
		ACL_QUIC_FORCED_NOTICE="1"
	fi
}

get_acl_udp_flag() {
	local acl="$1"
	local proxy_mode="$2"
	local udp_flag=""
	if ! acl_proxy_supports_udp; then
		if [ "${proxy_mode}" != "0" ]; then
			note_acl_udp_unsupported_once
		fi
		echo "0"
		return
	fi
	if [ "${proxy_mode}" == "3" ];then
		echo "1"
		return
	fi
	if [ -n "${acl}" ];then
		eval udp_flag=\$ss_acl_udp_${acl}
	else
		udp_flag="$(resolve_acl_default_udp_raw)"
	fi
	if [ -z "${udp_flag}" ];then
		if [ -n "${acl}" ];then
			if [ "${ss_basic_udpall}" == "1" ];then
				udp_flag="1"
			else
				udp_flag="0"
			fi
		else
			udp_flag="0"
		fi
	fi
	echo "${udp_flag}"
}

get_acl_quic_flag() {
	local acl="$1"
	local proxy_mode="$2"
	local udp_flag="$3"
	local quic_flag=""
	if [ -n "${acl}" ];then
		eval quic_flag=\$ss_acl_quic_${acl}
	else
		quic_flag="${ss_acl_default_quic}"
	fi
	if [ -z "${quic_flag}" ];then
		if [ -n "${acl}" ];then
			if [ -n "${ss_basic_block_quic}" ];then
				quic_flag="${ss_basic_block_quic}"
			else
				quic_flag="1"
			fi
		else
			quic_flag="1"
		fi
	fi
	if [ "${proxy_mode}" != "0" ]; then
		if ! acl_proxy_supports_udp; then
			note_acl_udp_unsupported_once
			quic_flag="1"
		elif [ "${udp_flag}" != "1" ] && [ "${quic_flag}" != "1" ]; then
			note_acl_quic_forced_once
			quic_flag="1"
		fi
	fi
	echo "${quic_flag}"
}

get_acl_source_rule4() {
	local acl="$1"
	local ipaddr=""
	local acl_mac=""
	eval ipaddr=\$ss_acl_ip_${acl}
	if acl_is_cidr_rule "${ipaddr}"; then
		echo "$(factor "${ipaddr}" "-s")"
		return 0
	fi
	acl_mac=$(resolve_acl_mac "${acl}")
	if [ -n "${acl_mac}" ]; then
		echo "-m mac --mac-source ${acl_mac}"
	else
		echo "$(factor "${ipaddr}" "-s")"
	fi
}

get_acl_source_rule6() {
	local acl="$1"
	local ipaddr=""
	local acl_mac=""
	eval ipaddr=\$ss_acl_ip_${acl}
	acl_is_cidr_rule "${ipaddr}" && return 1
	acl_mac=$(resolve_acl_mac "${acl}")
	[ -n "${acl_mac}" ] || return 1
	echo "-m mac --mac-source ${acl_mac}"
}

apply_acl_udp_rule() {
	local acl_desc="$1"
	local source_rule="$2"
	local ports="$3"
	local proxy_mode="$4"
	local udp_flag="$5"
	local quic_flag="$6"

	if [ "${proxy_mode}" != "0" -a "${udp_flag}" == "1" ];then
		echo_date "UDP代理规则：【${acl_desc}】开启UDP代理，模式：$(get_mode_name ${proxy_mode})"
		if [ "${quic_flag}" == "1" ];then
			echo_date "UDP 443处理：【${acl_desc}】屏蔽QUIC流量，先直连放行至filter表进一步处理。"
			iptables -t mangle -A SHADOWSOCKS ${source_rule} -p udp --dport 443 -j RETURN
		else
			echo_date "UDP 443处理：【${acl_desc}】不屏蔽QUIC流量。"
		fi
		iptables -t mangle -A SHADOWSOCKS ${source_rule} -p udp $(factor ${ports} "-m multiport --dport") -$(get_jump_mode ${proxy_mode}) $(get_action_chain ${proxy_mode})
	else
		if [ "${proxy_mode}" == "0" ];then
			echo_date "UDP代理规则：【${acl_desc}】不通过代理，UDP流量直连。"
		elif ! acl_proxy_supports_udp; then
			echo_date "UDP代理规则：【${acl_desc}】当前节点不支持UDP代理，已忽略UDP代理设置。"
		else
			echo_date "UDP代理规则：【${acl_desc}】关闭UDP代理。"
		fi
		iptables -t mangle -A SHADOWSOCKS ${source_rule} -p udp -j RETURN
	fi
}

apply_acl_quic_filter_rule() {
	local acl_desc="$1"
	local source_rule="$2"
	local proxy_mode="$3"
	local quic_flag="$4"

	if [ "${proxy_mode}" == "0" ];then
		echo_date "UDP 443过滤规则：【${acl_desc}】不通过代理，UDP 443直连。"
		append_if_not_exists filter -A SHADOWSOCKS ${source_rule} -p udp --dport 443 -j RETURN
	elif ! acl_proxy_supports_udp; then
		echo_date "UDP 443过滤规则：【${acl_desc}】因当前节点不支持UDP代理，默认屏蔽QUIC流量，按$(get_mode_name ${proxy_mode})处理海外UDP 443。"
		append_if_not_exists filter -A SHADOWSOCKS ${source_rule} -p udp --dport 443 -$(get_jump_mode ${proxy_mode}) $(get_action_chain ${proxy_mode})
	elif [ "${quic_flag}" == "1" ];then
		echo_date "UDP 443过滤规则：【${acl_desc}】屏蔽QUIC流量，按$(get_mode_name ${proxy_mode})处理海外UDP 443。"
		append_if_not_exists filter -A SHADOWSOCKS ${source_rule} -p udp --dport 443 -$(get_jump_mode ${proxy_mode}) $(get_action_chain ${proxy_mode})
	else
		echo_date "UDP 443过滤规则：【${acl_desc}】不屏蔽QUIC流量。"
		append_if_not_exists filter -A SHADOWSOCKS ${source_rule} -p udp --dport 443 -j RETURN
	fi
}

append_acl_desc_list() {
	local current="$1"
	local value="$2"
	if [ -z "${value}" ];then
		echo "${current}"
	elif [ -n "${current}" ];then
		echo "${current}、${value}"
	else
		echo "${value}"
	fi
}

resolve_ipv6_default_acl() {
	local acl_nu=$(get_acl_rule_indexes)
	local acl=""
	local ipaddr=""
	local source_rule6=""

	IPV6_ACL_RULES=""
	IPV6_ACL_SKIP_CIDR=""
	IPV6_ACL_SKIP_NOMAC=""
	IPV6_ACL_TOTAL_COUNT="0"
	IPV6_ACL_ACTIVE_COUNT="0"

	if [ -n "${acl_nu}" ]; then
		IPV6_ACL_HAS_CUSTOM="1"
		IPV6_ACL_DEFAULT_MODE="$(resolve_acl_default_mode 1)"
		for acl in ${acl_nu}
		do
			ipaddr=$(eval echo \$ss_acl_ip_${acl})
			IPV6_ACL_TOTAL_COUNT=$((${IPV6_ACL_TOTAL_COUNT} + 1))
			if acl_is_cidr_rule "${ipaddr}"; then
				IPV6_ACL_SKIP_CIDR=$(append_acl_desc_list "${IPV6_ACL_SKIP_CIDR}" "${ipaddr}")
				continue
			fi
			source_rule6=$(get_acl_source_rule6 ${acl})
			if [ -n "${source_rule6}" ];then
				IPV6_ACL_RULES="${IPV6_ACL_RULES} ${acl}"
				IPV6_ACL_ACTIVE_COUNT=$((${IPV6_ACL_ACTIVE_COUNT} + 1))
			else
				IPV6_ACL_SKIP_NOMAC=$(append_acl_desc_list "${IPV6_ACL_SKIP_NOMAC}" "${ipaddr}")
			fi
		done
		if [ "${IPV6_ACL_ACTIVE_COUNT}" -gt "0" ];then
			IPV6_ACL_DEFAULT_LABEL="剩余IPv6主机"
		else
			IPV6_ACL_DEFAULT_LABEL="全部IPv6主机"
		fi
	else
		IPV6_ACL_DEFAULT_LABEL="全部IPv6主机"
		IPV6_ACL_HAS_CUSTOM="0"
		IPV6_ACL_DEFAULT_MODE="$(resolve_acl_default_mode 0)"
	fi
	IPV6_ACL_DEFAULT_PORTS="$(resolve_acl_ports "$(resolve_acl_default_ports_raw)" "${IPV6_ACL_DEFAULT_MODE}")"
}

apply_acl_udp_rule6() {
	local acl_desc="$1"
	local source_rule="$2"
	local ports="$3"
	local proxy_mode="$4"
	local udp_flag="$5"
	local quic_flag="$6"

	if [ "${proxy_mode}" != "0" -a "${udp_flag}" == "1" ];then
		echo_date "IPv6 UDP代理规则：【${acl_desc}】开启UDP代理，模式：$(get_mode_name ${proxy_mode})"
		if [ "${quic_flag}" == "1" ];then
			echo_date "IPv6 UDP 443处理：【${acl_desc}】屏蔽QUIC流量，先直连放行至filter表进一步处理。"
			append_if_not_exists6 mangle -A SHADOWSOCKS6 ${source_rule} -p udp --dport 443 -j RETURN || return 1
		else
			echo_date "IPv6 UDP 443处理：【${acl_desc}】不屏蔽QUIC流量。"
		fi
		append_if_not_exists6 mangle -A SHADOWSOCKS6 ${source_rule} -p udp $(factor ${ports} "-m multiport --dport") -$(get_jump_mode ${proxy_mode}) $(get_action_chain6 ${proxy_mode}) || return 1
	else
		if [ "${proxy_mode}" == "0" ];then
			echo_date "IPv6 UDP代理规则：【${acl_desc}】不通过代理，UDP流量直连。"
		elif ! acl_proxy_supports_udp; then
			echo_date "IPv6 UDP代理规则：【${acl_desc}】当前节点不支持UDP代理，已忽略UDP代理设置。"
		else
			echo_date "IPv6 UDP代理规则：【${acl_desc}】关闭UDP代理。"
		fi
		append_if_not_exists6 mangle -A SHADOWSOCKS6 ${source_rule} -p udp -j RETURN || return 1
	fi
}

apply_acl_quic_filter_rule6() {
	local acl_desc="$1"
	local source_rule="$2"
	local proxy_mode="$3"
	local quic_flag="$4"

	if [ "${proxy_mode}" == "0" ];then
		echo_date "IPv6 UDP 443过滤规则：【${acl_desc}】不通过代理，UDP 443直连。"
		append_if_not_exists6 filter -A SHADOWSOCKS6 ${source_rule} -p udp --dport 443 -j RETURN || return 1
	elif ! acl_proxy_supports_udp; then
		echo_date "IPv6 UDP 443过滤规则：【${acl_desc}】因当前节点不支持UDP代理，默认屏蔽QUIC流量，按$(get_mode_name ${proxy_mode})处理海外UDP 443。"
		append_if_not_exists6 filter -A SHADOWSOCKS6 ${source_rule} -p udp --dport 443 -$(get_jump_mode ${proxy_mode}) $(get_action_chain6 ${proxy_mode}) || return 1
	elif [ "${quic_flag}" == "1" ];then
		echo_date "IPv6 UDP 443过滤规则：【${acl_desc}】屏蔽QUIC流量，按$(get_mode_name ${proxy_mode})处理海外UDP 443。"
		append_if_not_exists6 filter -A SHADOWSOCKS6 ${source_rule} -p udp --dport 443 -$(get_jump_mode ${proxy_mode}) $(get_action_chain6 ${proxy_mode}) || return 1
	else
		echo_date "IPv6 UDP 443过滤规则：【${acl_desc}】不屏蔽QUIC流量。"
		append_if_not_exists6 filter -A SHADOWSOCKS6 ${source_rule} -p udp --dport 443 -j RETURN || return 1
	fi
}

apply_quic_block() {
	# lan access control
	local default_mode=""
	acl_nu=$(get_acl_rule_indexes)
	if [ -n "$acl_nu" ]; then
		# 先设定访问控制内的主机
		for acl in $acl_nu; do
			ipaddr=$(eval echo \$ss_acl_ip_$acl)
			proxy_mode=$(eval echo \$ss_acl_mode_$acl)
			udp_flag=$(get_acl_udp_flag ${acl} ${proxy_mode})
			quic_flag=$(get_acl_quic_flag ${acl} ${proxy_mode} "${udp_flag}")
			apply_acl_quic_filter_rule "${ipaddr}" "$(get_acl_source_rule4 ${acl})" "${proxy_mode}" "${quic_flag}"
		done
		default_mode="$(resolve_acl_default_mode 1)"
		udp_flag=$(get_acl_udp_flag "" "${default_mode}")
		quic_flag=$(get_acl_quic_flag "" "${default_mode}" "${udp_flag}")
		apply_acl_quic_filter_rule "剩余主机" "" "${default_mode}" "${quic_flag}"
	else
		default_mode="$(resolve_acl_default_mode 0)"
		udp_flag=$(get_acl_udp_flag "" "${default_mode}")
		quic_flag=$(get_acl_quic_flag "" "${default_mode}" "${udp_flag}")
		apply_acl_quic_filter_rule "全部主机" "" "${default_mode}" "${quic_flag}"
	fi
}

lan_access_control() {
	# lan access control
	local default_mode=""
	local default_ports=""
	acl_nu=$(get_acl_rule_indexes)
	if [ -n "$acl_nu" ]; then
		acl_default_label="剩余主机"
		for acl in $acl_nu; do
			ipaddr=$(eval echo \$ss_acl_ip_$acl)
			ipaddr_hex=$(get_acl_ip_mark "${ipaddr}")
			source_rule=$(get_acl_source_rule4 ${acl})
			proxy_mode=$(eval echo \$ss_acl_mode_$acl)
			ports=$(resolve_acl_ports "$(eval echo \$ss_acl_port_$acl)" "${proxy_mode}")
			proxy_name=$(eval echo \$ss_acl_name_$acl)
			udp_flag=$(get_acl_udp_flag ${acl} ${proxy_mode})
			quic_flag=$(get_acl_quic_flag ${acl} ${proxy_mode} "${udp_flag}")
			if [ "$ports" == "all" ]; then
				ports=""
				echo_date "加载ACL规则：【$ipaddr】【全部端口】模式为：$(get_mode_name $proxy_mode)"
			else
				echo_date "加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)"
			fi
			# 1 acl in SHADOWSOCKS for nat
			iptables -t nat -A SHADOWSOCKS ${source_rule} -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			
			# 2 acl in OUTPUT（used by koolproxy）
			iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ports "-m multiport --dport") -m mark --mark "$ipaddr_hex" -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			
			# 3 acl in SHADOWSOCKS for mangle
			apply_acl_udp_rule "${ipaddr}" "${source_rule}" "${ports}" "${proxy_mode}" "${udp_flag}" "${quic_flag}"
		done

		default_mode="$(resolve_acl_default_mode 1)"
		default_ports="$(resolve_acl_ports "$(resolve_acl_default_ports_raw)" "${default_mode}")"
		if [ "${default_ports}" == "all" ]; then
			default_ports=""
			echo_date "加载ACL规则：【${acl_default_label}】【全部端口】模式为：$(get_mode_name ${default_mode})"
		else
			echo_date "加载ACL规则：【${acl_default_label}】【${default_ports}】模式为：$(get_mode_name ${default_mode})"
		fi
	else
		acl_default_label="全部主机"
		default_mode="$(resolve_acl_default_mode 0)"
		default_ports="$(resolve_acl_ports "$(resolve_acl_default_ports_raw)" "${default_mode}")"
		if [ "${default_ports}" == "all" ]; then
			default_ports=""
			echo_date "加载ACL规则：【${acl_default_label}】【全部端口】模式为：$(get_mode_name ${default_mode})"
		else
			echo_date "加载ACL规则：【${acl_default_label}】【${default_ports}】模式为：$(get_mode_name ${default_mode})"
		fi
	fi
	dbus remove ss_acl_ip
	dbus remove ss_acl_mac
	dbus remove ss_acl_name
	dbus remove ss_acl_mode
	dbus remove ss_acl_port
	dbus remove ss_acl_udp
	dbus remove ss_acl_quic
}

dns_hijack_control() {
	local type=${1:-4}
	if [ "${type}" == "4" ];then
		local iptab=iptables
		local chain_prefix=SHADOWSOCKS_DNS
	elif [ "${type}" == "6" ];then
		local iptab=ip6tables
		local chain_prefix=SHADOWSOCKS6_DNS
	fi
	
	if [ "$ss_basic_dns_hijack" == "1" ]; then
		for VLAN_INDEX in ${VLAN_INDEXS}
		do
			if [ "${type}" == "4" ];then
				local dest_ipaddr=$(ifconfig br${VLAN_INDEX} | grep "inet addr" | awk '{print $2}'|awk -F ":" '{print $2}')
			else
				local dest_ipaddr=$(ip -6 addr show dev br${VLAN_INDEX} scope global 2>/dev/null | awk '/inet6/ {print $2}' | head -n1 | awk -F "/" '{print $1}')
				if [ -z "${dest_ipaddr}" ];then
					echo_date "IPv6 DNS劫持：未获取到br${VLAN_INDEX}的IPv6地址，跳过该接口。"
					continue
				fi
			fi
			local acl_nu=$(get_acl_rule_indexes)
			if [ -n "$acl_nu" ]; then
				for acl in $acl_nu; do
					ipaddr=$(eval echo \$ss_acl_ip_$acl)
					proxy_mode=$(eval echo \$ss_acl_mode_$acl)
					if [ "${proxy_mode}" == "0" ]; then
						if [ "${type}" == "4" ];then
							local source_rule=$(get_acl_source_rule4 ${acl})
							${iptab} -t nat -A ${chain_prefix}_${VLAN_INDEX} ${source_rule} -p udp -j RETURN
						else
							local source_rule6=$(get_acl_source_rule6 ${acl})
							if [ -n "${source_rule6}" ]; then
								${iptab} -t nat -A ${chain_prefix}_${VLAN_INDEX} ${source_rule6} -p udp -j RETURN
							elif acl_is_cidr_rule "${ipaddr}"; then
								echo_date "IPv6 DNS劫持：ACL【${ipaddr}】为CIDR规则，无法按设备豁免DNS劫持，继续按IPv6默认DNS规则处理。"
							else
								echo_date "IPv6 DNS劫持：ACL【${ipaddr}】未获取到MAC地址，无法按设备豁免DNS劫持，继续按IPv6默认DNS规则处理。"
							fi
						fi
					fi
				done
			fi
			if [ "${type}" == "4" ];then
				${iptab} -t nat -A ${chain_prefix}_${VLAN_INDEX} -p udp -j DNAT --to ${dest_ipaddr}:53
			else
				${iptab} -t nat -A ${chain_prefix}_${VLAN_INDEX} -p udp -j DNAT --to-destination [${dest_ipaddr}]:53
			fi
		done
	fi
}

flush_iptables() {
	# use different xtables libdir
	if [ -d "/tmp/.xt" ];then
		export XTABLES_LIBDIR=/tmp/.xt
	fi
	
	# flush NAT
	local NAT_RULES=$(iptables -t nat -S | grep -E "SHADOWSOCKS|3333" | sort)
	if [ -n "${NAT_RULES}" ];then
		echo_date "清除iptables nat规则..."
		echo "${NAT_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			#echo "$TYPE" "$line"
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/iptables -t nat -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/iptables -t nat -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/iptables -t nat -X/g')
				run_bg $CMD3
			fi
		done
	fi

	# flush MANGLE
	local MANGLE_RULES=$(iptables -t mangle -S | grep -E "SHADOWSOCKS|3333|0x7" | sort)
	if [ -n "${MANGLE_RULES}" ];then
		echo_date "清除iptables mangle规则..."
		echo "${MANGLE_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			#echo "$TYPE" "$line"
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/iptables -t mangle -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/iptables -t mangle -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/iptables -t mangle -X/g')
				run_bg $CMD3
			fi
		done
	fi

	# flush MANGLE
	local FILTER_RULES=$(iptables -t filter -S | grep -E "SHADOWSOCKS" | sort)
	if [ -n "${FILTER_RULES}" ];then
		echo_date "清除iptables filter规则..."
		echo "${FILTER_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/iptables -t filter -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/iptables -t filter -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/iptables -t filter -X/g')
				run_bg $CMD3
			fi
		done
	fi

	# flush IPv6 NAT
	local NAT6_RULES=$(ip6tables -t nat -S 2>/dev/null | grep -E "SHADOWSOCKS6|3333|3334" | sort)
	if [ -n "${NAT6_RULES}" ];then
		echo_date "清除ip6tables nat规则..."
		echo "${NAT6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t nat -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t nat -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t nat -X/g')
				run_bg $CMD3
			fi
		done
	fi

	# flush IPv6 MANGLE
	local MANGLE6_RULES=$(ip6tables -t mangle -S 2>/dev/null | grep -E "SHADOWSOCKS6|3333|3334|0x7" | sort)
	if [ -n "${MANGLE6_RULES}" ];then
		echo_date "清除ip6tables mangle规则..."
		echo "${MANGLE6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t mangle -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t mangle -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t mangle -X/g')
				run_bg $CMD3
			fi
		done
	fi

	# flush IPv6 FILTER
	local FILTER6_RULES=$(ip6tables -t filter -S 2>/dev/null | grep -E "SHADOWSOCKS6" | sort)
	if [ -n "${FILTER6_RULES}" ];then
		echo_date "清除ip6tables filter规则..."
		echo "${FILTER6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t filter -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t filter -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t filter -X/g')
				run_bg $CMD3
			fi
		done
	fi

	local ip6_rule_exist=$(ip -6 rule show 2>/dev/null | grep "lookup 310" | grep -c 310)
	if [ -n "${ip6_rule_exist}" ]; then
		until [ "${ip6_rule_exist}" == "0" ]; do
			IP6_ARG=$(ip -6 rule show 2>/dev/null | grep "lookup 310" | head -n 1 | cut -d " " -f3,4,5,6)
			ip -6 rule del $IP6_ARG >/dev/null 2>&1
			ip6_rule_exist=$(expr $ip6_rule_exist - 1)
		done
	fi
	ip -6 route del local ::/0 dev lo table 310 >/dev/null 2>&1
}

stop_dns_process() {
	local CHNG_PID=$(pidof chinadns-ng)
	if [ -n "${CHNG_PID}" ];then
		echo_date "关闭chinadns-ng进程..."
		if [ -d "/koolshare/perp/chinadns-ng" ];then
			perpctl d chinadns-ng >/dev/null 2>&1
			rm -rf /koolshare/perp/chinadns-ng >/dev/null 2>&1
		fi
		killall chinadns-ng >/dev/null 2>&1
		kill -9 ${CHNG_PID} >/dev/null 2>&1
	fi

	local smartdns_process=$(pidof smartdns)
	if [ -n "$smartdns_process" ]; then
		echo_date "关闭smartdns进程..."
		killall smartdns >/dev/null 2>&1
	fi

}

flush_ip6tables() {
	if [ -d "/tmp/.xt" ];then
		export XTABLES_LIBDIR=/tmp/.xt
	fi

	local NAT6_RULES=$(ip6tables -t nat -S 2>/dev/null | grep -E "SHADOWSOCKS6|3333|3334" | sort)
	if [ -n "${NAT6_RULES}" ];then
		echo_date "清除ip6tables nat规则..."
		echo "${NAT6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t nat -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t nat -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t nat -X/g')
				run_bg $CMD3
			fi
		done
	fi

	local MANGLE6_RULES=$(ip6tables -t mangle -S 2>/dev/null | grep -E "SHADOWSOCKS6|3333|3334|0x7" | sort)
	if [ -n "${MANGLE6_RULES}" ];then
		echo_date "清除ip6tables mangle规则..."
		echo "${MANGLE6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t mangle -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t mangle -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t mangle -X/g')
				run_bg $CMD3
			fi
		done
	fi

	local FILTER6_RULES=$(ip6tables -t filter -S 2>/dev/null | grep -E "SHADOWSOCKS6" | sort)
	if [ -n "${FILTER6_RULES}" ];then
		echo_date "清除ip6tables filter规则..."
		echo "${FILTER6_RULES}" | while read line
		do
			local TYPE=$(echo "$line" | awk '{print $1}' | sed 's/^-//g')
			if [ "${TYPE}" == "A" ];then
				local CMD1=$(echo "$line" | sed 's/^-A/ip6tables -t filter -D/g')
				run_bg $CMD1
			elif [ "${TYPE}" == "N" ];then
				local CMD2=$(echo "$line" | sed 's/^-N/ip6tables -t filter -F/g')
				run_bg $CMD2
				local CMD3=$(echo "$line" | sed 's/^-N/ip6tables -t filter -X/g')
				run_bg $CMD3
			fi
		done
	fi

	local ip6_rule_exist=$(ip -6 rule show 2>/dev/null | grep "lookup 310" | grep -c 310)
	if [ -n "${ip6_rule_exist}" ]; then
		until [ "${ip6_rule_exist}" == "0" ]; do
			IP6_ARG=$(ip -6 rule show 2>/dev/null | grep "lookup 310" | head -n 1 | cut -d " " -f3,4,5,6)
			ip -6 rule del $IP6_ARG >/dev/null 2>&1
			ip6_rule_exist=$(expr $ip6_rule_exist - 1)
		done
	fi
	ip -6 route del local ::/0 dev lo table 310 >/dev/null 2>&1
}

disable_ipv6_proxy_runtime() {
	ss_basic_proxy_ipv6="0"
	ss_basic_chng_ipv6_drop_proxy="1"
	dbus set ss_basic_proxy_ipv6="0"
	dbus set ss_basic_chng_ipv6_drop_proxy="1"
}

fallback_ipv6_proxy_to_ipv4() {
	echo_date "⚠️检测到IPv6透明代理规则写入失败，开始回退到IPv4代理模式..."
	flush_ip6tables
	disable_ipv6_proxy_runtime
	echo_date "↪ 已同步关闭前端的IPv6代理开关，并强制开启代理域名IPv6过滤。"
	stop_dns_process
	start_dns_x
	echo_date "✅ 已回退为IPv4代理模式，IPv4透明代理规则继续生效。"
}

load_iptables() {
	#local nat_ready=$(ip6tables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	local nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	i=300
	until [ -n "$nat_ready" ]; do
		i=$(($i - 1))
		if [ "$i" -lt 1 ]; then
			echo_date "错误：不能正确加载nat规则!"
			close_in_five
		fi
		usleep 100000
		local nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	done
	# creat_ipset
	# add_white_black
	if ! _start_iptables; then
		echo_date "错误：写入iptables透明代理规则失败，正在回滚..."
		flush_iptables
		flush_ipset
		close_in_five flag
	fi
}

ensure_chain() {
	ensure_chain_with_cmd iptables "$@"
}

ensure_chain6() {
	ensure_chain_with_cmd ip6tables "$@"
}

ensure_chain_with_cmd() {
	local cmd="$1"
	local table="$2"
	local chain="$3"
	if ! ${cmd} -t "$table" -L "$chain" >/dev/null 2>&1; then
		${cmd} -t "$table" -N "$chain" >/dev/null 2>&1 || return 1
	fi
}

append_if_not_exists() {
	append_if_not_exists_with_cmd iptables "$@"
}

append_if_not_exists6() {
	append_if_not_exists_with_cmd ip6tables "$@"
}

append_if_not_exists_with_cmd() {
	local cmd="$1"
	local table="$2"
	shift 2
	set -- "$@"
	if [ "$1" = "-A" ]; then
		local chain="$2"
		shift 2
		if ! ${cmd} -t "$table" -C "$chain" "$@" >/dev/null 2>&1; then
			${cmd} -t "$table" -A "$chain" "$@" >/dev/null 2>&1 || return 1
		fi
	else
		echo "append_if_not_exists 需要以 -A 开头的参数" >&2
		return 1
	fi
}

insert_if_not_exists() {
	table="$1"
	shift
	# 剩余参数为完整规则，例如：-A CHAIN ... -j ...
	# 先构造对应的 -C 检查：把 -A 改为 -C
	# 注意：iptables -C 格式为：iptables -t table -C chain rule-spec
	# 因此需要拆出链名和去掉 -A
	set -- "$@"
	if [ "$1" = "-I" ]; then
		chain="$2"
		# 去掉前两个参数 "-A chain"
		shift 2
		if ! iptables -t "$table" -C "$chain" "$@" >/dev/null 2>&1; then
		  iptables -t "$table" -I "$chain" "$@"
		fi
	else
		echo "append_if_not_exists 需要以 -I 开头的参数" >&2
		return 1
	fi
}

get_shunt_ingress_mode() {
	local mode="${ss_basic_shunt_ingress_mode:-2}"
	case "${mode}" in
	5)
		echo "5"
		;;
	*)
		echo "2"
		;;
	esac
}

init_shunt_chain_v4() {
	local ingress_mode="$(get_shunt_ingress_mode)"

	ensure_chain nat SHADOWSOCKS_SHU
	ensure_chain mangle SHADOWSOCKS_SHU
	ensure_chain filter SHADOWSOCKS_SHU
	if [ "${ingress_mode}" = "5" ]; then
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -m set --match-set white_list dst -j RETURN
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -j REDIRECT --to-ports 3333
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -m set --match-set white_list dst -j RETURN
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -m set --match-set white_list dst -j RETURN
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -j REJECT --reject-with icmp-port-unreachable
	else
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -m set --match-set chnlist dst -j RETURN
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -m set --match-set chnroute dst -j RETURN
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -m set --match-set white_list dst -j RETURN
		append_if_not_exists nat -A SHADOWSOCKS_SHU -p tcp -j REDIRECT --to-ports 3333
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -m set --match-set chnlist dst -j RETURN
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -m set --match-set chnroute dst -j RETURN
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -m set --match-set white_list dst -j RETURN
		append_if_not_exists mangle -A SHADOWSOCKS_SHU -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -m set --match-set black_list dst -j REJECT --reject-with icmp-port-unreachable
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -m set --match-set chnlist dst -j RETURN
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -m set --match-set chnroute dst -j RETURN
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -m set --match-set white_list dst -j RETURN
		append_if_not_exists filter -A SHADOWSOCKS_SHU -p udp -j REJECT --reject-with icmp-port-unreachable
	fi
}

init_shunt_chain_v6() {
	local ingress_mode="$(get_shunt_ingress_mode)"
	local tproxy_port6="$(get_tproxy_port6)"

	ensure_chain6 nat SHADOWSOCKS6_SHU || return 1
	ensure_chain6 mangle SHADOWSOCKS6_SHU || return 1
	ensure_chain6 filter SHADOWSOCKS6_SHU || return 1
	if [ "${ingress_mode}" = "5" ]; then
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -j REDIRECT --to-ports ${tproxy_port6} || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -j TPROXY --on-port ${tproxy_port6} --tproxy-mark 0x07 || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -j REJECT --reject-with icmp6-port-unreachable || return 1
	else
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -m set --match-set black_list6 dst -j REDIRECT --to-ports ${tproxy_port6} || return 1
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -m set --match-set chnlist6 dst -j RETURN || return 1
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -m set --match-set chnroute6 dst -j RETURN || return 1
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 nat -A SHADOWSOCKS6_SHU -p tcp -j REDIRECT --to-ports ${tproxy_port6} || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -m set --match-set black_list6 dst -j TPROXY --on-port ${tproxy_port6} --tproxy-mark 0x07 || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -m set --match-set chnlist6 dst -j RETURN || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -m set --match-set chnroute6 dst -j RETURN || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 mangle -A SHADOWSOCKS6_SHU -p udp -j TPROXY --on-port ${tproxy_port6} --tproxy-mark 0x07 || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -m set --match-set black_list6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -m set --match-set chnlist6 dst -j RETURN || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -m set --match-set chnroute6 dst -j RETURN || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -m set --match-set white_list6 dst -j RETURN || return 1
		append_if_not_exists6 filter -A SHADOWSOCKS6_SHU -p udp -j REJECT --reject-with icmp6-port-unreachable || return 1
	fi
}

_start_iptables() {
	#----------------------BASIC RULES---------------------
	echo_date "写入iptables规则到nat表中..."
	local VLAN_INDEXS=$(ifconfig | grep -E "^br" | awk '{print $1}' | sed 's/^br//g')

	# 创建SHADOWSOCKS nat rule
	ensure_chain nat SHADOWSOCKS 

	if [ "$ss_basic_dns_hijack" == "1" ]; then
		for VLAN_INDEX in $VLAN_INDEXS
		do
			# iptables -t nat -N SHADOWSOCKS_DNS_${VLAN_INDEX}
			ensure_chain nat SHADOWSOCKS_DNS_${VLAN_INDEX} 
		done
	fi
	
	# 扩展
	ensure_chain nat SHADOWSOCKS_EXT 
	
	# IP/cidr/白域名 白名单控制（不go proxy）
	append_if_not_exists nat -A SHADOWSOCKS -p tcp -m set --match-set ignlist dst -j RETURN
	append_if_not_exists nat -A SHADOWSOCKS_EXT -p tcp -m set --match-set ignlist dst -j RETURN
	
	#-----------------------FOR GLOABLE---------------------
	# 创建全局模式 nat rule
	ensure_chain nat SHADOWSOCKS_GLO 
	# {white_list} 直连
	append_if_not_exists nat -A SHADOWSOCKS_GLO -p tcp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式 nat rule
	ensure_chain nat SHADOWSOCKS_GFW 
	# {white_list} 直连
	append_if_not_exists nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set white_list dst -j RETURN	
	# {black_list} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# {gfwlist} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports 3333
	# {rotlist} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
	
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式nat rule
	ensure_chain nat SHADOWSOCKS_CHN 
	# {black_list} 代理
	append_if_not_exists nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# {chnlist} 直连
	append_if_not_exists nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set chnlist dst -j RETURN
	# {chnroute} 直连
	append_if_not_exists nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set chnroute dst -j RETURN
	# {white_list} 直连
	append_if_not_exists nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists nat -A SHADOWSOCKS_CHN -p tcp -j REDIRECT --to-ports 3333
	
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式nat rule
	ensure_chain nat SHADOWSOCKS_GAM 
	# {black_list} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# {chnlist} 直连
	append_if_not_exists nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set chnlist dst -j RETURN
	# {chnroute} 直连
	append_if_not_exists nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set chnroute dst -j RETURN
	# {white_list} 直连
	append_if_not_exists nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists nat -A SHADOWSOCKS_GAM -p tcp -j REDIRECT --to-ports 3333
	
	#-----------------------FOR HOMEMODE---------------------
	# 创建回国模式nat rule
	ensure_chain nat SHADOWSOCKS_HOM 
	# {black_list} 代理
	append_if_not_exists nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# {gfwlist} 直连
	append_if_not_exists nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set gfwlist dst -j RETURN
	# {white_list} 直连
	append_if_not_exists nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set white_list dst -j RETURN

	#-----------------------FOR TPROXY---------------------
	load_tproxy
	if [ -z "$(ip rule show table 310 2>/dev/null)" ];then
		ip rule add fwmark 0x07 table 310
	fi
	
	if [ -z "$(ip route show table 310 2>/dev/null)" ];then
		ip route add local 0.0.0.0/0 dev lo table 310
	fi

	# 创建游戏模式udp rule
	ensure_chain mangle SHADOWSOCKS

	# IP/cidr/白域名 白名单控制（不go proxy）
	append_if_not_exists mangle -A SHADOWSOCKS -p udp -m set --match-set ignlist dst -j RETURN

	# 创建gfw模式udp rule
	ensure_chain mangle SHADOWSOCKS_GFW
	# {white_list} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set white_list dst -j RETURN
	# {black_list} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# {gfwlist} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set gfwlist dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# {rotlist} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set router dst -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建白名单模式udp rule
	ensure_chain mangle SHADOWSOCKS_CHN
	# {black_list} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# {chnlist} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set chnlist dst -j RETURN
	# {chnroute} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set chnroute dst -j RETURN
	# {white_list} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_CHN -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建游戏模式udp rule
	ensure_chain mangle SHADOWSOCKS_GAM
	# {black_list} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# {chnlist} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set chnlist dst -j RETURN
	# {chnroute} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set chnroute dst -j RETURN
	# {white_list} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GAM -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建glo模式udp rule
	ensure_chain mangle SHADOWSOCKS_GLO
	# {white_list} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_GLO -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_GLO -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07

	echo_date "创建xray分流模式专用链，入口策略：$( [ "$(get_shunt_ingress_mode)" = "5" ] && echo 全量引流 || echo 大陆白名单引流 )"
	init_shunt_chain_v4

	# 创建回国模式udp rule
	ensure_chain mangle SHADOWSOCKS_HOM
	# {black_list} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_HOM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# {gfwlist} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_HOM -p udp -m set --match-set gfwlist dst -j RETURN
	# {white_list} 直连
	append_if_not_exists mangle -A SHADOWSOCKS_HOM -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 代理
	append_if_not_exists mangle -A SHADOWSOCKS_HOM -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07
	
	#-----------------------FOR FILTER UDP443---------------------
	# 创建过滤 udp rule
	ensure_chain filter SHADOWSOCKS

	# {ignlist}不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS -p udp -m set --match-set ignlist dst -j RETURN

	# 创建gfw模式udp filter rule
	ensure_chain filter SHADOWSOCKS_GFW
	# {white_list} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GFW -p udp -m set --match-set white_list dst -j RETURN
	# {black_list} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GFW -p udp -m set --match-set black_list dst -j REJECT --reject-with icmp-port-unreachable
	# {gfwlist} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GFW -p udp -m set --match-set gfwlist dst -j REJECT --reject-with icmp-port-unreachable
	# {rotlist} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GFW -p udp -m set --match-set router dst -j REJECT --reject-with icmp-port-unreachable

	# 创建白名单模式udp filter rule
	ensure_chain filter SHADOWSOCKS_CHN
	# {black_list} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_CHN -p udp -m set --match-set black_list dst -j REJECT --reject-with icmp-port-unreachable
	# {chnlist} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_CHN -p udp -m set --match-set chnlist dst -j RETURN
	# {chnroute} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_CHN -p udp -m set --match-set chnroute dst -j RETURN
	# {white_list} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_CHN -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_CHN -p udp -j REJECT --reject-with icmp-port-unreachable

	# 创建游戏模式udp rule
	ensure_chain filter SHADOWSOCKS_GAM 
	# 游戏模式默认不过滤，创建一个空的就行

	# 创建glo模式udp rule
	ensure_chain filter SHADOWSOCKS_GLO
	# {white_list} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GLO -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_GLO -p udp -j REJECT --reject-with icmp-port-unreachable

	# 创建回国模式udp filter rule
	ensure_chain filter SHADOWSOCKS_HOM
	# {black_list} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_HOM -p udp -m set --match-set black_list dst -j REJECT --reject-with icmp-port-unreachable
	# {gfwlist} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_HOM -p udp -m set --match-set gfwlist dst -j RETURN
	# {white_list} 不过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_HOM -p udp -m set --match-set white_list dst -j RETURN
	# {剩余流量} 过滤udp 443
	append_if_not_exists filter -A SHADOWSOCKS_HOM -p udp -j REJECT --reject-with icmp-port-unreachable
	
	#-------------------------------------------------------
	# 局域网黑名单（不go proxy）/局域网黑名单（go proxy）
	lan_access_control $1

	# Block QUIC(UDP/443) to non-China destinations (HTTP/3) so clients fallback to TCP.
	apply_quic_block
	
	# DNS 劫持
	dns_hijack_control 4
	#-----------------------FOR ROUTER---------------------
	# router itself
	if [ "${ss_basic_mode}" != "6" ];then
		append_if_not_exists nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333

		# make sure these match go proxy inside router
		# append_if_not_exists mangle -A OUTPUT -p udp -m set --match-set router dst -j MARK --set-mark 0x07
		append_if_not_exists mangle -A OUTPUT -p udp -m set --match-set router dst -m udp --dport 53 -j MARK --set-mark 0x7/0xffffffff
	fi
	append_if_not_exists nat -A OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT

	# 把最后剩余流量重定向到相应模式的nat表中对应的主模式的链
	local acl_default_mode_runtime="$(resolve_acl_default_mode "$(if [ -n "${acl_nu}" ];then echo 1; else echo 0; fi)")"
	local acl_default_ports_runtime="$(resolve_acl_ports "$(resolve_acl_default_ports_raw)" "${acl_default_mode_runtime}")"
	local acl_default_ports_match="${acl_default_ports_runtime}"
	[ "${acl_default_ports_match}" = "all" ] && acl_default_ports_match=""
	append_if_not_exists nat -A SHADOWSOCKS -p tcp $(factor ${acl_default_ports_match} "-m multiport --dport") -j $(get_action_chain ${acl_default_mode_runtime})
	
	append_if_not_exists nat -A SHADOWSOCKS_EXT -p tcp $(factor ${acl_default_ports_match} "-m multiport --dport") -j $(get_action_chain ${acl_default_mode_runtime})

	local default_udp_flag=$(get_acl_udp_flag "" "${acl_default_mode_runtime}")
	local default_quic_flag=$(get_acl_quic_flag "" "${acl_default_mode_runtime}" "${default_udp_flag}")
	apply_acl_udp_rule "${acl_default_label}" "" "${acl_default_ports_match}" "${acl_default_mode_runtime}" "${default_udp_flag}" "${default_quic_flag}"
	
	# 重定所有流量到 SHADOWSOCKS
	KP_NU=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/KOOLPROXY/=' | head -n1)
	[ -z "${KP_NU}" ] && KP_NU=0
	INSET_NU=$(expr "${KP_NU}" + 1)
	iptables -t nat -I PREROUTING "${INSET_NU}" -p tcp -j SHADOWSOCKS
	
	[ "${mangle}" != "0" ] && append_if_not_exists mangle -A PREROUTING -p udp -j SHADOWSOCKS

	# FOR FILTER
	insert_if_not_exists filter -I FORWARD 1 -p udp --dport 443 -j SHADOWSOCKS

	if [ "$ss_basic_dns_hijack" == "1" ]; then
		echo_date "开启DNS劫持功能功能，防止DNS污染..."
		#INSET_NU_DNS=$(expr "${INSET_NU}" + 1)
		local INSET_NU_DNS=$((${INSET_NU} + 1))
		#append_if_not_exists nat -I PREROUTING "$INSET_NU_DNS" -p udp ! -s ${lan_ipaddr} --dport 53 -j SHADOWSOCKS_DNS
		for VLAN_INDEX in ${VLAN_INDEXS}
		do
			iptables -t nat -I PREROUTING "${INSET_NU_DNS}" -i br${VLAN_INDEX} -p udp -m udp --dport 53 -j SHADOWSOCKS_DNS_${VLAN_INDEX}
			let INSET_NU_DNS+=1
		done
	else
		echo_date "DNS劫持功能未开启，建议开启！"
	fi

	# QOS开启的情况下
	QOSO=$(iptables -t mangle -S | grep -o QOSO | wc -l)
	RRULE=$(iptables -t mangle -S | grep "A QOSO" | head -n1 | grep RETURN)
	if [ "$QOSO" -gt "1" -a -z "$RRULE" ]; then
		iptables -t mangle -I QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN
	fi

	if ipv6_proxy_enabled; then
		if ! _start_ipv6_iptables; then
			fallback_ipv6_proxy_to_ipv4 || return 1
		fi
	fi
}

_start_ipv6_iptables() {
	echo_date "写入ip6tables规则到ipv6 nat/mangle/filter表中..."

	resolve_ipv6_default_acl

	local ipv6_ports="${IPV6_ACL_DEFAULT_PORTS}"
	if [ "${ipv6_ports}" == "all" ];then
		ipv6_ports=""
		echo_date "加载IPv6默认ACL规则：【${IPV6_ACL_DEFAULT_LABEL}】【全部端口】模式为：$(get_mode_name ${IPV6_ACL_DEFAULT_MODE})"
	else
		echo_date "加载IPv6默认ACL规则：【${IPV6_ACL_DEFAULT_LABEL}】【${ipv6_ports}】模式为：$(get_mode_name ${IPV6_ACL_DEFAULT_MODE})"
	fi
	if [ -n "${IPV6_ACL_SKIP_CIDR}" ];then
		echo_date "IPv6 ACL提示：以下CIDR规则继续仅用于IPv4：${IPV6_ACL_SKIP_CIDR}"
	fi
	if [ -n "${IPV6_ACL_SKIP_NOMAC}" ];then
		echo_date "IPv6 ACL提示：以下主机未获取到MAC，继续仅用于IPv4：${IPV6_ACL_SKIP_NOMAC}"
	fi
	if [ "${IPV6_ACL_HAS_CUSTOM}" == "1" -a "${IPV6_ACL_ACTIVE_COUNT}" == "0" ];then
		echo_date "IPv6 ACL提示：当前没有可直接用于IPv6的自定义主机规则，全部IPv6流量将按默认规则处理。"
	fi

	#-----------------------FOR NAT TCP---------------------
	ensure_chain6 nat SHADOWSOCKS6 || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6 -p tcp -m set --match-set ignlist6 dst -j RETURN || return 1
	if [ "$ss_basic_dns_hijack" == "1" ]; then
		for VLAN_INDEX in ${VLAN_INDEXS}
		do
			ensure_chain6 nat SHADOWSOCKS6_DNS_${VLAN_INDEX} || return 1
		done
	fi

	ensure_chain6 nat SHADOWSOCKS6_GLO || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GLO -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GLO -p tcp -j REDIRECT --to-ports $(get_tproxy_port6) || return 1

	ensure_chain6 nat SHADOWSOCKS6_GFW || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GFW -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GFW -p tcp -m set --match-set black_list6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GFW -p tcp -m set --match-set gfwlist6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GFW -p tcp -m set --match-set router6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1

	ensure_chain6 nat SHADOWSOCKS6_CHN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_CHN -p tcp -m set --match-set black_list6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_CHN -p tcp -m set --match-set chnlist6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_CHN -p tcp -m set --match-set chnroute6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_CHN -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_CHN -p tcp -j REDIRECT --to-ports $(get_tproxy_port6) || return 1

	ensure_chain6 nat SHADOWSOCKS6_GAM || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GAM -p tcp -m set --match-set black_list6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GAM -p tcp -m set --match-set chnlist6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GAM -p tcp -m set --match-set chnroute6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GAM -p tcp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_GAM -p tcp -j REDIRECT --to-ports $(get_tproxy_port6) || return 1

	ensure_chain6 nat SHADOWSOCKS6_HOM || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_HOM -p tcp -m set --match-set black_list6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_HOM -p tcp -m set --match-set gfwlist6 dst -j RETURN || return 1
	append_if_not_exists6 nat -A SHADOWSOCKS6_HOM -p tcp -m set --match-set white_list6 dst -j RETURN || return 1

	#-----------------------FOR TPROXY UDP---------------------
	load_tproxy
	if [ -z "$(ip -6 rule show table 310 2>/dev/null | grep "fwmark 0x7")" ];then
		ip -6 rule add fwmark 0x07 table 310 >/dev/null 2>&1 || return 1
	fi
	if [ -z "$(ip -6 route show table 310 2>/dev/null | grep "^local ::/0 dev lo")" ];then
		ip -6 route add local ::/0 dev lo table 310 >/dev/null 2>&1 || return 1
	fi

	ensure_chain6 mangle SHADOWSOCKS6 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6 -p udp -m set --match-set ignlist6 dst -j RETURN || return 1

	ensure_chain6 mangle SHADOWSOCKS6_GFW || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GFW -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GFW -p udp -m set --match-set black_list6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GFW -p udp -m set --match-set gfwlist6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GFW -p udp -m set --match-set router6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1

	ensure_chain6 mangle SHADOWSOCKS6_CHN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_CHN -p udp -m set --match-set black_list6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_CHN -p udp -m set --match-set chnlist6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_CHN -p udp -m set --match-set chnroute6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_CHN -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_CHN -p udp -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1

	ensure_chain6 mangle SHADOWSOCKS6_GAM || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GAM -p udp -m set --match-set black_list6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GAM -p udp -m set --match-set chnlist6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GAM -p udp -m set --match-set chnroute6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GAM -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GAM -p udp -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1

	ensure_chain6 mangle SHADOWSOCKS6_GLO || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GLO -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_GLO -p udp -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1

	ensure_chain6 mangle SHADOWSOCKS6_HOM || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_HOM -p udp -m set --match-set black_list6 dst -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_HOM -p udp -m set --match-set gfwlist6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_HOM -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 mangle -A SHADOWSOCKS6_HOM -p udp -j TPROXY --on-port $(get_tproxy_port6) --tproxy-mark 0x07 || return 1

	#-----------------------FOR FILTER UDP443---------------------
	ensure_chain6 filter SHADOWSOCKS6 || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6 -p udp -m set --match-set ignlist6 dst -j RETURN || return 1

	ensure_chain6 filter SHADOWSOCKS6_GFW || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GFW -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GFW -p udp -m set --match-set black_list6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GFW -p udp -m set --match-set gfwlist6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GFW -p udp -m set --match-set router6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1

	ensure_chain6 filter SHADOWSOCKS6_CHN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_CHN -p udp -m set --match-set black_list6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_CHN -p udp -m set --match-set chnlist6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_CHN -p udp -m set --match-set chnroute6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_CHN -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_CHN -p udp -j REJECT --reject-with icmp6-port-unreachable || return 1

	ensure_chain6 filter SHADOWSOCKS6_GAM || return 1

	ensure_chain6 filter SHADOWSOCKS6_GLO || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GLO -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_GLO -p udp -j REJECT --reject-with icmp6-port-unreachable || return 1

	echo_date "创建IPv6 xray分流模式专用链，入口策略：$( [ "$(get_shunt_ingress_mode)" = "5" ] && echo 全量引流 || echo 大陆白名单引流 )"
	init_shunt_chain_v6 || return 1

	ensure_chain6 filter SHADOWSOCKS6_HOM || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_HOM -p udp -m set --match-set black_list6 dst -j REJECT --reject-with icmp6-port-unreachable || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_HOM -p udp -m set --match-set gfwlist6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_HOM -p udp -m set --match-set white_list6 dst -j RETURN || return 1
	append_if_not_exists6 filter -A SHADOWSOCKS6_HOM -p udp -j REJECT --reject-with icmp6-port-unreachable || return 1

	local acl_nu="${IPV6_ACL_RULES}"
	if [ -n "${acl_nu}" ];then
		for acl in ${acl_nu}
		do
			ipaddr=$(eval echo \$ss_acl_ip_${acl})
			source_rule6=$(get_acl_source_rule6 ${acl})
			if [ -z "${source_rule6}" ];then
				continue
			fi

			proxy_mode=$(eval echo \$ss_acl_mode_${acl})
			ports=$(resolve_acl_ports "$(eval echo \$ss_acl_port_${acl})" "${proxy_mode}")
			udp_flag=$(get_acl_udp_flag ${acl} ${proxy_mode})
			quic_flag=$(get_acl_quic_flag ${acl} ${proxy_mode} "${udp_flag}")
			if [ "${ports}" == "all" ]; then
				ports=""
				echo_date "加载IPv6 ACL规则：【${ipaddr}】【全部端口】模式为：$(get_mode_name ${proxy_mode})"
			else
				echo_date "加载IPv6 ACL规则：【${ipaddr}】【${ports}】模式为：$(get_mode_name ${proxy_mode})"
			fi

			append_if_not_exists6 nat -A SHADOWSOCKS6 ${source_rule6} -p tcp $(factor ${ports} "-m multiport --dport") -$(get_jump_mode ${proxy_mode}) $(get_action_chain6 ${proxy_mode}) || return 1
			apply_acl_udp_rule6 "${ipaddr}" "${source_rule6}" "${ports}" "${proxy_mode}" "${udp_flag}" "${quic_flag}" || return 1
			apply_acl_quic_filter_rule6 "${ipaddr}" "${source_rule6}" "${proxy_mode}" "${quic_flag}" || return 1
		done
	fi

	local default_udp_flag=$(get_acl_udp_flag "" "${IPV6_ACL_DEFAULT_MODE}")
	local default_quic_flag=$(get_acl_quic_flag "" "${IPV6_ACL_DEFAULT_MODE}" "${default_udp_flag}")
	append_if_not_exists6 nat -A SHADOWSOCKS6 -p tcp $(factor ${ipv6_ports} "-m multiport --dport") -j $(get_action_chain6 ${IPV6_ACL_DEFAULT_MODE}) || return 1
	apply_acl_udp_rule6 "${IPV6_ACL_DEFAULT_LABEL}" "" "${ipv6_ports}" "${IPV6_ACL_DEFAULT_MODE}" "${default_udp_flag}" "${default_quic_flag}" || return 1
	apply_acl_quic_filter_rule6 "${IPV6_ACL_DEFAULT_LABEL}" "" "${IPV6_ACL_DEFAULT_MODE}" "${default_quic_flag}" || return 1

	if ! ip6tables -t nat -C PREROUTING -p tcp -j SHADOWSOCKS6 >/dev/null 2>&1; then
		ip6tables -t nat -I PREROUTING 1 -p tcp -j SHADOWSOCKS6 >/dev/null 2>&1 || return 1
	fi

	if [ "$ss_basic_dns_hijack" == "1" ]; then
		echo_date "开启IPv6 DNS劫持功能，防止IPv6 DNS污染..."
		dns_hijack_control 6 || return 1
		local INSET_NU_DNS6=1
		for VLAN_INDEX in ${VLAN_INDEXS}
		do
			local br_ipv6=$(ip -6 addr show dev br${VLAN_INDEX} scope global 2>/dev/null | awk '/inet6/ {print $2}' | head -n1)
			[ -z "${br_ipv6}" ] && continue
			ip6tables -t nat -I PREROUTING "${INSET_NU_DNS6}" -i br${VLAN_INDEX} -p udp -m udp --dport 53 -j SHADOWSOCKS6_DNS_${VLAN_INDEX} >/dev/null 2>&1 || return 1
			let INSET_NU_DNS6+=1
		done
	else
		echo_date "IPv6 DNS劫持功能未开启，建议开启！"
	fi

	if [ "${ss_basic_mode}" != "6" ];then
		append_if_not_exists6 nat -A OUTPUT -p tcp -m set --match-set router6 dst -j REDIRECT --to-ports $(get_tproxy_port6) || return 1
		append_if_not_exists6 mangle -A OUTPUT -p udp -m set --match-set router6 dst -m udp --dport 53 -j MARK --set-mark 0x7/0xffffffff || return 1
	fi

	if [ "${mangle}" != "0" ];then
		if ! ip6tables -t mangle -C PREROUTING -p udp -j SHADOWSOCKS6 >/dev/null 2>&1; then
			ip6tables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS6 >/dev/null 2>&1 || return 1
		fi
	fi

	if ! ip6tables -t filter -C FORWARD -p udp --dport 443 -j SHADOWSOCKS6 >/dev/null 2>&1; then
		ip6tables -t filter -I FORWARD 1 -p udp --dport 443 -j SHADOWSOCKS6 >/dev/null 2>&1 || return 1
	fi

	return 0
}

restart_dnsmasq() {
	# 如果是梅林固件，需要将 【Tool - Other Settings  - Advanced Tweaks and Hacks - Wan: Use local caching DNS server as system resolver (default: No)】此处设置为【是】
	# 这将确保固件自身的DNS解析使用127.0.0.1，而不是上游的DNS。否则插件的状态检测将无法解析谷歌，导致状态检测失败。
	local DLC=$(nvram get dns_local_cache)
	if [ "$DLC" == "0" ]; then
		nvram set dns_local_cache=1
		nvram commit
	fi
	# 从梅林刷到官改固件，如果不重置固件，则dns_local_cache将会保留，会导致误判，所以需要改写一次以确保OK
	local LOCAL_DNS=$(cat /etc/resolv.conf|grep "127.0.0.1")
	if [ -z "$LOCAL_DNS" ]; then
		cat >/etc/resolv.conf <<-EOF
			nameserver 127.0.0.1
		EOF
	fi
	# Restart dnsmasq
	echo_date "重启dnsmasq服务..."
	service restart_dnsmasq >/dev/null 2>&1 &
	detect_running_status dnsmasq
}

load_module() {
	xt=$(lsmod | grep xt_set)
	OS=$(uname -r)
	if [ -f /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko -a -z "$xt" ]; then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
}

# write number into nvram with no commit
write_numbers() {
	nvram set update_gfwlist="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.gfwlist.date')"
	nvram set update_chnlist="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnlist.date')"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.date')"
	nvram set gfwlist_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.gfwlist.count')"
	nvram set chnroute_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.count')"
	nvram set chnroute_ips="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.count_ip')"
	nvram set chnlist_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnlist.count')"
}

remove_ss_reboot_job() {
	if [ -n "$(cru l | grep ss_reboot)" ]; then
		echo_date "【科学上网】：删除插件自动重启定时任务..."
		sed -i '/ss_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_reboot_job() {
	if [[ "${ss_reboot_check}" == "0" ]]; then
		remove_ss_reboot_job
	elif [[ "${ss_reboot_check}" == "1" ]]; then
		echo_date "【科学上网】：设置每天${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "2" ]]; then
		echo_date "【科学上网】：设置每周${ss_basic_week}的${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * "${ss_basic_week}" /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "3" ]]; then
		echo_date "【科学上网】：设置每月${ss_basic_day}日${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour} ${ss_basic_day}" * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "4" ]]; then
		if [[ "${ss_basic_inter_pre}" == "1" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_min}分钟重启插件..."
			cru a ss_reboot "*/"${ss_basic_inter_min}" * * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "2" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_hour}小时重启插件..."
			cru a ss_reboot "0 */"${ss_basic_inter_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "3" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_day}天${ss_basic_inter_hour}小时${ss_basic_time_min}分钟重启插件..."
			cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" */"${ss_basic_inter_day} " * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		fi
	elif [[ "${ss_reboot_check}" == "5" ]]; then
		check_custom_time=$(echo ss_basic_custom | base64_decode)
		echo_date "【科学上网】：设置每天${check_custom_time}时的${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${check_custom_time}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	fi
}

remove_ss_trigger_job() {
	if [ -n "$(cru l | grep ss_tri_check)" ]; then
		echo_date "删除插件触发重启定时任务..."
		sed -i '/ss_tri_check/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_trigger_job() {
	if current_node_server_uses_runtime_dns; then
		echo_date "检测到当前节点使用【动态解析】且服务器地址为域名，跳过触发重启任务设置。"
		remove_ss_trigger_job
		return 0
	fi

	if [ "$ss_basic_tri_reboot_time" == "0" ]; then
		remove_ss_trigger_job
	else
		if [ "$ss_basic_tri_reboot_policy" == "1" ]; then
			echo_date "设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启科学上网插件..."
		else
			echo_date "设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启dnsmasq..."
		fi
		echo_date "科学上网插件触发重启功能的日志将显示再系统日志内。"
		cru d ss_tri_check >/dev/null 2>&1
		cru a ss_tri_check "*/$ss_basic_tri_reboot_time * * * * /koolshare/scripts/ss_reboot_job.sh check_ip"
	fi
}

ss_post_start() {
	# 在SS插件启动成功后触发脚本
	local i
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort); do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 启动后触发脚本: $i -------------
		if [ -r "$i" ]; then
			$i start
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

ss_pre_stop() {
	# 在SS插件关闭前触发脚本
	local i
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort -r); do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 关闭前触发脚本: $i ------------
		if [ -r "$i" ]; then
			$i stop
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

stop_status() {
	kill -9 $(pidof ss_status_main.sh) >/dev/null 2>&1
	kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
	killall curl-status >/dev/null 2>&1
	rm -rf /tmp/upload/ss_status.txt
}

detect_ip(){
	local SUBJECT=$1
	local TIMEOUT=$2
	local METHOD=$3
	local CURL_IP_FLAG="-4"
	[ -z "${TIMEOUT}" ] && TIMEOUT="3"

	if [ "${METHOD}" == "1" ] && ipv6_proxy_enabled; then
		CURL_IP_FLAG=""
	fi

	if [ "${METHOD}" == "0" ];then
		# 检测国内ip
		local IP=$(run curl-fancyss ${CURL_IP_FLAG} -s -m ${TIMEOUT} ${SUBJECT} 2>&1 | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep -v "Terminated")
	elif [ "${METHOD}" == "1" ];then
		# 检测代理ip
		local SOCKS5_OPEN=$(netstat -nlpt 2>/dev/null|grep -w "23456"|grep -Eo "v2ray|xray|naive|tuic")
		if [ -n "${SOCKS5_OPEN}" ];then
			local IP=$(run curl-fancyss ${CURL_IP_FLAG} -s -x socks5h://127.0.0.1:23456 -m ${TIMEOUT} ${SUBJECT} 2>&1 | grep -v "Terminated")
		else
			local IP=$(run curl-fancyss ${CURL_IP_FLAG} -s -m  ${TIMEOUT} ${SUBJECT} 2>&1 | grep -v "Terminated")
		fi
	fi

	local IP=$(__valid_ip $IP)
	echo ${IP}
}

check_frn_public_ip(){
	echo_date "开始代理出口ip检测..."

	local SOCKS5_OPEN=$(netstat -nlp 2>/dev/null | grep -w "23456" | grep -Eo "v2ray|xray|naive|tuic" | head -n1)
	if [ -n "${SOCKS5_OPEN}" ];then
		echo_date "检测方式1：socks5"
	else
		echo_date "检测方式2：透明代理"
	fi
	
	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN_SRC="http://ip.sb"
		REMOTE_IP_FRN=$(detect_ip "${REMOTE_IP_FRN_SRC}" 5 1)
	fi
	
	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN_SRC="https://icanhazip.com/"
		REMOTE_IP_FRN=$(detect_ip "${REMOTE_IP_FRN_SRC}" 3 1)
	fi
	
	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN_SRC="https://ipecho.net/plain"
		REMOTE_IP_FRN=$(detect_ip "${REMOTE_IP_FRN_SRC}" 4 1)
	fi

	if [ -n "${REMOTE_IP_FRN}" ];then
		__valid_ip46 ${REMOTE_IP_FRN}
		if [ "$?" == "0" ]; then
			# ipv4
			ipset test chnroute ${REMOTE_IP_FRN} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 国外ip
				echo_date "代理服务器出口地址：${REMOTE_IP_FRN}，属地：海外，来源：${REMOTE_IP_FRN_SRC}"
			else
				# 国内ip
				echo_date "代理服务器出口地址：${REMOTE_IP_FRN}，属地：大陆，来源：${REMOTE_IP_FRN_SRC}"
			fi
		elif [ "$?" == "1" ]; then
			# ipv6
			echo_date "代理服务器出口地址：${REMOTE_IP_FRN}，来源：${REMOTE_IP_FRN_SRC}"
		fi
	else
		echo_date "代理服务器出口地址检测失败！可能是以下原因："
		echo_date "---------------------------------------------------------"
		echo_date "1. 节点失效，请尝试更新订阅、更换节点"
		echo_date "2. 节点延迟较高，请尝试更换低延迟节点"
		if [ "${FDNS_OK_FLAG}" != "1" ];then
			echo_date "3. DNS解析失效，请尝试更换DNS方案"
		fi
		echo_date "插件将会继续运行，但是不保证代理工作正常！"
		echo_date "---------------------------------------------------------"
		# close_in_five flag
	fi


	# 检测节点解析结果
	if [ -n "${ss_basic_server_ip}" ]; then
		__valid_ip46 "${ss_basic_server_ip}"
		if [ "$?" == "0" ]; then
			# ipv4
			ipset test chnroute ${ss_basic_server_ip} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 国外ip
				ss_real_server_ip="${ss_basic_server_ip}"
				echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：海外，来源：${ss_basic_server_orig}"
			else
				# 国内ip
				ss_real_server_ip=""
				echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：大陆，来源：${ss_basic_server_orig}"
			fi
		elif [ "$?" == "1" ]; then
			# ipv6
			ipset test chnroute6 ${ss_basic_server_ip} >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# 国外ip
				ss_real_server_ip="${ss_basic_server_ip}"
				echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：海外，来源：${ss_basic_server_orig}"
			else
				# 国内ip
				ss_real_server_ip=""
				echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：大陆，来源：${ss_basic_server_orig}"
			fi
		fi
	fi
}

finish_start(){
	# get foreign ip
	if [ "${ss_basic_nofrnipcheck}" != "1" ];then
		echo_date "---------------------------------------------------------"
		echo_date "所有服务和规则加载完毕，运行一些检测..."
		check_frn_public_ip
	fi
}

check_status() {
	dbus remove ss_basic_wait
	if [ "$ss_failover_enable" == "1" ]; then
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssf_status.txt
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssc_status.txt
		run start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status_main.sh
	fi

	(
		# 对一些域名进行预解析，如果本地有解析缓存，解析没有走路由器，则ipset没有写入导致无法走代理，所以一些域名可以预解析一次
		run_bg dnsclient -46 -t 5 -i 2 @127.0.0.1 openai.com
		run_bg dnsclient -46 -t 5 -i 2 @127.0.0.1 chat.openai.com
		run_bg dnsclient -46 -t 5 -i 2 @127.0.0.1 stun.syncthing.net
	)&

}

disable_ss() {
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date ------------------------- 关闭【科学上网】 -----------------------------
	ss_pre_stop
	set_skin
	dbus remove ss_basic_server_ip
	stop_status
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	restart_dnsmasq
	flush_iptables
	flush_ipset
	kill_cron_job
	rm -rf /tmp/upload/fancyss_node_name.txt
	dbus set ss_basic_status="0"
	echo_date ------------------------ 【科学上网】已关闭 ----------------------------
}

apply_ss() {
	local shunt_hot_restart="0"
	local shunt_prev_xray_json=""

	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	if [ "${ss_basic_status}" == "1" ];then
		if shunt_hot_restart_eligible; then
			shunt_prev_xray_json="/tmp/fss_shunt_prev_xray.json.$$"
			cp -f /koolshare/ss/xray.json "${shunt_prev_xray_json}" >/dev/null 2>&1 || shunt_prev_xray_json=""
			if [ -s "${shunt_prev_xray_json}" ]; then
				shunt_hot_restart="1"
				echo_date "[hot-reload] 检测到 xray 分流热重载已启用，将在新配置生成后判断是否可保留当前 xray 进程。"
			fi
		fi
		echo_date ------------------------- 关闭【科学上网】 -----------------------------
		ss_pre_stop
		stop_status
		if [ "${shunt_hot_restart}" != "1" ]; then
			kill_process
		fi
		remove_ss_trigger_job
		remove_ss_reboot_job
		restore_conf
		restart_dnsmasq
		flush_iptables
		flush_ipset
		kill_cron_job
	fi
	# pre-start
	echo_date ------------------------- 启动【科学上网】 -----------------------------
	# start
	FSS_SKIP_XRAY_PORT_CLEANUP=""
	[ "${shunt_hot_restart}" = "1" ] && FSS_SKIP_XRAY_PORT_CLEANUP="1"
	prepare_system
	resolv_server_ip
	load_module
	creat_ipset
	create_dnsmasq_conf
	add_white_black
	# 生成代理主程序配置
	if [ "${ss_basic_mode}" = "7" ]; then
		creat_shunt_json
	else
		[ "${ss_basic_type}" == "0" ] && creat_xray_ss_json
		[ "${ss_basic_type}" == "1" ] && creat_ssr_json
		[ "${ss_basic_type}" == "3" ] && creat_vmess_json
		[ "${ss_basic_type}" == "4" ] && creat_vless_json
		[ "${ss_basic_type}" == "5" ] && creat_trojan_json
		[ "${ss_basic_type}" == "8" ] && creat_hy2_json
	fi

	local bootstrap_dns_first="0"
	if should_bootstrap_dns_before_proxy; then
		bootstrap_dns_first="1"
		restart_dnsmasq
		start_dns_x
		if ! refresh_current_node_server_ip_runtime; then
			echo_date "节点服务器域名运行时解析失败，将继续启动代理主程序，并等待客户端后续自行解析。"
		fi
	fi

	# 开启代理主程序
	if [ "${ss_basic_mode}" = "7" ]; then
		if [ "${shunt_hot_restart}" = "1" ] && shunt_configs_equivalent "${shunt_prev_xray_json}" "/koolshare/ss/xray.json"; then
			echo_date "[hot-reload] 检测到 xray 配置未变化，保留当前 xray 进程并复用已有运行时统计。"
		else
			if [ "${shunt_hot_restart}" = "1" ]; then
				echo_date "[hot-reload] 检测到 xray 配置已变化，回退为重启 xray 主进程。"
				FSS_SKIP_XRAY_PORT_CLEANUP=""
				kill_process
			fi
			start_xray
		fi
	else
		[ "${ss_basic_type}" == "0" ] && start_xray
		[ "${ss_basic_type}" == "1" ] && start_ssr_redir
		[ "${ss_basic_type}" == "3" ] && start_xray
		[ "${ss_basic_type}" == "4" ] && start_xray
		[ "${ss_basic_type}" == "5" ] && start_trojan
		[ "${ss_basic_type}" == "6" ] && start_naive
		[ "${ss_basic_type}" == "7" ] && start_tuic
		[ "${ss_basic_type}" == "8" ] && start_hy2
	fi

	if [ "${bootstrap_dns_first}" != "1" ]; then
		restart_dnsmasq
		start_dns_x
	fi

	get_proxy_server_ip
	load_iptables
	#restart_dnsmasq
	auto_start
	write_cron_job
	set_ss_reboot_job
	set_ss_trigger_job
	write_numbers
	finish_start
	ss_post_start
	check_status
	if [ "${ss_basic_mode}" = "7" ] && [ "${ss_basic_shunt_hot_reload}" = "1" ] && [ -x "/koolshare/scripts/ss_shunt_hot_reload.sh" ]; then
		sh /koolshare/scripts/ss_shunt_hot_reload.sh seed >/dev/null 2>&1 || true
	fi
	# store current status
	dbus set ss_basic_status="1"
	echo_date ------------------------ 【科学上网】 启动完毕 ------------------------
	FSS_SKIP_XRAY_PORT_CLEANUP=""
	rm -f "${shunt_prev_xray_json}" >/dev/null 2>&1
}

# for debug
get_status() {
	echo_date
	echo_date =========================================================
	echo_date "PID of this script: $$"
	echo_date "PPID of this script: $PPID"
	echo_date ========== 本脚本的PID ==========
	ps | grep $$ | grep -v grep
	echo_date ========== 本脚本的PPID ==========
	ps | grep $PPID | grep -v grep
	echo_date ========== 所有运行中的shell ==========
	ps | grep "\.sh" | grep -v grep
	echo_date ------------------------------------

	WAN_ACTION=$(ps | grep /jffs/scripts/wan-start | grep -v grep)
	NAT_ACTION=$(ps | grep /jffs/scripts/nat-start | grep -v grep)
	WEB_ACTION=$(ps | grep "ss_config.sh" | grep -v grep)
	[ -n "${WAN_ACTION}" ] && echo_date "路由器开机触发fancyss重启！"
	[ -n "${NAT_ACTION}" ] && echo_date "路由器防火墙触发fancyss重启！"
	[ -n "${WEB_ACTION}" ] && echo_date "WEB提交操作触发fancyss重启！"

	iptables -nvL PREROUTING -t nat
	iptables -nvL OUTPUT -t nat
	iptables -nvL SHADOWSOCKS -t nat
	iptables -nvL SHADOWSOCKS_EXT -t nat
	iptables -nvL SHADOWSOCKS_GFW -t nat
	iptables -nvL SHADOWSOCKS_CHN -t nat
	iptables -nvL SHADOWSOCKS_GAM -t nat
	iptables -nvL SHADOWSOCKS_GLO -t nat
	iptables -nvL SHADOWSOCKS_SHU -t nat 2>/dev/null
}

apply_ss_by_nat() {
	# 1. 开机的时候会触发，此时其它组件都没有准备，需要开启
	# 2. 防火墙重启，重新拨号等会触发，此时其它组件都是ok的，只需要重启iptables
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date "restart by nat!"
	flush_iptables
	load_iptables
	echo_date
	echo_date ------------------------ 【科学上网】 启动完毕 ------------------------
}

start_ws(){
	if [ -x "/koolshare/bin/websocketd" -a -f "/koolshare/ss/websocket" ];then
		if [ -z "$(pidof websocketd)" ];then
			run_bg websocketd --port=803 /koolshare/ss/websocket
		fi
	fi
}

# =========================================================================

case $ACTION in
start)
	# start on wan-start
	set_lock
	if [ "$ss_basic_enable" == "1" ]; then
		logger "[软件中心]: wan-start启动科学上网插件！"
		apply_ss 2>&1 | tee -a "$LOG_FILE" | tee -a "/tmp/upload/ss_wan_log.txt"
		echo XU6J03M6 | tee -a "$LOG_FILE"
		start_ws
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	unset_lock
	;;
stop)
	set_lock
	disable_ss
	echo_date
	echo_date "你已经成功关闭科学上网服务~"
	echo_date "See you again!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	;;
restart)
	# start/restart by web or user
	set_lock
	apply_ss
	start_ws
	echo_date
	echo_date "Across the Great Wall we can reach every corner in the world!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	;;
flush_nat)
		set_lock
		flush_iptables
		unset_lock
		;;
start_nat)
	# start on nat-start
	SOCKS5_OPEN=$(netstat -nlpt 2>/dev/null|grep -w "23456"|grep -Eo "v2ray|xray|naive|tuic")
	if [ -z "${SOCKS5_OPEN}" ];then
		# 代理程序没有运行，可能是刚开机，不继续
		return 0
	fi
	set_lock
	if [ "$ss_basic_enable" == "1" ]; then
		logger "[软件中心]: nat-start触发fancyss重启！"
		true >"$LOG_FILE"
		apply_ss_by_nat 2>&1 | tee -a "$LOG_FILE" | tee -a "/tmp/upload/ss_nat_log.txt"
		echo XU6J03M6 | tee -a "$LOG_FILE"
	fi
	unset_lock
	;;
restart_chinadns_ng)
	start_chinadns_ng
	;;
refresh_node_direct_dns)
	set_lock
	refresh_node_direct_dns
	unset_lock
	;;
esac
