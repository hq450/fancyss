#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
#-----------------------------------------------
# Variable definitions
THREAD=$(grep -c '^processor' /proc/cpuinfo)
dbus set ss_basic_version_local=$(cat /koolshare/ss/version)
LOG_FILE=/tmp/upload/ss_log.txt
CONFIG_FILE=/koolshare/ss/ss.json
LOCK_FILE=/var/lock/koolss.lock
DNSC_PORT=53
ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
ISP_DNS2=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 2p | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
lan_ipaddr=$(nvram get lan_ipaddr)
ip_prefix_hex=$(nvram get lan_ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}')
WAN_ACTION=$(ps | grep /jffs/scripts/wan-start | grep -v grep)
NAT_ACTION=$(ps | grep /jffs/scripts/nat-start | grep -v grep)
ARG_OBFS=""
OUTBOUNDS="[]"
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')

#-----------------------------------------------

cmd() {
	# echo_date "$*" 2>&1
	# env -i PATH=${PATH} "$@" 2>/dev/null
	env -i PATH=${PATH} "$@" >/dev/null 2>&1 &
}

run(){
	env -i PATH=${PATH} "$@"
}

run_bg(){
	env -i PATH=${PATH} "$@" >/dev/null 2>&1 &
}

set_lock() {
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}

unset_lock() {
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

get_model_name(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		echo "${ODMPID}"
	else
		echo "${PRODUCTID}"
	fi
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css 2>/dev/null|head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css 2>/dev/null|head -n1)
	local TS_FLAG=$(grep -o "2ED9C3" /www/css/difference.css 2>/dev/null|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	if [ -n "${TS_FLAG}" ];then
		UI_TYPE="TS"
	fi

	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

get_time(){
	local src=$1
	local debug=$2
	# Automatically Updates System Time According to the NIST Atomic Clock in a Linux Environment
	nistTime=$(curl -4skI --connect-timeout 2 --max-time 2 "${src}" | grep "Date")
	if [ -z "${nistTime}" ]; then
		return 1
	fi
	dateString=$(echo $nistTime | cut -d' ' -f2-7)
	dayString=$(echo $nistTime | cut -d' ' -f2-2)
	dateValue=$(echo $nistTime | cut -d' ' -f3-3)
	monthValue=$(echo $nistTime | cut -d' ' -f4-4)
	yearValue=$(echo $nistTime | cut -d' ' -f5-5)
	timeValue=$(echo $nistTime | cut -d' ' -f6-6)
	timeZoneValue=$(echo $nistTime | cut -d' ' -f7-7)
	#echo $dateString
	case $monthValue in
		"Jan")
			monthValue="01"
			;;
		"Feb")
			monthValue="02"
			;;
		"Mar")
			monthValue="03"
			;;
		"Apr")
			monthValue="04"
			;;
		"May")
			monthValue="05"
			;;
		"Jun")
			monthValue="06"
			;;
		"Jul")
			monthValue="07"
			;;
		"Aug")
			monthValue="08"
			;;
		"Sep")
			monthValue="09"
			;;
		"Oct")
			monthValue="10"
			;;
		"Nov")
			monthValue="11"
			;;
		"Dec")
			monthValue="12"
			;;
		*)
		    continue
	esac
	local UTCTIME="$yearValue.$monthValue.$dateValue-$timeValue"
	local SERVER_TIMESTAMP=$(date +%s --utc ${UTCTIME})
	if [ -n "${debug}" ];then
		local ROUTER_TIME=$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})
		echo_date "实际时间：${ROUTER_TIME}，来源：${src}"
	else
		echo ${SERVER_TIMESTAMP}
	fi
}

