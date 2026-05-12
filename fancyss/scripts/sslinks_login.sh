#!/bin/sh

source /koolshare/scripts/base.sh
[ -f /koolshare/scripts/ss_subscribe_profile_lib.sh ] && source /koolshare/scripts/ss_subscribe_profile_lib.sh

LOG_FILE=/tmp/upload/ss_log.txt
SSLINKS_RESULT_KEY="sslinks_login_result"
SSLINKS_EMAIL_KEY="sslinks_login_email"
SSLINKS_PASSWORD_KEY="sslinks_login_password"
SSLINKS_UA="fancyss_sslinks"
SSLINKS_TRANSPORT="${SSLINKS_TRANSPORT:-socks5}"
SSLINKS_SESSION_TTL="86400"

sslinks_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

sslinks_cleanup_tmp_keys() {
	dbus remove "${SSLINKS_EMAIL_KEY}" >/dev/null 2>&1 || true
	dbus remove "${SSLINKS_PASSWORD_KEY}" >/dev/null 2>&1 || true
}

sslinks_set_result() {
	local json_text="$1"
	[ -n "${json_text}" ] || json_text='{"ok":false,"message":"未知错误"}'
	subprof_dbus_set_json_by_key "${SSLINKS_RESULT_KEY}" "${json_text}" >/dev/null 2>&1 || true
}

sslinks_get_result() {
	subprof_dbus_get_json_by_key "${SSLINKS_RESULT_KEY}" 2>/dev/null || true
}

sslinks_jq_bin() {
	if [ -x "/koolshare/bin/jq" ]; then
		printf '%s\n' "/koolshare/bin/jq"
		return 0
	fi
	type jq 2>/dev/null | awk '{print $NF}' | sed -n '1p'
}

sslinks_curl_bin() {
	if [ -x "/koolshare/bin/curl-fancyss" ]; then
		printf '%s\n' "/koolshare/bin/curl-fancyss"
		return 0
	fi
	if type curl-fancyss >/dev/null 2>&1; then
		type curl-fancyss 2>/dev/null | awk '{print $NF}' | sed -n '1p'
		return 0
	fi
	if type curl >/dev/null 2>&1; then
		type curl 2>/dev/null | awk '{print $NF}' | sed -n '1p'
		return 0
	fi
	return 1
}

sslinks_curl_proxy_args() {
	case "${SSLINKS_TRANSPORT}" in
	socks5)
		netstat -nlp 2>/dev/null | grep -q "127.0.0.1:23456" || return 1
		printf '%s\n' "--socks5-hostname 127.0.0.1:23456"
		return 0
		;;
	*)
		return 0
		;;
	esac
}

sslinks_write_profile() {
	local subscribe_url="$1"
	local jq_bin="$2"
	local existing_profile_id=""
	local profile_payload=""
	local profile_id=""

	existing_profile_id="$(subprof_list_profile_ids | while IFS= read -r _id
	do
		[ -n "${_id}" ] || continue
		_json="$(subprof_dbus_get_json_by_key "$(subprof_profile_key "${_id}")" 2>/dev/null)" || continue
		_url="$(printf '%s' "${_json}" | "${jq_bin}" -r '.url // empty' 2>/dev/null | sed -n '1p')"
		[ "${_url}" = "${subscribe_url}" ] && {
			printf '%s\n' "${_id}"
			break
		}
	done)"
	profile_payload="$("${jq_bin}" -cn \
		--arg id "${existing_profile_id}" \
		--arg name "ssLinks" \
		--arg url "${subscribe_url}" \
		--arg subscribe_mode "$(dbus get ssr_subscribe_mode)" \
		--arg ua "${SSLINKS_UA}" \
		'{
			version: 1,
			id: $id,
			name: $name,
			url: $url,
			enabled: true,
			subscribe_mode: (if ($subscribe_mode // "") == "" then "2" else $subscribe_mode end),
			download: {policy: "auto"},
			ua: {mode: "custom", preset: "default", custom: $ua},
			filter: {exclude: "", include: "", keep_info_node: true},
			flags: {allow_insecure: false, node_log: true},
			hy2: {up: "", dl: "", tfo_switch: "2", cg_opt: "bbr"},
			schedule: {enabled: true, type: "1", week: "1", day: "7", hour: "3", minute: "5", interval_value: "1", interval_unit: "2", custom_hours: ""}
		}')"
	profile_id="$(subprof_write_profile_json "${profile_payload}" 2>/dev/null)" || profile_id=""
	[ -n "${profile_id}" ] || profile_id="${existing_profile_id}"
	[ -n "${profile_id}" ] || return 1
	subprof_rebuild_cron_jobs >/dev/null 2>&1 || true
	printf '%s\n' "${profile_id}"
	return 0
}

