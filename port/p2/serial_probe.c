#include "berry_port.h"
#include "p2_smartserial.h"

int main(void)
{
    p2_serial_init();
    p2_serial_puts("\nserial probe alive\n");

    for (;;) {
        int ch = p2_smartserial_rx();
        if (ch >= 0) {
            p2_serial_puts("rx: ");
            p2_smartserial_tx(ch);
            p2_serial_puts("\n");
        }
    }
}
