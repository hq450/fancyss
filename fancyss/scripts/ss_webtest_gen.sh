#!/bin/sh
#
# Shared config generators for ss_webtest.sh
# Keep logic consistent with ssconfig.sh where possible.

source /koolshare/scripts/ss_node_common.sh

wt_node_get() {
	fss_get_node_field_legacy "$2" "$1"
}

wt_node_get_plain() {
	fss_get_node_field_plain "$2" "$1"
}

wt_get_path_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"/\"]
	fi
}

wt_get_host_empty() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo [\"\"]
	fi
}

wt_get_grpc_multimode() {
	case "$1" in
	multi)
		echo true
		;;
	gun|*)
		echo false
		;;
	esac
}

wt_get_ws_header() {
	if [ -n "$1" ]; then
		echo {\"Host\": \"$1\"}
	else
		echo null
	fi
}

wt_get_host() {
	if [ -n "$1" ]; then
		echo [\"$1\"]
	else
		echo null
	fi
}

wt_get_value_null() {
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo null
	fi
}

wt_get_value_speed() {
	if [ -n "$1" ]; then
		echo \"${1}mbps\"
	else
		echo null
	fi
}

wt_get_value_empty() {
	if [ -n "$1" ]; then
		echo \"$1\"
	else
		echo \"\"
	fi
}

wt_get_value_congestion() {
	local _up="$1"
	local _down="$2"
	local _cg="$3"
	if [ -n "${_up}" -a -n "${_down}" ]; then
		if [ -z "${_cg}" ]; then
			echo \"brutal\"
		else
			echo \"${_cg}\"
		fi
	elif [ -z "${_up}" -a -z "${_down}" ]; then
		echo \"bbr\"
	else
		echo \"${_cg}\"
	fi
}

wt_get_hy2_port() {
	local _match1=$(echo $1 | grep -Eo ",")
	local _match2=$(echo $1 | grep -Eo "-")
	if [ -z "${_match1}" -a -z "${_match2}" ]; then
		echo "$1"
	else
		echo null
	fi
}

wt_get_hy2_udphop_port() {
	local _match1=$(echo $1 | grep -Eo ",")
	local _match2=$(echo $1 | grep -Eo "-")
	if [ -z "${_match1}" -a -z "${_match2}" ]; then
		echo \"\"
	else
		echo \"$1\"
	fi
}

wt_get_out_file_path() {
	local nu="$1"
	local mark="$2"
	if [ -n "${WT_GEN_OUT_FILE}" ]; then
		printf '%s' "${WT_GEN_OUT_FILE}"
	else
		printf '%s' "${TMP2}/conf_${mark}/${nu}_outbounds.json"
	fi
}

wt_get_start_file_path() {
	local nu="$1"
	local mark="$2"
	if [ -n "${WT_GEN_START_FILE}" ]; then
		printf '%s' "${WT_GEN_START_FILE}"
	else
		printf '%s' "${TMP2}/bash_${mark}/start_${nu}.sh"
	fi
}

wt_get_stop_file_path() {
	local nu="$1"
	local mark="$2"
	if [ -n "${WT_GEN_STOP_FILE}" ]; then
		printf '%s' "${WT_GEN_STOP_FILE}"
	else
		printf '%s' "${TMP2}/bash_${mark}/stop_${nu}.sh"
	fi
}

wt_strip_null_keys() {
	local json_file="$1"
	local tmp_file="${json_file}.tmp"

	[ -f "${json_file}" ] || return 1
	run jq '
		def strip_nulls:
			if type == "object" then
				with_entries(select(.value != null) | .value |= strip_nulls)
			elif type == "array" then
				map(strip_nulls)
			else
				.
			end;
		strip_nulls
	' "${json_file}" > "${tmp_file}" || {
		rm -f "${tmp_file}"
		return 1
	}
	mv -f "${tmp_file}" "${json_file}"
}

wt_wrap_user_outbound_json() {
	local json_file="$1"
	local target_addr="$2"
	local out_file="$3"
	local tag_name="$4"

	[ -n "${json_file}" ] || return 1
	[ -f "${json_file}" ] || return 1
	[ -n "${out_file}" ] || return 1
	[ -n "${tag_name}" ] || tag_name="proxy"
	run jq --arg addr "${target_addr}" --arg tag "${tag_name}" '
		def patch_addr:
			(.outbound // (.outbounds[0] // {})) as $ob
			| ($ob.protocol // "") as $protocol
			| if $addr == "" then
				.
			elif ($protocol == "vmess" or $protocol == "vless") then
				if has("outbound") then
					.outbound.settings.vnext[0].address = $addr
				elif ((.outbounds // []) | length) > 0 then
					.outbounds[0].settings.vnext[0].address = $addr
				else
					.
				end
			elif ($protocol == "socks" or $protocol == "shadowsocks" or $protocol == "trojan") then
				if has("outbound") then
					.outbound.settings.servers[0].address = $addr
				elif ((.outbounds // []) | length) > 0 then
					.outbounds[0].settings.servers[0].address = $addr
				else
					.
				end
			elif ($protocol == "hysteria") then
				if has("outbound") then
					.outbound.settings.address = $addr
				elif ((.outbounds // []) | length) > 0 then
					.outbounds[0].settings.address = $addr
				else
					.
				end
			else
				.
			end;
		patch_addr
		| (.outbound // (.outbounds[0] // {})) as $ob
		| if ($ob | type) == "object" and (($ob | keys | length) > 0) then
			($ob | .tag = $tag)
		else
			empty
		end
	' "${json_file}" > "${out_file}" 2>/dev/null
}

wt_get_server_addr() {
	local server_host="$1"
	local server_ip=""

	[ -n "${server_host}" ] || return 1
	if wt_server_resolv_mode_is_dynamic; then
		printf '%s' "${server_host}"
		return 0
	fi
	server_ip=$(_get_server_ip "${server_host}")
	if [ -n "${server_ip}" ]; then
		printf '%s' "${server_ip}"
	else
		printf '%s' "${server_host}"
	fi
}

wt_gen_ss_outbound() {
	local nu="$1"
	local mark="$2"
	local out_file=""
	local start_file=""
	local stop_file=""
	local ss_server=""
	local _server_ip=""
	local ss_port=""
	local ss_pass=""
	local ss_meth=""
	local ss_obfs=""
	local ss_obfs_host=""
	local OBFS_ARG=""
	local _server_ip_tmp=""
	local _server_port_tmp=""
	local _uot=""

	WT_LAST_START_PORT=""
	ss_server=$(wt_node_get_plain server "${nu}")
	_server_ip=$(wt_get_server_addr "${ss_server}")
	ss_port=$(wt_node_get_plain port "${nu}")
	ss_pass=$(wt_node_get_plain password "${nu}")
	ss_meth=$(wt_node_get_plain method "${nu}")
	ss_obfs=$(wt_node_get_plain ss_obfs "${nu}")
	ss_obfs_host=$(wt_node_get_plain ss_obfs_host "${nu}")
	out_file=$(wt_get_out_file_path "${nu}" "${mark}")
	start_file=$(wt_get_start_file_path "${nu}" "${mark}")
	stop_file=$(wt_get_stop_file_path "${nu}" "${mark}")

	if [ "${ss_basic_tfo}" == "1" -a "${LINUX_VER}" != "26" ]; then
		OBFS_ARG="--fast-open"
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	fi

	if [ "${ss_obfs}" = "http" -o "${ss_obfs}" = "tls" ]; then
		local obfs_port="${WT_PRESET_START_PORT}"
		[ -n "${obfs_port}" ] || obfs_port=$(wt_get_reserved_port)
		WT_LAST_START_PORT="${obfs_port}"
		_server_ip_tmp="127.0.0.1"
		_server_port_tmp="${obfs_port}"
		if [ -n "${ss_obfs_host}" ]; then
			cat >"${start_file}" <<-EOF
				#!/bin/sh
				_wt_root=\${WT_RUNTIME_ROOT:-\$(cd "\$(dirname "\$0")/.." && pwd)}
				"\${_wt_root}/wt-obfs" -s ${_server_ip} -p ${ss_port} -l ${_server_port_tmp} --obfs ${ss_obfs} --obfs-host ${ss_obfs_host} ${OBFS_ARG} >/dev/null 2>&1 &
				_i=20
				while [ \${_i} -gt 0 ]; do
					netstat -nl 2>/dev/null | awk '{print \$4}' | grep -E "[:\\\\.]${_server_port_tmp}\$" >/dev/null 2>&1 && break
					usleep 100000
					_i=\$((\${_i} - 1))
				done
			EOF
		else
			cat >"${start_file}" <<-EOF
				#!/bin/sh
				_wt_root=\${WT_RUNTIME_ROOT:-\$(cd "\$(dirname "\$0")/.." && pwd)}
				"\${_wt_root}/wt-obfs" -s ${_server_ip} -p ${ss_port} -l ${_server_port_tmp} --obfs ${ss_obfs} ${OBFS_ARG} >/dev/null 2>&1 &
				_i=20
				while [ \${_i} -gt 0 ]; do
					netstat -nl 2>/dev/null | awk '{print \$4}' | grep -E "[:\\\\.]${_server_port_tmp}\$" >/dev/null 2>&1 && break
					usleep 100000
					_i=\$((\${_i} - 1))
				done
			EOF
		fi
		cat >"${stop_file}" <<-EOF
			#!/bin/sh
			_pid=\$(ps -w | grep "wt-obfs" | grep -w "${_server_ip}" | grep -w "${ss_port}" | grep -w "${_server_port_tmp}" | awk '{print \$1}' | sed -n '1p')
			if [ -n "\${_pid}" ];then
			    kill -9 \${_pid}
			fi
		EOF
		_uot="true"
	else
		_server_ip_tmp="${_server_ip}"
		_server_port_tmp="${ss_port}"
		_uot="false"
	fi

	cat >"${out_file}" <<-EOF
		{
			"tag": "proxy${nu}",
			"protocol": "shadowsocks",
			"settings": {
				"servers": [
					{
						"address": "${_server_ip_tmp}",
						"port": ${_server_port_tmp},
						"password": "${ss_pass}",
						"method": "${ss_meth}",
						"uot": ${_uot}
					}
				]
			},
			"streamSettings": {
				"network": "raw"
			},
			"sockopt": {
				"tcpFastOpen": $(get_function_switch ${ss_basic_tfo}),
				"tcpMptcp": false,
				"tcpcongestion": "bbr"
			}
		}
	EOF
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' "${out_file}" 2>/dev/null
	fi
}

wt_gen_vmess_outbound() {
	local nu="$1"
	local mark="$2"
	local out_file=""
	local v2ray_use_json=$(wt_node_get_plain v2ray_use_json ${nu})
	out_file=$(wt_get_out_file_path "${nu}" "${mark}")
	if [ "${v2ray_use_json}" != "1" ]; then
		local v2ray_server=$(wt_node_get_plain server ${nu})
		local _server_ip=$(wt_get_server_addr "${v2ray_server}")

		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"

		local v2ray_network=$(wt_node_get_plain v2ray_network ${nu})
		[ -z "${v2ray_network}" ] && v2ray_network="tcp"
		local v2ray_network_host_raw=$(wt_node_get_plain v2ray_network_host ${nu})
		local v2ray_network_host=$(echo ${v2ray_network_host_raw} | sed 's/,/", "/g')
		local v2ray_network_path=$(wt_node_get_plain v2ray_network_path ${nu})
		local v2ray_grpc_authority=$(wt_node_get_plain v2ray_grpc_authority ${nu})
		local v2ray_network_security=$(wt_node_get_plain v2ray_network_security ${nu})
		[ -z "${v2ray_network_security}" ] && v2ray_network_security="none"

		if [ "$(wt_node_get_plain v2ray_mux_enable ${nu})" == "1" -a -z "$(wt_node_get_plain v2ray_mux_concurrency ${nu})" ];then
			local v2ray_mux_concurrency=8
		else
			local v2ray_mux_concurrency=$(wt_node_get_plain v2ray_mux_concurrency ${nu})
		fi
		if [ "$(wt_node_get_plain v2ray_mux_enable ${nu})" != "1" ];then
			local v2ray_mux_concurrency="-1"
		fi

		if [ "${v2ray_network_security}" == "none" ];then
			local v2ray_network_security_ai=""
			local v2ray_network_security_alpn_h2=""
			local v2ray_network_security_alpn_http=""
			local v2ray_network_security_sni=""
		else
			local v2ray_network_security_ai=$(wt_node_get_plain v2ray_network_security_ai ${nu})
			local v2ray_network_security_alpn_h2=$(wt_node_get_plain v2ray_network_security_alpn_h2 ${nu})
			local v2ray_network_security_alpn_http=$(wt_node_get_plain v2ray_network_security_alpn_http ${nu})
			local v2ray_network_security_sni=$(wt_node_get_plain v2ray_network_security_sni ${nu})
		fi

		if [ "${v2ray_network_security}" == "tls" ];then
			if [ "${v2ray_network_security_alpn_h2}" == "1" -a "${v2ray_network_security_alpn_http}" == "1" ];then
				local apln="[\"h2\",\"http/1.1\"]"
			elif [ "${v2ray_network_security_alpn_h2}" != "1" -a "${v2ray_network_security_alpn_http}" == "1" ];then
				local apln="[\"http/1.1\"]"
			elif [ "${v2ray_network_security_alpn_h2}" == "1" -a "${v2ray_network_security_alpn_http}" != "1" ];then
				local apln="[\"h2\"]"
			else
				local apln="null"
			fi

			if [ -z "${v2ray_network_security_sni}" ];then
				if [ -n "${v2ray_network_host_raw}" ];then
					local v2ray_network_security_sni="${v2ray_network_host_raw}"
				else
					__valid_ip "${v2ray_server}"
					if [ "$?" != "0" ]; then
						local v2ray_network_security_sni="${v2ray_server}"
					else
						local v2ray_network_security_sni=""
					fi
				fi
			fi

			local tls="{
				\"allowInsecure\": $(get_function_switch ${v2ray_network_security_ai})
				,\"alpn\": ${apln}
				,\"serverName\": $(wt_get_value_null ${v2ray_network_security_sni})
				}"
		fi

		case "${v2ray_network}" in
		tcp)
			if [ "$(wt_node_get_plain v2ray_headtype_tcp ${nu})" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(wt_get_path_empty ${v2ray_network_path})
					,\"headers\": {
					\"Host\": $(wt_get_host_empty ${v2ray_network_host}),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$(wt_node_get_plain v2ray_headtype_kcp ${nu})\"
				}
				,\"seed\": $(wt_get_value_null $(wt_node_get_plain v2ray_kcp_seed ${nu}))
				}"
			;;
		ws)
			if [ -z "${v2ray_network_path}" -a -z "${v2ray_network_host}" ]; then
				local ws="{}"
			elif [ -z "${v2ray_network_path}" -a -n "${v2ray_network_host}" ]; then
				local ws="{
					\"headers\": $(wt_get_ws_header ${v2ray_network_host})
					}"
			elif [ -n "${v2ray_network_path}" -a -z "${v2ray_network_host}" ]; then
				local ws="{
					\"path\": $(wt_get_value_null ${v2ray_network_path})
					}"
			else
				local ws="{
					\"path\": $(wt_get_value_null ${v2ray_network_path}),
					\"headers\": $(wt_get_ws_header ${v2ray_network_host})
					}"
			fi
			;;
		h2)
			local h2="{
				\"path\": $(wt_get_value_empty ${v2ray_network_path})
				,\"host\": $(wt_get_host ${v2ray_network_host})
				}"
			;;
		quic)
			local qc="{
				\"security\": $(wt_get_value_empty ${v2ray_network_host}),
				\"key\": $(wt_get_value_empty ${v2ray_network_path}),
				\"header\": {
				\"type\": \"$(wt_node_get_plain v2ray_headtype_quic ${nu})\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(wt_get_value_empty ${v2ray_network_path}),
				\"authority\": $(wt_get_value_empty ${v2ray_grpc_authority}),
				\"multiMode\": $(wt_get_grpc_multimode $(wt_node_get_plain v2ray_grpc_mode ${nu}))
				}"
			;;
		esac

		cat >"${out_file}" <<-EOF
			{
				"tag": "proxy${nu}",
				"protocol": "vmess",
				"settings": {
					"vnext": [
						{
							"address": "${_server_ip}",
							"port": $(wt_node_get_plain port ${nu}),
							"users": [
								{
									"id": "$(wt_node_get_plain v2ray_uuid ${nu})"
									,"alterId": $(wt_node_get_plain v2ray_alterid ${nu})
									,"security": "$(wt_node_get_plain v2ray_security ${nu})"
								}
							]
						}
					]
				},
				"streamSettings": {
					"network": "${v2ray_network}"
					,"security": "${v2ray_network_security}"
					,"tlsSettings": $tls
					,"tcpSettings": $tcp
					,"kcpSettings": $kcp
					,"wsSettings": $ws
					,"httpSettings": $h2
					,"quicSettings": $qc
					,"grpcSettings": $gr
				},
				"mux": {
					"enabled": $(get_function_switch $(wt_node_get_plain v2ray_mux_enable ${nu})),
					"concurrency": ${v2ray_mux_concurrency}
				}
			}
		EOF

		wt_strip_null_keys "${out_file}"
	else
		wt_node_get_plain v2ray_json ${nu} >${TMP2}/v2ray_user_${nu}.json
		local user_host=""
		local user_host_addr=""
		{
			read -r user_host
			read -r _
		} <<-EOF
		$(fss_get_node_server_host_port "${nu}")
		EOF
		user_host_addr=$(wt_get_server_addr "${user_host}")
		wt_wrap_user_outbound_json "${TMP2}/v2ray_user_${nu}.json" "${user_host_addr}" "${out_file}" "proxy${nu}"
	fi
}

