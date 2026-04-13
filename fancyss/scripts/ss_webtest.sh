#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
source /koolshare/scripts/ss_webtest_gen.sh
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
TMP2=/tmp/fancyss_webtest
WT_WEBTEST_FILE=/tmp/upload/webtest.txt
WT_WEBTEST_STREAM=/tmp/upload/webtest.stream
WT_WEBTEST_BACKUP=/tmp/upload/webtest_bakcup.txt
WT_WEBTEST_STOP_FLAG=/tmp/webtest.stop
WT_WEBTEST_PID_FILE=/tmp/webtest.pid
WT_WEBTEST_STATE_LOCK=/tmp/webtest.state.lock
WT_SERVER_RESOLV_MODE="1"
WT_NODE_CACHE_DIR=""
WT_NODE_ACTIVE_ID=""
WT_NODE_ACTIVE_JSON=""
WT_PREVIEW_READY=0
WT_GROUP_ORDER_PREPARED=0
WT_GROUP_CURRENT_TAG=""
WT_GROUP_CURRENT_FILE=""
WT_GROUP_PREVIEW_FILE=""
WT_WEBTEST_STATE_FILE=""
WT_BATCH_ACTIVE=0
WT_BATCH_FINALIZED=0
WT_BATCH_ABORT_REASON=""
WT_WEBTEST_CACHE_REV="1"
WT_WEBTEST_CACHE_GEN_REV="20260409_1"
WT_WEBTEST_CACHE_LOCK="/tmp/fss_webtest_cache.lock"
WT_WEBTEST_CACHE_STATE_DIR="/tmp/fancyss_cache_state"
WT_WEBTEST_CACHE_STATE_FILE="${WT_WEBTEST_CACHE_STATE_DIR}/webtest.state"
WT_MEM_TIER_MID_MB="768"
WT_MEM_TIER_HIGH_MB="1536"
WT_PERF_READY="0"
LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
WT_CAN_HTTP_RESPONSE=0

wt_http_response() {
	[ "${WT_CAN_HTTP_RESPONSE}" = "1" ] || return 0
	http_response "$@" >/dev/null 2>&1
}

wt_cache_log() {
	[ "${WT_CACHE_LOGGING}" = "1" ] || return 0
	echo_date "$@"
}

wt_cache_state_count_ids() {
	local ids_file="$1"
	local count="0"

	[ -f "${ids_file}" ] || {
		printf '%s' "0"
		return 0
	}
	count=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${count}" ] || count="0"
	printf '%s' "${count}"
}

wt_cache_state_write() {
	local status="$1"
	local phase="$2"
	local reason="$3"
	local ids_file="$4"
	local message="$5"
	local target_count=""

	mkdir -p "${WT_WEBTEST_CACHE_STATE_DIR}" >/dev/null 2>&1 || return 1
	target_count="$(wt_cache_state_count_ids "${ids_file}")"
	cat > "${WT_WEBTEST_CACHE_STATE_FILE}.tmp.$$" <<-EOF
		status=${status}
		phase=${phase}
		reason=${reason}
		pid=$$
		target_count=${target_count}
		message=${message}
		updated_at=$(date +%s)
	EOF
	mv -f "${WT_WEBTEST_CACHE_STATE_FILE}.tmp.$$" "${WT_WEBTEST_CACHE_STATE_FILE}"
}

wt_cache_state_get() {
	local key="$1"

	[ -n "${key}" ] || return 1
	[ -f "${WT_WEBTEST_CACHE_STATE_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${WT_WEBTEST_CACHE_STATE_FILE}" | sed -n '1p'
}

wt_cache_state_begin() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	wt_cache_state_write "building" "init" "${reason}" "${ids_file}" "${message}"
}

wt_cache_state_phase() {
	local phase="$1"
	local reason="$2"
	local ids_file="$3"
	local message="$4"
	wt_cache_state_write "building" "${phase}" "${reason}" "${ids_file}" "${message}"
}

wt_cache_state_ready() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	wt_cache_state_write "ready" "done" "${reason}" "${ids_file}" "${message}"
}

wt_cache_state_failed() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	wt_cache_state_write "failed" "failed" "${reason}" "${ids_file}" "${message}"
}

wt_cache_state_is_building() {
	[ "$(wt_cache_state_get "status")" = "building" ]
}

wt_pick_node_tool() {
	if command -v node-tool >/dev/null 2>&1; then
		if "$(command -v node-tool)" version >/dev/null 2>&1; then
			command -v node-tool
			return 0
		fi
	fi
	if [ -x "/koolshare/bin/node-tool" ];then
		if /koolshare/bin/node-tool version >/dev/null 2>&1; then
			echo "/koolshare/bin/node-tool"
			return 0
		fi
	fi
	return 1
}

wt_try_node_tool_webtest_cache() {
	local ids_file="$1"
	local node_tool=""

	[ -f "${ids_file}" ] || return 1
	node_tool="$(wt_pick_node_tool 2>/dev/null)" || return 1
	"${node_tool}" warm-cache --webtest --ids-file "${ids_file}" >/dev/null 2>&1 || return 1
	wt_cache_log "ℹ️通过node-tool构建/复用webtest节点配置缓存。"
	wt_log_node_tool_webtest_summary
	return 0
}

wt_try_node_tool_webtest_cache_all() {
	local node_tool=""

	node_tool="$(wt_pick_node_tool 2>/dev/null)" || return 1
	"${node_tool}" warm-cache --webtest >/dev/null 2>&1 || return 1
	wt_cache_log "ℹ️通过node-tool构建/复用webtest节点配置缓存。"
	wt_log_node_tool_webtest_summary
	return 0
}

wt_try_node_tool_webtest_groups() {
	local node_tool=""

	node_tool="$(wt_pick_node_tool 2>/dev/null)" || return 1
	"${node_tool}" webtest-groups --output-dir "${TMP2}" >/dev/null 2>&1 || return 1
	wt_cache_log "ℹ️通过node-tool生成webtest分组清单。"
	return 0
}

wt_get_webtest_cache_xray_count() {
	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 1
	sed -n 's/^xray_count=//p' "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" | sed -n '1p'
}

wt_log_node_tool_webtest_summary() {
	local native=""
	local shell=""
	local missing=""
	local other=""
	local reasons=""

	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 0
	native="$(wt_webtest_cache_global_meta_get "builder_native")"
	shell="$(wt_webtest_cache_global_meta_get "builder_shell")"
	missing="$(wt_webtest_cache_global_meta_get "builder_missing")"
	other="$(wt_webtest_cache_global_meta_get "builder_other")"
	reasons="$(wt_webtest_cache_global_meta_get "builder_shell_reasons")"
	[ -n "${native}${shell}${missing}${other}${reasons}" ] || return 0
	[ -n "${native}" ] || native="0"
	[ -n "${shell}" ] || shell="0"
	[ -n "${missing}" ] || missing="0"
	[ -n "${other}" ] || other="0"
	wt_cache_log "ℹ️node-tool构建摘要：native ${native}，shell ${shell}，missing ${missing}，other ${other}。"
	[ "${shell}" = "0" ] || [ -z "${reasons}" ] || wt_cache_log "ℹ️shell回退原因：${reasons}"
}

wt_try_node_tool_json_cache() {
	local node_tool=""

	node_tool="$(wt_pick_node_tool 2>/dev/null)" || return 1
	"${node_tool}" warm-cache --json >/dev/null 2>&1 || return 1
	wt_cache_log "ℹ️通过node-tool构建/复用节点JSON缓存。"
	return 0
}

wt_try_node_tool_env_cache() {
	return 1
}

wt_pick_webtest_tool() {
	if command -v webtest-tool >/dev/null 2>&1; then
		command -v webtest-tool
		return 0
	fi
	if [ -x "/koolshare/bin/webtest-tool" ]; then
		echo "/koolshare/bin/webtest-tool"
		return 0
	fi
	return 1
}

wt_pick_webtestctl() {
	if command -v webtestctl >/dev/null 2>&1; then
		command -v webtestctl
		return 0
	fi
	if [ -x "/koolshare/bin/webtestctl" ]; then
		echo "/koolshare/bin/webtestctl"
		return 0
	fi
	return 1
}

wt_pick_statusctl() {
	if command -v statusctl >/dev/null 2>&1; then
		command -v statusctl
		return 0
	fi
	if [ -x "/koolshare/bin/statusctl" ]; then
		echo "/koolshare/bin/statusctl"
		return 0
	fi
	return 1
}

wt_pick_jq() {
	if command -v jq >/dev/null 2>&1; then
		command -v jq
		return 0
	fi
	if [ -x "/koolshare/bin/jq" ]; then
		echo "/koolshare/bin/jq"
		return 0
	fi
	return 1
}

wt_webtest_tool_build_job() {
	local pairs_file="$1"
	local job_file="$2"
	local output_json="$3"
	local output_stream="$4"
	local concurrency="$5"
	local batch_tag="$6"
	local live_result_file="$7"
	local live_stream_file="$8"
	local jq_bin=""
	local effective_concurrency="1"
	local group_label=""
	local first=1
	local node_id=""
	local test_port=""
	local meta_file=""
	local start_script=""
	local stop_script=""
	local wait_port=""
	local has_start=""
	local wait_timeout_ms="5000"

	jq_bin="$(wt_pick_jq 2>/dev/null)" || return 1
	[ -f "${pairs_file}" ] || return 1
	[ -n "${concurrency}" ] || concurrency="1"
	effective_concurrency="${concurrency}"
	group_label="$(wt_webtest_group_label "${batch_tag}")"

	{
		printf '[\n'
		while IFS='|' read -r node_id test_port
		do
			[ -n "${node_id}" ] || continue
			[ -n "${test_port}" ] || continue
			meta_file="${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta"
			start_script=""
			stop_script=""
			wait_port=""
			has_start=""
			if [ -f "${meta_file}" ]; then
				has_start=$(sed -n 's/^has_start=//p' "${meta_file}" | sed -n '1p')
				wait_port=$(sed -n 's/^start_port=//p' "${meta_file}" | sed -n '1p')
			fi
			if [ "${has_start}" = "1" ] && [ -x "${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_start.sh" ]; then
				start_script="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_start.sh"
				[ -x "${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_stop.sh" ] && stop_script="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_stop.sh"
			fi
			[ "${first}" = "1" ] || printf ',\n'
			first=0
			printf '{"id":"%s","identity":"%s","test_port":%s' "${node_id}" "${node_id}" "${test_port}"
			if [ -n "${start_script}" ]; then
				printf ',"start_script":"%s"' "${start_script}"
			fi
			if [ -n "${stop_script}" ]; then
				printf ',"stop_script":"%s"' "${stop_script}"
			fi
			if [ -n "${wait_port}" ]; then
				printf ',"wait_port":%s,"wait_timeout_ms":%s' "${wait_port}" "${wait_timeout_ms}"
			fi
			printf '}'
		done < "${pairs_file}"
		printf '\n]\n'
	} > "${job_file}.targets.tmp.$$" || return 1

	cat > "${job_file}.tmp.$$" <<-EOF
		{
		  "batch_id": "${batch_tag}_$(date +%s)",
		  "url": "${ss_basic_furl}",
		  "timeout_ms": 3000,
		  "warmup": 1,
		  "attempts": 2,
		  "concurrency": ${effective_concurrency},
		  "output_json": "${output_json}",
		  "output_stream": "${output_stream}",
		  "legacy_result_file": "${live_result_file}",
		  "legacy_stream_file": "${live_stream_file}",
		  "legacy_emit_stop": false,
		  "runtime_root": "${TMP2}",
		  "groups": [
		    {
		      "name": "${group_label}",
		      "concurrency": ${effective_concurrency},
		      "targets": $(cat "${job_file}.targets.tmp.$$")
		    }
		  ]
		}
	EOF
	rm -f "${job_file}.targets.tmp.$$"
	mv -f "${job_file}.tmp.$$" "${job_file}"
	"${jq_bin}" . "${job_file}" >/dev/null 2>&1 || return 1
	return 0
}

wt_webtest_tool_import_results() {
	local output_json="$1"
	local jq_bin=""
	local parsed_file="${TMP2}/webtest_tool_import.$$.txt"
	local line=""
	local nu=""

	jq_bin="$(wt_pick_jq 2>/dev/null)" || return 1
	[ -f "${output_json}" ] || return 1
	"${jq_bin}" -r '
		(.results // [])[] |
		if .state == "ok" and (.latency_ms != null) then
			"\(.id)>\(.latency_ms)"
		elif .state == "timeout" then
			"\(.id)>timeout"
		elif .state == "stopped" then
			"\(.id)>stopped"
		else
			"\(.id)>failed"
		end
	' "${output_json}" 2>/dev/null > "${parsed_file}" || {
		rm -f "${parsed_file}"
		return 1
	}
	while IFS= read -r line
	do
		nu="${line%%>*}"
		[ -n "${nu}" ] || continue
		printf '%s\n' "${line}" > "${TMP2}/results/${nu}.txt"
		wt_append_webtest_file "${TMP2}/results/${nu}.txt"
	done < "${parsed_file}"
	rm -f "${parsed_file}"
	return 0
}

wt_wait_pid_with_timeout() {
	local pid="$1"
	local timeout_secs="$2"
	local elapsed=0

	[ -n "${pid}" ] || return 1
	[ -n "${timeout_secs}" ] || timeout_secs=30
	while kill -0 "${pid}" >/dev/null 2>&1
	do
		[ "${elapsed}" -ge "${timeout_secs}" ] && return 1
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 0
}

wt_calc_batch_timeout_secs() {
	local target_count="$1"
	local concurrency="$2"
	local wait_timeout_ms="$3"
	local probe_timeout_ms="$4"
	local warmup="$5"
	local attempts="$6"
	local wave_count=1
	local per_target_secs=0
	local total_secs=0

	printf '%s' "${target_count}" | grep -Eq '^[0-9]+$' || target_count=1
	printf '%s' "${concurrency}" | grep -Eq '^[0-9]+$' || concurrency=1
	printf '%s' "${wait_timeout_ms}" | grep -Eq '^[0-9]+$' || wait_timeout_ms=0
	printf '%s' "${probe_timeout_ms}" | grep -Eq '^[0-9]+$' || probe_timeout_ms=3000
	printf '%s' "${warmup}" | grep -Eq '^[0-9]+$' || warmup=1
	printf '%s' "${attempts}" | grep -Eq '^[0-9]+$' || attempts=2
	[ "${target_count}" -gt 0 ] || target_count=1
	[ "${concurrency}" -gt 0 ] || concurrency=1

	wave_count=$(((target_count + concurrency - 1) / concurrency))
	per_target_secs=$(((wait_timeout_ms + 999) / 1000))
	per_target_secs=$((per_target_secs + (((warmup + attempts + 1) * probe_timeout_ms + 999) / 1000) + 2))
	total_secs=$((wave_count * per_target_secs + 15))
	[ "${total_secs}" -lt 20 ] && total_secs=20
	printf '%s\n' "${total_secs}"
}

wt_try_webtest_tool_batch() {
	local pairs_file="$1"
	local batch_tag="$2"
	local output_json="${TMP2}/webtest_tool_${batch_tag}.json"
	local output_stream="${TMP2}/webtest_tool_${batch_tag}.stream.jsonl"
	local job_file="${TMP2}/webtest_tool_${batch_tag}.job.json"
	local live_result_file="${TMP2}/webtest_tool_${batch_tag}.legacy.txt"
	local live_stream_file="${TMP2}/webtest_tool_${batch_tag}.legacy.stream"
	local webtest_tool=""
	local daemon_pid=""
	local follower_pid=""
	local follower_script="${TMP2}/webtest_tool_${batch_tag}.follow.sh"
	local follower_stop="${TMP2}/webtest_tool_${batch_tag}.follow.stop"
	local target_count=0
	local timeout_secs=0

	webtest_tool="$(wt_pick_webtest_tool 2>/dev/null)" || return 1
	[ -f "${pairs_file}" ] || return 1
	target_count=$(wc -l < "${pairs_file}" | tr -d ' ')
	[ -n "${target_count}" ] || target_count=0
	rm -f "${output_json}" "${output_stream}" "${job_file}" "${live_result_file}" "${live_stream_file}" "${follower_script}" "${follower_stop}"
	: > "${live_stream_file}"
	: > "${live_result_file}"
	wt_webtest_tool_build_job "${pairs_file}" "${job_file}" "${output_json}" "${output_stream}" "${WT_XRAY_THREADS}" "${batch_tag}" "${live_result_file}" "${live_stream_file}" || return 1
	timeout_secs=$(wt_calc_batch_timeout_secs "${target_count}" "${WT_XRAY_THREADS}" 0 3000 1 2)
	cat > "${follower_script}" <<-EOF
		#!/bin/sh
		last_lines=0
		while [ ! -f "${follower_stop}" ]
		do
			[ -f "${live_stream_file}" ] || {
				sleep 1
				continue
			}
			current_lines=\$(wc -l < "${live_stream_file}" 2>/dev/null)
			[ -n "\${current_lines}" ] || current_lines=0
			if [ "\${current_lines}" -gt "\${last_lines}" ]; then
				sed -n "$((last_lines + 1)),\${current_lines}p" "${live_stream_file}" 2>/dev/null | while IFS= read -r line
				do
					[ -n "\${line}" ] || continue
					[ "\${line}" = "__FSS_WEBTEST_FOLLOWER_STOP__" ] && continue
					nu="\${line%%>*}"
					state="\${line#*>}"
					[ -n "\${nu}" ] || continue
					[ -f "${WT_WEBTEST_STATE_FILE}" ] || continue
					current=\$(awk -F '>' -v node="\${nu}" '\$1 == node { print \$2; exit }' "${WT_WEBTEST_STATE_FILE}" 2>/dev/null)
					if [ "\${current}" != "\${state}" ]; then
						tmp_state_file="${WT_WEBTEST_STATE_FILE}.tmp.\$\$"
						awk -F '>' -v node="\${nu}" -v state="\${state}" '
							BEGIN { updated = 0 }
							\$1 == node {
								print node ">" state
								updated = 1
								next
							}
							{ print }
							END {
								if (updated == 0) {
									print node ">" state
								}
							}
						' "${WT_WEBTEST_STATE_FILE}" > "\${tmp_state_file}" 2>/dev/null && mv -f "\${tmp_state_file}" "${WT_WEBTEST_STATE_FILE}"
						printf '%s\n' "\${line}" >> "${WT_WEBTEST_FILE}"
						printf '%s\n' "\${line}" >> "${WT_WEBTEST_STREAM}"
					fi
				done
				last_lines="\${current_lines}"
			fi
			sleep 1
		done
	EOF
	chmod +x "${follower_script}"
	"${follower_script}" >/dev/null 2>&1 &
	follower_pid="$!"
	"${webtest_tool}" run --config "${job_file}" >/dev/null 2>&1 &
	daemon_pid="$!"
	if ! wt_wait_pid_with_timeout "${daemon_pid}" "${timeout_secs}"; then
		kill -9 "${daemon_pid}" >/dev/null 2>&1 || true
		: > "${follower_stop}"
		printf '%s\n' "__FSS_WEBTEST_FOLLOWER_STOP__" >> "${live_stream_file}"
		sleep 1
		[ -n "${follower_pid}" ] && kill "${follower_pid}" >/dev/null 2>&1 || true
		return 1
	fi
	wait "${daemon_pid}" >/dev/null 2>&1 || true
	: > "${follower_stop}"
	printf '%s\n' "__FSS_WEBTEST_FOLLOWER_STOP__" >> "${live_stream_file}"
	sleep 1
	if [ -n "${follower_pid}" ]; then
		kill "${follower_pid}" >/dev/null 2>&1 || true
	fi
	[ -f "${output_json}" ] || return 1
	if [ "${WT_SINGLE}" = "1" ]; then
		wt_webtest_tool_import_results "${output_json}" || return 1
		rm -f "${follower_script}" "${follower_stop}"
		return 0
	fi
	wt_webtest_tool_import_results "${output_json}" || return 1
	rm -f "${follower_script}" "${follower_stop}"
	return 0
}

