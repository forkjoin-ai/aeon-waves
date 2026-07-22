// becky.cpp -- GG compiler in C++.
// The "C with std::unordered_map" answer. Should smoke pure C.
// Build: c++ -O3 -std=c++20 -o becky-cpp becky.cpp

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <regex>
#include <cmath>
#include <chrono>
#include <cstring>

struct GgNode {
    std::string id;
    std::vector<std::string> labels;
    std::unordered_map<std::string, std::string> properties;
};

struct GgEdge {
    std::vector<std::string> source_ids;
    std::vector<std::string> target_ids;
    std::string edge_type;
    std::unordered_map<std::string, std::string> properties;
};

struct GgProgram {
    std::unordered_map<std::string, GgNode> nodes;
    std::vector<GgEdge> edges;
};

static std::string strip_comments(const std::string& source) {
    std::string result;
    std::istringstream stream(source);
    std::string line;
    bool first = true;
    while (std::getline(stream, line)) {
        auto idx = line.find("//");
        if (idx != std::string::npos) line = line.substr(0, idx);
        // Trim
        auto start = line.find_first_not_of(" \t\r");
        if (start == std::string::npos) continue;
        auto end = line.find_last_not_of(" \t\r");
        line = line.substr(start, end - start + 1);
        if (line.empty()) continue;
        if (!first) result += '\n';
        result += line;
        first = false;
    }
    return result;
}

static std::unordered_map<std::string, std::string> parse_properties(const std::string& raw) {
    std::unordered_map<std::string, std::string> props;
    if (raw.empty()) return props;
    std::istringstream stream(raw);
    std::string segment;
    while (std::getline(stream, segment, ',')) {
        auto colon = segment.find(':');
        if (colon == std::string::npos) continue;
        auto key = segment.substr(0, colon);
        auto val = segment.substr(colon + 1);
        // Trim
        auto ks = key.find_first_not_of(" \t"); if (ks == std::string::npos) continue;
        auto ke = key.find_last_not_of(" \t"); key = key.substr(ks, ke - ks + 1);
        auto vs = val.find_first_not_of(" \t'\""); if (vs == std::string::npos) continue;
        auto ve = val.find_last_not_of(" \t'\""); val = val.substr(vs, ve - vs + 1);
        if (!key.empty() && !val.empty()) props[key] = val;
    }
    return props;
}

static std::vector<std::string> split_pipe(const std::string& raw) {
    std::vector<std::string> ids;
    std::istringstream stream(raw);
    std::string part;
    while (std::getline(stream, part, '|')) {
        // Trim and strip parens
        auto s = part.find_first_not_of(" \t(");
        if (s == std::string::npos) continue;
        auto e = part.find_last_not_of(" \t)");
        part = part.substr(s, e - s + 1);
        // Take before : or {
        auto colon = part.find(':'); if (colon != std::string::npos) part = part.substr(0, colon);
        auto brace = part.find('{'); if (brace != std::string::npos) part = part.substr(0, brace);
        // Trim again
        s = part.find_first_not_of(" \t"); if (s == std::string::npos) continue;
        e = part.find_last_not_of(" \t"); part = part.substr(s, e - s + 1);
        if (!part.empty()) ids.push_back(part);
    }
    return ids;
}

static GgProgram parse_gg(const std::string& source) {
    auto cleaned = strip_comments(source);
    GgProgram prog;

    // Sweep 1: edges
    static const std::regex edge_re(R"(\(([^)]+)\)\s*-\[:([A-Z]+)(?:\s*\{([^}]+)\})?\]->\s*\(([^)]+)\))");
    auto begin = std::sregex_iterator(cleaned.begin(), cleaned.end(), edge_re);
    auto end = std::sregex_iterator();
    for (auto it = begin; it != end; ++it) {
        auto& m = *it;
        auto src_ids = split_pipe(m[1].str());
        auto tgt_ids = split_pipe(m[4].str());
        auto props = parse_properties(m[3].matched ? m[3].str() : "");
        prog.edges.push_back({src_ids, tgt_ids, m[2].str(), props});
        for (auto& id : src_ids) if (!prog.nodes.count(id)) prog.nodes[id] = {id, {}, {}};
        for (auto& id : tgt_ids) if (!prog.nodes.count(id)) prog.nodes[id] = {id, {}, {}};
    }

    // Sweep 2: standalone nodes
    static const std::regex node_re(R"(\(([^:)\s|]+)(?:\s*:\s*([^){\s]+))?(?:\s*\{([^}]+)\})?\))");
    std::istringstream lines(cleaned);
    std::string line;
    while (std::getline(lines, line)) {
        if (line.find("-[:") != std::string::npos) continue;
        auto nbegin = std::sregex_iterator(line.begin(), line.end(), node_re);
        auto nend = std::sregex_iterator();
        for (auto it = nbegin; it != nend; ++it) {
            auto& m = *it;
            auto id = m[1].str();
            if (id.empty() || id.find('|') != std::string::npos) continue;
            if (!prog.nodes.count(id)) {
                std::vector<std::string> labels;
                if (m[2].matched && !m[2].str().empty()) labels.push_back(m[2].str());
                auto props = parse_properties(m[3].matched ? m[3].str() : "");
                prog.nodes[id] = {id, labels, props};
            }
        }
    }
    return prog;
}

