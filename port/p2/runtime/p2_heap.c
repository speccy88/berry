#include "berry_conf_p2.h"
#include "p2_heap.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <propeller2.h>

enum {
    P2_HEAP_ALIGN = 8
};

typedef struct p2_heap_block {
    size_t size;
    struct p2_heap_block *next;
    struct p2_heap_block *prev;
    int free;
} p2_heap_block;

typedef struct p2_heap_arena {
    p2_heap_block *head;
    int ready;
    unsigned char *raw;
    size_t bytes;
    int segments;
    size_t low_address;
    size_t high_address;
} p2_heap_arena;

#ifndef BE_P2_HEAP_STATIC_EXTERNAL_ARENA
#define BE_P2_HEAP_STATIC_EXTERNAL_ARENA 0
#endif

#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
static unsigned char *p2_heap_external_storage;
static size_t p2_heap_external_requested_bytes = BE_P2_HEAP_BYTES;
static int p2_heap_external_alloc_failed;
#else
static union {
    unsigned char raw[BE_P2_HEAP_BYTES];
    uint64_t align;
} p2_heap_storage;
#endif
static union {
    unsigned char raw[BE_P2_WORKER_HEAP_BYTES];
    uint64_t align;
} p2_worker_heap_storage;
static p2_heap_arena p2_main_arena = {
    NULL,
    0,
#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
    NULL,
#else
    p2_heap_storage.raw,
#endif
    BE_P2_HEAP_BYTES,
    0,
    0,
    0
};
static p2_heap_arena p2_worker_arena = {
    NULL,
    0,
    p2_worker_heap_storage.raw,
    BE_P2_WORKER_HEAP_BYTES,
    0,
    0,
    0
};
static volatile int p2_worker_heap_cog = -1;
static p2_heap_arena p2_vm_partition_arena[BE_P2_VM_HEAP_MAX_PARTITIONS];
static p2_heap_arena *p2_heap_cog_arena[8];
static size_t p2_heap_wrong_free_events;
static size_t p2_heap_wrong_realloc_events;

#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
#ifndef BE_P2_EXTERNAL_HEAP_MIN_BYTES
#define BE_P2_EXTERNAL_HEAP_MIN_BYTES (4 * 1024 * 1024)
#endif

#ifndef BE_P2_EXTERNAL_HEAP_STEP_BYTES
#define BE_P2_EXTERNAL_HEAP_STEP_BYTES (512 * 1024)
#endif

#ifndef BE_P2_EXTERNAL_HEAP_CHUNK_BYTES
#define BE_P2_EXTERNAL_HEAP_CHUNK_BYTES (4 * 1024 * 1024)
#endif
#endif

static int p2_heap_add_segment(p2_heap_arena *arena, unsigned char *raw, size_t bytes)
{
    uintptr_t start = (uintptr_t)raw;
    uintptr_t aligned = (start + (P2_HEAP_ALIGN - 1u)) & ~(uintptr_t)(P2_HEAP_ALIGN - 1u);
    uintptr_t end = start + bytes;
    size_t offset = (size_t)(aligned - start);
    p2_heap_block *block;
    p2_heap_block *tail;

    if (offset + sizeof(p2_heap_block) >= bytes) {
        return 0;
    }

    block = (p2_heap_block *)aligned;
    block->size = bytes - offset - sizeof(p2_heap_block);
    block->next = NULL;
    block->prev = NULL;
    block->free = 1;

    if (arena->head == NULL) {
        arena->head = block;
        arena->raw = raw;
    } else {
        for (tail = arena->head; tail->next; tail = tail->next) {
        }
        tail->next = block;
        block->prev = tail;
    }

    arena->bytes += bytes;
    arena->segments += 1;
    if (arena->low_address == 0 || start < (uintptr_t)arena->low_address) {
        arena->low_address = (size_t)start;
    }
    if (end > (uintptr_t)arena->high_address) {
        arena->high_address = (size_t)end;
    }
    return 1;
}

