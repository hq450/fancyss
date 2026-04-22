#!/bin/sh

source /koolshare/scripts/base.sh
[ -f /koolshare/scripts/ss_node_common.sh ] && source /koolshare/scripts/ss_node_common.sh
[ -f /koolshare/scripts/ss_subscribe_profile_lib.sh ] && source /koolshare/scripts/ss_subscribe_profile_lib.sh

LOG_FILE=/tmp/upload/ss_log.txt
NODE_SUMMARY_FILE=/tmp/upload/ss_node_summary.json
NODE_SUMMARY_TMP_EFFECTIVE_KEY="ss_node_summary_effective"
NODE_SUMMARY_TMP_PROFILE_ID_KEY="ss_node_summary_profile_id"
NODE_SUMMARY_TMP_SOURCE_KEY="ss_node_summary_source"
NODE_SUMMARY_TMP_SOURCE_TAG_KEY="ss_node_summary_source_tag"
NODE_SUMMARY_TMP_AIRPORT_KEY="ss_node_summary_airport_identity"

node_data_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

node_data_cleanup_tmp_keys() {
	dbus remove "${NODE_SUMMARY_TMP_EFFECTIVE_KEY}" >/dev/null 2>&1 || true
	dbus remove "${NODE_SUMMARY_TMP_PROFILE_ID_KEY}" >/dev/null 2>&1 || true
	dbus remove "${NODE_SUMMARY_TMP_SOURCE_KEY}" >/dev/null 2>&1 || true
	dbus remove "${NODE_SUMMARY_TMP_SOURCE_TAG_KEY}" >/dev/null 2>&1 || true
	dbus remove "${NODE_SUMMARY_TMP_AIRPORT_KEY}" >/dev/null 2>&1 || true
}

node_data_pick_jq() {
	if [ -x "/koolshare/bin/jq" ]; then
		echo "/koolshare/bin/jq"
		return 0
	fi
	command -v jq 2>/dev/null
}

node_data_write_profiles_json() {
	local jq_bin="$1"
	local output_file="$2"
	local profile_id=""
	local row=""
	local first=1

	[ -n "${jq_bin}" ] || return 1
	[ -n "${output_file}" ] || return 1
	{
		printf '{"version":1,"items":['
		for profile_id in $(subprof_list_profile_ids)
		do
			[ -n "${profile_id}" ] || continue
			row="$(subprof_merge_profile_and_state "${profile_id}" 2>/dev/null)" || row=""
			[ -n "${row}" ] || continue
			if [ "${first}" = "1" ]; then
				first=0
			else
				printf ','
			fi
			printf '%s' "${row}"
		done
		printf ']}'
	} > "${output_file}" || return 1
	"${jq_bin}" -c '.' "${output_file}" >/dev/null 2>&1 || return 1
}

