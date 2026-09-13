/* Native regression tests compile the ACTUAL production allocator below.
 * White-box access is limited to constructing segments, inspecting invariants,
 * and injecting impossible sizes without allocating enormous host buffers.
 * Each named case runs in a fresh process (including baseline crash cases).
 */
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef TEST_P2_HEAP_FREESTANDING32
#include "freestanding32/runtime.h"
#endif

int test_p2_cog;

/* External backing allocation is a bounded HOST-ONLY fixture, not PSRAM. */
static void *test_backing_malloc(size_t bytes);
static void test_backing_free(void *ptr);
#define malloc(bytes) test_backing_malloc(bytes)
#define free(ptr) test_backing_free(ptr)
#include "../../port/p2/runtime/p2_heap.c"
#undef malloc
#undef free

#define CHECK(condition) do { \
    if (!(condition)) { \
        printf("FAIL %s:%d: %s\n", __func__, __LINE__, #condition); \
        return 1; \
    } \
} while (0)

#define HEADER sizeof(p2_heap_block)
#define MAX_SIZE ((size_t)-1)
#define MAX_ADDRESS ((uintptr_t)-1)

typedef union test_storage {
    uint64_t alignment;
    unsigned char raw[8192];
} test_storage __attribute__((aligned(8)));

static test_storage backing[4];
static int backing_calls;
static int backing_frees;
static int backing_limit = 4;

static void *test_backing_malloc(size_t bytes)
{
    ++backing_calls;
    if (backing_calls > backing_limit || bytes > sizeof(backing[0].raw)) {
        return NULL;
    }
    return backing[backing_calls - 1].raw;
}

static void test_backing_free(void *ptr)
{
    if (ptr != NULL) {
        ++backing_frees;
    }
}

static int bytes_are(const unsigned char *ptr, size_t bytes, unsigned char value)
{
    size_t i;
    for (i = 0; i < bytes; ++i) {
        if (ptr[i] != value) {
            return 0;
        }
    }
    return 1;
}

static void init_arena(p2_heap_arena *arena, test_storage *storage, size_t bytes)
{
    memset(storage->raw, 0xa5, sizeof(storage->raw));
    memset(arena, 0, sizeof(*arena));
    if (!p2_heap_add_segment(arena, storage->raw, bytes)) {
        abort();
    }
    arena->ready = 1;
}

static void init_main(void)
{
    /* Override storage only in the test translation unit. Public APIs below
     * still execute unmodified allocator/routing/partition code. */
    static test_storage main_storage;
    init_arena(&p2_main_arena, &main_storage, sizeof(main_storage.raw));
}

static int test_zero_size(void)
{
    test_storage storage;
    p2_heap_arena arena;
    size_t before;
    void *ptr;
    init_arena(&arena, &storage, 1024);
    before = p2_heap_arena_free_bytes(&arena);
    CHECK(p2_heap_arena_malloc(&arena, 0) == NULL);
    CHECK(p2_heap_arena_realloc(&arena, NULL, 0) == NULL);
    p2_heap_arena_free(&arena, NULL);
    ptr = p2_heap_arena_realloc(&arena, NULL, 33);
    CHECK(ptr != NULL);
    CHECK(p2_heap_arena_realloc(&arena, ptr, 0) == NULL);
    CHECK(p2_heap_arena_free_bytes(&arena) == before);
    return 0;
}

static int test_alignment_split_coalesce(void)
{
    test_storage storage;
    p2_heap_arena arena;
    void *ptr[3];
    size_t before;
    int i;
    init_arena(&arena, &storage, 1024);
    before = p2_heap_arena_free_bytes(&arena);
    for (i = 0; i < 3; ++i) {
        ptr[i] = p2_heap_arena_malloc(&arena, (size_t)(i * 17 + 1));
        CHECK(ptr[i] != NULL);
        CHECK((uintptr_t)ptr[i] % P2_HEAP_ALIGN == 0);
        CHECK((((p2_heap_block *)ptr[i]) - 1)->size % P2_HEAP_ALIGN == 0);
    }
    p2_heap_arena_free(&arena, ptr[1]);
    p2_heap_arena_free(&arena, ptr[0]);
    p2_heap_arena_free(&arena, ptr[2]);
    CHECK(arena.head->next == NULL);
    CHECK(p2_heap_arena_free_bytes(&arena) == before);
    return 0;
}

