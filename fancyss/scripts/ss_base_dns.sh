#!/bin/sh

# fancyss smartdns / airport dns lazy-loaded helpers

generate_smartdns_whitelist_file() {
	local outfile="$1"
	[ -n "${outfile}" ] || return 1
	: > "${outfile}"
	[ -f "/koolshare/ss/rules/chnroute.txt" ] && sed 's/^/whitelist-ip /g' /koolshare/ss/rules/chnroute.txt >> "${outfile}"
	[ -f "/koolshare/ss/rules/chnroute6.txt" ] && sed 's/^/whitelist-ip /g' /koolshare/ss/rules/chnroute6.txt >> "${outfile}"
}

SMARTDNS_STORAGE_PREFIX="j1:"
SMARTDNS_RELAY_PORT_BASE=1055
SMARTDNS_RELAY_PORT_MAX=1070

smartdns_get_wan_dns_raw() {
	local dns_raw="$(nvram get wan0_dns)"
	[ -n "${dns_raw}" ] || dns_raw="$(nvram get wan0_dns_r)"
	[ -n "${dns_raw}" ] || dns_raw="$(nvram get wan_dns)"
	[ -n "${dns_raw}" ] || dns_raw="$(nvram get wan0_xdns)"
	[ -n "${dns_raw}" ] || dns_raw="223.5.5.5 223.6.6.6"
	echo "${dns_raw}"
}

smartdns_get_isp_dns_slot() {
	local slot="$1"
	smartdns_get_wan_dns_raw | tr ' ' '\n' | grep -v '^0\.0\.0\.0$' | grep -v '^127\.0\.0\.1$' | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:" | sed -n "${slot}p"
}

smartdns_json_encode_one_line() {
	printf '%s' "$1" | base64 | tr -d '\r\n'
}

smartdns_store_json_value() {
	echo "${SMARTDNS_STORAGE_PREFIX}$(smartdns_json_encode_one_line "$1")"
}

fss_airport_runtime_current_entry_json() {
	return 1
}

fss_airport_special_current_conf_path() {
	local airport_identity=""
	local conf_path=""
	airport_identity="$(fss_get_current_node_airport_identity 2>/dev/null)" || return 1
	[ -n "${airport_identity}" ] || return 1
	conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || return 1
	[ -f "${conf_path}" ] || return 1
	printf '%s\n' "${conf_path}"
}

fss_airport_special_conf_get_value() {
	local conf_path="$1"
	local key="$2"
	[ -f "${conf_path}" ] || return 1
	[ -n "${key}" ] || return 1
	sed -n "s/^${key}=//p" "${conf_path}" | sed -n '1p'
}

fss_airport_special_conf_iter_dns_urls() {
	local conf_path="$1"
	[ -f "${conf_path}" ] || return 1
	sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d;/^[A-Za-z0-9_][A-Za-z0-9_]*=/d' "${conf_path}" 2>/dev/null
}

fss_airport_special_conf_iter_identities() {
	[ -f "${FSS_AIRPORT_SPECIAL_INDEX_FILE}" ] || return 1
	sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "${FSS_AIRPORT_SPECIAL_INDEX_FILE}" 2>/dev/null
}

fss_airport_special_runtime_domain_file() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	printf '/tmp/ss_node_domains_airport_%s.txt\n' "${airport_identity}"
}

fss_airport_special_runtime_dns_file() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	printf '/tmp/ss_node_domains_airport_dns_%s.txt\n' "${airport_identity}"
}

fss_clear_airport_special_runtime_files() {
	rm -f /tmp/ss_node_domains_airport.txt \
		/tmp/ss_node_domains_airport_dns.txt \
		/tmp/ss_node_domains_other.txt \
		/tmp/ss_node_domains_airport_*.txt \
		/tmp/ss_node_domains_airport_dns_*.txt >/dev/null 2>&1
}

fss_airport_special_conf_has_active_nodes() {
	local airport_identity="$1"
	[ -n "${airport_identity}" ] || return 1
	[ -s "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" ] || return 1
	awk -F '\t' -v id="${airport_identity}" '$1 == id {found=1; exit} END {exit(found ? 0 : 1)}' "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" 2>/dev/null
}

