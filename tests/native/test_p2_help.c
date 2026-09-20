/* Metadata-only fixture modules, actual production help and capability code.
 * Full P2 registration and UART output are tested separately on the board. */
#include "berry.h"
#include "be_module.h"
#include "be_map.h"
#include "be_vm.h"
#include "be_string.h"
#include "p2_cog_registry.h"
#include <stdio.h>
#include <string.h>
#define BE_P2_ENABLE_ROADMAP_NATIVE_FACADES 0
#define BE_P2_ENABLE_UNSAFE_SHARED_VM_COG 0
#include "p2_help.inc"

int main(void)
{
    int rc, top;
    bvm *vm = be_vm_new();
    if (!vm) return 2;
    be_pushstring(vm, "p2");
    be_newmodule(vm);
    be_pushntvfunction(vm, m_p2_help);
    be_setmember(vm, -2, "help");
    be_pop(vm, 1);
    be_newmodule(vm);
    be_pushint(vm, 123);
    be_setmember(vm, -2, "fixture_member");
    be_pop(vm, 1);
    be_setmember(vm, -2, "pin");
    be_pop(vm, 1);
    be_newmodule(vm);
    be_setmember(vm, -2, "cog");
    be_pop(vm, 1);
    be_cache_module(vm, var_tostr(be_indexof(vm, -2)));
    be_pop(vm, 2);
    top = be_top(vm);
    rc = be_loadstring(vm,
        "import p2 import introspect import gc "
        "assert(p2.help()['groups'].size()==2) "
        "assert(p2.help('pin')['members']==['fixture_member']) "
        "assert(!p2.help('cog')['capabilities']['spawn_source']) "
        "introspect.set(p2.pin,'another',456) "
        "assert(p2.help('pin')['members'].size()==2) "
        "for i:0..49 gc.collect() assert(p2.help('pin')['members'].size()==2) end "
        "var n=0 "
        "for v:[nil,42,[],{},true] "
        "try p2.help(v) except 'type_error' n+=1 end end assert(n==5) "
        "for v:['','missing','pin.read','pin\\u0000tail'] "
        "try p2.help(v) except 'value_error' n+=1 end end assert(n==9) "
        "try p2.help('pin','extra') except 'type_error' n+=1 end assert(n==10) "
        "assert(p2.help('p2')['topic']=='p2')");
    if (!rc) rc = be_pcall(vm, 0);
    if (rc) be_dumpexcept(vm);
    else be_pop(vm, 1);
    if (!rc && be_top(vm) != top) rc = 3;
    be_vm_delete(vm);
    printf("production help metadata fixture exit=%d (not P2 registration/HIL)\n", rc);
    return rc;
}
