#!/bin/sh

# fancyss node helper functions

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh

FSS_NODE_BOOL_FIELDS="
v2ray_use_json
v2ray_mux_enable
v2ray_network_security_ai
v2ray_network_security_alpn_h2
v2ray_network_security_alpn_http
xray_use_json
xray_network_security_ai
xray_network_security_alpn_h2
xray_network_security_alpn_http
xray_show
trojan_ai
trojan_tfo
hy2_ai
hy2_tfo
anytls_ai
"

FSS_NODE_B64_FIELDS="
password
naive_pass
v2ray_json
xray_json
tuic_json
"

FSS_NODE_RUNTIME_FIELDS="
latency
ping
"

FSS_NODE_MIGRATION_DIR="/koolshare/configs/fancyss/migration"
FSS_NODE_MIGRATION_LOCK="/var/lock/fss_node_migrate.lock"
FSS_NODE_MIGRATION_KEEP=3
FSS_NODE_DIRECT_CACHE_FILE="/koolshare/configs/fancyss/node_direct_domains.txt"
FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE="/koolshare/configs/fancyss/node_airport_domains.txt"
FSS_NODE_DIRECT_RUNTIME_FILE="/tmp/ss_node_domains.txt"
FSS_NODE_DIRECT_RUNTIME_OTHER_FILE="/tmp/ss_node_domains_other.txt"
FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE="/tmp/ss_node_domains_airport.txt"
FSS_NODE_DIRECT_RUNTIME_AIRPORT_DNS_FILE="/tmp/ss_node_domains_airport_dns.txt"
FSS_NODE_DIRECT_CACHE_META_FILE="/koolshare/configs/fancyss/node_direct_domains.meta"
FSS_NODE_JSON_CACHE_DIR="/koolshare/configs/fancyss/node_json_cache"
FSS_NODE_JSON_CACHE_META_FILE="/koolshare/configs/fancyss/node_json_cache.meta"
FSS_NODE_JSON_INDEX_FILE="${FSS_NODE_JSON_CACHE_DIR}/nodes_index.txt"
FSS_NODE_ENV_CACHE_DIR="/koolshare/configs/fancyss/node_env_cache"
FSS_NODE_ENV_CACHE_META_FILE="/koolshare/configs/fancyss/node_env_cache.meta"
FSS_NODE_ENV_CACHE_OBFS_FILE="${FSS_NODE_ENV_CACHE_DIR}/ss_obfs_ids.txt"
FSS_WEBTEST_CACHE_DIR="/koolshare/configs/fancyss/webtest_cache"
FSS_WEBTEST_CACHE_NODE_DIR="${FSS_WEBTEST_CACHE_DIR}/nodes"
FSS_WEBTEST_CACHE_META_DIR="${FSS_WEBTEST_CACHE_DIR}/meta"
FSS_WEBTEST_CACHE_GLOBAL_META_FILE="${FSS_WEBTEST_CACHE_DIR}/cache.meta"
FSS_WEBTEST_CACHE_INDEX_FILE="${FSS_WEBTEST_CACHE_DIR}/materialize_index.txt"
FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE="${FSS_WEBTEST_CACHE_DIR}/all_outbounds.json"
FSS_WEBTEST_RUNTIME_FILE="/tmp/upload/webtest.txt"
FSS_WEBTEST_RUNTIME_STREAM_FILE="/tmp/upload/webtest.stream"
FSS_WEBTEST_RUNTIME_BACKUP_FILE="/tmp/upload/webtest_bakcup.txt"
FSS_CURRENT_NODE_IDENTITY_DBUS_KEY="fss_node_current_identity"
FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY="fss_node_failover_identity"
FSS_REFERENCE_NOTICE_DBUS_KEY="fss_data_reference_notice"
FSS_REFERENCE_NOTICE_TS_DBUS_KEY="fss_data_reference_notice_ts"
FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY="fss_current_node_identity"
FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY="fss_failover_node_identity"
FSS_REFERENCE_NOTICE_DBUS_KEY_LEGACY="fss_reference_notice"
FSS_REFERENCE_NOTICE_TS_DBUS_KEY_LEGACY="fss_reference_notice_ts"
FSS_AIRPORT_PROFILE_FILE="/koolshare/ss/rules/airport-profile.json"
FSS_AIRPORT_SPECIAL_INDEX_FILE="/koolshare/configs/fancyss/airport_special.list"

fss_pick_node_tool() {
	if [ -n "${FSS_NODE_TOOL_PICKED:-}" ]; then
		if [ "${FSS_NODE_TOOL_PICKED}" != "none" ] && [ -x "${FSS_NODE_TOOL_PICKED}" ]; then
			if [ "${FSS_NODE_TOOL_TRUST_PICKED:-}" = "1" ];then
				printf '%s\n' "${FSS_NODE_TOOL_PICKED}"
				return 0
			fi
			if ! "${FSS_NODE_TOOL_PICKED}" version >/dev/null 2>&1; then
				unset FSS_NODE_TOOL_PICKED
				unset FSS_NODE_TOOL_TRUST_PICKED
			else
				printf '%s\n' "${FSS_NODE_TOOL_PICKED}"
				return 0
			fi
		fi
		unset FSS_NODE_TOOL_PICKED
		unset FSS_NODE_TOOL_TRUST_PICKED
	fi
	if [ -x "/koolshare/bin/node-tool" ];then
		FSS_NODE_TOOL_PICKED="/koolshare/bin/node-tool"
		export FSS_NODE_TOOL_PICKED
		echo "/koolshare/bin/node-tool"
		return 0
	fi
	if command -v node-tool >/dev/null 2>&1; then
		if "$(command -v node-tool)" version >/dev/null 2>&1; then
			FSS_NODE_TOOL_PICKED="$(command -v node-tool)"
			export FSS_NODE_TOOL_PICKED
			command -v node-tool
			return 0
		fi
	fi
	return 1
}

fss_node_tool_supports_command() {
	local node_tool="$1"
	local command_name="$2"
	[ -n "${node_tool}" ] || return 1
	[ -n "${command_name}" ] || return 1
	"${node_tool}" "${command_name}" --help >/dev/null 2>&1 && return 0
	"${node_tool}" --help 2>&1 | grep -Eq "^[[:space:]]*node-tool[[:space:]]+${command_name}([[:space:]]|$)"
}

fss_run_node_tool() {
	local node_tool="$1"
	shift
	if [ "${FSS_NODE_TOOL_CLEAN_ENV:-}" = "1" ];then
		env -i PATH="/koolshare/bin:/usr/sbin:/usr/bin:/sbin:/bin" "${node_tool}" "$@"
		return "$?"
	fi
	"${node_tool}" "$@"
}

fss_run_node_tool_with_clean_retry() {
	local node_tool="$1"
	local output_file="$2"
	shift 2
	fss_run_node_tool "${node_tool}" "$@" > "${output_file}" 2>&1
	local node_tool_rc="$?"
	if [ "${node_tool_rc}" = "127" ];then
		env -i PATH="/koolshare/bin:/usr/sbin:/usr/bin:/sbin:/bin" "${node_tool}" "$@" > "${output_file}" 2>&1
		node_tool_rc="$?"
	fi
	return "${node_tool_rc}"
}

fss_airport_special_conf_path() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	printf '%s/%s.conf\n' "/koolshare/configs/fancyss" "${airport_identity}"
}

fss_airport_special_conf_register() {
	local airport_identity="$1"
	local index_file="${FSS_AIRPORT_SPECIAL_INDEX_FILE}"
	local tmp_file="${index_file}.tmp.$$"
	local index_dir="${index_file%/*}"
	[ -n "${airport_identity}" ] || return 1
	mkdir -p "${index_dir}" || return 1
	{
		[ -f "${index_file}" ] && cat "${index_file}"
		printf '%s\n' "${airport_identity}"
	} | sed '/^$/d' | sort -u > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${index_file}"
}

fss_airport_special_conf_unregister() {
	local airport_identity="$1"
	local index_file="${FSS_AIRPORT_SPECIAL_INDEX_FILE}"
	local tmp_file="${index_file}.tmp.$$"
	[ -n "${airport_identity}" ] || return 1
	[ -f "${index_file}" ] || return 0
	grep -Fvx "${airport_identity}" "${index_file}" > "${tmp_file}" 2>/dev/null || true
	if [ -s "${tmp_file}" ];then
		mv -f "${tmp_file}" "${index_file}"
	else
		rm -f "${tmp_file}" "${index_file}"
	fi
}

fss_remove_airport_special_conf() {
	local airport_identity="$1"
	local conf_path=""
	[ -n "${airport_identity}" ] || return 1
	conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || return 1
	rm -f "${conf_path}" >/dev/null 2>&1
	fss_airport_special_conf_unregister "${airport_identity}" >/dev/null 2>&1 || true
}

fss_airport_special_conf_signature() {
	local airport_identity="$1"
	local conf_path=""
	[ -n "${airport_identity}" ] || {
		echo "missing"
		return 0
	}
	conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || {
		echo "missing"
		return 0
	}
	if [ -f "${conf_path}" ];then
		md5sum "${conf_path}" 2>/dev/null | awk '{print $1}'
	else
		echo "missing"
	fi
}

fss_clear_airport_special_confs() {
	local index_file="${FSS_AIRPORT_SPECIAL_INDEX_FILE}"
	local airport_identity=""
	local conf_path=""
	if [ -f "${index_file}" ];then
		while IFS= read -r airport_identity
		do
			[ -n "${airport_identity}" ] || continue
			conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
			rm -f "${conf_path}" >/dev/null 2>&1
		done < "${index_file}"
	fi
	rm -f "${index_file}" >/dev/null 2>&1
}

fss_clear_webtest_cache_node() {
	local node_id="$1"

	[ -n "${node_id}" ] || return 0
	rm -f "${FSS_WEBTEST_CACHE_META_DIR}/${node_id}.meta" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_outbounds.json" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_start.sh" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_stop.sh" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_anytls.pass" \
		"${FSS_WEBTEST_CACHE_NODE_DIR}/${node_id}_anytls.pid" \
		"${FSS_WEBTEST_CACHE_AGG_OUTBOUNDS_FILE}" \
		"${FSS_WEBTEST_CACHE_INDEX_FILE}" \
		"${FSS_WEBTEST_CACHE_GLOBAL_META_FILE}" >/dev/null 2>&1
}

fss_clear_node_json_cache_node() {
	local node_id="$1"

	[ -n "${node_id}" ] || return 0
	rm -f "${FSS_NODE_JSON_CACHE_DIR}/${node_id}.json" \
		"${FSS_NODE_JSON_INDEX_FILE}" \
		"${FSS_NODE_JSON_CACHE_META_FILE}" >/dev/null 2>&1
}

fss_clear_node_cache_node() {
	local node_id="$1"

	[ -n "${node_id}" ] || return 0
	fss_clear_node_json_cache_node "${node_id}" >/dev/null 2>&1 || true
	fss_clear_webtest_cache_node "${node_id}" >/dev/null 2>&1 || true
}

fss_clear_webtest_cache_all() {
	rm -rf "${FSS_WEBTEST_CACHE_DIR}" >/dev/null 2>&1
}

fss_clear_webtest_runtime_results() {
	rm -f "${FSS_WEBTEST_RUNTIME_FILE}" \
		"${FSS_WEBTEST_RUNTIME_STREAM_FILE}" \
		"${FSS_WEBTEST_RUNTIME_BACKUP_FILE}" >/dev/null 2>&1
	dbus remove ss_basic_webtest_ts >/dev/null 2>&1
}

fss_clear_reference_notice() {
	dbus remove "${FSS_REFERENCE_NOTICE_DBUS_KEY}" >/dev/null 2>&1
	dbus remove "${FSS_REFERENCE_NOTICE_TS_DBUS_KEY}" >/dev/null 2>&1
	dbus remove "${FSS_REFERENCE_NOTICE_DBUS_KEY_LEGACY}" >/dev/null 2>&1
	dbus remove "${FSS_REFERENCE_NOTICE_TS_DBUS_KEY_LEGACY}" >/dev/null 2>&1
}

fss_set_reference_notice_json() {
	local notice_json="$1"
	local ts=""

	[ -n "${notice_json}" ] || {
		fss_clear_reference_notice
		return 0
	}
	ts="$(fss_now_ts_ms)"
	dbus set "${FSS_REFERENCE_NOTICE_DBUS_KEY}=$(fss_b64_encode "${notice_json}")"
	dbus set "${FSS_REFERENCE_NOTICE_TS_DBUS_KEY}=${ts}"
	dbus remove "${FSS_REFERENCE_NOTICE_DBUS_KEY_LEGACY}" >/dev/null 2>&1
	dbus remove "${FSS_REFERENCE_NOTICE_TS_DBUS_KEY_LEGACY}" >/dev/null 2>&1
}

fss_get_node_catalog_ts() {
	local ts

	ts=$(dbus get fss_node_catalog_ts)
	printf '%s' "${ts}" | grep -Eq '^[0-9]+$' || ts="0"
	printf '%s' "${ts}"
}

fss_now_ts_ms() {
	local now_sec

	now_sec=$(date +%s)
	printf '%s' "${now_sec}" | grep -Eq '^[0-9]+$' || now_sec="0"
	printf '%s000' "${now_sec}"
}

fss_next_ts_ms() {
	local old_ts="$1"
	local now_ts

	now_ts=$(fss_now_ts_ms)
	awk -v now="${now_ts}" -v old="${old_ts}" 'BEGIN {
		if (now !~ /^[0-9]+$/) now = 0
		if (old !~ /^[0-9]+$/) old = 0
		if ((now + 0) <= (old + 0)) now = (old + 0) + 1
		printf "%.0f", now + 0
	}'
}

fss_touch_node_catalog_ts() {
	local old_ts now_ts

	old_ts=$(fss_get_node_catalog_ts)
	now_ts=$(fss_next_ts_ms "${old_ts}")
	dbus set fss_node_catalog_ts="${now_ts}"
	printf '%s' "${now_ts}"
}

fss_get_node_config_ts() {
	local ts

	ts=$(dbus get fss_node_config_ts)
	printf '%s' "${ts}" | grep -Eq '^[0-9]+$' || ts="0"
	printf '%s' "${ts}"
}

fss_touch_node_config_ts() {
	local old_ts now_ts

	old_ts=$(fss_get_node_config_ts)
	now_ts=$(fss_next_ts_ms "${old_ts}")
	dbus set fss_node_config_ts="${now_ts}"
	printf '%s' "${now_ts}"
}

fss_node_field_affects_direct_domains() {
	case "$1" in
	type|server|naive_server|hy2_server|anytls_server|v2ray_use_json|v2ray_json|xray_use_json|xray_json|tuic_json)
		return 0
		;;
	esac
	return 1
}

