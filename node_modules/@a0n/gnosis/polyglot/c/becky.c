/*
 * becky.c -- GG compiler in C.
 *
 * Same two-sweep architecture. Hand-rolled scanner, no regex library.
 * Minimal allocations. Fixed-size buffers where possible.
 *
 * Usage:
 *   ./becky-c betti.gg
 *   ./becky-c --beta1 betti.gg
 *   ./becky-c --summary betti.gg
 *   ./becky-c --bench 100000 betti.gg
 *
 * Build:
 *   cc -O3 -o becky-c becky.c -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <ctype.h>

#define MAX_NODES 1024
#define MAX_EDGES 1024
#define MAX_LABELS 4
#define MAX_PROPS 16
#define MAX_IDS 16
#define MAX_ID_LEN 128
#define MAX_DIAGS 256

/* ═══════════════════════════════════════════════════════════════════════════ */
/* Types                                                                      */
/* ═══════════════════════════════════════════════════════════════════════════ */

typedef struct {
    char key[64];
    char value[256];
} Property;

typedef struct {
    char id[MAX_ID_LEN];
    char labels[MAX_LABELS][MAX_ID_LEN];
    int label_count;
    Property props[MAX_PROPS];
    int prop_count;
} GgNode;

typedef struct {
    char source_ids[MAX_IDS][MAX_ID_LEN];
    int source_count;
    char target_ids[MAX_IDS][MAX_ID_LEN];
    int target_count;
    char edge_type[32];
    Property props[MAX_PROPS];
    int prop_count;
} GgEdge;

typedef struct {
    char code[64];
    char message[256];
    char severity[16];
} Diagnostic;

typedef struct {
    GgNode nodes[MAX_NODES];
    int node_count;
    GgEdge edges[MAX_EDGES];
    int edge_count;
} GgProgram;

typedef struct {
    GgProgram program;
    int beta1;
    Diagnostic diagnostics[MAX_DIAGS];
    int diag_count;
    int void_dimensions;
    double landauer_heat;
    int total_deficit;
} BeckyResult;

/* ═══════════════════════════════════════════════════════════════════════════ */
/* Helpers                                                                    */
/* ═══════════════════════════════════════════════════════════════════════════ */

static char* read_file(const char* path) {
    FILE* f = fopen(path, "r");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = malloc(len + 1);
    if (!buf) { fclose(f); return NULL; }
    fread(buf, 1, len, f);
    buf[len] = 0;
    fclose(f);
    return buf;
}

static void trim(char* s) {
    char* start = s;
    while (*start && isspace(*start)) start++;
    if (start != s) memmove(s, start, strlen(start) + 1);
    char* end = s + strlen(s) - 1;
    while (end > s && isspace(*end)) *end-- = 0;
}

static void strip_quotes(char* s) {
    int len = strlen(s);
    if (len >= 2 && ((s[0] == '\'' && s[len-1] == '\'') || (s[0] == '"' && s[len-1] == '"'))) {
        memmove(s, s + 1, len - 2);
        s[len - 2] = 0;
    }
}

static int find_node(GgProgram* prog, const char* id) {
    for (int i = 0; i < prog->node_count; i++) {
        if (strcmp(prog->nodes[i].id, id) == 0) return i;
    }
    return -1;
}

static int ensure_node(GgProgram* prog, const char* id) {
    int idx = find_node(prog, id);
    if (idx >= 0) return idx;
    if (prog->node_count >= MAX_NODES) return -1;
    idx = prog->node_count++;
    strncpy(prog->nodes[idx].id, id, MAX_ID_LEN - 1);
    prog->nodes[idx].label_count = 0;
    prog->nodes[idx].prop_count = 0;
    return idx;
}

