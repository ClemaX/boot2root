#!/usr/bin/env bash

set -euo pipefail

export LC_LANG=C

to_printable()
{
	local val="$1"

	[ "$val" -lt 5 ] && ((val+=16#10))

	printf "\x$(printf '%x' "$((16#60 + val))")"
}

KEY="isrveawhobpnutfg"
STR="giants"

ANSWER=""

for ((i=0; i<${#STR}; i++))
do
	c="${STR:$i:1}"
	sub="${KEY%${c}*}"
	ANSWER+=$(to_printable "${#sub}")
done

echo "$ANSWER"
