#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_subscribe_profile_lib.sh" ] && source ${KSROOT}/scripts/ss_subscribe_profile_lib.sh
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source ${KSROOT}/scripts/ss_node_common.sh

reconcile_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

reconcile_profile_scope_row() {
	local profile_id="$1"
	local profile_key=""
	local state_key=""
	local profile_json=""
	local state_json=""
	local jq_bin=""
	local profile_name=""
	local profile_url=""
	local last_group=""
	local last_url_hash=""
	local airport_identity=""
	local source_scope=""

	[ -n "${profile_id}" ] || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || return 1
	[ -n "${profile_json}" ] || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
	jq_bin="$(subprof_jq_bin)" || return 1

	profile_name="$(printf '%s' "${profile_json}" | "${jq_bin}" -r '.name // empty' 2>/dev/null | sed -n '1p')"
	profile_url="$(printf '%s' "${profile_json}" | "${jq_bin}" -r '.url // empty' 2>/dev/null | sed -n '1p')"
	if [ -n "${state_json}" ]; then
		last_group="$(printf '%s' "${state_json}" | "${jq_bin}" -r '.last_group // empty' 2>/dev/null | sed -n '1p')"
		last_url_hash="$(printf '%s' "${state_json}" | "${jq_bin}" -r '.last_url_hash // empty' 2>/dev/null | sed -n '1p')"
	fi
	[ -n "${last_group}" ] || last_group="${profile_name}"
	if [ -z "${last_group}" ] && [ -n "${profile_url}" ]; then
		last_group="$(subprof_pretty_name_from_url "${profile_url}" 2>/dev/null)" || last_group=""
	fi
	if [ -z "${last_url_hash}" ] && [ -n "${profile_url}" ]; then
		last_url_hash="$(printf '%s' "${profile_url}" | md5sum | awk '{print substr($1,1,4)}')"
	fi
	[ -n "${last_group}" ] || return 1
	airport_identity="$(fss_identity_slugify "${last_group}" "sub" 2>/dev/null)"
	[ -n "${airport_identity}" ] || return 1
	source_scope="profile_${profile_id}"
	printf '%s\t%s\t%s\t%s\n' "${source_scope}" "${profile_id}" "${last_group}" "${last_url_hash}"
}

reconcile_collect_profile_scope_map() {
	local output_file="$1"
	local profile_id=""
	local row=""

	[ -n "${output_file}" ] || return 1
	: > "${output_file}"
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		row="$(reconcile_profile_scope_row "${profile_id}" 2>/dev/null)" || row=""
		[ -n "${row}" ] || continue
		printf '%s\n' "${row}" >> "${output_file}"
	done
	[ -s "${output_file}" ]
}

reconcile_collect_pending_nodes_fast() {
	local output_file="$1"
	local node_tool=""
	local jq_bin=""
	local nodes_file=""

	[ -n "${output_file}" ] || return 1
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || return 1
	fss_node_tool_supports_command "${node_tool}" "node2json" || return 1
	jq_bin="$(subprof_jq_bin)" || return 1
	nodes_file="/tmp/.fss_profile_reconcile_nodes.$$"
	if ! "${node_tool}" node2json --source subscribe --format json > "${nodes_file}" 2>/dev/null; then
		rm -f "${nodes_file}" "${output_file}"
		return 1
	fi
	"${jq_bin}" -r '.[]? | select((._source_scope // "") != "" and (._source_scope // "") != "local" and ((._profile_id // "") == "")) | @base64' "${nodes_file}" > "${output_file}" 2>/dev/null || {
		rm -f "${nodes_file}" "${output_file}"
		return 1
	}
	rm -f "${nodes_file}"
	return 0
}