wt_webtest_group_label() {
	case "$1" in
	xg*) printf '%s\n' "xray-like" ;;
	nv) printf '%s\n' "naive" ;;
	tc) printf '%s\n' "tuic" ;;
	01|single) printf '%s\n' "ssr" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

wt_webtest_tool_build_targets_job() {
	local targets_file="$1"
	local job_file="$2"
	local output_json="$3"
	local output_stream="$4"
	local concurrency="$5"
	local batch_tag="$6"
	local live_result_file="$7"
	local live_stream_file="$8"
	local jq_bin=""
	local effective_concurrency="1"
	local group_label=""
	local first=1
	local node_id=""
	local test_port=""
	local start_script=""
	local stop_script=""
	local wait_port=""
	local wait_timeout_ms=""

	jq_bin="$(wt_pick_jq 2>/dev/null)" || return 1
	[ -f "${targets_file}" ] || return 1
	[ -n "${concurrency}" ] || concurrency="1"
	effective_concurrency="${concurrency}"
	group_label="$(wt_webtest_group_label "${batch_tag}")"

	{
		printf '[\n'
		while IFS='|' read -r node_id test_port start_script stop_script wait_port wait_timeout_ms
		do
			[ -n "${node_id}" ] || continue
			[ -n "${test_port}" ] || continue
			[ "${first}" = "1" ] || printf ',\n'
			first=0
			printf '{"id":"%s","identity":"%s","test_port":%s' "${node_id}" "${node_id}" "${test_port}"
			[ -n "${start_script}" ] && printf ',"start_script":"%s"' "${start_script}"
			[ -n "${stop_script}" ] && printf ',"stop_script":"%s"' "${stop_script}"
			if [ -n "${wait_port}" ]; then
				[ -n "${wait_timeout_ms}" ] || wait_timeout_ms="5000"
				printf ',"wait_port":%s,"wait_timeout_ms":%s' "${wait_port}" "${wait_timeout_ms}"
			fi
			printf '}'
		done < "${targets_file}"
		printf '\n]\n'
	} > "${job_file}.targets.tmp.$$" || return 1

	cat > "${job_file}.tmp.$$" <<-EOF
		{
		  "batch_id": "${batch_tag}_$(date +%s)",
		  "url": "${ss_basic_furl}",
		  "timeout_ms": 3000,
		  "warmup": 1,
		  "attempts": 2,
		  "concurrency": ${effective_concurrency},
		  "output_json": "${output_json}",
		  "output_stream": "${output_stream}",
		  "legacy_result_file": "${live_result_file}",
		  "legacy_stream_file": "${live_stream_file}",
		  "legacy_emit_stop": false,
		  "runtime_root": "${TMP2}",
		  "groups": [
		    {
		      "name": "${group_label}",
		      "concurrency": ${effective_concurrency},
		      "targets": $(cat "${job_file}.targets.tmp.$$")
		    }
		  ]
		}
	EOF
	rm -f "${job_file}.targets.tmp.$$"
	mv -f "${job_file}.tmp.$$" "${job_file}"
	"${jq_bin}" . "${job_file}" >/dev/null 2>&1 || return 1
	return 0
}

wt_try_webtest_tool_targets_batch() {
	local targets_file="$1"
	local batch_tag="$2"
	local concurrency="$3"
	local output_json="${TMP2}/webtest_tool_${batch_tag}.json"
	local output_stream="${TMP2}/webtest_tool_${batch_tag}.stream.jsonl"
	local job_file="${TMP2}/webtest_tool_${batch_tag}.job.json"
	local live_result_file="${TMP2}/webtest_tool_${batch_tag}.legacy.txt"
	local live_stream_file="${TMP2}/webtest_tool_${batch_tag}.legacy.stream"
	local webtest_tool=""
	local daemon_pid=""
	local follower_pid=""
	local follower_script="${TMP2}/webtest_tool_${batch_tag}.follow.sh"
	local follower_stop="${TMP2}/webtest_tool_${batch_tag}.follow.stop"
	local nodes_file="${TMP2}/webtest_tool_${batch_tag}.nodes"
	local target_count=0
	local timeout_secs=0

	webtest_tool="$(wt_pick_webtest_tool 2>/dev/null)" || return 1
	[ -f "${targets_file}" ] || return 1
	target_count=$(wc -l < "${targets_file}" | tr -d ' ')
	[ -n "${target_count}" ] || target_count=0
	rm -f "${output_json}" "${output_stream}" "${job_file}" "${live_result_file}" "${live_stream_file}" "${follower_script}" "${follower_stop}" "${nodes_file}"
	: > "${live_stream_file}"
	: > "${live_result_file}"
	wt_webtest_tool_build_targets_job "${targets_file}" "${job_file}" "${output_json}" "${output_stream}" "${concurrency}" "${batch_tag}" "${live_result_file}" "${live_stream_file}" || return 1
	timeout_secs=$(wt_calc_batch_timeout_secs "${target_count}" "${concurrency}" 5000 3000 1 2)
	awk -F '|' '{print $1}' "${targets_file}" > "${nodes_file}"
	wt_set_batch_state_from_file "${nodes_file}" "queued..." ""
	cat > "${follower_script}" <<-EOF
		#!/bin/sh
		last_lines=0
		while [ ! -f "${follower_stop}" ]
		do
			[ -f "${live_stream_file}" ] || {
				sleep 1
				continue
			}
			current_lines=\$(wc -l < "${live_stream_file}" 2>/dev/null)
			[ -n "\${current_lines}" ] || current_lines=0
			if [ "\${current_lines}" -gt "\${last_lines}" ]; then
				sed -n "$((last_lines + 1)),\${current_lines}p" "${live_stream_file}" 2>/dev/null | while IFS= read -r line
				do
					[ -n "\${line}" ] || continue
					[ "\${line}" = "__FSS_WEBTEST_FOLLOWER_STOP__" ] && continue
					nu="\${line%%>*}"
					state="\${line#*>}"
					[ -n "\${nu}" ] || continue
					[ -f "${WT_WEBTEST_STATE_FILE}" ] || continue
					current=\$(awk -F '>' -v node="\${nu}" '\$1 == node { print \$2; exit }' "${WT_WEBTEST_STATE_FILE}" 2>/dev/null)
					if [ "\${current}" != "\${state}" ]; then
						tmp_state_file="${WT_WEBTEST_STATE_FILE}.tmp.\$\$"
						awk -F '>' -v node="\${nu}" -v state="\${state}" '
							BEGIN { updated = 0 }
							\$1 == node {
								print node ">" state
								updated = 1
								next
							}
							{ print }
							END {
								if (updated == 0) {
									print node ">" state
								}
							}
						' "${WT_WEBTEST_STATE_FILE}" > "\${tmp_state_file}" 2>/dev/null && mv -f "\${tmp_state_file}" "${WT_WEBTEST_STATE_FILE}"
						printf '%s\n' "\${line}" >> "${WT_WEBTEST_FILE}"
						printf '%s\n' "\${line}" >> "${WT_WEBTEST_STREAM}"
					fi
				done
				last_lines="\${current_lines}"
			fi
			sleep 1
		done
	EOF
	chmod +x "${follower_script}"
	"${follower_script}" >/dev/null 2>&1 &
	follower_pid="$!"
	"${webtest_tool}" run --config "${job_file}" >/dev/null 2>&1 &
	daemon_pid="$!"
	if ! wt_wait_pid_with_timeout "${daemon_pid}" "${timeout_secs}"; then
		kill -9 "${daemon_pid}" >/dev/null 2>&1 || true
		: > "${follower_stop}"
		printf '%s\n' "__FSS_WEBTEST_FOLLOWER_STOP__" >> "${live_stream_file}"
		sleep 1
		[ -n "${follower_pid}" ] && kill "${follower_pid}" >/dev/null 2>&1 || true
		return 1
	fi
	wait "${daemon_pid}" >/dev/null 2>&1 || true
	: > "${follower_stop}"
	printf '%s\n' "__FSS_WEBTEST_FOLLOWER_STOP__" >> "${live_stream_file}"
	sleep 1
	[ -n "${follower_pid}" ] && kill "${follower_pid}" >/dev/null 2>&1 || true
	[ -f "${output_json}" ] || return 1
	if [ "${WT_SINGLE}" = "1" ]; then
		wt_webtest_tool_import_results "${output_json}" || return 1
		rm -f "${follower_script}" "${follower_stop}" "${nodes_file}"
		return 0
	fi
	wt_webtest_tool_import_results "${output_json}" || return 1
	rm -f "${follower_script}" "${follower_stop}" "${nodes_file}"
	return 0
}

wt_prepare_protocol_targets_workspace() {
	local targets_file="$1"
	local valid_nodes_file="$2"
	local hooks_dir="$3"

	[ -n "${targets_file}" ] || return 1
	[ -n "${valid_nodes_file}" ] || return 1
	[ -n "${hooks_dir}" ] || return 1
	mkdir -p "${hooks_dir}" || return 1
	: > "${targets_file}"
	: > "${valid_nodes_file}"
}

wt_write_pid_hook_scripts() {
	local start_script="$1"
	local stop_script="$2"
	local pid_file="$3"
	local launch_cmd="$4"

	[ -n "${start_script}" ] || return 1
	[ -n "${stop_script}" ] || return 1
	[ -n "${pid_file}" ] || return 1
	[ -n "${launch_cmd}" ] || return 1
	cat > "${start_script}" <<-EOF
		#!/bin/sh
		${launch_cmd} >/dev/null 2>&1 &
		echo \$! > "${pid_file}"
	EOF
	cat > "${stop_script}" <<-EOF
		#!/bin/sh
		if [ -f "${pid_file}" ]; then
			_pid=\$(cat "${pid_file}" 2>/dev/null)
			[ -n "\${_pid}" ] && kill -9 "\${_pid}" >/dev/null 2>&1
			rm -f "${pid_file}"
		fi
	EOF
	chmod +x "${start_script}" "${stop_script}"
}

wt_append_protocol_target_row() {
	local targets_file="$1"
	local valid_nodes_file="$2"
	local node_id="$3"
	local test_port="$4"
	local start_script="$5"
	local stop_script="$6"
	local wait_port="$7"
	local wait_timeout_ms="${8:-5000}"

	[ -n "${targets_file}" ] || return 1
	[ -n "${valid_nodes_file}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ -n "${test_port}" ] || return 1
	printf '%s|%s|%s|%s|%s|%s\n' "${node_id}" "${test_port}" "${start_script}" "${stop_script}" "${wait_port}" "${wait_timeout_ms}" >> "${targets_file}"
	printf '%s\n' "${node_id}" >> "${valid_nodes_file}"
}

wt_has_active_test_runner() {
	local self_pid="${1:-$$}"

	[ -f "/tmp/webtest.lock" ] && return 0
	ps w 2>/dev/null | awk -v self="${self_pid}" '
		/ss_webtest\.sh/ && !/grep/ {
			pid = $1
			if (pid == self) {
				next
			}
			if ($0 ~ /schedule_warm/ || $0 ~ /schedule_node_direct_refresh/ || $0 ~ /warm_cache/ || $0 ~ /node_direct_refresh/) {
				next
			}
			found = 1
			exit
		}
		END {
			exit(found ? 0 : 1)
		}
	'
}

wt_kill_stale_batch_runners() {
	local self_pid="${1:-$$}"
	local pid=""

	ps w 2>/dev/null | awk -v self="${self_pid}" '
		/ss_webtest\.sh/ && !/grep/ {
			pid = $1
			if (pid == self) next
			if ($0 ~ /schedule_warm/ || $0 ~ /schedule_node_direct_refresh/ || $0 ~ /warm_cache/ || $0 ~ /node_direct_refresh/) next
			print pid
		}
	' | while read -r pid
	do
		[ -n "${pid}" ] || continue
		kill -9 "${pid}" >/dev/null 2>&1 || true
	done
}

wt_ensure_webtest_dir() {
	mkdir -p /tmp/upload
}

wt_reset_webtest_output() {
	wt_ensure_webtest_dir
	: >"${WT_WEBTEST_FILE}"
	: >"${WT_WEBTEST_STREAM}"
}

wt_init_reserved_ports() {
	WT_RESERVED_PORTS_FILE="${TMP2}/reserved_ports.txt"
	: > "${WT_RESERVED_PORTS_FILE}"
}

wt_get_reserved_port() {
	local port=""

	[ -n "${WT_RESERVED_PORTS_FILE}" ] || WT_RESERVED_PORTS_FILE="${TMP2}/reserved_ports.txt"
	[ -f "${WT_RESERVED_PORTS_FILE}" ] || : > "${WT_RESERVED_PORTS_FILE}"
	port=$(get_rand_port "${WT_RESERVED_PORTS_FILE}")
	[ -n "${port}" ] || return 1
	printf '%s\n' "${port}" >> "${WT_RESERVED_PORTS_FILE}"
	sort -un "${WT_RESERVED_PORTS_FILE}" -o "${WT_RESERVED_PORTS_FILE}" 2>/dev/null
	printf '%s\n' "${port}"
}

wt_append_webtest_line() {
	local line="$1"

	[ -n "${line}" ] || return 0
	wt_ensure_webtest_dir
	printf '%s\n' "${line}" >>"${WT_WEBTEST_FILE}"
	printf '%s\n' "${line}" >>"${WT_WEBTEST_STREAM}"
}

wt_emit_webtest_refresh_marker() {
	wt_ensure_webtest_dir
	printf '%s\n' "refresh>snapshot" >>"${WT_WEBTEST_STREAM}"
}

wt_append_webtest_file() {
	local src="$1"

	[ -f "${src}" ] || return 0
	if [ "${WT_SINGLE}" != "1" ] && [ -n "${WT_WEBTEST_STATE_FILE}" ] && [ -f "${WT_WEBTEST_STATE_FILE}" ]; then
		wt_record_batch_result_file "${src}"
		return 0
	fi
	wt_ensure_webtest_dir
	cat "${src}" >>"${WT_WEBTEST_FILE}"
	cat "${src}" >>"${WT_WEBTEST_STREAM}"
}

wt_write_webtest_snapshot() {
	local src="$1"

	wt_ensure_webtest_dir
	if [ -f "${src}" ]; then
		cp -f "${src}" "${WT_WEBTEST_FILE}"
	else
		: >"${WT_WEBTEST_FILE}"
	fi
}

wt_extract_single_outbound_object() {
	local src="$1"
	local out_file="$2"

	[ -f "${src}" ] || return 1
	[ -n "${out_file}" ] || return 1
	awk '
		BEGIN {
			seen_outbounds = 0
			capture = 0
			depth = 0
		}
		{
			if (capture == 0) {
				if (seen_outbounds == 0) {
					if ($0 ~ /"outbounds"[[:space:]]*:/) {
						seen_outbounds = 1
					}
					next
				}
			if ($0 ~ /[{]/) {
				capture = 1
			} else {
				next
			}
		}
			print $0
			line = $0
			opens = gsub(/[{]/, "{", line)
			closes = gsub(/[}]/, "}", line)
			depth += opens - closes
			if (capture == 1 && depth <= 0) {
				exit
			}
		}
	' "${src}" > "${out_file}" || return 1
	[ -s "${out_file}" ]
}

wt_build_group_outbounds_json() {
	local list_file="$1"
	local out_file="$2"
	local cache_out=""
	local first="1"

	[ -s "${list_file}" ] || return 1
	{
		echo '{'
		echo '  "outbounds": ['
		while IFS= read -r cache_out
		do
			[ -s "${cache_out}" ] || continue
			if [ "${first}" = "1" ]; then
				first="0"
			else
				echo ','
			fi
			cat "${cache_out}"
		done < "${list_file}"
		echo '  ]'
		echo '}'
	} > "${out_file}"
	[ "${first}" = "0" ]
}

wt_webtest_cache_write_all_outbounds() {
	local ids_file="$1"
	local tmp_file="${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}.tmp.$$"
	local node_id=""
	local cache_out=""
	local first="1"

	[ -f "${ids_file}" ] || return 1
	wt_webtest_cache_prepare_dirs || return 1
	{
		echo '{'
		echo '  "outbounds": ['
		while IFS= read -r node_id
		do
			[ -n "${node_id}" ] || continue
			cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
			[ -s "${cache_out}" ] || continue
			if [ "${first}" = "1" ]; then
				first="0"
			else
				echo ','
			fi
			cat "${cache_out}"
		done < "${ids_file}"
		echo '  ]'
		echo '}'
	} > "${tmp_file}"
	if [ "${first}" = "1" ]; then
		rm -f "${tmp_file}" "${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}"
		return 1
	fi
	mv -f "${tmp_file}" "${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}"
}

wt_materialize_cached_nodes() {
	local ids_file="$1"
	local out_file="$2"
	local node_id=""
	local cache_out=""
	local meta_file=""
	local start_port=""
	local key=""
	local value=""

	[ -f "${ids_file}" ] || return 1
	[ -n "${out_file}" ] || return 1
	[ -n "${WT_RESERVED_PORTS_FILE}" ] || WT_RESERVED_PORTS_FILE="${TMP2}/reserved_ports.txt"
	[ -f "${WT_RESERVED_PORTS_FILE}" ] || : > "${WT_RESERVED_PORTS_FILE}"
	: > "${out_file}"
	if [ -s "${FSS_WEBTEST_CACHE_INDEX_FILE}" ]; then
		awk -F '|' \
			-v cache_index="${FSS_WEBTEST_CACHE_INDEX_FILE}" \
			-v cache_dir="${FSS_WEBTEST_CACHE_NODE_DIR}" \
			-v reserved_file="${WT_RESERVED_PORTS_FILE}" '
			FILENAME == cache_index {
				cache_ok[$1] = 1
				cache_port[$1] = $2
				next
			}
			$1 != "" {
				node_id = $1
				if (!(node_id in cache_ok)) {
					next
				}
				start_port = (node_id in cache_port ? cache_port[node_id] : "")
				if (start_port != "") {
					print start_port >> reserved_file
				}
				printf "%s|%s/%s_outbounds.json|%s\n", node_id, cache_dir, node_id, start_port
				count++
			}
			END {
				exit(count > 0 ? 0 : 1)
			}
		' "${FSS_WEBTEST_CACHE_INDEX_FILE}" "${ids_file}" > "${out_file}" || true
		if [ -s "${out_file}" ]; then
			sort -un "${WT_RESERVED_PORTS_FILE}" -o "${WT_RESERVED_PORTS_FILE}" 2>/dev/null
			return 0
		fi
		: > "${out_file}"
		: > "${WT_RESERVED_PORTS_FILE}"
	fi
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
		if [ ! -s "${cache_out}" ]; then
			echo -en "${node_id}>failed\n" >>${TMP2}/results/${node_id}.txt
			wt_append_webtest_file "${TMP2}/results/${node_id}.txt"
			continue
		fi
		start_port=""
		meta_file="${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta"
		if [ -f "${meta_file}" ]; then
			while IFS='=' read -r key value
			do
				[ "${key}" = "start_port" ] || continue
				start_port="${value}"
				break
			done < "${meta_file}"
		fi
		[ -n "${start_port}" ] && printf '%s\n' "${start_port}" >> "${WT_RESERVED_PORTS_FILE}"
		printf '%s|%s|%s\n' "${node_id}" "${cache_out}" "${start_port}" >> "${out_file}"
	done < "${ids_file}"
	sort -un "${WT_RESERVED_PORTS_FILE}" -o "${WT_RESERVED_PORTS_FILE}" 2>/dev/null
	[ -s "${out_file}" ]
}

wt_allocate_ports_and_lists() {
	local materialized_file="$1"
	local json_dir="$2"
	local count=0
	local port_count=0
	local ports_file="${json_dir}/ports.txt"
	local pairs_file="${json_dir}/pairs.txt"
	local inbound_items="${json_dir}/00_inbounds.items"
	local routing_items="${json_dir}/02_routing.items"
	local outbound_list="${json_dir}/01_outbounds.list"
	local valid_nodes_file="${json_dir}/valid_nodes.txt"
	local valid_pairs_file="${json_dir}/valid_pairs.txt"

	[ -s "${materialized_file}" ] || return 1
	[ -n "${json_dir}" ] || return 1
	count=$(wc -l < "${materialized_file}" | tr -d ' ')
	[ -n "${count}" ] || count=0
	[ "${count}" -gt 0 ] || return 1
	: > "${ports_file}"
	: > "${pairs_file}"
	: > "${inbound_items}"
	: > "${routing_items}"
	: > "${outbound_list}"
	: > "${valid_nodes_file}"
	: > "${valid_pairs_file}"

	get_avail_ports "${count}" "${WT_RESERVED_PORTS_FILE}" > "${ports_file}" 2>/dev/null
	port_count=$(wc -l < "${ports_file}" | tr -d ' ')
	[ -n "${port_count}" ] || port_count=0
	[ "${port_count}" = "${count}" ] || return 1

	awk '
		NR == FNR {
			ports[NR] = $0
			next
		}
		{
			print $0 "|" ports[FNR]
		}
	' "${ports_file}" "${materialized_file}" > "${pairs_file}" || return 1
	awk -F '|' \
		-v inbound_items="${inbound_items}" \
		-v routing_items="${routing_items}" \
		-v outbound_list="${outbound_list}" \
		-v valid_nodes_file="${valid_nodes_file}" \
		-v valid_pairs_file="${valid_pairs_file}" '
		NF >= 4 && $1 != "" && $2 != "" && $4 != "" {
			id = $1
			cache_out = $2
			socks5_port = $4
			printf "\t\t{\"listen\": \"127.0.0.1\", \"port\": %s, \"protocol\": \"socks\", \"settings\": {\"auth\": \"noauth\", \"udp\": true}, \"tag\": \"socks%s\"}\n", socks5_port, id >> inbound_items
			printf "\t\t{\"type\": \"field\", \"inboundTag\": [\"socks%s\"], \"outboundTag\": \"proxy%s\"}\n", id, id >> routing_items
			print cache_out >> outbound_list
			print id >> valid_nodes_file
			printf "%s|%s\n", id, socks5_port >> valid_pairs_file
			count++
		}
		END {
			exit(count > 0 ? 0 : 1)
		}
	' "${pairs_file}" || return 1
}

wt_prune_webtest_entries() {
	local node_id="$1"
	local file_path=""
	local tmp_file=""

	[ -n "${node_id}" ] || return 0
	for file_path in "${WT_WEBTEST_FILE}" "${WT_WEBTEST_STREAM}" "${WT_WEBTEST_BACKUP}"
	do
		[ -f "${file_path}" ] || continue
		tmp_file="${file_path}.tmp.$$"
		grep -v -E "^${node_id}>|^stop>" "${file_path}" > "${tmp_file}" 2>/dev/null || true
		mv -f "${tmp_file}" "${file_path}"
	done
}

wt_latency_state_is_transient() {
	case "$1" in
	waiting...|loading...|booting...|queued...|warming...|testing...)
		return 0
		;;
	esac
	return 1
}

wt_latency_state_is_terminal() {
	case "$1" in
	failed|timeout|ns|stopped|canceled)
		return 0
		;;
	esac
	echo "$1" | grep -Eq '^[0-9]+$'
}

