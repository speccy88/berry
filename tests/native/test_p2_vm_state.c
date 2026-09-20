/* Host-only ownership regressions: two real Berry VMs on one simulated cog.
 * Production callbacks and clock logic are included/linked, never copied.
 * No physical IO. Unexercised CORDIC instructions fail loudly if reached. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>
#include "be_vm.h"
#include "be_gc.h"
#include "be_exec.h"
#include "be_mem.h"
#include "be_var.h"
#include "be_vector.h"
#include "be_libs.h"
#include <propeller2.h>
#if BE_DEBUG
#include <signal.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

static unsigned checks, failures;
#define CHECK(x) do { ++checks; if (!(x)) { ++failures; \
    fprintf(stderr, "FAIL %s:%d: %s\n", __func__, __LINE__, #x); } } while (0)
static long fail_after = -1;
static size_t live_blocks;
static bvm *deleting_vm;
static unsigned vm_frees;
static int reject_alloc(void)
{
    if (fail_after < 0) return 0;
    if (fail_after == 0) return 1; /* also fail Berry's retry after GC */
    --fail_after;
    return 0;
}
void *test_malloc(size_t n)
{
    void *p;
    if (reject_alloc()) return NULL;
    p = malloc(n);
    if (p) ++live_blocks;
    return p;
}
void test_free(void *p)
{
    if (p && p == deleting_vm) {
        CHECK(deleting_vm->gc.usage == sizeof(bvm));
        CHECK(deleting_vm->native_context == NULL);
        CHECK(deleting_vm->native_context_delete == NULL);
        ++vm_frees;
        deleting_vm = NULL;
    }
    if (p) { CHECK(live_blocks > 0); --live_blocks; }
    free(p);
}
void *test_realloc(void *p, size_t n)
{
    void *q;
    if (!p) return test_malloc(n);
    if (!n) { test_free(p); return NULL; }
    if (reject_alloc()) return NULL;
    q = realloc(p, n);
    return q;
}
uint32_t _cnth(void) { return 0; }
uint32_t _cnt(void) { return 0; }
uint32_t _clockfreq(void) { return 200000000; }
int _cogid(void) { return 0; }
void _waitms(int ms) { (void)ms; abort(); }
cartesian_t _polxy(polar_t p) { (void)p; abort(); }
polar_t _xypol(cartesian_t p) { (void)p; abort(); }

#include "../../port/p2/overrides/be_tasklib_p2.c"
/* Keep the host string module needed by core format(); the P2 override's
 * string descriptor is not under test. No Berry functions are replaced. */
#define be_native_module_string be_native_module_p2_test_string
#include "../../port/p2/overrides/be_math_stringlib_p2.c"
#undef be_native_module_string

static void script(bvm *vm, const char *source)
{
    int top = be_top(vm);
    int rc = be_loadstring(vm, source);
    if (!rc) rc = be_pcall(vm, 0);
    CHECK(rc == BE_OK);
    if (rc) be_dumpexcept(vm);
    be_pop(vm, be_top(vm) - top);
}
static bvm *new_vm(void)
{
    bvm *vm = be_vm_new();
    CHECK(vm != NULL);
    CHECK(_cogid() == 0);
    /* Host generated strings omit the P2 permanent task name. Root it just
     * as the existing native clock fixture does while installing the module. */
    be_pushstring(vm, "task");
    be_cache_taskmodule(vm);
    be_pop(vm, 1);
    be_cache_mathmodule(vm);
    return vm;
}
static void seed(bvm *vm, bint value)
{
    be_pushntvfunction(vm, p2_math_srand);
    be_pushint(vm, value);
    CHECK(be_pcall(vm, 1) == BE_OK);
    be_pop(vm, 2);
}
static bint random_value(bvm *vm)
{
    bint value;
    be_pushntvfunction(vm, p2_math_rand);
    CHECK(be_pcall(vm, 0) == BE_OK);
    CHECK(be_isint(vm, -1));
    value = be_toint(vm, -1);
    be_pop(vm, 1);
    return value;
}
static void scheduler_reset(void)
{
    bvm *a = new_vm(), *b = new_vm();
    script(a, "import task\nvar runs = 0\ndef tick() runs += 1 return task.again end\n"
              "var h = task.start(tick)\nassert(h == 0)\nassert(task.signal('a'))\n");
    script(b, "import task\nassert(task.reset())\n");
    script(a, "assert(task.chk(h), 'other VM reset removed task')\n"
              "assert(task.events().find('a') != nil, 'other VM reset removed event')\n"
              "assert(task.next() == h)\nassert(runs == 1)\n");
    be_vm_delete(b);
    be_vm_delete(a);
}
static void rng_isolation(void)
{
    bvm *a = new_vm(), *b = new_vm();
    bint first, second;
    seed(a, 1);
    first = random_value(a);
    second = random_value(a);
    seed(a, 1);
    CHECK(random_value(a) == first);
    seed(b, 99);
    (void)random_value(b);
    CHECK(random_value(a) == second);
    be_vm_delete(b);
    be_vm_delete(a);
}
static void rng_sequence(void)
{
    /* Independent fixed known-answer vectors for xorshift32(13,17,5), masked
     * to 31 bits. These reject the old +7919 counter, not only global state. */
    static const uint32_t expected[] = {270369, 67634689, 499951813, 307599695, 251205585};
    bvm *vm = new_vm();
    unsigned i;
    seed(vm, 1);
    for (i = 0; i < sizeof(expected) / sizeof(expected[0]); ++i)
        CHECK(random_value(vm) == (bint)expected[i]);
    be_vm_delete(vm);
}

