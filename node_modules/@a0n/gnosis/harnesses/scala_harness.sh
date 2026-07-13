#!/bin/sh
# Gnosis polyglot execution harness for Scala.
#
# Uses scala-cli or scalac to compile and run the target file.

set -e

REQUEST=$(cat)

if command -v python3 >/dev/null 2>&1; then
  FILE_PATH=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('filePath',''))")
  ACTION=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('action','execute'))")
else
  FILE_PATH=$(echo "$REQUEST" | grep -o '"filePath"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  ACTION=$(echo "$REQUEST" | grep -o '"action"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  ACTION=${ACTION:-execute}
fi

if [ "$ACTION" = "ping" ]; then
  printf '{"status":"ok","value":"pong","stdout":"","stderr":""}'
  exit 0
fi

TMPDIR="${TMPDIR:-/tmp}"
EXIT_CODE=0

# Try scala-cli first (modern), then scala (classic).
if command -v scala-cli >/dev/null 2>&1; then
  RUN_STDOUT=$(scala-cli run "$FILE_PATH" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
elif command -v scala >/dev/null 2>&1; then
  RUN_STDOUT=$(scala "$FILE_PATH" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
else
  printf '{"status":"error","value":"scala or scala-cli not found","stdout":"","stderr":""}'
  exit 0
fi

RUN_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
rm -f "$TMPDIR/gnode_stderr_$$"

if command -v python3 >/dev/null 2>&1; then
  python3 -c "
import json, sys
status = 'ok' if $EXIT_CODE == 0 else 'error'
stdout = sys.stdin.read()
try:
    value = json.loads(stdout)
except:
    value = stdout.strip()
json.dump({'status': status, 'value': value, 'stdout': stdout, 'stderr': '''$(echo "$RUN_STDERR" | sed "s/'/\\\\'/g")'''}, sys.stdout)
" <<< "$RUN_STDOUT"
else
  ESCAPED=$(printf '%s' "$RUN_STDOUT" | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
  STATUS="ok"
  [ "$EXIT_CODE" -ne 0 ] && STATUS="error"
  printf '{"status":"%s","value":"%s","stdout":"%s","stderr":""}' "$STATUS" "$ESCAPED" "$ESCAPED"
fi