static int test_adjacent_growth(void)
{
    test_storage storage;
    p2_heap_arena arena;
    unsigned char *ptr;
    init_arena(&arena, &storage, 1024);
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 64);
    CHECK(p2_heap_arena_realloc(&arena, ptr, 200) == ptr);
    CHECK(bytes_are(ptr, 64, 0x5a));
    CHECK(arena.head->size == 200);
    p2_heap_arena_free(&arena, ptr);
    CHECK(arena.head->next == NULL);
    CHECK(bytes_are(storage.raw + 1024, sizeof(storage.raw) - 1024, 0xa5));
    return 0;
}

static int segmented_growth(int adjacent, int fallback)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    unsigned char *ptr;
    unsigned char *result;
    size_t first_bytes = HEADER + 64;
    size_t second_offset = adjacent ? first_bytes : 512;
    size_t second_bytes = HEADER + (fallback ? 256 : 64);
    init_arena(&arena, &storage, first_bytes);
    CHECK(p2_heap_add_segment(&arena, storage.raw + second_offset, second_bytes));
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 64);
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    result = p2_heap_arena_realloc(&arena, ptr, 96);
    /* Check canaries BEFORE traversing potentially corrupt baseline metadata. */
    if (!adjacent) {
        CHECK(bytes_are(storage.raw + first_bytes, second_offset - first_bytes, 0xa5));
    }
    CHECK(bytes_are(storage.raw + second_offset + second_bytes,
        sizeof(storage.raw) - second_offset - second_bytes, 0xa5));
    if (adjacent) {
        CHECK(result == ptr);
        CHECK(bytes_are(result, 64, 0x5a));
    } else if (fallback) {
        CHECK(result == storage.raw + second_offset + HEADER);
        CHECK(bytes_are(result, 64, 0x5a));
        CHECK(arena.head->free);
    } else {
        CHECK(result == NULL);
        CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    }
    return 0;
}

static int test_adjacent_segments(void) { return segmented_growth(1, 0); }
static int test_nonadjacent_failure(void) { return segmented_growth(0, 0); }
static int test_nonadjacent_fallback(void) { return segmented_growth(0, 1); }

static int test_multiple_adjacent_segments(void)
{
    test_storage storage;
    p2_heap_arena arena;
    size_t segment = HEADER + 64;
    unsigned char *ptr;
    init_arena(&arena, &storage, segment);
    CHECK(p2_heap_add_segment(&arena, storage.raw + segment, segment));
    CHECK(p2_heap_add_segment(&arena, storage.raw + segment * 2, segment));
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 64);
    CHECK(p2_heap_arena_realloc(&arena, ptr, 192 + HEADER * 2) == ptr);
    CHECK(bytes_are(ptr, 64, 0x5a));
    CHECK(arena.head->size == 192 + HEADER * 2);
    CHECK(arena.head->next == NULL);
    CHECK(bytes_are(storage.raw + segment * 3,
        sizeof(storage.raw) - segment * 3, 0xa5));
    p2_heap_arena_free(&arena, ptr);
    CHECK(p2_heap_arena_free_bytes(&arena) == arena.bytes - HEADER);
    return 0;
}

static int test_occupied_next_fallback(void)
{
    test_storage storage;
    p2_heap_arena arena;
    unsigned char *ptr;
    unsigned char *barrier;
    unsigned char *result;
    init_arena(&arena, &storage, 1024);
    ptr = p2_heap_arena_malloc(&arena, 64);
    barrier = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr && barrier);
    memset(ptr, 0x5a, 64);
    memset(barrier, 0xc3, 64);
    result = p2_heap_arena_realloc(&arena, ptr, 256);
    CHECK(result != NULL && result != ptr);
    CHECK(bytes_are(result, 64, 0x5a));
    CHECK(bytes_are(barrier, 64, 0xc3));
    CHECK(arena.head->free);
    p2_heap_arena_free(&arena, barrier);
    p2_heap_arena_free(&arena, result);
    CHECK(arena.head->next == NULL);
    return 0;
}

