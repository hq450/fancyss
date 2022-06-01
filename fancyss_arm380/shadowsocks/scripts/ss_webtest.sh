#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

source /koolshare/scripts/base.sh
eval `dbus export ssconf_basic`

# flush previous test value in the table
webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ ! -z "$webtest" ];then
	for line in $webtest
	do
		dbus remove "$line"
	done
fi

start_webtest(){
	array1=`dbus get ssconf_basic_server_$nu`
	array2=`dbus get ssconf_basic_port_$nu`
	array3=`dbus get ssconf_basic_password_$nu|base64_decode`
	array4=`dbus get ssconf_basic_method_$nu`
	array5=`dbus get ssconf_basic_use_rss_$nu`
	#array6=`dbus get ssconf_basic_onetime_auth_$nu`
	array7=`dbus get ssconf_basic_rss_protocol_$nu`
	array8=`dbus get ssconf_basic_rss_obfs_$nu`
	array9=`dbus get ssconf_basic_ss_v2ray_plugin_$nu`
	array10=`dbus get ssconf_basic_ss_v2ray_plugin_opts_$nu`
	array11=`dbus get ssconf_basic_mode_$nu`
	
	#[ "$array6" -ne "1" ] && ARG_OTA="" || ARG_OTA="-A";
	if [ "$array10" != "" ];then
		if [ "$array9" == "1" ];then
			ARG_V2RAY_PLUGIN="--plugin v2ray-plugin --plugin-opts $array10"
		else
			ARG_V2RAY_PLUGIN=""
		fi
	fi
	
	if [ "$array11" == "1" ] || [ "$array11" == "2" ] || [ "$array11" == "3" ] || [ "$array11" == "5" ];then
		if [ "$array5" == "1" ];then
			cat > /tmp/tmp_ss.json <<-EOF
			{
			    "server":"$array1",
			    "server_port":$array2,
			    "local_port":23458,
			    "password":"$array3",
			    "timeout":600,
			    "protocol":"$array7",
			    "obfs":"$array8",
			    "obfs_param":"www.baidu.com",
			    "method":"$array4"
			}
		EOF
			rss-local -b 0.0.0.0 -l 23458 -c /tmp/tmp_ss.json -u -f /var/run/sslocal2.pid >/dev/null 2>&1
			sleep 2
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			# result=`curl -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}:%{speed_download} --socks5-hostname 127.0.0.1:23456 https://www.google.com/`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep rss-local|grep 23458|awk '{print $1}'` >/dev/null 2>&1
			rm -rf /tmp/tmp_ss.json
		else
			ss-local -b 0.0.0.0 -l 23458 -s $array1 -p $array2 -k $array3 -m $array4 -u $ARG_OTA $ARG_V2RAY_PLUGIN -f /var/run/sslocal3.pid >/dev/null 2>&1
			sleep 2
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep ss-local|grep 23458|awk '{print $1}'` >/dev/null 2>&1
		fi
	else
		dbus set ssconf_basic_webtest_$nu="failed"
	fi
}

# start testing
if [ "$ssconf_basic_test_node" != "0" ];then
	nu="$ssconf_basic_test_node"
	start_webtest
else
	server_nu=`dbus list ssconf_basic_server | sort -n -t "_" -k 4|cut -d "=" -f 1|cut -d "_" -f 4`
	for nu in $server_nu
	do
		start_webtest
	done
fi
