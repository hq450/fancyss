#!/bin/sh

eval `dbus export ssconf_basic`

# flush previous test value in the table
webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ ! -z "$webtest" ];then
	for line in $webtest
	do
		dbus remove "$line"
	done
fi