static int test_failed_growth_preserves_state(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    void *ptr;
    init_arena(&arena, &storage, 256);
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 64);
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    CHECK(p2_heap_arena_realloc(&arena, ptr, 512) == NULL);
    CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    CHECK(p2_heap_arena_owns_payload(&arena, ptr));
    CHECK(p2_heap_arena_realloc(&arena, ptr, 128) == ptr);
    CHECK(bytes_are(ptr, 64, 0x5a));
    return 0;
}

static int test_exact_capacity(void)
{
    test_storage storage;
    p2_heap_arena arena;
    void *ptr;
    size_t capacity = 1024 - HEADER;
    init_arena(&arena, &storage, 1024);
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    CHECK(p2_heap_arena_realloc(&arena, ptr, capacity) == ptr);
    CHECK(arena.head->size == capacity && arena.head->next == NULL);
    CHECK(p2_heap_arena_malloc(&arena, 1) == NULL);
    p2_heap_arena_free(&arena, ptr);
    CHECK(p2_heap_arena_free_bytes(&arena) == capacity);
    return 0;
}

static int test_shrink_coalesces(void)
{
    test_storage storage;
    p2_heap_arena arena;
    unsigned char *ptr;
    init_arena(&arena, &storage, 1024);
    ptr = p2_heap_arena_malloc(&arena, 256);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 256);
    CHECK(p2_heap_arena_realloc(&arena, ptr, 64) == ptr);
    CHECK(bytes_are(ptr, 64, 0x5a));
    CHECK(arena.head->next != NULL);
    CHECK(arena.head->next->next == NULL);
    CHECK(p2_heap_arena_realloc(&arena, ptr, 800) == ptr);
    return 0;
}

static int test_oversized_split_noop(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    init_arena(&arena, &storage, HEADER + 64);
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    p2_heap_split(arena.head, 96);
    CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    return 0;
}

static int test_malloc_overflow(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    size_t delta;
    init_arena(&arena, &storage, 1024);
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    for (delta = 0; delta < 32; ++delta) {
        CHECK(p2_heap_arena_malloc(&arena, MAX_SIZE - delta) == NULL);
        CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    }
    CHECK(p2_heap_arena_malloc(&arena, MAX_SIZE / 2 + 1) == NULL);
    CHECK(p2_heap_arena_malloc(&arena, (size_t)UINT32_MAX) == NULL);
    return 0;
}

static int test_realloc_overflow(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    void *ptr;
    size_t delta;
    init_arena(&arena, &storage, 1024);
    ptr = p2_heap_arena_malloc(&arena, 64);
    CHECK(ptr != NULL);
    memset(ptr, 0x5a, 64);
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    for (delta = 0; delta < 32; ++delta) {
        CHECK(p2_heap_arena_realloc(&arena, ptr, MAX_SIZE - delta) == NULL);
        CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    }
    CHECK(p2_heap_arena_realloc(&arena, ptr, MAX_SIZE / 2 + 1) == NULL);
    CHECK(bytes_are(ptr, 64, 0x5a));
    p2_heap_arena_free(&arena, ptr);
    CHECK(p2_heap_arena_free_bytes(&arena) == 1024 - HEADER);
    return 0;
}

static int test_overflow_before_lazy_init(void)
{
    test_storage storage;
    p2_heap_arena arena = {0};
    p2_heap_arena snapshot;
    memset(storage.raw, 0xa5, sizeof(storage.raw));
    arena.raw = storage.raw;
    arena.bytes = 1024;
    memcpy(&snapshot, &arena, sizeof(arena));
    CHECK(p2_heap_arena_malloc(&arena, MAX_SIZE) == NULL);
    CHECK(memcmp(&arena, &snapshot, sizeof(arena)) == 0);
    CHECK(bytes_are(storage.raw, sizeof(storage.raw), 0xa5));
    return 0;
}

