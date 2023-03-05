#!/usr/bin/env bash

set -euo pipefail

for phase in ./phase_*.sh
do
	source "$phase"
done
