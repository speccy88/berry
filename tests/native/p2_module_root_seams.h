/* Host-only seams for the production be_cache_p2module body.
 * No GPIO, timer, RNG, bus or cog outcome is simulated. Namespace population
 * supplies real Berry allocation/GC pressure solely to test the cache name's
 * lifetime and the actual interpreter/module-cache import path. */
#include "be_module.h"
#define BE_P2_ENABLE_ROADMAP_NATIVE_FACADES 1

static void root_allocation_pressure(bvm *vm)
{
    unsigned i;
    char name[16];
    be_gc_collect(vm);
    for (i = 0; i < 48; ++i) {
        (void)snprintf(name, sizeof(name), "tt_%02u", i);
        (void)be_newstr(vm, name);
    }
}

static int m_p2_member(bvm *vm)
{
    be_return_nil(vm);
}

static int m_p2_vm_cog_ping(bvm *vm)
{
    (void)vm;
    abort(); /* Never supply a simulated hardware success. */
    return 0;
}
