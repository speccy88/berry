enum {
    _clkfreq = 160000000
};

#include <stdio.h>
#include <propeller.h>

static const unsigned char filler[150000] = { 1 };

int main(void)
{
    _setbaud(115200);
    printf("load probe %u\n", (unsigned)filler[0]);
    for (;;) {
    }
    return 0;
}