static bvm *peer;
static int visit_peer(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    CHECK(state->current == 0);
    CHECK(p2_vm_scheduler(peer)->current == -1);
    script(peer, "assert(task.current() == -1)\nassert(task.next() == 5)\n"
                 "assert(task.current() == -1)\n");
    CHECK(state->current == 0);
    be_return_nil(vm);
}

static void scheduler_isolation(void)
{
    bvm *a = new_vm(), *b = new_vm();
    p2_task_state *sa = p2_vm_scheduler(a), *sb = p2_vm_scheduler(b);
    CHECK(a->native_context != b->native_context);
    CHECK(sa != sb);
    CHECK(sa->current == -1 && sb->current == -1);
    CHECK(sa->next == -1 && sb->next == -1);
    script(a, "import task\nvar runs = 0\n"
              "def tick()\n assert(task.current() == 0)\n runs += 1\n"
              " if runs == 1 return task.wait('shared') end\n"
              " assert(task.woke_by_event('shared'))\n return task.again\n end\n"
              "var h = task.start(tick)\nassert(h == 0)\nassert(task.next() == h)\n");
    script(b, "import task\nvar runs = 0\n"
              "assert(!task.chk(0))\nassert(!task.stop(0))\n"
              "def tick() runs += 1 return task.again end\n"
              "var h = task.start(tick)\nassert(h == 0)\n"
              "assert(task.signal('shared'))\nassert(task.pause(h))\n");
    script(a, "assert(task.status(h) == 'waiting')\nassert(task.next() == -1)\n"
              "assert(runs == 1)\nassert(size(task.events()) == 0)\n"
              "assert(task.signal('shared'))\nassert(task.next() == h)\nassert(runs == 2)\n");
    script(b, "assert(task.status(h) == 'paused')\nassert(runs == 0)\n"
              "assert(task.resume(h))\nassert(task.next() == h)\nassert(runs == 1)\n"
              "assert(task.clear_all())\nassert(task.stop(h))\nassert(!task.chk(h))\n");
    script(a, "assert(task.chk(h))\nassert(task.events().find('shared') != nil)\n");
    be_vm_delete(b);
    CHECK(p2_vm_scheduler(a) == sa);
    script(a, "assert(task.next() == h)\nassert(runs == 3)\n");
    b = new_vm();
    CHECK(p2_vm_scheduler(b) != sa);
    script(b, "import task\nassert(size(task.list()) == 0)\n"
              "assert(size(task.events()) == 0)\nassert(task.current() == -1)\n"
              "def tick() return task.again end\nassert(task.start(tick) == 0)\n"
              "assert(task.reset_result()['released_tasks'] == 1)\n");
    script(a, "assert(task.chk(h))\nassert(task.next() == h)\nassert(runs == 4)\n"
              "assert(task.reset())\n");
    /* Native callback visits a second real VM while A has an active task.
     * Host analogue of same-cog VM entry, NOT be_p2lib vm_call/hardware proof. */
    peer = b;
    be_regfunc(a, "visit_peer", visit_peer);
    script(b, "def nested() assert(task.current() == 5) return task.again end\n"
              "assert(task.spin(5, nested) == 5)\n");
    script(a, "def nested() visit_peer() assert(task.current() == 0) return task.done end\n"
              "assert(task.start(nested) == 0)\nassert(task.next() == 0)\n"
              "assert(task.status(0) == 'free')\nassert(!task.chk(0))\n"
              "assert(task.current() == -1)\n");
    CHECK(sa->next == 0 && p2_vm_scheduler(b)->next == 5);
    peer = NULL;
    be_vm_delete(b);
    be_vm_delete(a);
}

static void scheduler_gc(void)
{
    bvm *vm = new_vm();
    bvalue *ref, *object;
    void *wait_object;
    script(vm, "import task\nvar calls = 0\n"
               "def install()\n var captured = [41]\n"
               " def work(arg)\n calls += 1\n assert(captured[0] == 41)\n"
               " assert(arg[0] == 99)\n if calls == 1 return task.wait(task.Semaphore(0)) end\n"
               " return task.done\n end\n return task.start(work, [99])\n end\n"
               "var h = install()\ninstall = nil\n");
    be_gc_collect(vm);
    script(vm, "assert(task.next() == h)\nassert(calls == 1)\n"
               "assert(task.status(h) == 'waiting')\n");
    ref = p2_task_registry_value(vm, 0);
    CHECK(ref && var_ismap(ref));
    object = p2_task_map_find_cstr(vm, var_toobj(ref), "wait_object");
    CHECK(object && var_isinstance(object));
    wait_object = var_toobj(object);
    be_gc_collect(vm);
    ref = p2_task_registry_value(vm, 0);
    object = p2_task_map_find_cstr(vm, var_toobj(ref), "wait_object");
    CHECK(var_toobj(object) == wait_object);
    /* The wait object's only persistent root is the hidden per-VM registry. */
    *vm->top = *object;
    be_incrtop(vm);
    CHECK(p2_task_get_member_int(vm, -1, "count", -1) == 0);
    p2_task_set_member_int(vm, be_absindex(vm, -1), "count", 1);
    be_pop(vm, 1);
    script(vm, "assert(task.next() == h)\nassert(calls == 2)\n"
               "assert(task.status(h) == 'free')\nassert(!task.chk(h))\n"
               "assert(!task.stop(h))\n");
    CHECK(var_isnil(p2_task_registry_value(vm, 0)));
    be_gc_collect(vm);
    be_vm_delete(vm);
}

