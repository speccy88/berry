/********************************************************************
** Friendly Propeller 2 native module for Berry.
** This wraps the lower-level prop2_* globals with tutorial-sized names.
********************************************************************/
#include "berry.h"
#include "be_bus_common_p2.h"
#include "be_gc.h"
#include "be_mem.h"
#include "be_module.h"
#include "be_object.h"
#include "be_string.h"
#include "be_var.h"
#include "be_vm.h"
#include "berry_conf_p2.h"
#include "berry_port.h"
#include "p2_build_info.h"
#include "p2_heap.h"

#include <propeller2.h>
#include <prop.h>
#include <cog.h>
#if defined(__CATALINA_LARGE)
#include <hmalloc.h>
#endif
#ifdef __CATALINA_libthreads
#include <threads.h>
#endif
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern int sbrk(int amount);
extern unsigned long _registry(void);

#if defined(__CATALINA_LARGE)
static const unsigned long p2_xmmd_array[] = {
#include "../runtime/p2_xmmd.inc"
};

static const unsigned long p2_xmmcache_array[] = {
#include "../runtime/p2_xmmcache.inc"
};

#include "../runtime/p2_xmml.inc"
#endif

#ifndef BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
#define BE_P2_ENABLE_ROADMAP_NATIVE_FACADES 0
#endif

#ifndef BE_P2_ENABLE_EXPERIMENTAL_VM_COG
#define BE_P2_ENABLE_EXPERIMENTAL_VM_COG 0
#endif

#ifndef BE_P2_ENABLE_EXPERIMENTAL_COG_PING
#define BE_P2_ENABLE_EXPERIMENTAL_COG_PING 0
#endif

#ifndef BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
#define BE_P2_ENABLE_UNSAFE_SHARED_VM_COG 0
#endif

#if defined(__CATALINA_libpsram) || defined(__CATALINA_PSRAM)
#include <psram.h>
#define P2_HAS_CATALINA_PSRAM 1
#else
#define P2_HAS_CATALINA_PSRAM 0
#endif

enum {
    P2_PSRAM_TRANSFER_MAX = 8192,
    P2_PSRAM_LIBSTORE_TOP_RESERVE = 1024 * 1024,
    P2_PSRAM_CACHE_MAX_ENTRIES = 16,
    P2_PSRAM_CACHE_OWNER_MAX = 31,
    P2_EDGE_SD_DO = 58,
    P2_EDGE_SD_DI = 59,
    P2_EDGE_SD_CS = 60,
    P2_EDGE_SD_CLK = 61,
    P2_EDGE_FLASH_DO = 58,
    P2_EDGE_FLASH_DI = 59,
    P2_EDGE_FLASH_CLK = 60,
    P2_EDGE_FLASH_CS = 61
};

typedef struct p2_psram_cache_entry {
    size_t address;
    size_t size;
    size_t used;
    size_t write_count;
    size_t last_write_offset;
    size_t last_write_size;
    uint32_t last_write_checksum;
    char owner[P2_PSRAM_CACHE_OWNER_MAX + 1];
} p2_psram_cache_entry;

static size_t p2_psram_cache_next;
static size_t p2_psram_cache_alloc_count;
static size_t p2_psram_cache_entry_count;
static p2_psram_cache_entry p2_psram_cache_entries[P2_PSRAM_CACHE_MAX_ENTRIES];

static void p2_psram_require_available(bvm *vm);
static int m_p2_closure_cog_stop(bvm *vm);
static int m_p2_closure_cog_blinker(bvm *vm);
static int m_p2_closure_cog_task(bvm *vm);
#if defined(__CATALINA_LARGE)
static int m_p2_closure_cog_task_kinds(bvm *vm);
static int m_p2_closure_cog_task_release(bvm *vm);
static int m_p2_closure_cog_task_info(bvm *vm);
static int m_p2_closure_cog_spawn_source(bvm *vm);
#endif
static int m_p2_closure_cog_is_task(bvm *vm);

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
extern volatile int *berry_vm_new_diag_stage_ptr;
extern volatile int berry_vm_new_skip_loadlibs;

enum {
    P2_PINMODE_INPUT = 0,
    P2_PINMODE_OUTPUT = 1,
    P2_PINMODE_OPENDRAIN = 2
};

enum {
    P2_CLOSURE_COG_MAX = 4,
    P2_CLOSURE_COG_ARGS_MAX = 8,
    P2_CLOSURE_COG_TEXT_MAX = 63,
    P2_CLOSURE_COG_DESCRIPTOR_MAX = 768,
    P2_CLOSURE_COG_STACK_DEFAULT = 8192,
    P2_CLOSURE_COG_STACK_NATIVE_BLINK = 2048,
    P2_CLOSURE_COG_HANDLE_BASE = 100,
    P2_CLOSURE_COG_IDLE_WAIT_MS = 1
};

#define P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED 0

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

#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
static uint32_t p2_require_u32_arg(bvm *vm, int index, const char *message)
{
    bint value = p2_require_int_arg(vm, index, message);

    if (value < 0) {
        be_raise(vm, "value_error", message);
    }
    return (uint32_t)value;
}
#endif

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

static int p2_sd_probe_swap_cs_clk;

static int p2_sd_probe_cs_pin(void)
{
    return p2_sd_probe_swap_cs_clk ? P2_EDGE_SD_CLK : P2_EDGE_SD_CS;
}

static int p2_sd_probe_clk_pin(void)
{
    return p2_sd_probe_swap_cs_clk ? P2_EDGE_SD_CS : P2_EDGE_SD_CLK;
}

