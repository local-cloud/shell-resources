#!/usr/bin/env bash
### START DEPENDENCIES
# set_file_permissions
### END DEPENDENCIES

set -euo pipefail
shopt -s lastpipe

ARG_PATH=${ARG_PATH:?'Path must be specified'}
ARG_OWNER=${ARG_OWNER:-$(id -un)}
ARG_GROUP=${ARG_GROUP:-$(id -gn)}
ARG_MODE=${ARG_MODE:-750}
ARG_FOLLOW_LINK=${ARG_FOLLOW_LINK:-1}
ARG_STATE=${ARG_STATE:-'present'}
ARG_RECURSIVE=${ARG_RECURSIVE:-1}

setup_directory() {
	set_file_permissions \
		--path "$ARG_PATH" \
		--owner "$ARG_OWNER" \
		--group "$ARG_GROUP" \
		--mode "$ARG_MODE"
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
				echo "Create directory ${ARG_PATH}"
				return
			fi
			mkdir --verbose --mode "$ARG_MODE" "$ARG_PATH"
			setup_directory
		fi
	else
		if [ "$file_type" != 'directory' ]; then
			echo "${ARG_PATH} exists and is not a directory." >&2
			return 1
		fi
		if [ "$ARG_STATE" = 'present' ]; then
			setup_directory
		else
			if [ "$ARG_CHECK_MODE" -eq 1 ]; then
				echo "Remove directory ${ARG_PATH}"
				return
			fi
			local recursive_option=''
			if [ "$ARG_RECURSIVE" -eq 1 ]; then
				recursive_option='-r'
			fi
			rm $recursive_option -vf "${ARG_PATH}"
		fi
	fi
}

main "$@"
