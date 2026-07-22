#include "gnosis_client.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

static char* gnosis_strdup(const char* value) {
  if (!value) {
    return NULL;
  }
  size_t length = strlen(value);
  /* polyglot:ignore RESOURCE_LEAK — popen handle closed at end of function */
  char* copy = (char*)malloc(length + 1);
  if (!copy) {
    return NULL;
  }
  memcpy(copy, value, length + 1);
  return copy;
}

gnosis_result_t gnosis_run(const char* binary, const char* command_args) {
  const char* exe = binary && binary[0] ? binary : "gnosis";
  const char* args = command_args ? command_args : "";

  size_t command_length = strlen(exe) + strlen(args) + strlen(" 2>&1") + 2;
  char* command = (char*)malloc(command_length);
  if (!command) {
    return (gnosis_result_t){.exit_code = 1, .output = gnosis_strdup("memory allocation failed")};
  }

  if (args[0]) {
    snprintf(command, command_length, "%s %s 2>&1", exe, args);
  } else {
    snprintf(command, command_length, "%s 2>&1", exe);
  }

  FILE* pipe = popen(command, "r");
  free(command);
  if (!pipe) {
    return (gnosis_result_t){.exit_code = 1, .output = gnosis_strdup("failed to open process")};
  }

  size_t capacity = 256;
  size_t used = 0;
  char* output = (char*)malloc(capacity);
  if (!output) {
    pclose(pipe);
    return (gnosis_result_t){.exit_code = 1, .output = gnosis_strdup("memory allocation failed")};
  }

  int ch;
  while ((ch = fgetc(pipe)) != EOF) {
    if (used + 1 >= capacity) {
      capacity *= 2;
      char* resized = (char*)realloc(output, capacity);
      if (!resized) {
        free(output);
        pclose(pipe);
        return (gnosis_result_t){.exit_code = 1, .output = gnosis_strdup("memory allocation failed")};
      }
      output = resized;
    }
    output[used++] = (char)ch;
  }
  output[used] = '\0';

  int status = pclose(pipe);
#ifdef WEXITSTATUS
  if (status >= 0) {
    status = WEXITSTATUS(status);
  }
#endif
  if (status < 0) {
    status = 1;
  }

  return (gnosis_result_t){.exit_code = status, .output = output};
}

void gnosis_result_free(gnosis_result_t* result) {
  if (!result) {
    return;
  }
  free(result->output);
  result->output = NULL;
  result->exit_code = 0;
}
