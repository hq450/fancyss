#!/bin/sh

source /koolshare/scripts/ss_base.sh
source /koolshare/scripts/ss_node_shunt.sh

XRAY_API_SERVER="127.0.0.1:10085"
XAPI_TOOL_BIN="/koolshare/bin/xapi-tool"
HOT_STATE_DIR="/tmp/fancyss_shunt_hot_reload"
HOT_BASE_FILE="${HOT_STATE_DIR}/base.tsv"
HOT_LAST_FILE="${HOT_STATE_DIR}/applied.tsv"
HOT_NEXT_FILE="${HOT_STATE_DIR}/next.tsv"
HOT_STAGE_FILE="${HOT_STATE_DIR}/stage.tsv"
HOT_LOCK_FILE="/var/lock/fss_shunt_hot_reload.lock"
HOT_BASE_RULE_TS_FILE="${HOT_STATE_DIR}/base_rule_ts"
HOT_APPLIED_RULE_TS_FILE="${HOT_STATE_DIR}/applied_rule_ts"
HOT_BASE_RULES_B64_FILE="${HOT_STATE_DIR}/base_rules.b64"
HOT_BASE_DEFAULT_FILE="${HOT_STATE_DIR}/base_default_node"

hot_log() {
	echo_date "[hot-reload] $*"
}

hot_ensure_state_dir() {
	mkdir -p "${HOT_STATE_DIR}" >/dev/null 2>&1 || return 1
}

hot_require_ready() {
	fss_shunt_mode_selected || {
		hot_log "当前不是 xray 分流模式，跳过。"
		return 1
	}
	[ -x "${XAPI_TOOL_BIN}" ] || {
		hot_log "缺少 xapi-tool，无法执行热重载。"
		return 1
	}
	pidof xray >/dev/null 2>&1 || {
		hot_log "Xray 未运行，无法执行热重载。"
		return 1
	}
	return 0
}

hot_runtime_target_tag() {
	local target_id="$1"
	if fss_shunt_target_is_direct "${target_id}"; then
		echo direct
	elif fss_shunt_target_is_reject "${target_id}"; then
		echo reject
	else
		echo "proxy${target_id}"
	fi
}

hot_target_loaded() {
	local target_id="$1"
	local tag="$(hot_runtime_target_tag "${target_id}")"
	grep -q '"tag"[[:space:]]*:[[:space:]]*"'"${tag}"'"' /koolshare/ss/xray.json 2>/dev/null
}

hot_build_next_state() {
	hot_ensure_state_dir || return 1
	fss_shunt_cleanup_runtime >/dev/null 2>&1 || true
	fss_shunt_prepare_runtime || return 1
	fss_shunt_write_hot_reload_state "${HOT_NEXT_FILE}" || return 1
	return 0
}

hot_verify_targets_loaded() {
	local line tag target_id domain_files ip_files domain_rules ip_rules place
	[ -s "${HOT_NEXT_FILE}" ] || return 0
	while IFS='|' read -r tag target_id domain_files ip_files domain_rules ip_rules place
	do
		[ -n "${target_id}" ] || continue
		hot_target_loaded "${target_id}" || {
			hot_log "目标出站 ${target_id} 当前未加载到运行中的 xray，需冷启动完整重建。"
			return 1
		}
	done < "${HOT_NEXT_FILE}"
	return 0
}

hot_remove_rule() {
	local tag="$1"
	[ -n "${tag}" ] || return 0
	run "${XAPI_TOOL_BIN}" routing-remove-rule --server "${XRAY_API_SERVER}" --rule-tag "${tag}" >/dev/null 2>&1 || return 1
}

