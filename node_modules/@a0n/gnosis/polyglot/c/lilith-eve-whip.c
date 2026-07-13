/*
 * lilith-eve-whip.c -- Hella-whipped Worthington rotation of Lilith + Eve.
 *
 * Three stages. S shards. Full pipeline occupancy.
 *
 *   Stage 1 (Lilith): compile .gg topology (3us)
 *   Stage 2 (Handler): execute topology dispatch
 *   Stage 3 (Eve): chunk + codec race + compress output
 *
 * Worthington Whip: S shards rotate through all 3 stages simultaneously.
 * While shard 0 is in Eve, shard 1 is in handler, shard 2 is in Lilith.
 * The cursor advances every tick. No stage is ever idle.
 *
 *   Tick 0: L(s0)
 *   Tick 1: L(s1) H(s0)
 *   Tick 2: L(s2) H(s1) E(s0)    ← full pipeline
 *   Tick 3: L(s3) H(s2) E(s1)    ← steady state
 *   ...
 *
 * Build: cc -O3 -march=native -o lilith-eve-whip lilith-eve-whip.c -lz -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <zlib.h>

#define MAX_NODES 512
#define MAX_EDGES 256
#define ID_LEN 64
#define CHUNK_SIZE 65536
#define SHARD_COUNT 4
#define CODEC_COUNT 3

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 1: Lilith (topology compilation)                             */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    char node_ids[MAX_NODES][ID_LEN];
    int node_count;
    char edge_types[MAX_EDGES][16];
    int edge_src_n[MAX_EDGES], edge_tgt_n[MAX_EDGES];
    int edge_count;
    int beta1, void_dims;
    double heat;
} LilithResult;

static inline int is_space(char c) { return c == ' ' || c == '\t' || c == '\r'; }

