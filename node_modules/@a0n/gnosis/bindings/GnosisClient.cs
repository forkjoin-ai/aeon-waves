using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

public sealed record GnosisResult(int ExitCode, string Stdout, string Stderr);

public sealed class GnosisClient {
  private readonly string _binary;

  public GnosisClient(string? binary = null) {
    _binary = string.IsNullOrWhiteSpace(binary) ? "gnosis" : binary;
  }

  public async Task<GnosisResult> RunAsync(IEnumerable<string> args, CancellationToken cancellationToken = default) {
    var startInfo = new ProcessStartInfo {
      FileName = _binary,
      RedirectStandardOutput = true,
      RedirectStandardError = true,
      UseShellExecute = false,
    };

    foreach (var arg in args) {
      startInfo.ArgumentList.Add(arg);
    }

    using var process = Process.Start(startInfo) ?? throw new InvalidOperationException("Failed to start gnosis process.");

    Task<string> stdoutTask = process.StandardOutput.ReadToEndAsync();
    Task<string> stderrTask = process.StandardError.ReadToEndAsync();

    await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);

    string stdout = await stdoutTask.ConfigureAwait(false);
    string stderr = await stderrTask.ConfigureAwait(false);

    return new GnosisResult(process.ExitCode, stdout, stderr);
  }

  public Task<GnosisResult> LintAsync(string topologyPath, string? target = null, bool asJson = false, CancellationToken cancellationToken = default) {
    var args = new List<string> { "lint", topologyPath };
    if (!string.IsNullOrWhiteSpace(target)) {
      args.Add("--target");
      args.Add(target);
    }
    if (asJson) {
      args.Add("--json");
    }
    return RunAsync(args, cancellationToken);
  }

  public Task<GnosisResult> AnalyzeAsync(string targetPath, bool asJson = false, CancellationToken cancellationToken = default) {
    var args = new List<string> { "analyze", targetPath };
    if (asJson) {
      args.Add("--json");
    }
    return RunAsync(args, cancellationToken);
  }

  public Task<GnosisResult> VerifyAsync(string topologyPath, string? tlaOut = null, CancellationToken cancellationToken = default) {
    var args = new List<string> { "verify", topologyPath };
    if (!string.IsNullOrWhiteSpace(tlaOut)) {
      args.Add("--tla-out");
      args.Add(tlaOut);
    }
    return RunAsync(args, cancellationToken);
  }

  public Task<GnosisResult> RunTopologyAsync(string topologyPath, bool nativeRuntime = false, CancellationToken cancellationToken = default) {
    var args = new List<string> { "run", topologyPath };
    if (nativeRuntime) {
      args.Add("--native");
    }
    return RunAsync(args, cancellationToken);
  }

  public Task<GnosisResult> TestTopologyAsync(string testPath, CancellationToken cancellationToken = default) {
    return RunAsync(new[] { "test", testPath }, cancellationToken);
  }
}