fss_get_node_direct_cache_meta_value() {
	local key="$1"

	[ -f "${FSS_NODE_DIRECT_CACHE_META_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_NODE_DIRECT_CACHE_META_FILE}" | sed -n '1p'
}

fss_write_node_direct_cache_meta() {
	local catalog_ts="$1"
	local cache_dir="${FSS_NODE_DIRECT_CACHE_META_FILE%/*}"
	local tmp_file="${FSS_NODE_DIRECT_CACHE_META_FILE}.tmp.$$"

	mkdir -p "${cache_dir}" || return 1
	cat > "${tmp_file}" <<-EOF
		catalog_ts=${catalog_ts}
		built_at=$(date +%s)
	EOF
	mv -f "${tmp_file}" "${FSS_NODE_DIRECT_CACHE_META_FILE}"
}

fss_node_direct_cache_is_fresh() {
	local catalog_ts=""
	local cached_ts=""

	[ -s "${FSS_NODE_DIRECT_CACHE_FILE}" ] || return 1
	[ -s "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" ] || return 1
	[ -f "${FSS_NODE_DIRECT_CACHE_META_FILE}" ] || return 1
	catalog_ts=$(fss_get_node_catalog_ts)
	[ "${catalog_ts}" != "0" ] || return 1
	cached_ts=$(fss_get_node_direct_cache_meta_value "catalog_ts")
	[ -n "${cached_ts}" ] || return 1
	[ "${cached_ts}" = "${catalog_ts}" ]
}

fss_get_node_json_cache_meta_value() {
	local key="$1"

	[ -f "${FSS_NODE_JSON_CACHE_META_FILE}" ] || return 1
	sed -n "s/^${key}=//p" "${FSS_NODE_JSON_CACHE_META_FILE}" | sed -n '1p'
}

fss_write_node_json_cache_meta() {
	local config_ts="$1"
	local cache_dir="${FSS_NODE_JSON_CACHE_META_FILE%/*}"
	local tmp_file="${FSS_NODE_JSON_CACHE_META_FILE}.tmp.$$"

	mkdir -p "${cache_dir}" || return 1
	cat > "${tmp_file}" <<-EOF
		config_ts=${config_ts}
		built_at=$(date +%s)
	EOF
	mv -f "${tmp_file}" "${FSS_NODE_JSON_CACHE_META_FILE}"
}

fss_node_json_cache_is_fresh() {
	local config_ts=""
	local cached_ts=""

	ls "${FSS_NODE_JSON_CACHE_DIR}"/*.json >/dev/null 2>&1 || return 1
	[ -f "${FSS_NODE_JSON_CACHE_META_FILE}" ] || return 1
	config_ts=$(fss_get_node_config_ts)
	[ "${config_ts}" != "0" ] || return 1
	cached_ts=$(fss_get_node_json_cache_meta_value "config_ts")
	[ -n "${cached_ts}" ] || cached_ts=$(fss_get_node_json_cache_meta_value "catalog_ts")
	[ -n "${cached_ts}" ] || return 1
	[ "${cached_ts}" = "${config_ts}" ]
}

fss_clear_node_env_cache_artifacts() {
	rm -rf "${FSS_NODE_ENV_CACHE_DIR}" \
		"${FSS_NODE_ENV_CACHE_DIR}.tmp."* \
		"${FSS_NODE_ENV_CACHE_DIR}.old."* \
		"${FSS_NODE_ENV_CACHE_DIR}.tmp.node_tool" \
		"${FSS_NODE_ENV_CACHE_DIR}.old.node_tool" >/dev/null 2>&1
	rm -f "${FSS_NODE_ENV_CACHE_META_FILE}" >/dev/null 2>&1
}

fss_schedule_webtest_cache_warm() {
	local warm_log="${2:-/tmp/upload/ss_log.txt}"
	local ignore_pid="$1"
	local webtest_pids=""

	[ -x "${KSROOT}/scripts/ss_webtest.sh" ] || return 0
	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	[ -n "$(fss_list_node_ids | sed -n '1p')" ] || return 0
	webtest_pids=$(ps | grep -E "ss_webtest\.sh" | awk '{print $1}' | grep -v "^${ignore_pid}$" 2>/dev/null)
	if [ -n "${webtest_pids}" ]; then
		return 0
	fi
	mkdir -p /tmp/upload >/dev/null 2>&1
	sh "${KSROOT}/scripts/ss_webtest.sh" warm_cache >> "${warm_log}" 2>&1 &
}

fss_get_acl_default_ports_value() {
	local modern legacy
	modern=$(dbus get ss_acl_default_ports)
	if [ -n "${modern}" ]; then
		printf '%s' "${modern}"
		return 0
	fi
	legacy=$(dbus get ss_acl_default_port)
	if [ -n "${legacy}" ]; then
		printf '%s' "${legacy}"
		return 0
	fi
	return 1
}

fss_cleanup_acl_default_port_keys() {
	local modern legacy
	modern=$(dbus get ss_acl_default_ports)
	legacy=$(dbus get ss_acl_default_port)
	if [ -z "${modern}" ] && [ -n "${legacy}" ]; then
		dbus set ss_acl_default_ports="${legacy}"
		modern="${legacy}"
	fi
	if [ -n "${legacy}" ]; then
		dbus remove ss_acl_default_port
	fi
	[ -n "${modern}" ]
}

fss_b64_encode() {
	printf '%s' "$1" | base64 | tr -d '\n'
}

fss_b64_decode() {
	printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 --decode 2>/dev/null
}

fss_node_json_meta_assignments() {
	local node_json="$1"
	[ -n "${node_json}" ] || return 0
	printf '%s' "${node_json}" | jq -r '
		def text($v):
			if $v == null then
				""
			elif ($v | type) == "string" then
				$v
			else
				($v | tostring)
			end;
		@sh "FSS_NODE_META_B64_MODE=\(text(._b64_mode)); FSS_NODE_META_SOURCE=\(text(._source)); FSS_NODE_META_NAME=\(text(.name)); FSS_NODE_META_GROUP=\(text(.group)); FSS_NODE_META_PROFILE_ID=\(text(._profile_id)); FSS_NODE_META_AIRPORT_IDENTITY=\(text(._airport_identity)); FSS_NODE_META_SOURCE_SCOPE=\(text(._source_scope)); FSS_NODE_META_SOURCE_URL_HASH=\(text(._source_url_hash)); FSS_NODE_META_IDENTITY=\(text(._identity))"
	' 2>/dev/null
}

fss_unpack_node_meta() {
	local node_json="$1"
	local meta_assignments=""

	FSS_NODE_META_B64_MODE=""
	FSS_NODE_META_SOURCE=""
	FSS_NODE_META_NAME=""
	FSS_NODE_META_GROUP=""
	FSS_NODE_META_PROFILE_ID=""
	FSS_NODE_META_AIRPORT_IDENTITY=""
	FSS_NODE_META_SOURCE_SCOPE=""
	FSS_NODE_META_SOURCE_URL_HASH=""
	FSS_NODE_META_IDENTITY=""

	[ -n "${node_json}" ] || return 0
	meta_assignments="$(fss_node_json_meta_assignments "${node_json}")" || return 1
	[ -n "${meta_assignments}" ] && eval "${meta_assignments}"
}

fss_node_json_field_meta_assignments() {
	local node_json="$1"
	local field="$2"
	[ -n "${field}" ] || return 1
	[ -n "${node_json}" ] || return 0
	printf '%s' "${node_json}" | jq -r --arg k "${field}" '
		def text($v):
			if $v == null then
				""
			elif ($v | type) == "string" then
				$v
			else
				($v | tostring)
			end;
		@sh "FSS_NODE_FIELD_VALUE=\(text(.[$k])); FSS_NODE_FIELD_B64_MODE=\(text(._b64_mode)); FSS_NODE_FIELD_SOURCE=\(text(._source))"
	' 2>/dev/null
}

fss_unpack_node_field_meta() {
	local node_json="$1"
	local field="$2"
	local field_assignments=""

	FSS_NODE_FIELD_VALUE=""
	FSS_NODE_FIELD_B64_MODE=""
	FSS_NODE_FIELD_SOURCE=""

	[ -n "${field}" ] || return 1
	[ -n "${node_json}" ] || return 0
	field_assignments="$(fss_node_json_field_meta_assignments "${node_json}" "${field}")" || return 1
	[ -n "${field_assignments}" ] && eval "${field_assignments}"
}

fss_node_json_snapshot_tsv() {
	local node_json="$1"
	[ -n "${node_json}" ] || return 0
	printf '%s' "${node_json}" | jq -r '
		def text($v):
			if $v == null then
				""
			elif ($v | type) == "string" then
				$v
			else
				($v | tostring)
			end;
		[
			text(.name),
			text(.type),
			text((.server // .hy2_server)),
			text((.port // .hy2_port)),
			text(._identity)
		] | join("\u001f")
	' 2>/dev/null
}

fss_v2_field_plain_value() {
	local node_json="$1"
	local field="$2"
	local value="$3"
	local mode="$4"
	local source="$5"
	local decoded

	[ -n "${field}" ] || return 1
	if ! fss_is_b64_field "${field}"; then
		printf '%s' "${value}"
		return 0
	fi

	if [ -z "${mode}" ] || [ -z "${source}" ]; then
		fss_unpack_node_meta "${node_json}" || return 1
		mode="${FSS_NODE_META_B64_MODE}"
		source="${FSS_NODE_META_SOURCE}"
	fi
	if [ "${mode}" = "raw" ] || [ "${source}" != "subscribe" ]; then
		printf '%s' "${value}"
		return 0
	fi

	decoded=$(fss_b64_decode "${value}")
	if [ "$?" = "0" ]; then
		printf '%s' "${decoded}"
	else
		printf '%s' "${value}"
	fi
}

fss_shell_quote() {
	printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

fss_is_bool_field() {
	printf '%s\n' ${FSS_NODE_BOOL_FIELDS} | grep -Fxq "$1"
}

fss_is_b64_field() {
	printf '%s\n' ${FSS_NODE_B64_FIELDS} | grep -Fxq "$1"
}

fss_is_runtime_field() {
	printf '%s\n' ${FSS_NODE_RUNTIME_FIELDS} | grep -Fxq "$1"
}

fss_resolve_node_field_name() {
	case "$1" in
	xray_svn)
		echo "xray_vcn"
		;;
	hy2_svn)
		echo "hy2_vcn"
		;;
	*)
		echo "$1"
		;;
	esac
}

fss_identity_hash_v1() {
	if command -v cksum >/dev/null 2>&1; then
		printf '%s' "$1" | cksum | awk '{printf "%08x", $1}'
	else
		printf '%s' "$1" | md5sum | awk '{print substr($1, 1, 8)}'
	fi
}

fss_identity_slugify() {
	local raw="$1"
	local fallback="$2"
	local slug=""
	slug=$(printf '%s' "${raw}" \
		| tr 'A-Z' 'a-z' \
		| sed 's/[^a-z0-9]\+/_/g; s/^_//; s/_$//')
	[ -n "${slug}" ] || slug="${fallback}"
	printf '%s' "${slug}"
}

fss_legacy_subscribe_url_hash() {
	local sub_url="$1"
	[ -n "${sub_url}" ] || return 1
	sub_url=$(printf '%s' "${sub_url}" | sed 's/%20/ /g')
	printf '%s' "${sub_url}" | md5sum | awk '{print substr($1, 1, 4)}'
}

fss_legacy_subscribe_host_from_url() {
	local sub_url="$1"
	[ -n "${sub_url}" ] || return 1
	sub_url=$(printf '%s' "${sub_url}" | sed 's/%20/ /g')
	printf '%s' "${sub_url}" \
		| sed 's#^[A-Za-z][A-Za-z0-9+.-]*://##' \
		| sed 's#/.*$##' \
		| sed 's#^[^@]*@##' \
		| sed 's#^\[\([^]]*\)\].*$#\1#' \
		| sed 's#:.*$##' \
		| sed -n '1p'
}

fss_legacy_subscribe_domain_tag_from_url() {
	local host=""
	host="$(fss_legacy_subscribe_host_from_url "$1" 2>/dev/null)" || host=""
	[ -n "${host}" ] || return 1
	printf '%s' "${host}" | md5sum | awk '{print substr($1, 1, 4)}'
}

fss_legacy_group_base_from_value() {
	local raw_group="$1"
	local source_tag="$2"
	local group_base=""
	[ -n "${raw_group}" ] || return 1
	[ -n "${source_tag}" ] || return 1
	case "${raw_group}" in
	*_"${source_tag}")
		group_base="${raw_group%_"${source_tag}"}"
		;;
	*)
		return 1
		;;
	esac
	case "${group_base}" in
	""|"null"|"_")
		return 1
		;;
	esac
	printf '%s' "${group_base}"
}

fss_legacy_subscribe_group_from_legacy_nodes() {
	local source_tag="$1"
	local tmp_file="/tmp/.fss_legacy_group_${source_tag}.$$"
	local line value group_base match_count
	[ -n "${source_tag}" ] || return 1
	: > "${tmp_file}"
	dbus list ssconf_basic_group_ 2>/dev/null | while IFS='=' read -r _key value
	do
		[ -n "${value}" ] || continue
		group_base="$(fss_legacy_group_base_from_value "${value}" "${source_tag}" 2>/dev/null)" || continue
		[ -n "${group_base}" ] && printf '%s\n' "${group_base}"
	done | sort -u > "${tmp_file}"
	match_count="$(sed '/^$/d' "${tmp_file}" | wc -l | tr -d ' ')"
	if [ "${match_count}" = "1" ];then
		sed -n '1p' "${tmp_file}"
		rm -f "${tmp_file}"
		return 0
	fi
	line="$(sed '/^$/d' "${tmp_file}" | sed -n '1p')"
	rm -f "${tmp_file}"
	[ -n "${line}" ] || return 1
	printf '%s' "${line}"
}

fss_legacy_subscribe_group_from_schema2_nodes() {
	local source_tag="$1"
	local tmp_file="/tmp/.fss_schema2_group_${source_tag}.$$"
	local line key value node_json group_value group_base match_count
	[ -n "${source_tag}" ] || return 1
	: > "${tmp_file}"
	dbus list fss_node_ 2>/dev/null | while IFS='=' read -r key value
	do
		case "${key}" in
		fss_node_[0-9]*)
			node_json="$(fss_b64_decode "${value}" 2>/dev/null)" || continue
			group_value="$(printf '%s' "${node_json}" | jq -r '.group // empty' 2>/dev/null | sed -n '1p')"
			[ -n "${group_value}" ] || continue
			group_base="$(fss_legacy_group_base_from_value "${group_value}" "${source_tag}" 2>/dev/null)" || continue
			[ -n "${group_base}" ] && printf '%s\n' "${group_base}"
			;;
		esac
	done | sort -u > "${tmp_file}"
	match_count="$(sed '/^$/d' "${tmp_file}" | wc -l | tr -d ' ')"
	if [ "${match_count}" = "1" ];then
		sed -n '1p' "${tmp_file}"
		rm -f "${tmp_file}"
		return 0
	fi
	line="$(sed '/^$/d' "${tmp_file}" | sed -n '1p')"
	rm -f "${tmp_file}"
	[ -n "${line}" ] || return 1
	printf '%s' "${line}"
}

fss_legacy_subscribe_group_from_tags() {
	local source_tag group_label
	for source_tag in "$@"
	do
		[ -n "${source_tag}" ] || continue
		group_label="$(dbus get ss_online_group_${source_tag} 2>/dev/null)"
		[ -n "${group_label}" ] && {
			printf '%s' "${group_label}"
			return 0
		}
	done
	for source_tag in "$@"
	do
		[ -n "${source_tag}" ] || continue
		group_label="$(fss_legacy_subscribe_group_from_legacy_nodes "${source_tag}" 2>/dev/null)" || group_label=""
		[ -n "${group_label}" ] && {
			printf '%s' "${group_label}"
			return 0
		}
	done
	for source_tag in "$@"
	do
		[ -n "${source_tag}" ] || continue
		group_label="$(fss_legacy_subscribe_group_from_schema2_nodes "${source_tag}" 2>/dev/null)" || group_label=""
		[ -n "${group_label}" ] && {
			printf '%s' "${group_label}"
			return 0
		}
	done
	return 1
}

fss_legacy_subscribe_profile_id_by_url() {
	local sub_url="$1"
	local profile_id profile_json profile_url
	[ -n "${sub_url}" ] || return 1
	type subprof_list_profile_ids >/dev/null 2>&1 || return 1
	type subprof_profile_key >/dev/null 2>&1 || return 1
	type subprof_dbus_get_json_by_key >/dev/null 2>&1 || return 1
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		profile_json="$(subprof_dbus_get_json_by_key "$(subprof_profile_key "${profile_id}")" 2>/dev/null)" || continue
		profile_url="$(printf '%s' "${profile_json}" | jq -r '.url // empty' 2>/dev/null | sed -n '1p')"
		[ "${profile_url}" = "${sub_url}" ] && {
			printf '%s' "${profile_id}"
			return 0
		}
	done
	return 1
}

fss_legacy_subscribe_emit_meta_row() {
	local source_tag="$1"
	local profile_id="$2"
	local group_label="$3"
	local url_hash="$4"
	local airport_identity="$5"
	local source_scope="$6"
	[ -n "${source_tag}" ] || return 0
	case "${source_tag}" in
	user|local|null)
		return 0
		;;
	esac
	printf '%s' "${source_tag}" | grep -Eq '^[A-Za-z0-9]+$' || return 0
	[ -n "${group_label}" ] || group_label="${source_tag}"
	[ -n "${airport_identity}" ] || airport_identity="$(fss_identity_slugify "${group_label}" "${source_tag}")"
	if [ -z "${source_scope}" ];then
		source_scope="${airport_identity}"
		[ -n "${url_hash}" ] && source_scope="${source_scope}_${url_hash}"
	fi
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${source_tag}" "${profile_id}" "${airport_identity}" "${source_scope}" "${url_hash}" "${group_label}"
}

fss_collect_legacy_subscribe_source_meta_from_profiles() {
	local profile_id profile_key state_key profile_json state_json profile_url profile_name
	local last_group last_url_hash raw_tag canonical_tag legacy_tag group_label airport_identity source_scope group_value suffix
	local profile_host group_base profile_count match_group
	type subprof_list_profile_ids >/dev/null 2>&1 || return 1
	type subprof_profile_key >/dev/null 2>&1 || return 1
	type subprof_state_key >/dev/null 2>&1 || return 1
	type subprof_dbus_get_json_by_key >/dev/null 2>&1 || return 1
	profile_count="$(subprof_list_profile_ids 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')"
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		profile_key="$(subprof_profile_key "${profile_id}" 2>/dev/null)" || continue
		profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || continue
		[ -n "${profile_json}" ] || continue
		state_key="$(subprof_state_key "${profile_id}" 2>/dev/null)" || continue
		state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
		profile_url="$(printf '%s' "${profile_json}" | jq -r '.url // empty' 2>/dev/null | sed -n '1p')"
		profile_name="$(printf '%s' "${profile_json}" | jq -r '.name // empty' 2>/dev/null | sed -n '1p')"
		[ -n "${profile_url}" ] || continue
		profile_host="$(fss_legacy_subscribe_host_from_url "${profile_url}" 2>/dev/null)" || profile_host=""
		last_group="$(printf '%s' "${state_json}" | jq -r '.last_group // empty' 2>/dev/null | sed -n '1p')"
		last_url_hash="$(printf '%s' "${state_json}" | jq -r '.last_url_hash // empty' 2>/dev/null | sed -n '1p')"
		raw_tag="$(fss_legacy_subscribe_domain_tag_from_url "${profile_url}" 2>/dev/null)" || raw_tag=""
		canonical_tag=""
		[ -n "${raw_tag}" ] && canonical_tag="$(dbus get ss_online_hash_${raw_tag} 2>/dev/null)"
		[ -n "${canonical_tag}" ] || canonical_tag="${raw_tag}"
		legacy_tag="$(fss_legacy_subscribe_url_hash "${profile_url}" 2>/dev/null)" || legacy_tag=""
		[ -n "${last_url_hash}" ] || last_url_hash="${legacy_tag}"
		group_label="${last_group}"
		[ -n "${group_label}" ] || group_label="$(fss_legacy_subscribe_group_from_tags "${canonical_tag}" "${raw_tag}" "${legacy_tag}" 2>/dev/null)"
		[ -n "${group_label}" ] || group_label="${profile_name}"
		[ -n "${group_label}" ] || group_label="$(fss_legacy_subscribe_host_from_url "${profile_url}" 2>/dev/null)"
		airport_identity="$(fss_identity_slugify "${group_label}" "${canonical_tag:-${raw_tag:-sub}}")"
		source_scope="${airport_identity}"
		[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"
		fss_legacy_subscribe_emit_meta_row "${canonical_tag}" "${profile_id}" "${group_label}" "${last_url_hash}" "${airport_identity}" "${source_scope}"
		[ "${raw_tag}" != "${canonical_tag}" ] && fss_legacy_subscribe_emit_meta_row "${raw_tag}" "${profile_id}" "${group_label}" "${last_url_hash}" "${airport_identity}" "${source_scope}"
		[ "${legacy_tag}" != "${canonical_tag}" ] && [ "${legacy_tag}" != "${raw_tag}" ] && fss_legacy_subscribe_emit_meta_row "${legacy_tag}" "${profile_id}" "${group_label}" "${last_url_hash}" "${airport_identity}" "${source_scope}"
		dbus list ssconf_basic_group_ 2>/dev/null | cut -d "=" -f 2- | sed '/^$/d' | sort -u | while IFS= read -r group_value
		do
			suffix="${group_value##*_}"
			[ "${suffix}" != "${group_value}" ] || continue
			printf '%s' "${suffix}" | grep -Eq '^[A-Za-z0-9]{4}$' || continue
			group_base="${group_value%_*}"
			match_group=0
			case "${group_base}" in
			"${group_label}"|"${profile_name}"|"${profile_host}")
				match_group=1
				;;
			esac
			[ "${profile_count}" = "1" ] && match_group=1
			[ "${match_group}" = "1" ] || continue
			fss_legacy_subscribe_emit_meta_row "${suffix}" "${profile_id}" "${group_base}" "${suffix}" "${airport_identity}" "${airport_identity}_${suffix}"
		done
	done
}

fss_collect_schema2_subscribe_group_meta_from_profiles() {
	local profile_id profile_key state_key profile_json state_json profile_url profile_name
	local last_group last_url_hash raw_tag canonical_tag legacy_tag group_label airport_identity source_scope group_value suffix
	type subprof_list_profile_ids >/dev/null 2>&1 || return 1
	type subprof_profile_key >/dev/null 2>&1 || return 1
	type subprof_state_key >/dev/null 2>&1 || return 1
	type subprof_dbus_get_json_by_key >/dev/null 2>&1 || return 1
	for profile_id in $(subprof_list_profile_ids)
	do
		[ -n "${profile_id}" ] || continue
		profile_key="$(subprof_profile_key "${profile_id}" 2>/dev/null)" || continue
		profile_json="$(subprof_dbus_get_json_by_key "${profile_key}" 2>/dev/null)" || continue
		[ -n "${profile_json}" ] || continue
		state_key="$(subprof_state_key "${profile_id}" 2>/dev/null)" || continue
		state_json="$(subprof_dbus_get_json_by_key "${state_key}" 2>/dev/null)" || state_json=""
		profile_url="$(printf '%s' "${profile_json}" | jq -r '.url // empty' 2>/dev/null | sed -n '1p')"
		profile_name="$(printf '%s' "${profile_json}" | jq -r '.name // empty' 2>/dev/null | sed -n '1p')"
		[ -n "${profile_url}" ] || continue
		last_group="$(printf '%s' "${state_json}" | jq -r '.last_group // empty' 2>/dev/null | sed -n '1p')"
		last_url_hash="$(printf '%s' "${state_json}" | jq -r '.last_url_hash // empty' 2>/dev/null | sed -n '1p')"
		raw_tag="$(fss_legacy_subscribe_domain_tag_from_url "${profile_url}" 2>/dev/null)" || raw_tag=""
		canonical_tag=""
		[ -n "${raw_tag}" ] && canonical_tag="$(dbus get ss_online_hash_${raw_tag} 2>/dev/null)"
		[ -n "${canonical_tag}" ] || canonical_tag="${raw_tag}"
		legacy_tag="$(fss_legacy_subscribe_url_hash "${profile_url}" 2>/dev/null)" || legacy_tag=""
		[ -n "${last_url_hash}" ] || last_url_hash="${legacy_tag}"
		group_label="${last_group}"
		[ -n "${group_label}" ] || group_label="${profile_name}"
		[ -n "${group_label}" ] || group_label="$(fss_legacy_subscribe_host_from_url "${profile_url}" 2>/dev/null)"
		[ -n "${group_label}" ] || continue
		airport_identity="$(fss_identity_slugify "${group_label}" "${canonical_tag:-${raw_tag:-sub}}")"
		source_scope="${airport_identity}"
		[ -n "${last_url_hash}" ] && source_scope="${source_scope}_${last_url_hash}"
		fss_legacy_subscribe_emit_meta_row "${group_label}" "${profile_id}" "${group_label}" "${last_url_hash}" "${airport_identity}" "${source_scope}"
		{
			dbus list ssconf_basic_group_ 2>/dev/null | cut -d "=" -f 2-
			if [ "$(fss_detect_storage_schema 2>/dev/null)" = "2" ];then
				dbus list fss_node_ 2>/dev/null | while IFS='=' read -r key value
				do
					case "${key}" in
					fss_node_[0-9]*)
						fss_b64_decode "${value}" 2>/dev/null | jq -r '.group // empty' 2>/dev/null
						;;
					esac
				done
			fi
		} | sed '/^$/d' | sort -u | while IFS= read -r group_value
		do
			case "${group_value}" in
			"${group_label}"_*)
				suffix="${group_value##*_}"
				fss_legacy_subscribe_emit_meta_row "${suffix}" "${profile_id}" "${group_label}" "${last_url_hash}" "${airport_identity}" "${source_scope}"
				;;
			esac
		done
	done
}

fss_collect_legacy_subscribe_source_meta_from_links() {
	local raw_links="" link raw_tag canonical_tag legacy_tag profile_id group_label airport_identity source_scope host
	local group_value group_base suffix
	raw_links="$(dbus get ss_online_links | base64 -d 2>/dev/null)" || raw_links=""
	[ -n "${raw_links}" ] || return 1
	printf '%s\n' "${raw_links}" \
		| sed '/^$/d' \
		| sed '/^#/d' \
		| sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
		| grep -E '^https?://' | while IFS= read -r link
	do
		[ -n "${link}" ] || continue
		raw_tag="$(fss_legacy_subscribe_domain_tag_from_url "${link}" 2>/dev/null)" || raw_tag=""
		canonical_tag=""
		[ -n "${raw_tag}" ] && canonical_tag="$(dbus get ss_online_hash_${raw_tag} 2>/dev/null)"
		[ -n "${canonical_tag}" ] || canonical_tag="${raw_tag}"
		legacy_tag="$(fss_legacy_subscribe_url_hash "${link}" 2>/dev/null)" || legacy_tag=""
		profile_id="$(fss_legacy_subscribe_profile_id_by_url "${link}" 2>/dev/null)" || profile_id=""
		group_label="$(fss_legacy_subscribe_group_from_tags "${canonical_tag}" "${raw_tag}" "${legacy_tag}" 2>/dev/null)" || group_label=""
		if [ -z "${group_label}" ];then
			host="$(fss_legacy_subscribe_host_from_url "${link}" 2>/dev/null)" || host=""
			group_label="${host}"
		fi
		airport_identity="$(fss_identity_slugify "${group_label}" "${canonical_tag:-${raw_tag:-sub}}")"
		source_scope="${airport_identity}"
		[ -n "${legacy_tag}" ] && source_scope="${source_scope}_${legacy_tag}"
		fss_legacy_subscribe_emit_meta_row "${canonical_tag}" "${profile_id}" "${group_label}" "${legacy_tag}" "${airport_identity}" "${source_scope}"
		[ "${raw_tag}" != "${canonical_tag}" ] && fss_legacy_subscribe_emit_meta_row "${raw_tag}" "${profile_id}" "${group_label}" "${legacy_tag}" "${airport_identity}" "${source_scope}"
		[ "${legacy_tag}" != "${canonical_tag}" ] && [ "${legacy_tag}" != "${raw_tag}" ] && fss_legacy_subscribe_emit_meta_row "${legacy_tag}" "${profile_id}" "${group_label}" "${legacy_tag}" "${airport_identity}" "${source_scope}"
		dbus list ssconf_basic_group_ 2>/dev/null | cut -d "=" -f 2- | sed '/^$/d' | sort -u | while IFS= read -r group_value
		do
			suffix="${group_value##*_}"
			[ "${suffix}" != "${group_value}" ] || continue
			printf '%s' "${suffix}" | grep -Eq '^[A-Za-z0-9]{4}$' || continue
			group_base="${group_value%_*}"
			case "${group_base}" in
			"${group_label}"|"${host}")
				fss_legacy_subscribe_emit_meta_row "${suffix}" "${profile_id}" "${group_base}" "${suffix}" "${airport_identity}" "${airport_identity}_${suffix}"
				;;
			esac
		done
	done
}

fss_collect_legacy_subscribe_source_meta() {
	local output_file="$1"
	local tmp_file=""
	[ -n "${output_file}" ] || return 1
	tmp_file="${output_file}.tmp.$$"
	: > "${tmp_file}"
	fss_collect_legacy_subscribe_source_meta_from_links >> "${tmp_file}" 2>/dev/null || true
	fss_collect_legacy_subscribe_source_meta_from_profiles >> "${tmp_file}" 2>/dev/null || true
	fss_collect_schema2_subscribe_group_meta_from_profiles >> "${tmp_file}" 2>/dev/null || true
	if [ -s "${tmp_file}" ];then
		awk -F '\t' '
			NF >= 6 && $1 != "" {
				key = $1
				if (!(key in seen_order)) {
					order[++count] = key
					seen_order[key] = 1
				}
				if (!(key in row) || (profile_id[key] == "" && $2 != "")) {
					row[key] = $0
					profile_id[key] = $2
				}
			}
			END {
				for (i = 1; i <= count; i++) {
					key = order[i]
					if (row[key] != "") print row[key]
				}
			}
		' "${tmp_file}" > "${output_file}"
	else
		: > "${output_file}"
	fi
	rm -f "${tmp_file}"
	[ -s "${output_file}" ]
}

fss_repair_legacy_subscribe_source_meta() {
	local source_meta_file="/tmp/.fss_legacy_subscribe_source_meta.$$"
	local jq_filter_file="/tmp/.fss_legacy_subscribe_repair_filter.$$"
	local node_id blob node_json updated_json enriched_json
	local changed=0

	[ "$(fss_detect_storage_schema 2>/dev/null)" = "2" ] || {
		printf '%s\n' "0"
		return 0
	}
	fss_collect_legacy_subscribe_source_meta "${source_meta_file}" >/dev/null 2>&1 || {
		rm -f "${source_meta_file}"
		printf '%s\n' "0"
		return 0
	}
	cat > "${jq_filter_file}" <<-'EOF'
		def slugify($raw; $fallback):
			($raw | tostring | ascii_downcase | gsub("[^a-z0-9]+"; "_") | gsub("^_+|_+$"; "")) as $slug
			| if $slug == "" then $fallback else $slug end;
		def source_meta_by_tag:
			$source_meta
			| split("\n")
			| map(select(length > 0))
			| map(split("\t"))
			| map(select(length >= 6 and .[0] != "")
				| {
					tag: .[0],
					profile_id: .[1],
					airport_identity: .[2],
					source_scope: .[3],
					url_hash: .[4],
					group_label: .[5]
				})
			| map({key: .tag, value: .})
			| from_entries;
		def source_meta_by_group($group_label):
			[
				$source_meta
				| split("\n")
				| map(select(length > 0))
				| map(split("\t"))
				| map(select(length >= 6 and .[5] == $group_label)
					| {
						tag: .[0],
						profile_id: .[1],
						airport_identity: .[2],
						source_scope: .[3],
						url_hash: .[4],
						group_label: .[5]
					})
				| unique_by((.profile_id // "") + "\t" + (.source_scope // ""))
				| .[]
			] as $matches
			| if ($matches | length) == 1 then $matches[0] else null end;
		def subscription_meta($group):
			($group // "" | tostring) as $raw_group
			| (source_meta_by_group($raw_group)) as $direct_meta
			| if $direct_meta != null then
				($direct_meta.group_label // $raw_group) as $group_label_jq
				| ($direct_meta.url_hash // "") as $url_hash
				| ($direct_meta.airport_identity // slugify($group_label_jq; ($direct_meta.tag // "sub"))) as $airport_identity
				| ($direct_meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
				| {
					"_source": "subscribe",
					"_profile_id": ($direct_meta.profile_id // ""),
					"_airport_identity": $airport_identity,
					"_source_scope": $source_scope,
					"_source_url_hash": $url_hash
				}
			elif ($raw_group | test("_[A-Za-z0-9]+$")) then
				($raw_group | capture("^(?<base>.*)_(?<tag>[A-Za-z0-9]+)$")) as $parts
				| (source_meta_by_tag[$parts.tag] // null) as $tag_meta
				| (($tag_meta // null) // source_meta_by_group($parts.base)) as $meta
				| if $meta == null or ($tag_meta == null and (($meta.group_label // "") != "" and $parts.base != ($meta.group_label // ""))) then
					null
				else
					($meta.group_label // $parts.base) as $group_label_jq
					| ($meta.url_hash // "") as $url_hash
					| ($meta.airport_identity // slugify($group_label_jq; $parts.tag)) as $airport_identity
					| ($meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
					| {
						"_source": "subscribe",
						"_profile_id": ($meta.profile_id // ""),
						"_airport_identity": $airport_identity,
						"_source_scope": $source_scope,
						"_source_url_hash": $url_hash
					}
				end
			else
				null
			end;
		(subscription_meta(.group) // {}) as $sub_meta
		| if (($sub_meta._source // "") == "subscribe")
			and ((._migrated_from // "") != "" or ((["migration", "install", "legacy", "legacy-runtime", "restore-sh", "legacy-export"] | index(._source // "")) != null))
			and ((._source // "") != "subscribe" or (._source_scope // "") != ($sub_meta._source_scope // "") or ((._profile_id // "") == "" and ($sub_meta._profile_id // "") != "")) then
			. + $sub_meta
		else
			.
		end
EOF
	for node_id in $(fss_list_node_ids)
	do
		[ -n "${node_id}" ] || continue
		blob="$(dbus get fss_node_${node_id})"
		[ -n "${blob}" ] || continue
		node_json="$(fss_b64_decode "${blob}" 2>/dev/null)" || continue
		[ -n "${node_json}" ] || continue
		updated_json="$(printf '%s' "${node_json}" | jq -c --rawfile source_meta "${source_meta_file}" -f "${jq_filter_file}" 2>/dev/null)" || continue
		[ -n "${updated_json}" ] || continue
		[ "${updated_json}" != "${node_json}" ] || continue
		enriched_json="$(fss_enrich_node_identity_json "${updated_json}" "" "" "" "" 2>/dev/null)" || enriched_json="${updated_json}"
		dbus set fss_node_${node_id}="$(fss_b64_encode "${enriched_json}")" >/dev/null 2>&1 || continue
		changed=$((changed + 1))
	done
	rm -f "${source_meta_file}" "${jq_filter_file}"
	if [ "${changed}" -gt 0 ] 2>/dev/null;then
		fss_touch_node_catalog_ts >/dev/null 2>&1 || true
		fss_touch_node_config_ts >/dev/null 2>&1 || true
	fi
	printf '%s\n' "${changed}"
	return 0
}

fss_identity_secondary_payload_json() {
	if [ "$#" -gt 0 ]; then
		printf '%s' "$1"
	else
		cat
	fi | jq -S -c '
		del(
			.name,
			.group,
			.mode,
			._id,
			._schema,
			._rev,
			._source,
			._updated_at,
			._created_at,
			._migrated_from,
			._b64_mode,
			._profile_id,
			._airport_identity,
			._source_scope,
			._source_url_hash,
			._identity_primary,
			._identity_secondary,
			._identity,
			._identity_ver,
			._identity_slot,
			.server_ip,
			.latency,
			.ping
		)
	'
}

fss_enrich_node_identity_json() {
	local node_json="$1"
	local explicit_airport="$2"
	local explicit_scope="$3"
	local explicit_url_hash="$4"
	local explicit_source="$5"
	local explicit_profile_id="$6"
	local source=""
	local raw_name=""
	local group_value=""
	local profile_id=""
	local airport_identity=""
	local source_scope=""
	local source_url_hash=""
	local group_base=""
	local group_hash_suffix=""
	local primary=""
	local secondary_payload=""
	local secondary=""

	[ -n "${node_json}" ] || return 1
	fss_unpack_node_meta "${node_json}" || return 1
	source="${FSS_NODE_META_SOURCE}"
	[ -n "${source}" ] || source="${explicit_source}"
	[ -n "${source}" ] || source="manual"
	raw_name="${FSS_NODE_META_NAME}"
	group_value="${FSS_NODE_META_GROUP}"
	profile_id="${FSS_NODE_META_PROFILE_ID}"
	[ -n "${explicit_profile_id}" ] && profile_id="${explicit_profile_id}"
	source_url_hash="${FSS_NODE_META_SOURCE_URL_HASH}"
	[ -n "${explicit_url_hash}" ] && source_url_hash="${explicit_url_hash}"
	airport_identity="${FSS_NODE_META_AIRPORT_IDENTITY}"
	[ -n "${explicit_airport}" ] && airport_identity="${explicit_airport}"
	source_scope="${FSS_NODE_META_SOURCE_SCOPE}"
	[ -n "${explicit_scope}" ] && source_scope="${explicit_scope}"

	if [ "${source}" = "subscribe" ]; then
		case "${group_value}" in
		*_[0-9a-f][0-9a-f][0-9a-f][0-9a-f])
			group_base="${group_value%_*}"
			group_hash_suffix="${group_value##*_}"
			[ -n "${explicit_airport}" ] || airport_identity=$(fss_identity_slugify "${group_base}" "sub")
			if [ -z "${source_url_hash}" ] && [ -z "${explicit_url_hash}" ]; then
				source_url_hash="${group_hash_suffix}"
			fi
			;;
		esac
		if [ -z "${airport_identity}" ]; then
			group_base="${group_value}"
			case "${group_base}" in
			*_*)
				group_base="${group_base%_*}"
				;;
			esac
			airport_identity=$(fss_identity_slugify "${group_base}" "sub")
		fi
		if [ -z "${explicit_scope}" ]; then
			source_scope="${airport_identity}"
			[ -n "${source_url_hash}" ] && source_scope="${source_scope}_${source_url_hash}"
		elif [ -z "${source_scope}" ]; then
			source_scope="${airport_identity}"
			[ -n "${source_url_hash}" ] && source_scope="${source_scope}_${source_url_hash}"
		fi
	else
		[ -n "${airport_identity}" ] || airport_identity="local"
		[ -n "${source_scope}" ] || source_scope="local"
		if [ "${source_scope}" = "local" ]; then
			source_url_hash=""
		fi
	fi

	primary=$(fss_identity_hash_v1 "$(printf '%s\037%s' "${source_scope}" "${raw_name}")")
	secondary_payload=$(fss_identity_secondary_payload_json "${node_json}") || return 1
	secondary=$(fss_identity_hash_v1 "${secondary_payload}")

	printf '%s' "${node_json}" | jq -c \
		--arg source "${source}" \
		--arg profile_id "${profile_id}" \
		--arg airport_identity "${airport_identity}" \
		--arg source_scope "${source_scope}" \
		--arg source_url_hash "${source_url_hash}" \
		--arg identity_primary "${primary}" \
		--arg identity_secondary "${secondary}" \
		'
		. + {
			"_source": (if (._source // "") == "" then $source else ._source end),
			"_profile_id": $profile_id,
			"_airport_identity": $airport_identity,
			"_source_scope": $source_scope,
			"_source_url_hash": $source_url_hash,
			"_identity_primary": $identity_primary,
			"_identity_secondary": $identity_secondary,
			"_identity": ($identity_primary + "_" + $identity_secondary),
			"_identity_ver": "1"
		}
	'
}

fss_enrich_node_identity_file() {
	local input_file="$1"
	local output_file="$2"
	local explicit_airport="$3"
	local explicit_scope="$4"
	local explicit_url_hash="$5"
	local explicit_source="$6"
	local explicit_profile_id="$7"
	local line=""

	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	: > "${output_file}"
	while IFS= read -r line || [ -n "${line}" ]
	do
		[ -n "${line}" ] || continue
		fss_enrich_node_identity_json "${line}" "${explicit_airport}" "${explicit_scope}" "${explicit_url_hash}" "${explicit_source}" "${explicit_profile_id}" >> "${output_file}" || return 1
	done < "${input_file}"
}

fss_prune_node_json() {
	if [ "$#" -gt 0 ]; then
		printf '%s' "$1"
	else
		cat
	fi | jq -c '
		def keep_common($k):
			$k == "group"
			or $k == "name"
			or $k == "mode"
			or $k == "type";
		def keep_type($type; $k):
			if $type == "0" then
				$k == "server"
				or $k == "port"
				or $k == "method"
				or $k == "password"
				or $k == "ss_obfs"
				or $k == "ss_obfs_host"
			elif $type == "1" then
				$k == "server"
				or $k == "port"
				or $k == "method"
				or $k == "password"
				or $k == "rss_protocol"
				or $k == "rss_protocol_param"
				or $k == "rss_obfs"
				or $k == "rss_obfs_param"
			elif $type == "3" then
				$k == "server"
				or $k == "port"
				or $k == "v2ray_uuid"
				or $k == "v2ray_alterid"
				or $k == "v2ray_security"
				or $k == "v2ray_network"
				or $k == "v2ray_headtype_tcp"
				or $k == "v2ray_headtype_kcp"
				or $k == "v2ray_kcp_seed"
				or $k == "v2ray_headtype_quic"
				or $k == "v2ray_grpc_mode"
				or $k == "v2ray_grpc_authority"
				or $k == "v2ray_network_path"
				or $k == "v2ray_network_host"
				or $k == "v2ray_network_security"
				or $k == "v2ray_network_security_ai"
				or $k == "v2ray_network_security_alpn_h2"
				or $k == "v2ray_network_security_alpn_http"
				or $k == "v2ray_network_security_sni"
				or $k == "v2ray_mux_concurrency"
				or $k == "v2ray_json"
				or $k == "v2ray_use_json"
				or $k == "v2ray_mux_enable"
			elif $type == "4" then
				$k == "server"
				or $k == "port"
				or $k == "xray_uuid"
				or $k == "xray_alterid"
				or $k == "xray_prot"
				or $k == "xray_encryption"
				or $k == "xray_flow"
				or $k == "xray_network"
				or $k == "xray_headtype_tcp"
				or $k == "xray_headtype_kcp"
				or $k == "xray_kcp_seed"
				or $k == "xray_headtype_quic"
				or $k == "xray_grpc_mode"
				or $k == "xray_grpc_authority"
				or $k == "xray_xhttp_mode"
				or $k == "xray_network_path"
				or $k == "xray_network_host"
				or $k == "xray_network_security"
				or $k == "xray_network_security_ai"
				or $k == "xray_network_security_alpn_h2"
				or $k == "xray_network_security_alpn_http"
				or $k == "xray_network_security_sni"
				or $k == "xray_pcs"
				or $k == "xray_vcn"
				or $k == "xray_fingerprint"
				or $k == "xray_publickey"
				or $k == "xray_shortid"
				or $k == "xray_spiderx"
				or $k == "xray_show"
				or $k == "xray_json"
				or $k == "xray_use_json"
			elif $type == "5" then
				$k == "server"
				or $k == "port"
				or $k == "trojan_ai"
				or $k == "trojan_uuid"
				or $k == "trojan_sni"
				or $k == "trojan_pcs"
				or $k == "trojan_vcn"
				or $k == "trojan_tfo"
				or $k == "trojan_plugin"
				or $k == "trojan_obfs"
				or $k == "trojan_obfshost"
				or $k == "trojan_obfsuri"
			elif $type == "6" then
				$k == "naive_prot"
				or $k == "naive_server"
				or $k == "naive_port"
				or $k == "naive_user"
				or $k == "naive_pass"
			elif $type == "7" then
				$k == "tuic_json"
			elif $type == "8" then
				$k == "hy2_server"
				or $k == "hy2_port"
				or $k == "hy2_pass"
				or $k == "hy2_up"
				or $k == "hy2_dl"
				or $k == "hy2_obfs"
				or $k == "hy2_obfs_pass"
				or $k == "hy2_sni"
				or $k == "hy2_pcs"
				or $k == "hy2_vcn"
				or $k == "hy2_ai"
				or $k == "hy2_tfo"
				or $k == "hy2_cg"
			elif $type == "9" then
				$k == "anytls_server"
				or $k == "anytls_port"
				or $k == "anytls_pass"
				or $k == "anytls_sni"
				or $k == "anytls_ai"
			else
				false
			end;
		. as $root
		| (($root.type // "") | tostring) as $type
		| with_entries(select((.key | startswith("_")) or keep_common(.key) or keep_type($type; .key)))
	'
}

fss_prepare_backup_node_json() {
	if [ "$#" -gt 0 ]; then
		printf '%s' "$1"
	else
		cat
	fi | jq -c '
		with_entries(select(.value != "" and .value != null))
		| del(
			.server_ip,
			.latency,
			.ping,
			._schema,
			._rev,
			._updated_at,
			._migrated_from,
			._created_at
		)
		| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end
	' | fss_prune_node_json
}

fss_get_plugin_version() {
	local version
	version=$(dbus get ss_basic_version_local)
	[ -n "${version}" ] && {
		echo "${version}"
		return
	}
	[ -f "${KSROOT}/ss/version" ] && cat ${KSROOT}/ss/version
}

fss_detect_storage_schema() {
	local schema
	if [ -n "${FSS_STORAGE_SCHEMA_CACHE:-}" ]; then
		printf '%s\n' "${FSS_STORAGE_SCHEMA_CACHE}"
		return 0
	fi
	schema=$(dbus get fss_data_schema)
	if [ "${schema}" = "2" ];then
		FSS_STORAGE_SCHEMA_CACHE="2"
	else
		FSS_STORAGE_SCHEMA_CACHE="1"
	fi
	export FSS_STORAGE_SCHEMA_CACHE
	printf '%s\n' "${FSS_STORAGE_SCHEMA_CACHE}"
}

fss_set_storage_schema_cache() {
	case "$1" in
	2)
		FSS_STORAGE_SCHEMA_CACHE="2"
		;;
	*)
		FSS_STORAGE_SCHEMA_CACHE="1"
		;;
	esac
	export FSS_STORAGE_SCHEMA_CACHE
}

fss_clear_schema2_migration_notice() {
	dbus remove fss_data_migration_notice
	dbus remove fss_data_migration_time
	dbus remove fss_data_legacy_snapshot
	dbus remove fss_data_migrating
}

fss_mark_native_schema2_storage() {
	local next_id=""
	local max_id=""

	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2 >/dev/null 2>&1 || true
	next_id=$(dbus get fss_node_next_id)
	if [ -z "${next_id}" ];then
		max_id=$(dbus get fss_node_order | tr ',' '\n' | sed '/^$/d' | sort -n | tail -n1)
		[ -n "${max_id}" ] || max_id=0
		dbus set fss_node_next_id="$((max_id + 1))"
	fi
	dbus set fss_data_migrated=1
	fss_clear_schema2_migration_notice
	fss_clear_legacy_nodes >/dev/null 2>&1 || true
}

fss_legacy_node_count() {
	fss_list_legacy_node_indices | sed '/^$/d' | wc -l
}

fss_v2_node_count() {
	local order
	order=$(dbus get fss_node_order)
	[ -z "${order}" ] && {
		echo 0
		return
	}
	printf '%s' "${order}" | tr ',' '\n' | sed '/^$/d' | wc -l
}

fss_kv_lines_to_json() {
	jq -Rs '
		split("\u0000") as $kv
		| reduce range(0; ($kv | length) - 1; 2) as $i ({};
			if ($kv[$i] // "") == "" then
				.
			else
				. + {($kv[$i]): ($kv[$i + 1] // "")}
			end
		)
	'
}

fss_emit_kv_lines() {
	while IFS= read -r line
	do
		[ -z "${line}" ] && continue
		local key=${line%%=*}
		local value=${line#*=}
		printf '%s\0%s\0' "${key}" "${value}"
	done
}

fss_csv_to_json_array() {
	local csv="$1"
	if [ -z "${csv}" ];then
		echo '[]'
		return
	fi
	printf '%s' "${csv}" | tr ',' '\n' | sed '/^$/d' | jq -Rsc 'split("\n") | map(select(length > 0))'
}

fss_mktemp_dir() {
	local prefix="$1"
	local base_dir="/tmp"
	local try path

	[ -n "${prefix}" ] || prefix="fss_tmp"
	if command -v mktemp >/dev/null 2>&1;then
		mktemp -d "${base_dir}/${prefix}.XXXXXX" 2>/dev/null && return 0
	fi

	try=0
	while [ "${try}" -lt 16 ]
	do
		path="${base_dir}/${prefix}.$$.${RANDOM:-0}.${try}"
		if mkdir -p "${path}" 2>/dev/null;then
			echo "${path}"
			return 0
		fi
		try=$((try + 1))
	done

	return 1
}

fss_list_legacy_node_indices() {
	dbus list ssconf_basic_name_ | while IFS= read -r line
	do
		[ -z "${line}" ] && continue
		line=${line%%=*}
		echo "${line}" | sed -n 's/^.*_\([0-9]\+\)$/\1/p'
	done | sort -n
}

fss_clear_v2_nodes() {
	fss_clear_webtest_cache_all
	fss_clear_webtest_runtime_results
	rm -f "${FSS_NODE_DIRECT_CACHE_FILE}" \
		"${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" \
		"${FSS_NODE_DIRECT_RUNTIME_FILE}" \
		"${FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE}" \
		"${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}" \
		"${FSS_NODE_DIRECT_RUNTIME_AIRPORT_DNS_FILE}" \
		"${FSS_NODE_DIRECT_CACHE_META_FILE}" >/dev/null 2>&1
	fss_clear_airport_special_confs >/dev/null 2>&1 || true
	dbus list fss_node_ | while IFS= read -r line
	do
		[ -z "${line}" ] && continue
		dbus remove "${line%%=*}"
	done
	dbus remove fss_node_order
	dbus remove fss_node_current
	dbus remove fss_node_failover_backup
	dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}"
	dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}"
	dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}"
	dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}"
	fss_clear_reference_notice
	dbus remove fss_node_next_id
	dbus remove fss_data_schema
	fss_set_storage_schema_cache 1
	dbus remove fss_data_migrated
	dbus remove fss_data_migration_notice
	dbus remove fss_data_migration_time
	dbus remove fss_data_legacy_snapshot
	dbus remove fss_data_migrating
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
}

fss_clear_legacy_nodes() {
	dbus list ssconf_basic_ | while IFS= read -r line
	do
		[ -z "${line}" ] && continue
		line=${line%%=*}
		echo "${line}" | grep -Eq '_[0-9]+$' || continue
		dbus remove "${line}"
	done
	if [ "$(fss_detect_storage_schema 2>/dev/null)" = "2" ];then
		local current_id=""
		current_id=$(dbus get fss_node_current)
		[ -n "${current_id}" ] && dbus set ssconf_basic_node="${current_id}" || dbus remove ssconf_basic_node
	else
		dbus remove ssconf_basic_node
	fi
}

fss_clear_all_node_storage() {
	fss_clear_legacy_nodes
	fss_clear_v2_nodes
	dbus remove ss_failover_s4_3
}

fss_prepare_migration_state() {
	if [ "$(dbus get fss_data_migrating)" = "1" ] && [ "$(fss_detect_storage_schema)" != "2" ];then
		fss_clear_v2_nodes
	fi
}

fss_migration_snapshot_path() {
	local ts="$1"
	[ -z "${ts}" ] && ts=$(date +%Y%m%d_%H%M%S)
	mkdir -p "${FSS_NODE_MIGRATION_DIR}" >/dev/null 2>&1
	echo "${FSS_NODE_MIGRATION_DIR}/legacy_migration_${ts}.sh"
}

fss_latest_migration_snapshot() {
	set -- "${FSS_NODE_MIGRATION_DIR}"/legacy_migration_[0-9]*_[0-9]*.sh
	[ -e "$1" ] || return 1
	ls -1t "$@" 2>/dev/null | sed -n '1p'
}

fss_resolve_migration_snapshot() {
	local snapshot_path latest_snapshot

	snapshot_path=$(dbus get fss_data_legacy_snapshot)
	if [ -n "${snapshot_path}" ] && [ -f "${snapshot_path}" ];then
		echo "${snapshot_path}"
		return 0
	fi

	latest_snapshot=$(fss_latest_migration_snapshot) || return 1
	[ -n "${latest_snapshot}" ] || return 1
	dbus set fss_data_legacy_snapshot="${latest_snapshot}"
	echo "${latest_snapshot}"
}

fss_prune_migration_snapshots() {
	local keep_count="$1"
	local current_snapshot keep_file keep_sorted entry kept=0

	[ -d "${FSS_NODE_MIGRATION_DIR}" ] || return 0
	[ -n "${keep_count}" ] || keep_count="${FSS_NODE_MIGRATION_KEEP}"
	keep_file="/tmp/fss_migration_keep.$$"
	keep_sorted="${keep_file}.sorted"
	: > "${keep_file}"

	current_snapshot=$(fss_resolve_migration_snapshot 2>/dev/null)
	if [ -n "${current_snapshot}" ] && [ -f "${current_snapshot}" ];then
		echo "${current_snapshot}" >> "${keep_file}"
	fi

	set -- "${FSS_NODE_MIGRATION_DIR}"/legacy_migration_[0-9]*_[0-9]*.sh
	if [ ! -e "$1" ];then
		rm -f "${keep_file}" "${keep_sorted}"
		return 0
	fi

	for entry in $(ls -1t "$@" 2>/dev/null)
	do
		kept=$((kept + 1))
		[ "${kept}" -le "${keep_count}" ] && echo "${entry}" >> "${keep_file}"
	done

	sort -u "${keep_file}" > "${keep_sorted}" 2>/dev/null || cp -f "${keep_file}" "${keep_sorted}"
	for entry in "$@"
	do
		[ -e "${entry}" ] || continue
		grep -Fxq "${entry}" "${keep_sorted}" || rm -f "${entry}"
	done
	rm -f "${keep_file}" "${keep_sorted}"
}

fss_report_progress() {
	local progress_cb="$1"
	shift
	[ -n "${progress_cb}" ] || return 0
	type "${progress_cb}" >/dev/null 2>&1 || return 0
	"${progress_cb}" "$@"
}

fss_create_migration_snapshot() {
	local snapshot_path="$1"
	local progress_cb="$2"
	[ -z "${snapshot_path}" ] && snapshot_path=$(fss_migration_snapshot_path)
	fss_report_progress "${progress_cb}" "阶段1/4：生成旧版兼容快照..."
	fss_export_legacy_backup "${snapshot_path}" || return 1
	fss_prune_migration_snapshots
}

fss_validate_v2_tempdir() {
	local tmp_dir="$1"
	local expected_count="$2"
	local node_id
	local actual_count=0
	local current_id failover_id order_csv

	[ -d "${tmp_dir}" ] || return 1
	[ -f "${tmp_dir}/order" ] || return 1
	order_csv=$(tr '\n' ',' < "${tmp_dir}/order" | sed 's/,$//')
	actual_count=$(printf '%s' "${order_csv}" | tr ',' '\n' | sed '/^$/d' | awk 'END{print NR}')
	[ "${actual_count}" = "${expected_count}" ] || return 1

	current_id=$(cat "${tmp_dir}/current" 2>/dev/null)
	failover_id=$(cat "${tmp_dir}/failover" 2>/dev/null)
	if [ -n "${current_id}" ];then
		printf '%s\n' "${order_csv}" | tr ',' '\n' | grep -Fxq "${current_id}" || return 1
	fi
	if [ -n "${failover_id}" ];then
		printf '%s\n' "${order_csv}" | tr ',' '\n' | grep -Fxq "${failover_id}" || return 1
	fi

	while IFS= read -r node_id
	do
		[ -z "${node_id}" ] && continue
		[ -s "${tmp_dir}/node_${node_id}.json" ] || return 1
		jq -e --arg id "${node_id}" '._schema == 2 and ._id == $id' "${tmp_dir}/node_${node_id}.json" >/dev/null 2>&1 || return 1
		[ -s "${tmp_dir}/node_${node_id}.b64" ] || return 1
	done < "${tmp_dir}/order"

	return 0
}

fss_migrate_legacy_nodes() {
	local remove_legacy="$1"
	local progress_cb="$2"
	local ts snapshot_path
	local tmp_dir expected_count=0 actual_count=0 migrated_nodes=0
	local node_id node_b64 current_id failover_id max_id=0 order_csv=""
	local order_file="" node_dump_file="" nodes_tsv="" source_meta_file="" node_ts=""
	local old_current old_failover
	local node_tool="" node_tool_output="" node_tool_output_file="" node_tool_rc="" migrated_count="" subscribe_nodes="" legacy_keys_removed=""
	local node_tool_attempt=0
	local key value field

	[ "$(fss_detect_storage_schema)" = "2" ] && return 0
	old_current=$(dbus get ssconf_basic_node)
	old_failover=$(dbus get ss_failover_s4_3)
	expected_count=$(fss_legacy_node_count)
	[ "${expected_count}" -gt 0 ] || return 1

	exec 234>"${FSS_NODE_MIGRATION_LOCK}"
	flock -n 234 || return 1

	tmp_dir=$(fss_mktemp_dir fss_migrate)
	ts=$(date +%Y%m%d_%H%M%S)
	snapshot_path=$(fss_migration_snapshot_path "${ts}")
	order_file="${tmp_dir}/order"
	node_dump_file="${tmp_dir}/nodes.dump"
	nodes_tsv="${tmp_dir}/nodes.tsv"
	source_meta_file="${tmp_dir}/legacy_subscribe_sources.tsv"
	dbus set fss_data_migrating=1
	fss_report_progress "${progress_cb}" "节点数据配置升级中，此步耗时可能较长，请耐心等待..."

	if ! fss_create_migration_snapshot "${snapshot_path}" "${progress_cb}"; then
		rm -rf "${tmp_dir}"
		dbus remove fss_data_migrating
		flock -u 234
		return 1
	fi

	fss_collect_legacy_subscribe_source_meta "${source_meta_file}" >/dev/null 2>&1 || : > "${source_meta_file}"
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || node_tool=""
	if [ -n "${node_tool}" ];then
		fss_report_progress "${progress_cb}" "阶段2/4：检测到 node-tool：${node_tool}"
	else
		fss_report_progress "${progress_cb}" "阶段2/4：未检测到可用 node-tool，回退 shell 迁移流程..."
	fi
	if [ -n "${node_tool}" ];then
		fss_report_progress "${progress_cb}" "阶段2/4：使用 node-tool 快速迁移旧版节点数据..."
		fss_clear_v2_nodes >/dev/null 2>&1 || true
		dbus set fss_data_migrating=1
		node_tool_output_file="${tmp_dir}/node_tool_migrate.out"
		while [ "${node_tool_attempt}" -lt 2 ]
		do
			: > "${node_tool_output_file}"
			fss_run_node_tool_with_clean_retry "${node_tool}" "${node_tool_output_file}" migrate-legacy --meta "${source_meta_file}"
			node_tool_rc="$?"
			[ "${node_tool_rc}" != "127" ] && break
			node_tool_attempt=$((node_tool_attempt + 1))
			[ "${node_tool_attempt}" -lt 2 ] || break
			fss_report_progress "${progress_cb}" "node-tool 首次执行返回 127，等待 1 秒后重试..."
			sleep 1
		done
		node_tool_output="$(cat "${node_tool_output_file}" 2>/dev/null)"
		if [ "${node_tool_rc}" = "0" ];then
			migrated_count="$(printf '%s\n' "${node_tool_output}" | awk -F': ' '$1 == "migrated" {print $2}' | sed -n '1p')"
			if [ "${migrated_count}" = "${expected_count}" ];then
				subscribe_nodes="$(printf '%s\n' "${node_tool_output}" | awk -F': ' '$1 == "subscribe_nodes" {print $2}' | sed -n '1p')"
				legacy_keys_removed="$(printf '%s\n' "${node_tool_output}" | awk -F': ' '$1 == "legacy_keys_removed" {print $2}' | sed -n '1p')"
				fss_set_storage_schema_cache 2
				dbus set fss_data_migrated=1
				dbus set fss_data_secret_mode=raw
				dbus set fss_data_migration_tool=node-tool
				if [ "${subscribe_nodes:-0}" -gt 0 ] 2>/dev/null || [ ! -s "${source_meta_file}" ];then
					dbus set fss_data_source_meta_repaired=1
				else
					dbus remove fss_data_source_meta_repaired
				fi
				dbus set fss_data_migration_notice=1
				dbus set fss_data_migration_time="${ts}"
				dbus set fss_data_legacy_snapshot="${snapshot_path}"
				fss_touch_node_catalog_ts >/dev/null 2>&1
				fss_touch_node_config_ts >/dev/null 2>&1
				[ -n "$(dbus get fss_node_current)" ] && dbus set ssconf_basic_node="$(dbus get fss_node_current)" || dbus remove ssconf_basic_node
				[ -n "$(dbus get fss_node_failover_backup)" ] && dbus set ss_failover_s4_3="$(dbus get fss_node_failover_backup)" || dbus remove ss_failover_s4_3
				fss_report_progress "${progress_cb}" "node-tool 快速迁移完成：${migrated_count}/${expected_count} 个节点。"
				[ -n "${subscribe_nodes}" ] && fss_report_progress "${progress_cb}" "node-tool 已写入 ${subscribe_nodes} 个订阅节点来源归属。"
				[ -n "${legacy_keys_removed}" ] && fss_report_progress "${progress_cb}" "node-tool 已清理 ${legacy_keys_removed} 个旧版节点键。"
				if [ "${remove_legacy}" = "1" ] && [ "${legacy_keys_removed:-0}" = "0" ];then
					fss_clear_legacy_nodes
				fi
				dbus remove fss_data_migrating
				rm -rf "${tmp_dir}"
				flock -u 234
				return 0
			fi
			fss_report_progress "${progress_cb}" "node-tool 迁移结果数量异常，回退 shell 迁移流程..."
			printf '%s\n' "${node_tool_output}" | sed -n '1,20p' | while IFS= read -r line
			do
				[ -n "${line}" ] && fss_report_progress "${progress_cb}" "node-tool 输出：${line}"
			done
		else
			fss_report_progress "${progress_cb}" "node-tool 快速迁移失败（退出码 ${node_tool_rc}），回退 shell 迁移流程..."
			printf '%s\n' "${node_tool_output}" | sed -n '1,20p' | while IFS= read -r line
			do
				[ -n "${line}" ] && fss_report_progress "${progress_cb}" "node-tool 输出：${line}"
			done
		fi
	fi

	fss_report_progress "${progress_cb}" "阶段2/4：批量读取旧版节点数据..."
	: > "${order_file}"
	: > "${node_dump_file}"
	dbus list ssconf_basic_ | while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		node_id=""
		key=${line%%=*}
		value=${line#*=}
		case "${key}" in
		ssconf_basic_name_*)
			node_id=${key##*_}
			field=${key#ssconf_basic_}
			field=${field%_"${node_id}"}
			printf '%s\0%s\0%s\0' "${node_id}" "${field}" "${value}" >> "${node_dump_file}"
			printf '%s\n' "${node_id}" >> "${order_file}"
			;;
		ssconf_basic_*_[0-9]*)
			node_id=${key##*_}
			field=${key#ssconf_basic_}
			field=${field%_"${node_id}"}
			printf '%s\0%s\0%s\0' "${node_id}" "${field}" "${value}" >> "${node_dump_file}"
			;;
		esac
	done
	sort -n -u "${order_file}" -o "${order_file}"
	actual_count=$(awk 'END{print NR + 0}' "${order_file}")
	[ "${actual_count}" = "${expected_count}" ] || {
		rm -rf "${tmp_dir}"
		dbus remove fss_data_migrating
		flock -u 234
		return 1
	}

	current_id="${old_current}"
	failover_id="${old_failover}"
	[ -n "${current_id}" ] && grep -Fxq "${current_id}" "${order_file}" || current_id="$(sed -n '1p' "${order_file}")"
	[ -n "${failover_id}" ] && grep -Fxq "${failover_id}" "${order_file}" || failover_id=""

	fss_report_progress "${progress_cb}" "阶段3/4：转换节点到新存储结构，共 ${expected_count} 个节点..."
	node_ts="$(fss_now_ts_ms)"
	fss_legacy_node_dump_to_v2_tsv "${node_dump_file}" "${order_file}" "migration" "${node_ts}" "${source_meta_file}" > "${nodes_tsv}" || {
		rm -rf "${tmp_dir}"
		dbus remove fss_data_migrating
		flock -u 234
		return 1
	}
	actual_count=$(awk 'END{print NR + 0}' "${nodes_tsv}")
	[ "${actual_count}" = "${expected_count}" ] || {
		rm -rf "${tmp_dir}"
		dbus remove fss_data_migrating
		flock -u 234
		return 1
	}

	fss_clear_v2_nodes
	fss_report_progress "${progress_cb}" "阶段4/4：写入新存储结构，共 ${expected_count} 个节点..."
	while IFS='	' read -r node_id node_b64
	do
		[ -z "${node_id}" ] && continue
		[ -n "${node_b64}" ] || continue
		dbus set "fss_node_${node_id}=${node_b64}"
		migrated_nodes=$((migrated_nodes + 1))
		if [ "${node_id}" -gt "${max_id}" ] 2>/dev/null;then
			max_id="${node_id}"
		fi
		if [ "${migrated_nodes}" = "1" ] || [ $((migrated_nodes % 20)) -eq 0 ] || [ "${migrated_nodes}" = "${expected_count}" ];then
			fss_report_progress "${progress_cb}" "节点数据升级进度：${migrated_nodes}/${expected_count}"
		fi
	done < "${nodes_tsv}"
	[ "${migrated_nodes}" = "${expected_count}" ] || {
		rm -rf "${tmp_dir}"
		dbus remove fss_data_migrating
		flock -u 234
		return 1
	}

	order_csv=$(tr '\n' ',' < "${order_file}" | sed 's/,$//')
	dbus set fss_node_order="${order_csv}"
	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2
	fss_set_current_node_id "${current_id}"
	fss_set_failover_node_id "${failover_id}"
	dbus set fss_node_next_id="$((max_id + 1))"
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	dbus set fss_data_migrated=1
	dbus set fss_data_secret_mode=raw
	dbus set fss_data_migration_tool=shell
	dbus set fss_data_migration_notice=1
	dbus set fss_data_migration_time="${ts}"
	dbus set fss_data_legacy_snapshot="${snapshot_path}"

	if [ "${remove_legacy}" = "1" ];then
		fss_clear_legacy_nodes
	fi

	dbus remove fss_data_migrating
	rm -rf "${tmp_dir}"
	flock -u 234
	return 0
}

fss_auto_migrate_if_needed() {
	local remove_legacy="$1"
	local progress_cb="$2"
	local legacy_count=0

	[ -n "${remove_legacy}" ] || remove_legacy=1
	fss_prepare_migration_state
	[ "$(fss_detect_storage_schema)" = "2" ] && return 0

	legacy_count=$(fss_legacy_node_count)
	[ "${legacy_count}" -gt 0 ] || return 2

	fss_migrate_legacy_nodes "${remove_legacy}" "${progress_cb}" || return 1
	if [ "${remove_legacy}" = "1" ] && [ "$(fss_legacy_node_count)" -gt 0 ];then
		fss_clear_legacy_nodes
	fi
	return 0
}

fss_build_legacy_node_json() {
	local node_index="$1"
	local dump_file="$2"

	if [ -n "${dump_file}" ] && [ -f "${dump_file}" ];then
		while IFS= read -r line
		do
			local key=${line%%=*}
			local value=${line#*=}
			case "${key}" in
			ssconf_basic_*_"${node_index}")
				key=${key#ssconf_basic_}
				key=${key%_"${node_index}"}
				[ -z "${value}" ] && continue
				printf '%s\0%s\0' "${key}" "${value}"
				;;
			esac
		done < "${dump_file}" | fss_kv_lines_to_json
	else
		dbus list ssconf_basic_ | while IFS= read -r line
		do
			local key=${line%%=*}
			local value=${line#*=}
			case "${key}" in
			ssconf_basic_*_"${node_index}")
				key=${key#ssconf_basic_}
				key=${key%_"${node_index}"}
				[ -z "${value}" ] && continue
				printf '%s\0%s\0' "${key}" "${value}"
				;;
			esac
		done | fss_kv_lines_to_json
	fi
}

fss_capture_legacy_backup_sh() {
	local script_file="$1"
	local output_file="$2"

	[ -f "${script_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	: > "${output_file}"

	(
		_FSS_RESTORE_CAPTURE_OUT="${output_file}"
		dbus() {
			[ "$1" = "set" ] || return 0
			[ -n "$2" ] || return 0
			printf '%s\n' "$2" >> "${_FSS_RESTORE_CAPTURE_OUT}"
		}
		. "${script_file}"
	) >/dev/null 2>&1
}

fss_legacy_node_dump_to_v2_tsv() {
	local dump_file="$1"
	local order_file="$2"
	local source="$3"
	local node_ts="$4"
	local source_meta_file="$5"
	local source_meta_tmp=""

	[ -f "${dump_file}" ] || return 1
	[ -f "${order_file}" ] || return 1
	[ -n "${source}" ] || source="legacy"
	[ -n "${node_ts}" ] || node_ts="$(fss_now_ts_ms)"
	if [ -z "${source_meta_file}" ] || [ ! -f "${source_meta_file}" ];then
		source_meta_tmp="/tmp/.fss_legacy_source_meta.$$"
		: > "${source_meta_tmp}"
		source_meta_file="${source_meta_tmp}"
	fi

	jq -Rnrc \
		--rawfile dump "${dump_file}" \
		--rawfile order "${order_file}" \
		--rawfile source_meta "${source_meta_file}" \
		--arg source "${source}" \
		--argjson updated_at "${node_ts}" \
		'
		def valid_ids:
			$order | split("\n") | map(select(length > 0));
		def slugify($raw; $fallback):
			($raw | tostring | ascii_downcase | gsub("[^a-z0-9]+"; "_") | gsub("^_+|_+$"; "")) as $slug
			| if $slug == "" then $fallback else $slug end;
		def source_meta_rows:
			$source_meta
			| split("\n")
			| map(select(length > 0))
			| map(split("\t"))
			| map(select(length >= 6 and .[0] != "")
				| {
					tag: .[0],
					profile_id: .[1],
					airport_identity: .[2],
					source_scope: .[3],
					url_hash: .[4],
					group_label: .[5]
				});
		def source_meta_by_tag:
			source_meta_rows | map({key: .tag, value: .}) | from_entries;
		def source_meta_by_group($group_label):
			[source_meta_rows[] | select(.group_label == $group_label)]
			| unique_by((.profile_id // "") + "\t" + (.source_scope // "")) as $matches
			| if ($matches | length) == 1 then $matches[0] else null end;
		def subscription_meta($group):
			($group // "" | tostring) as $raw_group
			| (source_meta_by_group($raw_group)) as $direct_meta
			| if $direct_meta != null then
				($direct_meta.group_label // $raw_group) as $group_label_jq
				| ($direct_meta.url_hash // "") as $url_hash
				| ($direct_meta.airport_identity // slugify($group_label_jq; ($direct_meta.tag // "sub"))) as $airport_identity
				| ($direct_meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
				| {
					"_source": "subscribe",
					"_profile_id": ($direct_meta.profile_id // ""),
					"_airport_identity": $airport_identity,
					"_source_scope": $source_scope,
					"_source_url_hash": $url_hash
				}
			elif ($raw_group | test("_[A-Za-z0-9]+$")) then
				($raw_group | capture("^(?<base>.*)_(?<tag>[A-Za-z0-9]+)$")) as $parts
				| (source_meta_by_tag[$parts.tag] // null) as $tag_meta
				| (($tag_meta // null) // source_meta_by_group($parts.base)) as $meta
				| if $meta == null or ($tag_meta == null and (($meta.group_label // "") != "" and $parts.base != ($meta.group_label // ""))) then
					null
				else
					($meta.group_label // $parts.base) as $group_label_jq
					| ($meta.url_hash // "") as $url_hash
					| ($meta.airport_identity // slugify($group_label_jq; $parts.tag)) as $airport_identity
					| ($meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
					| {
						"_source": "subscribe",
						"_profile_id": ($meta.profile_id // ""),
						"_airport_identity": $airport_identity,
						"_source_scope": $source_scope,
						"_source_url_hash": $url_hash
					}
				end
			else
				null
			end;
		def keep_common($k):
			$k == "group"
			or $k == "name"
			or $k == "mode"
			or $k == "type";
		def keep_type($type; $k):
			if $type == "0" then
				$k == "server" or $k == "port" or $k == "method" or $k == "password" or $k == "ss_obfs" or $k == "ss_obfs_host"
			elif $type == "1" then
				$k == "server" or $k == "port" or $k == "method" or $k == "password" or $k == "rss_protocol" or $k == "rss_protocol_param" or $k == "rss_obfs" or $k == "rss_obfs_param"
			elif $type == "3" then
				$k == "server" or $k == "port" or $k == "v2ray_uuid" or $k == "v2ray_alterid" or $k == "v2ray_security" or $k == "v2ray_network" or $k == "v2ray_headtype_tcp" or $k == "v2ray_headtype_kcp" or $k == "v2ray_kcp_seed" or $k == "v2ray_headtype_quic" or $k == "v2ray_grpc_mode" or $k == "v2ray_grpc_authority" or $k == "v2ray_network_path" or $k == "v2ray_network_host" or $k == "v2ray_network_security" or $k == "v2ray_network_security_ai" or $k == "v2ray_network_security_alpn_h2" or $k == "v2ray_network_security_alpn_http" or $k == "v2ray_network_security_sni" or $k == "v2ray_mux_concurrency" or $k == "v2ray_json" or $k == "v2ray_use_json" or $k == "v2ray_mux_enable"
			elif $type == "4" then
				$k == "server" or $k == "port" or $k == "xray_uuid" or $k == "xray_alterid" or $k == "xray_prot" or $k == "xray_encryption" or $k == "xray_flow" or $k == "xray_network" or $k == "xray_headtype_tcp" or $k == "xray_headtype_kcp" or $k == "xray_kcp_seed" or $k == "xray_headtype_quic" or $k == "xray_grpc_mode" or $k == "xray_grpc_authority" or $k == "xray_xhttp_mode" or $k == "xray_network_path" or $k == "xray_network_host" or $k == "xray_network_security" or $k == "xray_network_security_ai" or $k == "xray_network_security_alpn_h2" or $k == "xray_network_security_alpn_http" or $k == "xray_network_security_sni" or $k == "xray_pcs" or $k == "xray_vcn" or $k == "xray_fingerprint" or $k == "xray_publickey" or $k == "xray_shortid" or $k == "xray_spiderx" or $k == "xray_show" or $k == "xray_json" or $k == "xray_use_json"
			elif $type == "5" then
				$k == "server" or $k == "port" or $k == "trojan_ai" or $k == "trojan_uuid" or $k == "trojan_sni" or $k == "trojan_pcs" or $k == "trojan_vcn" or $k == "trojan_tfo" or $k == "trojan_plugin" or $k == "trojan_obfs" or $k == "trojan_obfshost" or $k == "trojan_obfsuri"
			elif $type == "6" then
				$k == "naive_prot" or $k == "naive_server" or $k == "naive_port" or $k == "naive_user" or $k == "naive_pass"
			elif $type == "7" then
				$k == "tuic_json"
			elif $type == "8" then
				$k == "hy2_server" or $k == "hy2_port" or $k == "hy2_pass" or $k == "hy2_up" or $k == "hy2_dl" or $k == "hy2_obfs" or $k == "hy2_obfs_pass" or $k == "hy2_sni" or $k == "hy2_pcs" or $k == "hy2_vcn" or $k == "hy2_ai" or $k == "hy2_tfo" or $k == "hy2_cg"
			elif $type == "9" then
				$k == "anytls_server" or $k == "anytls_port" or $k == "anytls_pass" or $k == "anytls_sni" or $k == "anytls_ai"
			else
				false
			end;
		def prune:
			. as $root
			| (($root.type // "") | tostring) as $type
			| with_entries(select((.key | startswith("_")) or keep_common(.key) or keep_type($type; .key)));
		def is_b64_field($key):
			$key == "password"
			or $key == "naive_pass"
			or $key == "v2ray_json"
			or $key == "xray_json"
			or $key == "tuic_json";
		def decode_value($key; $value):
			if is_b64_field($key) and ($value != "" and $value != null) then
				try ($value | @base64d) catch $value
			else
				$value
			end;
		def bool_value($value):
			if $value == "1" then "1" else "0" end;
		def default_empty_fields:
			(.type // "" | tostring) as $type
			| .mode = (if ((.mode // "") == "") then "2" else .mode end)
			| if $type == "0" then
				.ss_obfs = (if ((.ss_obfs // "") == "") then "0" else .ss_obfs end)
			elif $type == "1" then
				.rss_protocol = (if ((.rss_protocol // "") == "") then "origin" else .rss_protocol end)
				| .rss_obfs = (if ((.rss_obfs // "") == "") then "plain" else .rss_obfs end)
			elif $type == "3" then
				.v2ray_alterid = (if ((.v2ray_alterid // "") == "") then "0" else .v2ray_alterid end)
				| .v2ray_security = (if ((.v2ray_security // "") == "") then "auto" else .v2ray_security end)
				| .v2ray_network = (if ((.v2ray_network // "") == "") then "tcp" else .v2ray_network end)
				| .v2ray_headtype_tcp = (if ((.v2ray_headtype_tcp // "") == "") then "none" else .v2ray_headtype_tcp end)
				| .v2ray_headtype_kcp = (if ((.v2ray_headtype_kcp // "") == "") then "none" else .v2ray_headtype_kcp end)
				| .v2ray_headtype_quic = (if ((.v2ray_headtype_quic // "") == "") then "none" else .v2ray_headtype_quic end)
				| .v2ray_grpc_mode = (if ((.v2ray_grpc_mode // "") == "") then "multi" else .v2ray_grpc_mode end)
				| .v2ray_network_security = (if ((.v2ray_network_security // "") == "") then "none" else .v2ray_network_security end)
			elif $type == "4" then
				.xray_alterid = (if ((.xray_alterid // "") == "") then "0" else .xray_alterid end)
				| .xray_encryption = (if ((.xray_encryption // "") == "") then "none" else .xray_encryption end)
				| .xray_network = (if ((.xray_network // "") == "") then "tcp" else .xray_network end)
				| .xray_headtype_tcp = (if ((.xray_headtype_tcp // "") == "") then "none" else .xray_headtype_tcp end)
				| .xray_headtype_kcp = (if ((.xray_headtype_kcp // "") == "") then "none" else .xray_headtype_kcp end)
				| .xray_headtype_quic = (if ((.xray_headtype_quic // "") == "") then "none" else .xray_headtype_quic end)
				| .xray_grpc_mode = (if ((.xray_grpc_mode // "") == "") then "gun" else .xray_grpc_mode end)
				| .xray_xhttp_mode = (if ((.xray_xhttp_mode // "") == "") then "auto" else .xray_xhttp_mode end)
				| .xray_network_security = (if ((.xray_network_security // "") == "") then "none" else .xray_network_security end)
			elif $type == "6" then
				.naive_prot = (if ((.naive_prot // "") == "") then "https" else .naive_prot end)
			elif $type == "8" then
				.hy2_obfs = (if ((.hy2_obfs // "") == "") then "0" else .hy2_obfs end)
			else
				.
			end;
		($dump | split("\u0000")) as $items
		| (valid_ids) as $valid
		| reduce range(0; ($items | length) - 2; 3) as $i ({};
			($items[$i] // "") as $id
			| ($items[$i + 1] // "") as $key
			| ($items[$i + 2] // "") as $value
			| if $id == "" or $key == "" or (($valid | index($id)) == null) then
				.
			else
				.[$id] = ((.[$id] // {}) + {($key): decode_value($key; $value)})
			end
		)
		| to_entries[]
		| . as $entry
		| (
			$entry.value
			| .v2ray_use_json = bool_value(.v2ray_use_json // "")
			| .v2ray_mux_enable = bool_value(.v2ray_mux_enable // "")
			| .v2ray_network_security_ai = bool_value(.v2ray_network_security_ai // "")
			| .v2ray_network_security_alpn_h2 = bool_value(.v2ray_network_security_alpn_h2 // "")
			| .v2ray_network_security_alpn_http = bool_value(.v2ray_network_security_alpn_http // "")
			| .xray_use_json = bool_value(.xray_use_json // "")
			| .xray_network_security_ai = bool_value(.xray_network_security_ai // "")
			| .xray_network_security_alpn_h2 = bool_value(.xray_network_security_alpn_h2 // "")
			| .xray_network_security_alpn_http = bool_value(.xray_network_security_alpn_http // "")
			| .xray_show = bool_value(.xray_show // "")
			| .trojan_ai = bool_value(.trojan_ai // "")
			| .trojan_tfo = bool_value(.trojan_tfo // "")
			| .hy2_ai = bool_value(.hy2_ai // "")
			| .hy2_tfo = bool_value(.hy2_tfo // "")
			| .anytls_ai = bool_value(.anytls_ai // "")
			| with_entries(select(.value != "" and .value != null))
			| del(.server_ip, .latency, .ping)
			| default_empty_fields
			| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end
			| (subscription_meta(.group) // {}) as $sub_meta
			| . + {
				"_schema": 2,
				"_id": $entry.key,
				"_rev": 1,
				"_b64_mode": "raw",
				"_source": ($sub_meta._source // $source),
				"_updated_at": $updated_at,
				"_created_at": $updated_at,
				"_migrated_from": $entry.key
			} + $sub_meta
			| prune
		) as $node
		| [$entry.key, ($node | @base64)] | @tsv
		'
	local rc=$?
	[ -n "${source_meta_tmp}" ] && rm -f "${source_meta_tmp}"
	return ${rc}
}

fss_node_legacy_to_v2_json() {
	local node_index="$1"
	local node_id="$2"
	local source="$3"
	local dump_file="$4"
	local node_json=""
	local node_ts="$(fss_now_ts_ms)"
	local source_meta_file="/tmp/.fss_legacy_source_meta_single.$$"
	local key value

	[ -z "${node_id}" ] && node_id="${node_index}"
	[ -z "${source}" ] && source="legacy"
	if [ -n "${dump_file}" ] && [ -f "${dump_file}" ];then
		node_json=$(
			while IFS= read -r line
			do
				key=${line%%=*}
				value=${line#*=}
				case "${key}" in
				ssconf_basic_*_"${node_index}")
					key=${key#ssconf_basic_}
					key=${key%_"${node_index}"}
					[ -z "${value}" ] && continue
					if fss_is_b64_field "${key}"; then
						value=$(fss_b64_decode "${value}")
					fi
					if fss_is_bool_field "${key}"; then
						[ "${value}" = "1" ] && value="1" || value="0"
					fi
					printf '%s\0%s\0' "${key}" "${value}"
					;;
				esac
			done < "${dump_file}" | fss_kv_lines_to_json
		)
		else
			node_json=$(fss_build_legacy_node_json "${node_index}" "${dump_file}")
			node_json=$(printf '%s' "${node_json}" | jq -c '
				with_entries(
					if (
						(
							.key == "password"
							or .key == "naive_pass"
							or .key == "v2ray_json"
							or .key == "xray_json"
							or .key == "tuic_json"
						)
						and (.value != "" and .value != null)
					)
					then . as $entry | .value = (try (.value | @base64d) catch $entry.value)
					else .
					end
				)
				| .v2ray_use_json = (if .v2ray_use_json == "1" then "1" else "0" end)
			| .v2ray_mux_enable = (if .v2ray_mux_enable == "1" then "1" else "0" end)
			| .v2ray_network_security_ai = (if .v2ray_network_security_ai == "1" then "1" else "0" end)
			| .v2ray_network_security_alpn_h2 = (if .v2ray_network_security_alpn_h2 == "1" then "1" else "0" end)
			| .v2ray_network_security_alpn_http = (if .v2ray_network_security_alpn_http == "1" then "1" else "0" end)
			| .xray_use_json = (if .xray_use_json == "1" then "1" else "0" end)
			| .xray_network_security_ai = (if .xray_network_security_ai == "1" then "1" else "0" end)
			| .xray_network_security_alpn_h2 = (if .xray_network_security_alpn_h2 == "1" then "1" else "0" end)
			| .xray_network_security_alpn_http = (if .xray_network_security_alpn_http == "1" then "1" else "0" end)
			| .xray_show = (if .xray_show == "1" then "1" else "0" end)
			| .trojan_ai = (if .trojan_ai == "1" then "1" else "0" end)
			| .trojan_tfo = (if .trojan_tfo == "1" then "1" else "0" end)
			| .hy2_ai = (if .hy2_ai == "1" then "1" else "0" end)
			| .hy2_tfo = (if .hy2_tfo == "1" then "1" else "0" end)
			| .anytls_ai = (if .anytls_ai == "1" then "1" else "0" end)
		')
	fi

	fss_collect_legacy_subscribe_source_meta "${source_meta_file}" >/dev/null 2>&1 || : > "${source_meta_file}"
	printf '%s' "${node_json}" | jq -c \
		--rawfile source_meta "${source_meta_file}" \
		--arg id "${node_id}" \
		--arg source "${source}" \
		--arg migrated_from "${node_index}" \
		--argjson updated_at "${node_ts}" \
		'
		def default_empty_fields:
			(.type // "" | tostring) as $type
			| .mode = (if ((.mode // "") == "") then "2" else .mode end)
			| if $type == "0" then
				.ss_obfs = (if ((.ss_obfs // "") == "") then "0" else .ss_obfs end)
			elif $type == "1" then
				.rss_protocol = (if ((.rss_protocol // "") == "") then "origin" else .rss_protocol end)
				| .rss_obfs = (if ((.rss_obfs // "") == "") then "plain" else .rss_obfs end)
			elif $type == "3" then
				.v2ray_alterid = (if ((.v2ray_alterid // "") == "") then "0" else .v2ray_alterid end)
				| .v2ray_security = (if ((.v2ray_security // "") == "") then "auto" else .v2ray_security end)
				| .v2ray_network = (if ((.v2ray_network // "") == "") then "tcp" else .v2ray_network end)
				| .v2ray_headtype_tcp = (if ((.v2ray_headtype_tcp // "") == "") then "none" else .v2ray_headtype_tcp end)
				| .v2ray_headtype_kcp = (if ((.v2ray_headtype_kcp // "") == "") then "none" else .v2ray_headtype_kcp end)
				| .v2ray_headtype_quic = (if ((.v2ray_headtype_quic // "") == "") then "none" else .v2ray_headtype_quic end)
				| .v2ray_grpc_mode = (if ((.v2ray_grpc_mode // "") == "") then "multi" else .v2ray_grpc_mode end)
				| .v2ray_network_security = (if ((.v2ray_network_security // "") == "") then "none" else .v2ray_network_security end)
			elif $type == "4" then
				.xray_alterid = (if ((.xray_alterid // "") == "") then "0" else .xray_alterid end)
				| .xray_encryption = (if ((.xray_encryption // "") == "") then "none" else .xray_encryption end)
				| .xray_network = (if ((.xray_network // "") == "") then "tcp" else .xray_network end)
				| .xray_headtype_tcp = (if ((.xray_headtype_tcp // "") == "") then "none" else .xray_headtype_tcp end)
				| .xray_headtype_kcp = (if ((.xray_headtype_kcp // "") == "") then "none" else .xray_headtype_kcp end)
				| .xray_headtype_quic = (if ((.xray_headtype_quic // "") == "") then "none" else .xray_headtype_quic end)
				| .xray_grpc_mode = (if ((.xray_grpc_mode // "") == "") then "gun" else .xray_grpc_mode end)
				| .xray_xhttp_mode = (if ((.xray_xhttp_mode // "") == "") then "auto" else .xray_xhttp_mode end)
				| .xray_network_security = (if ((.xray_network_security // "") == "") then "none" else .xray_network_security end)
			elif $type == "6" then
				.naive_prot = (if ((.naive_prot // "") == "") then "https" else .naive_prot end)
			elif $type == "8" then
				.hy2_obfs = (if ((.hy2_obfs // "") == "") then "0" else .hy2_obfs end)
			else
				.
			end;
		def slugify($raw; $fallback):
			($raw | tostring | ascii_downcase | gsub("[^a-z0-9]+"; "_") | gsub("^_+|_+$"; "")) as $slug
			| if $slug == "" then $fallback else $slug end;
		def source_meta_by_tag:
			$source_meta
			| split("\n")
			| map(select(length > 0))
			| map(split("\t"))
			| map(select(length >= 6 and .[0] != "")
				| {
					tag: .[0],
					profile_id: .[1],
					airport_identity: .[2],
					source_scope: .[3],
					url_hash: .[4],
					group_label: .[5]
				})
			| map({key: .tag, value: .})
			| from_entries;
		def source_meta_by_group($group_label):
			[
				$source_meta
				| split("\n")
				| map(select(length > 0))
				| map(split("\t"))
				| map(select(length >= 6 and .[5] == $group_label)
					| {
						tag: .[0],
						profile_id: .[1],
						airport_identity: .[2],
						source_scope: .[3],
						url_hash: .[4],
						group_label: .[5]
					})
				| unique_by((.profile_id // "") + "\t" + (.source_scope // ""))
				| .[]
			] as $matches
			| if ($matches | length) == 1 then $matches[0] else null end;
		def subscription_meta($group):
			($group // "" | tostring) as $raw_group
			| (source_meta_by_group($raw_group)) as $direct_meta
			| if $direct_meta != null then
				($direct_meta.group_label // $raw_group) as $group_label_jq
				| ($direct_meta.url_hash // "") as $url_hash
				| ($direct_meta.airport_identity // slugify($group_label_jq; ($direct_meta.tag // "sub"))) as $airport_identity
				| ($direct_meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
				| {
					"_source": "subscribe",
					"_profile_id": ($direct_meta.profile_id // ""),
					"_airport_identity": $airport_identity,
					"_source_scope": $source_scope,
					"_source_url_hash": $url_hash
				}
			elif ($raw_group | test("_[A-Za-z0-9]+$")) then
				($raw_group | capture("^(?<base>.*)_(?<tag>[A-Za-z0-9]+)$")) as $parts
				| (source_meta_by_tag[$parts.tag] // null) as $tag_meta
				| (($tag_meta // null) // source_meta_by_group($parts.base)) as $meta
				| if $meta == null or ($tag_meta == null and (($meta.group_label // "") != "" and $parts.base != ($meta.group_label // ""))) then
					null
				else
					($meta.group_label // $parts.base) as $group_label_jq
					| ($meta.url_hash // "") as $url_hash
					| ($meta.airport_identity // slugify($group_label_jq; $parts.tag)) as $airport_identity
					| ($meta.source_scope // ($airport_identity + (if $url_hash == "" then "" else "_" + $url_hash end))) as $source_scope
					| {
						"_source": "subscribe",
						"_profile_id": ($meta.profile_id // ""),
						"_airport_identity": $airport_identity,
						"_source_scope": $source_scope,
						"_source_url_hash": $url_hash
					}
				end
			else
				null
			end;
		with_entries(select(.value != "" and .value != null))
		| del(.server_ip, .latency, .ping)
		| default_empty_fields
		| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end
		'"${jq_bool_fix}"'
		| (subscription_meta(.group) // {}) as $sub_meta
		| . + {
			"_schema": 2,
			"_id": $id,
			"_rev": 1,
			"_b64_mode": "raw",
			"_source": ($sub_meta._source // $source),
			"_updated_at": $updated_at,
			"_created_at": $updated_at,
			"_migrated_from": $migrated_from
		} + $sub_meta
		' | fss_prune_node_json
	local rc=$?
	rm -f "${source_meta_file}"
	return ${rc}
}

fss_compact_json_value() {
	printf '%s' "$1" | jq -c . 2>/dev/null || printf '%s' "$1"
}

fss_node_v2_to_legacy_script_lines() {
	local node_index="$1"
	local node_json

	node_json=$(cat)
	[ -z "${node_json}" ] && return 0

	printf '%s' "${node_json}" | jq -r --arg idx "${node_index}" '
		def is_runtime: . == "server_ip" or . == "latency" or . == "ping";
		def is_bool: . == "v2ray_use_json" or . == "v2ray_mux_enable" or . == "v2ray_network_security_ai" or . == "v2ray_network_security_alpn_h2" or . == "v2ray_network_security_alpn_http" or . == "xray_use_json" or . == "xray_network_security_ai" or . == "xray_network_security_alpn_h2" or . == "xray_network_security_alpn_http" or . == "xray_show" or . == "trojan_ai" or . == "trojan_tfo" or . == "hy2_ai" or . == "hy2_tfo" or . == "anytls_ai";
		def is_b64: . == "password" or . == "naive_pass" or . == "v2ray_json" or . == "xray_json" or . == "tuic_json";
		def need_compact_json: . == "v2ray_json" or . == "xray_json" or . == "tuic_json";
		def compact_json_string: try (fromjson | tojson) catch .;
		to_entries[]
		| select(.key | startswith("_") | not)
		| select(.key | is_runtime | not)
		| .key as $k
		| (.value | if type == "string" then . else tostring end) as $v0
		| select($v0 != "")
		| select(($k | is_bool | not) or $v0 == "1")
		| (
			if ($k | is_b64) then
				(if ($k | need_compact_json) then ($v0 | compact_json_string) else $v0 end) | @base64
			else
				$v0
			end
		  ) as $v
		| "dbus set ssconf_basic_\($k)_\($idx)=\($v | @sh)"
	'
}

fss_export_global_json() {
	dbus list ss | grep -v '^ssconf_basic_' | grep -v '^ss_acl_' | grep -v '^ssid_' | grep -v '^ss_failover_s4_3=' | fss_emit_kv_lines | fss_kv_lines_to_json
}

fss_export_acl_json() {
	local acl_default_ports=""
	acl_default_ports=$(fss_get_acl_default_ports_value)
	{
		dbus list ss_acl_ | grep -v '^ss_acl_default_port=' | grep -v '^ss_acl_default_ports='
		[ -n "${acl_default_ports}" ] && printf 'ss_acl_default_ports=%s\n' "${acl_default_ports}"
	} | fss_emit_kv_lines | fss_kv_lines_to_json
}

fss_clear_global_config_storage() {
	dbus list ss 2>/dev/null | cut -d "=" -f 1 | grep -v '^ssconf_basic_' | grep -v '^ss_acl_' | grep -v '^ssid_' | grep -v '^ss_failover_s4_3$' | while IFS= read -r key
	do
		[ -n "${key}" ] || continue
		dbus remove "${key}"
	done
}

fss_clear_acl_config_storage() {
	dbus list ss_acl_ 2>/dev/null | cut -d "=" -f 1 | while IFS= read -r key
	do
		[ -n "${key}" ] || continue
		dbus remove "${key}"
	done
}

fss_clear_global_and_acl_storage() {
	fss_clear_global_config_storage
	fss_clear_acl_config_storage
	fss_cleanup_acl_default_port_keys >/dev/null 2>&1
}

fss_node_json_has_identity_meta() {
	local node_json="$1"
	[ -n "${node_json}" ] || return 1
	case "${node_json}" in
	*'"_identity"'*)
		;;
	*)
		return 1
		;;
	esac
	case "${node_json}" in
	*'"_source"'*)
		;;
	*)
		return 1
		;;
	esac
	case "${node_json}" in
	*'"_airport_identity"'*)
		;;
	*)
		return 1
		;;
	esac
	case "${node_json}" in
	*'"_source_scope"'*)
		;;
	*)
		return 1
		;;
	esac
	return 0
}

fss_node_json_simple_value() {
	local node_json="$1"
	local field="$2"
	local value=""
	[ -n "${node_json}" ] || return 1
	[ -n "${field}" ] || return 1
	value="$(printf '%s' "${node_json}" | sed -n 's/.*"'"${field}"'"[[:space:]]*:[[:space:]]*"\([^"\\]*\)".*/\1/p' | sed -n '1p')"
	if [ -z "${value}" ];then
		value="$(printf '%s' "${node_json}" | sed -n 's/.*"'"${field}"'"[[:space:]]*:[[:space:]]*\([^,}][^,}]*\).*/\1/p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed -n '1p')"
	fi
	printf '%s' "${value}"
}

fss_v2_get_node_json_by_id() {
	local node_id="$1"
	local blob=""
	local node_json=""
	local enriched_json=""
	blob=$(dbus get fss_node_${node_id})
	[ -z "${blob}" ] && return 1
	node_json="$(fss_b64_decode "${blob}")" || return 1
	[ -n "${node_json}" ] || return 1
	if fss_node_json_has_identity_meta "${node_json}"; then
		printf '%s' "${node_json}"
		return 0
	fi
	enriched_json="$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null)" || return 1
	if [ -n "${enriched_json}" ] && [ "${enriched_json}" != "${node_json}" ]; then
		dbus set fss_node_${node_id}="$(fss_b64_encode "${enriched_json}")" >/dev/null 2>&1 || true
	fi
	printf '%s' "${enriched_json:-${node_json}}"
}

fss_dump_v2_node_json_dir() {
	local output_dir="$1"
	local line key value node_id

	[ -n "${output_dir}" ] || return 1
	mkdir -p "${output_dir}" || return 1
	dbus list fss_node_ 2>/dev/null | while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		key=${line%%=*}
		value=${line#*=}
		case "${key}" in
		fss_node_[0-9]*)
			node_id=${key#fss_node_}
			printf '%s' "${node_id}" | grep -Eq '^[0-9]+$' || continue
			fss_b64_decode "${value}" > "${output_dir}/${node_id}.json" 2>/dev/null || {
				return 1
			}
			;;
		esac
	done
}

fss_list_node_ids() {
	local schema
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		printf '%s\n' "$(dbus get fss_node_order)" | tr ',' '\n' | sed '/^$/d'
	else
		fss_list_legacy_node_indices
	fi
}

fss_get_node_count() {
	fss_list_node_ids | sed '/^$/d' | wc -l
}

fss_get_first_node_id() {
	local schema=""
	local order=""

	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		order="$(dbus get fss_node_order)"
		[ -n "${order}" ] || return 1
		printf '%s\n' "${order%%,*}"
		return 0
	fi
	fss_list_node_ids | sed -n '1p'
}

fss_node_id_exists() {
	local node_id="$1"
	local schema=""
	local blob=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		printf '%s' "${node_id}" | grep -Eq '^[0-9]+$' || return 1
		blob="$(dbus get fss_node_${node_id})"
		[ -n "${blob}" ]
		return $?
	fi
	fss_list_node_ids | grep -Fxq "${node_id}"
}

fss_resolve_reference_node_id() {
	local node_id="$1"
	local node_identity="$2"
	local allow_blank="$3"
	local resolved_id=""

	[ -n "${allow_blank}" ] || allow_blank="0"
	if [ -n "${node_id}" ] && fss_node_id_exists "${node_id}"; then
		printf '%s' "${node_id}"
		return 0
	fi
	if [ -n "${node_identity}" ]; then
		resolved_id=$(fss_find_node_id_by_identity "${node_identity}" 2>/dev/null)
		if [ -n "${resolved_id}" ]; then
			printf '%s' "${resolved_id}"
			return 0
		fi
	fi
	if [ "${allow_blank}" = "1" ]; then
		return 1
	fi
	resolved_id=$(fss_get_first_node_id)
	[ -n "${resolved_id}" ] || return 1
	printf '%s' "${resolved_id}"
}

fss_set_schema2_reference_node_id() {
	local id_key="$1"
	local identity_key="$2"
	local node_id="$3"
	local node_identity=""

	[ -n "${id_key}" ] || return 1
	[ -n "${identity_key}" ] || return 1
	if [ -n "${node_id}" ]; then
		if ! fss_node_id_exists "${node_id}"; then
			dbus remove "${id_key}"
			dbus remove "${identity_key}"
			case "${identity_key}" in
			"${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			"${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			esac
			return 0
		fi
		dbus set "${id_key}=${node_id}"
		node_identity=$(fss_get_node_identity_by_id "${node_id}" 2>/dev/null)
		if [ -n "${node_identity}" ]; then
			dbus set "${identity_key}=${node_identity}"
			case "${identity_key}" in
			"${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			"${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			esac
		else
			dbus remove "${identity_key}"
			case "${identity_key}" in
			"${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			"${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}")
				dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}"
				;;
			esac
		fi
	else
		dbus remove "${id_key}"
		dbus remove "${identity_key}"
		case "${identity_key}" in
		"${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}")
			dbus remove "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}"
			;;
		"${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}")
			dbus remove "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}"
			;;
		esac
	fi
}

fss_resolve_current_node_id() {
	local schema current_id current_identity resolved_id
	FSS_CURRENT_NODE_ID_RESULT=""
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		current_id=$(dbus get fss_node_current)
		if [ -n "${current_id}" ] && fss_node_id_exists "${current_id}"; then
			FSS_CURRENT_NODE_ID_RESULT="${current_id}"
			return 0
		fi
		current_identity=$(dbus get "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}")
		[ -n "${current_identity}" ] || current_identity=$(dbus get "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY_LEGACY}")
		resolved_id=$(fss_resolve_reference_node_id "${current_id}" "${current_identity}" "0" 2>/dev/null)
		[ -n "${resolved_id}" ] || resolved_id=$(fss_get_first_node_id)
		if [ -n "${resolved_id}" ] && [ "${resolved_id}" != "${current_id}" ]; then
			fss_set_schema2_reference_node_id "fss_node_current" "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}" "${resolved_id}" >/dev/null 2>&1
		elif [ -z "${resolved_id}" ] && [ -n "${current_id}${current_identity}" ]; then
			fss_set_schema2_reference_node_id "fss_node_current" "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}" "" >/dev/null 2>&1
		fi
		current_id="${resolved_id}"
	else
		current_id=$(dbus get ssconf_basic_node)
		[ -z "${current_id}" ] && current_id=$(fss_get_first_node_id)
	fi
	FSS_CURRENT_NODE_ID_RESULT="${current_id}"
	[ -n "${FSS_CURRENT_NODE_ID_RESULT}" ]
}

fss_get_current_node_id() {
	fss_resolve_current_node_id || return 1
	printf '%s\n' "${FSS_CURRENT_NODE_ID_RESULT}"
}

fss_resolve_failover_node_id() {
	local schema failover_id failover_identity resolved_id
	FSS_FAILOVER_NODE_ID_RESULT=""
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		failover_id=$(dbus get fss_node_failover_backup)
		if [ -n "${failover_id}" ] && fss_node_id_exists "${failover_id}"; then
			FSS_FAILOVER_NODE_ID_RESULT="${failover_id}"
			return 0
		fi
		failover_identity=$(dbus get "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}")
		[ -n "${failover_identity}" ] || failover_identity=$(dbus get "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY_LEGACY}")
		resolved_id=$(fss_resolve_reference_node_id "${failover_id}" "${failover_identity}" "1" 2>/dev/null)
		if [ -n "${resolved_id}" ]; then
			if [ "${resolved_id}" != "${failover_id}" ]; then
				fss_set_schema2_reference_node_id "fss_node_failover_backup" "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}" "${resolved_id}" >/dev/null 2>&1
			fi
			FSS_FAILOVER_NODE_ID_RESULT="${resolved_id}"
			return 0
		else
			[ -n "${failover_id}${failover_identity}" ] && fss_set_schema2_reference_node_id "fss_node_failover_backup" "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}" "" >/dev/null 2>&1
			return 1
		fi
	else
		FSS_FAILOVER_NODE_ID_RESULT="$(dbus get ss_failover_s4_3)"
		[ -n "${FSS_FAILOVER_NODE_ID_RESULT}" ]
	fi
}

fss_get_failover_node_id() {
	fss_resolve_failover_node_id || return 1
	printf '%s\n' "${FSS_FAILOVER_NODE_ID_RESULT}"
}

fss_get_node_identity_by_id() {
	local node_id="$1"
	local schema node_json node_identity=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		node_identity="$(fss_node_json_simple_value "${node_json}" "_identity" 2>/dev/null)"
		if [ -z "${node_identity}" ]; then
			node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
			node_identity="$(fss_node_json_simple_value "${node_json}" "_identity" 2>/dev/null)"
			[ -n "${node_identity}" ] && dbus set fss_node_${node_id}="$(fss_b64_encode "${node_json}")"
		fi
	else
		node_json=$(fss_node_legacy_to_v2_json "${node_id}" "${node_id}" "legacy-runtime" "" 2>/dev/null) || return 1
		node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
		fss_unpack_node_meta "${node_json}" || return 1
		node_identity="${FSS_NODE_META_IDENTITY}"
	fi
	printf '%s' "${node_identity}"
}

fss_get_node_source_scope_by_id() {
	local node_id="$1"
	local schema node_json node_scope=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		node_scope="$(fss_node_json_simple_value "${node_json}" "_source_scope" 2>/dev/null)"
	else
		node_json=$(fss_node_legacy_to_v2_json "${node_id}" "${node_id}" "legacy-runtime" "" 2>/dev/null) || return 1
		node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
		fss_unpack_node_meta "${node_json}" || return 1
		node_scope="${FSS_NODE_META_SOURCE_SCOPE}"
	fi
	printf '%s' "${node_scope}"
}

fss_get_node_profile_id_by_id() {
	local node_id="$1"
	local schema node_json profile_id=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		profile_id="$(fss_node_json_simple_value "${node_json}" "_profile_id" 2>/dev/null)"
	else
		node_json=$(fss_node_legacy_to_v2_json "${node_id}" "${node_id}" "legacy-runtime" "" 2>/dev/null) || return 1
		node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
		fss_unpack_node_meta "${node_json}" || return 1
		profile_id="${FSS_NODE_META_PROFILE_ID}"
	fi
	printf '%s' "${profile_id}"
}

fss_get_node_airport_identity_by_id() {
	local node_id="$1"
	local schema node_json airport=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		airport="$(fss_node_json_simple_value "${node_json}" "_airport_identity" 2>/dev/null)"
	else
		node_json=$(fss_node_legacy_to_v2_json "${node_id}" "${node_id}" "legacy-runtime" "" 2>/dev/null) || return 1
		node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
		fss_unpack_node_meta "${node_json}" || return 1
		airport="${FSS_NODE_META_AIRPORT_IDENTITY}"
	fi
	printf '%s' "${airport}"
}

fss_get_current_node_source_scope() {
	local node_id
	node_id=$(fss_get_current_node_id 2>/dev/null) || return 1
	[ -n "${node_id}" ] || return 1
	fss_get_node_source_scope_by_id "${node_id}"
}

fss_get_current_node_airport_identity() {
	local node_id
	node_id=$(fss_get_current_node_id 2>/dev/null) || return 1
	[ -n "${node_id}" ] || return 1
	fss_get_node_airport_identity_by_id "${node_id}"
}

fss_sync_reference_identity_shadows() {
	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	fss_get_current_node_id >/dev/null 2>&1 || true
	fss_get_failover_node_id >/dev/null 2>&1 || true
}

fss_find_node_id_by_identity() {
	local identity="$1"
	local schema=""
	local node_id=""
	local current_identity=""

	[ -n "${identity}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ]; then
		node_id=$(
			dbus list fss_node_ 2>/dev/null | while IFS= read -r line
			do
				[ -n "${line}" ] || continue
				key=${line%%=*}
				value=${line#*=}
				case "${key}" in
				fss_node_[0-9]*)
					fss_b64_decode "${value}" 2>/dev/null || true
					printf '\n'
					;;
				esac
			done | jq -r --arg identity "${identity}" 'select((._identity // "") == $identity) | ._id // empty' 2>/dev/null | sed -n '1p'
		)
		if [ -n "${node_id}" ];then
			printf '%s' "${node_id}"
			return 0
		fi
	fi
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		current_identity=$(fss_get_node_identity_by_id "${node_id}" 2>/dev/null) || continue
		[ -n "${current_identity}" ] || continue
		if [ "${current_identity}" = "${identity}" ];then
			printf '%s' "${node_id}"
			return 0
		fi
	done <<-EOF
$(fss_list_node_ids)
	EOF
	return 1
}

fss_get_next_node_id_in_order() {
	local current_id="$1"
	local first_id=""
	local hit="0"
	local node_id=""

	while IFS= read -r node_id
	do
		[ -z "${node_id}" ] && continue
		[ -z "${first_id}" ] && first_id="${node_id}"
		if [ "${hit}" = "1" ];then
			echo "${node_id}"
			return 0
		fi
		[ "${node_id}" = "${current_id}" ] && hit="1"
	done <<EOF
$(fss_list_node_ids)
EOF

	echo "${first_id}"
}

fss_get_node_field_plain() {
	local node_id="$1"
	local field="$2"
	local store_field=""
	local schema value="" node_json=""

	[ -z "${node_id}" ] && return 1
	[ -z "${field}" ] && return 1
	store_field=$(fss_resolve_node_field_name "${field}")

	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		if ! fss_is_b64_field "${store_field}"; then
			fss_node_json_simple_value "${node_json}" "${store_field}"
			return 0
		fi
		fss_unpack_node_field_meta "${node_json}" "${store_field}" || return 1
		value="${FSS_NODE_FIELD_VALUE}"
		[ -n "${value}" ] && value=$(fss_v2_field_plain_value "${node_json}" "${store_field}" "${value}" "${FSS_NODE_FIELD_B64_MODE}" "${FSS_NODE_FIELD_SOURCE}")
	else
		value=$(dbus get ssconf_basic_${store_field}_${node_id})
		if [ -n "${value}" ] && fss_is_b64_field "${store_field}"; then
			value=$(fss_b64_decode "${value}")
		fi
	fi

	printf '%s' "${value}"
}

fss_get_node_field_legacy() {
	local node_id="$1"
	local field="$2"
	local store_field=""
	local schema value=""

	[ -z "${node_id}" ] && return 1
	[ -z "${field}" ] && return 1
	store_field=$(fss_resolve_node_field_name "${field}")

	schema=$(fss_detect_storage_schema)
	if [ "${schema}" != "2" ];then
		value=$(dbus get ssconf_basic_${store_field}_${node_id})
		[ -z "${value}" ] && [ "${store_field}" != "${field}" ] && value=$(dbus get ssconf_basic_${field}_${node_id})
		printf '%s' "${value}"
		return 0
	fi

	value=$(fss_get_node_field_plain "${node_id}" "${field}")
	if [ -z "${value}" ];then
		return 0
	fi

	if fss_is_bool_field "${store_field}"; then
		[ "${value}" = "1" ] || return 0
	fi

	if fss_is_b64_field "${store_field}"; then
		case "${store_field}" in
		v2ray_json|xray_json|tuic_json)
			value=$(fss_compact_json_value "${value}")
			;;
		esac
		value=$(fss_b64_encode "${value}")
	fi

	printf '%s' "${value}"
}

fss_extract_tuic_server_host_port() {
	local tuic_server_raw="$1"
	local tuic_server=""
	local tuic_port=""

	case "${tuic_server_raw}" in
	\[*\]:*)
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]:*}"
		tuic_port="${tuic_server_raw##*\]:}"
		;;
	\[*\])
		tuic_server="${tuic_server_raw#\[}"
		tuic_server="${tuic_server%\]}"
		;;
	*:* )
		tuic_server="${tuic_server_raw%:*}"
		tuic_port="${tuic_server_raw##*:}"
		;;
	*)
		tuic_server="${tuic_server_raw}"
		;;
	esac

	printf '%s\n%s\n' "${tuic_server}" "${tuic_port}"
}