static uint8_t p2_sd_probe_transfer(uint8_t value)
{
    uint8_t in = 0;
    int clk = p2_sd_probe_clk_pin();
    int bit;

    for (bit = 0; bit < 8; ++bit) {
        if (value & 0x80u) {
            _pinh(P2_EDGE_SD_DI);
        } else {
            _pinl(P2_EDGE_SD_DI);
        }
        value <<= 1;
        _waitus(5);
        _pinh(clk);
        _waitus(5);
        in = (uint8_t)((in << 1) | (_pinr(P2_EDGE_SD_DO) ? 1u : 0u));
        _pinl(clk);
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

static uint32_t p2_flash_probe_rdid(int release_powerdown)
{
    uint8_t b0;
    uint8_t b1;
    uint8_t b2;

    _pinh(P2_EDGE_FLASH_CS);
    _pinl(P2_EDGE_FLASH_CLK);
    _pinh(P2_EDGE_FLASH_DI);
    _pinf(P2_EDGE_FLASH_DO);
    _waitus(10);

    if (release_powerdown) {
        p2_flash_probe_command(0xABu);
        _waitus(40);
    }

    _pinl(P2_EDGE_FLASH_CS);
    (void)p2_flash_probe_transfer(0x9Fu);
    b0 = p2_flash_probe_transfer(0xffu);
    b1 = p2_flash_probe_transfer(0xffu);
    b2 = p2_flash_probe_transfer(0xffu);
    _pinh(P2_EDGE_FLASH_CS);
    _waitus(10);

    return ((uint32_t)b0 << 16) | ((uint32_t)b1 << 8) | (uint32_t)b2;
}

static void p2_sd_probe_flash_powerdown(void)
{
    int i;

    _pinh(P2_EDGE_FLASH_CS);
    _pinl(P2_EDGE_FLASH_CLK);
    _pinl(P2_EDGE_FLASH_DI);
    _pinf(P2_EDGE_FLASH_DO);
    p2_flash_probe_command(0x66u);
    p2_flash_probe_command(0x99u);
    _waitms(1);
    p2_flash_probe_command(0xB9u);
    _waitus(10);

    _pinh(P2_EDGE_FLASH_CS);
    _pinh(P2_EDGE_FLASH_DI);
    _pinf(P2_EDGE_FLASH_DO);
    for (i = 0; i < 10; ++i) {
        int bit;
        for (bit = 0; bit < 8; ++bit) {
            _pinh(P2_EDGE_FLASH_CLK);
            _waitus(2);
            _pinl(P2_EDGE_FLASH_CLK);
            _waitus(2);
        }
    }
}

static void p2_sd_probe_deselect(void)
{
    _pinh(p2_sd_probe_cs_pin());
    (void)p2_sd_probe_transfer(0xffu);
}

static void p2_sd_probe_idle(void)
{
    int i;

    _pinh(p2_sd_probe_cs_pin());
    _pinl(p2_sd_probe_clk_pin());
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
    _pinl(p2_sd_probe_cs_pin());
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

#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
static int m_p2_clock_set(bvm *vm)
{
    uint32_t mode = p2_require_u32_arg(vm, 1, "mode must be a non-negative int");
    uint32_t freq = p2_require_u32_arg(vm, 2, "freq must be a non-negative int");

    _clkset(mode, freq);
    be_return_nil(vm);
}

static int m_p2_hubset(bvm *vm)
{
    _hubset(p2_require_u32_arg(vm, 1, "value must be a non-negative int"));
    be_return_nil(vm);
}
#endif

static int m_p2_cogid(bvm *vm)
{
    be_pushint(vm, (bint)_cogid());
    be_return(vm);
}

static int m_p2_cog_stop(bvm *vm)
{
    bint cog = p2_require_int_arg(vm, 1, "cog_id must be an int");
    if (cog >= P2_CLOSURE_COG_HANDLE_BASE) {
        return m_p2_closure_cog_stop(vm);
    }
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

#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
static int m_p2_pin_dir_low(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);

    _dirl(pin);
    be_return_nil(vm);
}

static int m_p2_pin_dir_high(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);

    _dirh(pin);
    be_return_nil(vm);
}
#endif

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
    p2_map_set_int(vm, "main_requested", (bint)p2_heap_main_requested_size());
    p2_map_set_int(vm, "main_actual", (bint)p2_heap_main_size());
    p2_map_set_int(vm, "main_segments", (bint)p2_heap_main_segments());
    p2_map_set_int(vm, "main_base", (bint)(uintptr_t)p2_heap_main_base());
    p2_map_set_int(vm, "main_low", (bint)p2_heap_main_low_address());
    p2_map_set_int(vm, "main_high", (bint)p2_heap_main_high_address());
    p2_map_set_bool(vm, "main_crosses_block_window", p2_heap_main_crosses_block_window());
    p2_map_set_int(vm, "pointer_window_bytes", (bint)BE_P2_XMM_BYTES);
    p2_map_set_int(vm, "pointer_heap_limit", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "psram_block_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "psram_block_bytes",
        (bint)(BE_P2_EXTERNAL_RAM_BYTES > BE_P2_PSRAM_BLOCK_BASE
            ? BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE
            : 0));
    p2_map_set_bool(vm, "main_inside_pointer_window",
        !p2_heap_main_crosses_block_window() &&
        (BE_P2_PSRAM_BLOCK_BASE == 0 ||
            p2_heap_main_high_address() <= (size_t)BE_P2_PSRAM_BLOCK_BASE));
    p2_map_set_int(vm, "vm_partition_bytes", (bint)p2_heap_vm_partition_size());
    p2_map_set_int(vm, "vm_partition_capacity", (bint)p2_heap_main_vm_partition_capacity());
    p2_map_set_int(vm, "vm_partition_free_capacity", (bint)p2_heap_main_vm_partition_free_capacity());
    p2_map_set_int(vm, "vm_partition_remainder", (bint)p2_heap_main_vm_partition_remainder());
    p2_map_set_int(vm, "vm_partition_free_remainder", (bint)p2_heap_main_vm_partition_free_remainder());
    p2_map_set_int(vm, "vm_partition_max", (bint)BE_P2_VM_HEAP_MAX_PARTITIONS);
    p2_map_set_int(vm, "vm_partition_created", (bint)p2_heap_vm_partition_created_count());
    p2_map_set_int(vm, "vm_partition_total", (bint)p2_heap_vm_partition_total_bytes());
    p2_map_set_int(vm, "vm_partition_current", (bint)p2_heap_vm_partition_current());
    p2_map_set_int(vm, "wrong_free_count", (bint)p2_heap_wrong_free_count());
    p2_map_set_int(vm, "wrong_realloc_count", (bint)p2_heap_wrong_realloc_count());
    p2_map_set_bool(vm, "main_ready", p2_heap_main_ready());
    p2_map_set_bool(vm, "main_alloc_failed", p2_heap_main_alloc_failed());
    p2_map_set_bool(vm, "external_heap", BE_P2_HEAP_USES_EXTERNAL_RAM);
    p2_map_set_int(vm, "c_sbrk", (bint)sbrk(0));

    be_pop(vm, 1);
    be_return(vm);
}

typedef struct p2_child_vm_handle {
    bvm *child;
    size_t bytes;
    void *cog_stack;
    size_t cog_stack_size;
    volatile int cog_status;
    volatile int cog_id;
    volatile int cog_call_result;
    volatile int cog_function_found;
    volatile int cog_result_type;
    volatile bint cog_result_int;
    volatile int cog_result_bool;
    char cog_result_string[96];
    volatile int cog_child_stack_top;
    volatile size_t cog_wrong_free_delta;
    volatile size_t cog_wrong_realloc_delta;
    int active;
} p2_child_vm_handle;

static p2_child_vm_handle p2_child_vm_handles[BE_P2_VM_HEAP_MAX_PARTITIONS];
static int p2_child_vm_handles_ready;
static int p2_child_vm_runtime_lock = -2;
static volatile size_t p2_child_vm_runtime_lock_acquires;
static volatile size_t p2_child_vm_runtime_lock_contentions;
static volatile int p2_child_vm_runtime_lock_failed;

typedef struct p2_child_vm_cog_job {
    int slot;
    char name[64];
    int argc;
    int arg_type[8];
    bint arg_int[8];
    int arg_bool[8];
    char arg_string[8][96];
} p2_child_vm_cog_job;

static p2_child_vm_cog_job p2_child_vm_cog_jobs[BE_P2_VM_HEAP_MAX_PARTITIONS];

typedef struct p2_child_vm_cog_ping_job {
    volatile int status;
    volatile int cog_id;
    volatile int input;
    volatile int result;
} p2_child_vm_cog_ping_job;

typedef struct p2_child_vm_cog_once_job {
    volatile int status;
    volatile int cog_id;
    volatile int partition_ready;
    volatile int selected;
    volatile int child_created;
    volatile int child_deleted;
    volatile int function_found;
    volatile int vm_new_stage;
    volatile int vm_new_detail_stage;
    volatile int source_stage;
    volatile int load_stage;
    volatile int call_stage;
    volatile int execprotected_stage;
    volatile int return_top;
    volatile int return_is_function;
    volatile int post_call_top;
    volatile int result_slot_type;
    volatile int post_call_type_1;
    volatile int post_call_type_2;
    volatile int post_call_type_3;
    volatile int source_result;
    volatile int call_result;
    volatile int result_type;
    volatile bint result_int;
    volatile int result_bool;
    volatile int child_stack_top;
    volatile size_t wrong_free_delta;
    volatile size_t wrong_realloc_delta;
    int slot;
    size_t bytes;
    char source[512];
    char name[64];
    int argc;
    int arg_type[8];
    bint arg_int[8];
    int arg_bool[8];
    char arg_string[8][96];
    char result_string[96];
} p2_child_vm_cog_once_job;

static p2_child_vm_cog_once_job p2_child_vm_cog_once_jobs[BE_P2_VM_HEAP_MAX_PARTITIONS];

static int p2_child_vm_runtime_lock_enter(void);
static void p2_child_vm_runtime_lock_leave(int locked);

#if defined(__CATALINA_LARGE)
#define P2_COG_STACK_POOL_SLOTS 4
#define P2_COG_STACK_POOL_BYTES 8192
static union {
    unsigned char raw[P2_COG_STACK_POOL_BYTES];
    uint64_t align;
} p2_cog_stack_pool[P2_COG_STACK_POOL_SLOTS];
static int p2_cog_stack_pool_used[P2_COG_STACK_POOL_SLOTS];
#endif

static void *p2_cog_stack_alloc(size_t size)
{
#if defined(__CATALINA_LARGE)
    int i;

    if (size > P2_COG_STACK_POOL_BYTES) {
        return NULL;
    }
    for (i = 0; i < P2_COG_STACK_POOL_SLOTS; ++i) {
        if (!p2_cog_stack_pool_used[i]) {
            p2_cog_stack_pool_used[i] = 1;
            return p2_cog_stack_pool[i].raw;
        }
    }
    return NULL;
#else
    return p2_heap_malloc(size);
#endif
}

static void p2_cog_stack_free(void *ptr)
{
    if (ptr == NULL) {
        return;
    }
#if defined(__CATALINA_LARGE)
    int i;

    for (i = 0; i < P2_COG_STACK_POOL_SLOTS; ++i) {
        if (ptr == p2_cog_stack_pool[i].raw) {
            p2_cog_stack_pool_used[i] = 0;
            return;
        }
    }
#else
        p2_heap_free(ptr);
#endif
}

static void *p2_hub_mem_alloc(size_t size)
{
#if defined(__CATALINA_LARGE)
    return hub_malloc(size);
#else
    return p2_heap_malloc(size);
#endif
}

#if defined(__CATALINA_LARGE)
static void *p2_hub_mem_calloc(size_t count, size_t size)
{
    return hub_calloc(count, size);
}
#endif

static void p2_hub_mem_free(void *ptr)
{
    if (ptr == NULL) {
        return;
    }
#if defined(__CATALINA_LARGE)
    hub_free(ptr);
#else
    p2_heap_free(ptr);
#endif
}

#if defined(__CATALINA_LARGE)
static int p2_cog_marker_probe(int target_cog, uint32_t *marker_out, uint32_t *cog_out);
static int p2_cog_large_marker_probe(int target_cog, uint32_t *marker_out, uint32_t *cog_out);

typedef struct p2_xmm_private_cache {
    unsigned long *kernel;
    unsigned long *init;
    unsigned long *mailbox;
    unsigned long *buffer;
    unsigned long *child_kernel;
    unsigned long *child_lut;
    void *child_cog_data;
    int cache_cog;
} p2_xmm_private_cache;

static p2_xmm_private_cache p2_xmm_private_caches[8];
static volatile int p2_xmm_after_cache_pasm_cog = -1;
static volatile uint32_t p2_xmm_after_cache_pasm_marker = 0;
static volatile uint32_t p2_xmm_after_cache_pasm_seen = 0xffffffffu;
static volatile uint32_t p2_xmm_kernel_word0 = 0;
static volatile uint32_t p2_xmm_kernel_word90 = 0;
static volatile uint32_t p2_xmm_kernel_word91 = 0;
static volatile uint32_t p2_xmm_kernel_addr = 0;
static volatile uint32_t p2_xmm_cog_data_addr = 0;
static volatile int p2_xmm_large_pasm_cog = -1;
static volatile uint32_t p2_xmm_large_pasm_marker = 0;
static volatile uint32_t p2_xmm_large_pasm_seen = 0xffffffffu;
static volatile uint32_t p2_xmm_cog_data_word0_after = 0;
static volatile uint32_t p2_xmm_cog_data_word1_after = 0;
static volatile uint32_t p2_xmm_cog_data_word2_after = 0;
static volatile uint32_t p2_xmm_cog_data_word3_after = 0;
static volatile uint32_t p2_xmm_cog_data_word4_after = 0;
static volatile uint32_t p2_xmm_cog_data_word5_after = 0;
static volatile uint32_t p2_xmm_cog_data_word6_after = 0;
static volatile uint32_t p2_xmm_cog_data_word7_after = 0;

static void p2_xmm_private_cache_release(int child_cog)
{
    p2_xmm_private_cache *cache;

    if (child_cog < 0 || child_cog >= 8) {
        return;
    }
    cache = &p2_xmm_private_caches[child_cog];
    if (cache->kernel == NULL && cache->init == NULL && cache->mailbox == NULL && cache->buffer == NULL &&
            cache->child_kernel == NULL && cache->child_lut == NULL && cache->child_cog_data == NULL &&
            cache->cache_cog == 0) {
        cache->cache_cog = -1;
        return;
    }
    if (cache->cache_cog >= 0 && cache->cache_cog < 8 && _cogchk(cache->cache_cog)) {
        _cogstop(cache->cache_cog);
    }
    if (cache->cache_cog >= 0 && cache->cache_cog < 8) {
        volatile unsigned long *registry = (volatile unsigned long *)_registry();
        registry[cache->cache_cog] |= 0xff000000UL;
    }
    if (cache->kernel != NULL) {
        hub_free(cache->kernel);
    }
    if (cache->init != NULL) {
        hub_free(cache->init);
    }
    if (cache->mailbox != NULL) {
        hub_free(cache->mailbox);
    }
    if (cache->buffer != NULL) {
        hub_free(cache->buffer);
    }
    if (cache->child_kernel != NULL) {
        hub_free(cache->child_kernel);
    }
    if (cache->child_lut != NULL) {
        hub_free(cache->child_lut);
    }
    if (cache->child_cog_data != NULL) {
        hub_free(cache->child_cog_data);
    }
    memset(cache, 0, sizeof(*cache));
    cache->cache_cog = -1;
}

static int p2_xmm_private_cache_start(int child_cog)
{
    enum {
        P2_XMM_CACHE_BYTES = 8192,
        P2_XMM_CACHE_INDEX_WIDTH = 8,
        P2_XMM_CACHE_OFFSET_WIDTH = 5,
        P2_XMM_CACHE_TYPE = 29
    };

    p2_xmm_private_cache *cache;
    volatile unsigned long *registry;
    volatile unsigned long *request;
    unsigned long request_addr;
    int cache_cog;
    int wait_count;

    if (child_cog < 0 || child_cog >= 8) {
        return -1;
    }
    cache_cog = child_cog ^ 1;
    cache = &p2_xmm_private_caches[child_cog];
    p2_xmm_private_cache_release(child_cog);

    cache->cache_cog = cache_cog;
    cache->kernel = (unsigned long *)hub_malloc(sizeof(p2_xmmcache_array));
    cache->init = (unsigned long *)hub_malloc(4u * sizeof(unsigned long));
    cache->mailbox = (unsigned long *)hub_malloc(2u * sizeof(unsigned long));
    cache->buffer = (unsigned long *)hub_malloc(P2_XMM_CACHE_BYTES);
    if (cache->kernel == NULL || cache->init == NULL || cache->mailbox == NULL || cache->buffer == NULL) {
        p2_xmm_private_cache_release(child_cog);
        return -1;
    }

    memcpy(cache->kernel, p2_xmmcache_array, sizeof(p2_xmmcache_array));
    memset(cache->buffer, 0, P2_XMM_CACHE_BYTES);
    cache->mailbox[0] = 0xffffffffUL;
    cache->mailbox[1] = 0;
    cache->init[0] = (unsigned long)&cache->mailbox[0];
    cache->init[1] = (unsigned long)cache->buffer;
    cache->init[2] = P2_XMM_CACHE_INDEX_WIDTH;
    cache->init[3] = P2_XMM_CACHE_OFFSET_WIDTH;

    if (_coginit((int)cache->init >> 2, (int)cache->kernel >> 2, cache_cog) < 0) {
        p2_xmm_private_cache_release(child_cog);
        return -1;
    }
    wait_count = 0;
    while (cache->mailbox[0] != 0 && wait_count < 5000) {
        _waitus(1000);
        ++wait_count;
    }
    if (cache->mailbox[0] != 0) {
        p2_xmm_private_cache_release(child_cog);
        return -1;
    }

    registry = (volatile unsigned long *)_registry();
    request_addr = registry[cache_cog] & 0x00ffffffUL;
    request = (volatile unsigned long *)request_addr;
    request[0] = (1UL << P2_XMM_CACHE_OFFSET_WIDTH) - 1UL;
    request[1] = (unsigned long)&cache->mailbox[0];
    registry[cache_cog] = request_addr | ((unsigned long)P2_XMM_CACHE_TYPE << 24);
    return 0;
}

static int p2_catalina_cogstart_C(void func(void *), void *arg, void *stack_base, uint32_t stack_size)
{
    typedef struct p2_xmm_cog_data {
        unsigned long REG;
        unsigned long PC;
        unsigned long SP;
        unsigned long lsize;
        unsigned long laddr;
        unsigned long arg1;
        unsigned long arg2;
        unsigned long CS;
    } p2_xmm_cog_data;

    enum {
        P2_XMM_DYNAMIC_KERNEL_LONGS = 512,
        P2_XMM_CODE_SEGMENT_START = 0x00080200UL
    };

    unsigned long *kernel = NULL;
    unsigned long *lut = NULL;
    p2_xmm_cog_data *cog_data = NULL;
    p2_xmm_private_cache *cache;
    int cog = -1;
    int child_cog = -1;
    int candidate;
    volatile unsigned long *registry;
    size_t lut_bytes = (size_t)XMM_LUT_LIBRARY_BLOB_SIZE;
    int i;

    if (func == NULL || stack_base == NULL || stack_size == 0u) {
        return -1;
    }
    registry = (volatile unsigned long *)_registry();
    for (candidate = 2; candidate < 8; candidate += 2) {
        int pair_cog = candidate ^ 1;
        int candidate_inactive = ((registry[candidate] >> 24) == 0xffu);
        int pair_inactive = ((registry[pair_cog] >> 24) == 0xffu);
        if (candidate_inactive && pair_inactive && !_cogchk(candidate) && !_cogchk(pair_cog)) {
            child_cog = candidate;
            break;
        }
    }
    if (child_cog < 0) {
        return -1;
    }
    if (p2_xmm_private_cache_start(child_cog) != 0) {
        return -1;
    }
    p2_xmm_after_cache_pasm_cog = p2_cog_marker_probe(child_cog,
            (uint32_t *)&p2_xmm_after_cache_pasm_marker,
            (uint32_t *)&p2_xmm_after_cache_pasm_seen);
    p2_xmm_large_pasm_cog = p2_cog_large_marker_probe(child_cog,
            (uint32_t *)&p2_xmm_large_pasm_marker,
            (uint32_t *)&p2_xmm_large_pasm_seen);
    cache = &p2_xmm_private_caches[child_cog];
    kernel = (unsigned long *)hub_malloc(P2_XMM_DYNAMIC_KERNEL_LONGS * sizeof(unsigned long));
    lut = (unsigned long *)hub_malloc(lut_bytes);
    cog_data = (p2_xmm_cog_data *)hub_malloc(sizeof(*cog_data));
    if (kernel == NULL || lut == NULL || cog_data == NULL) {
        p2_xmm_private_cache_release(child_cog);
        if (kernel != NULL) {
            hub_free(kernel);
        }
        if (lut != NULL) {
            hub_free(lut);
        }
        if (cog_data != NULL) {
            hub_free(cog_data);
        }
        return -1;
    }
    cache->child_kernel = kernel;
    cache->child_lut = lut;
    cache->child_cog_data = cog_data;
    for (i = 0; i < P2_XMM_DYNAMIC_KERNEL_LONGS; ++i) {
        kernel[i] = p2_xmmd_array[i];
    }
    p2_xmm_kernel_word0 = (uint32_t)kernel[0];
    p2_xmm_kernel_word90 = (uint32_t)kernel[90];
    p2_xmm_kernel_word91 = (uint32_t)kernel[91];
    p2_xmm_kernel_addr = (uint32_t)kernel;
    p2_xmm_cog_data_addr = (uint32_t)cog_data;
    memcpy(lut, XMM_LUT_LIBRARY_array, lut_bytes);

    cog_data->REG = (unsigned long)_registry();
    cog_data->PC = (unsigned long)func;
    cog_data->SP = (unsigned long)stack_base + stack_size;
    cog_data->lsize = (unsigned long)((XMM_LUT_LIBRARY_BLOB_SIZE / 4) - 1u);
    cog_data->laddr = (unsigned long)lut;
    cog_data->arg1 = (unsigned long)arg;
    cog_data->arg2 = (unsigned long)arg;
    cog_data->CS = P2_XMM_CODE_SEGMENT_START;

    cog = _cogstart_PASM(child_cog, kernel, cog_data);
    _waitcnt(_cnt() + (_clockfreq() / 20));
    if (cog < 0) {
        p2_xmm_private_cache_release(child_cog);
    }
    return cog;
}
#else
#define p2_catalina_cogstart_C(func, arg, stack_base, stack_size) _cogstart_C((func), (arg), (stack_base), (stack_size))
#endif

enum {
    P2_NATIVE_BLINK_STATUS = 0,
    P2_NATIVE_BLINK_STOP,
    P2_NATIVE_BLINK_PIN,
    P2_NATIVE_BLINK_PERIOD_MS,
    P2_NATIVE_BLINK_COGID,
    P2_NATIVE_BLINK_CALLS,
    P2_NATIVE_BLINK_MS_TICKS,
    P2_NATIVE_BLINK_MAILBOX_LONGS
};

static const uint32_t p2_native_blink_pasm[] = {
    0xf60055f8u, 0xfd606201u, 0xf600562au, 0xf1045610u,
    0xfc60622bu, 0xf600562au, 0xf1045608u, 0xfb00582bu,
    0xf600562au, 0xf104560cu, 0xfb005a2bu, 0xf600562au,
    0xf1045618u, 0xfb005c2bu, 0xfd605859u, 0xfd605e1au,
    0xf6046201u, 0xfc60622au, 0xf600562au, 0xf1045604u,
    0xfb08622bu, 0x5d90003cu, 0xf600602du, 0xfa605e2eu,
    0xfd602224u, 0xf600562au, 0xf1045604u, 0xfb08622bu,
    0x5d900020u, 0xfb6c61f9u, 0xfd60585fu, 0xf600562au,
    0xf1045614u, 0xfb00622bu, 0xf1046201u, 0xfc60622bu,
    0xfd9fffb4u, 0xfd605850u, 0xf6046202u, 0xfc60622au,
    0xfd606201u, 0xfd606203u, 0x00000000u, 0x00000000u,
    0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
    0x00000000u, 0x00000000u
};

static const uint32_t p2_cog_marker_pasm[] = {
    0xf60011f8u, 0xff2d52adu, 0xf60412a5u, 0xfc601208u,
    0xfd601201u, 0xf1041004u, 0xfc601208u, 0xfd601203u,
    0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u,
    0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u
};

static int p2_cog_marker_probe(int target_cog, uint32_t *marker_out, uint32_t *cog_out)
{
    uint32_t *program;
    uint32_t *mailbox;
    int cog;
    int wait_ms;

    if (marker_out != NULL) {
        *marker_out = 0;
    }
    if (cog_out != NULL) {
        *cog_out = 0xffffffffu;
    }
    program = (uint32_t *)p2_hub_mem_alloc(sizeof(p2_cog_marker_pasm));
    mailbox = (uint32_t *)p2_hub_mem_alloc(2u * sizeof(uint32_t));
    if (program == NULL || mailbox == NULL) {
        if (program != NULL) {
            p2_hub_mem_free(program);
        }
        if (mailbox != NULL) {
            p2_hub_mem_free(mailbox);
        }
        return -1;
    }
    memcpy(program, p2_cog_marker_pasm, sizeof(p2_cog_marker_pasm));
    mailbox[0] = 0;
    mailbox[1] = 0xffffffffu;
    cog = _cogstart_PASM(target_cog, program, mailbox);
    for (wait_ms = 0; cog >= 0 && wait_ms < 50 && mailbox[0] == 0; ++wait_ms) {
        _waitms(1);
    }
    if (marker_out != NULL) {
        *marker_out = mailbox[0];
    }
    if (cog_out != NULL) {
        *cog_out = mailbox[1];
    }
    if (cog >= 0 && _cogchk(cog)) {
        _cogstop(cog);
    }
    p2_hub_mem_free(mailbox);
    p2_hub_mem_free(program);
    return cog;
}

static int p2_cog_large_marker_probe(int target_cog, uint32_t *marker_out, uint32_t *cog_out)
{
    static const uint32_t probe_words[] = {
        0xf600c5f8u, 0xff35db35u, 0xf604c7b6u, 0xfc60c662u,
        0xfd60c601u, 0xf104c404u, 0xfc60c662u, 0xfd60c603u
    };
    uint32_t *program;
    uint32_t *mailbox;
    int cog;
    int wait_ms;
    int i;

    if (marker_out != NULL) {
        *marker_out = 0;
    }
    if (cog_out != NULL) {
        *cog_out = 0xffffffffu;
    }
    program = (uint32_t *)p2_hub_mem_alloc(512u * sizeof(uint32_t));
    mailbox = (uint32_t *)p2_hub_mem_alloc(2u * sizeof(uint32_t));
    if (program == NULL || mailbox == NULL) {
        if (program != NULL) {
            p2_hub_mem_free(program);
        }
        if (mailbox != NULL) {
            p2_hub_mem_free(mailbox);
        }
        return -1;
    }
    memset(program, 0, 512u * sizeof(uint32_t));
    program[0] = 0xfd900164u;
    for (i = 0; i < (int)(sizeof(probe_words) / sizeof(probe_words[0])); ++i) {
        program[90 + i] = probe_words[i];
    }
    mailbox[0] = 0;
    mailbox[1] = 0xffffffffu;
    cog = _cogstart_PASM(target_cog, program, mailbox);
    for (wait_ms = 0; cog >= 0 && wait_ms < 50 && mailbox[0] == 0; ++wait_ms) {
        _waitms(1);
    }
    if (marker_out != NULL) {
        *marker_out = mailbox[0];
    }
    if (cog_out != NULL) {
        *cog_out = mailbox[1];
    }
    if (cog >= 0 && _cogchk(cog)) {
        _cogstop(cog);
    }
    p2_hub_mem_free(mailbox);
    p2_hub_mem_free(program);
    return cog;
}

static void p2_child_vm_cog_ping_entry(void *arg)
{
    p2_child_vm_cog_ping_job *job = (p2_child_vm_cog_ping_job *)arg;

    if (job == NULL) {
        return;
    }
    job->status = 1;
    job->cog_id = _cogid();
    job->result = (job->input * 2) + 1;
    _waitus(1000);
    job->status = 2;
    while (job->status != 3) {
        _waitus(1000);
    }
}

#ifdef __CATALINA_libthreads
static int p2_child_vm_thread_ping_entry(int argc, char *argv[])
{
    p2_child_vm_cog_ping_job *job = NULL;

    (void)argc;
    if (argv != NULL) {
        job = (p2_child_vm_cog_ping_job *)argv;
    }
    if (job == NULL) {
        return -1;
    }
    job->status = 1;
    job->cog_id = _cogid();
    job->result = (job->input * 2) + 1;
    _thread_wait(1);
    job->status = 2;
    return job->result;
}
#endif

static void p2_child_vm_cog_once_entry(void *arg)
{
    p2_child_vm_cog_once_job *job = (p2_child_vm_cog_once_job *)arg;
    bvm *child = NULL;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    int i;

    if (job == NULL || job->slot < 0 || job->slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return;
    }
    job->status = 1;
    job->cog_id = _cogid();
    job->partition_ready = 0;
    job->selected = 0;
    job->child_created = 0;
    job->child_deleted = 0;
    job->function_found = 0;
    job->vm_new_stage = 0;
    job->vm_new_detail_stage = 0;
    job->source_stage = 0;
    job->load_stage = 0;
    job->call_stage = 0;
    job->execprotected_stage = 0;
    job->return_top = 0;
    job->return_is_function = 0;
    job->post_call_top = 0;
    job->result_slot_type = -1;
    job->post_call_type_1 = -1;
    job->post_call_type_2 = -1;
    job->post_call_type_3 = -1;
    job->source_result = BE_SYNTAX_ERROR;
    job->call_result = BE_SYNTAX_ERROR;
    job->result_type = 0;
    job->result_int = 0;
    job->result_bool = 0;
    job->result_string[0] = '\0';
    job->child_stack_top = 0;
    job->wrong_free_delta = 0;
    job->wrong_realloc_delta = 0;

    {
        int runtime_locked = p2_child_vm_runtime_lock_enter();

        wrong_free_before = p2_heap_wrong_free_count();
        wrong_realloc_before = p2_heap_wrong_realloc_count();
        job->partition_ready = p2_heap_vm_partition_create(job->slot, job->bytes);
        if (job->partition_ready) {
            job->selected = p2_heap_vm_partition_select(job->slot);
        }
        if (job->selected) {
            job->vm_new_stage = 1;
            berry_vm_new_diag_stage_ptr = &job->vm_new_detail_stage;
            berry_vm_new_skip_loadlibs = 1;
            child = be_vm_new();
            berry_vm_new_skip_loadlibs = 0;
            berry_vm_new_diag_stage_ptr = NULL;
            job->vm_new_stage = child != NULL ? 2 : -1;
        }
        if (child != NULL) {
            job->child_created = 1;
            job->source_stage = 1;
            job->load_stage = 1;
            if (job->name[0] != '\0') {
                (void)be_global_new(child, be_newstr(child, job->name));
            }
            job->source_result = be_loadbuffer(child, "cog_source", job->source, strlen(job->source));
            job->load_stage = 2;
            if (job->source_result == BE_OK) {
                job->call_stage = 1;
                job->source_result = be_pcall(child, 0);
                job->call_stage = 2;
            }
            job->source_stage = 2;
            if (job->source_result == BE_OK) {
                job->return_top = be_top(child);
                job->return_is_function = (job->return_top > 0 && be_isfunction(child, -1));
                if (!strcmp(job->name, "$return")) {
                    if (be_top(child) > 0 && be_isfunction(child, -1)) {
                        job->function_found = 1;
                    } else if (be_top(child) > 1 && be_isfunction(child, -2)) {
                        be_pop(child, 1);
                        job->function_found = 1;
                    } else if (be_top(child) > 0) {
                        int result_index = -1;
                        int stack_top = be_top(child);
                        int result_scan;

                        for (result_scan = -1; result_scan >= -stack_top; --result_scan) {
                            if (be_isint(child, result_scan)) {
                                result_index = result_scan;
                                break;
                            }
                        }

                        if (be_isint(child, result_index)) {
                            job->result_type = 1;
                            job->result_int = be_toint(child, result_index);
                        } else if (be_isbool(child, result_index)) {
                            job->result_type = 2;
                            job->result_bool = be_tobool(child, result_index);
                        } else if (be_isnil(child, result_index)) {
                            job->result_type = 3;
                        } else if (be_isstring(child, result_index)) {
                            const char *text = be_tostring(child, result_index);

                            job->result_type = 4;
                            if (text != NULL) {
                                strncpy(job->result_string, text, sizeof(job->result_string) - 1);
                                job->result_string[sizeof(job->result_string) - 1] = '\0';
                            }
                        }
                        job->call_result = BE_OK;
                    }
                } else {
                    be_pop(child, be_top(child));
                    job->function_found = be_getglobal(child, job->name);
                }
                if (job->function_found) {
                    bvalue *result_slot;

                    for (i = 0; i < job->argc; ++i) {
                        switch (job->arg_type[i]) {
                        case 1:
                            be_pushint(child, job->arg_int[i]);
                            break;
                        case 2:
                            be_pushbool(child, job->arg_bool[i]);
                            break;
                        case 3:
                            be_pushnil(child);
                            break;
                        case 4:
                            be_pushstring(child, job->arg_string[i]);
                            break;
                        default:
                            be_pushnil(child);
                            break;
                        }
                    }
                    result_slot = child->top - job->argc - 1;
                    job->call_result = be_pcall(child, job->argc);
                    if (job->call_result == BE_OK) {
                        job->post_call_top = be_top(child);
                        job->result_slot_type = var_type(result_slot);
                        if (be_top(child) >= 1) {
                            job->post_call_type_1 = var_type(child->top - 1);
                        }
                        if (be_top(child) >= 2) {
                            job->post_call_type_2 = var_type(child->top - 2);
                        }
                        if (be_top(child) >= 3) {
                            job->post_call_type_3 = var_type(child->top - 3);
                        }
                        if (var_isint(result_slot)) {
                            job->result_type = 1;
                            job->result_int = var_toint(result_slot);
                        } else if (var_isbool(result_slot)) {
                            job->result_type = 2;
                            job->result_bool = var_tobool(result_slot);
                        } else if (var_isnil(result_slot)) {
                            job->result_type = 3;
                        } else if (var_isstr(result_slot)) {
                            const char *text = str(var_tostr(result_slot));

                            job->result_type = 4;
                            if (text != NULL) {
                                strncpy(job->result_string, text, sizeof(job->result_string) - 1);
                                job->result_string[sizeof(job->result_string) - 1] = '\0';
                            }
                        }
                    }
                }
            }
            be_pop(child, be_top(child));
            job->child_stack_top = be_top(child);
            be_vm_delete(child);
            job->child_deleted = 1;
        }
        p2_heap_vm_partition_clear_current();
        job->wrong_free_delta = p2_heap_wrong_free_count() - wrong_free_before;
        job->wrong_realloc_delta = p2_heap_wrong_realloc_count() - wrong_realloc_before;
        p2_child_vm_runtime_lock_leave(runtime_locked);
    }

    job->status = 2;
    while (job->status != 4) {
        _waitus(1000);
    }
}

static void p2_child_vm_runtime_lock_init(void)
{
    if (p2_child_vm_runtime_lock == -2) {
        int lock = LOCKNEW;

        if (lock >= 0) {
            p2_child_vm_runtime_lock = lock;
        } else {
            p2_child_vm_runtime_lock = -1;
            p2_child_vm_runtime_lock_failed = 1;
        }
    }
}

static int p2_child_vm_runtime_lock_enter(void)
{
    int lock;

    p2_child_vm_runtime_lock_init();
    lock = p2_child_vm_runtime_lock;
    if (lock < 0) {
        return 0;
    }
    while (LOCKSET(lock)) {
        ++p2_child_vm_runtime_lock_contentions;
        _waitus(10);
    }
    ++p2_child_vm_runtime_lock_acquires;
    return 1;
}

static void p2_child_vm_runtime_lock_leave(int locked)
{
    if (locked && p2_child_vm_runtime_lock >= 0) {
        LOCKCLR(p2_child_vm_runtime_lock);
    }
}

typedef struct p2_closure_cog_slot {
    int used;
    bvm *vm;
    void *stack;
    size_t stack_size;
    bint handle;
    volatile int stop;
    volatile int status;
    volatile int cog_id;
    volatile int period_ms;
    volatile int native_pin;
    volatile int native_blink;
    volatile int descriptor_task;
    volatile int setup_function;
    volatile int setup_descriptor_return;
    volatile int task_kind;
    volatile int isolated_source;
    p2_child_vm_cog_once_job *source_job;
#if defined(__CATALINA_LARGE)
    volatile uint32_t *native_mailbox;
#else
    volatile uint32_t native_mailbox[P2_NATIVE_BLINK_MAILBOX_LONGS];
#endif
    volatile int argc;
    int arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
    volatile size_t call_count;
    volatile int call_result;
    volatile int last_result_type;
    volatile bint last_result_int;
    volatile int last_result_bool;
    volatile int stop_wait_ms;
    char closure_name[64];
    char last_error[64];
} p2_closure_cog_slot;

static p2_closure_cog_slot p2_closure_cog_slots[P2_CLOSURE_COG_MAX];
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
static volatile int p2_closure_cog_main_idle;
static int p2_closure_cog_main_vm_locked;
#endif

void p2_closure_cog_repl_idle(int idle)
{
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    if (idle) {
        p2_closure_cog_main_idle = 1;
        p2_child_vm_runtime_lock_leave(p2_closure_cog_main_vm_locked);
        p2_closure_cog_main_vm_locked = 0;
    } else {
        p2_closure_cog_main_idle = 0;
        if (!p2_closure_cog_main_vm_locked) {
            p2_closure_cog_main_vm_locked = p2_child_vm_runtime_lock_enter();
        }
    }
#else
    (void)idle;
#endif
}

#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
static int p2_closure_cog_runtime_lock_enter(p2_closure_cog_slot *slot)
{
    int lock;

    p2_child_vm_runtime_lock_init();
    lock = p2_child_vm_runtime_lock;
    if (lock < 0) {
        return 0;
    }
    while (LOCKSET(lock)) {
        ++p2_child_vm_runtime_lock_contentions;
        if (slot == NULL || slot->stop || !p2_closure_cog_main_idle) {
            return 0;
        }
        _waitus(10);
    }
    if (slot != NULL && (slot->stop || !p2_closure_cog_main_idle)) {
        LOCKCLR(lock);
        return 0;
    }
    ++p2_child_vm_runtime_lock_acquires;
    return 1;
}
#endif

static int p2_closure_cog_slot_from_handle(bint handle)
{
    bint slot = handle - P2_CLOSURE_COG_HANDLE_BASE;

    if (slot < 0 || slot >= P2_CLOSURE_COG_MAX) {
        return -1;
    }
    return (int)slot;
}

static void p2_closure_cog_capture_function_name(bvm *vm, int index, p2_closure_cog_slot *slot)
{
    bvalue *value;
    bclosure *closure;
    const char *name;

    if (!vm || !slot || !be_isclosure(vm, index)) {
        return;
    }
    value = be_indexof(vm, index);
    closure = (bclosure *)var_toobj(value);
    if (!closure || !closure->proto || !closure->proto->name) {
        return;
    }
    name = str(closure->proto->name);
    if (!name || !name[0] || !strcmp(name, "_anonymous_")) {
        return;
    }
    strncpy(slot->closure_name, name, sizeof(slot->closure_name) - 1);
    slot->closure_name[sizeof(slot->closure_name) - 1] = '\0';
}

#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
static void p2_closure_cog_registry_init(bvm *vm)
{
    int i;

    if (be_getglobal(vm, "__p2_closure_cogs")) {
        be_pop(vm, 1);
        return;
    }
    be_pop(vm, 1);
    be_newobject(vm, "list");
    for (i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
        be_pushnil(vm);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_setglobal(vm, "__p2_closure_cogs");
    be_pop(vm, 1);
}

static void p2_closure_cog_registry_set(bvm *vm, int slot, int value_index)
{
    int abs_value = be_absindex(vm, value_index);

    p2_closure_cog_registry_init(vm);
    (void)be_getglobal(vm, "__p2_closure_cogs");
    be_pushint(vm, (bint)slot);
    be_pushvalue(vm, abs_value);
    (void)be_setindex(vm, -3);
    be_pop(vm, 3);
}

static void p2_closure_cog_registry_clear(bvm *vm, int slot)
{
    p2_closure_cog_registry_init(vm);
    (void)be_getglobal(vm, "__p2_closure_cogs");
    be_pushint(vm, (bint)slot);
    be_pushnil(vm);
    (void)be_setindex(vm, -3);
    be_pop(vm, 3);
}
#endif

static void p2_closure_cog_capture_exception(bvm *vm, p2_closure_cog_slot *slot)
{
    const char *msg = NULL;

    if (be_top(vm) >= 1 && be_isstring(vm, -1)) {
        msg = be_tostring(vm, -1);
    }
    if (!msg && be_top(vm) >= 2 && be_isstring(vm, -2)) {
        msg = be_tostring(vm, -2);
    }
    if (!msg) {
        msg = "closure cog callback failed";
    }
    strncpy(slot->last_error, msg, sizeof(slot->last_error) - 1);
    slot->last_error[sizeof(slot->last_error) - 1] = '\0';
}

static void p2_closure_cog_push_arg(bvm *vm, p2_closure_cog_slot *slot, int index)
{
    switch (slot->arg_type[index]) {
    case 1:
        be_pushint(vm, slot->arg_int[index]);
        break;
    case 2:
        be_pushbool(vm, slot->arg_bool[index]);
        break;
    case 3:
        be_pushnil(vm);
        break;
    case 4:
        be_pushstring(vm, slot->arg_string[index]);
        break;
    default:
        be_pushnil(vm);
        break;
    }
}

#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
static int p2_closure_cog_call_once(p2_closure_cog_slot *slot)
{
    bvm *vm = slot->vm;
    int top_before;
    int callable = 0;
    int result_index;
    int i;

    if (vm == NULL) {
        return 0;
    }
    top_before = be_top(vm);
    if (be_getglobal(vm, "__p2_closure_cogs")) {
        be_pushint(vm, slot->handle - P2_CLOSURE_COG_HANDLE_BASE);
        callable = be_getindex(vm, -2);
        be_remove(vm, -2);
        be_remove(vm, -2);
    }
    if (!callable || !be_isfunction(vm, -1)) {
        be_pop(vm, be_top(vm) - top_before);
        strncpy(slot->last_error, "closure cog callback is not callable", sizeof(slot->last_error) - 1);
        slot->last_error[sizeof(slot->last_error) - 1] = '\0';
        slot->call_result = BE_EXCEPTION;
        return 0;
    }
    for (i = 0; i < slot->argc; ++i) {
        p2_closure_cog_push_arg(vm, slot, i);
    }
    slot->call_result = be_pcall(vm, slot->argc);
    if (slot->call_result != BE_OK) {
        p2_closure_cog_capture_exception(vm, slot);
        be_pop(vm, be_top(vm) - top_before);
        return 0;
    }
    ++slot->call_count;
    result_index = -(slot->argc + 1);
    slot->last_result_type = 0;
    slot->last_result_int = 0;
    slot->last_result_bool = 0;
    if (be_top(vm) > top_before) {
        if (be_isbool(vm, result_index)) {
            slot->last_result_type = 2;
            slot->last_result_bool = be_tobool(vm, result_index);
            if (!slot->last_result_bool) {
                be_pop(vm, be_top(vm) - top_before);
                return 0;
            }
        } else if (be_isnil(vm, result_index)) {
            slot->last_result_type = 3;
            be_pop(vm, be_top(vm) - top_before);
            return 0;
        } else if (be_isint(vm, result_index)) {
            slot->last_result_type = 1;
            slot->last_result_int = be_toint(vm, result_index);
            if (slot->last_result_int < 0) {
                be_pop(vm, be_top(vm) - top_before);
                return 0;
            }
            slot->period_ms = (int)slot->last_result_int;
        }
    }
    be_pop(vm, be_top(vm) - top_before);
    return 1;
}
#endif

static void p2_closure_cog_setup_native_blink(bvm *vm, p2_closure_cog_slot *slot)
{
    (void)vm;

    slot->call_result = BE_OK;
    slot->last_result_type = 1;
    slot->last_result_int = (bint)slot->period_ms;
    slot->last_result_bool = 0;
}

static void p2_closure_cog_sync_native_blink(p2_closure_cog_slot *slot)
{
    if (slot == NULL || !slot->native_blink) {
        return;
    }
#if defined(__CATALINA_LARGE)
    if (slot->native_mailbox == NULL) {
        return;
    }
#endif
    if (slot->native_mailbox[P2_NATIVE_BLINK_STATUS] != 0) {
        slot->status = (int)slot->native_mailbox[P2_NATIVE_BLINK_STATUS];
    }
    if (slot->native_mailbox[P2_NATIVE_BLINK_COGID] < 8u) {
        slot->cog_id = (int)slot->native_mailbox[P2_NATIVE_BLINK_COGID];
    }
    slot->call_count = (size_t)slot->native_mailbox[P2_NATIVE_BLINK_CALLS];
}

static void p2_closure_cog_sync_isolated_source(p2_closure_cog_slot *slot)
{
    p2_child_vm_cog_once_job *job;

    if (slot == NULL || !slot->isolated_source) {
        return;
    }
    job = slot->source_job;
    if (job == NULL) {
        return;
    }
    if (job->status != 0) {
        slot->status = job->status;
    }
    if (job->cog_id >= 0 && job->cog_id < 8) {
        slot->cog_id = job->cog_id;
    }
    slot->call_result = job->call_result;
    slot->last_result_type = job->result_type;
    slot->last_result_int = job->result_int;
    slot->last_result_bool = job->result_bool;
    slot->call_count = job->function_found ? 1u : 0u;
}

static int p2_closure_cog_start_native_blink(p2_closure_cog_slot *slot)
{
    void *program;
    uint64_t ms_ticks;
    int cog;
    int target;
    int wait_ms;

    if (slot == NULL || slot->native_pin < 0 || slot->native_pin > 63 || slot->period_ms <= 0) {
        return -1;
    }

#if defined(__CATALINA_LARGE)
    slot->native_mailbox = (volatile uint32_t *)p2_hub_mem_calloc(P2_NATIVE_BLINK_MAILBOX_LONGS, sizeof(uint32_t));
    if (slot->native_mailbox == NULL) {
        strncpy(slot->last_error, "failed to allocate native blinker mailbox", sizeof(slot->last_error) - 1);
        slot->last_error[sizeof(slot->last_error) - 1] = '\0';
        return -2;
    }
#else
    memset((void *)slot->native_mailbox, 0, sizeof(slot->native_mailbox));
#endif
    ms_ticks = ((uint64_t)_clockfreq()) / 1000u;
    if (ms_ticks == 0u) {
        ms_ticks = 1u;
    }
    if (ms_ticks > 0xffffffffu) {
        ms_ticks = 0xffffffffu;
    }
    slot->native_mailbox[P2_NATIVE_BLINK_PIN] = (uint32_t)slot->native_pin;
    slot->native_mailbox[P2_NATIVE_BLINK_PERIOD_MS] = (uint32_t)slot->period_ms;
    slot->native_mailbox[P2_NATIVE_BLINK_MS_TICKS] = (uint32_t)ms_ticks;

    program = p2_hub_mem_alloc(sizeof(p2_native_blink_pasm));
    if (program == NULL) {
#if defined(__CATALINA_LARGE)
        p2_hub_mem_free((void *)slot->native_mailbox);
        slot->native_mailbox = NULL;
#endif
        strncpy(slot->last_error, "failed to allocate native blinker program", sizeof(slot->last_error) - 1);
        slot->last_error[sizeof(slot->last_error) - 1] = '\0';
        return -2;
    }
    memcpy(program, p2_native_blink_pasm, sizeof(p2_native_blink_pasm));
    target = ANY_COG;
    cog = _cogstart_PASM(target, program, (void *)slot->native_mailbox);
    p2_hub_mem_free(program);
    if (cog < 0) {
#if defined(__CATALINA_LARGE)
        p2_hub_mem_free((void *)slot->native_mailbox);
        slot->native_mailbox = NULL;
#endif
        return -1;
    }
    target = cog;
    slot->cog_id = target;
    slot->status = 0;
    for (wait_ms = 0; wait_ms < 20 && slot->native_mailbox[P2_NATIVE_BLINK_STATUS] == 0; ++wait_ms) {
        _waitms(1);
    }
    p2_closure_cog_sync_native_blink(slot);
    if (slot->native_mailbox[P2_NATIVE_BLINK_STATUS] == 0) {
        _cogstop(target);
        slot->cog_id = -1;
        slot->status = 3;
        strncpy(slot->last_error, "blink cog no ack", sizeof(slot->last_error) - 1);
        slot->last_error[sizeof(slot->last_error) - 1] = '\0';
#if defined(__CATALINA_LARGE)
        p2_hub_mem_free((void *)slot->native_mailbox);
        slot->native_mailbox = NULL;
#endif
        return -2;
    }
    return target;
}

static void p2_closure_cog_entry(void *arg)
{
    p2_closure_cog_slot *slot = (p2_closure_cog_slot *)arg;

    if (slot == NULL) {
        return;
    }
    slot->status = 1;
    slot->cog_id = _cogid();
    if (slot->native_blink && slot->native_pin >= 0 && slot->native_pin <= 63) {
        _dirh(slot->native_pin);
        while (!slot->stop) {
            int waited = 0;

            while (!slot->stop && waited < slot->period_ms) {
                int chunk = slot->period_ms - waited;

                if (chunk > 10) {
                    chunk = 10;
                }
                if (chunk <= 0) {
                    chunk = 1;
                }
                _waitms((uint32_t)chunk);
                waited += chunk;
            }
            if (!slot->stop) {
                berry_p2_gpio_toggle(slot->native_pin);
                ++slot->call_count;
            }
        }
        slot->status = slot->stop ? 2 : 3;
        return;
    }
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    while (!slot->stop) {
        int locked = 0;
        int keep_running = 1;
        int waited = 0;

        while (!slot->stop && !p2_closure_cog_main_idle) {
            _waitms(P2_CLOSURE_COG_IDLE_WAIT_MS);
        }
        if (slot->stop) {
            break;
        }
        locked = p2_closure_cog_runtime_lock_enter(slot);
        if (locked && !slot->stop && p2_closure_cog_main_idle) {
            keep_running = p2_closure_cog_call_once(slot);
        }
        p2_child_vm_runtime_lock_leave(locked);
        if (!keep_running) {
            break;
        }
        while (!slot->stop && waited < slot->period_ms) {
            int chunk = slot->period_ms - waited;

            if (chunk > 10) {
                chunk = 10;
            }
            if (chunk <= 0) {
                chunk = 1;
            }
            _waitms((uint32_t)chunk);
            waited += chunk;
        }
    }
#endif
    slot->status = slot->stop ? 2 : 3;
}

static int p2_closure_cog_first_free(void)
{
    int i;

    for (i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
        if (!p2_closure_cog_slots[i].used) {
            return i;
        }
    }
    return -1;
}

static void p2_closure_cog_reap_stopped(bvm *vm)
{
    int i;

    for (i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
        p2_closure_cog_slot *slot = &p2_closure_cog_slots[i];
        int raw_running = 0;

        if (!slot->used || slot->status == 1) {
            p2_closure_cog_sync_native_blink(slot);
            p2_closure_cog_sync_isolated_source(slot);
        }
        if (!slot->used || slot->status == 1) {
            continue;
        }
        if (slot->cog_id >= 0 && slot->cog_id < 8) {
            raw_running = _cogchk(slot->cog_id) ? 1 : 0;
        }
        if (slot->isolated_source &&
            slot->status == 2 &&
            slot->cog_id >= 1 &&
            slot->cog_id < 8 &&
            raw_running) {
            if (slot->source_job != NULL) {
                slot->source_job->status = 3;
            }
            _cogstop(slot->cog_id);
            raw_running = 0;
        }
        if (raw_running) {
            continue;
        }
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
        p2_closure_cog_registry_clear(vm, i);
#else
        (void)vm;
#endif
        if (slot->stack != NULL) {
            p2_cog_stack_free(slot->stack);
        }
#if defined(__CATALINA_LARGE)
        if (slot->native_mailbox != NULL) {
            p2_hub_mem_free((void *)slot->native_mailbox);
        }
#endif
        if (slot->isolated_source) {
            (void)p2_heap_vm_partition_release(i);
            if (slot->source_job != NULL) {
                p2_hub_mem_free(slot->source_job);
            }
        }
        memset(slot, 0, sizeof(*slot));
    }
}

static p2_closure_cog_slot *p2_closure_cog_require_handle(bvm *vm, int index, int *slot_index)
{
    bint handle = p2_require_int_arg(vm, index, "closure cog handle must be an int");
    int slot = p2_closure_cog_slot_from_handle(handle);

    if (slot < 0 || !p2_closure_cog_slots[slot].used) {
        be_raise(vm, "value_error", "invalid closure cog handle");
    }
    if (slot_index != NULL) {
        *slot_index = slot;
    }
    return &p2_closure_cog_slots[slot];
}

enum {
    P2_CLOSURE_TASK_NONE = 0,
    P2_CLOSURE_TASK_BLINKER = 1,
#if defined(__CATALINA_LARGE)
    P2_CLOSURE_TASK_SOURCE = 2
#endif
};

#if defined(__CATALINA_LARGE)
typedef struct p2_closure_source_task {
    int used;
    char source[512];
    char name[64];
    int argc;
    int arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
} p2_closure_source_task;

static p2_closure_source_task p2_closure_source_tasks[P2_CLOSURE_COG_MAX];
#endif

static int p2_closure_cog_parse_blinker_descriptor(const char *text, int *argc,
    int arg_type[P2_CLOSURE_COG_ARGS_MAX],
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX],
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX],
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1])
{
    int parsed_pin = -1;
    int parsed_ms = 0;
    char tail = '\0';
    const char *p;
    char *endptr;
    long count;
    int i;

    if (text == NULL) {
        return 0;
    }
    if (sscanf(text, "p2blink:%d:%d%c", &parsed_pin, &parsed_ms, &tail) == 2) {
        if (parsed_pin < 0 || parsed_pin > 63 || parsed_ms <= 0) {
            return 0;
        }
        *argc = 2;
        arg_type[0] = 1;
        arg_int[0] = (bint)parsed_pin;
        arg_bool[0] = 0;
        arg_string[0][0] = '\0';
        arg_type[1] = 1;
        arg_int[1] = (bint)parsed_ms;
        arg_bool[1] = 0;
        arg_string[1][0] = '\0';
        return 1;
    }
    if (strncmp(text, "p2blinkv:", 9) != 0) {
        return 0;
    }
    p = text + 9;
    count = strtol(p, &endptr, 10);
    if (endptr == p || *endptr != ':' || count < 2 || count > P2_CLOSURE_COG_ARGS_MAX) {
        return 0;
    }
    p = endptr + 1;
    for (i = 0; i < count; ++i) {
        arg_type[i] = 0;
        arg_int[i] = 0;
        arg_bool[i] = 0;
        arg_string[i][0] = '\0';
        if (*p == 'i') {
            long value;

            ++p;
            value = strtol(p, &endptr, 10);
            if (endptr == p) {
                return 0;
            }
            arg_type[i] = 1;
            arg_int[i] = (bint)value;
            p = endptr;
        } else if (*p == 'b' && (p[1] == '0' || p[1] == '1')) {
            arg_type[i] = 2;
            arg_bool[i] = p[1] == '1';
            p += 2;
        } else if (*p == 'n') {
            arg_type[i] = 3;
            ++p;
        } else if (*p == 's') {
            long len;

            ++p;
            len = strtol(p, &endptr, 10);
            if (endptr == p || *endptr != '=' ||
                len < 0 || len > P2_CLOSURE_COG_TEXT_MAX ||
                strlen(endptr + 1) < (size_t)len) {
                return 0;
            }
            arg_type[i] = 4;
            memcpy(arg_string[i], endptr + 1, (size_t)len);
            arg_string[i][len] = '\0';
            p = endptr + 1 + len;
        } else {
            return 0;
        }
        if (i + 1 < count) {
            if (*p != ':') {
                return 0;
            }
            ++p;
        } else if (*p != '\0') {
            return 0;
        }
    }
    if (arg_type[0] != 1 || arg_type[1] != 1 ||
        arg_int[0] < 0 || arg_int[0] > 63 || arg_int[1] <= 0) {
        return 0;
    }
    *argc = (int)count;
    return 1;
}