fss_airport_special_active_identities() {
	local airport_identity=""
	local conf_path=""

	fss_refresh_node_direct_cache >/dev/null 2>&1 || true
	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
		[ -f "${conf_path}" ] || continue
		fss_airport_special_conf_has_active_nodes "${airport_identity}" || continue
		printf '%s\n' "${airport_identity}"
	done <<-EOF
$(fss_airport_special_conf_iter_identities 2>/dev/null)
	EOF
}

fss_airport_special_active_label_by_plan() {
	local preferred_plan="${1:-smartdns}"
	local airport_identity=""
	local conf_path=""
	local conf_plan=""
	local conf_label=""

	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
		[ -f "${conf_path}" ] || continue
		conf_plan="$(fss_airport_special_conf_get_value "${conf_path}" "preferred_dns_plan" 2>/dev/null)"
		[ -n "${conf_plan}" ] || conf_plan="smartdns"
		[ "${conf_plan}" = "${preferred_plan}" ] || continue
		fss_airport_special_conf_has_active_nodes "${airport_identity}" || continue
		conf_label="$(fss_airport_special_conf_get_value "${conf_path}" "airport_label" 2>/dev/null)"
		[ -n "${conf_label}" ] || conf_label="${airport_identity}"
		printf '%s\n' "${conf_label}"
		return 0
	done <<-EOF
$(fss_airport_special_active_identities 2>/dev/null)
	EOF
	return 1
}

fss_airport_special_active_labels_by_plan() {
	local preferred_plan="${1:-smartdns}"
	local airport_identity=""
	local conf_path=""
	local conf_plan=""
	local conf_label=""
	local labels=""

	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
		[ -f "${conf_path}" ] || continue
		conf_plan="$(fss_airport_special_conf_get_value "${conf_path}" "preferred_dns_plan" 2>/dev/null)"
		[ -n "${conf_plan}" ] || conf_plan="smartdns"
		[ "${conf_plan}" = "${preferred_plan}" ] || continue
		fss_airport_special_conf_has_active_nodes "${airport_identity}" || continue
		conf_label="$(fss_airport_special_conf_get_value "${conf_path}" "airport_label" 2>/dev/null)"
		[ -n "${conf_label}" ] || conf_label="${airport_identity}"
		if [ -n "${labels}" ]; then
			labels="${labels}、${conf_label}"
		else
			labels="${conf_label}"
		fi
	done <<-EOF
$(fss_airport_special_active_identities 2>/dev/null)
	EOF

	[ -n "${labels}" ] || return 1
	printf '%s\n' "${labels}"
}

fss_airport_special_iter_active_tsv() {
	local airport_identity=""
	local conf_path=""
	local conf_label=""
	local conf_plan=""
	local sep="$(printf '\037')"

	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
		[ -f "${conf_path}" ] || continue
		conf_label="$(fss_airport_special_conf_get_value "${conf_path}" "airport_label" 2>/dev/null)"
		[ -n "${conf_label}" ] || conf_label="${airport_identity}"
		conf_plan="$(fss_airport_special_conf_get_value "${conf_path}" "preferred_dns_plan" 2>/dev/null)"
		[ -n "${conf_plan}" ] || conf_plan="smartdns"
		printf '%s%s%s%s%s\n' "${airport_identity}" "${sep}" "${conf_label}" "${sep}" "${conf_plan}"
	done <<-EOF
$(fss_airport_special_active_identities 2>/dev/null)
	EOF
}