hot_add_rule() {
	local tag="$1"
	local target_id="$2"
	local domain_files="$3"
	local ip_files="$4"
	local domain_rules="$5"
	local ip_rules="$6"
	local part=""
	local ip_rule_file=""
	local target_tag="$(hot_runtime_target_tag "${target_id}")"
	set -- routing-add-rule --server "${XRAY_API_SERVER}" --rule-tag "${tag}" --target-tag "${target_tag}"
	if [ -n "${domain_files}" ]; then
		set -- "$@" --domain-file "${domain_files}"
	fi
	if [ -n "${domain_rules}" ]; then
		OLDIFS="$IFS"
		IFS=','
		for part in ${domain_rules}
		do
			[ -n "${part}" ] || continue
			set -- "$@" --domain-rule "${part}"
		done
		IFS="$OLDIFS"
	fi
	if [ -n "${ip_files}" ]; then
		OLDIFS="$IFS"
		IFS=','
		for part in ${ip_files}
		do
			[ -n "${part}" ] || continue
			set -- "$@" --ip-file "${part}"
		done
		IFS="$OLDIFS"
	fi
	if [ -n "${ip_rules}" ]; then
		ip_rule_file="${HOT_STATE_DIR}/.${tag}.iprules.$$"
		printf '%s\n' "${ip_rules}" | tr ',' '\n' > "${ip_rule_file}"
		set -- "$@" --ip-file "${ip_rule_file}"
	fi
	if [ -z "${domain_files}${ip_files}${domain_rules}${ip_rules}" ]; then
		set -- "$@" --match-all
	fi
	run "${XAPI_TOOL_BIN}" "$@" >/dev/null 2>&1
	local ret=$?
	rm -f "${ip_rule_file}" >/dev/null 2>&1 || true
	[ "${ret}" = "0" ] || return 1
}

hot_reverse_rules_file() {
	local src_file="$1"
	local out_file="$2"

	[ -f "${src_file}" ] || return 1
	awk '{lines[NR]=$0} END {for (i=NR; i>=1; i--) print lines[i]}' "${src_file}" > "${out_file}"
}

hot_remove_rules_from_file() {
	local src_file="$1"
	local reverse="${2:-0}"
	local read_file="${src_file}"
	local reverse_file=""
	local old_tag=""

	[ -s "${src_file}" ] || return 0
	if [ "${reverse}" = "1" ]; then
		reverse_file="${HOT_STATE_DIR}/reverse.$$"
		hot_reverse_rules_file "${src_file}" "${reverse_file}" || return 1
		read_file="${reverse_file}"
	fi
	while IFS='|' read -r old_tag _
	do
		[ -n "${old_tag}" ] || continue
		hot_log "删除托管规则：${old_tag}"
		hot_remove_rule "${old_tag}" || {
			rm -f "${reverse_file}" >/dev/null 2>&1
			return 1
		}
	done < "${read_file}"
	rm -f "${reverse_file}" >/dev/null 2>&1
	return 0
}

hot_runtime_managed_rule_tags() {
	run "${XAPI_TOOL_BIN}" routing-list-rule --server "${XRAY_API_SERVER}" 2>/dev/null | run jq -r '.rules[]? | (.rule_tag // empty)' 2>/dev/null | awk '/^fss_/'
}

hot_remove_runtime_rules_except() {
	local keep_file="$1"
	local runtime_tags_file="${HOT_STATE_DIR}/runtime_tags.$$"
	local reverse_file="${HOT_STATE_DIR}/runtime_reverse.$$"
	local old_tag=""

	hot_runtime_managed_rule_tags > "${runtime_tags_file}" 2>/dev/null || true
	[ -s "${runtime_tags_file}" ] || {
		rm -f "${runtime_tags_file}" >/dev/null 2>&1
		return 0
	}
	hot_reverse_rules_file "${runtime_tags_file}" "${reverse_file}" || {
		rm -f "${runtime_tags_file}" >/dev/null 2>&1
		return 1
	}
	while IFS= read -r old_tag
	do
		[ -n "${old_tag}" ] || continue
		if [ -n "${keep_file}" ] && [ -f "${keep_file}" ] && grep -q '^'"${old_tag}"'|' "${keep_file}" 2>/dev/null; then
			continue
		fi
		hot_log "删除旧规则：${old_tag}"
		hot_remove_rule "${old_tag}" || {
			rm -f "${runtime_tags_file}" "${reverse_file}" >/dev/null 2>&1
			return 1
		}
	done < "${reverse_file}"
	rm -f "${runtime_tags_file}" "${reverse_file}" >/dev/null 2>&1
	return 0
}

hot_apply_rules_from_file() {
	local src_file="$1"
	local tag=""
	local target_id=""
	local domain_files=""
	local ip_files=""
	local domain_rules=""
	local ip_rules=""
	local place=""

	[ -s "${src_file}" ] || return 0
	while IFS='|' read -r tag target_id domain_files ip_files domain_rules ip_rules place
	do
		[ -n "${tag}" ] || continue
		hot_log "追加新规则：${tag} -> ${target_id}"
		hot_add_rule "${tag}" "${target_id}" "${domain_files}" "${ip_files}" "${domain_rules}" "${ip_rules}" || return 1
	done < "${src_file}"
	return 0
}