wt_init_batch_state_file() {
	WT_WEBTEST_STATE_FILE="${TMP2}/webtest.state"
	rm -f "${WT_WEBTEST_STATE_LOCK}"
	[ -s "${TMP2}/nodes_index.txt" ] || wt_build_nodes_index >/dev/null 2>&1 || return 1
	awk -F '|' '
		NF > 0 && $1 != "" {
			print $1 ">waiting..."
		}
	' ${TMP2}/nodes_index.txt > "${WT_WEBTEST_STATE_FILE}"
	cp -f "${WT_WEBTEST_STATE_FILE}" "${WT_WEBTEST_FILE}"
	cp -f "${WT_WEBTEST_STATE_FILE}" "${WT_WEBTEST_STREAM}"
}

wt_batch_state_lock_acquire() {
	exec 235>"${WT_WEBTEST_STATE_LOCK}"
	flock -x 235
}

wt_batch_state_lock_release() {
	flock -u 235
}

wt_get_batch_state() {
	local node_id="$1"
	[ -n "${WT_WEBTEST_STATE_FILE}" ] || return 1
	[ -f "${WT_WEBTEST_STATE_FILE}" ] || return 1
	awk -F '>' -v node="${node_id}" '
		$1 == node {
			print $2
			exit
		}
	' "${WT_WEBTEST_STATE_FILE}" 2>/dev/null
}

wt_set_batch_state() {
	local node_id="$1"
	local state="$2"
	local current=""

	[ -n "${node_id}" ] || return 0
	[ -n "${state}" ] || return 0
	[ -n "${WT_WEBTEST_STATE_FILE}" ] || return 0
	[ -f "${WT_WEBTEST_STATE_FILE}" ] || return 0
	wt_batch_state_lock_acquire
	current=$(awk -F '>' -v node="${node_id}" '
		$1 == node {
			print $2
			exit
		}
	' "${WT_WEBTEST_STATE_FILE}" 2>/dev/null)
	if [ "${current}" != "${state}" ]; then
		if grep -q "^${node_id}>" "${WT_WEBTEST_STATE_FILE}" 2>/dev/null; then
			sed -i "/^${node_id}>/c\\${node_id}>${state}" "${WT_WEBTEST_STATE_FILE}"
		else
			echo "${node_id}>${state}" >> "${WT_WEBTEST_STATE_FILE}"
		fi
	fi
	wt_batch_state_lock_release
	[ "${current}" = "${state}" ] && return 0
	wt_append_webtest_line "${node_id}>${state}"
}

wt_set_batch_state_from_file() {
	local file_path="$1"
	local state="$2"
	local limit="$3"
	local count=0
	local node_id=""
	local old_state_file=""

	[ -f "${file_path}" ] || return 0
	if [ -z "${limit}" ] && [ -n "${WT_WEBTEST_STATE_FILE}" ] && [ -f "${WT_WEBTEST_STATE_FILE}" ]; then
		old_state_file="${WT_WEBTEST_STATE_FILE}.bulk.$$"
		cp -f "${WT_WEBTEST_STATE_FILE}" "${old_state_file}"
		wt_batch_state_lock_acquire
		while read node_id
		do
			[ -n "${node_id}" ] || continue
			if grep -q "^${node_id}>" "${WT_WEBTEST_STATE_FILE}" 2>/dev/null; then
				sed -i "/^${node_id}>/c\\${node_id}>${state}" "${WT_WEBTEST_STATE_FILE}"
			else
				echo "${node_id}>${state}" >> "${WT_WEBTEST_STATE_FILE}"
			fi
		done < "${file_path}"
		wt_batch_state_lock_release
		if ! cmp -s "${old_state_file}" "${WT_WEBTEST_STATE_FILE}" 2>/dev/null; then
			wt_write_webtest_snapshot "${WT_WEBTEST_STATE_FILE}"
			wt_emit_webtest_refresh_marker
		fi
		rm -f "${old_state_file}"
		return 0
	fi
	while read node_id
	do
		[ -n "${node_id}" ] || continue
		wt_set_batch_state "${node_id}" "${state}"
		count=$((count + 1))
		if [ -n "${limit}" ] && [ "${count}" -ge "${limit}" ]; then
			break
		fi
	done < "${file_path}"
}

wt_emit_batch_state_diff() {
	local old_file="$1"
	local new_file="$2"
	local line=""

	[ -f "${old_file}" ] || return 0
	[ -f "${new_file}" ] || return 0
	awk -F '>' '
		NR == FNR {
			old[$1] = $2
			next
		}
		{
			if (old[$1] != $2) {
				print $0
			}
		}
	' "${old_file}" "${new_file}" | while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		wt_append_webtest_line "${line}"
	done
}

wt_record_batch_result_file() {
	local src="$1"
	local line=""
	local node_id=""
	local state=""

	[ -f "${src}" ] || return 0
	while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		node_id="${line%%>*}"
		state="${line#*>}"
		[ -n "${node_id}" ] || continue
		wt_set_batch_state "${node_id}" "${state}"
	done < "${src}"
}

wt_runtime_cleanup() {
	killall wt-ss >/dev/null 2>&1
	killall wt-ss-local >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	killall wt-rss-local >/dev/null 2>&1
	killall wt-v2ray >/dev/null 2>&1
	killall wt-xray >/dev/null 2>&1
	killall wt-trojan >/dev/null 2>&1
	killall wt-naive >/dev/null 2>&1
	killall wt-tuic >/dev/null 2>&1
	killall wt-hy2 >/dev/null 2>&1
	killall webtest-tool >/dev/null 2>&1
	killall curl-fancyss >/dev/null 2>&1
	ps w 2>/dev/null | grep -F '/tmp/fancyss_webtest/webtest_tool_' | grep -E 'follow\.sh|tail -n \+1 -f' | grep -v grep | awk '{print $1}' | while read -r pid
	do
		[ -n "${pid}" ] || continue
		kill -9 "${pid}" >/dev/null 2>&1
	done
}

wt_finalize_batch_output() {
	[ -f "${WT_WEBTEST_STATE_FILE}" ] || return 0
	cp -f "${WT_WEBTEST_STATE_FILE}" "${WT_WEBTEST_FILE}"
	echo "stop>stop" >> "${WT_WEBTEST_FILE}"
	echo "stop>stop" >> "${WT_WEBTEST_STREAM}"
	local TS_LOG=$(date -r "${WT_WEBTEST_FILE}" "+%Y/%m/%d %X")
	dbus set ss_basic_webtest_ts="${TS_LOG}"
	cp -f "${WT_WEBTEST_FILE}" "${WT_WEBTEST_BACKUP}"
}

wt_abort_batch_run() {
	local reason="$1"
	local old_state=""
	local new_state=""

	[ "${WT_BATCH_FINALIZED}" = "1" ] && return 0
	[ -n "${reason}" ] || reason="canceled"
	WT_BATCH_FINALIZED=1
	WT_BATCH_ABORT_REASON="${reason}"
	wt_runtime_cleanup
	if [ -f "${WT_WEBTEST_STATE_FILE}" ]; then
		old_state="${WT_WEBTEST_STATE_FILE}.old.$$"
		new_state="${WT_WEBTEST_STATE_FILE}.new.$$"
		cp -f "${WT_WEBTEST_STATE_FILE}" "${old_state}"
		awk -F '>' -v reason="${reason}" '
			function terminal(v) {
				return (v ~ /^[0-9]+$/ || v == "failed" || v == "timeout" || v == "ns" || v == "stopped" || v == "canceled")
			}
			{
				val = $2
				if (!terminal(val)) {
					val = reason
				}
				print $1 ">" val
			}
		' "${WT_WEBTEST_STATE_FILE}" > "${new_state}"
		wt_emit_batch_state_diff "${old_state}" "${new_state}"
		mv -f "${new_state}" "${WT_WEBTEST_STATE_FILE}"
		rm -f "${old_state}"
	fi
	wt_finalize_batch_output
	rm -f "${WT_WEBTEST_PID_FILE}" "${WT_WEBTEST_STOP_FLAG}" /tmp/webtest.lock "${WT_WEBTEST_STATE_LOCK}"
}

wt_finish_batch_run() {
	[ "${WT_BATCH_FINALIZED}" = "1" ] && return 0
	WT_BATCH_FINALIZED=1
	wt_finalize_batch_output
	rm -f "${WT_WEBTEST_PID_FILE}" "${WT_WEBTEST_STOP_FLAG}" /tmp/webtest.lock "${WT_WEBTEST_STATE_LOCK}"
}

wt_batch_exit_guard() {
	local reason=""

	[ "${WT_BATCH_ACTIVE}" = "1" ] || return 0
	[ "${WT_BATCH_FINALIZED}" = "1" ] && return 0
	[ -f "${WT_WEBTEST_STOP_FLAG}" ] && reason="$(cat "${WT_WEBTEST_STOP_FLAG}" 2>/dev/null)"
	[ -n "${reason}" ] || reason="${WT_BATCH_ABORT_REASON}"
	[ -n "${reason}" ] || reason="canceled"
	wt_abort_batch_run "${reason}"
}

wt_batch_signal_handler() {
	local reason=""

	[ -f "${WT_WEBTEST_STOP_FLAG}" ] && reason="$(cat "${WT_WEBTEST_STOP_FLAG}" 2>/dev/null)"
	[ -n "${reason}" ] || reason="canceled"
	WT_BATCH_ABORT_REASON="${reason}"
	exit 0
}

wt_request_stop_batch() {
	local current_pid="$$"
	local old_state=""
	local new_state=""
	local ss_webtest_pids=""

	echo "stopped" > "${WT_WEBTEST_STOP_FLAG}"
	if [ -f "${TMP2}/webtest.state" ]; then
		WT_WEBTEST_STATE_FILE="${TMP2}/webtest.state"
		old_state="${WT_WEBTEST_STATE_FILE}.old.$$"
		new_state="${WT_WEBTEST_STATE_FILE}.new.$$"
		cp -f "${WT_WEBTEST_STATE_FILE}" "${old_state}"
		awk -F '>' '
			function terminal(v) {
				return (v ~ /^[0-9]+$/ || v == "failed" || v == "timeout" || v == "ns" || v == "stopped" || v == "canceled")
			}
			{
				val = $2
				if (!terminal(val)) {
					val = "stopped"
				}
				print $1 ">" val
			}
		' "${WT_WEBTEST_STATE_FILE}" > "${new_state}"
	fi
	ss_webtest_pids=$(ps | grep -E "ss_webtest\.sh" | awk '{print $1}' | grep -v "^${current_pid}$")
	if [ -n "${ss_webtest_pids}" ];then
		for ss_webtest_pid in ${ss_webtest_pids}
		do
			kill -9 ${ss_webtest_pid} >/dev/null 2>&1
		done
	fi
	wt_runtime_cleanup
	if [ -f "${new_state}" ]; then
		wt_emit_batch_state_diff "${old_state}" "${new_state}"
		mv -f "${new_state}" "${WT_WEBTEST_STATE_FILE}"
		rm -f "${old_state}"
		wt_finalize_batch_output
	fi
	rm -f "${WT_WEBTEST_PID_FILE}" "${WT_WEBTEST_STOP_FLAG}" /tmp/webtest.lock "${WT_WEBTEST_STATE_LOCK}"
}

wt_reset_active_node_env() {
	WT_NODE_ACTIVE_ID=""
	WT_NODE_ACTIVE_JSON=""
}

wt_build_node_env_file() {
	return 0
}

wt_build_node_env_files_bulk() {
	return 0
}

wt_get_router_model() {
	local odmpid=""
	local productid=""

	odmpid=$(nvram get odmpid 2>/dev/null)
	productid=$(nvram get productid 2>/dev/null)
	if [ -n "${odmpid}" ]; then
		printf '%s' "${odmpid}"
	else
		printf '%s' "${productid}"
	fi
}

wt_collect_perf_facts() {
	WT_ARCH=$(uname -m)
	WT_CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
	printf '%s' "${WT_CPU_CORES}" | grep -Eq '^[0-9]+$' || WT_CPU_CORES="1"
	WT_MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
	printf '%s' "${WT_MEM_MB}" | grep -Eq '^[0-9]+$' || WT_MEM_MB="0"
	WT_MODEL=$(wt_get_router_model)
}

wt_select_perf_profile() {
	case "${WT_ARCH}" in
	aarch64)
		if [ "${WT_CPU_CORES}" -lt 3 ]; then
			printf '%s\n' "aarch64_dual_core"
		elif [ "${WT_MEM_MB}" -ge "${WT_MEM_TIER_HIGH_MB}" ]; then
			printf '%s\n' "aarch64_3plus_2g"
		elif [ "${WT_MEM_MB}" -ge "${WT_MEM_TIER_MID_MB}" ]; then
			printf '%s\n' "aarch64_3plus_1g"
		else
			printf '%s\n' "aarch64_3plus_512m"
		fi
		;;
	armv7l)
		if [ "${WT_MODEL}" = "RT-AX89X" ]; then
			printf '%s\n' "armv7l_rt_ax89x"
		elif [ "${WT_CPU_CORES}" -ge 4 ]; then
			if [ "${WT_MEM_MB}" -ge "${WT_MEM_TIER_MID_MB}" ]; then
				printf '%s\n' "armv7l_quad_core_1g"
			else
				printf '%s\n' "armv7l_quad_core_512m"
			fi
		elif [ "${WT_CPU_CORES}" -ge 3 ]; then
			printf '%s\n' "armv7l_tri_core"
		else
			printf '%s\n' "armv7l_low_end"
		fi
		;;
	*)
		printf '%s\n' "generic_low_end"
		;;
	esac
}

wt_apply_perf_profile() {
	local profile="$1"

	WT_LOW_END=1
	WT_XRAY_THREADS=12
	WT_SSR_THREADS=1
	WT_TUIC_THREADS=1
	WT_NAIVE_THREADS=1
	WT_CACHE_BUILD_THREADS=1

	case "${profile}" in
	aarch64_3plus_2g)
		WT_LOW_END=0
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=4
		WT_TUIC_THREADS=3
		WT_NAIVE_THREADS=3
		WT_CACHE_BUILD_THREADS=4
		;;
	aarch64_3plus_1g)
		WT_LOW_END=0
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=4
		WT_TUIC_THREADS=2
		WT_NAIVE_THREADS=2
		WT_CACHE_BUILD_THREADS=4
		;;
	aarch64_3plus_512m)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=2
		WT_TUIC_THREADS=1
		WT_NAIVE_THREADS=1
		WT_CACHE_BUILD_THREADS=2
		;;
	aarch64_dual_core)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=2
		WT_TUIC_THREADS=1
		WT_NAIVE_THREADS=1
		WT_CACHE_BUILD_THREADS=2
		;;
	armv7l_rt_ax89x)
		WT_LOW_END=0
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=2
		WT_TUIC_THREADS=2
		WT_NAIVE_THREADS=2
		WT_CACHE_BUILD_THREADS=3
		;;
	armv7l_quad_core_1g)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=2
		WT_TUIC_THREADS=2
		WT_NAIVE_THREADS=2
		WT_CACHE_BUILD_THREADS=3
		;;
	armv7l_quad_core_512m)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=1
		WT_TUIC_THREADS=1
		WT_NAIVE_THREADS=1
		WT_CACHE_BUILD_THREADS=2
		;;
	armv7l_tri_core)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=1
		WT_TUIC_THREADS=1
		WT_NAIVE_THREADS=1
		WT_CACHE_BUILD_THREADS=2
		;;
	armv7l_low_end|generic_low_end|*)
		WT_LOW_END=1
		WT_XRAY_THREADS=12
		WT_SSR_THREADS=1
		WT_TUIC_THREADS=1
		WT_NAIVE_THREADS=1
		WT_CACHE_BUILD_THREADS=1
		;;
	esac
}

