/********************************************************************
** Propeller 2 Berry worker module.
********************************************************************/
#include "berry.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_worker.h"
#include "p2_heap.h"

#include <cog.h>
#include <propeller2.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

enum {
    BERRY_WORKER_STACK_BYTES = 16 * 1024,
    BERRY_WORKER_START_TIMEOUT_MS = 3000
};

static berry_worker_mailbox g_worker_mailbox;
static berry_worker_boot g_worker_boot;
static union {
    unsigned char raw[BERRY_WORKER_STACK_BYTES];
    uint64_t align;
} g_worker_stack;
static int g_worker_started;
static int g_worker_cog = -1;

static const char g_worker_script[] =
    "import p2\n"
    "import rtos\n"
    "\n";

static void worker_set_error(berry_worker_mailbox *mailbox, const char *message)
{
    if (!message) {
        message = "worker error";
    }
    strncpy(mailbox->error, message, BERRY_WORKER_ERROR_MAX - 1);
    mailbox->error[BERRY_WORKER_ERROR_MAX - 1] = '\0';
}

static void worker_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

const char *berry_worker_state_name(int state)
{
    switch (state) {
    case BERRY_WORKER_STOPPED:
        return "stopped";
    case BERRY_WORKER_BOOTING:
        return "booting";
    case BERRY_WORKER_READY:
        return "ready";
    case BERRY_WORKER_REQUEST:
        return "request";
    case BERRY_WORKER_RUNNING:
        return "running";
    case BERRY_WORKER_ERROR:
        return "error";
    default:
        return "unknown";
    }
}

static void worker_capture_exception(bvm *vm, berry_worker_mailbox *mailbox)
{
    const char *msg = NULL;
    if (be_top(vm) >= 2 && be_isstring(vm, -1)) {
        msg = be_tostring(vm, -1);
    }
    if (!msg && be_top(vm) >= 2 && be_isstring(vm, -2)) {
        msg = be_tostring(vm, -2);
    }
    worker_set_error(mailbox, msg);
    if (be_top(vm) >= 2) {
        be_pop(vm, 2);
    }
}

static int worker_load_script(bvm *vm, berry_worker_mailbox *mailbox)
{
    int res = be_dostring(vm, g_worker_script);
    if (res != BE_OK) {
        worker_capture_exception(vm, mailbox);
        return res;
    }
    be_pop(vm, be_top(vm));
    return BE_OK;
}

static void worker_load_user_source(bvm *vm, berry_worker_mailbox *mailbox)
{
    int res;

    mailbox->state = BERRY_WORKER_RUNNING;
    mailbox->error[0] = '\0';
    res = be_dostring(vm, mailbox->source);
    if (res != BE_OK) {
        worker_capture_exception(vm, mailbox);
        mailbox->state = BERRY_WORKER_ERROR;
        return;
    }
    be_pop(vm, be_top(vm));
    mailbox->state = BERRY_WORKER_READY;
}

static void worker_load_user_file(bvm *vm, berry_worker_mailbox *mailbox)
{
    int res;

    mailbox->state = BERRY_WORKER_RUNNING;
    mailbox->error[0] = '\0';
    res = be_loadfile(vm, mailbox->source);
    if (res == BE_OK) {
        res = be_pcall(vm, 0);
    }
    if (res != BE_OK) {
        worker_capture_exception(vm, mailbox);
        mailbox->state = BERRY_WORKER_ERROR;
        return;
    }
    be_pop(vm, be_top(vm));
    mailbox->state = BERRY_WORKER_READY;
}

static void worker_exec_function(bvm *vm, berry_worker_mailbox *mailbox)
{
    int i;
    int res;

    mailbox->state = BERRY_WORKER_RUNNING;
    mailbox->error[0] = '\0';

    if (!be_getglobal(vm, mailbox->name)) {
        be_pop(vm, 1);
        worker_set_error(mailbox, "worker function not found");
        mailbox->state = BERRY_WORKER_ERROR;
        return;
    }

    for (i = 0; i < mailbox->argc; ++i) {
        be_pushint(vm, (bint)mailbox->argv[i]);
    }

    res = be_pcall(vm, mailbox->argc);
    if (res != BE_OK) {
        worker_capture_exception(vm, mailbox);
        mailbox->state = BERRY_WORKER_ERROR;
        return;
    }

    if (be_top(vm) > 0) {
        be_pop(vm, 1);
    }
    mailbox->state = BERRY_WORKER_READY;
}

static void worker_dispatch(bvm *vm, berry_worker_mailbox *mailbox)
{
    int command = mailbox->command;

    mailbox->command = BERRY_WORKER_CMD_NONE;
    if (command == BERRY_WORKER_CMD_LOAD_STR) {
        worker_load_user_source(vm, mailbox);
    } else if (command == BERRY_WORKER_CMD_LOAD_FILE) {
        worker_load_user_file(vm, mailbox);
    } else if (command == BERRY_WORKER_CMD_EXEC) {
        worker_exec_function(vm, mailbox);
    } else {
        worker_set_error(mailbox, "unknown worker command");
        mailbox->state = BERRY_WORKER_ERROR;
    }
}

