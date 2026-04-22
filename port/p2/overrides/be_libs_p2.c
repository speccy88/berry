#include "be_libs.h"

extern void be_load_baselib(bvm *vm);

void be_loadlibs(bvm *vm)
{
    be_load_baselib(vm);
}
