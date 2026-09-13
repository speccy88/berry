/* Host-only execution of production clock arithmetic and, in the task build,
 * the real scheduler/Berry VM. Injected registers are not P2 HIL evidence. */
#include "p2_clock.h"
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned long checks;
static unsigned long tick_cases;
static unsigned long deadline_cases;
static unsigned long sampler_cases;
static unsigned long task_cases;

#define CHECK(test) do { \
    ++checks; \
    if (!(test)) { \
        fprintf(stderr, "FAIL line %d: %s (tick=%lu deadline=%lu task=%lu)\n", \
            __LINE__, #test, tick_cases, deadline_cases, task_cases); \
        exit(1); \
    } \
} while (0)

#ifdef __CATALINA_P2
static uint32_t mock_hz = 1000;
static uint32_t mock_high;
static uint32_t mock_low;
static int mock_retry;
static unsigned int high_reads;
static unsigned int low_reads;

uint32_t _clockfreq(void) { return mock_hz; }
uint32_t _cnth(void)
{
    ++high_reads;
    if (mock_retry) {
        /* Two torn samples, then a stable high/low/high sample. */
        return high_reads < 2 ? 0 : (high_reads < 4 ? 1 : 2);
    }
    return mock_high;
}
uint32_t _cnt(void)
{
    ++low_reads;
    return mock_retry && low_reads < 3 ? 0xffffffffU : mock_low;
}
void _waitms(int ms) { mock_low += (uint32_t)ms; }

static void test_sampler(void)
{
    uint32_t result = 123;
    mock_hz = 0;
    high_reads = low_reads = 0;
    CHECK(!p2_clock_millis_now(&result));
    CHECK(result == 123 && high_reads == 0 && low_reads == 0);
    ++sampler_cases;
    mock_hz = 1000;
    mock_high = 0xffffffffU;
    mock_low = 17;
    CHECK(p2_clock_millis_now(&result) && result == 17);
    CHECK(high_reads == 2 && low_reads == 1);
    ++sampler_cases;
    mock_retry = 1;
    high_reads = low_reads = 0;
    mock_low = 7;
    CHECK(p2_clock_millis_now(&result) && result == 7);
    CHECK(high_reads == 6 && low_reads == 3);
    ++sampler_cases;
    mock_retry = 0;
    mock_high = mock_low = 0;
}
#endif

static void test_vectors(const char *path)
{
    FILE *file = fopen(path, "r");
    char kind;
    unsigned long a, b, c, d, e, f, g, h;
    uint32_t q, r, ms;
    p2_deadline deadline;
    CHECK(file != NULL);
    while (fscanf(file, " %c", &kind) == 1) {
        if (kind == 'T') {
            CHECK(fscanf(file, "%lu %lu %lu %lu %lu %lu", &a, &b, &c, &d, &e, &f) == 6);
            ++tick_cases;
            CHECK(p2_clock_divmod((uint32_t)a, (uint32_t)b, (uint32_t)c, &q, &r));
            CHECK(q == d && r == e);
            CHECK(p2_clock_ticks_to_millis((uint32_t)a, (uint32_t)b, (uint32_t)c, &ms));
            if (ms != f) {
                fprintf(stderr, "ticks high=%lu low=%lu hz=%lu actual=%lu expected=%lu\n",
                    a, b, c, (unsigned long)ms, f);
            }
            CHECK(ms == f);
        } else {
            CHECK(kind == 'D');
            CHECK(fscanf(file, "%lu %lu %lu %lu %lu %lu %lu %lu",
                &a, &b, &c, &d, &e, &f, &g, &h) == 8);
            ++deadline_cases;
            deadline.at_ms = 123;
            deadline.armed = (int)h;
            CHECK(p2_deadline_arm(&deadline, (uint32_t)a, (uint32_t)b) == (int)d);
            if (d) {
                CHECK(deadline.armed && deadline.at_ms == e);
                CHECK(p2_deadline_reached(&deadline, (uint32_t)c) == (int)f);
                CHECK(p2_deadline_remaining(&deadline, (uint32_t)c) == g);
            } else {
                CHECK(deadline.armed == (int)h && deadline.at_ms == 123);
            }
            p2_deadline_cancel(&deadline);
            CHECK(!deadline.armed);
            CHECK(!p2_deadline_reached(&deadline, (uint32_t)c));
            CHECK(p2_deadline_remaining(&deadline, (uint32_t)c) == 0);
        }
    }
    CHECK(!ferror(file));
    CHECK(fclose(file) == 0);
    CHECK(tick_cases > 0 && deadline_cases > 0);
}

