#include "p2_clock.h"

#ifdef __CATALINA_P2
#include <prop2.h>
#endif

int p2_clock_divmod(uint32_t high, uint32_t low, uint32_t divisor,
    uint32_t *quotient, uint32_t *remainder)
{
    uint32_t q = 0;
    uint32_t r;
    uint32_t carry;
    int bit;

    if (divisor == 0) {
        return 0;
    }
    /* The omitted high quotient contributes only multiples of 2^32. */
    r = high % divisor;
    for (bit = 31; bit >= 0; --bit) {
        carry = r >> 31;
        r = (r << 1) | ((low >> bit) & 1U);
        q <<= 1;
        /* Saved carry is the 33rd remainder bit; unsigned wrap is deliberate. */
        if (carry || r >= divisor) {
            r -= divisor;
            q |= 1U;
        }
    }
    *quotient = q;
    *remainder = r;
    return 1;
}

int p2_clock_ticks_to_millis(uint32_t high, uint32_t low, uint32_t clock_hz,
    uint32_t *millis)
{
    uint32_t seconds, remainder, fraction;
    uint32_t low_product, high_product;

    if (!p2_clock_divmod(high, low, clock_hz, &seconds, &remainder)) {
        return 0;
    }
    /* Exact remainder * 1000 as a pair, using products of 16-bit halves. */
    low_product = (remainder & 0xffffU) * 1000U;
    high_product = (remainder >> 16) * 1000U;
    low = low_product + (high_product << 16);
    high = (high_product >> 16) + (low < low_product);
    p2_clock_divmod(high, low, clock_hz, &fraction, &remainder);
    *millis = seconds * 1000U + fraction;
    return 1;
}

#ifdef __CATALINA_P2
int p2_clock_millis_now(uint32_t *millis)
{
    uint32_t high, low, after;
    uint32_t hz = _clockfreq();

    if (hz == 0) {
        return 0;
    }
    do {
        high = _cnth();
        low = _cnt();
        after = _cnth();
    } while (high != after);
    return p2_clock_ticks_to_millis(high, low, hz, millis);
}
#endif

int p2_deadline_arm(p2_deadline *deadline, uint32_t now_ms, uint32_t delay_ms)
{
    if (delay_ms > P2_DEADLINE_MAX_DELAY) {
        return 0;
    }
    deadline->at_ms = now_ms + delay_ms;
    deadline->armed = 1;
    return 1;
}

void p2_deadline_cancel(p2_deadline *deadline)
{
    deadline->armed = 0;
}

int p2_deadline_reached(const p2_deadline *deadline, uint32_t now_ms)
{
    return deadline->armed && (uint32_t)(now_ms - deadline->at_ms) < 0x80000000U;
}

uint32_t p2_deadline_remaining(const p2_deadline *deadline, uint32_t now_ms)
{
    if (!deadline->armed || p2_deadline_reached(deadline, now_ms)) {
        return 0;
    }
    return deadline->at_ms - now_ms;
}
