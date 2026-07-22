/*
 * lilith-rotated.c -- Lilith with Wallington rotation.
 *
 * Three-stage pipeline, chunked input, staggered execution:
 *   Stage 1: Scan chunk for )-[: markers (edge detection)
 *   Stage 2: Extract source/target IDs from detected edges
 *   Stage 3: Compute beta-1, void dimensions, Landauer heat
 *
 * On large topologies, stages overlap: while S1 scans chunk C,
 * S2 processes chunk C-1, S3 analyzes chunk C-2.
 *
 * Build: cc -O3 -march=native -o lilith-rotated lilith-rotated.c -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define MAX_NODES 512
#define MAX_EDGES 256
#define MAX_MARKERS 128
#define ID_LEN 64
#define SRC_MAX 65536
#define CHUNK_COUNT 4

/* ═══════════════════════════════════════════════════════════════════ */
/* Types                                                              */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    int marker_pos;        /* position of ) in )-[: */
    int last_open_paren;   /* position of matching ( */
    int bracket_end;       /* position of ] */
    int target_start;      /* position of first char inside target (...) */
    int target_end;        /* position of ) closing target */
    char etype[16];        /* edge type string */
} EdgeMarker;

typedef struct {
    EdgeMarker markers[MAX_MARKERS];
    int count;
} MarkerBuffer;

typedef struct {
    char ids[MAX_NODES][ID_LEN];
    int count;
} NodeTable;

typedef struct {
    char types[MAX_EDGES][16];
    int src_n[MAX_EDGES];
    int tgt_n[MAX_EDGES];
    int count;
} EdgeTable;

typedef struct {
    int beta1;
    int void_dims;
    double heat;
} AnalysisResult;

/* ═══════════════════════════════════════════════════════════════════ */
/* Inline helpers                                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static inline int is_space(char c) { return c == ' ' || c == '\t' || c == '\r'; }

static inline int count_pipes(const char *s, int len) {
    int n = 0;
    for (int i = 0; i < len; i++) if (s[i] == '|') n++;
    return n;
}

static inline void extract_id(const char *start, int len, char *out) {
    int i = 0, j = 0;
    while (i < len && (is_space(start[i]) || start[i] == '(')) i++;
    while (i < len && j < ID_LEN - 1) {
        char c = start[i];
        if (c == ':' || c == '{' || c == ')' || c == '|' || c == ' ') break;
        out[j++] = c;
        i++;
    }
    out[j] = 0;
}

static int find_node(const NodeTable *restrict t, const char *restrict id) {
    for (int i = 0; i < t->count; i++)
        if (strcmp(t->ids[i], id) == 0) return i;
    return -1;
}

static void insert_node(NodeTable *restrict t, const char *restrict id) {
    if (id[0] == 0 || t->count >= MAX_NODES) return;
    if (find_node(t, id) >= 0) return;
    strncpy(t->ids[t->count], id, ID_LEN - 1);
    t->ids[t->count][ID_LEN - 1] = 0;
    t->count++;
}

static void add_piped_nodes(NodeTable *restrict t, const char *restrict raw, int len) {
    int start = 0;
    char id[ID_LEN];
    for (int i = 0; i <= len; i++) {
        if (i == len || raw[i] == '|') {
            if (i > start) { extract_id(raw + start, i - start, id); insert_node(t, id); }
            start = i + 1;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Strip comments                                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static int strip_comments(const char *restrict src, int slen, char *restrict dst) {
    int dlen = 0, i = 0;
    while (i < slen) {
        int ls = i;
        while (i < slen && src[i] != '\n') i++;
        int le = i;
        for (int j = ls; j + 1 < le; j++)
            if (src[j] == '/' && src[j+1] == '/') { le = j; break; }
        while (ls < le && is_space(src[ls])) ls++;
        while (le > ls && is_space(src[le-1])) le--;
        if (le > ls) {
            memcpy(dst + dlen, src + ls, le - ls);
            dlen += le - ls;
            dst[dlen++] = '\n';
        }
        i++;
    }
    dst[dlen] = 0;
    return dlen;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* STAGE 1: Scan for edge markers (forward-only, per chunk)          */
/* ═══════════════════════════════════════════════════════════════════ */

