#include <string.h>
#include <propeller2.h>

#include "berry.h"
#include "be_repl.h"
#include "berry_port.h"

enum {
    HEAPSIZE = 48 * 1024
};

int stackspace[256];

static int run_chunk(bvm *vm, const char *name, const char *source)
{
    int res = be_loadbuffer(vm, name, source, strlen(source));

    if (res == BE_OK) {
        res = be_pcall(vm, 0);
        if (res == BE_OK) {
            if (!be_isnil(vm, -1)) {
                be_dumpvalue(vm, -1);
            } else {
                be_pop(vm, 1);
            }
            return BE_OK;
        }
    }

    if (res == BE_EXCEPTION) {
        be_dumpexcept(vm);
    } else if (res == BE_MALLOC_FAIL) {
        be_writestring("error: out of memory\n");
    } else {
        be_writestring("error: boot script failed\n");
    }

    return res;
}

static void berry_p2_main(void)
{
    bvm *vm;

    p2_serial_init();

    p2_serial_puts("\nBerry on Propeller 2\n");
    vm = be_vm_new();
    if (!vm) {
        p2_serial_puts("error: failed to create VM\n");
        for (;;) {
        }
    }

    run_chunk(vm, "<boot>", "print(\"Berry on P2\")");

    for (;;) {
        int res = be_repl(vm, p2_readline, p2_freeline);
        if (res == BE_MALLOC_FAIL) {
            p2_serial_puts("error: REPL ran out of memory\n");
        }
    }
}

void main(void)
{
    berry_p2_main();
}