static void rng_boundaries(void)
{
    static const uint32_t zero[] = {1085196063, 299895833, 470802728, 1701901981, 265159372};
    static const uint32_t minimum[] = {540672, 151553156, 714162504, 1438122644, 1756881985};
    static const uint32_t negative[] = {253983, 2080898559, 1958451267, 1909229786, 2049502865};
    bvm *a = new_vm(), *b = new_vm();
    unsigned i;
    bint sequence[128];
    CHECK(random_value(a) == 1960601816); /* lazy default */
    CHECK(random_value(b) == 1960601816);
    seed(a, 0);
    seed(b, (bint)INT32_MIN);
    for (i = 0; i < 5; ++i) {
        CHECK(random_value(a) == (bint)zero[i]);
        CHECK(random_value(b) == (bint)minimum[i]);
    }
    seed(a, -1);
    for (i = 0; i < 5; ++i) CHECK(random_value(a) == (bint)negative[i]);
#if BE_INTGER_TYPE == 2
    seed(a, (bint)INT64_MIN); /* low 32 bits are zero, no signed negation */
    for (i = 0; i < 5; ++i) CHECK(random_value(a) == (bint)zero[i]);
    seed(a, (bint)UINT64_C(0x100000001));
    CHECK(random_value(a) == 270369);
#else
    seed(a, (bint)INT_MIN);
    for (i = 0; i < 5; ++i) CHECK(random_value(a) == (bint)minimum[i]);
#endif
    script(a, "import math\nassert(math.srand() == nil)\nassert(math.rand() == 1960601816)\n"
              "math.srand(nil)\nassert(math.rand() == 1960601816)\n"
              "math.srand('1')\nassert(math.rand() == 1960601816)\n"
              "math.srand(1.0)\nassert(math.rand() == 1960601816)\n"
              "math.srand(true)\nassert(math.rand() == 1960601816)\n"
              "math.srand(1, 99)\nassert(math.rand('ignored') == 270369)\n");
    seed(a, 123456);
    for (i = 0; i < 128; ++i) {
        sequence[i] = random_value(a);
        CHECK(sequence[i] >= 0 && sequence[i] <= INT32_MAX);
    }
    seed(a, 123456);
    seed(b, 123456);
    CHECK(p2_vm_rng(a) != p2_vm_rng(b));
    for (i = 0; i < 128; ++i) {
        CHECK(random_value(a) == sequence[i]);
        if (i % 2 == 0) CHECK(random_value(b) == sequence[i / 2]);
        if (i == 63) {
            be_vm_delete(b);
            b = new_vm();
            seed(b, 123456);
            /* Catch up independently without touching A. */
            { unsigned j; for (j = 0; j < 32; ++j) CHECK(random_value(b) == sequence[j]); }
        }
    }
    be_vm_delete(b);
    be_vm_delete(a);
}

static int no_op(bvm *vm) { be_return_nil(vm); }
static bvm *plain_vm(void)
{
    bvm *vm = be_vm_new();
    CHECK(vm != NULL);
    CHECK(vm->native_context == NULL && vm->native_context_delete == NULL);
    /* Warm the real native call frame before exact allocation delta checks. */
    be_pushntvfunction(vm, no_op);
    CHECK(be_pcall(vm, 0) == BE_OK);
    be_pop(vm, 1);
    be_gc_collect(vm);
    be_gc_setpause(vm, 0); /* only disable automatic GC; explicit/failed-alloc GC remains */
    return vm;
}

static void delete_checked(bvm *vm)
{
    unsigned before = vm_frees;
    deleting_vm = vm;
    be_vm_delete(vm);
    CHECK(vm_frees == before + 1 && deleting_vm == NULL);
}

static unsigned cleanup_calls, finalizer_calls;
static void (*real_cleanup)(bvm *, void *);
static void observe_cleanup(bvm *vm, void *context)
{
    p2_vm_state *state = context;
    size_t bytes = sizeof(*state), before = be_gc_memcount(vm);
    CHECK(context != NULL);
    CHECK(vm->native_context == NULL && vm->native_context_delete == NULL);
    if (state->scheduler) bytes += sizeof(*state->scheduler);
    if (state->rng) bytes += sizeof(*state->rng);
    ++cleanup_calls;
    real_cleanup(vm, context); /* actual production callback; no replacement */
    CHECK(before - be_gc_memcount(vm) == bytes);
}
static void observe(bvm *vm)
{
    real_cleanup = vm->native_context_delete;
    CHECK(real_cleanup != NULL);
    vm->native_context_delete = observe_cleanup;
}

static int finalizer(bvm *vm)
{
    unsigned *count = be_tocomptr(vm, 1);
    ++*count;
    CHECK(cleanup_calls == 0);
    CHECK(p2_vm_scheduler(vm)->current == -1);
    p2_vm_srand(vm, 1);
    CHECK(p2_vm_rand(vm) == 270369);
    if (vm->native_context_delete != observe_cleanup) observe(vm);
    be_return_nil(vm);
}

