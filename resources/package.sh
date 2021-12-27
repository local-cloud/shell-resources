#!/usr/bin/env bash

set -euo pipefail

ARG_PACKAGES=${ARG_PACKAGES:?'Packages must be specified'}

export DEBIAN_FRONTEND=noninteractive
if [ "$ARG_CHECK_MODE" -eq 1 ]; then
	options='-qq --simulate -o APT::Get::Show-User-Simulation-Note=no'
else
	options='-y'
fi
# shellcheck disable=SC2086
apt-get install $options $ARG_PACKAGES
