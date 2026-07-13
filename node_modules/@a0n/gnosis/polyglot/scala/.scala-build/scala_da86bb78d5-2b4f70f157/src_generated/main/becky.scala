
//> using scala 3.3

// becky.scala -- GG compiler in Scala.
// JVM JIT + HashMap. Functional style.

import scala.util.matching.Regex
import scala.collection.mutable

val EdgeRe = """(?s)\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\)""".r
val NodeRe = """\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\)""".r

case class GgNode(id: String, labels: List[String], properties: Map[String, String])
case class GgEdge(sourceIds: List[String], targetIds: List[String], edgeType: String, properties: Map[String, String])
case class GgProgram(nodes: mutable.Map[String, GgNode], edges: mutable.ListBuffer[GgEdge])

def stripComments(source: String): String =
  source.linesIterator.map(l => l.indexOf("//") match { case -1 => l.trim; case i => l.take(i).trim }).filter(_.nonEmpty).mkString("\n")

def parseProperties(raw: String): Map[String, String] =
  if raw == null || raw.isEmpty then Map.empty
  else raw.split(",").flatMap { seg =>
    seg.indexOf(':') match {
      case -1 => None
      case i =>
        val k = seg.take(i).trim; val v = seg.drop(i + 1).trim.stripPrefix("'").stripSuffix("'").stripPrefix("\"").stripSuffix("\"")
        if k.nonEmpty && v.nonEmpty then Some(k -> v) else None
    }
  }.toMap

def splitPipe(raw: String): List[String] =
  raw.split("\\|").toList.flatMap { p =>
    var s = p.trim.stripPrefix("(").stripSuffix(")")
    s.indexOf(':') match { case -1 => ; case i => s = s.take(i) }
    s.indexOf('{') match { case -1 => ; case i => s = s.take(i) }
    s = s.trim; if s.nonEmpty then Some(s) else None
  }

def parseGG(source: String): GgProgram =
  val cleaned = stripComments(source)
  val nodes = mutable.Map.empty[String, GgNode]
  val edges = mutable.ListBuffer.empty[GgEdge]

  for m <- EdgeRe.findAllMatchIn(cleaned) do
    val srcIds = splitPipe(m.group(1)); val tgtIds = splitPipe(m.group(4))
    val props = parseProperties(Option(m.group(3)).getOrElse(""))
    edges += GgEdge(srcIds, tgtIds, m.group(2).trim, props)
    (srcIds ++ tgtIds).foreach(id => nodes.getOrElseUpdate(id, GgNode(id, Nil, Map.empty)))

  for line <- cleaned.linesIterator if !line.contains("-[:") do
    for m <- NodeRe.findAllMatchIn(line) do
      val id = m.group(1).trim
      if id.nonEmpty && !id.contains("|") && !nodes.contains(id) then
        val label = Option(m.group(2)).map(_.trim).filter(_.nonEmpty).toList
        nodes(id) = GgNode(id, label, parseProperties(Option(m.group(3)).getOrElse("")))

  GgProgram(nodes, edges)

def computeBeta1(prog: GgProgram): Int =
  prog.edges.foldLeft(0) { (b1, e) =>
    val s = e.sourceIds.size; val t = e.targetIds.size
    e.edgeType match
      case "FORK" => b1 + t - 1
      case "FOLD" | "COLLAPSE" | "OBSERVE" => math.max(0, b1 - (s - 1))
      case "RACE" | "SLIVER" => math.max(0, b1 - math.max(0, s - t))
      case "VENT" => math.max(0, b1 - 1)
      case _ => b1
  }

def computeVoid(prog: GgProgram): Int = prog.edges.filter(_.edgeType == "FORK").map(_.targetIds.size).sum
def computeHeat(prog: GgProgram): Double = prog.edges.filter(e => Set("FOLD","COLLAPSE","OBSERVE")(e.edgeType) && e.sourceIds.size > 1).map(e => math.log(e.sourceIds.size) / math.log(2)).sum

@main def main(args: String*): Unit =
  var beta1Only = false; var summary = false; var benchIters = 0; var filepath: String = null
  var i = 0
  while i < args.size do
    args(i) match
      case "--beta1" => beta1Only = true
      case "--summary" => summary = true
      case "--bench" => i += 1; benchIters = args(i).toInt
      case s => filepath = s
    i += 1

  if filepath == null then { System.err.println("usage: scala becky.scala [--beta1|--summary|--bench N] <file.gg>"); sys.exit(1) }
  val source = scala.io.Source.fromFile(filepath).mkString

  if benchIters > 0 then
    (1 to 100).foreach(_ => parseGG(source))
    val start = System.nanoTime()
    (1 to benchIters).foreach(_ => parseGG(source))
    val us = (System.nanoTime() - start).toDouble / benchIters / 1000
    val p = parseGG(source)
    println(f"$us%.1fus/iter | $benchIters iterations | ${p.nodes.size} nodes ${p.edges.size} edges | b1=${computeBeta1(p)} | void=${computeVoid(p)} heat=${computeHeat(p)}%.3f")
    sys.exit(0)

  val p = parseGG(source); val b1 = computeBeta1(p)
  if beta1Only then println(b1)
  else if summary then println(s"$filepath: ${p.nodes.size} nodes, ${p.edges.size} edges, b1=$b1, void=${computeVoid(p)}, heat=${f"${computeHeat(p)}%.3f"}")
  else println(s"""{"nodes":${p.nodes.size},"edges":${p.edges.size},"beta1":$b1}""")
