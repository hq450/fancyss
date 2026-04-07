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

	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	[ -n "${node_id}" ] || return 1
	node_json="$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null)" || return 1
	[ -n "${node_json}" ] || return 1
	old_identity="$(printf '%s' "${node_json}" | jq -r '._identity // empty' 2>/dev/null)"
	updated_json="$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null)" || return 1
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
	;;
*)
	;;
esac

echo "fancyss"