static int p2_closure_cog_parse_task_descriptor(const char *text, int *kind, int *argc,
    int arg_type[P2_CLOSURE_COG_ARGS_MAX],
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX],
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX],
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1])
{
    const char *p;
    const char *kind_start;
    char *endptr;
    long kind_len;
    long count;
    int i;

    if (kind != NULL) {
        *kind = P2_CLOSURE_TASK_NONE;
    }
#if defined(__CATALINA_LARGE)
    if (text != NULL && strncmp(text, "p2source:", 9) == 0) {
        long id;

        p = text + 9;
        id = strtol(p, &endptr, 10);
        if (endptr == p || *endptr != '\0' ||
            id < 0 || id >= P2_CLOSURE_COG_MAX ||
            !p2_closure_source_tasks[id].used) {
            return 0;
        }
        if (kind != NULL) {
            *kind = P2_CLOSURE_TASK_SOURCE;
        }
        if (argc != NULL) {
            *argc = p2_closure_source_tasks[id].argc;
        }
        for (i = 0; i < p2_closure_source_tasks[id].argc; ++i) {
            arg_type[i] = p2_closure_source_tasks[id].arg_type[i];
            arg_int[i] = p2_closure_source_tasks[id].arg_int[i];
            arg_bool[i] = p2_closure_source_tasks[id].arg_bool[i];
            if (p2_closure_source_tasks[id].arg_type[i] == 4) {
                strncpy(arg_string[i], p2_closure_source_tasks[id].arg_string[i], P2_CLOSURE_COG_TEXT_MAX);
                arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
            }
        }
        return 1;
    }
#endif
    if (text != NULL && strncmp(text, "p2task:", 7) == 0) {
        p = text + 7;
        kind_len = strtol(p, &endptr, 10);
        if (endptr == p || *endptr != '=' || kind_len <= 0 || kind_len > 31) {
            return 0;
        }
        kind_start = endptr + 1;
        p = kind_start + kind_len;
        if (*p != ':') {
            return 0;
        }
        if (kind_len != 7 || memcmp(kind_start, "blinker", 7) != 0) {
            return 0;
        }
        ++p;
        count = strtol(p, &endptr, 10);
        if (endptr == p || *endptr != ':' || count < 2 || count > P2_CLOSURE_COG_ARGS_MAX) {
            return 0;
        }
        p = endptr + 1;
        for (i = 0; i < count; ++i) {
            arg_type[i] = 0;
            arg_int[i] = 0;
            arg_bool[i] = 0;
            arg_string[i][0] = '\0';
            if (*p == 'i') {
                long value;

                ++p;
                value = strtol(p, &endptr, 10);
                if (endptr == p) {
                    return 0;
                }
                arg_type[i] = 1;
                arg_int[i] = (bint)value;
                p = endptr;
            } else if (*p == 'b' && (p[1] == '0' || p[1] == '1')) {
                arg_type[i] = 2;
                arg_bool[i] = p[1] == '1';
                p += 2;
            } else if (*p == 'n') {
                arg_type[i] = 3;
                ++p;
            } else if (*p == 's') {
                long len;

                ++p;
                len = strtol(p, &endptr, 10);
                if (endptr == p || *endptr != '=' ||
                    len < 0 || len > P2_CLOSURE_COG_TEXT_MAX ||
                    strlen(endptr + 1) < (size_t)len) {
                    return 0;
                }
                arg_type[i] = 4;
                memcpy(arg_string[i], endptr + 1, (size_t)len);
                arg_string[i][len] = '\0';
                p = endptr + 1 + len;
            } else {
                return 0;
            }
            if (i + 1 < count) {
                if (*p != ':') {
                    return 0;
                }
                ++p;
            } else if (*p != '\0') {
                return 0;
            }
        }
        if (arg_type[0] != 1 || arg_type[1] != 1 ||
            arg_int[0] < 0 || arg_int[0] > 63 || arg_int[1] <= 0) {
            return 0;
        }
        if (kind != NULL) {
            *kind = P2_CLOSURE_TASK_BLINKER;
        }
        *argc = (int)count;
        return 1;
    }
    if (p2_closure_cog_parse_blinker_descriptor(text, argc, arg_type, arg_int, arg_bool, arg_string)) {
        if (kind != NULL) {
            *kind = P2_CLOSURE_TASK_BLINKER;
        }
        return 1;
    }
    return 0;
}

static const char *p2_closure_cog_task_kind_name(int kind)
{
    switch (kind) {
    case P2_CLOSURE_TASK_BLINKER:
        return "blinker";
#if defined(__CATALINA_LARGE)
    case P2_CLOSURE_TASK_SOURCE:
        return "source";
#endif
    default:
        return "unknown";
    }
}

static int p2_closure_cog_push_blinker_descriptor(bvm *vm, int first_arg, int argc)
{
    int pin = (int)p2_require_int_arg(vm, first_arg, "pin must be an int");
    int ms = (int)p2_require_int_arg(vm, first_arg + 1, "delay ms must be an int");
    char descriptor[P2_CLOSURE_COG_DESCRIPTOR_MAX];
    size_t used;
    int i;

    if (pin < 0 || pin > 63) {
        be_raise(vm, "value_error", "pin out of range");
    }
    if (ms <= 0) {
        be_raise(vm, "value_error", "delay ms must be > 0");
    }
    if (argc < 2 || argc > P2_CLOSURE_COG_ARGS_MAX) {
        be_raise(vm, "value_error", "too many blinker descriptor args");
    }
    used = (size_t)snprintf(descriptor, sizeof(descriptor), "p2task:7=blinker:%d", argc);
    for (i = 0; i < argc; ++i) {
        int arg_index = first_arg + i;
        int written;

        if (be_isbool(vm, arg_index)) {
            written = snprintf(descriptor + used, sizeof(descriptor) - used,
                ":b%d", be_tobool(vm, arg_index) ? 1 : 0);
        } else if (be_isint(vm, arg_index)) {
            written = snprintf(descriptor + used, sizeof(descriptor) - used,
                ":i%ld", (long)be_toint(vm, arg_index));
        } else if (be_isnil(vm, arg_index)) {
            written = snprintf(descriptor + used, sizeof(descriptor) - used, ":n");
        } else if (be_isstring(vm, arg_index)) {
            const char *text = be_tostring(vm, arg_index);
            size_t len = text ? strlen(text) : 0u;

            if (len > P2_CLOSURE_COG_TEXT_MAX) {
                be_raise(vm, "value_error", "blinker descriptor string too long");
            }
            written = snprintf(descriptor + used, sizeof(descriptor) - used,
                ":s%lu=", (unsigned long)len);
            if (written < 0 || used + (size_t)written + len >= sizeof(descriptor)) {
                be_raise(vm, "value_error", "blinker descriptor too long");
            }
            used += (size_t)written;
            if (len > 0u) {
                memcpy(descriptor + used, text, len);
                used += len;
                descriptor[used] = '\0';
            }
            continue;
        } else {
            be_raise(vm, "type_error", "blinker descriptor args must be int, bool, nil, or string");
        }
        if (written < 0 || used + (size_t)written >= sizeof(descriptor)) {
            be_raise(vm, "value_error", "blinker descriptor too long");
        }
        used += (size_t)written;
    }
    be_pushstring(vm, descriptor);
    be_return(vm);
}

static int m_p2_closure_cog_blinker(bvm *vm)
{
    return p2_closure_cog_push_blinker_descriptor(vm, 1, be_top(vm));
}

#if defined(__CATALINA_LARGE)
static int p2_closure_cog_push_source_descriptor(bvm *vm, int first_arg, int argc)
{
    const char *source;
    const char *name;
    int task_index = -1;
    int i;
    char descriptor[24];
    p2_closure_source_task *task;

    if (argc < 2 || argc - 2 > P2_CLOSURE_COG_ARGS_MAX) {
        be_raise(vm, "value_error", "source task expects source, name, and up to 8 args");
    }
    if (!be_isstring(vm, first_arg) || !be_isstring(vm, first_arg + 1)) {
        be_raise(vm, "type_error", "source task expects source and function name strings");
    }
    source = be_tostring(vm, first_arg);
    name = be_tostring(vm, first_arg + 1);
    if (source == NULL || strlen(source) >= sizeof(p2_closure_source_tasks[0].source)) {
        be_raise(vm, "value_error", "source task source too long");
    }
    if (name == NULL || !name[0] || strlen(name) >= sizeof(p2_closure_source_tasks[0].name)) {
        be_raise(vm, "value_error", "source task function name too long");
    }
    for (i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
        if (!p2_closure_source_tasks[i].used) {
            task_index = i;
            break;
        }
    }
    if (task_index < 0) {
        be_raise(vm, "runtime_error", "no source task descriptor slots available");
    }
    task = &p2_closure_source_tasks[task_index];
    memset(task, 0, sizeof(*task));
    task->used = 1;
    strcpy(task->source, source);
    strcpy(task->name, name);
    task->argc = argc - 2;
    for (i = 0; i < task->argc; ++i) {
        int arg_index = first_arg + 2 + i;

        if (be_isint(vm, arg_index)) {
            task->arg_type[i] = 1;
            task->arg_int[i] = be_toint(vm, arg_index);
        } else if (be_isbool(vm, arg_index)) {
            task->arg_type[i] = 2;
            task->arg_bool[i] = be_tobool(vm, arg_index);
        } else if (be_isnil(vm, arg_index)) {
            task->arg_type[i] = 3;
        } else if (be_isstring(vm, arg_index)) {
            const char *text = be_tostring(vm, arg_index);

            task->arg_type[i] = 4;
            if (text != NULL) {
                strncpy(task->arg_string[i], text, P2_CLOSURE_COG_TEXT_MAX);
                task->arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
            }
        } else {
            memset(task, 0, sizeof(*task));
            be_raise(vm, "type_error", "source task args must be int, bool, nil, or string");
        }
    }
    snprintf(descriptor, sizeof(descriptor), "p2source:%d", task_index);
    be_pushstring(vm, descriptor);
    be_return(vm);
}
#endif

static int m_p2_closure_cog_task(bvm *vm)
{
    const char *kind;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "task kind must be a string");
    }
    kind = be_tostring(vm, 1);
    if (kind != NULL && !strcmp(kind, "blinker")) {
        return p2_closure_cog_push_blinker_descriptor(vm, 2, be_top(vm) - 1);
    }
#if defined(__CATALINA_LARGE)
    if (kind != NULL && !strcmp(kind, "source")) {
#if !P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED
        be_raise(vm, "runtime_error", "source task cog runtime is not supported on this P2 build");
#endif
        return p2_closure_cog_push_source_descriptor(vm, 2, be_top(vm) - 1);
    }
#endif
    be_raise(vm, "value_error", "unsupported task kind");
    be_return_nil(vm);
}

#if defined(__CATALINA_LARGE)
static int m_p2_closure_cog_task_kinds(bvm *vm)
{
    be_newobject(vm, "list");
    be_pushstring(vm, "blinker");
    be_data_push(vm, -2);
    be_pop(vm, 1);
#if defined(__CATALINA_LARGE)
#if P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED
    be_pushstring(vm, "source");
    be_data_push(vm, -2);
    be_pop(vm, 1);
#endif
#endif
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_closure_cog_task_release(bvm *vm)
{
    const char *text;
    int source_index;
    int released = 0;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "task descriptor must be a string");
    }
    text = be_tostring(vm, 1);
#if defined(__CATALINA_LARGE)
    if (text != NULL && strncmp(text, "p2source:", 9) == 0) {
        source_index = (int)strtol(text + 9, NULL, 10);
        if (source_index >= 0 && source_index < P2_CLOSURE_COG_MAX &&
            p2_closure_source_tasks[source_index].used) {
            memset(&p2_closure_source_tasks[source_index], 0, sizeof(p2_closure_source_tasks[source_index]));
            released = 1;
        }
    }
#else
    (void)text;
#endif
    be_pushbool(vm, released);
    be_return(vm);
}
#endif

static int m_p2_closure_cog_is_task(bvm *vm)
{
    int argc = 0;
    int arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
    int kind = P2_CLOSURE_TASK_NONE;
    int ok = 0;

    memset(arg_type, 0, sizeof(arg_type));
    memset(arg_int, 0, sizeof(arg_int));
    memset(arg_bool, 0, sizeof(arg_bool));
    memset(arg_string, 0, sizeof(arg_string));
    if (be_top(vm) >= 1 && be_isstring(vm, 1)) {
        ok = p2_closure_cog_parse_task_descriptor(be_tostring(vm, 1), &kind, &argc,
            arg_type, arg_int, arg_bool, arg_string);
    }
    be_pushbool(vm, ok);
    be_return(vm);
}

#if defined(__CATALINA_LARGE)
static int m_p2_closure_cog_task_info(bvm *vm)
{
    int argc = 0;
    int arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
    int kind = P2_CLOSURE_TASK_NONE;
    int i;

    memset(arg_type, 0, sizeof(arg_type));
    memset(arg_int, 0, sizeof(arg_int));
    memset(arg_bool, 0, sizeof(arg_bool));
    memset(arg_string, 0, sizeof(arg_string));
    if (be_top(vm) < 1 || !be_isstring(vm, 1) ||
        !p2_closure_cog_parse_task_descriptor(be_tostring(vm, 1), &kind, &argc,
            arg_type, arg_int, arg_bool, arg_string)) {
        be_raise(vm, "value_error", "invalid task descriptor");
    }
    be_newobject(vm, "map");
    p2_map_set_string(vm, "kind", p2_closure_cog_task_kind_name(kind));
    p2_map_set_int(vm, "argc", (bint)argc);
    if (kind == P2_CLOSURE_TASK_BLINKER) {
        p2_map_set_int(vm, "pin", arg_int[0]);
        p2_map_set_int(vm, "period_ms", arg_int[1]);
    }
#if defined(__CATALINA_LARGE)
    else if (kind == P2_CLOSURE_TASK_SOURCE && be_isstring(vm, 1)) {
        const char *text = be_tostring(vm, 1);
        int source_index = text ? (int)strtol(text + 9, NULL, 10) : -1;

        if (source_index >= 0 && source_index < P2_CLOSURE_COG_MAX &&
            p2_closure_source_tasks[source_index].used) {
            p2_map_set_string(vm, "function", p2_closure_source_tasks[source_index].name);
            p2_map_set_int(vm, "source_len", (bint)strlen(p2_closure_source_tasks[source_index].source));
        }
    }
#endif
    (void)arg_type;
    (void)arg_bool;
    (void)arg_string;
    be_pop(vm, 1);
    be_return(vm);
}
#endif

static int p2_closure_cog_call_setup_function(bvm *vm, p2_closure_cog_slot *slot)
{
    int top_before;
    bvalue *result_slot;
    int parsed_kind = P2_CLOSURE_TASK_NONE;
    int parsed_argc = 0;
    int parsed_arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint parsed_arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int parsed_arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char parsed_arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
    int i;

    if (vm == NULL || slot == NULL || !be_isfunction(vm, 1)) {
        return 0;
    }
    slot->setup_function = 1;
    slot->setup_descriptor_return = 0;

    memset(parsed_arg_type, 0, sizeof(parsed_arg_type));
    memset(parsed_arg_int, 0, sizeof(parsed_arg_int));
    memset(parsed_arg_bool, 0, sizeof(parsed_arg_bool));
    memset(parsed_arg_string, 0, sizeof(parsed_arg_string));

    top_before = be_top(vm);
    be_pushvalue(vm, 1);
    for (i = 0; i < slot->argc; ++i) {
        p2_closure_cog_push_arg(vm, slot, i);
    }
    result_slot = vm->top - slot->argc - 1;
    slot->call_result = be_pcall(vm, slot->argc);
    if (slot->call_result != BE_OK) {
        p2_closure_cog_capture_exception(vm, slot);
        be_pop(vm, be_top(vm) - top_before);
        return 0;
    }

    if (var_isint(result_slot)) {
        slot->last_result_type = 1;
        slot->last_result_int = var_toint(result_slot);
        slot->period_ms = (int)slot->last_result_int;
    } else if (var_isbool(result_slot)) {
        slot->last_result_type = 2;
        slot->last_result_bool = var_tobool(result_slot);
    } else if (var_isnil(result_slot)) {
        slot->last_result_type = 3;
    } else if (var_isstr(result_slot)) {
        const char *text = str(var_tostr(result_slot));

        slot->last_result_type = 4;
        if (text != NULL) {
            strncpy(slot->arg_string[0], text, P2_CLOSURE_COG_TEXT_MAX);
            slot->arg_string[0][P2_CLOSURE_COG_TEXT_MAX] = '\0';
            if (p2_closure_cog_parse_task_descriptor(text, &parsed_kind, &parsed_argc,
                    parsed_arg_type, parsed_arg_int, parsed_arg_bool, parsed_arg_string) &&
                parsed_kind == P2_CLOSURE_TASK_BLINKER) {
                slot->setup_descriptor_return = 1;
                slot->task_kind = parsed_kind;
                slot->argc = parsed_argc;
                for (i = 0; i < parsed_argc; ++i) {
                    slot->arg_type[i] = parsed_arg_type[i];
                    slot->arg_int[i] = parsed_arg_int[i];
                    slot->arg_bool[i] = parsed_arg_bool[i];
                    if (parsed_arg_type[i] == 4) {
                        strncpy(slot->arg_string[i], parsed_arg_string[i], P2_CLOSURE_COG_TEXT_MAX);
                        slot->arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
                    } else {
                        slot->arg_string[i][0] = '\0';
                    }
                }
                slot->native_pin = (int)slot->arg_int[0];
                slot->period_ms = (int)slot->arg_int[1];
            }
        }
    } else {
        slot->last_result_type = 0;
    }

    be_pop(vm, be_top(vm) - top_before);
    return 1;
}

static int m_p2_closure_cog_spawn(bvm *vm)
{
    int slot_index;
    int argc;
    int i;
    int cog;
    int descriptor_native = 0;
    int descriptor_kind = P2_CLOSURE_TASK_NONE;
    int descriptor_argc = 0;
    int descriptor_arg_type[P2_CLOSURE_COG_ARGS_MAX];
    bint descriptor_arg_int[P2_CLOSURE_COG_ARGS_MAX];
    int descriptor_arg_bool[P2_CLOSURE_COG_ARGS_MAX];
    char descriptor_arg_string[P2_CLOSURE_COG_ARGS_MAX][P2_CLOSURE_COG_TEXT_MAX + 1];
    void *stack;
    p2_closure_cog_slot *slot;
#if defined(__CATALINA_LARGE)
    p2_child_vm_cog_once_job *source_job = NULL;
    p2_closure_source_task *source_task = NULL;
    int source_task_index = -1;
#endif

    memset(descriptor_arg_type, 0, sizeof(descriptor_arg_type));
    memset(descriptor_arg_int, 0, sizeof(descriptor_arg_int));
    memset(descriptor_arg_bool, 0, sizeof(descriptor_arg_bool));
    memset(descriptor_arg_string, 0, sizeof(descriptor_arg_string));

    if (be_top(vm) < 1) {
        be_raise(vm, "type_error", "expected closure/function or spawn descriptor");
    }
    if (be_isfunction(vm, 1)) {
        argc = be_top(vm) - 1;
    } else if (be_top(vm) == 1 &&
        be_isstring(vm, 1) &&
        p2_closure_cog_parse_task_descriptor(be_tostring(vm, 1), &descriptor_kind, &descriptor_argc,
            descriptor_arg_type, descriptor_arg_int, descriptor_arg_bool, descriptor_arg_string)) {
        descriptor_native = 1;
        argc = descriptor_argc;
#if defined(__CATALINA_LARGE)
        if (descriptor_kind == P2_CLOSURE_TASK_SOURCE) {
            const char *text = be_tostring(vm, 1);
            source_task_index = (int)strtol(text + 9, NULL, 10);
            if (source_task_index < 0 || source_task_index >= P2_CLOSURE_COG_MAX ||
                !p2_closure_source_tasks[source_task_index].used) {
                be_raise(vm, "value_error", "invalid source task descriptor");
            }
            source_task = &p2_closure_source_tasks[source_task_index];
        }
#endif
    } else {
        be_raise(vm, "type_error", "expected closure/function or spawn descriptor");
    }
    if (argc > P2_CLOSURE_COG_ARGS_MAX) {
        be_raise(vm, "value_error", "too many closure cog args");
    }
    p2_child_vm_runtime_lock_init();
    if (p2_child_vm_runtime_lock < 0) {
        be_raise(vm, "runtime_error", "closure cog requires a hardware VM lock");
    }
    p2_closure_cog_reap_stopped(vm);
    slot_index = p2_closure_cog_first_free();
    if (slot_index < 0) {
        be_raise(vm, "runtime_error", "no closure cog slots available");
    }
    slot = &p2_closure_cog_slots[slot_index];
    memset(slot, 0, sizeof(*slot));
    slot->vm = vm;
    slot->handle = P2_CLOSURE_COG_HANDLE_BASE + slot_index;
    slot->cog_id = -1;
    slot->period_ms = 0;
    slot->native_pin = -1;
    slot->task_kind = P2_CLOSURE_TASK_NONE;
    slot->argc = argc;
    slot->call_result = BE_OK;
    slot->stack_size = P2_CLOSURE_COG_STACK_DEFAULT;
    if (!descriptor_native) {
        p2_closure_cog_capture_function_name(vm, 1, slot);
    }
    if (descriptor_native) {
        slot->descriptor_task = 1;
        slot->task_kind = descriptor_kind;
        for (i = 0; i < argc; ++i) {
            slot->arg_type[i] = descriptor_arg_type[i];
            slot->arg_int[i] = descriptor_arg_int[i];
            slot->arg_bool[i] = descriptor_arg_bool[i];
            if (descriptor_arg_type[i] == 4) {
                strncpy(slot->arg_string[i], descriptor_arg_string[i], P2_CLOSURE_COG_TEXT_MAX);
                slot->arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
            }
        }
#if defined(__CATALINA_LARGE)
        if (descriptor_kind == P2_CLOSURE_TASK_SOURCE && source_task != NULL) {
            slot->argc = source_task->argc;
            for (i = 0; i < source_task->argc; ++i) {
                slot->arg_type[i] = source_task->arg_type[i];
                slot->arg_int[i] = source_task->arg_int[i];
                slot->arg_bool[i] = source_task->arg_bool[i];
                if (source_task->arg_type[i] == 4) {
                    strncpy(slot->arg_string[i], source_task->arg_string[i], P2_CLOSURE_COG_TEXT_MAX);
                    slot->arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
                }
            }
        }
#endif
    } else {
        for (i = 0; i < argc; ++i) {
            int arg_index = i + 2;

            if (be_isint(vm, arg_index)) {
                slot->arg_type[i] = 1;
                slot->arg_int[i] = be_toint(vm, arg_index);
            } else if (be_isbool(vm, arg_index)) {
                slot->arg_type[i] = 2;
                slot->arg_bool[i] = be_tobool(vm, arg_index);
            } else if (be_isnil(vm, arg_index)) {
                slot->arg_type[i] = 3;
            } else if (be_isstring(vm, arg_index)) {
                const char *text = be_tostring(vm, arg_index);

                slot->arg_type[i] = 4;
                if (text != NULL) {
                    strncpy(slot->arg_string[i], text, P2_CLOSURE_COG_TEXT_MAX);
                    slot->arg_string[i][P2_CLOSURE_COG_TEXT_MAX] = '\0';
                }
            } else {
                memset(slot, 0, sizeof(*slot));
                be_raise(vm, "type_error", "closure cog args must be int, bool, nil, or string");
            }
        }
    }
    if (!descriptor_native) {
        if (!p2_closure_cog_call_setup_function(vm, slot)) {
            memset(slot, 0, sizeof(*slot));
            be_raise(vm, "runtime_error", "closure setup function failed");
        }
    }
    if ((descriptor_kind == P2_CLOSURE_TASK_BLINKER ||
            (!descriptor_native && descriptor_kind == P2_CLOSURE_TASK_NONE)) &&
        slot->argc >= 2 &&
        slot->arg_type[0] == 1 &&
        slot->arg_type[1] == 1 &&
        slot->arg_int[0] >= 0 &&
        slot->arg_int[0] <= 63 &&
        slot->period_ms > 0) {
        slot->native_blink = 1;
        slot->task_kind = P2_CLOSURE_TASK_BLINKER;
        slot->native_pin = (int)slot->arg_int[0];
        slot->stack_size = P2_CLOSURE_COG_STACK_NATIVE_BLINK;
        if (descriptor_native) {
            slot->period_ms = (int)slot->arg_int[1];
            p2_closure_cog_setup_native_blink(vm, slot);
        }
    }
#if !BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    if (!slot->native_blink
#if defined(__CATALINA_LARGE)
        && descriptor_kind != P2_CLOSURE_TASK_SOURCE
#endif
        ) {
        memset(slot, 0, sizeof(*slot));
        be_raise(vm, "runtime_error", "unsupported closure cog shape");
    }
