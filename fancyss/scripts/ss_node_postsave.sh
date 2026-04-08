#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source "${KSROOT}/scripts/base.sh"
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source "${KSROOT}/scripts/ss_node_common.sh"
[ -f "${KSROOT}/scripts/ss_node_shunt.sh" ] && source "${KSROOT}/scripts/ss_node_shunt.sh"

fss_postsave_rebuild_identity_by_id() {
	local node_id="$1"
	local node_json=""
	local updated_json=""
	local old_identity=""
	local new_identity=""
	local source=""
	local airport_identity=""
	local source_scope=""
	local source_url_hash=""

	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	[ -n "${node_id}" ] || return 1
	node_json="$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null)" || return 1
	[ -n "${node_json}" ] || return 1
	old_identity="$(printf '%s' "${node_json}" | jq -r '._identity // empty' 2>/dev/null)"
	source="$(printf '%s' "${node_json}" | jq -r '._source // empty' 2>/dev/null)"
	airport_identity="$(printf '%s' "${node_json}" | jq -r '._airport_identity // empty' 2>/dev/null)"
	source_scope="$(printf '%s' "${node_json}" | jq -r '._source_scope // empty' 2>/dev/null)"
	source_url_hash="$(printf '%s' "${node_json}" | jq -r '._source_url_hash // empty' 2>/dev/null)"
	updated_json="$(fss_enrich_node_identity_json "${node_json}" "${airport_identity}" "${source_scope}" "${source_url_hash}" "${source}")" || return 1
	new_identity="$(printf '%s' "${updated_json}" | jq -r '._identity // empty' 2>/dev/null)"
	[ -n "${new_identity}" ] || return 1
	if [ "${updated_json}" != "${node_json}" ];then
		dbus set fss_node_${node_id}="$(fss_b64_encode "${updated_json}")"
	fi
	[ "${old_identity}" != "${new_identity}" ] && return 10
	return 0
}

rebuild_nodes_identity() {
	local ids_csv="$1"
	local node_id=""
	local touched=0
	local identity_changed=0

	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		fss_postsave_rebuild_identity_by_id "${node_id}" >/dev/null 2>&1
		case "$?" in
		0)
			touched=1
			;;
		10)
			touched=1
			identity_changed=1
			;;
		esac
	done <<-EOF
$(printf '%s' "${ids_csv}" | tr ',' '\n' | sed '/^$/d')
	EOF

	if [ "${touched}" = "1" ];then
		fss_sync_reference_identity_shadows >/dev/null 2>&1 || true
		fss_shunt_sync_identity_shadows >/dev/null 2>&1 || true
		fss_touch_node_config_ts >/dev/null 2>&1 || true
		fss_touch_node_catalog_ts >/dev/null 2>&1 || true
	fi
	[ "${identity_changed}" = "1" ] && fss_clear_webtest_runtime_results >/dev/null 2>&1 || true
}

compact_node_ids_if_needed() {
	local threshold="${FSS_NODE_ID_COMPACT_THRESHOLD:-9999}"
	local next_id=""
	local node_tool=""

	printf '%s' "${threshold}" | grep -Eq '^[0-9]+$' || threshold="9999"
	next_id="$(dbus get fss_node_next_id)"
	printf '%s' "${next_id}" | grep -Eq '^[0-9]+$' || return 0
	[ "${next_id}" -gt "${threshold}" ] || return 0

	node_tool="$(fss_pick_node_tool 2>/dev/null)" || return 0
	fss_node_tool_supports_command "${node_tool}" "compact-ids" || return 0
	"${node_tool}" compact-ids >/dev/null 2>&1 || return 1
	fss_clear_webtest_cache_all >/dev/null 2>&1 || true
	fss_clear_webtest_runtime_results >/dev/null 2>&1 || true
	fss_refresh_node_direct_cache >/dev/null 2>&1 || true
	return 0
}

ACTION=""
IDS=""
if [ "$1" = "rebuild" ];then
	ACTION="$1"
	IDS="$2"
elif [ -n "$3" ];then
	ACTION="$2"
	IDS="$3"
elif [ -n "$2" ];then
	ACTION="$2"
	IDS="$3"
elif [ -n "$1" ];then
	ACTION="$1"
fi

case "${ACTION}" in
rebuild)
	rebuild_nodes_identity "${IDS}"
	compact_node_ids_if_needed >/dev/null 2>&1 || true
	;;
*)
	;;
esac

echo "fancyss"
