#!/usr/bin/env bash
### START DEPENDENCIES
# set_file_permissions
### END DEPENDENCIES

set -euo pipefail
shopt -s lastpipe

ARG_CONTENT=${ARG_CONTENT:-''}
ARG_PATH=${ARG_PATH:?'Path must be specified'}
ARG_OWNER=${ARG_OWNER:-$(id -un)}
ARG_GROUP=${ARG_GROUP:-$(id -gn)}
ARG_MODE=${ARG_MODE:-640}
# Available values: present, absent
ARG_STATE=${ARG_STATE:-'present'}
ARG_FOLLOW_LINK=${ARG_FOLLOW_LINK:-1}

setup_file() {
	set_file_permissions \
		--path "$ARG_PATH" \
		--owner "$ARG_OWNER" \
		--group "$ARG_GROUP" \
		--mode "$ARG_MODE"

	changed=0
	if [ -s "$ARG_PATH" ]; then
		diff <(echo "$ARG_CONTENT") "$ARG_PATH" || changed=1
	else
		diff <(echo "$ARG_CONTENT") "$ARG_PATH" >/dev/null || changed=1
		echo "Copy content to ${ARG_PATH}"
	fi
	if [ "$ARG_CHECK_MODE" -eq 1 ]; then
		return
	fi
	if [ "$changed" -eq 1 ]; then
		echo -n "$ARG_CONTENT" > "$ARG_PATH"
	fi
}

main() {
	if [ "$ARG_FOLLOW_LINK" -eq 1 ]; then
		ARG_PATH=$(realpath "$ARG_PATH")
	fi

	local file_type stat_exit_code
	set +e
	stat -c "%F" "$ARG_PATH" 2>/dev/null | read -r file_type
	stat_exit_code="${PIPESTATUS[0]}"
	set -e

	if [ "$stat_exit_code" -ne 0 ]; then
		if [ "$ARG_STATE" = 'present' ]; then
			if [ "$ARG_CHECK_MODE" -eq 1 ]; then
				echo "Create file ${ARG_PATH}"
				return
			fi
			touch "$ARG_PATH"
			setup_file
		fi
	else
		if [ "$(echo "$file_type" | rev | cut -d ' ' -f 1 | rev)" != 'file' ]; then
			echo "${ARG_PATH} exists and is not a regular file." >&2
			return 1
		fi
		if [ "$ARG_STATE" = 'present' ]; then
			setup_file
		else
			if [ "$ARG_CHECK_MODE" -eq 1 ]; then
				echo "Remove file ${ARG_PATH}"
				return
			fi
			rm -fv "${ARG_PATH}"
		fi
	fi
}

main "$@"