wt_get_cache_build_threads() {
	detect_perf
	printf '%s' "${WT_CACHE_BUILD_THREADS:-1}"
}

wt_cache_start_port_get() {
	local node_id="$1"

	[ -n "${WT_CACHE_START_PORT_MAP_FILE}" ] || return 1
	[ -f "${WT_CACHE_START_PORT_MAP_FILE}" ] || return 1
	awk -F '|' -v node_id="${node_id}" '$1 == node_id {print $2; exit}' "${WT_CACHE_START_PORT_MAP_FILE}" 2>/dev/null
}

wt_assign_webtest_cache_start_ports() {
	local ids_file="$1"
	local node_id=""
	local node_type=""
	local ss_obfs=""
	local count=0
	local port_count=0
	local ids_tmp="${TMP2}/cache_start_port_ids.txt"
	local ports_tmp="${TMP2}/cache_start_ports.alloc"

	[ -f "${ids_file}" ] || return 1
	[ -n "${WT_CACHE_START_PORT_MAP_FILE}" ] || return 1
	: > "${WT_CACHE_START_PORT_MAP_FILE}"
	: > "${ids_tmp}"
	if [ -s "${FSS_NODE_JSON_INDEX_FILE}" ]; then
		awk -F '|' 'NR == FNR {want[$1]=1; next} ($1 in want) && $2 == "00" && ($3 == "http" || $3 == "tls") {print $1}' "${ids_file}" "${FSS_NODE_JSON_INDEX_FILE}" > "${ids_tmp}" 2>/dev/null || true
	else
		while IFS= read -r node_id
		do
			[ -n "${node_id}" ] || continue
			node_type=$(wt_node_get_plain type "${node_id}")
			[ "${node_type}" = "0" ] || continue
			ss_obfs=$(wt_node_get_plain ss_obfs "${node_id}")
			case "${ss_obfs}" in
			http|tls)
				printf '%s\n' "${node_id}" >> "${ids_tmp}"
				;;
			esac
		done < "${ids_file}"
	fi
	count=$(wc -l < "${ids_tmp}" | tr -d ' ')
	[ -n "${count}" ] || count=0
	[ "${count}" -gt 0 ] || return 0
	get_avail_ports "${count}" "${WT_RESERVED_PORTS_FILE}" > "${ports_tmp}" 2>/dev/null || return 1
	port_count=$(wc -l < "${ports_tmp}" | tr -d ' ')
	[ -n "${port_count}" ] || port_count=0
	[ "${port_count}" = "${count}" ] || return 1
	awk '
		NR == FNR {
			ports[NR] = $0
			next
		}
		{
			print $0 "|" ports[FNR]
		}
	' "${ports_tmp}" "${ids_tmp}" >> "${WT_CACHE_START_PORT_MAP_FILE}" || return 1
	cat "${ports_tmp}" >> "${WT_RESERVED_PORTS_FILE}"
	sort -un "${WT_RESERVED_PORTS_FILE}" -o "${WT_RESERVED_PORTS_FILE}" 2>/dev/null
}

wt_load_node_env() {
	local node_id="$1"
	local json_file=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ "${WT_NODE_ACTIVE_ID}" = "${node_id}" ] && return 0
	json_file="${WT_NODE_CACHE_DIR}/${node_id}.json"
	[ -f "${json_file}" ] || return 1
	wt_reset_active_node_env
	WT_NODE_ACTIVE_JSON="$(cat "${json_file}" 2>/dev/null)" || return 1
	[ -n "${WT_NODE_ACTIVE_JSON}" ] || return 1
	WT_NODE_ACTIVE_ID="${node_id}"
}