#endif
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    p2_closure_cog_registry_set(vm, slot_index, 1);
#endif
    if (slot->native_blink) {
        stack = NULL;
    } else {
        stack = p2_cog_stack_alloc(slot->stack_size);
    }
    if (!slot->native_blink && stack == NULL) {
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
        p2_closure_cog_registry_clear(vm, slot_index);
#endif
        memset(slot, 0, sizeof(*slot));
        be_raise(vm, "memory_error", "failed to allocate closure cog stack");
    }
    slot->stack = stack;
    slot->used = 1;
#if defined(__CATALINA_LARGE)
    if (descriptor_kind == P2_CLOSURE_TASK_SOURCE && source_task != NULL) {
        int wait_count = 0;

        source_job = (p2_child_vm_cog_once_job *)p2_hub_mem_alloc(sizeof(*source_job));
        if (source_job == NULL) {
            if (stack != NULL) {
                p2_cog_stack_free(stack);
            }
            memset(source_task, 0, sizeof(*source_task));
            memset(slot, 0, sizeof(*slot));
            be_raise(vm, "memory_error", "failed to allocate closure source mailbox");
        }
        memset(source_job, 0, sizeof(*source_job));
        source_job->status = 0;
        source_job->cog_id = -1;
        source_job->slot = slot_index;
        source_job->bytes = p2_heap_vm_partition_size();
        strcpy(source_job->source, source_task->source);
        strcpy(source_job->name, source_task->name);
        source_job->argc = source_task->argc;
        for (i = 0; i < source_task->argc; ++i) {
            source_job->arg_type[i] = source_task->arg_type[i];
            source_job->arg_int[i] = source_task->arg_int[i];
            source_job->arg_bool[i] = source_task->arg_bool[i];
            if (source_task->arg_type[i] == 4) {
                strncpy(source_job->arg_string[i], source_task->arg_string[i], sizeof(source_job->arg_string[i]) - 1);
                source_job->arg_string[i][sizeof(source_job->arg_string[i]) - 1] = '\0';
            }
        }
        slot->isolated_source = 1;
        slot->source_job = source_job;
        strncpy(slot->closure_name, source_task->name, sizeof(slot->closure_name) - 1);
        slot->closure_name[sizeof(slot->closure_name) - 1] = '\0';
        cog = p2_catalina_cogstart_C(p2_child_vm_cog_once_entry, source_job, stack, (int)slot->stack_size);
        if (cog >= 0 && cog < 8) {
            source_job->cog_id = cog;
            while (source_job->status == 0 && wait_count < 100) {
                _waitus(1000);
                ++wait_count;
            }
            p2_closure_cog_sync_isolated_source(slot);
        }
        memset(source_task, 0, sizeof(*source_task));
    } else
#endif
    if (slot->native_blink) {
        cog = p2_closure_cog_start_native_blink(slot);
    } else {
        cog = p2_catalina_cogstart_C(p2_closure_cog_entry, slot, stack, (int)slot->stack_size);
    }
    if (cog < 0 || cog >= 8) {
        char spawn_error[96];

        strncpy(spawn_error, slot->last_error[0] ? slot->last_error : "no free cog for closure", sizeof(spawn_error) - 1);
        spawn_error[sizeof(spawn_error) - 1] = '\0';
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
        p2_closure_cog_registry_clear(vm, slot_index);
#endif
        if (stack != NULL) {
            p2_cog_stack_free(stack);
        }
#if defined(__CATALINA_LARGE)
        if (descriptor_kind == P2_CLOSURE_TASK_SOURCE) {
            if (source_job != NULL) {
                p2_hub_mem_free(source_job);
            }
        }
#endif
        memset(slot, 0, sizeof(*slot));
        be_raise(vm, "runtime_error", spawn_error);
    }
    slot->cog_id = cog;
    be_pushint(vm, slot->handle);
    be_return(vm);
}

#if defined(__CATALINA_LARGE)
static int m_p2_closure_cog_spawn_source(bvm *vm)
{
    int slot_index;
    bint bytes = (bint)p2_heap_vm_partition_size();
    const char *source;
    const char *name;
    int argc;
    int i;
    int cog;
    int wait_count = 0;
    void *stack;
    p2_closure_cog_slot *slot;
    p2_child_vm_cog_once_job *job;

#if !P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED
    be_raise(vm, "runtime_error", "source cog runtime is not supported on this P2 build");
#endif

    if (be_top(vm) < 2 || !be_isstring(vm, 1) || !be_isstring(vm, 2)) {
        be_raise(vm, "type_error", "expected source string and function name");
    }
    argc = be_top(vm) - 2;
    if (argc > P2_CLOSURE_COG_ARGS_MAX) {
        be_raise(vm, "value_error", "too many closure cog args");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }

    source = be_tostring(vm, 1);
    name = be_tostring(vm, 2);
    if (source == NULL || strlen(source) >= sizeof(p2_child_vm_cog_once_jobs[0].source)) {
        be_raise(vm, "value_error", "source too long");
    }
    if (name == NULL || !name[0] || strlen(name) >= sizeof(p2_child_vm_cog_once_jobs[0].name)) {
        be_raise(vm, "value_error", "function name too long");
    }

    p2_child_vm_runtime_lock_init();
    if (p2_child_vm_runtime_lock < 0) {
        be_raise(vm, "runtime_error", "closure cog requires a hardware VM lock");
    }
    p2_closure_cog_reap_stopped(vm);
    slot_index = p2_closure_cog_first_free();
    if (slot_index < 0) {
        be_raise(vm, "runtime_error", "no closure cog slots available");
    }

    slot = &p2_closure_cog_slots[slot_index];
    job = (p2_child_vm_cog_once_job *)p2_hub_mem_alloc(sizeof(*job));
    if (job == NULL) {
        memset(slot, 0, sizeof(*slot));
        be_raise(vm, "memory_error", "failed to allocate closure source mailbox");
    }
    memset(slot, 0, sizeof(*slot));
    memset(job, 0, sizeof(*job));
    slot->vm = vm;
    slot->handle = P2_CLOSURE_COG_HANDLE_BASE + slot_index;
    slot->cog_id = -1;
    slot->native_pin = -1;
    slot->argc = argc;
    slot->call_result = BE_OK;
    slot->stack_size = P2_CLOSURE_COG_STACK_DEFAULT;
    slot->isolated_source = 1;

    job->status = 0;
    job->cog_id = -1;
    job->slot = slot_index;
    job->bytes = (size_t)bytes;
    strcpy(job->source, source);
    strcpy(job->name, name);
    job->argc = argc;
    for (i = 0; i < argc; ++i) {
        int arg_index = i + 3;

        if (be_isint(vm, arg_index)) {
            job->arg_type[i] = 1;
            job->arg_int[i] = be_toint(vm, arg_index);
        } else if (be_isbool(vm, arg_index)) {
            job->arg_type[i] = 2;
            job->arg_bool[i] = be_tobool(vm, arg_index);
        } else if (be_isnil(vm, arg_index)) {
            job->arg_type[i] = 3;
        } else if (be_isstring(vm, arg_index)) {
            const char *text = be_tostring(vm, arg_index);

            job->arg_type[i] = 4;
            if (text != NULL) {
                strncpy(job->arg_string[i], text, sizeof(job->arg_string[i]) - 1);
                job->arg_string[i][sizeof(job->arg_string[i]) - 1] = '\0';
            }
        } else {
            memset(slot, 0, sizeof(*slot));
            p2_hub_mem_free(job);
            be_raise(vm, "type_error", "closure cog args must be int, bool, nil, or string");
        }
    }

    stack = p2_cog_stack_alloc(slot->stack_size);
    if (stack == NULL) {
        memset(slot, 0, sizeof(*slot));
        p2_hub_mem_free(job);
        be_raise(vm, "memory_error", "failed to allocate closure cog stack");
    }
    slot->stack = stack;
    slot->used = 1;
    slot->source_job = job;
    cog = p2_catalina_cogstart_C(p2_child_vm_cog_once_entry, job, stack, (int)slot->stack_size);
    if (cog < 0 || cog >= 8) {
        p2_cog_stack_free(stack);
        memset(slot, 0, sizeof(*slot));
        p2_hub_mem_free(job);
        be_raise(vm, "runtime_error", "no free cog for closure source");
    }
    slot->cog_id = cog;
    job->cog_id = cog;
    while (job->status == 0 && wait_count < 100) {
        _waitus(1000);
        ++wait_count;
    }
    p2_closure_cog_sync_isolated_source(slot);
    if (job->status == 0) {
        _cogstop(cog);
        p2_cog_stack_free(stack);
        (void)p2_heap_vm_partition_release(slot_index);
        memset(slot, 0, sizeof(*slot));
        p2_hub_mem_free(job);
        be_raise(vm, "runtime_error", "closure source cog did not start");
    }
    be_pushint(vm, slot->handle);
    be_return(vm);
}
#endif

static void p2_closure_cog_label(p2_closure_cog_slot *slot, char *buf, size_t len)
{
    if (!buf || len == 0) {
        return;
    }
    buf[0] = '\0';
    if (!slot) {
        return;
    }

    if (slot->native_blink && slot->closure_name[0]) {
        snprintf(buf, len, "p2.cog %s p%d %dms, handle %ld",
                 slot->closure_name, (int)slot->native_pin, (int)slot->period_ms, (long)slot->handle);
    } else if (slot->native_blink) {
        snprintf(buf, len, "p2.cog native blinker p%d %dms, handle %ld",
                 (int)slot->native_pin, (int)slot->period_ms, (long)slot->handle);
    } else if (slot->closure_name[0]) {
        snprintf(buf, len, "p2.cog %s, handle %ld", slot->closure_name, (long)slot->handle);
    } else if (slot->isolated_source && slot->source_job && slot->source_job->name[0]) {
        snprintf(buf, len, "p2.cog source task %s, handle %ld",
                 slot->source_job->name, (long)slot->handle);
    } else if (slot->descriptor_task) {
        snprintf(buf, len, "p2.cog task %s, handle %ld",
                 p2_closure_cog_task_kind_name(slot->task_kind), (long)slot->handle);
    } else if (slot->setup_function) {
        snprintf(buf, len, "p2.cog Berry setup function, handle %ld", (long)slot->handle);
    } else {
        snprintf(buf, len, "p2.cog spawned handle %ld", (long)slot->handle);
    }
}

static p2_closure_cog_slot *p2_closure_cog_find_by_cog(int cog, int *slot_index)
{
    if (slot_index) {
        *slot_index = -1;
    }

    for (int i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
        p2_closure_cog_slot *slot = &p2_closure_cog_slots[i];
        if (!slot->used) {
            continue;
        }
        p2_closure_cog_sync_native_blink(slot);
        p2_closure_cog_sync_isolated_source(slot);
        if ((int)slot->cog_id == cog) {
            if (slot_index) {
                *slot_index = i;
            }
            return slot;
        }
    }

    return NULL;
}

static void p2_closure_cog_push_info_map(bvm *vm, int slot_index, p2_closure_cog_slot *slot)
{
    int raw_running = 0;
    char label[128];

    p2_closure_cog_sync_native_blink(slot);
    p2_closure_cog_sync_isolated_source(slot);
    if (slot->cog_id >= 0 && slot->cog_id < 8) {
        raw_running = _cogchk(slot->cog_id) ? 1 : 0;
    }
    p2_closure_cog_label(slot, label, sizeof(label));
    be_newobject(vm, "map");
    p2_map_set_string(vm, "kind", "closure");
    p2_map_set_string(vm, "model", slot->native_blink ? "native_blink" : (slot->isolated_source ? "isolated_source_vm" : "shared_vm_repl_idle"));
    p2_map_set_string(vm, "label", label);
    p2_map_set_string(vm, "function", slot->closure_name[0] ? slot->closure_name : ((slot->isolated_source && slot->source_job && slot->source_job->name[0]) ? slot->source_job->name : ""));
    p2_map_set_string(vm, "closure_name", slot->closure_name);
    p2_map_set_int(vm, "slot", (bint)slot_index);
    p2_map_set_int(vm, "handle", slot->handle);
    p2_map_set_int(vm, "cog", (bint)slot->cog_id);
    p2_map_set_bool(vm, "used", slot->used);
    p2_map_set_bool(vm, "running", slot->status == 1 && raw_running);
    p2_map_set_bool(vm, "raw_running", raw_running);
    p2_map_set_int(vm, "status", (bint)slot->status);
    p2_map_set_int(vm, "period_ms", (bint)slot->period_ms);
    p2_map_set_bool(vm, "native_blink", slot->native_blink);
    p2_map_set_bool(vm, "descriptor_task", slot->descriptor_task);
    p2_map_set_bool(vm, "setup_function", slot->setup_function);
    p2_map_set_bool(vm, "setup_descriptor_return", slot->setup_descriptor_return);
    p2_map_set_string(vm, "task_kind", p2_closure_cog_task_kind_name(slot->task_kind));
    p2_map_set_bool(vm, "isolated_source", slot->isolated_source);
    p2_map_set_int(vm, "native_pin", (bint)slot->native_pin);
    p2_map_set_int(vm, "argc", (bint)slot->argc);
    p2_map_set_int(vm, "calls", (bint)slot->call_count);
    p2_map_set_int(vm, "call_result", (bint)slot->call_result);
    p2_map_set_int(vm, "last_result_type", (bint)slot->last_result_type);
    p2_map_set_int(vm, "last_result_int", slot->last_result_int);
    p2_map_set_bool(vm, "last_result_bool", slot->last_result_bool);
    p2_map_set_string(vm, "error", slot->last_error);
#if defined(__CATALINA_LARGE)
    if (slot->isolated_source && slot->source_job != NULL) {
        p2_child_vm_cog_once_job *job = slot->source_job;

        p2_map_set_bool(vm, "source_partition_ready", job->partition_ready);
        p2_map_set_bool(vm, "source_selected", job->selected);
        p2_map_set_bool(vm, "source_child_created", job->child_created);
        p2_map_set_bool(vm, "source_child_deleted", job->child_deleted);
        p2_map_set_bool(vm, "source_function_found", job->function_found);
        p2_map_set_int(vm, "source_vm_new_stage", (bint)job->vm_new_stage);
        p2_map_set_int(vm, "source_vm_new_detail_stage", (bint)job->vm_new_detail_stage);
        p2_map_set_int(vm, "source_stage", (bint)job->source_stage);
        p2_map_set_int(vm, "source_load_stage", (bint)job->load_stage);
        p2_map_set_int(vm, "source_call_stage", (bint)job->call_stage);
        p2_map_set_int(vm, "source_execprotected_stage", (bint)job->execprotected_stage);
        p2_map_set_int(vm, "source_return_top", (bint)job->return_top);
        p2_map_set_bool(vm, "source_return_is_function", job->return_is_function);
        p2_map_set_int(vm, "source_post_call_top", (bint)job->post_call_top);
        p2_map_set_int(vm, "source_result_slot_type", (bint)job->result_slot_type);
        p2_map_set_int(vm, "source_post_call_type_1", (bint)job->post_call_type_1);
        p2_map_set_int(vm, "source_post_call_type_2", (bint)job->post_call_type_2);
        p2_map_set_int(vm, "source_post_call_type_3", (bint)job->post_call_type_3);
        p2_map_set_int(vm, "source_result", (bint)job->source_result);
        p2_map_set_int(vm, "source_call_result", (bint)job->call_result);
        p2_map_set_int(vm, "source_child_stack_top", (bint)job->child_stack_top);
        p2_map_set_int(vm, "source_wrong_free_delta", (bint)job->wrong_free_delta);
        p2_map_set_int(vm, "source_wrong_realloc_delta", (bint)job->wrong_realloc_delta);
    }
#endif
    p2_map_set_int(vm, "stack_bytes", (bint)slot->stack_size);
    p2_map_set_int(vm, "wait_ms", (bint)slot->stop_wait_ms);
    p2_map_set_bool(vm, "repl_idle_only", (slot->native_blink || slot->isolated_source) ? 0 : 1);
    be_pop(vm, 1);
}

static int m_p2_closure_cog_info(bvm *vm)
{
    int slot_index;
    p2_closure_cog_slot *slot;

    if (be_top(vm) < 1) {
        int i;

        be_newobject(vm, "list");
        for (i = 0; i < P2_CLOSURE_COG_MAX; ++i) {
            if (p2_closure_cog_slots[i].used) {
                p2_closure_cog_push_info_map(vm, i, &p2_closure_cog_slots[i]);
                be_data_push(vm, -2);
                be_pop(vm, 1);
            }
        }
        be_pop(vm, 1);
        be_return(vm);
    }

    slot = p2_closure_cog_require_handle(vm, 1, &slot_index);

    p2_closure_cog_push_info_map(vm, slot_index, slot);
    be_return(vm);
}

static int m_p2_closure_cog_capabilities(bvm *vm)
{
    be_newobject(vm, "map");
    p2_map_set_bool(vm, "spawn", 1);
    p2_map_set_bool(vm, "spawn_task", 1);
    p2_map_set_bool(vm, "spawn_source", P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED);
    p2_map_set_bool(vm, "berry_closure", 0);
    p2_map_set_bool(vm, "isolated_child_vm_cog", P2_CLOSURE_COG_SOURCE_RUNTIME_SUPPORTED);
    p2_map_set_bool(vm, "blinker_descriptor", 1);
    p2_map_set_bool(vm, "task_descriptor", 1);
    p2_map_set_bool(vm, "function_entity_spawn", 1);
    p2_map_set_bool(vm, "function_entity_setup_call", 1);
    p2_map_set_bool(vm, "function_entity_descriptor_return", 1);
    p2_map_set_bool(vm, "task_kinds", 1);
    p2_map_set_bool(vm, "task_release",
#if defined(__CATALINA_LARGE)
        1
#else
        0
#endif
    );
    p2_map_set_bool(vm, "task_descriptor_info", 1);
    p2_map_set_int(vm, "task_max_args", (bint)P2_CLOSURE_COG_ARGS_MAX);
    p2_map_set_bool(vm, "native_blink", 1);
    p2_map_set_int(vm, "native_blink_stack", (bint)P2_CLOSURE_COG_STACK_NATIVE_BLINK);
    p2_map_set_int(vm, "handle_base", (bint)P2_CLOSURE_COG_HANDLE_BASE);
    p2_map_set_int(vm, "max_handles", (bint)P2_CLOSURE_COG_MAX);
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    p2_map_set_bool(vm, "unsafe_shared_vm", 1);
    p2_map_set_bool(vm, "reject_unsupported", 0);
#else
    p2_map_set_bool(vm, "unsafe_shared_vm", 0);
    p2_map_set_bool(vm, "reject_unsupported", 1);
#endif
    p2_map_set_bool(vm, "isolated_vm_closure", 0);
    p2_map_set_bool(vm, "isolated_source_vm", 1);
    p2_map_set_bool(vm, "literal_closure_transfer", 0);
#if BE_USE_BYTECODE_LOADER
    p2_map_set_bool(vm, "bytecode_loader", 1);
#else
    p2_map_set_bool(vm, "bytecode_loader", 0);
#endif
#if BE_USE_BYTECODE_SAVER
    p2_map_set_bool(vm, "bytecode_saver", 1);
#else
    p2_map_set_bool(vm, "bytecode_saver", 0);
#endif
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_closure_cog_stop(bvm *vm)
{
    int slot_index;
    int wait_count = 0;
    p2_closure_cog_slot *slot = p2_closure_cog_require_handle(vm, 1, &slot_index);

    slot->stop = 1;
    if (slot->native_blink) {
#if defined(__CATALINA_LARGE)
        if (slot->native_mailbox != NULL) {
            slot->native_mailbox[P2_NATIVE_BLINK_STOP] = 1;
        }
#else
        slot->native_mailbox[P2_NATIVE_BLINK_STOP] = 1;
#endif
    }
    if (slot->isolated_source) {
        if (slot->source_job != NULL) {
            slot->source_job->status = 3;
        }
    }
    if (slot->cog_id >= (slot->native_blink ? 1 : 0) && slot->cog_id < 8 && _cogchk(slot->cog_id)) {
        _cogstop(slot->cog_id);
    }
    if (slot->native_blink && slot->native_pin >= 0 && slot->native_pin <= 63) {
        _pinf(slot->native_pin);
        slot->status = 2;
#if defined(__CATALINA_LARGE)
        if (slot->native_mailbox != NULL) {
            slot->native_mailbox[P2_NATIVE_BLINK_STATUS] = 2;
        }
#else
        slot->native_mailbox[P2_NATIVE_BLINK_STATUS] = 2;
#endif
        p2_closure_cog_sync_native_blink(slot);
    }
    slot->stop_wait_ms = wait_count;
#if BE_P2_ENABLE_UNSAFE_SHARED_VM_COG
    p2_closure_cog_registry_clear(vm, slot_index);
#endif
    if (slot->stack != NULL) {
        p2_cog_stack_free(slot->stack);
        slot->stack = NULL;
    }
    p2_closure_cog_push_info_map(vm, slot_index, slot);
#if defined(__CATALINA_LARGE)
    if (slot->native_mailbox != NULL) {
        p2_hub_mem_free((void *)slot->native_mailbox);
        slot->native_mailbox = NULL;
    }
#endif
    if (slot->isolated_source) {
        (void)p2_heap_vm_partition_release(slot_index);
        if (slot->source_job != NULL) {
            p2_hub_mem_free(slot->source_job);
            slot->source_job = NULL;
        }
    }
    memset(slot, 0, sizeof(*slot));
    be_return(vm);
}

static void p2_child_vm_handles_init(void)
{
    int slot;

    if (p2_child_vm_handles_ready) {
        return;
    }
    for (slot = 0; slot < BE_P2_VM_HEAP_MAX_PARTITIONS; ++slot) {
        p2_child_vm_handles[slot].cog_id = -1;
    }
    p2_child_vm_handles_ready = 1;
}

static void p2_child_vm_cog_entry(void *arg)
{
    p2_child_vm_cog_job *job = (p2_child_vm_cog_job *)arg;
    p2_child_vm_handle *handle;
    bvm *child;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    int i;

    if (job == NULL || job->slot < 0 || job->slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return;
    }
    handle = &p2_child_vm_handles[job->slot];
    handle->cog_status = 1;
    handle->cog_id = _cogid();
    handle->cog_call_result = BE_SYNTAX_ERROR;
    handle->cog_function_found = 0;
    handle->cog_result_type = 0;
    handle->cog_result_int = 0;
    handle->cog_result_bool = 0;
    handle->cog_result_string[0] = '\0';
    handle->cog_child_stack_top = 0;
    handle->cog_wrong_free_delta = 0;
    handle->cog_wrong_realloc_delta = 0;
    {
        int runtime_locked = p2_child_vm_runtime_lock_enter();

        if (!handle->active || handle->child == NULL || !p2_heap_vm_partition_select(job->slot)) {
            p2_child_vm_runtime_lock_leave(runtime_locked);
            handle->cog_status = 3;
            while (handle->cog_status != 4) {
                _waitus(1000);
            }
            return;
        }

        child = handle->child;
        wrong_free_before = p2_heap_wrong_free_count();
        wrong_realloc_before = p2_heap_wrong_realloc_count();
        handle->cog_function_found = be_getglobal(child, job->name);
        if (handle->cog_function_found) {
            for (i = 0; i < job->argc; ++i) {
                switch (job->arg_type[i]) {
                case 1:
                    be_pushint(child, job->arg_int[i]);
                    break;
                case 2:
                    be_pushbool(child, job->arg_bool[i]);
                    break;
                case 3:
                    be_pushnil(child);
                    break;
                case 4:
                    be_pushstring(child, job->arg_string[i]);
                    break;
                default:
                    be_pushnil(child);
                    break;
                }
            }
            handle->cog_call_result = be_pcall(child, job->argc);
            if (handle->cog_call_result == BE_OK && be_top(child) > 0) {
                int result_index = -(job->argc + 1);

                if (be_isint(child, result_index)) {
                    handle->cog_result_type = 1;
                    handle->cog_result_int = be_toint(child, result_index);
                } else if (be_isbool(child, result_index)) {
                    handle->cog_result_type = 2;
                    handle->cog_result_bool = be_tobool(child, result_index);
                } else if (be_isnil(child, result_index)) {
                    handle->cog_result_type = 3;
                } else if (be_isstring(child, result_index)) {
                    const char *text = be_tostring(child, result_index);

                    handle->cog_result_type = 4;
                    if (text != NULL) {
                        strncpy(handle->cog_result_string, text, sizeof(handle->cog_result_string) - 1);
                        handle->cog_result_string[sizeof(handle->cog_result_string) - 1] = '\0';
                    }
                }
            }
        }
        be_pop(child, be_top(child));
        handle->cog_child_stack_top = be_top(child);
        handle->cog_wrong_free_delta = p2_heap_wrong_free_count() - wrong_free_before;
        handle->cog_wrong_realloc_delta = p2_heap_wrong_realloc_count() - wrong_realloc_before;
        p2_heap_vm_partition_clear_current();
        p2_child_vm_runtime_lock_leave(runtime_locked);
    }
    handle->cog_status = 2;
    while (handle->cog_status != 4) {
        _waitus(1000);
    }
}

static int m_p2_vm_probe(bvm *vm)
{
    bint slot = 0;
    bint bytes = (bint)p2_heap_vm_partition_size();
    int previous_slot;
    int created;
    int selected = 0;
    int child_created = 0;
    int child_deleted = 0;
    int child_ran = 0;
    int child_run_result = BE_OK;
    int child_stack_top = 0;
    size_t main_before;
    size_t main_after;
    size_t partition_before = 0;
    size_t partition_live = 0;
    size_t partition_after = 0;
    size_t child_gc_usage = 0;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;
    const char *source = NULL;
    char source_copy[512];
    bvm *child = NULL;

    source_copy[0] = '\0';

    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        if (!be_isint(vm, 1)) {
            be_raise(vm, "type_error", "slot must be int");
        }
        slot = be_toint(vm, 1);
    }
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isint(vm, 2)) {
            be_raise(vm, "type_error", "bytes must be int");
        }
        bytes = be_toint(vm, 2);
    }
    if (be_top(vm) >= 3 && !be_isnil(vm, 3)) {
        if (!be_isstring(vm, 3)) {
            be_raise(vm, "type_error", "source must be string");
        }
        source = be_tostring(vm, 3);
        if (source != NULL) {
            if (strlen(source) >= sizeof(source_copy)) {
                be_raise(vm, "value_error", "source too long");
            }
            strcpy(source_copy, source);
            source = source_copy;
        }
    }
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }

    previous_slot = p2_heap_vm_partition_current();
    main_before = p2_heap_main_free_bytes();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    created = p2_heap_vm_partition_create((int)slot, (size_t)bytes);
    if (created) {
        partition_before = p2_heap_vm_partition_free_bytes((int)slot);
        selected = p2_heap_vm_partition_select((int)slot);
    }
    if (selected) {
        child = be_vm_new();
        if (child != NULL) {
            child_created = 1;
            child_gc_usage = be_gc_memcount(child);
            partition_live = p2_heap_free_bytes();
            if (source != NULL) {
                int top;

                child_ran = 1;
                child_run_result = be_dostring(child, source);
                top = be_top(child);
                be_pop(child, top);
                child_stack_top = be_top(child);
                partition_live = p2_heap_free_bytes();
            }
            be_vm_delete(child);
            child_deleted = 1;
        }
        p2_heap_vm_partition_clear_current();
    }
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    partition_after = p2_heap_vm_partition_free_bytes((int)slot);
    main_after = p2_heap_main_free_bytes();
    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "bytes", bytes);
    p2_map_set_bool(vm, "partition_ready", created);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "child_created", child_created);
    p2_map_set_bool(vm, "child_deleted", child_deleted);
    p2_map_set_bool(vm, "child_ran", child_ran);
    p2_map_set_int(vm, "child_run_result", (bint)child_run_result);
    p2_map_set_int(vm, "child_stack_top", (bint)child_stack_top);
    p2_map_set_int(vm, "main_before", (bint)main_before);
    p2_map_set_int(vm, "main_after", (bint)main_after);
    p2_map_set_int(vm, "partition_before", (bint)partition_before);
    p2_map_set_int(vm, "partition_live", (bint)partition_live);
    p2_map_set_int(vm, "partition_after", (bint)partition_after);
    p2_map_set_int(vm, "child_gc_usage", (bint)child_gc_usage);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "vm_partition_current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_probe_many(bvm *vm)
{
    bint count = 2;
    bint bytes = (bint)p2_heap_vm_partition_size();
    const char *source = NULL;
    char source_copy[512];
    int previous_slot;
    int slot;
    int partition_ready_count = 0;
    int selected_count = 0;
    int child_created_count = 0;
    int child_deleted_count = 0;
    int child_ran_count = 0;
    int child_run_ok_count = 0;
    int child_stack_clean_count = 0;
    int first_failure_slot = -1;
    int last_run_result = BE_OK;
    size_t main_before;
    size_t main_after;
    size_t partition_total_before;
    size_t partition_total_after;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;

    source_copy[0] = '\0';

    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        if (!be_isint(vm, 1)) {
            be_raise(vm, "type_error", "count must be int");
        }
        count = be_toint(vm, 1);
    }
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isint(vm, 2)) {
            be_raise(vm, "type_error", "bytes must be int");
        }
        bytes = be_toint(vm, 2);
    }
    if (be_top(vm) >= 3 && !be_isnil(vm, 3)) {
        if (!be_isstring(vm, 3)) {
            be_raise(vm, "type_error", "source must be string");
        }
        source = be_tostring(vm, 3);
        if (source != NULL) {
            if (strlen(source) >= sizeof(source_copy)) {
                be_raise(vm, "value_error", "source too long");
            }
            strcpy(source_copy, source);
            source = source_copy;
        }
    }
    if (count < 1 || count > BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "count out of range");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }

    previous_slot = p2_heap_vm_partition_current();
    main_before = p2_heap_main_free_bytes();
    partition_total_before = p2_heap_vm_partition_total_bytes();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    for (slot = 0; slot < count; ++slot) {
        int ready = p2_heap_vm_partition_create(slot, (size_t)bytes);
        int selected = 0;
        bvm *child = NULL;

        if (ready) {
            ++partition_ready_count;
            selected = p2_heap_vm_partition_select(slot);
        }
        if (selected) {
            ++selected_count;
            child = be_vm_new();
        }
        if (child != NULL) {
            ++child_created_count;
            if (source != NULL) {
                int res;
                int top;

                ++child_ran_count;
                res = be_dostring(child, source);
                last_run_result = res;
                if (res == BE_OK) {
                    ++child_run_ok_count;
                }
                top = be_top(child);
                be_pop(child, top);
                if (be_top(child) == 0) {
                    ++child_stack_clean_count;
                }
            }
            be_vm_delete(child);
            ++child_deleted_count;
        }
        p2_heap_vm_partition_clear_current();
        if ((ready == 0 || selected == 0 || child == NULL) && first_failure_slot < 0) {
            first_failure_slot = slot;
        }
    }

    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    main_after = p2_heap_main_free_bytes();
    partition_total_after = p2_heap_vm_partition_total_bytes();
    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "count", count);
    p2_map_set_int(vm, "bytes", bytes);
    p2_map_set_int(vm, "partition_ready_count", (bint)partition_ready_count);
    p2_map_set_int(vm, "selected_count", (bint)selected_count);
    p2_map_set_int(vm, "child_created_count", (bint)child_created_count);
    p2_map_set_int(vm, "child_deleted_count", (bint)child_deleted_count);
    p2_map_set_int(vm, "child_ran_count", (bint)child_ran_count);
    p2_map_set_int(vm, "child_run_ok_count", (bint)child_run_ok_count);
    p2_map_set_int(vm, "child_stack_clean_count", (bint)child_stack_clean_count);
    p2_map_set_int(vm, "last_run_result", (bint)last_run_result);
    p2_map_set_int(vm, "first_failure_slot", (bint)first_failure_slot);
    p2_map_set_int(vm, "main_before", (bint)main_before);
    p2_map_set_int(vm, "main_after", (bint)main_after);
    p2_map_set_int(vm, "partition_total_before", (bint)partition_total_before);
    p2_map_set_int(vm, "partition_total_after", (bint)partition_total_after);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "vm_partition_current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static const char *p2_vm_closure_name_or_raise(bvm *vm, int index)
{
    bvalue *value = be_indexof(vm, index);
    bclosure *closure = var_toobj(value);
    const char *name;

    if (!closure->proto || !closure->proto->name) {
        be_raise(vm, "runtime_error", "bad child VM closure");
    }
    if (closure->nupvals != 0) {
        be_raise(vm, "runtime_error", "captured closure transfer is not supported");
    }
    name = str(closure->proto->name);
    if (!name || !name[0]) {
        be_raise(vm, "runtime_error", "bad child VM closure name");
    }
    return name;
}

