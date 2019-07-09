# vbuild: a build system written in POSIX-compliant shell

# Internal API
_vbuild_print_indent() {
	[ "$1" -le 0 ] && return
	printf ' '
	_vbuild_print_indent "$(( $1 - 1 ))"
}

_vbuild_dbug() {
	[ -z "$VBUILD_VERBOSE" ] && return
	_vbuild_print_indent "$_vbuild_indent_level"
	echo "$@"
}

_vbuild_indent_level=0
_vbuild_indent() {
	_vbuild_indent_level="$(( ${1:-1} + _vbuild_indent_level ))"
}

_vbuild_rules=""

_vbuild_add_rule() {
	_vbuild_rules+="$(printf '%s\t%s\t%s' "$@")
"
	_vbuild_dbug "Added rule $2 -> $1 ($3)"
}

_vbuild_do_rule() {
	_vbuild_dbug "Searching for rule targetting $1"
	_vbuild_indent
	printf '%s' "$_vbuild_rules" | while IFS='	' read -r _vbuild_targets _vbuild_cond _vbuild_cmd; do
		_vbuild_dbug "Checking rule $_vbuild_cond -> $_vbuild_targets"
		_vbuild_indent
		echo "$_vbuild_targets" | tr ' ' '\n' | while read -r _vbuild_target; do
			_vbuild_dbug "Checking $_vbuild_target against $1"
			_vbuild_indent
			case "$1" in
				# Not quoted so that pattern matching occurs
				$_vbuild_target) 
					(_vbuild_dbug "Running rule $_vbuild_cond -> $_vbuild_targets"
					_vbuild_indent
					export target="$1"
					_vbuild_dbug "Checking condition $_vbuild_cond"
					if eval "$_vbuild_cond"; then
						_vbuild_dbug "Executing command $_vbuild_cmd"
						eval "$_vbuild_cmd"
					fi) || exit 2 # retcode 2 = build error
					exit 1 # retcode 1 = matched rule
					;;
			esac
			_vbuild_indent -1
		done || exit # Forward the exit code
		_vbuild_indent -1
	done
	_vbuild_ret="$?"

	case "$_vbuild_ret" in
		0)
			# No rule matched. If the file doesn't exist we need to throw an error
			_vbuild_dbug 'No rule found'
			if ! [ -e "$1" ]; then
				echo "Could not find rule for $1" >&2
				exit 2
			fi
			;;
		1)
			# We successfully executed a rule, so we're done
			;;
		*)
			# We found a rule, but there was an error executing it
			exit 2
			;;
	esac
	_vbuild_indent -1
}

_vbuild_detect_cc() {
	[ -n "$CROSS_TRIPLE" ] && CROSS_TRIPLE+=-
	for CC in "$CC" cc clang gcc tcc; do
		if command -v "$CROSS_TRIPLE$CC" 2>&1 >/dev/null; then
			CC="$CROSS_TRIPLE$CC"
			CROSS_TRIPLE="${CROSS_TRIPLE%-}"
			return 0
		fi
	done
	echo "Could not find a suitable C compiler" >&2
	exit 2
}

# Public API
dep() {
	# Rebuild all the dependencies
	vbuild "$@" || exit 2

	# Save the dependencies for use by the command
	deps="$*"

	# If the target doesn't exist, we need to rebuild it regardless
	[ -e "$target" ] || return 0

	# find is pretty much the only POSIX-compliant way to compare file mtimes from shell
	_vbuild_dep_findout="$(find -L "$@" -prune -newer "$target")" || exit 2
	[ -n "$_vbuild_dep_findout" ]
}

build() {
	_vbuild_targets="$1"
	shift
	_vbuild_cond="$1"
	shift
	_vbuild_command="$*"
	_vbuild_add_rule "$_vbuild_targets" "$_vbuild_cond" "$_vbuild_command"
}

vbuild() {
	for _vbuild_rule; do _vbuild_do_rule "$_vbuild_rule"; done
}

# Detect the system C compiler
_vbuild_detect_cc
