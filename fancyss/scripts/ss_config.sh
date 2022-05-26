#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)

mkdir -p /tmp/upload
true > /tmp/upload/ss_log.txt
http_response "$1"

case $2 in
start)
	if [ "${ss_basic_enable}" == "1" ];then
		sh /koolshare/ss/ssconfig.sh restart >> /tmp/upload/ss_log.txt 2>&1
	else
		sh /koolshare/ss/ssconfig.sh stop >> /tmp/upload/ss_log.txt 2>&1
	fi
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac