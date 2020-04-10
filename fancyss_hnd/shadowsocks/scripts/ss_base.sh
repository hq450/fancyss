#!/bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

# 此脚本用以获取fancyss插件的所有数据 + 节点数据
# 同时可以存放一些公用的函数
# 其他脚本如果需要获取节点数据的，只需要引用本脚本即可！无需单独去拿插件数据
# 引用方法：source /koolshare/scripts/ss_base.sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
source helper.sh
eval `dbus export ss`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

cur_node=$ssconf_basic_node
base_1="type mode server port method password ss_obfs ss_obfs_host ss_v2ray ss_v2ray_opts koolgame_udp rss_protocol rss_protocol_param rss_obfs rss_obfs_param v2ray_uuid v2ray_alterid v2ray_security v2ray_network v2ray_headtype_tcp v2ray_headtype_kcp v2ray_network_path v2ray_network_host v2ray_network_security v2ray_mux_concurrency v2ray_json"
base_2="use_kcp v2ray_use_json v2ray_mux_enable"
for config in $base_1 $base_2
do
	key_1=ssconf_basic_${config}_${cur_node}
	key_2=ss_basic_${config}
	tmp="export $key_2=\$$key_1"
	eval $tmp
	unset key_1 key_2
done

gfw_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "1"`
chn_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "2|3|4"`
all_on=`dbus list ss_acl_mode_|cut -d "=" -f 2 | grep -E "5"`
game_on=`dbus list ss_acl_mode|cut -d "=" -f 2 | grep 3`
[ -n "$game_on" ] || [ "$ss_basic_mode" == "3" ] && mangle=1
ss_basic_password=`echo $ss_basic_password|base64_decode`
ss_basic_server_orig=$ss_basic_server
# 兼容1.2.0及其以下
[ -z "$ss_basic_type" ] && {
	if [ -n "$ss_basic_rss_protocol" ];then
		ss_basic_type="1"
	else
		if [ -n "$ss_basic_koolgame_udp" ];then
			ss_basic_type="2"
		else
			if [ -n "$ss_basic_v2ray_use_json" ];then
				ss_basic_type="3"
			else
				ss_basic_type="0"
			fi
		fi
	fi
}
