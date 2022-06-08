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
DNSF_PORT=7913
DNSC_PORT=53
ISP_DNS1=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 1p)
ISP_DNS2=$(nvram get wan0_dns | sed 's/ /\n/g' | grep -v 0.0.0.0 | grep -v 127.0.0.1 | sed -n 2p)
IFIP_DNS1=$(echo $ISP_DNS1 | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
IFIP_DNS2=$(echo $ISP_DNS2 | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:")
lan_ipaddr=$(nvram get lan_ipaddr)
ip_prefix_hex=$(nvram get lan_ipaddr | awk -F "." '{printf ("0x%02x", $1)} {printf ("%02x", $2)} {printf ("%02x", $3)} {printf ("00/0xffffff00\n")}')
WAN_ACTION=$(ps | grep /jffs/scripts/wan-start | grep -v grep)
NAT_ACTION=$(ps | grep /jffs/scripts/nat-start | grep -v grep)
ARG_OBFS=""
OUTBOUNDS="[]"
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')

#-----------------------------------------------

cmd() {
	echo_date "$*" 2>&1
	"$@" 2>/dev/null
}

set_lock() {
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}

unset_lock() {
	flock -u 1000
	rm -rf "$LOCK_FILE"
}

set_skin(){
	local UI_TYPE=ASUSWRT
	local SC_SKIN=$(nvram get sc_skin)
	local ROG_FLAG=$(grep -o "680516" /www/form_style.css|head -n1)
	local TUF_FLAG=$(grep -o "D0982C" /www/form_style.css|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
	
	if [ -z "${SC_SKIN}" -o "${SC_SKIN}" != "${UI_TYPE}" ];then
		echo_date "安装${UI_TYPE}皮肤！"
		nvram set sc_skin="${UI_TYPE}"
		nvram commit
	fi
}

pre_set(){
	# set vcore name
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

	if [ "${ss_basic_tcore}" == "1" ];then
		TCORE_NAME=Xray
		TROJAN_CONFIG_TEMP="/tmp/xray_tmp.json"
		TROJAN_CONFIG_FILE="/koolshare/ss/xray.json"
	else
		TCORE_NAME=trojan
		TROJAN_CONFIG_TEMP="/tmp/trojan_nat_tmp.json"
		TROJAN_CONFIG_FILE="/koolshare/ss/trojan.json"
		TROJAN_CONFIG_TEMP_SOCKS="/tmp/trojan_client_tmp.json"
		TROJAN_CONFIG_FILE_SOCKS="/koolshare/ss/trojan_client.json"
	fi

	# set skin
	set_skin
}

donwload_binary(){
	# 二进制下载应该在fancyss关闭/重启前运行，这样可以利用代理进行下载
	if [ "${ss_basic_type}" == "0" -a "${ss_basic_rust}" == "1" -a "${ACTION}" == "restart" ]; then
		if [ ! -x "/koolshare/bin/sslocal" ];then
			echo_date "没有检测到shadowsocks-rust二进制文件:sslocal，准备下载..."
			sh /koolshare/scripts/ss_rust_update.sh download
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
	echo_date "插件将在5秒后自动关闭！！"
	local i=5
	while [ $i -ge 0 ]; do
		sleep 1
		echo_date $i
		let i--
	done
	dbus set ss_basic_enable="0"
	disable_ss >/dev/null
	echo_date "插件已关闭！！"
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
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
	2)
		echo "koolgame"
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
	2)
		echo "koolgame"
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
	esac
}

__valid_ip() {
	# 验证是否为ipv4或者ipv6地址，是则正确返回，不是返回空值
	local format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	local format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')
	if [ -n "$format_4" -a -z "$format_6" ]; then
		echo "$format_4"
		return 0
	elif [ -z "$format_4" -a -n "$format_6" ]; then
		echo "$format_6"
		return 0
	else
		echo ""
		return 1
	fi
}

__get_server_resolver() {
	local value_1="$ss_basic_server_resolver"
	local value_2="$ss_basic_server_resolver_user"
	local res
	if [ "$value_1" == "1" ]; then
		if [ -n "$IFIP_DNS1" ]; then
			res="$ISP_DNS1"
		else
			res="114.114.114.114"
		fi
	fi
	[ "$value_1" == "2" ] && res="223.5.5.5"
	[ "$value_1" == "3" ] && res="223.6.6.6"
	[ "$value_1" == "4" ] && res="114.114.114.114"
	[ "$value_1" == "5" ] && res="114.114.115.115"
	[ "$value_1" == "6" ] && res="1.2.4.8"
	[ "$value_1" == "7" ] && res="210.2.4.8"
	[ "$value_1" == "8" ] && res="117.50.11.11"
	[ "$value_1" == "9" ] && res="117.50.22.22"
	[ "$value_1" == "10" ] && res="180.76.76.76"
	[ "$value_1" == "11" ] && res="119.29.29.29"
	[ "$value_1" == "13" ] && res="8.8.8.8"
	[ "$value_1" == "14" ] && res="8.8.4.4"
	[ "$value_1" == "15" ] && res="9.9.9.9"
	[ "$value_1" == "16" ] && res="1.1.1.1"
	if [ "$value_1" == "12" ]; then
		if [ -n "$value_2" ]; then
			res=$(__valid_ip "$value_2")
			[ -z "$res" ] && res="114.114.114.114"
		else
			res="114.114.114.114"
		fi
	fi
	echo $res
}

__get_server_resolver_port() {
	local port
	if [ "$ss_basic_server_resolver" == "12" ]; then
		if [ -n "$ss_basic_server_resolver_user" ]; then
			port=$(echo "$ss_basic_server_resolver_user" | awk -F"#|:" '{print $2}')
			[ -z "$port" ] && port="53"
		else
			port="53"
		fi
	else
		port="53"
	fi
	echo $port
}

__resolve_ip() {
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "$domain1" -o -z "$domain2" ]; then
		# not ip, not domain
		echo ""
		return 2
	else
		# domain format
		SERVER_IP=$(nslookup "$1" $(__get_server_resolver):$(__get_server_resolver_port) | sed '1,4d' | awk '{print $3}' | grep -v : | awk 'NR==1{print}' 2>/dev/null)
		SERVER_IP=$(__valid_ip $SERVER_IP)
		if [ -n "$SERVER_IP" ]; then
			# success resolved
			echo "$SERVER_IP"
			return 0
		else
			# resolve failed
			echo ""
			return 1
		fi
	fi
}

# ================================= ss stop ===============================
restore_conf() {
	echo_date 删除ss相关的名单配置文件.
	local isconf=$(find /jffs/configs/dnsmasq.d/ -name "*.conf" 2>/dev/null)
	if [ -n "${isconf}" -o -f "/jffs/configs/dnsmasq.conf.add" -o -f "/jffs/scripts/dnsmasq.postconf" ];then
		rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
		rm -rf /jffs/configs/dnsmasq.d/cdn.conf
		rm -rf /jffs/configs/dnsmasq.d/custom.conf
		rm -rf /jffs/configs/dnsmasq.d/wblist.conf
		rm -rf /jffs/configs/dnsmasq.d/ss_host.conf
		rm -rf /jffs/configs/dnsmasq.d/ss_server.conf
		rm -rf /jffs/configs/dnsmasq.conf.add
		rm -rf /jffs/scripts/dnsmasq.postconf
		rm -rf /tmp/sscdn.conf
		rm -rf /tmp/custom.conf
		rm -rf /tmp/wblist.conf
		rm -rf /tmp/ss_host.conf
		rm -rf /tmp/smartdns.conf
		rm -rf /tmp/gfwlist.txt
	fi
}

kill_process() {
	v2ray_process=$(pidof v2ray)
	if [ -n "$v2ray_process" ]; then
		echo_date 关闭V2Ray进程...
		# 有时候killall杀不了v2ray进程，所以用不同方式杀两次
		killall v2ray >/dev/null 2>&1
		kill -9 "$v2ray_process" >/dev/null 2>&1
	fi
	xray_process=$(pidof xray)
	if [ -n "$xray_process" ]; then
		echo_date 关闭xray进程...
		[ -f "/koolshare/perp/xray/rc.main" ] && perpctl d xray >/dev/null 2>&1
		rm -rf /koolshare/perp/xray
		killall xray >/dev/null 2>&1
		kill -9 "$xray_process" >/dev/null 2>&1
	fi
	trojan_process=$(pidof trojan)
	if [ -n "$trojan_process" ]; then
		echo_date 关闭trojan进程...
		killall trojan >/dev/null 2>&1
	fi
	ssredir=$(pidof ss-redir)
	if [ -n "$ssredir" ]; then
		echo_date 关闭ss-redir进程...
		killall ss-redir >/dev/null 2>&1
	fi
	rssredir=$(pidof rss-redir)
	if [ -n "$rssredir" ]; then
		echo_date 关闭ssr-redir进程...
		killall rss-redir >/dev/null 2>&1
	fi
	sslocal=$(ps | grep -w ss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}')
	if [ -n "$sslocal" ]; then
		echo_date 关闭ss-local进程:23456端口...
		kill $sslocal >/dev/null 2>&1
	fi
	ssrlocal=$(ps | grep -w rss-local | grep -v "grep" | grep -w "23456" | awk '{print $1}')
	if [ -n "$ssrlocal" ]; then
		echo_date 关闭ssr-local进程:23456端口...
		kill $ssrlocal >/dev/null 2>&1
	fi
	ssrustlocal=$(pidof sslocal)
	if [ -n "$ssrustlocal" ]; then
		echo_date 关闭sslocal进程...
		kill $ssrustlocal >/dev/null 2>&1
	fi
	sstunnel=$(pidof ss-tunnel)
	if [ -n "$sstunnel" ]; then
		echo_date 关闭进程...
		killall ss-tunnel >/dev/null 2>&1
	fi
	rsstunnel=$(pidof rss-tunnel)
	if [ -n "$rsstunnel" ]; then
		echo_date 关闭rss-tunnel进程...
		killall rss-tunnel >/dev/null 2>&1
	fi
	chinadns_process=$(pidof chinadns)
	if [ -n "$chinadns_process" ]; then
		echo_date 关闭chinadns2进程...
		killall chinadns >/dev/null 2>&1
	fi
	chinadns1_process=$(pidof chinadns1)
	if [ -n "$chinadns1_process" ]; then
		echo_date 关闭chinadns1进程...
		killall chinadns1 >/dev/null 2>&1
	fi
	chinadnsNG_process=$(pidof chinadns-ng)
	if [ -n "$chinadnsNG_process" ]; then
		echo_date 关闭chinadns-ng进程...
		killall chinadns-ng >/dev/null 2>&1
	fi
	cdns_process=$(pidof cdns)
	if [ -n "$cdns_process" ]; then
		echo_date 关闭cdns进程...
		killall cdns >/dev/null 2>&1
	fi
	dns2socks_process=$(pidof dns2socks)
	if [ -n "$dns2socks_process" ]; then
		echo_date 关闭dns2socks进程...
		killall dns2socks >/dev/null 2>&1
	fi
	smartdns_process=$(pidof smartdns)
	if [ -n "$smartdns_process" ]; then
		echo_date 关闭smartdns进程...
		killall smartdns >/dev/null 2>&1
	fi
	koolgame_process=$(pidof koolgame)
	if [ -n "$koolgame_process" ]; then
		echo_date 关闭koolgame进程...
		killall koolgame >/dev/null 2>&1
	fi
	pdu_process=$(pidof pdu)
	if [ -n "$pdu_process" ]; then
		echo_date 关闭pdu进程...
		kill -9 $pdu >/dev/null 2>&1
	fi
	kcptun_process=$(pidof kcptun)
	if [ -n "$kcptun_process" ]; then
		echo_date 关闭kcp协议进程...
		killall kcptun >/dev/null 2>&1
	fi
	haproxy_process=$(pidof haproxy)
	if [ -n "$haproxy_process" ]; then
		echo_date 关闭haproxy进程...
		killall haproxy >/dev/null 2>&1
	fi
	speederv1_process=$(pidof speederv1)
	if [ -n "$speederv1_process" ]; then
		echo_date 关闭speederv1进程...
		killall speederv1 >/dev/null 2>&1
	fi
	speederv2_process=$(pidof speederv2)
	if [ -n "$speederv2_process" ]; then
		echo_date 关闭speederv2进程...
		killall speederv2 >/dev/null 2>&1
	fi
	ud2raw_process=$(pidof udp2raw)
	if [ -n "$ud2raw_process" ]; then
		echo_date 关闭ud2raw进程...
		killall udp2raw >/dev/null 2>&1
	fi
	https_dns_proxy_process=$(pidof https_dns_proxy)
	if [ -n "$https_dns_proxy_process" ]; then
		echo_date 关闭https_dns_proxy进程...
		killall https_dns_proxy >/dev/null 2>&1
	fi
	# only close haveged form fancyss, not haveged from system
	haveged_pid=$(ps |grep "/koolshare/bin/haveged"|grep -v grep|awk '{print $1}')
	if [ -n "${haveged_pid}" ]; then
		echo_date 关闭haveged进程...
		killall haveged >/dev/null 2>&1
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
			echo_date 插件启动前触发:触发启动负载均衡功能！
			#start haproxy
			sh /koolshare/scripts/ss_lb_config.sh
		#else
			#echo_date 插件启动前触发:未选择负载均衡节点，不触发负载均衡启动！
		fi
	else
		if [ -n "${IS_LOCAL_ADDR}" -a "${ss_basic_port}" == "${ss_lb_port}" ]; then
			echo_date 插件启动前触发【警告】：你选择了负载均衡节点，但是负载均衡开关未启用！！
		#else
			#echo_date ss启动前触发：你选择了普通节点，不触发负载均衡启动！
		fi
	fi
}
# ================================= ss start ==============================

