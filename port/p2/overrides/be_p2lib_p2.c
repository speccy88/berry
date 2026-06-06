/********************************************************************
** Friendly Propeller 2 native module for Berry.
** This wraps the lower-level prop2_* globals with tutorial-sized names.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_mem.h"
#include "be_module.h"
#include "be_string.h"
#include "berry_conf_p2.h"
#include "berry_port.h"
#include "p2_build_info.h"
#include "p2_heap.h"

#include <propeller2.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#if defined(__CATALINA_libpsram) || defined(__CATALINA_PSRAM)
#include <psram.h>
#define P2_HAS_CATALINA_PSRAM 1
#else
#define P2_HAS_CATALINA_PSRAM 0
#endif

enum {
    P2_PSRAM_TRANSFER_MAX = 8192,
    P2_EDGE_SD_DO = 58,
    P2_EDGE_SD_DI = 59,
    P2_EDGE_SD_CS = 60,
    P2_EDGE_SD_CLK = 61,
    P2_EDGE_FLASH_DO = 58,
    P2_EDGE_FLASH_DI = 59,
    P2_EDGE_FLASH_CLK = 60,
    P2_EDGE_FLASH_CS = 61
};

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
extern int m_cog_start_c(bvm *vm);
extern int m_cog_start_pasm(bvm *vm);
extern int m_cog_start_hex(bvm *vm);
extern int m_cog_stop(bvm *vm);
extern int m_cog_check(bvm *vm);
extern int m_cog_id(bvm *vm);
extern int m_cog_states(bvm *vm);
extern int m_cog_stack_bytes(bvm *vm);
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

static void p2_map_set_int(bvm *vm, const char *key, bint value)
{
    be_pushstring(vm, key);
    be_pushint(vm, value);
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static void p2_map_set_bool(bvm *vm, const char *key, int value)
{
    be_pushstring(vm, key);
    be_pushbool(vm, value ? 1 : 0);
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static void p2_map_set_string(bvm *vm, const char *key, const char *value)
{
    be_pushstring(vm, key);
    be_pushstring(vm, value ? value : "");
    be_setindex(vm, -3);
    be_pop(vm, 2);
}

static void p2_map_set_u32_hex(bvm *vm, const char *key, uint32_t value)
{
    char buffer[11];

    snprintf(buffer, sizeof(buffer), "0x%08lX", (unsigned long)value);
    p2_map_set_string(vm, key, buffer);
}

static uint8_t p2_sd_probe_transfer(uint8_t value)
{
    uint8_t in = 0;
    int bit;

    for (bit = 0; bit < 8; ++bit) {
        if (value & 0x80u) {
            _pinh(P2_EDGE_SD_DI);
        } else {
            _pinl(P2_EDGE_SD_DI);
        }
        value <<= 1;
        _waitus(5);
        _pinh(P2_EDGE_SD_CLK);
        _waitus(5);
        in = (uint8_t)((in << 1) | (_pinr(P2_EDGE_SD_DO) ? 1u : 0u));
        _pinl(P2_EDGE_SD_CLK);
    }
    return in;
}

static uint8_t p2_flash_probe_transfer(uint8_t value)
{
    uint8_t in = 0;
    int bit;

    for (bit = 0; bit < 8; ++bit) {
        if (value & 0x80u) {
            _pinh(P2_EDGE_FLASH_DI);
        } else {
            _pinl(P2_EDGE_FLASH_DI);
        }
        value <<= 1;
        _waitus(1);
        _pinh(P2_EDGE_FLASH_CLK);
        _waitus(1);
        in = (uint8_t)((in << 1) | (_pinr(P2_EDGE_FLASH_DO) ? 1u : 0u));
        _pinl(P2_EDGE_FLASH_CLK);
    }
    return in;
}

static void p2_flash_probe_command(uint8_t cmd)
{
    _pinl(P2_EDGE_FLASH_CS);
    (void)p2_flash_probe_transfer(cmd);
    _pinh(P2_EDGE_FLASH_CS);
}

static void p2_sd_probe_flash_powerdown(void)
{
    _pinh(P2_EDGE_FLASH_CS);
    _pinl(P2_EDGE_FLASH_CLK);
    _pinl(P2_EDGE_FLASH_DI);
    _pinf(P2_EDGE_FLASH_DO);
    p2_flash_probe_command(0x66u);
    p2_flash_probe_command(0x99u);
    _waitms(1);
    p2_flash_probe_command(0xB9u);
    _waitus(10);
}

static void p2_sd_probe_deselect(void)
{
    _pinh(P2_EDGE_SD_CS);
    (void)p2_sd_probe_transfer(0xffu);
}

static void p2_sd_probe_idle(void)
{
    int i;

    _pinh(P2_EDGE_SD_CS);
    _pinl(P2_EDGE_SD_CLK);
    _pinh(P2_EDGE_SD_DI);
    _pinf(P2_EDGE_SD_DO);
    _waitms(1);
    for (i = 0; i < 10; ++i) {
        (void)p2_sd_probe_transfer(0xffu);
    }
}

static uint8_t p2_sd_probe_command(uint8_t cmd, uint32_t arg, uint8_t crc,
    uint8_t *extra, int extra_len, int keep_selected)
{
    uint8_t response = 0xffu;
    int i;

    p2_sd_probe_deselect();
    _pinl(P2_EDGE_SD_CS);
    (void)p2_sd_probe_transfer(0xffu);
    (void)p2_sd_probe_transfer((uint8_t)(0x40u | cmd));
    (void)p2_sd_probe_transfer((uint8_t)(arg >> 24));
    (void)p2_sd_probe_transfer((uint8_t)(arg >> 16));
    (void)p2_sd_probe_transfer((uint8_t)(arg >> 8));
    (void)p2_sd_probe_transfer((uint8_t)arg);
    (void)p2_sd_probe_transfer(crc);

    for (i = 0; i < 128; ++i) {
        response = p2_sd_probe_transfer(0xffu);
        if (response != 0xffu) {
            break;
        }
    }
    for (i = 0; i < extra_len; ++i) {
        extra[i] = p2_sd_probe_transfer(0xffu);
    }
    if (!keep_selected) {
        p2_sd_probe_deselect();
    }
    return response;
}

static const char *p2_fs_result_name(int result)
{
    switch (result) {
    case BERRY_P2_FS_RESULT_NOT_RUN:
        return "not_run";
    case -1:
        return "errmisc";
    case 0:
        return "ok";
    case 1:
        return "eof";
    case 2:
        return "write_protected";
    case 3:
        return "not_found";
    case 4:
        return "path_too_long";
    case 5:
        return "alloc_new_cluster";
    case 6:
        return "name_error";
    case 7:
        return "not_supported";
    case 0x100:
        return "sd_no_response";
    case BERRY_P2_FS_RESULT_SD_TIMEOUT:
        return "sd_timeout";
    case BERRY_P2_FS_RESULT_SD_BUSY:
        return "sd_busy";
    case BERRY_P2_FS_RESULT_SD_NO_SERVICE:
        return "sd_no_service";
    default:
        return "unknown";
    }
}

static void p2_map_set_fs_result(bvm *vm, const char *key, int result)
{
    char name_key[32];

    p2_map_set_int(vm, key, (bint)result);
    snprintf(name_key, sizeof(name_key), "%s_name", key);
    p2_map_set_string(vm, name_key, p2_fs_result_name(result));
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

static int m_p2_sbrk(bvm *vm)
{
    be_pushint(vm, (bint)p2_heap_free_bytes());
    be_return(vm);
}

static int m_p2_heap_info(bvm *vm)
{
    be_newobject(vm, "map");

    p2_map_set_int(vm, "current", (bint)p2_heap_free_bytes());
    p2_map_set_int(vm, "main", (bint)p2_heap_main_free_bytes());
    p2_map_set_int(vm, "worker", (bint)p2_heap_worker_free_bytes());
    p2_map_set_bool(vm, "external_heap", BE_P2_HEAP_USES_EXTERNAL_RAM);

    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_c_allocator_test(bvm *vm)
{
    bint requested = BE_P2_HEAP_USES_EXTERNAL_RAM ? (256 * 1024) : (8 * 1024);
    bint grown;
    unsigned char *buffer = NULL;
    unsigned char *grown_buffer = NULL;
    unsigned char *zeroed = NULL;
    unsigned long checksum = 0;
    const char *stage = "ok";
    int ok = 1;
    bint i;

    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        requested = be_toint(vm, 1);
    }
    if (requested < 1) {
        requested = 1;
    }
    if (requested > (1024 * 1024)) {
        requested = 1024 * 1024;
    }
    grown = requested + 1024;

    buffer = (unsigned char *)malloc((size_t)requested);
    if (!buffer) {
        ok = 0;
        stage = "malloc";
        goto done;
    }

    for (i = 0; i < requested; ++i) {
        buffer[i] = (unsigned char)((i * 31 + 7) & 0xff);
    }

    grown_buffer = (unsigned char *)realloc(buffer, (size_t)grown);
    if (!grown_buffer) {
        ok = 0;
        stage = "realloc";
        goto done;
    }
    buffer = NULL;

    for (i = 0; i < requested; ++i) {
        unsigned char expected = (unsigned char)((i * 31 + 7) & 0xff);
        checksum += grown_buffer[i];
        if (grown_buffer[i] != expected) {
            ok = 0;
            stage = "verify";
            goto done;
        }
    }
    for (i = requested; i < grown; ++i) {
        grown_buffer[i] = (unsigned char)((i * 17 + 3) & 0xff);
        checksum += grown_buffer[i];
    }

    zeroed = (unsigned char *)calloc(256u, 4u);
    if (!zeroed) {
        ok = 0;
        stage = "calloc";
        goto done;
    }
    for (i = 0; i < 1024; ++i) {
        if (zeroed[i] != 0) {
            ok = 0;
            stage = "calloc_verify";
            goto done;
        }
    }

done:
    free(zeroed);
    free(grown_buffer);
    free(buffer);

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", ok);
    p2_map_set_string(vm, "stage", stage);
    p2_map_set_int(vm, "requested", requested);
    p2_map_set_int(vm, "grown", grown);
    p2_map_set_int(vm, "checksum", (bint)(checksum & 0x7fffffffUL));
    p2_map_set_bool(vm, "external_heap", BE_P2_HEAP_USES_EXTERNAL_RAM);

    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_sd_raw_probe(bvm *vm)
{
    uint8_t extra[4] = { 0xffu, 0xffu, 0xffu, 0xffu };
    uint8_t cmd0;
    uint8_t cmd8;
    uint8_t cmd55 = 0xffu;
    uint8_t acmd41 = 0xffu;
    uint8_t cmd58;
    uint8_t cmd16;
    uint8_t cmd17 = 0xffu;
    uint8_t token = 0xffu;
    uint8_t first0 = 0xffu;
    uint8_t first1 = 0xffu;
    uint8_t sig0 = 0xffu;
    uint8_t sig1 = 0xffu;
    uint32_t cmd8_r7;
    uint32_t ocr;
    uint32_t sector = 0;
    uint32_t read_arg;
    int high_capacity;
    int tries;
    int i;

    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        bint value = be_toint(vm, 1);
        if (value > 0) {
            sector = (uint32_t)value;
        }
    }

    p2_sd_probe_idle();

    cmd0 = p2_sd_probe_command(0, 0, 0x95u, NULL, 0, 0);
    extra[0] = extra[1] = extra[2] = extra[3] = 0xffu;
    cmd8 = p2_sd_probe_command(8, 0x1aau, 0x87u, extra, 4, 0);
    cmd8_r7 = ((uint32_t)extra[0] << 24)
        | ((uint32_t)extra[1] << 16)
        | ((uint32_t)extra[2] << 8)
        | (uint32_t)extra[3];

    for (tries = 0; tries < 1000; ++tries) {
        cmd55 = p2_sd_probe_command(55, 0, 0x01u, NULL, 0, 1);
        acmd41 = p2_sd_probe_command(41, 0x40000000u, 0x01u, NULL, 0, 0);
        if (acmd41 == 0x00u || cmd55 > 0x01u) {
            break;
        }
        _waitms(1);
    }

    extra[0] = extra[1] = extra[2] = extra[3] = 0xffu;
    cmd58 = p2_sd_probe_command(58, 0, 0x01u, extra, 4, 0);
    ocr = ((uint32_t)extra[0] << 24)
        | ((uint32_t)extra[1] << 16)
        | ((uint32_t)extra[2] << 8)
        | (uint32_t)extra[3];
    high_capacity = (extra[0] & 0x40u) ? 1 : 0;

    cmd16 = p2_sd_probe_command(16, 512, 0x01u, NULL, 0, 0);

    read_arg = high_capacity ? sector : (sector << 9);
    cmd17 = p2_sd_probe_command(17, read_arg, 0x01u, NULL, 0, 1);
    if (cmd17 == 0x00u) {
        for (i = 0; i < 20000; ++i) {
            token = p2_sd_probe_transfer(0xffu);
            if (token == 0xfeu || (token & 0xf0u) == 0) {
                break;
            }
        }
        if (token == 0xfeu) {
            first0 = p2_sd_probe_transfer(0xffu);
            first1 = p2_sd_probe_transfer(0xffu);
            for (i = 2; i < 510; ++i) {
                (void)p2_sd_probe_transfer(0xffu);
            }
            sig0 = p2_sd_probe_transfer(0xffu);
            sig1 = p2_sd_probe_transfer(0xffu);
            (void)p2_sd_probe_transfer(0xffu);
            (void)p2_sd_probe_transfer(0xffu);
        }
    }
    p2_sd_probe_deselect();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "sector", (bint)sector);
    p2_map_set_int(vm, "cmd0", (bint)cmd0);
    p2_map_set_int(vm, "cmd8", (bint)cmd8);
    p2_map_set_u32_hex(vm, "cmd8_r7", cmd8_r7);
    p2_map_set_int(vm, "cmd55", (bint)cmd55);
    p2_map_set_int(vm, "acmd41", (bint)acmd41);
    p2_map_set_int(vm, "acmd41_tries", (bint)(tries + 1));
    p2_map_set_int(vm, "cmd58", (bint)cmd58);
    p2_map_set_u32_hex(vm, "ocr", ocr);
    p2_map_set_bool(vm, "high_capacity", high_capacity);
    p2_map_set_int(vm, "cmd16", (bint)cmd16);
    p2_map_set_int(vm, "cmd17", (bint)cmd17);
    p2_map_set_int(vm, "token", (bint)token);
    p2_map_set_int(vm, "first0", (bint)first0);
    p2_map_set_int(vm, "first1", (bint)first1);
    p2_map_set_int(vm, "sig0", (bint)sig0);
    p2_map_set_int(vm, "sig1", (bint)sig1);
    p2_map_set_int(vm, "signature", (bint)(((int)sig1 << 8) | (int)sig0));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_fs_info(bvm *vm)
{
    const char *path = "/";
    int write_probe = 0;
    int top = be_top(vm);
    berry_p2_fs_info info;

    if (top >= 1) {
        if (be_isstring(vm, 1)) {
            path = be_tostring(vm, 1);
        } else if (be_isbool(vm, 1) || be_isint(vm, 1)) {
            write_probe = be_tobool(vm, 1) ? 1 : 0;
        }
    }
    if (top >= 2) {
        if (be_isbool(vm, 2) || be_isint(vm, 2)) {
            write_probe = be_tobool(vm, 2) ? 1 : 0;
        } else if (be_isstring(vm, 2)) {
            path = be_tostring(vm, 2);
        }
    }

    p2_fs_info(path, write_probe, &info);

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "available", info.available);
    p2_map_set_bool(vm, "mounted", info.mounted);
    p2_map_set_bool(vm, "write_probe", write_probe);
    p2_map_set_string(vm, "cwd", info.cwd);
    p2_map_set_string(vm, "path", info.path);
    p2_map_set_string(vm, "fs_path", info.fs_path);
    p2_map_set_string(vm, "read_value", info.read_value);
    p2_map_set_int(vm, "root_entry_count", (bint)info.root_entry_count);
    p2_map_set_int(vm, "write_count", (bint)info.write_count);
    p2_map_set_int(vm, "read_count", (bint)info.read_count);
    p2_map_set_int(vm, "sector0_signature", (bint)info.sector0_signature);
    p2_map_set_int(vm, "sector0_byte0", (bint)info.sector0_byte0);
    p2_map_set_int(vm, "sector0_byte1", (bint)info.sector0_byte1);
    p2_map_set_int(vm, "sector0_byte2", (bint)info.sector0_byte2);
    p2_map_set_int(vm, "sector0_byte3", (bint)info.sector0_byte3);
    p2_map_set_int(vm, "sector0_sig0", (bint)info.sector0_sig0);
    p2_map_set_int(vm, "sector0_sig1", (bint)info.sector0_sig1);
    p2_map_set_int(vm, "sd_service_entry", (bint)info.sd_service_entry);
    p2_map_set_int(vm, "sd_service_cog", (bint)info.sd_service_cog);
    p2_map_set_int(vm, "sd_service_lock", (bint)info.sd_service_lock);
    p2_map_set_int(vm, "sd_service_code", (bint)info.sd_service_code);
    p2_map_set_int(vm, "sd_request", (bint)info.sd_request);
    p2_map_set_int(vm, "sd_response", (bint)info.sd_response);
    p2_map_set_int(vm, "fil_cog", (bint)info.fil_cog);
    p2_map_set_int(vm, "fil_registered_type", (bint)info.fil_registered_type);
    p2_map_set_int(vm, "partition_type", (bint)info.partition_type);
    p2_map_set_int(vm, "partition_active", (bint)info.partition_active);
    p2_map_set_int(vm, "partition_start", (bint)info.partition_start);
    p2_map_set_int(vm, "partition_size", (bint)info.partition_size);
    p2_map_set_int(vm, "filesystem_type", (bint)info.filesystem_type);
    p2_map_set_fs_result(vm, "sd_init_result", info.sd_init_result);
    p2_map_set_fs_result(vm, "raw_sector0_result", info.raw_sector0_result);
    p2_map_set_fs_result(vm, "dfs_sector0_result", info.dfs_sector0_result);
    p2_map_set_fs_result(vm, "volinfo_result", info.volinfo_result);
    p2_map_set_fs_result(vm, "mount_result", info.mount_result);
    p2_map_set_fs_result(vm, "resolve_result", info.resolve_result);
    p2_map_set_fs_result(vm, "root_open_result", info.root_open_result);
    p2_map_set_fs_result(vm, "root_first_result", info.root_first_result);
    p2_map_set_fs_result(vm, "path_read_result", info.path_read_result);
    p2_map_set_fs_result(vm, "path_dir_result", info.path_dir_result);
    p2_map_set_fs_result(vm, "create_file_result", info.create_file_result);
    p2_map_set_fs_result(vm, "write_file_result", info.write_file_result);
    p2_map_set_fs_result(vm, "read_file_result", info.read_file_result);
    p2_map_set_fs_result(vm, "unlink_file_result", info.unlink_file_result);

    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_info(bvm *vm)
{
    be_newobject(vm, "map");

    p2_map_set_bool(vm, "available", P2_HAS_CATALINA_PSRAM);
    p2_map_set_int(vm, "bytes", (bint)BE_P2_EXTERNAL_RAM_BYTES);
    p2_map_set_int(vm, "xmm_bytes", (bint)BE_P2_XMM_BYTES);
    p2_map_set_int(vm, "block_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "block_bytes",
        (bint)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE));
    p2_map_set_string(vm, "access",
        P2_HAS_CATALINA_PSRAM
            ? (BE_P2_HEAP_USES_EXTERNAL_RAM ? "xmm+block" : "block")
            : "none");
    p2_map_set_int(vm, "max_transfer", P2_HAS_CATALINA_PSRAM ? P2_PSRAM_TRANSFER_MAX : 0);
    p2_map_set_bool(vm, "heap", BE_P2_HEAP_USES_EXTERNAL_RAM);
    p2_map_set_int(vm, "reserved_pin_first", P2_HAS_CATALINA_PSRAM ? 40 : -1);
    p2_map_set_int(vm, "reserved_pin_last", P2_HAS_CATALINA_PSRAM ? 57 : -1);

    be_pop(vm, 1);
    be_return(vm);
}

static void p2_psram_require_available(bvm *vm)
{
    if (!P2_HAS_CATALINA_PSRAM) {
        be_raise(vm, "runtime_error", "not built with Catalina -lpsram");
    }
}

static void p2_psram_check_range(bvm *vm, bint address, bint size)
{
    if (address < 0) {
        be_raise(vm, "value_error", "address must be >= 0");
    }
    if (size < 0) {
        be_raise(vm, "value_error", "size must be >= 0");
    }
    if (size > P2_PSRAM_TRANSFER_MAX) {
        be_raise(vm, "value_error", "size exceeds p2.psram_info()[\"max_transfer\"]");
    }
    if (address < BE_P2_PSRAM_BLOCK_BASE) {
        be_raise(vm, "value_error", "range reserved for Catalina XMM");
    }
    if (address > BE_P2_EXTERNAL_RAM_BYTES || size > BE_P2_EXTERNAL_RAM_BYTES - address) {
        be_raise(vm, "value_error", "range outside PSRAM");
    }
}

static int m_p2_psram_read(bvm *vm)
{
    bint address = p2_require_int_arg(vm, 1, "address must be an int");
    bint size = p2_require_int_arg(vm, 2, "size must be an int");

    p2_psram_require_available(vm);
    p2_psram_check_range(vm, address, size);

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        char *buffer = be_malloc(vm, (size_t)size);
        int result = psram_read(buffer,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_free(vm, buffer, (size_t)size);
            be_raise(vm, "io_error", "PSRAM read failed");
        }
        be_pushnstring(vm, buffer, (size_t)size);
        be_free(vm, buffer, (size_t)size);
    } else {
        be_pushstring(vm, "");
    }
    be_return(vm);
#else
    be_return_nil(vm);
#endif
}

static int m_p2_psram_write(bvm *vm)
{
    bint address = p2_require_int_arg(vm, 1, "address must be an int");
    const void *data = NULL;
    size_t size = 0;
    int result = 0;

    p2_psram_require_available(vm);
    if (be_top(vm) < 2 || (!be_isstring(vm, 2) && !be_isbytes(vm, 2))) {
        be_raise(vm, "type_error", "data must be a string or bytes");
    }
    if (be_isstring(vm, 2)) {
        data = be_tostring(vm, 2);
        size = (size_t)be_strlen(vm, 2);
    } else {
        data = be_tobytes(vm, 2, &size);
    }
    if (size > (size_t)P2_PSRAM_TRANSFER_MAX) {
        be_raise(vm, "value_error", "data exceeds p2.psram_info()[\"max_transfer\"]");
    }
    p2_psram_check_range(vm, address, (bint)size);

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        result = psram_write((void *)data,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_raise(vm, "io_error", "PSRAM write failed");
        }
    }
#endif

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", result >= 0);
    p2_map_set_int(vm, "address", address);
    p2_map_set_int(vm, "size", (bint)size);
    p2_map_set_int(vm, "result", (bint)result);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_test(bvm *vm)
{
    enum {
        P2_PSRAM_TEST_SIZE = 32
    };
    bint address = (31 * 1024 * 1024);

    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        address = be_toint(vm, 1);
    }

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "available", P2_HAS_CATALINA_PSRAM);
    p2_map_set_int(vm, "bytes", (bint)BE_P2_EXTERNAL_RAM_BYTES);
    p2_map_set_int(vm, "address", address);
    p2_map_set_int(vm, "size", P2_PSRAM_TEST_SIZE);

#if P2_HAS_CATALINA_PSRAM
    {
        static const char pattern[] = "Berry P2 PSRAM smoke";
        char readback[P2_PSRAM_TEST_SIZE];
        int write_result;
        int read_result = 0;
        int ok = 0;

        if (address < 0 || address + P2_PSRAM_TEST_SIZE > BE_P2_EXTERNAL_RAM_BYTES) {
            p2_map_set_bool(vm, "ok", 0);
            p2_map_set_string(vm, "error", "address outside PSRAM");
        } else {
            memset(readback, 0, sizeof(readback));
            write_result = psram_write((void *)pattern,
                (void *)(uintptr_t)address,
                (int32_t)sizeof(pattern));
            if (write_result >= 0) {
                read_result = psram_read(readback,
                    (void *)(uintptr_t)address,
                    (int32_t)sizeof(readback));
                ok = read_result >= 0 && strcmp(readback, pattern) == 0;
            }
            p2_map_set_int(vm, "write_result", (bint)write_result);
            p2_map_set_int(vm, "read_result", (bint)read_result);
            p2_map_set_bool(vm, "ok", ok);
            p2_map_set_string(vm, "value", ok ? readback : "");
        }
    }
#else
    p2_map_set_bool(vm, "ok", 0);
    p2_map_set_string(vm, "error", "not built with Catalina -lpsram");
#endif

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
    unsigned long external_total = (unsigned long)BE_P2_EXTERNAL_RAM_BYTES;
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
    if (external_total > 0) {
        p2_status_writef("  external     %7lu B PSRAM %s, Berry heap in %s\n",
            external_total,
            P2_HAS_CATALINA_PSRAM ? "block API" : "not linked",
            BE_P2_HEAP_USES_EXTERNAL_RAM ? "PSRAM" : "Hub RAM");
    }
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

static void p2_status_info_build(bvm *vm)
{
    be_newobject(vm, "map");
    p2_map_set_string(vm, "date", P2_BUILD_DATE_STR);
    p2_map_set_string(vm, "time", P2_BUILD_TIME_STR);
    p2_map_set_string(vm, "profile", BE_P2_PROFILE_NAME);
    p2_map_set_string(vm, "board", BE_P2_BOARD_NAME);
    p2_map_set_string(vm, "silicon", BE_P2_SILICON_NAME);
    p2_map_set_int(vm, "led0_pin", (bint)BE_P2_BOARD_LED0_PIN);
    p2_map_set_int(vm, "led1_pin", (bint)BE_P2_BOARD_LED1_PIN);
    p2_map_set_int(vm, "board_has_psram", (bint)BE_P2_BOARD_HAS_PSRAM);
    p2_map_set_int(vm, "binary_bytes", (bint)P2_BUILD_BINARY_BYTES);
    p2_map_set_int(vm, "code_bytes", (bint)P2_BUILD_CODE_BYTES);
    p2_map_set_int(vm, "const_bytes", (bint)P2_BUILD_CONST_BYTES);
    p2_map_set_int(vm, "init_bytes", (bint)P2_BUILD_INIT_BYTES);
    p2_map_set_int(vm, "data_bytes", (bint)P2_BUILD_DATA_BYTES);
    p2_map_set_int(vm, "bytes_max", (bint)BE_BYTES_MAX_SIZE);
    p2_map_set_int(vm, "stack_slots", (bint)BE_STACK_TOTAL_MAX);
    be_pop(vm, 1);
}

static void p2_status_info_clock(bvm *vm)
{
    uint32_t mode = _clockmode();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "frequency", (bint)_clockfreq());
    p2_map_set_int(vm, "mode", (bint)mode);
    p2_map_set_u32_hex(vm, "mode_hex", mode);
    p2_map_set_int(vm, "ticks", (bint)_cnt());
    be_pop(vm, 1);
}

static void p2_status_info_memory(bvm *vm)
{
    unsigned long image = (unsigned long)P2_BUILD_BINARY_BYTES;
    unsigned long hub_total = (unsigned long)BE_P2_HUB_RAM_BYTES;
    unsigned long main_total = (unsigned long)BE_P2_HEAP_BYTES;
    unsigned long worker_total = (unsigned long)BE_P2_WORKER_HEAP_BYTES;
    unsigned long main_free = (unsigned long)p2_heap_main_free_bytes();
    unsigned long worker_free = (unsigned long)p2_heap_worker_free_bytes();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "hub_total", (bint)hub_total);
    p2_map_set_int(vm, "hub_image_used", (bint)(image <= hub_total ? image : hub_total));
    p2_map_set_int(vm, "main_heap_total", (bint)main_total);
    p2_map_set_int(vm, "main_heap_free", (bint)main_free);
    p2_map_set_int(vm, "main_heap_used", (bint)(main_total > main_free ? main_total - main_free : 0u));
    p2_map_set_int(vm, "worker_heap_total", (bint)worker_total);
    p2_map_set_int(vm, "worker_heap_free", (bint)worker_free);
    p2_map_set_int(vm, "worker_heap_used", (bint)(worker_total > worker_free ? worker_total - worker_free : 0u));
    p2_map_set_int(vm, "current_heap_free", (bint)p2_heap_free_bytes());
    p2_map_set_bool(vm, "external_heap", BE_P2_HEAP_USES_EXTERNAL_RAM);
    be_pop(vm, 1);
}

static void p2_status_info_psram(bvm *vm)
{
    be_newobject(vm, "map");
    p2_map_set_bool(vm, "available", P2_HAS_CATALINA_PSRAM);
    p2_map_set_int(vm, "bytes", (bint)BE_P2_EXTERNAL_RAM_BYTES);
    p2_map_set_int(vm, "xmm_bytes", (bint)BE_P2_XMM_BYTES);
    p2_map_set_int(vm, "block_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "block_bytes",
        (bint)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE));
    p2_map_set_string(vm, "access",
        P2_HAS_CATALINA_PSRAM
            ? (BE_P2_HEAP_USES_EXTERNAL_RAM ? "xmm+block" : "block")
            : "none");
    p2_map_set_int(vm, "max_transfer", P2_HAS_CATALINA_PSRAM ? P2_PSRAM_TRANSFER_MAX : 0);
    p2_map_set_bool(vm, "heap", BE_P2_HEAP_USES_EXTERNAL_RAM);
    p2_map_set_int(vm, "reserved_pin_first", P2_HAS_CATALINA_PSRAM ? 40 : -1);
    p2_map_set_int(vm, "reserved_pin_last", P2_HAS_CATALINA_PSRAM ? 57 : -1);
    be_pop(vm, 1);
}

static void p2_status_info_cogs(bvm *vm)
{
    int cog;
    int current = _cogid();

    be_newobject(vm, "list");
    for (cog = 0; cog < 8; ++cog) {
        int raw = _cogchk(cog);

        be_newobject(vm, "map");
        p2_map_set_int(vm, "id", (bint)cog);
        p2_map_set_bool(vm, "running", raw != 0);
        p2_map_set_int(vm, "raw", (bint)raw);
        p2_map_set_bool(vm, "current", cog == current);
        p2_map_set_int(vm, "stack_bytes", (bint)-1);
        be_pop(vm, 1);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
}

static int m_p2_status_info(bvm *vm)
{
    be_newobject(vm, "map");

    be_pushstring(vm, "build");
    p2_status_info_build(vm);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "runtime");
    be_newobject(vm, "map");
    p2_map_set_string(vm, "toolchain", "Catalina");
    p2_map_set_string(vm, "platform", "P2_EDGE");
    p2_map_set_string(vm, "memory_profile",
        P2_HAS_CATALINA_PSRAM
            ? (BE_P2_HEAP_USES_EXTERNAL_RAM ? "xmm+psram-block" : "psram-block")
            : "hub");
    be_pop(vm, 1);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "clock");
    p2_status_info_clock(vm);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "memory");
    p2_status_info_memory(vm);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "psram");
    p2_status_info_psram(vm);
    be_setindex(vm, -3);
    be_pop(vm, 2);

    be_pushstring(vm, "cogs");
    p2_status_info_cogs(vm);
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
    else if (!strcmp(name, "delay_us")) be_pushntvfunction(vm, m_p2_delay_us);
    else if (!strcmp(name, "cogid")) be_pushntvfunction(vm, m_p2_cogid);
    else if (!strcmp(name, "cog_id")) be_pushntvfunction(vm, m_cog_id);
    else if (!strcmp(name, "cog_start_c")) be_pushntvfunction(vm, m_cog_start_c);
    else if (!strcmp(name, "cog_start_pasm")) be_pushntvfunction(vm, m_cog_start_pasm);
    else if (!strcmp(name, "cog_start_hex")) be_pushntvfunction(vm, m_cog_start_hex);
    else if (!strcmp(name, "cog_stop")) be_pushntvfunction(vm, m_p2_cog_stop);
    else if (!strcmp(name, "cog_raw_stop")) be_pushntvfunction(vm, m_cog_stop);
    else if (!strcmp(name, "cog_check")) be_pushntvfunction(vm, m_cog_check);
    else if (!strcmp(name, "cog_states")) be_pushntvfunction(vm, m_p2_cog_states);
    else if (!strcmp(name, "cog_stack_bytes")) be_pushntvfunction(vm, m_cog_stack_bytes);
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
    else if (!strcmp(name, "c_allocator_test")) be_pushntvfunction(vm, m_p2_c_allocator_test);
    else if (!strcmp(name, "fs_info")) be_pushntvfunction(vm, m_p2_fs_info);
    else if (!strcmp(name, "sd_info")) be_pushntvfunction(vm, m_p2_fs_info);
    else if (!strcmp(name, "sd_raw_probe")) be_pushntvfunction(vm, m_p2_sd_raw_probe);
    else if (!strcmp(name, "psram_info")) be_pushntvfunction(vm, m_p2_psram_info);
    else if (!strcmp(name, "psram_read")) be_pushntvfunction(vm, m_p2_psram_read);
    else if (!strcmp(name, "psram_write")) be_pushntvfunction(vm, m_p2_psram_write);
    else if (!strcmp(name, "psram_test")) be_pushntvfunction(vm, m_p2_psram_test);
    else if (!strcmp(name, "status")) be_pushntvfunction(vm, m_p2_status);
    else if (!strcmp(name, "status_info")) be_pushntvfunction(vm, m_p2_status_info);
    else if (!strcmp(name, "debug_snapshot")) be_pushntvfunction(vm, m_p2_status_info);
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
