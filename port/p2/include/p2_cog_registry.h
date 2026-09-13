/* Managed cog identity only. No VM execution or physical cog lifecycle here. */
#ifndef P2_COG_REGISTRY_H
#define P2_COG_REGISTRY_H
#include <stdint.h>

#define P2_COG_HANDLE_BASE 100
#define P2_COG_REGISTRY_SLOTS 4

typedef enum p2_cog_lifecycle {
    P2_COG_FREE, P2_COG_RESERVED, P2_COG_LIVE
} p2_cog_lifecycle;

typedef struct p2_cog_identity {
    p2_cog_lifecycle state;
    uint32_t token;
    uint32_t owner; /* zero means dead, never an authorization */
} p2_cog_identity;

typedef struct p2_cog_registry {
    p2_cog_identity slots[P2_COG_REGISTRY_SLOTS];
    uint32_t last_token;
    uint32_t last_owner;
} p2_cog_registry;

#define P2_COG_REGISTRY_INITIALIZER { { { P2_COG_FREE, 0, 0 } }, P2_COG_HANDLE_BASE, 0 }
enum {
    P2_COG_OK = 0,
    P2_COG_FULL = -1,
    P2_COG_TOKEN_EXHAUSTED = -2,
    P2_COG_OWNER_EXHAUSTED = -3,
    P2_COG_INVALID_OWNER = -4
};

/* All registry operations are caller-serialized. No allocation, callbacks,
 * hardware access, or hidden locking. Initialize ONCE per boot, never reset a
 * used registry: even reservations for failed starts permanently burn tokens. */
int p2_cog_registry_new_owner(p2_cog_registry *registry, uint32_t *owner);
int p2_cog_registry_reserve(p2_cog_registry *registry, uint32_t owner, uint32_t *token);
int p2_cog_registry_publish(p2_cog_registry *registry, int slot, uint32_t token);
int p2_cog_registry_lookup(const p2_cog_registry *registry, uint32_t owner, int64_t token);
int p2_cog_registry_owned_live(const p2_cog_registry *registry, uint32_t owner, int slot);
/* LIVE -> RESERVED hides a job during physical cleanup; prevents GC/reentry
 * from inspecting or recycling it. Release only AFTER physical cleanup. */
int p2_cog_registry_claim(p2_cog_registry *registry, uint32_t owner, int slot, uint32_t token);
int p2_cog_registry_release(p2_cog_registry *registry, int slot, uint32_t token);
/* Native-only deletion: mark ownership dead, retain storage/resources. F3
 * orphan-running shutdown remains a separate, unfinished liveness gate. */
void p2_cog_registry_invalidate_owner(p2_cog_registry *registry, uint32_t owner);

/* Shared P2 metadata lock. Startup MUST run on the primary cog before user
 * cogs. enter fails closed if startup failed/was omitted; never lazy-init. */
int p2_cog_registry_startup(void);
int p2_cog_registry_enter(void);
void p2_cog_registry_leave(void);
#endif
