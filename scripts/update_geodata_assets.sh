#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
RULES_ROOT="${REPO_ROOT}/rules_ng2"
SITE_DIR="${RULES_ROOT}/site"
IP_DIR="${RULES_ROOT}/ip"
META_DIR="${RULES_ROOT}/meta"
ASSETS_JSON="${META_DIR}/assets.json"
PRESETS_JSON="${META_DIR}/presets.json"
COUNTS_JSON="${META_DIR}/rule_counts.json"
PKG_RULES_ROOT="${REPO_ROOT}/fancyss/ss/rules_ng2"
MANIFEST_FILE="${REPO_ROOT}/fancyss/res/shunt_manifest.json.js"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fss_geodata_assets.XXXXXX")"
DO_FETCH=1

cleanup() {
	rm -rf "${TMP_DIR}"
}
trap cleanup EXIT INT TERM

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "missing dependency: $1" >&2
		exit 1
	}
}

usage() {
	cat <<-'EOF'
	usage: scripts/update_geodata_assets.sh [--no-fetch]

	  --no-fetch   do not pull remote/local generated sources again; only
	               regenerate manifest and package assets from existing site/ip sources.
	EOF
}

while [ "$#" -gt 0 ]
do
	case "$1" in
	--no-fetch)
		DO_FETCH=0
		;;
	-h|--help)
		usage
		exit 0
		;;
	*)
		echo "unknown argument: $1" >&2
		usage >&2
		exit 1
		;;
	esac
	shift
done

need_cmd jq
need_cmd awk
need_cmd sort
need_cmd curl

mkdir -p "${SITE_DIR}" "${IP_DIR}" "${META_DIR}" "${PKG_RULES_ROOT}"

fetch_url() {
	curl -fsSL --connect-timeout 20 --retry 3 --retry-delay 1 "$1"
}

pick_host_geotool() {
	if [ -x "${REPO_ROOT}/tool/geotool/zig-out/bin/geotool" ]; then
		printf '%s\n' "${REPO_ROOT}/tool/geotool/zig-out/bin/geotool"
		return 0
	fi
	if [ -x "${REPO_ROOT}/binaries/geotool/geotool-v1.2-linux-x86_64" ]; then
		printf '%s\n' "${REPO_ROOT}/binaries/geotool/geotool-v1.2-linux-x86_64"
		return 0
	fi
	if command -v geotool >/dev/null 2>&1; then
		command -v geotool
		return 0
	fi
	return 1
}

tsv_to_simple_json() {
	jq -Rn '
		reduce inputs as $line ({};
			($line | split("\t")) as $parts
			| if ($parts | length) >= 2 and ($parts[0] | length) > 0
				then . + { ($parts[0] | ascii_downcase): { total: ($parts[1] | tonumber) } }
				else .
				end
		)
	'
}

