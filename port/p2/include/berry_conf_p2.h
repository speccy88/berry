#ifndef BERRY_CONF_P2_H
#define BERRY_CONF_P2_H

#include <assert.h>
#include <stdlib.h>

#define BE_P2_PROFILE_MINIMAL           1
#define BE_P2_PROFILE_FULL              2
#define BE_P2_PROFILE_EDGE32            3
#define BE_P2_PROFILE_XMM               4
#define BE_P2_PROFILE_SDDIAG            5

#define BE_P2_BOARD_P2EDGE              1
#define BE_P2_BOARD_P2EDGE32            2

#define BE_P2_SILICON_OLD               1
#define BE_P2_SILICON_LATEST            2

#ifndef BE_P2_PROFILE
#define BE_P2_PROFILE                   BE_P2_PROFILE_FULL
#endif

#ifndef BE_P2_BOARD
#if BE_P2_PROFILE == BE_P2_PROFILE_EDGE32 || BE_P2_PROFILE == BE_P2_PROFILE_XMM || BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG
#define BE_P2_BOARD                     BE_P2_BOARD_P2EDGE32
#else
#define BE_P2_BOARD                     BE_P2_BOARD_P2EDGE
#endif
#endif

#ifndef BE_P2_BOARD_NAME
#if BE_P2_BOARD == BE_P2_BOARD_P2EDGE32
#define BE_P2_BOARD_NAME                "p2edge32"
#else
#define BE_P2_BOARD_NAME                "p2edge"
#endif
#endif

#ifndef BE_P2_BOARD_HAS_PSRAM
#define BE_P2_BOARD_HAS_PSRAM           (BE_P2_BOARD == BE_P2_BOARD_P2EDGE32)
#endif

#ifndef BE_P2_BOARD_LED0_PIN
#if BE_P2_BOARD == BE_P2_BOARD_P2EDGE32
#define BE_P2_BOARD_LED0_PIN            38
#else
#define BE_P2_BOARD_LED0_PIN            56
#endif
#endif

#ifndef BE_P2_BOARD_LED1_PIN
#if BE_P2_BOARD == BE_P2_BOARD_P2EDGE32
#define BE_P2_BOARD_LED1_PIN            39
#else
#define BE_P2_BOARD_LED1_PIN            57
#endif
#endif

#ifndef BE_P2_SILICON
#define BE_P2_SILICON                   BE_P2_SILICON_LATEST
#endif

#ifndef BE_P2_SILICON_NAME
#if BE_P2_SILICON == BE_P2_SILICON_OLD
#define BE_P2_SILICON_NAME              "old"
#else
#define BE_P2_SILICON_NAME              "latest"
#endif
#endif

#if BE_P2_PROFILE == BE_P2_PROFILE_MINIMAL
#define BE_P2_PROFILE_NAME              "minimal"

#define BE_USE_JSON                     0
#define BE_USE_MATH                     0
#define BE_USE_OS                       0
#define BE_USE_FILE                     0
#define BE_USE_INTROSPECT               0
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         0
#define BE_P2_USE_P2_MODULE             0
#define BE_P2_USE_I2C_MODULE            0
#define BE_P2_USE_SPI_MODULE            0
#define BE_P2_USE_RTOS_MODULE           0
#define BE_P2_USE_THREADS_MODULE        0
#define BE_P2_USE_SPIN2_MODULE          0
#define BE_P2_USE_WORKER_MODULE         0
#define BE_P2_USE_XMM_PLACEHOLDER       0
#define BE_P2_USE_EDGE32_PSRAM          0

#define BE_P2_HEAP_SIZE                 (192 * 1024)
#define BE_P2_WORKER_HEAP_SIZE          (4 * 1024)
#define BE_P2_STACK_SLOTS               512
#define BE_P2_BYTES_MAX                 2048

#elif BE_P2_PROFILE == BE_P2_PROFILE_EDGE32 || BE_P2_PROFILE == BE_P2_PROFILE_XMM || BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG
#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
#define BE_P2_PROFILE_NAME              "xmm"
#elif BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG
#define BE_P2_PROFILE_NAME              "sddiag"
#else
#define BE_P2_PROFILE_NAME              "edge32"
#endif

