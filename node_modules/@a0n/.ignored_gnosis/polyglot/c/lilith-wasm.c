/*
 * lilith-wasm.c -- Lilith compiled to standalone WASM.
 *
 * No libc. No stdio. No malloc. Just exported functions and
 * a bump allocator. Runs on Cloudflare Workers, browsers, Node, Bun.
 *
 * Exports:
 *   lilith_alloc(size)      → pointer into linear memory
 *   lilith_compile(ptr,len) → 0 on success
 *   lilith_get_nodes()      → node count
 *   lilith_get_edges()      → edge count
 *   lilith_get_beta1()      → beta-1
 *   lilith_get_void()       → void dimensions
 *
 * Build:
 *   clang --target=wasm32-unknown-unknown -O3 -nostdlib \
 *     -Wl,--no-entry -Wl,--export-dynamic \
 *     -Wl,--initial-memory=1048576 \
 *     -o lilith.wasm lilith-wasm.c
 */

/* No includes -- standalone WASM, no libc */

#define MAX_NODES 512
#define MAX_EDGES 256
#define ID_LEN 64

/* ═══════════════════════════════════════════════════════════════════ */
/* Bump allocator                                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static unsigned char __heap[262144]; /* 256KB heap */
static int __heap_ptr = 0;

__attribute__((export_name("lilith_alloc")))
void* lilith_alloc(int size) {
    int aligned = (__heap_ptr + 7) & ~7;
    if (aligned + size > (int)sizeof(__heap)) return (void*)0;
    void* ptr = &__heap[aligned];
    __heap_ptr = aligned + size;
    return ptr;
}

static void heap_reset(void) { __heap_ptr = 0; }

/* ═══════════════════════════════════════════════════════════════════ */
/* String helpers (no libc)                                           */
/* ═══════════════════════════════════════════════════════════════════ */

static int str_eq(const char *a, const char *b) {
    while (*a && *b) { if (*a != *b) return 0; a++; b++; }
    return *a == *b;
}

static int str_len(const char *s) { int n = 0; while (s[n]) n++; return n; }

