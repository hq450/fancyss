#!/bin/sh

dbus set ssconf_basic_node="1"
/koolshare/ss/ssconfig.sh stop;
/koolshare/scripts/ss_online_update.sh fancyss 3;
dbus set ss_heart_beat="1"
/koolshare/ss/ssconfig.sh restart
