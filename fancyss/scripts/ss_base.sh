#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

# 此脚本用以获取fancyss插件的所有数据 + 节点数据
# 同时可以存放一些公用的函数
# 其他脚本如果需要获取节点数据的，只需要引用本脚本即可！无需单独去拿插件数据
# 引用方法：source /koolshare/scripts/ss_base.sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
source $KSROOT/scripts/ss_node_common.sh
FSS_SHUNT_LIB_LOADED=0
fss_require_shunt_lib() {
	[ "${FSS_SHUNT_LIB_LOADED}" = "1" ] && return 0
	[ -f "$KSROOT/scripts/ss_node_shunt.sh" ] || return 1
	. "$KSROOT/scripts/ss_node_shunt.sh"
	FSS_SHUNT_LIB_LOADED=1
}
[ "${FSS_BASE_SKIP_SHUNT_SOURCE:-0}" = "1" ] || fss_require_shunt_lib >/dev/null 2>&1 || true
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
source helper.sh
fss_cleanup_acl_default_port_keys >/dev/null 2>&1
eval $(dbus export ss | sed 's/export //' | sed 's/;export /\n/g;' | sed '/ssconf_.*$/d'|sed 's/^/export /' | tr '\n' ';')
export FSS_GLOBAL_BASIC_MODE="${ss_basic_mode}"
AIRPORT_DNS_ACTIVE="0"
AIRPORT_DNS_CURRENT_MATCHED="0"
AIRPORT_DNS_AIRPORT_IDENTITY=""
AIRPORT_DNS_AIRPORT_LABEL=""
AIRPORT_DNS_PREFERRED_PLAN=""
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

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y%m%d\ %X)】:'

get_runtime_proxy_mode() {
	local mode="${ss_basic_mode}"

	if [ "${ss_basic_mode}" = "7" ] && ! type fss_shunt_effective_mode >/dev/null 2>&1; then
		fss_require_shunt_lib >/dev/null 2>&1 || true
	fi
	if type fss_shunt_effective_mode >/dev/null 2>&1; then
		mode="$(fss_shunt_effective_mode 2>/dev/null)"
		[ -n "${mode}" ] || mode="${ss_basic_mode}"
	fi
	echo "${mode}"
}

get_fancyss_default_furl() {
	echo "http://www.google.com/generate_204"
}

get_fancyss_default_curl() {
	echo "http://connectivitycheck.platform.hicloud.com/generate_204"
}

get_pkg_meta_from_file() {
	local file_path="$1"
	local field="$2"
	[ -f "${file_path}" ] || return 1
	tr -d '\r' < "${file_path}" | grep -Eo "PKG_${field}=.+" | awk -F "=" '{print $2}' | sed 's/"//g' | sed -n '1p'
}

get_pkg_meta() {
	local field="$1"
	local dbus_key="ss_basic_pkg_$(echo "${field}" | tr 'A-Z' 'a-z')"
	local value=""
	value="$(dbus get "${dbus_key}")"
	if [ -z "${value}" ];then
		value="$(get_pkg_meta_from_file /koolshare/webs/Module_shadowsocks.asp "${field}")"
	fi
	echo "${value}"
}

get_pkg_name() {
	get_pkg_meta "NAME"
}

get_pkg_arch() {
	get_pkg_meta "ARCH"
}

get_pkg_type() {
	get_pkg_meta "TYPE"
}

get_pkg_exta() {
	get_pkg_meta "EXTA"
}

get_pkg_full_name() {
	echo "$(get_pkg_name)_$(get_pkg_arch)_$(get_pkg_type)$(get_pkg_exta)"
}

FSS_BASE_DNS_LIB_LOADED=0
fss_require_base_dns() {
	[ "${FSS_BASE_DNS_LIB_LOADED}" = "1" ] && return 0
	[ -f "$KSROOT/scripts/ss_base_dns.sh" ] || return 1
	. "$KSROOT/scripts/ss_base_dns.sh"
	FSS_BASE_DNS_LIB_LOADED=1
}

