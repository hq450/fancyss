#!/bin/sh

# shadowsocks script for qca-ipq806x platform router

source /koolshare/scripts/base.sh
eval $(dbus export ss_)
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
	if [ "$ss_local_obfs_host" != "" ];then
		if [ "$ss_local_obfs" == "http" ];then
			ARG_OBFS="obfs=http;obfs-host=$ss_local_obfs_host"
		elif [ "$ss_local_obfs" == "tls" ];then
			ARG_OBFS="obfs=tls;obfs-host=$ss_local_obfs_host"
		else
			ARG_OBFS=""
		fi
	else
		if [ "$ss_local_obfs" == "http" ];then
			ARG_OBFS="obfs=http"
		elif [ "$ss_local_obfs" == "tls" ];then
			ARG_OBFS="obfs=tls"
		else
			ARG_OBFS=""
		fi
	fi
	
	if [ "$ss_local_acl" == "0" ];then
		ARG_ACL=""
	elif [ "$ss_local_acl" == "1" ];then
		ARG_ACL="--acl /koolshare/ss/rules/gfwlist.acl"
	elif [ "$ss_local_acl" == "2" ];then
		ARG_ACL="--acl /koolshare/ss/rules/chn.acl"
	fi

	if [ "$ss_local_obfs" == "0" ];then
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL -f /var/run/ss_local.pid
	else
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/ss_local.pid
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
esac

case $2 in
start)
	echo " " > /tmp/upload/ss_log.txt
	http_response "$1"
	if [ "$ss_local_enable" == "1" ];then
		kill_socks5 >> /tmp/upload/ss_log.txt
		start_socks5 >> /tmp/upload/ss_log.txt
	else
		kill_socks5 >> /tmp/upload/ss_log.txt
		echo_date 完成...
	fi
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac