#!/usr/bin/env bash

set -euo pipefail
set -x

: \
	"${ARG_SOURCE:?"Source must be provided"}" \
	"${ARG_DESTINATION:?"Destination must be provided"}"

if [ -e "$ARG_DESTINATION" ] && [ ! -L "$ARG_DESTINATION" ]; then
	echo "${ARG_DESTINATION} already exists and is not a symbolic link." >&2
	exit 1
fi
link_source=$(realpath "$ARG_DESTINATION" 2>/dev/null) || true
if [ "$link_source" != "$ARG_SOURCE" ]; then
	if [ "$ARG_CHECK_MODE" -eq 1 ]; then
		echo "Create symbolic link from ${ARG_DESTINATION} to ${ARG_SOURCE}"
	else
		ln -s -f -v "$ARG_SOURCE" "$ARG_DESTINATION"
	fi
fi
