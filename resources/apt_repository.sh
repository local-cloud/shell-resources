#!/usr/bin/env bash
### START DEPENDENCIES
# resource_file
### END DEPENDENCIES

set -euo pipefail
shopt -s lastpipe

: \
	"${ARG_CHECK_MODE:=0}" \
	"${ARG_STATE:="present"}" \
	"${ARG_NAME:?}" \
	"${ARG_URL:=}" \
	"${ARG_SUITES:=}" \
	"${ARG_COMPONENTS:=}" \
	"${ARG_KEYRING:=}" \
	"${ARG_TYPES:="deb"}" \
	"${ARG_DOMAIN:=}" \
	"${ARG_ARCHITECTURES:=}"

if [ "$ARG_STATE" = "present" ]; then
	: \
		"${ARG_URL:?}" \
		"${ARG_SUITES:?}" \
		"${ARG_COMPONENTS:?}" \
		"${ARG_KEYRING:?}"
fi
if [ -z "${ARG_ARCHITECTURES}" ]; then
	dpkg --print-architecture | read -r ARG_ARCHITECTURES
fi
keyring_path="/usr/share/keyrings/${ARG_NAME}-archive-keyring.gpg"
resource file \
	path "$keyring_path" \
	content "$ARG_KEYRING" \
	state "$ARG_STATE"
{ IFS="" read -rd "" source_file || true; } <<-EOF
	Types: "${ARG_TYPES}"
	URIs: ${ARG_URL}
	Suites: ${ARG_SUITES}
	Architectures: ${ARG_ARCHITECTURES}
	Components: ${ARG_COMPONENTS}
	Signed-By: ${keyring_path}
EOF
resource file \
	path "/etc/apt/sources.list.d/${ARG_NAME}.sources" \
	content "$source_file" \
	state "$ARG_STATE"
if [ -z "${ARG_DOMAIN:-}" ]; then
	echo "$ARG_URL" | cut -d '/' -f 3 | read -r ARG_DOMAIN
fi
{ IFS="" read -rd "" preferences_file || true; } <<-EOF
	Package: *
	Pin: origin ${ARG_DOMAIN}
	Pin-Priority: 100
EOF
resource file \
	path "/etc/apt/preferences.d/${ARG_NAME}.pref" \
	content "$preferences_file" \
	state "$ARG_STATE"
