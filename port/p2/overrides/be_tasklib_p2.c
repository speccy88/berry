/********************************************************************
** Native cooperative task module for the P2 Berry port.
**
** This intentionally keeps the import path small: the scheduler state is C
** owned, while task functions and argument lists are kept in a hidden Berry
** global list so the GC can still see them.
********************************************************************/
#include "berry.h"
#include "be_exec.h"
#include "be_list.h"
#include "be_map.h"
#include "be_module.h"
#include "be_object.h"
#include "be_string.h"
#include "be_vm.h"

#include <propeller2.h>
#include <string.h>

#define P2_TASK_MAX_TASKS 16
#define P2_TASK_MAX_EVENTS 16
#define P2_TASK_EVENT_MAX 31
#define P2_TASK_ERROR_MAX 63

#define P2_TASK_FREE 0
#define P2_TASK_READY 1
#define P2_TASK_PAUSED 2
#define P2_TASK_WAITING 3
#define P2_TASK_DONE 4
#define P2_TASK_ERROR 5

#define P2_TASK_WAIT_NONE 0
#define P2_TASK_WAIT_SLEEP 1
#define P2_TASK_WAIT_EVENT 2

typedef struct p2_task_slot {
    int status;
    int wait_kind;
    int runs;
    int wakeups;
    int woke_timeout;
    char wait_event[P2_TASK_EVENT_MAX + 1];
    char woke_event[P2_TASK_EVENT_MAX + 1];
    char last_error[P2_TASK_ERROR_MAX + 1];
    unsigned long deadline;
} p2_task_slot;

static p2_task_slot p2_task_slots[P2_TASK_MAX_TASKS];
static int p2_task_current = -1;
static int p2_task_next = -1;
static char p2_task_events[P2_TASK_MAX_EVENTS][P2_TASK_EVENT_MAX + 1];

static int p2_task_next_internal(bvm *vm);

static unsigned long p2_task_millis_now(void)
{
    unsigned long hz = (unsigned long)_clockfreq();
    if (hz == 0) {
        return 0;
    }
    return (unsigned long)(_cnt() / (hz / 1000u));
}

static const char *p2_task_status_name(int status)
{
    switch (status) {
    case P2_TASK_FREE: return "free";
    case P2_TASK_READY: return "ready";
    case P2_TASK_WAITING: return "waiting";
    case P2_TASK_PAUSED: return "paused";
    case P2_TASK_DONE: return "done";
    case P2_TASK_ERROR: return "error";
    default: return "unknown";
    }
}

static void p2_task_copy_event(char *dst, const char *src)
{
    if (!dst) {
        return;
    }
    if (!src) {
        dst[0] = '\0';
        return;
    }
    strncpy(dst, src, P2_TASK_EVENT_MAX);
    dst[P2_TASK_EVENT_MAX] = '\0';
}

static void p2_task_map_set_int(bvm *vm, int map_index, const char *key, bint value)
{
    map_index = be_absindex(vm, map_index);
    be_pushstring(vm, key);
    be_pushint(vm, value);
    be_data_insert(vm, map_index);
    be_pop(vm, 2);
}

static void p2_task_map_set_bool(bvm *vm, int map_index, const char *key, int value)
{
    map_index = be_absindex(vm, map_index);
    be_pushstring(vm, key);
    be_pushbool(vm, value ? btrue : bfalse);
    be_data_insert(vm, map_index);
    be_pop(vm, 2);
}

static void p2_task_map_set_string(bvm *vm, int map_index, const char *key, const char *value)
{
    map_index = be_absindex(vm, map_index);
    be_pushstring(vm, key);
    be_pushstring(vm, value ? value : "");
    be_data_insert(vm, map_index);
    be_pop(vm, 2);
}

static bvalue *p2_task_map_find_cstr(bvm *vm, bmap *map, const char *key)
{
    return be_map_findstr(vm, map, be_newstr(vm, key));
}