compare_time(){
	local TIMESTAMP_SOURCE=$1
	local SERVER_TIMESTAMP=$2
	local ROUTER_TIMESTAMP=$(date +%s)
	if [ -z "${SERVER_TIMESTAMP}" ];then
		return 1
	fi
	local TIME_DIFF=$((${SERVER_TIMESTAMP} - ${ROUTER_TIMESTAMP}))
	local TIME_DIFF=${TIME_DIFF#-}
	echo_date "实际时间：$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})，来源：${TIMESTAMP_SOURCE}"
	echo_date "路由时间：$(date +'%Y-%m-%d %H:%M:%S' -d @${ROUTER_TIMESTAMP})，来源：$(get_model_name)"
	if [ "${TIME_DIFF}" -ge "60" ];then
		echo_date "*路由器时间和实际时间相差${TIME_DIFF}秒，重新设置路由器时间为：$(date +'%Y-%m-%d %H:%M:%S' -d @${SERVER_TIMESTAMP})！"
		date -s @${SERVER_TIMESTAMP} >/dev/null 2>&1
		echo_date "路由器时间更新成功！"
	elif [ "${TIME_DIFF}" -eq "0" ];then
		echo_date "路由器时间和实际时间相同，继续！"
	else
		echo_date "路由器时间和实际时间相差${TIME_DIFF}秒，在允许误差范围60秒内！"
	fi
}

test_xray_conf(){
	#uset _test_ret
	local conf=$1
	echo_date "测试xray配置文件..."
	local test_ret=$(run xray run -test -c=$conf 2>&1)
	local ret_1=$(echo "$test_ret" | grep "Configuration OK.")
	local ret_2=$(echo "$test_ret" | grep "does not support fingerprint")
	#local ret_2=$(echo $test_ret | grep "Old version of XTLS does not support fingerprint")
	if [ -n "${ret_1}" ]; then
		# test OK
		_test_ret=${ret_1}
		return 0
	elif [ -n "${ret_2}" ];then
		# fingerprint should be deleted
		_test_ret=${ret_2}
		return 2
	else
		# test faild
		_test_ret=${test_ret}
		return 1
	fi
}

check_time(){
	# 因为部分代理协议要求本地时间和服务器时间一致才能工作，所以检测下路由器时间是否设置正确
	# 时间检测优先从worldtimeapi.org获取，如果获取成功，能同时得到公网出口ipv4地址
	# 如果所有检测方式用光了还无法获取时间，说明可能是DNS无法获取到解析通造成的
	echo_date "检测路由器本地时间是否正确..."

	# debug use
	# get_time "www.weibo.com" debug
	# get_time "www.baidu.com" debug
	# get_time "www.qq.com" debug
	# get_time "www.taobao.com" debug
	# get_time "www.zhihu.com" debug
	# get_time "www.jd.com" debug
	# get_time "https://nist.time.gov/" debug
	
	local RET=$(curl -4sk --connect-timeout 2 --max-time 2 "http://worldtimeapi.org/api/timezone/Asia/Shanghai")
	if [ -n "${RET}" ];then
		if [ "${ss_basic_nochnipcheck}" != "1" ];then
			REMOTE_IP_OUT_SRC="worldtimeapi.org"
			REMOTE_IP_OUT=$(echo ${RET}|run jq -r '.client_ip')
		fi
		local TIMESTAMP_SOURCE="worldtimeapi.org"
		local SERVER_TIMESTAMP=$(echo ${RET}|run jq -r '.unixtime')
		if [ "${SERVER_TIMESTAMP}" == "null" ];then
			local SERVER_TIMESTAMP=""
		fi
		compare_time "worldtimeapi.org" ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.weibo.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.baidu.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.qq.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.taobao.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="www.jd.com"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		local TIMESTAMP_SOURCE="https://nist.time.gov/"
		local SERVER_TIMESTAMP=$(get_time ${TIMESTAMP_SOURCE})
		compare_time ${TIMESTAMP_SOURCE} ${SERVER_TIMESTAMP}
	fi

	if [ -z "${SERVER_TIMESTAMP}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+            经多种方法尝试，均无法从服务器获取当前实际时间!            +"
		echo_date "+                 这可能是路由器DNS不通造成的!                      +"
		echo_date "+                请尝试更正此问题后重新启动插件!                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
}

check_internet(){
	# 开启插件之前必须检查网络，如果网络不通，则插件不予开启
	# 考虑到本插件可能的国外环境用户，最后添加8.8.8.8的检测
	echo_date "科学上网插件开启前，需要进行网络连通性检测，请稍后..."
	if [ -z "${PING_RET}" ];then
		local PING_SRC="223.5.5.5"
		local PING_RET=$(ping -4 -c 1 -w 1 ${PING_SRC}|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING_RET}" ];then
		local PING_SRC="114.114.114.114"
		local PING_RET=$(ping -4 -c 1 -w 1 ${PING_SRC}|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING_RET}" ];then
		local PING_SRC="119.29.29.29"
		local PING_RET=$(ping -4 -c 1 -w 1 ${PING_SRC}|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING_RET}" ];then
		local PING_SRC="1.2.4.8"
		local PING_RET=$(ping -4 -c 1 -w 1 ${PING_SRC}|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -z "${PING_RET}" ];then
		local PING_SRC="8.8.8.8"
		local PING_RET=$(ping -4 -c 1 -w 1 ${PING_SRC}|tail -n1|awk -F '/' '{print $4}')
	fi
	if [ -n "${PING_RET}" ];then
		echo_date "检测到路由器可以正常访问公网，检测源：${PING_SRC}，延迟：${PING_RET}s，继续！"
	else
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+                 检测到路由器无法正常访问公网！                     +"
		echo_date "+                 请配置好你的路由器网络后重试！                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
}

check_chn_public_ip(){
	# 5.1 检测路由器公网出口IPV4地址
	if [ -z "${REMOTE_IP_OUT}" -o "${REMOTE_IP_OUT}" == "null" ];then
		REMOTE_IP_OUT=$(nvram get wan0_realip_ip)
		REMOTE_IP_OUT_SRC="nvram: wan0_realip_ip"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT=$(detect_ip ip.ddnsto.com 5 0)
		REMOTE_IP_OUT_SRC="ip.ddnsto.com"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT=$(detect_ip https://ip.clang.cn 5 0)
		#REMOTE_IP_OUT=$(curl -4sk --connect-timeout 2 https://ip.clang.cn 2>&1 | grep -v "Terminated" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
		REMOTE_IP_OUT_SRC="ip.clang.com"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT=$(detect_ip whatismyip.akamai.com 5 0)
		REMOTE_IP_OUT_SRC="whatismyip.akamai.com"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		REMOTE_IP_OUT=$(curl-fancyss -4sk --connect-timeout 2 http://api.myip.com 2>&1 | grep -v "Terminated" | run jq -r '.ip' | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
		REMOTE_IP_OUT_SRC="api.myip.com"
	fi

	if [ -z "${REMOTE_IP_OUT}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+            经多种方法尝试，均无法检测到本机国内出口IP!               +"
		echo_date "+                 这可能是路由器DNS不通造成的!                      +"
		echo_date "+                请尝试更正此问题后重新启动插件！                    +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi

	# 5.2 检测路由器WAN口IPV4地址
	echo_date "检测[公网出口IPV4地址]和[路由器WAN口IPV4地址]..."
	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(nvram get wan0_ipaddr)
		local ROUTER_IP_WAN_SRC="nvram get wan0_ipaddr"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ifconfig ppp0|sed -n '2p'|grep -Eo 'inet addr:([0-9]{1,3}[\.]){3}[0-9]{1,3}'|awk -F":" '{print $2}')
		local ROUTER_IP_WAN_SRC="ipconfig ppp0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ip addr show ppp0|grep -w inet|awk '{print $2}')|awk -F "/" '{print $1}'
		local ROUTER_IP_WAN_SRC="ip addr show ppp0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ifconfig eth0|sed -n '2p'|grep -Eo 'inet addr:([0-9]{1,3}[\.]){3}[0-9]{1,3}'|awk -F":" '{print $2}')
		local ROUTER_IP_WAN_SRC="ipconfig eth0"
	fi

	if [ -z "${ROUTER_IP_WAN}" ];then
		local ROUTER_IP_WAN=$(ip addr show eth0|grep -w inet|awk '{print $2}')|awk -F "/" '{print $1}'
		local ROUTER_IP_WAN_SRC="ip addr show eth0"
	fi
	
	if [ -z "${ROUTER_IP_WAN}" ];then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+             经多种方法尝试，均无法检测到本机WAN口IP!                +"
		echo_date "+                请尝试更正此问题后重新启动插件!                     +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five flag
	fi
	
	# 5.3 判断
	local ISCHN_OUT=$(awk -F'[./]' -v ip=${REMOTE_IP_OUT} ' {for (i=1;i<=int($NF/8);i++){a=a$i"."} if (index(ip, a)==1){split( ip, A, ".");b=int($NF/8);if (A[b+1]<($(NF+b-4)+2^(8-$NF%8))&&A[b+1]>=$(NF+b-4)) print ip,"belongs to",$0} a=""}' /koolshare/ss/rules/chnroute.txt)
	if [ -n "${ISCHN_OUT}" ];then
		# 大陆地址
		echo_date "公网出口IPV4地址：${REMOTE_IP_OUT}，属地：大陆，来源：${REMOTE_IP_OUT_SRC}"
	else
		# 海外地址
		# 为日志输出标准，此处属地海外表示的是：中国外且包含港澳台地址，后同，并没有任何分裂国家的表达意思。
		echo_date "公网出口IPV4地址：${REMOTE_IP_OUT}，属地：海外，来源：${REMOTE_IP_OUT_SRC}"
	fi

	if [ "${ROUTER_IP_WAN}" == "${REMOTE_IP_OUT}" ];then
		if [ -z "${ISCHN_OUT}" ];then
			echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址相同，为海外公网IPV4地址！"
			if [ "${ss_basic_mode}" != "6" ];then
				echo_date "检测到路由器公网出口IPV4地址为海外地址，可能是以下情况："
				echo_date "-------------------------------"
				echo_date "1. 检测到路由器使用环境在海外，如果确实是这种情况，建议使用回国代理 + 回国模式"
				echo_date "2. 可能你身在大陆，但是chnroute.txt没有收录你的公网出口IPV4地址，你可以自行将该IPV4地址加入到IP/CIDR黑名单"
				echo_date "-------------------------------"
			fi
		else
			echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址相同，为大陆公网IPV4地址！"
		fi
	else
		echo_date "路由WAN IPV4地址：${ROUTER_IP_WAN}，和公网出口地址不同，为私网（局域网）IPV4地址"
		if [ -z "${ISCHN_OUT}" ];then
			if [ "${ss_basic_mode}" != "6" ];then
				echo_date "检测到路由器公网出口IPV4地址为海外地址，可能是以下情况："
				echo_date "-------------------------------"
				echo_date "1. 可能你身在大陆，但是你的网络经过了多层代理，请检查是否有上游路由器开启了代理，特别是全局代理"
				echo_date "2. 可能你身在海外，如果是这种情况，建议使用回国代理 + 回国模式"
				echo_date "3. 可能你身在大陆，但是chnroute.txt没有收录你的公网出口IPV4地址，你可以自行将该IPV4地址加入到IP/CIDR黑名单"
				echo_date "-------------------------------"
			fi
		fi
	fi
}

prepare_system() {
	# prepare system
	
	# 0. set skin, 不管是否能启动成功，都检测下皮肤是否正确，如果不对，则设置下皮肤
	set_skin
	
	# 1. 检测是否是路由模式，科学上网插件工作方式为透明代理 + NAT（iptables），而非路由模式是没有NAT的，所以无法工作！
	local ROUTER_MODE=$(nvram get sw_mode)
	if [ "$(nvram get sw_mode)" != "1" ]; then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+          无法启用插件，因为当前路由器工作在非无线路由器模式下          +"
		echo_date "+     科学上网插件工作方式为透明代理，需要在NAT下，即路由模式下才能工作    +"
		echo_date "+            请前往【系统管理】- 【系统设置】去切换路由模式！           +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five
	fi
	
	# 2. 检测jffs2_script是否开启，如果没有开启，将会影响插件的自启和DNS部分（dnsmasq.postconf）
	# 判断为非官改固件的，即merlin固件，需要开启jffs2_scripts，官改固件不需要开启
	if [ -z "$(nvram get extendno | grep koolshare)" ]; then
		if [ "$(nvram get jffs2_scripts)" != "1" ]; then
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+     发现你未开启Enable JFFS custom scripts and configs选项！     +"
			echo_date "+    【软件中心】和【科学上网】插件都需要此项开启才能正常使用！！         +"
			echo_date "+     请前往【系统管理】- 【系统设置】去开启，并重启路由器后重试！！      +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			close_in_five
		fi
	fi

	# 3. internet detect
	if [ "${ss_basic_nonetcheck}" != "1" ];then
		check_internet
	#else
		#echo_date "跳过路由器网络连通性检测..."
	fi

	# 4. 检测路由器时间是否正确
	if [ "${ss_basic_notimecheck}" != "1" ];then
		check_time
	#else
		#echo_date "跳过路由器本地时间检测..."
	fi

	# 检测路由器公网出口IPV4地址
	if [ "${ss_basic_nochnipcheck}" != "1" ];then
		check_chn_public_ip
	#else
		#echo_date "跳过国内公网出口ip检测..."
	fi
	# 6. set_ulimit
	ulimit -n 16384

	# 7. clean mem
	echo 1 >/proc/sys/vm/overcommit_memory

	# 8. more entropy
	# use command `cat /proc/sys/kernel/random/entropy_avail` to check current entropy
	# few scenario should be noticed below:
	# 1. from merlin fw 386.2, jitterentropy-rngd has been intergrated into fw, so haveged form fancyss should not be used
	# 2. from merlin fw 386.4, jitterentropy-rngd was replaced by haveged, so havege form fancyss should not be used
	# 3. newer asus fw or asus_ks_mod fw like GT-AX6000 use jitterentropy-rngd, so havege form fancyss should not be used
	# 4. older merlin or asus_ks_mod fw do not have jitterentropy-rngd or haveged, so havege form fancyss should be used
	if [ -z "$(pidof jitterentropy-rngd)" -a -z "$(pidof haveged)" -a -f "/koolshare/bin/haveged" ];then
		# run haveged form fancyss when there are not entropy software running
		echo_date "启动haveged，为系统提供更多的可用熵！"
		run /koolshare/bin/haveged -w 1024 >/dev/null 2>&1
	fi

	# 9. 用户自定义的dns不需要
	if [ -n "$(nvram get dhcp_dns1_x)" ]; then
		nvram unset dhcp_dns1_x
		nvram commit
	fi
	if [ -n "$(nvram get dhcp_dns2_x)" ]; then
		nvram unset dhcp_dns2_x
		nvram commit
	fi

	# 10. set vcore (v2ray_core) name
	XRAY_CONFIG_TEMP="/tmp/xray_tmp.json"
	XRAY_CONFIG_FILE="/koolshare/ss/xray.json"
	if [ "${ss_basic_vcore}" == "1" ];then
		VCORE_NAME=Xray
		V2RAY_CONFIG_TEMP="/tmp/xray_tmp.json"
		V2RAY_CONFIG_FILE="/koolshare/ss/xray.json"
	else
		VCORE_NAME=V2ray
		V2RAY_CONFIG_TEMP="/tmp/v2ray_tmp.json"
		V2RAY_CONFIG_FILE="/koolshare/ss/v2ray.json"
	fi

	# 11. set tcore (trojan core) name
	if [ "${ss_basic_tcore}" == "1" ];then
		TCORE_NAME=Xray
		TROJAN_CONFIG_TEMP="/tmp/xray_tmp.json"
		TROJAN_CONFIG_FILE="/koolshare/ss/xray.json"
	else
		TCORE_NAME=trojan
		TROJAN_CONFIG_TEMP="/tmp/trojan_nat_tmp.json"
		TROJAN_CONFIG_FILE="/koolshare/ss/trojan.json"
	fi

	# 12. info
	if [ "${ss_basic_type}" == "3" ];then
		if [ "${ss_basic_vcore}" == "1" ];then
			echo_date "ℹ️使用Xray-core替换V2ray-core..."
		else
			echo_date "ℹ️使用V2ray-core..."
		fi
	fi

	if [ "${ss_basic_type}" == "5" ];then
		if [ "${ss_basic_tcore}" == "1" ];then
			echo_date "ℹ️使用Xray-core运行trojan协议节点..."
		else
			echo_date "ℹ️使用trojan二进制运行trojan协议节点..."
		fi
	fi

	if [ "${ss_basic_type}" == "6" -a "${ss_basic_mode}" == "3" ];then
		echo_date "NaïveProxy不支持udp代理，因此不支持游戏模式，自动切换为大陆白名单模式！"
		ss_basic_mode="2"
		ss_acl_default_mode="2"
		dbus set ssconf_basic_mode_${ssconf_basic_node}="2"
	fi

	if [ "${ss_basic_type}" == "5" -a "${ss_basic_tcore}" != "1" -a "${ss_basic_advdns}" = "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "1" ]; then
		echo_date "[可信DNS-1]: Trojan核心不支持udp代理，将可信DNS-1自动切换为tcp协议！"
		ss_basic_chng_trust_1_opt=2
		dbus set ss_basic_chng_trust_1_opt=2
	fi

	if [ "${ss_basic_type}" == "6" -a "${ss_basic_advdns}" = "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "1" ]; then
		echo_date "[可信DNS-1]: NaïveProxy不支持udp代理，将可信DNS-1自动切换为tcp协议！"
		ss_basic_chng_trust_1_opt=2
		dbus set ss_basic_chng_trust_1_opt=2
	fi
}

donwload_binary(){
	# 二进制下载应该在fancyss关闭/重启前运行，这样可以利用代理进行下载
	if [ "${ss_basic_type}" == "0" -a "${ss_basic_rust}" == "1" -a "${ACTION}" == "restart" ]; then
		if [ ! -x "/koolshare/bin/sslocal" ];then
			echo_date "没有检测到shadowsocks-rust二进制文件:sslocal，准备下载..."
			run sh /koolshare/scripts/ss_rust_update.sh download
		fi
	fi
}

get_lan_cidr() {
	local netmask=$(nvram get lan_netmask)
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(((${#netmask} - ${#x}) * 2)) ${x%%.*}
	x=${1%%$3*}
	suffix=$(($2 + (${#x} / 4)))
	#prefix=`nvram get lan_ipaddr | cut -d "." -f1,2,3`
	echo $lan_ipaddr/$suffix
}

get_wan0_cidr() {
	local netmask=$(nvram get wan0_netmask)
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(((${#netmask} - ${#x}) * 2)) ${x%%.*}
	x=${1%%$3*}
	suffix=$(($2 + (${#x} / 4)))
	prefix=$(nvram get wan0_ipaddr)
	if [ -n "$prefix" -a -n "$netmask" ]; then
		echo $prefix/$suffix
	else
		echo ""
	fi
}

close_in_five() {
	# 5秒关闭功能是为了让用户注意到关闭过程，从而及时得知错误信息
	# 插件在运行过程中不能使用此功能，不然插件被关闭了，无法进行故障转移功能
	# 在某些条件无法达成时使用5s关闭功能，比如系统配置为中继模式，jffs2_scripts未开启
	# 节点挂掉等其它情况，不建议使用，不然影响故障转移功能
	local flag=$1
	echo_date "插件将在5秒后自动关闭！！"
	local i=5
	while [ $i -ge 0 ]; do
		sleep 1
		echo_date $i
		let i--
	done
	if [ -z "${flag}" ];then
		# 彻底关闭插件
		dbus set ss_basic_enable="0"
		ss_basic_status=1
		disable_ss >/dev/null
		echo_date "科学上网插件已完全关闭！！"
	else
		# 关闭插件，但是开关保留开启，状态检测保持开启
		ss_basic_status=1
		disable_ss ${flag} >/dev/null
		# set ss_basic_wait=1，because ss_status.sh need to show something else
		dbus set ss_basic_wait=1
		# set ss_basic_status=1，because some scripts still running in background
		dbus set ss_basic_status=1
		if [ "$ss_failover_enable" == "1" ]; then
			echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssf_status.txt
			echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssc_status.txt
			run start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status_main.sh
		fi
		echo_date "科学上网插件已关闭！！"
	fi
	echo_date "======================= 梅林固件 - 【科学上网】 ========================"
	unset_lock
	exit
}

__get_type_full_name() {
	case "$1" in
	0)
		if [ "${ss_basic_rust}" == "1" ];then
			echo "shadowsocks-rust"
		else
			echo "shadowsocks-libev"
		fi
		;;
	1)
		echo "shadowsocksR-libev"
		;;
	3)
		echo "${VCORE_NAME}"
		;;
	4)
		echo "Xray"
		;;
	5)
		echo "Trojan"
		;;
	6)
		echo "NaïvePoroxy"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
		;;
	esac
}

__get_type_abbr_name() {
	case "${ss_basic_type}" in
	0)
		if [ "${ss_basic_rust}" == "1" ];then
			echo "ss-rust"
		else
			echo "ss"
		fi
		;;
	1)
		echo "ssr"
		;;
	3)
		echo "${VCORE_NAME}"
		;;
	4)
		echo "Xray"
		;;
	5)
		echo "Trojan"
		;;
	6)
		echo "Naïve"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
		;;
	esac
}

__get_server_resolver() {
	local idx=$1
	local res
		# tcp/udp servers
		# ------------------ 国内 -------------------
		# 阿里dns
		[ "${idx}" == "1" ] && res="223.5.5.5"
		# DNSPod dns
		[ "${idx}" == "2" ] && res="119.29.29.29"
		# 114 dns
		[ "${idx}" == "3" ] && res="114.114.114.114"
		# oneDNS 拦截版
		[ "${idx}" == "4" ] && res="52.80.66.66"
		# 360安全DNS 电信/铁通/移动
		[ "${idx}" == "5" ] && res="218.30.118.6"
		# 360安全DNS 联通
		[ "${idx}" == "6" ] && res="123.125.81.6"
		# 清华大学TUNA DNS
		[ "${idx}" == "7" ] && res="101.6.6.6"
		# 百度DNS
		[ "${idx}" == "8" ] && res="180.76.76.76"
		# ------------------ 国外 -------------------
		# Google DNS
		[ "${idx}" == "11" ] && res="8.8.8.8"
		# Cloudflare DNS
		[ "${idx}" == "12" ] && res="1.1.1.1"
		# Quad9 Secured 
		[ "${idx}" == "13" ] && res="9.9.9.11"
		# OpenDNS
		[ "${idx}" == "14" ] && res="208.67.222.222"
		# DNS.SB
		[ "${idx}" == "15" ] && res="185.222.222.222"
		# AdGuard Default servers
		[ "${idx}" == "16" ] && res="94.140.14.14"
		# Quad 101 (TaiWan Province)
		[ "${idx}" == "17" ] && res="101.101.101.101"
		# CleanBrowsing
		[ "${idx}" == "18" ] && res="185.228.168.9"

	if [ "${idx}" == "99" ]; then
		local user_content=${ss_basic_server_resolv_user}
		if [ -n "${user_content}" ];then
			local res_ip=$(echo "${user_content}"|awk -F"#|:" '{print $1}')
			local res_ip=$(__valid_ip ${res_ip})
			if [ -n "${res_ip}" ];then
				res="${res_ip}"
			else
				res="114.114.114.114"
			fi
		else
			res="114.114.114.114"
		fi
	fi
	echo ${res}
}

__get_server_resolver_port() {
	local idx=$1
	local res
	if [ "${idx}" == "99" ]; then
		local user_content=${ss_basic_server_resolv_user}
		if [ -n "${user_content}" ];then
			local res_port=$(echo "${user_content}"|awk -F"#|:" '{print $2}')
			local res_port=$(__valid_port ${res_port})
			if [ -n "${res_port}" ];then
				res="${res_port}"
			else
				res="53"
			fi
		else
			res="53"
		fi
	elif [ "${idx}" == "7" -o "${idx}" == "14" ]; then
		res="5353"
	else
		res="53"
	fi
	echo ${res}
}

__resolve_server_domain() {
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		# not ip, not domain
		return 2
	fi

	if [ -z "${ss_basic_server_resolv}" ];then
		ss_basic_server_resolv="-1"
		dbus set ss_basic_server_resolv="-1"
	fi

	# start to resolv, udp dns lookup
	if [ "${ss_basic_server_resolv}" -le "0" ];then
		local count=0
		local current=${ss_basic_lastru}
		if [ $(number_test ${current}) != "0" ];then
			# 如果上次解析成功的DNS不存在，则随机一个
			if [ "${ss_basic_server_resolv}" == "0" ];then
				local current=$(shuf -i 1-18 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				local current=$(shuf -i 1-8 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				local current=$(shuf -i 11-18 -n 1)
			fi
		fi
		# check current value
		if [ "${ss_basic_server_resolv}" == "0" ];then
			# 国内 + 国外自动选择，区间为 1-7和11-18
			if [ ${current} -gt 8 -a ${current} -lt 11 ];then
				current=11
			fi
			if [ ${current} -lt 1 -o ${current} -gt 18 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-1" ];then
			# 国内自动选择，区间为 1-7
			if [ ${current} -lt 1 -o ${current} -gt 8 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-2" ];then
			# 国外自动选择，区间为 11-18
			if [ ${current} -lt 11 -o ${current} -gt 18 ];then
				current=11
			fi
		fi
		# 只解析一轮
		until [ ${count} -eq 18 ]; do
			echo_date "尝试解析$(__get_type_abbr_name)服务器域名，自动选取DNS-${current}：$(__get_server_resolver ${current}):$(__get_server_resolver_port ${current})"
			SERVER_IP=$(run dnsclient -p $(__get_server_resolver_port ${current}) -t 2 -i 1 @$(__get_server_resolver ${current}) $1 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
			SERVER_IP=$(__valid_ip ${SERVER_IP})
			if [ -n "${SERVER_IP}" -a "${SERVER_IP}" != "127.0.0.1" ]; then
				dbus set ss_basic_lastru=${current}
				break
			fi
			
			let current++
			if [ "${ss_basic_server_resolv}" == "0" ];then
				if [ ${current} -gt 8 -a ${current} -lt 11 ];then
					echo_date "解析失败！自动切换到国外组列表第一个DNS服务器！"
					current=11
				fi
				if [ ${current} -lt 1 -o ${current} -gt 18 ];then
					current=1
					echo_date "解析失败！自动切换到国内组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到下一个DNS服务器！"
				fi
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				if [ ${current} -lt 1 -o ${current} -gt 8 ];then
					current=1
					echo_date "解析失败！自动切换到国内组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到国内组列表下一个DNS服务器！"
				fi
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				if [ ${current} -lt 11 -o ${current} -gt 18 ];then
					current=11
					echo_date "解析失败！自动切换到国外组列表第一个DNS服务器！"
				else
					echo_date "解析失败！自动切换到国外组列表下一个DNS服务器！"
				fi
			fi
			
			let count++
		done
	elif [ "${ss_basic_server_resolv}" == "99" ];then
		# 自定义udp解析服务器
		echo_date "尝试解析$(__get_type_abbr_name)服务器域名，使用自定义DNS服务器：$(__get_server_resolver ${ss_basic_server_resolv}):$(__get_server_resolver_port ${ss_basic_server_resolv})"
		SERVER_IP=$(run dnsclient -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
		SERVER_IP=$(__valid_ip ${SERVER_IP})
		if [ -z "${SERVER_IP}" -o "${SERVER_IP}" == "127.0.0.1" ]; then
			echo_date "解析失败！请选择其它DNS服务器 或 其它节点域名解析方案！"
		fi
	else
		# 指定udp解析服务器
		if [ -z "${ss_basic_server_resolv}" ];then
			ss_basic_server_resolv=3
		fi
		if [ "${ss_basic_server_resolv}" == "2" -a -z "${ISP_DNS2}" ];then
			# 如果ISPDNS-2不存在，强制使用ISPDNS-1
			ss_basic_server_resolv=1
		fi
		if [ "${ss_basic_server_resolv}" == "1" -a -z "${ISP_DNS1}" ];then
			# 如果ISPDNS-1不存在，强制使用公共DNS：223.5.5.5
			ss_basic_server_resolv=3
		fi
		echo_date "尝试解析$(__get_type_abbr_name)服务器域名，使用指定DNS-${ss_basic_server_resolv}：$(__get_server_resolver ${ss_basic_server_resolv}):$(__get_server_resolver_port ${ss_basic_server_resolv})"
		SERVER_IP=$(run dnsclient -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
		SERVER_IP=$(__valid_ip ${SERVER_IP})
		if [ -z "${SERVER_IP}" -o "${SERVER_IP}" == "127.0.0.1" ]; then
			echo_date "解析失败！请选择其它DNS服务器 或 其它节点域名解析方案！"
		fi
	fi

	# resolve failed
	if [ -z "${SERVER_IP}" ]; then
		return 1
	fi

	# resolve failed
	if [ "${SERVER_IP}" == "127.0.0.1" ]; then
		return 1
	fi
	
	# success resolved
	return 0
}

# ================================= ss stop ===============================
remove_file(){
	local rfile=$1
	local count=$2
	if [ -f ${rfile} -o -L ${rfile} ];then
		#echo_date "移除：${rfile}"
		rm -rf $1
		count=$((${count} + 1))
	fi
	return ${count}
}

restore_conf() {
	rm -rf /koolshare/perp/doh_chn1
	rm -rf /koolshare/perp/doh_chn2
	rm -rf /koolshare/perp/doh_frn1
	rm -rf /koolshare/perp/doh_frn2
	rm -rf /koolshare/perp/doh_main
	remove_file /jffs/configs/dnsmasq.d/gfwlist.conf 0
	remove_file /jffs/configs/dnsmasq.d/cdn.conf $?
	remove_file /jffs/configs/dnsmasq.d/gfwlist.conf $?
	remove_file /jffs/configs/dnsmasq.d/custom.conf $?
	remove_file /jffs/configs/dnsmasq.d/wblist.conf $?
	remove_file /jffs/configs/dnsmasq.d
	remove_file /jffs/configs/dnsmasq.d/ss_host.conf $?
	remove_file /jffs/configs/dnsmasq.d/ss_server.conf $?
	remove_file /jffs/configs/dnsmasq.d/ss_domain.conf
	remove_file /jffs/configs/dnsmasq.conf.add $?
	remove_file /jffs/scripts/dnsmasq.postconf $?
	remove_file /tmp/custom.conf $?
	remove_file /tmp/wblist.conf $?
	remove_file /tmp/ss_host.conf $?
	remove_file /tmp/smartdns.conf $?
	remove_file /tmp/smartdns.log $?
	remove_file /tmp/gfwlist.txt $?
	remove_file /tmp/gfwlist.conf $?
	remove_file /tmp/cdn.txt $?
	remove_file /tmp/cdn.conf $?
	remove_file /tmp/upload/smartdns_chng_direct.conf $?
	remove_file /tmp/upload/smartdns_chng_proxy_5.conf $?
	remove_file /tmp/upload/smartdns_chng_proxy_6.conf $?
	remove_file /tmp/upload/smartdns_chng_proxy_7.conf $?
	remove_file /tmp/upload/smartdns_chng_proxy_8.conf $?
	remove_file /tmp/upload/smartdns_chng_china_doh.conf $?
	remove_file /tmp/upload/smartdns_chng_china_udp.conf $?
	remove_file /tmp/upload/smartdns_smrt_1.conf $?
	remove_file /tmp/upload/smartdns_smrt_2.conf $?
	remove_file /tmp/upload/smartdns_smrt_3.conf $?
	remove_file /tmp/upload/smartdns_smrt_4.conf $?
	remove_file /tmp/upload/smartdns_smrt_5.conf $?
	remove_file /tmp/upload/smartdns_smrt_6.conf $?
	remove_file /tmp/upload/smartdns_smrt_7.conf $?
	remove_file /tmp/upload/smartdns_smrt_8.conf $?
	remove_file /tmp/upload/smartdns_smrt_9.conf $?
	remove_file /tmp/doh_main.conf $?
	remove_file /tmp/doh_frn1.conf $?
	remove_file /tmp/doh_frn2.conf $?
	if [ "$?" != "0" ];then
		echo_date "删除fancyss相关的名单配置文件..."
	fi
}

kill_process() {
	local v2ray_process=$(pidof v2ray)
	if [ -n "$v2ray_process" ]; then
		echo_date "关闭V2Ray进程..."
		# 有时候killall杀不了v2ray进程，所以用不同方式杀两次
		killall v2ray >/dev/null 2>&1
		kill -9 "$v2ray_process" >/dev/null 2>&1
	fi

	local xray_process=$(pidof xray)
	if [ -n "$xray_process" ]; then
		echo_date "关闭xray进程..."
		killall xray >/dev/null 2>&1
		kill -9 "$xray_process" >/dev/null 2>&1
	fi
	if [ -d "/koolshare/perp/xray" ];then
		perpctl d xray >/dev/null 2>&1
		rm -rf /koolshare/perp/xray
	fi

	local trojan_process=$(pidof trojan)
	if [ -n "$trojan_process" ]; then
		echo_date "关闭trojan进程..."
		killall trojan >/dev/null 2>&1
	fi

	local ssredir=$(pidof ss-redir)
	if [ -n "$ssredir" ]; then
		echo_date "关闭ss-redir进程..."
		killall ss-redir >/dev/null 2>&1
	fi

	local rssredir=$(pidof rss-redir)
	if [ -n "$rssredir" ]; then
		echo_date "关闭ssr-redir进程..."
		killall rss-redir >/dev/null 2>&1
	fi

	local sslocal=$(ps | grep -w ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}')
	if [ -n "$sslocal" ]; then
		echo_date "关闭ss-local进程:23456端口..."
		kill $sslocal >/dev/null 2>&1
	fi

	local ssrlocal=$(ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}')
	if [ -n "$ssrlocal" ]; then
		echo_date "关闭ssr-local进程:23456端口..."
		kill $ssrlocal >/dev/null 2>&1
	fi

	local ssrustlocal=$(pidof sslocal)
	if [ -n "$ssrustlocal" ]; then
		echo_date "关闭sslocal进程..."
		kill $ssrustlocal >/dev/null 2>&1
	fi

	local sstunnel=$(pidof ss-tunnel)
	if [ -n "$sstunnel" ]; then
		echo_date "关闭进程..."
		killall ss-tunnel >/dev/null 2>&1
	fi

	local rsstunnel=$(pidof rss-tunnel)
	if [ -n "$rsstunnel" ]; then
		echo_date "关闭rss-tunnel进程..."
		killall rss-tunnel >/dev/null 2>&1
	fi

	local chinadnsNG_process=$(pidof chinadns-ng)
	if [ -n "$chinadnsNG_process" ]; then
		echo_date "关闭chinadns-ng进程..."
		killall chinadns-ng >/dev/null 2>&1
	fi

	local dns2socks_process=$(pidof dns2socks)
	if [ -n "$dns2socks_process" ]; then
		echo_date "关闭dns2socks进程..."
		killall dns2socks >/dev/null 2>&1
	fi

	local smartdns_process=$(pidof smartdns)
	if [ -n "$smartdns_process" ]; then
		echo_date "关闭smartdns进程..."
		killall smartdns >/dev/null 2>&1
	fi

	local kcptun_process=$(pidof kcptun)
	if [ -n "$kcptun_process" ]; then
		echo_date "关闭kcp协议进程..."
		killall kcptun >/dev/null 2>&1
	fi

	local haproxy_process=$(pidof haproxy)
	if [ -n "$haproxy_process" ]; then
		echo_date "关闭haproxy进程..."
		killall haproxy >/dev/null 2>&1
	fi

	local speederv1_process=$(pidof speederv1)
	if [ -n "$speederv1_process" ]; then
		echo_date "关闭speederv1进程..."
		killall speederv1 >/dev/null 2>&1
	fi

	local speederv2_process=$(pidof speederv2)
	if [ -n "$speederv2_process" ]; then
		echo_date "关闭speederv2进程..."
		killall speederv2 >/dev/null 2>&1
	fi

	local ud2raw_process=$(pidof udp2raw)
	if [ -n "$ud2raw_process" ]; then
		echo_date "关闭ud2raw进程..."
		killall udp2raw >/dev/null 2>&1
	fi

	local doh_pid_chn1=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_chn1" | awk '{print $1}')
	if [ -n "${doh_pid_chn1}" ]; then
		echo_date "关闭工作在chinadns-ng国内-1上游的dohclient进程..."
		[ -f "/koolshare/perp/doh_chn1/rc.main" ] && perpctl d doh_chn1 >/dev/null 2>&1
		rm -rf /koolshare/perp/doh_chn1
		kill -9 ${doh_pid_chn1} >/dev/null 2>&1
		rm -rf /tmp/doh_chn1.conf
		rm -rf /tmp/doh_chn1.db
		rm -rf /tmp/doh_chn1.log
		rm -rf /var/run/doh_chn1.pid
	fi

	local doh_pid_chn2=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_chn2" | awk '{print $1}')
	if [ -n "${doh_pid_chn2}" ]; then
		echo_date "关闭工作在chinadns-ng国内-2上游的dohclient进程..."
		[ -f "/koolshare/perp/doh_chn2/rc.main" ] && perpctl d doh_chn2 >/dev/null 2>&1
		rm -rf /koolshare/perp/doh_chn2
		kill -9 ${doh_pid_chn2} >/dev/null 2>&1
		rm -rf /tmp/doh_chn2.conf
		rm -rf /tmp/doh_chn2.db
		rm -rf /tmp/doh_chn2.log
		rm -rf /var/run/doh_chn2.pid
	fi

	local doh_pid_frn1=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_frn1" | awk '{print $1}')
	if [ -n "${doh_pid_frn1}" ]; then
		echo_date "关闭工作在chinadns-ng国外-1上游的dohclient进程..."
		[ -f "/koolshare/perp/doh_frn1/rc.main" ] && perpctl d doh_frn1 >/dev/null 2>&1
		rm -rf /koolshare/perp/doh_frn1
		kill -9 ${doh_pid_frn1} >/dev/null 2>&1
		rm -rf /tmp/doh_frn1.conf
		rm -rf /tmp/doh_frn1.db
		rm -rf /tmp/doh_frn1.log
	fi

	local doh_pid_frn2=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_frn2" | awk '{print $1}')
	if [ -n "${doh_pid_frn2}" ]; then
		echo_date "关闭工作在chinadns-ng国外-2上游的dohclient进程..."
		[ -f "/koolshare/perp/doh_frn2/rc.main" ] && perpctl d doh_frn2 >/dev/null 2>&1
		rm -rf /koolshare/perp/doh_frn2
		kill -9 ${doh_pid_frn2} >/dev/null 2>&1
		rm -rf /tmp/doh_frn2.conf
		rm -rf /tmp/doh_frn2.db
		rm -rf /tmp/doh_frn2.log
	fi
	local doh_pid_main=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "7913|doh_main" | awk '{print $1}')
	if [ -n "${doh_pid_main}" ]; then
		echo_date "关闭用于国内+国外域名解析的dohclient进程..."
		if [ "${ss_basic_dohc_cache_reuse}" == "1" ];then
			echo_date "检测到持久化缓存开启，关闭dohclient前写入DNS缓存..."
			# 保存缓存
			local ret=$(dohclient-cache -s 127.0.0.1:7913 save /tmp/doh_main_backup.db 2>/dev/null)
			if [ $? == 0 -a -n "${ret}" ];then
				local error=$(echo ${ret} | run jq '.error')
				local data=$(echo ${ret} | run jq '.data')
				if [ "${error}" == "0" -a -n "${data}" ];then
					echo_date "DNS缓存写入成功：总计写入了${data}条DNS缓存到：/tmp/doh_main_backup.db！"
				else
					echo_date "DNS缓存写入失败！删除缓存文件，以便下次重建！"
					rm -f /tmp/doh_main_backup.db
				fi
			else
				echo_date "DNS缓存写入失败！删除缓存文件，以便下次重建！"
				rm -f /tmp/doh_main_backup.db
			fi
		fi
		# 关闭dohclient
		[ -f "/koolshare/perp/doh_main/rc.main" ] && perpctl d doh_main >/dev/null 2>&1
		rm -rf /koolshare/perp/doh_main
		kill -9 ${doh_pid_main} >/dev/null 2>&1
		rm -f /tmp/doh_main.conf >/dev/null 2>&1
		rm -rf /tmp/doh_main.log >/dev/null 2>&1
		rm -rf /var/run/doh_main.pid >/dev/null 2>&1
		echo_date "删除dohclient的DNS缓存文件/tmp/doh_main.db"
		rm -f /tmp/doh_main.db
		sync
	fi
		
	# only close haveged form fancyss, not haveged from system
	local haveged_pid=$(ps |grep "/koolshare/bin/haveged"|grep -v grep|awk '{print $1}')
	if [ -n "${haveged_pid}" ]; then
		echo_date "关闭haveged进程..."
		killall -9 ${haveged_pid} >/dev/null 2>&1
	fi
		
	# dns2tcp
	local dns2tcp_pid=$(ps | grep "dns2tcp" | grep -v grep | awk '{print $1}')
	if [ -n "${dns2tcp_pid}" ]; then
		echo_date "关闭dns2tcp进程..."
		killall dns2tcp >/dev/null 2>&1
	fi
		
	# def
	local def_pid=$(ps |grep "dns-ecs-forcer"| grep -v grep | awk '{print $1}')
	if [ -n "${def_pid}" ]; then
		echo_date "关闭dns-ecs-forcer进程..."
		killall dns-ecs-forcer >/dev/null 2>&1
	fi

	local SOCAT_PID=$(ps | grep -E "socat" | grep -E "2055|2056" | awk '{print $1}')
	if [ -n "${SOCAT_PID}" ];then
		echo_date "关闭socat进程..."
		kill -9 ${SOCAT_PID}
	fi
	
	local UREDIR_PID=$(ps | grep "uredir" | grep -v grep | awk '{print $1}')
	if [ -n "${UREDIR_PID}" ];then
		echo_date "关闭uredir进程..."
		killall uredir
	fi

	local IPT2SOCKS_PID=$(ps | grep "ipt2socks" | grep -v grep | awk '{print $1}')
	if [ -n "${IPT2SOCKS_PID}" ];then
		echo_date "关闭ipt2socks进程..."
		killall ipt2socks
	fi	

	local NAIVE_PID=$(ps | grep "naive" | grep -v grep | awk '{print $1}')
	if [ -n "${NAIVE_PID}" ];then
		echo_date "关闭naive进程..."
		killall naive
	fi

	local TUIC_PID=$(ps | grep "tuic-client" | grep -v grep | awk '{print $1}')
	if [ -n "${TUIC_PID}" ];then
		echo_date "关闭tuic-client进程..."
		killall tuic-client
	fi

	local HY2_PID=$(ps | grep "hysteria2" | grep -v grep | awk '{print $1}')
	if [ -n "${HY2_PID}" ];then
		echo_date "关闭hysteria2进程..."
		killall hysteria2
	fi
	# close tcp_fastopen
	if [ "${LINUX_VER}" != "26" ]; then
		echo 1 >/proc/sys/net/ipv4/tcp_fastopen
	fi
}

# ================================= ss prestart ===========================
ss_pre_start() {
	local IS_LOCAL_ADDR=$(echo "${ss_basic_server}" | grep -o "127.0.0.1" 2>/dev/null)
	if [ "$ss_lb_enable" == "1" ]; then
		echo_date ---------------------- 【科学上网】 启动前触发脚本 ----------------------
		if [ -n "${IS_LOCAL_ADDR}" -a "${ss_basic_port}" == "${ss_lb_port}" ]; then
			echo_date "插件启动前触发:触发启动负载均衡功能！"
			#start haproxy
			sh /koolshare/scripts/ss_lb_config.sh
		#else
			#echo_date 插件启动前触发:未选择负载均衡节点，不触发负载均衡启动！
		fi
	else
		if [ -n "${IS_LOCAL_ADDR}" -a "${ss_basic_port}" == "${ss_lb_port}" ]; then
			echo_date "插件启动前触发【警告】：你选择了负载均衡节点，但是负载均衡开关未启用！！"
		#else
			#echo_date ss启动前触发：你选择了普通节点，不触发负载均衡启动！
		fi
	fi
}
# ================================= ss start ==============================

resolv_server_ip() {
	local tmp server_ip
	if [ "${ss_basic_type}" == "3" -a "${ss_basic_v2ray_use_json}" == "1" ]; then
		#v2ray json配置在后面单独处理
		return 1
	elif [ "${ss_basic_type}" == "4" -a "${ss_basic_xray_use_json}" == "1" ]; then
		#xray json配置在后面单独处理
		return 1
	elif [ "${ss_basic_type}" == "7" ]; then
		#tuic节点，不需要解析
		return 1
	else
		# 判断服务器域名格式
		tmp=$(__valid_ip "${ss_basic_server}")
		if [ $? == 0 ]; then
			# server is ip address format, not need to resolve.
			echo_date "检测到你的$(__get_type_abbr_name)服务器已经是IP格式：${ss_basic_server}，跳过解析... "
			ss_basic_server_ip="${ss_basic_server}"
			dbus set ss_basic_server_ip=${ss_basic_server}
		else
			echo_date "检测到你的$(__get_type_abbr_name)服务器：【${ss_basic_server}】不是ip格式！"
			__resolve_server_domain "${ss_basic_server}"
			case $? in
			0)
				echo_date "$(__get_type_abbr_name)服务器【${ss_basic_server}】的ip地址解析成功：${SERVER_IP}"
				ss_basic_server="$SERVER_IP"
				ss_basic_server_ip="$SERVER_IP"
				dbus set ss_basic_server_ip="$SERVER_IP"
				;;
			1)
				# server is domain format and failed to resolve.
				echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
				echo_date "$(__get_type_abbr_name)服务器的ip地址解析失败，这将大概率导致节点无法正常工作！"
				echo_date "请尝试在【DNS设定】- 【节点域名解析DNS服务器】处更换节点服务器的解析方案后重试！"
				echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
				unset ss_basic_server_ip
				dbus remvoe ss_basic_server_ip
				# close_in_five flag
				;;
			2)
				# server is not ip either domain!
				echo_date "错误2！！检测到你设置的服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
				echo_date "请更正你的错误然后重试！！"
				close_in_five flag
				;;
			esac
		fi
	fi
}

ss_arg() {
	if [ "${ss_basic_type}" != "0" ];then
		return
	fi

	if [ "${ss_basic_ss_v2ray}" == "1" ]; then
		if [ "${ss_basic_ss_obfs}" == "http" -o "${ss_basic_ss_obfs}" == "tls" ]; then
			echo_date "检测到你同时开启了obfs-local和v2ray-plugin！。"
			echo_date "插件只能支持开启一个SIP002插件！"
			echo_date "请更正设置后重试！"
			close_in_five flag
		fi
		if [ -n "${ss_basic_ss_v2ray_opts}" ];then
			ARG_OBFS="--plugin v2ray-plugin --plugin-opts ${ss_basic_ss_v2ray_opts}"
		else
			ARG_OBFS="--plugin v2ray-plugin"
		fi
		echo_date "检测到开启了v2ray-plugin。"
	else
		if [ "${ss_basic_ss_obfs}" == "http" ]; then
			echo_date "检测到开启了simple-obfs。"
			if [ -n "${ss_basic_ss_obfs_host}" ]; then
				ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http;obfs-host=${ss_basic_ss_obfs_host}"
			else
				ARG_OBFS="--plugin obfs-local --plugin-opts obfs=http"
			fi
		elif [ "${ss_basic_ss_obfs}" == "tls" ]; then
			echo_date "检测到开启了simple-obfs。"
			if [ -n "${ss_basic_ss_obfs_host}" ]; then
				ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls;obfs-host=${ss_basic_ss_obfs_host}"
			else
				ARG_OBFS="--plugin obfs-local --plugin-opts obfs=tls"
			fi
		else
			ARG_OBFS=""
		fi
	fi
}
# create shadowsocks config file...
creat_ss_json() {
	if [ "${ss_basic_type}" == "0" -a "${ss_basic_rust}" == "1" ]; then
		echo_date "ℹ️使用shadowsocks-rust替换shadowsocks-libev..."
		if [ "${ss_basic_tfo}" == "1" -a "${LINUX_VER}" != "26" ]; then
			RUST_ARG_1="--fast-open"
			echo_date ss-rust开启tcp fast open支持.
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			RUST_ARG_1=""
		fi

		if [ "${ss_basic_tnd}" == "1" ]; then
			echo_date ss-rust开启TCP_NODELAY支持.
			RUST_ARG_2="--no-delay"
		else
			RUST_ARG_2=""
		fi

		ARG_RUST_REDIR="--protocol redir -b 0.0.0.0:3333 -s ${ss_basic_server}:${ss_basic_port} -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		ARG_RUST_REDIR_NS="--protocol redir -b 0.0.0.0:3333 -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		ARG_RUST_SOCKS="-b 127.0.0.1:23456 -s ${ss_basic_server}:${ss_basic_port} -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		ARG_RUST_TUNNEL="--protocol tunnel -b 0.0.0.0:${DNSF_PORT} -s ${ss_basic_server}:${ss_basic_port} -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		return 0
	fi
	
	if [ -n "${WAN_ACTION}" ]; then
		echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	fi
	if [ -n "${NAT_ACTION}" ]; then
		echo_date "检测到防火墙重启触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	fi
	
	echo_date "创建$(__get_type_abbr_name)配置文件到${CONFIG_FILE}"
	if [ "${ss_basic_type}" == "0" ]; then
		cat >${CONFIG_FILE} <<-EOF
			{
			    "server":"${ss_basic_server}",
			    "server_port":${ss_basic_port},
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"${ss_basic_password}",
			    "timeout":600,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "${ss_basic_type}" == "1" ]; then
		cat >${CONFIG_FILE} <<-EOF
			{
			    "server":"${ss_basic_server}",
			    "server_port":${ss_basic_port},
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"${ss_basic_password}",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocol",
			    "protocol_param":"$ss_basic_rss_protocol_param",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_param",
			    "method":"$ss_basic_method"
			}
		EOF
	fi

	if [ "$ss_basic_udp2raw_boost_enable" == "1" -o "$ss_basic_udp_boost_enable" == "1" ]; then
		if [ "$ss_basic_udp_upstream_mtu" == "1" -a "$ss_basic_udp_node" == "$ssconf_basic_node" ]; then
			echo_date "设定MTU为 $ss_basic_udp_upstream_mtu_value"
			cat /koolshare/ss/ss.json | run jq --argjson MTU $ss_basic_udp_upstream_mtu_value '. + {MTU: $MTU}' >/koolshare/ss/ss_tmp.json
			mv /koolshare/ss/ss_tmp.json /koolshare/ss/ss.json
		fi
	fi
}

get_proxy_server_ip(){
	# 获取代理服务器ip地址
	# 在代理程序启动前获取，不一定是真实的代理服务器ip，比如中转节点
	if [ -n "${ss_real_server_ip}" ]; then
		return
	fi
	
	if [ -n "${ss_basic_server_ip}" ]; then
		# 用chnroute去判断SS服务器在国内还是在国外
		ipset test chnroute ${ss_basic_server_ip} >/dev/null 2>&1
		if [ "$?" != "0" ]; then
			# ss服务器是国外IP
			ss_real_server_ip="${ss_basic_server_ip}"
			echo_date "检测到节点服务器的ip地址为：${ss_basic_server_ip}，是国外IP"
		else
			# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
			ss_real_server_ip=""
			echo_date "检测到代理服务器的ip地址为：${ss_basic_server_ip}，是国内IP，可能是国内中转节点！"
		fi
	else
		# ss服务器可能是域名且没有正确解析
		ss_real_server_ip=""
	fi
}

start_ss_local() {
	if [ -n "$(ps|grep ss-local|grep 23456)" ];then
		return
	fi
	
	if [ "${ss_basic_type}" == "1" ]; then
		echo_date "开启ssr-local，提供socks5代理端口：23456"
		run_bg rss-local -l 23456 -c ${CONFIG_FILE} -u -f /var/run/sslocal1.pid
		detect_running_status rss-local "/var/run/sslocal1.pid"
	elif [ "${ss_basic_type}" == "0" ]; then
		if [ "${ss_basic_rust}" == "1" -a -x "/koolshare/bin/sslocal" ];then
			echo_date "开启sslocal (shadowsocks-rust)，提供socks5代理端口：23456"
			run_bg sslocal ${ARG_RUST_SOCKS} ${ARG_OBFS} -d
			detect_running_status sslocal
		else
			local ARG_1 ARG_2
			if [ "${ss_basic_tfo}" == "1" -a "${LINUX_VER}" != "26" ]; then
				local ARG_1="--fast-open"
				echo 3 >/proc/sys/net/ipv4/tcp_fastopen
			fi

			if [ "${ss_basic_tnd}" == "1" ]; then
				local ARG_2="--no-delay"
			fi
		
			echo_date "开启ss-local(shadowsocks-libev)，提供socks5代理端口：23456"
			run_bg ss-local -l 23456 -c ${CONFIG_FILE} ${ARG_OBFS} ${ARG_1} ${ARG_2} -u -f /var/run/sslocal1.pid
			detect_running_status ss-local "/var/run/sslocal1.pid"
		fi
	fi
}

start_dns2socks(){
	local addr=$1
	local port=$2
	local edns=$3
	
	killall dns2socks >/dev/null 2>&1

	if [ "${ss_basic_nofrnipcheck}" != "1" ];then
		if [ "${edns}" == "1" ];then
			if [ -n "${ss_real_server_ip}" ];then
				run_bg dns2socks /ef:${ss_real_server_ip}/24 127.0.0.1:23456 "${addr}" 127.0.0.1:${port}
			fi

			if [ -n "${REMOTE_IP_FRN}" ];then
				run_bg dns2socks /ef:${REMOTE_IP_FRN}/24 127.0.0.1:23456 "${addr}" 127.0.0.1:${port}
			fi

			if [ -z "${ss_real_server_ip}" -a -z "${REMOTE_IP_FRN}" ];then
				run_bg dns2socks 127.0.0.1:23456 "${addr}" 127.0.0.1:${port}
			fi
		else
			run_bg dns2socks 127.0.0.1:23456 "${addr}" 127.0.0.1:${port}
		fi
	else
		run_bg dns2socks 127.0.0.1:23456 "${addr}" 127.0.0.1:${port}
	fi
	detect_running_status2 dns2socks ${port}
}

start_ss_tunnel() {
	local port=$1
	if [ "${ss_basic_type}" == "1" ]; then
		echo_date "开启ssr-tunnel，端口：$port，作为chinadns-ng的上游DNS..."
		run_bg rss-tunnel -c ${CONFIG_FILE} -l ${port} -L $(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}):$(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}) -u -f /var/run/sstunnel.pid
	elif [ "${ss_basic_type}" == "0" ]; then
		echo_date "开启ss-tunnel，端口：$port，作为chinadns-ng的上游DNS..."
		if [ "${ss_basic_rust}" == "1" ];then
			run_bg sslocal ${ARG_RUST_TUNNEL} -f $(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}):$(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}) ${ARG_OBFS} -u -d
		else
			run_bg ss-tunnel -c ${CONFIG_FILE} -l ${port} -L $(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}):$(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}) ${ARG_OBFS} -u -f /var/run/sstunnel.pid
		fi
	fi
}

start_dohclient_chng(){
	# 此处的dohclient进程作为chinadns方案的上游DNS
	# start | restart
	local ACT=$1
	# 1:chn1 | 2:chn2 | 3:fr1 | 4:frn2
	local FLG=$2
	# OPTION FOR DNS PROVIDER
	local VAL=$3
	# ECS switch
	local ECS=$4
	# ENABLE PROXY
	local PXY=$5
	get_dns_doh ${VAL}

	if [ "${ACT}" == "start" ];then
		if [ "${FLG}" == "chn1" ];then
			echo_date "开启dohclient，DoH服务器：${DOHNAME}，作为chinadns-ng的国内上游DNS-1"
		elif [ "${FLG}" == "chn2" ];then
			echo_date "开启dohclient，DoH服务器：${DOHNAME}，作为chinadns-ng的国内上游DNS-2"
		elif [ "${FLG}" == "frn1" ];then
			echo_date "开启dohclient，DoH服务器：${DOHNAME}，作为chinadns-ng的可信上游DNS-1"
			start_ss_local
		elif [ "${FLG}" == "frn2" ];then
			echo_date "开启dohclient，DoH服务器：${DOHNAME}，作为chinadns-ng的可信上游DNS-2"
		fi
	elif [ "${ACT}" == "restart" ];then
		# 重启情况仅在需要添加国外IP出口的时候使用，chn1、chn2不使用
		if [ "${REMOTE_IP_FRN}" == "${ss_real_server_ip}" ];then
			return
		fi
		if [ "${FLG}" == "frn1" ];then
			echo_date "重启dohclient，填入EDNS subnet，作为chinadns-ng的可信上游DNS-1"
			local doh_pid_frn1=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_frn1" | awk '{print $1}')
			if [ -n "${doh_pid_frn1}" ]; then
				#echo_date "先关闭工作在chinadns-ng国外-1上游的dohclient进程..."
				if [ -f "/koolshare/perp/doh_frn1/rc.main" ];then
					perpctl X doh_frn1 >/dev/null 2>&1
					perpctl d doh_frn1 >/dev/null 2>&1
				fi
				rm -rf /koolshare/perp/doh_frn1
				kill -9 ${doh_pid_frn1} >/dev/null 2>&1
				rm -rf /tmp/doh_frn1.conf
				rm -rf /tmp/doh_frn1.log
				rm -rf /tmp/doh_frn1.db
			fi
		elif [ "${FLG}" == "frn2" ];then
			echo_date "重启dohclient，填入EDNS subnet，作为chinadns-ng的可信上游DNS-2"
			local doh_pid_frn2=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "1056|doh_frn2" | awk '{print $1}')
			if [ -n "${doh_pid_frn2}" ]; then
				#echo_date "先关闭工作在chinadns-ng国外-2上游的dohclient进程..."
				[ -f "/koolshare/perp/doh_frn2/rc.main" ] && perpctl d doh_frn2 >/dev/null 2>&1
				rm -rf /koolshare/perp/doh_frn2
				kill -9 ${doh_pid_frn2} >/dev/null 2>&1
				rm -rf /tmp/doh_frn2.conf
				rm -rf /tmp/doh_frn2.db
				rm -rf /tmp/doh_frn2.log
			fi
		fi
	fi

	local CARGS="addr=${DOHADDR}&host=${DOHHOST}&path=${DOHPATH}&post=0&keep-alive=600&proxy=${PXY}&ecs=0"

	if [ "${FLG%%[0-9]}" == "chn" ];then
		if [ "${ECS}" == "1" ];then
			if [ "${ss_basic_nochnipcheck}" == "1" ];then
				echo_date "因插件关闭了国内出口ip检测，故无法开启chinadns-ng的国内DNS-${FLG:3:1}的ecs功能，继续！"
			else
				if [ -n "${REMOTE_IP_OUT}" ];then
					local CARGS="addr=${DOHADDR}&host=${DOHHOST}&path=${DOHPATH}&post=0&keep-alive=600&proxy=${PXY}&ecs=1&china-ip4=${REMOTE_IP_OUT%.*}.0/24"
				else
					echo_date "因未获取到国内出口ip，故无法开启chinadns-ng的国内DNS-${FLG:3:1}的ecs功能，继续！"
				fi
			fi
		fi
	elif [ "${FLG%%[0-9]}" == "frn" ];then
		if [ "${ECS}" == "1" ];then
			if [ "${ss_basic_nofrnipcheck}" == "1" ];then
				echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-${FLG:3:1}的ecs功能，继续！"
			else
				if [ -n "${ss_real_server_ip}" ];then
					local CARGS="addr=${DOHADDR}&host=${DOHHOST}&path=${DOHPATH}&post=0&keep-alive=600&proxy=${PXY}&ecs=1&foreign-ip4=${ss_real_server_ip%.*}.0/24"
				fi
				if [ -n "${REMOTE_IP_FRN}" ];then
					local CARGS="addr=${DOHADDR}&host=${DOHHOST}&path=${DOHPATH}&post=0&keep-alive=600&proxy=${PXY}&ecs=1&foreign-ip4=${REMOTE_IP_FRN%.*}.0/24"
				fi
				if [ -z "${ss_real_server_ip}" -a -z "${REMOTE_IP_FRN}" ];then
					echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-${FLG:3:1}的ecs功能，继续！"
				fi
			fi
		fi
	fi

	if [ "${FLG}" == "chn1" ];then
		if [ "${ECS}" == "1" ];then
			BIND_PORT=2051
		else
			BIND_PORT=1051
		fi
	elif [ "${FLG}" == "chn2" ];then
		if [ "${ECS}" == "1" ];then
			BIND_PORT=2052
		else
			BIND_PORT=1052
		fi
	elif [ "${FLG}" == "frn1" ];then
		if [ "${ECS}" == "1" ];then
			BIND_PORT=2055
		else
			BIND_PORT=1055
		fi
	elif [ "${FLG}" == "frn2" ];then
		if [ "${ECS}" == "1" ];then
			BIND_PORT=2056
		else
			BIND_PORT=1056
		fi
	fi

	cat >/tmp/doh_${FLG}.conf <<-EOF
		config cfg
		    option bind_addr '0.0.0.0'
		    option bind_port '${BIND_PORT}'
		    option proxy '127.0.0.1:23456'
		    option chnroute '/koolshare/ss/rules/chnroute.txt'
		    option timeout '10'
		    option log_file '/tmp/doh_${FLG}.log'
		    option log_level '5'
		    option cache_timeout '1'
		    option cache_db '/tmp/doh_${FLG}.db'
		    option cache_autosave '/tmp/doh_${FLG}.db'
		    option cache_api 'get,list,put,delete,save,load'
		    option wwwroot '/koolshare/ss/dohclient'
		    option mode '1'
		    option channel doh
		    option channel_args '${CARGS}'
	EOF

	if [ "${FLG}" == "frn2" ];then
		sed -i '/option proxy/d' /tmp/doh_${FLG}.conf
	fi

	# use perp to start dohclient
	mkdir -p /koolshare/perp/doh_${FLG}
	cat >/koolshare/perp/doh_${FLG}/rc.main <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		CMD="dohclient --config=/tmp/doh_${FLG}.conf"

		if test \${1} = 'start' ; then   
			exec 2>&1
			exec \$CMD
		fi
		exit 0
		
	EOF
	chmod +x /koolshare/perp/doh_${FLG}/rc.main
	chmod +t /koolshare/perp/doh_${FLG}/
	sync
	perpctl A doh_${FLG} >/dev/null 2>&1
	perpctl u doh_${FLG} >/dev/null 2>&1
	detect_running_status2 dohclient doh_${FLG}
}

start_dohclient_main(){
	local flag=$1
	local EARGS=""
	local FRNPROXY="0"
	if [ "${ss_basic_dohc_proxy}" == "1" ];then
		start_ss_local
		local EARGS="--proxy=127.0.0.1:23456"
		local FRNPROXY="1"
	fi
	
	if [ "${flag}" == "start" ];then
		echo_date "开启dohclient，作为国内加国外域名解析DNS..."
	elif [ "${flag}" == "restart" ];then
		if [ -z "${REMOTE_IP_FRN}" ];then
			return
		fi
		if [ "${REMOTE_IP_FRN}" == "${ss_real_server_ip}" ];then
			return
		fi
		#local doh_pid_main=$(ps -w | grep "dohclient" | grep -v "grep" | grep "7913" | awk '{print $1}')
		local doh_pid_main=$(ps -w | grep "dohclient" | grep -v "grep" | grep -E "7913|doh_main" | awk '{print $1}')
		if [ -n "${doh_pid_main}" ]; then
			echo_date "关闭dohclient进程3..."
			# 保存缓存
			dohclient-cache -s 127.0.0.1:7913 save /tmp/doh_main.db >/dev/null 2>&1
			sync
			# 关闭dohclient
			[ -f "/koolshare/perp/doh_main/rc.main" ] && perpctl d doh_main >/dev/null 2>&1
			rm -rf /koolshare/perp/doh_main
			kill -9 ${doh_pid_main} >/dev/null 2>&1
			rm -rf /var/run/doh_main.pid
			rm -rf /tmp/doh_main.log
			# rm -f /tmp/doh_main.db
			sync
		fi
		echo_date "重启dohclient，填入EDNS Client Subnet，作为国内加国外域名解析DNS..."
	fi
	
	local CHNREQ="0"
	local FRNREQ="0"
	local CHNECS="0"
	local FRNECS="0"
	local ECSFLAG="0"
	if [ "${ss_basic_dohc_ecs_china}" == "1" ];then
		if [ "${ss_basic_nochnipcheck}" == "1" ];then
			echo_date "因插件关闭了国内出口ip检测，故无法开启dohclient的国内DNS的ecs功能，继续！"
		else
			if [ -n "${REMOTE_IP_OUT}" ];then
				local CHNECS="1"
				local CHNNET="${REMOTE_IP_OUT}/24"
			else
				echo_date "因未获取到国内出口ip，故无法开启dohclient的国内DNS的ecs功能，继续！"
			fi
		fi
	fi
	if [ "${ss_basic_dohc_ecs_foreign}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" == "1" ];then
			echo_date "因插件关闭了代理出口ip检测，故无法开启dohclient的国外DNS的ecs功能，继续！"
		else
			if [ -n "${ss_real_server_ip}" ];then
				local FRNECS="1"
				local FRNNET="${ss_real_server_ip}/24"
			fi
			if [ -n "${REMOTE_IP_FRN}" ];then
				local FRNECS="1"
				local FRNNET="${REMOTE_IP_FRN}/24"
			fi
			if [ -z "${ss_real_server_ip}" -a -z "${REMOTE_IP_FRN}" ];then
				echo_date "因未获取到代理出口ip，故无法开启dohclient的国外DNS的ecs功能，继续！"
			fi
		fi
	fi

	# doh_main China DNS
	if [ "${ss_basic_dohc_sel_china}" == "1" ];then
		local CHN_CHANNEL="udp"
		local CHDNS=$(get_dns_china ${ss_basic_dohc_udp_china} ${ss_basic_dohc_udp_china_user})
		local CHPOT=$(get_dns_china_port ${ss_basic_dohc_udp_china} ${ss_basic_dohc_udp_china_user})
		local CHNADDR="${CHDNS}:${CHPOT}"
	elif  [ "${ss_basic_dohc_sel_china}" == "2" ];then
		local CHN_CHANNEL="tcp"
		local CHDNS=$(get_dns_china ${ss_basic_dohc_tcp_china} ${ss_basic_dohc_tcp_china_user})
		local CHPOT=$(get_dns_china_port ${ss_basic_dohc_tcp_china} ${ss_basic_dohc_tcp_china_user})
		local CHNADDR="${CHDNS}:${CHPOT}"
	elif  [ "${ss_basic_dohc_sel_china}" == "3" ];then
		local CHN_CHANNEL="doh"
		get_dns_doh ${ss_basic_dohc_doh_china}
		local CHNADDR="${DOHADDR}"
		local CHNHOST="${DOHHOST}"
	fi

	# doh_main foreign DNS
	if  [ "${ss_basic_dohc_sel_foreign}" == "2" ];then
		local FRN_CHANNEL="tcp"
		local FNDNS=$(get_dns_foreign ${ss_basic_dohc_tcp_foreign} ${ss_basic_dohc_tcp_foreign_user})
		local FNPOT=$(get_dns_foreign_port ${ss_basic_dohc_tcp_foreign} ${ss_basic_dohc_tcp_foreign_user})
		local FRNADDR="${FNDNS}:${FNPOT}"
	elif  [ "${ss_basic_dohc_sel_foreign}" == "3" ];then
		local FRN_CHANNEL="doh"
		get_dns_doh ${ss_basic_dohc_doh_foreign}
		local FRNADDR="${DOHADDR}"
		local FRNHOST="${DOHHOST}"
	fi
	
	local CARGS=""
	local CARGS="${CARGS}chndoh.channel=${CHN_CHANNEL}"
	local CARGS="${CARGS}&chndoh.addr=${CHNADDR}"
	[ "${CHN_CHANNEL}" == "doh" ] && local CARGS="${CARGS}&chndoh.host=${CHNHOST}"
	[ "${CHN_CHANNEL}" == "doh" ] && local CARGS="${CARGS}&chndoh.path=/dns-query"
	local CARGS="${CARGS}&chndoh.post=${CHNREQ}"
	local CARGS="${CARGS}&chndoh.ecs=${CHNECS}"
	[ -n "${CHNNET}" ] && local CARGS="${CARGS}&chndoh.net=${CHNNET}"
	local CARGS="${CARGS}&frndoh.channel=${FRN_CHANNEL}"
	local CARGS="${CARGS}&frndoh.addr=${FRNADDR}"
	[ "${FRN_CHANNEL}" == "doh" ] && local CARGS="${CARGS}&frndoh.host=${FRNHOST}"
	[ "${FRN_CHANNEL}" == "doh" ] && local CARGS="${CARGS}&frndoh.path=/dns-query"
	local CARGS="${CARGS}&frndoh.post=${FRNREQ}"
	local CARGS="${CARGS}&frndoh.proxy=${FRNPROXY}"
	local CARGS="${CARGS}&frndoh.ecs=${FRNECS}"
	[ -n "${FRNNET}" ] && local CARGS="${CARGS}&frndoh.net=${FRNNET}"

	# 缓存时长
	local CACHETIME=${ss_basic_dohc_cache_timeout}

	# gen conf
	cat >/tmp/doh_main.conf <<-EOF
		config cfg
		    option bind_addr '0.0.0.0'
		    option bind_port '7913'
		    option proxy '127.0.0.1:23456'
		    option chnroute '/koolshare/ss/rules/chnroute.txt'
		    option timeout '10'
		    option log_file '/tmp/doh_main.log'
		    option log_level '5'
		    option cache_timeout '${CACHETIME}'
		    option cache_db '/tmp/doh_main.db'
		    option cache_autosave '/tmp/doh_main.db'
		    option cache_api 'get,list,put,delete,save,load'
		    option wwwroot '/koolshare/ss/dohclient'
		    option mode '1'
		    option channel chinadns
		    option channel_args '${CARGS}'
	EOF

	# use perp to start dohclient
	mkdir -p /koolshare/perp/doh_main
	cat >/koolshare/perp/doh_main/rc.main <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		CMD="dohclient --config=/tmp/doh_main.conf"

		if test \${1} = 'start' ; then   
			exec 2>&1
			exec \$CMD
		fi
		exit 0
		
	EOF
	chmod +x /koolshare/perp/doh_main/rc.main
	chmod +t /koolshare/perp/doh_main/
	sync
	perpctl A doh_main >/dev/null 2>&1
	perpctl u doh_main >/dev/null 2>&1
	detect_running_status2 dohclient doh_main

	# load cache from db
	if [ "${ss_basic_dohc_cache_reuse}" == "1" ];then
		local ret=$(dohclient-cache -s 127.0.0.1:7913 load /tmp/doh_main_backup.db 2>/dev/null)
		if [ $? == 0 -a -n "${ret}" ];then
			local error=$(echo ${ret} | run jq '.error')
			local data=$(echo ${ret} | run jq '.data')
			if [ "${error}" == "0" -a -n "${data}" ];then
				echo_date "DNS缓存加载成功：总计加载了${data}条DNS缓存！"
			else
				echo_date "DNS缓存加载失败！删除缓存备份文件！"
			fi
		else
			echo_date "DNS缓存加载失败！删除缓存备份文件！"
		fi
		rm -f /tmp/doh_main_backup.db
	fi
}

start_smartdns(){
	local conf_name=$1
	local _pid_file=/var/run/${conf_name}.pid
	local save_path=/koolshare/ss/rules
	local show_path=/tmp/upload
	
	rm -rf /tmp/smartdns*
	if [ -f ${save_path}/${conf_name}_user.conf ];then
		cp -rf ${save_path}/${conf_name}_user.conf ${show_path}/${conf_name}.conf
		run_bg smartdns -S -c ${save_path}/${conf_name}_user.conf -p ${_pid_file}
	else
		cp -rf ${save_path}/${conf_name}.conf ${show_path}/${conf_name}.conf
		run_bg smartdns -S -c ${save_path}/${conf_name}.conf -p ${_pid_file}
	fi	
	detect_running_status smartdns ${_pid_file}
}

start_dns(){
	if [ "${ss_basic_advdns}" != "1" ];then
		start_dns_old
	else
		start_dns_new
	fi
}

start_dns_new(){
	local EXT=""
	local CDNS=""
	local FDNS=""
	local CDNS_PORT=""
	
	# 通过域名解析获取代理服务器ip地址
	# 对于中转机场，还需要在代理开启成功后再进行一次检测
	get_proxy_server_ip

	# 如果之前使用full版本，切换为lite后，某些dns选项没了
	if [ -z "${ss_dns_plan}" ];then
		ss_dns_plan="1"
		dbus set ss_dns_plan="1"
	fi
	if [ "${ss_dns_plan}" == "2" -a ! -x "/koolshare/bin/smartdns" ];then
		ss_dns_plan="1"
		dbus set ss_dns_plan="1"
	fi
	
	if [ "${ss_dns_plan}" == "3" -a ! -x "/koolshare/bin/dohclient" ];then
		ss_dns_plan="1"
		dbus set ss_dns_plan="1"
	fi

	echo_date "----------------------- start dns -----------------------"
	
	# chinadns-ng
	if [ "${ss_dns_plan}" == "1" ];then
		# 1. 中国DNS至少选择一个
		if [ "${ss_basic_chng_china_1_enable}" != "1" -a "${ss_basic_chng_china_2_enable}" != "1" ];then
			echo_date "检测到中国DNS-1和中国DNS-2均未开启，chinadns-ng至少需要指定一个国内上游DNS！"
			echo_date "自动开启中国DNS-1和中国DNS-2！"
			ss_basic_chng_china_1_enable=1
			dbus set ss_basic_chng_china_1_enable=1
			ss_basic_chng_china_2_enable=1
			dbus set ss_basic_chng_china_2_enable=1
		fi

		# 2. 中国DNS不能选择一样的
		if [ "${ss_basic_chng_china_1_enable}" == "1" -a "${ss_basic_chng_china_2_enable}" == "1" ];then
			if [ "${ss_basic_chng_china_1_prot}" == "1" -a "${ss_basic_chng_china_2_prot}" == "1" ];then
				if [ "${ss_basic_chng_china_1_udp}" == "${ss_basic_chng_china_2_udp}" ];then
					if [ "${ss_basic_chng_china_1_udp}" != "99" ];then
						echo_date "检测到两个中国DNS值一样！，自动关闭第二个中国DNS！"
						ss_basic_chng_china_2_enable=0
						dbus set ss_basic_chng_china_2_enable=0
					else
						if [ "${ss_basic_chng_china_1_udp_user}" == "${ss_basic_chng_china_2_udp_user}" ];then
							echo_date "检测到两个中国DNS值一样！，自动关闭第二个中国DNS！"
							ss_basic_chng_china_2_enable=0
							dbus set ss_basic_chng_china_2_enable=0
						fi
					fi
				fi
			fi
			if [ "${ss_basic_chng_china_1_prot}" == "2" -a "${ss_basic_chng_china_2_prot}" == "2" ];then
				if [ "${ss_basic_chng_china_1_tcp}" == "${ss_basic_chng_china_2_tcp}" ];then
					if [ "${ss_basic_chng_china_1_tcp}" != "99" ];then
						echo_date "检测到两个中国DNS值一样！，自动关闭第二个中国DNS！"
						ss_basic_chng_china_2_enable=0
						dbus set ss_basic_chng_china_2_enable=0
					else
						if [ "${ss_basic_chng_china_1_tcp_user}" == "${ss_basic_chng_china_2_tcp_user}" ];then
							echo_date "检测到两个中国DNS值一样！，自动关闭第二个中国DNS！"
							ss_basic_chng_china_2_enable=0
							dbus set ss_basic_chng_china_2_enable=0
						fi
					fi
				fi
			fi
			if [ "${ss_basic_chng_china_1_prot}" == "3" -a "${ss_basic_chng_china_2_prot}" == "3" ];then
				if [ "${ss_basic_chng_china_1_doh}" == "${ss_basic_chng_china_2_doh}" ];then
					echo_date "检测到两个中国DNS值一样！，自动关闭第二个中国DNS！"
					ss_basic_chng_china_2_enable="0"
					dbus set ss_basic_chng_china_2_enable="0"
				fi
			fi
		fi

		# 3. 可信DNS至少选择一个
		if [ "${ss_basic_chng_trust_1_enable}" != "1" -a "${ss_basic_chng_trust_2_enable}" != "1" ];then
			echo_date "检测到可信DNS-1和可信DNS-2均未开启，chinadns-ng至少需要指定一个可信上游DNS！"
			echo_date "自动开启可信DNS-1！"
			ss_basic_chng_trust_1_enable="1"
			dbus set ss_basic_chng_trust_1_enable="1"
		fi

		# 5. chinandns-ng的启动参数检查
		if [ -n "${ss_basic_chng_repeat_times}" ];then
			if [ $(number_test ${ss_basic_chng_repeat_times}) != "0" ];then
				echo_date "chinadns-ng重复发包次数填写错误，自动更正为2！"
				ss_basic_chng_repeat_times="2"
				dbus set ss_basic_chng_repeat_times="2"
			fi
			if [ ${ss_basic_chng_repeat_times} -gt "3" ];then
				echo_date "chinadns-ng重复发包次数填为${ss_basic_chng_repeat_times}！建议此处设置不超过3！继续！"
			fi
			local EXT="-p ${ss_basic_chng_repeat_times}"
		fi

		# 6. 生成chinadns-ng的国内DNS
		if [ "${ss_basic_chng_china_1_enable}" == "1" ];then
			if [ -z "${ss_basic_chng_china_1_prot}" ];then
				ss_basic_chng_china_1_prot="1"
				ss_basic_chng_china_1_ecs="1"
				dbus set ss_basic_chng_china_1_prot="1"
				dbus set ss_basic_chng_china_1_ecs="1"
			fi
		
			if [ "${ss_basic_chng_china_1_prot}" == "1" ];then
				# udp
				if [ -z "${ss_basic_chng_china_1_udp}" ];then
					# use isp dns defalut
					ss_basic_chng_china_1_udp="1"
					dbus set ss_basic_chng_china_1_udp="1"
				fi
				local CHINA_DNS_1=$(get_dns_china ${ss_basic_chng_china_1_udp} ${ss_basic_chng_china_1_udp_user})
				local CHINA_POR_1=$(get_dns_china_port ${ss_basic_chng_china_1_udp} ${ss_basic_chng_china_1_udp_user})
				if [ "${ss_basic_chng_china_1_udp}" == "96" ];then
					echo_date "开启【smartdns (udp)】，作为chinadns-ng的国内上游DNS..."
					local CDNS_1="${CHINA_DNS_1}#${CHINA_POR_1}"
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_udp
				else
					if [ "${ss_basic_chng_china_1_ecs}" == "1" ];then
						if [ -n "${REMOTE_IP_OUT}" ];then
							echo_date "开启dns-ecs-forcer，将DNS查询带上ECS，作为chinadns-ng的国内上游DNS"
							local CDNS_1="127.0.0.1#2051"
							run_bg dns-ecs-forcer -p 2051 -s ${CHINA_DNS_1}:${CHINA_POR_1} -e "${REMOTE_IP_OUT%.*}.0"
							detect_running_status2 dns-ecs-forcer 2051 slient
						else
							if [ "${ss_basic_nochnipcheck}" == "1" ];then
								echo_date "因插件关闭了国内出口ip检测，故无法开启chinadns-ng的国内DNS-1的ecs功能，继续！"
							else
								echo_date "因未获取到国内出口ip，故无法开启chinadns-ng的国内DNS-1的ecs功能，继续！"
							fi
							local CDNS_1="${CHINA_DNS_1}#${CHINA_POR_1}"
						fi
					else
						echo_date "使用${CHINA_DNS_1}:${CHINA_POR_1}，udp协议，作为chinadns-ng的国内上游DNS"
						local CDNS_1="${CHINA_DNS_1}#${CHINA_POR_1}"
					fi
				fi
			elif [ "${ss_basic_chng_china_1_prot}" == "2" ];then
				# tcp
				local CHINA_DNS_1=$(get_dns_china ${ss_basic_chng_china_1_tcp} ${ss_basic_chng_china_1_tcp_user})
				local CHINA_POR_1=$(get_dns_china_port ${ss_basic_chng_china_1_tcp} ${ss_basic_chng_china_1_tcp_user})
				if [ "${ss_basic_chng_china_1_tcp}" == "97" ];then
					local CDNS_1="${CHINA_DNS_1}#${CHINA_POR_1}"
					echo_date "开启【smartdns (tcp)】，作为chinadns-ng的国内上游DNS..."
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_tcp
				else
					if [ "${ss_basic_chng_china_1_ecs}" == "1" ];then
						if [ -n "${REMOTE_IP_OUT}" ];then
							# 将1051端口的UDP DNS请求，通过TCP转发到上游服务器
							local CDNS_1="127.0.0.1#2051"
							echo_date "开启dns2tcp，将dns-ecs-forcer的udp查询转换为tcp查询"
							run_bg dns2tcp -L"127.0.0.1#1051" -R"${CHINA_DNS_1}#${CHINA_POR_1}"
							detect_running_status2 dns2tcp 1051 slient
							# 把来自2051的dns请求加上ecs标签，转发给1051端口
							echo_date "开启dns-ecs-forcer，将DNS查询带上ECS，作为chinadns-ng的国内上游DNS"
							run_bg dns-ecs-forcer -p 2051 -s 127.0.0.1:1051 -e "${REMOTE_IP_OUT%.*}.0"
							detect_running_status2 dns-ecs-forcer 2051 slient
						else
							if [ "${ss_basic_nochnipcheck}" == "1" ];then
								echo_date "因插件关闭了国内出口ip检测，故无法开启chinadns-ng的国内DNS-1的ecs功能，继续！"
							else
								echo_date "因未获取到国内出口ip，故无法开启chinadns-ng的国内DNS-1的ecs功能，继续！"
							fi
							echo_date "开启dns2tcp，将中国DNS-1的udp查询转换为tcp查询，作为chinadns-ng的国内上游DNS"
							local CDNS_1="127.0.0.1#1051"
							run_bg dns2tcp -L"127.0.0.1#1051" -R"${CHINA_DNS_1}#${CHINA_POR_1}"
							detect_running_status2 dns2tcp 1051 slient
						fi
					else
						echo_date "开启dns2tcp，将中国DNS-1的udp查询转换为tcp查询，作为chinadns-ng的国内上游DNS"
						local CDNS_1="127.0.0.1#1051"
						run_bg dns2tcp -L"127.0.0.1#1051" -R"${CHINA_DNS_1}#${CHINA_POR_1}"
						detect_running_status2 dns2tcp 1051 slient
					fi
				fi
			elif [ "${ss_basic_chng_china_1_prot}" == "3" ];then
				# doh
				if [ "${ss_basic_chng_china_1_doh}" == "98" ]; then
					echo_date "开启smartdns(doh)，作为chinadns-ng国内上游DNS"
					local CDNS_1="127.0.0.1#5445"
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_doh
				else
					if [ "${ss_basic_chng_china_1_ecs}" != "1" ]; then
						local CDNS_1="127.0.0.1#1051"
					else
						local CDNS_1="127.0.0.1#2051"
					fi
					start_dohclient_chng start chn1 ${ss_basic_chng_china_1_doh} ${ss_basic_chng_china_1_ecs} 0
				fi
			fi
		fi

		if [ "${ss_basic_chng_china_2_enable}" == "1" ];then
			if [ -z "${ss_basic_chng_china_2_prot}" ];then
				ss_basic_chng_china_2_prot="2"
				dbus set ss_basic_chng_china_2_prot="2"
			fi
		
			if [ "${ss_basic_chng_china_2_prot}" == "1" ];then
				# udp
				local CHINA_DNS_2=$(get_dns_china ${ss_basic_chng_china_2_udp} ${ss_basic_chng_china_2_udp_user})
				local CHINA_POR_2=$(get_dns_china_port ${ss_basic_chng_china_2_udp} ${ss_basic_chng_china_1_udp_user})
				if [ "${ss_basic_chng_china_2_udp}" == "96" ];then
					echo_date "开启【smartdns (udp)】，作为chinadns-ng的国内上游DNS..."
					local CDNS_2="${CHINA_DNS_2}#${CHINA_POR_2}"
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_udp
				else
					if [ "${ss_basic_chng_china_2_ecs}" == "1" ];then
						if [ -n "${REMOTE_IP_OUT}" ];then
							echo_date "开启dns-ecs-forcer，将DNS查询带上ECS，作为chinadns-ng的国内上游DNS"
							local CDNS_2="127.0.0.1#2052"
							run_bg dns-ecs-forcer -p 2052 -s ${CHINA_DNS_2}:${CHINA_POR_2} -e "${REMOTE_IP_OUT%.*}.0"
							detect_running_status2 dns-ecs-forcer 2052 slient
						else
							if [ "${ss_basic_nochnipcheck}" == "1" ];then
								echo_date "因插件关闭了国内出口ip检测，故无法开启chinadns-ng的国内DNS-2的ecs功能，继续！"
							else
								echo_date "因未获取到国内出口ip，故无法开启chinadns-ng的国内DNS-2的ecs功能，继续！"
							fi
							local CDNS_2="${CHINA_DNS_2}#${CHINA_POR_2}"
						fi
					else
						echo_date "使用${CHINA_DNS_2}:${CHINA_POR_2}，udp协议，作为chinadns-ng的国内上游DNS"
						local CDNS_2="${CHINA_DNS_2}#${CHINA_POR_2}"
					fi
				fi
			elif [ "${ss_basic_chng_china_2_prot}" == "2" ];then
				# tcp
				if [ -z "${ss_basic_chng_china_2_tcp}" ];then
					# use isp dns defalut
					ss_basic_chng_china_2_tcp="5"
					ss_basic_chng_china_2_ecs="1"
					dbus set ss_basic_chng_china_2_tcp="5"
					dbus set ss_basic_chng_china_2_ecs="1"
				fi
				local CHINA_DNS_2=$(get_dns_china ${ss_basic_chng_china_2_tcp} ${ss_basic_chng_china_2_tcp_user})
				local CHINA_POR_2=$(get_dns_china_port ${ss_basic_chng_china_2_tcp} ${ss_basic_chng_china_1_tcp_user})
				if [ "${ss_basic_chng_china_2_tcp}" == "97" ];then
					local CDNS_2="${CHINA_DNS_2}#${CHINA_POR_2}"
					echo_date "开启【smartdns (tcp)】，作为chinadns-ng的国内上游DNS..."
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_tcp
				else
					if [ "${ss_basic_chng_china_2_ecs}" == "1" ];then
						if [ -n "${REMOTE_IP_OUT}" ];then
							local CDNS_2="127.0.0.1#2052"
							# 将1052端口的UDP DNS请求，通过TCP转发到上游服务器
							echo_date "开启dns2tcp，将dns-ecs-forcer的udp查询转换为tcp查询"
							run_bg dns2tcp -L"127.0.0.1#1052" -R"${CHINA_DNS_2}#${CHINA_POR_2}"
							detect_running_status2 dns2tcp 1052
							# 把来自2052的dns请求加上ecs标签，转发给1052端口
							echo_date "开启dns-ecs-forcer，将DNS查询带上ECS，作为chinadns-ng的国内上游DNS"
							run_bg dns-ecs-forcer -p 2052 -s 127.0.0.1:1052 -e "${REMOTE_IP_OUT%.*}.0"
							detect_running_status2 dns-ecs-forcer 2052
						else
							if [ "${ss_basic_nochnipcheck}" == "1" ];then
								echo_date "因插件关闭了国内出口ip检测，故无法开启chinadns-ng的国内DNS-2的ecs功能，继续！"
							else
								echo_date "因未获取到国内出口ip，故无法开启chinadns-ng的国内DNS-2的ecs功能，继续！"
							fi
							echo_date "开启dns2tcp，将中国DNS-2的udp查询转换为tcp查询，作为chinadns-ng的国内上游DNS"
							local CDNS_2="127.0.0.1#1052"
							run_bg dns2tcp -L"127.0.0.1#1052" -R"${CHINA_DNS_2}#${CHINA_POR_2}"
							detect_running_status2 dns2tcp 1052
						fi
					else
						echo_date "开启dns2tcp，将中国DNS-2的udp查询转换为tcp查询，作为chinadns-ng的国内上游DNS"
						local CDNS_2="127.0.0.1#1052"
						run_bg dns2tcp -L"127.0.0.1#1052" -R"${CHINA_DNS_2}#${CHINA_POR_2}"
						detect_running_status2 dns2tcp 1052
					fi
				fi
			elif [ "${ss_basic_chng_china_2_prot}" == "3" ];then
				# doh
				if [ "${ss_basic_chng_china_2_doh}" == "98" ]; then
					echo_date "开启smartdns(doh)，作为chinadns-ng上游DNS"
					local CDNS_2="127.0.0.1#5445"
					rm -rf /tmp/smartdns*
					start_smartdns smartdns_chng_china_doh
				else
					if [ "${ss_basic_chng_china_2_ecs}" != "1" ]; then
						local CDNS_2="127.0.0.1#1052"
					else
						local CDNS_2="127.0.0.1#2052"
					fi
					start_dohclient_chng start chn2 ${ss_basic_chng_china_2_doh} ${ss_basic_chng_china_2_ecs} 0
				fi
			fi
		fi

		if [ -n "${CDNS_1}" -a -n "${CDNS_2}" ];then
			local CDNS="${CDNS_1},${CDNS_2}"
		elif [ -n "${CDNS_1}" -a -z "${CDNS_2}" ];then
			local CDNS="${CDNS_1}"
		elif [ -z "${CDNS_1}" -a -n "${CDNS_2}" ];then
			local CDNS="${CDNS_2}"
		fi

		# 7. 生成chinadns-ng的可信DNS -1 （代理）
		if [ "${ss_basic_chng_trust_1_enable}" == "1" ];then
			if [ -z "${ss_basic_chng_trust_1_opt}" ];then
				# use dns2socks as default
				ss_basic_chng_trust_1_opt="2"
				dbus set ss_basic_chng_trust_1_opt="2"
			fi
			
			# 7.1 udp
			if [ "${ss_basic_chng_trust_1_opt}" == "1" ];then
		 		if [ "${ss_basic_type}" == "0" -o "${ss_basic_type}" == "1" ]; then
		 			# ss/ssr 使用ss-tunnel或者ssr-tunnel
					if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
						local FDNS1="127.0.0.1#2055"
						if [ -n "${ss_real_server_ip}" ];then
							echo_date "开启ss-tunnel + ecs，作为chinadns-ng的上游DNS..."
							run_bg dns-ecs-forcer -p 2055 -s 127.0.0.1:1055 -e "${ss_real_server_ip%.*}.0"
							detect_running_status2 dns-ecs-forcer 2055
							start_ss_tunnel 1055
						else
							# 可能是中转服务器，没有确切的国外出口IP，此时先不开启ecs，等检测到国外出口IP后，再开启def
							# 先使用socat或者uredir将2055端口的请求转发到1055去
							if [ -z "$(which socat)" ];then
								echo_date "开启uredir，用于端口转发：1055 → 2055"
								uredir :2055 127.0.0.1:1055
								detect_running_status2 uredir 2055
							else
								echo_date "开启socat，用于端口转发：1055 → 2055"
								run_bg socat -T5 UDP4-LISTEN:2055,fork,reuseaddr UDP4:127.0.0.1:1055
								detect_running_status2 socat 2055
							fi
							start_ss_tunnel 1055
						fi
					else
						echo_date "开启ss-tunnel，作为chinadns-ng的上游DNS-1..."
						local FDNS1="127.0.0.1#1055"
						start_ss_tunnel 1055
					fi
				elif [ "${ss_basic_type}" == "3" -o "${ss_basic_type}" == "4" ]; then
					# v2ray xray
					if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
						echo_date "使用${VCORE_NAME}_dns作为chinadns-ng的上游DNS，并开启ECS..."
						local FDNS1="127.0.0.1#2055"
						if [ -n "${ss_real_server_ip}" ];then
							echo_date "开启dns-ecs-forcer..."
							run_bg dns-ecs-forcer -p 2055 -s 127.0.0.1:1055 -e "${ss_real_server_ip%.*}.0"
							detect_running_status2 dns-ecs-forcer 2055
						else
							# 可能是中转服务器，没有确切的国外出口IP，此时先不开启ecs，等检测到国外出口IP后，再开启def
							# 先使用socat或者uredir将2055端口的请求转发到1055去
							if [ -z "$(which socat)" ];then
								echo_date "开启uredir，用于端口转发：1055 → 2055"
								uredir :2055 127.0.0.1:1055
								detect_running_status2 uredir 2055
							else
								echo_date "开启socat，用于端口转发：1055 → 2055"
								run_bg socat -T5 UDP4-LISTEN:2055,fork,reuseaddr UDP4:127.0.0.1:1055
								detect_running_status2 socat 2055
							fi
						fi
					else
						echo_date "使用${VCORE_NAME}_dns作为chinadns-ng的上游DNS..."
						local FDNS1="127.0.0.1#1055"
					fi
				elif [ "${ss_basic_type}" == "5" ]; then
					# trojan
					if [ "${ss_basic_tcore}" == "1" ];then
						# trojan-xray
						if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
							echo_date "使用${TCORE_NAME}_dns作为chinadns-ng的上游DNS，并开启ECS..."
							local FDNS1="127.0.0.1#2055"
							if [ -n "${ss_real_server_ip}" ];then
								run_bg dns-ecs-forcer -p 2055 -s 127.0.0.1:1055 -e "${ss_real_server_ip%.*}.0"
								detect_running_status2 dns-ecs-forcer 2055
							else
								# 可能是中转服务器，没有确切的国外出口IP，此时先不开启ecs，等检测到国外出口IP后，再开启def
								# 先使用socat或者uredir将2055端口的请求转发到1055去
								if [ -z "$(which socat)" ];then
									echo_date "开启uredir，用于端口转发：1055 → 2055"
									uredir :2055 127.0.0.1:1055
									detect_running_status2 uredir 2055
								else
									echo_date "开启socat，用于端口转发：1055 → 2055"
									run_bg socat -T5 UDP4-LISTEN:2055,fork,reuseaddr UDP4:127.0.0.1:1055
									detect_running_status2 socat 2055
								fi
							fi
						else
							echo_date "使用${TCORE_NAME}_dns作为chinadns-ng的上游DNS..."
							local FDNS1="127.0.0.1#1055"
						fi
					fi
				fi
			fi

			# 7.2 tcp
			if [ "${ss_basic_chng_trust_1_opt}" == "2" ];then
				if [ -z "${ss_basic_chng_trust_1_opt_tcp_val}" ];then
					ss_basic_chng_trust_1_opt_tcp_val="1"
					ss_basic_chng_trust_1_ecs="1"
					dbus set ss_basic_chng_trust_1_opt_tcp_val="1"
					dbus set ss_basic_chng_trust_1_ecs="1"
				fi
			
				start_ss_local
				echo_date "开启dns2socks，作为chinadns-ng的可信上游DNS-1"
				if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
					local DNS2SOCKS_PORT="2055"
				else
					local DNS2SOCKS_PORT="1055"
				fi
				start_dns2socks $(get_dns_foreign ${ss_basic_chng_trust_1_opt_tcp_val} ${ss_basic_chng_trust_1_opt_tcp_val_user}):$(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_tcp_val} ${ss_basic_chng_trust_1_opt_tcp_val_user}) ${DNS2SOCKS_PORT} ${ss_basic_chng_trust_1_ecs}
				local FDNS1="127.0.0.1#${DNS2SOCKS_PORT}"
			fi
			
			# 7.3 doh
			if [ "${ss_basic_chng_trust_1_opt}" == "3" ];then
				start_dohclient_chng start frn1 ${ss_basic_chng_trust_1_opt_doh_val} ${ss_basic_chng_trust_1_ecs} 1
				if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
					local FDNS1="127.0.0.1#2055"
				else
					local FDNS1="127.0.0.1#2055"
				fi
			fi
		fi

		# 8. 生成chinadns-ng的可信DNS-2
		if [ "${ss_basic_chng_trust_2_enable}" == "1" ];then
			# 8.0 判断
			if [ "${ss_basic_chng_trust_2_opt}" == "1" -z "${ss_basic_chng_trust_2_opt_udp}" ];then
				echo_date "可信DNS-2自定义原生udp DNS服务器为空，自动切换：[直连] dohclient作为默认选项！"
				ss_basic_chng_trust_2_opt="2"
				dbus set ss_basic_chng_trust_2_opt="2"
			fi
			if [ "${ss_basic_chng_trust_2_opt}" == "2" -z "${ss_basic_chng_trust_2_opt_tcp}" ];then
				echo_date "可信DNS-2自定义原生tcp DNS服务器为空，自动切换：[直连] dohclient作为默认选项！"
				ss_basic_chng_trust_2_opt="2"
				dbus set ss_basic_chng_trust_2_opt="2"
			fi

			# 8.1 原生udp
			if [ "${ss_basic_chng_trust_2_opt}" == "1" ];then
				local TARGET_IP=$(echo "${ss_basic_chng_trust_2_opt_udp}"|awk -F"#|:" '{print $1}')
				local TARGET_IP=$(__valid_ip ${TARGET_IP})
				local TARGET_PT=$(echo "${ss_basic_chng_trust_2_opt_udp}"|awk -F"#|:" '{print $2}')
				local TARGET_PT=$(__valid_port ${TARGET_PT})

				if [ -z "${TARGET_PT}" ];then
					local TARGET_PT="53"
				fi

				if [ -n "${TARGET_IP}" ];then
					UDP_TARGET=${TARGET_IP}:${TARGET_PT}
					echo_date "使用原生UDP DNS服务器：${UDP_TARGET}作为可信DNS-2！"
					if [ "${ss_basic_chng_trust_2_ecs}" == "1" ];then
						if [ -n "${ss_real_server_ip}" ];then
							# dns request: udp → dnsmasq:53 → chinadns-ng:7913 → def(ecs):2056 → DNS server:${TARGET_PT}
							run_bg dns-ecs-forcer -p 2056 -s ${UDP_TARGET} -e "${ss_real_server_ip%.*}.0"
							detect_running_status2 dns-ecs-forcer 2056 slient
							local FDNS2="127.0.0.1#2056"
						else
							# 可能是中转服务器，没有确切的国外出口IP，此时先使用socat将2056端口转发到DNS服务器，等待获取到国外出口IP后再用dns-ecs-forcer替代socat
							# 如果没有socat就用uredir
							if [ -z "$(which socat)" ];then
								uredir :2056 ${UDP_TARGET}
								detect_running_status2 uredir 2055
							else
								run_bg socat -T5 UDP4-LISTEN:2056,fork,reuseaddr UDP4:${UDP_TARGET}
								detect_running_status2 socat 2055
							fi
							local FDNS2="127.0.0.1#2056"
						fi
					else
						local FDNS2="${TARGET_IP}#${TARGET_PT}"
					fi
				else
					echo_date "可信DNS-2自定义原生udp DNS服务器ip地址错误！自动切换：[直连] dohclient作为默认选项！"
					ss_basic_chng_trust_2_opt="2"
					dbus set ss_basic_chng_trust_2_opt="2"
				fi
			fi

			# 8.2 原生tcp
			if [ "${ss_basic_chng_trust_2_opt}" == "2" ];then
				local TARGET_IP=$(echo "${ss_basic_chng_trust_2_opt_tcp}"|awk -F"#|:" '{print $1}')
				local TARGET_IP=$(__valid_ip ${TARGET_IP})
				local TARGET_PT=$(echo "${ss_basic_chng_trust_2_opt_tcp}"|awk -F"#|:" '{print $2}')
				local TARGET_PT=$(__valid_port ${TARGET_PT})

				if [ -z "${TARGET_PT}" ];then
					local TARGET_PT="53"
				fi

				if [ -n "${TARGET_IP}" ];then
					TCP_TARGET=${TARGET_IP}:${TARGET_PT}
					if [ "${ss_basic_chng_trust_2_ecs}" == "1" ];then
						if [ -n "${ss_real_server_ip}" ];then
							# dns request: udp → dnsmasq:53 → chinadns-ng:7913 → def(ecs):2056 → dns2tcp:1056 → DNS server:${TARGET_PT}
							run_bg dns-ecs-forcer -p 2056 -s 127.0.0.1:1056 -e "${ss_real_server_ip%.*}.0"
							detect_running_status2 dns-ecs-forcer 2056 slient
						else
							# 可能是中转服务器，没有确切的国外出口IP，此时先使用socat将2056端口转发到DNS服务器，等待获取到国外出口IP后再用dns-ecs-forcer替代socat
							# 如果没有socat就用uredir
							if [ -z "$(which socat)" ];then
								echo_date "开启uredir，用于端口转发：1056 → 2056"
								uredir :2056 127.0.0.1:1056
								detect_running_status2 uredir 2056
							else
								echo_date "开启socat，用于端口转发：1056 → 2056"
								run_bg socat -T5 UDP4-LISTEN:2056,fork,reuseaddr UDP4:127.0.0.1:1056
								detect_running_status2 socat 2056
							fi
						fi
						run_bg dns2tcp -L"127.0.0.1#1056" -R"${TARGET_IP}#${TARGET_PT}"
						detect_running_status2 dns2tcp 1056 slient
						
						local FDNS2="127.0.0.1#2056"
					else
						run_bg dns2tcp -L"127.0.0.1#1056" -R"${TARGET_IP}#${TARGET_PT}"
						detect_running_status2 dns2tcp 1056 slient
						local FDNS2="127.0.0.1#1056"
					fi
				else
					echo_date "可信DNS-2自定义原生tcp DNS服务器ip地址错误！自动切换：[直连] dohclient作为默认选项！"
					ss_basic_chng_trust_2_opt="2"
					dbus set ss_basic_chng_trust_2_opt="2"
				fi
			fi
			
			# 8.3 start dohclient on port 1056/2056 (direct)
			if [ "${ss_basic_chng_trust_2_opt}" == "3" ];then

				if [ "${ss_basic_chng_trust_2_opt_doh}" == "97" ];then
					rm -rf /tmp/smartdns*
					echo_date "开启smartdns，作为chinadns-ng的可信上游DNS-2"
					start_smartdns smartdns_chng_direct
					local FDNS2="127.0.0.1#1056"
				else
					start_dohclient_chng start frn2 ${ss_basic_chng_trust_2_opt_doh} ${ss_basic_chng_trust_2_ecs} 0
					if [ "${ss_basic_chng_trust_2_ecs}" == "1" ];then
						local FDNS2="127.0.0.1#2056"
					else
						local FDNS2="127.0.0.1#1056"
					fi
				fi
			fi
		fi

		if [ -n "${FDNS1}" -a -n "${FDNS2}" ];then
			local FDNS="${FDNS1},${FDNS2}"
		elif [ -n "${FDNS1}" -a -z "${FDNS2}" ];then
			local FDNS="${FDNS1}"
		elif [ -z "${FDNS1}" -a -n "${FDNS2}" ];then
			local FDNS="${FDNS2}"
		fi

		# 9. start_chinadns-ng
		echo_date "开启chinadns-ng，用于【国内所有网站 + 国外所有网站】的DNS解析..."

		if [ "${ss_basic_chng_no_ipv6}" == "1" ];then
			if [ "${ss_basic_chng_act}" != "1" -a "${ss_basic_chng_gt}" != "1" -a "${ss_basic_chng_mc}" != "1" ];then
				ss_basic_chng_act="0"
				ss_basic_chng_gt="1"
				ss_basic_chng_mc="0"
			fi
			if [ "${ss_basic_chng_act}" == "1" ];then
				local EXT="${EXT} -N act"
			fi
			if [ "${ss_basic_chng_gt}" == "1" ];then
				local EXT="${EXT} -N gt"
			fi
			if [ "${ss_basic_chng_mc}" == "1" ];then
				local EXT="${EXT} -N mc"
			fi
		fi
		
		if [ "${DNS_PLAN}" == "1" ];then
			# match cdn.txt first, go to chn DNS;
			# then match gfwlist.txt, go to trust DNS
			# all domain have no match goes to chn DNS;
			run_bg chinadns-ng ${EXT} -l 7913 -c ${CDNS} -t ${FDNS} -g /tmp/gfwlist.txt -m /tmp/cdn.txt -d chn -M
		elif [ "${DNS_PLAN}" == "2" ];then
			# new (less dns leak, chn cdn depends on cdn.txt)
			# match cdn.txt first, go to chn DNS;
			# all domain have no match goes to trust DNS;
			# run_bg chinadns-ng ${EXT} -l 7913 -c ${CDNS} -t ${FDNS} -m /tmp/cdn.txt -d gfw
			# ------
			# use legacy
			run_bg chinadns-ng ${EXT} -l 7913 -c ${CDNS} -t ${FDNS} -g /tmp/gfwlist.txt -m /tmp/cdn.txt -M
		else
			# legacy (better chn cdn)
			# match cdn.txt first, go to chn DNS;
			# then match gfwlist.txt, go to trust DNS
			# all domain have no match goes to both chn DNS and trust DNS;
			run_bg chinadns-ng ${EXT} -l 7913 -c ${CDNS} -t ${FDNS} -g /tmp/gfwlist.txt -m /tmp/cdn.txt -M
		fi
		detect_running_status chinadns-ng
	elif [ "${ss_dns_plan}" == "2" ];then
		# default smartdns conf
		if [ -z "${ss_basic_smrt}" ];then
			ss_basic_smrt="1"
			dbus set ss_basic_smrt="1"
		fi

		echo_date "生成smartdns dns分流文件: /tmp/smart_cdn.txt，/tmp/smart_gfw.txt"
		cat /tmp/cdn.txt | sed 's/^/nameserver \//' | sed 's/$/\/chn/' >/tmp/smart_cdn.conf
		cat /tmp/gfwlist.txt | sed 's/^/nameserver \//' | sed 's/$/\/gfw/' >/tmp/smart_gfw.conf
	
		rm -rf /tmp/smartdns*
		rm -rf /var/run/smartdns*
		echo_date "开启【smartdns】配置-${ss_basic_smrt}，作为国内加国外域名解析DNS..."

		# dns2scosk needed
		if [ "${ss_basic_smrt}" == "1" -o "${ss_basic_smrt}" == "3" -o "${ss_basic_smrt}" == "4" -o "${ss_basic_smrt}" == "6" -o "${ss_basic_smrt}" == "7" -o "${ss_basic_smrt}" == "8" -o "${ss_basic_smrt}" == "9" ];then
			start_ss_local
			echo_date "先开启dns2socks，作为smartdns的上游..."
			start_dns2socks 8.8.8.8:53 1057 0
		fi
		
		if [ -f "/koolshare/ss/rules/smartdns_smrt_${ss_basic_smrt}_user.conf" ];then
			cp -rf /koolshare/ss/rules/smartdns_smrt_${ss_basic_smrt}_user.conf /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf
			run_bg smartdns -S -c /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf -p /var/run/smartdns_${ss_basic_smrt}.pid
		else
			cp -rf /koolshare/ss/rules/smartdns_smrt_${ss_basic_smrt}.conf /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf
			run_bg smartdns -S -c /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf -p /var/run/smartdns_${ss_basic_smrt}.pid
		fi
		
		# write isp dns to smartdns conf file
		if [ "${ss_basic_smrt}" -le "3" ];then
			if [ -n "${ISP_DNS1}" ]; then
				sed -i "s/114.114.114.114/${ISP_DNS1}/g" /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf
			fi
			
			if [ -n "${ISP_DNS2}" ]; then
				sed -i "s/114.114.115.115/${ISP_DNS2}/g" /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf
			else
				sed -i "/114.114.115.115/d" /tmp/upload/smartdns_smrt_${ss_basic_smrt}.conf
			fi
		fi
		
		detect_running_status smartdns "/var/run/smartdns_${ss_basic_smrt}.pid"
	elif [ "${ss_dns_plan}" == "3" ];then
		start_dohclient_main start
	fi
	echo_date "---------------------------------------------------------"
}

start_dns_old() {
	# 如果之前使用full版本，切换为lite后，某些dns选项没了
	if [ -z "${ss_foreign_dns}" ];then
		ss_foreign_dns="1"
		dbus set ss_foreign_dns="1"
	fi
	if [ "${ss_foreign_dns}" == "9" -a ! -x "/koolshare/bin/smartdns" ];then
		ss_foreign_dns="1"
		dbus set ss_foreign_dns="1"
	fi
	if [ "${ss_foreign_dns}" == "4" -a ! -x "/koolshare/bin/ss-tunnel" -a "${ss_basic_type}" == "0" ];then
		ss_dns_plan="1"
		dbus set ss_dns_plan="1"
	fi
	if [ "${ss_foreign_dns}" == "4" -a ! -x "/koolshare/bin/rss-tunnel" -a "${ss_basic_type}" == "1" ];then
		ss_dns_plan="1"
		dbus set ss_dns_plan="1"
	fi

	# 回国模式下强制改国外DNS为直连方式
	if [ "${ss_basic_mode}" == "6" ]; then
		if [ "${ss_basic_advdns}" == "1" ]; then
			echo_date "回国模式自动使用基础DNS设定"
			dbus set ss_basic_advdns="0"
			dbus set ss_basic_olddns="1"
		fi
		if [ "${ss_foreign_dns}" != "8" ]; then
			echo_date "检测到当前为回国模式，dns解析方案强制更改为直连模式..."
			ss_foreign_dns="8"
			dbus set ss_foreign_dns="8"
		fi
	fi

	# 从 3.2.3开始，插件要求所有代理都开启23456端口，用于状态检测
	start_ss_local

	# 3. Start DNS2SOCKS (default)
	if [ "${ss_foreign_dns}" == "3" -o -z "${ss_foreign_dns}" ]; then
		if [ -z "${ss_foreign_dns}" ]; then
			dbus set ss_foreign_dns="3"
		fi
		[ "${DNS_PLAN}" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
		[ "${DNS_PLAN}" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
		start_dns2socks ${ss_dns2socks_user} 7913 0
	fi

	# 4. Start ss-tunnel
	if [ "$ss_foreign_dns" == "4" ]; then
		if [ "${ss_basic_type}" == "1" ]; then
			[ "${DNS_PLAN}" == "1" ] && echo_date "开启ssr-tunnel，用于【国外gfwlist站点】的DNS解析..."
			[ "${DNS_PLAN}" == "2" ] && echo_date "开启ssr-tunnel，用于【国外所有网站】的DNS解析..."
			rss-tunnel -c $CONFIG_FILE -l 7913 -L $ss_sstunnel_user -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif [ "${ss_basic_type}" == "0" ]; then
			[ "${DNS_PLAN}" == "1" ] && echo_date "开启ss-tunnel，用于【国外gfwlist站点】的DNS解析..."
			[ "${DNS_PLAN}" == "2" ] && echo_date "开启ss-tunnel，用于【国外所有网站】的DNS解析..."
			if [ "${ss_basic_rust}" == "1" ];then
				sslocal ${ARG_RUST_TUNNEL} -f ${ss_sstunnel_user} ${ARG_OBFS} -u -d >/dev/null 2>&1
			else
				ss-tunnel -c ${CONFIG_FILE} -l 7913 -L ${ss_sstunnel_user} ${ARG_OBFS} -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		elif [ "${ss_basic_type}" == "3" -o "${ss_basic_type}" == "4" -o "${ss_basic_type}" == "5" ]; then
			echo_date $(__get_type_full_name ${ss_basic_type})下不支持ss-tunnel，改用dns2socks！
			dbus set ss_foreign_dns=3
			[ "${DNS_PLAN}" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "${DNS_PLAN}" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			start_dns2socks ${ss_dns2socks_user} 7913 0
		fi
	fi

	# 7. start v2ray dns
	if [ "$ss_foreign_dns" == "7" ]; then
		if [ "${ss_basic_type}" == "3" -o "${ss_basic_type}" == "4" ]; then
			return 0
		elif [ "${ss_basic_type}" == "5" -a "$ss_basic_tcore" == "1" ]; then
			return 0
		else
			echo_date "$(__get_type_full_name ${ss_basic_type})下不支持${VCORE_NAME} dns，改用dns2socks！"
			dbus set ss_foreign_dns=3
			[ "${DNS_PLAN}" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "${DNS_PLAN}" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			start_dns2socks ${ss_chinadnsng_user} 7913 0
		fi
	fi

	# 9. 开启SmartDNS
	if [ "${ss_china_dns}" == "98" -a "${ss_foreign_dns}" == "9" ]; then
		# 国内国外都启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式也不需要使用cdn.conf）
		[ "${DNS_PLAN}" == "1" ] && echo_date "开启SmartDNS，用于【国内所有网站 + 国外gfwlist站点】的DNS解析..."
		[ "${DNS_PLAN}" == "2" ] && echo_date "开启SmartDNS，用于【国内所有网站 + 国外所有网站】的DNS解析..."
		sed '/^#/d /^$/d' /koolshare/ss/rules/smartdns.conf > /tmp/smartdns.conf
		run_bg smartdns -c /tmp/smartdns.conf
	
	elif [ "${ss_china_dns}" == "98" -a "${ss_foreign_dns}" != "9" ]; then
		# 国内启用SmartDNS，国外不启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则是根据国外DNS的选择而决定是否使用cdn.conf）
		[ "${DNS_PLAN}" == "1" ] && echo_date "开启SmartDNS，用于【国内所有网站】的DNS解析..."
		[ "${DNS_PLAN}" == "2" ] && echo_date "开启SmartDNS，用于【国内cdn网站】的DNS解析..."
		sed '/^#/d /^$/d /foreign/d' /koolshare/ss/rules/smartdns.conf > /tmp/smartdns.conf
		run_bg smartdns -c /tmp/smartdns.conf
	elif [ "${ss_china_dns}" != "98" -a "${ss_foreign_dns}" == "9" ]; then
		# 国内不启用SmartDNS，国外启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则需要使用cdn.conf）
		[ "${DNS_PLAN}" == "1" ] && echo_date "开启SmartDNS，用于【国外gfwlist站点】的DNS解析..."
		[ "${DNS_PLAN}" == "2" ] && echo_date "开启SmartDNS，用于【国外所有网站】的DNS解析..."
		sed '/^#/d /^$/d /china/d' /koolshare/ss/rules/smartdns.conf > /tmp/smartdns.conf
		run_bg smartdns -c /tmp/smartdns.conf
	fi

	# 8. direct
	if [ "${ss_foreign_dns}" == "8" ]; then
		if [ "${ss_basic_mode}" == "6" ]; then
			echo_date "回国模式，国外DNS采用直连方案。"
		else
			echo_date "非回国模式，国外DNS直连解析不能使用，自动切换到dns2socks方案。"
			dbus set ss_foreign_dns=3
			[ "${DNS_PLAN}" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "${DNS_PLAN}" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			start_dns2socks ${ss_dns2socks_user} 7913 0
		fi
	fi
}
#--------------------------------------------------------------------------------------

detect_domain() {
	domain1=$(echo $1 | grep -E "^https://|^http://|/")
	domain2=$(echo $1 | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		return 1
	else
		return 0
	fi
}

get_dns_china(){
	local DNS_OPT=$1
	local DNS_OPT_USER=$2
	if [ "${DNS_OPT}" == "0" ];then
		CDN=""
	fi
	# 运营商DNS
	if [ "${DNS_OPT}" == "1" ]; then
		if [ -n "${ISP_DNS1}" ]; then
			local CDN="${ISP_DNS1}"
		else
			local CDN="114.114.114.114"
		fi
	fi
	if [ "${DNS_OPT}" == "2" ]; then
		if [ -n "${ISP_DNS2}" ]; then
			local CDN="${ISP_DNS2}"
		else
			local CDN="114.114.115.115"
		fi
	fi
	# 阿里DNS
	[ "${DNS_OPT}" == "3" ] && CDN="223.5.5.5"
	[ "${DNS_OPT}" == "4" ] && CDN="223.6.6.6"
	# DNSPod DNS
	[ "${DNS_OPT}" == "5" ] && CDN="119.29.29.29"
	[ "${DNS_OPT}" == "6" ] && CDN="119.28.28.28"
	# 114 DNS
	[ "${DNS_OPT}" == "7" ] && CDN="114.114.114.114"
	[ "${DNS_OPT}" == "8" ] && CDN="114.114.115.115"
	# OneDNS 拦截版 纯净版 家庭版
	[ "${DNS_OPT}" == "9" ] && CDN="117.50.11.11"
	[ "${DNS_OPT}" == "10" ] && CDN="52.80.66.66"
	[ "${DNS_OPT}" == "11" ] && CDN="117.50.10.10"
	[ "${DNS_OPT}" == "12" ] && CDN="52.80.52.52"
	[ "${DNS_OPT}" == "13" ] && CDN="117.50.60.30"
	[ "${DNS_OPT}" == "14" ] && CDN="52.80.60.30"		
	# 360安全DNS 电信/铁通/移动
	[ "${DNS_OPT}" == "15" ] && CDN="101.226.4.6"
	[ "${DNS_OPT}" == "16" ] && CDN="218.30.118.6"
	# cnnic DNS
	[ "${DNS_OPT}" == "17" ] && CDN="1.2.4.8"
	[ "${DNS_OPT}" == "18" ] && CDN="210.2.4.8"
	# 360安全DNS 联通
	[ "${DNS_OPT}" == "19" ] && CDN="123.125.81.6"
	[ "${DNS_OPT}" == "20" ] && CDN="140.207.198.6"
	# 百度DNS
	[ "${DNS_OPT}" == "21" ] && CDN="180.76.76.76"
	# 教育网DNS
	[ "${DNS_OPT}" == "22" ] && CDN="101.6.6.6"
	[ "${DNS_OPT}" == "23" ] && CDN="58.132.8.1"
	[ "${DNS_OPT}" == "24" ] && CDN="101.7.8.9"
	# smartdns
	[ "${DNS_OPT}" == "96" ] && CDN="127.0.0.1"
	[ "${DNS_OPT}" == "97" ] && CDN="127.0.0.1"
	[ "${DNS_OPT}" == "98" ] && CDN="127.0.0.1"
	# user defined dns
	if [ "${DNS_OPT}" == "99" ]; then
		if [ -n "${DNS_OPT_USER}" ];then
			local res_ip=$(echo "${DNS_OPT_USER}"|awk -F"#|:" '{print $1}')
			local res_ip=$(__valid_ip ${res_ip})
			if [ -n "${res_ip}" ];then
				CDN="${res_ip}"
			else
				CDN="114.114.114.114"
			fi
		else
			CDN="114.114.114.114"
		fi
	fi
	echo ${CDN}
}

get_dns_china_port(){
	local PORT_OPT=$1
	local PORT_OPT_USER=$2
	if [ "${PORT_OPT}" == "99" ];then
		if [ -n "${PORT_OPT_USER}" ];then
			local res_port=$(echo "${PORT_OPT_USER}"|awk -F"#|:" '{print $2}')
			local res_port=$(__valid_port ${res_port})
			if [ -n "${res_port}" ];then
				echo ${res_port}
			else
				echo 53
			fi
		else
			echo 53
		fi
	elif [ "${PORT_OPT}" == "98" ];then
		# smartdns udp
		echo 5445
	elif [ "${PORT_OPT}" == "97" ];then
		# smartdns tcp
		echo 5335
	elif [ "${PORT_OPT}" == "96" ];then
		# smartdns doh
		echo 5225
	elif [ "${PORT_OPT}" == "22" ];then
		echo 5353
	else
		echo 53
	fi
}

get_dns_foreign(){
	local DNS_OPT=$1
	local DNS_OPT_USER=$2
	local FDNS
	# Google DNS
	[ "${DNS_OPT}" == "1" ] && FDNS="8.8.8.8"
	[ "${DNS_OPT}" == "2" ] && FDNS="8.8.4.4"
	# cloudflare
	[ "${DNS_OPT}" == "3" ] && FDNS="1.1.1.1"
	[ "${DNS_OPT}" == "4" ] && FDNS="1.0.0.1"
	# Quad9 DNS
	[ "${DNS_OPT}" == "5" ] && FDNS="9.9.9.11"
	[ "${DNS_OPT}" == "6" ] && FDNS="149.112.112.11"
	# opendns
	[ "${DNS_OPT}" == "7" ] && FDNS="208.67.222.222"
	[ "${DNS_OPT}" == "8" ] && FDNS="208.67.220.220"
	# DNS.SB
	[ "${DNS_OPT}" == "9" ] && FDNS="185.222.222.222"
	[ "${DNS_OPT}" == "10" ] && FDNS="45.11.45.11"
	# adguard
	[ "${DNS_OPT}" == "11" ] && FDNS="94.140.14.14"
	[ "${DNS_OPT}" == "12" ] && FDNS="94.140.15.15"
	# quad 101
	[ "${DNS_OPT}" == "13" ] && FDNS="101.101.101.101"
	[ "${DNS_OPT}" == "14" ] && FDNS="101.102.103.104"
	# user defined dns
	[ "${DNS_OPT}" == "99" ] && {
		if [ -n "${DNS_OPT_USER}" ];then
			local res_ip=$(echo "${DNS_OPT_USER}"|awk -F"#|:" '{print $1}')
			local res_ip=$(__valid_ip ${res_ip})
			if [ -n "${res_ip}" ];then
				FDNS="${res_ip}"
			else
				FDNS="8.8.8.8"
			fi
		else
			FDNS="8.8.8.8"
		fi
	}
	echo ${FDNS}
}

get_dns_foreign_port(){
	local PORT_OPT=$1
	local PORT_OPT_USER=$2
	if [ "${PORT_OPT}" == "99" ];then
		if [ -n "${PORT_OPT_USER}" ];then
			local res_port=$(echo "${PORT_OPT_USER}"|awk -F"#|:" '{print $2}')
			local res_port=$(__valid_port ${res_port})
			if [ -n "${res_port}" ];then
				echo ${res_port}
			else
				echo 53
			fi
		else
			echo 53
		fi
	elif [ "${PORT_OPT}" == "6" ];then
		echo 5353
	else
		echo 53
	fi
}

get_dns_doh(){
	local idx=$1
	unset DOHNAME
	unset DOHADDR
	unset DOHHOST
	DOHPATH="/dns-query"
	case "${idx}" in
	1)
		# 阿里公共DNS
		DOHNAME="阿里公共DNS"
		DOHADDR="223.5.5.5:443"
		DOHHOST="dns.alidns.com"
		;;
	2)
		# DDNSPOD
		DOHNAME="DNSPod公共DNS"
		DOHADDR="1.12.12.12:443"
		DOHHOST="1.12.12.12"
		;;
	3)
		# 360
		DOHNAME="360安全DNS"
		DOHADDR="101.198.191.4:443"
		DOHHOST="doh.360.cn"
		;;
	11)
		# cloudflare
		DOHNAME="cloudflare"
		DOHADDR="1.1.1.1:443"
		DOHHOST="cloudflare-dns.com"
		;;
	12)
		# google
		DOHNAME="Google DNS"
		DOHADDR="8.8.8.8:443"
		DOHHOST="dns.google"
		;;
	13)
		# quad9
		DOHNAME="quad9"
		DOHADDR="149.112.112.11:443"
		DOHHOST="dns11.quad9.net"
		;;
	14)
		# adguard
		DOHNAME="adguard"
		DOHADDR="94.140.14.14:443"
		DOHHOST="dns.adguard.com"
		;;
	15)
		# quad 101
		DOHNAME="quad 101"
		DOHADDR="101.101.101.101:443"
		DOHHOST="dns.twnic.tw"
		;;
	16)
		# opendns
		DOHNAME="opendns"
		DOHADDR="146.112.41.2:443"
		DOHHOST="doh.opendns.com"
		;;
	17)
		# DNS.SB
		DOHNAME="DNS.SB"
		DOHADDR="185.222.222.222:443"
		DOHHOST="185.222.222.222"
		;;
	18)
		# cleanbrowsing
		DOHNAME="cleanbrowsing"
		DOHADDR="185.228.168.10:443"
		DOHHOST="doh.cleanbrowsing.org"
		DOHPATH="/doh/security-filter/"
		;;
	19)
		# he.net
		DOHNAME="he.net"
		DOHADDR="74.82.42.42:443"
		DOHHOST="ordns.he.net"
		;;
	20)
		# PureDNS
		DOHNAME="PureDNS"
		DOHADDR="146.190.6.13:443"
		DOHHOST="puredns.org"
		;;
	21)
		# dnslow
		DOHNAME="dnslow"
		DOHADDR="20.83.126.175:443"
		DOHHOST="dnslow.me"
		;;
	22)
		# dnswarden
		DOHNAME="dnswarden"
		DOHADDR="137.66.22.153:443"
		DOHHOST="dns.dnswarden.com"
		DOHPATH="/uncensored"
		;;
	23)
		# nextdns
		DOHNAME="nextdns"
		DOHADDR="45.90.30.0:443"
		DOHHOST="anycast.dns.nextdns.io"
		;;
	24)
		# bebasid
		DOHNAME="bebasid"
		DOHADDR="47.254.192.66:443"
		DOHHOST="dns.bebasid.com"
		;;
	25)
		# bebasid
		DOHNAME="AT&T"
		DOHADDR="40.76.112.230:443"
		DOHHOST="dohtrial.att.net"
		;;
	esac
}

