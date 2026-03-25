#!/bin/sh

# fancyss script for asuswrt/merlin based router with software center

source /koolshare/scripts/ss_base.sh
source /koolshare/scripts/ss_webtest_gen.sh
LOGTIME1=⌚$(TZ=UTC-8 date -R "+%H:%M:%S")
TMP2=/tmp/fancyss_webtest
WT_WEBTEST_FILE=/tmp/upload/webtest.txt
WT_WEBTEST_STREAM=/tmp/upload/webtest.stream
WT_WEBTEST_BACKUP=/tmp/upload/webtest_bakcup.txt
WT_SERVER_RESOLV_MODE=$(dbus get ss_basic_server_resolv_mode)
[ "${WT_SERVER_RESOLV_MODE}" = "2" ] || WT_SERVER_RESOLV_MODE="1"
WT_NODE_CACHE_DIR=""
WT_NODE_ENV_DIR=""
WT_NODE_ACTIVE_ID=""
WT_NODE_ACTIVE_FIELDS=""
WT_PREVIEW_READY=0

wt_ensure_webtest_dir() {
	mkdir -p /tmp/upload
}

wt_reset_webtest_output() {
	wt_ensure_webtest_dir
	: >"${WT_WEBTEST_FILE}"
	: >"${WT_WEBTEST_STREAM}"
}

wt_append_webtest_line() {
	local line="$1"

	[ -n "${line}" ] || return 0
	wt_ensure_webtest_dir
	printf '%s\n' "${line}" >>"${WT_WEBTEST_FILE}"
	printf '%s\n' "${line}" >>"${WT_WEBTEST_STREAM}"
}

wt_append_webtest_file() {
	local src="$1"

	[ -f "${src}" ] || return 0
	wt_ensure_webtest_dir
	cat "${src}" >>"${WT_WEBTEST_FILE}"
	cat "${src}" >>"${WT_WEBTEST_STREAM}"
}

wt_write_webtest_snapshot() {
	local src="$1"

	wt_ensure_webtest_dir
	if [ -f "${src}" ]; then
		cp -f "${src}" "${WT_WEBTEST_FILE}"
	else
		: >"${WT_WEBTEST_FILE}"
	fi
}

wt_reset_active_node_env() {
	local field=""

	for field in ${WT_NODE_ACTIVE_FIELDS}
	do
		unset WTN_${field}
	done
	unset WT_NODE_ENV_FIELDS
	WT_NODE_ACTIVE_ID=""
	WT_NODE_ACTIVE_FIELDS=""
}

wt_build_node_env_file() {
	local node_id="$1"
	local json_file=""
	local env_file=""
	local jq_bin=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${WT_NODE_ENV_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	json_file="${WT_NODE_CACHE_DIR}/${node_id}.json"
	env_file="${WT_NODE_ENV_DIR}/${node_id}.env"
	[ -f "${json_file}" ] || return 1
	jq_bin=$(fss_pick_jq_bin)
	[ -n "${jq_bin}" ] || return 1

	"${jq_bin}" -r '
		def is_b64_field($key):
			$key == "password"
			or $key == "naive_pass"
			or $key == "v2ray_json"
			or $key == "xray_json"
			or $key == "tuic_json";
		def decode_value($key; $value):
			if is_b64_field($key) and ((._b64_mode // "") != "raw") and ((._source // "") == "subscribe") then
				(try ($value | @base64d) catch $value)
			else
				$value
			end;
		[
			to_entries[]
			| select(.key | startswith("_") | not)
			| .key as $k
			| (.value | if type == "string" then . else tostring end) as $v
			| select($v != "")
			| {key: $k, value: decode_value($k; $v)}
		] as $entries
		| "WT_NODE_ENV_FIELDS=" + (($entries | map(.key) | join(" ")) | @sh),
		  ($entries[] | "WTN_" + .key + "=" + (.value | @sh))
	' "${json_file}" > "${env_file}.tmp" 2>/dev/null || {
		rm -f "${env_file}.tmp"
		return 1
	}
	mv -f "${env_file}.tmp" "${env_file}"
}

wt_load_node_env() {
	local node_id="$1"
	local env_file=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${WT_NODE_ENV_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ "${WT_NODE_ACTIVE_ID}" = "${node_id}" ] && return 0
	env_file="${WT_NODE_ENV_DIR}/${node_id}.env"
	[ -f "${env_file}" ] || wt_build_node_env_file "${node_id}" || return 1
	wt_reset_active_node_env
	. "${env_file}" || return 1
	WT_NODE_ACTIVE_ID="${node_id}"
	WT_NODE_ACTIVE_FIELDS="${WT_NODE_ENV_FIELDS}"
}

wt_node_get_plain_from_cache() {
	local node_id="$1"
	local field="$2"
	local store_field=""
	local value=""

	[ -n "${WT_NODE_CACHE_DIR}" ] || return 1
	[ -n "${node_id}" ] || return 1
	[ -n "${field}" ] || return 1
	store_field=$(fss_resolve_node_field_name "${field}")
	wt_load_node_env "${node_id}" || return 1
	eval "value=\${WTN_${store_field}-}"
	printf '%s' "${value}"
}

wt_node_get() {
	local field="$1"
	local node_id="$2"
	local store_field=""
	local value=""

	if value=$(wt_node_get_plain_from_cache "${node_id}" "${field}" 2>/dev/null); then
		store_field=$(fss_resolve_node_field_name "${field}")
		[ -n "${value}" ] || return 0
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
		return 0
	fi
	fss_get_node_field_legacy "${node_id}" "${field}"
}

wt_node_get_plain() {
	local field="$1"
	local node_id="$2"
	local value=""

	if value=$(wt_node_get_plain_from_cache "${node_id}" "${field}" 2>/dev/null); then
		printf '%s' "${value}"
		return 0
	fi
	fss_get_node_field_plain "${node_id}" "${field}"
}

wt_node_count() {
	fss_get_node_count
}

run(){
	env -i PATH=${PATH} "$@"
}

wt_server_resolv_mode_is_dynamic() {
	[ "${WT_SERVER_RESOLV_MODE}" = "1" ]
}

wt_server_resolv_mode_is_preresolve() {
	[ "${WT_SERVER_RESOLV_MODE}" = "2" ]
}

wt_prepare_node_cache() {
	local node_id=""
	local blob=""

	wt_reset_active_node_env
	WT_NODE_CACHE_DIR=""
	WT_NODE_ENV_DIR=""
	[ "$(fss_detect_storage_schema)" = "2" ] || return 0
	WT_NODE_CACHE_DIR="${TMP2}/node_cache"
	WT_NODE_ENV_DIR="${TMP2}/node_env"
	mkdir -p "${WT_NODE_CACHE_DIR}" || {
		WT_NODE_CACHE_DIR=""
		return 1
	}
	mkdir -p "${WT_NODE_ENV_DIR}" || {
		WT_NODE_CACHE_DIR=""
		WT_NODE_ENV_DIR=""
		return 1
	}
	rm -f ${WT_NODE_CACHE_DIR}/*.json >/dev/null 2>&1
	rm -f ${WT_NODE_ENV_DIR}/*.env >/dev/null 2>&1
	fss_list_node_ids | while read node_id
	do
		[ -n "${node_id}" ] || continue
		blob=$(dbus get fss_node_${node_id})
		[ -n "${blob}" ] || continue
		fss_b64_decode "${blob}" > "${WT_NODE_CACHE_DIR}/${node_id}.json" 2>/dev/null || {
			rm -f "${WT_NODE_CACHE_DIR}/${node_id}.json"
		}
	done
	ls ${WT_NODE_CACHE_DIR}/*.json >/dev/null 2>&1 || {
		WT_NODE_CACHE_DIR=""
		WT_NODE_ENV_DIR=""
		return 1
	}
}

wt_list_group_files() {
	find ${TMP2} -name "wt_*.txt" 2>/dev/null | sed 's#^.*/##' | grep -v '^wt_xray_group\.txt$' | sort -t '_' -k2,2n -k3,3n
}

wt_build_nodes_index() {
	local jq_bin=""
	local json_files=""

	if [ -n "${WT_NODE_CACHE_DIR}" ];then
		jq_bin=$(fss_pick_jq_bin)
		if [ -n "${jq_bin}" ];then
			json_files=$(find "${WT_NODE_CACHE_DIR}" -name "*.json" | sort -t "/" -nk5)
			[ -n "${json_files}" ] && "${jq_bin}" -r '
				[
					(input_filename | split("/")[-1] | rtrimstr(".json")),
					(
						((.type // "") | tostring) as $type
						| if ($type | length) == 1 then "0" + $type else $type end
					),
					((.ss_obfs // "") | tostring),
					((.method // "") | tostring)
				] | join("|")
			' ${json_files} 2>/dev/null > ${TMP2}/nodes_index.txt && {
				sort -t "|" -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt
				return 0
			}
		fi
	fi

	: >${TMP2}/nodes_index.txt
	fss_list_node_ids | while read node_id
	do
		[ -z "${node_id}" ] && continue
		printf "%s|%02d|%s|%s\n" \
			"${node_id}" \
			"$(wt_node_get type ${node_id})" \
			"$(wt_node_get ss_obfs ${node_id})" \
			"$(wt_node_get method ${node_id})" \
			>>${TMP2}/nodes_index.txt
	done
	sort -t "|" -nk1 ${TMP2}/nodes_index.txt -o ${TMP2}/nodes_index.txt
}

wt_group_type_is_xray_like() {
	case "$1" in
	00_01|00_02|00_04|00_05|03|04|05|08)
		return 0
		;;
	esac
	return 1
}

wt_group_preview_count() {
	case "$1" in
	00_01|00_02|00_04|00_05|03|04|05|08)
		printf '%s\n' "${WT_XRAY_THREADS:-1}"
		;;
	01)
		printf '%s\n' "${WT_SSR_THREADS:-1}"
		;;
	06|07)
		printf '%s\n' 9999
		;;
	*)
		printf '%s\n' 4
		;;
	esac
}

wt_show_current_group_preview() {
	local preview_file="$1"
	local node_type="$2"
	local preview_lines=""
	local nu=""

	[ -f "${preview_file}" ] || return 0
	preview_lines=$(wt_group_preview_count "${node_type}")
	[ -n "${preview_lines}" ] || preview_lines=1
	sed -n "1,${preview_lines}p" ${preview_file} | while read nu
	do
		[ -n "${nu}" ] || continue
		wt_append_webtest_line "${nu}>testing..."
	done
}

wt_refresh_node_direct_dns_if_needed() {
	local dns_plan=""

	wt_server_resolv_mode_is_dynamic || return 0
	[ "$(dbus get ss_basic_enable)" = "1" ] || return 0
	dns_plan=$(dbus get ss_basic_dns_plan)
	case "${dns_plan}" in
	1|2)
			;;
	*)
		return 0
		;;
	esac
	fss_refresh_node_direct_cache >/dev/null 2>&1
	fss_node_direct_cache_differs_from_runtime || return 0
	/bin/sh /koolshare/ss/ssconfig.sh refresh_node_direct_dns >/dev/null 2>&1
}

