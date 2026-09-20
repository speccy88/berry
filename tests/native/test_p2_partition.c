/* Actual production control/allocator. Only cog identity and hardware locks
 * are host seams. This does not simulate cache coherence or physical cogs. */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
int test_p2_cog;
#ifdef TEST_FRESH_BREAK
static unsigned char virgin_break[8192];
static unsigned break_bytes, break_calls;
int p2_test_fresh_break(int n) {
    unsigned old = break_bytes;
    if (n < 0 || (unsigned)n > sizeof(virgin_break)-old) return -1;
    if (n) { break_bytes += ((unsigned)n+3u)&~3u; ++break_calls; }
    return (int)(uintptr_t)(virgin_break+old);
}
#endif
static int locked;
static int _locktry(int id) { assert(id == 3); assert(!locked); locked=1; return 1; }
static void _lockrel(int id) { assert(id == 3 && locked); locked=0; }
#include "../../port/p2/runtime/p2_heap.c"
#include "../../port/p2/runtime/p2_partition.c"
static void hub_backing_cases(void)
{
#ifndef P2_PARTITION_HUB_API
    assert(!"RED: bounded Hub partition reservation is absent");
#else
    p2_partition a = {0}, b = {0}, bad = {0};
    union { unsigned char raw[2048]; double align; } ra, rb;
    unsigned char *x, *y, *moved;
    size_t before;
    test_p2_cog=5;
    assert(!p2_partition_reserve_hub(&a, 51, ra.raw, sizeof(ra.raw), 3, 4));
    test_p2_cog=0;
    assert(!p2_partition_reserve_hub(&bad, 1, ra.raw+1, 1024, 3, 4));
    assert(!p2_partition_reserve_hub(&bad, 1, ra.raw, (size_t)-1, 3, 4));
    assert(!p2_partition_reserve_hub(&bad, 1, &bad, sizeof(bad), 3, 4));
    assert(p2_partition_reserve_hub(&a,51,ra.raw,sizeof(ra.raw),3,4));
    assert(p2_partition_reserve_hub(&b,52,rb.raw,sizeof(rb.raw),3,4));
    assert(p2_partition_is_hub(&a,51) && p2_partition_is_hub(&b,52));
    assert(!p2_partition_is_hub(&a,52) && !p2_partition_is_hub(&bad,1));
    assert(!p2_partition_reserve_hub(&a,53,rb.raw,sizeof(rb.raw),3,4));
    assert(p2_partition_offer(&a,51,6)); assert(p2_partition_offer(&b,52,5));
    test_p2_cog=6; assert(p2_partition_claim(&a,51)==1);
    before=p2_partition_free_bytes(&a,51);
    x=p2_partition_realloc(&a,NULL,64); assert(x); memset(x,0x73,64);
    y=p2_partition_realloc(&a,NULL,64); assert(y);
    moved=p2_partition_realloc(&a,x,256); assert(moved && moved!=x);
    assert(!p2_partition_realloc(&a,moved,(size_t)-1));
    for (int i=0;i<64;++i) assert(moved[i]==0x73);
    test_p2_cog=5; assert(!p2_partition_realloc(&a,moved,0));
    assert(p2_partition_claim(&b,52)==1);
    assert(!p2_partition_realloc(&b,moved,0));
    assert(p2_partition_rejections(&b,52)==1);
    test_p2_cog=6; p2_partition_realloc(&a,moved,0); p2_partition_realloc(&a,y,0);
    assert(p2_partition_free_bytes(&a,51)==before);
    assert(p2_partition_retire(&a,51)); assert(!p2_partition_realloc(&a,NULL,8));
    test_p2_cog=5; assert(p2_partition_retire(&b,52));
    test_p2_cog=0;
    puts("PASS supplied bounded Hub arenas: owner separation, moved/failed growth, foreign rejection, cleanup, quarantine");
#endif
}
int main(void)
{
    p2_partition a = {0}, b = {0}, invalid = {0};
    unsigned char *x, *y;
    size_t before;
    test_p2_cog=5;
    assert(p2_heap_malloc(8)==NULL); /* no implicit worker -> main routing */
    assert(p2_heap_realloc(NULL,8)==NULL);
    assert(p2_heap_free_bytes()==0);
    test_p2_cog=0;
    assert(!p2_partition_reserve(&invalid, 0, 512, 32, 3, 4));
    assert(!p2_partition_reserve(&invalid, 1, (size_t)-1, 32, 3, 4));
    assert(!p2_partition_reserve(&invalid, 1, 512, 16, 3, 4));
    assert(p2_partition_reserve(&a, 17, 512, 32, 3, 4));
    assert(p2_partition_reserve(&b, 18, 512, 32, 3, 4));
    assert(!p2_partition_is_hub(&a,17) && !p2_partition_is_hub(&b,18));
    assert(!p2_partition_reserve(&a, 19, 512, 32, 3, 4));
#ifdef TEST_FRESH_BREAK
    assert(break_calls == 2);
#endif
    assert(p2_partition_claim(&a, 17) == -1);
    assert(!p2_partition_offer(&a, 99, 6));
    test_p2_cog=5; assert(!p2_partition_offer(&a, 17, 6));
    test_p2_cog=0; assert(p2_partition_offer(&a,17,6));
    test_p2_cog=5; assert(!p2_partition_claim(&a,17));
    test_p2_cog=6; assert(!p2_partition_claim(&a,99));
    assert(p2_partition_claim(&a,17)==1);
    assert(!p2_partition_claim(&a,17));
    assert(p2_partition_execution_lock(&a,17)==4);
    assert(p2_partition_execution_lock(&a,99)==-1);
    before=p2_partition_free_bytes(&a,17);
    x=p2_partition_realloc(&a,NULL,64); assert(x); memset(x,0x5a,64);
    assert(!p2_partition_retire(&a,17));
    assert(!p2_partition_realloc(&a,x,(size_t)-1));
    for (int i=0;i<64;++i) assert(x[i]==0x5a);
    test_p2_cog=0; assert(!p2_partition_realloc(&a,x,0));
    assert(!p2_partition_cancel(&a,17)); /* running owner still owns cleanup */
    assert(p2_partition_offer(&b,18,5));
    test_p2_cog=5; assert(p2_partition_claim(&b,18)==1);
    assert(!p2_partition_realloc(&b,x,0));
    y=p2_partition_realloc(&b,NULL,64); assert(y && y!=x);
    p2_partition_realloc(&b,y,0); assert(p2_partition_retire(&b,18));
    assert(!p2_partition_claim(&b,18));
    test_p2_cog=6; p2_partition_realloc(&a,x,0);
    assert(p2_partition_free_bytes(&a,17)==before);
    assert(p2_partition_retire(&a,17));
    assert(!p2_partition_realloc(&a,NULL,8));
    test_p2_cog=0;
    assert(!p2_partition_offer(&a,17,6)); /* retirement is permanent */
    assert(p2_heap_malloc(8)); /* closes the virgin reservation phase */
    assert(!p2_partition_reserve(&invalid,3,512,32,3,4));
    assert(!locked);
    hub_backing_cases();
    puts("PASS explicit partition ownership, stale identity, cancellation, quarantine and fail-closed allocation");
    return 0;
}
