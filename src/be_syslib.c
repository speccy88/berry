/********************************************************************
** Copyright (c) 2018-2020 Guan Wenliang
** This file is part of the Berry default interpreter.
** skiars@qq.com, https://github.com/Skiars/berry
** See Copyright Notice in the LICENSE file or at
** https://github.com/Skiars/berry/blob/master/LICENSE
********************************************************************/
#include "be_object.h"

#if BE_USE_SYS_MODULE

static int m_path(bvm *vm)
{
    be_getbuiltin(vm, "list");
    be_module_path(vm);
    be_call(vm, 1);
    be_pop(vm, 1);
    be_return(vm);
}

static int m_path_add(bvm *vm)
{
    const char *path;
    if (be_top(vm) < 1 || !be_isstring(vm, 1)) {
        be_raise(vm, "type_error", "path must be a string");
    }
    path = be_tostring(vm, 1);
    if (!path || !path[0]) {
        be_raise(vm, "value_error", "module path is empty");
    }
    be_module_path_set(vm, path);
    be_pushbool(vm, btrue);
    be_return(vm);
}

#if !BE_USE_PRECOMPILED_OBJECT || (defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS)
be_native_module_attr_table(sys){
    be_native_module_function("path", m_path)
    be_native_module_function("path_add", m_path_add)
};

be_define_native_module(sys, NULL);
#else
/* @const_object_info_begin
module sys (scope: global, depend: BE_USE_SYS_MODULE) {
    path, func(m_path)
    path_add, func(m_path_add)
}
@const_object_info_end */
#include "../generate/be_fixed_sys.h"
#endif

#endif /* BE_USE_SYS_MODULE */
