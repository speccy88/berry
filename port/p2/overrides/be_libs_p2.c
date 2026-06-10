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

static void be_p2_configure_module_paths(bvm *vm)
{
#if BE_USE_FILE_SYSTEM
    /* P2 keeps optional Berry libraries on SD. The upstream loader searches
     * this path lazily on import, so source modules do not consume Hub image
     * space until a program asks for them.
     *
     * Catalina DOSFS often exposes short FAT names in uppercase on P2, while
     * cards copied from desktop systems are naturally described in lowercase.
     * Register both spellings so users can copy either /modules or /MODULES
     * layouts without having to repair sys.path manually.
     *
     * Berry searches this list from the end toward the beginning. Add lower
     * priority roots first so /MODULES and /modules remain the preferred SD
     * module locations, followed by /berry/lib, then /berry/app.
     */
    be_module_path_set(vm, "/berry/app");
    be_module_path_set(vm, "/BERRY/APP");
    be_module_path_set(vm, "/berry/lib");
    be_module_path_set(vm, "/BERRY/LIB");
    be_module_path_set(vm, "/modules");
    be_module_path_set(vm, "/MODULES");
#else
    (void)vm;
#endif
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
extern void be_cache_taskmodule(bvm *vm);
extern void p2_startup_status_tick(int stage);

static void be_p2_startup_tick(int stage)
{
    p2_startup_status_tick(stage);
}

void be_loadlibs(bvm *vm)
{
    be_p2_startup_tick(20);
    be_load_baselib(vm);
    be_p2_startup_tick(21);
    be_load_listlib(vm);
    be_p2_startup_tick(22);
    be_load_maplib(vm);
    be_p2_startup_tick(23);
    be_load_rangelib(vm);
    be_p2_startup_tick(24);
#if BE_USE_FILE_SYSTEM
    be_load_filelib(vm);
    be_p2_startup_tick(25);
#endif
    be_load_byteslib(vm);
    be_p2_startup_tick(26);
    be_cache_builtin_value(vm, "bytes", "bytes");
    be_p2_startup_tick(27);
#if BE_USE_MATH_MODULE
    be_cache_mathmodule(vm);
    be_p2_startup_tick(28);
#endif
#if BE_USE_STRING_MODULE
    be_cache_stringmodule(vm);
    be_p2_startup_tick(29);
#endif
#if BE_USE_JSON_MODULE
    be_cache_jsonmodule(vm);
    be_p2_startup_tick(30);
#endif
#if BE_USE_OS_MODULE
    be_cache_osmodule(vm);
    be_p2_startup_tick(31);
#endif
#if BE_P2_USE_P2_MODULE
    be_cache_p2module(vm);
    be_p2_startup_tick(32);
#endif
#if BE_P2_USE_I2C_MODULE
    be_cache_i2cmodule(vm);
    be_p2_startup_tick(33);
#endif
#if BE_P2_USE_SPI_MODULE
    be_cache_spimodule(vm);
    be_p2_startup_tick(34);
#endif
#if BE_P2_USE_RTOS_MODULE
    be_cache_rtosmodule(vm);
    be_p2_startup_tick(35);
#endif
#if BE_P2_USE_THREADS_MODULE
    be_cache_threadsmodule(vm);
    be_p2_startup_tick(36);
#endif
#if BE_P2_USE_SPIN2_MODULE
    be_cache_spin2module(vm);
    be_p2_startup_tick(37);
#endif
#if BE_P2_USE_WORKER_MODULE
    be_cache_workermodule(vm);
    be_p2_startup_tick(38);
#endif
    be_cache_taskmodule(vm);
    be_p2_startup_tick(39);
    be_p2_configure_module_paths(vm);
    be_p2_startup_tick(40);
}