static void lifecycle(void)
{
    unsigned mode;
    bvm *vm = plain_vm();
    delete_checked(vm); /* ordinary VM never initializes port context */
    for (mode = 0; mode < 4; ++mode) {
        size_t base, expected;
        p2_vm_state *state;
        vm = plain_vm();
        base = be_gc_memcount(vm);
        state = p2_vm_state_get(vm);
        expected = sizeof(*state);
        CHECK(be_gc_memcount(vm) == base + expected);
        CHECK(state->rng == NULL && state->scheduler == NULL);
        if (mode & 1) { p2_vm_scheduler(vm); expected += sizeof(p2_task_state); }
        if (mode & 2) { p2_vm_rng(vm); expected += sizeof(p2_rng_state); }
        CHECK(be_gc_memcount(vm) == base + expected);
        CHECK(p2_vm_state_get(vm) == state);
        be_gc_collect(vm);
        CHECK(be_gc_memcount(vm) == base + expected);
        cleanup_calls = 0;
        observe(vm);
        delete_checked(vm);
        CHECK(cleanup_calls == 1);
    }
    /* Unrooted native finalizer runs on collection; rooted one runs at delete.
     * A fresh VM may first acquire its context from a native delete finalizer. */
    for (mode = 0; mode < 2; ++mode) {
        vm = plain_vm();
        cleanup_calls = finalizer_calls = 0;
        be_newcomobj(vm, &finalizer_calls, finalizer);
        if (mode == 0) {
            be_pop(vm, 1);
            be_gc_collect(vm);
            CHECK(finalizer_calls == 1 && cleanup_calls == 0);
            CHECK(p2_vm_rand(vm) == 67634689);
            be_gc_collect(vm);
            CHECK(finalizer_calls == 1);
            be_newcomobj(vm, &finalizer_calls, finalizer);
        }
        delete_checked(vm);
        CHECK(finalizer_calls == (mode == 0 ? 2U : 1U));
        CHECK(cleanup_calls == 1);
    }
}

typedef struct filler {
    void *blocks[4096];
    size_t sizes[4096];
    size_t size;
    unsigned count;
} filler;
static void fill_pool(bvm *vm, void *data)
{
    filler *f = data;
    while (f->count < sizeof(f->blocks) / sizeof(f->blocks[0])) {
        void *block = be_malloc(vm, f->size);
        f->sizes[f->count] = f->size;
        f->blocks[f->count++] = block;
    }
}
static void exhaust_pool(bvm *vm, filler *f)
{
    f->count = 0;
    fail_after = 0;
    /* Existing pool slots still succeed until the real OS allocator is needed.
     * Retain every C allocation across the real protected longjmp. */
    f->size = 16;
    CHECK(be_execprotected(vm, fill_pool, f) == BE_MALLOC_FAIL);
    /* The owner cookie/callback can move p2_vm_state into the larger pool.
     * Exhaust that class as well; RNG still needs the original small pool. */
    if (sizeof(p2_vm_state) > 16) {
        f->size = sizeof(p2_vm_state);
        CHECK(be_execprotected(vm, fill_pool, f) == BE_MALLOC_FAIL);
    }
    CHECK(f->count < sizeof(f->blocks) / sizeof(f->blocks[0]));
}
static void release_pool(bvm *vm, filler *f)
{
    fail_after = -1;
    while (f->count) {
        --f->count;
        be_free(vm, f->blocks[f->count], f->sizes[f->count]);
    }
}
static void get_feature(bvm *vm, void *data)
{
    int feature = *(int *)data;
    if (feature == 0) p2_vm_state_get(vm);
    else if (feature == 1) p2_vm_scheduler(vm);
    else p2_vm_rng(vm);
}

