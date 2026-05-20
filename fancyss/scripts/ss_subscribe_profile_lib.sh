#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
if ! type fss_detect_storage_schema >/dev/null 2>&1 && [ -f "${KSROOT}/scripts/ss_node_common.sh" ]; then
	source ${KSROOT}/scripts/ss_node_common.sh
fi

SUB_PROFILE_TMP_PAYLOAD_KEY="ss_subscribe_profile_payload"
SUB_PROFILE_TMP_ID_KEY="ss_subscribe_profile_id"
SUB_PROFILE_TMP_SYNC_ID_KEY="ss_subscribe_profile_selected"
SUB_PROFILE_SCHEMA_VERSION="1"
SUB_PROFILE_DBUS_PREFIX="ss_subprof_"
SUB_PROFILE_IDS_KEY="ss_subprof_ids"
NODE_TOOL_CONF_FILE="/koolshare/ss/rules/node-tool.conf"

subprof_jq_bin() {
	if [ -x "/koolshare/bin/jq" ]; then
		printf '%s\n' "/koolshare/bin/jq"
		return 0
	fi
	type jq 2>/dev/null | awk '{print $NF}' | sed -n '1p'
}

subprof_profile_key() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf '%s%s\n' "${SUB_PROFILE_DBUS_PREFIX}" "${profile_id}"
}

subprof_state_key() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf '%s%s_state\n' "${SUB_PROFILE_DBUS_PREFIX}" "${profile_id}"
}

subprof_b64_compact() {
	printf '%s' "$1" | tr -d ' \t\r\n'
}

subprof_b64_encode_compact() {
	printf '%s' "$1" | base64 | tr -d ' \t\r\n'
}

subprof_b64_decode_loose() {
	local compact=""
	local decoded=""
	compact="$(subprof_b64_compact "$1")"
	[ -n "${compact}" ] || return 1
	printf '%s' "${compact}" | grep -Eq '^[A-Za-z0-9+/=_-]+$' || return 1
	[ "$(( ${#compact} % 4 ))" -ne "1" ] 2>/dev/null || return 1
	decoded="$(printf '%s' "${compact}" | base64 -d 2>/dev/null)" && {
		printf '%s' "${decoded}"
		return 0
	}
	printf '%s' "${compact}" | base64 --decode 2>/dev/null
}

subprof_json_is_valid() {
	local jq_bin=""
	jq_bin="$(subprof_jq_bin)" || return 1
	printf '%s' "$1" | "${jq_bin}" -c '.' >/dev/null 2>&1
}

subprof_dbus_set_json_by_key() {
	local dbus_key="$1"
	local json_text="$2"
	local encoded=""

	[ -n "${dbus_key}" ] || return 1
	[ -n "${json_text}" ] || return 1
	encoded="$(subprof_b64_encode_compact "${json_text}")" || return 1
	[ -n "${encoded}" ] || return 1
	dbus set "${dbus_key}=${encoded}"
}

subprof_dbus_get_json_by_key() {
	local dbus_key="$1"
	local raw_value=""
	local compact_value=""
	local decoded_json=""

	[ -n "${dbus_key}" ] || return 1
	raw_value="$(dbus get "${dbus_key}" 2>/dev/null)" || raw_value=""
	[ -n "${raw_value}" ] || return 1

	compact_value="$(subprof_b64_compact "${raw_value}")"
	if [ -n "${compact_value}" ]; then
		decoded_json="$(subprof_b64_decode_loose "${compact_value}" 2>/dev/null)" || decoded_json=""
		if [ -n "${decoded_json}" ] && subprof_json_is_valid "${decoded_json}"; then
			printf '%s' "${decoded_json}"
			return 0
		fi
	fi
	return 1
}

subprof_valid_profile_id() {
	local profile_id="$1"
	printf '%s' "${profile_id}" | grep -Eq '^[A-Za-z0-9._-]+$'
}

subprof_profile_id_exists() {
	local profile_id="$1"
	local profile_key=""
	local raw_value=""

	[ -n "${profile_id}" ] || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	raw_value="$(dbus get "${profile_key}" 2>/dev/null)" || raw_value=""
	[ -n "${raw_value}" ]
}

subprof_random_hex_id() {
	local candidate=""

	if [ -r "/proc/sys/kernel/random/uuid" ]; then
		candidate="$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | cut -c1-12)"
	fi
	if ! printf '%s' "${candidate}" | grep -Eq '^[a-f0-9]{12}$'; then
		candidate="$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n' | cut -c1-12)"
	fi
	if ! printf '%s' "${candidate}" | grep -Eq '^[a-f0-9]{12}$'; then
		candidate="$(printf '%s' "$$_$(date +%s 2>/dev/null)_$(cat /proc/uptime 2>/dev/null)" | md5sum | awk '{print substr($1,1,12)}')"
	fi
	printf '%s\n' "${candidate}"
}

subprof_generate_profile_id() {
	local candidate=""
	local attempt=0

	while [ "${attempt}" -lt 32 ]
	do
		candidate="$(subprof_random_hex_id 2>/dev/null)" || candidate=""
		if printf '%s' "${candidate}" | grep -Eq '^[a-f0-9]{12}$' && ! subprof_profile_id_exists "${candidate}"; then
			printf '%s\n' "${candidate}"
			return 0
		fi
		attempt=$((attempt + 1))
	done
	return 1
}