static int p2_vm_call_impl(bvm *vm, int auto_release)
{
    bint slot = 0;
    bint bytes = (bint)p2_heap_vm_partition_size();
    const char *source;
    const char *name;
    char source_copy[512];
    char name_copy[64];
    int argc;
    int arg_type[8];
    bint arg_int[8];
    int arg_bool[8];
    char arg_string[8][96];
    int arg_int_count = 0;
    int arg_bool_count = 0;
    int arg_nil_count = 0;
    int arg_string_count = 0;
    int previous_slot;
    int i;
    int created;
    int selected = 0;
    int child_created = 0;
    int child_deleted = 0;
    int source_result = BE_OK;
    int call_result = BE_OK;
    int function_found = 0;
    int result_type = 0;
    bint result_int = 0;
    int result_bool = 0;
    char result_string[96];
    int child_stack_top = 0;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;
    int release_attempted = 0;
    int release_result = 0;
    size_t release_before_main = 0;
    size_t release_after_main = 0;
    size_t release_before_total = 0;
    size_t release_after_total = 0;
    int release_before_created = 0;
    int release_after_created = 0;
    bvm *child = NULL;
    int runtime_locked = 0;

    result_string[0] = '\0';
    source_copy[0] = '\0';
    name_copy[0] = '\0';

    if (be_top(vm) < 4) {
        be_raise(vm, "value_error", "expected slot, bytes, source, function name");
    }
    if (!be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    if (!be_isint(vm, 2)) {
        be_raise(vm, "type_error", "bytes must be int");
    }
    if (!be_isstring(vm, 3)) {
        be_raise(vm, "type_error", "source must be string");
    }
    if (!be_isstring(vm, 4) && !be_isclosure(vm, 4)) {
        be_raise(vm, "type_error", "function must be name string or named closure");
    }

    slot = be_toint(vm, 1);
    bytes = be_toint(vm, 2);
    source = be_tostring(vm, 3);
    if (be_isclosure(vm, 4)) {
        name = p2_vm_closure_name_or_raise(vm, 4);
    } else {
        name = be_tostring(vm, 4);
    }
    if (source != NULL) {
        if (strlen(source) >= sizeof(source_copy)) {
            be_raise(vm, "value_error", "source too long");
        }
        strcpy(source_copy, source);
        source = source_copy;
    }
    if (name != NULL) {
        if (strlen(name) >= sizeof(name_copy)) {
            be_raise(vm, "value_error", "function name too long");
        }
        strcpy(name_copy, name);
        name = name_copy;
    }
    argc = be_top(vm) - 4;
    if (argc > 8) {
        be_raise(vm, "value_error", "too many child VM call args");
    }
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }
    for (i = 0; i < argc; ++i) {
        int index = i + 5;

        arg_type[i] = 0;
        arg_int[i] = 0;
        arg_bool[i] = 0;
        arg_string[i][0] = '\0';
        if (be_isint(vm, index)) {
            arg_type[i] = 1;
            arg_int[i] = be_toint(vm, index);
            ++arg_int_count;
        } else if (be_isbool(vm, index)) {
            arg_type[i] = 2;
            arg_bool[i] = be_tobool(vm, index);
            ++arg_bool_count;
        } else if (be_isnil(vm, index)) {
            arg_type[i] = 3;
            ++arg_nil_count;
        } else if (be_isstring(vm, index)) {
            const char *text = be_tostring(vm, index);

            arg_type[i] = 4;
            if (text != NULL) {
                strncpy(arg_string[i], text, sizeof(arg_string[i]) - 1);
                arg_string[i][sizeof(arg_string[i]) - 1] = '\0';
            }
            ++arg_string_count;
        } else {
            be_raise(vm, "type_error", "child VM call args must be int, bool, nil, or string");
        }
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    created = p2_heap_vm_partition_create((int)slot, (size_t)bytes);
    if (created) {
        selected = p2_heap_vm_partition_select((int)slot);
    }
    if (selected) {
        child = be_vm_new();
    }
    if (child != NULL) {
        child_created = 1;
        source_result = be_dostring(child, source);
        be_pop(child, be_top(child));
        if (source_result == BE_OK) {
            function_found = be_getglobal(child, name);
            if (function_found) {
                for (i = 0; i < argc; ++i) {
                    switch (arg_type[i]) {
                    case 1:
                        be_pushint(child, arg_int[i]);
                        break;
                    case 2:
                        be_pushbool(child, arg_bool[i]);
                        break;
                    case 3:
                        be_pushnil(child);
                        break;
                    case 4:
                        be_pushstring(child, arg_string[i]);
                        break;
                    default:
                        be_pushnil(child);
                        break;
                    }
                }
                call_result = be_pcall(child, argc);
                if (call_result == BE_OK && be_top(child) > 0) {
                    int result_index = -(argc + 1);

                    if (be_isint(child, result_index)) {
                        result_type = 1;
                        result_int = be_toint(child, result_index);
                    } else if (be_isbool(child, result_index)) {
                        result_type = 2;
                        result_bool = be_tobool(child, result_index);
                    } else if (be_isnil(child, result_index)) {
                        result_type = 3;
                    } else if (be_isstring(child, result_index)) {
                        const char *text = be_tostring(child, result_index);

                        result_type = 4;
                        if (text != NULL) {
                            strncpy(result_string, text, sizeof(result_string) - 1);
                            result_string[sizeof(result_string) - 1] = '\0';
                        }
                    }
                }
            } else {
                be_pop(child, be_top(child));
                call_result = BE_SYNTAX_ERROR;
            }
        }
        {
            int top = be_top(child);

            be_pop(child, top);
            child_stack_top = be_top(child);
        }
        be_vm_delete(child);
        child_deleted = 1;
    }
    p2_heap_vm_partition_clear_current();
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();

    if (auto_release) {
        release_attempted = 1;
        release_before_main = p2_heap_main_free_bytes();
        release_before_total = p2_heap_vm_partition_total_bytes();
        release_before_created = p2_heap_vm_partition_created_count();
        release_result = p2_heap_vm_partition_release((int)slot);
        release_after_main = p2_heap_main_free_bytes();
        release_after_total = p2_heap_vm_partition_total_bytes();
        release_after_created = p2_heap_vm_partition_created_count();
    }
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "bytes", bytes);
    p2_map_set_int(vm, "argc", (bint)argc);
    p2_map_set_int(vm, "arg_int_count", (bint)arg_int_count);
    p2_map_set_int(vm, "arg_bool_count", (bint)arg_bool_count);
    p2_map_set_int(vm, "arg_nil_count", (bint)arg_nil_count);
    p2_map_set_int(vm, "arg_string_count", (bint)arg_string_count);
    p2_map_set_bool(vm, "partition_ready", created);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "child_created", child_created);
    p2_map_set_bool(vm, "child_deleted", child_deleted);
    p2_map_set_bool(vm, "function_found", function_found);
    p2_map_set_int(vm, "source_result", (bint)source_result);
    p2_map_set_int(vm, "call_result", (bint)call_result);
    p2_map_set_int(vm, "result_type", (bint)result_type);
    p2_map_set_int(vm, "result_int", result_int);
    p2_map_set_bool(vm, "result_bool", result_bool);
    p2_map_set_string(vm, "result_string", result_string);
    p2_map_set_int(vm, "child_stack_top", (bint)child_stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "vm_partition_current", (bint)p2_heap_vm_partition_current());
    p2_map_set_bool(vm, "release_attempted", release_attempted);
    p2_map_set_bool(vm, "released", release_result);
    p2_map_set_bool(vm, "partition_ready_after", p2_heap_vm_partition_ready((int)slot));
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_int(vm, "release_before_main", (bint)release_before_main);
    p2_map_set_int(vm, "release_after_main", (bint)release_after_main);
    p2_map_set_int(vm, "release_before_total", (bint)release_before_total);
    p2_map_set_int(vm, "release_after_total", (bint)release_after_total);
    p2_map_set_int(vm, "release_before_created", (bint)release_before_created);
    p2_map_set_int(vm, "release_after_created", (bint)release_after_created);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_call_probe(bvm *vm)
{
    return p2_vm_call_impl(vm, 0);
}

static int m_p2_vm_call_once(bvm *vm)
{
    return p2_vm_call_impl(vm, 1);
}

static int m_p2_vm_open(bvm *vm)
{
    bint slot;
    bint bytes = (bint)p2_heap_vm_partition_size();
    int previous_slot;
    int created;
    int selected = 0;
    int child_created = 0;
    int already_active = 0;
    int runtime_locked = 0;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;

    p2_child_vm_handles_init();
    if (be_top(vm) < 1 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    slot = be_toint(vm, 1);
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isint(vm, 2)) {
            be_raise(vm, "type_error", "bytes must be int");
        }
        bytes = be_toint(vm, 2);
    }
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    already_active = p2_child_vm_handles[slot].active;
    created = p2_heap_vm_partition_create((int)slot, (size_t)bytes);
    if (created && !already_active) {
        selected = p2_heap_vm_partition_select((int)slot);
        if (selected) {
            p2_child_vm_handles[slot].child = be_vm_new();
            if (p2_child_vm_handles[slot].child != NULL) {
                p2_child_vm_handles[slot].bytes = (size_t)bytes;
                p2_child_vm_handles[slot].active = 1;
                child_created = 1;
            }
            p2_heap_vm_partition_clear_current();
        }
    }
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "bytes", bytes);
    p2_map_set_bool(vm, "partition_ready", created);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "child_created", child_created);
    p2_map_set_bool(vm, "already_active", already_active);
    p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_eval(bvm *vm)
{
    bint slot;
    const char *source;
    char source_copy[512];
    int previous_slot;
    int selected = 0;
    int run_result = BE_SYNTAX_ERROR;
    int stack_top = 0;
    int runtime_locked = 0;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;

    p2_child_vm_handles_init();
    source_copy[0] = '\0';
    if (be_top(vm) < 2 || !be_isint(vm, 1) || !be_isstring(vm, 2)) {
        be_raise(vm, "type_error", "expected slot, source");
    }
    slot = be_toint(vm, 1);
    source = be_tostring(vm, 2);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (source != NULL) {
        if (strlen(source) >= sizeof(source_copy)) {
            be_raise(vm, "value_error", "source too long");
        }
        strcpy(source_copy, source);
        source = source_copy;
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    if (p2_child_vm_handles[slot].active && p2_child_vm_handles[slot].child != NULL) {
        selected = p2_heap_vm_partition_select((int)slot);
        if (selected) {
            run_result = be_dostring(p2_child_vm_handles[slot].child, source);
            be_pop(p2_child_vm_handles[slot].child, be_top(p2_child_vm_handles[slot].child));
            stack_top = be_top(p2_child_vm_handles[slot].child);
            p2_heap_vm_partition_clear_current();
        }
    }
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_int(vm, "run_result", (bint)run_result);
    p2_map_set_int(vm, "stack_top", (bint)stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_get(bvm *vm)
{
    bint slot;
    const char *name;
    char name_copy[64];
    int previous_slot;
    int selected = 0;
    int found = 0;
    int result_type = 0;
    bint result_int = 0;
    int result_bool = 0;
    int runtime_locked = 0;
    char result_string[96];

    p2_child_vm_handles_init();
    name_copy[0] = '\0';
    result_string[0] = '\0';
    if (be_top(vm) < 2 || !be_isint(vm, 1) || !be_isstring(vm, 2)) {
        be_raise(vm, "type_error", "expected slot, name");
    }
    slot = be_toint(vm, 1);
    name = be_tostring(vm, 2);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (name != NULL) {
        if (strlen(name) >= sizeof(name_copy)) {
            be_raise(vm, "value_error", "name too long");
        }
        strcpy(name_copy, name);
        name = name_copy;
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    if (p2_child_vm_handles[slot].active && p2_child_vm_handles[slot].child != NULL) {
        selected = p2_heap_vm_partition_select((int)slot);
        if (selected) {
            found = be_getglobal(p2_child_vm_handles[slot].child, name);
            if (found && be_top(p2_child_vm_handles[slot].child) > 0) {
                if (be_isint(p2_child_vm_handles[slot].child, -1)) {
                    result_type = 1;
                    result_int = be_toint(p2_child_vm_handles[slot].child, -1);
                } else if (be_isbool(p2_child_vm_handles[slot].child, -1)) {
                    result_type = 2;
                    result_bool = be_tobool(p2_child_vm_handles[slot].child, -1);
                } else if (be_isnil(p2_child_vm_handles[slot].child, -1)) {
                    result_type = 3;
                } else if (be_isstring(p2_child_vm_handles[slot].child, -1)) {
                    const char *text = be_tostring(p2_child_vm_handles[slot].child, -1);

                    result_type = 4;
                    if (text != NULL) {
                        strncpy(result_string, text, sizeof(result_string) - 1);
                        result_string[sizeof(result_string) - 1] = '\0';
                    }
                }
            }
            be_pop(p2_child_vm_handles[slot].child, be_top(p2_child_vm_handles[slot].child));
            p2_heap_vm_partition_clear_current();
        }
    }
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_bool(vm, "found", found);
    p2_map_set_int(vm, "result_type", (bint)result_type);
    p2_map_set_int(vm, "result_int", result_int);
    p2_map_set_bool(vm, "result_bool", result_bool);
    p2_map_set_string(vm, "result_string", result_string);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_invoke(bvm *vm)
{
    bint slot;
    const char *name;
    char name_copy[64];
    int argc;
    int arg_type[8];
    bint arg_int[8];
    int arg_bool[8];
    char arg_string[8][96];
    int arg_int_count = 0;
    int arg_bool_count = 0;
    int arg_nil_count = 0;
    int arg_string_count = 0;
    int previous_slot;
    int selected = 0;
    int function_found = 0;
    int call_result = BE_SYNTAX_ERROR;
    int result_type = 0;
    bint result_int = 0;
    int result_bool = 0;
    char result_string[96];
    int child_stack_top = 0;
    int runtime_locked = 0;
    size_t wrong_free_before;
    size_t wrong_realloc_before;
    size_t wrong_free_after;
    size_t wrong_realloc_after;
    int i;
    bvm *child = NULL;

    p2_child_vm_handles_init();
    name_copy[0] = '\0';
    result_string[0] = '\0';
    if (be_top(vm) < 2 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "expected slot, function name");
    }
    if (!be_isstring(vm, 2) && !be_isclosure(vm, 2)) {
        be_raise(vm, "type_error", "function must be name string or named closure");
    }

    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (be_isclosure(vm, 2)) {
        name = p2_vm_closure_name_or_raise(vm, 2);
    } else {
        name = be_tostring(vm, 2);
    }
    if (name != NULL) {
        if (strlen(name) >= sizeof(name_copy)) {
            be_raise(vm, "value_error", "function name too long");
        }
        strcpy(name_copy, name);
        name = name_copy;
    }

    argc = be_top(vm) - 2;
    if (argc > 8) {
        be_raise(vm, "value_error", "too many child VM call args");
    }
    for (i = 0; i < argc; ++i) {
        int index = i + 3;

        arg_type[i] = 0;
        arg_int[i] = 0;
        arg_bool[i] = 0;
        arg_string[i][0] = '\0';
        if (be_isint(vm, index)) {
            arg_type[i] = 1;
            arg_int[i] = be_toint(vm, index);
            ++arg_int_count;
        } else if (be_isbool(vm, index)) {
            arg_type[i] = 2;
            arg_bool[i] = be_tobool(vm, index);
            ++arg_bool_count;
        } else if (be_isnil(vm, index)) {
            arg_type[i] = 3;
            ++arg_nil_count;
        } else if (be_isstring(vm, index)) {
            const char *text = be_tostring(vm, index);

            arg_type[i] = 4;
            if (text != NULL) {
                strncpy(arg_string[i], text, sizeof(arg_string[i]) - 1);
                arg_string[i][sizeof(arg_string[i]) - 1] = '\0';
            }
            ++arg_string_count;
        } else {
            be_raise(vm, "type_error", "child VM call args must be int, bool, nil, or string");
        }
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    wrong_free_before = p2_heap_wrong_free_count();
    wrong_realloc_before = p2_heap_wrong_realloc_count();

    if (p2_child_vm_handles[slot].active && p2_child_vm_handles[slot].child != NULL) {
        child = p2_child_vm_handles[slot].child;
        selected = p2_heap_vm_partition_select((int)slot);
        if (selected) {
            function_found = be_getglobal(child, name);
            if (function_found) {
                for (i = 0; i < argc; ++i) {
                    switch (arg_type[i]) {
                    case 1:
                        be_pushint(child, arg_int[i]);
                        break;
                    case 2:
                        be_pushbool(child, arg_bool[i]);
                        break;
                    case 3:
                        be_pushnil(child);
                        break;
                    case 4:
                        be_pushstring(child, arg_string[i]);
                        break;
                    default:
                        be_pushnil(child);
                        break;
                    }
                }
                call_result = be_pcall(child, argc);
                if (call_result == BE_OK && be_top(child) > 0) {
                    int result_index = -(argc + 1);

                    if (be_isint(child, result_index)) {
                        result_type = 1;
                        result_int = be_toint(child, result_index);
                    } else if (be_isbool(child, result_index)) {
                        result_type = 2;
                        result_bool = be_tobool(child, result_index);
                    } else if (be_isnil(child, result_index)) {
                        result_type = 3;
                    } else if (be_isstring(child, result_index)) {
                        const char *text = be_tostring(child, result_index);

                        result_type = 4;
                        if (text != NULL) {
                            strncpy(result_string, text, sizeof(result_string) - 1);
                            result_string[sizeof(result_string) - 1] = '\0';
                        }
                    }
                }
            }
            be_pop(child, be_top(child));
            child_stack_top = be_top(child);
            p2_heap_vm_partition_clear_current();
        }
    }
    if (previous_slot >= 0) {
        p2_heap_vm_partition_select(previous_slot);
    }

    wrong_free_after = p2_heap_wrong_free_count();
    wrong_realloc_after = p2_heap_wrong_realloc_count();
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "argc", (bint)argc);
    p2_map_set_int(vm, "arg_int_count", (bint)arg_int_count);
    p2_map_set_int(vm, "arg_bool_count", (bint)arg_bool_count);
    p2_map_set_int(vm, "arg_nil_count", (bint)arg_nil_count);
    p2_map_set_int(vm, "arg_string_count", (bint)arg_string_count);
    p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_bool(vm, "function_found", function_found);
    p2_map_set_int(vm, "call_result", (bint)call_result);
    p2_map_set_int(vm, "result_type", (bint)result_type);
    p2_map_set_int(vm, "result_int", result_int);
    p2_map_set_bool(vm, "result_bool", result_bool);
    p2_map_set_string(vm, "result_string", result_string);
    p2_map_set_int(vm, "child_stack_top", (bint)child_stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)(wrong_free_after - wrong_free_before));
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)(wrong_realloc_after - wrong_realloc_before));
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_cog_call_once(bvm *vm)
{
    bint slot;
    bint bytes;
    const char *source;
    const char *name;
    char source_copy[512];
    char name_copy[64];
    int argc;
    uint32_t stack_size = 8192u;
    int i;
    int result = -1;
    int raw_running = 0;
    int stack_freed = 0;
    int released = 0;
    int wait_count = 0;
    p2_child_vm_cog_once_job *job;
    void *stack_mem;

    source_copy[0] = '\0';
    name_copy[0] = '\0';
    if (be_top(vm) < 4) {
        be_raise(vm, "value_error", "expected slot, bytes, source, function name");
    }
    if (!be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    if (!be_isint(vm, 2)) {
        be_raise(vm, "type_error", "bytes must be int");
    }
    if (!be_isstring(vm, 3)) {
        be_raise(vm, "type_error", "source must be string");
    }
    if (!be_isstring(vm, 4) && !be_isclosure(vm, 4)) {
        be_raise(vm, "type_error", "function must be name string or named closure");
    }
    slot = be_toint(vm, 1);
    bytes = be_toint(vm, 2);
    source = be_tostring(vm, 3);
    if (be_isclosure(vm, 4)) {
        name = p2_vm_closure_name_or_raise(vm, 4);
    } else {
        name = be_tostring(vm, 4);
    }
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (bytes < (bint)p2_heap_vm_partition_size()) {
        be_raise(vm, "value_error", "bytes below VM partition minimum");
    }
    if (source != NULL) {
        if (strlen(source) >= sizeof(source_copy)) {
            be_raise(vm, "value_error", "source too long");
        }
        strcpy(source_copy, source);
        source = source_copy;
    }
    if (name != NULL) {
        if (strlen(name) >= sizeof(name_copy)) {
            be_raise(vm, "value_error", "function name too long");
        }
        strcpy(name_copy, name);
        name = name_copy;
    }
    argc = be_top(vm) - 4;
    if (argc > 8) {
        be_raise(vm, "value_error", "too many child VM cog args");
    }

    job = &p2_child_vm_cog_once_jobs[slot];
    memset(job, 0, sizeof(*job));
    job->status = 0;
    job->cog_id = -1;
    job->slot = (int)slot;
    job->bytes = (size_t)bytes;
    strcpy(job->source, source ? source : "");
    strcpy(job->name, name ? name : "");
    job->argc = argc;
    for (i = 0; i < argc; ++i) {
        int index = i + 5;

        job->arg_type[i] = 0;
        job->arg_int[i] = 0;
        job->arg_bool[i] = 0;
        job->arg_string[i][0] = '\0';
        if (be_isint(vm, index)) {
            job->arg_type[i] = 1;
            job->arg_int[i] = be_toint(vm, index);
        } else if (be_isbool(vm, index)) {
            job->arg_type[i] = 2;
            job->arg_bool[i] = be_tobool(vm, index);
        } else if (be_isnil(vm, index)) {
            job->arg_type[i] = 3;
        } else if (be_isstring(vm, index)) {
            const char *text = be_tostring(vm, index);

            job->arg_type[i] = 4;
            if (text != NULL) {
                strncpy(job->arg_string[i], text, sizeof(job->arg_string[i]) - 1);
                job->arg_string[i][sizeof(job->arg_string[i]) - 1] = '\0';
            }
        } else {
            be_raise(vm, "type_error", "child VM cog args must be int, bool, nil, or string");
        }
    }

    stack_mem = p2_cog_stack_alloc(stack_size);
    if (stack_mem == NULL) {
        be_raise(vm, "memory_error", "failed to allocate isolated child VM cog stack");
    }
    result = p2_catalina_cogstart_C(p2_child_vm_cog_once_entry, job, stack_mem, stack_size);
    if (result >= 0 && result < 8) {
        job->cog_id = result;
        while ((job->status == 0 || job->status == 1) && wait_count < 10000) {
            _waitus(1000);
            ++wait_count;
        }
        if (job->status == 2 && _cogchk(result)) {
            job->status = 4;
            _cogstop(result);
        }
        while (_cogchk(result) && wait_count < 10200) {
            _waitus(1000);
            ++wait_count;
        }
        raw_running = _cogchk(result) ? 1 : 0;
        if (!raw_running) {
            p2_cog_stack_free(stack_mem);
            stack_freed = 1;
            released = p2_heap_vm_partition_release((int)slot);
        }
    } else {
        p2_cog_stack_free(stack_mem);
        stack_freed = 1;
    }

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "bytes", bytes);
    p2_map_set_int(vm, "cog", (bint)result);
    p2_map_set_bool(vm, "started", result >= 0);
    p2_map_set_int(vm, "status", (bint)job->status);
    p2_map_set_bool(vm, "raw_running", raw_running);
    p2_map_set_bool(vm, "stack_freed", stack_freed);
    p2_map_set_bool(vm, "released", released);
    p2_map_set_bool(vm, "partition_ready", job->partition_ready);
    p2_map_set_bool(vm, "selected", job->selected);
    p2_map_set_bool(vm, "child_created", job->child_created);
    p2_map_set_bool(vm, "child_deleted", job->child_deleted);
    p2_map_set_bool(vm, "function_found", job->function_found);
    p2_map_set_int(vm, "source_result", (bint)job->source_result);
    p2_map_set_int(vm, "call_result", (bint)job->call_result);
    p2_map_set_int(vm, "result_type", (bint)job->result_type);
    p2_map_set_int(vm, "result_int", job->result_int);
    p2_map_set_bool(vm, "result_bool", job->result_bool);
    p2_map_set_string(vm, "result_string", job->result_string);
    p2_map_set_int(vm, "child_stack_top", (bint)job->child_stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)job->wrong_free_delta);
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)job->wrong_realloc_delta);
    p2_map_set_int(vm, "argc", (bint)argc);
    p2_map_set_int(vm, "stack_bytes", (bint)stack_size);
    p2_map_set_int(vm, "wait_count", (bint)wait_count);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_cog_start(bvm *vm)
{
    bint slot;
    const char *name;
    char name_copy[64];
    int argc;
    uint32_t stack_size = 8192u;
    int i;
    int result = -1;
    int final_status = 0;
    int raw_running = 0;
    int stack_freed = 0;
    p2_child_vm_handle *handle;
    p2_child_vm_cog_job *job;
    void *stack_mem;
    int wait_count = 0;

    p2_child_vm_handles_init();
    name_copy[0] = '\0';
    if (be_top(vm) < 2 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "expected slot, function name");
    }
    if (!be_isstring(vm, 2) && !be_isclosure(vm, 2)) {
        be_raise(vm, "type_error", "function must be name string or named closure");
    }
    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    if (be_isclosure(vm, 2)) {
        name = p2_vm_closure_name_or_raise(vm, 2);
    } else {
        name = be_tostring(vm, 2);
    }
    if (name != NULL) {
        if (strlen(name) >= sizeof(name_copy)) {
            be_raise(vm, "value_error", "function name too long");
        }
        strcpy(name_copy, name);
        name = name_copy;
    }

    argc = be_top(vm) - 2;
    if (argc > 8) {
        be_raise(vm, "value_error", "too many child VM call args");
    }

    handle = &p2_child_vm_handles[slot];
    job = &p2_child_vm_cog_jobs[slot];
    if (!handle->active || handle->child == NULL) {
        be_raise(vm, "runtime_error", "child VM slot is not open");
    }
    if (handle->cog_status == 1) {
        be_raise(vm, "runtime_error", "child VM cog already running");
    }
    if (handle->cog_stack != NULL) {
        if (handle->cog_id >= 0 && _cogchk(handle->cog_id)) {
            be_raise(vm, "runtime_error", "previous child VM cog still running");
        }
        p2_cog_stack_free(handle->cog_stack);
        handle->cog_stack = NULL;
        handle->cog_stack_size = 0;
    }

    memset(job, 0, sizeof(*job));
    job->slot = (int)slot;
    strcpy(job->name, name ? name : "");
    job->argc = argc;
    for (i = 0; i < argc; ++i) {
        int index = i + 3;

        job->arg_type[i] = 0;
        job->arg_int[i] = 0;
        job->arg_bool[i] = 0;
        job->arg_string[i][0] = '\0';
        if (be_isint(vm, index)) {
            job->arg_type[i] = 1;
            job->arg_int[i] = be_toint(vm, index);
        } else if (be_isbool(vm, index)) {
            job->arg_type[i] = 2;
            job->arg_bool[i] = be_tobool(vm, index);
        } else if (be_isnil(vm, index)) {
            job->arg_type[i] = 3;
        } else if (be_isstring(vm, index)) {
            const char *text = be_tostring(vm, index);

            job->arg_type[i] = 4;
            if (text != NULL) {
                strncpy(job->arg_string[i], text, sizeof(job->arg_string[i]) - 1);
                job->arg_string[i][sizeof(job->arg_string[i]) - 1] = '\0';
            }
        } else {
            be_raise(vm, "type_error", "child VM cog args must be int, bool, nil, or string");
        }
    }

    stack_mem = p2_cog_stack_alloc(stack_size);
    if (stack_mem == NULL) {
        be_raise(vm, "memory_error", "failed to allocate child VM cog stack");
    }

    handle->cog_status = 0;
    handle->cog_id = -1;
    handle->cog_call_result = BE_SYNTAX_ERROR;
    handle->cog_function_found = 0;
    handle->cog_result_type = 0;
    handle->cog_result_int = 0;
    handle->cog_result_bool = 0;
    handle->cog_result_string[0] = '\0';
    handle->cog_child_stack_top = 0;
    handle->cog_wrong_free_delta = 0;
    handle->cog_wrong_realloc_delta = 0;
    result = p2_catalina_cogstart_C(p2_child_vm_cog_entry, job, stack_mem, stack_size);
    if (result >= 0 && result < 8) {
        handle->cog_stack = stack_mem;
        handle->cog_stack_size = stack_size;
        handle->cog_id = result;
        while ((handle->cog_status == 0 || handle->cog_status == 1) && wait_count < 5000) {
            _waitus(1000);
            ++wait_count;
        }
        final_status = handle->cog_status;
        if ((final_status == 2 || final_status == 3) && _cogchk(result)) {
            handle->cog_status = 4;
            _cogstop(result);
        }
        while (_cogchk(result) && wait_count < 5200) {
            _waitus(1000);
            ++wait_count;
        }
        if (_cogchk(result)) {
            _cogstop(result);
            while (_cogchk(result) && wait_count < 5400) {
                _waitus(1000);
                ++wait_count;
            }
        }
        raw_running = _cogchk(result) ? 1 : 0;
        if (!raw_running) {
            p2_cog_stack_free(stack_mem);
            handle->cog_stack = NULL;
            handle->cog_stack_size = 0;
            stack_freed = 1;
        }
        handle->cog_status = final_status;
    } else {
        p2_cog_stack_free(stack_mem);
        stack_freed = 1;
    }

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "cog", (bint)result);
    p2_map_set_bool(vm, "started", result >= 0);
    p2_map_set_bool(vm, "active", handle->active);
    p2_map_set_int(vm, "status", (bint)handle->cog_status);
    p2_map_set_bool(vm, "raw_running", raw_running);
    p2_map_set_bool(vm, "stack_freed", stack_freed);
    p2_map_set_int(vm, "wait_count", (bint)wait_count);
    p2_map_set_bool(vm, "function_found", handle->cog_function_found);
    p2_map_set_int(vm, "call_result", (bint)handle->cog_call_result);
    p2_map_set_int(vm, "result_type", (bint)handle->cog_result_type);
    p2_map_set_int(vm, "result_int", handle->cog_result_int);
    p2_map_set_bool(vm, "result_bool", handle->cog_result_bool);
    p2_map_set_string(vm, "result_string", handle->cog_result_string);
    p2_map_set_int(vm, "child_stack_top", (bint)handle->cog_child_stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)handle->cog_wrong_free_delta);
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)handle->cog_wrong_realloc_delta);
    p2_map_set_int(vm, "argc", (bint)argc);
    p2_map_set_int(vm, "stack_bytes", (bint)stack_size);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_cog_ping(bvm *vm)
{
    bint input = 20;
    bint slot = 0;
    uint32_t stack_size = 2048u;
    p2_child_vm_cog_ping_job *job;
    void *stack_mem;
    int result;
    int wait_count = 0;
    int raw_running = 0;
    int stack_freed = 0;
    int thread_mode = 0;
    uint32_t startup_marker = 0;
    uint32_t pasm_marker = 0;
    uint32_t pasm_cog_seen = 0xffffffffu;
    int pasm_cog = -1;

    if (be_top(vm) >= 1 && !be_isnil(vm, 1)) {
        if (!be_isint(vm, 1)) {
            be_raise(vm, "type_error", "input must be int");
        }
        input = be_toint(vm, 1);
    }
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isint(vm, 2)) {
            be_raise(vm, "type_error", "slot must be int");
        }
        slot = be_toint(vm, 2);
    }
    if (slot < 0 || slot >= 8) {
        be_raise(vm, "value_error", "slot out of range");
    }

    job = (p2_child_vm_cog_ping_job *)p2_hub_mem_alloc(sizeof(*job));
    if (job == NULL) {
        be_raise(vm, "memory_error", "failed to allocate cog ping mailbox");
    }
    job->status = 0;
    job->cog_id = -1;
    job->input = (int)input;
    job->result = 0;

    stack_mem = p2_cog_stack_alloc(stack_size);
    if (stack_mem == NULL) {
        p2_hub_mem_free(job);
        be_raise(vm, "memory_error", "failed to allocate cog ping stack");
    }
    ((volatile uint32_t *)stack_mem)[0] = 0;
    pasm_cog = p2_cog_marker_probe(6, &pasm_marker, &pasm_cog_seen);

