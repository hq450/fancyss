#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

# 此脚本用以获取fancyss插件的所有数据 + 节点数据
# 同时可以存放一些公用的函数
# 其他脚本如果需要获取节点数据的，只需要引用本脚本即可！无需单独去拿插件数据
# 引用方法：source /koolshare/scripts/ss_base.sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
source helper.sh
eval $(dbus export ss | sed 's/export //' | sed 's/;export /\n/g;' | sed '/ssconf_.*$/d'|sed 's/^/export /' | tr '\n' ';')
unset usb2jffs_time_hour
unset usb2jffs_week
unset usb2jffs_title
unset usb2jffs_day
unset usb2jffs_rsync
unset usb2jffs_sync
unset usb2jffs_inter_day
unset usb2jffs_inter_pre
unset usb2jffs_version
unset usb2jffs_mount_path
unset usb2jffs_inter_hour
unset usb2jffs_time_min
unset usb2jffs_inter_min
unset usb2jffs_backupfile_name
unset usb2jffs_backup_file
unset usb2jffs_mtd_jffs
unset usb2jffs_warn_2
unset DEVICENAME
unset DEVNAME
unset DEVPATH
unset DEVTYPE
unset INTERFACE
unset PRODUCT
unset USBPORT
unset SUBSYSTEM
unset SEQNUM
unset MAJOR
unset MINOR
unset SHLVL
unset TERM

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

# ss_basic_type
# 0	ss
# 1 ssr
# 2 koolgame (deleted in 3.0.4)
# 3 v2ray
# 4 xray
# 5 trojan
# 6 naive (不支持udp)
# 7 tuic
# 8 hysteria

cur_node=$(dbus get ssconf_basic_node)
base_1="name type mode server port method password ss_obfs ss_obfs_host ss_v2ray ss_v2ray_opts rss_protocol rss_protocol_param rss_obfs rss_obfs_param v2ray_uuid v2ray_alterid v2ray_security v2ray_network v2ray_headtype_tcp v2ray_headtype_kcp v2ray_headtype_quic v2ray_grpc_mode v2ray_network_path v2ray_network_host v2ray_kcp_seed v2ray_network_security v2ray_network_security_ai v2ray_network_security_sni v2ray_mux_concurrency v2ray_json xray_uuid xray_encryption xray_flow xray_network xray_headtype_tcp xray_headtype_kcp xray_headtype_quic xray_grpc_mode xray_network_path xray_network_host xray_kcp_seed xray_network_security xray_network_security_ai xray_network_security_sni xray_fingerprint xray_show xray_publickey xray_shortid xray_spiderx xray_prot xray_alterid xray_json tuic_json"
base_2="use_kcp v2ray_use_json v2ray_mux_enable v2ray_network_security_alpn_h2 v2ray_network_security_alpn_http xray_use_json xray_network_security_alpn_h2 xray_network_security_alpn_http trojan_ai trojan_uuid trojan_sni trojan_tfo naive_prot naive_server naive_port naive_user naive_pass hy2_server hy2_port hy2_pass hy2_up hy2_dl hy2_obfs hy2_obfs_pass hy2_sni hy2_ai hy2_tfo"
for config in ${base_1} ${base_2}
do
	key_1=$(dbus get ssconf_basic_${config}_${cur_node})
	if [ -n "$key_1" ];then
		key_2=ss_basic_${config}
		tmp="export $key_2=\"$key_1\""
		eval ${tmp}
	fi
	unset key_1 key_2
done
# ------------------------------------------------
gfw_on=$(dbus list ss_acl_mode_ | cut -d "=" -f 2 | grep -E "1")
chn_on=$(dbus list ss_acl_mode_ | cut -d "=" -f 2 | grep -E "2|3")
all_on=$(dbus list ss_acl_mode_ | cut -d "=" -f 2 | grep -E "5")
game_on=$(dbus list ss_acl_mode | cut -d "=" -f 2 | grep "3")
if [ "${ss_basic_mode}" == "1" -a -z "${chn_on}" -a -z "${all_on}" -o "${ss_basic_mode}" == "6" ];then
	# gfwlist模式的时候，且访问控制主机中不存在 大陆白名单模式 游戏模式 全局模式，则使用国内优先模式
	# 回国模式下自动判断使用国内优先
	DNS_PLAN=1
else
	# 其它情况，均使用国外优先模式
	DNS_PLAN=2
fi