resolv_server_ip() {
	local tmp server_ip
	if [ "$ss_basic_type" == "3" -a "$ss_basic_v2ray_use_json" == "1" ]; then
		#v2ray json配置在后面单独处理
		return 1
	elif [ "$ss_basic_type" == "4" -a "$ss_basic_xray_use_json" == "1" ]; then
		#xray json配置在后面单独处理
		return 1
	else
		# 判断服务器域名格式
		tmp=$(__valid_ip "$ss_basic_server")
		if [ $? == 0 ]; then
			# server is ip address format, not need to resolve.
			echo_date "检测到你的$(__get_type_abbr_name)服务器已经是IP格式：$ss_basic_server,跳过解析... "
			ss_basic_server_ip="$ss_basic_server"
			dbus set ss_basic_server_ip=$ss_basic_server
		else
			echo_date "检测到你的$(__get_type_abbr_name)服务器：【$ss_basic_server】不是ip格式！"
			echo_date "尝试解析$(__get_type_abbr_name)服务器的ip地址，使用DNS：$(__get_server_resolver):$(__get_server_resolver_port)"
			echo_date "如果此处等待时间较久，建议在【节点域名解析DNS服务器】处更换DNS服务器..."
			server_ip=$(__resolve_ip "$ss_basic_server")
			case $? in
			0)
				echo_date "$(__get_type_abbr_name)服务器【$ss_basic_server】的ip地址解析成功：$server_ip"
				echo "server=/$ss_basic_server/$(__get_server_resolver)#$(__get_server_resolver_port)" >/jffs/configs/dnsmasq.d/ss_server.conf
				# server is domain format and success resolved.
				# 记录解析结果到/tmp/ss_host.conf，方便插件触发重启设定工作
				echo "address=/$ss_basic_server/$server_ip" >/tmp/ss_host.conf
				# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
				#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
				ss_basic_server="$server_ip"
				ss_basic_server_ip="$server_ip"
				dbus set ss_basic_server_ip="$server_ip"
				;;
			1)
				# server is domain format and failed to resolve.
				echo_date "$(__get_type_abbr_name)服务器的ip地址解析失败，将由ss-redir自己解析... "
				echo "server=/$ss_basic_server/$(__get_server_resolver)#$(__get_server_resolver_port)" >/jffs/configs/dnsmasq.d/ss_server.conf
				unset ss_basic_server_ip
				dbus remvoe ss_basic_server_ip
				;;
			2)
				# server is not ip either domain!
				echo_date "错误2！！检测到你设置的服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
				echo_date "请更正你的错误然后重试！！"
				close_in_five
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
		if [ "${ss_basic_ss_obfs}" == "tls" -o "${ss_basic_ss_obfs}" == "tls" ]; then
			echo_date "检测到你同时开启了obfs-local和v2ray-plugin！。"
			echo_date "插件只能支持开启一个SIP002插件！"
			echo_date "请更正设置后重试！"
			close_in_five
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
	if [ "$ss_basic_type" == "0" -a "${ss_basic_rust}" == "1" ]; then
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
		ARG_RUST_TUNNEL="--protocol tunnel -b 0.0.0.0:${DNSF_PORT} -s ${ss_basic_server}:${ss_basic_port} -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		ARG_RUST_SOCKS="-b 127.0.0.1:23456 -s ${ss_basic_server}:${ss_basic_port} -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
		ARG_RUST_REDIR_NS="--protocol redir -b 0.0.0.0:3333 -m ${ss_basic_method} -k ${ss_basic_password} ${RUST_ARG_1} ${RUST_ARG_2}"
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
	if [ "$ss_basic_type" == "0" ]; then
		cat >$CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "1" ]; then
		cat >$CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_address":"0.0.0.0",
			    "local_port":3333,
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "protocol":"$ss_basic_rss_protocol",
			    "protocol_param":"$ss_basic_rss_protocol_param",
			    "obfs":"$ss_basic_rss_obfs",
			    "obfs_param":"$ss_basic_rss_obfs_param",
			    "method":"$ss_basic_method"
			}
		EOF
	elif [ "$ss_basic_type" == "2" ]; then
		cat >$CONFIG_FILE <<-EOF
			{
			    "server":"$ss_basic_server",
			    "server_port":$ss_basic_port,
			    "local_port":3333,
			    "sock5_port":23456,
			    "dns2ss":$DNSF_PORT,
			    "adblock_addr":"",
			    "dns_server":"$ss_dns2ss_user",
			    "password":"$ss_basic_password",
			    "timeout":600,
			    "method":"$ss_basic_method",
			    "use_tcp":$ss_basic_koolgame_udp
			}
		EOF
	fi

	if [ "$ss_basic_udp2raw_boost_enable" == "1" -o "$ss_basic_udp_boost_enable" == "1" ]; then
		if [ "$ss_basic_udp_upstream_mtu" == "1" -a "$ss_basic_udp_node" == "$ssconf_basic_node" ]; then
			echo_date 设定MTU为 $ss_basic_udp_upstream_mtu_value
			cat /koolshare/ss/ss.json | jq --argjson MTU $ss_basic_udp_upstream_mtu_value '. + {MTU: $MTU}' >/koolshare/ss/ss_tmp.json
			mv /koolshare/ss/ss_tmp.json /koolshare/ss/ss.json
		fi
	fi
}

get_dns_name() {
	case "$1" in
	1)
		echo "cdns"
		;;
	2)
		echo "chinadns2"
		;;
	3)
		echo "dns2socks"
		;;
	4)
		if [ -n "$ss_basic_rss_obfs" ]; then
			echo "ssr-tunnel"
		else
			echo "ss-tunnel"
		fi
		;;
	5)
		echo "chinadns1"
		;;
	6)
		echo "https_dns_proxy"
		;;
	7)
		echo "${VCORE_NAME} dns"
		;;
	8)
		echo "koolgame内置"
		;;
	9)
		echo "SmartDNS"
		;;
	10)
		echo "chinadns-ng"
		;;
	esac
}

start_ss_local() {
	if [ "$ss_basic_type" == "1" ]; then
		echo_date 开启ssr-local，提供socks5代理端口：23456
		rss-local -l 23456 -c $CONFIG_FILE -u -f /var/run/sslocal1.pid >/dev/null 2>&1
	elif [ "$ss_basic_type" == "0" ]; then
		if [ "${ss_basic_rust}" == "1" ];then
			echo_date 开启sslocal，提供socks5代理端口：23456
			sslocal ${ARG_RUST_SOCKS} ${ARG_OBFS} -d >/dev/null 2>&1
		else
			echo_date 开启ss-local，提供socks5代理端口：23456
			ss-local -l 23456 -c $CONFIG_FILE $ARG_OBFS -u -f /var/run/sslocal1.pid >/dev/null 2>&1
		fi
	fi
}