static void worker_entry(void *arg)
{
    berry_worker_boot *boot = (berry_worker_boot *)arg;
    berry_worker_mailbox *mailbox = boot->mailbox;
    bvm *vm;

    boot->worker_cog = _cogid();
    p2_heap_set_worker_cog((int)boot->worker_cog);
    mailbox->state = BERRY_WORKER_BOOTING;
    mailbox->error[0] = '\0';

    vm = be_vm_new();
    if (!vm) {
        worker_set_error(mailbox, "failed to create worker VM");
        mailbox->state = BERRY_WORKER_ERROR;
        for (;;) {
            _waitms(1000);
        }
    }

    if (worker_load_script(vm, mailbox) != BE_OK) {
        mailbox->state = BERRY_WORKER_ERROR;
        for (;;) {
            _waitms(1000);
        }
    }

    mailbox->state = BERRY_WORKER_READY;
    for (;;) {
        if (mailbox->state == BERRY_WORKER_REQUEST) {
            worker_dispatch(vm, mailbox);
        }
        _waitms(1);
    }
}

int berry_worker_start_cog(const char **error)
{
    int waited = 0;
    int cog;

    if (error) {
        *error = NULL;
    }
    if (g_worker_started) {
        return g_worker_cog;
    }

    memset(&g_worker_mailbox, 0, sizeof(g_worker_mailbox));
    memset(&g_worker_boot, 0, sizeof(g_worker_boot));
    g_worker_mailbox.state = BERRY_WORKER_STOPPED;
    g_worker_boot.mailbox = &g_worker_mailbox;
    g_worker_boot.heap_base = p2_heap_worker_base();
    g_worker_boot.heap_size = p2_heap_worker_size();
    g_worker_boot.worker_cog = -1;

    /* Catalina's C cog launcher uses SETQ + COGINIT internally and passes
     * the boot pointer in the new cog's PTRA. */
    cog = _cogstart_C(worker_entry, &g_worker_boot, g_worker_stack.raw, sizeof(g_worker_stack.raw));
    if (cog < 0) {
        if (error) {
            *error = "failed to start worker cog";
        }
        return -1;
    }
    g_worker_cog = cog;
    g_worker_started = 1;

    while (g_worker_mailbox.state == BERRY_WORKER_STOPPED ||
           g_worker_mailbox.state == BERRY_WORKER_BOOTING) {
        if (waited >= BERRY_WORKER_START_TIMEOUT_MS) {
            if (error) {
                *error = "worker start timed out";
            }
            return -1;
        }
        _waitms(1);
        ++waited;
    }
    if (g_worker_mailbox.state == BERRY_WORKER_ERROR) {
        if (error) {
            *error = g_worker_mailbox.error;
        }
        return -1;
    }

    return cog;
}

int berry_worker_exec_ints(const char *name, int argc, const int *argv, const char **error)
{
    size_t len;
    int i;

    if (error) {
        *error = NULL;
    }
    if (!g_worker_started || g_worker_cog < 0) {
        if (error) {
            *error = "worker has not been started";
        }
        return -1;
    }
    if (g_worker_mailbox.state != BERRY_WORKER_READY) {
        if (error) {
            *error = "worker is not ready";
        }
        return -1;
    }
    if (!name) {
        if (error) {
            *error = "function name is required";
        }
        return -1;
    }

    len = strlen(name);
    if (len == 0 || len > BERRY_WORKER_NAME_MAX) {
        if (error) {
            *error = "function name is too long";
        }
        return -1;
    }
    if (argc < 0 || argc > BERRY_WORKER_ARGS_MAX) {
        if (error) {
            *error = "too many worker arguments";
        }
        return -1;
    }

    memset((void *)&g_worker_mailbox, 0, sizeof(g_worker_mailbox));
    g_worker_mailbox.command = BERRY_WORKER_CMD_EXEC;
    memcpy(g_worker_mailbox.name, name, len + 1);
    g_worker_mailbox.argc = argc;
    for (i = 0; i < argc; ++i) {
        g_worker_mailbox.argv[i] = argv ? argv[i] : 0;
    }
    g_worker_mailbox.state = BERRY_WORKER_REQUEST;
    return 0;
}