# ---------------------- udp代理 ----------------------
# 1. 非游戏模式，访问控制内无游戏模式，且关闭了udp代理	（当前模式 off udp）
# 2. 非游戏模式，访问控制内无游戏模式，且开启了udp代理	（当前模式 all udp）
# 3. 非游戏模式，访问控制内无游戏模式，且开启了gpt代理	（当前模式 gpt udp）

# 1. 非游戏模式，访问控制内有游戏模式，且关闭了udp代理	（当前模式 off udp + 游戏模式 all udp）
# 2. 非游戏模式，访问控制内有游戏模式，且开启了udp代理	（当前模式 all udp + 游戏模式 all udp）
# 3. 非游戏模式，访问控制内有游戏模式，且开启了gpt代理	（当前模式 gpt udp + 游戏模式 all udp）

# 1. 游戏模式，访问控制内无其他模式，且关闭了udp代理	（游戏模式 all udp）
# 2. 游戏模式，访问控制内无其他模式，且开启了udp代理	（游戏模式 all udp）
# 3. 游戏模式，访问控制内无其他模式，且开启了gpt代理	（游戏模式 all udp）

# 1. 游戏模式，访问控制内有其他模式，且关闭了udp代理	（游戏模式 all udp + 其他模式 off udp）
# 2. 游戏模式，访问控制内有其他模式，且开启了udp代理	（游戏模式 all udp + 其他模式 all udp）
# 3. 游戏模式，访问控制内有其他模式，且开启了gpt代理	（游戏模式 all udp + 其他模式 gpt udp）

# 默认不开启udp
mangle=0

if [ "${ss_basic_mode}" == "3" ];then
	# 游戏模式下启用udp
	mangle=1
fi

# 访问控制内有主机开启了游戏模式
if [ -n "${game_on}" ];then
	mangle=1
fi

if [ "${ss_basic_udpall}" == "1" ];then
	mangle=1
fi

if [ "${ss_basic_udpgpt}" == "1" ];then
	mangle=1
fi

# naive 节点不支持udp
if [ "${ss_basic_type}" == "6" ];then
	mangle=0
fi


if [ "${ss_basic_type}" == "6" ];then
	ss_basic_password=$(echo ${ss_basic_naive_pass} | base64_decode)
	ss_basic_server=${ss_basic_naive_server}
elif [ "${ss_basic_type}" == "8" ];then
	ss_basic_server=${ss_basic_hy2_server}
else
	ss_basic_password=$(echo ${ss_basic_password} | base64_decode)
fi

ss_basic_server_orig=${ss_basic_server}

if [ ! -x "/koolshare/bin/v2ray" ];then
	ss_basic_vcore=1
fi
if [ ! -x "/koolshare/bin/trojan" ];then
	ss_basic_tcore=1
fi
if [ ! -x "/koolshare/bin/v2ray" -a ! -x "/tmp/shadowsocks/bin/sslocal" ];then
	ss_basic_rust=0
fi

# trojan 全局允许不安全
if [ "${ss_basic_type}" == "5" -a "${ss_basic_tjai}" == "1" ];then
	ss_basic_trojan_ai=1
	#eval ss_basic_trojan_ai_${cur_node}=1
fi

# ss_basic_dns_flag="1"    使用代理的udp
# ss_basic_dns_flag="2"    使用代理的socks

# v2ray/xray使用自带dns
ss_basic_dns_flag="0"
DNSF_PORT=1055
if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "1" ];then
	# 新dns方案  chinadns-ng，udp 方案
	ss_basic_dns_flag="1"
	if [ "${ss_basic_tcore}" != "1" -a "${ss_basic_type}" == "5" ];then
		# trojan下只有xray核心支持udp，trojan核心不支持udp
		ss_basic_dns_flag="2"
	fi
fi
if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "2" ];then
	# 新dns方案 chinadns-ng，tcp 方案，dns2socks，socks5 23456 needed
	ss_basic_dns_flag="2"
fi
if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "3" ];then
	# 新dns方案 chinadns-ng，dohclient，socks5 23456 needed
	ss_basic_dns_flag="2"
fi
if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "2" ];then
	# 新dns方案  chinadns-ng，v2ray/xray原生dns，经过smartdns，非socks5 + dns2socks 方案
	ss_basic_dns_flag="2"
	DNSF_PORT=7913
fi
if [ "${ss_basic_advdns}" != "1" -a "${ss_foreign_dns}" == "7" ]; then
	# 旧dns方案，v2ray/xray原生dns，非socks5 + dns2socks 方案
	ss_basic_dns_flag="1"
	DNSF_PORT=7913
