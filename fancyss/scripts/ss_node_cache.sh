#!/bin/sh

[ -z "${KSROOT}" ] && export KSROOT=/koolshare
[ -f "${KSROOT}/scripts/base.sh" ] && source ${KSROOT}/scripts/base.sh
[ -f "${KSROOT}/scripts/ss_node_common.sh" ] && source ${KSROOT}/scripts/ss_node_common.sh

ACTION="$1"
WEB_ACTION=0
if [ -z "$2" -a -n "$1" ]; then
	ACTION="$1"
	WEB_ACTION=0
elif [ -n "$2" -a -n "$1" ]; then
	ACTION="$2"
	WEB_ACTION=1
fi

case "${ACTION}" in
drop_node_cache)
	NODE_ID="$2"
	[ "${WEB_ACTION}" = "1" ] && NODE_ID="$3"
	fss_clear_node_cache_node "${NODE_ID}" >/dev/null 2>&1 || true
	[ "${WEB_ACTION}" = "1" ] && http_response "$1" >/dev/null 2>&1
	;;
*)
	[ "${WEB_ACTION}" = "1" ] && http_response "$1" >/dev/null 2>&1
	;;
esac