wt_prepare_webtest_preview() {
	local curr_node=""
	local curr_file=""
	local curr_file_name=""
	local curr_type=""
	local preview_file=""
	local max_show=""
	local begn_node=""
	local first_bgn=""
	local xray_group_file="${TMP2}/wt_xray_group.txt"

	WT_PREVIEW_READY=0
	detect_perf
	curr_node=$(fss_get_current_node_id)
	[ -z "${curr_node}" ] && curr_node=$(fss_get_first_node_id)
	[ -n "${curr_node}" ] || return 1

	max_show=$(dbus get ss_basic_row)
	if [ "${max_show}" -gt "1" ]; then
		begn_node=$(awk -v x=${curr_node} -v y=${max_show} 'BEGIN { printf "%.0f\n", (x-y/2)}')
	else
		begn_node=$((${curr_node} - 10))
	fi

	curr_file=$(find ${TMP2}/ -name "wt_*.txt" | xargs grep -Ew "^${curr_node}" | awk -F ":" '{print $1}')
	[ -f "${curr_file}" ] || return 1
	curr_file_name=${curr_file##*/}
	curr_type=${curr_file_name#wt_*_}
	curr_type=${curr_type%%.*}

	first_bgn=$(sed -n '1p' ${curr_file})
	if [ -n "${first_bgn}" ] && [ "${begn_node}" -gt "${first_bgn}" ]; then
		sed -n "/${begn_node}/,\$p" ${curr_file} > ${TMP2}/re-arrange-1.txt
		sed -n "1,/^${begn_node}\$/p" ${curr_file} | sed '$d' > ${TMP2}/re-arrange-2.txt
		cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${curr_file}
		rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
	fi

	if wt_group_type_is_xray_like "${curr_type}"; then
		rm -rf ${xray_group_file}
		wt_list_group_files | while read xfile_name
		do
			[ -n "${xfile_name}" ] || continue
			local xfile="${TMP2}/${xfile_name}"
			local xnode_type=${xfile_name#wt_*_}
			xnode_type=${xnode_type%%.*}
			case ${xnode_type} in
			00_01|00_02|00_04|00_05|03|04|05|08)
				cat ${xfile} >> ${xray_group_file}
				;;
			esac
		done
		if [ -s "${xray_group_file}" ] && grep -Ew "^${curr_node}$" ${xray_group_file} >/dev/null 2>&1; then
			first_bgn=$(sed -n '1p' ${xray_group_file})
			if [ -n "${first_bgn}" ] && [ "${begn_node}" -gt "${first_bgn}" ]; then
				sed -n "/${begn_node}/,\$p" ${xray_group_file} > ${TMP2}/re-arrange-1.txt
				sed -n "1,/^${begn_node}\$/p" ${xray_group_file} | sed '$d' > ${TMP2}/re-arrange-2.txt
				cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${xray_group_file}
				rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
			fi
			preview_file="${xray_group_file}"
		fi
	fi

	[ -n "${preview_file}" ] || preview_file="${curr_file}"
	wt_reset_webtest_output
	http_response "ok4, webtest.txt generating..."
	wt_show_current_group_preview "${preview_file}" "${curr_type}"
	WT_PREVIEW_READY=1
}

detect_perf(){
	WT_ARCH=$(uname -m)
	WT_CPU_CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
	WT_MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
	WT_LOW_END=0

	# 低端机型： armv7l设备，或者aarch64设备，内存小于1G
	# 高端机型： aarch64设备，且内存1G及其以上
	if [ "${WT_ARCH}" == "armv7l" ];then
		WT_LOW_END=1
	elif [ "${WT_ARCH}" == "aarch64" ];then
		if [ "${WT_CPU_CORES}" -le 2 -o "${WT_MEM_MB}" -lt 768 ];then
			WT_LOW_END=1
		fi
	else
		WT_LOW_END=1
	fi

	if [ "${WT_LOW_END}" == "1" ];then
		WT_XRAY_THREADS=1
		WT_SSR_THREADS=1
		WT_XRAY_BATCH_SIZE=1
		if [ "$(nvram get odmpid)" == "RT-AX89X" ];then
			WT_XRAY_THREADS=4
			WT_SSR_THREADS=2
			WT_XRAY_BATCH_SIZE=4
		fi
	else
		if [ "${WT_CPU_CORES}" -ge 3 -a "${WT_MEM_MB}" -ge 1024 ];then
			# aarch64 4cores + 2G内存
			WT_XRAY_THREADS=8
			WT_SSR_THREADS=4
			WT_XRAY_BATCH_SIZE=8
		else
			# aarch64 4cores + 1G内存
			WT_XRAY_THREADS=4
			WT_SSR_THREADS=2
			WT_XRAY_BATCH_SIZE=4
		fi
	fi
}

ensure_latency_batch(){
	if [ -z "${ss_basic_latency_batch}" ];then
		detect_perf
		if [ "${WT_LOW_END}" == "1" ];then
			dbus set ss_basic_latency_batch="0"
			ss_basic_latency_batch="0"
		else
			dbus set ss_basic_latency_batch="1"
			ss_basic_latency_batch="1"
		fi
	fi
}

update_webtest_file(){
	local snapshot_file="${TMP2}/webtest.snapshot"

	rm -f "${snapshot_file}"
	if [ "${WT_SINGLE}" == "1" ];then
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > "${snapshot_file}"
		cat "${snapshot_file}" >> "${WT_WEBTEST_FILE}"
	else
		find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > "${snapshot_file}"
		wt_write_webtest_snapshot "${snapshot_file}"
	fi
	rm -f "${snapshot_file}"
}

get_webtest_usable_count(){
	local webtest_file="$1"
	[ -f "${webtest_file}" ] || {
		echo 0
		return 0
	}
	awk -F '>' '
		$1 != "stop" && ($2 == "failed" || $2 == "timeout" || $2 == "ns" || $2 ~ /^[0-9]+$/) {count++}
		END {print count + 0}
	' "${webtest_file}" 2>/dev/null
}

# ----------------------------------------------------------------------
# webtest
# 0: ss: ss, ss + simpple obfs, ss + v2ray plugin
# 1: ssr
# 3: v2ray
# 4: xray
# 5: trojan
# 6: naive

# 1. 先分类，ss分4类（ss, ss+simple, ss+v2ray, ss2022），ssr一类，v2ray + xray + trojan一类，naive一类，总共7类
# 2. 按照类别分别进行测试，而不是按照节点顺序测试，这样可以避免v2ray，xray等线程过多导致路由器资源耗尽，每个类的线程数不一样
# 3. 每个类别的测试，不同机型给到不同的线程数量，比如RT-AX56U_V2这种小内存机器，给一个线程即可
# 4. ss测试需要判断加密方式是否为2022AEAD，如果是，则需要判断是否存在sslocal，（不存在则返回不支持）
# 4. ss测试需要判断是否启用了插件，如果是v2ray-plugin插件，则测试线程应该降低，fancyss_lite不测试（返回不支持）
# 5. v2ray的配置文件（一般为vmess）由xray进行测试，因为fancyss_lite不带v2ray二进制
# 6. 二进制启动目标为开socks5端口，然后用curl通过该端口进行落地延迟测试
# 7. ss ssr这类以开多个二进制来增加线程，xray测试则使用一个线程 + 开多个socks5端口的配置文件来进行测试
# 8. 运行测试的时候，需要将各个二进制改名后运行，以免ssconfig.sh的启停将某个测试进程杀掉

webtest_web(){
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		http_response "batch_disabled"
		return 0
	fi
	# 1. 如果没有结果文件，需要去获取webtest
	if [ ! -f "${WT_WEBTEST_FILE}" ];then
		local backup_usable=$(get_webtest_usable_count "${WT_WEBTEST_BACKUP}")
		if [ "${backup_usable}" -gt "0" ];then
			cp -f "${WT_WEBTEST_BACKUP}" "${WT_WEBTEST_FILE}" >/dev/null 2>&1
			http_response "ok3, partial cache exists, keep it"
			return 0
		fi
		clean_webtest
		start_webtest
		return 0
	fi

	# 2. 如果有结果文件，且lock 存在，说明正在webtest，那么告诉web自己去拿结果吧
	if [ -f "/tmp/webtest.lock" ];then
		http_response "ok1, lock exist, webtest is running..."
		return 0
	fi

	# 3. 如果有结果该文件，且没有lock（webtest完成了的），需要检测下节点数量和webtest数量是否一致，避免新增节点没有webtest
	local webtest_nu=$(cat "${WT_WEBTEST_FILE}" | awk -F ">" '{print $1}' | sort -un | sed '/stop/d' | wc -l)
	local node_nu=$(wt_node_count)
	if [ "${webtest_nu}" -ne "${node_nu}" ];then
		local backup_usable=$(get_webtest_usable_count "${WT_WEBTEST_BACKUP}")
		if [ "${backup_usable}" -gt "0" ];then
			cp -f "${WT_WEBTEST_BACKUP}" "${WT_WEBTEST_FILE}" >/dev/null 2>&1
			http_response "ok3, partial cache exists, keep it"
			return 0
		fi
		clean_webtest
		start_webtest
		return 0
	fi

	# 4. 如果有结果该文件，且没有lock（webtest完成了的），且节点数和webtest结果数一致，比较下上次webtest结果生成的时间，如果是15分钟以内，则不需要重新webtest
	TS_LST=$(/bin/date -r "${WT_WEBTEST_FILE}" "+%s")
	TS_NOW=$(/bin/date +%s)
	TS_DUR=$((${TS_NOW} - ${TS_LST}))
	if [ "${TS_DUR}" -lt "1800" ];then
		http_response "ok2, webtest result in 30min, do not refresh!"
	else
		clean_webtest
		start_webtest
	fi
}

start_webtest(){
	# create lock
	touch /tmp/webtest.lock
	WT_SINGLE=0
	WT_SKIP_DNS=0
	WT_PREVIEW_READY=0
	wt_reset_webtest_output
	
	# 1. prepare
	mkdir -p ${TMP2}
	rm -rf ${TMP2}/*
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	ln -sf /koolshare/bin/curl-fancyss ${TMP2}/curl-webtest
	wt_prepare_node_cache >/dev/null 2>&1

	# 2. 分类
	sort_nodes
	wt_prepare_webtest_preview

	# 3. 批量测速前，同步全量节点域名直连解析缓存
	wt_refresh_node_direct_dns_if_needed
	ensure_latency_batch

	# 4. 测试
	test_nodes

	# 5. remove lock
	rm -rf /tmp/webtest.lock
}

sort_nodes(){
	# 1.给所有节点分类
	# 00_01 ss 
	# 00_02 ss + obfs
	# 00_03 ss + v2ray					# deprecated since 3.3.6
	# 00_04 ss2022
	# 00_05 ss2022 + obfs
	# 00_06 ss2022 + v2ray				# deprecated since 3.3.6
	# 01 ssr
	# 02 koolgame (deleted in 3.0.4)
	# 03 v2ray
	# 04 xray
	# 05 trojan
	# 06 naive
	# 07 tuic
	# 08 hysteria2

	# sort by type first
	local count=1
	local prev_type=""
	local group_file=""
	local group_prefix=""
	local ss_variant=""
	local ss_2022=""
	local _obfs_enable=""
	wt_build_nodes_index || return 1
	while IFS='|' read node_id node_type ss_obfs ss_method
	do
		[ -z "${node_id}" ] && continue
		[ -z "${node_type}" ] && continue
		if [ "${node_type}" != "${prev_type}" ];then
			group_prefix="${TMP2}/wt_${count}_${node_type}"
			if [ "${node_type}" != "00" ];then
				group_file="${group_prefix}.txt"
				: > "${group_file}"
			fi
			count=$((count + 1))
			prev_type="${node_type}"
		fi
		if [ "${node_type}" = "00" ];then
			if [ -z "${ss_obfs}" -o "${ss_obfs}" = "0" ];then
				_obfs_enable="0"
			else
				_obfs_enable="1"
			fi
			ss_2022=$(echo ${ss_method} | grep "2022-blake")
			if [ -z "${ss_2022}" ];then
				if [ "${_obfs_enable}" = "0" ];then
					ss_variant="01"
				else
					ss_variant="02"
				fi
			else
				if [ "${_obfs_enable}" = "0" ];then
					ss_variant="04"
				else
					ss_variant="05"
				fi
			fi
			group_file="${group_prefix}_${ss_variant}.txt"
			[ -f "${group_file}" ] || : > "${group_file}"
		fi
		echo "${node_id}" >> "${group_file}"
	done < ${TMP2}/nodes_index.txt
}

test_nodes(){
	# define
	LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
	detect_perf

	# 优先测试当前节点及其附近的同类型节点，重排生成节点序号储存文件
	local CURR_NODE=$(fss_get_current_node_id)
	[ -z "${CURR_NODE}" ] && CURR_NODE=$(fss_get_first_node_id)
	local CURR_FILE=""
	local CURR_FILE_NAME=""
	local FIRST_EFFECTIVE_FILE=""
	local FIRST_EFFECTIVE_NAME=""
	local FIRST_EFFECTIVE_TYPE=""
	local PREVIEW_FILE=""
	local PREVIEW_TYPE=""
	local XRAY_GROUP_FILE="${TMP2}/wt_xray_group.txt"
	local XRAY_GROUP_NAME="wt_xray_group.txt"
	MAX_SHOW=$(dbus get ss_basic_row)
	if [ "${MAX_SHOW}" -gt "1" ];then 
		BEGN_NODE=$(awk -v x=${CURR_NODE} -v y=${MAX_SHOW} 'BEGIN { printf "%.0f\n", (x-y/2)}')
	else
		BEGN_NODE=$((${CURR_NODE} - 10))
	fi

	CURR_FILE=$(find ${TMP2}/ -name "wt_*.txt" | xargs grep -Ew "^${CURR_NODE}" | awk -F ":" '{print $1}')
	if [ -f "${CURR_FILE}" ];then
		local FIRST_BGN=$(cat ${CURR_FILE}|sed -n '1p')
		if [ -f "${CURR_FILE}" -a "${BEGN_NODE}" -gt "${FIRST_BGN}" ];then
			sed -n "/${BEGN_NODE}/,\$p" ${CURR_FILE} > ${TMP2}/re-arrange-1.txt 
			sed -n "1,/^${BEGN_NODE}\$/p" ${CURR_FILE} | sed '$d' > ${TMP2}/re-arrange-2.txt
			cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${CURR_FILE}
			rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
		fi
	fi

	# 优先测试当前节点所属的节点类型
	wt_list_group_files | while read file_name
	do
		[ -n "${file_name}" ] || continue
		echo "${TMP2}/${file_name}"
	done > ${TMP2}/nodes_file_name.txt
	CURR_FILE_NAME=${CURR_FILE##*/}
	CURR_FILE_NAME=${CURR_FILE_NAME%%.*}
	local CURR_LINE=$(sed -n "/${CURR_FILE_NAME}/=" ${TMP2}/nodes_file_name.txt)
	[ -n "${CURR_LINE}" ] || CURR_LINE=1
	if [ "${CURR_LINE}" -gt "1" ];then
		sed -n "${CURR_LINE},\$p" ${TMP2}/nodes_file_name.txt > ${TMP2}/nodes_file_name-1.txt
		sed -n "1,${CURR_LINE}p" ${TMP2}/nodes_file_name.txt | sed '$d' > ${TMP2}/nodes_file_name-2.txt
		cat ${TMP2}/nodes_file_name-1.txt ${TMP2}/nodes_file_name-2.txt > ${TMP2}/nodes_file_name.txt
		rm -f ${TMP2}/nodes_file_name-1.txt ${TMP2}/nodes_file_name-2.txt	
	fi
	
	#echo CURR_LINE $CURR_LINE
	#echo CURR_FILE $CURR_FILE
	#echo BEGN_NODE $BEGN_NODE

	# merge all xray-core capable nodes into one file for batch testing
	rm -rf ${XRAY_GROUP_FILE}
	wt_list_group_files | while read xfile_name; do
		[ -n "${xfile_name}" ] || continue
		local xfile="${TMP2}/${xfile_name}"
		local xnode_type=${xfile_name#wt_*_}
		local xnode_type=${xnode_type%%.*}
		case ${xnode_type} in
		00_01|00_02|00_04|00_05|03|04|05|08)
			cat ${xfile} >> ${XRAY_GROUP_FILE}
			;;
		esac
	done
	if [ -s "${XRAY_GROUP_FILE}" ];then
		local XR_CURR=$(grep -Ew "^${CURR_NODE}$" ${XRAY_GROUP_FILE})
		if [ -n "${XR_CURR}" ];then
			local XR_FIRST=$(cat ${XRAY_GROUP_FILE} | sed -n '1p')
			if [ "${BEGN_NODE}" -gt "${XR_FIRST}" ];then
				sed -n "/${BEGN_NODE}/,\$p" ${XRAY_GROUP_FILE} > ${TMP2}/re-arrange-1.txt
				sed -n "1,/^${BEGN_NODE}\$/p" ${XRAY_GROUP_FILE} | sed '$d' > ${TMP2}/re-arrange-2.txt
				cat ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt > ${XRAY_GROUP_FILE}
				rm -rf ${TMP2}/re-arrange-1.txt ${TMP2}/re-arrange-2.txt
			fi
		fi
	fi

	if [ "${WT_PREVIEW_READY}" != "1" ];then
		wt_reset_webtest_output
		http_response "ok4, webtest.txt generating..."
		FIRST_EFFECTIVE_FILE=$(sed -n '1p' ${TMP2}/nodes_file_name.txt)
		FIRST_EFFECTIVE_NAME=${FIRST_EFFECTIVE_FILE##*/}
		FIRST_EFFECTIVE_TYPE=${FIRST_EFFECTIVE_NAME#wt_*_}
		FIRST_EFFECTIVE_TYPE=${FIRST_EFFECTIVE_TYPE%%.*}
		if wt_group_type_is_xray_like "${FIRST_EFFECTIVE_TYPE}" && [ -s "${XRAY_GROUP_FILE}" ];then
			PREVIEW_FILE="${XRAY_GROUP_FILE}"
			PREVIEW_TYPE="${FIRST_EFFECTIVE_TYPE}"
		else
			PREVIEW_FILE="${FIRST_EFFECTIVE_FILE}"
			PREVIEW_TYPE="${FIRST_EFFECTIVE_TYPE}"
		fi
		wt_show_current_group_preview "${PREVIEW_FILE}" "${PREVIEW_TYPE}"
	fi
	
	local xray_group_done=0
	cat ${TMP2}/nodes_file_name.txt | while read test_file
	do
		local file_name=${test_file##*/}
		local node_type=${file_name#wt_*_}
		local node_type=${node_type%%.*}
		local pref_name=${file_name%_*}

		#echo -----------------
		#echo test_file $test_file
		#echo file_name $file_name
		#echo node_type $node_type
		#echo pref_name $pref_name
		#echo -----------------
		# 00_01 ss
		# 00_02 ss + obfs
		# 00_03 ss + v2ray					# deprecated since 3.3.6
		# 00_04 ss2022
		# 00_05 ss2022 + obfs
		# 00_06 ss2022 + v2ray				# deprecated since 3.3.6
		# 01 ssr
		# 02 koolgame (deleted in 3.0.4)
		# 03 v2ray
		# 04 xray
		# 05 trojan
		# 06 naive
		# 07 tuic
		# 08 hysteria2
		case $node_type in
		00_01|00_02|00_04|00_05|03|04|05|08)
			if [ "${xray_group_done}" != "1" -a -s "${XRAY_GROUP_FILE}" ];then
				test_xray_group ${XRAY_GROUP_NAME} xg
				xray_group_done=1
			fi
			;;
		01)
			test_07_sr $file_name $node_type
			;;
		06)
			test_11_nv $file_name $node_type
			;;
		07)
			test_12_tc $file_name $node_type
			;;
		esac
	done
	
	# finish mark
	find ${TMP2}/results/ -name "*.txt" | sort -t "/" -nk5 | xargs cat > "${WT_WEBTEST_FILE}"
	wt_append_webtest_line "stop>stop"

	# record timestamp
	local TS_LOG=$(date -r "${WT_WEBTEST_FILE}" "+%Y/%m/%d %X")
	dbus set ss_basic_webtest_ts="${TS_LOG}"

	# copy webtest.txt for other useage
	cp -rf "${WT_WEBTEST_FILE}" "${WT_WEBTEST_BACKUP}"

	# we shold remove test tmp file
	
}

test_xray_group(){
	# test nodes by single xray instance
	local file=$1
	local mark=$2
	local batch_size=""
	local file_path=""
	[ -z "${WT_XRAY_THREADS}" ] && WT_XRAY_THREADS=1
	case "${file}" in
	/*)
		file_path="${file}"
		;;
	*)
		file_path="${TMP2}/${file}"
		;;
	esac
	[ ! -f "${file_path}" ] && return 0
	local count=$(cat ${file_path} | wc -l)
	[ "${count}" -lt 1 ] && return 0
	batch_size="${WT_XRAY_BATCH_SIZE}"
	[ -n "${batch_size}" ] || batch_size="${WT_XRAY_THREADS}"
	if [ "${batch_size}" -lt "${WT_XRAY_THREADS}" ];then
		batch_size="${WT_XRAY_THREADS}"
	fi
	if [ "${count}" -gt "${batch_size}" ];then
		local chunk_dir="${TMP2}/chunks_${mark}"
		local chunk_idx=0
		mkdir -p "${chunk_dir}"
		rm -f "${chunk_dir}"/*.txt
		awk -v n="${batch_size}" -v dir="${chunk_dir}" '
			{
				file = sprintf("%s/chunk_%03d.txt", dir, int((NR - 1) / n) + 1);
				print > file;
			}
		' ${file_path}
		for chunk_file in $(find "${chunk_dir}" -name "chunk_*.txt" | sort)
		do
			chunk_idx=$((chunk_idx + 1))
			test_xray_group "${chunk_file}" "${mark}_${chunk_idx}"
		done
		rm -rf "${chunk_dir}"
		return 0
	fi
	local JQ_BIN="/koolshare/bin/jq"
	if [ ! -x "${JQ_BIN}" ];then
		JQ_BIN="$(command -v jq 2>/dev/null)"
	fi
	[ -z "${JQ_BIN}" ] && JQ_BIN="/usr/bin/jq"

	# show info to web as soon as possible
	cat ${file_path} | xargs -n ${WT_XRAY_THREADS} | sed -n '1p' | while read nus; do
		for nu in $nus; do
			wt_append_webtest_line "${nu}>testing..."
		done
	done

	# prepare
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	ln -sf /koolshare/bin/xray ${TMP2}/wt-xray
	ln -sf /koolshare/bin/obfs-local ${TMP2}/wt-obfs
	mkdir -p ${TMP2}/conf_${mark}
	mkdir -p ${TMP2}/json_${mark}
	mkdir -p ${TMP2}/bash_${mark}
	mkdir -p ${TMP2}/logs_${mark}
	rm -rf ${TMP2}/conf_${mark}/*
	rm -rf ${TMP2}/json_${mark}/*
	rm -rf ${TMP2}/bash_${mark}/*
	rm -rf ${TMP2}/logs_${mark}/*
	rm -f ${TMP2}/socsk5_ports.txt

	# gen xray json for all nodes
	cat ${file_path} | while read nu; do
		local node_type=$(wt_node_get type ${nu})
		case ${node_type} in
		0)
			wt_gen_ss_outbound ${nu} ${mark}
			;;
		3)
			wt_gen_vmess_outbound ${nu} ${mark}
			;;
		4)
			wt_gen_vless_outbound ${nu} ${mark}
			;;
		5)
			wt_gen_trojan_outbound ${nu} ${mark}
			;;
		8)
			wt_gen_hy2_outbound ${nu} ${mark}
			;;
		esac
		wt_write_inbound_routing ${nu} ${mark}
	done

	# merge all xray json
	find ${TMP2}/conf_${mark} -name "*_inbounds.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{ inbounds: [ inputs.inbounds[0] ] }' >${TMP2}/json_${mark}/00_inbounds.json
	find ${TMP2}/conf_${mark} -name "*_outbounds.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{ outbounds: [ inputs.outbounds[0] ] }' >${TMP2}/json_${mark}/01_outbounds.json
	find ${TMP2}/conf_${mark} -name "*_routing.json" | sort -t "/" -nk5 | xargs cat | run ${JQ_BIN} -n '{routing: { rules: [ inputs.routing.rules[0] ] }}' >${TMP2}/json_${mark}/02_routing.json
	if [ ! -s "${TMP2}/json_${mark}/00_inbounds.json" -o ! -s "${TMP2}/json_${mark}/01_outbounds.json" -o ! -s "${TMP2}/json_${mark}/02_routing.json" ];then
		cat ${file_path} | while read nu; do
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
		done
		update_webtest_file
		return 0
	fi

	# now we can start xray to host multiple outbounds
	run ${TMP2}/wt-xray run -confdir ${TMP2}/json_${mark}/ >${TMP2}/logs_${mark}/log.txt 2>&1 &
	local xray_pid=$!

	# make sure xray is runing, otherwise output error
	wait_program2 wt-xray ${TMP2}/logs_${mark}/log.txt started
	if ! pidof wt-xray >/dev/null 2>&1;then
		cat ${file_path} | while read nu; do
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
			wt_append_webtest_file "${TMP2}/results/${nu}.txt"
		done
		update_webtest_file
		return 0
	fi

	if [ -f "${TMP2}/socsk5_ports.txt" ];then
		eval $(cat ${TMP2}/socsk5_ports.txt)
	fi

	# test in multiple process (FIFO semaphore)
	local count=$(cat ${file_path} | wc -l)
	[ "${count}" -lt 1 ] && return 0
	if [ "${WT_XRAY_THREADS}" -gt "${count}" ];then
		WT_XRAY_THREADS=${count}
	fi

	local fifo="${TMP2}/fd1_${mark}"
	[ -e "${fifo}" ] || mknod "${fifo}" p
	exec 3<>"${fifo}"
	rm -f "${fifo}"

	local i=0
	while [ ${i} -lt ${WT_XRAY_THREADS} ]; do
		echo >&3
		i=$((i+1))
	done

	local pids=""
	while read -r nu; do
		[ -z "${nu}" ] && continue
		read -r _ <&3
		{
			trap 'echo >&3' EXIT
			# 0. testing info
			wt_append_webtest_line "${nu}>testing..."

			# 1. start obfs-local if needed
			if [ -x "${TMP2}/bash_${mark}/start_${nu}.sh" ];then
				sh ${TMP2}/bash_${mark}/start_${nu}.sh
			fi

			# 2. start curl test
			local socks5_port=$(eval echo \$socks5_port_${nu})
			if [ -z "${socks5_port}" ];then
				echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
				# 4. update result to web file
				wt_append_webtest_file "${TMP2}/results/${nu}.txt"
				exit 0
			fi
			curl_test ${nu} ${socks5_port}

			# 3. stop obfs-local if needed
			if [ -x "${TMP2}/bash_${mark}/stop_${nu}.sh" ];then
				sh ${TMP2}/bash_${mark}/stop_${nu}.sh
			fi

			# 4. update result to web file
			if [ -f "${TMP2}/results/${nu}.txt" ];then
				wt_append_webtest_file "${TMP2}/results/${nu}.txt"
			fi
		} &
		pids="${pids} $!"
	done < ${file_path}
	if [ -n "${pids}" ]; then
		wait ${pids}
	fi

	exec 3<&-
	exec 3>&-

	# finished kill xray
	if [ -n "${xray_pid}" ]; then
		kill ${xray_pid} >/dev/null 2>&1
	fi
	killall wt-xray >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1

	# finished
	rm -rf ${TMP2}/wt-xray
	rm -rf ${TMP2}/wt-obfs
}

test_07_sr(){
	local file=$1
	local mark=$2
	
	# alisa binary
	killall wt-rss-local >/dev/null 2>&1
	ln -sf /koolshare/bin/rss-local ${TMP2}/wt-rss-local
	mkdir -p ${TMP2}/conf_${mark}
	rm -rf ${TMP2}/conf_${mark}/*

	cat ${TMP2}/${file} | xargs -n 8 | while read nus; do
		for nu in $nus; do
			{
				# 0. testing info
				wt_append_webtest_line "${nu}>testing..."
				
				# 1. resolve server
				local _server_ip=$(_get_server_ip $(wt_node_get server ${nu}))
				if [ -z "${_server_ip}" ];then
					# use domain
					_server_ip=$(wt_node_get server ${nu})
				fi

				# 2. gen json conf
				local socks5_port=$(get_rand_port)
				cat >${TMP2}/conf_${mark}/${nu}.json <<-EOF
					{
					    "server":"${_server_ip}",
					    "server_port":$(wt_node_get port ${nu}),
					    "local_address":"0.0.0.0",
					    "local_port":${socks5_port},
					    "password":"$(wt_node_get password ${nu} | base64_decode)",
					    "timeout":600,
					    "protocol":"$(wt_node_get rss_protocol ${nu})",
					    "protocol_param":"$(wt_node_get rss_protocol_param ${nu})",
					    "obfs":"$(wt_node_get rss_obfs ${nu})",
					    "obfs_param":"$(wt_node_get rss_obfs_param ${nu})",
					    "method":"$(wt_node_get method ${nu})"
					}
				EOF

				# 3. start rss-local
				run ${TMP2}/wt-rss-local -c ${TMP2}/conf_${mark}/${nu}.json -f ${TMP2}/pids/${nu}.pid >/dev/null 2>&1
				sleep 1

				# 4. start curl test
				curl_test ${nu} ${socks5_port}
				if [ -f "${TMP2}/results/${nu}.txt" ];then
					wt_append_webtest_file "${TMP2}/results/${nu}.txt"
				fi

				# 5. stop rss-local
				if [ -f "${TMP2}/pids/${nu}.pid" ];then
					kill -9 $(cat ${TMP2}/pids/${nu}.pid) >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		update_webtest_file
	done

	rm -rf ${TMP2}/wt-ss-local
}

test_11_nv(){
	local file=$1

	# alisa binary
	ln -sf /koolshare/bin/naive ${TMP2}/wt-naive
	killall wt-naive >/dev/null 2>&1

	cat ${TMP2}/${file} | xargs -n 1 | while read nus; do
		for nu in $nus; do
			{
				wt_append_webtest_line "${nu}>testing..."

				# 1. resolve server
				local _server_ip=$(_get_server_ip $(wt_node_get naive_server ${nu}))

				# 2. start naiveproxy
				local socks5_port=$(get_rand_port)
				if [ -z "${_server_ip}" ];then
					run ${TMP2}/wt-naive --listen=socks://127.0.0.1:${socks5_port} --proxy=$(wt_node_get naive_prot ${nu})://$(wt_node_get naive_user ${nu}):$(wt_node_get naive_pass ${nu} | base64_decode)@$(wt_node_get naive_server ${nu}):$(wt_node_get naive_port ${nu}) >/dev/null 2>&1 &
				else
					run ${TMP2}/wt-naive --listen=socks://127.0.0.1:${socks5_port} --proxy=$(wt_node_get naive_prot ${nu})://$(wt_node_get naive_user ${nu}):$(wt_node_get naive_pass ${nu} | base64_decode)@$(wt_node_get naive_server ${nu}):$(wt_node_get naive_port ${nu}) --host-resolver-rules="MAP $(wt_node_get naive_server ${nu}) ${_server_ip}" >/dev/null 2>&1 &
				fi

				sleep 2

				# 4. start curl test
				curl_test ${nu} ${socks5_port}
				if [ -f "${TMP2}/results/${nu}.txt" ];then
					wt_append_webtest_file "${TMP2}/results/${nu}.txt"
				fi

				# 5. stop naive
				local _pid=$(ps | grep wt-naive | grep ${socks5_port} | awk '{print $1}')
				if [ -n "${_pid}" ];then
					kill -9 ${_pid} >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		update_webtest_file
	done
	
	killall wt-naive >/dev/null 2>&1
	rm -rf ${TMP2}/wt-naive
}

test_12_tc(){
	local file=$1

	# alisa binary
	ln -sf /koolshare/bin/tuic-client ${TMP2}/wt-tuic
	killall wt-tuic >/dev/null 2>&1

	cat ${TMP2}/${file} | xargs -n 1 | while read nus; do
		for nu in $nus; do
			{
				wt_append_webtest_line "${nu}>testing..."

				# 1. gen json
				local socks5_port=$(get_rand_port)
				local new_addr="127.0.0.1:${socks5_port}"
				local tuic_json_file="${TMP2}/conf/tuic-${socks5_port}.json"
				local relay_server_raw=""
				local relay_host=""
				local relay_ip=""
				wt_node_get tuic_json ${nu} | base64_decode | run jq --arg addr "$new_addr" '.local.server = $addr' >${tuic_json_file}
				relay_server_raw=$(cat ${tuic_json_file} | run jq -r '.relay.server // empty' 2>/dev/null)
				{
					read -r relay_host
					read -r _
				} <<-EOF
				$(fss_extract_tuic_server_host_port "${relay_server_raw}")
				EOF
				relay_ip=$(_get_server_ip "${relay_host}")
				if [ -n "${relay_ip}" ];then
					cat ${tuic_json_file} | run jq --arg ip "${relay_ip}" '.relay.ip = $ip' | run sponge ${tuic_json_file}
				else
					cat ${tuic_json_file} | run jq 'del(.relay.ip)' | run sponge ${tuic_json_file}
				fi

				# 2. start tuic
				run ${TMP2}/wt-tuic -c ${tuic_json_file} >/dev/null 2>&1 &

				sleep 2

				# 4. start curl test
				curl_test ${nu} ${socks5_port}
				if [ -f "${TMP2}/results/${nu}.txt" ];then
					wt_append_webtest_file "${TMP2}/results/${nu}.txt"
				fi

				# 5. stop tuic
				local _pid=$(ps | grep "wt-tuic" | grep -v grep | grep ${socks5_port} | awk '{print $1}')
				if [ -n "${_pid}" ];then
					kill -9 ${_pid} >/dev/null 2>&1
				fi
			} &
		done
		wait

		# merge all curl test result
		update_webtest_file
	done
	
	killall wt-tuic >/dev/null 2>&1
	rm -rf ${TMP2}/wt-tuic
}

creat_trojan_json(){
	local nu=$1
	local trojan_server=$(wt_node_get server ${nu})
	local trojan_port=$(wt_node_get port ${nu})
	local trojan_uuid=$(wt_node_get trojan_uuid ${nu})
	local trojan_sni=$(wt_node_get trojan_sni ${nu})
	local trojan_ai=$(wt_node_get trojan_ai ${nu})
	local trojan_ai_global=$(dbus get ss_basic_tjai${nu})
	if [ "${trojan_ai_global}" == "1" ];then
		local trojan_ai="1"
	fi
	local trojan_tfo=$(wt_node_get trojan_tfo ${nu})
	local _server_ip=$(_get_server_ip ${trojan_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${trojan_server}
	fi

	
	# outbounds area
	cat >>${TMP2}/conf/${nu}_outbounds.json <<-EOF
		{
		"outbounds": [
			{
				"tag": "proxy${nu}",
				"protocol": "trojan",
				"settings": {
					"servers": [{
					"address": "${_server_ip}",
					"port": ${trojan_port},
					"password": "${trojan_uuid}"
					}]
				},
				"streamSettings": {
					"network": "tcp",
					"security": "tls",
					"tlsSettings": {
						"serverName": $(get_value_null ${trojan_sni}),
						"allowInsecure": $(get_function_switch ${trojan_ai})
    				}
    				,"sockopt": {"tcpFastOpen": $(get_function_switch ${trojan_tfo})}
    			}
  			}
  		]
  		}
	EOF
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf/${nu}_outbounds.json
	fi
	# inbounds
	local socks5_port=$(get_rand_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >>${TMP2}/conf/${nu}_inbounds.json <<-EOF
		{
		  "inbounds": [
		    {
		      "port": ${socks5_port},
		      "protocol": "socks",
		      "settings": {
		        "auth": "noauth",
		        "udp": true
		      },
		      "tag": "socks${nu}"
		    }
		  ]
		}
	EOF
	# routing
	cat >>${TMP2}/conf/${nu}_routing.json <<-EOF
		{
		  "routing": {
		    "rules": [
		      {
		        "type": "field",
		        "inboundTag": ["socks${nu}"],
		        "outboundTag": "proxy${nu}"
		      }
		    ]
		  }
		}
	EOF
}

creat_hy2_yaml(){
	local nu=$1
	local mark=$2
	if [ -z "$(wt_node_get hy2_sni ${nu})" ];then
		__valid_ip_silent "$(wt_node_get hy2_server ${nu})"
		if [ "$?" != "0" ];then
			# not ip, should be a domain
			local hy2_sni=$(wt_node_get hy2_server ${nu})
		else
			local hy2_sni=""
		fi
	else
		local hy2_sni="$(wt_node_get hy2_sni ${nu})"
	fi

	local _server_ip=$(_get_server_ip $(wt_node_get hy2_server ${nu}))
	if [ -z "${_server_ip}" ];then
		# use domain
		_server_ip=$(wt_node_get hy2_server ${nu})
		#echo -en "${nu}:\t解析失败！\n"
		#continue
	fi

	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		server: ${_server_ip}:$(wt_node_get hy2_port ${nu})
		
		auth: $(wt_node_get hy2_pass ${nu})

		tls:
		  sni: ${hy2_sni}
		  insecure: $(get_function_switch $(wt_node_get hy2_ai ${nu}))
		
		fastOpen: $(get_function_switch $(wt_node_get hy2_tfo ${nu}))
		
	EOF
	
	if [ -n "$(wt_node_get hy2_up ${nu})" -o -n "$(wt_node_get hy2_dl ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			bandwidth: 
			  up: $(wt_node_get hy2_up ${nu}) mbps
			  down: $(wt_node_get hy2_dl ${nu}) mbps
			
		EOF
	fi

	if [ "$(wt_node_get hy2_obfs ${nu})" == "1" -a -n "$(wt_node_get hy2_obfs_pass ${nu})" ];then
		cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
			obfs:
			  type: salamander
			  salamander:
			    password: "$(wt_node_get hy2_obfs_pass ${nu})"
			
		EOF
	fi

	local socks5_port=$(get_rand_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >> ${TMP2}/conf_${mark}/${nu}.yaml <<-EOF
		transport:
		  udp:
		    hopInterval: 30s
		
		socks5:
		  listen: 127.0.0.1:${socks5_port}
	EOF
}

curl_test(){
	local nu=$1
	local port=$2
	local tdir="${TMP2}/curl_${nu}"
	local series_cfg="${tdir}/series.cfg"
	local series_out="${tdir}/series.out"
	local retry_cfg="${tdir}/retry.cfg"
	local retry_out="${tdir}/retry.out"
	local history_ms=""
	local best_ms=""
	local has_timeout=0
	local inline_score2=0
	local proto="socks5h"
	local warm_timeout=3
	local score_timeout=3

	wt_get_history_latency(){
		local node_id="$1"
		[ -n "${node_id}" ] || return 0
		[ -f "${WT_WEBTEST_BACKUP}" ] || return 0
		awk -F '>' -v nu="${node_id}" '
			$1 == nu && $2 ~ /^[0-9]+$/ {lat=$2}
			END {
				if (lat != "") {
					print lat
				}
			}
		' "${WT_WEBTEST_BACKUP}" 2>/dev/null
	}

	wt_write_curl_transfer(){
		local cfg_file="$1"
		local tag="$2"
		local timeout_sec="$3"
		local add_next="$4"

		cat >>"${cfg_file}" <<-EOF
			silent
			head
			output = "/dev/null"
			proxy = "${proto}://127.0.0.1:${port}"
			connect-timeout = "${timeout_sec}"
			max-time = "${timeout_sec}"
			url = "${ss_basic_furl}"
			write-out = "${tag}|%{exitcode}|%{response_code}|%{time_total}\\n"
		EOF
		[ "${add_next}" = "1" ] && echo "next" >>"${cfg_file}"
	}

	wt_run_curl_series(){
		local cfg_file="$1"
		local out_file="$2"

		: >"${out_file}"
		run ${TMP2}/curl-webtest -q -K "${cfg_file}" >"${out_file}" 2>/dev/null
	}

	wt_get_series_field(){
		local out_file="$1"
		local tag="$2"
		local col="$3"
		[ -f "${out_file}" ] || return 1
		awk -F '|' -v t="${tag}" -v c="${col}" '
			$1 == t {
				print $c
				exit
			}
		' "${out_file}" 2>/dev/null
	}

	wt_series_timeout(){
		local out_file="$1"
		local tag="$2"
		local exitcode=""

		exitcode=$(wt_get_series_field "${out_file}" "${tag}" 2)
		[ "${exitcode}" = "28" ]
	}

	wt_series_result_ms(){
		local out_file="$1"
		local tag="$2"
		local exitcode=""
		local resp_code=""
		local ms=""

		exitcode=$(wt_get_series_field "${out_file}" "${tag}" 2)
		resp_code=$(wt_get_series_field "${out_file}" "${tag}" 3)
		[ "${exitcode}" = "0" ] || return 1
		[ "${resp_code}" = "200" -o "${resp_code}" = "204" ] || return 1
		ms=$(awk -F '|' -v t="${tag}" '
			$1 == t {
				printf "%.0f", $4 * 1000
				exit
			}
		' "${out_file}" 2>/dev/null)
		[ -n "${ms}" ] || return 1
		[ "${ms}" -le "5000" ] || {
			echo "timeout"
			return 0
		}
		echo "${ms}"
		return 0
	}

	wt_pick_better_ms(){
		local lhs="$1"
		local rhs="$2"
		if [ -z "${lhs}" ];then
			echo "${rhs}"
			return 0
		fi
		if [ -z "${rhs}" ];then
			echo "${lhs}"
			return 0
		fi
		if [ "${lhs}" = "timeout" ];then
			echo "${rhs}"
			return 0
		fi
		if [ "${rhs}" = "timeout" ];then
			echo "${lhs}"
			return 0
		fi
		if [ "${lhs}" -le "${rhs}" ];then
			echo "${lhs}"
		else
			echo "${rhs}"
		fi
	}

	wt_score_needs_retry(){
		local current_ms="$1"
		local prev_ms="$2"
		local limit_a=""
		local limit_b=""
		local limit=""

		[ -n "${current_ms}" ] || return 0
		[ "${current_ms}" = "timeout" ] && return 0
		[ -n "${prev_ms}" ] || return 0
		limit_a=$((prev_ms + 100))
		limit_b=$((prev_ms * 3 / 2))
		limit="${limit_a}"
		[ "${limit_b}" -gt "${limit}" ] && limit="${limit_b}"
		[ "${current_ms}" -gt "${limit}" ]
	}

	rm -rf ${tdir}
	mkdir -p ${tdir}
	history_ms=$(wt_get_history_latency "${nu}")

	if [ "${WT_SINGLE}" = "1" ];then
		# Manual single-node test prefers accuracy over total duration.
		inline_score2=1
	elif [ -z "${history_ms}" ];then
		# No historical baseline: take one extra scored sample and keep the better one.
		inline_score2=1
	fi

	: >"${series_cfg}"
	wt_write_curl_transfer "${series_cfg}" "warm" "${warm_timeout}" 1
	if [ "${inline_score2}" = "1" ];then
		wt_write_curl_transfer "${series_cfg}" "score1" "${score_timeout}" 1
		wt_write_curl_transfer "${series_cfg}" "score2" "${score_timeout}" 0
	else
		wt_write_curl_transfer "${series_cfg}" "score1" "${score_timeout}" 0
	fi
	wt_run_curl_series "${series_cfg}" "${series_out}"

	if wt_series_timeout "${series_out}" "warm";then
		has_timeout=1
	fi
	if wt_series_timeout "${series_out}" "score1";then
		has_timeout=1
	fi
	best_ms=$(wt_series_result_ms "${series_out}" "score1")

	if [ "${inline_score2}" = "1" ];then
		if wt_series_timeout "${series_out}" "score2";then
			has_timeout=1
		fi
		best_ms=$(wt_pick_better_ms "${best_ms}" "$(wt_series_result_ms "${series_out}" "score2")")
	elif wt_score_needs_retry "${best_ms}" "${history_ms}";then
		: >"${retry_cfg}"
		wt_write_curl_transfer "${retry_cfg}" "score2" "${score_timeout}" 0
		wt_run_curl_series "${retry_cfg}" "${retry_out}"
		if wt_series_timeout "${retry_out}" "score2";then
			has_timeout=1
		fi
		best_ms=$(wt_pick_better_ms "${best_ms}" "$(wt_series_result_ms "${retry_out}" "score2")")
	fi

	rm -rf ${tdir}

	if [ -n "${best_ms}" ];then
		if [ "${best_ms}" = "timeout" ];then
			echo -en "${nu}>timeout\n" >>${TMP2}/results/${nu}.txt
		else
			echo -en "${nu}>${best_ms}\n" >>${TMP2}/results/${nu}.txt
		fi
	else
		if [ "${has_timeout}" = "1" ];then
			echo -en "${nu}>timeout\n" >>${TMP2}/results/${nu}.txt
		else
			echo -en "${nu}>failed\n" >>${TMP2}/results/${nu}.txt
		fi
	fi
}

single_test_node(){
	local test_node="$1"
	if [ -z "${test_node}" ];then
		return 1
	fi

	WT_SINGLE=1
	WT_SKIP_DNS=0
	wt_refresh_node_direct_dns_if_needed
	detect_perf
	WT_XRAY_THREADS=1
	WT_SSR_THREADS=1

	mkdir -p ${TMP2}
	mkdir -p ${TMP2}/conf
	mkdir -p ${TMP2}/pids
	mkdir -p ${TMP2}/results
	rm -rf ${TMP2}/conf/*
	rm -rf ${TMP2}/pids/*
	rm -rf ${TMP2}/results/*
	ln -sf /koolshare/bin/curl-fancyss ${TMP2}/curl-webtest
	wt_prepare_node_cache >/dev/null 2>&1

	wt_append_webtest_line "${test_node}>testing..."

	local single_file="wt_single_${test_node}.txt"
	echo "${test_node}" > ${TMP2}/${single_file}
	local node_type=$(wt_node_get type ${test_node})
	case ${node_type} in
	0|3|4|5|8)
		test_xray_group ${single_file} xg
		;;
	1)
		test_07_sr ${single_file} single
		;;
	6)
		test_11_nv ${single_file}
		;;
	7)
		test_12_tc ${single_file}
		;;
	*)
		wt_append_webtest_line "${test_node}>failed"
		;;
	esac

	# 避免内部测速函数复用局部变量名后把原节点序号冲掉。
	update_single_backup "${test_node}"
	wt_append_webtest_line "stop>stop"
}

update_single_backup(){
	local nu="$1"
	[ -z "${nu}" ] && return 0
	local new_line=$(grep "^${nu}>" "${WT_WEBTEST_FILE}" | tail -n 1)
	[ -z "${new_line}" ] && return 0
	mkdir -p /tmp/upload ${TMP2}
	local tmp_file="${TMP2}/webtest_bakcup.tmp"
	: > ${tmp_file}
	if [ -f "${WT_WEBTEST_BACKUP}" ];then
		grep -v -E "^${nu}>|^stop>" "${WT_WEBTEST_BACKUP}" > ${tmp_file} || true
	else
		grep -v -E "^${nu}>|^stop>" "${WT_WEBTEST_FILE}" > ${tmp_file} || true
	fi
	echo "${new_line}" >> ${tmp_file}
	echo "stop>stop" >> ${tmp_file}
	mv -f ${tmp_file} "${WT_WEBTEST_BACKUP}"
}

_get_server_ip() {
	local SERVER_IP
	if [ "${WT_SKIP_DNS}" = "1" ];then
		SERVER_IP=$(__valid_ip $1)
		if [ -n "${SERVER_IP}" ]; then
			echo $SERVER_IP
		else
			echo $1
		fi
		return 0
	fi
	local domain1=$(echo "$1" | grep -E "^https://|^http://|/")
	local domain2=$(echo "$1" | grep -E "\.")
	if [ -n "${domain1}" -o -z "${domain2}" ]; then
		echo "$1 不是域名也不是ip" >>${TMP2}/webtest_log.txt
		echo ""
		return 2
	fi

	SERVER_IP=$(__valid_ip $1)
	if [ -n "${SERVER_IP}" ]; then
		echo "$1 已经是ip，跳过解析！" >>${TMP2}/webtest_log.txt
		echo $SERVER_IP
		return 0
	fi

	wt_server_resolv_mode_is_dynamic && {
		echo ""
		return 0
	}

	local ss_basic_server_resolv=$(dbus get ss_basic_server_resolv)
	[ -n "${ss_basic_server_resolv}" ] || ss_basic_server_resolv="-1"

	if [ "${ss_basic_server_resolv}" -le "0" ];then
		local count=0
		local current=$(dbus get ss_basic_lastru)
		if [ $(number_test ${current}) != "0" ];then
			if [ "${ss_basic_server_resolv}" == "0" ];then
				current=$(shuf -i 1-18 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				current=$(shuf -i 1-8 -n 1)
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				current=$(shuf -i 11-18 -n 1)
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "0" ];then
			if [ ${current} -gt 8 -a ${current} -lt 11 ];then
				current=11
			fi
			if [ ${current} -lt 1 -o ${current} -gt 18 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-1" ];then
			if [ ${current} -lt 1 -o ${current} -gt 8 ];then
				current=1
			fi
		fi
		if [ "${ss_basic_server_resolv}" == "-2" ];then
			if [ ${current} -lt 11 -o ${current} -gt 18 ];then
				current=11
			fi
		fi
		until [ ${count} -eq 18 ]; do
			SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${current}) -t 2 -i 1 @$(__get_server_resolver ${current}) $1 2>/dev/null | head -n1)
			__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
			if [ "$?" != "0" -a "$?" != "1" ]; then
				SERVER_IP=""
			fi
			if [ -n "${SERVER_IP}" -a "${SERVER_IP}" != "127.0.0.1" ]; then
				dbus set ss_basic_lastru=${current}
				break
			fi
			let current++
			if [ "${ss_basic_server_resolv}" == "0" ];then
				if [ ${current} -gt 8 -a ${current} -lt 11 ];then
					current=11
				fi
				if [ ${current} -lt 1 -o ${current} -gt 18 ];then
					current=1
				fi
			elif [ "${ss_basic_server_resolv}" == "-1" ];then
				if [ ${current} -lt 1 -o ${current} -gt 8 ];then
					current=1
				fi
			elif [ "${ss_basic_server_resolv}" == "-2" ];then
				if [ ${current} -lt 11 -o ${current} -gt 18 ];then
					current=11
				fi
			fi
			let count++
		done
	elif [ "${ss_basic_server_resolv}" == "99" ];then
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
	else
		SERVER_IP=$(run dnsclient -46 -p $(__get_server_resolver_port ${ss_basic_server_resolv}) -t 2 -i 1 @$(__get_server_resolver ${ss_basic_server_resolv}) $1 2>/dev/null | head -n1)
		__valid_ip46 "${SERVER_IP}" >/dev/null 2>&1
		if [ "$?" != "0" -a "$?" != "1" ]; then
			SERVER_IP=""
		fi
	fi

	# resolve failed
	if [ -z "${SERVER_IP}" ]; then
		#echo "$1 域名解析失败！" >>${TMP2}/webtest_log.txt
		echo ""
		return 1
	fi

	# resolve failed
	if [ "${SERVER_IP}" == "127.0.0.1" ]; then
		#echo "$1 解析结果为127.0.0.1，域名解析失败！" >>${TMP2}/webtest_log.txt
		echo ""
		return 1
	fi
	
	# success resolved
	#echo "$1 域名解析成功，解析结果：${SERVER_IP}" >>${TMP2}/webtest_log.txt
	echo $SERVER_IP
	return 0
}

__get_server_resolver() {
	local idx=$1
	local res
	# tcp/udp servers
	# ------------------ 国内 -------------------
	# 阿里dns
	[ "${idx}" == "1" ] && res="223.5.5.5"
	# DNSPod dns
	[ "${idx}" == "2" ] && res="119.29.29.29"
	# 114 dns
	[ "${idx}" == "3" ] && res="114.114.114.114"
	# oneDNS 拦截版
	[ "${idx}" == "4" ] && res="52.80.66.66"
	# 360安全DNS 电信/铁通/移动
	[ "${idx}" == "5" ] && res="218.30.118.6"
	# 360安全DNS 联通
	[ "${idx}" == "6" ] && res="123.125.81.6"
	# 清华大学TUNA DNS
	[ "${idx}" == "7" ] && res="101.6.6.6"
	# 百度DNS
	[ "${idx}" == "8" ] && res="180.76.76.76"
	# ------------------ 国外 -------------------
	# Google DNS
	[ "${idx}" == "11" ] && res="8.8.8.8"
	# Cloudflare DNS
	[ "${idx}" == "12" ] && res="1.1.1.1"
	# Quad9 Secured 
	[ "${idx}" == "13" ] && res="9.9.9.11"
	# OpenDNS
	[ "${idx}" == "14" ] && res="208.67.222.222"
	# DNS.SB
	[ "${idx}" == "15" ] && res="185.222.222.222"
	# AdGuard Default servers
	[ "${idx}" == "16" ] && res="94.140.14.14"
	# Quad 101 (TaiWan Province)
	[ "${idx}" == "17" ] && res="101.101.101.101"
	# CleanBrowsing
	[ "${idx}" == "18" ] && res="185.228.168.9"
	if [ "${idx}" == "99" ]; then
		local user_content=$(dbus get ss_basic_server_resolv_user)
		if [ -n "${user_content}" ];then
			local res_ip=$(echo "${user_content}"|awk -F"#|:" '{print $1}')
			local res_ip=$(__valid_ip ${res_ip})
			if [ -n "${res_ip}" ];then
				res="${res_ip}"
			else
				res="114.114.114.114"
			fi
		else
			res="114.114.114.114"
		fi
	fi
	echo ${res}
}

__get_server_resolver_port() {
	local idx=$1
	local res
	if [ "${idx}" == "99" ]; then
		local user_content=$(dbus get ss_basic_server_resolv_user)
		if [ -n "${user_content}" ];then
			local res_port=$(echo "${user_content}"|awk -F"#|:" '{print $2}')
			local res_port=$(__valid_port ${res_port})
			if [ -n "${res_port}" ];then
				res="${res_port}"
			else
				res="53"
			fi
		else
			res="53"
		fi
	elif [ "${idx}" == "7" -o "${idx}" == "14" ]; then
		res="5353"
	else
		res="53"
	fi
	echo ${res}
}

wait_program(){
	local BINNAME=$1
	local PID1
	local i=40
	until [ -n "${PID1}" ]; do
		usleep 250000
		i=$(($i - 1))
		PID1=$(pidof ${BINNAME})
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	usleep 500000
}

wait_program2(){
	local BINNAME=$1
	local LOGFILE=$2
	local CONTENT=$3
	local MATCH
	local PID1
	# wait for 4s
	local i=16
	# until [ -n "${PID1}" ]; do
	# 	usleep 250000
	# 	i=$(($i - 1))
	# 	PID1=$(pidof ${BINNAME})
	# 	if [ "$i" -lt 1 ]; then
	# 		return 1
	# 	fi
	# done
	
	until [ -n "${MATCH}" ]; do
		usleep 250000
		i=$(($i - 1))
		local MATCH=$(cat $LOGFILE 2>/dev/null | grep -w $CONTENT)
		if [ "$i" -lt 1 ]; then
			return 1
		fi
	done
	usleep 500000
	return 0
}

get_path_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"/\"]
	fi
}


get_host_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"\"]
	fi
}

get_function_switch() {
	case "$1" in
	1)
		echo "true"
		;;
	0 | *)
		echo "false"
		;;
	esac
}

get_grpc_multimode(){
	case "$1" in
	multi)
		echo true
		;;
	gun|*)
		echo false
		;;
	esac
}

get_ws_header() {
	if [ -n "$1" ]; then
		echo {\"Host\": \"$1\"}
	else
		echo null
	fi
}

get_host() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo null
	fi
}


get_value_null(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo null
	fi
}

get_value_empty(){
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo \"\"
	fi
}

clean_webtest(){
	# 当用户手动点击web test按钮的时候，不论是否有正在进行的任务，不论是否在在时限内，强制开始webtest
	# 1. killall program
	killall wt-ss >/dev/null 2>&1
	killall wt-ss-local >/dev/null 2>&1
	killall wt-obfs >/dev/null 2>&1
	killall wt-rss-local >/dev/null 2>&1
	killall wt-v2ray >/dev/null 2>&1
	killall wt-xray >/dev/null 2>&1
	killall wt-trojan >/dev/null 2>&1
	killall wt-naive >/dev/null 2>&1
	killall wt-tuic >/dev/null 2>&1
	killall wt-hy2 >/dev/null 2>&1
	killall curl-fancyss >/dev/null 2>&1
	killall curl-webtest >/dev/null 2>&1

	# 2. kill all other ss_webtest.sh
	local current_pid=$$
	local ss_webtest_pids=$(ps|grep -E "ss_webtest\.sh"|awk '{print $1}'|grep -v ${current_pid})
	if [ -n "${ss_webtest_pids}" ];then
		for ss_webtest_pid in ${ss_webtest_pids}
		do
			kill -9 ${ss_webtest_pid} >/dev/null 2>&1
		done
	fi

	# 3. remove lock file if exist
	rm -rf /tmp/webtest.lock >/dev/null 2>&1

	# 4. remove webtest result file
	rm -rf "${WT_WEBTEST_FILE}"
	rm -rf "${WT_WEBTEST_STREAM}"
	rm -rf ${TMP2}/*
}

set_latency_job() {
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ]; then
		echo_date "批量web延迟测试已关闭!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		return 0
	fi
	if [ "${ss_basic_lt_cru_opts}" == "0" ]; then
		echo_date "定时测试节点延迟未开启!"
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	elif [ "${ss_basic_lt_cru_opts}" == "1" ]; then
		echo_date "设置每隔${ss_basic_lt_cru_time}分钟对所有节点进行web延迟检测..."
		sed -i '/sslatencyjob/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
		cru a sslatencyjob "*/${ss_basic_lt_cru_time} * * * * /koolshare/scripts/ss_webtest.sh 2"
	fi
}

case $1 in
2)
	# start webtest by cron
	clean_webtest
	start_webtest
	;;
