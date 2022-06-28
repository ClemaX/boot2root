# shellcheck shell=bash

set -euo pipefail

TARGET="${TARGET:-boot2root.vm}"
PMA_BASE="https://$TARGET/phpmyadmin"

pma_token() # pma_base cookie_file
{
	local pma_base="$1"

	curl --insecure "$pma_base/index.php" \
		-s \
		-b "$cookie_file" -c "$cookie_file" \
	| grep "token=" | head -n 1 \
	| sed 's/.*token=\([0-9a-fA-F]\+\).*/\1/g'
}

pma_login() # pma_base cookie_file user pass
{
	local pma_base="$1"
	local cookie_file="$2"
	local user="$3"
	local pass="$4"
	local token

	token=$(pma_token "$PMA_BASE" "$cookie_file")

	curl --insecure -X POST "https://$TARGET/phpmyadmin/index.php" \
		-s \
		-b "$cookie_file" -c "$cookie_file" \
		-H 'Content-Type: application/x-www-form-urlencoded' \
		--data-raw "pma_username=$user&pma_password=$pass&server=1&token=$token"
}