tsv_to_ip_json() {
	jq -n \
		--argjson total "$(cat "$1")" \
		--argjson ipv4 "$(cat "$2")" \
		--argjson ipv6 "$(cat "$3")" '
		((((($total | keys_unsorted) + ($ipv4 | keys_unsorted) + ($ipv6 | keys_unsorted)) | unique)) as $keys
		| reduce $keys[] as $key ({};
			.[$key] = {
				total: ($total[$key].total // 0),
				ipv4: ($ipv4[$key].total // 0),
				ipv6: ($ipv6[$key].total // 0)
			}
		))
	'
}

build_count_summary() {
	local geotool_bin=""
	local site_json="{}"
	local ip_json="{}"
	local summary_tmp="${TMP_DIR}/rule_counts.json"
	local source="wc"

	geotool_bin="$(pick_host_geotool 2>/dev/null || true)"
	if [ -n "${geotool_bin}" ] && [ -s "${RULES_ROOT}/dat/geosite.dat" ] && [ -s "${RULES_ROOT}/dat/geoip.dat" ]; then
		source="geotool"
		"${geotool_bin}" stat -i "${RULES_ROOT}/dat/geosite.dat" > "${TMP_DIR}/site_stats.tsv"
		"${geotool_bin}" geoip-stat -i "${RULES_ROOT}/dat/geoip.dat" > "${TMP_DIR}/ip_stats_total.tsv"
		"${geotool_bin}" geoip-stat -i "${RULES_ROOT}/dat/geoip.dat" --ipv4 > "${TMP_DIR}/ip_stats_v4.tsv"
		"${geotool_bin}" geoip-stat -i "${RULES_ROOT}/dat/geoip.dat" --ipv6 > "${TMP_DIR}/ip_stats_v6.tsv"
		site_json="$(tsv_to_simple_json < "${TMP_DIR}/site_stats.tsv")"
		tsv_to_simple_json < "${TMP_DIR}/ip_stats_total.tsv" > "${TMP_DIR}/ip_total.json"
		tsv_to_simple_json < "${TMP_DIR}/ip_stats_v4.tsv" > "${TMP_DIR}/ip_v4.json"
		tsv_to_simple_json < "${TMP_DIR}/ip_stats_v6.tsv" > "${TMP_DIR}/ip_v6.json"
		ip_json="$(tsv_to_ip_json "${TMP_DIR}/ip_total.json" "${TMP_DIR}/ip_v4.json" "${TMP_DIR}/ip_v6.json")"
	else
		find "${SITE_DIR}" -maxdepth 1 -type f -name '*.txt' | sort | while IFS= read -r file
		do
			asset_id="$(basename "${file}" .txt)"
			count="$(wc -l < "${file}" | tr -d ' ')"
			printf '%s\t%s\n' "${asset_id}" "${count:-0}"
		done > "${TMP_DIR}/site_stats.tsv"
		find "${IP_DIR}" -maxdepth 1 -type f -name '*.txt' | sort | while IFS= read -r file
		do
			asset_id="$(basename "${file}" .txt)"
			awk -v id="${asset_id}" '
				BEGIN { total = 0; v4 = 0; v6 = 0 }
				{
					line = $0
					gsub(/\r/, "", line)
					sub(/#.*/, "", line)
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
					if (line == "") next
					total++
					if (line ~ /:/) v6++
					else v4++
				}
				END {
					printf "%s\t%d\t%d\t%d\n", id, total, v4, v6
				}
			' "${file}"
		done > "${TMP_DIR}/ip_stats.tsv"
		site_json="$(tsv_to_simple_json < "${TMP_DIR}/site_stats.tsv")"
		ip_json="$(jq -Rn '
			reduce inputs as $line ({};
				($line | split("\t")) as $parts
				| if ($parts | length) >= 4 and ($parts[0] | length) > 0
					then . + {
						($parts[0] | ascii_downcase): {
							total: ($parts[1] | tonumber),
							ipv4: ($parts[2] | tonumber),
							ipv6: ($parts[3] | tonumber)
						}
					}
					else .
					end
			)
		' < "${TMP_DIR}/ip_stats.tsv")"
	fi

	jq -n \
		--arg source "${source}" \
		--argjson site "${site_json}" \
		--argjson ip "${ip_json}" \
		--slurpfile presets "${PRESETS_JSON}" '
		{
			generated_at: (now | floor),
			source: $source,
			site: $site,
			ip: $ip,
			preset: (
				reduce $presets[0][] as $preset ({};
					.[$preset.id] = {
						site_assets: ($preset.site // []),
						ip_assets: ($preset.ip // []),
						site_count: ([($preset.site // [])[] | ($site[.]?.total // 0)] | add // 0),
						ip_count: ([($preset.ip // [])[] | ($ip[.]?.total // 0)] | add // 0),
						total: (([($preset.site // [])[] | ($site[.]?.total // 0)] | add // 0) + ([($preset.ip // [])[] | ($ip[.]?.total // 0)] | add // 0))
					}
				)
			)
		}
	' > "${summary_tmp}"
	mv -f "${summary_tmp}" "${COUNTS_JSON}"
}

build_geodata_if_possible() {
	if command -v git >/dev/null 2>&1 && command -v tar >/dev/null 2>&1 && [ -x "${REPO_ROOT}/scripts/ensure_local_go.sh" ]; then
		"${REPO_ROOT}/scripts/build_geodata_fancyss.sh" >/dev/null 2>&1 || return 1
	fi
	return 0
}

normalize_site_tokens() {
	awk '
	function emit(prefix, value, key) {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		if (value == "") return
		key = prefix ":" value
		if (!seen[key]++) print key
	}
	{
		line = $0
		gsub(/\r/, "", line)
		sub(/#.*/, "", line)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
		if (line == "") next
		line = tolower(line)
		if (line ~ /^full:/) {
			emit("full", substr(line, 6))
		} else if (line ~ /^domain:/) {
			emit("domain", substr(line, 8))
		} else if (line ~ /^keyword:/) {
			value = substr(line, 9)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
			if (value ~ /^[a-z0-9._-]+$/) emit("keyword", value)
		} else if (line ~ /^regexp:/ || line ~ /^regex:/) {
			next
		} else if (line ~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) {
			emit("domain", line)
		}
	}'
}

normalize_site_domain_list_custom() {
	awk -F ',' '
	function emit(prefix, value, key) {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		if (value == "") return
		key = prefix ":" value
		if (!seen[key]++) print key
	}
	BEGIN { IGNORECASE = 1 }
	/^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
	{
		type = tolower($1)
		value = tolower($2)
		gsub(/\r/, "", value)
		if (type == "domain") {
			emit("full", value)
		} else if (type == "domain-suffix") {
			emit("domain", value)
		} else if (type == "domain-keyword") {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
			if (value ~ /^[a-z0-9._-]+$/ && !seen["keyword:" value]++) print "keyword:" value
		} else if (type == "full") {
			emit("full", value)
		} else if (type == "keyword") {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
			if (value ~ /^[a-z0-9._-]+$/ && !seen["keyword:" value]++) print "keyword:" value
		}
	}'
}

normalize_site_666os() {
	awk '
	function emit(prefix, value, key) {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		if (value == "") return
		key = prefix ":" value
		if (!seen[key]++) print key
	}
	{
		line = $0
		gsub(/\r/, "", line)
		sub(/#.*/, "", line)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
		if (line == "") next
		line = tolower(line)
		if (line ~ /^regexp:/ || line ~ /^regex:/) next
		if (line ~ /^\+\./) {
			emit("domain", substr(line, 3))
		} else if (line ~ /^\./) {
			emit("domain", substr(line, 2))
		} else if (line ~ /^full:/) {
			emit("full", substr(line, 6))
		} else if (line ~ /^domain:/) {
			emit("domain", substr(line, 8))
		} else if (line ~ /^keyword:/) {
			value = substr(line, 9)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
			if (value ~ /^[a-z0-9._-]+$/ && !seen["keyword:" value]++) print "keyword:" value
		} else if (line ~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) {
			emit("full", line)
		}
	}'
}

normalize_site_plain_suffix() {
	awk '
	function emit(value, key) {
		gsub(/\r/, "", value)
		sub(/#.*/, "", value)
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
		gsub(/^[*.]+/, "", value)
		value = tolower(value)
		if (value == "") return
		if (value !~ /^[a-z0-9._-]+(\.[a-z0-9._-]+)+$/) return
		key = "domain:" value
		if (!seen[key]++) print key
	}
	{ emit($0) }'
}

normalize_ip_plain() {
	awk '
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
		if (valid_cidr(line) && !seen[line]++) print line
	}'
}

emit_source() {
	family="$1"
	source_json="$2"
	type=$(printf '%s' "$source_json" | jq -r '.type')
	case "$family:$type" in
	site:remote_domain_list_custom)
		url=$(printf '%s' "$source_json" | jq -r '.url')
		fetch_url "$url" | normalize_site_domain_list_custom
		;;
	site:remote_666os_site)
		url=$(printf '%s' "$source_json" | jq -r '.url')
		fetch_url "$url" | normalize_site_666os
		;;
	site:local_gzip_domain_suffix)
		path=$(printf '%s' "$source_json" | jq -r '.path')
		gzip -dc "${REPO_ROOT}/${path}" | normalize_site_plain_suffix
		;;
	site:local_plain_domain_suffix)
		path=$(printf '%s' "$source_json" | jq -r '.path')
		cat "${REPO_ROOT}/${path}" | normalize_site_plain_suffix
		;;
	ip:remote_666os_ip)
		url=$(printf '%s' "$source_json" | jq -r '.url')
		fetch_url "$url" | normalize_ip_plain
		;;
	ip:local_plain_cidr)
		path=$(printf '%s' "$source_json" | jq -r '.path')
		cat "${REPO_ROOT}/${path}" | normalize_ip_plain
		;;
	*)
		echo "unsupported source type: ${family}:${type}" >&2
		return 1
		;;
	esac
}

build_asset_family() {
	family="$1"
	asset_dir="${RULES_ROOT}/${family}"
	jq -c ".${family}[]" "${ASSETS_JSON}" | while IFS= read -r asset
	do
		[ -n "$asset" ] || continue
		id=$(printf '%s' "$asset" | jq -r '.id')
		mode=$(printf '%s' "$asset" | jq -r '.mode')
		out_file="${asset_dir}/${id}.txt"
		tmp_file="${TMP_DIR}/${family}.${id}.txt"
		: > "$tmp_file"
		if [ "$mode" = "manual" ]; then
			[ -f "$out_file" ] || {
				echo "manual asset missing: ${out_file}" >&2
				exit 1
			}
			cat "$out_file" > "$tmp_file"
		elif [ "$DO_FETCH" = "1" ]; then
			printf '%s' "$asset" | jq -c '.sources[]' | while IFS= read -r source
			do
				emit_source "$family" "$source"
			done > "$tmp_file"
		else
			[ -f "$out_file" ] || {
				echo "asset missing for --no-fetch: ${out_file}" >&2
				exit 1
			}
			cat "$out_file" > "$tmp_file"
		fi
		if [ "$family" = "site" ]; then
			normalize_site_tokens < "$tmp_file" | sort -u > "${tmp_file}.norm"
		else
			normalize_ip_plain < "$tmp_file" | sort -u > "${tmp_file}.norm"
		fi
		mv -f "${tmp_file}.norm" "$out_file"
	done
}

build_manifest() {
	manifest_tmp="${TMP_DIR}/shunt_manifest.json.js"
	counts_json="${COUNTS_JSON}"
	printf 'var SHUNT_PRESET_MANIFEST = [' > "$manifest_tmp"
	first=1
	jq -c 'sort_by(.order, .id)[]' "${PRESETS_JSON}" | while IFS= read -r preset
	do
		id=$(printf '%s' "$preset" | jq -r '.id')
		label_text=$(printf '%s' "$preset" | jq -r '.label')
		desc_text=$(printf '%s' "$preset" | jq -r '.description')
		direct=$(printf '%s' "$preset" | jq -r '.direct // false')
		policy=$(printf '%s' "$preset" | jq -r '.policy // "neutral"')
		count=$(jq -r --arg id "${id}" '.preset[$id].total // 0' "${counts_json}" 2>/dev/null || echo 0)
		site_count=$(jq -r --arg id "${id}" '.preset[$id].site_count // 0' "${counts_json}" 2>/dev/null || echo 0)
		ip_count=$(jq -r --arg id "${id}" '.preset[$id].ip_count // 0' "${counts_json}" 2>/dev/null || echo 0)
		file_path=""
		first_site=$(printf '%s' "$preset" | jq -r '.site[0] // empty')
		first_ip=$(printf '%s' "$preset" | jq -r '.ip[0] // empty')
		if [ -n "${first_site}" ]; then
			file_path="rules_ng2/site/${first_site}.txt"
		elif [ -n "${first_ip}" ]; then
			file_path="rules_ng2/ip/${first_ip}.txt"
		fi
		entry=$(jq -nc \
			--arg id "$id" \
			--arg lbl "$label_text" \
			--arg desc "$desc_text" \
			--arg file "${file_path}" \
			--argjson count "$count" \
			--argjson site_count "$site_count" \
			--argjson ip_count "$ip_count" \
			--argjson direct "$direct" \
			--arg policy "$policy" \
			--argjson site_assets "$(printf '%s' "$preset" | jq -c '.site // []')" \
			--argjson ip_assets "$(printf '%s' "$preset" | jq -c '.ip // []')" \
			'{"id":$id,"label":$lbl,"description":$desc,"file":$file,"count":$count,"site_count":$site_count,"ip_count":$ip_count,"direct":$direct,"policy":$policy,"site_assets":$site_assets,"ip_assets":$ip_assets}')
		if [ "$first" = "1" ]; then
			first=0
		else
			printf ',' >> "$manifest_tmp"
		fi
		printf '%s' "$entry" >> "$manifest_tmp"
	done
	printf '];
' >> "$manifest_tmp"
	mv -f "$manifest_tmp" "$MANIFEST_FILE"
}

sync_package_tree() {
	rm -rf "${PKG_RULES_ROOT}"
	mkdir -p "${PKG_RULES_ROOT}"
	cp -a "${RULES_ROOT}/." "${PKG_RULES_ROOT}/"
}

build_asset_family site
build_asset_family ip
build_geodata_if_possible || true
build_count_summary
build_manifest
sync_package_tree

echo "updated geodata assets under rules_ng2/{site,ip,meta}"
echo "generated rule count summary: rules_ng2/meta/rule_counts.json ($(jq -r '.source' "${COUNTS_JSON}" 2>/dev/null || echo unknown))"
