<?php

declare(strict_types=1);

final class GnosisResult {
    public function __construct(
        public int $exitCode,
        public string $stdout,
        public string $stderr,
    ) {
    }
}

final class GnosisClient {
    public function __construct(private string $binary = 'gnosis') {
        if ($this->binary === '') {
            $this->binary = 'gnosis';
        }
    }

    /** @param list<string> $args */
    public function run(array $args): GnosisResult {
        $command = array_merge([$this->binary], $args);

        $descriptorSpec = [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ];

        $process = proc_open($command, $descriptorSpec, $pipes);
        if (!is_resource($process)) {
            throw new RuntimeException('Failed to start gnosis process.');
        }

        fclose($pipes[0]);
        $stdout = stream_get_contents($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[1]);
        fclose($pipes[2]);

        $exitCode = proc_close($process);

        return new GnosisResult($exitCode, $stdout === false ? '' : $stdout, $stderr === false ? '' : $stderr);
    }

    public function lint(string $topologyPath, ?string $target = null, bool $asJson = false): GnosisResult {
        $args = ['lint', $topologyPath];
        if ($target !== null && $target !== '') {
            $args[] = '--target';
            $args[] = $target;
        }
        if ($asJson) {
            $args[] = '--json';
        }
        return $this->run($args);
    }

    public function analyze(string $targetPath, bool $asJson = false): GnosisResult {
        $args = ['analyze', $targetPath];
        if ($asJson) {
            $args[] = '--json';
        }
        return $this->run($args);
    }

    public function verify(string $topologyPath, ?string $tlaOut = null): GnosisResult {
        $args = ['verify', $topologyPath];
        if ($tlaOut !== null && $tlaOut !== '') {
            $args[] = '--tla-out';
            $args[] = $tlaOut;
        }
        return $this->run($args);
    }

    public function runTopology(string $topologyPath, bool $native = false): GnosisResult {
        $args = ['run', $topologyPath];
        if ($native) {
            $args[] = '--native';
        }
        return $this->run($args);
    }

    public function testTopology(string $testPath): GnosisResult {
        return $this->run(['test', $testPath]);
    }
}
