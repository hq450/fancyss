#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh
LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
LOGTIME1=$(TZ=UTC-8 date -R "+%m-%d %H:%M:%S")
CURRENT=$(dbus get ssconf_basic_node)

get_china_status(){
	# --- wget ---
	#wget -4 --no-check-certificate --spider --quiet --tries=1 --timeout=4 www.baidu.com
	#if [ "$?" == "0" ]; then
	#	log2='国内链接 【'$LOGTIME'】 ✓'
	#else
	#	log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	#fi

	# --- curl ---
	#local ret=`curl -o /dev/null -s -w '%{http_code}:%{time_total}' -X HEAD -I 'http://www.baidu.com'`
	#local S1=`echo $ret|cut -d":" -f1`
	#if [ "$S1" == "200" ]; then
	#	local S2=`echo $ret|cut -d":" -f2`
	#	S2=`awk 'BEGIN{printf "%.0fms\n",('$S2'*'1000')}'`
	#	log2='国内链接  【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	#else
	#	log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	#fi

	# --- httping ---
	local ret=`httping www.baidu.com -s -Z -c1 -f -t 3 2>/dev/null|sed -n '2p'|sed 's/seq=0//g'|sed 's/([0-9]\+\sbytes),\s//g'`
	echo $LOGTIME1 $ret >> $LOGFILE_C
	local S1=`echo $ret|grep -Eo "200 OK"`
	if [ -n "$S1" ]; then
		local S2=`echo $ret|sed 's/time=//g'|awk '{printf "%.0f ms\n",$(NF -3)}'`
		log2='国内链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	else
		log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
	# --- httping ---
}

get_foreign_status(){
	# --- wget ---
	#wget -4 --no-check-certificate --spider --quiet --tries=1 --timeout=4 https://www.google.com.tw
	#if [ "$?" == "0" ]; then
	#	log1='国外链接 【'$LOGTIME'】 ✓'
	#else
	#	log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	#fi

	# --- curl ---
	#local ret=`curl -o /dev/null -s -w '%{http_code}:%{time_total}' -X HEAD -I 'http://www.google.com.tw'`
	#local S1=`echo $ret|cut -d":" -f1`
	#if [ "$S1" == "200" ]; then
	#	local S2=`echo $ret|cut -d":" -f2`
	#	S2=`awk 'BEGIN{printf "%.0fms\n",('$S2'*'1000')}'`
	#	log1='国外链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	#else
	#	log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	#fi

	# --- httping ---
	local ret=`httping www.google.com.tw -s -Z -c1 -f -t 3 2>/dev/null|sed -n '2p'|sed 's/seq=0//g'|sed 's/([0-9]\+\sbytes),\s//g'`
	echo $LOGTIME1 $ret "[`dbus get ssconf_basic_name_$CURRENT`]" >> $LOGFILE_F
	local S1=`echo $ret|grep -Eo "200 OK"`
	if [ -n "$S1" ]; then
		local S2=`echo $ret|sed 's/time=//g'|awk '{printf "%.0f ms\n",$(NF -3)}'`
		log1='国外链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
	else
		log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}

[ "`ps|grep ssconfig.sh|grep -v grep`" ] && exit
[ "`dbus get ss_basic_enable`" != "1" ] && exit

get_china_status
get_foreign_status
curl -X POST -d "$log1@@$log2" http://127.0.0.1/_resp/9527
