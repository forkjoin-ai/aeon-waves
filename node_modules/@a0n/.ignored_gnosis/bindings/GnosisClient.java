import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

public final class GnosisClient {
  public record GnosisResult(int exitCode, String stdout, String stderr) {}

  private final String binary;

  public GnosisClient() {
    this("gnosis");
  }

  public GnosisClient(String binary) {
    if (binary == null || binary.isBlank()) {
      this.binary = "gnosis";
    } else {
      this.binary = binary;
    }
  }

  public GnosisResult run(List<String> args) throws IOException, InterruptedException {
    List<String> command = new ArrayList<>();
    command.add(binary);
    command.addAll(args);

    Process process = new ProcessBuilder(command).start();
    byte[] stdoutBytes = process.getInputStream().readAllBytes();
    byte[] stderrBytes = process.getErrorStream().readAllBytes();
    int exitCode = process.waitFor();

    return new GnosisResult(
        exitCode,
        new String(stdoutBytes, StandardCharsets.UTF_8),
        new String(stderrBytes, StandardCharsets.UTF_8));
  }

  public GnosisResult lint(String topologyPath, String target, boolean asJson)
      throws IOException, InterruptedException {
    List<String> args = new ArrayList<>();
    args.add("lint");
    args.add(topologyPath);
    if (target != null && !target.isBlank()) {
      args.add("--target");
      args.add(target);
    }
    if (asJson) {
      args.add("--json");
    }
    return run(args);
  }

  public GnosisResult analyze(String targetPath, boolean asJson)
      throws IOException, InterruptedException {
    List<String> args = new ArrayList<>();
    args.add("analyze");
    args.add(targetPath);
    if (asJson) {
      args.add("--json");
    }
    return run(args);
  }

  public GnosisResult verify(String topologyPath, String tlaOut)
      throws IOException, InterruptedException {
    List<String> args = new ArrayList<>();
    args.add("verify");
    args.add(topologyPath);
    if (tlaOut != null && !tlaOut.isBlank()) {
      args.add("--tla-out");
      args.add(tlaOut);
    }
    return run(args);
  }

  public GnosisResult runTopology(String topologyPath, boolean nativeRuntime)
      throws IOException, InterruptedException {
    List<String> args = new ArrayList<>();
    args.add("run");
    args.add(topologyPath);
    if (nativeRuntime) {
      args.add("--native");
    }
    return run(args);
  }

  public GnosisResult testTopology(String testPath) throws IOException, InterruptedException {
    return run(List.of("test", testPath));
  }
}
