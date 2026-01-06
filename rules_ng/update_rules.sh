#!/usr/bin/env bash
set -euo pipefail

CURR_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_FILE="${CURR_PATH}/rules.json.js"

now_ts() { TZ=CST-8 date +'%Y-%m-%d %H:%M'; }

file_mtime_ts() {
	local f="$1"
	local epoch
	epoch="$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f")"
	TZ=CST-8 date -d "@${epoch}" +'%Y-%m-%d %H:%M'
}

die() { echo "error: $*" >&2; exit 1; }

require_cmd() {
	local c
	for c in "$@"; do
		command -v "$c" >/dev/null 2>&1 || die "$c is required"
	done
}

curl_common_args() {
	# keep progress in terminal (stderr), keep body on stdout/file
	# shellcheck disable=SC2034
	CURL_ARGS=(-4 -fSL --connect-timeout 10 --max-time 300 --retry 3 --retry-delay 1 --retry-connrefused)
	if [ "${NO_PROGRESS:-0}" = "1" ]; then
		CURL_ARGS+=(-sS)
	else
		CURL_ARGS+=(--progress-bar)
	fi
}

curl_download() {
	local url="$1"
	local out="$2"
	local label="${3:-}"
	# shellcheck disable=SC2154
	if [ -n "$label" ]; then
		printf '==> %s\n' "$label" >&2
	fi
	curl "${CURL_ARGS[@]}" -o "$out" "$url"
}

curl_stdout() {
	local url="$1"
	local label="${2:-}"
	# shellcheck disable=SC2154
	if [ -n "$label" ]; then
		printf '==> %s\n' "$label" >&2
	fi
	curl "${CURL_ARGS[@]}" "$url"
}

md5_file() { md5sum "$1" | awk '{print $1}'; }
line_count() { awk 'END{print NR}' "$1"; }

gzip_deterministic() {
	local src="$1"
	local dest="$2"
	# -n: omit original name+timestamp for deterministic output
	gzip -n -9 -c "$src" >"$dest"
}

json_get() {
	local jq_expr="$1"
	jq -r "${jq_expr} // empty" "$RULE_FILE"
}

json_set_rule() {
	# Updates: .KEY.name/date/md5/count (+ optional count_ip)
	local key="$1"
	local name="$2"
	local date="$3"
	local md5="$4"
	local count="$5"
	local count_ip="${6:-}"

	if [ -n "$count_ip" ]; then
		jq --arg name "$name" --arg date "$date" --arg md5 "$md5" --arg count "$count" --arg count_ip "$count_ip" \
			".$key |= (.name=\$name | .date=\$date | .md5=\$md5 | .count=\$count | .count_ip=\$count_ip)" \
			"$RULE_FILE" | sponge "$RULE_FILE"
	else
		jq --arg name "$name" --arg date "$date" --arg md5 "$md5" --arg count "$count" \
			".$key |= (.name=\$name | .date=\$date | .md5=\$md5 | .count=\$count)" \
			"$RULE_FILE" | sponge "$RULE_FILE"
	fi
}

update_local_txt_rule() {
	# For local-maintained lists: only bump json when file content changed.
	local key="$1"
	local filename="$2"

	local path="${CURR_PATH}/${filename}"
	[ -f "$path" ] || : >"$path"

	local md5_new
	md5_new="$(md5_file "$path")"
	local md5_old
	md5_old="$(json_get ".$key.md5")"
	local count_new
	count_new="$(line_count "$path")"
	local count_old
	count_old="$(json_get ".$key.count")"
	local date_old
	date_old="$(json_get ".$key.date")"

	if [ -n "$md5_old" ] && [ "$md5_old" = "$md5_new" ]; then
		# keep date stable when content unchanged; but fix missing/wrong count/md5/name
		if [ "$count_old" != "$count_new" ] || [ -z "$date_old" ]; then
			local date_fix="$date_old"
			[ -n "$date_fix" ] || date_fix="$(file_mtime_ts "$path")"
			json_set_rule "$key" "$filename" "$date_fix" "$md5_new" "$count_new"
		fi
		return 0
	fi

	local date
	date="$(file_mtime_ts "$path")"
	json_set_rule "$key" "$filename" "$date" "$md5_new" "$count_new"
}

