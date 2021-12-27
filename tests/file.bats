load common.sh

@test "create new file" {
	local path="${BATS_TEST_TMPDIR}/file"
	cat >> "$MANIFEST" <<-EOF
		resource file \
			path $(q "$path") \
			content "test"
		stat -c '%F' $(q "$path")
		cat $(q "$path")
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	[ "${lines[-2]}" = 'regular file' ]
	[ "${lines[-1]}" = 'test' ]
}

@test "remove existing file" {
	local path="${BATS_TEST_TMPDIR}/file"
	echo 'test' > "$path"
	cat >> "$MANIFEST" <<-EOF
		resource file \
			path $(q "$path") \
			state absent
	EOF
	run "$MANIFEST"
	[ "$status" -eq 0 ]
	run stat "$path"
	[ "$status" -ne 0 ]
}

@test "create file on directory" {
	local path="${BATS_TEST_TMPDIR}/file"
	mkdir "$path"
	cat >> "$MANIFEST" <<-EOF
		resource file \
			path $(q "$path")
	EOF
	run "$MANIFEST"
	[ "$status" -ne 0 ]
}