static void test_boundaries(void)
{
    uint32_t q = 123, r = 456, ms = 789;
    p2_deadline deadline = { 0, 0 };
    unsigned int i;
    uint32_t now = 0xfffffff0U;
    CHECK(CHAR_BIT == 8 && sizeof(uint32_t) == 4);
    CHECK(!p2_clock_divmod(0xffffffffU, 0xffffffffU, 0, &q, &r));
    CHECK(q == 123 && r == 456);
    CHECK(!p2_clock_ticks_to_millis(0xffffffffU, 0xffffffffU, 0, &ms));
    CHECK(ms == 789);
    CHECK(!p2_deadline_reached(&deadline, 0));
    CHECK(p2_deadline_arm(&deadline, 0xfffffff0U, 16));
    CHECK(deadline.armed && deadline.at_ms == 0);
    CHECK(!p2_deadline_reached(&deadline, 0xffffffffU));
    CHECK(p2_deadline_remaining(&deadline, 0xffffffffU) == 1);
    CHECK(p2_deadline_reached(&deadline, 0));
    CHECK(p2_deadline_arm(&deadline, 0, 0));
    CHECK(p2_deadline_reached(&deadline, 0));
    CHECK(!p2_deadline_reached(&deadline, 0x80000000U));
    for (i = 0; i < 100; ++i) {
        CHECK(p2_deadline_arm(&deadline, now, 60000));
        CHECK(!p2_deadline_reached(&deadline, now + 59999U));
        now += 60007U; /* late consumption, then fixed-delay rearm */
        CHECK(p2_deadline_reached(&deadline, now));
        CHECK(p2_deadline_remaining(&deadline, now) == 0);
    }
    p2_deadline_cancel(&deadline);
    CHECK(!p2_deadline_reached(&deadline, now));
}

#ifdef TEST_P2_TASK
/* Include actual scheduler so lifecycle checks can inspect its private slots.
 * Only hardware registers are injected; all Berry types/APIs are real. */
#include "../../port/p2/overrides/be_tasklib_p2.c"

static void script(bvm *vm, const char *source)
{
    int top = be_top(vm);
    int result = be_dostring(vm, source);
    if (result) {
        fprintf(stderr, "Berry integration script failed:\n%s\n", source);
        be_dumpexcept(vm);
    }
    CHECK(result == 0);
    be_pop(vm, be_top(vm) - top);
}