fss_airport_dns_raw_to_tsv() {
	local raw="$1"
	local proto="" addr="" port="" host="" host_ip="" hostport="" remain=""
	local sep="$(printf '\037')"

	raw=$(printf '%s' "${raw}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//;s/^'\''//;s/'\''$//')
	[ -n "${raw}" ] || return 1
	case "${raw}" in
	https://*)
		proto="https"
		hostport=$(printf '%s' "${raw#https://}" | sed 's#/.*$##')
		port=$(printf '%s' "${hostport}" | awk -F: 'NF>1{print $NF}')
		[ -n "${port}" ] || port="443"
		case "${hostport}" in
		\[*\]:*)
			host=$(printf '%s' "${hostport}" | sed -n 's/^\[\(.*\)\]:[0-9][0-9]*$/\1/p')
			[ -n "${host}" ] || host=$(printf '%s' "${hostport}" | sed 's/^\[//;s/\]$//')
			;;
		*)
			host=$(printf '%s' "${hostport}" | sed 's/:[0-9][0-9]*$//')
			;;
		esac
		;;
	quic://*)
		proto="quic"
		hostport=$(printf '%s' "${raw#quic://}" | sed 's#/.*$##')
		port=$(printf '%s' "${hostport}" | awk -F: 'NF>1{print $NF}')
		[ -n "${port}" ] || port="853"
		case "${hostport}" in
		\[*\]:*)
			host=$(printf '%s' "${hostport}" | sed -n 's/^\[\(.*\)\]:[0-9][0-9]*$/\1/p')
			[ -n "${host}" ] || host=$(printf '%s' "${hostport}" | sed 's/^\[//;s/\]$//')
			;;
		*)
			host=$(printf '%s' "${hostport}" | sed 's/:[0-9][0-9]*$//')
			;;
		esac
		;;
	tls://*)
		proto="tls"
		remain="${raw#tls://}"
		host="${remain%%@*}"
		[ "${remain#*@}" != "${remain}" ] && host_ip="${remain#*@}" || host_ip=""
		port="853"
		;;
	tcp://*)
		proto="tcp"
		remain="${raw#tcp://}"
		addr="${remain%%:*}"
		port="${remain##*:}"
		[ "${addr}" = "${port}" ] && port="53"
		[ -n "$(fss_is_domain_name "${addr}")" ] && host="${addr}"
		;;
	udp://*)
		proto="udp"
		remain="${raw#udp://}"
		addr="${remain%%:*}"
		port="${remain##*:}"
		[ "${addr}" = "${port}" ] && port="53"
		[ -n "$(fss_is_domain_name "${addr}")" ] && host="${addr}"
		;;
	*)
		if printf '%s' "${raw}" | grep -Eq '^([0-9]{1,3}[.]){3}[0-9]{1,3}(:[0-9]+)?$';then
			proto="udp"
			addr="${raw%%:*}"
			port="${raw##*:}"
			[ "${addr}" = "${port}" ] && port="53"
		else
			return 1
		fi
		;;
	esac
	printf '%s%s%s%s%s%s%s%s%s%s%s\n' "${proto}" "${sep}" "${raw}" "${sep}" "${addr}" "${sep}" "${port}" "${sep}" "${host}" "${sep}" "${host_ip}"
}

fss_airport_runtime_iter_current_dns_items_tsv() {
	local airport_identity=""
	local conf_path=""
	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || continue
		[ -f "${conf_path}" ] || continue
		fss_airport_special_conf_iter_dns_urls "${conf_path}" 2>/dev/null | while IFS= read -r raw
		do
			[ -n "${raw}" ] || continue
			fss_airport_dns_raw_to_tsv "${raw}" 2>/dev/null || true
		done
	done <<-EOF
$(fss_airport_special_active_identities 2>/dev/null)
	EOF
}

fss_airport_runtime_iter_dns_items_tsv_by_identity() {
	local airport_identity="$1"
	local conf_path=""
	[ -n "${airport_identity}" ] || return 1
	conf_path="$(fss_airport_special_conf_path "${airport_identity}" 2>/dev/null)" || return 1
	[ -f "${conf_path}" ] || return 1
	fss_airport_special_conf_iter_dns_urls "${conf_path}" 2>/dev/null | while IFS= read -r raw
	do
		[ -n "${raw}" ] || continue
		fss_airport_dns_raw_to_tsv "${raw}" 2>/dev/null || true
	done
}