#ifdef __CATALINA_libthreads
    thread_mode = 1;
    result = _threadstart_C(p2_child_vm_thread_ping_entry, 0, (char **)job, stack_mem, stack_size);
#else
    result = p2_catalina_cogstart_C(p2_child_vm_cog_ping_entry, job, stack_mem, stack_size);
#endif
    if (result >= 0 && result < 8) {
        job->cog_id = result;
        while ((job->status == 0 || job->status == 1) && wait_count < 5000) {
            _waitus(1000);
            ++wait_count;
        }
        if (job->status == 2 && _cogchk(result)) {
            job->status = 3;
            _cogstop(result);
        }
        while (_cogchk(result) && wait_count < 5200) {
            _waitus(1000);
            ++wait_count;
        }
        if (_cogchk(result)) {
            _cogstop(result);
            while (_cogchk(result) && wait_count < 5400) {
                _waitus(1000);
                ++wait_count;
            }
        }
        startup_marker = ((volatile uint32_t *)stack_mem)[0];
        raw_running = _cogchk(result) ? 1 : 0;
        if (!raw_running) {
            p2_cog_stack_free(stack_mem);
            stack_freed = 1;
        }
#if defined(__CATALINA_LARGE)
        if (result >= 0 && result < 8 && p2_xmm_private_caches[result].child_cog_data != NULL) {
            volatile uint32_t *data = (volatile uint32_t *)p2_xmm_private_caches[result].child_cog_data;

            p2_xmm_cog_data_word0_after = data[0];
            p2_xmm_cog_data_word1_after = data[1];
            p2_xmm_cog_data_word2_after = data[2];
            p2_xmm_cog_data_word3_after = data[3];
            p2_xmm_cog_data_word4_after = data[4];
            p2_xmm_cog_data_word5_after = data[5];
            p2_xmm_cog_data_word6_after = data[6];
            p2_xmm_cog_data_word7_after = data[7];
        }
        p2_xmm_private_cache_release(result);
#endif
    } else {
        p2_cog_stack_free(stack_mem);
        stack_freed = 1;
    }

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_int(vm, "input", input);
    p2_map_set_int(vm, "cog", (bint)result);
    p2_map_set_bool(vm, "started", result >= 0);
    p2_map_set_int(vm, "status", (bint)job->status);
    p2_map_set_int(vm, "result", (bint)job->result);
    p2_map_set_int(vm, "wait_count", (bint)wait_count);
    p2_map_set_bool(vm, "raw_running", raw_running);
    p2_map_set_bool(vm, "stack_freed", stack_freed);
    p2_map_set_bool(vm, "thread_mode", thread_mode);
    p2_map_set_int(vm, "startup_marker", (bint)startup_marker);
    p2_map_set_int(vm, "pasm_cog", (bint)pasm_cog);
    p2_map_set_int(vm, "pasm_marker", (bint)pasm_marker);
    p2_map_set_int(vm, "pasm_cog_seen", (bint)pasm_cog_seen);
#if defined(__CATALINA_LARGE)
    p2_map_set_int(vm, "after_cache_pasm_cog", (bint)p2_xmm_after_cache_pasm_cog);
    p2_map_set_int(vm, "after_cache_pasm_marker", (bint)p2_xmm_after_cache_pasm_marker);
    p2_map_set_int(vm, "after_cache_pasm_seen", (bint)p2_xmm_after_cache_pasm_seen);
    p2_map_set_int(vm, "xmm_kernel_word0", (bint)p2_xmm_kernel_word0);
    p2_map_set_int(vm, "xmm_kernel_word90", (bint)p2_xmm_kernel_word90);
    p2_map_set_int(vm, "xmm_kernel_word91", (bint)p2_xmm_kernel_word91);
    p2_map_set_int(vm, "xmm_kernel_addr", (bint)p2_xmm_kernel_addr);
    p2_map_set_int(vm, "xmm_cog_data_addr", (bint)p2_xmm_cog_data_addr);
    p2_map_set_int(vm, "large_pasm_cog", (bint)p2_xmm_large_pasm_cog);
    p2_map_set_int(vm, "large_pasm_marker", (bint)p2_xmm_large_pasm_marker);
    p2_map_set_int(vm, "large_pasm_seen", (bint)p2_xmm_large_pasm_seen);
    p2_map_set_int(vm, "xmm_cog_data_word0_after", (bint)p2_xmm_cog_data_word0_after);
    p2_map_set_int(vm, "xmm_cog_data_word1_after", (bint)p2_xmm_cog_data_word1_after);
    p2_map_set_int(vm, "xmm_cog_data_word2_after", (bint)p2_xmm_cog_data_word2_after);
    p2_map_set_int(vm, "xmm_cog_data_word3_after", (bint)p2_xmm_cog_data_word3_after);
    p2_map_set_int(vm, "xmm_cog_data_word4_after", (bint)p2_xmm_cog_data_word4_after);
    p2_map_set_int(vm, "xmm_cog_data_word5_after", (bint)p2_xmm_cog_data_word5_after);
    p2_map_set_int(vm, "xmm_cog_data_word6_after", (bint)p2_xmm_cog_data_word6_after);
    p2_map_set_int(vm, "xmm_cog_data_word7_after", (bint)p2_xmm_cog_data_word7_after);
