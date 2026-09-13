/* Host-only tests of the production Hub allocator wrapper.
 * Lock intrinsics and the SDK allocator are explicit test seams, not cogs.
 */
#include "p2_hub_heap.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int available;
static int held;
static int busy_reads;
static int fail_realloc;
static unsigned lock_requests, acquisitions, releases, allocator_calls;

int _locknew(void)
{
    ++lock_requests;
    return available ? 7 : -1;
}

int _locktry(int lock)
{
    assert(lock == 7);
    if (busy_reads > 0) {
        --busy_reads;
        return 0;
    }
    assert(!held);
    held = 1;
    ++acquisitions;
    return 1;
}

void _lockrel(int lock)
{
    assert(lock == 7 && held);
    held = 0;
    ++releases;
}

void *hub_realloc(void *ptr, size_t size)
{
    assert(held);
    ++allocator_calls;
    if (fail_realloc) {
        fail_realloc = 0;
        return NULL;
    }
    return realloc(ptr, size);
}

void hub_free(void *ptr)
{
    assert(held);
    ++allocator_calls;
    free(ptr);
}

int main(void)
{
    unsigned char *p;
    unsigned before;
    size_t i;
    assert(p2_hub_malloc(16) == NULL);
    assert(allocator_calls == 0);
    assert(!p2_hub_heap_init());
    available = 1;
    assert(p2_hub_heap_init());
    before = lock_requests;
    assert(p2_hub_heap_init());
    assert(lock_requests == before);
    busy_reads = 3;
    p = p2_hub_calloc(4, 8);
    assert(p != NULL && busy_reads == 0 && !held);
    for (i = 0; i < 32; ++i) {
        assert(p[i] == 0);
        p[i] = (unsigned char)i;
    }
    fail_realloc = 1;
    assert(p2_hub_realloc(p, 64) == NULL && !held);
    for (i = 0; i < 32; ++i) {
        assert(p[i] == (unsigned char)i);
    }
    before = allocator_calls;
    assert(p2_hub_calloc((size_t)-1, 2) == NULL);
    assert(allocator_calls == before && !held);
    p2_hub_free(p);
    before = allocator_calls;
    p2_hub_free(NULL);
    assert(allocator_calls == before);
    assert(acquisitions == releases && !held);
    puts("PASS Hub allocator wrapper: initialization, locking, overflow, OOM, free");
    return 0;
}
