// becky.zig -- GG compiler in Zig.
//
// The "C but with hash maps" answer. No hidden allocations.
// AutoHashMap for O(1) node lookup. Same two-sweep architecture.
//
// Build: zig build-exe -OReleaseFast becky.zig
// Usage: ./becky betti.gg --summary

const std = @import("std");
const Allocator = std.mem.Allocator;

const MAX_ID = 128;

const GgNode = struct {
    id: []const u8,
    label: []const u8,
    prop_count: usize,
};

const GgEdge = struct {
    source_ids: std.ArrayList([]const u8),
    target_ids: std.ArrayList([]const u8),
    edge_type: []const u8,
};

const GgProgram = struct {
    nodes: std.StringHashMap(GgNode),
    edges: std.ArrayList(GgEdge),

    fn init(alloc: Allocator) GgProgram {
        return .{
            .nodes = std.StringHashMap(GgNode).init(alloc),
            .edges = std.ArrayList(GgEdge).init(alloc),
        };
    }

    fn deinit(self: *GgProgram) void {
        self.nodes.deinit();
        self.edges.deinit();
    }
};

fn stripComments(alloc: Allocator, source: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(alloc);
    var lines = std.mem.splitScalar(u8, source, '\n');
    var first = true;
    while (lines.next()) |line| {
        var trimmed = std.mem.trim(u8, line, " \t\r");
        // Strip // comments
        if (std.mem.indexOf(u8, trimmed, "//")) |idx| {
            trimmed = std.mem.trim(u8, trimmed[0..idx], " \t\r");
        }
        if (trimmed.len == 0) continue;
        if (!first) try result.append('\n');
        try result.appendSlice(trimmed);
        first = false;
    }
    return result.toOwnedSlice();
}

fn splitPipe(alloc: Allocator, raw: []const u8) !std.ArrayList([]const u8) {
    var ids = std.ArrayList([]const u8).init(alloc);
    var parts = std.mem.splitScalar(u8, raw, '|');
    while (parts.next()) |part| {
        var trimmed = std.mem.trim(u8, part, " \t\r()");
        // Take ID before : or {
        if (std.mem.indexOfScalar(u8, trimmed, ':')) |idx| {
            trimmed = std.mem.trim(u8, trimmed[0..idx], " \t\r");
        }
        if (std.mem.indexOfScalar(u8, trimmed, '{')) |idx| {
            trimmed = std.mem.trim(u8, trimmed[0..idx], " \t\r");
        }
        if (trimmed.len > 0) {
            try ids.append(trimmed);
        }
    }
    return ids;
}

fn parseGG(alloc: Allocator, source: []const u8) !GgProgram {
    const cleaned = try stripComments(alloc, source);
    var prog = GgProgram.init(alloc);

    // Sweep 1: edges -- find )-[: pattern
    var i: usize = 0;
    while (i + 4 < cleaned.len) : (i += 1) {
        if (cleaned[i] == ')' and cleaned[i + 1] == '-' and cleaned[i + 2] == '[' and cleaned[i + 3] == ':') {
            // Backtrack for source (
            var src_start = i;
            var depth: i32 = 0;
            var j = i;
            while (j > 0) {
                j -= 1;
                if (cleaned[j] == ')') {
                    depth += 1;
                } else if (cleaned[j] == '(') {
                    if (depth == 0) {
                        src_start = j + 1;
                        break;
                    }
                    depth -= 1;
                }
            }

            const source_raw = cleaned[src_start..i];

            // Find ] after [:TYPE...
            const bracket_start = i + 3;
            const bracket_end_opt = std.mem.indexOfScalar(u8, cleaned[bracket_start..], ']');
            if (bracket_end_opt == null) continue;
            const bracket_end = bracket_start + bracket_end_opt.?;

            var rel = cleaned[bracket_start..bracket_end];
            // Strip leading :
            if (rel.len > 0 and rel[0] == ':') rel = rel[1..];
            // Extract type (before {)
            var edge_type = rel;
            if (std.mem.indexOfScalar(u8, rel, '{')) |brace| {
                edge_type = std.mem.trim(u8, rel[0..brace], " \t\r");
            } else {
                edge_type = std.mem.trim(u8, rel, " \t\r");
            }

            // Find ->(...) after ]
            const arrow_start = bracket_end + 1;
            if (arrow_start + 2 >= cleaned.len) continue;
            if (cleaned[arrow_start] != '-' or cleaned[arrow_start + 1] != '>') continue;

            const after_arrow = arrow_start + 2;
            const tgt_open_opt = std.mem.indexOfScalar(u8, cleaned[after_arrow..], '(');
            if (tgt_open_opt == null) continue;
            const tgt_open = after_arrow + tgt_open_opt.?;

            depth = 0;
            var tgt_close = tgt_open;
            for (cleaned[tgt_open..], tgt_open..) |ch, k| {
                if (ch == '(') {
                    depth += 1;
                } else if (ch == ')') {
                    depth -= 1;
                    if (depth == 0) {
                        tgt_close = k;
                        break;
                    }
                }
            }

            const target_raw = cleaned[tgt_open + 1 .. tgt_close];

            var source_ids = try splitPipe(alloc, source_raw);
            var target_ids = try splitPipe(alloc, target_raw);

            // Ensure nodes
            for (source_ids.items) |id| {
                if (!prog.nodes.contains(id)) {
                    try prog.nodes.put(id, .{ .id = id, .label = "", .prop_count = 0 });
                }
            }
            for (target_ids.items) |id| {
                if (!prog.nodes.contains(id)) {
                    try prog.nodes.put(id, .{ .id = id, .label = "", .prop_count = 0 });
                }
            }

            try prog.edges.append(.{
                .source_ids = source_ids,
                .target_ids = target_ids,
                .edge_type = edge_type,
            });

            i = tgt_close;
        }
    }

    // Sweep 2: standalone nodes (lines without edges)
    var lines = std.mem.splitScalar(u8, cleaned, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "-[:") != null) continue;
        var k: usize = 0;
        while (k < line.len) {
            if (line[k] == '(') {
                const start = k + 1;
                var depth2: i32 = 1;
                var end = start;
                while (end < line.len and depth2 > 0) : (end += 1) {
                    if (line[end] == '(') depth2 += 1;
                    if (line[end] == ')') depth2 -= 1;
                }
                if (depth2 == 0 and end > start) {
                    const inner = line[start .. end - 1];
                    if (std.mem.indexOfScalar(u8, inner, '|') == null) {
                        // Extract id (before : or {)
                        var id = inner;
                        if (std.mem.indexOfScalar(u8, inner, '{')) |brace| {
                            id = inner[0..brace];
                        }
                        var label: []const u8 = "";
                        if (std.mem.indexOfScalar(u8, id, ':')) |colon| {
                            label = std.mem.trim(u8, id[colon + 1 ..], " \t\r");
                            id = id[0..colon];
                        }
                        id = std.mem.trim(u8, id, " \t\r");
                        if (id.len > 0 and !prog.nodes.contains(id)) {
                            try prog.nodes.put(id, .{ .id = id, .label = label, .prop_count = 0 });
                        }
                    }
                    k = end;
                } else {
                    k += 1;
                }
            } else {
                k += 1;
            }
        }
    }

    return prog;
}