fss_refresh_airport_special_runtime_domain_files() {
	local airport_file="${FSS_NODE_DIRECT_RUNTIME_AIRPORT_FILE}"
	local other_file="${FSS_NODE_DIRECT_RUNTIME_OTHER_FILE}"
	local airport_tmp="${airport_file}.tmp.$$"
	local other_tmp="${other_file}.tmp.$$"
	local active_ids_file="${airport_file}.active.$$"
	local airport_identity=""
	local airport_identity_tmp=""
	local domain_file=""
	local domain_tmp=""

	fss_clear_airport_special_runtime_files
	rm -f "${airport_tmp}" "${other_tmp}" "${active_ids_file}"
	fss_refresh_node_direct_cache >/dev/null 2>&1 || return 1
	fss_airport_special_active_identities 2>/dev/null | sort -u > "${active_ids_file}"
	[ -s "${active_ids_file}" ] || {
		rm -f "${airport_file}" "${other_file}" "${active_ids_file}"
		return 0
	}
	awk -F '\t' -v active_ids="${active_ids_file}" -v airport_out="${airport_tmp}" -v other_out="${other_tmp}" '
		BEGIN {
			while ((getline line < active_ids) > 0) {
				active[line] = 1
			}
		}
		NF >= 2 && $2 != "" {
			if ($1 in active) {
				print $2 >> airport_out
				print $2 >> sprintf("/tmp/ss_node_domains_airport_%s.txt.tmp.__ACTIVE__", $1)
			} else {
				print $2 >> other_out
			}
		}
	' "${FSS_NODE_AIRPORT_DOMAIN_CACHE_FILE}" 2>/dev/null
	rm -f "${active_ids_file}"

	for airport_identity_tmp in /tmp/ss_node_domains_airport_*.txt.tmp.__ACTIVE__
	do
		[ -f "${airport_identity_tmp}" ] || continue
		airport_identity="${airport_identity_tmp#/tmp/ss_node_domains_airport_}"
		airport_identity="${airport_identity%.txt.tmp.__ACTIVE__}"
		domain_file="$(fss_airport_special_runtime_domain_file "${airport_identity}" 2>/dev/null)" || {
			rm -f "${airport_identity_tmp}"
			continue
		}
		domain_tmp="${domain_file}.tmp.$$"
		sort -u "${airport_identity_tmp}" -o "${airport_identity_tmp}" 2>/dev/null
		cat "${airport_identity_tmp}" > "${domain_tmp}" 2>/dev/null && mv -f "${domain_tmp}" "${domain_file}"
		rm -f "${airport_identity_tmp}" "${domain_tmp}"
	done

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

fss_airport_dns_item_effective_host() {
	local proto="$1"
	local raw="$2"
	local addr="$3"
	local host="$4"
	local hostport=""
	local remain=""

	[ -n "${host}" ] || {
		case "${proto}" in
		https|quic)
			hostport=$(printf '%s' "${raw#*://}" | sed 's#/.*$##')
			case "${hostport}" in
			\[*\]:*)
				host=$(printf '%s' "${hostport}" | sed -n 's/^\[\(.*\)\]:[0-9][0-9]*$/\1/p')
				[ -n "${host}" ] || host=$(printf '%s' "${hostport}" | sed 's/^\[//;s/\]$//')
				;;
			*)
				host=$(printf '%s' "${hostport}" | sed 's/:[0-9][0-9]*$//')
				;;
			esac
			;;
		tls)
			remain="${raw#tls://}"
			host="${remain%%@*}"
			;;
		tcp|udp)
			[ -n "$(fss_is_domain_name "${addr}")" ] && host="${addr}"
			;;
		esac
	}
	[ -n "${host}" ] || return 1
	[ -n "$(fss_is_domain_name "${host}")" ] || return 1
	printf '%s' "${host}"
}