static int berry_worker_load_text_command(const char *text, int command, const char *what, const char **error)
{
    size_t len;
    int waited = 0;

    if (error) {
        *error = NULL;
    }
    if (!g_worker_started || g_worker_cog < 0) {
        if (error) {
            *error = "worker has not been started";
        }
        return -1;
    }
    if (g_worker_mailbox.state != BERRY_WORKER_READY) {
        if (error) {
            *error = "worker is not ready";
        }
        return -1;
    }
    if (!text) {
        if (error) {
            *error = what;
        }
        return -1;
    }
    len = strlen(text);
    if (len == 0 || len > BERRY_WORKER_SOURCE_MAX) {
        if (error) {
            *error = "worker load text is empty or too long";
        }
        return -1;
    }

    memset((void *)&g_worker_mailbox, 0, sizeof(g_worker_mailbox));
    g_worker_mailbox.command = command;
    memcpy(g_worker_mailbox.source, text, len + 1);
    g_worker_mailbox.state = BERRY_WORKER_REQUEST;

    while (g_worker_mailbox.state == BERRY_WORKER_REQUEST ||
           g_worker_mailbox.state == BERRY_WORKER_RUNNING) {
        if (waited >= BERRY_WORKER_START_TIMEOUT_MS) {
            if (error) {
                *error = "worker source load timed out";
            }
            return -1;
        }
        _waitms(1);
        ++waited;
    }
    if (g_worker_mailbox.state == BERRY_WORKER_ERROR) {
        if (error) {
            *error = g_worker_mailbox.error;
        }
        return -1;
    }
    return 0;
}

int berry_worker_load_str(const char *source, const char **error)
{
    return berry_worker_load_text_command(source,
        BERRY_WORKER_CMD_LOAD_STR,
        "source is required",
        error);
}

int berry_worker_load_file(const char *path, const char **error)
{
    return berry_worker_load_text_command(path,
        BERRY_WORKER_CMD_LOAD_FILE,
        "file path is required",
        error);
}

void berry_worker_stop_cog(void)
{
    if (g_worker_started && g_worker_cog >= 0) {
        _cogstop(g_worker_cog);
    }
    g_worker_started = 0;
    g_worker_cog = -1;
    g_worker_boot.worker_cog = -1;
    g_worker_mailbox.state = BERRY_WORKER_STOPPED;
    p2_heap_set_worker_cog(-1);
}

int berry_worker_cog_id(void)
{
    return g_worker_started ? g_worker_cog : -1;
}

int berry_worker_mailbox_state(void)
{
    return g_worker_mailbox.state;
}

const char *berry_worker_last_error(void)
{
    return g_worker_mailbox.error[0] ? g_worker_mailbox.error : NULL;
}

static int worker_require_started(bvm *vm)
{
    if (!g_worker_started || g_worker_cog < 0) {
        be_raise(vm, "runtime_error", "worker has not been started");
        return -1;
    }
    return g_worker_cog;
}

static int m_worker_start(bvm *vm)
{
    int cog;
    const char *error = NULL;

    cog = berry_worker_start_cog(&error);
    if (cog < 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start worker cog");
    }

    be_pushint(vm, (bint)cog);
    be_return(vm);
}

static int m_worker_exec(bvm *vm)
{
    const char *name;
    int argc;
    int argv[BERRY_WORKER_ARGS_MAX];
    int i;
    const char *error = NULL;

    worker_require_started(vm);
    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "function name must be a string");
    }

    name = be_tostring(vm, 1);
    argc = be_top(vm) - 1;
    if (argc > BERRY_WORKER_ARGS_MAX) {
        be_raise(vm, "value_error", "too many worker arguments");
    }

    for (i = 0; i < argc; ++i) {
        if (!be_isint(vm, i + 2)) {
            be_raise(vm, "type_error", "worker arguments must be integers");
        }
        argv[i] = (int)be_toint(vm, i + 2);
    }

    if (berry_worker_exec_ints(name, argc, argv, &error) != 0) {
        be_raise(vm, "runtime_error", error ? error : "worker exec failed");
    }

    be_return_nil(vm);
}

static int m_worker_state(bvm *vm)
{
    be_pushstring(vm, berry_worker_state_name(g_worker_mailbox.state));
    be_return(vm);
}

static int m_worker_error(bvm *vm)
{
    if (g_worker_mailbox.error[0]) {
        be_pushstring(vm, g_worker_mailbox.error);
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int m_worker_stop(bvm *vm)
{
    (void)vm;
    berry_worker_stop_cog();
    be_return_nil(vm);
}

static int m_worker_member(bvm *vm)
{
    const char *name = be_tostring(vm, 1);

    if (!strcmp(name, "start")) be_pushntvfunction(vm, m_worker_start);
    else if (!strcmp(name, "exec")) be_pushntvfunction(vm, m_worker_exec);
    else if (!strcmp(name, "state")) be_pushntvfunction(vm, m_worker_state);
    else if (!strcmp(name, "error")) be_pushntvfunction(vm, m_worker_error);
    else if (!strcmp(name, "stop")) be_pushntvfunction(vm, m_worker_stop);
    else be_pushnil(vm);
    be_return(vm);
}

void be_cache_workermodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "worker");

    be_newmodule(vm);
    worker_module_set_func(vm, "member", m_worker_member);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