static void test_task_waits(bvm *vm)
{
    p2_task_slot *p2_task_slots = p2_vm_scheduler(vm)->slots;
    static const char *descriptors[] = {
        "task.sleep(timeout)", "task.wait('event', timeout)",
        "task.wait(task.Queue(1), timeout)", "task.wait(task.Semaphore(0), timeout)",
        "task.wait(mutex, timeout)", "task.wait(task.EventFlags(), 1, 'any', timeout)",
        "task.wait(task.Timer(120000, false), timeout)",
        "task.wait(channel, 'recv', timeout)", "task.wait(channel, 'send', timeout)",
        "task.wait(mailbox, 'get', timeout)", "task.wait(mailbox, 'put', timeout)",
        "task.wait(full_queue, 'put', timeout)"
    };
    static const int kinds[] = { 1, 2, 5, 6, 7, 8, 9, 3, 3, 4, 4, 5 };
    static const int delays[] = { 16, 0, 60000, -1 };
    unsigned int i, j;
    char source[1800];
    for (i = 0; i < sizeof(descriptors) / sizeof(descriptors[0]); ++i) {
        for (j = 0; j < sizeof(delays) / sizeof(delays[0]); ++j) {
            int delay = delays[j];
            if (i == 0 && delay < 0) { continue; } /* sleep keeps negative->0 coercion */
            mock_hz = 1000;
            mock_high = 0;
            mock_low = delay == 60000 ? 1234 : 0xfffffff0U;
            snprintf(source, sizeof(source),
                "import task\n task.reset()\n var count=0\n var timedout=false\n"
                "class IPC\n var _task_kind\n def init(kind) self._task_kind=kind end\n"
                "def wait_ready(mode) return false end\n end\n"
                "var channel=IPC('p2ipc_channel')\n var mailbox=IPC('p2ipc_mailbox')\n"
                "var full_queue=task.Queue(1)\n full_queue.put(42)\n"
                "var mutex=task.Mutex()\n mutex.lock()\n var timeout=%d\n var desc=%s\n"
                "def step()\n count+=1\n if count==1 return desc end\n"
                "timedout=task.woke_by_timeout()\n return task.done\n end\n"
                "var handle=task.start(step)\n assert(task.next()==handle)\n",
                delay, descriptors[i]);
            script(vm, source);
            CHECK(p2_task_slots[0].status == P2_TASK_WAITING);
            CHECK(p2_task_slots[0].wait_kind == kinds[i]);
            CHECK(p2_task_slots[0].deadline.armed == (delay >= 0));
            if (delay == 16) {
                CHECK(p2_task_slots[0].deadline.at_ms == 0);
                script(vm, "assert(task.lifecycle_result(handle)['deadline_armed'])\n"
                    "assert(task.lifecycle_result(handle)['deadline']==0)\n");
            }
            if (delay > 0) {
                mock_low += (uint32_t)delay - 1U;
                script(vm, "assert(task.next()==-1)\n assert(count==1)\n");
                ++mock_low;
            } else if (delay < 0) {
                mock_low += 1000;
                script(vm, "assert(task.next()==-1)\n assert(count==1)\n task.stop(handle)\n");
                CHECK(!p2_task_slots[0].deadline.armed);
                ++task_cases;
                continue;
            }
            script(vm, "assert(task.next()==handle)\n assert(count==2)\n assert(timedout)\n");
            CHECK(p2_task_slots[0].status == P2_TASK_FREE);
            CHECK(!p2_task_slots[0].deadline.armed);
            ++task_cases;
        }
    }
}

static void test_task_timers(bvm *vm)
{
    mock_hz = 1000;
    mock_high = 0;
    mock_low = 0xfffffff0U;
    script(vm, "import task\n task.reset()\n var timer=task.Timer(16, true)\n"
        "assert(timer.deadline==0)\n assert(timer.remaining()==16)\n"
        "assert(!timer.expired())\n assert(!timer.expired_result()['expired'])\n");
    mock_low = 0xffffffffU;
    script(vm, "assert(timer.remaining()==1)\n assert(!timer.expired())\n");
    mock_low = 0;
    script(vm, "assert(timer.remaining()==0)\n assert(timer.expired())\n"
        "assert(timer.deadline==16)\n assert(timer.remaining()==16)\n");
    mock_low = 20;
    script(vm, "var result=timer.expired_result()\n assert(result['expired'])\n"
        "assert(result['previous_deadline']==16)\n assert(result['deadline']==36)\n"
        "assert(timer.remaining()==16)\n assert(timer.cancel())\n"
        "assert(!timer.active)\n assert(timer.remaining()==0)\n assert(!timer.expired())\n"
        "assert(timer.restart())\n assert(timer.deadline==36)\n"
        "assert(timer.cancel_result()['ok'])\n assert(!timer.active)\n"
        "assert(timer.restart_result()['deadline']==36)\n assert(timer.active)\n");
    ++task_cases;
    mock_low = 0x7ffffff8U;
    script(vm, "timer=task.Timer(16, false)\n assert(timer.deadline<0)\n"
        "assert(timer.remaining()==16)\n assert(!timer.expired())\n"
        "assert(timer.remaining_result()['remaining_ms']==16)\n"
        "assert(timer.remaining_result()['deadline']==timer.deadline)\n"
        "assert(timer.info()['remaining_ms']==16)\n");
    mock_low = 0x80000008U;
    script(vm, "assert(timer.remaining()==0)\n assert(timer.expired_result()['expired'])\n"
        "assert(!timer.active)\n assert(!timer.expired())\n"
        "timer=task.Timer(0, false)\n assert(timer.expired())\n assert(!timer.active)\n");
    ++task_cases;
    mock_low = 0;
    script(vm, "timer=task.Timer(2147483647, false)\n assert(timer.remaining()==2147483647)\n");
    mock_low = 0x7fffffffU;
    script(vm, "assert(timer.expired())\n");
    ++task_cases;
    /* Both repeat APIs must remain active when rearming lands exactly on 0. */
    mock_low = 0xffffffe0U;
    script(vm, "timer=task.Timer(16, true)\n var other=task.Timer(16, true)\n");
    mock_low = 0xfffffff0U;
    script(vm, "assert(timer.expired())\n assert(timer.deadline==0)\n assert(timer.active)\n"
        "assert(other.expired_result()['deadline']==0)\n assert(other.active)\n"
        "assert(timer.remaining_result()['remaining_ms']==16)\n"
        "assert(other.info()['remaining_ms']==16)\n");
    mock_low = 0xffffffffU;
    script(vm, "assert(!timer.expired())\n assert(!other.expired_result()['expired'])\n");
    mock_low = 0;
    script(vm, "assert(timer.expired())\n assert(other.expired_result()['expired'])\n"
        "assert(timer.deadline==16)\n assert(other.deadline==16)\n");
    ++task_cases;
}