fss_base_load_current_node_env() {
	[ "${FSS_CURRENT_NODE_ENV_LOADED:-0}" = "1" ] && return 0
	local cur_node=""
	local base_1=""
	local base_2=""
	if [ "${ss_basic_mode}" = "7" ]; then
		fss_require_shunt_lib >/dev/null 2>&1 || true
	fi
	if [ "${ss_basic_mode}" = "7" ] && type fss_shunt_resolve_default_node_id >/dev/null 2>&1; then
		fss_shunt_resolve_default_node_id >/dev/null 2>&1 || true
		cur_node="${FSS_SHUNT_DEFAULT_NODE_ID_PICK}"
	elif [ "${ss_basic_mode}" = "7" ] && type fss_shunt_get_default_node_id >/dev/null 2>&1; then
		cur_node=$(fss_shunt_get_default_node_id)
	elif type fss_resolve_current_node_id >/dev/null 2>&1; then
		fss_resolve_current_node_id >/dev/null 2>&1 || true
		cur_node="${FSS_CURRENT_NODE_ID_RESULT}"
	else
		cur_node=$(fss_get_current_node_id)
	fi
	base_1="name type mode server port method password ss_obfs ss_obfs_host rss_protocol rss_protocol_param rss_obfs rss_obfs_param v2ray_uuid v2ray_alterid v2ray_security v2ray_network v2ray_headtype_tcp v2ray_headtype_kcp v2ray_headtype_quic v2ray_grpc_mode v2ray_grpc_authority v2ray_network_path v2ray_network_host v2ray_kcp_seed v2ray_network_security v2ray_network_security_ai v2ray_network_security_sni v2ray_mux_concurrency v2ray_json xray_uuid xray_encryption xray_flow xray_network xray_headtype_tcp xray_headtype_kcp xray_headtype_quic xray_grpc_mode xray_grpc_authority xray_xhttp_mode xray_network_path xray_network_host xray_kcp_seed xray_network_security xray_network_security_ai xray_network_security_sni xray_pcs xray_vcn xray_svn xray_fingerprint xray_show xray_publickey xray_shortid xray_spiderx xray_prot xray_alterid xray_json tuic_json"
	base_2="v2ray_use_json v2ray_mux_enable v2ray_network_security_alpn_h2 v2ray_network_security_alpn_http xray_use_json xray_network_security_alpn_h2 xray_network_security_alpn_http trojan_ai trojan_uuid trojan_sni trojan_pcs trojan_vcn trojan_tfo trojan_plugin trojan_obfs trojan_obfshost trojan_obfsuri naive_prot naive_server naive_port naive_user naive_pass hy2_server hy2_port hy2_pass hy2_up hy2_dl hy2_obfs hy2_obfs_pass hy2_sni hy2_pcs hy2_vcn hy2_svn hy2_ai hy2_tfo hy2_cg"
	fss_export_current_node_env "${cur_node}" ${base_1} ${base_2}
	ssconf_basic_node=${cur_node}
	export ss_basic_mode="${FSS_GLOBAL_BASIC_MODE}"
	if [ "$(fss_detect_storage_schema)" = "2" ];then
		ss_failover_s4_3=$(fss_get_failover_node_id)
		export ss_failover_s4_3
	fi
	FSS_CURRENT_NODE_ENV_LOADED=1
}

[ "${FSS_BASE_EAGER_NODE_ENV:-1}" = "1" ] && fss_base_load_current_node_env
# ------------------------------------------------
mangle=0

resolve_acl_udp_flag() {
	local udp_flag="$1"
	local proxy_mode="$2"
	if [ "${proxy_mode}" == "3" ];then
		echo "1"
		return
	fi
	if [ -z "${udp_flag}" ];then
		if [ "${ss_basic_udpall}" == "1" ];then
			udp_flag="1"
		else
			udp_flag="0"
		fi
	fi
	echo "${udp_flag}"
}

normalize_acl_default_mode_raw() {
	case "$1" in
	follow | "")
		echo "follow"
		;;
	0)
		echo "0"
		;;
	2)
		# default ACL rule only supports follow-current-mode or no-proxy
		echo "follow"
		;;
	1 | 3 | 5 | 6)
		# legacy default-rule proxy modes are normalized to follow-current-mode
		echo "follow"
		;;
	*)
		echo "follow"
		;;
	esac
}