wt_node_get_plain_from_cache() {
	local node_id="$1"
	local field="$2"
	local store_field=""
	local value=""
	local jq_bin=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ -n "${field}" ] || return 1
	store_field=$(fss_resolve_node_field_name "${field}")
	wt_load_node_env "${node_id}" || return 1
	jq_bin=$(fss_pick_jq_bin)
	[ -n "${jq_bin}" ] || return 1
	value=$(printf '%s' "${WT_NODE_ACTIVE_JSON}" | "${jq_bin}" -r --arg field "${store_field}" '
		def is_b64_field($key):
			$key == "password"
			or $key == "naive_pass"
			or $key == "v2ray_json"
			or $key == "xray_json"
			or $key == "tuic_json";
		. as $root
		| ($root[$field] // empty) as $v
		| if ($v | type) == "null" then
			""
		elif ($v | type) == "string" then
			if is_b64_field($field) and (($root._b64_mode // "") != "raw") and (($root._source // "") == "subscribe") then
				(try ($v | @base64d) catch $v)
			else
				$v
			end
		else
			($v | tostring)
		end
	' 2>/dev/null) || return 1
	printf '%s' "${value}"
}

wt_node_get() {
	local field="$1"
	local node_id="$2"
	local store_field=""
	local value=""

	if value=$(wt_node_get_plain_from_cache "${node_id}" "${field}" 2>/dev/null); then
		store_field=$(fss_resolve_node_field_name "${field}")
		[ -n "${value}" ] || return 0
		if fss_is_bool_field "${store_field}"; then
			[ "${value}" = "1" ] || return 0
		fi
		if fss_is_b64_field "${store_field}"; then
			case "${store_field}" in
			v2ray_json|xray_json|tuic_json)
				value=$(fss_compact_json_value "${value}")
				;;
			esac
			value=$(fss_b64_encode "${value}")
		fi
		printf '%s' "${value}"
		return 0
	fi
	fss_get_node_field_legacy "${node_id}" "${field}"
}

wt_node_get_plain() {
	local field="$1"
	local node_id="$2"
	local value=""

	if value=$(wt_node_get_plain_from_cache "${node_id}" "${field}" 2>/dev/null); then
		printf '%s' "${value}"
		return 0
	fi
	fss_get_node_field_plain "${node_id}" "${field}"
}

wt_node_count() {
	fss_get_node_count
}

run(){
	env -i PATH=${PATH} "$@"
}

wt_prepare_node_cache() {
	local node_id=""
	local blob=""
	local node_cache_dir=""

	wt_reset_active_node_env
	WT_NODE_CACHE_DIR=""
	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	WT_NODE_CACHE_DIR="${FSS_NODE_JSON_CACHE_DIR}"
	if [ -n "${WT_NODE_CACHE_DIR}" ];then
		if type fss_node_json_cache_is_fresh >/dev/null 2>&1 && fss_node_json_cache_is_fresh >/dev/null 2>&1; then
			:
		elif wt_try_node_tool_json_cache; then
			:
		elif type fss_refresh_node_json_cache >/dev/null 2>&1; then
			fss_refresh_node_json_cache >/dev/null 2>&1 || {
				WT_NODE_CACHE_DIR=""
			}
		else
			WT_NODE_CACHE_DIR=""
		fi
	fi
	if [ -n "${WT_NODE_CACHE_DIR}" ] && ls "${WT_NODE_CACHE_DIR}"/*.json >/dev/null 2>&1; then
		return 0
	fi

	node_cache_dir="${TMP2}/node_cache"
	WT_NODE_CACHE_DIR="${node_cache_dir}"
	mkdir -p "${WT_NODE_CACHE_DIR}" || {
		WT_NODE_CACHE_DIR=""
		return 1
	}
	rm -f ${WT_NODE_CACHE_DIR}/*.json >/dev/null 2>&1
	if type fss_dump_v2_node_json_dir >/dev/null 2>&1; then
		fss_dump_v2_node_json_dir "${WT_NODE_CACHE_DIR}" >/dev/null 2>&1 && {
			ls ${WT_NODE_CACHE_DIR}/*.json >/dev/null 2>&1 || {
				WT_NODE_CACHE_DIR=""
				return 1
			}
			return 0
		}
	fi
	fss_list_node_ids | while read node_id
	do
		[ -n "${node_id}" ] || continue
		blob=$(dbus get fss_node_${node_id})
		[ -n "${blob}" ] || continue
		fss_b64_decode "${blob}" > "${WT_NODE_CACHE_DIR}/${node_id}.json" 2>/dev/null || {
			rm -f "${WT_NODE_CACHE_DIR}/${node_id}.json"
		}
	done
	ls ${WT_NODE_CACHE_DIR}/*.json >/dev/null 2>&1 || {
		WT_NODE_CACHE_DIR=""
		return 1
	}
}

wt_prepare_node_env_cache() {
	[ -n "${WT_NODE_CACHE_DIR}" ] || wt_prepare_node_cache || return 1
	fss_clear_node_env_cache_artifacts >/dev/null 2>&1 || true
	return 0
}

wt_list_group_files() {
	if [ -f "${TMP2}/nodes_file_name.txt" ]; then
		sed 's#^.*/##' "${TMP2}/nodes_file_name.txt" 2>/dev/null
		return 0
	fi
	find ${TMP2} -name "wt_*.txt" 2>/dev/null | sed 's#^.*/##' | grep -v '^wt_xray_group\.txt$' | sort -t '_' -k2,2n -k3,3n
}

wt_build_nodes_index() {
	local jq_bin=""
	local json_files=""

	if [ "$(fss_detect_storage_schema)" = "2" ]; then
		if [ ! -s "${FSS_NODE_JSON_INDEX_FILE}" ]; then
			wt_try_node_tool_json_cache >/dev/null 2>&1 || true
		fi
		if [ -s "${FSS_NODE_JSON_INDEX_FILE}" ]; then
			cp -f "${FSS_NODE_JSON_INDEX_FILE}" ${TMP2}/nodes_index.txt 2>/dev/null || true
			[ -f "${TMP2}/nodes_index.txt" ] && sort -t "|" -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt 2>/dev/null
			[ -s "${TMP2}/nodes_index.txt" ] && return 0
		fi
	fi
	if [ -n "${WT_NODE_CACHE_DIR}" ];then
		jq_bin=$(fss_pick_jq_bin)
		if [ -n "${jq_bin}" ];then
			json_files=$(find "${WT_NODE_CACHE_DIR}" -name "*.json" | sort -t "/" -nk5)
			[ -n "${json_files}" ] && "${jq_bin}" -r '
				[
					(input_filename | split("/")[-1] | rtrimstr(".json")),
					(
						((.type // "") | tostring) as $type
						| if ($type | length) == 1 then "0" + $type else $type end
					),
					((.ss_obfs // "") | tostring),
					((.method // "") | tostring)
				] | join("|")
			' ${json_files} 2>/dev/null > ${TMP2}/nodes_index.txt && {
				sort -t "|" -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt
				return 0
			}
		fi
	fi

	: >${TMP2}/nodes_index.txt
	fss_list_node_ids | while read node_id
	do
		[ -z "${node_id}" ] && continue
		printf "%s|%02d|%s|%s\n" \
			"${node_id}" \
			"$(wt_node_get type ${node_id})" \
			"$(wt_node_get ss_obfs ${node_id})" \
			"$(wt_node_get method ${node_id})" \
			>>${TMP2}/nodes_index.txt
	done
	sort -t "|" -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt
}

wt_get_node_group_tag() {
	local node_id="$1"

	[ -n "${node_id}" ] || return 1
	[ -f "${TMP2}/nodes_index.txt" ] || return 1
	awk -F '|' -v node_id="${node_id}" '
		function ss_tag(obfs, method,    obfs_enable, is_2022) {
			obfs_enable = (obfs != "" && obfs != "0") ? 1 : 0
			is_2022 = (method ~ /2022-blake/) ? 1 : 0
			if (is_2022 == 1) {
				return obfs_enable ? "00_05" : "00_04"
			}
			return obfs_enable ? "00_02" : "00_01"
		}
		$1 == node_id {
			if ($2 == "00") {
				print ss_tag($3, $4)
			} else {
				print $2
			}
			exit
		}
	' "${TMP2}/nodes_index.txt"
}

wt_get_group_file_by_tag() {
	local group_tag="$1"

	[ -n "${group_tag}" ] || return 1
	[ -f "${TMP2}/nodes_file_name.txt" ] || return 1
	awk -v group_tag="${group_tag}" '
		$0 ~ ("_" group_tag "\\.txt$") {
			print
			exit
		}
	' "${TMP2}/nodes_file_name.txt"
}

wt_rotate_node_file_from_begin() {
	local file_path="$1"
	local begn_node="$2"
	local first_bgn=""

	[ -f "${file_path}" ] || return 1
	[ -n "${begn_node}" ] || return 0
	first_bgn=$(sed -n '1p' "${file_path}")
	if [ -n "${first_bgn}" ] && [ "${begn_node}" -gt "${first_bgn}" ] 2>/dev/null; then
		sed -n "/${begn_node}/,\$p" "${file_path}" > "${TMP2}/re-arrange-1.txt"
		sed -n "1,/^${begn_node}\$/p" "${file_path}" | sed '$d' > "${TMP2}/re-arrange-2.txt"
		cat "${TMP2}/re-arrange-1.txt" "${TMP2}/re-arrange-2.txt" > "${file_path}"
		rm -f "${TMP2}/re-arrange-1.txt" "${TMP2}/re-arrange-2.txt"
	fi
}

wt_rotate_nodes_manifest_by_file() {
	local curr_file="$1"
	local curr_line=""

	[ -f "${TMP2}/nodes_file_name.txt" ] || return 1
	[ -n "${curr_file}" ] || return 1
	curr_line=$(awk -v target="${curr_file}" '$0 == target {print NR; exit}' "${TMP2}/nodes_file_name.txt")
	[ -n "${curr_line}" ] || curr_line=1
	if [ "${curr_line}" -gt "1" ] 2>/dev/null; then
		sed -n "${curr_line},\$p" "${TMP2}/nodes_file_name.txt" > "${TMP2}/nodes_file_name-1.txt"
		sed -n "1,${curr_line}p" "${TMP2}/nodes_file_name.txt" | sed '$d' > "${TMP2}/nodes_file_name-2.txt"
		cat "${TMP2}/nodes_file_name-1.txt" "${TMP2}/nodes_file_name-2.txt" > "${TMP2}/nodes_file_name.txt"
		rm -f "${TMP2}/nodes_file_name-1.txt" "${TMP2}/nodes_file_name-2.txt"
	fi
}

wt_prepare_group_order() {
	local curr_node="$1"
	local begn_node="$2"
	local curr_tag=""
	local curr_file=""

	[ "${WT_GROUP_ORDER_PREPARED}" = "1" ] && return 0
	curr_tag=$(wt_get_node_group_tag "${curr_node}")
	[ -n "${curr_tag}" ] || return 1
	curr_file=$(wt_get_group_file_by_tag "${curr_tag}")
	[ -f "${curr_file}" ] || return 1

	wt_rotate_node_file_from_begin "${curr_file}" "${begn_node}"
	wt_rotate_nodes_manifest_by_file "${curr_file}"

	WT_GROUP_CURRENT_TAG="${curr_tag}"
	WT_GROUP_CURRENT_FILE="${curr_file}"
	WT_GROUP_PREVIEW_FILE="${curr_file}"
	if wt_group_type_is_xray_like "${curr_tag}" && [ -s "${TMP2}/wt_xray_group.txt" ]; then
		if grep -Fxq "${curr_node}" "${TMP2}/wt_xray_group.txt" >/dev/null 2>&1; then
			wt_rotate_node_file_from_begin "${TMP2}/wt_xray_group.txt" "${begn_node}"
			WT_GROUP_PREVIEW_FILE="${TMP2}/wt_xray_group.txt"
		fi
	fi
	WT_GROUP_ORDER_PREPARED=1
}

wt_webtest_cache_write_materialize_index() {
	local tmp_file="${FSS_WEBTEST_CACHE_INDEX_FILE}.tmp.$$"
	local meta_file=""
	local node_id=""
	local start_port=""
	local count=0

	wt_webtest_cache_prepare_dirs || return 1
	: > "${tmp_file}"
	for meta_file in "${FSS_WEBTEST_CACHE_META_DIR}"/*.meta
	do
		[ -f "${meta_file}" ] || continue
		node_id=$(basename "${meta_file}" .meta)
		[ -s "${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json" ] || continue
		start_port=$(sed -n 's/^start_port=//p' "${meta_file}" | sed -n '1p')
		printf '%s|%s\n' "${node_id}" "${start_port}" >> "${tmp_file}"
		count=$((count + 1))
	done
	if [ "${count}" -gt 0 ]; then
		sort -t "|" -nk1 "${tmp_file}" -o "${tmp_file}" 2>/dev/null
		mv -f "${tmp_file}" "${FSS_WEBTEST_CACHE_INDEX_FILE}"
	else
		rm -f "${tmp_file}" "${FSS_WEBTEST_CACHE_INDEX_FILE}"
	fi
}

wt_group_type_is_xray_like() {
	case "$1" in
	00_01|00_02|00_04|00_05|03|04|05|08)
		return 0
		;;
	esac
	return 1
}

wt_group_preview_count() {
	case "$1" in
	00_01|00_02|00_04|00_05|03|04|05|08)
		if wt_pick_webtest_tool >/dev/null 2>&1; then
			printf '%s\n' 9999
		else
			printf '%s\n' "${WT_XRAY_THREADS:-1}"
		fi
		;;
	01)
		printf '%s\n' "${WT_SSR_THREADS:-1}"
		;;
	06|07)
		printf '%s\n' 9999
		;;
	*)
		printf '%s\n' 4
		;;
	esac
}

wt_show_current_group_preview() {
	local preview_file="$1"
	local node_type="$2"
	local preview_lines=""
	local nu=""

	[ -f "${preview_file}" ] || return 0
	if wt_group_type_is_xray_like "${node_type}" && wt_pick_webtest_tool >/dev/null 2>&1; then
		wt_set_batch_state_from_file "${preview_file}" "loading..." ""
		return 0
	fi
	preview_lines=$(wt_group_preview_count "${node_type}")
	[ -n "${preview_lines}" ] || preview_lines=1
	sed -n "1,${preview_lines}p" ${preview_file} | while read nu
	do
		[ -n "${nu}" ] || continue
		wt_set_batch_state "${nu}" "loading..."
	done
}

wt_ensure_node_direct_dns_ready() {
	local dns_plan=""

	wt_server_resolv_mode_is_dynamic || return 0
	fss_refresh_node_direct_cache >/dev/null 2>&1 || return 1
	if ! fss_node_direct_cache_differs_from_runtime; then
		return 0
	fi
	[ "$(dbus get ss_basic_enable)" = "1" ] || {
		fss_sync_node_direct_runtime >/dev/null 2>&1
		return 0
	}
	dns_plan=$(dbus get ss_basic_dns_plan)
	case "${dns_plan}" in
	1|2)
		sh /koolshare/ss/ssconfig.sh refresh_node_direct_dns >/dev/null 2>&1
		;;
	*)
		fss_sync_node_direct_runtime >/dev/null 2>&1
		;;
	esac
}

refresh_node_direct_after_schema2_change() {
	local dns_plan=""

	fss_refresh_node_direct_cache >/dev/null 2>&1 || return 1
	wt_server_resolv_mode_is_dynamic || return 0
	if ! fss_node_direct_cache_differs_from_runtime; then
		return 0
	fi
	[ "$(dbus get ss_basic_enable)" = "1" ] || {
		fss_sync_node_direct_runtime >/dev/null 2>&1
		return 0
	}
	dns_plan=$(dbus get ss_basic_dns_plan)
	case "${dns_plan}" in
	1|2)
		sh /koolshare/ss/ssconfig.sh refresh_node_direct_dns >/dev/null 2>&1
		;;
	*)
		fss_sync_node_direct_runtime >/dev/null 2>&1
		;;
	esac
	return 0
}

wt_webtest_cache_prepare_dirs() {
	mkdir -p "${FSS_WEBTEST_CACHE_DIR}" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}" \
		"${FSS_WEBTEST_CACHE_META_DIR}" || return 1
}

wt_webtest_cache_global_meta_get() {
	local key="$1"

	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" | sed -n '1p'
}

wt_collect_xray_like_ids_file() {
	local out_file="$1"

	[ -n "${out_file}" ] || return 1
	awk -F '|' '
		$1 != "" && ($2 == "00" || $2 == "03" || $2 == "04" || $2 == "05" || $2 == "08") {
			print $1
		}
	' "${TMP2}/nodes_index.txt" > "${out_file}"
}

wt_filter_supported_ids_file() {
	local src_file="$1"
	local out_file="$2"

	[ -f "${src_file}" ] || return 1
	[ -n "${out_file}" ] || return 1
	[ -f "${TMP2}/nodes_index.txt" ] || return 1
	awk -F '|' '
		NR == FNR {
			if ($1 != "") {
				want[$1] = 1
			}
			next
		}
		want[$1] && ($2 == "00" || $2 == "03" || $2 == "04" || $2 == "05" || $2 == "08") {
			print $1
		}
	' "${src_file}" "${TMP2}/nodes_index.txt" | sort -u > "${out_file}"
}

wt_md5_of_file() {
	local file_path="$1"

	[ -f "${file_path}" ] || {
		printf '%s' "none"
		return 0
	}
	md5sum "${file_path}" 2>/dev/null | awk '{print $1}'
}

wt_webtest_cache_write_global_meta() {
	local ids_file="$1"
	local tmp_file="${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}.tmp.$$"
	local node_config_ts=""
	local xray_count=""
	local xray_ids_md5=""

	[ -f "${ids_file}" ] || return 1
	wt_webtest_cache_prepare_dirs || return 1
	node_config_ts=$(fss_get_node_config_ts)
	[ "${node_config_ts}" != "0" ] || node_config_ts=$(fss_touch_node_config_ts)
	xray_count=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${xray_count}" ] || xray_count=0
	xray_ids_md5=$(wt_md5_of_file "${ids_file}")
	cat > "${tmp_file}" <<-EOF
		cache_rev=${WT_WEBTEST_CACHE_REV}
		gen_rev=${WT_WEBTEST_CACHE_GEN_REV}
		linux_ver=${LINUX_VER}
		ss_basic_tfo=${ss_basic_tfo}
		node_config_ts=${node_config_ts}
		xray_count=${xray_count}
		xray_ids_md5=${xray_ids_md5}
		built_at=$(date +%s)
	EOF
	mv -f "${tmp_file}" "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}"
}

wt_webtest_cache_is_globally_fresh() {
	local ids_file="$1"
	local node_config_ts=""
	local current_count=""
	local current_ids_md5=""
	local cache_rev=""
	local gen_rev=""
	local linux_ver=""
	local cache_tfo=""
	local cache_node_config_ts=""
	local cache_xray_count=""
	local cache_xray_ids_md5=""

	[ -f "${ids_file}" ] || return 1
	current_count=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${current_count}" ] || current_count=0
	[ "${current_count}" -gt 0 ] || return 0
	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 1
	current_ids_md5=$(wt_md5_of_file "${ids_file}")
	cache_rev=$(wt_webtest_cache_global_meta_get "cache_rev")
	gen_rev=$(wt_webtest_cache_global_meta_get "gen_rev")
	linux_ver=$(wt_webtest_cache_global_meta_get "linux_ver")
	cache_tfo=$(wt_webtest_cache_global_meta_get "ss_basic_tfo")
	cache_node_config_ts=$(wt_webtest_cache_global_meta_get "node_config_ts")
	cache_xray_count=$(wt_webtest_cache_global_meta_get "xray_count")
	cache_xray_ids_md5=$(wt_webtest_cache_global_meta_get "xray_ids_md5")
	node_config_ts=$(fss_get_node_config_ts)
	[ "${cache_rev}" = "${WT_WEBTEST_CACHE_REV}" ] || return 1
	[ "${gen_rev}" = "${WT_WEBTEST_CACHE_GEN_REV}" ] || return 1
	[ "${linux_ver}" = "${LINUX_VER}" ] || return 1
	[ "${cache_tfo}" = "${ss_basic_tfo}" ] || return 1
	[ "${cache_node_config_ts}" = "${node_config_ts}" ] || return 1
	[ "${cache_xray_count}" = "${current_count}" ] || return 1
	[ "${cache_xray_ids_md5}" = "${current_ids_md5}" ] || return 1
	[ -s "${FSS_WEBTEST_CACHE_INDEX_FILE}" ] || return 1
	awk -F '|' '{print $1}' "${FSS_WEBTEST_CACHE_INDEX_FILE}" 2>/dev/null | cmp -s - "${ids_file}" || return 1
	[ -s "${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}" ] || return 1
}

wt_webtest_cache_lock_acquire() {
	local waited=0
	local owner_pid=""
	local owner_phase=""
	local owner_count=""

	while ! mkdir "${WT_WEBTEST_CACHE_LOCK}" 2>/dev/null
	do
		owner_pid=$(sed -n '1p' "${WT_WEBTEST_CACHE_LOCK}/pid" 2>/dev/null)
		if [ -n "${owner_pid}" ] && kill -0 "${owner_pid}" 2>/dev/null; then
			if [ "${WT_CACHE_LOGGING}" = "1" ]; then
				owner_phase="$(wt_cache_state_get "phase")"
				owner_count="$(wt_cache_state_get "target_count")"
				[ $((waited % 3)) -eq 0 ] && wt_cache_log "ℹ️节点配置缓存正在由其它任务重建，当前阶段：${owner_phase:-unknown}，目标节点：${owner_count:-0}，已等待 ${waited}s。"
			fi
			[ "${waited}" -lt 120 ] || return 1
			sleep 1
			waited=$((waited + 1))
			continue
		fi
		rm -rf "${WT_WEBTEST_CACHE_LOCK}" >/dev/null 2>&1
	done
	echo "$$" > "${WT_WEBTEST_CACHE_LOCK}/pid"
}

wt_webtest_cache_lock_release() {
	rm -rf "${WT_WEBTEST_CACHE_LOCK}" >/dev/null 2>&1
}

wt_webtest_cache_prune_stale() {
	local source_ids_file="$1"
	local active_ids_file="${TMP2}/webtest_cache_active_ids.txt"
	local node_id=""

	wt_webtest_cache_prepare_dirs >/dev/null 2>&1 || return 0
	if [ -n "${source_ids_file}" ] && [ -f "${source_ids_file}" ]; then
		sort -u "${source_ids_file}" > "${active_ids_file}" 2>/dev/null || cp -f "${source_ids_file}" "${active_ids_file}"
	elif [ -s "${TMP2}/nodes_index.txt" ]; then
		: > "${active_ids_file}"
		wt_collect_xray_like_ids_file "${active_ids_file}"
	else
		: > "${active_ids_file}"
	fi
	{
		find "${FSS_WEBTEST_CACHE_META_DIR}" -name "*.meta" 2>/dev/null | while read -r meta_file
		do
			[ -n "${meta_file}" ] || continue
			basename "${meta_file}" .meta
		done
		find "${FSS_WEBTEST_CACHE_NODE_DIR}" -name '*_outbounds.json' 2>/dev/null | sed -n 's#^.*/\([0-9][0-9]*\)_outbounds\.json$#\1#p'
	} | sort -u | while read -r node_id
	do
		[ -n "${node_id}" ] || continue
		grep -Fxq "${node_id}" "${active_ids_file}" 2>/dev/null && continue
		rm -f "${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta" \
			"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json" \
			"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_start.sh" \
			"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_stop.sh"
	done
	rm -f "${active_ids_file}"
}

wt_webtest_cache_settings_match() {
	local cache_rev=""
	local gen_rev=""
	local linux_ver=""
	local cache_tfo=""

	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 1
	cache_rev=$(wt_webtest_cache_global_meta_get "cache_rev")
	gen_rev=$(wt_webtest_cache_global_meta_get "gen_rev")
	linux_ver=$(wt_webtest_cache_global_meta_get "linux_ver")
	cache_tfo=$(wt_webtest_cache_global_meta_get "ss_basic_tfo")
	[ "${cache_rev}" = "${WT_WEBTEST_CACHE_REV}" ] || return 1
	[ "${gen_rev}" = "${WT_WEBTEST_CACHE_GEN_REV}" ] || return 1
	[ "${linux_ver}" = "${LINUX_VER}" ] || return 1
	[ "${cache_tfo}" = "${ss_basic_tfo}" ] || return 1
}

wt_node_json_meta_get() {
	local node_id="$1"
	local key="$2"
	local json_file=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ -n "${key}" ] || return 1
	json_file="${WT_NODE_CACHE_DIR}/${node_id}.json"
	[ -f "${json_file}" ] || return 1
	sed -n 's/.*"'"${key}"'":[[:space:]]*"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/p' "${json_file}" | sed -n '1p'
}

wt_node_current_rev_get() {
	local node_id="$1"
	local current_rev=""

	[ -n "${node_id}" ] || return 1
	current_rev=$(fss_get_node_field_plain "${node_id}" "_rev" 2>/dev/null)
	[ -n "${current_rev}" ] || current_rev=$(wt_node_json_meta_get "${node_id}" "_rev")
	[ -n "${current_rev}" ] || current_rev="0"
	printf '%s\n' "${current_rev}"
}

wt_collect_missing_webtest_cache_ids() {
	local ids_file="$1"
	local out_file="$2"
	local node_id=""
	local cache_out=""
	local meta_file=""
	local current_rev=""
	local cached_rev=""

	[ -f "${ids_file}" ] || return 1
	[ -n "${out_file}" ] || return 1
	: > "${out_file}"
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
		meta_file="${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta"
		if [ -s "${cache_out}" ] && [ -f "${meta_file}" ]; then
			current_rev=$(wt_node_current_rev_get "${node_id}")
			cached_rev=$(sed -n 's/^node_rev=//p' "${meta_file}" | sed -n '1p')
			[ -n "${cached_rev}" ] || cached_rev="0"
			[ "${cached_rev}" = "${current_rev}" ] && continue
		fi
		printf '%s\n' "${node_id}" >> "${out_file}"
	done < "${ids_file}"
}

wt_rebuild_webtest_cache_from_ids() {
	local ids_file="$1"
	local build_ids_file="${TMP2}/cache_build_ids.txt"
	local node_id=""
	local xray_count=0
	local worker_pids=""
	local worker_fifo="${TMP2}/cache_build_fifo"
	local worker_threads="1"
	local fail_file="${TMP2}/cache_build.fail"
	local allow_incremental="0"

	[ -f "${ids_file}" ] || return 1
	wt_cache_state_begin "webtest_rebuild" "${ids_file}" "检测到节点配置缓存缺失或已过期，开始重建。"
	wt_cache_log "ℹ️检测到节点配置缓存缺失或已过期，开始重建。"
	if wt_try_node_tool_webtest_cache "${ids_file}"; then
		wt_cache_state_ready "webtest_rebuild" "${ids_file}" "node-tool 已完成节点配置缓存重建。"
		return 0
	fi
	wt_cache_log "ℹ️node-tool 未完成缓存构建，回退 shell 生成器继续重建。"
	wt_webtest_cache_prepare_dirs || return 1
	wt_webtest_cache_prune_stale "${ids_file}" >/dev/null 2>&1
	xray_count=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${xray_count}" ] || xray_count=0
	if wt_webtest_cache_settings_match; then
		allow_incremental="1"
	fi
	if [ "${allow_incremental}" = "1" ]; then
		wt_cache_state_phase "scan" "webtest_rebuild" "${ids_file}" "正在检查缺失或过期的节点配置缓存。"
		wt_cache_log "ℹ️正在检查缺失或过期的节点配置缓存。"
		wt_collect_missing_webtest_cache_ids "${ids_file}" "${build_ids_file}" || return 1
	else
		wt_cache_state_phase "full_rebuild" "webtest_rebuild" "${ids_file}" "当前缓存不可增量复用，准备全量重建。"
		wt_cache_log "ℹ️当前缓存不可增量复用，准备全量重建。"
		cp -f "${ids_file}" "${build_ids_file}" || return 1
	fi
	[ -s "${build_ids_file}" ] || {
		wt_cache_state_phase "finalize" "webtest_rebuild" "${ids_file}" "缓存已是最新，正在整理索引。"
		wt_cache_log "ℹ️缓存已是最新，正在整理索引。"
		wt_webtest_cache_prune_stale "${ids_file}" >/dev/null 2>&1
		wt_webtest_cache_write_materialize_index || return 1
		wt_webtest_cache_write_all_outbounds "${ids_file}" >/dev/null 2>&1 || true
		wt_webtest_cache_write_global_meta "${ids_file}" || return 1
		wt_cache_state_ready "webtest_rebuild" "${ids_file}" "节点配置缓存已就绪。"
		return 0
	}
	wt_cache_state_phase "prepare" "webtest_rebuild" "${ids_file}" "正在准备测速运行产物。"
	wt_cache_log "ℹ️正在准备测速运行产物。"
	wt_init_reserved_ports
	wt_reset_active_node_env
	WT_CACHE_START_PORT_MAP_FILE="${TMP2}/cache_start_ports.txt"
	wt_assign_webtest_cache_start_ports "${build_ids_file}" || return 1
	worker_threads=$(wt_get_cache_build_threads)
	printf '%s' "${worker_threads}" | grep -Eq '^[0-9]+$' || worker_threads="1"
	[ "${worker_threads}" -gt 0 ] || worker_threads="1"
	rm -f "${fail_file}"
	wt_open_fifo_pool "${worker_threads}" "${worker_fifo}"
	wt_cache_state_phase "build" "webtest_rebuild" "${ids_file}" "正在生成节点测速配置缓存。"
	wt_cache_log "ℹ️正在生成节点测速配置缓存。"
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		read -r _ <&3
		{
			trap 'echo >&3' EXIT
			wt_webtest_cache_build_node "${node_id}" >/dev/null 2>&1 || {
				echo "${node_id}" >> "${fail_file}"
				fss_clear_webtest_cache_node "${node_id}" >/dev/null 2>&1
			}
		} &
		worker_pids="${worker_pids} $!"
	done < "${build_ids_file}"
	[ -n "${worker_pids}" ] && wait ${worker_pids}
	wt_close_fifo_pool
	rm -f "${WT_CACHE_START_PORT_MAP_FILE}"
	WT_CACHE_START_PORT_MAP_FILE=""
	[ ! -s "${fail_file}" ] || return 1

	wt_cache_state_phase "finalize" "webtest_rebuild" "${ids_file}" "正在整理测速缓存索引。"
	wt_cache_log "ℹ️正在整理测速缓存索引。"
	wt_webtest_cache_prune_stale "${ids_file}" >/dev/null 2>&1
	wt_webtest_cache_write_materialize_index || return 1
	wt_webtest_cache_write_all_outbounds "${ids_file}" >/dev/null 2>&1 || true
	wt_webtest_cache_write_global_meta "${ids_file}" || return 1
	wt_cache_state_ready "webtest_rebuild" "${ids_file}" "节点配置缓存重建完成。"
	wt_cache_log "ℹ️节点配置缓存重建完成。"
}

wt_webtest_cache_build_node() {
	local node_id="$1"
	local node_type=""
	local cache_mark=""
	local meta_file=""
	local cache_out=""
	local cache_start=""
	local cache_stop=""
	local tmp_meta=""
	local tmp_out=""
	local tmp_start=""
	local tmp_stop=""
	local current_rev="0"

	[ -n "${node_id}" ] || return 1
	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${LINUX_VER}" ] || LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="$(dbus get ss_basic_tfo)"
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="0"
	wt_webtest_cache_prepare_dirs || return 1
	node_type=$(wt_node_get type "${node_id}")
	cache_mark="cache_${node_id}"
	meta_file="${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta"
	cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
	cache_start="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_start.sh"
	cache_stop="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_stop.sh"
	tmp_meta="${meta_file}.tmp.$$"
	tmp_out="${cache_out}.tmp.$$"
	tmp_start="${cache_start}.tmp.$$"
	tmp_stop="${cache_stop}.tmp.$$"

	rm -f "${tmp_meta}" "${tmp_out}" "${tmp_start}" "${tmp_stop}"
	WT_LAST_START_PORT=""
	WT_PRESET_START_PORT=""
	[ -n "${WT_CACHE_START_PORT_MAP_FILE}" ] && WT_PRESET_START_PORT=$(wt_cache_start_port_get "${node_id}")
	WT_GEN_OUT_FILE="${tmp_out}"
	WT_GEN_START_FILE="${tmp_start}"
	WT_GEN_STOP_FILE="${tmp_stop}"
	WT_OUTBOUND_OBJECT_ONLY="1"

	case "${node_type}" in
	0)
		wt_gen_ss_outbound "${node_id}" "${cache_mark}"
		;;
	3)
		wt_gen_vmess_outbound "${node_id}" "${cache_mark}"
		;;
	4)
		wt_gen_vless_outbound "${node_id}" "${cache_mark}"
		;;
	5)
		wt_gen_trojan_outbound "${node_id}" "${cache_mark}"
		;;
	8)
		wt_gen_hy2_outbound "${node_id}" "${cache_mark}"
		;;
	*)
		WT_OUTBOUND_OBJECT_ONLY=""
		WT_GEN_OUT_FILE=""
		WT_GEN_START_FILE=""
		WT_GEN_STOP_FILE=""
		return 1
		;;
	esac
	WT_OUTBOUND_OBJECT_ONLY=""
	WT_GEN_OUT_FILE=""
	WT_GEN_START_FILE=""
	WT_GEN_STOP_FILE=""

	[ -s "${tmp_out}" ] || {
		rm -f "${tmp_meta}" "${tmp_out}" "${tmp_start}" "${tmp_stop}"
		return 1
	}

	current_rev=$(wt_node_current_rev_get "${node_id}")
	cat > "${tmp_meta}" <<-EOF
		node_type=${node_type}
		node_rev=${current_rev}
		linux_ver=${LINUX_VER}
		ss_basic_tfo=${ss_basic_tfo}
		builder=shell
		has_start=0
		has_stop=0
		start_port=${WT_LAST_START_PORT}
		built_at=$(date +%s)
	EOF

	if [ -f "${tmp_start}" ]; then
		sed -i '/^has_start=/c\has_start=1' "${tmp_meta}" 2>/dev/null
	fi
	if [ -f "${tmp_stop}" ]; then
		sed -i '/^has_stop=/c\has_stop=1' "${tmp_meta}" 2>/dev/null
	fi

	mv -f "${tmp_out}" "${cache_out}" || {
		rm -f "${tmp_out}" "${tmp_meta}" "${tmp_start}" "${tmp_stop}"
		return 1
	}
	if [ -f "${tmp_start}" ]; then
		mv -f "${tmp_start}" "${cache_start}"
		chmod +x "${cache_start}"
	else
		rm -f "${cache_start}"
	fi
	if [ -f "${tmp_stop}" ]; then
		mv -f "${tmp_stop}" "${cache_stop}"
		chmod +x "${cache_stop}"
	else
		rm -f "${cache_stop}"
	fi
	mv -f "${tmp_meta}" "${meta_file}" || {
		rm -f "${tmp_meta}"
		return 1
	}
	return 0
}