#endif
    p2_map_set_int(vm, "stack_bytes", (bint)stack_size);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    p2_hub_mem_free(job);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_cog_info(bvm *vm)
{
    bint slot;
    p2_child_vm_handle *handle;
    int raw_running = 0;

    p2_child_vm_handles_init();
    if (be_top(vm) < 1 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }
    handle = &p2_child_vm_handles[slot];
    if (handle->cog_id >= 0 && handle->cog_id < 8) {
        raw_running = _cogchk(handle->cog_id) ? 1 : 0;
    }

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "active", handle->active);
    p2_map_set_int(vm, "status", (bint)handle->cog_status);
    p2_map_set_int(vm, "cog", (bint)handle->cog_id);
    p2_map_set_bool(vm, "running", handle->cog_status == 1);
    p2_map_set_bool(vm, "raw_running", raw_running);
    p2_map_set_bool(vm, "function_found", handle->cog_function_found);
    p2_map_set_int(vm, "call_result", (bint)handle->cog_call_result);
    p2_map_set_int(vm, "result_type", (bint)handle->cog_result_type);
    p2_map_set_int(vm, "result_int", handle->cog_result_int);
    p2_map_set_bool(vm, "result_bool", handle->cog_result_bool);
    p2_map_set_string(vm, "result_string", handle->cog_result_string);
    p2_map_set_int(vm, "child_stack_top", (bint)handle->cog_child_stack_top);
    p2_map_set_int(vm, "wrong_free_delta", (bint)handle->cog_wrong_free_delta);
    p2_map_set_int(vm, "wrong_realloc_delta", (bint)handle->cog_wrong_realloc_delta);
    p2_map_set_int(vm, "stack_bytes", (bint)handle->cog_stack_size);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_lock_info(bvm *vm)
{
    p2_child_vm_runtime_lock_init();
    be_newobject(vm, "map");
    p2_map_set_bool(vm, "available", p2_child_vm_runtime_lock >= 0);
    p2_map_set_int(vm, "lock", (bint)p2_child_vm_runtime_lock);
    p2_map_set_bool(vm, "failed", p2_child_vm_runtime_lock_failed);
    p2_map_set_int(vm, "acquires", (bint)p2_child_vm_runtime_lock_acquires);
    p2_map_set_int(vm, "contentions", (bint)p2_child_vm_runtime_lock_contentions);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_close(bvm *vm)
{
    bint slot;
    int previous_slot;
    int selected = 0;
    int was_active;
    int child_deleted = 0;
    int released = 0;
    size_t release_before_main;
    size_t release_after_main;
    size_t release_before_total;
    size_t release_after_total;
    int release_before_created;
    int release_after_created;
    int runtime_locked = 0;

    p2_child_vm_handles_init();
    if (be_top(vm) < 1 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    previous_slot = p2_heap_vm_partition_current();
    was_active = p2_child_vm_handles[slot].active;
    if (p2_child_vm_handles[slot].cog_status == 1 ||
        (p2_child_vm_handles[slot].cog_id >= 0 && _cogchk(p2_child_vm_handles[slot].cog_id))) {
        p2_child_vm_runtime_lock_leave(runtime_locked);
        be_newobject(vm, "map");
        p2_map_set_int(vm, "slot", slot);
        p2_map_set_bool(vm, "was_active", was_active);
        p2_map_set_bool(vm, "selected", 0);
        p2_map_set_bool(vm, "child_deleted", 0);
        p2_map_set_bool(vm, "released", 0);
        p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
        p2_map_set_bool(vm, "partition_ready_after", p2_heap_vm_partition_ready((int)slot));
        p2_map_set_bool(vm, "runtime_locked", runtime_locked);
        p2_map_set_int(vm, "release_before_main", (bint)0);
        p2_map_set_int(vm, "release_after_main", (bint)0);
        p2_map_set_int(vm, "release_before_total", (bint)0);
        p2_map_set_int(vm, "release_after_total", (bint)0);
        p2_map_set_int(vm, "release_before_created", (bint)0);
        p2_map_set_int(vm, "release_after_created", (bint)0);
        p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
        be_pop(vm, 1);
        be_return(vm);
    }
    if (was_active && p2_child_vm_handles[slot].child != NULL) {
        selected = p2_heap_vm_partition_select((int)slot);
        if (selected) {
            be_vm_delete(p2_child_vm_handles[slot].child);
            p2_child_vm_handles[slot].child = NULL;
            p2_child_vm_handles[slot].bytes = 0;
            p2_child_vm_handles[slot].active = 0;
            child_deleted = 1;
            p2_heap_vm_partition_clear_current();
        }
    }
    if (p2_child_vm_handles[slot].cog_stack != NULL) {
        p2_cog_stack_free(p2_child_vm_handles[slot].cog_stack);
        p2_child_vm_handles[slot].cog_stack = NULL;
        p2_child_vm_handles[slot].cog_stack_size = 0;
    }

    release_before_main = p2_heap_main_free_bytes();
    release_before_total = p2_heap_vm_partition_total_bytes();
    release_before_created = p2_heap_vm_partition_created_count();
    released = p2_heap_vm_partition_release((int)slot);
    release_after_main = p2_heap_main_free_bytes();
    release_after_total = p2_heap_vm_partition_total_bytes();
    release_after_created = p2_heap_vm_partition_created_count();

    if (previous_slot >= 0 && previous_slot != slot) {
        p2_heap_vm_partition_select(previous_slot);
    }
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "was_active", was_active);
    p2_map_set_bool(vm, "selected", selected);
    p2_map_set_bool(vm, "child_deleted", child_deleted);
    p2_map_set_bool(vm, "released", released);
    p2_map_set_bool(vm, "active", p2_child_vm_handles[slot].active);
    p2_map_set_bool(vm, "partition_ready_after", p2_heap_vm_partition_ready((int)slot));
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_int(vm, "release_before_main", (bint)release_before_main);
    p2_map_set_int(vm, "release_after_main", (bint)release_after_main);
    p2_map_set_int(vm, "release_before_total", (bint)release_before_total);
    p2_map_set_int(vm, "release_after_total", (bint)release_after_total);
    p2_map_set_int(vm, "release_before_created", (bint)release_before_created);
    p2_map_set_int(vm, "release_after_created", (bint)release_after_created);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_partition_info(bvm *vm)
{
    bint slot;
    size_t bytes;
    size_t free_bytes;

    if (be_top(vm) < 1 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }

    bytes = p2_heap_vm_partition_bytes((int)slot);
    free_bytes = p2_heap_vm_partition_free_bytes((int)slot);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "ready", p2_heap_vm_partition_ready((int)slot));
    p2_map_set_int(vm, "bytes", (bint)bytes);
    p2_map_set_int(vm, "free", (bint)free_bytes);
    p2_map_set_int(vm, "used", (bint)(bytes > free_bytes ? bytes - free_bytes : 0));
    p2_map_set_int(vm, "low", (bint)p2_heap_vm_partition_low_address((int)slot));
    p2_map_set_int(vm, "high", (bint)p2_heap_vm_partition_high_address((int)slot));
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_partition_release(bvm *vm)
{
    bint slot;
    int was_ready;
    int released;
    size_t before_main;
    size_t after_main;
    size_t before_total;
    size_t after_total;
    int before_created;
    int after_created;
    int runtime_locked;

    if (be_top(vm) < 1 || !be_isint(vm, 1)) {
        be_raise(vm, "type_error", "slot must be int");
    }
    slot = be_toint(vm, 1);
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        be_raise(vm, "value_error", "slot out of range");
    }

    runtime_locked = p2_child_vm_runtime_lock_enter();
    was_ready = p2_heap_vm_partition_ready((int)slot);
    before_main = p2_heap_main_free_bytes();
    before_total = p2_heap_vm_partition_total_bytes();
    before_created = p2_heap_vm_partition_created_count();
    released = p2_heap_vm_partition_release((int)slot);
    after_main = p2_heap_main_free_bytes();
    after_total = p2_heap_vm_partition_total_bytes();
    after_created = p2_heap_vm_partition_created_count();
    p2_child_vm_runtime_lock_leave(runtime_locked);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "slot", slot);
    p2_map_set_bool(vm, "released", released);
    p2_map_set_bool(vm, "was_ready", was_ready);
    p2_map_set_bool(vm, "ready", p2_heap_vm_partition_ready((int)slot));
    p2_map_set_bool(vm, "runtime_locked", runtime_locked);
    p2_map_set_int(vm, "before_main", (bint)before_main);
    p2_map_set_int(vm, "after_main", (bint)after_main);
    p2_map_set_int(vm, "before_total", (bint)before_total);
    p2_map_set_int(vm, "after_total", (bint)after_total);
    p2_map_set_int(vm, "before_created", (bint)before_created);
    p2_map_set_int(vm, "after_created", (bint)after_created);
    p2_map_set_int(vm, "current", (bint)p2_heap_vm_partition_current());
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_vm_copyable(bvm *vm)
{
    const char *kind = "unsupported";
    const char *reason = "live object transfer is not supported";
    int ok = 0;

    if (be_top(vm) < 1) {
        be_raise(vm, "value_error", "expected value");
    }

    if (be_isnil(vm, 1)) {
        ok = 1;
        kind = "nil";
        reason = "copy as nil";
    } else if (be_isbool(vm, 1)) {
        ok = 1;
        kind = "bool";
        reason = "copy by value";
    } else if (be_isint(vm, 1)) {
        ok = 1;
        kind = "int";
        reason = "copy by value";
    } else if (be_isstring(vm, 1)) {
        ok = 1;
        kind = "string";
        reason = "bounded copy";
    } else if (be_isfunction(vm, 1)) {
        kind = "function";
        reason = "closure/function transfer needs explicit child VM launch support";
    } else if (be_islist(vm, 1)) {
        kind = "list";
        reason = "list object graph transfer is not supported";
    } else if (be_ismap(vm, 1)) {
        kind = "map";
        reason = "map object graph transfer is not supported";
    }

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", ok);
    p2_map_set_string(vm, "kind", kind);
    p2_map_set_string(vm, "reason", reason);
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
    if (requested > BE_P2_XMM_BYTES) {
        requested = BE_P2_XMM_BYTES;
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
    p2_map_set_int(vm, "c_sbrk", (bint)sbrk(0));
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
    int swap_cs_clk = 0;
    int tries;
    int i;

    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        bint value = be_toint(vm, 1);
        if (value > 0) {
            sector = (uint32_t)value;
        }
    }
    if (be_top(vm) >= 2 && (be_isbool(vm, 2) || be_isint(vm, 2))) {
        swap_cs_clk = be_tobool(vm, 2) ? 1 : 0;
    }
    p2_sd_probe_swap_cs_clk = swap_cs_clk;

    p2_sd_probe_flash_powerdown();
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
    p2_map_set_bool(vm, "swap_cs_clk", swap_cs_clk);
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

static int m_p2_flash_diag(bvm *vm)
{
    uint32_t before_sleep;
    uint32_t after_sleep;
    uint32_t after_release;

    before_sleep = p2_flash_probe_rdid(1);
    p2_sd_probe_flash_powerdown();
    after_sleep = p2_flash_probe_rdid(0);
    after_release = p2_flash_probe_rdid(1);
    p2_sd_probe_flash_powerdown();

    be_newobject(vm, "map");
    p2_map_set_u32_hex(vm, "before_sleep", before_sleep);
    p2_map_set_u32_hex(vm, "after_sleep", after_sleep);
    p2_map_set_u32_hex(vm, "after_release", after_release);
    p2_map_set_bool(vm, "sleep_quiet", after_sleep == 0xffffffu || after_sleep == 0x000000u);
    p2_map_set_bool(vm, "release_answers", after_release != after_sleep);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_sd_pin_diag(bvm *vm)
{
    int initial_do;
    int initial_di;
    int initial_cs;
    int initial_clk;
    int cs_low;
    int cs_high;
    int clk_low;
    int clk_high;
    int di_low;
    int di_high;
    int do_after_cs_low;
    int do_after_clk_high;
    int do_final;

    (void)vm;

    p2_sd_probe_flash_powerdown();

    _pinh(P2_EDGE_SD_CS);
    _pinl(P2_EDGE_SD_CLK);
    _pinh(P2_EDGE_SD_DI);
    _pinf(P2_EDGE_SD_DO);
    _waitus(20);

    initial_do = _pinr(P2_EDGE_SD_DO) ? 1 : 0;
    initial_di = _pinr(P2_EDGE_SD_DI) ? 1 : 0;
    initial_cs = _pinr(P2_EDGE_SD_CS) ? 1 : 0;
    initial_clk = _pinr(P2_EDGE_SD_CLK) ? 1 : 0;

    _pinl(P2_EDGE_SD_CS);
    _waitus(20);
    cs_low = _pinr(P2_EDGE_SD_CS) ? 1 : 0;
    do_after_cs_low = _pinr(P2_EDGE_SD_DO) ? 1 : 0;

    _pinh(P2_EDGE_SD_CS);
    _waitus(20);
    cs_high = _pinr(P2_EDGE_SD_CS) ? 1 : 0;

    _pinl(P2_EDGE_SD_CLK);
    _waitus(20);
    clk_low = _pinr(P2_EDGE_SD_CLK) ? 1 : 0;

    _pinh(P2_EDGE_SD_CLK);
    _waitus(20);
    clk_high = _pinr(P2_EDGE_SD_CLK) ? 1 : 0;
    do_after_clk_high = _pinr(P2_EDGE_SD_DO) ? 1 : 0;

    _pinl(P2_EDGE_SD_CLK);
    _pinl(P2_EDGE_SD_DI);
    _waitus(20);
    di_low = _pinr(P2_EDGE_SD_DI) ? 1 : 0;

    _pinh(P2_EDGE_SD_DI);
    _waitus(20);
    di_high = _pinr(P2_EDGE_SD_DI) ? 1 : 0;

    _pinh(P2_EDGE_SD_CS);
    _pinl(P2_EDGE_SD_CLK);
    _pinh(P2_EDGE_SD_DI);
    _pinf(P2_EDGE_SD_DO);
    _waitus(20);
    do_final = _pinr(P2_EDGE_SD_DO) ? 1 : 0;

    be_newobject(vm, "map");
    p2_map_set_int(vm, "initial_do", (bint)initial_do);
    p2_map_set_int(vm, "initial_di", (bint)initial_di);
    p2_map_set_int(vm, "initial_cs", (bint)initial_cs);
    p2_map_set_int(vm, "initial_clk", (bint)initial_clk);
    p2_map_set_int(vm, "cs_low", (bint)cs_low);
    p2_map_set_int(vm, "cs_high", (bint)cs_high);
    p2_map_set_int(vm, "clk_low", (bint)clk_low);
    p2_map_set_int(vm, "clk_high", (bint)clk_high);
    p2_map_set_int(vm, "di_low", (bint)di_low);
    p2_map_set_int(vm, "di_high", (bint)di_high);
    p2_map_set_int(vm, "do_after_cs_low", (bint)do_after_cs_low);
    p2_map_set_int(vm, "do_after_clk_high", (bint)do_after_clk_high);
    p2_map_set_int(vm, "do_final", (bint)do_final);
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
#if BE_P2_ENABLE_SD_DIAGNOSTICS
    p2_map_set_string(vm, "root_first_name", info.root_first_name);
    p2_map_set_string(vm, "root_sample", info.root_sample);
#endif
    p2_map_set_string(vm, "read_value", info.read_value);
    p2_map_set_int(vm, "root_entry_count", (bint)info.root_entry_count);
#if BE_P2_ENABLE_SD_DIAGNOSTICS
    p2_map_set_int(vm, "root_zero_entry_count", (bint)info.root_zero_entry_count);
    p2_map_set_int(vm, "root_deleted_entry_count", (bint)info.root_deleted_entry_count);
    p2_map_set_int(vm, "root_hidden_entry_count", (bint)info.root_hidden_entry_count);
    p2_map_set_int(vm, "root_lfn_entry_count", (bint)info.root_lfn_entry_count);
    p2_map_set_int(vm, "root_first_byte", (bint)info.root_first_byte);
    p2_map_set_int(vm, "root_first_attr", (bint)info.root_first_attr);
#endif
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
#if BE_P2_ENABLE_SD_DIAGNOSTICS
    p2_map_set_int(vm, "vol_startsector", (bint)info.vol_startsector);
    p2_map_set_int(vm, "vol_secperclus", (bint)info.vol_secperclus);
    p2_map_set_int(vm, "vol_reservedsecs", (bint)info.vol_reservedsecs);
    p2_map_set_int(vm, "vol_secperfat", (bint)info.vol_secperfat);
    p2_map_set_int(vm, "vol_fat1", (bint)info.vol_fat1);
    p2_map_set_int(vm, "vol_rootdir", (bint)info.vol_rootdir);
    p2_map_set_int(vm, "vol_dataarea", (bint)info.vol_dataarea);
    p2_map_set_int(vm, "vol_numsecs", (bint)info.vol_numsecs);
    p2_map_set_int(vm, "vol_rootentries", (bint)info.vol_rootentries);
    p2_map_set_int(vm, "vol_numclusters", (bint)info.vol_numclusters);
    p2_map_set_int(vm, "vol_root_sector", (bint)info.vol_root_sector);
#endif
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
    p2_map_set_int(vm, "pointer_window_bytes", (bint)BE_P2_XMM_BYTES);
    p2_map_set_int(vm, "pointer_heap_limit", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "block_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "block_bytes",
        (bint)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE));
    p2_map_set_int(vm, "cache_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "cache_bytes",
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

static size_t p2_psram_block_bytes(void)
{
    if (BE_P2_EXTERNAL_RAM_BYTES <= BE_P2_PSRAM_BLOCK_BASE) {
        return 0;
    }
    return (size_t)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE);
}

static size_t p2_psram_cache_limit_address(void)
{
    size_t block_bytes = p2_psram_block_bytes();
    size_t limit = (size_t)BE_P2_PSRAM_BLOCK_BASE + block_bytes;

    if (block_bytes > (size_t)P2_PSRAM_LIBSTORE_TOP_RESERVE) {
        limit -= (size_t)P2_PSRAM_LIBSTORE_TOP_RESERVE;
    }
    return limit;
}

static void p2_psram_cache_cursor_init(void)
{
    if (p2_psram_cache_next == 0) {
        p2_psram_cache_next = (size_t)BE_P2_PSRAM_BLOCK_BASE;
    }
}

static size_t p2_psram_cache_align(size_t size)
{
    return (size + 7u) & ~(size_t)7u;
}

static uint32_t p2_psram_cache_checksum(const void *data, size_t size)
{
    const unsigned char *bytes = (const unsigned char *)data;
    uint32_t sum = 0;
    size_t i;

    for (i = 0; i < size; ++i) {
        sum += (uint32_t)bytes[i];
    }
    return sum;
}

static int m_p2_psram_cache_info(bvm *vm)
{
    size_t base = (size_t)BE_P2_PSRAM_BLOCK_BASE;
    size_t block_bytes = p2_psram_block_bytes();
    size_t block_end = base + block_bytes;
    size_t limit = p2_psram_cache_limit_address();

    p2_psram_cache_cursor_init();

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "available", P2_HAS_CATALINA_PSRAM && block_bytes > 0 && limit > base);
    p2_map_set_int(vm, "base", (bint)base);
    p2_map_set_int(vm, "next", (bint)p2_psram_cache_next);
    p2_map_set_int(vm, "limit", (bint)limit);
    p2_map_set_int(vm, "used", (bint)(p2_psram_cache_next > base ? p2_psram_cache_next - base : 0));
    p2_map_set_int(vm, "free", (bint)(limit > p2_psram_cache_next ? limit - p2_psram_cache_next : 0));
    p2_map_set_int(vm, "block_base", (bint)base);
    p2_map_set_int(vm, "block_bytes", (bint)block_bytes);
    p2_map_set_int(vm, "block_end", (bint)block_end);
    p2_map_set_int(vm, "libstore_top_reserve", (bint)P2_PSRAM_LIBSTORE_TOP_RESERVE);
    p2_map_set_int(vm, "libstore_base", (bint)limit);
    p2_map_set_int(vm, "alloc_count", (bint)p2_psram_cache_alloc_count);
    p2_map_set_int(vm, "entry_count", (bint)p2_psram_cache_entry_count);
    p2_map_set_int(vm, "entry_max", (bint)P2_PSRAM_CACHE_MAX_ENTRIES);
    p2_map_set_int(vm, "align", 8);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_reserve(bvm *vm)
{
    bint requested = p2_require_int_arg(vm, 1, "size must be an int");
    const char *owner = "";
    size_t base = (size_t)BE_P2_PSRAM_BLOCK_BASE;
    size_t block_bytes = p2_psram_block_bytes();
    size_t limit = p2_psram_cache_limit_address();
    size_t size;
    size_t address;
    int ok;

    if (requested <= 0) {
        be_raise(vm, "value_error", "size must be > 0");
    }
    if (be_top(vm) >= 2 && !be_isnil(vm, 2)) {
        if (!be_isstring(vm, 2)) {
            be_raise(vm, "type_error", "owner must be a string");
        }
        owner = be_tostring(vm, 2);
        if (owner == NULL) {
            owner = "";
        }
    }

    p2_psram_cache_cursor_init();
    size = p2_psram_cache_align((size_t)requested);
    address = p2_psram_cache_next;
    ok = P2_HAS_CATALINA_PSRAM && block_bytes > 0 && limit > base &&
        size <= limit - p2_psram_cache_next &&
        p2_psram_cache_entry_count < P2_PSRAM_CACHE_MAX_ENTRIES;

    if (ok) {
        p2_psram_cache_entry *entry = &p2_psram_cache_entries[p2_psram_cache_entry_count];

        entry->address = address;
        entry->size = size;
        entry->used = 0;
        entry->write_count = 0;
        entry->last_write_offset = 0;
        entry->last_write_size = 0;
        entry->last_write_checksum = 0;
        strncpy(entry->owner, owner, P2_PSRAM_CACHE_OWNER_MAX);
        entry->owner[P2_PSRAM_CACHE_OWNER_MAX] = '\0';
        ++p2_psram_cache_entry_count;
        p2_psram_cache_next += size;
        ++p2_psram_cache_alloc_count;
    }

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", ok);
    p2_map_set_int(vm, "address", ok ? (bint)address : -1);
    p2_map_set_int(vm, "requested", requested);
    p2_map_set_int(vm, "size", (bint)size);
    p2_map_set_int(vm, "base", (bint)base);
    p2_map_set_int(vm, "next", (bint)p2_psram_cache_next);
    p2_map_set_int(vm, "limit", (bint)limit);
    p2_map_set_int(vm, "free", (bint)(limit > p2_psram_cache_next ? limit - p2_psram_cache_next : 0));
    p2_map_set_int(vm, "libstore_base", (bint)limit);
    p2_map_set_int(vm, "alloc_count", (bint)p2_psram_cache_alloc_count);
    p2_map_set_int(vm, "entry_count", (bint)p2_psram_cache_entry_count);
    p2_map_set_int(vm, "index", ok ? (bint)(p2_psram_cache_entry_count - 1) : -1);
    p2_map_set_string(vm, "owner", ok ? p2_psram_cache_entries[p2_psram_cache_entry_count - 1].owner : owner);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_reset(bvm *vm)
{
    size_t base = (size_t)BE_P2_PSRAM_BLOCK_BASE;
    size_t limit = p2_psram_cache_limit_address();
    size_t before_next = p2_psram_cache_next == 0 ? base : p2_psram_cache_next;
    size_t before_count = p2_psram_cache_alloc_count;
    size_t before_entries = p2_psram_cache_entry_count;

    p2_psram_cache_next = base;
    p2_psram_cache_alloc_count = 0;
    p2_psram_cache_entry_count = 0;
    memset(p2_psram_cache_entries, 0, sizeof(p2_psram_cache_entries));

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", P2_HAS_CATALINA_PSRAM && limit > base);
    p2_map_set_int(vm, "base", (bint)base);
    p2_map_set_int(vm, "next", (bint)p2_psram_cache_next);
    p2_map_set_int(vm, "limit", (bint)limit);
    p2_map_set_int(vm, "free", (bint)(limit > p2_psram_cache_next ? limit - p2_psram_cache_next : 0));
    p2_map_set_int(vm, "before_next", (bint)before_next);
    p2_map_set_int(vm, "before_alloc_count", (bint)before_count);
    p2_map_set_int(vm, "before_entry_count", (bint)before_entries);
    p2_map_set_int(vm, "alloc_count", (bint)p2_psram_cache_alloc_count);
    p2_map_set_int(vm, "entry_count", (bint)p2_psram_cache_entry_count);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_entries(bvm *vm)
{
    size_t i;

    be_newobject(vm, "list");
    for (i = 0; i < p2_psram_cache_entry_count; ++i) {
        p2_psram_cache_entry *entry = &p2_psram_cache_entries[i];

        be_newobject(vm, "map");
        p2_map_set_int(vm, "index", (bint)i);
        p2_map_set_int(vm, "address", (bint)entry->address);
        p2_map_set_int(vm, "size", (bint)entry->size);
        p2_map_set_int(vm, "used", (bint)entry->used);
        p2_map_set_int(vm, "write_count", (bint)entry->write_count);
        p2_map_set_int(vm, "last_write_offset", (bint)entry->last_write_offset);
        p2_map_set_int(vm, "last_write_size", (bint)entry->last_write_size);
        p2_map_set_int(vm, "last_write_checksum", (bint)entry->last_write_checksum);
        p2_map_set_string(vm, "owner", entry->owner);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_find(bvm *vm)
{
    const char *owner;
    size_t i;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "owner must be a string");
    }
    owner = be_tostring(vm, 1);
    if (owner == NULL) {
        owner = "";
    }

    be_newobject(vm, "list");
    for (i = 0; i < p2_psram_cache_entry_count; ++i) {
        p2_psram_cache_entry *entry = &p2_psram_cache_entries[i];

        if (strcmp(entry->owner, owner) != 0) {
            continue;
        }
        be_newobject(vm, "map");
        p2_map_set_int(vm, "index", (bint)i);
        p2_map_set_int(vm, "address", (bint)entry->address);
        p2_map_set_int(vm, "size", (bint)entry->size);
        p2_map_set_int(vm, "used", (bint)entry->used);
        p2_map_set_int(vm, "write_count", (bint)entry->write_count);
        p2_map_set_int(vm, "last_write_offset", (bint)entry->last_write_offset);
        p2_map_set_int(vm, "last_write_size", (bint)entry->last_write_size);
        p2_map_set_int(vm, "last_write_checksum", (bint)entry->last_write_checksum);
        p2_map_set_string(vm, "owner", entry->owner);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_find_latest(bvm *vm)
{
    const char *owner;
    size_t i;
    int found = 0;

    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "owner must be a string");
    }
    owner = be_tostring(vm, 1);
    if (owner == NULL) {
        owner = "";
    }

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "found", 0);
    p2_map_set_int(vm, "index", -1);
    p2_map_set_int(vm, "address", -1);
    p2_map_set_int(vm, "size", 0);
    p2_map_set_int(vm, "used", 0);
    p2_map_set_int(vm, "write_count", 0);
    p2_map_set_int(vm, "last_write_offset", 0);
    p2_map_set_int(vm, "last_write_size", 0);
    p2_map_set_int(vm, "last_write_checksum", 0);
    p2_map_set_string(vm, "owner", owner);

    for (i = p2_psram_cache_entry_count; i > 0; --i) {
        size_t index = i - 1;
        p2_psram_cache_entry *entry = &p2_psram_cache_entries[index];

        if (strcmp(entry->owner, owner) != 0) {
            continue;
        }
        found = 1;
        p2_map_set_bool(vm, "found", 1);
        p2_map_set_int(vm, "index", (bint)index);
        p2_map_set_int(vm, "address", (bint)entry->address);
        p2_map_set_int(vm, "size", (bint)entry->size);
        p2_map_set_int(vm, "used", (bint)entry->used);
        p2_map_set_int(vm, "write_count", (bint)entry->write_count);
        p2_map_set_int(vm, "last_write_offset", (bint)entry->last_write_offset);
        p2_map_set_int(vm, "last_write_size", (bint)entry->last_write_size);
        p2_map_set_int(vm, "last_write_checksum", (bint)entry->last_write_checksum);
        p2_map_set_string(vm, "owner", entry->owner);
        break;
    }
    (void)found;
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_release(bvm *vm)
{
    bint index = p2_require_int_arg(vm, 1, "index must be an int");
    p2_psram_cache_entry released;
    int ok = 0;

    if (index < 0 || (size_t)index >= p2_psram_cache_entry_count) {
        be_raise(vm, "value_error", "cache entry index out of range");
    }

    memset(&released, 0, sizeof(released));
    released = p2_psram_cache_entries[(size_t)index];
    if ((size_t)index + 1 == p2_psram_cache_entry_count) {
        ok = 1;
        p2_psram_cache_next = released.address;
        memset(&p2_psram_cache_entries[(size_t)index], 0, sizeof(p2_psram_cache_entries[(size_t)index]));
        --p2_psram_cache_entry_count;
    }

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", ok);
    p2_map_set_bool(vm, "released", ok);
    p2_map_set_int(vm, "index", index);
    p2_map_set_int(vm, "address", (bint)released.address);
    p2_map_set_int(vm, "size", (bint)released.size);
    p2_map_set_int(vm, "used", (bint)released.used);
    p2_map_set_int(vm, "write_count", (bint)released.write_count);
    p2_map_set_int(vm, "last_write_offset", (bint)released.last_write_offset);
    p2_map_set_int(vm, "last_write_size", (bint)released.last_write_size);
    p2_map_set_int(vm, "last_write_checksum", (bint)released.last_write_checksum);
    p2_map_set_string(vm, "owner", released.owner);
    p2_map_set_int(vm, "next", (bint)p2_psram_cache_next);
    p2_map_set_int(vm, "entry_count", (bint)p2_psram_cache_entry_count);
    p2_map_set_bool(vm, "lifo_required", !ok);
    be_pop(vm, 1);
    be_return(vm);
}

static p2_psram_cache_entry *p2_psram_cache_entry_or_raise(bvm *vm, bint index)
{
    if (index < 0 || (size_t)index >= p2_psram_cache_entry_count) {
        be_raise(vm, "value_error", "cache entry index out of range");
    }
    return &p2_psram_cache_entries[(size_t)index];
}

static void p2_psram_cache_check_entry_range(bvm *vm, p2_psram_cache_entry *entry, bint offset, bint size)
{
    if (offset < 0) {
        be_raise(vm, "value_error", "offset must be >= 0");
    }
    if (size < 0) {
        be_raise(vm, "value_error", "size must be >= 0");
    }
    if (size > P2_PSRAM_TRANSFER_MAX) {
        be_raise(vm, "value_error", "size exceeds p2.psram_info()[\"max_transfer\"]");
    }
    if ((size_t)offset > entry->size || (size_t)size > entry->size - (size_t)offset) {
        be_raise(vm, "value_error", "range outside PSRAM cache entry");
    }
}

static void p2_psram_cache_check_range(bvm *vm, bint address, bint size)
{
    size_t base = (size_t)BE_P2_PSRAM_BLOCK_BASE;
    size_t limit = p2_psram_cache_limit_address();
    size_t reserved_limit;

    p2_psram_cache_cursor_init();
    reserved_limit = p2_psram_cache_next;

    if (address < 0) {
        be_raise(vm, "value_error", "address must be >= 0");
    }
    if (size < 0) {
        be_raise(vm, "value_error", "size must be >= 0");
    }
    if (size > P2_PSRAM_TRANSFER_MAX) {
        be_raise(vm, "value_error", "size exceeds p2.psram_info()[\"max_transfer\"]");
    }
    if ((size_t)address < base || (size_t)address > limit ||
        (size_t)size > limit - (size_t)address) {
        be_raise(vm, "value_error", "range outside native PSRAM cache window");
    }
    if ((size_t)address > reserved_limit ||
        (size_t)size > reserved_limit - (size_t)address) {
        be_raise(vm, "value_error", "range outside reserved PSRAM cache bytes");
    }
}

static int m_p2_psram_cache_read_entry(bvm *vm)
{
    bint index = p2_require_int_arg(vm, 1, "index must be an int");
    bint offset = p2_require_int_arg(vm, 2, "offset must be an int");
    bint size = p2_require_int_arg(vm, 3, "size must be an int");
    p2_psram_cache_entry *entry = p2_psram_cache_entry_or_raise(vm, index);
    size_t address;

    p2_psram_require_available(vm);
    p2_psram_cache_check_entry_range(vm, entry, offset, size);
    address = entry->address + (size_t)offset;

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        char *buffer = be_malloc(vm, (size_t)size);
        int result = psram_read(buffer,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_free(vm, buffer, (size_t)size);
            be_raise(vm, "io_error", "PSRAM cache entry read failed");
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

static int m_p2_psram_cache_write_entry(bvm *vm)
{
    bint index = p2_require_int_arg(vm, 1, "index must be an int");
    bint offset = p2_require_int_arg(vm, 2, "offset must be an int");
    p2_psram_cache_entry *entry = p2_psram_cache_entry_or_raise(vm, index);
    const void *data = NULL;
    size_t size = 0;
    size_t address;
    int result = 0;

    p2_psram_require_available(vm);
    if (be_top(vm) < 3 || (!be_isstring(vm, 3) && !be_isbytes(vm, 3))) {
        be_raise(vm, "type_error", "data must be a string or bytes");
    }
    if (be_isstring(vm, 3)) {
        data = be_tostring(vm, 3);
        size = (size_t)be_strlen(vm, 3);
    } else {
        data = be_tobytes(vm, 3, &size);
    }
    if (size > (size_t)P2_PSRAM_TRANSFER_MAX) {
        be_raise(vm, "value_error", "data exceeds p2.psram_info()[\"max_transfer\"]");
    }
    p2_psram_cache_check_entry_range(vm, entry, offset, (bint)size);
    address = entry->address + (size_t)offset;

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        result = psram_write((void *)data,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_raise(vm, "io_error", "PSRAM cache entry write failed");
        }
        if ((size_t)offset + size > entry->used) {
            entry->used = (size_t)offset + size;
        }
        entry->write_count += 1;
        entry->last_write_offset = (size_t)offset;
        entry->last_write_size = size;
        entry->last_write_checksum = p2_psram_cache_checksum(data, size);
    }
#endif

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", result >= 0);
    p2_map_set_int(vm, "index", index);
    p2_map_set_int(vm, "offset", offset);
    p2_map_set_int(vm, "address", (bint)address);
    p2_map_set_int(vm, "size", (bint)size);
    p2_map_set_int(vm, "used", (bint)entry->used);
    p2_map_set_int(vm, "write_count", (bint)entry->write_count);
    p2_map_set_int(vm, "last_write_offset", (bint)entry->last_write_offset);
    p2_map_set_int(vm, "last_write_size", (bint)entry->last_write_size);
    p2_map_set_int(vm, "last_write_checksum", (bint)entry->last_write_checksum);
    p2_map_set_int(vm, "result", (bint)result);
    p2_map_set_string(vm, "owner", entry->owner);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_verify_entry(bvm *vm)
{
    bint index = p2_require_int_arg(vm, 1, "index must be an int");
    p2_psram_cache_entry *entry = p2_psram_cache_entry_or_raise(vm, index);
    uint32_t checksum = 0;
    int result = 0;
    int has_write = entry->write_count > 0 && entry->last_write_size > 0;

    p2_psram_require_available(vm);

#if P2_HAS_CATALINA_PSRAM
    if (has_write) {
        char *buffer = be_malloc(vm, entry->last_write_size);

        result = psram_read(buffer,
            (void *)(uintptr_t)(entry->address + entry->last_write_offset),
            (int32_t)entry->last_write_size);
        if (result >= 0) {
            checksum = p2_psram_cache_checksum(buffer, entry->last_write_size);
        }
        be_free(vm, buffer, entry->last_write_size);
        if (result < 0) {
            be_raise(vm, "io_error", "PSRAM cache verify read failed");
        }
    }
#endif

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", !has_write || checksum == entry->last_write_checksum);
    p2_map_set_bool(vm, "has_write", has_write);
    p2_map_set_int(vm, "index", index);
    p2_map_set_int(vm, "offset", (bint)entry->last_write_offset);
    p2_map_set_int(vm, "size", (bint)entry->last_write_size);
    p2_map_set_int(vm, "expected", (bint)entry->last_write_checksum);
    p2_map_set_int(vm, "actual", (bint)checksum);
    p2_map_set_int(vm, "write_count", (bint)entry->write_count);
    p2_map_set_string(vm, "owner", entry->owner);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_psram_cache_read(bvm *vm)
{
    bint address = p2_require_int_arg(vm, 1, "address must be an int");
    bint size = p2_require_int_arg(vm, 2, "size must be an int");

    p2_psram_require_available(vm);
    p2_psram_cache_check_range(vm, address, size);

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        char *buffer = be_malloc(vm, (size_t)size);
        int result = psram_read(buffer,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_free(vm, buffer, (size_t)size);
            be_raise(vm, "io_error", "PSRAM cache read failed");
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

static int m_p2_psram_cache_write(bvm *vm)
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
    p2_psram_cache_check_range(vm, address, (bint)size);

#if P2_HAS_CATALINA_PSRAM
    if (size > 0) {
        result = psram_write((void *)data,
            (void *)(uintptr_t)address,
            (int32_t)size);
        if (result < 0) {
            be_raise(vm, "io_error", "PSRAM cache write failed");
        }
    }
#endif

    be_newobject(vm, "map");
    p2_map_set_bool(vm, "ok", result >= 0);
    p2_map_set_int(vm, "address", address);
    p2_map_set_int(vm, "size", (bint)size);
    p2_map_set_int(vm, "result", (bint)result);
    p2_map_set_bool(vm, "cache_window", 1);
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

static unsigned long p2_status_cog_registry_entry(int cog)
{
    volatile unsigned long *registry = (volatile unsigned long *)_registry();
    if (!registry || cog < 0 || cog >= 8) {
        return 0u;
    }
    return registry[cog];
}

static int p2_status_cog_registry_type(unsigned long entry)
{
    return (int)((entry >> 24) & 0xffu);
}

static void p2_status_cog_describe(int cog, int raw, int current,
    char *role, size_t role_len,
    char *label, size_t label_len,
    unsigned long *registry_entry,
    int *registry_type,
    int *slot_index,
    p2_closure_cog_slot **slot_out)
{
    unsigned long entry = p2_status_cog_registry_entry(cog);
    int type = p2_status_cog_registry_type(entry);
    p2_closure_cog_slot *slot = p2_closure_cog_find_by_cog(cog, slot_index);

    if (registry_entry) {
        *registry_entry = entry;
    }
    if (registry_type) {
        *registry_type = type;
    }
    if (slot_out) {
        *slot_out = slot;
    }
    if (role && role_len > 0) {
        role[0] = '\0';
    }
    if (label && label_len > 0) {
        label[0] = '\0';
    }

    if (slot) {
        snprintf(role, role_len, "user");
        p2_closure_cog_label(slot, label, label_len);
    } else if (cog == current) {
        snprintf(role, role_len, "main");
        snprintf(label, label_len, "main Berry VM / REPL");
    } else if (!raw) {
        snprintf(role, role_len, "free");
        snprintf(label, label_len, "available");
    } else if (type == 29) {
        snprintf(role, role_len, "xmm_cache");
        snprintf(label, label_len, "XMM cache service");
    } else if (entry != 0u && type != 0xff) {
        snprintf(role, role_len, "runtime");
        snprintf(label, label_len, "Catalina runtime service type %d", type);
    } else {
        snprintf(role, role_len, "unknown");
        snprintf(label, label_len, "running, no Berry/Catalina registry label");
    }
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
    unsigned long image_total = hub_total;
#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
    image_total = (unsigned long)BE_P2_XMM_BYTES;
#endif
    p2_status_print_bar_line("image", image, image_total);
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
        char role[24];
        char label[128];
        unsigned long registry_entry = 0u;
        int registry_type = 0xff;
        int slot_index = -1;
        p2_closure_cog_slot *slot = NULL;

        p2_status_cog_describe(cog, raw, (int)cogid,
            role, sizeof(role),
            label, sizeof(label),
            &registry_entry,
            &registry_type,
            &slot_index,
            &slot);

        p2_status_writef("  cog %d  %-4s  raw %d  %-9s  %s",
            cog,
            raw ? "run" : "free",
            raw,
            role,
            label);
        if (slot) {
            p2_status_writef("  slot %d", slot_index);
        } else if (registry_entry != 0u) {
            p2_status_writef("  reg 0x%08lx type %d", registry_entry, registry_type);
        }
        if (cog == (int)cogid) {
            p2_status_write("  current");
        }
        p2_status_write_line("");
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
    p2_map_set_int(vm, "bytecode_saver", (bint)BE_USE_BYTECODE_SAVER);
    p2_map_set_int(vm, "bytecode_loader", (bint)BE_USE_BYTECODE_LOADER);
    p2_map_set_int(vm, "bytecode_execution", (bint)BE_P2_ENABLE_BYTECODE_EXECUTION);
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
    unsigned long main_total = (unsigned long)p2_heap_main_size();
    unsigned long main_requested = (unsigned long)p2_heap_main_requested_size();
    unsigned long worker_total = (unsigned long)BE_P2_WORKER_HEAP_BYTES;
    unsigned long main_free = (unsigned long)p2_heap_main_free_bytes();
    unsigned long worker_free = (unsigned long)p2_heap_worker_free_bytes();

    be_newobject(vm, "map");
    p2_map_set_int(vm, "hub_total", (bint)hub_total);
    p2_map_set_int(vm, "hub_image_used", (bint)(image <= hub_total ? image : hub_total));
    p2_map_set_int(vm, "main_heap_requested", (bint)main_requested);
    p2_map_set_int(vm, "main_heap_total", (bint)main_total);
    p2_map_set_int(vm, "main_heap_free", (bint)main_free);
    p2_map_set_int(vm, "main_heap_used", (bint)(main_total > main_free ? main_total - main_free : 0u));
    p2_map_set_int(vm, "main_heap_base", (bint)(uintptr_t)p2_heap_main_base());
    p2_map_set_bool(vm, "main_heap_ready", p2_heap_main_ready());
    p2_map_set_bool(vm, "main_heap_alloc_failed", p2_heap_main_alloc_failed());
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
        char role[24];
        char label[128];
        unsigned long registry_entry = 0u;
        int registry_type = 0xff;
        int slot_index = -1;
        p2_closure_cog_slot *slot = NULL;

        p2_status_cog_describe(cog, raw, current,
            role, sizeof(role),
            label, sizeof(label),
            &registry_entry,
            &registry_type,
            &slot_index,
            &slot);

        be_newobject(vm, "map");
        p2_map_set_int(vm, "id", (bint)cog);
        p2_map_set_bool(vm, "running", raw != 0);
        p2_map_set_int(vm, "raw", (bint)raw);
        p2_map_set_bool(vm, "current", cog == current);
        p2_map_set_string(vm, "role", role);
        p2_map_set_string(vm, "label", label);
        p2_map_set_int(vm, "registry_entry", (bint)registry_entry);
        p2_map_set_int(vm, "registry_type", (bint)registry_type);
        p2_map_set_int(vm, "slot", (bint)slot_index);
        p2_map_set_int(vm, "handle", slot ? slot->handle : (bint)-1);
        p2_map_set_string(vm, "model", slot ? (slot->native_blink ? "native_blink" : (slot->isolated_source ? "isolated_source_vm" : "shared_vm_repl_idle")) : "");
        p2_map_set_string(vm, "function", slot ? (slot->closure_name[0] ? slot->closure_name : ((slot->isolated_source && slot->source_job && slot->source_job->name[0]) ? slot->source_job->name : "")) : "");
        p2_map_set_string(vm, "closure_name", slot ? slot->closure_name : "");
        p2_map_set_string(vm, "task_kind", slot ? p2_closure_cog_task_kind_name(slot->task_kind) : "");
        p2_map_set_int(vm, "native_pin", slot ? (bint)slot->native_pin : (bint)-1);
        p2_map_set_int(vm, "period_ms", slot ? (bint)slot->period_ms : (bint)-1);
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

#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
static void p2_module_set_current_as_member(bvm *vm, const char *name)
{
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}


static const char *p2_debug_pin_reservation(int pin)
{
#if defined(__CATALINA__)
#if defined(__CATALINA_libpsram) || defined(__CATALINA_PSRAM)
    if (pin >= 40 && pin <= 57) {
        return "psram";
    }
#endif
    if (pin >= 58 && pin <= 61) {
        return "sd";
    }
    if (pin == 62 || pin == 63) {
        return "serial";
    }
#else
    (void)pin;
#endif
    return "";
}

static uint32_t p2_debug_pin_mask(int pin)
{
    return (uint32_t)1u << (pin & 31);
}

static uint32_t p2_debug_pin_reg_in(int pin)
{
    return pin < 32 ? (uint32_t)_INA : (uint32_t)_INB;
}

static uint32_t p2_debug_pin_reg_out(int pin)
{
    return pin < 32 ? (uint32_t)_OUTA : (uint32_t)_OUTB;
}

static uint32_t p2_debug_pin_reg_dir(int pin)
{
    return pin < 32 ? (uint32_t)_DIRA : (uint32_t)_DIRB;
}

static void p2_debug_pin_record(bvm *vm, int pin)
{
    uint32_t mask = p2_debug_pin_mask(pin);
    const char *reservation = p2_debug_pin_reservation(pin);
    int direction = (p2_debug_pin_reg_dir(pin) & mask) ? 1 : 0;
    int output = (p2_debug_pin_reg_out(pin) & mask) ? 1 : 0;
    int input = (p2_debug_pin_reg_in(pin) & mask) ? 1 : 0;

    be_newobject(vm, "map");
    p2_map_set_int(vm, "pin", (bint)pin);
    p2_map_set_bool(vm, "reserved", reservation[0] != '\0');
    p2_map_set_string(vm, "reservation", reservation);
    p2_map_set_bool(vm, "direction_output", direction);
    p2_map_set_string(vm, "direction", direction ? "output" : "input");
    p2_map_set_bool(vm, "output", output);
    p2_map_set_bool(vm, "input", input);
}

static int m_p2_debug_snapshot(bvm *vm)
{
    return m_p2_status_info(vm);
}

static int m_p2_debug_heap(bvm *vm)
{
    return m_p2_heap_info(vm);
}

static int m_p2_debug_gc(bvm *vm)
{
    size_t before = be_gc_memcount(vm);
    size_t after;

    be_gc_collect(vm);
    after = be_gc_memcount(vm);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "before", (bint)before);
    p2_map_set_int(vm, "after", (bint)after);
    p2_map_set_int(vm, "freed", before > after ? (bint)(before - after) : (bint)0);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_cogs(bvm *vm)
{
    p2_status_info_cogs(vm);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_memory_map(bvm *vm)
{
    be_newobject(vm, "map");
    p2_map_set_int(vm, "hub_total", 512 * 1024);
    p2_map_set_int(vm, "main_heap_requested", (bint)p2_heap_main_requested_size());
    p2_map_set_int(vm, "main_heap_total", (bint)p2_heap_main_size());
    p2_map_set_int(vm, "main_heap_free", (bint)p2_heap_main_free_bytes());
    p2_map_set_int(vm, "main_heap_used", (bint)(p2_heap_main_size() > p2_heap_main_free_bytes() ? p2_heap_main_size() - p2_heap_main_free_bytes() : 0u));
    p2_map_set_int(vm, "main_heap_base", (bint)(uintptr_t)p2_heap_main_base());
    p2_map_set_bool(vm, "main_heap_ready", p2_heap_main_ready());
    p2_map_set_bool(vm, "main_heap_alloc_failed", p2_heap_main_alloc_failed());
    p2_map_set_int(vm, "worker_heap_total", (bint)BE_P2_WORKER_HEAP_BYTES);
    p2_map_set_int(vm, "worker_heap_free", (bint)p2_heap_worker_free_bytes());
    p2_map_set_int(vm, "worker_heap_used", (bint)(BE_P2_WORKER_HEAP_BYTES > p2_heap_worker_free_bytes() ? BE_P2_WORKER_HEAP_BYTES - p2_heap_worker_free_bytes() : 0u));
    p2_map_set_int(vm, "current_heap_free", (bint)p2_heap_free_bytes());
    p2_map_set_bool(vm, "external_heap", BE_P2_HEAP_USES_EXTERNAL_RAM);
    p2_map_set_int(vm, "psram_bytes", (bint)BE_P2_EXTERNAL_RAM_BYTES);
    p2_map_set_int(vm, "xmm_bytes", (bint)BE_P2_XMM_BYTES);
    p2_map_set_int(vm, "psram_block_base", (bint)BE_P2_PSRAM_BLOCK_BASE);
    p2_map_set_int(vm, "psram_block_bytes", (bint)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE));
    p2_map_set_string(vm, "psram_access", P2_HAS_CATALINA_PSRAM ? (BE_P2_HEAP_USES_EXTERNAL_RAM ? "xmm+block" : "block") : "none");
    p2_map_set_string(vm, "sd_mount_path", "/");
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_pin(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);

    p2_debug_pin_record(vm, pin);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_pins(bvm *vm)
{
    int pin;

    be_newobject(vm, "list");
    for (pin = 0; pin < 64; ++pin) {
        p2_debug_pin_record(vm, pin);
        be_data_push(vm, -2);
        be_pop(vm, 1);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_smartpin(bvm *vm)
{
    int pin = p2_require_pin_arg(vm, 1);

    p2_debug_pin_record(vm, pin);
    p2_map_set_int(vm, "rdpin", (bint)_rdpin(pin));
    p2_map_set_int(vm, "rqpin", (bint)_rqpin(pin));
    be_pop(vm, 1);
    be_return(vm);
}

static int m_p2_debug_registers(bvm *vm)
{
    bint cog = (bint)_cogid();
    counter64_t ct;

    if (be_top(vm) >= 1) {
        cog = p2_require_int_arg(vm, 1, "cog must be an int");
    }
    if (cog < 0 || cog > 7) {
        be_raise(vm, "value_error", "cog must be between 0 and 7");
    }

    ct = _cnthl();
    be_newobject(vm, "map");
    p2_map_set_int(vm, "cog", cog);
    p2_map_set_bool(vm, "readable", cog == (bint)_cogid());
    p2_map_set_int(vm, "ct_low", (bint)ct.low);
    p2_map_set_int(vm, "ct_high", (bint)ct.high);
    if (cog == (bint)_cogid()) {
        p2_map_set_int(vm, "ptra", (bint)_PTRA);
        p2_map_set_int(vm, "ptrb", (bint)_PTRB);
        p2_map_set_int(vm, "ina", (bint)_INA);
        p2_map_set_int(vm, "inb", (bint)_INB);
        p2_map_set_int(vm, "outa", (bint)_OUTA);
        p2_map_set_int(vm, "outb", (bint)_OUTB);
        p2_map_set_int(vm, "dira", (bint)_DIRA);
        p2_map_set_int(vm, "dirb", (bint)_DIRB);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static void p2_module_add_debug(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "snapshot", m_p2_debug_snapshot);
    p2_module_set_func(vm, "heap", m_p2_debug_heap);
    p2_module_set_func(vm, "gc", m_p2_debug_gc);
    p2_module_set_func(vm, "cogs", m_p2_debug_cogs);
    p2_module_set_func(vm, "memory_map", m_p2_debug_memory_map);
    p2_module_set_func(vm, "pin", m_p2_debug_pin);
    p2_module_set_func(vm, "pins", m_p2_debug_pins);
    p2_module_set_func(vm, "smartpin", m_p2_debug_smartpin);
    p2_module_set_func(vm, "registers", m_p2_debug_registers);
    p2_module_set_current_as_member(vm, "debug");
}

static void p2_module_add_clock(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "freq", m_clock_freq);
    p2_module_set_func(vm, "mode", m_clock_mode);
    p2_module_set_func(vm, "set", m_p2_clock_set);
    p2_module_set_func(vm, "cnt", m_counter_ticks);
    p2_module_set_func(vm, "cnth", m_counter_ticks_high);
    p2_module_set_func(vm, "waitx", m_counter_wait_ticks);
    p2_module_set_func(vm, "waitus", m_counter_sleep_us);
    p2_module_set_func(vm, "waitms", m_counter_sleep_ms);
    p2_module_set_func(vm, "waitsec", m_counter_sleep);
    p2_module_set_func(vm, "waitcnt", m_counter_wait_until);
    p2_module_set_func(vm, "hubset", m_p2_hubset);
    p2_module_set_current_as_member(vm, "clock");
}

static void p2_module_add_cog(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "id", m_p2_cogid);
    p2_module_set_func(vm, "check", m_cog_check);
    p2_module_set_func(vm, "stop", m_p2_cog_stop);
    p2_module_set_func(vm, "blinker", m_p2_closure_cog_blinker);
    p2_module_set_func(vm, "task", m_p2_closure_cog_task);
#if defined(__CATALINA_LARGE)
    p2_module_set_func(vm, "task_kinds", m_p2_closure_cog_task_kinds);
    p2_module_set_func(vm, "task_release", m_p2_closure_cog_task_release);
    p2_module_set_func(vm, "task_info", m_p2_closure_cog_task_info);
    p2_module_set_func(vm, "spawn_source", m_p2_closure_cog_spawn_source);
#endif
    p2_module_set_func(vm, "is_task", m_p2_closure_cog_is_task);
    p2_module_set_func(vm, "spawn", m_p2_closure_cog_spawn);
    p2_module_set_func(vm, "spawn_task", m_p2_closure_cog_spawn);
    p2_module_set_func(vm, "info", m_p2_closure_cog_info);
    p2_module_set_func(vm, "capabilities", m_p2_closure_cog_capabilities);
    p2_module_set_func(vm, "vm_cog_ping", m_p2_vm_cog_ping);
    p2_module_set_func(vm, "attention", m_attention_signal);
    p2_module_set_func(vm, "poll_attention", m_attention_poll);
    p2_module_set_func(vm, "wait_attention", m_attention_wait);
    p2_module_set_current_as_member(vm, "cog");
}

static void p2_module_add_lock(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "new", m_lock_new);
    p2_module_set_func(vm, "ret", m_lock_return);
    p2_module_set_func(vm, "try", m_lock_try);
    p2_module_set_func(vm, "release", m_lock_release);
    p2_module_set_func(vm, "check", m_lock_check);
    p2_module_set_current_as_member(vm, "lock");
}

static void p2_module_add_pin(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "dir_low", m_p2_pin_dir_low);
    p2_module_set_func(vm, "dir_high", m_p2_pin_dir_high);
    p2_module_set_func(vm, "write", m_pin_write);
    p2_module_set_func(vm, "low", m_pin_low);
    p2_module_set_func(vm, "high", m_pin_high);
    p2_module_set_func(vm, "toggle", m_pin_toggle);
    p2_module_set_func(vm, "float", m_pin_float);
    p2_module_set_func(vm, "read", m_pin_read);
    p2_module_set_current_as_member(vm, "pin");
}

static void p2_module_add_cordic(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "rotxy", m_cordic_rotxy);
    p2_module_set_func(vm, "polxy", m_cordic_polxy);
    p2_module_set_func(vm, "xypol", m_cordic_xypol);
    p2_module_set_current_as_member(vm, "cordic");
}

static void p2_module_add_math(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "isqrt", m_misc_isqrt);
    p2_module_set_func(vm, "muldiv64", m_misc_muldiv64);
    p2_module_set_func(vm, "rev", m_misc_reverse_bits);
    p2_module_set_func(vm, "encod", m_misc_encode);
    p2_module_set_current_as_member(vm, "math");
}

static void p2_module_add_rng(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "rnd", m_misc_random);
    p2_module_set_current_as_member(vm, "rng");
}

static void p2_module_add_asm(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "getrnd", m_misc_random);
    p2_module_set_func(vm, "getct", m_counter_ticks);
    p2_module_set_func(vm, "waitx", m_counter_wait_ticks);
    p2_module_set_func(vm, "hubset", m_p2_hubset);
    p2_module_set_current_as_member(vm, "asm");
}

static void p2_module_add_smart(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "wrpin", m_smartpin_write_mode);
    p2_module_set_func(vm, "wxpin", m_smartpin_write_x);
    p2_module_set_func(vm, "wypin", m_smartpin_write_y);
    p2_module_set_func(vm, "akpin", m_smartpin_ack);
    p2_module_set_func(vm, "rdpin", m_smartpin_read);
    p2_module_set_func(vm, "rqpin", m_smartpin_query);
    p2_module_set_func(vm, "start", m_smartpin_start);
    p2_module_set_func(vm, "clear", m_smartpin_clear);
    p2_module_set_current_as_member(vm, "smart");
}

#endif

static void p2_module_add_runtime_cog(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "id", m_p2_cogid);
    p2_module_set_func(vm, "check", m_cog_check);
    p2_module_set_func(vm, "stop", m_p2_cog_stop);
    p2_module_set_func(vm, "blinker", m_p2_closure_cog_blinker);
    p2_module_set_func(vm, "task", m_p2_closure_cog_task);
#if defined(__CATALINA_LARGE)
    p2_module_set_func(vm, "task_kinds", m_p2_closure_cog_task_kinds);
    p2_module_set_func(vm, "task_release", m_p2_closure_cog_task_release);
    p2_module_set_func(vm, "task_info", m_p2_closure_cog_task_info);
    p2_module_set_func(vm, "spawn_source", m_p2_closure_cog_spawn_source);
#endif
    p2_module_set_func(vm, "is_task", m_p2_closure_cog_is_task);
    p2_module_set_func(vm, "spawn", m_p2_closure_cog_spawn);
    p2_module_set_func(vm, "spawn_task", m_p2_closure_cog_spawn);
    p2_module_set_func(vm, "info", m_p2_closure_cog_info);
    p2_module_set_func(vm, "capabilities", m_p2_closure_cog_capabilities);
    p2_module_set_func(vm, "attention", m_attention_signal);
    p2_module_set_func(vm, "poll_attention", m_attention_poll);
    p2_module_set_func(vm, "wait_attention", m_attention_wait);
    be_setmember(vm, -2, "cog");
    be_pop(vm, 1);
}

static void p2_module_add_runtime_pin(bvm *vm)
{
    be_newmodule(vm);
    p2_module_set_func(vm, "dir_low", m_pin_input);
    p2_module_set_func(vm, "dir_high", m_pin_output);
    p2_module_set_func(vm, "write", m_pin_write);
    p2_module_set_func(vm, "low", m_pin_low);
    p2_module_set_func(vm, "high", m_pin_high);
    p2_module_set_func(vm, "toggle", m_pin_toggle);
    p2_module_set_func(vm, "float", m_pin_float);
    p2_module_set_func(vm, "read", m_pin_read);
    be_setmember(vm, -2, "pin");
    be_pop(vm, 1);
}

static void p2_module_add_runtime_clock_aliases(bvm *vm)
{
    p2_module_set_func(vm, "cnt", m_counter_ticks);
    p2_module_set_func(vm, "cnth", m_counter_ticks_high);
    p2_module_set_func(vm, "ticks", m_counter_ticks);
    p2_module_set_func(vm, "ticks_high", m_counter_ticks_high);
    p2_module_set_func(vm, "ticks64", m_counter_ticks64);
    p2_module_set_func(vm, "waitx", m_counter_wait_ticks);
    p2_module_set_func(vm, "wait_ticks", m_counter_wait_ticks);
    p2_module_set_func(vm, "waitus", m_counter_sleep_us);
    p2_module_set_func(vm, "waitms", m_counter_sleep_ms);
    p2_module_set_func(vm, "waitsec", m_counter_sleep);
    p2_module_set_func(vm, "waitcnt", m_counter_wait_until);
    p2_module_set_func(vm, "wait_until", m_counter_wait_until);
}

static int m_p2_gc(bvm *vm)
{
    size_t before = be_gc_memcount(vm);
    size_t after;

    be_gc_collect(vm);
    after = be_gc_memcount(vm);

    be_newobject(vm, "map");
    p2_map_set_int(vm, "before", (bint)before);
    p2_map_set_int(vm, "after", (bint)after);
    p2_map_set_int(vm, "freed", before > after ? (bint)(before - after) : (bint)0);
    be_pop(vm, 1);
    be_return(vm);
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
    else if (!strcmp(name, "cnt")) be_pushntvfunction(vm, m_counter_ticks);
    else if (!strcmp(name, "cnth")) be_pushntvfunction(vm, m_counter_ticks_high);
    else if (!strcmp(name, "waitx")) be_pushntvfunction(vm, m_counter_wait_ticks);
    else if (!strcmp(name, "waitus")) be_pushntvfunction(vm, m_counter_sleep_us);
    else if (!strcmp(name, "waitms")) be_pushntvfunction(vm, m_counter_sleep_ms);
    else if (!strcmp(name, "waitsec")) be_pushntvfunction(vm, m_counter_sleep);
    else if (!strcmp(name, "waitcnt")) be_pushntvfunction(vm, m_counter_wait_until);
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
    else if (!strcmp(name, "cog_spawn")) be_pushntvfunction(vm, m_p2_closure_cog_spawn);
    else if (!strcmp(name, "cog_spawn_task")) be_pushntvfunction(vm, m_p2_closure_cog_spawn);
    else if (!strcmp(name, "cog_blinker")) be_pushntvfunction(vm, m_p2_closure_cog_blinker);
    else if (!strcmp(name, "cog_task")) be_pushntvfunction(vm, m_p2_closure_cog_task);
#if defined(__CATALINA_LARGE)
    else if (!strcmp(name, "cog_task_kinds")) be_pushntvfunction(vm, m_p2_closure_cog_task_kinds);
    else if (!strcmp(name, "cog_task_release")) be_pushntvfunction(vm, m_p2_closure_cog_task_release);
    else if (!strcmp(name, "cog_task_info")) be_pushntvfunction(vm, m_p2_closure_cog_task_info);
    else if (!strcmp(name, "cog_spawn_source")) be_pushntvfunction(vm, m_p2_closure_cog_spawn_source);
#endif
    else if (!strcmp(name, "cog_is_task")) be_pushntvfunction(vm, m_p2_closure_cog_is_task);
    else if (!strcmp(name, "cog_info")) be_pushntvfunction(vm, m_p2_closure_cog_info);
    else if (!strcmp(name, "cog_closure_stop")) be_pushntvfunction(vm, m_p2_closure_cog_stop);
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
    else if (!strcmp(name, "gc")) be_pushntvfunction(vm, m_p2_gc);
    else if (!strcmp(name, "vm_probe")) be_pushntvfunction(vm, m_p2_vm_probe);
    else if (!strcmp(name, "vm_probe_many")) be_pushntvfunction(vm, m_p2_vm_probe_many);
    else if (!strcmp(name, "vm_call_probe")) be_pushntvfunction(vm, m_p2_vm_call_probe);
    else if (!strcmp(name, "vm_call")) be_pushntvfunction(vm, m_p2_vm_call_probe);
    else if (!strcmp(name, "vm_call_once")) be_pushntvfunction(vm, m_p2_vm_call_once);
    else if (!strcmp(name, "vm_open")) be_pushntvfunction(vm, m_p2_vm_open);
    else if (!strcmp(name, "vm_eval")) be_pushntvfunction(vm, m_p2_vm_eval);
    else if (!strcmp(name, "vm_get")) be_pushntvfunction(vm, m_p2_vm_get);
    else if (!strcmp(name, "vm_invoke")) be_pushntvfunction(vm, m_p2_vm_invoke);
    else if (!strcmp(name, "vm_lock_info")) be_pushntvfunction(vm, m_p2_vm_lock_info);
#if BE_P2_ENABLE_EXPERIMENTAL_VM_COG
    else if (!strcmp(name, "vm_cog_call_once")) be_pushntvfunction(vm, m_p2_vm_cog_call_once);
    else if (!strcmp(name, "vm_cog_start")) be_pushntvfunction(vm, m_p2_vm_cog_start);
    else if (!strcmp(name, "vm_cog_info")) be_pushntvfunction(vm, m_p2_vm_cog_info);
#endif
#if BE_P2_ENABLE_EXPERIMENTAL_VM_COG || BE_P2_ENABLE_EXPERIMENTAL_COG_PING
    else if (!strcmp(name, "vm_cog_ping")) be_pushntvfunction(vm, m_p2_vm_cog_ping);
#endif
    else if (!strcmp(name, "vm_close")) be_pushntvfunction(vm, m_p2_vm_close);
    else if (!strcmp(name, "vm_partition_info")) be_pushntvfunction(vm, m_p2_vm_partition_info);
    else if (!strcmp(name, "vm_partition_release")) be_pushntvfunction(vm, m_p2_vm_partition_release);
    else if (!strcmp(name, "vm_copyable")) be_pushntvfunction(vm, m_p2_vm_copyable);
    else if (!strcmp(name, "c_allocator_test")) be_pushntvfunction(vm, m_p2_c_allocator_test);
    else if (!strcmp(name, "fs_info")) be_pushntvfunction(vm, m_p2_fs_info);
    else if (!strcmp(name, "sd_info")) be_pushntvfunction(vm, m_p2_fs_info);
    else if (!strcmp(name, "sd_raw_probe")) be_pushntvfunction(vm, m_p2_sd_raw_probe);
    else if (!strcmp(name, "sd_pin_diag")) be_pushntvfunction(vm, m_p2_sd_pin_diag);
    else if (!strcmp(name, "flash_diag")) be_pushntvfunction(vm, m_p2_flash_diag);
    else if (!strcmp(name, "psram_info")) be_pushntvfunction(vm, m_p2_psram_info);
    else if (!strcmp(name, "psram_cache_info")) be_pushntvfunction(vm, m_p2_psram_cache_info);
    else if (!strcmp(name, "psram_cache_reserve")) be_pushntvfunction(vm, m_p2_psram_cache_reserve);
    else if (!strcmp(name, "psram_cache_reset")) be_pushntvfunction(vm, m_p2_psram_cache_reset);
    else if (!strcmp(name, "psram_cache_entries")) be_pushntvfunction(vm, m_p2_psram_cache_entries);
    else if (!strcmp(name, "psram_cache_find")) be_pushntvfunction(vm, m_p2_psram_cache_find);
    else if (!strcmp(name, "psram_cache_find_latest")) be_pushntvfunction(vm, m_p2_psram_cache_find_latest);
    else if (!strcmp(name, "psram_cache_release")) be_pushntvfunction(vm, m_p2_psram_cache_release);
    else if (!strcmp(name, "psram_cache_read_entry")) be_pushntvfunction(vm, m_p2_psram_cache_read_entry);
    else if (!strcmp(name, "psram_cache_write_entry")) be_pushntvfunction(vm, m_p2_psram_cache_write_entry);
    else if (!strcmp(name, "psram_cache_verify_entry")) be_pushntvfunction(vm, m_p2_psram_cache_verify_entry);
    else if (!strcmp(name, "psram_cache_read")) be_pushntvfunction(vm, m_p2_psram_cache_read);
    else if (!strcmp(name, "psram_cache_write")) be_pushntvfunction(vm, m_p2_psram_cache_write);
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
    p2_module_set_func(vm, "vm_cog_ping", m_p2_vm_cog_ping);
    p2_module_add_runtime_cog(vm);
    p2_module_add_runtime_pin(vm);
    p2_module_add_runtime_clock_aliases(vm);
#if BE_P2_ENABLE_ROADMAP_NATIVE_FACADES
    p2_module_add_debug(vm);
    p2_module_add_clock(vm);
    p2_module_add_cog(vm);
    p2_module_add_lock(vm);
    p2_module_add_pin(vm);
    p2_module_add_cordic(vm);
    p2_module_add_math(vm);
    p2_module_add_rng(vm);
    p2_module_add_asm(vm);
    p2_module_add_smart(vm);
#endif
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