static void advance_ticks(uint32_t ticks)
{
    uint32_t before = mock_low;
    mock_low += ticks;
    mock_high += mock_low < before;
}

static void test_task_counter_wrap(bvm *vm)
{
    p2_task_slot *p2_task_slots = p2_vm_scheduler(vm)->slots;
    static const uint32_t frequencies[] = { 200000000U, 240000000U, 300000000U };
    unsigned int i, second, repeat;
    for (i = 0; i < sizeof(frequencies) / sizeof(frequencies[0]); ++i) {
        mock_hz = frequencies[i];
        mock_high = 0;
        mock_low = 0xffffffffU - mock_hz / 20U;
        /* Same 100 ms deadline / 120 ms elapsed regression as pre-fix RED,
         * but now through the real Timer and high/low/high sampler. */
        script(vm, "timer=task.Timer(100, false)\n assert(!timer.expired())\n");
        advance_ticks((mock_hz / 1000U) * 120U);
        CHECK(mock_high == 1);
        script(vm, "assert(timer.expired())\n assert(timer.remaining()==0)\n");
        ++task_cases;

        script(vm, "task.reset()\n var count=0\n def step()\n count+=1\n"
            "if count==1 return task.sleep(60000) end\n"
            "assert(task.woke_by_timeout())\n return task.done\n end\n"
            "var handle=task.start(step)\n assert(task.next()==handle)\n"
            "timer=task.Timer(60000, true)\n");
        for (repeat = 0; repeat < 3; ++repeat) {
            for (second = 0; second < 59; ++second) { advance_ticks(mock_hz); }
            script(vm, "assert(task.next()==-1)\n assert(!timer.expired())\n"
                "assert(timer.remaining()==1000)\n");
            advance_ticks(mock_hz);
            script(vm, "assert(timer.expired())\n assert(timer.remaining()==60000)\n");
            if (repeat == 0) {
                script(vm, "assert(task.next()==handle)\n assert(count==2)\n");
                CHECK(!p2_task_slots[0].deadline.armed);
            }
            ++task_cases;
        }
    }
}

static void test_task_readiness(bvm *vm)
{
    p2_task_slot *p2_task_slots = p2_vm_scheduler(vm)->slots;
    /* Ready events/objects still beat simultaneous timeouts; each wake must
     * disarm the timeout before the callback (not just when freeing a slot). */
    mock_hz = 1000;
    mock_high = 0;
    mock_low = 0xfffffff0U;
    script(vm, "task.reset()\n var queue=task.Queue(1)\n var count=0\n var ipc_ready=false\n"
        "class ReadyIPC\n var _task_kind\n def init() self._task_kind='p2ipc_channel' end\n"
        "def wait_ready(mode) return ipc_ready end\n end\n"
        "var channel=ReadyIPC()\n var timer=task.Timer(16, false)\n"
        "def step(desc)\n if task.lifecycle_result()['runs']==1 return desc end\n"
        "assert(!task.woke_by_timeout())\n"
        "assert(!task.lifecycle_result()['deadline_armed'])\n count+=1\n return task.done\n end\n"
        "var h0=task.start(step,task.wait('ready',16))\n"
        "var h1=task.start(step,task.wait(queue,16))\n"
        "var h2=task.start(step,task.wait(channel,16))\n"
        "var h3=task.start(step,task.wait(timer,16))\n"
        "assert(task.next()==h0)\n assert(task.next()==h1)\n"
        "assert(task.next()==h2)\n assert(task.next()==h3)\n"
        "task.signal('ready')\n queue.put(42)\n ipc_ready=true\n");
    mock_low = 0;
    script(vm, "assert(task.next()==h0)\n assert(task.next()==h1)\n"
        "assert(task.next()==h2)\n assert(task.next()==h3)\n assert(count==4)\n");
    CHECK(!p2_task_slots[0].deadline.armed && !p2_task_slots[1].deadline.armed);
    CHECK(!p2_task_slots[2].deadline.armed && !p2_task_slots[3].deadline.armed);
    ++task_cases;
}

