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
#include "p2_clock.h"
#include "p2_vm_state.h"

#include <propeller2.h>
#include <string.h>

#define P2_TASK_FREE 0
#define P2_TASK_READY 1
#define P2_TASK_PAUSED 2
#define P2_TASK_WAITING 3
#define P2_TASK_DONE 4
#define P2_TASK_ERROR 5

#define P2_TASK_WAIT_NONE 0
#define P2_TASK_WAIT_SLEEP 1
#define P2_TASK_WAIT_EVENT 2
#define P2_TASK_WAIT_P2IPC_CHANNEL 3
#define P2_TASK_WAIT_P2IPC_MAILBOX 4
#define P2_TASK_WAIT_QUEUE 5
#define P2_TASK_WAIT_SEMAPHORE 6
#define P2_TASK_WAIT_MUTEX 7
#define P2_TASK_WAIT_FLAGS 8
#define P2_TASK_WAIT_TIMER 9

static int p2_task_next_internal(bvm *vm);
static int p2_task_live_count(bvm *vm);
static int p2_task_status_count(bvm *vm, int wanted);
static int p2_task_active_count(bvm *vm);
static int p2_task_valid(int handle);
static int p2_task_event_count(bvm *vm);
static void p2_task_push_events(bvm *vm);
static int m_task_semaphore_new(bvm *vm);
static int m_task_mutex_new(bvm *vm);
static int m_task_queue_new(bvm *vm);
static int m_task_event_flags_new(bvm *vm);
static int m_task_timer_new(bvm *vm);
static void event_flags_push_mask_value(bvm *vm, int map_index, const char *key, int value_index, int fallback);
static void event_flags_push_ready_result(bvm *vm, int ok, int ready, int value, int mask_index, int fallback_mask, const char *mode, const char *error, const char *message);
static int timer_ready(bvm *vm, int self_index);
static int timer_remaining_ms(bvm *vm, int self_index);

static uint32_t p2_task_millis_now(bvm *vm)
{
    uint32_t now = 0;
    if (!p2_clock_millis_now(&now)) {
        be_raise(vm, "runtime_error", "P2 clock frequency is not configured");
    }
    return now;
}

static uint32_t p2_task_delay_ms(bvm *vm, bint delay)
{
    /* Check before narrowing a Berry integer on either host or Catalina. */
    if (delay < 0 || delay > (bint)P2_DEADLINE_MAX_DELAY) {
        be_raise(vm, "value_error", "P2 delay must be in 0..2147483647 milliseconds");
    }
    return (uint32_t)delay;
}

static void p2_task_set_deadline(bvm *vm, p2_deadline *deadline, bint timeout)
{
    uint32_t delay;
    if (timeout < 0) {
        p2_deadline_cancel(deadline);
        deadline->at_ms = 0;
        return;
    }
    delay = p2_task_delay_ms(vm, timeout);
    p2_deadline_arm(deadline, p2_task_millis_now(vm), delay);
}

static bint p2_task_millis_value(uint32_t millis)
{
    /* Preserve the signed 32-bit Berry timestamp projection without
     * implementation-defined unsigned-to-signed narrowing on either ABI. */
    if (millis <= P2_DEADLINE_MAX_DELAY) {
        return (bint)millis;
    }
    return -1 - (bint)(0xffffffffU - millis);
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

static const char *p2_task_wait_name(int wait_kind)
{
    switch (wait_kind) {
    case P2_TASK_WAIT_SLEEP: return "sleep";
    case P2_TASK_WAIT_EVENT: return "event";
    case P2_TASK_WAIT_P2IPC_CHANNEL: return "p2ipc_channel";
    case P2_TASK_WAIT_P2IPC_MAILBOX: return "p2ipc_mailbox";
    case P2_TASK_WAIT_QUEUE: return "queue";
    case P2_TASK_WAIT_SEMAPHORE: return "semaphore";
    case P2_TASK_WAIT_MUTEX: return "mutex";
    case P2_TASK_WAIT_FLAGS: return "flags";
    case P2_TASK_WAIT_TIMER: return "timer";
    default: return "";
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

static void p2_task_map_set_value(bvm *vm, int map_index, const char *key, int value_index)
{
    map_index = be_absindex(vm, map_index);
    value_index = be_absindex(vm, value_index);
    be_pushstring(vm, key);
    be_pushvalue(vm, value_index);
    be_data_insert(vm, map_index);
    be_pop(vm, 2);
}

static void p2_task_list_push_string(bvm *vm, int list_index, const char *value)
{
    list_index = be_absindex(vm, list_index);
    be_pushstring(vm, value ? value : "");
    be_data_push(vm, list_index);
    be_pop(vm, 1);
}

static int p2_task_get_member_int(bvm *vm, int index, const char *name, int fallback)
{
    int value = fallback;
    if (be_getmember(vm, index, name) && be_isint(vm, -1)) {
        value = (int)be_toint(vm, -1);
    }
    be_pop(vm, 1);
    return value;
}

static int p2_task_get_queue_items(bvm *vm, int self_index)
{
    if (!be_getmember(vm, self_index, ".items") || !be_islist(vm, -1)) {
        be_pop(vm, 1);
        be_newobject(vm, "list");
        be_pushvalue(vm, -1);
        be_setmember(vm, self_index, ".items");
        be_pop(vm, 1);
    }
    return be_absindex(vm, -1);
}

static int p2_task_queue_size_from_items(bvm *vm, int items_index)
{
    int size = be_data_size(vm, items_index);
    return size < 0 ? 0 : size;
}

static void p2_task_set_member_int(bvm *vm, int index, const char *name, int value)
{
    be_pushint(vm, value);
    be_setmember(vm, index, name);
    be_pop(vm, 1);
}

static int p2_task_get_member_bool(bvm *vm, int index, const char *name, int fallback)
{
    int value = fallback;
    if (be_getmember(vm, index, name) && be_isbool(vm, -1)) {
        value = be_tobool(vm, -1) ? 1 : 0;
    }
    be_pop(vm, 1);
    return value;
}

static void p2_task_set_member_bool(bvm *vm, int index, const char *name, int value)
{
    be_pushbool(vm, value ? btrue : bfalse);
    be_setmember(vm, index, name);
    be_pop(vm, 1);
}

static int p2_task_member_string_is(bvm *vm, int index, const char *name, const char *wanted)
{
    int match = 0;
    if (be_getmember(vm, index, name) && be_isstring(vm, -1)) {
        const char *value = be_tostring(vm, -1);
        match = value && wanted && !strcmp(value, wanted);
    }
    be_pop(vm, 1);
    return match;
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

static void p2_task_registry_set_wait_object(bvm *vm, int id, int object_index)
{
    bvalue *ref;
    int object_abs = object_index ? be_absindex(vm, object_index) : 0;
    int map_index;

    if (!p2_task_valid(id)) {
        return;
    }
    ref = p2_task_registry_value(vm, id);
    if (!ref || !var_ismap(ref)) {
        return;
    }
    *vm->top = *ref;
    be_incrtop(vm);
    map_index = be_absindex(vm, -1);
    be_pushstring(vm, "wait_object");
    if (object_abs) {
        be_pushvalue(vm, object_abs);
    } else {
        be_pushnil(vm);
    }
    be_data_insert(vm, map_index);
    be_pop(vm, 3);
}

static void p2_task_free_slot(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_registry_clear(vm, id);
    memset(&state->slots[id], 0, sizeof(state->slots[id]));
}

static int p2_task_first_free(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (state->slots[i].status == P2_TASK_FREE) {
            return i;
        }
    }
    return -1;
}

static int p2_task_valid(int handle)
{
    return handle >= 0 && handle < P2_TASK_MAX_TASKS;
}

static int p2_task_activate_slot(bvm *vm, int id, int fn_index, int first_arg, int argc)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_registry_set(vm, id, fn_index, first_arg, argc);
    memset(&state->slots[id], 0, sizeof(state->slots[id]));
    state->slots[id].status = P2_TASK_READY;
    return id;
}

static int p2_task_event_index(bvm *vm, const char *event)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    if (!event || !event[0]) {
        return -1;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (state->events[i][0] && !strcmp(state->events[i], event)) {
            return i;
        }
    }
    return -1;
}

static int p2_task_event_latched(bvm *vm, const char *event)
{
    return p2_task_event_index(vm, event) >= 0;
}

static int p2_task_signal_event(bvm *vm, const char *event)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    if (!event || !event[0]) {
        return 0;
    }
    if (p2_task_event_latched(vm, event)) {
        return 1;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (!state->events[i][0]) {
            p2_task_copy_event(state->events[i], event);
            return 1;
        }
    }
    return 0;
}

static int p2_task_clear_event(bvm *vm, const char *event)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int idx = p2_task_event_index(vm, event);
    if (idx < 0) {
        return 0;
    }
    state->events[idx][0] = '\0';
    return 1;
}

static int p2_task_object_wait_ready(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot;
    bvalue *ref;
    bmap *map;
    bvalue *objv;
    int obj_index;
    int ready = 0;

    if (!p2_task_valid(id)) {
        return 0;
    }
    slot = &state->slots[id];
    ref = p2_task_registry_value(vm, id);
    if (!ref || !var_ismap(ref)) {
        return 0;
    }
    map = var_toobj(ref);
    objv = p2_task_map_find_cstr(vm, map, "wait_object");
    if (!objv || var_isnil(objv)) {
        return 0;
    }
    *vm->top = *objv;
    be_incrtop(vm);
    obj_index = be_absindex(vm, -1);
    if (slot->wait_kind == P2_TASK_WAIT_P2IPC_CHANNEL ||
            slot->wait_kind == P2_TASK_WAIT_P2IPC_MAILBOX) {
        if (be_getmember(vm, obj_index, "wait_ready")) {
            be_pushvalue(vm, obj_index);
            be_pushstring(vm, slot->wait_event);
            be_call(vm, 2);
            be_pop(vm, 2);
            ready = be_isbool(vm, -1) && be_tobool(vm, -1);
            be_pop(vm, 1);
        } else {
            be_pop(vm, 1);
        }
    } else if (slot->wait_kind == P2_TASK_WAIT_QUEUE) {
        int depth = p2_task_get_member_int(vm, obj_index, "depth", 0);
        int items = p2_task_get_queue_items(vm, obj_index);
        int size = p2_task_queue_size_from_items(vm, items);
        ready = !strcmp(slot->wait_event, "put") ? size < depth : size > 0;
        be_remove(vm, items);
    } else if (slot->wait_kind == P2_TASK_WAIT_SEMAPHORE) {
        ready = p2_task_get_member_int(vm, obj_index, "count", 0) > 0;
    } else if (slot->wait_kind == P2_TASK_WAIT_MUTEX) {
        ready = !p2_task_get_member_bool(vm, obj_index, "locked", 0);
    } else if (slot->wait_kind == P2_TASK_WAIT_FLAGS) {
        int flags = p2_task_get_member_int(vm, obj_index, "flags", 0);
        ready = !strcmp(slot->wait_event, "all") ? ((flags & slot->wait_value) == slot->wait_value) : ((flags & slot->wait_value) != 0);
    } else if (slot->wait_kind == P2_TASK_WAIT_TIMER) {
        ready = timer_ready(vm, obj_index);
    } else {
        ready = 0;
    }
    be_pop(vm, 1);
    return ready;
}

static int p2_task_is_object_wait_kind(int wait_kind)
{
    return wait_kind == P2_TASK_WAIT_P2IPC_CHANNEL ||
        wait_kind == P2_TASK_WAIT_P2IPC_MAILBOX ||
        wait_kind == P2_TASK_WAIT_QUEUE ||
        wait_kind == P2_TASK_WAIT_SEMAPHORE ||
        wait_kind == P2_TASK_WAIT_MUTEX ||
        wait_kind == P2_TASK_WAIT_FLAGS ||
        wait_kind == P2_TASK_WAIT_TIMER;
}