update_generated_txt_rule() {
	local key="$1"
	local filename="$2"
	local tmp_txt="$3"
	local extra_count_ip="${4:-}"

	local out="${CURR_PATH}/${filename}"
	local md5_new
	md5_new="$(md5_file "$tmp_txt")"

	local md5_old_file
	md5_old_file="$(md5sum "$out" 2>/dev/null | awk '{print $1}' || true)"
	if [ -n "$md5_old_file" ] && [ "$md5_old_file" = "$md5_new" ]; then
		# content unchanged: don't bump date, but ensure json has correct md5/count
		rm -f "$tmp_txt" || true
		chmod 0644 "$out" 2>/dev/null || true
		local date_old
		date_old="$(json_get ".$key.date")"
		local md5_old_json
		md5_old_json="$(json_get ".$key.md5")"
		local count_old
		count_old="$(json_get ".$key.count")"
		local count_new
		count_new="$(line_count "$out")"
		if [ -z "$date_old" ] || [ "$md5_old_json" != "$md5_new" ] || [ "$count_old" != "$count_new" ]; then
			local date_fix="$date_old"
			[ -n "$date_fix" ] || date_fix="$(file_mtime_ts "$out")"
			json_set_rule "$key" "$filename" "$date_fix" "$md5_new" "$count_new" "$extra_count_ip"
		fi
		return 0
	fi

	mv -f "$tmp_txt" "$out"
	chmod 0644 "$out" 2>/dev/null || true

	local date
	date="$(now_ts)"
	local count
	count="$(line_count "$out")"
	json_set_rule "$key" "$filename" "$date" "$md5_new" "$count" "$extra_count_ip"
}

update_generated_gz_rule() {
	# md5 stored for gz file; count stored for original text lines
	local key="$1"
	local gz_filename="$2"
	local tmp_txt="$3"

	local tmp_gz
	tmp_gz="$(mktemp)"
	gzip_deterministic "$tmp_txt" "$tmp_gz"

	local md5_new
	md5_new="$(md5_file "$tmp_gz")"
	local md5_old
	md5_old="$(json_get ".$key.md5")"

	if [ -n "$md5_old" ] && [ "$md5_old" = "$md5_new" ] && [ -f "${CURR_PATH}/${gz_filename}" ]; then
		rm -f "$tmp_gz"
		chmod 0644 "${CURR_PATH}/${gz_filename}" 2>/dev/null || true
		return 0
	fi

	mv -f "$tmp_gz" "${CURR_PATH}/${gz_filename}"
	chmod 0644 "${CURR_PATH}/${gz_filename}" 2>/dev/null || true
	local date
	date="$(now_ts)"
	local count
	count="$(line_count "$tmp_txt")"
	json_set_rule "$key" "$gz_filename" "$date" "$md5_new" "$count"
}

update_gfwlist() {
	local tmpdir="$1"
	local raw1="${tmpdir}/gfwlist_b64.txt"
	local list1="${tmpdir}/gfwlist_1.txt"
	local list2="${tmpdir}/gfwlist_2.txt"
	local merged="${tmpdir}/gfwlist_merged.txt"

	curl_download "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt" "$raw1" "download gfwlist (Loukky)"
	python3 - "$raw1" >"$list1" <<'PY'
import base64, re, sys

raw = open(sys.argv[1], "rb").read()
try:
    decoded = base64.b64decode(raw)
    text = decoded.decode("utf-8", "ignore")
    if not text.lstrip().startswith("[AutoProxy"):
        text = raw.decode("utf-8", "ignore")
except Exception:
    text = raw.decode("utf-8", "ignore")

comment_re = re.compile(r"^\!|\[|^@@|^\d+\.\d+\.\d+\.\d+")
domain_re = re.compile(r"([\w\-\_]+\.[\w\.\-\_]+)[\/\*]*")
seen = set()
for line in text.splitlines():
    if comment_re.search(line):
        continue
    m = domain_re.search(line)
    if not m:
        continue
    seen.add(m.group(1))
for d in sorted(seen):
    sys.stdout.write(d + "\n")
PY

	curl_download "https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt" "$list2" "download gfwlist extra (pexcn)"

	cat "$list1" "$list2" \
		| grep -Ev "([0-9]{1,3}[\\.]){3}[0-9]{1,3}" \
		| sed '/^$/d' \
		| sort -u >"$merged"

	# asus asd detect these domains
	sed -i '/hasi\./d' "$merged"
	sed -i '/v2ex/d' "$merged"
	sed -i '/apple\.com/d' "$merged"
	sed -i '/m-team/d' "$merged"
	sed -i '/windowsupdate/d' "$merged"

	update_generated_gz_rule "gfwlist" "gfwlist.gz" "$merged"
	rm -f "${CURR_PATH}/gfwlist.txt" || true
}

