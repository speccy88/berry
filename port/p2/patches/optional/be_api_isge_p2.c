/* Split from src/be_api.c to avoid a Windows FlexC crash near EOF. */
#include "be_vm.h"

BERRY_API bbool be_isge(bvm *vm)
{
    be_assert(vm->reg + 2 <= vm->top);
    return be_vm_isge(vm, vm->top - 2, vm->top - 1);
}
