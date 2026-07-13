// Becky.java -- GG compiler in Java.
// JVM JIT with HashMap. The enterprise answer.
// Build: javac Becky.java && java Becky betti.gg --bench 10000

import java.io.*;
import java.util.*;
import java.util.regex.*;

public class Becky {
    static final Pattern EDGE_RE = Pattern.compile(
        "\\(([^)]+)\\)\\s*-\\[:([A-Z]+)(?:\\s*\\{([^}]+)\\})?\\]->\\s*\\(([^)]+)\\)");
    static final Pattern NODE_RE = Pattern.compile(
        "\\(([^:)\\s|]+)(?:\\s*:\\s*([^){\\s]+))?(?:\\s*\\{([^}]+)\\})?\\)");

    record GgNode(String id, List<String> labels, Map<String,String> properties) {}
    record GgEdge(List<String> sourceIds, List<String> targetIds, String type, Map<String,String> properties) {}
    record GgProgram(Map<String,GgNode> nodes, List<GgEdge> edges) {}

    static String stripComments(String source) {
        var sb = new StringBuilder();
        for (var line : source.split("\n")) {
            int idx = line.indexOf("//");
            if (idx >= 0) line = line.substring(0, idx);
            line = line.trim();
            if (!line.isEmpty()) { if (sb.length() > 0) sb.append('\n'); sb.append(line); }
        }
        return sb.toString();
    }

    static Map<String,String> parseProperties(String raw) {
        var props = new HashMap<String,String>();
        if (raw == null || raw.isEmpty()) return props;
        for (var seg : raw.split(",")) {
            int idx = seg.indexOf(':');
            if (idx < 0) continue;
            var key = seg.substring(0, idx).trim();
            var val = seg.substring(idx + 1).trim().replaceAll("^['\"]|['\"]$", "");
            if (!key.isEmpty() && !val.isEmpty()) props.put(key, val);
        }
        return props;
    }

    static List<String> splitPipe(String raw) {
        var ids = new ArrayList<String>();
        for (var part : raw.split("\\|")) {
            var p = part.trim().replaceAll("^\\(|\\)$", "");
            int c = p.indexOf(':'); if (c >= 0) p = p.substring(0, c);
            int b = p.indexOf('{'); if (b >= 0) p = p.substring(0, b);
            p = p.trim();
            if (!p.isEmpty()) ids.add(p);
        }
        return ids;
    }

    static GgProgram parseGG(String source) {
        var cleaned = stripComments(source);
        var nodes = new HashMap<String,GgNode>();
        var edges = new ArrayList<GgEdge>();

        var m = EDGE_RE.matcher(cleaned);
        while (m.find()) {
            var srcIds = splitPipe(m.group(1));
            var tgtIds = splitPipe(m.group(4));
            var props = parseProperties(m.group(3));
            edges.add(new GgEdge(srcIds, tgtIds, m.group(2).trim(), props));
            for (var id : srcIds) nodes.putIfAbsent(id, new GgNode(id, new ArrayList<>(), new HashMap<>()));
            for (var id : tgtIds) nodes.putIfAbsent(id, new GgNode(id, new ArrayList<>(), new HashMap<>()));
        }

        for (var line : cleaned.split("\n")) {
            if (line.contains("-[:")) continue;
            var nm = NODE_RE.matcher(line);
            while (nm.find()) {
                var id = nm.group(1).trim();
                if (id.isEmpty() || id.contains("|")) continue;
                var label = nm.group(2) != null ? nm.group(2).trim() : "";
                var props = parseProperties(nm.group(3) != null ? nm.group(3).trim() : "");
                if (!nodes.containsKey(id)) {
                    var labels = new ArrayList<String>();
                    if (!label.isEmpty()) labels.add(label);
                    nodes.put(id, new GgNode(id, labels, props));
                }
            }
        }
        return new GgProgram(nodes, edges);
    }

    static int computeBeta1(GgProgram prog) {
        int b1 = 0;
        for (var e : prog.edges) {
            int s = e.sourceIds.size(), t = e.targetIds.size();
            switch (e.type) {
                case "FORK" -> b1 += t - 1;
                case "FOLD", "COLLAPSE", "OBSERVE" -> b1 = Math.max(0, b1 - (s - 1));
                case "RACE", "SLIVER" -> b1 = Math.max(0, b1 - Math.max(0, s - t));
                case "VENT" -> b1 = Math.max(0, b1 - 1);
            }
        }
        return b1;
    }

    static int computeVoidDims(GgProgram prog) {
        int d = 0;
        for (var e : prog.edges) if (e.type.equals("FORK")) d += e.targetIds.size();
        return d;
    }

    static double computeHeat(GgProgram prog) {
        double h = 0;
        for (var e : prog.edges)
            if ((e.type.equals("FOLD") || e.type.equals("COLLAPSE") || e.type.equals("OBSERVE")) && e.sourceIds.size() > 1)
                h += Math.log(e.sourceIds.size()) / Math.log(2);
        return h;
    }

    static int computeDeficit(GgProgram prog) {
        var out = new HashMap<String,Integer>();
        var in_ = new HashMap<String,Integer>();
        for (var e : prog.edges) {
            for (var s : e.sourceIds) out.merge(s, e.targetIds.size(), Integer::sum);
            for (var t : e.targetIds) in_.merge(t, e.sourceIds.size(), Integer::sum);
        }
        int total = 0;
        for (var id : prog.nodes.keySet()) total += Math.abs(out.getOrDefault(id, 0) - in_.getOrDefault(id, 0));
        return total;
    }

    public static void main(String[] args) throws Exception {
        boolean beta1Only = false, summary = false;
        int benchIters = 0;
        String filepath = null;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--beta1" -> beta1Only = true;
                case "--summary" -> summary = true;
                case "--bench" -> benchIters = Integer.parseInt(args[++i]);
                default -> filepath = args[i];
            }
        }
        if (filepath == null) { System.err.println("usage: java Becky [--beta1|--summary|--bench N] <file.gg>"); System.exit(1); }
        var source = new String(new FileInputStream(filepath).readAllBytes());

        if (benchIters > 0) {
            for (int i = 0; i < 100; i++) parseGG(source); // warmup JIT
            long start = System.nanoTime();
            for (int i = 0; i < benchIters; i++) parseGG(source);
            long elapsed = System.nanoTime() - start;
            double usPerIter = elapsed / (double) benchIters / 1000.0;
            var p = parseGG(source);
            System.out.printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f deficit=%d%n",
                usPerIter, benchIters, p.nodes.size(), p.edges.size(), computeBeta1(p),
                computeVoidDims(p), computeHeat(p), computeDeficit(p));
            return;
        }

        var p = parseGG(source);
        int b1 = computeBeta1(p);
        if (beta1Only) { System.out.println(b1); return; }
        if (summary) {
            System.out.printf("%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f, deficit=%d%n",
                filepath, p.nodes.size(), p.edges.size(), b1, computeVoidDims(p), computeHeat(p), computeDeficit(p));
            return;
        }
        System.out.printf("{\"nodes\":%d,\"edges\":%d,\"beta1\":%d}%n", p.nodes.size(), p.edges.size(), b1);
    }
}
