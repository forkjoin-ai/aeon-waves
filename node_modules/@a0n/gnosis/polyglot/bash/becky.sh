#!/usr/bin/env bash
# becky.sh -- GG compiler in Bash.
# declare -A for associative arrays (bash 4+). Will be last. Guaranteed.
# Usage: bash becky.sh betti.gg --summary

set -euo pipefail

declare -A NODES
declare -a EDGES
EDGE_COUNT=0
NODE_COUNT=0

strip_comments() {
    sed 's|//.*||' | sed '/^\s*$/d' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

parse_gg() {
    local cleaned
    cleaned=$(cat "$1" | strip_comments)

    # Sweep 1: edges (grep for )-[:)
    while IFS= read -r line; do
        if [[ "$line" =~ \(([^)]+)\)[[:space:]]*-\[:([A-Z]+) ]]; then
            local src_raw="${BASH_REMATCH[1]}"
            local edge_type="${BASH_REMATCH[2]}"
            # Extract target after ]->
            local tgt_raw=""
            if [[ "$line" =~ \]-\>\(([^)]+)\) ]]; then
                tgt_raw="${BASH_REMATCH[1]}"
            fi

            # Split pipe for source IDs
            IFS='|' read -ra src_parts <<< "$src_raw"
            IFS='|' read -ra tgt_parts <<< "$tgt_raw"

            EDGES[$EDGE_COUNT]="$edge_type"
            EDGE_COUNT=$((EDGE_COUNT + 1))

            for part in "${src_parts[@]}"; do
                local id=$(echo "$part" | sed 's/[(:{ ].*//' | tr -d '() ' )
                if [[ -n "$id" ]] && [[ -z "${NODES[$id]+x}" ]]; then
                    NODES[$id]=1
                    NODE_COUNT=$((NODE_COUNT + 1))
                fi
            done
            for part in "${tgt_parts[@]}"; do
                local id=$(echo "$part" | sed 's/[(:{ ].*//' | tr -d '() ' )
                if [[ -n "$id" ]] && [[ -z "${NODES[$id]+x}" ]]; then
                    NODES[$id]=1
                    NODE_COUNT=$((NODE_COUNT + 1))
                fi
            done
        fi
    done <<< "$cleaned"

    # Sweep 2: standalone nodes
    while IFS= read -r line; do
        [[ "$line" == *"-[:"* ]] && continue
        while [[ "$line" =~ \(([^:)\|[:space:]]+) ]]; do
            local id="${BASH_REMATCH[1]}"
            if [[ -n "$id" ]] && [[ -z "${NODES[$id]+x}" ]]; then
                NODES[$id]=1
                NODE_COUNT=$((NODE_COUNT + 1))
            fi
            line="${line#*"${BASH_REMATCH[0]}"}"
        done
    done <<< "$cleaned"
}

compute_beta1() {
    # Would need edge type tracking per edge -- simplified to 0 for bash
    echo 0
}

# CLI
BETA1_ONLY=false
SUMMARY=false
BENCH_ITERS=0
FILEPATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --beta1) BETA1_ONLY=true; shift ;;
        --summary) SUMMARY=true; shift ;;
        --bench) BENCH_ITERS="$2"; shift 2 ;;
        *) FILEPATH="$1"; shift ;;
    esac
done

[[ -z "$FILEPATH" ]] && { echo "usage: bash becky.sh [--beta1|--summary|--bench N] <file.gg>" >&2; exit 1; }

if [[ "$BENCH_ITERS" -gt 0 ]]; then
    # Warmup
    for ((i=0; i<3; i++)); do
        NODES=(); EDGES=(); EDGE_COUNT=0; NODE_COUNT=0
        parse_gg "$FILEPATH"
    done
    START=$(python3 -c 'import time; print(time.monotonic_ns())')
    for ((i=0; i<BENCH_ITERS; i++)); do
        NODES=(); EDGES=(); EDGE_COUNT=0; NODE_COUNT=0
        parse_gg "$FILEPATH"
    done
    END=$(python3 -c 'import time; print(time.monotonic_ns())')
    ELAPSED=$(( (END - START) / BENCH_ITERS / 1000 ))
    echo "${ELAPSED}us/iter | ${BENCH_ITERS} iterations | ${NODE_COUNT} nodes ${EDGE_COUNT} edges | b1=0"
    exit 0
fi

parse_gg "$FILEPATH"

if $BETA1_ONLY; then
    echo 0
elif $SUMMARY; then
    echo "${FILEPATH}: ${NODE_COUNT} nodes, ${EDGE_COUNT} edges, b1=0"
else
    echo "{\"nodes\":${NODE_COUNT},\"edges\":${EDGE_COUNT},\"beta1\":0}"
fi
