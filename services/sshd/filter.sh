#!/usr/bin/env bash

FILTERS=()

[ $# -eq 0 ] && set -- login logout success failure sudo

for arg in "$@"
do
	case "$arg"
	in
		login	)	FILTERS+=(-e 's/.*session opened for user \([^[:space:]]*\) by \([^[:space:]]*\)/login:'$'\t\t''\1@\2/g');;
		logout	)	FILTERS+=(-e 's/.*session closed for user \([^[:space:]]*\)/logout:'$'\t\t''\1/g');;
		success	)	FILTERS+=(-e 's/.*Accepted password for \([^[:space:]]*\) from \([^[:space:]]*\) port \([^[:space:]]*\).*/success:'$'\t''\1@\2:\3/g');;
		failure	)	FILTERS+=(-e 's/.*Failed password for invalid user \([^[:space:]]*\) from \([^[:space:]]*\) port \([^[:space:]]*\) .*/failure: '$'\t''\1@\2:\3/g');;
		sudo	)	FILTERS+=(-e 's/.*sudo: \([^[:space:]]*\) : TTY=\([^[:space:]]*\) ; PWD=\([^[:space:]]*\) ; USER=\([^[:space:]]*\) ; COMMAND=\([^[:space:]]*\)/sudo:'$'\t\t''\1@\2 as \4 in \3 \5/g');;
		*		)	echo "Invalid filter!" >&2; exit 1;;
	esac
	shift
done

sed \
	"${FILTERS[@]}" \
	-e '/sshd\[[0-9]*\]/d' \
	-e '/ sudo/d' \
	-e '/CRON\[[0-9]*\]/d'
