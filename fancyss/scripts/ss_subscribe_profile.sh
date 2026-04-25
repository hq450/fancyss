#!/bin/sh

source /koolshare/scripts/base.sh
[ -f /koolshare/scripts/ss_subscribe_profile_lib.sh ] && source /koolshare/scripts/ss_subscribe_profile_lib.sh
[ -f /koolshare/scripts/ss_node_common.sh ] && source /koolshare/scripts/ss_node_common.sh

LOG_FILE=/tmp/upload/ss_log.txt
NODE_TOOL_CONF_FILE="/koolshare/ss/rules/node-tool.conf"

profile_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

profile_cleanup_tmp_keys() {
	dbus remove "${SUB_PROFILE_TMP_PAYLOAD_KEY}" >/dev/null 2>&1 || true
	dbus remove "${SUB_PROFILE_TMP_ID_KEY}" >/dev/null 2>&1 || true
	dbus remove "${SUB_PROFILE_TMP_SYNC_ID_KEY}" >/dev/null 2>&1 || true
}

profile_lookup_airport_label_by_domain() {
	local domain_name="$1"
	[ -n "${domain_name}" ] || return 1
	[ -s "${NODE_TOOL_CONF_FILE}" ] || return 1
	awk -v domain_name="${domain_name}" '
		BEGIN {
			target = tolower(domain_name)
		}
		/^[[:space:]]*#/ || NF < 3 { next }
		tolower($1) == "domain" && tolower($2) == target {
			$1 = ""
			$2 = ""
			sub(/^[[:space:]]+/, "")
			print
			exit
		}
	' "${NODE_TOOL_CONF_FILE}" 2>/dev/null | sed -n '1p'
}