create_dnsmasq_conf() {
	# 0. delete pre settings
	rm -rf /tmp/cdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/gfwlist.conf
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/scripts/dnsmasq.postconf
	rm -rf /tmp/smartdns.conf

	# copy gfwlist.conf to tmp
	if [ "${ss_basic_mode}" == "6" ];then
		cat /koolshare/ss/rules/gfwlist.conf | sed "s/127.0.0.1#7913/${ss_direct_user}/g" >>/tmp/gfwlist.conf
	else
		if [ "${ss_basic_advdns}" != "1" ]; then
			cp -rf /koolshare/ss/rules/gfwlist.conf /tmp/gfwlist.conf
		else
			cp -rf /koolshare/ss/rules/gfwlist.conf /tmp/gfwlist.conf
			sed -i '/^server=/d' /tmp/gfwlist.conf
		fi
	fi

	# copy gfwlist.txt & cdn.txt to tmp
	echo_date "创建/tmp/cdn.txt 和 /tmp/gfwlist.txt！"
	rm -rf /tmp/cdn.txt
	rm -rf /tmp/gfwlist.txt
	cp -rf /koolshare/ss/rules/cdn.txt /tmp/cdn.txt
	cat /koolshare/ss/rules/gfwlist.conf | sed '/^server=/d' | sed 's/ipset=\/.//g' | sed 's/\/gfwlist//g' >>/tmp/gfwlist.txt

	# 1. define CDN value
	if [ "${ss_basic_mode}" == "6" ];then
		# 如果是回国模式，先检查下CDN是否定义正确
		if [ "${ss_china_dns}" == "1" ];then
			# 检测并更正ISPDNS1
			if [ -n "${ISP_DNS1}" ];then
				local FO=$(awk -F'[./]' -v ip=${ISP_DNS1} ' {for (i=1;i<=int($NF/8);i++){a=a$i"."} if (index(ip, a)==1){split( ip, A, ".");b=int($NF/8);if (A[b+1]<($(NF+b-4)+2^(8-$NF%8))&&A[b+1]>=$(NF+b-4)) print ip,"belongs to",$0} a=""}' /koolshare/ss/rules/chnroute.txt)
				if [ -n "${FO}" ];then
					# 运营商DNS1:ISP_DNS1是中国IP
					CDN="${ISP_DNS1}"
				else
					# 运营商DNS1:ISP_DNS1是国外IP或者局域网IP，直接都改为中国的
					ss_china_dns="3"
					dbus set ss_china_dns="3"
				fi
			else
				ss_china_dns="3"
				dbus set ss_china_dns="3"
			fi
		fi
		if [ "${ss_china_dns}" == "2" ];then
			# 检测并更正ISPDNS2
			if [ -n "${ISP_DNS2}" ];then
				local FO=$(awk -F'[./]' -v ip=${ISP_DNS2} ' {for (i=1;i<=int($NF/8);i++){a=a$i"."} if (index(ip, a)==1){split( ip, A, ".");b=int($NF/8);if (A[b+1]<($(NF+b-4)+2^(8-$NF%8))&&A[b+1]>=$(NF+b-4)) print ip,"belongs to",$0} a=""}' /koolshare/ss/rules/chnroute.txt)
				if [ -n "${FO}" ];then
					# 运营商DNS1:ISP_DNS2是中国IP
					CDN="${ISP_DNS2}"
				else
					# 运营商DNS1:ISP_DNS2是国外IP或者局域网IP，直接都改为中国的
					ss_china_dns="3"
					dbus set ss_china_dns="3"
				fi
			else
				ss_china_dns="3"
				dbus set ss_china_dns="3"
			fi
		fi
		DNSC_PORT=$(get_dns_china_port ${ss_china_dns})
	else
		# 出国代理模式下，CDN定义
		if [ "${ss_basic_advdns}" != "1" ];then
			# basic dns settings
			CDN=$(get_dns_china ${ss_china_dns} ${ss_china_dns_user})
			DNSC_PORT=$(get_dns_china_port ${ss_china_dns})
		else
			# advanced dns settings
			CDN="127.0.0.1"
			DNSC_PORT="7913"
		fi
	fi

	# 2. custom dnsmasq settings by user
	if [ -n "${ss_dnsmasq}" ]; then
		echo_date "添加自定义dnsmasq设置到/tmp/custom.conf"
		echo "${ss_dnsmasq}" | base64_decode | sort -u >>/tmp/custom.conf
	fi

	# 3. sites need to go proxy inside router
	if [ "${ss_basic_online_links_goss}" == "1" ];then
		local NODES_DOMAINS=$(dbus get ss_online_links | base64_decode | sed 's/$/\n/' | sed '/^$/d' | sed '/^#/d' | grep -E "^http"|sed -e 's|^[^/]*//||' -e 's|/.*$||')
	else
		local NODES_DOMAINS=""
	fi

	if [ "${ss_basic_mode}" == "6" ]; then
		# 回国模式下，/koolshare/ss/rules/router.txt里的域名可以直连，所以不需要走代理
		local ROUTER_DOMAINS=""
	else
		local ROUTER_DOMAINS=$(cat /koolshare/ss/rules/router.txt)
	fi

	local ALL_ROUTER_DOMAIN="${NODES_DOMAINS} ${ROUTER_DOMAINS}"
	if [ -n "${ALL_ROUTER_DOMAIN}" ];then
		echo "# -------- for router itself --------" >>/tmp/wblist.conf
		for ROUTER_DOMAIN in ${ALL_ROUTER_DOMAIN}
		do
			# 1. 域名解析部分
			if [ "${ss_basic_advdns}" == "1" ];then
				if [ "${ss_dns_plan}" == "1" -o "${ss_dns_plan}" == "2" ];then
					# 需要走代理的域名，需要加入到chinadns-ng的黑名单中，以便用可信DNS进行解析
					echo ${ROUTER_DOMAIN} >> /tmp/gfwlist.txt
				fi
			else
				if [ "${DNS_PLAN}" == "1" ];then
					if [ "${ss_basic_mode}" == "6" ];then
						# 回国代理时：国内优先模式的时候，需要指定这些域名的解析为国内DNS
						echo "${ROUTER_DOMAIN}" | sed "s/^/server=&\/./g" | sed "s/$/\/${CDN}#${DNSC_PORT}/g" >>/tmp/wblist.conf
					else
						# 出国代理时：国内优先模式的时候，需要指定这些域名的解析端口为7913
						echo "${ROUTER_DOMAIN}" | sed "s/^/server=&\/./g" | sed "s/$/\/127\.0\.0\.1#7913/g" >>/tmp/wblist.conf
					fi
				fi
			fi
			# 2. ipset 规则部分，解析出的ip必须进入名为router的ipset集中
			echo "${ROUTER_DOMAIN}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/router/g" >>/tmp/wblist.conf
		done
	fi
	
	# 4.1 append udp black domain list for GPTmode, through proxy
	local GPT_DOMAINS=$(cat /koolshare/ss/rules/udplist.txt)
	if [ "${ss_basic_udpgpt}"  == "1" ];then
		echo "# -------- for udp --------" >>/tmp/wblist.conf
		for GPT_DOMAIN in ${GPT_DOMAINS}
		do
			echo "${GPT_DOMAIN}" | sed "s/^/server=&\/./g" | sed "s/$/\/127\.0\.0\.1#7913/g" >>/tmp/wblist.conf
			echo "${GPT_DOMAIN}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/chatgpt/g" >>/tmp/wblist.conf
		done
	fi

	# 4.2 append black domain list, through proxy
	local wanblackdomains=$(echo ${ss_wan_black_domain} | base64_decode)
	if [ "${ss_basic_proxy_newb}" == "1" ];then
		local wanblackdomains="${wanblackdomains} bing.com ipinfo.io ip.sb"
	fi
	if [ -n "${ss_wan_black_domain}" ]; then
		echo_date "生成域名黑名单！"
		echo "# -------- for black_domain --------" >>/tmp/wblist.conf
		for wan_black_domain in ${wanblackdomains}; do
			detect_domain "${wan_black_domain}"
			if [ "$?" == "0" ]; then
				# 1. 域名解析部分
				if [ "${ss_basic_advdns}" == "1" ];then
					if [ "${ss_dns_plan}" == "1" -o "${ss_dns_plan}" == "2" ];then
						# 需要走代理的域名，需要加入到chinadns-ng的黑名单中，以便用可信DNS进行解析
						echo ${wan_black_domain} >> /tmp/gfwlist.txt
					fi
				else
					if [ "${DNS_PLAN}" == "1" ];then
						if [ "${ss_basic_mode}" == "6" ];then
							echo "${wan_black_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/${ss_direct_user}/g" >>/tmp/wblist.conf
						else
							echo "${wan_black_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/127\.0\.0\.1#7913/g" >>/tmp/wblist.conf
						fi
					fi
				fi
				# 2. ipset 规则部分，解析出的ip必须进入名为router的ipset集中
				echo "${wan_black_domain}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >>/tmp/wblist.conf
			else
				echo_date "！！检测到域名黑名单内的【${wan_black_domain}】不是域名格式！！此条将不会添加！！"
			fi
		done
	fi
	
	# 5. append white domain list, not through proxy
	# gfwlist模式
	#    走代理的只有gfwlist名单内域名，所以不走代理就是希望其中一些域名不翻墙（且国内也访问不了），比如一些黄色网站，所以应该用国内DNS去解析
	#    但是用国内域名去解析的话，比如google等有DNS投毒的网站，会导致出现DNS污染，用户如果再次删掉这个域名白名单，PC等系统内还是会有污染ip，导致一段时间内无法通过代理连接
	#    如果用可信DNS去解析的话，得到的IP是无污染IP地址，国内同样无法访问。但是用户可能会很自信的在列表里加入一些国内域名，导致国内域名走了国外DNS解析！！！
	#    1. 依靠dnsmasq分流的方案下，直接使用server=去指定域名需要的解析DNS即可
	#    2. 依靠自身分流的方案，如chinadns-ng等，需要将指定域名添加进白名单即cdn.txt内，因为cdn.txt的优先级高于gfwlist
	#    3. 依靠自身分流的方案，如smartdns等，因其没有，需要在cdn.txt里添加域名，在gfwlist里删除域名
	# 大陆白名单模式
	#    走代理的除了cdn列表里的其它域名，假如有个国外域名用户希望能直连访问github，那么应该用国内DNS去解析，得到和不开插件一样的解析效果
	#    1. 依靠dnsmasq分流的方案下，直接使用server=去指定域名需要的解析DNS即可
	# 回国模式
	#    走代理的除了gfw列表里其其它域名，加入有个国外用户想直连访问国内的新浪微博，那么应该用国外DNS去解析，得到和不开插件一样的解析效果
	local ALL_NODE_DOMAINS=$(dbus list ssconf|grep _server_|awk -F"=" '{print $NF}'|sort -u|grep -Ev "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	local wanwhitedomains=$(echo ${ss_wan_white_domain} | base64_decode | sed '/^#/d' | grep "." | sort -u)
	local ALL_WHITE_DOMAINS=$(echo ${wanwhitedomains} ${ALL_NODE_DOMAINS})
	if [ -n "${ALL_WHITE_DOMAINS} " ]; then
		echo_date "生成域名白名单！"
		echo "# -------- for white_domain --------" >>/tmp/wblist.conf
		for wan_white_domain in ${ALL_WHITE_DOMAINS} ${ALL_NODE_DOMAINS}; do
			detect_domain "${wan_white_domain}"
			if [ "$?" == "0" ]; then
				if [ "${ss_basic_advdns}" == "1" ];then
					# chinadns-ng 用到cdn.txt
					if [ "${ss_dns_plan}" == "1" -o "${ss_dns_plan}" == "2" ];then
						# 域名白名单添加到cdn.txt，chinadns-ng需要白名单优先
						# local DOMAIN_EXIST_1=$(cat /tmp/cdn.txt | /bin/grep -Ew "^${wan_white_domain}")
						# if [ -z ${DOMAIN_EXIST_1} ];then
						# 	echo "${wan_white_domain}" >> /tmp/cdn.txt
						# else
						# 	echo_date "检测到域名白名单内的【${wan_white_domain}】已经被cdn.txt收录，跳过添加！！"
						# fi
						# 应该从gfwlist中删除对应域名
						echo "${wan_white_domain}" >> /tmp/cdn.txt
						local DOMAIN_EXIST_2=$(cat /tmp/gfwlist.txt | /bin/grep -Ew "^${wan_white_domain}")
						if [ -n ${DOMAIN_EXIST_2} ];then
							cat /tmp/gfwlist.txt | /bin/grep -Evw "^${wan_white_domain}" | run sponge /tmp/gfwlist.txt
						fi	
					fi
				else
					if [ "${DNS_PLAN}" == "1" ];then
						if [ "${ss_basic_mode}" == "6" ]; then
							echo "${wan_white_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/${ss_direct_user}/g" >>/tmp/wblist.conf
						else
							# 从gfwlist中移除
							local DOMAIN_EXIST_3=$(cat /tmp/gfwlist.conf | /bin/grep -Ew "/.${wan_white_domain}")
							if [ -n "${DOMAIN_EXIST_3}" ];then
								echo_date "域名白名单：从/tmp/gfwlist.conf移除域名：${wan_white_domain}"
								cat /tmp/gfwlist.conf | /bin/grep -Evw "/.${wan_white_domain}" | run sponge /tmp/gfwlist.conf
							fi
							# 方案2，用国外DNS，如果站点只有DNS投毒，没有tcp阻断，可能导致国内能直接访问
							# echo "${wan_white_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/127\.0\.0\.1#7913/g" >>/tmp/wblist.conf
						fi
					elif [ "${DNS_PLAN}" == "2" ];then
						# 方案1，用国内DNS，存在污染，去除白名单后难以恢复
						echo "${wan_white_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/${CDN}#${DNSC_PORT}/g" >>/tmp/wblist.conf
						# 方案2，用国外DNS，如果站点只有DNS投毒，没有tcp阻断，可能导致国内能直接访问
						# echo "${wan_white_domain}" | sed "s/^/server=&\/./g" | sed "s/$/\/127\.0\.0\.1#7913/g" >>/tmp/wblist.conf
					fi
				fi
				echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
			else
				echo_date "检测到域名白名单内的【${wan_white_domain}】不是域名格式！！此条将不会添加！！"
			fi
		done
	fi	

	# 非回国模式下，apple 和 microsoft需要中国cdn；
	# 另外：dns.msftncsi.com是asuswrt/merlin固件里，用以判断网络是否畅通的地址，固件后台会通过解析dns.msftncsi.com （nvram get dns_probe_content），并检查其解析结果是否和`nvram get dns_probe_content`匹配
	# 此地址在非回国模式下用国内DNS解析，以免SS/SSR/V2RAY线路挂掉，导致一些走远端解析的情况下，无法获取到dns.msftncsi.com的解析结果，从而使得【网络地图】中网络显示断开。
	if [ "${ss_basic_mode}" != "6" ]; then
		echo "#for special site (Mandatory China DNS)" >>/tmp/wblist.conf
		for wan_white_domain2 in "apple.com" "microsoft.com" "dns.msftncsi.com" "worldtimeapi.org"; do
			echo "${wan_white_domain2}" | sed "s/^/server=&\/./g" | sed "s/$/\/${CDN}#${DNSC_PORT}/g" >>/tmp/wblist.conf
			echo "${wan_white_domain2}" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
		done
	fi

	# 此处决定何时使用cdn.txt
	if [ "${ss_basic_advdns}" != "1" ]; then
		if [ "${ss_basic_mode}" == "6" ]; then
			# 回国模式中，因为国外DNS无论如何都不会污染的，所以采取的策略是直连就行，默认国内优先即可
			echo_date "自动判断在回国模式中使用国内优先模式，不加载cdn.conf"
		else
			if [ "${ss_basic_mode}" == "1" -a -z "${chn_on}" -a -z "${all_on}" -o "${ss_basic_mode}" == "6" ]; then
				# gfwlist模式的时候，且访问控制主机中不存在 大陆白名单模式 游戏模式 全局模式，则使用国内优先模式
				# 回国模式下自动判断使用国内优先
				echo_date "自动判断使用国内优先模式，不加载cdn.conf"
			else
				# 其它情况，均使用国外优先模式，以下区分是否加载cdn.conf
				echo_date "自动判断dns解析使用国外优先模式..."
				echo_date "生成cdn加速列表到/tmp/cdn.conf，加速用的dns：${CDN}"
				echo "#for china site CDN acclerate" >>/tmp/cdn.conf
				cat /tmp/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN#$DNSC_PORT/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/cdn.conf
			fi
		fi
	fi

	#ln_conf
	if [ -f /tmp/custom.conf ]; then
		#echo_date 创建域自定义dnsmasq配置文件软链接到/jffs/configs/dnsmasq.d/custom.conf
		ln -sf /tmp/custom.conf /jffs/configs/dnsmasq.d/custom.conf
	fi
	if [ -f /tmp/wblist.conf ]; then
		#echo_date 创建域名黑/白名单软链接到/jffs/configs/dnsmasq.d/wblist.conf
		ln -sf /tmp/wblist.conf /jffs/configs/dnsmasq.d/wblist.conf
	fi

	if [ -f /tmp/cdn.conf ]; then
		#echo_date 创建cdn加速列表软链接/jffs/configs/dnsmasq.d/cdn.conf
		ln -sf /tmp/cdn.conf /jffs/configs/dnsmasq.d/cdn.conf
	fi

	# 此处决定何时使用gfwlist.conf
	if [ "${ss_basic_mode}" == "1" ]; then
		echo_date "创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹."
		ln -sf /tmp/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	elif [ "${ss_basic_mode}" == "2" -o "${ss_basic_mode}" == "3" ]; then
		if [ -n "${gfw_on}" ]; then
			echo_date "创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹."
			ln -sf /tmp/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
		fi
	elif [ "${ss_basic_mode}" == "6" ]; then
		# 回国模式下默认方案是国内优先，所以gfwlist里的网站不能由127.0.0.1#7913来解析了，应该是国外当地直连
		if [ -n "$(echo ${ss_direct_user} | grep :)" ]; then
			echo_date "国外直连dns设定格式错误，将自动更正为8.8.8.8#53."
			ss_direct_user="8.8.8.8#53"
			dbus set ss_direct_user="8.8.8.8#53"
		fi
		echo_date "创建回国模式专用gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹."
		[ -z "${ss_direct_user}" ] && ss_direct_user="8.8.8.8#53"
		ln -sf /tmp/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	fi

	#echo_date 创建dnsmasq.postconf软连接到/jffs/scripts/文件夹.
	[ ! -L "/jffs/scripts/dnsmasq.postconf" ] && ln -sf /koolshare/ss/rules/dnsmasq.postconf /jffs/scripts/dnsmasq.postconf
}

auto_start() {
	[ ! -L "/koolshare/init.d/S99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/S99shadowsocks.sh
	[ ! -L "/koolshare/init.d/N99shadowsocks.sh" ] && ln -sf /koolshare/ss/ssconfig.sh /koolshare/init.d/N99shadowsocks.sh
}

start_kcp() {
	# Start kcp
	if [ "$ss_basic_use_kcp" == "1" ]; then
		echo_date 启动KCP协议进程，为了更好的体验，建议在路由器上创建虚拟内存.
		export GOGC=30
		[ -z "$ss_basic_kcp_server" ] && ss_basic_kcp_server="${ss_basic_server}"
		if [ "$ss_basic_kcp_method" == "1" ]; then
			[ -n "$ss_basic_kcp_encrypt" ] && KCP_CRYPT="--crypt $ss_basic_kcp_encrypt"
			[ -n "$ss_basic_kcp_password" ] && KCP_KEY="--key $ss_basic_kcp_password" || KCP_KEY=""
			[ -n "$ss_basic_kcp_sndwnd" ] && KCP_SNDWND="--sndwnd $ss_basic_kcp_sndwnd" || KCP_SNDWND=""
			[ -n "$ss_basic_kcp_rcvwnd" ] && KCP_RNDWND="--rcvwnd $ss_basic_kcp_rcvwnd" || KCP_RNDWND=""
			[ -n "$ss_basic_kcp_mtu" ] && KCP_MTU="--mtu $ss_basic_kcp_mtu" || KCP_MTU=""
			[ -n "$ss_basic_kcp_conn" ] && KCP_CONN="--conn $ss_basic_kcp_conn" || KCP_CONN=""
			[ "$ss_basic_kcp_nocomp" == "1" ] && COMP="--nocomp" || COMP=""
			[ -n "$ss_basic_kcp_mode" ] && KCP_MODE="--mode $ss_basic_kcp_mode" || KCP_MODE=""

			start-stop-daemon -S -q -b -m \
				-p /tmp/var/kcp.pid \
				-x /koolshare/bin/kcptun \
				-- -l 127.0.0.1:1091 \
				-r $ss_basic_kcp_server:$ss_basic_kcp_port \
				$KCP_CRYPT $KCP_KEY $KCP_SNDWND $KCP_RNDWND $KCP_MTU $KCP_CONN $COMP $KCP_MODE $ss_basic_kcp_extra
		else
			start-stop-daemon -S -q -b -m \
				-p /tmp/var/kcp.pid \
				-x /koolshare/bin/kcptun \
				-- -l 127.0.0.1:1091 \
				-r $ss_basic_kcp_server:$ss_basic_kcp_port \
				$ss_basic_kcp_parameter
		fi
	fi
}

start_speeder() {
	#只有游戏模式下或者访问控制中有游戏模式主机，且udp加速节点和当前使用节点一致
	if [ "$ss_basic_use_kcp" == "1" -a "$ss_basic_kcp_server" == "127.0.0.1" -a "$ss_basic_kcp_port" == "1092" ]; then
		echo_date 检测到你配置了KCP与UDPspeeder串联.
		SPEED_KCP=1
	fi

	if [ "$ss_basic_use_kcp" == "1" -a "$ss_basic_kcp_server" == "127.0.0.1" -a "$ss_basic_kcp_port" == "1093" ]; then
		echo_date 检测到你配置了KCP与UDP2raw串联.
		SPEED_KCP=2
	fi

	if [ "$mangle" == "1" -a "$ss_basic_udp_node" == "$ssconf_basic_node" -o "$SPEED_KCP" == "1" -o "$SPEED_KCP" == "2" ]; then
		#开启udpspeeder
		if [ "$ss_basic_udp_boost_enable" == "1" ]; then
			if [ "$ss_basic_udp_software" == "1" ]; then
				echo_date 开启UDPspeederV1进程.
				[ -z "$ss_basic_udpv1_rserver" ] && ss_basic_udpv1_rserver="${ss_basic_server}_ip"
				[ -n "$ss_basic_udpv1_duplicate_time" ] && duplicate_time="-t $ss_basic_udpv1_duplicate_time" || duplicate_time=""
				[ -n "$ss_basic_udpv1_jitter" ] && jitter="-j $ss_basic_udpv1_jitter" || jitter=""
				[ -n "$ss_basic_udpv1_report" ] && report="--report $ss_basic_udpv1_report" || report=""
				[ -n "$ss_basic_udpv1_drop" ] && drop="--random-drop $ss_basic_udpv1_drop" || drop=""
				[ -n "$ss_basic_udpv1_duplicate_nu" ] && duplicate="-d $ss_basic_udpv1_duplicate_nu" || duplicate=""
				[ -n "$ss_basic_udpv1_password" ] && key1="-k $ss_basic_udpv1_password" || key1=""
				[ "$ss_basic_udpv1_disable_filter" == "1" ] && filter="--disable-filter" || filter=""

				if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
					#串联：如果两者都开启了，则把udpspeeder的流udp量转发给udp2raw
					run_bg speederv1 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key1 $ss_basic_udpv1_password \
						$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					run_bg speederv1 -c -l 0.0.0.0:1092 -r $ss_basic_udpv1_rserver:$ss_basic_udpv1_rport $key1 \
						$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu
				fi
			elif [ "$ss_basic_udp_software" == "2" ]; then
				echo_date 开启UDPspeederV2进程.
				[ -z "$ss_basic_udpv2_rserver" ] && ss_basic_udpv2_rserver="${ss_basic_server}_ip"
				[ "$ss_basic_udpv2_disableobscure" == "1" ] && disable_obscure="--disable-obscure" || disable_obscure=""
				[ "$ss_basic_udpv2_disablechecksum" == "1" ] && disable_checksum="--disable-checksum" || disable_checksum=""
				[ -n "$ss_basic_udpv2_timeout" ] && timeout="--timeout $ss_basic_udpv2_timeout" || timeout=""
				[ -n "$ss_basic_udpv2_mode" ] && mode="--mode $ss_basic_udpv2_mode" || mode=""
				[ -n "$ss_basic_udpv2_report" ] && report="--report $ss_basic_udpv2_report" || report=""
				[ -n "$ss_basic_udpv2_mtu" ] && mtu="--mtu $ss_basic_udpv2_mtu" || mtu=""
				[ -n "$ss_basic_udpv2_jitter" ] && jitter="--jitter $ss_basic_udpv2_jitter" || jitter=""
				[ -n "$ss_basic_udpv2_interval" ] && interval="-interval $ss_basic_udpv2_interval" || interval=""
				[ -n "$ss_basic_udpv2_drop" ] && drop="-random-drop $ss_basic_udpv2_drop" || drop=""
				[ -n "$ss_basic_udpv2_password" ] && key2="-k $ss_basic_udpv2_password" || key2=""
				[ -n "$ss_basic_udpv2_fec" ] && fec="-f $ss_basic_udpv2_fec" || fec=""

				if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
					#串联：如果两者都开启了，则把udpspeeder的流udp量转发给udp2raw
					run_bg speederv2 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key2 \
						$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $disable_checksum $ss_basic_udpv2_other --fifo /tmp/fifo.file
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					run_bg speederv2 -c -l 0.0.0.0:1092 -r $ss_basic_udpv2_rserver:$ss_basic_udpv2_rport $key2 \
						$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $disable_checksum $ss_basic_udpv2_other --fifo /tmp/fifo.file
				fi
			fi
		fi
		#开启udp2raw
		if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
			echo_date 开启UDP2raw进程.
			[ -z "$ss_basic_udp2raw_rserver" ] && ss_basic_udp2raw_rserver="${ss_basic_server}_ip"
			[ "$ss_basic_udp2raw_a" == "1" ] && UD2RAW_EX1="-a" || UD2RAW_EX1=""
			[ "$ss_basic_udp2raw_keeprule" == "1" ] && UD2RAW_EX2="--keep-rule" || UD2RAW_EX2=""
			[ -n "$ss_basic_udp2raw_lowerlevel" ] && UD2RAW_LOW="--lower-level $ss_basic_udp2raw_lowerlevel" || UD2RAW_LOW=""
			[ -n "$ss_basic_udp2raw_password" ] && key3="-k $ss_basic_udp2raw_password" || key3=""

			run_bg udp2raw -c -l 0.0.0.0:1093 -r $ss_basic_udp2raw_rserver:$ss_basic_udp2raw_rport $key3 $UD2RAW_EX1 $UD2RAW_EX2 \
				--raw-mode $ss_basic_udp2raw_rawmode --cipher-mode $ss_basic_udp2raw_ciphermode --auth-mode $ss_basic_udp2raw_authmode \
				$UD2RAW_LOW $ss_basic_udp2raw_other
		fi
	fi
}

start_ss_redir() {
	if [ "${ss_basic_type}" == "1" ]; then
		echo_date "开启ssr-redir进程，用于透明代理."
		BIN=rss-redir
		ARG_OBFS=""
	elif [ "${ss_basic_type}" == "0" ]; then
		if [ "${ss_basic_rust}" == "1" ];then
			echo_date "开启shadowsocks-rust的sslocal进程，用于透明代理."
			BIN=sslocal
		else
			echo_date "开启ss-redir进程，用于透明代理."
			BIN=ss-redir
		fi
	fi

	if [ "$ss_basic_udp_boost_enable" == "1" ]; then
		#只要udpspeeder开启，不管udp2raw是否开启，均设置为1092,
		SPEED_PORT=1092
	else
		# 如果只开了udp2raw，则需要把udp转发到1093
		SPEED_PORT=1093
	fi

	if [ "$ss_basic_udp2raw_boost_enable" == "1" -o "$ss_basic_udp_boost_enable" == "1" ]; then
		#udp2raw开启，udpspeeder未开启则ss-redir的udp流量应该转发到1093
		SPEED_UDP=1
	fi

	if [ "$ss_basic_use_kcp" == "1" -a "$ss_basic_kcp_server" == "127.0.0.1" -a "$ss_basic_kcp_port" == "1092" ]; then
		SPEED_KCP=1
	fi

	if [ "$ss_basic_use_kcp" == "1" -a "$ss_basic_kcp_server" == "127.0.0.1" -a "$ss_basic_kcp_port" == "1093" ]; then
		SPEED_KCP=2
	fi
	# Start ss-redir
	if [ "$ss_basic_use_kcp" == "1" ]; then
		if [ "$mangle" == "1" ]; then
			if [ "$SPEED_UDP" == "1" -a "$ss_basic_udp_node" == "$ssconf_basic_node" ]; then
				# tcp go kcp
				if [ "$SPEED_KCP" == "1" ]; then
					echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
				elif [ "$SPEED_KCP" == "2" ]; then
					echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpraw
				else
					echo_date ${BIN}的 tcp 走kcptun.
				fi
				if [ "${ss_basic_type}" == "1" ]; then
					run rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
					else
						run ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
				# udp go udpspeeder
				[ "$ss_basic_udp2raw_boost_enable" == "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "$ss_basic_udp2raw_boost_enable" == "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走udpraw.
				[ "$ss_basic_udp2raw_boost_enable" != "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder.
				[ "$ss_basic_udp2raw_boost_enable" != "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走${BIN}.
				if [ "${ss_basic_type}" == "1" ]; then
					run rss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal -s "127.0.0.1:${SPEED_PORT}" ${ARG_RUST_REDIR_NS} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						run ss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
			else
				# tcp go kcp, udp go ss
				if [ "${SPEED_KCP}" == "1" ]; then
					echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
				elif [ "${SPEED_KCP}" == "2" ]; then
					echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpraw
				else
					echo_date ${BIN}的 tcp 走kcptun.
				fi
				
				if [ "${ss_basic_type}" == "1" ]; then
					run rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					run rss-redir -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
						run sslocal ${ARG_RUST_REDIR} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						run ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
						run ss-redir -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
			fi
		else
			# tcp only go kcp
			if [ "${SPEED_KCP}" == "1" ]; then
				echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpspeeder
			elif [ "${SPEED_KCP}" == "2" ]; then
				echo_date ${BIN}的 tcp 走kcptun, kcptun的 udp 走 udpraw
			else
				echo_date ${BIN}的 tcp 走kcptun.
			fi
			echo_date ${BIN}的 udp 未开启.
			if [ "${ss_basic_type}" == "1" ]; then
				run rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
			else
				if [ "${ss_basic_rust}" == "1" ];then
					run sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
				else
					run ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				fi
			fi
		fi
	else
		if [ "${mangle}" == "1" ]; then
			if [ "${SPEED_UDP}" == "1" -a "${ss_basic_udp_node}" == "${ssconf_basic_node}" ]; then
				# tcp go ss
				echo_date ${BIN}的 tcp 走${BIN}.
				if [ "${ss_basic_type}" == "1" ]; then
					run rss-redir -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
					else
						run ss-redir -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
				# udp go udpspeeder
				[ "${ss_basic_udp2raw_boost_enable}" == "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "${ss_basic_udp2raw_boost_enable}" == "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走udpraw.
				[ "${ss_basic_udp2raw_boost_enable}" != "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder.
				[ "${ss_basic_udp2raw_boost_enable}" != "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走${BIN}.

				if [ "${ss_basic_type}" == "1" ]; then
					run rss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						run ss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
			else
				# tcp udp go ss
				echo_date ${BIN}的 tcp 走${BIN}.
				echo_date ${BIN}的 udp 走${BIN}.
				if [ "${ss_basic_type}" == "1" ]; then
					fire_redir "rss-redir -c ${CONFIG_FILE} -u"
				else
					if [ "${ss_basic_rust}" == "1" ];then
						run sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" --udp-redir "tproxy" ${ARG_OBFS} -U -d >/dev/null 2>&1
					else
						fire_redir "ss-redir -c ${CONFIG_FILE} ${ARG_OBFS} -u"
					fi
				fi
			fi
		else
			# tcp only go ss
			echo_date ${BIN}的 tcp 走${BIN}.
			echo_date ${BIN}的 udp 未开启.
			if [ "${ss_basic_type}" == "1" ]; then
				fire_redir "rss-redir -c ${CONFIG_FILE}"
			else
				if [ "${ss_basic_rust}" == "1" ];then
					run sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
				else
					fire_redir "ss-redir -c ${CONFIG_FILE} ${ARG_OBFS}"
				fi
			fi
		fi
	fi
	echo_date ${BIN} 启动完毕！.

	start_speeder
}

fire_redir() {
	local ARG_1 ARG_2 ARG_3
	if [ "${ss_basic_type}" == "0" -a "$ss_basic_mcore" == "1" -a "${LINUX_VER}" != "26" ];then
		local ARG_1="--reuse-port"
	fi
	if [ "${ss_basic_type}" == "0" -a "$ss_basic_tfo" == "1" -a "${LINUX_VER}" != "26" ]; then
		local ARG_2="--fast-open"
		echo_date "$BIN开启tcp fast open支持."
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi

	if [ "${ss_basic_type}" == "0" -a "$ss_basic_tnd" == "1" ]; then
		echo_date "$BIN开启TCP_NODELAY支持."
		local ARG_3="--no-delay"
	fi

	if [ "$ss_basic_mcore" == "1" -a "${LINUX_VER}" != "26" ]; then
		echo_date "$BIN开启$THREAD线程支持."
		local i=1
		while [ $i -le $THREAD ]; do
			cmd $1 $ARG_1 $ARG_2 $ARG_3 -f /var/run/ss_$i.pid
			let i++
		done
	else
		cmd $1 -f /var/run/ss.pid
	fi
}

get_path_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"/\"]
	fi
}


get_host_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"\"]
	fi
}

get_function_switch() {
	case "$1" in
	1)
		echo "true"
		;;
	0 | *)
		echo "false"
		;;
	esac
}

get_reverse_switch() {
	case "$1" in
	1)
		echo "false"
		;;
	0|*)
		echo "true"
		;;
	esac
}

get_grpc_multimode(){
	case "$1" in
	multi)
		echo true
		;;
	gun|*)
		echo false
		;;
	esac
}