resolve_acl_default_mode() {
	local has_custom_rules="$1"
	local raw_mode
	local current_mode

	current_mode="$(get_runtime_proxy_mode)"
	raw_mode=$(normalize_acl_default_mode_raw "${ss_acl_default_mode}")
	if [ "${has_custom_rules}" = "1" ];then
		if [ "${raw_mode}" = "follow" ];then
			echo "${current_mode}"
		else
			echo "${raw_mode}"
		fi
	else
		echo "${current_mode}"
	fi
}

is_legacy_acl_default_follow_profile() {
	[ "$(normalize_acl_default_mode_raw "${ss_acl_default_mode}")" = "follow" ] || return 1
	[ "${ss_acl_default_mode_format}" != "2" ]
}

resolve_acl_default_udp_raw() {
	if is_legacy_acl_default_follow_profile;then
		echo "0"
	else
		echo "${ss_acl_default_udp}"
	fi
}

resolve_acl_default_ports_raw() {
	if is_legacy_acl_default_follow_profile;then
		echo "22,80,443,8080,8443"
	else
		echo "${ss_acl_default_ports}"
	fi
}

resolve_acl_ports() {
	local raw_ports="$1"
	local proxy_mode="$2"
	if [ -z "${raw_ports}" ];then
		case "${proxy_mode}" in
		0 | 3)
			raw_ports="all"
			;;
		1)
			raw_ports="80,443"
			;;
		*)
			raw_ports="22,80,443,8080,8443"
			;;
		esac
	fi
	if [ "${proxy_mode}" = "0" ] || [ "${proxy_mode}" = "3" ];then
		echo "all"
	else
		echo "${raw_ports}"
	fi
}

cleanup_acl_rule() {
	local acl="$1"
	local field=""
	for field in ip mac name mode port udp quic
	do
		dbus remove ss_acl_${field}_${acl}
		unset ss_acl_${field}_${acl}
	done
}

get_acl_host_ip() {
	local acl_ip="$1"
	case "${acl_ip}" in
	*/*)
		echo "${acl_ip%/*}"
		;;
	*)
		echo "${acl_ip}"
		;;
	esac
}

acl_is_cidr_rule() {
	case "$1" in
	*/*)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

is_valid_acl_mac() {
	echo "$1" | grep -Eiq '^([0-9a-f]{2}:){5}[0-9a-f]{2}$'
}

normalize_acl_mac() {
	local acl_mac=$(echo "$1" | tr 'A-F' 'a-f')
	if is_valid_acl_mac "${acl_mac}"; then
		echo "${acl_mac}"
	fi
}

get_arp_mac_by_ip() {
	local host_ip="$(get_acl_host_ip "$1")"
	local acl_mac=""
	acl_mac=$(arp -n 2>/dev/null | awk -v target="(${host_ip})" '$2 == target {print $4; exit}')
	if [ -z "${acl_mac}" ]; then
		acl_mac=$(ip neigh show 2>/dev/null | awk -v target="${host_ip}" '$1 == target {for (i = 1; i <= NF; i++) if ($i == "lladdr") {print $(i + 1); exit}}')
	fi
	normalize_acl_mac "${acl_mac}"
}

resolve_acl_mac() {
	local acl="$1"
	local acl_ip=""
	local acl_mac=""
	eval acl_ip=\$ss_acl_ip_${acl}
	eval acl_mac=\$ss_acl_mac_${acl}

	acl_mac=$(normalize_acl_mac "${acl_mac}")
	if acl_is_cidr_rule "${acl_ip}"; then
		[ -n "${acl_mac}" ] && dbus remove ss_acl_mac_${acl}
		return 1
	fi

	if [ -z "${acl_mac}" ]; then
		acl_mac=$(get_arp_mac_by_ip "${acl_ip}")
	fi

	if [ -n "${acl_mac}" ]; then
		dbus set ss_acl_mac_${acl}=${acl_mac}
		eval ss_acl_mac_${acl}="${acl_mac}"
		echo "${acl_mac}"
		return 0
	fi

	dbus remove ss_acl_mac_${acl}
	return 1
}

