#include "p2_heap.h"

#include <stdint.h>
#include <string.h>

enum {
    P2_HEAP_ALIGN = 8
};

typedef struct p2_heap_block {
    size_t size;
    struct p2_heap_block *next;
    struct p2_heap_block *prev;
    int free;
} p2_heap_block;

static p2_heap_block *p2_heap_head;
static int p2_heap_ready;
static union {
    unsigned char raw[BE_P2_HEAP_BYTES];
    uint64_t align;
} p2_heap_storage;

static size_t p2_heap_align(size_t size)
{
    return (size + (P2_HEAP_ALIGN - 1u)) & ~(size_t)(P2_HEAP_ALIGN - 1u);
}

static void p2_heap_init(void)
{
    if (p2_heap_ready) {
        return;
    }

    {
        uintptr_t start = (uintptr_t)p2_heap_storage.raw;
        uintptr_t aligned = (start + (P2_HEAP_ALIGN - 1u)) & ~(uintptr_t)(P2_HEAP_ALIGN - 1u);
        size_t offset = (size_t)(aligned - start);

        if (offset + sizeof(p2_heap_block) >= BE_P2_HEAP_BYTES) {
            return;
        }

        p2_heap_head = (p2_heap_block *)aligned;
        p2_heap_head->size = BE_P2_HEAP_BYTES - offset - sizeof(p2_heap_block);
    }
    p2_heap_head->next = NULL;
    p2_heap_head->prev = NULL;
    p2_heap_head->free = 1;
    p2_heap_ready = 1;
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

static p2_heap_block *p2_heap_find(size_t size)
{
    p2_heap_block *block;

    for (block = p2_heap_head; block; block = block->next) {
        if (block->free && block->size >= size) {
            return block;
        }
    }

    return NULL;
}

void *p2_heap_malloc(size_t size)
{
    p2_heap_block *block;

    if (size == 0) {
        return NULL;
    }

    p2_heap_init();
    size = p2_heap_align(size);
    block = p2_heap_find(size);
    if (!block) {
        return NULL;
    }

    p2_heap_split(block, size);
    block->free = 0;
    return block + 1;
}

void p2_heap_free(void *ptr)
{
    p2_heap_block *block;

    if (!ptr) {
        return;
    }

    p2_heap_init();
    block = ((p2_heap_block *)ptr) - 1;
    block->free = 1;

    p2_heap_merge_next(block);
    if (block->prev && block->prev->free) {
        p2_heap_merge_next(block->prev);
    }
}

void *p2_heap_realloc(void *ptr, size_t size)
{
    p2_heap_block *block;
    void *newptr;

    if (!ptr) {
        return p2_heap_malloc(size);
    }
    if (size == 0) {
        p2_heap_free(ptr);
        return NULL;
    }

    p2_heap_init();
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
