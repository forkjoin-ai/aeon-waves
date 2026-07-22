#!/bin/sh
# Gnosis polyglot execution harness for Kotlin.
#
# Uses kotlinc to compile and run the target file.
# Falls back to kotlin scripting mode for .kts files.

set -e

REQUEST=$(cat)

if command -v python3 >/dev/null 2>&1; then
  FILE_PATH=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('filePath',''))")
  FUNCTION_NAME=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('functionName','main'))")
  ACTION=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('action','execute'))")
else
  FILE_PATH=$(echo "$REQUEST" | grep -o '"filePath"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  FUNCTION_NAME=$(echo "$REQUEST" | grep -o '"functionName"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  ACTION=$(echo "$REQUEST" | grep -o '"action"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  FUNCTION_NAME=${FUNCTION_NAME:-main}
  ACTION=${ACTION:-execute}
fi

if [ "$ACTION" = "ping" ]; then
  printf '{"status":"ok","value":"pong","stdout":"","stderr":""}'
  exit 0
fi

TMPDIR="${TMPDIR:-/tmp}"
EXT="${FILE_PATH##*.}"

if [ "$EXT" = "kts" ]; then
  # Kotlin script mode.
  RUN_STDOUT=$(kotlin "$FILE_PATH" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
else
  # Compile and run.
  JARFILE="$TMPDIR/gnode_kotlin_$$.jar"
  kotlinc "$FILE_PATH" -include-runtime -d "$JARFILE" 2>"$TMPDIR/gnode_stderr_$$" || {
    COMPILE_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
      "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
    rm -f "$TMPDIR/gnode_stderr_$$"
    exit 0
  }
  RUN_STDOUT=$(java -jar "$JARFILE" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
  rm -f "$JARFILE"
fi

EXIT_CODE=${EXIT_CODE:-0}
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
