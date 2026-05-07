#!/bin/sh

source /koolshare/scripts/ss_base.sh

STATUS_TOOL_BIN="/koolshare/bin/status-tool"
STATUS_DAEMON_PIDFILE="/var/run/status-tool.pid"
STATUS_SERVE_PIDFILE="/var/run/status-tool-serve.pid"
STATUS_DAEMON_STATE="/tmp/upload/ss_status_daemon.json"
STATUS_DAEMON_LEGACY="/tmp/upload/ss_status_front.txt"
STATUS_SERVE_SOCKET="/tmp/status-tool.sock"
STATUS_SERVE_ARGS_FILE="/tmp/status-tool-serve.args"
STATUS_WS_LOCK_DIR="/tmp/fancyss_status_ws.lock"
STATUS_HTTP_LOCK_DIR="/tmp/fancyss_status_http.lock"

kill_status_stream_followers() {
	ps w | grep -F "/tmp/upload/ssf_status.stream" | grep -v grep | awk '{print $1}' | while read -r pid; do
		[ -n "${pid}" ] && kill "${pid}" >/dev/null 2>&1
	done
	ps w | grep -F "/tmp/upload/ssc_status.stream" | grep -v grep | awk '{print $1}' | while read -r pid; do
		[ -n "${pid}" ] && kill "${pid}" >/dev/null 2>&1
	done
	ps w | grep -F "sh /koolshare/scripts/ss_status_ws.sh" | grep -v grep | awk '{print $1}' | while read -r pid; do
		[ -n "${pid}" ] && kill "${pid}" >/dev/null 2>&1
	done
}

status_tool_tz() {
	local tz=""
	tz="$(nvram get time_zone 2>/dev/null)"
	[ -n "${tz}" ] || tz="$(nvram get time_zone_x 2>/dev/null)"
	[ -n "${tz}" ] || tz="CST-8"
	printf '%s' "${tz}"
}

pick_status_interval_ms() {
	case "$(dbus get ss_basic_interval)" in
	1) echo 1000 ;;
	2) echo 3500 ;;
	3) echo 9500 ;;
	4) echo 21500 ;;
	5) echo 45500 ;;
	*) echo 3500 ;;
	esac
}

pick_status_urls() {
	local chn="$(dbus get ss_basic_curl)"
	local frn="$(dbus get ss_basic_furl)"
	[ -n "${chn}" ] || chn="$(get_fancyss_default_curl)"
	[ -n "${frn}" ] || frn="$(get_fancyss_default_furl)"
	printf '%s\n%s\n' "${chn}" "${frn}"
}

write_waiting_cache() {
	local now="$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")"
	local ipv6="$(dbus get ss_basic_proxy_ipv6)"
	mkdir -p /tmp/upload
	if [ "${ipv6}" = "1" ];then
		printf '%s' "国外IPv4 【${now}】：等待...@@国外IPv6 【${now}】：等待...@@国内连接 【${now}】：等待..." > "${STATUS_DAEMON_LEGACY}"
	else
		printf '%s' "国外链接 【${now}】：等待...@@国内连接 【${now}】：等待..." > "${STATUS_DAEMON_LEGACY}"
	fi
}

ensure_waiting_cache() {
	[ -s "${STATUS_DAEMON_LEGACY}" ] && return 0
	write_waiting_cache
}

start_status_daemon() {
	[ -x "${STATUS_TOOL_BIN}" ] || return 1
	local chn_url
	local frn_url
	local interval_ms
	local proxy_ipv6
	ensure_waiting_cache
	{
		read -r chn_url
		read -r frn_url
	} <<-EOF
	$(pick_status_urls)
	EOF
	interval_ms="$(pick_status_interval_ms)"
	proxy_ipv6="$(dbus get ss_basic_proxy_ipv6)"
	env TZ="$(status_tool_tz)" start-stop-daemon -S -q -b -m -p "${STATUS_DAEMON_PIDFILE}" -x "${STATUS_TOOL_BIN}" -- daemon \
		--china-url "${chn_url}" \
		--foreign-url "${frn_url}" \
		--proxy-ipv6 "${proxy_ipv6:-0}" \
		--foreign-proxy "socks5://127.0.0.1:23456" \
		--interval-ms "${interval_ms}" \
		--state-file "${STATUS_DAEMON_STATE}" \
		--legacy-file "${STATUS_DAEMON_LEGACY}"
}

