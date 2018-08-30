#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ssconf_basic`

# flush previous ping value in the table
pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ ! -z "$pings" ];then
	for ping in $pings
	do
		dbus remove "$ping"
	done
fi

# start testing
if [ "$ssconf_basic_ping_node" != "0" ];then
	server_nu="$ssconf_basic_ping_node"
	server_address=`dbus get ssconf_basic_server_$server_nu`
	[ "$ssconf_basic_ping_method" == "5" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
	[ "$ssconf_basic_ping_method" == "6" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
	[ "$ssconf_basic_ping_method" == "7" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
	ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
	ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
	
	if [ ! -z "$ping_time" ];then
		dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms / "$ping_loss"
	else
		dbus set ssconf_basic_ping_"$server_nu"="failed"
	fi
else
	if [ "$ssconf_basic_ping_method" == "1" ];then
		servers=`dbus list ssconf_basic_server | sort -n -t "_" -k 4`
		for server in $servers
		do
			server_nu=`echo $server|cut -d "=" -f 1|cut -d "_" -f 4`
			server_address=`echo $server|cut -d "=" -f 2`
			ping_text=`ping -4 $server_address -c 10 -w 10 -q`
			ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
			ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
		
			if [ ! -z "$ping_time" ];then
				dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms / "$ping_loss"
			else
				dbus set ssconf_basic_ping_"$server_nu"="failed"
			fi
		done
	else
		servers=`dbus list ssconf_basic_server | sort -n -t "_" -k 4`
		for server in $servers
		do
		{
			server_nu=`echo $server|cut -d "=" -f 1|cut -d "_" -f 4`
			server_address=`echo $server|cut -d "=" -f 2`
			[ "$ssconf_basic_ping_method" == "2" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
			[ "$ssconf_basic_ping_method" == "3" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
			[ "$ssconf_basic_ping_method" == "4" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
			ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
			ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
		
			if [ ! -z "$ping_time" ];then
				dbus set ssconf_basic_ping_"$server_nu"="$ping_time" ms / "$ping_loss"
			else
				dbus set ssconf_basic_ping_"$server_nu"="failed"
			fi
		}&
		done
	fi
fi