fss_refresh_airport_dns_host_runtime_file() {
	local runtime_file="${FSS_NODE_DIRECT_RUNTIME_AIRPORT_DNS_FILE}"
	local tmp_file="${runtime_file}.tmp.$$"
	local sep="$(printf '\037')"
	local proto="" raw="" addr="" port="" host="" host_ip=""
	local effective_host=""
	local airport_identity=""
	local airport_runtime_file=""
	local airport_tmp_file=""

	rm -f "${tmp_file}"
	fss_airport_runtime_iter_current_dns_items_tsv 2>/dev/null | while IFS="${sep}" read -r proto raw addr port host host_ip
	do
		effective_host="$(fss_airport_dns_item_effective_host "${proto}" "${raw}" "${addr}" "${host}" 2>/dev/null)" || continue
		printf '%s\n' "${effective_host}"
	done | sort -u > "${tmp_file}" 2>/dev/null

	if [ -s "${tmp_file}" ];then
		mv -f "${tmp_file}" "${runtime_file}"
	else
		rm -f "${tmp_file}" "${runtime_file}"
	fi

	while IFS= read -r airport_identity
	do
		[ -n "${airport_identity}" ] || continue
		airport_runtime_file="$(fss_airport_special_runtime_dns_file "${airport_identity}" 2>/dev/null)" || continue
		airport_tmp_file="${airport_runtime_file}.tmp.$$"
		rm -f "${airport_tmp_file}"
		fss_airport_runtime_iter_dns_items_tsv_by_identity "${airport_identity}" 2>/dev/null | while IFS="${sep}" read -r proto raw addr port host host_ip
		do
			effective_host="$(fss_airport_dns_item_effective_host "${proto}" "${raw}" "${addr}" "${host}" 2>/dev/null)" || continue
			printf '%s\n' "${effective_host}"
		done | sort -u > "${airport_tmp_file}" 2>/dev/null
		if [ -s "${airport_tmp_file}" ];then
			mv -f "${airport_tmp_file}" "${airport_runtime_file}"
		else
			rm -f "${airport_tmp_file}" "${airport_runtime_file}"
		fi
	done <<-EOF
$(fss_airport_special_active_identities 2>/dev/null)
	EOF
}

fss_airport_dns_override_reset() {
	AIRPORT_DNS_ACTIVE="0"
	AIRPORT_DNS_CURRENT_MATCHED="0"
	AIRPORT_DNS_AIRPORT_IDENTITY=""
	AIRPORT_DNS_AIRPORT_LABEL=""
	AIRPORT_DNS_PREFERRED_PLAN=""
	fss_clear_airport_special_runtime_files
}

fss_airport_dns_override_load() {
	local current_airport=""
	local conf_path=""
	local active_identity=""
	local active_conf_path=""
	fss_airport_dns_override_reset
	active_identity="$(fss_airport_special_active_identities 2>/dev/null | sed -n '1p')" || active_identity=""
	[ -n "${active_identity}" ] || return 0
	AIRPORT_DNS_ACTIVE="1"
	current_airport="$(fss_get_current_node_airport_identity 2>/dev/null)" || current_airport=""
	conf_path=""
	if [ -n "${current_airport}" ];then
		conf_path="$(fss_airport_special_conf_path "${current_airport}" 2>/dev/null)" || conf_path=""
	fi
	if [ -n "${conf_path}" ] && [ -f "${conf_path}" ] && fss_airport_special_conf_has_active_nodes "${current_airport}"; then
		AIRPORT_DNS_CURRENT_MATCHED="1"
		AIRPORT_DNS_AIRPORT_IDENTITY="${current_airport}"
		AIRPORT_DNS_AIRPORT_LABEL="$(fss_airport_special_conf_get_value "${conf_path}" "airport_label" 2>/dev/null)"
		AIRPORT_DNS_PREFERRED_PLAN="$(fss_airport_special_conf_get_value "${conf_path}" "preferred_dns_plan" 2>/dev/null)"
	else
		active_conf_path="$(fss_airport_special_conf_path "${active_identity}" 2>/dev/null)" || active_conf_path=""
		AIRPORT_DNS_AIRPORT_IDENTITY="${active_identity}"
		AIRPORT_DNS_AIRPORT_LABEL="$(fss_airport_special_conf_get_value "${active_conf_path}" "airport_label" 2>/dev/null)"
		AIRPORT_DNS_PREFERRED_PLAN="$(fss_airport_special_conf_get_value "${active_conf_path}" "preferred_dns_plan" 2>/dev/null)"
	fi
	[ -n "${AIRPORT_DNS_AIRPORT_LABEL}" ] || AIRPORT_DNS_AIRPORT_LABEL="${AIRPORT_DNS_AIRPORT_IDENTITY}"
	[ -n "${AIRPORT_DNS_PREFERRED_PLAN}" ] || AIRPORT_DNS_PREFERRED_PLAN="smartdns"
	fss_refresh_airport_special_runtime_domain_files >/dev/null 2>&1 || true
	fss_refresh_airport_dns_host_runtime_file >/dev/null 2>&1 || true
}