3)
	set_latency_job
	;;
esac


case $2 in
web_webtest)
	# 当用户进入插件，插件列表渲染好后开始调用本脚本进行webtest
	webtest_web
	;;
clear_webtest)
	if [ -f "/tmp/webtest.lock" ];then
		http_response "busy"
		exit 0
	fi
	http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	rm -f "${WT_WEBTEST_BACKUP}"
	;;
single_test)
	if [ -f "/tmp/webtest.lock" ];then
		http_response "busy"
		exit 0
	fi
	http_response $1
	single_test_node $3
	;;
manual_webtest)
	ensure_latency_batch
	if [ "${ss_basic_latency_batch}" != "1" ];then
		http_response "batch_disabled"
		exit 0
	fi
	clean_webtest
	rm -f "${WT_WEBTEST_BACKUP}"
	dbus remove ss_basic_webtest_ts
	http_response $1
	;;
close_latency_test)
	http_response $1
	clean_webtest
	dbus remove ss_basic_webtest_ts
	;;
0)
	http_response $1
	set_latency_job
	;;
1)
	# webtest foreign url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
	fi
	set_latency_job
	;;
2)
	# webtest china url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
3)
	# webtest foreign + china url changed
	http_response $1
	if [ "${ss_failover_enable}" == "1" ];then
		echo "${LOGTIME1} fancyss：切换国外web延迟检测地址为：${ss_basic_furl}" >>/tmp/upload/ssf_status.txt
		echo "${LOGTIME1} fancyss：切换国内web延迟检测地址为：${ss_basic_curl}" >>/tmp/upload/ssc_status.txt
	fi
	set_latency_job
	;;
esac