#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
static int p2_heap_chunk_crosses_block_window(unsigned char *ptr, size_t bytes)
{
#if BE_P2_PSRAM_BLOCK_BASE > 0
    uintptr_t start = (uintptr_t)ptr;
    uintptr_t end = start + bytes;

    return start >= (uintptr_t)BE_P2_PSRAM_BLOCK_BASE ||
        end > (uintptr_t)BE_P2_PSRAM_BLOCK_BASE;
#else
    (void)ptr;
    (void)bytes;
    return 0;
#endif
}

static size_t p2_heap_allowed_before_block_window(unsigned char *ptr)
{
#if BE_P2_PSRAM_BLOCK_BASE > 0
    uintptr_t start = (uintptr_t)ptr;

    if (start >= (uintptr_t)BE_P2_PSRAM_BLOCK_BASE) {
        return 0;
    }
    return ((size_t)BE_P2_PSRAM_BLOCK_BASE - (size_t)start) & ~(size_t)(P2_HEAP_ALIGN - 1u);
#else
    (void)ptr;
    return (size_t)-1;
#endif
}

static void p2_heap_alloc_external_arena(p2_heap_arena *arena)
{
    size_t target_bytes = arena->bytes;
    size_t remaining = target_bytes;
    size_t min_bytes = (size_t)BE_P2_EXTERNAL_HEAP_MIN_BYTES;
    size_t step_bytes = (size_t)BE_P2_EXTERNAL_HEAP_STEP_BYTES;
    size_t chunk_bytes = (size_t)BE_P2_EXTERNAL_HEAP_CHUNK_BYTES;

    arena->head = NULL;
    arena->raw = NULL;
    arena->bytes = 0;
    arena->segments = 0;
    arena->low_address = 0;
    arena->high_address = 0;

    if (min_bytes > target_bytes) {
        min_bytes = target_bytes;
    }
    if (step_bytes == 0) {
        step_bytes = P2_HEAP_ALIGN;
    }
    if (chunk_bytes == 0 || chunk_bytes > target_bytes) {
        chunk_bytes = target_bytes;
    }

    p2_heap_external_alloc_failed = 0;
    while (remaining > 0) {
        unsigned char *chunk = NULL;
        size_t want = remaining < chunk_bytes ? remaining : chunk_bytes;

        while (want >= step_bytes) {
            chunk = (unsigned char *)malloc(want);
            if (chunk != NULL && p2_heap_chunk_crosses_block_window(chunk, want)) {
                size_t allowed = p2_heap_allowed_before_block_window(chunk);
                free(chunk);
                chunk = NULL;
                if (allowed < step_bytes) {
                    want = 0;
                    break;
                }
                want = allowed < want ? allowed : want - step_bytes;
                continue;
            }
            if (chunk != NULL) {
                break;
            }
            want -= step_bytes;
        }

        if (chunk == NULL) {
            break;
        }

        if (!p2_heap_add_segment(arena, chunk, want)) {
            free(chunk);
            break;
        }

        remaining -= want;
    }

    if (arena->bytes < min_bytes) {
        p2_heap_external_alloc_failed = 1;
    }
}
#endif

static size_t p2_heap_align(size_t size)
{
    return (size + (P2_HEAP_ALIGN - 1u)) & ~(size_t)(P2_HEAP_ALIGN - 1u);
}

static p2_heap_arena *p2_heap_current(void)
{
    int cog = _cogid();
    if (cog >= 0 && cog < 8 && p2_heap_cog_arena[cog] != NULL) {
        return p2_heap_cog_arena[cog];
    }
    if (cog == p2_worker_heap_cog) {
        return &p2_worker_arena;
    }
    return &p2_main_arena;
}

static void p2_heap_init(p2_heap_arena *arena)
{
    if (arena->ready) {
        return;
    }

#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
    if (arena == &p2_main_arena && arena->raw == NULL) {
        p2_heap_alloc_external_arena(arena);
        if (arena->raw == NULL) {
            return;
        }
        arena->ready = 1;
        return;
    }
#endif

    {
        unsigned char *raw = arena->raw;
        size_t bytes = arena->bytes;

        arena->head = NULL;
        arena->raw = NULL;
        arena->bytes = 0;
        arena->segments = 0;
        arena->low_address = 0;
        arena->high_address = 0;
        if (!p2_heap_add_segment(arena, raw, bytes)) {
            return;
        }
    }
    arena->ready = 1;
}