is_valid_acl_source() {
	local acl_ip="$1"
	local host_ip="${acl_ip}"
	local prefix="32"
	local octet=""

	case "${acl_ip}" in
	*/*)
		host_ip="${acl_ip%/*}"
		prefix="${acl_ip##*/}"
		case "${prefix}" in
		''|*[!0-9]*)
			return 1
			;;
		esac
		[ "${prefix}" -ge 0 ] && [ "${prefix}" -le 32 ] || return 1
		;;
	esac

	echo "${host_ip}" | grep -Eq "^([0-9]{1,3}[.]){3}[0-9]{1,3}$" || return 1
	for octet in $(echo "${host_ip}" | tr '.' ' ')
	do
		[ "${octet}" -ge 0 ] && [ "${octet}" -le 255 ] || return 1
	done
	return 0
}

get_acl_ip_mark() {
	local acl_ip="$1"
	local host_ip="${acl_ip}"
	local prefix="32"
	local o1 o2 o3 o4
	local m1 m2 m3 m4
	local n1 n2 n3 n4
	local rem

	case "${acl_ip}" in
	*/*)
		host_ip="${acl_ip%/*}"
		prefix="${acl_ip##*/}"
		;;
	esac

	IFS='.' read -r o1 o2 o3 o4 <<EOF
${host_ip}
EOF

	rem=${prefix}
	for idx in 1 2 3 4
	do
		local mask_val=0
		if [ "${rem}" -ge 8 ];then
			mask_val=255
			rem=$((rem - 8))
		elif [ "${rem}" -gt 0 ];then
			mask_val=$((256 - (1 << (8 - rem))))
			rem=0
		fi
		eval m${idx}=${mask_val}
	done

	n1=$((o1 & m1))
	n2=$((o2 & m2))
	n3=$((o3 & m3))
	n4=$((o4 & m4))
	printf "0x%02x%02x%02x%02x/0x%02x%02x%02x%02x\n" "${n1}" "${n2}" "${n3}" "${n4}" "${m1}" "${m2}" "${m3}" "${m4}"
}

is_acl_rule_complete() {
	local acl="$1"
	local acl_ip=""
	local acl_mode=""
	local acl_port=""
	eval acl_ip=\$ss_acl_ip_${acl}
	eval acl_mode=\$ss_acl_mode_${acl}
	eval acl_port=\$ss_acl_port_${acl}

	if [ -z "${acl_ip}" -o -z "${acl_mode}" -o -z "${acl_port}" ];then
		return 1
	fi

	is_valid_acl_source "${acl_ip}" || return 1
	return 0
}

get_acl_rule_indexes() {
	local all_acl_nu=$(dbus list ss_acl_mode_ | cut -d "=" -f 1 | cut -d "_" -f 4 | sort -n)
	local valid_acl_nu=""
	local acl=""
	for acl in ${all_acl_nu}
	do
		if is_acl_rule_complete "${acl}";then
			resolve_acl_mac "${acl}" >/dev/null 2>&1
			valid_acl_nu="${valid_acl_nu} ${acl}"
		else
			cleanup_acl_rule "${acl}"
		fi
	done
	echo ${valid_acl_nu}
}

acl_nu=$(get_acl_rule_indexes)
if [ -n "${acl_nu}" ];then
	default_mode=$(resolve_acl_default_mode 1)
else
	default_mode=$(resolve_acl_default_mode 0)
fi
default_udp_flag=$(resolve_acl_udp_flag "$(resolve_acl_default_udp_raw)" "${default_mode}")
if [ "${default_mode}" != "0" -a "${default_udp_flag}" == "1" ];then
	mangle=1
fi

for acl in ${acl_nu}
do
	eval acl_mode=\$ss_acl_mode_${acl}
	eval acl_udp=\$ss_acl_udp_${acl}
	acl_udp=$(resolve_acl_udp_flag "${acl_udp}" "${acl_mode}")
	if [ "${acl_mode}" != "0" -a "${acl_udp}" == "1" ];then
		mangle=1
		break
	fi
done

# naive 节点不支持udp
if [ "${ss_basic_type}" == "6" ];then
	mangle=0
fi

