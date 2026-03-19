#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh

run(){
	env -i PATH=${PATH} "$@"
}

GET_MODE_NAME() {
	case "${ss_basic_mode}" in
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
	esac
}

GET_MODEL(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		echo "${ODMPID}"
	else
		echo "${PRODUCTID}"
	fi
}

GET_FW_TYPE() {
	local KS_TAG=$(nvram get extendno|grep -E "_kool")
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			echo "koolshare 官改固件"
		else
			echo "koolshare 梅林改版固件"
		fi
	else
		if [ "$(uname -o | grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

GET_FW_VER(){
	local BUILD=$(nvram get buildno)
	local FWVER=$(nvram get extendno)
	echo ${BUILD}_${FWVER}
}

GET_PROXY_TOOL(){
	case "${ss_basic_type}" in
	0)
		echo "xray-core"
		;;
	1)
		echo "shadowsocksR"
		;;
	3)
		if [ "${ss_basic_vcore}"  == "1" ];then
			echo "xray-core"
		else
			echo "v2ray-core"
		fi
		;;
	4)
		echo "xray-core"
		;;
	5)
		echo "xray-core"
		;;
	6)
		echo "naive"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "xray-core"
		;;
	esac
}

GET_TYPE_NAME(){
	case "$1" in
	0)
		echo "SS"
		;;
	1)
		echo "SSR"
		;;
	3)
		echo "v2ray"
		;;
	4)
		echo "xray"
		;;
	5)
		echo "trojan"
		;;
	6)
		echo "NaïveProxy"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
		;;
	esac
}

GET_NODES_TYPE(){
	local TYPE
	local NUBS
	local STATUS=$(dbus list ssconf|grep _type_|awk -F "=" '{print $NF}' | sort -n | uniq -c | sed 's/^[[:space:]]\+//g' | sed 's/[[:space:]]/|/g')
	for line in ${STATUS}
	do
		TYPE=$(echo $line | awk -F"|" '{print $2}')
		NUBS=$(echo $line | awk -F"|" '{print $1}')
		RESULT="${RESULT}$(GET_TYPE_NAME ${TYPE})节点 ${NUBS}个 | "
	done
	RESULT=$(echo ${RESULT} | sed 's/|$//g')
	echo ${RESULT}
}

GET_INTERVAL() {
	case "$1" in
	1)
		echo "2s -3s"
		;;
	2)
		echo "4s -7s"
		;;
	3)
		echo "8s -15s"
		;;
	4)
		echo "16s - 31s"
		;;
	5)
		echo "32s - 63s"
		;;
	esac
}

GET_FAILOVER(){
	if [ "${ss_failover_enable}" == "1" ]; then
		echo "开启，状态检测时间间隔: $(GET_INTERVAL ${ss_basic_interval})"
	else
		echo "关闭"
	fi
}

GET_RULE_UPDATE(){
	if [ "${ss_basic_rule_update}" == "1" ]; then
		echo "规则定时更新开启，每天${ss_basic_rule_update_time}:00更新规则"
	else
		echo "规则定时更新关闭"
	fi
}

GET_SUBS_UPDATE(){
	if [ "${ss_basic_node_update}" = "1" ]; then
		if [ "${ss_basic_node_update_day}" = "7" ]; then
			echo "订阅定时更新开启，每天${ss_basic_node_update_hr}:00自动更新订阅。" 
		else
			echo "订阅定时更新开启，星期${ss_basic_node_update_day}的${ss_basic_node_update_hr}点自动更新订阅。"
		fi
	else
		echo "订阅定时更新关闭！"
	fi
}

GET_CURRENT_NODE_TYPE(){
	#local TYPE=$(dbus get ss_node_${ssconf_basic_node} | base64_decode | run jq '.type')
	echo "$(GET_TYPE_NAME ${ss_basic_type})节点"
}

GET_CURRENT_NODE_NAME(){
	#local NAME=$(dbus get ss_node_${ssconf_basic_node} | base64_decode | run jq '.name')
	echo "${ss_basic_name}"
}

