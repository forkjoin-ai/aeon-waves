#!/usr/bin/env php
<?php
/**
 * Gnosis polyglot execution harness for PHP.
 *
 * Protocol: reads JSON request from stdin, includes the target file,
 * calls the named function, writes JSON response to stdout.
 */

$raw_input = file_get_contents('php://stdin');
if (empty(trim($raw_input))) {
    echo json_encode(['status' => 'error', 'value' => 'empty input', 'stdout' => '', 'stderr' => '']);
    exit(0);
}

$request = json_decode($raw_input, true);
if ($request === null) {
    echo json_encode(['status' => 'error', 'value' => 'invalid JSON input', 'stdout' => '', 'stderr' => '']);
    exit(0);
}

if (($request['action'] ?? '') === 'ping') {
    echo json_encode(['status' => 'ok', 'value' => 'pong', 'stdout' => '', 'stderr' => '']);
    exit(0);
}

$file_path = $request['filePath'] ?? '';
$function_name = $request['functionName'] ?? 'main';
$args = $request['args'] ?? [];

// Capture output.
ob_start();

try {
    require_once $file_path;

    if (!function_exists($function_name)) {
        $stdout = ob_get_clean();
        echo json_encode([
            'status' => 'error',
            'value' => "Function '$function_name' not found in $file_path",
            'stdout' => $stdout,
            'stderr' => ''
        ]);
        exit(0);
    }

    $result = call_user_func_array($function_name, $args);
    $stdout = ob_get_clean();

    // Try to JSON-encode the result.
    $encoded = json_encode($result);
    if ($encoded === false) {
        $value = (string)$result;
    } else {
        $value = $result;
    }

    echo json_encode([
        'status' => 'ok',
        'value' => $value,
        'stdout' => $stdout,
        'stderr' => ''
    ]);

} catch (Throwable $e) {
    $stdout = ob_get_clean();
    echo json_encode([
        'status' => 'error',
        'value' => $e->getMessage() . "\n" . $e->getTraceAsString(),
        'stdout' => $stdout,
        'stderr' => ''
    ]);
}