static void parse_props_into(const char* raw, Property* props, int* count) {
    if (!raw || !*raw) return;
    const char* p = raw;
    while (*p && *count < MAX_PROPS) {
        while (*p && isspace(*p)) p++;
        if (!*p) break;
        const char* comma = strchr(p, ',');
        if (!comma) comma = p + strlen(p);

        /* Extract this segment */
        char seg[512];
        int slen = comma - p;
        if (slen >= (int)sizeof(seg)) slen = sizeof(seg) - 1;
        memcpy(seg, p, slen);
        seg[slen] = 0;

        char* colon = strchr(seg, ':');
        if (colon) {
            *colon = 0;
            char* key = seg;
            char* val = colon + 1;
            trim(key);
            trim(val);
            strip_quotes(val);
            if (*key && *val) {
                strncpy(props[*count].key, key, 63);
                props[*count].key[63] = 0;
                strncpy(props[*count].value, val, 255);
                props[*count].value[255] = 0;
                (*count)++;
            }
        }
        p = (*comma == ',') ? comma + 1 : comma;
    }
}

/* Split "a | b | c" into IDs, extracting just the id part (before : or {) */
static int split_pipe(const char* raw, char ids[][MAX_ID_LEN], int max) {
    int count = 0;
    const char* p = raw;
    while (*p && count < max) {
        /* Skip whitespace */
        while (*p && isspace(*p)) p++;
        if (!*p) break;

        /* Find end of this segment (next | or end of string) */
        const char* seg_end = strchr(p, '|');
        if (!seg_end) seg_end = p + strlen(p);

        /* Copy segment */
        char seg[MAX_ID_LEN];
        int slen = seg_end - p;
        if (slen >= MAX_ID_LEN) slen = MAX_ID_LEN - 1;
        memcpy(seg, p, slen);
        seg[slen] = 0;
        trim(seg);

        /* Remove surrounding parens */
        char* s = seg;
        if (*s == '(') s++;
        int sl = strlen(s);
        if (sl > 0 && s[sl-1] == ')') s[sl-1] = 0;

        /* Extract ID (before : or {) */
        char id[MAX_ID_LEN];
        strncpy(id, s, MAX_ID_LEN - 1);
        id[MAX_ID_LEN - 1] = 0;
        char* c = strchr(id, ':');
        if (c) *c = 0;
        c = strchr(id, '{');
        if (c) *c = 0;
        trim(id);
        if (*id) {
            strncpy(ids[count], id, MAX_ID_LEN - 1);
            ids[count][MAX_ID_LEN - 1] = 0;
            count++;
        }

        p = (*seg_end == '|') ? seg_end + 1 : seg_end;
    }
    return count;
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* Parser                                                                     */
/* ═══════════════════════════════════════════════════════════════════════════ */

static void parse_gg(const char* source, GgProgram* prog) {
    prog->node_count = 0;
    prog->edge_count = 0;

    /* Work on a copy */
    size_t len = strlen(source);
    char* buf = malloc(len + 1);
    memcpy(buf, source, len + 1);

    /* Strip comments */
    char* lines[8192];
    int line_count = 0;
    /* Split lines manually (strtok is not reentrant) */
    char* lp = buf;
    while (*lp && line_count < 8192) {
        char* eol = strchr(lp, '\n');
        if (eol) *eol = 0;
        /* Strip // comments */
        char* comment = strstr(lp, "//");
        if (comment) *comment = 0;
        /* Trim leading whitespace */
        while (*lp && isspace(*lp)) lp++;
        if (*lp) {
            lines[line_count++] = lp;
        }
        if (eol) lp = eol + 1;
        else break;
    }

    /* Rebuild cleaned source for edge scanning (fresh allocation, no shared pointers) */
    size_t cleaned_len = 0;
    for (int i = 0; i < line_count; i++) cleaned_len += strlen(lines[i]) + 1;
    char* cleaned = malloc(cleaned_len + 1);
    char* wp = cleaned;
    for (int i = 0; i < line_count; i++) {
        size_t ll = strlen(lines[i]);
        memcpy(wp, lines[i], ll);
        wp += ll;
        *wp++ = '\n';
    }
    *wp = 0;

    /* Sweep 1: edges -- scan for )-[: pattern */
    const char* p = cleaned;
    while (*p) {
        /* Find )-[: */
        const char* marker = strstr(p, ")-[:");
        if (!marker) break;

        /* Backtrack to find source ( */
        const char* src_end = marker;
        const char* src_start = marker;
        int depth = 0;
        for (const char* q = marker - 1; q >= cleaned; q--) {
            if (*q == ')') depth++;
            else if (*q == '(') {
                if (depth == 0) { src_start = q + 1; break; }
                depth--;
            }
        }

        /* Extract edge type + props: [:TYPE {props}]-> */
        const char* rel_start = marker + 3; /* after )-[ */
        const char* bracket_end = strchr(rel_start, ']');
        if (!bracket_end) { p = marker + 1; continue; }

        char rel_content[512];
        int rel_len = bracket_end - rel_start;
        if (rel_len >= (int)sizeof(rel_content)) rel_len = sizeof(rel_content) - 1;
        memcpy(rel_content, rel_start, rel_len);
        rel_content[rel_len] = 0;

        /* Skip leading : */
        char* rc = rel_content;
        if (*rc == ':') rc++;

        char edge_type[32] = {0};
        char edge_props_raw[256] = {0};
        char* brace = strchr(rc, '{');
        if (brace) {
            int etype_len = brace - rc;
            strncpy(edge_type, rc, etype_len);
            edge_type[etype_len] = 0;
            trim(edge_type);
            char* brace_end = strchr(brace, '}');
            if (brace_end) {
                int plen = brace_end - brace - 1;
                strncpy(edge_props_raw, brace + 1, plen);
                edge_props_raw[plen] = 0;
            }
        } else {
            strncpy(edge_type, rc, sizeof(edge_type) - 1);
            trim(edge_type);
        }

        /* Find target: ]->(...) */
        const char* arrow = bracket_end + 1;
        if (arrow[0] != '-' || arrow[1] != '>') { p = marker + 1; continue; }
        const char* tgt_open = strchr(arrow + 2, '(');
        if (!tgt_open) { p = marker + 1; continue; }

        depth = 0;
        const char* tgt_close = tgt_open;
        for (const char* q = tgt_open; *q; q++) {
            if (*q == '(') depth++;
            else if (*q == ')') {
                depth--;
                if (depth == 0) { tgt_close = q; break; }
            }
        }

        /* Extract source and target raw strings */
        char source_raw[512], target_raw[512];
        int slen = src_end - src_start;
        if (slen >= (int)sizeof(source_raw)) slen = sizeof(source_raw) - 1;
        memcpy(source_raw, src_start, slen);
        source_raw[slen] = 0;

        int tlen = tgt_close - tgt_open - 1;
        if (tlen >= (int)sizeof(target_raw)) tlen = sizeof(target_raw) - 1;
        memcpy(target_raw, tgt_open + 1, tlen);
        target_raw[tlen] = 0;

        /* Add edge */
        if (prog->edge_count < MAX_EDGES) {
            GgEdge* e = &prog->edges[prog->edge_count];
            e->source_count = split_pipe(source_raw, e->source_ids, MAX_IDS);
            e->target_count = split_pipe(target_raw, e->target_ids, MAX_IDS);
            strncpy(e->edge_type, edge_type, sizeof(e->edge_type) - 1);
            e->prop_count = 0;
            parse_props_into(edge_props_raw, e->props, &e->prop_count);

            /* Ensure nodes exist */
            for (int i = 0; i < e->source_count; i++) ensure_node(prog, e->source_ids[i]);
            for (int i = 0; i < e->target_count; i++) ensure_node(prog, e->target_ids[i]);

            prog->edge_count++;
        }

        p = tgt_close + 1;
    }

    /* Sweep 2: standalone node declarations */
    for (int i = 0; i < line_count; i++) {
        if (strstr(lines[i], "-[:")) continue;

        const char* lp = lines[i];
        while (*lp) {
            if (*lp == '(') {
                const char* start = lp + 1;
                int depth = 1;
                const char* end = start;
                while (*end && depth > 0) {
                    if (*end == '(') depth++;
                    else if (*end == ')') depth--;
                    if (depth > 0) end++;
                }
                if (depth == 0) {
                    char inner[512];
                    int ilen = end - start;
                    if (ilen >= (int)sizeof(inner)) ilen = sizeof(inner) - 1;
                    memcpy(inner, start, ilen);
                    inner[ilen] = 0;

                    if (!strchr(inner, '|')) {
                        /* Parse: id:Label {props} */
                        char id[MAX_ID_LEN] = {0};
                        char label[MAX_ID_LEN] = {0};
                        char props_raw[256] = {0};

                        char* brace = strchr(inner, '{');
                        char* brace_end = brace ? strchr(brace, '}') : NULL;
                        if (brace && brace_end) {
                            int plen = brace_end - brace - 1;
                            strncpy(props_raw, brace + 1, plen);
                            props_raw[plen] = 0;
                            *brace = 0; /* truncate for id:label parsing */
                        }

                        char* colon = strchr(inner, ':');
                        if (colon) {
                            *colon = 0;
                            strncpy(id, inner, MAX_ID_LEN - 1);
                            strncpy(label, colon + 1, MAX_ID_LEN - 1);
                            trim(id);
                            trim(label);
                        } else {
                            strncpy(id, inner, MAX_ID_LEN - 1);
                            trim(id);
                        }

                        if (*id) {
                            int idx = ensure_node(prog, id);
                            if (idx >= 0 && *label && prog->nodes[idx].label_count == 0) {
                                strncpy(prog->nodes[idx].labels[0], label, MAX_ID_LEN - 1);
                                prog->nodes[idx].label_count = 1;
                            }
                            if (idx >= 0 && *props_raw) {
                                parse_props_into(props_raw, prog->nodes[idx].props, &prog->nodes[idx].prop_count);
                            }
                        }
                    }
                    lp = end + 1;
                } else {
                    lp++;
                }
            } else {
                lp++;
            }
        }
    }

    free(cleaned);
    free(buf);
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* Analysis                                                                   */
/* ═══════════════════════════════════════════════════════════════════════════ */

static int compute_beta1(GgProgram* prog) {
    int b1 = 0;
    for (int i = 0; i < prog->edge_count; i++) {
        GgEdge* e = &prog->edges[i];
        if (strcmp(e->edge_type, "FORK") == 0) {
            b1 += e->target_count - 1;
        } else if (strcmp(e->edge_type, "FOLD") == 0 || strcmp(e->edge_type, "COLLAPSE") == 0 || strcmp(e->edge_type, "OBSERVE") == 0) {
            b1 -= e->source_count - 1;
            if (b1 < 0) b1 = 0;
        } else if (strcmp(e->edge_type, "RACE") == 0 || strcmp(e->edge_type, "SLIVER") == 0) {
            int diff = e->source_count - e->target_count;
            if (diff < 0) diff = 0;
            b1 -= diff;
            if (b1 < 0) b1 = 0;
        } else if (strcmp(e->edge_type, "VENT") == 0) {
            b1--;
            if (b1 < 0) b1 = 0;
        }
    }
    return b1;
}

static BeckyResult* compile_gg(const char* source) {
    BeckyResult* result = calloc(1, sizeof(BeckyResult));
    if (!result) return NULL;

    parse_gg(source, &result->program);
    result->beta1 = compute_beta1(&result->program);

    /* Void dimensions */
    for (int i = 0; i < result->program.edge_count; i++) {
        if (strcmp(result->program.edges[i].edge_type, "FORK") == 0)
            result->void_dimensions += result->program.edges[i].target_count;
    }

    /* Landauer heat */
    for (int i = 0; i < result->program.edge_count; i++) {
        GgEdge* e = &result->program.edges[i];
        if ((strcmp(e->edge_type, "FOLD") == 0 || strcmp(e->edge_type, "COLLAPSE") == 0 || strcmp(e->edge_type, "OBSERVE") == 0) && e->source_count > 1) {
            result->landauer_heat += log2((double)e->source_count);
        }
    }

    /* Deficit */
    int* out_branching = calloc(MAX_NODES, sizeof(int));
    int* in_merging = calloc(MAX_NODES, sizeof(int));
    for (int i = 0; i < result->program.edge_count; i++) {
        GgEdge* e = &result->program.edges[i];
        for (int s = 0; s < e->source_count; s++) {
            int idx = find_node(&result->program, e->source_ids[s]);
            if (idx >= 0) out_branching[idx] += e->target_count;
        }
        for (int t = 0; t < e->target_count; t++) {
            int idx = find_node(&result->program, e->target_ids[t]);
            if (idx >= 0) in_merging[idx] += e->source_count;
        }
    }
    for (int i = 0; i < result->program.node_count; i++) {
        int d = out_branching[i] - in_merging[i];
        if (d < 0) d = -d;
        result->total_deficit += d;
    }
    free(out_branching);
    free(in_merging);

    return result;
}

/* ═══════════════════════════════════════════════════════════════════════════ */
/* CLI                                                                        */
/* ═══════════════════════════════════════════════════════════════════════════ */

int main(int argc, char** argv) {
    int beta1_only = 0, summary = 0, bench_iters = 0;
    const char* filepath = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--beta1") == 0) beta1_only = 1;
        else if (strcmp(argv[i], "--summary") == 0) summary = 1;
        else if (strcmp(argv[i], "--bench") == 0 && i + 1 < argc) bench_iters = atoi(argv[++i]);
        else filepath = argv[i];
    }

    if (!filepath) {
        fprintf(stderr, "usage: becky-c [--beta1|--summary|--bench N] <file.gg>\n");
        return 1;
    }

    char* source = read_file(filepath);
    if (!source) {
        fprintf(stderr, "becky-c: cannot read %s\n", filepath);
        return 1;
    }

    if (bench_iters > 0) {
        /* Warmup */
        for (int i = 0; i < 10; i++) { BeckyResult* w = compile_gg(source); free(w); }

        struct timespec start, end;
        clock_gettime(CLOCK_MONOTONIC, &start);
        for (int i = 0; i < bench_iters; i++) {
            BeckyResult* w = compile_gg(source); free(w);
        }
        clock_gettime(CLOCK_MONOTONIC, &end);

        double ns = (end.tv_sec - start.tv_sec) * 1e9 + (end.tv_nsec - start.tv_nsec);
        double us_per_iter = ns / bench_iters / 1000.0;

        BeckyResult* r = compile_gg(source);
        printf("%.1fus/iter | %d iterations | %d nodes %d edges | b1=%d | %d diag | void=%d heat=%.3f deficit=%d\n",
            us_per_iter, bench_iters,
            r->program.node_count, r->program.edge_count,
            r->beta1, r->diag_count,
            r->void_dimensions, r->landauer_heat, r->total_deficit);
        free(source);
        return 0;
    }

    BeckyResult* r = compile_gg(source);

    if (beta1_only) {
        printf("%d\n", r->beta1);
    } else if (summary) {
        printf("%s: %d nodes, %d edges, b1=%d, %d diagnostics, void=%d, heat=%.3f, deficit=%d\n",
            filepath, r->program.node_count, r->program.edge_count,
            r->beta1, r->diag_count,
            r->void_dimensions, r->landauer_heat, r->total_deficit);
    } else {
        /* JSON-ish output */
        printf("{\"nodes\":%d,\"edges\":%d,\"beta1\":%d,\"diagnostics\":%d,\"void_dimensions\":%d,\"landauer_heat\":%.3f,\"total_deficit\":%d}\n",
            r->program.node_count, r->program.edge_count,
            r->beta1, r->diag_count,
            r->void_dimensions, r->landauer_heat, r->total_deficit);
    }

    free(source);
    return 0;
}