static void p2_task_wake_waiting(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    uint32_t now = p2_task_millis_now(vm);

    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_slot *slot = &state->slots[i];
        if (slot->status != P2_TASK_WAITING) {
            continue;
        }
        slot->woke_timeout = 0;
        slot->woke_event[0] = '\0';
        if (slot->wait_kind == P2_TASK_WAIT_SLEEP && p2_deadline_reached(&slot->deadline, now)) {
            slot->status = P2_TASK_READY;
            slot->woke_timeout = 1;
            ++slot->wakeups;
        } else if (slot->wait_kind == P2_TASK_WAIT_EVENT &&
                slot->wait_event[0] &&
                p2_task_event_latched(vm, slot->wait_event)) {
            slot->status = P2_TASK_READY;
            p2_task_copy_event(slot->woke_event, slot->wait_event);
            ++slot->wakeups;
        } else if (slot->wait_kind == P2_TASK_WAIT_EVENT &&
                p2_deadline_reached(&slot->deadline, now)) {
            slot->status = P2_TASK_READY;
            slot->woke_timeout = 1;
            ++slot->wakeups;
        } else if (p2_task_is_object_wait_kind(slot->wait_kind) &&
                p2_task_object_wait_ready(vm, i)) {
            slot->status = P2_TASK_READY;
            ++slot->wakeups;
            p2_task_registry_set_wait_object(vm, i, 0);
        } else if (p2_task_is_object_wait_kind(slot->wait_kind) &&
                p2_deadline_reached(&slot->deadline, now)) {
            slot->status = P2_TASK_READY;
            slot->woke_timeout = 1;
            ++slot->wakeups;
            p2_task_registry_set_wait_object(vm, i, 0);
        }
        if (slot->status == P2_TASK_READY) {
            p2_deadline_cancel(&slot->deadline);
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

static void p2_task_apply_p2ipc_wait(bvm *vm, int id, bmap *map, const char *wait_kind)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot = &state->slots[id];
    bvalue *objv = p2_task_map_find_cstr(vm, map, "wait_object");
    bint timeout = p2_task_map_int_or(vm, map, "timeout", -1);
    const char *fallback_mode = !strcmp(wait_kind, "p2ipc_channel_send") ? "send" :
        (!strcmp(wait_kind, "p2ipc_mailbox_put") ? "put" :
        (!strcmp(wait_kind, "p2ipc_mailbox_get") ? "get" : "recv"));
    const char *mode = p2_task_map_str_or(vm, map, "mode", fallback_mode);

    if (!objv || var_isnil(objv)) {
        slot->status = P2_TASK_ERROR;
        p2_deadline_cancel(&slot->deadline);
        strcpy(slot->last_error, "p2ipc wait object missing");
        return;
    }
    p2_task_set_deadline(vm, &slot->deadline, timeout);
    *vm->top = *objv;
    be_incrtop(vm);
    p2_task_registry_set_wait_object(vm, id, -1);
    be_pop(vm, 1);
    slot->status = P2_TASK_WAITING;
    slot->wait_kind = !strncmp(wait_kind, "p2ipc_channel_", 14) ? P2_TASK_WAIT_P2IPC_CHANNEL : P2_TASK_WAIT_P2IPC_MAILBOX;
    p2_task_copy_event(slot->wait_event, mode);
}

static void p2_task_apply_primitive_wait(bvm *vm, int id, bmap *map, const char *wait_kind)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot = &state->slots[id];
    bvalue *objv = p2_task_map_find_cstr(vm, map, "wait_object");
    bint timeout = p2_task_map_int_or(vm, map, "timeout", -1);
    const char *fallback_mode = !strcmp(wait_kind, "queue_put") ? "put" :
        (!strcmp(wait_kind, "flags") ? "any" : "get");
    const char *mode = p2_task_map_str_or(vm, map, "mode", fallback_mode);

    if (!objv || var_isnil(objv)) {
        slot->status = P2_TASK_ERROR;
        p2_deadline_cancel(&slot->deadline);
        strcpy(slot->last_error, "primitive wait object missing");
        return;
    }
    p2_task_set_deadline(vm, &slot->deadline, timeout);
    *vm->top = *objv;
    be_incrtop(vm);
    p2_task_registry_set_wait_object(vm, id, -1);
    be_pop(vm, 1);
    slot->status = P2_TASK_WAITING;
    slot->wait_value = (int)p2_task_map_int_or(vm, map, "mask", 0);
    if (!strcmp(wait_kind, "queue_get") || !strcmp(wait_kind, "queue_put")) {
        slot->wait_kind = P2_TASK_WAIT_QUEUE;
        p2_task_copy_event(slot->wait_event, !strcmp(wait_kind, "queue_put") ? "put" : "get");
    } else if (!strcmp(wait_kind, "sem")) {
        slot->wait_kind = P2_TASK_WAIT_SEMAPHORE;
        p2_task_copy_event(slot->wait_event, "take");
    } else if (!strcmp(wait_kind, "mutex")) {
        slot->wait_kind = P2_TASK_WAIT_MUTEX;
        p2_task_copy_event(slot->wait_event, "lock");
    } else if (!strcmp(wait_kind, "flags")) {
        slot->wait_kind = P2_TASK_WAIT_FLAGS;
        p2_task_copy_event(slot->wait_event, mode && !strcmp(mode, "all") ? "all" : "any");
    } else {
        slot->wait_kind = P2_TASK_WAIT_TIMER;
        p2_task_copy_event(slot->wait_event, "expired");
    }
}

static void p2_task_interpret_result(bvm *vm, int id, int result_index)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot = &state->slots[id];
    bvalue *rv = be_indexof(vm, result_index);
    const char *wait_kind = p2_task_wait_kind_from_value(vm, rv);

    if (p2_task_is_done_value(vm, result_index)) {
        p2_task_free_slot(vm, id);
    } else if (be_isstring(vm, result_index) && !strcmp(be_tostring(vm, result_index), "__task_pause__")) {
        p2_deadline_cancel(&slot->deadline);
        slot->status = P2_TASK_PAUSED;
    } else if (wait_kind) {
        bmap *map = var_toobj(rv);
        if (!strcmp(wait_kind, "sleep")) {
            bint ms = p2_task_map_int_or(vm, map, "ms", 0);
            if (ms < 0) {
                ms = 0;
            }
            p2_task_set_deadline(vm, &slot->deadline, ms);
            slot->status = P2_TASK_WAITING;
            slot->wait_kind = P2_TASK_WAIT_SLEEP;
        } else if (!strcmp(wait_kind, "p2ipc_channel_recv") ||
                !strcmp(wait_kind, "p2ipc_channel_send") ||
                !strcmp(wait_kind, "p2ipc_mailbox_get") ||
                !strcmp(wait_kind, "p2ipc_mailbox_put")) {
            p2_task_apply_p2ipc_wait(vm, id, map, wait_kind);
        } else if (!strcmp(wait_kind, "queue_get") ||
                !strcmp(wait_kind, "queue_put") ||
                !strcmp(wait_kind, "sem") ||
                !strcmp(wait_kind, "mutex") ||
                !strcmp(wait_kind, "flags") ||
                !strcmp(wait_kind, "timer")) {
            p2_task_apply_primitive_wait(vm, id, map, wait_kind);
        } else {
            const char *event = p2_task_map_str_or(vm, map, "event", wait_kind);
            bint timeout = p2_task_map_int_or(vm, map, "timeout", -1);
            p2_task_set_deadline(vm, &slot->deadline, timeout);
            slot->status = P2_TASK_WAITING;
            slot->wait_kind = P2_TASK_WAIT_EVENT;
            p2_task_copy_event(slot->wait_event, event);
        }
    } else {
        p2_deadline_cancel(&slot->deadline);
        slot->status = P2_TASK_READY;
    }
}

static int p2_task_call_slot(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    bvalue *ref = p2_task_registry_value(vm, id);
    bvalue *fnv;
    bvalue *argsv;
    bmap *map;
    blist *args;
    int argc;
    int i;

    if (!ref || !var_ismap(ref)) {
        p2_deadline_cancel(&state->slots[id].deadline);
        state->slots[id].status = P2_TASK_ERROR;
        strcpy(state->slots[id].last_error, "task reference missing");
        return 0;
    }
    map = var_toobj(ref);
    fnv = p2_task_map_find_cstr(vm, map, "fn");
    argsv = p2_task_map_find_cstr(vm, map, "args");
    if (!fnv || !var_isfunction(fnv) || !argsv || !var_islist(argsv)) {
        p2_deadline_cancel(&state->slots[id].deadline);
        state->slots[id].status = P2_TASK_ERROR;
        strcpy(state->slots[id].last_error, "task reference invalid");
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
    be_pop(vm, argc);
    return 1;
}

static int p2_task_run_slot(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot = &state->slots[id];
    int result_index;

    state->current = id;
    ++slot->runs;
    slot->last_error[0] = '\0';
    if (!p2_task_call_slot(vm, id)) {
        state->current = -1;
        return id;
    }
    result_index = be_absindex(vm, -1);
    state->current = -1;
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
    id = p2_task_first_free(vm);
    if (id < 0) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    be_pushint(vm, p2_task_activate_slot(vm, id, 1, 2, argc));
    be_return(vm);
}

static int m_task_start_result(bvm *vm)
{
    int id;
    int argc = be_top(vm) - 1;
    be_newobject(vm, "map");
    if (be_top(vm) < 1 || !be_isfunction(vm, 1)) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_int(vm, -1, "handle", -1);
        p2_task_map_set_string(vm, -1, "error", "invalid_function");
        p2_task_map_set_string(vm, -1, "message", "task function must be a function");
    } else {
        id = p2_task_first_free(vm);
        if (id < 0) {
            p2_task_map_set_bool(vm, -1, "ok", 0);
            p2_task_map_set_int(vm, -1, "handle", -1);
            p2_task_map_set_string(vm, -1, "error", "no_free_slot");
            p2_task_map_set_string(vm, -1, "message", "no free task slots");
        } else {
            p2_task_activate_slot(vm, id, 1, 2, argc);
            p2_task_map_set_bool(vm, -1, "ok", 1);
            p2_task_map_set_int(vm, -1, "handle", id);
            p2_task_map_set_string(vm, -1, "error", "");
            p2_task_map_set_string(vm, -1, "message", "");
        }
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_spin(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id;
    int fn_index = 2;
    int first_arg = 3;
    int argc = be_top(vm) - 2;

    if (be_top(vm) < 2 || !be_isint(vm, 1) || !be_isfunction(vm, 2)) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    id = (int)be_toint(vm, 1);
    if (id == -1) {
        id = p2_task_first_free(vm);
    } else if (!p2_task_valid(id) || state->slots[id].status != P2_TASK_FREE) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    if (id < 0) {
        be_pushint(vm, -1);
        be_return(vm);
    }
    be_pushint(vm, p2_task_activate_slot(vm, id, fn_index, first_arg, argc));
    be_return(vm);
}

static int m_task_sleep(bvm *vm)
{
    bint ms = be_top(vm) >= 1 && be_isint(vm, 1) ? be_toint(vm, 1) : 0;
    if (ms < 0) {
        ms = 0;
    }
    p2_task_delay_ms(vm, ms);
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "_task_wait", "sleep");
    p2_task_map_set_int(vm, -1, "ms", ms);
    be_return(vm);
}

static int m_task_wait(bvm *vm)
{
    const char *event;
    bint timeout;

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "queue")) {
        const char *mode = "get";
        if (be_top(vm) >= 2 && be_isstring(vm, 2)) {
            mode = !strcmp(be_tostring(vm, 2), "put") ? "put" : "get";
        }
        timeout = be_top(vm) >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) :
            (be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1);
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", !strcmp(mode, "put") ? "queue_put" : "queue_get");
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "sem")) {
        timeout = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1;
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", "sem");
        p2_task_map_set_string(vm, -1, "mode", "take");
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "mutex")) {
        timeout = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1;
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", "mutex");
        p2_task_map_set_string(vm, -1, "mode", "lock");
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "flags")) {
        int mask = be_top(vm) >= 2 && be_isint(vm, 2) ? (int)be_toint(vm, 2) : p2_task_get_member_int(vm, 1, "_last_mask", 0);
        const char *mode = be_top(vm) >= 3 && be_isstring(vm, 3) && !strcmp(be_tostring(vm, 3), "all") ? "all" : "any";
        timeout = be_top(vm) >= 4 && be_isint(vm, 4) ? be_toint(vm, 4) :
            (be_top(vm) >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) : -1);
        p2_task_set_member_int(vm, 1, "_last_mask", mask);
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", "flags");
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_int(vm, -1, "mask", mask);
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "timer")) {
        timeout = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1;
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", "timer");
        p2_task_map_set_string(vm, -1, "mode", "expired");
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "p2ipc_channel")) {
        const char *mode = "recv";
        if (be_top(vm) >= 2 && be_isstring(vm, 2)) {
            const char *input = be_tostring(vm, 2);
            mode = !strcmp(input, "send") || !strcmp(input, "put") ? "send" : "recv";
        }
        timeout = be_top(vm) >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) :
            (be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1);
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", !strcmp(mode, "send") ? "p2ipc_channel_send" : "p2ipc_channel_recv");
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "p2ipc_mailbox")) {
        const char *mode = "get";
        if (be_top(vm) >= 2 && be_isstring(vm, 2)) {
            const char *input = be_tostring(vm, 2);
            mode = !strcmp(input, "put") || !strcmp(input, "send") ? "put" : "get";
        }
        timeout = be_top(vm) >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) :
            (be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1);
        be_newobject(vm, "map");
        p2_task_map_set_string(vm, -1, "_task_wait", !strcmp(mode, "put") ? "p2ipc_mailbox_put" : "p2ipc_mailbox_get");
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_value(vm, -1, "wait_object", 1);
        if (timeout >= 0) {
            p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
        }
        be_return(vm);
    }

    event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    timeout = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : -1;
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "_task_wait", "event");
    p2_task_map_set_string(vm, -1, "event", event);
    if (timeout >= 0) {
        p2_task_map_set_int(vm, -1, "timeout", p2_task_delay_ms(vm, timeout));
    }
    be_return(vm);
}

