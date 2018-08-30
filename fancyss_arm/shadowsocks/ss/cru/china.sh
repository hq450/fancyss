#!/bin/sh
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
/usr/sbin/wget -4 --spider --quiet --tries=2 --timeout=2 www.baidu.com

if [ "$?" == "0" ]; then
	log='<font color='#fc0'>国内连接 - [ '$LOGTIME' ] ✓</font>'
	#log='国内连接 - [ '$LOGTIME' ] ✓'
else
	log='<font color='#FF5722'>国内连接 - [ '$LOGTIME' ] X</font>'
fi

nvram set ss_china_state="$log"