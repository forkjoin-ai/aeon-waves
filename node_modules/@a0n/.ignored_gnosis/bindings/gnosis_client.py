from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable
import subprocess


@dataclass(frozen=True)
class GnosisResult:
    exit_code: int
    stdout: str
    stderr: str


class GnosisClient:
    def __init__(self, binary: str = "gnosis") -> None:
        self._binary = binary

    def run(self, args: Iterable[str]) -> GnosisResult:
        completed = subprocess.run(
            [self._binary, *args],
            capture_output=True,
            text=True,
            check=False,
        )
        return GnosisResult(
            exit_code=completed.returncode,
            stdout=completed.stdout,
            stderr=completed.stderr,
        )

    def lint(self, topology_path: str, target: str | None = None, as_json: bool = False) -> GnosisResult:
        args = ["lint", topology_path]
        if target:
            args.extend(["--target", target])
        if as_json:
            args.append("--json")
        return self.run(args)

    def analyze(self, target_path: str, as_json: bool = False) -> GnosisResult:
        args = ["analyze", target_path]
        if as_json:
            args.append("--json")
        return self.run(args)

    def verify(self, topology_path: str, tla_out: str | None = None) -> GnosisResult:
        args = ["verify", topology_path]
        if tla_out:
            args.extend(["--tla-out", tla_out])
        return self.run(args)

    def run_topology(self, topology_path: str, native: bool = False) -> GnosisResult:
        args = ["run", topology_path]
        if native:
            args.append("--native")
        return self.run(args)

    def test_topology(self, topology_path: str) -> GnosisResult:
        return self.run(["test", topology_path])