static int p2_task_registry(bvm *vm)
{
    int i;

    if (be_getglobal(vm, "__p2_task_refs") && be_islist(vm, -1)) {
        return be_absindex(vm, -1);
    }
    be_pop(vm, 1);
    be_newlist(vm);
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        be_pushnil(vm);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pushvalue(vm, -1);
    be_setglobal(vm, "__p2_task_refs");
    be_pop(vm, 1);
    return be_absindex(vm, -1);
}

static bvalue *p2_task_registry_value(bvm *vm, int id)
{
    int reg = p2_task_registry(vm);
    bvalue *rv = be_indexof(vm, reg);
    blist *list = var_toobj(rv);
    bvalue *value = be_list_index(list, id);
    be_pop(vm, 1);
    return value;
}

static void p2_task_registry_clear(bvm *vm, int id)
{
    int reg = p2_task_registry(vm);
    be_pushint(vm, id);
    be_pushnil(vm);
    be_setindex(vm, reg);
    be_pop(vm, 3);
}

static void p2_task_registry_set(bvm *vm, int id, int fn_index, int first_arg, int argc)
{
    int i;
    int reg = p2_task_registry(vm);
    int map_index;
    int args_index;

    be_newmap(vm);
    map_index = be_absindex(vm, -1);
    be_pushstring(vm, "fn");
    be_pushvalue(vm, fn_index);
    be_data_insert(vm, map_index);
    be_pop(vm, 2);

    be_newlist(vm);
    args_index = be_absindex(vm, -1);
    for (i = 0; i < argc; ++i) {
        be_pushvalue(vm, first_arg + i);
        be_data_push(vm, args_index);
        be_pop(vm, 1);
    }
    be_pushstring(vm, "args");
    be_pushvalue(vm, args_index);
    be_data_insert(vm, map_index);
    be_pop(vm, 2);

    be_pushint(vm, id);
    be_pushvalue(vm, map_index);
    be_setindex(vm, reg);
    be_pop(vm, 5);
}

static void p2_task_free_slot(bvm *vm, int id)
{
    memset(&p2_task_slots[id], 0, sizeof(p2_task_slots[id]));
    p2_task_registry_clear(vm, id);
}

static int p2_task_first_free(void)
{
    int i;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (p2_task_slots[i].status == P2_TASK_FREE) {
            return i;
        }
    }
    return -1;
}

static int p2_task_valid(int handle)
{
    return handle >= 0 && handle < P2_TASK_MAX_TASKS;
}

static int p2_task_event_index(const char *event)
{
    int i;
    if (!event || !event[0]) {
        return -1;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (p2_task_events[i][0] && !strcmp(p2_task_events[i], event)) {
            return i;
        }
    }
    return -1;
}

static int p2_task_event_latched(const char *event)
{
    return p2_task_event_index(event) >= 0;
}

static int p2_task_signal_event(const char *event)
{
    int i;
    if (!event || !event[0]) {
        return 0;
    }
    if (p2_task_event_latched(event)) {
        return 1;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (!p2_task_events[i][0]) {
            p2_task_copy_event(p2_task_events[i], event);
            return 1;
        }
    }
    return 0;
}

static int p2_task_clear_event(const char *event)
{
    int idx = p2_task_event_index(event);
    if (idx < 0) {
        return 0;
    }
    p2_task_events[idx][0] = '\0';
    return 1;
}

static void p2_task_wake_waiting(void)
{
    int i;
    unsigned long now = p2_task_millis_now();

    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_slot *slot = &p2_task_slots[i];
        if (slot->status != P2_TASK_WAITING) {
            continue;
        }
        slot->woke_timeout = 0;
        slot->woke_event[0] = '\0';
        if (slot->wait_kind == P2_TASK_WAIT_SLEEP && now >= slot->deadline) {
            slot->status = P2_TASK_READY;
            ++slot->wakeups;
        } else if (slot->wait_kind == P2_TASK_WAIT_EVENT &&
                slot->wait_event[0] &&
                p2_task_event_latched(slot->wait_event)) {
            slot->status = P2_TASK_READY;
            p2_task_copy_event(slot->woke_event, slot->wait_event);
            ++slot->wakeups;
        } else if (slot->wait_kind == P2_TASK_WAIT_EVENT &&
                slot->deadline != 0 &&
                now >= slot->deadline) {
            slot->status = P2_TASK_READY;
            slot->woke_timeout = 1;
            ++slot->wakeups;
        }
    }
}

