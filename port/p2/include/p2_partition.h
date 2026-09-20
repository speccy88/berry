#ifndef P2_PARTITION_H
#define P2_PARTITION_H
#include <stddef.h>
/* Explicit Hub control; no cached global publication or implicit cog selector.
 * Storage is zeroed once, remains at the same Hub address until reset, and is
 * passed via the native cog bootstrap. Tickets are never republished/reused. */
typedef struct p2_partition p2_partition;
enum { P2_PARTITION_NEW, P2_PARTITION_RESERVED, P2_PARTITION_OFFERED,
       P2_PARTITION_ACTIVE, P2_PARTITION_RETIRED };
/* Pinned P2_EDGE LARGE, default CACHED/LUT: 2^(13-8). The worker launcher
 * uses offset_width=5 too. Other cache configurations are not admitted. */
#define P2_PARTITION_CACHE_LINE_BYTES 32u
size_t p2_partition_storage_size(void);
#define P2_PARTITION_HUB_API 1
/* Cog 0 supplies separately allocated, exclusive Hub backing and Hub control.
 * Both stay alive/quarantined until reset. No SDK allocation/free is performed
 * here or by the consumer. Backing is 8-byte aligned, size a multiple of 8;
 * claim/offer/cancel/retire and allocator ownership are identical to PSRAM. */
int p2_partition_reserve_hub(p2_partition *p, unsigned generation, void *backing,
    size_t bytes, int control_lock, int execution_lock);
int p2_partition_is_hub(p2_partition *p, unsigned generation);
int p2_partition_reserve(p2_partition *p, unsigned generation, size_t bytes,
    unsigned cache_line_bytes, int control_lock, int execution_lock);
int p2_partition_offer(p2_partition *p, unsigned generation, int consumer_cog);
/* -1 means producer has not offered yet; 0 refused; 1 is sole-owner admission. */
int p2_partition_claim(p2_partition *p, unsigned generation);
/* Refuses ACTIVE: live VM cancellation and join remain separate gates. */
int p2_partition_cancel(p2_partition *p, unsigned generation);
int p2_partition_is_retired(p2_partition *p, unsigned generation);
size_t p2_partition_low_address(p2_partition *p, unsigned generation);
int p2_partition_retire(p2_partition *p, unsigned generation);
int p2_partition_execution_lock(p2_partition *p, unsigned generation);
void *p2_partition_realloc(void *context, void *ptr, size_t size);
size_t p2_partition_free_bytes(p2_partition *p, unsigned generation);
size_t p2_partition_rejections(p2_partition *p, unsigned generation);
#endif
