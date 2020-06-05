#!/usr/bin/env bash
FILE=repoman.lst
INVOKE_DIR=${PWD}/

help() {
	ME=`basename "$0"`
	cat << EOF
usage: $ME <option>

This script exports and imports git repos found at the current location.

OPTIONS:
   export  Write git repos into $FILE
   import  Clone git repos from $FILE
   help    This message
EOF
}


export() {
	if [[ -f "$FILE" ]]; then
	    echo "⚠️ Error: $FILE exists! Please remove the file before exporting."
	    exit 1
	fi

	while read -r d
	do
	    pushd "$d/.." >/dev/null
	        PRJ_DIR=${PWD#"$INVOKE_DIR"}
	        REMOTE=$(git remote get-url origin 2>/dev/null)
	    popd >/dev/null

	    if [ -z "$REMOTE" ]; then
	      continue
	    fi

	    echo "$PRJ_DIR=$REMOTE" | tee -a $FILE
	done < <(find . -type d -name '.git' -follow)	
}

import() {
	if [[ ! -f "$FILE" ]]; then
	    echo "⚠️ Error: $FILE does not exists! Please copy it here before importing."
	    exit 1
	fi

	while read line
	do
		IFS='=' read PRJ_DIR REMOTE <<< "$line"
		
	    echo; echo "⏳ Cloning $PRJ_DIR"
	    git clone $REMOTE $PRJ_DIR
	done < repoman.lst
}


CB=$1; CB=${CB:=help}
$CB