fi

if [ "${ss_basic_advdns}" != "1" -a "${ss_foreign_dns}" == "4" ]; then
	# 旧dns方案，ss-tunnel，非socks5 + dns2socks 方案
	if [ "${ss_basic_type}" == "3" -o "${ss_basic_type}" == "4" -o "${ss_basic_type}" == "5" -o "${ss_basic_type}" == "6" ];then
		# v2ray xray trojan naive 不支持ss-tunnel，会自动切换到dns2socks，所以默认应该开启socks5
		ss_basic_dns_flag="2"
		DNSF_PORT=7913
	else
		ss_basic_dns_flag="1"
		DNSF_PORT=7913
	fi
fi

#---------------------------
# 20230609，119.29.29.29的tcp解析有问题，如果用户选这个，强制更换到119.28.28.28
if [ "${ss_basic_chng_china_1_tcp}" == "5" ];then
	ss_basic_chng_china_1_tcp="6"
fi
if [ "${ss_basic_chng_china_2_tcp}" == "5" ];then
	ss_basic_chng_china_2_tcp="6"
fi

[ -z "$(dbus get ss_basic_wt_furl)" ] && ss_basic_wt_furl="http://www.google.com.tw"
[ -z "$(dbus get ss_basic_wt_curl)" ] && ss_basic_wt_curl="http://www.baidu.com"

#----------------------------
number_test(){
	case $1 in
		''|*[!0-9]*)
			echo 1
			;;
		*) 
			echo 0
			;;
	esac
}

__valid_ip() {
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$")
	local format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')
	if [ -n "${format_4}" -a -z "${format_6}" ]; then
		echo "${format_4}"
		return 0
	elif [ -z "${format_4}" -a -n "${format_6}" ]; then
		echo "$format_6"
		return 0
	else
		echo ""
		return 1
	fi
}

__valid_ip_silent() {
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$")
	local format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')
	if [ -n "${format_4}" -a -z "${format_6}" ]; then
		return 0
	elif [ -z "${format_4}" -a -n "${format_6}" ]; then
		return 0
	else
		return 1
	fi
}

__valid_port() {
	local port=$1
	if [ $(number_test ${port}) != "0" ];then
		echo ""
		return 1
	fi

	if [ ${port} -gt "1" -a ${port} -lt "65535" ];then
		echo "${port}"
		return 0
	else
		echo ""
		return 1
	fi
}

detect_running_status(){
	[ "${ss_basic_noruncheck}" == "1" ] && return
	local BINNAME=$1
	local PIDFILE=$2
	local PID1
	local PID2
	local i=40
	if [ -n "${PIDFILE}" ];then
		until [ -n "${PID1}" -a -n "${PID2}" -a -n $(echo ${PID1} | grep -Eow ${PID2} 2>/dev/null) ]; do
			usleep 250000
			i=$(($i - 1))
			PID1=$(pidof ${BINNAME})
			PID2=$(cat ${PIDFILE})
			if [ "$i" -lt 1 ]; then
				echo_date "$1进程启动失败！请检查你的配置！"
				#return 1
				close_in_five flag
			fi
		done
		echo_date "$1启动成功！pid：${PID2}"
	else
		until [ -n "${PID1}" ]; do
			usleep 250000
			i=$(($i - 1))
			PID1=$(pidof ${BINNAME})
			if [ "$i" -lt 1 ]; then
				echo_date "$1进程启动失败，请检查你的配置！"
				#return 1
				close_in_five flag
			fi
		done
		echo_date "$1启动成功，pid：${PID1}"
	fi
}

detect_running_status2(){
	[ "${ss_basic_noruncheck}" == "1" ] && return
	# detect process by binary name and key word
	local BINNAME=$1
	local KEY=$2
	local SLIENT=$3
	local i=100
	local DPID
 	until [ -n "${DPID}" ]; do
 		# wait for 0.1s
		usleep 100000
		i=$(($i - 1))
		DPID=$(ps -w | grep "${BINNAME}" | grep -v "grep" | grep "${KEY}" | awk '{print $1}')
		if [ "$i" -lt 1 ]; then
			echo_date "$1进程启动失败，请检查你的配置！"
			#return 1
			close_in_five flag
		fi
	done
	if [ -z "${SLIENT}" ];then
		echo_date "$1启动成功，pid：${DPID}"
	fi
}