GET_VM_RSS(){
	# Backward-compatible wrapper for single pid; supports multiple pids too.
	GET_VM_RSS_MULTI "$@"
}

__format_kb() {
	# $1: integer KB
	# output: 123KB | 12.3MB
	awk -v val_kb="${1:-0}" 'BEGIN{
		if (val_kb < 1024) {
			printf "%.0fKB", val_kb
		} else {
			printf "%.1fMB", val_kb/1024
		}
	}'
}

__get_vm_rss_kb() {
	# $1: pid, output integer KB (0 if missing)
	[ -n "$1" ] || { echo 0; return 1; }
	[ -r "/proc/$1/status" ] || { echo 0; return 1; }
	awk '$1=="VmRSS:"{print $2; exit}' "/proc/$1/status" 2>/dev/null | awk 'NF{print;exit} END{if(NR==0)print 0}'
}

GET_VM_RSS_MULTI() {
	# Usage: GET_VM_RSS_MULTI <pid1> [pid2 ...]
	# Output:
	# - single pid: "12.3MB"
	# - multi pids : "1.0MB 0.8MB (1.8MB)"
	local rss_list=""
	local total_kb=0
	local count=0
	local pid kb

	for pid in "$@"; do
		[ -n "${pid}" ] || continue
		kb="$(__get_vm_rss_kb "${pid}")"
		[ -n "${kb}" ] || kb=0
		rss_list="${rss_list}$(__format_kb "${kb}") "
		total_kb=$((total_kb + kb))
		count=$((count + 1))
	done

	# Trim trailing space
	rss_list="${rss_list% }"

	[ "${count}" -eq 0 ] && return 0
	if [ "${count}" -eq 1 ]; then
		echo "${rss_list}"
	else
		echo "${rss_list} ($(__format_kb "${total_kb}"))"
	fi
}

