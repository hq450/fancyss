#!/bin/sh

alias echo_date1='echo $(date +%Y年%m月%d日\ %X)'
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
date=`echo_date1`
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")


get_china_status(){
	wget -4 --spider --quiet --tries=2 --timeout=2 www.baidu.com
	if [ "$?" == "0" ]; then
		log2='国内链接 【'$LOGTIME'】 ✓'
	else
		log2='国内链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}

get_foreign_status(){
	wget -4 --spider --quiet --tries=2 --timeout=2 www.google.com.tw
	if [ "$?" == "0" ]; then
		log1='国外链接 【'$LOGTIME'】 ✓'
	else
		log1='国外链接 【'$LOGTIME'】 <font color='#FF0000'>X</font>'
	fi
}

get_china_status
get_foreign_status

http_response "$log1@@$log2"
