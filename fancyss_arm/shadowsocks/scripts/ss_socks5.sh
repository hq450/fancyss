#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

kill_socks5(){
	PID=`ps | grep ss-local | grep -v "grep" | grep -v "23456"|awk '{print $1}'`
	if [ -n "$PID" ];then
		echo_date 关闭ss-local...
		kill -9  "$PID" >/dev/null 2>&1
		echo_date 完成...
	fi	
}

# Start ss-local
start_socks5(){
	echo_date 开启ss-local...
	if [ "$ss_local_v2ray_plugin_opts" != "" ];then
		if [ "$ss_local_v2ray_plugin" == "1" ];then
			ARG_V2RAY_PLUGIN="--plugin v2ray-plugin --plugin-opts $ss_local_v2ray_plugin_opts"
		else
			ARG_V2RAY_PLUGIN=""
		fi
	fi
	
	if [ "$ss_local_acl" == "0" ];then
		ARG_ACL=""
	elif [ "$ss_local_acl" == "1" ];then
		ARG_ACL="--acl /koolshare/ss/rules/gfwlist.acl"
	elif [ "$ss_local_acl" == "2" ];then
		ARG_ACL="--acl /koolshare/ss/rules/chn.acl"
	fi

	if [ "$ss_local_v2ray_plugin" == "0" ];then
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL -f /var/run/ss_local.pid
	else
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL "$ARG_V2RAY_PLUGIN" -f /var/run/ss_local.pid
	fi
	echo_date 完成...
}

case $1 in
start)
	if [ "$ss_local_enable" == "1" ];then
		logger "[软件中心]: 启动socks5！"
		[ "$ss_basic_sleep" != "0" ] && sleep $ss_basic_sleep
		kill_socks5
		start_socks5 >> /tmp/syslog.log
	else
		logger "[软件中心]: socks5未开启，不启动！"
	fi
	;;
*)
	if [ "$ss_local_enable" == "1" ];then
		kill_socks5
		start_socks5
	else
		kill_socks5
	fi
	;;
esac
