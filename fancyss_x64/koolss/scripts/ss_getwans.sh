#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh

rm -rf /tmp/wan_names.txt
interface_nu=`ubus call network.interface dump|jq '.interface|length'`
if [ -z "$interface_nu" ];then
	echo "没有找到任何可用网络接口"
else
	j=0
	until [ "$j" == "$interface_nu" ]
	do
		lan_addr_prefix=`uci -q get network.lan.ipaddr|cut -d . -f1,2,3`
		WAN_EXIST=`ubus call network.interface dump|jq .interface[$j]|grep nexthop|grep -v "$lan_addr_prefix."|grep -v 127.0.0.1|sed 's/"nexthop"://g'|grep -v :`
		if [ -n "$WAN_EXIST" ];then
			wan_name=`ubus call network.interface dump|jq .interface[$j].interface|sed 's/"//g'`
			wan_ifname=`ubus call network.interface dump|jq .interface[$j].device|sed 's/"//g'`
			wan_ifname_l3=`ubus call network.interface dump|jq .interface[$j].l3_device|sed 's/"//g'`
			wan_up=`ubus call network.interface dump|jq .interface[$j].up|sed 's/"//g'`
			
			if [ "$wan_up" == "true" ];then
				#echo "[ \"$wan_ifname_l3\", \"$wan_name\" ]" >> /tmp/wan_names.txt
				echo "[ \"$j\", \"$wan_name\" ]" >> /tmp/wan_names.txt
			fi
		fi
		j=$(($j+1))
	done
fi

WANS=`cat /tmp/wan_names.txt|sed 's/$/,/g'|sed ':a;N;$!ba;s#\n##g'|sed 's/,$/]/g'|sed 's/^/[/g'|base64_encode`
if [ -n "$WANS" ];then
	dbus set ss_basic_arp="$arp"
fi

http_response "$WANS"