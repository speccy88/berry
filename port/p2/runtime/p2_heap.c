#include "berry_conf_p2.h"
#include "p2_heap.h"

#include <stdint.h>
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
} p2_heap_arena;

static union {
    unsigned char raw[BE_P2_HEAP_BYTES];
    uint64_t align;
} p2_heap_storage;
static union {
    unsigned char raw[BE_P2_WORKER_HEAP_BYTES];
    uint64_t align;
} p2_worker_heap_storage;
static p2_heap_arena p2_main_arena = {
    NULL,
    0,
    p2_heap_storage.raw,
    BE_P2_HEAP_BYTES
};
static p2_heap_arena p2_worker_arena = {
    NULL,
    0,
    p2_worker_heap_storage.raw,
    BE_P2_WORKER_HEAP_BYTES
};
static volatile int p2_worker_heap_cog = -1;

static size_t p2_heap_align(size_t size)
{
    return (size + (P2_HEAP_ALIGN - 1u)) & ~(size_t)(P2_HEAP_ALIGN - 1u);
}

static p2_heap_arena *p2_heap_current(void)
{
    int cog = _cogid();
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

    {
        uintptr_t start = (uintptr_t)arena->raw;
        uintptr_t aligned = (start + (P2_HEAP_ALIGN - 1u)) & ~(uintptr_t)(P2_HEAP_ALIGN - 1u);
        size_t offset = (size_t)(aligned - start);

        if (offset + sizeof(p2_heap_block) >= arena->bytes) {
            return;
        }

        arena->head = (p2_heap_block *)aligned;
        arena->head->size = arena->bytes - offset - sizeof(p2_heap_block);
    }
    arena->head->next = NULL;
    arena->head->prev = NULL;
    arena->head->free = 1;
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

void *p2_heap_malloc(size_t size)
{
    p2_heap_arena *arena = p2_heap_current();
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

void p2_heap_free(void *ptr)
{
    p2_heap_arena *arena = p2_heap_current();
    p2_heap_block *block;

    if (!ptr) {
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

void *p2_heap_realloc(void *ptr, size_t size)
{
    p2_heap_arena *arena = p2_heap_current();
    p2_heap_block *block;
    void *newptr;

    if (!ptr) {
        return p2_heap_malloc(size);
    }
    if (size == 0) {
        p2_heap_free(ptr);
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

    newptr = p2_heap_malloc(size);
    if (!newptr) {
        return NULL;
    }

    memcpy(newptr, ptr, block->size);
    p2_heap_free(ptr);
    return newptr;
}

void p2_heap_set_worker_cog(int cog)
{
    p2_worker_heap_cog = cog;
}

void *p2_heap_worker_base(void)
{
    return p2_worker_heap_storage.raw;
}

size_t p2_heap_worker_size(void)
{
    return (size_t)BE_P2_WORKER_HEAP_BYTES;
}
