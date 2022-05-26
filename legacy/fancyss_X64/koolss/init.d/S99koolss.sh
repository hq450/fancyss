#!/bin/sh /etc/rc.common
#
# Copyright (C) 2015 OpenWrt-dist
# Copyright (C) 2016 fw867 <ffkykzs@gmail.com>
# Copyright (C) 2016 sadog <sadoneli@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

START=99
STOP=15
source /koolshare/scripts/base.sh
eval `dbus export ss`

start(){
	if [ "$ss_basic_enable" == "1" ];then
		sh /koolshare/ss/ssstart.sh restart > /tmp/upload/ss_log.txt
		echo "XU6J03M6" >> /tmp/upload/ss_log.txt
	fi
}

stop(){
	sh /koolshare/ss/ssstart.sh stop > /tmp/upload/ss_log.txt
	echo "XU6J03M6" >> /tmp/upload/ss_log.txt
}
