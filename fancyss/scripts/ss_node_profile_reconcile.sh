#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_subscribe_profile_lib.sh" ] && source ${KSROOT}/scripts/ss_subscribe_profile_lib.sh
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source ${KSROOT}/scripts/ss_node_common.sh

reconcile_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

reconcile_profile_scope() {
	local profile_id="$1"
	local row_json="$2"
	local last_group=""
	local last_url_hash=""
	local airport_identity=""
	local source_scope=""

	[ -n "${profile_id}" ] || return 1
	[ -n "${row_json}" ] || return 1
	last_group="$(printf '%s' "${row_json}" | "$(subprof_jq_bin)" -r '.last_group // empty' 2>/dev/null)"
	last_url_hash="$(printf '%s' "${row_json}" | "$(subprof_jq_bin)" -r '.last_url_hash // empty' 2>/dev/null)"
	[ -n "${last_group}" ] || return 1
	airport_identity="$(fss_identity_slugify "${last_group}" "sub" 2>/dev/null)"
	[ -n "${airport_identity}" ] || return 1
	source_scope="${airport_identity}"
	[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"
	printf '%s\n' "${source_scope}"
}

reconcile_profile_nodes() {
	local profile_id="$1"
	local row_json="$2"
	local source_scope=""
	local node_id=""
	local node_json=""
	local node_scope=""
	local node_profile_id=""
	local updated_json=""
	local touched="0"

	source_scope="$(reconcile_profile_scope "${profile_id}" "${row_json}" 2>/dev/null)" || return 0
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
	done
	[ "${touched}" = "1" ] || return 0
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	return 0
}

reconcile_main() {
	local runtime_json=""
	local row_json=""
	local profile_id=""

	[ "$(fss_detect_storage_schema)" = "2" ] || {
		reconcile_log "当前不是 schema2，跳过 _profile_id 回填。"
		return 0
	}
	runtime_json="$(subprof_runtime_json_file 2>/dev/null)" || runtime_json="/tmp/upload/ss_subscribe_profiles.json"
	[ -f "${runtime_json}" ] || subprof_write_profiles_runtime_json >/dev/null 2>&1 || true
	[ -f "${runtime_json}" ] || {
		reconcile_log "未找到订阅 profile runtime 文件，跳过。"
		return 0
	}

	while IFS= read -r row_json
	do
		[ -n "${row_json}" ] || continue
		profile_id="$(printf '%s' "${row_json}" | "$(subprof_jq_bin)" -r '.id // empty' 2>/dev/null)"
		[ -n "${profile_id}" ] || continue
		reconcile_profile_nodes "${profile_id}" "${row_json}" || true
	done <<-EOF
$(cat "${runtime_json}" 2>/dev/null | "$(subprof_jq_bin)" -c '.items[]?')
	EOF
}

reconcile_main "$@"
