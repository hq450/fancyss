#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`

if [ "$ss_basic_enable" == "1" ];then
	sh /koolshare/ss/ssconfig.sh restart
else
	sh /koolshare/ss/ssconfig.sh stop
fi
