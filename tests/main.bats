q() {
	printf '%q' "$1"
}

setup() {
	# Ignore duplicated slashes
	export BATS_TEST_TMPDIR=$(realpath "$BATS_TEST_TMPDIR")
	rm -rfv "${BATS_TEST_TMPDIR}"/*
	export MANIFEST="${BATS_TEST_TMPDIR}/manifest.sh"
	cat > "$MANIFEST" <<- EOF
		#!/bin/bash
		set -euo pipefail
		export RESOURCE_DIR=/test/resources
		source "${BATS_TEST_DIRNAME}/../resources.sh"
		CHECK_MODE=0
		use_check_mode
	EOF
	chmod +x "$MANIFEST"
}

##############################################################################
# symbolic_link
##############################################################################
@test "new symbolic link" {
	touch "${BATS_TEST_TMPDIR}/src"
	cat >> "$MANIFEST" <<-EOF
		resource symbolic_link \
			source $(q "${BATS_TEST_TMPDIR}/src") \
			destination $(q "${BATS_TEST_TMPDIR}/dest")
		realpath $(q "${BATS_TEST_TMPDIR}/dest")
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	[ "${lines[-1]}" = "${BATS_TEST_TMPDIR}/src" ]
}

@test "invalid symbolic link" {
	touch "${BATS_TEST_TMPDIR}/src"
	touch "${BATS_TEST_TMPDIR}/dest"
	cat >> "$MANIFEST" <<-EOF
		resource symbolic_link \
			source $(q "${BATS_TEST_TMPDIR}/src") \
			destination $(q "${BATS_TEST_TMPDIR}/dest")
	EOF
	run "$MANIFEST"
	[ "$status" -ne 0 ]
	run stat -c "%F" "${BATS_TEST_TMPDIR}/dest"
	[ "$output" = 'regular empty file' ]
}

@test "symbolic link with different source" {
	touch "${BATS_TEST_TMPDIR}/src"
	ln -s "${BATS_TEST_TMPDIR}/src2" "${BATS_TEST_TMPDIR}/dest"
	cat >> "$MANIFEST" <<-EOF
		resource symbolic_link \
			source $(q "${BATS_TEST_TMPDIR}/src") \
			destination $(q "${BATS_TEST_TMPDIR}/dest")
		realpath $(q "${BATS_TEST_TMPDIR}/dest")
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	[ "${lines[-1]}" = "${BATS_TEST_TMPDIR}/src" ]
}

##############################################################################
# directory
##############################################################################
@test "new directory" {
	local \
		owner=nobody \
		group=root \
		mode=750
		path="${BATS_TEST_TMPDIR}/dir"
	cat >> "$MANIFEST" <<-EOF
		resource directory \
			path $(q "$path") \
			owner $(q "$owner") \
			group $(q "$group") \
			mode $(q "$mode")
		stat -c "%F;%U;%G;%a" $(q "$path")
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	[ "${lines[-1]}" = "directory;${owner};${group};${mode}" ]
}

@test "invalid directory" {
	touch "${BATS_TEST_TMPDIR}/dir"
	cat >> "$MANIFEST" <<-EOF
		resource directory \
			path $(q "${BATS_TEST_TMPDIR}/dir")
	EOF
	run "$MANIFEST"
	[ "$status" -ne 0 ]
	run stat -c "%F" "${BATS_TEST_TMPDIR}/dir"
	[ "$output" = "regular empty file" ]
}

@test "directory with different properties" {
	local \
		owner=nobody \
		group=root \
		mode=750
		path="${BATS_TEST_TMPDIR}/dir"
	mkdir "${path}"
	chown root:www-data "$path"
	chmod 111 "$path"
	cat >> "$MANIFEST" <<-EOF
		resource directory \
			path $(q "$path") \
			owner $(q "$owner") \
			group $(q "$group") \
			mode $(q "$mode")
		stat -c "%F;%U;%G;%a" $(q "$path")
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	[ "${lines[-1]}" = "directory;${owner};${group};${mode}" ]
}
