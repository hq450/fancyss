#!/bin/sh

# shadowsocks script for koolshare merlin armv7l 384 router with kernel 2.6.36.4

source /koolshare/scripts/base.sh

start_ping(){
	touch /tmp/ss_ping.lock
	eval $(dbus export ss_basic_ping)
	[ -z "$ss_basic_ping_node" ] && ss_basic_ping_node="0"
	[ -z "$ss_basic_ping_method" ] && ss_basic_ping_method="2"
	if [ "$ss_basic_ping_node" != "0" ];then
		node_doamin=$(dbus get ssconf_basic_server_$ss_basic_ping_node)
		[ "$ss_basic_ping_method" == "1" ] && ping_text=$(ping -4 $node_doamin -c 1 -w 1 -q)
		[ "$ss_basic_ping_method" == "2" ] && ping_text=$(ping -4 $node_doamin -c 10 -w 10 -q)
		[ "$ss_basic_ping_method" == "3" ] && ping_text=$(ping -4 $node_doamin -c 20 -w 20 -q)
		ping_time=$(echo $ping_text|grep avg|awk -F '/' '{print $4}')
		[ -z "$ping_time" ] && ping_time="failed"
		ping_loss=$(echo $ping_text|grep loss|awk -F ', ' '{print $3}'|awk '{print $1}')
		echo "$ss_basic_ping_node>$ping_time>$ping_loss" >> /tmp/ping.txt
	else
		dbus list ssconf_basic_server_|grep -v "server_ip"|sort -n -t "_" -k 4|while read node
		do
		{
			node_nu=$(echo $node|cut -d "=" -f1|cut -d "_" -f4)
			node_doamin=$(echo $node|cut -d "=" -f2)
			[ "$ss_basic_ping_method" == "1" ] && ping_text=$(ping -4 $node_doamin -c 1 -w 1 -q)
			[ "$ss_basic_ping_method" == "2" ] && ping_text=$(ping -4 $node_doamin -c 5 -w 5 -q)
			[ "$ss_basic_ping_method" == "3" ] && ping_text=$(ping -4 $node_doamin -c 10 -w 10 -q)
			[ "$ss_basic_ping_method" == "4" ] && ping_text=$(ping -4 $node_doamin -c 20 -w 20 -q)
			ping_time=$(echo $ping_text|awk -F '/' '{print $4}')
			[ -z "$ping_time" ] && ping_time="failed"
			ping_loss=$(echo $ping_text|grep loss|awk -F ', ' '{print $3}'|awk '{print $1}')
			echo "$node_nu>$ping_time>$ping_loss" >> /tmp/ping.txt
		} &
		done
	fi
	sleep 2
	TOTAL_LINE=$(dbus list ssconf_basic_server_|grep -v "server_ip"|sort -n -t "_" -k 4|wc -l)
	CURR_LINE=$(cat /tmp/ping.txt|wc -l)
	while [ "$CURR_LINE" -lt "$TOTAL_LINE" ]
	do
		usleep 200000
		CURR_LINE=$(cat /tmp/ping.txt|wc -l)
	done
	response_text=$(cat /tmp/ping.txt|sort -t '>' -nk1|sed 's/^/["/g'|sed 's/>/","/g'|sed 's/$/"],/g'|sed 's/failed//g'|sed ':a;N;$!ba;s#\n##g'|sed 's/,$/]/g'|sed 's/^/[/g'|base64|sed ':a;N;$!ba;s#\n##g')
	http_response "$response_text"
	rm -rf /tmp/ss_ping.lock
}

if [ -n "$(pidof ping)" ] && [ -n "$(pidof ss_ping.sh)" ] && [ -f "/tmp/ss_ping.lock" ]; then
	while [ -n "$(pidof ping)" ]
	do
		usleep 500000
	done
	sleep 2
	response_text=$(cat /tmp/ping.txt|sort -t '>' -nk1|sed 's/^/["/g'|sed 's/>/","/g'|sed 's/$/"],/g'|sed 's/failed//g'|sed ':a;N;$!ba;s#\n##g'|sed 's/,$/]/g'|sed 's/^/[/g'|base64|sed ':a;N;$!ba;s#\n##g')
	http_response "$response_text"
	rm -rf /tmp/ss_ping.lock
else
	rm -rf /tmp/ping.txt
	start_ping
fi
