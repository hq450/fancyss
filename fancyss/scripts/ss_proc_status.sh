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

GET_DNS_TYPE() {
	if [ "${ss_basic_advdns}" == "1" ]; then
		echo "进阶DNS方案：$(get_adv_plan)"
	else
		echo "基础DNS方案：$(get_old_plan)"
	fi
}

get_adv_plan(){
	if [ "${ss_dns_plan}" == "1" ]; then
		echo "chinadns-ng"
	elif [ "${ss_dns_plan}" == "2" ]; then
		echo "SmartDNS"
	elif [ "${ss_dns_plan}" == "3" ]; then
		echo "dohclient"
	fi
}


get_old_plan() {
	case "${ss_foreign_dns}" in
	3)
		echo "dns2socks"
		;;
	4)
		if [ -n "${ss_basic_rss_obfs}" ]; then
			echo "ssr-tunnel"
		else
			echo "ss-tunnel"
		fi
		;;
	7)
		[ "${ss_basic_type}" == "3" ] && echo "v2ray_dns"
		[ "${ss_basic_type}" == "4" ] && echo "xray_dns"
		[ "${ss_basic_type}" == "5" -a "${ss_basic_vcore}" == "1" ] && echo "xray_dns"
		;;
	9)
		echo "SmartDNS"
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
		if [ "${ss_basic_rust}" == "1" ];then
			echo "shadowsocks-rust"
		else
			echo "shadowsocks-libev"
		fi
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
		if [ "${ss_basic_tcore}"  == "1" ];then
			echo "xray-core"
		else
			echo "trojan"
		fi
		;;
	6)
		echo "naive"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
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

