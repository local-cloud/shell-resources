#!/usr/bin/env bash

set -euo pipefail

ARG_URL=${ARG_URL:-https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz}
ARG_PATH=${ARG_PATH:-/usr/local/go}

if [ -e "${ARG_PATH}/VERSION" ]; then
	exit
fi
[ "$ARG_CHECK_MODE" -eq 1 ] && {
	echo "Install Go in ${ARG_PATH}"
	exit
}
echo "Installing Go..."
wget "$ARG_URL" -qO - \
	| tar -C "$ARG_PATH" --strip-components=1 -xzf -
