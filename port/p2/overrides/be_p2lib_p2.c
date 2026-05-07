/********************************************************************
** Friendly Propeller 2 native module for Berry.
** This wraps the lower-level prop2_* globals with tutorial-sized names.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_worker.h"
#include "p2_heap.h"

#include <propeller2.h>
#include <stdint.h>
#include <string.h>

enum {
    P2_PINMODE_INPUT = 0,
    P2_PINMODE_OUTPUT = 1,
    P2_PINMODE_OPENDRAIN = 2
};

static void p2_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static bint p2_require_int_arg(bvm *vm, int index, const char *message)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", message);
    }
    return be_toint(vm, index);
}

static int p2_require_pin_arg(bvm *vm, int index)
{
    return berry_p2_bus_require_pin(vm, index, "pin must be an int");
}

static void p2_gpio_clear(int pin)
{
    _wrpin(pin, 0);
    _dirl(pin);
    _wxpin(pin, 0);
    _wypin(pin, 0);
    _akpin(pin);
}

static int m_p2_high(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    _pinh(pin);
    be_return_nil(vm);
}

static int m_p2_low(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    _pinl(pin);
    be_return_nil(vm);
}

static int m_p2_toggle(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    _pinnot(pin);
    be_return_nil(vm);
}

static int m_p2_read(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    be_pushint(vm, (bint)_pinr(pin));
    be_return(vm);
}

static int m_p2_pinmode(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    bint mode = p2_require_int_arg(vm, 2, "mode must be an int");

    p2_gpio_clear(pin);
    switch (mode) {
    case P2_PINMODE_INPUT:
        _dirl(pin);
        break;
    case P2_PINMODE_OUTPUT:
        _dirh(pin);
        break;
    case P2_PINMODE_OPENDRAIN:
        _pinl(pin);
        _dirl(pin);
        break;
    default:
        be_raise(vm, "value_error", "mode must be p2.INPUT, p2.OUTPUT, or p2.OPENDRAIN");
    }
    be_return_nil(vm);
}

static int m_p2_sleep_ms(bvm *vm)
{
    bint ms = p2_require_int_arg(vm, 1, "ms must be an int");
    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }
    _waitms((uint32_t)ms);
    be_return_nil(vm);
}

static int m_p2_delay_us(bvm *vm)
{
    bint us = p2_require_int_arg(vm, 1, "us must be an int");
    if (us < 0) {
        be_raise(vm, "value_error", "us must be >= 0");
    }
    _waitus((uint32_t)us);
    be_return_nil(vm);
}

static int m_p2_cogid(bvm *vm)
{
    be_pushint(vm, (bint)_cogid());
    be_return(vm);
}

static int m_p2_cog_stop(bvm *vm)
{
    bint cog = p2_require_int_arg(vm, 1, "cog_id must be an int");
    if (cog < 0 || cog > 7) {
        be_raise(vm, "value_error", "cog_id must be between 0 and 7");
    }
    _cogstop((int)cog);
    be_return_nil(vm);
}

static int m_p2_cog_start(bvm *vm)
{
    const char *name;
    int argc = be_top(vm) - 1;
    int argv[BERRY_WORKER_ARGS_MAX];
    int i;
    int cog;
    const char *error = NULL;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "function name must be a string");
    }
    if (argc > BERRY_WORKER_ARGS_MAX) {
        be_raise(vm, "value_error", "too many cog_start arguments");
    }
    name = be_tostring(vm, 1);
    for (i = 0; i < argc; ++i) {
        argv[i] = (int)p2_require_int_arg(vm, i + 2, "cog_start arguments must be ints");
    }

    cog = berry_worker_start_cog(&error);
    if (cog < 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start worker cog");
    }
    if (berry_worker_exec_ints(name, argc, argv, &error) != 0) {
        be_raise(vm, "runtime_error", error ? error : "failed to start cog job");
    }

    be_pushint(vm, (bint)cog);
    be_return(vm);
}

static int m_p2_cog_states(bvm *vm)
{
    int cog;

    be_newobject(vm, "list");
    for (cog = 0; cog < 8; ++cog) {
        be_pushint(vm, (bint)_cogchk(cog));
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_locknew(bvm *vm)
{
    be_pushint(vm, (bint)_locknew());
    be_return(vm);
}

static int m_p2_lockset(bvm *vm)
{
    bint lock = p2_require_int_arg(vm, 1, "lock must be an int");
    if (lock < 0 || lock > 15) {
        be_raise(vm, "value_error", "lock must be between 0 and 15");
    }
    be_pushbool(vm, _locktry((int)lock) != 0);
    be_return(vm);
}

static int m_p2_lockclr(bvm *vm)
{
    bint lock = p2_require_int_arg(vm, 1, "lock must be an int");
    if (lock < 0 || lock > 15) {
        be_raise(vm, "value_error", "lock must be between 0 and 15");
    }
    _lockrel((int)lock);
    be_return_nil(vm);
}

static int m_p2_lockret(bvm *vm)
{
    bint lock = p2_require_int_arg(vm, 1, "lock must be an int");
    if (lock < 0 || lock > 15) {
        be_raise(vm, "value_error", "lock must be between 0 and 15");
    }
    _lockret((int)lock);
    be_return_nil(vm);
}

static int m_p2_sbrk(bvm *vm)
{
    be_pushint(vm, (bint)p2_heap_free_bytes());
    be_return(vm);
}

static int m_p2_heap_info(bvm *vm)
{
    be_newobject(vm, "map");

    be_pushstring(vm, "current");
    be_pushint(vm, (bint)p2_heap_free_bytes());
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "main");
    be_pushint(vm, (bint)p2_heap_main_free_bytes());
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "worker");
    be_pushint(vm, (bint)p2_heap_worker_free_bytes());
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_beep(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    bint freq = p2_require_int_arg(vm, 2, "freq must be an int");
    bint ms = p2_require_int_arg(vm, 3, "ms must be an int");
    uint32_t half_ticks;
    uint32_t end_ticks;
    uint32_t now;

    if (freq <= 0) {
        be_raise(vm, "value_error", "freq must be > 0");
    }
    if (ms < 0) {
        be_raise(vm, "value_error", "ms must be >= 0");
    }

    p2_gpio_clear(pin);
    _dirh(pin);
    half_ticks = (uint32_t)(_clockfreq() / ((uint32_t)freq * 2u));
    if (half_ticks == 0u) {
        half_ticks = 1u;
    }
    end_ticks = _cnt() + (uint32_t)((uint64_t)_clockfreq() * (uint32_t)ms / 1000u);
    do {
        _pinnot(pin);
        _waitx(half_ticks);
        now = _cnt();
    } while ((int32_t)(end_ticks - now) > 0);
    _pinl(pin);
    be_return_nil(vm);
}

void be_cache_p2module(bvm *vm)
{
    bstring *name = be_newstr(vm, "p2");

    be_newmodule(vm);
    p2_module_set_func(vm, "high", m_p2_high);
    p2_module_set_func(vm, "low", m_p2_low);
    p2_module_set_func(vm, "toggle", m_p2_toggle);
    p2_module_set_func(vm, "read", m_p2_read);
    p2_module_set_func(vm, "pinmode", m_p2_pinmode);
    p2_module_set_func(vm, "sleep_ms", m_p2_sleep_ms);
    p2_module_set_func(vm, "delay_us", m_p2_delay_us);
    p2_module_set_func(vm, "cogid", m_p2_cogid);
    p2_module_set_func(vm, "cog_start", m_p2_cog_start);
    p2_module_set_func(vm, "cog_stop", m_p2_cog_stop);
    p2_module_set_func(vm, "cog_states", m_p2_cog_states);
    p2_module_set_func(vm, "locknew", m_p2_locknew);
    p2_module_set_func(vm, "lockset", m_p2_lockset);
    p2_module_set_func(vm, "lockclr", m_p2_lockclr);
    p2_module_set_func(vm, "lockret", m_p2_lockret);
    p2_module_set_func(vm, "sbrk", m_p2_sbrk);
    p2_module_set_func(vm, "heap_info", m_p2_heap_info);
    p2_module_set_func(vm, "beep", m_p2_beep);

    be_pushstring(vm, "INPUT");
    be_pushint(vm, P2_PINMODE_INPUT);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "OUTPUT");
    be_pushint(vm, P2_PINMODE_OUTPUT);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "OPENDRAIN");
    be_pushint(vm, P2_PINMODE_OPENDRAIN);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_cache_module(vm, name);
    be_pop(vm, 1);
}
