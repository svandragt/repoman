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
  -d, --dirty        Only list repositories with uncommitted changes.
                     Combines with the other filters.
  -h, --help         Show this help message

EXAMPLES:
  $(basename "$0") > repos.txt             # Export repos with remotes to a file
  $(basename "$0") -n > local-repos.txt    # Export repos without remotes to a file
  $(basename "$0") -x work -x 'tmp*'       # Export, skipping work/ and tmp*/
  $(basename "$0") -a -d                   # List every repo that needs a commit
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

# Matches the host only, so a github.com inside another host's path does not count
_is_github() {
		[[ "$1" =~ ^(https://([^/@]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/) ]]
}

# git has already printed its own error, so this adds only the likely fix
_clone_hint() {
		local remote=$1 dir=$2 err
		# A failed clone removes the directory it created, so a non-empty one was there before
		if [[ -n "$(ls -A -- "$dir" 2>/dev/null)" ]]; then
				echo "   $dir already exists. Move it away or remove its line from the list." >&2
				return
		fi
		# English messages and no second ssh prompt, so the patterns below match and the probe stays quiet
		err=$(LC_ALL=C GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-$(git config core.sshCommand || echo ssh)} -o BatchMode=yes" \
				git ls-remote "$remote" HEAD 2>&1 >/dev/null </dev/null)
		case "$err" in
				*"could not read Username"*|*"Authentication failed"*|*"Repository not found"*)
						echo "   The repository is private or does not exist, or your login to its host failed." >&2
						if [[ "$remote" == https://* ]] && _is_github "$remote"; then
								echo "   For a private GitHub repository, log in with 'gh auth login'." >&2
						fi ;;
				*"Host key verification failed"*)
						echo "   ssh does not know this host's key. Run 'ssh -T' against the host once to check and accept it." >&2 ;;
				*"Permission denied (publickey)"*)
						echo "   The host refused your SSH key. Add the key to your account, or change the remote to an https:// URL." >&2 ;;
				*"Could not resolve host"*)
						echo "   The host name does not resolve. Check the network connection and the URL." >&2 ;;
		esac
}

_export() {
		local show_no_remote=false
		local show_all=false
		local excludes=()
		local only_dirty=false

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
						-d|--dirty)
								only_dirty=true
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
				# The working directory itself is a repo: PWD has no trailing slash to strip
				[[ "$PWD/" == "$INVOKE_DIR" ]] && PRJ_DIR=.
				REMOTE=$(git remote get-url origin 2>/dev/null)
				has_remote=$([[ -n "$REMOTE" ]] && echo true || echo false)
				is_dirty=$([[ -n "$(git status --porcelain 2>/dev/null)" ]] && echo true || echo false)

				popd >/dev/null || continue

				if _is_excluded "$PRJ_DIR" "${excludes[@]}"; then
						continue
				fi
				if $only_dirty && ! $is_dirty; then
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
		local input_file="${1:-/dev/stdin}" PRJ_DIR REMOTE line clone

		# Check if the input file exists and is readable
		if [[ ! -r "$input_file" ]]; then
				echo "❌ Input file not found or unreadable: $input_file" >&2
				exit 1
		fi

		local use_gh=false
		if command -v gh >/dev/null && gh auth status --hostname github.com >/dev/null 2>&1; then
				use_gh=true
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
				clone=(git clone)
				# gh clones with its own login, so private repos work before `gh auth setup-git`
				if $use_gh && _is_github "$REMOTE"; then
						clone=(gh repo clone)
				fi
				# </dev/null: the loop's stdin is the list, and a child that reads it would skip repos
				if ! "${clone[@]}" "$REMOTE" "$PRJ_DIR" </dev/null; then
						echo "❌ Failed to clone $REMOTE into $PRJ_DIR" >&2
						_clone_hint "$REMOTE" "$PRJ_DIR"
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