static int test_segment_address_overflow(void)
{
    test_storage storage;
    p2_heap_arena arena = {0};
    p2_heap_arena snapshot;
    size_t overflowing_bytes = (size_t)(MAX_ADDRESS - (uintptr_t)storage.raw) + 1;
    memset(storage.raw, 0xa5, sizeof(storage.raw));
    memcpy(&snapshot, &arena, sizeof(arena));
    CHECK(!p2_heap_add_segment(&arena, storage.raw, overflowing_bytes));
    CHECK(memcmp(&arena, &snapshot, sizeof(arena)) == 0);
    CHECK(bytes_are(storage.raw, sizeof(storage.raw), 0xa5));
    return 0;
}

static int test_segment_alignment_overflow(void)
{
    p2_heap_arena arena = {0};
    /* Invalid numerical address must be rejected BEFORE any dereference. */
    CHECK(!p2_heap_add_segment(&arena, (unsigned char *)(MAX_ADDRESS - 3), 128));
    CHECK(arena.head == NULL && arena.bytes == 0);
    return 0;
}

static int test_segment_total_overflow(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    p2_heap_arena saved;
    init_arena(&arena, &storage, 128);
    arena.bytes = MAX_SIZE - 63;
    memcpy(&saved, &arena, sizeof(arena));
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    CHECK(!p2_heap_add_segment(&arena, storage.raw + 512, 128));
    CHECK(memcmp(&saved, &arena, sizeof(arena)) == 0);
    CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    return 0;
}

static int test_segment_count_overflow(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    init_arena(&arena, &storage, 128);
    arena.segments = INT_MAX;
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    CHECK(!p2_heap_add_segment(&arena, storage.raw + 512, 128));
    CHECK(arena.segments == INT_MAX);
    CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    return 0;
}

static int test_segment_null(void)
{
    p2_heap_arena arena = {0};
    CHECK(!p2_heap_add_segment(&arena, NULL, 128));
    CHECK(arena.head == NULL);
    return 0;
}

static int test_segment_small_and_unaligned(void)
{
    test_storage storage;
    p2_heap_arena arena = {0};
    unsigned char *ptr;
    memset(storage.raw, 0xa5, sizeof(storage.raw));
    CHECK(!p2_heap_add_segment(&arena, storage.raw + 1, HEADER + 7));
    CHECK(bytes_are(storage.raw, sizeof(storage.raw), 0xa5));
    CHECK(p2_heap_add_segment(&arena, storage.raw + 1, 255));
    arena.ready = 1;
    ptr = p2_heap_arena_malloc(&arena, 80);
    CHECK(ptr != NULL && (uintptr_t)ptr % P2_HEAP_ALIGN == 0);
    memset(ptr, 0x5a, 80);
    p2_heap_arena_free(&arena, ptr);
    CHECK(bytes_are(storage.raw, 8, 0xa5));
    CHECK(bytes_are(storage.raw + 256, sizeof(storage.raw) - 256, 0xa5));
    return 0;
}

static int test_init_failure_preserves_state(void)
{
    test_storage storage;
    p2_heap_arena arena = {0};
    p2_heap_arena saved;
    memset(storage.raw, 0xa5, sizeof(storage.raw));
    arena.raw = storage.raw;
    arena.bytes = HEADER;
    memcpy(&saved, &arena, sizeof(arena));
    p2_heap_init(&arena);
    CHECK(memcmp(&saved, &arena, sizeof(arena)) == 0);
    CHECK(bytes_are(storage.raw, sizeof(storage.raw), 0xa5));
    return 0;
}

static int test_merge_capacity_overflow(void)
{
    test_storage storage;
    test_storage snapshot;
    p2_heap_arena arena;
    p2_heap_block *next;
    init_arena(&arena, &storage, HEADER + 64);
    CHECK(p2_heap_add_segment(&arena, storage.raw + HEADER + 64, HEADER + 64));
    next = arena.head->next;
    next->size = MAX_SIZE - 31; /* Synthetic invalid metadata, no huge memory. */
    memcpy(snapshot.raw, storage.raw, sizeof(storage.raw));
    p2_heap_merge_next(arena.head);
    CHECK(memcmp(snapshot.raw, storage.raw, sizeof(storage.raw)) == 0);
    return 0;
}

