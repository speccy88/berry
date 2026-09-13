#include "p2_cog_registry.h"
#include <prop2.h>

static volatile int registry_lock = -1;

int p2_cog_registry_startup(void)
{
    /* Primary startup only. Do not reset identities on repeated initialization. */
    if (registry_lock < 0) registry_lock = _locknew();
    return registry_lock >= 0;
}

int p2_cog_registry_enter(void)
{
    int lock = registry_lock;
    if (lock < 0) return 0;
    while (!_locktry(lock)) {
    }
    return 1;
}

void p2_cog_registry_leave(void)
{
    _lockrel(registry_lock);
}

static int valid_slot(int slot)
{
    return slot >= 0 && slot < P2_COG_REGISTRY_SLOTS;
}

int p2_cog_registry_new_owner(p2_cog_registry *r, uint32_t *owner)
{
    if (r->last_owner == UINT32_MAX) return P2_COG_OWNER_EXHAUSTED;
    *owner = ++r->last_owner;
    return P2_COG_OK;
}

int p2_cog_registry_reserve(p2_cog_registry *r, uint32_t owner, uint32_t *token)
{
    int i;
    if (!owner) return P2_COG_INVALID_OWNER;
    if (r->last_token >= INT32_MAX) return P2_COG_TOKEN_EXHAUSTED;
    for (i = 0; i < P2_COG_REGISTRY_SLOTS; ++i) {
        p2_cog_identity *id = &r->slots[i];
        if (id->state == P2_COG_FREE) {
            id->token = ++r->last_token;
            id->owner = owner;
            id->state = P2_COG_RESERVED;
            *token = id->token;
            return i;
        }
    }
    return P2_COG_FULL;
}

int p2_cog_registry_publish(p2_cog_registry *r, int slot, uint32_t token)
{
    p2_cog_identity *id;
    if (!valid_slot(slot)) return 0;
    id = &r->slots[slot];
    if (id->state != P2_COG_RESERVED || !id->owner || id->token != token) return 0;
    id->state = P2_COG_LIVE;
    return 1;
}

int p2_cog_registry_owned_live(const p2_cog_registry *r, uint32_t owner, int slot)
{
    return owner && valid_slot(slot) && r->slots[slot].state == P2_COG_LIVE &&
        r->slots[slot].owner == owner;
}

int p2_cog_registry_lookup(const p2_cog_registry *r, uint32_t owner, int64_t token)
{
    int i;
    /* Check full signed input before any narrowing; never subtract the base. */
    if (!owner || token <= P2_COG_HANDLE_BASE || token > INT32_MAX) return -1;
    for (i = 0; i < P2_COG_REGISTRY_SLOTS; ++i) {
        if (p2_cog_registry_owned_live(r, owner, i) && r->slots[i].token == (uint32_t)token)
            return i;
    }
    return -1;
}

int p2_cog_registry_claim(p2_cog_registry *r, uint32_t owner, int slot, uint32_t token)
{
    if (!p2_cog_registry_owned_live(r, owner, slot) || r->slots[slot].token != token) return 0;
    r->slots[slot].state = P2_COG_RESERVED;
    return 1;
}

int p2_cog_registry_release(p2_cog_registry *r, int slot, uint32_t token)
{
    p2_cog_identity *id;
    if (!valid_slot(slot)) return 0;
    id = &r->slots[slot];
    if (id->state != P2_COG_RESERVED || id->token != token) return 0;
    id->owner = 0;
    id->token = 0;
    id->state = P2_COG_FREE;
    return 1;
}

void p2_cog_registry_invalidate_owner(p2_cog_registry *r, uint32_t owner)
{
    int i;
    if (!owner) return;
    for (i = 0; i < P2_COG_REGISTRY_SLOTS; ++i) {
        if (r->slots[i].owner == owner) r->slots[i].owner = 0;
    }
}
