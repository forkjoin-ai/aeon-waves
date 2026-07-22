#!/bin/sh
# Gnosis polyglot execution harness -- generic fallback.
#
# Protocol: reads JSON request from stdin, compiles and runs the target file,
# captures output, writes JSON response to stdout.
#
# Supports: C, C++, Rust, Java, and other compiled languages.
# For interpreted languages, use the language-specific harness instead.

set -e

# Read the full request from stdin.
REQUEST=$(cat)

# Parse fields using lightweight JSON extraction (no jq dependency).
# Uses python3 if available, otherwise falls back to basic parsing.
if command -v python3 >/dev/null 2>&1; then
  FILE_PATH=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('filePath',''))")
  FUNCTION_NAME=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('functionName','main'))")
  ACTION=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('action','execute'))")
  LANGUAGE=$(echo "$REQUEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('language',''))")
else
  # Fallback: basic grep extraction (fragile but functional).
  FILE_PATH=$(echo "$REQUEST" | grep -o '"filePath"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  FUNCTION_NAME=$(echo "$REQUEST" | grep -o '"functionName"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  ACTION=$(echo "$REQUEST" | grep -o '"action"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  LANGUAGE=$(echo "$REQUEST" | grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//;s/"$//')
  FUNCTION_NAME=${FUNCTION_NAME:-main}
  ACTION=${ACTION:-execute}
fi

# Ping action.
if [ "$ACTION" = "ping" ]; then
  printf '{"status":"ok","value":"pong","stdout":"","stderr":""}'
  exit 0
fi

# Determine file extension.
EXT="${FILE_PATH##*.}"
TMPDIR="${TMPDIR:-/tmp}"
BINARY="$TMPDIR/gnode_harness_$$"

COMPILE_STDERR=""
RUN_STDOUT=""
RUN_STDERR=""
EXIT_CODE=0

case "$EXT" in
  c)
    COMPILE_STDERR=$(cc -o "$BINARY" "$FILE_PATH" -lm 2>&1) || {
      printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
        "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
      exit 0
    }
    RUN_STDOUT=$("$BINARY" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
    RUN_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    rm -f "$BINARY" "$TMPDIR/gnode_stderr_$$"
    ;;
  cpp|cc|cxx)
    COMPILE_STDERR=$(c++ -std=c++17 -o "$BINARY" "$FILE_PATH" 2>&1) || {
      printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
        "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
      exit 0
    }
    RUN_STDOUT=$("$BINARY" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
    RUN_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    rm -f "$BINARY" "$TMPDIR/gnode_stderr_$$"
    ;;
  rs)
    COMPILE_STDERR=$(rustc -o "$BINARY" "$FILE_PATH" 2>&1) || {
      printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
        "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
      exit 0
    }
    RUN_STDOUT=$("$BINARY" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
    RUN_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    rm -f "$BINARY" "$TMPDIR/gnode_stderr_$$"
    ;;
  java)
    DIR=$(dirname "$FILE_PATH")
    CLASSNAME=$(basename "$FILE_PATH" .java)
    COMPILE_STDERR=$(javac -d "$TMPDIR" "$FILE_PATH" 2>&1) || {
      printf '{"status":"error","value":"compilation failed","stdout":"","stderr":"%s"}' \
        "$(echo "$COMPILE_STDERR" | sed 's/"/\\"/g' | tr '\n' ' ')"
      exit 0
    }
    RUN_STDOUT=$(java -cp "$TMPDIR" "$CLASSNAME" 2>"$TMPDIR/gnode_stderr_$$") || EXIT_CODE=$?
    RUN_STDERR=$(cat "$TMPDIR/gnode_stderr_$$" 2>/dev/null || true)
    rm -f "$TMPDIR/$CLASSNAME.class" "$TMPDIR/gnode_stderr_$$"
    ;;
  *)
    printf '{"status":"error","value":"unsupported file extension: .%s","stdout":"","stderr":""}' "$EXT"
    exit 0
    ;;
esac

# Escape for JSON output.
if command -v python3 >/dev/null 2>&1; then
  python3 -c "
import json, sys
status = 'ok' if $EXIT_CODE == 0 else 'error'
stdout = '''$RUN_STDOUT'''
stderr = '''$RUN_STDERR'''
# Try to parse stdout as JSON value.
try:
    value = json.loads(stdout)
except:
    value = stdout.strip()
json.dump({'status': status, 'value': value, 'stdout': stdout, 'stderr': stderr}, sys.stdout)
"
else
  # Minimal JSON output without python.
  STATUS="ok"
  if [ "$EXIT_CODE" -ne 0 ]; then
    STATUS="error"
  fi
  ESCAPED_STDOUT=$(printf '%s' "$RUN_STDOUT" | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
  ESCAPED_STDERR=$(printf '%s' "$RUN_STDERR" | sed 's/\\/\\\\/g;s/"/\\"/g' | tr '\n' ' ')
  printf '{"status":"%s","value":"%s","stdout":"%s","stderr":"%s"}' \
    "$STATUS" "$ESCAPED_STDOUT" "$ESCAPED_STDOUT" "$ESCAPED_STDERR"
fi
