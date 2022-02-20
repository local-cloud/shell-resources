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
			owner=$(id -u "$1")
			shift
		;;
		'--group')
			group=$(id -g "$1")
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
	if [ -z "$path" ]; then
		echo "Path must not be empty" >&2
		exit 1
	fi

	local current_uid current_gid current_mode
	# Colon should never appear in username/groupname. Otherwise they would
	# break /etc/{passwd,group}.
	IFS=":" read -r \
		current_uid \
		current_gid \
		current_mode \
		< <(stat -c "%u:%g:%a" "$path")
	if [ "${owner:-"$current_uid"}" != "$current_uid" ]; then
		if [ "$ARG_CHECK_MODE" = 1 ]; then
			echo "Change owner from ${current_uid} to ${owner} for ${path}"
		else
			chown -c "$owner" "$path"
		fi
	fi
	if [ "${group:-"$current_gid"}" != "$current_gid" ]; then
		if [ "$ARG_CHECK_MODE" = 1 ]; then
			echo "Change group from ${current_gid} to ${group} for ${path}"
		else
			chgrp -c "$group" "$path"
		fi
	fi
	if [ "${mode:-"$current_mode"}" != "$current_mode" ]; then
		if [ "$ARG_CHECK_MODE" = 1 ]; then
			echo "Change mode from ${current_mode} to ${mode}"
		else
			chmod -c "$mode" "$path"
		fi
	fi
}