smartdns_decode_json_value() {
	local value="$1"
	case "${value}" in
	${SMARTDNS_STORAGE_PREFIX}*)
		value="${value#${SMARTDNS_STORAGE_PREFIX}}"
		;;
	esac
	[ -n "${value}" ] || return 1
	printf '%s' "${value}" | base64_decode 2>/dev/null
}

smartdns_should_seed_isp_defaults() {
	if [ "${ss_basic_add_ispdns}" = "0" ];then
		echo "0"
	else
		echo "1"
	fi
}

smartdns_default_group_json() {
	local group="$1"
	local include_isp="$2"
	local isp1="$(smartdns_get_isp_dns_slot 1)"
	local isp2="$(smartdns_get_isp_dns_slot 2)"
	case "${group}" in
	chn)
		run jq -cn \
			--arg include_isp "${include_isp}" \
			--arg isp1 "${isp1}" \
			--arg isp2 "${isp2}" \
			'
			def net(addr): if (addr | contains(":")) then "ipv6" else "ipv4" end;
			def isp_item(slot; provider; addr; desc): {
			  id: ("isp_udp_" + (slot|tostring)),
			  proto: "udp",
			  provider: provider,
			  description: desc,
			  kind: "isp",
			  slot: slot,
			  isp: 1,
			  net: net(addr)
			};
			def udp_item(provider; addr; desc): {
			  id: ("udp_" + addr + "_53"),
			  proto: "udp",
			  provider: provider,
			  description: desc,
			  kind: "preset",
			  addr: addr,
			  port: 53,
			  isp: 0,
			  net: net(addr)
			};
			{
			  version: 1,
			  items: (
			    (if $include_isp == "1" and $isp1 != "" then [isp_item(1; "ISP DNS 1"; $isp1; "主用DNS")] else [udp_item("OneDNS"; "117.50.10.10"; "纯净版")] end) +
			    (if $include_isp == "1" and $isp2 != "" then [isp_item(2; "ISP DNS 2"; $isp2; "备用DNS")] else [udp_item("OneDNS"; "117.50.60.30"; "家庭版")] end) +
			    [
			      udp_item("阿里公共DNS"; "223.5.5.5"; ""),
			      udp_item("DNSPod DNS"; "119.29.29.29"; ""),
			      udp_item("114 DNS"; "114.114.114.114"; "纯净版"),
			      udp_item("字节跳动DNS"; "180.184.1.1"; ""),
			      udp_item("CNNIC DNS"; "1.2.4.8"; ""),
			      udp_item("百度DNS"; "180.76.76.76"; "")
			    ]
			  )
			}'
		;;
	gfw)
		run jq -cn '
			def tcp_item(provider; addr; desc): {
			  id: ("tcp_" + addr + "_53"),
			  proto: "tcp",
			  provider: provider,
			  description: desc,
			  kind: "preset",
			  addr: addr,
			  port: 53,
			  isp: 0,
			  net: (if (addr | contains(":")) then "ipv6" else "ipv4" end)
			};
			{
			  version: 1,
			  items: [
			    tcp_item("Google DNS"; "8.8.8.8"; ""),
			    tcp_item("Cloudflare DNS"; "1.1.1.1"; "")
			  ]
			}'
		;;
	esac
}

