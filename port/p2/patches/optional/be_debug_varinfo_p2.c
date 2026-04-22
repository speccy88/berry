/* Split from src/be_debug.c to avoid a Windows FlexC crash near EOF. */
#include "be_debug.h"
#include "be_vm.h"
#include "be_func.h"
#include "be_vector.h"

#if BE_DEBUG_VAR_INFO
static binstruction* callstack_fixip(bvm *vm, int level)
{
    bcallframe *top = (bcallframe*)be_stack_top(&vm->callstack);
    bcallframe *cf = top - level + 2;
    for (; cf <= top && cf->status & PRIM_FUNC; ++cf);
    return cf <= top ? cf->ip : vm->ip;
}

bbool be_debug_varname(bvm *vm, int level, int index)
{
    int depth = be_stack_count(&vm->callstack);
    if (level > 0 && level <= depth) {
        bcallframe *cf = be_vector_at(&vm->callstack, depth - level);
        if ((cf->status & PRIM_FUNC) == 0) {
            bproto *proto = cast(bclosure*, var_toobj(cf->func))->proto;
            int pc = (int)(callstack_fixip(vm, level) - proto->code);
            bstring *name = be_func_varname(proto, index, pc);
            if (name) {
                bvalue *reg = be_incrtop(vm);
                var_setstr(reg, name);
                return btrue;
            }
        }
    }
    return bfalse;
}

bbool be_debug_upvname(bvm *vm, int level, int index)
{
    int depth = be_stack_count(&vm->callstack);
    if (level > 0 && level <= depth) {
        bcallframe *cf = be_vector_at(&vm->callstack, depth - level);
        if ((cf->status & PRIM_FUNC) == 0) {
            bproto *proto = cast(bclosure*, var_toobj(cf->func))->proto;
            if (index >= 0 && index < proto->nupvals) {
                bvalue *reg = be_incrtop(vm);
                var_setstr(reg, proto->upvals[index].name);
                return btrue;
            }
        }
    }
    return bfalse;
}
#endif
