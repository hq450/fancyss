#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh

get_mode_name() {
	case "$1" in
	1)
		echo "【gfwlist模式】"
		;;
	2)
		echo "【大陆白名单模式】"
		;;
	3)
		echo "【游戏模式】"
		;;
	5)
		echo "【全局模式】"
		;;
	6)
		echo "【回国模式】"
		;;
	esac
}

get_dns_name() {
	case "$1" in
	1)
		echo "cdns"
		;;
	2)
		echo "chinadns2"
		;;
	3)
		echo "dns2socks"
		;;
	4)
		if [ -n "$ss_basic_rss_obfs" ]; then
			echo "ssr-tunnel"
		else
			echo "ss-tunnel"
		fi
		;;
	5)
		echo "chinadns1 + dns2socks上游"
		;;
	6)
		echo "https_dns_proxy"
		;;
	7)
		echo "v2ray dns"
		;;
	8)
		echo "koolgame内置"
		;;
	9)
		echo "SmartDNS"
		;;
	10)
		echo "chinadns-ng"
		;;
	esac
}

echo_version() {
	echo 2️⃣插件主要二进制程序版本：
	echo --------------------------------------------------------------------------------------------------------
	echo "程序			版本			备注"
#@	if [ -x "/koolshare/bin/sslocal" ];then
#@		local SSRUST_VER=$(/koolshare/bin/sslocal --version|awk '{print $NF}' 2>/dev/null)
#@		if [ -n "${SSRUST_VER}" ];then
#@			echo "sslocal			${SSRUST_VER}		shadowsocks-rust"
#@		fi
#@	fi
	echo "ss-redir		3.3.5			2022年04月29日编译"
#@	echo "ss-tunnel		3.3.5			2022年04月29日编译"
	echo "ss-local		3.3.5			2022年04月29日编译"
	echo "obfs-local		0.0.5			2018年11月25日编译"
	echo "ssrr-redir		3.5.3			2018年12月06日编译"
	echo "ssrr-local		3.5.3			2018年12月06日编译"
#@	echo "haproxy			2.1.2			2020年01月06日编译"
	echo "dns2socks		V2.0			2017年12月05日编译"
#@	echo "cdns			1.0			2017年12月09日编译"
#@	echo "chinadns1		1.3.2			2017年12月09日编译"
#@	echo "chinadns2		2.0.0			2017年12月09日编译"
	echo "chinadns-ng		v1.0-beta.25		2020年06月02日编译"
	echo "https_dns_proxy		758f913			2019年02月05日编译"
	echo "httping			2.6			2020年01月06日编译"
#@	echo "trojan			1.16.0			2020年01月19日编译"
#@	local v2_info_all=$(v2ray -version|head -n1)
#@	local v2_info_date=$(echo ${v2_info_all}|head -n1|awk '{print $4}')
#@	echo "v2ray			$(echo ${v2_info_all}|awk '{print $2}')			${v2_info_date::4}年${v2_info_date:4:2}月${v2_info_date:6:2}日编译"
	echo "xray			$(xray -version|head -n1|awk '{print $2}')			2022年05月11日编译"
#@	echo "v2ray-plugin		$(v2ray-plugin -version|head -n1|awk '{print $2}')			https://github.com/teddysun/v2ray-plugin"
#@	echo "SmartDNS		1.2020.05.04-0005	Official Release 2020年05月04日"
#@	echo "kcptun			20210922		Official Release 2021年09月22日"
	echo --------------------------------------------------------------------------------------------------------
}

