/********************************************************************
** Propeller 2 I2C native module for Berry.
** Transaction sequencing is adapted from Catalina's P2 I2C examples.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_module.h"
#include "be_string.h"
#include <propeller2.h>
#include <stdint.h>
#include <stdlib.h>

enum {
    BERRY_P2_I2C_ACK = 0,
    BERRY_P2_I2C_NAK = 1
};

typedef struct berry_p2_i2c_state {
    int initialized;
    int scl_pin;
    int sda_pin;
    unsigned khz;
    uint32_t quarter_ticks;
} berry_p2_i2c_state;

static berry_p2_i2c_state g_i2c;

static void i2c_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void i2c_delay(uint32_t ticks)
{
    if (ticks > 0u) {
        _waitx(ticks);
    }
}

static void i2c_release_high(int pin)
{
    _dirl(pin);
}

static void i2c_drive_low(int pin)
{
    _pinl(pin);
}

static void i2c_start_condition(void)
{
    uint32_t tix = g_i2c.quarter_ticks;

    i2c_release_high(g_i2c.sda_pin);
    i2c_release_high(g_i2c.scl_pin);
    i2c_delay(tix);

    i2c_drive_low(g_i2c.sda_pin);
    i2c_delay(tix);

    i2c_drive_low(g_i2c.scl_pin);
    i2c_delay(tix);
}

static void i2c_setup_bus(int scl, int sda, unsigned khz)
{
    uint32_t quarter_ticks = (_clockfreq() / (khz * 1000u)) >> 2;

    if (quarter_ticks == 0u) {
        quarter_ticks = 1u;
    }

    g_i2c.initialized = 1;
    g_i2c.scl_pin = scl;
    g_i2c.sda_pin = sda;
    g_i2c.khz = khz;
    g_i2c.quarter_ticks = quarter_ticks;

    _pinl(scl);
    _pinl(sda);
    _dirl(scl);
    _dirl(sda);
}

static void i2c_stop_condition(void)
{
    uint32_t tix = g_i2c.quarter_ticks;

    i2c_drive_low(g_i2c.sda_pin);
    i2c_release_high(g_i2c.scl_pin);
    i2c_delay(tix);
    i2c_release_high(g_i2c.sda_pin);
    i2c_delay(tix);
}

static int i2c_write_byte(uint8_t value)
{
    uint32_t tix = g_i2c.quarter_ticks;
    unsigned bit;

    for (bit = 0; bit < 8u; ++bit) {
        if (value & 0x80u) {
            i2c_release_high(g_i2c.sda_pin);
        } else {
            i2c_drive_low(g_i2c.sda_pin);
        }
        value <<= 1;
        i2c_delay(tix);
        i2c_release_high(g_i2c.scl_pin);
        i2c_delay(tix);
        i2c_delay(tix);
        i2c_drive_low(g_i2c.scl_pin);
        i2c_delay(tix);
    }

    i2c_release_high(g_i2c.sda_pin);
    i2c_delay(tix);
    i2c_release_high(g_i2c.scl_pin);
    i2c_delay(tix);
    {
        int ack = _pinr(g_i2c.sda_pin) ? BERRY_P2_I2C_NAK : BERRY_P2_I2C_ACK;
        i2c_delay(tix);
        i2c_drive_low(g_i2c.scl_pin);
        i2c_delay(tix);
        i2c_delay(tix);
        return ack;
    }
}

static int i2c_write_block(const uint8_t *data, size_t length)
{
    size_t i;

    for (i = 0; i < length; ++i) {
        if (i2c_write_byte(data[i]) != BERRY_P2_I2C_ACK) {
            return 0;
        }
    }
    return 1;
}

static uint8_t i2c_read_byte(int ackbit)
{
    uint32_t tix = g_i2c.quarter_ticks;
    uint8_t value = 0;
    unsigned bit;

    i2c_release_high(g_i2c.sda_pin);

    for (bit = 0; bit < 8u; ++bit) {
        i2c_delay(tix);
        i2c_release_high(g_i2c.scl_pin);
        i2c_delay(tix);
        value = (uint8_t)((value << 1) | (_pinr(g_i2c.sda_pin) ? 1u : 0u));
        i2c_delay(tix);
        i2c_drive_low(g_i2c.scl_pin);
        i2c_delay(tix);
    }

    if (ackbit == BERRY_P2_I2C_ACK) {
        i2c_drive_low(g_i2c.sda_pin);
    } else {
        i2c_release_high(g_i2c.sda_pin);
    }
    i2c_delay(tix);
    i2c_release_high(g_i2c.scl_pin);
    i2c_delay(tix);
    i2c_delay(tix);
    i2c_drive_low(g_i2c.scl_pin);
    i2c_delay(tix);
    i2c_delay(tix);
    i2c_release_high(g_i2c.sda_pin);

    return value;
}

static void i2c_read_block(uint8_t *data, size_t length)
{
    size_t i;

    for (i = 0; i < length; ++i) {
        int ackbit = (i + 1u < length) ? BERRY_P2_I2C_ACK : BERRY_P2_I2C_NAK;
        data[i] = i2c_read_byte(ackbit);
    }
}

static int i2c_probe_address(int addr)
{
    int ok;

    i2c_start_condition();
    ok = (i2c_write_byte((uint8_t)(addr << 1)) == BERRY_P2_I2C_ACK);
    i2c_stop_condition();
    return ok;
}

static int i2c_transaction_write(int addr, const uint8_t *data, size_t length)
{
    int ok;

    i2c_start_condition();
    ok = (i2c_write_byte((uint8_t)(addr << 1)) == BERRY_P2_I2C_ACK);
    if (ok && length > 0u) {
        ok = i2c_write_block(data, length);
    }
    i2c_stop_condition();
    return ok;
}

static int i2c_transaction_read(int addr, uint8_t *data, size_t length)
{
    int ok;

    if (length == 0u) {
        return 1;
    }

    i2c_start_condition();
    ok = (i2c_write_byte((uint8_t)((addr << 1) | 1)) == BERRY_P2_I2C_ACK);
    if (ok) {
        i2c_read_block(data, length);
    }
    i2c_stop_condition();
    return ok;
}

static int i2c_transaction_writeread(int addr,
    const uint8_t *txdata,
    size_t txlen,
    uint8_t *rxdata,
    size_t rxlen)
{
    int ok;

    if (txlen == 0u) {
        return i2c_transaction_read(addr, rxdata, rxlen);
    }

    i2c_start_condition();
    ok = (i2c_write_byte((uint8_t)(addr << 1)) == BERRY_P2_I2C_ACK);
    if (ok) {
        ok = i2c_write_block(txdata, txlen);
    }
    if (ok && rxlen > 0u) {
        i2c_start_condition();
        ok = (i2c_write_byte((uint8_t)((addr << 1) | 1)) == BERRY_P2_I2C_ACK);
        if (ok) {
            i2c_read_block(rxdata, rxlen);
        }
    }
    i2c_stop_condition();
    return ok;
}

static int m_i2c_init(bvm *vm)
{
    int scl = berry_p2_bus_require_pin(vm, 1, "scl_pin must be an int");
    int sda = berry_p2_bus_require_pin(vm, 2, "sda_pin must be an int");
    unsigned khz = berry_p2_bus_require_khz(vm, 3, "khz must be an int");

    i2c_setup_bus(scl, sda, khz);
    be_return_nil(vm);
}

static int m_i2c_write(bvm *vm)
{
    int addr = berry_p2_bus_require_address7(vm, 1);
    berry_p2_bus_buffer tx = berry_p2_bus_get_buffer(vm, 2, "data must be a string, bytes, or list");
    size_t txlen = tx.length;
    int ok;

    berry_p2_bus_require_init(vm, g_i2c.initialized, "i2c.init() must be called first");
    ok = i2c_transaction_write(addr, tx.data, tx.length);
    berry_p2_bus_release_buffer(&tx);

    if (!ok) {
        be_raise(vm, "runtime_error", "i2c write failed");
    }

    be_pushint(vm, (bint)txlen);
    be_return(vm);
}

static int m_i2c_read(bvm *vm)
{
    int addr = berry_p2_bus_require_address7(vm, 1);
    size_t count = berry_p2_bus_require_count(vm, 2, "count must be an int");
    uint8_t *rx;
    int ok;

    berry_p2_bus_require_init(vm, g_i2c.initialized, "i2c.init() must be called first");

    if (count == 0u) {
        be_pushstring(vm, "");
        be_return(vm);
    }

    rx = (uint8_t *)malloc(count);
    if (!rx) {
        be_raise(vm, "memory_error", "failed to allocate read buffer");
    }

    ok = i2c_transaction_read(addr, rx, count);
    if (!ok) {
        free(rx);
        be_raise(vm, "runtime_error", "i2c read failed");
    }

    be_pushnstring(vm, (const char *)rx, count);
    free(rx);
    be_return(vm);
}

static int m_i2c_writeread(bvm *vm)
{
    int addr = berry_p2_bus_require_address7(vm, 1);
    berry_p2_bus_buffer tx = berry_p2_bus_get_buffer(vm, 2, "txdata must be a string, bytes, or list");
    size_t rxcount = berry_p2_bus_require_count(vm, 3, "rxcount must be an int");
    uint8_t *rx = NULL;
    int ok;

    berry_p2_bus_require_init(vm, g_i2c.initialized, "i2c.init() must be called first");

    if (rxcount > 0u) {
        rx = (uint8_t *)malloc(rxcount);
        if (!rx) {
            berry_p2_bus_release_buffer(&tx);
            be_raise(vm, "memory_error", "failed to allocate read buffer");
        }
    }

    ok = i2c_transaction_writeread(addr, tx.data, tx.length, rx, rxcount);
    berry_p2_bus_release_buffer(&tx);

    if (!ok) {
        free(rx);
        be_raise(vm, "runtime_error", "i2c writeread failed");
    }

    if (rxcount == 0u) {
        be_pushstring(vm, "");
    } else {
        be_pushnstring(vm, (const char *)rx, rxcount);
    }
    free(rx);
    be_return(vm);
}

static int m_i2c_scan(bvm *vm)
{
    int addr;

    berry_p2_bus_require_init(vm, g_i2c.initialized, "i2c.init() must be called first");

    be_newobject(vm, "list");
    for (addr = 0x08; addr <= 0x77; ++addr) {
        if (i2c_probe_address(addr)) {
            be_pushint(vm, (bint)addr);
            be_data_push(vm, -2);
            be_pop(vm, 1);
        }
    }
    be_pop(vm, 1);
    be_return(vm);
}

void be_cache_i2cmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "i2c");

    be_newmodule(vm);
    i2c_module_set_func(vm, "init", m_i2c_init);
    i2c_module_set_func(vm, "write", m_i2c_write);
    i2c_module_set_func(vm, "read", m_i2c_read);
    i2c_module_set_func(vm, "writeread", m_i2c_writeread);
    i2c_module_set_func(vm, "scan", m_i2c_scan);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
