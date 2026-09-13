#ifndef TEST_NATIVE_PROPELLER2_H
#define TEST_NATIVE_PROPELLER2_H

/* HOST-ONLY seam: selects allocator routing synchronously, not a real P2 cog.
 * This supplies no hardware, concurrency, locking or PSRAM evidence. */
extern int test_p2_cog;
static int _cogid(void)
{
    return test_p2_cog;
}

#endif