hot_remove_all_managed_rules() {
	hot_remove_rules_from_file "${HOT_LAST_FILE}"
}

hot_apply_all_rules() {
	hot_apply_rules_from_file "${HOT_NEXT_FILE}"
}

hot_remove_staged_rules() {
	hot_remove_rules_from_file "${HOT_STAGE_FILE}" 1
}

hot_apply_staged_rules() {
	hot_apply_rules_from_file "${HOT_STAGE_FILE}"
}

hot_seed_state() {
	cp -f "${HOT_NEXT_FILE}" "${HOT_BASE_FILE}" >/dev/null 2>&1
	cp -f "${HOT_NEXT_FILE}" "${HOT_LAST_FILE}" >/dev/null 2>&1
	printf '%s\n' "$(hot_current_rule_ts)" > "${HOT_BASE_RULE_TS_FILE}"
	printf '%s\n' "$(hot_current_rule_ts)" > "${HOT_APPLIED_RULE_TS_FILE}"
	dbus get ss_basic_shunt_rules > "${HOT_BASE_RULES_B64_FILE}"
	dbus get ss_basic_shunt_default_node > "${HOT_BASE_DEFAULT_FILE}"
}

hot_current_rule_ts() {
	local ts="${ss_basic_shunt_rule_ts:-$(dbus get ss_basic_shunt_rule_ts)}"
	printf '%s\n' "${ts}"
}

hot_seed_exists() {
	[ -s "${HOT_BASE_FILE}" ] && [ -s "${HOT_BASE_RULE_TS_FILE}" ] && [ -s "${HOT_LAST_FILE}" ] && [ -s "${HOT_APPLIED_RULE_TS_FILE}" ] && [ -f "${HOT_BASE_RULES_B64_FILE}" ] && [ -f "${HOT_BASE_DEFAULT_FILE}" ]
}

hot_seed_matches_current() {
	[ -s "${HOT_LAST_FILE}" ] && [ -s "${HOT_APPLIED_RULE_TS_FILE}" ] || return 1
	local current_ts="$(hot_current_rule_ts)"
	local saved_ts="$(sed -n '1p' "${HOT_APPLIED_RULE_TS_FILE}" 2>/dev/null)"
	[ -n "${current_ts}" ] || current_ts="0"
	[ -n "${saved_ts}" ] || saved_ts="0"
	[ "${current_ts}" = "${saved_ts}" ]
}

hot_clear_state() {
	rm -rf "${HOT_STATE_DIR}" >/dev/null 2>&1
}

hot_mark_applied_state() {
	local src_file="${1:-${HOT_NEXT_FILE}}"
	cp -f "${src_file}" "${HOT_LAST_FILE}" >/dev/null 2>&1
	printf '%s\n' "$(hot_current_rule_ts)" > "${HOT_APPLIED_RULE_TS_FILE}"
}

hot_make_stage_tag() {
	local base_tag="$1"
	local generation="$2"
	[ -n "${base_tag}" ] || return 1
	[ -n "${generation}" ] || return 1
	printf '%s__%s\n' "${base_tag}" "${generation}"
}

hot_build_stage_state() {
	local generation="$1"
	local src_file="${2:-${HOT_NEXT_FILE}}"
	local out_file="${3:-${HOT_STAGE_FILE}}"
	local tag=""
	local target_id=""
	local domain_files=""
	local ip_files=""
	local domain_rules=""
	local ip_rules=""
	local place=""

	[ -n "${generation}" ] || return 1
	[ -f "${src_file}" ] || return 1
	: > "${out_file}" || return 1
	while IFS='|' read -r tag target_id domain_files ip_files domain_rules ip_rules place
	do
		[ -n "${tag}" ] || continue
		printf '%s|%s|%s|%s|%s|%s|%s\n' \
			"$(hot_make_stage_tag "${tag}" "${generation}")" \
			"${target_id}" \
			"${domain_files}" \
			"${ip_files}" \
			"${domain_rules}" \
			"${ip_rules}" \
			"${place}" >> "${out_file}"
	done < "${src_file}"
}

hot_stage_generation() {
	local generation="$(hot_current_rule_ts)"
	[ -n "${generation}" ] || generation="$(date +%s)_$$"
	printf '%s\n' "${generation}"
}

