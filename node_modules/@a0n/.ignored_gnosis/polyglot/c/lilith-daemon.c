/*
 * lilith-daemon.c -- Persistent Lilith compiler with Wallington rotation.
 *
 * Accepts topology compilations over stdin (newline-delimited protocol).
 * Wallington-rotates requests through three stages:
 *   S1: Scan for edge markers
 *   S2: Extract nodes and edges
 *   S3: Compute beta-1, void, heat
 *
 * While S1 scans request N, S2 extracts request N-1, S3 analyzes N-2.
 * The pipeline is always full after 2 requests. No request waits for
 * another request's analysis to complete.
 *
 * Protocol (stdin → stdout):
 *   Input:  "COMPILE <length>\n<gg source bytes>\n"
 *   Output: "<length> <nodes> <edges> <beta1> <void> <heat>\n"
 *   Input:  "QUIT\n"
 *   Output: (exits)
 *
 * The cannon model: preload once, fire forever.
 *
 * Build: cc -O3 -march=native -o lilith-daemon lilith-daemon.c -lm
 * Usage: echo -e "COMPILE 89\n(src)-[:FORK]->(a|b)\n(a|b)-[:FOLD]->(sink)\n" | ./lilith-daemon
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
#define REQ_MAX 65536
#define PIPELINE_DEPTH 3

/* ═══════════════════════════════════════════════════════════════════ */
/* Types (same as lilith-rotated)                                     */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    int marker_pos, last_open_paren, bracket_end, target_start, target_end;
    char etype[16];
} EdgeMarker;

typedef struct { EdgeMarker markers[MAX_MARKERS]; int count; } MarkerBuffer;
typedef struct { char ids[MAX_NODES][ID_LEN]; int count; } NodeTable;
typedef struct { char types[MAX_EDGES][16]; int src_n[MAX_EDGES]; int tgt_n[MAX_EDGES]; int count; } EdgeTable;
typedef struct { int beta1, void_dims; double heat; } Analysis;

typedef struct {
    int beta1, void_dims, node_count, edge_count;
    double heat;
    int ready; /* 1 when result is available */
} CompileResult;

/* ═══════════════════════════════════════════════════════════════════ */
/* Pipeline slot: one request in flight                               */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    /* Input */
    char source[REQ_MAX];
    int source_len;
    int active; /* 1 if this slot has a request */

    /* Stage 1 output */
    MarkerBuffer markers;

    /* Stage 2 output */
    NodeTable nodes;
    EdgeTable edges;
    int edge_start; /* index into edges where this request's edges begin */

    /* Stage 3 output */
    CompileResult result;
} PipelineSlot;

/* ═══════════════════════════════════════════════════════════════════ */
/* Inline helpers                                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static inline int is_space(char c) { return c == ' ' || c == '\t' || c == '\r'; }
static inline int count_pipes(const char *s, int len) {
    int n = 0; for (int i = 0; i < len; i++) if (s[i] == '|') n++; return n;
}
static inline void extract_id(const char *start, int len, char *out) {
    int i = 0, j = 0;
    while (i < len && (is_space(start[i]) || start[i] == '(')) i++;
    while (i < len && j < ID_LEN - 1) {
        char c = start[i];
        if (c == ':' || c == '{' || c == ')' || c == '|' || c == ' ') break;
        out[j++] = c; i++;
    }
    out[j] = 0;
}
static int find_node(const NodeTable *t, const char *id) {
    for (int i = 0; i < t->count; i++) if (strcmp(t->ids[i], id) == 0) return i;
    return -1;
}
static void insert_node(NodeTable *t, const char *id) {
    if (id[0] == 0 || t->count >= MAX_NODES || find_node(t, id) >= 0) return;
    strncpy(t->ids[t->count], id, ID_LEN - 1); t->ids[t->count][ID_LEN - 1] = 0; t->count++;
}
static void add_piped(NodeTable *t, const char *raw, int len) {
    int start = 0; char id[ID_LEN];
    for (int i = 0; i <= len; i++) {
        if (i == len || raw[i] == '|') {
            if (i > start) { extract_id(raw + start, i - start, id); insert_node(t, id); }
            start = i + 1;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Strip comments (in-place for speed)                                */
/* ═══════════════════════════════════════════════════════════════════ */