static void allocation_failures(void)
{
    int mode;
    for (mode = 0; mode < 7; ++mode) {
        bvm *vm = plain_vm();
        p2_vm_state *state = NULL;
        p2_task_state saved;
        filler f;
        size_t before;
        int feature = mode < 3 ? mode : (mode == 3 || mode == 5 ? 1 : 2);
        if (mode >= 3) state = p2_vm_state_get(vm);
        if (mode == 5) p2_vm_srand(vm, 99);
        if (mode == 6) {
            p2_task_state *scheduler = p2_vm_scheduler(vm);
            scheduler->slots[3].status = P2_TASK_PAUSED;
            CHECK(p2_task_signal_event(vm, "kept"));
            saved = *scheduler;
        }
        exhaust_pool(vm, &f);
        before = be_gc_memcount(vm);
        CHECK(be_execprotected(vm, get_feature, &feature) == BE_MALLOC_FAIL);
        CHECK(be_gc_memcount(vm) == before);
        CHECK(vm->native_context == state);
        if (!state) CHECK(vm->native_context_delete == NULL);
        else {
            CHECK(vm->native_context_delete != NULL);
            CHECK(feature == 1 ? state->scheduler == NULL : state->rng == NULL);
            if (mode == 5) CHECK(state->rng->value == 99);
            if (mode == 6) CHECK(!memcmp(&saved, state->scheduler, sizeof(saved)));
        }
        release_pool(vm, &f);
        CHECK(be_execprotected(vm, get_feature, &feature) == BE_OK);
        delete_checked(vm);
    }
    /* A context successfully allocated within this call must remain owned if
     * the following feature allocation throws, including on a fresh VM. */
    for (mode = 1; mode <= 2; ++mode) {
        bvm *vm = plain_vm();
        filler f;
        size_t before;
        exhaust_pool(vm, &f);
        if (f.count && (f.sizes[f.count - 1] == sizeof(p2_vm_state) ||
                        sizeof(p2_vm_state) <= 16)) {
            --f.count;
            be_free(vm, f.blocks[f.count], f.sizes[f.count]); /* one context slot */
        } else {
            /* A larger context uses direct allocation even when the exhausted
             * RNG pool contributed filler slots. Permit only that allocation. */
            fail_after = 1;
        }
        before = be_gc_memcount(vm);
        CHECK(be_execprotected(vm, get_feature, &mode) == BE_MALLOC_FAIL);
        CHECK(vm->native_context != NULL && vm->native_context_delete != NULL);
        CHECK(be_gc_memcount(vm) == before + sizeof(p2_vm_state));
        CHECK(((p2_vm_state *)vm->native_context)->scheduler == NULL);
        CHECK(((p2_vm_state *)vm->native_context)->rng == NULL);
        release_pool(vm, &f);
        CHECK(be_execprotected(vm, get_feature, &mode) == BE_OK);
        delete_checked(vm);
    }
    /* Actual task and math callbacks propagate allocator errors through
     * be_pcall, and remain usable after allocation is restored. */
    for (mode = 0; mode < 3; ++mode) {
        static const bntvfunc callbacks[] = {p2_math_rand, p2_math_srand, m_task_current};
        bvm *vm = plain_vm();
        filler f;
        int top, rc;
        exhaust_pool(vm, &f);
        top = be_top(vm);
        be_pushntvfunction(vm, callbacks[mode]);
        rc = be_pcall(vm, 0);
        CHECK(rc == BE_MALLOC_FAIL);
        CHECK(vm->native_context == NULL);
        be_pop(vm, be_top(vm) - top);
        release_pool(vm, &f);
        CHECK(random_value(vm) == 1960601816);
        CHECK(p2_vm_scheduler(vm)->current == -1);
        delete_checked(vm);
    }
}

static p2_vm_state *reentered_state;
static int reentry_feature;
static unsigned reentry_calls;
static int reenter(bvm *vm)
{
    ++reentry_calls;
    fail_after = -1; /* release the host allocation fault, not a Berry stub */
    get_feature(vm, &reentry_feature);
    reentered_state = vm->native_context;
    if (reentry_feature == 1) reentered_state->scheduler->next = 7;
    if (reentry_feature == 2) reentered_state->rng->value = 99;
    be_return_nil(vm);
}
static void allocation_reentry(void)
{
    int feature;
    for (feature = 0; feature < 3; ++feature) {
        bvm *vm = plain_vm();
        filler f;
        size_t before, added;
        if (feature) p2_vm_state_get(vm);
        reentry_feature = feature;
        reentry_calls = 0;
        reentered_state = NULL;
        be_newcomobj(vm, &reentry_calls, reenter);
        exhaust_pool(vm, &f); /* keep common object rooted until exhaustion */
        CHECK(reentry_calls == 0);
        be_pop(vm, 1);
        before = be_gc_memcount(vm);
        added = feature == 0 ? sizeof(p2_vm_state) :
            (feature == 1 ? sizeof(p2_task_state) : sizeof(p2_rng_state));
        CHECK(be_execprotected(vm, get_feature, &feature) == BE_OK);
        CHECK(reentry_calls == 1 && reentered_state == vm->native_context);
        CHECK(be_gc_memcount(vm) == before + added - sizeof(bcommomobj));
        if (feature == 1) CHECK(reentered_state->scheduler->next == 7);
        if (feature == 2) CHECK(reentered_state->rng->value == 99);
        release_pool(vm, &f);
        delete_checked(vm);
    }
}

/* The host lacks UART, but the real VM opcode hook calls production poll
 * and cancellation code. No replacement interpreter or exception mechanism. */
extern int p2_vm_poll_due(bvm *vm);
extern void p2_vm_set_cancel_flag(bvm *vm, const volatile int *flag);
void p2_check_interrupt(bvm *vm) { (void)p2_vm_poll_due(vm); }
static volatile int requested;
static int request_stop(bvm *vm)
{
    requested = 1;
    fail_after = 0; /* cancellation must still unwind under allocator failure */
    be_return_nil(vm);
}
static void interrupt_isolation(void)
{
    bvm *a = plain_vm(), *b = plain_vm();
    unsigned i;
    for (i = 0; i < 1023; ++i) CHECK(!p2_vm_poll_due(a));
    CHECK(!p2_vm_poll_due(b));
    CHECK(p2_vm_poll_due(a));
    CHECK(a->native_context == NULL && b->native_context == NULL);
    for (i = 0; i < 1022; ++i) CHECK(!p2_vm_poll_due(b));
    CHECK(p2_vm_poll_due(b));
    delete_checked(a); delete_checked(b);
}
static void cooperative_cancel(void)
{
    bvm *a = plain_vm(), *b = plain_vm();
    int status;
    requested = 0;
    p2_vm_set_cancel_flag(a, &requested);
    be_regfunc(a, "request_stop", request_stop);
    status = be_loadstring(a, "try request_stop() var n=0 while n<100000 n+=1 end except .. return 999 end return 777");
    CHECK(status == BE_OK);
    if (status == BE_OK) status = be_pcall(a, 0);
    fail_after = -1;
    CHECK(status == BE_EXIT); /* cannot be swallowed by Berry except .. */
    be_pop(a, be_top(a));
    CHECK(be_loadstring(b, "return 42") == BE_OK);
    CHECK(be_pcall(b, 0) == BE_OK && be_toint(b, -1) == 42);
    be_pop(b, be_top(b));
    p2_vm_set_cancel_flag(a, NULL);
    CHECK(be_loadstring(a, "return 17") == BE_OK);
    CHECK(be_pcall(a, 0) == BE_OK && be_toint(a, -1) == 17);
    be_pop(a, be_top(a));
    delete_checked(a); delete_checked(b);
}

