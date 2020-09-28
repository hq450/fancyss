#!/bin/sh

# shadowsocks script for qca-ipq806x platform router

source /koolshare/scripts/ss_base.sh
game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`
[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && mangle=1
v1=`pidof speederv1`
v2=`pidof speederv2`
RAW=`pidof udp2raw`
[ "$ss_basic_udp2raw_boost_enable" == "1" ] || [ "$ss_basic_udp2_boost_enable" == "1" ] && SPEED_UDP=1

[ -n "$v1" ] && message1="【UDPspeederV1运行中，pid：$v1】" || message1="【UDPspeederV1未运行】"
[ -n "$v2" ] && message2="【UDPspeederV2运行中，pid：$v2】" || message2="【UDPspeederV2未运行】"
[ -n "$RAW" ] && message3="【UDP2raw运行中，pid：$RAW】" || message3="【UDP2raw未运行】"

[ -n "$v1" ] && [ -z "$v2" ] && message2=""
[ -z "$v1" ] && [ -n "$v2" ] && message1=""
[ -z "$v1" ] && [ -z "$v2" ] && [ -z "$RAW" ] && message1="" && message2="" && message3="" && message1="udp加速未运行"

[ -n "$v1" ] && [ -n "$RAW" ] && message0="串联模式： "
[ -n "$v2" ] && [ -n "$RAW" ] && message0="串联模式： "

[ -z "$v1" ] && [ -z "$v2" ] && [ -n "$RAW" ] && message0="" && message1="" && message2=""
[ -n "$v1" ] && [ -z "$v2" ] && [ -z "$RAW" ] && message3=""
[ -n "$v2" ] && [ -z "$v1" ] && [ -z "$RAW" ] && message3=""
check_status(){
	http_response $message0 $message1 $message2 $message3 
}

if [ "$ss_basic_enable" == "1" ];then
	check_status
else
	http_response "插件尚未启用！"
fi