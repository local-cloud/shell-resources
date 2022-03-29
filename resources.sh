#!/usr/bin/env bash

RESOURCE_DIR=${RESOURCE_DIR:-$(realpath ./resources)}

resource() {
	local resource=$1; shift
	(
		if [ "$(type -t "resource_${resource}")" != "function" ]; then
			resource_to_function "$resource"
		fi
		local var_name var_value
		while [ "$#" -gt 0 ]; do
			var_name=$1; shift
			var_name="ARG_${var_name^^}"
			var_value=$1; shift
			declare "${var_name}=${var_value}"
		done
		"resource_${resource}"
	)
}

get_resource_dependencies() {
	# shellcheck disable=SC2064
	trap "$(shopt -p lastpipe)" RETURN
	shopt -s lastpipe
	local dependencies
	sed -n "/### START DEPENDENCIES/,/### END DEPENDENCIES/p" \
		| tail -n +2 \
		| head -n -1 \
		| cut -d " " -f 2 \
		| IFS="" read -rd "" dependencies
	local dependency
	for dependency in $dependencies; do
		if [ "$(type -t "$dependency")" != "function" ]; then
			# TODO: Base directory would be better than relying on poorly named RESOURCE_DIR
			# shellcheck disable=SC1090
			source "${RESOURCE_DIR}/../helpers/${dependency}.sh"
		fi
		declare -f "${dependency}"
	done
}

resource_to_function() {
	# shellcheck disable=SC2064
	trap "$(shopt -p lastpipe)" RETURN
	shopt -s lastpipe
	local resource=$1
	local function_definition
	{
		echo "resource_${resource}() {"
		echo "set -euo pipefail"
		# shellcheck disable=SC2016
		echo 'trap "$(shopt -p);$(shopt -po);$(declare -f)" RETURN'
		local resource_code
		IFS="" read -rd "" resource_code < "${RESOURCE_DIR}/${resource}.sh"
		echo "$resource_code" | get_resource_dependencies
		echo "$resource_code"
		echo "}"
	} | IFS="" read -rd "" function_definition || true
	eval "$function_definition"
}

resource_to_string() {
	local resource=$1; shift
	if [ "$(type -t "resource_${resource}")" != "function" ]; then
		resource_to_function "$resource"
	fi
	declare -f "resource_${resource}"
	declare -f resource
	if [ "$(($# % 2))" -ne 0 ]; then
		echo "Resource ${resource} needs even quantity of arguments." >&2
		return 1
	fi
	echo -n "resource ${resource}"
	local arg
	for arg in "$@"; do
		printf " %q" "$arg"
	done
	echo
}

use_check_mode() {
	# shellcheck disable=SC2064
	trap "$(shopt -p)" RETURN
	shopt -s lastpipe

	local function_definition

	declare -f resource | tail -n +3 | IFS="" read -rd "" function_definition || true
	{
		echo "resource() {"
		# shellcheck disable=SC2016
		echo 'set -- "$@" check_mode "$CHECK_MODE"'
		echo "$function_definition"
	} | IFS="" read -rd "" function_definition || true
	eval "$function_definition"

	declare -f resource_to_string | tail -n +3 | IFS="" read -rd "" function_definition || true
	{
		echo "resource_to_string() {"
		# shellcheck disable=SC2016
		echo 'echo "CHECK_MODE=$(printf "%q" "$CHECK_MODE")"'
		echo "$function_definition"
	} | IFS="" read -rd "" function_definition || true
	eval "$function_definition"
}

with_sudo() {
	# shellcheck disable=SC2064
	trap "$(shopt -po errexit)" RETURN
	set -o errexit
	local \
		password=$1 \
		user=${2:-root}
	{
		echo "$password"
		cat
	} | sudo \
		--reset-timestamp \
		--user "$user" \
		--prompt "" \
		--stdin \
		bash
}