static int strip_comments(const char *src, int slen, char *dst) {
    int dlen = 0, i = 0;
    while (i < slen) {
        int ls = i;
        while (i < slen && src[i] != '\n') i++;
        int le = i;
        for (int j = ls; j + 1 < le; j++) if (src[j] == '/' && src[j+1] == '/') { le = j; break; }
        while (ls < le && is_space(src[ls])) ls++;
        while (le > ls && is_space(src[le-1])) le--;
        if (le > ls) { memcpy(dst + dlen, src + ls, le - ls); dlen += le - ls; dst[dlen++] = '\n'; }
        i++;
    }
    dst[dlen] = 0;
    return dlen;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 1: Scan for edge markers                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static void stage1(PipelineSlot *slot) {
    const char *src = slot->source;
    int slen = slot->source_len;
    MarkerBuffer *buf = &slot->markers;
    buf->count = 0;
    int pd = 0, lo = 0;

    for (int i = 0; i < slen; i++) {
        if (src[i] == '(') { pd++; if (pd == 1) lo = i; }
        if (src[i] == ')') pd--;

        if (i + 3 < slen && src[i] == ')' && src[i+1] == '-' && src[i+2] == '[' && src[i+3] == ':') {
            if (buf->count >= MAX_MARKERS) break;
            EdgeMarker *m = &buf->markers[buf->count];
            m->marker_pos = i; m->last_open_paren = lo;

            int bs = i + 4, be = bs;
            while (be < slen && src[be] != ']') be++;
            if (be >= slen) continue;
            m->bracket_end = be;

            int ei = 0;
            for (int j = bs; j < be && ei < 15; j++) {
                if (src[j] == '{') break;
                if (!is_space(src[j])) m->etype[ei++] = src[j];
            }
            m->etype[ei] = 0;

            int arrow = be + 1;
            if (arrow + 1 >= slen || src[arrow] != '-' || src[arrow+1] != '>') continue;
            int ts = arrow + 2;
            while (ts < slen && src[ts] != '(') ts++;
            if (ts >= slen) continue;
            ts++;
            int depth = 1, te = ts;
            while (te < slen && depth > 0) {
                if (src[te] == '(') depth++;
                if (src[te] == ')') { depth--; if (depth == 0) break; }
                te++;
            }
            m->target_start = ts; m->target_end = te;
            buf->count++;
            i = te; pd = 0; lo = te + 1;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 2: Extract nodes and edges                                   */
/* ═══════════════════════════════════════════════════════════════════ */

static void stage2(PipelineSlot *slot) {
    const char *src = slot->source;
    slot->nodes.count = 0;
    slot->edges.count = 0;

    for (int m = 0; m < slot->markers.count; m++) {
        EdgeMarker *mk = &slot->markers.markers[m];
        int ss = mk->last_open_paren + 1, sl = mk->marker_pos - ss;
        int tl = mk->target_end - mk->target_start;

        if (slot->edges.count < MAX_EDGES) {
            strncpy(slot->edges.types[slot->edges.count], mk->etype, 15);
            slot->edges.src_n[slot->edges.count] = count_pipes(src + ss, sl) + 1;
            slot->edges.tgt_n[slot->edges.count] = count_pipes(src + mk->target_start, tl) + 1;
            slot->edges.count++;
        }
        add_piped(&slot->nodes, src + ss, sl);
        add_piped(&slot->nodes, src + mk->target_start, tl);
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 3: Analyze                                                   */
/* ═══════════════════════════════════════════════════════════════════ */

static void stage3(PipelineSlot *slot) {
    int b1 = 0, vd = 0; double h = 0.0;
    for (int e = 0; e < slot->edges.count; e++) {
        int s = slot->edges.src_n[e], t = slot->edges.tgt_n[e];
        const char *et = slot->edges.types[e];
        if (strcmp(et, "FORK") == 0) { b1 += t - 1; vd += t; }
        else if (strcmp(et, "FOLD") == 0 || strcmp(et, "COLLAPSE") == 0 || strcmp(et, "OBSERVE") == 0) {
            b1 -= s - 1; if (b1 < 0) b1 = 0; if (s > 1) h += log2((double)s);
        } else if (strcmp(et, "RACE") == 0 || strcmp(et, "SLIVER") == 0) {
            int d = s - t; if (d < 0) d = 0; b1 -= d; if (b1 < 0) b1 = 0;
        } else if (strcmp(et, "VENT") == 0) { b1--; if (b1 < 0) b1 = 0; }
    }
    slot->result.beta1 = b1;
    slot->result.void_dims = vd;
    slot->result.heat = h;
    slot->result.node_count = slot->nodes.count;
    slot->result.edge_count = slot->edges.count;
    slot->result.ready = 1;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* The daemon: Wallington-rotated request pipeline                    */
/* ═══════════════════════════════════════════════════════════════════ */

int main(int argc, char **argv) {
    /* Single-request mode for compatibility */
    if (argc > 1 && strcmp(argv[1], "--once") == 0 && argc > 2) {
        FILE *f = fopen(argv[2], "r");
        if (!f) { fprintf(stderr, "lilith-daemon: cannot read %s\n", argv[2]); return 1; }
        static char raw[REQ_MAX];
        int rlen = fread(raw, 1, REQ_MAX - 1, f); raw[rlen] = 0; fclose(f);
        static char cleaned[REQ_MAX];
        int clen = strip_comments(raw, rlen, cleaned);

        PipelineSlot slot = { .active = 1, .source_len = clen };
        memcpy(slot.source, cleaned, clen + 1);
        stage1(&slot); stage2(&slot); stage3(&slot);

        int bench = 0;
        for (int i = 3; i < argc; i++) {
            if (strcmp(argv[i], "--bench") == 0 && i + 1 < argc) bench = atoi(argv[++i]);
            if (strcmp(argv[i], "--summary") == 0) {
                printf("%s: %d nodes, %d edges, b1=%d, void=%d, heat=%.3f\n",
                    argv[2], slot.result.node_count, slot.result.edge_count,
                    slot.result.beta1, slot.result.void_dims, slot.result.heat);
                return 0;
            }
        }
        if (bench > 0) {
            for (int i = 0; i < 10; i++) { stage1(&slot); stage2(&slot); stage3(&slot); }
            struct timespec t0, t1;
            clock_gettime(CLOCK_MONOTONIC, &t0);
            for (int i = 0; i < bench; i++) { stage1(&slot); stage2(&slot); stage3(&slot); }
            clock_gettime(CLOCK_MONOTONIC, &t1);
            double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
            printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d\n",
                ns / bench / 1000.0, bench, slot.result.node_count, slot.result.edge_count, slot.result.beta1);
            return 0;
        }
        printf("%d %d %d %d %.3f\n", slot.result.node_count, slot.result.edge_count,
            slot.result.beta1, slot.result.void_dims, slot.result.heat);
        return 0;
    }

    /* ═══════════════════════════════════════════════════════════════ */
    /* Daemon mode: read requests from stdin, Wallington-rotate them  */
    /* ═══════════════════════════════════════════════════════════════ */

    static PipelineSlot pipeline[PIPELINE_DEPTH];
    int head = 0; /* next slot to fill */
    int completed = 0;
    char cmd[32];
    int len;

    /* Disable buffering for real-time response */
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stdin, NULL, _IONBF, 0);

    fprintf(stderr, "[lilith-daemon] ready. Pipeline depth: %d\n", PIPELINE_DEPTH);

    while (1) {
        if (scanf("%31s", cmd) != 1) break;

        if (strcmp(cmd, "QUIT") == 0) break;

        if (strcmp(cmd, "COMPILE") == 0) {
            if (scanf("%d", &len) != 1 || len <= 0 || len >= REQ_MAX) {
                fprintf(stderr, "[lilith-daemon] bad length\n");
                continue;
            }
            /* Read the newline after length */
            fgetc(stdin);

            /* Read source bytes */
            static char raw[REQ_MAX];
            int got = fread(raw, 1, len, stdin);
            raw[got] = 0;

            /* Strip comments into pipeline slot */
            int slot_idx = head % PIPELINE_DEPTH;
            PipelineSlot *slot = &pipeline[slot_idx];

            /* If this slot has a completed result we haven't emitted, emit it */
            if (slot->result.ready) {
                printf("%d %d %d %d %.3f\n",
                    slot->result.node_count, slot->result.edge_count,
                    slot->result.beta1, slot->result.void_dims, slot->result.heat);
                slot->result.ready = 0;
            }

            slot->source_len = strip_comments(raw, got, slot->source);
            slot->active = 1;

            /* ═══════════════════════════════════════════════════════ */
            /* Wallington rotation: advance all stages one tick        */
            /* ═══════════════════════════════════════════════════════ */

            /* Stage 1: scan the new request */
            stage1(slot);

            /* Stage 2: extract from the previous request (if any) */
            int prev_idx = (head - 1 + PIPELINE_DEPTH) % PIPELINE_DEPTH;
            if (head > 0 && pipeline[prev_idx].active && !pipeline[prev_idx].result.ready) {
                stage2(&pipeline[prev_idx]);
            }

            /* Stage 3: analyze two requests back (if any) */
            int prev2_idx = (head - 2 + PIPELINE_DEPTH) % PIPELINE_DEPTH;
            if (head > 1 && pipeline[prev2_idx].active && !pipeline[prev2_idx].result.ready) {
                stage3(&pipeline[prev2_idx]);
                /* Emit result immediately */
                printf("%d %d %d %d %.3f\n",
                    pipeline[prev2_idx].result.node_count,
                    pipeline[prev2_idx].result.edge_count,
                    pipeline[prev2_idx].result.beta1,
                    pipeline[prev2_idx].result.void_dims,
                    pipeline[prev2_idx].result.heat);
                fflush(stdout);
                pipeline[prev2_idx].result.ready = 0;
                pipeline[prev2_idx].active = 0;
                completed++;
            }

            head++;
        }
    }

    /* Drain: flush remaining pipeline stages */
    for (int drain = 0; drain < PIPELINE_DEPTH; drain++) {
        int idx = (head - PIPELINE_DEPTH + drain + PIPELINE_DEPTH) % PIPELINE_DEPTH;
        PipelineSlot *slot = &pipeline[idx];
        if (!slot->active) continue;
        if (slot->markers.count > 0 && slot->edges.count == 0) stage2(slot);
        if (slot->edges.count > 0 && !slot->result.ready) stage3(slot);
        if (slot->result.ready) {
            printf("%d %d %d %d %.3f\n",
                slot->result.node_count, slot->result.edge_count,
                slot->result.beta1, slot->result.void_dims, slot->result.heat);
            completed++;
        }
    }

    fprintf(stderr, "[lilith-daemon] %d compilations completed\n", completed);
    return 0;
}
