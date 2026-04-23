#include <propeller2.h>
#include <stdio.h>

#include "berry.h"
#include "be_repl.h"
#include "berry_port.h"
#include "p2_build_info.h"

int stackspace[4096];

#if BE_DEBUG
#define P2_FULL_VERSION "Berry " BERRY_VERSION " (debug)"
#else
#define P2_FULL_VERSION "Berry " BERRY_VERSION
#endif

#if defined(__CATALINA__)
#define P2_COMPILER "Catalina"
#define P2_RUNTIME "Propeller 2 Edge (P2_EDGE, compact)"
#elif defined(__clang__)
#define P2_COMPILER "clang"
#define P2_RUNTIME "Propeller 2"
#elif defined(__GNUC__)
#define P2_COMPILER "GCC"
#define P2_RUNTIME "Propeller 2"
#else
#define P2_COMPILER "Unknown Compiler"
#define P2_RUNTIME "Propeller 2"
#endif

static void p2_print_banner(void)
{
    char buffer[192];

    snprintf(buffer, sizeof(buffer),
        "%s (build %s %s)\n",
        P2_FULL_VERSION,
        P2_BUILD_DATE_STR,
        P2_BUILD_TIME_STR);
    p2_serial_puts(buffer);

    snprintf(buffer, sizeof(buffer),
        "[%s] on %s\n",
        P2_COMPILER,
        P2_RUNTIME);
    p2_serial_puts(buffer);

    snprintf(buffer, sizeof(buffer),
        "[image %lu B | code %lu B | const %lu B | init %lu B | data %lu B]\n",
        (unsigned long)P2_BUILD_BINARY_BYTES,
        (unsigned long)P2_BUILD_CODE_BYTES,
        (unsigned long)P2_BUILD_CONST_BYTES,
        (unsigned long)P2_BUILD_INIT_BYTES,
        (unsigned long)P2_BUILD_DATA_BYTES);
    p2_serial_puts(buffer);

    snprintf(buffer, sizeof(buffer),
        "[heap %lu B | stack %d slots | bytes max %d B]\n",
        (unsigned long)BE_P2_HEAP_BYTES,
        BE_STACK_TOTAL_MAX,
        BE_BYTES_MAX_SIZE);
    p2_serial_puts(buffer);
}

static void berry_p2_main(void)
{
    bvm *vm;

    p2_serial_init();
    p2_print_banner();
    p2_serial_puts("[Ctrl-D or Ctrl-C at an empty prompt quits]\n");
    vm = be_vm_new();
    if (!vm) {
        p2_serial_puts("error: failed to create VM\n");
        for (;;) {
        }
    }

    for (;;) {
        int res = be_repl(vm, p2_readline, p2_freeline);
        if (p2_take_exit_request() || res == BE_EXIT) {
            p2_serial_puts("bye\n");
            break;
        }
        if (res == BE_MALLOC_FAIL) {
            p2_serial_puts("error: REPL ran out of memory\n");
            p2_serial_puts("bye\n");
            break;
        }
    }
}

int main()
{
    berry_p2_main();
    return 0;
}