subprof_extract_url_host() {
	local url="$1"
	printf '%s\n' "${url}" | sed -n 's#^[A-Za-z][A-Za-z0-9+.-]*://\([^/@:]*\).*$#\1#p' | sed -n '1p'
}

subprof_lookup_domain_airport_label() {
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

subprof_pretty_name_from_url() {
	local url="$1"
	local host=""
	local label=""
	host="$(subprof_extract_url_host "${url}")"
	[ -n "${host}" ] || {
		printf '%s\n' "订阅"
		return 0
	}
	label="$(subprof_lookup_domain_airport_label "${host}" 2>/dev/null)" || label=""
	if [ -n "${label}" ]; then
		printf '%s\n' "${label}"
		return 0
	fi
	printf '%s\n' "${host}" | sed 's/^www\.//'
}

subprof_policy_from_legacy_value() {
	case "$1" in
	1)
		printf '%s\n' "proxy"
		;;
	2)
		printf '%s\n' "direct"
		;;
	*)
		printf '%s\n' "auto"
		;;
	esac
}

subprof_ua_preset_from_legacy_value() {
	case "$1" in
	1)
		printf '%s\n' "curl"
		;;
	2)
		printf '%s\n' "v2rayn"
		;;
	3)
		printf '%s\n' "v2rayng"
		;;
	4)
		printf '%s\n' "shadowrocket"
		;;
	*)
		printf '%s\n' "default"
		;;
	esac
}

subprof_boolean_string() {
	case "$1" in
	1|true|TRUE|yes|YES|on|ON)
		printf '%s\n' "true"
		;;
	*)
		printf '%s\n' "false"
		;;
	esac
}