static int m_task_signal(bvm *vm)
{
    const char *event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    be_pushbool(vm, p2_task_signal_event(vm, event) ? btrue : bfalse);
    be_return(vm);
}

static int m_task_clear(bvm *vm)
{
    const char *event = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : "";
    be_pushbool(vm, p2_task_clear_event(vm, event) ? btrue : bfalse);
    be_return(vm);
}

static int m_task_clear_all(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    memset(state->events, 0, sizeof(state->events));
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_events(bvm *vm)
{
    p2_task_push_events(vm);
    be_return(vm);
}

static int m_task_ready_result(bvm *vm)
{
    const char *event = NULL;
    bvalue *target = be_top(vm) >= 1 ? be_indexof(vm, 1) : NULL;
    const char *wait_kind = p2_task_wait_kind_from_value(vm, target);

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "queue")) {
        const char *mode = be_top(vm) >= 2 && be_isstring(vm, 2) && !strcmp(be_tostring(vm, 2), "put") ? "put" : "get";
        int depth = p2_task_get_member_int(vm, 1, "depth", 0);
        int items = p2_task_get_queue_items(vm, 1);
        int size = p2_task_queue_size_from_items(vm, items);
        int free_slots = depth - size;
        int can_get = size > 0;
        int can_put = free_slots > 0;
        int ready = !strcmp(mode, "put") ? can_put : can_get;
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_string(vm, -1, "kind", "queue");
        p2_task_map_set_string(vm, -1, "wait", !strcmp(mode, "put") ? "queue_put" : "queue_get");
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_bool(vm, -1, "can_get", can_get);
        p2_task_map_set_bool(vm, -1, "can_put", can_put);
        p2_task_map_set_int(vm, -1, "size", size);
        p2_task_map_set_int(vm, -1, "free", free_slots);
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "queue is not ready for the requested operation");
        be_pop(vm, 1);
        be_remove(vm, items);
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "sem")) {
        int count = p2_task_get_member_int(vm, 1, "count", 0);
        int ready = count > 0;
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_string(vm, -1, "kind", "semaphore");
        p2_task_map_set_string(vm, -1, "wait", "sem");
        p2_task_map_set_string(vm, -1, "mode", "take");
        p2_task_map_set_int(vm, -1, "count", count);
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "semaphore count is zero");
        be_pop(vm, 1);
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "mutex")) {
        int locked = p2_task_get_member_bool(vm, 1, "locked", 0);
        int ready = !locked;
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_string(vm, -1, "kind", "mutex");
        p2_task_map_set_string(vm, -1, "wait", "mutex");
        p2_task_map_set_string(vm, -1, "mode", "lock");
        p2_task_map_set_bool(vm, -1, "locked", locked);
        p2_task_map_set_int(vm, -1, "owner", p2_task_get_member_int(vm, 1, "owner_id", -1));
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "mutex is locked");
        be_pop(vm, 1);
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "flags")) {
        int flags = p2_task_get_member_int(vm, 1, "flags", 0);
        const char *input_mode = be_top(vm) >= 3 && be_isstring(vm, 3) ? be_tostring(vm, 3) : "any";
        const char *mode = input_mode && !strcmp(input_mode, "all") ? "all" : "any";
        int mask;
        int ready;
        if (be_top(vm) < 2 || !be_isint(vm, 2)) {
            be_newobject(vm, "map");
            p2_task_map_set_bool(vm, -1, "ok", 0);
            p2_task_map_set_bool(vm, -1, "ready", 0);
            p2_task_map_set_int(vm, -1, "value", flags);
            event_flags_push_mask_value(vm, -1, "mask", be_top(vm) >= 2 ? 2 : 0, 0);
            p2_task_map_set_string(vm, -1, "mode", mode);
            p2_task_map_set_string(vm, -1, "kind", "flags");
            p2_task_map_set_string(vm, -1, "wait", "flags");
            p2_task_map_set_string(vm, -1, "error", "invalid_mask");
            p2_task_map_set_string(vm, -1, "message", "event flag mask must be an int");
            be_pop(vm, 1);
            be_return(vm);
        }
        mask = (int)be_toint(vm, 2);
        ready = !strcmp(mode, "all") ? ((flags & mask) == mask) : ((flags & mask) != 0);
        p2_task_set_member_int(vm, 1, "_last_mask", mask);
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_int(vm, -1, "value", flags);
        event_flags_push_mask_value(vm, -1, "mask", 2, mask);
        p2_task_map_set_string(vm, -1, "mode", mode);
        p2_task_map_set_string(vm, -1, "kind", "flags");
        p2_task_map_set_string(vm, -1, "wait", "flags");
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "event flags are not ready");
        be_pop(vm, 1);
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "timer")) {
        int ready = timer_ready(vm, 1);
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_string(vm, -1, "kind", "timer");
        p2_task_map_set_string(vm, -1, "wait", "timer");
        p2_task_map_set_string(vm, -1, "mode", "expired");
        p2_task_map_set_bool(vm, -1, "active", p2_task_get_member_bool(vm, 1, "active", 0));
        p2_task_map_set_int(vm, -1, "remaining_ms", timer_remaining_ms(vm, 1));
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "timer has not expired");
        be_pop(vm, 1);
        be_return(vm);
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "p2ipc_channel")) {
        const char *input_mode = be_top(vm) >= 2 && be_isstring(vm, 2) ? be_tostring(vm, 2) : "recv";
        if (be_getmember(vm, 1, "ready_result")) {
            be_pushvalue(vm, 1);
            be_pushstring(vm, input_mode);
            be_call(vm, 2);
            be_pop(vm, 2);
            be_return(vm);
        } else {
            be_pop(vm, 1);
        }
    }

    if (be_top(vm) >= 1 && p2_task_member_string_is(vm, 1, "_task_kind", "p2ipc_mailbox")) {
        const char *input_mode = be_top(vm) >= 2 && be_isstring(vm, 2) ? be_tostring(vm, 2) : "get";
        if (be_getmember(vm, 1, "ready_result")) {
            be_pushvalue(vm, 1);
            be_pushstring(vm, input_mode);
            be_call(vm, 2);
            be_pop(vm, 2);
            be_return(vm);
        } else {
            be_pop(vm, 1);
        }
    }

    if (be_top(vm) >= 1 && be_isstring(vm, 1)) {
        event = be_tostring(vm, 1);
    } else if (wait_kind && !strcmp(wait_kind, "event") && target && var_ismap(target)) {
        event = p2_task_map_str_or(vm, var_toobj(target), "event", "");
    }

    be_newobject(vm, "map");
    if (!event || !event[0]) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_bool(vm, -1, "ready", 0);
        p2_task_map_set_string(vm, -1, "kind", "event");
        p2_task_map_set_string(vm, -1, "event", "");
        p2_task_map_set_string(vm, -1, "mode", "event");
        p2_task_map_set_string(vm, -1, "error", "invalid_event");
        p2_task_map_set_string(vm, -1, "message", "event name must be a non-empty string or event wait descriptor");
    } else {
        int ready = p2_task_event_latched(vm, event);
        p2_task_map_set_bool(vm, -1, "ok", ready);
        p2_task_map_set_bool(vm, -1, "ready", ready);
        p2_task_map_set_string(vm, -1, "kind", "event");
        p2_task_map_set_string(vm, -1, "event", event);
        p2_task_map_set_string(vm, -1, "mode", "event");
        p2_task_map_set_string(vm, -1, "error", ready ? "" : "not_ready");
        p2_task_map_set_string(vm, -1, "message", ready ? "" : "event is not signaled");
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int semaphore_init(bvm *vm)
{
    bint count = 1;
    if (be_top(vm) >= 2) {
        if (!be_isint(vm, 2) || be_toint(vm, 2) < 0) {
            count = 0;
        } else {
            count = be_toint(vm, 2);
        }
    }
    be_pushstring(vm, "sem");
    be_setmember(vm, 1, "_task_kind");
    be_pop(vm, 1);
    p2_task_set_member_int(vm, 1, "count", count);
    be_pushvalue(vm, 1);
    be_return(vm);
}

static void semaphore_push_result(bvm *vm, int ok, int count, const char *error, const char *message)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    p2_task_map_set_int(vm, -1, "count", count);
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static int semaphore_take(bvm *vm)
{
    int count = p2_task_get_member_int(vm, 1, "count", 0);
    if (count <= 0) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_set_member_int(vm, 1, "count", count - 1);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int semaphore_take_result(bvm *vm)
{
    int count = p2_task_get_member_int(vm, 1, "count", 0);
    if (count <= 0) {
        semaphore_push_result(vm, 0, count, "unavailable", "semaphore count is zero");
        be_return(vm);
    }
    --count;
    p2_task_set_member_int(vm, 1, "count", count);
    semaphore_push_result(vm, 1, count, "", "");
    be_return(vm);
}

static int semaphore_give(bvm *vm)
{
    int count = p2_task_get_member_int(vm, 1, "count", 0) + 1;
    p2_task_set_member_int(vm, 1, "count", count);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int semaphore_give_result(bvm *vm)
{
    int count = p2_task_get_member_int(vm, 1, "count", 0) + 1;
    p2_task_set_member_int(vm, 1, "count", count);
    semaphore_push_result(vm, 1, count, "", "");
    be_return(vm);
}

static int semaphore_value(bvm *vm)
{
    be_pushint(vm, p2_task_get_member_int(vm, 1, "count", 0));
    be_return(vm);
}

static int semaphore_info(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "kind", "Semaphore");
    p2_task_map_set_int(vm, -1, "count", p2_task_get_member_int(vm, 1, "count", 0));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_semaphore_new(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "_task_kind", NULL },
        { "count", NULL },
        { "init", semaphore_init },
        { "take", semaphore_take },
        { "take_result", semaphore_take_result },
        { "give", semaphore_give },
        { "give_result", semaphore_give_result },
        { "value", semaphore_value },
        { "info", semaphore_info },
        { NULL, NULL }
    };
    int argc = be_top(vm);
    be_pushclass(vm, "Semaphore", members);
    if (argc >= 1) {
        be_pushvalue(vm, 1);
        be_call(vm, 1);
    } else {
        be_call(vm, 0);
    }
    be_return(vm);
}

static int mutex_init(bvm *vm)
{
    be_pushstring(vm, "mutex");
    be_setmember(vm, 1, "_task_kind");
    be_pop(vm, 1);
    p2_task_set_member_bool(vm, 1, "locked", 0);
    p2_task_set_member_int(vm, 1, "owner_id", -1);
    be_pushvalue(vm, 1);
    be_return(vm);
}

static void mutex_push_lock_result(bvm *vm, int ok, int locked, int owner, const char *error, const char *message)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    p2_task_map_set_bool(vm, -1, "locked", locked);
    p2_task_map_set_int(vm, -1, "owner", owner);
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static void mutex_push_unlock_result(bvm *vm, int ok, int locked, int owner, int previous_owner, const char *error, const char *message)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    p2_task_map_set_bool(vm, -1, "locked", locked);
    p2_task_map_set_int(vm, -1, "owner", owner);
    p2_task_map_set_int(vm, -1, "previous_owner", previous_owner);
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static int mutex_lock(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    if (p2_task_get_member_bool(vm, 1, "locked", 0)) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_set_member_bool(vm, 1, "locked", 1);
    p2_task_set_member_int(vm, 1, "owner_id", state->current);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int mutex_lock_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int locked = p2_task_get_member_bool(vm, 1, "locked", 0);
    int owner = p2_task_get_member_int(vm, 1, "owner_id", -1);
    if (locked) {
        mutex_push_lock_result(vm, 0, locked, owner, "busy", "mutex is already locked");
        be_return(vm);
    }
    owner = state->current;
    p2_task_set_member_bool(vm, 1, "locked", 1);
    p2_task_set_member_int(vm, 1, "owner_id", owner);
    mutex_push_lock_result(vm, 1, 1, owner, "", "");
    be_return(vm);
}

static int mutex_unlock(bvm *vm)
{
    if (!p2_task_get_member_bool(vm, 1, "locked", 0)) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_set_member_bool(vm, 1, "locked", 0);
    p2_task_set_member_int(vm, 1, "owner_id", -1);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int mutex_unlock_result(bvm *vm)
{
    int locked = p2_task_get_member_bool(vm, 1, "locked", 0);
    int owner = p2_task_get_member_int(vm, 1, "owner_id", -1);
    if (!locked) {
        mutex_push_unlock_result(vm, 0, 0, owner, owner, "not_locked", "mutex is not locked");
        be_return(vm);
    }
    p2_task_set_member_bool(vm, 1, "locked", 0);
    p2_task_set_member_int(vm, 1, "owner_id", -1);
    mutex_push_unlock_result(vm, 1, 0, -1, owner, "", "");
    be_return(vm);
}

static int mutex_owner(bvm *vm)
{
    be_pushint(vm, p2_task_get_member_int(vm, 1, "owner_id", -1));
    be_return(vm);
}

static int mutex_is_locked(bvm *vm)
{
    be_pushbool(vm, p2_task_get_member_bool(vm, 1, "locked", 0) ? btrue : bfalse);
    be_return(vm);
}

static int mutex_info(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "kind", "Mutex");
    p2_task_map_set_bool(vm, -1, "locked", p2_task_get_member_bool(vm, 1, "locked", 0));
    p2_task_map_set_int(vm, -1, "owner", p2_task_get_member_int(vm, 1, "owner_id", -1));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_mutex_new(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "_task_kind", NULL },
        { "locked", NULL },
        { "owner_id", NULL },
        { "init", mutex_init },
        { "lock", mutex_lock },
        { "lock_result", mutex_lock_result },
        { "unlock", mutex_unlock },
        { "unlock_result", mutex_unlock_result },
        { "owner", mutex_owner },
        { "is_locked", mutex_is_locked },
        { "info", mutex_info },
        { NULL, NULL }
    };
    be_pushclass(vm, "Mutex", members);
    be_call(vm, 0);
    be_return(vm);
}

