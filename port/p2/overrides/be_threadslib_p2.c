/********************************************************************
** Small Propeller 2 thread/channel helper module for Berry.
** v1 intentionally keeps execution name-based and data integer/string-only.
********************************************************************/
#include "berry.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_worker.h"

#include <propeller2.h>
#include <stdio.h>
#include <string.h>

enum {
    THREADS_CHANNEL_MAX = 8,
    THREADS_NAME_MAX = 31,
    THREADS_QUEUE_MAX = 8,
    THREADS_TEXT_MAX = 63,
    THREADS_KV_MAX = 16
};

typedef enum threads_value_type {
    THREADS_VALUE_EMPTY = 0,
    THREADS_VALUE_INT = 1,
    THREADS_VALUE_STRING = 2
} threads_value_type;

typedef struct threads_value {
    threads_value_type type;
    int ivalue;
    char svalue[THREADS_TEXT_MAX + 1];
} threads_value;

typedef struct threads_channel {
    int used;
    char name[THREADS_NAME_MAX + 1];
    threads_value queue[THREADS_QUEUE_MAX];
    int head;
    int tail;
    int count;
} threads_channel;

typedef struct threads_kv {
    int used;
    char key[THREADS_NAME_MAX + 1];
    threads_value value;
} threads_kv;

static threads_channel g_channels[THREADS_CHANNEL_MAX];
static threads_kv g_kv[THREADS_KV_MAX];
static int g_threads_lock = -2;
static int g_requested_workers;

static void threads_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static bint threads_require_int(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    return be_toint(vm, index);
}

