#!/bin/sh
#
# Shared config generators for ss_webtest.sh
# Keep logic consistent with ssconfig.sh where possible.

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

wt_write_inbound_routing() {
	local nu="$1"
	local mark="$2"
	local socks5_port=$(get_rand_port)
	echo "export socks5_port_${nu}=${socks5_port}" >> ${TMP2}/socsk5_ports.txt
	cat >${TMP2}/conf_${mark}/${nu}_inbounds.json <<-EOF
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
	cat >${TMP2}/conf_${mark}/${nu}_routing.json <<-EOF
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

wt_gen_ss_outbound() {
	local nu="$1"
	local mark="$2"

	local ss_server=$(dbus get ssconf_basic_server_${nu})
	local _server_ip=$(_get_server_ip ${ss_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${ss_server}
	fi
	local ss_port=$(dbus get ssconf_basic_port_${nu})
	local ss_pass=$(dbus get ssconf_basic_password_${nu} | base64_decode)
	local ss_meth=$(dbus get ssconf_basic_method_${nu})

	if [ "${ss_basic_tfo}" == "1" -a "${LINUX_VER}" != "26" ]; then
		local OBFS_ARG="--fast-open"
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
	else
		local OBFS_ARG=""
	fi

	if [ "$(dbus get ssconf_basic_ss_obfs_${nu})" == "http" -o "$(dbus get ssconf_basic_ss_obfs_${nu})" == "tls" ]; then
		local obfs_port=$(get_rand_port)
		local _server_ip_tmp="127.0.0.1"
		local _server_port_tmp="${obfs_port}"
		if [ -n "$(dbus get ssconf_basic_ss_obfs_host_${nu})" ]; then
			cat >>"${TMP2}/bash_${mark}/start_${nu}.sh" <<-EOF
				#!/bin/sh
				${TMP2}/wt-obfs -s ${_server_ip} -p ${ss_port} -l ${_server_port_tmp} --obfs $(dbus get ssconf_basic_ss_obfs_${nu}) --obfs-host $(dbus get ssconf_basic_ss_obfs_host_${nu}) ${OBFS_ARG} >/dev/null 2>&1 &
			EOF
		else
			cat >>"${TMP2}/bash_${mark}/start_${nu}.sh" <<-EOF
				#!/bin/sh
				${TMP2}/wt-obfs -s ${_server_ip} -p ${ss_port} -l ${_server_port_tmp} --obfs $(dbus get ssconf_basic_ss_obfs_${nu}) ${OBFS_ARG} >/dev/null 2>&1 &
			EOF
		fi
		cat >${TMP2}/bash_${mark}/stop_${nu}.sh <<-EOF
			#!/bin/sh
			_pid=\$(ps -w | grep "wt-obfs" | grep -w "${_server_ip}" | grep -w "${ss_port}" | grep -w "${_server_port_tmp}" | awk '{print \$1}' | sed -n '1p')
			if [ -n "\${_pid}" ];then
			    kill -9 \${_pid}
			fi
		EOF
		chmod +x ${TMP2}/bash_${mark}/start_${nu}.sh
		chmod +x ${TMP2}/bash_${mark}/stop_${nu}.sh
		local _uot="true"
	else
		local _server_ip_tmp="${_server_ip}"
		local _server_port_tmp="${ss_port}"
		local _uot="false"
	fi

	cat >${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
		{
		"outbounds": [
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
		]
		}
	EOF

	sed -i '/null/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
	fi
}

wt_gen_vmess_outbound() {
	local nu="$1"
	local mark="$2"
	local v2ray_use_json=$(dbus get ssconf_basic_v2ray_use_json_${nu})
	if [ "${v2ray_use_json}" != "1" ]; then
		local v2ray_server=$(dbus get ssconf_basic_server_${nu})
		local _server_ip=$(_get_server_ip ${v2ray_server})
		if [ -z "${_server_ip}" ];then
			_server_ip=${v2ray_server}
		fi

		local tcp="null"
		local kcp="null"
		local ws="null"
		local h2="null"
		local qc="null"
		local gr="null"
		local tls="null"

		local v2ray_network=$(dbus get ssconf_basic_v2ray_network_${nu})
		[ -z "${v2ray_network}" ] && v2ray_network="tcp"
		local v2ray_network_host_raw=$(dbus get ssconf_basic_v2ray_network_host_${nu})
		local v2ray_network_host=$(echo ${v2ray_network_host_raw} | sed 's/,/", "/g')
		local v2ray_network_path=$(dbus get ssconf_basic_v2ray_network_path_${nu})
		local v2ray_network_security=$(dbus get ssconf_basic_v2ray_network_security_${nu})
		[ -z "${v2ray_network_security}" ] && v2ray_network_security="none"

		if [ "$(dbus get ssconf_basic_v2ray_mux_enable_${nu})" == "1" -a -z "$(dbus get ssconf_basic_v2ray_mux_concurrency_${nu})" ];then
			local v2ray_mux_concurrency=8
		else
			local v2ray_mux_concurrency=$(dbus get ssconf_basic_v2ray_mux_concurrency_${nu})
		fi
		if [ "$(dbus get ssconf_basic_v2ray_mux_enable_${nu})" != "1" ];then
			local v2ray_mux_concurrency="-1"
		fi

		if [ "${v2ray_network_security}" == "none" ];then
			local v2ray_network_security_ai=""
			local v2ray_network_security_alpn_h2=""
			local v2ray_network_security_alpn_http=""
			local v2ray_network_security_sni=""
		else
			local v2ray_network_security_ai=$(dbus get ssconf_basic_v2ray_network_security_ai_${nu})
			local v2ray_network_security_alpn_h2=$(dbus get ssconf_basic_v2ray_network_security_alpn_h2_${nu})
			local v2ray_network_security_alpn_http=$(dbus get ssconf_basic_v2ray_network_security_alpn_http_${nu})
			local v2ray_network_security_sni=$(dbus get ssconf_basic_v2ray_network_security_sni_${nu})
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
			if [ "$(dbus get ssconf_basic_v2ray_headtype_tcp_${nu})" == "http" ]; then
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
				\"type\": \"$(dbus get ssconf_basic_v2ray_headtype_kcp_${nu})\"
				}
				,\"seed\": $(wt_get_value_null $(dbus get ssconf_basic_v2ray_kcp_seed_${nu}))
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
				\"type\": \"$(dbus get ssconf_basic_v2ray_headtype_quic_${nu})\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(wt_get_value_empty ${v2ray_network_path}),
				\"multiMode\": $(wt_get_grpc_multimode $(dbus get ssconf_basic_v2ray_grpc_mode_${nu}))
				}"
			;;
		esac

		cat >${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
			{
			"outbounds": [
				{
					"tag": "proxy${nu}",
					"protocol": "vmess",
					"settings": {
						"vnext": [
							{
								"address": "${_server_ip}",
								"port": $(dbus get ssconf_basic_port_${nu}),
								"users": [
									{
										"id": "$(dbus get ssconf_basic_v2ray_uuid_${nu})"
										,"alterId": $(dbus get ssconf_basic_v2ray_alterid_${nu})
										,"security": "$(dbus get ssconf_basic_v2ray_security_${nu})"
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
						"enabled": $(get_function_switch $(dbus get ssconf_basic_v2ray_mux_enable_${nu})),
						"concurrency": ${v2ray_mux_concurrency}
					}
				}
			]
			}
		EOF

		sed -i '/null/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
	else
		dbus get ssconf_basic_v2ray_json_${nu} | base64_decode >${TMP2}/v2ray_user_${nu}.json
		local OB=$(cat ${TMP2}/v2ray_user_${nu}.json | run jq .outbound)
		local OBS=$(cat ${TMP2}/v2ray_user_${nu}.json | run jq .outbounds)
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat ${TMP2}/v2ray_user_${nu}.json | run jq .outbound)
		fi
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat ${TMP2}/v2ray_user_${nu}.json | run jq .outbounds[0])
		fi
		echo "{}" | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >${TMP2}/conf_${mark}/${nu}_outbounds.json
	fi
}

wt_gen_vless_outbound() {
	local nu="$1"
	local mark="$2"
	local xray_use_json=$(dbus get ssconf_basic_xray_use_json_${nu})
	if [ "${xray_use_json}" != "1" ]; then
		local xray_server=$(dbus get ssconf_basic_server_${nu})
		local _server_ip=$(_get_server_ip ${xray_server})
		if [ -z "${_server_ip}" ];then
			_server_ip=${xray_server}
		fi

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

		local xray_network_host_raw=$(dbus get ssconf_basic_xray_network_host_${nu})
		local xray_network_host=$(echo ${xray_network_host_raw} | sed 's/,/", "/g')
		local xray_network_path=$(dbus get ssconf_basic_xray_network_path_${nu})
		local xray_network_security_sni=$(dbus get ssconf_basic_xray_network_security_sni_${nu})
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
		local xray_flow=$(dbus get ssconf_basic_xray_flow_${nu})
		local xray_fingerprint=$(dbus get ssconf_basic_xray_fingerprint_${nu})
		[ -z "${xray_fingerprint}" ] && xray_fingerprint="chrome"
		local xray_pcs=$(dbus get ssconf_basic_xray_pcs_${nu})
		local xray_svn=$(dbus get ssconf_basic_xray_svn_${nu})
		local xray_network_security=$(dbus get ssconf_basic_xray_network_security_${nu})
		[ -z "${xray_network_security}" ] && xray_network_security="none"
		local xray_xhttp_mode=$(dbus get ssconf_basic_xray_xhttp_mode_${nu})

		if [ "${xray_network_security}" == "none" ];then
			xray_flow=""
		fi

		if [ "${xray_network_security}" == "tls" -o "${xray_network_security}" == "xtls" ];then
			local xray_network_security_ai=$(dbus get ssconf_basic_xray_network_security_ai_${nu})
			local xray_network_security_alpn_h2=$(dbus get ssconf_basic_xray_network_security_alpn_h2_${nu})
			local xray_network_security_alpn_ht=$(dbus get ssconf_basic_xray_network_security_alpn_http_${nu})
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
						,\"verifyPeerCertByName\": $(wt_get_value_empty ${xray_svn})
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
			local xray_show=$(dbus get ssconf_basic_xray_show_${nu})
			local xray_publickey=$(dbus get ssconf_basic_xray_publickey_${nu})
			local xray_shortid=$(dbus get ssconf_basic_xray_shortid_${nu})
			local xray_spiderx=$(dbus get ssconf_basic_xray_spiderx_${nu})
			local reali="{
					\"show\": $(get_function_switch ${xray_show})
					,\"fingerprint\": $(wt_get_value_empty ${xray_fingerprint})
					,\"serverName\": $(wt_get_value_null ${xray_network_security_sni})
					,\"publicKey\": $(wt_get_value_null ${xray_publickey})
					,\"shortId\": $(wt_get_value_empty ${xray_shortid})
					,\"spiderX\": $(wt_get_value_empty ${xray_spiderx})
					}"
		fi

		local xray_network=$(dbus get ssconf_basic_xray_network_${nu})
		[ -z "${xray_network}" ] && xray_network="tcp"
		case "${xray_network}" in
		tcp)
			if [ "$(dbus get ssconf_basic_xray_headtype_tcp_${nu})" == "http" ]; then
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
				\"type\": \"$(dbus get ssconf_basic_xray_headtype_kcp_${nu})\"
				}
				,\"seed\": $(wt_get_value_null $(dbus get ssconf_basic_xray_kcp_seed_${nu}))
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
				\"type\": \"$(dbus get ssconf_basic_xray_headtype_quic_${nu})\"
				}
				}"
			;;
		grpc)
			local gr="{
				\"serviceName\": $(wt_get_value_empty ${xray_network_path}),
				\"multiMode\": $(wt_get_grpc_multimode $(dbus get ssconf_basic_xray_grpc_mode_${nu}))
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

		local xray_port=$(dbus get ssconf_basic_port_${nu})
		local xray_uuid=$(dbus get ssconf_basic_xray_uuid_${nu})
		local xray_prot=$(dbus get ssconf_basic_xray_prot_${nu})
		local xray_alterid=$(dbus get ssconf_basic_xray_alterid_${nu})
		local xray_encryption=$(dbus get ssconf_basic_xray_encryption_${nu})
		[ -z "${xray_prot}" ] && xray_prot="vless"
		[ -z "${xray_alterid}" ] && xray_alterid="0"

		cat >${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
			{
			"outbounds": [
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
										"id": "${xray_uuid}"
										,"alterId": ${xray_alterid}
										,"security": "auto"
										,"encryption": "${xray_encryption}"
										,"flow": $(wt_get_value_null ${xray_flow})
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
			]
			}
		EOF

		sed -i '/null/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
		if [ "${xray_prot}" == "vless" ];then
			sed -i '/alterId/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
		fi
		if [ "${LINUX_VER}" == "26" ]; then
			sed -i '/tcpFastOpen/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
		fi
	else
		dbus get ssconf_basic_xray_json_${nu} | base64_decode >${TMP2}/xray_user_${nu}.json
		local OB=$(cat ${TMP2}/xray_user_${nu}.json | run jq .outbound)
		local OBS=$(cat ${TMP2}/xray_user_${nu}.json | run jq .outbounds)
		if [ "$OB" != "null" ]; then
			OUTBOUNDS=$(cat ${TMP2}/xray_user_${nu}.json | run jq .outbound)
		fi
		if [ "$OBS" != "null" ]; then
			OUTBOUNDS=$(cat ${TMP2}/xray_user_${nu}.json | run jq .outbounds[0])
		fi
		echo "{}" | run jq --argjson args "$OUTBOUNDS" '. + {outbounds: [$args]}' >${TMP2}/conf_${mark}/${nu}_outbounds.json
	fi
}

