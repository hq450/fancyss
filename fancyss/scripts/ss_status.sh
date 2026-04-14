#!/bin/sh

source /koolshare/scripts/ss_base.sh

STATUS_FRONT_CACHE=/tmp/upload/ss_status_front.txt
STATUS_BACK_CACHE=/tmp/upload/ss_status.txt
STATUS_WS_CACHE_FILE=/tmp/upload/ss_status_ws.txt
STATUS_WS_LOCK_DIR=/tmp/fancyss_status_ws.lock
STATUS_SERVE_SOCKET=/tmp/status-tool.sock
STATUS_CTL_BIN=/koolshare/bin/statusctl

LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
HEART_STATUS=$(dbus get ss_heart_beat)
CHN_TEST_SITE="${ss_basic_curl}"
FRN_TEST_SITE="${ss_basic_furl}"
PROXY_IPV6=$(dbus get ss_basic_proxy_ipv6)
[ -n "${CHN_TEST_SITE}" ] || CHN_TEST_SITE="$(get_fancyss_default_curl)"
[ -n "${FRN_TEST_SITE}" ] || FRN_TEST_SITE="$(get_fancyss_default_furl)"

pick_status_tool(){
	if [ -x "/koolshare/bin/status-tool" ];then
		echo "/koolshare/bin/status-tool"
		return 0
	fi
	if command -v status-tool >/dev/null 2>&1;then
		command -v status-tool
		return 0
	fi
	return 1
}

status_socks5_ready() {
	netstat -nlp 2>/dev/null \
		| grep -w "23456" \
		| grep -Eq "xray|v2ray|naive|tuic|rss-local"
}

set_waiting_status(){
	if [ "${PROXY_IPV6}" = "1" ];then
		log1="国外IPv4 【${LOGTIME}】：等待..."
		log3="国外IPv6 【${LOGTIME}】：等待..."
	else
		log1="国外链接 【${LOGTIME}】：等待..."
		log3=""
	fi
	log2="国内连接 【${LOGTIME}】：等待..."
}

get_status_payload(){
	if [ "${PROXY_IPV6}" = "1" ];then
		printf '%s' "${log1}@@${log3}@@${log2}"
	else
		printf '%s' "${log1}@@${log2}"
	fi
}

read_front_cache(){
	[ -s "${STATUS_FRONT_CACHE}" ] || return 1
	cat "${STATUS_FRONT_CACHE}" 2>/dev/null
}

read_ws_cache(){
	[ -s "${STATUS_WS_CACHE_FILE}" ] || return 1
	cat "${STATUS_WS_CACHE_FILE}" 2>/dev/null
}

write_ws_cache(){
	[ -n "$1" ] || return 1
	printf '%s' "$1" > "${STATUS_WS_CACHE_FILE}" 2>/dev/null
}

acquire_status_ws_lock(){
	mkdir "${STATUS_WS_LOCK_DIR}" >/dev/null 2>&1
}

release_status_ws_lock(){
	rmdir "${STATUS_WS_LOCK_DIR}" >/dev/null 2>&1
}

json_probe_line(){
	local json_text="$1"
	local probe_name="$2"
	local label="$3"
	local now="$4"
	local ok ms
	ok=$(printf '%s' "${json_text}" | jq -r --arg name "${probe_name}" '(.results // []) | map(select(.name == $name)) | if length == 0 then "false" else (.[0].ok // false) end' 2>/dev/null)
	ms=$(printf '%s' "${json_text}" | jq -r --arg name "${probe_name}" '(.results // []) | map(select(.name == $name)) | if length == 0 then "0" else (.[0].elapsed_ms // 0) end' 2>/dev/null)
	if [ "${ok}" = "true" ];then
		if [ "${ms}" != "0" ];then
			printf '%s' "${label} 【${now}】 ✓&nbsp;&nbsp;${ms} ms"
			return 0
		fi
	fi
	printf '%s' "${label} 【${now}】 <font color=\"#FF0000\">X</font>"
}

