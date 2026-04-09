#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
LOGFILE_F=/tmp/upload/ssf_status.txt
LOGFILE_C=/tmp/upload/ssc_status.txt
LOGTIME=$(TZ=UTC-8 date -R "+%Y-%m-%d %H:%M:%S")
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
CURRENT=$(fss_get_current_node_id)
CURRENT_NAME=$(fss_get_node_field_plain "${CURRENT}" name)
CURRENT_SERVER_HOST=""
CURRENT_SERVER_PORT=""
CURRENT_SERVER_ADDR=""
{
	read -r CURRENT_SERVER_HOST
	read -r CURRENT_SERVER_PORT
} <<-EOF
$(fss_get_node_server_host_port "${CURRENT}")
EOF
CURRENT_SERVER_ADDR="$(fss_get_node_field_plain "${CURRENT}" server_ip)"
[ -z "${CURRENT_SERVER_ADDR}" ] && CURRENT_SERVER_ADDR="${CURRENT_SERVER_HOST}"
HEART_STATUS=$(dbus get ss_heart_beat)
eval $(dbus export ss_failover_enable)
CHN_TEST_SITE="${ss_basic_curl}"
FRN_TEST_SITE="${ss_basic_furl}"
PROXY_IPV6=$(dbus get ss_basic_proxy_ipv6)
[ -z "${CHN_TEST_SITE}" ] && CHN_TEST_SITE="$(get_fancyss_default_curl)"
[ -z "${FRN_TEST_SITE}" ] && FRN_TEST_SITE="$(get_fancyss_default_furl)"
SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "ss-local|sslocal|v2ray|xray|trojan|naive|tuic|hysteria"|head -n1)
REDIRC_OPEN=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -Eo "ss-redir|sslocal|v2ray|xray|trojan|ipt2socks|hysteria"|head -n1)
STATUS_HISTORY_DIR=/tmp/upload/ss_status_history
STATUS_WS_LOCK_DIR=/tmp/fancyss_status_ws.lock
STATUS_WS_CACHE_FILE=/tmp/upload/ss_status_ws.txt
STATUS_TOOL_TIMEOUT_MS=3000

run(){
	env -i PATH=${PATH} "$@"
}

pick_status_tool(){
	if [ -x "/koolshare/bin/status-tool" ];then
		echo "/koolshare/bin/status-tool"
		return 0
	fi
	if command -v status-tool >/dev/null 2>&1;then
		echo "$(command -v status-tool)"
		return 0
	fi
	return 1
}

