/********************************************************************
** Propeller 2 native module for Berry on P2.
********************************************************************/
#include "berry.h"
#include <propeller2.h>
#include <stdio.h>

static bint p2_require_int(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    return be_toint(vm, index);
}

static uint32_t p2_require_u32(bvm *vm, int index, const char *what)
{
    return (uint32_t)p2_require_int(vm, index, what);
}

static int p2_require_boolish(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || (!be_isbool(vm, index) && !be_isint(vm, index))) {
        be_raise(vm, "type_error", what);
    }
    return be_tobool(vm, index);
}

static int p2_require_pin(bvm *vm, int index)
{
    bint pin = p2_require_int(vm, index, "pin must be an int");
    if (pin < 0 || pin > 63) {
        be_raise(vm, "value_error", "pin must be between 0 and 63");
    }
    return (int)pin;
}

int m_clock_freq(bvm *vm)
{
    be_pushint(vm, (bint)_clockfreq());
    be_return(vm);
}

int m_clock_mode(bvm *vm)
{
    be_pushint(vm, (bint)_clockmode());
    be_return(vm);
}

int m_misc_random(bvm *vm)
{
    be_pushint(vm, (bint)_rnd());
    be_return(vm);
}

int m_misc_reverse_bits(bvm *vm)
{
    be_pushint(vm, (bint)_rev(p2_require_u32(vm, 1, "value must be an int")));
    be_return(vm);
}

int m_misc_encode(bvm *vm)
{
    be_pushint(vm, (bint)_encod(p2_require_u32(vm, 1, "value must be an int")));
    be_return(vm);
}

int m_misc_isqrt(bvm *vm)
{
    be_pushint(vm, (bint)_isqrt(p2_require_u32(vm, 1, "value must be an int")));
    be_return(vm);
}

int m_misc_muldiv64(bvm *vm)
{
    uint32_t mult1 = p2_require_u32(vm, 1, "mult1 must be an int");
    uint32_t mult2 = p2_require_u32(vm, 2, "mult2 must be an int");
    uint32_t divisor = p2_require_u32(vm, 3, "divisor must be an int");
    be_pushint(vm, (bint)_muldiv64(mult1, mult2, divisor));
    be_return(vm);
}

int m_counter_ticks(bvm *vm)
{
    be_pushint(vm, (bint)_cnt());
    be_return(vm);
}

int m_counter_ticks_high(bvm *vm)
{
    be_pushint(vm, (bint)_cnth());
    be_return(vm);
}

int m_counter_ticks64(bvm *vm)
{
    counter64_t value = _cnthl();
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "%lu:%lu",
        (unsigned long)value.high, (unsigned long)value.low);
    be_pushstring(vm, buffer);
    be_return(vm);
}

int m_counter_wait_until(bvm *vm)
{
    _waitcnt(p2_require_u32(vm, 1, "tick must be an int"));
    be_return_nil(vm);
}

int m_counter_wait_ticks(bvm *vm)
{
    _waitx(p2_require_u32(vm, 1, "delay must be an int"));
    be_return_nil(vm);
}

int m_counter_sleep_us(bvm *vm)
{
    _waitus(p2_require_u32(vm, 1, "usecs must be an int"));
    be_return_nil(vm);
}

int m_counter_sleep_ms(bvm *vm)
{
    _waitms(p2_require_u32(vm, 1, "msecs must be an int"));
    be_return_nil(vm);
}

int m_counter_sleep(bvm *vm)
{
    _waitsec(p2_require_u32(vm, 1, "secs must be an int"));
    be_return_nil(vm);
}

int m_pin_input(bvm *vm)
{
    _dirl(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_output(bvm *vm)
{
    _dirh(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_write(bvm *vm)
{
    int pin = p2_require_pin(vm, 1);
    int value = p2_require_boolish(vm, 2, "value must be a bool or int");
    _pinw(pin, value);
    be_return_nil(vm);
}

int m_pin_low(bvm *vm)
{
    _pinl(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_high(bvm *vm)
{
    _pinh(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_toggle(bvm *vm)
{
    _pinnot(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_randomize(bvm *vm)
{
    _pinrnd(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_float(bvm *vm)
{
    _pinf(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_pin_read(bvm *vm)
{
    be_pushint(vm, (bint)_pinr(p2_require_pin(vm, 1)));
    be_return(vm);
}

int m_smartpin_write_mode(bvm *vm)
{
    _wrpin(p2_require_pin(vm, 1), p2_require_u32(vm, 2, "mode must be an int"));
    be_return_nil(vm);
}

int m_smartpin_write_x(bvm *vm)
{
    _wxpin(p2_require_pin(vm, 1), p2_require_u32(vm, 2, "x must be an int"));
    be_return_nil(vm);
}

int m_smartpin_write_y(bvm *vm)
{
    _wypin(p2_require_pin(vm, 1), p2_require_u32(vm, 2, "y must be an int"));
    be_return_nil(vm);
}

int m_smartpin_ack(bvm *vm)
{
    _akpin(p2_require_pin(vm, 1));
    be_return_nil(vm);
}

int m_smartpin_read(bvm *vm)
{
    be_pushint(vm, (bint)_rdpin(p2_require_pin(vm, 1)));
    be_return(vm);
}

int m_smartpin_query(bvm *vm)
{
    be_pushint(vm, (bint)_rqpin(p2_require_pin(vm, 1)));
    be_return(vm);
}

int m_smartpin_start(bvm *vm)
{
    int pin = p2_require_pin(vm, 1);
    uint32_t mode = p2_require_u32(vm, 2, "mode must be an int");
    uint32_t x = p2_require_u32(vm, 3, "x must be an int");
    uint32_t y = p2_require_u32(vm, 4, "y must be an int");
    _pinstart(pin, mode, x, y);
    be_return_nil(vm);
}

int m_smartpin_clear(bvm *vm)
{
    _pinclear(p2_require_pin(vm, 1));
    be_return_nil(vm);
}