static void str_copy(char *dst, const char *src, int max) {
    int i = 0;
    while (i < max - 1 && src[i]) { dst[i] = src[i]; i++; }
    dst[i] = 0;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Result storage                                                     */
/* ═══════════════════════════════════════════════════════════════════ */

static int result_nodes, result_edges, result_beta1, result_void;
static float result_heat;

__attribute__((export_name("lilith_get_nodes")))
int lilith_get_nodes(void) { return result_nodes; }

__attribute__((export_name("lilith_get_edges")))
int lilith_get_edges(void) { return result_edges; }

__attribute__((export_name("lilith_get_beta1")))
int lilith_get_beta1(void) { return result_beta1; }

__attribute__((export_name("lilith_get_void")))
int lilith_get_void(void) { return result_void; }

/* ═══════════════════════════════════════════════════════════════════ */
/* Node dedup                                                         */
/* ═══════════════════════════════════════════════════════════════════ */

static char node_ids[MAX_NODES][ID_LEN];
static int node_count;

static int find_node(const char *id) {
    for (int i = 0; i < node_count; i++)
        if (str_eq(node_ids[i], id)) return i;
    return -1;
}

static void insert_node(const char *id) {
    if (id[0] == 0 || node_count >= MAX_NODES || find_node(id) >= 0) return;
    str_copy(node_ids[node_count], id, ID_LEN);
    node_count++;
}

static inline int is_space(char c) { return c == ' ' || c == '\t' || c == '\r'; }

static void extract_id(const char *start, int len, char *out) {
    int i = 0, j = 0;
    while (i < len && (is_space(start[i]) || start[i] == '(')) i++;
    while (i < len && j < ID_LEN - 1) {
        char c = start[i];
        if (c == ':' || c == '{' || c == ')' || c == '|' || c == ' ') break;
        out[j++] = c; i++;
    }
    out[j] = 0;
}

static int count_pipes(const char *s, int len) {
    int n = 0; for (int i = 0; i < len; i++) if (s[i] == '|') n++; return n;
}

static void add_piped(const char *raw, int len) {
    int start = 0;
    char id[ID_LEN];
    for (int i = 0; i <= len; i++) {
        if (i == len || raw[i] == '|') {
            if (i > start) { extract_id(raw + start, i - start, id); insert_node(id); }
            start = i + 1;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Edge storage                                                       */
/* ═══════════════════════════════════════════════════════════════════ */

static char edge_types[MAX_EDGES][16];
static int edge_src_n[MAX_EDGES], edge_tgt_n[MAX_EDGES];
static int edge_count;

/* ═══════════════════════════════════════════════════════════════════ */
/* Strip comments                                                     */
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
        if (le > ls) {
            for (int k = ls; k < le; k++) dst[dlen++] = src[k];
            dst[dlen++] = '\n';
        }
        i++;
    }
    dst[dlen] = 0;
    return dlen;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Forward-only scanner (Lilith core)                                 */
/* ═══════════════════════════════════════════════════════════════════ */

__attribute__((export_name("lilith_compile")))
int lilith_compile(const char *raw, int raw_len) {
    static char cleaned[65536];
    int slen = strip_comments(raw, raw_len, cleaned);

    node_count = 0;
    edge_count = 0;

    int paren_depth = 0, last_open = 0;

    for (int i = 0; i < slen; i++) {
        if (cleaned[i] == '(') { paren_depth++; if (paren_depth == 1) last_open = i; }
        if (cleaned[i] == ')') paren_depth--;

        if (i + 3 < slen && cleaned[i] == ')' && cleaned[i+1] == '-'
            && cleaned[i+2] == '[' && cleaned[i+3] == ':') {

            int src_start = last_open + 1;
            int src_len = i - src_start;

            int bs = i + 4, be = bs;
            while (be < slen && cleaned[be] != ']') be++;
            if (be >= slen) { i++; continue; }

            char etype[16] = {0};
            int ei = 0;
            for (int j = bs; j < be && ei < 15; j++) {
                if (cleaned[j] == '{') break;
                if (!is_space(cleaned[j])) etype[ei++] = cleaned[j];
            }

            int arrow = be + 1;
            if (arrow + 1 >= slen || cleaned[arrow] != '-' || cleaned[arrow+1] != '>') { i++; continue; }

            int ts = arrow + 2;
            while (ts < slen && cleaned[ts] != '(') ts++;
            if (ts >= slen) { i++; continue; }
            ts++;
            int depth = 1, te = ts;
            while (te < slen && depth > 0) {
                if (cleaned[te] == '(') depth++;
                if (cleaned[te] == ')') { depth--; if (depth == 0) break; }
                te++;
            }

            if (edge_count < MAX_EDGES) {
                str_copy(edge_types[edge_count], etype, 16);
                edge_src_n[edge_count] = count_pipes(cleaned + src_start, src_len) + 1;
                edge_tgt_n[edge_count] = count_pipes(cleaned + ts, te - ts) + 1;
                edge_count++;
            }

            add_piped(cleaned + src_start, src_len);
            add_piped(cleaned + ts, te - ts);

            i = te;
            paren_depth = 0;
            last_open = 0;
            continue;
        }
    }

    /* Compute results */
    int b1 = 0, vd = 0;
    for (int e = 0; e < edge_count; e++) {
        int s = edge_src_n[e], t = edge_tgt_n[e];
        if (str_eq(edge_types[e], "FORK")) { b1 += t - 1; vd += t; }
        else if (str_eq(edge_types[e], "FOLD") || str_eq(edge_types[e], "COLLAPSE") || str_eq(edge_types[e], "OBSERVE"))
            { b1 -= s - 1; if (b1 < 0) b1 = 0; }
        else if (str_eq(edge_types[e], "RACE") || str_eq(edge_types[e], "SLIVER"))
            { int d = s - t; if (d < 0) d = 0; b1 -= d; if (b1 < 0) b1 = 0; }
        else if (str_eq(edge_types[e], "VENT"))
            { b1--; if (b1 < 0) b1 = 0; }
    }

    result_nodes = node_count;
    result_edges = edge_count;
    result_beta1 = b1;
    result_void = vd;

    return 0;
}
