#!/bin/sh
# Gnosis polyglot execution harness for C#.
#
# Uses `dotnet-script` for .csx files, or `dotnet run` for .cs in a project.
# Falls back to `csc` + mono/direct execution.

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

EXT="${FILE_PATH##*.}"

if [ "$EXT" = "csx" ] && command -v dotnet-script >/dev/null 2>&1; then
  RUN_STDOUT=$(dotnet-script "$FILE_PATH" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
elif command -v dotnet >/dev/null 2>&1; then
  # Create a temporary project.
  PROJDIR="$TMPDIR/gnode_cs_$$"
  mkdir -p "$PROJDIR"
  dotnet new console -o "$PROJDIR" --force >/dev/null 2>&1
  cp "$FILE_PATH" "$PROJDIR/Program.cs"
  RUN_STDOUT=$(dotnet run --project "$PROJDIR" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
  rm -rf "$PROJDIR"
elif command -v csc >/dev/null 2>&1; then
  BINARY="$TMPDIR/gnode_cs_$$.exe"
  csc -out:"$BINARY" "$FILE_PATH" 2>"$TMPDIR/gnode_stderr_$$" || {
    COMPILE_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
      "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
    rm -f "$TMPDIR/gnode_stderr_$$"
    exit 0
  }
  if command -v mono >/dev/null 2>&1; then
    RUN_STDOUT=$(mono "$BINARY" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
  else
    RUN_STDOUT=$("$BINARY" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
  fi
  rm -f "$BINARY"
else
  printf '{"status":"error","value":"dotnet/csc not found","stdout":"","stderr":""}'
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
