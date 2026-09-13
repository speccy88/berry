/* Host-only platform harness. All Berry VM/API/GC/allocator logic is REAL.
 * PASM ack/stop are test inputs, not execution or physical lifecycle evidence.
 * C cog execution deliberately fails; never emulate a VM-per-cog runtime. */
#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "be_vm.h"
#include "be_exec.h"
#include "be_mem.h"
#include "be_gc.h"
#include "be_string.h"
#include "be_var.h"
#include "p2_vm_state.h"
#include "p2_cog_registry.h"
#include "p2_heap.h"
#include "prop2.h"

extern int test_registry_locked, test_lock_failure;
static int stop_calls, running[8], fail_pasm, no_ack, platform_alloc_fail;
static int partition_releases;
static long fail_after = -1;
static void *hold_vm, *delete_address;
static int reuse_vm;
static int reject_alloc(void)
{
    assert(!test_registry_locked);
    if (fail_after < 0) return 0;
    if (fail_after == 0) return 1;
    --fail_after;
    return 0;
}
void *test_malloc(size_t n)
{
    if (reject_alloc()) return NULL;
    if (reuse_vm && hold_vm && n == sizeof(bvm)) {
        void *p = hold_vm;
        hold_vm = NULL;
        return p;
    }
    return malloc(n);
}
void test_free(void *p)
{
    assert(!test_registry_locked);
    if (p && p == delete_address) {
        assert(!hold_vm);
        hold_vm = p;
        delete_address = NULL;
    } else free(p);
}
void *test_realloc(void *p, size_t n)
{
    if (!p) return test_malloc(n);
    if (!n) { test_free(p); return NULL; }
    return reject_alloc() ? NULL : realloc(p, n);
}
static int _cogchk(int cog) { assert(!test_registry_locked); return running[cog]; }
static void _cogstop(int cog) { assert(!test_registry_locked); ++stop_calls; running[cog] = 0; }
static void _pinf(int pin) { (void)pin; assert(!test_registry_locked); }
static void _dirh(int pin) { (void)pin; abort(); }
static int _cogid(void) { return 0; }
static uint32_t _clockfreq(void) { return 200000000u; }
static void _waitms(uint32_t ms) { (void)ms; assert(!test_registry_locked); }
static void _waitus(uint32_t us) { (void)us; assert(!test_registry_locked); }
static void berry_p2_gpio_toggle(int pin) { (void)pin; abort(); }
static int _cogstart_PASM(int cog, void *program, void *mailbox);
static void *p2_hub_mem_alloc(size_t n) { assert(!test_registry_locked); return platform_alloc_fail ? NULL : malloc(n); }
static void *p2_hub_mem_calloc(size_t n, size_t s) { assert(!test_registry_locked); return platform_alloc_fail ? NULL : calloc(n, s); }
static void p2_hub_mem_free(void *p) { assert(!test_registry_locked); free(p); }
static void *p2_cog_stack_alloc(size_t n) { return p2_hub_mem_alloc(n); }
static void p2_cog_stack_free(void *p) { p2_hub_mem_free(p); }
int p2_heap_vm_partition_release(int slot) { (void)slot; assert(!test_registry_locked); ++partition_releases; return 1; }
size_t p2_heap_vm_partition_size(void) { return 4096; }
static void p2_child_vm_cog_once_entry(void *arg) { (void)arg; abort(); }
static int p2_catalina_cogstart_C(void (*fn)(void *), void *arg, void *stack, int size)
{
    (void)fn; (void)arg; (void)stack; (void)size;
    assert(!test_registry_locked);
    return -1; /* No simulated C/VM execution. */
}
#define ANY_COG 8
/* Host-only legacy VM-lock intrinsics; actual production lock functions below. */
#define LOCKNEW 2
#define LOCKSET(lock) ((void)(lock), 0)
#define LOCKCLR(lock) ((void)(lock))
#include "managed_consumer.inc"

static int _cogstart_PASM(int cog, void *program, void *mailbox)
{
    volatile uint32_t *m = mailbox;
    (void)cog; (void)program;
    assert(!test_registry_locked);
    if (fail_pasm) return -1;
    for (cog = 1; cog < 8 && running[cog]; ++cog) {}
    if (cog == 8) return -1;
    running[cog] = 1;
    if (!no_ack) {
        m[P2_NATIVE_BLINK_STATUS] = 1;
        m[P2_NATIVE_BLINK_COGID] = cog;
    }
    return cog;
}

