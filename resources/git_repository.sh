#!/usr/bin/env bash

set -euo pipefail

ARG_PATH=${ARG_PATH:?'Destination path must be present'}
ARG_URL=${ARG_URL:?'Repository URL must be present'}
ARG_BRANCH=${ARG_BRANCH:-''}

if [ -e "$ARG_PATH" ]; then
	if [ ! -d "${ARG_PATH}/.git" ]; then
		# shellcheck disable=SC2034
		ERROR_MESSAGE="${ARG_PATH} already exists and is not a repository."
		exit 1
	fi
	exit
fi
[ "$ARG_CHECK_MODE" -eq 1 ] && {
	echo "Create repository in ${ARG_PATH}"
	exit
}
if [ -n "$ARG_BRANCH" ]; then
	ARG_BRANCH="--branch $(printf '%q' "$ARG_BRANCH")"
fi
# shellcheck disable=SC2086
git clone "$ARG_URL" "$ARG_PATH" $ARG_BRANCH
