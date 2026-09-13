#include "p2_hub_heap.h"

#if defined(__CATALINA_LARGE)
#include <prop2.h>
#include <hmalloc.h>
#include <string.h>

static volatile int hub_heap_lock = -1;

int p2_hub_heap_init(void)
{
    /* Startup is single-cog; do not lazily initialize from concurrent workers. */
    if (hub_heap_lock < 0) {
        hub_heap_lock = _locknew();
    }
    return hub_heap_lock >= 0;
}

void *p2_hub_realloc(void *ptr, size_t size)
{
    void *result;
    int lock = hub_heap_lock;
    if (lock < 0 || (ptr == NULL && size == 0)) {
        return NULL;
    }
    while (!_locktry(lock)) {
    }
    if (size == 0) {
        hub_free(ptr);
        result = NULL;
    } else {
        result = hub_realloc(ptr, size);
    }
    _lockrel(lock);
    return result;
}

void *p2_hub_malloc(size_t size)
{
    return p2_hub_realloc(NULL, size);
}

void p2_hub_free(void *ptr)
{
    if (ptr != NULL) {
        p2_hub_realloc(ptr, 0);
    }
}

void *p2_hub_calloc(size_t count, size_t size)
{
    size_t bytes;
    void *result;
    if (size != 0 && count > (size_t)-1 / size) {
        return NULL;
    }
    bytes = count * size;
    result = p2_hub_realloc(NULL, bytes);
    if (result != NULL) {
        memset(result, 0, bytes);
    }
    return result;
}
#endif