GET_PROG_STAT(){
	echo
	echo "1️⃣ 检测当前相关进程工作状态："
	echo "--------------------------------------------------------------------------------------------------------"
	echo "程序		状态		作用		PID		内存"

	# proxy core program
if [ "${ss_basic_type}" == "1" ]; then
		# ssr
		local SSR_REDIR_PID=$(pidof rss-redir)
		local SSR_REDIR_RSS=$(GET_VM_RSS_MULTI ${SSR_REDIR_PID})
		if [ -n "${SSR_REDIR_PID}" ];then
			echo "ssr-redir	运行中🟢		透明代理		${SSR_REDIR_PID}		${SSR_REDIR_RSS}"
		else
			echo "ssr-redir	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "0" -o "${ss_basic_type}" == "3" -o "${ss_basic_type}" == "4" -o "${ss_basic_type}" == "5" -o "${ss_basic_type}" == "8" ]; then
		# xray
		local XRAY_PID=$(pidof xray)
		local XRAY_RSS=$(GET_VM_RSS_MULTI ${XRAY_PID})
		if [ -n "${XRAY_PID}" ];then
			echo "Xray		运行中🟢		透明代理		${XRAY_PID}		${XRAY_RSS}"
		else
			echo "Xray	未运行🔴"
		fi
		local OBFS_SWITCH=$(dbus get ssconf_basic_ss_obfs_${ssconf_basic_node})
		if [ -n "${OBFS_SWITCH}" -a "${OBFS_SWITCH}" != "0" ]; then
			local SIMPLEOBFS_PID=$(pidof obfs-local)
			local SIMPLEOBFS_RSS=$(GET_VM_RSS_MULTI ${SIMPLEOBFS_PID})
			if [ -n "${SIMPLEOBFS_PID}" ]; then
				echo "obfs-local	运行中🟢		混淆插件		${SIMPLEOBFS_PID}		${SIMPLEOBFS_RSS}"
			else
				echo "obfs-local	未运行🔴		混淆插件"
			fi
		fi
	elif [ "${ss_basic_type}" == "6" ]; then
		# naive
		local NAIVE_PID=$(pidof naive)
		local NAIVE_RSS=$(GET_VM_RSS_MULTI ${NAIVE_PID})
		if [ -n "${NAIVE_PID}" ]; then
			echo "naive		运行中🟢		socks5		${NAIVE_PID}		${NAIVE_RSS}"
		else
			echo "naive		未运行🔴		socks5"
		fi
		local IPT2SOCKS_PID=$(pidof ipt2socks)
		local IPT2SOCKS_RSS=$(GET_VM_RSS_MULTI ${IPT2SOCKS_PID})
		if [ -n "${IPT2SOCKS_PID}" ]; then
			echo "ipt2socks	运行中🟢		透明代理		${IPT2SOCKS_PID}		${IPT2SOCKS_RSS}"
		else
			echo "ipt2socks	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "7" ]; then
		# tuic
		local TUIC_PID=$(pidof tuic-client)
		local TUIC_RSS=$(GET_VM_RSS_MULTI ${TUIC_PID})
		if [ -n "${TUIC_PID}" ]; then
			echo "tuic-client	运行中🟢		socks5		${TUIC_PID}		${TUIC_RSS}"
		else
			echo "tuic-client	未运行🔴		socks5"
		fi
		local IPT2SOCKS_PID=$(pidof ipt2socks)
		local IPT2SOCKS_RSS=$(GET_VM_RSS_MULTI ${IPT2SOCKS_PID})
		if [ -n "${IPT2SOCKS_PID}" ]; then
			echo "ipt2socks	运行中🟢		透明代理		${IPT2SOCKS_PID}		${IPT2SOCKS_RSS}"
		else
			echo "ipt2socks	未运行🔴		透明代理"
		fi
	fi

	# DNS program
	if [ "${ss_basic_dns_plan}" == "1" ];then
		# chinadns-ng
		local CHNG_PID=$(pidof chinadns-ng)
		local CHNG_RSS=$(GET_VM_RSS_MULTI ${CHNG_PID})
		if [ -n "${CHNG_PID}" ];then
			echo "chinadns-ng	运行中🟢		DNS分流		${CHNG_PID}		${CHNG_RSS}"
		else
			echo "chinadns-ng	未运行🔴		DNS分流"
		fi
	else
		# smartdns
		local SMRT_PID=$(pidof smartdns)
		local SMRT_RSS=$(GET_VM_RSS_MULTI ${SMRT_PID})
		if [ -n "${SMRT_PID}" ];then
			echo "smartdns	运行中🟢		DNS分流		${SMRT_PID}		${SMRT_RSS}"
		else
			echo "smartdns	未运行🔴		DNS分流"
		fi
	fi
		
	if [ "${ss_basic_dns_serverx}" != "1" ];then
		local DMQ_PID=$(pidof dnsmasq)
		local DMQ_RSS=$(GET_VM_RSS_MULTI ${DMQ_PID})
		if [ -n "${DMQ_PID}" ];then
			echo "dnsmasq		运行中🟢		DNS解析		${DMQ_PID}	${DMQ_RSS}"
		else
			echo "dnsmasq	未运行🔴		DNS解析"
		fi
	fi
	echo --------------------------------------------------------------------------------------------------------
}

