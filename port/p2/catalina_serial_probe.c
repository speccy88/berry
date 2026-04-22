#include <serial2.h>

static void serial2_puts(const char *s)
{
    while (*s) {
        s_tx(0, *s++);
    }
}

int main(void)
{
    serial2_puts("catalina serial2 probe alive\r\n");

    for (;;) {
        int ch = s_rx(0);
        if (ch >= 0) {
            serial2_puts("rx: ");
            s_tx(0, (char)ch);
            serial2_puts("\r\n");
        }
    }
}
