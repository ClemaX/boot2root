#!/usr/bin/env bash

set -euo pipefail

pushd ft_fun > /dev/null
	if ! [ -e sorted ]
	then
		mkdir sorted

		for file in *.pcap
		do
			NUM=$(tail -n1 "$file" | sed 's/\/\/file//g')
			head -n -2 "$file" > "sorted/file$(printf '%03u' "$NUM")"
		done
	fi

	pushd sorted > /dev/null
		cat ./* | sed -e '/void useless()/d' -e '/Hahaha/d' # -e '/^\/\*/d' -e '/\*\/$/d'
	popd > /dev/null
popd > /dev/null
