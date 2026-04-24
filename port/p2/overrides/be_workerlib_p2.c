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
    BERRY_WORKER_STACK_BYTES = 4096,
    BERRY_WORKER_START_TIMEOUT_MS = 3000
};

static berry_worker_mailbox g_worker_mailbox;
static berry_worker_boot g_worker_boot;
static unsigned char g_worker_stack[BERRY_WORKER_STACK_BYTES];
static int g_worker_started;
static int g_worker_cog = -1;

static const char g_worker_script[] =
    "def noop(value)\n"
    "    return value\n"
    "end\n"
    "\n"
    "def blink(pin, delay_ms)\n"
    "    prop2_smartpin_clear(pin)\n"
    "    prop2_pin_output(pin)\n"
    "    while true\n"
    "        prop2_pin_high(pin)\n"
    "        prop2_sleep_ms(delay_ms)\n"
    "        prop2_pin_low(pin)\n"
    "        prop2_sleep_ms(delay_ms)\n"
    "    end\n"
    "end\n";

static void worker_set_error(berry_worker_mailbox *mailbox, const char *message)
{
    if (!message) {
        message = "worker error";
    }
    strncpy(mailbox->error, message, BERRY_WORKER_ERROR_MAX - 1);
    mailbox->error[BERRY_WORKER_ERROR_MAX - 1] = '\0';
}

static const char *worker_state_name(int state)
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

static void worker_dispatch(bvm *vm, berry_worker_mailbox *mailbox)
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
    int waited = 0;
    int cog;

    if (g_worker_started) {
        be_pushint(vm, (bint)g_worker_cog);
        be_return(vm);
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
    cog = _cogstart_C(worker_entry, &g_worker_boot, g_worker_stack, sizeof(g_worker_stack));
    if (cog < 0) {
        be_raise(vm, "runtime_error", "failed to start worker cog");
    }
    g_worker_cog = cog;
    g_worker_started = 1;

    while (g_worker_mailbox.state == BERRY_WORKER_STOPPED ||
           g_worker_mailbox.state == BERRY_WORKER_BOOTING) {
        if (waited >= BERRY_WORKER_START_TIMEOUT_MS) {
            be_raise(vm, "runtime_error", "worker start timed out");
        }
        _waitms(1);
        ++waited;
    }
    if (g_worker_mailbox.state == BERRY_WORKER_ERROR) {
        be_raise(vm, "runtime_error", g_worker_mailbox.error);
    }

    be_pushint(vm, (bint)cog);
    be_return(vm);
}

static int m_worker_exec(bvm *vm)
{
    const char *name;
    size_t len;
    int argc;
    int i;

    worker_require_started(vm);
    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "function name must be a string");
    }
    if (g_worker_mailbox.state != BERRY_WORKER_READY) {
        be_raise(vm, "runtime_error", "worker is not ready");
    }

    name = be_tostring(vm, 1);
    len = strlen(name);
    if (len == 0 || len > BERRY_WORKER_NAME_MAX) {
        be_raise(vm, "value_error", "function name is too long");
    }
    argc = be_top(vm) - 1;
    if (argc > BERRY_WORKER_ARGS_MAX) {
        be_raise(vm, "value_error", "too many worker arguments");
    }

    for (i = 0; i < argc; ++i) {
        if (!be_isint(vm, i + 2)) {
            be_raise(vm, "type_error", "worker arguments must be integers");
        }
    }

    memset((void *)&g_worker_mailbox, 0, sizeof(g_worker_mailbox));
    memcpy(g_worker_mailbox.name, name, len + 1);
    g_worker_mailbox.argc = argc;
    for (i = 0; i < argc; ++i) {
        g_worker_mailbox.argv[i] = (int)be_toint(vm, i + 2);
    }
    g_worker_mailbox.state = BERRY_WORKER_REQUEST;

    be_return_nil(vm);
}

static int m_worker_state(bvm *vm)
{
    be_pushstring(vm, worker_state_name(g_worker_mailbox.state));
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

be_native_module_attr_table(worker) {
    be_native_module_function("start", m_worker_start),
    be_native_module_function("exec", m_worker_exec),
    be_native_module_function("state", m_worker_state),
    be_native_module_function("error", m_worker_error)
};

be_define_native_module(worker, NULL);
