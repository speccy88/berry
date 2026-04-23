/********************************************************************
** Propeller 2 native module for Berry on P2.
********************************************************************/
#include "berry.h"
#include <propeller2.h>
#include <cog.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void *p2_cog_stack_mem[8];
static uint32_t p2_cog_stack_size[8];

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

static int p2_optional_cog(bvm *vm, int index)
{
    if (be_top(vm) < index || be_isnil(vm, index)) {
        return ANY_COG;
    }
    {
        bint cog = p2_require_int(vm, index, "cog must be an int");
        if (cog < 0 || cog > 7) {
            be_raise(vm, "value_error", "cog must be between 0 and 7");
        }
        return (int)cog;
    }
}

static void *p2_optional_pointer(bvm *vm, int index)
{
    if (be_top(vm) < index || be_isnil(vm, index)) {
        return NULL;
    }
    if (be_iscomptr(vm, index)) {
        return be_tocomptr(vm, index);
    }
    if (be_isint(vm, index)) {
        return (void *)(uintptr_t)p2_require_u32(vm, index, "pointer must be an int or comptr");
    }
    be_raise(vm, "type_error", "pointer must be an int, comptr, or nil");
    return NULL;
}

static void p2_push_map_int_pair(bvm *vm,
    const char *k1,
    bint v1,
    const char *k2,
    bint v2)
{
    be_newobject(vm, "map");

    be_pushstring(vm, k1);
    be_pushint(vm, (bint)v1);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, k2);
    be_pushint(vm, (bint)v2);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    /* Keep only the map instance on the stack. */
    be_pop(vm, 1);
}

static int p2_hex_digit(int ch)
{
    if (ch >= '0' && ch <= '9') {
        return ch - '0';
    }
    if (ch >= 'a' && ch <= 'f') {
        return ch - 'a' + 10;
    }
    if (ch >= 'A' && ch <= 'F') {
        return ch - 'A' + 10;
    }
    return -1;
}

static int p2_cog_start_blob(bvm *vm, const void *blob, size_t length, void *arg, int cog)
{
    uint8_t *aligned;
    int result;

    if (!blob || length == 0 || (length & 3u) != 0u) {
        be_raise(vm, "value_error", "program bytes must be non-empty and 4-byte aligned in length");
    }

    aligned = malloc(length);
    if (!aligned) {
        be_raise(vm, "memory_error", "failed to allocate cog program buffer");
    }
    memcpy(aligned, blob, length);
    result = _cogstart_PASM(cog, aligned, arg);
    free(aligned);
    return result;
}

static void p2_cog_release_stack(int cog)
{
    if (cog >= 0 && cog < 8 && p2_cog_stack_mem[cog]) {
        free(p2_cog_stack_mem[cog]);
        p2_cog_stack_mem[cog] = NULL;
        p2_cog_stack_size[cog] = 0;
    }
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
    p2_push_map_int_pair(vm, "low", (bint)value.low, "high", (bint)value.high);
    be_return(vm);
}

int m_cog_start_pasm(bvm *vm)
{
    const void *blob;
    size_t length = 0;
    int cog;
    void *arg;
    int result;

    if (!be_isbytes(vm, 1)) {
        be_raise(vm, "type_error", "program must be a bytes object");
    }
    blob = be_tobytes(vm, 1, &length);
    cog = p2_optional_cog(vm, 3);
    arg = p2_optional_pointer(vm, 2);
    result = p2_cog_start_blob(vm, blob, length, arg, cog);

    be_pushint(vm, (bint)result);
    be_return(vm);
}

int m_cog_start_c(bvm *vm)
{
    void (*func)(void *);
    void *arg;
    uint32_t stack_size;
    void *stack_mem;
    int result;

    if (!be_iscomptr(vm, 1)) {
        be_raise(vm, "type_error", "function must be a comptr");
    }

    func = (void (*)(void *))be_tocomptr(vm, 1);
    arg = p2_optional_pointer(vm, 2);
    if (be_top(vm) >= 3 && !be_isnil(vm, 3)) {
        stack_size = p2_require_u32(vm, 3, "stack size must be an int");
    } else {
        stack_size = 1024u;
    }
    if (stack_size < 128u) {
        be_raise(vm, "value_error", "stack size must be at least 128 bytes");
    }

    stack_mem = malloc(stack_size);
    if (!stack_mem) {
        be_raise(vm, "memory_error", "failed to allocate cog C stack");
    }

    result = _cogstart_C(func, arg, stack_mem, stack_size);
    if (result >= 0 && result < 8) {
        p2_cog_release_stack(result);
        p2_cog_stack_mem[result] = stack_mem;
        p2_cog_stack_size[result] = stack_size;
    } else {
        free(stack_mem);
    }

    be_pushint(vm, (bint)result);
    be_return(vm);
}

