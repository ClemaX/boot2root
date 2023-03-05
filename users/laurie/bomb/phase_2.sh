#!/usr/bin/env bash

set -euo pipefail

NUMS=()

NUMS+=(1)

for i in {2..6}
do
	NUMS+=($((i * NUMS[i - 2])))
done

echo "${NUMS[@]}"
