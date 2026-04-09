#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source ${KSROOT}/scripts/ss_node_common.sh
[ -f "${KSROOT}/scripts/ss_webtest_gen.sh" ] && source ${KSROOT}/scripts/ss_webtest_gen.sh

eval $(dbus export ss_basic_)

FSS_SHUNT_RULES_DBUS_KEY="ss_basic_shunt_rules"
FSS_SHUNT_CUSTOM_PRESETS_DBUS_KEY="ss_basic_shunt_custom_presets"
FSS_SHUNT_DEFAULT_NODE_DBUS_KEY="ss_basic_shunt_default_node"
FSS_SHUNT_DEFAULT_NODE_IDENTITY_DBUS_KEY="ss_basic_shunt_default_node_identity"
FSS_SHUNT_RULE_TS_DBUS_KEY="ss_basic_shunt_rule_ts"
FSS_SHUNT_INGRESS_MODE_DBUS_KEY="ss_basic_shunt_ingress_mode"
FSS_SHUNT_RULE_BACKEND_DBUS_KEY="ss_basic_shunt_rule_backend"
FSS_SHUNT_MAX_RULES=16
FSS_SHUNT_MAX_TARGETS=8
FSS_SHUNT_DIRECT_TARGET="DIRECT"
FSS_SHUNT_REJECT_TARGET="REJECT"
FSS_SHUNT_RULES_FILE="${KSROOT}/configs/fancyss/node_shunt_rules.json"
FSS_SHUNT_RUNTIME_DIR="/tmp/fancyss_shunt"
FSS_SHUNT_RUNTIME_RULE_DIR="${FSS_SHUNT_RUNTIME_DIR}/rules"
FSS_SHUNT_RUNTIME_ACTIVE_FILE="${FSS_SHUNT_RUNTIME_DIR}/active_rules.tsv"
FSS_SHUNT_RUNTIME_TARGET_FILE="${FSS_SHUNT_RUNTIME_DIR}/target_nodes.txt"
FSS_SHUNT_RUNTIME_META_FILE="${FSS_SHUNT_RUNTIME_DIR}/runtime.meta"
FSS_SHUNT_RUNTIME_OUTBOUND_DIR="${FSS_SHUNT_RUNTIME_DIR}/outbounds"
FSS_SHUNT_RUNTIME_ARTIFACT_DIR="${FSS_SHUNT_RUNTIME_DIR}/runtime_artifacts"
FSS_SHUNT_RUNTIME_ARTIFACT_LOCK="/tmp/fss_runtime_artifact_shunt.lock"
FSS_SHUNT_CACHE_STATE_DIR="/tmp/fancyss_cache_state"
FSS_SHUNT_RUNTIME_STATE_FILE="${FSS_SHUNT_CACHE_STATE_DIR}/shunt.state"
FSS_SHUNT_RUNTIME_PROXY_FILE="/tmp/ss_shunt_proxy.txt"
FSS_SHUNT_HOT_STATE_FILE="${FSS_SHUNT_RUNTIME_DIR}/hot_reload_state.tsv"
FSS_SHUNT_RUNTIME_CHNLIST_FILE="/tmp/chnlist.txt"
FSS_SHUNT_RUNTIME_GFWLIST_FILE="/tmp/gfwlist.txt"
FSS_SHUNT_RUNTIME_CHNROUTE4_FILE="/tmp/chnroute.txt"
FSS_SHUNT_RUNTIME_CHNROUTE6_FILE="/tmp/chnroute6.txt"
FSS_SHUNT_RULES_ROOT="${KSROOT}/ss/rules_ng2"
FSS_SHUNT_SITE_DIR="${FSS_SHUNT_RULES_ROOT}/site"
FSS_SHUNT_IP_DIR="${FSS_SHUNT_RULES_ROOT}/ip"
FSS_SHUNT_META_PRESETS_FILE="${FSS_SHUNT_RULES_ROOT}/meta/presets.json"
FSS_SHUNT_DAT_DIR="${FSS_SHUNT_RULES_ROOT}/dat"
FSS_SHUNT_GEOSITE_FILE="${FSS_SHUNT_DAT_DIR}/geosite.dat"
FSS_SHUNT_GEOIP_FILE="${FSS_SHUNT_DAT_DIR}/geoip.dat"
FSS_SHUNT_GEOTOOL_BIN="${KSROOT}/bin/geotool"
FSS_SHUNT_WEBTEST_HELPER="${KSROOT}/scripts/ss_webtest.sh"
FSS_SCRIPT_DIR="${KSROOT}/scripts"

fss_shunt_log() {
	echo "【$(date +'%Y%m%d %H:%M:%S')】: $*"
}

fss_shunt_state_count_ids() {
	local ids_file="$1"
	local count="0"

	[ -f "${ids_file}" ] || {
		printf '%s' "0"
		return 0
	}
	count=$(wc -l < "${ids_file}" | tr -d ' ')
	[ -n "${count}" ] || count="0"
	printf '%s' "${count}"
}

fss_shunt_state_write() {
	local status="$1"
	local phase="$2"
	local reason="$3"
	local ids_file="$4"
	local message="$5"
	local target_count=""

	mkdir -p "${FSS_SHUNT_CACHE_STATE_DIR}" >/dev/null 2>&1 || return 1
	target_count="$(fss_shunt_state_count_ids "${ids_file}")"
	cat > "${FSS_SHUNT_RUNTIME_STATE_FILE}.tmp.$$" <<-EOF
		status=${status}
		phase=${phase}
		reason=${reason}
		pid=$$
		target_count=${target_count}
		message=${message}
		updated_at=$(date +%s)
	EOF
	mv -f "${FSS_SHUNT_RUNTIME_STATE_FILE}.tmp.$$" "${FSS_SHUNT_RUNTIME_STATE_FILE}"
}

fss_shunt_state_get() {
	local key="$1"

	[ -n "${key}" ] || return 1
	[ -f "${FSS_SHUNT_RUNTIME_STATE_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_SHUNT_RUNTIME_STATE_FILE}" | sed -n '1p'
}

fss_shunt_state_begin() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	fss_shunt_state_write "building" "init" "${reason}" "${ids_file}" "${message}"
}

fss_shunt_state_phase() {
	local phase="$1"
	local reason="$2"
	local ids_file="$3"
	local message="$4"
	fss_shunt_state_write "building" "${phase}" "${reason}" "${ids_file}" "${message}"
}

fss_shunt_state_ready() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	fss_shunt_state_write "ready" "done" "${reason}" "${ids_file}" "${message}"
}

fss_shunt_state_failed() {
	local reason="$1"
	local ids_file="$2"
	local message="$3"
	fss_shunt_state_write "failed" "failed" "${reason}" "${ids_file}" "${message}"
}

fss_shunt_runtime_artifact_lock_acquire() {
	local waited=0
	local owner_pid=""
	local owner_phase=""
	local owner_count=""

	while ! mkdir "${FSS_SHUNT_RUNTIME_ARTIFACT_LOCK}" 2>/dev/null
	do
		owner_pid="$(sed -n '1p' "${FSS_SHUNT_RUNTIME_ARTIFACT_LOCK}/pid" 2>/dev/null)"
		if [ -n "${owner_pid}" ] && kill -0 "${owner_pid}" 2>/dev/null; then
			owner_phase="$(fss_shunt_state_get "phase")"
			owner_count="$(fss_shunt_state_get "target_count")"
			[ $((waited % 2)) -eq 0 ] && fss_shunt_log "ℹ️节点运行产物正在由其它任务重建，当前阶段：${owner_phase:-unknown}，目标节点：${owner_count:-0}，已等待 ${waited}s。"
			[ "${waited}" -lt 60 ] || return 1
			sleep 1
			waited=$((waited + 1))
			continue
		fi
		rm -rf "${FSS_SHUNT_RUNTIME_ARTIFACT_LOCK}" >/dev/null 2>&1
	done
	echo "$$" > "${FSS_SHUNT_RUNTIME_ARTIFACT_LOCK}/pid"
}

fss_shunt_runtime_artifact_lock_release() {
	rm -rf "${FSS_SHUNT_RUNTIME_ARTIFACT_LOCK}" >/dev/null 2>&1
}

fss_shunt_mode_selected() {
	[ "${ss_basic_mode}" = "7" ]
}

fss_shunt_rules_enabled() {
	return 0
}

fss_shunt_is_active() {
	fss_shunt_mode_selected
}

fss_shunt_cleanup_runtime() {
	rm -rf "${FSS_SHUNT_RUNTIME_DIR}" >/dev/null 2>&1
	rm -f "${FSS_SHUNT_RUNTIME_PROXY_FILE}" >/dev/null 2>&1
	unset FSS_SHUNT_RUNTIME_READY FSS_SHUNT_RUNTIME_READY_KEY
}

fss_shunt_runtime_mode() {
	local mode="${ss_basic_shunt_ingress_mode}"

	[ -n "${mode}" ] || mode="$(dbus get ${FSS_SHUNT_INGRESS_MODE_DBUS_KEY})"
	case "${mode}" in
	5)
		echo "5"
		;;
	*)
		echo "2"
		;;
	esac
}

fss_shunt_effective_mode() {
	if fss_shunt_mode_selected; then
		echo "7"
	else
		echo "${ss_basic_mode}"
	fi
}

fss_shunt_rule_backend() {
	local backend="${ss_basic_shunt_rule_backend}"

	[ -n "${backend}" ] || backend="$(dbus get ${FSS_SHUNT_RULE_BACKEND_DBUS_KEY})"
	case "${backend}" in
	geodata|dat)
		echo "geodata"
		;;
	*)
		echo "text"
		;;
	esac
}