GET_PROG_STAT(){
	echo
	echo "1️⃣ 检测当前相关进程工作状态："
	echo "--------------------------------------------------------------------------------------------------------"
	echo "程序		状态		作用		PID"

	# proxy core program
	if [ "${ss_basic_type}" == "0" ]; then
		# ss
		if [ "${ss_basic_rust}" == "1" ]; then
			local SS_RUST=$(ps | grep "sslocal" | grep "3333" | awk '{print $1}')
			if [ -n "${SS_RUST}" ]; then
				echo "sslocal		运行中🟢		透明代理		${SS_RUST}"
			else
				echo "sslocal	未运行🔴		透明代理"
			fi
		else
			local SS_REDIR=$(pidof ss-redir)
			if [ -n "${SS_REDIR}" ]; then
				echo "ss-redir	运行中🟢		透明代理		${SS_REDIR}"
			else
				echo "ss-redir	未运行🔴		透明代理"
			fi
		fi

		local OBFS_SWITCH=$(dbus get ssconf_basic_ss_obfs_${ssconf_basic_node})
		if [ -n "${OBFS_SWITCH}" -a "${OBFS_SWITCH}" != "0" ]; then
			local SIMPLEOBFS=$(pidof obfs-local)
			if [ -n "${SIMPLEOBFS}" ]; then
				echo "obfs-local	运行中🟢		混淆插件		${SIMPLEOBFS}"
			else
				echo "obfs-local	未运行🔴		混淆插件"
			fi
		fi
		
		local V2PL_SWITCH=$(dbus get ssconf_basic_ss_v2ray_${ssconf_basic_node})
		if [ -n "${V2PL_SWITCH}" -a "${V2PL_SWITCH}" != "0" ]; then
			local SS_V2RAY=$(pidof v2ray-plugin)
			if [ -n "${SS_V2RAY}" ]; then
				echo "v2ray-plugin	运行中🟢		混淆插件		${SS_V2RAY}"
			else
				echo "v2ray-plugin	未运行🔴		混淆插件"
			fi
		fi
	elif [ "${ss_basic_type}" == "1" ]; then
		# ssr
		local SSR_REDIR=$(pidof rss-redir)
		if [ -n "${SSR_REDIR}" ];then
			echo "ssr-redir	运行中🟢		透明代理		${SSR_REDIR}"
		else
			echo "ssr-redir	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "3" ]; then
		# v2ray
		if [ "${ss_basic_vcore}" == "1" ];then
			local XRAY=$(pidof xray)
			if [ -n "${XRAY}" ];then
				local xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${xray_time}" ];then
					echo "Xray		运行中🟢		透明代理		${XRAY}	工作时长: ${xray_time}"
				else
					echo "Xray		运行中🟢		透明代理		${XRAY}"
				fi
			else
				echo "Xray	未运行🔴"
			fi
		else
			local V2RAY=$(pidof v2ray)
			if [ -n "${V2RAY}" ]; then
				echo "v2ray		运行中🟢		透明代理		${V2RAY}"
			else
				echo "v2ray		未运行🔴		透明代理"
			fi
		fi
	elif [ "${ss_basic_type}" == "4" ]; then
		# xray
		local XRAY=$(pidof xray)
		if [ -n "${XRAY}" ];then
			local xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
			if [ -n "${xray_time}" ];then
				echo "Xray		运行中🟢		透明代理		${XRAY}	工作时长: ${xray_time}"
			else
				echo "Xray		运行中🟢		透明代理		${XRAY}"
			fi
		else
			echo "Xray	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "5" ]; then
		# trojan
		if [ "${ss_basic_tcore}" == "1" ];then
			local XRAY=$(pidof xray)
			if [ -n "${XRAY}" ];then
				local xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${xray_time}" ];then
					echo "Xray		运行中🟢		透明代理		${XRAY}	工作时长: ${xray_time}"
				else
					echo "Xray		运行中🟢		透明代理		${XRAY}"
				fi
			else
				echo "Xray	未运行🔴		透明代理"
			fi
		else
			local IPT2SOCKS=$(pidof ipt2socks)
			if [ -n "${IPT2SOCKS}" ]; then
				echo "ipt2socks	运行中🟢		透明代理		${IPT2SOCKS}"
			else
				echo "ipt2socks	未运行🔴		透明代理"
			fi
		fi
	elif [ "${ss_basic_type}" == "6" ]; then
		# naive
		local NAIVE=$(pidof naive)
		if [ -n "${NAIVE}" ]; then
			echo "naive		运行中🟢		socks5		${NAIVE}"
		else
			echo "naive		未运行🔴		socks5"
		fi
		local IPT2SOCKS=$(pidof ipt2socks)
		if [ -n "${IPT2SOCKS}" ]; then
			echo "ipt2socks	运行中🟢		透明代理		${IPT2SOCKS}"
		else
			echo "ipt2socks	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "7" ]; then
		# tuic
		local TUIC=$(pidof tuic-client)
		if [ -n "${TUIC}" ]; then
			echo "tuic-client	运行中🟢		socks5		${TUIC}"
		else
			echo "tuic-client	未运行🔴		socks5"
		fi
		local IPT2SOCKS=$(pidof ipt2socks)
		if [ -n "${IPT2SOCKS}" ]; then
			echo "ipt2socks	运行中🟢		透明代理		${IPT2SOCKS}"
		else
			echo "ipt2socks	未运行🔴		透明代理"
		fi
	elif [ "${ss_basic_type}" == "8" ]; then
		# tuic
		local HY2=$(pidof hysteria2)
		if [ -n "${HY2}" ]; then
			echo "hysteria2	运行中🟢		透明代理		${HY2}"
		else
			echo "hysteria2	未运行🔴		透明代理"
		fi
	fi

	# DNS program
	if [ "${ss_basic_advdns}" != "1" ]; then
		# 基础DNS方案
		if [ "${ss_foreign_dns}" == "3" ]; then
			# dns2socks
			local DNS2SOCKS=$(pidof dns2socks)
			if [ -n "${DNS2SOCKS}" ];then
				echo "dns2socks	运行中🟢		DNS解析		${DNS2SOCKS}"
			else
				echo "dns2socks	未运行🔴		DNS解析"
			fi
			
			if [ "${ss_basic_type}" == "0" ]; then
				if [ "${ss_basic_rust}" == "1" ]; then
					local SS_RUST_LOCAL=$(ps | grep "sslocal" | grep "23456" | awk '{print $1}')
					if [ -n "${SS_RUST_LOCAL}" ];then
						echo "sslocal		运行中🟢		socks5		${SS_RUST_LOCAL}"
					else
						echo "sslocal		未运行🔴		socks5"
					fi
				else
					local SS_LOCAL=$(ps | grep "ss-local" | grep "23456" | awk '{print $1}')
					if [ -n "${SS_LOCAL}" ];then
						echo "ss-local	运行中🟢		socks5		${SS_LOCAL}"
					else
						echo "ss-local	未运行🔴		socks5"
					fi
				fi
			elif [ "${ss_basic_type}" == "1" ]; then
				local SSR_LOCAL=$(ps | grep "rss-local" | grep "23456" | awk '{print $1}')
				if [ -n "${SSR_LOCAL}" ]; then
					echo "rss-local	运行中🟢		socks5		${SSR_LOCAL}" 
				else
					echo "rss-local	未运行🔴		socks5"
				fi
			elif [ "${ss_basic_type}" == "5" ]; then
				# trojan
				local TROJAN_SOCKS=$(netstat -nlp | grep 23456 | grep LISTEN | grep trojan | awk '{print $NF}' | awk -F "/" '{print $1}' | tr "\n" " ")
				if [ -n "${TROJAN_SOCKS}" ]; then
					echo "trojan		运行中🟢		socks5		${TROJAN_SOCKS}" 

				else
					echo "trojan		未运行🔴		socks5"
				fi
			fi
		elif [ "${ss_foreign_dns}" == "4" ]; then
			if [ "${ss_basic_type}" == "0" ]; then
				# ss-tunnel
				if [ "${ss_basic_rust}" == "1" ]; then
					local SS_RUST_TUNNEL=$(ps | grep "sslocal" | grep "7913" | awk '{print $1}')
					if [ -n "${SS_RUST_TUNNEL}" ];then
						echo "sslocal		运行中🟢		DNS解析		${SS_RUST_TUNNEL}"
					else
						echo "sslocal		未运行🔴		DNS解析"
					fi
				else
					local SS_TUNNEL=$(ps | grep "ss-tunnel" | grep "7913" | awk '{print $1}')
					if [ -n "${SS_TUNNEL}" ];then
						echo "ss-tunnel	运行中🟢		DNS解析		${SS_TUNNEL}"
					else
						echo "ss-tunnel	未运行🔴		DNS解析"
					fi
				fi
			elif [ "${ss_basic_type}" == "1" ]; then
				# rss-tunnel
				local RSS_TUNNEL=$(ps | grep "rss-tunnel" | grep "7913" | awk '{print $1}')
				if [ -n "${RSS_TUNNEL}" ];then
					echo "rss-tunnel	运行中🟢		DNS解析		${RSS_TUNNEL}"
				else
					echo "rss-tunnel	未运行🔴		DNS解析"
				fi
			fi
		elif [ "${ss_foreign_dns}" == "9" ]; then
			# smartdns
			local SMD=$(pidof smartdns)
			if [ -n "${SMD}" ];then
				echo "smartdns	运行中🟢		DNS解析		${SMD}"
			else
				echo "smartdns	未运行🔴		DNS解析"
			fi
		fi

		if [ "${ss_china_dns}" == "98" -a "${ss_foreign_dns}" != "9" ];then
			# smartdns
			local SMD=$(pidof smartdns)
			if [ -n "${SMD}" ];then
				echo "smartdns	运行中🟢		DNS解析		${SMD}"
			else
				echo "smartdns	未运行🔴		DNS解析"
			fi
		fi
	else
		# 进阶DNS方案
		if [ "${ss_dns_plan}" == "1" ]; then
			# 中国DNS-1
			if [ "${ss_basic_chng_china_1_enable}" == "1" ];then
				if [ "${ss_basic_chng_china_1_prot}" == "1" ];then
					if [ "${ss_basic_chng_china_1_udp}" == "96" ];then
						local SMD1=$(ps | grep "smartdns" | grep "smartdns_chng_china_udp" | awk '{print $1}')
						if [ -n "${SMD1}" ];then
							echo "smartdns	运行中🟢		中国1:UDP查询	${SMD1}"
						else
							echo "smartdns	未运行🔴		中国1:UDP查询"
						fi
					else
						if [ "${ss_basic_chng_china_1_ecs}" == "1" -a "${ss_basic_nochnipcheck}" != "1" ];then
							local DEF1=$(ps | grep "dns-ecs-forcer" | grep "051 " | awk '{print $1}')
							if [ -n "${DEF1}" ];then
								echo "dns-ecs-forcer	运行中🟢		中国1:ECS	${DEF1}"
							else
								echo "dns-ecs-forcer	未运行🔴		中国1:ECS"
							fi
						fi
					fi
				fi
				if [ "${ss_basic_chng_china_1_prot}" == "2" ];then
					local D2T1=$(ps | grep "dns2tcp" | grep "051" | awk '{print $1}')
					if [ -n "${D2T1}" ];then
						echo "dns2tcp		运行中🟢		中国1:TCP查询	${D2T1}"
					else
						echo "dns2tcp		未运行🔴		中国1:TCP查询"
					fi
					if [ "${ss_basic_chng_china_1_ecs}" == "1"  -a "${ss_basic_nochnipcheck}" != "1" ];then
						local DEF1=$(ps | grep "dns-ecs-forcer" | grep "051 " | awk '{print $1}')
						if [ -n "${DEF1}" ];then
							echo "dns-ecs-forcer	运行中🟢		中国1:ECS	${DEF1}"
						else
							echo "dns-ecs-forcer	未运行🔴		中国1:ECS"
						fi
					fi
				fi
				if [ "${ss_basic_chng_china_1_prot}" == "3" ];then
					local DOH1=$(ps | grep "dohclient" | grep "chn1" | awk '{print $1}')
					if [ -n "${DOH1}" ];then
						echo "dohclient	运行中🟢		中国1:DoH查询	${DOH1}"
					else
						echo "dohclient	未运行🔴		中国1:DoH查询"
					fi
				fi
			fi

			# 中国DNS-2
			if [ "${ss_basic_chng_china_2_enable}" == "1" ];then
				if [ "${ss_basic_chng_china_2_prot}" == "1" ];then
					if [ "${ss_basic_chng_china_2_ecs}" == "1" -a "${ss_basic_nochnipcheck}" != "1" ];then
						local DEF2=$(ps | grep "dns-ecs-forcer" | grep "052 " | awk '{print $1}')
						if [ -n "${DEF2}" ];then
							echo "dns-ecs-forcer	运行中🟢		中国2:ECS	${DEF2}"
						else
							echo "dns-ecs-forcer	未运行🔴		中国2:ECS"
						fi
					fi
				elif [ "${ss_basic_chng_china_2_prot}" == "2" ];then
					local D2T2=$(ps | grep "dns2tcp" | grep "052" | awk '{print $1}')
					if [ -n "${D2T2}" ];then
						echo "dns2tcp		运行中🟢		中国2:TCP查询	${D2T2}"
					else
						echo "dns2tcp		未运行🔴		中国2:TCP查询"
					fi
					if [ "${ss_basic_chng_china_2_ecs}" == "1" -a "${ss_basic_nochnipcheck}" != "1" ];then
						local DEF2=$(ps | grep "dns-ecs-forcer" | grep "052 " | awk '{print $1}')
						if [ -n "${DEF2}" ];then
							echo "dns-ecs-forcer	运行中🟢		中国2:ECS	${DEF2}"
						else
							echo "dns-ecs-forcer	未运行🔴		中国2:ECS"
						fi
					fi
				elif [ "${ss_basic_chng_china_2_prot}" == "3" ];then
					local DOH2=$(ps | grep "dohclient" | grep "chn2" | awk '{print $1}')
					if [ -n "${DOH2}" ];then
						echo "dohclient	运行中🟢		中国2:DoH查询	${DOH2}"
					else
						echo "dohclient	未运行🔴		中国2:DoH查询"
					fi
				fi
			fi

			# 可信DNS-1
			if [ "${ss_basic_chng_trust_1_enable}" == "1" ];then
				if [ "${ss_basic_chng_trust_1_opt}" == "1" ];then
					# udp
					if [ "${ss_basic_type}" == "0" ];then
						# ss
						if [ "${ss_basic_rust}" == "1" ];then
							local SS_RUST_TUNNEL=$(ps | grep "sslocal" | grep "055" | awk '{print $1}')
							if [ -n "${SS_RUST_TUNNEL}" ];then
								echo "sslocal		运行中🟢		可信1:UDP查询	${SS_RUST_TUNNEL}"
							else
								echo "sslocal		未运行🔴		可信1:UDP查询"
							fi
						else
							local SS_TUNNEL=$(ps | grep "ss-tunnel" | grep "055" | awk '{print $1}')
							if [ -n "${SS_TUNNEL}" ];then
								echo "ss-tunnel	运行中🟢		可信1:UDP查询	${SS_TUNNEL}"
							else
								echo "ss-tunnel	未运行🔴		可信1:UDP查询"
							fi
						fi
					elif [ "${ss_basic_type}" == "1" ];then
						# ssr
						local RSS_TUNNEL=$(ps | grep "rss-tunnel" | grep "055" | awk '{print $1}')
						if [ -n "${RSS_TUNNEL}" ];then
							echo "rss-tunnel	运行中🟢		可信1:UDP查询	${RSS_TUNNEL}"
						else
							echo "rss-tunnel	未运行🔴		可信1:UDP查询"
						fi
					fi

					if [ "${ss_basic_chng_trust_1_ecs}" == "1" -a "${ss_basic_nofrnipcheck}" != "1" ];then
						local DEF3=$(ps | grep "dns-ecs-forcer" | grep "055 " | awk '{print $1}')
						if [ -n "${DEF3}" ];then
							echo "dns-ecs-forcer	运行中🟢		可信1:ECS	${DEF3}"
						else
							echo "dns-ecs-forcer	未运行🔴		可信1:ECS"
						fi
					fi
					
				elif [ "${ss_basic_chng_trust_1_opt}" == "2" ];then
					# tcp
					local DNS2SOCKS=$(ps -w | grep "dns2socks" | grep "055" | awk '{print $1}')
					if [ -n "${DNS2SOCKS}" ];then
						echo "dns2socks	运行中🟢		可信1:TCP查询	${DNS2SOCKS}"
					else
						echo "dns2socks	未运行🔴		可信1:TCP查询"
					fi
					if [ "${ss_basic_type}" == "0" ];then
						if [ "${ss_basic_rust}" == "1" ]; then
							local SS_RUST_LOCAL=$(ps | grep "sslocal" | grep "23456" | awk '{print $1}')
							if [ -n "${SS_RUST_LOCAL}" ];then
								echo "sslocal		运行中🟢		可信1:socks5	${SS_RUST_LOCAL}"
							else
								echo "sslocal		未运行🔴		可信1:socks5"
							fi
						else
							local SS_LOCAL=$(ps | grep "ss-local" | grep "23456" | awk '{print $1}')
							if [ -n "${SS_LOCAL}" ];then
								echo "ss-local	运行中🟢		可信1:socks5	${SS_LOCAL}"
							else
								echo "ss-local	未运行🔴		可信1:socks5"
							fi
						fi
					elif [ "${ss_basic_type}" == "1" ];then
						local SSR_LOCAL=$(ps | grep "rss-local" | grep "23456" | awk '{print $1}')
						if [ -n "${SSR_LOCAL}" ]; then
							echo "rss-local	运行中🟢		可信1:socks5	${SSR_LOCAL}" 
						else
							echo "rss-local	未运行🔴		可信1:socks5"
						fi
					elif [ "${ss_basic_type}" == "3" ];then
						if [ "${ss_basic_vcore}" == "1" ];then
							local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${XRAY_SOCKS}" ];then
								echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
							else
								echo "xray		未运行🔴		可信1:socks5"
							fi
						else
							local V2RAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "v2ray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${V2RAY_SOCKS}" ];then
								echo "v2ray		运行中🟢		可信1:socks5	${V2RAY_SOCKS}"
							else
								echo "v2ray		未运行🔴		可信1:socks5"
							fi
						fi
					elif [ "${ss_basic_type}" == "4" ];then
						local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${XRAY_SOCKS}" ];then
							echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
						else
							echo "xray		未运行🔴		可信1:socks5"
						fi
					elif [ "${ss_basic_type}" == "5" ];then
						if [ "${ss_basic_tcore}" == "1" ];then
							local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${XRAY_SOCKS}" ];then
								echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
							else
								echo "xray		未运行🔴		可信1:socks5"
							fi
						else
							local TROJAN_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "trojan" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${TROJAN_SOCKS}" ];then
								echo "trojan		运行中🟢		可信1:socks5	${TROJAN_SOCKS}"
							else
								echo "trojan		未运行🔴		可信1:socks5"
							fi
						fi
					fi
				elif [ "${ss_basic_chng_trust_1_opt}" == "3" ];then
					# dohclient
					local DOH3=$(ps | grep "dohclient" | grep "frn1" | awk '{print $1}')
					if [ -n "${DOH3}" ];then
						echo "dohclient	运行中🟢		可信1:DoH查询	${DOH3}"
					else
						echo "dohclient	未运行🔴		可信1:DoH查询"
					fi
					if [ "${ss_basic_type}" == "0" ];then
						if [ "${ss_basic_rust}" == "1" ]; then
							local SS_RUST_LOCAL=$(ps | grep "sslocal" | grep "23456" | awk '{print $1}')
							if [ -n "${SS_RUST_LOCAL}" ];then
								echo "sslocal		运行中🟢		可信1:socks5	${SS_RUST_LOCAL}"
							else
								echo "sslocal		未运行🔴		可信1:socks5"
							fi
						else
							local SS_LOCAL=$(ps | grep "ss-local" | grep "23456" | awk '{print $1}')
							if [ -n "${SS_LOCAL}" ];then
								echo "ss-local	运行中🟢		可信1:socks5	${SS_LOCAL}"
							else
								echo "ss-local	未运行🔴		可信1:socks5"
							fi
						fi
					elif [ "${ss_basic_type}" == "1" ];then
						local SSR_LOCAL=$(ps | grep "rss-local" | grep "23456" | awk '{print $1}')
						if [ -n "${SSR_LOCAL}" ]; then
							echo "rss-local	运行中🟢		可信1:socks5	${SSR_LOCAL}" 
						else
							echo "rss-local	未运行🔴		可信1:socks5"
						fi
					elif [ "${ss_basic_type}" == "3" ];then
						if [ "${ss_basic_vcore}" == "1" ];then
							local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${XRAY_SOCKS}" ];then
								echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
							else
								echo "xray		未运行🔴		可信1:socks5"
							fi
						else
							local V2RAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "v2ray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${V2RAY_SOCKS}" ];then
								echo "v2ray		运行中🟢		可信1:socks5	${V2RAY_SOCKS}"
							else
								echo "v2ray		未运行🔴		可信1:socks5"
							fi
						fi
					elif [ "${ss_basic_type}" == "4" ];then
						local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${XRAY_SOCKS}" ];then
							echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
						else
							echo "xray		未运行🔴		可信1:socks5"
						fi
					elif [ "${ss_basic_type}" == "5" ];then
						if [ "${ss_basic_tcore}" == "1" ];then
							local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${XRAY_SOCKS}" ];then
								echo "xray		运行中🟢		可信1:socks5	${XRAY_SOCKS}"
							else
								echo "xray		未运行🔴		可信1:socks5"
							fi
						else
							local TROJAN_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "trojan" | awk '{print $NF}' | awk -F "/" '{print $1}')
							if [ -n "${TROJAN_SOCKS}" ];then
								echo "trojan		运行中🟢		可信1:socks5	${TROJAN_SOCKS}"
							else
								echo "trojan		未运行🔴		可信1:socks5"
							fi
						fi
					fi
				fi
			fi
			# 可信DNS-2
			if [ "${ss_basic_chng_trust_2_enable}" == "1" ];then
				if [ "${ss_basic_chng_trust_2_opt}" == "1" ];then
					if [ "${ss_basic_chng_trust_2_ecs}" == "1" -a "${ss_basic_nofrnipcheck}" != "1" ];then
						local DEF4=$(ps | grep "dns-ecs-forcer" | grep "056 " | awk '{print $1}')
						if [ -n "${DEF4}" ];then
							echo "dns-ecs-forcer	运行中🟢		可信2:ECS	${DEF4}"
						else
							echo "dns-ecs-forcer	未运行🔴		可信2:ECS"
						fi
					fi
				elif [ "${ss_basic_chng_trust_2_opt}" == "2" ];then
					local D2T4=$(ps | grep "dns2tcp" | grep "056" | awk '{print $1}')
					if [ -n "${D2T4}" ];then
						echo "dns2tcp		运行中🟢		可信2:TCP查询	${D2T4}"
					else
						echo "dns2tcp		未运行🔴		可信2:TCP查询"
					fi
					if [ "${ss_basic_chng_trust_2_ecs}" == "1" -a "${ss_basic_nofrnipcheck}" != "1" ];then
						local DEF4=$(ps | grep "dns-ecs-forcer" | grep "056 " | awk '{print $1}')
						if [ -n "${DEF4}" ];then
							echo "dns-ecs-forcer	运行中🟢		可信2:ECS	${DEF4}"
						else
							echo "dns-ecs-forcer	未运行🔴		可信2:ECS"
						fi
					fi
				elif [ "${ss_basic_chng_trust_2_opt}" == "3" ];then
					local DOH4=$(ps | grep "dohclient" | grep "frn2" | awk '{print $1}')
					if [ -n "${DOH4}" ];then
						echo "dohclient	运行中🟢		可信2:DoH查询	${DOH4}"
					else
						echo "dohclient	未运行🔴		可信2:DoH查询"
					fi
				fi
			fi
			# chinadns-ng
			local CHNG=$(pidof chinadns-ng)
			if [ -n "${CHNG}" ];then
				echo "chinadns-ng	运行中🟢		DNS分流		${CHNG}"
			else
				echo "chinadns-ng	未运行🔴		DNS分流"
			fi
		elif [ "${ss_dns_plan}" == "2" ]; then
			# smartdns
			local SMD=$(pidof smartdns)
			if [ -n "${SMD}" ];then
				echo "smartdns	运行中🟢		DNS解析		${SMD}"
			else
				echo "smartdns	未运行🔴		DNS解析"
			fi
		elif [ "${ss_dns_plan}" == "3" ]; then
			local DOH_MAIN=$(ps | grep "dohclient" | grep "main" | awk '{print $1}')
			if [ -n "${DOH_MAIN}" ];then
				echo "dohclient	运行中🟢		DNS解析		${DOH_MAIN}"
			else
				echo "dohclient	未运行🔴		DNS解析"
			fi
			if [ "${ss_basic_dohc_proxy}" == "1" ];then
				if [ "${ss_basic_type}" == "0" ];then
					if [ "${ss_basic_rust}" == "1" ]; then
						local SS_RUST_LOCAL=$(ps | grep "sslocal" | grep "23456" | awk '{print $1}')
						if [ -n "${SS_RUST_LOCAL}" ];then
							echo "sslocal		运行中🟢		socks5		${SS_RUST_LOCAL}"
						else
							echo "sslocal		未运行🔴		socks5"
						fi
					else
						local SS_LOCAL=$(ps | grep "ss-local" | grep "23456" | awk '{print $1}')
						if [ -n "${SS_LOCAL}" ];then
							echo "ss-local	运行中🟢		socks5		${SS_LOCAL}"
						else
							echo "ss-local	未运行🔴		socks5"
						fi
					fi
				elif [ "${ss_basic_type}" == "1" ];then
					local SSR_LOCAL=$(ps | grep "rss-local" | grep "23456" | awk '{print $1}')
					if [ -n "${SSR_LOCAL}" ]; then
						echo "rss-local	运行中🟢		socks5		${SSR_LOCAL}" 
					else
						echo "rss-local	未运行🔴		socks5"
					fi
				elif [ "${ss_basic_type}" == "3" ];then
					if [ "${ss_basic_vcore}" == "1" ];then
						local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${XRAY_SOCKS}" ];then
							echo "xray		运行中🟢		socks5		${XRAY_SOCKS}"
						else
							echo "xray		未运行🔴		socks5"
						fi
					else
						local V2RAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "v2ray" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${V2RAY_SOCKS}" ];then
							echo "v2ray		运行中🟢		socks5		${V2RAY_SOCKS}"
						else
							echo "v2ray		未运行🔴		socks5"
						fi
					fi
				elif [ "${ss_basic_type}" == "4" ];then
					local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
					if [ -n "${XRAY_SOCKS}" ];then
						echo "xray		运行中🟢		socks5		${XRAY_SOCKS}"
					else
						echo "xray		未运行🔴		socks5"
					fi
				elif [ "${ss_basic_type}" == "5" ];then
					if [ "${ss_basic_tcore}" == "1" ];then
						local XRAY_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "xray" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${XRAY_SOCKS}" ];then
							echo "xray		运行中🟢		socks5		${XRAY_SOCKS}"
						else
							echo "xray		未运行🔴		socks5"
						fi
					else
						local TROJAN_SOCKS=$(netstat -nlp | grep "23456" | grep "LISTEN" | grep "trojan" | awk '{print $NF}' | awk -F "/" '{print $1}')
						if [ -n "${TROJAN_SOCKS}" ];then
							echo "trojan		运行中🟢		socks5		${TROJAN_SOCKS}"
						else
							echo "trojan		未运行🔴		socks5"
						fi
					fi
				fi
			fi
		fi
	fi
	
	if [ "${ss_basic_use_kcp}" == "1" ]; then
		local KCPTUN=$(pidof kcptun)
		if [ -n "${KCPTUN}" ];then
			echo "kcptun		运行中🟢		kcp加速		${KCPTUN}"
		else
			echo "kcptun		未运行🔴"
		fi
	fi

	if [ "${ss_basic_server}" == "127.0.0.1" ]; then
		local HAPROXY=$(pidof haproxy)
		if [ -n "${HAPROXY}" ];then
			echo "haproxy		运行中🟢		负载均衡		${HAPROXY}"
		else
			echo "haproxy		未运行🔴"
		fi
	fi
	
	local DMQ=$(pidof dnsmasq)
	if [ -n "${DMQ}" ];then
		echo "dnsmasq		运行中🟢		DNS解析		$DMQ"
	else
		echo "dnsmasq	未运行🔴		DNS解析"
	fi
	echo --------------------------------------------------------------------------------------------------------
}

