#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
"${SCRIPT_DIR}/build_geosite_fancyss.sh"
"${SCRIPT_DIR}/build_geoip_fancyss.sh"