fss_shunt_pick_geotool() {
	if [ -x "${FSS_SHUNT_GEOTOOL_BIN}" ]; then
		echo "${FSS_SHUNT_GEOTOOL_BIN}"
		return 0
	fi
	if command -v geotool >/dev/null 2>&1; then
		command -v geotool
		return 0
	fi
	return 1
}

fss_shunt_dat_store_ready() {
	[ -s "${FSS_SHUNT_GEOSITE_FILE}" ] || return 1
	[ -s "${FSS_SHUNT_GEOIP_FILE}" ] || return 1
	fss_shunt_pick_geotool >/dev/null 2>&1
}

fss_shunt_geodata_ready() {
	[ "$(fss_shunt_rule_backend)" = "geodata" ] || return 1
	fss_shunt_dat_store_ready
}

fss_shunt_xray_asset_dir() {
	fss_shunt_geodata_ready || return 1
	printf '%s\n' "${FSS_SHUNT_DAT_DIR}"
}

fss_shunt_preset_asset_list() {
	local preset_id="$1"
	local family="$2"
	local jq_bin=""

	[ -n "${preset_id}" ] || return 1
	[ -n "${family}" ] || return 1
	[ -f "${FSS_SHUNT_META_PRESETS_FILE}" ] || return 1
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || return 1
	"${jq_bin}" -r --arg id "${preset_id}" --arg family "${family}" '
		.[]?
		| select((.id // "") == $id)
		| .[$family][]?
	' "${FSS_SHUNT_META_PRESETS_FILE}" 2>/dev/null
}

fss_shunt_join_csv() {
	local first=1
	local item=""

	while IFS= read -r item
	do
		[ -n "${item}" ] || continue
		if [ "${first}" = "1" ]; then
			first=0
			printf '%s' "${item}"
		else
			printf ',%s' "${item}"
		fi
	done
}

fss_shunt_export_site_assets() {
	local assets_csv="$1"
	local out_file="$2"
	local geotool_bin=""
	local asset_id=""

	[ -n "${out_file}" ] || return 1
	: > "${out_file}"
	[ -n "${assets_csv}" ] || return 0
	if fss_shunt_dat_store_ready; then
		geotool_bin="$(fss_shunt_pick_geotool)" || return 1
		"${geotool_bin}" export -i "${FSS_SHUNT_GEOSITE_FILE}" -c "${assets_csv}" -o "${out_file}" >/dev/null 2>&1 || return 1
		sort -u "${out_file}" -o "${out_file}" 2>/dev/null || true
		return 0
	fi
	printf '%s' "${assets_csv}" | tr ',' '\n' | while IFS= read -r asset_id
	do
		[ -n "${asset_id}" ] || continue
		[ -f "${FSS_SHUNT_SITE_DIR}/${asset_id}.txt" ] || continue
		cat "${FSS_SHUNT_SITE_DIR}/${asset_id}.txt"
	done | awk '!seen[$0]++' > "${out_file}"
}

fss_shunt_export_ip_assets() {
	local assets_csv="$1"
	local out_file="$2"
	local geotool_bin=""
	local asset_id=""

	[ -n "${out_file}" ] || return 1
	: > "${out_file}"
	[ -n "${assets_csv}" ] || return 0
	if fss_shunt_dat_store_ready; then
		geotool_bin="$(fss_shunt_pick_geotool)" || return 1
		"${geotool_bin}" geoip-export -i "${FSS_SHUNT_GEOIP_FILE}" -c "${assets_csv}" -o "${out_file}" >/dev/null 2>&1 || return 1
		sort -u "${out_file}" -o "${out_file}" 2>/dev/null || true
		return 0
	fi
	printf '%s' "${assets_csv}" | tr ',' '\n' | while IFS= read -r asset_id
	do
		[ -n "${asset_id}" ] || continue
		[ -f "${FSS_SHUNT_IP_DIR}/${asset_id}.txt" ] || continue
		cat "${FSS_SHUNT_IP_DIR}/${asset_id}.txt"
	done | awk '!seen[$0]++' > "${out_file}"
}

fss_shunt_export_runtime_base_rules() {
	local geotool_bin=""
	local plan_file="/tmp/fss_shunt_base_rules.plan.$$"

	fss_shunt_mode_selected || return 1
	fss_shunt_dat_store_ready || return 1
	geotool_bin="$(fss_shunt_pick_geotool)" || return 1

	cat > "${plan_file}" <<-EOF
		site|domain|cn|${FSS_SHUNT_RUNTIME_CHNLIST_FILE}
		site|domain|gfw|${FSS_SHUNT_RUNTIME_GFWLIST_FILE}
		ip|cidr4|cn|${FSS_SHUNT_RUNTIME_CHNROUTE4_FILE}
		ip|cidr6|cn|${FSS_SHUNT_RUNTIME_CHNROUTE6_FILE}
	EOF

	"${geotool_bin}" batch-export \
		--geosite "${FSS_SHUNT_GEOSITE_FILE}" \
		--geoip "${FSS_SHUNT_GEOIP_FILE}" \
		--plan "${plan_file}" >/dev/null 2>&1
	local ret=$?
	rm -f "${plan_file}"
	return "${ret}"
}

fss_shunt_get_runtime_chnroute4_file() {
	[ -s "${FSS_SHUNT_RUNTIME_CHNROUTE4_FILE}" ] || return 1
	printf '%s\n' "${FSS_SHUNT_RUNTIME_CHNROUTE4_FILE}"
}

fss_shunt_get_runtime_chnroute6_file() {
	[ -s "${FSS_SHUNT_RUNTIME_CHNROUTE6_FILE}" ] || return 1
	printf '%s\n' "${FSS_SHUNT_RUNTIME_CHNROUTE6_FILE}"
}

fss_shunt_batch_export_assets() {
	local site_assets_csv="$1"
	local domain_file="$2"
	local proxy_file="$3"
	local ip_assets_csv="$4"
	local ip_file="$5"
	local geotool_bin=""
	local plan_file="${domain_file}.plan.$$"

	[ -n "${domain_file}" ] || return 1
	[ -n "${proxy_file}" ] || return 1
	[ -n "${ip_file}" ] || return 1
	fss_shunt_dat_store_ready || return 1
	geotool_bin="$(fss_shunt_pick_geotool)" || return 1

	: > "${plan_file}" || return 1
	if [ -n "${site_assets_csv}" ]; then
		printf 'site|raw|%s|%s\n' "${site_assets_csv}" "${domain_file}" >> "${plan_file}"
		printf 'site|domain|%s|%s\n' "${site_assets_csv}" "${proxy_file}" >> "${plan_file}"
	fi
	if [ -n "${ip_assets_csv}" ]; then
		printf 'ip|cidr|%s|%s\n' "${ip_assets_csv}" "${ip_file}" >> "${plan_file}"
	fi

	if [ ! -s "${plan_file}" ]; then
		rm -f "${plan_file}"
		return 1
	fi

	"${geotool_bin}" batch-export \
		--geosite "${FSS_SHUNT_GEOSITE_FILE}" \
		--geoip "${FSS_SHUNT_GEOIP_FILE}" \
		--plan "${plan_file}" >/dev/null 2>&1
	local ret=$?
	rm -f "${plan_file}"
	return "${ret}"
}

fss_shunt_preset_assets_csv() {
	local preset_id="$1"
	local family="$2"

	fss_shunt_preset_asset_list "${preset_id}" "${family}" 2>/dev/null | fss_shunt_join_csv
}

fss_shunt_custom_presets_json() {
	local raw_b64="${ss_basic_shunt_custom_presets}"
	local decoded=""
	local jq_bin=""

	[ -n "${raw_b64}" ] || raw_b64="$(dbus get ${FSS_SHUNT_CUSTOM_PRESETS_DBUS_KEY})"
	[ -n "${raw_b64}" ] || {
		echo '[]'
		return 0
	}
	decoded="$(fss_b64_decode "${raw_b64}" 2>/dev/null)"
	[ -n "${decoded}" ] || {
		echo '[]'
		return 0
	}
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || {
		echo '[]'
		return 0
	}
	printf '%s' "${decoded}" | "${jq_bin}" -c '.' 2>/dev/null || echo '[]'
}

fss_shunt_custom_preset_get() {
	local preset_id="$1"
	local field="$2"
	local jq_bin=""
	local json=""

	[ -n "${preset_id}" ] || return 1
	[ -n "${field}" ] || return 1
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || return 1
	json="$(fss_shunt_custom_presets_json)"
	printf '%s' "${json}" | "${jq_bin}" -r --arg id "${preset_id}" --arg field "${field}" '
		.[]?
		| select((.id // "") == $id)
		| .[$field] // empty
	' 2>/dev/null | sed -n '1p'
}

fss_shunt_is_custom_preset() {
	local preset_id="$1"
	local val=""

	val="$(fss_shunt_custom_preset_get "${preset_id}" "id" 2>/dev/null)"
	[ -n "${val}" ]
}

fss_shunt_custom_domain_to_tokens() {
	awk -v domain_file="$1" -v proxy_file="$2" '
		function normalize(line, lower, prefix, value, token) {
			gsub(/\r/, "", line)
			sub(/#.*/, "", line)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			if (line == "") return ""
			lower = tolower(line)
			prefix = "domain"
			value = lower
			if (lower ~ /^domain,/) {
				prefix = "full"
				value = substr(lower, 8)
			} else if (lower ~ /^domain-suffix,/) {
				prefix = "domain"
				value = substr(lower, 15)
			} else if (lower ~ /^domain-keyword,/) {
				prefix = "keyword"
				value = substr(lower, 16)
			} else if (lower ~ /^full:/) {
				prefix = "full"
				value = substr(lower, 6)
			} else if (lower ~ /^domain:/) {
				prefix = "domain"
				value = substr(lower, 8)
			} else if (lower ~ /^keyword:/) {
				prefix = "keyword"
				value = substr(lower, 9)
			}
			gsub(/^[*.]+/, "", value)
			gsub(/[[:space:]]+$/, "", value)
			if (value == "") return ""
			if (prefix == "keyword") {
				if (value !~ /^[a-z0-9._-]+$/) return ""
			} else {
				if (value !~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) return ""
			}
			return prefix ":" value
		}
		{
			token = normalize($0)
			if (token == "" || seen[token]++) next
			print token > domain_file
			if (token ~ /^(full|domain):/) print substr(token, index(token, ":") + 1) >> proxy_file
		}
	'
}

fss_shunt_custom_ip_to_tokens() {
	awk -v ip_file="$1" '
		function valid_cidr(value) {
			return value ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}(\/[0-9]{1,2})?$/ || value ~ /^[0-9a-f:]+\/[0-9]{1,3}$/
		}
		{
			line = $0
			gsub(/\r/, "", line)
			sub(/#.*/, "", line)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			line = tolower(line)
			if (line == "") next
			if (line ~ /^ip-cidr:/) line = substr(line, 9)
			if (valid_cidr(line) && !seen[line]++) print line > ip_file
		}
	'
}

fss_shunt_rules_json() {
	local rules_b64="${ss_basic_shunt_rules}"
	local decoded=""
	local jq_bin=""

	[ -n "${rules_b64}" ] || rules_b64="$(dbus get ${FSS_SHUNT_RULES_DBUS_KEY})"
	[ -n "${rules_b64}" ] || {
		echo '[]'
		return 0
	}
	decoded="$(fss_b64_decode "${rules_b64}" 2>/dev/null)"
	[ -n "${decoded}" ] || {
		echo '[]'
		return 0
	}
	jq_bin="$(fss_pick_jq_bin)"
	if [ -n "${jq_bin}" ]; then
		printf '%s' "${decoded}" | "${jq_bin}" -c '.' 2>/dev/null || echo '[]'
	else
		echo '[]'
	fi
}

fss_shunt_sync_identity_shadows() {
	local json=""
	local jq_bin=""
	local default_target=""
	local default_identity=""
	local new_default_identity=""
	local new_json=""

	json="$(fss_shunt_rules_json)"
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || return 0
	new_json="$(printf '%s' "${json}" | "${jq_bin}" -c '.[]?' 2>/dev/null | while IFS= read -r line
	do
		local target_id=""
		local target_identity=""
		local resolved_identity=""
		[ -n "${line}" ] || continue
		target_id=$(printf '%s' "${line}" | "${jq_bin}" -r '.target_node_id // empty' 2>/dev/null)
		target_identity=$(printf '%s' "${line}" | "${jq_bin}" -r '.target_node_identity // empty' 2>/dev/null)
		if fss_shunt_target_is_direct "${target_id}" || fss_shunt_target_is_reject "${target_id}"; then
			printf '%s' "${line}" | "${jq_bin}" -c '.target_node_identity = ""'
			continue
		fi
		if [ -n "${target_id}" ] && fss_shunt_target_is_proxy_node "${target_id}" && [ -z "${target_identity}" ]; then
			resolved_identity="$(fss_get_node_identity_by_id "${target_id}" 2>/dev/null)"
			if [ -n "${resolved_identity}" ]; then
				printf '%s' "${line}" | "${jq_bin}" -c --arg identity "${resolved_identity}" '.target_node_identity = $identity'
				continue
			fi
		fi
		printf '%s\n' "${line}"
	done | "${jq_bin}" -s -c '.')"
	[ -n "${new_json}" ] || new_json='[]'
	if [ "${new_json}" != "${json}" ]; then
		dbus set ${FSS_SHUNT_RULES_DBUS_KEY}="$(fss_b64_encode "${new_json}")"
		fss_shunt_write_rules_mirror "${new_json}" >/dev/null 2>&1 || true
	fi

	default_target="${ss_basic_shunt_default_node}"
	[ -n "${default_target}" ] || default_target="$(dbus get ${FSS_SHUNT_DEFAULT_NODE_DBUS_KEY})"
	default_identity="$(dbus get ${FSS_SHUNT_DEFAULT_NODE_IDENTITY_DBUS_KEY})"
	if fss_shunt_target_is_direct "${default_target}" || fss_shunt_target_is_reject "${default_target}"; then
		[ -n "${default_identity}" ] && dbus set ${FSS_SHUNT_DEFAULT_NODE_IDENTITY_DBUS_KEY}=""
	elif [ -n "${default_target}" ] && fss_shunt_target_is_proxy_node "${default_target}" && [ -z "${default_identity}" ]; then
		new_default_identity="$(fss_get_node_identity_by_id "${default_target}" 2>/dev/null)"
		[ -n "${new_default_identity}" ] && dbus set ${FSS_SHUNT_DEFAULT_NODE_IDENTITY_DBUS_KEY}="${new_default_identity}"
	fi
}

fss_shunt_resolve_target_id() {
	local target_id="$1"
	local target_identity="$2"
	local mapped=""

	if fss_shunt_target_is_direct "${target_id}"; then
		echo "${FSS_SHUNT_DIRECT_TARGET}"
		return 0
	fi
	if fss_shunt_target_is_reject "${target_id}"; then
		echo "${FSS_SHUNT_REJECT_TARGET}"
		return 0
	fi
	if [ -n "${target_id}" ] && fss_shunt_target_is_proxy_node "${target_id}"; then
		echo "${target_id}"
		return 0
	fi
	if [ -n "${target_identity}" ]; then
		mapped="$(fss_find_node_id_by_identity "${target_identity}" 2>/dev/null)"
		if [ -n "${mapped}" ] && fss_shunt_target_is_proxy_node "${mapped}"; then
			echo "${mapped}"
			return 0
		fi
	fi
	return 1
}

fss_shunt_rules_json_resolved() {
	local json=""
	local jq_bin=""

	fss_shunt_sync_identity_shadows >/dev/null 2>&1 || true
	json="$(fss_shunt_rules_json)"
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || {
		echo '[]'
		return 0
	}
	printf '%s' "${json}" | "${jq_bin}" -c '.[]?' 2>/dev/null | while IFS= read -r line
	do
		local target_id=""
		local target_identity=""
		local resolved=""
		[ -n "${line}" ] || continue
		target_id=$(printf '%s' "${line}" | "${jq_bin}" -r '.target_node_id // empty' 2>/dev/null)
		target_identity=$(printf '%s' "${line}" | "${jq_bin}" -r '.target_node_identity // empty' 2>/dev/null)
		resolved=$(fss_shunt_resolve_target_id "${target_id}" "${target_identity}" 2>/dev/null) || resolved="${target_id}"
		printf '%s' "${line}" | "${jq_bin}" -c --arg target "${resolved}" '.target_node_id = $target'
	done | "${jq_bin}" -s -c '.'
}

fss_shunt_write_rules_mirror() {
	local json="$1"
	local dir="${FSS_SHUNT_RULES_FILE%/*}"

	mkdir -p "${dir}" >/dev/null 2>&1 || return 1
	printf '%s\n' "${json}" > "${FSS_SHUNT_RULES_FILE}"
}

fss_shunt_node_supported() {
	local node_id="$1"
	local node_type=""
	local ss_obfs=""

	[ -n "${node_id}" ] || return 1
	node_type="$(fss_get_node_field_plain "${node_id}" type)"
	case "${node_type}" in
	0)
		ss_obfs="$(fss_get_node_field_plain "${node_id}" ss_obfs)"
		[ -z "${ss_obfs}" ] || [ "${ss_obfs}" = "0" ]
		;;
	3|4|5|8)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

fss_shunt_target_is_direct() {
	local target="$1"

	[ -n "${target}" ] || return 1
	[ "$(printf '%s' "${target}" | tr 'a-z' 'A-Z')" = "${FSS_SHUNT_DIRECT_TARGET}" ]
}

fss_shunt_target_is_reject() {
	local target="$1"

	[ -n "${target}" ] || return 1
	[ "$(printf '%s' "${target}" | tr 'a-z' 'A-Z')" = "${FSS_SHUNT_REJECT_TARGET}" ]
}

fss_shunt_target_is_special() {
	local target="$1"

	fss_shunt_target_is_direct "${target}" || fss_shunt_target_is_reject "${target}"
}

fss_shunt_target_is_proxy_node() {
	local target="$1"

	[ -n "${target}" ] || return 1
	fss_shunt_target_is_special "${target}" && return 1
	fss_shunt_node_supported "${target}"
}

fss_shunt_target_outbound_tag() {
	local target="$1"

	if fss_shunt_target_is_direct "${target}"; then
		echo "direct"
	elif fss_shunt_target_is_reject "${target}"; then
		echo "reject"
	else
		echo "proxy${target}"
	fi
}

fss_shunt_get_first_rule_target_id() {
	local json=""
	local jq_bin=""

	json="$(fss_shunt_rules_json_resolved)"
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || return 1
	printf '%s' "${json}" | "${jq_bin}" -r '.[]? | select((.enabled // 1 | tostring) != "0") | (.target_node_id // "" | tostring)' 2>/dev/null | while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		fss_shunt_target_is_proxy_node "${node_id}" || continue
		echo "${node_id}"
		break
	done | sed -n '1p'
}

fss_shunt_get_active_rule_count() {
	local json=""
	local jq_bin=""
	local count=""

	json="$(fss_shunt_rules_json_resolved)"
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || {
		echo "0"
		return 0
	}
	count="$(printf '%s' "${json}" | "${jq_bin}" -r '[.[]? | select((.enabled // 1 | tostring) != "0") | select((.target_node_id // "" | tostring) != "")] | length' 2>/dev/null)"
	printf '%s\n' "${count:-0}"
}

fss_shunt_current_node_supported() {
	local node_id="$1"
	[ -n "${node_id}" ] || node_id="$(fss_shunt_get_default_node_id)"
	fss_shunt_node_supported "${node_id}"
}

fss_shunt_get_configured_default_target() {
	local target="${ss_basic_shunt_default_node}"
	local target_identity=""
	local mapped=""

	[ -n "${target}" ] || target="$(dbus get ${FSS_SHUNT_DEFAULT_NODE_DBUS_KEY})"
	target_identity="$(dbus get ${FSS_SHUNT_DEFAULT_NODE_IDENTITY_DBUS_KEY})"
	[ -n "${target}${target_identity}" ] || return 1
	if fss_shunt_target_is_direct "${target}"; then
		echo "${FSS_SHUNT_DIRECT_TARGET}"
		return 0
	fi
	fss_shunt_target_is_reject "${target}" && return 1
	if printf '%s' "${target}" | grep -Eq '^[0-9]+$' && fss_shunt_target_is_proxy_node "${target}"; then
		echo "${target}"
		return 0
	fi
	mapped="$(fss_shunt_resolve_target_id "${target}" "${target_identity}" 2>/dev/null)" || return 1
	echo "${mapped}"
}

fss_shunt_get_effective_default_target() {
	local target="$1"
	local rule_count=0

	[ -n "${target}" ] || target="$(fss_shunt_get_configured_default_target 2>/dev/null)"
	if fss_shunt_target_is_direct "${target}"; then
		rule_count="$(fss_shunt_get_active_rule_count)"
		[ -n "${rule_count}" ] || rule_count=0
		if [ "${rule_count}" -gt 0 ]; then
			echo "${FSS_SHUNT_DIRECT_TARGET}"
			return 0
		fi
		target=""
	fi
	if [ -n "${target}" ] && fss_shunt_target_is_proxy_node "${target}"; then
		echo "${target}"
		return 0
	fi
	fss_shunt_get_default_node_id
}

fss_shunt_get_default_node_id() {
	local node_id="$1"

	[ -n "${node_id}" ] || node_id="$(fss_shunt_get_configured_default_target 2>/dev/null)"
	if [ -n "${node_id}" ] && fss_shunt_target_is_proxy_node "${node_id}"; then
		echo "${node_id}"
		return 0
	fi
	node_id="$(fss_get_current_node_id)"
	if [ -n "${node_id}" ] && fss_shunt_target_is_proxy_node "${node_id}"; then
		echo "${node_id}"
		return 0
	fi
	node_id="$(fss_shunt_get_first_rule_target_id)"
	if [ -n "${node_id}" ] && fss_shunt_target_is_proxy_node "${node_id}"; then
		echo "${node_id}"
		return 0
	fi
	fss_list_node_ids | while read -r node_id
	do
		[ -n "${node_id}" ] || continue
		if fss_shunt_target_is_proxy_node "${node_id}"; then
			echo "${node_id}"
			break
		fi
	done | sed -n '1p'
}

fss_shunt_validate_current_node() {
	local node_id="$1"
	local node_type=""
	local ss_obfs=""

	[ -n "${node_id}" ] || node_id="$(fss_shunt_get_default_node_id)"
	[ -n "${node_id}" ] || {
		fss_shunt_log "错误：xray分流模式未找到可用的运行节点。"
		return 1
	}
	if fss_shunt_node_supported "${node_id}"; then
		return 0
	fi

	node_type="$(fss_get_node_field_plain "${node_id}" type)"
	if [ "${node_type}" = "0" ]; then
		ss_obfs="$(fss_get_node_field_plain "${node_id}" ss_obfs)"
		if [ -n "${ss_obfs}" ] && [ "${ss_obfs}" != "0" ]; then
			fss_shunt_log "错误：xray分流模式暂不支持将带obfs的SS节点作为运行节点。"
			return 1
		fi
	fi
	fss_shunt_log "错误：xray分流模式当前仅支持 SS(无obfs)/VMess/VLESS/Trojan/Hysteria2 节点作为运行节点。"
	return 1
}

fss_shunt_runtime_key() {
	local rule_ts=""
	local node_config_ts=""
	local ingress_mode=""

	rule_ts="${ss_basic_shunt_rule_ts}"
	[ -n "${rule_ts}" ] || rule_ts="$(dbus get ${FSS_SHUNT_RULE_TS_DBUS_KEY})"
	printf '%s' "${rule_ts}" | grep -Eq '^[0-9]+$' || rule_ts="0"
	node_config_ts="$(fss_get_node_config_ts)"
	printf '%s' "${node_config_ts}" | grep -Eq '^[0-9]+$' || node_config_ts="0"
	ingress_mode="$(fss_shunt_runtime_mode)"
	printf '%s|%s|%s\n' "${ingress_mode}" "${rule_ts}" "${node_config_ts}"
}

fss_shunt_runtime_meta_get() {
	local key="$1"

	[ -f "${FSS_SHUNT_RUNTIME_META_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_SHUNT_RUNTIME_META_FILE}" | sed -n '1p'
}

fss_shunt_enabled_rule_count() {
	local json=""
	local jq_bin=""

	json="$(fss_shunt_rules_json)"
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || {
		echo "0"
		return 0
	}
	printf '%s' "${json}" | "${jq_bin}" -r '[.[]? | select((.enabled // 1 | tostring) != "0")] | length' 2>/dev/null | sed -n '1p'
}

fss_shunt_runtime_is_fresh() {
	local current_key=""
	local cached_key=""
	local enabled_rules="0"

	[ -f "${FSS_SHUNT_RUNTIME_META_FILE}" ] || return 1
	current_key="$(fss_shunt_runtime_key)"
	cached_key="$(fss_shunt_runtime_meta_get runtime_key)"
	[ -n "${cached_key}" ] || return 1
	[ "${cached_key}" = "${current_key}" ] || return 1
	enabled_rules="$(fss_shunt_enabled_rule_count)"
	printf '%s' "${enabled_rules}" | grep -Eq '^[0-9]+$' || enabled_rules="0"
	if [ "${enabled_rules}" -gt 0 ] 2>/dev/null; then
		[ -s "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" ] || return 1
	fi
	return 0
}

fss_shunt_write_runtime_meta() {
	local runtime_key="$1"
	local tmp_file="${FSS_SHUNT_RUNTIME_META_FILE}.tmp.$$"

	mkdir -p "${FSS_SHUNT_RUNTIME_DIR}" >/dev/null 2>&1 || return 1
	cat > "${tmp_file}" <<-EOF
		runtime_key=${runtime_key}
		built_at=$(date +%s)
	EOF
	mv -f "${tmp_file}" "${FSS_SHUNT_RUNTIME_META_FILE}"
}

fss_shunt_materialize_rule_domains() {
	local source_type="$1"
	local preset="$2"
	local custom_b64="$3"
	local domain_file="$4"
	local proxy_file="$5"
	local ip_file="${domain_file%.domains}.ips"
	local geoip_file="${domain_file%.domains}.geoips"
	local text=""
	local site_assets_csv=""
	local ip_assets_csv=""
	local count_domain=0
	local count_ip=0
	local count_geoip=0
	local custom_tmp=""

	[ -n "${domain_file}" ] || return 1
	[ -n "${proxy_file}" ] || return 1
	: > "${domain_file}"
	: > "${proxy_file}"
	: > "${ip_file}"
	: > "${geoip_file}"
	if [ "${source_type}" = "builtin" ]; then
		if fss_shunt_is_custom_preset "${preset}"; then
			local custom_domain_b64=""
			local custom_ip_b64=""
			local custom_domain_text=""
			local custom_ip_text=""
			custom_domain_b64="$(fss_shunt_custom_preset_get "${preset}" "domain_b64" 2>/dev/null)"
			custom_ip_b64="$(fss_shunt_custom_preset_get "${preset}" "ip_b64" 2>/dev/null)"
			custom_domain_text="$(fss_b64_decode "${custom_domain_b64}" 2>/dev/null)"
			custom_ip_text="$(fss_b64_decode "${custom_ip_b64}" 2>/dev/null)"
			if [ -n "${custom_domain_text}" ]; then
				printf '%s\n' "${custom_domain_text}" | fss_shunt_custom_domain_to_tokens "${domain_file}" "${proxy_file}"
				count_domain="$(wc -l < "${domain_file}" | tr -d ' ')"
				[ -n "${count_domain}" ] || count_domain=0
			fi
			if [ -n "${custom_ip_text}" ]; then
				printf '%s\n' "${custom_ip_text}" | fss_shunt_custom_ip_to_tokens "${ip_file}"
				count_ip="$(wc -l < "${ip_file}" | tr -d ' ')"
				[ -n "${count_ip}" ] || count_ip=0
			fi
			printf '%s\n' $((count_domain + count_ip))
			return 0
		fi
		site_assets_csv="$(fss_shunt_preset_assets_csv "${preset}" site)"
		ip_assets_csv="$(fss_shunt_preset_assets_csv "${preset}" ip)"
		[ -n "${site_assets_csv}${ip_assets_csv}" ] || return 1
		if ! fss_shunt_batch_export_assets "${site_assets_csv}" "${domain_file}" "${proxy_file}" "${ip_assets_csv}" "${ip_file}"; then
			fss_shunt_export_site_assets "${site_assets_csv}" "${domain_file}" || return 1
			fss_shunt_export_ip_assets "${ip_assets_csv}" "${ip_file}" || return 1
			if [ -s "${domain_file}" ]; then
				awk '
					/^(full|domain):/ {
						value = substr($0, index($0, ":") + 1)
						if (value != "" && !seen[value]++) print value
					}
				' "${domain_file}" > "${proxy_file}"
			fi
		fi
		if [ -s "${domain_file}" ]; then
			count_domain="$(wc -l < "${domain_file}" | tr -d ' ')"
			[ -n "${count_domain}" ] || count_domain=0
		fi
		if [ -s "${ip_file}" ]; then
			count_ip="$(wc -l < "${ip_file}" | tr -d ' ')"
			[ -n "${count_ip}" ] || count_ip=0
		fi
		printf '%s\n' $((count_domain + count_ip))
		return 0
	fi

	[ "${source_type}" = "custom" ] || return 1
	text="$(fss_b64_decode "${custom_b64}" 2>/dev/null)"
	[ -n "${text}" ] || return 1
	printf '%s\n' "${text}" | awk -v domain_file="${domain_file}" -v proxy_file="${proxy_file}" '
		function normalize(line, lower, prefix, value, token) {
			gsub(/\r/, "", line)
			sub(/#.*/, "", line)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			if (line == "") return ""
			lower = tolower(line)
			prefix = "domain"
			value = lower
			if (lower ~ /^domain,/) {
				prefix = "full"
				value = substr(lower, 8)
			} else if (lower ~ /^domain-suffix,/) {
				prefix = "domain"
				value = substr(lower, 15)
			} else if (lower ~ /^domain-keyword,/) {
				prefix = "keyword"
				value = substr(lower, 16)
			} else if (lower ~ /^full:/) {
				prefix = "full"
				value = substr(lower, 6)
			} else if (lower ~ /^domain:/) {
				prefix = "domain"
				value = substr(lower, 8)
			} else if (lower ~ /^keyword:/) {
				prefix = "keyword"
				value = substr(lower, 9)
			}
			gsub(/^[*.]+/, "", value)
			gsub(/[[:space:]]+$/, "", value)
			if (value == "") return ""
			if (prefix == "keyword") {
				if (value !~ /^[a-z0-9._-]+$/) return ""
			} else {
				if (value !~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) return ""
			}
			return prefix ":" value
		}
		{
			token = normalize($0)
			if (token == "" || seen[token]++) next
			print token > domain_file
			if (token ~ /^(full|domain):/) print substr(token, index(token, ":") + 1) >> proxy_file
			count++
		}
	'
	custom_tmp="${FSS_SHUNT_RUNTIME_DIR}/custom_${$}_$$.txt"
	printf '%s\n' "${text}" > "${custom_tmp}"
	sh "${KSROOT}/scripts/ss_parse_ip_geoip.sh" "${custom_tmp}" "${ip_file}" "${geoip_file}" >/dev/null 2>&1 || true
	rm -f "${custom_tmp}" >/dev/null 2>&1
	count_domain="$(wc -l < "${domain_file}" 2>/dev/null | tr -d ' ')"
	count_ip="$(wc -l < "${ip_file}" 2>/dev/null | tr -d ' ')"
	count_geoip="$(wc -l < "${geoip_file}" 2>/dev/null | tr -d ' ')"
	[ -n "${count_domain}" ] || count_domain=0
	[ -n "${count_ip}" ] || count_ip=0
	[ -n "${count_geoip}" ] || count_geoip=0
	printf '%s\n' $((count_domain + count_ip + count_geoip))
}

fss_shunt_rebuild_proxy_domains() {
	local active_file="$1"
	local proxy_file="$2"

	[ -n "${active_file}" ] || return 1
	[ -n "${proxy_file}" ] || return 1
	if [ ! -s "${active_file}" ]; then
		rm -f "${proxy_file}" >/dev/null 2>&1
		return 0
	fi
	awk -F'|' '
	{
		file = $3
		if (file == "") next
		while ((getline line < file) > 0) {
			split(line, part, ":")
			if ((part[1] == "full" || part[1] == "domain") && !seen[part[2]]++) print part[2]
		}
		close(file)
	}
	' "${active_file}" > "${proxy_file}"
}

fss_shunt_get_proxy_domain_file() {
	fss_shunt_mode_selected || return 1
	fss_shunt_rules_enabled || return 1
	fss_shunt_prepare_runtime || return 1
	[ -s "${FSS_SHUNT_RUNTIME_PROXY_FILE}" ] || return 1
	printf '%s\n' "${FSS_SHUNT_RUNTIME_PROXY_FILE}"
}

fss_shunt_prepare_runtime() {
	local json=""
	local jq_bin=""
	local tmp_dir=""
	local active_tmp=""
	local proxy_tmp=""
	local targets_tmp=""
	local count=0
	local rule_id=""
	local source_type=""
	local preset=""
	local custom_b64=""
	local target_id=""
	local remark=""
	local domain_file=""
	local rule_count=0
	local target_count=0
	local rebuild_runtime_lists=0
	local runtime_key=""
	local sep="$(printf '\037')"

	fss_shunt_mode_selected || return 0
	fss_shunt_rules_enabled || return 0
	runtime_key="$(fss_shunt_runtime_key)"
	if [ "${FSS_SHUNT_RUNTIME_READY}" = "1" ] && [ "${FSS_SHUNT_RUNTIME_READY_KEY}" = "${runtime_key}" ]; then
		return 0
	fi
	if fss_shunt_runtime_is_fresh; then
		FSS_SHUNT_RUNTIME_READY="1"
		FSS_SHUNT_RUNTIME_READY_KEY="${runtime_key}"
		return 0
	fi
	fss_shunt_cleanup_runtime
	json="$(fss_shunt_rules_json)"
	fss_shunt_write_rules_mirror "${json}" >/dev/null 2>&1 || true
	jq_bin="$(fss_pick_jq_bin)"
	[ -n "${jq_bin}" ] || return 1
	mkdir -p "${FSS_SHUNT_RUNTIME_RULE_DIR}" >/dev/null 2>&1 || return 1
	tmp_dir="$(fss_mktemp_dir fss_shunt)" || return 1
	active_tmp="${tmp_dir}/active.tsv"
	proxy_tmp="${tmp_dir}/proxy.txt"
	targets_tmp="${tmp_dir}/targets.txt"
	: > "${active_tmp}"
	: > "${proxy_tmp}"
	: > "${targets_tmp}"

	printf '%s' "${json}" | "${jq_bin}" -r '.[]? | select((.enabled // 1 | tostring) != "0") | "\(.id // "" | tostring)\u001f\(.source // "builtin" | tostring)\u001f\(.preset // "" | tostring)\u001f\(.custom_b64 // "" | tostring)\u001f\(.target_node_id // "" | tostring)\u001f\(.remark // "" | tostring)"' 2>/dev/null > "${tmp_dir}/rules.txt"

	while IFS="${sep}" read -r rule_id source_type preset custom_b64 target_id remark
	do
		[ -n "${target_id}" ] || continue
		if ! fss_shunt_target_is_special "${target_id}"; then
			fss_shunt_target_is_proxy_node "${target_id}" || continue
		fi
		domain_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.domains"
		ip_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.ips"
		geoip_file="${FSS_SHUNT_RUNTIME_RULE_DIR}/${rule_id}.geoips"
		rm -f "${domain_file}" "${ip_file}" "${geoip_file}" >/dev/null 2>&1
		count="$(fss_shunt_materialize_rule_domains "${source_type}" "${preset}" "${custom_b64}" "${domain_file}" "${proxy_tmp}" 2>/dev/null)"
		[ -n "${count}" ] || count=0
		if [ "${count}" -le 0 ] 2>/dev/null; then
			rm -f "${domain_file}" "${ip_file}" "${geoip_file}" >/dev/null 2>&1
			continue
		fi
		echo "${rule_id}|${target_id}|${domain_file}|${source_type}|${preset}|${remark}" >> "${active_tmp}"
		fss_shunt_target_is_special "${target_id}" || echo "${target_id}" >> "${targets_tmp}"
	done < "${tmp_dir}/rules.txt"

	if [ -s "${targets_tmp}" ]; then
		sort -u "${targets_tmp}" -o "${targets_tmp}" 2>/dev/null || true
	fi
	rule_count=$(wc -l < "${active_tmp}" 2>/dev/null | tr -d ' ')
	[ -n "${rule_count}" ] || rule_count=0
	target_count=$(wc -l < "${targets_tmp}" 2>/dev/null | tr -d ' ')
	[ -n "${target_count}" ] || target_count=0
	if [ "${rule_count}" -gt "${FSS_SHUNT_MAX_RULES}" ]; then
		head -n "${FSS_SHUNT_MAX_RULES}" "${active_tmp}" > "${active_tmp}.limit"
		mv -f "${active_tmp}.limit" "${active_tmp}"
		rule_count="${FSS_SHUNT_MAX_RULES}"
		rebuild_runtime_lists=1
	fi
	if [ "${rebuild_runtime_lists}" = "1" ]; then
		awk -F '|' 'NF >= 2 && $2 != "DIRECT" && $2 != "REJECT" && !seen[$2]++ {print $2}' "${active_tmp}" > "${targets_tmp}"
		target_count=$(wc -l < "${targets_tmp}" 2>/dev/null | tr -d ' ')
		[ -n "${target_count}" ] || target_count=0
	fi
	if [ "${target_count}" -gt "${FSS_SHUNT_MAX_TARGETS}" ]; then
		head -n "${FSS_SHUNT_MAX_TARGETS}" "${targets_tmp}" > "${targets_tmp}.limit"
		mv -f "${targets_tmp}.limit" "${targets_tmp}"
		target_count="${FSS_SHUNT_MAX_TARGETS}"
		awk -F '|' 'NR==FNR {keep[$1]=1; next} keep[$2] || $2 == "DIRECT" || $2 == "REJECT"' "${targets_tmp}" "${active_tmp}" > "${active_tmp}.keep"
		mv -f "${active_tmp}.keep" "${active_tmp}"
		rebuild_runtime_lists=1
	fi
	if [ "${rebuild_runtime_lists}" = "1" ]; then
		fss_shunt_rebuild_proxy_domains "${active_tmp}" "${proxy_tmp}"
	fi
	if [ -s "${proxy_tmp}" ]; then
		sort -u "${proxy_tmp}" > "${FSS_SHUNT_RUNTIME_PROXY_FILE}" 2>/dev/null
	else
		rm -f "${FSS_SHUNT_RUNTIME_PROXY_FILE}" >/dev/null 2>&1
	fi
	if [ -s "${active_tmp}" ]; then
		mv -f "${active_tmp}" "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"
	else
		rm -f "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" >/dev/null 2>&1
	fi
	if [ -s "${targets_tmp}" ]; then
		mv -f "${targets_tmp}" "${FSS_SHUNT_RUNTIME_TARGET_FILE}"
	else
		rm -f "${FSS_SHUNT_RUNTIME_TARGET_FILE}" >/dev/null 2>&1
	fi
	fss_shunt_write_runtime_meta "${runtime_key}" >/dev/null 2>&1 || true
	FSS_SHUNT_RUNTIME_READY="1"
	FSS_SHUNT_RUNTIME_READY_KEY="${runtime_key}"
	rm -rf "${tmp_dir}" >/dev/null 2>&1
}

fss_shunt_emit_dns_relay_route_rule() {
	local first=1
	local relay_port=""
	local sep="$(printf '\037')"
	local tags=""

	type has_dns_udp_relay_targets >/dev/null 2>&1 || return 0
	has_dns_udp_relay_targets || return 0
	while IFS="${sep}" read -r relay_port _rest
	do
		[ -n "${relay_port}" ] || continue
		if [ "${first}" = "1" ]; then
			first=0
		else
			tags="${tags},"
		fi
		tags="${tags}\"dns_udp_${relay_port}\""
	done <<-EOF2
	$(iter_dns_udp_relay_targets)
EOF2
	[ -n "${tags}" ] || return 0
	printf '        {"type":"field","inboundTag":[%s],"outboundTag":"proxy%s"}' "${tags}" "$1"
}

fss_shunt_emit_outbounds_json() {
	local current_id="$1"
	local node_id=""
	local runtime_out=""

	runtime_out="${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${current_id}_outbounds.json"
	[ -s "${runtime_out}" ] || return 1
	cat "${runtime_out}"
	if [ -f "${FSS_SHUNT_RUNTIME_TARGET_FILE}" ]; then
		while IFS= read -r node_id
		do
			[ -n "${node_id}" ] || continue
			[ "${node_id}" = "${current_id}" ] && continue
			runtime_out="${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${node_id}_outbounds.json"
			[ -s "${runtime_out}" ] || continue
			printf ',\n'
			cat "${runtime_out}"
		done < "${FSS_SHUNT_RUNTIME_TARGET_FILE}"
	fi
	printf ',\n        {"tag":"direct","protocol":"freedom","settings":{}}'
	printf ',\n        {"tag":"reject","protocol":"blackhole","settings":{}}'
}

fss_shunt_json_array_from_file() {
	local file="$1"
	local prefix="$2"

	[ -f "${file}" ] || return 1
	awk -v prefix="${prefix}" '
		BEGIN {
			first = 1
			printf "["
		}
		NF {
			value = $0
			gsub(/\\/, "\\\\", value)
			gsub(/"/, "\\\"", value)
			if (prefix != "") {
				value = prefix value
			}
			if (!first) {
				printf ","
			}
			printf "\"%s\"", value
			first = 0
		}
		END {
			printf "]"
		}
	' "${file}"
}

fss_shunt_json_array_from_csv() {
	local csv="$1"
	local prefix="$2"
	local old_ifs="${IFS}"
	local item=""
	local first=1

	IFS=','
	printf '['
	for item in ${csv}
	do
		[ -n "${item}" ] || continue
		item="${prefix}${item}"
		item=$(printf '%s' "${item}" | sed 's/\\/\\\\/g; s/"/\\"/g')
		if [ "${first}" = "1" ]; then
			first=0
		else
			printf ','
		fi
		printf '"%s"' "${item}"
	done
	printf ']'
	IFS="${old_ifs}"
}

fss_shunt_csv_to_xray_refs() {
	local csv="$1"
	local prefix="$2"
	local old_ifs="${IFS}"
	local item=""
	local first=1

	IFS=','
	printf '['
	for item in ${csv}
	do
		[ -n "${item}" ] || continue
		item="$(printf '%s' "${item}" | awk '{print toupper($0)}')"
		item="${prefix}${item}"
		item=$(printf '%s' "${item}" | sed 's/\\/\\\\/g; s/"/\\"/g')
		if [ "${first}" = "1" ]; then
			first=0
		else
			printf ','
		fi
		printf '"%s"' "${item}"
	done
	printf ']'
	IFS="${old_ifs}"
}

fss_shunt_emit_routing_rule_line() {
	local field_name="$1"
	local values_json="$2"
	local target_id="$3"
	local rule_tag="$4"
	local outbound_tag=""

	[ -n "${values_json}" ] || return 1
	outbound_tag="$(fss_shunt_target_outbound_tag "${target_id}")"
	if [ -n "${rule_tag}" ]; then
		printf '        {"type":"field","ruleTag":"%s","%s":%s,"outboundTag":"%s"}' "${rule_tag}" "${field_name}" "${values_json}" "${outbound_tag}"
	else
		printf '        {"type":"field","%s":%s,"outboundTag":"%s"}' "${field_name}" "${values_json}" "${outbound_tag}"
	fi
}

fss_shunt_make_rule_tag() {
	local rule_id="$1"
	local suffix="$2"
	[ -n "${rule_id}" ] || return 1
	[ -n "${suffix}" ] || return 1
	printf 'fss_%s_%s\n' "${rule_id}" "${suffix}"
}

fss_shunt_emit_routing_rules_json() {
	local backend=""
	local first_rule=1
	local rule_id=""
	local target_id=""
	local domain_file=""
	local source_type=""
	local preset=""
	local remark=""
	local ip_file=""
	local geoip_file=""
	local site_assets_csv=""
	local ip_assets_csv=""
	local values_json=""
	local rule_line=""

	[ -s "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" ] || return 0
	backend="$(fss_shunt_rule_backend)"
	while IFS='|' read -r rule_id target_id domain_file source_type preset remark
	do
		[ -n "${target_id}" ] || continue
		[ -n "${domain_file}" ] || continue
		ip_file="${domain_file%.domains}.ips"
		geoip_file="${domain_file%.domains}.geoips"
		if [ "${backend}" = "geodata" ] && [ "${source_type}" = "builtin" ] && ! fss_shunt_is_custom_preset "${preset}"; then
			site_assets_csv="$(fss_shunt_preset_assets_csv "${preset}" site)"
			ip_assets_csv="$(fss_shunt_preset_assets_csv "${preset}" ip)"
			if [ -n "${site_assets_csv}" ]; then
				values_json="$(fss_shunt_csv_to_xray_refs "${site_assets_csv}" 'geosite:')"
				rule_line="$(fss_shunt_emit_routing_rule_line "domain" "${values_json}" "${target_id}" "$(fss_shunt_make_rule_tag "${rule_id}" domain)" 2>/dev/null || true)"
				if [ -n "${rule_line}" ]; then
					[ "${first_rule}" = "1" ] || printf ',\n'
					first_rule=0
					printf '%s' "${rule_line}"
				fi
			fi
			if [ -n "${ip_assets_csv}" ]; then
				values_json="$(fss_shunt_csv_to_xray_refs "${ip_assets_csv}" 'geoip:')"
				rule_line="$(fss_shunt_emit_routing_rule_line "ip" "${values_json}" "${target_id}" "$(fss_shunt_make_rule_tag "${rule_id}" ip)" 2>/dev/null || true)"
				if [ -n "${rule_line}" ]; then
					[ "${first_rule}" = "1" ] || printf ',\n'
					first_rule=0
					printf '%s' "${rule_line}"
				fi
			fi
			continue
		fi
		if [ -s "${domain_file}" ]; then
			values_json="$(fss_shunt_json_array_from_file "${domain_file}" '')"
			rule_line="$(fss_shunt_emit_routing_rule_line "domain" "${values_json}" "${target_id}" "$(fss_shunt_make_rule_tag "${rule_id}" domain)" 2>/dev/null || true)"
			if [ -n "${rule_line}" ]; then
				[ "${first_rule}" = "1" ] || printf ',\n'
				first_rule=0
				printf '%s' "${rule_line}"
			fi
		fi
		values_json=""
		if [ -s "${ip_file}" ]; then
			values_json="$(fss_shunt_json_array_from_file "${ip_file}" '')"
		fi
		if [ -s "${geoip_file}" ]; then
			if [ -n "${values_json}" ] && [ "${values_json}" != "[]" ]; then
				values_json="${values_json%]}"
				if [ -n "${values_json}" ] && [ "${values_json}" != "[" ]; then
					values_json="${values_json},"
				fi
				values_json="${values_json}$(fss_shunt_json_array_from_file "${geoip_file}" 'geoip:' | sed 's/^\[//; s/\]$//')]"
			else
				values_json="$(fss_shunt_json_array_from_file "${geoip_file}" 'geoip:')"
			fi
		fi
		if [ -n "${values_json}" ] && [ "${values_json}" != "[]" ]; then
			rule_line="$(fss_shunt_emit_routing_rule_line "ip" "${values_json}" "${target_id}" "$(fss_shunt_make_rule_tag "${rule_id}" ip)" 2>/dev/null || true)"
			if [ -n "${rule_line}" ]; then
				[ "${first_rule}" = "1" ] || printf ',\n'
				first_rule=0
				printf '%s' "${rule_line}"
			fi
		fi
	done < "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"
}

fss_shunt_write_hot_reload_state() {
	local out_file="${1:-${FSS_SHUNT_HOT_STATE_FILE}}"
	local backend=""
	local rule_id=""
	local target_id=""
	local domain_file=""
	local source_type=""
	local preset=""
	local remark=""
	local ip_file=""
	local geoip_file=""
	local site_assets_csv=""
	local ip_assets_csv=""
	local domain_rule_csv=""
	local ip_rule_csv=""
	local domain_rule_file=""
	local ip_rule_files=""

	[ -s "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" ] || {
		: > "${out_file}"
		return 0
	}

	backend="$(fss_shunt_rule_backend)"
	: > "${out_file}" || return 1
	while IFS='|' read -r rule_id target_id domain_file source_type preset remark
	do
		[ -n "${rule_id}" ] || continue
		ip_file="${domain_file%.domains}.ips"
		geoip_file="${domain_file%.domains}.geoips"
		domain_rule_csv=""
		ip_rule_csv=""
		domain_rule_file="${domain_file}"
		ip_rule_files="${ip_file}${geoip_file:+,${geoip_file}}"
		if [ -s "${domain_file}" ]; then
			printf '%s|%s|%s|%s|%s|%s|%s\n' \
				"$(fss_shunt_make_rule_tag "${rule_id}" domain)" \
				"${target_id}" \
				"${domain_rule_file}" \
				"" \
				"${domain_rule_csv}" \
				"" \
				"prepend" >> "${out_file}"
		fi
		if [ -s "${ip_file}" ] || [ -s "${geoip_file}" ]; then
			printf '%s|%s|%s|%s|%s|%s|%s\n' \
				"$(fss_shunt_make_rule_tag "${rule_id}" ip)" \
				"${target_id}" \
				"" \
				"${ip_rule_files}" \
				"" \
				"${ip_rule_csv}" \
				"prepend" >> "${out_file}"
		fi
	done < "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"

	printf '%s|%s|%s|%s|%s|%s|%s\n' \
		"fss_default" \
		"$(fss_shunt_get_effective_default_target)" \
		"" \
		"" \
		"" \
		"" \
		"append" >> "${out_file}"
}

fss_shunt_get_webtest_cache_meta() {
	local key="$1"

	[ -n "${key}" ] || return 1
	[ -f "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" | sed -n '1p'
}

fss_shunt_webtest_cache_settings_match() {
	local cache_linux_ver=""
	local cache_tfo=""

	[ -n "${LINUX_VER}" ] || LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="$(dbus get ss_basic_tfo)"
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="0"
	cache_linux_ver="$(fss_shunt_get_webtest_cache_meta linux_ver)"
	cache_tfo="$(fss_shunt_get_webtest_cache_meta ss_basic_tfo)"
	[ "${cache_linux_ver}" = "${LINUX_VER}" ] || return 1
	[ "${cache_tfo}" = "${ss_basic_tfo}" ] || return 1
	return 0
}

fss_shunt_webtest_cache_node_is_fresh() {
	local node_id="$1"
	local cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
	local meta_file="${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta"
	local current_rev=""
	local cached_rev=""
	local cache_linux_ver=""
	local cache_tfo=""

	[ -n "${node_id}" ] || return 1
	[ -s "${cache_out}" ] || return 1
	[ -f "${meta_file}" ] || return 1
	[ -n "${LINUX_VER}" ] || LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="$(dbus get ss_basic_tfo)"
	[ -n "${ss_basic_tfo}" ] || ss_basic_tfo="0"
	current_rev="$(fss_get_node_field_plain "${node_id}" "_rev" 2>/dev/null)"
	[ -n "${current_rev}" ] || current_rev="0"
	cached_rev="$(sed -n 's/^node_rev=//p' "${meta_file}" | sed -n '1p')"
	[ -n "${cached_rev}" ] || cached_rev="0"
	cache_linux_ver="$(sed -n 's/^linux_ver=//p' "${meta_file}" | sed -n '1p')"
	cache_tfo="$(sed -n 's/^ss_basic_tfo=//p' "${meta_file}" | sed -n '1p')"
	[ "${cached_rev}" = "${current_rev}" ] || return 1
	[ "${cache_linux_ver}" = "${LINUX_VER}" ] || return 1
	[ "${cache_tfo}" = "${ss_basic_tfo}" ] || return 1
	return 0
}

fss_shunt_need_webtest_cache_rebuild() {
	local ids_file="$1"
	local node_id=""

	[ -f "${ids_file}" ] || return 0
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		fss_shunt_webtest_cache_node_is_fresh "${node_id}" || return 0
	done < "${ids_file}"
	return 1
}

fss_shunt_link_webtest_cache_outbounds() {
	local ids_file="$1"
	local node_id=""
	local cache_out=""

	[ -f "${ids_file}" ] || return 1
	rm -rf "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}" >/dev/null 2>&1
	mkdir -p "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}" || {
		fss_shunt_state_failed "runtime_artifact" "${ids_file}" "无法创建分流运行产物目录。"
		fss_shunt_runtime_artifact_lock_release
		return 1
	}
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		cache_out="${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json"
		[ -s "${cache_out}" ] || return 1
		ln -sf "${cache_out}" "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${node_id}_outbounds.json" || return 1
	done < "${ids_file}"
}

fss_shunt_runtime_artifact_meta_get() {
	local key="$1"
	local meta_file="${FSS_SHUNT_RUNTIME_ARTIFACT_DIR}/cache.meta"

	[ -n "${key}" ] || return 1
	[ -f "${meta_file}" ] || return 1
	sed -n "s/^${key}=//p" "${meta_file}" | sed -n '1p'
}

fss_shunt_log_node_tool_runtime_summary() {
	local native=""
	local shell=""
	local missing=""
	local other=""
	local reasons=""

	native="$(fss_shunt_runtime_artifact_meta_get "builder_native")"
	shell="$(fss_shunt_runtime_artifact_meta_get "builder_shell")"
	missing="$(fss_shunt_runtime_artifact_meta_get "builder_missing")"
	other="$(fss_shunt_runtime_artifact_meta_get "builder_other")"
	reasons="$(fss_shunt_runtime_artifact_meta_get "builder_shell_reasons")"
	[ -n "${native}${shell}${missing}${other}${reasons}" ] || return 0
	[ -n "${native}" ] || native="0"
	[ -n "${shell}" ] || shell="0"
	[ -n "${missing}" ] || missing="0"
	[ -n "${other}" ] || other="0"
	fss_shunt_log "ℹ️node-tool运行产物摘要：native ${native}，shell ${shell}，missing ${missing}，other ${other}。"
	[ "${shell}" = "0" ] || [ -z "${reasons}" ] || fss_shunt_log "ℹ️shell回退原因：${reasons}"
}

fss_shunt_runtime_artifacts_ready_for_ids() {
	local ids_file="$1"
	local node_id=""
	local artifact_out=""
	local meta_file="${FSS_SHUNT_RUNTIME_ARTIFACT_DIR}/cache.meta"

	[ -f "${ids_file}" ] || return 1
	[ -f "${meta_file}" ] || return 1
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		artifact_out="${FSS_SHUNT_RUNTIME_ARTIFACT_DIR}/nodes/${node_id}_outbounds.json"
		[ -s "${artifact_out}" ] || return 1
	done < "${ids_file}"
	return 0
}

fss_shunt_try_prepare_node_tool_runtime_artifacts() {
	local ids_file="$1"
	local node_tool=""
	local node_id=""
	local artifact_out=""
	local ret=0

	[ -f "${ids_file}" ] || return 1
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || return 1
	fss_node_tool_supports_command "${node_tool}" "runtime-artifact" || return 1
	fss_refresh_node_json_cache >/dev/null 2>&1 || return 1
	fss_shunt_runtime_artifact_lock_acquire || return 1
	if ! fss_shunt_runtime_artifacts_ready_for_ids "${ids_file}"; then
		fss_shunt_state_begin "runtime_artifact" "${ids_file}" "检测到分流运行产物缺失或已过期，开始重建。"
		fss_shunt_log "ℹ️检测到分流运行产物缺失或已过期，开始重建。"
		fss_shunt_state_phase "build" "runtime_artifact" "${ids_file}" "正在生成当前分流所需节点运行产物。"
		fss_shunt_log "ℹ️正在生成当前分流所需节点运行产物。"
		"${node_tool}" runtime-artifact \
			--profile shunt \
			--ids-file "${ids_file}" \
			--output-dir "${FSS_SHUNT_RUNTIME_ARTIFACT_DIR}" >/dev/null 2>&1 || ret=1
	else
		fss_shunt_log "ℹ️等待中的节点运行产物已就绪，继续复用。"
	fi
	[ "${ret}" = "0" ] || {
		fss_shunt_state_failed "runtime_artifact" "${ids_file}" "分流运行产物重建失败。"
		fss_shunt_runtime_artifact_lock_release
		return 1
	}
	rm -rf "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}" >/dev/null 2>&1
	mkdir -p "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}" || return 1
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		artifact_out="${FSS_SHUNT_RUNTIME_ARTIFACT_DIR}/nodes/${node_id}_outbounds.json"
		[ -s "${artifact_out}" ] || {
			fss_shunt_state_failed "runtime_artifact" "${ids_file}" "分流运行产物缺少必要节点出站。"
			fss_shunt_runtime_artifact_lock_release
			return 1
		}
		ln -sf "${artifact_out}" "${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${node_id}_outbounds.json" || {
			fss_shunt_state_failed "runtime_artifact" "${ids_file}" "无法链接分流运行产物。"
			fss_shunt_runtime_artifact_lock_release
			return 1
		}
	done < "${ids_file}"
	fss_shunt_state_ready "runtime_artifact" "${ids_file}" "分流运行产物已就绪。"
	fss_shunt_runtime_artifact_lock_release
	fss_shunt_log "ℹ️通过node-tool生成shunt统一运行产物。"
	fss_shunt_log_node_tool_runtime_summary
	return 0
}

fss_shunt_try_prepare_webtest_outbounds() {
	local ids_file="$1"

	[ -f "${ids_file}" ] || return 1
	if fss_shunt_try_prepare_node_tool_runtime_artifacts "${ids_file}"; then
		return 0
	fi
	fss_refresh_node_json_cache >/dev/null 2>&1 || return 1
	if fss_shunt_need_webtest_cache_rebuild "${ids_file}"; then
		fss_shunt_log "复用webtest节点配置缓存：检测到缺失或过期，开始增量更新。"
		sh "${FSS_SHUNT_WEBTEST_HELPER}" ensure_cache_ids_file "${ids_file}" >/dev/null 2>&1 || return 1
	fi
	fss_shunt_link_webtest_cache_outbounds "${ids_file}" || return 1
}

fss_shunt_prune_runtime_targets_by_cache() {
	local current_id="$1"
	local tmp_targets="${FSS_SHUNT_RUNTIME_TARGET_FILE}.tmp.$$"
	local tmp_active="${FSS_SHUNT_RUNTIME_ACTIVE_FILE}.tmp.$$"
	local node_id=""
	local runtime_out=""
	local keep_any=0

	[ -f "${FSS_SHUNT_RUNTIME_TARGET_FILE}" ] || return 0
	: > "${tmp_targets}"
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		runtime_out="${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${node_id}_outbounds.json"
		[ -s "${runtime_out}" ] || continue
		echo "${node_id}" >> "${tmp_targets}"
		keep_any=1
	done < "${FSS_SHUNT_RUNTIME_TARGET_FILE}"
	if [ "${keep_any}" = "1" ]; then
		mv -f "${tmp_targets}" "${FSS_SHUNT_RUNTIME_TARGET_FILE}"
		awk -F '|' 'NR==FNR {keep[$1]=1; next} keep[$2]' "${FSS_SHUNT_RUNTIME_TARGET_FILE}" "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" > "${tmp_active}"
		mv -f "${tmp_active}" "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}"
	else
		rm -f "${tmp_targets}" "${FSS_SHUNT_RUNTIME_TARGET_FILE}" "${tmp_active}" "${FSS_SHUNT_RUNTIME_ACTIVE_FILE}" >/dev/null 2>&1
	fi
}

fss_shunt_prepare_outbound_cache() {
	local current_id="$1"
	local runtime_out="${FSS_SHUNT_RUNTIME_OUTBOUND_DIR}/${current_id}_outbounds.json"
	local ids_file="${FSS_SHUNT_RUNTIME_DIR}/cache_ids.txt"
	local node_id=""

	: > "${ids_file}" || return 1
	echo "${current_id}" >> "${ids_file}"
	if [ -f "${FSS_SHUNT_RUNTIME_TARGET_FILE}" ]; then
		while IFS= read -r node_id
		do
			[ -n "${node_id}" ] || continue
			echo "${node_id}" >> "${ids_file}"
		done < "${FSS_SHUNT_RUNTIME_TARGET_FILE}"
	fi
	sort -u "${ids_file}" -o "${ids_file}" 2>/dev/null || true
	if fss_shunt_try_prepare_webtest_outbounds "${ids_file}"; then
		[ -s "${runtime_out}" ] || return 1
		fss_shunt_prune_runtime_targets_by_cache "${current_id}"
		return 0
	fi
	fss_shunt_log "⚠️复用webtest节点配置缓存失败，无法继续构建shunt运行时出站。"
	return 1
}

fss_shunt_build_xray_config() {
	local config_file="$1"
	local current_id="$2"
	local current_tag="proxy${current_id}"
	local default_target=""
	local default_outbound_tag=""
	local tmp_file="${config_file}.tmp.$$"
	local dns_rule=""
	local route_rules_file="${tmp_file}.rules"
	local build_started=0
	local build_elapsed=0

	[ -n "${config_file}" ] || return 1
	[ -n "${current_id}" ] || return 1
	fss_shunt_mode_selected || return 1
	build_started="$(date +%s)"
	fss_shunt_validate_current_node "${current_id}" || return 1
	fss_shunt_prepare_runtime || return 1
	fss_shunt_prepare_outbound_cache "${current_id}" || return 1
	fss_shunt_write_hot_reload_state >/dev/null 2>&1 || true
	default_target="$(fss_shunt_get_effective_default_target)"
	if fss_shunt_target_is_direct "${default_target}"; then
		default_outbound_tag="direct"
	else
		[ -n "${default_target}" ] || default_target="${current_id}"
		default_outbound_tag="proxy${default_target}"
	fi

	cat > "${tmp_file}" <<-EOF2
	{
	  "log": {
	    "access": "none",
	    "error": "none",
	    "loglevel": "warning"
	  },
	  "api": {
	    "tag": "api",
	    "services": ["StatsService", "HandlerService", "RoutingService"]
	  },
	  "stats": {},
	  "policy": {
	    "system": {
	      "statsOutboundUplink": true,
	      "statsOutboundDownlink": true
	    }
	  },
	  "inbounds": [
EOF2
	gen_xray_dns_inbound "${tmp_file}"
	cat >> "${tmp_file}" <<-EOF2
	    {
	      "tag": "socks-in",
	      "port": 23456,
	      "listen": "127.0.0.1",
	      "protocol": "socks",
	      "settings": {
	        "auth": "noauth",
	        "udp": true,
	        "ip": "127.0.0.1"
	      }
	    },
	    {
	      "tag": "tproxy-in",
	      "listen": "0.0.0.0",
	      "port": 3333,
	      "protocol": "dokodemo-door",
	      "settings": {
	        "network": "tcp,udp",
	        "followRedirect": true
	      },
	      "sniffing": {
	        "enabled": true,
	        "destOverride": ["http", "tls"],
	        "routeOnly": true
	      }
	    },
	    {
	      "tag": "api-in",
	      "listen": "127.0.0.1",
	      "port": 10085,
	      "protocol": "dokodemo-door",
	      "settings": {
	        "address": "127.0.0.1"
	      }
	    }
	  ],
	  "outbounds": [
EOF2
	fss_shunt_emit_outbounds_json "${current_id}" >> "${tmp_file}" || {
		rm -f "${tmp_file}" "${route_rules_file}" >/dev/null 2>&1
		return 1
	}
	cat >> "${tmp_file}" <<-EOF2
	  ,
	    {"tag":"api","protocol":"freedom","settings":{}}
	  ],
	  "routing": {
	    "domainStrategy": "AsIs",
	    "rules": [
	      {"type":"field","inboundTag":["socks-in"],"outboundTag":"${current_tag}"},
	      {"type":"field","inboundTag":["api-in"],"outboundTag":"api"}
EOF2
	dns_rule="$(fss_shunt_emit_dns_relay_route_rule "${current_id}")"
	if [ -n "${dns_rule}" ]; then
		printf ',\n%s\n' "${dns_rule}" >> "${tmp_file}"
	fi
	fss_shunt_emit_routing_rules_json > "${route_rules_file}" 2>/dev/null
	if [ -s "${route_rules_file}" ]; then
		printf ',\n' >> "${tmp_file}"
		cat "${route_rules_file}" >> "${tmp_file}"
		printf '\n' >> "${tmp_file}"
	fi
	cat >> "${tmp_file}" <<-EOF2
	,
	      {"type":"field","ruleTag":"fss_default","network":"tcp,udp","outboundTag":"${default_outbound_tag}"}
	    ]
	  }
	}
EOF2
	rm -f "${route_rules_file}" >/dev/null 2>&1
	mv -f "${tmp_file}" "${config_file}"
	build_elapsed=$(( $(date +%s) - build_started ))
	fss_shunt_log "xray分流配置已生成，用时${build_elapsed}s。"
}
