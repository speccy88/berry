#include "berry.h"

/* default modules declare */
#if !BE_P2_OVERRIDE_MATH_STRING_MODULES
be_extern_native_module(string);
#endif
be_extern_native_module(json);
#if !BE_P2_OVERRIDE_MATH_STRING_MODULES
be_extern_native_module(math);
#endif
be_extern_native_module(time);
be_extern_native_module(os);
be_extern_native_module(global);
be_extern_native_module(sys);
be_extern_native_module(debug);
be_extern_native_module(gc);
be_extern_native_module(solidify);
be_extern_native_module(introspect);
be_extern_native_module(strict);
be_extern_native_module(undefined);
be_extern_native_module(task);

BERRY_LOCAL const bntvmodule_t * const be_module_table[] = {
#if BE_USE_STRING_MODULE && !BE_P2_OVERRIDE_MATH_STRING_MODULES
    &be_native_module(string),
#endif
#if BE_USE_JSON_MODULE
    &be_native_module(json),
#endif
#if BE_USE_MATH_MODULE && !BE_P2_OVERRIDE_MATH_STRING_MODULES
    &be_native_module(math),
#endif
#if BE_USE_TIME_MODULE
    &be_native_module(time),
#endif
#if BE_USE_OS_MODULE
    &be_native_module(os),
#endif
#if BE_USE_GLOBAL_MODULE
    &be_native_module(global),
#endif
#if BE_USE_SYS_MODULE
    &be_native_module(sys),
#endif
#if BE_USE_DEBUG_MODULE
    &be_native_module(debug),
#endif
#if BE_USE_GC_MODULE
    &be_native_module(gc),
#endif
#if BE_USE_SOLIDIFY_MODULE
    &be_native_module(solidify),
#endif
#if BE_USE_INTROSPECT_MODULE
    &be_native_module(introspect),
#endif
#if BE_USE_STRICT_MODULE
    &be_native_module(strict),
#endif
    &be_native_module(task),
    &be_native_module(undefined),
    NULL
};

BERRY_LOCAL bclass_array be_class_table = {
    NULL
};
