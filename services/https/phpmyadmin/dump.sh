#!/usr/bin/env bash

SCRIPTDIR=.

source "$SCRIPTDIR/login.sh"

pma_dump() # pma_base cookie_file db_name
{
	local pma_base="$1"
	local cookie_file="$2"
	local db_name="$3"
	local filename_temp="@SERVER@"
	local compression=none
	local token

	token=$(pma_token "$pma_base")

	curl --insecure -X POST "$pma_base/export.php" \
		-s \
		-b "$cookie_file" -c "$cookie_file" \
		--data-urlencode "token=$token" \
		--data-urlencode "export_type=server" \
		--data-urlencode "export_method=quick" \
		--data-urlencode "quick_or_custom=custom" \
		--data-urlencode "db_select%5B%5D=$db_name" \
		--data-urlencode "output_format=sendit" \
		--data-urlencode "filename_template=$filename_temp" \
		--data-urlencode "remember_template=on" \
		--data-urlencode "charset_of_file=utf-8" \
		--data-urlencode "compression=$compression" \
		--data-urlencode "what=sql" \
		--data-urlencode "sql_include_comments=something" \
		--data-urlencode "sql_header_comment=" \
		--data-urlencode "sql_compatibility=NONE" \
		--data-urlencode "sql_structure_or_data=structure_and_data" \
		--data-urlencode "sql_procedure_function=something" \
		--data-urlencode "sql_create_table_statements=something" \
		--data-urlencode "sql_if_not_exists=something" \
		--data-urlencode "sql_auto_increment=something" \
		--data-urlencode "sql_backquotes=something" \
		--data-urlencode "sql_type=INSERT" \
		--data-urlencode "sql_insert_syntax=both" \
		--data-urlencode "sql_max_query_size=50000" \
		--data-urlencode "sql_hex_for_blob=something" \
		--data-urlencode "sql_utc_time=something"
}

pma_login "$PMA_BASE" "$1.cookies" "$1" "$2"
pma_dump "$PMA_BASE" "$1.cookies" "${3:-phpmyadmin}"
