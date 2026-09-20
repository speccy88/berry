/* Native unit inputs at the Catalina HMI boundary, NOT physical UART proof.
 * Real p2_smartserial.c is compiled. SDK service results are supplied explicitly:
 * target/p2/hmisimpl.t and hmitty.t translate EOT (4) to -1. */
#include <stdio.h>
/* HMI service results change between calls, like hardware mailbox reads. */
static volatile int service_value, ready;
int k_wait(void) { return service_value; }
int k_get(void) { return service_value; }
int k_ready(void) { return ready; }
#define __CATALINA__ 1
#include "p2_smartserial.inc"
int main(void)
{
    unsigned failures = 0;
    int values[] = {3, 4, 13, 65, 127, 255};
    unsigned i;
    for (i = 0; i < sizeof(values) / sizeof(values[0]); ++i) {
        service_value = values[i] == 4 ? -1 : values[i];
        ready = 1;
        if (p2_smartserial_rx() != values[i]) {
            fprintf(stderr, "blocking HMI translation failed for byte %d\n", values[i]);
            ++failures;
        }
        if (p2_smartserial_rxcheck() != values[i]) {
            fprintf(stderr, "ready HMI translation failed for byte %d\n", values[i]);
            ++failures;
        }
        ready = 0;
        if (p2_smartserial_rxcheck() != -1) ++failures;
    }
    printf("Catalina serial adapter: failures=%u (native HMI fixtures only)\n", failures);
    return failures ? 1 : 0;
}
