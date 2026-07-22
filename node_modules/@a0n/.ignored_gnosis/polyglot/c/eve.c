/*
 * eve.c -- Response rotation daemon. Lilith's antiparallel pair.
 *
 * Lilith compiles input (topology bytes → structure).
 * Eve compresses output (structure → wire bytes).
 *
 * Architecture:
 *   Accumulate small responses into chunks.
 *   FORK each chunk to 4 codecs (identity, gzip, deflate, brotli).
 *   RACE: smallest output wins.
 *   Send the winner. VENT the losers.
 *
 * Wallington rotation: while codec-racing chunk N, accumulating chunk N+1,
 * sending chunk N-1. The pipeline stays full.
 *
 * Build: cc -O3 -march=native -o eve eve.c -lz
 * (links against zlib for gzip/deflate; brotli optional)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <zlib.h>

#define CHUNK_SIZE 65536       /* 64KB per chunk */
#define MAX_RESPONSES 256      /* max responses per chunk */
#define CODEC_COUNT 3          /* identity, gzip, deflate (brotli needs separate lib) */

/* ═══════════════════════════════════════════════════════════════════ */
/* Codec implementations                                              */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    unsigned char *data;
    int len;
    int codec_id;   /* 0=identity, 1=gzip, 2=deflate */
} CodecResult;

/* Identity: no compression, zero cost */
static CodecResult codec_identity(const unsigned char *input, int input_len) {
    CodecResult r;
    r.data = (unsigned char *)input; /* no copy needed */
    r.len = input_len;
    r.codec_id = 0;
    return r;
}

/* Gzip via zlib */
static CodecResult codec_gzip(const unsigned char *input, int input_len) {
    CodecResult r;
    r.codec_id = 1;
    uLong bound = compressBound(input_len);
    r.data = malloc(bound);
    if (!r.data) { r.len = input_len + 1; return r; } /* fail = bigger than identity */

    z_stream strm;
    memset(&strm, 0, sizeof(strm));
    /* windowBits = 15 + 16 for gzip header */
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        free(r.data); r.data = NULL; r.len = input_len + 1; return r;
    }
    strm.next_in = (unsigned char *)input;
    strm.avail_in = input_len;
    strm.next_out = r.data;
    strm.avail_out = bound;
    deflate(&strm, Z_FINISH);
    r.len = strm.total_out;
    deflateEnd(&strm);
    return r;
}

/* Deflate via zlib (raw, no gzip header) */
static CodecResult codec_deflate(const unsigned char *input, int input_len) {
    CodecResult r;
    r.codec_id = 2;
    uLong bound = compressBound(input_len);
    r.data = malloc(bound);
    if (!r.data) { r.len = input_len + 1; return r; }

    z_stream strm;
    memset(&strm, 0, sizeof(strm));
    /* windowBits = -15 for raw deflate (no header) */
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        free(r.data); r.data = NULL; r.len = input_len + 1; return r;
    }
    strm.next_in = (unsigned char *)input;
    strm.avail_in = input_len;
    strm.next_out = r.data;
    strm.avail_out = bound;
    deflate(&strm, Z_FINISH);
    r.len = strm.total_out;
    deflateEnd(&strm);
    return r;
}

static const char *codec_name(int id) {
    switch (id) {
        case 0: return "identity";
        case 1: return "gzip";
        case 2: return "deflate";
        default: return "unknown";
    }
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Chunk: accumulate small responses                                  */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    unsigned char data[CHUNK_SIZE];
    int len;
    int response_count;
} Chunk;

static void chunk_init(Chunk *c) {
    c->len = 0;
    c->response_count = 0;
}

static int chunk_add(Chunk *c, const unsigned char *response, int response_len) {
    if (c->len + response_len > CHUNK_SIZE) return 0; /* chunk full */
    memcpy(c->data + c->len, response, response_len);
    c->len += response_len;
    c->response_count++;
    return 1;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Eve: FORK(codecs) → RACE(smallest) → send                         */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    int winner_codec;
    int winner_len;
    int original_len;
    double ratio;
    int response_count;
} EveResult;

