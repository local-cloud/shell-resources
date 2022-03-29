#!/usr/bin/env bash

set -euo pipefail
shopt -s lastpipe

: \
	"${ARG_CHECK_MODE:=0}" \
	"${ARG_OWNER:=}" \
	"${ARG_GROUP:=}" \
	"${ARG_MODE:=}" \
	"${ARG_PATH:?"Path must be specified"}"

[ -n "$ARG_OWNER" ] && ARG_OWNER=$(id -u "$ARG_OWNER")
[ -n "$ARG_GROUP" ] && ARG_GROUP=$(id -g "$ARG_GROUP")

IFS=":" read -r \
	current_uid \
	current_gid \
	current_mode \
	< <(stat -c "%u:%g:%a" "$ARG_PATH")
if [ "${ARG_OWNER:-"$current_uid"}" != "$current_uid" ]; then
	if [ "$ARG_CHECK_MODE" = 1 ]; then
		echo "Change ARG_OWNER from ${current_uid} to ${ARG_OWNER} for ${ARG_PATH}"
	else
		chown -c "$ARG_OWNER" "$ARG_PATH"
	fi
fi
if [ "${ARG_GROUP:-"$current_gid"}" != "$current_gid" ]; then
	if [ "$ARG_CHECK_MODE" = 1 ]; then
		echo "Change group from ${current_gid} to ${ARG_GROUP} for ${ARG_PATH}"
	else
		chgrp -c "$ARG_GROUP" "$ARG_PATH"
	fi
fi
if [ "${ARG_MODE:-"$current_mode"}" != "$current_mode" ]; then
	if [ "$ARG_CHECK_MODE" = 1 ]; then
		echo "Change mode from ${current_mode} to ${ARG_MODE}"
	else
		chmod -c "$ARG_MODE" "$ARG_PATH"
	fi
fi
