#include "be_libs.h"
#include "be_module.h"
#include "be_string.h"

static void be_cache_builtin_value(bvm *vm, const char *module_name, const char *global_name)
{
    bstring *name = be_newstr(vm, module_name);

    if (be_getglobal(vm, global_name)) {
        be_cache_module(vm, name);
        be_pop(vm, 1);
    }
}

extern void be_load_baselib(bvm *vm);
extern void be_load_listlib(bvm *vm);
extern void be_load_maplib(bvm *vm);
extern void be_load_rangelib(bvm *vm);
extern void be_load_filelib(bvm *vm);
extern void be_load_byteslib(bvm *vm);
extern void be_cache_mathmodule(bvm *vm);
extern void be_cache_stringmodule(bvm *vm);
extern void be_cache_jsonmodule(bvm *vm);
extern void be_cache_osmodule(bvm *vm);
extern void be_cache_i2cmodule(bvm *vm);
extern void be_cache_spimodule(bvm *vm);
void be_loadlibs(bvm *vm)
{
    be_load_baselib(vm);
    be_load_listlib(vm);
    be_load_maplib(vm);
    be_load_rangelib(vm);
    be_load_filelib(vm);
    be_load_byteslib(vm);
    be_cache_builtin_value(vm, "bytes", "bytes");
    be_cache_mathmodule(vm);
    be_cache_stringmodule(vm);
    be_cache_jsonmodule(vm);
    be_cache_osmodule(vm);
    be_cache_i2cmodule(vm);
    be_cache_spimodule(vm);
}