sslinks_session_status() {
	local jq_bin=""
	local now_ts=""
	local result_json=""
	local login_ts=""
	local ok=""
	local session_valid=""

	jq_bin="$(sslinks_jq_bin 2>/dev/null)" || jq_bin=""
	[ -n "${jq_bin}" ] || {
		sslinks_set_result '{"ok":false,"logged_in":false,"message":"系统缺少 jq，无法解析 ssLinks 登录状态。"}'
		return 1
	}
	now_ts="$(date +%s 2>/dev/null)"
	result_json="$(sslinks_get_result)"
	if [ -z "${result_json}" ]; then
		sslinks_set_result '{"ok":true,"logged_in":false,"message":"尚未登录 ssLinks。"}'
		return 0
	fi
	ok="$(printf '%s' "${result_json}" | "${jq_bin}" -r '.ok // false' 2>/dev/null)"
	login_ts="$(printf '%s' "${result_json}" | "${jq_bin}" -r '.login_ts // 0' 2>/dev/null)"
	session_valid="$(printf '%s' "${result_json}" | "${jq_bin}" -r --argjson now_ts "${now_ts:-0}" --argjson ttl "${SSLINKS_SESSION_TTL}" '
		((.ok // false) == true)
		and (((.login_ts // 0) | tonumber? // 0) > 0)
		and (($now_ts - (((.login_ts // 0) | tonumber? // 0))) < $ttl)
	' 2>/dev/null)"
	if [ "${ok}" = "true" ] && [ "${session_valid}" = "true" ]; then
		result_json="$(printf '%s' "${result_json}" | "${jq_bin}" -c --argjson now_ts "${now_ts:-0}" --argjson ttl "${SSLINKS_SESSION_TTL}" '
			. + {
				ok: true,
				logged_in: true,
				session_valid: true,
				session_expire_at: ((((.login_ts // 0) | tonumber? // 0) + $ttl)),
				session_remain: (((((.login_ts // 0) | tonumber? // 0) + $ttl) - $now_ts) | if . < 0 then 0 else . end)
			}
		' 2>/dev/null)"
		sslinks_set_result "${result_json}"
		return 0
	fi
	sslinks_set_result '{"ok":true,"logged_in":false,"session_valid":false,"message":"ssLinks 登录状态已过期，请重新登录。"}'
	return 0
}

sslinks_login() {
	local email=""
	local password=""
	local jq_bin=""
	local curl_bin=""
	local login_file="/tmp/sslinks_login.$$"
	local sub_file="/tmp/sslinks_subscribe.$$"
	local login_payload=""
	local auth_data=""
	local proxy_args=""
	local subscribe_url=""
	local sub_bak_url=""
	local profile_id=""
	local result_json=""
	local now_ts=""

	jq_bin="$(sslinks_jq_bin 2>/dev/null)" || jq_bin=""
	[ -n "${jq_bin}" ] || {
		sslinks_set_result '{"ok":false,"message":"系统缺少 jq，无法解析 ssLinks 返回数据。"}'
		return 1
	}
	curl_bin="$(sslinks_curl_bin 2>/dev/null)" || curl_bin=""
	[ -n "${curl_bin}" ] || {
		sslinks_set_result '{"ok":false,"message":"系统缺少 curl，无法连接 ssLinks。"}'
		return 1
	}
	email="$(dbus get "${SSLINKS_EMAIL_KEY}" 2>/dev/null)"
	password="$(dbus get "${SSLINKS_PASSWORD_KEY}" 2>/dev/null)"
	[ -n "${email}" ] && [ -n "${password}" ] || {
		sslinks_set_result '{"ok":false,"message":"请填写 ssLinks 账号和密码。"}'
		return 1
	}

	login_payload="$("${jq_bin}" -cn --arg email "${email}" --arg password "${password}" '{email:$email,password:$password}')"
	proxy_args="$(sslinks_curl_proxy_args 2>/dev/null)" || {
		sslinks_set_result '{"ok":false,"message":"当前测试模式需要先开启可用节点，未检测到 127.0.0.1:23456 socks5。"}'
		return 1
	}
	if ! "${curl_bin}" ${proxy_args} -sS -L --connect-timeout 10 --max-time 30 \
		-A "${SSLINKS_UA}" \
		-H "ua: ${SSLINKS_UA}" \
		-H "Content-Type: application/json" \
		-H "Accept: application/json, text/plain, */*" \
		--data-raw "${login_payload}" \
		"https://ss.mba/api/v1/passport/auth/login" > "${login_file}" 2>/dev/null; then
		sslinks_set_result '{"ok":false,"message":"连接 ssLinks 登录接口失败，请稍后重试。"}'
		rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
		return 1
	fi

	auth_data="$(cat "${login_file}" | "${jq_bin}" -r '.data.auth_data // empty' 2>/dev/null)"
	if [ -z "${auth_data}" ]; then
		result_json="$("${jq_bin}" -cn --arg msg "登录失败，请检查账号或密码。" '{ok:false,message:$msg}')"
		sslinks_set_result "${result_json}"
		rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
		return 1
	fi

	if ! "${curl_bin}" ${proxy_args} -sS -L --connect-timeout 10 --max-time 30 \
		-A "${SSLINKS_UA}" \
		-H "ua: ${SSLINKS_UA}" \
		-H "Accept: application/json, text/plain, */*" \
		-H "authorization: ${auth_data}" \
		"https://ss.mba/api/v1/user/getSubscribe" > "${sub_file}" 2>/dev/null; then
		sslinks_set_result '{"ok":false,"message":"登录成功，但获取订阅信息失败，请稍后重试。"}'
		rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
		return 1
	fi

	subscribe_url="$(cat "${sub_file}" | "${jq_bin}" -r '.data.subscribe_url // empty' 2>/dev/null | sed -n '1p')"
	sub_bak_url="$(cat "${sub_file}" | "${jq_bin}" -r '.data.sub_bak_url // empty' 2>/dev/null | sed -n '1p')"
	[ -n "${subscribe_url}" ] || subscribe_url="${sub_bak_url}"
	if [ -z "${subscribe_url}" ]; then
		result_json="$("${jq_bin}" -cn --arg msg "登录成功，但当前账号未返回有效订阅地址。" '{ok:false,message:$msg}')"
		sslinks_set_result "${result_json}"
		rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
		return 1
	fi
	profile_id="$(sslinks_write_profile "${subscribe_url}" "${jq_bin}" 2>/dev/null)" || profile_id=""
	[ -n "${profile_id}" ] || {
		sslinks_set_result '{"ok":false,"message":"订阅信息获取成功，但写入 fancyss 订阅配置失败。"}'
		rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
		return 1
	}

	now_ts="$(date +%s 2>/dev/null)"
	result_json="$(cat "${sub_file}" | "${jq_bin}" -c \
		--arg profile_id "${profile_id}" \
		--arg subscribe_url "${subscribe_url}" \
		--arg sub_bak_url "${sub_bak_url}" \
		--argjson now_ts "${now_ts:-0}" '
		.data as $d
		| {
			ok: true,
			logged_in: true,
			session_valid: true,
			login_ts: $now_ts,
			session_expire_at: ($now_ts + 86400),
			session_remain: 86400,
			message: (if (((($d.expired_at // 0) | tonumber? // 0) > 0) and ((($d.expired_at // 0) | tonumber? // 0) < $now_ts)) then "登录成功，但 ssLinks 套餐已过期。" else "登录成功，已写入 ssLinks 订阅配置。" end),
			profile_id: $profile_id,
			email: ($d.email // ""),
			plan_name: ($d.plan.name // ""),
			expired_at: (($d.expired_at // 0) | tonumber? // 0),
			expired: (((($d.expired_at // 0) | tonumber? // 0) > 0) and ((($d.expired_at // 0) | tonumber? // 0) < $now_ts)),
			sync_allowed: ((((($d.expired_at // 0) | tonumber? // 0) > 0) and ((($d.expired_at // 0) | tonumber? // 0) < $now_ts)) | not),
			expire_day: ($d.expire_day // {}),
			reset_day: ($d.reset_day // {}),
			transfer_used: ((($d.u // 0) | tonumber? // 0) + (($d.d // 0) | tonumber? // 0)),
			transfer_enable: (($d.transfer_enable // 0) | tonumber? // 0),
			subscribe_url: $subscribe_url,
			sub_bak_url: $sub_bak_url
		}
	' 2>/dev/null)"
	[ -n "${result_json}" ] || result_json='{"ok":true,"message":"登录成功，已写入 ssLinks 订阅配置。"}'
	sslinks_set_result "${result_json}"
	sslinks_log "ssLinks 登录成功，已写入订阅配置：${profile_id}"
	rm -f "${login_file}" "${sub_file}" >/dev/null 2>&1
	return 0
}

ACTION="$1"
WEB_ACTION=0
if [ -n "$2" -a -n "$1" ]; then
	ACTION="$2"
	WEB_ACTION=1
fi

case "${ACTION}" in
login)
	true > "${LOG_FILE}"
	dbus remove "${SSLINKS_RESULT_KEY}" >/dev/null 2>&1 || true
	if sslinks_login >> "${LOG_FILE}" 2>&1; then
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	else
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	fi
	sslinks_cleanup_tmp_keys
	;;
status)
	true > "${LOG_FILE}"
	if sslinks_session_status >> "${LOG_FILE}" 2>&1; then
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	else
		[ "${WEB_ACTION}" = "1" ] && http_response "$1"
		echo XU6J03M6 >> "${LOG_FILE}"
	fi
	sslinks_cleanup_tmp_keys
	;;
logout)
	true > "${LOG_FILE}"
	dbus remove "${SSLINKS_RESULT_KEY}" >/dev/null 2>&1 || true
	sslinks_set_result '{"ok":true,"logged_in":false,"message":"已退出 ssLinks 登录。"}'
	[ "${WEB_ACTION}" = "1" ] && http_response "$1"
	echo XU6J03M6 >> "${LOG_FILE}"
	sslinks_cleanup_tmp_keys
	;;
*)
	true > "${LOG_FILE}"
	sslinks_log "未知操作：${ACTION}" >> "${LOG_FILE}" 2>&1
	echo XU6J03M6 >> "${LOG_FILE}"
	sslinks_cleanup_tmp_keys
	exit 1
	;;
esac
