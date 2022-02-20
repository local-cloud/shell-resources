#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o errtrace
set -o pipefail
shopt -s nullglob

BATS_URL="https://github.com/bats-core/bats-core/archive/429e86417b52f09d491778bb3cd14eaa1d25462f.tar.gz"
CONTAINER_NAME="shell-resources-tests"
IMAGE_NAME=$CONTAINER_NAME
# Leave container by default
LEAVE_ENV=${LEAVE_ENV:-1}
TARGET_TEST="."
TARGET_IMAGE=""
TARGET_IMAGES="alpine debian"

on_error() {
	local \
		exit_code=$? \
		cmd=$BASH_COMMAND
	if [ "$LEAVE_ENV" != 1 ]; then
		local label
		for label in $TARGET_IMAGES; do
			podman rm -f "${CONTAINER_NAME}-${label}" >/dev/null || true
		done
	fi
	echo "Failing with code ${exit_code} at ${*} in command: ${cmd}" >&2
	exit "$exit_code"
}

build_images() {
	local label
	for label in $TARGET_IMAGES; do
		if [ -n "$TARGET_IMAGE" ] && [ "$label" != "$TARGET_IMAGE" ]; then
			continue
		fi
		if ! podman image inspect "${IMAGE_NAME}:${label}" &>/dev/null; then
			podman build -t "${IMAGE_NAME}:${label}" . -f "${label}.dockerfile"
		fi
	done
}

run_tests() {
	local label
	for label in $TARGET_IMAGES; do
		if [ -n "$TARGET_IMAGE" ] && [ "$label" != "$TARGET_IMAGE" ]; then
			continue
		fi
		echo "Running tests for ${label}..."
		if ! podman container inspect "${CONTAINER_NAME}-${label}" &>/dev/null; then
			podman run \
				-d --name "${CONTAINER_NAME}-${label}" \
				-v ".:/test:ro" \
				"${IMAGE_NAME}:${label}" \
				>/dev/null
		fi
		local with_tty_option=''
		if [ -t 1 ]; then
			with_tty_option='-t'
		fi
		podman exec \
			$with_tty_option \
			"${CONTAINER_NAME}-${label}" \
			"/test/.bats/bin/bats" \
			--print-output-on-failure \
			"/test/tests/${TARGET_TEST}"
		podman rm -f "${CONTAINER_NAME}-${label}" >/dev/null
	done
}

download_bats() {
	if [ ! -d .bats ]; then
		mkdir .bats
		wget -q -O - "$BATS_URL" \
			| tar -C .bats --strip-components 1 -xzf -
	fi
}

main_help() {
cat << EOF
Synopsis:
	Run shell-resources project tests in Podman containers.
Options:
	-i|--image IMAGE       Container image to use. By default all images are used
	                       sequentially.
	-t|--target TARGET     Target test path.
EOF
}

main() {
	trap 'on_error ${BASH_SOURCE[0]}:${LINENO}' ERR
	while [ "$#" != 0 ]; do
		local option
		option=$1
		shift
		case "$option" in
		-t|--target)
			TARGET_TEST=$option
			shift
		;;
		-i|--image)
			TARGET_IMAGE=$option
			shift
		;;
		*)
			main_help
			exit
		;;
		esac
	done
	shellcheck "$0" resources.sh resources/*
	download_bats
	build_images
	run_tests
}

main "$@"
