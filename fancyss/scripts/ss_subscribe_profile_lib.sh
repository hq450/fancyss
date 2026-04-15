#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source ${KSROOT}/scripts/ss_node_common.sh

SUB_PROFILE_ROOT="/koolshare/configs/fancyss/subscriptions"
SUB_PROFILE_DIR="${SUB_PROFILE_ROOT}/profiles"
SUB_PROFILE_STATE_DIR="${SUB_PROFILE_ROOT}/states"
SUB_PROFILE_RUNTIME_JSON="/tmp/upload/ss_subscribe_profiles.json"
SUB_PROFILE_TMP_PAYLOAD_KEY="ss_subscribe_profile_payload"
SUB_PROFILE_TMP_ID_KEY="ss_subscribe_profile_id"
SUB_PROFILE_TMP_SYNC_ID_KEY="ss_subscribe_profile_selected"
SUB_PROFILE_SCHEMA_VERSION="1"
NODE_TOOL_CONF_FILE="/koolshare/ss/rules/node-tool.conf"

subprof_jq_bin() {
	if [ -x "/koolshare/bin/jq" ]; then
		printf '%s\n' "/koolshare/bin/jq"
		return 0
	fi
	type jq 2>/dev/null | awk '{print $NF}' | sed -n '1p'
}

subprof_ensure_dirs() {
	mkdir -p "${SUB_PROFILE_DIR}" "${SUB_PROFILE_STATE_DIR}" >/dev/null 2>&1
}

subprof_runtime_json_file() {
	printf '%s\n' "${SUB_PROFILE_RUNTIME_JSON}"
}

subprof_profile_file() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf '%s/%s.json\n' "${SUB_PROFILE_DIR}" "${profile_id}"
}

subprof_state_file() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf '%s/%s.state.json\n' "${SUB_PROFILE_STATE_DIR}" "${profile_id}"
}