node_data_write_summary() {
	local node_tool=""
	local jq_bin=""
	local effective=""
	local profile_id=""
	local source=""
	local source_tag=""
	local airport_identity=""
	local list_file="${NODE_SUMMARY_FILE}.list.$$"
	local stat_file="${NODE_SUMMARY_FILE}.stat.$$"
	local profiles_file="${NODE_SUMMARY_FILE}.profiles.$$"
	local output_tmp="${NODE_SUMMARY_FILE}.tmp.$$"
	local generated_at=""

	node_tool="$(fss_pick_node_tool 2>/dev/null)" || {
		node_data_log "未找到 node-tool，无法生成节点摘要。"
		return 1
	}
	jq_bin="$(node_data_pick_jq)" || {
		node_data_log "未找到 jq，无法生成节点摘要。"
		return 1
	}

	effective="$(dbus get ${NODE_SUMMARY_TMP_EFFECTIVE_KEY})"
	profile_id="$(dbus get ${NODE_SUMMARY_TMP_PROFILE_ID_KEY})"
	source="$(dbus get ${NODE_SUMMARY_TMP_SOURCE_KEY})"
	source_tag="$(dbus get ${NODE_SUMMARY_TMP_SOURCE_TAG_KEY})"
	airport_identity="$(dbus get ${NODE_SUMMARY_TMP_AIRPORT_KEY})"
	generated_at="$(date +%s)"

	set -- list --format json
	[ "${effective}" = "1" ] && set -- "$@" --effective
	[ -n "${profile_id}" ] && set -- "$@" --profile-id "${profile_id}"
	[ -n "${source}" ] && set -- "$@" --source "${source}"
	[ -n "${source_tag}" ] && set -- "$@" --source-tag "${source_tag}"
	[ -n "${airport_identity}" ] && set -- "$@" --airport-identity "${airport_identity}"
	"${node_tool}" "$@" > "${list_file}" 2>/dev/null || {
		rm -f "${list_file}" "${stat_file}" "${output_tmp}"
		node_data_log "node-tool list 生成节点摘要失败。"
		return 1
	}

	set -- stat --format json
	[ "${effective}" = "1" ] && set -- "$@" --effective
	[ -n "${profile_id}" ] && set -- "$@" --profile-id "${profile_id}"
	[ -n "${source}" ] && set -- "$@" --source "${source}"
	[ -n "${source_tag}" ] && set -- "$@" --source-tag "${source_tag}"
	[ -n "${airport_identity}" ] && set -- "$@" --airport-identity "${airport_identity}"
	"${node_tool}" "$@" > "${stat_file}" 2>/dev/null || {
		rm -f "${list_file}" "${stat_file}" "${profiles_file}" "${output_tmp}"
		node_data_log "node-tool stat 生成节点摘要失败。"
		return 1
	}

	node_data_write_profiles_json "${jq_bin}" "${profiles_file}" || {
		rm -f "${list_file}" "${stat_file}" "${profiles_file}" "${output_tmp}"
		node_data_log "订阅配置快照生成失败。"
		return 1
	}

	"${jq_bin}" -cn \
		--slurpfile profiles "${profiles_file}" \
		--argjson generated_at "${generated_at}" \
		--argjson items "$("${jq_bin}" -c '.' "${list_file}")" \
		--argjson stat "$("${jq_bin}" -c '.' "${stat_file}")" \
		'
		def profile_map($raw):
			(($raw[0].items // []) | map({key: (.id // ""), value: .}) | from_entries);
		def airport_label($item):
			if ($item.source // "") == "subscribe" and (($item.group // "") | test("_[0-9a-f]{4}$")) then
				($item.group | sub("_[0-9a-f]{4}$"; ""))
			elif ($item.airport_identity // "") != "" then
				$item.airport_identity
			else
				"local"
			end;
		def bucket_key($item; $profile):
			if ($item.profile_id // "") != "" then
				$item.profile_id
			elif ($item.source // "") == "subscribe" and ($item.source_tag // "") != "" then
				$item.source_tag
			else
				"local"
			end;
		def bucket_label($item; $profile):
			if ($profile.name // "") != "" then
				$profile.name
			elif ($item.source // "") == "subscribe" then
				airport_label($item)
			else
				"本地节点"
			end;
		(profile_map($profiles)) as $profile_map
		| {
			version: 1,
			generated_at: $generated_at,
			items: (
				$items | map(
					. as $item
					| ($profile_map[$item.profile_id] // {}) as $profile
					| ($item.profile_id == null or $item.profile_id == "" or (($profile.enabled // true) == true)) as $effective
					| {
						id: ($item.id // ""),
						name: ($item.name // ""),
						type: ($item.protocol // ""),
						type_label: ($item.protocol_label // ""),
						server: ($item.server // ""),
						port: ($item.port // ""),
						latency: ($item.latency // ""),
						ping: ($item.ping // ""),
						group: ($item.group // ""),
						source: ($item.source // ""),
						source_tag: ($item.source_tag // ""),
						profile_id: ($item.profile_id // ""),
						profile_name: ($profile.name // ""),
						profile_enabled: ($profile.enabled // true),
						effective: $effective,
						airport_identity: ($item.airport_identity // ""),
						airport_label: airport_label($item),
						source_bucket_key: bucket_key($item; $profile),
						source_bucket_label: bucket_label($item; $profile),
						identity: ($item.identity // "")
					}
				)
			),
			stat: $stat
		}
		' > "${output_tmp}" 2>/dev/null || {
		rm -f "${list_file}" "${stat_file}" "${profiles_file}" "${output_tmp}"
		node_data_log "节点摘要 JSON 封装失败。"
		return 1
	}

	mv -f "${output_tmp}" "${NODE_SUMMARY_FILE}"
	rm -f "${list_file}" "${stat_file}" "${profiles_file}"
	node_data_log "节点摘要已刷新：${NODE_SUMMARY_FILE}"
	return 0
}

ACTION="$1"
WEB_ACTION=0
if [ -z "$2" -a -n "$1" ]; then
	ACTION="$1"
	WEB_ACTION=0
elif [ -n "$2" -a -n "$1" ]; then
	ACTION="$2"
	WEB_ACTION=1
fi
[ -z "${ACTION}" ] && ACTION="summary"

case "${ACTION}" in
summary)
	true > "${LOG_FILE}"
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	node_data_write_summary >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	node_data_cleanup_tmp_keys
	;;
*)
	true > "${LOG_FILE}"
	node_data_log "未知操作：${ACTION}" >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	node_data_cleanup_tmp_keys
	exit 1
	;;
esac