static void script(bvm *vm, const char *source)
{
    int result, top = be_top(vm);
    assert(!test_registry_locked);
    result = be_loadstring(vm, source);
    if (result == BE_OK) result = be_pcall(vm, 0);
    if (result != BE_OK) {
        fprintf(stderr, "Berry failure %d: %s\n%s\n", result,
                be_isstring(vm, -1) ? be_tostring(vm, -1) : "non-string error", source);
        abort();
    }
    be_pop(vm, be_top(vm) - top);
}
static void reg(bvm *vm, const char *name, bntvfunc fn)
{
    be_pushntvfunction(vm, fn); be_setglobal(vm, name); be_pop(vm, 1);
}
static int collect(bvm *vm) { be_gc_collect(vm); be_return_nil(vm); }
static void register_api(bvm *vm)
{
    reg(vm, "spawn", m_p2_closure_cog_spawn);
    reg(vm, "stop", m_p2_closure_cog_stop);
    reg(vm, "info", m_p2_closure_cog_info);
    reg(vm, "join", m_p2_closure_cog_join);
    reg(vm, "result", m_p2_closure_cog_result);
    reg(vm, "error", m_p2_closure_cog_error);
    reg(vm, "cleanup", m_p2_closure_cog_cleanup_result);
    reg(vm, "collect", collect);
    script(vm, "def blinker(pin, ms) return ms end");
}
static bint getint(bvm *vm, const char *name)
{
    bint v;
    assert(be_getglobal(vm, name)); v = be_toint(vm, -1); be_pop(vm, 1); return v;
}
static void setint(bvm *vm, const char *name, bint v)
{
    be_pushint(vm, v); be_setglobal(vm, name); be_pop(vm, 1);
}
static int owned_count(bvm *vm, p2_cog_lifecycle state)
{
    int i, count = 0;
    for (i = 0; i < P2_COG_REGISTRY_SLOTS; ++i)
        if (p2_closure_cog_identities.slots[i].owner == p2_closure_cog_owner(vm) &&
            p2_closure_cog_identities.slots[i].state == state) ++count;
    return count;
}
static int handle_id(bvm *vm) { return p2_closure_cog_id_for_handle(vm, 1); }
static void rejected(bvm *vm, bint token)
{
    bntvfunc functions[] = {m_p2_closure_cog_stop, m_p2_closure_cog_kill,
        m_p2_closure_cog_join, m_p2_closure_cog_info, m_p2_closure_cog_result,
        m_p2_closure_cog_error, handle_id};
    unsigned i;
    int before = stop_calls;
    void *context = vm->native_context;
    for (i = 0; i < sizeof(functions)/sizeof(functions[0]); ++i) {
        int top = be_top(vm), res;
        be_pushntvfunction(vm, functions[i]); be_pushint(vm, token);
        res = be_pcall(vm, 1);
        assert(res == BE_EXCEPTION);
        assert(be_isstring(vm, -2) && !strcmp(be_tostring(vm, -2), "value_error"));
        be_pop(vm, be_top(vm) - top);
    }
    assert(stop_calls == before && vm->native_context == context);
    assert(!test_registry_locked);
}
static int setup(bvm *vm) { assert(!test_registry_locked); be_pushint(vm, be_toint(vm, 2)); be_return(vm); }
static int call_spawn_period(bvm *vm, bint period)
{
    be_pushntvfunction(vm, m_p2_closure_cog_spawn);
    be_pushntvfunction(vm, setup); be_pushint(vm, 38); be_pushint(vm, period);
    return be_pcall(vm, 3);
}
static int call_spawn(bvm *vm) { return call_spawn_period(vm, 25); }
static int finalizer_count;
static int gc_reenter(bvm *vm)
{
    int index = *(int *)be_tocomptr(vm, 1);
    int before = stop_calls;
    ++finalizer_count;
    assert(!test_registry_locked);
    p2_closure_cog_reap_stopped(vm);
    assert(p2_closure_cog_identities.slots[index].state == P2_COG_RESERVED);
    assert(p2_closure_cog_slot_from_handle(vm, p2_closure_cog_slots[index].handle) < 0);
    assert(stop_calls == before);
    /* A common-object finalizer runs during sweep, not Berry's script
     * destructor phase. Do not compile new GC objects into the active sweep.
     * Exercise the real native start with its actual Berry setup callback. */
    {
        int top = be_top(vm);
        assert(call_spawn_period(vm, 20) == BE_OK);
        assert(p2_closure_cog_slot_from_handle(vm, be_toint(vm, -4)) != index);
        be_pop(vm, be_top(vm) - top);
    }
    be_return_nil(vm);
}
static int gc_replace_index, gc_replace_count;
static int gc_replace(bvm *vm)
{
    ++gc_replace_count;
    assert(!test_registry_locked);
    assert(p2_closure_cog_claim(vm, gc_replace_index, p2_closure_cog_slots[gc_replace_index].handle));
    /* Metadata-only test fixture has no physical resources. */
    assert(p2_closure_cog_finish_reserved(vm, gc_replace_index) == BE_OK);
    {
        int top = be_top(vm);
        assert(call_spawn_period(vm, 77) == BE_OK);
        setint(vm, "replacement", be_toint(vm, -4));
        be_pop(vm, be_top(vm) - top);
    }
    be_return_nil(vm);
}
static void push_info_protected(bvm *vm, void *data)
{
    int i = *(int *)data;
    p2_closure_cog_push_info_map(vm, i, &p2_closure_cog_slots[i]);
}
static void reserve_protected(bvm *vm, void *data)
{
    *(int *)data = p2_closure_cog_reserve(vm);
}
typedef struct context_pool_fill {
    void *blocks[4096];
    size_t count;
} context_pool_fill;
static void exhaust_context_pool(bvm *vm, void *data)
{
    context_pool_fill *fill = data;
    while (fill->count < sizeof(fill->blocks) / sizeof(fill->blocks[0])) {
        void *block = be_malloc(vm, sizeof(p2_vm_state));
        fill->blocks[fill->count++] = block;
    }
}
int main(void)
{
    bvm *a, *b, *fresh;
    bint old, live;
    uint32_t cookie;
    int i, before, index, status;
    setvbuf(stdout, NULL, _IONBF, 0);
    assert(!p2_cog_registry_enter());
    test_lock_failure = 1;
    assert(!p2_cog_registry_startup() && !p2_cog_registry_enter());
    test_lock_failure = 0;
    assert(p2_cog_registry_startup() && p2_cog_registry_startup());
    a = be_vm_new(); b = be_vm_new(); assert(a && b);
    register_api(a); register_api(b);
    script(a, "var h = spawn(blinker, 38, 50) assert(h > 100) assert(result(h) == 50) assert(join(h)['handle'] == h)");
    old = getint(a, "h");
    rejected(b, old); /* live foreign, with no per-VM state */
    assert(b->native_context == NULL);
    script(b, "assert(size(info()) == 0) assert(cleanup()['released_handles'] == 0)");
    p2_closure_cog_reap_stopped(b);
    assert(p2_closure_cog_find_by_cog(b, 1, NULL) == NULL);
    script(a, "assert(stop(h)['handle_valid_after_stop'] == false) var h2 = spawn(blinker, 38, 55) assert(h2 != h)");
    live = getint(a, "h2");
    rejected(a, old); rejected(b, live);
    rejected(a, INT32_MIN); rejected(a, INT32_MAX); rejected(a, 0); rejected(a, 7); rejected(a, 100);
#if BE_INTGER_TYPE == 2
    {
        rejected(a, (bint)INT64_MIN); rejected(a, (bint)INT64_MAX);
        rejected(a, (bint)INT32_MAX + (bint)1);
    }
#endif
    script(a, "assert(cleanup()['released_handles'] == 1) assert(cleanup()['released_handles'] == 0)");
    puts("PASS consumers: live foreign/stale/bounds rejected; rejected tokens caused zero physical stop seam calls");

    script(a, "def outer(pin, ms) var nested = spawn(blinker, 39, 22) assert(size(info()) == 1) collect() return ms end var outer_h = spawn(outer, 38, 66) assert(size(info()) == 2) assert(result(outer_h) == 66) cleanup()");
    index = p2_closure_cog_reserve(a);
    be_newcomobj(a, &index, gc_reenter); be_pop(a, 1); be_gc_collect(a);
    assert(finalizer_count == 1 && owned_count(a, P2_COG_RESERVED) == 1);
    assert(p2_closure_cog_finish_reserved(a, index) == BE_OK);
    script(a, "cleanup()");
    puts("PASS reservation: actual setup reentry and real GC finalizer cannot steal/reap/lookup reserved slot");

    /* Sweep real Berry allocator failure positions, including state allocation.
     * No mock be_malloc/be_pcall/be_vm_new is linked. */
    fresh = be_vm_new(); assert(fresh);
    {
        context_pool_fill fill = { { NULL }, 0 };
        fail_after = 0;
        assert(be_execprotected(fresh, exhaust_context_pool, &fill) == BE_MALLOC_FAIL);
        index = -1;
        status = be_execprotected(fresh, reserve_protected, &index);
        fail_after = -1;
        assert(status == BE_MALLOC_FAIL && index == -1 && !fresh->native_context);
        while (fill.count) be_free(fresh, fill.blocks[--fill.count], sizeof(p2_vm_state));
    }
    be_vm_delete(fresh);
    for (i = 0; i < 45; ++i) {
        int top = be_top(a);
        uint32_t last = p2_closure_cog_identities.last_token;
        fail_after = i;
        status = call_spawn(a);
        fail_after = -1;
        assert(status == BE_OK || status == BE_MALLOC_FAIL);
        assert(owned_count(a, P2_COG_RESERVED) == 0);
        assert(p2_closure_cog_identities.last_token > last);
        be_pop(a, be_top(a) - top);
        script(a, "cleanup()");
    }
    for (i = 0; i < 3; ++i) {
        int top = be_top(a);
        uint32_t last = p2_closure_cog_identities.last_token;
        fail_pasm = i == 0; no_ack = i == 1; platform_alloc_fail = i == 2;
        assert(call_spawn(a) == BE_EXCEPTION);
        fail_pasm = no_ack = platform_alloc_fail = 0;
        assert(owned_count(a, P2_COG_RESERVED) == 0 && owned_count(a, P2_COG_LIVE) == 0);
        assert(p2_closure_cog_identities.last_token > last);
        be_pop(a, be_top(a) - top);
    }
    puts("PASS failure cleanup: real Berry allocation sweep, platform allocation, rejected start, missing PASM ack; tokens burned");

    /* Completed source-job metadata input tests reap ownership without pretending
     * to execute a child VM. Source spawn's production unsafe gate stays OFF. */
    index = p2_closure_cog_reserve(a);
    p2_closure_cog_slots[index].isolated_source = 1;
    p2_closure_cog_slots[index].source_job = calloc(1, sizeof(p2_child_vm_cog_once_job));
    p2_closure_cog_slots[index].source_job->status = 1;
    p2_closure_cog_slots[index].source_job->cog_id = 3;
    p2_closure_cog_slots[index].cog_id = 3; running[3] = 1;
    assert(p2_cog_registry_publish(&p2_closure_cog_identities, index, p2_closure_cog_slots[index].handle));
    before = stop_calls;
    setint(a, "pending_source", p2_closure_cog_slots[index].handle);
    script(a, "var busy=false try stop(pending_source) except 'runtime_error' busy=true end assert(busy)");
    assert(stop_calls == before && running[3]);
    assert(p2_closure_cog_slots[index].source_job->cancel_requested == 1);
    assert(owned_count(a, P2_COG_LIVE) == 1);
    script(a, "var c=cleanup() assert(!c['ok']) assert(c['active_after']==1) assert(!c['registry_empty'])");
    assert(stop_calls == before && running[3]);
    assert(owned_count(a, P2_COG_LIVE) == 1);
    /* Only the simulated platform changes completion, not the stop consumer. */
    p2_closure_cog_slots[index].source_job->status = 2;
    p2_closure_cog_reap_stopped(b); assert(stop_calls == before);
    p2_closure_cog_reap_stopped(a); assert(stop_calls == before + 1);
    p2_closure_cog_reap_stopped(a); assert(stop_calls == before + 1);
#if defined(__CATALINA_LARGE)
    reg(a, "spawn_source", m_p2_closure_cog_spawn_source);
    script(a, "var blocked = false try spawn_source('def f() return 1 end', 'f') except 'runtime_error' blocked = true end assert(blocked)");
    assert(owned_count(a, P2_COG_RESERVED) == 0);
#endif
    puts("PASS stopped-source reap: foreign VM untouched, owner cleanup idempotent; source execution not simulated");

    /* Snapshot test: allocation retry invokes a real native GC finalizer which
     * reuses the slot while the production info result is being allocated. */
    index = p2_closure_cog_reserve(a);
    p2_closure_cog_slots[index].last_result_type = 1;
    p2_closure_cog_slots[index].last_result_int = 12345;
    strcpy(p2_closure_cog_slots[index].closure_name, "snapshot_original");
    old = p2_closure_cog_slots[index].handle;
    assert(p2_cog_registry_publish(&p2_closure_cog_identities, index, old));
    gc_replace_index = index;
    setint(a, "replacement", 0); /* prewarm before sweep-finalizer native entry */
    be_newcomobj(a, &index, gc_replace); be_pop(a, 1);
    /* Force GC at the next allocation using Berry's own threshold. */
    a->gc.threshold = 0;
    before = be_top(a);
    assert(be_execprotected(a, push_info_protected, &index) == BE_OK);
    assert(gc_replace_count == 1);
    be_setglobal(a, "snapshot_info"); be_pop(a, 1);
    assert(be_top(a) == before);
    setint(a, "old_snapshot_handle", old);
    script(a, "assert(snapshot_info['handle'] == old_snapshot_handle) assert(snapshot_info['last_result_int'] == 12345) assert(snapshot_info['function'] == 'snapshot_original') assert(replacement != old_snapshot_handle) cleanup()");
    puts("PASS result snapshot: real GC slot replacement does not change old info result");

    script(a, "var orphan = spawn(blinker, 38, 99)");
    index = p2_closure_cog_reserve(a);
    p2_closure_cog_slots[index].isolated_source = 1;
    p2_closure_cog_slots[index].source_job = calloc(1, sizeof(p2_child_vm_cog_once_job));
    p2_closure_cog_slots[index].source_job->status = 1;
    assert(p2_cog_registry_publish(&p2_closure_cog_identities, index, p2_closure_cog_slots[index].handle));
    old = getint(a, "orphan"); cookie = p2_closure_cog_owner(a); before = stop_calls;
    delete_address = a; be_vm_delete(a);
    assert(stop_calls == before && hold_vm == a);
    assert(p2_closure_cog_slots[index].source_job->cancel_requested == 1);
    reuse_vm = 1; fresh = be_vm_new(); reuse_vm = 0;
    assert(fresh == a && !hold_vm && !fresh->native_context);
    rejected(fresh, old);
    index = p2_closure_cog_reserve(fresh);
    assert(p2_closure_cog_owner(fresh) != cookie);
    assert(p2_closure_cog_finish_reserved(fresh, index) == BE_OK);
    rejected(fresh, old); rejected(b, old);
    p2_closure_cog_reap_stopped(fresh); assert(stop_calls == before);
    /* Test teardown of orphan metadata/resources only; NOT production F3. */
    for (i = 0; i < P2_COG_REGISTRY_SLOTS; ++i) {
        if (!p2_closure_cog_identities.slots[i].owner && p2_closure_cog_identities.slots[i].state == P2_COG_LIVE) {
            free(p2_closure_cog_slots[i].source_job);
#if defined(__CATALINA_LARGE)
            free((void *)p2_closure_cog_slots[i].native_mailbox);
#endif
            p2_closure_cog_identities.slots[i].state = P2_COG_RESERVED;
            assert(p2_cog_registry_release(&p2_closure_cog_identities, i, p2_closure_cog_identities.slots[i].token));
        }
    }
    be_vm_delete(fresh); be_vm_delete(b);
    printf("PASS real VM deletion/address reuse: dead cookie rejected, zero deletion stop calls; bint=%u unsafe=%d\n",
        (unsigned)(8 * sizeof(bint)), BE_P2_ENABLE_UNSAFE_SHARED_VM_COG);
    return 0;
}
