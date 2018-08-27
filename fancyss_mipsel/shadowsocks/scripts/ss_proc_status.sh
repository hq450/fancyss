#!/bin/sh

eval `dbus export ss`
source /koolshare/scripts/base.sh
source helper.sh
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'

get_mode_name() {
	case "$1" in
		1)
			echo "【gfwlist模式】"
		;;
		2)
			echo "【大陆白名单模式】"
		;;
		5)
			echo "【全局模式】"
		;;
	esac
}

get_dns_name() {
	case "$1" in
		1)
			echo "dns2socks"
		;;
		2)
			if [ "$ss_basic_use_rss" == "1" ];then
				echo "ssr-tunnel"
			else
				echo "ss-tunnel"
			fi
		;;
		3)
			echo "dnscrypt-proxy"
		;;
		4)
			echo "pdnsd"
		;;
		5)
			if [ "$ss_chinadns_foreign_method" == "1" ];then
				echo "chinadns, 上游dns方案dns2socks"
			elif [ "$ss_chinadns_foreign_method" == "3" ];then
				echo "chinadns, 上游dns方案ss-tunnel"
			elif [ "$ss_chinadns_foreign_method" == "4" ];then
				echo "chinadns, 上游dns方案自定义"
			fi
		;;
	esac
}

echo_version(){
	echo ① 程序版本（插件版本：3.3.4）：
	echo -----------------------------------------------------------
	echo "程序			版本		备注"
	echo "ss-redir		3.0.6		2017年6月9日"
	echo "ss-tunnel		3.0.6 		2017年6月9日"
	echo "ss-local		3.0.6		2017年6月9日"
	echo "obfs-local		0.0.3		2017年6月9日"
	echo "ssr-redir		2.5.6 		with mbed TLS 2.4.0"
	echo "ssr-tunnel		2.5.6 		with mbed TLS 2.4.0"
	echo "ssr-local		2.5.6 		with mbed TLS 2.4.0"
	echo "haproxy			1.7.5	"
	echo "dns2socks		V2.0 	"
	echo "dnscrypt-proxy		1.6.0 	"
	echo "ChinaDNS		1.3.2 	"
	echo "pndsd			1.2.9a-par 	"
	echo -----------------------------------------------------------
}

