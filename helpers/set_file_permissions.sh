set_file_permissions() {
	# shellcheck disable=SC2064
	trap "$(shopt -p lastpipe)" RETURN
	shopt -s lastpipe

	ARG_CHECK_MODE=${ARG_CHECK_MODE:-0}

	local \
		owner='' \
		group='' \
		mode='' \
		path=''

	while [ "$#" -gt 0 ]; do
		local option
		option=$1; shift
		case "$option" in
		'--path')
			path=$1
			shift
		;;
		'--owner')
			owner=$1
			shift
		;;
		'--group')
			group=$1
			shift
		;;
		'--mode')
			mode=$1
			shift
		;;
		*)
			echo "Wrong option: ${1}" >&2
			exit 1
		;;
		esac
	done
	if [ -z "$owner" ]; then
		owner=$(id -un)
	fi
	if [ -z "$group" ]; then
		group=$(id -gn)
	fi
	if [ -z "$mode" ]; then
		mode=755
	fi
	if [ -z "$path" ]; then
		echo "Path must not be empty" >&2
		exit 1
	fi

	local stat_output current_owner current_group current_mode
	stat -c "%U;%G;%a" "$path" | read -r stat_output
	echo "$stat_output" | cut -d ';' -f 1 | read -r current_owner
	echo "$stat_output" | cut -d ';' -f 2 | read -r current_group
	echo "$stat_output" | cut -d ';' -f 3 | read -r current_mode
	if [ "$owner" != "$current_owner" ] || [ "$group" != "$current_group" ]; then
		if [ "$ARG_CHECK_MODE" -eq 1 ]; then
			echo "Change ownership from ${current_owner}:${current_group} to ${owner}:${group}"
		else
			chown --changes "${owner}:${group}" "$path"
		fi
	fi

	if [ "$mode" != "$current_mode" ]; then
		if [ "$ARG_CHECK_MODE" -eq 1 ]; then
			echo "Change mode from ${current_mode} to ${mode}"
		else
			chmod --changes "$mode" "$path"
		fi
	fi
}
