#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh
LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
LOGTIME1=$(TZ=UTC-8 date -R "+%m-%d %H:%M:%S")
CURRENT=$(dbus get ssconf_basic_node)
eval $(dbus export ss_failover_enable)

get_china_status(){
	local ret=`httping www.baidu.com -s -Z -c1 -f -t 3 2>/dev/null|sed -n '2p'|sed 's/seq=0//g'|sed 's/([0-9]\+\sbytes),\s//g'`
	[ "$ss_failover_enable" == "1" ] && echo $LOGTIME1 $ret >> $LOGFILE_C
	local S1=`echo $ret|grep -Eo "200 OK"`
	if [ -n "$S1" ]; then
		local S2=`echo $ret|sed 's/time=//g'|awk '{printf "%.0f ms\n",$(NF -3)}'`
		log2='国内链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	else
		log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}

get_foreign_status(){
	local ret=`httping www.google.com.tw -s -Z -c1 -f -t 3 2>/dev/null|sed -n '2p'|sed 's/seq=0//g'|sed 's/([0-9]\+\sbytes),\s//g'`
	[ "$ss_failover_enable" == "1" ] && echo $LOGTIME1 $ret "[`dbus get ssconf_basic_name_$CURRENT`]" $1 >> $LOGFILE_F
	local S1=`echo $ret|grep -Eo "200 OK"`
	if [ -n "$S1" ]; then
		local S2=`echo $ret|sed 's/time=//g'|awk '{printf "%.0f ms\n",$(NF -3)}'`
		log1='国外链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	else
		log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}

PIDC="`ps|grep httping|grep baidu|grep -v grep`"
PIDF="`ps|grep httping|grep google.com.tw|grep -v grep`"
[ -n "$PIDC" ] && echo $LOGTIME1 httping China timeout >> $LOGFILE_C && kill -9 $PIDC
[ -n "$PIDF" ] && echo $LOGTIME1 httping foreign timeout "[`dbus get ssconf_basic_name_$CURRENT`]" >> $LOGFILE_F && kill -9 $PIDF
[ -n "`ps|grep ssconfig.sh|grep -v grep`" ] && exit
[ -n "`ps|grep ss_v2ray.sh|grep -v grep`" ] && exit
[ "`dbus get ss_basic_enable`" != "1" ] && exit

get_china_status $1
get_foreign_status $1

if [ "$ss_failover_enable" == "1" ];then
	echo "$log1@@$log2" > /tmp/upload/ss_status.txt
else
	http_response "$log1@@$log2"
fi
