#ifndef P2_CLOCK_H
#define P2_CLOCK_H

#include <stdint.h>

#define P2_DEADLINE_MAX_DELAY 0x7fffffffU

typedef struct p2_deadline {
    uint32_t at_ms;
    int armed;
} p2_deadline;

/* Divide the unsigned (high, low) pair: quotient modulo 2^32, exact remainder.
 * All result pointers must be valid. Zero divisor/frequency returns failure
 * without changing outputs. No Catalina 64-bit C type is required.
 */
int p2_clock_divmod(uint32_t high, uint32_t low, uint32_t divisor,
    uint32_t *quotient, uint32_t *remainder);
int p2_clock_ticks_to_millis(uint32_t high, uint32_t low, uint32_t clock_hz,
    uint32_t *millis);

#ifdef __CATALINA_P2
/* Stable high/low/high hardware sample, no shared rollover accumulator. */
int p2_clock_millis_now(uint32_t *millis);
#endif

/* Zero is a valid deadline. Invalid delays leave the whole deadline unchanged.
 * Poll within the signed half-range after expiry; modular time cannot order
 * timestamps separated by 2^31 ms or more. Repeat by arming from current time
 * for fixed-delay (not catch-up/fixed-rate) semantics.
 */
int p2_deadline_arm(p2_deadline *deadline, uint32_t now_ms, uint32_t delay_ms);
void p2_deadline_cancel(p2_deadline *deadline);
int p2_deadline_reached(const p2_deadline *deadline, uint32_t now_ms);
uint32_t p2_deadline_remaining(const p2_deadline *deadline, uint32_t now_ms);

#endif
