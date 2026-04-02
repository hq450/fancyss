#!/bin/sh

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/koolshare/bin:${PATH}"
export PATH

ss_basic_mode="$(dbus get ss_basic_mode 2>/dev/null)"

OUTPUT_FILE="/tmp/upload/ss_shunt_stats.json"
XRAY_CONFIG_FILE="/koolshare/ss/xray.json"
XRAY_API_SERVER="127.0.0.1:10085"
OUTPUT_MODE="${1:-api}"

run() {
	env -i PATH=${PATH} "$@"
}

write_empty_payload() {
	local enabled="$1"
	local ok="$2"
	mkdir -p /tmp/upload >/dev/null 2>&1
	cat > "${OUTPUT_FILE}" <<-EOF
	{"ok":${ok:-0},"enabled":${enabled:-0},"updated_at":$(date +%s),"summary":{"memory_rss_kb":0,"memory_text":"","uptime_seconds":-1,"uptime_text":"","total_uplink":0,"total_downlink":0,"total_traffic":0,"traffic_ready":0,"connection_count":"","connection_text":""},"stats":{}}
	EOF
}

write_process_state_payload() {
	local enabled="$1"
	local ok="$2"
	local rss_kb="$3"
	local memory_text="$4"
	local uptime_secs="$5"
	local uptime_text="$6"

	mkdir -p /tmp/upload >/dev/null 2>&1
	cat > "${OUTPUT_FILE}" <<-EOF
	{"ok":${ok:-1},"enabled":${enabled:-1},"updated_at":$(date +%s),"summary":{"memory_rss_kb":${rss_kb:-0},"memory_text":"${memory_text}","uptime_seconds":${uptime_secs:--1},"uptime_text":"${uptime_text}","total_uplink":0,"total_downlink":0,"total_traffic":0,"traffic_ready":0,"connection_count":"","connection_text":""},"stats":{}}
	EOF
}

respond_api() {
	printf '{"result":"%s"}\n' "${1:-ok}"
}

emit_response() {
	if [ "${OUTPUT_MODE}" = "ws" ]; then
		[ -s "${OUTPUT_FILE}" ] && cat "${OUTPUT_FILE}"
	else
		respond_api "${1:-ok}"
	fi
}

pick_xray_bin() {
	if command -v xray >/dev/null 2>&1; then
		command -v xray
		return 0
	fi
	if [ -x "/koolshare/bin/xray" ]; then
		echo "/koolshare/bin/xray"
		return 0
	fi
	return 1
}

pick_xapi_tool() {
	if command -v xapi-tool >/dev/null 2>&1; then
		command -v xapi-tool
		return 0
	fi
	if [ -x "/koolshare/bin/xapi-tool" ]; then
		echo "/koolshare/bin/xapi-tool"
		return 0
	fi
	return 1
}

is_xray_api_ready() {
	netstat -nlp 2>/dev/null | awk '
		$4 ~ /(^127\.0\.0\.1:10085$|^:::10085$|^0\.0\.0\.0:10085$)/ && $0 ~ /xray/ {
			found = 1
		}
		END {
			exit(found ? 0 : 1)
		}
	'
}

