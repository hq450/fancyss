#!/bin/sh
eval `dbus export shadowsocks`
eval `dbus export ss`
source /koolshare/scripts/base.sh


kill_socks5(){
kill `ps | grep ss-local | grep -v "grep" | grep -v "23456"|awk '{print $1}'`  >/dev/null 2>&1
}

# Start ss-local
start_socks5(){
	
	if [ "$ss_local_enable" == "1" ]; then
		echo $(date): enable ss_local...
		ss-local -b 0.0.0.0 -s "$ss_local_server" -p "$ss_local_port" -l "$ss_local_proxyport" -k "$ss_local_password" -m "$ss_local_method" -u -f /var/run/ss_local.pid
		echo $(date): done
		echo $(date):
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
    start_socks5
    ;;
*)
    echo "Usage: $0 (start|stop|restart)"
    exit 1
    ;;
esac


