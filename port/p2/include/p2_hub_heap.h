#ifndef P2_HUB_HEAP_H
#define P2_HUB_HEAP_H

#include <stddef.h>

/* Initialize once on the main cog before creating VMs or worker cogs.
 * The lock belongs to the shared Hub allocator, not to any one VM.
 */
int p2_hub_heap_init(void);
void *p2_hub_malloc(size_t size);
void p2_hub_free(void *ptr);
void *p2_hub_realloc(void *ptr, size_t size);
void *p2_hub_calloc(size_t count, size_t size);

#endif