if [ "${ss_basic_type}" == "6" ];then
	if [ "$(fss_detect_storage_schema 2>/dev/null)" = "2" ]; then
		ss_basic_password="${ss_basic_naive_pass}"
	else
		ss_basic_password=$(echo ${ss_basic_naive_pass} | base64_decode)
	fi
	ss_basic_server=${ss_basic_naive_server}
elif [ "${ss_basic_type}" == "8" ];then
	ss_basic_server=${ss_basic_hy2_server}
else
	if [ "$(fss_detect_storage_schema 2>/dev/null)" = "2" ]; then
		:
	else
		ss_basic_password=$(echo ${ss_basic_password} | base64_decode)
	fi
fi

ss_basic_server_orig=${ss_basic_server}

[ -z "$(dbus get ss_basic_furl)" ] && ss_basic_furl="$(get_fancyss_default_furl)"
[ -z "$(dbus get ss_basic_curl)" ] && ss_basic_curl="$(get_fancyss_default_curl)"

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

cmd() {
	echo_date "$@"
	env -i PATH=${PATH} "$@" >/dev/null 2>&1 &
}

run(){
	env -i PATH=${PATH} "$@"
}

run_loud(){
	echo_date "$@"
	"$@"
}

run_bg(){
	env -i PATH=${PATH} "$@" >/dev/null 2>&1 &
}

__timeout_init() {
	# Determine best available timeout implementation:
	# 1) system timeout (GNU/coreutils or BusyBox applet)
	# 2) busybox timeout applet (no symlink)
	# 3) shell fallback (sleep + kill + wait)
	__TIMEOUT_CMD=""
	__TIMEOUT_STYLE=""

	if command -v timeout >/dev/null 2>&1; then
		__TIMEOUT_CMD="timeout"
	elif command -v busybox >/dev/null 2>&1; then
		# Some firmwares ship timeout applet without /bin/timeout symlink
		if busybox timeout --help >/dev/null 2>&1; then
			__TIMEOUT_CMD="busybox timeout"
		fi
	fi

	if [ -n "${__TIMEOUT_CMD}" ]; then
		# Prefer GNU/coreutils style: timeout DURATION CMD...
		# BusyBox uses: timeout -t SECONDS [CMD...]
		if env -i PATH=${PATH} ${__TIMEOUT_CMD} --help 2>&1 | grep -q -- "-t SECS"; then
			# Some BusyBox timeout returns 0 even on timeout; avoid it to keep 124 semantics.
			env -i PATH=${PATH} ${__TIMEOUT_CMD} -t 1 sh -c "sleep 2" >/dev/null 2>&1
			if [ "$?" = "124" ]; then
				__TIMEOUT_STYLE="bb"
			else
				__TIMEOUT_CMD=""
				__TIMEOUT_STYLE=""
			fi
		elif env -i PATH=${PATH} ${__TIMEOUT_CMD} 1 sh -c ":" >/dev/null 2>&1; then
			__TIMEOUT_STYLE="gnu"
		else
			__TIMEOUT_CMD=""
			__TIMEOUT_STYLE=""
		fi
	fi
}

