#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center
source /koolshare/scripts/base.sh
source /koolshare/scripts/ss_node_common.sh
NEW_PATH=$(echo $PATH|tr ':' '\n'|sed '/opt/d;/mmc/d'|awk '!a[$0]++'|tr '\n' ':'|sed '$ s/:$//')
export PATH=${NEW_PATH}
LC_ALL=C
LANG=C
LOCK_FILE=/var/lock/node_subscribe.lock
LOG_FILE=/tmp/upload/ss_log.txt
DIR="/tmp/fancyss_subs"
LOCAL_NODES_SPL="$DIR/ss_nodes_spl.txt"
LOCAL_NODES_BAK="$DIR/ss_nodes_bak.txt"
LOCAL_SPLIT_META="$DIR/local_split_meta.tsv"
ACTIVE_SOURCE_TAGS="$DIR/active_source_tags.txt"
SCHEMA2_RAW_JSONL="$DIR/schema2_nodes_raw.txt"
SCHEMA2_EXPORT_JSONL="$DIR/schema2_nodes_export.txt"
SUB_RAW_CACHE_DIR="/koolshare/configs/fancyss/subscribe_cache/raw"
SUB_PARSED_CACHE_DIR="/koolshare/configs/fancyss/subscribe_cache/parsed"
# 订阅缓存的 raw / parsed / meta 都放在持久化目录。
# 每次调整 meta 结构或比对语义时，只需要递增 schema，
# 下次订阅就会自动判定旧 meta 失效并重建缓存。
SUB_PARSED_CACHE_META_SCHEMA="2"
SUB_STORAGE_SCHEMA=$(dbus get fss_data_schema)
[ "${SUB_STORAGE_SCHEMA}" = "2" ] || SUB_STORAGE_SCHEMA="1"
NODES_SEQ=""
NODE_INDEX=""
SEQ_NU="0"
SUB_MODE=$(dbus get ssr_subscribe_mode)
[ -z "${SUB_MODE}" ] && SUB_MODE=2
HY2_UP_SPEED=$(dbus get ss_basic_hy2_up_speed)
HY2_DL_SPEED=$(dbus get ss_basic_hy2_dl_speed)
HY2_TFO_SWITCH=$(dbus get ss_basic_hy2_tfo_switch)
CURR_NODE=""
FAILOVER_NODE=""
CURR_NODE_NAME=""
CURR_NODE_TYPE=""
CURR_NODE_SERVER=""
CURR_NODE_PORT=""
FAILOVER_NODE_NAME=""
FAILOVER_NODE_TYPE=""
FAILOVER_NODE_SERVER=""
FAILOVER_NODE_PORT=""
SUB_REWRITE_ALL=0
SUB_LOCAL_CHANGED=0
SUB_HAS_FAILURE=0
SUB_BY_PROXY=$(dbus get ss_basic_online_links_proxy)
SUB_AI=$(dbus get ss_basic_sub_ai)
[ -z "${SUB_BY_PROXY}" ] && SUB_BY_PROXY=0
KEY_WORDS_1=$(dbus get ss_basic_exclude | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_2=$(dbus get ss_basic_include | sed 's/,$//g' | sed 's/,/|/g')
KEY_WORDS_1_RAW=$(dbus get ss_basic_exclude | sed 's/,$//g')
KEY_WORDS_2_RAW=$(dbus get ss_basic_include | sed 's/,$//g')
SUB_ONLINE_URLS=""
SUB_ONLINE_URLS_READY=0
SUB_VERBOSE_NODE_LOG=1
LOCAL_SPLIT_META_VALID=0
alias urldecode='sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"'

# 20230701, some vairiable should be unset
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
		printf '%s' "$(dbus get fss_node_order)" | tr ',' '\n' | sed '/^$/d'
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

sub_get_online_url_count(){
	sub_get_online_urls | wc -l
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

sub_get_legacy_tag_from_url(){
	local sub_url="$1"
	[ -n "${sub_url}" ] || return 1
	sub_url=$(echo "${sub_url}" | sed 's/%20/ /g')
	printf '%s' "${sub_url}" | md5sum | awk '{print substr($1, 1, 4)}'
}

sub_reset_schema2_cache(){
	rm -f "${SCHEMA2_RAW_JSONL}" "${SCHEMA2_EXPORT_JSONL}"
}

sub_mark_active_source_tag(){
	local source_tag="$1"
	[ -n "${source_tag}" ] || return 1
	mkdir -p "${DIR}" >/dev/null 2>&1
	touch "${ACTIVE_SOURCE_TAGS}"
	grep -Fxq "${source_tag}" "${ACTIVE_SOURCE_TAGS}" 2>/dev/null || echo "${source_tag}" >> "${ACTIVE_SOURCE_TAGS}"
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
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "$(dbus get ss_basic_hy2_cg_opt)")
	EOF
	printf '%s\n' \
		"exclude=${KEY_WORDS_1_RAW}" \
		"include=${KEY_WORDS_2_RAW}" \
		"sub_mode=${SUB_MODE}" \
		"sub_ai=${effective_sub_ai}" \
		"hy2_up=${effective_hy2_up}" \
		"hy2_dl=${effective_hy2_dl}" \
		"hy2_tfo_switch=${effective_hy2_tfo}" \
		"hy2_cg_opt=${effective_hy2_cg}" \
		| md5sum | awk '{print $1}'
}

sub_update_parsed_cache_meta(){
	local sub_hash="$1"
	local parsed_file="$2"
	local meta_file filter_sig effective_sub_ai effective_hy2_up effective_hy2_dl effective_hy2_tfo effective_hy2_cg
	local has_ai_sensitive has_hy2_sensitive
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
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "$(dbus get ss_basic_hy2_cg_opt)")
	EOF
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
	hy2_up=${effective_hy2_up}
	hy2_dl=${effective_hy2_dl}
	hy2_tfo_switch=${effective_hy2_tfo}
	hy2_cg_opt=${effective_hy2_cg}
	has_ai_sensitive=${has_ai_sensitive}
	has_hy2_sensitive=${has_hy2_sensitive}
	EOF
}

