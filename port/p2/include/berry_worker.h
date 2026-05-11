#ifndef BERRY_WORKER_P2_H
#define BERRY_WORKER_P2_H

#include <stddef.h>

#define BERRY_WORKER_NAME_MAX 31
#define BERRY_WORKER_ARGS_MAX 8
#define BERRY_WORKER_ERROR_MAX 96
#define BERRY_WORKER_SOURCE_MAX 2047

typedef enum berry_worker_command {
    BERRY_WORKER_CMD_NONE = 0,
    BERRY_WORKER_CMD_EXEC = 1,
    BERRY_WORKER_CMD_LOAD_STR = 2,
    BERRY_WORKER_CMD_LOAD_FILE = 3
} berry_worker_command;

typedef enum berry_worker_state {
    BERRY_WORKER_STOPPED = 0,
    BERRY_WORKER_BOOTING = 1,
    BERRY_WORKER_READY = 2,
    BERRY_WORKER_REQUEST = 3,
    BERRY_WORKER_RUNNING = 4,
    BERRY_WORKER_ERROR = 5
} berry_worker_state;

typedef struct berry_worker_mailbox {
    volatile int state;
    volatile int command;
    char name[BERRY_WORKER_NAME_MAX + 1];
    int argc;
    int argv[BERRY_WORKER_ARGS_MAX];
    char source[BERRY_WORKER_SOURCE_MAX + 1];
    char error[BERRY_WORKER_ERROR_MAX];
} berry_worker_mailbox;

typedef struct berry_worker_boot {
    berry_worker_mailbox *mailbox;
    void *heap_base;
    size_t heap_size;
    volatile int worker_cog;
} berry_worker_boot;

int berry_worker_start_cog(const char **error);
int berry_worker_load_str(const char *source, const char **error);
int berry_worker_load_file(const char *path, const char **error);
int berry_worker_exec_ints(const char *name, int argc, const int *argv, const char **error);
void berry_worker_stop_cog(void);
int berry_worker_cog_id(void);
int berry_worker_mailbox_state(void);
const char *berry_worker_state_name(int state);
const char *berry_worker_last_error(void);

#endif