wt_ensure_webtest_cache_nodes_file() {
	local src_ids_file="$1"
	local ids_file="${TMP2}/xray_like_nodes.ensure"
	local build_ids_file="${TMP2}/cache_build.ensure"
	local node_id=""
	local ret=0

	[ -f "${src_ids_file}" ] || return 1
	if [ "$(fss_detect_storage_schema)" = "2" ]; then
	if wt_try_node_tool_webtest_cache "${src_ids_file}"; then
			return 0
		fi
	fi
	wt_prepare_node_cache >/dev/null 2>&1 || return 1
	wt_ensure_node_direct_dns_ready >/dev/null 2>&1 || true
	wt_build_nodes_index || return 1
	wt_filter_supported_ids_file "${src_ids_file}" "${ids_file}" || return 1
	[ -s "${ids_file}" ] || return 0
	if wt_webtest_cache_is_globally_fresh "${ids_file}"; then
		rm -f "${ids_file}" >/dev/null 2>&1
		return 0
	fi
	if wt_try_node_tool_webtest_cache "${ids_file}"; then
		rm -f "${ids_file}" >/dev/null 2>&1
		return 0
	fi
	wt_webtest_cache_prepare_dirs || return 1
	wt_webtest_cache_lock_acquire || return 1
	if wt_webtest_cache_settings_match; then
		wt_collect_missing_webtest_cache_ids "${ids_file}" "${build_ids_file}" || ret=1
	else
		cp -f "${ids_file}" "${build_ids_file}" || ret=1
	fi
	if [ "${ret}" = "0" ] && [ -s "${build_ids_file}" ]; then
		wt_init_reserved_ports
		wt_reset_active_node_env
		if [ "${ret}" = "0" ]; then
			while IFS= read -r node_id
			do
				[ -n "${node_id}" ] || continue
				wt_webtest_cache_build_node "${node_id}" >/dev/null 2>&1 || {
					fss_clear_webtest_cache_node "${node_id}" >/dev/null 2>&1
					ret=1
					break
				}
			done < "${build_ids_file}"
		fi
	fi
	rm -f "${WT_CACHE_START_PORT_MAP_FILE}" "${build_ids_file}" "${ids_file}" >/dev/null 2>&1
	WT_CACHE_START_PORT_MAP_FILE=""
	wt_webtest_cache_lock_release
	[ "${ret}" = "0" ] || wt_cache_state_failed "webtest_rebuild" "${src_ids_file}" "节点配置缓存重建失败。"
	return "${ret}"
}

wt_ensure_webtest_cache_ready() {
	local ids_file="${TMP2}/xray_like_nodes.all"
	local ret=0

	if [ "$(fss_detect_storage_schema)" = "2" ]; then
		if wt_try_node_tool_webtest_cache_all; then
			return 0
		fi
	fi
	wt_build_nodes_index || return 1
	wt_collect_xray_like_ids_file "${ids_file}" || return 1
	if wt_webtest_cache_is_globally_fresh "${ids_file}"; then
		return 0
	fi
	if wt_try_node_tool_webtest_cache "${ids_file}"; then
		return 0
	fi
	wt_webtest_cache_lock_acquire || return 1
	if wt_webtest_cache_is_globally_fresh "${ids_file}"; then
		wt_webtest_cache_lock_release
		return 0
	fi
	wt_rebuild_webtest_cache_from_ids "${ids_file}"
	ret=$?
	wt_webtest_cache_lock_release
	[ "${ret}" = "0" ] || wt_cache_state_failed "webtest_rebuild" "${ids_file}" "节点配置缓存重建失败。"
	return "${ret}"
}

wt_build_group_inbounds_json() {
	local items_file="$1"
	local out_file="$2"

	[ -s "${items_file}" ] || return 1
	{
		echo '{'
		echo '  "inbounds": ['
		sed '$!s/$/,/' "${items_file}"
		echo '  ]'
		echo '}'
	} > "${out_file}"
}

wt_build_group_routing_json() {
	local items_file="$1"
	local out_file="$2"

	[ -s "${items_file}" ] || return 1
	{
		echo '{'
		echo '  "routing": {'
		echo '    "rules": ['
		sed '$!s/$/,/' "${items_file}"
		echo '    ]'
		echo '  }'
		echo '}'
	} > "${out_file}"
}

wt_mark_failed_result() {
	local node_id="$1"

	[ -n "${node_id}" ] || return 0
	echo -en "${node_id}>failed\n" >>${TMP2}/results/${node_id}.txt
	wt_append_webtest_file "${TMP2}/results/${node_id}.txt"
}

wt_mark_failed_from_nodes_file() {
	local file_path="$1"
	local node_id=""

	[ -f "${file_path}" ] || return 0
	while read -r node_id
	do
		[ -n "${node_id}" ] || continue
		wt_mark_failed_result "${node_id}"
	done < "${file_path}"
}

wt_cleanup_xray_group_runtime() {
	local xray_pid="$1"

	[ -n "${xray_pid}" ] && kill "${xray_pid}" >/dev/null 2>&1
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	rm -rf ${TMP2}/wt-xray
	rm -rf ${TMP2}/wt-obfs
}

wt_prepare_xray_group_runtime() {
	local file_path="$1"
	local mark="$2"
	local json_dir="${TMP2}/json_${mark}"
	local logs_dir="${TMP2}/logs_${mark}"
	local materialized_file="${json_dir}/materialized.txt"
	local outbound_list="${json_dir}/01_outbounds.list"
	local valid_nodes_file="${json_dir}/valid_nodes.txt"
	local valid_pairs_file="${json_dir}/valid_pairs.txt"
	local valid_count=0
	local cache_xray_count=""

	mkdir -p "${json_dir}" "${logs_dir}"
	rm -rf "${json_dir}"/* "${logs_dir}"/*
	rm -f "${materialized_file}" "${outbound_list}" "${valid_nodes_file}" "${valid_pairs_file}"

	if ! wt_ensure_webtest_cache_ready; then
		wt_mark_failed_from_nodes_file "${file_path}"
		return 1
	fi
	if ! wt_materialize_cached_nodes "${file_path}" "${materialized_file}"; then
		return 1
	fi
	[ -f "${materialized_file}" ] && valid_count=$(wc -l < "${materialized_file}" | tr -d ' ')
	[ -n "${valid_count}" ] || valid_count=0
	[ "${valid_count}" -gt 0 ] || return 1

	if ! wt_allocate_ports_and_lists "${materialized_file}" "${json_dir}"; then
		cat "${materialized_file}" | awk -F '|' '{print $1}' | while read -r node_id
		do
			[ -n "${node_id}" ] || continue
			wt_mark_failed_result "${node_id}"
		done
		return 1
	fi

	[ -f "${valid_nodes_file}" ] && valid_count=$(wc -l < "${valid_nodes_file}" | tr -d ' ')
	[ -n "${valid_count}" ] || valid_count=0
	[ "${valid_count}" -gt 0 ] || return 1

	wt_build_group_inbounds_json "${json_dir}/00_inbounds.items" "${json_dir}/00_inbounds.json"
	cache_xray_count=$(wt_webtest_cache_global_meta_get "xray_count")
	if [ -s "${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}" ] && [ -n "${cache_xray_count}" ] && [ "${valid_count}" = "${cache_xray_count}" ]; then
		cp -f "${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}" "${json_dir}/01_outbounds.json"
	else
		wt_build_group_outbounds_json "${outbound_list}" "${json_dir}/01_outbounds.json"
	fi
	wt_build_group_routing_json "${json_dir}/02_routing.items" "${json_dir}/02_routing.json"
	if [ ! -s "${json_dir}/00_inbounds.json" -o ! -s "${json_dir}/01_outbounds.json" -o ! -s "${json_dir}/02_routing.json" ];then
		wt_mark_failed_from_nodes_file "${valid_nodes_file}"
		return 1
	fi

	printf '%s|%s|%s|%s\n' "${json_dir}" "${logs_dir}" "${valid_nodes_file}" "${valid_pairs_file}"
	return 0
}

wt_open_fifo_pool() {
	local slots="$1"
	local fifo_path="$2"
	local i=0

	[ -n "${slots}" ] || slots=1
	[ "${slots}" -gt 0 ] 2>/dev/null || slots=1
	[ -e "${fifo_path}" ] || mknod "${fifo_path}" p
	exec 3<>"${fifo_path}"
	rm -f "${fifo_path}"
	while [ ${i} -lt "${slots}" ]; do
		echo >&3
		i=$((i + 1))
	done
}

wt_close_fifo_pool() {
	exec 3<&-
	exec 3>&-
}

wt_prepare_webtest_preview() {
	local curr_node=""
	local max_show=""
	local begn_node=""
	local preview_ids_file="${TMP2}/xray_like_nodes.preview"

	WT_PREVIEW_READY=0
	detect_perf
	curr_node=$(fss_get_current_node_id)
	[ -z "${curr_node}" ] && curr_node=$(fss_get_first_node_id)
	[ -n "${curr_node}" ] || return 1

	max_show=$(dbus get ss_basic_row)
	if [ "${max_show}" -gt "1" ]; then
		begn_node=$(awk -v x=${curr_node} -v y=${max_show} 'BEGIN { printf "%.0f\n", (x-y/2)}')
	else
		begn_node=$((${curr_node} - 10))
	fi

	wt_prepare_group_order "${curr_node}" "${begn_node}" || return 1
	if [ -f "${TMP2}/nodes_index.txt" ]; then
		wt_collect_xray_like_ids_file "${preview_ids_file}" >/dev/null 2>&1 || true
	fi
	if [ -s "${preview_ids_file}" ] && ! wt_webtest_cache_is_globally_fresh "${preview_ids_file}"; then
		wt_http_response "ok5, webtest cache rebuilding..."
	else
		wt_http_response "ok4, webtest.txt generating..."
	fi
	rm -f "${preview_ids_file}" >/dev/null 2>&1
	wt_show_current_group_preview "${WT_GROUP_PREVIEW_FILE}" "${WT_GROUP_CURRENT_TAG}"
	WT_PREVIEW_READY=1
}

detect_perf(){
	[ "${WT_PERF_READY}" = "1" ] && return 0
	wt_collect_perf_facts
	WT_PERF_PROFILE=$(wt_select_perf_profile)
	wt_apply_perf_profile "${WT_PERF_PROFILE}"
	WT_PERF_READY="1"
}

ensure_latency_batch(){
	if [ -z "${ss_basic_latency_batch}" ];then
		detect_perf
		if [ "${WT_LOW_END}" == "1" ];then
			dbus set ss_basic_latency_batch="0"
			ss_basic_latency_batch="0"
		else
			dbus set ss_basic_latency_batch="1"
			ss_basic_latency_batch="1"
		fi
	fi
}

update_webtest_file(){
	local snapshot_file="${TMP2}/webtest.snapshot"

	rm -f "${snapshot_file}"
	if [ "${WT_SINGLE}" != "1" ];then
		return 0
	fi
	if [ "${WT_SINGLE}" == "1" ];then
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > "${snapshot_file}"
		cat "${snapshot_file}" >> "${WT_WEBTEST_FILE}"
	else
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > "${snapshot_file}"
		wt_write_webtest_snapshot "${snapshot_file}"
	fi
	rm -f "${snapshot_file}"
}

get_webtest_usable_count(){
	local webtest_file="$1"
	[ -f "${webtest_file}" ] || {
		echo 0
		return 0
	}
	awk -F '>' '
		$1 != "stop" && ($2 == "failed" || $2 == "timeout" || $2 == "ns" || $2 == "stopped" || $2 == "canceled" || $2 ~ /^[0-9]+$/) {count++}
		END {print count + 0}
	' "${webtest_file}" 2>/dev/null
}

# ----------------------------------------------------------------------
# webtest
# 0: ss: ss, ss + simpple obfs, ss + v2ray plugin
# 1: ssr
# 3: v2ray
# 4: xray
# 5: trojan
# 6: naive

# 1. 先分类，ss分4类（ss, ss+simple, ss+v2ray, ss2022），ssr一类，v2ray + xray + trojan一类，naive一类，总共7类
# 2. 按照类别分别进行测试，而不是按照节点顺序测试，这样可以避免v2ray，xray等线程过多导致路由器资源耗尽，每个类的线程数不一样
# 3. 每个类别的测试，不同机型给到不同的线程数量，比如RT-AX56U_V2这种小内存机器，给一个线程即可
# 4. ss测试需要判断加密方式是否为2022AEAD，如果是，则需要判断是否存在sslocal，（不存在则返回不支持）
# 4. ss测试需要判断是否启用了插件，如果是v2ray-plugin插件，则测试线程应该降低，fancyss_lite不测试（返回不支持）
# 5. v2ray的配置文件（一般为vmess）由xray进行测试，因为fancyss_lite不带v2ray二进制
# 6. 二进制启动目标为开socks5端口，然后用curl通过该端口进行落地延迟测试
# 7. ss ssr这类以开多个二进制来增加线程，xray测试则使用一个线程 + 开多个socks5端口的配置文件来进行测试
# 8. 运行测试的时候，需要将各个二进制改名后运行，以免ssconfig.sh的启停将某个测试进程杀掉

webtest_web(){
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		wt_http_response "batch_disabled"
		return 0
	fi
	set_default "ss_basic_lt_web_time" "30"
	# 1. 如果 lock 存在，说明正在 webtest，那么告诉 web 自己去拿结果吧
	if [ -f "/tmp/webtest.lock" ];then
		if wt_cache_state_is_building; then
			wt_http_response "ok5, webtest cache rebuilding..."
		else
			wt_http_response "ok1, lock exist, webtest is running..."
		fi
		return 0
	fi

	# 2. 如果没有结果文件，或者文件为空，需要去获取 webtest
	if [ ! -s "${WT_WEBTEST_FILE}" ];then
		local backup_usable=$(get_webtest_usable_count "${WT_WEBTEST_BACKUP}")
		if [ "${backup_usable}" -gt "0" ];then
			cp -f "${WT_WEBTEST_BACKUP}" "${WT_WEBTEST_FILE}" >/dev/null 2>&1
			wt_http_response "ok3, partial cache exists, keep it"
			return 0
		fi
		clean_webtest
		start_webtest
		return 0
	fi

	# 3. 如果有结果该文件，且没有lock（webtest完成了的），需要检测下节点数量和webtest数量是否一致，避免新增节点没有webtest
	local webtest_nu=$(cat "${WT_WEBTEST_FILE}" | awk -F ">" '{print $1}' | sort -un | sed '/stop/d' | wc -l)
	local node_nu=$(wt_node_count)
	if [ "${webtest_nu}" -ne "${node_nu}" ];then
		wt_http_response "ok3, partial cache exists, keep it"
		return 0
	fi

	# 4. 如果有结果该文件，且没有lock（webtest完成了的），且节点数和webtest结果数一致，比较下上次webtest结果生成的时间，如果是15分钟以内，则不需要重新webtest
	if [ "${ss_basic_lt_cru_opts}" = "1" ] || [ "${ss_basic_lt_web_time}" = "0" ];then
		wt_http_response "ok2, webtest auto refresh disabled!"
		return 0
	fi
	TS_LST=$(/bin/date -r "${WT_WEBTEST_FILE}" "+%s")
	TS_NOW=$(/bin/date +%s)
	TS_DUR=$((${TS_NOW} - ${TS_LST}))
	local web_refresh_secs=$((ss_basic_lt_web_time * 60))
	if [ "${TS_DUR}" -lt "${web_refresh_secs}" ];then
		wt_http_response "ok2, webtest result in ${ss_basic_lt_web_time}min, do not refresh!"
	else
		clean_webtest
		start_webtest
	fi
}

start_webtest(){
	wt_kill_stale_batch_runners "$$"
	if wt_has_active_test_runner "$$"; then
		return 0
	fi
	# create lock
	touch /tmp/webtest.lock
	rm -f "${WT_WEBTEST_STOP_FLAG}"
	echo "$$" > "${WT_WEBTEST_PID_FILE}"
	WT_BATCH_ACTIVE=1
	WT_BATCH_FINALIZED=0
	WT_BATCH_ABORT_REASON=""
	trap 'wt_batch_signal_handler' HUP INT TERM
	trap 'wt_batch_exit_guard' EXIT
	WT_SINGLE=0
	WT_SKIP_DNS=0
	WT_PREVIEW_READY=0
	WT_GROUP_ORDER_PREPARED=0
	WT_GROUP_CURRENT_TAG=""
	WT_GROUP_CURRENT_FILE=""
	WT_GROUP_PREVIEW_FILE=""
	wt_reset_webtest_output
	
	# 1. prepare
	mkdir -p ${TMP2}
	rm -rf ${TMP2}/*
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	wt_init_reserved_ports
	wt_prepare_node_cache >/dev/null 2>&1
	wt_ensure_node_direct_dns_ready >/dev/null 2>&1

	# 2. 分类
	sort_nodes
	wt_init_batch_state_file
	wt_prepare_webtest_preview

	# 3. 批量测速前，确保批量测速策略参数已经就绪
	ensure_latency_batch

	# 4. 测试
	test_nodes

	# 5. remove lock
	wt_finish_batch_run
	trap - HUP INT TERM EXIT
}

sort_nodes(){
	if [ "$(fss_detect_storage_schema)" = "2" ]; then
		rm -f "${TMP2}"/wt_*.txt "${TMP2}/nodes_file_name.txt" >/dev/null 2>&1
		if wt_try_node_tool_webtest_groups; then
			wt_build_nodes_index || return 1
			return 0
		fi
	fi
	wt_build_nodes_index || return 1
	rm -f "${TMP2}"/wt_*.txt "${TMP2}/nodes_file_name.txt" >/dev/null 2>&1
	awk -F '|' -v tmp2="${TMP2}" '
		function resolve_tag(node_type, ss_obfs, ss_method,    obfs_enable, is_2022) {
			if (node_type != "00") {
				return node_type
			}
			obfs_enable = (ss_obfs != "" && ss_obfs != "0") ? 1 : 0
			is_2022 = (ss_method ~ /2022-blake/) ? 1 : 0
			if (is_2022 == 1) {
				return obfs_enable ? "00_05" : "00_04"
			}
			return obfs_enable ? "00_02" : "00_01"
		}
		function is_xray_like(tag) {
			return (tag == "00_01" || tag == "00_02" || tag == "00_04" || tag == "00_05" || tag == "03" || tag == "04" || tag == "05" || tag == "08")
		}
		$1 != "" && $2 != "" {
			tag = resolve_tag($2, $3, $4)
			if (!(tag in group_path)) {
				group_path[tag] = sprintf("%s/wt_%d_%s.txt", tmp2, ++group_count, tag)
				group_order[group_count] = tag
			}
			print $1 >> group_path[tag]
			if (is_xray_like(tag)) {
				print $1 >> (tmp2 "/wt_xray_group.txt")
			}
		}
		END {
			for (i = 1; i <= group_count; i++) {
				print group_path[group_order[i]] >> (tmp2 "/nodes_file_name.txt")
			}
		}
	' "${TMP2}/nodes_index.txt"
}

test_nodes(){
	# define
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	detect_perf

	local CURR_NODE=$(fss_get_current_node_id)
	[ -z "${CURR_NODE}" ] && CURR_NODE=$(fss_get_first_node_id)
	local XRAY_GROUP_FILE="${TMP2}/wt_xray_group.txt"
	local XRAY_GROUP_NAME="wt_xray_group.txt"
	local FIRST_EFFECTIVE_FILE=""
	local FIRST_EFFECTIVE_NAME=""
	local FIRST_EFFECTIVE_TYPE=""
	local PREVIEW_FILE=""
	local PREVIEW_TYPE=""
	MAX_SHOW=$(dbus get ss_basic_row)
	if [ "${MAX_SHOW}" -gt "1" ];then 
		BEGN_NODE=$(awk -v x=${CURR_NODE} -v y=${MAX_SHOW} 'BEGIN { printf "%.0f\n", (x-y/2)}')
	else
		BEGN_NODE=$((${CURR_NODE} - 10))
	fi

	if [ "${WT_GROUP_ORDER_PREPARED}" != "1" ]; then
		wt_prepare_group_order "${CURR_NODE}" "${BEGN_NODE}" || return 1
	fi

	if [ "${WT_PREVIEW_READY}" != "1" ];then
		wt_reset_webtest_output
		wt_http_response "ok4, webtest.txt generating..."
		FIRST_EFFECTIVE_FILE=$(sed -n '1p' ${TMP2}/nodes_file_name.txt)
		FIRST_EFFECTIVE_NAME=${FIRST_EFFECTIVE_FILE##*/}
		FIRST_EFFECTIVE_TYPE=${FIRST_EFFECTIVE_NAME#wt_*_}
		FIRST_EFFECTIVE_TYPE=${FIRST_EFFECTIVE_TYPE%%.*}
		if wt_group_type_is_xray_like "${FIRST_EFFECTIVE_TYPE}" && [ -s "${XRAY_GROUP_FILE}" ];then
			PREVIEW_FILE="${XRAY_GROUP_FILE}"
			PREVIEW_TYPE="${FIRST_EFFECTIVE_TYPE}"
		else
			PREVIEW_FILE="${FIRST_EFFECTIVE_FILE}"
			PREVIEW_TYPE="${FIRST_EFFECTIVE_TYPE}"
		fi
		wt_show_current_group_preview "${PREVIEW_FILE}" "${PREVIEW_TYPE}"
	fi
	
	local xray_group_done=0
	cat ${TMP2}/nodes_file_name.txt | while read test_file
	do
		local file_name=${test_file##*/}
		local node_type=${file_name#wt_*_}
		local node_type=${node_type%%.*}

		case $node_type in
		00_01|00_02|00_04|00_05|03|04|05|08)
			if [ "${xray_group_done}" != "1" -a -s "${XRAY_GROUP_FILE}" ];then
				test_xray_group ${XRAY_GROUP_NAME} xg
				xray_group_done=1
			fi
			;;
		01)
			test_07_sr $file_name $node_type
			;;
		06)
			test_11_nv $file_name $node_type
			;;
		07)
			test_12_tc $file_name $node_type
			;;
		esac
	done
	
	# we shold remove test tmp file
}

