load common.sh

@test "create a new file" {
	local path="${BATS_TEST_TMPDIR}/file"
	cat >> "$MANIFEST" <<-EOF
		resource file \
			path $(q "$path") \
			content "test"
		stat -c '%F' $(q "$path")
		cat $(q "$path")
	EOF
	run -0 "$MANIFEST"
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
	run -0 "$MANIFEST"
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

@test "leave permissions and content unchanged" {
	local path="${BATS_TEST_TMPDIR}/file"
	echo qwerty > "$path"
	chown nobody:root "$path"
	chmod 000 "$path"
	cat >> "$MANIFEST" <<-EOF
		resource file \
			path $(q "$path") \
			manage_content 0
	EOF
	run -0 "$MANIFEST"
	run -0 stat -c "%U:%G:%a:%F" "$path"
	[ "$output" = "nobody:root:0:regular file" ]
}