fn computeBeta1(prog: *const GgProgram) i64 {
    var b1: i64 = 0;
    for (prog.edges.items) |edge| {
        const sources: i64 = @intCast(edge.source_ids.items.len);
        const targets: i64 = @intCast(edge.target_ids.items.len);
        if (std.mem.eql(u8, edge.edge_type, "FORK")) {
            b1 += targets - 1;
        } else if (std.mem.eql(u8, edge.edge_type, "FOLD") or std.mem.eql(u8, edge.edge_type, "COLLAPSE") or std.mem.eql(u8, edge.edge_type, "OBSERVE")) {
            b1 = @max(0, b1 - (sources - 1));
        } else if (std.mem.eql(u8, edge.edge_type, "RACE") or std.mem.eql(u8, edge.edge_type, "SLIVER")) {
            b1 = @max(0, b1 - @max(0, sources - targets));
        } else if (std.mem.eql(u8, edge.edge_type, "VENT")) {
            b1 = @max(0, b1 - 1);
        }
    }
    return b1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    var filepath: ?[]const u8 = null;
    var summary = false;
    var beta1_only = false;
    var bench_iters: usize = 0;

    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        if (std.mem.eql(u8, args[arg_i], "--summary")) {
            summary = true;
        } else if (std.mem.eql(u8, args[arg_i], "--beta1")) {
            beta1_only = true;
        } else if (std.mem.eql(u8, args[arg_i], "--bench")) {
            arg_i += 1;
            if (arg_i < args.len) bench_iters = try std.fmt.parseInt(usize, args[arg_i], 10);
        } else {
            filepath = args[arg_i];
        }
    }

    if (filepath == null) {
        std.debug.print("usage: becky-zig [--beta1|--summary|--bench N] <file.gg>\n", .{});
        return;
    }

    const source = try std.fs.cwd().readFileAlloc(alloc, filepath.?, 10 * 1024 * 1024);
    defer alloc.free(source);

    const stdout = std.io.getStdOut().writer();

    if (bench_iters > 0) {
        // Warmup
        for (0..10) |_| {
            var p = try parseGG(alloc, source);
            p.deinit();
        }
        const start = std.time.nanoTimestamp();
        for (0..bench_iters) |_| {
            var p = try parseGG(alloc, source);
            p.deinit();
        }
        const end = std.time.nanoTimestamp();
        const ns_per_iter = @divFloor(end - start, @as(i128, bench_iters));
        const us_per_iter = @as(f64, @floatFromInt(ns_per_iter)) / 1000.0;

        var prog = try parseGG(alloc, source);
        defer prog.deinit();
        const b1 = computeBeta1(&prog);
        try stdout.print("{d:.1}us/iter | {d} iterations | {d} nodes {d} edges | b1={d}\n", .{ us_per_iter, bench_iters, prog.nodes.count(), prog.edges.items.len, b1 });
        return;
    }

    var prog = try parseGG(alloc, source);
    defer prog.deinit();
    const b1 = computeBeta1(&prog);

    if (beta1_only) {
        try stdout.print("{d}\n", .{b1});
    } else if (summary) {
        try stdout.print("{s}: {d} nodes, {d} edges, b1={d}\n", .{ filepath.?, prog.nodes.count(), prog.edges.items.len, b1 });
    } else {
        try stdout.print("{{\"nodes\":{d},\"edges\":{d},\"beta1\":{d}}}\n", .{ prog.nodes.count(), prog.edges.items.len, b1 });
    }
}