static int p2_task_is_done_value(bvm *vm, int index)
{
    if (be_isnil(vm, index)) {
        return 1;
    }
    if (be_isbool(vm, index) && !be_tobool(vm, index)) {
        return 1;
    }
    if (be_isstring(vm, index) && !strcmp(be_tostring(vm, index), "__task_done__")) {
        return 1;
    }
    return 0;
}

static const char *p2_task_wait_kind_from_value(bvm *vm, bvalue *value)
{
    bmap *map;
    bvalue *kind;
    if (!value || !var_ismap(value)) {
        return NULL;
    }
    map = var_toobj(value);
    kind = p2_task_map_find_cstr(vm, map, "_task_wait");
    if (!kind || !var_isstr(kind)) {
        return NULL;
    }
    return str(var_tostr(kind));
}

static bint p2_task_map_int_or(bvm *vm, bmap *map, const char *key, bint fallback)
{
    bvalue *value = p2_task_map_find_cstr(vm, map, key);
    (void)vm;
    if (value && var_isint(value)) {
        return var_toint(value);
    }
    return fallback;
}

static const char *p2_task_map_str_or(bvm *vm, bmap *map, const char *key, const char *fallback)
{
    bvalue *value = p2_task_map_find_cstr(vm, map, key);
    (void)vm;
    if (value && var_isstr(value)) {
        return str(var_tostr(value));
    }
    return fallback;
}

static void p2_task_interpret_result(bvm *vm, int id, int result_index)
{
    p2_task_slot *slot = &p2_task_slots[id];
    bvalue *rv = be_indexof(vm, result_index);
    const char *wait_kind = p2_task_wait_kind_from_value(vm, rv);

    if (p2_task_is_done_value(vm, result_index)) {
        p2_task_free_slot(vm, id);
    } else if (be_isstring(vm, result_index) && !strcmp(be_tostring(vm, result_index), "__task_pause__")) {
        slot->status = P2_TASK_PAUSED;
    } else if (wait_kind) {
        bmap *map = var_toobj(rv);
        if (!strcmp(wait_kind, "sleep")) {
            slot->status = P2_TASK_WAITING;
            slot->wait_kind = P2_TASK_WAIT_SLEEP;
            slot->deadline = (unsigned long)p2_task_map_int_or(vm, map, "deadline", (bint)p2_task_millis_now());
        } else {
            const char *event = p2_task_map_str_or(vm, map, "event", wait_kind);
            slot->status = P2_TASK_WAITING;
            slot->wait_kind = P2_TASK_WAIT_EVENT;
            p2_task_copy_event(slot->wait_event, event);
            slot->deadline = (unsigned long)p2_task_map_int_or(vm, map, "deadline", 0);
        }
    } else {
        slot->status = P2_TASK_READY;
    }
}

static int p2_task_call_slot(bvm *vm, int id)
{
    bvalue *ref = p2_task_registry_value(vm, id);
    bvalue *fnv;
    bvalue *argsv;
    bmap *map;
    blist *args;
    int argc;
    int i;

    if (!ref || !var_ismap(ref)) {
        p2_task_slots[id].status = P2_TASK_ERROR;
        strcpy(p2_task_slots[id].last_error, "task reference missing");
        return 0;
    }
    map = var_toobj(ref);
    fnv = p2_task_map_find_cstr(vm, map, "fn");
    argsv = p2_task_map_find_cstr(vm, map, "args");
    if (!fnv || !var_isfunction(fnv) || !argsv || !var_islist(argsv)) {
        p2_task_slots[id].status = P2_TASK_ERROR;
        strcpy(p2_task_slots[id].last_error, "task reference invalid");
        return 0;
    }
    args = var_toobj(argsv);
    argc = be_list_count(args);
    *vm->top = *fnv;
    be_incrtop(vm);
    for (i = 0; i < argc; ++i) {
        bvalue *arg = be_list_at(args, i);
        *vm->top = *arg;
        be_incrtop(vm);
    }
    be_call(vm, argc);
    return 1;
}