#include "p2_cache_under_test.h"

static void module_name_root(void)
{
    bvm *vm = plain_vm();
    ptrdiff_t old_top = vm->top - vm->stack;
    be_cache_p2module(vm);
    CHECK(vm->top - vm->stack == old_top);
    be_gc_collect(vm);
    be_getglobal(vm, "p2");
    CHECK(be_ismodule(vm, -1));
    {
        const char *name = be_module_name(var_toobj(vm->top - 1));
        CHECK(name != NULL);
        if (name) CHECK(!strcmp(name, "p2"));
    }
    be_setglobal(vm, "expected_p2");
    be_pop(vm, 1);
    /* Real module-cache lookup: never treat a global alias as import proof. */
    script(vm, "import p2");
    be_getglobal(vm, "expected_p2");
    be_getglobal(vm, "p2");
    CHECK(var_ismodule(vm->top - 1));
    CHECK(var_toobj(vm->top - 1) == var_toobj(vm->top - 2));
    be_pop(vm, 2);
    be_vm_delete(vm);
}

typedef struct { size_t calls, live; long budget; } allocator_probe;
typedef union { struct { allocator_probe *owner; size_t size; } meta; long double alignment; } allocator_header;
static void *probe_allocator(void *context, void *ptr, size_t size)
{
    allocator_probe *p = context;
    allocator_header *h = ptr ? (allocator_header *)ptr - 1 : NULL;
    ++p->calls;
    if (h) { CHECK(h->meta.owner == p); }
    if (!size) { if (h) { --p->live; test_free(h); } return NULL; }
    if (p->budget == 0) return NULL;
    if (p->budget > 0) --p->budget;
    if (size > (size_t)-1 - sizeof(*h)) return NULL;
    h = test_realloc(h, size + sizeof(*h));
    if (!h) return NULL;
    if (!ptr) ++p->live;
    h->meta.owner = p; h->meta.size = size;
    return h + 1;
}
static bvm *probe_vm(allocator_probe *p)
{
#ifdef BE_VM_ALLOCATOR_API
    return be_vm_new_with_allocator(probe_allocator, p);
#else
    (void)p; (void)probe_allocator;
    return be_vm_new(); /* baseline must fail routing, not fail to link */
#endif
}
static void default_constructor(void)
{
    bvm *vm = be_vm_new();
    CHECK(vm != NULL);
    if (vm) be_vm_delete(vm);
    vm = be_vm_new_with_allocator(NULL, NULL);
    CHECK(vm != NULL);
    if (vm) be_vm_delete(vm);
#ifdef BE_VM_OPTIONS_API
    {
        bvm_options options = {0};
        vm = be_vm_new_with_options(NULL);
        CHECK(vm != NULL);
        if (vm) {
            script(vm, "assert(size([1,2,3]) == 3)");
            be_vm_delete(vm);
        }
        vm = be_vm_new_with_options(&options);
        CHECK(vm != NULL);
        if (vm) {
            script(vm, "assert(size([1,2,3]) == 3)");
            be_vm_delete(vm);
        }
        options.allocator_context = (void *)1;
        CHECK(be_vm_new_with_options(&options) == NULL);
    }
#endif
#if BE_DEBUG
    /* Preserve the existing debug assertion contract for default APIs.
     * Each expected abort is isolated from the test runner; never dump cores. */
    int default_apis = 2;
#ifdef BE_VM_OPTIONS_API
    ++default_apis;
#endif
    for (int use_wrapper = 0; use_wrapper < default_apis; ++use_wrapper) {
        int status = 0;
        pid_t child = fork();
        CHECK(child >= 0);
        if (child == 0) {
            struct rlimit limit = {0, 0};
            if (setrlimit(RLIMIT_CORE, &limit) != 0) _exit(78);
            fail_after = 0;
#ifdef BE_VM_OPTIONS_API
            if (use_wrapper == 2) vm = be_vm_new_with_options(NULL);
            else
#endif
            vm = use_wrapper ? be_vm_new() : be_vm_new_with_allocator(NULL, NULL);
            (void)vm;
            _exit(77); /* returning NULL is the regression, not a pass */
        }
        if (child > 0) {
            CHECK(waitpid(child, &status, 0) == child);
            CHECK(WIFSIGNALED(status));
            CHECK(WIFSIGNALED(status) && WTERMSIG(status) == SIGABRT);
        }
    }
#endif
}

