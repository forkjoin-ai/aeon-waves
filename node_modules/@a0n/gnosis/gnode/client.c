/*
 * gnode client -- native C client for the gnode daemon.
 *
 * Eliminates the 59ms Node startup overhead for daemon communication.
 * Connects to Unix socket, sends request, prints response.
 *
 * Build: cc -O2 -o gnode-client client.c
 * Usage: ./gnode-client echo.ts '{"name":"test"}'
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>

#define SOCKET_PATH "/tmp/gnode.sock"
#define BUF_SIZE 65536

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: gnode-client <script.ts> [inputJson]\n");
        return 1;
    }

    const char *script = argv[1];
    const char *input = argc > 2 ? argv[2] : "{}";

    /* Connect to daemon */
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) { perror("socket"); return 1; }

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        fprintf(stderr, "gnode-client: daemon not running (start: node gnode/daemon.mjs &)\n");
        close(fd);
        return 1;
    }

    /* Build and send request */
    char request[BUF_SIZE];
    int len = snprintf(request, sizeof(request),
        "{\"script\":\"%s\",\"inputJson\":\"%s\"}\n",
        script, input);

    /* Escape the inputJson properly */
    /* Simple version: just send the raw JSON */
    len = snprintf(request, sizeof(request),
        "{\"script\":\"%s\",\"inputJson\":%s}\n",
        script, input);

    write(fd, request, len);

    /* Shutdown write side to signal end of request */
    shutdown(fd, SHUT_WR);

    /* Read response */
    char response[BUF_SIZE];
    int total = 0;
    int n;
    while ((n = read(fd, response + total, sizeof(response) - total - 1)) > 0) {
        total += n;
    }
    response[total] = 0;

    close(fd);

    /* Parse and print stdout from response */
    /* Look for "stdout":" in the JSON response */
    char *stdout_start = strstr(response, "\"stdout\":\"");
    if (stdout_start) {
        stdout_start += 10; /* skip "stdout":" */
        char *stdout_end = strstr(stdout_start, "\"");
        if (stdout_end) {
            /* Unescape \n */
            for (char *p = stdout_start; p < stdout_end; p++) {
                if (*p == '\\' && *(p+1) == 'n') { putchar('\n'); p++; }
                else putchar(*p);
            }
        }
    } else {
        /* No JSON wrapper -- print raw */
        printf("%s", response);
    }

    return 0;
}
