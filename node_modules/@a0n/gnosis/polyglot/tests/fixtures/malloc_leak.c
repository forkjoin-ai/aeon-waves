// Bug: memory leak -- malloc without free on error path.
#include <stdlib.h>
#include <string.h>

char* duplicate(const char* input) {
    char* buf = malloc(strlen(input) + 1);
    if (buf == NULL) {
        return NULL;
    }
    strcpy(buf, input);
    if (strlen(buf) == 0) {
        // BUG: buf not freed before early return
        return NULL;
    }
    return buf;
}
