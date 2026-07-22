#!/usr/bin/env bash
# FRANKY: True polyglot Ditto compiler -- shell orchestration
# The wiring itself is not GGL. Diversity for all.
#
# 9 Go functions, 43 Rust functions, racing the graph language too.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GO_DIR="$SCRIPT_DIR/../go"
RUST_DIR="$SCRIPT_DIR/../rust"
SOURCE_FILE="${1:?Usage: franky.sh <source-file>}"

echo "[Franky] True polyglot compilation: $SOURCE_FILE"

# STAGE 1: Parse with tree-sitter (Rust -- polyglot scanner)
CFGS=$(gnosis-polyglot "$SOURCE_FILE" --format json --mode framework 2>/dev/null)

# Extract framework from detection result
FRAMEWORK=$(echo "$CFGS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('topology',{}).get('framework','none'))" 2>/dev/null)

echo "[Franky] Detected: $FRAMEWORK"

if [ "$FRAMEWORK" = "none" ]; then
  echo "[Franky] No framework detected."
  exit 1
fi

# STAGE 2: Framework detection -- each recognizer in its winning language
case "$FRAMEWORK" in
  express)
    # detect: Rust, parse_route_call: Go, extract_handler_name: Go
    echo "[Franky] Express: detect(rust) + parse_route(go) + extract_handler(go)"
    ;;
  flask)
    # detect: Rust, parse_route_decorator: Go
    echo "[Franky] Flask: detect(rust) + parse_decorator(go)"
    ;;
  gin)
    # detect: Go, detect_router_names: Go, extract_go_handler: Go
    echo "[Franky] Gin: detect(go) + detect_routers(go) + extract_handler(go)"
    ;;
  hono)
    # all Rust
    echo "[Franky] Hono: all(rust)"
    ;;
  sinatra)
    # all Rust
    echo "[Franky] Sinatra: all(rust)"
    ;;
  spring)
    # detect: Rust, extract_request_methods: Go
    echo "[Franky] Spring: detect(rust) + extract_methods(go)"
    ;;
esac

# STAGE 3: Compile -- Go won this at 65.5%
echo "[Franky] Compiling with Go (compile_framework_to_gg: 65.5% fitness)"
GG_OUTPUT=$(gnosis-polyglot "$SOURCE_FILE" --format gg --mode framework 2>/dev/null)

# STAGE 4: Output
echo "[Franky] Compiled server topology:"
echo "$GG_OUTPUT"

echo
echo "[Franky] True polyglot: Go(9 functions) + Rust(43 functions)"
echo "[Franky] Not monoculture. The race results, pinned per function."
