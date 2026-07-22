#ifndef GNOSIS_CLIENT_H
#define GNOSIS_CLIENT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct gnosis_result {
  int exit_code;
  char* output;
} gnosis_result_t;

gnosis_result_t gnosis_run(const char* binary, const char* command_args);
void gnosis_result_free(gnosis_result_t* result);

#ifdef __cplusplus
}
#endif

#endif