reconcile_apply_pending_nodes_fast() {
	local profile_map_file="$1"
	local pending_file="$2"
	local jq_bin=""
	local row_b64=""
	local node_json=""
	local node_id=""
	local source_scope=""
	local profile_id=""
	local updated_json=""
	local touched="0"
	local touched_count=0

	[ -s "${profile_map_file}" ] || return 0
	[ -f "${pending_file}" ] || return 0
	jq_bin="$(subprof_jq_bin)" || return 1

	while IFS= read -r row_b64
	do
		[ -n "${row_b64}" ] || continue
		node_json="$(printf '%s' "${row_b64}" | base64_decode 2>/dev/null)" || continue
		[ -n "${node_json}" ] || continue
		node_id="$(printf '%s' "${node_json}" | "${jq_bin}" -r '._id // empty' 2>/dev/null)"
		source_scope="$(printf '%s' "${node_json}" | "${jq_bin}" -r '._source_scope // empty' 2>/dev/null)"
		[ -n "${node_id}" ] || continue
		[ -n "${source_scope}" ] || continue
		profile_id="$(awk -F '\t' -v scope="${source_scope}" '$1 == scope {print $2; exit}' "${profile_map_file}" 2>/dev/null | sed -n '1p')"
		[ -n "${profile_id}" ] || continue
		updated_json="$(printf '%s' "${node_json}" | "${jq_bin}" -c --arg profile_id "${profile_id}" '._profile_id = $profile_id' 2>/dev/null)" || continue
		dbus set fss_node_${node_id}="$(fss_b64_encode "${updated_json}")"
		reconcile_log "回填节点 _profile_id：node=${node_id}, profile=${profile_id}, scope=${source_scope}"
		touched="1"
		touched_count=$((touched_count + 1))
	done < "${pending_file}"

	[ "${touched}" = "1" ] || return 0
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	reconcile_log "快速回填完成：${touched_count} 个节点。"
	return 0
}

reconcile_profile_nodes_legacy() {
	local profile_id="$1"
	local source_scope="$2"
	local node_id=""
	local node_json=""
	local node_scope=""
	local node_profile_id=""
	local updated_json=""
	local touched="0"
	local touched_count=0

	[ -n "${profile_id}" ] || return 0
	[ -n "${source_scope}" ] || return 0
	for node_id in $(fss_list_node_ids)
	do
		[ -n "${node_id}" ] || continue
		node_json="$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null)" || continue
		[ -n "${node_json}" ] || continue
		node_scope="$(printf '%s' "${node_json}" | jq -r '._source_scope // empty' 2>/dev/null)"
		[ "${node_scope}" = "${source_scope}" ] || continue
		node_profile_id="$(printf '%s' "${node_json}" | jq -r '._profile_id // empty' 2>/dev/null)"
		[ -n "${node_profile_id}" ] && continue
		updated_json="$(printf '%s' "${node_json}" | jq -c --arg profile_id "${profile_id}" '._profile_id = $profile_id' 2>/dev/null)" || continue
		dbus set fss_node_${node_id}="$(fss_b64_encode "${updated_json}")"
		reconcile_log "回填节点 _profile_id：node=${node_id}, profile=${profile_id}, scope=${source_scope}"
		touched="1"
		touched_count=$((touched_count + 1))
	done
	[ "${touched}" = "1" ] || return 0
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	reconcile_log "兼容回填完成：${touched_count} 个节点。"
	return 0
}

reconcile_run_legacy() {
	local profile_map_file="$1"
	local source_scope=""
	local profile_id=""

	[ -s "${profile_map_file}" ] || return 0
	while IFS='	' read -r source_scope profile_id _
	do
		[ -n "${source_scope}" ] || continue
		[ -n "${profile_id}" ] || continue
		reconcile_profile_nodes_legacy "${profile_id}" "${source_scope}" || true
	done < "${profile_map_file}"
}

reconcile_main() {
	local profile_map_file="/tmp/.fss_profile_scope_map.$$"
	local pending_file="/tmp/.fss_profile_pending.$$"

	[ "$(fss_detect_storage_schema)" = "2" ] || {
		reconcile_log "当前不是 schema2，跳过 _profile_id 回填。"
		return 0
	}
	reconcile_collect_profile_scope_map "${profile_map_file}" || {
		rm -f "${profile_map_file}" "${pending_file}"
		reconcile_log "未检测到可用于回填的订阅 profile。"
		return 0
	}
	if reconcile_collect_pending_nodes_fast "${pending_file}"; then
		reconcile_apply_pending_nodes_fast "${profile_map_file}" "${pending_file}" || true
	else
		reconcile_run_legacy "${profile_map_file}" || true
	fi
	rm -f "${profile_map_file}" "${pending_file}"
}

reconcile_main "$@"
