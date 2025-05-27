#!/usr/bin/env bash
INVOKE_DIR=${PWD}/

_show_help() {
		cat << EOF
Repoman - A tool to export and import git repositories

USAGE:
  Export mode (when run from terminal):
    $(basename "$0") [OPTIONS]

  Import mode (when piped input):
    cat repos.txt | $(basename "$0") [FILE]

OPTIONS:
  -n, --no-remote    Only list repositories without a remote
  -a, --all          List all repositories (with and without remotes)
  -h, --help         Show this help message

EXAMPLES:
  $(basename "$0") > repos.txt             # Export repos with remotes to a file
  $(basename "$0") -n > local-repos.txt    # Export repos without remotes to a file
  cat repos.txt | $(basename "$0")         # Import/clone repositories from a file
EOF
}

_export() {
		local show_no_remote=false
		local show_all=false

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

		# Check if INVOKE_DIR is defined
		if [ -z "$INVOKE_DIR" ]; then
				echo "Error: INVOKE_DIR is not defined." >&2
				exit 1
		fi

		# Use `find` command in a more portable way
		find . -type d -name '.git' | while read -r d; do
				# Ensure navigation to the directory works
				if ! pushd "$d/.." >/dev/null; then
						echo "Error: Could not navigate to $d/.." >&2
						continue
				fi

				PRJ_DIR=${PWD#"$INVOKE_DIR"}
				REMOTE=$(git remote get-url origin 2>/dev/null)
				has_remote=$([[ -n "$REMOTE" ]] && echo true || echo false)

				popd >/dev/null || continue

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

if [ -t 0 ]; then
		# tty: Call _export with all parameters provided
		_export "$@"
else
		# no tty: Explicitly call _import with arguments
		_import "$@"
fi
exit 0