subprof_valid_profile_id() {
	local profile_id="$1"
	printf '%s' "${profile_id}" | grep -Eq '^[A-Za-z0-9._-]+$'
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
		--argjson node_log "$(subprof_boolean_string "$(dbus get ss_basic_sub_node_log)")" \
		--argjson keep_info_node "$(subprof_boolean_string "$(dbus get ss_basic_sub_keep_info_node)")" \
		--arg hy2_up "$(dbus get ss_basic_hy2_up_speed)" \
		--arg hy2_dl "$(dbus get ss_basic_hy2_dl_speed)" \
		--arg hy2_tfo_switch "$(dbus get ss_basic_hy2_tfo_switch)" \
		--arg hy2_cg_opt "$(dbus get ss_basic_hy2_cg_opt)" \
		--argjson schedule_enabled "$(subprof_boolean_string "$(dbus get ss_basic_node_update)")" \
		--arg schedule_day "$(dbus get ss_basic_node_update_day)" \
		--arg schedule_hour "$(dbus get ss_basic_node_update_hr)" '
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
				keep_info_node: $keep_info_node
			},
			flags: {
				allow_insecure: $allow_insecure,
				node_log: $node_log
			},
			hy2: {
				up: ($hy2_up // ""),
				dl: ($hy2_dl // ""),
				tfo_switch: (if ($hy2_tfo_switch // "") == "" then "2" else $hy2_tfo_switch end),
				cg_opt: (if ($hy2_cg_opt // "") == "" then "bbr" else $hy2_cg_opt end)
			},
			schedule: {
				enabled: $schedule_enabled,
				day: (if ($schedule_day // "") == "" then "7" else $schedule_day end),
				hour: (if ($schedule_hour // "") == "" then "3" else $schedule_hour end)
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
				keep_info_node: (pick3(.filter.keep_info_node; .keep_info_node; false) | to_bool)
			},
			flags: {
				allow_insecure: (pick3(.flags.allow_insecure; .allow_insecure; false) | to_bool),
				node_log: (pick3(.flags.node_log; .node_log; false) | to_bool)
			},
			hy2: {
				up: ((.hy2.up // .hy2_up // "") | tostring),
				dl: ((.hy2.dl // .hy2_dl // "") | tostring),
				tfo_switch: ((.hy2.tfo_switch // .hy2_tfo_switch // "2") | tostring | if . == "" then "2" else . end),
				cg_opt: ((.hy2.cg_opt // .hy2_cg_opt // "bbr") | tostring | if . == "" then "bbr" else . end)
			},
			schedule: {
				enabled: (pick3(.schedule.enabled; .schedule_enabled; false) | to_bool),
				day: ((.schedule.day // .schedule_day // "7") | tostring | if . == "" then "7" else . end),
				hour: ((.schedule.hour // .schedule_hour // "3") | tostring | if . == "" then "3" else . end)
			}
		}
	'
}

subprof_write_profile_json() {
	local payload_json="$1"
	local normalized=""
	local profile_id=""
	local profile_url=""
	local profile_file=""
	local state_file=""
	local existing_id=""
	local existing_file=""
	local existing_url=""

	subprof_ensure_dirs || return 1
	normalized="$(subprof_normalize_payload "${payload_json}")" || return 1
	profile_url="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -r '.url // empty' 2>/dev/null)"
	[ -n "${profile_url}" ] || return 1
	printf '%s' "${profile_url}" | grep -Eq '^https?://' || return 1

	profile_id="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -r '.id // empty' 2>/dev/null)"
	[ -n "${profile_id}" ] || profile_id="$(printf '%s' "${profile_url}" | md5sum | awk '{print substr($1,1,8)}')"
	subprof_valid_profile_id "${profile_id}" || return 1
	for existing_id in $(subprof_list_profile_ids)
	do
		[ -n "${existing_id}" ] || continue
		[ "${existing_id}" = "${profile_id}" ] && continue
		existing_file="$(subprof_profile_file "${existing_id}" 2>/dev/null)" || continue
		[ -f "${existing_file}" ] || continue
		existing_url="$("$(subprof_jq_bin)" -r '.url // empty' "${existing_file}" 2>/dev/null | sed -n '1p')"
		if [ -n "${existing_url}" ] && [ "${existing_url}" = "${profile_url}" ]; then
			return 1
		fi
	done
	normalized="$(printf '%s' "${normalized}" | "$(subprof_jq_bin)" -c --arg id "${profile_id}" '.id = $id')" || return 1

	profile_file="$(subprof_profile_file "${profile_id}")" || return 1
	state_file="$(subprof_state_file "${profile_id}")" || return 1
	printf '%s\n' "${normalized}" > "${profile_file}" || return 1
	if [ ! -s "${state_file}" ]; then
		"$(subprof_jq_bin)" -cn --arg id "${profile_id}" '{version:1,id:$id,last_ok_ts:0,last_error_ts:0,last_error:"",last_url_hash:"",last_group:""}' > "${state_file}" 2>/dev/null || true
	fi
	printf '%s\n' "${profile_id}"
	return 0
}

subprof_remove_profile() {
	local profile_id="$1"
	local profile_file=""
	local state_file=""

	[ -n "${profile_id}" ] || return 1
	subprof_valid_profile_id "${profile_id}" || return 1
	profile_file="$(subprof_profile_file "${profile_id}")" || return 1
	state_file="$(subprof_state_file "${profile_id}")" || return 1
	rm -f "${profile_file}" "${state_file}" >/dev/null 2>&1
	return 0
}

subprof_list_profile_ids() {
	[ -d "${SUB_PROFILE_DIR}" ] || return 0
	find "${SUB_PROFILE_DIR}" -maxdepth 1 -type f -name '*.json' 2>/dev/null \
		| sed 's#.*/##' \
		| sed 's/\.json$//' \
		| sort
}

subprof_has_profiles() {
	[ -n "$(subprof_list_profile_ids | sed -n '1p')" ]
}

subprof_count_profile_nodes_fast() {
	local profile_id="$1"
	local source_scope="$2"
	local node_tool=""
	local jq_bin=""
	local count=""

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
	return 1
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

subprof_merge_profile_and_state() {
	local profile_id="$1"
	local profile_file=""
	local state_file=""
	local node_count="0"
	local airport_identity=""
	local last_url_hash=""
	local last_group=""
	local source_scope=""

	[ -n "${profile_id}" ] || return 1
	profile_file="$(subprof_profile_file "${profile_id}")" || return 1
	[ -f "${profile_file}" ] || return 1
	state_file="$(subprof_state_file "${profile_id}")" || return 1
	if [ ! -f "${state_file}" ]; then
		"$(subprof_jq_bin)" -cn --arg id "${profile_id}" '{version:1,id:$id,last_ok_ts:0,last_error_ts:0,last_error:"",last_url_hash:"",last_group:""}' > "${state_file}" 2>/dev/null || printf '{}\n' > "${state_file}"
	fi
	last_group="$("$(subprof_jq_bin)" -r '.last_group // empty' "${state_file}" 2>/dev/null | sed -n '1p')"
	last_url_hash="$("$(subprof_jq_bin)" -r '.last_url_hash // empty' "${state_file}" 2>/dev/null | sed -n '1p')"
	if [ -n "${last_group}" ]; then
		airport_identity="$(fss_identity_slugify "${last_group}" "sub" 2>/dev/null)"
		source_scope="${airport_identity}"
		[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"
	fi
	node_count="$(subprof_count_profile_nodes_fast "${profile_id}" "${source_scope}" 2>/dev/null)" || node_count=""
	[ -n "${node_count}" ] || node_count="$(subprof_count_profile_nodes_fallback "${profile_id}" "${source_scope}" 2>/dev/null)"
	[ -n "${node_count}" ] || node_count="0"
	"$(subprof_jq_bin)" -cn \
		--slurpfile profile "${profile_file}" \
		--slurpfile state "${state_file}" \
		--argjson node_count "${node_count}" '
		($profile[0] // {}) as $p
		| ($state[0] // {}) as $s
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
			keep_info_node: (if $p.filter.keep_info_node == null then false else $p.filter.keep_info_node end),
			allow_insecure: (if $p.flags.allow_insecure == null then false else $p.flags.allow_insecure end),
			node_log: (if $p.flags.node_log == null then false else $p.flags.node_log end),
			hy2_up: ($p.hy2.up // ""),
			hy2_dl: ($p.hy2.dl // ""),
			hy2_tfo_switch: ($p.hy2.tfo_switch // "2"),
			hy2_cg_opt: ($p.hy2.cg_opt // "bbr"),
			schedule_enabled: (if $p.schedule.enabled == null then false else $p.schedule.enabled end),
			schedule_day: ($p.schedule.day // "7"),
			schedule_hour: ($p.schedule.hour // "3"),
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

subprof_write_profiles_runtime_json() {
	local runtime_json
	local tmp_file=""
	local profile_id=""
	local first=1

	subprof_ensure_dirs || return 1
	runtime_json="$(subprof_runtime_json_file)"
	tmp_file="${runtime_json}.tmp.$$"
	{
		printf '{"version":1,"items":['
		for profile_id in $(subprof_list_profile_ids)
		do
			[ -n "${profile_id}" ] || continue
			local row=""
			row="$(subprof_merge_profile_and_state "${profile_id}")" || row=""
			[ -n "${row}" ] || continue
			if [ "${first}" = "1" ]; then
				first=0
			else
				printf ','
			fi
			printf '%s' "${row}"
		done
		printf ']}'
	} > "${tmp_file}" || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${runtime_json}"
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
			.schedule_day,
			.schedule_hour
		] | @tsv' 2>/dev/null >> "${output_file}" || return 1
	done
}

subprof_cron_job_name() {
	local profile_id="$1"
	[ -n "${profile_id}" ] || return 1
	printf 'ssnodeprof_%s\n' "${profile_id}" | cut -c1-31
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
	local schedule_enabled=""
	local schedule_day=""
	local schedule_hour=""
	local job_name=""
	local cron_expr=""
	local command_text=""

	subprof_clear_cron_jobs
	[ -x "/usr/sbin/cru" ] || return 0
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		row="$(subprof_merge_profile_and_state "${profile_id}")" || row=""
		[ -n "${row}" ] || continue
		schedule_enabled="$(printf '%s' "${row}" | "$(subprof_jq_bin)" -r '.schedule_enabled // false' 2>/dev/null)"
		[ "${schedule_enabled}" = "true" ] || continue
		schedule_day="$(printf '%s' "${row}" | "$(subprof_jq_bin)" -r '.schedule_day // "7"' 2>/dev/null)"
		schedule_hour="$(printf '%s' "${row}" | "$(subprof_jq_bin)" -r '.schedule_hour // "3"' 2>/dev/null)"
		[ -n "${schedule_hour}" ] || schedule_hour="3"
		if [ "${schedule_day}" = "7" ]; then
			cron_expr="0 ${schedule_hour} * * *"
		else
			cron_expr="0 ${schedule_hour} * * ${schedule_day}"
		fi
		job_name="$(subprof_cron_job_name "${profile_id}")" || continue
		command_text="dbus set ${SUB_PROFILE_TMP_SYNC_ID_KEY}=${profile_id}; /koolshare/scripts/ss_node_subscribe.sh fancyss 3"
		cru a "${job_name}" "${cron_expr} ${command_text}" >/dev/null 2>&1 || true
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
	local state_file=""
	local tmp_file=""
	local now_ts=""

	[ -n "${profile_id}" ] || return 1
	state_file="$(subprof_state_file "${profile_id}")" || return 1
	tmp_file="${state_file}.tmp.$$"
	now_ts="$(date +%s)"
	"$(subprof_jq_bin)" -cn \
		--slurpfile old "${state_file}" \
		--arg id "${profile_id}" \
		--arg url_hash "${url_hash}" \
		--arg group_name "${group_name}" \
		--arg download_tool "${download_tool}" \
		--arg download_path "${download_path}" \
		--arg ua_mode "${ua_mode}" \
		--arg ua_preset "${ua_preset}" \
		--argjson now_ts "${now_ts}" '
		(($old[0] // {}) + {
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
		})
	' > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${state_file}"
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
	local state_file=""
	local tmp_file=""
	local now_ts=""

	[ -n "${profile_id}" ] || return 1
	state_file="$(subprof_state_file "${profile_id}")" || return 1
	tmp_file="${state_file}.tmp.$$"
	now_ts="$(date +%s)"
	"$(subprof_jq_bin)" -cn \
		--slurpfile old "${state_file}" \
		--arg id "${profile_id}" \
		--arg error_text "${error_text}" \
		--arg url_hash "${url_hash}" \
		--arg group_name "${group_name}" \
		--arg download_tool "${download_tool}" \
		--arg download_path "${download_path}" \
		--arg ua_mode "${ua_mode}" \
		--arg ua_preset "${ua_preset}" \
		--argjson now_ts "${now_ts}" '
		(($old[0] // {}) + {
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
		})
	' > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${state_file}"
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

	subprof_has_profiles && return 0
	raw_links="$(dbus get ss_online_links | base64_decode 2>/dev/null)" || raw_links=""
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
		profile_id="$(printf '%s' "${link}" | md5sum | awk '{print substr($1,1,8)}')"
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
		migrated=$((migrated + 1))
	done < "${tmp_links}"
	rm -f "${tmp_links}" "${seen_names}"
	[ "${migrated}" -gt 0 ] || return 1
	dbus remove ss_online_links
	printf '%s\n' "${migrated}"
	return 0
}