static int p2_task_run_slot(bvm *vm, int id)
{
    p2_task_slot *slot = &p2_task_slots[id];
    int result_index;

    p2_task_current = id;
    ++slot->runs;
    slot->last_error[0] = '\0';
    if (!p2_task_call_slot(vm, id)) {
        p2_task_current = -1;
        return id;
    }
    result_index = be_absindex(vm, -1);
    p2_task_current = -1;
    if (slot->status == P2_TASK_READY) {
        p2_task_interpret_result(vm, id, result_index);
    }
    be_pop(vm, 1);
    return id;
}

static int m_task_start(bvm *vm)
{
    int id;
    int argc = be_top(vm) - 1;

    if (be_top(vm) < 1 || !be_isfunction(vm, 1)) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    id = p2_task_first_free();
    if (id < 0) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    memset(&p2_task_slots[id], 0, sizeof(p2_task_slots[id]));
    p2_task_slots[id].status = P2_TASK_READY;
    p2_task_registry_set(vm, id, 1, 2, argc);
    be_pushint(vm, id);
    be_return(vm);
}

static int m_task_sleep(bvm *vm)
{
    bint ms = be_top(vm) >= 1 && be_isint(vm, 1) ? be_toint(vm, 1) : 0;
    if (ms < 0) {
        ms = 0;
    }
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "_task_wait", "sleep");
    p2_task_map_set_int(vm, -1, "ms", ms);
    p2_task_map_set_int(vm, -1, "deadline", (bint)(p2_task_millis_now() + (unsigned long)ms));
    be_return(vm);
}

static int m_task_wait(bvm *vm)
{
    const char *event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    bint timeout = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1;
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "_task_wait", "event");
    p2_task_map_set_string(vm, -1, "event", event);
    if (timeout >= 0) {
        p2_task_map_set_int(vm, -1, "deadline", (bint)(p2_task_millis_now() + (unsigned long)timeout));
    }
    be_return(vm);
}

static int m_task_signal(bvm *vm)
{
    const char *event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    be_pushbool(vm, p2_task_signal_event(event) ? btrue : bfalse);
    be_return(vm);
}

static int m_task_clear(bvm *vm)
{
    const char *event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    be_pushbool(vm, p2_task_clear_event(event) ? btrue : bfalse);
    be_return(vm);
}

static int m_task_next(bvm *vm)
{
    int ran;

    ran = p2_task_next_internal(vm);
    be_pushint(vm, ran);
    be_return(vm);
}

static int p2_task_next_internal(bvm *vm)
{
    int i;
    p2_task_wake_waiting();
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_next = (p2_task_next + 1) % P2_TASK_MAX_TASKS;
        if (p2_task_slots[p2_task_next].status == P2_TASK_READY) {
            return p2_task_run_slot(vm, p2_task_next);
        }
    }
    return -1;
}

static int p2_task_live_count(void)
{
    int i;
    int count = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (p2_task_slots[i].status == P2_TASK_READY ||
            p2_task_slots[i].status == P2_TASK_WAITING) {
            ++count;
        }
    }
    return count;
}

static int m_task_run(bvm *vm)
{
    int max_steps = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    int idle_ms = be_top(vm) >= 2 && be_isint(vm, 2) ? (int)be_toint(vm, 2) : 1;
    int steps = 0;

    while (max_steps < 0 || steps < max_steps) {
        int before = steps;
        p2_task_wake_waiting();
        if (p2_task_live_count() <= 0) {
            break;
        }
        be_pushntvfunction(vm, m_task_next);
        be_call(vm, 0);
        if (be_isint(vm, -1) && be_toint(vm, -1) >= 0) {
            ++steps;
        }
        be_pop(vm, 1);
        if (steps == before && idle_ms > 0) {
            _waitms(idle_ms);
        }
    }
    be_pushint(vm, steps);
    be_return(vm);
}

