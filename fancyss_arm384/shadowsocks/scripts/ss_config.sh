#!/bin/sh

# shadowsocks script for koolshare merlin armv7l 384 router with kernel 2.6.36.4

source /koolshare/scripts/base.sh
eval $(dbus export ss_basic_)

mkdir -p /tmp/upload
echo "" > /tmp/upload/ss_log.txt
http_response "$1"

case $2 in
start)
	if [ "$ss_basic_enable" == "1" ];then
		sh /koolshare/ss/ssconfig.sh restart >> /tmp/upload/ss_log.txt
	else
		sh /koolshare/ss/ssconfig.sh stop >> /tmp/upload/ss_log.txt
	fi
	echo XU6J03M6 >> /tmp/upload/ss_log.txt
	;;
esac