wt_gen_vless_outbound() {
	local nu="$1"
	local mark="$2"
	local out_file=""
	local xray_use_json=$(wt_node_get_plain xray_use_json ${nu})
	out_file=$(wt_get_out_file_path "${nu}" "${mark}")
	if [ "${xray_use_json}" != "1" ]; then
		local xray_server=$(wt_node_get_plain server ${nu})
		local _server_ip=$(wt_get_server_addr "${xray_server}")

		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"
		local xtls="null"
		local reali="null"
		local xht="null"
		local htup="null"

		local xray_network_host_raw=$(wt_node_get_plain xray_network_host ${nu})
		local xray_network_host=$(echo ${xray_network_host_raw} | sed 's/,/", "/g')
		local xray_network_path=$(wt_node_get_plain xray_network_path ${nu})
		local xray_grpc_authority=$(wt_node_get_plain xray_grpc_authority ${nu})
		local xray_network_security_sni=$(wt_node_get_plain xray_network_security_sni ${nu})
		if [ -z "${xray_network_security_sni}" ];then
			if [ -n "${xray_network_host_raw}" ];then
				xray_network_security_sni="${xray_network_host_raw}"
			else
				__valid_ip "${xray_server}"
				if [ "$?" != "0" ]; then
					xray_network_security_sni="${xray_server}"
				else
					xray_network_security_sni=""
				fi
			fi
		fi
		local xray_flow=$(wt_node_get_plain xray_flow ${nu})
		local xray_prot=$(wt_node_get_plain xray_prot ${nu})
		local xray_encryption=$(wt_node_get_plain xray_encryption ${nu})
		[ -z "${xray_prot}" ] && xray_prot="vless"
		[ -z "${xray_encryption}" ] && xray_encryption="none"
		local xray_fingerprint=$(wt_node_get_plain xray_fingerprint ${nu})
		[ -z "${xray_fingerprint}" ] && xray_fingerprint="chrome"
		local xray_pcs=$(wt_node_get_plain xray_pcs ${nu})
		local xray_vcn=$(wt_node_get_plain xray_vcn ${nu})
		local xray_network_security=$(wt_node_get_plain xray_network_security ${nu})
		[ -z "${xray_network_security}" ] && xray_network_security="none"
		local xray_xhttp_mode=$(wt_node_get_plain xray_xhttp_mode ${nu})

		if [ "${xray_network_security}" == "none" ];then
			if [ "${xray_prot}" != "vless" ] || [ "${xray_encryption}" = "none" ];then
				xray_flow=""
			fi
		fi

		if [ "${xray_network_security}" == "tls" -o "${xray_network_security}" == "xtls" ];then
			local xray_network_security_ai=$(wt_node_get_plain xray_network_security_ai ${nu})
			local xray_network_security_alpn_h2=$(wt_node_get_plain xray_network_security_alpn_h2 ${nu})
			local xray_network_security_alpn_ht=$(wt_node_get_plain xray_network_security_alpn_http ${nu})
			if [ "${xray_network_security_alpn_h2}" == "1" -a "${xray_network_security_alpn_ht}" == "1" ];then
				local apln="[\"h2\",\"http/1.1\"]"
			elif [ "${xray_network_security_alpn_h2}" != "1" -a "${xray_network_security_alpn_ht}" == "1" ];then
				local apln="[\"http/1.1\"]"
			elif [ "${xray_network_security_alpn_h2}" == "1" -a "${xray_network_security_alpn_ht}" != "1" ];then
				local apln="[\"h2\"]"
			else
				local apln="null"
			fi

			if [ "${xray_network_security_ai}" != "1" ];then
				local _tmp="{
						\"alpn\": ${apln}
						,\"serverName\": $(wt_get_value_null ${xray_network_security_sni})
						,\"fingerprint\": $(wt_get_value_empty ${xray_fingerprint})
						,\"pinnedPeerCertSha256\": $(wt_get_value_empty ${xray_pcs})
						,\"verifyPeerCertByName\": $(wt_get_value_empty ${xray_vcn})
						}"
			else
				local _tmp="{
						\"allowInsecure\": true
						,\"alpn\": ${apln}
						,\"serverName\": $(wt_get_value_null ${xray_network_security_sni})
						,\"fingerprint\": $(wt_get_value_empty ${xray_fingerprint})
						}"
			fi
			if [ "${xray_network_security}" == "tls" ];then
				local tls="${_tmp}"
			else
				local xtls="${_tmp}"
			fi
		fi

		if [ "${xray_network_security}" == "reality" ];then
			local xray_show=$(wt_node_get_plain xray_show ${nu})
			local xray_publickey=$(wt_node_get_plain xray_publickey ${nu})
			local xray_shortid=$(wt_node_get_plain xray_shortid ${nu})
			local xray_spiderx=$(wt_node_get_plain xray_spiderx ${nu})
			local reali="{
					\"show\": $(get_function_switch ${xray_show})
					,\"fingerprint\": $(wt_get_value_empty ${xray_fingerprint})
					,\"serverName\": $(wt_get_value_null ${xray_network_security_sni})
					,\"publicKey\": $(wt_get_value_null ${xray_publickey})
					,\"shortId\": $(wt_get_value_empty ${xray_shortid})
					,\"spiderX\": $(wt_get_value_empty ${xray_spiderx})
					}"
		fi

		local xray_network=$(wt_node_get_plain xray_network ${nu})
		[ -z "${xray_network}" ] && xray_network="tcp"
		case "${xray_network}" in
		tcp)
			if [ "$(wt_node_get_plain xray_headtype_tcp ${nu})" == "http" ]; then
				local tcp="{
					\"header\": {
					\"type\": \"http\"
					,\"request\": {
					\"version\": \"1.1\"
					,\"method\": \"GET\"
					,\"path\": $(wt_get_path_empty ${xray_network_path})
					,\"headers\": {
					\"Host\": $(wt_get_host_empty ${xray_network_host}),
					\"User-Agent\": [
					\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\"
					,\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"
					]
					,\"Accept-Encoding\": [\"gzip, deflate\"]
					,\"Connection\": [\"keep-alive\"]
					,\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350
				,\"tti\": 50
				,\"uplinkCapacity\": 12
				,\"downlinkCapacity\": 100
				,\"congestion\": false
				,\"readBufferSize\": 2
				,\"writeBufferSize\": 2
				,\"header\": {
				\"type\": \"$(wt_node_get_plain xray_headtype_kcp ${nu})\"
				}
				,\"seed\": $(wt_get_value_null $(wt_node_get_plain xray_kcp_seed ${nu}))
				}"
			;;
		ws)
			if [ -z "${xray_network_path}" -a -z "${xray_network_host}" ]; then
				local ws="{}"
			elif [ -z "${xray_network_path}" -a -n "${xray_network_host}" ]; then
				local ws="{
					\"headers\": $(wt_get_ws_header ${xray_network_host})
					}"
			elif [ -n "${xray_network_path}" -a -z "${xray_network_host}" ]; then
				local ws="{
					\"path\": $(wt_get_value_null ${xray_network_path})
					}"
			else
				local ws="{
					\"path\": $(wt_get_value_null ${xray_network_path}),
					\"headers\": $(wt_get_ws_header ${xray_network_host})
					}"
			fi
			;;
		h2)
			local h2="{
				\"path\": $(wt_get_value_empty ${xray_network_path})
				,\"host\": $(wt_get_host ${xray_network_host})
				}"
			;;
		quic)
			local qc="{
				\"security\": $(wt_get_value_empty ${xray_network_host}),
				\"key\": $(wt_get_value_empty ${xray_network_path}),
				\"header\": {
				\"type\": \"$(wt_node_get_plain xray_headtype_quic ${nu})\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(wt_get_value_empty ${xray_network_path}),
				\"authority\": $(wt_get_value_empty ${xray_grpc_authority}),
				\"multiMode\": $(wt_get_grpc_multimode $(wt_node_get_plain xray_grpc_mode ${nu}))
				}"
			;;
		xhttp)
			local xht="{
				\"path\": $(wt_get_value_empty ${xray_network_path})
				,\"host\": $(wt_get_value_empty ${xray_network_host})
				,\"mode\": \"${xray_xhttp_mode}\"
				}"
			;;
		httpupgrade)
			local htup="{
				\"path\": $(wt_get_value_empty ${xray_network_path})
				,\"host\": $(wt_get_value_empty ${xray_network_host})
				}"
			;;
		esac

		local xray_port=$(wt_node_get_plain port ${nu})
		local xray_uuid=$(wt_node_get_plain xray_uuid ${nu})
		local xray_user_json
		if [ "${xray_prot}" = "vless" ];then
			xray_user_json=$(cat <<-EOF
										"id": "${xray_uuid}"
										,"encryption": "${xray_encryption}"
										,"flow": $(wt_get_value_null ${xray_flow})
			EOF
			)
		else
			[ -z "${xray_encryption}" -o "${xray_encryption}" = "none" ] && xray_encryption="auto"
			xray_user_json=$(cat <<-EOF
										"id": "${xray_uuid}"
										,"security": "${xray_encryption}"
			EOF
			)
		fi

		cat >"${out_file}" <<-EOF
			{
				"tag": "proxy${nu}",
				"protocol": "${xray_prot}",
				"settings": {
					"vnext": [
						{
							"address": "${_server_ip}",
							"port": ${xray_port},
							"users": [
								{
${xray_user_json}
								}
							]
						}
					]
				},
				"streamSettings": {
					"network": "${xray_network}"
					,"security": "${xray_network_security}"
					,"tlsSettings": $tls
					,"xtlsSettings": $xtls
					,"realitySettings": $reali
					,"tcpSettings": $tcp
					,"kcpSettings": $kcp
					,"wsSettings": $ws
					,"httpSettings": $h2
					,"quicSettings": $qc
					,"grpcSettings": $gr
					,"httpupgradeSettings": $htup
					,"xhttpSettings": $xht
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${ss_basic_tfo})}
				},
				"mux": {"enabled": false}
			}
		EOF

		wt_strip_null_keys "${out_file}"
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' "${out_file}" 2>/dev/null
		fi
	else
		wt_node_get_plain xray_json ${nu} >${TMP2}/xray_user_${nu}.json
		local user_host=""
		local user_host_addr=""
		{
			read -r user_host
			read -r _
		} <<-EOF
		$(fss_get_node_server_host_port "${nu}")
		EOF
		user_host_addr=$(wt_get_server_addr "${user_host}")
		wt_wrap_user_outbound_json "${TMP2}/xray_user_${nu}.json" "${user_host_addr}" "${out_file}" "proxy${nu}"
	fi
}