test_xray_group(){
	# test nodes by single xray instance
	local file=$1
	local mark=$2
	local file_path=""
	local webtest_tool_ready="0"
	local runtime_info=""
	local json_dir=""
	local logs_dir=""
	local valid_nodes_file=""
	local valid_pairs_file=""
	local first_port=""
	local xray_pid=""
	[ -z "${WT_XRAY_THREADS}" ] && WT_XRAY_THREADS=1
	if wt_pick_webtest_tool >/dev/null 2>&1; then
		webtest_tool_ready="1"
	fi
	case "${file}" in
	/*)
		file_path="${file}"
		;;
	*)
		file_path="${TMP2}/${file}"
		;;
	esac
	[ ! -f "${file_path}" ] && return 0
	local count=$(cat ${file_path} | wc -l)
	[ "${count}" -lt 1 ] && return 0
	# show the first batch state to web as soon as possible
	wt_set_batch_state_from_file "${file_path}" "loading..." ""

	# prepare
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	ln -sf /koolshare/bin/xray ${TMP2}/wt-xray
	ln -sf /koolshare/bin/obfs-local ${TMP2}/wt-obfs
	runtime_info="$(wt_prepare_xray_group_runtime "${file_path}" "${mark}")" || {
		wt_cleanup_xray_group_runtime ""
		return 0
	}
	json_dir="${runtime_info%%|*}"
	runtime_info="${runtime_info#*|}"
	logs_dir="${runtime_info%%|*}"
	runtime_info="${runtime_info#*|}"
	valid_nodes_file="${runtime_info%%|*}"
	valid_pairs_file="${runtime_info##*|}"

	# now we can start xray to host multiple outbounds
	first_port=$(awk -F '|' 'NR == 1 {print $2; exit}' "${valid_pairs_file}" 2>/dev/null)
	wt_set_batch_state_from_file "${valid_nodes_file}" "booting..." ""
	run ${TMP2}/wt-xray run -confdir "${json_dir}/" >"${logs_dir}/log.txt" 2>&1 &
	xray_pid=$!

	# make sure xray is runing, otherwise output error
	wait_local_port "${first_port}" 30 100000 || wait_program2 wt-xray "${logs_dir}/log.txt" started
	if ! pidof wt-xray >/dev/null 2>&1;then
		wt_mark_failed_from_nodes_file "${valid_nodes_file}"
		wt_cleanup_xray_group_runtime "${xray_pid}"
		return 0
	fi

	if [ "${webtest_tool_ready}" = "1" ]; then
		wt_set_batch_state_from_file "${valid_nodes_file}" "queued..." ""
	fi

	if wt_try_webtest_tool_batch "${valid_pairs_file}" "${mark}"; then
		wt_cleanup_xray_group_runtime "${xray_pid}"
		return 0
	fi

	wt_mark_failed_from_nodes_file "${valid_nodes_file}"
	wt_cleanup_xray_group_runtime "${xray_pid}"
	return 0
}

test_07_sr(){
	local file=$1
	local mark=$2
	local file_path=""
	local max_threads=""
	local targets_file="${TMP2}/targets_${mark}.table"
	local hooks_dir="${TMP2}/hooks_${mark}"
	local pid_file=""
	local start_script=""
	local stop_script=""
	local socks5_port=""
	local json_file=""
	local valid_nodes_file="${TMP2}/targets_${mark}.nodes"
	local _server_ip=""

	case "${file}" in
	/*)
		file_path="${file}"
		;;
	*)
		file_path="${TMP2}/${file}"
		;;
	esac
	[ -f "${file_path}" ] || return 0
	wt_prepare_node_env_cache >/dev/null 2>&1 || true
	max_threads="${WT_SSR_THREADS}"
	[ -n "${max_threads}" ] || max_threads=1
	wt_set_batch_state_from_file "${file_path}" "loading..." ""
	
	# alisa binary
	killall wt-rss-local >/dev/null 2>&1
	ln -sf /koolshare/bin/rss-local ${TMP2}/wt-rss-local
	mkdir -p ${TMP2}/conf_${mark}
	rm -rf ${TMP2}/conf_${mark}/*
	wt_prepare_protocol_targets_workspace "${targets_file}" "${valid_nodes_file}" "${hooks_dir}" || return 1
	while read -r nu
	do
		[ -n "${nu}" ] || continue
		_server_ip=$(_get_server_ip "$(wt_node_get server ${nu})")
		if [ -z "${_server_ip}" ];then
			_server_ip=$(wt_node_get server ${nu})
		fi
		socks5_port=$(wt_get_reserved_port)
		[ -n "${socks5_port}" ] || {
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
			continue
		}
		json_file="${TMP2}/conf_${mark}/${nu}.json"
		cat >"${json_file}" <<-EOF
			{
			    "server":"${_server_ip}",
			    "server_port":$(wt_node_get port ${nu}),
			    "local_address":"0.0.0.0",
			    "local_port":${socks5_port},
			    "password":"$(wt_node_get password ${nu} | base64_decode)",
			    "timeout":600,
			    "protocol":"$(wt_node_get rss_protocol ${nu})",
			    "protocol_param":"$(wt_node_get rss_protocol_param ${nu})",
			    "obfs":"$(wt_node_get rss_obfs ${nu})",
			    "obfs_param":"$(wt_node_get rss_obfs_param ${nu})",
			    "method":"$(wt_node_get method ${nu})"
			}
		EOF
		pid_file="${TMP2}/pids/rss_${nu}.pid"
		start_script="${hooks_dir}/${nu}.start.sh"
		stop_script="${hooks_dir}/${nu}.stop.sh"
		wt_write_pid_hook_scripts "${start_script}" "${stop_script}" "${pid_file}" "\"${TMP2}/wt-rss-local\" -c \"${json_file}\" -f \"${pid_file}\"" || continue
		wt_append_protocol_target_row "${targets_file}" "${valid_nodes_file}" "${nu}" "${socks5_port}" "${start_script}" "${stop_script}" "${socks5_port}" "5000" || continue
	done < "${file_path}"
	[ -s "${targets_file}" ] || return 0
	wt_set_batch_state_from_file "${valid_nodes_file}" "booting..." ""
	if wt_try_webtest_tool_targets_batch "${targets_file}" "${mark}" "${max_threads}"; then
		killall wt-rss-local >/dev/null 2>&1
		rm -rf "${hooks_dir}" ${TMP2}/wt-rss-local
		return 0
	fi

	wt_mark_failed_from_nodes_file "${valid_nodes_file}"
	killall wt-rss-local >/dev/null 2>&1
	rm -rf "${hooks_dir}" ${TMP2}/wt-rss-local
}

test_11_nv(){
	local file=$1
	local file_path=""
	local max_threads=""
	local targets_file="${TMP2}/targets_nv.table"
	local hooks_dir="${TMP2}/hooks_nv"
	local pid_file=""
	local start_script=""
	local stop_script=""
	local socks5_port=""
	local proxy_uri=""
	local valid_nodes_file="${TMP2}/targets_nv.nodes"

	case "${file}" in
	/*)
		file_path="${file}"
		;;
	*)
		file_path="${TMP2}/${file}"
		;;
	esac
	[ -f "${file_path}" ] || return 0
	wt_prepare_node_env_cache >/dev/null 2>&1 || true
	max_threads="${WT_NAIVE_THREADS}"
	[ -n "${max_threads}" ] || max_threads=1
	wt_set_batch_state_from_file "${file_path}" "loading..." ""

	# alisa binary
	ln -sf /koolshare/bin/naive ${TMP2}/wt-naive
	killall wt-naive >/dev/null 2>&1
	wt_prepare_protocol_targets_workspace "${targets_file}" "${valid_nodes_file}" "${hooks_dir}" || return 1

	while read -r nu
	do
		[ -n "${nu}" ] || continue
		socks5_port=$(wt_get_reserved_port)
		[ -n "${socks5_port}" ] || {
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
			continue
		}
		pid_file="${TMP2}/pids/naive_${nu}.pid"
		start_script="${hooks_dir}/${nu}.start.sh"
		stop_script="${hooks_dir}/${nu}.stop.sh"
		proxy_uri="$(wt_node_get naive_prot ${nu})://$(wt_node_get naive_user ${nu}):$(wt_node_get naive_pass ${nu} | base64_decode)@$(wt_node_get naive_server ${nu}):$(wt_node_get naive_port ${nu})"
		wt_write_pid_hook_scripts "${start_script}" "${stop_script}" "${pid_file}" "\"${TMP2}/wt-naive\" --listen=socks://127.0.0.1:${socks5_port} --proxy='${proxy_uri}'" || continue
		wt_append_protocol_target_row "${targets_file}" "${valid_nodes_file}" "${nu}" "${socks5_port}" "${start_script}" "${stop_script}" "${socks5_port}" "5000" || continue
	done < "${file_path}"
	[ -s "${targets_file}" ] || return 0
	wt_set_batch_state_from_file "${valid_nodes_file}" "booting..." ""
	if wt_try_webtest_tool_targets_batch "${targets_file}" "nv" "${max_threads}"; then
		killall wt-naive >/dev/null 2>&1
		rm -rf ${TMP2}/wt-naive "${hooks_dir}"
		return 0
	fi
	
	wt_mark_failed_from_nodes_file "${valid_nodes_file}"
	killall wt-naive >/dev/null 2>&1
	rm -rf ${TMP2}/wt-naive "${hooks_dir}"
}

test_12_tc(){
	local file=$1
	local file_path=""
	local max_threads=""
	local targets_file="${TMP2}/targets_tc.table"
	local hooks_dir="${TMP2}/hooks_tc"
	local pid_file=""
	local start_script=""
	local stop_script=""
	local socks5_port=""
	local new_addr=""
	local tuic_json_file=""
	local valid_nodes_file="${TMP2}/targets_tc.nodes"

	case "${file}" in
	/*)
		file_path="${file}"
		;;
	*)
		file_path="${TMP2}/${file}"
		;;
	esac
	[ -f "${file_path}" ] || return 0
	wt_prepare_node_env_cache >/dev/null 2>&1 || true
	max_threads="${WT_TUIC_THREADS}"
	[ -n "${max_threads}" ] || max_threads=1
	wt_set_batch_state_from_file "${file_path}" "loading..." ""

	# alisa binary
	ln -sf /koolshare/bin/tuic-client ${TMP2}/wt-tuic
	killall wt-tuic >/dev/null 2>&1
	wt_prepare_protocol_targets_workspace "${targets_file}" "${valid_nodes_file}" "${hooks_dir}" || return 1

	while read -r nu
	do
		[ -n "${nu}" ] || continue
		socks5_port=$(wt_get_reserved_port)
		[ -n "${socks5_port}" ] || {
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
			continue
		}
		new_addr="127.0.0.1:${socks5_port}"
		tuic_json_file="${TMP2}/conf/tuic-${socks5_port}.json"
		wt_build_tuic_runtime_json "${nu}" "${new_addr}" "${tuic_json_file}" || {
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
			continue
		}
		pid_file="${TMP2}/pids/tuic_${nu}.pid"
		start_script="${hooks_dir}/${nu}.start.sh"
		stop_script="${hooks_dir}/${nu}.stop.sh"
		wt_write_pid_hook_scripts "${start_script}" "${stop_script}" "${pid_file}" "\"${TMP2}/wt-tuic\" -c \"${tuic_json_file}\"" || continue
		wt_append_protocol_target_row "${targets_file}" "${valid_nodes_file}" "${nu}" "${socks5_port}" "${start_script}" "${stop_script}" "${socks5_port}" "5000" || continue
	done < "${file_path}"
	[ -s "${targets_file}" ] || return 0
	wt_set_batch_state_from_file "${valid_nodes_file}" "booting..." ""
	if wt_try_webtest_tool_targets_batch "${targets_file}" "tc" "${max_threads}"; then
		killall wt-tuic >/dev/null 2>&1
		rm -rf ${TMP2}/wt-tuic "${hooks_dir}"
		return 0
	fi
	
	wt_mark_failed_from_nodes_file "${valid_nodes_file}"
	killall wt-tuic >/dev/null 2>&1
	rm -rf ${TMP2}/wt-tuic "${hooks_dir}"
}

creat_trojan_json(){
	local nu=$1
	local trojan_server=$(wt_node_get server ${nu})
	local trojan_port=$(wt_node_get port ${nu})
	local trojan_uuid=$(wt_node_get trojan_uuid ${nu})
	local trojan_sni=$(wt_node_get trojan_sni ${nu})
	local trojan_ai=$(wt_node_get trojan_ai ${nu})
	local trojan_ai_global=$(dbus get ss_basic_tjai${nu})
	if [ "${trojan_ai_global}" == "1" ];then
		local trojan_ai="1"
	fi
	local trojan_tfo=$(wt_node_get trojan_tfo ${nu})
	local _server_ip=$(_get_server_ip ${trojan_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${trojan_server}
	fi

	
	# outbounds area
	cat >>${TMP2}/conf/${nu}_outbounds.json <<-EOF
		{
		"outbounds": [
			{
				"tag": "proxy${nu}",
				"protocol": "trojan",
				"settings": {
					"servers": [{
					"address": "${_server_ip}",
					"port": ${trojan_port},
					"password": "${trojan_uuid}"
					}]
				},
				"streamSettings": {
					"network": "tcp",
					"security": "tls",
					"tlsSettings": {
						"serverName": $(get_value_null ${trojan_sni}),
						"allowInsecure": $(get_function_switch ${trojan_ai})
    				}
    				,"sockopt": {"tcpFastOpen": $(get_function_switch ${trojan_tfo})}
    			}
  			}
  		]
  		}
	EOF
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf/${nu}_outbounds.json
	fi
	# inbounds
	local socks5_port=$(wt_get_reserved_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >>${TMP2}/conf/${nu}_inbounds.json <<-EOF
		{
		  "inbounds": [
		    {
		      "port": ${socks5_port},
		      "protocol": "socks",
		      "settings": {
		        "auth": "noauth",
		        "udp": true
		      },
		      "tag": "socks${nu}"
		    }
		  ]
		}
	EOF
	# routing
	cat >>${TMP2}/conf/${nu}_routing.json <<-EOF
		{
		  "routing": {
		    "rules": [
		      {
		        "type": "field",
		        "inboundTag": ["socks${nu}"],
		        "outboundTag": "proxy${nu}"
		      }
		    ]
		  }
		}
	EOF
}

creat_hy2_yaml(){
	local nu=$1
	local mark=$2
	if [ -z "$(wt_node_get hy2_sni ${nu})" ];then
		__valid_ip_silent "$(wt_node_get hy2_server ${nu})"
		if [ "$?" != "0" ];then
			# not ip, should be a domain
			local hy2_sni=$(wt_node_get hy2_server ${nu})
		else
			local hy2_sni=""
		fi
	else
		local hy2_sni="$(wt_node_get hy2_sni ${nu})"
	fi

	local _server_ip=$(_get_server_ip $(wt_node_get hy2_server ${nu}))
	if [ -z "${_server_ip}" ];then
		# use domain
		_server_ip=$(wt_node_get hy2_server ${nu})
		#echo -en "${nu}:\t解析失败！\n"
		#continue
	fi

	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		server: ${_server_ip}:$(wt_node_get hy2_port ${nu})
		
		auth: $(wt_node_get hy2_pass ${nu})

		tls:
		  sni: ${hy2_sni}
		  insecure: $(get_function_switch $(wt_node_get hy2_ai ${nu}))
		
		fastOpen: $(get_function_switch $(wt_node_get hy2_tfo ${nu}))
		
	EOF
	
	if [ -n "$(wt_node_get hy2_up ${nu})" -o -n "$(wt_node_get hy2_dl ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			bandwidth: 
			  up: $(wt_node_get hy2_up ${nu}) mbps
			  down: $(wt_node_get hy2_dl ${nu}) mbps
			
		EOF
	fi

	if [ "$(wt_node_get hy2_obfs ${nu})" == "1" -a -n "$(wt_node_get hy2_obfs_pass ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			obfs:
			  type: salamander
			  salamander:
			    password: "$(wt_node_get hy2_obfs_pass ${nu})"
			
		EOF
	fi

	local socks5_port=$(wt_get_reserved_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		transport:
		  udp:
		    hopInterval: 30s
		
		socks5:
		  listen: 127.0.0.1:${socks5_port}
	EOF
}

single_test_node(){
	local test_node="$1"
	if [ -z "${test_node}" ];then
		return 1
	fi

	WT_SINGLE=1
	WT_SKIP_DNS=0
	WT_WEBTEST_STATE_FILE="${TMP2}/webtest.single.state"
	detect_perf
	WT_XRAY_THREADS=1
	WT_SSR_THREADS=1
	WT_TUIC_THREADS=1
	WT_NAIVE_THREADS=1

	mkdir -p ${TMP2}
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	rm -f "${TMP2}/nodes_index.txt" "${TMP2}/nodes_file_name.txt" "${TMP2}"/wt_*.txt >/dev/null 2>&1
	rm -rf ${TMP2}/conf/*
	rm -rf ${TMP2}/pids/*
	rm -rf ${TMP2}/results/*
	: > "${WT_WEBTEST_STATE_FILE}"
	wt_init_reserved_ports
	wt_prune_webtest_entries "${test_node}"
	wt_prepare_node_cache >/dev/null 2>&1
	wt_ensure_node_direct_dns_ready >/dev/null 2>&1
	wt_set_batch_state "${test_node}" "waiting..."

	local single_file="wt_single_${test_node}.txt"
	echo "${test_node}" > ${TMP2}/${single_file}
	local node_type=$(wt_node_get type ${test_node})
	case ${node_type} in
	0|3|4|5|8)
		test_xray_group ${single_file} xg
		;;
	1)
		test_07_sr ${single_file} single
		;;
	6)
		test_11_nv ${single_file}
		;;
	7)
		test_12_tc ${single_file}
		;;
	*)
		wt_append_webtest_line "${test_node}>failed"
		;;
	esac

	# 避免内部测速函数复用局部变量名后把原节点序号冲掉。
	update_single_backup "${test_node}"
	wt_append_webtest_line "stop>stop"
}

warm_webtest_cache() {
	local ids_file=""
	local scanned=0
	local start_ts=""
	local end_ts=""
	local duration=0
	local ret=0
	local cache_tmp2="/tmp/fancyss_webtest_cachework"

	WT_CACHE_LOGGING=1
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	TMP2="${cache_tmp2}"
	mkdir -p "${TMP2}"
	rm -rf "${TMP2}/node_cache" "${TMP2}/node_env" "${TMP2}/nodes_index.txt"
	start_ts=$(date +%s)
	if [ "$(fss_detect_storage_schema)" = "2" ]; then
		if wt_try_node_tool_webtest_cache_all; then
			end_ts=$(date +%s)
			duration=$((end_ts - start_ts))
			scanned=$(wt_get_webtest_cache_xray_count 2>/dev/null)
			[ -n "${scanned}" ] || scanned=0
			wt_cache_log "ℹ️测速配置缓存预热：${scanned} 个 xray 类节点缓存已就绪，耗时 ${duration}s。"
			rm -rf "${TMP2}" >/dev/null 2>&1
			return 0
		fi
	fi
	wt_prepare_node_cache >/dev/null 2>&1 || return 1
	wt_ensure_node_direct_dns_ready >/dev/null 2>&1 || true
	wt_build_nodes_index || return 1
	wt_webtest_cache_prepare_dirs || return 1
	ids_file="${TMP2}/xray_like_nodes.all"
	wt_collect_xray_like_ids_file "${ids_file}" || return 1
	scanned=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${scanned}" ] || scanned=0
	start_ts=$(date +%s)

	if [ "${scanned}" -gt 0 ]; then
		if ! wt_webtest_cache_is_globally_fresh "${ids_file}"; then
			if ! wt_try_node_tool_webtest_cache "${ids_file}"; then
				wt_webtest_cache_lock_acquire || ret=1
				if [ "${ret}" = "0" ]; then
					if ! wt_webtest_cache_is_globally_fresh "${ids_file}"; then
						wt_rebuild_webtest_cache_from_ids "${ids_file}" >/dev/null 2>&1 || ret=1
					fi
					wt_webtest_cache_lock_release
				fi
			fi
		fi
	fi

	end_ts=$(date +%s)
	duration=$((end_ts - start_ts))
	if [ "${scanned}" = "0" ]; then
		wt_cache_log "ℹ️测速配置缓存预热：未发现可由 xray 批量测速的节点，跳过。"
	elif [ "${ret}" != "0" ]; then
		wt_cache_log "⚠️测速配置缓存预热失败：目标 ${scanned} 个 xray 类节点，耗时 ${duration}s。"
	elif wt_webtest_cache_is_globally_fresh "${ids_file}"; then
		wt_cache_log "ℹ️测速配置缓存预热：${scanned} 个 xray 类节点缓存已就绪，耗时 ${duration}s。"
	else
		wt_cache_log "⚠️测速配置缓存预热未完成：目标 ${scanned} 个 xray 类节点，耗时 ${duration}s。"
	fi
	rm -rf "${TMP2}" >/dev/null 2>&1
	return "${ret}"
}

update_single_backup(){
	local nu="$1"
	[ -z "${nu}" ] && return 0
	local new_line=$(grep "^${nu}>" "${WT_WEBTEST_FILE}" | tail -n 1)
	[ -z "${new_line}" ] && return 0
	mkdir -p /tmp/upload ${TMP2}
	local tmp_file="${TMP2}/webtest_bakcup.tmp"
	: > ${tmp_file}
	if [ -f "${WT_WEBTEST_BACKUP}" ];then
		grep -v -E "^${nu}>|^stop>" "${WT_WEBTEST_BACKUP}" > ${tmp_file} || true
	else
		grep -v -E "^${nu}>|^stop>" "${WT_WEBTEST_FILE}" > ${tmp_file} || true
	fi
	echo "${new_line}" >> ${tmp_file}
	echo "stop>stop" >> ${tmp_file}
	mv -f ${tmp_file} "${WT_WEBTEST_BACKUP}"
}

_get_server_ip() {
	local SERVER_IP
	if [ "${WT_SKIP_DNS}" = "1" ];then
		SERVER_IP=$(__valid_ip $1)
		if [ -n "${SERVER_IP}" ]; then
			echo $SERVER_IP
		else
			echo ""
		fi
		return 0
	fi
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		echo "$1 不是域名也不是ip" >>${TMP2}/webtest_log.txt
		echo ""
		return 2
	fi

	SERVER_IP=$(__valid_ip $1)
	if [ -n "${SERVER_IP}" ]; then
		echo "$1 已经是ip，跳过解析！" >>${TMP2}/webtest_log.txt
		echo $SERVER_IP
		return 0
	fi

	echo ""
	return 1
}

wt_json_escape_simple() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

wt_build_tuic_runtime_json() {
	local node_id="$1"
	local local_addr="$2"
	local out_file="$3"
	local raw_json=""
	local relay_server_raw=""
	local relay_host=""
	local relay_ip=""
	local escaped_local_addr=""
	local escaped_relay_ip=""

	[ -n "${node_id}" ] || return 1
	[ -n "${local_addr}" ] || return 1
	[ -n "${out_file}" ] || return 1

	raw_json=$(wt_node_get tuic_json "${node_id}" | base64_decode 2>/dev/null)
	[ -n "${raw_json}" ] || return 1
	raw_json=$(printf '%s' "${raw_json}" | tr -d '\r\n')
	[ -n "${raw_json}" ] || return 1

	relay_server_raw=$(printf '%s' "${raw_json}" | sed -n 's/.*"relay"[[:space:]]*:[[:space:]]*{[^}]*"server"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
	{
		read -r relay_host
		read -r _
	} <<-EOF
	$(fss_extract_tuic_server_host_port "${relay_server_raw}")
	EOF
	relay_ip=$(_get_server_ip "${relay_host}")

	raw_json=$(printf '%s' "${raw_json}" | sed 's/,"local"[[:space:]]*:[[:space:]]*{[^}]*}//; s/"local"[[:space:]]*:[[:space:]]*{[^}]*},//')
	raw_json=$(printf '%s' "${raw_json}" | sed 's/,"ip"[[:space:]]*:[[:space:]]*"[^"]*"//; s/"ip"[[:space:]]*:[[:space:]]*"[^"]*",//')

	if [ -n "${relay_ip}" ]; then
		escaped_relay_ip=$(wt_json_escape_simple "${relay_ip}")
		raw_json=$(printf '%s' "${raw_json}" | sed '0,/"server"[[:space:]]*:[[:space:]]*"[^"]*"/s//&,"ip":"'"${escaped_relay_ip}"'"/')
	fi

	escaped_local_addr=$(wt_json_escape_simple "${local_addr}")
	raw_json=$(printf '%s' "${raw_json}" | sed 's/}[[:space:]]*$/,"local":{"server":"'"${escaped_local_addr}"'"}}/')
	printf '%s' "${raw_json}" > "${out_file}"
}

wait_program(){
	local BINNAME=$1
	local PID1
	local i=40
	until [ -n "${PID1}" ]; do
		usleep 250000
		i=$(($i - 1))
		PID1=$(pidof ${BINNAME})
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	usleep 500000
}

wait_program2(){
	local BINNAME=$1
	local LOGFILE=$2
	local CONTENT=$3
	local MATCH
	local PID1
	# wait for 4s
	local i=16
	# until [ -n "${PID1}" ]; do
	# 	usleep 250000
	# 	i=$(($i - 1))
	# 	PID1=$(pidof ${BINNAME})
	# 	if [ "$i" -lt 1 ]; then
	# 		return 1
	# 	fi
	# done
	
	until [ -n "${MATCH}" ]; do
		usleep 250000
		i=$(($i - 1))
		local MATCH=$(cat $LOGFILE 2>/dev/null | grep -w $CONTENT)
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	return 0
}

wait_local_port(){
	local PORT="$1"
	local RETRIES="${2:-20}"
	local INTERVAL_US="${3:-100000}"
	local MATCH=""

	[ -n "${PORT}" ] || return 1
	until [ -n "${MATCH}" ]; do
		MATCH=$(netstat -nl 2>/dev/null | awk '{print $4}' | grep -E "[:\\.]${PORT}\$" | head -n1)
		[ -n "${MATCH}" ] && return 0
		RETRIES=$((RETRIES - 1))
		[ "${RETRIES}" -lt 1 ] && return 1
		usleep "${INTERVAL_US}"
	done
	return 0
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

clean_webtest(){
	# 当用户手动点击web test按钮的时候，不论是否有正在进行的任务，不论是否在在时限内，强制开始webtest
	# 1. killall program
	wt_runtime_cleanup

	# 2. kill all other ss_webtest.sh
	local current_pid=$$
	local ss_webtest_pids=$(ps|grep -E "ss_webtest\.sh"|awk '{print $1}'|grep -v ${current_pid})
	if [ -n "${ss_webtest_pids}" ];then
		for ss_webtest_pid in ${ss_webtest_pids}
		do
			kill -9 ${ss_webtest_pid} >/dev/null 2>&1
		done
	fi

	# 3. remove lock file if exist
	rm -rf /tmp/webtest.lock >/dev/null 2>&1
	rm -f "${WT_WEBTEST_STOP_FLAG}" "${WT_WEBTEST_PID_FILE}" >/dev/null 2>&1

	# 4. remove webtest result file
	rm -rf "${WT_WEBTEST_FILE}"
	rm -rf "${WT_WEBTEST_STREAM}"
	rm -rf ${TMP2}/*
}

set_latency_job() {
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ]; then
		echo_date "批量web延迟测试已关闭!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		return 0
	fi
	if [ "${ss_basic_lt_cru_opts}" == "0" ]; then
		echo_date "定时测试节点延迟未开启!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	elif [ "${ss_basic_lt_cru_opts}" == "1" ]; then
		echo_date "设置每隔${ss_basic_lt_cru_time}分钟对所有节点进行web延迟检测..."
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		cru a sslatencyjob "*/${ss_basic_lt_cru_time} * * * * /koolshare/scripts/ss_webtest.sh 2"
	fi
}

