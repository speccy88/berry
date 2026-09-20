#include "p2_partition.h"
#include "p2_heap_internal.h"
#include <stdint.h>
#include <string.h>
#include <propeller2.h>

/* All cross-cog authority lives here in Hub RAM. The producer alone reserves
 * virgin ranges; the designated consumer alone initializes/walks their headers.
 * No free/reassignment operation exists: retirement quarantines until reset. */
struct p2_partition {
    volatile unsigned generation;
    volatile int state;
    int producer, consumer, control_lock, execution_lock;
    volatile int cancelled;
    unsigned hub_storage;
    unsigned char *base;
    size_t bytes;
    p2_heap_arena arena; /* only the admitted consumer accesses this member */
    size_t live_blocks, rejections;
};

static int control_address(p2_partition *p)
{
    if (!p) return 0;
#if defined(__CATALINA_P2)
    /* LARGE native access dispatches below $80000 to Hub (512 KiB). */
    if ((uintptr_t)p >= 0x80000u || sizeof(*p) > 0x80000u-(uintptr_t)p
            || (uintptr_t)p % sizeof(unsigned long)) return 0;
#endif
    return 1;
}
static int ticket(p2_partition *p, unsigned generation)
{
    return control_address(p) && generation && p->generation == generation
        && p->state != P2_PARTITION_NEW;
}
static int active_owner(p2_partition *p)
{
    return control_address(p) && p->state == P2_PARTITION_ACTIVE
        && p->consumer == _cogid();
}
static void control_enter(p2_partition *p)
{
    while (!_locktry(p->control_lock)) { }
}
static void control_leave(p2_partition *p) { _lockrel(p->control_lock); }