sub_parsed_cache_meta_matches(){
	local sub_hash="$1"
	local meta_file cached_schema cached_exclude cached_include cached_sub_mode cached_sub_ai
	local cached_hy2_up cached_hy2_dl cached_hy2_tfo cached_hy2_cg has_ai_sensitive has_hy2_sensitive
	local current_sub_ai current_hy2_up current_hy2_dl current_hy2_tfo current_hy2_cg
	[ -n "${sub_hash}" ] || return 1
	meta_file=$(sub_get_parsed_cache_meta_file "${sub_hash}") || return 1
	[ -f "${meta_file}" ] || return 1
	cached_schema=$(sed -n 's/^schema_version=//p' "${meta_file}" | sed -n '1p')
	cached_exclude=$(sed -n 's/^exclude_keywords=//p' "${meta_file}" | sed -n '1p')
	cached_include=$(sed -n 's/^include_keywords=//p' "${meta_file}" | sed -n '1p')
	cached_sub_mode=$(sed -n 's/^sub_mode=//p' "${meta_file}" | sed -n '1p')
	cached_sub_ai=$(sed -n 's/^sub_ai=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_up=$(sed -n 's/^hy2_up=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_dl=$(sed -n 's/^hy2_dl=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_tfo=$(sed -n 's/^hy2_tfo_switch=//p' "${meta_file}" | sed -n '1p')
	cached_hy2_cg=$(sed -n 's/^hy2_cg_opt=//p' "${meta_file}" | sed -n '1p')
	has_ai_sensitive=$(sed -n 's/^has_ai_sensitive=//p' "${meta_file}" | sed -n '1p')
	has_hy2_sensitive=$(sed -n 's/^has_hy2_sensitive=//p' "${meta_file}" | sed -n '1p')
	current_sub_ai=$(sub_get_effective_sub_ai "${SUB_AI}")
	{
		read -r current_hy2_up
		read -r current_hy2_dl
		read -r current_hy2_tfo
		read -r current_hy2_cg
	} <<-EOF
	$(sub_get_effective_hy2_context "${HY2_UP_SPEED}" "${HY2_DL_SPEED}" "${HY2_TFO_SWITCH}" "$(dbus get ss_basic_hy2_cg_opt)")
	EOF
	[ "${cached_schema}" = "${SUB_PARSED_CACHE_META_SCHEMA}" ] || return 1
	[ -n "${cached_sub_mode}" ] || return 1
	[ "${cached_exclude}" = "${KEY_WORDS_1_RAW}" ] || return 1
	[ "${cached_include}" = "${KEY_WORDS_2_RAW}" ] || return 1
	[ "${cached_sub_mode}" = "${SUB_MODE}" ] || return 1
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

sub_log_node_success(){
	[ "${SUB_VERBOSE_NODE_LOG}" = "1" ] || return 0
	echo_date "$1"
}

sub_prepare_decoded_file(){
	local short_hash="$1"
	local encoded_file="${DIR}/sub_file_encode_${short_hash}.txt"
	local decoded_file="${DIR}/sub_file_decode_${short_hash}.txt"
	local head_count="0"

	[ -f "${encoded_file}" ] || return 1
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
	local parsed_cache local_file parsed_md5 local_md5

	[ -n "${sub_hash}" ] || return 1
	[ -n "${short_hash}" ] || return 1
	[ -n "${sub_count}" ] || return 1
	parsed_cache=$(sub_get_parsed_cache_file "${sub_hash}") || return 1
	[ -f "${parsed_cache}" ] || return 1
	if ! sub_parsed_cache_meta_matches "${sub_hash}";then
		echo_date "♻️检测到订阅筛选条件或默认参数发生变化，需要重新解析并重写节点。"
		return 1
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
	[ -n "${local_file}" ] && rm -f "${local_file}"
	cp -f "${parsed_cache}" "${DIR}/local_${sub_count}_${short_hash}.txt"
	sub_mark_active_source_tag "${short_hash}"
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
		| del(._schema, ._rev, ._source, ._updated_at, ._migrated_from, .server_ip, .latency, .ping)
	' "${SCHEMA2_RAW_JSONL}" > "${SCHEMA2_EXPORT_JSONL}" || return 1
	return 0
}

sub_extract_groups_from_file(){
	local file_path="$1"
	[ -f "${file_path}" ] || return 0
	jq -r '.group // "null"' "${file_path}" 2>/dev/null
}

sub_refresh_node_state(){
	NODES_SEQ=$(sub_list_node_ids | tr '\n' ' ' | sed 's/[[:space:]]$//')
	NODE_INDEX=$(sub_list_node_ids | sed -n '$p')
	SEQ_NU=$(sub_list_node_ids | sed '/^$/d' | wc -l)
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		CURR_NODE=$(dbus get fss_node_current)
		FAILOVER_NODE=$(dbus get fss_node_failover_backup)
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
	local store_field value=""

	[ -z "${node_id}" ] && return 1
	[ -z "${field}" ] && return 1
	store_field=$(sub_resolve_field_name "${field}")

	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		value=$(fss_v2_get_node_json_by_id "${node_id}" 2>/dev/null | jq -r --arg k "${store_field}" '.[$k] // empty')
	else
		value=$(dbus get ssconf_basic_${store_field}_${node_id})
		if [ -n "${value}" ] && fss_is_b64_field "${store_field}"; then
			value=$(fss_b64_decode "${value}")
		fi
	fi

	printf '%s' "${value}"
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

sub_node_exists_in_order(){
	local node_id="$1"
	[ -z "${node_id}" ] && return 1
	sub_list_node_ids | grep -Fxq "${node_id}"
}

sub_capture_active_nodes(){
	sub_refresh_node_state
	CURR_NODE_NAME=$(sub_get_node_field_plain "${CURR_NODE}" name)
	CURR_NODE_TYPE=$(sub_get_node_field_plain "${CURR_NODE}" type)
	CURR_NODE_SERVER=$(sub_get_node_server_plain "${CURR_NODE}")
	CURR_NODE_PORT=$(sub_get_node_port_plain "${CURR_NODE}")
	FAILOVER_NODE_NAME=$(sub_get_node_field_plain "${FAILOVER_NODE}" name)
	FAILOVER_NODE_TYPE=$(sub_get_node_field_plain "${FAILOVER_NODE}" type)
	FAILOVER_NODE_SERVER=$(sub_get_node_server_plain "${FAILOVER_NODE}")
	FAILOVER_NODE_PORT=$(sub_get_node_port_plain "${FAILOVER_NODE}")
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

sub_export_local_node_json(){
	local node_id="$1"
	[ -z "${node_id}" ] && return 1
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
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
			| del(._schema, ._rev, ._source, ._updated_at, ._migrated_from, .server_ip, .latency, .ping)
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
		| del(._id, ._schema, ._rev, ._source, ._updated_at, ._migrated_from, ._b64_mode, .server_ip, .latency, .ping)
	' "${file}" 2>/dev/null | md5sum | awk '{print $1}'
}

sub_validate_jsonl_file(){
	local file="$1"
	local total=0 valid=0
	[ -f "${file}" ] || return 1
	while IFS= read -r line
	do
		[ -n "${line}" ] || continue
		total=$((total + 1))
		printf '%s\n' "${line}" | jq -c . >/dev/null 2>&1 || {
			echo_date "⚠️检测到无效的节点JSON，第${total}行校验失败！"
			return 1
		}
		valid=$((valid + 1))
	done < "${file}"
	[ "${total}" -gt 0 ] || return 1
	[ "${valid}" = "${total}" ]
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

sub_write_nodes_schema2(){
	local input_file="$1"
	local order_csv next_id max_id reserved_max imported_order="" mapped_file meta_file now_ts
	local node_id stored_b64 export_b64 export_json

	[ -f "${input_file}" ] || return 1
	mapped_file="${input_file}.mapped"
	meta_file="${input_file}.meta"
	: > "${mapped_file}"
	order_csv=$(dbus get fss_node_order)
	next_id=$(dbus get fss_node_next_id)
	[ -n "${next_id}" ] || next_id=1
	max_id=$(printf '%s' "${order_csv}" | tr ',' '\n' | sed '/^$/d' | sort -n | tail -n1)
	[ -n "${max_id}" ] || max_id=0
	reserved_max=$(jq -r '._id // empty' "${input_file}" 2>/dev/null | sed '/^$/d' | sort -n | tail -n1)
	if [ -n "${reserved_max}" ] && [ "${reserved_max}" -gt "${max_id}" ] 2>/dev/null;then
		max_id="${reserved_max}"
	fi
	if [ "${next_id}" -le "${max_id}" ] 2>/dev/null;then
		next_id=$((max_id + 1))
	fi
	now_ts=$(date +%s)
		jq -nr -r -c --argjson next "${next_id}" --argjson ts "${now_ts}" '
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
		reduce inputs as $node (
			{next: $next, rows: []};
			($node | clean) as $clean
			| ($clean._id // "" | tostring) as $raw_id
			| (if ($raw_id | test("^[0-9]+$")) then ($raw_id | tonumber) else .next end) as $id
			| .rows += [[
				($id | tostring),
				(($clean + {
					"_schema": 2,
					"_id": ($id | tostring),
					"_rev": 1,
					"_b64_mode": "raw",
					"_source": "subscribe",
					"_updated_at": $ts
				}) | tojson | @base64),
				($clean | tojson | @base64)
			]]
			| .next = (if ($raw_id | test("^[0-9]+$")) then .next else (.next + 1) end)
		)
		| .rows[]
		| @tsv
	' "${input_file}" > "${meta_file}" 2>/dev/null || {
		rm -f "${mapped_file}" "${meta_file}"
		return 1
	}

	while IFS='	' read -r node_id stored_b64 export_b64
	do
		[ -n "${node_id}" ] || continue
		[ -n "${stored_b64}" ] || continue
		dbus set fss_node_${node_id}="${stored_b64}"
		export_json=$(fss_b64_decode "${export_b64}")
		printf '%s\n' "${export_json}" >> "${mapped_file}"
		imported_order="${imported_order}${imported_order:+,}${node_id}"
		if [ "${node_id}" -gt "${max_id}" ] 2>/dev/null;then
			max_id="${node_id}"
		fi
	done < "${meta_file}"
	rm -f "${meta_file}"

	if [ -z "${imported_order}" ];then
		rm -f "${mapped_file}"
		return 1
	fi
	if [ -n "${order_csv}" ];then
		dbus set fss_node_order="${order_csv},${imported_order}"
	else
		dbus set fss_node_order="${imported_order}"
	fi
	dbus set fss_data_schema=2
	dbus set fss_node_next_id="$((max_id + 1))"
	mv "${mapped_file}" "${input_file}"
	return 0
}

sub_restore_active_nodes_after_rewrite(){
	local input_file="$1"
	local restore_current="" restore_failover="" first_id=""

	first_id=$(sub_list_node_ids | sed -n '1p')

	if sub_node_exists_in_order "${CURR_NODE}";then
		restore_current="${CURR_NODE}"
	else
		restore_current=$(sub_find_node_id_in_file "${input_file}" "${CURR_NODE_NAME}" "${CURR_NODE_TYPE}" "${CURR_NODE_SERVER}" "${CURR_NODE_PORT}")
	fi
	[ -z "${restore_current}" ] && restore_current="${first_id}"

	if sub_node_exists_in_order "${FAILOVER_NODE}";then
		restore_failover="${FAILOVER_NODE}"
	else
		restore_failover=$(sub_find_node_id_in_file "${input_file}" "${FAILOVER_NODE_NAME}" "${FAILOVER_NODE_TYPE}" "${FAILOVER_NODE_SERVER}" "${FAILOVER_NODE_PORT}")
	fi

	[ -n "${restore_current}" ] && dbus set fss_node_current="${restore_current}" || dbus remove fss_node_current
	[ -n "${restore_failover}" ] && dbus set fss_node_failover_backup="${restore_failover}" || dbus remove fss_node_failover_backup
}

sub_refresh_node_state

# 一个节点里可能有的所有信息，记录用
# ssconf_basic_name_
# ssconf_basic_server_
# ssconf_basic_mode_
# ssconf_basic_method_
# ssconf_basic_password_
# ssconf_basic_port_
# ssconf_basic_ss_obfs_
# ssconf_basic_ss_obfs_host_
# ssconf_basic_rss_obfs_
# ssconf_basic_rss_obfs_param_
# ssconf_basic_rss_protocol_
# ssconf_basic_rss_protocol_param_
# ssconf_basic_koolgame_udp_			#废弃
# ssconf_basic_use_kcp_					#废弃
# ssconf_basic_use_lb_					#废弃
# ssconf_basic_lbmode_					#废弃
# ssconf_basic_weight_					#废弃
# ssconf_basic_group_
# ssconf_basic_v2ray_use_json_
# ssconf_basic_v2ray_uuid_
# ssconf_basic_v2ray_alterid_
# ssconf_basic_v2ray_security_
# ssconf_basic_v2ray_network_
# ssconf_basic_v2ray_headtype_tcp_
# ssconf_basic_v2ray_headtype_kcp_
# ssconf_basic_v2ray_kcp_seed
# ssconf_basic_v2ray_headtype_quic_
# ssconf_basic_v2ray_grpc_mode_
# ssconf_basic_v2ray_grpc_authority_
# ssconf_basic_v2ray_network_path_
# ssconf_basic_v2ray_network_host_
# ssconf_basic_v2ray_network_security_
# ssconf_basic_v2ray_network_security_ai_
# ssconf_basic_v2ray_network_security_alpn_h2_
# ssconf_basic_v2ray_network_security_alpn_http_
# ssconf_basic_v2ray_network_security_sni_
# ssconf_basic_v2ray_mux_enable_
# ssconf_basic_v2ray_mux_concurrency_
# ssconf_basic_v2ray_json_
# ssconf_basic_xray_use_json_
# ssconf_basic_xray_uuid_
# ssconf_basic_xray_alterid_
# ssconf_basic_xray_prot_
# ssconf_basic_xray_encryption_
# ssconf_basic_xray_flow_
# ssconf_basic_xray_network_
# ssconf_basic_xray_headtype_tcp_
# ssconf_basic_xray_headtype_kcp_
# ssconf_basic_xray_kcp_seed
# ssconf_basic_xray_headtype_quic_
# ssconf_basic_xray_grpc_mode_
# ssconf_basic_xray_grpc_authority_
# ssconf_basic_xray_xhttp_mode_
# ssconf_basic_xray_network_path_
# ssconf_basic_xray_network_host_
# ssconf_basic_xray_network_security_
# ssconf_basic_xray_network_security_ai_
# ssconf_basic_xray_network_security_alpn_h2_
# ssconf_basic_xray_network_security_alpn_http_
# ssconf_basic_xray_network_security_sni_
# ssconf_basic_xray_fingerprint_
# ssconf_basic_xray_show_
# ssconf_basic_xray_publickey_
# ssconf_basic_xray_shortid_
# ssconf_basic_xray_spiderx_
# ssconf_basic_xray_json_
# ssconf_basic_trojan_ai_
# ssconf_basic_trojan_uuid_
# ssconf_basic_trojan_sni_
# ssconf_basic_trojan_tfo_
# ssconf_basic_trojan_plugin_
# ssconf_basic_trojan_obfs_
# ssconf_basic_trojan_obfshost_
# ssconf_basic_trojan_obfsuri_
# ssconf_basic_naive_prot_
# ssconf_basic_naive_server_
# ssconf_basic_naive_port_
# ssconf_basic_naive_user_
# ssconf_basic_naive_pass_
# ssconf_basic_tuic_json_
# ssconf_basic_hy2_server_
# ssconf_basic_hy2_port_
# ssconf_basic_hy2_pass_
# ssconf_basic_hy2_obfs_
# ssconf_basic_hy2_obfs_pass_
# ssconf_basic_hy2_up_
# ssconf_basic_hy2_dl_
# ssconf_basic_hy2_sni_
# ssconf_basic_hy2_tfo_
# ssconf_basic_hy2_cg_
# ssconf_basic_type_

# 方案
# 设计：通过操作文件实现节点的订阅
# 1.	skipdb2json：订阅前将节点信息导出到文件，通过sed等操作将其转换为一个节点一行的压缩json格式的节点文件：fancyss_nodes_old_spl.txt，如果有有200个节点就是200行json
# 2.	nodes2files：根据节点中的link_hash信息，将节点文件拆分为多个，usr.txt (用户节点)， local_1_xxxx.txt (机场xxxx)， local_2_yyyy.txt (机场xxxx)
# 3.	nodes_stats：用拆分文件统计节点信息
# 4.	remove_null：订阅钱检测下是否有机场不再订阅（用户删除了这个机场的url）
# 5.	下载订阅
# 6.	解析订阅
# 7.	解析节点
# 8.		过滤节点
# 9.		点写入更新文件
# 10. 	对比更新文件和本地节点文件
# 11. 	写入/不写入节点
# 12.	

# 7. 最后改写key的顺序，写入dbus
# 8. 如果节点数量变少了，那么还需要掐尾去尾巴
# 优点：删除节点，节点排序很方便！

set_lock(){
	exec 233>"${LOCK_FILE}"
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
	echo $NODE_DATA | sed '$ s/,$/}/g' >>$1
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
		sub_write_nodes_schema2 "${DIR}/${file_name}.txt" || return 1
		if [ "${SUB_REWRITE_ALL}" = "1" ];then
			sub_restore_active_nodes_after_rewrite "${DIR}/${file_name}.txt"
			SUB_REWRITE_ALL=0
		elif [ -z "$(dbus get fss_node_current)" ];then
			local first_id=$(sub_list_node_ids | sed -n '1p')
			[ -n "${first_id}" ] && dbus set fss_node_current="${first_id}"
		fi
		echo_date "😀节点信息写入成功！"
		sync
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
	sync
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
		sub_prepare_schema2_raw_jsonl >/dev/null 2>&1 || return 0
		invalid_file="${DIR}/schema2_invalid_groups.txt"
		jq -r 'select(has("group")) | [._id // empty, (.group // "")] | @tsv' "${SCHEMA2_RAW_JSONL}" > "${invalid_file}" 2>/dev/null
		while IFS='	' read -r node value
		do
			[ -z "${node}" ] && continue
			if ! normalize_group_name "${value}" >/dev/null 2>&1;then
				echo_date "🧹检测到第${node}个节点的group值无效，已移除该group标记。"
				fss_set_node_field_plain "${node}" group ""
				changed=1
			fi
		done < "${invalid_file}"
		[ "${changed}" = "1" ] && sub_reset_schema2_cache
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
	[ -z "${file_path}" -o ! -f "${file_path}" ] && echo -n "${fallback_name}" && return 0
	local group_label=$(sub_extract_groups_from_file "${file_path}" | while IFS= read -r raw_group
	do
		local real_group=$(normalize_group_name "${raw_group}")
		[ -n "${real_group}" ] && echo "${real_group}"
	done | sort -u | sed '/^$/d' | sed 's/$/ + /g' | sed ':a;N;$!ba;s#\n##g' | sed 's/ + $//g')
	if [ -n "${group_label}" ];then
		echo -n "${group_label}"
	else
		echo -n "${fallback_name}"
	fi
}

skipdb2json(){
	if [ "${SEQ_NU}" == "0" ];then
		return
	fi
	echo_date "➡️开始整理本地节点到文件，请稍等..."
	rm -f "${LOCAL_SPLIT_META}"
	LOCAL_SPLIT_META_VALID=0
	sanitize_invalid_local_groups
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
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
	rm -rf "$DIR"/local_*.txt "${LOCAL_SPLIT_META}"
	[ -f "${LOCAL_NODES_SPL}" ] || return 0
	local split_total
	: > "${LOCAL_SPLIT_META}"
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
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
	else
		local map_file="${DIR}/local_split_map.tsv"
		local next_idx=0
		local raw_group group_hash group_label file_path key map_line
		: > "${map_file}"
		while IFS= read -r node_json
		do
			[ -n "${node_json}" ] || continue
			raw_group=$(printf '%s\n' "${node_json}" | jq -r '.group // "null"' 2>/dev/null)
			group_hash=$(get_group_hash_value "${raw_group}" 2>/dev/null)
			group_label=$(normalize_group_name "${raw_group}" 2>/dev/null)
			if [ -z "${group_hash}" ] || [ "${group_hash}" = "null" ];then
				key="user"
				file_path="${DIR}/local_0_user.txt"
				map_line=$(grep -F "user	" "${map_file}" 2>/dev/null | sed -n '1p')
				if [ -z "${map_line}" ];then
					printf '%s\t%s\t%s\n' "user" "${file_path}" "" >> "${map_file}"
				fi
			else
				key="${group_hash}"
				map_line=$(grep -F "${key}	" "${map_file}" 2>/dev/null | sed -n '1p')
				if [ -n "${map_line}" ];then
					file_path=$(printf '%s' "${map_line}" | awk -F '\t' '{print $2}')
				else
					next_idx=$((next_idx + 1))
					file_path="${DIR}/local_${next_idx}_${group_hash}.txt"
					printf '%s\t%s\t%s\n' "${group_hash}" "${file_path}" "${group_label}" >> "${map_file}"
				fi
			fi
			printf '%s\n' "${node_json}" >> "${file_path}"
		done < "${LOCAL_NODES_SPL}"

		while IFS='	' read -r group_hash file_path group_label
		do
			[ -n "${file_path}" ] || continue
			printf '%s\t%s\t%s\t%s\n' "${file_path}" "$(wc -l < "${file_path}")" "${group_hash}" "${group_label}" >> "${LOCAL_SPLIT_META}"
		done < "${map_file}"
		rm -f "${map_file}"
	fi

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
		sub_capture_active_nodes
		SUB_REWRITE_ALL=1
		fss_clear_v2_nodes
		dbus set fss_data_schema=2
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
		fss_clear_v2_nodes
		dbus set fss_data_schema=2
		dbus set fss_node_next_id=1
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
	echo_date "删除成功！"
}

# 删除所有订阅节点
remove_sub_node(){
	echo_date "删除所有订阅节点信息...自添加的节点不受影响！"
	#remove_node_info
	if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
		local remove_flag=0
		local keep_order=""
		local first_keep=""
		local max_keep="0"
		local restore_current=""
		local restore_failover=""
		sub_capture_active_nodes
		for remove_nu in $(sub_list_node_ids)
		do
			local group_value=$(sub_get_node_field_plain "${remove_nu}" group)
			if [ -n "$(normalize_group_name "${group_value}")" ];then
				echo_date "移除第$remove_nu节点：【$(sub_get_node_field_plain "${remove_nu}" name)】"
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
		[ -n "${restore_current}" ] && dbus set fss_node_current="${restore_current}" || dbus remove fss_node_current
		[ -n "${restore_failover}" ] && dbus set fss_node_failover_backup="${restore_failover}" || dbus remove fss_node_failover_backup
		dbus set fss_data_schema=2
		dbus set fss_node_next_id="$((max_keep + 1))"
		for conf1 in $(dbus list ss_online_group|awk -F"=" '{print $1}')
		do
			dbus remove ${conf1}
		done
		for conf2 in $(dbus list ss_online_hash|awk -F"=" '{print $1}')
		do
			dbus remove ${conf2}
		done
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
	if [ -z "${KEY_WORDS_1}" -a -z "${KEY_WORDS_2}" ];then
		return 0
	fi
	local _type=$1
	local remarks=$2
	local server=$3
	[ -n "${KEY_WORDS_1}" ] && local KEY_MATCH_1=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_1}")
	[ -n "${KEY_WORDS_2}" ] && local KEY_MATCH_2=$(echo ${remarks} ${server} | grep -Eo "${KEY_WORDS_2}")
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
	# 目前发现4种类型的节点：
	# 1. ss://YWVzLTEyOC1nY206RkFOQ1lTU19QQVNT@fancyss.net:111/?group=ZmFuY3lzX3Rlc3Q=#FANCYSS%20SS%E6%B5%8B%E8%AF%95%E8%8A%82%E7%82%B91%0A
	# 2. ss://2022-blake3-aes-256-gcm:czh9CYElDUxw9Y94bzTPjx2Q8URybABYROeiFwZ3o4U=@11.22.33.44:222#FANCYSS%20SS%E6%B5%8B%E8%AF%95%E8%8A%82%E7%82%B92%0A
	# 3. ss://MjAyMi1ibGFrZTMtYWVzLTI1Ni1nY206TWtjeGJsTkJXbUpKemRvY25ERUpOSk5BUw==@11.22.33.44:333#FANCYSS%20SS%E6%B5%8B%E8%AF%95%E8%8A%82%E7%82%B93%0A
	# 4. ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpGQU5DWVNTX1BBU1NAdGVzdC5mYW5jeXNzLmNvbTo0NDQ=#FANCYSS%20SS%E6%B5%8B%E8%AF%95%E8%8A%82%E7%82%B94%0A

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

	password=$(echo ${password} | base64_encode | sed 's/[[:space:]]//g')
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

	if [ -z "${server}" -o -z "${remarks}" -o -z "${server_port}" -o -z "${password}" -o -z "${encrypt_method}" ]; then
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

sub_uri_scheme(){
	printf '%s' "${1}" | sed -n 's#^\([A-Za-z0-9+.-]\+\)://.*#\1#p'
}

sub_uri_body(){
	printf '%s' "${1}" | sed -n 's#^[A-Za-z0-9+.-]\+://\(.*\)$#\1#p'
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
		x_encryption="none"
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
	# example, not real
	# trojan://a479d06e-c8b2-4f47-8f3d-0fdda666c7fc@userm2.su.com:39718?allowInsecure=1&plugin=obfs-local;obfs=websocket;obfs-host=bing.com;obfs-uri=/&tfo=1#香港M2-5|专线|流媒体|
	# trojan://auto@104.211.135.143:443?peer=elicense3.wawa55.workers.dev&plugin=obfs-local;obfs=websocket;obfs-host=esetsecuritylicense3.wawafec355.workers.dev;obfs-uri=/#United+States
	# trojan://yaml77@104.121.161.173:443?peer=yaml117.ggggf.net&plugin=obfs-local;obfs=websocket;obfs-host=yaml7.ggff.net;obfs-uri=/#United+States
	# trojan://amclubs2024@198.162.162.156:443?peer=trer.amub.us&plugin=obfs-local;obfs=websocket;obfs-host=trer.amub.us;obfs-uri=/?ed=2560#United+States
	# trojan://37470001032741200@grateful-glowworm.treefrog761.one:443#Mexico
	# trojan://37470001032741200@humble-rodent.treefrog761.one:443#South+Korea
	
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

	if [ "${tuic_auth#*:}" != "${tuic_auth}" ];then
		tuic_uuid=$(printf '%s' "${tuic_auth%%:*}" | urldecode)
		tuic_pass=$(printf '%s' "${tuic_auth#*:}" | urldecode)
	else
		tuic_uuid=""
		tuic_pass=""
	fi

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

	if [ -n "${tuic_server_override}" -a -n "$(__valid_ip "${tuic_server}")" ];then
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
		HY2_CG_OPT=$(dbus get ss_basic_hy2_cg_opt)
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
	# echo -n "${FW_TYPE}|${FW_MOD}|${MODEL}|${fw_version}|${pkg_name}|${pkg_arch}|${pkg_type}|${pkg_vers}|curl|v2rayN|Shadowrocket"
	# echo -n "${FW_TYPE}|${FW_MOD}|${MODEL}|${fw_version}|${pkg_name}|${pkg_arch}|${pkg_type}|${pkg_vers}|curl|v2rayN"

	_UA=$(dbus get ss_basic_online_ua)
	case ${_UA} in
	0)
		echo -n "${FW_TYPE}|${FW_MOD}|${MODEL}|${fw_version}|${pkg_name}|${pkg_arch}|${pkg_type}|${pkg_vers}|curl|v2rayN"
		;;
	1)
		echo -n ""
		;;
	2)
		echo -n "v2rayn"
		;;
	3)
		echo -n "v2rayng"
		;;
	4)
		echo -n "shadowrocket"
		;;
	esac
	#&flag=shadowrocket
	#&flag=v2rayn
}

download_by_curl(){
	local url_encode=$(echo "$1")
	
	echo_date "⬇️使用curl下载订阅..."
	local UA=$(get_ua)
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
		echo_date "➡️通过本地网络直连下载订阅..."
		run /tmp/curl-subscribe -sSk -L ${UA_ARG} --connect-timeout 5 -m 5 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		if [ "$?" == "0" ]; then
			return 0
		fi

		# 下载失败，使用代理下载
		echo_date "❌️直连下载订阅失败！尝试使用当前节点代理下载订阅！"
		SOCKS5_OPEN=$(netstat -nlp 2>/dev/null|grep -w "23456"|grep -Eo "v2ray|xray|naive|tuic")
		if [ -n "${SOCKS5_OPEN}" ];then
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			run /tmp/curl-subscribe -sSk -L ${UA_ARG} --connect-timeout 5 -m 5 -x socks5h://127.0.0.1:23456 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
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
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			run /tmp/curl-subscribe -sSk -L ${UA_ARG} --connect-timeout 5 -m 5 -x socks5h://127.0.0.1:23456 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
			return $?
		else
			local EXT_ARG=""
			echo_date "⚠️当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点工作异常，改用常规网络下载..."
			return 1
		fi
	elif [ "${SUB_BY_PROXY}" == "2" ]; then
		# 直连下载
		echo_date "⬇️使用常规网络下载..."
		run /tmp/curl-subscribe -sSk -L ${UA_ARG} --connect-timeout 5 -m 5 --retry 3 --retry-delay 1 "${url_encode}" 2>/dev/null >${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		return $?
	fi
}

download_by_wget(){
	local url_encode=$(echo "$1")
	#local url_encode="${url_encode}&flag=shadowrocket"
	echo_date "⬇️使用wget下载订阅..."
	local UA=$(get_ua)
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
		echo_date "➡️通过本地网络直连下载订阅..."
		run5 wget -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		if [ "$?" == "0" ]; then
			return 0
		fi
		
		# 下载失败，使用代理下载
		echo_date "❌️直连下载订阅失败！尝试使用当前节点代理下载订阅！"
		proxy_rule add "${DOMAIN_NAME}"
		if [ "$?" == "0" ];then
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			run5 wget -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		else
			echo_date "⚠️当前订阅链接域名：${DOMAIN_NAME}解析失败，结束wget订阅下载！"
			return 1
		fi
		proxy_rule del "${DOMAIN_NAME}"
	elif [ "${SUB_BY_PROXY}" == "1" ]; then
		# 代理下载
		proxy_rule add "${DOMAIN_NAME}"
		if [ "$?" == "0" ];then
			echo_date "✈️使用当前$(get_type_name "$(sub_get_node_field_plain "${CURR_NODE}" type)")节点：[$(sub_get_node_field_plain "${CURR_NODE}" name)]提供的网络下载..."
			run5 wget -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		else
			echo_date "⚠️当前订阅链接域名：${DOMAIN_NAME}解析失败，结束wget订阅下载！"
			return 1
		fi
		proxy_rule del "${DOMAIN_NAME}"
	elif [ "${SUB_BY_PROXY}" == "2" ]; then
		# 直连下载
		echo_date "⬇️使用常规网络下载..."
		run5 wget -t 3 ${UA_ARG} -q ${EXT_OPT} "${url_encode}" -O ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		return $?
	fi
}

get_online_rule_now(){
	# 0. variable define
	local SUB_LINK="$1"
	local RAW_SOURCE_TAG=""
	local CANONICAL_SOURCE_TAG=""
	local SUB_SOURCE_TAG=""

	# 1. get domain name of node subscribe link
	local DOMAIN_NAME="$(get_domain_name ${SUB_LINK})"
	if [ -z "${DOMAIN_NAME}" ];then
		echo_date "⚠️该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
		subscribe_failed
		return 1
	fi

	# 2. detect duplitcate sub
	local SUB_LINK_HASH=$(echo "${SUB_LINK}" | md5sum | awk '{print $1}')
	RAW_SOURCE_TAG=$(sub_get_source_tag_from_domain "${DOMAIN_NAME}")
	SUB_SOURCE_TAG=$(sub_get_source_alias_tag "${RAW_SOURCE_TAG}")
	if [ -z "${SUB_SOURCE_TAG}" ];then
		echo_date "⚠️无法识别当前订阅来源域名，跳过此订阅！"
		return 1
	fi
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

	# 3. try to delete some file left by last sublink subscribe
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	
	# 7. download sublink
	echo_date "📁准备下载订阅链接到本地临时文件，请稍等..."
	download_by_curl "${SUB_LINK}"
	if [ "$?" == "0" ]; then
		echo_date "😀下载成功，继续检测下载内容..."

		#可能有跳转
		local jump=$(grep -Eo "Redirecting|301" ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt)
		if [ -n "$jump" ]; then
			echo_date "⤴️订阅链接可能有跳转，尝试更换wget进行下载..."
			rm ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
			download_by_wget "${SUB_LINK}"
		fi

		# 下载到了yaml文件？
		if [ "$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | grep -c proxies)" -ge "1" ]; then
			echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
			return 1
		fi

		#下载为空...
		if [ "$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | wc -c)" == "0" ]; then
			echo_date "🈳下载内容为空，尝试更换wget进行下载..."
			rm ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
			download_by_wget "${SUB_LINK}"
		fi

		# 404
		local wrong1=$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | grep -E "404")
		if [ -n "${wrong1}" ]; then
			echo_date "⚠️解析错误！原因：该订阅链接无法访问，错误代码：404！"
			return 1
		fi
		
		# 产品信息错误
		local wrong=$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | grep -E "\{")
		if [ -n "${wrong}" ]; then
			echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
			echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
			echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
			return 1
		fi

		# 非base64编码
		dec64 $(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt) >/dev/null 2>&1
		if [ "$?" != "0" ]; then
			echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
			echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
			return 1
		fi
	else
		echo_date "⚠️使用curl下载订阅失败！"
		rm ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt
		download_by_wget "${SUB_LINK}"

		#返回错误
		if [ "$?" != "0" ]; then
			echo_date "⚠️wget下载订阅失败！"
			return 1
		fi

		# 下载到了yaml文件？
		if [ "$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | grep -c proxies)" -ge "1" ]; then
			echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
			return 1
		fi

		#下载为空...
		if [ "$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | wc -c)" == "0" ]; then
			echo_date "⚠️下载内容为空！️该订阅链接不包含任何节点信息"
			echo_date "⚠️请检查你的服务商是否更换了订阅链接！"
			return 1
		fi
		
		# 产品信息错误
		local wrong2=$(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt | grep -E "\{")
		if [ -n "${wrong2}" ]; then
			echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
			echo_date "⚠️请检查你是否使用了错误的订阅链接，如clash专用订阅链接！"
			echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
			return 1
		fi

		# 非base64编码
		dec64 $(cat ${DIR}/sub_file_encode_${SUB_LINK_HASH:0:4}.txt) >/dev/null 2>&1
		if [ "$?" != "0" ]; then
			echo_date "⚠️解析错误！原因：该订阅链接获取的内容并非正确的base64编码内容！"
			echo_date "⚠️请尝试将用浏览器打开订阅链接，看内容是否正常！"
			return 1
		fi
	fi
	
	echo_date "😀下载内容检测完成！"
	local decoded_hash="${SUB_LINK_HASH:0:4}"
	local source_hash="${SUB_SOURCE_TAG}"
	local decoded_file="${DIR}/sub_file_decode_${decoded_hash}.txt"
	sub_prepare_decoded_file "${decoded_hash}" || return 1
	if sub_raw_cache_same_as_current "${SUB_LINK_HASH}" "${source_hash}" "${decoded_file}";then
		sub_restore_from_parsed_cache "${SUB_LINK_HASH}" "${source_hash}" "${sub_count}" && return 0
	fi
	echo_date "🔍开始解析节点信息..."

	local NODE_NU_RAW=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -c "://")
	echo_date "😀初步解析成功！共获得${NODE_NU_RAW}个节点！"

	# 11. 检测 ss ssr vmess
	NODE_FORMAT1=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^ss://")
	NODE_FORMAT2=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^ssr://")
	NODE_FORMAT3=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^vmess://")
	NODE_FORMAT4=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^vless://")
	NODE_FORMAT5=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^trojan://")
	NODE_FORMAT6=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^hysteria2://|^hy2://")
	NODE_FORMAT7=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^tuic://")
	NODE_FORMAT8=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -E "^naive\\+https://|^naive\\+quic://")

	local NODE_NU_SS=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^ss://") || "0"
	local NODE_NU_SR=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^ssr://") || "0"
	local NODE_NU_VM=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^vmess://") || "0"
	local NODE_NU_VL=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^vless://") || "0"
	local NODE_NU_TJ=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^trojan://") || "0"
	local NODE_NU_H2=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^hysteria2://|^hy2://") || "0"
	local NODE_NU_TC=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^tuic://") || "0"
	local NODE_NU_NV=$(cat ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt | grep -Ec "^naive\\+https://|^naive\\+quic://") || "0"
	local pkg_type=$(dbus get ss_basic_pkg_type)
	[ -n "${pkg_type}" ] || pkg_type=$(cat /koolshare/webs/Module_shadowsocks.asp | tr -d '\r' | grep -Eo "PKG_TYPE=.+"|awk -F "=" '{print $2}'|sed 's/"//g')
	local NODE_NU_TT=$((${NODE_NU_SS} + ${NODE_NU_SR} + ${NODE_NU_VM} + ${NODE_NU_VL} + ${NODE_NU_TJ} + ${NODE_NU_H2}))
	if [ "${pkg_type}" == "full" ];then
		NODE_NU_TT=$((${NODE_NU_TT} + ${NODE_NU_TC} + ${NODE_NU_NV}))
	fi
	if [ -z "${NODE_FORMAT1}" -a -z "${NODE_FORMAT2}" -a -z "${NODE_FORMAT3}" -a -z "${NODE_FORMAT4}" -a -z "${NODE_FORMAT5}" -a -z "${NODE_FORMAT6}" -a -z "${NODE_FORMAT7}" -a -z "${NODE_FORMAT8}" ];then
		echo_date "⚠️订阅中不包含任何ss/ssr/vmess/vless/trojan/hysteria2/tuic/naive节点，退出！"
		return 1
	fi
	if [ "${NODE_NU_TT}" -eq "0" -a "${pkg_type}" != "full" -a $((${NODE_NU_TC} + ${NODE_NU_NV})) -gt "0" ];then
		echo_date "⚠️当前插件为lite版本，订阅中的TUIC/NaïveProxy节点均为full版专属，无法导入！"
		return 1
	fi
	if [ "${NODE_NU_TT}" -lt "${NODE_NU_RAW}" ];then
		echo_date "ℹ️${NODE_NU_RAW}个节点中，一共检测到${NODE_NU_TT}个支持节点！"
	fi
	echo_date "ℹ️具体情况如下："
	[ "${NODE_NU_SS}" -gt "0" ] && echo_date "🟢ss节点：${NODE_NU_SS}个"
	[ "${NODE_NU_SR}" -gt "0" ] && echo_date "🔵ssr节点：${NODE_NU_SR}个"
	[ "${NODE_NU_VM}" -gt "0" ] && echo_date "🟠vmess节点：${NODE_NU_VM}个"
	[ "${NODE_NU_VL}" -gt "0" ] && echo_date "🟣vless节点：${NODE_NU_VL}个"
	[ "${NODE_NU_TJ}" -gt "0" ] && echo_date "🟡trojan节点：${NODE_NU_TJ}个"
	[ "${NODE_NU_H2}" -gt "0" ] && echo_date "🟤hysteria2节点：${NODE_NU_H2}个"
	[ "${NODE_NU_TC}" -gt "0" ] && echo_date "🟫tuic节点：${NODE_NU_TC}个"
	[ "${NODE_NU_NV}" -gt "0" ] && echo_date "🟧Naïve节点：${NODE_NU_NV}个"
	if [ "${pkg_type}" != "full" -a $((${NODE_NU_TC} + ${NODE_NU_NV})) -gt "0" ];then
		echo_date "⚠️当前插件为lite版本，TUIC/NaïveProxy节点会被跳过。"
	fi
	echo_date "-------------------------------------------------------------------"

	# 12. 开始解析并写入节点
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
				echo_date "⛔不支持${node_type}格式的节点，跳过！"
			fi
			# if [ -n "${node_info}" ];then
			# 	local _match=$(echo "${node_info}"|grep -E "//")
			# 	if [ -z "${_match}" ];then
			# 		echo_date "ℹ️$node"
			# 	else
			# 		echo "${node_info}"
			# 	fi
			# fi
			continue
			;;
		esac
	done < ${DIR}/sub_file_decode_${SUB_LINK_HASH:0:4}.txt
	echo_date "-------------------------------------------------------------------"
	local ONLINE_GROUP=$(get_group_label_from_file "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt" "${DOMAIN_NAME}")
	CANONICAL_SOURCE_TAG=$(sub_canonicalize_online_source "${sub_count}" "${SUB_SOURCE_TAG}" "${ONLINE_GROUP}" 2>/dev/null)
	[ -n "${CANONICAL_SOURCE_TAG}" ] || CANONICAL_SOURCE_TAG="${SUB_SOURCE_TAG}"
	if [ "${CANONICAL_SOURCE_TAG}" != "${SUB_SOURCE_TAG}" ];then
		echo_date "♻️检测到订阅域名已变更，但机场分组保持为【${ONLINE_GROUP}】，沿用原机场身份处理。"
		SUB_SOURCE_TAG="${CANONICAL_SOURCE_TAG}"
	fi
	sub_register_source_identity "${RAW_SOURCE_TAG}" "${SUB_SOURCE_TAG}" "${ONLINE_GROUP}" >/dev/null 2>&1
	if [ -s "${ACTIVE_SOURCE_TAGS}" ] && grep -Fxq "${SUB_SOURCE_TAG}" "${ACTIVE_SOURCE_TAGS}";then
		echo_date "⚠️检测到多个订阅链接属于同一机场【${ONLINE_GROUP}】，本次仅保留第一个来源。"
		rm -f "${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt"
		return 0
	fi
	sub_mark_active_source_tag "${SUB_SOURCE_TAG}"
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
	local ISLOCALFILE=$(find ${DIR} -name "local_*_${SUB_SOURCE_TAG}.txt")
	if [ -n "${ISLOCALFILE}" ];then
		local md5_loc=$(sub_nodes_file_md5 ${ISLOCALFILE})
		local LOCAL_GROUP=$(get_group_label_from_file "${ISLOCALFILE}" "${DOMAIN_NAME}")
		local LOCAL_NODES=$(cat $ISLOCALFILE | wc -l)
		echo_date "🔶当前订阅来源【${LOCAL_GROUP}】，在本地已有节点${LOCAL_NODES}个。"
		echo_date "🔶本地节点校验：${md5_loc}"
		if [ "${md5_loc}" == "${md5_new}" ];then
			echo_date "🆚对比结果：本地节点已经是最新，跳过！"
			rm -rf ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt
			sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
			sub_update_parsed_cache "${SUB_LINK_HASH}" "${ISLOCALFILE}"
		else
			echo_date "🆚对比结果：检测到节点发生变更，生成节点更新文件！"
			# 将订阅后的文件，覆盖为本地的相同link hash的文件
			rm -rf ${ISLOCALFILE}
			cp -rf ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt ${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt
			sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
			sub_update_parsed_cache "${SUB_LINK_HASH}" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
			SUB_LOCAL_CHANGED=1
		fi
		return 0
	else
		echo_date "🔶当前订阅链来源【${ONLINE_GROUP}】在本地尚无节点！"
		echo_date "🆚对比结果：检测到新的订阅节点，生成节点添加文件！"
		# 将订阅后的文件，覆盖为本地的相同link hash的文件
		cp -rf ${DIR}/online_${sub_count}_${SUB_SOURCE_TAG}.txt ${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt
		sub_update_raw_cache "${SUB_LINK_HASH}" "${decoded_file}"
		sub_update_parsed_cache "${SUB_LINK_HASH}" "${DIR}/local_${sub_count}_${SUB_SOURCE_TAG}.txt"
		SUB_LOCAL_CHANGED=1
		return 0
	fi
}

exit_sub(){
	echo_date "==================================================================="
	exit 1
}

start_node_subscribe(){
	local online_url_nu online_urls active_hash_file
	echo_date "==================================================================="
	echo_date "                服务器订阅程序(Shell by stones & sadog)"
	echo_date "==================================================================="

	# run some test before anything start
	# echo_date "⚙️test: 脚本环境变量：$(env | wc -l)个"
	
	# 0. var define
	sub_refresh_node_state

	# 1. 检查订阅链接是否有效
	if [ -z "$(dbus get ss_online_links)" ];then
		echo_date "🈳订阅地址输入框为空，准备清理现有订阅节点..."
		remove_sub_node
		sub_clear_subscribe_cache
		echo_date "🎉订阅节点清理完成！"
		echo_date "==================================================================="
		return 0
	fi
	online_urls=$(sub_get_online_urls)
	online_url_nu=$(printf '%s\n' "${online_urls}" | sed '/^$/d' | wc -l)
	if [ "${online_url_nu}" == "0" ];then
		echo_date "🈳未发现任何有效的订阅地址，准备清理现有订阅节点..."
		remove_sub_node
		sub_clear_subscribe_cache
		echo_date "🎉订阅节点清理完成！"
		echo_date "==================================================================="
		return 0
	fi
	echo_date "✈️开始订阅！"
	SUB_LOCAL_CHANGED=0
	SUB_HAS_FAILURE=0

	# 2. 创建临时文件夹，用于存放订阅过程中的临时文件
	mkdir -p $DIR
	rm -rf $DIR/*
	sub_reset_schema2_cache
	: > "${ACTIVE_SOURCE_TAGS}"
	active_hash_file="${DIR}/active_link_hashes.txt"
	sub_collect_active_link_hashes "${active_hash_file}" "${online_urls}"
	sub_prune_subscribe_cache "${active_hash_file}"

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
	echo_date "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
	if [ "${SUB_HAS_FAILURE}" = "1" ];then
		echo_date "⚠️本次订阅存在失败任务，跳过过期订阅来源清理，保留现有本地订阅节点。"
	else
		remove_null
		sub_prune_source_identity "${ACTIVE_SOURCE_TAGS}"
	fi

	# 5. 写入所有节点
	if [ "${SUB_LOCAL_CHANGED}" != "1" ];then
		echo_date "ℹ️本次订阅没有任何节点发生变化，不进行写入，继续！"
		echo_date "🧹一点点清理工作..."
		echo_date "🎉所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
		echo_date "==================================================================="
		return 0
	fi
	local ISNEW=$(find $DIR -name "local_*_*.txt")
	if [ -n "${ISNEW}" ];then
		find $DIR -name "local_*.txt" | sort -n | xargs cat >$DIR/ss_nodes_new.txt
		local md5sum_old=$(sub_nodes_file_md5 ${LOCAL_NODES_BAK})
		local md5sum_new=$(sub_nodes_file_md5 $DIR/ss_nodes_new.txt)
		if [ "${md5sum_new}" != "${md5sum_old}" ];then
			if [ "${SUB_STORAGE_SCHEMA}" = "2" ];then
				if ! sub_validate_jsonl_file "$DIR/ss_nodes_new.txt"; then
					echo_date "❌节点写入文件校验失败，已终止本次订阅，原有节点保持不变！"
					exit_sub
				fi
			fi
			clear_nodes
			echo_date "ℹ️开始写入节点..."
			if ! json2skipd "ss_nodes_new"; then
				echo_date "❌节点信息写入失败！"
				exit_sub
			fi
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
			echo_date "⚠️尚不支持${node_type}格式的节点，跳过！"
			continue
			;;
		esac
	done
	dbus remove ss_base64_links
	echo_date "-------------------------------------------------------------------"
	if [ -f "${DIR}/offline_node_new.txt" ];then
		echo_date "ℹ️离线节点解析完毕，开始写入节点..."
		json2skipd "offline_node_new"
	else
		echo_date "ℹ️离线节点解析失败！跳过！"
	fi

	
	echo_date "==================================================================="
}

if [ -z "$2" -a -n "$1" ];then
	SH_ARG=$1
	WEB_ACTION=0
elif [ -n "$2" -a -n "$1" ];then
	SH_ARG=$2
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