wt_gen_trojan_outbound() {
	local nu="$1"
	local mark="$2"
	local out_file=""

	local trojan_server=$(wt_node_get_plain server ${nu})
	local trojan_port=$(wt_node_get_plain port ${nu})
	local trojan_uuid=$(wt_node_get_plain trojan_uuid ${nu})
	local trojan_sni=$(wt_node_get_plain trojan_sni ${nu})
	local trojan_pcs=$(wt_node_get_plain trojan_pcs ${nu})
	local trojan_vcn=$(wt_node_get_plain trojan_vcn ${nu})
	local trojan_ai=$(wt_node_get_plain trojan_ai ${nu})
	local trojan_tfo=$(wt_node_get_plain trojan_tfo ${nu})

	local _server_ip=$(wt_get_server_addr "${trojan_server}")
	out_file=$(wt_get_out_file_path "${nu}" "${mark}")

	if [ -n "$(wt_node_get_plain trojan_plugin ${nu})" -a "$(wt_node_get_plain trojan_plugin ${nu})" == "obfs-local" -a "$(wt_node_get_plain trojan_obfs ${nu})" == "websocket" ];then
		local _trojan_network="ws"
		local _trojan_ws="{
							\"path\": \"$(wt_node_get_plain trojan_obfsuri ${nu})\",
							\"headers\": {
								\"Host\": \"$(wt_node_get_plain trojan_obfshost ${nu})\"
							}
						 }"
	else
		local _trojan_network="tcp"
		local _trojan_ws=null
	fi

	cat >"${out_file}" <<-EOF
		{
			"tag": "proxy${nu}",
			"protocol": "trojan",
			"settings": {
				"servers": [{
					"address": "${_server_ip}",
					"port": ${trojan_port},
					"password": "${trojan_uuid}"
				}
				]
			},
			"streamSettings": {
				"network": "${_trojan_network}",
				"security": "tls",
				"tlsSettings": {
					"serverName": $(wt_get_value_null ${trojan_sni}),
					"pinnedPeerCertSha256": $(wt_get_value_empty ${trojan_pcs}),
					"verifyPeerCertByName": $(wt_get_value_empty ${trojan_vcn}),
					"allowInsecure": $(get_function_switch ${trojan_ai})
				},
				"wsSettings": ${_trojan_ws},
				"sockopt": {"tcpFastOpen": $(get_function_switch ${trojan_tfo})}
			}
		}
	EOF

	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' "${out_file}" 2>/dev/null
	fi
}

