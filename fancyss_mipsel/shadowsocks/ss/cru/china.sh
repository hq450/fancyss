#!/bin/sh
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
/usr/sbin/wget -4 --spider --quiet --tries=2 --timeout=2 www.baidu.com
if [ "$?" == "0" ]; then
log='[ '$LOGTIME' ] working...'
else
log='[ '$LOGTIME' ] Problem detected!'
fi
nvram set ss_china_state="$log"
#dbus ram ss_basic_state_china="$log"