get_ws_header() {
	if [ -n "$1" ]; then
		echo {\"Host\": \"$1\"}
	else
		echo null
	fi
}

get_host() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo null
	fi
}


get_value_null(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo null
	fi
}

get_value_empty(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo \"\"
	fi
}

creat_v2ray_json() {
	if [ -n "$WAN_ACTION" ]; then
		echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	elif [ -n "$NAT_ACTION" ]; then
		echo_date "检测到防火墙重启触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	else
		echo_date "创建$(__get_type_abbr_name)配置文件到${V2RAY_CONFIG_FILE}"
	fi

	rm -rf "${V2RAY_CONFIG_TEMP}"
	rm -rf "${V2RAY_CONFIG_FILE}"
	if [ "${ss_basic_v2ray_use_json}" != "1" ]; then
		echo_date 生成${VCORE_NAME}配置文件...
		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"

		if [ "$ss_basic_v2ray_mux_enable" == "1" -a -z "$ss_basic_v2ray_mux_concurrency" ];then
			local ss_basic_v2ray_mux_concurrency=8
		fi

		if [ "$ss_basic_v2ray_mux_enable" != "1" ];then
			local ss_basic_v2ray_mux_concurrency="-1"
		fi
		
		if [ -z "$ss_basic_v2ray_network_security" ];then
			local ss_basic_v2ray_network_security="none"
		fi

		if [ "$ss_basic_v2ray_network_security" == "none" ];then
			ss_basic_v2ray_network_security_ai=""
			ss_basic_v2ray_network_security_alpn_h2=""
			ss_basic_v2ray_network_security_alpn_http=""
			ss_basic_v2ray_network_security_sni=""
		fi

		local alpn_h2=${ss_basic_v2ray_network_security_alpn_h2}
		local alpn_ht=${ss_basic_v2ray_network_security_alpn_http}

		if [ "${alpn_h2}" == "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"h2\",\"http/1.1\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"http/1.1\"]"
		elif [ "${alpn_h2}" == "1" -a "${alpn_ht}" != "1" ];then
			local apln="[\"h2\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" != "1" ];then
			local apln="null"
		fi

		# 如果sni空，host不空，用host代替
		if [ -z "${ss_basic_v2ray_network_security_sni}" ];then
			if [ -n "${ss_basic_v2ray_network_host}" ];then
				local ss_basic_v2ray_network_security_sni="${ss_basic_v2ray_network_host}"
			else
				local ss_basic_v2ray_network_security_sni=""
			fi
		fi

		# 如果sni空，host空，用server domain代替
		if [ -z "${ss_basic_v2ray_network_security_sni}" -a -z "${ss_basic_v2ray_network_host}" ];then
			# 判断是否域名，是就填入
			tmp=$(__valid_ip "${ss_basic_server_orig}")
			if [ $? == 0 ]; then
				# server is ip address format
				local ss_basic_v2ray_network_security_sni=""
			else
				# likely to be domain
				local ss_basic_v2ray_network_security_sni="${ss_basic_server_orig}"
			fi
		fi

		if [ "${ss_basic_v2ray_network_security}" == "tls" ];then
			local tls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_v2ray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_v2ray_network_security_sni)
					}"
		else
			local tls="null"
		fi

		# incase multi-domain input
		if [ "$(echo $ss_basic_v2ray_network_host | grep ",")" ]; then
			ss_basic_v2ray_network_host=$(echo $ss_basic_v2ray_network_host | sed 's/,/", "/g')
		fi

		case "$ss_basic_v2ray_network" in
		tcp)
			if [ "$ss_basic_v2ray_headtype_tcp" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(get_path_empty $ss_basic_v2ray_network_path)
					,\"headers\": {
					\"Host\": $(get_host_empty $ss_basic_v2ray_network_host),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$ss_basic_v2ray_headtype_kcp\"
				}
				,\"seed\": $(get_value_null $ss_basic_v2ray_kcp_seed)
				}"
			;;
		ws)
			if [ -z "$ss_basic_v2ray_network_path" -a -z "$ss_basic_v2ray_network_host" ]; then
				local ws="{}"
			elif [ -z "$ss_basic_v2ray_network_path" -a -n "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"headers\": $(get_ws_header $ss_basic_v2ray_network_host)
					}"
			elif [ -n "$ss_basic_v2ray_network_path" -a -z "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_v2ray_network_path)
					}"
			elif [ -n "$ss_basic_v2ray_network_path" -a -n "$ss_basic_v2ray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_v2ray_network_path),
					\"headers\": $(get_ws_header $ss_basic_v2ray_network_host)
					}"
			fi
			;;
		h2)

			local h2="{
				\"path\": $(get_value_empty $ss_basic_v2ray_network_path)
				,\"host\": $(get_host $ss_basic_v2ray_network_host)
				}"
			;;
		quic)
			local qc="{
				\"security\": $(get_value_empty $ss_basic_v2ray_network_host),
				\"key\": $(get_value_empty $ss_basic_v2ray_network_path),
				\"header\": {
				\"type\": \"${ss_basic_v2ray_headtype_quic}\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(get_value_empty $ss_basic_v2ray_network_path),
				\"multiMode\": $(get_grpc_multimode ${ss_basic_v2ray_grpc_mode})
				}"
			;;
		esac
		# log area
		cat >"${V2RAY_CONFIG_TEMP}" <<-EOF
			{
			"log": {
				"access": "none",
				"error": "none",
				"loglevel": "none"
			},
		EOF
		# inbounds area (7913 for dns resolve)
		if [ "${ss_basic_dns_flag}" == "1" ]; then
			echo_date 配置${VCORE_NAME} dns，用于dns解析...
			cat >>"${V2RAY_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "$(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user})",
						"port": $(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}),
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
						}
					},
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		else
			# inbounds area (23456 for socks5)
			cat >>"$V2RAY_CONFIG_TEMP" <<-EOF
				"inbounds": [
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		fi
		# outbounds area
		cat >>"$V2RAY_CONFIG_TEMP" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "vmess",
					"settings": {
						"vnext": [
							{
								"address": "${ss_basic_server}",
								"port": $ss_basic_port,
								"users": [
									{
										"id": "$ss_basic_v2ray_uuid"
										,"alterId": $ss_basic_v2ray_alterid
										,"security": "$ss_basic_v2ray_security"
									}
								]
							}
						]
					},
					"streamSettings": {
						"network": "$ss_basic_v2ray_network"
						,"security": "$ss_basic_v2ray_network_security"
						,"tlsSettings": $tls
						,"tcpSettings": $tcp
						,"kcpSettings": $kcp
						,"wsSettings": $ws
						,"httpSettings": $h2
						,"quicSettings": $qc
						,"grpcSettings": $gr
					},
					"mux": {
						"enabled": $(get_function_switch $ss_basic_v2ray_mux_enable),
						"concurrency": $ss_basic_v2ray_mux_concurrency
					}
				}
			]
			}
		EOF
		echo_date 解析${VCORE_NAME}配置文件...
		sed -i '/null/d' ${V2RAY_CONFIG_TEMP} 2>/dev/null
		run jq --tab . ${V2RAY_CONFIG_TEMP} >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . $V2RAY_CONFIG_TEMP >"$V2RAY_CONFIG_FILE"
		echo_date ${VCORE_NAME}配置文件写入成功到"$V2RAY_CONFIG_FILE"
	else
		echo_date "使用自定义的${VCORE_NAME} json配置文件..."
		echo "$ss_basic_v2ray_json" | base64_decode >"$V2RAY_CONFIG_TEMP"
		local OB=$(cat "$V2RAY_CONFIG_TEMP" | run jq .outbound)
		local OBS=$(cat "$V2RAY_CONFIG_TEMP" | run jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_TEMP" | run jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_TEMP" | run jq .outbounds[0])
		fi
		if [ "${ss_basic_dns_flag}" == "1" ]; then
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"protocol\": \"dokodemo-door\", 
										\"port\": ${DNSF_PORT},
										\"settings\": {
											\"address\": \"$(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user})\",
											\"port\": $(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}),
											\"network\": \"udp\",
											\"timeout\": 0,
											\"followRedirect\": false
										}
									},
									{
										\"port\": 23456,
										\"listen\": \"127.0.0.1\",
										\"protocol\": \"socks\",
										\"settings\": {
											\"auth\": \"noauth\",
											\"udp\": true,
											\"ip\": \"127.0.0.1\",
											\"clients\": null
										},
										\"streamSettings\": null
									},
									{
										\"listen\": \"0.0.0.0\",
										\"port\": 3333,
										\"protocol\": \"dokodemo-door\",
										\"settings\": {
											\"network\": \"tcp,udp\",
											\"followRedirect\": true
										}
									}
								]
							}"
		else
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"port\": 23456,
										\"listen\": \"127.0.0.1\",
										\"protocol\": \"socks\",
										\"settings\": {
											\"auth\": \"noauth\",
											\"udp\": true,
											\"ip\": \"127.0.0.1\",
											\"clients\": null
										},
										\"streamSettings\": null
									},
									{
										\"listen\": \"0.0.0.0\",
										\"port\": 3333,
										\"protocol\": \"dokodemo-door\",
										\"settings\": {
											\"network\": \"tcp,udp\",
											\"followRedirect\": true
										}
									}
								]
							}"
		fi
		echo_date "解析${VCORE_NAME}配置文件..."
		echo ${TEMPLATE} | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"$V2RAY_CONFIG_FILE"
		echo_date "${VCORE_NAME}配置文件写入成功到$V2RAY_CONFIG_FILE"

		# 检查v2ray json是否配置了xtls，如果是，则自动切换为xray
		if [ -f "/koolshare/ss/v2ray.json" ];then
			local IS_XTLS=$(cat /koolshare/ss/v2ray.json | run jq -r .outbounds[0].streamSettings.security 2>/dev/null)
			if [ "${IS_XTLS}" == "xtls" -a "${ss_basic_vcore}" != "1" ];then
				echo_date "ℹ️检测到你配置了支持xtls节点，而V2ray不支持xtls，自动切换为Xray核心！"
				ss_basic_vcore=1
				VCORE_NAME=Xray
				mv /koolshare/ss/v2ray.json /koolshare/ss/xray.json 
				V2RAY_CONFIG_FILE="/koolshare/ss/xray.json"
			fi
		fi

		# 检测用户json的服务器ip地址
		v2ray_protocal=$(cat "$V2RAY_CONFIG_FILE" | run jq -r .outbounds[0].protocol)
		case $v2ray_protocal in
		vmess|vless)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | run jq -r .outbounds[0].settings.vnext[0].address)
			;;
		socks)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | run jq -r .outbounds[0].settings.servers[0].address)
			;;
		shadowsocks)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | run jq -r .outbounds[0].settings.servers[0].address)
			;;
		*)
			v2ray_server=""
			;;
		esac

		if [ -n "${v2ray_server}" -a "${v2ray_server}" != "null" ]; then
			# 服务器地址强制由用户选择的DNS解析，以免插件还未开始工作而导致解析失败
			# 判断服务器域名格式
			local v2ray_server_tmp=$(__valid_ip ${v2ray_server})
			if [ -n "${v2ray_server_tmp}" ]; then
				# ip format
				echo_date "检测到你的json配置的${VCORE_NAME}服务器已经是IP格式：${v2ray_server}，跳过解析... "
				ss_basic_server_ip="${v2ray_server}"
			else
				echo_date "检测到你的json配置的${VCORE_NAME}服务器：【${v2ray_server}】不是ip格式！"
				__resolve_server_domain "${v2ray_server}"
				case $? in
				0)
					# server is domain format and success resolved.
					echo_date "${VCORE_NAME}服务器的ip地址解析成功：$SERVER_IP"
					# 解析并记录一次ip，方便插件触发重启设定工作
					echo "address=/${v2ray_server}/${SERVER_IP}" >/tmp/ss_host.conf
					# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
					#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
					ss_basic_server_orig="${v2ray_server}"
					ss_basic_server_ip="${SERVER_IP}"
					;;
				1)
					# server is domain format and failed to resolve.
					unset ss_basic_server_ip
					echo_date "${VCORE_NAME}服务器的ip地址解析失败!插件将继续运行，域名解析将由${VCORE_NAME}自己进行！"
					echo_date "请自行将${VCORE_NAME}服务器的ip地址填入IP/CIDR白名单中!"
					echo_date "为了确保${VCORE_NAME}的正常工作，建议配置ip格式的${VCORE_NAME}服务器地址！"
					;;
				2)
					# server is not ip either domain!
					echo_date "错误3！！检测到json配置内的${VCORE_NAME}服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
					echo_date "请更正你的错误然后重试！！"
					close_in_five flag
					;;
				esac
			fi
			# write v2ray server
			dbus set ssconf_basic_server_${ssconf_basic_node}=${v2ray_server}
		else
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+       没有检测到你的${VCORE_NAME}服务器地址，如果你确定你的配置是正确的        +"
			echo_date "+   请自行将${VCORE_NAME}服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用   +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		fi
	fi

	if [ "${ss_basic_vcore}" == "1" ];then
		# test v2ray Configuration generated from user json then run by xray
		echo_date "测试${VCORE_NAME}配置文件...."
		test_xray_conf $V2RAY_CONFIG_FILE
		case $? in
		0)
			echo_date "测试结果：${_test_ret}"
			echo_date "${VCORE_NAME}配置文件通过测试!!!"
			;;
		2)
			echo_date "测试结果：${_test_ret}"
			echo_date "${VCORE_NAME}配置文件没有通过测试，尝试删除fingerprint配置后重试！"
			run jq 'del(.. | .fingerprint?)' $V2RAY_CONFIG_FILE | run sponge $V2RAY_CONFIG_FILE
			test_xray_conf $V2RAY_CONFIG_FILE
			case $? in
			0)
				echo_date "测试结果：${_test_ret}"
				echo_date "${VCORE_NAME}配置文件通过测试!!!"
				;;
			*)
				echo_date "测试结果：${_test_ret}"
				echo_date "${VCORE_NAME}配置文件没有通过测试，请检查设置!!!"
				rm -rf "$V2RAY_CONFIG_TEMP"
				rm -rf "$V2RAY_CONFIG_FILE"
				close_in_five flag
				;;
			esac
			;;
		*)
			echo_date "测试结果：${_test_ret}"
			echo_date "${VCORE_NAME}配置文件没有通过测试，请检查设置!!!"
			rm -rf "$V2RAY_CONFIG_TEMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five flag
			;;
		esac
	else
		echo_date "测试${VCORE_NAME}配置文件...."
		cd /koolshare/bin
		#result=$(v2ray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		result=$(run v2ray test -c "$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		if [ -n "$result" ]; then
			echo_date $result
			echo_date "${VCORE_NAME}配置文件通过测试!!!"
		else
			echo_date "${VCORE_NAME}配置文件没有通过测试，请检查设置!!!"
			rm -rf "$V2RAY_CONFIG_TEMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five flag
		fi
	fi
}

