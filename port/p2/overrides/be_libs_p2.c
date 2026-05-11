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
#if BE_USE_FILE_SYSTEM
extern void be_load_filelib(bvm *vm);
#endif
extern void be_load_byteslib(bvm *vm);
#if BE_USE_MATH_MODULE
extern void be_cache_mathmodule(bvm *vm);
#endif
#if BE_USE_STRING_MODULE
extern void be_cache_stringmodule(bvm *vm);
#endif
#if BE_USE_JSON_MODULE
extern void be_cache_jsonmodule(bvm *vm);
#endif
#if BE_USE_OS_MODULE
extern void be_cache_osmodule(bvm *vm);
#endif
#if BE_P2_USE_P2_MODULE
extern void be_cache_p2module(bvm *vm);
#endif
#if BE_P2_USE_I2C_MODULE
extern void be_cache_i2cmodule(bvm *vm);
#endif
#if BE_P2_USE_SPI_MODULE
extern void be_cache_spimodule(bvm *vm);
#endif
#if BE_P2_USE_RTOS_MODULE
extern void be_cache_rtosmodule(bvm *vm);
#endif
#if BE_P2_USE_THREADS_MODULE
extern void be_cache_threadsmodule(bvm *vm);
#endif
#if BE_P2_USE_SPIN2_MODULE
extern void be_cache_spin2module(bvm *vm);
#endif
#if BE_P2_USE_WORKER_MODULE
extern void be_cache_workermodule(bvm *vm);
#endif
void be_loadlibs(bvm *vm)
{
    be_load_baselib(vm);
    be_load_listlib(vm);
    be_load_maplib(vm);
    be_load_rangelib(vm);
#if BE_USE_FILE_SYSTEM
    be_load_filelib(vm);
#endif
    be_load_byteslib(vm);
    be_cache_builtin_value(vm, "bytes", "bytes");
#if BE_USE_MATH_MODULE
    be_cache_mathmodule(vm);
#endif
#if BE_USE_STRING_MODULE
    be_cache_stringmodule(vm);
#endif
#if BE_USE_JSON_MODULE
    be_cache_jsonmodule(vm);
#endif
#if BE_USE_OS_MODULE
    be_cache_osmodule(vm);
#endif
#if BE_P2_USE_P2_MODULE
    be_cache_p2module(vm);
#endif
#if BE_P2_USE_I2C_MODULE
    be_cache_i2cmodule(vm);
#endif
#if BE_P2_USE_SPI_MODULE
    be_cache_spimodule(vm);
#endif
#if BE_P2_USE_RTOS_MODULE
    be_cache_rtosmodule(vm);
#endif
#if BE_P2_USE_THREADS_MODULE
    be_cache_threadsmodule(vm);
#endif
#if BE_P2_USE_SPIN2_MODULE
    be_cache_spin2module(vm);
#endif
#if BE_P2_USE_WORKER_MODULE
    be_cache_workermodule(vm);
#endif
}
