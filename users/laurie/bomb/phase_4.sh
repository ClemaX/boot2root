#!/usr/bin/env bash

set -euo pipefail

fib_pos() { # target
	local target="$1"
	local previous=1
	local pos=1
	local num=1
	local cur

	while [ "$num" -lt "$target" ]
	do
		((cur=num))
		((num+=previous))
		((previous=cur))
		((pos+=1))
	done
	echo "$pos"
}

POS=$(fib_pos 55)
SECRET=austinpowers

[ "${BONUS:-}" = true ] && echo "$POS $SECRET" || echo "$POS"