static int compute_beta1(const GgProgram& prog) {
    int b1 = 0;
    for (auto& e : prog.edges) {
        int s = e.source_ids.size(), t = e.target_ids.size();
        if (e.edge_type == "FORK") b1 += t - 1;
        else if (e.edge_type == "FOLD" || e.edge_type == "COLLAPSE" || e.edge_type == "OBSERVE") b1 = std::max(0, b1 - (s - 1));
        else if (e.edge_type == "RACE" || e.edge_type == "SLIVER") b1 = std::max(0, b1 - std::max(0, s - t));
        else if (e.edge_type == "VENT") b1 = std::max(0, b1 - 1);
    }
    return b1;
}

static int compute_void_dims(const GgProgram& prog) {
    int d = 0;
    for (auto& e : prog.edges) if (e.edge_type == "FORK") d += e.target_ids.size();
    return d;
}

static double compute_heat(const GgProgram& prog) {
    double h = 0;
    for (auto& e : prog.edges)
        if ((e.edge_type == "FOLD" || e.edge_type == "COLLAPSE" || e.edge_type == "OBSERVE") && e.source_ids.size() > 1)
            h += std::log2(e.source_ids.size());
    return h;
}

static int compute_deficit(const GgProgram& prog) {
    std::unordered_map<std::string, int> out_b, in_m;
    for (auto& e : prog.edges) {
        for (auto& s : e.source_ids) out_b[s] += e.target_ids.size();
        for (auto& t : e.target_ids) in_m[t] += e.source_ids.size();
    }
    int total = 0;
    for (auto& [id, _] : prog.nodes) total += std::abs(out_b[id] - in_m[id]);
    return total;
}

int main(int argc, char** argv) {
    bool beta1_only = false, summary = false;
    int bench_iters = 0;
    const char* filepath = nullptr;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--beta1")) beta1_only = true;
        else if (!strcmp(argv[i], "--summary")) summary = true;
        else if (!strcmp(argv[i], "--bench") && i + 1 < argc) bench_iters = std::atoi(argv[++i]);
        else filepath = argv[i];
    }
    if (!filepath) { std::cerr << "usage: becky-cpp [--beta1|--summary|--bench N] <file.gg>\n"; return 1; }

    std::ifstream file(filepath);
    if (!file) { std::cerr << "becky-cpp: cannot read " << filepath << "\n"; return 1; }
    std::string source((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

    if (bench_iters > 0) {
        for (int i = 0; i < 100; i++) parse_gg(source);
        auto start = std::chrono::high_resolution_clock::now();
        for (int i = 0; i < bench_iters; i++) parse_gg(source);
        auto end = std::chrono::high_resolution_clock::now();
        double ns = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();
        double us = ns / bench_iters / 1000.0;
        auto p = parse_gg(source);
        std::printf("%.1fus/iter | %d iterations | %zu nodes %zu edges | b1=%d | void=%d heat=%.3f deficit=%d\n",
            us, bench_iters, p.nodes.size(), p.edges.size(), compute_beta1(p),
            compute_void_dims(p), compute_heat(p), compute_deficit(p));
        return 0;
    }

    auto p = parse_gg(source);
    int b1 = compute_beta1(p);
    if (beta1_only) { std::cout << b1 << "\n"; return 0; }
    if (summary) {
        std::printf("%s: %zu nodes, %zu edges, b1=%d, void=%d, heat=%.3f, deficit=%d\n",
            filepath, p.nodes.size(), p.edges.size(), b1, compute_void_dims(p), compute_heat(p), compute_deficit(p));
        return 0;
    }
    std::printf("{\"nodes\":%zu,\"edges\":%zu,\"beta1\":%d}\n", p.nodes.size(), p.edges.size(), b1);
    return 0;
}