static int p2_task_resolve_handle(bvm *vm)
{
    if (be_top(vm) < 1 || be_isnil(vm, 1) || (be_isint(vm, 1) && be_toint(vm, 1) == -1)) {
        return p2_task_current;
    }
    return be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
}

static int m_task_stop(bvm *vm)
{
    int id = p2_task_resolve_handle(vm);
    if (!p2_task_valid(id) || p2_task_slots[id].status == P2_TASK_FREE) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_free_slot(vm, id);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_pause(bvm *vm)
{
    int id = p2_task_resolve_handle(vm);
    if (!p2_task_valid(id) || p2_task_slots[id].status == P2_TASK_FREE) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_slots[id].status = P2_TASK_PAUSED;
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_resume(bvm *vm)
{
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    if (!p2_task_valid(id) || p2_task_slots[id].status != P2_TASK_PAUSED) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_slots[id].status = P2_TASK_READY;
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_status(bvm *vm)
{
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    be_pushstring(vm, p2_task_valid(id) ? p2_task_status_name(p2_task_slots[id].status) : "free");
    be_return(vm);
}

static int m_task_current(bvm *vm)
{
    be_pushint(vm, p2_task_current);
    be_return(vm);
}

static void p2_task_push_slot_info(bvm *vm, int id)
{
    p2_task_slot *slot = &p2_task_slots[id];
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_string(vm, -1, "status", p2_task_status_name(slot->status));
    p2_task_map_set_string(vm, -1, "wait", slot->wait_kind == P2_TASK_WAIT_SLEEP ? "sleep" : (slot->wait_kind == P2_TASK_WAIT_EVENT ? "event" : ""));
    p2_task_map_set_int(vm, -1, "runs", slot->runs);
    p2_task_map_set_int(vm, -1, "wakeups", slot->wakeups);
    p2_task_map_set_string(vm, -1, "last_error", slot->last_error);
    be_pop(vm, 1);
}

static int m_task_list(bvm *vm)
{
    int i;
    be_newobject(vm, "list");
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (p2_task_slots[i].status != P2_TASK_FREE) {
            p2_task_push_slot_info(vm, i);
            be_data_push(vm, -2);
            be_pop(vm, 1);
        }
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_info(bvm *vm)
{
    int i;
    int active = 0, ready = 0, waiting = 0, paused = 0, events = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        int status = p2_task_slots[i].status;
        if (status != P2_TASK_FREE) ++active;
        if (status == P2_TASK_READY) ++ready;
        if (status == P2_TASK_WAITING) ++waiting;
        if (status == P2_TASK_PAUSED) ++paused;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (p2_task_events[i][0]) ++events;
    }
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "backend", "p2_native_cooperative");
    p2_task_map_set_int(vm, -1, "max_tasks", P2_TASK_MAX_TASKS);
    p2_task_map_set_int(vm, -1, "active", active);
    p2_task_map_set_int(vm, -1, "ready", ready);
    p2_task_map_set_int(vm, -1, "waiting", waiting);
    p2_task_map_set_int(vm, -1, "paused", paused);
    p2_task_map_set_int(vm, -1, "events", events);
    p2_task_map_set_int(vm, -1, "current", p2_task_current);
    p2_task_map_set_bool(vm, -1, "uses_p2_counter", 1);
    p2_task_map_set_bool(vm, -1, "uses_cog_attention", 0);
    p2_task_map_set_bool(vm, -1, "preemptive", 0);
    p2_task_map_set_bool(vm, -1, "stackful", 0);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_millis(bvm *vm)
{
    be_pushint(vm, (bint)p2_task_millis_now());
    be_return(vm);
}

static int m_task_woke_by_timeout(bvm *vm)
{
    int ok = p2_task_valid(p2_task_current) && p2_task_slots[p2_task_current].woke_timeout;
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static int m_task_woke_by_event(bvm *vm)
{
    int ok = 0;
    if (p2_task_valid(p2_task_current) && p2_task_slots[p2_task_current].woke_event[0]) {
        if (be_top(vm) < 1 || be_isnil(vm, 1)) {
            ok = 1;
        } else if (be_isstring(vm, 1) && !strcmp(be_tostring(vm, 1), p2_task_slots[p2_task_current].woke_event)) {
            ok = 1;
        }
    }
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static int m_task_reset(bvm *vm)
{
    int i;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_free_slot(vm, i);
    }
    memset(p2_task_events, 0, sizeof(p2_task_events));
    p2_task_current = -1;
    p2_task_next = -1;
    be_pushbool(vm, btrue);
    be_return(vm);
}

static void task_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void task_module_set_int(bvm *vm, const char *name, bint value)
{
    be_pushint(vm, value);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void task_module_set_str(bvm *vm, const char *name, const char *value)
{
    be_pushstring(vm, value);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

void be_cache_taskmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "task");

    be_newmodule(vm);
    task_module_set_int(vm, "MAX_TASKS", P2_TASK_MAX_TASKS);
    task_module_set_int(vm, "MAX_EVENTS", P2_TASK_MAX_EVENTS);
    task_module_set_int(vm, "MAX_TIMERS", 16);
    task_module_set_int(vm, "MAX_QUEUE_DEPTH", 8);
    task_module_set_str(vm, "again", "__task_again__");
    task_module_set_str(vm, "done", "__task_done__");
    task_module_set_str(vm, "paused", "__task_pause__");
    task_module_set_func(vm, "start", m_task_start);
    task_module_set_func(vm, "sleep", m_task_sleep);
    task_module_set_func(vm, "wait", m_task_wait);
    task_module_set_func(vm, "signal", m_task_signal);
    task_module_set_func(vm, "clear", m_task_clear);
    task_module_set_func(vm, "next", m_task_next);
    task_module_set_func(vm, "run", m_task_run);
    task_module_set_func(vm, "stop", m_task_stop);
    task_module_set_func(vm, "pause", m_task_pause);
    task_module_set_func(vm, "resume", m_task_resume);
    task_module_set_func(vm, "status", m_task_status);
    task_module_set_func(vm, "current", m_task_current);
    task_module_set_func(vm, "list", m_task_list);
    task_module_set_func(vm, "info", m_task_info);
    task_module_set_func(vm, "millis", m_task_millis);
    task_module_set_func(vm, "woke_by_timeout", m_task_woke_by_timeout);
    task_module_set_func(vm, "woke_by_event", m_task_woke_by_event);
    task_module_set_func(vm, "reset", m_task_reset);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}

be_native_module_attr_table(task) {
    be_native_module_int("MAX_TASKS", P2_TASK_MAX_TASKS),
    be_native_module_int("MAX_EVENTS", P2_TASK_MAX_EVENTS),
    be_native_module_int("MAX_TIMERS", 16),
    be_native_module_int("MAX_QUEUE_DEPTH", 8),
    be_native_module_str("again", "__task_again__"),
    be_native_module_str("done", "__task_done__"),
    be_native_module_str("paused", "__task_pause__"),
    be_native_module_function("start", m_task_start),
    be_native_module_function("sleep", m_task_sleep),
    be_native_module_function("wait", m_task_wait),
    be_native_module_function("signal", m_task_signal),
    be_native_module_function("clear", m_task_clear),
    be_native_module_function("next", m_task_next),
    be_native_module_function("run", m_task_run),
    be_native_module_function("stop", m_task_stop),
    be_native_module_function("pause", m_task_pause),
    be_native_module_function("resume", m_task_resume),
    be_native_module_function("status", m_task_status),
    be_native_module_function("current", m_task_current),
    be_native_module_function("list", m_task_list),
    be_native_module_function("info", m_task_info),
    be_native_module_function("millis", m_task_millis),
    be_native_module_function("woke_by_timeout", m_task_woke_by_timeout),
    be_native_module_function("woke_by_event", m_task_woke_by_event),
    be_native_module_function("reset", m_task_reset),
};

be_define_native_module(task, NULL);