wt_is_named_action() {
	case "$1" in
	schedule_warm|schedule_node_direct_refresh|warm_cache|ensure_cache_ids_file|node_direct_refresh|web_webtest|clear_webtest|cleanup_helpers|single_test|manual_webtest|close_latency_test|stop_webtest|ws_start_batch|ws_stop_batch|ws_clear_cache|ws_close_latency|ws_single_test)
		return 0
		;;
	esac
	return 1
}

WEBTEST_ACTION=""
WEBTEST_ACTION_ARG=""
if wt_is_named_action "$1"; then
	WEBTEST_ACTION="$1"
	WEBTEST_ACTION_ARG="$2"
elif [ -n "$2" ]; then
	WT_CAN_HTTP_RESPONSE=1
	WEBTEST_ACTION="$2"
	WEBTEST_ACTION_ARG="$3"
else
	WEBTEST_ACTION="$1"
	WEBTEST_ACTION_ARG="$2"
fi

case $1 in
2)
	# start webtest by cron
	clean_webtest
	start_webtest
	;;
3)
	set_latency_job
	;;
schedule_warm)
	mkdir -p /tmp/upload >/dev/null 2>&1
	if wt_has_active_test_runner "$$"; then
		wt_http_response "ok"
		exit 0
	fi
	if ! ps | grep -E "ss_webtest\\.sh warm_cache" | grep -v grep >/dev/null 2>&1; then
		sh "${KSROOT}/scripts/ss_webtest.sh" warm_cache >> /tmp/upload/ss_log.txt 2>&1 &
	fi
	wt_http_response "ok"
	exit 0
	;;
schedule_node_direct_refresh)
	mkdir -p /tmp/upload >/dev/null 2>&1
	if wt_has_active_test_runner "$$"; then
		wt_http_response "ok"
		exit 0
	fi
	if ! ps | grep -E "ss_webtest\\.sh node_direct_refresh" | grep -v grep >/dev/null 2>&1; then
		sh "${KSROOT}/scripts/ss_webtest.sh" node_direct_refresh >> /tmp/upload/ss_log.txt 2>&1 &
	fi
	wt_http_response "ok"
	exit 0
	;;
warm_cache)
	warm_webtest_cache
	;;
ensure_cache_ids_file)
	shift
	ensure_webtest_cache_nodes_file="$1"
	[ -n "${ensure_webtest_cache_nodes_file}" ] || exit 1
	WT_CACHE_LOGGING=0
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	TMP2=/tmp/fancyss_webtest_cachework
	mkdir -p "${TMP2}"
	rm -rf "${TMP2}/node_cache" "${TMP2}/node_env" "${TMP2}/nodes_index.txt"
	wt_ensure_webtest_cache_nodes_file "${ensure_webtest_cache_nodes_file}"
	;;
node_direct_refresh)
	refresh_node_direct_after_schema2_change
	;;
esac

case $WEBTEST_ACTION in
schedule_warm)
	mkdir -p /tmp/upload >/dev/null 2>&1
	if wt_has_active_test_runner "$$"; then
		wt_http_response "ok"
		exit 0
	fi
	if ! ps | grep -E "ss_webtest\\.sh warm_cache" | grep -v grep >/dev/null 2>&1; then
		sh "${KSROOT}/scripts/ss_webtest.sh" warm_cache >> /tmp/upload/ss_log.txt 2>&1 &
	fi
	wt_http_response "ok"
	exit 0
	;;
schedule_node_direct_refresh)
	mkdir -p /tmp/upload >/dev/null 2>&1
	if wt_has_active_test_runner "$$"; then
		wt_http_response "ok"
		exit 0
	fi
	if ! ps | grep -E "ss_webtest\\.sh node_direct_refresh" | grep -v grep >/dev/null 2>&1; then
		sh "${KSROOT}/scripts/ss_webtest.sh" node_direct_refresh >> /tmp/upload/ss_log.txt 2>&1 &
	fi
	wt_http_response "ok"
	exit 0
	;;
warm_cache)
	warm_webtest_cache
	;;
ensure_cache_ids_file)
	ensure_webtest_cache_nodes_file="${WEBTEST_ACTION_ARG}"
	[ -n "${ensure_webtest_cache_nodes_file}" ] || exit 1
	WT_CACHE_LOGGING=0
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	TMP2=/tmp/fancyss_webtest_cachework
	mkdir -p "${TMP2}"
	rm -rf "${TMP2}/node_cache" "${TMP2}/node_env" "${TMP2}/nodes_index.txt"
	wt_ensure_webtest_cache_nodes_file "${ensure_webtest_cache_nodes_file}"
	;;
node_direct_refresh)
	refresh_node_direct_after_schema2_change
	;;
web_webtest)
	# 当用户进入插件，插件列表渲染好后开始调用本脚本进行webtest
	webtest_web
	;;
clear_webtest)
	if [ -f "/tmp/webtest.lock" ];then
		wt_http_response "busy"
		exit 0
	fi
	wt_http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	rm -f "${WT_WEBTEST_BACKUP}"
	;;
cleanup_helpers)
	wt_runtime_cleanup
	rm -rf "${TMP2}" >/dev/null 2>&1
	;;
single_test)
	if [ -f "/tmp/webtest.lock" ];then
		wt_http_response "busy"
		exit 0
	fi
	wt_http_response $1
	single_test_node "${WEBTEST_ACTION_ARG}"
	;;
manual_webtest)
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		wt_http_response "batch_disabled"
		exit 0
	fi
	clean_webtest
	rm -f "${WT_WEBTEST_BACKUP}"
	dbus remove ss_basic_webtest_ts
	wt_http_response $1
	;;
close_latency_test)
	wt_http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	;;
stop_webtest)
	wt_http_response $1
	wt_request_stop_batch
	;;
ws_start_batch)
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		echo "batch_disabled"
		exit 0
	fi
	dbus set ss_basic_latency_val=2 >/dev/null 2>&1
	clean_webtest
	sh /koolshare/scripts/ss_webtest.sh web_webtest >/dev/null 2>&1 &
	echo XU6J03M6
	;;
ws_stop_batch)
	wt_request_stop_batch
	echo XU6J03M6
	;;
ws_clear_cache)
	if [ -f "/tmp/webtest.lock" ];then
		echo busy
	else
		clean_webtest
		dbus remove ss_basic_webtest_ts
		rm -f "${WT_WEBTEST_BACKUP}"
		echo XU6J03M6
	fi
	;;
ws_close_latency)
	dbus set ss_basic_latency_val=0 >/dev/null 2>&1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	echo XU6J03M6
	;;
ws_single_test)
	if [ -z "${WEBTEST_ACTION_ARG}" ];then
		echo busy
		exit 0
	fi
	if [ -f "/tmp/webtest.lock" ];then
		echo busy
	else
		sh /koolshare/scripts/ss_webtest.sh single_test "${WEBTEST_ACTION_ARG}" >/dev/null 2>&1 &
		echo XU6J03M6
	fi
	;;
0)
	wt_http_response $1
	set_latency_job
	;;
1)
	# webtest foreign url changed
	wt_http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
	fi
	set_latency_job
	;;
2)
	# webtest china url changed
	wt_http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
3)
	# webtest foreign + china url changed
	wt_http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
esac
