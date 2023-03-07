#!/usr/bin/env bash

set -euo pipefail

sed \
	-e 's/Avance[[:space:]]\+\([[:digit:]]\+\)[[:space:]]\+spaces/forward \1/g' \
	-e 's/Recule[[:space:]]\+\([[:digit:]]\+\)[[:space:]]\+spaces/back \1/g' \
	-e 's/gauche/left/g' -e 's/droite/right/g' \
	-e 's/Tourne[[:space:]]\+\([[:alpha:]]\+\)[[:space:]]\+de[[:space:]]\+\([[:digit:]]\+\) degrees/turn \1 \2/g' \
	-e '/Can you digest the message/d'

