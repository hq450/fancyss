#!/bin/sh
eval `dbus export ss`

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

# 此脚本用于升级3.6.4版本及其以下的ss插件储存数据

nodes=`dbus list ssc|grep port|cut -d "=" -f1|cut -d "_" -f4|sort -n`
for node in $nodes
do
	if [ "`dbus get ssconf_basic_use_rss_$node`" == "1" ];then
		#ssr
		dbus remove ssconf_basic_ss_v2ray_plugin_$node
		dbus remove ssconf_basic_ss_v2ray_plugin_opts_$node
		dbus remove ssconf_basic_koolgame_udp_$node
	else
		if [ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ];then
			#koolgame
			dbus remove ssconf_basic_rss_protocol_$node
			dbus remove ssconf_basic_rss_protocol_param_$node
			dbus remove ssconf_basic_rss_obfs_$node
			dbus remove ssconf_basic_rss_obfs_param_$node
			dbus remove ssconf_basic_ss_v2ray_plugin_$node
			dbus remove ssconf_basic_ss_v2ray_plugin_opts_$node
		else
			#ss
			dbus remove ssconf_basic_rss_protocol_$node
			dbus remove ssconf_basic_rss_protocol_param_$node
			dbus remove ssconf_basic_rss_obfs_$node
			dbus remove ssconf_basic_rss_obfs_param_$node
			dbus remove ssconf_basic_koolgame_udp_$node
			[ -z "`dbus get ssconf_basic_ss_v2ray_plugin_$node`" ] && dbus set ssconf_basic_ss_v2ray_plugin_$node="0"
		fi
	fi
	dbus remove ssconf_basic_use_rss_$node
done

use_node=`dbus get ssconf_basic_node`
if [ -n "$use_node" ];then
	dbus remove ss_basic_server
	dbus remove ss_basic_mode
	dbus remove ss_basic_port
	dbus remove ss_basic_method
	dbus remove ss_basic_ss_v2ray_plugin
	dbus remove ss_basic_ss_v2ray_plugin_opts
	dbus remove ss_basic_rss_protocol
	dbus remove ss_basic_rss_protocol_param
	dbus remove ss_basic_rss_obfs
	dbus remove ss_basic_rss_obfs_param
	dbus remove ss_basic_koolgame_udp
	dbus remove ss_basic_use_rss
	dbus remove ss_basic_use_kcp
	sleep 1
	[ -n "`dbus get ssconf_basic_server_$node`" ] && dbus set ss_basic_server=`dbus get ssconf_basic_server_$node`
	[ -n "`dbus get ssconf_basic_mode_$node`" ] && dbus set ss_basic_mode=`dbus get ssconf_basic_mode_$node`
	[ -n "`dbus get ssconf_basic_port_$node`" ] && dbus set ss_basic_port=`dbus get ssconf_basic_port_$node`
	[ -n "`dbus get ssconf_basic_method_$node`" ] && dbus set ss_basic_method=`dbus get ssconf_basic_method_$node`
	[ -n "`dbus get ssconf_basic_ss_v2ray_plugin_$node`" ] && dbus set ss_basic_ss_v2ray_plugin=`dbus get ssconf_basic_ss_v2ray_plugin_$node`
	[ -n "`dbus get ssconf_basic_ss_v2ray_plugin_opts_$node`" ] && dbus set ss_basic_ss_v2ray_plugin_opts=`dbus get ssconf_basic_ss_v2ray_plugin_opts_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_$node`" ] && dbus set ss_basic_rss_protocol=`dbus get ssconf_basic_rss_protocol_$node`
	[ -n "`dbus get ssconf_basic_rss_protocol_param_$node`" ] && dbus set ss_basic_rss_protocol_param=`dbus get ssconf_basic_rss_protocol_param_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_$node`" ] && dbus set ss_basic_rss_obfs=`dbus get ssconf_basic_rss_obfs_$node`
	[ -n "`dbus get ssconf_basic_rss_obfs_param_$node`" ] && dbus set ss_basic_rss_obfs_param=`dbus get ssconf_basic_rss_obfs_param_$node`
	[ -n "`dbus get ssconf_basic_koolgame_udp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_koolgame_udp_$node`
	[ -n "`dbus get ssconf_basic_use_kcp_$node`" ] && dbus set ss_basic_koolgame_udp=`dbus get ssconf_basic_use_kcp_$node`
fi