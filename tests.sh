#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME='shell-resources-tests'
# Leave container by default
LEAVE_ENV=${LEAVE_ENV:-1}

on_exit() {
	local exit_code=$?
	if [ "$exit_code" -eq 0 ] || [ "$LEAVE_ENV" -eq 0 ]; then
		if podman inspect "$CONTAINER_NAME" &>/dev/null; then
			podman kill "$CONTAINER_NAME" >/dev/null || true
			podman rm -f "$CONTAINER_NAME" >/dev/null
		fi
	fi
	exit "$exit_code"
}

main() {
	trap on_exit EXIT
	[ ! -d .bats ] && git clone --depth 1 https://github.com/bats-core/bats-core .bats
	shellcheck resources.sh resources/*
	if ! podman inspect "$CONTAINER_NAME" &>/dev/null; then
		podman run \
			-d --name "$CONTAINER_NAME" \
			-v ".:/test:ro" \
			debian:bullseye \
			sleep infinity \
			>/dev/null
	fi
	local with_tty_option=''
	if [ -t 1 ]; then
		with_tty_option='-t'
	fi
	podman exec "$with_tty_option" "$CONTAINER_NAME" "/test/.bats/bin/bats" "$@" "/test/tests"
}

main "$@"
