#ifndef BERRY_WORKER_P2_H
#define BERRY_WORKER_P2_H

#include <stddef.h>

#define BERRY_WORKER_NAME_MAX 31
#define BERRY_WORKER_ARGS_MAX 8
#define BERRY_WORKER_ERROR_MAX 96

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
    char name[BERRY_WORKER_NAME_MAX + 1];
    int argc;
    int argv[BERRY_WORKER_ARGS_MAX];
    char error[BERRY_WORKER_ERROR_MAX];
} berry_worker_mailbox;

typedef struct berry_worker_boot {
    berry_worker_mailbox *mailbox;
    void *heap_base;
    size_t heap_size;
    volatile int worker_cog;
} berry_worker_boot;

#endif
