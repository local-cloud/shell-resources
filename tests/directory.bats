load common.sh

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

@test "remove existing directory" {
	local path="${BATS_TEST_TMPDIR}/dir"
	mkdir "$path"
	touch "${path}/file1"
	cat >> "$MANIFEST" <<-EOF
		resource directory \
			path $(q "$path") \
			state 'absent'
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	run stat "$path"
	[ "$status" -ne 0 ]
}
