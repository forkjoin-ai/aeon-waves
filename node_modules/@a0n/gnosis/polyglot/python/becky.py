#!/usr/bin/env python3
"""
becky.py -- GG compiler in Python.

Same two-sweep architecture. Dict for O(1) node lookup.
re module for regex. The question: can CPython's dict beat V8's Map?

Usage:
    python3 becky.py betti.gg
    python3 becky.py --beta1 betti.gg
    python3 becky.py --summary betti.gg
    python3 becky.py --bench 100000 betti.gg
"""

import re
import sys
import json
import math
import time

EDGE_RE = re.compile(r'\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)')
NODE_RE = re.compile(r'\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)')


def strip_comments(source):
    lines = []
    for line in source.split('\n'):
        idx = line.find('//')
        if idx >= 0:
            line = line[:idx]
        line = line.strip()
        if line:
            lines.append(line)
    return '\n'.join(lines)


def parse_properties(raw):
    props = {}
    if not raw:
        return props
    for segment in raw.split(','):
        segment = segment.strip()
        idx = segment.find(':')
        if idx < 0:
            continue
        key = segment[:idx].strip()
        value = segment[idx + 1:].strip().strip("'\"")
        if key and value:
            props[key] = value
    return props


def split_pipe(raw):
    ids = []
    for part in raw.split('|'):
        part = part.strip().strip('()')
        idx = part.find(':')
        if idx >= 0:
            part = part[:idx]
        idx = part.find('{')
        if idx >= 0:
            part = part[:idx]
        part = part.strip()
        if part:
            ids.append(part)
    return ids


def parse_gg(source):
    cleaned = strip_comments(source)
    nodes = {}
    edges = []

    # Sweep 1: edges
    for m in EDGE_RE.finditer(cleaned):
        source_raw = m.group(1).strip()
        edge_type = m.group(2).strip()
        props_raw = (m.group(3) or '').strip()
        target_raw = m.group(4).strip()

        source_ids = split_pipe(source_raw)
        target_ids = split_pipe(target_raw)

        edges.append({
            'sourceIds': source_ids,
            'targetIds': target_ids,
            'type': edge_type,
            'properties': parse_properties(props_raw),
        })

        for nid in source_ids + target_ids:
            if nid not in nodes:
                nodes[nid] = {'id': nid, 'labels': [], 'properties': {}}

    # Sweep 2: standalone nodes
    for line in cleaned.split('\n'):
        if '-[:' in line:
            continue
        for m in NODE_RE.finditer(line):
            nid = m.group(1).strip()
            if not nid or '|' in nid:
                continue
            label = (m.group(2) or '').strip()
            props = parse_properties((m.group(3) or '').strip())
            if nid not in nodes:
                nodes[nid] = {'id': nid, 'labels': [label] if label else [], 'properties': props}
            else:
                if label and not nodes[nid]['labels']:
                    nodes[nid]['labels'] = [label]
                nodes[nid]['properties'].update(props)

    return {'nodes': nodes, 'edges': edges}


def compute_beta1(prog):
    b1 = 0
    for edge in prog['edges']:
        sources = len(edge['sourceIds'])
        targets = len(edge['targetIds'])
        t = edge['type']
        if t == 'FORK':
            b1 += targets - 1
        elif t in ('FOLD', 'COLLAPSE', 'OBSERVE'):
            b1 = max(0, b1 - (sources - 1))
        elif t in ('RACE', 'SLIVER'):
            b1 = max(0, b1 - max(0, sources - targets))
        elif t == 'VENT':
            b1 = max(0, b1 - 1)
    return b1


def compute_void_dimensions(prog):
    return sum(len(e['targetIds']) for e in prog['edges'] if e['type'] == 'FORK')


def compute_landauer_heat(prog):
    heat = 0.0
    for e in prog['edges']:
        if e['type'] in ('FOLD', 'COLLAPSE', 'OBSERVE') and len(e['sourceIds']) > 1:
            heat += math.log2(len(e['sourceIds']))
    return heat


def compute_deficit(prog):
    out_b = {}
    in_m = {}
    for e in prog['edges']:
        for s in e['sourceIds']:
            out_b[s] = out_b.get(s, 0) + len(e['targetIds'])
        for t in e['targetIds']:
            in_m[t] = in_m.get(t, 0) + len(e['sourceIds'])
    total = 0
    for nid in prog['nodes']:
        total += abs(out_b.get(nid, 0) - in_m.get(nid, 0))
    return total


def compile_gg(source):
    prog = parse_gg(source)
    return {
        'program': prog,
        'beta1': compute_beta1(prog),
        'void_dimensions': compute_void_dimensions(prog),
        'landauer_heat': compute_landauer_heat(prog),
        'total_deficit': compute_deficit(prog),
    }


def main():
    args = sys.argv[1:]
    beta1_only = '--beta1' in args
    summary = '--summary' in args
    bench_iters = 0

    filepath = None
    i = 0
    while i < len(args):
        if args[i] == '--bench' and i + 1 < len(args):
            bench_iters = int(args[i + 1])
            i += 2
            continue
        if not args[i].startswith('--'):
            filepath = args[i]
        i += 1

    if not filepath:
        print('usage: becky.py [--beta1|--summary|--bench N] <file.gg>', file=sys.stderr)
        sys.exit(1)

    with open(filepath) as f:
        source = f.read()

    if bench_iters > 0:
        # Warmup
        for _ in range(10):
            compile_gg(source)
        start = time.monotonic_ns()
        for _ in range(bench_iters):
            compile_gg(source)
        elapsed_ns = time.monotonic_ns() - start
        us_per_iter = elapsed_ns / bench_iters / 1000
        r = compile_gg(source)
        p = r['program']
        print(f"{us_per_iter:.1f}us/iter | {bench_iters} iterations | "
              f"{len(p['nodes'])} nodes {len(p['edges'])} edges | "
              f"b1={r['beta1']} | void={r['void_dimensions']} "
              f"heat={r['landauer_heat']:.3f} deficit={r['total_deficit']}")
        return

    r = compile_gg(source)
    p = r['program']

    if beta1_only:
        print(r['beta1'])
    elif summary:
        print(f"{filepath}: {len(p['nodes'])} nodes, {len(p['edges'])} edges, "
              f"b1={r['beta1']}, void={r['void_dimensions']}, "
              f"heat={r['landauer_heat']:.3f}, deficit={r['total_deficit']}")
    else:
        print(json.dumps({
            'nodes': len(p['nodes']),
            'edges': len(p['edges']),
            'beta1': r['beta1'],
            'void_dimensions': r['void_dimensions'],
            'landauer_heat': r['landauer_heat'],
            'total_deficit': r['total_deficit'],
        }, indent=2))


if __name__ == '__main__':
    main()
