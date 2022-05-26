#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh

ALL_NODES=`dbus list ss|grep conf_basic_server_|grep -v server_ip| sort -t "_" -nk 4`
rm -rf /tmp/ping.txt
ss_basic_ping_method=`dbus get ss_basic_ping_method`
ss_mwan_ping_dst=`dbus get ss_mwan_ping_dst`
[ -z "$ss_basic_ping_method" ] && ss_basic_ping_method="1"

IFS_LINE=`ip route show|grep 'default'|grep -v 'lo'|awk -F " " '{print $5}'| wc -l`
if [ "$IFS_LINE" -gt "1" ] && [ -n "$ss_mwan_ping_dst" ];then
	if [ "$ss_mwan_ping_dst" != "0" ];then
		l3_name=`ubus call network.interface dump|jq .interface["$ss_mwan_ping_dst"].l3_device|sed 's/"//g'`
		ARG="-I $l3_name"
	else
		ARG=""
	fi
else
	ARG=""
fi
#for node in $SS_NODES $SSR_NODES
for node in $ALL_NODES
do
{
	node_nu=`echo $node|cut -d "=" -f1|cut -d "_" -f4`
	[ -n "`echo $node|grep ssconf`" ] && node_type="ss" || node_type="ssr"
	node_doamin=`echo $node|cut -d "=" -f2`
	
	[ "$ss_basic_ping_method" == "1" ] && ping_text=`/bin/ping -4 $ARG $node_doamin -c 1 -w 1 -q`
	[ "$ss_basic_ping_method" == "2" ] && ping_text=`/bin/ping -4 $ARG $node_doamin -c 10 -w 10 -q`
	[ "$ss_basic_ping_method" == "3" ] && ping_text=`/bin/ping -4 $ARG $node_doamin -c 20 -w 20 -q`
	ping_time=`echo $ping_text | awk -F '/' '{print $4}'`
	[ -z "$ping_time" ] && ping_time="failed"
	ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
	echo $node_nu $node_type $ping_time $ping_loss >> /tmp/ping.txt
}>/dev/null 2>&1 &
#}&
done

sleep 1
while [ -n "`pidof ping`" ]; do
	sleep 1
done

response_text=`cat /tmp/ping.txt |sort -t ' ' -nk1|sed 's/^/["/g'|sed 's/ /","/g'|sed 's/$/"],/g'|sed 's/failed//g'|sed ':a;N;$!ba;s#\n##g'|sed 's/,$/]/g'|sed 's/^/[/g'|base64_encode`
http_response "$response_text"
sleep 1
#rm -rf /tmp/ping.txt