check_status() {
	CURR_TIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
	echo "*️⃣${CURR_TIME}: fancyss插件版本：$(cat /koolshare/ss/version)"
	echo
#@	SS_RUST=$(pidof sslocal)
	SIMPLEOBFS=$(pidof obfs-local)
	SS_REDIR=$(pidof ss-redir)
	SS_TUNNEL=$(pidof ss-tunnel)
#@	SS_V2RAY=$(pidof v2ray-plugin)
	SS_LOCAL=$(ps | grep ss-local | grep 23456 | awk '{print $1}')
	SSR_REDIR=$(pidof rss-redir)
	SSR_LOCAL=$(ps | grep rss-local | grep 23456 | awk '{print $1}')
	SSR_TUNNEL=$(pidof rss-tunnel)
#@	KOOLGAME=$(pidof koolgame)
	DNS2SOCKS=$(pidof dns2socks)
#@	CDNS=$(pidof cdns)
#@	CHINADNS1=$(pidof chinadns1)
#@	CHINADNS=$(pidof chinadns)
	CHINADNS_NG=$(pidof chinadns-ng)
#@	KCPTUN=$(pidof kcptun)
#@	HAPROXY=$(pidof haproxy)
#@	V2RAY=$(pidof v2ray)
	XRAY=$(pidof xray)
	HDP=$(pidof https_dns_proxy)
	DMQ=$(pidof dnsmasq)
#@	SMD=$(pidof smartdns)
#@	TROJAN=$(pidof trojan)
	game_on=$(dbus list ss_acl_mode | cut -d "=" -f 2 | grep 3)

	if [ "$ss_basic_type" == "0" ]; then
		if [ "$ss_basic_rust" == "1" ]; then
			echo 1️⃣ 检测当前相关进程工作状态：（你正在使用shadowsocks-rust，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		else
			echo 1️⃣ 检测当前相关进程工作状态：（你正在使用shadowsocks-libev，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		fi
		echo --------------------------------------------------------------------------------------------------------
		echo "程序		状态	PID"
		if [ "$ss_basic_rust" == "1" ]; then
			[ -n "$SS_RUST" ] && echo "sslocal		工作中	pid：$SS_RUST" || echo "sslocal	未运行"
		else
			[ -n "$SS_REDIR" ] && echo "ss-redir	工作中	pid：$SS_REDIR" || echo "ss-redir	未运行"
		fi
		if [ -n "$SS_V2RAY" ]; then
			echo "v2ray-plugin	工作中	pid：$SS_V2RAY"
		fi
		if [ -n "$SIMPLEOBFS" ]; then
			echo "obfs-local	工作中	pid：$SIMPLEOBFS"
		fi
	elif [ "$ss_basic_type" == "1" ]; then
		echo 1️⃣ 检测当前相关进程工作状态：（你正在使用shadowsocks-libev，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo --------------------------------------------------------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SSR_REDIR" ] && echo "ssr-redir	工作中	pid：$SSR_REDIR" || echo "ssr-redir	未运行"
	elif [ "$ss_basic_type" == "2" ]; then
		echo 1️⃣ 检测当前相关进程工作状态：（你正在使用koolgame，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name 8)）
		echo --------------------------------------------------------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$KOOLGAME" ] && echo "koolgame	工作中	pid：$KOOLGAME" || echo "koolgame	未运行"
	elif [ "$ss_basic_type" == "3" ]; then
		if [ "${ss_basic_vcore}" == "1" ];then
			echo 1️⃣检测当前相关进程工作状态：（你正在使用Xray运行v2ray节点，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
			echo --------------------------------------------------------------------------------------------------------
			echo "程序		状态	PID"
			if [ -n "${XRAY}" ];then
				xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${xray_time}" ];then
					echo "Xray		工作中	pid：$XRAY	工作时长: ${xray_time}"
				else
					echo "Xray		工作中	pid：$XRAY"
				fi
			else
				echo "Xray	未运行"
			fi
		else
			echo 1️⃣检测当前相关进程工作状态：（你正在使用V2ray，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
			echo --------------------------------------------------------------------------------------------------------
			echo "程序		状态	PID"
			[ -n "$V2RAY" ] && echo "v2ray		工作中	pid：$V2RAY" || echo "v2ray	未运行"
		fi
	elif [ "$ss_basic_type" == "4" ]; then
		echo 1️⃣检测当前相关进程工作状态：（你正在使用Xray，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
		echo --------------------------------------------------------------------------------------------------------
		echo "程序		状态	PID"
		if [ -n "${XRAY}" ];then
			xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
			if [ -n "${xray_time}" ];then
				echo "Xray		工作中	pid：$XRAY	工作时长: ${xray_time}"
			else
				echo "Xray		工作中	pid：$XRAY"
			fi
		else
			echo "Xray	未运行"
		fi
	elif [ "$ss_basic_type" == "5" ]; then
		if [ "${ss_basic_tcore}" == "1" ];then
			echo 1️⃣检测当前相关进程工作状态：（你正在使用Xray运行trojan节点，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
			echo --------------------------------------------------------------------------------------------------------
			echo "程序		状态	PID"
			if [ -n "${XRAY}" ];then
				xray_time=$(perpls|grep xray|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${xray_time}" ];then
					echo "Xray		工作中	pid：$XRAY	工作时长: ${xray_time}"
				else
					echo "Xray		工作中	pid：$XRAY"
				fi
			else
				echo "Xray	未运行"
			fi
		else
			echo 1️⃣ 检测当前相关进程工作状态：（你正在使用trojan，选择的模式是$(get_mode_name $ss_basic_mode)，国外DNS解析方案是：$(get_dns_name $ss_foreign_dns)）
			echo --------------------------------------------------------------------------------------------------------
			echo "程序		状态	PID"
			[ -n "${TROJAN}" ] && echo "trojan		工作中	pid：${TROJAN}" || echo "trojan		未运行"
		fi
	fi

	if [ -z "$ss_basic_koolgame_udp" ]; then
		if [ "$ss_basic_use_kcp" == "1" ]; then
			[ -n "$KCPTUN" ] && echo "kcptun		工作中	pid：$KCPTUN" || echo "kcptun		未运行"
		fi

		if [ "$ss_basic_server" == "127.0.0.1" ]; then
			[ -n "$HAPROXY" ] && echo "haproxy		工作中	pid：$HAPROXY" || echo "haproxy		未运行"
		fi

		if [ "$ss_foreign_dns" == "1" ]; then
			[ -n "$CDNS" ] && echo "cdns		工作中	pid：$CDNS" || echo "cdns	未运行"
		elif [ "$ss_foreign_dns" == "2" ]; then
			[ -n "$CHINADNS" ] && echo "chinadns	工作中	pid：$CHINADNS" || echo "chinadns	未运行"
		elif [ "$ss_foreign_dns" == "3" ]; then
			if [ -n "$ss_basic_rss_obfs" ]; then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			else
				if [ "$ss_basic_type" == "0" -o "$ss_basic_type" == "1" ]; then
					if [ "$ss_basic_rust" != "1" ]; then
						[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
					fi
				fi
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			fi
		elif [ "$ss_foreign_dns" == "4" ]; then
			if [ -n "$ss_basic_rss_obfs" ]; then
				[ -n "$SSR_TUNNEL" ] && echo "ssr-tunnel	工作中	pid：$SSR_TUNNEL" || echo "ssr-tunnel	未运行"
			else
				if [ "$ss_basic_rust" != "1" ]; then
					[ -n "$SS_TUNNEL" ] && echo "ss-tunnel	工作中	pid：$SS_TUNNEL" || echo "ss-tunnel	未运行"
				fi
			fi
		elif [ "$ss_foreign_dns" == "5" ]; then
			if [ "$ss_basic_type" == "0" -o "$ss_basic_type" == "1" ]; then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
			fi
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			[ -n "$CHINADNS1" ] && echo "chinadns1	工作中	pid：$CHINADNS1" || echo "chinadns1	未运行"
		elif [ "$ss_foreign_dns" == "6" ]; then
			[ -n "$HDP" ] && echo "https_dns_proxy	工作中	pid：$HDP" || echo "https_dns_proxy	未运行"
		elif [ "$ss_foreign_dns" == "7" ]; then
			[ -n "$HDP" ] && echo "https_dns_proxy	工作中	pid：$HDP" || echo "https_dns_proxy	未运行"
		elif [ "$ss_foreign_dns" == "9" ]; then
			[ -n "$SMD" ] && echo "SmartDNS	工作中	pid：$SMD" || echo "SmartDNS	未运行"
		elif [ "$ss_foreign_dns" == "10" ]; then
			if [ "$ss_basic_type" == "0" -o "$ss_basic_type" == "1" ]; then
				if [ "$ss_basic_rust" != "1" ]; then
					[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
				fi
			fi
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			[ -n "${CHINADNS_NG}" ] && echo "chinadns-ng	工作中	pid：${CHINADNS_NG}" || echo "chinadns-ng	未运行"
		fi
	fi
	[ "$ss_dns_china" == "13" ] &&{
		if [ "$ss_foreign_dns" != "9" ]; then 
			[ -n "$SMD" ] && echo "SmartDNS	工作中	pid：$SMD" || echo "SmartDNS	未运行"
		fi
	}
	[ -n "$DMQ" ] && echo "dnsmasq		工作中	pid：$DMQ" || echo "dnsmasq	未运行"
	echo --------------------------------------------------------------------------------------------------------

	echo
	echo_version

	echo
	echo
	echo 3️⃣检测iptbales工作状态：
	echo ----------------------------------------------------- nat表 PREROUTING 链 --------------------------------------------------------
	iptables -nvL PREROUTING -t nat
	echo
	echo ----------------------------------------------------- nat表 OUTPUT 链 ------------------------------------------------------------
	iptables -nvL OUTPUT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_EXT 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS_EXT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GFW 链 ----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GFW -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_CHN 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_CHN -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GAM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GAM -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GLO 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GLO -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_HOM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_HOM -t nat
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 PREROUTING 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL PREROUTING -t mangle
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 SHADOWSOCKS 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL SHADOWSOCKS -t mangle
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo ------------------------------------------------------ mangle表 SHADOWSOCKS_GAM 链 -------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && iptables -nvL SHADOWSOCKS_GAM -t mangle
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo -----------------------------------------------------------------------------------------------------------------------------------
	[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && echo
}

if [ "$ss_basic_enable" == "1" ]; then
	rm -rf /tmp/upload/ss_proc_status.txt
	check_status >/tmp/upload/ss_proc_status.txt 2>&1
	#echo XU6J03M6 >> /tmp/upload/ss_proc_status.txt
else
	echo 插件尚未启用！ >/tmp/upload/ss_proc_status.txt 2>&1
fi

http_response $1