size_t p2_partition_storage_size(void) { return sizeof(p2_partition); }
int p2_partition_reserve_hub(p2_partition *p, unsigned generation, void *backing,
    size_t bytes, int control_lock, int execution_lock)
{
    uintptr_t start = (uintptr_t)backing, control = (uintptr_t)p;
    if (!control_address(p) || _cogid() != 0 || p->state != P2_PARTITION_NEW
            || p->generation || !generation || !backing || start % 8u || bytes % 8u
            || bytes <= sizeof(p2_heap_block) || bytes > (uintptr_t)-1 - start
            || sizeof(*p) > (uintptr_t)-1 - control
            || (start < control + sizeof(*p) && control < start + bytes)
            || control_lock < 0 || control_lock >= 16 || execution_lock < 0
            || execution_lock >= 16 || control_lock == execution_lock) return 0;
#if defined(__CATALINA_P2)
    if (start >= 0x80000u || bytes > 0x80000u - start) return 0;
#endif
    p->producer = _cogid(); p->consumer = -1;
    p->control_lock = control_lock; p->execution_lock = execution_lock;
    p->base = backing; p->bytes = bytes; p->cancelled = 0; p->hub_storage = 1;
    p->live_blocks = 0; p->rejections = 0;
    p->generation = generation;
    p->state = P2_PARTITION_RESERVED;
    return 1;
}
int p2_partition_reserve(p2_partition *p, unsigned generation, size_t bytes,
    unsigned line, int control_lock, int execution_lock)
{
    unsigned char *raw;
    if (!control_address(p) || _cogid() != 0 || p->state != P2_PARTITION_NEW
            || p->generation || !generation || line != P2_PARTITION_CACHE_LINE_BYTES
            || bytes <= sizeof(p2_heap_block) + line || bytes % line
            || control_lock < 0 || control_lock >= 16 || execution_lock < 0
            || execution_lock >= 16 || control_lock == execution_lock) return 0;
    /* Single producer before any ordinary main allocation. The payload is not
     * initialized here: even writing a zero header would leave a dirty line. */
    raw = p2_heap_reserve_private(bytes, line);
    if (!raw) return 0;
    p->producer = _cogid(); p->consumer = -1;
    p->control_lock = control_lock; p->execution_lock = execution_lock;
    p->base = raw; p->bytes = bytes; p->cancelled = 0; p->hub_storage = 0;
    p->live_blocks = 0; p->rejections = 0;
    p->generation = generation;
    p->state = P2_PARTITION_RESERVED;
    return 1;
}
int p2_partition_is_hub(p2_partition *p, unsigned generation)
{
    return ticket(p, generation) && p->hub_storage;
}
int p2_partition_offer(p2_partition *p, unsigned generation, int cog)
{
    int ok;
    if (!ticket(p,generation) || p->producer != _cogid() || cog < 0 || cog >= 8) return 0;
    control_enter(p);
    ok = p->state == P2_PARTITION_RESERVED && !p->cancelled;
    if (ok) { p->consumer = cog; p->state = P2_PARTITION_OFFERED; }
    control_leave(p);
    return ok;
}
int p2_partition_claim(p2_partition *p, unsigned generation)
{
    int result = 0;
    if (!ticket(p,generation)) return 0;
    control_enter(p);
    if (p->state == P2_PARTITION_RESERVED && !p->cancelled) result = -1;
    else if (p->state == P2_PARTITION_OFFERED && !p->cancelled && p->consumer == _cogid()) {
        p2_heap_arena_initialize(&p->arena, p->base, p->bytes);
        if (p->arena.ready) { p->state = P2_PARTITION_ACTIVE; result = 1; }
    }
    control_leave(p);
    return result;
}
int p2_partition_cancel(p2_partition *p, unsigned generation)
{
    int ok;
    if (!ticket(p,generation) || p->producer != _cogid()) return 0;
    control_enter(p);
    /* Admission cancellation only. Live VM cancellation uses its existing
     * cooperative job flag; never revoke an allocator underneath cleanup. */
    ok = p->state == P2_PARTITION_RESERVED || p->state == P2_PARTITION_OFFERED;
    if (ok) { p->cancelled = 1; p->state = P2_PARTITION_RETIRED; }
    control_leave(p);
    return ok;
}
int p2_partition_retire(p2_partition *p, unsigned generation)
{
    int ok;
    if (!ticket(p,generation) || !active_owner(p)) return 0;
    control_enter(p);
    ok = p->live_blocks == 0 && p2_heap_arena_free_bytes(&p->arena) == p->bytes - sizeof(p2_heap_block);
    if (ok) p->state = P2_PARTITION_RETIRED;
    control_leave(p);
    return ok;
}
int p2_partition_execution_lock(p2_partition *p, unsigned generation)
{
    return ticket(p,generation) && active_owner(p) ? p->execution_lock : -1;
}
void *p2_partition_realloc(void *context, void *ptr, size_t size)
{
    p2_partition *p = context;
    void *result;
    if (!active_owner(p)) return NULL; /* NEVER fall back to the main heap. */
    if (ptr && !p2_heap_arena_owns_payload(&p->arena, ptr)) {
        ++p->rejections; return NULL;
    }
    if (ptr && ((p2_heap_block *)ptr - 1)->free) { ++p->rejections; return NULL; }
    result = p2_heap_arena_realloc(&p->arena, ptr, size);
    if (ptr && !size) --p->live_blocks;
    else if (!ptr && result) ++p->live_blocks;
    return result;
}
size_t p2_partition_free_bytes(p2_partition *p, unsigned generation)
{
    return ticket(p,generation) && active_owner(p) ? p2_heap_arena_free_bytes(&p->arena) : 0;
}
size_t p2_partition_rejections(p2_partition *p, unsigned generation)
{
    return ticket(p,generation) && active_owner(p) ? p->rejections : 0;
}

int p2_partition_is_retired(p2_partition *p, unsigned generation)
{
    return ticket(p,generation) && p->state == P2_PARTITION_RETIRED;
}
size_t p2_partition_low_address(p2_partition *p, unsigned generation)
{
    return ticket(p,generation) ? (size_t)(uintptr_t)p->base : 0;
}