ECHO_VERSION(){
	echo
	echo "2️⃣插件主要二进制程序版本："
	echo "--------------------------------------------------------------------------------------------------------"
	echo "程序			版本			备注"
	if [ -x "/koolshare/bin/xray" ];then
		echo "xray			$(run xray -version|head -n1|awk '{print $2}')			https://github.com/XTLS/Xray-core"
	fi
	if [ -x "/koolshare/bin/v2ray" ];then
		local v2_info_all=$(run v2ray version|head -n1)
		echo "v2ray			$(echo ${v2_info_all}|awk '{print $2}')			https://github.com/v2fly/v2ray-core"
	fi
	if [ -x "/koolshare/bin/naive" ];then
		echo "naive			$(run naive --version|awk '{print $NF}')		https://github.com/klzgrad/naiveproxy"
	fi
	if [ -x "/koolshare/bin/tuic-client" ];then
		echo "tuic-client		$(run tuic-client -V|awk '{print $NF}')			https://github.com/Itsusinn/tuic"
	fi
	if [ -x "/koolshare/bin/sslocal" ];then
		local SSRUST_VER=$(run /koolshare/bin/sslocal --version|awk '{print $NF}' 2>/dev/null)
		if [ -n "${SSRUST_VER}" ];then
			echo "sslocal			${SSRUST_VER}			https://github.com/shadowsocks/shadowsocks-rust"
		fi
	fi
	echo "obfs-local		$(run obfs-local -h|sed '/^$/d'|head -n1|awk '{print $NF}')			https://github.com/shadowsocks/simple-obfs"
	echo "ssr-redir		$(run rss-redir -h|sed '/^$/d'|head -n1|awk '{print $2}')			https://github.com/shadowsocksrr/shadowsocksr-libev"
	echo "ssr-local		$(run rss-local -h|sed '/^$/d'|head -n1|awk '{print $2}')			https://github.com/shadowsocksrr/shadowsocksr-libev"
	if [ -x "/koolshare/bin/chinadns-ng" ];then
		echo "chinadns-ng		$(run chinadns-ng -V | awk '{print $2}')		https://github.com/zfl9/chinadns-ng"
	fi
	if [ -x "/koolshare/bin/smartdns" ];then
		echo "smartdns		$(run smartdns -v|awk '{print $2}')	https://github.com/pymumu/smartdns"
	fi
	echo --------------------------------------------------------------------------------------------------------
}

ECHO_IPTABLES(){
	echo
	echo "3️⃣检测iptbales工作状态："
	echo "----------------------------------------------------- nat表 PREROUTING 链 -------------------------------------------------------"
	iptables -nvL PREROUTING -t nat
	echo
	echo "----------------------------------------------------- nat表 OUTPUT 链 -----------------------------------------------------------"
	iptables -nvL OUTPUT -t nat
	echo
	echo "----------------------------------------------------- nat表 SHADOWSOCKS 链 ------------------------------------------------------"
	iptables -nvL SHADOWSOCKS -t nat
	echo
	echo "----------------------------------------------------- nat表 SHADOWSOCKS_EXT 链 --------------------------------------------------"
	iptables -nvL SHADOWSOCKS_EXT -t nat
	echo
	if [ "${ss_basic_dns_hijack}" == "1" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_DNS 链 --------------------------------------------------"
		iptables -nvL SHADOWSOCKS_DNS -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "1" -o -n "${gfw_on}" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_GFW 链 --------------------------------------------------"
		iptables -nvL SHADOWSOCKS_GFW -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "2" -o -n "${chn_on}" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_CHN 链 ---------------------------------------------------"
		iptables -nvL SHADOWSOCKS_CHN -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "3" -o -n "${game_on}" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_GAM 链 ---------------------------------------------------"
		iptables -nvL SHADOWSOCKS_GAM -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "5" -o -n "${all_on}" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_GLO 链 ---------------------------------------------------"
		iptables -nvL SHADOWSOCKS_GLO -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "6" ];then
		echo "----------------------------------------------------- nat表 SHADOWSOCKS_HOM 链 ---------------------------------------------------"
		iptables -nvL SHADOWSOCKS_HOM -t nat
		echo
	fi
	if [ "${ss_basic_mode}" == "3" -o -n "${game_on}" ];then
		echo "------------------------------------------------------ mangle表 PREROUTING 链 ----------------------------------------------------"
		iptables -nvL PREROUTING -t mangle
		echo
		echo "------------------------------------------------------ mangle表 SHADOWSOCKS 链 ---------------------------------------------------"
		iptables -nvL SHADOWSOCKS -t mangle
		echo
		echo "------------------------------------------------------ mangle表 SHADOWSOCKS_GAM 链 -----------------------------------------------"
		iptables -nvL SHADOWSOCKS_GAM -t mangle
	fi
	echo "---------------------------------------------------------------------------------------------------------------------------------"
	echo
}

