#!/bin/sh

SELF_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
if [ -f "${SELF_DIR}/ss_node_common.sh" ]; then
	source "${SELF_DIR}/ss_node_common.sh"
elif [ -f "${KSROOT}/scripts/ss_node_common.sh" ]; then
	source "${KSROOT}/scripts/ss_node_common.sh"
fi

reconcile_usage() {
	cat <<-'EOF'
	Usage:
	  ss_node_identity_reconcile.sh <old_jsonl> <new_jsonl>

	Output TSV:
	  old_id<TAB>new_id<TAB>reason

	Reasons:
	  identity
	  primary
	  airport_name
	  airport_secondary
	  secondary
	  deleted
	  new
	EOF
}

reconcile_emit_enriched() {
	local input_file="$1"
	local output_file="$2"
	local stripped_file="${output_file}.stripped"
	[ -f "${input_file}" ] || return 1
	jq -c '
		del(
			._airport_identity,
			._source_scope,
			._source_url_hash,
			._identity_primary,
			._identity_secondary,
			._identity,
			._identity_ver
		)
	' "${input_file}" > "${stripped_file}" 2>/dev/null || return 1
	fss_enrich_node_identity_file "${stripped_file}" "${output_file}" "" "" "" "" || {
		rm -f "${stripped_file}"
		return 1
	}
	rm -f "${stripped_file}"
}

reconcile_build_old_map() {
	local old_file="$1"
	local map_file="$2"
	jq -r '[
		._id // "",
		._identity // "",
		._identity_primary // "",
		._identity_secondary // "",
		._airport_identity // "",
		.name // "",
		((._airport_identity // "") + "\u001f" + (.name // "")),
		((._airport_identity // "") + "\u001f" + (._identity_secondary // ""))
	] | @tsv' "${old_file}" 2>/dev/null > "${map_file}"
}

reconcile_build_new_map() {
	local new_file="$1"
	local map_file="$2"
	jq -r '[
		._id // "",
		._identity // "",
		._identity_primary // "",
		._identity_secondary // "",
		._airport_identity // "",
		.name // "",
		((._airport_identity // "") + "\u001f" + (.name // "")),
		((._airport_identity // "") + "\u001f" + (._identity_secondary // ""))
	] | @tsv' "${new_file}" 2>/dev/null | awk -F '\t' 'BEGIN{OFS="\t"} { if ($1 == "") $1 = NR; print }' > "${map_file}"
}

reconcile_assign_unique_matches() {
	local field_name="$1"
	local old_map="$2"
	local new_map="$3"
	local old_used="$4"
	local new_used="$5"
	local out_file="$6"
	local old_id=""
	local old_identity=""
	local old_primary=""
	local old_secondary=""
	local old_airport=""
	local old_name=""
	local old_airport_name=""
	local old_airport_secondary=""
	local old_value=""
	local new_value=""
	local new_count=0
	local match_count=0
	local chosen_new_id=""
	local new_id=""
	local new_identity=""
	local new_primary=""
	local new_secondary=""
	local new_airport=""
	local new_name=""
	local new_airport_name=""
	local new_airport_secondary=""

	while IFS='	' read -r old_id old_identity old_primary old_secondary old_airport old_name old_airport_name old_airport_secondary
	do
		[ -n "${old_id}" ] || continue
		grep -Fxq "${old_id}" "${old_used}" 2>/dev/null && continue
		case "${field_name}" in
		identity)
			old_value="${old_identity}"
			;;
		primary)
			old_value="${old_primary}"
			;;
		airport_name)
			old_value="${old_airport_name}"
			;;
		airport_secondary)
			old_value="${old_airport_secondary}"
			;;
		secondary)
			old_value="${old_secondary}"
			;;
		*)
			continue
			;;
		esac
		[ -n "${old_value}" ] || continue
		new_count=$(awk -F '\t' -v field="${field_name}" -v value="${old_value}" '
			{
				if (field == "identity" && $2 == value) c++
				else if (field == "primary" && $3 == value) c++
				else if (field == "secondary" && $4 == value) c++
				else if (field == "airport_name" && $7 == value) c++
				else if (field == "airport_secondary" && $8 == value) c++
			}
			END {print c + 0}
		' "${new_map}" 2>/dev/null)
		[ "${new_count}" = "1" ] || continue
		match_count=0
		chosen_new_id=""
		while IFS='	' read -r new_id new_identity new_primary new_secondary new_airport new_name new_airport_name new_airport_secondary
		do
			[ -n "${new_id}" ] || continue
			grep -Fxq "${new_id}" "${new_used}" 2>/dev/null && continue
			case "${field_name}" in
			identity)
				new_value="${new_identity}"
				;;
			primary)
				new_value="${new_primary}"
				;;
			airport_name)
				new_value="${new_airport_name}"
				;;
			airport_secondary)
				new_value="${new_airport_secondary}"
				;;
			secondary)
				new_value="${new_secondary}"
				;;
			esac
			[ "${new_value}" = "${old_value}" ] || continue
			match_count=$((match_count + 1))
			chosen_new_id="${new_id}"
		done < "${new_map}"
		[ "${match_count}" = "1" ] || continue
		echo "${old_id}" >> "${old_used}"
		echo "${chosen_new_id}" >> "${new_used}"
		printf '%s\t%s\t%s\n' "${old_id}" "${chosen_new_id}" "${field_name}" >> "${out_file}"
	done < "${old_map}"
}

