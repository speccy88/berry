#ifndef BERRY_CONF_P2_H
#define BERRY_CONF_P2_H

#include <assert.h>
#include <stdlib.h>

#ifndef BE_DEBUG
#define BE_DEBUG                        0
#endif

#ifndef BE_P2_HEAP_BYTES
#define BE_P2_HEAP_BYTES                (192 * 1024)
#endif

#include "p2_heap.h"

/*
 * Favor smaller objects and lower VM overhead for the first Propeller 2 port.
 * FlexC targets ILP32 on P2, so using `long` keeps integers compact.
 */
#define BE_INTGER_TYPE                  1
#define BE_USE_SINGLE_FLOAT             1
#define BE_BYTES_MAX_SIZE               (4 * 1024)
#define BE_USE_PRECOMPILED_OBJECT       1
#define BE_P2_CUSTOM_PRECOMPILED_BUILTINS 1
#define BE_P2_NO_SMALL_POOLS            1
#define BE_P2_SIMPLE_REALLOC            1
#define BE_P2_BUMP_HEAP_BYTES           (128 * 1024)

#define BE_DEBUG_SOURCE_FILE            0
#define BE_DEBUG_RUNTIME_INFO           0
#define BE_DEBUG_VAR_INFO               0
#define BE_P2_STARTUP_TRACE             0
#define BE_USE_PERF_COUNTERS            0
#define BE_VM_OBSERVABILITY_SAMPLING    18

#define BE_STACK_TOTAL_MAX              1024
#define BE_STACK_FREE_MIN               8
#define BE_STACK_START                  32
#define BE_CONST_SEARCH_SIZE            32
#define BE_USE_STR_HASH_CACHE           0

#define BE_USE_FILE_SYSTEM              0
#define BE_USE_SCRIPT_COMPILER          1
#define BE_USE_BYTECODE_SAVER           0
#define BE_USE_BYTECODE_LOADER          0
#define BE_USE_SHARED_LIB               0
#define BE_USE_OVERLOAD_HASH            0

#define BE_USE_DEBUG_HOOK               0
#define BE_USE_DEBUG_GC                 0
#define BE_USE_DEBUG_STACK              0
#define BE_USE_MEM_ALIGNED              0

#define BE_USE_STRING_MODULE            0
#define BE_USE_JSON_MODULE              0
#define BE_USE_MATH_MODULE              0
#define BE_USE_TIME_MODULE              0
#define BE_USE_OS_MODULE                0
#define BE_USE_GLOBAL_MODULE            0
#define BE_USE_SYS_MODULE               0
#define BE_USE_DEBUG_MODULE             0
#define BE_USE_GC_MODULE                0
#define BE_USE_SOLIDIFY_MODULE          0
#define BE_USE_INTROSPECT_MODULE        0
#define BE_USE_STRICT_MODULE            0

#define BE_EXPLICIT_ABORT               abort
#define BE_EXPLICIT_EXIT                exit
#define BE_EXPLICIT_MALLOC              p2_heap_malloc
#define BE_EXPLICIT_FREE                p2_heap_free
#define BE_EXPLICIT_REALLOC             p2_heap_realloc

#define be_assert(expr)                 assert(expr)

#endif