smartdns_validate_group_value() {
	local group="$1"
	local value="$2"
	local json
	json="$(smartdns_decode_json_value "${value}")" || return 1
	printf '%s' "${json}" | run jq -e '
		(.items | type == "array") and
		(.items | length > 0) and
		(.items | length <= 16) and
		all(.items[];
			(.proto == "udp" or .proto == "tcp" or .proto == "dot") and
			(
				((.kind // "preset") == "isp" and ((.slot | tostring) == "1" or (.slot | tostring) == "2")) or
				((.kind // "preset") == "preset" and (
					((.proto == "udp" or .proto == "tcp") and ((.addr // "") != "")) or
					(.proto == "dot" and ((.host // "") != "") and ((.host_ip // "") != ""))
				))
			)
		)
	' >/dev/null 2>&1
}

smartdns_group_json() {
	local group="$1"
	local key="ss_basic_smrt_${group}_dns"
	local value
	eval "value=\${${key}}"
	if smartdns_validate_group_value "${group}" "${value}"; then
		smartdns_decode_json_value "${value}" | run jq -c '.'
	else
		smartdns_default_group_json "${group}" "$(smartdns_should_seed_isp_defaults)"
	fi
}

smartdns_iter_group_items() {
	local group="$1"
	smartdns_group_json "${group}" | run jq -rc '.items[] | @base64'
}

smartdns_resolve_item_tsv() {
	local item_b64="$1"
	local decoded
	decoded="$(printf '%s' "${item_b64}" | base64_decode 2>/dev/null)" || return 1
	local fields
	local sep="$(printf '\037')"
	fields="$(printf '%s' "${decoded}" | run jq -r --arg sep "${sep}" '[.id, .proto, (.provider // ""), (.description // ""), (.kind // "preset"), ((.slot // "") | tostring), (.addr // ""), ((.port // "") | tostring), (.host // ""), (.host_ip // ""), ((.isp // 0) | tostring), (.net // "")] | join($sep)')" || return 1
	local id proto provider description kind slot addr port host host_ip isp net
	IFS="${sep}" read -r id proto provider description kind slot addr port host host_ip isp net <<-EOF
${fields}
EOF
	if [ "${kind}" = "isp" ];then
		addr="$(smartdns_get_isp_dns_slot "${slot}")"
		[ -n "${addr}" ] || return 1
		port="53"
		net="$(echo "${addr}" | grep -q ':' && echo ipv6 || echo ipv4)"
	fi
	if [ "${proto}" = "dot" ];then
		[ -n "${host}" ] || return 1
		[ -n "${host_ip}" ] || return 1
		[ -n "${port}" ] || port="853"
	else
		[ -n "${addr}" ] || return 1
		[ -n "${port}" ] || port="53"
	fi
	printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n' "${id}" "${proto}" "${provider}" "${description}" "${kind}" "${slot}" "${addr}" "${port}" "${host}" "${host_ip}" "${isp}" "${net}"
}

smartdns_group_items_tsv() {
	local group="$1"
	smartdns_iter_group_items "${group}" | while read -r item_b64
	do
		smartdns_resolve_item_tsv "${item_b64}"
	done
}

smartdns_iter_gfw_udp_relays() {
	local idx=0
	local item_line
	local sep="$(printf '\037')"
	while IFS="${sep}" read -r id proto provider description kind slot addr port host host_ip isp net
	do
		[ "${proto}" = "udp" ] || continue
		idx=$((idx + 1))
		[ $((SMARTDNS_RELAY_PORT_BASE + idx - 1)) -le "${SMARTDNS_RELAY_PORT_MAX}" ] || break
		printf '%s\037%s\037%s\037%s\037%s\n' "$((SMARTDNS_RELAY_PORT_BASE + idx - 1))" "${addr}" "${port}" "${provider}" "${description}"
	done <<-EOF
$(smartdns_group_items_tsv gfw)
EOF
}

smartdns_ensure_dns_groups() {
	case "${ss_basic_smrt}" in
	4)
		ss_basic_smrt="1"
		dbus set ss_basic_smrt="1"
		;;
	5)
		ss_basic_smrt="2"
		dbus set ss_basic_smrt="2"
		;;
	6)
		ss_basic_smrt="3"
		dbus set ss_basic_smrt="3"
		;;
	"")
		ss_basic_smrt="3"
		dbus set ss_basic_smrt="3"
		;;
	esac

	local seed_isp="$(smartdns_should_seed_isp_defaults)"
	if ! smartdns_validate_group_value "chn" "${ss_basic_smrt_chn_dns}"; then
		ss_basic_smrt_chn_dns="$(smartdns_store_json_value "$(smartdns_default_group_json chn "${seed_isp}")")"
		dbus set ss_basic_smrt_chn_dns="${ss_basic_smrt_chn_dns}"
	fi
	if ! smartdns_validate_group_value "gfw" "${ss_basic_smrt_gfw_dns}"; then
		ss_basic_smrt_gfw_dns="$(smartdns_store_json_value "$(smartdns_default_group_json gfw "${seed_isp}")")"
		dbus set ss_basic_smrt_gfw_dns="${ss_basic_smrt_gfw_dns}"
	fi
	if [ -n "${ss_basic_add_ispdns}" ];then
		dbus remove ss_basic_add_ispdns
		unset ss_basic_add_ispdns
	fi
	if [ -n "${ss_basic_smartdns_rule}" ];then
		dbus remove ss_basic_smartdns_rule
		unset ss_basic_smartdns_rule
	fi
}

generate_smartdns_runtime_policy_file() {
	local outfile="$1"
	local mode="${ss_basic_mode}"
	[ -n "${outfile}" ] || return 1
	: > "${outfile}"

	cat > "${outfile}" <<-'EOF'
# ------------------------------------------------------------------------------
# fancyss smartdns 运行时 IPv6 / AAAA 策略
# ------------------------------------------------------------------------------
# 此文件由 fancyss 在插件启动时自动生成。
# SmartDNS 关键语法：
#   force-AAAA-SOA yes      -> 全局关闭 AAAA 响应
#   address /example.com/#6 -> 对指定域名/域名集合关闭 AAAA
#   address /example.com/-6 -> 对指定域名/域名集合清除全局 AAAA 抑制
# ------------------------------------------------------------------------------
EOF

	if [ "${ss_basic_proxy_ipv6}" = "1" ];then
		cat >> "${outfile}" <<-'EOF'
# 已开启 IPv6 透明代理：
# 保留 SmartDNS 对各域名集合的 AAAA 响应能力。
EOF
		return 0
	fi

	case "${mode}" in
	1)
		cat >> "${outfile}" <<-'EOF'
# gfw 黑名单模式：
# - 代理域名：gfwlist / black_list / rotlist
# - 直连域名：chnlist / white_list / default
# 保留直连域名的双栈能力，同时抑制代理域名集合的 AAAA。
address /domain-set:gfwlist/#6
address /domain-set:black_list/#6
address /domain-set:rotlist/#6
EOF
		;;
	2|3)
		cat >> "${outfile}" <<-'EOF'
# 大陆白名单模式 / 游戏模式：
# - 明确直连域名：chnlist / white_list
# - 其余域名可能在后续路由判断中继续走代理
# 为避免代理域名解析到 IPv6 后直连，先全局抑制 AAAA，再对白名单域名集合放开。
force-AAAA-SOA yes
address /domain-set:chnlist/-6
address /domain-set:white_list/-6
EOF
		;;
	5)
		cat >> "${outfile}" <<-'EOF'
# 全局模式：
# - 直连域名：white_list
# - 其余域名全部走代理
# 先全局抑制 AAAA，再仅对白名单域名集合放开。
force-AAAA-SOA yes
address /domain-set:white_list/-6
EOF
		;;
	*)
		cat >> "${outfile}" <<-'EOF'
# 当前模式无需追加额外的 AAAA 抑制规则。
EOF
		;;
	esac
}

append_smartdns_runtime_policy_conf() {
	local smartdns_conf="$1"
	local policy_file="$2"
	[ -f "${smartdns_conf}" ] || return 1
	[ -n "${policy_file}" ] || return 1

	generate_smartdns_runtime_policy_file "${policy_file}" || return 1
	sed -i '/# BEGIN FANCYSS SMARTDNS RUNTIME POLICY/,/# END FANCYSS SMARTDNS RUNTIME POLICY/d' "${smartdns_conf}" 2>/dev/null
	cat >> "${smartdns_conf}" <<-EOF

# BEGIN FANCYSS SMARTDNS RUNTIME POLICY
# The following file is generated by fancyss on each startup.
conf-file ${policy_file}
# END FANCYSS SMARTDNS RUNTIME POLICY
EOF
}