static void allocator_context(void)
{
    allocator_probe a = {0, 0, -1}, b = {0, 0, -1};
    bvm *va = probe_vm(&a), *vb = probe_vm(&b);
    CHECK(va != NULL && vb != NULL);
    CHECK(a.calls > 0 && b.calls > 0);
    if (va && vb) {
        script(va, "var private_value=71 var held=[] for i:0..100 held.push(str(i)) end");
        script(vb, "var private_value=29 var held=[] for i:0..70 held.push(str(i)) end");
        be_gc_collect(va); be_gc_collect(vb);
        script(va, "assert(private_value==71) assert(size(held)==101)");
        script(vb, "assert(private_value==29) assert(size(held)==71)");
    }
    if (va) be_vm_delete(va);
    CHECK(a.live == 0);
    if (vb) { script(vb, "assert(private_value==29)"); be_vm_delete(vb); }
    CHECK(b.live == 0);
#ifdef BE_VM_ALLOCATOR_API
    {
        int budget, successes = 0, refused = 0;
        for (budget = 0; budget < 220; ++budget) {
            allocator_probe p = {0, 0, budget};
            bvm *vm = probe_vm(&p);
            if (vm) { ++successes; be_vm_delete(vm); }
            else ++refused;
            CHECK(p.live == 0);
        }
        CHECK(successes > 0 && refused > 0);
        CHECK(be_vm_new_with_allocator(NULL, &a) == NULL);
    }
#endif
}

/* Deterministic nested allocator calls interleave COMPLETE Berry constructors,
 * without pthreads or a mocked VM. The fallback reproduces the old worker's
 * global-option protocol so the same regression runs RED before the API exists. */