__timeout_run() {
	# Usage: __timeout_run <seconds> <cmd...>
	# Returns 124 on timeout (GNU timeout convention).
	local _t="$1"
	shift

	[ -z "${1}" ] && return 127

	if [ -z "${__TIMEOUT_STYLE}" -a -z "${__TIMEOUT_CMD}" ]; then
		__timeout_init
	fi

	if [ -n "${__TIMEOUT_CMD}" -a "${__TIMEOUT_STYLE}" = "gnu" ]; then
		env -i PATH=${PATH} ${__TIMEOUT_CMD} "${_t}" "$@"
		return $?
	elif [ -n "${__TIMEOUT_CMD}" -a "${__TIMEOUT_STYLE}" = "bb" ]; then
		env -i PATH=${PATH} ${__TIMEOUT_CMD} -t "${_t}" "$@"
		return $?
	fi

	# Shell fallback: run command in background, kill it if still running after _t seconds.
	# Avoid setsid on BusyBox as it can detach and make wait() return immediately.
	local _cmd_pid _timer_pid _rc _timer_rc _kill_target _flag
	env -i PATH=${PATH} "$@" &
	_cmd_pid=$!
	_kill_target="${_cmd_pid}"
	_flag="/tmp/.timeout_${$}_${_cmd_pid}"

	(
		sleep "${_t}"
		if kill -0 "${_cmd_pid}" >/dev/null 2>&1; then
			echo 1 > "${_flag}"
			kill -TERM ${_kill_target} >/dev/null 2>&1
			sleep 1
			kill -KILL ${_kill_target} >/dev/null 2>&1
			exit 124
		fi
		exit 0
	) &
	_timer_pid=$!

	wait "${_cmd_pid}"
	_rc=$?

	# If timeout fired, honor it.
	if [ -f "${_flag}" ]; then
		rm -f "${_flag}"
		wait "${_timer_pid}" >/dev/null 2>&1
		return 124
	fi

	# Stop timer early if command finished before timeout.
	if kill -0 "${_timer_pid}" >/dev/null 2>&1; then
		kill "${_timer_pid}" >/dev/null 2>&1
	fi
	wait "${_timer_pid}" >/dev/null 2>&1
	_timer_rc=$?

	[ "${_timer_rc}" = "124" ] && return 124
	return "${_rc}"
}

run5(){
	__timeout_run 5 "$@"
}

