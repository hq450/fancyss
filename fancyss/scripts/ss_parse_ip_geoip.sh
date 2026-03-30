#!/bin/sh
# IP/GEOIP 规则解析辅助脚本
# 用法: parse_ip_geoip_rules.sh <input_file> <ip_output> <geoip_output>

input_file="$1"
ip_output="$2"
geoip_output="$3"

[ -f "${input_file}" ] || exit 1
[ -n "${ip_output}" ] || exit 1
[ -n "${geoip_output}" ] || exit 1

awk -v ip_file="${ip_output}" -v geoip_file="${geoip_output}" '
{
	gsub(/\r/, "")
	sub(/#.*/, "")
	gsub(/^[[:space:]]+|[[:space:]]+$/, "")
	if ($0 == "") next

	lower = tolower($0)

	# IP-CIDR 规则
	if (lower ~ /^ip-cidr:/) {
		value = substr(lower, 9)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		# 验证 IPv4/IPv6 CIDR
		if (value ~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(\/[0-9]{1,2})?$/ ||
		    value ~ /^[0-9a-f:]+\/[0-9]{1,3}$/) {
			if (!seen_ip[value]++) {
				print value > ip_file
				ip_count++
			}
		}
		next
	}

	# GEOIP 规则
	if (lower ~ /^geoip:/) {
		value = substr(lower, 7)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		# 验证 geoip 标签
		if (value ~ /^[a-z0-9_-]+$/) {
			if (!seen_geoip[value]++) {
				print value > geoip_file
				geoip_count++
			}
		}
		next
	}
}
END {
	printf "%d|%d\n", ip_count + 0, geoip_count + 0
}
' "${input_file}"
