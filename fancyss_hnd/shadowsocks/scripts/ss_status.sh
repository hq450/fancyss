#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export ss_`
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")


get_china_status(){
	wget -4 --no-check-certificate --spider --quiet --tries=1 --timeout=4 www.baidu.com
	if [ "$?" == "0" ]; then
		log2='国内链接 【'$LOGTIME'】 ✓'
	else
		log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi

}

get_foreign_status(){
	wget -4 --no-check-certificate --spider --quiet --tries=1 --timeout=4 https://www.google.com.tw
	if [ "$?" == "0" ]; then
		log1='国外链接 【'$LOGTIME'】 ✓'
	else
		log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}


get_china_status
get_foreign_status

http_response "$log1@@$log2"