wt_gen_trojan_outbound() {
	local nu="$1"
	local mark="$2"

	local trojan_server=$(dbus get ssconf_basic_server_${nu})
	local trojan_port=$(dbus get ssconf_basic_port_${nu})
	local trojan_uuid=$(dbus get ssconf_basic_trojan_uuid_${nu})
	local trojan_sni=$(dbus get ssconf_basic_trojan_sni_${nu})
	local trojan_ai=$(dbus get ssconf_basic_trojan_ai_${nu})
	local trojan_tfo=$(dbus get ssconf_basic_trojan_tfo_${nu})

	local _server_ip=$(_get_server_ip ${trojan_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${trojan_server}
	fi

	if [ -n "$(dbus get ssconf_basic_trojan_plugin_${nu})" -a "$(dbus get ssconf_basic_trojan_plugin_${nu})" == "obfs-local" -a "$(dbus get ssconf_basic_trojan_obfs_${nu})" == "websocket" ];then
		local _trojan_network="ws"
		local _trojan_ws="{
							\"path\": \"$(dbus get ssconf_basic_trojan_obfsuri_${nu})\",
							\"headers\": {
								\"Host\": \"$(dbus get ssconf_basic_trojan_obfshost_${nu})\"
							}
						 }"
	else
		local _trojan_network="tcp"
		local _trojan_ws=null
	fi

	cat >${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
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
					"network": "${_trojan_network}",
					"security": "tls",
					"tlsSettings": {
						"serverName": $(wt_get_value_null ${trojan_sni}),
						"allowInsecure": $(get_function_switch ${trojan_ai})
					}
					,"wsSettings": ${_trojan_ws}
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${trojan_tfo})}
				}
			}
		]
		}
	EOF

	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
	fi
}

