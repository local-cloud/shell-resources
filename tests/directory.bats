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
	run -0 "$MANIFEST"
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
	run -0 "$MANIFEST"
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
	run -0 "$MANIFEST"
	run stat "$path"
	[ "$status" -ne 0 ]
}

@test "leave permissions unchanged" {
	local path="${BATS_TEST_TMPDIR}/dir"
	mkdir "$path"
	chmod 000 "$path"
	cat >> "$MANIFEST" <<-EOF
		resource directory path $(q "$path")
	EOF
	run -0 "$MANIFEST"
	run -0 stat -c "%F:%a" "$path"
	[ "$output" = "directory:0" ]
}
