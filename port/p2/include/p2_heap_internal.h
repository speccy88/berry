#ifndef P2_HEAP_INTERNAL_H
#define P2_HEAP_INTERNAL_H
#include <stddef.h>
/* Internal single-owner arena operations; never publish these through XMM globals. */
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

void p2_heap_arena_initialize(p2_heap_arena *arena, unsigned char *raw, size_t bytes);
void *p2_heap_arena_malloc(p2_heap_arena *arena, size_t size);
void *p2_heap_arena_realloc(p2_heap_arena *arena, void *ptr, size_t size);
size_t p2_heap_arena_free_bytes(p2_heap_arena *arena);
int p2_heap_arena_owns_payload(p2_heap_arena *arena, void *ptr);
/* Cog 0, startup only, before any ordinary main allocation. Never free/reuse
 * these quarantined regions. Parent initializes only headers outside them. */
unsigned char *p2_heap_reserve_private(size_t bytes, size_t cache_line_bytes);
#endif
