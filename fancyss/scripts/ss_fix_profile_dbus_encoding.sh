#!/bin/sh

# Profile dbus 编码修复脚本
# 用途：将已存储的明文 JSON 转换为 base64 编码，避免 httpdb JSON 嵌套问题

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh

DBUS_PREFIX="ss_subprof_"
DBUS_IDS_KEY="ss_subprof_ids"

fix_log() {
	echo "【$(date +'%Y-%m-%d %H:%M:%S')】 $*"
}

fix_profile_encoding() {
	local profile_id=""
	local profile_key=""
	local state_key=""
	local profile_json=""
	local state_json=""
	local fixed_count=0
	local failed_count=0
	local ids=""

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
		profile_json="$(dbus get "${profile_key}" 2>/dev/null)"
		if [ -n "${profile_json}" ]; then
			# 检查是否是明文 JSON（以 { 开头）
			if printf '%s' "${profile_json}" | grep -q '^{'; then
				# 明文 JSON，需要编码
				if dbus set "${profile_key}=$(printf '%s' "${profile_json}" | base64_encode)"; then
					fix_log "  ✓ Profile 已重新编码: ${profile_key}"
					fixed_count=$((fixed_count + 1))
				else
					fix_log "  ✗ Profile 编码失败: ${profile_key}"
					failed_count=$((failed_count + 1))
				fi
			else
				fix_log "  ○ Profile 已是 base64 编码，跳过"
			fi
		else
			fix_log "  ✗ Profile 不存在: ${profile_key}"
			failed_count=$((failed_count + 1))
		fi

		# 修复 State
		state_key="${DBUS_PREFIX}${profile_id}_state"
		state_json="$(dbus get "${state_key}" 2>/dev/null)"
		if [ -n "${state_json}" ]; then
			# 检查是否是明文 JSON（以 { 开头）
			if printf '%s' "${state_json}" | grep -q '^{'; then
				# 明文 JSON，需要编码
				if dbus set "${state_key}=$(printf '%s' "${state_json}" | base64_encode)"; then
					fix_log "  ✓ State 已重新编码: ${state_key}"
				else
					fix_log "  ✗ State 编码失败: ${state_key}"
				fi
			else
				fix_log "  ○ State 已是 base64 编码，跳过"
			fi
		fi
	done

	fix_log "修复完成: 成功 ${fixed_count} 个, 失败 ${failed_count} 个"
	return 0
}

verify_encoding() {
	local profile_id=""
	local profile_key=""
	local profile_json=""
	local decoded_json=""
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
		profile_json="$(dbus get "${profile_key}" 2>/dev/null)"
		if [ -n "${profile_json}" ]; then
			decoded_json="$(printf '%s' "${profile_json}" | base64_decode 2>/dev/null)"
			if [ -n "${decoded_json}" ]; then
				fix_log "  ✓ ${profile_id}: base64 编码正确"
			else
				fix_log "  ✗ ${profile_id}: base64 解码失败"
			fi
		else
			fix_log "  ✗ ${profile_id}: 未找到"
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