static void p2_heap_split(p2_heap_block *block, size_t size)
{
    p2_heap_block *next;
    size_t remain;

    remain = block->size - size;
    if (remain <= sizeof(p2_heap_block) + P2_HEAP_ALIGN) {
        return;
    }

    next = (p2_heap_block *)((unsigned char *)(block + 1) + size);
    next->size = remain - sizeof(p2_heap_block);
    next->next = block->next;
    next->prev = block;
    next->free = 1;

    if (next->next) {
        next->next->prev = next;
    }

    block->size = size;
    block->next = next;
}

static void p2_heap_merge_next(p2_heap_block *block)
{
    p2_heap_block *next = block->next;

    if (!next || !next->free) {
        return;
    }
    if ((unsigned char *)(block + 1) + block->size != (unsigned char *)next) {
        return;
    }

    block->size += sizeof(p2_heap_block) + next->size;
    block->next = next->next;
    if (block->next) {
        block->next->prev = block;
    }
}

static p2_heap_block *p2_heap_find(p2_heap_arena *arena, size_t size)
{
    p2_heap_block *block;

    for (block = arena->head; block; block = block->next) {
        if (block->free && block->size >= size) {
            return block;
        }
    }

    return NULL;
}

static int p2_heap_arena_owns_payload(p2_heap_arena *arena, void *ptr)
{
    p2_heap_block *block;

    if (ptr == NULL) {
        return 1;
    }
    p2_heap_init(arena);
    for (block = arena->head; block; block = block->next) {
        if ((void *)(block + 1) == ptr) {
            return 1;
        }
    }
    return 0;
}

static size_t p2_heap_arena_free_bytes(p2_heap_arena *arena)
{
    p2_heap_block *block;
    size_t total = 0;

    p2_heap_init(arena);
    for (block = arena->head; block; block = block->next) {
        if (block->free) {
            total += block->size;
        }
    }
    return total;
}

static void *p2_heap_arena_malloc(p2_heap_arena *arena, size_t size)
{
    p2_heap_block *block;

    if (size == 0) {
        return NULL;
    }

    p2_heap_init(arena);
    size = p2_heap_align(size);
    block = p2_heap_find(arena, size);
    if (!block) {
        return NULL;
    }

    p2_heap_split(block, size);
    block->free = 0;
    return block + 1;
}

void *p2_heap_malloc(size_t size)
{
    return p2_heap_arena_malloc(p2_heap_current(), size);
}

static void p2_heap_arena_free(p2_heap_arena *arena, void *ptr)
{
    p2_heap_block *block;

    if (!ptr) {
        return;
    }
    if (!p2_heap_arena_owns_payload(arena, ptr)) {
        ++p2_heap_wrong_free_events;
        return;
    }

    p2_heap_init(arena);
    block = ((p2_heap_block *)ptr) - 1;
    block->free = 1;

    p2_heap_merge_next(block);
    if (block->prev && block->prev->free) {
        p2_heap_merge_next(block->prev);
    }
}

void p2_heap_free(void *ptr)
{
    p2_heap_arena_free(p2_heap_current(), ptr);
}

static void *p2_heap_arena_realloc(p2_heap_arena *arena, void *ptr, size_t size)
{
    p2_heap_block *block;
    void *newptr;

    if (!ptr) {
        return p2_heap_arena_malloc(arena, size);
    }
    if (size == 0) {
        p2_heap_arena_free(arena, ptr);
        return NULL;
    }
    if (!p2_heap_arena_owns_payload(arena, ptr)) {
        ++p2_heap_wrong_realloc_events;
        return NULL;
    }

    p2_heap_init(arena);
    size = p2_heap_align(size);
    block = ((p2_heap_block *)ptr) - 1;

    if (block->size >= size) {
        p2_heap_split(block, size);
        return ptr;
    }

    if (block->next && block->next->free &&
        block->size + sizeof(p2_heap_block) + block->next->size >= size) {
        p2_heap_merge_next(block);
        p2_heap_split(block, size);
        block->free = 0;
        return ptr;
    }

    newptr = p2_heap_arena_malloc(arena, size);
    if (!newptr) {
        return NULL;
    }

    memcpy(newptr, ptr, block->size);
    p2_heap_arena_free(arena, ptr);
    return newptr;
}