static int test_partition_overflow(void)
{
    test_storage snapshot;
    size_t before;
    size_t delta;
    init_main();
    before = p2_heap_main_free_bytes();
    memcpy(snapshot.raw, p2_main_arena.raw, sizeof(snapshot.raw));
    for (delta = 0; delta < 32; ++delta) {
        CHECK(!p2_heap_vm_partition_create(0, MAX_SIZE - delta));
        CHECK(!p2_heap_vm_partition_ready(0));
        CHECK(p2_heap_vm_partition_bytes(0) == 0);
        CHECK(p2_heap_main_free_bytes() == before);
        CHECK(memcmp(snapshot.raw, p2_main_arena.raw, sizeof(snapshot.raw)) == 0);
    }
    CHECK(p2_heap_vm_partition_create(0, 512));
    CHECK(p2_heap_vm_partition_release(0));
    CHECK(p2_heap_main_free_bytes() == before);
    return 0;
}

static int test_existing_partition_overflow(void)
{
    size_t before;
    init_main();
    CHECK(p2_heap_vm_partition_create(0, 512));
    before = p2_heap_main_free_bytes();
    CHECK(!p2_heap_vm_partition_create(0, MAX_SIZE));
    CHECK(p2_heap_vm_partition_bytes(0) == 512);
    CHECK(p2_heap_main_free_bytes() == before);
    return 0;
}

static int test_partition_lifecycle(void)
{
    size_t before;
    init_main();
    before = p2_heap_main_free_bytes();
    CHECK(!p2_heap_vm_partition_create(-1, 512));
    CHECK(!p2_heap_vm_partition_create(BE_P2_VM_HEAP_MAX_PARTITIONS, 512));
    CHECK(!p2_heap_vm_partition_create(0, HEADER));
    CHECK(!p2_heap_vm_partition_select(0));
    CHECK(p2_heap_vm_partition_create(0, 0));
    CHECK(p2_heap_vm_partition_bytes(0) == p2_heap_vm_partition_size());
    CHECK(p2_heap_vm_partition_create(0, 513)); /* Existing valid slot is idempotent. */
    CHECK(p2_heap_vm_partition_create(1, 513));
    CHECK(p2_heap_vm_partition_total_bytes() == p2_heap_vm_partition_size() + 513);
    CHECK(p2_heap_vm_partition_created_count() == 2);
    CHECK(p2_heap_vm_partition_high_address(1) - p2_heap_vm_partition_low_address(1) == 513);
    CHECK(p2_heap_vm_partition_select(0));
    CHECK(p2_heap_vm_partition_current() == 0);
    CHECK(!p2_heap_vm_partition_release(0));
    p2_heap_vm_partition_clear_current();
    CHECK(p2_heap_vm_partition_current() == -1);
    CHECK(p2_heap_vm_partition_release(0));
    CHECK(p2_heap_vm_partition_release(1));
    CHECK(p2_heap_vm_partition_created_count() == 0);
    CHECK(p2_heap_vm_partition_total_bytes() == 0);
    CHECK(p2_heap_main_free_bytes() == before);
    return 0;
}

static int test_partition_capacity_range(void)
{
    test_storage storage;
    p2_heap_block *block = (p2_heap_block *)storage.raw;
    size_t capacity = MAX_SIZE / p2_heap_vm_partition_size();
    int expected = capacity > (size_t)INT_MAX ? INT_MAX : (int)capacity;
    /* Synthetic diagnostic-only metadata: no allocation or pointer walk. */
    memset(block, 0, sizeof(*block));
    block->size = MAX_SIZE;
    block->free = 1;
    p2_main_arena.head = block;
    p2_main_arena.ready = 1;
    p2_main_arena.bytes = MAX_SIZE;
    CHECK(p2_heap_main_vm_partition_capacity() == expected);
    CHECK(p2_heap_main_vm_partition_free_capacity() == expected);
    return 0;
}

