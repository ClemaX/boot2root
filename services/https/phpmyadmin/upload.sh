#!/usr/bin/env bash

SCRIPTDIR=.

CONTENT=$(tr '\n' ' ' < "$3")
DEST="${4:-/tmp/$(basename "$3")}"

source "$SCRIPTDIR/login.sh"

./query.sh "$1" "$2" <<< "SELECT '$CONTENT' INTO OUTFILE '$DEST'"
