load common.sh

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
