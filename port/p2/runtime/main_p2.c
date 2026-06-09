#include <propeller2.h>
#include <stdio.h>

#include "berry.h"
#include "be_repl.h"
#include "berry_port.h"
#include "p2_build_info.h"

#ifndef BE_P2_RUN_SD_MAIN
#define BE_P2_RUN_SD_MAIN 1
#endif

#define BE_P2_SD_MAIN_PATH "/berry/main.be"

int stackspace[4096];

#if BE_DEBUG
#define P2_FULL_VERSION "Berry " BERRY_VERSION " (debug)"
#else
#define P2_FULL_VERSION "Berry " BERRY_VERSION
#endif

#if defined(__CATALINA__)
#define P2_COMPILER "Catalina"
#if defined(__CATALINA_libpsram) || defined(__CATALINA_PSRAM)
#define P2_RUNTIME "Propeller 2 Edge (P2_EDGE, PSRAM)"
#else
#define P2_RUNTIME "Propeller 2 Edge (P2_EDGE, no PSRAM)"
#endif
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
        "[%s] on %s [%s profile]\n",
        P2_COMPILER,
        P2_RUNTIME,
        BE_P2_PROFILE_NAME);
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

    if (BE_P2_EXTERNAL_RAM_BYTES > 0) {
        if (BE_P2_XMM_BYTES > 0) {
            snprintf(buffer, sizeof(buffer),
                "[external %lu B PSRAM | XMM %lu B | block %lu B @ %lu | Berry heap %s]\n",
                (unsigned long)BE_P2_EXTERNAL_RAM_BYTES,
                (unsigned long)BE_P2_XMM_BYTES,
                (unsigned long)(BE_P2_EXTERNAL_RAM_BYTES - BE_P2_PSRAM_BLOCK_BASE),
                (unsigned long)BE_P2_PSRAM_BLOCK_BASE,
                BE_P2_HEAP_USES_EXTERNAL_RAM ? "external" : "Hub RAM");
        } else {
            snprintf(buffer, sizeof(buffer),
                "[external %lu B PSRAM block API | Berry heap %s]\n",
                (unsigned long)BE_P2_EXTERNAL_RAM_BYTES,
                BE_P2_HEAP_USES_EXTERNAL_RAM ? "external" : "Hub RAM");
        }
        p2_serial_puts(buffer);
    }
}

static int p2_try_run_sd_main(bvm *vm)
{
#if BE_P2_RUN_SD_MAIN && BE_USE_SCRIPT_COMPILER && BE_USE_FILE_SYSTEM
    int res = be_loadfile(vm, BE_P2_SD_MAIN_PATH);

    if (res == BE_IO_ERROR) {
        be_pop(vm, be_top(vm));
        return BE_OK;
    }
    if (res == BE_OK) {
        res = be_pcall(vm, 0);
    }
    be_pop(vm, be_top(vm));
    if (res != BE_OK && res != BE_EXIT) {
        p2_serial_puts("warning: /berry/main.be failed; continuing to REPL\n");
    }
    return res;
#else
    (void)vm;
    return BE_OK;
#endif
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

    if (p2_try_run_sd_main(vm) == BE_EXIT || p2_take_exit_request()) {
        p2_serial_puts("bye\n");
        return;
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