static void test_task_lifecycle(bvm *vm)
{
    p2_task_slot *p2_task_slots = p2_vm_scheduler(vm)->slots;
    mock_hz = 1000;
    mock_high = mock_low = 0;
    script(vm, "import task\n task.reset()\n def sleeper() return task.sleep(60000) end\n"
        "var handle=task.start(sleeper)\n task.next()\n"
        "assert(task.lifecycle_result(handle)['deadline_armed'])\n task.pause(handle)\n"
        "assert(!task.lifecycle_result(handle)['deadline_armed'])\n task.resume(handle)\n"
        "task.next()\n assert(task.lifecycle_result(handle)['deadline_armed'])\n"
        "task.pause_result(handle)\n assert(!task.lifecycle_result(handle)['deadline_armed'])\n"
        "task.resume_result(handle)\n task.next()\n task.stop_result(handle)\n"
        "assert(!task.lifecycle_result(handle)['deadline_armed'])\n"
        "handle=task.start(sleeper)\n task.next()\n task.reset_result()\n"
        "assert(!task.lifecycle_result(handle)['deadline_armed'])\n");
    CHECK(!p2_task_slots[0].deadline.armed);
    ++task_cases;
    script(vm, "var caught=false\n try task.Timer(2147483648) except 'value_error' caught=true end\n"
        "assert(caught)\n caught=false\n try task.sleep(4294967296) except 'value_error' caught=true end\n"
        "assert(caught)\n caught=false\n try task.wait('x',2147483648) except 'value_error' caught=true end\n"
        "assert(caught)\n timer=task.Timer(10)\n timer.period_ms=4294967296\n caught=false\n"
        "try timer.restart() except 'value_error' caught=true end\n assert(caught)\n"
        "caught=false\n try task.run(0,4294967296) except 'value_error' caught=true end\n assert(caught)\n"
        "caught=false\n try task.run_result(0,4294967296) except 'value_error' caught=true end\n assert(caught)\n");
    ++task_cases;
    mock_hz = 0;
    script(vm, "caught=false\n try task.millis() except 'runtime_error' as e,m\n"
        "caught=true\n assert(m=='P2 clock frequency is not configured')\n end\n assert(caught)\n"
        "caught=false\n try task.Timer(1) except 'runtime_error' caught=true end\n assert(caught)\n");
    ++task_cases;
    mock_hz = 1000;
}

static void test_task(void)
{
    bvm *vm = be_vm_new();
    CHECK(vm != NULL);
    /* The host const-string table lacks P2's permanent "task" string. */
    be_pushstring(vm, "task");
    be_cache_taskmodule(vm);
    be_pop(vm, 1);
    test_task_waits(vm);
    test_task_timers(vm);
    test_task_counter_wrap(vm);
    test_task_readiness(vm);
    test_task_lifecycle(vm);
    be_vm_delete(vm);
}
#endif

int main(int argc, char **argv)
{
    CHECK(argc == 2);
    test_boundaries();
    test_vectors(argv[1]);
#ifdef __CATALINA_P2
    test_sampler();
#endif
#ifdef TEST_P2_TASK
    test_task();
#endif
    printf("{\"tick_cases\":%lu,\"deadline_cases\":%lu,\"sampler_cases\":%lu,"
        "\"task_cases\":%lu,\"checks\":%lu,\"long_bits\":%lu,\"pointer_bits\":%lu}\n",
        tick_cases, deadline_cases, sampler_cases, task_cases, checks,
        (unsigned long)(sizeof(long) * CHAR_BIT), (unsigned long)(sizeof(void *) * CHAR_BIT));
    return 0;
}