int m_cog_start_hex(bvm *vm)
{
    const char *text;
    size_t text_len = 0;
    uint8_t *blob;
    size_t blob_len;
    size_t pos = 0;
    size_t i;
    int high = -1;
    int cog;
    void *arg;
    int result;

    if (!be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "program must be a hex string");
    }
    text = be_tostring(vm, 1);
    if (!text) {
        be_raise(vm, "value_error", "program must be a hex string");
    }
    text_len = strlen(text);
    blob_len = text_len / 2u + 1u;
    blob = malloc(blob_len);
    if (!blob) {
        be_raise(vm, "memory_error", "failed to allocate cog program buffer");
    }

    for (i = 0; i < text_len; ++i) {
        int digit = p2_hex_digit((unsigned char)text[i]);
        if (digit >= 0) {
            if (high < 0) {
                high = digit;
            } else {
                blob[pos++] = (uint8_t)((high << 4) | digit);
                high = -1;
            }
            continue;
        }
        if (text[i] == 'x' || text[i] == 'X') {
            if (i > 0 && text[i - 1] == '0' && high < 0) {
                continue;
            }
        }
        if (text[i] == ' ' || text[i] == '\t' || text[i] == '\r' || text[i] == '\n' || text[i] == '_' || text[i] == ':' || text[i] == ',') {
            continue;
        }
        free(blob);
        be_raise(vm, "value_error", "program contains a non-hex character");
    }

    if (high >= 0) {
        free(blob);
        be_raise(vm, "value_error", "program hex string must contain an even number of digits");
    }

    cog = p2_optional_cog(vm, 3);
    arg = p2_optional_pointer(vm, 2);
    result = p2_cog_start_blob(vm, blob, pos, arg, cog);
    free(blob);

    be_pushint(vm, (bint)result);
    be_return(vm);
}

int m_cog_stop(bvm *vm)
{
    int cog = p2_require_int(vm, 1, "cog must be an int");
    _cogstop(cog);
    p2_cog_release_stack(cog);
    be_return_nil(vm);
}

int m_cog_check(bvm *vm)
{
    be_pushint(vm, (bint)_cogchk(p2_require_int(vm, 1, "cog must be an int")));
    be_return(vm);
}

int m_cog_id(bvm *vm)
{
    be_pushint(vm, (bint)_cogid());
    be_return(vm);
}

int m_cog_states(bvm *vm)
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

int m_cog_stack_bytes(bvm *vm)
{
    int cog = p2_require_int(vm, 1, "cog must be an int");
    if (cog < 0 || cog > 7) {
        be_raise(vm, "value_error", "cog must be between 0 and 7");
    }
    be_pushint(vm, (bint)p2_cog_stack_size[cog]);
    be_return(vm);
}

int m_lock_new(bvm *vm)
{
    be_pushint(vm, (bint)_locknew());
    be_return(vm);
}

int m_lock_return(bvm *vm)
{
    _lockret(p2_require_int(vm, 1, "lock must be an int"));
    be_return_nil(vm);
}

int m_lock_try(bvm *vm)
{
    be_pushint(vm, (bint)_locktry(p2_require_int(vm, 1, "lock must be an int")));
    be_return(vm);
}

int m_lock_release(bvm *vm)
{
    _lockrel(p2_require_int(vm, 1, "lock must be an int"));
    be_return_nil(vm);
}

int m_lock_check(bvm *vm)
{
    be_pushint(vm, (bint)_lockchk(p2_require_int(vm, 1, "lock must be an int")));
    be_return(vm);
}

int m_attention_signal(bvm *vm)
{
    _cogatn(p2_require_u32(vm, 1, "mask must be an int"));
    be_return_nil(vm);
}

int m_attention_poll(bvm *vm)
{
    be_pushint(vm, (bint)_pollatn());
    be_return(vm);
}

int m_attention_wait(bvm *vm)
{
    be_pushint(vm, (bint)_waitatn());
    be_return(vm);
}

int m_cordic_rotxy(bvm *vm)
{
    cartesian_t coord;
    coord.x = (int32_t)p2_require_int(vm, 1, "x must be an int");
    coord.y = (int32_t)p2_require_int(vm, 2, "y must be an int");
    coord = _rotxy(coord, p2_require_u32(vm, 3, "theta must be an int"));
    p2_push_map_int_pair(vm, "x", (bint)coord.x, "y", (bint)coord.y);
    be_return(vm);
}

int m_cordic_xypol(bvm *vm)
{
    cartesian_t coord;
    polar_t polar;
    coord.x = (int32_t)p2_require_int(vm, 1, "x must be an int");
    coord.y = (int32_t)p2_require_int(vm, 2, "y must be an int");
    polar = _xypol(coord);
    p2_push_map_int_pair(vm, "r", (bint)polar.r, "t", (bint)polar.t);
    be_return(vm);
}

int m_cordic_polxy(bvm *vm)
{
    polar_t polar;
    cartesian_t coord;
    polar.r = p2_require_u32(vm, 1, "r must be an int");
    polar.t = p2_require_u32(vm, 2, "theta must be an int");
    coord = _polxy(polar);
    p2_push_map_int_pair(vm, "x", (bint)coord.x, "y", (bint)coord.y);
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
    /* FlexC advertises _pinrnd() in propeller2.h but does not resolve it
     * reliably on the current P2 build path, so use a portable fallback. */
    _pinw(p2_require_pin(vm, 1), (int)(_rnd() & 1u));
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
