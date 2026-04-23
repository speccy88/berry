#ifndef BE_BUS_COMMON_P2_H
#define BE_BUS_COMMON_P2_H

#include "berry.h"
#include <stdint.h>
#include <stdlib.h>

#define BE_P2_BUS_MAX_XFER 1024u

typedef struct berry_p2_bus_buffer {
    const uint8_t *data;
    size_t length;
    uint8_t *owned;
} berry_p2_bus_buffer;

static inline bint berry_p2_bus_require_int(bvm *vm, int index, const char *what)
{
    if (be_top(vm) < index || !be_isint(vm, index)) {
        be_raise(vm, "type_error", what);
    }
    return be_toint(vm, index);
}

static inline void berry_p2_bus_validate_pin_usage(bvm *vm, int pin, const char *usage)
{
    /* Guard only the pins that are still known to be in active platform use
     * on the current Catalina P2 path. Pins 56/57 are intentionally left
     * available for boards that expose them as GPIO/LEDs instead of PSRAM. */
#if defined(__CATALINA__)
    if (pin >= 58 && pin <= 61) {
        be_raise(vm, "value_error", "pin is reserved by the P2 Edge SD card interface");
    }
    if (pin == 62 || pin == 63) {
        be_raise(vm, "value_error", "pin is reserved by the P2 Edge serial console");
    }
#else
    (void)vm;
    (void)pin;
    (void)usage;
#endif
    (void)usage;
}

static inline int berry_p2_bus_require_pin(bvm *vm, int index, const char *what)
{
    bint pin = berry_p2_bus_require_int(vm, index, what);
    if (pin < 0 || pin > 63) {
        be_raise(vm, "value_error", "pin must be between 0 and 63");
    }
    berry_p2_bus_validate_pin_usage(vm, (int)pin, "bus");
    return (int)pin;
}

static inline unsigned berry_p2_bus_require_khz(bvm *vm, int index, const char *what)
{
    bint khz = berry_p2_bus_require_int(vm, index, what);
    if (khz <= 0) {
        be_raise(vm, "value_error", "khz must be greater than 0");
    }
    return (unsigned)khz;
}

static inline int berry_p2_bus_require_address7(bvm *vm, int index)
{
    bint addr = berry_p2_bus_require_int(vm, index, "addr must be a 7-bit int");
    if (addr < 0 || addr > 0x7F) {
        be_raise(vm, "value_error", "addr must be between 0x00 and 0x7F");
    }
    return (int)addr;
}

static inline size_t berry_p2_bus_require_count(bvm *vm, int index, const char *what)
{
    bint count = berry_p2_bus_require_int(vm, index, what);
    if (count < 0) {
        be_raise(vm, "value_error", "count must be >= 0");
    }
    if ((size_t)count > BE_P2_BUS_MAX_XFER) {
        be_raise(vm, "value_error", "count exceeds v1 transfer limit");
    }
    return (size_t)count;
}

static inline uint8_t berry_p2_bus_require_byte(bvm *vm, int index, const char *what)
{
    bint value = berry_p2_bus_require_int(vm, index, what);
    if (value < 0 || value > 255) {
        be_raise(vm, "value_error", "byte value must be between 0 and 255");
    }
    return (uint8_t)value;
}

static inline void berry_p2_bus_require_init(bvm *vm, int initialized, const char *what)
{
    if (!initialized) {
        be_raise(vm, "runtime_error", what);
    }
}

static inline void berry_p2_bus_release_buffer(berry_p2_bus_buffer *buffer)
{
    if (buffer->owned) {
        free(buffer->owned);
    }
    buffer->owned = NULL;
    buffer->data = NULL;
    buffer->length = 0;
}

static inline berry_p2_bus_buffer berry_p2_bus_get_buffer(bvm *vm, int index, const char *what)
{
    berry_p2_bus_buffer buffer;
    int abs_index = be_absindex(vm, index);

    buffer.data = NULL;
    buffer.length = 0;
    buffer.owned = NULL;

    if (be_isstring(vm, abs_index)) {
        buffer.data = (const uint8_t *)be_tostring(vm, abs_index);
        buffer.length = (size_t)be_strlen(vm, abs_index);
        if (buffer.length > BE_P2_BUS_MAX_XFER) {
            be_raise(vm, "value_error", "data exceeds v1 transfer limit");
        }
        return buffer;
    }

    if (be_isbytes(vm, abs_index)) {
        buffer.data = (const uint8_t *)be_tobytes(vm, abs_index, &buffer.length);
        if (buffer.length > BE_P2_BUS_MAX_XFER) {
            be_raise(vm, "value_error", "data exceeds v1 transfer limit");
        }
        return buffer;
    }

    if (be_islistinstance(vm, abs_index)) {
        int size;
        int i;

        be_getmember(vm, abs_index, ".p");
        if (!be_islist(vm, -1)) {
            be_pop(vm, 1);
            be_raise(vm, "type_error", what);
        }

        size = be_data_size(vm, -1);
        if (size < 0) {
            be_pop(vm, 1);
            be_raise(vm, "type_error", what);
        }
        if ((size_t)size > BE_P2_BUS_MAX_XFER) {
            be_pop(vm, 1);
            be_raise(vm, "value_error", "data exceeds v1 transfer limit");
        }

        buffer.length = (size_t)size;
        buffer.owned = (uint8_t *)malloc(buffer.length ? buffer.length : 1u);
        if (!buffer.owned) {
            be_pop(vm, 1);
            be_raise(vm, "memory_error", "failed to allocate transfer buffer");
        }

        for (i = 0; i < size; ++i) {
            be_pushint(vm, (bint)i);
            be_getindex(vm, -2);
            if (!be_isint(vm, -1)) {
                free(buffer.owned);
                buffer.owned = NULL;
                be_pop(vm, 3);
                be_raise(vm, "type_error", "list data must contain ints");
            }
            {
                bint value = be_toint(vm, -1);
                if (value < 0 || value > 255) {
                    free(buffer.owned);
                    buffer.owned = NULL;
                    be_pop(vm, 3);
                    be_raise(vm, "value_error", "list data ints must be between 0 and 255");
                }
                buffer.owned[i] = (uint8_t)value;
            }
            be_pop(vm, 2);
        }

        be_pop(vm, 1);
        buffer.data = buffer.owned;
        return buffer;
    }

    be_raise(vm, "type_error", what);
    return buffer;
}

#endif