update_chnlist_and_related() {
	local tmpdir="$1"
	local chn_conf="${tmpdir}/chnlist.conf"
	local apple_conf="${tmpdir}/apple.china.conf"
	local google_conf="${tmpdir}/google.china.conf"
	local chn_txt="${tmpdir}/chnlist.txt"
	local apple_txt="${tmpdir}/apple_china.txt"
	local google_txt="${tmpdir}/google_china.txt"

	curl_download "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf" "$chn_conf" "download chnlist (accelerated-domains)"
	curl_download "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf" "$apple_conf" "download apple china domains"
	curl_download "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf" "$google_conf" "download google china domains"

	cat "$chn_conf" "$apple_conf" "$google_conf" \
		| sed '/^#/d' \
		| sed 's/server=\/\.//g' \
		| sed 's/server=\///g' \
		| sed -r 's/\/\S{1,30}//g' \
		| sed '/^$/d' \
		| sort -u >"$chn_txt"
	update_generated_gz_rule "chnlist" "chnlist.gz" "$chn_txt"
	rm -f "${CURR_PATH}/chnlist.txt" || true

	cat "$apple_conf" \
		| sed '/^#/d' \
		| sed 's/server=\/\.//g' \
		| sed 's/server=\///g' \
		| sed -r 's/\/\S{1,30}//g' \
		| sed '/^$/d' \
		| sort -u >"$apple_txt"
	update_generated_txt_rule "apple_china" "apple_china.txt" "$apple_txt"

	cat "$google_conf" \
		| sed '/^#/d' \
		| sed 's/server=\/\.//g' \
		| sed 's/server=\///g' \
		| sed -r 's/\/\S{1,30}//g' \
		| sed '/^$/d' \
		| sort -u >"$google_txt"
	update_generated_txt_rule "google_china" "google_china.txt" "$google_txt"
}

update_cdn_test() {
	local tmpdir="$1"
	local tmp="${tmpdir}/cdn_test.txt"
	curl_download "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/cdn-testlist.txt" "$tmp" "download cdn test list"
	update_generated_txt_rule "cdn_test" "cdn_test.txt" "$tmp"
}

count_ipv4_total() {
	awk -F "/" '{if ($2 == "") $2 = 32;sum += 2^(32-$2)};END {printf "%.0f\n", sum}'
}

