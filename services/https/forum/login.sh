#!/usr/bin/env bash

TARGET=boot2root.vm
SUCCESS_CODE=302

if [ $# -lt 2 ]
then
	echo "Usage: $0 username password"
fi

USER="$1"
PASS="$2"

COOKIE_FILE="$USER.cookies"

CODE=$(curl --insecure -X POST "https://$TARGET/forum/index.php" \
	-o /dev/null -s -w '%{http_code}\n' \
	-b "$COOKIE_FILE" -c "$COOKIE_FILE" \
	--data-raw "mode=login&username=$USER&userpw=$PASS")

if [ "$CODE" -ne "$SUCCESS_CODE" ]
then
	rm -f "$COOKIE_FILE"
	exit 1
else
	exit 0
fi
