#!/bin/sh

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)"
SRC_DIR="${REPO_ROOT}/rules_ng2/shunt"
PKG_DIR="${REPO_ROOT}/fancyss/ss/rules_ng2/shunt"
MANIFEST_FILE="${REPO_ROOT}/fancyss/res/shunt_manifest.json.js"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fss_shunt_ng2.XXXXXX")"

cleanup() {
	rm -rf "${TMP_DIR}"
}
trap cleanup EXIT INT TERM

mkdir -p "${SRC_DIR}" "${PKG_DIR}"

fetch_remote_list() {
	local url="$1"

	curl -fsSL --connect-timeout 15 --retry 3 --retry-delay 1 "${url}"
}

convert_remote_list() {
	awk -F ',' '
	BEGIN {
		IGNORECASE = 1
	}
	/^[[:space:]]*#/ || /^[[:space:]]*$/ {
		next
	}
	{
		type = tolower($1)
		value = tolower($2)
		gsub(/\r/, "", value)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		if (value == "") {
			next
		}
		if (type == "domain") {
			prefix = "full"
		} else if (type == "domain-suffix") {
			prefix = "domain"
		} else if (type == "domain-keyword") {
			prefix = "keyword"
		} else {
			next
		}
		if (prefix == "keyword") {
			if (value ~ /^[a-z0-9._-]+$/) {
				print prefix ":" value
			}
		} else if (value ~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) {
			print prefix ":" value
		}
	}'
}

convert_local_gfw_list() {
	gzip -dc "${REPO_ROOT}/rules_ng/gfwlist.gz" | awk '
	/^[[:space:]]*#/ || /^[[:space:]]*$/ {
		next
	}
	{
		value = tolower($0)
		gsub(/\r/, "", value)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		if (value ~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) {
			print "domain:" value
		}
	}'
}

emit_manifest() {
	local tmp_manifest="${TMP_DIR}/manifest.js"
	local first=1
	local id label desc source type count

	printf 'var SHUNT_PRESET_MANIFEST = [' > "${tmp_manifest}"
	while IFS='|' read -r id label desc source type
	do
		[ -n "${id}" ] || continue
		count="$(wc -l < "${SRC_DIR}/${id}.txt" | tr -d ' ')"
		[ -n "${count}" ] || count=0
		if [ "${first}" = "1" ]; then
			first=0
		else
			printf ',' >> "${tmp_manifest}"
		fi
		printf '{"id":"%s","label":"%s","description":"%s","file":"rules_ng2/shunt/%s.txt","count":%s}' \
			"${id}" "${label}" "${desc}" "${id}" "${count}" >> "${tmp_manifest}"
	done <<-'EOF'
ai|AI|AI 常见域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/ai.list|remote
media|媒体合集|常见流媒体与媒体域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/media.list|remote
youtube|YouTube|YouTube 及 Google Video 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/youtube.list|remote
netflix|Netflix|Netflix 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/netflix.list|remote
disney|Disney+|Disney+ 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/disney.list|remote
max|Max|Max / HBO Max 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/max.list|remote
primevideo|Prime Video|Prime Video 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/primevideo.list|remote
appletv|Apple TV+|Apple TV+ 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/appletv.list|remote
spotify|Spotify|Spotify 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/spotify.list|remote
tiktok|TikTok|TikTok 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/tiktok.list|remote
bilibili|Bilibili|哔哩哔哩海外与国际化域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/bilibili.list|remote
games|Games|常见游戏平台与游戏服务域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/games.list|remote
networktest|测速站点|网络测试与测速域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/networktest.list|remote
gfw|GFW 扩展|补充代理常见域名|local:gfwlist|local
EOF
	printf '];\n' >> "${tmp_manifest}"
	mv -f "${tmp_manifest}" "${MANIFEST_FILE}"
}

while IFS='|' read -r id label desc source type
do
	[ -n "${id}" ] || continue
	if [ "${type}" = "local" ]; then
		convert_local_gfw_list | sort -u > "${SRC_DIR}/${id}.txt"
	else
		fetch_remote_list "${source}" | convert_remote_list | sort -u > "${SRC_DIR}/${id}.txt"
	fi
done <<-'EOF'
ai|AI|AI 常见域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/ai.list|remote
media|媒体合集|常见流媒体与媒体域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/media.list|remote
youtube|YouTube|YouTube 及 Google Video 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/youtube.list|remote
netflix|Netflix|Netflix 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/netflix.list|remote
disney|Disney+|Disney+ 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/disney.list|remote
max|Max|Max / HBO Max 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/max.list|remote
primevideo|Prime Video|Prime Video 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/primevideo.list|remote
appletv|Apple TV+|Apple TV+ 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/appletv.list|remote
spotify|Spotify|Spotify 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/spotify.list|remote
tiktok|TikTok|TikTok 相关域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/tiktok.list|remote
bilibili|Bilibili|哔哩哔哩海外与国际化域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/bilibili.list|remote
games|Games|常见游戏平台与游戏服务域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/games.list|remote
networktest|测速站点|网络测试与测速域名|https://raw.githubusercontent.com/DustinWin/domain-list-custom/domains/networktest.list|remote
gfw|GFW 扩展|补充代理常见域名|local:gfwlist|local
EOF

rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}"
cp -f "${SRC_DIR}"/*.txt "${PKG_DIR}/"

emit_manifest
