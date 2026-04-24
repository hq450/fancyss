#!/bin/sh

# Profile 存储迁移脚本：文件 → dbus
# 用途：将 /koolshare/configs/fancyss/subscriptions/profiles/*.json 迁移到 dbus

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_subscribe_profile_lib.sh" ] && source ${KSROOT}/scripts/ss_subscribe_profile_lib.sh

OLD_PROFILE_DIR="/koolshare/configs/fancyss/subscriptions/profiles"
OLD_STATE_DIR="/koolshare/configs/fancyss/subscriptions/states"

migrate_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

migrate_profile_files() {
	local profile_file=""
	local state_file=""
	local profile_id=""
	local profile_json=""
	local state_json=""
	local profile_key=""
	local state_key=""
	local migrated_count=0
	local failed_count=0
	local current_ids=""
	local new_ids=""

	migrate_log "开始迁移 Profile 文件到 dbus..."

	if [ ! -d "${OLD_PROFILE_DIR}" ]; then
		migrate_log "Profile 目录不存在: ${OLD_PROFILE_DIR}"
		return 0
	fi

	for profile_file in "${OLD_PROFILE_DIR}"/*.json
	do
		[ -f "${profile_file}" ] || continue
		profile_id="$(basename "${profile_file}" .json)"
		[ -n "${profile_id}" ] || continue

		migrate_log "迁移 Profile: ${profile_id}"

		# 读取 Profile JSON
		profile_json="$(cat "${profile_file}" 2>/dev/null)"
		if [ -z "${profile_json}" ]; then
			migrate_log "  ✗ 读取失败: ${profile_file}"
			failed_count=$((failed_count + 1))
			continue
		fi

		# 写入 dbus (使用 base64 编码避免 JSON 嵌套问题)
		profile_key="$(subprof_profile_key "${profile_id}")"
		if subprof_dbus_set_json_by_key "${profile_key}" "${profile_json}"; then
			migrate_log "  ✓ Profile 已写入 dbus: ${profile_key}"
		else
			migrate_log "  ✗ Profile 写入失败: ${profile_key}"
			failed_count=$((failed_count + 1))
			continue
		fi

		# 迁移 state 文件（如果存在）
		state_file="${OLD_STATE_DIR}/${profile_id}.state.json"
		if [ -f "${state_file}" ]; then
			state_json="$(cat "${state_file}" 2>/dev/null)"
			if [ -n "${state_json}" ]; then
				state_key="$(subprof_state_key "${profile_id}")"
				if subprof_dbus_set_json_by_key "${state_key}" "${state_json}"; then
					migrate_log "  ✓ State 已写入 dbus: ${state_key}"
				else
					migrate_log "  ✗ State 写入失败: ${state_key}"
				fi
			fi
		fi

		# 添加到 ID 列表
		current_ids="$(dbus get "${SUB_PROFILE_IDS_KEY}" 2>/dev/null)"
		if [ -z "${current_ids}" ]; then
			new_ids="${profile_id}"
		elif ! printf '%s' "${current_ids}" | tr ',' '\n' | grep -qx "${profile_id}"; then
			new_ids="${current_ids},${profile_id}"
		else
			new_ids="${current_ids}"
		fi
		dbus set "${SUB_PROFILE_IDS_KEY}=${new_ids}"

		migrated_count=$((migrated_count + 1))
	done

	migrate_log "迁移完成: 成功 ${migrated_count} 个, 失败 ${failed_count} 个"
	return 0
}

verify_migration() {
	local profile_id=""
	local profile_key=""
	local profile_json=""
	local ids=""

	migrate_log "验证迁移结果..."

	ids="$(dbus get "${SUB_PROFILE_IDS_KEY}" 2>/dev/null)"
	if [ -z "${ids}" ]; then
		migrate_log "  ✗ 未找到 Profile ID 列表"
		return 1
	fi

	migrate_log "  Profile ID 列表: ${ids}"

	for profile_id in $(printf '%s' "${ids}" | tr ',' '\n')
	do
		[ -n "${profile_id}" ] || continue
		profile_key="$(subprof_profile_key "${profile_id}")"
		profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || profile_json=""
		if [ -n "${profile_json}" ]; then
			migrate_log "  ✓ ${profile_id}: 已存在于 dbus"
		else
			migrate_log "  ✗ ${profile_id}: 未找到"
		fi
	done

	migrate_log "验证完成"
	return 0
}

show_usage() {
	cat <<-'EOF'
	用法: ss_migrate_profile_to_dbus.sh [选项]

	选项:
	  migrate   - 执行迁移
	  verify    - 验证迁移结果
	  help      - 显示帮助

	示例:
	  sh ss_migrate_profile_to_dbus.sh migrate
	  sh ss_migrate_profile_to_dbus.sh verify
	EOF
}

main() {
	local action="${1:-help}"

	case "${action}" in
		migrate)
			migrate_profile_files
			;;
		verify)
			verify_migration
			;;
		help|*)
			show_usage
			;;
	esac
}

main "$@"
