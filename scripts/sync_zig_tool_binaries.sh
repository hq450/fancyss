#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD=0
BUILD_UPX_ARG=()
REQUESTED_TOOLS=()

print_usage() {
	cat <<'EOF'
Usage:
  scripts/sync_zig_tool_binaries.sh [options] [tool...]

Tools:
  geotool node-tool sub-tool anytls-zig xapi-tool ws-tool status-tool webtest-tool

Options:
  --build       Build tools before syncing into binaries/
  --no-build    Only sync existing tool/*/dist artifacts into binaries/ (default)
  --no-upx      Pass --no-upx to each tool build-release script
  --upx         Pass --upx to each tool build-release script
  -h, --help    Show this help

Environment:
  ZIG, UPX_4_2_4, UPX_5_0_2, UPX, OUT_DIR and cache variables are forwarded
  to each tool's own scripts/build-release.sh.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--build)
			BUILD=1
			shift
			;;
		--no-build)
			BUILD=0
			shift
			;;
		--no-upx)
			BUILD_UPX_ARG=(--no-upx)
			shift
			;;
		--upx)
			BUILD_UPX_ARG=(--upx)
			shift
			;;
		-h|--help)
			print_usage
			exit 0
			;;
		*)
			REQUESTED_TOOLS+=("$1")
			shift
			;;
	esac
done

all_tools() {
	printf '%s\n' \
		geotool \
		node-tool \
		sub-tool \
		anytls-zig \
		xapi-tool \
		ws-tool \
		status-tool \
		webtest-tool
}

tool_selected() {
	local tool="$1"
	local requested=""

	if [[ ${#REQUESTED_TOOLS[@]} -eq 0 ]]; then
		return 0
	fi
	for requested in "${REQUESTED_TOOLS[@]}"; do
		[[ "$requested" == "$tool" ]] && return 0
	done
	return 1
}

tool_configured() {
	local tool="$1"
	local configured=""

	for configured in $(all_tools); do
		[[ "$configured" == "$tool" ]] && return 0
	done
	return 1
}

assert_all_zig_tools_configured() {
	local tool_dir=""
	local tool=""
	local missing=0

	while IFS= read -r tool_dir; do
		tool="$(basename "$tool_dir")"
		if ! tool_configured "$tool"; then
			echo "error: Zig tool has no sync config: tool/${tool}" >&2
			missing=1
		fi
	done < <(find "${ROOT_DIR}/tool" -mindepth 2 -maxdepth 2 -name build.zig -printf '%h\n' | sort)

	[[ "$missing" == "0" ]] || return 1
}

tool_config() {
	local tool="$1"

	case "$tool" in
		geotool)
			printf '%s|%s|%s|%s\n' "tool/geotool" "binaries/geotool" "geotool" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		node-tool)
			printf '%s|%s|%s|%s\n' "tool/node-tool" "binaries/node-tool" "node-tool" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		sub-tool)
			printf '%s|%s|%s|%s\n' "tool/sub-tool" "binaries/sub-tool" "sub-tool" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		anytls-zig)
			printf '%s|%s|%s|%s\n' "tool/anytls-zig" "binaries/anytls-zig" "anytls-zig" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		xapi-tool)
			printf '%s|%s|%s|%s\n' "tool/xapi-tool" "binaries/xapi-tool" "xapi-tool" "x86_64 aarch64 armv7a armv7hf"
			;;
		ws-tool)
			printf '%s|%s|%s|%s\n' "tool/ws-tool" "binaries/websocketd" "websocketd" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		status-tool)
			printf '%s|%s|%s|%s\n' "tool/status-tool" "binaries/status-tool" "status-tool statusctl" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		webtest-tool)
			printf '%s|%s|%s|%s\n' "tool/webtest-tool" "binaries/webtest-tool" "webtest-tool webtestctl" "x86_64 aarch64 armv5te armv7a armv7hf"
			;;
		*)
			echo "error: unsupported Zig tool '$tool'" >&2
			return 1
			;;
	esac
}

read_tool_version() {
	local tool_dir="$1"
	local version_file="${ROOT_DIR}/${tool_dir}/VERSION"

	[[ -f "$version_file" ]] || {
		echo "error: VERSION file not found: $version_file" >&2
		return 1
	}
	tr -d '\r\n' < "$version_file"
}

assert_artifacts() {
	local dist_dir="$1"
	local version="$2"
	local prefixes="$3"
	local targets="$4"
	local prefix=""
	local target=""
	local artifact=""

	for prefix in $prefixes; do
		for target in $targets; do
			artifact="${dist_dir}/${prefix}-v${version}-linux-${target}"
			[[ -s "$artifact" ]] || {
				echo "error: missing artifact: $artifact" >&2
				return 1
			}
		done
	done
}

copy_artifacts() {
	local dist_dir="$1"
	local binaries_dir="$2"
	local version="$3"
	local prefixes="$4"
	local checksum="SHA256SUMS-v${version}"
	local prefix=""
	local found=0
	local known_artifacts=()
	local existing_artifacts=()
	local artifact=""
	local filename=""
	local checksum_tmp=""
	local seen=0

	mkdir -p "$binaries_dir"
	for prefix in $prefixes; do
		while IFS= read -r artifact; do
			[[ -n "$artifact" ]] || continue
			cp -f "$artifact" "$binaries_dir/"
			chmod 0755 "${binaries_dir}/$(basename "$artifact")"
			found=1
		done < <(find "$dist_dir" -maxdepth 1 -type f -name "${prefix}-v${version}-linux-*" | sort)
	done
	[[ "$found" == "1" ]] || {
		echo "error: no artifacts found in $dist_dir for v${version}" >&2
		return 1
	}
	if [[ -f "$binaries_dir/$checksum" ]]; then
		while read -r _ filename; do
			[[ -n "${filename:-}" && -f "$binaries_dir/$filename" ]] && existing_artifacts+=("$filename")
		done < "$binaries_dir/$checksum"
	fi
	for prefix in $prefixes; do
		while IFS= read -r artifact; do
			known_artifacts+=("$artifact")
		done < <(find "$binaries_dir" -maxdepth 1 -type f -name "${prefix}-v${version}-linux-*" -printf '%f\n' | sort)
	done
	[[ ${#known_artifacts[@]} -gt 0 ]] || {
		echo "error: no binaries found in $binaries_dir for v${version}" >&2
		return 1
	}
	checksum_tmp="$(mktemp "$binaries_dir/.${checksum}.tmp.XXXXXX")"
	(
		cd "$binaries_dir"
		for artifact in "${existing_artifacts[@]}"; do
			sha256sum "$artifact"
		done
		for artifact in "${known_artifacts[@]}"; do
			seen=0
			for filename in "${existing_artifacts[@]}"; do
				if [[ "$artifact" == "$filename" ]]; then
					seen=1
					break
				fi
			done
			if [[ "$seen" == "0" ]]; then
				sha256sum "$artifact"
			fi
		done
	) > "$checksum_tmp"
	mv -f "$checksum_tmp" "$binaries_dir/$checksum"
}

verify_checksums() {
	local binaries_dir="$1"
	local version="$2"
	local checksum="SHA256SUMS-v${version}"

	(
		cd "$binaries_dir"
		sha256sum -c "$checksum"
	)
}

sync_tool() {
	local tool="$1"
	local config=""
	local tool_dir=""
	local binaries_dir=""
	local prefixes=""
	local targets=""
	local version=""
	local dist_dir=""

	config="$(tool_config "$tool")"
	IFS='|' read -r tool_dir binaries_dir prefixes targets <<< "$config"
	version="$(read_tool_version "$tool_dir")"
	dist_dir="${ROOT_DIR}/${tool_dir}/dist"

	echo ">>> sync Zig tool: ${tool} v${version}"
	if [[ "$BUILD" == "1" ]]; then
		(
			cd "${ROOT_DIR}/${tool_dir}"
			bash ./scripts/build-release.sh "${BUILD_UPX_ARG[@]}" $targets
		)
	fi

	assert_artifacts "$dist_dir" "$version" "$prefixes" "$targets"
	copy_artifacts "$dist_dir" "${ROOT_DIR}/${binaries_dir}" "$version" "$prefixes"
	verify_checksums "${ROOT_DIR}/${binaries_dir}" "$version" >/dev/null
	echo ">>> synced ${tool} v${version} -> ${binaries_dir}"
}

main() {
	local tool=""
	local selected=0

	assert_all_zig_tools_configured

	for tool in $(all_tools); do
		tool_selected "$tool" || continue
		selected=1
		sync_tool "$tool"
	done

	[[ "$selected" == "1" ]] || {
		echo "error: no supported Zig tools selected" >&2
		exit 1
	}
}

main "$@"
