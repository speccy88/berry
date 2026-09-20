/* Real Berry VMs; malloc-backed domain fixtures are NOT Hub/board proof. */
#include "berry.h"
#include "be_vm.h"
#include "be_exec.h"
#include "be_vector.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

extern int forbid_global_hub;
#ifdef BE_VM_SPECIAL_ALLOCATOR_API
typedef struct allocation {
    struct allocation *next;
    size_t size;
    void *ptr;
} allocation;
typedef struct {
    allocation *head;
    size_t live, bytes, calls, moves, releases;
    int fail;
    int use_budget;
    unsigned budget;
} domain;
static void *domain_realloc(void *context, void *ptr, size_t size)
{
    domain *d = context;
    allocation **slot = &d->head, *a;
    void *result;
    assert(d);
    ++d->calls;
    while (*slot && (*slot)->ptr != ptr) slot = &(*slot)->next;
    assert(!ptr || *slot); /* wrong context / pool / foreign free */
    if (!size) {
        if (ptr) {
            a = *slot; *slot = a->next;
            d->bytes -= a->size; --d->live;
            ++d->releases;
            free(a->ptr); free(a);
        }
        return NULL;
    }
    if (d->fail || (d->use_budget && !d->budget)) return NULL;
    if (d->use_budget) --d->budget;
    result = malloc(size); assert(result);
    if (ptr) {
        a = *slot;
        memcpy(result, ptr, a->size < size ? a->size : size);
        free(ptr); d->bytes -= a->size; ++d->moves;
    } else {
        a = malloc(sizeof(*a)); assert(a);
        a->next = d->head; d->head = a; ++d->live;
    }
    a->ptr = result; a->size = size; d->bytes += size;
    return result;
}
static int special_execute(bvm *vm, const char *src)
{
    int rc = be_loadstring(vm, src);
    if (rc == BE_OK) rc = be_pcall(vm, 0);
    if (rc != BE_OK) {
        fprintf(stderr, "special rc=%d count=%d capacity=%d\n", rc,
            vm->exceptstack.count, vm->exceptstack.capacity);
        if (be_top(vm) && be_isstring(vm, -1)) fprintf(stderr, "%s\n", be_tostring(vm, -1));
    }
    be_pop(vm, be_top(vm));
    assert(!vm->errjmp && vm->exceptstack.count == 0);
    return rc;
}
static void push_vector(bvm *vm, void *unused)
{
    (void)unused;
    be_vector_push(vm, &vm->exceptstack, NULL);
}
typedef struct { bvm_options *outer, *inner; bvm *peer; int entered; } nesting;
static void nested_progress(void *context, int stage)
{
    nesting *n = context;
    if (stage == 4 && !n->entered) {
        n->entered = 1;
        /* Caller options are no longer authoritative after entry. */
        n->outer->special_allocator = NULL;
        n->outer->special_allocator_context = NULL;
        n->peer = be_vm_new_with_options(n->inner);
        assert(n->peer);
    }
}
#endif
void test_vm_special_storage(void)
{
#ifndef BE_VM_SPECIAL_ALLOCATOR_API
    assert(!"RED: explicit VM special storage API is absent");
#else
    domain ordinary_a = {0}, ordinary_b = {0}, a = {0}, b = {0};
    bvm_options oa = {0}, ob = {0};
    nesting n = {&oa, &ob, NULL, 0};
    bvm *vm, *peer;
    size_t usage, peer_bytes, before;
    void *old, *end;
    int capacity;
    const char *growth =
        "def nested(n) try if n>0 return nested(n-1) end "
        "raise 'value_error', 'deep' except .. as e "
        "if n<2 raise 'value_error', 'again' end return n end end assert(nested(12)==2)";
    forbid_global_hub = 1;
    oa.allocator = ob.allocator = domain_realloc;
    oa.allocator_context = &ordinary_a; ob.allocator_context = &ordinary_b;
    oa.special_allocator = ob.special_allocator = domain_realloc;
    oa.special_allocator_context = &a; ob.special_allocator_context = &b;
    oa.progress = nested_progress; oa.progress_context = &n;
    vm = be_vm_new_with_options(&oa); peer = n.peer;
    assert(vm && peer && n.entered);
    assert(vm->special_allocator_context == &a && peer->special_allocator_context == &b);
    assert(a.live == 1 && b.live == 1 && a.head->ptr == vm->exceptstack.data);
    assert(b.head->ptr == peer->exceptstack.data && a.head->ptr != b.head->ptr);
    assert(special_execute(peer, "var private_value=29") == BE_OK);
    peer_bytes = b.bytes;
    before = a.calls;
    {
        bvector ordinary;
        be_vector_init(vm, &ordinary, sizeof(int));
        be_vector_resize(vm, &ordinary, 20);
        be_vector_delete(vm, &ordinary);
    }
    assert(before == a.calls);
    /* Failure is atomic even before the outer protected call unwinds. */
    be_vector_push(vm, &vm->exceptstack, NULL);
    be_vector_push(vm, &vm->exceptstack, NULL);
    old = vm->exceptstack.data; end = vm->exceptstack.end;
    capacity = vm->exceptstack.capacity; usage = vm->gc.usage;
    a.fail = 1;
    assert(be_execprotected(vm, push_vector, NULL) == BE_MALLOC_FAIL);
    assert(vm->gc.usage == usage && vm->exceptstack.data == old);
    assert(vm->exceptstack.end == end && vm->exceptstack.capacity == capacity);
    assert(vm->exceptstack.count == 2);
    be_vector_clear(&vm->exceptstack);
    assert(special_execute(vm, growth) == BE_MALLOC_FAIL);
    assert(b.bytes == peer_bytes);
    a.fail = 0;
    assert(special_execute(vm, growth) == BE_OK && a.moves > 0);
    assert(special_execute(vm, "def broken(") == BE_EXCEPTION);
    assert(special_execute(vm, "raise 'value_error', 'uncaught'") == BE_EXCEPTION);
    assert(special_execute(vm, "assert(6*7==42)") == BE_OK);
    usage = vm->gc.usage;
    before = a.bytes;
    be_vector_release(vm, &vm->exceptstack);
    assert(a.live == 0 && vm->gc.usage == usage-before);
    assert(special_execute(vm, growth) == BE_OK);
    be_vm_delete(vm);
    assert(a.live == 0 && ordinary_a.live == 0);
    assert(special_execute(peer, "assert(private_value==29)") == BE_OK);
    be_vm_delete(peer);
    assert(!b.live && !ordinary_b.live);
    /* Initial special allocation fails after ordinary constructor allocations. */
    oa.progress = NULL; oa.special_allocator = domain_realloc;
    oa.special_allocator_context = &a; a.fail = 1;
    assert(be_vm_new_with_options(&oa) == NULL);
    assert(!a.live && !ordinary_a.live);
    a.fail = 0;
    oa.special_allocator = NULL;
    before = ordinary_a.calls;
    assert(be_vm_new_with_options(&oa) == NULL); /* invalid pair */
    assert(ordinary_a.calls == before);
    oa.special_allocator_context = NULL;
    assert(be_vm_new_with_options(&oa) == NULL); /* P2 requires Hub domain */
    assert(!ordinary_a.live);
    /* Ordinary OOM after special allocation releases both domains. */
    {
        unsigned budget, refused=0, late=0, succeeded=0;
        bvm_options sweep={0};
        sweep.allocator=domain_realloc; sweep.allocator_context=&ordinary_a;
        sweep.special_allocator=domain_realloc; sweep.special_allocator_context=&a;
        ordinary_a.use_budget=1;
        for (budget=0; budget<320; ++budget) {
            size_t releases=a.releases;
            ordinary_a.budget=budget;
            vm=be_vm_new_with_options(&sweep);
            if (vm) {++succeeded; be_vm_delete(vm);}
            else {++refused; if (a.releases>releases) ++late;}
            assert(!ordinary_a.live && !ordinary_a.bytes && !a.live && !a.bytes);
        }
        ordinary_a.use_budget=0;
        assert(refused && late && succeeded);
        printf("PASS explicit domains constructor sweep: refused=%u late=%u succeeded=%u\n",refused,late,succeeded);
    }
    /* Special-only custom options also get protected constructor failure. */
    oa.allocator = NULL; oa.allocator_context = NULL;
    oa.special_allocator = domain_realloc; oa.special_allocator_context = &a;
    a.fail = 1; assert(be_vm_new_with_options(&oa) == NULL); assert(!a.live);
    a.fail = 0;
    vm = be_vm_new_with_options(&oa); assert(vm);
    assert(special_execute(vm, growth) == BE_OK);
    be_vm_delete(vm); assert(!a.live);
    forbid_global_hub = 0;
    puts("PASS explicit special storage: two domains, nested constructors, copied options, moving/failed growth, accounting, load/call unwind, cleanup, no global Hub fallback");
#endif
}
