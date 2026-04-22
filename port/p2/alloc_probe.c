#include "berry_port.h"
#include "be_vm.h"
#include "p2_heap.h"

#include <string.h>

int main(void)
{
    char *buf1;
    char *buf2;

    p2_serial_init();
    p2_serial_puts("\nalloc probe alive\n");
    p2_serial_puts("before malloc1\n");
    buf1 = p2_heap_malloc(sizeof(bvm));
    if (!buf1) {
        p2_serial_puts("malloc1 failed\n");
        for (;;) {
        }
    }
    p2_serial_puts("after malloc1\n");
    p2_serial_puts("before malloc2\n");
    buf2 = p2_heap_malloc(16);
    if (!buf2) {
        p2_serial_puts("malloc2 failed\n");
        for (;;) {
        }
    }
    p2_serial_puts("after malloc2\n");
    memset(buf1, 0x11, sizeof(bvm));
    memset(buf2, 0x22, 16);
    p2_serial_puts("filled\n");
    p2_heap_free(buf2);
    p2_heap_free(buf1);
    p2_serial_puts("after free\n");

    for (;;) {
    }
}
