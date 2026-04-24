#ifndef P2_HEAP_H
#define P2_HEAP_H

#include <stddef.h>

#ifndef BE_P2_HEAP_BYTES
#define BE_P2_HEAP_BYTES (8 * 1024)
#endif

#ifndef BE_P2_WORKER_HEAP_BYTES
#define BE_P2_WORKER_HEAP_BYTES (8 * 1024)
#endif

void *p2_heap_malloc(size_t size);
void p2_heap_free(void *ptr);
void *p2_heap_realloc(void *ptr, size_t size);
void p2_heap_set_worker_cog(int cog);
void *p2_heap_worker_base(void);
size_t p2_heap_worker_size(void);

#endif
