#!/usr/bin/env swift
// becky.swift -- GG compiler in Swift.
// Dictionary for O(1) lookup. ARC not GC. Apple ecosystem.
// Run: swift becky.swift betti.gg --summary

import Foundation

let EDGE_RE = try! NSRegularExpression(pattern: #"\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)"#)
let NODE_RE = try! NSRegularExpression(pattern: #"\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)"#)

struct GgNode { var id: String; var labels: [String]; var properties: [String: String] }
struct GgEdge { var sourceIds: [String]; var targetIds: [String]; var type: String; var properties: [String: String] }
struct GgProgram { var nodes: [String: GgNode]; var edges: [GgEdge] }

func stripComments(_ source: String) -> String {
    source.split(separator: "\n").compactMap { line -> String? in
        var l = String(line)
        if let idx = l.range(of: "//") { l = String(l[..<idx.lowerBound]) }
        let trimmed = l.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }.joined(separator: "\n")
}

func parseProperties(_ raw: String?) -> [String: String] {
    guard let raw = raw, !raw.isEmpty else { return [:] }
    var props: [String: String] = [:]
    for seg in raw.split(separator: ",") {
        let parts = seg.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { continue }
        let key = parts[0].trimmingCharacters(in: .whitespaces)
        var val = parts[1].trimmingCharacters(in: .whitespaces)
        val = val.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        if !key.isEmpty && !val.isEmpty { props[key] = val }
    }
    return props
}

func splitPipe(_ raw: String) -> [String] {
    raw.split(separator: "|").compactMap { part -> String? in
        var p = part.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        if let idx = p.firstIndex(of: ":") { p = String(p[..<idx]) }
        if let idx = p.firstIndex(of: "{") { p = String(p[..<idx]) }
        p = p.trimmingCharacters(in: .whitespaces)
        return p.isEmpty ? nil : p
    }
}

func match(_ regex: NSRegularExpression, _ string: String, _ group: Int) -> String? {
    nil // placeholder for iteration
}

func parseGG(_ source: String) -> GgProgram {
    let cleaned = stripComments(source)
    var nodes: [String: GgNode] = [:]
    var edges: [GgEdge] = []
    let nsRange = NSRange(cleaned.startIndex..., in: cleaned)

    // Sweep 1: edges
    for m in EDGE_RE.matches(in: cleaned, range: nsRange) {
        func g(_ i: Int) -> String? {
            let r = m.range(at: i)
            guard r.location != NSNotFound else { return nil }
            return String(cleaned[Range(r, in: cleaned)!])
        }
        let srcIds = splitPipe(g(1) ?? "")
        let tgtIds = splitPipe(g(4) ?? "")
        let props = parseProperties(g(3))
        edges.append(GgEdge(sourceIds: srcIds, targetIds: tgtIds, type: (g(2) ?? "").trimmingCharacters(in: .whitespaces), properties: props))
        for id in srcIds { if nodes[id] == nil { nodes[id] = GgNode(id: id, labels: [], properties: [:]) } }
        for id in tgtIds { if nodes[id] == nil { nodes[id] = GgNode(id: id, labels: [], properties: [:]) } }
    }

    // Sweep 2: standalone nodes
    for line in cleaned.split(separator: "\n") {
        let lineStr = String(line)
        if lineStr.contains("-[:") { continue }
        let lineRange = NSRange(lineStr.startIndex..., in: lineStr)
        for m in NODE_RE.matches(in: lineStr, range: lineRange) {
            func g(_ i: Int) -> String? {
                let r = m.range(at: i)
                guard r.location != NSNotFound else { return nil }
                return String(lineStr[Range(r, in: lineStr)!])
            }
            let id = (g(1) ?? "").trimmingCharacters(in: .whitespaces)
            if id.isEmpty || id.contains("|") { continue }
            if nodes[id] == nil {
                let label = (g(2) ?? "").trimmingCharacters(in: .whitespaces)
                let labels = label.isEmpty ? [String]() : [label]
                nodes[id] = GgNode(id: id, labels: labels, properties: parseProperties(g(3)))
            }
        }
    }
    return GgProgram(nodes: nodes, edges: edges)
}

func computeBeta1(_ prog: GgProgram) -> Int {
    var b1 = 0
    for e in prog.edges {
        let s = e.sourceIds.count, t = e.targetIds.count
        switch e.type {
        case "FORK": b1 += t - 1
        case "FOLD", "COLLAPSE", "OBSERVE": b1 = max(0, b1 - (s - 1))
        case "RACE", "SLIVER": b1 = max(0, b1 - max(0, s - t))
        case "VENT": b1 = max(0, b1 - 1)
        default: break
        }
    }
    return b1
}

func computeVoid(_ prog: GgProgram) -> Int { prog.edges.filter { $0.type == "FORK" }.reduce(0) { $0 + $1.targetIds.count } }
func computeHeat(_ prog: GgProgram) -> Double { prog.edges.filter { ["FOLD","COLLAPSE","OBSERVE"].contains($0.type) && $0.sourceIds.count > 1 }.reduce(0.0) { $0 + log2(Double($1.sourceIds.count)) } }

// CLI
var args = CommandLine.arguments.dropFirst()
var beta1Only = false, summary = false, benchIters = 0
var filepath: String? = nil
var i = args.startIndex
while i < args.endIndex {
    switch args[i] {
    case "--beta1": beta1Only = true
    case "--summary": summary = true
    case "--bench": i = args.index(after: i); benchIters = Int(args[i]) ?? 0
    default: filepath = args[i]
    }
    i = args.index(after: i)
}
guard let fp = filepath else { fputs("usage: swift becky.swift [--beta1|--summary|--bench N] <file.gg>\n", stderr); exit(1) }
let source = try! String(contentsOfFile: fp, encoding: .utf8)

if benchIters > 0 {
    for _ in 0..<100 { _ = parseGG(source) }
    let start = DispatchTime.now()
    for _ in 0..<benchIters { _ = parseGG(source) }
    let ns = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
    let us = Double(ns) / Double(benchIters) / 1000.0
    let p = parseGG(source)
    print(String(format: "%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f",
        us, benchIters, p.nodes.count, p.edges.count, computeBeta1(p), computeVoid(p), computeHeat(p)))
    exit(0)
}

let p = parseGG(source)
let b1 = computeBeta1(p)
if beta1Only { print(b1) }
else if summary { print("\(fp): \(p.nodes.count) nodes, \(p.edges.count) edges, b1=\(b1), void=\(computeVoid(p)), heat=\(String(format: "%.3f", computeHeat(p)))") }
else { print("{\"nodes\":\(p.nodes.count),\"edges\":\(p.edges.count),\"beta1\":\(b1)}") }
