#!/usr/bin/env bash
INVOKE_DIR=${PWD}/

_export() {
	while read -r d
	do
		pushd "$d/.." >/dev/null
			PRJ_DIR=${PWD#"$INVOKE_DIR"}
			REMOTE=$(git remote get-url origin 2>/dev/null)
		popd >/dev/null

		if [ -z "$REMOTE" ]; then
		  continue
		fi

		echo "$PRJ_DIR=$REMOTE"
	done < <(find . -type d -name '.git' -follow)	
}

_import() {
	while read line
	do
		IFS='=' read PRJ_DIR REMOTE <<< "$line"
		
		echo; echo "⏳ Cloning $PRJ_DIR"
		git clone $REMOTE $PRJ_DIR
	done < "${1:-/dev/stdin}"
}


if [ -t 0 ]; then
	# tty	
	_export
else 
	# no tty
	_import
fi