status_probe_mode() {
	local mode="$(dbus get ss_basic_status_mode 2>/dev/null)"
	case "${mode}" in
	serve|once)
		printf '%s' "${mode}"
		;;
	*)
		printf '%s' "serve"
		;;
	esac
}

start_status_serve() {
	[ -x "${STATUS_TOOL_BIN}" ] || return 1
	local chn_url
	local frn_url
	local proxy_ipv6
	ensure_waiting_cache
	{
		read -r chn_url
		read -r frn_url
	} <<-EOF
	$(pick_status_urls)
	EOF
	proxy_ipv6="$(dbus get ss_basic_proxy_ipv6)"
	ps w | grep -E '(^| )/koolshare/bin/status-tool serve( |$)' | grep -v grep | awk '{print $1}' | while read -r pid; do
		[ -n "${pid}" ] && kill "${pid}" >/dev/null 2>&1
	done
	rm -f "${STATUS_SERVE_SOCKET}" "${STATUS_SERVE_PIDFILE}" >/dev/null 2>&1
	{
		printf 'china_url=%s\n' "${chn_url}"
		printf 'foreign_url=%s\n' "${frn_url}"
		printf 'proxy_ipv6=%s\n' "${proxy_ipv6:-0}"
	} > "${STATUS_SERVE_ARGS_FILE}" 2>/dev/null
	env TZ="$(status_tool_tz)" start-stop-daemon -S -q -b -m -p "${STATUS_SERVE_PIDFILE}" -x "${STATUS_TOOL_BIN}" -- serve \
		--socket-path "${STATUS_SERVE_SOCKET}" \
		--china-url "${chn_url}" \
		--foreign-url "${frn_url}" \
		--proxy-ipv6 "${proxy_ipv6:-0}" \
		--foreign-proxy "socks5://127.0.0.1:23456" \
		--state-file "${STATUS_DAEMON_STATE}" \
		--legacy-file "${STATUS_DAEMON_LEGACY}" >/tmp/upload/status-tool-serve.log 2>&1
	sleep 1
	if [ -f "${STATUS_SERVE_PIDFILE}" ] && [ -S "${STATUS_SERVE_SOCKET}" ];then
		return 0
	fi
	return 1
}

stop_status_daemon() {
	kill_status_stream_followers
	if [ -f "${STATUS_DAEMON_PIDFILE}" ];then
		start-stop-daemon -K -q -p "${STATUS_DAEMON_PIDFILE}" >/dev/null 2>&1
	fi
	if [ -f "${STATUS_SERVE_PIDFILE}" ];then
		start-stop-daemon -K -q -p "${STATUS_SERVE_PIDFILE}" >/dev/null 2>&1
	fi
	ps w | grep -E '(^| )(/koolshare/bin/status-tool|/tmp/status-tool-serve) (daemon|serve|fancyss)( |$)' | grep -v grep | awk '{print $1}' | while read -r pid; do
		kill "${pid}" >/dev/null 2>&1
	done
	rm -f "${STATUS_DAEMON_PIDFILE}" "${STATUS_SERVE_PIDFILE}" "${STATUS_DAEMON_STATE}" "${STATUS_DAEMON_LEGACY}" "${STATUS_SERVE_SOCKET}" "${STATUS_SERVE_ARGS_FILE}" >/dev/null 2>&1
	rm -rf "${STATUS_WS_LOCK_DIR}" >/dev/null 2>&1
	rm -rf "${STATUS_HTTP_LOCK_DIR}" >/dev/null 2>&1
}

restart_status_daemon() {
	stop_status_daemon
	if [ "$(dbus get ss_failover_enable)" = "1" ];then
		start_status_daemon
	elif [ "$(status_probe_mode)" = "serve" ];then
		start_status_serve
	fi
}

case "$1" in
start)
	if [ "$(dbus get ss_failover_enable)" = "1" ];then
		start_status_daemon
	elif [ "$(status_probe_mode)" = "serve" ];then
		start_status_serve
	fi
	;;
stop)
	stop_status_daemon
	;;
restart)
	restart_status_daemon
	;;
esac
