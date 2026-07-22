import Foundation

public struct GnosisResult {
  public let exitCode: Int32
  public let stdout: String
  public let stderr: String
}

public final class GnosisClient {
  private let binary: String

  public init(binary: String = "gnosis") {
    self.binary = binary.isEmpty ? "gnosis" : binary
  }

  public func run(_ args: [String]) throws -> GnosisResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [binary] + args

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderr = String(data: stderrData, encoding: .utf8) ?? ""

    return GnosisResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
  }

  public func lint(topologyPath: String, target: String? = nil, asJSON: Bool = false) throws -> GnosisResult {
    var args = ["lint", topologyPath]
    if let targetValue = target, !targetValue.isEmpty {
      args += ["--target", targetValue]
    }
    if asJSON {
      args.append("--json")
    }
    return try run(args)
  }

  public func analyze(targetPath: String, asJSON: Bool = false) throws -> GnosisResult {
    var args = ["analyze", targetPath]
    if asJSON {
      args.append("--json")
    }
    return try run(args)
  }

  public func verify(topologyPath: String, tlaOut: String? = nil) throws -> GnosisResult {
    var args = ["verify", topologyPath]
    if let tlaOutValue = tlaOut, !tlaOutValue.isEmpty {
      args += ["--tla-out", tlaOutValue]
    }
    return try run(args)
  }

  public func runTopology(topologyPath: String, native: Bool = false) throws -> GnosisResult {
    var args = ["run", topologyPath]
    if native {
      args.append("--native")
    }
    return try run(args)
  }

  public func testTopology(testPath: String) throws -> GnosisResult {
    try run(["test", testPath])
  }
}