collect_stats_payload() {
	local xapi_tool=""
	local xray_bin="$1"
	if xapi_tool="$(pick_xapi_tool 2>/dev/null)"; then
		run "${xapi_tool}" stats-query --server "${XRAY_API_SERVER}" --pattern "outbound>>>" 2>/dev/null
		return 0
	fi
	run "${xray_bin}" api statsquery --server="${XRAY_API_SERVER}" 2>/dev/null | awk '
	function flush_stat(tag, uplink, downlink, total, first_item) {
		if (tag == "" || (tag !~ /^proxy[0-9]+$/ && tag != "direct")) {
			return
		}
		uplink += 0
		downlink += 0
		total = uplink + downlink
		if (first_json == 0) {
			printf ","
		}
		first_json = 0
		printf "\"%s\":{\"uplink\":%.0f,\"downlink\":%.0f,\"total\":%.0f}", tag, uplink, downlink, total
	}
	BEGIN {
		first_json = 1
		stat_name = ""
	}
	{
		if ($0 ~ /"name"[[:space:]]*:/) {
			stat_name = $0
			sub(/^.*"name"[[:space:]]*:[[:space:]]*"/, "", stat_name)
			sub(/".*$/, "", stat_name)
			next
		}
		if ($0 ~ /"value"[[:space:]]*:/) {
			stat_value = $0
			sub(/^.*"value"[[:space:]]*:[[:space:]]*/, "", stat_value)
			sub(/[^0-9].*$/, "", stat_value)
			if (stat_name ~ /^outbound>>>/) {
				split(stat_name, parts, ">>>")
				tag = parts[2]
				direction = parts[4]
				if (direction == "uplink") {
					uplink[tag] += stat_value + 0
				} else if (direction == "downlink") {
					downlink[tag] += stat_value + 0
				}
			}
			stat_name = ""
		}
	}
	END {
		proxy_up = 0
		proxy_down = 0
		printf "{\"ok\":1,\"enabled\":1,\"updated_at\":%d,\"summary\":{\"total_uplink\":", systime()
		for (tag in uplink) {
			if (tag ~ /^proxy[0-9]+$/) proxy_up += uplink[tag]
		}
		for (tag in downlink) {
			if (tag ~ /^proxy[0-9]+$/) proxy_down += downlink[tag]
		}
		printf "%.0f,\"total_downlink\":%.0f,\"total_traffic\":%.0f,\"traffic_ready\":1,\"connection_count\":\"\",\"connection_text\":\"\"},\"stats\":{", proxy_up, proxy_down, proxy_up + proxy_down
		for (tag in uplink) {
			seen[tag] = 1
		}
		for (tag in downlink) {
			seen[tag] = 1
		}
		for (tag in seen) {
			flush_stat(tag, uplink[tag], downlink[tag])
		}
		printf "}}"
	}'
}

get_main_xray_pid() {
	local pid=""
	local cmdline=""

	for pid in $(pidof xray 2>/dev/null)
	do
		[ -r "/proc/${pid}/cmdline" ] || continue
		cmdline="$(tr '\000' ' ' < "/proc/${pid}/cmdline" 2>/dev/null)"
		case "${cmdline}" in
		*"/koolshare/bin/xray run -c /koolshare/ss/xray.json"*)
			printf '%s\n' "${pid}"
			return 0
			;;
		esac
	done
	ps w 2>/dev/null | awk '
		$0 ~ /\/koolshare\/bin\/xray run -c \/koolshare\/ss\/xray\.json/ {
			print $1
			exit
		}
	'
}

get_main_xray_rss_kb() {
	local pid="$1"
	local rss_kb=""

	[ -n "${pid}" ] || return 1
	if [ -r "/proc/${pid}/status" ]; then
		rss_kb="$(awk '/VmRSS:/ {print $2; exit}' "/proc/${pid}/status" 2>/dev/null)"
	fi
	[ -n "${rss_kb}" ] || rss_kb="0"
	printf '%s\n' "${rss_kb}"
}

format_memory_text() {
	local rss_kb="$1"

	[ -n "${rss_kb}" ] || rss_kb="0"
	if [ "${rss_kb}" -ge 1024 ] 2>/dev/null; then
		awk -v kb="${rss_kb}" 'BEGIN {printf "%.1f MB", kb / 1024}'
	elif [ "${rss_kb}" -gt 0 ] 2>/dev/null; then
		printf '%s KB' "${rss_kb}"
	fi
}

get_main_xray_uptime_seconds() {
	local pid="$1"
	local start_ticks=""
	local uptime_secs=""
	local system_uptime=""
	local clock_ticks=""

	[ -n "${pid}" ] || return 1
	[ -r "/proc/${pid}/stat" ] || return 1
	start_ticks="$(awk '{print $22; exit}' "/proc/${pid}/stat" 2>/dev/null)"
	[ -n "${start_ticks}" ] || return 1
	system_uptime="$(awk -F '.' 'NR==1 {print $1; exit}' /proc/uptime 2>/dev/null)"
	[ -n "${system_uptime}" ] || return 1
	clock_ticks="$(getconf CLK_TCK 2>/dev/null | sed -n '1p')"
	[ -n "${clock_ticks}" ] || clock_ticks="100"
	uptime_secs=$((system_uptime - start_ticks / clock_ticks))
	[ "${uptime_secs}" -ge 0 ] 2>/dev/null || uptime_secs=0
	printf '%s\n' "${uptime_secs}"
}

format_uptime_text() {
	local uptime_secs="$1"
	local days=0
	local hours=0
	local mins=0
	local secs=0

	[ -n "${uptime_secs}" ] || uptime_secs="0"
	days=$((uptime_secs / 86400))
	hours=$(((uptime_secs % 86400) / 3600))
	mins=$(((uptime_secs % 3600) / 60))
	secs=$((uptime_secs % 60))

	if [ "${days}" -gt 0 ]; then
		printf '%s天%s时%s分%s秒' "${days}" "${hours}" "${mins}" "${secs}"
	elif [ "${hours}" -gt 0 ]; then
		printf '%s时%s分%s秒' "${hours}" "${mins}" "${secs}"
	elif [ "${mins}" -gt 0 ]; then
		printf '%s分%s秒' "${mins}" "${secs}"
	else
		printf '%s秒' "${secs}"
	fi
}

append_process_summary() {
	local payload="$1"
	local rss_kb="$2"
	local memory_text="$3"
	local uptime_secs="$4"
	local uptime_text="$5"

	[ -n "${payload}" ] || return 1
	printf '%s\n' "${payload}" | awk -v rss="${rss_kb}" -v text="${memory_text}" -v uptime="${uptime_secs}" -v uptime_text="${uptime_text}" '
		BEGIN {
			gsub(/\\/, "\\\\", text)
			gsub(/"/, "\\\"", text)
			gsub(/\\/, "\\\\", uptime_text)
			gsub(/"/, "\\\"", uptime_text)
		}
		{
			sub(/"summary":\{/, "\"summary\":{\"memory_rss_kb\":" rss ",\"memory_text\":\"" text "\",\"uptime_seconds\":" uptime ",\"uptime_text\":\"" uptime_text "\",")
			print
		}
	'
}

main() {
	local xray_bin=""
	local payload=""
	local pid=""
	local rss_kb="0"
	local memory_text=""
	local uptime_secs="-1"
	local uptime_text=""

	[ "${ss_basic_mode}" = "7" ] || {
		emit_response "ok"
		return 0
	}
	pid="$(get_main_xray_pid)"
	if [ -z "${pid}" ]; then
		write_process_state_payload 1 1 0 "" -1 "xray not running!"
		emit_response "ok"
		return 0
	fi
	rss_kb="$(get_main_xray_rss_kb "${pid}" 2>/dev/null || echo 0)"
	memory_text="$(format_memory_text "${rss_kb}" 2>/dev/null)"
	uptime_secs="$(get_main_xray_uptime_seconds "${pid}" 2>/dev/null || echo 0)"
	uptime_text="$(format_uptime_text "${uptime_secs}" 2>/dev/null)"
	if [ "${OUTPUT_MODE}" = "ws" ]; then
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
	fi
	[ -s "${XRAY_CONFIG_FILE}" ] || {
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
		return 0
	}
	grep -q '"StatsService"' "${XRAY_CONFIG_FILE}" 2>/dev/null || {
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
		return 0
	}
	grep -q '"port":[[:space:]]*10085' "${XRAY_CONFIG_FILE}" 2>/dev/null || {
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
		return 0
	}
	is_xray_api_ready || {
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
		return 0
	}
	xray_bin="$(pick_xray_bin)" || {
		write_process_state_payload 1 1 "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}"
		emit_response "ok"
		return 0
	}
	payload="$(collect_stats_payload "${xray_bin}")"
	if [ -n "${payload}" ]; then
		payload="$(append_process_summary "${payload}" "${rss_kb}" "${memory_text}" "${uptime_secs}" "${uptime_text}")"
		printf '%s\n' "${payload}" > "${OUTPUT_FILE}"
	else
		write_empty_payload 1 1
	fi
	emit_response "ok"
}

main "$@"