wt_gen_hy2_outbound() {
	local nu="$1"
	local mark="$2"
	local out_file=""

	local hy2_server=$(wt_node_get_plain hy2_server ${nu})
	local hy2_port=$(wt_node_get_plain hy2_port ${nu})
	local hy2_pass=$(wt_node_get_plain hy2_pass ${nu})
	local hy2_up=$(wt_node_get_plain hy2_up ${nu})
	local hy2_dl=$(wt_node_get_plain hy2_dl ${nu})
	local hy2_obfs=$(wt_node_get_plain hy2_obfs ${nu})
	local hy2_obfs_pass=$(wt_node_get_plain hy2_obfs_pass ${nu})
	local hy2_sni=$(wt_node_get_plain hy2_sni ${nu})
	local hy2_pcs=$(wt_node_get_plain hy2_pcs ${nu})
	local hy2_vcn=$(wt_node_get_plain hy2_vcn ${nu})
	local hy2_ai=$(wt_node_get_plain hy2_ai ${nu})
	local hy2_tfo=$(wt_node_get_plain hy2_tfo ${nu})
	local hy2_cg=$(wt_node_get_plain hy2_cg ${nu})

	if [ -z "${hy2_sni}" ];then
		__valid_ip_silent "${hy2_server}"
		if [ "$?" != "0" ];then
			hy2_sni="${hy2_server}"
		else
			hy2_sni=""
		fi
	fi

	local _server_ip=$(wt_get_server_addr "${hy2_server}")
	out_file=$(wt_get_out_file_path "${nu}" "${mark}")

	cat >"${out_file}" <<-EOF
		{
			"tag": "proxy${nu}",
			"protocol": "hysteria",
			"settings": {
				"version": 2,
				"address": "${_server_ip}",
				"port": $(wt_get_hy2_port ${hy2_port})
			},
			"streamSettings": {
				"network": "hysteria",
				"hysteriaSettings": {
					"version": 2
					,"auth": $(wt_get_value_empty ${hy2_pass})
					,"congestion": $(wt_get_value_congestion ${hy2_up} ${hy2_dl} ${hy2_cg})
					,"up": $(wt_get_value_speed ${hy2_up})
					,"down": $(wt_get_value_speed ${hy2_dl})
					,"udphop": {
						"port": $(wt_get_hy2_udphop_port ${hy2_port}),
						"interval": 30
					}
				}
				,"security": "tls"
				,"tlsSettings": {
					"serverName": "${hy2_sni}"
	EOF
	if [ "${hy2_ai}" != "1" ];then
		cat >>"${out_file}" <<-EOF
						,"pinnedPeerCertSha256": $(wt_get_value_empty ${hy2_pcs})
						,"verifyPeerCertByName": $(wt_get_value_empty ${hy2_vcn})
		EOF
	else
		cat >>"${out_file}" <<-EOF
						,"allowInsecure": true
		EOF
	fi
	cat >>"${out_file}" <<-EOF
						,"alpn": ["h3"]
					}
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${hy2_tfo})}
	EOF
	if [ "${hy2_obfs}" == "1" -a -n "${hy2_obfs_pass}" ];then
		cat >>"${out_file}" <<-EOF
					,"finalmask": {
						"udp": [
						{
							"type": "salamander",
							"settings": {
								"password": "${hy2_obfs_pass}"
							}
						}]
			}
		EOF
	fi
	cat >>"${out_file}" <<-EOF
				}
		}
	EOF

	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' "${out_file}" 2>/dev/null
	fi
}