start_v2ray() {
	# tfo start
	if [ "$ss_basic_tfo" == "1" -a "${LINUX_VER}" != "26" ]; then
		echo_date "开启tcp fast open支持."
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi
	if [ "${ss_basic_vcore}" == "1" ];then
		# xray start
		if [ "${ss_basic_xguard}" == "1" ];then
			echo_date "开启Xray主进程 + Xray守护..."
			# use perp to start xray
			mkdir -p /koolshare/perp/xray/
			cat >/koolshare/perp/xray/rc.main <<-EOF
				#!/bin/sh
				source /koolshare/scripts/base.sh
				CMD="xray run -c /koolshare/ss/xray.json"
				
				exec 2>&1
				exec \$CMD
				
			EOF
			chmod +x /koolshare/perp/xray/rc.main
			chmod +t /koolshare/perp/xray/
			sync
			perpctl A xray >/dev/null 2>&1
			perpctl u xray >/dev/null 2>&1
		else
			echo_date "开启Xray主进程..."
			cd /koolshare/bin
			run_bg xray run -c ${V2RAY_CONFIG_FILE}
		fi
		detect_running_status xray
	else
		# v2ray start
		echo_date "开启V2ray主进程..."
		cd /koolshare/bin
		#run_bg v2ray --config=${V2RAY_CONFIG_FILE}
		run_bg v2ray run -c ${V2RAY_CONFIG_FILE}
		detect_running_status2 v2ray ${V2RAY_CONFIG_FILE}
	fi
}

