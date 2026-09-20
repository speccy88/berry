#include "berry.h"

#if defined(__CATALINA_LARGE)
#include "be_vm.h"
#include "be_exec.h"
#include "p2_hub_heap.h"

/* Catalina saves/restores jmp_buf with raw Hub RDLONG/WRLONG instructions.
 * Only the VM's exception-frame vector uses this allocation domain. Its
 * metadata stays VM-owned; byte accounting includes its Hub storage.
 */
void *be_p2_realloc_exceptstack(bvm *vm, void *ptr,
    size_t old_size, size_t new_size)
{
    void *result;
    /* Custom VMs must provide their own Hub domain. In LARGE the SDK heap's
     * metadata is cached XMM: even a lock cannot make worker use coherent. */
    if (old_size == new_size) {
        return ptr;
    }
    if (vm->allocator) be_throw(vm, BE_MALLOC_FAIL);
    result = p2_hub_realloc(ptr, new_size);
    if (result == NULL && new_size != 0) {
        /* Hub exhaustion is distinct from the ordinary PSRAM heap. No user
         * code or exception transfer runs while the shared heap lock is held.
         */
        be_throw(vm, BE_MALLOC_FAIL);
    }
#if BE_USE_PERF_COUNTERS
    vm->counter_mem_alloc++;
    if (ptr != NULL && old_size != 0) {
        if (new_size == 0) {
            vm->counter_mem_free++;
        } else {
            vm->counter_mem_realloc++;
        }
    }
#endif
    vm->gc.usage = vm->gc.usage + new_size - old_size;
    return result;
}
#endif
