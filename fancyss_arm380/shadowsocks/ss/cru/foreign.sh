#!/bin/sh
source /koolshare/scripts/base.sh
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

ret=`/koolshare/bin/httping www.google.com.tw -s -Z -c1 -f -t 3 2>/dev/null|sed -n '2p'|sed 's/seq=0//g'|sed 's/([0-9]\+\sbytes),\s//g'`
S1=`echo $ret|grep -Eo "200 OK"`
if [ -n "$S1" ]; then
	S2=`echo $ret|sed 's/time=//g'|awk '{printf "%.0f ms\n",$(NF -3)}'`
	log='国外链接 【'$LOGTIME'】 ✓&nbsp;&nbsp;'$S2''
else
	log='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
fi

nvram set ss_foreign_state="$log"
