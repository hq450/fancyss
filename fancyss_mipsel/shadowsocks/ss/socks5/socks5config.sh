#!/bin/sh
eval `dbus export shadowsocks`
eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo $(date +%Y年%m月%d日\ %X):'

kill_socks5(){
kill `ps | grep ss-local | grep -v "grep" | grep -v "23456"|awk '{print $1}'`  >/dev/null 2>&1
}

# Start ss-local
start_socks5(){
	if [ "$ss_local_obfs_host" != "" ];then
		if [ "$ss_local_obfs" == "http" ];then
			ARG_OBFS="obfs=http;obfs-host=$ss_basic_ss_obfs_host"
		elif [ "$ss_local_obfs" == "tls" ];then
			ARG_OBFS="obfs=tls;obfs-host=$ss_basic_ss_obfs_host"
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
		ARG_ACL="--acl /koolshare/ss/socks5/gfwlist.acl"
	elif [ "$ss_local_acl" == "2" ];then
		ARG_ACL="--acl /koolshare/ss/socks5/chn.acl"
	fi

	echo_date enable ss_local...
	if [ "$ss_local_obfs" == "0" ];then
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL -f /var/run/ss_local.pid
	else
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u $ARG_ACL --plugin obfs-local --plugin-opts "$ARG_OBFS" -f /var/run/ss_local.pid
	fi
}

case $ACTION in
start)
    if [ "$ss_local_enable" == "1" ];then
        start_socks5
    fi
    ;;
stop | kill )
    kill_socks5
    ;;
restart)
    kill_socks5
    if [ "$ss_local_enable" == "1" ];then
        start_socks5
    fi
    ;;
*)
    echo "Usage: $0 (start|stop|restart)"
    exit 1
    ;;
esac


