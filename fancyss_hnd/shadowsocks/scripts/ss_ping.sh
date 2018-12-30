#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware

source /koolshare/scripts/base.sh
eval `dbus export ss_basic`

reomve_ping(){
	# flush previous ping value in the table
	pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
	if [ -n "$pings" ];then
		for ping in $pings
		do
			dbus remove "$ping"
		done
	fi
}

start_ping(){
	touch /tmp/ss_ping.lock
	reomve_ping
	
	# start testing
	if [ "$ss_basic_ping_node" != "0" ];then
		server_nu="$ss_basic_ping_node"
		server_address=`dbus get ssconf_basic_server_$server_nu`
		[ "$ss_basic_ping_method" == "5" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
		[ "$ss_basic_ping_method" == "6" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
		[ "$ss_basic_ping_method" == "7" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
		ping_time=`echo $ping_text | grep avg|awk -F '/' '{print $4}'`
		ping_loss=`echo $ping_text | grep loss|awk -F ', ' '{print $3}' | awk '{print $1}'`
		
		if [ "$?" == "0" ] && [ ! -z "$ping_time" ];then
			dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms / "$ping_loss"
		else
			dbus set ssconf_basic_ping_"$server_nu"="failed"
		fi
	else
		servers=`dbus list ssconf_basic_server | sort -n -t "_" -k 4`
		for server in $servers
		do
		{
			server_nu=`echo $server|cut -d "=" -f 1|cut -d "_" -f 4`
			server_address=`echo $server|cut -d "=" -f 2`
			[ "$ss_basic_ping_method" == "1" ] && ping_text=`ping -4 $server_address -c 1 -w 1 -q`
			[ "$ss_basic_ping_method" == "2" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
			[ "$ss_basic_ping_method" == "3" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
			[ "$ss_basic_ping_method" == "4" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
			ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
			ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
		
			if [ ! -z "$ping_time" ];then
				if [ "$ss_basic_ping_method" == "1" ];then
					dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms
				else
					dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms / "$ping_loss"
				fi
			else
				dbus set ssconf_basic_ping_"$server_nu"="failed"
			fi
		}&
		done
	fi

	sleep 1
	while [ -n "`pidof ping`" ]; do
		sleep 1
	done
	rm -rf /tmp/ss_ping.lock
}

case $2 in
1)
	[ -f "/tmp/ss_ping.lock" ] && exit 
	ss_basic_ping_node=0
	ss_basic_ping_method=1
	start_ping
	http_response "$1"
	;;
2)
	[ -f "/tmp/ss_ping.lock" ] && exit 
	start_ping
	http_response "$1"
	;;
3)
	reomve_ping
	http_response "$1"
	;;
esac