run2(){
	__timeout_run 2 "$@"
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

__valid_ip46() {
	# 验证是否为ipv4或者ipv6地址，ipv4返回0，ipv6返回1
	local format_4=$(echo "$1" | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$")
	local format_6=$(echo "$1" | grep -Eo '^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*')
	if [ -n "${format_4}" -a -z "${format_6}" ]; then
		return 0
	elif [ -z "${format_4}" -a -n "${format_6}" ]; then
		return 1
	else
		return 2
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

detect_running_status(){
	# detect process by binary name and PIDFILE content
	local BINNAME=$1
	local PIDFILE=$2
	local FORCE=$3
	[ "${ss_basic_noruncheck}" == "1" -a -z "${FORCE}" ] && return
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
	# detect process by binary name and key word
	local BINNAME=$1
	local KEY=$2
	local SLIENT=$3
	local FORCE=$4
	[ "${ss_basic_noruncheck}" == "1" -a -z "${FORCE}" ] && return
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

detect_running_status3(){
	# detect process by netstat
	local BINNAME=$1
	local PORT=$2
	local VERBOSE=$3
	local FORCE=$4
	[ "${ss_basic_noruncheck}" == "1" -a -z "${FORCE}" ] && return
	local i=50
	local RET
 	until [ -n "${RET}" ]; do
 		# wait for 0.1s
		usleep 100000
		i=$(($i - 1))
		RET=$(netstat -nlp 2>/dev/null|grep -Ew "${PORT}"|grep -Eo "${BINNAME}"|head -n1)
		if [ "$i" -lt 1 ]; then
			echo_date "$1进程启动失败，请检查你的配置！"
			#return 1
			close_in_five flag
		fi
	done
	if [ "${VERBOSE}" == "1" ];then
		local _pid=$(pidof ${BINNAME})
		if [ -n "${_pid}" ];then
			echo_date "$1启动成功，pid：${_pid}"
		else
			echo_date "$1启动成功"
		fi
	fi
}

get_rand_port(){
	get_avail_ports 1 "$@" | sed -n '1p'
}

get_avail_ports(){
	local need="$1"
	local tmp_dir=""
	local used_file="${tmp_dir}/used.txt"
	local extra_file=""
	local tmp_seed=""
	local tmp_try=0
	local ret=0

	printf '%s' "${need}" | grep -Eq '^[0-9]+$' || need=1
	[ "${need}" -gt 0 ] || need=1
	tmp_seed=$(date +%s 2>/dev/null)
	[ -n "${tmp_seed}" ] || tmp_seed="0"
	while [ "${tmp_try}" -lt 128 ]
	do
		tmp_dir="/tmp/fss_ports.${tmp_seed}.$$.$tmp_try"
		if mkdir "${tmp_dir}" 2>/dev/null; then
			break
		fi
		tmp_try=$((tmp_try + 1))
	done
	[ -n "${tmp_dir}" ] && [ -d "${tmp_dir}" ] || return 1
	used_file="${tmp_dir}/used.txt"
	: > "${used_file}"

	# `-nlp` 只能看到监听端口，测速时大量已建立/TIME_WAIT 的本地端口也会占用 bind。
	netstat -an 2>/dev/null | awk '
		/^(tcp|udp|raw)/ {
			n = split($4, parts, ":")
			port = parts[n]
			if (port ~ /^[0-9]+$/) {
				print port
			}
		}
	' > "${used_file}"
	shift
	for extra_file in "$@"
	do
		[ -f "${extra_file}" ] || continue
		cat "${extra_file}" >> "${used_file}"
	done
	awk -v need="${need}" -v seed="${tmp_seed}" '
		/^[0-9]+$/ {
			used[$1] = 1
			next
		}
		END {
			min = 2000
			max = 65000
			range = max - min + 1
			if (need < 1) {
				need = 1
			}
			srand(seed + 0)
			start = int(rand() * range)
			count = 0
			for (offset = 0; offset < range && count < need; offset++) {
				port = min + ((start + offset) % range)
				if (!(port in used)) {
					print port
					used[port] = 1
					count++
				}
			}
			if (count < need) {
				exit 1
			}
		}
	' "${used_file}"
	ret=$?
	rm -rf "${tmp_dir}"
	return "${ret}"
}

kill_used_port(){
	# ports will be used in fancyss
	local ports="3333 3334 23456 7913 1051 1052 2051 2052 2055 2056 1091 1092 1093"
	local relay_port
	local relay_port_base="${SMARTDNS_RELAY_PORT_BASE}"
	local relay_port_max="${SMARTDNS_RELAY_PORT_MAX}"
	printf '%s' "${relay_port_base}" | grep -Eq '^[0-9]+$' || relay_port_base=1055
	printf '%s' "${relay_port_max}" | grep -Eq '^[0-9]+$' || relay_port_max=1070
	relay_port=${relay_port_base}
	while [ "${relay_port}" -le "${relay_port_max}" ]
	do
		ports="${ports} ${relay_port}"
		relay_port=$((relay_port + 1))
	done
	# get all used port in system
	local LISTENS=$(netstat -nlp 2>/dev/null | grep -E "^tcp|^udp|^raw" | awk '{print $4}'|awk -F ":" '{print $NF}'|sort -un)
	# get target ports that have been used
	local used_ports=$(echo ${ports} ${LISTENS} | sed 's/[[:space:]]/\n/g' | sort -n | uniq -d | tr '\n' ' ' | sed 's/[[:space:]]$//g')
	# kill ports taken program
	if [ -n "${used_ports}" ];then
		echo_date "检测到冲突端口：${used_ports}，尝试关闭占用端口的程序..."
		for used_port in ${used_ports}
		do
			local _ret=$(netstat -nlp 2>/dev/null | grep -E "^tcp|^udp|^raw" | grep -w "${used_port}" | awk '{print $NF}')
			local _conflic_prg=$(echo "${_ret}" | awk -F "/" '{print $2}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]$//g' )
			local _conflic_pid=$(echo "${_ret}" | awk -F "/" '{print $1}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]$//g' )
			if [ "${FSS_SKIP_XRAY_PORT_CLEANUP}" = "1" ] && echo " ${_conflic_prg} " | grep -q " xray "; then
				echo_date "[hot-reload] 冲突端口 ${used_port} 当前由 xray 占用，保留现有进程。"
				continue
			fi
			echo_date "关闭冲突端口 ${used_port} 占用程序：${_conflic_prg}，pid：${_conflic_pid}"
			kill -9 "${_conflic_pid}" >/dev/null 2>&1
		done
	fi
}

set_default() {
	local var_name="$1"
	local default_value="$2"
	
	# 使用间接变量引用获取变量的值
	eval "current_value=\$$var_name"
	
	# 如果该变量为空，则赋值并更新 dbus
	if [ -z "$current_value" ]; then
		eval "$var_name=\$default_value"
		dbus set "$var_name=$default_value"
	fi
}