static int strip_comments(const char *restrict src, int slen, char *restrict dst) {
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

static int find_node(const LilithResult *r, const char *id) {
    for (int i = 0; i < r->node_count; i++) if (strcmp(r->node_ids[i], id) == 0) return i;
    return -1;
}

static void insert_node(LilithResult *r, const char *id) {
    if (id[0] == 0 || r->node_count >= MAX_NODES || find_node(r, id) >= 0) return;
    strncpy(r->node_ids[r->node_count], id, ID_LEN - 1);
    r->node_ids[r->node_count][ID_LEN - 1] = 0;
    r->node_count++;
}

static void extract_id(const char *s, int len, char *out) {
    int i = 0, j = 0;
    while (i < len && (is_space(s[i]) || s[i] == '(')) i++;
    while (i < len && j < ID_LEN - 1) {
        char c = s[i]; if (c == ':' || c == '{' || c == ')' || c == '|' || c == ' ') break;
        out[j++] = c; i++;
    }
    out[j] = 0;
}

static int count_pipes(const char *s, int len) {
    int n = 0; for (int i = 0; i < len; i++) if (s[i] == '|') n++; return n;
}

static void add_piped(LilithResult *r, const char *raw, int len) {
    int start = 0; char id[ID_LEN];
    for (int i = 0; i <= len; i++) {
        if (i == len || raw[i] == '|') {
            if (i > start) { extract_id(raw + start, i - start, id); insert_node(r, id); }
            start = i + 1;
        }
    }
}

static void lilith_compile(const char *restrict cleaned, int slen, LilithResult *r) {
    r->node_count = 0; r->edge_count = 0;
    r->beta1 = 0; r->void_dims = 0; r->heat = 0.0;

    int pd = 0, lo = 0;
    for (int i = 0; i < slen; i++) {
        if (cleaned[i] == '(') { pd++; if (pd == 1) lo = i; }
        if (cleaned[i] == ')') pd--;

        if (i + 3 < slen && cleaned[i] == ')' && cleaned[i+1] == '-' && cleaned[i+2] == '[' && cleaned[i+3] == ':') {
            int ss = lo + 1, sl = i - ss;
            int bs = i + 4, be = bs;
            while (be < slen && cleaned[be] != ']') be++;
            if (be >= slen) { i++; continue; }

            char et[16] = {0}; int ei = 0;
            for (int j = bs; j < be && ei < 15; j++) { if (cleaned[j] == '{') break; if (!is_space(cleaned[j])) et[ei++] = cleaned[j]; }

            int arrow = be + 1;
            if (arrow + 1 >= slen || cleaned[arrow] != '-' || cleaned[arrow+1] != '>') { i++; continue; }
            int ts = arrow + 2;
            while (ts < slen && cleaned[ts] != '(') ts++;
            if (ts >= slen) { i++; continue; }
            ts++;
            int depth = 1, te = ts;
            while (te < slen && depth > 0) { if (cleaned[te] == '(') depth++; if (cleaned[te] == ')') { depth--; if (depth == 0) break; } te++; }

            if (r->edge_count < MAX_EDGES) {
                strncpy(r->edge_types[r->edge_count], et, 15);
                r->edge_src_n[r->edge_count] = count_pipes(cleaned + ss, sl) + 1;
                r->edge_tgt_n[r->edge_count] = count_pipes(cleaned + ts, te - ts) + 1;
                r->edge_count++;
            }
            add_piped(r, cleaned + ss, sl);
            add_piped(r, cleaned + ts, te - ts);
            i = te; pd = 0; lo = 0; continue;
        }
    }

    /* Compute beta1, void, heat */
    for (int e = 0; e < r->edge_count; e++) {
        int s = r->edge_src_n[e], t = r->edge_tgt_n[e];
        if (strcmp(r->edge_types[e], "FORK") == 0) { r->beta1 += t - 1; r->void_dims += t; }
        else if (strcmp(r->edge_types[e], "FOLD") == 0 || strcmp(r->edge_types[e], "COLLAPSE") == 0 || strcmp(r->edge_types[e], "OBSERVE") == 0) {
            r->beta1 -= s - 1; if (r->beta1 < 0) r->beta1 = 0;
            if (s > 1) r->heat += log2((double)s);
        }
        else if (strcmp(r->edge_types[e], "RACE") == 0 || strcmp(r->edge_types[e], "SLIVER") == 0) { int d = s - t; if (d < 0) d = 0; r->beta1 -= d; if (r->beta1 < 0) r->beta1 = 0; }
        else if (strcmp(r->edge_types[e], "VENT") == 0) { r->beta1--; if (r->beta1 < 0) r->beta1 = 0; }
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 2: Handler (topology dispatch -- simulated)                  */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    unsigned char response[65536];
    int response_len;
    int route_matched;
} HandlerResult;

static void handler_dispatch(const LilithResult *topology, const char *path,
                             HandlerResult *out) {
    /* Simulated handler: produce response based on path */
    if (strcmp(path, "/plaintext") == 0) {
        memcpy(out->response, "Hello, World!", 13);
        out->response_len = 13;
    } else if (strcmp(path, "/json") == 0) {
        const char *json = "{\"message\":\"Hello, World!\"}";
        int len = strlen(json);
        memcpy(out->response, json, len);
        out->response_len = len;
    } else {
        out->response_len = 0;
    }
    out->route_matched = out->response_len > 0;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Stage 3: Eve (response compression)                                */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    unsigned char compressed[65536];
    int compressed_len;
    int codec_id;     /* 0=identity, 1=gzip, 2=deflate */
    int original_len;
} EveResult;

static void eve_compress(const unsigned char *data, int len, EveResult *out) {
    out->original_len = len;

    /* Identity */
    int id_len = len;

    /* Deflate */
    unsigned char deflate_buf[65536];
    z_stream strm;
    memset(&strm, 0, sizeof(strm));
    deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
    strm.next_in = (unsigned char *)data;
    strm.avail_in = len;
    strm.next_out = deflate_buf;
    strm.avail_out = sizeof(deflate_buf);
    deflate(&strm, Z_FINISH);
    int def_len = strm.total_out;
    deflateEnd(&strm);

    /* Gzip */
    unsigned char gzip_buf[65536];
    memset(&strm, 0, sizeof(strm));
    deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY);
    strm.next_in = (unsigned char *)data;
    strm.avail_in = len;
    strm.next_out = gzip_buf;
    strm.avail_out = sizeof(gzip_buf);
    deflate(&strm, Z_FINISH);
    int gz_len = strm.total_out;
    deflateEnd(&strm);

    /* RACE: smallest wins */
    if (def_len <= gz_len && def_len <= id_len) {
        memcpy(out->compressed, deflate_buf, def_len);
        out->compressed_len = def_len; out->codec_id = 2;
    } else if (gz_len <= id_len) {
        memcpy(out->compressed, gzip_buf, gz_len);
        out->compressed_len = gz_len; out->codec_id = 1;
    } else {
        memcpy(out->compressed, data, len);
        out->compressed_len = len; out->codec_id = 0;
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* The Worthington Whip: S shards × 3 stages, fully pipelined         */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    /* Per-shard state */
    char source[65536];
    int source_len;
    char cleaned[65536];
    int cleaned_len;
    char path[64];

    LilithResult lilith;
    HandlerResult handler;
    EveResult eve;

    int stage; /* 0=waiting, 1=in-lilith, 2=in-handler, 3=in-eve, 4=done */
} Shard;

typedef struct {
    int requests_completed;
    int total_original_bytes;
    int total_compressed_bytes;
    int codec_wins[CODEC_COUNT];
} WhipStats;

/*
 * Hella-whipped Worthington rotation.
 *
 * Each tick advances all active shards one stage:
 *   - Shards in stage 1 (Lilith) move to stage 2 (Handler)
 *   - Shards in stage 2 (Handler) move to stage 3 (Eve)
 *   - Shards in stage 3 (Eve) are completed (results collected)
 *   - A new shard enters stage 1 (Lilith)
 *
 * After ramp-up (2 ticks), all 3 stages are occupied every tick.
 */
static WhipStats whip_process(const char *topology_source, int topology_len,
                               const char **paths, int path_count, int iterations) {
    WhipStats stats;
    memset(&stats, 0, sizeof(stats));

    Shard shards[SHARD_COUNT];
    memset(shards, 0, sizeof(shards));

    /* Pre-strip comments once */
    char cleaned[65536];
    int cleaned_len = strip_comments(topology_source, topology_len, cleaned);

    int cursor = 0;        /* next shard slot to use */
    int path_idx = 0;      /* next request to process */
    int total_requests = path_count * iterations;
    int requests_submitted = 0;

    while (stats.requests_completed < total_requests) {
        /* Advance all shards one stage (in reverse order to avoid conflicts) */

        /* Stage 3 → Done: collect Eve results */
        for (int s = 0; s < SHARD_COUNT; s++) {
            if (shards[s].stage == 3) {
                stats.requests_completed++;
                stats.total_original_bytes += shards[s].eve.original_len;
                stats.total_compressed_bytes += shards[s].eve.compressed_len;
                stats.codec_wins[shards[s].eve.codec_id]++;
                shards[s].stage = 0; /* free slot */
            }
        }

        /* Stage 2 → Stage 3: run Eve on handler output */
        for (int s = 0; s < SHARD_COUNT; s++) {
            if (shards[s].stage == 2) {
                if (shards[s].handler.route_matched) {
                    eve_compress(shards[s].handler.response,
                                shards[s].handler.response_len, &shards[s].eve);
                } else {
                    shards[s].eve.original_len = 0;
                    shards[s].eve.compressed_len = 0;
                    shards[s].eve.codec_id = 0;
                }
                shards[s].stage = 3;
            }
        }

        /* Stage 1 → Stage 2: run handler on Lilith output */
        for (int s = 0; s < SHARD_COUNT; s++) {
            if (shards[s].stage == 1) {
                handler_dispatch(&shards[s].lilith, shards[s].path, &shards[s].handler);
                shards[s].stage = 2;
            }
        }

        /* Submit new request → Stage 1: run Lilith */
        if (requests_submitted < total_requests) {
            /* Find a free shard slot */
            for (int s = 0; s < SHARD_COUNT; s++) {
                if (shards[s].stage == 0) {
                    int pi = path_idx % path_count;
                    strncpy(shards[s].path, paths[pi], 63);
                    shards[s].path[63] = 0;

                    /* Lilith compiles the topology */
                    lilith_compile(cleaned, cleaned_len, &shards[s].lilith);
                    shards[s].stage = 1;

                    path_idx++;
                    requests_submitted++;
                    break;
                }
            }
        }
    }

    return stats;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* CLI                                                                */
/* ═══════════════════════════════════════════════════════════════════ */

int main(int argc, char **argv) {
    int bench_iters = 100;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--bench") == 0 && i + 1 < argc) bench_iters = atoi(argv[++i]);
    }

    /* Server topology */
    const char *topology =
        "(accept: TCPListener { port: '8080' })\n"
        "(parse: RequestParser)\n"
        "(route: LocationRouter)\n"
        "(plaintext: Handler { path: '/plaintext' })\n"
        "(json_handler: Handler { path: '/json' })\n"
        "(respond: ResponseAssembler)\n"
        "(route)-[:FORK]->(plaintext | json_handler)\n"
        "(plaintext | json_handler)-[:RACE { failure: 'vent' }]->(respond)\n";
    int topology_len = strlen(topology);

    /* Request paths */
    const char *paths[] = { "/plaintext", "/json", "/plaintext", "/plaintext" };
    int path_count = 4;

    /* Warmup */
    whip_process(topology, topology_len, paths, path_count, 10);

    /* Benchmark */
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    WhipStats stats = whip_process(topology, topology_len, paths, path_count, bench_iters);
    clock_gettime(CLOCK_MONOTONIC, &t1);

    double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
    double us_total = ns / 1000.0;
    double us_per_req = us_total / stats.requests_completed;
    double ratio = stats.total_original_bytes > 0
        ? (double)stats.total_compressed_bytes / stats.total_original_bytes * 100.0
        : 100.0;

    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Lilith-Eve Worthington Whip: %d shards × 3 stages\n", SHARD_COUNT);
    printf("═══════════════════════════════════════════════════════════\n");
    printf("  Requests: %d\n", stats.requests_completed);
    printf("  Total time: %.1fus\n", us_total);
    printf("  Per request: %.1fus (Lilith compile + handler + Eve compress)\n", us_per_req);
    printf("  Wire ratio: %.1f%% (%d → %d bytes)\n",
        ratio, stats.total_original_bytes, stats.total_compressed_bytes);
    printf("  Codec wins: identity=%d gzip=%d deflate=%d\n",
        stats.codec_wins[0], stats.codec_wins[1], stats.codec_wins[2]);
    printf("  Throughput: %.0f req/sec (single-threaded)\n",
        stats.requests_completed / (us_total / 1e6));
    printf("═══════════════════════════════════════════════════════════\n");

    return 0;
}
