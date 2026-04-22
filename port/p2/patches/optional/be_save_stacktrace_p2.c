/* Split from src/be_exec.c to avoid a Windows FlexC crash near EOF. */
#include "be_exec.h"
#include "be_vm.h"

void be_save_stacktrace(bvm *vm)
{
    bstack *stack = &vm->tracestack;
    be_stack_clear(stack);
    if (be_stack_count(&vm->callstack)) {
        bcallframe *cf;
        bcallframe *base = be_stack_base(&vm->callstack);
        bcallframe *top = be_stack_top(&vm->callstack);
        for (cf = base; cf <= top; ++cf) {
            bcallsnapshot *st;
            be_stack_push(vm, stack, NULL);
            st = be_stack_top(stack);
            st->func = *cf->func;
            st->ip = cf == top ? vm->ip : cf[1].ip;
        }
    }
}