creat_xray_json() {
	if [ -n "${WAN_ACTION}" ]; then
		echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	elif [ -n "${NAT_ACTION}" ]; then
		echo_date "检测到防火墙重启触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	else
		echo_date "创建$(__get_type_abbr_name)配置文件到${XRAY_CONFIG_FILE}"
	fi

	local tmp xray_server_ip
	rm -rf "${XRAY_CONFIG_TEMP}"
	rm -rf "${XRAY_CONFIG_FILE}"
	if [ "${ss_basic_xray_use_json}" != "1" ]; then
		echo_date 生成Xray配置文件...
		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"
		local xtls="null"
		local reali="null"

		if [ -z "$ss_basic_xray_network_security" ];then
			local ss_basic_xray_network_security="none"
		fi

		if [ "${ss_basic_xray_network_security}" == "none" ];then
			ss_basic_xray_flow=""
			ss_basic_xray_network_security_ai=""
			ss_basic_xray_network_security_alpn_h2=""
			ss_basic_xray_network_security_alpn_http=""
			ss_basic_xray_network_security_sni=""
		fi

		#if [ "${ss_basic_xray_network_security}" == "tls" ];then
		#	ss_basic_xray_flow=""
		#fi

		local alpn_h2=${ss_basic_xray_network_security_alpn_h2}
		local alpn_ht=${ss_basic_xray_network_security_alpn_http}
		if [ "${alpn_h2}" == "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"h2\",\"http/1.1\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" == "1" ];then
			local apln="[\"http/1.1\"]"
		elif [ "${alpn_h2}" == "1" -a "${alpn_ht}" != "1" ];then
			local apln="[\"h2\"]"
		elif [ "${alpn_h2}" != "1" -a "${alpn_ht}" != "1" ];then
			local apln="null"
		fi

		# 如果sni空，host不空，用host代替
		if [ -z "${ss_basic_xray_network_security_sni}" ];then
			if [ -n "${ss_basic_xray_network_host}" ];then
				local ss_basic_xray_network_security_sni="${ss_basic_xray_network_host}"
			else
				local ss_basic_xray_network_security_sni=""
			fi
		fi

		# 如果sni空，host空，用server domain代替
		if [ -z "${ss_basic_xray_network_security_sni}" -a -z "${ss_basic_xray_network_host}" ];then
			# 判断是否域名，是就填入
			tmp=$(__valid_ip "${ss_basic_server_orig}")
			if [ $? == 0 ]; then
				# server is ip address format
				local ss_basic_xray_network_security_sni=""
			else
				# likely to be domain
				local ss_basic_xray_network_security_sni="${ss_basic_server_orig}"
			fi
		fi

		if [ "${ss_basic_xray_network_security}" == "tls" ];then
			if [ -z "${ss_basic_xray_fingerprint}" ];then
				echo_date "fingerprint为空，默认使用chrome作为指纹"
				ss_basic_xray_fingerprint="chrome"
				dbus set ssconf_basic_xray_fingerprint_${cur_node}="chrome"
			fi
			local tls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_xray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					,\"fingerprint\": $(get_value_empty $ss_basic_xray_fingerprint)
					}"
		else
			local tls="null"
		fi

		if [ "${ss_basic_xray_network_security}" == "xtls" ];then
			if [ -z "${ss_basic_xray_fingerprint}" ];then
				echo_date "fingerprint为空，默认使用chrome作为指纹"
				ss_basic_xray_fingerprint="chrome"
				dbus set ssconf_basic_xray_fingerprint_${cur_node}="chrome"
			fi
			local xtls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_xray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					,\"fingerprint\": $(get_value_empty $ss_basic_xray_fingerprint)
					}"
		else
			local xtls="null"
		fi

		if [ "${ss_basic_xray_network_security}" == "reality" ];then
			local reali="{
					\"show\": $(get_function_switch $ss_basic_xray_show)
					,\"fingerprint\": $(get_value_empty $ss_basic_xray_fingerprint)
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					,\"publicKey\": $(get_value_null $ss_basic_xray_publickey)
					,\"shortId\": $(get_value_empty $ss_basic_xray_shortid)
					,\"spiderX\": $(get_value_empty $ss_basic_xray_spiderx)
					}"
		else
			local reali="null"		
		fi
		# incase multi-domain input
		if [ "$(echo $ss_basic_xray_network_host | grep ",")" ]; then
			ss_basic_xray_network_host=$(echo ${ss_basic_xray_network_host} | sed 's/,/", "/g')
		fi

		case "${ss_basic_xray_network}" in
		tcp)
			if [ "${ss_basic_xray_headtype_tcp}" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(get_path_empty $ss_basic_xray_network_path)
					,\"headers\": {
					\"Host\": $(get_host_empty $ss_basic_xray_network_host),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$ss_basic_xray_headtype_kcp\"
				}
				,\"seed\": $(get_value_null $ss_basic_xray_kcp_seed)
				}"
			;;
		ws)
			if [ -z "$ss_basic_xray_network_path" -a -z "$ss_basic_xray_network_host" ]; then
				local ws="{}"
			elif [ -z "$ss_basic_xray_network_path" -a -n "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"headers\": $(get_ws_header $ss_basic_xray_network_host)
					}"
			elif [ -n "$ss_basic_xray_network_path" -a -z "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_xray_network_path)
					}"
			elif [ -n "$ss_basic_xray_network_path" -a -n "$ss_basic_xray_network_host" ]; then
				local ws="{
					\"path\": $(get_value_null $ss_basic_xray_network_path),
					\"headers\": $(get_ws_header $ss_basic_xray_network_host)
					}"
			fi
			;;
		h2)
			local h2="{
				\"path\": $(get_value_empty $ss_basic_xray_network_path)
				,\"host\": $(get_host $ss_basic_xray_network_host)
				}"
			;;
		quic)
			local qc="{
				\"security\": $(get_value_empty $ss_basic_xray_network_host),
				\"key\": $(get_value_empty $ss_basic_xray_network_path),
				\"header\": {
				\"type\": \"${ss_basic_xray_headtype_quic}\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(get_value_empty $ss_basic_xray_network_path),
				\"multiMode\": $(get_grpc_multimode ${ss_basic_xray_grpc_mode})
				}"
			;;
		esac
		# log area
		cat >"${XRAY_CONFIG_TEMP}" <<-EOF
			{
			"log": {
				"access": "none",
				"error": "none",
				"loglevel": "none"
			},
		EOF
		# inbounds area (7913 for dns resolve)
		if [ "${ss_basic_dns_flag}" == "1" ]; then
			echo_date 配置xray dns，用于dns解析...
			cat >>"${XRAY_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "$(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user})",
						"port": $(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}),
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
						}
					},
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		else
			# inbounds area (23456 for socks5)
			cat >>"${XRAY_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		fi
		# outbounds area
		[ -z "${ss_basic_xray_alterid}" ] && ss_basic_xray_alterid="0"
		[ -z "${ss_basic_xray_prot}" ] && ss_basic_xray_prot="vless"
		cat >>"${XRAY_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "${ss_basic_xray_prot}",
					"settings": {
						"vnext": [
							{
								"address": "${ss_basic_server}",
								"port": ${ss_basic_port},
								"users": [
									{
										"id": "$ss_basic_xray_uuid"
										,"alterId": $ss_basic_xray_alterid
										,"security": "auto"
										,"encryption": "$ss_basic_xray_encryption"
										,"flow": $(get_value_null $ss_basic_xray_flow)
									}
								]
							}
						]
					},
					"streamSettings": {
						"network": "$ss_basic_xray_network"
						,"security": "$ss_basic_xray_network_security"
						,"tlsSettings": $tls
						,"xtlsSettings": $xtls
						,"realitySettings": $reali
						,"tcpSettings": $tcp
						,"kcpSettings": $kcp
						,"wsSettings": $ws
						,"httpSettings": $h2
						,"quicSettings": $qc
						,"grpcSettings": $gr
						,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_tfo})}
					},
					"mux": {
						"enabled": false,
						"concurrency": -1
					}
				}
			]
			}
		EOF
		echo_date "解析Xray配置文件..."
		sed -i '/null/d' ${XRAY_CONFIG_TEMP} 2>/dev/null
		if [ "${ss_basic_xray_prot}" == "vless" ];then
			sed -i '/alterId/d' ${XRAY_CONFIG_TEMP} 2>/dev/null
		fi
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' ${XRAY_CONFIG_TEMP} 2>/dev/null
		fi
		run jq --tab . $XRAY_CONFIG_TEMP >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . ${XRAY_CONFIG_TEMP} >${XRAY_CONFIG_FILE}
		echo_date "Xray配置文件写入成功到${XRAY_CONFIG_FILE}"

	else
		echo_date "使用自定义的Xray json配置文件..."
		echo "$ss_basic_xray_json" | base64_decode >"$XRAY_CONFIG_TEMP"
		local OB=$(cat "$XRAY_CONFIG_TEMP" | run jq .outbound)
		local OBS=$(cat "$XRAY_CONFIG_TEMP" | run jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$XRAY_CONFIG_TEMP" | run jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$XRAY_CONFIG_TEMP" | run jq .outbounds[0])
		fi
		if [ "${ss_basic_dns_flag}" == "1" ]; then
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"protocol\": \"dokodemo-door\", 
										\"port\": ${DNSF_PORT},
										\"settings\": {
											\"address\": \"$(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user})\",
											\"port\": $(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}),
											\"network\": \"udp\",
											\"timeout\": 0,
											\"followRedirect\": false
										}
									},
									{
										\"port\": 23456,
										\"listen\": \"127.0.0.1\",
										\"protocol\": \"socks\",
										\"settings\": {
											\"auth\": \"noauth\",
											\"udp\": true,
											\"ip\": \"127.0.0.1\",
											\"clients\": null
										},
										\"streamSettings\": null
									},
									{
										\"listen\": \"0.0.0.0\",
										\"port\": 3333,
										\"protocol\": \"dokodemo-door\",
										\"settings\": {
											\"network\": \"tcp,udp\",
											\"followRedirect\": true
										}
									}
								]
							}"
		else
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"port\": 23456,
										\"listen\": \"127.0.0.1\",
										\"protocol\": \"socks\",
										\"settings\": {
											\"auth\": \"noauth\",
											\"udp\": true,
											\"ip\": \"127.0.0.1\",
											\"clients\": null
										},
										\"streamSettings\": null
									},
									{
										\"listen\": \"0.0.0.0\",
										\"port\": 3333,
										\"protocol\": \"dokodemo-door\",
										\"settings\": {
											\"network\": \"tcp,udp\",
											\"followRedirect\": true
										}
									}
								]
							}"
		fi
		echo_date "解析Xray配置文件..."
		echo ${TEMPLATE} | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"${XRAY_CONFIG_FILE}"
		echo_date "Xray配置文件写入成功到${XRAY_CONFIG_FILE}"

		# 检测用户json的服务器ip地址
		xray_protocal=$(cat "${XRAY_CONFIG_FILE}" | run jq -r .outbounds[0].protocol)
		case ${xray_protocal} in
		vmess|vless)
			xray_server=$(cat "${XRAY_CONFIG_FILE}" | run jq -r .outbounds[0].settings.vnext[0].address)
			;;
		socks|shadowsocks|trojan)
			xray_server=$(cat "${XRAY_CONFIG_FILE}" | run jq -r .outbounds[0].settings.servers[0].address)
			;;
		*)
			xray_server=""
			;;
		esac

		if [ -n "${xray_server}" -a "${xray_server}" != "null" ]; then
			# 服务器地址强制由用户选择的DNS解析，以免插件还未开始工作而导致解析失败
			# 判断服务器域名格式
			local xray_server_tmp=$(__valid_ip ${xray_server})
			if [ -n "${xray_server_tmp}" ]; then
				echo_date "检测到你的json配置的Xray服务器是已经是IP格式：${xray_server}，跳过解析... "
				ss_basic_server_ip="${xray_server}"
			else
				echo_date "检测到你的json配置的Xray服务器：【${xray_server}】不是ip格式！"
				__resolve_server_domain "${xray_server}"
				case $? in
				0)
					# server is domain format and success resolved.
					echo_date "Xray服务器的ip地址解析成功：${SERVER_IP}"
					# 解析并记录一次ip，方便插件触发重启设定工作
					echo "address=/${xray_server}/${SERVER_IP}" >/tmp/ss_host.conf
					# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
					#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
					ss_basic_server_orig="${xray_server}"
					ss_basic_server_ip="${SERVER_IP}"
					;;
				1)
					# server is domain format and failed to resolve.
					unset ss_basic_server_ip
					echo_date "Xray服务器的ip地址解析失败!插件将继续运行，域名解析将由Xray自己进行！"
					echo_date "请自行将Xray服务器的ip地址填入IP/CIDR白名单中!"
					echo_date "为了确保Xray的正常工作，建议配置ip格式的Xray服务器地址！"
					;;
				2)
					echo_date "错误1！！检测到json配置内的Xray服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
					echo_date "请更正你的错误然后重试！！"
					close_in_five flag
					;;
				esac
			fi
			# write xray server
			dbus set ssconf_basic_server_${ssconf_basic_node}=${xray_server}
		else
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "+       没有检测到你的Xray服务器地址，如果你确定你的配置是正确的        +"
			echo_date "+   请自行将Xray服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用   +"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		fi
	fi
	
	# test xray Configuration run by xray
	test_xray_conf $XRAY_CONFIG_FILE
	case $? in
	0)
		echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件通过测试!!!"
		;;
	2)
		#echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件没有通过测试，尝试删除fingerprint配置后重试！"
		run jq 'del(.. | .fingerprint?)' $XRAY_CONFIG_FILE | run sponge $XRAY_CONFIG_FILE
		test_xray_conf $XRAY_CONFIG_FILE
		case $? in
		0)
			echo_date "测试结果：${_test_ret}"
			echo_date "Xray配置文件通过测试!!!"
			;;
		*)
			echo_date "测试结果：${_test_ret}"
			echo_date "Xray配置文件没有通过测试，请检查设置!!!"
			rm -rf "$XRAY_CONFIG_TEMP"
			rm -rf "$XRAY_CONFIG_FILE"
			close_in_five flag
			;;
		esac
		;;
	*)
		echo_date "测试结果：${_test_ret}"
		echo_date "Xray配置文件没有通过测试，请检查设置!!!"
		rm -rf "$XRAY_CONFIG_TEMP"
		rm -rf "$XRAY_CONFIG_FILE"
		close_in_five flag
		;;
	esac
}