check_status() {
	local LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	local pkg_name=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_NAME=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_exta=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_EXTA=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_vers=$(dbus get ss_basic_version_local)
	local CURR_NAME=${pkg_name}_${pkg_arch}_${pkg_type}${pkg_exta}
	local CURR_VERS=$(cat /koolshare/ss/version)
	local CURR_BAKD=$(echo ${ss_wan_black_domain} | base64_decode | sed '/^#/d' | sed 's/$/\n/' | sed '/^$/d' | wc -l)
	local CURR_BAKI=$(echo ${ss_wan_black_ip} | base64_decode | sed '/^#/d' | sed 's/$/\n/' | sed '/^$/d' | wc -l)
	local CURR_WHTD=$(echo ${ss_wan_white_domain} | base64_decode |sed '/^#/d'|sed 's/$/\n/' | sed '/^$/d' | wc -l)
	local CURR_WHTI=$(echo ${ss_wan_white_ip} | base64_decode | sed '/^#/d' | sed 's/$/\n/' | sed '/^$/d' | wc -l)
	local CURR_SUBS=$(echo ${ss_online_links} | base64_decode | sed 's/^[[:space:]]//g' | grep -Ec "^http")
	local CURR_NODE=$(dbus list ssconf | grep "_name_" | wc -l)
	local GFWVERSIN=$(cat /koolshare/ss/rules/rules.json.js|run jq -r '.gfwlist.date')
	local CHNVERSIN=$(cat /koolshare/ss/rules/rules.json.js|run jq -r '.chnroute.date')
	local CDNVERSIN=$(cat /koolshare/ss/rules/rules.json.js|run jq -r '.chnlist.date')

	echo "🟠 路由型号：$(GET_MODEL)"
	echo "🟠 固件类型：$(GET_FW_TYPE)"
	echo "🟠 固件版本：$(GET_FW_VER)"
	echo "🟠 路由时间：$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")"
	echo "🟠 插件版本：${CURR_NAME} ${CURR_VERS}"
	echo "🟠 代理模式：$(GET_MODE_NAME)"
	echo "🟠 当前节点：$(GET_CURRENT_NODE_NAME)"
	echo "🟠 节点类型：$(GET_CURRENT_NODE_TYPE)"
	echo "🟠 程序核心：$(GET_PROXY_TOOL)"
	echo "🟠 黑名单数：域名 ${CURR_BAKD}条，IP/CIDR ${CURR_BAKI}条"
	echo "🟠 白名单数：域名 ${CURR_WHTD}条，IP/CIDR ${CURR_WHTI}条"
	echo "🟠 订阅数量：${CURR_SUBS}个"
	echo "🟠 节点数量：${CURR_NODE}个"
	echo "🟠 节点类型：$(GET_NODES_TYPE)"
	echo "🟠 规则版本：gfwlist ${GFWVERSIN} | chnlist ${CDNVERSIN} | chnroute ${CHNVERSIN}"
	echo "🟠 规则更新：$(GET_RULE_UPDATE)"
	echo "🟠 订阅更新：$(GET_SUBS_UPDATE)"
	echo "🟠 故障转移：$(GET_FAILOVER)"
	
	GET_PROG_STAT

	ECHO_VERSION

	ECHO_IPTABLES
}

true > /tmp/upload/ss_proc_status.txt
if [ "${ss_basic_enable}" == "1" ]; then
	check_status | tee /tmp/upload/ss_proc_status.txt 2>&1
else
	echo "插件尚未启用！" | tee /tmp/upload/ss_proc_status.txt 2>&1
fi

if [ "$#" == "1" ];then
	http_response $1
fi
