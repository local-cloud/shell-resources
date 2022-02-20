#!/usr/bin/env bash
### START DEPENDENCIES
# set_file_permissions
### END DEPENDENCIES

set -euo pipefail
shopt -s lastpipe

ARG_MANAGE_CONTENT=${ARG_MANAGE_CONTENT:-1}
ARG_CONTENT=${ARG_CONTENT:-}
ARG_PATH=${ARG_PATH:?"Path must be specified"}
ARG_OWNER=${ARG_OWNER:-}
ARG_GROUP=${ARG_GROUP:-}
ARG_MODE=${ARG_MODE:-}
# Available values: present, absent
ARG_STATE=${ARG_STATE:-"present"}
ARG_FOLLOW_LINK=${ARG_FOLLOW_LINK:-1}

setup_permissions() {
	declare -a options
	[ -n "$ARG_OWNER" ] && options+=("--owner" "$ARG_OWNER")
	[ -n "$ARG_GROUP" ] && options+=("--group" "$ARG_GROUP")
	[ -n "$ARG_MODE" ] && options+=("--mode" "$ARG_MODE")
	set_file_permissions --path "$ARG_PATH" "${options[@]}"
}

setup_content() {
	if [ "$ARG_MANAGE_CONTENT" = 0 ]; then
		return 0
	fi
	local changed=0
	if [ -s "$ARG_PATH" ]; then
		diff <(echo "$ARG_CONTENT") "$ARG_PATH" || changed=1
	else
		diff <(echo "$ARG_CONTENT") "$ARG_PATH" >/dev/null || changed=1
		echo "Copy content to ${ARG_PATH}"
	fi
	if [ "$ARG_CHECK_MODE" = 1 ]; then
		return
	fi
	if [ "$changed" = 1 ]; then
		echo -n "$ARG_CONTENT" > "$ARG_PATH"
	fi
}

setup_file() {
	setup_permissions
	setup_content
}

main() {
	if [ "$ARG_FOLLOW_LINK" = 1 ]; then
		ARG_PATH=$(realpath "$ARG_PATH")
	fi

	local file_type stat_exit_code
	set +e
	stat -c "%F" "$ARG_PATH" 2>/dev/null | read -r file_type
	stat_exit_code="${PIPESTATUS[0]}"
	set -e

	if [ "$stat_exit_code" != 0 ]; then
		if [ "$ARG_STATE" = "present" ]; then
			if [ "$ARG_CHECK_MODE" = 1 ]; then
				echo "Create file ${ARG_PATH}"
			else
				umask 066
				touch "$ARG_PATH"
				setup_file
			fi
		fi
	else
		if [ "$(echo "$file_type" | rev | cut -d ' ' -f 1 | rev)" != 'file' ]; then
			echo "${ARG_PATH} exists and is not a regular file." >&2
			return 1
		fi
		if [ "$ARG_STATE" = 'present' ]; then
			setup_file
		else
			if [ "$ARG_CHECK_MODE" = 1 ]; then
				echo "Remove file ${ARG_PATH}"
				return
			fi
			rm -fv "${ARG_PATH}"
		fi
	fi
}

main "$@"