start_dns() {
	# 判断使用何种DNS优先方案
	if [ "$ss_basic_mode" == "1" -a -z "$chn_on" -a -z "$all_on" -o "$ss_basic_mode" == "6" ];then
		# gfwlist模式的时候，且访问控制主机中不存在 大陆白名单模式 游戏模式 全局模式，则使用国内优先模式
		# 回国模式下自动判断使用国内优先
		local DNS_PLAN=1
	else
		# 其它情况，均使用国外优先模式
		local DNS_PLAN=2
	fi
	
	# 回国模式下强制改国外DNS为直连方式
	if [ "$ss_basic_mode" == "6" -a "$ss_foreign_dns" != "8" ]; then
		ss_foreign_dns="8"
		dbus set ss_foreign_dns="8"
	fi

	# Start cdns
	if [ "$ss_foreign_dns" == "1" ]; then
		[ "$DNS_PLAN" == "1" ] && echo_date "开启cdns，用于【国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启cdns，用于【国外所有网站】的DNS解析..."
		cdns -c /koolshare/ss/rules/cdns.json >/dev/null 2>&1 &
	fi

	# Start chinadns2
	if [ "$ss_foreign_dns" == "2" ]; then
		[ "$DNS_PLAN" == "1" ] && echo_date "开启chinadns2，用于【国内所有网站 + 国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启chinadns2，用于【国内cdn网站 + 国外所有网站】的DNS解析..."
		clinet_ip="114.114.114.114"
		public_ip=$(nvram get wan0_realip_ip)
		if [ -z "$public_ip" ]; then
			# 路由公网ip为空则获取
			public_ip=$(curl --connect-timeout 1 --retry 0 --max-time 1 -s 'http://members.3322.org/dyndns/getip')
			if [ "$?" == "0" -a -n "$public_ip" ]; then
				# 获取成功
				echo_date 你的公网ip地址是：$public_ip
				dbus set ss_basic_publicip="$public_ip"
				clinet_ip="$public_ip"
			else
				# 获取失败，则自动为114
				[ -n "$ss_basic_publicip" ] && clinet_ip="$ss_basic_publicip"
			fi
		else
			# 获取失败，则自动为114
			clinet_ip="$public_ip"
		fi

		if [ -n "$ss_basic_server_ip" ]; then
			# 用chnroute去判断SS服务器在国内还是在国外
			ipset test chnroute $ss_basic_server_ip >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# ss服务器是国外IP
				ss_real_server_ip="$ss_basic_server_ip"
			else
				# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
				ss_real_server_ip="8.8.8.8"
			fi
		else
			# ss服务器可能是域名且没有正确解析
			ss_real_server_ip="8.8.8.8"
		fi
		chinadns -p $DNSF_PORT -s $ss_chinadns_user -e $clinet_ip,$ss_real_server_ip -c /koolshare/ss/rules/chnroute.txt >/dev/null 2>&1 &
	fi

	# Start DNS2SOCKS (default)
	if [ "$ss_foreign_dns" == "3" -o -z "$ss_foreign_dns" ]; then
		[ -z "$ss_foreign_dns" ] && dbus set ss_foreign_dns="3"
		start_ss_local
		[ "$DNS_PLAN" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
		dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
	fi

	# Start ss-tunnel
	if [ "$ss_foreign_dns" == "4" ]; then
		if [ "$ss_basic_type" == "1" ]; then
			[ "$DNS_PLAN" == "1" ] && echo_date "开启ssr-tunnel，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启ssr-tunnel，用于【国外所有网站】的DNS解析..."
			rss-tunnel -c $CONFIG_FILE -l $DNSF_PORT -L $ss_sstunnel_user -u -f /var/run/sstunnel.pid >/dev/null 2>&1
		elif [ "$ss_basic_type" == "0" ]; then
			[ "$DNS_PLAN" == "1" ] && echo_date "开启ss-tunnel，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启ss-tunnel，用于【国外所有网站】的DNS解析..."
			if [ "${ss_basic_rust}" == "1" ];then
				sslocal ${ARG_RUST_TUNNEL} -f ${ss_sstunnel_user} ${ARG_OBFS} -u -d >/dev/null 2>&1
			else
				ss-tunnel -c ${CONFIG_FILE} -l ${DNSF_PORT} -L ${ss_sstunnel_user} ${ARG_OBFS} -u -f /var/run/sstunnel.pid >/dev/null 2>&1
			fi
		elif [ "$ss_basic_type" == "3" -o "$ss_basic_type" == "4" -o "$ss_basic_type" == "5" ]; then
			echo_date $(__get_type_full_name $ss_basic_type)下不支持ss-tunnel，改用dns2socks！
			dbus set ss_foreign_dns=3
			start_ss_local
			[ "$DNS_PLAN" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
		fi
	fi

	#start chinadns1
	if [ "$ss_foreign_dns" == "5" ]; then
		# 当国内SmartDNS和国外chiandns1冲突
		if [ "$ss_dns_china" == "13" -a "$ss_foreign_dns" == "5" ]; then
			echo_date "！！中国DNS选择SmartDNS和外国DNS选择chiandns1冲突，将外国DNS默认改为dns2socks！！"
			ss_foreign_dns="3"
			dbus set ss_foreign_dns="3"
			start_ss_local
			[ "$DNS_PLAN" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
		else
			start_ss_local
			echo_date 开启dns2socks，用于chinadns1上游...
			dns2socks 127.0.0.1:23456 "$ss_chinadns1_user" 127.0.0.1:1055 >/dev/null 2>&1 &
			[ "$DNS_PLAN" == "1" ] && echo_date "开启chinadns1，用于【国内所有网站 + 国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启chinadns1，用于【国内cdn网站 + 国外所有网站】的DNS解析..."
			chinadns1 -p $DNSF_PORT -s $CDN,127.0.0.1:1055 -d -c /koolshare/ss/rules/chnroute.txt >/dev/null 2>&1 &
		fi
	fi

	#start chinadns_ng
	if [ "$ss_foreign_dns" == "10" ]; then
		start_ss_local
		echo_date 开启dns2socks，用于chinadns-ng的国外上游...
		[ -z "$ss_chinadnsng_user" ] && ss_chinadnsng_user="8.8.8.8:53"
		dns2socks 127.0.0.1:23456 "$ss_chinadnsng_user" 127.0.0.1:1055 >/dev/null 2>&1 &
		[ "$DNS_PLAN" == "1" ] && echo_date "开启chinadns-ng，用于【国内所有网站 + 国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启chinadns-ng，用于【国内所有网站 + 国外所有网站】的DNS解析..."
		cat /koolshare/ss/rules/gfwlist.conf|sed '/^server=/d'|sed 's/ipset=\/.//g'|sed 's/\/gfwlist//g' > /tmp/gfwlist.txt
		if [ "${ss_disable_aaaa}" == "1" ];then
			local EXT="-N"
		else
			local EXT=""
		fi
		chinadns-ng ${EXT} -l ${DNSF_PORT} -c ${CDN}#${DNSC_PORT} -t 127.0.0.1#1055 -g /tmp/gfwlist.txt -m /koolshare/ss/rules/cdn.txt -M >/dev/null 2>&1 &
	fi

	#start https_dns_proxy
	if [ "$ss_foreign_dns" == "6" ]; then
		[ "$DNS_PLAN" == "1" ] && echo_date "开启https_dns_proxy，用于【国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启https_dns_proxy，用于【国外所有网站】的DNS解析..."
		if [ -n "$ss_basic_server_ip" ]; then
			# 用chnroute去判断SS服务器在国内还是在国外
			ipset test chnroute $ss_basic_server_ip >/dev/null 2>&1
			if [ "$?" != "0" ]; then
				# ss服务器是国外IP
				ss_real_server_ip="$ss_basic_server_ip"
			else
				# ss服务器是国内ip （可能用了国内中转，那么用谷歌dns ip地址去作为国外edns标签）
				ss_real_server_ip="8.8.8.8"
			fi
		else
			# ss服务器可能是域名且没有正确解析
			ss_real_server_ip="8.8.8.8"
		fi
		https_dns_proxy -u nobody -p $DNSF_PORT -b 8.8.8.8,1.1.1.1,8.8.4.4,1.0.0.1,145.100.185.15,145.100.185.16,185.49.141.37 -e $ss_real_server_ip/16 -r "https://cloudflare-dns.com/dns-query?ct=application/dns-json&" -d
	fi

	# start v2ray DNSF_PORT
	if [ "$ss_foreign_dns" == "7" ]; then
		if [ "$ss_basic_type" == "3" -o "$ss_basic_type" == "4" ]; then
			return 0
		elif [ "$ss_basic_type" == "5" -a "$ss_basic_tcore" == "1" ]; then
			return 0
		else
			echo_date $(__get_type_full_name $ss_basic_type)下不支持${VCORE_NAME} dns，改用dns2socks！
			dbus set ss_foreign_dns=3
			start_ss_local
			[ "$DNS_PLAN" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
		fi
	fi

	# 开启SmartDNS
	if [ "$ss_dns_china" == "13" -a "$ss_foreign_dns" == "9" ]; then
		# 国内国外都启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式也不需要使用cdn.conf）
		[ "$DNS_PLAN" == "1" ] && echo_date "开启SmartDNS，用于【国内所有网站 + 国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启SmartDNS，用于【国内所有网站 + 国外所有网站】的DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
	elif [ "$ss_dns_china" == "13" -a "$ss_foreign_dns" != "9" ]; then
		# 国内启用SmartDNS，国外不启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则是根据国外DNS的选择而决定是否使用cdn.conf）
		[ "$DNS_PLAN" == "1" ] && echo_date "开启SmartDNS，用于【国内所有网站】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启SmartDNS，用于【国内cdn网站】的DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d /foreign/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d /foreign/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
	elif [ "$ss_dns_china" != "13" -a "$ss_foreign_dns" == "9" ]; then
		# 国内不启用SmartDNS，国外启用SmartDNS （此情况下，如果是gfwlist模式则不用cdn.conf；如果是大陆白名单模式则需要使用cdn.conf）
		[ "$DNS_PLAN" == "1" ] && echo_date "开启SmartDNS，用于【国外gfwlist站点】的DNS解析..."
		[ "$DNS_PLAN" == "2" ] && echo_date "开启SmartDNS，用于【国外所有网站】的DNS解析..."
		#if [ "$(nvram get ipv6_service)" == "disabled" ]; then
		#	sed 's/# force-AAAA-SOA yes/force-AAAA-SOA yes/g' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#	sed -i '/^#/d /^$/d /china/d' /tmp/smartdns.conf
		#else
			sed '/^#/d /^$/d /china/d' /koolshare/ss/rules/smartdns_template.conf > /tmp/smartdns.conf
		#fi
		smartdns -c /tmp/smartdns.conf >/dev/null 2>&1 &
	fi

	# direct
	if [ "$ss_foreign_dns" == "8" ]; then
		if [ "$ss_basic_mode" == "6" ]; then
			echo_date 回国模式，国外DNS采用直连方案。
		else
			echo_date 非回国模式，国外DNS直连解析不能使用，自动切换到dns2socks方案。
			dbus set ss_foreign_dns=3
			start_ss_local
			[ "$DNS_PLAN" == "1" ] && echo_date "开启dns2socks，用于【国外gfwlist站点】的DNS解析..."
			[ "$DNS_PLAN" == "2" ] && echo_date "开启dns2socks，用于【国外所有网站】的DNS解析..."
			dns2socks 127.0.0.1:23456 "$ss_dns2socks_user" 127.0.0.1:$DNSF_PORT >/dev/null 2>&1 &
		fi
	fi
}
#--------------------------------------------------------------------------------------

detect_domain() {
	domain1=$(echo $1 | grep -E "^https://|^http://|www|/")
	domain2=$(echo $1 | grep -E "\.")
	if [ -n "$domain1" -o -z "$domain2" ]; then
		return 1
	else
		return 0
	fi
}

create_dnsmasq_conf() {
	if [ "$ss_dns_china" == "1" ]; then
		if [ "$ss_basic_mode" == "6" ]; then
			# 使用回国模式的时候，ISP dns是国外的，所以这里直接用114取代
			CDN="114.114.114.114"
		else
			if [ -n "$IFIP_DNS1" ]; then
				# 用chnroute去判断运营商DNS是否为局域网(国外)ip地址，有些二级路由的是局域网ip地址，会被ChinaDNS 判断为国外dns服务器，这个时候用114取代之
				ipset test chnroute $IFIP_DNS1 >/dev/null 2>&1
				if [ "$?" != "0" ]; then
					# 运营商DNS：ISP_DNS1是局域网(国外)ip
					CDN="114.114.114.114"
				else
					# 运营商DNS：ISP_DNS1是国内ip
					CDN="$ISP_DNS1"
				fi
			else
				# 运营商DNS：ISP_DNS1不是ip格式，用114取代之
				CDN="114.114.114.114"
			fi
		fi
	fi
	[ "$ss_dns_china" == "2" ] && CDN="223.5.5.5"
	[ "$ss_dns_china" == "3" ] && CDN="223.6.6.6"
	[ "$ss_dns_china" == "4" ] && CDN="114.114.114.114"
	[ "$ss_dns_china" == "5" ] && CDN="114.114.115.115"
	[ "$ss_dns_china" == "6" ] && CDN="1.2.4.8"
	[ "$ss_dns_china" == "7" ] && CDN="210.2.4.8"
	[ "$ss_dns_china" == "8" ] && CDN="117.50.11.11"
	[ "$ss_dns_china" == "9" ] && CDN="117.50.22.22"
	[ "$ss_dns_china" == "10" ] && CDN="180.76.76.76"
	[ "$ss_dns_china" == "11" ] && CDN="119.29.29.29"
	[ "$ss_dns_china" == "12" ] && {
		[ -n "$ss_dns_china_user" ] && CDN="$ss_dns_china_user" || CDN="114.114.114.114"
	}
	if [ "$ss_dns_china" == "13" ];then
		CDN="127.0.0.1"
		DNSC_PORT=5335
	fi

	# delete pre settings
	rm -rf /tmp/sscdn.conf
	rm -rf /tmp/custom.conf
	rm -rf /tmp/wblist.conf
	rm -rf /tmp/gfwlist.conf
	rm -rf /tmp/gfwlist.txt
	rm -rf /jffs/configs/dnsmasq.d/custom.conf
	rm -rf /jffs/configs/dnsmasq.d/wblist.conf
	rm -rf /jffs/configs/dnsmasq.d/cdn.conf
	rm -rf /jffs/configs/dnsmasq.d/gfwlist.conf
	rm -rf /jffs/scripts/dnsmasq.postconf
	rm -rf /tmp/smartdns.conf

	# custom dnsmasq settings by user
	if [ -n "$ss_dnsmasq" ]; then
		echo_date 添加自定义dnsmasq设置到/tmp/custom.conf
		echo "$ss_dnsmasq" | base64_decode | sort -u >>/tmp/custom.conf
	fi

	# these sites need to go ss inside router
	if [ "$ss_basic_mode" != "6" ]; then
		echo "#for router itself" >>/tmp/wblist.conf
		echo "server=/.google.com.tw/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.google.com.tw/router" >>/tmp/wblist.conf
		echo "server=/dns.google.com/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/dns.google.com/router" >>/tmp/wblist.conf
		echo "server=/.github.com/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.github.com/router" >>/tmp/wblist.conf
		echo "server=/.github.io/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.github.io/router" >>/tmp/wblist.conf
		echo "server=/.raw.githubusercontent.com/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.raw.githubusercontent.com/router" >>/tmp/wblist.conf
		echo "server=/.adblockplus.org/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.adblockplus.org/router" >>/tmp/wblist.conf
		echo "server=/.entware.net/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.entware.net/router" >>/tmp/wblist.conf
		echo "server=/.apnic.net/127.0.0.1#$DNSF_PORT" >>/tmp/wblist.conf
		echo "ipset=/.apnic.net/router" >>/tmp/wblist.conf
	fi

	# append white domain list, not through ss
	wanwhitedomain=$(echo $ss_wan_white_domain | base64_decode)
	if [ -n "$ss_wan_white_domain" ]; then
		echo_date 应用域名白名单
		echo "#for white_domain" >>/tmp/wblist.conf
		for wan_white_domain in $wanwhitedomain; do
			detect_domain "$wan_white_domain"
			if [ "$?" == "0" ]; then
				# 回国模式下，用外国DNS，否则用中国DNS。
				if [ "$ss_basic_mode" != "6" ]; then
					echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#$DNSC_PORT/g" >>/tmp/wblist.conf
					echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
				else
					echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$ss_direct_user/g" >>/tmp/wblist.conf
					echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
				fi
			else
				echo_date ！！检测到域名白名单内的【"$wan_white_domain"】不是域名格式！！此条将不会添加！！
			fi
		done
	fi

	# 非回国模式下，apple 和 microsoft需要中国cdn；
	# 另外：dns.msftncsi.com是asuswrt/merlin固件里，用以判断网络是否畅通的地址，固件后台会通过解析dns.msftncsi.com （nvram get dns_probe_content），并检查其解析结果是否和`nvram get dns_probe_content`匹配
	# 此地址在非回国模式下用国内DNS解析，以免SS/SSR/V2RAY线路挂掉，导致一些走远端解析的情况下，无法获取到dns.msftncsi.com的解析结果，从而使得【网络地图】中网络显示断开。
	if [ "$ss_basic_mode" != "6" ]; then
		echo "#for special site (Mandatory China DNS)" >>/tmp/wblist.conf
		for wan_white_domain2 in "apple.com" "microsoft.com" "dns.msftncsi.com"; do
			echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#$DNSC_PORT/g" >>/tmp/wblist.conf
			echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >>/tmp/wblist.conf
		done
	fi

	# append black domain list, through ss
	wanblackdomain=$(echo $ss_wan_black_domain | base64_decode)
	if [ -n "$ss_wan_black_domain" ]; then
		echo_date 应用域名黑名单
		echo "#for black_domain" >>/tmp/wblist.conf
		for wan_black_domain in $wanblackdomain; do
			detect_domain "$wan_black_domain"
			if [ "$?" == "0" ]; then
				if [ "$ss_basic_mode" != "6" ]; then
					echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#$DNSF_PORT/g" >>/tmp/wblist.conf
					echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >>/tmp/wblist.conf
				else
					echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN#$DNSC_PORT/g" >>/tmp/wblist.conf
					echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >>/tmp/wblist.conf
				fi
			else
				echo_date ！！检测到域名黑名单内的【"$wan_black_domain"】不是域名格式！！此条将不会添加！！
			fi
		done
	fi

	# 使用cdn.conf和gfwlist的策略
	# cdn.conf的作用：cdn.conf内包含了4万多条国内的网站，基本包含了普通人的所有国内上网需求，使用cdn.conf会让里面指定的网站强制走中国DNS的解析
	# gfwlist的主用：gfwlist内包含了已知的被墙网站，大部分人的翻墙需求（google, youtube, netflix, etc...），能得到满足，使用gfwlist会让里面指定的网站走国外的dns解析（墙内出去需要防污染，墙外进来直连即可）
	# 1.1 在国内优先模式下（在墙内出去），dnsmasq的全局dns是中国的，所以不需要cdn.conf，此时对路由的dnsmasq的负担也较小，但是为了保证国外被墙的网站解析无污染，使用gfwlist来解析国外被墙网站（此处需要防污染的软件来获得正确dns，如dns2socks的转发方式，chinadns的过滤方式，cdns的edns的特殊获取方式等），这样如果遇到gfwlist漏掉的，或者上普通未被墙的国外网站可能速度较慢；
	# 1.2 在国内优先模式下（在墙外回来），dnsmasq的全局dns是中国的，所以不需要cdn.conf，此时对路由的dnsmasq的负担也较小，但是为了保证国外被墙的网站解析无污染，使用gfwlist来解析国外被墙网站（因为本来身在国外，直连国外当地dns即可，如果转发，则会让这些请求在国内vps上去做，导致污染，如果使用chinadns过滤，则无需指定通过转发的），但是这样会导致很多国外网站的访问是从国内的vps发起的，导致一些国外网站的体验不好

	# 2.1 在国外优先的模式下（在墙内出去），dnsmasq的全局dns是国外的（此处需要使用防污染的软件来获得正确的dns），但是要保证国内的网站的解析效果，只好引入cdn.conf，此时路由的负担也会较大，这样国内的网站解析效果完全靠cdn.tx，一般来说能普通人的所有国内上网需求
	# 2.2 在国外优先的模式下（在墙外回来），dnsmasq的全局dns是国外的（此处只需要直连国外当地的dns服务器即可！），但是要保证国内的网站的解析效果，只好引入cdn.conf，此时路由的负担也会较大，这样国内的网站解析效果完全靠cdn.conf，一般来说翻墙回来都是看国内影视剧和音乐等需要，cdn.conf应该能够满足。

	# 总结
	# 国内优先模式，使用gfwlist，不用cdn.conf，国内cdn好，国外cdn差，路由器负担小
	# 国外优先模式，不用gfwlist，使用cdn.conf，国内cdn好，国外cdn好，路由器负担大（dns2socks ss-tunnel，cdns）
	# 国外优先模式，如果dns自带了国内cdn，不用gfwlist，不用cdn.conf，国内cdn好，国外cdn好，路由器负小（chinadns1 chinadns2）

	# 使用场景
	# 1.1 gfwlist模式：该模式的特点就是只有gfwlist内的网站走代理，所以dns部分也应该是相同的策略，即国内优先模式。
	# 1.2 在gfwlist模式下，如果访问控制内有主机走chnroute模式，那么怎么办？也许这台主机希望获得更好的国外访问效果？原来ks的策略是如果检测到这种情况则切换到国外优先，并且保持gfwlist存在（因为主模式下的主机在iptables内必须匹配gfwlist的ipset）；
	# 2.1 chnroute模式：除了国内的IP不走代理，其余都应该走代理，即使是某个国外的网站未被墙，因为用户的初衷是为了获得更好的国外访问效果才使用chnroute模式，所以dns部分也应该是类似的策略，即国外优先模式：
	# 2.2 在chnroute模式下，如果访问控制内有主机走gfwlist模式，那么怎么办？这台机器应该指望着获得更好的国内访问效果？原来ks的策略是如果检测这种情况，保持国外优先不变的情况下，再引入gfwlist（因为这些gfwlist的主机在iptables内必须匹配gfwlist的ipset）；
	# 对于访问控制存在上面的情况，都是向着国外优先

	# 指定策略
	# 1 一刀切的自动方案：和原KS方案相同，不过对于回国模式需要做出修改，国外的dns不能由软件转发等，直连就行了（fix）
	# 2 用户自己选择，一刀切的方案很多情况下都会走到国外优先上去，这对路由器的负担是很大的，而多数人的上网需求国内优先就足够了，一些人需要国外访问快（代理够快的情况下），可以自行选择国外优先（todo）
	# 3 所以最终保留自动方案，增加国内优先和国外优先的选择方案（todo）

	# 此处决定何时使用cdn.txt
	if [ "$ss_basic_mode" == "6" ]; then
		# 回国模式中，因为国外DNS无论如何都不会污染的，所以采取的策略是直连就行，默认国内优先即可
		echo_date 自动判断在回国模式中使用国内优先模式，不加载cdn.conf
	else
		if [ "$ss_basic_mode" == "1" -a -z "$chn_on" -a -z "$all_on" -o "$ss_basic_mode" == "6" ]; then
			# gfwlist模式的时候，且访问控制主机中不存在 大陆白名单模式 游戏模式 全局模式，则使用国内优先模式
			# 回国模式下自动判断使用国内优先
			echo_date 自动判断使用国内优先模式，不加载cdn.conf
		else
			# 其它情况，均使用国外优先模式，以下区分是否加载cdn.conf
			# if [ "$ss_foreign_dns" == "2" -o "$ss_foreign_dns" == "5" -o "$ss_foreign_dns" == "9" -a "$ss_dns_china" == "13" ]; then
			if [ "$ss_foreign_dns" == "2" -o "$ss_foreign_dns" == "5" -a "$ss_dns_china" != "13" -o "$ss_foreign_dns" == "10" ]; then
				# 因为chinadns1 chinadns2自带国内cdn，所以也不需要cdn.conf
				echo_date 自动判断dns解析使用国外优先模式...
				echo_date 国外解析方案【$(get_dns_name $ss_foreign_dns)】自带国内cdn，无需加载cdn.conf，路由器开销小...
			else
				echo_date 自动判断dns解析使用国外优先模式...
				echo_date 国外解析方案【$(get_dns_name $ss_foreign_dns)】，需要加载cdn.conf提供国内cdn...
				echo_date 生成cdn加速列表到/tmp/sscdn.conf，加速用的dns：$CDN
				echo "#for china site CDN acclerate" >>/tmp/sscdn.conf
				cat /koolshare/ss/rules/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN#$DNSC_PORT/g" | sort | awk '{if ($0!=line) print;line=$0}' >>/tmp/sscdn.conf
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

	if [ -f /tmp/sscdn.conf ]; then
		#echo_date 创建cdn加速列表软链接/jffs/configs/dnsmasq.d/cdn.conf
		ln -sf /tmp/sscdn.conf /jffs/configs/dnsmasq.d/cdn.conf
	fi

	# 此处决定何时使用gfwlist.txt
	if [ "$ss_basic_mode" == "1" ]; then
		echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
	elif [ "$ss_basic_mode" == "2" -o "$ss_basic_mode" == "3" ]; then
		if [ -n "$gfw_on" ]; then
			echo_date 创建gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
			ln -sf /koolshare/ss/rules/gfwlist.conf /jffs/configs/dnsmasq.d/gfwlist.conf
		fi
	elif [ "$ss_basic_mode" == "6" ]; then
		# 回国模式下默认方案是国内优先，所以gfwlist里的网站不能由127.0.0.1#7913来解析了，应该是国外当地直连
		if [ -n "$(echo $ss_direct_user | grep :)" ]; then
			echo_date 国外直连dns设定格式错误，将自动更正为8.8.8.8#53.
			ss_direct_user="8.8.8.8#53"
			dbus set ss_direct_user="8.8.8.8#53"
		fi
		echo_date 创建回国模式专用gfwlist的软连接到/jffs/etc/dnsmasq.d/文件夹.
		[ -z "$ss_direct_user" ] && ss_direct_user="8.8.8.8#53"
		cat /koolshare/ss/rules/gfwlist.conf | sed "s/127.0.0.1#$DNSF_PORT/$ss_direct_user/g" >/tmp/gfwlist.conf
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
		[ -z "$ss_basic_kcp_server" ] && ss_basic_kcp_server="$ss_basic_server"
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
				[ -z "$ss_basic_udpv1_rserver" ] && ss_basic_udpv1_rserver="$ss_basic_server_ip"
				[ -n "$ss_basic_udpv1_duplicate_time" ] && duplicate_time="-t $ss_basic_udpv1_duplicate_time" || duplicate_time=""
				[ -n "$ss_basic_udpv1_jitter" ] && jitter="-j $ss_basic_udpv1_jitter" || jitter=""
				[ -n "$ss_basic_udpv1_report" ] && report="--report $ss_basic_udpv1_report" || report=""
				[ -n "$ss_basic_udpv1_drop" ] && drop="--random-drop $ss_basic_udpv1_drop" || drop=""
				[ -n "$ss_basic_udpv1_duplicate_nu" ] && duplicate="-d $ss_basic_udpv1_duplicate_nu" || duplicate=""
				[ -n "$ss_basic_udpv1_password" ] && key1="-k $ss_basic_udpv1_password" || key1=""
				[ "$ss_basic_udpv1_disable_filter" == "1" ] && filter="--disable-filter" || filter=""

				if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
					#串联：如果两者都开启了，则把udpspeeder的流udp量转发给udp2raw
					speederv1 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key1 $ss_basic_udpv1_password \
						$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu >/dev/null 2>&1 &
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					speederv1 -c -l 0.0.0.0:1092 -r $ss_basic_udpv1_rserver:$ss_basic_udpv1_rport $key1 \
						$duplicate_time $jitter $report $drop $filter $duplicate $ss_basic_udpv1_duplicate_nu >/dev/null 2>&1 &
				fi
			elif [ "$ss_basic_udp_software" == "2" ]; then
				echo_date 开启UDPspeederV2进程.
				[ -z "$ss_basic_udpv2_rserver" ] && ss_basic_udpv2_rserver="$ss_basic_server_ip"
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
					speederv2 -c -l 0.0.0.0:1092 -r 127.0.0.1:1093 $key2 \
						$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $disable_checksum $ss_basic_udpv2_other --fifo /tmp/fifo.file >/dev/null 2>&1 &
					#如果只开启了udpspeeder，则把udpspeeder的流udp量转发给服务器
				else
					speederv2 -c -l 0.0.0.0:1092 -r $ss_basic_udpv2_rserver:$ss_basic_udpv2_rport $key2 \
						$fec $timeout $mode $report $mtu $jitter $interval $drop $disable_obscure $disable_checksum $ss_basic_udpv2_other --fifo /tmp/fifo.file >/dev/null 2>&1 &
				fi
			fi
		fi
		#开启udp2raw
		if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
			echo_date 开启UDP2raw进程.
			[ -z "$ss_basic_udp2raw_rserver" ] && ss_basic_udp2raw_rserver="$ss_basic_server_ip"
			[ "$ss_basic_udp2raw_a" == "1" ] && UD2RAW_EX1="-a" || UD2RAW_EX1=""
			[ "$ss_basic_udp2raw_keeprule" == "1" ] && UD2RAW_EX2="--keep-rule" || UD2RAW_EX2=""
			[ -n "$ss_basic_udp2raw_lowerlevel" ] && UD2RAW_LOW="--lower-level $ss_basic_udp2raw_lowerlevel" || UD2RAW_LOW=""
			[ -n "$ss_basic_udp2raw_password" ] && key3="-k $ss_basic_udp2raw_password" || key3=""

			udp2raw -c -l 0.0.0.0:1093 -r $ss_basic_udp2raw_rserver:$ss_basic_udp2raw_rport $key3 $UD2RAW_EX1 $UD2RAW_EX2 \
				--raw-mode $ss_basic_udp2raw_rawmode --cipher-mode $ss_basic_udp2raw_ciphermode --auth-mode $ss_basic_udp2raw_authmode \
				$UD2RAW_LOW $ss_basic_udp2raw_other >/dev/null 2>&1 &
		fi
	fi
}

start_ss_redir() {
	if [ "$ss_basic_type" == "1" ]; then
		echo_date 开启ssr-redir进程，用于透明代理.
		BIN=rss-redir
		ARG_OBFS=""
	elif [ "$ss_basic_type" == "0" ]; then
		# ss-libev需要大于160的熵才能正常工作
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
		# 如果只开了udp2raw，则需要吧udp转发到1093
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
				if [ "$ss_basic_type" == "1" ]; then
					rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
					else
						ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
				# udp go udpspeeder
				[ "$ss_basic_udp2raw_boost_enable" == "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "$ss_basic_udp2raw_boost_enable" == "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走udpraw.
				[ "$ss_basic_udp2raw_boost_enable" != "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder.
				[ "$ss_basic_udp2raw_boost_enable" != "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走${BIN}.
				if [ "$ss_basic_type" == "1" ]; then
					rss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						sslocal -s "127.0.0.1:${SPEED_PORT}" ${ARG_RUST_REDIR_NS} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						ss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
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
					rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					rss-redir -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
						sslocal ${ARG_RUST_REDIR} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
						ss-redir -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
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
				rss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
			else
				if [ "${ss_basic_rust}" == "1" ];then
					sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
				else
					ss-redir -s 127.0.0.1 -p 1091 -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				fi
			fi
		fi
	else
		if [ "${mangle}" == "1" ]; then
			if [ "${SPEED_UDP}" == "1" -a "${ss_basic_udp_node}" == "${ssconf_basic_node}" ]; then
				# tcp go ss
				echo_date ${BIN}的 tcp 走${BIN}.
				if [ "${ss_basic_type}" == "1" ]; then
					rss-redir -c ${CONFIG_FILE} -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
					else
						ss-redir -c ${CONFIG_FILE} ${ARG_OBFS} -f /var/run/shadowsocks.pid >/dev/null 2>&1
					fi
				fi
				# udp go udpspeeder
				[ "${ss_basic_udp2raw_boost_enable}" == "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder, udpspeeder的 udp 走 udpraw
				[ "${ss_basic_udp2raw_boost_enable}" == "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走udpraw.
				[ "${ss_basic_udp2raw_boost_enable}" != "1" -a "$ss_basic_udp_boost_enable" == "1" ] && echo_date ${BIN}的 udp 走udpspeeder.
				[ "${ss_basic_udp2raw_boost_enable}" != "1" -a "$ss_basic_udp_boost_enable" != "1" ] && echo_date ${BIN}的 udp 走${BIN}.

				if [ "${ss_basic_type}" == "1" ]; then
					rss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
				else
					if [ "${ss_basic_rust}" == "1" ];then
						sslocal -s "127.0.0.1:1091" ${ARG_RUST_REDIR_NS} --udp-redir "tproxy" ${ARG_OBFS} -u -d >/dev/null 2>&1
					else
						ss-redir -s 127.0.0.1 -p ${SPEED_PORT} -c ${CONFIG_FILE} ${ARG_OBFS} -U -f /var/run/shadowsocks.pid >/dev/null 2>&1
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
						sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" --udp-redir "tproxy" ${ARG_OBFS} -U -d >/dev/null 2>&1
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
					sslocal ${ARG_RUST_REDIR} --tcp-redir "redirect" ${ARG_OBFS} -d >/dev/null 2>&1
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
	local ARG_1=""
	local ARG_2=""
	if [ "$ss_basic_type" == "0" -a "$ss_basic_mcore" == "1" -a "${LINUX_VER}" != "26" ];then
		local ARG_1="--reuse-port"
	fi
	if [ "$ss_basic_type" == "0" -a "$ss_basic_tfo" == "1" -a "${LINUX_VER}" != "26" ]; then
		local ARG_2="--fast-open"
		echo_date $BIN开启tcp fast open支持.
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi

	if [ "$ss_basic_type" == "0" -a "$ss_basic_tnd" == "1" ]; then
		echo_date $BIN开启TCP_NODELAY支持.
		local ARG_3="--no-delay"
	else
		local ARG_3=""
	fi

	if [ "$ss_basic_mcore" == "1" -a "${LINUX_VER}" != "26" ]; then
		echo_date $BIN开启$THREAD线程支持.
		local i=1
		while [ $i -le $THREAD ]; do
			cmd $1 $ARG_1 $ARG_2 $ARG_3 -f /var/run/ss_$i.pid
			let i++
		done
	else
		cmd $1 -f /var/run/ss.pid
	fi
}

start_koolgame() {
	# Start koolgame
	pdu=$(ps | grep pdu | grep -v grep)
	if [ -z "$pdu" ]; then
		echo_date 开启pdu进程，用于优化mtu...
		pdu br0 /tmp/var/pdu.pid >/dev/null 2>&1
		sleep 1
	fi
	echo_date 开启koolgame主进程...
	start-stop-daemon -S -q -b -m -p /tmp/var/koolgame.pid -x /koolshare/bin/koolgame -- -c $CONFIG_FILE

	if [ "$mangle" == "1" -a "$ss_basic_udp_node" == "$ssconf_basic_node" ]; then
		if [ "$ss_basic_udp_boost_enable" == "1" ]; then
			if [ "$ss_basic_udp_software" == "1" ]; then
				echo_date 检测到你启用了UDPspeederV1，但是koolgame下不支持UDPspeederV1加速，不启用！
				dbus set ss_basic_udp_boost_enable=0
			elif [ "$ss_basic_udp_software" == "2" ]; then
				echo_date 检测到你启用了UDPspeederV2，但是koolgame下不支持UDPspeederV1加速，不启用！
				dbus set ss_basic_udp_boost_enable=0
			fi
		fi
		if [ "$ss_basic_udp2raw_boost_enable" == "1" ]; then
			echo_date 检测到你启用了UDP2raw，但是koolgame下不支持UDP2raw，不启用！
			dbus set ss_basic_udp2raw_boost_enable=0
		fi
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

	local tmp v2ray_server_ip
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
		if [ "${ss_foreign_dns}" == "7" ]; then
			echo_date 配置${VCORE_NAME} dns，用于dns解析...
			cat >>"${V2RAY_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "8.8.8.8",
						"port": 53,
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
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
						"listen": "0.0.0.0",
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
								"address": "$ss_basic_server_orig",
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
		jq --tab . ${V2RAY_CONFIG_TEMP} >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five
		fi
		jq --tab . $V2RAY_CONFIG_TEMP >"$V2RAY_CONFIG_FILE"
		echo_date ${VCORE_NAME}配置文件写入成功到"$V2RAY_CONFIG_FILE"
	else
		echo_date 使用自定义的${VCORE_NAME} json配置文件...
		echo "$ss_basic_v2ray_json" | base64_decode >"$V2RAY_CONFIG_TEMP"
		local OB=$(cat "$V2RAY_CONFIG_TEMP" | jq .outbound)
		local OBS=$(cat "$V2RAY_CONFIG_TEMP" | jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_TEMP" | jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$V2RAY_CONFIG_TEMP" | jq .outbounds[0])
		fi
		
		if [ "$ss_foreign_dns" == "7" ]; then
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"protocol\": \"dokodemo-door\", 
										\"port\": $DNSF_PORT,
										\"settings\": {
											\"address\": \"8.8.8.8\",
											\"port\": 53,
											\"network\": \"udp\",
											\"timeout\": 0,
											\"followRedirect\": false
										}
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
										\"listen\": \"0.0.0.0\",
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
		echo_date 解析${VCORE_NAME}配置文件...
		echo $TEMPLATE | jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"$V2RAY_CONFIG_FILE"
		echo_date ${VCORE_NAME}配置文件写入成功到"$V2RAY_CONFIG_FILE"

		# 检查v2ray json是否配置了xtls，如果是，则自动切换为xray
		if [ -f "/koolshare/ss/v2ray.json" ];then
			local IS_XTLS=$(cat /koolshare/ss/v2ray.json | jq -r .outbounds[0].streamSettings.security 2>/dev/null)
			if [ "${IS_XTLS}" == "xtls" -a "${ss_basic_vcore}" != "1" ];then
				echo_date "ℹ️检测到你配置了支持xtls节点，而V2ray不支持xtls，自动切换为Xray核心！"
				ss_basic_vcore=1
				VCORE_NAME=Xray
				mv /koolshare/ss/v2ray.json /koolshare/ss/xray.json 
				V2RAY_CONFIG_FILE="/koolshare/ss/xray.json"
			fi
		fi

		# 检测用户json的服务器ip地址
		v2ray_protocal=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].protocol)
		case $v2ray_protocal in
		vmess|vless)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.vnext[0].address)
			;;
		socks)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		shadowsocks)
			v2ray_server=$(cat "$V2RAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		*)
			v2ray_server=""
			;;
		esac

		if [ -n "$v2ray_server" -a "$v2ray_server" != "null" ]; then
			# 服务器地址强制由用户选择的DNS解析，以免插件还未开始工作而导致解析失败
			echo "server=/$v2ray_server/$(__get_server_resolver)#$(__get_server_resolver_port)" >/jffs/configs/dnsmasq.d/ss_server.conf
			# 判断服务器域名格式
			tmp=$(__valid_ip "$v2ray_server")
			if [ $? == 0 ]; then
				echo_date "检测到你的json配置的${VCORE_NAME}服务器是：$v2ray_server"
				ss_basic_server_ip="$v2ray_server"
			else
				echo_date "检测到你的json配置的${VCORE_NAME}服务器：【$v2ray_server】不是ip格式！"
				echo_date "尝试解析${VCORE_NAME}服务器的ip地址，使用DNS：$(__get_server_resolver):$(__get_server_resolver_port)"
				echo_date "如果此处等待时间较久，建议在【节点域名解析DNS服务器】处更换DNS服务器..."
				v2ray_server_ip=$(__resolve_ip "$v2ray_server")
				case $? in
				0)
					# server is domain format and success resolved.
					echo_date "${VCORE_NAME}服务器的ip地址解析成功：$v2ray_server_ip"
					# 解析并记录一次ip，方便插件触发重启设定工作
					echo "address=/$v2ray_server/$v2ray_server_ip" >/tmp/ss_host.conf
					# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
					#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
					ss_basic_server_ip="$v2ray_server_ip"
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
					close_in_five
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
		echo_date 当前核心为${VCORE_NAME}，不进行配置文件测试....
	else
		echo_date 测试${VCORE_NAME}配置文件....
		cd /koolshare/bin
		result=$(v2ray -test -config="$V2RAY_CONFIG_FILE" | grep "Configuration OK.")
		if [ -n "$result" ]; then
			echo_date $result
			echo_date ${VCORE_NAME}配置文件通过测试!!!
		else
			echo_date ${VCORE_NAME}配置文件没有通过测试，请检查设置!!!
			rm -rf "$V2RAY_CONFIG_TEMP"
			rm -rf "$V2RAY_CONFIG_FILE"
			close_in_five
		fi
	fi
}

start_v2ray() {
	# tfo start
	if [ "$ss_basic_tfo" == "1" -a "${LINUX_VER}" != "26" ]; then
		echo_date 开启tcp fast open支持.
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
			perpctl -u xray >/dev/null 2>&1
		else
			echo_date "开启Xray主进程..."
			cd /koolshare/bin
			xray run -c $V2RAY_CONFIG_FILE >/dev/null 2>&1 &
		fi
		local XPID
		local i=25
		until [ -n "$XPID" ]; do
			i=$(($i - 1))
			XPID=$(pidof xray)
			if [ "$i" -lt 1 ]; then
				echo_date "${VCORE_NAME}进程启动失败！"
				close_in_five
			fi
			usleep 250000
		done
		echo_date ${VCORE_NAME}启动成功，pid：$XPID
	else
		# v2ray start
		echo_date "开启V2ray主进程..."
		cd /koolshare/bin
		v2ray --config=$V2RAY_CONFIG_FILE >/dev/null 2>&1 &
		local V2PID
		local i=25
		until [ -n "$V2PID" ]; do
			i=$(($i - 1))
			V2PID=$(pidof v2ray)
			if [ "$i" -lt 1 ]; then
				echo_date "${VCORE_NAME}进程启动失败！"
				close_in_five
			fi
			usleep 250000
		done
		echo_date ${VCORE_NAME}启动成功，pid：$V2PID
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

		if [ "${ss_basic_xray_network_security}" == "tls" ];then
			ss_basic_xray_flow=""
		fi

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
				local ss_basic_xray_network_security_sni="${ss_basicxray_network_host}"
			else
				local ss_basic_xray_network_security_sni=""
			fi
		fi

		if [ "${ss_basic_xray_network_security}" == "tls" ];then
			local tls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_xray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					}"
		else
			local tls="null"
		fi

		if [ "${ss_basic_xray_network_security}" == "xtls" ];then
			local xtls="{
					\"allowInsecure\": $(get_function_switch $ss_basic_xray_network_security_ai)
					,\"alpn\": ${apln}
					,\"serverName\": $(get_value_null $ss_basic_xray_network_security_sni)
					}"
		else
			local xtls="null"
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
		if [ "${ss_foreign_dns}" == "7" ]; then
			echo_date 配置xray dns，用于dns解析...
			cat >>"${XRAY_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "8.8.8.8",
						"port": 53,
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
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
						"listen": "0.0.0.0",
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
		cat >>"${XRAY_CONFIG_TEMP}" <<-EOF
			"outbounds": [
				{
					"tag": "proxy",
					"protocol": "vless",
					"settings": {
						"vnext": [
							{
								"address": "$ss_basic_server_orig",
								"port": $ss_basic_port,
								"users": [
									{
										"id": "$ss_basic_xray_uuid"
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
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' ${XRAY_CONFIG_TEMP} 2>/dev/null
		fi
		jq --tab . $XRAY_CONFIG_TEMP >/tmp/jq_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/jq_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/jq_para_tmp.txt
			close_in_five
		fi
		jq --tab . $XRAY_CONFIG_TEMP >$XRAY_CONFIG_FILE
		echo_date "Xray配置文件写入成功到$XRAY_CONFIG_FILE"
	else
		echo_date 使用自定义的Xray json配置文件...
		echo "$ss_basic_xray_json" | base64_decode >"$XRAY_CONFIG_TEMP"
		local OB=$(cat "$XRAY_CONFIG_TEMP" | jq .outbound)
		local OBS=$(cat "$XRAY_CONFIG_TEMP" | jq .outbounds)

		# 兼容旧格式：outbound
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat "$XRAY_CONFIG_TEMP" | jq .outbound)
		fi
		
		# 新格式：outbound[]
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat "$XRAY_CONFIG_TEMP" | jq .outbounds[0])
		fi
		
		if [ "$ss_foreign_dns" == "7" ]; then
			local TEMPLATE="{
								\"log\": {
									\"access\": \"none\",
									\"error\": \"none\",
									\"loglevel\": \"none\"
								},
								\"inbounds\": [
									{
										\"protocol\": \"dokodemo-door\", 
										\"port\": $DNSF_PORT,
										\"settings\": {
											\"address\": \"8.8.8.8\",
											\"port\": 53,
											\"network\": \"udp\",
											\"timeout\": 0,
											\"followRedirect\": false
										}
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
										\"listen\": \"0.0.0.0\",
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
		echo_date 解析Xray配置文件...
		echo $TEMPLATE | jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >"$XRAY_CONFIG_FILE"
		echo_date Xray配置文件写入成功到"$XRAY_CONFIG_FILE"

		# 检查xray json是否配置了xtls，如果是，则自动切换为xray
		if [ -f "/koolshare/ss/xray.json" ];then
			local IS_XTLS=$(cat /koolshare/ss/xray.json | jq -r .outbounds[0].streamSettings.security 2>/dev/null)
			if [ "${IS_XTLS}" == "xtls" -a "${ss_basic_vcore}" != "1" ];then
				echo_date "ℹ️检测到你配置了支持xtls节点，而Xray不支持xtls，自动切换为Xray核心！"
				ss_basic_vcore=1
				VCORE_NAME=Xray
				mv /koolshare/ss/xray.json /koolshare/ss/xray.json 
				XRAY_CONFIG_FILE="/koolshare/ss/xray.json"
			fi
		fi

		# 检测用户json的服务器ip地址
		xray_protocal=$(cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].protocol)
		case $xray_protocal in
		vmess|vless)
			xray_server=$(cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].settings.vnext[0].address)
			;;
		socks|shadowsocks|trojan)
			xray_server=$(cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address)
			;;
		*)
			xray_server=""
			;;
		esac

		if [ -n "$xray_server" -a "$xray_server" != "null" ]; then
			# 服务器地址强制由用户选择的DNS解析，以免插件还未开始工作而导致解析失败
			echo "server=/$xray_server/$(__get_server_resolver)#$(__get_server_resolver_port)" >/jffs/configs/dnsmasq.d/ss_server.conf
			# 判断服务器域名格式
			tmp=$(__valid_ip "$xray_server")
			if [ "$?" == "0" ]; then
				echo_date "检测到你的json配置的Xray服务器是：$xray_server"
				ss_basic_server_ip="$xray_server"
			else
				echo_date "检测到你的json配置的Xray服务器：【$xray_server】不是ip格式！"
				echo_date "尝试解析Xray服务器的ip地址，使用DNS：$(__get_server_resolver):$(__get_server_resolver_port)"
				echo_date "如果此处等待时间较久，建议在【节点域名解析DNS服务器】处更换DNS服务器..."
				xray_server_ip=$(__resolve_ip "$xray_server")
				case $? in
				0)
					# server is domain format and success resolved.
					echo_date "Xray服务器的ip地址解析成功：$xray_server_ip"
					# 解析并记录一次ip，方便插件触发重启设定工作
					echo "address=/$xray_server/$xray_server_ip" >/tmp/ss_host.conf
					# 去掉此功能，以免ip发生变更导致问题，或者影响域名对应的其它二级域名
					#ln -sf /tmp/ss_host.conf /jffs/configs/dnsmasq.d/ss_host.conf
					ss_basic_server_ip="$xray_server_ip"
					;;
				1)
					# server is domain format and failed to resolve.
					unset ss_basic_server_ip
					echo_date "Xray服务器的ip地址解析失败!插件将继续运行，域名解析将由Xray自己进行！"
					echo_date "请自行将Xray服务器的ip地址填入IP/CIDR白名单中!"
					echo_date "为了确保Xray的正常工作，建议配置ip格式的Xray服务器地址！"
					;;
				2)
					# server is not ip either domain!
					echo_date "错误1！！检测到json配置内的Xray服务器:${ss_basic_server}既不是ip地址，也不是域名格式！"
					echo_date "请更正你的错误然后重试！！"
					close_in_five
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
		perpctl -u xray >/dev/null 2>&1
	else
		echo_date "开启Xray主进程..."
		cd /koolshare/bin
		xray run -c $XRAY_CONFIG_FILE >/dev/null 2>&1 &
	fi
	local XPID
	local i=25
	until [ -n "$XPID" ]; do
		i=$(($i - 1))
		XPID=$(pidof xray)
		if [ "$i" -lt 1 ]; then
			echo_date "Xray进程启动失败！"
			close_in_five
		fi
		usleep 250000
	done
	echo_date Xray启动成功，pid：$XPID
}

