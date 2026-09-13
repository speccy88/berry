/* VM-owned native allocations. No shared-VM synchronization is provided.
 * Existing full-program runtime locking remains required and unchanged. */
#include "p2_vm_state.h"
#include "be_mem.h"
#include "be_vm.h"
#include <string.h>

static void p2_vm_state_delete(bvm *vm, void *context)
{
    p2_vm_state *state = (p2_vm_state *)context;
    /* After native finalizers, before memory pools are freed. Never inspect
     * Berry objects, execute scripts, allocate, or raise from this callback. */
    if (state) {
        if (state->cog_owner_cookie && state->cog_owner_invalidate) {
            state->cog_owner_invalidate(state->cog_owner_cookie);
            state->cog_owner_cookie = 0;
        }
        if (state->scheduler) {
            be_free(vm, state->scheduler, sizeof(p2_task_state));
        }
        if (state->rng) {
            be_free(vm, state->rng, sizeof(p2_rng_state));
        }
        be_free(vm, state, sizeof(p2_vm_state));
    }
}

p2_vm_state *p2_vm_state_existing(bvm *vm)
{
    return (p2_vm_state *)vm->native_context;
}

p2_vm_state *p2_vm_state_get(bvm *vm)
{
    p2_vm_state *state = (p2_vm_state *)vm->native_context;
    if (!state) {
        state = (p2_vm_state *)be_malloc(vm, sizeof(p2_vm_state));
        /* be_malloc may run GC, including common-object native finalizers.
         * A finalizer may have installed this state during allocation retry.
         * Keep the published allocation and release our redundant one. */
        if (vm->native_context) {
            be_free(vm, state, sizeof(p2_vm_state));
            return (p2_vm_state *)vm->native_context;
        }
        memset(state, 0, sizeof(*state));
        vm->native_context = state;
        vm->native_context_delete = p2_vm_state_delete;
    }
    return state;
}

p2_task_state *p2_vm_scheduler(bvm *vm)
{
    p2_vm_state *state = p2_vm_state_get(vm);
    if (!state->scheduler) {
        p2_task_state *scheduler = (p2_task_state *)be_malloc(vm, sizeof(p2_task_state));
        if (state->scheduler) {
            be_free(vm, scheduler, sizeof(p2_task_state));
        } else {
            memset(scheduler, 0, sizeof(*scheduler));
            scheduler->current = -1;
            scheduler->next = -1;
            state->scheduler = scheduler;
        }
    }
    return state->scheduler;
}

p2_rng_state *p2_vm_rng(bvm *vm)
{
    p2_vm_state *state = p2_vm_state_get(vm);
    if (!state->rng) {
        p2_rng_state *rng = (p2_rng_state *)be_malloc(vm, sizeof(p2_rng_state));
        if (state->rng) {
            be_free(vm, rng, sizeof(p2_rng_state));
        } else {
            rng->value = P2_RNG_DEFAULT_SEED;
            state->rng = rng;
        }
    }
    return state->rng;
}

void p2_vm_srand(bvm *vm, uint32_t seed)
{
    p2_vm_rng(vm)->value = seed ? seed : P2_RNG_ZERO_SEED;
}

uint32_t p2_vm_rand(bvm *vm)
{
    p2_rng_state *rng = p2_vm_rng(vm);
    uint32_t value = rng->value;
    /* xorshift32 (13,17,5): modulo-32-bit unsigned operations only.
     * Deterministic, non-cryptographic; no entropy or security guarantee. */
    value ^= value << 13;
    value ^= value >> 17;
    value ^= value << 5;
    rng->value = value;
    return value & UINT32_C(0x7fffffff);
}
