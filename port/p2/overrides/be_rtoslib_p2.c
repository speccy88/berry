/********************************************************************
** Small Propeller 2 RTOS-style module for Berry.
**
** This module deliberately stays inside the primitives that are already
** verified in the Catalina P2 build: worker mailbox dispatch, hardware locks,
** the system counter, cog-attention signals, and ordinary VM-safe callback
** dispatch. It does not run Berry code from a hardware ISR.
********************************************************************/
#include "berry.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_conf_p2.h"
#include "berry_port.h"
#include "berry_worker.h"

#include <cog.h>
#include <propeller2.h>
#include <stdint.h>
#include <string.h>

enum {
    RTOS_LOCK_COUNT = 16,
    RTOS_CHANNEL_MAX = 8,
    RTOS_NAME_MAX = 31,
    RTOS_QUEUE_MAX = 8,
    RTOS_TEXT_MAX = 63,
    RTOS_TIMER_MAX = 8,
    RTOS_IRQ_CHANNELS = 16,
    RTOS_IRQ_ATN = 14,
    RTOS_LOCK_UNUSED = -2
};

typedef enum rtos_value_type {
    RTOS_VALUE_EMPTY = 0,
    RTOS_VALUE_INT = 1,
    RTOS_VALUE_STRING = 2
} rtos_value_type;

typedef struct rtos_value {
    rtos_value_type type;
    int ivalue;
    char svalue[RTOS_TEXT_MAX + 1];
} rtos_value;

typedef struct rtos_channel {
    int used;
    int lock_id;
    char name[RTOS_NAME_MAX + 1];
    rtos_value queue[RTOS_QUEUE_MAX];
    int head;
    int tail;
    int count;
} rtos_channel;

typedef struct rtos_timer {
    int used;
    counter64_t target;
} rtos_timer;

typedef struct rtos_irq_slot {
    int enabled;
    volatile int pending;
    char handler[RTOS_NAME_MAX + 1];
} rtos_irq_slot;

static int g_rtos_locks[RTOS_LOCK_COUNT];
static int g_rtos_locks_ready;
static int g_rtos_state_lock = RTOS_LOCK_UNUSED;
static int g_rtos_event_lock = RTOS_LOCK_UNUSED;
static volatile uint32_t g_rtos_event_flags;
static rtos_channel g_rtos_channels[RTOS_CHANNEL_MAX];
static rtos_timer g_rtos_timers[RTOS_TIMER_MAX];
static rtos_irq_slot g_rtos_irq[RTOS_IRQ_CHANNELS];

static void rtos_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void rtos_init_user_locks(void)
{
    int i;

    if (g_rtos_locks_ready) {
        return;
    }
    for (i = 0; i < RTOS_LOCK_COUNT; ++i) {
        g_rtos_locks[i] = RTOS_LOCK_UNUSED;
    }
    g_rtos_locks_ready = 1;
}

static void rtos_bootstrap_state(void)
{
    rtos_init_user_locks();

    /* The module keeps two internal P2 semaphore bits: one protects registry
     * state such as channels/timers/IRQ slots, and the other protects the
     * shared event flag word. User-visible locks are allocated separately by
     * rtos.new_lock(). */
    if (g_rtos_state_lock == RTOS_LOCK_UNUSED) {
        g_rtos_state_lock = _locknew();
    }
    if (g_rtos_event_lock == RTOS_LOCK_UNUSED) {
        g_rtos_event_lock = _locknew();
    }
}

static bint rtos_require_int(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    return be_toint(vm, index);
}

static uint32_t rtos_require_u32(bvm *vm, int index, const char *what)
{
    return (uint32_t)rtos_require_int(vm, index, what);
}

