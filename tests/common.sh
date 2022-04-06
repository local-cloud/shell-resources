q() {
	printf '%q' "$1"
}

setup_manifest() {
	cat > "$MANIFEST" <<- EOF
		#!/bin/bash
		set -euo pipefail
		export RESOURCE_DIR=/test/resources
		source "${BATS_TEST_DIRNAME}/../resources.sh"
		CHECK_MODE=0
		use_check_mode
	EOF
}

setup() {
	# Ignore duplicated slashes
	export BATS_TEST_TMPDIR=$(realpath "$BATS_TEST_TMPDIR")
	rm -rfv "${BATS_TEST_TMPDIR}"/*
	export MANIFEST="${BATS_TEST_TMPDIR}/manifest.sh"
	setup_manifest
	chmod +x "$MANIFEST"
}
