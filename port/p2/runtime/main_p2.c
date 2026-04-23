#include <propeller2.h>

#include "berry.h"
#include "be_repl.h"
#include "berry_port.h"

int stackspace[4096];

#if BE_DEBUG
#define P2_FULL_VERSION "Berry " BERRY_VERSION " (debug)"
#else
#define P2_FULL_VERSION "Berry " BERRY_VERSION
#endif

#if defined(__CATALINA__)
#define P2_BUILD_TIME "unknown"
#else
#define P2_BUILD_TIME __TIME__
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

#define P2_REPL_PRELUDE \
    P2_FULL_VERSION " (build in " __DATE__ ", " P2_BUILD_TIME ")\n" \
    "[" P2_COMPILER "] on " P2_RUNTIME " (p2)\n"

static void berry_p2_main(void)
{
    bvm *vm;

    p2_serial_init();
    p2_serial_puts(P2_REPL_PRELUDE);
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