hot_reload_apply() {
	local generation=""

	[ -f "${HOT_LOCK_FILE}" ] && {
		hot_log "已有热重载任务在执行。"
		return 1
	}
	touch "${HOT_LOCK_FILE}" || return 1
	trap 'rm -f "${HOT_LOCK_FILE}" "${HOT_NEXT_FILE}" "${HOT_STAGE_FILE}" >/dev/null 2>&1' EXIT INT TERM

	hot_require_ready || return 1
	hot_log "开始生成目标规则状态。"
	hot_build_next_state || {
		hot_log "生成目标规则状态失败。"
		return 1
	}
	hot_verify_targets_loaded || return 1

	if ! hot_seed_exists; then
		hot_log "缺少热重载基线，无法直接应用热更新。"
		return 1
	fi
	if hot_seed_matches_current; then
		hot_log "当前规则与已记录基线一致，无需重复热重载。"
		hot_mark_applied_state
		return 0
	fi

	generation="$(hot_stage_generation)"
	hot_build_stage_state "${generation}" "${HOT_NEXT_FILE}" "${HOT_STAGE_FILE}" || {
		hot_log "生成热重载临时规则失败。"
		return 1
	}
	hot_apply_staged_rules || {
		hot_log "写入新规则失败，回滚本次新增规则。"
		hot_remove_staged_rules >/dev/null 2>&1 || true
		return 1
	}
	hot_remove_runtime_rules_except "${HOT_STAGE_FILE}" || {
		hot_log "删除旧规则失败。"
		return 1
	}
	hot_mark_applied_state "${HOT_STAGE_FILE}"
	hot_log "热重载完成。"
	return 0
}

hot_reload_seed() {
	hot_require_ready || return 1
	hot_build_next_state || return 1
	hot_seed_state
	hot_log "已写入当前热重载基线。"
}

hot_reload_revert() {
	[ -f "${HOT_LOCK_FILE}" ] && {
		hot_log "已有热重载任务在执行。"
		return 1
	}
	touch "${HOT_LOCK_FILE}" || return 1
	trap 'rm -f "${HOT_LOCK_FILE}" "${HOT_NEXT_FILE}" >/dev/null 2>&1' EXIT INT TERM

	hot_require_ready || return 1
	[ -s "${HOT_BASE_FILE}" ] || {
		hot_log "缺少热重载基线，无法回滚。"
		return 1
	}
	if [ -f "${HOT_BASE_RULES_B64_FILE}" ]; then
		ss_basic_shunt_rules="$(cat "${HOT_BASE_RULES_B64_FILE}")"
		dbus set ss_basic_shunt_rules="${ss_basic_shunt_rules}"
	fi
	if [ -f "${HOT_BASE_DEFAULT_FILE}" ]; then
		ss_basic_shunt_default_node="$(cat "${HOT_BASE_DEFAULT_FILE}")"
		dbus set ss_basic_shunt_default_node="${ss_basic_shunt_default_node}"
	fi
	if [ -f "${HOT_BASE_RULE_TS_FILE}" ]; then
		ss_basic_shunt_rule_ts="$(cat "${HOT_BASE_RULE_TS_FILE}")"
		dbus set ss_basic_shunt_rule_ts="${ss_basic_shunt_rule_ts}"
	fi
	FSS_SHUNT_RUNTIME_READY=""
	FSS_SHUNT_RUNTIME_READY_KEY=""
	hot_build_next_state || {
		hot_log "回滚时重建基线状态失败。"
		return 1
	}
	hot_remove_all_managed_rules || {
		hot_log "回滚时删除旧规则失败。"
		return 1
	}
	hot_apply_all_rules || {
		hot_log "回滚时写入基线规则失败。"
		return 1
	}
	cp -f "${HOT_NEXT_FILE}" "${HOT_LAST_FILE}" >/dev/null 2>&1 || return 1
	cp -f "${HOT_BASE_RULE_TS_FILE}" "${HOT_APPLIED_RULE_TS_FILE}" >/dev/null 2>&1 || true
	hot_log "已回滚到热重载基线。"
	return 0
}

case "$1" in
apply|"")
	hot_reload_apply
	;;
seed)
	hot_reload_seed
	;;
revert)
	hot_reload_revert
	;;
clear)
	hot_clear_state
	hot_log "已清理热重载状态。"
	;;
*)
	echo "Usage: $0 [apply|seed|revert|clear]"
	exit 1
	;;
esac