refresh_payload_once(){
	local status_tool="$1"
	if [ "${PROXY_IPV6}" = "1" ];then
		"${status_tool}" fancyss --china-url "${CHN_TEST_SITE}" --foreign-url "${FRN_TEST_SITE}" --proxy-ipv6 1 2>/dev/null || return 1
	else
		"${status_tool}" fancyss --china-url "${CHN_TEST_SITE}" --foreign-url "${FRN_TEST_SITE}" --proxy-ipv6 0 --foreign-proxy "socks5://127.0.0.1:23456" 2>/dev/null || return 1
	fi
}

refresh_payload_via_ctl(){
	local payload=""
	payload="$("${STATUS_CTL_BIN}" --socket-path "${STATUS_SERVE_SOCKET}" probe-once 2>/dev/null)" || payload=""
	case "${payload}" in
	""|cache-miss*)
		payload="$("${STATUS_CTL_BIN}" --socket-path "${STATUS_SERVE_SOCKET}" get-cache 2>/dev/null)" || return 1
		;;
	esac
	printf '%s' "${payload}" | sed 's/[[:space:]]*$//'
}

prepare(){
	local fancyss_enable="$(dbus get ss_basic_enable)"
	if [ "${fancyss_enable}" != "1" ];then
		set_waiting_status
		return 1
	fi
	if [ "$(dbus get ss_basic_wait)" = "1" ];then
		set_waiting_status
		return 1
	fi
	if ps | grep "ssconfig.sh" | grep -v grep >/dev/null 2>&1;then
		set_waiting_status
		return 1
	fi
	if [ "${ss_failover_enable}" != "1" ] && ! status_socks5_ready;then
		set_waiting_status
		return 1
	fi
	return 0
}

resolve_payload(){
	local payload=""
	if payload="$(read_front_cache)"; then
		printf '%s' "${payload}"
		return 0
	fi
	if status_tool_bin="$(pick_status_tool)"; then
		if payload="$(refresh_payload_once "${status_tool_bin}")"; then
			printf '%s' "${payload}"
			return 0
		fi
	fi
	set_waiting_status
	get_status_payload
	return 0
}

resolve_payload_once_only(){
	local payload=""
	if [ -x "${STATUS_CTL_BIN}" ] && [ -S "${STATUS_SERVE_SOCKET}" ];then
		if payload="$(refresh_payload_via_ctl)"; then
			printf '%s' "${payload}"
			return 0
		fi
	fi
	if status_tool_bin="$(pick_status_tool)"; then
		if payload="$(refresh_payload_once "${status_tool_bin}")"; then
			printf '%s' "${payload}"
			return 0
		fi
	fi
	set_waiting_status
	get_status_payload
	return 0
}

if [ -z "$1" ] && [ -z "$2" ];then
	if ! prepare >/dev/null 2>&1; then
		get_status_payload
		exit
	fi
	if [ "${ss_failover_enable}" = "1" ];then
		resolve_payload
	else
		resolve_payload_once_only
	fi
	exit
fi

case "$1" in
ws)
		if ! prepare >/dev/null 2>&1; then
			set_waiting_status
			get_status_payload
			exit 0
		fi
		if ! acquire_status_ws_lock; then
			if payload="$(read_ws_cache)"; then
				printf '%s' "${payload}"
			else
				if [ "${ss_failover_enable}" = "1" ];then
					resolve_payload
				else
					resolve_payload_once_only
				fi
			fi
			exit 0
		fi
		trap 'release_status_ws_lock' EXIT INT TERM
		if [ "${ss_failover_enable}" = "1" ];then
			payload="$(resolve_payload)"
		else
			payload="$(resolve_payload_once_only)"
		fi
		write_ws_cache "${payload}" >/dev/null 2>&1
		printf '%s' "${payload}"
		;;
	*)
		if ! prepare >/dev/null 2>&1; then
			set_waiting_status
			payload="$(get_status_payload)"
		else
			if [ "${ss_failover_enable}" = "1" ];then
				payload="$(resolve_payload)"
			else
				payload="$(resolve_payload_once_only)"
			fi
		fi
		if [ "${ss_failover_enable}" = "1" ];then
			printf '%s@@%s\n' "${payload}" "${HEART_STATUS}" > "${STATUS_BACK_CACHE}"
		else
			http_response "${payload}"
		fi
		;;
esac
