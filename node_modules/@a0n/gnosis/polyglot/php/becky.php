#!/usr/bin/env php
<?php
// becky.php -- GG compiler in PHP.
// Associative arrays are hash maps. Web server native.

function strip_comments($source) {
    $lines = [];
    foreach (explode("\n", $source) as $line) {
        $idx = strpos($line, '//');
        if ($idx !== false) $line = substr($line, 0, $idx);
        $line = trim($line);
        if ($line !== '') $lines[] = $line;
    }
    return implode("\n", $lines);
}

function parse_properties($raw) {
    $props = [];
    if (!$raw) return $props;
    foreach (explode(',', $raw) as $seg) {
        $parts = explode(':', $seg, 2);
        if (count($parts) < 2) continue;
        $key = trim($parts[0]);
        $val = trim(trim($parts[1]), "'\"");
        if ($key && $val) $props[$key] = $val;
    }
    return $props;
}

function split_pipe($raw) {
    $ids = [];
    foreach (explode('|', $raw) as $part) {
        $part = trim($part, " \t()");
        $c = strpos($part, ':'); if ($c !== false) $part = substr($part, 0, $c);
        $b = strpos($part, '{'); if ($b !== false) $part = substr($part, 0, $b);
        $part = trim($part);
        if ($part) $ids[] = $part;
    }
    return $ids;
}

function parse_gg($source) {
    $cleaned = strip_comments($source);
    $nodes = [];
    $edges = [];

    preg_match_all('/\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)/', $cleaned, $matches, PREG_SET_ORDER);
    foreach ($matches as $m) {
        $src_ids = split_pipe($m[1]);
        $tgt_ids = split_pipe($m[4]);
        $edges[] = ['sourceIds' => $src_ids, 'targetIds' => $tgt_ids, 'type' => trim($m[2]), 'properties' => parse_properties($m[3] ?? '')];
        foreach (array_merge($src_ids, $tgt_ids) as $id) {
            if (!isset($nodes[$id])) $nodes[$id] = ['id' => $id, 'labels' => [], 'properties' => []];
        }
    }

    foreach (explode("\n", $cleaned) as $line) {
        if (strpos($line, '-[:') !== false) continue;
        preg_match_all('/\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)/', $line, $matches, PREG_SET_ORDER);
        foreach ($matches as $m) {
            $id = trim($m[1]);
            if (!$id || strpos($id, '|') !== false) continue;
            if (!isset($nodes[$id])) {
                $label = isset($m[2]) ? trim($m[2]) : '';
                $nodes[$id] = ['id' => $id, 'labels' => $label ? [$label] : [], 'properties' => parse_properties($m[3] ?? '')];
            }
        }
    }

    return ['nodes' => $nodes, 'edges' => $edges];
}

function compute_beta1($prog) {
    $b1 = 0;
    foreach ($prog['edges'] as $e) {
        $s = count($e['sourceIds']); $t = count($e['targetIds']);
        switch ($e['type']) {
            case 'FORK': $b1 += $t - 1; break;
            case 'FOLD': case 'COLLAPSE': case 'OBSERVE': $b1 = max(0, $b1 - ($s - 1)); break;
            case 'RACE': case 'SLIVER': $b1 = max(0, $b1 - max(0, $s - $t)); break;
            case 'VENT': $b1 = max(0, $b1 - 1); break;
        }
    }
    return $b1;
}

function compute_void($prog) {
    $d = 0;
    foreach ($prog['edges'] as $e) if ($e['type'] === 'FORK') $d += count($e['targetIds']);
    return $d;
}

function compute_heat($prog) {
    $h = 0.0;
    foreach ($prog['edges'] as $e)
        if (in_array($e['type'], ['FOLD','COLLAPSE','OBSERVE']) && count($e['sourceIds']) > 1)
            $h += log(count($e['sourceIds']), 2);
    return $h;
}

// CLI
$args = array_slice($argv, 1);
$beta1_only = in_array('--beta1', $args);
$summary = in_array('--summary', $args);
$bench_iters = 0;
$filepath = null;

for ($i = 0; $i < count($args); $i++) {
    if ($args[$i] === '--bench' && $i + 1 < count($args)) { $bench_iters = (int)$args[++$i]; continue; }
    if ($args[$i][0] !== '-') $filepath = $args[$i];
}

if (!$filepath) { fwrite(STDERR, "usage: php becky.php [--beta1|--summary|--bench N] <file.gg>\n"); exit(1); }
$source = file_get_contents($filepath);

if ($bench_iters > 0) {
    for ($i = 0; $i < 10; $i++) parse_gg($source);
    $start = hrtime(true);
    for ($i = 0; $i < $bench_iters; $i++) parse_gg($source);
    $elapsed = hrtime(true) - $start;
    $us = $elapsed / $bench_iters / 1000;
    $p = parse_gg($source);
    printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f\n",
        $us, $bench_iters, count($p['nodes']), count($p['edges']), compute_beta1($p), compute_void($p), compute_heat($p));
    exit;
}

$p = parse_gg($source);
$b1 = compute_beta1($p);
if ($beta1_only) { echo "$b1\n"; exit; }
if ($summary) { printf("%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f\n",
    $filepath, count($p['nodes']), count($p['edges']), $b1, compute_void($p), compute_heat($p)); exit; }
printf("{\"nodes\":%d,\"edges\":%d,\"beta1\":%d}\n", count($p['nodes']), count($p['edges']), $b1);