creat_trojan_json(){
	if [ "$ss_foreign_dns" == "3" -o "$ss_foreign_dns" == "4" -o "$ss_foreign_dns" == "5" -o "$ss_foreign_dns" == "10" ]; then
		trojan_socks=1
	fi
	
	if [ -n "$WAN_ACTION" ]; then
		echo_date "检测到网络拨号/开机触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	elif [ -n "$NAT_ACTION" ]; then
		
		echo_date "检测到防火墙重启触发启动，不创建$(__get_type_abbr_name)配置文件，使用上次的配置文件！"
		return 0
	else
		if [ "${ss_basic_tcore}" == "1" ];then
			echo_date "创建xray的trojan配置文件到${TROJAN_CONFIG_FILE}"
		else
			echo_date "创建$(__get_type_abbr_name)的配置文件到${TROJAN_CONFIG_FILE}"
			[ "${trojan_socks}" == "1" ] && echo_date "创建$(__get_type_abbr_name)的client配置文件到${TROJAN_CONFIG_FILE_SOCKS}"
		fi
	fi

	if [ "${ss_basic_tcore}" == "1" ];then
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
		if [ "${ss_foreign_dns}" == "7" ]; then
			echo_date 配置${TCORE_NAME} dns，用于dns解析...
			cat >>"${TROJAN_CONFIG_TEMP}" <<-EOF
				"inbounds": [
					{
					"protocol": "dokodemo-door",
					"port": ${DNSF_PORT},
					"settings": {
						"address": "8.8.8.8",
						"port": 53,
						"network": "udp",
						"timeout": 0,
						"followRedirect": false
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
			if [ "${trojan_socks}" == "1" ];then
				# inbounds area (23456 for socks5)
				cat >>"$TROJAN_CONFIG_TEMP" <<-EOF
					"inbounds": [
						{
							"port": 23456,
							"listen": "0.0.0.0",
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
				# inbounds area
				cat >>"$TROJAN_CONFIG_TEMP" <<-EOF
					"inbounds": [
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
		jq --tab . ${TROJAN_CONFIG_TEMP} >/tmp/trojan_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/trojan_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/trojan_para_tmp.txt
			close_in_five
		fi
		jq --tab . ${TROJAN_CONFIG_TEMP} >${TROJAN_CONFIG_FILE}
		echo_date "解析成功！xray的trojan配置文件成功写入到${TROJAN_CONFIG_FILE}"
	else
		rm -rf "${TROJAN_CONFIG_TEMP}"
		rm -rf "${TROJAN_CONFIG_FILE}"
		rm -rf "${TROJAN_CONFIG_TEMP_SOCKS}"
		rm -rf "${TROJAN_CONFIG_FILE_SOCKS}"
		
		cat > "${TROJAN_CONFIG_TEMP}" <<-EOF
			{
				"run_type": "nat",
				"local_addr": "0.0.0.0",
				"local_port": 3333,
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
		EOF
		if [ "${LINUX_VER}" != "26" ]; then
			cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
					"reuse_port": $(get_function_switch ${ss_basic_mcore}),
					"fast_open": $(get_function_switch ${ss_basic_trojan_tfo}),
			EOF
		else
			cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
					"reuse_port": false,
					"fast_open": false,
			EOF
		fi
		cat >> "${TROJAN_CONFIG_TEMP}" <<-EOF
				"fast_open_qlen": 20
				}
			}
		EOF
		
		echo_date "解析trojan的nat配置文件..."
		jq --tab . ${TROJAN_CONFIG_TEMP} >/tmp/trojan_para_tmp.txt 2>&1
		if [ "$?" != "0" ];then
			echo_date "json配置解析错误，错误信息如下："
			echo_date $(cat /tmp/trojan_para_tmp.txt) 
			echo_date "请更正你的错误然后重试！！"
			rm -rf /tmp/trojan_para_tmp.txt
			close_in_five
		fi
		jq --tab . ${TROJAN_CONFIG_TEMP} >${TROJAN_CONFIG_FILE}
		echo_date "解析成功！trojan的nat配置文件成功写入到${TROJAN_CONFIG_FILE}"

		echo_date 测试trojan的nat配置文件....
		result=$(/koolshare/bin/trojan -t ${TROJAN_CONFIG_FILE} 2>&1 | grep "The config file looks good.")
		if [ -n "${result}" ]; then
			echo_date 测试结果：${result}
			echo_date trojan的nat配置文件通过测试!!!
		else
			echo_date trojan的nat配置文件没有通过测试，请检查设置!!!
			rm -rf ${TROJAN_CONFIG_TEMP}
			rm -rf ${TROJAN_CONFIG_FILE}
			close_in_five
		fi
		
		if [ "${trojan_socks}" == "1" ]; then
			# 3:  dns2socks
			# 4:  ss-tunnel    →   fall back to dns2socks
			# 5:  chinadns1    →   use dns2socks as upstream
			# 7:  v2ray_dns    →   fall back to dns2socks
			# 10: chinadns-ng  →   use dns2socks as upstream
			cat > "${TROJAN_CONFIG_TEMP_SOCKS}" <<-EOF
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
				cat >> "${TROJAN_CONFIG_TEMP_SOCKS}" <<-EOF
					"fast_open": $(get_function_switch ${ss_basic_trojan_tfo}),
				EOF
			else
				cat >> "${TROJAN_CONFIG_TEMP_SOCKS}" <<-EOF
					"fast_open": false,
				EOF
			fi
			cat >> "${TROJAN_CONFIG_TEMP_SOCKS}" <<-EOF
					"fast_open_qlen": 20
					}
				}
			EOF
			echo_date 解析trojan的client配置文件...
			jq --tab . ${TROJAN_CONFIG_TEMP_SOCKS} >/tmp/trojan_para_tmp.txt 2>&1
			if [ "$?" != "0" ];then
				echo_date "json配置解析错误，错误信息如下："
				echo_date $(cat /tmp/trojan_para_tmp.txt) 
				echo_date "请更正你的错误然后重试！！"
				rm -rf /tmp/trojan_para_tmp.txt
				close_in_five
			fi
			jq --tab . ${TROJAN_CONFIG_TEMP_SOCKS} >${TROJAN_CONFIG_FILE_SOCKS}
			echo_date "解析成功！trojan的client配置文件成功写入到${TROJAN_CONFIG_FILE_SOCKS}"

			echo_date 测试trojan的client配置文件....
			result=$(/koolshare/bin/trojan -t ${TROJAN_CONFIG_FILE_SOCKS} 2>&1 | grep "The config file looks good.")
			if [ -n "${result}" ]; then
				echo_date 测试结果：${result}
				echo_date trojan的client配置文件通过测试!!!
			else
				echo_date trojan的client配置文件没有通过测试，请检查设置!!!
				rm -rf ${TROJAN_CONFIG_TEMP_SOCKS}
				rm -rf ${TROJAN_CONFIG_FILE_SOCKS}
				close_in_five
			fi
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
			perpctl -u xray >/dev/null 2>&1
		else
			echo_date "开启Xray主进程，用以运行trojan协议节点..."
			cd /koolshare/bin
			xray run -c $XRAY_CONFIG_FILE >/dev/null 2>&1 &
		fi
		local XPID
		local i=25
		until [ -n "$XPID" ]; do
			i=$(($i - 1))
			XPID=$(pidof xray)
			if [ "$i" -lt 1 ]; then
				echo_date "Xray进程启动失败！"
				close_in_five
			fi
			usleep 250000
		done
		echo_date Xray启动成功，pid：$XPID
	else
		# start trojan
		if [ "${ss_basic_mcore}" == "1" ]; then
			echo_date trojan开启$THREAD线程支持.
			local i=1
			while [ $i -le $THREAD ]; do
				trojan >/dev/null 2>&1 &
				let i++
			done
		else
			trojan >/dev/null 2>&1 &
		fi

		if [ "${trojan_socks}" == "1" ];then
			trojan -c ${TROJAN_CONFIG_FILE_SOCKS} >/dev/null 2>&1 &
		fi
	fi
}

write_cron_job() {
	sed -i '/ssupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "1" == "$ss_basic_rule_update" ]; then
		echo_date 添加fancyss规则定时更新任务，每天"$ss_basic_rule_update_time"自动检测更新规则.
		cru a ssupdate "0 $ss_basic_rule_update_time * * * /bin/sh /koolshare/scripts/ss_rule_update.sh"
	else
		echo_date fancyss规则定时更新任务未启用！
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
	#iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS >/dev/null 2>&1

	iptables -t nat -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_EXT >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GFW >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GFW >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_CHN >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_CHN >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GAM >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GAM >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_GLO >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_GLO >/dev/null 2>&1
	iptables -t nat -F SHADOWSOCKS_HOM >/dev/null 2>&1 && iptables -t nat -X SHADOWSOCKS_HOM >/dev/null 2>&1

	mangle_indexs=$(iptables -nvL PREROUTING -t mangle | sed 1,2d | sed -n '/SHADOWSOCKS/=' | sort -r)
	for mangle_index in $mangle_indexs; do
		iptables -t mangle -D PREROUTING $mangle_index >/dev/null 2>&1
	done
	#iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS >/dev/null 2>&1

	iptables -t mangle -F SHADOWSOCKS >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS >/dev/null 2>&1
	iptables -t mangle -F SHADOWSOCKS_GAM >/dev/null 2>&1 && iptables -t mangle -X SHADOWSOCKS_GAM >/dev/null 2>&1
	iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333 >/dev/null 2>&1
	iptables -t nat -F OUTPUT >/dev/null 2>&1
	iptables -t nat -X SHADOWSOCKS_EXT >/dev/null 2>&1
	#iptables -t nat -D PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
	chromecast_nu=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep "dpt:53" | awk '{print $1}')
	[ -n "$chromecast_nu" ] && iptables -t nat -D PREROUTING $chromecast_nu >/dev/null 2>&1
	iptables -t mangle -D QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN >/dev/null 2>&1
	# flush ipset
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
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
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" /koolshare/ss/rules/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}

add_white_black_ip() {
	# black ip/cidr
	if [ "$ss_basic_mode" != "6" ]; then
		ip_tg="149.154.0.0/16 91.108.4.0/22 91.108.56.0/24 109.239.140.0/24 67.198.55.0/24"
		for ip in $ip_tg; do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi

	if [ -n "$ss_wan_black_ip" ]; then
		ss_wan_black_ip=$(echo $ss_wan_black_ip | base64_decode | sed '/\#/d')
		echo_date 应用IP/CIDR黑名单
		for ip in $ss_wan_black_ip; do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi

	# white ip/cidr
	[ -n "$ss_basic_server_ip" ] && SERVER_IP="$ss_basic_server_ip" || SERVER_IP=""
	[ -n "$IFIP_DNS1" ] && ISP_DNS_a="$ISP_DNS1" || ISP_DNS_a=""
	[ -n "$IFIP_DNS2" ] && ISP_DNS_b="$ISP_DNS2" || ISP_DNS_a=""
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 117.50.11.11 117.50.22.22 180.76.76.76 119.29.29.29 $ISP_DNS_a $ISP_DNS_b $SERVER_IP $(get_wan0_cidr)"
	for ip in $ip_lan; do
		ipset -! add white_list $ip >/dev/null 2>&1
	done

	if [ -n "$ss_wan_white_ip" ]; then
		ss_wan_white_ip=$(echo $ss_wan_white_ip | base64_decode | sed '/\#/d')
		echo_date 应用IP/CIDR白名单
		for ip in $ss_wan_white_ip; do
			ipset -! add white_list $ip >/dev/null 2>&1
		done
	fi
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
			if [ "$proxy_mode" == "3" ]; then
				iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp $(factor $ports "-m multiport --dport") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
			else
				[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS $(factor $ipaddr "-s") -p udp -j RETURN
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

apply_nat_rules() {
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到nat表中...
	# 创建SHADOWSOCKS nat rule
	iptables -t nat -N SHADOWSOCKS
	# 扩展
	iptables -t nat -N SHADOWSOCKS_EXT
	# IP/cidr/白域名 白名单控制（不走ss）
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set white_list dst -j RETURN
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp -m set --match-set white_list dst -j RETURN
	#-----------------------FOR GLOABLE---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GLO
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GLO -p tcp -j REDIRECT --to-ports 3333
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式nat rule
	iptables -t nat -N SHADOWSOCKS_GFW
	# IP/CIDR/黑域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# IP黑名单控制-gfwlist（走ss）
	iptables -t nat -A SHADOWSOCKS_GFW -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports 3333
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式nat rule
	iptables -t nat -N SHADOWSOCKS_CHN
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_CHN -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式nat rule
	iptables -t nat -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_GAM -p tcp -m set ! --match-set chnroute dst -j REDIRECT --to-ports 3333
	#-----------------------FOR HOMEMODE---------------------
	# 创建回国模式nat rule
	iptables -t nat -N SHADOWSOCKS_HOM
	# IP/CIDR/域名 黑名单控制（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set black_list dst -j REDIRECT --to-ports 3333
	# cidr黑名单控制-chnroute（走ss）
	iptables -t nat -A SHADOWSOCKS_HOM -p tcp -m set --match-set chnroute dst -j REDIRECT --to-ports 3333

	[ "$mangle" == "1" ] && load_tproxy
	[ "$mangle" == "1" ] && ip rule add fwmark 0x07 table 310
	[ "$mangle" == "1" ] && ip route add local 0.0.0.0/0 dev lo table 310
	# 创建游戏模式udp rule
	[ "$mangle" == "1" ] && iptables -t mangle -N SHADOWSOCKS
	# IP/cidr/白域名 白名单控制（不走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS -p udp -m set --match-set white_list dst -j RETURN
	# 创建游戏模式udp rule
	[ "$mangle" == "1" ] && iptables -t mangle -N SHADOWSOCKS_GAM
	# IP/CIDR/域名 黑名单控制（走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（走ss）
	[ "$mangle" == "1" ] && iptables -t mangle -A SHADOWSOCKS_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 3333 --tproxy-mark 0x07
	#-------------------------------------------------------
	# 局域网黑名单（不走ss）/局域网黑名单（走ss）
	lan_acess_control
	#-----------------------FOR ROUTER---------------------
	# router itself
	[ "$ss_basic_mode" != "6" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 3333
	iptables -t nat -A OUTPUT -p tcp -m mark --mark "$ip_prefix_hex" -j SHADOWSOCKS_EXT

	# 把最后剩余流量重定向到相应模式的nat表中对应的主模式的链
	iptables -t nat -A SHADOWSOCKS -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)
	iptables -t nat -A SHADOWSOCKS_EXT -p tcp $(factor $ss_acl_default_port "-m multiport --dport") -j $(get_action_chain $ss_acl_default_mode)

	# 如果是主模式游戏模式，则把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM链
	# 如果主模式不是游戏模式，则不需要把SHADOWSOCKS链中剩余udp流量转发给SHADOWSOCKS_GAM，不然会造成其他模式主机的udp也走游戏模式
	###[ "$mangle" == "1" ] && ss_acl_default_mode=3
	[ "$ss_acl_default_mode" != "0" -a "$ss_acl_default_mode" != "3" ] && ss_acl_default_mode=0
	[ "$ss_basic_mode" == "3" ] && iptables -t mangle -A SHADOWSOCKS -p udp -j $(get_action_chain $ss_acl_default_mode)
	# 重定所有流量到 SHADOWSOCKS
	KP_NU=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/KOOLPROXY/=' | head -n1)
	[ "$KP_NU" == "" ] && KP_NU=0
	INSET_NU=$(expr "$KP_NU" + 1)
	iptables -t nat -I PREROUTING "$INSET_NU" -p tcp -j SHADOWSOCKS
	[ "$mangle" == "1" ] && iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS
	# QOS开启的情况下
	QOSO=$(iptables -t mangle -S | grep -o QOSO | wc -l)
	RRULE=$(iptables -t mangle -S | grep "A QOSO" | head -n1 | grep RETURN)
	if [ "$QOSO" -gt "1" -a -z "$RRULE" ]; then
		iptables -t mangle -I QOSO0 -m mark --mark "$ip_prefix_hex" -j RETURN
	fi
}

chromecast() {
	chromecast_nu=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep "dpt:53" | awk '{print $1}')
	if [ "$ss_basic_dns_hijack" == "1" ]; then
		if [ -z "$chromecast_nu" ]; then
			iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1
			echo_date 开启DNS劫持功能功能，防止DNS污染...
		else
			echo_date DNS劫持规则已经添加，跳过~
		fi
	else
		echo_date DNS劫持功能未开启，建议开启！
	fi
}
# -----------------------------------nat part end--------------------------------------------------------

restart_dnsmasq() {
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
	echo_date 重启dnsmasq服务...
	service restart_dnsmasq >/dev/null 2>&1
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
	nvram set update_ipset="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.gfwlist.date')"
	nvram set update_chnroute="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.chnroute.date')"
	nvram set update_cdn="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.cdn_china.date')"
	
	nvram set ipset_numbers="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.gfwlist.count')"
	nvram set chnroute_numbers="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.chnroute.count')"
	nvram set chnroute_ips="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.chnroute.count_ip')"
	nvram set cdn_numbers="$(cat /koolshare/ss/rules/rules.json.js | /koolshare/bin/jq -r '.cdn_china.count')"
}

set_sys() {
	# set_ulimit
	ulimit -n 16384

	# mem
	echo 1 >/proc/sys/vm/overcommit_memory

	# more entropy
	# use command `cat /proc/sys/kernel/random/entropy_avail` to check current entropy
	# few scenario should be noticed below:
	# 1. from merlin fw 386.2, jitterentropy-rngd has been intergrated into fw, so havege form fancyss should not be used
	# 2. from merlin fw 386.4, jitterentropy-rngd was replaced by haveged, so havege form fancyss should not be used
	# 3. newer asus fw or asus_ks_mod fw like GT-AX6000 use jitterentropy-rngd, so havege form fancyss should not be used
	# 4. older merlin or asus_ks_mod fw do not have jitterentropy-rngd or haveged, so havege form fancyss should be used
	if [ -z "$(pidof jitterentropy-rngd)" -a -z "$(pidof haveged)" -a -f "/koolshare/bin/haveged" ];then
		# run haveged form fancyss only there are not entropy software running
		echo_date "启动haveged，为系统提供更多的可用熵！"
		/koolshare/bin/haveged -w 1024 >/dev/null 2>&1
	fi
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
	nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	i=120
	until [ -n "$nat_ready" ]; do
		i=$(($i - 1))
		if [ "$i" -lt 1 ]; then
			echo_date "错误：不能正确加载nat规则!"
			close_in_five
		fi
		sleep 1
		nat_ready=$(iptables -t nat -L PREROUTING -v -n --line-numbers | grep -v PREROUTING | grep -v destination)
	done
	echo_date "加载nat规则!"
	#creat_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
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

detect() {
	# 检测是否是路由模式
	local ROUTER_MODE=$(nvram get sw_mode)
	if [ "$(nvram get sw_mode)" != "1" ]; then
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo_date "+          无法启用插件，因为当前路由器工作在非无线路由器模式下          +"
		echo_date "+     科学上网插件工作方式为透明代理，需要在NAT下，即路由模式下才能工作    +"
		echo_date "+            请前往【系统管理】- 【系统设置】去切换路由模式！           +"
		echo_date "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		close_in_five
	fi
	
	# 检测jffs2脚本是否开启，如果没有开启，不然将会影响插件的自启和DNS部分（dnsmasq.postconf）
	# 判断为非官改固件的，即merlin固件，需要开启jffs2_scripts，官改固件不需要开启
	local MODEL=$(nvram get productid)
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

	# 检测是否在lan设置中是否自定义过dns,如果有给干掉
	if [ -n "$(nvram get dhcp_dns1_x)" ]; then
		nvram unset dhcp_dns1_x
		nvram commit
	fi
	if [ -n "$(nvram get dhcp_dns2_x)" ]; then
		nvram unset dhcp_dns2_x
		nvram commit
	fi

	# info
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
	kill -9 $(pidof ss_status_main.sh) >/dev/null 2>&1
	kill -9 $(pidof ss_status.sh) >/dev/null 2>&1
	killall curl >/dev/null 2>&1
	killall httping >/dev/null 2>&1
	rm -rf /tmp/upload/ss_status.txt
}

check_status() {
	if [ "$ss_failover_enable" == "1" ]; then
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssf_status.txt
		echo "=========================================== start/restart ==========================================" >>/tmp/upload/ssc_status.txt
		start-stop-daemon -S -q -b -x /koolshare/scripts/ss_status_main.sh
	fi
}

disable_ss() {
	ss_pre_stop
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date ------------------------- 关闭【科学上网】 -----------------------------
	pre_set
	dbus remove ss_basic_server_ip
	stop_status
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	restart_dnsmasq
	flush_nat
	kill_cron_job
	echo_date ------------------------ 【科学上网】已关闭 ----------------------------
}

apply_ss() {
	ss_pre_stop
	# now stop first
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	echo_date
	echo_date ------------------------- 启动【科学上网】 -----------------------------
	pre_set
	stop_status
	kill_process
	remove_ss_trigger_job
	remove_ss_reboot_job
	restore_conf
	# restart dnsmasq when ss server is not ip or on router boot
	restart_dnsmasq
	flush_nat
	kill_cron_job
	#echo_date ------------------------ 【科学上网】已关闭 ----------------------------
	# pre-start
	ss_pre_start
	# start
	#echo_date ------------------------- 启动 【科学上网】 ----------------------------
	detect
	set_sys
	resolv_server_ip
	ss_arg
	load_module
	creat_ipset
	create_dnsmasq_conf
	# do not re generate json on router start, use old one
	[ "$ss_basic_type" == "0" -o "$ss_basic_type" == "1" -o "$ss_basic_type" == "2" ] && creat_ss_json
	[ "$ss_basic_type" == "3" ] && creat_v2ray_json
	[ "$ss_basic_type" == "4" ] && creat_xray_json
	[ "$ss_basic_type" == "5" ] && creat_trojan_json
	[ "$ss_basic_type" == "0" -o "$ss_basic_type" == "1" ] && start_ss_redir
	[ "$ss_basic_type" == "2" ] && start_koolgame
	[ "$ss_basic_type" == "3" ] && start_v2ray
	[ "$ss_basic_type" == "4" ] && start_xray
	[ "$ss_basic_type" == "5" ] && start_trojan
	[ "$ss_basic_type" != "2" ] && start_kcp
	[ "$ss_basic_type" != "2" ] && start_dns
	#===load nat start===
	load_nat
	#===load nat end===
	restart_dnsmasq
	auto_start
	write_cron_job
	set_ss_reboot_job
	set_ss_trigger_job
	write_numbers
	# post-start
	ss_post_start
	#httping_check
	#[ "$?" == "1" ] && return 1
	check_status
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

# =========================================================================

case $ACTION in
start)
	set_lock
	if [ "$ss_basic_enable" == "1" ]; then
		logger "[软件中心]: 启动科学上网插件！"
		apply_ss >>"$LOG_FILE"
		#get_status >> /tmp/upload/test.txt
	else
		logger "[软件中心]: 科学上网插件未开启，不启动！"
	fi
	unset_lock
	;;
stop)
	set_lock
	disable_ss
	echo_date
	echo_date 你已经成功关闭科学上网服务~
	echo_date See you again!
	echo_date
	echo_date ======================= 梅林固件 - 【科学上网】 ========================
	unset_lock
	;;
restart)
	set_lock
	donwload_binary
	apply_ss
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
