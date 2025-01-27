#!/usr/bin/env bash
INVOKE_DIR=${PWD}/

_export() {
		# Check if INVOKE_DIR is defined
		if [ -z "$INVOKE_DIR" ]; then
				echo "Error: INVOKE_DIR is not defined." >&2
				return 1
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

				popd >/dev/null || continue

				if [ -z "$REMOTE" ]; then
						continue
				fi

				# Print the result
				echo "$PRJ_DIR=$REMOTE"
		done
}

_import() {
		local input_file="${1:-/dev/stdin}" PRJ_DIR REMOTE line

		# Check if the input file exists and is readable
		if [[ ! -r "$input_file" ]]; then
				echo "❌ Input file not found or unreadable: $input_file" >&2
				return 1
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
		# tty: Call _export with no parameters
		_export
else
		# no tty: Explicitly call _import with arguments
		_import "$@"
fi
