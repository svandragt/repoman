#!/usr/bin/env bash
INVOKE_DIR=${PWD}/

_show_help() {
		cat << EOF
Repoman - A tool to export and import git repositories

USAGE:
  Export mode (when run from terminal):
    $(basename "$0") [OPTIONS]

  Import mode (when given a file or piped input):
    $(basename "$0") repos.txt
    cat repos.txt | $(basename "$0")

OPTIONS:
  (default)          Only list repositories with a remote
  -n, --no-remote    Only list repositories without a remote
  -a, --all          List all repositories (with and without remotes)
  -x, --exclude PAT  Skip repositories at PAT or below it. PAT is a path
                     relative to the working directory and may be a glob.
                     Repeat the option to exclude more than one.
  -h, --help         Show this help message

EXAMPLES:
  $(basename "$0") > repos.txt             # Export repos with remotes to a file
  $(basename "$0") -n > local-repos.txt    # Export repos without remotes to a file
  $(basename "$0") -x work -x 'tmp*'       # Export, skipping work/ and tmp*/
  cat repos.txt | $(basename "$0")         # Import/clone repositories from a file
  $(basename "$0") repos.txt               # The same, without the pipe
EOF
}

_is_excluded() {
		local dir=$1 pat
		shift
		for pat in "$@"; do
				# Unquoted $pat so a pattern can be a glob as well as a plain name
				# shellcheck disable=SC2053
				if [[ "$dir" == $pat || "$dir" == $pat/* ]]; then
						return 0
				fi
		done
		return 1
}

_export() {
		local show_no_remote=false
		local show_all=false
		local excludes=()

		# Parse command line arguments
		while [[ $# -gt 0 ]]; do
				case "$1" in
						-n|--no-remote)
								show_no_remote=true
								shift
								;;
						-a|--all)
								show_all=true
								shift
								;;
						-x|--exclude)
								if [[ -z "$2" ]]; then
										echo "Error: $1 requires a pattern" >&2
										exit 1
								fi
								excludes+=("$2")
								shift 2
								;;
						-h|--help)
								_show_help
								exit 0
								;;
						*)
								echo "Error: Unknown option: $1" >&2
								_show_help
								exit 1
								;;
				esac
		done

		# -prune: a repo's own object store never contains another repo
		find . -type d -name '.git' -prune | while read -r d; do
				# Ensure navigation to the directory works
				if ! pushd "$d/.." >/dev/null; then
						echo "Error: Could not navigate to $d/.." >&2
						continue
				fi

				PRJ_DIR=${PWD#"$INVOKE_DIR"}
				REMOTE=$(git remote get-url origin 2>/dev/null)
				has_remote=$([[ -n "$REMOTE" ]] && echo true || echo false)

				popd >/dev/null || continue

				if _is_excluded "$PRJ_DIR" "${excludes[@]}"; then
						continue
				fi

				# Determine whether to show this repository based on filters
				if $show_all; then
						# Show all repositories
						if $has_remote; then
								echo "$PRJ_DIR=$REMOTE"
						else
								echo "$PRJ_DIR"
						fi
				elif $show_no_remote; then
						# Only show repos without remotes
						if ! $has_remote; then
								echo "$PRJ_DIR"
						fi
				else
						# Default: only show repos with remotes
						if $has_remote; then
								echo "$PRJ_DIR=$REMOTE"
						fi
				fi
		done
}

_import() {
		local input_file="${1:-/dev/stdin}" PRJ_DIR REMOTE line

		# Check if the input file exists and is readable
		if [[ ! -r "$input_file" ]]; then
				echo "❌ Input file not found or unreadable: $input_file" >&2
				exit 1
		fi

		# Read the file line by line
		while read -r line; do
				# Skip empty lines
				if [[ -z "$line" ]]; then
						echo "⚠️ Skipping empty line" >&2
						continue
				fi

				# Parse PRJ_DIR and REMOTE from the line
				IFS='=' read -r PRJ_DIR REMOTE <<< "$line"

				# Validate the parsed values
				if [[ -z "$PRJ_DIR" || -z "$REMOTE" ]]; then
						echo "❌ Invalid entry: $line" >&2
						continue
				fi

				echo; echo "⏳ Cloning $PRJ_DIR"
				if ! git clone "$REMOTE" "$PRJ_DIR"; then
						echo "❌ Failed to clone $REMOTE into $PRJ_DIR" >&2
						continue
				fi
		done < "$input_file"
}

if [[ -f "$1" ]]; then
		# A readable file argument always means import, tty or not
		_import "$1"
elif [[ "$1" == -* || -t 0 ]]; then
		# An option always means export, even when the output is piped
		_export "$@"
else
		_import "$@"
fi
exit 0
