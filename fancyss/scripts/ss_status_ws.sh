#!/bin/sh

STATUS_FILE_F="/tmp/upload/ssf_status.txt"
STATUS_FILE_C="/tmp/upload/ssc_status.txt"
STATUS_STREAM_F="/tmp/upload/ssf_status.stream"
STATUS_STREAM_C="/tmp/upload/ssc_status.stream"

emit_status_snapshot() {
	local status_file="$1"
	[ -f "${status_file}" ] || : > "${status_file}"
	awk '
		BEGIN {
			print "__FSS_SNAPSHOT_BEGIN__"
			chunk = ""
			count = 0
		}
		{
			gsub(/\r/, "")
			chunk = chunk $0 "__FSS_NL__"
			count++
			if (count >= 64) {
				print "__FSS_SNAPSHOT_CHUNK__" chunk
				chunk = ""
				count = 0
			}
		}
		END {
			if (count > 0) {
				print "__FSS_SNAPSHOT_CHUNK__" chunk
			}
			print "__FSS_SNAPSHOT_END__"
		}
	' "${status_file}" 2>/dev/null
}

follow_status_stream() {
	local status_file="$1"
	local status_stream="$2"
	local status_lines=0

	[ -f "${status_file}" ] || : > "${status_file}"
	[ -f "${status_stream}" ] || : > "${status_stream}"
	emit_status_snapshot "${status_file}"
	status_lines="$(wc -l < "${status_stream}" 2>/dev/null)"
	[ -n "${status_lines}" ] || status_lines=0
	tail -n +"$((status_lines + 1))" -f "${status_stream}" 2>/dev/null | while IFS= read -r line
	do
		echo "${line}"
	done
	exit 0
}

case "$1" in
follow_ssf_status)
	follow_status_stream "${STATUS_FILE_F}" "${STATUS_STREAM_F}"
	;;
follow_ssc_status)
	follow_status_stream "${STATUS_FILE_C}" "${STATUS_STREAM_C}"
	;;
get_ssf_log)
	awk 'BEGIN{ORS="@@"}{print}' "${STATUS_FILE_F}" 2>/dev/null
	;;
get_ssc_log)
	awk 'BEGIN{ORS="@@"}{print}' "${STATUS_FILE_C}" 2>/dev/null
	;;
*)
	exit 1
	;;
esac
