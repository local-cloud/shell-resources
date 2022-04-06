load common.sh

resource_repository() {
	local state=${1:-"present"}
	cat >> "$MANIFEST" <<-EOF
		resource apt_repository \
			name ${name} \
			url ${url} \
			suites ${suites} \
			components ${components} \
			keyring ${keyring} \
			state ${state}
	EOF
}

@test "manage APT repository" {
	if [ ! -e "/etc/debian_version" ]; then
		skip "Run only on Debian."
	fi

	local \
		name="test" \
		url="http://localhost/test" \
		suites="stable" \
		components="main" \
		keyring="qwerty"
	local \
		keyring_path="/usr/share/keyrings/${name}-archive-keyring.gpg" \
		preferences_path="/etc/apt/preferences.d/${name}.pref" \
		sources_path="/etc/apt/sources.list.d/${name}.sources"

	cat >> "$MANIFEST" <<-EOF
		resource apt_repository \
			name ${name} \
			url ${url} \
			suites ${suites} \
			components ${components} \
			keyring ${keyring}
	EOF
	run -0 "$MANIFEST"
	run -0 "$MANIFEST"
	[ "$(cat "$keyring_path")" = "$keyring" ]
	[ "$(grep -E "^URIs:" "$sources_path")" = "URIs: ${url}" ]
	[ "$(grep -E "^Pin:" "$preferences_path")" = "Pin: origin localhost" ]

	setup_manifest
	cat >> "$MANIFEST" <<-EOF
		resource apt_repository \
			name ${name} \
			state "absent"
	EOF
	run -0 "$MANIFEST"
	run -0 "$MANIFEST"
	[ ! -e "$keyring_path" ]
	[ ! -e "$sources_path" ]
	[ ! -e "$preferences_path" ]
}