wt_gen_hy2_outbound() {
	local nu="$1"
	local mark="$2"

	local hy2_server=$(dbus get ssconf_basic_hy2_server_${nu})
	local hy2_port=$(dbus get ssconf_basic_hy2_port_${nu})
	local hy2_pass=$(dbus get ssconf_basic_hy2_pass_${nu})
	local hy2_up=$(dbus get ssconf_basic_hy2_up_${nu})
	local hy2_dl=$(dbus get ssconf_basic_hy2_dl_${nu})
	local hy2_obfs=$(dbus get ssconf_basic_hy2_obfs_${nu})
	local hy2_obfs_pass=$(dbus get ssconf_basic_hy2_obfs_pass_${nu})
	local hy2_sni=$(dbus get ssconf_basic_hy2_sni_${nu})
	local hy2_pcs=$(dbus get ssconf_basic_hy2_pcs_${nu})
	local hy2_svn=$(dbus get ssconf_basic_hy2_svn_${nu})
	local hy2_ai=$(dbus get ssconf_basic_hy2_ai_${nu})
	local hy2_tfo=$(dbus get ssconf_basic_hy2_tfo_${nu})
	local hy2_cg=$(dbus get ssconf_basic_hy2_cg_${nu})

	if [ -z "${hy2_sni}" ];then
		__valid_ip_silent "${hy2_server}"
		if [ "$?" != "0" ];then
			hy2_sni="${hy2_server}"
		else
			hy2_sni=""
		fi
	fi

	local _server_ip=$(_get_server_ip ${hy2_server})
	if [ -z "${_server_ip}" ];then
		_server_ip=${hy2_server}
	fi

	cat >${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
		{
		"outbounds": [
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
		cat >>${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
						,"pinnedPeerCertSha256": $(wt_get_value_empty ${hy2_pcs})
						,"verifyPeerCertByName": $(wt_get_value_empty ${hy2_svn})
		EOF
	else
		cat >>${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
						,"allowInsecure": true
		EOF
	fi
	cat >>${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
						,"alpn": ["h3"]
					}
					,"sockopt": {"tcpFastOpen": $(get_function_switch ${hy2_tfo})}
	EOF
	if [ "${hy2_obfs}" == "1" -a -n "${hy2_obfs_pass}" ];then
		cat >>${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
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
	cat >>${TMP2}/conf_${mark}/${nu}_outbounds.json <<-EOF
				}
			}
		]
		}
	EOF

	if [ "${LINUX_VER}" == "26" ]; then
		sed -i '/tcpFastOpen/d' ${TMP2}/conf_${mark}/${nu}_outbounds.json 2>/dev/null
	fi
}