static int queue_init(bvm *vm)
{
    bint depth = 8;
    if (be_top(vm) >= 2) {
        if (!be_isint(vm, 2) || be_toint(vm, 2) < 0) {
            depth = 0;
        } else {
            depth = be_toint(vm, 2);
        }
    } else {
        depth = 8;
    }
    be_pushstring(vm, "queue");
    be_setmember(vm, 1, "_task_kind");
    be_pop(vm, 1);
    be_pushint(vm, depth);
    be_setmember(vm, 1, "depth");
    be_pop(vm, 1);
    be_newobject(vm, "list");
    be_setmember(vm, 1, ".items");
    be_pushvalue(vm, 1);
    be_return(vm);
}

static void queue_push_result(bvm *vm, int ok, int value_index, int size, int free_slots, const char *error, const char *message)
{
    value_index = value_index ? be_absindex(vm, value_index) : 0;
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    if (value_index) {
        int result = be_absindex(vm, -1);
        be_pushstring(vm, "value");
        be_pushvalue(vm, value_index);
        be_data_insert(vm, result);
        be_pop(vm, 2);
    } else {
        be_pushstring(vm, "value");
        be_pushnil(vm);
        be_data_insert(vm, -3);
        be_pop(vm, 2);
    }
    p2_task_map_set_int(vm, -1, "size", size);
    p2_task_map_set_int(vm, -1, "free", free_slots);
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static int queue_put(bvm *vm)
{
    int depth = p2_task_get_member_int(vm, 1, "depth", 0);
    int items = p2_task_get_queue_items(vm, 1);
    int size = p2_task_queue_size_from_items(vm, items);
    if (size >= depth) {
        be_pop(vm, 1);
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    if (be_top(vm) >= 2) {
        be_pushvalue(vm, 2);
    } else {
        be_pushnil(vm);
    }
    be_data_push(vm, items);
    be_pop(vm, 2);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int queue_put_result(bvm *vm)
{
    int depth = p2_task_get_member_int(vm, 1, "depth", 0);
    int items = p2_task_get_queue_items(vm, 1);
    int size = p2_task_queue_size_from_items(vm, items);
    int value_index = be_top(vm) >= 2 ? 2 : 0;
    if (size >= depth) {
        queue_push_result(vm, 0, value_index, size, depth - size, "full", "queue is full");
        be_remove(vm, items);
        be_return(vm);
    }
    if (value_index) {
        be_pushvalue(vm, value_index);
    } else {
        be_pushnil(vm);
    }
    be_data_push(vm, items);
    be_pop(vm, 1);
    queue_push_result(vm, 1, value_index, size + 1, depth - size - 1, "", "");
    be_remove(vm, items);
    be_return(vm);
}

static int queue_get(bvm *vm)
{
    int items = p2_task_get_queue_items(vm, 1);
    blist *list = var_toobj(be_indexof(vm, items));
    bvalue *value;
    if (be_list_count(list) <= 0) {
        be_pop(vm, 1);
        be_return_nil(vm);
    }
    value = be_list_index(list, 0);
    if (value) {
        *vm->top = *value;
        be_incrtop(vm);
    } else {
        be_pushnil(vm);
    }
    be_list_remove(vm, list, 0);
    be_remove(vm, items);
    be_return(vm);
}

static int queue_get_result(bvm *vm)
{
    int depth = p2_task_get_member_int(vm, 1, "depth", 0);
    int items = p2_task_get_queue_items(vm, 1);
    blist *list = var_toobj(be_indexof(vm, items));
    int size = be_list_count(list);
    bvalue *value;
    if (size <= 0) {
        queue_push_result(vm, 0, 0, 0, depth, "empty", "queue is empty");
        be_remove(vm, items);
        be_return(vm);
    }
    value = be_list_index(list, 0);
    if (value) {
        *vm->top = *value;
        be_incrtop(vm);
    } else {
        be_pushnil(vm);
    }
    be_list_remove(vm, list, 0);
    queue_push_result(vm, 1, be_absindex(vm, -1), size - 1, depth - size + 1, "", "");
    be_remove(vm, items);
    be_return(vm);
}

static int queue_size(bvm *vm)
{
    int items = p2_task_get_queue_items(vm, 1);
    be_pushint(vm, p2_task_queue_size_from_items(vm, items));
    be_remove(vm, items);
    be_return(vm);
}

static int queue_free(bvm *vm)
{
    int depth = p2_task_get_member_int(vm, 1, "depth", 0);
    int items = p2_task_get_queue_items(vm, 1);
    int size = p2_task_queue_size_from_items(vm, items);
    be_pushint(vm, depth - size);
    be_remove(vm, items);
    be_return(vm);
}

static int queue_info(bvm *vm)
{
    int depth = p2_task_get_member_int(vm, 1, "depth", 0);
    int items = p2_task_get_queue_items(vm, 1);
    int size = p2_task_queue_size_from_items(vm, items);
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "kind", "Queue");
    p2_task_map_set_int(vm, -1, "depth", depth);
    p2_task_map_set_int(vm, -1, "size", size);
    p2_task_map_set_int(vm, -1, "free", depth - size);
    be_pop(vm, 1);
    be_remove(vm, items);
    be_return(vm);
}

static int m_task_queue_new(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "_task_kind", NULL },
        { "depth", NULL },
        { ".items", NULL },
        { "init", queue_init },
        { "put", queue_put },
        { "put_result", queue_put_result },
        { "get", queue_get },
        { "get_result", queue_get_result },
        { "size", queue_size },
        { "free", queue_free },
        { "info", queue_info },
        { NULL, NULL }
    };
    int argc = be_top(vm);
    be_pushclass(vm, "Queue", members);
    if (argc >= 1) {
        be_pushvalue(vm, 1);
        be_call(vm, 1);
    } else {
        be_call(vm, 0);
    }
    be_return(vm);
}

static int event_flags_init(bvm *vm)
{
    bint flags = 0;
    if (be_top(vm) >= 2 && be_isint(vm, 2)) {
        flags = be_toint(vm, 2);
    }
    be_pushstring(vm, "flags");
    be_setmember(vm, 1, "_task_kind");
    be_pop(vm, 1);
    p2_task_set_member_int(vm, 1, "flags", (int)flags);
    p2_task_set_member_int(vm, 1, "_last_mask", 0);
    be_pushvalue(vm, 1);
    be_return(vm);
}

static void event_flags_push_mask_value(bvm *vm, int map_index, const char *key, int value_index, int fallback)
{
    map_index = be_absindex(vm, map_index);
    be_pushstring(vm, key);
    if (value_index) {
        be_pushvalue(vm, be_absindex(vm, value_index));
    } else {
        be_pushint(vm, fallback);
    }
    be_data_insert(vm, map_index);
    be_pop(vm, 2);
}

static void event_flags_push_update_result(bvm *vm, int ok, int value, int mask_index, int fallback_mask, const char *error, const char *message)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    p2_task_map_set_int(vm, -1, "value", value);
    event_flags_push_mask_value(vm, -1, "mask", mask_index, fallback_mask);
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static void event_flags_push_ready_result(bvm *vm, int ok, int ready, int value, int mask_index, int fallback_mask, const char *mode, const char *error, const char *message)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", ok);
    p2_task_map_set_bool(vm, -1, "ready", ready);
    p2_task_map_set_int(vm, -1, "value", value);
    event_flags_push_mask_value(vm, -1, "mask", mask_index, fallback_mask);
    p2_task_map_set_string(vm, -1, "mode", mode ? mode : "any");
    p2_task_map_set_string(vm, -1, "error", error ? error : "");
    p2_task_map_set_string(vm, -1, "message", message ? message : "");
    be_pop(vm, 1);
}

static int event_flags_set(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    if (be_top(vm) >= 2 && be_isint(vm, 2)) {
        flags |= (int)be_toint(vm, 2);
        p2_task_set_member_int(vm, 1, "flags", flags);
    }
    be_pushint(vm, flags);
    be_return(vm);
}

static int event_flags_set_result(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    if (be_top(vm) < 2 || !be_isint(vm, 2)) {
        event_flags_push_update_result(vm, 0, flags, be_top(vm) >= 2 ? 2 : 0, 0, "invalid_mask", "event flag mask must be an int");
        be_return(vm);
    }
    flags |= (int)be_toint(vm, 2);
    p2_task_set_member_int(vm, 1, "flags", flags);
    event_flags_push_update_result(vm, 1, flags, 2, (int)be_toint(vm, 2), "", "");
    be_return(vm);
}

static int event_flags_clear(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    if (be_top(vm) >= 2 && be_isint(vm, 2)) {
        flags &= ~((int)be_toint(vm, 2));
        p2_task_set_member_int(vm, 1, "flags", flags);
    }
    be_pushint(vm, flags);
    be_return(vm);
}

static int event_flags_clear_result(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    if (be_top(vm) < 2 || !be_isint(vm, 2)) {
        event_flags_push_update_result(vm, 0, flags, be_top(vm) >= 2 ? 2 : 0, 0, "invalid_mask", "event flag mask must be an int");
        be_return(vm);
    }
    flags &= ~((int)be_toint(vm, 2));
    p2_task_set_member_int(vm, 1, "flags", flags);
    event_flags_push_update_result(vm, 1, flags, 2, (int)be_toint(vm, 2), "", "");
    be_return(vm);
}

static int event_flags_value(bvm *vm)
{
    be_pushint(vm, p2_task_get_member_int(vm, 1, "flags", 0));
    be_return(vm);
}

static int event_flags_ready(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    int mask;
    const char *mode;
    int ready;
    if (be_top(vm) < 2 || !be_isint(vm, 2)) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    mask = (int)be_toint(vm, 2);
    mode = be_top(vm) >= 3 && be_isstring(vm, 3) ? be_tostring(vm, 3) : "any";
    p2_task_set_member_int(vm, 1, "_last_mask", mask);
    ready = (mode && !strcmp(mode, "all")) ? ((flags & mask) == mask) : ((flags & mask) != 0);
    be_pushbool(vm, ready ? btrue : bfalse);
    be_return(vm);
}

static int event_flags_ready_result(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    int mask;
    const char *input_mode;
    const char *mode;
    int ready;
    if (be_top(vm) < 2 || !be_isint(vm, 2)) {
        input_mode = be_top(vm) >= 3 && be_isstring(vm, 3) ? be_tostring(vm, 3) : "any";
        event_flags_push_ready_result(vm, 0, 0, flags, be_top(vm) >= 2 ? 2 : 0, 0, input_mode, "invalid_mask", "event flag mask must be an int");
        be_return(vm);
    }
    mask = (int)be_toint(vm, 2);
    input_mode = be_top(vm) >= 3 && be_isstring(vm, 3) ? be_tostring(vm, 3) : "any";
    mode = (input_mode && !strcmp(input_mode, "all")) ? "all" : "any";
    ready = !strcmp(mode, "all") ? ((flags & mask) == mask) : ((flags & mask) != 0);
    p2_task_set_member_int(vm, 1, "_last_mask", mask);
    event_flags_push_ready_result(vm, ready, ready, flags, 2, mask, mode, ready ? "" : "not_ready", ready ? "" : "event flags are not ready");
    be_return(vm);
}

static int event_flags_wait(bvm *vm)
{
    int flags = p2_task_get_member_int(vm, 1, "flags", 0);
    int mask;
    if (be_top(vm) < 2 || !be_isint(vm, 2)) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    mask = (int)be_toint(vm, 2);
    p2_task_set_member_int(vm, 1, "_last_mask", mask);
    be_pushbool(vm, (flags & mask) != 0 ? btrue : bfalse);
    be_return(vm);
}