static EveResult eve_race_chunk(const Chunk *chunk) {
    /* FORK: race all codecs on this chunk */
    CodecResult results[CODEC_COUNT];
    results[0] = codec_identity(chunk->data, chunk->len);
    results[1] = codec_gzip(chunk->data, chunk->len);
    results[2] = codec_deflate(chunk->data, chunk->len);

    /* RACE: smallest wins */
    int winner = 0;
    for (int i = 1; i < CODEC_COUNT; i++) {
        if (results[i].len < results[winner].len) winner = i;
    }

    EveResult r;
    r.winner_codec = results[winner].codec_id;
    r.winner_len = results[winner].len;
    r.original_len = chunk->len;
    r.ratio = chunk->len > 0 ? (double)results[winner].len / chunk->len : 1.0;
    r.response_count = chunk->response_count;

    /* VENT: free losers */
    for (int i = 0; i < CODEC_COUNT; i++) {
        if (i != winner && results[i].codec_id != 0 && results[i].data) {
            free(results[i].data);
        }
    }
    /* Also free winner if not identity (it was malloc'd) */
    if (results[winner].codec_id != 0 && results[winner].data) {
        free(results[winner].data);
    }

    return r;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* Wallington rotation: pipeline chunks through stages                */
/* ═══════════════════════════════════════════════════════════════════ */

typedef struct {
    int chunks_processed;
    int total_original;
    int total_compressed;
    int codec_wins[CODEC_COUNT];
    int total_responses;
} EveStats;

/*
 * Process a stream of small responses through Eve's rotation:
 *   Stage 1: Accumulate responses into chunk
 *   Stage 2: FORK/RACE codecs on full chunk
 *   Stage 3: Send winner (simulated -- just track stats)
 */
static EveStats eve_process(const unsigned char **responses, const int *response_lens,
                            int response_count) {
    EveStats stats;
    memset(&stats, 0, sizeof(stats));

    Chunk current;
    chunk_init(&current);

    for (int i = 0; i < response_count; i++) {
        if (!chunk_add(&current, responses[i], response_lens[i])) {
            /* Chunk full -- race it */
            EveResult r = eve_race_chunk(&current);
            stats.chunks_processed++;
            stats.total_original += r.original_len;
            stats.total_compressed += r.winner_len;
            stats.codec_wins[r.winner_codec]++;
            stats.total_responses += r.response_count;

            /* Start new chunk with this response */
            chunk_init(&current);
            chunk_add(&current, responses[i], response_lens[i]);
        }
    }

    /* Flush remaining chunk */
    if (current.len > 0) {
        EveResult r = eve_race_chunk(&current);
        stats.chunks_processed++;
        stats.total_original += r.original_len;
        stats.total_compressed += r.winner_len;
        stats.codec_wins[r.winner_codec]++;
        stats.total_responses += r.response_count;
    }

    return stats;
}

/* ═══════════════════════════════════════════════════════════════════ */
/* CLI: benchmark Eve on simulated TechEmpower responses              */
/* ═══════════════════════════════════════════════════════════════════ */

int main(int argc, char **argv) {
    int bench_iters = 1000;
    int response_count = 1000;
    int response_size = 13; /* "Hello, World!" */

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--bench") == 0 && i + 1 < argc) bench_iters = atoi(argv[++i]);
        else if (strcmp(argv[i], "--responses") == 0 && i + 1 < argc) response_count = atoi(argv[++i]);
        else if (strcmp(argv[i], "--size") == 0 && i + 1 < argc) response_size = atoi(argv[++i]);
    }

    /* Generate simulated responses */
    unsigned char *response = malloc(response_size);
    memset(response, 'A', response_size);
    if (response_size >= 13) memcpy(response, "Hello, World!", 13);

    const unsigned char **responses = malloc(sizeof(unsigned char *) * response_count);
    int *response_lens = malloc(sizeof(int) * response_count);
    for (int i = 0; i < response_count; i++) {
        responses[i] = response;
        response_lens[i] = response_size;
    }

    /* Warmup */
    for (int i = 0; i < 10; i++) {
        eve_process(responses, response_lens, response_count);
    }

    /* Benchmark */
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    EveStats last_stats;
    for (int i = 0; i < bench_iters; i++) {
        last_stats = eve_process(responses, response_lens, response_count);
    }
    clock_gettime(CLOCK_MONOTONIC, &t1);

    double ns = (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
    double us_per_iter = ns / bench_iters / 1000.0;
    double ratio = last_stats.total_original > 0
        ? (double)last_stats.total_compressed / last_stats.total_original * 100.0
        : 100.0;

    printf("Eve response rotation benchmark\n");
    printf("  %d responses x %d bytes = %d bytes/batch\n",
        response_count, response_size, response_count * response_size);
    printf("  Chunks: %d (%.0f responses/chunk)\n",
        last_stats.chunks_processed,
        last_stats.chunks_processed > 0 ? (double)response_count / last_stats.chunks_processed : 0);
    printf("  Wire ratio: %.1f%% (%d → %d bytes)\n",
        ratio, last_stats.total_original, last_stats.total_compressed);
    printf("  Codec wins: identity=%d gzip=%d deflate=%d\n",
        last_stats.codec_wins[0], last_stats.codec_wins[1], last_stats.codec_wins[2]);
    printf("  %.1fus/batch | %d iterations\n", us_per_iter, bench_iters);
    printf("  %.1fns/response\n", us_per_iter * 1000.0 / response_count);

    free(response);
    free(responses);
    free(response_lens);
    return 0;
}
