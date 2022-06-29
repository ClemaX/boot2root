#!/usr/bin/env bash

set -euo pipefail

[ -e ft_fun ] || tar xf fun.tar

./filter.sh \
| grep 'return' \
| sed 's/.*'\''\(.\)'\''.*/\1/g' \
| tr -d '\n' \
| sha256sum \
| sed -e 's/^/laurie:/g' -e 's/  -//g'
