/* Host-only allocator-routing test using the real Berry VM and vector code. */
#include "berry.h"
#include "be_vm.h"
#include "be_exec.h"
#include "be_vector.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int forbid_global_hub;
void test_vm_special_storage(void);
static void *storage;
static size_t storage_size;
static unsigned allocations, releases, moves;
static int fail_growth;

void *p2_hub_realloc(void *ptr, size_t new_size)
{
    void *replacement;
    size_t old_size = storage_size;
    assert(!forbid_global_hub);
    assert(ptr == storage);
    if (new_size == 0) {
        free(ptr);
        storage = NULL;
        storage_size = 0;
        ++releases;

        return NULL;
    }
    if (fail_growth && ptr != NULL) {
        fail_growth = 0;
        return NULL;
    }
    /* Force every growth to move, exercising the real exception-chain fixup. */
    replacement = malloc(new_size);
    assert(replacement != NULL);
    if (ptr != NULL) {
        memcpy(replacement, ptr, old_size < new_size ? old_size : new_size);
        free(ptr);
        ++moves;
    }
    storage = replacement;
    storage_size = new_size;
    ++allocations;

    return replacement;
}

static int execute(bvm *vm, const char *source)
{
    int result = be_loadstring(vm, source);
    if (result == BE_OK) {
        result = be_pcall(vm, 0);
    }
    /* be_dostring uses logical OR and collapses distinct error codes to 1. */
    if (result != BE_OK) {
        fprintf(stderr, "Berry result=%d, exception count=%d, capacity=%d\n",
            result, vm->exceptstack.count, vm->exceptstack.capacity);
        if (be_top(vm) > 0 && be_isstring(vm, -1)) {
            fprintf(stderr, "%s\n", be_tostring(vm, -1));
        }
    }
    be_pop(vm, be_top(vm));
    return result;
}

static void reset_tracking(void)
{
    assert(storage == NULL && storage_size == 0);

    allocations = releases = moves = 0;
    fail_growth = 0;
}

int main(void)
{
    bvm *vm;
    bvector ordinary;
    unsigned before;
    const char *loop =
        "var total=0\n"
        "for i:0..15\n total+=i\n end\n"
        "assert(total==15*16/2)\n";
    const char *nested =
        "var count=0\n"
        "for a:0..0\n for b:0..0\n for c:0..0\n for d:0..0\n"
        "for e:0..0\n for f:0..0\n for g:0..0\n for h:0..0\n"
        "count+=1\n end\n end\n end\n end\n end\n end\n end\n end\n"
        "assert(count==1)\n";
    const char *growth =
        "try\n try\n try\n var x=1\n"
        "except .. as e\n var ignored=0\n end\n"
        "except .. as e\n var ignored=0\n end\n"
        "except .. as e\n var ignored=0\n end\n";

    reset_tracking();
    vm = be_vm_new();
    assert(vm != NULL);
    assert(allocations > 0 && storage == vm->exceptstack.data);
    before = allocations;
    be_vector_init(vm, &ordinary, sizeof(int));
    be_vector_push(vm, &ordinary, NULL);
    be_vector_resize(vm, &ordinary, 12);
    be_vector_delete(vm, &ordinary);
    assert(allocations == before); /* Ordinary vectors keep their allocator. */
    assert(execute(vm, loop) == BE_OK);
    assert(execute(vm, nested) == BE_OK);
    assert(moves > 0);
    assert(be_stack_count(&vm->exceptstack) == 0);
    assert(vm->errjmp == NULL);
    be_vector_release(vm, &vm->exceptstack);
    assert(storage == NULL && storage_size == 0);
    assert(execute(vm, loop) == BE_OK);
    be_vm_delete(vm);
    assert(storage == NULL && storage_size == 0 && releases > 0);

    reset_tracking();
    vm = be_vm_new();
    assert(vm != NULL && allocations > 0);
    fail_growth = 1;
    assert(execute(vm, growth) == BE_MALLOC_FAIL);
    assert(fail_growth == 0);
    assert(be_stack_count(&vm->exceptstack) == 0);
    assert(vm->errjmp == NULL);
    assert(execute(vm, loop) == BE_OK);
    be_vm_delete(vm);
    assert(storage == NULL && storage_size == 0 && releases > 0);
    puts("PASS exception storage: routing, moving growth, unwind, OOM, recovery, free");
    test_vm_special_storage();
    return 0;
}