void *p2_heap_realloc(void *ptr, size_t size)
{
    return p2_heap_arena_realloc(p2_heap_current(), ptr, size);
}

size_t p2_heap_free_bytes(void)
{
    return p2_heap_arena_free_bytes(p2_heap_current());
}

size_t p2_heap_main_free_bytes(void)
{
    return p2_heap_arena_free_bytes(&p2_main_arena);
}

size_t p2_heap_worker_free_bytes(void)
{
    return p2_heap_arena_free_bytes(&p2_worker_arena);
}

void p2_heap_set_worker_cog(int cog)
{
    p2_worker_heap_cog = cog;
}

void *p2_heap_main_base(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.raw;
}

size_t p2_heap_main_size(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.ready ? p2_main_arena.bytes : 0u;
}

size_t p2_heap_main_requested_size(void)
{
#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
    return p2_heap_external_requested_bytes;
#else
    return (size_t)BE_P2_HEAP_BYTES;
#endif
}

int p2_heap_main_segments(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.segments;
}

size_t p2_heap_main_low_address(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.low_address;
}

size_t p2_heap_main_high_address(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.high_address;
}

int p2_heap_main_crosses_block_window(void)
{
    p2_heap_init(&p2_main_arena);
#if BE_P2_PSRAM_BLOCK_BASE > 0
    return p2_main_arena.high_address > (size_t)BE_P2_PSRAM_BLOCK_BASE;
#else
    return 0;
#endif
}

int p2_heap_main_ready(void)
{
    p2_heap_init(&p2_main_arena);
    return p2_main_arena.ready;
}

int p2_heap_main_alloc_failed(void)
{
#if BE_P2_HEAP_USES_EXTERNAL_RAM && !BE_P2_HEAP_STATIC_EXTERNAL_ARENA
    p2_heap_init(&p2_main_arena);
    return p2_heap_external_alloc_failed;
#else
    return 0;
#endif
}

size_t p2_heap_vm_partition_size(void)
{
    return (size_t)BE_P2_VM_HEAP_PARTITION_BYTES;
}

int p2_heap_main_vm_partition_capacity(void)
{
    size_t partition_bytes = p2_heap_vm_partition_size();

    if (partition_bytes == 0) {
        return 0;
    }
    return (int)(p2_heap_main_size() / partition_bytes);
}

int p2_heap_main_vm_partition_free_capacity(void)
{
    size_t partition_bytes = p2_heap_vm_partition_size();

    if (partition_bytes == 0) {
        return 0;
    }
    return (int)(p2_heap_main_free_bytes() / partition_bytes);
}

size_t p2_heap_main_vm_partition_remainder(void)
{
    size_t partition_bytes = p2_heap_vm_partition_size();

    if (partition_bytes == 0) {
        return 0;
    }
    return p2_heap_main_size() % partition_bytes;
}

size_t p2_heap_main_vm_partition_free_remainder(void)
{
    size_t partition_bytes = p2_heap_vm_partition_size();

    if (partition_bytes == 0) {
        return 0;
    }
    return p2_heap_main_free_bytes() % partition_bytes;
}

int p2_heap_vm_partition_create(int slot, size_t bytes)
{
    p2_heap_arena *arena;
    unsigned char *raw;

    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    if (bytes == 0) {
        bytes = p2_heap_vm_partition_size();
    }
    if (bytes <= sizeof(p2_heap_block) + P2_HEAP_ALIGN) {
        return 0;
    }

    arena = &p2_vm_partition_arena[slot];
    if (arena->ready || arena->raw != NULL) {
        return arena->ready;
    }

    raw = (unsigned char *)p2_heap_arena_malloc(&p2_main_arena, bytes);
    if (raw == NULL) {
        return 0;
    }

    arena->head = NULL;
    arena->ready = 0;
    arena->raw = raw;
    arena->bytes = bytes;
    arena->segments = 0;
    arena->low_address = 0;
    arena->high_address = 0;
    p2_heap_init(arena);
    return arena->ready;
}

