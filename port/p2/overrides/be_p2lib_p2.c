/********************************************************************
** Friendly Propeller 2 native module for Berry.
** This wraps the lower-level prop2_* globals with tutorial-sized names.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_conf_p2.h"
#include "berry_port.h"
#include "berry_worker.h"
#include "p2_build_info.h"
#include "p2_heap.h"

#include <propeller2.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern int m_clock_freq(bvm *vm);
extern int m_clock_mode(bvm *vm);
extern int m_misc_random(bvm *vm);
extern int m_misc_reverse_bits(bvm *vm);
extern int m_misc_encode(bvm *vm);
extern int m_misc_isqrt(bvm *vm);
extern int m_misc_muldiv64(bvm *vm);
extern int m_counter_ticks(bvm *vm);
extern int m_counter_ticks_high(bvm *vm);
extern int m_counter_ticks64(bvm *vm);
extern int m_counter_wait_until(bvm *vm);
extern int m_counter_wait_ticks(bvm *vm);
extern int m_counter_sleep_us(bvm *vm);
extern int m_counter_sleep_ms(bvm *vm);
extern int m_counter_sleep(bvm *vm);
extern int m_cog_start_c(bvm *vm);
extern int m_cog_start_pasm(bvm *vm);
extern int m_cog_start_hex(bvm *vm);
extern int m_cog_stop(bvm *vm);
extern int m_cog_check(bvm *vm);
extern int m_cog_id(bvm *vm);
extern int m_cog_states(bvm *vm);
extern int m_cog_stack_bytes(bvm *vm);
extern int m_lock_new(bvm *vm);
extern int m_lock_return(bvm *vm);
extern int m_lock_try(bvm *vm);
extern int m_lock_release(bvm *vm);
extern int m_lock_check(bvm *vm);
extern int m_attention_signal(bvm *vm);
extern int m_attention_poll(bvm *vm);
extern int m_attention_wait(bvm *vm);
extern int m_cordic_rotxy(bvm *vm);
extern int m_cordic_xypol(bvm *vm);
extern int m_cordic_polxy(bvm *vm);
extern int m_pin_input(bvm *vm);
extern int m_pin_output(bvm *vm);
extern int m_pin_write(bvm *vm);
extern int m_pin_low(bvm *vm);
extern int m_pin_high(bvm *vm);
extern int m_pin_toggle(bvm *vm);
extern int m_pin_randomize(bvm *vm);
extern int m_pin_float(bvm *vm);
extern int m_pin_read(bvm *vm);
extern int m_smartpin_write_mode(bvm *vm);
extern int m_smartpin_write_x(bvm *vm);
extern int m_smartpin_write_y(bvm *vm);
extern int m_smartpin_ack(bvm *vm);
extern int m_smartpin_read(bvm *vm);
extern int m_smartpin_query(bvm *vm);
extern int m_smartpin_start(bvm *vm);
extern int m_smartpin_clear(bvm *vm);

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
    berry_p2_gpio_reset(pin);
}

static int m_p2_high(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    berry_p2_gpio_output_value(pin, 1);
    be_return_nil(vm);
}

static int m_p2_low(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    berry_p2_gpio_output_value(pin, 0);
    be_return_nil(vm);
}

static int m_p2_toggle(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    p2_gpio_clear(pin);
    berry_p2_gpio_toggle(pin);
    be_return_nil(vm);
}

static int m_p2_read(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    be_pushint(vm, (bint)berry_p2_gpio_read(pin));
    be_return(vm);
}

static int m_p2_pinmode(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);
    bint mode = p2_require_int_arg(vm, 2, "mode must be an int");

    p2_gpio_clear(pin);
    switch (mode) {
    case P2_PINMODE_INPUT:
        berry_p2_gpio_input(pin);
        break;
    case P2_PINMODE_OUTPUT:
        berry_p2_gpio_output(pin);
        break;
    case P2_PINMODE_OPENDRAIN:
        berry_p2_gpio_output_value(pin, 0);
        berry_p2_gpio_input(pin);
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
    while (ms > 0) {
        uint32_t chunk = ms > 10 ? 10u : (uint32_t)ms;
        p2_check_interrupt_now(vm);
        _waitms(chunk);
        ms -= (bint)chunk;
    }
    p2_check_interrupt_now(vm);
    be_return_nil(vm);
}

static int m_p2_delay_us(bvm *vm)
{
    bint us = p2_require_int_arg(vm, 1, "us must be an int");
    if (us < 0) {
        be_raise(vm, "value_error", "us must be >= 0");
    }
    while (us > 0) {
        uint32_t chunk = us > 10000 ? 10000u : (uint32_t)us;
        p2_check_interrupt_now(vm);
        _waitus(chunk);
        us -= (bint)chunk;
    }
    p2_check_interrupt_now(vm);
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

static void p2_status_write(const char *text)
{
    be_writebuffer(text, strlen(text));
}

static void p2_status_write_line(const char *text)
{
    p2_status_write(text);
    be_writenewline();
}

static void p2_status_writef(const char *fmt, ...)
{
    char buffer[160];
    va_list ap;

    va_start(ap, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, ap);
    va_end(ap);
    p2_status_write(buffer);
}

static void p2_status_bar(char *out, size_t size, unsigned long used, unsigned long total)
{
    enum { P2_STATUS_BAR_WIDTH = 24 };
    unsigned long filled = 0;
    unsigned i;

    if (!out || size < P2_STATUS_BAR_WIDTH + 3u) {
        return;
    }
    if (total > 0) {
        filled = (used * P2_STATUS_BAR_WIDTH + (total / 2u)) / total;
        if (filled > P2_STATUS_BAR_WIDTH) {
            filled = P2_STATUS_BAR_WIDTH;
        }
    }

    out[0] = '[';
    for (i = 0; i < P2_STATUS_BAR_WIDTH; ++i) {
        out[i + 1u] = i < filled ? '#' : '.';
    }
    out[P2_STATUS_BAR_WIDTH + 1u] = ']';
    out[P2_STATUS_BAR_WIDTH + 2u] = '\0';
}

static void p2_status_print_bar_line(const char *label,
    unsigned long used,
    unsigned long total)
{
    char bar[32];
    unsigned long pct = 0;

    if (total > 0) {
        pct = (used * 100u + (total / 2u)) / total;
        if (pct > 999u) {
            pct = 999u;
        }
    }
    p2_status_bar(bar, sizeof(bar), used, total);
    p2_status_writef("  %-12s %s %3lu%% %7lu / %7lu B\n",
        label,
        bar,
        pct,
        used,
        total);
}

static void p2_status_print_size_line(const char *label, unsigned long bytes)
{
    p2_status_writef("  %-12s %7lu B\n", label, bytes);
}

static int m_p2_status(bvm *vm)
{
    unsigned long image = (unsigned long)P2_BUILD_BINARY_BYTES;
    unsigned long code = (unsigned long)P2_BUILD_CODE_BYTES;
    unsigned long cnst = (unsigned long)P2_BUILD_CONST_BYTES;
    unsigned long init = (unsigned long)P2_BUILD_INIT_BYTES;
    unsigned long data = (unsigned long)P2_BUILD_DATA_BYTES;
    unsigned long hub_total = (unsigned long)BE_P2_HUB_RAM_BYTES;
    unsigned long main_total = (unsigned long)BE_P2_HEAP_BYTES;
    unsigned long worker_total = (unsigned long)BE_P2_WORKER_HEAP_BYTES;
    unsigned long main_free = (unsigned long)p2_heap_main_free_bytes();
    unsigned long worker_free = (unsigned long)p2_heap_worker_free_bytes();
    unsigned long current_free = (unsigned long)p2_heap_free_bytes();
    unsigned long main_used = main_total > main_free ? main_total - main_free : 0u;
    unsigned long worker_used = worker_total > worker_free ? worker_total - worker_free : 0u;
    unsigned long hub_used = image <= hub_total ? image : hub_total;
    unsigned long clock = (unsigned long)_clockfreq();
    unsigned long mode = (unsigned long)_clockmode();
    unsigned long cogid = (unsigned long)_cogid();
    unsigned long ticks = (unsigned long)_cnt();
    int cog;

    (void)vm;

    p2_status_write_line("");
    p2_status_write_line("P2 status");
    p2_status_write_line("---------");
    p2_status_writef("Build       %s %s\n", P2_BUILD_DATE_STR, P2_BUILD_TIME_STR);
    p2_status_writef("Runtime     Catalina P2_EDGE %s\n",
#if defined(__CATALINA_libpsram) || defined(__CATALINA_PSRAM)
        "PSRAM"
#else
        "no-PSRAM"
#endif
    );
    p2_status_writef("Clock       %lu Hz  mode 0x%08lX  tick %lu\n", clock, mode, ticks);
    p2_status_writef("Current cog %lu\n", cogid);
    p2_status_write_line("");

    p2_status_write_line("Memory");
    p2_status_print_bar_line("image", image, hub_total);
    p2_status_print_bar_line("main heap", main_used, main_total);
    p2_status_print_bar_line("worker heap", worker_used, worker_total);
    p2_status_writef("  current free %7lu B\n", current_free);
    p2_status_print_size_line("code", code);
    p2_status_print_size_line("const", cnst);
    p2_status_print_size_line("init", init);
    p2_status_print_size_line("data", data);
    p2_status_print_size_line("bytes max", (unsigned long)BE_BYTES_MAX_SIZE);
    p2_status_writef("  stack        %7lu slots\n", (unsigned long)BE_STACK_TOTAL_MAX);
    p2_status_write_line("");

    p2_status_write_line("Cogs");
    for (cog = 0; cog < 8; ++cog) {
        int raw = _cogchk(cog);
        p2_status_writef("  cog %d  %-4s  raw %d%s\n",
            cog,
            raw ? "run" : "free",
            raw,
            cog == (int)cogid ? "  current" : "");
    }
    p2_status_write_line("");

    be_return_nil(vm);
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
        berry_p2_gpio_toggle(pin);
        _waitx(half_ticks);
        now = _cnt();
    } while ((int32_t)(end_ticks - now) > 0);
    berry_p2_gpio_output_value(pin, 0);
    be_return_nil(vm);
}

static int m_p2_member(bvm *vm)
{
    const char *name = be_tostring(vm, 1);

    if (!strcmp(name, "clock_freq")) be_pushntvfunction(vm, m_clock_freq);
    else if (!strcmp(name, "clock_mode")) be_pushntvfunction(vm, m_clock_mode);
    else if (!strcmp(name, "random")) be_pushntvfunction(vm, m_misc_random);
    else if (!strcmp(name, "reverse_bits")) be_pushntvfunction(vm, m_misc_reverse_bits);
    else if (!strcmp(name, "encode")) be_pushntvfunction(vm, m_misc_encode);
    else if (!strcmp(name, "isqrt")) be_pushntvfunction(vm, m_misc_isqrt);
    else if (!strcmp(name, "muldiv64")) be_pushntvfunction(vm, m_misc_muldiv64);
    else if (!strcmp(name, "ticks")) be_pushntvfunction(vm, m_counter_ticks);
    else if (!strcmp(name, "ticks_high")) be_pushntvfunction(vm, m_counter_ticks_high);
    else if (!strcmp(name, "ticks64")) be_pushntvfunction(vm, m_counter_ticks64);
    else if (!strcmp(name, "wait_until")) be_pushntvfunction(vm, m_counter_wait_until);
    else if (!strcmp(name, "wait_ticks")) be_pushntvfunction(vm, m_counter_wait_ticks);
    else if (!strcmp(name, "sleep_us")) be_pushntvfunction(vm, m_counter_sleep_us);
    else if (!strcmp(name, "sleep")) be_pushntvfunction(vm, m_counter_sleep);
    else if (!strcmp(name, "high")) be_pushntvfunction(vm, m_p2_high);
    else if (!strcmp(name, "low")) be_pushntvfunction(vm, m_p2_low);
    else if (!strcmp(name, "toggle")) be_pushntvfunction(vm, m_p2_toggle);
    else if (!strcmp(name, "read")) be_pushntvfunction(vm, m_p2_read);
    else if (!strcmp(name, "pinmode")) be_pushntvfunction(vm, m_p2_pinmode);
    else if (!strcmp(name, "pin_input")) be_pushntvfunction(vm, m_pin_input);
    else if (!strcmp(name, "pin_output")) be_pushntvfunction(vm, m_pin_output);
    else if (!strcmp(name, "pin_write")) be_pushntvfunction(vm, m_pin_write);
    else if (!strcmp(name, "pin_low")) be_pushntvfunction(vm, m_pin_low);
    else if (!strcmp(name, "pin_high")) be_pushntvfunction(vm, m_pin_high);
    else if (!strcmp(name, "pin_toggle")) be_pushntvfunction(vm, m_pin_toggle);
    else if (!strcmp(name, "pin_randomize")) be_pushntvfunction(vm, m_pin_randomize);
    else if (!strcmp(name, "pin_float")) be_pushntvfunction(vm, m_pin_float);
    else if (!strcmp(name, "pin_read")) be_pushntvfunction(vm, m_pin_read);
    else if (!strcmp(name, "sleep_ms")) be_pushntvfunction(vm, m_p2_sleep_ms);
    else if (!strcmp(name, "delay_us")) be_pushntvfunction(vm, m_p2_delay_us);
    else if (!strcmp(name, "cogid")) be_pushntvfunction(vm, m_p2_cogid);
    else if (!strcmp(name, "cog_id")) be_pushntvfunction(vm, m_cog_id);
    else if (!strcmp(name, "cog_start")) be_pushntvfunction(vm, m_p2_cog_start);
    else if (!strcmp(name, "cog_start_c")) be_pushntvfunction(vm, m_cog_start_c);
    else if (!strcmp(name, "cog_start_pasm")) be_pushntvfunction(vm, m_cog_start_pasm);
    else if (!strcmp(name, "cog_start_hex")) be_pushntvfunction(vm, m_cog_start_hex);
    else if (!strcmp(name, "cog_stop")) be_pushntvfunction(vm, m_p2_cog_stop);
    else if (!strcmp(name, "cog_raw_stop")) be_pushntvfunction(vm, m_cog_stop);
    else if (!strcmp(name, "cog_check")) be_pushntvfunction(vm, m_cog_check);
    else if (!strcmp(name, "cog_states")) be_pushntvfunction(vm, m_p2_cog_states);
    else if (!strcmp(name, "cog_stack_bytes")) be_pushntvfunction(vm, m_cog_stack_bytes);
    else if (!strcmp(name, "locknew")) be_pushntvfunction(vm, m_p2_locknew);
    else if (!strcmp(name, "lock_new")) be_pushntvfunction(vm, m_lock_new);
    else if (!strcmp(name, "lockset")) be_pushntvfunction(vm, m_p2_lockset);
    else if (!strcmp(name, "lockclr")) be_pushntvfunction(vm, m_p2_lockclr);
    else if (!strcmp(name, "lockret")) be_pushntvfunction(vm, m_p2_lockret);
    else if (!strcmp(name, "lock_return")) be_pushntvfunction(vm, m_lock_return);
    else if (!strcmp(name, "lock_try")) be_pushntvfunction(vm, m_lock_try);
    else if (!strcmp(name, "lock_release")) be_pushntvfunction(vm, m_lock_release);
    else if (!strcmp(name, "lock_check")) be_pushntvfunction(vm, m_lock_check);
    else if (!strcmp(name, "attention_signal")) be_pushntvfunction(vm, m_attention_signal);
    else if (!strcmp(name, "attention_poll")) be_pushntvfunction(vm, m_attention_poll);
    else if (!strcmp(name, "attention_wait")) be_pushntvfunction(vm, m_attention_wait);
    else if (!strcmp(name, "rotxy")) be_pushntvfunction(vm, m_cordic_rotxy);
    else if (!strcmp(name, "xypol")) be_pushntvfunction(vm, m_cordic_xypol);
    else if (!strcmp(name, "polxy")) be_pushntvfunction(vm, m_cordic_polxy);
    else if (!strcmp(name, "smartpin_write_mode")) be_pushntvfunction(vm, m_smartpin_write_mode);
    else if (!strcmp(name, "smartpin_write_x")) be_pushntvfunction(vm, m_smartpin_write_x);
    else if (!strcmp(name, "smartpin_write_y")) be_pushntvfunction(vm, m_smartpin_write_y);
    else if (!strcmp(name, "smartpin_ack")) be_pushntvfunction(vm, m_smartpin_ack);
    else if (!strcmp(name, "smartpin_read")) be_pushntvfunction(vm, m_smartpin_read);
    else if (!strcmp(name, "smartpin_query")) be_pushntvfunction(vm, m_smartpin_query);
    else if (!strcmp(name, "smartpin_start")) be_pushntvfunction(vm, m_smartpin_start);
    else if (!strcmp(name, "smartpin_clear")) be_pushntvfunction(vm, m_smartpin_clear);
    else if (!strcmp(name, "sbrk")) be_pushntvfunction(vm, m_p2_sbrk);
    else if (!strcmp(name, "heap_info")) be_pushntvfunction(vm, m_p2_heap_info);
    else if (!strcmp(name, "status")) be_pushntvfunction(vm, m_p2_status);
    else if (!strcmp(name, "beep")) be_pushntvfunction(vm, m_p2_beep);
    else if (!strcmp(name, "INPUT")) be_pushint(vm, P2_PINMODE_INPUT);
    else if (!strcmp(name, "OUTPUT")) be_pushint(vm, P2_PINMODE_OUTPUT);
    else if (!strcmp(name, "OPENDRAIN")) be_pushint(vm, P2_PINMODE_OPENDRAIN);
    else be_pushnil(vm);
    be_return(vm);
}

void be_cache_p2module(bvm *vm)
{
    bstring *name = be_newstr(vm, "p2");

    be_newmodule(vm);
    p2_module_set_func(vm, "member", m_p2_member);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
