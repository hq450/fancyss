#!/bin/sh

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
if [ "$ssconf_basic_Ping_node" != "0" ];then
	server_mu="$ssconf_basic_Ping_node"
	server_address=`dbus get ssconf_basic_server_$server_mu`
	[ "$ssconf_basic_Ping_Method" == "5" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
	[ "$ssconf_basic_Ping_Method" == "6" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
	[ "$ssconf_basic_Ping_Method" == "7" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
	ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
	ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
	
	if [ ! -z "$ping_time" ];then
		dbus set ssconf_basic_ping_"$server_mu"="$ping_time" ms / "$ping_loss"
	else
		dbus set ssconf_basic_ping_"$server_mu"="failed"
	fi
else
	if [ "$ssconf_basic_Ping_Method" == "1" ];then
		servers=`dbus list ssconf_basic_server | sort -n -t "_" -k 4`
		for server in $servers
		do
			server_mu=`echo $server|cut -d "=" -f 1|cut -d "_" -f 4`
			server_address=`echo $server|cut -d "=" -f 2`
			ping_text=`ping -4 $server_address -c 10 -w 10 -q`
			ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
			ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
		
			if [ ! -z "$ping_time" ];then
				dbus set ssconf_basic_ping_"$server_mu"="$ping_time" ms / "$ping_loss"
			else
				dbus set ssconf_basic_ping_"$server_mu"="failed"
			fi
		done
	else
		servers=`dbus list ssconf_basic_server | sort -n -t "_" -k 4`
		for server in $servers
		do
		{
			server_mu=`echo $server|cut -d "=" -f 1|cut -d "_" -f 4`
			server_address=`echo $server|cut -d "=" -f 2`
			[ "$ssconf_basic_Ping_Method" == "2" ] && ping_text=`ping -4 $server_address -c 10 -w 10 -q`
			[ "$ssconf_basic_Ping_Method" == "3" ] && ping_text=`ping -4 $server_address -c 20 -w 20 -q`
			[ "$ssconf_basic_Ping_Method" == "4" ] && ping_text=`ping -4 $server_address -c 50 -w 50 -q`
			ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
			ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
		
			if [ ! -z "$ping_time" ];then
				dbus set ssconf_basic_ping_"$server_mu"="$ping_time" ms / "$ping_loss"
			else
				dbus set ssconf_basic_ping_"$server_mu"="failed"
			fi
		}&
		done
	fi
fi