update_chnroute() {
	local tmpdir="$1"
	local misakaio="${tmpdir}/misakaio.txt"
	local apnic="${tmpdir}/apnic.txt"
	local mon17="${tmpdir}/17mon.txt"
	local ipip="${tmpdir}/ipip.txt"
	local maxmind="${tmpdir}/maxmind.txt"
	local merged="${tmpdir}/chnroute.txt"

	curl_download "https://raw.githubusercontent.com/misakaio/chnroutes2/master/chnroutes.txt" "$misakaio" "download chnroute source (misakaio)"
	sed -i '/^#/d' "$misakaio"

	curl_stdout "https://ftp.apnic.net/stats/apnic/delegated-apnic-latest" "download chnroute source (apnic delegated)" \
		| awk -F'|' '$2=="CN" && $3=="ipv4" { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >"$apnic"

	curl_download "https://raw.githubusercontent.com/17mon/china_ip_list/refs/heads/master/china_ip_list.txt" "$mon17" "download chnroute source (17mon)"
	sed -i '/^#/d' "$mon17"

	curl_download "https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/ipip_country/ipip_country_cn.netset" "$ipip" "download chnroute source (firehol ipip)"
	curl_download "https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/geolite2_country/country_cn.netset" "$maxmind" "download chnroute source (firehol maxmind)"

	# keep only valid ipv4 routes (CIDR or single IP), avoid accidental matches from non-data content
	sed -i '/^#/d;/^$/d' "$ipip" "$maxmind"
	cat "$misakaio" "$apnic" "$mon17" "$ipip" "$maxmind" \
		| grep -E '^([0-9]{1,3}[\\.]){3}[0-9]{1,3}(/[0-9]{1,2})?$' \
		| iprange >"$merged"

	local ip_count
	ip_count="$(cat "$merged" | count_ipv4_total)"
	update_generated_txt_rule "chnroute" "chnroute.txt" "$merged" "$ip_count"
}

update_chnroute6() {
	local tmpdir="$1"
	local tmp="${tmpdir}/chnroute6.txt"
	curl_stdout "https://ftp.apnic.net/stats/apnic/delegated-apnic-latest" "download chnroute6 source (apnic delegated)" \
		| awk -F'|' '$2=="CN" && $3=="ipv6" { printf("%s/%s\n", $4, $5) }' \
		| sed '/^$/d' \
		| sort -u >"$tmp"
	update_generated_txt_rule "chnroute6" "chnroute6.txt" "$tmp"
}

update_adslist() {
	local tmpdir="$1"
	local tmp_txt="${tmpdir}/adslist.txt"
	local raw="${tmpdir}/ads_domains.txt"

	curl_download "https://anti-ad.net/domains.txt" "$raw" "download adslist (anti-ad)"
	cat "$raw" \
		| sed '/^#/d' \
		| sed '/^$/d' \
		| tr 'A-Z' 'a-z' \
		| sort -u >"$tmp_txt"

	update_generated_gz_rule "adslist" "adslist.gz" "$tmp_txt"
}

update_all() {
	require_cmd curl jq sponge gzip md5sum awk sed sort iprange python3 stat
	curl_common_args
	[ -f "$RULE_FILE" ] || echo '{}' >"$RULE_FILE"
	jq -e . "$RULE_FILE" >/dev/null 2>&1 || die "invalid json: $RULE_FILE"

	RULES_TMPDIR="$(mktemp -d)"
	trap 'rm -rf "${RULES_TMPDIR:-}"' EXIT

	update_gfwlist "$RULES_TMPDIR"
	update_chnlist_and_related "$RULES_TMPDIR"
	update_adslist "$RULES_TMPDIR"
	update_chnroute "$RULES_TMPDIR"
	update_chnroute6 "$RULES_TMPDIR"
	update_cdn_test "$RULES_TMPDIR"

	# local-maintained lists
	update_local_txt_rule "udplist" "udplist.txt"
	update_local_txt_rule "rotlist" "rotlist.txt"
	update_local_txt_rule "white_list" "white_list.txt"
	update_local_txt_rule "black_list" "black_list.txt"
	update_local_txt_rule "block_list" "block_list.txt"
}

clean_generated() {
	rm -f \
		"${CURR_PATH}/gfwlist.gz" \
		"${CURR_PATH}/chnlist.gz" \
		"${CURR_PATH}/adslist.gz" \
		"${CURR_PATH}/chnroute.txt" \
		"${CURR_PATH}/chnroute6.txt" \
		"${CURR_PATH}/apple_china.txt" \
		"${CURR_PATH}/google_china.txt" \
		"${CURR_PATH}/cdn_test.txt"
}

case "${1:-update}" in
	update)
		update_all
		;;
	clean)
		clean_generated
		;;
	*)
		die "usage: $0 [update|clean] (set NO_PROGRESS=1 to hide curl progress)"
		;;
esac
