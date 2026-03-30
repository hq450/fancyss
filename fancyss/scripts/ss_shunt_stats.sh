#!/bin/sh

source /koolshare/scripts/ss_base.sh

OUTPUT_FILE="/tmp/upload/ss_shunt_stats.json"
XRAY_CONFIG_FILE="/koolshare/ss/xray.json"
XRAY_API_SERVER="127.0.0.1:10085"

run() {
	env -i PATH=${PATH} "$@"
}

write_empty_payload() {
	local enabled="$1"
	local ok="$2"
	mkdir -p /tmp/upload >/dev/null 2>&1
	cat > "${OUTPUT_FILE}" <<-EOF
	{"ok":${ok:-0},"enabled":${enabled:-0},"updated_at":$(date +%s),"stats":{}}
	EOF
}

respond_api() {
	printf '{"result":"%s"}\n' "${1:-ok}"
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
	local xray_bin="$1"
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
		printf "{\"ok\":1,\"enabled\":1,\"updated_at\":%d,\"stats\":{", systime()
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

main() {
	local xray_bin=""
	local payload=""

	write_empty_payload 0 0
	[ "${ss_basic_mode}" = "7" ] || {
		respond_api "ok"
		return 0
	}
	[ -s "${XRAY_CONFIG_FILE}" ] || {
		respond_api "ok"
		return 0
	}
	grep -q '"StatsService"' "${XRAY_CONFIG_FILE}" 2>/dev/null || {
		respond_api "ok"
		return 0
	}
	grep -q '"port":[[:space:]]*10085' "${XRAY_CONFIG_FILE}" 2>/dev/null || {
		respond_api "ok"
		return 0
	}
	is_xray_api_ready || {
		respond_api "ok"
		return 0
	}
	xray_bin="$(pick_xray_bin)" || {
		respond_api "ok"
		return 0
	}
	payload="$(collect_stats_payload "${xray_bin}")"
	if [ -n "${payload}" ]; then
		printf '%s\n' "${payload}" > "${OUTPUT_FILE}"
	else
		write_empty_payload 1 1
	fi
	respond_api "ok"
}

main "$@"