static const char *threads_require_name(bvm *vm, int index, const char *what)
{
    const char *name;
    size_t len;

    if (be_top(vm) < index || !be_isstring(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    name = be_tostring(vm, index);
    len = strlen(name);
    if (len == 0 || len > THREADS_NAME_MAX) {
        be_raise(vm, "value_error", "name is empty or too long");
    }
    return name;
}

static void threads_init_lock(void)
{
    if (g_threads_lock == -2) {
        g_threads_lock = _locknew();
    }
}

static void threads_lock(void)
{
    threads_init_lock();
    if (g_threads_lock < 0) {
        return;
    }
    while (!_locktry(g_threads_lock)) {
        _waitms(1);
    }
}

static void threads_unlock(void)
{
    if (g_threads_lock >= 0) {
        _lockrel(g_threads_lock);
    }
}

static int threads_find_channel(const char *name)
{
    int i;

    for (i = 0; i < THREADS_CHANNEL_MAX; ++i) {
        if (g_channels[i].used && strcmp(g_channels[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

static int threads_find_or_create_channel(const char *name)
{
    int i = threads_find_channel(name);

    if (i >= 0) {
        return i;
    }
    for (i = 0; i < THREADS_CHANNEL_MAX; ++i) {
        if (!g_channels[i].used) {
            memset(&g_channels[i], 0, sizeof(g_channels[i]));
            g_channels[i].used = 1;
            strncpy(g_channels[i].name, name, THREADS_NAME_MAX);
            g_channels[i].name[THREADS_NAME_MAX] = '\0';
            return i;
        }
    }
    return -1;
}

static void threads_read_value(bvm *vm, int index, threads_value *value)
{
    size_t len;

    memset(value, 0, sizeof(*value));
    if (be_isint(vm, index)) {
        value->type = THREADS_VALUE_INT;
        value->ivalue = (int)be_toint(vm, index);
        return;
    }
    if (be_isstring(vm, index)) {
        const char *text = be_tostring(vm, index);
        len = strlen(text);
        if (len > THREADS_TEXT_MAX) {
            be_raise(vm, "value_error", "channel string is too long");
        }
        value->type = THREADS_VALUE_STRING;
        memcpy(value->svalue, text, len + 1);
        return;
    }
    be_raise(vm, "type_error", "value must be an int or string");
}

static void threads_push_value(bvm *vm, const threads_value *value)
{
    switch (value->type) {
    case THREADS_VALUE_INT:
        be_pushint(vm, (bint)value->ivalue);
        break;
    case THREADS_VALUE_STRING:
        be_pushstring(vm, value->svalue);
        break;
    default:
        be_pushnil(vm);
        break;
    }
}

static int m_threads_workers(bvm *vm)
{
    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        bint requested = threads_require_int(vm, 1, "worker count must be an int");
        const char *error = NULL;

        if (requested < 0 || requested > 7) {
            be_raise(vm, "value_error", "worker count must be between 0 and 7");
        }
        g_requested_workers = (int)requested;
        if (requested > 0 && berry_worker_start_cog(&error) < 0) {
            be_raise(vm, "runtime_error", error ? error : "failed to start worker");
        }
    }
    be_pushint(vm, g_requested_workers > 0 && berry_worker_cog_id() >= 0 ? 1 : 0);
    be_return(vm);
}

static int m_threads_channel(bvm *vm)
{
    const char *name = threads_require_name(vm, 1, "channel name must be a string");
    int index;

    threads_lock();
    index = threads_find_or_create_channel(name);
    threads_unlock();
    if (index < 0) {
        be_raise(vm, "runtime_error", "no channel slots available");
    }

    be_pushstring(vm, name);
    be_return(vm);
}

static int m_threads_put(bvm *vm)
{
    const char *name = threads_require_name(vm, 1, "channel name must be a string");
    threads_value value;
    int index;
    int ok = 0;

    if (be_top(vm) < 2) {
        be_raise(vm, "type_error", "value is required");
    }
    threads_read_value(vm, 2, &value);

    threads_lock();
    index = threads_find_or_create_channel(name);
    if (index >= 0 && g_channels[index].count < THREADS_QUEUE_MAX) {
        g_channels[index].queue[g_channels[index].tail] = value;
        g_channels[index].tail = (g_channels[index].tail + 1) % THREADS_QUEUE_MAX;
        ++g_channels[index].count;
        ok = 1;
    }
    threads_unlock();

    if (index < 0) {
        be_raise(vm, "runtime_error", "no channel slots available");
    }
    if (!ok) {
        be_raise(vm, "runtime_error", "channel is full");
    }
    be_pushbool(vm, 1);
    be_return(vm);
}

static int m_threads_get(bvm *vm)
{
    const char *name = threads_require_name(vm, 1, "channel name must be a string");
    bint timeout_ms = 0;
    bint waited = 0;
    threads_value value;
    int found = 0;

    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        timeout_ms = threads_require_int(vm, 2, "timeout_ms must be an int");
        if (timeout_ms < 0) {
            be_raise(vm, "value_error", "timeout_ms must be >= 0");
        }
    }

    memset(&value, 0, sizeof(value));
    do {
        int index;

        threads_lock();
        index = threads_find_channel(name);
        if (index >= 0 && g_channels[index].count > 0) {
            value = g_channels[index].queue[g_channels[index].head];
            memset(&g_channels[index].queue[g_channels[index].head], 0, sizeof(threads_value));
            g_channels[index].head = (g_channels[index].head + 1) % THREADS_QUEUE_MAX;
            --g_channels[index].count;
            found = 1;
        }
        threads_unlock();

        if (found || waited >= timeout_ms) {
            break;
        }
        _waitms(1);
        ++waited;
    } while (1);

    if (found) {
        threads_push_value(vm, &value);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_threads_output(bvm *vm)
{
    const char *text;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "output value must be a string");
    }
    text = be_tostring(vm, 1);
    printf("%s", text);
    be_return_nil(vm);
}

static int m_threads_msleep(bvm *vm)
{
    bint ms = threads_require_int(vm, 1, "ms must be an int");
    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }
    _waitms((uint32_t)ms);
    be_return_nil(vm);
}

static int threads_find_kv(const char *key)
{
    int i;

    for (i = 0; i < THREADS_KV_MAX; ++i) {
        if (g_kv[i].used && strcmp(g_kv[i].key, key) == 0) {
            return i;
        }
    }
    return -1;
}

static int threads_find_or_create_kv(const char *key)
{
    int i = threads_find_kv(key);

    if (i >= 0) {
        return i;
    }
    for (i = 0; i < THREADS_KV_MAX; ++i) {
        if (!g_kv[i].used) {
            memset(&g_kv[i], 0, sizeof(g_kv[i]));
            g_kv[i].used = 1;
            strncpy(g_kv[i].key, key, THREADS_NAME_MAX);
            g_kv[i].key[THREADS_NAME_MAX] = '\0';
            return i;
        }
    }
    return -1;
}

static int m_threads_update(bvm *vm)
{
    const char *key = threads_require_name(vm, 1, "key must be a string");
    threads_value value;
    int index;

    if (be_top(vm) < 2) {
        be_raise(vm, "type_error", "value is required");
    }
    threads_read_value(vm, 2, &value);

    threads_lock();
    index = threads_find_or_create_kv(key);
    if (index >= 0) {
        g_kv[index].value = value;
    }
    threads_unlock();

    if (index < 0) {
        be_raise(vm, "runtime_error", "no shared-data slots available");
    }
    be_return_nil(vm);
}

static int m_threads_value(bvm *vm)
{
    const char *key = threads_require_name(vm, 1, "key must be a string");
    threads_value value;
    int found = 0;
    int index;

    memset(&value, 0, sizeof(value));
    threads_lock();
    index = threads_find_kv(key);
    if (index >= 0) {
        value = g_kv[index].value;
        found = 1;
    }
    threads_unlock();

    if (found) {
        threads_push_value(vm, &value);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_threads_new(bvm *vm)
{
    const char *name = threads_require_name(vm, 1, "function name must be a string");
    int argc = be_top(vm) - 1;
    int argv[BERRY_WORKER_ARGS_MAX];
    int i;
    const char *error = NULL;
    int cog;

    if (argc > BERRY_WORKER_ARGS_MAX) {
        be_raise(vm, "value_error", "too many thread arguments");
    }
    for (i = 0; i < argc; ++i) {
        argv[i] = (int)threads_require_int(vm, i + 2, "thread args must be ints");
    }

    cog = berry_worker_start_cog(&error);
    if (cog < 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start worker");
    }
    if (berry_worker_exec_ints(name, argc, argv, &error) != 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to launch worker job");
    }

    be_pushint(vm, (bint)cog);
    be_return(vm);
}

static int m_threads_member(bvm *vm)
{
    const char *name = be_tostring(vm, 1);

    if (!strcmp(name, "workers")) be_pushntvfunction(vm, m_threads_workers);
    else if (!strcmp(name, "channel")) be_pushntvfunction(vm, m_threads_channel);
    else if (!strcmp(name, "put")) be_pushntvfunction(vm, m_threads_put);
    else if (!strcmp(name, "get")) be_pushntvfunction(vm, m_threads_get);
    else if (!strcmp(name, "output")) be_pushntvfunction(vm, m_threads_output);
    else if (!strcmp(name, "msleep")) be_pushntvfunction(vm, m_threads_msleep);
    else if (!strcmp(name, "update")) be_pushntvfunction(vm, m_threads_update);
    else if (!strcmp(name, "value")) be_pushntvfunction(vm, m_threads_value);
    else if (!strcmp(name, "new")) be_pushntvfunction(vm, m_threads_new);
    else be_pushnil(vm);
    be_return(vm);
}

void be_cache_threadsmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "threads");

    be_newmodule(vm);
    threads_module_set_func(vm, "member", m_threads_member);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