static int event_flags_info(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "kind", "EventFlags");
    p2_task_map_set_int(vm, -1, "value", p2_task_get_member_int(vm, 1, "flags", 0));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_event_flags_new(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "_task_kind", NULL },
        { "flags", NULL },
        { "_last_mask", NULL },
        { "init", event_flags_init },
        { "set", event_flags_set },
        { "set_result", event_flags_set_result },
        { "clear", event_flags_clear },
        { "clear_result", event_flags_clear_result },
        { "value", event_flags_value },
        { "ready", event_flags_ready },
        { "ready_result", event_flags_ready_result },
        { "wait", event_flags_wait },
        { "info", event_flags_info },
        { NULL, NULL }
    };
    int argc = be_top(vm);
    be_pushclass(vm, "EventFlags", members);
    if (argc >= 1) {
        be_pushvalue(vm, 1);
        be_call(vm, 1);
    } else {
        be_call(vm, 0);
    }
    be_return(vm);
}

static p2_deadline timer_deadline(bvm *vm, int self_index)
{
    p2_deadline deadline;
    deadline.at_ms = (uint32_t)p2_task_get_member_int(vm, self_index, "deadline", 0);
    deadline.armed = p2_task_get_member_bool(vm, self_index, "active", 0);
    return deadline;
}

static uint32_t timer_period(bvm *vm, int self_index)
{
    bint period = 0;
    if (be_getmember(vm, self_index, "period_ms") && be_isint(vm, -1)) {
        period = be_toint(vm, -1);
    }
    be_pop(vm, 1);
    return p2_task_delay_ms(vm, period);
}

static uint32_t timer_rearm(bvm *vm, int self_index)
{
    uint32_t period = timer_period(vm, self_index);
    p2_deadline deadline;
    /* Repeats remain fixed-delay: late polling starts a fresh period at now. */
    p2_deadline_arm(&deadline, p2_task_millis_now(vm), period);
    p2_task_set_member_int(vm, self_index, "deadline", p2_task_millis_value(deadline.at_ms));
    p2_task_set_member_bool(vm, self_index, "active", deadline.armed);
    return deadline.at_ms;
}

static int timer_init(bvm *vm)
{
    int period = 10;
    int repeat = 1;
    p2_deadline deadline;
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isint(vm, 2) || be_toint(vm, 2) < 0) {
            period = 0;
        } else {
            period = (int)p2_task_delay_ms(vm, be_toint(vm, 2));
        }
    }
    if (be_top(vm) >= 3 && !be_isnil(vm, 3)) {
        repeat = be_tobool(vm, 3) ? 1 : 0;
    }
    p2_deadline_arm(&deadline, p2_task_millis_now(vm), (uint32_t)period);
    be_pushstring(vm, "timer");
    be_setmember(vm, 1, "_task_kind");
    be_pop(vm, 1);
    p2_task_set_member_int(vm, 1, "period_ms", period);
    p2_task_set_member_bool(vm, 1, "repeat", repeat);
    p2_task_set_member_int(vm, 1, "deadline", p2_task_millis_value(deadline.at_ms));
    p2_task_set_member_bool(vm, 1, "active", 1);
    be_pushvalue(vm, 1);
    be_return(vm);
}

static int timer_ready(bvm *vm, int self_index)
{
    p2_deadline deadline = timer_deadline(vm, self_index);
    return deadline.armed && p2_deadline_reached(&deadline, p2_task_millis_now(vm));
}

static int timer_remaining_ms(bvm *vm, int self_index)
{
    p2_deadline deadline = timer_deadline(vm, self_index);
    if (!deadline.armed) {
        return 0;
    }
    return (int)p2_deadline_remaining(&deadline, p2_task_millis_now(vm));
}

static int timer_expired(bvm *vm)
{
    if (!timer_ready(vm, 1)) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    if (p2_task_get_member_bool(vm, 1, "repeat", 1)) {
        timer_rearm(vm, 1);
    } else {
        p2_task_set_member_bool(vm, 1, "active", 0);
    }
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int timer_expired_result(bvm *vm)
{
    int active = p2_task_get_member_bool(vm, 1, "active", 0);
    int repeat = p2_task_get_member_bool(vm, 1, "repeat", 1);
    uint32_t deadline = timer_deadline(vm, 1).at_ms;
    uint32_t previous_deadline = deadline;
    if (!timer_ready(vm, 1)) {
        be_newobject(vm, "map");
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_bool(vm, -1, "expired", 0);
        p2_task_map_set_bool(vm, -1, "active", active);
        p2_task_map_set_bool(vm, -1, "repeat", repeat);
        p2_task_map_set_int(vm, -1, "deadline", p2_task_millis_value(deadline));
        p2_task_map_set_string(vm, -1, "error", "not_expired");
        p2_task_map_set_string(vm, -1, "message", "timer has not expired");
        be_pop(vm, 1);
        be_return(vm);
    }
    if (repeat) {
        deadline = timer_rearm(vm, 1);
        active = 1;
    } else {
        p2_task_set_member_bool(vm, 1, "active", 0);
        active = 0;
    }
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_bool(vm, -1, "expired", 1);
    p2_task_map_set_bool(vm, -1, "active", active);
    p2_task_map_set_bool(vm, -1, "repeat", repeat);
    p2_task_map_set_int(vm, -1, "deadline", p2_task_millis_value(deadline));
    p2_task_map_set_int(vm, -1, "previous_deadline", p2_task_millis_value(previous_deadline));
    p2_task_map_set_string(vm, -1, "error", "");
    p2_task_map_set_string(vm, -1, "message", "");
    be_pop(vm, 1);
    be_return(vm);
}

static int timer_remaining(bvm *vm)
{
    be_pushint(vm, timer_remaining_ms(vm, 1));
    be_return(vm);
}

static int timer_remaining_result(bvm *vm)
{
    int active = p2_task_get_member_bool(vm, 1, "active", 0);
    int left = timer_remaining_ms(vm, 1);
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", active);
    p2_task_map_set_bool(vm, -1, "active", active);
    p2_task_map_set_int(vm, -1, "remaining_ms", left);
    p2_task_map_set_int(vm, -1, "deadline", p2_task_get_member_int(vm, 1, "deadline", 0));
    p2_task_map_set_int(vm, -1, "period_ms", p2_task_get_member_int(vm, 1, "period_ms", 0));
    p2_task_map_set_string(vm, -1, "error", active ? "" : "inactive");
    p2_task_map_set_string(vm, -1, "message", active ? "" : "timer is not active");
    be_pop(vm, 1);
    be_return(vm);
}

static int timer_cancel(bvm *vm)
{
    p2_task_set_member_bool(vm, 1, "active", 0);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int timer_cancel_result(bvm *vm)
{
    int was_active = p2_task_get_member_bool(vm, 1, "active", 0);
    p2_task_set_member_bool(vm, 1, "active", 0);
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_bool(vm, -1, "active", 0);
    p2_task_map_set_bool(vm, -1, "was_active", was_active);
    p2_task_map_set_int(vm, -1, "deadline", p2_task_get_member_int(vm, 1, "deadline", 0));
    p2_task_map_set_string(vm, -1, "error", "");
    p2_task_map_set_string(vm, -1, "message", "");
    be_pop(vm, 1);
    be_return(vm);
}

static int timer_restart(bvm *vm)
{
    timer_rearm(vm, 1);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int timer_restart_result(bvm *vm)
{
    uint32_t deadline = timer_rearm(vm, 1);
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_bool(vm, -1, "active", 1);
    p2_task_map_set_int(vm, -1, "deadline", p2_task_millis_value(deadline));
    p2_task_map_set_int(vm, -1, "period_ms", timer_period(vm, 1));
    p2_task_map_set_string(vm, -1, "error", "");
    p2_task_map_set_string(vm, -1, "message", "");
    be_pop(vm, 1);
    be_return(vm);
}

static int timer_info(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "kind", "Timer");
    p2_task_map_set_int(vm, -1, "period_ms", p2_task_get_member_int(vm, 1, "period_ms", 0));
    p2_task_map_set_bool(vm, -1, "repeat", p2_task_get_member_bool(vm, 1, "repeat", 1));
    p2_task_map_set_bool(vm, -1, "active", p2_task_get_member_bool(vm, 1, "active", 0));
    p2_task_map_set_int(vm, -1, "deadline", p2_task_get_member_int(vm, 1, "deadline", 0));
    p2_task_map_set_int(vm, -1, "remaining_ms", timer_remaining_ms(vm, 1));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_timer_new(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "_task_kind", NULL },
        { "period_ms", NULL },
        { "repeat", NULL },
        { "deadline", NULL },
        { "active", NULL },
        { "init", timer_init },
        { "expired", timer_expired },
        { "expired_result", timer_expired_result },
        { "remaining", timer_remaining },
        { "remaining_result", timer_remaining_result },
        { "cancel", timer_cancel },
        { "cancel_result", timer_cancel_result },
        { "restart", timer_restart },
        { "restart_result", timer_restart_result },
        { "info", timer_info },
        { NULL, NULL }
    };
    int argc = be_top(vm);
    be_pushclass(vm, "Timer", members);
    if (argc >= 1) {
        be_pushvalue(vm, 1);
        if (argc >= 2) {
            be_pushvalue(vm, 2);
            be_call(vm, 2);
        } else {
            be_call(vm, 1);
        }
    } else {
        be_call(vm, 0);
    }
    be_return(vm);
}

static int m_task_next(bvm *vm)
{
    int ran;

    ran = p2_task_next_internal(vm);
    be_pushint(vm, ran);
    be_return(vm);
}

static int m_task_next_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int live_before = p2_task_live_count(vm);
    int ran = p2_task_next_internal(vm);
    int live_after = p2_task_live_count(vm);
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", ran);
    p2_task_map_set_int(vm, -1, "live_before", live_before);
    p2_task_map_set_int(vm, -1, "live_after", live_after);
    p2_task_map_set_int(vm, -1, "ready_after", p2_task_status_count(vm, P2_TASK_READY));
    p2_task_map_set_int(vm, -1, "waiting_after", p2_task_status_count(vm, P2_TASK_WAITING));
    if (ran < 0) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_bool(vm, -1, "ran", 0);
        p2_task_map_set_string(vm, -1, "status", "idle");
        p2_task_map_set_int(vm, -1, "runs", 0);
        p2_task_map_set_string(vm, -1, "last_error", "");
        p2_task_map_set_string(vm, -1, "error", "no_ready_task");
        p2_task_map_set_string(vm, -1, "message", "no ready cooperative task was available");
    } else {
        p2_task_slot *slot = &state->slots[ran];
        p2_task_map_set_bool(vm, -1, "ok", 1);
        p2_task_map_set_bool(vm, -1, "ran", 1);
        p2_task_map_set_string(vm, -1, "status", p2_task_status_name(slot->status));
        p2_task_map_set_int(vm, -1, "runs", slot->runs);
        p2_task_map_set_string(vm, -1, "last_error", slot->last_error);
        p2_task_map_set_string(vm, -1, "error", "");
        p2_task_map_set_string(vm, -1, "message", "");
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int p2_task_next_internal(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    p2_task_wake_waiting(vm);
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        state->next = (state->next + 1) % P2_TASK_MAX_TASKS;
        if (state->slots[state->next].status == P2_TASK_READY) {
            return p2_task_run_slot(vm, state->next);
        }
    }
    return -1;
}

static int p2_task_live_count(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    int count = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (state->slots[i].status == P2_TASK_READY ||
            state->slots[i].status == P2_TASK_WAITING) {
            ++count;
        }
    }
    return count;
}

static int p2_task_status_count(bvm *vm, int wanted)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    int count = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (state->slots[i].status == wanted) {
            ++count;
        }
    }
    return count;
}

static int p2_task_active_count(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    int count = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (state->slots[i].status != P2_TASK_FREE) {
            ++count;
        }
    }
    return count;
}

static int p2_task_event_count(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    int count = 0;
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (state->events[i][0]) {
            ++count;
        }
    }
    return count;
}

static void p2_task_push_events(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    be_newobject(vm, "list");
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (state->events[i][0]) {
            p2_task_list_push_string(vm, -1, state->events[i]);
        }
    }
    be_pop(vm, 1);
}