static int test_vm_ownership_and_oom(void)
{
    unsigned char *first;
    unsigned char *second;
    size_t main_free;
    size_t second_free;
    size_t first_capacity;
    init_main();
    CHECK(p2_heap_vm_partition_create(0, 512));
    CHECK(p2_heap_vm_partition_create(1, 512));
    main_free = p2_heap_main_free_bytes();
    test_p2_cog = 1;
    CHECK(p2_heap_vm_partition_select(0));
    first_capacity = p2_heap_free_bytes();
    first = p2_heap_malloc(first_capacity);
    CHECK(first != NULL);
    memset(first, 0x5a, first_capacity);
    CHECK(p2_heap_malloc(1) == NULL);
    CHECK(p2_heap_realloc(first, first_capacity + 8) == NULL);
    CHECK(bytes_are(first, first_capacity, 0x5a));
    test_p2_cog = 2;
    CHECK(p2_heap_vm_partition_select(1));
    second_free = p2_heap_free_bytes();
    p2_heap_free(first);
    CHECK(p2_heap_wrong_free_count() == 1);
    CHECK(p2_heap_realloc(first, 64) == NULL);
    CHECK(p2_heap_wrong_realloc_count() == 1);
    CHECK(p2_heap_free_bytes() == second_free);
    CHECK(bytes_are(first, first_capacity, 0x5a));
    second = p2_heap_malloc(64);
    CHECK(second != NULL);
    memset(second, 0xc3, 64);
    CHECK(p2_heap_main_free_bytes() == main_free);
    CHECK(!p2_heap_vm_partition_release(0)); /* Selected by another host seam ID. */
    p2_heap_free(second);
    p2_heap_vm_partition_clear_current();
    test_p2_cog = 1;
    p2_heap_free(first);
    CHECK(p2_heap_free_bytes() == first_capacity);
    p2_heap_vm_partition_clear_current();
    CHECK(p2_heap_vm_partition_release(0));
    CHECK(p2_heap_vm_partition_release(1));
    return 0;
}

static int test_worker_routing(void)
{
    void *ptr;
    size_t main_free;
    size_t worker_free;
    init_main();
    main_free = p2_heap_main_free_bytes();
    worker_free = p2_heap_worker_free_bytes();
    p2_heap_set_worker_cog(3);
    test_p2_cog = 3;
    ptr = p2_heap_malloc(64);
    CHECK(ptr != NULL);
    CHECK(p2_heap_main_free_bytes() == main_free);
    CHECK(p2_heap_worker_free_bytes() < worker_free);
    p2_heap_free(ptr);
    CHECK(p2_heap_worker_free_bytes() == worker_free);
    test_p2_cog = 8;
    CHECK(!p2_heap_vm_partition_select(0));
    CHECK(p2_heap_vm_partition_current() == -1);
    return 0;
}

#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
static int test_external_chunks(void)
{
    p2_heap_arena arena = {0};
    arena.bytes = 3072;
    p2_heap_alloc_external_arena(&arena);
    CHECK(arena.bytes == 3072 && arena.segments == 3);
    CHECK(backing_calls == 3 && backing_frees == 0);
    CHECK(!p2_heap_external_alloc_failed);
    arena.ready = 1;
    CHECK(p2_heap_arena_malloc(&arena, 512) != NULL);
    return 0;
}

static int test_external_partial_oom(void)
{
    p2_heap_arena arena = {0};
    arena.bytes = 4096;
    backing_limit = 1;
    p2_heap_alloc_external_arena(&arena);
    CHECK(arena.bytes == 1024 && arena.segments == 1);
    CHECK(p2_heap_external_alloc_failed);
    CHECK(backing_calls > 1);
    return 0;
}

static int test_external_request_overflow(void)
{
    p2_heap_arena arena = {0};
    arena.bytes = MAX_SIZE;
    p2_heap_alloc_external_arena(&arena);
    CHECK(backing_calls == 0);
    CHECK(arena.head == NULL && arena.raw == NULL && arena.bytes == MAX_SIZE);
    CHECK(arena.segments == 0 && arena.low_address == 0 && arena.high_address == 0);
    CHECK(p2_heap_external_alloc_failed);
    return 0;
}

