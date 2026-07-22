#!/usr/bin/env kotlin
// becky.kts -- GG compiler in Kotlin.
// JVM JIT + HashMap. Kotlin script (no compile step).

import java.io.File

val EDGE_RE = Regex("""\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)""")
val NODE_RE = Regex("""\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)""")

data class GgNode(val id: String, val labels: MutableList<String>, val properties: MutableMap<String, String>)
data class GgEdge(val sourceIds: List<String>, val targetIds: List<String>, val type: String, val properties: Map<String, String>)
data class GgProgram(val nodes: MutableMap<String, GgNode>, val edges: MutableList<GgEdge>)

fun stripComments(source: String) = source.lines()
    .map { it.substringBefore("//").trim() }
    .filter { it.isNotEmpty() }
    .joinToString("\n")

fun parseProperties(raw: String?): Map<String, String> {
    if (raw.isNullOrBlank()) return emptyMap()
    return raw.split(",").mapNotNull { seg ->
        val idx = seg.indexOf(':')
        if (idx < 0) null
        else seg.substring(0, idx).trim() to seg.substring(idx + 1).trim().trim('\'', '"')
    }.filter { it.first.isNotEmpty() && it.second.isNotEmpty() }.toMap()
}

fun splitPipe(raw: String): List<String> = raw.split("|").mapNotNull { p ->
    var s = p.trim().trimStart('(').trimEnd(')')
    s.indexOf(':').let { if (it >= 0) s = s.substring(0, it) }
    s.indexOf('{').let { if (it >= 0) s = s.substring(0, it) }
    s = s.trim()
    if (s.isNotEmpty()) s else null
}

fun parseGG(source: String): GgProgram {
    val cleaned = stripComments(source)
    val nodes = mutableMapOf<String, GgNode>()
    val edges = mutableListOf<GgEdge>()

    for (m in EDGE_RE.findAll(cleaned)) {
        val srcIds = splitPipe(m.groupValues[1])
        val tgtIds = splitPipe(m.groupValues[4])
        edges.add(GgEdge(srcIds, tgtIds, m.groupValues[2].trim(), parseProperties(m.groupValues[3])))
        (srcIds + tgtIds).forEach { id -> nodes.putIfAbsent(id, GgNode(id, mutableListOf(), mutableMapOf())) }
    }

    for (line in cleaned.lines()) {
        if ("-[:" in line) continue
        for (m in NODE_RE.findAll(line)) {
            val id = m.groupValues[1].trim()
            if (id.isEmpty() || '|' in id) continue
            if (id !in nodes) {
                val label = m.groupValues[2].trim()
                nodes[id] = GgNode(id, if (label.isNotEmpty()) mutableListOf(label) else mutableListOf(), parseProperties(m.groupValues[3]).toMutableMap())
            }
        }
    }
    return GgProgram(nodes, edges)
}

fun computeBeta1(prog: GgProgram): Int {
    var b1 = 0
    for (e in prog.edges) {
        val s = e.sourceIds.size; val t = e.targetIds.size
        when (e.type) {
            "FORK" -> b1 += t - 1
            "FOLD", "COLLAPSE", "OBSERVE" -> b1 = maxOf(0, b1 - (s - 1))
            "RACE", "SLIVER" -> b1 = maxOf(0, b1 - maxOf(0, s - t))
            "VENT" -> b1 = maxOf(0, b1 - 1)
        }
    }
    return b1
}

fun computeVoid(prog: GgProgram) = prog.edges.filter { it.type == "FORK" }.sumOf { it.targetIds.size }
fun computeHeat(prog: GgProgram) = prog.edges.filter { it.type in listOf("FOLD", "COLLAPSE", "OBSERVE") && it.sourceIds.size > 1 }.sumOf { Math.log(it.sourceIds.size.toDouble()) / Math.log(2.0) }

// CLI
var beta1Only = false; var summary = false; var benchIters = 0; var filepath: String? = null
val cliArgs = args.toMutableList()
var i = 0
while (i < cliArgs.size) {
    when (cliArgs[i]) {
        "--beta1" -> beta1Only = true
        "--summary" -> summary = true
        "--bench" -> { i++; benchIters = cliArgs[i].toInt() }
        else -> filepath = cliArgs[i]
    }
    i++
}
if (filepath == null) { System.err.println("usage: kotlin becky.kts [--beta1|--summary|--bench N] <file.gg>"); kotlin.system.exitProcess(1) }
val source = File(filepath!!).readText()

if (benchIters > 0) {
    repeat(100) { parseGG(source) }
    val start = System.nanoTime()
    repeat(benchIters) { parseGG(source) }
    val us = (System.nanoTime() - start).toDouble() / benchIters / 1000
    val p = parseGG(source)
    println("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f".format(us, benchIters, p.nodes.size, p.edges.size, computeBeta1(p), computeVoid(p), computeHeat(p)))
    kotlin.system.exitProcess(0)
}

val p = parseGG(source); val b1 = computeBeta1(p)
if (beta1Only) println(b1)
else if (summary) println("$filepath: ${p.nodes.size} nodes, ${p.edges.size} edges, b1=$b1, void=${computeVoid(p)}, heat=${"%.3f".format(computeHeat(p))}")
else println("""{"nodes":${p.nodes.size},"edges":${p.edges.size},"beta1":$b1}""")
