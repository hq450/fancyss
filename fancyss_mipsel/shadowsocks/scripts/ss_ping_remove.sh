#!/bin/sh

eval `dbus export ssconf_basic`

# flush previous ping value in the table
pings=`dbus list ssconf_basic_ping | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ ! -z "$pings" ];then
	for ping in $pings
	do
		dbus remove "$ping"
	done
fi