#define BE_USE_JSON                     (BE_P2_PROFILE != BE_P2_PROFILE_SDDIAG)
#define BE_USE_MATH                     0
#define BE_USE_OS                       1
#define BE_USE_FILE                     1
#define BE_USE_INTROSPECT               (BE_P2_PROFILE != BE_P2_PROFILE_SDDIAG)
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         (BE_P2_PROFILE != BE_P2_PROFILE_SDDIAG)
#define BE_P2_USE_P2_MODULE             1
#define BE_P2_USE_I2C_MODULE            (BE_P2_PROFILE != BE_P2_PROFILE_SDDIAG)
#define BE_P2_USE_SPI_MODULE            (BE_P2_PROFILE != BE_P2_PROFILE_SDDIAG)
#define BE_P2_USE_RTOS_MODULE           0
#define BE_P2_USE_THREADS_MODULE        0
#define BE_P2_USE_SPIN2_MODULE          0 /* archived: replace with real closure/VM path */
#define BE_P2_USE_WORKER_MODULE         0
#define BE_P2_USE_XMM_PLACEHOLDER       0
#define BE_P2_USE_EDGE32_PSRAM          1

#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
/* Catalina LARGE/XMM exposes the lower PSRAM window as pointer-addressable C
 * memory. Reserve 1 MiB for Catalina/runtime allocations and use the rest as
 * the Berry VM heap arena. The upper 16 MiB remains the explicit block/cache
 * window through BE_P2_PSRAM_BLOCK_BASE. */
#define BE_P2_XMM_RUNTIME_RESERVE_BYTES (1 * 1024 * 1024)
#define BE_P2_HEAP_SIZE                 (15 * 1024 * 1024)
#elif BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG
#define BE_P2_HEAP_SIZE                 (96 * 1024)
#else
#define BE_P2_HEAP_SIZE                 (128 * 1024)
#endif
#define BE_P2_WORKER_HEAP_SIZE          (16 * 1024)
#define BE_P2_STACK_SLOTS               1024
#define BE_P2_BYTES_MAX                 (4 * 1024)

#elif BE_P2_PROFILE == BE_P2_PROFILE_FULL
#define BE_P2_PROFILE_NAME              "full"

#define BE_USE_JSON                     1
#define BE_USE_MATH                     0
#define BE_USE_OS                       1
#define BE_USE_FILE                     1
#define BE_USE_INTROSPECT               1
#define BE_USE_SOLIDIFY                 0
#define BE_USE_DEBUG                    0

#define BE_P2_USE_PROP2_GLOBALS         1
#define BE_P2_USE_P2_MODULE             1
#define BE_P2_USE_I2C_MODULE            1
#define BE_P2_USE_SPI_MODULE            1
#define BE_P2_USE_RTOS_MODULE           0
#define BE_P2_USE_THREADS_MODULE        0
#define BE_P2_USE_SPIN2_MODULE          0 /* archived: replace with real closure/VM path */
#define BE_P2_USE_WORKER_MODULE         0
#define BE_P2_USE_XMM_PLACEHOLDER       0

#define BE_P2_HEAP_SIZE                 (128 * 1024)
#define BE_P2_WORKER_HEAP_SIZE          (32 * 1024)
#define BE_P2_STACK_SLOTS               1024
#define BE_P2_BYTES_MAX                 (4 * 1024)

#else
#error Unsupported BE_P2_PROFILE
#endif

#ifndef BE_DEBUG
#define BE_DEBUG                        BE_USE_DEBUG
#endif

#ifndef BE_P2_HEAP_BYTES
#define BE_P2_HEAP_BYTES                BE_P2_HEAP_SIZE
#endif

#ifndef BE_P2_WORKER_HEAP_BYTES
#define BE_P2_WORKER_HEAP_BYTES         BE_P2_WORKER_HEAP_SIZE
#endif

#ifndef BE_P2_HUB_RAM_BYTES
#define BE_P2_HUB_RAM_BYTES             (512 * 1024)
#endif

#ifndef BE_P2_EXTERNAL_RAM_BYTES
#if BE_P2_PROFILE == BE_P2_PROFILE_EDGE32 || BE_P2_PROFILE == BE_P2_PROFILE_XMM || BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG
#define BE_P2_EXTERNAL_RAM_BYTES        (32 * 1024 * 1024)
#else
#define BE_P2_EXTERNAL_RAM_BYTES        0
#endif
#endif

#ifndef BE_P2_XMM_BYTES
#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
#define BE_P2_XMM_BYTES                 (16 * 1024 * 1024)
#else
#define BE_P2_XMM_BYTES                 0
#endif
#endif

#ifndef BE_P2_PSRAM_BLOCK_BASE
#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
#define BE_P2_PSRAM_BLOCK_BASE          BE_P2_XMM_BYTES
#else
#define BE_P2_PSRAM_BLOCK_BASE          0
#endif
#endif

#ifndef BE_P2_HEAP_USES_EXTERNAL_RAM
#if BE_P2_PROFILE == BE_P2_PROFILE_XMM
#define BE_P2_HEAP_USES_EXTERNAL_RAM    1
#else
#define BE_P2_HEAP_USES_EXTERNAL_RAM    0
#endif
#endif