typedef struct {
    volatile int stage;
    unsigned calls, mask;
#ifdef BE_VM_OPTIONS_API
    bvm_options *mutate;
#endif
} constructor_trace;
#ifdef BE_VM_OPTIONS_API
static void constructor_observe(void *context, int stage)
{
    constructor_trace *t = context;
    t->stage = stage;
    ++t->calls;
    if (stage >= 1 && stage <= 9) t->mask |= 1u << stage;
    if (stage == 1 && t->mutate) {
        /* The constructor must already own a value-copy, not re-read this. */
        t->mutate->skip_loadlibs = !t->mutate->skip_loadlibs;
        t->mutate->progress = NULL;
        t->mutate->progress_context = NULL;
        t->mutate->allocator = NULL;
        t->mutate->allocator_context = NULL;
    }
}
#endif
static bvm *configured_vm(bvm_allocator allocator, void *context, int skip,
                         constructor_trace *trace)
{
#ifdef BE_VM_OPTIONS_API
    bvm_options options = {0};
    bvm *vm;
    options.allocator = allocator;
    options.allocator_context = context;
    options.skip_loadlibs = skip;
    options.progress = constructor_observe;
    options.progress_context = trace;
    trace->mutate = &options;
    vm = be_vm_new_with_options(&options);
    trace->mutate = NULL;
    return vm;
#else
    extern volatile int berry_vm_new_skip_loadlibs;
    extern volatile int *berry_vm_new_diag_stage_ptr;
    bvm *vm;
    berry_vm_new_skip_loadlibs = skip;
    berry_vm_new_diag_stage_ptr = &trace->stage;
    vm = be_vm_new_with_allocator(allocator, context);
    berry_vm_new_skip_loadlibs = 0;
    berry_vm_new_diag_stage_ptr = NULL;
    return vm;
#endif
}
typedef struct {
    allocator_probe own, peer;
    constructor_trace *peer_trace;
    bvm *peer_vm;
    int fired, peer_skip;
} interleaved_allocator;
static void *interleaved_alloc(void *context, void *ptr, size_t size)
{
    interleaved_allocator *p = context;
    if (size && !p->fired && p->own.calls == 2) {
        p->fired = 1;
        p->peer_vm = configured_vm(probe_allocator, &p->peer, p->peer_skip,
                                  p->peer_trace);
    }
    return probe_allocator(&p->own, ptr, size);
}
static void constructor_isolation(void)
{
    int skip, budget, scenario;
    for (skip = 0; skip <= 1; ++skip) {
        constructor_trace a = {0}, b = {0};
        interleaved_allocator p = {{0, 0, -1}, {0, 0, -1}, &b, NULL, 0, !skip};
        bvm *vm = configured_vm(interleaved_alloc, &p, skip, &a);
        CHECK(vm != NULL && p.peer_vm != NULL && p.fired);
        CHECK(a.stage == 9 && b.stage == 9);
#ifdef BE_VM_OPTIONS_API
        CHECK(a.mask == 0x3fe && b.mask == 0x3fe);
        CHECK(vm == NULL || (vm->construction_progress == NULL && vm->construction_context == NULL));
        CHECK(p.peer_vm == NULL || (p.peer_vm->construction_progress == NULL && p.peer_vm->construction_context == NULL));
#endif
        if (vm && p.peer_vm) {
            unsigned a_calls = a.calls, b_calls = b.calls;
            CHECK((be_builtin_count(vm) == 0) == skip);
            CHECK((be_builtin_count(p.peer_vm) == 0) == !skip);
            /* A library-free precompiled host VM must finish builtin setup
             * before general parsing. This is real be_loadlibs, not a seam. */
            if (!be_builtin_count(vm)) be_loadlibs(vm);
            if (!be_builtin_count(p.peer_vm)) be_loadlibs(p.peer_vm);
            /* Real compile/execute, independent globals and live peer after
             * deletion. */
            script(vm, "var private_value=71");
            script(p.peer_vm, "var private_value=29");
            be_gc_collect(vm); be_gc_collect(p.peer_vm);
            CHECK(be_getglobal(vm, "private_value") && be_toint(vm, -1) == 71);
            be_pop(vm, 1);
            be_vm_delete(vm); vm = NULL;
            CHECK(p.own.live == 0);
            CHECK(be_getglobal(p.peer_vm, "private_value") && be_toint(p.peer_vm, -1) == 29);
            be_pop(p.peer_vm, 1);
            be_vm_delete(p.peer_vm); p.peer_vm = NULL;
            CHECK(a.calls == a_calls && b.calls == b_calls);
            CHECK(a.stage == 9 && b.stage == 9);
        }
        if (vm) be_vm_delete(vm);
        if (p.peer_vm) be_vm_delete(p.peer_vm);
        CHECK(p.own.live == 0 && p.peer.live == 0);
    }
    /* Failure at each constructor budget, both library policies. */
    for (skip = 0; skip <= 1; ++skip) {
        int refused = 0, succeeded = 0;
        for (budget = 0; budget < 220; ++budget) {
            constructor_trace t = {0};
            allocator_probe p = {0, 0, budget};
            bvm *vm = configured_vm(probe_allocator, &p, skip, &t);
            if (vm) {
                ++succeeded;
                CHECK(t.stage == 9);
                CHECK((be_builtin_count(vm) == 0) == skip);
                be_vm_delete(vm);
            } else {
                ++refused;
                CHECK(t.stage >= 2 && t.stage <= 8);
            }
            CHECK(p.live == 0);
        }
        CHECK(refused > 0 && succeeded > 0);
    }
    /* A freed diagnostic destination must never be retained by the VM.
     * Post-constructor OOM must unwind with the ordinary allocator intact. */
    for (skip = 0; skip <= 1; ++skip) {
      for (scenario = 0; scenario < 4; ++scenario) {
        int refused = 0, succeeded = 0;
        for (budget = 0; budget < 180; ++budget) {
            static const char *sources[] = {
                "var text='owned' def f(x) return x+'-copy' end return f(text)",
                "return '012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'",
                "def broken( return",
                "return [1,2,3].copy()[1]"
            };
            allocator_probe p = {0, 0, -1};
            constructor_trace *t = test_malloc(sizeof(*t));
            bvm *vm;
            int rc, expected = scenario == 2 ? BE_EXCEPTION : BE_OK;
            memset(t, 0, sizeof(*t));
            vm = configured_vm(probe_allocator, &p, skip, t);
            CHECK(vm != NULL);
            test_free(t);
            if (!vm) continue;
            if (!be_builtin_count(vm)) be_loadlibs(vm);
            /* Last scenario injects during runtime list construction/copy;
             * others inject across real parser/lexer and execution. */
            if (scenario != 3) p.budget = budget;
            rc = be_loadstring(vm, sources[scenario]);
            if (scenario == 3) { CHECK(rc == BE_OK); p.budget = budget; }
            if (rc == BE_OK) rc = be_pcall(vm, 0);
            CHECK(rc == expected || rc == BE_MALLOC_FAIL);
            if (rc == expected) {
                ++succeeded;
                if (scenario == 0) CHECK(be_isstring(vm, -1) && !strcmp(be_tostring(vm, -1), "owned-copy"));
                if (scenario == 1) CHECK(be_isstring(vm, -1) && strlen(be_tostring(vm, -1)) == 90);
                if (scenario == 3) CHECK(be_isint(vm, -1) && be_toint(vm, -1) == 2);
            } else ++refused;
            p.budget = -1;
            be_pop(vm, be_top(vm));
            be_gc_collect(vm);
            CHECK(be_loadstring(vm, "return 117") == BE_OK);
            CHECK(be_pcall(vm, 0) == BE_OK && be_toint(vm, -1) == 117);
            be_pop(vm, be_top(vm));
            be_vm_delete(vm);
            CHECK(p.live == 0);
        }
        CHECK(refused > 0 && succeeded > 0);
      }
    }
}

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    if (!strcmp(argv[1], "scheduler_reset")) scheduler_reset();
    else if (!strcmp(argv[1], "rng_isolation")) rng_isolation();
    else if (!strcmp(argv[1], "rng_sequence")) rng_sequence();
    else if (!strcmp(argv[1], "scheduler_isolation")) scheduler_isolation();
    else if (!strcmp(argv[1], "scheduler_gc")) scheduler_gc();
    else if (!strcmp(argv[1], "rng_boundaries")) rng_boundaries();
    else if (!strcmp(argv[1], "lifecycle")) lifecycle();
    else if (!strcmp(argv[1], "allocation_failures")) allocation_failures();
    else if (!strcmp(argv[1], "allocation_reentry")) allocation_reentry();
    else if (!strcmp(argv[1], "interrupt_isolation")) interrupt_isolation();
    else if (!strcmp(argv[1], "cooperative_cancel")) cooperative_cancel();
    else if (!strcmp(argv[1], "module_name_root")) module_name_root();
    else if (!strcmp(argv[1], "allocator_context")) allocator_context();
    else if (!strcmp(argv[1], "default_constructor")) default_constructor();
    else if (!strcmp(argv[1], "constructor_isolation")) constructor_isolation();
    else return 2;
    CHECK(live_blocks == 0);
    printf("{\"case\":\"%s\",\"checks\":%u,\"failures\":%u,\"pointer_bits\":%u,\"bint_bits\":%u}\n",
           argv[1], checks, failures, (unsigned)(sizeof(void *) * CHAR_BIT),
           (unsigned)(sizeof(bint) * CHAR_BIT));
    return failures ? 1 : 0;
}
