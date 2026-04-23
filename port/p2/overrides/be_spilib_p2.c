/********************************************************************
** Propeller 2 SPI native module for Berry.
** The public Berry API shape follows the requested Berry-facing design,
** while the low-level transfer loop stays intentionally small and local.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_module.h"
#include "be_string.h"
#include <propeller2.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct berry_p2_spi_state {
    int initialized;
    int clk_pin;
    int mosi_pin;
    int miso_pin;
    int cs_pin;
    int mode;
    unsigned khz;
    uint32_t half_ticks;
} berry_p2_spi_state;

static berry_p2_spi_state g_spi;

static void spi_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void spi_delay(uint32_t ticks)
{
    if (ticks > 0u) {
        _waitx(ticks);
    }
}

static int spi_require_mode(bvm *vm, int index)
{
    bint mode = berry_p2_bus_require_int(vm, index, "mode must be an int");
    if (mode < 0 || mode > 3) {
        be_raise(vm, "value_error", "mode must be between 0 and 3");
    }
    return (int)mode;
}

static void spi_apply_idle(void)
{
    _pinw(g_spi.clk_pin, (g_spi.mode & 0x2) ? 1 : 0);
}

static void spi_setup_bus(int clk, int mosi, int miso, int cs, int mode, unsigned khz)
{
    uint64_t denom = (uint64_t)khz * 2000u;
    uint32_t half_ticks = (uint32_t)((uint64_t)_clockfreq() / denom);

    if (half_ticks == 0u) {
        half_ticks = 1u;
    }

    g_spi.initialized = 1;
    g_spi.clk_pin = clk;
    g_spi.mosi_pin = mosi;
    g_spi.miso_pin = miso;
    g_spi.cs_pin = cs;
    g_spi.mode = mode;
    g_spi.khz = khz;
    g_spi.half_ticks = half_ticks;

    _dirh(clk);
    _dirh(mosi);
    _dirl(miso);
    _dirh(cs);

    _pinw(g_spi.mosi_pin, 0);
    spi_apply_idle();
    _pinw(g_spi.cs_pin, 1);
}

static uint8_t spi_transfer_byte(uint8_t out)
{
    uint8_t in = 0;
    int cpha = g_spi.mode & 0x1;
    int idle = (g_spi.mode & 0x2) ? 1 : 0;
    int active = idle ? 0 : 1;
    unsigned bit;

    for (bit = 0; bit < 8u; ++bit) {
        _pinw(g_spi.mosi_pin, (out & 0x80u) ? 1 : 0);
        out <<= 1;

        spi_delay(g_spi.half_ticks);
        _pinw(g_spi.clk_pin, active);
        spi_delay(g_spi.half_ticks);
        if (!cpha) {
            in = (uint8_t)((in << 1) | (_pinr(g_spi.miso_pin) ? 1u : 0u));
        }

        _pinw(g_spi.clk_pin, idle);
        spi_delay(g_spi.half_ticks);
        if (cpha) {
            in = (uint8_t)((in << 1) | (_pinr(g_spi.miso_pin) ? 1u : 0u));
        }
    }

    return in;
}

static int m_spi_init(bvm *vm)
{
    int clk = berry_p2_bus_require_pin(vm, 1, "clk_pin must be an int");
    int mosi = berry_p2_bus_require_pin(vm, 2, "mosi_pin must be an int");
    int miso = berry_p2_bus_require_pin(vm, 3, "miso_pin must be an int");
    int cs = berry_p2_bus_require_pin(vm, 4, "cs_pin must be an int");
    int mode = spi_require_mode(vm, 5);
    unsigned khz = berry_p2_bus_require_khz(vm, 6, "khz must be an int");

    spi_setup_bus(clk, mosi, miso, cs, mode, khz);
    be_return_nil(vm);
}

static int m_spi_select(bvm *vm)
{
    berry_p2_bus_require_init(vm, g_spi.initialized, "spi.init() must be called first");
    _pinw(g_spi.cs_pin, 0);
    spi_apply_idle();
    be_return_nil(vm);
}

static int m_spi_deselect(bvm *vm)
{
    berry_p2_bus_require_init(vm, g_spi.initialized, "spi.init() must be called first");
    spi_apply_idle();
    _pinw(g_spi.cs_pin, 1);
    be_return_nil(vm);
}

static int m_spi_write(bvm *vm)
{
    berry_p2_bus_buffer tx = berry_p2_bus_get_buffer(vm, 1, "data must be a string, bytes, or list");
    size_t txlen = tx.length;
    size_t i;

    berry_p2_bus_require_init(vm, g_spi.initialized, "spi.init() must be called first");

    for (i = 0; i < txlen; ++i) {
        (void)spi_transfer_byte(tx.data[i]);
    }

    be_pushint(vm, (bint)txlen);
    berry_p2_bus_release_buffer(&tx);
    be_return(vm);
}

static int m_spi_read(bvm *vm)
{
    size_t count = berry_p2_bus_require_count(vm, 1, "count must be an int");
    uint8_t filler = 0xFFu;
    uint8_t *rx;
    size_t i;

    berry_p2_bus_require_init(vm, g_spi.initialized, "spi.init() must be called first");

    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        filler = berry_p2_bus_require_byte(vm, 2, "filler must be an int");
    }

    if (count == 0u) {
        be_pushstring(vm, "");
        be_return(vm);
    }

    rx = (uint8_t *)malloc(count);
    if (!rx) {
        be_raise(vm, "memory_error", "failed to allocate read buffer");
    }

    for (i = 0; i < count; ++i) {
        rx[i] = spi_transfer_byte(filler);
    }

    be_pushnstring(vm, (const char *)rx, count);
    free(rx);
    be_return(vm);
}

static int m_spi_transfer(bvm *vm)
{
    berry_p2_bus_buffer tx = berry_p2_bus_get_buffer(vm, 1, "data must be a string, bytes, or list");
    uint8_t *rx;
    size_t i;

    berry_p2_bus_require_init(vm, g_spi.initialized, "spi.init() must be called first");

    if (tx.length == 0u) {
        be_pushstring(vm, "");
        berry_p2_bus_release_buffer(&tx);
        be_return(vm);
    }

    rx = (uint8_t *)malloc(tx.length);
    if (!rx) {
        berry_p2_bus_release_buffer(&tx);
        be_raise(vm, "memory_error", "failed to allocate transfer buffer");
    }

    for (i = 0; i < tx.length; ++i) {
        rx[i] = spi_transfer_byte(tx.data[i]);
    }

    be_pushnstring(vm, (const char *)rx, tx.length);
    free(rx);
    berry_p2_bus_release_buffer(&tx);
    be_return(vm);
}

void be_cache_spimodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "spi");

    be_newmodule(vm);
    spi_module_set_func(vm, "init", m_spi_init);
    spi_module_set_func(vm, "select", m_spi_select);
    spi_module_set_func(vm, "deselect", m_spi_deselect);
    spi_module_set_func(vm, "write", m_spi_write);
    spi_module_set_func(vm, "read", m_spi_read);
    spi_module_set_func(vm, "transfer", m_spi_transfer);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