static int m_task_run(bvm *vm)
{
    int max_steps = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    bint idle_ms = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : 1;
    int steps = 0;

    if (idle_ms > 0) {
        p2_task_delay_ms(vm, idle_ms);
    }
    while (max_steps < 0 || steps < max_steps) {
        int before = steps;
        p2_task_wake_waiting(vm);
        if (p2_task_live_count(vm) <= 0) {
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

static int m_task_run_result(bvm *vm)
{
    int max_steps = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    bint idle_ms = be_top(vm) >= 2 && be_isint(vm, 2) ? be_toint(vm, 2) : 1;
    int steps = 0;
    int live_before = p2_task_live_count(vm);

    if (idle_ms > 0) {
        p2_task_delay_ms(vm, idle_ms);
    }
    while (max_steps < 0 || steps < max_steps) {
        int before = steps;
        p2_task_wake_waiting(vm);
        if (p2_task_live_count(vm) <= 0) {
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

    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_int(vm, -1, "steps", steps);
    p2_task_map_set_int(vm, -1, "max_steps", max_steps);
    p2_task_map_set_int(vm, -1, "idle_ms", idle_ms);
    p2_task_map_set_int(vm, -1, "live_before", live_before);
    p2_task_map_set_int(vm, -1, "live_after", p2_task_live_count(vm));
    p2_task_map_set_int(vm, -1, "ready_after", p2_task_status_count(vm, P2_TASK_READY));
    p2_task_map_set_int(vm, -1, "waiting_after", p2_task_status_count(vm, P2_TASK_WAITING));
    p2_task_map_set_int(vm, -1, "paused_after", p2_task_status_count(vm, P2_TASK_PAUSED));
    p2_task_map_set_int(vm, -1, "errors_after", p2_task_status_count(vm, P2_TASK_ERROR));
    p2_task_map_set_bool(vm, -1, "complete", p2_task_live_count(vm) == 0);
    be_pop(vm, 1);
    be_return(vm);
}

static int p2_task_resolve_handle(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    if (be_top(vm) < 1 || be_isnil(vm, 1) || (be_isint(vm, 1) && be_toint(vm, 1) == -1)) {
        return state->current;
    }
    return be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
}

static void p2_task_push_lifecycle_result(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_bool(vm, -1, "current_vm", 1);
    p2_task_map_set_string(vm, -1, "backend", "p2_native_cooperative");
    if (!p2_task_valid(id)) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_bool(vm, -1, "allocated", 0);
        p2_task_map_set_string(vm, -1, "status", "invalid");
        p2_task_map_set_string(vm, -1, "wait", "");
        p2_task_map_set_int(vm, -1, "runs", 0);
        p2_task_map_set_int(vm, -1, "wakeups", 0);
        p2_task_map_set_string(vm, -1, "last_error", "");
        p2_task_map_set_string(vm, -1, "error", "invalid_handle");
        p2_task_map_set_string(vm, -1, "message", "invalid task handle");
    } else {
        p2_task_slot *slot = &state->slots[id];
        p2_task_map_set_bool(vm, -1, "ok", 1);
        p2_task_map_set_bool(vm, -1, "allocated", slot->status != P2_TASK_FREE);
        p2_task_map_set_string(vm, -1, "status", p2_task_status_name(slot->status));
        p2_task_map_set_string(vm, -1, "wait", p2_task_wait_name(slot->wait_kind));
        p2_task_map_set_string(vm, -1, "wait_event", slot->wait_event);
        p2_task_map_set_int(vm, -1, "deadline", p2_task_millis_value(slot->deadline.at_ms));
        p2_task_map_set_bool(vm, -1, "deadline_armed", slot->deadline.armed);
        p2_task_map_set_int(vm, -1, "runs", slot->runs);
        p2_task_map_set_int(vm, -1, "wakeups", slot->wakeups);
        p2_task_map_set_bool(vm, -1, "woke_timeout", slot->woke_timeout);
        p2_task_map_set_string(vm, -1, "woke_event", slot->woke_event);
        p2_task_map_set_string(vm, -1, "last_error", slot->last_error);
        p2_task_map_set_string(vm, -1, "error", "");
        p2_task_map_set_string(vm, -1, "message", "");
    }
    be_pop(vm, 1);
}

static int m_task_stop(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = p2_task_resolve_handle(vm);
    if (!p2_task_valid(id) || state->slots[id].status == P2_TASK_FREE) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    p2_task_free_slot(vm, id);
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_stop_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = p2_task_resolve_handle(vm);
    const char *previous = p2_task_valid(id) ? p2_task_status_name(state->slots[id].status) : "invalid";
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_string(vm, -1, "previous_status", previous);
    if (!p2_task_valid(id)) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", "invalid");
        p2_task_map_set_string(vm, -1, "error", "invalid_handle");
        p2_task_map_set_string(vm, -1, "message", "invalid task handle");
    } else if (state->slots[id].status == P2_TASK_FREE) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", "free");
        p2_task_map_set_string(vm, -1, "error", "free");
        p2_task_map_set_string(vm, -1, "message", "task slot is already free");
    } else {
        p2_task_free_slot(vm, id);
        p2_task_map_set_bool(vm, -1, "ok", 1);
        p2_task_map_set_string(vm, -1, "status", "free");
        p2_task_map_set_string(vm, -1, "error", "");
        p2_task_map_set_string(vm, -1, "message", "");
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_pause(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = p2_task_resolve_handle(vm);
    if (!p2_task_valid(id) || state->slots[id].status == P2_TASK_FREE) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    state->slots[id].status = P2_TASK_PAUSED;
    be_pushbool(vm, btrue);
    p2_deadline_cancel(&state->slots[id].deadline);
    be_return(vm);
}

static int m_task_pause_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = p2_task_resolve_handle(vm);
    const char *previous = p2_task_valid(id) ? p2_task_status_name(state->slots[id].status) : "invalid";
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_string(vm, -1, "previous_status", previous);
    if (!p2_task_valid(id)) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", "invalid");
        p2_task_map_set_string(vm, -1, "error", "invalid_handle");
        p2_task_map_set_string(vm, -1, "message", "invalid task handle");
    } else if (state->slots[id].status == P2_TASK_FREE) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", "free");
        p2_task_map_set_string(vm, -1, "error", "free");
        p2_task_map_set_string(vm, -1, "message", "task slot is free");
    } else {
        state->slots[id].status = P2_TASK_PAUSED;
        p2_task_map_set_bool(vm, -1, "ok", 1);
        p2_deadline_cancel(&state->slots[id].deadline);
        p2_task_map_set_string(vm, -1, "status", "paused");
        p2_task_map_set_string(vm, -1, "error", "");
        p2_task_map_set_string(vm, -1, "message", "");
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_resume(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    if (!p2_task_valid(id) || state->slots[id].status != P2_TASK_PAUSED) {
        be_pushbool(vm, bfalse);
        be_return(vm);
    }
    state->slots[id].status = P2_TASK_READY;
    be_pushbool(vm, btrue);
    p2_deadline_cancel(&state->slots[id].deadline);
    be_return(vm);
}

static int m_task_resume_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    const char *previous = p2_task_valid(id) ? p2_task_status_name(state->slots[id].status) : "invalid";
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_string(vm, -1, "previous_status", previous);
    if (!p2_task_valid(id)) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", "invalid");
        p2_task_map_set_string(vm, -1, "error", "invalid_handle");
        p2_task_map_set_string(vm, -1, "message", "invalid task handle");
    } else if (state->slots[id].status != P2_TASK_PAUSED) {
        p2_task_map_set_bool(vm, -1, "ok", 0);
        p2_task_map_set_string(vm, -1, "status", previous);
        p2_task_map_set_string(vm, -1, "error", "not_paused");
        p2_task_map_set_string(vm, -1, "message", "task is not paused");
    } else {
        state->slots[id].status = P2_TASK_READY;
        p2_task_map_set_bool(vm, -1, "ok", 1);
        p2_deadline_cancel(&state->slots[id].deadline);
        p2_task_map_set_string(vm, -1, "status", "ready");
        p2_task_map_set_string(vm, -1, "error", "");
        p2_task_map_set_string(vm, -1, "message", "");
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_chk(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    be_pushbool(vm, p2_task_valid(id) && state->slots[id].status != P2_TASK_FREE ? btrue : bfalse);
    be_return(vm);
}

static int m_task_status(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int id = be_top(vm) >= 1 && be_isint(vm, 1) ? (int)be_toint(vm, 1) : -1;
    be_pushstring(vm, p2_task_valid(id) ? p2_task_status_name(state->slots[id].status) : "free");
    be_return(vm);
}

static int m_task_current(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    be_pushint(vm, state->current);
    be_return(vm);
}

static int m_task_id(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    be_pushint(vm, state->current);
    be_return(vm);
}

static int m_task_lifecycle_result(bvm *vm)
{
    int id = p2_task_resolve_handle(vm);
    p2_task_push_lifecycle_result(vm, id);
    be_return(vm);
}

static void p2_task_push_slot_info(bvm *vm, int id)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    p2_task_slot *slot = &state->slots[id];
    be_newobject(vm, "map");
    p2_task_map_set_int(vm, -1, "handle", id);
    p2_task_map_set_string(vm, -1, "status", p2_task_status_name(slot->status));
    p2_task_map_set_string(vm, -1, "wait", p2_task_wait_name(slot->wait_kind));
    p2_task_map_set_int(vm, -1, "runs", slot->runs);
    p2_task_map_set_int(vm, -1, "wakeups", slot->wakeups);
    p2_task_map_set_string(vm, -1, "last_error", slot->last_error);
    be_pop(vm, 1);
}

static int m_task_list(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    be_newobject(vm, "list");
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        if (state->slots[i].status != P2_TASK_FREE) {
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
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    int active = 0, ready = 0, waiting = 0, paused = 0, events = 0;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        int status = state->slots[i].status;
        if (status != P2_TASK_FREE) ++active;
        if (status == P2_TASK_READY) ++ready;
        if (status == P2_TASK_WAITING) ++waiting;
        if (status == P2_TASK_PAUSED) ++paused;
    }
    for (i = 0; i < P2_TASK_MAX_EVENTS; ++i) {
        if (state->events[i][0]) ++events;
    }
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "backend", "p2_native_cooperative");
    p2_task_map_set_int(vm, -1, "max_tasks", P2_TASK_MAX_TASKS);
    p2_task_map_set_int(vm, -1, "active", active);
    p2_task_map_set_int(vm, -1, "ready", ready);
    p2_task_map_set_int(vm, -1, "waiting", waiting);
    p2_task_map_set_int(vm, -1, "paused", paused);
    p2_task_map_set_int(vm, -1, "events", events);
    p2_task_map_set_int(vm, -1, "current", state->current);
    p2_task_map_set_bool(vm, -1, "uses_p2_counter", 1);
    p2_task_map_set_bool(vm, -1, "uses_cog_attention", 0);
    p2_task_map_set_bool(vm, -1, "preemptive", 0);
    p2_task_map_set_bool(vm, -1, "stackful", 0);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_task_millis(bvm *vm)
{
    be_pushint(vm, p2_task_millis_value(p2_task_millis_now(vm)));
    be_return(vm);
}

static int m_task_woke_by_timeout(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int ok = p2_task_valid(state->current) && state->slots[state->current].woke_timeout;
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static int m_task_woke_by_event(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int ok = 0;
    if (p2_task_valid(state->current) && state->slots[state->current].woke_event[0]) {
        if (be_top(vm) < 1 || be_isnil(vm, 1)) {
            ok = 1;
        } else if (be_isstring(vm, 1) && !strcmp(be_tostring(vm, 1), state->slots[state->current].woke_event)) {
            ok = 1;
        }
    }
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static int m_task_reset(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int i;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_free_slot(vm, i);
    }
    memset(state->events, 0, sizeof(state->events));
    state->current = -1;
    state->next = -1;
    be_pushbool(vm, btrue);
    be_return(vm);
}

static int m_task_reset_result(bvm *vm)
{
    p2_task_state *state = p2_vm_scheduler(vm);
    int active_before = p2_task_active_count(vm);
    int events_before = p2_task_event_count(vm);
    int i;
    for (i = 0; i < P2_TASK_MAX_TASKS; ++i) {
        p2_task_free_slot(vm, i);
    }
    memset(state->events, 0, sizeof(state->events));
    state->current = -1;
    state->next = -1;
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_bool(vm, -1, "reset", 1);
    p2_task_map_set_int(vm, -1, "released_tasks", active_before);
    p2_task_map_set_int(vm, -1, "released_events", events_before);
    p2_task_map_set_int(vm, -1, "active_before", active_before);
    p2_task_map_set_int(vm, -1, "events_before", events_before);
    p2_task_map_set_int(vm, -1, "active_after", p2_task_active_count(vm));
    p2_task_map_set_int(vm, -1, "events_after", p2_task_event_count(vm));
    p2_task_map_set_int(vm, -1, "max_tasks", P2_TASK_MAX_TASKS);
    p2_task_map_set_string(vm, -1, "error", "");
    p2_task_map_set_string(vm, -1, "message", "");
    be_pop(vm, 1);
    be_return(vm);
}

static void p2_task_push_required_capability_keys(bvm *vm)
{
    be_newobject(vm, "list");
    p2_task_list_push_string(vm, -1, "backend");
    p2_task_list_push_string(vm, -1, "cooperative");
    p2_task_list_push_string(vm, -1, "scheduler_policy");
    p2_task_list_push_string(vm, -1, "max_tasks");
    p2_task_list_push_string(vm, -1, "spin2_compatible_names");
    p2_task_list_push_string(vm, -1, "contract");
    p2_task_list_push_string(vm, -1, "contract_value");
    p2_task_list_push_string(vm, -1, "attention_policy");
    p2_task_list_push_string(vm, -1, "attention_policy_value");
    p2_task_list_push_string(vm, -1, "execution_model");
    p2_task_list_push_string(vm, -1, "execution_model_value");
    p2_task_list_push_string(vm, -1, "event_readiness_result");
    p2_task_list_push_string(vm, -1, "primitive_readiness_result");
    p2_task_list_push_string(vm, -1, "primitive_object_waits");
    p2_task_list_push_string(vm, -1, "p2ipc_object_readiness_result");
    p2_task_list_push_string(vm, -1, "p2ipc_object_waits");
    p2_task_list_push_string(vm, -1, "event_inspection");
    p2_task_list_push_string(vm, -1, "native_semaphore");
    p2_task_list_push_string(vm, -1, "native_mutex");
    p2_task_list_push_string(vm, -1, "native_queue");
    p2_task_list_push_string(vm, -1, "native_event_flags");
    p2_task_list_push_string(vm, -1, "native_timer");
    be_pop(vm, 1);
}

static void p2_task_push_capabilities(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "backend", "p2_native_cooperative");
    p2_task_map_set_bool(vm, -1, "cooperative", 1);
    p2_task_map_set_bool(vm, -1, "current_vm", 1);
    p2_task_map_set_bool(vm, -1, "preemptive", 0);
    p2_task_map_set_bool(vm, -1, "stackful", 0);
    p2_task_map_set_bool(vm, -1, "independent_stacks", 0);
    p2_task_map_set_bool(vm, -1, "independent_vm_per_task", 0);
    p2_task_map_set_string(vm, -1, "scheduler_policy", "current_vm_callback_step");
    p2_task_map_set_string(vm, -1, "attention_policy", "native_attention_event_current_vm_only");
    p2_task_map_set_int(vm, -1, "max_tasks", P2_TASK_MAX_TASKS);
    p2_task_map_set_int(vm, -1, "max_events", P2_TASK_MAX_EVENTS);
    p2_task_map_set_bool(vm, -1, "spin2_compatible_names", 1);
    p2_task_map_set_bool(vm, -1, "wait_descriptors", 1);
    p2_task_map_set_bool(vm, -1, "event_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "primitive_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "primitive_object_waits", 1);
    p2_task_map_set_bool(vm, -1, "p2ipc_object_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "p2ipc_object_waits", 1);
    p2_task_map_set_bool(vm, -1, "event_inspection", 1);
    p2_task_map_set_bool(vm, -1, "clear_all_events", 1);
    p2_task_map_set_bool(vm, -1, "native_semaphore", 1);
    p2_task_map_set_bool(vm, -1, "semaphore_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_mutex", 1);
    p2_task_map_set_bool(vm, -1, "mutex_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_queue", 1);
    p2_task_map_set_bool(vm, -1, "queue_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_event_flags", 1);
    p2_task_map_set_bool(vm, -1, "event_flags_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_timer", 1);
    p2_task_map_set_bool(vm, -1, "timer_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "start_result", 1);
    p2_task_map_set_bool(vm, -1, "stop_result", 1);
    p2_task_map_set_bool(vm, -1, "pause_result", 1);
    p2_task_map_set_bool(vm, -1, "resume_result", 1);
    p2_task_map_set_bool(vm, -1, "scheduler_step_result", 1);
    p2_task_map_set_bool(vm, -1, "scheduler_run_result", 1);
    p2_task_map_set_bool(vm, -1, "reset_result", 1);
    p2_task_map_set_bool(vm, -1, "task_lifecycle_result", 1);
    p2_task_map_set_bool(vm, -1, "contract", 1);
    p2_task_map_set_bool(vm, -1, "contract_value", 1);
    p2_task_map_set_bool(vm, -1, "execution_model", 1);
    p2_task_map_set_bool(vm, -1, "execution_model_value", 1);
    p2_task_map_set_bool(vm, -1, "attention_policy_value", 1);
    p2_task_map_set_bool(vm, -1, "audit", 1);
    p2_task_map_set_bool(vm, -1, "bounded_attention_wait", 0);
    p2_task_map_set_bool(vm, -1, "cross_cog_attention_wakeup", 0);
    p2_task_map_set_string(vm, -1, "unsupported_reason", "native task backend is current-VM cooperative only; independent stacks, preemption, cross-cog p2ipc wakeups, and true Spin2/PASM task switching are not implemented");
    be_pop(vm, 1);
}

static void p2_task_push_attention_policy(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_string(vm, -1, "policy", "native_attention_event_current_vm_only");
    p2_task_map_set_string(vm, -1, "event", "attention");
    p2_task_map_set_bool(vm, -1, "signal_uses_cog_attention", 0);
    p2_task_map_set_bool(vm, -1, "poll_uses_cog_attention", 0);
    p2_task_map_set_bool(vm, -1, "bounded_attention_wait", 0);
    p2_task_map_set_string(vm, -1, "wait_helper", "");
    p2_task_map_set_bool(vm, -1, "cross_cog_wakeup", 0);
    p2_task_map_set_bool(vm, -1, "current_vm_only", 1);
    be_pop(vm, 1);
}

static void p2_task_push_contract(bvm *vm)
{
    be_newobject(vm, "map");
    p2_task_map_set_bool(vm, -1, "ok", 1);
    p2_task_map_set_string(vm, -1, "model", "cooperative_step");
    p2_task_map_set_string(vm, -1, "backend", "p2_native_cooperative");
    p2_task_map_set_string(vm, -1, "scheduler_policy", "current_vm_callback_step");
    p2_task_map_set_bool(vm, -1, "current_vm", 1);
    p2_task_map_set_bool(vm, -1, "cooperative", 1);
    p2_task_map_set_bool(vm, -1, "callback_step_scheduler", 1);
    p2_task_map_set_bool(vm, -1, "preemptive", 0);
    p2_task_map_set_bool(vm, -1, "stackful", 0);
    p2_task_map_set_bool(vm, -1, "independent_stacks", 0);
    p2_task_map_set_bool(vm, -1, "independent_vm_per_task", 0);
    p2_task_map_set_bool(vm, -1, "true_spin2_task_switching", 0);
    p2_task_map_set_int(vm, -1, "max_tasks", P2_TASK_MAX_TASKS);
    p2_task_map_set_bool(vm, -1, "spin2_compatible_names", 1);
    p2_task_map_set_bool(vm, -1, "wait_descriptors", 1);
    p2_task_map_set_bool(vm, -1, "event_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "primitive_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "primitive_object_waits", 1);
    p2_task_map_set_bool(vm, -1, "p2ipc_object_readiness_result", 1);
    p2_task_map_set_bool(vm, -1, "p2ipc_object_waits", 1);
    p2_task_map_set_bool(vm, -1, "event_inspection", 1);
    p2_task_map_set_bool(vm, -1, "clear_all_events", 1);
    p2_task_map_set_bool(vm, -1, "native_semaphore", 1);
    p2_task_map_set_bool(vm, -1, "semaphore_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_mutex", 1);
    p2_task_map_set_bool(vm, -1, "mutex_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_queue", 1);
    p2_task_map_set_bool(vm, -1, "queue_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_event_flags", 1);
    p2_task_map_set_bool(vm, -1, "event_flags_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "native_timer", 1);
    p2_task_map_set_bool(vm, -1, "timer_result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "result_diagnostics", 1);
    p2_task_map_set_bool(vm, -1, "reset_result", 1);
    p2_task_map_set_bool(vm, -1, "task_lifecycle_result", 1);
    p2_task_map_set_bool(vm, -1, "scheduler_step_result", 1);
    p2_task_map_set_bool(vm, -1, "scheduler_run_result", 1);
    p2_task_map_set_string(vm, -1, "sharing_policy", "current_vm_objects_only");
    p2_task_map_set_bool(vm, -1, "cross_vm_serialization", 0);
    p2_task_map_set_bool(vm, -1, "cross_cog_wakeup", 0);
    p2_task_map_set_string(vm, -1, "attention_policy", "native_attention_event_current_vm_only");
    p2_task_map_set_bool(vm, -1, "bounded_attention_wait", 0);
    p2_task_map_set_bool(vm, -1, "cross_cog_attention_wakeup", 0);
    p2_task_map_set_string(vm, -1, "unsupported_reason", "native task backend is current-VM cooperative only; independent stacks, preemption, cross-cog p2ipc wakeups, and true Spin2/PASM task switching are not implemented");
    be_pop(vm, 1);
}

static int m_task_capabilities(bvm *vm)
{
    p2_task_push_capabilities(vm);
    be_return(vm);
}

static int m_task_capability(bvm *vm)
{
    const char *name = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : NULL;
    if (!name) {
        be_pushnil(vm);
    } else if (!strcmp(name, "backend")) {
        be_pushstring(vm, "p2_native_cooperative");
    } else if (!strcmp(name, "cooperative") || !strcmp(name, "current_vm") ||
               !strcmp(name, "spin2_compatible_names") || !strcmp(name, "wait_descriptors") ||
               !strcmp(name, "event_readiness_result") || !strcmp(name, "primitive_readiness_result") ||
               !strcmp(name, "primitive_object_waits") ||
               !strcmp(name, "p2ipc_object_readiness_result") || !strcmp(name, "p2ipc_object_waits") ||
               !strcmp(name, "event_inspection") ||
               !strcmp(name, "clear_all_events") || !strcmp(name, "native_semaphore") ||
               !strcmp(name, "semaphore_result_diagnostics") || !strcmp(name, "native_mutex") ||
               !strcmp(name, "mutex_result_diagnostics") || !strcmp(name, "native_queue") ||
               !strcmp(name, "queue_result_diagnostics") || !strcmp(name, "native_event_flags") ||
               !strcmp(name, "event_flags_result_diagnostics") || !strcmp(name, "native_timer") ||
               !strcmp(name, "timer_result_diagnostics") ||
                   !strcmp(name, "contract") || !strcmp(name, "contract_value") ||
                   !strcmp(name, "execution_model") || !strcmp(name, "execution_model_value") ||
                   !strcmp(name, "attention_policy_value") ||
                   !strcmp(name, "audit") || !strcmp(name, "result_diagnostics") ||
               !strcmp(name, "start_result") || !strcmp(name, "stop_result") ||
               !strcmp(name, "pause_result") || !strcmp(name, "resume_result") ||
               !strcmp(name, "scheduler_step_result") || !strcmp(name, "scheduler_run_result") ||
               !strcmp(name, "reset_result") || !strcmp(name, "task_lifecycle_result")) {
        be_pushbool(vm, btrue);
    } else if (!strcmp(name, "preemptive") || !strcmp(name, "stackful") ||
               !strcmp(name, "independent_stacks") || !strcmp(name, "independent_vm_per_task") ||
               !strcmp(name, "bounded_attention_wait") || !strcmp(name, "cross_cog_attention_wakeup")) {
        be_pushbool(vm, bfalse);
    } else if (!strcmp(name, "scheduler_policy")) {
        be_pushstring(vm, "current_vm_callback_step");
    } else if (!strcmp(name, "attention_policy")) {
        be_pushstring(vm, "native_attention_event_current_vm_only");
    } else if (!strcmp(name, "max_tasks")) {
        be_pushint(vm, P2_TASK_MAX_TASKS);
    } else if (!strcmp(name, "max_events")) {
        be_pushint(vm, P2_TASK_MAX_EVENTS);
    } else if (!strcmp(name, "unsupported_reason")) {
        be_pushstring(vm, "native task backend is current-VM cooperative only; independent stacks, preemption, cross-cog p2ipc wakeups, and true Spin2/PASM task switching are not implemented");
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_task_attention_policy(bvm *vm)
{
    p2_task_push_attention_policy(vm);
    be_return(vm);
}

static int m_task_attention_policy_value(bvm *vm)
{
    const char *name = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : NULL;
    if (!name) {
        be_pushnil(vm);
    } else if (!strcmp(name, "policy")) {
        be_pushstring(vm, "native_attention_event_current_vm_only");
    } else if (!strcmp(name, "event")) {
        be_pushstring(vm, "attention");
    } else if (!strcmp(name, "signal_uses_cog_attention") ||
               !strcmp(name, "poll_uses_cog_attention") ||
               !strcmp(name, "bounded_attention_wait") ||
               !strcmp(name, "cross_cog_wakeup")) {
        be_pushbool(vm, bfalse);
    } else if (!strcmp(name, "wait_helper")) {
        be_pushstring(vm, "");
    } else if (!strcmp(name, "current_vm_only")) {
        be_pushbool(vm, btrue);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_task_contract(bvm *vm)
{
    p2_task_push_contract(vm);
    be_return(vm);
}

static int m_task_contract_value(bvm *vm)
{
    const char *name = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : NULL;
    if (!name) {
        be_pushnil(vm);
    } else if (!strcmp(name, "model")) {
        be_pushstring(vm, "cooperative_step");
    } else if (!strcmp(name, "backend")) {
        be_pushstring(vm, "p2_native_cooperative");
    } else if (!strcmp(name, "scheduler_policy")) {
        be_pushstring(vm, "current_vm_callback_step");
    } else if (!strcmp(name, "sharing_policy")) {
        be_pushstring(vm, "current_vm_objects_only");
    } else if (!strcmp(name, "attention_policy")) {
        be_pushstring(vm, "native_attention_event_current_vm_only");
    } else if (!strcmp(name, "unsupported_reason")) {
        be_pushstring(vm, "native task backend is current-VM cooperative only; independent stacks, preemption, cross-cog p2ipc wakeups, and true Spin2/PASM task switching are not implemented");
    } else if (!strcmp(name, "max_tasks")) {
        be_pushint(vm, P2_TASK_MAX_TASKS);
    } else if (!strcmp(name, "ok") || !strcmp(name, "current_vm") ||
               !strcmp(name, "cooperative") || !strcmp(name, "callback_step_scheduler") ||
               !strcmp(name, "spin2_compatible_names") || !strcmp(name, "wait_descriptors") ||
               !strcmp(name, "event_readiness_result") || !strcmp(name, "primitive_readiness_result") ||
               !strcmp(name, "primitive_object_waits") || !strcmp(name, "p2ipc_object_readiness_result") ||
               !strcmp(name, "p2ipc_object_waits") || !strcmp(name, "event_inspection") ||
               !strcmp(name, "clear_all_events") || !strcmp(name, "native_semaphore") ||
               !strcmp(name, "semaphore_result_diagnostics") || !strcmp(name, "native_mutex") ||
               !strcmp(name, "mutex_result_diagnostics") || !strcmp(name, "native_queue") ||
               !strcmp(name, "queue_result_diagnostics") || !strcmp(name, "native_event_flags") ||
               !strcmp(name, "event_flags_result_diagnostics") || !strcmp(name, "native_timer") ||
               !strcmp(name, "timer_result_diagnostics") || !strcmp(name, "result_diagnostics") ||
               !strcmp(name, "reset_result") || !strcmp(name, "task_lifecycle_result") ||
               !strcmp(name, "scheduler_step_result") || !strcmp(name, "scheduler_run_result")) {
        be_pushbool(vm, btrue);
    } else if (!strcmp(name, "preemptive") || !strcmp(name, "stackful") ||
               !strcmp(name, "independent_stacks") || !strcmp(name, "independent_vm_per_task") ||
               !strcmp(name, "true_spin2_task_switching") || !strcmp(name, "cross_vm_serialization") ||
               !strcmp(name, "cross_cog_wakeup") || !strcmp(name, "bounded_attention_wait") ||
               !strcmp(name, "cross_cog_attention_wakeup")) {
        be_pushbool(vm, bfalse);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_task_execution_model(bvm *vm)
{
    p2_task_push_contract(vm);
    be_return(vm);
}

static int m_task_execution_model_value(bvm *vm)
{
    const char *name = be_top(vm) >= 1 && be_isstring(vm, 1) ? be_tostring(vm, 1) : NULL;
    if (!name) {
        be_pushnil(vm);
    } else if (!strcmp(name, "model")) {
        be_pushstring(vm, "cooperative_step");
    } else if (!strcmp(name, "backend")) {
        be_pushstring(vm, "p2_native_cooperative");
    } else if (!strcmp(name, "scheduler_policy")) {
        be_pushstring(vm, "current_vm_callback_step");
    } else if (!strcmp(name, "unsupported_reason")) {
        be_pushstring(vm, "native task backend is current-VM cooperative only; independent stacks, preemption, cross-cog p2ipc wakeups, and true Spin2/PASM task switching are not implemented");
    } else if (!strcmp(name, "max_tasks")) {
        be_pushint(vm, P2_TASK_MAX_TASKS);
    } else if (!strcmp(name, "ok") || !strcmp(name, "current_vm") ||
               !strcmp(name, "cooperative") || !strcmp(name, "callback_step_scheduler") ||
               !strcmp(name, "spin2_compatible_names") || !strcmp(name, "wait_descriptors") ||
               !strcmp(name, "event_readiness_result") || !strcmp(name, "primitive_readiness_result") ||
               !strcmp(name, "primitive_object_waits") || !strcmp(name, "p2ipc_object_readiness_result") ||
               !strcmp(name, "p2ipc_object_waits") || !strcmp(name, "event_inspection") ||
               !strcmp(name, "clear_all_events") || !strcmp(name, "native_semaphore") ||
               !strcmp(name, "semaphore_result_diagnostics") || !strcmp(name, "native_mutex") ||
               !strcmp(name, "mutex_result_diagnostics") || !strcmp(name, "native_queue") ||
               !strcmp(name, "queue_result_diagnostics") || !strcmp(name, "native_event_flags") ||
               !strcmp(name, "event_flags_result_diagnostics") || !strcmp(name, "native_timer") ||
               !strcmp(name, "timer_result_diagnostics") || !strcmp(name, "result_diagnostics") ||
               !strcmp(name, "reset_result") || !strcmp(name, "task_lifecycle_result") ||
               !strcmp(name, "scheduler_step_result") || !strcmp(name, "scheduler_run_result")) {
        be_pushbool(vm, btrue);
    } else if (!strcmp(name, "preemptive") || !strcmp(name, "stackful") ||
               !strcmp(name, "independent_stacks") || !strcmp(name, "independent_vm_per_task") ||
               !strcmp(name, "true_spin2_task_switching") ||
               !strcmp(name, "bounded_attention_wait") ||
               !strcmp(name, "cross_cog_attention_wakeup")) {
        be_pushbool(vm, bfalse);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_task_required_capability_keys(bvm *vm)
{
    p2_task_push_required_capability_keys(vm);
    be_return(vm);
}

static int m_task_audit_ok(bvm *vm)
{
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
    task_module_set_func(vm, "Semaphore", m_task_semaphore_new);
    task_module_set_func(vm, "Mutex", m_task_mutex_new);
    task_module_set_func(vm, "Queue", m_task_queue_new);
    task_module_set_func(vm, "EventFlags", m_task_event_flags_new);
    task_module_set_func(vm, "Timer", m_task_timer_new);
    task_module_set_str(vm, "again", "__task_again__");
    task_module_set_str(vm, "done", "__task_done__");
    task_module_set_str(vm, "paused", "__task_pause__");
    task_module_set_func(vm, "start", m_task_start);
    task_module_set_func(vm, "start_result", m_task_start_result);
    task_module_set_func(vm, "spin", m_task_spin);
    task_module_set_func(vm, "sleep", m_task_sleep);
    task_module_set_func(vm, "wait", m_task_wait);
    task_module_set_func(vm, "signal", m_task_signal);
    task_module_set_func(vm, "clear", m_task_clear);
    task_module_set_func(vm, "clear_all", m_task_clear_all);
    task_module_set_func(vm, "events", m_task_events);
    task_module_set_func(vm, "ready_result", m_task_ready_result);
    task_module_set_func(vm, "next", m_task_next);
    task_module_set_func(vm, "next_result", m_task_next_result);
    task_module_set_func(vm, "run", m_task_run);
    task_module_set_func(vm, "run_result", m_task_run_result);
    task_module_set_func(vm, "stop", m_task_stop);
    task_module_set_func(vm, "stop_result", m_task_stop_result);
    task_module_set_func(vm, "pause", m_task_pause);
    task_module_set_func(vm, "pause_result", m_task_pause_result);
    task_module_set_func(vm, "halt", m_task_pause);
    task_module_set_func(vm, "hlt", m_task_pause);
    task_module_set_func(vm, "resume", m_task_resume);
    task_module_set_func(vm, "resume_result", m_task_resume_result);
    task_module_set_func(vm, "cont", m_task_resume);
    task_module_set_func(vm, "chk", m_task_chk);
    task_module_set_func(vm, "status", m_task_status);
    task_module_set_func(vm, "current", m_task_current);
    task_module_set_func(vm, "id", m_task_id);
    task_module_set_func(vm, "lifecycle_result", m_task_lifecycle_result);
    task_module_set_func(vm, "list", m_task_list);
    task_module_set_func(vm, "info", m_task_info);
    task_module_set_func(vm, "millis", m_task_millis);
    task_module_set_func(vm, "woke_by_timeout", m_task_woke_by_timeout);
    task_module_set_func(vm, "woke_by_event", m_task_woke_by_event);
    task_module_set_func(vm, "reset", m_task_reset);
    task_module_set_func(vm, "reset_result", m_task_reset_result);
    task_module_set_func(vm, "capabilities", m_task_capabilities);
    task_module_set_func(vm, "capability", m_task_capability);
    task_module_set_func(vm, "attention_policy", m_task_attention_policy);
    task_module_set_func(vm, "attention_policy_value", m_task_attention_policy_value);
    task_module_set_func(vm, "contract", m_task_contract);
    task_module_set_func(vm, "contract_value", m_task_contract_value);
    task_module_set_func(vm, "execution_model", m_task_execution_model);
    task_module_set_func(vm, "execution_model_value", m_task_execution_model_value);
    task_module_set_func(vm, "required_capability_keys", m_task_required_capability_keys);
    task_module_set_func(vm, "audit_ok", m_task_audit_ok);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}

be_native_module_attr_table(task) {
    be_native_module_int("MAX_TASKS", P2_TASK_MAX_TASKS),
    be_native_module_int("MAX_EVENTS", P2_TASK_MAX_EVENTS),
    be_native_module_int("MAX_TIMERS", 16),
    be_native_module_int("MAX_QUEUE_DEPTH", 8),
    be_native_module_function("Semaphore", m_task_semaphore_new),
    be_native_module_function("Mutex", m_task_mutex_new),
    be_native_module_function("Queue", m_task_queue_new),
    be_native_module_function("EventFlags", m_task_event_flags_new),
    be_native_module_function("Timer", m_task_timer_new),
    be_native_module_str("again", "__task_again__"),
    be_native_module_str("done", "__task_done__"),
    be_native_module_str("paused", "__task_pause__"),
    be_native_module_function("start", m_task_start),
    be_native_module_function("start_result", m_task_start_result),
    be_native_module_function("spin", m_task_spin),
    be_native_module_function("sleep", m_task_sleep),
    be_native_module_function("wait", m_task_wait),
    be_native_module_function("signal", m_task_signal),
    be_native_module_function("clear", m_task_clear),
    be_native_module_function("clear_all", m_task_clear_all),
    be_native_module_function("events", m_task_events),
    be_native_module_function("ready_result", m_task_ready_result),
    be_native_module_function("next", m_task_next),
    be_native_module_function("next_result", m_task_next_result),
    be_native_module_function("run", m_task_run),
    be_native_module_function("run_result", m_task_run_result),
    be_native_module_function("stop", m_task_stop),
    be_native_module_function("stop_result", m_task_stop_result),
    be_native_module_function("pause", m_task_pause),
    be_native_module_function("pause_result", m_task_pause_result),
    be_native_module_function("halt", m_task_pause),
    be_native_module_function("hlt", m_task_pause),
    be_native_module_function("resume", m_task_resume),
    be_native_module_function("resume_result", m_task_resume_result),
    be_native_module_function("cont", m_task_resume),
    be_native_module_function("chk", m_task_chk),
    be_native_module_function("status", m_task_status),
    be_native_module_function("current", m_task_current),
    be_native_module_function("id", m_task_id),
    be_native_module_function("lifecycle_result", m_task_lifecycle_result),
    be_native_module_function("list", m_task_list),
    be_native_module_function("info", m_task_info),
    be_native_module_function("millis", m_task_millis),
    be_native_module_function("woke_by_timeout", m_task_woke_by_timeout),
    be_native_module_function("woke_by_event", m_task_woke_by_event),
    be_native_module_function("reset", m_task_reset),
    be_native_module_function("reset_result", m_task_reset_result),
    be_native_module_function("capabilities", m_task_capabilities),
    be_native_module_function("capability", m_task_capability),
        be_native_module_function("attention_policy", m_task_attention_policy),
        be_native_module_function("attention_policy_value", m_task_attention_policy_value),
        be_native_module_function("contract", m_task_contract),
        be_native_module_function("contract_value", m_task_contract_value),
        be_native_module_function("execution_model", m_task_execution_model),
        be_native_module_function("execution_model_value", m_task_execution_model_value),
        be_native_module_function("required_capability_keys", m_task_required_capability_keys),
    be_native_module_function("audit_ok", m_task_audit_ok),
};

be_define_native_module(task, NULL);