static void stage1_scan(const char *restrict src, int start, int end,
                        MarkerBuffer *restrict buf) {
    buf->count = 0;
    int paren_depth = 0, last_open = start;

    for (int i = start; i < end; i++) {
        if (src[i] == '(') { paren_depth++; if (paren_depth == 1) last_open = i; }
        if (src[i] == ')') paren_depth--;

        if (i + 3 < end && src[i] == ')' && src[i+1] == '-' && src[i+2] == '[' && src[i+3] == ':') {
            if (buf->count >= MAX_MARKERS) break;

            EdgeMarker *m = &buf->markers[buf->count];
            m->marker_pos = i;
            m->last_open_paren = last_open;

            /* Find ] */
            int bs = i + 4, be = bs;
            while (be < end && src[be] != ']') be++;
            if (be >= end) continue;
            m->bracket_end = be;

            /* Extract edge type */
            int ei = 0;
            for (int j = bs; j < be && ei < 15; j++) {
                if (src[j] == '{') break;
                if (!is_space(src[j])) m->etype[ei++] = src[j];
            }
            m->etype[ei] = 0;

            /* Find -> and target */
            int arrow = be + 1;
            if (arrow + 1 >= end || src[arrow] != '-' || src[arrow+1] != '>') continue;

            int ts = arrow + 2;
            while (ts < end && src[ts] != '(') ts++;
            if (ts >= end) continue;
            ts++;
            int depth = 1, te = ts;
            while (te < end && depth > 0) {
                if (src[te] == '(') depth++;
                if (src[te] == ')') { depth--; if (depth == 0) break; }
                te++;
            }
            m->target_start = ts;
            m->target_end = te;
            buf->count++;

            /* Jump past target for next iteration */
            i = te;
            paren_depth = 0;
            last_open = te + 1;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* STAGE 2: Extract IDs from detected markers                        */
/* ═══════════════════════════════════════════════════════════════════ */

static void stage2_extract(const char *restrict src,
                           const MarkerBuffer *restrict markers,
                           NodeTable *restrict nodes,
                           EdgeTable *restrict edges) {
    for (int m = 0; m < markers->count; m++) {
        const EdgeMarker *mk = &markers->markers[m];

        int src_start = mk->last_open_paren + 1;
        int src_len = mk->marker_pos - src_start;
        int tgt_len = mk->target_end - mk->target_start;

        if (edges->count < MAX_EDGES) {
            strncpy(edges->types[edges->count], mk->etype, 15);
            edges->src_n[edges->count] = count_pipes(src + src_start, src_len) + 1;
            edges->tgt_n[edges->count] = count_pipes(src + mk->target_start, tgt_len) + 1;
            edges->count++;
        }

        add_piped_nodes(nodes, src + src_start, src_len);
        add_piped_nodes(nodes, src + mk->target_start, tgt_len);
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* STAGE 3: Compute beta-1, void, heat from edge table               */
/* ═══════════════════════════════════════════════════════════════════ */

static AnalysisResult stage3_analyze(const EdgeTable *restrict edges,
                                      int start_edge, int end_edge,
                                      AnalysisResult prev) {
    AnalysisResult r = prev;
    for (int e = start_edge; e < end_edge; e++) {
        int s = edges->src_n[e], t = edges->tgt_n[e];
        const char *et = edges->types[e];
        if (strcmp(et, "FORK") == 0) {
            r.beta1 += t - 1; r.void_dims += t;
        } else if (strcmp(et, "FOLD") == 0 || strcmp(et, "COLLAPSE") == 0 || strcmp(et, "OBSERVE") == 0) {
            r.beta1 -= s - 1; if (r.beta1 < 0) r.beta1 = 0;
            if (s > 1) r.heat += log2((double)s);
        } else if (strcmp(et, "RACE") == 0 || strcmp(et, "SLIVER") == 0) {
            int d = s - t; if (d < 0) d = 0;
            r.beta1 -= d; if (r.beta1 < 0) r.beta1 = 0;
        } else if (strcmp(et, "VENT") == 0) {
            r.beta1--; if (r.beta1 < 0) r.beta1 = 0;
        }
    }
    return r;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Wallington rotation: chunked three-stage pipeline                  */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    int beta1, void_dims, node_count, edge_count;
    double heat;
} LilithResult;

static LilithResult lilith_parse_rotated(const char *restrict src, int slen) {
    NodeTable nodes = { .count = 0 };
    EdgeTable edges = { .count = 0 };

    /* Chunk the input at newline boundaries */
    int chunk_starts[CHUNK_COUNT + 1];
    int chunk_size = slen / CHUNK_COUNT;
    chunk_starts[0] = 0;
    for (int c = 1; c < CHUNK_COUNT; c++) {
        int pos = c * chunk_size;
        /* Align to next newline so we don't split edges */
        while (pos < slen && src[pos] != '\n') pos++;
        if (pos < slen) pos++; /* skip the newline */
        chunk_starts[c] = pos;
    }
    chunk_starts[CHUNK_COUNT] = slen;

    /* Wallington rotation: stagger stages across chunks.
     *
     * Tick 0: S1(chunk0)
     * Tick 1: S1(chunk1), S2(chunk0)
     * Tick 2: S1(chunk2), S2(chunk1), S3(chunk0)
     * Tick 3: S1(chunk3), S2(chunk2), S3(chunk1)
     * Tick 4:             S2(chunk3), S3(chunk2)
     * Tick 5:                         S3(chunk3)
     *
     * In single-threaded mode, stages execute sequentially per tick.
     * The rotation reduces per-stage working set (cache-friendly).
     */

    MarkerBuffer marker_bufs[CHUNK_COUNT];
    int edge_count_before[CHUNK_COUNT];
    AnalysisResult analysis = { .beta1 = 0, .void_dims = 0, .heat = 0.0 };

    int total_ticks = CHUNK_COUNT + 2; /* ramp-up + drain */

    for (int tick = 0; tick < total_ticks; tick++) {
        /* Stage 1: scan chunk[tick] if in range */
        int s1_chunk = tick;
        if (s1_chunk >= 0 && s1_chunk < CHUNK_COUNT) {
            stage1_scan(src, chunk_starts[s1_chunk], chunk_starts[s1_chunk + 1],
                       &marker_bufs[s1_chunk]);
        }

        /* Stage 2: extract from chunk[tick-1] if in range */
        int s2_chunk = tick - 1;
        if (s2_chunk >= 0 && s2_chunk < CHUNK_COUNT) {
            edge_count_before[s2_chunk] = edges.count;
            stage2_extract(src, &marker_bufs[s2_chunk], &nodes, &edges);
        }

        /* Stage 3: analyze edges from chunk[tick-2] if in range */
        int s3_chunk = tick - 2;
        if (s3_chunk >= 0 && s3_chunk < CHUNK_COUNT) {
            int e_start = edge_count_before[s3_chunk];
            int e_end = (s3_chunk + 1 < CHUNK_COUNT) ? edge_count_before[s3_chunk + 1] : edges.count;
            /* For the last chunk being analyzed, e_end might not be set yet */
            if (s3_chunk == CHUNK_COUNT - 1) e_end = edges.count;
            analysis = stage3_analyze(&edges, e_start, e_end, analysis);
        }
    }

    return (LilithResult){
        .beta1 = analysis.beta1,
        .void_dims = analysis.void_dims,
        .heat = analysis.heat,
        .node_count = nodes.count,
        .edge_count = edges.count,
    };
}

/* ═══════════════════════════════════════════════════════════════════ */
/* CLI                                                                */
/* ═══════════════════════════════════════════════════════════════════ */

int main(int argc, char **argv) {
    int beta1_only = 0, summary = 0, bench_iters = 0;
    const char *filepath = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--beta1") == 0) beta1_only = 1;
        else if (strcmp(argv[i], "--summary") == 0) summary = 1;
        else if (strcmp(argv[i], "--bench") == 0 && i + 1 < argc) bench_iters = atoi(argv[++i]);
        else filepath = argv[i];
    }
    if (!filepath) { fprintf(stderr, "usage: lilith-rotated [--beta1|--summary|--bench N] <file.gg>\n"); return 1; }

    FILE *f = fopen(filepath, "r");
    if (!f) { fprintf(stderr, "lilith-rotated: cannot read %s\n", filepath); return 1; }
    static char raw[SRC_MAX];
    int raw_len = fread(raw, 1, SRC_MAX - 1, f);
    raw[raw_len] = 0;
    fclose(f);

    static char cleaned[SRC_MAX];
    int clean_len = strip_comments(raw, raw_len, cleaned);

    if (bench_iters > 0) {
        for (int i = 0; i < 10; i++) lilith_parse_rotated(cleaned, clean_len);
        struct timespec t0, t1;
        clock_gettime(CLOCK_MONOTONIC, &t0);
        for (int i = 0; i < bench_iters; i++) lilith_parse_rotated(cleaned, clean_len);
        clock_gettime(CLOCK_MONOTONIC, &t1);
        double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
        double us = ns / bench_iters / 1000.0;
        LilithResult r = lilith_parse_rotated(cleaned, clean_len);
        printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | void=%d heat=%.3f\n",
            us, bench_iters, r.node_count, r.edge_count, r.beta1, r.void_dims, r.heat);
        return 0;
    }

    LilithResult r = lilith_parse_rotated(cleaned, clean_len);

    if (beta1_only) printf("%d\n", r.beta1);
    else if (summary) printf("%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f\n",
        filepath, r.node_count, r.edge_count, r.beta1, r.void_dims, r.heat);
    else printf("{\"nodes\":%d,\"edges\":%d,\"beta1\":%d}\n", r.node_count, r.edge_count, r.beta1);
    return 0;
}
