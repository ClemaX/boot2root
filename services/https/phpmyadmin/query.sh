#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR=.

source "$SCRIPTDIR/login.sh"

COOKIES="$1.cookies"

pma_query() # pma_base cookie_file query
{
    local pma_base="$1"
    local cookie_file="$2"
    local query="$3"
    local token

    token=$(pma_token "$pma_base" "$cookie_file")

    curl --insecure -X POST "$PMA_BASE/import.php" \
        -s \
        -b "$COOKIES" -c "$COOKIES" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H 'X-Requested-With: XMLHttpRequest' \
        --data-urlencode "is_js_confirmed=0" \
        --data-urlencode "token=$token" \
        --data-urlencode "pos=0" \
        --data-urlencode "goto=server_sql.php" \
        --data-urlencode "message_to_show=Your SQL query has been executed successfully" \
        --data-urlencode "prev_sql_query=" \
        --data-urlencode "sql_query=$query" \
        --data-urlencode "bkm_label=" \
        --data-urlencode "sql_delimiter=;" \
        --data-urlencode "show_query=1" \
        --data-urlencode "id_bookmark=" \
        --data-urlencode "bookmark_variable=" \
        --data-urlencode "action_bookmark=0" \
        --data-urlencode "ajax_request=true"
}

query_prompt() # dest_var
{
    local dest_var="$1"
    local PS1="mysql> "
    local PS2="  ...> "

    declare -n dest_var

    [ -t 0 ] && echo -n "$PS1" >&2

    read dest_var

    #dest_var="${dest_var//+/%2B}"
    #dest_var="${dest_var// /+}"

    return "$?"
}

pma_login "$PMA_BASE" "$COOKIES" "$1" "$2"

QUERY=

while query_prompt QUERY
do
    RESPONSE=$(pma_query "$PMA_BASE" "$COOKIES" "$QUERY")
    jq '.message//.error | capture("<[^>]+>(?<content>[^<]+)<[^>]+>") | .content' 2>/dev/null <<< "$RESPONSE" || echo "$RESPONSE"
done
