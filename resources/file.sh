#!/usr/bin/env bash

set -euo pipefail

ARG_CONTENT=${ARG_CONTENT:?'Content must be specified'}
ARG_PATH=${ARG_PATH:?'Path must be specified'}
ARG_OWNER=${ARG_OWNER:-$(id -un)}
ARG_GROUP=${ARG_GROUP:-$(id -gn)}
ARG_MODE=${ARG_MODE:-640}
ARG_FOLLOW_LINK=${ARG_FOLLOW_LINK:-1}

if [ "$ARG_FOLLOW_LINK" -eq 1 ]; then
	ARG_PATH=$(realpath "$ARG_PATH")
fi

set +e
stat_output=$(stat -c "%F;%U;%G;%a" "$ARG_PATH" 2>/dev/null)
stat_exit_code=$?
set -e
if [ "$stat_exit_code" -ne 0 ]; then
	[ "$ARG_CHECK_MODE" -eq 1 ] && {
		echo "Create file ${ARG_PATH}"
		exit
	}
	touch "$ARG_PATH"
	stat_output=$(stat -c "%F;%U;%G;%a" "$ARG_PATH")
fi

file_type=$(echo "$stat_output" | cut -d ';' -f 1)
owner=$(echo "$stat_output" | cut -d ';' -f 2)
group=$(echo "$stat_output" | cut -d ';' -f 3)
mode=$(echo "$stat_output" | cut -d ';' -f 4)

if [ "${file_type:0:7}" != 'regular' ]; then
	echo "${ARG_PATH} exists and is not a regular file." >&2
	exit 1
fi

if [ "$owner" != "$ARG_OWNER" ] || [ "$group" != "$ARG_GROUP" ]; then
	if [ "$ARG_CHECK_MODE" -eq 1 ]; then
		echo "Change ownership from ${owner}:${group} to ${ARG_OWNER}:${ARG_GROUP}"
	else
		chown --changes "${ARG_OWNER}:${ARG_GROUP}" "$ARG_PATH"
	fi
fi

if [ "$mode" != "$ARG_MODE" ]; then
	if [ "$ARG_CHECK_MODE" -eq 1 ]; then
		echo "Change mode from ${mode} to ${ARG_MODE}"
	else
		chmod --changes "$ARG_MODE" "$ARG_PATH"
	fi
fi

changed=0
if [ -s "$ARG_PATH" ]; then
	diff <(echo "$ARG_CONTENT") "$ARG_PATH" || changed=1
else
	diff <(echo "$ARG_CONTENT") "$ARG_PATH" >/dev/null || changed=1
	echo "Copy content to ${ARG_PATH}"
fi
[ "$ARG_CHECK_MODE" -eq 1 ] && exit
if [ "$changed" -eq 1 ]; then
	echo "$ARG_CONTENT" > "$ARG_PATH"
fi