reconcile_emit_deleted_and_new() {
	local old_map="$1"
	local new_map="$2"
	local old_used="$3"
	local new_used="$4"
	local out_file="$5"
	local node_id=""

	while IFS='	' read -r node_id _rest
	do
		[ -n "${node_id}" ] || continue
		grep -Fxq "${node_id}" "${old_used}" 2>/dev/null && continue
		printf '%s\t\tdeleted\n' "${node_id}" >> "${out_file}"
	done < "${old_map}"

	while IFS='	' read -r node_id _rest
	do
		[ -n "${node_id}" ] || continue
		grep -Fxq "${node_id}" "${new_used}" 2>/dev/null && continue
		printf '\t%s\tnew\n' "${node_id}" >> "${out_file}"
	done < "${new_map}"
}

reconcile_main() {
	local old_input="$1"
	local new_input="$2"
	local tmp_dir=""
	local old_enriched=""
	local new_enriched=""
	local old_map=""
	local new_map=""
	local old_used=""
	local new_used=""
	local out_file=""

	[ -f "${old_input}" ] || return 1
	[ -f "${new_input}" ] || return 1

	tmp_dir=$(fss_mktemp_dir reconcile) || return 1
	old_enriched="${tmp_dir}/old.jsonl"
	new_enriched="${tmp_dir}/new.jsonl"
	old_map="${tmp_dir}/old.tsv"
	new_map="${tmp_dir}/new.tsv"
	old_used="${tmp_dir}/old.used"
	new_used="${tmp_dir}/new.used"
	out_file="${tmp_dir}/result.tsv"

	reconcile_emit_enriched "${old_input}" "${old_enriched}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	reconcile_emit_enriched "${new_input}" "${new_enriched}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	reconcile_build_old_map "${old_enriched}" "${old_map}" || {
		rm -rf "${tmp_dir}"
		return 1
	}
	reconcile_build_new_map "${new_enriched}" "${new_map}" || {
		rm -rf "${tmp_dir}"
		return 1
	}

	: > "${old_used}"
	: > "${new_used}"
	: > "${out_file}"

	reconcile_assign_unique_matches "identity" "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"
	reconcile_assign_unique_matches "primary" "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"
	reconcile_assign_unique_matches "airport_name" "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"
	reconcile_assign_unique_matches "airport_secondary" "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"
	reconcile_assign_unique_matches "secondary" "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"
	reconcile_emit_deleted_and_new "${old_map}" "${new_map}" "${old_used}" "${new_used}" "${out_file}"

	cat "${out_file}"
	rm -rf "${tmp_dir}"
}

if [ "$#" -ne 2 ]; then
	reconcile_usage >&2
	exit 1
fi

reconcile_main "$1" "$2"