static int test_external_window_overflow(void)
{
    CHECK(p2_heap_chunk_crosses_block_window((unsigned char *)(MAX_ADDRESS - 15), 32));
#if BE_P2_PSRAM_BLOCK_BASE > 0
    CHECK(!p2_heap_chunk_crosses_block_window(
        (unsigned char *)((uintptr_t)BE_P2_PSRAM_BLOCK_BASE - 32), 32));
    CHECK(p2_heap_chunk_crosses_block_window(
        (unsigned char *)((uintptr_t)BE_P2_PSRAM_BLOCK_BASE - 32), 33));
    CHECK(p2_heap_allowed_before_block_window(
        (unsigned char *)((uintptr_t)BE_P2_PSRAM_BLOCK_BASE - 33)) == 32);
    CHECK(p2_heap_allowed_before_block_window(
        (unsigned char *)(uintptr_t)BE_P2_PSRAM_BLOCK_BASE) == 0);
#endif
    return 0;
}
#endif

typedef struct test_case {
    const char *name;
    int (*run)(void);
} test_case;

static const test_case cases[] = {
    {"zero_size", test_zero_size},
    {"alignment_split_coalesce", test_alignment_split_coalesce},
    {"adjacent_growth", test_adjacent_growth},
    {"adjacent_segments", test_adjacent_segments},
    {"multiple_adjacent_segments", test_multiple_adjacent_segments},
    {"nonadjacent_failure", test_nonadjacent_failure},
    {"nonadjacent_fallback", test_nonadjacent_fallback},
    {"occupied_next_fallback", test_occupied_next_fallback},
    {"failed_growth_preserves_state", test_failed_growth_preserves_state},
    {"exact_capacity", test_exact_capacity},
    {"shrink_coalesces", test_shrink_coalesces},
    {"oversized_split_noop", test_oversized_split_noop},
    {"malloc_overflow", test_malloc_overflow},
    {"realloc_overflow", test_realloc_overflow},
    {"overflow_before_lazy_init", test_overflow_before_lazy_init},
    {"segment_address_overflow", test_segment_address_overflow},
    {"segment_alignment_overflow", test_segment_alignment_overflow},
    {"segment_total_overflow", test_segment_total_overflow},
    {"segment_count_overflow", test_segment_count_overflow},
    {"segment_null", test_segment_null},
    {"segment_small_and_unaligned", test_segment_small_and_unaligned},
    {"init_failure_preserves_state", test_init_failure_preserves_state},
    {"merge_capacity_overflow", test_merge_capacity_overflow},
    {"partition_overflow", test_partition_overflow},
    {"existing_partition_overflow", test_existing_partition_overflow},
    {"partition_lifecycle", test_partition_lifecycle},
    {"partition_capacity_range", test_partition_capacity_range},
    {"vm_ownership_and_oom", test_vm_ownership_and_oom},
    {"worker_routing", test_worker_routing},
#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
    {"external_chunks", test_external_chunks},
    {"external_partial_oom", test_external_partial_oom},
    {"external_window_overflow", test_external_window_overflow},
    {"external_request_overflow", test_external_request_overflow},
#endif
};

int main(int argc, char **argv)
{
    size_t i;
    if (argc != 2) {
        return 2;
    }
    if (strcmp(argv[1], "--list") == 0) {
        for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
            puts(cases[i].name);
        }
        return 0;
    }
    /* Keep the backing fixture referenced in static-arena warning builds. */
    (void)test_backing_malloc;
    (void)test_backing_free;
    for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        if (strcmp(argv[1], cases[i].name) == 0) {
            int result = cases[i].run();
            if (!result) {
                printf("PASS %s (size_t=%u bits, pointer=%u bits)\n", cases[i].name,
                    (unsigned)(sizeof(size_t) * CHAR_BIT),
                    (unsigned)(sizeof(void *) * CHAR_BIT));
            }
            return result;
        }
    }
    printf("Unknown test: %s\n", argv[1]);
    return 2;
}
