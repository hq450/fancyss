#!/bin/sh

# Profile dbus 编码修复脚本
# 用途：将已存储的明文 JSON 转换为 base64 编码，避免 httpdb JSON 嵌套问题

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_subscribe_profile_lib.sh" ] && source ${KSROOT}/scripts/ss_subscribe_profile_lib.sh

DBUS_PREFIX="ss_subprof_"
DBUS_IDS_KEY="ss_subprof_ids"

fix_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

fix_profile_key_encoding() {
	local dbus_key="$1"
	local label="$2"
	local raw_value=""
	local compact_value=""
	local json_text=""
	local encoded_value=""

	[ -n "${dbus_key}" ] || return 1
	raw_value="$(dbus get "${dbus_key}" 2>/dev/null)" || raw_value=""
	if [ -z "${raw_value}" ]; then
		fix_log "  ✗ ${label} 不存在: ${dbus_key}"
		return 1
	fi

	if printf '%s' "${raw_value}" | grep -q '^[[:space:]]*{'; then
		json_text="${raw_value}"
	else
		json_text="$(subprof_dbus_get_json_by_key "${dbus_key}" 2>/dev/null)" || json_text=""
	fi
	if [ -z "${json_text}" ] || ! subprof_json_is_valid "${json_text}"; then
		fix_log "  ✗ ${label} JSON 解码或校验失败: ${dbus_key}"
		return 1
	fi

	encoded_value="$(subprof_b64_encode_compact "${json_text}")" || return 1
	compact_value="$(subprof_b64_compact "${raw_value}")"
	if [ "${raw_value}" = "${encoded_value}" ]; then
		fix_log "  ○ ${label} 已是紧凑 base64 编码，跳过"
		return 0
	fi
	if [ "${compact_value}" = "${encoded_value}" ]; then
		dbus set "${dbus_key}=${encoded_value}" >/dev/null 2>&1 || return 1
		fix_log "  ✓ ${label} 已清理 base64 空白字符: ${dbus_key}"
		return 2
	fi
	dbus set "${dbus_key}=${encoded_value}" >/dev/null 2>&1 || return 1
	fix_log "  ✓ ${label} 已重新编码: ${dbus_key}"
	return 2
}

fix_profile_encoding() {
	local profile_id=""
	local profile_key=""
	local state_key=""
	local fixed_count=0
	local failed_count=0
	local ids=""
	local ret=0

	fix_log "开始修复 Profile dbus 编码..."

	ids="$(dbus get "${DBUS_IDS_KEY}" 2>/dev/null)"
	if [ -z "${ids}" ]; then
		fix_log "未找到 Profile ID 列表"
		return 0
	fi

	fix_log "Profile ID 列表: ${ids}"

	for profile_id in $(printf '%s' "${ids}" | tr ',' '\n')
	do
		[ -n "${profile_id}" ] || continue
		fix_log "修复 Profile: ${profile_id}"

		# 修复 Profile
		profile_key="${DBUS_PREFIX}${profile_id}"
		fix_profile_key_encoding "${profile_key}" "Profile"
		ret=$?
		case "${ret}" in
		2)
			fixed_count=$((fixed_count + 1))
			;;
		1)
			failed_count=$((failed_count + 1))
			;;
		esac

		# 修复 State
		state_key="${DBUS_PREFIX}${profile_id}_state"
		if [ -n "$(dbus get "${state_key}" 2>/dev/null)" ]; then
			fix_profile_key_encoding "${state_key}" "State"
			ret=$?
			[ "${ret}" = "2" ] && fixed_count=$((fixed_count + 1))
			[ "${ret}" = "1" ] && failed_count=$((failed_count + 1))
		fi
	done

	fix_log "修复完成: 成功 ${fixed_count} 个, 失败 ${failed_count} 个"
	return 0
}

verify_encoding() {
	local profile_id=""
	local profile_key=""
	local raw_value=""
	local decoded_json=""
	local compact_value=""
	local ids=""

	fix_log "验证编码结果..."

	ids="$(dbus get "${DBUS_IDS_KEY}" 2>/dev/null)"
	if [ -z "${ids}" ]; then
		fix_log "  ✗ 未找到 Profile ID 列表"
		return 1
	fi

	for profile_id in $(printf '%s' "${ids}" | tr ',' '\n')
	do
		[ -n "${profile_id}" ] || continue
		profile_key="${DBUS_PREFIX}${profile_id}"
		raw_value="$(dbus get "${profile_key}" 2>/dev/null)" || raw_value=""
		compact_value="$(subprof_b64_compact "${raw_value}")"
		decoded_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || decoded_json=""
		if [ -n "${decoded_json}" ] && subprof_json_is_valid "${decoded_json}"; then
			if [ "${raw_value}" = "${compact_value}" ]; then
				fix_log "  ✓ ${profile_id}: base64 编码正确"
			else
				fix_log "  ⚠ ${profile_id}: base64 可解码但存在空白字符，建议执行 fix"
			fi
		else
			fix_log "  ✗ ${profile_id}: base64 解码或 JSON 校验失败"
		fi
	done

	fix_log "验证完成"
	return 0
}

case "$1" in
	fix)
		fix_profile_encoding
		;;
	verify)
		verify_encoding
		;;
	*)
		echo "用法: $0 {fix|verify}"
		echo "  fix    - 修复 Profile dbus 编码（明文 → base64）"
		echo "  verify - 验证编码是否正确"
		exit 1
		;;
esac