start_xray() {
	# tfo start
	if [ "${LINUX_VER}" != "26" ]; then
		if [ "$ss_basic_tfo" == "1" ]; then
			echo_date 开启tcp fast open支持.
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			echo 1 >/proc/sys/net/ipv4/tcp_fastopen
		fi
	fi
	# xray start
	if [ "${ss_basic_xguard}" == "1" ];then
		echo_date "开启Xray主进程 + Xray守护..."
		# use perp to start xray
		mkdir -p /koolshare/perp/xray/
		cat >/koolshare/perp/xray/rc.main <<-EOF
			#!/bin/sh
			source /koolshare/scripts/base.sh
			CMD="xray run -c /koolshare/ss/xray.json"
			
			exec 2>&1
			exec \$CMD
			
		EOF
		chmod +x /koolshare/perp/xray/rc.main
		chmod +t /koolshare/perp/xray/
		sync
		perpctl A xray >/dev/null 2>&1
		perpctl u xray >/dev/null 2>&1
	else
		echo_date "开启Xray主进程..."
		cd /koolshare/bin
		run_bg xray run -c $XRAY_CONFIG_FILE
	fi
	detect_running_status xray
}

creat_trojan_json(){
	# do not create json file on start
	if [ -n "${WAN_ACTION}" ]; then
		echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	elif [ -n "${NAT_ACTION}" ]; then
		echo_date "检测到防火墙重启触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	else
		if [ "${ss_basic_tcore}" == "1" ];then
			echo_date "创建xray的trojan配置文件到${TROJAN_CONFIG_FILE}"
		else
			echo_date "创建$(__get_type_abbr_name)的client配置文件到${TROJAN_CONFIG_FILE}"
		fi
	fi

	if [ "${ss_basic_tcore}" == "1" ];then
		# trojan协议由xray来运行
		rm -rf "${TROJAN_CONFIG_TEMP}"
		rm -rf "${TROJAN_CONFIG_FILE}"
		# log area
		cat >"${TROJAN_CONFIG_TEMP}" <<-EOF
			{
			"log": {
				"access": "none",
				"error": "none",
				"loglevel": "none"
			},
		EOF
		if [ "${ss_basic_dns_flag}" == "1" ]; then
			echo_date 配置${TCORE_NAME} dns，用于dns解析...
			cat >>"${TROJAN_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "$(get_dns_foreign ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user})",
						"port": $(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_udp_val} ${ss_basic_chng_trust_1_opt_udp_val_user}),
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
						}
					},
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		else
			# inbounds area (23456 for socks5)
			cat >>"$TROJAN_CONFIG_TEMP" <<-EOF
				"inbounds": [
					{
						"port": 23456,
						"listen": "127.0.0.1",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1"
						}
					},
					{
						"listen": "0.0.0.0",
						"port": 3333,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		fi
		# outbounds area
		cat >>"${TROJAN_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"protocol": "trojan",
					"settings": {
						"servers": [{
						"address": "${ss_basic_server}",
						"port": ${ss_basic_port},
						"password": "${ss_basic_trojan_uuid}"
						}]
					},
					"streamSettings": {
						"network": "tcp",
						"security": "tls",
						"tlsSettings": {
							"serverName": $(get_value_null ${ss_basic_trojan_sni}),
							"allowInsecure": $(get_function_switch ${ss_basic_trojan_ai})
      					}
      					,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_trojan_tfo})}
    				}
  				}
  			]
  			}
		EOF
		echo_date "解析xray的trojan配置文件..."
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' ${TROJAN_CONFIG_TEMP} 2>/dev/null
		fi
		run jq --tab . ${TROJAN_CONFIG_TEMP} >/tmp/trojan_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/trojan_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/trojan_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . ${TROJAN_CONFIG_TEMP} >${TROJAN_CONFIG_FILE}
		echo_date "解析成功！xray的trojan配置文件成功写入到${TROJAN_CONFIG_FILE}"
	else
		rm -rf "${TROJAN_CONFIG_TEMP}"
		rm -rf "${TROJAN_CONFIG_FILE}"
		
		cat > "${TROJAN_CONFIG_TEMP}" <<-EOF
			{
				"run_type": "client",
				"local_addr": "127.0.0.1",
				"local_port": 23456,
				"remote_addr": "${ss_basic_server}",
				"remote_port": ${ss_basic_port},
				"password": ["${ss_basic_trojan_uuid}"],
				"log_level": 1,
				"ssl": {
					"verify": $(get_reverse_switch ${ss_basic_trojan_ai}),
					"verify_hostname": true,
					"cert": "/rom/etc/ssl/certs/ca-certificates.crt",
					"cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
					"cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
					"sni": $(get_value_null ${ss_basic_trojan_sni}),
					"alpn": ["h2","http/1.1"],
					"reuse_session": true,
					"session_ticket": false,
					"curves": ""
				},
				"tcp": {
				"no_delay": true,
				"keep_alive": true,
				"reuse_port": false,
		EOF
		if [ "${LINUX_VER}" != "26" ]; then
			cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
				"fast_open": $(get_function_switch ${ss_basic_trojan_tfo}),
			EOF
		else
			cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
				"fast_open": false,
			EOF
		fi
		cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
				"fast_open_qlen": 20
				}
			}
		EOF
		echo_date "解析trojan的配置文件..."
		run jq --tab . ${TROJAN_CONFIG_TEMP} >/tmp/trojan_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/trojan_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/trojan_para_tmp.txt
			close_in_five flag
		fi
		run jq --tab . ${TROJAN_CONFIG_TEMP} >${TROJAN_CONFIG_FILE}
		echo_date "解析成功！trojan的配置文件成功写入到${TROJAN_CONFIG_FILE}"

		echo_date 测试trojan的配置文件....
		result=$(run /koolshare/bin/trojan -t ${TROJAN_CONFIG_FILE} 2>&1 | grep "The config file looks good.")
		if [ -n "${result}" ]; then
			echo_date 测试结果：${result}
			echo_date trojan的配置文件通过测试!!!
		else
			echo_date trojan的配置文件没有通过测试，请检查设置!!!
			rm -rf ${TROJAN_CONFIG_TEMP}
			rm -rf ${TROJAN_CONFIG_FILE}
			close_in_five flag
		fi
	fi
}

start_trojan(){
	# tfo
	if [ "${LINUX_VER}" != "26" ]; then
		if [ "${ss_basic_trojan_tfo}" == "1" ]; then
			echo_date ${TCORE_NAME}开启tcp fast open支持.
			echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		else
			echo 1 >/proc/sys/net/ipv4/tcp_fastopen
		fi
	fi
	if [ "${ss_basic_tcore}" == "1" ];then
		if [ "${ss_basic_xguard}" == "1" ];then
			echo_date "开启Xray主进程 + Xray守护，用以运行trojan协议节点..."
			# use perp to start xray
			mkdir -p /koolshare/perp/xray/
			cat >/koolshare/perp/xray/rc.main <<-EOF
				#!/bin/sh
				source /koolshare/scripts/base.sh
				CMD="xray run -c /koolshare/ss/xray.json"
				
				exec 2>&1
				exec \$CMD
				
			EOF
			chmod +x /koolshare/perp/xray/rc.main
			chmod +t /koolshare/perp/xray/
			sync
			perpctl A xray >/dev/null 2>&1
			perpctl u xray >/dev/null 2>&1
		else
			echo_date "开启Xray主进程，用以运行trojan协议节点..."
			cd /koolshare/bin
			run_bg xray run -c $XRAY_CONFIG_FILE
		fi
		detect_running_status xray
	else
		echo_date "开启ipt2socks进程，用于透明代理..."
		run_bg ipt2socks -p 23456 -l 3333 -4 -R
		detect_running_status2 ipt2socks 23456
		
		# start trojan
		if [ "${ss_basic_mcore}" == "1" ]; then
			echo_date "trojan开启$THREAD线程支持."
			local i=1
			while [ $i -le $THREAD ]; do
				run_bg trojan
				let i++
			done
		else
			run_bg trojan
		fi
	fi
}

start_naive(){
	echo_date "开启ipt2socks进程..."
	run_bg ipt2socks -p 23456 -l 3333 -4 -R
	detect_running_status2 ipt2socks 23456
	
	echo_date "开启NaïveProxy主进程..."
	if [ -n "${ss_basic_server_ip}" ];then
		run_bg naive --listen=socks://127.0.0.1:23456 --proxy=${ss_basic_naive_prot}://${ss_basic_naive_user}:${ss_basic_password}@${ss_basic_server_orig}:${ss_basic_naive_port} --host-resolver-rules="MAP ${ss_basic_server_orig} ${ss_basic_server_ip}"
	else
		run_bg naive --listen=socks://127.0.0.1:23456 --proxy=${ss_basic_naive_prot}://${ss_basic_naive_user}:${ss_basic_password}@${ss_basic_server_orig}:${ss_basic_naive_port}
	fi
	detect_running_status2 naive 23456
}

start_tuic(){
	rm -rf /koolshare/ss/tuic.json 2>/dev/null
	echo "${ss_basic_tuic_json}" | base64_decode >/tmp/tuic_tmp_1.json
	local RELAY=$(cat /tmp/tuic_tmp_1.json | run jq '.relay')

	echo_date "解析tuic配置文件..."
	echo "{\"local\": {\"server\": \"127.0.0.1:23456\"},\"log_level\": \"warn\"}" | run jq --argjson args "$RELAY" '. + {relay: $args}' >/koolshare/ss/tuic.json

	# 检测用户是否配置了ip地址
	local tuic_server=$(cat /koolshare/ss/tuic.json | run jq -r '.relay.server' | awk -F ":" '{print $1}')
	if [ -z "${tuic_server}" -o "${tuic_server}" == "null" ];then
		echo_date "检测到你的tuic配置文件未配置服务器地址/域名，请修改配置，退出！"
		close_in_five
	fi
	
	local tuic_ip=$(cat /koolshare/ss/tuic.json | run jq -r '.relay.ip')
	local tuic_ipaddr=$(__valid_ip ${tuic_ip})
	if [ -z "${tuic_ipaddr}" ];then
		echo_date "检测到你的tuic配置文件未配置ip地址，尝试解析！"
		__resolve_server_domain "${tuic_server}"
		case $? in
		0)
			echo_date "$(__get_type_abbr_name)服务器【${tuic_server}】的ip地址解析成功：${SERVER_IP}"
			tuic_server_ip="$SERVER_IP"
			;;
		1)
			# server is domain format and failed to resolve.
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			echo_date "$(__get_type_abbr_name)服务器的ip地址解析失败，这将大概率导致节点无法正常工作！"
			echo_date "请尝试在【DNS设定】- 【节点域名解析DNS服务器】处更换节点服务器的解析方案后重试！"
			echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
			tuic_server_ip=""
			# close_in_five flag
			;;
		2)
			# server is not ip either domain!
			echo_date "错误2！！检测到你设置的服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
			echo_date "请更正你的错误然后重试！！"
			close_in_five flag
			;;
		esac

		if [ -n "${tuic_server_ip}" ];then
			cat /koolshare/ss/tuic.json | run jq --arg addr "$tuic_server_ip" '.relay.ip = $addr' | run sponge /koolshare/ss/tuic.json
		fi
	fi
	
	echo_date "开启ipt2socks进程..."
	run_bg ipt2socks -p 23456 -l 3333 -4 -R
	detect_running_status2 ipt2socks 23456
	
	echo_date "开启tuic-client主进程..."
	run_bg tuic-client -c /koolshare/ss/tuic.json
	detect_running_status tuic-client
}

start_hysteria2(){
	rm -rf /koolshare/ss/hysteria2.yaml 2>/dev/null

	echo_date "生成hysteria2配置文件..."
	if [ -z "${ss_basic_hy2_sni}" ];then
		__valid_ip_silent "${ss_basic_hy2_server}"
		if [ "$?" != "0" ];then
			# not ip, should be a domain
			ss_basic_hy2_sni=${ss_basic_hy2_server}
		else
			ss_basic_hy2_sni=""
		fi
	else
		ss_basic_hy2_sni="${ss_basic_hy2_sni}"
	fi
	cat >> /koolshare/ss/hysteria2.yaml <<-EOF
		server: ${ss_basic_server}:${ss_basic_hy2_port}
		
		auth: ${ss_basic_hy2_pass}

		tls:
		  sni: ${ss_basic_hy2_sni}
		  insecure: $(get_function_switch ${ss_basic_hy2_ai})
		
		fastOpen: $(get_function_switch ${ss_basic_hy2_tfo})
		
	EOF
	
	if [ -n "${ss_basic_hy2_up}" -o -n "${ss_basic_hy2_dl}" ];then
		cat >> /koolshare/ss/hysteria2.yaml <<-EOF
			bandwidth: 
			  up: ${ss_basic_hy2_up} mbps
			  down: ${ss_basic_hy2_dl} mbps
			
		EOF
	fi

	if [ "${ss_basic_hy2_obfs}" == "1" -a -n "${ss_basic_hy2_obfs_pass}" ];then
		cat >> /koolshare/ss/hysteria2.yaml <<-EOF
			obfs:
			  type: salamander
			  salamander:
			    password: ${ss_basic_hy2_obfs_pass}
			
		EOF
	fi

	cat >> /koolshare/ss/hysteria2.yaml <<-EOF
		transport:
		  udp:
		    hopInterval: 30s
		
		socks5:
		  listen: 127.0.0.1:23456
		
		tcpRedirect:
		  listen: :3333
		
		udpTProxy:
		  listen: :3333
		  timeout: 20s
	EOF

	echo_date "开启hysteria2进程..."
	if [ "${LINUX_VER}" == "419" -o "${LINUX_VER}" == "54" ];then
		run_bg hysteria2 -c /koolshare/ss/hysteria2.yaml
	else
		env -i PATH=${PATH} QUIC_GO_DISABLE_ECN=true hysteria2 -c /koolshare/ss/hysteria2.yaml >/dev/null 2>&1 &
	fi
	run_bg hysteria2 -c /koolshare/ss/hysteria2.yaml
	detect_running_status hysteria2
}

write_cron_job() {
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date "添加fancyss规则定时更新任务，每天$ss_basic_rule_update_time自动检测更新规则."
		cru a ssupdate "0 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date "fancyss规则定时更新任务未启用！"
	fi
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$ss_basic_node_update" = "1" ]; then
		if [ "$ss_basic_node_update_day" = "7" ]; then
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * * /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置订阅服务器自动更新订阅服务器在每天 $ss_basic_node_update_hr 点。"
		else
			cru a ssnodeupdate "0 $ss_basic_node_update_hr * * $ss_basic_node_update_day /koolshare/scripts/ss_online_update.sh fancyss 3"
			echo_date "设置订阅服务器自动更新订阅服务器在星期 $ss_basic_node_update_day 的 $ss_basic_node_update_hr 点。"
		fi
	fi
}

kill_cron_job() {
	if [ -n "$(cru l | grep ssupdate)" ]; then
		echo_date 删除fancyss规则定时更新任务...
		sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	if [ -n "$(cru l | grep ssnodeupdate)" ]; then
		echo_date 删除SSR定时订阅任务...
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}
#--------------------------------------nat part begin------------------------------------------------
load_tproxy() {
	MODULES="xt_TPROXY xt_socket xt_comment"
	OS=$(uname -r)
	# load Kernel Modules
	echo_date 加载TPROXY模块，用于udp转发...
	checkmoduleisloaded() {
		if lsmod | grep $MODULE &>/dev/null; then return 0; else return 1; fi
	}

	for MODULE in $MODULES; do
		if ! checkmoduleisloaded; then
			#insmod /lib/modules/${OS}/kernel/net/netfilter/${MODULE}.ko
			modprobe ${MODULE}.ko
		fi
	done

	modules_loaded=0

	for MODULE in $MODULES; do
		if checkmoduleisloaded; then
			modules_loaded=$((j++))
		fi
	done

	if [ $modules_loaded -ne 2 ]; then
		echo "One or more modules are missing, only $((modules_loaded + 1)) are loaded. Can't start."
		close_in_five
	fi
}

flush_nat() {
	echo_date "清除iptables规则和ipset..."
	# flush rules and set if any
	nat_indexs=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/SHADOWSOCKS/=' | sort -r)
	for nat_index in $nat_indexs; do
		iptables -t nat -D PREROUTING $nat_index >/dev/null 2>&1
	done
	iptables -t nat -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_EXT >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_DNS >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_DNS >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GFW >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GFW >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_CHN >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_CHN >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GAM >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GAM >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GLO >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GLO >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_HOM >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_HOM >/dev/null 2>&1
	mangle_indexs=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/SHADOWSOCKS/=' | sort -r)
	for mangle_index in $mangle_indexs; do
		iptables -t mangle -D PREROUTING $mangle_index >/dev/null 2>&1
	done
	iptables -t mangle -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GPT >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GPT >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GFW >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GFW >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_CHN >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_CHN >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GAM >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GAM >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GLO >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GLO >/dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333 >/dev/null 2>&1
	iptables -t nat -F OUTPUT >/dev/null 2>&1
	iptables -t nat -X SHADOWSOCKS_EXT >/dev/null 2>&1
	iptables -t mangle -D QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN >/dev/null 2>&1
	
	# flush ipset
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F chatgpt >/dev/null 2>&1 && ipset -X chatgpt >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
	#remove_redundant_rule
	ip_rule_exist=$(ip rule show | grep "lookup 310" | grep -c 310)
	if [ -n "${ip_rule_exist}" ]; then
		#echo_date 清除重复的ip rule规则.
		until [ "${ip_rule_exist}" == "0" ]; do
			IP_ARG=$(ip rule show | grep "lookup 310" | head -n 1 | cut -d " " -f3,4,5,6)
			ip rule del $IP_ARG
			ip_rule_exist=$(expr $ip_rule_exist - 1)
		done
	fi
	#remove_route_table
	#echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}

# creat ipset rules
creat_ipset() {
	echo_date 创建ipset名单
	ipset -! create white_list nethash && ipset flush white_list
	ipset -! create black_list nethash && ipset flush black_list
	ipset -! create chatgpt nethash && ipset flush chatgpt
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

add_white_black_ip() {
	# black ip/cidr
	if [ "${ss_basic_mode}" != "6" ]; then
		ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
		for ip in ${ip_tg}; do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi

	if [ -n "${ss_wan_black_ip}" ]; then
		ss_wan_black_ip=$(echo ${ss_wan_black_ip} | base64_decode | sed '/\#/d')
		echo_date "应用IP/CIDR黑名单"
		for ip in ${ss_wan_black_ip}; do
			ipset -! add black_list ${ip} >/dev/null 2>&1
		done
	fi

	# white ip/cidr
	[ -n "${ss_basic_server_ip}" ] && SBSI="${ss_basic_server_ip}" || SBSI=""
	[ -n "${ISP_DNS1}" ] && ISP_DNS_a="${ISP_DNS1}" || ISP_DNS_a=""
	[ -n "${IFIP_DNS2}" ] && ISP_DNS_b="${ISP_DNS2}" || ISP_DNS_b=""
	local ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 192.18.0.0/15 224.0.0.0/4 240.0.0.0/4 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 117.50.11.11 117.50.22.22 180.76.76.76 119.29.29.29 ${ISP_DNS_a} ${ISP_DNS_b} ${SBSI} $(get_wan0_cidr)"
	local ALL_NODE_DOMAINS=$(dbus list ssconf|grep _server_|awk -F"=" '{print $NF}'|sort -u|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	ss_wan_white_ip=$(echo ${ss_wan_white_ip} | base64_decode | sed '/\#/d')
	echo_date "应用IP/CIDR白名单"
	for ip in ${ss_wan_white_ip} ${ALL_NODE_DOMAINS} ${ip_lan}
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done
}

get_action_chain() {
	case "$1" in
	0)
		echo "RETURN"
		;;
	1)
		echo "SHADOWSOCKS_GFW"
		;;
	2)
		echo "SHADOWSOCKS_CHN"
		;;
	3)
		echo "SHADOWSOCKS_GAM"
		;;
	5)
		echo "SHADOWSOCKS_GLO"
		;;
	6)
		echo "SHADOWSOCKS_HOM"
		;;
	esac
}

get_mode_name() {
	case "$1" in
	0)
		echo "不通过代理"
		;;
	1)
		echo "gfwlist模式"
		;;
	2)
		echo "大陆白名单模式"
		;;
	3)
		echo "游戏模式"
		;;
	5)
		echo "全局模式"
		;;
	6)
		echo "回国模式"
		;;
	esac
}

factor() {
	if [ -z "$1" -o -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}

get_jump_mode() {
	case "$1" in
	0)
		echo "j"
		;;
	*)
		echo "g"
		;;
	esac
}

lan_acess_control() {
	# lan access control
	acl_nu=$(dbus list ss_acl_mode_ | cut -d "=" -f 1 | cut -d "_" -f 4 | sort -n)
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu; do
			ipaddr=$(eval echo \$ss_acl_ip_$acl)
			ipaddr_hex=$(echo $ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("%02x\n", $4)}')
			ports=$(eval echo \$ss_acl_port_$acl)
			proxy_mode=$(eval echo \$ss_acl_mode_$acl)
			proxy_name=$(eval echo \$ss_acl_name_$acl)
			if [ "$ports" == "all" ]; then
				ports=""
				echo_date 加载ACL规则：【$ipaddr】【全部端口】模式为：$(get_mode_name $proxy_mode)
			else
				echo_date 加载ACL规则：【$ipaddr】【$ports】模式为：$(get_mode_name $proxy_mode)
			fi
			# 1 acl in SHADOWSOCKS for nat
			iptables -t nat -A SHADOWSOCKS $(factor $ipaddr "-s") -p tcp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			
			# 2 acl in OUTPUT（used by koolproxy）
			iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ports "-m multiport --dport") -m mark --mark "$ipaddr_hex" -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			
			# 3 acl in SHADOWSOCKS for mangle
			if [ "$proxy_mode" != "0" ];then
				if [ "$ss_basic_udpoff" == "1" ];then
					iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
				fi
				if [ "$ss_basic_udpall" == "1" ];then
					iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
				fi
				if [ "$ss_basic_udpgpt" == "1" ];then
					iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -j SHADOWSOCKS_GPT
				fi
			else
				iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
			fi
		done

		if [ "$ss_acl_default_port" == "all" ]; then
			ss_acl_default_port=""
			[ -z "$ss_acl_default_mode" ] && dbus set ss_acl_default_mode="$ss_basic_mode" && ss_acl_default_mode="$ss_basic_mode"
			echo_date 加载ACL规则：【剩余主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【剩余主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	else
		ss_acl_default_mode="$ss_basic_mode"
		if [ "$ss_acl_default_port" == "all" ]; then
			ss_acl_default_port=""
			echo_date 加载ACL规则：【全部主机】【全部端口】模式为：$(get_mode_name $ss_acl_default_mode)
		else
			echo_date 加载ACL规则：【全部主机】【$ss_acl_default_port】模式为：$(get_mode_name $ss_acl_default_mode)
		fi
	fi
	dbus remove ss_acl_ip
	dbus remove ss_acl_name
	dbus remove ss_acl_mode
	dbus remove ss_acl_port
}

dns_hijack_control() {
	if [ "$ss_basic_dns_hijack" == "1" ]; then
		acl_nu=$(dbus list ss_acl_mode_ | cut -d "=" -f 1 | cut -d "_" -f 4 | sort -n)
		if [ -n "$acl_nu" ]; then
			for acl in $acl_nu; do
				ipaddr=$(eval echo \$ss_acl_ip_$acl)
				ipaddr_hex=$(echo $ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("%02x\n", $4)}')
				ports=$(eval echo \$ss_acl_port_$acl)
				proxy_mode=$(eval echo \$ss_acl_mode_$acl)
				if [ "$proxy_mode" == "0" ]; then
					iptables -t nat -A SHADOWSOCKS_DNS -p udp -s ${ipaddr} -j RETURN
				fi
			done
		fi
		iptables -t nat -A SHADOWSOCKS_DNS -p udp -j DNAT --to ${lan_ipaddr}:53
	fi
}

