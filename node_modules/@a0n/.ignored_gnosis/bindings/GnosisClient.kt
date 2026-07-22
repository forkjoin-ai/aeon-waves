data class GnosisResult(
  val exitCode: Int,
  val stdout: String,
  val stderr: String,
)

class GnosisClient(binary: String = "gnosis") {
  private val executable: String = if (binary.isBlank()) "gnosis" else binary

  fun run(args: List<String>): GnosisResult {
    val command = mutableListOf(executable)
    command.addAll(args)

    val process = ProcessBuilder(command).start()
    val stdout = process.inputStream.bufferedReader().use { it.readText() }
    val stderr = process.errorStream.bufferedReader().use { it.readText() }
    val exitCode = process.waitFor()

    return GnosisResult(exitCode = exitCode, stdout = stdout, stderr = stderr)
  }

  fun lint(topologyPath: String, target: String? = null, asJson: Boolean = false): GnosisResult {
    val args = mutableListOf("lint", topologyPath)
    if (!target.isNullOrBlank()) {
      args += listOf("--target", target)
    }
    if (asJson) {
      args += "--json"
    }
    return run(args)
  }

  fun analyze(targetPath: String, asJson: Boolean = false): GnosisResult {
    val args = mutableListOf("analyze", targetPath)
    if (asJson) {
      args += "--json"
    }
    return run(args)
  }

  fun verify(topologyPath: String, tlaOut: String? = null): GnosisResult {
    val args = mutableListOf("verify", topologyPath)
    if (!tlaOut.isNullOrBlank()) {
      args += listOf("--tla-out", tlaOut)
    }
    return run(args)
  }

  fun runTopology(topologyPath: String, native: Boolean = false): GnosisResult {
    val args = mutableListOf("run", topologyPath)
    if (native) {
      args += "--native"
    }
    return run(args)
  }

  fun testTopology(testPath: String): GnosisResult {
    return run(listOf("test", testPath))
  }
}
