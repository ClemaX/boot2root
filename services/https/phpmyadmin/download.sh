#!/usr/bin/env bash

set -euo pipefail

FILE="$3"

DB_NAME=files
TABLE_NAME=$(basename "$FILE")

DOWNLOAD_DIR=files
DUMP_DIR=dumps

DUMP_FILE=files.sqlite

USER="$1"
PASS="$2"

FILE="$3"

./query.sh "$USER" "$PASS" > /dev/null << EOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`; USE \`$DB_NAME\`; DROP TABLE IF EXISTS \`$TABLE_NAME\`; CREATE TABLE \`$TABLE_NAME\` (\`data\` varchar(4096) CHARACTER SET utf8 NOT NULL DEFAULT ''); LOAD DATA INFILE '$FILE' INTO TABLE \`$TABLE_NAME\`;
EOF

[ -f "$DUMP_DIR/$DUMP_FILE" ] && rm "$DUMP_DIR/$DUMP_FILE"

./dump.sh "$USER" "$PASS" "$DB_NAME" \
| ../../../utils/mysql2sqlite.sh \
| sqlite3 "$DUMP_DIR/$DUMP_FILE"

if [ -t 1 ] && pushd "$DOWNLOAD_DIR" > /dev/null
then
	mkdir -p "./$(dirname "$FILE")"
	exec >"./$FILE"
	popd > /dev/null || exit 1
fi

sqlite3 "$DUMP_DIR/$DUMP_FILE" <<< "SELECT data FROM \`$TABLE_NAME\`;"
