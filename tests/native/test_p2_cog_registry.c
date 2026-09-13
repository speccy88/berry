/* Tests the production caller-serialized identity registry, not a model. */
#include "p2_cog_registry.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>

int main(void)
{
    p2_cog_registry r = P2_COG_REGISTRY_INITIALIZER;
    uint32_t a, b, token, nested, next;
    int slot, other;
    assert(p2_cog_registry_new_owner(&r, &a) == P2_COG_OK && a != 0);
    assert(p2_cog_registry_new_owner(&r, &b) == P2_COG_OK && b != a);
    slot = p2_cog_registry_reserve(&r, a, &token);
    assert(slot == 0 && token > P2_COG_HANDLE_BASE);
    assert(p2_cog_registry_lookup(&r, a, token) == -1);
    other = p2_cog_registry_reserve(&r, a, &nested);
    assert(other == 1 && nested > token); /* reentrant setup cannot steal slot */
    assert(!p2_cog_registry_release(&r, slot, nested));
    assert(p2_cog_registry_release(&r, other, nested)); /* failed start burns token */
    assert(!p2_cog_registry_release(&r, other, nested));
    assert(p2_cog_registry_publish(&r, slot, token));
    assert(!p2_cog_registry_publish(&r, slot, token));
    assert(p2_cog_registry_lookup(&r, a, token) == slot);
    assert(p2_cog_registry_lookup(&r, b, token) == -1);
    assert(!p2_cog_registry_claim(&r, b, slot, token));
    assert(!p2_cog_registry_release(&r, slot, token)); /* must claim before cleanup */
    assert(p2_cog_registry_claim(&r, a, slot, token));
    assert(p2_cog_registry_lookup(&r, a, token) == -1);
    assert(p2_cog_registry_release(&r, slot, token));
    assert(p2_cog_registry_reserve(&r, a, &next) == slot && next > nested);
    assert(p2_cog_registry_publish(&r, slot, next));
    assert(p2_cog_registry_lookup(&r, a, token) == -1);
    assert(!p2_cog_registry_claim(&r, a, slot, token));
    assert(p2_cog_registry_lookup(&r, a, INT64_MIN) == -1);
    assert(p2_cog_registry_lookup(&r, a, INT32_MIN) == -1);
    assert(p2_cog_registry_lookup(&r, a, P2_COG_HANDLE_BASE) == -1);
    assert(p2_cog_registry_lookup(&r, a, INT64_MAX) == -1);
    assert(p2_cog_registry_lookup(&r, a, (int64_t)INT32_MAX + 1) == -1);
    p2_cog_registry_invalidate_owner(&r, a);
    p2_cog_registry_invalidate_owner(&r, a);
    assert(p2_cog_registry_lookup(&r, a, next) == -1);
    assert(p2_cog_registry_new_owner(&r, &a) == P2_COG_OK);
    assert(p2_cog_registry_lookup(&r, a, next) == -1);
    /* Test-only boundary positioning; production never resets either counter. */
    r.last_token = INT32_MAX - 1U;
    other = p2_cog_registry_reserve(&r, b, &token);
    assert(other >= 0 && token == INT32_MAX);
    assert(p2_cog_registry_publish(&r, other, token));
    assert(p2_cog_registry_lookup(&r, b, INT32_MAX) == other);
    assert(p2_cog_registry_claim(&r, b, other, token));
    assert(p2_cog_registry_release(&r, other, token));
    assert(p2_cog_registry_reserve(&r, b, &token) == P2_COG_TOKEN_EXHAUSTED);
    assert(p2_cog_registry_reserve(&r, b, &token) == P2_COG_TOKEN_EXHAUSTED);
    assert(r.last_token == INT32_MAX);
    r.last_owner = UINT32_MAX - 1U;
    assert(p2_cog_registry_new_owner(&r, &a) == P2_COG_OK && a == UINT32_MAX);
    assert(p2_cog_registry_new_owner(&r, &a) == P2_COG_OWNER_EXHAUSTED);
    assert(r.last_owner == UINT32_MAX);
    puts("PASS production registry: reservation/publication, reentry, stale/foreign, invalidation, signed bounds, exhaustion, idempotence");
    return 0;
}