subprof_build_legacy_payload_json() {
	local profile_id="$1"
	local profile_name="$2"
	local profile_url="$3"
	local ua_preset=""
	local download_policy=""

	ua_preset="$(subprof_ua_preset_from_legacy_value "$(dbus get ss_basic_online_ua)")"
	download_policy="$(subprof_policy_from_legacy_value "$(dbus get ss_basic_online_links_proxy)")"
	"$(subprof_jq_bin)" -cn \
		--arg id "${profile_id}" \
		--arg name "${profile_name}" \
		--arg url "${profile_url}" \
		--arg subscribe_mode "$(dbus get ssr_subscribe_mode)" \
		--arg download_policy "${download_policy}" \
		--arg ua_preset "${ua_preset}" \
		--arg exclude "$(dbus get ss_basic_exclude)" \
		--arg include "$(dbus get ss_basic_include)" \
		--argjson allow_insecure "$(subprof_boolean_string "$(dbus get ss_basic_sub_ai)")" \
		--arg hy2_up "$(dbus get ss_basic_hy2_up_speed)" \
		--arg hy2_dl "$(dbus get ss_basic_hy2_dl_speed)" \
		--arg hy2_tfo_switch "$(dbus get ss_basic_hy2_tfo_switch)" \
		--arg hy2_cg_opt "$(dbus get ss_basic_hy2_cg_opt)" \
		--argjson schedule_enabled "true" '
		{
			version: 1,
			id: $id,
			name: $name,
			url: $url,
			enabled: true,
			subscribe_mode: (if ($subscribe_mode // "") == "" then "2" else $subscribe_mode end),
			download: {
				policy: $download_policy
			},
			ua: {
				mode: "fixed",
				preset: $ua_preset,
				custom: ""
			},
			filter: {
				exclude: ($exclude // ""),
				include: ($include // ""),
				keep_info_node: true
			},
			flags: {
				allow_insecure: $allow_insecure,
				node_log: true
			},
			hy2: {
				up: ($hy2_up // ""),
				dl: ($hy2_dl // ""),
				tfo_switch: (if ($hy2_tfo_switch // "") == "" then "2" else $hy2_tfo_switch end),
				cg_opt: (if ($hy2_cg_opt // "") == "" then "bbr" else $hy2_cg_opt end)
			},
			schedule: {
				enabled: $schedule_enabled,
				type: "1",
				week: "1",
				day: "7",
				hour: "3",
				minute: "5",
				interval_value: "1",
				interval_unit: "2",
				custom_hours: ""
			}
		}
	'
}

subprof_normalize_payload() {
	local payload_json="$1"
	printf '%s' "${payload_json}" | "$(subprof_jq_bin)" -c '
		def to_bool:
			if type == "boolean" then .
			elif type == "number" then . != 0
			else
				((tostring | ascii_downcase) == "1")
				or ((tostring | ascii_downcase) == "true")
				or ((tostring | ascii_downcase) == "yes")
				or ((tostring | ascii_downcase) == "on")
			end;
		def pick3($a; $b; $fallback):
			if $a != null then $a
			elif $b != null then $b
			else $fallback
			end;
		{
			version: 1,
			id: ((.id // "") | tostring),
			name: ((.name // "") | tostring),
			url: ((.url // "") | tostring),
			enabled: ((if .enabled == null then true else .enabled end) | to_bool),
			subscribe_mode: ((.subscribe_mode // "2") | tostring | if . == "" then "2" else . end),
			download: {
				policy: (
					(.download.policy // .download_policy // "auto")
					| tostring
					| ascii_downcase
					| if . == "direct" or . == "proxy" then . else "auto" end
				)
			},
			ua: {
				mode: (
					(.ua.mode // .ua_mode // "fixed")
					| tostring
					| ascii_downcase
					| if . == "auto" or . == "custom" or . == "inherit" then . else "fixed" end
				),
				preset: (
					(.ua.preset // .ua_preset // "default")
					| tostring
					| ascii_downcase
					| if . == "curl" or . == "v2rayn" or . == "v2rayng" or . == "shadowrocket" then . else "default" end
				),
				custom: ((.ua.custom // .ua_custom // "") | tostring)
			},
			filter: {
				exclude: ((.filter.exclude // .exclude // "") | tostring),
				include: ((.filter.include // .include // "") | tostring),
				keep_info_node: true
			},
			flags: {
				allow_insecure: (pick3(.flags.allow_insecure; .allow_insecure; false) | to_bool),
				node_log: true
			},
			hy2: {
				up: ((.hy2.up // .hy2_up // "") | tostring),
				dl: ((.hy2.dl // .hy2_dl // "") | tostring),
				tfo_switch: ((.hy2.tfo_switch // .hy2_tfo_switch // "2") | tostring | if . == "" then "2" else . end),
				cg_opt: ((.hy2.cg_opt // .hy2_cg_opt // "bbr") | tostring | if . == "" then "bbr" else . end)
			},
			schedule: {
				enabled: (pick3(.schedule.enabled; .schedule_enabled; true) | to_bool),
				type: ((.schedule.type // .schedule_type // "1") | tostring | if . == "" then "1" else . end),
				week: ((.schedule.week // .schedule_week // "1") | tostring | if . == "" then "1" else . end),
				day: ((.schedule.day // .schedule_day // "7") | tostring | if . == "" then "7" else . end),
				hour: ((.schedule.hour // .schedule_hour // "3") | tostring | if . == "" then "3" else . end),
				minute: ((.schedule.minute // .schedule_minute // "5") | tostring | if . == "" then "5" else . end),
				interval_value: ((.schedule.interval_value // .schedule_interval_value // "1") | tostring | if . == "" then "1" else . end),
				interval_unit: ((.schedule.interval_unit // .schedule_interval_unit // "2") | tostring | if . == "" then "2" else . end),
				custom_hours: ((.schedule.custom_hours // .schedule_custom_hours // "") | tostring)
			}
		}
	'
}

subprof_write_profile_json() {
	local payload_json="$1"
	local normalized=""
	local profile_id=""
	local profile_url=""
	local profile_key=""
	local state_key=""
	local existing_id=""
	local existing_json=""
	local existing_url=""

	normalized="$(subprof_normalize_payload "${payload_json}")" || return 1
	profile_url="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -r '.url // empty' 2>/dev/null)"
	[ -n "${profile_url}" ] || return 1
	printf '%s' "${profile_url}" | grep -Eq '^https?://' || return 1

	profile_id="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -r '.id // empty' 2>/dev/null)"
	[ -n "${profile_id}" ] || profile_id="$(subprof_generate_profile_id 2>/dev/null)"
	subprof_valid_profile_id "${profile_id}" || return 1
	for existing_id in $(subprof_list_profile_ids)
	do
		[ -n "${existing_id}" ] || continue
		[ "${existing_id}" = "${profile_id}" ] && continue
		existing_json="$(subprof_dbus_get_json_by_key "$(subprof_profile_key "${existing_id}")" 2>/dev/null)" || continue
		[ -n "${existing_json}" ] || continue
		existing_url="$(printf '%s' "${existing_json}" | "$(subprof_jq_bin)" -r '.url // empty' 2>/dev/null | sed -n '1p')"
		if [ -n "${existing_url}" ] && [ "${existing_url}" = "${profile_url}" ]; then
			return 1
		fi
	done
	normalized="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -c --arg id "${profile_id}" '.id = $id')" || return 1

	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	# Base64 encode JSON without any whitespace to avoid httpdb/skipd JSON corruption
	subprof_dbus_set_json_by_key "${profile_key}" "${normalized}" || return 1
	if ! dbus get "${state_key}" >/dev/null 2>&1; then
		local state_json="$("$(subprof_jq_bin)" -cn --arg id "${profile_id}" '{version:1,id:$id,last_ok_ts:0,last_error_ts:0,last_error:"",last_url_hash:"",last_group:""}')"
		subprof_dbus_set_json_by_key "${state_key}" "${state_json}" >/dev/null 2>&1 || true
	fi
	subprof_add_profile_id "${profile_id}"
	printf '%s\n' "${profile_id}"
	return 0
}

subprof_remove_profile() {
	local profile_id="$1"
	local profile_key=""
	local state_key=""

	[ -n "${profile_id}" ] || return 1
	subprof_valid_profile_id "${profile_id}" || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	dbus remove "${profile_key}" >/dev/null 2>&1
	dbus remove "${state_key}" >/dev/null 2>&1
	subprof_remove_profile_id "${profile_id}"
	return 0
}

subprof_list_profile_ids() {
	dbus get "${SUB_PROFILE_IDS_KEY}" 2>/dev/null | tr ',' '\n' | grep -v '^$'
}

subprof_has_profiles() {
	[ -n "$(subprof_list_profile_ids | sed -n '1p')" ]
}

subprof_add_profile_id() {
	local profile_id="$1"
	local current_ids=""
	local new_ids=""

	[ -n "${profile_id}" ] || return 1
	current_ids="$(dbus get "${SUB_PROFILE_IDS_KEY}" 2>/dev/null)"

	if [ -z "${current_ids}" ]; then
		new_ids="${profile_id}"
	elif ! printf '%s' "${current_ids}" | tr ',' '\n' | grep -qx "${profile_id}"; then
		new_ids="${current_ids},${profile_id}"
	else
		return 0
	fi

	dbus set "${SUB_PROFILE_IDS_KEY}=${new_ids}"
}

subprof_remove_profile_id() {
	local profile_id="$1"
	local current_ids=""
	local new_ids=""

	[ -n "${profile_id}" ] || return 1
	current_ids="$(dbus get "${SUB_PROFILE_IDS_KEY}" 2>/dev/null)"
	[ -n "${current_ids}" ] || return 0

	new_ids="$(printf '%s' "${current_ids}" | tr ',' '\n' | grep -vx "${profile_id}" | tr '\n' ',' | sed 's/,$//')"
	dbus set "${SUB_PROFILE_IDS_KEY}=${new_ids}"
}

subprof_count_profile_nodes_fast() {
	local profile_id="$1"
	local source_scope="$2"
	local node_tool=""
	local jq_bin=""
	local count=""
	local list_count=""

	[ -n "${profile_id}" ] || return 1
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || return 1
	jq_bin="$(subprof_jq_bin)" || return 1
	count="$(
		"${node_tool}" stat --source subscribe --profile-id "${profile_id}" --format json 2>/dev/null \
			| "${jq_bin}" -r '.total // empty' 2>/dev/null \
			| sed -n '1p'
	)"
	printf '%s' "${count}" | grep -Eq '^[0-9]+$' || return 1
	if [ "${count}" -gt 0 ] 2>/dev/null || [ -z "${source_scope}" ]; then
		printf '%s\n' "${count}"
		return 0
	fi
	list_count="$(subprof_count_profile_nodes_fallback "${profile_id}" "${source_scope}" 2>/dev/null)" || return 1
	printf '%s' "${list_count}" | grep -Eq '^[0-9]+$' || return 1
	printf '%s\n' "${list_count}"
	return 0
}

subprof_count_profile_nodes_fallback() {
	local profile_id="$1"
	local source_scope="$2"
	local node_id=""
	local node_profile_id=""
	local node_scope=""

	fss_list_node_ids | sed '/^$/d' | while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		node_profile_id="$(fss_get_node_profile_id_by_id "${node_id}" 2>/dev/null)" || node_profile_id=""
		if [ -n "${node_profile_id}" ]; then
			[ "${node_profile_id}" = "${profile_id}" ] && echo 1
			continue
		fi
		[ -n "${source_scope}" ] || continue
		node_scope="$(fss_get_node_source_scope_by_id "${node_id}" 2>/dev/null)" || node_scope=""
		[ "${node_scope}" = "${source_scope}" ] && echo 1
	done | wc -l | tr -d ' '
}

subprof_repair_state_from_bound_nodes() {
	local profile_id="$1"
	local state_key=""
	local state_json=""
	local last_group=""
	local last_url_hash=""
	local node_id=""
	local node_json=""
	local node_profile_id=""
	local group_value=""
	local url_hash=""
	local group_suffix=""
	local state_input=""
	local repaired_json=""

	[ -n "${profile_id}" ] || return 1
	type fss_list_node_ids >/dev/null 2>&1 || return 1
	type fss_v2_get_node_json_by_id >/dev/null 2>&1 || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
	if [ -n "${state_json}" ]; then
		last_group="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -r '.last_group // empty' 2>/dev/null | sed -n '1p')"
		last_url_hash="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -r '.last_url_hash // empty' 2>/dev/null | sed -n '1p')"
		[ -n "${last_group}" ] && [ -n "${last_url_hash}" ] && {
			printf '%s' "${state_json}"
			return 0
		}
	fi

	for node_id in $(fss_list_node_ids 2>/dev/null)
	do
		[ -n "${node_id}" ] || continue
		node_json="$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null)" || continue
		[ -n "${node_json}" ] || continue
		node_profile_id="$(printf '%s' "${node_json}" | "$(subprof_jq_bin)" -r '._profile_id // empty' 2>/dev/null | sed -n '1p')"
		[ "${node_profile_id}" = "${profile_id}" ] || continue
		group_value="$(printf '%s' "${node_json}" | "$(subprof_jq_bin)" -r '.group // empty' 2>/dev/null | sed -n '1p')"
		url_hash="$(printf '%s' "${node_json}" | "$(subprof_jq_bin)" -r '._source_url_hash // empty' 2>/dev/null | sed -n '1p')"
		[ -n "${group_value}" ] || continue
		group_suffix="${group_value##*_}"
		if [ "${group_suffix}" != "${group_value}" ] && printf '%s' "${group_suffix}" | grep -Eq '^[A-Za-z0-9]{4}$'; then
			group_value="${group_value%_*}"
		fi
		if [ -n "${state_json}" ]; then
			state_input="${state_json}"
		else
			state_input="{}"
		fi
		repaired_json="$(printf '%s' "${state_input}" | "$(subprof_jq_bin)" -c \
			--arg id "${profile_id}" \
			--arg group_name "${group_value}" \
			--arg url_hash "${url_hash}" '
			(. // {}) + {
				version: 1,
				id: $id,
				last_ok_ts: (.last_ok_ts // 0),
				last_error_ts: (.last_error_ts // 0),
				last_error: (.last_error // ""),
				last_url_hash: (if (.last_url_hash // "") == "" then $url_hash else .last_url_hash end),
				last_group: (if (.last_group // "") == "" then $group_name else .last_group end)
			}
		')" || return 1
		subprof_dbus_set_json_by_key "${state_key}" "${repaired_json}" >/dev/null 2>&1 || true
		printf '%s' "${repaired_json}"
		return 0
	done

	[ -n "${state_json}" ] && {
		printf '%s' "${state_json}"
		return 0
	}
	return 1
}

subprof_merge_profile_and_state() {
	local profile_id="$1"
	local profile_key=""
	local state_key=""
	local profile_json=""
	local state_json=""
	local node_count="0"
	local airport_identity=""
	local last_url_hash=""
	local last_group=""
	local source_scope=""

	[ -n "${profile_id}" ] || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || return 1
	[ -n "${profile_json}" ] || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
	if [ -z "${state_json}" ]; then
		state_json="$("$(subprof_jq_bin)" -cn --arg id "${profile_id}" '{version:1,id:$id,last_ok_ts:0,last_error_ts:0,last_error:"",last_url_hash:"",last_group:""}')"
		subprof_dbus_set_json_by_key "${state_key}" "${state_json}" >/dev/null 2>&1 || true
	fi
	state_json="$(subprof_repair_state_from_bound_nodes "${profile_id}" 2>/dev/null)" || state_json="${state_json}"
	last_group="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -r '.last_group // empty' 2>/dev/null | sed -n '1p')"
	last_url_hash="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -r '.last_url_hash // empty' 2>/dev/null | sed -n '1p')"
	if [ -n "${last_group}" ]; then
		airport_identity="$(fss_identity_slugify "${last_group}" "sub" 2>/dev/null)"
		source_scope="${airport_identity}"
		[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"
	fi
	node_count="$(subprof_count_profile_nodes_fast "${profile_id}" "${source_scope}" 2>/dev/null)" || node_count=""
	[ -n "${node_count}" ] || node_count="0"
	printf '%s\n%s\n' "${profile_json}" "${state_json}" | "$(subprof_jq_bin)" -s \
		--argjson node_count "${node_count}" '
		(.[0] // {}) as $p
		| (.[1] // {}) as $s
		| {
			id: ($p.id // ""),
			name: ($p.name // ""),
			url: ($p.url // ""),
			enabled: (if $p.enabled == null then true else $p.enabled end),
			subscribe_mode: ($p.subscribe_mode // "2"),
			download_policy: ($p.download.policy // "auto"),
			ua_mode: ($p.ua.mode // "fixed"),
			ua_preset: ($p.ua.preset // "default"),
			ua_custom: ($p.ua.custom // ""),
			exclude: ($p.filter.exclude // ""),
			include: ($p.filter.include // ""),
			keep_info_node: true,
			allow_insecure: (if $p.flags.allow_insecure == null then false else $p.flags.allow_insecure end),
			node_log: true,
			hy2_up: ($p.hy2.up // ""),
			hy2_dl: ($p.hy2.dl // ""),
			hy2_tfo_switch: ($p.hy2.tfo_switch // "2"),
			hy2_cg_opt: ($p.hy2.cg_opt // "bbr"),
			schedule_enabled: (if $p.schedule.enabled == null then true else $p.schedule.enabled end),
			schedule_type: ($p.schedule.type // "1"),
			schedule_week: ($p.schedule.week // "1"),
			schedule_day: ($p.schedule.day // "7"),
			schedule_hour: ($p.schedule.hour // "3"),
			schedule_minute: ($p.schedule.minute // "5"),
			schedule_interval_value: ($p.schedule.interval_value // "1"),
			schedule_interval_unit: ($p.schedule.interval_unit // "2"),
			schedule_custom_hours: ($p.schedule.custom_hours // ""),
			last_ok_ts: ($s.last_ok_ts // 0),
			last_error_ts: ($s.last_error_ts // 0),
			last_error: ($s.last_error // ""),
			last_url_hash: ($s.last_url_hash // ""),
			last_group: ($s.last_group // ""),
			last_download_tool: ($s.last_download_tool // ""),
			last_download_path: ($s.last_download_path // ""),
			last_ua_mode: ($s.last_ua_mode // ""),
			last_ua_preset: ($s.last_ua_preset // ""),
			node_count: $node_count
		}
	' 2>/dev/null
}

subprof_collect_enabled_profiles_tsv() {
	local output_file="$1"
	local profile_id=""
	local row=""
	local enabled=""

	[ -n "${output_file}" ] || return 1
	: > "${output_file}"
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		row="$(subprof_merge_profile_and_state "${profile_id}")" || row=""
		[ -n "${row}" ] || continue
		enabled="$(printf '%s' "${row}" | "$(subprof_jq_bin)" -r '.enabled // false' 2>/dev/null)"
		[ "${enabled}" = "true" ] || continue
		printf '%s' "${row}" | "$(subprof_jq_bin)" -r '[
			.id,
			.name,
			.url,
			.subscribe_mode,
			.download_policy,
			.ua_mode,
			.ua_preset,
			.ua_custom,
			.exclude,
			.include,
			.allow_insecure,
			.node_log,
			.keep_info_node,
			.hy2_up,
			.hy2_dl,
			.hy2_tfo_switch,
			.hy2_cg_opt,
			.schedule_enabled,
			.schedule_type,
			.schedule_week,
			.schedule_day,
			.schedule_hour,
			.schedule_minute,
			.schedule_interval_value,
			.schedule_interval_unit,
			.schedule_custom_hours
		] | @tsv' 2>/dev/null >> "${output_file}" || return 1
	done
}

subprof_profile_exec_tsv() {
	local profile_id="$1"
	local profile_key=""
	local profile_json=""

	[ -n "${profile_id}" ] || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || return 1
	[ -n "${profile_json}" ] || return 1
	printf '%s' "${profile_json}" | "$(subprof_jq_bin)" -r '
		if ((.enabled // true) == true) then
			[
				(.id // ""),
				(.name // ""),
				(.url // ""),
				(.subscribe_mode // "2"),
				(.download.policy // "auto"),
				(.ua.mode // "fixed"),
				(.ua.preset // "default"),
				(.ua.custom // ""),
				(.filter.exclude // ""),
				(.filter.include // ""),
				(.flags.allow_insecure // false),
				(.flags.node_log // true),
				(.filter.keep_info_node // true),
				(.hy2.up // ""),
				(.hy2.dl // ""),
				(.hy2.tfo_switch // "2"),
				(.hy2.cg_opt // "bbr")
			] | @tsv
		else
			empty
		end
	' 2>/dev/null
}

subprof_collect_enabled_profiles_exec_tsv() {
	local output_file="$1"
	local profile_id=""

	[ -n "${output_file}" ] || return 1
	: > "${output_file}"
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		subprof_profile_exec_tsv "${profile_id}" >> "${output_file}" || true
	done
}

subprof_enabled_profile_count_fast() {
	local profile_id=""
	local count=0

	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		if [ -n "$(subprof_profile_exec_tsv "${profile_id}" 2>/dev/null | sed -n '1p')" ]; then
			count=$((count + 1))
		fi
	done
	printf '%s\n' "${count}"
}

subprof_cron_job_name() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf 'ssnodeprof_%s\n' "${profile_id}" | cut -c1-31
}

subprof_cron_value_csv() {
	local raw="$1"
	local min="$2"
	local max="$3"
	local fallback="$4"
	local item=""
	local out=""

	out="$(
		printf '%s\n' "${raw}" | tr ',' '\n' | while IFS= read -r item
		do
			item="$(printf '%s' "${item}" | sed 's/[^0-9]//g')"
			[ -n "${item}" ] || continue
			if [ "${item}" -ge "${min}" ] 2>/dev/null && [ "${item}" -le "${max}" ] 2>/dev/null; then
				printf '%s\n' "${item}"
			fi
		done | awk '!seen[$0]++' | tr '\n' ',' | sed 's/,$//'
	)"
	[ -n "${out}" ] && printf '%s\n' "${out}" || printf '%s\n' "${fallback}"
}

subprof_cron_week_csv() {
	local raw="$1"
	local parsed=""
	parsed="$(subprof_cron_value_csv "${raw}" 0 7 "1")"
	printf '%s\n' "${parsed}" | tr ',' '\n' | while IFS= read -r item
	do
		[ -n "${item}" ] || continue
		[ "${item}" = "7" ] && item="0"
		printf '%s\n' "${item}"
	done | awk '!seen[$0]++' | tr '\n' ',' | sed 's/,$//'
}

subprof_cron_minute() {
	local minute="$1"
	minute="$(printf '%s' "${minute}" | sed 's/[^0-9]//g')"
	if [ -n "${minute}" ] && [ "${minute}" -ge 0 ] 2>/dev/null && [ "${minute}" -le 59 ] 2>/dev/null; then
		printf '%s\n' "${minute}"
		return 0
	fi
	printf '%s\n' "5"
}

subprof_cron_hour() {
	local hour="$1"
	local parsed=""
	parsed="$(subprof_cron_value_csv "${hour}" 0 23 "")"
	[ -n "${parsed}" ] && printf '%s\n' "${parsed}" || printf '%s\n' "3"
}

subprof_cron_delay_for_index() {
	local idx="$1"
	[ -n "${idx}" ] || idx=0
	printf '%s\n' "$((idx * 10))"
}

subprof_profile_schedule_tsv() {
	local profile_id="$1"
	local profile_key=""
	local profile_json=""

	[ -n "${profile_id}" ] || return 1
	profile_key="$(subprof_profile_key "${profile_id}")" || return 1
	profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || return 1
	[ -n "${profile_json}" ] || return 1
	printf '%s' "${profile_json}" | "$(subprof_jq_bin)" -r '[
		(if .enabled == null then true else .enabled end),
		(if .schedule.enabled == null then true else .schedule.enabled end),
		(.schedule.type // "1"),
		(.schedule.week // "1"),
		(.schedule.day // "7"),
		(.schedule.hour // "3"),
		(.schedule.minute // "5"),
		(.schedule.interval_value // "1"),
		(.schedule.interval_unit // "2"),
		(.schedule.custom_hours // "")
	] | @tsv' 2>/dev/null
}

subprof_clear_cron_jobs() {
	local job_name=""
	if [ -x "/usr/sbin/cru" ]; then
		for job_name in $(cru l 2>/dev/null | awk '/^(ssnodeupdate|ssnodeprof_)/ {print $1}')
		do
			[ -n "${job_name}" ] || continue
			cru d "${job_name}" >/dev/null 2>&1 || true
		done
	fi
	sed -i '/ssnodeupdate/d;/ssnodeprof_/d' /var/spool/cron/crontabs/* >/dev/null 2>&1 || true
}

subprof_rebuild_cron_jobs() {
	local profile_id=""
	local row=""
	local old_ifs=""
	local profile_enabled=""
	local schedule_enabled=""
	local schedule_type=""
	local schedule_week=""
	local schedule_day=""
	local schedule_hour=""
	local schedule_minute=""
	local schedule_interval_value=""
	local schedule_interval_unit=""
	local schedule_custom_hours=""
	local job_name=""
	local cron_expr=""
	local command_text=""
	local delay_seconds=""
	local job_index=0

	subprof_clear_cron_jobs
	[ -x "/usr/sbin/cru" ] || return 0
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		row="$(subprof_profile_schedule_tsv "${profile_id}")" || row=""
		[ -n "${row}" ] || continue
		old_ifs="${IFS}"
		IFS="$(printf '\t')"
		read -r profile_enabled schedule_enabled schedule_type schedule_week schedule_day schedule_hour schedule_minute schedule_interval_value schedule_interval_unit schedule_custom_hours <<EOF
${row}
EOF
		IFS="${old_ifs}"
		[ "${profile_enabled}" = "true" ] || continue
		[ "${schedule_enabled}" = "true" ] || continue
		schedule_minute="$(subprof_cron_minute "${schedule_minute}")"
		schedule_hour="$(subprof_cron_hour "${schedule_hour}")"
		case "${schedule_type}" in
		2)
			schedule_week="$(subprof_cron_week_csv "${schedule_week}")"
			[ -n "${schedule_week}" ] || schedule_week="1"
			cron_expr="${schedule_minute} ${schedule_hour} * * ${schedule_week}"
			;;
		3)
			schedule_day="$(subprof_cron_value_csv "${schedule_day}" 1 31 "1")"
			[ -n "${schedule_day}" ] || schedule_day="1"
			cron_expr="${schedule_minute} ${schedule_hour} ${schedule_day} * *"
			;;
		4)
			schedule_interval_value="$(printf '%s' "${schedule_interval_value}" | sed 's/[^0-9]//g')"
			[ -n "${schedule_interval_value}" ] || schedule_interval_value="1"
			case "${schedule_interval_unit}" in
			1)
				[ "${schedule_interval_value}" -lt 1 ] 2>/dev/null && schedule_interval_value=1
				[ "${schedule_interval_value}" -gt 59 ] 2>/dev/null && schedule_interval_value=59
				cron_expr="*/${schedule_interval_value} * * * *"
				;;
			3)
				[ "${schedule_interval_value}" -lt 1 ] 2>/dev/null && schedule_interval_value=1
				[ "${schedule_interval_value}" -gt 30 ] 2>/dev/null && schedule_interval_value=30
				cron_expr="${schedule_minute} ${schedule_hour} */${schedule_interval_value} * *"
				;;
			*)
				[ "${schedule_interval_value}" -lt 1 ] 2>/dev/null && schedule_interval_value=1
				[ "${schedule_interval_value}" -gt 23 ] 2>/dev/null && schedule_interval_value=23
				cron_expr="${schedule_minute} */${schedule_interval_value} * * *"
				;;
			esac
			;;
		5)
			schedule_hour="$(subprof_cron_hour "${schedule_custom_hours}")"
			cron_expr="${schedule_minute} ${schedule_hour} * * *"
			;;
		*)
			cron_expr="${schedule_minute} ${schedule_hour} * * *"
			;;
		esac
		job_name="$(subprof_cron_job_name "${profile_id}")" || continue
		delay_seconds="$(subprof_cron_delay_for_index "${job_index}")"
		command_text="sleep ${delay_seconds}; FSS_SUBSCRIBE_LOCK_WAIT=1 /koolshare/scripts/ss_node_subscribe.sh 3 ${profile_id}"
		cru a "${job_name}" "${cron_expr} ${command_text}" >/dev/null 2>&1 || true
		job_index=$((job_index + 1))
	done
}

subprof_enabled_profile_count() {
	local tmp_file
	tmp_file="/tmp/.subprof_enabled.$$"
	subprof_collect_enabled_profiles_tsv "${tmp_file}" >/dev/null 2>&1 || {
		rm -f "${tmp_file}"
		printf '%s\n' "0"
		return 0
	}
	awk 'NF{c++} END{print c+0}' "${tmp_file}"
	rm -f "${tmp_file}"
}

subprof_mark_state_success() {
	local profile_id="$1"
	local url_hash="$2"
	local group_name="$3"
	local download_tool="$4"
	local download_path="$5"
	local ua_mode="$6"
	local ua_preset="$7"
	local state_key=""
	local state_json=""
	local new_state=""
	local now_ts=""

	[ -n "${profile_id}" ] || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
	now_ts="$(date +%s)"
	new_state="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -c \
		--arg id "${profile_id}" \
		--arg url_hash "${url_hash}" \
		--arg group_name "${group_name}" \
		--arg download_tool "${download_tool}" \
		--arg download_path "${download_path}" \
		--arg ua_mode "${ua_mode}" \
		--arg ua_preset "${ua_preset}" \
		--argjson now_ts "${now_ts}" '
		(. // {}) + {
			version: 1,
			id: $id,
			last_ok_ts: $now_ts,
			last_error_ts: 0,
			last_error: "",
			last_url_hash: $url_hash,
			last_group: $group_name,
			last_download_tool: $download_tool,
			last_download_path: $download_path,
			last_ua_mode: $ua_mode,
			last_ua_preset: $ua_preset
		}
	')" || return 1
	subprof_dbus_set_json_by_key "${state_key}" "${new_state}"
}

subprof_mark_state_failure() {
	local profile_id="$1"
	local error_text="$2"
	local url_hash="$3"
	local group_name="$4"
	local download_tool="$5"
	local download_path="$6"
	local ua_mode="$7"
	local ua_preset="$8"
	local state_key=""
	local state_json=""
	local new_state=""
	local now_ts=""

	[ -n "${profile_id}" ] || return 1
	state_key="$(subprof_state_key "${profile_id}")" || return 1
	state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
	now_ts="$(date +%s)"
	new_state="$(printf '%s' "${state_json}" | "$(subprof_jq_bin)" -c \
		--arg id "${profile_id}" \
		--arg error_text "${error_text}" \
		--arg url_hash "${url_hash}" \
		--arg group_name "${group_name}" \
		--arg download_tool "${download_tool}" \
		--arg download_path "${download_path}" \
		--arg ua_mode "${ua_mode}" \
		--arg ua_preset "${ua_preset}" \
		--argjson now_ts "${now_ts}" '
		(. // {}) + {
			version: 1,
			id: $id,
			last_error_ts: $now_ts,
			last_error: $error_text,
			last_url_hash: $url_hash,
			last_group: $group_name,
			last_download_tool: $download_tool,
			last_download_path: $download_path,
			last_ua_mode: $ua_mode,
			last_ua_preset: $ua_preset
		}
	')" || return 1
	subprof_dbus_set_json_by_key "${state_key}" "${new_state}"
}

subprof_migrate_legacy_profiles_if_needed() {
	local raw_links=""
	local tmp_links=""
	local seen_names=""
	local link=""
	local profile_id=""
	local profile_name=""
	local unique_name=""
	local suffix=""
	local name_count=0
	local migrated=0
	local payload_json=""
	local raw_tag=""
	local canonical_tag=""
	local legacy_tag=""
	local group_label=""
	local state_key=""
	local state_json=""

	subprof_has_profiles && return 0
	raw_links="$(dbus get ss_online_links | base64 -d 2>/dev/null)" || raw_links=""
	[ -n "${raw_links}" ] || return 1
	tmp_links="/tmp/.subprof_links.$$"
	seen_names="/tmp/.subprof_names.$$"
	printf '%s\n' "${raw_links}" \
		| sed '/^$/d' \
		| sed '/^#/d' \
		| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
		| grep -E '^https?://' > "${tmp_links}" 2>/dev/null
	[ -s "${tmp_links}" ] || {
		rm -f "${tmp_links}" "${seen_names}"
		return 1
	}
	: > "${seen_names}"
	while IFS= read -r link
	do
		[ -n "${link}" ] || continue
		profile_id="$(subprof_generate_profile_id 2>/dev/null)" || continue
		profile_name="$(subprof_pretty_name_from_url "${link}")"
		[ -n "${profile_name}" ] || profile_name="订阅"
		unique_name="${profile_name}"
		name_count=1
		while grep -Fxq "${unique_name}" "${seen_names}" 2>/dev/null
		do
			name_count=$((name_count + 1))
			suffix=$(printf '%s' "${profile_id}" | cut -c1-4)
			if [ "${name_count}" -gt 2 ]; then
				unique_name="${profile_name}-${suffix}-${name_count}"
			else
				unique_name="${profile_name}-${suffix}"
			fi
		done
		printf '%s\n' "${unique_name}" >> "${seen_names}"
		payload_json="$(subprof_build_legacy_payload_json "${profile_id}" "${unique_name}" "${link}")" || continue
		subprof_write_profile_json "${payload_json}" >/dev/null 2>&1 || continue
		raw_tag="$(fss_legacy_subscribe_domain_tag_from_url "${link}" 2>/dev/null)" || raw_tag=""
		canonical_tag=""
		[ -n "${raw_tag}" ] && canonical_tag="$(dbus get ss_online_hash_${raw_tag} 2>/dev/null)"
		[ -n "${canonical_tag}" ] || canonical_tag="${raw_tag}"
		legacy_tag="$(fss_legacy_subscribe_url_hash "${link}" 2>/dev/null)" || legacy_tag=""
		group_label="$(fss_legacy_subscribe_group_from_tags "${canonical_tag}" "${raw_tag}" "${legacy_tag}" 2>/dev/null)" || group_label=""
		[ -n "${group_label}" ] || group_label="${profile_name}"
		if [ -n "${group_label}" ] || [ -n "${legacy_tag}" ];then
			state_key="$(subprof_state_key "${profile_id}" 2>/dev/null)" || state_key=""
			if [ -n "${state_key}" ];then
				state_json="$("$(subprof_jq_bin)" -cn \
					--arg id "${profile_id}" \
					--arg url_hash "${legacy_tag}" \
					--arg group_name "${group_label}" \
					'{version:1,id:$id,last_ok_ts:0,last_error_ts:0,last_error:"",last_url_hash:$url_hash,last_group:$group_name}')"
				[ -n "${state_json}" ] && subprof_dbus_set_json_by_key "${state_key}" "${state_json}" >/dev/null 2>&1 || true
			fi
		fi
		migrated=$((migrated + 1))
	done < "${tmp_links}"
	rm -f "${tmp_links}" "${seen_names}"
	[ "${migrated}" -gt 0 ] || return 1
	dbus remove ss_online_links
	printf '%s\n' "${migrated}"
	return 0
}