static const char *rtos_require_name(bvm *vm, int index, const char *what)
{
    const char *name;
    size_t len;

    if (be_top(vm) < index || !be_isstring(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    name = be_tostring(vm, index);
    len = strlen(name);
    if (len == 0 || len > RTOS_NAME_MAX) {
        be_raise(vm, "value_error", "name is empty or too long");
    }
    return name;
}

static bint rtos_optional_timeout_ms(bvm *vm, int index)
{
    if (be_top(vm) < index || be_isnil(vm, index)) {
        return -1;
    }
    {
        bint timeout_ms = rtos_require_int(vm, index, "timeout_ms must be an int");
        if (timeout_ms < 0) {
            be_raise(vm, "value_error", "timeout_ms must be >= 0");
        }
        return timeout_ms;
    }
}

static int rtos_require_lock_id(bvm *vm, int index)
{
    bint lock = rtos_require_int(vm, index, "lock id must be an int");

    rtos_init_user_locks();
    if (lock < 0 || lock >= RTOS_LOCK_COUNT) {
        be_raise(vm, "value_error", "lock id must be between 0 and 15");
    }
    if (g_rtos_locks[(int)lock] != (int)lock) {
        be_raise(vm, "value_error", "lock id was not allocated by rtos.new_lock()");
    }
    return (int)lock;
}

static void rtos_acquire_lock_id(int lock)
{
    /* LOCKTRY spins on a shared hub resource, so every failed attempt yields
     * for 1 ms and keeps one cog from hammering hub access while another owns
     * a lock. */
    while (!_locktry(lock)) {
        _waitms(1);
    }
}

static void rtos_acquire_state(bvm *vm)
{
    if (g_rtos_state_lock < 0) {
        be_raise(vm, "runtime_error", "rtos state lock is not available");
    }
    rtos_acquire_lock_id(g_rtos_state_lock);
}

static void rtos_release_state(void)
{
    if (g_rtos_state_lock >= 0) {
        _lockrel(g_rtos_state_lock);
    }
}

static void rtos_acquire_event(bvm *vm)
{
    if (g_rtos_event_lock < 0) {
        be_raise(vm, "runtime_error", "rtos event lock is not available");
    }
    rtos_acquire_lock_id(g_rtos_event_lock);
}

static void rtos_release_event(void)
{
    if (g_rtos_event_lock >= 0) {
        _lockrel(g_rtos_event_lock);
    }
}

static int rtos_find_channel(const char *name)
{
    int i;

    for (i = 0; i < RTOS_CHANNEL_MAX; ++i) {
        if (g_rtos_channels[i].used &&
            strcmp(g_rtos_channels[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

static int rtos_find_or_create_channel(const char *name, int *lock_error)
{
    int i = rtos_find_channel(name);

    if (lock_error) {
        *lock_error = 0;
    }
    if (i >= 0) {
        return i;
    }
    for (i = 0; i < RTOS_CHANNEL_MAX; ++i) {
        if (!g_rtos_channels[i].used) {
            int lock_id = _locknew();

            /* Each mailbox gets its own hardware lock. The global state lock
             * is only used to find/create channel slots; queue head/tail/count
             * are protected by this per-channel semaphore. */
            if (lock_id < 0) {
                if (lock_error) {
                    *lock_error = 1;
                }
                return -1;
            }
            memset(&g_rtos_channels[i], 0, sizeof(g_rtos_channels[i]));
            g_rtos_channels[i].used = 1;
            g_rtos_channels[i].lock_id = lock_id;
            strncpy(g_rtos_channels[i].name, name, RTOS_NAME_MAX);
            g_rtos_channels[i].name[RTOS_NAME_MAX] = '\0';
            return i;
        }
    }
    return -1;
}

static void rtos_read_value(bvm *vm, int index, rtos_value *value)
{
    size_t len;

    memset(value, 0, sizeof(*value));
    if (be_top(vm) < index) {
        be_raise(vm, "type_error", "value is required");
    }
    if (be_isint(vm, index)) {
        value->type = RTOS_VALUE_INT;
        value->ivalue = (int)be_toint(vm, index);
        return;
    }
    if (be_isstring(vm, index)) {
        const char *text = be_tostring(vm, index);
        len = strlen(text);
        if (len > RTOS_TEXT_MAX) {
            be_raise(vm, "value_error", "channel string is too long");
        }
        value->type = RTOS_VALUE_STRING;
        memcpy(value->svalue, text, len + 1);
        return;
    }
    be_raise(vm, "type_error", "value must be an int or string");
}

static void rtos_push_value(bvm *vm, const rtos_value *value)
{
    switch (value->type) {
    case RTOS_VALUE_INT:
        be_pushint(vm, (bint)value->ivalue);
        break;
    case RTOS_VALUE_STRING:
        be_pushstring(vm, value->svalue);
        break;
    default:
        be_pushnil(vm);
        break;
    }
}

static void rtos_counter_add_ticks(counter64_t *value, uint32_t ticks)
{
    uint32_t old_low = value->low;

    value->low += ticks;
    if (value->low < old_low) {
        ++value->high;
    }
}

static uint32_t rtos_ms_chunk_ticks(uint32_t ms)
{
    return (uint32_t)(((uint64_t)_clockfreq() * (uint64_t)ms) / 1000u);
}

static counter64_t rtos_counter_after_ms(bint ms)
{
    counter64_t target = _cnthl();

    /* Catalina exposes the P2 counter as high/low words. Keeping timers in
     * counter64_t form avoids non-portable 64-bit shifts in the Catalina C
     * frontend while still handling low-word wrap correctly. */
    while (ms > 0) {
        uint32_t chunk_ms = ms > 1000 ? 1000u : (uint32_t)ms;
        rtos_counter_add_ticks(&target, rtos_ms_chunk_ticks(chunk_ms));
        ms -= (bint)chunk_ms;
    }
    return target;
}

static void rtos_wait_ms_counter(bvm *vm, bint ms)
{
    while (ms > 0) {
        uint32_t chunk_ms = ms > 1000 ? 1000u : (uint32_t)ms;
        uint32_t ticks = rtos_ms_chunk_ticks(chunk_ms);

        if (ticks > 0u) {
            _waitcnt(_cnt() + ticks);
        }
        ms -= (bint)chunk_ms;
        p2_check_interrupt_now(vm);
    }
}

static int rtos_timer_expired_target(const counter64_t *target)
{
    counter64_t now = _cnthl();

    return now.high > target->high ||
        (now.high == target->high && now.low >= target->low);
}

static void rtos_map_set_int(bvm *vm, const char *key, bint value)
{
    be_pushstring(vm, key);
    be_pushint(vm, value);
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static void rtos_map_set_bool(bvm *vm, const char *key, int value)
{
    be_pushstring(vm, key);
    be_pushbool(vm, value ? 1 : 0);
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static void rtos_map_set_string(bvm *vm, const char *key, const char *value)
{
    be_pushstring(vm, key);
    be_pushstring(vm, value);
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static const char *rtos_cog_state_name(int cog)
{
    int worker_cog = berry_worker_cog_id();
    int raw = _cogchk(cog);

    if (!raw) {
        return "free";
    }
    if (cog == worker_cog) {
        return berry_worker_state_name(berry_worker_mailbox_state());
    }
    return "running";
}

static void rtos_mark_irq_mask_locked(uint32_t mask)
{
    int channel;

    /* irq_* is intentionally deferred: event bits mark callbacks pending, and
     * Berry code dispatches them later through rtos.irq_poll(). This keeps the
     * VM out of interrupt context and matches the current COMPACT build. */
    for (channel = 0; channel < RTOS_IRQ_CHANNELS; ++channel) {
        if ((mask & (1u << channel)) && g_rtos_irq[channel].enabled) {
            g_rtos_irq[channel].pending = 1;
        }
    }
}

static void rtos_mark_irq_mask(bvm *vm, uint32_t mask)
{
    rtos_acquire_state(vm);
    rtos_mark_irq_mask_locked(mask);
    rtos_release_state();
}

static int m_rtos_spawn(bvm *vm)
{
    const char *name = rtos_require_name(vm, 1, "function name must be a string");
    int argc = be_top(vm) - 1;
    int argv[BERRY_WORKER_ARGS_MAX];
    int i;
    const char *error = NULL;
    int cog;

    if (argc > BERRY_WORKER_ARGS_MAX) {
        be_raise(vm, "value_error", "too many task arguments");
    }
    for (i = 0; i < argc; ++i) {
        argv[i] = (int)rtos_require_int(vm, i + 2, "task arguments must be ints");
    }

    cog = berry_worker_start_cog(&error);
    if (cog < 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start worker cog");
    }
    if (berry_worker_exec_ints(name, argc, argv, &error) != 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to launch worker task");
    }

    be_pushint(vm, (bint)cog);
    be_return(vm);
}

static int m_rtos_load(bvm *vm)
{
    const char *source;
    const char *error = NULL;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "source must be a string");
    }
    source = be_tostring(vm, 1);
    if (berry_worker_start_cog(&error) < 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start worker cog");
    }
    if (berry_worker_load_source(source, &error) != 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to load worker source");
    }
    be_return_nil(vm);
}

static int m_rtos_stop(bvm *vm)
{
    (void)vm;
    berry_worker_stop_cog();
    be_return_nil(vm);
}

static int m_rtos_state(bvm *vm)
{
    be_pushstring(vm, berry_worker_state_name(berry_worker_mailbox_state()));
    be_return(vm);
}

static int m_rtos_error(bvm *vm)
{
    const char *error = berry_worker_last_error();

    if (error) {
        be_pushstring(vm, error);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_rtos_yield(bvm *vm)
{
    (void)vm;
    _waitms(0);
    be_return_nil(vm);
}

static int m_rtos_sleep_ms(bvm *vm)
{
    bint ms = rtos_require_int(vm, 1, "ms must be an int");

    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }
    while (ms > 0) {
        uint32_t chunk = ms > 10 ? 10u : (uint32_t)ms;
        _waitms(chunk);
        ms -= (bint)chunk;
        p2_check_interrupt_now(vm);
    }
    p2_check_interrupt_now(vm);
    be_return_nil(vm);
}

static int m_rtos_cog_id(bvm *vm)
{
    be_pushint(vm, (bint)_cogid());
    be_return(vm);
}

static int m_rtos_new_lock(bvm *vm)
{
    int lock;

    rtos_init_user_locks();
    lock = _locknew();
    if (lock < 0 || lock >= RTOS_LOCK_COUNT) {
        be_raise(vm, "runtime_error", "no hardware locks available");
    }
    g_rtos_locks[lock] = lock;
    be_pushint(vm, (bint)lock);
    be_return(vm);
}

static int m_rtos_lock(bvm *vm)
{
    int lock = rtos_require_lock_id(vm, 1);

    rtos_acquire_lock_id(lock);
    be_return_nil(vm);
}

static int m_rtos_try_lock(bvm *vm)
{
    int lock = rtos_require_lock_id(vm, 1);

    be_pushbool(vm, _locktry(lock) != 0);
    be_return(vm);
}

static int m_rtos_unlock(bvm *vm)
{
    int lock = rtos_require_lock_id(vm, 1);

    _lockrel(lock);
    be_return_nil(vm);
}

static int m_rtos_delete_lock(bvm *vm)
{
    int lock = rtos_require_lock_id(vm, 1);

    _lockret(lock);
    g_rtos_locks[lock] = RTOS_LOCK_UNUSED;
    be_return_nil(vm);
}

static int m_rtos_channel(bvm *vm)
{
    const char *name = rtos_require_name(vm, 1, "channel name must be a string");
    int index;
    int lock_error;

    rtos_acquire_state(vm);
    index = rtos_find_or_create_channel(name, &lock_error);
    rtos_release_state();

    if (lock_error) {
        be_raise(vm, "runtime_error", "no hardware locks available for channel");
    }
    if (index < 0) {
        be_raise(vm, "runtime_error", "no channel slots available");
    }
    be_pushstring(vm, name);
    be_return(vm);
}

static int m_rtos_put(bvm *vm)
{
    const char *name = rtos_require_name(vm, 1, "channel name must be a string");
    rtos_value value;
    int index;
    int lock_id = -1;
    int lock_error;
    int ok = 0;

    rtos_read_value(vm, 2, &value);

    rtos_acquire_state(vm);
    index = rtos_find_or_create_channel(name, &lock_error);
    if (index >= 0) {
        lock_id = g_rtos_channels[index].lock_id;
    }
    rtos_release_state();

    if (lock_error) {
        be_raise(vm, "runtime_error", "no hardware locks available for channel");
    }
    if (index < 0) {
        be_raise(vm, "runtime_error", "no channel slots available");
    }

    rtos_acquire_lock_id(lock_id);
    if (g_rtos_channels[index].count < RTOS_QUEUE_MAX) {
        g_rtos_channels[index].queue[g_rtos_channels[index].tail] = value;
        g_rtos_channels[index].tail = (g_rtos_channels[index].tail + 1) % RTOS_QUEUE_MAX;
        ++g_rtos_channels[index].count;
        ok = 1;
    }
    _lockrel(lock_id);

    if (!ok) {
        be_raise(vm, "runtime_error", "channel is full");
    }
    be_pushbool(vm, 1);
    be_return(vm);
}

static int m_rtos_get(bvm *vm)
{
    const char *name = rtos_require_name(vm, 1, "channel name must be a string");
    bint timeout_ms = rtos_optional_timeout_ms(vm, 2);
    bint waited = 0;
    rtos_value value;
    int found = 0;

    memset(&value, 0, sizeof(value));
    for (;;) {
        int index;
        int lock_id = -1;

        rtos_acquire_state(vm);
        index = rtos_find_channel(name);
        if (index >= 0) {
            lock_id = g_rtos_channels[index].lock_id;
        }
        rtos_release_state();

        if (index >= 0) {
            rtos_acquire_lock_id(lock_id);
            if (g_rtos_channels[index].count > 0) {
                value = g_rtos_channels[index].queue[g_rtos_channels[index].head];
                memset(&g_rtos_channels[index].queue[g_rtos_channels[index].head],
                    0, sizeof(rtos_value));
                g_rtos_channels[index].head = (g_rtos_channels[index].head + 1) % RTOS_QUEUE_MAX;
                --g_rtos_channels[index].count;
                found = 1;
            }
            _lockrel(lock_id);
        }

        if (found || (timeout_ms >= 0 && waited >= timeout_ms)) {
            break;
        }
        _waitms(1);
        if (timeout_ms >= 0) {
            ++waited;
        }
        p2_check_interrupt_now(vm);
    }

    if (found) {
        rtos_push_value(vm, &value);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_rtos_event_set(bvm *vm)
{
    uint32_t mask = rtos_require_u32(vm, 1, "mask must be an int");

    if (mask == 0u) {
        be_raise(vm, "value_error", "mask must be non-zero");
    }
    rtos_acquire_event(vm);
    g_rtos_event_flags |= mask;
    rtos_release_event();

    rtos_mark_irq_mask(vm, mask);
    _cogatn(0xffu);
    be_return_nil(vm);
}

static int m_rtos_event_clear(bvm *vm)
{
    uint32_t mask = rtos_require_u32(vm, 1, "mask must be an int");

    if (mask == 0u) {
        be_raise(vm, "value_error", "mask must be non-zero");
    }
    rtos_acquire_event(vm);
    g_rtos_event_flags &= ~mask;
    rtos_release_event();
    be_return_nil(vm);
}

static int m_rtos_event_wait(bvm *vm)
{
    uint32_t mask = rtos_require_u32(vm, 1, "mask must be an int");
    bint timeout_ms = rtos_optional_timeout_ms(vm, 2);
    bint waited = 0;
    int matched = 0;

    if (mask == 0u) {
        be_raise(vm, "value_error", "mask must be non-zero");
    }
    for (;;) {
        rtos_acquire_event(vm);
        matched = ((g_rtos_event_flags & mask) != 0u);
        rtos_release_event();
        if (matched || (timeout_ms >= 0 && waited >= timeout_ms)) {
            break;
        }
        (void)_pollatn();
        _waitms(1);
        if (timeout_ms >= 0) {
            ++waited;
        }
        p2_check_interrupt_now(vm);
    }

    be_pushbool(vm, matched);
    be_return(vm);
}

static int m_rtos_event_flags(bvm *vm)
{
    uint32_t flags;

    rtos_acquire_event(vm);
    flags = g_rtos_event_flags;
    rtos_release_event();

    be_pushint(vm, (bint)flags);
    be_return(vm);
}

static int m_rtos_ticks_per_ms(bvm *vm)
{
    be_pushint(vm, (bint)(_clockfreq() / 1000u));
    be_return(vm);
}

static int m_rtos_delay_ms(bvm *vm)
{
    bint ms = rtos_require_int(vm, 1, "ms must be an int");

    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }
    rtos_wait_ms_counter(vm, ms);
    be_return_nil(vm);
}

static int m_rtos_timer_start(bvm *vm)
{
    bint ms = rtos_require_int(vm, 1, "ms must be an int");
    counter64_t target;
    int i;
    int selected = -1;

    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }
    target = rtos_counter_after_ms(ms);

    rtos_acquire_state(vm);
    for (i = 0; i < RTOS_TIMER_MAX; ++i) {
        if (!g_rtos_timers[i].used ||
            rtos_timer_expired_target(&g_rtos_timers[i].target)) {
            selected = i;
            g_rtos_timers[i].used = 1;
            g_rtos_timers[i].target = target;
            break;
        }
    }
    rtos_release_state();

    if (selected < 0) {
        be_raise(vm, "runtime_error", "no timer slots available");
    }
    be_pushint(vm, (bint)selected);
    be_return(vm);
}

static int m_rtos_timer_expired(bvm *vm)
{
    bint id = rtos_require_int(vm, 1, "timer id must be an int");
    counter64_t target;
    int used = 0;

    if (id < 0 || id >= RTOS_TIMER_MAX) {
        be_raise(vm, "value_error", "timer id is out of range");
    }

    rtos_acquire_state(vm);
    used = g_rtos_timers[(int)id].used;
    target = g_rtos_timers[(int)id].target;
    rtos_release_state();

    if (!used) {
        be_raise(vm, "value_error", "timer id is not active");
    }
    be_pushbool(vm, rtos_timer_expired_target(&target));
    be_return(vm);
}

static int m_rtos_timer_wait(bvm *vm)
{
    bint id = rtos_require_int(vm, 1, "timer id must be an int");
    counter64_t target;
    int used = 0;

    if (id < 0 || id >= RTOS_TIMER_MAX) {
        be_raise(vm, "value_error", "timer id is out of range");
    }

    rtos_acquire_state(vm);
    used = g_rtos_timers[(int)id].used;
    target = g_rtos_timers[(int)id].target;
    rtos_release_state();

    if (!used) {
        be_raise(vm, "value_error", "timer id is not active");
    }
    while (!rtos_timer_expired_target(&target)) {
        rtos_wait_ms_counter(vm, 1);
    }
    be_return_nil(vm);
}

static int m_rtos_irq_enable(bvm *vm)
{
    bint channel = rtos_require_int(vm, 1, "event channel must be an int");
    const char *handler = rtos_require_name(vm, 2, "handler name must be a string");

    if (channel < 0 || channel >= RTOS_IRQ_CHANNELS) {
        be_raise(vm, "value_error", "event channel must be between 0 and 15");
    }

    rtos_acquire_state(vm);
    g_rtos_irq[(int)channel].enabled = 1;
    g_rtos_irq[(int)channel].pending = 0;
    strncpy(g_rtos_irq[(int)channel].handler, handler, RTOS_NAME_MAX);
    g_rtos_irq[(int)channel].handler[RTOS_NAME_MAX] = '\0';
    rtos_release_state();

    be_return_nil(vm);
}

static int m_rtos_irq_disable(bvm *vm)
{
    bint channel = rtos_require_int(vm, 1, "event channel must be an int");

    if (channel < 0 || channel >= RTOS_IRQ_CHANNELS) {
        be_raise(vm, "value_error", "event channel must be between 0 and 15");
    }

    rtos_acquire_state(vm);
    memset(&g_rtos_irq[(int)channel], 0, sizeof(g_rtos_irq[(int)channel]));
    rtos_release_state();
    be_return_nil(vm);
}

static int m_rtos_irq_poll(bvm *vm)
{
    char handlers[RTOS_IRQ_CHANNELS][RTOS_NAME_MAX + 1];
    int pending[RTOS_IRQ_CHANNELS];
    int channel;
    int dispatched = 0;

    memset(handlers, 0, sizeof(handlers));
    memset(pending, 0, sizeof(pending));

    rtos_acquire_state(vm);
    if (g_rtos_irq[RTOS_IRQ_ATN].enabled && _pollatn()) {
        g_rtos_irq[RTOS_IRQ_ATN].pending = 1;
    }
    for (channel = 0; channel < RTOS_IRQ_CHANNELS; ++channel) {
        if (g_rtos_irq[channel].enabled && g_rtos_irq[channel].pending) {
            pending[channel] = 1;
            g_rtos_irq[channel].pending = 0;
            strncpy(handlers[channel], g_rtos_irq[channel].handler, RTOS_NAME_MAX);
            handlers[channel][RTOS_NAME_MAX] = '\0';
        }
    }
    rtos_release_state();

    for (channel = 0; channel < RTOS_IRQ_CHANNELS; ++channel) {
        if (pending[channel]) {
            if (!be_getglobal(vm, handlers[channel])) {
                be_pop(vm, 1);
                be_raise(vm, "runtime_error", "irq handler function not found");
            }
            be_call(vm, 0);
            if (be_top(vm) > 0) {
                be_pop(vm, 1);
            }
            ++dispatched;
        }
    }

    be_pushint(vm, (bint)dispatched);
    be_return(vm);
}

static int m_rtos_debug_tasks(bvm *vm)
{
    int cog;

    be_newobject(vm, "list");
    for (cog = 0; cog < 8; ++cog) {
        be_newobject(vm, "map");
        rtos_map_set_int(vm, "cog", (bint)cog);
        rtos_map_set_string(vm, "state", rtos_cog_state_name(cog));
        /* Catalina's worker launcher owns the C stack internally; this module
         * does not have a reliable stack watermark yet, so report -1 instead
         * of pretending a value is known. */
        rtos_map_set_int(vm, "stack_free", (bint)-1);
        be_pop(vm, 1);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_rtos_debug_regs(bvm *vm)
{
    bint cog = rtos_require_int(vm, 1, "cog must be an int");
    counter64_t ct;

    if (cog < 0 || cog > 7) {
        be_raise(vm, "value_error", "cog must be between 0 and 7");
    }

    ct = _cnthl();
    be_newobject(vm, "map");
    rtos_map_set_int(vm, "cog", cog);
    rtos_map_set_string(vm, "state", rtos_cog_state_name((int)cog));
    rtos_map_set_bool(vm, "readable", cog == _cogid());
    rtos_map_set_int(vm, "ct_low", (bint)ct.low);
    rtos_map_set_int(vm, "ct_high", (bint)ct.high);
    if (cog == _cogid()) {
        rtos_map_set_int(vm, "ptra", (bint)_PTRA);
        rtos_map_set_int(vm, "ptrb", (bint)_PTRB);
        rtos_map_set_int(vm, "ina", (bint)_INA);
        rtos_map_set_int(vm, "inb", (bint)_INB);
        rtos_map_set_int(vm, "outa", (bint)_OUTA);
        rtos_map_set_int(vm, "outb", (bint)_OUTB);
        rtos_map_set_int(vm, "dira", (bint)_DIRA);
        rtos_map_set_int(vm, "dirb", (bint)_DIRB);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_rtos_member(bvm *vm)
{
    const char *name = be_tostring(vm, 1);

    if (!strcmp(name, "load")) be_pushntvfunction(vm, m_rtos_load);
    else if (!strcmp(name, "spawn")) be_pushntvfunction(vm, m_rtos_spawn);
    else if (!strcmp(name, "cog_start")) be_pushntvfunction(vm, m_rtos_spawn);
    else if (!strcmp(name, "thread")) be_pushntvfunction(vm, m_rtos_spawn);
    else if (!strcmp(name, "new")) be_pushntvfunction(vm, m_rtos_spawn);
    else if (!strcmp(name, "stop")) be_pushntvfunction(vm, m_rtos_stop);
    else if (!strcmp(name, "state")) be_pushntvfunction(vm, m_rtos_state);
    else if (!strcmp(name, "error")) be_pushntvfunction(vm, m_rtos_error);
    else if (!strcmp(name, "yield")) be_pushntvfunction(vm, m_rtos_yield);
    else if (!strcmp(name, "task_yield")) be_pushntvfunction(vm, m_rtos_yield);
    else if (!strcmp(name, "sleep_ms")) be_pushntvfunction(vm, m_rtos_sleep_ms);
    else if (!strcmp(name, "cog_id")) be_pushntvfunction(vm, m_rtos_cog_id);
    else if (!strcmp(name, "new_lock")) be_pushntvfunction(vm, m_rtos_new_lock);
    else if (!strcmp(name, "lock")) be_pushntvfunction(vm, m_rtos_lock);
    else if (!strcmp(name, "try_lock")) be_pushntvfunction(vm, m_rtos_try_lock);
    else if (!strcmp(name, "unlock")) be_pushntvfunction(vm, m_rtos_unlock);
    else if (!strcmp(name, "delete_lock")) be_pushntvfunction(vm, m_rtos_delete_lock);
    else if (!strcmp(name, "channel")) be_pushntvfunction(vm, m_rtos_channel);
    else if (!strcmp(name, "put")) be_pushntvfunction(vm, m_rtos_put);
    else if (!strcmp(name, "get")) be_pushntvfunction(vm, m_rtos_get);
    else if (!strcmp(name, "event_set")) be_pushntvfunction(vm, m_rtos_event_set);
    else if (!strcmp(name, "event_clear")) be_pushntvfunction(vm, m_rtos_event_clear);
    else if (!strcmp(name, "event_wait")) be_pushntvfunction(vm, m_rtos_event_wait);
    else if (!strcmp(name, "event_flags")) be_pushntvfunction(vm, m_rtos_event_flags);
    else if (!strcmp(name, "ticks_per_ms")) be_pushntvfunction(vm, m_rtos_ticks_per_ms);
    else if (!strcmp(name, "delay_ms")) be_pushntvfunction(vm, m_rtos_delay_ms);
    else if (!strcmp(name, "timer_start")) be_pushntvfunction(vm, m_rtos_timer_start);
    else if (!strcmp(name, "timer_expired")) be_pushntvfunction(vm, m_rtos_timer_expired);
    else if (!strcmp(name, "timer_wait")) be_pushntvfunction(vm, m_rtos_timer_wait);
    else if (!strcmp(name, "irq_enable")) be_pushntvfunction(vm, m_rtos_irq_enable);
    else if (!strcmp(name, "irq_poll")) be_pushntvfunction(vm, m_rtos_irq_poll);
    else if (!strcmp(name, "irq_disable")) be_pushntvfunction(vm, m_rtos_irq_disable);
    else if (!strcmp(name, "debug_tasks")) be_pushntvfunction(vm, m_rtos_debug_tasks);
    else if (!strcmp(name, "debug_regs")) be_pushntvfunction(vm, m_rtos_debug_regs);
    else if (!strcmp(name, "IRQ_ATN")) be_pushint(vm, RTOS_IRQ_ATN);
    else if (!strcmp(name, "IRQ_DEFERRED")) be_pushbool(vm, 1);
    else if (!strcmp(name, "QUEUE_MAX")) be_pushint(vm, RTOS_QUEUE_MAX);
    else if (!strcmp(name, "TIMER_MAX")) be_pushint(vm, RTOS_TIMER_MAX);
    else be_pushnil(vm);
    be_return(vm);
}

void be_cache_rtosmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "rtos");

    rtos_bootstrap_state();
    be_newmodule(vm);
    rtos_module_set_func(vm, "member", m_rtos_member);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
