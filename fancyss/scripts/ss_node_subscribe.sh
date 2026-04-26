#!/bin/sh

# fancyss subscribe script for asuswrt/merlin based router with software center
source /koolshare/scripts/base.sh
source /koolshare/scripts/ss_node_common.sh
[ -f /koolshare/scripts/ss_subscribe_profile_lib.sh ] && source /koolshare/scripts/ss_subscribe_profile_lib.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
LC_ALL=C
LANG=C
LOCK_FILE=/var/lock/node_subscribe.lock
LOG_FILE=/tmp/upload/ss_subscribe_log.txt
mkdir -p /tmp/upload >/dev/null 2>&1
DIR="/tmp/fancyss_subs"
LOCAL_NODES_SPL="$DIR/ss_nodes_spl.txt"
LOCAL_NODES_BAK="$DIR/ss_nodes_bak.txt"
LOCAL_SPLIT_META="$DIR/local_split_meta.tsv"
ACTIVE_SOURCE_TAGS="$DIR/active_source_tags.txt"
SUB_CHANGED_SOURCE_TAGS_FILE="$DIR/changed_source_tags.txt"
SUB_REMOVED_SOURCE_TAGS_FILE="$DIR/removed_source_tags.txt"
SCHEMA2_RAW_JSONL="$DIR/schema2_nodes_raw.txt"
SCHEMA2_EXPORT_JSONL="$DIR/schema2_nodes_export.txt"
SCHEMA2_BEFORE_EXPORT_JSONL="$DIR/schema2_nodes_before_rewrite.txt"
SUB_RAW_CACHE_DIR="/koolshare/configs/fancyss/subscribe_cache/raw"
SUB_PARSED_CACHE_DIR="/koolshare/configs/fancyss/subscribe_cache/parsed"
# 订阅缓存的 raw / parsed / meta 都放在持久化目录。
# 每次调整 meta 结构或缓存判定语义时，递增 schema 即可触发重建。
SUB_PARSED_CACHE_META_SCHEMA="2"
SUB_STORAGE_SCHEMA=""
SUB_SCHEMA2_NATIVE_INITIALIZED=0
NODES_SEQ=""
NODE_INDEX=""
SEQ_NU="0"
SUB_MODE=$(dbus get ssr_subscribe_mode)
[ -z "${SUB_MODE}" ] && SUB_MODE=2
HY2_UP_SPEED=$(dbus get ss_basic_hy2_up_speed)
HY2_DL_SPEED=$(dbus get ss_basic_hy2_dl_speed)
HY2_TFO_SWITCH=$(dbus get ss_basic_hy2_tfo_switch)
HY2_CG_OPT=$(dbus get ss_basic_hy2_cg_opt)
CURR_NODE=""
FAILOVER_NODE=""
CURR_NODE_NAME=""
CURR_NODE_TYPE=""
CURR_NODE_SERVER=""
CURR_NODE_PORT=""
CURR_NODE_IDENTITY=""
FAILOVER_NODE_NAME=""
FAILOVER_NODE_TYPE=""
FAILOVER_NODE_SERVER=""
FAILOVER_NODE_PORT=""
FAILOVER_NODE_IDENTITY=""
SUB_REWRITE_ALL=0
SUB_FAST_APPEND=0
SUB_FAST_APPEND_USED=0
SUB_FAST_APPEND_REUSE=1
SUB_LOCAL_CHANGED=0
SUB_HAS_FAILURE=0
SUB_BY_PROXY=$(dbus get ss_basic_online_links_proxy)
SUB_AI=$(dbus get ss_basic_sub_ai)
SUB_TOOL_NODE_LOG=$(dbus get ss_basic_sub_node_log)
SUB_KEEP_INFO_NODE=$(dbus get ss_basic_sub_keep_info_node)
[ -z "${SUB_BY_PROXY}" ] && SUB_BY_PROXY=0
[ -n "${SUB_TOOL_NODE_LOG}" ] || SUB_TOOL_NODE_LOG=0
[ -n "${SUB_KEEP_INFO_NODE}" ] || SUB_KEEP_INFO_NODE=0
KEY_WORDS_1=$(dbus get ss_basic_exclude | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_2=$(dbus get ss_basic_include | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_1_RAW=$(dbus get ss_basic_exclude | sed 's/,$//g')
KEY_WORDS_2_RAW=$(dbus get ss_basic_include | sed 's/,$//g')
SUB_ONLINE_URLS=""
SUB_ONLINE_URLS_READY=0
SUB_VERBOSE_NODE_LOG=1
LOCAL_SPLIT_META_VALID=0
alias urldecode='sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"'
SUB_WEBTEST_WARM_LOG="/tmp/upload/ss_webtest_cache.log"
SUB_SOURCE_URL_HASH=""
SUB_AIRPORT_IDENTITY=""
SUB_SOURCE_SCOPE=""
SUB_PAYLOAD_KIND=""
SUB_DOWNLOAD_FILENAME=""
NODE_TOOL_CONF_FILE="/koolshare/ss/rules/node-tool.conf"
SCHEMA2_REFERENCE_NOTICE_FILE="${DIR}/reference_notice.jsonl"
SUB_TOOL_DIFF_FILE_CURRENT=""
SUB_TOOL_DIFF_SUMMARY_FILE_CURRENT=""
SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT=""
SUB_NODE_TOOL_PLAN_FILE_CURRENT=""
SUB_REFERENCE_RESOLVED_IDENTITY=""
SUB_AIRPORT_SPECIAL_CHANGED=0
SUB_ACTIVE_PROFILE_ID=""
SUB_ACTIVE_PROFILE_NAME=""
SUB_ACTIVE_UA_MODE=""
SUB_ACTIVE_UA_PRESET=""
SUB_ACTIVE_UA_CUSTOM=""
SUB_LAST_ONLINE_GROUP=""
SUB_LAST_URL_HASH=""
SUB_LAST_DOWNLOAD_TOOL=""
SUB_LAST_DOWNLOAD_PATH=""
SUB_LAST_DOWNLOAD_MODE=""
SUB_LAST_DOWNLOAD_UA=""
SUB_LAST_DOWNLOAD_ERROR=""
SUB_SINGLE_PROFILE_SYNC=0

sub_init_storage_schema(){
	local schema=""
	local legacy_count="0"

	schema=$(dbus get fss_data_schema)
	if [ "${schema}" = "2" ];then
		fss_clear_legacy_nodes >/dev/null 2>&1 || true
		SUB_STORAGE_SCHEMA="2"
		return 0
	fi

	legacy_count=$(fss_legacy_node_count 2>/dev/null | sed -n '1p')
	[ -n "${legacy_count}" ] || legacy_count=0
	if [ "${legacy_count}" = "0" ];then
		fss_mark_native_schema2_storage >/dev/null 2>&1 || {
			dbus set fss_data_schema=2
			fss_set_storage_schema_cache 2 >/dev/null 2>&1 || true
			[ -n "$(dbus get fss_node_next_id)" ] || dbus set fss_node_next_id=1
			dbus remove fss_data_migration_notice
			dbus remove fss_data_migration_time
			dbus remove fss_data_legacy_snapshot
			dbus remove fss_data_migrating
		}
		SUB_STORAGE_SCHEMA="2"
		SUB_SCHEMA2_NATIVE_INITIALIZED=1
		return 0
	fi

	SUB_STORAGE_SCHEMA="1"
}

sub_now_epoch(){
	date +%s 2>/dev/null || echo 0
}

sub_elapsed_text(){
	local start="$1"
	local end=""
	end=$(sub_now_epoch)
	if [ -n "${start}" ] && [ -n "${end}" ] && [ "${start}" -gt "0" ] 2>/dev/null && [ "${end}" -ge "${start}" ] 2>/dev/null;then
		echo "$((end - start))s"
	else
		echo "未知"
	fi
}

sub_schedule_background_sync(){
	echo_date "💾节点数据已提交，后台同步磁盘缓存，不阻塞订阅窗口..."
	( sync >/dev/null 2>&1 ) &
}

sub_refresh_runtime_caches_async(){
	echo_date "⚙️节点运行缓存已失效，后台刷新直连域名/测速缓存；慢速设备可能需要几十秒，但不影响本次订阅完成。"
	(
		fss_refresh_node_direct_cache >/dev/null 2>&1
		fss_schedule_webtest_cache_warm "" "${SUB_WEBTEST_WARM_LOG}" >/dev/null 2>&1
	) &
}

sub_init_storage_schema

# 20230701: unset inherited hotplug/environment variables that may interfere with execution.
unset usb2jffs_time_hour
unset usb2jffs_week
unset usb2jffs_title
unset usb2jffs_day
unset usb2jffs_rsync
unset usb2jffs_sync
unset usb2jffs_inter_day
unset usb2jffs_inter_pre
unset usb2jffs_version
unset usb2jffs_mount_path
unset usb2jffs_inter_hour
unset usb2jffs_time_min
unset usb2jffs_inter_min
unset usb2jffs_backupfile_name
unset usb2jffs_backup_file
unset usb2jffs_mtd_jffs
unset usb2jffs_warn_2
unset ACTION
unset DEVICENAME
unset DEVNAME
unset DEVPATH
unset DEVTYPE
unset INTERFACE
unset PRODUCT
unset USBPORT
unset SUBSYSTEM
unset SEQNUM
unset MAJOR
unset MINOR
unset PERP_SVPID
unset SHLVL
unset TERM
unset PERP_BASE
unset HOME
unset PWD

sub_list_node_ids(){
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		printf '%s\n' "$(dbus get fss_node_order)" | tr ',' '\n' | sed '/^$/d'
	else
		dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -n
	fi
}

sub_get_online_urls(){
	if [ "${SUB_ONLINE_URLS_READY}" = "1" ];then
		printf '%s\n' "${SUB_ONLINE_URLS}" | sed '/^$/d'
		return 0
	fi
	SUB_ONLINE_URLS=$(dbus get ss_online_links | base64 -d | sed '/^$/d' | sed '/^#/d' | sed 's/^[[:space:]]//g' | sed 's/[[:space:]]$//g' | grep -E "^http" | sed 's/[[:space:]]/%20/g')
	SUB_ONLINE_URLS_READY=1
	printf '%s\n' "${SUB_ONLINE_URLS}" | sed '/^$/d'
}

sub_reset_active_profile_context() {
	SUB_ACTIVE_PROFILE_ID=""
	SUB_ACTIVE_PROFILE_NAME=""
	SUB_ACTIVE_UA_MODE=""
	SUB_ACTIVE_UA_PRESET=""
	SUB_ACTIVE_UA_CUSTOM=""
	SUB_BY_PROXY=$(dbus get ss_basic_online_links_proxy)
	SUB_AI=$(dbus get ss_basic_sub_ai)
	SUB_TOOL_NODE_LOG=$(dbus get ss_basic_sub_node_log)
	SUB_KEEP_INFO_NODE=$(dbus get ss_basic_sub_keep_info_node)
	[ -z "${SUB_BY_PROXY}" ] && SUB_BY_PROXY=0
	[ -n "${SUB_TOOL_NODE_LOG}" ] || SUB_TOOL_NODE_LOG=0
	[ -n "${SUB_KEEP_INFO_NODE}" ] || SUB_KEEP_INFO_NODE=0
	SUB_MODE=$(dbus get ssr_subscribe_mode)
	[ -z "${SUB_MODE}" ] && SUB_MODE=2
	HY2_UP_SPEED=$(dbus get ss_basic_hy2_up_speed)
	HY2_DL_SPEED=$(dbus get ss_basic_hy2_dl_speed)
	HY2_TFO_SWITCH=$(dbus get ss_basic_hy2_tfo_switch)
	HY2_CG_OPT=$(dbus get ss_basic_hy2_cg_opt)
	KEY_WORDS_1_RAW=$(dbus get ss_basic_exclude | sed 's/,$//g')
	KEY_WORDS_2_RAW=$(dbus get ss_basic_include | sed 's/,$//g')
	KEY_WORDS_1=$(printf '%s' "${KEY_WORDS_1_RAW}" | sed 's/,/|/g')
	KEY_WORDS_2=$(printf '%s' "${KEY_WORDS_2_RAW}" | sed 's/,/|/g')
}

sub_apply_active_profile_context() {
	local profile_id="$1"
	local profile_name="$2"
	local subscribe_mode="$3"
	local download_policy="$4"
	local ua_mode="$5"
	local ua_preset="$6"
	local ua_custom="$7"
	local exclude_raw="$8"
	local include_raw="$9"
	shift 9
	local allow_insecure="$1"
	local node_log="$2"
	local keep_info_node="$3"
	local hy2_up="$4"
	local hy2_dl="$5"
	local hy2_tfo_switch="$6"
	local hy2_cg_opt="$7"

	SUB_ACTIVE_PROFILE_ID="${profile_id}"
	SUB_ACTIVE_PROFILE_NAME="${profile_name}"
	SUB_MODE="${subscribe_mode}"
	[ -n "${SUB_MODE}" ] || SUB_MODE=2
	case "${download_policy}" in
	proxy)
		SUB_BY_PROXY=1
		;;
	direct)
		SUB_BY_PROXY=2
		;;
	*)
		SUB_BY_PROXY=0
		;;
	esac
	SUB_ACTIVE_UA_MODE="${ua_mode}"
	SUB_ACTIVE_UA_PRESET="${ua_preset}"
	SUB_ACTIVE_UA_CUSTOM="${ua_custom}"
	[ "${allow_insecure}" = "true" ] && SUB_AI=1 || SUB_AI=0
	[ "${node_log}" = "true" ] && SUB_TOOL_NODE_LOG=1 || SUB_TOOL_NODE_LOG=0
	[ "${keep_info_node}" = "true" ] && SUB_KEEP_INFO_NODE=1 || SUB_KEEP_INFO_NODE=0
	KEY_WORDS_1_RAW="$(printf '%s' "${exclude_raw}" | sed 's/,$//g')"
	KEY_WORDS_2_RAW="$(printf '%s' "${include_raw}" | sed 's/,$//g')"
	KEY_WORDS_1="$(printf '%s' "${KEY_WORDS_1_RAW}" | sed 's/,/|/g')"
	KEY_WORDS_2="$(printf '%s' "${KEY_WORDS_2_RAW}" | sed 's/,/|/g')"
	HY2_UP_SPEED="${hy2_up}"
	HY2_DL_SPEED="${hy2_dl}"
	HY2_TFO_SWITCH="${hy2_tfo_switch}"
	[ -n "${HY2_TFO_SWITCH}" ] || HY2_TFO_SWITCH=2
	HY2_CG_OPT="${hy2_cg_opt}"
	[ -n "${HY2_CG_OPT}" ] || HY2_CG_OPT="bbr"
}

sub_get_online_url_count(){
	sub_get_online_urls | wc -l
}

sub_collect_active_link_hashes_from_profiles_file() {
	local output_file="$1"
	local profiles_file="$2"
	local profile_url=""

	[ -n "${output_file}" ] || return 1
	[ -f "${profiles_file}" ] || return 1
	: > "${output_file}"
	while IFS='	' read -r _profile_id _profile_name profile_url _
	do
		[ -n "${profile_url}" ] || continue
		printf '%s' "${profile_url}" | md5sum | awk '{print $1}' >> "${output_file}"
		printf '\n' >> "${output_file}"
	done < "${profiles_file}"
}

sub_prepare_enabled_profiles_file() {
	local output_file="$1"
	local selected_id="${SUB_SELECTED_PROFILE_ID:-$(dbus get ${SUB_PROFILE_TMP_SYNC_ID_KEY})}"
	local tmp_file=""

	[ -n "${output_file}" ] || return 1
	subprof_collect_enabled_profiles_tsv "${output_file}" >/dev/null 2>&1 || return 1
	if [ -n "${selected_id}" ]; then
		tmp_file="${output_file}.tmp.$$"
		awk -F '\t' -v selected_id="${selected_id}" '$1 == selected_id {print}' "${output_file}" > "${tmp_file}" 2>/dev/null || true
		mv -f "${tmp_file}" "${output_file}"
	fi
	[ -s "${output_file}" ]
}

sub_pick_jq() {
	if [ -x "/koolshare/bin/jq" ]; then
		printf '%s\n' "/koolshare/bin/jq"
		return 0
	fi
	command -v jq 2>/dev/null
}

pick_sub_get() {
	local sub_get_path=""
	sub_get_path="$(type sub-get 2>/dev/null | awk '{print $NF}' | sed -n '1p')"
	if [ -n "${sub_get_path}" ]; then
		if "${sub_get_path}" version >/dev/null 2>&1; then
			printf '%s\n' "${sub_get_path}"
			return 0
		fi
	fi
	if [ -x "/koolshare/bin/sub-get" ]; then
		if /koolshare/bin/sub-get version >/dev/null 2>&1; then
			printf '%s\n' "/koolshare/bin/sub-get"
			return 0
		fi
	fi
	return 1
}

sub_get_supports_command() {
	local sub_get_bin="$1"
	local command_name="$2"
	[ -n "${sub_get_bin}" ] || return 1
	[ -n "${command_name}" ] || return 1
	"${sub_get_bin}" --help 2>&1 | grep -Eq "^[[:space:]]*sub-get[[:space:]]+${command_name}([[:space:]]|$)"
}

sub_reset_download_trace() {
	SUB_LAST_DOWNLOAD_TOOL=""
	SUB_LAST_DOWNLOAD_PATH=""
	SUB_LAST_DOWNLOAD_MODE=""
	SUB_LAST_DOWNLOAD_UA=""
	SUB_LAST_DOWNLOAD_ERROR=""
}

sub_write_sub_get_plan() {
	local output_file="$1"
	local url="$2"
	local ua="$3"
	local policy="$4"
	local profile_id="$5"
	local profile_name="$6"
	local sub_get_jq=""

	[ -n "${output_file}" ] || return 1
	sub_get_jq="$(sub_pick_jq)" || return 1
	"${sub_get_jq}" -cn \
		--arg url "${url}" \
		--arg ua "${ua}" \
		--arg policy "${policy}" \
		--arg profile_id "${profile_id}" \
		--arg profile_name "${profile_name}" \
		'{
			version: 1,
			url: $url,
			policy: $policy,
			profile: {
				id: $profile_id,
				name: $profile_name
			},
			ua: {
				value: $ua
			}
		}' > "${output_file}" 2>/dev/null
}

sub_get_source_domain_from_url(){
	local sub_url="$1"
	[ -n "${sub_url}" ] || return 1
	sub_url=$(echo "${sub_url}" | sed 's/%20/ /g')
	get_domain_name "${sub_url}"
}

sub_get_source_tag_from_domain(){
	local domain_name="$1"
	[ -n "${domain_name}" ] || return 1
	printf '%s' "${domain_name}" | md5sum | awk '{print substr($1, 1, 4)}'
}

sub_get_source_alias_tag(){
	local source_tag="$1"
	local alias_tag=""
	[ -n "${source_tag}" ] || return 1
	alias_tag=$(dbus get ss_online_hash_${source_tag})
	if [ -n "${alias_tag}" ];then
		echo "${alias_tag}"
	else
		echo "${source_tag}"
	fi
}

sub_get_source_tag_from_url(){
	local domain_name
	domain_name=$(sub_get_source_domain_from_url "$1")
	[ -n "${domain_name}" ] || return 1
	sub_get_source_alias_tag "$(sub_get_source_tag_from_domain "${domain_name}")"
}

sub_build_airport_identity(){
	local label="$1"
	local fallback="$2"
	fss_identity_slugify "${label}" "${fallback}"
}

sub_build_source_scope(){
	local airport_identity="$1"
	local short_url_hash="$2"
	local scope="${airport_identity}"
	[ -n "${short_url_hash}" ] && scope="${scope}_${short_url_hash}"
	printf '%s' "${scope}"
}

sub_rewrite_identity_fields_for_file(){
	local file_path="$1"
	local airport_label="$2"
	local source_tag="$3"
	local short_url_hash="$4"
	local source_type="$5"
	local airport_identity=""
	local source_scope=""
	local tmp_file=""

	[ -f "${file_path}" ] || return 1
	[ -n "${source_type}" ] || source_type="subscribe"
	if [ "${source_type}" = "subscribe" ];then
		airport_identity=$(sub_build_airport_identity "${airport_label}" "${source_tag}")
		source_scope=$(sub_build_source_scope "${airport_identity}" "${short_url_hash}")
	else
		airport_identity="local"
		source_scope="local"
		short_url_hash=""
	fi
	if sub_file_has_identity_fields "${file_path}" && sub_file_identity_scope_matches "${file_path}" "${airport_identity}" "${source_scope}" "${short_url_hash}";then
		return 0
	fi
	tmp_file="${file_path}.identity.$$"
	fss_enrich_node_identity_file "${file_path}" "${tmp_file}" "${airport_identity}" "${source_scope}" "${short_url_hash}" "${source_type}" || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${file_path}"
	return 0
}

sub_get_legacy_tag_from_url(){
	local sub_url="$1"
	[ -n "${sub_url}" ] || return 1
	sub_url=$(echo "${sub_url}" | sed 's/%20/ /g')
	printf '%s' "${sub_url}" | md5sum | awk '{print substr($1, 1, 4)}'
}

sub_reset_schema2_cache(){
	rm -f "${SCHEMA2_RAW_JSONL}" "${SCHEMA2_EXPORT_JSONL}" "${SCHEMA2_BEFORE_EXPORT_JSONL}"
}

sub_mark_active_source_tag(){
	local source_tag="$1"
	[ -n "${source_tag}" ] || return 1
	mkdir -p "${DIR}" >/dev/null 2>&1
	touch "${ACTIVE_SOURCE_TAGS}"
	grep -Fxq "${source_tag}" "${ACTIVE_SOURCE_TAGS}" 2>/dev/null || echo "${source_tag}" >> "${ACTIVE_SOURCE_TAGS}"
}

sub_mark_changed_source_tag(){
	local source_tag="$1"
	[ -n "${source_tag}" ] || return 1
	[ "${source_tag}" = "user" ] && return 0
	mkdir -p "${DIR}" >/dev/null 2>&1
	touch "${SUB_CHANGED_SOURCE_TAGS_FILE}"
	grep -Fxq "${source_tag}" "${SUB_CHANGED_SOURCE_TAGS_FILE}" 2>/dev/null || echo "${source_tag}" >> "${SUB_CHANGED_SOURCE_TAGS_FILE}"
}

sub_mark_removed_source_tag(){
	local source_tag="$1"
	[ -n "${source_tag}" ] || return 1
	[ "${source_tag}" = "user" ] && return 0
	mkdir -p "${DIR}" >/dev/null 2>&1
	touch "${SUB_REMOVED_SOURCE_TAGS_FILE}"
	grep -Fxq "${source_tag}" "${SUB_REMOVED_SOURCE_TAGS_FILE}" 2>/dev/null || echo "${source_tag}" >> "${SUB_REMOVED_SOURCE_TAGS_FILE}"
}

sub_get_single_changed_source_tag(){
	local uniq_file="${SUB_CHANGED_SOURCE_TAGS_FILE}.uniq.$$"
	[ -s "${SUB_CHANGED_SOURCE_TAGS_FILE}" ] || return 1
	sort -u "${SUB_CHANGED_SOURCE_TAGS_FILE}" > "${uniq_file}" 2>/dev/null || {
		rm -f "${uniq_file}"
		return 1
	}
	[ "$(wc -l < "${uniq_file}" | tr -d ' ')" = "1" ] || {
		rm -f "${uniq_file}"
		return 1
	}
	sed -n '1p' "${uniq_file}"
	rm -f "${uniq_file}"
}

sub_find_group_hash_by_label(){
	local group_label="$1"
	local local_match=""
	local dbus_match=""
	local match_count

	[ -n "${group_label}" ] || return 1
	if [ -s "${LOCAL_SPLIT_META}" ];then
		local_match=$(awk -F '\t' -v label="${group_label}" '$4 == label && $3 != "" && $3 != "null" && $3 != "user" {print $3}' "${LOCAL_SPLIT_META}" | sort -u)
		match_count=$(printf '%s\n' "${local_match}" | sed '/^$/d' | wc -l)
		if [ "${match_count}" = "1" ];then
			printf '%s\n' "${local_match}" | sed -n '1p'
			return 0
		fi
	fi
	dbus_match=$(dbus list ss_online_group_ 2>/dev/null | while IFS='=' read -r key value
	do
		[ -n "${key}" ] || continue
		[ "${value}" = "${group_label}" ] && echo "${key#ss_online_group_}"
	done | sort -u)
	match_count=$(printf '%s\n' "${dbus_match}" | sed '/^$/d' | wc -l)
	if [ "${match_count}" = "1" ];then
		printf '%s\n' "${dbus_match}" | sed -n '1p'
		return 0
	fi
	return 1
}

sub_register_source_identity(){
	local raw_tag="$1"
	local canonical_tag="$2"
	local group_label="$3"
	[ -n "${raw_tag}" ] || return 1
	[ -n "${canonical_tag}" ] || return 1
	dbus set ss_online_hash_${raw_tag}="${canonical_tag}"
	[ -n "${group_label}" ] && dbus set ss_online_group_${canonical_tag}="${group_label}"
}

sub_prune_source_identity(){
	local active_file="$1"
	local line key value canonical_tag
	[ -s "${active_file}" ] || return 0
	while IFS= read -r line
	do
		key="${line%%=*}"
		[ -n "${key}" ] || continue
		canonical_tag="${key#ss_online_group_}"
		grep -Fxq "${canonical_tag}" "${active_file}" || dbus remove "${key}"
	done <<-EOF
$(dbus list ss_online_group_ 2>/dev/null)
EOF
	while IFS= read -r line
	do
		key="${line%%=*}"
		value="${line#*=}"
		[ -n "${key}" ] || continue
		[ -n "${value}" ] || {
			dbus remove "${key}"
			continue
		}
		grep -Fxq "${value}" "${active_file}" || dbus remove "${key}"
	done <<-EOF
$(dbus list ss_online_hash_ 2>/dev/null)
	EOF
}

sub_collect_active_link_hashes(){
	local output_file="$1"
	local online_urls="$2"
	local url

	[ -n "${output_file}" ] || return 1
	: > "${output_file}"
	printf '%s\n' "${online_urls}" | sed '/^$/d' | while IFS= read -r url
	do
		[ -n "${url}" ] || continue
		echo "${url}" | md5sum | awk '{print $1}'
	done | sort -u > "${output_file}"
}

sub_prune_subscribe_cache(){
	local keep_hash_file="$1"
	local raw_removed=0 parsed_removed=0 cache_path cache_name cache_hash

	[ -s "${keep_hash_file}" ] || return 0
	mkdir -p "${SUB_RAW_CACHE_DIR}" "${SUB_PARSED_CACHE_DIR}" >/dev/null 2>&1

	for cache_path in "${SUB_RAW_CACHE_DIR}"/sub_*.txt
	do
		[ -e "${cache_path}" ] || continue
		cache_name=$(basename "${cache_path}")
		cache_hash="${cache_name#sub_}"
		cache_hash="${cache_hash%.txt}"
		if ! grep -Fxq "${cache_hash}" "${keep_hash_file}";then
			rm -f "${cache_path}"
			raw_removed=$((raw_removed + 1))
		fi
	done

	for cache_path in "${SUB_PARSED_CACHE_DIR}"/sub_*
	do
		[ -e "${cache_path}" ] || continue
		cache_name=$(basename "${cache_path}")
		cache_hash="${cache_name#sub_}"
		cache_hash="${cache_hash%.txt}"
		cache_hash="${cache_hash%.meta}"
		if ! grep -Fxq "${cache_hash}" "${keep_hash_file}";then
			rm -f "${SUB_PARSED_CACHE_DIR}/sub_${cache_hash}.txt" "${SUB_PARSED_CACHE_DIR}/sub_${cache_hash}.meta"
			parsed_removed=$((parsed_removed + 1))
		fi
	done

	if [ "${raw_removed}" -gt "0" ] || [ "${parsed_removed}" -gt "0" ];then
		echo_date "🧹清理过期订阅缓存：raw ${raw_removed} 份，parsed ${parsed_removed} 份。"
	fi
}

sub_clear_subscribe_cache(){
	local raw_removed parsed_removed
	mkdir -p "${SUB_RAW_CACHE_DIR}" "${SUB_PARSED_CACHE_DIR}" >/dev/null 2>&1
	raw_removed=$(find "${SUB_RAW_CACHE_DIR}" -type f -name 'sub_*.txt' | wc -l)
	parsed_removed=$(find "${SUB_PARSED_CACHE_DIR}" -type f \( -name 'sub_*.txt' -o -name 'sub_*.meta' \) | wc -l)
	rm -f "${SUB_RAW_CACHE_DIR}"/sub_*.txt "${SUB_PARSED_CACHE_DIR}"/sub_*.txt "${SUB_PARSED_CACHE_DIR}"/sub_*.meta 2>/dev/null
	if [ "${raw_removed}" -gt "0" ] || [ "${parsed_removed}" -gt "0" ];then
		echo_date "🧹已清空订阅缓存：raw ${raw_removed} 份，parsed ${parsed_removed} 个文件。"
	fi
}

sub_retag_online_file(){
	local file_path="$1"
	local old_tag="$2"
	local new_tag="$3"
	local tmp_file

	[ -f "${file_path}" ] || return 1
	[ -n "${old_tag}" ] || return 1
	[ -n "${new_tag}" ] || return 1
	[ "${old_tag}" = "${new_tag}" ] && return 0
	tmp_file="${file_path}.tmp"
	jq -c --arg old "_${old_tag}" --arg new "_${new_tag}" '
		if ((.group // "") | endswith($old)) then
			.group |= sub(($old + "$"); $new)
		else
			.
		end
	' "${file_path}" > "${tmp_file}" || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${file_path}"
}

sub_canonicalize_online_source(){
	local sub_count="$1"
	local raw_tag="$2"
	local online_group="$3"
	local old_file new_file canonical_tag

	[ -n "${sub_count}" ] || return 1
	[ -n "${raw_tag}" ] || return 1
	canonical_tag=$(sub_find_group_hash_by_label "${online_group}" 2>/dev/null)
	[ -n "${canonical_tag}" ] || canonical_tag="${raw_tag}"
	old_file="${DIR}/online_${sub_count}_${raw_tag}.txt"
	if [ "${canonical_tag}" != "${raw_tag}" ] && [ -f "${old_file}" ];then
		sub_retag_online_file "${old_file}" "${raw_tag}" "${canonical_tag}" || return 1
		new_file="${DIR}/online_${sub_count}_${canonical_tag}.txt"
		rm -f "${new_file}"
		mv -f "${old_file}" "${new_file}"
	fi
	echo "${canonical_tag}"
}

sub_get_raw_cache_file(){
	local sub_hash="$1"
	[ -n "${sub_hash}" ] || return 1
	mkdir -p "${SUB_RAW_CACHE_DIR}" >/dev/null 2>&1
	echo "${SUB_RAW_CACHE_DIR}/sub_${sub_hash}.txt"
}

sub_get_parsed_cache_file(){
	local sub_hash="$1"
	[ -n "${sub_hash}" ] || return 1
	mkdir -p "${SUB_PARSED_CACHE_DIR}" >/dev/null 2>&1
	echo "${SUB_PARSED_CACHE_DIR}/sub_${sub_hash}.txt"
}

sub_get_parsed_cache_meta_file(){
	local sub_hash="$1"
	[ -n "${sub_hash}" ] || return 1
	mkdir -p "${SUB_PARSED_CACHE_DIR}" >/dev/null 2>&1
	echo "${SUB_PARSED_CACHE_DIR}/sub_${sub_hash}.meta"
}

sub_get_effective_sub_ai(){
	local raw_sub_ai="$1"
	[ -n "${raw_sub_ai}" ] || raw_sub_ai="0"
	echo "${raw_sub_ai}"
}

sub_get_effective_hy2_context(){
	local raw_hy2_up="$1"
	local raw_hy2_dl="$2"
	local raw_hy2_tfo="$3"
	local raw_hy2_cg="$4"
	local eff_hy2_up eff_hy2_dl eff_hy2_tfo eff_hy2_cg

	eff_hy2_up="${raw_hy2_up}"
	eff_hy2_dl="${raw_hy2_dl}"
	eff_hy2_tfo="${raw_hy2_tfo}"
	[ -n "${eff_hy2_tfo}" ] || eff_hy2_tfo="2"

	# hy2 只有同时配置上下行带宽时，这两个值和 congestion 才真正影响最终节点内容。
	if [ -z "${eff_hy2_up}" ] && [ -n "${eff_hy2_dl}" ];then
		eff_hy2_dl=""
	elif [ -n "${eff_hy2_up}" ] && [ -z "${eff_hy2_dl}" ];then
		eff_hy2_up=""
	fi

	if [ -z "${eff_hy2_up}" ] && [ -z "${eff_hy2_dl}" ];then
		eff_hy2_cg="bbr"
	else
		eff_hy2_cg="${raw_hy2_cg}"
	fi

	printf '%s\n%s\n%s\n%s\n' "${eff_hy2_up}" "${eff_hy2_dl}" "${eff_hy2_tfo}" "${eff_hy2_cg}"
}

sub_get_filter_signature(){
	# 这里虽然函数名还叫 filter_signature，但实际表示的是“影响订阅解析结果的上下文签名”。
	# 这里记录的是“最终会影响订阅节点内容”的有效上下文，而不是原始 dbus 输入值。
	# 这样可以避免某些等价配置（例如 hy2 只填了单边带宽）导致的误判重解析。
	local effective_sub_ai effective_hy2_up effective_hy2_dl effective_hy2_tfo effective_hy2_cg
	effective_sub_ai=$(sub_get_effective_sub_ai "${SUB_AI}")
	{
		read -r effective_hy2_up
		read -r effective_hy2_dl
		read -r effective_hy2_tfo
		read -r effective_hy2_cg
	} <<-EOF
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "${HY2_CG_OPT}")
	EOF
	printf '%s\n' \
		"exclude=${KEY_WORDS_1_RAW}" \
		"include=${KEY_WORDS_2_RAW}" \
		"sub_mode=${SUB_MODE}" \
		"sub_ai=${effective_sub_ai}" \
		"keep_info_node=${SUB_KEEP_INFO_NODE}" \
		"hy2_up=${effective_hy2_up}" \
		"hy2_dl=${effective_hy2_dl}" \
		"hy2_tfo_switch=${effective_hy2_tfo}" \
		"hy2_cg_opt=${effective_hy2_cg}" \
		| md5sum | awk '{print $1}'
}

pick_sub_tool(){
	if command -v sub-tool >/dev/null 2>&1; then
		if "$(command -v sub-tool)" version >/dev/null 2>&1; then
			command -v sub-tool
			return 0
		fi
	fi
	if [ -x "/koolshare/bin/sub-tool" ];then
		if /koolshare/bin/sub-tool version >/dev/null 2>&1; then
			echo "/koolshare/bin/sub-tool"
			return 0
		fi
	fi
	return 1
}

pick_node_tool(){
	if command -v node-tool >/dev/null 2>&1; then
		if "$(command -v node-tool)" version >/dev/null 2>&1; then
			command -v node-tool
			return 0
		fi
	fi
	if [ -x "/koolshare/bin/node-tool" ];then
		if /koolshare/bin/node-tool version >/dev/null 2>&1; then
			echo "/koolshare/bin/node-tool"
			return 0
		fi
	fi
	return 1
}

node_tool_supports_command(){
	local node_tool="$1"
	local command_name="$2"
	[ -n "${node_tool}" ] || return 1
	[ -n "${command_name}" ] || return 1
	"${node_tool}" --help 2>&1 | grep -Eq "^[[:space:]]*node-tool[[:space:]]+${command_name}([[:space:]]|$)"
}

pick_node_tool_command(){
	local command_name="$1"
	local node_tool=""
	[ -n "${command_name}" ] || return 1
	node_tool="$(pick_node_tool 2>/dev/null)" || return 1
	node_tool_supports_command "${node_tool}" "${command_name}" || return 1
	printf '%s\n' "${node_tool}"
}

sub_tool_inspect_file(){
	local file_path="$1"
	local output_file="$2"
	local sub_tool=""
	[ -f "${file_path}" ] || return 1
	[ -n "${output_file}" ] || return 1
	sub_tool="$(pick_sub_tool 2>/dev/null)" || return 1
	"${sub_tool}" inspect --input "${file_path}" > "${output_file}" 2>/dev/null
}

sub_inspect_json_field(){
	local field_name="$1"
	local json_file="$2"
	[ -n "${field_name}" ] || return 1
	[ -f "${json_file}" ] || return 1
	sed -n "s/.*\"${field_name}\":\"\\([^\"]*\\)\".*/\\1/p" "${json_file}" | sed -n '1p'
}

sub_payload_preview(){
	local file_path="$1"
	[ -f "${file_path}" ] || return 0
	head -c 180 "${file_path}" 2>/dev/null | tr '\r\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

sub_url_scheme(){
	local url="$1"
	printf '%s' "${url}" | sed -n 's#^\([A-Za-z][A-Za-z0-9+.-]*\)://.*#\1#p' | sed -n '1p'
}

sub_url_origin(){
	local url="$1"
	printf '%s' "${url}" | sed -n 's#^\([A-Za-z][A-Za-z0-9+.-]*://[^/]*\).*#\1#p' | sed -n '1p'
}

sub_header_file_path(){
	local short_hash="$1"
	[ -n "${short_hash}" ] || return 1
	printf '%s\n' "${DIR}/sub_file_header_${short_hash}.txt"
}

sub_conf_file_exists(){
	[ -s "${NODE_TOOL_CONF_FILE}" ]
}

sub_conf_lookup_domain_airport_label(){
	local domain_name="$1"
	[ -n "${domain_name}" ] || return 1
	sub_conf_file_exists || return 1
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

sub_conf_lookup_clash_prefix_airport_label(){
	local filename="$1"
	local basename=""
	[ -n "${filename}" ] || return 1
	sub_conf_file_exists || return 1
	basename=$(printf '%s' "${filename}" | sed 's#^.*/##' | sed 's/\.[^.]\+$//')
	[ -n "${basename}" ] || return 1
	awk -v filename="${basename}" '
		BEGIN {
			target = tolower(filename)
			best_len = -1
			best = ""
		}
		/^[[:space:]]*#/ || NF < 3 { next }
		tolower($1) == "clash_file_prefix" || tolower($1) == "clash_file_perfix" {
			prefix = $2
			lower_prefix = tolower(prefix)
			if (index(target, lower_prefix) == 1 && length(prefix) > best_len) {
				$1 = ""
				$2 = ""
				sub(/^[[:space:]]+/, "")
				best = $0
				best_len = length(prefix)
			}
		}
		END {
			if (best != "") print best
		}
	' "${NODE_TOOL_CONF_FILE}" 2>/dev/null | sed -n '1p'
}

sub_extract_filename_from_header_file(){
	local short_hash="$1"
	local header_file=""
	local header_line=""
	local file_name=""
	[ -n "${short_hash}" ] || return 1
	header_file="$(sub_header_file_path "${short_hash}")" || return 1
	[ -f "${header_file}" ] || return 1
	header_line=$(tr -d '\r' < "${header_file}" | grep -i '^content-disposition:' | tail -n1)
	[ -n "${header_line}" ] || return 1
	file_name=$(printf '%s\n' "${header_line}" | sed -n "s/.*[Ff][Ii][Ll][Ee][Nn][Aa][Mm][Ee]\*=[Uu][Tt][Ff]-8''\\([^;]*\\).*/\\1/p" | sed -n '1p')
	if [ -n "${file_name}" ];then
		printf '%s' "${file_name}" | urldecode
		return 0
	fi
	file_name=$(printf '%s\n' "${header_line}" | sed -n 's/.*[Ff][Ii][Ll][Ee][Nn][Aa][Mm][Ee]="\([^"]*\)".*/\1/p' | sed -n '1p')
	[ -n "${file_name}" ] || file_name=$(printf '%s\n' "${header_line}" | sed -n 's/.*[Ff][Ii][Ll][Ee][Nn][Aa][Mm][Ee]=\([^;[:space:]]*\).*/\1/p' | sed -n '1p')
	[ -n "${file_name}" ] || return 1
	printf '%s\n' "${file_name}"
}

sub_airport_profile_match_node_domain_dns(){
	local airport_identity="$1"
	local payload_kind="$2"
	[ -n "${airport_identity}" ] || return 1
	[ -n "${payload_kind}" ] || return 1
	[ -f "${FSS_AIRPORT_PROFILE_FILE}" ] || return 1
	jq -e --arg airport_identity "${airport_identity}" --arg payload_kind "${payload_kind}" '
		(.profiles // [])[]
		| select((.airport_identity // "") == $airport_identity)
		| select(((.match.payload_kinds // []) | length) == 0 or ((.match.payload_kinds // []) | index($payload_kind)))
		| select((.specials.node_domain_dns.extractor // "") != "")
	' "${FSS_AIRPORT_PROFILE_FILE}" >/dev/null 2>&1
}

sub_airport_profile_get_node_domain_dns_value(){
	local airport_identity="$1"
	local payload_kind="$2"
	local field="$3"
	[ -n "${airport_identity}" ] || return 1
	[ -n "${payload_kind}" ] || return 1
	[ -n "${field}" ] || return 1
	[ -f "${FSS_AIRPORT_PROFILE_FILE}" ] || return 1
	jq -r --arg airport_identity "${airport_identity}" --arg payload_kind "${payload_kind}" --arg field "${field}" '
		(.profiles // [])[]
		| select((.airport_identity // "") == $airport_identity)
		| select(((.match.payload_kinds // []) | length) == 0 or ((.match.payload_kinds // []) | index($payload_kind)))
		| .specials.node_domain_dns[$field] // empty
	' "${FSS_AIRPORT_PROFILE_FILE}" 2>/dev/null | sed -n '1p'
}

sub_extract_clash_nameserver_lines(){
	local file_path="$1"
	[ -f "${file_path}" ] || return 1
	awk '
		function ltrim(s){ sub(/^[ \t]+/, "", s); return s }
		function rtrim(s){ sub(/[ \t]+$/, "", s); return s }
		function trim(s){ s = ltrim(s); s = rtrim(s); return s }
		function emit(v){
			v = trim(v)
			gsub(/^["'\'']+|["'\'']+$/, "", v)
			if (v != "") print v
		}
		{
			line = $0
			sub(/\r$/, "", line)
			if (line ~ /^[[:space:]]*#/) next
			pos = match(line, /[^ ]/)
			if (pos == 0) next
			indent = pos - 1
			trimmed = trim(line)

			if (state == "" && trimmed == "dns:") {
				state = "dns"
				dns_indent = indent
				next
			}
			if (state == "dns" && indent <= dns_indent && trimmed != "dns:") {
				state = ""
			}
			if (state == "") next

			if (state == "dns") {
				if (trimmed ~ /^nameserver:[[:space:]]*\[/) {
					inline = trimmed
					sub(/^nameserver:[[:space:]]*\[/, "", inline)
					sub(/\][[:space:]]*$/, "", inline)
					n = split(inline, arr, /,/)
					for (i = 1; i <= n; i++) emit(arr[i])
					next
				}
				if (trimmed == "nameserver:") {
					state = "nameserver"
					ns_indent = indent
					next
				}
				next
			}

			if (state == "nameserver") {
				if (indent <= ns_indent) {
					state = "dns"
				}
				if (state == "nameserver" && trimmed ~ /^-[[:space:]]*/) {
					item = trimmed
					sub(/^-[[:space:]]*/, "", item)
					emit(item)
					next
				}
			}
		}
	' "${file_path}" 2>/dev/null
}

sub_extract_airport_dns_urls_to_file(){
	local payload_file="$1"
	local extractor="$2"
	local output_file="$3"
	[ -f "${payload_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	case "${extractor}" in
	clash.nameserver)
		sub_extract_clash_nameserver_lines "${payload_file}" | sed '/^$/d' | sort -u > "${output_file}"
		;;
	*)
		rm -f "${output_file}"
		return 1
		;;
	esac
	[ -s "${output_file}" ]
}

sub_write_airport_special_conf(){
	local airport_identity="$1"
	local airport_label="$2"
	local payload_kind="$3"
	local preferred_dns_plan="$4"
	local urls_file="$5"
	local conf_path=""
	local tmp_file=""
	[ -n "${airport_identity}" ] || return 1
	[ -f "${urls_file}" ] || return 1
	conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || return 1
	tmp_file="${conf_path}.tmp.$$"
	cat > "${tmp_file}" <<-EOF
		# fancyss airport dns special config
		airport_identity=${airport_identity}
		airport_label=${airport_label}
		payload_kind=${payload_kind}
		preferred_dns_plan=${preferred_dns_plan}
	EOF
	cat "${urls_file}" >> "${tmp_file}" || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${conf_path}"
	fss_airport_special_conf_register "${airport_identity}" >/dev/null 2>&1 || true
}

sub_refresh_airport_special_conf(){
	local airport_identity="$1"
	local airport_label="$2"
	local payload_kind="$3"
	local payload_file="$4"
	local extractor=""
	local preferred_dns_plan=""
	local urls_file="${payload_file}.airport_dns_urls.$$"
	local before_sig=""
	local after_sig=""
	[ -n "${airport_identity}" ] || return 0
	before_sig="$(fss_airport_special_conf_signature "${airport_identity}" 2>/dev/null)"
	if ! sub_airport_profile_match_node_domain_dns "${airport_identity}" "${payload_kind}";then
		fss_remove_airport_special_conf "${airport_identity}" >/dev/null 2>&1 || true
		after_sig="$(fss_airport_special_conf_signature "${airport_identity}" 2>/dev/null)"
		[ "${before_sig}" != "${after_sig}" ] && SUB_AIRPORT_SPECIAL_CHANGED=1
		return 0
	fi
	extractor="$(sub_airport_profile_get_node_domain_dns_value "${airport_identity}" "${payload_kind}" "extractor" 2>/dev/null)"
	preferred_dns_plan="$(sub_airport_profile_get_node_domain_dns_value "${airport_identity}" "${payload_kind}" "preferred_dns_plan" 2>/dev/null)"
	[ -n "${extractor}" ] || {
		fss_remove_airport_special_conf "${airport_identity}" >/dev/null 2>&1 || true
		after_sig="$(fss_airport_special_conf_signature "${airport_identity}" 2>/dev/null)"
		[ "${before_sig}" != "${after_sig}" ] && SUB_AIRPORT_SPECIAL_CHANGED=1
		return 0
	}
	[ -n "${preferred_dns_plan}" ] || preferred_dns_plan="smartdns"
	if ! sub_extract_airport_dns_urls_to_file "${payload_file}" "${extractor}" "${urls_file}" >/dev/null 2>&1;then
		rm -f "${urls_file}"
		fss_remove_airport_special_conf "${airport_identity}" >/dev/null 2>&1 || true
		after_sig="$(fss_airport_special_conf_signature "${airport_identity}" 2>/dev/null)"
		[ "${before_sig}" != "${after_sig}" ] && SUB_AIRPORT_SPECIAL_CHANGED=1
		return 0
	fi
	sub_write_airport_special_conf "${airport_identity}" "${airport_label}" "${payload_kind}" "${preferred_dns_plan}" "${urls_file}" >/dev/null 2>&1 || true
	rm -f "${urls_file}"
	after_sig="$(fss_airport_special_conf_signature "${airport_identity}" 2>/dev/null)"
	[ "${before_sig}" != "${after_sig}" ] && SUB_AIRPORT_SPECIAL_CHANGED=1
}

sub_refresh_airport_special_conf_from_cached_source(){
	local sub_hash="$1"
	local parsed_file="$2"
	local payload_kind="$3"
	local payload_file="$4"
	local sep="$(printf '\037')"
	local first_meta=""
	local airport_identity=""
	local _source_scope=""
	local _source_hash=""
	local group_label=""
	local airport_label=""
	[ -n "${sub_hash}" ] || return 0
	[ -f "${parsed_file}" ] || return 0
	[ -f "${payload_file}" ] || return 0
	first_meta="$(sub_first_line_meta_tsv "${parsed_file}" 2>/dev/null)" || first_meta=""
	IFS="${sep}" read -r airport_identity _source_scope _source_hash group_label <<-EOF
	${first_meta}
	EOF
	[ -n "${airport_identity}" ] || return 0
	[ "${airport_identity}" = "local" ] && return 0
	airport_label="$(normalize_group_name "${group_label}" 2>/dev/null)"
	[ -n "${airport_label}" ] || airport_label="$(get_sub_group_fallback_by_hash "${sub_hash}" 2>/dev/null)"
	[ -n "${airport_label}" ] || airport_label="${airport_identity}"
	sub_refresh_airport_special_conf "${airport_identity}" "${airport_label}" "${payload_kind}" "${payload_file}"
}

sub_resolve_redirect_url(){
	local base_url="$1"
	local redirect_target="$2"
	local scheme origin base_no_frag base_no_query base_dir

	[ -n "${base_url}" ] || return 1
	[ -n "${redirect_target}" ] || return 1

	case "${redirect_target}" in
	http://*|https://*)
		echo "${redirect_target}"
		return 0
		;;
	//*)
		scheme=$(sub_url_scheme "${base_url}")
		[ -n "${scheme}" ] || return 1
		echo "${scheme}:${redirect_target}"
		return 0
		;;
	/*)
		origin=$(sub_url_origin "${base_url}")
		[ -n "${origin}" ] || return 1
		echo "${origin}${redirect_target}"
		return 0
		;;
	\?*)
		base_no_frag="${base_url%%#*}"
		base_no_query="${base_no_frag%%\?*}"
		echo "${base_no_query}${redirect_target}"
		return 0
		;;
	*)
		base_no_frag="${base_url%%#*}"
		base_no_query="${base_no_frag%%\?*}"
		base_dir="${base_no_query%/*}"
		if [ -z "${base_dir}" ] || [ "${base_dir}" = "${base_no_query}" ];then
			base_dir=$(sub_url_origin "${base_url}")
		fi
		[ -n "${base_dir}" ] || return 1
		echo "${base_dir%/}/${redirect_target}"
		return 0
		;;
	esac
}

sub_follow_html_redirect_chain_with_tool(){
	local base_url="$1"
	local short_hash="$2"
	local payload_file="${DIR}/sub_file_encode_${short_hash}.txt"
	local inspect_file="${DIR}/sub_file_inspect_${short_hash}.json"
	local backup_file="${DIR}/sub_file_encode_${short_hash}.bak"
	local current_url="${base_url}"
	local visited_urls=""
	local inspect_kind=""
	local redirect_target=""
	local resolved_url=""
	local hop=0
	local max_hops=3

	[ -f "${payload_file}" ] || return 1
	while [ "${hop}" -lt "${max_hops}" ]; do
		sub_tool_inspect_file "${payload_file}" "${inspect_file}" || return 2
		inspect_kind=$(sub_inspect_json_field "kind" "${inspect_file}")
		[ "${inspect_kind}" = "html-redirect" ] || return 0
		redirect_target=$(sub_inspect_json_field "redirect_url" "${inspect_file}")
		if [ -z "${redirect_target}" ];then
			echo_date "⚠️检测到HTML跳转页，但未能提取到跳转目标。"
			return 1
		fi
		resolved_url=$(sub_resolve_redirect_url "${current_url}" "${redirect_target}") || {
			echo_date "⚠️检测到HTML跳转页，但跳转链接解析失败：${redirect_target}"
			return 1
		}
		if printf '%s\n' "${visited_urls}" | grep -Fxq "${resolved_url}";then
			echo_date "⚠️检测到HTML跳转循环，终止继续跟随：${resolved_url}"
			return 1
		fi
		hop=$((hop + 1))
		echo_date "⤴️检测到HTML跳转页，第${hop}次跟随跳转：${resolved_url}"
		visited_urls=$(printf '%s\n%s\n' "${visited_urls}" "${resolved_url}")
		cp -f "${payload_file}" "${backup_file}" >/dev/null 2>&1
		rm -f "${payload_file}" "${inspect_file}" >/dev/null 2>&1
		download_by_curl "${resolved_url}" || {
			[ -f "${backup_file}" ] && mv -f "${backup_file}" "${payload_file}"
			echo_date "⚠️跟随HTML跳转后的订阅链接下载失败：${resolved_url}"
			return 1
		}
		rm -f "${backup_file}" >/dev/null 2>&1
		current_url="${resolved_url}"
	done

	rm -f "${backup_file}" >/dev/null 2>&1
	echo_date "⚠️HTML跳转次数超过${max_hops}次，终止继续跟随。"
	return 1
}

sub_validate_downloaded_payload_with_tool(){
	local short_hash="$1"
	local payload_file="${DIR}/sub_file_encode_${short_hash}.txt"
	local inspect_file="${DIR}/sub_file_inspect_${short_hash}.json"
	local inspect_kind=""
	local preview=""

	[ -f "${payload_file}" ] || return 1
	sub_tool_inspect_file "${payload_file}" "${inspect_file}" || return 2
	inspect_kind=$(sub_inspect_json_field "kind" "${inspect_file}")
	SUB_PAYLOAD_KIND="${inspect_kind}"
	case "${inspect_kind}" in
	uri-lines|base64-uri-lines)
		return 0
		;;
	clash-yaml)
		return 0
		;;
	empty)
		SUB_LAST_DOWNLOAD_ERROR="empty payload"
		echo_date "⚠️下载内容为空！️该订阅链接不包含任何节点信息"
		echo_date "⚠️请检查你的服务商是否更换了订阅链接！"
		return 1
		;;
	html-login)
		SUB_LAST_DOWNLOAD_ERROR="html login page"
		echo_date "⚠️解析错误！原因：该订阅链接返回了登录/验证页面，当前无法直接获取订阅内容！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	html-redirect)
		SUB_LAST_DOWNLOAD_ERROR="html redirect unresolved"
		echo_date "⚠️解析错误！原因：该订阅链接返回了HTML跳转页，但自动跟随未成功完成！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	html-page)
		SUB_LAST_DOWNLOAD_ERROR="html page"
		echo_date "⚠️解析错误！原因：该订阅链接返回了HTML页面，而不是订阅内容！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	json-error)
		SUB_LAST_DOWNLOAD_ERROR="json error payload"
		echo_date "⚠️解析错误！原因：该订阅链接返回了JSON错误响应！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	json)
		SUB_LAST_DOWNLOAD_ERROR="json payload"
		echo_date "⚠️解析错误！原因：该订阅链接返回了JSON内容，而不是订阅内容！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	text-error)
		SUB_LAST_DOWNLOAD_ERROR="text error payload"
		echo_date "⚠️解析错误！原因：该订阅链接返回了文本错误响应！"
		preview=$(sub_payload_preview "${payload_file}")
		[ -n "${preview}" ] && echo_date "⚠️返回内容摘要：${preview}"
		return 1
		;;
	ssep-envelope)
		SUB_LAST_DOWNLOAD_ERROR="ssep envelope unsupported"
		echo_date "⚠️解析错误！原因：检测到SSEP加密订阅Envelope，当前版本暂未解密此订阅格式！"
		return 1
		;;
	gzip)
		SUB_LAST_DOWNLOAD_ERROR="gzip payload unsupported"
		echo_date "⚠️解析错误！原因：检测到gzip压缩响应，当前订阅链路暂未处理此类返回内容！"
		return 1
		;;
	unknown|"")
		return 2
		;;
	*)
		return 2
		;;
	esac
}

sub_validate_downloaded_payload_legacy(){
	local sub_link="$1"
	local short_hash="$2"
	local download_mode="$3"
	local payload_file="${DIR}/sub_file_encode_${short_hash}.txt"
	local wrong=""
	local jump=""

	[ -f "${payload_file}" ] || return 1
	SUB_PAYLOAD_KIND=""

	if [ "${download_mode}" = "curl" ];then
		jump=$(grep -Eo "Redirecting|301" "${payload_file}")
		if [ -n "${jump}" ];then
			echo_date "⤴️订阅链接可能有跳转，尝试更换wget进行下载..."
			rm -f "${payload_file}" >/dev/null 2>&1
			download_by_wget "${sub_link}" || return 1
		fi

		if [ "$(cat "${payload_file}" | wc -c)" = "0" ];then
			echo_date "🈳下载内容为空，尝试更换wget进行下载..."
			rm -f "${payload_file}" >/dev/null 2>&1
			download_by_wget "${sub_link}" || return 1
		fi
	else
		if [ "$(cat "${payload_file}" | wc -c)" = "0" ];then
			echo_date "⚠️下载内容为空！️该订阅链接不包含任何节点信息"
			echo_date "⚠️请检查你的服务商是否更换了订阅链接！"
			return 1
		fi
	fi

	if [ "$(cat "${payload_file}" | grep -c proxies)" -ge "1" ];then
		SUB_PAYLOAD_KIND="clash-yaml"
		echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
		return 1
	fi

	wrong=$(cat "${payload_file}" | grep -E "404")
	if [ -n "${wrong}" ];then
		echo_date "⚠️解析错误！原因：该订阅链接无法访问，错误代码：404！"
		return 1
	fi

	wrong=$(cat "${payload_file}" | grep -E "\{")
	if [ -n "${wrong}" ];then
		echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
		echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
		echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
		return 1
	fi

	dec64 $(cat "${payload_file}") >/dev/null 2>&1
	if [ "$?" != "0" ];then
		echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
		echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
		return 1
	fi

	return 0
}

sub_process_downloaded_payload_with_tool(){
	local sub_link="$1"
	local short_hash="$2"
	local follow_rc=0

	sub_follow_html_redirect_chain_with_tool "${sub_link}" "${short_hash}"
	follow_rc="$?"
	case "${follow_rc}" in
	0)
		;;
	2)
		return 2
		;;
	*)
		return 1
		;;
	esac

	sub_validate_downloaded_payload_with_tool "${short_hash}"
	return $?
}

sub_validate_downloaded_payload(){
	local sub_link="$1"
	local short_hash="$2"
	local download_mode="$3"
	local tool_rc=2

	if pick_sub_tool >/dev/null 2>&1;then
		sub_process_downloaded_payload_with_tool "${sub_link}" "${short_hash}"
		tool_rc="$?"
	fi

	case "${tool_rc}" in
	0)
		return 0
		;;
	1)
		return 1
		;;
	esac

	sub_validate_downloaded_payload_legacy "${sub_link}" "${short_hash}" "${download_mode}"
	return $?
}

sub_filter_fancyss_jsonl_file(){
	local src_file="$1"
	local out_file="$2"
	local row=""
	local row_kind=""
	local type_b64=""
	local xray_b64=""
	local remarks_b64=""
	local server_b64=""
	local line_b64=""
	local type_id=""
	local xray_prot=""
	local remarks=""
	local server=""
	local type_name=""
	local line=""
	local sep="$(printf '\037')"
	local rows_file="${out_file}.rows.$$"

	[ -f "${src_file}" ] || return 1
	[ -n "${out_file}" ] || return 1
	: > "${out_file}"
	: > "${rows_file}"

	cat "${src_file}" | jq -Rr 'def text($v): if $v == null then "" elif ($v | type) == "string" then $v else ($v | tostring) end; . as $raw | select($raw != "") | (try ($raw | fromjson) catch null) as $obj | if ($obj | type) != "object" then ["raw", "", "", "", "", ($raw | @base64)] else ["json", (text($obj.type) | @base64), (text($obj.xray_prot) | @base64), (text($obj.name) | @base64), (text(($obj.server // $obj.hy2_server // $obj.naive_server)) | @base64), ($raw | @base64)] end | join("\u001f")' 2>/dev/null > "${rows_file}" || {
		rm -f "${rows_file}"
		return 1
	}
	while IFS= read -r row || [ -n "${row}" ]
	do
		[ -n "${row}" ] || continue
		IFS="${sep}" read -r row_kind type_b64 xray_b64 remarks_b64 server_b64 line_b64 <<-EOF
		${row}
		EOF
		line=""
		[ -n "${line_b64}" ] && line="$(fss_b64_decode "${line_b64}")"
		[ -n "${line}" ] || continue
		if [ "${row_kind}" != "json" ];then
			printf '%s\n' "${line}" >> "${out_file}"
			continue
		fi
		type_id=""
		xray_prot=""
		remarks=""
		server=""
		[ -n "${type_b64}" ] && type_id="$(fss_b64_decode "${type_b64}")"
		[ -n "${xray_b64}" ] && xray_prot="$(fss_b64_decode "${xray_b64}")"
		[ -n "${remarks_b64}" ] && remarks="$(fss_b64_decode "${remarks_b64}")"
		[ -n "${server_b64}" ] && server="$(fss_b64_decode "${server_b64}")"
		case "${type_id}" in
		0)
			type_name="SS"
			;;
		1)
			type_name="SSR"
			;;
		3)
			type_name="vmess"
			;;
		4)
			type_name="${xray_prot:-xray}"
			;;
		5)
			type_name="trojan"
			;;
		6)
			type_name="Naïve"
			;;
		7)
			type_name="tuic"
			;;
		8)
			type_name="hysteria2"
			;;
		*)
			type_name="node"
			;;
		esac
		filter_nodes "${type_name}" "${remarks}" "${server}" || continue
		printf '%s\n' "${line}" >> "${out_file}"
	done < "${rows_file}"
	rm -f "${rows_file}"
}

sub_keyword_patterns_can_use_tool(){
	local combined="${KEY_WORDS_1}${KEY_WORDS_2}"
	[ -n "${combined}" ] || return 0
	printf '%s' "${combined}" | grep -Eq '[\[\]\(\)\{\}\*\+\?\^\$\\]' && return 1
	return 0
}

sub_try_parse_uri_lines_with_tool(){
	local input_file="$1"
	local output_file="$2"
	local default_group="$3"
	local source_tag="$4"
	local pkg_type="$5"
	local sub_tool=""
	local tmp_output="${output_file}.subtool.$$"
	local filtered_output="${output_file}.filtered.$$"
	local subtool_log_file="${output_file}.log.$$"
	local effective_sub_ai=""
	local effective_hy2_up=""
	local effective_hy2_dl=""
	local effective_hy2_tfo=""
	local effective_hy2_cg=""
	local subtool_log_level="summary"
	local reuse_ids_from=""
	local diff_output_file=""
	local diff_summary_file=""
	local summary_output_file=""
	local tool_can_filter=1

	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	sub_tool="$(pick_sub_tool 2>/dev/null)" || return 1
	reuse_ids_from="$(sub_find_local_source_file "${source_tag}" 2>/dev/null)" || reuse_ids_from=""
	SUB_TOOL_DIFF_FILE_CURRENT=""
	SUB_TOOL_DIFF_SUMMARY_FILE_CURRENT=""
	SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT=""
	if ! sub_keyword_patterns_can_use_tool;then
		tool_can_filter=0
		echo_date "⚠️当前订阅过滤表达式过于复杂，已回退到兼容模式。请改用简单关键词格式，多个关键词用英文逗号分隔，例如：香港,新加坡,JP"
	fi
	effective_sub_ai=$(sub_get_effective_sub_ai "${SUB_AI}")
	{
		read -r effective_hy2_up
		read -r effective_hy2_dl
		read -r effective_hy2_tfo
		read -r effective_hy2_cg
	} <<-EOF
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "${HY2_CG_OPT}")
	EOF

	[ "${SUB_TOOL_NODE_LOG}" = "1" ] && subtool_log_level="verbose"
	rm -f "${tmp_output}" "${filtered_output}" "${subtool_log_file}" >/dev/null 2>&1
	set -- parse-uri-lines \
		--input "${input_file}" \
		--output "${tmp_output}" \
		--format fancyss \
		--mode "${SUB_MODE}" \
		--pkg-type "${pkg_type}" \
		--sub-ai "${effective_sub_ai}" \
		--hy2-tfo-switch "${effective_hy2_tfo}" \
		--hy2-cg-opt "${effective_hy2_cg}" \
		--log-level "${subtool_log_level}" \
		--log-output "${subtool_log_file}" \
		--include-raw
	[ -n "${default_group}" ] && set -- "$@" --group "${default_group}"
	[ -n "${source_tag}" ] && set -- "$@" --source-tag "${source_tag}"
	[ -n "${SUB_SOURCE_URL_HASH}" ] && set -- "$@" --source-url-hash "${SUB_SOURCE_URL_HASH}"
	[ -n "${SUB_AIRPORT_IDENTITY}" ] && set -- "$@" --airport-identity "${SUB_AIRPORT_IDENTITY}"
	[ -n "${SUB_SOURCE_SCOPE}" ] && set -- "$@" --source-scope "${SUB_SOURCE_SCOPE}"
	[ -n "${SUB_ACTIVE_PROFILE_ID}" ] && set -- "$@" --profile-id "${SUB_ACTIVE_PROFILE_ID}"
	[ -n "${reuse_ids_from}" ] && set -- "$@" --reuse-ids-from "${reuse_ids_from}"
	[ "${tool_can_filter}" = "1" ] && [ -n "${KEY_WORDS_1}" ] && set -- "$@" --exclude-pattern "${KEY_WORDS_1}"
	[ "${tool_can_filter}" = "1" ] && [ -n "${KEY_WORDS_2}" ] && set -- "$@" --include-pattern "${KEY_WORDS_2}"
	set -- "$@" --keep-info-node "${SUB_KEEP_INFO_NODE}"
	if [ -n "${reuse_ids_from}" ] && [ "${tool_can_filter}" = "1" ];then
		diff_output_file="${output_file}.diff.$$"
		diff_summary_file="${output_file}.diff.summary.$$"
		set -- "$@" --compare-with "${reuse_ids_from}" --diff-output "${diff_output_file}" --diff-summary-output "${diff_summary_file}"
	fi
	summary_output_file="${output_file}.summary.$$"
	set -- "$@" --summary-output "${summary_output_file}"
	[ -n "${effective_hy2_up}" ] && set -- "$@" --hy2-up "${effective_hy2_up}"
	[ -n "${effective_hy2_dl}" ] && set -- "$@" --hy2-dl "${effective_hy2_dl}"
	"${sub_tool}" "$@" >/dev/null 2>&1 || {
		rm -f "${tmp_output}" "${filtered_output}" "${subtool_log_file}" "${diff_output_file}" "${diff_summary_file}" "${summary_output_file}" >/dev/null 2>&1
		return 1
	}

	if [ "${tool_can_filter}" = "1" ];then
		mv -f "${tmp_output}" "${output_file}"
	else
		sub_filter_fancyss_jsonl_file "${tmp_output}" "${filtered_output}" || {
			rm -f "${tmp_output}" "${filtered_output}" "${subtool_log_file}" "${diff_output_file}" "${diff_summary_file}" "${summary_output_file}" >/dev/null 2>&1
			return 1
		}
		mv -f "${filtered_output}" "${output_file}"
		rm -f "${tmp_output}" >/dev/null 2>&1
	fi
	rm -f "${subtool_log_file}" >/dev/null 2>&1
	if [ -s "${output_file}" ];then
		local kept_total=0
		kept_total=$(wc -l < "${output_file}" 2>/dev/null | tr -d ' ')
		[ -n "${kept_total}" ] || kept_total=0
		if [ -n "${NODE_NU_TT}" ] && [ "${NODE_NU_TT}" -ge "${kept_total}" ] 2>/dev/null;then
			exclude=$((NODE_NU_TT - kept_total))
		fi
		if [ -n "${diff_output_file}" ] && [ -f "${diff_output_file}" ];then
			SUB_TOOL_DIFF_FILE_CURRENT="${diff_output_file}"
		fi
		if [ -n "${diff_summary_file}" ] && [ -f "${diff_summary_file}" ];then
			SUB_TOOL_DIFF_SUMMARY_FILE_CURRENT="${diff_summary_file}"
		fi
		if [ -n "${summary_output_file}" ] && [ -f "${summary_output_file}" ];then
			SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT="${summary_output_file}"
		fi
	else
		rm -f "${diff_output_file}" >/dev/null 2>&1
		rm -f "${diff_summary_file}" >/dev/null 2>&1
		rm -f "${summary_output_file}" >/dev/null 2>&1
		rm -f "${output_file}" >/dev/null 2>&1
	fi
	return 0
}

sub_update_parsed_cache_meta(){
	local sub_hash="$1"
	local parsed_file="$2"
	local meta_file filter_sig effective_sub_ai effective_hy2_up effective_hy2_dl effective_hy2_tfo effective_hy2_cg
	local has_ai_sensitive has_hy2_sensitive mapping_sig
	[ -n "${sub_hash}" ] || return 1
	meta_file=$(sub_get_parsed_cache_meta_file "${sub_hash}") || return 1
	filter_sig=$(sub_get_filter_signature)
	effective_sub_ai=$(sub_get_effective_sub_ai "${SUB_AI}")
	{
		read -r effective_hy2_up
		read -r effective_hy2_dl
		read -r effective_hy2_tfo
		read -r effective_hy2_cg
	} <<-EOF
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "${HY2_CG_OPT}")
	EOF
	mapping_sig=$(sub_get_airport_mapping_signature)
	has_ai_sensitive="0"
	has_hy2_sensitive="0"
	if [ -f "${parsed_file}" ];then
		if grep -q '"type":"8"' "${parsed_file}" 2>/dev/null;then
			has_hy2_sensitive="1"
		fi
		if grep -Eq '"type":"(3|4|5|8)"' "${parsed_file}" 2>/dev/null;then
			has_ai_sensitive="1"
		fi
	fi
	cat > "${meta_file}" <<-EOF
	schema_version=${SUB_PARSED_CACHE_META_SCHEMA}
	filter_signature=${filter_sig}
	exclude_keywords=${KEY_WORDS_1_RAW}
	include_keywords=${KEY_WORDS_2_RAW}
	sub_mode=${SUB_MODE}
	sub_ai=${effective_sub_ai}
	keep_info_node=${SUB_KEEP_INFO_NODE}
	hy2_up=${effective_hy2_up}
	hy2_dl=${effective_hy2_dl}
	hy2_tfo_switch=${effective_hy2_tfo}
	hy2_cg_opt=${effective_hy2_cg}
	airport_map_sig=${mapping_sig}
	has_ai_sensitive=${has_ai_sensitive}
	has_hy2_sensitive=${has_hy2_sensitive}
	EOF
}

sub_parsed_cache_meta_matches(){
	local sub_hash="$1"
	local meta_file cached_schema cached_exclude cached_include cached_sub_mode cached_sub_ai cached_keep_info_node
	local cached_hy2_up cached_hy2_dl cached_hy2_tfo cached_hy2_cg cached_mapping_sig has_ai_sensitive has_hy2_sensitive
	local current_sub_ai current_hy2_up current_hy2_dl current_hy2_tfo current_hy2_cg current_mapping_sig
	[ -n "${sub_hash}" ] || return 1
	meta_file=$(sub_get_parsed_cache_meta_file "${sub_hash}") || return 1
	[ -f "${meta_file}" ] || return 1
	cached_schema=$(sed -n 's/^schema_version=//p' "${meta_file}" | sed -n '1p')
	cached_exclude=$(sed -n 's/^exclude_keywords=//p' "${meta_file}" | sed -n '1p')
	cached_include=$(sed -n 's/^include_keywords=//p' "${meta_file}" | sed -n '1p')
	cached_sub_mode=$(sed -n 's/^sub_mode=//p' "${meta_file}" | sed -n '1p')
	cached_sub_ai=$(sed -n 's/^sub_ai=//p' "${meta_file}" | sed -n '1p')
	cached_keep_info_node=$(sed -n 's/^keep_info_node=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_up=$(sed -n 's/^hy2_up=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_dl=$(sed -n 's/^hy2_dl=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_tfo=$(sed -n 's/^hy2_tfo_switch=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_cg=$(sed -n 's/^hy2_cg_opt=//p' "${meta_file}" | sed -n '1p')
	cached_mapping_sig=$(sed -n 's/^airport_map_sig=//p' "${meta_file}" | sed -n '1p')
	has_ai_sensitive=$(sed -n 's/^has_ai_sensitive=//p' "${meta_file}" | sed -n '1p')
	has_hy2_sensitive=$(sed -n 's/^has_hy2_sensitive=//p' "${meta_file}" | sed -n '1p')
	current_sub_ai=$(sub_get_effective_sub_ai "${SUB_AI}")
	{
		read -r current_hy2_up
		read -r current_hy2_dl
		read -r current_hy2_tfo
		read -r current_hy2_cg
	} <<-EOF
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "${HY2_CG_OPT}")
	EOF
	current_mapping_sig=$(sub_get_airport_mapping_signature)
	[ "${cached_schema}" = "${SUB_PARSED_CACHE_META_SCHEMA}" ] || return 1
	[ -n "${cached_sub_mode}" ] || return 1
	[ "${cached_exclude}" = "${KEY_WORDS_1_RAW}" ] || return 1
	[ "${cached_include}" = "${KEY_WORDS_2_RAW}" ] || return 1
	[ "${cached_sub_mode}" = "${SUB_MODE}" ] || return 1
	[ "${cached_keep_info_node}" = "${SUB_KEEP_INFO_NODE}" ] || return 1
	[ "${cached_mapping_sig}" = "${current_mapping_sig}" ] || return 1
	if [ "${has_ai_sensitive}" = "1" ];then
		[ "${cached_sub_ai}" = "${current_sub_ai}" ] || return 1
	fi
	if [ "${has_hy2_sensitive}" = "1" ];then
		[ "${cached_hy2_up}" = "${current_hy2_up}" ] || return 1
		[ "${cached_hy2_dl}" = "${current_hy2_dl}" ] || return 1
		[ "${cached_hy2_tfo}" = "${current_hy2_tfo}" ] || return 1
		[ "${cached_hy2_cg}" = "${current_hy2_cg}" ] || return 1
	fi
	return 0
}

sub_file_md5(){
	local file_path="$1"
	[ -f "${file_path}" ] || return 1
	md5sum "${file_path}" | awk '{print $1}'
}

sub_get_airport_mapping_signature(){
	if [ -f "${NODE_TOOL_CONF_FILE}" ];then
		sub_file_md5 "${NODE_TOOL_CONF_FILE}" 2>/dev/null || echo "none"
	else
		echo "none"
	fi
}

sub_log_node_success(){
	[ "${SUB_VERBOSE_NODE_LOG}" = "1" ] || return 0
	echo_date "$1"
}

sub_fancyss_type_name(){
	local type_id="$1"
	local xray_prot="$2"
	case "${type_id}" in
	0)
		echo "SS"
		;;
	1)
		echo "SSR"
		;;
	3)
		echo "vmess"
		;;
	4)
		case "${xray_prot}" in
		vmess)
			echo "vmess"
			;;
		vless)
			echo "vless"
			;;
		*)
			echo "xray"
			;;
		esac
		;;
	5)
		echo "trojan"
		;;
	6)
		echo "Naïve"
		;;
	7)
		echo "tuic"
		;;
	8)
		echo "hysteria2"
		;;
	*)
		echo "node"
		;;
	esac
}

sub_fancyss_type_prefix(){
	local type_id="$1"
	local xray_prot="$2"
	case "${type_id}" in
	0)
		echo "🟢SS节点："
		;;
	1)
		echo "🔵SSR节点："
		;;
	3)
		echo "🟠vmess节点："
		;;
	4)
		case "${xray_prot}" in
		vmess)
			echo "🟠vmess节点："
			;;
		vless)
			echo "🟣vless节点："
			;;
		*)
			echo "🟣xray节点："
			;;
		esac
		;;
	5)
		echo "🟡trojan节点："
		;;
	6)
		echo "🟧Naïve节点："
		;;
	7)
		echo "🟫tuic节点："
		;;
	8)
		echo "🟤hysteria2节点："
		;;
	*)
		echo "⚪节点："
		;;
	esac
}

sub_log_fancyss_parse_summary(){
	local file="$1"
	local total=0
	[ -f "${file}" ] || return 0
	total=$(wc -l < "${file}" 2>/dev/null | tr -d ' ')
	[ -n "${total}" ] || total=0
	echo_date "ℹ️最终保留${total}个节点，具体情况如下："
	run jq -r '[.type // "", .xray_prot // ""] | @tsv' "${file}" 2>/dev/null | awk -F '\t' '
		function label(type_id, xray_prot) {
			if (type_id == "0") return "🟢SS节点";
			if (type_id == "1") return "🔵SSR节点";
			if (type_id == "3") return "🟠vmess节点";
			if (type_id == "4" && xray_prot == "vmess") return "🟠vmess节点";
			if (type_id == "4" && xray_prot == "vless") return "🟣vless节点";
			if (type_id == "4") return "🟣xray节点";
			if (type_id == "5") return "🟡trojan节点";
			if (type_id == "6") return "🟧Naïve节点";
			if (type_id == "7") return "🟫tuic节点";
			if (type_id == "8") return "🟤hysteria2节点";
			return "⚪节点";
		}
		{
			key = label($1, $2);
			if (key != "") cnt[key]++;
		}
		END {
			for (key in cnt) {
				print key "|" cnt[key];
			}
		}
	' | sort | while IFS='|' read -r label count
	do
		[ -n "${label}" ] && echo_date "${label}：${count}个"
	done
}

sub_describe_filter_rules(){
	if [ -n "${KEY_WORDS_1_RAW}" ] && [ -n "${KEY_WORDS_2_RAW}" ];then
		printf '排除【%s】；保留【%s】' "${KEY_WORDS_1_RAW}" "${KEY_WORDS_2_RAW}"
	elif [ -n "${KEY_WORDS_1_RAW}" ];then
		printf '排除【%s】' "${KEY_WORDS_1_RAW}"
	elif [ -n "${KEY_WORDS_2_RAW}" ];then
		printf '保留【%s】' "${KEY_WORDS_2_RAW}"
	else
		printf '未设置额外过滤规则'
	fi
}

sub_get_parse_summary_value(){
	local file="$1"
	local key="$2"
	[ -f "${file}" ] || return 1
	"$(sub_pick_jq)" -r --arg key "${key}" '.[$key] // 0' "${file}" 2>/dev/null | sed -n '1p'
}

sub_get_parse_summary_scheme_count(){
	local file="$1"
	local bucket="$2"
	local key="$3"
	[ -f "${file}" ] || return 1
	"$(sub_pick_jq)" -r --arg bucket "${bucket}" --arg key "${key}" '.[$bucket][$key] // 0' "${file}" 2>/dev/null | sed -n '1p'
}

sub_log_fancyss_parse_summary_json(){
	local file="$1"
	local total=0
	local kept=0
	local filtered=0
	local supported=0
	local filter_desc=""
	[ -f "${file}" ] || return 1
	total=$(sub_get_parse_summary_value "${file}" "uri_lines")
	kept=$(sub_get_parse_summary_value "${file}" "kept_nodes")
	filtered=$(sub_get_parse_summary_value "${file}" "filtered_nodes")
	supported=$(sub_get_parse_summary_value "${file}" "raw_supported_nodes")
	[ -n "${total}" ] || total=0
	[ -n "${kept}" ] || kept=0
	[ -n "${filtered}" ] || filtered=0
	[ -n "${supported}" ] || supported=0
	filter_desc="$(sub_describe_filter_rules)"
	echo_date "😀解析完成！共获得${total}个节点！"
	if [ -n "${KEY_WORDS_1_RAW}${KEY_WORDS_2_RAW}" ];then
		if [ "${filtered}" -gt "0" ];then
			echo_date "ℹ️根据用户定义的订阅过滤规则【${filter_desc}】，并结合当前插件支持情况，最终保留${kept}个节点，过滤掉${filtered}个，具体情况如下："
		else
			echo_date "ℹ️根据用户定义的订阅过滤规则【${filter_desc}】，并结合当前插件支持情况，最终保留${kept}个节点，具体情况如下："
		fi
	else
		if [ "${supported}" -ne "${kept}" ];then
			echo_date "ℹ️当前未设置额外订阅过滤规则，结合当前插件支持情况，最终保留${kept}个节点，具体情况如下："
		else
			echo_date "ℹ️当前未设置额外订阅过滤规则，最终保留${kept}个节点，具体情况如下："
		fi
	fi
	local ss=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "ss")
	local ssr=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "ssr")
	local vmess=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "vmess")
	local vless=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "vless")
	local trojan=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "trojan")
	local naive=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "naive")
	local tuic=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "tuic")
	local hy2=$(sub_get_parse_summary_scheme_count "${file}" "kept_counts" "hysteria2")
	[ -n "${ss}" ] || ss=0
	[ -n "${ssr}" ] || ssr=0
	[ -n "${vmess}" ] || vmess=0
	[ -n "${vless}" ] || vless=0
	[ -n "${trojan}" ] || trojan=0
	[ -n "${naive}" ] || naive=0
	[ -n "${tuic}" ] || tuic=0
	[ -n "${hy2}" ] || hy2=0
	[ "${ss}" -gt "0" ] && echo_date "🟢SS节点：${ss}个"
	[ "${ssr}" -gt "0" ] && echo_date "🔵SSR节点：${ssr}个"
	[ "${vmess}" -gt "0" ] && echo_date "🟠vmess节点：${vmess}个"
	[ "${vless}" -gt "0" ] && echo_date "🟣vless节点：${vless}个"
	[ "${trojan}" -gt "0" ] && echo_date "🟡trojan节点：${trojan}个"
	[ "${naive}" -gt "0" ] && echo_date "🟧Naïve节点：${naive}个"
	[ "${tuic}" -gt "0" ] && echo_date "🟫tuic节点：${tuic}个"
	[ "${hy2}" -gt "0" ] && echo_date "🟤hysteria2节点：${hy2}个"
	return 0
}

sub_collect_protocol_counts_from_decoded_file(){
	local file="$1"
	local pkg_type="$2"
	local raw=0 ss=0 ssr=0 vmess=0 vless=0 trojan=0 hy2=0 tuic=0 naive=0 total=0
	[ -f "${file}" ] || {
		echo "0 0 0 0 0 0 0 0 0 0"
		return 1
	}
	raw=$(grep -c "://" "${file}" 2>/dev/null)
	ss=$(grep -Ec "^ss://" "${file}" 2>/dev/null)
	ssr=$(grep -Ec "^ssr://" "${file}" 2>/dev/null)
	vmess=$(grep -Ec "^vmess://" "${file}" 2>/dev/null)
	vless=$(grep -Ec "^vless://" "${file}" 2>/dev/null)
	trojan=$(grep -Ec "^trojan://" "${file}" 2>/dev/null)
	hy2=$(grep -Ec "^hysteria2://|^hy2://" "${file}" 2>/dev/null)
	tuic=$(grep -Ec "^tuic://" "${file}" 2>/dev/null)
	naive=$(grep -Ec "^naive\\+https://|^naive\\+quic://" "${file}" 2>/dev/null)
	total=$((ss + ssr + vmess + vless + trojan + hy2))
	if [ "${pkg_type}" = "full" ];then
		total=$((total + tuic + naive))
	fi
	echo "${raw} ${ss} ${ssr} ${vmess} ${vless} ${trojan} ${hy2} ${tuic} ${naive} ${total}"
}

sub_collect_protocol_counts_from_summary(){
	local file="$1"
	local pkg_type="$2"
	local raw=0 ss=0 ssr=0 vmess=0 vless=0 trojan=0 hy2=0 tuic=0 naive=0 total=0
	[ -f "${file}" ] || {
		echo "0 0 0 0 0 0 0 0 0 0"
		return 1
	}
	raw=$(sub_get_parse_summary_value "${file}" "uri_lines")
	[ -n "${raw}" ] || raw=$(sub_get_parse_summary_value "${file}" "total_lines")
	ss=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "ss")
	ssr=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "ssr")
	vmess=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "vmess")
	vless=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "vless")
	trojan=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "trojan")
	hy2=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "hysteria2")
	tuic=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "tuic")
	naive=$(sub_get_parse_summary_scheme_count "${file}" "raw_counts" "naive")
	[ -n "${raw}" ] || raw=0
	[ -n "${ss}" ] || ss=0
	[ -n "${ssr}" ] || ssr=0
	[ -n "${vmess}" ] || vmess=0
	[ -n "${vless}" ] || vless=0
	[ -n "${trojan}" ] || trojan=0
	[ -n "${hy2}" ] || hy2=0
	[ -n "${tuic}" ] || tuic=0
	[ -n "${naive}" ] || naive=0
	total=$((ss + ssr + vmess + vless + trojan + hy2))
	if [ "${pkg_type}" = "full" ];then
		total=$((total + tuic + naive))
	fi
	echo "${raw} ${ss} ${ssr} ${vmess} ${vless} ${trojan} ${hy2} ${tuic} ${naive} ${total}"
}

sub_log_protocol_counts(){
	local raw="$1"
	local ss="$2"
	local ssr="$3"
	local vmess="$4"
	local vless="$5"
	local trojan="$6"
	local hy2="$7"
	local tuic="$8"
	local naive="$9"
	local total="${10}"
	local pkg_type="${11}"
	[ -n "${raw}" ] || raw=0
	[ -n "${total}" ] || total=0
	echo_date "😀初步解析成功！共获得${raw}个节点！"
	if [ "${total}" -eq "0" ] && [ "${pkg_type}" != "full" ] && [ $((tuic + naive)) -gt "0" ];then
		echo_date "⚠️当前插件为lite版本，订阅中的TUIC/NaïveProxy节点均为full版专属，无法导入！"
		return 1
	fi
	if [ "${total}" -lt "${raw}" ];then
		echo_date "ℹ️${raw}个节点中，一共检测到${total}个支持节点！"
	fi
	echo_date "ℹ️具体情况如下："
	[ "${ss}" -gt "0" ] && echo_date "🟢ss节点：${ss}个"
	[ "${ssr}" -gt "0" ] && echo_date "🔵ssr节点：${ssr}个"
	[ "${vmess}" -gt "0" ] && echo_date "🟠vmess节点：${vmess}个"
	[ "${vless}" -gt "0" ] && echo_date "🟣vless节点：${vless}个"
	[ "${trojan}" -gt "0" ] && echo_date "🟡trojan节点：${trojan}个"
	[ "${hy2}" -gt "0" ] && echo_date "🟤hysteria2节点：${hy2}个"
	[ "${tuic}" -gt "0" ] && echo_date "🟫tuic节点：${tuic}个"
	[ "${naive}" -gt "0" ] && echo_date "🟧Naïve节点：${naive}个"
	if [ "${pkg_type}" != "full" ] && [ $((tuic + naive)) -gt "0" ];then
		echo_date "⚠️当前插件为lite版本，TUIC/NaïveProxy节点会被跳过。"
	fi
	return 0
}

sub_log_fancyss_parse_nodes(){
	local file="$1"
	local meta=""
	local type_id=""
	local xray_prot=""
	local name=""
	local prefix=""
	local delim="$(printf '\037')"
	[ "${SUB_TOOL_NODE_LOG}" = "1" ] || return 0
	[ -f "${file}" ] || return 0
	run jq -r '[.type // "", .xray_prot // "", .name // ""] | join("\u001f")' "${file}" 2>/dev/null | while IFS="${delim}" read -r type_id xray_prot name
	do
		[ -n "${name}" ] || continue
		prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
		echo_date "${prefix}${name}"
	done
}

sub_prepare_decoded_file(){
	local short_hash="$1"
	local encoded_file="${DIR}/sub_file_encode_${short_hash}.txt"
	local decoded_file="${DIR}/sub_file_decode_${short_hash}.txt"
	local head_count="0"

	[ -f "${encoded_file}" ] || return 1
	if [ "${SUB_PAYLOAD_KIND}" = "clash-yaml" ];then
		cp -f "${encoded_file}" "${decoded_file}"
		return 0
	fi
	head_count=$(grep -Ec "^ss://|^ssr://|^vmess://|^vless://|^trojan://|^hysteria2://|^hy2://|^tuic://|^naive\\+https://|^naive\\+quic://" "${encoded_file}")
	if [ "${head_count}" -gt "0" ];then
		echo_date "📄检测到明文的订阅格式，无需解码，继续！"
		cp -f "${encoded_file}" "${decoded_file}"
	else
		tr -d '\n' < "${encoded_file}" | sed 's/-/+/g;s/_/\//g' | sed 's/$/===/' | base64 -d > "${decoded_file}"
		if [ "$?" != "0" ];then
			echo_date "⚠️解析错误！原因：解析后检测到乱码！请检查你的订阅地址！"
			return 1
		fi
	fi

	if [ -n "$(which dos2unix)" ];then
		dos2unix -u "${decoded_file}"
	else
		tr -d '\r' < "${decoded_file}" | sponge "${decoded_file}"
	fi

	return 0
}

sub_update_raw_cache(){
	local sub_hash="$1"
	local decoded_file="$2"
	local cache_file
	[ -n "${sub_hash}" ] || return 1
	[ -f "${decoded_file}" ] || return 1
	cache_file=$(sub_get_raw_cache_file "${sub_hash}") || return 1
	cp -f "${decoded_file}" "${cache_file}"
}

sub_update_parsed_cache(){
	local sub_hash="$1"
	local parsed_file="$2"
	local cache_file
	[ -n "${sub_hash}" ] || return 1
	[ -f "${parsed_file}" ] || return 1
	cache_file=$(sub_get_parsed_cache_file "${sub_hash}") || return 1
	cp -f "${parsed_file}" "${cache_file}"
	sub_update_parsed_cache_meta "${sub_hash}" "${parsed_file}"
}

sub_raw_cache_same_as_current(){
	local sub_hash="$1"
	local short_hash="$2"
	local decoded_file="$3"
	local cache_file local_file

	[ -n "${sub_hash}" ] || return 1
	[ -n "${short_hash}" ] || return 1
	[ -f "${decoded_file}" ] || return 1
	cache_file=$(sub_get_raw_cache_file "${sub_hash}") || return 1
	[ -f "${cache_file}" ] || return 1
	local_file=$(find "${DIR}" -name "local_*_${short_hash}.txt" | head -n1)
	[ -n "${local_file}" ] || return 1
	[ "$(sub_file_md5 "${decoded_file}")" = "$(sub_file_md5 "${cache_file}")" ]
}

sub_restore_from_parsed_cache(){
	local sub_hash="$1"
	local short_hash="$2"
	local sub_count="$3"
	local payload_kind="$4"
	local payload_file="$5"
	local parsed_cache local_file parsed_md5 local_md5 sub_tool compare_file compare_summary_file

	[ -n "${sub_hash}" ] || return 1
	[ -n "${short_hash}" ] || return 1
	[ -n "${sub_count}" ] || return 1
	parsed_cache=$(sub_get_parsed_cache_file "${sub_hash}") || return 1
	[ -f "${parsed_cache}" ] || return 1
	if ! sub_parsed_cache_meta_matches "${sub_hash}";then
		echo_date "♻️检测到订阅筛选条件或默认参数发生变化，需要重新解析并重写节点。"
		return 1
	fi
	if [ -n "${payload_kind}" ] && [ -n "${payload_file}" ];then
		sub_refresh_airport_special_conf_from_cached_source "${short_hash}" "${parsed_cache}" "${payload_kind}" "${payload_file}" >/dev/null 2>&1 || true
	fi
	local_file=$(find "${DIR}" -name "local_*_${short_hash}.txt" | head -n1)
	parsed_md5=$(sub_nodes_file_md5 "${parsed_cache}")
	[ -n "${local_file}" ] && local_md5=$(sub_nodes_file_md5 "${local_file}")
	if [ -n "${local_md5}" ] && [ "${local_md5}" = "${parsed_md5}" ];then
		echo_date "♻️原始订阅内容和上次成功订阅一致，跳过解析和写入。"
		sub_mark_active_source_tag "${short_hash}"
		return 0
	fi
	echo_date "♻️原始订阅内容未变化，但当前订阅来源的本地节点被修改/删除，正在用上次成功解析结果恢复。"
	if [ "${SUB_TOOL_NODE_LOG}" = "1" ] && [ -n "${local_file}" ];then
		sub_tool="$(pick_sub_tool 2>/dev/null)" || sub_tool=""
		if [ -n "${sub_tool}" ];then
			compare_file="${parsed_cache}.restore.diff.$$"
			compare_summary_file="${parsed_cache}.restore.summary.$$"
			if "${sub_tool}" compare-fancyss --old "${local_file}" --new "${parsed_cache}" --output "${compare_file}" --diff-summary-output "${compare_summary_file}" >/dev/null 2>&1;then
				sub_log_nodes_diff_tsv_file "${compare_file}" "${compare_summary_file}"
			fi
			rm -f "${compare_file}" "${compare_summary_file}" >/dev/null 2>&1
		fi
	fi
	[ -n "${local_file}" ] && rm -f "${local_file}"
	cp -f "${parsed_cache}" "${DIR}/local_${sub_count}_${short_hash}.txt"
	sub_mark_active_source_tag "${short_hash}"
	sub_mark_changed_source_tag "${short_hash}"
	SUB_LOCAL_CHANGED=1
	return 0
}

sub_prepare_schema2_raw_jsonl(){
	local blob_file order_file
	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ -s "${SCHEMA2_RAW_JSONL}" ] && return 0
	mkdir -p "${DIR}"
	blob_file="${DIR}/schema2_node_blobs.txt"
	order_file="${DIR}/schema2_node_order.txt"
	dbus list fss_node_ 2>/dev/null | while IFS= read -r line
	do
		case "${line}" in
		fss_node_[0-9]*=*)
			local key="${line%%=*}"
			local node_id="${key#fss_node_}"
			local blob="${line#*=}"
			printf '%s\t%s\n' "${node_id}" "${blob}"
			;;
		esac
	done > "${blob_file}"
	printf '%s' "$(dbus get fss_node_order)" | tr ',' '\n' | sed '/^$/d' > "${order_file}"
	: > "${SCHEMA2_RAW_JSONL}"
	if [ -s "${order_file}" ];then
		awk -F '\t' '
			NR == FNR { order[++count] = $1; next }
			{ blob[$1] = $2 }
			END {
				for (i = 1; i <= count; i++) {
					if (order[i] in blob) {
						print blob[order[i]]
					}
				}
			}
		' "${order_file}" "${blob_file}" | while IFS= read -r blob
		do
			[ -n "${blob}" ] || continue
			fss_b64_decode "${blob}"
			echo
		done > "${SCHEMA2_RAW_JSONL}"
	else
		awk -F '\t' '{print $2}' "${blob_file}" | while IFS= read -r blob
		do
			[ -n "${blob}" ] || continue
			fss_b64_decode "${blob}"
			echo
		done > "${SCHEMA2_RAW_JSONL}"
	fi
	rm -f "${blob_file}" "${order_file}"
	return 0
}

sub_prepare_schema2_export_jsonl(){
	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ -f "${SCHEMA2_EXPORT_JSONL}" ] && return 0
	local node_tool=""
	node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
	if [ -n "${node_tool}" ];then
		if "${node_tool}" node2json --format jsonl > "${SCHEMA2_EXPORT_JSONL}.tmp.$$" 2>/dev/null;then
			if [ ! -s "${SCHEMA2_EXPORT_JSONL}.tmp.$$" ];then
				: > "${SCHEMA2_EXPORT_JSONL}"
				rm -f "${SCHEMA2_EXPORT_JSONL}.tmp.$$"
				return 0
			fi
			if sub_file_has_identity_fields "${SCHEMA2_EXPORT_JSONL}.tmp.$$";then
				mv -f "${SCHEMA2_EXPORT_JSONL}.tmp.$$" "${SCHEMA2_EXPORT_JSONL}"
			else
				sub_prepare_identity_view_file "${SCHEMA2_EXPORT_JSONL}.tmp.$$" "${SCHEMA2_EXPORT_JSONL}" "" "" "" "" || {
					rm -f "${SCHEMA2_EXPORT_JSONL}.tmp.$$" "${SCHEMA2_EXPORT_JSONL}"
					return 1
				}
				rm -f "${SCHEMA2_EXPORT_JSONL}.tmp.$$"
			fi
			return 0
		fi
		rm -f "${SCHEMA2_EXPORT_JSONL}.tmp.$$" >/dev/null 2>&1
	fi
	local tmp_export="${SCHEMA2_EXPORT_JSONL}.tmp.$$"
	sub_prepare_schema2_raw_jsonl || return 1
	if [ ! -s "${SCHEMA2_RAW_JSONL}" ];then
		: > "${SCHEMA2_EXPORT_JSONL}"
		return 0
	fi
	jq -c '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
		with_entries(select(.value != "" and .value != null))
		| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
		| if has("xray_json") then .xray_json |= normalize_json_config else . end
		| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
		| del(._schema, ._rev, ._updated_at, ._created_at, ._migrated_from, .server_ip, .latency, .ping)
	' "${SCHEMA2_RAW_JSONL}" > "${tmp_export}" || {
		rm -f "${tmp_export}"
		return 1
	}
	if sub_file_has_identity_fields "${tmp_export}";then
		mv -f "${tmp_export}" "${SCHEMA2_EXPORT_JSONL}"
	else
		sub_prepare_identity_view_file "${tmp_export}" "${SCHEMA2_EXPORT_JSONL}" "" "" "" "" || {
			rm -f "${tmp_export}" "${SCHEMA2_EXPORT_JSONL}"
			return 1
		}
		rm -f "${tmp_export}"
	fi
	return 0
}

sub_extract_groups_from_file(){
	local file_path="$1"
	[ -f "${file_path}" ] || return 0
	jq -r '.group // "null"' "${file_path}" 2>/dev/null
}

sub_first_line_meta_tsv(){
	local file_path="$1"
	local first_line=""
	[ -f "${file_path}" ] || return 0
	first_line="$(sed -n '1p' "${file_path}" 2>/dev/null)"
	[ -n "${first_line}" ] || return 0
	printf '%s' "${first_line}" | jq -r '[
		(._airport_identity // ""),
		(._source_scope // ""),
		(._source_url_hash // ""),
		(.group // "")
	] | join("\u001f")' 2>/dev/null
}

sub_refresh_node_state(){
	NODES_SEQ=$(sub_list_node_ids | tr '\n' ' ' | sed 's/[[:space:]]$//')
	NODE_INDEX=$(sub_list_node_ids | sed -n '$p')
	SEQ_NU=$(sub_list_node_ids | sed '/^$/d' | wc -l)
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		CURR_NODE=$(fss_get_current_node_id)
		FAILOVER_NODE=$(fss_get_failover_node_id)
	else
		CURR_NODE=$(dbus get ssconf_basic_node)
		FAILOVER_NODE=$(dbus get ss_failover_s4_3)
	fi
	[ -z "${CURR_NODE}" ] && CURR_NODE=$(sub_list_node_ids | sed -n '1p')
	if [ -n "${CURR_NODE}" ] && ! sub_node_exists_in_order "${CURR_NODE}";then
		CURR_NODE=$(sub_list_node_ids | sed -n '1p')
	fi
}

sub_resolve_field_name(){
	fss_resolve_node_field_name "$1"
}

sub_get_node_field_plain(){
	local node_id="$1"
	local field="$2"

	[ -z "${node_id}" ] && return 1
	[ -z "${field}" ] && return 1
	fss_get_node_field_plain "${node_id}" "${field}"
}

sub_get_node_server_plain(){
	local node_id="$1"
	local server
	server=$(sub_get_node_field_plain "${node_id}" server)
	[ -z "${server}" ] && server=$(sub_get_node_field_plain "${node_id}" hy2_server)
	printf '%s' "${server}"
}

sub_get_node_port_plain(){
	local node_id="$1"
	local port
	port=$(sub_get_node_field_plain "${node_id}" port)
	[ -z "${port}" ] && port=$(sub_get_node_field_plain "${node_id}" hy2_port)
	printf '%s' "${port}"
}

sub_get_node_identity_plain(){
	local node_id="$1"
	local value=""
	local node_json=""
	[ -z "${node_id}" ] && return 1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		value=$(fss_get_node_identity_by_id "${node_id}" 2>/dev/null)
		[ -n "${value}" ] && {
			printf '%s' "${value}"
			return 0
		}
	fi
	node_json=$(sub_export_local_node_json "${node_id}" 2>/dev/null) || return 1
	node_json=$(fss_enrich_node_identity_json "${node_json}" "" "" "" "" 2>/dev/null) || return 1
	fss_unpack_node_meta "${node_json}" || return 1
	value="${FSS_NODE_META_IDENTITY}"
	printf '%s' "${value}"
}

sub_get_node_snapshot_plain(){
	local node_id="$1"
	local node_json=""
	[ -z "${node_id}" ] && return 1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		node_json=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null) || return 1
		[ -n "${node_json}" ] || return 1
		fss_node_json_snapshot_tsv "${node_json}"
		return 0
	fi
	node_json=$(sub_export_local_node_json "${node_id}" 2>/dev/null) || return 1
	[ -n "${node_json}" ] || return 1
	fss_node_json_snapshot_tsv "${node_json}"
}

sub_node_exists_in_order(){
	local node_id="$1"
	[ -z "${node_id}" ] && return 1
	sub_list_node_ids | grep -Fxq "${node_id}"
}

sub_capture_active_nodes(){
	local current_snapshot=""
	local failover_snapshot=""
	local sep="$(printf '\037')"
	sub_refresh_node_state
	current_snapshot=$(sub_get_node_snapshot_plain "${CURR_NODE}" 2>/dev/null)
	IFS="${sep}" read -r CURR_NODE_NAME CURR_NODE_TYPE CURR_NODE_SERVER CURR_NODE_PORT CURR_NODE_IDENTITY <<-EOF
	${current_snapshot}
	EOF
	[ -n "${CURR_NODE_IDENTITY}" ] || CURR_NODE_IDENTITY=$(sub_get_node_identity_plain "${CURR_NODE}")
	failover_snapshot=$(sub_get_node_snapshot_plain "${FAILOVER_NODE}" 2>/dev/null)
	IFS="${sep}" read -r FAILOVER_NODE_NAME FAILOVER_NODE_TYPE FAILOVER_NODE_SERVER FAILOVER_NODE_PORT FAILOVER_NODE_IDENTITY <<-EOF
	${failover_snapshot}
	EOF
	[ -n "${FAILOVER_NODE_IDENTITY}" ] || FAILOVER_NODE_IDENTITY=$(sub_get_node_identity_plain "${FAILOVER_NODE}")
}

sub_find_node_id_in_file(){
	local file="$1"
	local name="$2"
	local type="$3"
	local server="$4"
	local port="$5"
	[ -f "${file}" ] || return 1
	jq -r \
		--arg name "${name}" \
		--arg type "${type}" \
		--arg server "${server}" \
		--arg port "${port}" \
	'select((.name // "") == $name and (.type // "") == $type and ((.server // .hy2_server // "") == $server) and ((.port // .hy2_port // "") == $port)) | ._id // empty' \
		"${file}" 2>/dev/null | sed -n '1p'
}

sub_find_node_id_by_identity_in_file(){
	local file="$1"
	local identity="$2"
	[ -f "${file}" ] || return 1
	[ -n "${identity}" ] || return 1
	jq -r --arg identity "${identity}" 'select((._identity // "") == $identity) | ._id // empty' "${file}" 2>/dev/null | sed -n '1p'
}

sub_export_local_node_json(){
	local node_id="$1"
	local node_tool=""
	[ -z "${node_id}" ] && return 1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
		if [ -n "${node_tool}" ];then
			"${node_tool}" node2json --ids "${node_id}" --format jsonl 2>/dev/null | sed -n '1p'
			return 0
		fi
		fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null | jq -c '
			def normalize_json_config:
				. as $raw
				| if (($raw | type) != "string") or $raw == "" then
					$raw
				else
					(
						try ($raw | fromjson | tojson)
						catch (
							try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
							catch $raw
						)
					)
				end;
			with_entries(select(.value != "" and .value != null))
			| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
			| if has("xray_json") then .xray_json |= normalize_json_config else . end
			| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
			| del(._schema, ._rev, ._source, ._updated_at, ._created_at, ._migrated_from, .server_ip, .latency, .ping)
		'
	else
		fss_build_legacy_node_json "${node_id}" | jq -c .
	fi
}

sub_nodes_file_md5(){
	local file="$1"
	[ -f "${file}" ] || return 1
	jq -S -c '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
			def legacy_b64_mode:
				((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
			def decode_b64_field($field):
				if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
					.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
				else
					.
				end;
		decode_b64_field("password")
		| decode_b64_field("naive_pass")
		| decode_b64_field("v2ray_json")
		| decode_b64_field("xray_json")
		| decode_b64_field("tuic_json")
		| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
		| if has("xray_json") then .xray_json |= normalize_json_config else . end
		| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
		| del(._id, ._schema, ._rev, ._source, ._updated_at, ._created_at, ._migrated_from, ._b64_mode, .server_ip, .latency, .ping)
	' "${file}" 2>/dev/null | md5sum | awk '{print $1}'
}

sub_nodes_file_sorted_md5(){
	local file="$1"
	[ -f "${file}" ] || return 1
	jq -S -c '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
			def legacy_b64_mode:
				((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
			def decode_b64_field($field):
				if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
					.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
				else
					.
				end;
		decode_b64_field("password")
		| decode_b64_field("naive_pass")
		| decode_b64_field("v2ray_json")
		| decode_b64_field("xray_json")
		| decode_b64_field("tuic_json")
		| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
		| if has("xray_json") then .xray_json |= normalize_json_config else . end
		| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
		| del(._id, ._schema, ._rev, ._source, ._updated_at, ._created_at, ._migrated_from, ._b64_mode, .server_ip, .latency, .ping)
	' "${file}" 2>/dev/null | sort | md5sum | awk '{print $1}'
}

sub_nodes_file_identity_md5(){
	local file="$1"
	[ -f "${file}" ] || return 1
	jq -r '[.type // "", .xray_prot // "", .name // ""] | @tsv' "${file}" 2>/dev/null | sort -u | md5sum | awk '{print $1}'
}

sub_file_has_identity_fields(){
	local file="$1"
	local total=0
	local identity_hits=0
	local primary_hits=0
	local secondary_hits=0

	[ -s "${file}" ] || return 1
	total=$(wc -l < "${file}" 2>/dev/null | tr -d ' ')
	[ -n "${total}" ] || total=0
	[ "${total}" -gt 0 ] || return 1
	identity_hits=$(grep -c '"_identity":"[^"]\+"' "${file}" 2>/dev/null || true)
	primary_hits=$(grep -c '"_identity_primary":"[^"]\+"' "${file}" 2>/dev/null || true)
	secondary_hits=$(grep -c '"_identity_secondary":"[^"]\+"' "${file}" 2>/dev/null || true)
	[ "${identity_hits}" = "${total}" ] || return 1
	[ "${primary_hits}" = "${total}" ] || return 1
	[ "${secondary_hits}" = "${total}" ]
}

sub_file_has_complete_numeric_ids(){
	local file="$1"
	local total=0
	local id_hits=0

	[ -s "${file}" ] || return 1
	total=$(wc -l < "${file}" 2>/dev/null | tr -d ' ')
	[ -n "${total}" ] || total=0
	[ "${total}" -gt 0 ] || return 1
	id_hits=$(jq -r 'select(((._id // "") | tostring | test("^[0-9]+$")))|1' "${file}" 2>/dev/null | wc -l | tr -d ' ')
	[ -n "${id_hits}" ] || id_hits=0
	[ "${id_hits}" = "${total}" ]
}

sub_prepare_identity_view_file(){
	local input_file="$1"
	local output_file="$2"
	local explicit_airport="$3"
	local explicit_scope="$4"
	local explicit_url_hash="$5"
	local explicit_source="$6"

	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	if sub_file_has_identity_fields "${input_file}";then
		cp -f "${input_file}" "${output_file}"
		return 0
	fi
	fss_enrich_node_identity_file "${input_file}" "${output_file}" "${explicit_airport}" "${explicit_scope}" "${explicit_url_hash}" "${explicit_source}"
}

sub_prepare_canonical_identity_view_file(){
	local input_file="$1"
	local output_file="$2"
	local explicit_airport="$3"
	local explicit_scope="$4"
	local explicit_url_hash="$5"
	local explicit_source="$6"
	local tmp_file="${output_file}.canon.$$"

	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	jq -c '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
		def legacy_b64_mode:
			((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
		def decode_b64_field($field):
			if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
				.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
			else
				.
			end;
		with_entries(select(.value != "" and .value != null))
		| decode_b64_field("password")
		| decode_b64_field("naive_pass")
		| decode_b64_field("v2ray_json")
		| decode_b64_field("xray_json")
		| decode_b64_field("tuic_json")
		| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
		| if has("xray_json") then .xray_json |= normalize_json_config else . end
		| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
		| del(
			._airport_identity,
			._source_scope,
			._identity_primary,
			._identity_secondary,
			._identity,
			._identity_ver
		)
	' "${input_file}" > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	fss_enrich_node_identity_file "${tmp_file}" "${output_file}" "${explicit_airport}" "${explicit_scope}" "${explicit_url_hash}" "${explicit_source}" || {
		rm -f "${tmp_file}" "${output_file}"
		return 1
	}
	rm -f "${tmp_file}"
}

sub_prepare_current_nodes_identity_export(){
	local output_file="$1"
	local tmp_export=""
	local node_id=""
	[ -n "${output_file}" ] || return 1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		sub_prepare_schema2_export_jsonl || return 1
		cp -f "${SCHEMA2_EXPORT_JSONL}" "${output_file}"
		return 0
	fi
	tmp_export="${output_file}.tmp.$$"
	: > "${tmp_export}"
	for node_id in $(sub_list_node_ids)
	do
		[ -n "${node_id}" ] || continue
		sub_export_local_node_json "${node_id}" >> "${tmp_export}" || true
		echo >> "${tmp_export}"
	done
	sub_prepare_identity_view_file "${tmp_export}" "${output_file}" "" "" "" "" || {
		rm -f "${tmp_export}" "${output_file}"
		return 1
	}
	rm -f "${tmp_export}"
}

keyword_filter_alias_tokens(){
	case "$1" in
	*香港*|*[Hh][Oo][Nn][Gg]*|HK|hk|Hk|hK)
		printf '%s\n' '香港|[Hh][Oo][Nn][Gg][[:space:]]*[Kk][Oo][Nn][Gg]|[Hh][Oo][Nn][Gg]|(^|[^[:alnum:]])[Hh][Kk]([0-9]|[^[:alpha:]]|$)'
		;;
	*新加坡*|*[Ss][Ii][Nn][Gg]*|SG|sg|Sg|sG)
		printf '%s\n' '新加坡|[Ss][Ii][Nn][Gg][Aa][Pp][Oo][Rr][Ee]|[Ss][Ii][Nn][Gg]|(^|[^[:alnum:]])[Ss][Gg]([0-9]|[^[:alpha:]]|$)'
		;;
	*美国*|*美國*|*[Uu][Nn][Ii][Tt][Ee][Dd]*[Ss][Tt][Aa][Tt][Ee][Ss]*|*[Aa][Mm][Ee][Rr][Ii][Cc][Aa]*|USA|usa|US|us)
		printf '%s\n' '美国|美國|[Uu][Nn][Ii][Tt][Ee][Dd][[:space:]]*[Ss][Tt][Aa][Tt][Ee][Ss]|USA|usa|(^|[^[:alnum:]])[Uu][Ss]([0-9]|[^[:alpha:]]|$)|[Aa][Mm][Ee][Rr][Ii][Cc][Aa]'
		;;
	*日本*|*[Jj][Aa][Pp][Aa][Nn]*|JP|jp)
		printf '%s\n' '日本|[Jj][Aa][Pp][Aa][Nn]|(^|[^[:alnum:]])[Jj][Pp]([0-9]|[^[:alpha:]]|$)'
		;;
	*台湾*|*台灣*|*[Tt][Aa][Ii][Ww][Aa][Nn]*|TW|tw)
		printf '%s\n' '台湾|台灣|[Tt][Aa][Ii][Ww][Aa][Nn]|(^|[^[:alnum:]])[Tt][Ww]([0-9]|[^[:alpha:]]|$)'
		;;
	*韩国*|*韓國*|*[Kk][Oo][Rr][Ee][Aa]*|KR|kr)
		printf '%s\n' '韩国|韓國|[Kk][Oo][Rr][Ee][Aa]|(^|[^[:alnum:]])[Kk][Rr]([0-9]|[^[:alpha:]]|$)'
		;;
	*英国*|*英國*|*[Uu][Nn][Ii][Tt][Ee][Dd]*[Kk][Ii][Nn][Gg][Dd][Oo][Mm]*|*[Bb][Rr][Ii][Tt][Aa][Ii][Nn]*|UK|uk|GB|gb)
		printf '%s\n' '英国|英國|[Uu][Nn][Ii][Tt][Ee][Dd][[:space:]]*[Kk][Ii][Nn][Gg][Dd][Oo][Mm]|[Bb][Rr][Ii][Tt][Aa][Ii][Nn]|(^|[^[:alnum:]])([Uu][Kk]|[Gg][Bb])([0-9]|[^[:alpha:]]|$)'
		;;
	*德国*|*德國*|*[Gg][Ee][Rr][Mm][Aa][Nn][Yy]*|DE|de)
		printf '%s\n' '德国|德國|[Gg][Ee][Rr][Mm][Aa][Nn][Yy]|(^|[^[:alnum:]])[Dd][Ee]([0-9]|[^[:alpha:]]|$)'
		;;
	*法国*|*法國*|*[Ff][Rr][Aa][Nn][Cc][Ee]*|FR|fr)
		printf '%s\n' '法国|法國|[Ff][Rr][Aa][Nn][Cc][Ee]|(^|[^[:alnum:]])[Ff][Rr]([0-9]|[^[:alpha:]]|$)'
		;;
	*荷兰*|*荷蘭*|*[Nn][Ee][Tt][Hh][Ee][Rr][Ll][Aa][Nn][Dd][Ss]*|*[Hh][Oo][Ll][Ll][Aa][Nn][Dd]*|NL|nl)
		printf '%s\n' '荷兰|荷蘭|[Nn][Ee][Tt][Hh][Ee][Rr][Ll][Aa][Nn][Dd][Ss]|[Hh][Oo][Ll][Ll][Aa][Nn][Dd]|(^|[^[:alnum:]])[Nn][Ll]([0-9]|[^[:alpha:]]|$)'
		;;
	*加拿大*|*[Cc][Aa][Nn][Aa][Dd][Aa]*|CA|ca)
		printf '%s\n' '加拿大|[Cc][Aa][Nn][Aa][Dd][Aa]|(^|[^[:alnum:]])[Cc][Aa]([0-9]|[^[:alpha:]]|$)'
		;;
	*澳大利亚*|*澳大利亞*|*澳洲*|*[Aa][Uu][Ss][Tt][Rr][Aa][Ll][Ii][Aa]*|AU|au)
		printf '%s\n' '澳大利亚|澳大利亞|澳洲|[Aa][Uu][Ss][Tt][Rr][Aa][Ll][Ii][Aa]|(^|[^[:alnum:]])[Aa][Uu]([0-9]|[^[:alpha:]]|$)'
		;;
	*俄罗斯*|*俄羅斯*|*[Rr][Uu][Ss][Ss][Ii][Aa]*|RU|ru)
		printf '%s\n' '俄罗斯|俄羅斯|[Rr][Uu][Ss][Ss][Ii][Aa]|(^|[^[:alnum:]])[Rr][Uu]([0-9]|[^[:alpha:]]|$)'
		;;
	*)
		return 1
		;;
	esac
}

keyword_filter_short_ascii_code(){
	case "$1" in
	[A-Za-z][A-Za-z])
		return 0
		;;
	*)
		return 1
		;;
	esac
}

keyword_filter_match_token_text(){
	local text="$1"
	local token="$2"
	local alias_pattern=""
	[ -n "${token}" ] || return 1
	if keyword_filter_short_ascii_code "${token}";then
		if printf '%s' "${text}" | grep -Eiq "(^|[^[:alnum:]])${token}([0-9]|[^[:alpha:]]|$)" 2>/dev/null;then
			printf '%s' "${text}" | grep -Eio "(^|[^[:alnum:]])${token}([0-9]|[^[:alpha:]]|$)" 2>/dev/null | sed -n '1p'
			return 0
		fi
	else
		if printf '%s' "${text}" | grep -Eiq "${token}" 2>/dev/null; then
			printf '%s' "${text}" | grep -Eio "${token}" 2>/dev/null | sed -n '1p'
			return 0
		fi
	fi
	alias_pattern="$(keyword_filter_alias_tokens "${token}" 2>/dev/null)" || alias_pattern=""
	[ -n "${alias_pattern}" ] || return 1
	if printf '%s' "${text}" | grep -Eiq "${alias_pattern}" 2>/dev/null; then
		printf '%s' "${text}" | grep -Eio "${alias_pattern}" 2>/dev/null | sed -n '1p'
		return 0
	fi
	return 1
}

keyword_filter_match_text(){
	local text="$1"
	local pattern="$2"
	local token=""
	[ -n "${pattern}" ] || return 1
	while IFS= read -r token
	do
		[ -n "${token}" ] || continue
		keyword_filter_match_token_text "${text}" "${token}" && return 0
	done <<EOF
$(printf '%s' "${pattern}" | tr '|' '\n')
EOF
	return 1
}

sub_filter_offline_duplicate_nodes(){
	local input_file="$1"
	local current_file="${input_file}.current.$$"
	local identity_file="${input_file}.identity.$$"
	local seen_pairs="${input_file}.seen_pairs.$$"
	local import_map="${input_file}.import_map.$$"
	local filtered_file="${input_file}.filtered.$$"
	local duplicate_count=0
	local salt_idx=0
	local node_name=""
	local node_secondary=""
	local blob=""
	local pair=""
	local new_name=""
	local new_pair=""
	local raw_json=""
	local renamed_json=""
	local updated_json=""
	local suffix=""

	[ -s "${input_file}" ] || return 0
	sub_prepare_current_nodes_identity_export "${current_file}" || return 0
	[ -s "${current_file}" ] || {
		rm -f "${current_file}"
		return 0
	}
	sub_prepare_identity_view_file "${input_file}" "${identity_file}" "local" "local" "" "manual" || {
		rm -f "${current_file}" "${identity_file}"
		return 0
	}

	run jq -r '[.name // "", ._identity_secondary // ""] | @tsv' "${current_file}" 2>/dev/null | sort -u > "${seen_pairs}" || {
		rm -f "${current_file}" "${identity_file}" "${seen_pairs}"
		return 0
	}
	run jq -r '[.name // "", ._identity_secondary // "", (. | @base64)] | @tsv' "${identity_file}" 2>/dev/null > "${import_map}" || {
		rm -f "${current_file}" "${identity_file}" "${seen_pairs}" "${import_map}"
		return 0
	}

	: > "${filtered_file}"
	while IFS='	' read -r node_name node_secondary blob
	do
		[ -n "${blob}" ] || continue
		pair=$(printf '%s\t%s' "${node_name}" "${node_secondary}")
		if grep -Fqx "${pair}" "${seen_pairs}" 2>/dev/null;then
			duplicate_count=$((duplicate_count + 1))
			raw_json=$(printf '%s' "${blob}" | base64 -d 2>/dev/null)
			[ -n "${raw_json}" ] || continue
			while : ;do
				salt_idx=$((salt_idx + 1))
				if [ -r "/proc/sys/kernel/random/uuid" ];then
					suffix=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | cut -c1-4)
				else
					suffix=$(printf '%s' "${node_name}_${node_secondary}_${salt_idx}_$$_$(date +%s)" | fss_identity_hash_v1 | cut -c1-4)
				fi
				[ -n "${suffix}" ] || suffix=$(printf '%04d' "${salt_idx}")
				new_name="${node_name}-${suffix}"
				new_pair=$(printf '%s\t%s' "${new_name}" "${node_secondary}")
				if ! grep -Fqx "${new_pair}" "${seen_pairs}" 2>/dev/null;then
					break
				fi
			done
			updated_json=$(printf '%s' "${raw_json}" | jq -c --arg name "${new_name}" '.name = $name' 2>/dev/null) || updated_json=""
			[ -n "${updated_json}" ] || updated_json="${raw_json}"
			renamed_json="${updated_json}"
			updated_json=$(fss_enrich_node_identity_json "${renamed_json}" "local" "local" "" "manual" 2>/dev/null) || true
			[ -n "${updated_json}" ] || updated_json="${renamed_json}"
			printf '%s\n' "${updated_json}" >> "${filtered_file}"
			printf '%s\n' "${new_pair}" >> "${seen_pairs}"
			echo_date "ℹ️离线节点解析完毕，检测到名字和参数相同节点，已将节点名改为${new_name}"
			continue
		fi
		printf '%s' "${blob}" | base64 -d >> "${filtered_file}" 2>/dev/null || true
		echo >> "${filtered_file}"
		printf '%s\n' "${pair}" >> "${seen_pairs}"
	done < "${import_map}"

	if [ "${duplicate_count}" -eq 0 ];then
		rm -f "${current_file}" "${identity_file}" "${seen_pairs}" "${import_map}" "${filtered_file}"
		return 0
	fi

	mv -f "${filtered_file}" "${input_file}"
	rm -f "${current_file}" "${identity_file}" "${seen_pairs}" "${import_map}"
	return 0
}

sub_file_identity_scope_matches(){
	local file="$1"
	local airport_identity="$2"
	local source_scope="$3"
	local source_url_hash="$4"
	local first_airport=""
	local first_scope=""
	local first_hash=""
	local first_group=""
	local first_meta=""
	local sep="$(printf '\037')"

	[ -s "${file}" ] || return 1
	first_meta="$(sub_first_line_meta_tsv "${file}")" || first_meta=""
	IFS="${sep}" read -r first_airport first_scope first_hash first_group <<-EOF
	${first_meta}
	EOF
	[ "${first_airport}" = "${airport_identity}" ] || return 1
	[ "${first_scope}" = "${source_scope}" ] || return 1
	[ "${first_hash}" = "${source_url_hash}" ]
}

sub_mark_map_row_used(){
	local used_file="$1"
	local row_no="$2"
	[ -f "${used_file}" ] || return 1
	[ -n "${row_no}" ] || return 1
	grep -Fxq "${row_no}" "${used_file}" 2>/dev/null || echo "${row_no}" >> "${used_file}"
}

sub_find_first_unused_map_row(){
	local map_file="$1"
	local used_file="$2"
	local field_no="$3"
	local match_value="$4"
	local delim="$(printf '\037')"
	[ -f "${map_file}" ] || return 1
	[ -f "${used_file}" ] || return 1
	[ -n "${field_no}" ] || return 1
	[ -n "${match_value}" ] || return 1
	awk -v FS="${delim}" -v used_file="${used_file}" -v field_no="${field_no}" -v match_value="${match_value}" '
		BEGIN {
			while ((getline line < used_file) > 0) {
				used[line] = 1
			}
		}
		!($1 in used) && $(field_no) == match_value {
			print $1
			exit
		}
	' "${map_file}" 2>/dev/null | sed -n '1p'
}

sub_find_unique_unused_map_row(){
	local map_file="$1"
	local used_file="$2"
	local field_no="$3"
	local match_value="$4"
	local delim="$(printf '\037')"
	[ -f "${map_file}" ] || return 1
	[ -f "${used_file}" ] || return 1
	[ -n "${field_no}" ] || return 1
	[ -n "${match_value}" ] || return 1
	awk -v FS="${delim}" -v used_file="${used_file}" -v field_no="${field_no}" -v match_value="${match_value}" '
		BEGIN {
			while ((getline line < used_file) > 0) {
				used[line] = 1
			}
		}
		!($1 in used) && $(field_no) == match_value {
			count++
			if (count == 1) {
				first = $1
			}
		}
		END {
			if (count > 0) {
				printf "%s\t%s\n", count, first
			}
		}
	' "${map_file}" 2>/dev/null
}

sub_get_map_row_by_no(){
	local map_file="$1"
	local row_no="$2"
	local delim="$(printf '\037')"
	[ -f "${map_file}" ] || return 1
	[ -n "${row_no}" ] || return 1
	awk -v FS="${delim}" -v row_no="${row_no}" '$1 == row_no {print; exit}' "${map_file}" 2>/dev/null
}

sub_build_identity_change_map(){
	local input_file="$1"
	local output_file="$2"
	local delim="$(printf '\037')"
	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	run jq -r '[._identity // "", ._identity_primary // "", ._identity_secondary // "", ._source_scope // "", ._airport_identity // "", .type // "", .xray_prot // "", .name // "", ((._source_scope // "") + "|" + (._identity_secondary // ""))] | join("\u001f")' "${input_file}" 2>/dev/null \
		| awk -v fs="${delim}" 'BEGIN{FS=fs; OFS=fs} {print NR, $0}' > "${output_file}"
}

sub_log_nodes_file_change_detail(){
	local local_file="$1"
	local online_file="$2"
	local sub_tool=""
	local compare_file=""
	local reason=""
	local old_id=""
	local new_id=""
	local type_id=""
	local xray_prot=""
	local old_name=""
	local new_name=""
	local local_identity_file=""
	local online_identity_file=""
	local local_map=""
	local online_map=""
	local old_used=""
	local new_used=""
	local exact_new_row=""
	local exact_new_line=""
	local unique_match=""
	local match_count=""
	local match_row=""
	local match_line=""
	local old_row=""
	local old_identity=""
	local old_primary=""
	local old_secondary=""
	local old_scope=""
	local old_airport=""
	local old_type=""
	local old_xray=""
	local old_name=""
	local old_scope_secondary=""
	local new_row=""
	local new_identity=""
	local new_primary=""
	local new_secondary=""
	local new_scope=""
	local new_airport=""
	local new_type=""
	local new_xray=""
	local new_name=""
	local new_scope_secondary=""
	local prefix=""
	local delim="$(printf '\037')"
	local param_changed=0
	local renamed=0
	local deleted=0
	local added=0

	[ "${SUB_TOOL_NODE_LOG}" = "1" ] || return 0
	[ -f "${local_file}" ] || return 0
	[ -f "${online_file}" ] || return 0

	sub_tool="$(pick_sub_tool 2>/dev/null)" || sub_tool=""
	if [ -n "${sub_tool}" ];then
		compare_file="${online_file}.compare.$$"
		local_identity_file="${local_file}.identity_cmp.$$"
		online_identity_file="${online_file}.identity_cmp.$$"
		sub_prepare_canonical_identity_view_file "${local_file}" "${local_identity_file}" "" "" "" "" >/dev/null 2>&1 || true
		sub_prepare_canonical_identity_view_file "${online_file}" "${online_identity_file}" "" "" "" "" >/dev/null 2>&1 || true
		if [ -s "${local_identity_file}" ] && [ -s "${online_identity_file}" ] && "${sub_tool}" compare-fancyss --old "${local_identity_file}" --new "${online_identity_file}" --output "${compare_file}" >/dev/null 2>&1;then
			while IFS= read -r line
			do
				[ -n "${line}" ] || continue
				reason=$(printf '%s\n' "${line}" | awk -F '\t' '{print $1}')
				old_id=$(printf '%s\n' "${line}" | awk -F '\t' '{print $2}')
				new_id=$(printf '%s\n' "${line}" | awk -F '\t' '{print $3}')
				type_id=$(printf '%s\n' "${line}" | awk -F '\t' '{print $4}')
				xray_prot=$(printf '%s\n' "${line}" | awk -F '\t' '{print $5}')
				old_name=$(printf '%s\n' "${line}" | awk -F '\t' '{print $6}')
				new_name=$(printf '%s\n' "${line}" | awk -F '\t' '{print $7}')
				case "${reason}" in
				param)
					prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
					echo_date "${prefix}${new_name:-${old_name}}，发现节点参数改变。"
					param_changed=$((param_changed + 1))
					;;
				rename)
					prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
					echo_date "${prefix}${new_name}，发现节点名改变：${old_name} -> ${new_name}"
					renamed=$((renamed + 1))
					;;
				deleted)
					prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
					echo_date "${prefix}${old_name}，检测到节点已删除。"
					deleted=$((deleted + 1))
					;;
				new)
					prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
					echo_date "${prefix}${new_name}，检测到新增节点。"
					added=$((added + 1))
					;;
				esac
			done < "${compare_file}"
			rm -f "${local_identity_file}" "${online_identity_file}" "${compare_file}"
			if [ "$((param_changed + renamed + deleted + added))" -gt "0" ];then
				echo_date "ℹ️节点变更分类：参数改变${param_changed}个，名称改变${renamed}个，新增${added}个，删除${deleted}个。"
			fi
			return 0
		fi
		rm -f "${local_identity_file}" "${online_identity_file}" "${compare_file}"
	fi

	local_identity_file="${local_file}.identity_cmp.$$"
	online_identity_file="${online_file}.identity_cmp.$$"
	local_map="${local_file}.identity_cmp_map.$$"
	online_map="${online_file}.identity_cmp_map.$$"
	old_used="${local_file}.identity_cmp_used_old.$$"
	new_used="${online_file}.identity_cmp_used_new.$$"

	sub_prepare_canonical_identity_view_file "${local_file}" "${local_identity_file}" "" "" "" "" || {
		rm -f "${local_identity_file}" "${online_identity_file}" "${local_map}" "${online_map}" "${old_used}" "${new_used}"
		return 0
	}
	sub_prepare_canonical_identity_view_file "${online_file}" "${online_identity_file}" "" "" "" "" || {
		rm -f "${local_identity_file}" "${online_identity_file}" "${local_map}" "${online_map}" "${old_used}" "${new_used}"
		return 0
	}
	sub_build_identity_change_map "${local_identity_file}" "${local_map}" || {
		rm -f "${local_identity_file}" "${online_identity_file}" "${local_map}" "${online_map}" "${old_used}" "${new_used}"
		return 0
	}
	sub_build_identity_change_map "${online_identity_file}" "${online_map}" || {
		rm -f "${local_identity_file}" "${online_identity_file}" "${local_map}" "${online_map}" "${old_used}" "${new_used}"
		return 0
	}
	: > "${old_used}"
	: > "${new_used}"

	while IFS="${delim}" read -r old_row old_identity old_primary old_secondary old_scope old_airport old_type old_xray old_name old_scope_secondary
	do
		[ -n "${old_row}" ] || continue
		[ -n "${old_identity}" ] || continue
		exact_new_row=$(sub_find_first_unused_map_row "${online_map}" "${new_used}" "2" "${old_identity}")
		[ -n "${exact_new_row}" ] || continue
		sub_mark_map_row_used "${old_used}" "${old_row}" >/dev/null 2>&1
		sub_mark_map_row_used "${new_used}" "${exact_new_row}" >/dev/null 2>&1
	done < "${local_map}"

	while IFS="${delim}" read -r old_row old_identity old_primary old_secondary old_scope old_airport old_type old_xray old_name old_scope_secondary
	do
		[ -n "${old_row}" ] || continue
		grep -Fxq "${old_row}" "${old_used}" 2>/dev/null && continue
		[ -n "${old_primary}" ] || continue
		unique_match=$(sub_find_unique_unused_map_row "${online_map}" "${new_used}" "3" "${old_primary}")
		[ -n "${unique_match}" ] || continue
		match_count=$(printf '%s' "${unique_match}" | awk -F '\t' '{print $1}')
		match_row=$(printf '%s' "${unique_match}" | awk -F '\t' '{print $2}')
		[ "${match_count}" = "1" ] || continue
		match_line=$(sub_get_map_row_by_no "${online_map}" "${match_row}")
		[ -n "${match_line}" ] || continue
		IFS="${delim}" read -r new_row new_identity new_primary new_secondary new_scope new_airport new_type new_xray new_name new_scope_secondary <<-EOF
		${match_line}
		EOF
		prefix=$(sub_fancyss_type_prefix "${new_type:-${old_type}}" "${new_xray:-${old_xray}}")
		echo_date "${prefix}${new_name:-${old_name}}，发现节点参数改变。"
		param_changed=$((param_changed + 1))
		sub_mark_map_row_used "${old_used}" "${old_row}" >/dev/null 2>&1
		sub_mark_map_row_used "${new_used}" "${match_row}" >/dev/null 2>&1
	done < "${local_map}"

	while IFS="${delim}" read -r old_row old_identity old_primary old_secondary old_scope old_airport old_type old_xray old_name old_scope_secondary
	do
		[ -n "${old_row}" ] || continue
		grep -Fxq "${old_row}" "${old_used}" 2>/dev/null && continue
		[ -n "${old_scope_secondary}" ] || continue
		unique_match=$(sub_find_unique_unused_map_row "${online_map}" "${new_used}" "10" "${old_scope_secondary}")
		[ -n "${unique_match}" ] || continue
		match_count=$(printf '%s' "${unique_match}" | awk -F '\t' '{print $1}')
		match_row=$(printf '%s' "${unique_match}" | awk -F '\t' '{print $2}')
		[ "${match_count}" = "1" ] || continue
		match_line=$(sub_get_map_row_by_no "${online_map}" "${match_row}")
		[ -n "${match_line}" ] || continue
		IFS="${delim}" read -r new_row new_identity new_primary new_secondary new_scope new_airport new_type new_xray new_name new_scope_secondary <<-EOF
		${match_line}
		EOF
		[ "${old_name}" != "${new_name}" ] || continue
		prefix=$(sub_fancyss_type_prefix "${new_type:-${old_type}}" "${new_xray:-${old_xray}}")
		echo_date "${prefix}${new_name}，发现节点名改变：${old_name} -> ${new_name}"
		renamed=$((renamed + 1))
		sub_mark_map_row_used "${old_used}" "${old_row}" >/dev/null 2>&1
		sub_mark_map_row_used "${new_used}" "${match_row}" >/dev/null 2>&1
	done < "${local_map}"

	while IFS="${delim}" read -r old_row old_identity old_primary old_secondary old_scope old_airport old_type old_xray old_name old_scope_secondary
	do
		[ -n "${old_row}" ] || continue
		grep -Fxq "${old_row}" "${old_used}" 2>/dev/null && continue
		prefix=$(sub_fancyss_type_prefix "${old_type}" "${old_xray}")
		echo_date "${prefix}${old_name}，检测到节点已删除。"
		deleted=$((deleted + 1))
	done < "${local_map}"

	while IFS="${delim}" read -r new_row new_identity new_primary new_secondary new_scope new_airport new_type new_xray new_name new_scope_secondary
	do
		[ -n "${new_row}" ] || continue
		grep -Fxq "${new_row}" "${new_used}" 2>/dev/null && continue
		prefix=$(sub_fancyss_type_prefix "${new_type}" "${new_xray}")
		echo_date "${prefix}${new_name}，检测到新增节点。"
		added=$((added + 1))
	done < "${online_map}"

	if [ "$((param_changed + renamed + deleted + added))" -gt "0" ];then
		echo_date "ℹ️节点变更分类：参数改变${param_changed}个，名称改变${renamed}个，新增${added}个，删除${deleted}个。"
	fi

	rm -f "${local_identity_file}" "${online_identity_file}" "${local_map}" "${online_map}" "${old_used}" "${new_used}"
	return 0
}

sub_log_nodes_diff_tsv_file(){
	local diff_file="$1"
	local summary_file="$2"
	local line=""
	local reason=""
	local type_id=""
	local xray_prot=""
	local old_name=""
	local new_name=""
	local prefix=""
	local param_changed=0
	local renamed=0
	local deleted=0
	local added=0

	[ -f "${diff_file}" ] || return 0
	while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		reason=$(printf '%s\n' "${line}" | awk -F '\t' '{print $1}')
		type_id=$(printf '%s\n' "${line}" | awk -F '\t' '{print $4}')
		xray_prot=$(printf '%s\n' "${line}" | awk -F '\t' '{print $5}')
		old_name=$(printf '%s\n' "${line}" | awk -F '\t' '{print $6}')
		new_name=$(printf '%s\n' "${line}" | awk -F '\t' '{print $7}')
		case "${reason}" in
		param)
			prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
			echo_date "${prefix}${new_name:-${old_name}}，发现节点参数改变。"
			param_changed=$((param_changed + 1))
			;;
		rename)
			prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
			echo_date "${prefix}${new_name}，发现节点名改变：${old_name} -> ${new_name}"
			renamed=$((renamed + 1))
			;;
		deleted)
			prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
			echo_date "${prefix}${old_name}，检测到节点已删除。"
			deleted=$((deleted + 1))
			;;
		new)
			prefix=$(sub_fancyss_type_prefix "${type_id}" "${xray_prot}")
			echo_date "${prefix}${new_name}，检测到新增节点。"
			added=$((added + 1))
			;;
		esac
	done < "${diff_file}"
	if [ -f "${summary_file}" ];then
		IFS="$(printf '\037')" read -r param_changed renamed added deleted <<-EOF
		$(jq -r '[.param // 0, .rename // 0, .new // 0, .deleted // 0] | join("\u001f")' "${summary_file}" 2>/dev/null)
		EOF
	fi
	if [ "$((param_changed + renamed + deleted + added))" -gt "0" ];then
		echo_date "ℹ️节点变更分类：参数改变${param_changed}个，名称改变${renamed}个，新增${added}个，删除${deleted}个。"
	fi
}

sub_log_nodes_file_change_reason(){
	local local_file="$1"
	local online_file="$2"
	local local_count online_count local_sorted_md5 online_sorted_md5 local_identity_md5 online_identity_md5

	[ -f "${local_file}" ] || return 0
	[ -f "${online_file}" ] || return 0
	local_count=$(wc -l < "${local_file}" 2>/dev/null | tr -d ' ')
	online_count=$(wc -l < "${online_file}" 2>/dev/null | tr -d ' ')
	[ -n "${local_count}" ] || local_count=0
	[ -n "${online_count}" ] || online_count=0
	local_sorted_md5=$(sub_nodes_file_sorted_md5 "${local_file}") || return 0
	online_sorted_md5=$(sub_nodes_file_sorted_md5 "${online_file}") || return 0
	if [ "${local_sorted_md5}" = "${online_sorted_md5}" ];then
		echo_date "ℹ️本地与在线节点内容集合一致，仅节点顺序发生变化，本次仍会判定为更新。"
		return 0
	fi
	local_identity_md5=$(sub_nodes_file_identity_md5 "${local_file}") || return 0
	online_identity_md5=$(sub_nodes_file_identity_md5 "${online_file}") || return 0
	if [ "${local_identity_md5}" = "${online_identity_md5}" ];then
		echo_date "ℹ️本地与在线节点名称集合一致，但连接参数发生变化（如 server/port/relay），本次会正常判定为更新。"
		return 0
	fi
	if [ "${local_count}" = "${online_count}" ];then
		echo_date "ℹ️本地与在线节点数量一致，但节点身份集合发生变化，可能存在重命名、协议切换或节点替换。"
	else
		echo_date "ℹ️本地与在线节点数量从${local_count}变为${online_count}，说明存在新增或删除节点。"
	fi
}

sub_reference_notice_reset(){
	: > "${SCHEMA2_REFERENCE_NOTICE_FILE}"
}

sub_reference_notice_add(){
	local ref_type="$1"
	local title="$2"
	local message="$3"
	local old_id="$4"
	local new_id="$5"
	local reason="$6"
	local level="$7"
	local payload=""

	[ -n "${ref_type}${title}${message}" ] || return 0
	[ -n "${level}" ] || level="warn"
	payload=$(jq -cn \
		--arg type "${ref_type}" \
		--arg title "${title}" \
		--arg message "${message}" \
		--arg old_id "${old_id}" \
		--arg new_id "${new_id}" \
		--arg reason "${reason}" \
		--arg level "${level}" \
		'{
			type: $type,
			title: $title,
			message: $message,
			old_id: $old_id,
			new_id: $new_id,
			reason: $reason,
			level: $level
		}' 2>/dev/null)
	[ -n "${payload}" ] || return 0
	printf '%s\n' "${payload}" >> "${SCHEMA2_REFERENCE_NOTICE_FILE}"
}

sub_parse_shunt_rule_fields(){
	local rule_json="$1"
	[ -n "${rule_json}" ] || return 0
	printf '%s' "${rule_json}" | jq -r '
		def text($v):
			if $v == null then
				""
			elif ($v | type) == "string" then
				$v
			else
				($v | tostring)
			end;
		[
			(text(.target_node_id) | @base64),
			(text(.target_node_identity) | @base64),
			(text(.id) | @base64),
			(text(.remark) | @base64),
			(text(.preset) | @base64)
		] | join("\u001f")
	' 2>/dev/null
}

sub_reference_notice_commit(){
	local payload=""
	[ -s "${SCHEMA2_REFERENCE_NOTICE_FILE}" ] || {
		fss_clear_reference_notice
		return 0
	}
	payload=$(jq -sc --arg ts "$(fss_now_ts_ms)" '{version:"1", ts:$ts, items:.}' "${SCHEMA2_REFERENCE_NOTICE_FILE}" 2>/dev/null)
	[ -n "${payload}" ] || {
		fss_clear_reference_notice
		return 0
	}
	fss_set_reference_notice_json "${payload}"
}

sub_collect_runtime_reference_notice_after_rewrite(){
	local input_file="$1"
	local matched_current=""
	local matched_failover=""
	local restored_current=""
	local restored_failover=""
	local restored_current_name=""
	local restored_failover_name=""

	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 0
	[ -f "${input_file}" ] || return 0
	if [ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] && [ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ];then
		restored_current="$(awk -F '\t' '$1 == "current" {print $4; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)"
		restored_failover="$(awk -F '\t' '$1 == "failover" {print $4; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)"
		if [ -n "${CURR_NODE}" ] && [ -n "${restored_current}" ] && [ "${restored_current}" != "${CURR_NODE}" ];then
			restored_current_name="$(sub_get_node_field_plain "${restored_current}" name)"
			sub_reference_notice_add \
				"current" \
				"运行节点已调整" \
				"原运行节点【${CURR_NODE_NAME:-ID ${CURR_NODE}}】已无法恢复，系统已切换到【${restored_current_name:-ID ${restored_current}}】。请确认当前运行节点。" \
				"${CURR_NODE}" \
				"${restored_current}" \
				"fallback"
		fi
		if [ -n "${FAILOVER_NODE}" ];then
			if [ -n "${restored_failover}" ] && [ "${restored_failover}" != "${FAILOVER_NODE}" ];then
				restored_failover_name="$(sub_get_node_field_plain "${restored_failover}" name)"
				sub_reference_notice_add \
					"failover" \
					"故障转移节点已调整" \
					"原故障转移节点【${FAILOVER_NODE_NAME:-ID ${FAILOVER_NODE}}】已无法恢复，系统已改为【${restored_failover_name:-ID ${restored_failover}}】。请确认故障转移配置。" \
					"${FAILOVER_NODE}" \
					"${restored_failover}" \
					"fallback"
			elif [ -z "${restored_failover}" ];then
				sub_reference_notice_add \
					"failover" \
					"故障转移节点已失效" \
					"原故障转移节点【${FAILOVER_NODE_NAME:-ID ${FAILOVER_NODE}}】已无法恢复，当前已清空故障转移目标，请重新选择。" \
					"${FAILOVER_NODE}" \
					"" \
					"missing"
			fi
		fi
		return 0
	fi
	if sub_node_exists_in_order "${CURR_NODE}";then
		if [ -z "${FAILOVER_NODE}" ] || sub_node_exists_in_order "${FAILOVER_NODE}";then
			return 0
		fi
	fi

	restored_current="$(fss_get_current_node_id 2>/dev/null)"
	restored_failover="$(fss_get_failover_node_id 2>/dev/null)"

	if [ -n "${CURR_NODE}" ];then
		matched_current="$(sub_find_node_id_by_identity_in_file "${input_file}" "${CURR_NODE_IDENTITY}")"
		if [ -z "${matched_current}" ];then
			matched_current="$(sub_find_node_id_in_file "${input_file}" "${CURR_NODE_NAME}" "${CURR_NODE_TYPE}" "${CURR_NODE_SERVER}" "${CURR_NODE_PORT}")"
		fi
		if [ -z "${matched_current}" ] && [ -n "${restored_current}" ] && [ "${restored_current}" != "${CURR_NODE}" ];then
			restored_current_name="$(sub_get_node_field_plain "${restored_current}" name)"
			sub_reference_notice_add \
				"current" \
				"运行节点已调整" \
				"原运行节点【${CURR_NODE_NAME:-ID ${CURR_NODE}}】已无法恢复，系统已切换到【${restored_current_name:-ID ${restored_current}}】。请确认当前运行节点。" \
				"${CURR_NODE}" \
				"${restored_current}" \
				"fallback"
		fi
	fi

	if [ -n "${FAILOVER_NODE}" ];then
		matched_failover="$(sub_find_node_id_by_identity_in_file "${input_file}" "${FAILOVER_NODE_IDENTITY}")"
		if [ -z "${matched_failover}" ];then
			matched_failover="$(sub_find_node_id_in_file "${input_file}" "${FAILOVER_NODE_NAME}" "${FAILOVER_NODE_TYPE}" "${FAILOVER_NODE_SERVER}" "${FAILOVER_NODE_PORT}")"
		fi
		if [ -z "${matched_failover}" ];then
			if [ -n "${restored_failover}" ] && [ "${restored_failover}" != "${FAILOVER_NODE}" ];then
				restored_failover_name="$(sub_get_node_field_plain "${restored_failover}" name)"
				sub_reference_notice_add \
					"failover" \
					"故障转移节点已调整" \
					"原故障转移节点【${FAILOVER_NODE_NAME:-ID ${FAILOVER_NODE}}】已无法恢复，系统已改为【${restored_failover_name:-ID ${restored_failover}}】。请确认故障转移配置。" \
					"${FAILOVER_NODE}" \
					"${restored_failover}" \
					"fallback"
			else
				sub_reference_notice_add \
					"failover" \
					"故障转移节点已失效" \
					"原故障转移节点【${FAILOVER_NODE_NAME:-ID ${FAILOVER_NODE}}】已无法恢复，当前已清空故障转移目标，请重新选择。" \
					"${FAILOVER_NODE}" \
					"" \
					"missing"
			fi
		fi
	fi
}

sub_node_tool_plan_current_changed(){
	[ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	[ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	awk -F '\t' '
		$1 == "current" {
			if ($2 != $4 || $3 != $5) found = 1
			seen = 1
			exit
		}
		END { exit(found ? 0 : 1) }
	' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null
}

sub_node_tool_plan_failover_changed(){
	[ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	[ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	awk -F '\t' '
		$1 == "failover" {
			if ($2 != $4 || $3 != $5) found = 1
			seen = 1
			exit
		}
		END { exit(found ? 0 : 1) }
	' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null
}

sub_is_info_node_name(){
	local name="$1"
	case "${name}" in
	Expire:*|Expire：*|Traffic:*|Traffic：*|Sync:*|Sync：*|剩余流量:*|剩余流量：*|套餐到期:*|套餐到期：*|订阅到期:*|订阅到期：*|到期时间:*|到期时间：*|流量重置:*|流量重置：*|更新于:*|更新于：*|更新时间:*|更新时间：*)
		return 0
		;;
	esac
	return 1
}

sub_node_tool_plan_needs_runtime_cache_refresh(){
	[ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 0
	[ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 0
	awk -F '\t' '
		function is_info_name(name) {
			return name ~ /^(Expire:|Expire：|Traffic:|Traffic：|Sync:|Sync：|剩余流量:|剩余流量：|套餐到期:|套餐到期：|订阅到期:|订阅到期：|到期时间:|到期时间：|流量重置:|流量重置：|更新于:|更新于：|更新时间:|更新时间：)/
		}
		$1 == "add" || $1 == "remove" || $1 == "move" {
			if (!is_info_name($5)) { found = 1; exit }
			next
		}
		$1 == "update" {
			last_update_name = $5
			next
		}
		$1 == "field" {
			if (is_info_name(last_update_name) && ($3 == "name" || $3 == "group")) next
			found = 1
			exit
		}
		END { exit(found ? 0 : 1) }
	' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null
}

sub_should_run_reference_postwrite(){
	local mode=""
	mode="$(dbus get ss_basic_mode)"
	if [ "${mode}" = "7" ];then
		return 0
	fi
	if [ -z "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || [ ! -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ];then
		return 0
	fi
	sub_node_tool_plan_current_changed && return 0
	sub_node_tool_plan_failover_changed && return 0
	return 1
}

sub_should_refresh_runtime_caches(){
	[ "${SUB_FAST_APPEND_USED}" = "1" ] && return 0
	sub_node_tool_plan_needs_runtime_cache_refresh
}

sub_run_reference_postwrite_steps(){
	local input_file="$1"
	local step_start=""

	if [ "${SUB_FAST_APPEND_USED}" = "1" ];then
		echo_date "🧭本次为快速追加写入，跳过运行节点/分流引用改写。"
		return 0
	fi
	if ! sub_should_run_reference_postwrite;then
		echo_date "🧭运行节点和分流引用未受影响，跳过引用改写。"
		return 0
	fi

	echo_date "🧭开始同步运行节点/分流引用；分流规则较多时此步骤可能需要数秒..."
	step_start=$(sub_now_epoch)
	sub_reference_notice_reset
	sub_apply_shunt_reference_rewrite
	sub_collect_runtime_reference_notice_after_rewrite "${input_file}"
	sub_reference_notice_commit
	echo_date "🧭运行节点/分流引用同步完成，用时 $(sub_elapsed_text "${step_start}")。"
}

sub_run_cache_postwrite_steps(){
	if sub_should_refresh_runtime_caches;then
		sub_refresh_runtime_caches_async
	else
		echo_date "⚙️本次变更不影响运行缓存，跳过缓存刷新。"
	fi
}

sub_after_nodes_written(){
	local input_file="$1"
	sub_run_reference_postwrite_steps "${input_file}"
	sub_run_cache_postwrite_steps
}

sub_refresh_runtime_dns_after_airport_special_change(){
	[ "${SUB_AIRPORT_SPECIAL_CHANGED}" = "1" ] || return 0
	echo_date "⚙️机场专属节点DNS配置已更新，刷新节点域名解析运行态..."
	if [ "$(dbus get ss_basic_enable)" = "1" ];then
		sh /koolshare/ss/ssconfig.sh refresh_node_direct_dns >/dev/null 2>&1 || true
	else
		fss_refresh_node_direct_cache >/dev/null 2>&1 || true
	fi
}

sub_resolve_reference_from_plan(){
	local current_id="$1"
	local current_identity="$2"
	local line=""
	[ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	[ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] || return 1
	if [ -n "${current_identity}" ];then
		line=$(awk -F '\t' -v identity="${current_identity}" '$1 == "map" && $4 == identity {print $5 "\t" $6; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)
	fi
	if [ -z "${line}" ] && [ -n "${current_id}" ];then
		line=$(awk -F '\t' -v node_id="${current_id}" '$1 == "map" && $3 == node_id {print $5 "\t" $6; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)
	fi
	[ -n "${line}" ] || return 1
	printf '%s' "${line}"
	return 0
}

sub_resolve_reference_new_id(){
	local current_id="$1"
	local current_identity="$2"
	local mapped=""
	local mapped_identity=""
	local plan_result=""

	SUB_REFERENCE_RESOLVED_IDENTITY=""
	plan_result="$(sub_resolve_reference_from_plan "${current_id}" "${current_identity}" 2>/dev/null)" || plan_result=""
	if [ -n "${plan_result}" ];then
		mapped="$(printf '%s' "${plan_result}" | awk -F '\t' '{print $1}')"
		mapped_identity="$(printf '%s' "${plan_result}" | awk -F '\t' '{print $2}')"
		if [ -n "${mapped}" ];then
			SUB_REFERENCE_RESOLVED_IDENTITY="${mapped_identity}"
			printf '%s' "${mapped}"
			return 0
		fi
	fi
	if [ -n "${current_identity}" ];then
		mapped="$(fss_find_node_id_by_identity "${current_identity}" 2>/dev/null)"
		if [ -n "${mapped}" ];then
			SUB_REFERENCE_RESOLVED_IDENTITY="$(fss_get_node_identity_by_id "${mapped}" 2>/dev/null)"
			printf '%s' "${mapped}"
			return 0
		fi
	fi
	if [ -n "${current_id}" ] && fss_node_id_exists "${current_id}" 2>/dev/null;then
		SUB_REFERENCE_RESOLVED_IDENTITY="$(fss_get_node_identity_by_id "${current_id}" 2>/dev/null)"
		printf '%s' "${current_id}"
		return 0
	fi
	return 1
}

sub_apply_shunt_reference_rewrite(){
	local default_target=""
	local default_identity=""
	local mapped_target=""
	local mapped_identity=""
	local changed_default=0
	local changed_rules=0
	local synced_identities=0
	local unresolved=0
	local rules_b64=""
	local rules_json=""
	local line=""
	local new_line=""
	local target_id=""
	local target_identity=""
	local rule_id=""
	local remark=""
	local preset=""
	local label=""
	local sep="$(printf '\037')"
	local rules_file="${DIR}/shunt_apply_rules.$$"
	local updated_rules_file="${DIR}/shunt_apply_rules_new.$$"
	local new_json=""
	local rule_fields=""
	local target_id_b64=""
	local target_identity_b64=""
	local rule_id_b64=""
	local remark_b64=""
	local preset_b64=""
	local desired_target=""
	local desired_identity=""
	local target_changed="0"
	local identity_changed="0"

	default_target="$(dbus get ss_basic_shunt_default_node)"
	default_identity="$(dbus get ss_basic_shunt_default_node_identity)"
	case "${default_target}" in
	DIRECT|REJECT)
		if [ -n "${default_identity}" ];then
			dbus set ss_basic_shunt_default_node_identity=""
			changed_default=$((changed_default + 1))
		fi
		;;
	"")
		:
		;;
	*)
		mapped_target="$(sub_resolve_reference_new_id "${default_target}" "${default_identity}" 2>/dev/null)"
		if [ -n "${mapped_target}" ];then
			mapped_identity="${SUB_REFERENCE_RESOLVED_IDENTITY}"
			[ -n "${mapped_identity}" ] || mapped_identity="$(fss_get_node_identity_by_id "${mapped_target}" 2>/dev/null)"
			if [ "${mapped_target}" != "${default_target}" ];then
				dbus set ss_basic_shunt_default_node="${mapped_target}"
				changed_default=$((changed_default + 1))
			fi
			if [ -n "${mapped_identity}" ] && [ "${mapped_identity}" != "${default_identity}" ];then
				dbus set ss_basic_shunt_default_node_identity="${mapped_identity}"
				synced_identities=$((synced_identities + 1))
			fi
		elif [ -n "${default_target}${default_identity}" ];then
			sub_reference_notice_add \
				"shunt_default" \
				"分流兜底节点已失效" \
				"节点分流的兜底目标节点已无法恢复，请进入节点分流页面重新选择兜底节点。" \
				"${default_target}" \
				"" \
				"missing"
			unresolved=$((unresolved + 1))
		fi
		;;
	esac

	rules_b64="$(dbus get ss_basic_shunt_rules)"
	[ -n "${rules_b64}" ] || {
		[ "${changed_default}" -gt 0 -o "${synced_identities}" -gt 0 -o "${unresolved}" -gt 0 ] && echo_date "🧭分流引用已同步：兜底调整 ${changed_default} 项，规则调整 ${changed_rules} 项，补全 identity ${synced_identities} 项，未解析 ${unresolved} 项。"
		return 0
	}
	rules_json=$(printf '%s' "${rules_b64}" | base64 -d 2>/dev/null) || return 0
	printf '%s' "${rules_json}" | jq -c '.[]?' 2>/dev/null > "${rules_file}" || {
		rm -f "${rules_file}" "${updated_rules_file}"
		return 0
	}
	: > "${updated_rules_file}"
	while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		new_line="${line}"
		rule_fields="$(sub_parse_shunt_rule_fields "${line}")" || rule_fields=""
		IFS="${sep}" read -r target_id_b64 target_identity_b64 rule_id_b64 remark_b64 preset_b64 <<-EOF
		${rule_fields}
		EOF
		target_id=""
		target_identity=""
		rule_id=""
		remark=""
		preset=""
		[ -n "${target_id_b64}" ] && target_id="$(fss_b64_decode "${target_id_b64}")"
		[ -n "${target_identity_b64}" ] && target_identity="$(fss_b64_decode "${target_identity_b64}")"
		[ -n "${rule_id_b64}" ] && rule_id="$(fss_b64_decode "${rule_id_b64}")"
		[ -n "${remark_b64}" ] && remark="$(fss_b64_decode "${remark_b64}")"
		[ -n "${preset_b64}" ] && preset="$(fss_b64_decode "${preset_b64}")"
		label="${remark}"
		[ -n "${label}" ] || label="${preset}"
		[ -n "${label}" ] || label="${rule_id}"
		desired_target="${target_id}"
		desired_identity="${target_identity}"
		target_changed="0"
		identity_changed="0"
		case "${target_id}" in
		DIRECT|REJECT)
			if [ -n "${target_identity}" ];then
				desired_identity=""
				identity_changed="1"
			fi
			;;
		*)
			mapped_target="$(sub_resolve_reference_new_id "${target_id}" "${target_identity}" 2>/dev/null)"
			if [ -n "${mapped_target}" ];then
				mapped_identity="${SUB_REFERENCE_RESOLVED_IDENTITY}"
				[ -n "${mapped_identity}" ] || mapped_identity="$(fss_get_node_identity_by_id "${mapped_target}" 2>/dev/null)"
				if [ "${mapped_target}" != "${target_id}" ];then
					desired_target="${mapped_target}"
					target_changed="1"
				fi
				if [ -n "${mapped_identity}" ] && [ "${mapped_identity}" != "${target_identity}" ];then
					desired_identity="${mapped_identity}"
					identity_changed="1"
				fi
			elif [ -n "${target_id}${target_identity}" ];then
				echo_date "🧭分流规则保持原值：【${label}】未能解析新目标节点。"
				sub_reference_notice_add \
					"shunt_rule" \
					"分流规则目标节点已失效" \
					"节点分流规则【${label}】的目标节点已无法恢复，请进入节点分流页面重新选择。" \
					"${target_id}" \
					"" \
					"missing"
				unresolved=$((unresolved + 1))
			fi
			;;
		esac
		if [ "${target_changed}" = "1" -o "${identity_changed}" = "1" ];then
			new_line="$(printf '%s' "${new_line}" | jq -c --arg target "${desired_target}" --arg identity "${desired_identity}" '.target_node_id = $target | .target_node_identity = $identity' 2>/dev/null)"
			[ "${target_changed}" = "1" ] && changed_rules=$((changed_rules + 1))
			[ "${identity_changed}" = "1" ] && synced_identities=$((synced_identities + 1))
		fi
		printf '%s\n' "${new_line}" >> "${updated_rules_file}"
	done < "${rules_file}"
	new_json="$(jq -s -c '.' "${updated_rules_file}" 2>/dev/null)"
	if [ -n "${new_json}" ] && [ "${new_json}" != "${rules_json}" ];then
		dbus set ss_basic_shunt_rules="$(fss_b64_encode "${new_json}")"
	fi
	rm -f "${rules_file}" "${updated_rules_file}"
	[ "${changed_default}" -gt 0 -o "${changed_rules}" -gt 0 -o "${synced_identities}" -gt 0 -o "${unresolved}" -gt 0 ] && echo_date "🧭分流引用已同步：兜底调整 ${changed_default} 项，规则调整 ${changed_rules} 项，补全 identity ${synced_identities} 项，未解析 ${unresolved} 项。"
	return 0
}

sub_validate_jsonl_file(){
	local file="$1"
	[ -f "${file}" ] || return 1
	grep -q '[^[:space:]]' "${file}" 2>/dev/null || return 1
	jq -e -s 'length > 0 and all(.[]; type == "object")' "${file}" >/dev/null 2>&1 || {
		echo_date "⚠️检测到无效的节点JSON，文件整体校验失败！"
		return 1
	}
	return 0
}

sub_count_group_nodes(){
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		sub_prepare_schema2_export_jsonl >/dev/null 2>&1 || true
		sub_extract_groups_from_file "${SCHEMA2_EXPORT_JSONL}" | while IFS= read -r raw_group
		do
			local group_name
			group_name=$(normalize_group_name "${raw_group}" 2>/dev/null) || true
			[ -n "${group_name}" ] && echo "${group_name}"
		done | sed '/^$/d' | wc -l
	else
		dbus list ssconf_basic_group_ | sed '/^ssconf_basic_group_[0-9]\+=$/d' | wc -l
	fi
}

sub_count_unique_groups(){
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		sub_prepare_schema2_export_jsonl >/dev/null 2>&1 || true
		sub_extract_groups_from_file "${SCHEMA2_EXPORT_JSONL}" | while IFS= read -r raw_group
		do
			local group_name
			group_name=$(normalize_group_name "${raw_group}" 2>/dev/null) || true
			[ -n "${group_name}" ] && echo "${group_name}"
		done | sed '/^$/d' | sort -u | wc -l
	else
		dbus list ssconf_basic_group_ | cut -d "=" -f2 | sort -u | wc -l
	fi
}

sub_apply_existing_ids_by_identity(){
	local input_file="$1"
	local output_file="$2"
	local source_map_file="${SCHEMA2_BEFORE_EXPORT_JSONL}"

	[ -f "${input_file}" ] || return 1
	[ -n "${output_file}" ] || return 1
	if [ "${SUB_STORAGE_SCHEMA}" != "2" ];then
		cp -f "${input_file}" "${output_file}"
		return 0
	fi
	if [ ! -s "${source_map_file}" ];then
		sub_prepare_schema2_export_jsonl >/dev/null 2>&1 || true
		source_map_file="${SCHEMA2_EXPORT_JSONL}"
	fi
	if [ ! -s "${source_map_file}" ];then
		cp -f "${input_file}" "${output_file}"
		return 0
	fi
	run jq -n -c \
		--slurpfile src "${source_map_file}" '
		(reduce $src[] as $item ({};
			($item._identity // "") as $identity
			| if $identity != "" then
				.[$identity] = {
					id: (($item._id // "") | tostring),
					created: (($item._created_at // "") | tostring)
				}
			else
				.
			end
		)) as $identity_map
		| foreach inputs as $node (null;
			($node._identity // "") as $identity
			| ($identity_map[$identity] // null) as $mapped
			| if $mapped != null and (($mapped.id // "") != "") then
				($node + {
					"_id": ($mapped.id | tostring)
				} + (
					if (($mapped.created // "") != "") then
						{"_created_at": (((($mapped.created // "") | tonumber?) // ($node._created_at // empty)))}
					else
						{}
					end
				))
			else
				$node
			end
		)
	' "${input_file}" > "${output_file}" 2>/dev/null || {
		cp -f "${input_file}" "${output_file}"
		return 0
	}
	return 0
}

sub_write_nodes_schema2(){
	local input_file="$1"
	local node_tool=""
	local normalized_tmp=""
	local plan_tmp=""
	local old_order_csv="" next_id max_id reserved_max imported_order="" mapped_file meta_file now_ts identity_file reuse_file
	local old_export_file="${SCHEMA2_BEFORE_EXPORT_JSONL}"
	local new_ids_file="${input_file}.new_ids"
	local removed_ids_file="${input_file}.removed_ids"
	local node_id stored_b64 export_b64 export_json existing_blob
	local touched_any=0
	local prepared_reuse_temp=0

	[ -f "${input_file}" ] || return 1
	SUB_NODE_TOOL_PLAN_FILE_CURRENT=""
	node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
	if [ -n "${node_tool}" ];then
		plan_tmp="${input_file}.plan.$$"
		normalized_tmp="${input_file}.normalized.$$"
		if "${node_tool}" json2node --input "${input_file}" --mode replace --reuse-ids --normalized-output "${normalized_tmp}" --plan-output "${plan_tmp}" --plan-format shell >/dev/null 2>&1;then
			if [ -f "${normalized_tmp}" ];then
				mv -f "${normalized_tmp}" "${input_file}"
			else
				rm -f "${normalized_tmp}" >/dev/null 2>&1
			fi
			[ -f "${plan_tmp}" ] && SUB_NODE_TOOL_PLAN_FILE_CURRENT="${plan_tmp}"
			fss_mark_native_schema2_storage >/dev/null 2>&1 || true
			fss_clear_webtest_runtime_results
			return 0
		fi
		rm -f "${plan_tmp}" "${normalized_tmp}" >/dev/null 2>&1
	fi
	mapped_file="${input_file}.mapped"
	meta_file="${input_file}.meta"
	identity_file="${input_file}.identity"
	reuse_file="${input_file}.reuse"
	if [ ! -f "${old_export_file}" ];then
		sub_prepare_schema2_export_jsonl >/dev/null 2>&1 || true
		[ -s "${SCHEMA2_EXPORT_JSONL}" ] && cp -f "${SCHEMA2_EXPORT_JSONL}" "${old_export_file}"
	fi
	[ -f "${old_export_file}" ] || : > "${old_export_file}"
	: > "${mapped_file}"
	if sub_file_has_complete_numeric_ids "${input_file}";then
		reuse_file="${input_file}"
	else
		sub_prepare_identity_view_file "${input_file}" "${identity_file}" "" "" "" "" || {
			rm -f "${mapped_file}" "${identity_file}"
			return 1
		}
		sub_apply_existing_ids_by_identity "${identity_file}" "${reuse_file}" || {
			rm -f "${mapped_file}" "${identity_file}" "${reuse_file}"
			return 1
		}
		prepared_reuse_temp=1
	fi
	old_order_csv=$(dbus get fss_node_order)
	next_id=$(dbus get fss_node_next_id)
	[ -n "${next_id}" ] || next_id=1
	max_id=$(printf '%s' "${old_order_csv}" | tr ',' '\n' | sed '/^$/d' | sort -n | tail -n1)
	[ -n "${max_id}" ] || max_id=0
	reserved_max=$(jq -r '._id // empty' "${input_file}" 2>/dev/null | sed '/^$/d' | sort -n | tail -n1)
	if [ -n "${reserved_max}" ] && [ "${reserved_max}" -gt "${max_id}" ] 2>/dev/null;then
		max_id="${reserved_max}"
	fi
	if [ "${next_id}" -le "${max_id}" ] 2>/dev/null;then
		next_id=$((max_id + 1))
	fi
	now_ts=$(fss_now_ts_ms)
		jq -nr -r -c --argjson next "${next_id}" --argjson ts "${now_ts}" --slurpfile old "${old_export_file}" '
			def legacy_b64_mode:
				((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
			def decode_b64_field($field):
				if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
					.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
				else
					.
				end;
			def clean:
				with_entries(select(.value != "" and .value != null))
				| decode_b64_field("password")
			| decode_b64_field("naive_pass")
			| decode_b64_field("v2ray_json")
			| decode_b64_field("xray_json")
			| decode_b64_field("tuic_json")
			| del(._schema, ._rev, ._source, ._updated_at, ._migrated_from, .server_ip, .latency, .ping)
			| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end;
		(reduce $old[] as $item ({};
			(($item._id // "") | tostring) as $id
			| if $id != "" then
				.[$id] = (($item | clean) | tojson | @base64)
			else
				.
			end
		)) as $old_export_map
		| reduce inputs as $node (
			{next: $next, rows: []};
			($node | clean) as $clean
			| ($clean._id // "" | tostring) as $raw_id
			| (if ($raw_id | test("^[0-9]+$")) then ($raw_id | tonumber) else .next end) as $id
			| ($clean | tojson | @base64) as $export_b64
			| ($old_export_map[($id | tostring)] // "") as $old_export_b64
			| .rows += [[
				($id | tostring),
				(if $old_export_b64 == $export_b64 then
					""
				else
					(($clean + {
						"_schema": 2,
						"_id": ($id | tostring),
						"_rev": 1,
						"_b64_mode": "raw",
						"_source": "subscribe",
						"_updated_at": $ts
					} + {
						"_created_at": (((($clean._created_at // $ts) | tonumber?) // $ts) | if . < 1000000000000 then (. * 1000) else . end)
					}) | tojson | @base64)
				end),
				$export_b64
			]]
			| .next = (if ($raw_id | test("^[0-9]+$")) then .next else (.next + 1) end)
		)
		| .rows[]
		| @tsv
	' "${reuse_file}" > "${meta_file}" 2>/dev/null || {
		rm -f "${mapped_file}" "${meta_file}" "${identity_file}" "${reuse_file}"
		return 1
	}
	: > "${new_ids_file}"

	while IFS='	' read -r node_id stored_b64 export_b64
	do
		[ -n "${node_id}" ] || continue
		echo "${node_id}" >> "${new_ids_file}"
		if [ -n "${stored_b64}" ];then
			existing_blob="$(dbus get fss_node_${node_id})"
			if [ -n "${existing_blob}" ] && [ "${existing_blob}" = "${stored_b64}" ];then
				:
			else
				fss_clear_webtest_cache_node "${node_id}"
				dbus set fss_node_${node_id}="${stored_b64}"
				touched_any=1
			fi
		fi
		export_json=$(fss_b64_decode "${export_b64}")
		printf '%s\n' "${export_json}" >> "${mapped_file}"
		imported_order="${imported_order}${imported_order:+,}${node_id}"
		if [ "${node_id}" -gt "${max_id}" ] 2>/dev/null;then
			max_id="${node_id}"
		fi
	done < "${meta_file}"
	printf '%s' "${old_order_csv}" | tr ',' '\n' | sed '/^$/d' | while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		grep -Fxq "${node_id}" "${new_ids_file}" 2>/dev/null && continue
		echo "${node_id}"
	done > "${removed_ids_file}"
	while IFS= read -r node_id
	do
		[ -n "${node_id}" ] || continue
		fss_clear_webtest_cache_node "${node_id}"
		dbus remove fss_node_${node_id}
		touched_any=1
	done < "${removed_ids_file}"
	rm -f "${meta_file}" "${identity_file}" "${new_ids_file}" "${removed_ids_file}"
	[ "${prepared_reuse_temp}" = "1" ] && rm -f "${reuse_file}"

	if [ -z "${imported_order}" ];then
		rm -f "${mapped_file}"
		return 1
	fi
	dbus set fss_node_order="${imported_order}"
	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2 >/dev/null 2>&1 || true
	dbus set fss_node_next_id="$((max_id + 1))"
	fss_mark_native_schema2_storage >/dev/null 2>&1 || true
	[ "${touched_any}" = "1" ] && fss_clear_webtest_runtime_results
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	mv "${mapped_file}" "${input_file}"
	return 0
}

sub_can_fast_append_schema2(){
	local input_file="$1"
	local old_count=0
	local existing_count=0
	local total_count=0
	local new_count=0
	local non_user_count=0

	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ -f "${input_file}" ] || return 1
	old_count=$(sub_list_node_ids | sed '/^$/d' | wc -l)
	existing_count=$(jq -r 'select(((._id // "") | tostring | test("^[0-9]+$")))|1' "${input_file}" 2>/dev/null | wc -l | tr -d ' ')
	total_count=$(wc -l < "${input_file}" 2>/dev/null | tr -d ' ')
	[ -n "${existing_count}" ] || existing_count=0
	[ -n "${total_count}" ] || total_count=0
	new_count=$((total_count - existing_count))
	[ "${new_count}" -gt 0 ] || return 1
	[ "${existing_count}" -eq "${old_count}" ] || return 1
	if [ "${LOCAL_SPLIT_META_VALID}" = "1" ] && [ -s "${LOCAL_SPLIT_META}" ];then
		non_user_count=$(awk -F '\t' '$3 != "" && $3 != "null" && $3 != "user" {count++} END {print count + 0}' "${LOCAL_SPLIT_META}" 2>/dev/null)
	else
		non_user_count=1
	fi
	[ "${non_user_count}" -eq 0 ]
}

sub_append_nodes_schema2(){
	local input_file="$1"
	local reuse_ids="${2:-1}"
	local node_tool=""
	local normalized_tmp=""
	local plan_tmp=""
	local assigned_file="${input_file}.append"
	local meta_file="${input_file}.append.meta"
	local new_ids_file="${input_file}.append.ids"
	local old_order_csv="" next_id max_id imported_order=""
	local now_ts node_id stored_b64 touched_any=0

	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ -f "${input_file}" ] || return 1
	SUB_NODE_TOOL_PLAN_FILE_CURRENT=""
	node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
	if [ -n "${node_tool}" ];then
		normalized_tmp="${input_file}.append_normalized.$$"
		plan_tmp="${input_file}.append.plan.$$"
		if [ "${reuse_ids}" = "1" ];then
			if "${node_tool}" json2node --input "${input_file}" --mode append --reuse-ids --normalized-output "${normalized_tmp}" --plan-output "${plan_tmp}" --plan-format shell >/dev/null 2>&1;then
				if [ -f "${normalized_tmp}" ];then
					mv -f "${normalized_tmp}" "${input_file}"
				else
					rm -f "${normalized_tmp}" >/dev/null 2>&1
				fi
				[ -f "${plan_tmp}" ] && SUB_NODE_TOOL_PLAN_FILE_CURRENT="${plan_tmp}"
				fss_mark_native_schema2_storage >/dev/null 2>&1 || true
				fss_clear_webtest_runtime_results
				return 0
			fi
		else
			if "${node_tool}" json2node --input "${input_file}" --mode append --normalized-output "${normalized_tmp}" --plan-output "${plan_tmp}" --plan-format shell >/dev/null 2>&1;then
				if [ -f "${normalized_tmp}" ];then
					mv -f "${normalized_tmp}" "${input_file}"
				else
					rm -f "${normalized_tmp}" >/dev/null 2>&1
				fi
				[ -f "${plan_tmp}" ] && SUB_NODE_TOOL_PLAN_FILE_CURRENT="${plan_tmp}"
				fss_mark_native_schema2_storage >/dev/null 2>&1 || true
				fss_clear_webtest_runtime_results
				return 0
			fi
		fi
		rm -f "${normalized_tmp}" "${plan_tmp}" >/dev/null 2>&1
	fi

	old_order_csv=$(dbus get fss_node_order)
	next_id=$(dbus get fss_node_next_id)
	[ -n "${next_id}" ] || next_id=1
	max_id=$(printf '%s' "${old_order_csv}" | tr ',' '\n' | sed '/^$/d' | sort -n | tail -n1)
	[ -n "${max_id}" ] || max_id=0
	if [ "${next_id}" -le "${max_id}" ] 2>/dev/null;then
		next_id=$((max_id + 1))
	fi
	now_ts=$(fss_now_ts_ms)

	jq -nr -r -c --argjson next "${next_id}" --argjson ts "${now_ts}" '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
		def legacy_b64_mode:
			((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
		def decode_b64_field($field):
			if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
				.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
			else
				.
			end;
		def clean:
			with_entries(select(.value != "" and .value != null))
			| decode_b64_field("password")
			| decode_b64_field("naive_pass")
			| decode_b64_field("v2ray_json")
			| decode_b64_field("xray_json")
			| decode_b64_field("tuic_json")
			| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
			| if has("xray_json") then .xray_json |= normalize_json_config else . end
			| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
			| del(
				._schema,
				._rev,
				._updated_at,
				._migrated_from,
				._b64_mode,
				.server_ip,
				.latency,
				.ping
			)
			| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end;
		(reduce inputs as $node (
			{next: $next, out: []};
			($node | clean) as $clean
			| (($clean._id // "") | tostring) as $raw_id
			| if ($raw_id | test("^[0-9]+$")) then
				.out += [($clean | tojson)]
			else
				($clean + {
					"_id": (.next | tostring),
					"_created_at": (((($clean._created_at // $ts) | tonumber?) // $ts) | if . < 1000000000000 then (. * 1000) else . end)
				}) as $assigned
				| .out += [($assigned | tojson)]
				| .next += 1
			end
		)).out[]
	' "${input_file}" > "${assigned_file}" 2>/dev/null || {
		rm -f "${assigned_file}" "${meta_file}" "${new_ids_file}"
		return 1
	}

	jq -nr -r -c --argjson max "${max_id}" --argjson ts "${now_ts}" '
		def normalize_json_config:
			. as $raw
			| if (($raw | type) != "string") or $raw == "" then
				$raw
			else
				(
					try ($raw | fromjson | tojson)
					catch (
						try ($raw | gsub("\\\\\""; "\"") | fromjson | tojson)
						catch $raw
					)
				)
			end;
		def legacy_b64_mode:
			((._b64_mode // "") != "raw") and (((._source // "") == "") or ((._source // "") == "subscribe"));
		def decode_b64_field($field):
			if legacy_b64_mode and has($field) and (.[$field] // "") != "" then
				.[$field] as $raw | .[$field] |= (try @base64d catch $raw)
			else
				.
			end;
		def clean:
			with_entries(select(.value != "" and .value != null))
			| decode_b64_field("password")
			| decode_b64_field("naive_pass")
			| decode_b64_field("v2ray_json")
			| decode_b64_field("xray_json")
			| decode_b64_field("tuic_json")
			| if has("v2ray_json") then .v2ray_json |= normalize_json_config else . end
			| if has("xray_json") then .xray_json |= normalize_json_config else . end
			| if has("tuic_json") then .tuic_json |= normalize_json_config else . end
			| del(
				._schema,
				._rev,
				._updated_at,
				._migrated_from,
				._b64_mode,
				.server_ip,
				.latency,
				.ping
			)
			| if ((.type // "") == "4" and ((.xray_prot // "") == "")) then .xray_prot = "vless" else . end;
		foreach inputs as $node (null;
			($node | clean) as $clean
			| (($clean._id // "") | tostring) as $id
			| select(($id | test("^[0-9]+$")) and (($id | tonumber) > $max))
			| [
				$id,
				(($clean + {
					"_schema": 2,
					"_id": $id,
					"_rev": 1,
					"_b64_mode": "raw",
					"_source": (((($clean._source // "") | tostring)) | if . == "" then "subscribe" else . end),
					"_updated_at": $ts
				} + {
					"_created_at": (((($clean._created_at // $ts) | tonumber?) // $ts) | if . < 1000000000000 then (. * 1000) else . end)
				}) | tojson | @base64)
			] | @tsv
		)
	' "${assigned_file}" > "${meta_file}" 2>/dev/null || {
		rm -f "${assigned_file}" "${meta_file}" "${new_ids_file}"
		return 1
	}

	: > "${new_ids_file}"
	while IFS='	' read -r node_id stored_b64
	do
		[ -n "${node_id}" ] || continue
		dbus set fss_node_${node_id}="${stored_b64}"
		echo "${node_id}" >> "${new_ids_file}"
		touched_any=1
	done < "${meta_file}"

	imported_order=$(printf '%s' "${old_order_csv}")
	if [ -s "${new_ids_file}" ];then
		while IFS= read -r node_id
		do
			[ -n "${node_id}" ] || continue
			imported_order="${imported_order}${imported_order:+,}${node_id}"
			if [ "${node_id}" -gt "${max_id}" ] 2>/dev/null;then
				max_id="${node_id}"
			fi
		done < "${new_ids_file}"
	fi

	[ -n "${imported_order}" ] && dbus set fss_node_order="${imported_order}" || dbus remove fss_node_order
	dbus set fss_data_schema=2
	fss_set_storage_schema_cache 2 >/dev/null 2>&1 || true
	dbus set fss_node_next_id="$((max_id + 1))"
	fss_mark_native_schema2_storage >/dev/null 2>&1 || true
	[ "${touched_any}" = "1" ] && fss_clear_webtest_runtime_results
	fss_touch_node_catalog_ts >/dev/null 2>&1
	fss_touch_node_config_ts >/dev/null 2>&1
	mv -f "${assigned_file}" "${input_file}"
	rm -f "${meta_file}" "${new_ids_file}"
	return 0
}

sub_sync_single_source_schema2(){
	local source_tag="$1"
	local input_file="$2"
	local node_tool=""
	local normalized_tmp=""
	local plan_tmp=""

	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ -n "${source_tag}" ] || return 1
	[ -f "${input_file}" ] || return 1
	node_tool="$(pick_node_tool_command "sync-source" 2>/dev/null)" || return 1
	SUB_NODE_TOOL_PLAN_FILE_CURRENT=""
	normalized_tmp="${input_file}.sync.normalized.$$"
	plan_tmp="${input_file}.sync.plan.$$"
	if "${node_tool}" sync-source --source-tag "${source_tag}" --input "${input_file}" --reuse-ids --normalized-output "${normalized_tmp}" --plan-output "${plan_tmp}" --plan-format shell >/dev/null 2>&1;then
		if [ -f "${normalized_tmp}" ];then
			mv -f "${normalized_tmp}" "${input_file}"
		else
			rm -f "${normalized_tmp}" >/dev/null 2>&1
		fi
		[ -f "${plan_tmp}" ] && SUB_NODE_TOOL_PLAN_FILE_CURRENT="${plan_tmp}"
		fss_mark_native_schema2_storage >/dev/null 2>&1 || true
		sub_refresh_node_state
		return 0
	fi
	rm -f "${normalized_tmp}" "${plan_tmp}" >/dev/null 2>&1
	return 1
}

sub_try_sync_single_source_fast_path(){
	local source_tag=""
	local input_file=""
	local source_label=""

	[ "${SUB_STORAGE_SCHEMA}" = "2" ] || return 1
	[ ! -s "${SUB_REMOVED_SOURCE_TAGS_FILE}" ] || return 1
	source_tag="$(sub_get_single_changed_source_tag 2>/dev/null)" || return 1
	[ -n "${source_tag}" ] || return 1
	[ "${source_tag}" != "user" ] || return 1
	input_file="$(sub_find_local_source_file "${source_tag}" 2>/dev/null)" || return 1
	[ -f "${input_file}" ] || return 1
	source_label="$(get_group_label_from_file "${input_file}" "$(get_sub_group_fallback_by_hash "${source_tag}")")"

	SUB_FAST_APPEND_USED=0
	echo_date "🧭检测到仅【${source_label:-${source_tag}}】来源发生变化，尝试单来源快速同步..."
	sub_capture_active_nodes
	echo_date "⌛节点写入前准备..."
	echo_date "😀准备完成！"
	echo_date "ℹ️开始写入节点..."
	echo_date "🧭正在执行来源级同步：生成变更计划并更新该来源节点..."
	if ! sub_sync_single_source_schema2 "${source_tag}" "${input_file}";then
		echo_date "⚠️来源级快速同步失败，回退全量写入路径。"
		return 1
	fi
	echo_date "😀节点信息写入成功！"
	sub_schedule_background_sync
	sub_after_nodes_written "${input_file}"
	find $DIR -name "local_*.txt" | sort -n | xargs cat >$DIR/ss_nodes_new.txt
	cp -f "$DIR/ss_nodes_new.txt" "${LOCAL_NODES_BAK}"
	echo_date "🧹一点点清理工作..."
	echo_date "🎉所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
	return 0
}

sub_restore_active_nodes_after_rewrite(){
	local input_file="$1"
	local restore_current="" restore_failover="" first_id=""

	if [ -n "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ] && [ -f "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" ];then
		restore_current="$(awk -F '\t' '$1 == "current" {print $4; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)"
		restore_failover="$(awk -F '\t' '$1 == "failover" {print $4; exit}' "${SUB_NODE_TOOL_PLAN_FILE_CURRENT}" 2>/dev/null)"
		[ -z "${restore_current}" ] && restore_current="$(sub_list_node_ids | sed -n '1p')"
		fss_set_current_node_id "${restore_current}"
		fss_set_failover_node_id "${restore_failover}"
		return 0
	fi

	first_id=$(sub_list_node_ids | sed -n '1p')

	if sub_node_exists_in_order "${CURR_NODE}";then
		restore_current="${CURR_NODE}"
	else
		restore_current=$(sub_find_node_id_by_identity_in_file "${input_file}" "${CURR_NODE_IDENTITY}")
	fi
	if [ -z "${restore_current}" ];then
		restore_current=$(sub_find_node_id_in_file "${input_file}" "${CURR_NODE_NAME}" "${CURR_NODE_TYPE}" "${CURR_NODE_SERVER}" "${CURR_NODE_PORT}")
	fi
	[ -z "${restore_current}" ] && restore_current="${first_id}"

	if sub_node_exists_in_order "${FAILOVER_NODE}";then
		restore_failover="${FAILOVER_NODE}"
	else
		restore_failover=$(sub_find_node_id_by_identity_in_file "${input_file}" "${FAILOVER_NODE_IDENTITY}")
	fi
	if [ -z "${restore_failover}" ];then
		restore_failover=$(sub_find_node_id_in_file "${input_file}" "${FAILOVER_NODE_NAME}" "${FAILOVER_NODE_TYPE}" "${FAILOVER_NODE_SERVER}" "${FAILOVER_NODE_PORT}")
	fi

	fss_set_current_node_id "${restore_current}"
	fss_set_failover_node_id "${restore_failover}"
}

sub_refresh_node_state

# 订阅流程说明：
# 1. 导出本地节点并按来源拆分为文件；
# 2. 下载并解析每个订阅来源；
# 3. 对比在线节点与本地节点差异；
# 4. 生成写入文件并按需更新 dbus。

set_lock(){
	exec 233>"${LOCK_FILE}"
	if [ "${FSS_SUBSCRIBE_LOCK_WAIT}" = "1" ]; then
		if ! flock -n 233; then
			echo_date "检测到订阅脚本已经在运行，等待当前任务完成..."
			flock 233
			echo_date "订阅锁已释放，继续执行当前订阅任务。"
		fi
		return 0
	fi
	flock -n 233 || {
		local PID1=$$
		local PID2=$(ps|grep -w "ss_node_subscribe.sh"|grep -vw "grep"|grep -vw ${PID1})
		if [ -n "${PID2}" ];then
			echo_date "订阅脚本已经在运行，请稍候再试！"
			exit 1			
		else
			rm -rf ${LOCK_FILE}
		fi
	}
}

unset_lock(){
	flock -u 233
	rm -rf "${LOCK_FILE}"
}

count_start(){
	# opkg install coreutils-date
	_start=$(/opt/bin/date +%s.%6N)
	_start0=${_start}
	counter=0
	echo_date ------------------
	echo_date - 0.000000
}

count_time(){
	# opkg install coreutils-date
	_end=$(/opt/bin/date +%s.%6N)
	runtime=$(awk "BEGIN { x = ${_end}; y = ${_start}; print (x - y) }")
	let counter+=1
	echo_date + $counter $runtime
	_start=${_end}
}

count_total(){
	# opkg install coreutils-date
	_end=$(/opt/bin/date +%s.%6N)
	runtime=$(awk "BEGIN { x = ${_end}; y = ${_start0}; print (x - y) }")
	let counter+=1
	echo_date - $runtime
	echo_date ------------------
}

run(){
	env -i PATH=${PATH} "$@"
}

__timeout_init() {
	# Determine best available timeout implementation:
	# 1) system timeout (GNU/coreutils or BusyBox applet)
	# 2) busybox timeout applet (no symlink)
	# 3) shell fallback (sleep + kill + wait)
	__TIMEOUT_CMD=""
	__TIMEOUT_STYLE=""

	if command -v timeout >/dev/null 2>&1; then
		__TIMEOUT_CMD="timeout"
	elif command -v busybox >/dev/null 2>&1; then
		# Some firmwares ship timeout applet without /bin/timeout symlink
		if busybox timeout --help >/dev/null 2>&1; then
			__TIMEOUT_CMD="busybox timeout"
		fi
	fi

	if [ -n "${__TIMEOUT_CMD}" ]; then
		# Prefer GNU/coreutils style: timeout DURATION CMD...
		# BusyBox (newer) is compatible; older BusyBox uses: timeout -t SECONDS -s SIG CMD...
		if env -i PATH=${PATH} ${__TIMEOUT_CMD} 1 sh -c ":" >/dev/null 2>&1; then
			__TIMEOUT_STYLE="gnu"
		elif env -i PATH=${PATH} ${__TIMEOUT_CMD} -t 1 -s KILL sh -c ":" >/dev/null 2>&1; then
			__TIMEOUT_STYLE="bb"
		else
			__TIMEOUT_CMD=""
			__TIMEOUT_STYLE=""
		fi
	fi
}

__timeout_run() {
	# Usage: __timeout_run <seconds> <cmd...>
	# Returns 124 on timeout (GNU timeout convention).
	local _t="$1"
	shift

	[ -z "${1}" ] && return 127

	if [ -z "${__TIMEOUT_STYLE}" -a -z "${__TIMEOUT_CMD}" ]; then
		__timeout_init
	fi

	if [ -n "${__TIMEOUT_CMD}" -a "${__TIMEOUT_STYLE}" = "gnu" ]; then
		env -i PATH=${PATH} ${__TIMEOUT_CMD} "${_t}" "$@"
		return $?
	elif [ -n "${__TIMEOUT_CMD}" -a "${__TIMEOUT_STYLE}" = "bb" ]; then
		env -i PATH=${PATH} ${__TIMEOUT_CMD} -t "${_t}" -s KILL "$@" 2>/dev/null
		return $?
	fi

	# Shell fallback: run command in background, kill it if still running after _t seconds.
	# Try to isolate process group via setsid when available.
	local _cmd_pid _timer_pid _rc _timer_rc _kill_target
	if command -v setsid >/dev/null 2>&1; then
		env -i PATH=${PATH} setsid "$@" &
		_cmd_pid=$!
		_kill_target="-${_cmd_pid}"
	else
		env -i PATH=${PATH} "$@" &
		_cmd_pid=$!
		_kill_target="${_cmd_pid}"
	fi

	(
		sleep "${_t}"
		if kill -0 "${_cmd_pid}" >/dev/null 2>&1; then
			kill -TERM ${_kill_target} >/dev/null 2>&1
			sleep 1
			kill -KILL ${_kill_target} >/dev/null 2>&1
			exit 124
		fi
		exit 0
	) &
	_timer_pid=$!

	wait "${_cmd_pid}"
	_rc=$?

	# Stop timer early if command finished before timeout.
	if kill -0 "${_timer_pid}" >/dev/null 2>&1; then
		kill "${_timer_pid}" >/dev/null 2>&1
	fi
	wait "${_timer_pid}" >/dev/null 2>&1
	_timer_rc=$?

	[ "${_timer_rc}" = "124" ] && return 124
	return "${_rc}"
}

run5(){
	__timeout_run 5 "$@"
}

run2(){
	__timeout_run 2 "$@"
}

json_init(){
	#true >/tmp/node_data.txt
	NODE_DATA="{"
}

json_add_string(){
	if [ -n "$2" ];then
		NODE_DATA="${NODE_DATA}\"$1\":\"$2\","
	fi
}

json_write_object(){
	local output_file="$1"
	local object_json=""
	local source_type="manual"
	local airport_identity="local"
	local source_scope="local"
	local source_url_hash=""
	local profile_id=""
	object_json=$(echo $NODE_DATA | sed '$ s/,$/}/g')
	case "${output_file}" in
	*/online_*|*/local_*)
		source_type="subscribe"
		airport_identity="${SUB_AIRPORT_IDENTITY}"
		source_scope="${SUB_SOURCE_SCOPE}"
		source_url_hash="${SUB_SOURCE_URL_HASH}"
		profile_id="${SUB_ACTIVE_PROFILE_ID}"
		;;
	esac
	if type fss_enrich_node_identity_json >/dev/null 2>&1;then
		object_json=$(fss_enrich_node_identity_json "${object_json}" "${airport_identity}" "${source_scope}" "${source_url_hash}" "${source_type}" "${profile_id}") || return 1
	fi
	printf '%s\n' "${object_json}" >> "${output_file}"
}

dec64(){
	# echo -n "${link}" | sed 's/$/====/' | grep -o "...." | sed '${/====/d}' | tr -d '\n' | base64 -d
	echo -n "${1}===" | sed 's/-/+/g;s/_/\//g' | base64 -d 2>/dev/null
	return $?
}

decode_urllink(){
	# legacy
	read link
	local flag=$1
	local len=${#link}
	local mod4=$(($len%4))
	local var="===="
	#[ "${mod4}" -gt "0" ] && local link=${link}${var:${mod4}}
	local link=${link}${var:${mod4}}
	local decode_info=$(echo -n "${link}" | sed 's/-/+/g;s/_/\//g' | base64 -d 2>/dev/null)
	# 如果解析出乱码，返回空值，避免skipd中写入乱码value导致错误！
	echo -n "${decode_info}" | isutf8 -q
	if [ "$?" != "0" ];then
		echo ""
		return 1
	fi
	# 如果解析出多行结果，返回空值，避免skipd中写入多行value导致错误！
	if [ -z "${flag}" ];then
		local is_multi=$(echo "${decode_info}" | wc -l)
		if [ "${is_multi}" -gt "1" ];then
			echo ""
			return 2
		fi
	fi
	# 返回解析结果
	echo -n "${decode_info}"
	return 0
}

json2skipd(){
	local file_name=$1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		if [ "${SUB_FAST_APPEND}" = "1" ];then
			sub_append_nodes_schema2 "${DIR}/${file_name}.txt" "${SUB_FAST_APPEND_REUSE}" || {
				SUB_FAST_APPEND=0
				SUB_FAST_APPEND_REUSE=1
				return 1
			}
			SUB_FAST_APPEND_USED=1
			SUB_FAST_APPEND=0
			SUB_FAST_APPEND_REUSE=1
			if [ -z "$(fss_get_current_node_id)" ];then
				local first_id=$(sub_list_node_ids | sed -n '1p')
				[ -n "${first_id}" ] && fss_set_current_node_id "${first_id}"
			fi
			echo_date "😀节点信息写入成功！"
			sub_schedule_background_sync
			sub_refresh_node_state
			return 0
		fi
		sub_write_nodes_schema2 "${DIR}/${file_name}.txt" || return 1
		if [ "${SUB_REWRITE_ALL}" = "1" ];then
			sub_restore_active_nodes_after_rewrite "${DIR}/${file_name}.txt"
			SUB_REWRITE_ALL=0
		elif [ -z "$(fss_get_current_node_id)" ];then
			local first_id=$(sub_list_node_ids | sed -n '1p')
			[ -n "${first_id}" ] && fss_set_current_node_id "${first_id}"
		fi
		fss_clear_webtest_runtime_results
		echo_date "😀节点信息写入成功！"
		sub_schedule_background_sync
		sub_refresh_node_state
		return 0
	fi
	cat > $DIR/${file_name}.sh <<-EOF
		#!/bin/sh
		source /koolshare/scripts/base.sh
		#------------------------
	EOF
	NODE_INDEX=$(dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -rn | sed -n '1p')
	[ -z "${NODE_INDEX}" ] && NODE_INDEX="0"
	local count=$(($NODE_INDEX + 1))
	while read nodes; do
		echo ${nodes} | sed 's/\",\"/\"\n\"/g;s/^{//;s/}$//' | sed 's/^\"/dbus set ssconf_basic_/g' | sed "s/\":/_${count}=/g" >>$DIR/${file_name}.sh
		let count+=1
	done < $DIR/${file_name}.txt
	#echo dbus save ssconf >>$DIR/${file_name}.sh
	chmod +x $DIR/${file_name}.sh
	sh $DIR/${file_name}.sh
	echo_date "😀节点信息写入成功！"
	sub_schedule_background_sync
}

normalize_group_name(){
	local raw_group="$1"
	[ -z "${raw_group}" ] && return 1
	[ "${raw_group}" == "null" ] && return 1
	local real_group=$(echo "${raw_group}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/_[^_]\+$//')
	case "${real_group}" in
	""|"null"|"_")
		return 1
		;;
	*)
		echo -n "${real_group}"
		return 0
		;;
	esac
}

get_group_hash_value(){
	local raw_group="$1"
	local real_group=$(normalize_group_name "${raw_group}")
	[ -z "${real_group}" ] && return 1
	case "${raw_group}" in
	*_*)
		echo -n "${raw_group##*_}"
		return 0
		;;
	*)
		echo -n "${raw_group}"
		return 0
		;;
	esac
}

sanitize_invalid_local_groups(){
	local key value node changed=0 invalid_file
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		# schema2 节点的 group/identity 已由新写入链路保证；订阅阶段不再为兼容旧数据做全量巡检。
		return 0
	fi
	while IFS='=' read -r key value
	do
		[ -z "${key}" ] && continue
		if ! normalize_group_name "${value}" >/dev/null 2>&1;then
			node="${key##*_}"
			echo_date "🧹检测到第${node}个节点的group值无效，已移除该group标记。"
			dbus remove "${key}"
		fi
	done <<-EOF
$(dbus list ssconf_basic_group_ 2>/dev/null)
EOF
}

get_sub_group_fallback_by_hash(){
	local sub_hash="$1"
	[ -z "${sub_hash}" ] && return 1
	local online_sub_urls=$(sub_get_online_urls)
	local online_sub_url sublink_url source_tag legacy_tag
	for online_sub_url in ${online_sub_urls}
	do
		sublink_url=$(echo "${online_sub_url}" | sed 's/%20/ /g')
		source_tag=$(sub_get_source_tag_from_url "${sublink_url}")
		legacy_tag=$(sub_get_legacy_tag_from_url "${sublink_url}")
		if [ "${source_tag}" = "${sub_hash}" ] || [ "${legacy_tag}" = "${sub_hash}" ];then
			get_domain_name "${sublink_url}"
			return 0
		fi
	done
	return 1
}

get_file_group_fallback(){
	local file_name=$(basename "$1")
	local sub_hash=""
	case "${file_name}" in
	local_0_user.txt)
		return 1
		;;
	local_*_*.txt)
		sub_hash=$(echo "${file_name}" | sed -n 's/^local_[0-9]\+_\([^.]\+\)\.txt$/\1/p')
		;;
	online_*_*.txt)
		sub_hash=$(echo "${file_name}" | sed -n 's/^online_[0-9]\+_\([^.]\+\)\.txt$/\1/p')
		;;
	esac
	[ -n "${sub_hash}" ] && get_sub_group_fallback_by_hash "${sub_hash}"
}

get_group_label_from_file(){
	local file_path="$1"
	local fallback_name="$2"
	local first_group=""
	local real_group=""
	local first_meta=""
	local sep="$(printf '\037')"
	[ -z "${file_path}" -o ! -f "${file_path}" ] && echo -n "${fallback_name}" && return 0
	first_meta="$(sub_first_line_meta_tsv "${file_path}")" || first_meta=""
	IFS="${sep}" read -r _first_airport _first_scope _first_hash first_group <<-EOF
	${first_meta}
	EOF
	real_group=$(normalize_group_name "${first_group}")
	if [ -n "${real_group}" ];then
		echo -n "${real_group}"
		return 0
	fi
	local group_label=$(sub_extract_groups_from_file "${file_path}" | while IFS= read -r raw_group
	do
		real_group=$(normalize_group_name "${raw_group}")
		[ -n "${real_group}" ] && echo "${real_group}"
	done | sort -u | sed '/^$/d' | sed 's/$/ + /g' | sed ':a;N;$!ba;s#\n##g' | sed 's/ + $//g')
	if [ -n "${group_label}" ];then
		echo -n "${group_label}"
	else
		echo -n "${fallback_name}"
	fi
}

sub_rewrite_group_label_for_file(){
	local file_path="$1"
	local group_label="$2"
	local source_tag="$3"
	local tmp_file="${file_path}.group.$$"
	local group_hash=""
	[ -f "${file_path}" ] || return 1
	[ -n "${group_label}" ] || return 1
	[ -n "${source_tag}" ] || return 1
	group_hash="${group_label}_${source_tag}"
	jq -c --arg group_hash "${group_hash}" '.group = $group_hash' "${file_path}" > "${tmp_file}" 2>/dev/null || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${file_path}"
}

sub_resolve_online_group_label(){
	local file_path="$1"
	local domain_name="$2"
	local payload_kind="$3"
	local download_filename="$4"
	local raw_group=""
	local domain_label=""
	local file_label=""

	[ -n "${domain_name}" ] || return 1
	raw_group="$(get_group_label_from_file "${file_path}" "" 2>/dev/null)"
	domain_label="$(sub_conf_lookup_domain_airport_label "${domain_name}" 2>/dev/null)"
	if [ -n "${domain_label}" ];then
		printf '%s\n' "${domain_label}"
		return 0
	fi
	if [ -n "${raw_group}" ] && [ "${raw_group}" != "${domain_name}" ];then
		printf '%s\n' "${raw_group}"
		return 0
	fi
	if [ "${payload_kind}" = "clash-yaml" ] && [ -n "${download_filename}" ];then
		file_label="$(sub_conf_lookup_clash_prefix_airport_label "${download_filename}" 2>/dev/null)"
		if [ -n "${file_label}" ];then
			printf '%s\n' "${file_label}"
			return 0
		fi
	fi
	if [ -n "${raw_group}" ];then
		printf '%s\n' "${raw_group}"
	else
		printf '%s\n' "${domain_name}"
	fi
}

sub_find_local_source_file(){
	local source_tag="$1"
	local matches=""
	local first_match=""
	local match_count=0

	[ -n "${source_tag}" ] || return 1
	if [ "${LOCAL_SPLIT_META_VALID}" = "1" ] && [ -s "${LOCAL_SPLIT_META}" ];then
		matches=$(awk -F '\t' -v source_tag="${source_tag}" '$3 == source_tag {print $1}' "${LOCAL_SPLIT_META}" 2>/dev/null)
	else
		matches=$(find "${DIR}" -name "local_*_${source_tag}.txt" 2>/dev/null | sort -n)
	fi
	first_match=$(printf '%s\n' "${matches}" | sed '/^$/d' | sed -n '1p')
	match_count=$(printf '%s\n' "${matches}" | sed '/^$/d' | wc -l)
	[ -n "${first_match}" ] || return 1
	if [ "${match_count}" -gt "1" ];then
		echo_date "⚠️检测到来源【${source_tag}】对应多个本地节点文件，优先使用第一份进行对比。"
	fi
	printf '%s' "${first_match}"
}

skipdb2json(){
	local node_tool=""
	if [ "${SEQ_NU}" == "0" ];then
		return
	fi
	rm -f "${LOCAL_SPLIT_META}"
	LOCAL_SPLIT_META_VALID=0
	sanitize_invalid_local_groups
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		node_tool="$(pick_node_tool_command "export-sources" 2>/dev/null)" || node_tool=""
		if [ -n "${node_tool}" ];then
			echo_date "➡️使用node-tool整理本地节点到文件，请稍等..."
		else
			echo_date "➡️开始整理本地节点到文件，请稍等..."
		fi
		if [ -n "${node_tool}" ];then
			rm -rf "$DIR"/local_*.txt "${LOCAL_SPLIT_META}"
			if "${node_tool}" export-sources --output-dir "${DIR}" --meta "${LOCAL_SPLIT_META}" --all-jsonl "${LOCAL_NODES_SPL}" >/dev/null 2>&1;then
				if [ -f "${LOCAL_NODES_SPL}" ] && [ -s "${LOCAL_SPLIT_META}" ];then
					LOCAL_SPLIT_META_VALID=1
					echo_date "📁所有本地节点成功整理到文件：${LOCAL_NODES_SPL}"
					cp -rf ${LOCAL_NODES_SPL} ${LOCAL_NODES_BAK}
					return 0
				fi
				rm -rf "$DIR"/local_*.txt "${LOCAL_SPLIT_META}" "${LOCAL_NODES_SPL}" >/dev/null 2>&1
			fi
			echo_date "⚠️node-tool整理本地节点失败，回退脚本路径。"
		fi
		sub_prepare_schema2_export_jsonl || {
			echo_date "⚠️节点文件处理失败！请重启路由器后重试！"
			exit 1
		}
		cp -f "${SCHEMA2_EXPORT_JSONL}" "${LOCAL_NODES_SPL}"
		if [ -f "${LOCAL_NODES_SPL}" ];then
			echo_date "📁所有本地节点成功整理到文件：${LOCAL_NODES_SPL}"
			cp -rf ${LOCAL_NODES_SPL} ${LOCAL_NODES_BAK}
		else
			echo_date "⚠️节点文件处理失败！请重启路由器后重试！"
			exit 1
		fi
		return 0
	fi
	# 将所有节点数据储存到文件，顺便清理掉空值的key
	dbus list ssconf_basic_ | grep -E "_[0-9]+=" | sed '/^ssconf_basic_.\+_[0-9]\+=$/d' | sed 's/^ssconf_basic_//' >${DIR}/ssconf_keyval.txt
	NODES_SEQ=$(cat ${DIR}/ssconf_keyval.txt | sed -n 's/name_\([0-9]\+\)=.*/\1/p'| sort -n)
	for nu in ${NODES_SEQ}
	do
		# cat ssconf_keyval.txt |grep _2=|sed "s/_2=/\":\"/"|sed 's/^/"/;s/$/\"/;s/$/,/g;1 s/^/{/;$ s/,$/}/'| tr -d '\n' |sed 's/$/\n/'
		cat ${DIR}/ssconf_keyval.txt | grep "_${nu}=" | sed "s/_${nu}=/\":\"/" | sed 's/^/"/;s/$/\"/;s/$/,/g;1 s/^/{/;$ s/,$/}/' | tr -d '\n' | sed 's/$/\n/' >>${LOCAL_NODES_SPL}
	done
	if [ -f "${LOCAL_NODES_SPL}" ];then
		echo_date "📁所有本地节点成功整理到文件：${LOCAL_NODES_SPL}"
		cp -rf ${LOCAL_NODES_SPL} ${LOCAL_NODES_BAK}
	else
		echo_date "⚠️节点文件处理失败！请重启路由器后重试！"
		exit 1
	fi
}

nodes2files(){
	if [ "${SEQ_NU}" == "0" ];then
		return
	fi
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ] && [ "${LOCAL_SPLIT_META_VALID}" = "1" ] && [ -s "${LOCAL_SPLIT_META}" ];then
		return 0
	fi
	rm -rf "$DIR"/local_*.txt "${LOCAL_SPLIT_META}"
	[ -f "${LOCAL_NODES_SPL}" ] || return 0
	local split_total
	: > "${LOCAL_SPLIT_META}"
	jq -r '
		def raw_group: (.group // "null");
		def trimmed_group:
			(raw_group | sub("^\\s+"; "") | sub("\\s+$"; ""));
		def group_label:
			if (trimmed_group == "" or trimmed_group == "null" or trimmed_group == "_") then
				""
			else
				(trimmed_group | sub("_[^_]+$"; ""))
			end;
		def group_hash:
			raw_group as $raw
			| if (group_label == "") then
				"user"
			elif ($raw | contains("_")) then
				($raw | sub("^.*_"; ""))
			else
				$raw
			end;
		"\(group_hash)\u001f\(group_label)\u001f\(.)"
	' "${LOCAL_NODES_SPL}" 2>/dev/null | awk -F '\037' -v dir="${DIR}" -v meta="${LOCAL_SPLIT_META}" '
		BEGIN {
			next_idx = 0
		}
		{
			hash = $1
			label = $2
			json = $3
			if (hash == "" || hash == "null") {
				hash = "user"
			}
			if (!(hash in file_path)) {
				if (hash == "user") {
					file_path[hash] = dir "/local_0_user.txt"
					order[++order_count] = hash
					group_value[hash] = "user"
					group_label[hash] = ""
				} else {
					next_idx++
					file_path[hash] = dir "/local_" next_idx "_" hash ".txt"
					order[++order_count] = hash
					group_value[hash] = hash
					group_label[hash] = label
				}
			}
			print json >> file_path[hash]
			count[hash]++
		}
		END {
			for (i = 1; i <= order_count; i++) {
				hash = order[i]
				printf "%s\t%s\t%s\t%s\n", file_path[hash], count[hash] + 0, group_value[hash], group_label[hash] >> meta
			}
		}
	' || {
		echo_date "⚠节点文件处理失败！请重启路由器后重试！"
		exit 1
	}

	split_total=$(awk -F '\t' '{total += $2} END {print total + 0}' "${LOCAL_SPLIT_META}" 2>/dev/null)
	if [ "${split_total}" != "$(wc -l < "${LOCAL_NODES_SPL}")" ];then
		echo_date "⚠节点文件处理失败！请重启路由器后重试！"
		exit 1
	fi
	LOCAL_SPLIT_META_VALID=1
}

nodes_stats(){
	echo_date "-----------------------------------"
	local GROP
	local NUBS
	local TTNODE
	local NFILES=$(find $DIR -name "local_*.txt" | sort -n)
	if [ "${LOCAL_SPLIT_META_VALID}" = "1" ] && [ -s "${LOCAL_SPLIT_META}" ];then
		TTNODE=$(awk -F '\t' '{total += $2} END {print total + 0}' "${LOCAL_SPLIT_META}" 2>/dev/null)
		echo_date "📢当前节点统计信息：共有节点${TTNODE}个，其中："
		while IFS='	' read -r file count group_hash group_label
		do
			[ -n "${file}" ] || continue
			NUBS="${count}"
			if [ "$(basename "${file}")" == "local_0_user.txt" ];then
				GROP_NAME="😛【用户自添加】节点"
			else
				[ -n "${group_label}" ] || group_label=$(get_group_label_from_file "${file}" "$(get_sub_group_fallback_by_hash "${group_hash}")")
				GROP_NAME="🚀【${group_label}】机场节点"
			fi
			echo_date ${GROP_NAME}: ${NUBS}个
		done < "${LOCAL_SPLIT_META}"
	elif [ -n "${NFILES}" ];then
		TTNODE=$(cat ${LOCAL_NODES_BAK} 2>/dev/null| wc -l)
		echo_date "📢当前节点统计信息：共有节点${TTNODE}个，其中："
		for file in ${NFILES}
		do
			local fallback_name=$(get_file_group_fallback "${file}")
			GROP=$(get_group_label_from_file "${file}" "${fallback_name}")
			NUBS=$(cat $file | wc -l)
			if [ "$(basename "${file}")" == "local_0_user.txt" ];then
				GROP_NAME="😛【用户自添加】节点"
			else
				GROP_NAME="🚀【${GROP}】机场节点"
			fi
			echo_date ${GROP_NAME}: ${NUBS}个
		done
	else
		echo_date "📢当前尚无任何节点...继续！"
	fi
	echo_date "-----------------------------------"
}

remove_null(){
	if [ "${SEQ_NU}" == "0" ];then
		# 没有节点，不进行检查
		return
	fi
	[ "${LOCAL_SPLIT_META_VALID}" = "1" ] && [ -s "${LOCAL_SPLIT_META}" ] || return
	[ -s "${ACTIVE_SOURCE_TAGS}" ] || return
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		local node_tool=""
		local prune_log=""
		local removed_any=0
		node_tool="$(pick_node_tool_command "prune-export-sources" 2>/dev/null)" || node_tool=""
		if [ -n "${node_tool}" ];then
			prune_log="${LOCAL_SPLIT_META}.prune.$$"
			if "${node_tool}" prune-export-sources --meta "${LOCAL_SPLIT_META}" --active-source-tags "${ACTIVE_SOURCE_TAGS}" --format shell > "${prune_log}" 2>/dev/null;then
				while IFS='	' read -r action source_tag group_label count path
				do
					[ "${action}" = "remove" ] || continue
					echo_date "⚠️检测到【${group_label:-${source_tag}}】机场已经不再订阅！尝试删除该订阅的节点！"
					sub_mark_removed_source_tag "${source_tag}"
					removed_any=1
				done < "${prune_log}"
				rm -f "${prune_log}" >/dev/null 2>&1
				if [ "${removed_any}" = "1" ];then
					SUB_LOCAL_CHANGED=1
				fi
				return 0
			fi
			rm -f "${prune_log}" >/dev/null 2>&1
		fi
	fi
	local keep_hash_file tmp_meta removed_any=0
	keep_hash_file="${ACTIVE_SOURCE_TAGS}"
	tmp_meta="${LOCAL_SPLIT_META}.tmp"
	: > "${tmp_meta}"
	while IFS='	' read -r file count group_hash group_label
	do
		[ -n "${file}" ] || continue
		case "${group_hash}" in
		""|"null"|"user")
			printf '%s\t%s\t%s\t%s\n' "${file}" "${count}" "${group_hash}" "${group_label}" >> "${tmp_meta}"
			continue
			;;
		esac
		if grep -Fxq "${group_hash}" "${keep_hash_file}";then
			printf '%s\t%s\t%s\t%s\n' "${file}" "${count}" "${group_hash}" "${group_label}" >> "${tmp_meta}"
			continue
		fi
		[ -n "${group_label}" ] || group_label=$(get_sub_group_fallback_by_hash "${group_hash}")
		echo_date "⚠️检测到【${group_label}】机场已经不再订阅！尝试删除该订阅的节点！"
		sub_mark_removed_source_tag "${group_hash}"
		rm -rf "${file}"
		removed_any=1
	done < "${LOCAL_SPLIT_META}"
	mv -f "${tmp_meta}" "${LOCAL_SPLIT_META}"
	if [ "${removed_any}" = "1" ];then
		SUB_LOCAL_CHANGED=1
	fi
}

clear_nodes(){
	# 写入节点钱需要清空所有ssconf配置
	echo_date "⌛节点写入前准备..."
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		if [ "${SUB_FAST_APPEND}" = "1" ];then
			echo_date "😀准备完成！"
			return 0
		fi
		sub_capture_active_nodes
		SUB_REWRITE_ALL=1
		echo_date "😀准备完成！"
		return 0
	fi
	if [ "${SEQ_NU}" == "0" ];then
		return
	fi
	dbus list ssconf_basic_|awk -F "=" '{print "dbus remove "$1}' >$DIR/ss_nodes_remove.sh
	chmod +x $DIR/ss_nodes_remove.sh
	sh $DIR/ss_nodes_remove.sh
	sync
	[ -n "${CURR_NODE}" ] && dbus set ssconf_basic_node=$CURR_NODE
	echo_date "😀准备完成！"
}

get_type_name() {
	case "$1" in
		0)
			echo "ss"
		;;
		1)
			echo "ssr"
		;;
		3)
			echo "V2ray"
		;;
		4)
			echo "xray"
		;;
		5)
			echo "trojan"
		;;
		6)
			echo "NaïveProxy"
		;;
		7)
			echo "tuic"
		;;
		8)
			echo "hysteria2"
		;;
	esac
}

# 清除已有的所有旧配置的节点
remove_all_node(){
	echo_date "删除所有节点信息！"
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		local node_tool=""
		node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
		if [ -n "${node_tool}" ];then
			"${node_tool}" delete-nodes --all >/dev/null 2>&1 || return 1
		else
			fss_clear_v2_nodes
			dbus set fss_node_next_id=1
		fi
		fss_mark_native_schema2_storage >/dev/null 2>&1 || true
	else
	confs=$(dbus list ssconf_basic_ | cut -d "=" -f1 | awk '{print $NF}')
	for conf in ${confs}
	do
		#echo_date "移除配置：${conf}"
		dbus remove ${conf}
	done
	fi
	# remove group name
	for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
	do
		dbus remove ${conf1}
	done

	# remove group hash
	for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
	do
		dbus remove ${conf2}
	done
	fss_refresh_node_direct_cache >/dev/null 2>&1
	fss_clear_airport_special_confs >/dev/null 2>&1 || true
	echo_date "删除成功！"
}

# 删除所有订阅节点
remove_sub_node(){
	echo_date "删除所有订阅节点信息...自添加的节点不受影响！"
	#remove_node_info
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		local node_tool=""
		node_tool="$(pick_node_tool 2>/dev/null)" || node_tool=""
		if [ -n "${node_tool}" ];then
			local subscribe_count
			subscribe_count=$("${node_tool}" stat --format json 2>/dev/null | sed -n 's/.*"subscribe":\([0-9][0-9]*\).*/\1/p' | sed -n '1p')
			[ -n "${subscribe_count}" ] || subscribe_count=0
			if [ "${subscribe_count}" = "0" ];then
				echo_date "节点列表内不存在任何订阅来源节点，退出！"
				return 1
			fi
			"${node_tool}" delete-nodes --all-subscribe >/dev/null 2>&1 || return 1
			for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
			do
				dbus remove ${conf1}
			done
			for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
			do
				dbus remove ${conf2}
			done
			fss_refresh_node_direct_cache >/dev/null 2>&1
			fss_clear_airport_special_confs >/dev/null 2>&1 || true
			fss_schedule_webtest_cache_warm "" "${SUB_WEBTEST_WARM_LOG}" >/dev/null 2>&1
			echo_date "所有订阅节点信息已经成功删除！"
			sub_refresh_node_state
			return 0
		fi
		local remove_flag=0
		local keep_order=""
		local first_keep=""
		local max_keep="0"
		local restore_current=""
		local restore_failover=""
		sub_capture_active_nodes
		for remove_nu in $(sub_list_node_ids)
		do
			local group_value=""
			local node_name=""
			local node_json=""
			node_json="$(fss_v2_get_node_json_by_id "${remove_nu}" 2>/dev/null)" || node_json=""
			if [ -n "${node_json}" ];then
				fss_unpack_node_meta "${node_json}" || return 1
				group_value="${FSS_NODE_META_GROUP}"
				node_name="${FSS_NODE_META_NAME}"
			else
				group_value="$(sub_get_node_field_plain "${remove_nu}" group)"
				node_name="$(sub_get_node_field_plain "${remove_nu}" name)"
			fi
			if [ -n "$(normalize_group_name "${group_value}")" ];then
				echo_date "移除第$remove_nu节点：【${node_name}】"
				fss_clear_webtest_cache_node "${remove_nu}"
				dbus remove fss_node_${remove_nu}
				remove_flag=1
			else
				keep_order="${keep_order}${keep_order:+,}${remove_nu}"
				[ -z "${first_keep}" ] && first_keep="${remove_nu}"
				if [ "${remove_nu}" -gt "${max_keep}" ] 2>/dev/null;then
					max_keep="${remove_nu}"
				fi
			fi
		done
		if [ "${remove_flag}" = "0" ];then
			echo_date "节点列表内不存在任何订阅来源节点，退出！"
			return 1
		fi
		[ -n "${keep_order}" ] && dbus set fss_node_order="${keep_order}" || dbus remove fss_node_order
		if sub_node_exists_in_order "${CURR_NODE}";then
			restore_current="${CURR_NODE}"
		else
			restore_current="${first_keep}"
		fi
		if sub_node_exists_in_order "${FAILOVER_NODE}";then
			restore_failover="${FAILOVER_NODE}"
		fi
		fss_set_current_node_id "${restore_current}"
		fss_set_failover_node_id "${restore_failover}"
		dbus set fss_node_next_id="$((max_keep + 1))"
		fss_mark_native_schema2_storage >/dev/null 2>&1 || true
		fss_clear_webtest_runtime_results
		fss_touch_node_catalog_ts >/dev/null 2>&1
		fss_touch_node_config_ts >/dev/null 2>&1
		for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
		do
			dbus remove ${conf1}
		done
		for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
		do
			dbus remove ${conf2}
		done
		fss_refresh_node_direct_cache >/dev/null 2>&1
		fss_clear_airport_special_confs >/dev/null 2>&1 || true
		fss_schedule_webtest_cache_warm "" "${SUB_WEBTEST_WARM_LOG}" >/dev/null 2>&1
		echo_date "所有订阅节点信息已经成功删除！"
		sub_refresh_node_state
		return 0
	fi
	remove_nus=$(dbus list ssconf_basic_group_ | sed -n 's/ssconf_basic_group_\([0-9]\+\)=.\+$/\1/p' | sort -n)
	if [ -z "${remove_nus}" ]; then
		echo_date "节点列表内不存在任何订阅来源节点，退出！"
		return 1
	fi

	for remove_nu in ${remove_nus}
	do
		echo_date "移除第$remove_nu节点：【$(dbus get ssconf_basic_name_${remove_nu})】"
		dbus list ssconf_basic_|grep "_${remove_nu}="|sed -n 's/\(ssconf_basic_\w\+\)=.*/\1/p' |  while read key
		do
			dbus remove $key
		done
	done
	for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
	do
		dbus remove ${conf1}
	done
	for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
	do
		dbus remove ${conf2}
	done
	fss_refresh_node_direct_cache >/dev/null 2>&1
	fss_clear_airport_special_confs >/dev/null 2>&1 || true
	fss_schedule_webtest_cache_warm "" "${SUB_WEBTEST_WARM_LOG}" >/dev/null 2>&1
	echo_date "所有订阅节点信息已经成功删除！"
}

check_nodes(){
	if [ "${SEQ_NU}" == "0" ];then
		return
	fi
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		echo_date "ℹ️当前为 schema 2 节点存储，跳过 legacy 节点顺序检查。"
		return 0
	fi
	mkdir -p ${DIR}
	local BACKUP_FILE=${DIR}/ss_conf.sh
	echo_date "➡️开始节点数据检查..."
	local ADJUST=0
	local MAX_NU=${NODE_INDEX}
	dbus list ssconf_basic_ | grep -E "_[0-9]+=" >${DIR}/ssconf_keyval_origin.txt
	local KEY_NU=$(cat ${DIR}/ssconf_keyval_origin.txt | wc -l)
	local VAL_NU=$(cat ${DIR}/ssconf_keyval_origin.txt | cut -d "=" -f2 | sed '/^$/d' | wc -l)
	echo_date "ℹ️最大节点序号：${MAX_NU}"
	echo_date "ℹ️共有节点数量：${SEQ_NU}"

	# 如果[节点数量 ${SEQ_NU}]不等于[最大节点序号 ${MAX_NU}]，说明节点排序是不正确的。
	if [ ${SEQ_NU} -ne ${MAX_NU} ]; then
		local ADJUST=1
		echo_date "⚠️节点顺序不正确，需要调整！"
	fi

	# 如果key的数量不等于value的数量，说明有些key储存了空值，需要清理一下。
	if [ ${KEY_NU} -ne ${VAL_NU} ]; then
		echo_date "KEY_NU $KEY_NU"
		echo_date "VAL_NU $VAL_NU"
		local ADJUST=1
		echo_date "⚠️节点配置有残余值，需要清理！"
	fi

	if [ ${ADJUST} == "1" ]; then
		# 提取干净的节点配置，并重新排序，现在web界面里添加/删除节点后会自动排序，所以以下基本不会运行到
		echo_date "💾备份所有节点信息并重新排序..."
		echo_date "⌛如果节点数量过多，此处可能需要等待较长时间，请耐心等待..."
		rm -rf ${BACKUP_FILE}
		cat > ${BACKUP_FILE} <<-EOF
			#!/bin/sh
			source /koolshare/scripts/base.sh
			#------------------------
			# remove all nodes first
			confs=\$(dbus list ssconf_basic_ | cut -d "=" -f 1)
			for conf in \$confs
			do
			    dbus remove \$conf
			done
			usleep 300000
			#------------------------
			# rewrite all node in order
		EOF

		# node to json file
		sed -i '/^ssconf_basic_.\+_[0-9]\+=$/d' ${DIR}/ssconf_keyval_origin.txt
		local count="1"
		for nu in ${NODES_SEQ}
		do
			cat ${DIR}/ssconf_keyval_origin.txt | grep "_${nu}=" | sed "s/_${nu}=/_${count}=\"/g;s/^/dbus set /;s/$/\"/" >>${BACKUP_FILE}
			let count+=1
		done
		echo_date "⌛备份完毕，开始调整..."
		# 2 应用提取的干净的节点配置
		chmod +x ${BACKUP_FILE}
		sh ${BACKUP_FILE}
		echo_date "ℹ️节点调整完毕！"
		
		# 重新获取节点序列
		NODES_SEQ=$(dbus list ssconf_basic_name_ | sed -n 's/^.*_\([0-9]\+\)=.*/\1/p' | sort -n)
		NODE_INDEX=$(echo ${NODES_SEQ} | sed 's/.*[[:space:]]//')
	else
		echo_date "😀节点顺序正确，节点配置信息OK！"
	fi
}

filter_nodes(){
	# ------------------------------- 关键词匹配逻辑 -------------------------------
	# 用[排除]和[包括]关键词去匹配，剔除掉用户不需要的节点，剩下的需要的节点：UPDATE_FLAG=0，
	# UPDATE_FLAG=0,需要的节点；1.判断本地是否有此节点，2.如果有就添加，没有就判断是否需要更新
	# UPDATE_FLAG=2,不需要的节点；1. 判断本地是否有此节点，2.如果有就删除，没有就不管
	local _type=$1
	local remarks=$2
	local server=$3
	local keyword_text="${remarks} ${server}"
	local KEY_MATCH_1=""
	local KEY_MATCH_2=""
	if [ "${SUB_KEEP_INFO_NODE}" != "1" ] && printf '%s' "${remarks}" | grep -Eiq '^(Expire|Traffic|Sync)[:：]|^(剩余流量|套餐到期|订阅到期|到期时间|流量重置|更新于|更新时间)[:：]'; then
		echo_date "⚪${_type}节点：【${remarks}】，不添加，因为是订阅信息节点"
		let exclude+=1
		return 1
	fi
	if [ -z "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ];then
		return 0
	fi
	[ -n "${KEY_WORDS_1}" ] && KEY_MATCH_1=$(keyword_filter_match_text "${keyword_text}" "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && KEY_MATCH_2=$(keyword_filter_match_text "${keyword_text}" "${KEY_WORDS_2}")
	if [ -n "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：no
		if [ -n "${KEY_MATCH_1}" ]; then
			echo_date "⚪${_type}节点：【${remarks}】，不添加，因为匹配了[排除]关键词"
			let exclude+=1 
			return 1
		else
			return 0
		fi
	elif [ -z "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：no，包括节点：yes
		if [ -z "${KEY_MATCH_2}" ]; then
			echo_date "⚪${_type}节点：【${remarks}】，不添加，因为不匹配[包括]关键词"
			let exclude+=1 
			return 1
		else
			return 0
		fi
	elif [ -n "${KEY_WORDS_1}" -a -n "${KEY_WORDS_2}" ]; then
		# 排除节点：yes，包括节点：yes
		if [ -n "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "⚪${_type}节点：【${remarks}】，不添加，因为匹配了[排除+包括]关键词"
			let exclude+=1 
			return 1
		elif [ -n "${KEY_MATCH_1}" -a -n "${KEY_MATCH_2}" ]; then
			echo_date "⚪${_type}节点：【${remarks}】，不添加，因为匹配了[排除]关键词"
			let exclude+=1 
			return 1
		elif  [ -z "${KEY_MATCH_1}" -a -z "${KEY_MATCH_2}" ]; then
			echo_date "⚪${_type}节点：【${remarks}】，不添加，因为不匹配[包括]关键词"
			let exclude+=1 
			return 1
		else
			return 0
		fi
	else
		return 0
	fi
}

add_ss_node(){
	local urllink="$1"
	local action="$2"
	unset info_first string_nu decrypt_info server_raw encrypt_method password remarks server server_port 
	unset plugin_support obfs_para plugin_prog ss_obfs ss_obfs_host group
	remarks=$(echo "${urllink}" | sed -n 's/.*#\(.*\).*$/\1/p' | urldecode | sed 's/^[[:space:]]//g')
	
	echo "${remarks}" | isutf8 -q
	if [ "$?" != "0" ];then
		echo_date "当前节点名中存在特殊字符，节点添加后可能出现乱码！"
		remarks=""
	fi

	if [ "${action}" == "1" ];then
		group=$(echo "${urllink}" | urldecode | sed -n 's/.\+group=\(.\+\)#.\+/\1/p')
		if [ -n "${group}" ];then
			group=$(dec64 $group)
		fi
		group=$(normalize_group_name "${group}")
		[ -z "${group}" ] && group=${DOMAIN_NAME}
	fi

	urllink=${urllink%%#*}
	info_first=$(echo "${urllink}" | sed 's/[@:/?#]/\n/g' | sed -n '1p')
	dec64 "${info_first}" >/dev/null 2>&1
	if [ "$?" == "0" ];then
		# first string is base64
		string_nu=$(echo "${urllink}" | sed 's/[@:/?#]/\n/g' | wc -l)
		if [ "${string_nu}" -eq "1" ];then
			# method:password@server:port are base64
			decrypt_info=$(dec64 "${info_first}")
			server_raw=$(echo "${decrypt_info}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
			if [ -n "${server_raw}" ];then
				server="${server_raw%%:*}"
				server_port="${server_raw##*:}"
			fi
			encrypt_method="${decrypt_info%%:*}"
			password="${decrypt_info%%@*}"
			password="${password#*:}"
		elif [ "${string_nu}" -gt "1" ];then
			# method:passwor are base64
			decrypt_info=$(dec64 "${info_first}")
			server_raw=$(echo "${urllink}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
			if [ -n "${server_raw}" ];then
				server="${server_raw%%:*}"
				server_port="${server_raw##*:}"
			fi
			encrypt_method="${decrypt_info%%:*}"
			password="${decrypt_info%%@*}"
			password="${password#*:}"
		fi
	else
		# first string not base64
		# method:password@server:port/?group=group#remark
		encrypt_method=${info_first}
		server_raw=$(echo "${urllink}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
		if [ -n "${server_raw}" ];then
			server="${server_raw%%:*}"
			server_port="${server_raw##*:}"
		fi
		password=$(echo "${urllink}" | sed 's/[@:/?#]/\n/g' | sed -n '2p')
	fi

	if [ "${action}" == "2" ];then
		password=$(printf '%s' "${password}" | sed 's/[[:space:]]$//g')
	else
		password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
	fi
	ss_obfs="0"
	ss_obfs_host=""

	if [ -n $(echo "${urllink}"|grep -Eo "plugin=") ];then
		obfs_para=$(echo "${urllink}" | sed -n 's/.\+plugin=\(\)/\1/p'|sed 's/@/|/g;s/:/|/g;s/?/|/g;s/#/|/g;s/&/|/g' | awk -F'|' '{print $1}'| urldecode)
		plugin_prog=$(echo "${obfs_para}" | awk -F';' '{print $1}')
		if [ "${plugin_prog}" == "obfs-local" -o "${plugin_prog}" == "simple-obfs" ];then
			ss_obfs=$(echo "${obfs_para}" | awk -F';' '{print $2}'| awk -F'=' '{print $2}')
			ss_obfs_host=$(echo "${obfs_para}" | awk -F';' '{print $3}'| awk -F'=' '{print $2}')
		fi
	fi

	# echo ------------------------
	# echo urllink: ${urllink}
	# echo info_first: ${info_first}
	# echo decrypt_info: ${decrypt_info}
	# echo remarks: ${remarks}
	# echo server: ${server}
	# echo server_port: ${server_port}
	# echo encrypt_method: ${encrypt_method}
	# echo password: $(dec64 $password)
	# echo group: ${group}
	# echo plugin_prog: ${plugin_prog}
	# echo ss_obfs: ${ss_obfs}
	# echo ss_obfs_host: ${ss_obfs_host}
	# echo ------------------------

	if [ -z "${remarks}" ] && [ -n "${server}" ] && [ -n "${server_port}" ]; then
		remarks="${server}:${server_port}"
	fi

	if [ -z "${server}" -o -z "${server_port}" -o -z "${password}" -o -z "${encrypt_method}" ]; then
		local _shadowtls=$(echo "${urllink}" | grep -Eo "shadow-tls")
		if [ -n "${_shadowtls}" ]; then
			echo_date "🔴SS节点：这是一个shadow-tls节点，不支持，跳过！"
		else
			echo_date "🔴SS节点：检测到一个错误节点，跳过！"
		fi
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "SS" "${remarks}" "${server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi
	
	sub_log_node_success "🟢SS节点：${remarks}"
	
	json_init
	json_add_string group "${group}_${SUB_SOURCE_TAG}"
	json_add_string method "${encrypt_method}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${remarks}"
	json_add_string password "${password}"
	json_add_string port "${server_port}"
	json_add_string server "${server}"
	json_add_string ss_obfs "${ss_obfs}"
	json_add_string ss_obfs_host "${ss_obfs_host}"
	json_add_string type "0"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

add_ssr_node(){
	local urllink="$1"
	local action="$2"
	unset decrypt_info server server_port protocol encrypt_method obfs password obfsparam_temp obfsparam protoparam_temp protoparam remarks_temp remarks group_temp group

	local decrypt_info=$(dec64 ${urllink})

	# mysql.accessconnect.cc:699:auth_aes128_md5:rc4-md5:tls1.2_ticket_auth:ZGkxNVBW/?obfsparam=MWRjZjMxOTg2NjEud3d3Lmdvdi5oaw&protoparam=MTk4NjYxOjMydUk5RQ&remarks=TGFyZ2Ug5Y-w54GjMDQgLSBJRVBMIHwg5YCN546HOjEuNQ&group=5rW36LGa5rm-
	# server:port:protocol:method:obfs:password/?obfsparam=xxx&protoparam=xxx&remarks=xxx&group=xxx
	server=$(echo "${decrypt_info}" | awk -F':' '{print $1}' | sed 's/[[:space:]]//g')
	server_port=$(echo "${decrypt_info}" | awk -F':' '{print $2}')
	encrypt_method=$(echo "${decrypt_info}" |awk -F':' '{print $4}')
	password=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | awk -F'/' '{print $1}')
	
	protocol=$(echo "${decrypt_info}" | awk -F':' '{print $3}')
	protoparam_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "protoparam.+" | sed 's/protoparam=//g' | awk -F'&' '{print $1}')
	if [ -n "${protoparam_temp}" ];then
		protoparam=$(dec64 ${protoparam_temp} | sed 's/_compatible//g' | sed 's/[[:space:]]//g')
	else
		protoparam=""
	fi
	
	obfs=$(echo "${decrypt_info}" | awk -F':' '{print $5}' | sed 's/_compatible//g')
	obfsparam_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "obfsparam.+" | sed 's/obfsparam=//g' | awk -F'&' '{print $1}')
	if [ -n "${obfsparam_temp}" ];then
		obfsparam=$(dec64 ${obfsparam_temp})
	else
		obfsparam=""
	fi
	remarks_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "remarks.+" | sed 's/remarks=//g' | awk -F'&' '{print $1}')
	# 在线订阅必须要remarks信息
	if [ "${action}" == "1" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(dec64 ${remarks_temp})
		else
			remarks=""
		fi
	elif [ "${action}" == "2" ]; then
		if [ -n "${remarks_temp}" ];then
			remarks=$(dec64 ${remarks_temp})
		else
			remarks="${server}"
		fi
	fi
	group_temp=$(echo "${decrypt_info}" | awk -F':' '{print $6}' | grep -Eo "group.+" | sed 's/group=//g' | awk -F'&' '{print $1}')
	if [ "${action}" == "1" ]; then
		# 在线订阅，group从订阅链接里拿
		if [ -n "${group_temp}" ];then
			ssr_group=$(dec64 $group_temp)
		fi
		ssr_group=$(normalize_group_name "${ssr_group}")
		[ -z "${ssr_group}" ] && ssr_group=${DOMAIN_NAME}
		ssr_group_hash="${ssr_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		ssr_group=""
		ssr_group_hash=""
	fi
	
	# for debug, please keep it here~
	# echo ------------
	# echo group: $group
	# echo remarks: $remarks
	# echo server: $server
	# echo server_port: $server_port
	# echo password: $password
	# echo encrypt_method: $encrypt_method
	# echo protocol: $protocol
	# echo protoparam: $protoparam
	# echo obfs: $obfs
	# echo obfsparam: $obfsparam
	# echo ------------

	if [ -z "${server}" -o -z "${remarks}" -o -z "${server_port}" -o -z "${password}" -o -z "${protocol}" -o -z "${obfs}" -o -z "${encrypt_method}" ]; then
		echo_date "🔴SSR节点：检测到一个错误节点，跳过！"
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "SSR" "${remarks}" "${server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🔵SSR节点：$remarks"
	
	json_init
	json_add_string group "${ssr_group_hash}"
	json_add_string method "${encrypt_method}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${remarks}"
	json_add_string password "${password}"
	json_add_string port "${server_port}"
	json_add_string rss_obfs "${obfs}"
	json_add_string rss_obfs_param "${obfsparam}"
	json_add_string rss_protocol "${protocol}"
	json_add_string rss_protocol_param "${protoparam}"
	json_add_string server "${server}"
	json_add_string type "1"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

json_query(){
	echo "${2}" | sed 's/^{//;s/}$//;s/,"/,\n"/g;s/":"/":/g' | sed 's/,$//g;s/"$//g' | sed -n "s/^\"${1}\":\(.\+\)\$/\1/p"
}

add_vmess_node(){
	local urllink="$1"
	local action="$2"
	unset decrypt_info v_remark_tmp v_ps v_add v_port v_id v_aid v_scy v_net v_type
	unset v_headerType_tmp v_headtype_tcp v_headtype_kcp v_headtype_quic v_grpc_mode v_grpc_authority v_tls v_kcp_seed
	unset v_ai_tmp v_ai v_alpn v_alpn_h2_tmp v_alpn_http_tmp v_alpn_h2 v_alpn_http v_sni v_v v_host v_path v_group v_group_hash
	decrypt_info=$(dec64 ${urllink} | run jq -c '.')
	# node name, could be ps/remark in sub json，必须项
	
	v_ps=$(json_query ps "${decrypt_info}")
	[ -z "${v_ps}" ] && v_ps=$(json_query remark "${decrypt_info}")

	# node server addr，必须项
	v_add=$(json_query add "${decrypt_info}")

	# node server port，必须项
	v_port=$(json_query port "${decrypt_info}")

	# node uuid，必须项
	v_id=$(json_query id "${decrypt_info}")

	# alterid，必须项，如果为空则填0
	v_aid=$(json_query aid "${decrypt_info}")
	[ -z "${v2ray_aid}" ] && v2ray_aid="0"

	# 加密方式 (security)，v2ray必须字段，订阅中机场很多不提供该值，设为auto就好了
	v_scy=$(json_query scy "${decrypt_info}")
	[ -z "${v_scy}" ] && v_scy="auto"
	
	# 传输协议: tcp kcp ws h2 quic grpc
	v_net=$(json_query net "${decrypt_info}")
	[ -z "${v_net}" ] && v_net="tcp"
	
	# 伪装类型，在tcp kcp quic中使用，grpc mode借用此字段，ws和h2中不使用
	v_type=$(json_query type "${decrypt_info}")
	[ -z "${v_type}" ] && v_type=$(json_query headerType "${decrypt_info}")
	v_grpc_authority=$(json_query authority "${decrypt_info}")

	case ${v_net} in
	tcp)
		# tcp协议设置【tcp伪装类型 (type)】
		v_headtype_tcp=${v_type}
		v_headtype_kcp=""
		v_headtype_quic=""
		v_grpc_mode=""
		v_grpc_authority=""
		[ -z "${v_headtype_tcp}" ] && v_headtype_tcp="none"
		;;
	kcp)
		# kcp协议设置【kcp伪装类型 (type)】
		v_headtype_tcp=""
		v_headtype_kcp=${v_type}
		v_headtype_quic=""
		v_grpc_mode=""
		v_grpc_authority=""
		[ -z "${v_headtype_kcp}" ] && v_headtype_kcp="none"
		;;
	ws|h2)
		# ws/h2协议设置【伪装域名 (host))】
		v_headtype_tcp=""
		v_headtype_kcp=""
		v_headtype_quic=""
		v_grpc_mode=""
		v_grpc_authority=""
		;;
	quic)
		# quic协议设置【quic伪装类型 (type)】
		v_headtype_tcp=""
		v_headtype_kcp=""
		v_headtype_quic=${v_type}
		v_grpc_mode=""
		v_grpc_authority=""
		[ -z "${v_headtype_quic}" ] && v_headtype_quic="none"
		;;
	grpc)
		# grpc协议设置【grpc模式】
		v_headtype_tcp=""
		v_headtype_kcp=""
		v_headtype_quic=""
		v_grpc_mode=${v_type}
		[ -z "${v_grpc_mode}" ] && v_grpc_mode="multi"
		;;
	esac

	# 底层传输安全：none, tls
	v_tls=$(json_query tls "${decrypt_info}")
	if [ "${v_tls}" == "tls" ];then
		# 跳过证书验证 (AllowInsecure)，此处在底层传输安全（network_security）为tls时使用
		v_ai_tmp=$(json_query verify_cert "${decrypt_info}")
		if [ "${v_ai_tmp}" == "true" ];then
			v_ai=""
		else
			v_ai="1"
		fi

		# alpn: h2; http/1.1; h2,http/1.1，此处在底层传输安全（network_security）为tls时使用
		v_alpn=$(json_query alpn "${decrypt_info}")
		v_alpn_h2_tmp=$(echo "${v_alpn}" | grep "h2")
		v_alpn_http_tmp=$(echo "${v_alpn}" | grep "http/1.1")
		if [ -n "${v_alpn_h2_tmp}" ];then
			v_alpn_h2="1"
		else
			v_alpn_h2=""
		fi
		if [ -n "${v_alpn_http_tmp}" ];then
			v_alpn_http="1"
		else
			v_alpn_http=""
		fi

		# SNI, 如果空则用host替代，如果host空则空，此处在底层传输安全（network_security）为tls时使用
		v_sni=$(json_query sni "${decrypt_info}")
		[ "${SUB_AI}" == "1" ] && v_ai="1"
	else
		v_tls="none"
		v_ai=""
		v_alpn_h2=""
		v_alpn_http=""
		v_sni=""
	fi

	# sub version, 1 or 2
	v_v=$(json_query v "${decrypt_info}")

	# v2ray host & path
	v_host=$(json_query host "${decrypt_info}")
	v_path=$(json_query path "${decrypt_info}")

	# host is not needed in kcp and grpc
	if [ "${v_net}" == "kcp" -o "${v_net}" == "grpc" ];then
		v_host=""
	fi

	if [ "${v_net}" == "kcp" ];then
		v_kcp_seed=${v_path}
	fi
	
	# 根据订阅版本不同，来设置host path
	if [ "${v_v}" != "2" -a "${v_net}" == "ws" -a -n "${v_host}" ]; then
		format_ws=$(echo ${v_host} | grep -E ";")
		if [ -n "${format_ws}" ]; then
			v_host=$(echo ${v_host} | cut -d ";" -f1)
			v_path=$(echo ${v_host} | cut -d ";" -f2)
		else
			v_host=""
			v_path=${v_host}
		fi
	fi

	if [ "${action}" == "1" ];then
		v_group=${DOMAIN_NAME}
		v_group_hash="${v_group}_${SUB_SOURCE_TAG}"
	fi
	
	# for debug
	# echo ------------------
	# echo vmess_v: ${v_v}
	# echo vmess_ps: ${v_ps}
	# echo vmess_add: ${v_add}
	# echo vmess_port: ${v_port}
	# echo vmess_id: ${v_id}
	# echo vmess_net: ${v_net}
	# echo vmess_type: ${v_type}
	# echo vmess_scy: ${v_scy}
	# echo vmess_host: ${v_host}
	# echo vmess_path: ${v_path}
	# echo vmess_tls: ${v_tls}
	# echo ------------------
	
	if [ -z "${v_ps}" -o -z "${v_add}" -o -z "${v_port}" -o -z "${v_id}" ];then
		# 丢弃无效节点
		echo_date "🔴vmess节点：检测到一个错误节点，跳过！"
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "vmess" "${v_ps}" "${v_add}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🟠vmess节点：${v_ps}"

	json_init
	json_add_string group "${v_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${v_ps}"
	json_add_string port "${v_port}"
	json_add_string server "${v_add}"
	json_add_string type "3"
	json_add_string v2ray_alterid "${v_aid}"
	json_add_string v2ray_grpc_mode "${v_grpc_mode}"
	json_add_string v2ray_grpc_authority "${v_grpc_authority}"
	json_add_string v2ray_headtype_kcp "${v_headtype_kcp}"
	json_add_string v2ray_headtype_quic "${v_headtype_quic}"
	json_add_string v2ray_headtype_tcp "${v_headtype_tcp}"
	json_add_string v2ray_kcp_seed "${v_kcp_seed}"
	json_add_string v2ray_mux_enable "0"
	json_add_string v2ray_network "${v_net}"
	json_add_string v2ray_network_host "${v_host}"
	json_add_string v2ray_network_path "${v_path}"
	json_add_string v2ray_network_security "${v_tls}"
	json_add_string v2ray_network_security_ai "${v_ai}"
	json_add_string v2ray_network_security_alpn_h2 "${v_alpn_h2}"
	json_add_string v2ray_network_security_alpn_http "${v_alpn_http}"
	json_add_string v2ray_network_security_sni "${v_sni}"
	json_add_string v2ray_security "${v_scy}"
	json_add_string v2ray_use_json "0"
	json_add_string v2ray_uuid "${v_id}"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

sub_uri_query_value(){
	local uri="$1"
	local key="$2"
	printf '%s' "${uri}" | awk -F"?" '{print $2}' | sed 's/&/\n/g;s/#/\n/g' | awk -F"=" -v key="${key}" '$1 == key {print substr($0, length($1) + 2); exit}'
}

sub_uri_bool_value(){
	local value
	value=$(printf '%s' "$1" | tr 'A-Z' 'a-z')
	case "${value}" in
	1|true|yes|on)
		echo "1"
		;;
	*)
		echo ""
		;;
	esac
}

sub_uri_query_bool(){
	sub_uri_bool_value "$(sub_uri_query_value "$1" "$2")"
}

sub_log_unsupported_scheme_once(){
	local scheme="$1"
	local seen_file="${2:-${UNSUPPORTED_PROTO_LOG_FILE}}"
	[ -n "${scheme}" ] || return 0
	[ -n "${seen_file}" ] || seen_file="${DIR}/unsupported_proto_seen.txt"
	[ -d "${DIR}" ] || mkdir -p "${DIR}" >/dev/null 2>&1
	touch "${seen_file}" >/dev/null 2>&1
	if ! grep -Fxq "${scheme}" "${seen_file}" 2>/dev/null; then
		printf '%s\n' "${scheme}" >> "${seen_file}"
		echo_date "⛔检测到不支持的${scheme}格式节点，后续同协议节点将直接跳过！"
	fi
}

sub_log_unsupported_scheme_summary(){
	local file="$1"
	[ -s "${file}" ] || return 0
	awk -F '://' '
		BEGIN {
			supported["ss"] = 1
			supported["ssr"] = 1
			supported["vmess"] = 1
			supported["vless"] = 1
			supported["trojan"] = 1
			supported["hysteria2"] = 1
			supported["hy2"] = 1
			supported["tuic"] = 1
			supported["naive+https"] = 1
			supported["naive+quic"] = 1
		}
		NF >= 2 {
			scheme = $1
			if (!(scheme in supported)) {
				cnt[scheme]++
			}
		}
		END {
			for (scheme in cnt) {
				printf "⚫%s节点：%s个（不支持）\n", scheme, cnt[scheme]
			}
		}
	' "${file}" | sort | while IFS= read -r line
	do
		[ -n "${line}" ] && echo_date "${line}"
	done
}

sub_uri_scheme(){
	printf '%s' "${1}" | sed -n 's#^\([A-Za-z0-9+.-]\+\)://.*#\1#p'
}

sub_uri_body(){
	printf '%s' "${1}" | sed -n 's#^[A-Za-z0-9+.-]\+://\(.*\)$#\1#p'
}

sub_is_ipv4_literal(){
	printf '%s' "${1}" | awk -F'.' '
		NF != 4 { exit 1 }
		{
			for (i = 1; i <= 4; i++) {
				if ($i !~ /^[0-9]+$/ || $i < 0 || $i > 255) {
					exit 1
				}
			}
		}
		END { exit 0 }
	'
}

sub_is_ipv6_literal(){
	printf '%s' "${1}" | grep -Eq '^[0-9A-Fa-f:.%]+$' && printf '%s' "${1}" | grep -q ':'
}

sub_is_ip_literal(){
	local host="$1"
	[ -n "${host}" ] || return 1
	sub_is_ipv4_literal "${host}" && return 0
	sub_is_ipv6_literal "${host}" && return 0
	return 1
}

sub_uri_split_host_port(){
	local hostport="$1"
	local host=""
	local port=""

	case "${hostport}" in
	\[*\]:*)
		host=$(printf '%s' "${hostport}" | sed -n 's/^\[\([^]]\+\)\]:.*$/\1/p')
		port=$(printf '%s' "${hostport}" | sed -n 's/^\[[^]]\+\]:\(.*\)$/\1/p')
		;;
	\[*\])
		host=$(printf '%s' "${hostport}" | sed -n 's/^\[\([^]]\+\)\]$/\1/p')
		;;
	*:* )
		if [ "$(printf '%s' "${hostport}" | awk -F':' '{print NF}')" -gt "2" ];then
			host="${hostport}"
		else
			host="${hostport%%:*}"
			port="${hostport#*:}"
		fi
		;;
	*)
		host="${hostport}"
		;;
	esac

	printf '%s\t%s\n' "${host}" "${port}"
}

sub_uri_join_host_port(){
	local host="$1"
	local port="$2"
	if [ -z "${host}" ];then
		return 1
	fi
	if [ -n "${port}" ];then
		case "${host}" in
		*:* )
			printf '[%s]:%s' "${host}" "${port}"
			;;
		*)
			printf '%s:%s' "${host}" "${port}"
			;;
		esac
	else
		case "${host}" in
		*:* )
			printf '[%s]' "${host}"
			;;
		*)
			printf '%s' "${host}"
			;;
		esac
	fi
}

add_vless_node(){
	local decode_link="$1"
	local decode_link=$(echo "${decode_link}" | urldecode)
	local action="$2"
	local strtype="$3"
	unset x_server_raw x_server x_server_port x_remarks x_uuid x_host x_path x_encryption x_type
	unset x_headerType x_headtype_tcp x_headtype_kcp x_headtype_quic x_grpc_mode x_grpc_authority x_security_tmp x_security
	unset x_alpn x_alpn_h2_tmp x_alpn_http_tmp x_alpn_h2 x_alpn_http x_sni x_flow x_group x_group_hash x_kcp_seed
	unset x_ai x_fp x_pbk x_pcs x_vcn x_sid x_spx

	local _STRING_1=$(echo "${decode_link}" | awk -F"?" '{print $1}')
	local _STRING_2=$(echo "${decode_link}" | awk -F"?" '{print $2}')

	x_server_raw=$(echo "${decode_link}" | sed -n 's/.\+@\(.\+:[0-9]\+\).*/\1/p')
	x_server="${x_server_raw%%:*}"
	x_server_port="${x_server_raw##*:}"
	x_uuid="${decode_link%%@*}"
	#x_server=$(echo "${x_server_raw}" | awk -F':' '{print $1}')
	#x_server_port=$(echo "${x_server_raw}" | awk -F':' '{print $2}')
	#x_uuid=$(echo "${decode_link}" | awk -F"@" '{print $1}')

	echo "${decode_link}" | grep -Eqo "#"
	if [ "$?" != "0" ];then
		x_remarks=${x_server}
	else
		x_remarks=$(echo "${decode_link}" | awk -F"#" '{print $NF}')
	fi
	
	if [ "${strtype}" == "vmess" ];then
		x_aid=$(echo "${_STRING_2}" |sed 's/&/\n/g;s/#/\n/g' | grep "alterId" | awk -F"=" '{print $2}')
	fi
	x_host=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "host" | awk -F"=" '{print $2}')
	x_path=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "path" | awk -F"=" '{print $2}' | urldecode)
	x_encryption=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "encryption" | awk -F"=" '{print $2}')
	if [ -z "${x_encryption}" ];then
		if [ "${strtype}" = "vmess" ];then
			x_encryption="auto"
		else
			x_encryption="none"
		fi
	fi
	x_type=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "type" | grep -v "header" | awk -F"=" '{print $2}')
	if [ -z "${x_type}" ];then
		x_type="tcp"
	fi
	x_headerType=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "headerType" | awk -F"=" '{print $2}')
	x_mode=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "mode" | awk -F"=" '{print $2}')
	x_security=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "security" | awk -F"=" '{print $2}')
	x_serviceName=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "serviceName" | awk -F"=" '{print $2}' | urldecode)
	x_grpc_authority=$(sub_uri_query_value "${decode_link}" "authority" | urldecode)
	x_sni=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "sni" | awk -F"=" '{print $2}')
	x_flow=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "flow" | awk -F"=" '{print $2}')
	x_ai=$(sub_uri_query_bool "${decode_link}" "allowInsecure")
	[ -z "${x_ai}" ] && x_ai=$(sub_uri_query_bool "${decode_link}" "insecure")
	x_fp=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "fp=" | awk -F"=" '{print $2}')
	x_pbk=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "pbk=" | awk -F"=" '{print $2}')
	x_pcs=$(sub_uri_query_value "${decode_link}" "pcs" | urldecode)
	x_vcn=$(sub_uri_query_value "${decode_link}" "vcn" | urldecode)
	x_sid=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "sid=" | awk -F"=" '{print $2}')
	x_spx=$(echo "${_STRING_2}"|sed 's/&/\n/g;s/#/\n/g' | grep "spx=" | awk -F"=" '{print $2}' | urldecode)
	case ${x_type} in
	tcp)
		# tcp协议设置【tcp伪装类型 (type)】
		x_headtype_tcp=${x_headerType}
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=""
		x_grpc_authority=""
		if [ -z "${x_headtype_tcp}" ];then
			x_headtype_tcp="none"
		fi
		;;
	kcp)
		# kcp协议设置【kcp伪装类型 (type)】
		x_headtype_tcp=""
		x_headtype_kcp=${x_headerType}
		x_headtype_quic=""
		x_grpc_mode=""
		x_grpc_authority=""
		if [ -z "${x_headtype_kcp}" ];then
			x_headtype_kcp="none"
		fi
		;;
	ws)
		# ws/h2协议设置【伪装域名 (host))】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=""
		x_grpc_authority=""
		;;
	h2)
		# ws/h2协议设置【伪装域名 (host))】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=""
		x_grpc_authority=""
		if [ -z "${x_host}" ];then
			x_host="${x_server}"
		fi
		;;
	quic)
		# quic协议设置【quic伪装类型 (type)】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=${x_headerType}
		x_grpc_mode=""
		x_grpc_authority=""
		if [ -z "${x_headtype_quic}" ];then
			x_headtype_quic="none"
		fi
		;;
	grpc)
		# grpc协议设置【grpc模式】
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_mode=${x_mode}
		if [ -n "${x_grpc_mode}" ];then
			x_grpc_mode="${x_grpc_mode}"
		else
			x_grpc_mode="gun"
		fi
		if [ -n "${x_serviceName}" ];then
			x_path="${x_serviceName}"
		fi
		;;
	xhttp)
		# xhttp
		x_headtype_tcp=""
		x_headtype_kcp=""
		x_headtype_quic=""
		x_grpc_authority=""
		x_xhttp_mode=${x_mode}
		if [ -z "${x_host}" -a -z "${x_sni}" ];then
			x_host="${x_server}"
		fi
		;;
	esac

	# host is not needed in kcp and grpc
	if [ "${x_type}" == "kcp" -o "${x_type}" == "grpc" ];then 
		x_host=""
	fi

	if [ "${x_type}" == "kcp" ];then 
		x_kcp_seed=${x_path}
	fi

	# 底层传输安全：none, tls, xtls, reality
	if [ "${x_security}" == "tls" -o "${x_security}" == "xtls" ];then
		# alpn: h2; http/1.1; h2,http/1.1，此处在底层传输安全（network_security）为tls时使用
		x_alpn=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "alpn" | awk -F"=" '{print $2}' | urldecode)
		x_alpn_h2_tmp=$(echo "${x_alpn}" | grep "h2")
		x_alpn_http_tmp=$(echo "${x_alpn}" | grep "http/1.1")
		if [ -n "${x_alpn_h2_tmp}" ];then
			x_alpn_h2="1"
		else
			x_alpn_h2=""
		fi
		if [ -n "${x_alpn_http_tmp}" ];then
			x_alpn_http="1"
		else
			x_alpn_http=""
		fi
		[ "${SUB_AI}" == "1" ] && x_ai="1"
	elif [ "${x_security}" == "reality" ];then
		# fingerprint, reality must have fp
		if [ -z "${x_fp}" ];then
			x_fp="chrome"
		fi
		if [ "${x_type}" != "tcp" ];then
			x_flow=""
		fi
	fi
	
	if [ "${action}" == "1" ];then
		x_group=${DOMAIN_NAME}
		x_group_hash="${x_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		x_group=""
		x_group_hash=""
	fi
	# # for debug, please keep it here
	# echo ------------
	# echo decode_link: ${decode_link}
	# echo decrypt_info: ${decrypt_info}
	# echo group: ${x_group_hash}
	# echo remarks: ${x_remarks}
	# echo x_server_raw: ${x_server_raw}
	# echo server: ${x_server}
	# echo server_port: ${x_server_port}
	# echo uuid: ${x_uuid}
	# echo encryption: ${x_encryption}
	# echo type: ${x_type}
	# echo security: ${x_security}
	# echo AllowInsecure: ${x_ai}
	# echo host: ${x_host}
	# echo sni: ${x_sni}
	# echo fingerprint: ${x_fp}
	# echo flow: ${x_flow}
	# echo publicKey: ${x_pbk}
	# echo shortId: ${x_sid}
	# echo spiderX: ${x_spx}
	# echo path: ${x_path}
	# echo headerType: ${x_headerType}
	# echo x_headtype_tcp: ${x_headtype_tcp}
	# echo x_headtype_kcp: ${x_headtype_kcp}
	# echo x_headtype_quic: ${x_headtype_quic}
	# echo x_grpc_mode: ${x_grpc_mode}
	# echo x_xhttp_mode: ${x_xhttp_mode}
	# echo alpn: ${x_alpn}
	# echo ------------
	
	if [ -z "${x_server}" -o -z "${x_remarks}" -o -z "${x_server_port}" -o -z "${x_uuid}" ]; then
		# 丢弃无效节点
		if [ "${strtype}" == "vmess" ];then
			echo_date "🟠vmess节点：检测到一个错误节点，跳过！"
		else
			echo_date "🔴vless节点：检测到一个错误节点，跳过！"
		fi
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "vless" "${x_remarks}" "${x_server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	if [ "${strtype}" == "vmess" ];then
		sub_log_node_success "🟠vmess节点：${x_remarks}"
	else
		sub_log_node_success "🟣vless节点：${x_remarks}"
	fi
	
	json_init
	json_add_string group "${x_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${x_remarks}"
	json_add_string port "${x_server_port}"
	json_add_string server "${x_server}"
	json_add_string type "4"
	json_add_string xray_alterid "${x_aid}"
	json_add_string xray_encryption "${x_encryption}"
	json_add_string xray_fingerprint "${x_fp}"
	json_add_string xray_flow "${x_flow}"
	json_add_string xray_grpc_mode "${x_grpc_mode}"
	json_add_string xray_grpc_authority "${x_grpc_authority}"
	json_add_string xray_xhttp_mode "${x_xhttp_mode}"
	json_add_string xray_headtype_kcp "${x_headtype_kcp}"
	json_add_string xray_headtype_quic "${x_headtype_quic}"
	json_add_string xray_headtype_tcp "${x_headtype_tcp}"
	json_add_string xray_kcp_seed "${x_kcp_seed}"
	json_add_string xray_network "${x_type}"
	json_add_string xray_network_host "${x_host}"
	json_add_string xray_network_path "${x_path}"
	json_add_string xray_network_security "${x_security}"
	json_add_string xray_network_security_ai "${x_ai}"
	json_add_string xray_network_security_alpn_h2 "${x_alpn_h2}"
	json_add_string xray_network_security_alpn_http "${x_alpn_http}"
	json_add_string xray_network_security_sni "${x_sni}"
	json_add_string xray_pcs "${x_pcs}"
	json_add_string xray_prot "${strtype}"
	json_add_string xray_vcn "${x_vcn}"
	json_add_string xray_publickey "${x_pbk}"
	json_add_string xray_shortid "${x_sid}"
	json_add_string xray_show "0"
	json_add_string xray_spiderx "${x_spx}"
	#json_add_string xray_use_json
	json_add_string xray_uuid "${x_uuid}"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

add_trojan_node(){
	local decode_link="$1"
	local decode_link=$(echo "$1" | urldecode)
	local action="$2"
	unset t_server t_server_port t_remarks t_uuid t_ai t_tfo t_sni_tmp t_peer_tmp t_sni t_group t_group_hash t_plugin t_obfs t_obfshost t_obfsuri t_pcs t_vcn
	
	t_uuid=$(echo "${decode_link}" | awk -F"@" '{print $1}')
	t_server=$(echo "${decode_link}" | sed 's/@/ /g;s/:/ /g;s/?/ /g;s/#/ /g' | awk '{print $2}')
	t_server_port=$(echo "${decode_link}" | sed 's/@/ /g;s/:/ /g;s/?/ /g;s/#/ /g' | awk '{print $3}')

	echo "${decode_link}" | grep -Eqo "#"
	if [ "$?" != "0" ];then
		t_remarks=${t_server}
	else
		t_remarks=$(echo "${decode_link}" | awk -F"#" '{print $NF}')
	fi

	t_ai=$(sub_uri_query_bool "${decode_link}" "allowInsecure")
	[ -z "${t_ai}" ] && t_ai=$(sub_uri_query_bool "${decode_link}" "insecure")
	t_tfo=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "tfo" | awk -F"=" '{print $2}')
	t_sni_tmp=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "sni" | awk -F"=" '{print $2}')
	t_peer_tmp=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g' | grep "peer" | awk -F"=" '{print $2}')
	t_pcs=$(sub_uri_query_value "${decode_link}" "pcs" | urldecode)
	t_vcn=$(sub_uri_query_value "${decode_link}" "vcn" | urldecode)
	if [ -n "${t_sni_tmp}" ];then
		t_sni=${t_sni_tmp}
	else
		if [ -n "${t_peer_tmp}" ];then
			t_sni=${t_peer_tmp}
		fi
	fi
	t_plugin=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g;s/;/\n/g' | grep -E "^plugin=" | awk -F"=" '{print $2}')
	t_obfs=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g;s/;/\n/g' | grep -E "^obfs=" | awk -F"=" '{print $2}')
	t_obfshost=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g;s/;/\n/g' | grep -E "^obfs-host=" | awk -F"=" '{print $2}')
	t_obfsuri=$(echo "${decode_link}" | awk -F"?" '{print $2}'|sed 's/&/\n/g;s/#/\n/g;s/;/\n/g' | grep -E "^obfs-uri=" | awk -F"=" '{print $2}')
	if [ -z "${t_plugin}" -a "$(sub_uri_query_value "${decode_link}" "type" | tr 'A-Z' 'a-z')" == "ws" ];then
		t_plugin="obfs-local"
		t_obfs="websocket"
		t_obfshost=$(sub_uri_query_value "${decode_link}" "host" | urldecode)
		t_obfsuri=$(sub_uri_query_value "${decode_link}" "path" | urldecode)
	fi

	[ "${SUB_AI}" == "1" ] && t_ai="1"
	
	if [ "${action}" == "1" ];then
		t_group=${DOMAIN_NAME}
		t_group_hash="${t_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		t_group=""
		t_group_hash=""
	fi
	
	# for debug, please keep it here
	# echo ------------
	# echo group: ${t_group}
	# echo remarks: ${t_remarks}
	# echo server: ${t_server}
	# echo port: ${t_server_port}
	# echo password: ${t_uuid}
	# echo allowInsecure: ${t_ai}
	# echo SNI: ${t_sni}
	# echo plugin: ${t_tfo}
	# echo obfs: ${t_tfo}
	# echo obfs_host: ${t_tfo}
	# echo obfs_uri: ${t_tfo}
	# echo ------------	

	if [ -z "${t_server}" -o -z "${t_remarks}" -o -z "${t_server_port}" -o -z "${t_uuid}" ]; then
		# 丢弃无效节点
		echo_date "🔴trojan节点：检测到一个错误节点，跳过！"
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "trojan" "${t_remarks}" "${t_server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🟡trojan节点：${t_remarks}"
	
	json_init
	json_add_string group "${t_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${t_remarks}"
	json_add_string port "${t_server_port}"
	json_add_string server "${t_server}"
	json_add_string trojan_ai "${t_ai}"
	json_add_string trojan_pcs "${t_pcs}"
	json_add_string trojan_sni "${t_sni}"
	json_add_string trojan_tfo "${t_tfo}"
	json_add_string trojan_uuid "${t_uuid}"
	json_add_string trojan_vcn "${t_vcn}"
	json_add_string trojan_plugin "${t_plugin}"
	json_add_string trojan_obfs "${t_obfs}"
	json_add_string trojan_obfshost "${t_obfshost}"
	json_add_string trojan_obfsuri "${t_obfsuri}"
	json_add_string type "5"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

add_naive_node(){
	local scheme="$1"
	local decode_link="$2"
	local action="$3"
	local decode_link=$(printf '%s' "${decode_link}" | urldecode)
	unset naive_main naive_authority naive_query naive_auth naive_hostport naive_user naive_pass naive_server naive_port naive_remarks naive_group naive_group_hash naive_prot

	naive_main="${decode_link%%#*}"
	if [ "${naive_main#*\?}" != "${naive_main}" ];then
		naive_authority="${naive_main%%\?*}"
		naive_query="${naive_main#*\?}"
	else
		naive_authority="${naive_main}"
		naive_query=""
	fi
	naive_authority="${naive_authority%/}"

	if [ "${decode_link#*#}" != "${decode_link}" ];then
		naive_remarks=$(printf '%s' "${decode_link#*#}" | urldecode)
	fi

	if [ "${naive_authority##*@}" != "${naive_authority}" ];then
		naive_auth="${naive_authority%@*}"
		naive_hostport="${naive_authority##*@}"
	else
		naive_auth=""
		naive_hostport="${naive_authority}"
	fi

	if [ "${naive_auth#*:}" != "${naive_auth}" ];then
		naive_user=$(printf '%s' "${naive_auth%%:*}" | urldecode)
		naive_pass=$(printf '%s' "${naive_auth#*:}" | urldecode)
	else
		naive_user=""
		naive_pass=""
	fi

	local hostinfo
	hostinfo=$(sub_uri_split_host_port "${naive_hostport}")
	naive_server=$(printf '%s' "${hostinfo}" | awk -F'\t' '{print $1}')
	naive_port=$(printf '%s' "${hostinfo}" | awk -F'\t' '{print $2}')
	[ -z "${naive_port}" ] && naive_port="443"
	[ -z "${naive_remarks}" ] && naive_remarks="${naive_server}"

	naive_prot="${scheme#naive+}"
	case "${naive_prot}" in
	https|quic)
		:
		;;
	*)
		echo_date "🔴Naïve节点：暂不支持协议：${naive_prot}，跳过！"
		return 1
		;;
	esac

	if [ -n "$(sub_uri_query_value "${decode_link}" "extra-headers")" ];then
		echo_date "⚠️Naïve节点：检测到extra-headers参数，当前订阅解析暂未纳入该参数。"
	fi

	if [ "${action}" == "1" ];then
		naive_group=${DOMAIN_NAME}
		naive_group_hash="${naive_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		naive_group=""
		naive_group_hash=""
	fi

	if [ -z "${naive_server}" -o -z "${naive_port}" -o -z "${naive_user}" -o -z "${naive_pass}" ];then
		echo_date "🔴Naïve节点：检测到一个错误节点，跳过！"
		return 1
	fi

	if [ "${action}" == "1" ]; then
		filter_nodes "naive" "${naive_remarks}" "${naive_server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🟧Naïve节点：${naive_remarks}"

	naive_pass=$(printf '%s' "${naive_pass}" | base64_encode | sed 's/[[:space:]]//g')

	json_init
	json_add_string group "${naive_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${naive_remarks}"
	json_add_string naive_prot "${naive_prot}"
	json_add_string naive_server "${naive_server}"
	json_add_string naive_port "${naive_port}"
	json_add_string naive_user "${naive_user}"
	json_add_string naive_pass "${naive_pass}"
	json_add_string type "6"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

add_tuic_node(){
	local decode_link="$1"
	local action="$2"
	unset tuic_main tuic_authority tuic_query tuic_auth tuic_hostport tuic_uuid tuic_pass tuic_server tuic_port tuic_server_full tuic_remarks tuic_group tuic_group_hash
	unset tuic_ip tuic_alpn tuic_cc tuic_skip_verify tuic_server_override

	tuic_main="${decode_link%%#*}"
	if [ "${tuic_main#*\?}" != "${tuic_main}" ];then
		tuic_authority="${tuic_main%%\?*}"
		tuic_query="${tuic_main#*\?}"
	else
		tuic_authority="${tuic_main}"
		tuic_query=""
	fi
	tuic_authority="${tuic_authority%/}"

	if [ "${decode_link#*#}" != "${decode_link}" ];then
		tuic_remarks=$(printf '%s' "${decode_link#*#}" | urldecode)
	fi

	if [ "${tuic_authority##*@}" != "${tuic_authority}" ];then
		tuic_auth="${tuic_authority%@*}"
		tuic_hostport="${tuic_authority##*@}"
	else
		tuic_auth=""
		tuic_hostport="${tuic_authority}"
	fi

	tuic_auth=$(printf '%s' "${tuic_auth}" | urldecode)
	if [ "${tuic_auth#*:}" != "${tuic_auth}" ];then
		tuic_uuid=$(printf '%s' "${tuic_auth%%:*}" | urldecode)
		tuic_pass=$(printf '%s' "${tuic_auth#*:}" | urldecode)
	else
		tuic_uuid=""
		tuic_pass=""
	fi

	# Shadowrocket / sing-box style TUIC links often place credentials in query args
	# rather than in userinfo, e.g. tuic://host:port?uuid=...&password=...
	[ -z "${tuic_uuid}" ] && tuic_uuid=$(sub_uri_query_value "${decode_link}" "uuid" | urldecode)
	[ -z "${tuic_uuid}" ] && tuic_uuid=$(sub_uri_query_value "${decode_link}" "id" | urldecode)
	[ -z "${tuic_pass}" ] && tuic_pass=$(sub_uri_query_value "${decode_link}" "password" | urldecode)
	[ -z "${tuic_pass}" ] && tuic_pass=$(sub_uri_query_value "${decode_link}" "passwd" | urldecode)
	[ -z "${tuic_pass}" ] && tuic_pass=$(sub_uri_query_value "${decode_link}" "token" | urldecode)

	local hostinfo
	hostinfo=$(sub_uri_split_host_port "${tuic_hostport}")
	tuic_server=$(printf '%s' "${hostinfo}" | awk -F'\t' '{print $1}')
	tuic_port=$(printf '%s' "${hostinfo}" | awk -F'\t' '{print $2}')
	[ -z "${tuic_port}" ] && tuic_port="443"
	[ -z "${tuic_remarks}" ] && tuic_remarks="${tuic_server}"

	tuic_ip=$(sub_uri_query_value "${decode_link}" "ip" | urldecode)
	tuic_alpn=$(sub_uri_query_value "${decode_link}" "alpn" | urldecode)
	tuic_cc=$(sub_uri_query_value "${decode_link}" "congestion_control" | urldecode)
	tuic_skip_verify=$(sub_uri_query_bool "${decode_link}" "allow_insecure")
	[ -z "${tuic_skip_verify}" ] && tuic_skip_verify=$(sub_uri_query_bool "${decode_link}" "allowInsecure")
	[ -z "${tuic_skip_verify}" ] && tuic_skip_verify=$(sub_uri_query_bool "${decode_link}" "insecure")
	[ -z "${tuic_skip_verify}" ] && tuic_skip_verify=$(sub_uri_query_bool "${decode_link}" "skip_cert_verify")
	tuic_server_override=$(sub_uri_query_value "${decode_link}" "sni" | urldecode)

	if [ -n "${tuic_server_override}" ] && sub_is_ip_literal "${tuic_server}"; then
		tuic_ip="${tuic_server}"
		tuic_server="${tuic_server_override}"
	fi
	tuic_server_full=$(sub_uri_join_host_port "${tuic_server}" "${tuic_port}")

	if [ "${action}" == "1" ];then
		tuic_group=${DOMAIN_NAME}
		tuic_group_hash="${tuic_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		tuic_group=""
		tuic_group_hash=""
	fi

	if [ -z "${tuic_server}" -o -z "${tuic_port}" -o -z "${tuic_uuid}" -o -z "${tuic_pass}" ];then
		echo_date "🔴tuic节点：检测到一个错误节点，跳过！"
		return 1
	fi

	if [ "${action}" == "1" ]; then
		filter_nodes "tuic" "${tuic_remarks}" "${tuic_server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🟫tuic节点：${tuic_remarks}"

	local tuic_json
	tuic_json=$(run jq -cn \
		--arg server "${tuic_server_full}" \
		--arg uuid "${tuic_uuid}" \
		--arg password "${tuic_pass}" \
		--arg ip "${tuic_ip}" \
		--arg alpn "${tuic_alpn}" \
		--arg cc "${tuic_cc}" \
		--arg skip_verify "${tuic_skip_verify}" '
		{
			relay: (
				{
					server: $server,
					uuid: $uuid,
					password: $password
				}
				+ (if $ip != "" then {ip: $ip} else {} end)
				+ (if $alpn != "" then {alpn: ($alpn | split(",") | map(gsub("^[[:space:]]+|[[:space:]]+$"; "") | select(. != "")))} else {} end)
				+ (if $cc != "" then {congestion_control: $cc} else {} end)
				+ (if $skip_verify == "1" then {skip_cert_verify: true} else {} end)
			)
		}
	') || tuic_json=""

	if [ -z "${tuic_json}" ];then
		echo_date "🔴tuic节点：生成tuic配置失败，跳过！"
		return 1
	fi

	tuic_json=$(printf '%s' "${tuic_json}" | base64_encode | sed 's/[[:space:]]//g')

	json_init
	json_add_string group "${tuic_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${tuic_remarks}"
	json_add_string tuic_json "${tuic_json}"
	json_add_string type "7"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

add_hy2_node(){
	local decode_link="$1"
	local action="$2"
	unset hy2_authority hy2_hostport hy2_server hy2_port hy2_query hy2_remarks hy2_ai hy2_tfo hy2_sni hy2_group hy2_group_hash hy2_pcs hy2_vcn

	if [ -z "${HY2_UP_SPEED}" -a -n "${HY2_DL_SPEED}" ];then
		unset HY2_DL_SPEED
	elif [ -n "${HY2_UP_SPEED}" -a -z "${HY2_DL_SPEED}" ];then
		unset HY2_UP_SPEED
	fi

	if [ -z "${HY2_UP_SPEED}" -a -z "${HY2_DL_SPEED}" ];then
		echo_date "🔴hysteria2节点：未设置上行/下行速度，congestion（拥塞算法）默认采用：bbr"
		HY2_CG_OPT="bbr"
	elif [ -n "${HY2_UP_SPEED}" -a -n "${HY2_DL_SPEED}" ];then
		# echo_date "🔴hysteria2节点：congestion（拥塞算法）采用你设置的：${HY2_CG_OPT}！"
		HY2_CG_OPT="${HY2_CG_OPT:-$(dbus get ss_basic_hy2_cg_opt)}"
	fi

	local hy2_main="${decode_link%%#*}"
	if [ "${hy2_main#*\?}" != "${hy2_main}" ];then
		hy2_authority="${hy2_main%%\?*}"
		hy2_query="${hy2_main#*\?}"
	else
		hy2_authority="${hy2_main}"
		hy2_query=""
	fi
	hy2_authority="${hy2_authority%/}"
	if [ "${decode_link#*#}" != "${decode_link}" ];then
		hy2_remarks=$(printf '%s' "${decode_link#*#}" | urldecode)
	fi

	if [ "${hy2_authority##*@}" != "${hy2_authority}" ];then
		hy2_pass=$(printf '%s' "${hy2_authority%@*}" | urldecode)
		hy2_hostport="${hy2_authority##*@}"
	else
		hy2_pass=""
		hy2_hostport="${hy2_authority}"
	fi

	case "${hy2_hostport}" in
	\[*\]*)
		hy2_server=$(printf '%s' "${hy2_hostport}" | sed -n 's/^\[\([^]]\+\)\].*/\1/p')
		hy2_port=$(printf '%s' "${hy2_hostport}" | sed -n 's/^\[[^]]\+\]:\(.*\)$/\1/p')
		;;
	*)
		hy2_server="${hy2_hostport%%:*}"
		if [ "${hy2_hostport#*:}" != "${hy2_hostport}" ];then
			hy2_port="${hy2_hostport#*:}"
		else
			hy2_port=""
		fi
		;;
	esac

	[ -z "${hy2_port}" ] && hy2_port="443"
	[ -z "${hy2_remarks}" ] && hy2_remarks="${hy2_server}"

	hy2_sni=$(sub_uri_query_value "${decode_link}" "sni" | urldecode)
	hy2_obfs=$(sub_uri_query_value "${decode_link}" "obfs")
	if [ -z "${hy2_obfs}" -o "${hy2_obfs}" == "none" ];then
		hy2_obfs="0"
	fi
	if [ "${hy2_obfs}" == "salamander" ];then
		hy2_obfs="1"
	fi
	hy2_obfs_pass=$(sub_uri_query_value "${decode_link}" "obfs-password" | urldecode)
	hy2_ai=$(sub_uri_query_bool "${decode_link}" "insecure")
	[ -z "${hy2_ai}" ] && hy2_ai=$(sub_uri_query_bool "${decode_link}" "allowInsecure")
	hy2_tfo=$(sub_uri_query_value "${decode_link}" "tfo")
	hy2_mport=$(sub_uri_query_value "${decode_link}" "mport")
	hy2_pcs=$(sub_uri_query_value "${decode_link}" "pinSHA256" | urldecode)
	[ -z "${hy2_pcs}" ] && hy2_pcs=$(sub_uri_query_value "${decode_link}" "pcs" | urldecode)
	hy2_vcn=$(sub_uri_query_value "${decode_link}" "vcn" | urldecode)
	if [ -n "${hy2_mport}" ];then
		hy2_port=${hy2_mport}
	fi

	[ "${SUB_AI}" == "1" ] && hy2_ai="1"

	if [ "${action}" == "1" ];then
		hy2_group=${DOMAIN_NAME}
		hy2_group_hash="${hy2_group}_${SUB_SOURCE_TAG}"
	elif [ "${action}" == "2" ]; then
		# 离线离线添加节点，group不需要
		hy2_group=""
		hy2_group_hash=""
	fi
	
	# for debug, please keep it here
	# echo ------------
	# echo group: ${hy2_group}
	# echo remarks: ${hy2_remarks}
	# echo server: ${hy2_server}
	# echo port: ${hy2_port}
	# echo password: ${hy2_pass}
	# echo hy2_obfs: ${hy2_obfs}
	# echo hy2_obfs_pass: ${hy2_obfs_pass}
	# echo Insecure: ${hy2_ai}
	# echo SNI: ${hy2_sni}
	# echo TFO: ${hy2_tfo}
	# echo ------------	

	if [ -z "${hy2_server}" -o -z "${hy2_remarks}" -o -z "${hy2_port}" -o -z "${hy2_pass}" ]; then
		# 丢弃无效节点
		echo_date "🔴hysteria2节点：检测到一个错误节点，跳过！"
		return 1
	fi

	# 过滤节点
	if [ "${action}" == "1" ]; then
		filter_nodes "hysteria2" "${hy2_remarks}" "${hy2_server}"
		if [ "$?" != "0" ];then
			return 1
		fi
	fi

	sub_log_node_success "🟤hysteria2节点：${hy2_remarks}"
	
	json_init
	json_add_string group "${hy2_group_hash}"
	json_add_string mode "${SUB_MODE}"
	json_add_string name "${hy2_remarks}"
	json_add_string hy2_server "${hy2_server}"
	json_add_string hy2_port "${hy2_port}"
	json_add_string hy2_pass "${hy2_pass}"
	json_add_string hy2_ai "${hy2_ai}"
	json_add_string hy2_pcs "${hy2_pcs}"
	json_add_string hy2_sni "${hy2_sni}"
	json_add_string hy2_vcn "${hy2_vcn}"
	json_add_string hy2_obfs "${hy2_obfs}"
	json_add_string hy2_obfs_pass "${hy2_obfs_pass}"
	json_add_string hy2_up "${HY2_UP_SPEED}"
	json_add_string hy2_dl "${HY2_DL_SPEED}"
	json_add_string hy2_cg "${HY2_CG_OPT}"
	if [ "${HY2_TFO_SWITCH}" == "2" ];then
		json_add_string hy2_tfo "${hy2_tfo}"
	elif [ "${HY2_TFO_SWITCH}" == "1" ];then
		json_add_string hy2_tfo "1"
	elif [ "${HY2_TFO_SWITCH}" == "0" ];then
		json_add_string hy2_tfo "0"
	else
		json_add_string hy2_tfo "${hy2_tfo}"
	fi
	json_add_string type "8"

	if [ "${action}" == "1" ];then
		json_write_object ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
	elif [ "${action}" == "2" ]; then
		json_write_object ${DIR}/offline_node_new.txt
	fi
}

get_fancyss_running_status(){
	local STATUS_1=$(dbus get ss_basic_enable 2>/dev/null)
	local STATUS_2=$(iptables --t nat -S|grep SHADOWSOCKS|grep -w "3333" 2>/dev/null)
	local STATUS_3=$(netstat -nlp 2>/dev/null|grep -w "3333"|grep -E "ss-redir|sslocal|v2ray|koolgame|xray|ipt2socks")
	local STATUS_4=$(netstat -nlp 2>/dev/null|grep -w "7913")
	# 当插件状态为开启，iptables状态正常，透明端口进程正常，DNS端口正常，DNS配置文件正常
	if [ "${STATUS_1}" == "1" -a -n "${STATUS_2}" -a -n "${STATUS_3}" -a -n "${STATUS_4}" -a -f "/jffs/configs/dnsmasq.d/wblist.conf" ];then
		echo 1
	fi
}

get_domain_name(){
	echo "$1" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | awk -F ":" '{print $1}'
}

proxy_rule(){
	# wget don't support socks proxy, use this mothod to use current proxy
	local ACTION="$1"
	local DOMAIN="$2"
	case "${ACTION}" in
	add)
		rm -rf /tmp/fancyss_sublink_ips.txt
		run5 dnsclient -p 53 -t 2 -i 1 @223.5.5.5 ${DOMAIN} 2>/dev/null | grep -E "^IP" | awk '{print $2}' | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}$" >/tmp/fancyss_sublink_ips.txt
		if [ -f "/tmp/fancyss_sublink_ips.txt" ];then
			while read SUB_IP
			do
				#echo_date "add ${SUB_IP} to ipset: router"
				ipset -! add router ${SUB_IP}
			done </tmp/fancyss_sublink_ips.txt
			return 0
		else
			return 1
		fi
		;;
	del)
		if [ -f "/tmp/fancyss_sublink_ips.txt" ];then
			while read SUB_IP
			do
				#echo_date "del ${SUB_IP} to ipset: router"
				ipset -! del router ${SUB_IP}
			done </tmp/fancyss_sublink_ips.txt
			return 0
		else
			return 1
		fi
		;;
	esac
}

get_model(){
	local ODMPID=$(nvram get odmpid)
	local PRODUCTID=$(nvram get productid)
	if [ -n "${ODMPID}" ];then
		MODEL="${ODMPID}"
	else
		MODEL="${PRODUCTID}"
	fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno|grep -Eo "kool.+")
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			# 官改固件
			FW_TYPE="AsusWRT"
			FW_MOD="${KS_TAG}"
		else
			# 梅林改版固件
			FW_TYPE="AsusWRT-Merlin"
			FW_MOD="koolcenter"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			# 梅林原版
			FW_TYPE="AsusWRT-Merlin"
			FW_MOD="unknown"
		else
			FW_TYPE="AsusWRT"
			FW_MOD="unknown"
		fi
	fi
}

get_fw_ver(){
	local _buildno=$(nvram get buildno)
	local _extendno=$(nvram get extendno)
	if [ -n "${_buildno}" -a -n "${_extendno}" ];then
		fw_version="$(nvram get buildno)_$(nvram get extendno)"
	else
		fw_version="unknown"
	fi
}

get_ua(){
	# UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
	# UA="AsusWRT-Merlin/koolcenter/RT-BE88U/102.6/fancyss/hndv8/full/3.3.9"
	# UA="AsusWRT/koolcenter/RT-BE88U/102.5/fancyss/mtk/lite/3.3.9"
	# UA="系统名/改版方/机型/固件版本/fancyss/fancyss平台类型/fancyss类型/fancyss版本"
	get_fw_type
	get_model
	get_fw_ver
	local pkg_name=$(dbus get ss_basic_pkg_name)
	local pkg_arch=$(dbus get ss_basic_pkg_arch)
	local pkg_type=$(dbus get ss_basic_pkg_type)
	[ -n "${pkg_name}" ] || pkg_name=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_NAME=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	[ -n "${pkg_arch}" ] || pkg_arch=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_ARCH=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	[ -n "${pkg_type}" ] || pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local pkg_vers=$(dbus get ss_basic_version_local)
	local ua_mode="${SUB_ACTIVE_UA_MODE}"
	local ua_preset="${SUB_ACTIVE_UA_PRESET}"
	local ua_custom="${SUB_ACTIVE_UA_CUSTOM}"

	[ -n "${ua_mode}" ] || ua_mode="fixed"
	case "${ua_mode}" in
	custom)
		printf '%s' "${ua_custom}"
		return 0
		;;
	auto)
		ua_preset="${ua_preset:-default}"
		;;
	inherit|"")
		_UA=$(dbus get ss_basic_online_ua)
		ua_preset="$(subprof_ua_preset_from_legacy_value "${_UA}")"
		;;
	fixed|*)
		ua_preset="${ua_preset:-default}"
		;;
	esac

	case "${ua_preset}" in
	default)
		echo -n "${FW_TYPE}|${FW_MOD}|${MODEL}|${fw_version}|${pkg_name}|${pkg_arch}|${pkg_type}|${pkg_vers}|curl|v2rayN"
		;;
	curl)
		echo -n ""
		;;
	v2rayn)
		echo -n "v2rayn"
		;;
	v2rayng)
		echo -n "v2rayng"
		;;
	shadowrocket)
		echo -n "shadowrocket"
		;;
	*)
		echo -n "${FW_TYPE}|${FW_MOD}|${MODEL}|${fw_version}|${pkg_name}|${pkg_arch}|${pkg_type}|${pkg_vers}|curl|v2rayN"
		;;
	esac
	#&flag=shadowrocket
	#&flag=v2rayn
}

download_by_curl(){
	local url_encode=$(echo "$1")
	local header_file="$(sub_header_file_path "${SUB_LINK_HASH:0:4}")"
	
	echo_date "⬇️使用curl下载订阅..."
	local UA=$(get_ua)
	SUB_LAST_DOWNLOAD_TOOL="curl"
	SUB_LAST_DOWNLOAD_PATH="shell"
	SUB_LAST_DOWNLOAD_UA="${UA}"
	if [ -n "${UA}" ];then
		echo_date "🪧使用UA：$UA"
		local UA_ARG="--user-agent ${UA}"
	else
		echo_date "🪧使用UA：curl"
		local UA_ARG=""
	fi

	if [ ! -L "/tmp/curl-update" ];then
		ln -sf /koolshare/bin/curl-fancyss /tmp/curl-subscribe
	fi
	
	if [ "${SUB_BY_PROXY}" == "0" ]; then
		# 先直连下载
		SUB_LAST_DOWNLOAD_MODE="direct"
		echo_date "➡️通过本地网络直连下载订阅..."
		rm -f "${header_file}" >/dev/null 2>&1
		run /tmp/curl-subscribe -sSk -L ${UA_ARG} -D "${header_file}" --connect-timeout 5 -m 5 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		if [ "$?" == "0" ]; then
			return 0
		fi

		# 下载失败，使用代理下载
		echo_date "❌️直连下载订阅失败！尝试使用当前节点代理下载订阅！"
		SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "v2ray|xray|naive|tuic")
		if [ -n "${SOCKS5_OPEN}" ];then
			SUB_LAST_DOWNLOAD_MODE="proxy"
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			rm -f "${header_file}" >/dev/null 2>&1
			run /tmp/curl-subscribe -sSk -L ${UA_ARG} -D "${header_file}" --connect-timeout 5 -m 5 -x socks5h://127.0.0.1:23456 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
			return $?
		else
			echo_date "⚠️当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点工作异常，结束curl订阅下载！"
			return 1
		fi
	elif [ "${SUB_BY_PROXY}" == "1" ]; then
		# 代理下载
		SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "v2ray|xray|naive|tuic")
		if [ -n "${SOCKS5_OPEN}" ];then
			local EXT_ARG="-x socks5h://127.0.0.1:23456"
			SUB_LAST_DOWNLOAD_MODE="proxy"
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			rm -f "${header_file}" >/dev/null 2>&1
			run /tmp/curl-subscribe -sSk -L ${UA_ARG} -D "${header_file}" --connect-timeout 5 -m 5 -x socks5h://127.0.0.1:23456 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
			return $?
		else
			local EXT_ARG=""
			echo_date "⚠️当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点工作异常，改用常规网络下载..."
			return 1
		fi
	elif [ "${SUB_BY_PROXY}" == "2" ]; then
		# 直连下载
		SUB_LAST_DOWNLOAD_MODE="direct"
		echo_date "⬇️使用常规网络下载..."
		rm -f "${header_file}" >/dev/null 2>&1
		run /tmp/curl-subscribe -sSk -L ${UA_ARG} -D "${header_file}" --connect-timeout 5 -m 5 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		return $?
	fi
}

download_by_wget(){
	local url_encode=$(echo "$1")
	local header_file="$(sub_header_file_path "${SUB_LINK_HASH:0:4}")"
	#local url_encode="${url_encode}&flag=shadowrocket"
	echo_date "⬇️使用wget下载订阅..."
	local UA=$(get_ua)
	SUB_LAST_DOWNLOAD_TOOL="wget"
	SUB_LAST_DOWNLOAD_PATH="shell"
	SUB_LAST_DOWNLOAD_UA="${UA}"
	if [ -n "${UA}" ];then
		echo_date "🪧使用UA：$UA"
		local UA_ARG="--user-agent ${UA}"
	else
		echo_date "🪧使用UA：wget"
		local UA_ARG=""
	fi

	if [ -n $(echo $1 | grep -E "^https") ]; then
		local EXT_OPT="--no-check-certificate"
	else
		local EXT_OPT=""
	fi
	
	if [ ! -f "/root/.wget-hsts" ]; then 
		touch /root/.wget-hsts
		chmod 644 /root/.wget-hsts
	fi
	
	if [ "${SUB_BY_PROXY}" == "0" ]; then
		# 先直连下载
		SUB_LAST_DOWNLOAD_MODE="direct"
		echo_date "➡️通过本地网络直连下载订阅..."
		rm -f "${header_file}" >/dev/null 2>&1
		run5 wget -S -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt 2>"${header_file}"
		if [ "$?" == "0" ]; then
			return 0
		fi
		
		# 下载失败，使用代理下载
		echo_date "❌️直连下载订阅失败！尝试使用当前节点代理下载订阅！"
		proxy_rule add "${DOMAIN_NAME}"
		if [ "$?" == "0" ];then
			SUB_LAST_DOWNLOAD_MODE="proxy"
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			rm -f "${header_file}" >/dev/null 2>&1
			run5 wget -S -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt 2>"${header_file}"
		else
			echo_date "⚠️当前订阅链接域名：${DOMAIN_NAME}解析失败，结束wget订阅下载！"
			return 1
		fi
		proxy_rule del "${DOMAIN_NAME}"
	elif [ "${SUB_BY_PROXY}" == "1" ]; then
		# 代理下载
		proxy_rule add "${DOMAIN_NAME}"
		if [ "$?" == "0" ];then
			SUB_LAST_DOWNLOAD_MODE="proxy"
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			rm -f "${header_file}" >/dev/null 2>&1
			run5 wget -S -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt 2>"${header_file}"
		else
			echo_date "⚠️当前订阅链接域名：${DOMAIN_NAME}解析失败，结束wget订阅下载！"
			return 1
		fi
		proxy_rule del "${DOMAIN_NAME}"
	elif [ "${SUB_BY_PROXY}" == "2" ]; then
		# 直连下载
		SUB_LAST_DOWNLOAD_MODE="direct"
		echo_date "⬇️使用常规网络下载..."
		rm -f "${header_file}" >/dev/null 2>&1
		run5 wget -S -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt 2>"${header_file}"
		return $?
	fi
}

download_by_sub_get(){
	local url_encode="$1"
	local header_file="$(sub_header_file_path "${SUB_LINK_HASH:0:4}")"
	local plan_file="${DIR}/sub_get_plan_${SUB_LINK_HASH:0:4}.json"
	local sub_get_bin=""
	local ua_value=""
	local policy_value=""

	sub_get_bin="$(pick_sub_get 2>/dev/null)" || return 2
	sub_get_supports_command "${sub_get_bin}" "fetch" || return 2
	ua_value="$(get_ua)"
	case "${SUB_BY_PROXY}" in
	1)
		policy_value="proxy"
		;;
	2)
		policy_value="direct"
		;;
	*)
		policy_value="auto"
		;;
	esac
	SUB_LAST_DOWNLOAD_TOOL="sub-get"
	SUB_LAST_DOWNLOAD_PATH="sub-get"
	SUB_LAST_DOWNLOAD_MODE="${policy_value}"
	SUB_LAST_DOWNLOAD_UA="${ua_value}"
	echo_date "🧩检测到sub-get，优先尝试使用独立下载器..."
	sub_write_sub_get_plan "${plan_file}" "${url_encode}" "${ua_value}" "${policy_value}" "${SUB_ACTIVE_PROFILE_ID}" "${SUB_ACTIVE_PROFILE_NAME}" >/dev/null 2>&1 || true
	rm -f "${header_file}" >/dev/null 2>&1
	set -- fetch \
		--url "${url_encode}" \
		--output "${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt" \
		--header-output "${header_file}" \
		--policy "${policy_value}"
	[ -n "${ua_value}" ] && set -- "$@" --user-agent "${ua_value}"
	"${sub_get_bin}" "$@" >/dev/null 2>&1
	return $?
}

download_subscription_payload(){
	local url="$1"
	sub_reset_download_trace
	download_by_sub_get "${url}"
	case "$?" in
	0)
		return 0
		;;
	2)
		;;
	*)
		SUB_LAST_DOWNLOAD_ERROR="sub-get failed"
		return 1
		;;
	esac
	download_by_curl "${url}" && return 0
	echo_date "⚠️使用curl下载订阅失败！"
	rm -f "${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt" >/dev/null 2>&1
	download_by_wget "${url}" && return 0
	SUB_LAST_DOWNLOAD_ERROR="curl/wget failed"
	echo_date "⚠️wget下载订阅失败！"
	return 1
}

get_online_rule_now(){
	# 0. variable define
	local SUB_LINK="$1"
	local RAW_SOURCE_TAG=""
	local CANONICAL_SOURCE_TAG=""
	local SUB_SOURCE_TAG=""
	local DOMAIN_MAPPED_GROUP=""
	local FILE_MAPPED_GROUP=""
	SUB_TOOL_DIFF_FILE_CURRENT=""
	SUB_TOOL_DIFF_SUMMARY_FILE_CURRENT=""
	SUB_PAYLOAD_KIND=""
	SUB_DOWNLOAD_FILENAME=""

	# 1. get domain name of node subscribe link
	local DOMAIN_NAME="$(get_domain_name ${SUB_LINK})"
	if [ -z "${DOMAIN_NAME}" ];then
		echo_date "⚠️该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
		subscribe_failed
		return 1
	fi

	# 2. detect duplitcate sub
	local SUB_LINK_HASH=$(echo "${SUB_LINK}" | md5sum | awk '{print $1}')
	SUB_LAST_URL_HASH="${SUB_LINK_HASH:0:4}"
	RAW_SOURCE_TAG=$(sub_get_source_tag_from_domain "${DOMAIN_NAME}")
	SUB_SOURCE_TAG=$(sub_get_source_alias_tag "${RAW_SOURCE_TAG}")
	if [ -z "${SUB_SOURCE_TAG}" ];then
		echo_date "⚠️无法识别当前订阅来源域名，跳过此订阅！"
		return 1
	fi
	SUB_SOURCE_URL_HASH="${SUB_LINK_HASH:0:4}"
	DOMAIN_MAPPED_GROUP="$(sub_conf_lookup_domain_airport_label "${DOMAIN_NAME}" 2>/dev/null)"
	[ -n "${DOMAIN_MAPPED_GROUP}" ] || DOMAIN_MAPPED_GROUP="${DOMAIN_NAME}"
	SUB_AIRPORT_IDENTITY=$(sub_build_airport_identity "${DOMAIN_MAPPED_GROUP}" "${SUB_SOURCE_TAG}")
	SUB_SOURCE_SCOPE=$(sub_build_source_scope "${SUB_AIRPORT_IDENTITY}" "${SUB_SOURCE_URL_HASH}")
	if [ -f "/$DIR/sublink_md5.txt" ];then
		local IS_ADD=$(cat /$DIR/sublink_md5.txt | grep -Eo ${SUB_LINK_HASH})
		if [ -n "${IS_ADD}" ];then
			echo_date "⚠️检测到重复的订阅链接！不订阅该链接！请检查你的订阅地址栏填写情况！"
			return 1
		fi
	fi
	if [ -f "/$DIR/subsource_md5.txt" ];then
		local IS_SAME_SOURCE=$(grep -Fx "${SUB_SOURCE_TAG}" "/$DIR/subsource_md5.txt")
		if [ -n "${IS_SAME_SOURCE}" ];then
			echo_date "⚠️检测到相同域名的多个订阅链接，本次仅保留一个来源：${DOMAIN_NAME}"
			return 1
		fi
	fi
	echo ${SUB_LINK_HASH} >>/$DIR/sublink_md5.txt
	echo ${SUB_SOURCE_TAG} >>/$DIR/subsource_md5.txt
	UNSUPPORTED_PROTO_LOG_FILE="${DIR}/unsupported_proto_${SUB_SOURCE_TAG}.txt"
	rm -f "${UNSUPPORTED_PROTO_LOG_FILE}" >/dev/null 2>&1

	# 3. try to delete some file left by last sublink subscribe
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	
	# 7. download sublink
	echo_date "📁准备下载订阅链接到本地临时文件，请稍等..."
	download_subscription_payload "${SUB_LINK}" || return 1
	echo_date "😀下载成功，继续检测下载内容..."
	sub_validate_downloaded_payload "${SUB_LINK}" "${SUB_LINK_HASH:0:4}" "${SUB_LAST_DOWNLOAD_TOOL:-curl}" || {
		[ -n "${SUB_LAST_DOWNLOAD_ERROR}" ] || SUB_LAST_DOWNLOAD_ERROR="payload validation failed"
		return 1
	}
	
	echo_date "😀下载内容检测完成！"
	SUB_DOWNLOAD_FILENAME="$(sub_extract_filename_from_header_file "${SUB_LINK_HASH:0:4}" 2>/dev/null)" || SUB_DOWNLOAD_FILENAME=""
	if [ "${SUB_PAYLOAD_KIND}" = "clash-yaml" ] && [ -n "${SUB_DOWNLOAD_FILENAME}" ];then
		FILE_MAPPED_GROUP="$(sub_conf_lookup_clash_prefix_airport_label "${SUB_DOWNLOAD_FILENAME}" 2>/dev/null)"
	fi
	local decoded_hash="${SUB_LINK_HASH:0:4}"
	local source_hash="${SUB_SOURCE_TAG}"
	local decoded_file="${DIR}/sub_file_decode_${decoded_hash}.txt"
	sub_prepare_decoded_file "${decoded_hash}" || return 1
	if sub_raw_cache_same_as_current "${SUB_LINK_HASH}" "${source_hash}" "${decoded_file}";then
		sub_restore_from_parsed_cache "${SUB_LINK_HASH}" "${source_hash}" "${sub_count}" "${SUB_PAYLOAD_KIND}" "${decoded_file}" && return 0
	fi
	echo_date "🔍开始解析节点信息..."
	local NODE_NU_RAW="0"
	local NODE_NU_SS="0"
	local NODE_NU_SR="0"
	local NODE_NU_VM="0"
	local NODE_NU_VL="0"
	local NODE_NU_TJ="0"
	local NODE_NU_H2="0"
	local NODE_NU_TC="0"
	local NODE_NU_NV="0"
	local pkg_type=$(dbus get ss_basic_pkg_type)
	[ -n "${pkg_type}" ] || pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local NODE_NU_TT="0"

	# 12. 开始解析并写入节点
	local ONLINE_PARSED_FILE="${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
	local PARSED_BY_SUB_TOOL="0"
	if pick_sub_tool >/dev/null 2>&1;then
		echo_date "🧩检测到sub-tool，尝试使用新解析器..."
		if sub_try_parse_uri_lines_with_tool "${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt" "${ONLINE_PARSED_FILE}" "${DOMAIN_MAPPED_GROUP}" "${SUB_SOURCE_TAG}" "${pkg_type}";then
			PARSED_BY_SUB_TOOL="1"
			read NODE_NU_RAW NODE_NU_SS NODE_NU_SR NODE_NU_VM NODE_NU_VL NODE_NU_TJ NODE_NU_H2 NODE_NU_TC NODE_NU_NV NODE_NU_TT <<-EOF
			$(sub_collect_protocol_counts_from_summary "${SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT}" "${pkg_type}")
			EOF
			if [ "${NODE_NU_TT}" = "0" ] && [ "${NODE_NU_RAW}" = "0" ];then
				echo_date "⚠️订阅中不包含任何ss/ssr/vmess/vless/trojan/hysteria2/tuic/naive节点，退出！"
				return 1
			fi
			if [ -f "${SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT}" ];then
				sub_log_fancyss_parse_summary_json "${SUB_TOOL_PARSE_SUMMARY_FILE_CURRENT}" || sub_log_protocol_counts "${NODE_NU_RAW}" "${NODE_NU_SS}" "${NODE_NU_SR}" "${NODE_NU_VM}" "${NODE_NU_VL}" "${NODE_NU_TJ}" "${NODE_NU_H2}" "${NODE_NU_TC}" "${NODE_NU_NV}" "${NODE_NU_TT}" "${pkg_type}" || return 1
			else
				sub_log_protocol_counts "${NODE_NU_RAW}" "${NODE_NU_SS}" "${NODE_NU_SR}" "${NODE_NU_VM}" "${NODE_NU_VL}" "${NODE_NU_TJ}" "${NODE_NU_H2}" "${NODE_NU_TC}" "${NODE_NU_NV}" "${NODE_NU_TT}" "${pkg_type}" || return 1
			fi
			sub_log_unsupported_scheme_summary "${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt"
			echo_date "-------------------------------------------------------------------"
			sub_log_fancyss_parse_nodes "${ONLINE_PARSED_FILE}"
			echo_date "🧩sub-tool解析完成。"
		else
			echo_date "⚠️sub-tool解析失败，回退旧订阅解析器。"
			rm -f "${ONLINE_PARSED_FILE}" >/dev/null 2>&1
		fi
	fi
	if [ "${PARSED_BY_SUB_TOOL}" != "1" ];then
		read NODE_NU_RAW NODE_NU_SS NODE_NU_SR NODE_NU_VM NODE_NU_VL NODE_NU_TJ NODE_NU_H2 NODE_NU_TC NODE_NU_NV NODE_NU_TT <<-EOF
		$(sub_collect_protocol_counts_from_decoded_file "${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt" "${pkg_type}")
		EOF
		if [ "${NODE_NU_TT}" = "0" ] && [ "${NODE_NU_RAW}" = "0" ];then
			echo_date "⚠️订阅中不包含任何ss/ssr/vmess/vless/trojan/hysteria2/tuic/naive节点，退出！"
			return 1
		fi
		sub_log_protocol_counts "${NODE_NU_RAW}" "${NODE_NU_SS}" "${NODE_NU_SR}" "${NODE_NU_VM}" "${NODE_NU_VL}" "${NODE_NU_TJ}" "${NODE_NU_H2}" "${NODE_NU_TC}" "${NODE_NU_NV}" "${NODE_NU_TT}" "${pkg_type}" || return 1
		sub_log_unsupported_scheme_summary "${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt"
		echo_date "-------------------------------------------------------------------"
		while IFS= read -r node || [ -n "${node}" ]; do
			local node_type=$(sub_uri_scheme "${node}")
			local node_info=$(sub_uri_body "${node}")
			case ${node_type} in
			ss)
				add_ss_node "${node_info}" 1
				;;
			ssr)
				add_ssr_node "${node_info}" 1
				;;
			vmess)
				local _match=$(echo "${node_info}" | grep -E "@|\?|type")
				if [ -n "${_match}" ];then
					#明文的vmess链接
					add_vless_node "${node_info}" 1 vmess
				else
					#base64的vmess链接
					add_vmess_node "${node_info}" 1
				fi
				;;
			vless)
				add_vless_node "${node_info}" 1 vless
				;;
			trojan)
				add_trojan_node "${node_info}" 1
				;;
			hysteria2|hy2)
				add_hy2_node "${node_info}" 1
				;;
			tuic)
				if [ "${pkg_type}" == "full" ];then
					add_tuic_node "${node_info}" 1
				else
					echo_date "⛔当前为lite版本，跳过tuic节点！"
				fi
				;;
			naive+https|naive+quic)
				if [ "${pkg_type}" == "full" ];then
					add_naive_node "${node_type}" "${node_info}" 1
				else
					echo_date "⛔当前为lite版本，跳过Naïve节点！"
				fi
				;;
			*)
				if [ -n "${node_type}" ];then
					sub_log_unsupported_scheme_once "${node_type}"
				fi
				continue
				;;
			esac
		done < ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt
	fi
	echo_date "-------------------------------------------------------------------"
	local ONLINE_GROUP=$(sub_resolve_online_group_label "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${DOMAIN_NAME}" "${SUB_PAYLOAD_KIND}" "${SUB_DOWNLOAD_FILENAME}")
	SUB_LAST_ONLINE_GROUP="${ONLINE_GROUP}"
	local RAW_ONLINE_GROUP=$(get_group_label_from_file "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${DOMAIN_NAME}")
	if [ -n "${ONLINE_GROUP}" ] && [ "${ONLINE_GROUP}" != "${RAW_ONLINE_GROUP}" ];then
		sub_rewrite_group_label_for_file "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${ONLINE_GROUP}" "${SUB_SOURCE_TAG}" >/dev/null 2>&1 || true
	fi
	CANONICAL_SOURCE_TAG=$(sub_canonicalize_online_source "${sub_count}" "${SUB_SOURCE_TAG}" "${ONLINE_GROUP}" 2>/dev/null)
	[ -n "${CANONICAL_SOURCE_TAG}" ] || CANONICAL_SOURCE_TAG="${SUB_SOURCE_TAG}"
	if [ "${CANONICAL_SOURCE_TAG}" != "${SUB_SOURCE_TAG}" ];then
		echo_date "♻️检测到订阅域名已变更，但机场分组保持为【${ONLINE_GROUP}】，沿用原机场身份处理。"
		SUB_SOURCE_TAG="${CANONICAL_SOURCE_TAG}"
	fi
	SUB_AIRPORT_IDENTITY=$(sub_build_airport_identity "${ONLINE_GROUP}" "${SUB_SOURCE_TAG}")
	SUB_SOURCE_SCOPE=$(sub_build_source_scope "${SUB_AIRPORT_IDENTITY}" "${SUB_SOURCE_URL_HASH}")
	sub_rewrite_identity_fields_for_file "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${ONLINE_GROUP}" "${SUB_SOURCE_TAG}" "${SUB_SOURCE_URL_HASH}" "subscribe" >/dev/null 2>&1 || true
	sub_register_source_identity "${RAW_SOURCE_TAG}" "${SUB_SOURCE_TAG}" "${ONLINE_GROUP}" >/dev/null 2>&1
	if [ -s "${ACTIVE_SOURCE_TAGS}" ] && grep -Fxq "${SUB_SOURCE_TAG}" "${ACTIVE_SOURCE_TAGS}";then
		echo_date "⚠️检测到多个订阅链接属于同一机场【${ONLINE_GROUP}】，本次仅保留第一个来源。"
		rm -f "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
		return 0
	fi
	sub_mark_active_source_tag "${SUB_SOURCE_TAG}"
	sub_refresh_airport_special_conf "${SUB_AIRPORT_IDENTITY}" "${ONLINE_GROUP}" "${SUB_PAYLOAD_KIND}" "${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt"
	if [ -f "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" ];then
		echo_date "ℹ️在线节点解析完毕，开始将订阅节点和和本地节点进行对比！"
	else
		echo_date "ℹ️在线节点解析失败！跳过此订阅！"
	fi

	# 14. print INFO
	local md5_new=$(sub_nodes_file_md5 ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt)
	echo_date "🌎订阅节点信息："
	echo_date "🔷当前订阅来源【${ONLINE_GROUP}】，共有节点${NODE_NU_TT}个。"
	if [ "${exclude}" != "0" ];then
		echo_date "🔷其中：因关键词匹配排除节点${exclude}个，最终获得有效节点$((${NODE_NU_TT} - ${exclude}))个"
	fi
	echo_date "🔷订阅节点校验：${md5_new}"
	echo_date "💾本地节点信息："
	local ISLOCALFILE=$(sub_find_local_source_file "${SUB_SOURCE_TAG}" 2>/dev/null)
	if [ -n "${ISLOCALFILE}" ];then
		local md5_loc=$(sub_nodes_file_md5 "${ISLOCALFILE}")
		local LOCAL_GROUP=$(get_group_label_from_file "${ISLOCALFILE}" "${DOMAIN_NAME}")
		local LOCAL_NODES=$(cat "${ISLOCALFILE}" | wc -l)
		echo_date "🔶当前订阅来源【${LOCAL_GROUP}】，在本地已有节点${LOCAL_NODES}个。"
		echo_date "🔶本地节点校验：${md5_loc}"
		if [ "${md5_loc}" == "${md5_new}" ];then
			echo_date "🆚对比结果：本地节点已经是最新，跳过！"
			rm -rf "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
			sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
			sub_update_parsed_cache "${SUB_LINK_HASH}" "${ISLOCALFILE}"
		else
			sub_log_nodes_file_change_reason "${ISLOCALFILE}" "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
			if [ -n "${SUB_TOOL_DIFF_FILE_CURRENT}" ] && [ -f "${SUB_TOOL_DIFF_FILE_CURRENT}" ];then
				sub_log_nodes_diff_tsv_file "${SUB_TOOL_DIFF_FILE_CURRENT}" "${SUB_TOOL_DIFF_SUMMARY_FILE_CURRENT}"
			else
				sub_log_nodes_file_change_detail "${ISLOCALFILE}" "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
			fi
			echo_date "🆚对比结果：检测到节点发生变更，生成节点更新文件！"
			# 将订阅后的文件覆盖为本地同 source tag 文件，直接移动可减少一次复制 IO。
			mv -f "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt" || {
				echo_date "⚠️更新本地订阅节点文件失败：${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt -> ${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
				return 1
			}
			sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
			sub_update_parsed_cache "${SUB_LINK_HASH}" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
			sub_mark_changed_source_tag "${SUB_SOURCE_TAG}"
			SUB_LOCAL_CHANGED=1
		fi
		return 0
	else
		echo_date "🔶当前订阅链来源【${ONLINE_GROUP}】在本地尚无节点！"
		echo_date "🆚对比结果：检测到新的订阅节点，生成节点添加文件！"
		# 将订阅后的文件落地为本地 source tag 文件，直接移动减少复制开销。
		mv -f "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt" || {
			echo_date "⚠️写入本地订阅节点文件失败：${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt -> ${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
			return 1
		}
		sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
		sub_update_parsed_cache "${SUB_LINK_HASH}" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
		sub_mark_changed_source_tag "${SUB_SOURCE_TAG}"
		SUB_LOCAL_CHANGED=1
		return 0
	fi
}

exit_sub(){
	echo_date "==================================================================="
	exit 1
}

start_node_subscribe(){
	local online_url_nu online_urls active_hash_file profiles_file use_profiles=0 selected_profile_id="" enabled_profile_count=0
	echo_date "==================================================================="
	echo_date "                服务器订阅程序(Shell by stones & sadog)"
	echo_date "==================================================================="
	if [ "${SUB_SCHEMA2_NATIVE_INITIALIZED}" = "1" ];then
		echo_date "ℹ️未检测到旧版节点数据，已启用 schema 2 原生节点存储。"
	fi

	# run some test before anything start
	# echo_date "⚙️test: 脚本环境变量：$(env | wc -l)个"
	
	# 0. var define
	sub_refresh_node_state
	sub_reset_active_profile_context
	selected_profile_id="${SUB_SELECTED_PROFILE_ID:-$(dbus get ${SUB_PROFILE_TMP_SYNC_ID_KEY})}"
	SUB_SINGLE_PROFILE_SYNC=0
	profiles_file="${DIR}/active_profiles.tsv"
	enabled_profile_count="$(subprof_enabled_profile_count 2>/dev/null)"
	if [ -n "${enabled_profile_count}" ] && [ "${enabled_profile_count}" -gt "0" ] 2>/dev/null; then
		use_profiles=1
		online_url_nu="${enabled_profile_count}"
	else
		online_urls=$(sub_get_online_urls)
		online_url_nu=$(printf '%s\n' "${online_urls}" | sed '/^$/d' | wc -l)
	fi

	# 1. 检查订阅链接是否有效
	if [ "${use_profiles}" = "0" ] && [ -n "${selected_profile_id}" ]; then
		echo_date "⚠️未找到可同步的订阅配置：${selected_profile_id}"
		echo_date "==================================================================="
		return 1
	fi
	if [ "${use_profiles}" = "0" ] && [ -z "$(dbus get ss_online_links)" ];then
		echo_date "🈳订阅地址输入框为空，准备清理现有订阅节点..."
		remove_sub_node
		fss_refresh_node_direct_cache >/dev/null 2>&1
		sub_clear_subscribe_cache
		echo_date "🎉订阅节点清理完成！"
		echo_date "==================================================================="
		return 0
	fi
	if [ "${use_profiles}" = "0" ]; then
		online_urls=$(sub_get_online_urls)
		online_url_nu=$(printf '%s\n' "${online_urls}" | sed '/^$/d' | wc -l)
	fi
	if [ "${online_url_nu}" == "0" ];then
		if [ "${use_profiles}" = "1" ]; then
			echo_date "🈳未发现任何启用中的订阅配置，跳过本次订阅。"
		else
			echo_date "🈳未发现任何有效的订阅地址，准备清理现有订阅节点..."
			remove_sub_node
			fss_refresh_node_direct_cache >/dev/null 2>&1
			sub_clear_subscribe_cache
			echo_date "🎉订阅节点清理完成！"
		fi
		echo_date "==================================================================="
		return 0
	fi
	echo_date "✈️开始订阅！"
	SUB_LOCAL_CHANGED=0
	SUB_HAS_FAILURE=0
	SUB_AIRPORT_SPECIAL_CHANGED=0

	# 2. 创建临时文件夹，用于存放订阅过程中的临时文件
	mkdir -p $DIR
	rm -rf $DIR/*
	sub_reset_schema2_cache
	: > "${ACTIVE_SOURCE_TAGS}"
	active_hash_file="${DIR}/active_link_hashes.txt"
	if [ "${use_profiles}" = "1" ]; then
		sub_prepare_enabled_profiles_file "${profiles_file}" || {
			echo_date "⚠️生成订阅配置执行清单失败，终止本次订阅。"
			return 1
		}
		online_url_nu=$(awk 'NF{c++} END{print c+0}' "${profiles_file}")
		[ -n "${selected_profile_id}" ] && SUB_SINGLE_PROFILE_SYNC=1
		sub_collect_active_link_hashes_from_profiles_file "${active_hash_file}" "${profiles_file}"
	else
		sub_collect_active_link_hashes "${active_hash_file}" "${online_urls}"
	fi
	if [ "${SUB_SINGLE_PROFILE_SYNC}" != "1" ]; then
		sub_prune_subscribe_cache "${active_hash_file}"
	fi

	# 3.订阅前检查节点是否储存正常，不需要了
	# check_nodes

	# 4. skipd节点数据储存到文件
	skipdb2json

	# 4. 储存的节点文件，按照不通机场拆分
	nodes2files

	# 5. 用拆分文件统计节点
	nodes_stats
	
	# 6. 下载/解析订阅节点
	sub_count=0
	if [ "${use_profiles}" = "1" ]; then
		local profile_line=""
		while IFS= read -r profile_line
		do
			[ -n "${profile_line}" ] || continue
			profile_id="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $1}')"
			profile_name="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $2}')"
			url="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $3}')"
			subscribe_mode="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $4}')"
			download_policy="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $5}')"
			ua_mode="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $6}')"
			ua_preset="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $7}')"
			ua_custom="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $8}')"
			exclude_raw="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $9}')"
			include_raw="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $10}')"
			allow_insecure="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $11}')"
			node_log="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $12}')"
			keep_info_node="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $13}')"
			hy2_up="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $14}')"
			hy2_dl="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $15}')"
			hy2_tfo_switch="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $16}')"
			hy2_cg_opt="$(printf '%s\n' "${profile_line}" | awk -F '\t' '{print $17}')"
			[ -n "${url}" ] || continue
			let sub_count+=1
			sub_reset_active_profile_context
			sub_apply_active_profile_context "${profile_id}" "${profile_name}" "${subscribe_mode}" "${download_policy}" "${ua_mode}" "${ua_preset}" "${ua_custom}" "${exclude_raw}" "${include_raw}" "${allow_insecure}" "${node_log}" "${keep_info_node}" "${hy2_up}" "${hy2_dl}" "${hy2_tfo_switch}" "${hy2_cg_opt}"
			SUB_LAST_ONLINE_GROUP=""
			SUB_LAST_URL_HASH=""
			echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
			[ "${online_url_nu}" -gt "1" ] && echo_date "📢开始第【${sub_count}】个订阅配置：【${profile_name}】"
			[ "${online_url_nu}" -eq "1" ] && echo_date "📢开始同步订阅配置：【${profile_name}】"
			echo_date "🌎${url}"
			exclude=0
			get_online_rule_now "${url}"
			case $? in
			0)
				subprof_mark_state_success "${profile_id}" "${SUB_LAST_URL_HASH}" "${SUB_LAST_ONLINE_GROUP}" "${SUB_LAST_DOWNLOAD_TOOL}" "${SUB_LAST_DOWNLOAD_PATH}" "${SUB_ACTIVE_UA_MODE}" "${SUB_ACTIVE_UA_PRESET}" >/dev/null 2>&1 || true
				continue
				;;
			*)
				SUB_HAS_FAILURE=1
				subprof_mark_state_failure "${profile_id}" "${SUB_LAST_DOWNLOAD_ERROR:-订阅处理失败}" "${SUB_LAST_URL_HASH}" "${SUB_LAST_ONLINE_GROUP}" "${SUB_LAST_DOWNLOAD_TOOL}" "${SUB_LAST_DOWNLOAD_PATH}" "${SUB_ACTIVE_UA_MODE}" "${SUB_ACTIVE_UA_PRESET}" >/dev/null 2>&1 || true
				subscribe_failed
				;;
			esac
		done < "${profiles_file}"
	else
		until [ "${sub_count}" == "${online_url_nu}" ]; do
			let sub_count+=1
			url=$(printf '%s\n' "${online_urls}" | sed -n "${sub_count}p")
			[ -z "${url}" ] && continue
			echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
			[ "${online_url_nu}" -gt "1" ] && echo_date "📢开始第【${sub_count}】个订阅！订阅链接如下："
			[ "${online_url_nu}" -eq "1" ] && echo_date "📢开始订阅！订阅链接如下："
			echo_date "🌎${url}"
			exclude=0
			get_online_rule_now "${url}"
			case $? in
			0)
				continue
				;;
			*)
				SUB_HAS_FAILURE=1
				subscribe_failed
				;;
			esac
		done
	fi
	echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
	if [ "${SUB_HAS_FAILURE}" = "1" ];then
		echo_date "⚠️本次订阅存在失败任务，跳过过期订阅来源清理，保留现有本地订阅节点。"
	else
		if [ "${SUB_SINGLE_PROFILE_SYNC}" = "1" ]; then
			echo_date "ℹ️当前为单订阅配置同步，跳过其它订阅来源的清理与缓存裁剪。"
		else
			echo_date "ℹ️订阅来源处理完毕，开始整理本次变更并清理失效来源..."
			remove_null
			sub_prune_source_identity "${ACTIVE_SOURCE_TAGS}"
		fi
	fi

	# 5. 写入所有节点
	if [ "${SUB_LOCAL_CHANGED}" != "1" ];then
		echo_date "ℹ️本次订阅没有任何节点发生变化，不进行写入，继续！"
		sub_refresh_runtime_dns_after_airport_special_change
		echo_date "🧹一点点清理工作..."
		echo_date "🎉所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
		echo_date "==================================================================="
		return 0
	fi
	local ISNEW=$(find $DIR -name "local_*_*.txt")
	if [ -n "${ISNEW}" ];then
		echo_date "ℹ️正在评估本次写入方式..."
		if [ "${SUB_STORAGE_SCHEMA}" = "2" ] && sub_try_sync_single_source_fast_path;then
			return 0
		fi
		echo_date "🧭未命中单来源快路径，回退全量写入流程..."
		find $DIR -name "local_*.txt" | sort -n | xargs cat >$DIR/ss_nodes_new.txt
		local md5sum_old=$(sub_nodes_file_md5 ${LOCAL_NODES_BAK})
		local md5sum_new=$(sub_nodes_file_md5 $DIR/ss_nodes_new.txt)
		if [ "${md5sum_new}" != "${md5sum_old}" ];then
			if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
				if ! sub_validate_jsonl_file "$DIR/ss_nodes_new.txt"; then
					echo_date "❌节点写入文件校验失败，已终止本次订阅，原有节点保持不变！"
					exit_sub
				fi
				SUB_FAST_APPEND_USED=0
				if sub_can_fast_append_schema2 "$DIR/ss_nodes_new.txt";then
					SUB_FAST_APPEND=1
				else
					SUB_FAST_APPEND=0
				fi
			fi
			clear_nodes
			echo_date "ℹ️开始写入节点..."
			if ! json2skipd "ss_nodes_new"; then
				echo_date "❌节点信息写入失败！"
				exit_sub
			fi
			sub_after_nodes_written "$DIR/ss_nodes_new.txt"
		else
			echo_date "ℹ️本次订阅没有任何节点发生变化，不进行写入，继续！"
		fi
		cp -f "$DIR/ss_nodes_new.txt" "${LOCAL_NODES_BAK}"
		echo_date "🧹一点点清理工作..."
		echo_date "🎉所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	else
		echo_date "⚠️出错！未找到节点写入文件！"
		echo_date "⚠️退出订阅！"
	fi
	echo_date "==================================================================="
}

subscribe_failed(){
	# 当订阅失败后，在这里进行一些处理...
	rm -rf ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt >/dev/null 2>&1
	#echo ""
}

# 添加ss:// ssr:// vmess:// vless:// trojan:// hysteria2:// hy2:// tuic:// naive+https:// naive+quic://离线节点
start_offline_update() {
	echo_date "==================================================================="
	echo_date "ℹ️通过ss/ssr/vmess/vless/trojan/hysteria2/tuic/naive链接添加节点..."
	mkdir -p $DIR
	rm -rf $DIR/*
	UNSUPPORTED_PROTO_LOG_FILE="${DIR}/unsupported_proto_offline.txt"
	local nodes=$(dbus get ss_base64_links | base64 -d | urldecode)
	local pkg_type=$(dbus get ss_basic_pkg_type)
	[ -n "${pkg_type}" ] || pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	for node in $nodes
	do
		local node_type=$(sub_uri_scheme "${node}")
		local node_info=$(sub_uri_body "${node}")
		case $node_type in
		ss)
			add_ss_node "${node_info}" 2
			;;
		ssr)
			add_ssr_node "${node_info}" 2
			;;
		vmess)
			local _match=$(echo "${node_info}" | grep -E "@|\?|type")
			if [ -n "${_match}" ];then
				#明文的vmess链接
				add_vless_node "${node_info}" 2 vmess
			else
				#base64的vmess链接
				add_vmess_node "${node_info}" 2
			fi
			;;
		vless)
			add_vless_node "${node_info}" 2 vless
			;;
		trojan)
			add_trojan_node "${node_info}" 2
			;;
		hysteria2|hy2)
			add_hy2_node "${node_info}" 2
			;;
		tuic)
			if [ "${pkg_type}" == "full" ];then
				add_tuic_node "${node_info}" 2
			else
				echo_date "⚠️当前为lite版本，跳过tuic离线节点。"
			fi
			;;
		naive+https|naive+quic)
			if [ "${pkg_type}" == "full" ];then
				add_naive_node "${node_type}" "${node_info}" 2
			else
				echo_date "⚠️当前为lite版本，跳过Naïve离线节点。"
			fi
			;;
		*)
			sub_log_unsupported_scheme_once "${node_type}"
			continue
			;;
		esac
	done
	dbus remove ss_base64_links
	echo_date "-------------------------------------------------------------------"
	if [ -f "${DIR}/offline_node_new.txt" ];then
		sub_filter_offline_duplicate_nodes "${DIR}/offline_node_new.txt"
		[ -f "${DIR}/offline_node_new.txt" ] && echo_date "ℹ️离线节点解析完毕，开始写入节点..."
		SUB_FAST_APPEND=1
		SUB_FAST_APPEND_REUSE=0
		if [ -f "${DIR}/offline_node_new.txt" ] && json2skipd "offline_node_new"; then
			sub_after_nodes_written "${DIR}/offline_node_new.txt"
		fi
	else
		echo_date "ℹ️离线节点解析失败！跳过！"
	fi

	
	echo_date "==================================================================="
}

SUB_SELECTED_PROFILE_ID=""
if [ "$1" = "3" ] && [ -n "$2" ]; then
	SUB_SELECTED_PROFILE_ID="$2"
	SH_ARG="$1"
	WEB_ACTION=0
elif [ -z "$2" -a -n "$1" ];then
	SH_ARG=$1
	WEB_ACTION=0
elif [ -n "$2" -a -n "$1" ];then
	SH_ARG=$2
	[ "$2" = "3" ] && [ -n "$3" ] && SUB_SELECTED_PROFILE_ID="$3"
	WEB_ACTION=1
fi

case $SH_ARG in
0)
	# 删除所有节点
	set_lock
	true > $LOG_FILE
	[ "${WEB_ACTION}" == "1" ] && http_response "$1"
	remove_all_node | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
1)
	# 删除所有订阅节点
	set_lock
	true > $LOG_FILE
	[ "${WEB_ACTION}" == "1" ] && http_response "$1"
	remove_sub_node | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
2)
	# 保存订阅设置但是不订阅
	set_lock
	true > $LOG_FILE
	[ "${WEB_ACTION}" == "1" ] && http_response "$1"
	local_groups=$(sub_count_unique_groups)
	online_group=$(dbus get ss_online_links | base64 -d | awk '{print $1}' | sed '/^$/d' | sed '/^#/d' | sed 's/^[[:space:]]//g' | sed 's/[[:space:]]$//g' | grep -Ec "^http")
	echo_date "保存订阅节点成功！" | tee -a $LOG_FILE
	echo_date "现共有 $online_group 组订阅来源" | tee -a $LOG_FILE
	echo_date "当前节点列表内已经订阅了 $local_groups 组..." | tee -a $LOG_FILE
	sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	if [ "$(dbus get ss_basic_node_update)" = "1" ]; then
		if [ "$(dbus get ss_basic_node_update_day)" = "7" ]; then
			cru a ssnodeupdate "0 $(dbus get ss_basic_node_update_hr) * * * /koolshare/scripts/ss_node_subscribe.sh fancyss 3"
			echo_date "设置自动更新订阅服务在每天 $(dbus get ss_basic_node_update_hr) 点。" | tee -a $LOG_FILE
		else
			cru a ssnodeupdate "0 $(dbus get ss_basic_node_update_hr) * * $(dbus get ss_basic_node_update_day) /koolshare/scripts/ss_node_subscribe.sh fancyss 3"
			echo_date "设置自动更新订阅服务在星期 $(dbus get ss_basic_node_update_day) 的 $(dbus get ss_basic_node_update_hr) 点。" | tee -a $LOG_FILE
		fi
	else
		echo_date "关闭自动更新订阅服务！" | tee -a $LOG_FILE
		sed -i '/ssnodeupdate/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
3)
	# 使用订阅链接订阅ss/ssr/V2ray节点
	set_lock
	true > $LOG_FILE
	[ "${WEB_ACTION}" == "1" ] && http_response "$1"
	start_node_subscribe | tee -a $LOG_FILE
	[ -z "${SUB_SELECTED_PROFILE_ID}" ] && dbus remove ${SUB_PROFILE_TMP_SYNC_ID_KEY} >/dev/null 2>&1 || true
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
4)
	# 添加ss:// ssr:// vmess://离线节点
	set_lock
	true > $LOG_FILE
	[ "${WEB_ACTION}" == "1" ] && http_response "$1"
	start_offline_update | tee -a $LOG_FILE
	echo XU6J03M6 | tee -a $LOG_FILE
	unset_lock
	;;
esac