profile_remove_bound_nodes() {
	local profile_id="$1"
	local profile_json=""
	local last_group=""
	local last_url_hash=""
	local profile_url=""
	local profile_host=""
	local airport_identity=""
	local source_scope=""
	local node_id=""
	local keep_order=""
	local first_keep=""
	local max_keep="0"
	local removed_count="0"
	local current_id=""
	local failover_id=""
	local current_identity=""
	local failover_identity=""
	local fallback_current=""
	local node_scope=""
	local resolved_current=""
	local resolved_failover=""
	local node_tool=""
	local node_tool_output=""
	local node_tool_removed="0"
	local node_tool_removed_count="0"
	local reason_label="${2:-删除}"

	[ -n "${profile_id}" ] || return 0
	[ -f "/koolshare/scripts/ss_node_subscribe.sh" ] || return 0
	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	profile_json="$(subprof_merge_profile_and_state "${profile_id}" 2>/dev/null)" || profile_json=""
	[ -n "${profile_json}" ] || return 0
	last_group="$(printf '%s' "${profile_json}" | "$(subprof_jq_bin)" -r '.last_group // empty' 2>/dev/null)"
	last_url_hash="$(printf '%s' "${profile_json}" | "$(subprof_jq_bin)" -r '.last_url_hash // empty' 2>/dev/null)"
	profile_url="$(printf '%s' "${profile_json}" | "$(subprof_jq_bin)" -r '.url // empty' 2>/dev/null)"
	profile_host="$(subprof_extract_url_host "${profile_url}" 2>/dev/null)" || profile_host=""
	if [ -z "${last_group}" ] && [ -n "${profile_host}" ]; then
		last_group="$(profile_lookup_airport_label_by_domain "${profile_host}" 2>/dev/null)" || last_group=""
		[ -n "${last_group}" ] || last_group="${profile_host}"
	fi
	[ -n "${last_group}" ] || return 0
	airport_identity="$(fss_identity_slugify "${last_group}" "sub" 2>/dev/null)"
	[ -n "${airport_identity}" ] || return 0
	source_scope="${airport_identity}"
	[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"

	current_id="$(fss_get_current_node_id 2>/dev/null)" || current_id=""
	failover_id="$(fss_get_failover_node_id 2>/dev/null)" || failover_id=""
	[ -n "${current_id}" ] && current_identity="$(fss_get_node_identity_by_id "${current_id}" 2>/dev/null)" || current_identity=""
	[ -n "${failover_id}" ] && failover_identity="$(fss_get_node_identity_by_id "${failover_id}" 2>/dev/null)" || failover_identity=""
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || node_tool=""

	if [ -n "${node_tool}" ]; then
		node_tool_output="$("${node_tool}" delete-nodes --profile-id "${profile_id}" 2>/dev/null)" && {
			node_tool_removed_count="$(printf '%s\n' "${node_tool_output}" | awk -F': ' '$1 == "removed" {print $2; exit}' | sed -n '1p')"
			printf '%s' "${node_tool_removed_count}" | grep -Eq '^[0-9]+$' || node_tool_removed_count="0"
			[ "${node_tool_removed_count}" -gt "0" ] 2>/dev/null && node_tool_removed="1"
		}
	fi

	if [ "${node_tool_removed}" = "1" ]; then
		fss_clear_webtest_runtime_results
		fss_touch_node_catalog_ts >/dev/null 2>&1
		fss_touch_node_config_ts >/dev/null 2>&1
		profile_log "订阅配置${reason_label}，并按 _profile_id 清理对应节点：${profile_id} (${node_tool_removed_count} 个)"
		return 0
	fi

	for node_id in $(fss_list_node_ids)
	do
		[ -n "${node_id}" ] || continue
		node_scope="$(fss_get_node_source_scope_by_id "${node_id}" 2>/dev/null)" || node_scope=""
		if [ -n "${node_scope}" ] && [ "${node_scope}" = "${source_scope}" ]; then
			fss_clear_webtest_cache_node "${node_id}"
			dbus remove fss_node_${node_id}
			removed_count="$((removed_count + 1))"
		else
			keep_order="${keep_order}${keep_order:+,}${node_id}"
			[ -z "${first_keep}" ] && first_keep="${node_id}"
			if [ "${node_id}" -gt "${max_keep}" ] 2>/dev/null; then
				max_keep="${node_id}"
			fi
		fi
	done

	[ "${removed_count}" -gt "0" ] 2>/dev/null || return 0
	[ -n "${keep_order}" ] && dbus set fss_node_order="${keep_order}" || dbus remove fss_node_order
	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2 >/dev/null 2>&1 || true
	dbus set fss_node_next_id="$((max_keep + 1))"

	fallback_current="$(fss_get_first_node_id 2>/dev/null)" || fallback_current=""
	if [ -n "${current_id}" ] && fss_node_id_exists "${current_id}"; then
		fss_set_current_node_id "${current_id}"
	else
		resolved_current="$(fss_find_node_id_by_identity "${current_identity}" 2>/dev/null)" || resolved_current=""
		[ -n "${resolved_current}" ] && fss_set_current_node_id "${resolved_current}" || fss_set_current_node_id "${fallback_current}"
	fi
	if [ -n "${failover_id}" ] && fss_node_id_exists "${failover_id}"; then
		fss_set_failover_node_id "${failover_id}"
	else
		resolved_failover="$(fss_find_node_id_by_identity "${failover_identity}" 2>/dev/null)" || resolved_failover=""
		fss_set_failover_node_id "${resolved_failover}"
	fi

	fss_clear_webtest_runtime_results
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	fss_mark_native_schema2_storage >/dev/null 2>&1 || true
	profile_log "订阅配置${reason_label}，并回退按 _source_scope 清理对应节点：${profile_id} (${removed_count} 个)"
	return 0
}

profile_save() {
	local payload_json=""
	local profile_id=""

	payload_json="$(dbus get "${SUB_PROFILE_TMP_PAYLOAD_KEY}" | base64_decode 2>/dev/null)"
	[ -n "${payload_json}" ] || {
		profile_log "缺少订阅配置 payload。"
		return 1
	}
	if ! profile_id="$(subprof_write_profile_json "${payload_json}" 2>/dev/null)"; then
		profile_log "保存订阅配置失败，请检查别名和订阅链接。"
		return 1
	fi
	subprof_rebuild_cron_jobs >/dev/null 2>&1 || true
	profile_log "订阅配置已保存：${profile_id}"
	return 0
}

profile_delete() {
	local profile_id=""
	profile_id="$(dbus get "${SUB_PROFILE_TMP_ID_KEY}")"
	[ -n "${profile_id}" ] || {
		profile_log "缺少待删除的订阅配置 ID。"
		return 1
	}
	profile_remove_bound_nodes "${profile_id}" "删除" >/dev/null 2>&1 || true
	if ! subprof_remove_profile "${profile_id}"; then
		profile_log "删除订阅配置失败：${profile_id}"
		return 1
	fi
	subprof_rebuild_cron_jobs >/dev/null 2>&1 || true
	profile_log "已删除订阅配置：${profile_id}"
	return 0
}

profile_migrate_legacy() {
	local migrated=""
	migrated="$(subprof_migrate_legacy_profiles_if_needed 2>/dev/null)" || migrated=""
	if [ -n "${migrated}" ]; then
		subprof_rebuild_cron_jobs >/dev/null 2>&1 || true
		profile_log "已将旧版订阅地址拆分为 ${migrated} 个订阅配置。"
	else
		profile_log "未检测到需要迁移的旧版订阅地址。"
	fi
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

case "${ACTION}" in
save)
	true > "${LOG_FILE}"
	if profile_save >> "${LOG_FILE}" 2>&1; then
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	else
		echo XU6J03M6 >> "${LOG_FILE}"
		profile_cleanup_tmp_keys
		exit 1
	fi
	profile_cleanup_tmp_keys
	;;
delete)
	true > "${LOG_FILE}"
	if profile_delete >> "${LOG_FILE}" 2>&1; then
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	else
		echo XU6J03M6 >> "${LOG_FILE}"
		profile_cleanup_tmp_keys
		exit 1
	fi
	profile_cleanup_tmp_keys
	;;
migrate_legacy)
	true > "${LOG_FILE}"
	if profile_migrate_legacy >> "${LOG_FILE}" 2>&1; then
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	else
		echo XU6J03M6 >> "${LOG_FILE}"
		profile_cleanup_tmp_keys
		exit 1
	fi
	profile_cleanup_tmp_keys
	;;
*)
	true > "${LOG_FILE}"
	profile_log "未知操作：${ACTION}" >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	profile_cleanup_tmp_keys
	exit 1
	;;
esac
