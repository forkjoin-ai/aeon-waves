# frozen_string_literal: true

require 'open3'

GnosisResult = Struct.new(:exit_code, :stdout, :stderr, keyword_init: true)

class GnosisClient
  def initialize(binary = 'gnosis')
    @binary = binary.to_s.empty? ? 'gnosis' : binary
  end

  def run(args)
    stdout, stderr, status = Open3.capture3(@binary, *args)
    GnosisResult.new(exit_code: status.exitstatus, stdout: stdout, stderr: stderr)
  end

  def lint(topology_path, target: nil, as_json: false)
    args = ['lint', topology_path]
    args += ['--target', target] if target && !target.empty?
    args << '--json' if as_json
    run(args)
  end

  def analyze(target_path, as_json: false)
    args = ['analyze', target_path]
    args << '--json' if as_json
    run(args)
  end

  def verify(topology_path, tla_out: nil)
    args = ['verify', topology_path]
    args += ['--tla-out', tla_out] if tla_out && !tla_out.empty?
    run(args)
  end

  def run_topology(topology_path, native: false)
    args = ['run', topology_path]
    args << '--native' if native
    run(args)
  end

  def test_topology(test_path)
    run(['test', test_path])
  end
end