apply_nat_rules() {
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	
	# 创建SHADOWSOCKS nat rule
	iptables -t nat -N SHADOWSOCKS

	if [ "$ss_basic_dns_hijack" == "1" ]; then
		iptables -t nat -N SHADOWSOCKS_DNS
	fi
	
	# 扩展
	iptables -t nat -N SHADOWSOCKS_EXT
	
	# IP/cidr/白域名 白名单控制（不go proxy）
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set white_list dst -j RETURN
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp -m set --match-set white_list dst -j RETURN
	
	#-----------------------FOR GLOABLE---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GLO
	# IP黑名单控制-gfwlist（go proxy）
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GFW
	# IP/CIDR/黑域名 黑名单控制（go proxy）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# IP黑名单控制-gfwlist（go proxy）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports 3333
	
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式nat rule
	iptables -t nat -N SHADOWSOCKS_CHN
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式nat rule
	iptables -t nat -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	
	#-----------------------FOR HOMEMODE---------------------
	# 创建回国模式nat rule
	iptables -t nat -N SHADOWSOCKS_HOM
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set chnroute dst -j REDIRECT --to-ports 3333

	load_tproxy
	ip rule add fwmark 0x07 table 310
	ip route add local 0.0.0.0/0 dev lo table 310
	# 创建游戏模式udp rule
	iptables -t mangle -N SHADOWSOCKS
	# IP/cidr/白域名 白名单控制（不go proxy）
	iptables -t mangle -A SHADOWSOCKS -p udp -m set --match-set white_list dst -j RETURN

	# 创建GPT模式udp rule
	iptables -t mangle -N SHADOWSOCKS_GPT
	# IP/CIDR/域名 黑名单控制（go proxy）
	# iptables -t mangle -A SHADOWSOCKS_GPT -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# ipset黑名单控制-chatgpt（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GPT -p udp -m set --match-set chatgpt dst -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建gfw模式udp rule
	iptables -t mangle -N SHADOWSOCKS_GFW
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# ipset黑名单控制-gfwlist（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GFW -p udp -m set --match-set gfwlist dst -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建白名单模式udp rule
	iptables -t mangle -N SHADOWSOCKS_CHN
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t mangle -A SHADOWSOCKS_CHN -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t mangle -A SHADOWSOCKS_CHN -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建游戏模式udp rule
	iptables -t mangle -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07

	# 创建glo模式udp rule
	iptables -t mangle -N SHADOWSOCKS_GLO
	# IP/CIDR/域名 黑名单控制（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GLO -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（go proxy）
	iptables -t mangle -A SHADOWSOCKS_GLO -p udp -j TPROXY --on-port 3333 --tproxy-mark 0x07
	#-------------------------------------------------------
	# 局域网黑名单（不go proxy）/局域网黑名单（go proxy）
	lan_acess_control
	# DNS 劫持
	dns_hijack_control
	#-----------------------FOR ROUTER---------------------
	# router itself
	[ "$ss_basic_mode" != "6" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
	iptables -t nat -A OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT

	# 把最后剩余流量重定向到相应模式的nat表中对应的主模式的链
	iptables -t nat -A SHADOWSOCKS -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)

	if [ "$ss_basic_mode" == "3" ];then
		# 如果是主模式游戏模式，则把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM链
		if [ "$ss_acl_default_mode" == "3" ];then
			iptables -t mangle -A SHADOWSOCKS -p udp -j SHADOWSOCKS_GAM
		else
			iptables -t mangle -A SHADOWSOCKS -p udp -j RETURN
		fi
	else
		# 如果主模式不是游戏模式，则不需要把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM，不然会造成其他模式主机的udp也走游戏模式
		if [ "$ss_basic_udpoff" == "1" ];then
			iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
		fi
		
		if [ "$ss_basic_udpall" == "1" ];then
			iptables -t mangle -A SHADOWSOCKS -p udp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
		fi

		if [ "$ss_basic_udpgpt" == "1" ];then
			iptables -t mangle -A SHADOWSOCKS -p udp $(factor $ss_acl_default_port "-m multiport --dport") -j SHADOWSOCKS_GPT
		fi
	fi
	
	# 重定所有流量到 SHADOWSOCKS
	KP_NU=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/KOOLPROXY/=' | head -n1)
	[ "$KP_NU" == "" ] && KP_NU=0
	INSET_NU=$(expr "$KP_NU" + 1)
	iptables -t nat -I PREROUTING "$INSET_NU" -p tcp -j SHADOWSOCKS
	[ "$mangle" != "0" ] && iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS

	if [ "$ss_basic_dns_hijack" == "1" ]; then
		echo_date "开启DNS劫持功能功能，防止DNS污染..."
		INSET_NU_DNS=$(expr "$INSET_NU" + 1)
		iptables -t nat -I PREROUTING "$INSET_NU_DNS" -p udp ! -s ${lan_ipaddr} --dport 53 -j SHADOWSOCKS_DNS
	else
		echo_date" DNS劫持功能未开启，建议开启！"
	fi
	
	# QOS开启的情况下
	QOSO=$(iptables -t mangle -S | grep -o QOSO | wc -l)
	RRULE=$(iptables -t mangle -S | grep "A QOSO" | head -n1 | grep RETURN)
	if [ "$QOSO" -gt "1" -a -z "$RRULE" ]; then
		iptables -t mangle -I QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN
	fi
}

# -----------------------------------nat part end--------------------------------------------------------

restart_dnsmasq() {
	# 当dnsmasq处于自然状态下，不需要重启dnsmasq
	# if [ "${ss_basic_status}" == "0" -a "${ss_basic_enable}" == "0" ];then
	# 	return 0
	# fi
	
	# 如果是梅林固件，需要将 【Tool - Other Settings  - Advanced Tweaks and Hacks - Wan: Use local caching DNS server as system resolver (default: No)】此处设置为【是】
	# 这将确保固件自身的DNS解析使用127.0.0.1，而不是上游的DNS。否则插件的状态检测将无法解析谷歌，导致状态检测失败。
	local DLC=$(nvram get dns_local_cache)
	if [ "$DLC" == "0" ]; then
		nvram set dns_local_cache=1
		nvram commit
	fi
	# 从梅林刷到官改固件，如果不重置固件，则dns_local_cache将会保留，会导致误判，所以需要改写一次以确保OK
	local LOCAL_DNS=$(cat /etc/resolv.conf|grep "127.0.0.1")
	if [ -z "$LOCAL_DNS" ]; then
		cat >/etc/resolv.conf <<-EOF
			nameserver 127.0.0.1
		EOF
	fi
	# Restart dnsmasq
	echo_date "重启dnsmasq服务..."
	service restart_dnsmasq >/dev/null 2>&1 &
	detect_running_status dnsmasq
}

load_module() {
	xt=$(lsmod | grep xt_set)
	OS=$(uname -r)
	if [ -f /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko -a -z "$xt" ]; then
		echo_date "加载xt_set.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_set.ko
	fi
}

# write number into nvram with no commit
write_numbers() {
	nvram set update_ipset="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.gfwlist.date')"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.date')"
	nvram set update_cdn="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.cdn_china.date')"
	nvram set ipset_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.gfwlist.count')"
	nvram set chnroute_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.count')"
	nvram set chnroute_ips="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.chnroute.count_ip')"
	nvram set cdn_numbers="$(cat /koolshare/ss/rules/rules.json.js | run /koolshare/bin/jq -r '.cdn_china.count')"
}

remove_ss_reboot_job() {
	if [ -n "$(cru l | grep ss_reboot)" ]; then
		echo_date "【科学上网】：删除插件自动重启定时任务..."
		sed -i '/ss_reboot/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_reboot_job() {
	if [[ "${ss_reboot_check}" == "0" ]]; then
		remove_ss_reboot_job
	elif [[ "${ss_reboot_check}" == "1" ]]; then
		echo_date "【科学上网】：设置每天${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "2" ]]; then
		echo_date "【科学上网】：设置每周${ss_basic_week}的${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" * * "${ss_basic_week}" /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "3" ]]; then
		echo_date "【科学上网】：设置每月${ss_basic_day}日${ss_basic_time_hour}时${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour} ${ss_basic_day}" * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	elif [[ "${ss_reboot_check}" == "4" ]]; then
		if [[ "${ss_basic_inter_pre}" == "1" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_min}分钟重启插件..."
			cru a ss_reboot "*/"${ss_basic_inter_min}" * * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "2" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_hour}小时重启插件..."
			cru a ss_reboot "0 */"${ss_basic_inter_hour}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		elif [[ "${ss_basic_inter_pre}" == "3" ]]; then
			echo_date "【科学上网】：设置每隔${ss_basic_inter_day}天${ss_basic_inter_hour}小时${ss_basic_time_min}分钟重启插件..."
			cru a ss_reboot ${ss_basic_time_min} ${ss_basic_time_hour}" */"${ss_basic_inter_day} " * * /bin/sh /koolshare/ss/ssconfig.sh restart"
		fi
	elif [[ "${ss_reboot_check}" == "5" ]]; then
		check_custom_time=$(echo ss_basic_custom | base64_decode)
		echo_date "【科学上网】：设置每天${check_custom_time}时的${ss_basic_time_min}分重启插件..."
		cru a ss_reboot ${ss_basic_time_min} ${check_custom_time}" * * * /bin/sh /koolshare/ss/ssconfig.sh restart"
	fi
}

remove_ss_trigger_job() {
	if [ -n "$(cru l | grep ss_tri_check)" ]; then
		echo_date "删除插件触发重启定时任务..."
		sed -i '/ss_tri_check/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

set_ss_trigger_job() {
	if [ "$ss_basic_tri_reboot_time" == "0" ]; then
		remove_ss_trigger_job
	else
		if [ "$ss_basic_tri_reboot_policy" == "1" ]; then
			echo_date "设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启科学上网插件..."
		else
			echo_date "设置每隔$ss_basic_tri_reboot_time分钟检查服务器IP地址，如果IP发生变化，则重启dnsmasq..."
		fi
		echo_date "科学上网插件触发重启功能的日志将显示再系统日志内。"
		cru d ss_tri_check >/dev/null 2>&1
		cru a ss_tri_check "*/$ss_basic_tri_reboot_time * * * * /koolshare/scripts/ss_reboot_job.sh check_ip"
	fi
}

load_nat() {
	local nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	i=300
	until [ -n "$nat_ready" ]; do
		i=$(($i - 1))
		if [ "$i" -lt 1 ]; then
			echo_date "错误：不能正确加载nat规则!"
			close_in_five
		fi
		usleep 100000
		local nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	done
	#creat_ipset
	add_white_black_ip
	apply_nat_rules
}

ss_post_start() {
	# 在SS插件启动成功后触发脚本
	local i
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort); do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 启动后触发脚本: $i -------------
		if [ -r "$i" ]; then
			$i start
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

ss_pre_stop() {
	# 在SS插件关闭前触发脚本
	local i
	mkdir -p /koolshare/ss/postscripts && cd /koolshare/ss/postscripts
	for i in $(find ./ -name 'P*' | sort -r); do
		trap "" INT QUIT TSTP EXIT
		echo_date ------------- 【科学上网】 关闭前触发脚本: $i ------------
		if [ -r "$i" ]; then
			$i stop
		fi
		echo_date ----------------- 触发脚本: $i 运行完毕 -----------------
	done
}

httping_check() {
	[ "$ss_basic_check" != "1" ] && return
	echo "--------------------------------------------------------------------------------------"
	echo "检查国内可用性..."
	httping www.baidu.com -s -Z -r --ts -c 10 -i 0.5 -t 5 | tee /tmp/upload/china.txt
	if [ "$?" != "0" ]; then
		ehco "当前节点无法访问国内网络！"
		#dbus set ssconf_basic_node=$
	fi
	echo "--------------------------------------------------------------------------------------"
	echo "检查国外可用性..."
	#httping www.google.com.tw -s -Z --proxy 127.0.0.1:23456 -5 -r --ts -c 5
	httping www.google.com.tw -s -Z -5 -r --ts -c 10 -i 0.5 -t 2
	if [ "$?" != "0" ]; then
		echo "当前节点无法访问国外网络！"
		echo "自动切换到下一个节点..."
		ssconf_basic_node=$(($ssconf_basic_node + 1))
		dbus set ssconf_basic_node=$ssconf_basic_node
		apply_ss
		return 1
		#start-stop-daemon -S -q -x /koolshare/ss/ssconfig.sh 2>&1
	fi
	echo "--------------------------------------------------------------------------------------"
}

stop_status() {
	local flag=$1
	if [ -z "${flag}" ];then
		kill -9 $(pidof ss_status_main.sh) >/dev/null 2>&1
		kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
		killall curl >/dev/null 2>&1
		killall curl-fancyss >/dev/null 2>&1
		killall httping >/dev/null 2>&1
		rm -rf /tmp/upload/ss_status.txt
	fi
}

detect_ip(){
	local SUBJECT=$1
	local TIMEOUT=$2
	[ -z "${TIMEOUT}" ] && TIMEOUT="3"
	local IP=$(curl -4s --connect-timeout ${TIMEOUT} ${SUBJECT} 2>&1 | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep -v "Terminated")
	if [ -n "${IP}" ];then
		echo $IP
	else
		echo ""
	fi
}

check_chng_fdns(){
	local FDNS_OK_FLAG_1=0
	if [ "${ss_basic_chng_trust_1_enable}" == "1" ];then
		if [ "${ss_basic_chng_trust_1_ecs}" == "1" ];then
			local TPORT=2055
		else
			local TPORT=1055
		fi
		echo_date "检测进阶chinadns-ng方案可信DNS-1（端口：${TPORT}）是否正常工作..."
		# 国外dns检测，超时时间设置久一点
		local DETECT_SERVER_IP_1=$(run dnsclient -p ${TPORT} -t 5 -i 2 @127.0.0.1 dns.msftncsi.com 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
		local DETECT_SERVER_IP_1=$(__valid_ip ${DETECT_SERVER_IP_1})
		if [ -n "${DETECT_SERVER_IP_1}" ]; then
			echo_date "可信DNS-1 ${TPORT}端口DNS服务工作正常！"
			local FDNS_OK_FLAG_1=1
		else
			echo_date "可信DNS-1 ${TPORT}端口DNS服务工作异常，无法解析域名！可能是以下原因："
			echo_date "---------------------------------------------------------"
			echo_date "1. [大概率原因]：节点代理已经失效，请尝试更新订阅、更换可用节点"
			echo_date "2. [中概率原因]：国外DNS解析出现问题，请尝试更换其它的DNS方案"
			echo_date "3. [小概率原因]：节点延迟/丢包较高，请尝试更换低延迟/高质量节点"
			echo_date "---------------------------------------------------------"
			echo_date "如果插件启动完毕后国外不通，请检查可信DNS-1的配置！继续！"
			#echo_date "为了避免因代理失效对本地非代理网络也造成影响！将会关闭代理相关进程..."
			#close_in_five flag
		fi
	fi

	local FDNS_OK_FLAG_2=0
	if [ "${ss_basic_chng_trust_2_enable}" == "1" ];then
		if [ "${ss_basic_chng_trust_2_ecs}" == "1" ];then
			local TPORT=2056
		else
			local TPORT=1056
		fi

		if [ "${ss_basic_chng_trust_2_ecs}" == "97" ];then
			local TPORT=1056
		fi
	
		echo_date "检测进阶chinadns-ng方案可信DNS-2（端口：${TPORT}）是否正常工作..."
		# 国外dns检测，超时时间设置久一点
		local DETECT_SERVER_IP_2=$(run dnsclient -p ${TPORT} -t 5 -i 2 @127.0.0.1 dns.msftncsi.com 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
		local DETECT_SERVER_IP_2=$(__valid_ip ${DETECT_SERVER_IP_2})
		if [ -n "${DETECT_SERVER_IP_2}" ]; then
			echo_date "可信DNS-2 ${TPORT}端口DNS服务工作正常！"
			local FDNS_OK_FLAG_2=1
		else
			echo_date "可信DNS-2 ${TPORT}端口DNS服务工作异常，无法解析域名！"
			echo_date "如果插件启动完毕后国外不通，请检查可信DNS-2的配置！继续！"
		fi
	fi

	# if [ "${FDNS_OK_FLAG_1}" == "0" -a "${FDNS_OK_FLAG_2}" == "0" ];then
	# 	# 国外DNS不通，则
	# 	close_in_five flag
	# fi
}

check_chn_dns(){
	#echo_date "检测进阶chinadns-ng方案中的中国DNS是否正常工作..."
	echo_date "检测中国域名是否正常解析..."
	
	# 1. 检测5个国内域名的DNS解析
	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		local CHN_RESOLV_DOMAIN="www.baidu.com"
		local CHN_RESOLV_IPADDR=$(run dnsclient -p 7913 -t 3 -i 1 @127.0.0.1 ${CHN_RESOLV_DOMAIN} 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
	fi

	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		local CHN_RESOLV_DOMAIN="www.taobao.com"
		local CHN_RESOLV_IPADDR=$(run dnsclient -p 7913 -t 3 -i 1 @127.0.0.1 ${CHN_RESOLV_DOMAIN} 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
	fi

	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		local CHN_RESOLV_DOMAIN="www.sina.com"
		local CHN_RESOLV_IPADDR=$(run dnsclient -p 7913 -t 3 -i 1 @127.0.0.1 ${CHN_RESOLV_DOMAIN} 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
	fi

	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		local CHN_RESOLV_DOMAIN="www.jd.com"
		local CHN_RESOLV_IPADDR=$(run dnsclient -p 7913 -t 3 -i 1 @127.0.0.1 ${CHN_RESOLV_DOMAIN} 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
	fi

	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		local CHN_RESOLV_DOMAIN="www.qq.com"
		local CHN_RESOLV_IPADDR=$(run dnsclient -p 7913 -t 3 -i 1 @127.0.0.1 ${CHN_RESOLV_DOMAIN} 2>/dev/null|grep -E "^IP"|head -n1|awk '{print $2}')
	fi
	
	if [ -z "${CHN_RESOLV_IPADDR}" ]; then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "国内DNS工作异常，无法正常解析国内域名！请检查你的国内DNS设置..."
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		###close_in_five flag
	fi
	
	if [ -n "${CHN_RESOLV_IPADDR}" ]; then
		echo_date "中国DNS工作正常！检测源：${CHN_RESOLV_DOMAIN}，解析结果：${CHN_RESOLV_IPADDR}"
	fi
}

check_frn_public_ip(){
	echo_date "开始代理出口ip检测..."
	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN=$(detect_ip icanhazip.com 5 1)
		REMOTE_IP_FRN_SRC="icanhazip.com"
	fi
	
	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN=$(detect_ip ipecho.net/plain 5 1)
		REMOTE_IP_FRN_SRC="ipecho.net/plain"
	fi

	if [ -z "${REMOTE_IP_FRN}" ];then
		REMOTE_IP_FRN=$(detect_ip ip.sb 5 1)
		REMOTE_IP_FRN_SRC="ip.sb"
	fi

	if [ -n "${REMOTE_IP_FRN}" ];then
		ipset test chnroute ${REMOTE_IP_FRN} >/dev/null 2>&1
		if [ "$?" != "0" ]; then
			# 国外ip
			echo_date "代理服务器出口地址：${REMOTE_IP_FRN}，属地：海外，来源：${REMOTE_IP_FRN_SRC}"
			
		else
			# 国内ip
			echo_date "代理服务器出口地址：${REMOTE_IP_FRN}，属地：大陆，来源：${REMOTE_IP_FRN_SRC}"
		fi
	else
		echo_date "代理服务器出口地址检测失败！可能是以下原因："
		echo_date "---------------------------------------------------------"
		echo_date "1. 节点失效，请尝试更新订阅、更换节点"
		echo_date "2. 节点延迟较高，请尝试更换低延迟节点"
		if [ "${FDNS_OK_FLAG}" != "1" ];then
			echo_date "3. DNS解析失效，请尝试更换DNS方案"
		fi
		echo_date "插件将会继续运行，但是不保证代理工作正常！"
		echo_date "---------------------------------------------------------"
		# close_in_five flag
	fi
	
	# 检测节点解析结果
	if [ -n "${ss_basic_server_ip}" ];then
		[ -z "${ss_basic_server_orig}" ] && 
		ipset test chnroute ${ss_basic_server_ip} >/dev/null 2>&1
		if [ "$?" != "0" ]; then
			# 国外ip
			echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：海外，来源：${ss_basic_server_orig}"
			
		else
			# 国内ip
			echo_date "节点服务器解析地址：${ss_basic_server_ip}，属地：大陆，来源：${ss_basic_server_orig}"
		fi
	fi
}

finish_start(){
	# something else need to do

	if [ "${ss_basic_nocdnscheck}" != "1" -o "${ss_basic_nofdnscheck}" != "1" -o "${ss_basic_nofrnipcheck}" != "1" ];then
		echo_date "---------------------------------------------------------"
		echo_date "所有服务和规则加载完毕，运行一些检测..."
	fi

	# 1. 检测国内域名解析是否正常
	if [ "${ss_basic_advdns}" == "1" ];then
		if [ "${ss_basic_nocdnscheck}" != "1" ];then
			check_chn_dns
		#else
			#echo_date "跳过国内DNS可用性检测..."
		fi
	fi
	
	# 2. 如果dns经过代理，那么检测dns服务是否畅通
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" ];then
		if [ "${ss_basic_nofdnscheck}" != "1" ];then
			check_chng_fdns
		#else
			#echo_date "跳过chinadns-ng可信DNS的可用性检测..."
		fi
	fi
	
	# 3. get foreign ip
	if [ "${ss_basic_nofrnipcheck}" != "1" ];then
		check_frn_public_ip
	#else
		#echo_date "跳过代理出口ip检测..."
	fi

	# ECS开启：
	# new dns plan: chinadns-ng, trust-1，udp + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "1" -a "${ss_basic_chng_trust_1_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" ];then
					ipset test chnroute ${REMOTE_IP_FRN} >/dev/null 2>&1
					if [ "$?" != "0" ]; then
						local TMP_PID=$(ps | grep -E "socat|uredir" | grep 2055 | awk '{print $1}')
						if [ -n "${TMP_PID}" ];then
							kill -9 ${TMP_PID}
						fi
						local DEF_PID=$(ps | grep dns-ecs-forcer | grep 2055 | awk '{print $1}')
						if [ -n "${DEF_PID}" ];then
							kill -9 ${DEF_PID}
						fi
						echo_date "开启dns-ecs-forcer，填入ECS标签：${REMOTE_IP_FRN%.*}.0"
						run_bg dns-ecs-forcer -p 2055 -s 127.0.0.1:1055 -e "${REMOTE_IP_FRN%.*}.0"
						detect_running_status2 dns-ecs-forcer 2055
					fi
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
		fi
	fi

	# new dns plan: chinadns-ng, trust-1，tcp + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "2" -a "${ss_basic_chng_trust_1_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" ];then
					ipset test chnroute ${REMOTE_IP_FRN} >/dev/null 2>&1
					if [ "$?" != "0" ]; then
						# 最新版本dns2socks 本身就支持ecs，无需dns-ecs-forcer
						echo_date "重启dns2socks，开启EDNS支持，使用CLIENT-SUBNET: ${REMOTE_IP_FRN}/32"
						start_dns2socks $(get_dns_foreign ${ss_basic_chng_trust_1_opt_tcp_val} ${ss_basic_chng_trust_1_opt_tcp_val_user}):$(get_dns_foreign_port ${ss_basic_chng_trust_1_opt_tcp_val} ${ss_basic_chng_trust_1_opt_tcp_val_user}) 2055 1
					fi
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
		fi
	fi

	#  new dns plan: chinadns-ng, trust-1，doh + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_1_enable}" == "1" -a "${ss_basic_chng_trust_1_opt}" == "3" -a "${ss_basic_chng_trust_1_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" ];then
					start_dohclient_chng restart frn1 ${ss_basic_chng_trust_1_opt_doh_val} ${ss_basic_chng_trust_1_ecs} 1
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-1的ecs功能，继续！"
		fi
	fi
	
	# new dns plan: chinadns-ng, trust-2，原生udp + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_2_enable}" == "1" -a "${ss_basic_chng_trust_2_opt}" == "1" -a "${ss_basic_chng_trust_2_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" -a -n "${UDP_TARGET}" ];then
					echo_date "启动dns-ecs-forcer，填入ECS标签：${REMOTE_IP_FRN%.*}.0"
					local TMP_PID=$(ps | grep -E "socat|uredir" | grep 2056 | awk '{print $1}')
					if [ -n "${TMP_PID}" ];then
						kill -9 ${TMP_PID}
					fi		
					run_bg dns-ecs-forcer -p 2056 -s ${UDP_TARGET} -e "${REMOTE_IP_FRN%.*}.0"
					detect_running_status2 dns-ecs-forcer 2056 slient
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
		fi
	fi
	
	# new dns plan: chinadns-ng, trust-2，原生tcp + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_2_enable}" == "1" -a "${ss_basic_chng_trust_2_opt}" == "2" -a "${ss_basic_chng_trust_2_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" -a -n "${TCP_TARGET}" ];then
					echo_date "启动dns-ecs-forcer，填入ECS标签：${REMOTE_IP_FRN%.*}.0"
					local TMP_PID=$(ps | grep -E "socat|uredir" | grep 2056 | awk '{print $1}')
					if [ -n "${TMP_PID}" ];then
						kill -9 ${TMP_PID}
					fi		
					run_bg dns-ecs-forcer -p 2056 -s ${TCP_TARGET} -e "${REMOTE_IP_FRN%.*}.0"
					detect_running_status2 dns-ecs-forcer 2056 slient
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
		fi
	fi
	
	# new dns plan: chinadns-ng, trust-2，dohclient + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "1" -a "${ss_basic_chng_trust_2_enable}" == "1" -a "${ss_basic_chng_trust_2_opt}" == "3" -a "${ss_basic_chng_trust_2_ecs}" == "1" ];then
		if [ "${ss_basic_nofrnipcheck}" != "1" ];then
			if [ -n "${REMOTE_IP_FRN}" ];then
				if [ "${ss_real_server_ip}" != "${REMOTE_IP_FRN}" ];then
					start_dohclient_chng restart frn2 ${ss_basic_chng_trust_2_opt_doh} ${ss_basic_chng_trust_2_ecs} 0
				fi
			else
				echo_date "因未获取到代理出口ip，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
			fi
		else
			echo_date "因插件关闭了代理出口ip检测，故无法开启chinadns-ng的可信DNS-2的ecs功能，继续！"
		fi
	fi
	
	# new dns plan-3: dohclient + ecs
	if [ "${ss_basic_advdns}" == "1" -a "${ss_dns_plan}" == "3" ];then
		if [ -n "${REMOTE_IP_OUT}" -o -n "${REMOTE_IP_FRN}"  ];then
			start_dohclient_main restart
		fi
	fi
}

check_status() {
	dbus remove ss_basic_wait
	if [ "$ss_failover_enable" == "1" ]; then
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssf_status.txt
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssc_status.txt
		run start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status_main.sh
	fi

	# 对一些域名进行预解析，如果本地有解析缓存，解析没有走路由器，则ipset没有写入导致无法走代理，所以一些域名可以预解析一次
	run_bg dnsclient -t 5 -i 2 @127.0.0.1 openai.com
	run_bg dnsclient -t 5 -i 2 @127.0.0.1 chat.openai.com
	run_bg dnsclient -t 5 -i 2 @127.0.0.1 stun.syncthing.net
}

disable_ss() {
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	if [ "${ss_basic_status}" == "0" ];then
		return
	fi
	echo_date
	echo_date ------------------------- 关闭【科学上网】 -----------------------------
	ss_pre_stop
	set_skin
	dbus remove ss_basic_server_ip
	stop_status $1
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	restart_dnsmasq
	flush_nat
	kill_cron_job
	dbus set ss_basic_status="0"
	echo_date ------------------------ 【科学上网】已关闭 ----------------------------
}

apply_ss() {
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	if [ "${ss_basic_status}" == "1" ];then
		echo_date ------------------------- 关闭【科学上网】 -----------------------------
		ss_pre_stop
		stop_status
		kill_process
		remove_ss_trigger_job
		remove_ss_reboot_job
		restore_conf
		restart_dnsmasq
		flush_nat
		kill_cron_job
	fi
	# pre-start
	echo_date ------------------------- 启动【科学上网】 -----------------------------
	ss_pre_start
	# start
	prepare_system
	resolv_server_ip
	ss_arg
	load_module
	creat_ipset
	create_dnsmasq_conf
	# 生成代理主程序配置
	[ "${ss_basic_type}" == "0" -o "${ss_basic_type}" == "1" ] && creat_ss_json
	[ "${ss_basic_type}" == "3" ] && creat_v2ray_json
	[ "${ss_basic_type}" == "4" ] && creat_xray_json
	[ "${ss_basic_type}" == "5" ] && creat_trojan_json
	# 开启代理主程序
	[ "${ss_basic_type}" == "0" -o "${ss_basic_type}" == "1" ] && start_ss_redir
	[ "${ss_basic_type}" == "3" ] && start_v2ray
	[ "${ss_basic_type}" == "4" ] && start_xray
	[ "${ss_basic_type}" == "5" ] && start_trojan
	[ "${ss_basic_type}" == "6" ] && start_naive
	[ "${ss_basic_type}" == "7" ] && start_tuic
	[ "${ss_basic_type}" == "8" ] && start_hysteria2
	start_kcp
	start_dns
	#===load nat start===
	load_nat
	#===load nat end===
	restart_dnsmasq
	auto_start
	write_cron_job
	set_ss_reboot_job
	set_ss_trigger_job
	write_numbers
	finish_start
	ss_post_start
	#httping_check
	#[ "$?" == "1" ] && return 1
	check_status
	# store current status
	dbus set ss_basic_status="1"
	echo_date ------------------------ 【科学上网】 启动完毕 ------------------------
}

# for debug
get_status() {
	echo_date
	echo_date =========================================================
	echo_date "PID of this script: $$"
	echo_date "PPID of this script: $PPID"
	echo_date ========== 本脚本的PID ==========
	ps | grep $$ | grep -v grep
	echo_date ========== 本脚本的PPID ==========
	ps | grep $PPID | grep -v grep
	echo_date ========== 所有运行中的shell ==========
	ps | grep "\.sh" | grep -v grep
	echo_date ------------------------------------

	WAN_ACTION=$(ps | grep /jffs/scripts/wan-start | grep -v grep)
	NAT_ACTION=$(ps | grep /jffs/scripts/nat-start | grep -v grep)
	WEB_ACTION=$(ps | grep "ss_config.sh" | grep -v grep)
	[ -n "$WAN_ACTION" ] && echo_date 路由器开机触发koolss重启！
	[ -n "$NAT_ACTION" ] && echo_date 路由器防火墙触发koolss重启！
	[ -n "$WEB_ACTION" ] && echo_date WEB提交操作触发koolss重启！

	iptables -nvL PREROUTING -t nat
	iptables -nvL OUTPUT -t nat
	iptables -nvL SHADOWSOCKS -t nat
	iptables -nvL SHADOWSOCKS_EXT -t nat
	iptables -nvL SHADOWSOCKS_GFW -t nat
	iptables -nvL SHADOWSOCKS_CHN -t nat
	iptables -nvL SHADOWSOCKS_GAM -t nat
	iptables -nvL SHADOWSOCKS_GLO -t nat
}

start_ws(){
	if [ -x "/koolshare/bin/websocketd" -a -f "/koolshare/ss/websocket.sh" ];then
		if [ -z "$(pidof websocketd)" ];then
			run_bg websocketd --port=803 /bin/sh /koolshare/ss/websocket.sh
		fi
	fi
}

# =========================================================================

case $ACTION in
start)
	set_lock
	if [ "$ss_basic_enable" == "1" ]; then
		logger "[软件中心]: 启动科学上网插件！"
		apply_ss >>"$LOG_FILE"
		#get_status >> /tmp/upload/test.txt
		start_ws
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	unset_lock
	;;
stop)
	set_lock
	disable_ss
	echo_date
	echo_date "你已经成功关闭科学上网服务~"
	echo_date "See you again!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	;;
restart)
	set_lock
	donwload_binary
	apply_ss
	start_ws
	echo_date
	echo_date "Across the Great Wall we can reach every corner in the world!"
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	;;
flush_nat)
	set_lock
	flush_nat
	unset_lock
	;;
start_nat)
	set_lock
	[ "$ss_basic_enable" == "1" ] && apply_ss
	#get_status >> /tmp/upload/test.txt
	unset_lock
	;;
esac