status_tool_escape_json(){
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

status_tool_write_probe_json(){
	local cfg_file="$1"
	local comma="$2"
	local name="$3"
	local url="$4"
	local family="$5"
	local mode="$6"
	local proxy="$7"
	local warmup="$8"
	local attempts="$9"
	local timeout_ms="${10}"
	local esc_name esc_url esc_proxy
	esc_name=$(status_tool_escape_json "${name}")
	esc_url=$(status_tool_escape_json "${url}")
	esc_proxy=$(status_tool_escape_json "${proxy}")
	if [ -n "${proxy}" ];then
		cat >>"${cfg_file}" <<-EOF
		${comma}{
		  "name": "${esc_name}",
		  "url": "${esc_url}",
		  "family": "${family}",
		  "mode": "${mode}",
		  "warmup": ${warmup},
		  "attempts": ${attempts},
		  "timeout_ms": ${timeout_ms},
		  "proxy": "${esc_proxy}"
		}
		EOF
	else
		cat >>"${cfg_file}" <<-EOF
		${comma}{
		  "name": "${esc_name}",
		  "url": "${esc_url}",
		  "family": "${family}",
		  "mode": "${mode}",
		  "warmup": ${warmup},
		  "attempts": ${attempts},
		  "timeout_ms": ${timeout_ms}
		}
		EOF
	fi
}

status_tool_cleanup_tmp(){
	rm -f "$1" "$2" >/dev/null 2>&1
}

status_tool_get_legacy_result(){
	local json_file="$1"
	local probe_name="$2"
	jq -r --arg name "${probe_name}" '
		(.results // [])
		| map(select(.name == $name))
		| if length == 0 then
			""
		  else
			.[0] as $item
			| "\((($item.elapsed_ms // 0) / 1000))|\(($item.status_code // 0))|\(($item.remote_addr // ""))|\(($item.error // ""))"
		  end
	' "${json_file}" 2>/dev/null
}

status_tool_probe_all(){
	local status_tool="$1"
	local request_tag="$2"
	local cfg_file="/tmp/status-tool-status.${$}.json"
	local out_file="/tmp/status-tool-status.${$}.out"
	local china_result=""
	local foreign4_result=""
	local foreign6_result=""
	local probe_count=0
	local comma=""
	local foreign_mode="direct"
	local foreign_proxy=""

	cat >"${cfg_file}" <<-EOF
	{
	  "output": "json",
	  "probes": [
	EOF

	status_tool_write_probe_json "${cfg_file}" "" "china" "${CHN_TEST_SITE}" "ipv4" "direct" "" 0 1 "${STATUS_TOOL_TIMEOUT_MS}"
	probe_count=$((probe_count + 1))
	comma=","

	if [ "${PROXY_IPV6}" = "1" ];then
		if [ -n "${REDIRC_OPEN}" ];then
			status_tool_write_probe_json "${cfg_file}" "${comma}" "foreign4" "${FRN_TEST_SITE}" "ipv4" "direct" "" 1 2 "${STATUS_TOOL_TIMEOUT_MS}"
			comma=","
			status_tool_write_probe_json "${cfg_file}" "${comma}" "foreign6" "${FRN_TEST_SITE}" "ipv6" "direct" "" 1 2 "${STATUS_TOOL_TIMEOUT_MS}"
			probe_count=$((probe_count + 2))
		fi
	else
		if [ -n "${SOCKS5_OPEN}" -a -n "${REDIRC_OPEN}" ];then
			foreign_mode="socks5"
			foreign_proxy="socks5://127.0.0.1:23456"
			status_tool_write_probe_json "${cfg_file}" "${comma}" "foreign4" "${FRN_TEST_SITE}" "ipv4" "${foreign_mode}" "${foreign_proxy}" 1 2 "${STATUS_TOOL_TIMEOUT_MS}"
			probe_count=$((probe_count + 1))
		fi
	fi

	cat >>"${cfg_file}" <<-EOF
	  ]
	}
	EOF

	[ "${probe_count}" -gt 0 ] || {
		status_tool_cleanup_tmp "${cfg_file}" "${out_file}"
		return 1
	}
	"${status_tool}" once --config "${cfg_file}" --format json > "${out_file}" 2>/dev/null || {
		status_tool_cleanup_tmp "${cfg_file}" "${out_file}"
		return 1
	}

	china_result=$(status_tool_get_legacy_result "${out_file}" "china")
	[ -n "${china_result}" ] || china_result="0|000||StatusTool"
	get_china_status "${request_tag}" "${china_result}"

	if [ "${PROXY_IPV6}" = "1" ];then
		foreign4_result=$(status_tool_get_legacy_result "${out_file}" "foreign4")
		foreign6_result=$(status_tool_get_legacy_result "${out_file}" "foreign6")
		[ -n "${foreign4_result}" ] || foreign4_result="__UNAVAILABLE__"
		[ -n "${foreign6_result}" ] || foreign6_result="__UNAVAILABLE__"
		get_foreign_status_by_family "4" "国外IPv4" "log1" "1" "${request_tag}" "${foreign4_result}"
		get_foreign_status_by_family "6" "国外IPv6" "log3" "0" "${request_tag}" "${foreign6_result}"
	else
		foreign4_result=$(status_tool_get_legacy_result "${out_file}" "foreign4")
		[ -n "${foreign4_result}" ] || foreign4_result="__UNAVAILABLE__"
		get_foreign_status_by_family "4" "国外链接" "log1" "1" "${request_tag}" "${foreign4_result}"
	fi

	status_tool_cleanup_tmp "${cfg_file}" "${out_file}"
	return 0
}

acquire_status_ws_lock(){
	mkdir "${STATUS_WS_LOCK_DIR}" >/dev/null 2>&1
}

release_status_ws_lock(){
	rmdir "${STATUS_WS_LOCK_DIR}" >/dev/null 2>&1
}

read_status_ws_cache(){
	[ -s "${STATUS_WS_CACHE_FILE}" ] || return 1
	cat "${STATUS_WS_CACHE_FILE}" 2>/dev/null
}

write_status_ws_cache(){
	local payload="$1"
	[ -n "${payload}" ] || return 1
	printf '%s' "${payload}" > "${STATUS_WS_CACHE_FILE}" 2>/dev/null
}

cleanup_status_probes(){
	[ -n "${STATUS_PROBE_DIR}" ] && rm -rf "${STATUS_PROBE_DIR}" >/dev/null 2>&1
}

get_foreign_probe_mode(){
	if [ "${PROXY_IPV6}" == "1" ];then
		echo "direct"
	else
		echo "socks5"
	fi
}

set_waiting_status(){
	if [ "${PROXY_IPV6}" == "1" ];then
		log1="国外IPv4 【${LOGTIME}】：等待..."
		log3="国外IPv6 【${LOGTIME}】：等待..."
	else
		log1="国外链接 【${LOGTIME}】：等待..."
		log3=""
	fi
	log2="国内链接 【${LOGTIME}】：等待..."
}

get_status_payload(){
	if [ "${PROXY_IPV6}" == "1" ];then
		echo "${log1}@@${log3}@@${log2}"
	else
		echo "${log1}@@${log2}"
	fi
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

prepare_status_probes(){
	STATUS_PROBE_DIR="/tmp/ss_status.$$"
	rm -rf "${STATUS_PROBE_DIR}" >/dev/null 2>&1
	mkdir -p "${STATUS_PROBE_DIR}"
	CHINA_PROBE_FILE="${STATUS_PROBE_DIR}/china"
	FOREIGN4_PROBE_FILE="${STATUS_PROBE_DIR}/foreign4"
	FOREIGN6_PROBE_FILE="${STATUS_PROBE_DIR}/foreign6"
}

status_history_file(){
	printf '%s/%s.ms\n' "${STATUS_HISTORY_DIR}" "$1"
}

read_status_history_ms(){
	local history_file="$(status_history_file "$1")"
	[ -f "${history_file}" ] || return 0
	cat "${history_file}" 2>/dev/null
}

write_status_history_ms(){
	local key="$1"
	local ms="$2"
	[ -n "${key}" ] || return 0
	[ -n "${ms}" ] || return 0
	echo "${ms}" | grep -Eq '^[0-9]+$' || return 0
	mkdir -p "${STATUS_HISTORY_DIR}" >/dev/null 2>&1
	echo "${ms}" >"$(status_history_file "${key}")"
}

status_escape_curl_cfg_value(){
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

status_code_ok(){
	case "$1" in
	200|204|301|302)
		return 0
		;;
	esac
	return 1
}

status_probe_needs_retry(){
	local current_ms="$1"
	local prev_ms="$2"
	local limit_a=""
	local limit_b=""
	local limit=""

	[ -n "${current_ms}" ] || return 0
	[ -n "${prev_ms}" ] || return 0
	echo "${current_ms}" | grep -Eq '^[0-9]+$' || return 0
	echo "${prev_ms}" | grep -Eq '^[0-9]+$' || return 0
	limit_a=$((prev_ms + 100))
	limit_b=$((prev_ms * 3 / 2))
	limit="${limit_a}"
	[ "${limit_b}" -gt "${limit}" ] && limit="${limit_b}"
	[ "${current_ms}" -gt "${limit}" ]
}

status_write_transfer_cfg(){
	local cfg_file="$1"
	local tag="$2"
	local url="$3"
	local family="$4"
	local timeout_sec="$5"
	local proxy_uri="$6"
	local esc_url=""
	local esc_proxy=""

	esc_url=$(status_escape_curl_cfg_value "${url}")
	cat >>"${cfg_file}" <<-EOF
		silent
		insecure
		head
		output = "/dev/null"
		connect-timeout = "${timeout_sec}"
		max-time = "${timeout_sec}"
		url = "${esc_url}"
		write-out = "${tag}|%{exitcode}|%{response_code}|%{time_total}|%{remote_ip}\\n"
	EOF
	[ "${family}" = "4" ] && echo "ipv4" >>"${cfg_file}"
	[ "${family}" = "6" ] && echo "ipv6" >>"${cfg_file}"
	if [ -n "${proxy_uri}" ];then
		esc_proxy=$(status_escape_curl_cfg_value "${proxy_uri}")
		echo "proxy = \"${esc_proxy}\"" >>"${cfg_file}"
	fi
}

status_run_series(){
	local cfg_file="$1"
	local out_file="$2"
	: >"${out_file}"
	run /tmp/curl-status -q -K "${cfg_file}" >"${out_file}" 2>/dev/null
}

status_get_series_field(){
	local out_file="$1"
	local tag="$2"
	local col="$3"
	[ -f "${out_file}" ] || return 1
	awk -F '|' -v t="${tag}" -v c="${col}" '
		$1 == t {
			print $c
			exit
		}
	' "${out_file}" 2>/dev/null
}

status_get_series_line(){
	local out_file="$1"
	local tag="$2"
	[ -f "${out_file}" ] || return 1
	awk -F '|' -v t="${tag}" '
		$1 == t {
			print
			exit
		}
	' "${out_file}" 2>/dev/null
}

status_series_timeout(){
	local out_file="$1"
	local tag="$2"
	local exitcode=""
	exitcode=$(status_get_series_field "${out_file}" "${tag}" 2)
	[ "${exitcode}" = "28" ]
}

status_series_ms(){
	local out_file="$1"
	local tag="$2"
	local exitcode=""
	local resp_code=""
	local ms=""

	exitcode=$(status_get_series_field "${out_file}" "${tag}" 2)
	resp_code=$(status_get_series_field "${out_file}" "${tag}" 3)
	[ "${exitcode}" = "0" ] || return 1
	status_code_ok "${resp_code}" || return 1
	ms=$(awk -F '|' -v t="${tag}" '
		$1 == t {
			printf "%.0f", $4 * 1000
			exit
		}
	' "${out_file}" 2>/dev/null)
	[ -n "${ms}" ] || return 1
	echo "${ms}"
}

status_pick_better_tag(){
	local out_file="$1"
	local lhs_tag="$2"
	local rhs_tag="$3"
	local lhs_ms=""
	local rhs_ms=""

	lhs_ms=$(status_series_ms "${out_file}" "${lhs_tag}")
	rhs_ms=$(status_series_ms "${out_file}" "${rhs_tag}")
	if [ -z "${lhs_ms}" ];then
		printf '%s\n' "${rhs_tag}"
		return 0
	fi
	if [ -z "${rhs_ms}" ];then
		printf '%s\n' "${lhs_tag}"
		return 0
	fi
	if [ "${lhs_ms}" -le "${rhs_ms}" ];then
		printf '%s\n' "${lhs_tag}"
	else
		printf '%s\n' "${rhs_tag}"
	fi
}

status_line_to_legacy(){
	printf '%s' "$1" | awk -F '|' '{print $4 "|" $3 "|" $5 "|" $2}'
}

status_get_probe_mode_short(){
	case "$(get_foreign_probe_mode)" in
	direct)
		echo "d"
		;;
	socks5|*)
		echo "s5"
		;;
	esac
}

status_get_bin_short(){
	[ -n "$1" ] && {
		printf '%s' "$1"
		return 0
	}
	echo "0"
}

status_build_foreign_fail_diag(){
	local ret_exit="$1"
	local mode="$(status_get_probe_mode_short)"
	local socks_bin="$(status_get_bin_short "${SOCKS5_OPEN}")"
	local redir_bin="$(status_get_bin_short "${REDIRC_OPEN}")"
	local up_addr="${CURRENT_SERVER_ADDR}"

	[ -n "${ret_exit}" ] || ret_exit="na"
	[ -n "${up_addr}" ] || up_addr="-"
	[ -n "${CURRENT_SERVER_PORT}" ] && up_addr="${up_addr}:${CURRENT_SERVER_PORT}"
	printf ' 🔎 e=%s m=%s s5=%s rd=%s up=%s' "${ret_exit}" "${mode}" "${socks_bin}" "${redir_bin}" "${up_addr}"
}

launch_probe(){
	local key="$1"
	local outfile="$2"
	local url="$3"
	local family="$4"
	local proxy_uri="$5"
	(
		local probe_dir="${STATUS_PROBE_DIR}/${key}_dir"
		local series_cfg="${probe_dir}/series.cfg"
		local series_out="${probe_dir}/series.out"
		local retry_cfg="${probe_dir}/retry.cfg"
		local retry_out="${probe_dir}/retry.out"
		local history_ms=""
		local best_tag="score1"
		local best_ms=""
		local score2_ms=""
		local fallback_tag="score1"
		local inline_score2=0

		rm -rf "${probe_dir}" >/dev/null 2>&1
		mkdir -p "${probe_dir}"
		history_ms=$(read_status_history_ms "${key}")
		[ -z "${history_ms}" ] && inline_score2=1

		: >"${series_cfg}"
		status_write_transfer_cfg "${series_cfg}" "warm" "${url}" "${family}" 3 "${proxy_uri}"
		echo "next" >>"${series_cfg}"
		status_write_transfer_cfg "${series_cfg}" "score1" "${url}" "${family}" 3 "${proxy_uri}"
		if [ "${inline_score2}" = "1" ];then
			echo "next" >>"${series_cfg}"
			status_write_transfer_cfg "${series_cfg}" "score2" "${url}" "${family}" 3 "${proxy_uri}"
			fallback_tag="score2"
		fi
		status_run_series "${series_cfg}" "${series_out}"

		best_ms=$(status_series_ms "${series_out}" "score1")
		if [ "${inline_score2}" = "1" ];then
			best_tag=$(status_pick_better_tag "${series_out}" "score1" "score2")
			best_ms=$(status_series_ms "${series_out}" "${best_tag}")
		elif status_probe_needs_retry "${best_ms}" "${history_ms}";then
			: >"${retry_cfg}"
			status_write_transfer_cfg "${retry_cfg}" "score2" "${url}" "${family}" 3 "${proxy_uri}"
			status_run_series "${retry_cfg}" "${retry_out}"
			score2_ms=$(status_series_ms "${retry_out}" "score2")
			if [ -n "${score2_ms}" ] && { [ -z "${best_ms}" ] || [ "${score2_ms}" -lt "${best_ms}" ]; };then
				best_tag="score2"
				best_ms="${score2_ms}"
			else
				best_tag="score1"
			fi
			fallback_tag="score2"
		fi

		if [ -n "${best_ms}" ];then
			write_status_history_ms "${key}" "${best_ms}"
			if [ "${best_tag}" = "score2" -a -f "${retry_out}" ];then
				status_line_to_legacy "$(status_get_series_line "${retry_out}" "score2")" >"${outfile}"
			else
				status_line_to_legacy "$(status_get_series_line "${series_out}" "${best_tag}")" >"${outfile}"
			fi
		else
			if [ "${fallback_tag}" = "score2" -a -f "${retry_out}" ] && [ -n "$(status_get_series_line "${retry_out}" "score2")" ];then
				status_line_to_legacy "$(status_get_series_line "${retry_out}" "score2")" >"${outfile}"
			elif [ "${fallback_tag}" = "score2" ] && [ -n "$(status_get_series_line "${series_out}" "score2")" ];then
				status_line_to_legacy "$(status_get_series_line "${series_out}" "score2")" >"${outfile}"
			elif [ -n "$(status_get_series_line "${series_out}" "score1")" ];then
				status_line_to_legacy "$(status_get_series_line "${series_out}" "score1")" >"${outfile}"
			else
				echo "0|000|" >"${outfile}"
			fi
		fi
	) &
	echo $!
}

mark_probe_unavailable(){
	echo "__UNAVAILABLE__" >"$1"
}

start_status_probes(){
	prepare_status_probes
	CHINA_PROBE_PID=$(launch_probe "china" "${CHINA_PROBE_FILE}" "${CHN_TEST_SITE}" "4" "")

	if [ "${PROXY_IPV6}" == "1" ];then
		if [ -n "${REDIRC_OPEN}" ];then
			FOREIGN4_PROBE_PID=$(launch_probe "foreign4" "${FOREIGN4_PROBE_FILE}" "${FRN_TEST_SITE}" "4" "")
			FOREIGN6_PROBE_PID=$(launch_probe "foreign6" "${FOREIGN6_PROBE_FILE}" "${FRN_TEST_SITE}" "6" "")
		else
			mark_probe_unavailable "${FOREIGN4_PROBE_FILE}"
			mark_probe_unavailable "${FOREIGN6_PROBE_FILE}"
		fi
	else
		if [ -n "${SOCKS5_OPEN}" -a -n "${REDIRC_OPEN}" ];then
			FOREIGN4_PROBE_PID=$(launch_probe "foreign4" "${FOREIGN4_PROBE_FILE}" "${FRN_TEST_SITE}" "4" "socks5://127.0.0.1:23456")
		else
			mark_probe_unavailable "${FOREIGN4_PROBE_FILE}"
		fi
	fi
}

wait_status_probes(){
	[ -n "${CHINA_PROBE_PID}" ] && wait "${CHINA_PROBE_PID}" >/dev/null 2>&1
	[ -n "${FOREIGN4_PROBE_PID}" ] && wait "${FOREIGN4_PROBE_PID}" >/dev/null 2>&1
	[ -n "${FOREIGN6_PROBE_PID}" ] && wait "${FOREIGN6_PROBE_PID}" >/dev/null 2>&1
}

read_probe_result(){
	[ -f "$1" ] && cat "$1"
}

get_china_status(){
	local ret0="$2"
	[ -z "${ret0}" ] && ret0=$(read_probe_result "${CHINA_PROBE_FILE}")
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')

	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK 🧮$1"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found 🧮$1"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed 🧮$1"
	fi
	[ "${ss_failover_enable}" == "1" ] && echo ${ret1} >> ${LOGFILE_C}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		log2='国内链接 【'${LOGTIME}'】 ✓&nbsp;&nbsp;'${ret_time_ext}''
	else
		log2='国内链接 【'${LOGTIME}'】 <font color='#FF0000'>X</font>'
	fi
}

get_foreign_status_by_family(){
	local family="$1"
	local label="$2"
	local log_var="$3"
	local write_history="$4"
	local request_tag="$5"
	local ret0="$6"
	local probe_file="${FOREIGN4_PROBE_FILE}"
	[ "${family}" == "6" ] && probe_file="${FOREIGN6_PROBE_FILE}"
	[ -z "${ret0}" ] && ret0=$(read_probe_result "${probe_file}")

	if [ "${ret0}" == "__UNAVAILABLE__" ];then
		eval ${log_var}="'${label} 【${LOGTIME}】 <font color=\"#FF0000\">X</font>'"
		local ret1="${LOGTIME1} ➡️ $(get_domain_name ${FRN_TEST_SITE}) ⏱ --- ms 🌎 001 failed ✈️ ${CURRENT_NAME}$(status_build_foreign_fail_diag "na") 🧮${request_tag}"
		[ "${ss_failover_enable}" == "1" -a "${write_history}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}
		return 0
	fi
	
	local ret_time=$(echo $ret0 | awk -F "|" '{printf "%.2f\n", $1 * 1000}')
	local ret_code=$(echo $ret0 | awk -F "|" '{print $2}')
	local ret_addr=$(echo $ret0 | awk -F "|" '{print $3}')
	local ret_exit=$(echo $ret0 | awk -F "|" '{print $4}')
	if [ "${ret_addr}" == "127.0.0.1" ];then
		local ret_addr=$(get_domain_name ${FRN_TEST_SITE})
	fi
	
	# write test result to file
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ ${ret_time} ms 🌎 ${ret_code} OK ✈️ ${CURRENT_NAME} 🧮${request_tag}"
	elif [ "${ret_code}" == "404" ];then
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} Not Found ✈️ ${CURRENT_NAME} 🧮${request_tag}"
	else
		local ret1="${LOGTIME1} ➡️ ${ret_addr} ⏱ --- ms 🌎 ${ret_code} failed ✈️ ${CURRENT_NAME}$(status_build_foreign_fail_diag "${ret_exit}") 🧮${request_tag}"
	fi
	[ "${ss_failover_enable}" == "1" -a "${write_history}" == "1" ] && echo ${ret1} >> ${LOGFILE_F}

	# tell test result to web status check
	if [ "${ret_code}" == "200" -o "${ret_code}" == "204" -o "${ret_code}" == "301" -o "${ret_code}" == "302" ];then
		local ret_time_ext=$(echo $ret0 | awk -F "|" '{printf "%.0f ms\n", $1 * 1000}')
		eval ${log_var}="'${label} 【${LOGTIME}】 ✓&nbsp;&nbsp;${ret_time_ext}'"
	else
		eval ${log_var}="'${label} 【${LOGTIME}】 <font color=\"#FF0000\">X</font>'"
	fi
}

get_foreign_status(){
	if [ "${PROXY_IPV6}" == "1" ];then
		get_foreign_status_by_family "4" "国外IPv4" "log1" "1" "$1" "$(read_probe_result "${FOREIGN4_PROBE_FILE}")"
		get_foreign_status_by_family "6" "国外IPv6" "log3" "0" "$1" "$(read_probe_result "${FOREIGN6_PROBE_FILE}")"
	else
		get_foreign_status_by_family "4" "国外链接" "log1" "1" "$1" "$(read_probe_result "${FOREIGN4_PROBE_FILE}")"
	fi
}

prepare(){
	# 1. exit when fancyss not enabled
	local fancyss_enable=$(dbus get ss_basic_enable)
	if [ "${fancyss_enable}" != "1" ];then
		set_waiting_status
		exit
	fi
	
	# 2. exit when ssconfig.sh is running
	local _ssconfig=$(ps | grep "ssconfig.sh" | grep -v grep)
	if [ -n "${_ssconfig}" ];then
		set_waiting_status
		exit
	fi

	if [ ! -L "/tmp/curl-status" ];then
		ln -sf /koolshare/bin/curl-fancyss /tmp/curl-status
	fi
	
	# # 3. kill all other ss_status.sh process if exist
	# local current_pid=$$
	# local ss_status_pids=$(ps | grep -E "ss_status\.sh" | awk '{print $1}'| grep -v ${current_pid})
	# if [ -n "${ss_status_pids}" ];then
	# 	for ss_status_pid in ${ss_status_pids}
	# 	do
	# 		kill -9 ${ss_status_pid} >/dev/null 2>&1
	# 	done
	# fi

	# # 4. killall curl-status
	# killall curl-status
	# local fancyss_pids=$(ps | grep "curl-status" | grep -v "grep" | grep -E "${CHN_TEST_SITE}|${FRN_TEST_SITE}" | awk '{print $1}')
	# if [ -n "${fancyss_pids}" ];then
	# 	for fancyss_pid in ${fancyss_pids}
	# 	do
	# 		kill -9 ${fancyss_pid} >/dev/null 2>&1
	# 	done
	# fi
}

if [ -z "$1" -a -z "$2" ];then
	prepare
	if status_tool_bin="$(pick_status_tool)"; then
		if ! status_tool_probe_all "${status_tool_bin}" "$1"; then
			start_status_probes
			wait_status_probes
			get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
			get_foreign_status $1
			cleanup_status_probes
		fi
	else
		start_status_probes
		wait_status_probes
		get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
		get_foreign_status $1
		cleanup_status_probes
	fi
	echo "$(get_status_payload)"
	exit
fi

case $1 in
	ws)
		if [ "$(dbus get ss_basic_wait)" == "1" ];then
			set_waiting_status
		else
			if ! acquire_status_ws_lock; then
				if cached_payload="$(read_status_ws_cache)"; then
					echo "${cached_payload}"
				else
					set_waiting_status
					echo "$(get_status_payload)"
				fi
				exit 0
			fi
			trap 'release_status_ws_lock' EXIT INT TERM
			prepare
			if status_tool_bin="$(pick_status_tool)"; then
				if ! status_tool_probe_all "${status_tool_bin}" "$1"; then
					start_status_probes
					wait_status_probes
					get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
					get_foreign_status $1
					cleanup_status_probes
				fi
			else
				start_status_probes
				wait_status_probes
				get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
				get_foreign_status $1
				cleanup_status_probes
			fi
		fi
		payload="$(get_status_payload)"
		write_status_ws_cache "${payload}" >/dev/null 2>&1
		echo "${payload}"
	;;
	*)
		if [ "${ss_failover_enable}" == "1" ];then
			prepare
			if status_tool_bin="$(pick_status_tool)"; then
				if ! status_tool_probe_all "${status_tool_bin}" "$1"; then
					start_status_probes
					wait_status_probes
					get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
					get_foreign_status $1
					cleanup_status_probes
				fi
			else
				start_status_probes
				wait_status_probes
				get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
				get_foreign_status $1
				cleanup_status_probes
			fi
			echo -e -n  "$(get_status_payload)@@${HEART_STATUS}\n" >/tmp/upload/ss_status.txt
		else
			if [ "$(dbus get ss_basic_wait)" == "1" ];then
				set_waiting_status
			else
				prepare
				if status_tool_bin="$(pick_status_tool)"; then
					if ! status_tool_probe_all "${status_tool_bin}" "$1"; then
						start_status_probes
						wait_status_probes
						get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
						get_foreign_status $1
						cleanup_status_probes
					fi
				else
					start_status_probes
					wait_status_probes
					get_china_status "$1" "$(read_probe_result "${CHINA_PROBE_FILE}")"
					get_foreign_status $1
					cleanup_status_probes
				fi
			fi
			http_response "$(get_status_payload)"
		fi
	;;
esac
