#!/usr/bin/env ruby
# becky.rb -- GG compiler in Ruby.
# Hash is Ruby's hash map. Same two-sweep architecture.

EDGE_RE = /\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)/
NODE_RE = /\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)/

def strip_comments(source)
  source.lines.map { |l| l.sub(%r{//.*}, '').strip }.reject(&:empty?).join("\n")
end

def parse_properties(raw)
  return {} unless raw && !raw.empty?
  raw.split(',').each_with_object({}) do |seg, h|
    k, v = seg.split(':', 2).map(&:strip)
    h[k] = v.gsub(/^['"]|['"]$/, '') if k && v && !k.empty? && !v.empty?
  end
end

def split_pipe(raw)
  raw.split('|').map { |p| p.strip.gsub(/^[(\s]+|[)\s]+$/, '').split(/[:{\s]/).first&.strip }.compact.reject(&:empty?)
end

def parse_gg(source)
  cleaned = strip_comments(source)
  nodes = {}
  edges = []

  cleaned.scan(EDGE_RE) do |src, type, props, tgt|
    s_ids = split_pipe(src)
    t_ids = split_pipe(tgt)
    edges << { sourceIds: s_ids, targetIds: t_ids, type: type.strip, properties: parse_properties(props) }
    (s_ids + t_ids).each { |id| nodes[id] ||= { id: id, labels: [], properties: {} } }
  end

  cleaned.each_line do |line|
    next if line.include?('-[:')
    line.scan(NODE_RE) do |id, label, props|
      id = id.strip
      next if id.empty? || id.include?('|')
      unless nodes[id]
        labels = label && !label.strip.empty? ? [label.strip] : []
        nodes[id] = { id: id, labels: labels, properties: parse_properties(props) }
      end
    end
  end

  { nodes: nodes, edges: edges }
end

def compute_beta1(prog)
  b1 = 0
  prog[:edges].each do |e|
    s, t = e[:sourceIds].size, e[:targetIds].size
    case e[:type]
    when 'FORK' then b1 += t - 1
    when 'FOLD', 'COLLAPSE', 'OBSERVE' then b1 = [0, b1 - (s - 1)].max
    when 'RACE', 'SLIVER' then b1 = [0, b1 - [0, s - t].max].max
    when 'VENT' then b1 = [0, b1 - 1].max
    end
  end
  b1
end

def compute_void(prog)
  prog[:edges].select { |e| e[:type] == 'FORK' }.sum { |e| e[:targetIds].size }
end
def compute_heat(prog)
  prog[:edges].select { |e| %w[FOLD COLLAPSE OBSERVE].include?(e[:type]) && e[:sourceIds].size > 1 }.sum { |e| Math.log2(e[:sourceIds].size) }
end
def compute_deficit(prog)
  out_b, in_m = Hash.new(0), Hash.new(0)
  prog[:edges].each { |e| e[:sourceIds].each { |s| out_b[s] += e[:targetIds].size }; e[:targetIds].each { |t| in_m[t] += e[:sourceIds].size } }
  prog[:nodes].keys.sum { |id| (out_b[id] - in_m[id]).abs }
end

# CLI
beta1_only = ARGV.delete('--beta1')
summary = ARGV.delete('--summary')
bench_idx = ARGV.index('--bench')
bench_iters = bench_idx ? ARGV.delete_at(bench_idx) && ARGV.delete_at(bench_idx).to_i : 0
filepath = ARGV.first
abort "usage: ruby becky.rb [--beta1|--summary|--bench N] <file.gg>" unless filepath

source = File.read(filepath)

if bench_iters > 0
  10.times { parse_gg(source) }
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  bench_iters.times { parse_gg(source) }
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  us = elapsed * 1e6 / bench_iters
  p = parse_gg(source)
  puts "%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f deficit=%d" %
    [us, bench_iters, p[:nodes].size, p[:edges].size, compute_beta1(p), compute_void(p), compute_heat(p), compute_deficit(p)]
  exit
end

p = parse_gg(source)
b1 = compute_beta1(p)
if beta1_only
  puts b1
elsif summary
  puts "%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f, deficit=%d" %
    [filepath, p[:nodes].size, p[:edges].size, b1, compute_void(p), compute_heat(p), compute_deficit(p)]
else
  puts '{"nodes":%d,"edges":%d,"beta1":%d}' % [p[:nodes].size, p[:edges].size, b1]
end