int p2_heap_vm_partition_release(int slot)
{
    p2_heap_arena *arena;
    int cog;

    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }

    arena = &p2_vm_partition_arena[slot];
    for (cog = 0; cog < 8; ++cog) {
        if (p2_heap_cog_arena[cog] == arena) {
            return 0;
        }
    }

    if (arena->raw != NULL) {
        p2_heap_arena_free(&p2_main_arena, arena->raw);
    }
    arena->head = NULL;
    arena->ready = 0;
    arena->raw = NULL;
    arena->bytes = 0;
    arena->segments = 0;
    arena->low_address = 0;
    arena->high_address = 0;
    return 1;
}

int p2_heap_vm_partition_select(int slot)
{
    int cog = _cogid();

    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    if (!p2_vm_partition_arena[slot].ready) {
        return 0;
    }
    if (cog < 0 || cog >= 8) {
        return 0;
    }
    p2_heap_cog_arena[cog] = &p2_vm_partition_arena[slot];
    return 1;
}

void p2_heap_vm_partition_clear_current(void)
{
    int cog = _cogid();

    if (cog >= 0 && cog < 8) {
        p2_heap_cog_arena[cog] = NULL;
    }
}

int p2_heap_vm_partition_current(void)
{
    int cog = _cogid();
    int slot;
    p2_heap_arena *arena;

    if (cog < 0 || cog >= 8) {
        return -1;
    }
    arena = p2_heap_cog_arena[cog];
    if (arena == NULL) {
        return -1;
    }
    for (slot = 0; slot < BE_P2_VM_HEAP_MAX_PARTITIONS; ++slot) {
        if (arena == &p2_vm_partition_arena[slot]) {
            return slot;
        }
    }
    return -1;
}

size_t p2_heap_vm_partition_bytes(int slot)
{
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    return p2_vm_partition_arena[slot].ready ? p2_vm_partition_arena[slot].bytes : 0;
}

size_t p2_heap_vm_partition_free_bytes(int slot)
{
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    if (!p2_vm_partition_arena[slot].ready) {
        return 0;
    }
    return p2_heap_arena_free_bytes(&p2_vm_partition_arena[slot]);
}

int p2_heap_vm_partition_ready(int slot)
{
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    return p2_vm_partition_arena[slot].ready;
}

size_t p2_heap_vm_partition_low_address(int slot)
{
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    return p2_vm_partition_arena[slot].ready ? p2_vm_partition_arena[slot].low_address : 0;
}

size_t p2_heap_vm_partition_high_address(int slot)
{
    if (slot < 0 || slot >= BE_P2_VM_HEAP_MAX_PARTITIONS) {
        return 0;
    }
    return p2_vm_partition_arena[slot].ready ? p2_vm_partition_arena[slot].high_address : 0;
}

int p2_heap_vm_partition_created_count(void)
{
    int slot;
    int count = 0;

    for (slot = 0; slot < BE_P2_VM_HEAP_MAX_PARTITIONS; ++slot) {
        if (p2_vm_partition_arena[slot].ready) {
            ++count;
        }
    }
    return count;
}

size_t p2_heap_vm_partition_total_bytes(void)
{
    int slot;
    size_t total = 0;

    for (slot = 0; slot < BE_P2_VM_HEAP_MAX_PARTITIONS; ++slot) {
        if (p2_vm_partition_arena[slot].ready) {
            total += p2_vm_partition_arena[slot].bytes;
        }
    }
    return total;
}

size_t p2_heap_wrong_free_count(void)
{
    return p2_heap_wrong_free_events;
}

size_t p2_heap_wrong_realloc_count(void)
{
    return p2_heap_wrong_realloc_events;
}

void *p2_heap_worker_base(void)
{
    return p2_worker_heap_storage.raw;
}

size_t p2_heap_worker_size(void)
{
    return (size_t)BE_P2_WORKER_HEAP_BYTES;
}