#ifndef BE_P2_ENABLE_EXTENDED_MODULES
#define BE_P2_ENABLE_EXTENDED_MODULES   0
#endif

#ifndef BE_P2_ENABLE_TIME_MODULE
#define BE_P2_ENABLE_TIME_MODULE        0
#endif

#ifndef BE_P2_ENABLE_SD_DIAGNOSTICS
#define BE_P2_ENABLE_SD_DIAGNOSTICS     (BE_P2_PROFILE == BE_P2_PROFILE_SDDIAG)
#endif

#include "p2_heap.h"

/*
 * Favor smaller objects and lower VM overhead for the first Propeller 2 port.
 * FlexC targets ILP32 on P2, so using `long` keeps integers compact.
 */
#define BE_INTGER_TYPE                  1
#define BE_USE_SINGLE_FLOAT             1
#define BE_BYTES_MAX_SIZE               BE_P2_BYTES_MAX
#define BE_USE_PRECOMPILED_OBJECT       1
#define BE_P2_CUSTOM_PRECOMPILED_BUILTINS 1
#define BE_P2_NO_SMALL_POOLS            0
#define BE_P2_SIMPLE_REALLOC            0

#define BE_DEBUG_SOURCE_FILE            0
#define BE_DEBUG_RUNTIME_INFO           0
#define BE_DEBUG_VAR_INFO               0
#define BE_P2_STARTUP_TRACE             0
#define BE_P2_ENABLE_MAIN_INTERRUPT     1
#define BE_USE_PERF_COUNTERS            0
#define BE_VM_OBSERVABILITY_SAMPLING    18
#define BE_P2_TRACE_GC_COLLECT          0
#define BE_P2_TRACE_GC_MODULE           0

#define BE_STACK_TOTAL_MAX              BE_P2_STACK_SLOTS
#define BE_STACK_FREE_MIN               8
#define BE_STACK_START                  32
#define BE_CONST_SEARCH_SIZE            32
#define BE_USE_STR_HASH_CACHE           0

#define BE_USE_FILE_SYSTEM              BE_USE_FILE
#define BE_USE_SCRIPT_COMPILER          1
#ifndef BE_P2_ENABLE_BYTECODE_SAVER
#define BE_P2_ENABLE_BYTECODE_SAVER     0
#endif
#ifndef BE_P2_ENABLE_BYTECODE_LOADER
#define BE_P2_ENABLE_BYTECODE_LOADER    0
#endif
#ifndef BE_P2_ENABLE_BYTECODE_EXECUTION
#define BE_P2_ENABLE_BYTECODE_EXECUTION 0
#endif
#define BE_USE_BYTECODE_SAVER           BE_P2_ENABLE_BYTECODE_SAVER
#define BE_USE_BYTECODE_LOADER          BE_P2_ENABLE_BYTECODE_LOADER
#define BE_USE_SHARED_LIB               0
#define BE_USE_OVERLOAD_HASH            0

#define BE_USE_DEBUG_HOOK               0
#define BE_USE_DEBUG_GC                 0
#define BE_USE_DEBUG_STACK              0
#define BE_USE_MEM_ALIGNED              0

#define BE_USE_STRING_MODULE            1
#define BE_USE_JSON_MODULE              BE_USE_JSON
#define BE_USE_MATH_MODULE              BE_USE_MATH
#define BE_USE_TIME_MODULE              BE_P2_ENABLE_TIME_MODULE
#define BE_USE_OS_MODULE                BE_USE_OS
#define BE_USE_GLOBAL_MODULE            BE_P2_ENABLE_EXTENDED_MODULES
#define BE_USE_SYS_MODULE               BE_P2_ENABLE_EXTENDED_MODULES
#define BE_USE_DEBUG_MODULE             BE_P2_ENABLE_EXTENDED_MODULES
#define BE_USE_GC_MODULE                BE_P2_ENABLE_EXTENDED_MODULES
#define BE_USE_SOLIDIFY_MODULE          BE_USE_SOLIDIFY
#define BE_USE_INTROSPECT_MODULE        BE_USE_INTROSPECT
#define BE_USE_STRICT_MODULE            BE_P2_ENABLE_EXTENDED_MODULES

#define BE_EXPLICIT_ABORT               abort
#define BE_EXPLICIT_EXIT                exit
#define BE_EXPLICIT_MALLOC              p2_heap_malloc
#define BE_EXPLICIT_FREE                p2_heap_free
#define BE_EXPLICIT_REALLOC             p2_heap_realloc

#define be_assert(expr)                 assert(expr)

#endif
