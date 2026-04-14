#!/bin/sh

source /koolshare/scripts/base.sh
[ -f /koolshare/scripts/ss_subscribe_profile_lib.sh ] && source /koolshare/scripts/ss_subscribe_profile_lib.sh

LOG_FILE=/tmp/upload/ss_log.txt

profile_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

profile_cleanup_tmp_keys() {
	dbus remove "${SUB_PROFILE_TMP_PAYLOAD_KEY}" >/dev/null 2>&1 || true
	dbus remove "${SUB_PROFILE_TMP_ID_KEY}" >/dev/null 2>&1 || true
	dbus remove "${SUB_PROFILE_TMP_SYNC_ID_KEY}" >/dev/null 2>&1 || true
}

profile_write_list() {
	if subprof_write_profiles_runtime_json; then
		profile_log "订阅配置清单已刷新。"
	else
		profile_log "生成订阅配置清单失败。"
		return 1
	fi
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
	profile_write_list || return 1
	return 0
}

profile_delete() {
	local profile_id=""
	profile_id="$(dbus get "${SUB_PROFILE_TMP_ID_KEY}")"
	[ -n "${profile_id}" ] || {
		profile_log "缺少待删除的订阅配置 ID。"
		return 1
	}
	if ! subprof_remove_profile "${profile_id}"; then
		profile_log "删除订阅配置失败：${profile_id}"
		return 1
	fi
	subprof_rebuild_cron_jobs >/dev/null 2>&1 || true
	profile_log "已删除订阅配置：${profile_id}"
	profile_write_list || return 1
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
	profile_write_list || return 1
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
[ -z "${ACTION}" ] && ACTION="list"

case "${ACTION}" in
list)
	true > "${LOG_FILE}"
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	profile_write_list >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	profile_cleanup_tmp_keys
	;;
save)
	true > "${LOG_FILE}"
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	profile_save >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	profile_cleanup_tmp_keys
	;;
delete)
	true > "${LOG_FILE}"
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	profile_delete >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	profile_cleanup_tmp_keys
	;;
migrate_legacy)
	true > "${LOG_FILE}"
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	profile_migrate_legacy >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
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