fss_extract_xray_like_server_field_from_json_text() {
	local json_text="$1"
	local field="$2"

	printf '%s' "${json_text}" | jq -r --arg field "${field}" '
		(.outbound // (.outbounds[0] // {})) as $ob
		| ($ob.protocol // "") as $protocol
		| if ($protocol == "vmess" or $protocol == "vless") then
			if $field == "host" then
				($ob.settings.vnext[0].address // "")
			else
				(($ob.settings.vnext[0].port // "") | tostring)
			end
		elif ($protocol == "socks" or $protocol == "shadowsocks" or $protocol == "trojan") then
			if $field == "host" then
				($ob.settings.servers[0].address // "")
			else
				(($ob.settings.servers[0].port // "") | tostring)
			end
		else
			""
		end
	' 2>/dev/null
}

fss_is_domain_name() {
	[ -n "$1" ] || return 1
	printf '%s' "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$|:' && return 1
	printf '%s\n' "$1" | awk 'BEGIN {regex = "^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$"} $0 ~ regex { print }'
}

fss_node_json_server_host_port() {
	local node_json="$1"
	[ -n "${node_json}" ] || return 1
	printf '%s' "${node_json}" | jq -r '
		def text($v):
			if $v == null then
				""
			elif ($v | type) == "string" then
				$v
			else
				($v | tostring)
			end;
		def parse_embedded_json($raw):
			if (($raw | type) != "string") or $raw == "" then
				{}
			else
				(try ($raw | fromjson) catch {})
			end;
		def xray_like_host_port($cfg):
			($cfg.outbound // ($cfg.outbounds[0] // {})) as $ob
			| ($ob.protocol // "") as $protocol
			| if ($protocol == "vmess" or $protocol == "vless") then
				[
					text($ob.settings.vnext[0].address),
					text($ob.settings.vnext[0].port)
				]
			elif ($protocol == "socks" or $protocol == "shadowsocks" or $protocol == "trojan") then
				[
					text($ob.settings.servers[0].address),
					text($ob.settings.servers[0].port)
				]
			else
				["", ""]
			end;
		def split_tuic_server($raw):
			if $raw == "" then
				["", ""]
			elif ($raw | startswith("[")) then
				[
					(try ($raw | capture("^\\[(?<host>[^\\]]+)\\](?::.*)?$").host) catch ""),
					(try ($raw | capture("^\\[[^\\]]+\\]:(?<port>.*)$").port) catch "")
				]
			elif ($raw | contains(":")) then
				[
					($raw | sub(":.*$"; "")),
					($raw | capture(":(?<port>[^:]*)$").port)
				]
			else
				[$raw, ""]
			end;
		(.type // "") as $type
		| if ($type == "0" or $type == "1" or $type == "5") then
			[
				text(.server),
				text(.port)
			]
		elif $type == "3" then
			if text(.v2ray_use_json) == "1" then
				xray_like_host_port(parse_embedded_json(.v2ray_json))
			else
				[
					text(.server),
					text(.port)
				]
			end
		elif $type == "4" then
			if text(.xray_use_json) == "1" then
				xray_like_host_port(parse_embedded_json(.xray_json))
			else
				[
					text(.server),
					text(.port)
				]
			end
		elif $type == "6" then
			[
				text(.naive_server),
				text(.naive_port)
			]
		elif $type == "7" then
			split_tuic_server(text((parse_embedded_json(.tuic_json).relay.server)))
		elif $type == "8" then
			[
				text(.hy2_server),
				text(.hy2_port)
			]
		else
			[
				text(.server),
				text(.port)
			]
		end
		| .[]
	' 2>/dev/null
}

fss_get_node_server_host_port() {
	local node_id="$1"
	local node_type="" host="" port="" json_text="" relay_server="" node_json="" schema=""

	[ -n "${node_id}" ] || return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		node_json="$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null)" || return 1
		fss_node_json_server_host_port "${node_json}"
		return 0
	fi
	node_type="$(fss_get_node_field_plain "${node_id}" "type")"

	case "${node_type}" in
	0|1|5)
		host="$(fss_get_node_field_plain "${node_id}" "server")"
		port="$(fss_get_node_field_plain "${node_id}" "port")"
		;;
	3)
		if [ "$(fss_get_node_field_plain "${node_id}" "v2ray_use_json")" = "1" ]; then
			json_text="$(fss_get_node_field_plain "${node_id}" "v2ray_json")"
			host="$(fss_extract_xray_like_server_field_from_json_text "${json_text}" host)"
			port="$(fss_extract_xray_like_server_field_from_json_text "${json_text}" port)"
		else
			host="$(fss_get_node_field_plain "${node_id}" "server")"
			port="$(fss_get_node_field_plain "${node_id}" "port")"
		fi
		;;
	4)
		if [ "$(fss_get_node_field_plain "${node_id}" "xray_use_json")" = "1" ]; then
			json_text="$(fss_get_node_field_plain "${node_id}" "xray_json")"
			host="$(fss_extract_xray_like_server_field_from_json_text "${json_text}" host)"
			port="$(fss_extract_xray_like_server_field_from_json_text "${json_text}" port)"
		else
			host="$(fss_get_node_field_plain "${node_id}" "server")"
			port="$(fss_get_node_field_plain "${node_id}" "port")"
		fi
		;;
	6)
		host="$(fss_get_node_field_plain "${node_id}" "naive_server")"
		port="$(fss_get_node_field_plain "${node_id}" "naive_port")"
		;;
	7)
		json_text="$(fss_get_node_field_plain "${node_id}" "tuic_json")"
		relay_server="$(printf '%s' "${json_text}" | jq -r '.relay.server // empty' 2>/dev/null)"
		{
			read -r host
			read -r port
		} <<-EOF
		$(fss_extract_tuic_server_host_port "${relay_server}")
		EOF
		;;
	8)
		host="$(fss_get_node_field_plain "${node_id}" "hy2_server")"
		port="$(fss_get_node_field_plain "${node_id}" "hy2_port")"
		;;
	*)
		host="$(fss_get_node_field_plain "${node_id}" "server")"
		port="$(fss_get_node_field_plain "${node_id}" "port")"
		;;
	esac

	printf '%s\n%s\n' "${host}" "${port}"
}

fss_pick_jq_bin() {
	if [ -x "/koolshare/bin/jq" ]; then
		printf '%s\n' "/koolshare/bin/jq"
		return 0
	fi
	command -v jq 2>/dev/null
}

fss_list_node_server_domains_slow() {
	local node_id="" host="" port=""
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		{
			read -r host
			read -r port
		} <<-EOF
		$(fss_get_node_server_host_port "${node_id}")
		EOF
		[ -n "${host}" ] || continue
		[ -n "$(fss_is_domain_name "${host}")" ] || continue
		printf '%s\n' "${host}"
	done <<-EOF
	$(fss_list_node_ids)
	EOF
}

fss_list_node_server_domains_v2_fast() {
	local jq_bin="" line="" key="" value=""

	jq_bin=$(fss_pick_jq_bin)
	[ -n "${jq_bin}" ] || return 1

	dbus list fss_node_ 2>/dev/null | while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		key=${line%%=*}
		value=${line#*=}
		case "${key}" in
		fss_node_[0-9]*)
			fss_b64_decode "${value}" 2>/dev/null || true
			printf '\n'
			;;
		esac
	done | "${jq_bin}" -Rnr '
		def parse_embedded_json:
			if type != "string" or . == "" then
				{}
			else
				(try fromjson catch {})
			end;
		def xray_like_host($root):
			($root.outbound // ($root.outbounds[0] // {})) as $ob
			| ($ob.protocol // "") as $protocol
			| if ($protocol == "vmess" or $protocol == "vless") then
				($ob.settings.vnext[0].address // "")
			elif ($protocol == "socks" or $protocol == "shadowsocks" or $protocol == "trojan") then
				($ob.settings.servers[0].address // "")
			else
				""
			end;
		def tuic_host:
			if . == "" then
				""
			elif startswith("[") then
				(try capture("^\\[(?<host>[^\\]]+)\\](?::.*)?$").host catch "")
			else
				sub(":.*$"; "")
			end;
		inputs
		| (try fromjson catch null)
		| select(type == "object")
		| (.type // "") as $type
		| if ($type == "0" or $type == "1" or $type == "5") then
			(.server // "")
		elif $type == "6" then
			(.naive_server // "")
		elif $type == "8" then
			(.hy2_server // "")
		elif $type == "9" then
			(.anytls_server // "")
		elif $type == "3" then
			if (.v2ray_use_json // "0") == "1" then
				(.v2ray_json | parse_embedded_json | xray_like_host(.))
			else
				(.server // "")
			end
		elif $type == "4" then
			if (.xray_use_json // "0") == "1" then
				(.xray_json | parse_embedded_json | xray_like_host(.))
			else
				(.server // "")
			end
		elif $type == "7" then
			(.tuic_json | parse_embedded_json | .relay.server // "" | tuic_host)
		else
			(.server // "")
		end
	' 2>/dev/null | while IFS= read -r host
	do
		[ -n "${host}" ] || continue
		[ -n "$(fss_is_domain_name "${host}")" ] || continue
		printf '%s\n' "${host}"
	done
}

fss_list_node_server_domains() {
	if [ "$(fss_detect_storage_schema)" = "2" ]; then
		fss_list_node_server_domains_v2_fast && return 0
	fi
	fss_list_node_server_domains_slow
}

fss_list_node_airport_domains() {
	local node_id=""
	local airport_identity=""
	local host=""
	local port=""

	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		airport_identity="$(fss_get_node_airport_identity_by_id "${node_id}" 2>/dev/null)"
		[ -n "${airport_identity}" ] || airport_identity="local"
		{
			read -r host
			read -r port
		} <<-EOF
		$(fss_get_node_server_host_port "${node_id}" 2>/dev/null)
		EOF
		[ -n "${host}" ] || continue
		[ -n "$(fss_is_domain_name "${host}")" ] || continue
		printf '%s\t%s\n' "${airport_identity}" "${host}"
	done <<-EOF
	$(fss_list_node_ids)
	EOF
}

fss_refresh_node_direct_cache() {
	local cache_file="${FSS_NODE_DIRECT_CACHE_FILE}"
	local airport_cache_file="${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}"
	local cache_dir="${cache_file%/*}"
	local tmp_file="${cache_file}.tmp.$$"
	local airport_tmp="${airport_cache_file}.tmp.$$"
	local catalog_ts="0"
	local node_tool=""

	if [ "$(fss_detect_storage_schema)" = "2" ] && fss_node_direct_cache_is_fresh; then
		return 0
	fi
	mkdir -p "${cache_dir}" || return 1
	rm -f "${tmp_file}" "${airport_tmp}"
	node_tool="$(fss_pick_node_tool 2>/dev/null)" || node_tool=""
	if [ -n "${node_tool}" ] && fss_node_tool_supports_command "${node_tool}" "airport-domains"; then
		if "${node_tool}" warm-cache --direct-domains >/dev/null 2>&1 && "${node_tool}" airport-domains --format text > "${airport_tmp}" 2>/dev/null; then
			sort -u "${airport_tmp}" -o "${airport_tmp}" 2>/dev/null || true
			if [ -s "${airport_tmp}" ];then
				mv -f "${airport_tmp}" "${airport_cache_file}"
			else
				rm -f "${airport_tmp}" "${airport_cache_file}"
			fi
			catalog_ts=$(fss_get_node_catalog_ts)
			[ "${catalog_ts}" != "0" ] || catalog_ts=$(fss_touch_node_catalog_ts)
			if [ -s "${FSS_NODE_DIRECT_CACHE_FILE}" ] && [ -s "${airport_cache_file}" ];then
				fss_write_node_direct_cache_meta "${catalog_ts}"
				return 0
			fi
		fi
	fi
	fss_list_node_airport_domains | sort -u > "${airport_tmp}"
	awk -F '\t' 'NF >= 2 && $2 != "" {print $2}' "${airport_tmp}" | sort -u > "${tmp_file}"
	catalog_ts=$(fss_get_node_catalog_ts)
	[ "${catalog_ts}" != "0" ] || catalog_ts=$(fss_touch_node_catalog_ts)
	if [ -s "${tmp_file}" ] && [ -s "${airport_tmp}" ]; then
		mv -f "${tmp_file}" "${cache_file}"
		mv -f "${airport_tmp}" "${airport_cache_file}"
		fss_write_node_direct_cache_meta "${catalog_ts}"
	else
		rm -f "${tmp_file}" "${airport_tmp}" "${cache_file}" "${airport_cache_file}" "${FSS_NODE_DIRECT_CACHE_META_FILE}"
	fi
}

fss_refresh_airport_node_direct_runtime_by_airport() {
	local airport_identity="$1"
	local airport_file="${FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE}"
	local other_file="${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}"
	local airport_tmp="${airport_file}.tmp.$$"
	local other_tmp="${other_file}.tmp.$$"
	local line_airport=""
	local line_host=""

	rm -f "${airport_tmp}" "${other_tmp}"
	[ -n "${airport_identity}" ] || {
		rm -f "${airport_file}" "${other_file}"
		return 0
	}
	fss_refresh_node_direct_cache || return 1
	[ -s "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" ] || {
		rm -f "${airport_file}" "${other_file}"
		return 0
	}
	while IFS="$(printf '\t')" read -r line_airport line_host
	do
		[ -n "${line_airport}" ] || continue
		[ -n "${line_host}" ] || continue
		if [ "${line_airport}" = "${airport_identity}" ];then
			printf '%s\n' "${line_host}" >> "${airport_tmp}"
		else
			printf '%s\n' "${line_host}" >> "${other_tmp}"
		fi
	done < "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}"

	if [ -s "${airport_tmp}" ];then
		sort -u "${airport_tmp}" -o "${airport_tmp}" 2>/dev/null
		mv -f "${airport_tmp}" "${airport_file}"
	else
		rm -f "${airport_tmp}" "${airport_file}"
	fi
	if [ -s "${other_tmp}" ];then
		sort -u "${other_tmp}" -o "${other_tmp}" 2>/dev/null
		mv -f "${other_tmp}" "${other_file}"
	else
		rm -f "${other_tmp}" "${other_file}"
	fi
}

fss_refresh_node_json_cache() {
	local cache_dir="${FSS_NODE_JSON_CACHE_DIR}"
	local tmp_dir="${cache_dir}.tmp.$$"
	local old_dir="${cache_dir}.old.$$"
	local config_ts="0"
	local jq_bin=""
	local json_files=""

	if [ "$(fss_detect_storage_schema)" = "2" ] && fss_node_json_cache_is_fresh; then
		return 0
	fi
	mkdir -p "${cache_dir%/*}" || return 1
	rm -rf "${tmp_dir}" "${old_dir}"
	mkdir -p "${tmp_dir}" || return 1
	fss_dump_v2_node_json_dir "${tmp_dir}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	ls "${tmp_dir}"/*.json >/dev/null 2>&1 || {
		rm -rf "${tmp_dir}"
		return 1
	}
	jq_bin=$(fss_pick_jq_bin)
	json_files=$(ls "${tmp_dir}"/*.json 2>/dev/null)
	if [ -n "${jq_bin}" ] && [ -n "${json_files}" ]; then
		# 节点索引只在缓存重建时生成，批量测速热路径直接复用，避免每次再扫整批 JSON。
		# shellcheck disable=SC2086
		"${jq_bin}" -r '
			[
				(input_filename | split("/")[-1] | rtrimstr(".json")),
				(
					((.type // "") | tostring) as $type
					| if ($type | length) == 1 then "0" + $type else $type end
				),
				((.ss_obfs // "") | tostring),
				((.method // "") | tostring)
			] | join("|")
		' ${json_files} 2>/dev/null > "${tmp_dir}/nodes_index.txt" || rm -f "${tmp_dir}/nodes_index.txt"
		[ -s "${tmp_dir}/nodes_index.txt" ] && sort -t "|" -nk1 "${tmp_dir}/nodes_index.txt" -o "${tmp_dir}/nodes_index.txt" 2>/dev/null
	fi
	config_ts=$(fss_get_node_config_ts)
	[ "${config_ts}" != "0" ] || config_ts=$(fss_touch_node_config_ts)
	[ -d "${cache_dir}" ] && mv -f "${cache_dir}" "${old_dir}" >/dev/null 2>&1
	mv -f "${tmp_dir}" "${cache_dir}" || {
		rm -rf "${tmp_dir}"
		[ -d "${old_dir}" ] && mv -f "${old_dir}" "${cache_dir}" >/dev/null 2>&1
		return 1
	}
	rm -rf "${old_dir}"
	fss_write_node_json_cache_meta "${config_ts}"
}

fss_refresh_node_env_cache() {
	fss_clear_node_env_cache_artifacts >/dev/null 2>&1 || true
	return 1
}

fss_sync_node_direct_runtime() {
	local runtime_file="${FSS_NODE_DIRECT_RUNTIME_FILE}"
	local tmp_file="${runtime_file}.tmp.$$"

	rm -f "${tmp_file}"
	if [ -s "${FSS_NODE_DIRECT_CACHE_FILE}" ]; then
		if [ -s "${runtime_file}" ] && cmp -s "${FSS_NODE_DIRECT_CACHE_FILE}" "${runtime_file}" >/dev/null 2>&1; then
			return 0
		fi
		cat "${FSS_NODE_DIRECT_CACHE_FILE}" > "${tmp_file}" || {
			rm -f "${tmp_file}"
			return 1
		}
		mv -f "${tmp_file}" "${runtime_file}"
	else
		rm -f "${tmp_file}" "${runtime_file}"
	fi
}

fss_node_direct_cache_differs_from_runtime() {
	local cache_exists="0"
	local runtime_exists="0"

	[ -s "${FSS_NODE_DIRECT_CACHE_FILE}" ] && cache_exists="1"
	[ -s "${FSS_NODE_DIRECT_RUNTIME_FILE}" ] && runtime_exists="1"

	if [ "${cache_exists}" = "0" ] && [ "${runtime_exists}" = "0" ]; then
		return 1
	fi

	if [ "${cache_exists}" != "${runtime_exists}" ]; then
		return 0
	fi

	cmp -s "${FSS_NODE_DIRECT_CACHE_FILE}" "${FSS_NODE_DIRECT_RUNTIME_FILE}" >/dev/null 2>&1
	[ "$?" != "0" ]
}

fss_export_current_node_env_with_node_tool() {
	local node_id="$1"
	shift
	local node_tool=""
	local fields_csv="$*"
	local tmp_file=""

	node_tool="$(fss_pick_node_tool 2>/dev/null)" || return 1
	[ -n "${fields_csv}" ] || return 1
	tmp_file="/tmp/fss_node_env.${node_id}.$$.$RANDOM"
	"${node_tool}" current-env --ids "${node_id}" --fields "${fields_csv}" > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	[ -s "${tmp_file}" ] || {
		rm -f "${tmp_file}"
		return 1
	}
	. "${tmp_file}" || {
		rm -f "${tmp_file}"
		return 1
	}
	rm -f "${tmp_file}"
	return 0
}

fss_export_current_node_env() {
	local node_id="$1"
	shift
	local field value schema node_json meta_file encoded_value

	[ -z "${node_id}" ] && node_id=$(fss_get_current_node_id)
	[ -z "${node_id}" ] && return 1

	export FSS_NODE_CURRENT_ID="${node_id}"
	export ssconf_basic_node="${node_id}"

	schema=$(fss_detect_storage_schema)
	if [ "${schema}" = "2" ];then
		fss_export_current_node_env_with_node_tool "${node_id}" "$@" && return 0
		node_json=$(fss_v2_get_node_json_by_id "${node_id}") || return 1
		meta_file="/tmp/fss_export_env.${node_id}.$$.$RANDOM"
		: > "${meta_file}" || return 1
		for field in "$@"
		do
			[ -z "${field}" ] && continue
			printf '%s\t%s\n' "${field}" "$(fss_resolve_node_field_name "${field}")" >> "${meta_file}"
		done

		while IFS='	' read -r field encoded_value
		do
			[ -n "${field}" ] || continue
			[ -n "${encoded_value}" ] || continue
			value=$(fss_b64_decode "${encoded_value}")
			[ -n "${value}" ] && export ss_basic_${field}="${value}"
		done <<EOF
$(printf '%s' "${node_json}" | jq -r --rawfile meta "${meta_file}" '
	def is_bool($f):
		$f == "v2ray_use_json"
		or $f == "v2ray_mux_enable"
		or $f == "v2ray_network_security_ai"
		or $f == "v2ray_network_security_alpn_h2"
		or $f == "v2ray_network_security_alpn_http"
		or $f == "xray_use_json"
		or $f == "xray_network_security_ai"
		or $f == "xray_network_security_alpn_h2"
		or $f == "xray_network_security_alpn_http"
		or $f == "xray_show"
		or $f == "trojan_ai"
		or $f == "trojan_tfo"
		or $f == "hy2_ai"
		or $f == "hy2_tfo"
		or $f == "anytls_ai";
	def is_b64($f):
		$f == "password"
		or $f == "naive_pass"
		or $f == "v2ray_json"
		or $f == "xray_json"
		or $f == "tuic_json";
	def need_compact_json($f):
		$f == "v2ray_json"
		or $f == "xray_json"
		or $f == "tuic_json";
	def compact_json_string:
		try (fromjson | tojson) catch .;
	def to_plain_value($root; $field; $value):
		if is_b64($field) then
			if (($root._b64_mode // "") == "raw") or (($root._source // "") != "subscribe") then
				$value
			else
				(try ($value | @base64d) catch $value)
			end
		else
			$value
		end;
	. as $root
	| ($meta | split("\n") | map(select(length > 0) | split("\t")))[] as $item
	| ($item[0]) as $field
	| ($item[1]) as $store_field
	| ($root[$store_field] // empty | if type == "string" then . else tostring end) as $raw_value
	| select($raw_value != "")
	| (to_plain_value($root; $store_field; $raw_value)) as $plain_value
	| (
		if is_b64($store_field) and $store_field != "password" and $store_field != "naive_pass" then
			(if need_compact_json($store_field) then ($plain_value | compact_json_string) else $plain_value end) | @base64
		else
			$plain_value
		end
	  ) as $legacy_value
	| "\($field)\t\($legacy_value | @base64)"
')
EOF
		rm -f "${meta_file}"
		return 0
	fi

	for field in "$@"
	do
		[ -z "${field}" ] && continue
		value=$(fss_get_node_field_legacy "${node_id}" "${field}")
		[ -z "${value}" ] && continue
		export ss_basic_${field}="${value}"
	done
}

fss_set_current_node_id() {
	local node_id="$1"
	if [ "$(fss_detect_storage_schema)" = "2" ];then
		if [ -n "${node_id}" ]; then
			fss_set_schema2_reference_node_id "fss_node_current" "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}" "${node_id}"
			dbus set ssconf_basic_node="${node_id}"
		else
			fss_set_schema2_reference_node_id "fss_node_current" "${FSS_CURRENT_NODE_IDENTITY_DBUS_KEY}" ""
			dbus remove ssconf_basic_node
		fi
	else
		[ -n "${node_id}" ] && dbus set ssconf_basic_node="${node_id}" || dbus remove ssconf_basic_node
	fi
}

fss_set_failover_node_id() {
	local node_id="$1"
	if [ "$(fss_detect_storage_schema)" = "2" ];then
		fss_set_schema2_reference_node_id "fss_node_failover_backup" "${FSS_FAILOVER_NODE_IDENTITY_DBUS_KEY}" "${node_id}"
		[ -n "${node_id}" ] && dbus set ss_failover_s4_3="${node_id}" || dbus remove ss_failover_s4_3
	else
		[ -n "${node_id}" ] && dbus set ss_failover_s4_3="${node_id}" || dbus remove ss_failover_s4_3
	fi
}

fss_set_node_field_plain() {
	local node_id="$1"
	local field="$2"
	local value="$3"
	local schema node_json updated_json current_value updated_at is_runtime="0"

	[ -z "${node_id}" ] && return 1
	[ -z "${field}" ] && return 1

	schema=$(fss_detect_storage_schema)
	if [ "${schema}" != "2" ];then
		dbus set ssconf_basic_${field}_${node_id}="${value}"
		return 0
	fi

	node_json=$(fss_v2_get_node_json_by_id "${node_id}") || return 1
	if fss_is_bool_field "${field}"; then
		[ "${value}" = "1" ] && value="1" || value="0"
	fi
	current_value=$(fss_get_node_field_plain "${node_id}" "${field}" 2>/dev/null)
	[ "${current_value}" = "${value}" ] && return 0
	fss_is_runtime_field "${field}" && is_runtime="1"
	updated_at=$(fss_now_ts_ms)
	if [ "${is_runtime}" = "1" ]; then
		updated_json=$(printf '%s' "${node_json}" | jq -c --arg k "${field}" --arg v "${value}" '
			if $v == "" then
				del(.[$k])
			else
				.[$k] = $v
			end
		') || return 1
	else
		updated_json=$(printf '%s' "${node_json}" | jq -c --arg k "${field}" --arg v "${value}" --argjson updated_at "${updated_at}" '
			if $v == "" then
				del(.[$k])
			else
				.[$k] = $v
			end
			| ._rev = (((._rev // 0) | tonumber? // 0) + 1)
			| ._updated_at = $updated_at
		') || return 1
	fi
	dbus set fss_node_${node_id}="$(fss_b64_encode "${updated_json}")"
	if [ "${is_runtime}" != "1" ]; then
		fss_clear_webtest_cache_node "${node_id}"
		fss_clear_webtest_runtime_results
		fss_touch_node_config_ts >/dev/null 2>&1
	fi
	if fss_node_field_affects_direct_domains "${field}"; then
		fss_touch_node_catalog_ts >/dev/null 2>&1
	fi
}

fss_clear_node_runtime_fields() {
	local node_id="$1"
	local schema node_json updated_json

	[ -z "${node_id}" ] && return 1
	schema=$(fss_detect_storage_schema)
	if [ "${schema}" != "2" ];then
		dbus remove ssconf_basic_server_ip_${node_id}
		dbus remove ssconf_basic_latency_${node_id}
		dbus remove ssconf_basic_ping_${node_id}
		return 0
	fi

	node_json=$(fss_v2_get_node_json_by_id "${node_id}") || return 1
	updated_json=$(printf '%s' "${node_json}" | jq -c '
		del(.server_ip, .latency, .ping)
	') || return 1
	dbus set fss_node_${node_id}="$(fss_b64_encode "${updated_json}")"
}

fss_clear_all_runtime_fields() {
	local node_id

	if [ "$(fss_detect_storage_schema)" = "2" ];then
		for node_id in $(fss_list_node_ids)
		do
			[ -z "${node_id}" ] && continue
			fss_clear_node_runtime_fields "${node_id}" >/dev/null 2>&1
		done
	else
		dbus list ssconf_basic_server_ip_ | sort -n -t "_" -k 4 | cut -d "=" -f 1 | while IFS= read -r key
		do
			[ -z "${key}" ] && continue
			dbus remove "${key}"
		done
		dbus list ssconf_basic_latency_ | sort -n -t "_" -k 4 | cut -d "=" -f 1 | while IFS= read -r key
		do
			[ -z "${key}" ] && continue
			dbus remove "${key}"
		done
		dbus list ssconf_basic_ping_ | sort -n -t "_" -k 4 | cut -d "=" -f 1 | while IFS= read -r key
		do
			[ -z "${key}" ] && continue
			dbus remove "${key}"
		done
	fi
}

fss_set_current_node_field_plain() {
	local field="$1"
	local value="$2"
	local node_id

	node_id=$(fss_get_current_node_id)
	[ -z "${node_id}" ] && return 1
	fss_set_node_field_plain "${node_id}" "${field}" "${value}"
}

fss_export_native_backup() {
	local output_file="$1"
	local progress_cb="$2"
	local schema=$(fss_detect_storage_schema)
	local tmp_dir
	local global_json acl_json order_json
	local node_current="" node_failover="" node_next_id=""
	local plugin_version created_at
	local dump_file="" node_cache_dir=""
	local progress_enabled=0
	local node_total=0 idx=0

	[ -z "${output_file}" ] && return 1
	if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
		progress_enabled=1
	fi
	tmp_dir=$(fss_mktemp_dir fss_backup)
	if [ "${progress_enabled}" = "1" ];then
		"${progress_cb}" "阶段1/5：准备导出环境..."
	fi
	created_at=$(date '+%Y-%m-%dT%H:%M:%S%z')
	plugin_version=$(fss_get_plugin_version)
	if [ "${progress_enabled}" = "1" ];then
		"${progress_cb}" "阶段2/5：导出普通配置..."
	fi
	global_json=$(fss_export_global_json)
	if [ "${progress_enabled}" = "1" ];then
		"${progress_cb}" "阶段3/5：导出访问控制配置..."
	fi
	acl_json=$(fss_export_acl_json)
	printf '%s' "${global_json}" > "${tmp_dir}/global.json"
	printf '%s' "${acl_json}" > "${tmp_dir}/acl.json"

	if [ "${schema}" = "2" ];then
		local node_order_csv
		local node_id
		node_order_csv=$(dbus get fss_node_order)
		order_json=$(fss_csv_to_json_array "${node_order_csv}")
		node_current=$(fss_get_current_node_id)
		node_failover=$(fss_get_failover_node_id)
		node_next_id=$(dbus get fss_node_next_id)
		node_cache_dir="${tmp_dir}/nodes_v2"
		node_total=$(printf '%s' "${node_order_csv}" | tr ',' '\n' | sed '/^$/d' | awk 'END{print NR + 0}')
		if [ "${progress_enabled}" = "1" ];then
			"${progress_cb}" "阶段4/5：批量读取 schema 2 节点数据，共 ${node_total} 个节点..."
			[ "${node_total}" -gt 80 ] && "${progress_cb}" "节点数量较多，本阶段需要读取并规整每个节点，可能需要几十秒，请不要关闭窗口。"
		fi
		fss_dump_v2_node_json_dir "${node_cache_dir}" || {
			rm -rf "${tmp_dir}"
			return 1
		}
		printf '%s' "${order_json}" > "${tmp_dir}/order.json"
		: > "${tmp_dir}/nodes.jsonl"
		if [ "${progress_enabled}" = "1" ];then
			"${progress_cb}" "阶段5/5：规整节点并组装JSON备份..."
		fi
		idx=0
		for node_id in $(printf '%s' "${node_order_csv}" | tr ',' ' ')
		do
			idx=$((idx + 1))
			fss_prepare_backup_node_json "$(cat "${node_cache_dir}/${node_id}.json")" >> "${tmp_dir}/nodes.jsonl" || {
				rm -rf "${tmp_dir}"
				return 1
			}
			printf '\n' >> "${tmp_dir}/nodes.jsonl"
			if [ "${progress_enabled}" = "1" ];then
				if [ "${idx}" = "1" ] || [ $((idx % 25)) -eq 0 ] || [ "${idx}" = "${node_total}" ];then
					"${progress_cb}" "节点JSON导出进度：${idx}/${node_total}"
				fi
			fi
		done
	else
		local node_ids
		local max_node=0
		node_current=$(dbus get ssconf_basic_node)
		node_failover=$(dbus get ss_failover_s4_3)
		dump_file="${tmp_dir}/legacy_nodes.txt"
		dbus list ssconf_basic_ | grep -E '_[0-9]+=' | sed '/^ssconf_basic_.\+_[0-9]\+=$/d' > "${dump_file}"
		node_ids=$(fss_list_legacy_node_indices)
		order_json=$(printf '%s\n' ${node_ids} | sed '/^$/d' | jq -Rsc 'split("\n")[:-1]')
		printf '%s' "${order_json}" > "${tmp_dir}/order.json"
		: > "${tmp_dir}/nodes.jsonl"
		node_total=$(printf '%s\n' ${node_ids} | sed '/^$/d' | awk 'END{print NR + 0}')
		if [ "${progress_enabled}" = "1" ];then
			"${progress_cb}" "阶段4/5：读取旧版节点数据，共 ${node_total} 个节点..."
			[ "${node_total}" -gt 80 ] && "${progress_cb}" "旧版节点导出需要逐个转换为新JSON结构，节点较多时耗时较长，请不要关闭窗口。"
			"${progress_cb}" "阶段5/5：转换节点并组装JSON备份..."
		fi
		idx=0
		for node_id in ${node_ids}
		do
			idx=$((idx + 1))
			[ "${node_id}" -gt "${max_node}" ] && max_node="${node_id}"
			fss_node_legacy_to_v2_json "${node_id}" "${node_id}" "legacy-export" "${dump_file}" | fss_prepare_backup_node_json >> "${tmp_dir}/nodes.jsonl" || {
				rm -rf "${tmp_dir}"
				return 1
			}
			printf '\n' >> "${tmp_dir}/nodes.jsonl"
			if [ "${progress_enabled}" = "1" ];then
				if [ "${idx}" = "1" ] || [ $((idx % 25)) -eq 0 ] || [ "${idx}" = "${node_total}" ];then
					"${progress_cb}" "节点JSON导出进度：${idx}/${node_total}"
				fi
			fi
		done
		node_next_id=$((max_node + 1))
	fi

	if [ "${progress_enabled}" = "1" ];then
		"${progress_cb}" "正在生成最终JSON文件..."
	fi
	jq -s '.' "${tmp_dir}/nodes.jsonl" > "${tmp_dir}/nodes.json"
	jq -n \
		--arg created_at "${created_at}" \
		--arg plugin_version "${plugin_version}" \
		--arg node_current "${node_current}" \
		--arg node_failover "${node_failover}" \
		--arg node_next_id "${node_next_id}" \
		--arg storage_schema "${schema}" \
		--slurpfile global "${tmp_dir}/global.json" \
		--slurpfile acl "${tmp_dir}/acl.json" \
		--slurpfile nodes "${tmp_dir}/nodes.json" \
		--slurpfile order "${tmp_dir}/order.json" \
		'
		{
			format: "fancyss-backup",
			schema_version: 2,
			created_at: $created_at,
			plugin_version: $plugin_version,
			storage_schema: $storage_schema,
			global: $global[0],
			nodes: $nodes[0],
			node_order: $order[0],
			node_current: $node_current,
			node_failover_backup: $node_failover,
			node_next_id: $node_next_id,
			acl: $acl[0]
		}
		' > "${output_file}"
	if [ "${progress_enabled}" = "1" ];then
		local output_size
		output_size=$(du -h "${output_file}" 2>/dev/null | awk '{print $1}')
		"${progress_cb}" "最终JSON文件生成完成${output_size:+，大小 ${output_size}}。"
	fi

	rm -rf "${tmp_dir}"
}

fss_export_legacy_backup() {
	local output_file="$1"
	local progress_cb="$2"
	local schema=$(fss_detect_storage_schema)
	local key value idx node_id node_json
	local node_order_csv node_current node_failover current_pos="" failover_pos=""
	local tmp_dir="" node_cache_dir="" node_total=0
	local acl_default_ports=""

	[ -z "${output_file}" ] && return 1
	if [ "${schema}" = "2" ];then
		tmp_dir=$(fss_mktemp_dir fss_legacy) || return 1
		node_cache_dir="${tmp_dir}/nodes_v2"
		if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
			"${progress_cb}" "阶段1/4：批量读取节点数据..."
		fi
		fss_dump_v2_node_json_dir "${node_cache_dir}" || {
			rm -rf "${tmp_dir}"
			return 1
		}
	fi
	{
	cat <<-EOF
#!/bin/sh
source /koolshare/scripts/base.sh
EOF

	if [ "${schema}" = "2" ];then
		if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
			"${progress_cb}" "阶段2/4：导出全局配置..."
		fi
		dbus list ss | grep -v '^ssconf_basic_' | grep -v '^ss_acl_' | grep -v '^ss_basic_enable=' | grep -v '^ssid_' | grep -v '^ss_failover_s4_3=' | while IFS= read -r line
		do
			[ -z "${line}" ] && continue
			key=${line%%=*}
			value=${line#*=}
			printf 'dbus set %s=%s\n' "${key}" "$(fss_shell_quote "${value}")"
		done

		if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
			"${progress_cb}" "阶段3/4：导出访问控制配置..."
		fi
		acl_default_ports=$(fss_get_acl_default_ports_value)
		{
		dbus list ss_acl_ | grep -v '^ss_acl_default_port=' | grep -v '^ss_acl_default_ports='
		[ -n "${acl_default_ports}" ] && printf 'ss_acl_default_ports=%s\n' "${acl_default_ports}"
		[ -n "${acl_default_ports}" ] && printf 'ss_acl_default_port=%s\n' "${acl_default_ports}"
		} | while IFS= read -r line
		do
			[ -z "${line}" ] && continue
			key=${line%%=*}
			value=${line#*=}
			printf 'dbus set %s=%s\n' "${key}" "$(fss_shell_quote "${value}")"
		done

		node_order_csv=$(dbus get fss_node_order)
		node_current=$(fss_get_current_node_id)
		node_failover=$(fss_get_failover_node_id)
		node_total=$(printf '%s' "${node_order_csv}" | tr ',' '\n' | sed '/^$/d' | awk 'END{print NR + 0}')
		if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
			"${progress_cb}" "阶段4/4：导出节点配置，共 ${node_total} 个节点..."
		fi
		idx=0
		for node_id in $(printf '%s' "${node_order_csv}" | tr ',' ' ')
		do
			idx=$((idx + 1))
			[ "${node_current}" = "${node_id}" ] && current_pos="${idx}"
			[ "${node_failover}" = "${node_id}" ] && failover_pos="${idx}"
			node_json=$(cat "${node_cache_dir}/${node_id}.json" 2>/dev/null)
			[ -z "${node_json}" ] && node_json=$(fss_v2_get_node_json_by_id "${node_id}")
			printf '%s' "${node_json}" | fss_node_v2_to_legacy_script_lines "${idx}"
			if [ -n "${progress_cb}" ] && type "${progress_cb}" >/dev/null 2>&1; then
				if [ "${idx}" = "1" ] || [ $((idx % 20)) -eq 0 ] || [ "${idx}" = "${node_total}" ];then
					"${progress_cb}" "节点配置导出进度：${idx}/${node_total}"
				fi
			fi
		done

		[ -n "${current_pos}" ] && printf 'dbus set ssconf_basic_node=%s\n' "$(fss_shell_quote "${current_pos}")"
		[ -n "${failover_pos}" ] && printf 'dbus set ss_failover_s4_3=%s\n' "$(fss_shell_quote "${failover_pos}")"
	else
		dbus list ss | grep -v '^ss_basic_enable=' | grep -v '^ssid_' | while IFS= read -r line
		do
			[ -z "${line}" ] && continue
			key=${line%%=*}
			value=${line#*=}
			printf 'dbus set %s=%s\n' "${key}" "$(fss_shell_quote "${value}")"
		done
		acl_default_ports=$(fss_get_acl_default_ports_value)
		[ -n "${acl_default_ports}" ] && printf 'dbus set ss_acl_default_ports=%s\n' "$(fss_shell_quote "${acl_default_ports}")"
		[ -n "${acl_default_ports}" ] && printf 'dbus set ss_acl_default_port=%s\n' "$(fss_shell_quote "${acl_default_ports}")"
	fi
	} > "${output_file}"

	chmod +x "${output_file}"
	rm -rf "${tmp_dir}"
}

fss_restore_native_backup_to_legacy() {
	local json_file="$1"
	local script_file="$2"
	local idx=0
	local node_id="" node_json=""
	local node_order_count=0
	local node_current_id="" node_failover_id="" current_pos="" failover_pos=""
	local key value
	local acl_default_ports=""

	[ -f "${json_file}" ] || return 1
	[ -z "${script_file}" ] && return 1
	jq -e '.format == "fancyss-backup" and (.schema_version | tostring) == "2"' "${json_file}" >/dev/null 2>&1 || return 1

	cat > "${script_file}" <<-EOF
#!/bin/sh
source /koolshare/scripts/base.sh
EOF

	jq -r '.global | to_entries[] | @base64' "${json_file}" | while IFS= read -r entry
	do
		[ -z "${entry}" ] && continue
		key=$(printf '%s' "${entry}" | base64 -d 2>/dev/null | jq -r '.key')
		value=$(printf '%s' "${entry}" | base64 -d 2>/dev/null | jq -r '.value')
		printf 'dbus set %s=%s\n' "${key}" "$(fss_shell_quote "${value}")" >> "${script_file}"
	done

	jq -r '.acl | to_entries[] | @base64' "${json_file}" | while IFS= read -r entry
	do
		[ -z "${entry}" ] && continue
		key=$(printf '%s' "${entry}" | base64 -d 2>/dev/null | jq -r '.key')
		value=$(printf '%s' "${entry}" | base64 -d 2>/dev/null | jq -r '.value')
		[ "${key}" = "ss_acl_default_port" ] && continue
		printf 'dbus set %s=%s\n' "${key}" "$(fss_shell_quote "${value}")" >> "${script_file}"
	done
	acl_default_ports=$(jq -r '.acl.ss_acl_default_ports // .acl.ss_acl_default_port // empty' "${json_file}")
	[ -n "${acl_default_ports}" ] && printf 'dbus set ss_acl_default_port=%s\n' "$(fss_shell_quote "${acl_default_ports}")" >> "${script_file}"

	node_current_id=$(jq -r '.node_current // empty' "${json_file}")
	node_failover_id=$(jq -r '.node_failover_backup // empty' "${json_file}")
	node_order_count=$(jq '.node_order | length' "${json_file}" 2>/dev/null)
	if [ -z "${node_order_count}" ] || [ "${node_order_count}" = "0" ];then
		jq -r '.nodes[]._id' "${json_file}" > "${script_file}.order"
	else
		jq -r '.node_order[]' "${json_file}" > "${script_file}.order"
	fi

	while IFS= read -r node_id
	do
		[ -z "${node_id}" ] && continue
		idx=$((idx + 1))
		[ "${node_current_id}" = "${node_id}" ] && current_pos="${idx}"
		[ "${node_failover_id}" = "${node_id}" ] && failover_pos="${idx}"
		node_json=$(jq -c --arg id "${node_id}" '.nodes[] | select(._id == $id)' "${json_file}" | sed -n '1p')
		[ -z "${node_json}" ] && continue
		printf '%s' "${node_json}" | fss_node_v2_to_legacy_script_lines "${idx}" >> "${script_file}"
	done < "${script_file}.order"

	[ -n "${current_pos}" ] && printf 'dbus set ssconf_basic_node=%s\n' "$(fss_shell_quote "${current_pos}")" >> "${script_file}"
	[ -n "${failover_pos}" ] && printf 'dbus set ss_failover_s4_3=%s\n' "$(fss_shell_quote "${failover_pos}")" >> "${script_file}"

	chmod +x "${script_file}"
	rm -f "${script_file}.order"
}

fss_restore_legacy_backup_sh_fast() {
	local script_file="$1"
	local tmp_dir capture_file global_file order_file node_dump_file
	local line payload key value field
	local node_id order_csv="" node_ts=""
	local node_b64=""
	local current_id="" failover_id="" next_id=1 max_id=0
	local global_count=0 acl_count=0 node_count=0 restored_nodes=0
	local acl_default_port_legacy=""
	local acl_default_ports_seen=0

	[ -f "${script_file}" ] || return 1
	tmp_dir=$(fss_mktemp_dir fss_restore_sh) || return 1
	capture_file="${tmp_dir}/kv.txt"
	global_file="${tmp_dir}/global.txt"
	order_file="${tmp_dir}/order.txt"
	node_dump_file="${tmp_dir}/nodes.dump"
	: > "${capture_file}"
	: > "${global_file}"
	: > "${order_file}"
	: > "${node_dump_file}"

	fss_capture_legacy_backup_sh "${script_file}" "${capture_file}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	[ -s "${capture_file}" ] || {
		rm -rf "${tmp_dir}"
		return 1
	}

	while IFS= read -r payload
	do
		[ -n "${payload}" ] || continue
		key=${payload%%=*}
		value=${payload#*=}
		[ -n "${key}" ] || continue
		[ "${payload}" != "${key}" ] || continue
		case "${key}" in
		ssconf_basic_name_*)
			node_id=${key##*_}
			field=${key#ssconf_basic_}
			field=${field%_"${node_id}"}
			printf '%s\0%s\0%s\0' "${node_id}" "${field}" "${value}" >> "${node_dump_file}"
			printf '%s\n' "${node_id}" >> "${order_file}"
			node_count=$((node_count + 1))
			;;
		ssconf_basic_node)
			current_id="${value}"
			;;
		ss_failover_s4_3)
			failover_id="${value}"
			;;
		ss_acl_default_ports)
			printf '%s=%s\n' "${key}" "${value}" >> "${global_file}"
			acl_default_ports_seen=1
			acl_count=$((acl_count + 1))
			;;
		ss_acl_default_port)
			acl_default_port_legacy="${value}"
			;;
		ssconf_basic_*_[0-9]*)
			node_id=${key##*_}
			field=${key#ssconf_basic_}
			field=${field%_"${node_id}"}
			printf '%s\0%s\0%s\0' "${node_id}" "${field}" "${value}" >> "${node_dump_file}"
			:
			;;
		ss_acl_*)
			printf '%s=%s\n' "${key}" "${value}" >> "${global_file}"
			acl_count=$((acl_count + 1))
			;;
		ss*)
			printf '%s=%s\n' "${key}" "${value}" >> "${global_file}"
			global_count=$((global_count + 1))
			;;
		esac
	done < "${capture_file}"

	if [ "${acl_default_ports_seen}" != "1" ] && [ -n "${acl_default_port_legacy}" ]; then
		printf 'ss_acl_default_ports=%s\n' "${acl_default_port_legacy}" >> "${global_file}"
		acl_count=$((acl_count + 1))
	fi

	if [ -s "${order_file}" ];then
		sort -n -u "${order_file}" -o "${order_file}"
		node_count=$(wc -l < "${order_file}")
	fi

	echo_date "检测到兼容SH备份：普通配置${global_count}项，ACL配置${acl_count}项，节点${node_count}个。"
	echo_date "开始恢复普通配置和ACL配置..."

	fss_clear_all_node_storage
	fss_clear_global_and_acl_storage
	while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		key=${line%%=*}
		value=${line#*=}
		dbus set "${key}=${value}"
	done < "${global_file}"
	fss_cleanup_acl_default_port_keys >/dev/null 2>&1
	echo_date "普通配置和ACL配置恢复完成！"

	if [ ! -s "${order_file}" ];then
		dbus set fss_data_schema=2
		fss_set_storage_schema_cache 2
		dbus set fss_node_next_id=1
		dbus set fss_data_migrated=1
		dbus remove fss_data_migration_notice
		dbus remove fss_data_migration_time
		dbus remove fss_data_legacy_snapshot
		dbus remove fss_data_migrating
		rm -rf "${tmp_dir}"
		return 0
	fi

	echo_date "开始恢复节点到新存储结构..."
	node_ts="$(fss_now_ts_ms)"
	fss_legacy_node_dump_to_v2_tsv "${node_dump_file}" "${order_file}" "restore-sh" "${node_ts}" > "${tmp_dir}/nodes.tsv" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	while IFS='	' read -r node_id node_b64
	do
		[ -n "${node_id}" ] || continue
		[ -n "${node_b64}" ] || continue
		dbus set "fss_node_${node_id}=${node_b64}"
		restored_nodes=$((restored_nodes + 1))
		if [ "${restored_nodes}" = "${node_count}" ] || [ $((restored_nodes % 50)) = 0 ];then
			echo_date "恢复节点进度：${restored_nodes}/${node_count}"
		fi
	done < "${tmp_dir}/nodes.tsv" || {
		rm -rf "${tmp_dir}"
		return 1
	}

	order_csv=$(tr '\n' ',' < "${order_file}" | sed 's/,$//')
	max_id=$(sed -n '$p' "${order_file}")
	[ -n "${max_id}" ] || max_id=0

	next_id=$((max_id + 1))
	dbus set fss_node_order="${order_csv}"
	if [ -n "${current_id}" ];then
		grep -Fxq "${current_id}" "${order_file}" || current_id="$(sed -n '1p' "${order_file}")"
	else
		current_id="$(sed -n '1p' "${order_file}")"
	fi
	if [ -n "${failover_id}" ];then
		grep -Fxq "${failover_id}" "${order_file}" || failover_id=""
	fi
	fss_set_current_node_id "${current_id}"
	fss_set_failover_node_id "${failover_id}"
	dbus set fss_node_next_id="${next_id}"
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2
	dbus set fss_data_migrated=1
	dbus remove fss_data_migration_notice
	dbus remove fss_data_migration_time
	dbus remove fss_data_legacy_snapshot
	dbus remove fss_data_migrating
	echo_date "节点恢复完成：${restored_nodes}个节点。"

	rm -rf "${tmp_dir}"
	return 0
}

fss_restore_native_backup_v2() {
	local json_file="$1"
	local tmp_dir node_order_file global_tsv acl_tsv nodes_tsv
	local node_id node_b64 current_id failover_id next_id max_id=0 restored_nodes=0
	local key value_b64 value
	local node_count=0 global_count=0 acl_count=0 node_ts=0

	[ -f "${json_file}" ] || return 1
	jq -e '.format == "fancyss-backup" and (.schema_version | tostring) == "2"' "${json_file}" >/dev/null 2>&1 || return 1

	tmp_dir=$(fss_mktemp_dir fss_restore) || return 1
	node_order_file="${tmp_dir}/order"
	global_tsv="${tmp_dir}/global.tsv"
	acl_tsv="${tmp_dir}/acl.tsv"
	nodes_tsv="${tmp_dir}/nodes.tsv"

	echo_date "JSON备份节点较多时可能耗时较长，请耐心等待..."
	echo_date "阶段1/4：校验备份结构..."
	jq -r '
		if ((.node_order // []) | length) > 0 then
			.node_order[]
		else
			.nodes[]._id // empty
		end
	' "${json_file}" | sed '/^$/d' | awk '!seen[$0]++' > "${node_order_file}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	node_count=$(wc -l < "${node_order_file}" 2>/dev/null)
	global_count=$(jq '(.global // {}) | length' "${json_file}" 2>/dev/null)
	acl_count=$(jq '(.acl // {}) | length' "${json_file}" 2>/dev/null)
	[ -n "${global_count}" ] || global_count=0
	[ -n "${acl_count}" ] || acl_count=0
	[ -n "${node_count}" ] || node_count=0
	echo_date "检测到JSON备份：普通配置${global_count}项，ACL配置${acl_count}项，节点${node_count}个。"

	echo_date "阶段2/4：恢复普通配置和ACL配置..."
	jq -r '
		.global // {}
		| to_entries[]?
		| [.key, ((.value | if type == "string" then . else tostring end) | @base64)]
		| @tsv
	' "${json_file}" > "${global_tsv}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	jq -r '
		.acl // {}
		| to_entries[]?
		| [.key, ((.value | if type == "string" then . else tostring end) | @base64)]
		| @tsv
	' "${json_file}" > "${acl_tsv}" || {
		rm -rf "${tmp_dir}"
		return 1
	}

	fss_clear_all_node_storage
	fss_clear_global_and_acl_storage

	while IFS='	' read -r key value_b64
	do
		[ -n "${key}" ] || continue
		value=$(fss_b64_decode "${value_b64}")
		dbus set "${key}=${value}"
	done < "${global_tsv}"

	while IFS='	' read -r key value_b64
	do
		[ -n "${key}" ] || continue
		value=$(fss_b64_decode "${value_b64}")
		dbus set "${key}=${value}"
	done < "${acl_tsv}"
	fss_cleanup_acl_default_port_keys >/dev/null 2>&1
	echo_date "普通配置和ACL配置恢复完成！"

	current_id=$(jq -r '.node_current // empty' "${json_file}")
	failover_id=$(jq -r '.node_failover_backup // empty' "${json_file}")
	next_id=$(jq -r '.node_next_id // empty' "${json_file}")
	node_ts=$(fss_now_ts_ms)

	if [ "${node_count}" -gt 0 ];then
		echo_date "阶段3/4：准备节点数据，共 ${node_count} 个节点..."
		jq -r \
			--argjson ts "${node_ts}" '
			def keep_common($k):
				$k == "group"
				or $k == "name"
				or $k == "mode"
				or $k == "type";
			def keep_type($type; $k):
				if $type == "0" then
					$k == "server" or $k == "port" or $k == "method" or $k == "password" or $k == "ss_obfs" or $k == "ss_obfs_host"
				elif $type == "1" then
					$k == "server" or $k == "port" or $k == "method" or $k == "password" or $k == "rss_protocol" or $k == "rss_protocol_param" or $k == "rss_obfs" or $k == "rss_obfs_param"
				elif $type == "3" then
					$k == "server" or $k == "port" or $k == "v2ray_uuid" or $k == "v2ray_alterid" or $k == "v2ray_security" or $k == "v2ray_network" or $k == "v2ray_headtype_tcp" or $k == "v2ray_headtype_kcp" or $k == "v2ray_kcp_seed" or $k == "v2ray_headtype_quic" or $k == "v2ray_grpc_mode" or $k == "v2ray_grpc_authority" or $k == "v2ray_network_path" or $k == "v2ray_network_host" or $k == "v2ray_network_security" or $k == "v2ray_network_security_ai" or $k == "v2ray_network_security_alpn_h2" or $k == "v2ray_network_security_alpn_http" or $k == "v2ray_network_security_sni" or $k == "v2ray_mux_concurrency" or $k == "v2ray_json" or $k == "v2ray_use_json" or $k == "v2ray_mux_enable"
				elif $type == "4" then
					$k == "server" or $k == "port" or $k == "xray_uuid" or $k == "xray_alterid" or $k == "xray_prot" or $k == "xray_encryption" or $k == "xray_flow" or $k == "xray_network" or $k == "xray_headtype_tcp" or $k == "xray_headtype_kcp" or $k == "xray_kcp_seed" or $k == "xray_headtype_quic" or $k == "xray_grpc_mode" or $k == "xray_grpc_authority" or $k == "xray_xhttp_mode" or $k == "xray_network_path" or $k == "xray_network_host" or $k == "xray_network_security" or $k == "xray_network_security_ai" or $k == "xray_network_security_alpn_h2" or $k == "xray_network_security_alpn_http" or $k == "xray_network_security_sni" or $k == "xray_pcs" or $k == "xray_vcn" or $k == "xray_fingerprint" or $k == "xray_publickey" or $k == "xray_shortid" or $k == "xray_spiderx" or $k == "xray_show" or $k == "xray_json" or $k == "xray_use_json"
				elif $type == "5" then
					$k == "server" or $k == "port" or $k == "trojan_ai" or $k == "trojan_uuid" or $k == "trojan_sni" or $k == "trojan_pcs" or $k == "trojan_vcn" or $k == "trojan_tfo" or $k == "trojan_plugin" or $k == "trojan_obfs" or $k == "trojan_obfshost" or $k == "trojan_obfsuri"
				elif $type == "6" then
					$k == "naive_prot" or $k == "naive_server" or $k == "naive_port" or $k == "naive_user" or $k == "naive_pass"
				elif $type == "7" then
					$k == "tuic_json"
				elif $type == "8" then
					$k == "hy2_server" or $k == "hy2_port" or $k == "hy2_pass" or $k == "hy2_up" or $k == "hy2_dl" or $k == "hy2_obfs" or $k == "hy2_obfs_pass" or $k == "hy2_sni" or $k == "hy2_pcs" or $k == "hy2_vcn" or $k == "hy2_ai" or $k == "hy2_tfo" or $k == "hy2_cg"
				elif $type == "9" then
					$k == "anytls_server" or $k == "anytls_port" or $k == "anytls_pass" or $k == "anytls_sni" or $k == "anytls_ai"
				else
					false
				end;
			def restore_source:
				if ((._source // "") != "") then
					.
				elif ((._profile_id // "") != "") then
					._source = "subscribe"
				elif ((._source_scope // "") != "" and (._source_scope // "") != "local") then
					._source = "subscribe"
				elif ((._airport_identity // "") != "" and (._airport_identity // "") != "local") then
					._source = "subscribe"
				elif ((._source_url_hash // "") != "") then
					._source = "subscribe"
				else
					._source = "restore"
				end;
			def prune:
				. as $root
				| (($root.type // "") | tostring) as $type
				| with_entries(select((.key | startswith("_")) or keep_common(.key) or keep_type($type; .key)));
			(.nodes | map({key: ((._id // "") | tostring), value: .}) | from_entries) as $nodes_map
			| ((.node_order // []) | map(tostring) | map(select(length > 0))) as $order0
			| ($order0 | if length > 0 then . else (.nodes | map((._id // "") | tostring) | map(select(length > 0))) end) as $order
			| $order[]
			| . as $id
			| ($nodes_map[$id] // empty)
			| with_entries(select(.value != "" and .value != null))
			| del(.server_ip, .latency, .ping)
				| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end
				| ._schema = 2
				| ._id = $id
				| ._rev = (((._rev // 0) | tonumber? // 0) + 1)
				| ._b64_mode = ((._b64_mode // "") | if . == "" then "raw" else . end)
				| ._updated_at = $ts
				| ._created_at = (((._created_at // $ts) | tonumber? // $ts) | if . < 1000000000000 then (. * 1000) else . end)
				| restore_source
				| prune
				| [$id, (tojson | @base64)] | @tsv
			' "${json_file}" > "${nodes_tsv}" || {
			rm -rf "${tmp_dir}"
			return 1
		}
		restored_nodes=$(wc -l < "${nodes_tsv}" 2>/dev/null)
		[ -n "${restored_nodes}" ] || restored_nodes=0
		[ "${restored_nodes}" = "${node_count}" ] || {
			rm -rf "${tmp_dir}"
			return 1
		}
	else
		: > "${nodes_tsv}"
	fi

	echo_date "阶段4/4：写入节点数据..."
	restored_nodes=0
	max_id=0
	while IFS='	' read -r node_id node_b64
	do
		[ -n "${node_id}" ] || continue
		[ -n "${node_b64}" ] || continue
		dbus set "fss_node_${node_id}=${node_b64}"
		restored_nodes=$((restored_nodes + 1))
		if [ "${node_id}" -gt "${max_id}" ] 2>/dev/null;then
			max_id="${node_id}"
		fi
		if [ "${restored_nodes}" = "1" ] || [ $((restored_nodes % 25)) = 0 ] || [ "${restored_nodes}" = "${node_count}" ];then
			echo_date "JSON节点恢复进度：${restored_nodes}/${node_count}"
		fi
	done < "${nodes_tsv}"

	if [ -z "${next_id}" ] || [ "${next_id}" -le "${max_id}" ] 2>/dev/null;then
		next_id=$((max_id + 1))
	fi
	[ "${node_count}" -gt 0 ] || next_id=1

	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2
	if [ "${node_count}" -gt 0 ];then
		dbus set fss_node_order="$(tr '\n' ',' < "${node_order_file}" | sed 's/,$//')"
		if [ -n "${current_id}" ];then
			grep -Fxq "${current_id}" "${node_order_file}" || current_id=$(sed -n '1p' "${node_order_file}")
		else
			current_id=$(sed -n '1p' "${node_order_file}")
		fi
		if [ -n "${failover_id}" ];then
			grep -Fxq "${failover_id}" "${node_order_file}" || failover_id=""
		fi
		fss_set_current_node_id "${current_id}"
		fss_set_failover_node_id "${failover_id}"
	else
		dbus remove fss_node_order
		fss_set_current_node_id ""
		fss_set_failover_node_id ""
	fi
	dbus set fss_node_next_id="${next_id}"
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	dbus set fss_data_migrated=1
	dbus remove fss_data_migration_notice
	dbus remove fss_data_migration_time
	dbus remove fss_data_legacy_snapshot
	dbus remove fss_data_migrating
	dbus set ss_basic_enable="0"
	echo_date "节点恢复完成：${restored_nodes}个节点。"

	rm -rf "${tmp_dir}"
	return 0
}
