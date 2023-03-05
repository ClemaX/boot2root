#!/usr/bin/env bash

set -euo pipefail

NODES=($((16#fd)) $((16#2d5)) $((16#12d)) $((16#3e5)) $((16#d4)) $((16#1b0)))

#echo "4 2 6 1 3 5"
#exit

for ((i=0; i<${#NODES[@]}; i+=1))
do
	echo "${NODES[$i]} $((i + 1))"
done \
| sort --numeric-sort --reverse | cut -d' ' -f2 \
| tr '\n' ' ' | sed 's/[[:space:]]\+$/\n/g'