check_status(){
	#echo ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
	SS_REDIR=`pidof ss-redir`
	SS_TUNNEL=`pidof ss-tunnel`
	SS_LOCAL=`ps|grep ss-local|grep 23456|awk '{print $1}'`
	SSR_REDIR=`pidof rss-redir`
	SSR_LOCAL=`ps|grep rss-local|grep 23456|awk '{print $1}'`
	SSR_TUNNEL=`pidof rss-tunnel`
	DNS2SOCKS=`pidof dns2socks`
	DNS_CRYPT=`pidof dnscrypt-proxy`
	PDNSD=`pidof pdnsd`
	CHINADNS=`pidof chinadns`
	HAPROXY=`pidof haproxy`
	CHINADNS=`pidof chinadns`
	
	if [ "$ss_basic_use_rss" == "1" ];then
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SSR-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_dns_foreign)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SSR_REDIR" ] && echo "ssr-redir	工作中	pid：$SSR_REDIR" || echo "ssr-redir	未运行"
	else
		echo_version
		echo
		echo ② 检测当前相关进程工作状态：（你正在使用SS-libev,选择的模式是$(get_mode_name $ss_basic_mode),国外DNS解析方案是：$(get_dns_name $ss_dns_foreign)）
		echo -----------------------------------------------------------
		echo "程序		状态	PID"
		[ -n "$SS_REDIR" ] && echo "ss-redir	工作中	pid：$SS_REDIR" || echo "ss-redir	未运行"
	fi
	if [ "$ss_basic_server" == "127.0.0.1" ];then
	 	[ -n "$HAPROXY" ] && echo "haproxy		工作中	pid：$HAPROXY" || echo "haproxy		未运行"
	fi
	if [ "$ss_dns_foreign" == "1" ];then
		if [ "$ss_basic_use_rss" == "1" ];then
			[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
		else
			[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
			[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
		fi
	elif [ "$ss_dns_foreign" == "2" ];then
		if [ "$ss_basic_use_rss" == "1" ];then
			[ -n "$SSR_TUNNEL" ] && echo "ssr-tunnel	工作中	pid：$SSR_TUNNEL" || echo "ssr-tunnel	未运行"
		else
			[ -n "$SS_TUNNEL" ] && echo "ss-tunnel	工作中	pid：$SS_TUNNEL" || echo "ss-tunnel	未运行"
		fi
	elif [ "$ss_dns_foreign" == "3" ];then
		[ -n "$DNS_CRYPT" ] && echo "dnscrypt-proxy	工作中	pid：$DNS_CRYPT" || echo "dnscrypt-proxy	未运行"
	elif [ "$ss_dns_foreign" == "4" ];then
		if [ "$ss_pdnsd_method" == "1" ];then
			if [ "$ss_pdnsd_udp_server" == "1" ];then
				if [ "$ss_basic_use_rss" == "1" ];then
					[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
					[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
				else
					[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
					[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
				fi
			elif [ "$ss_pdnsd_udp_server" == "3" ];then
				if [ "$ss_basic_use_rss" == "1" ];then
					[ -n "$SSR_TUNNEL" ] && echo "ssr-tunnel	工作中	pid：$SSR_TUNNEL" || echo "ssr-tunnel	未运行"
				else
					[ -n "$SS_TUNNEL" ] && echo "ss-tunnel	工作中	pid：$SS_TUNNEL" || echo "ss-tunnel	未运行"
				fi
			elif [ "$ss_pdnsd_udp_server" == "2" ];then
				[ -n "$DNS_CRYPT" ] && echo "dnscrypt-proxy	工作中	pid：$DNS_CRYPT" || echo "dnscrypt-proxy	未运行"
			fi
		fi
		[ -n "$PDNSD" ] && echo "pdnsd		工作中	pid：$PDNSD" || echo "pdnsd	未运行"
		
	elif [ "$ss_dns_foreign" == "5" ];then
		if [ "$ss_chinadns_foreign_method" == "1" ];then
			if [ "$ss_basic_use_rss" == "1" ];then
				[ -n "$SSR_LOCAL" ] && echo "ssr-local	工作中	pid：$SSR_LOCAL" || echo "ssr-local	未运行"
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			else
				[ -n "$SS_LOCAL" ] && echo "ss-local	工作中	pid：$SS_LOCAL" || echo "ss-local	未运行"
				[ -n "$DNS2SOCKS" ] && echo "dns2socks	工作中	pid：$DNS2SOCKS" || echo "dns2socks	未运行"
			fi
		elif [ "$ss_chinadns_foreign_method" == "2" ];then
			[ -n "$DNS_CRYPT" ] && echo "dnscrypt-proxy	工作中	pid：$DNS_CRYPT" || echo "dnscrypt-proxy	未运行"
		elif [ "$ss_chinadns_foreign_method" == "3" ];then
			if [ "$ss_basic_use_rss" == "1" ];then
				[ -n "$SSR_TUNNEL" ] && echo "ssr-tunnel	工作中	pid：$SSR_TUNNEL" || echo "ssr-tunnel	未运行"
			else
				[ -n "$SS_TUNNEL" ] && echo "ss-tunnel	工作中	pid：$SS_TUNNEL" || echo "ss-tunnel	未运行"
			fi
		fi
		[ -n "$CHINADNS" ] && echo "chinadns	工作中	pid：$CHINADNS" || echo "chinadns	未运行"
	fi

	echo -----------------------------------------------------------
	echo
	echo
	echo ③ 检测iptbales工作状态：
	#echo ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
	echo ----------------------------------------------------- nat表 PREROUTING 链 --------------------------------------------------------
	iptables -nvL PREROUTING -t nat
	echo
	echo ----------------------------------------------------- nat表 OUTPUT 链 ------------------------------------------------------------
	iptables -nvL OUTPUT -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS 链 --------------------------------------------------------
	iptables -nvL SHADOWSOCKS -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GFW 链 ----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GFW -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_CHN 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_CHN -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_GLO 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_GLO -t nat
	echo
	echo ----------------------------------------------------- nat表 SHADOWSOCKS_HOM 链 -----------------------------------------------------
	iptables -nvL SHADOWSOCKS_HOM -t nat
	echo -----------------------------------------------------------------------------------------------------------------------------------
	echo
}

if [ "$ss_basic_enable" == "1" ];then
	check_status > /tmp/ss_proc_status.log 2>&1
else
	echo 插件尚未启用！
fi
echo XU6J03M6 >> /tmp/ss_proc_status.log