ECHO_VERSION(){
	echo
	echo "2️⃣插件主要二进制程序版本："
	echo "--------------------------------------------------------------------------------------------------------"
	echo "程序			版本			备注"
	if [ -x "/koolshare/bin/sslocal" ];then
		local SSRUST_VER=$(run /koolshare/bin/sslocal --version|awk '{print $NF}' 2>/dev/null)
		if [ -n "${SSRUST_VER}" ];then
			echo "sslocal			${SSRUST_VER}			https://github.com/shadowsocks/shadowsocks-rust"
		fi
	fi
	echo "ss-redir		$(run ss-redir -h|sed '/^$/d'|head -n1|awk '{print $NF}')			https://github.com/shadowsocks/shadowsocks-libev"
	if [ -x "/koolshare/bin/ss-tunnel" ];then
		echo "ss-tunnel		$(run ss-tunnel -h|sed '/^$/d'|head -n1|awk '{print $NF}')			https://github.com/shadowsocks/shadowsocks-libev"
	fi
	echo "ss-local		$(run ss-local -h|sed '/^$/d'|head -n1|awk '{print $NF}')			https://github.com/shadowsocks/shadowsocks-libev"
	echo "obfs-local		$(run obfs-local -h|sed '/^$/d'|head -n1|awk '{print $NF}')			https://github.com/shadowsocks/simple-obfs"
	echo "ssr-redir		$(run rss-redir -h|sed '/^$/d'|head -n1|awk '{print $2}')			https://github.com/shadowsocksrr/shadowsocksr-libev"
	echo "ssr-local		$(run rss-local -h|sed '/^$/d'|head -n1|awk '{print $2}')			https://github.com/shadowsocksrr/shadowsocksr-libev"
	if [ -x "/koolshare/bin/haproxy" ];then
		echo "haproxy			2.1.2			http://www.haproxy.org/"
	fi
	echo "dns2socks		$(run dns2socks /?|sed '/^$/d'|head -n1|awk '{print $2}')			https://sourceforge.net/projects/dns2socks/"
	echo "chinadns-ng		$(run chinadns-ng -V | awk '{print $2}')		https://github.com/zfl9/chinadns-ng"
	if [ -x "/koolshare/bin/ss-tunnel" ];then
		echo "trojan			$(run trojan -v 2>&1 | head -n1 | awk '{print $NF}')			https://github.com/trojan-gfw/trojan"
	fi
	if [ -x "/koolshare/bin/v2ray" ];then
		#local v2_info_all=$(run v2ray -version|head -n1)
		local v2_info_all=$(run v2ray version|head -n1)
		echo "v2ray			$(echo ${v2_info_all}|awk '{print $2}')			https://github.com/v2fly/v2ray-core"
	fi
	echo "xray			$(run xray -version|head -n1|awk '{print $2}')			https://github.com/XTLS/Xray-core"
	if [ -x "/koolshare/bin/v2ray-plugin" ];then
		echo "v2ray-plugin		$(run v2ray-plugin -version|head -n1|awk '{print $2}')			https://github.com/teddysun/v2ray-plugin"
	fi
	if [ -x "/koolshare/bin/smartdns" ];then
		echo "smartdns		$(run smartdns -v|awk '{print $2}')	https://github.com/pymumu/smartdns"
	fi
	if [ -x "/koolshare/bin/dohclient" ];then
		echo "dohclient		$(run dohclient -V|awk '{print $2}')		https://github.com/GangZhuo/dohclient"
	fi
	if [ -x "/koolshare/bin/kcptun" ];then
		echo "kcptun			$(run kcptun -v | awk '{print $NF}')		https://github.com/xtaci/kcptun"
	fi
	if [ -x "/koolshare/bin/naive" ];then
		echo "naive			$(run naive --version|awk '{print $NF}')		https://github.com/klzgrad/naiveproxy"
	fi
	if [ -x "/koolshare/bin/tuic-client" ];then
		echo "tuic-client		$(run tuic-client -v|awk '{print $NF}')			https://github.com/EAimTY/tuic"
	fi
	if [ -x "/koolshare/bin/hysteria2" ];then
		echo "hysteria2		$(run hysteria2 version|grep Version|awk '{print $2}')			https://github.com/apernet/hysteria"
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
	local CDNVERSIN=$(cat /koolshare/ss/rules/rules.json.js|run jq -r '.cdn_china.date')

	echo "🟠 路由型号：$(GET_MODEL)"
	echo "🟠 固件类型：$(GET_FW_TYPE)"
	echo "🟠 固件版本：$(GET_FW_VER)"
	echo "🟠 路由时间：$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")"
	echo "🟠 插件版本：${CURR_NAME} ${CURR_VERS}"
	echo "🟠 代理模式：$(GET_MODE_NAME)"
	echo "🟠 当前节点：$(GET_CURRENT_NODE_NAME)"
	echo "🟠 节点类型：$(GET_CURRENT_NODE_TYPE)"
	echo "🟠 程序核心：$(GET_PROXY_TOOL)"
	echo "🟠 DNS方案：$(GET_DNS_TYPE)"
	echo "🟠 黑名单数：域名 ${CURR_BAKD}条，IP/CIDR ${CURR_BAKI}条"
	echo "🟠 白名单数：域名 ${CURR_WHTD}条，IP/CIDR ${CURR_WHTI}条"
	echo "🟠 订阅数量：${CURR_SUBS}个"
	echo "🟠 节点数量：${CURR_NODE}个"
	echo "🟠 节点类型：$(GET_NODES_TYPE)"
	echo "🟠 规则版本：gfwlist ${GFWVERSIN} | chnroute ${CHNVERSIN} | cdn ${CDNVERSIN}"
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