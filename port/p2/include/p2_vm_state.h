/* Private P2 native state. Ownership is by bvm, NEVER by physical cog ID.
 * Physical services (clock, SD, PSRAM/cache, locks) are not duplicated here. */
#ifndef P2_VM_STATE_H
#define P2_VM_STATE_H

#include "berry.h"
#include "p2_clock.h"
#include <stdint.h>

#define P2_TASK_MAX_TASKS 16
#define P2_TASK_MAX_EVENTS 16
#define P2_TASK_EVENT_MAX 31
#define P2_TASK_ERROR_MAX 63

typedef struct p2_task_slot {
    int status;
    int wait_kind;
    int runs;
    int wakeups;
    int woke_timeout;
    int wait_value;
    char wait_event[P2_TASK_EVENT_MAX + 1];
    char woke_event[P2_TASK_EVENT_MAX + 1];
    char last_error[P2_TASK_ERROR_MAX + 1];
    p2_deadline deadline;
} p2_task_slot;

typedef struct p2_task_state {
    /* Handles are reusable VM-local slot indices, NOT cross-VM capabilities.
     * The round-robin cursor and active task ID belong to this same VM. */
    p2_task_slot slots[P2_TASK_MAX_TASKS];
    int current;
    int next;
    char events[P2_TASK_MAX_EVENTS][P2_TASK_EVENT_MAX + 1];
} p2_task_state;

typedef struct p2_rng_state {
    uint32_t value;
} p2_rng_state;

typedef struct p2_vm_state {
    p2_task_state *scheduler;
    p2_rng_state *rng;
    /* Assigned under the managed cog registry lock, never derived from a VM
     * address. Callback is native-only: no allocation/scripts/hardware stop. */
    uint32_t cog_owner_cookie;
    void (*cog_owner_invalidate)(uint32_t cookie);
} p2_vm_state;

#define P2_RNG_DEFAULT_SEED UINT32_C(1357911)
#define P2_RNG_ZERO_SEED UINT32_C(0x6d2b79f5)

/* Lazy, VM-accounted allocations. May throw BE_MALLOC_FAIL through Berry's
 * real allocator. Failure leaves no unowned C allocations: context/feature
 * pointers are either NULL or fully initialized. Call in a protected VM path.
 * State lives through all GC/native finalizers; only VM deletion releases it.
 * C state holds no Berry pointers. Task closures/args/waits stay in VM roots. */
p2_vm_state *p2_vm_state_get(bvm *vm);
/* Lookup must not allocate (including on a rejected foreign handle). */
p2_vm_state *p2_vm_state_existing(bvm *vm);
p2_task_state *p2_vm_scheduler(bvm *vm);
p2_rng_state *p2_vm_rng(bvm *vm);
void p2_vm_srand(bvm *vm, uint32_t seed);
uint32_t p2_vm_rand(bvm *vm);

#endif
