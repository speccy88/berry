/********************************************************************
** Copyright (c) 2018-2021 Guan Wenliang & Stephan Hadinger
** This file is part of the Berry default interpreter.
** skiars@qq.com, https://github.com/Skiars/berry
** See Copyright Notice in the LICENSE file or at
** https://github.com/Skiars/berry/blob/master/LICENSE
********************************************************************/
#include "be_object.h"
#include "be_module.h"
#include "be_string.h"
#include "be_vector.h"
#include "be_class.h"
#include "be_debug.h"
#include "be_map.h"
#include "be_vm.h"
#include "be_var.h"
#include "berry.h"
#include <string.h>

#if BE_USE_GLOBAL_MODULE

#define global(vm)      ((vm)->gbldesc.global)

#if defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS
static void global_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}
#endif

static int global_snapshot_value_supported(const bvalue *value)
{
#ifdef BE_P2_PROFILE
    switch (var_type(value)) {
    case BE_NIL:
    case BE_BOOL:
    case BE_INT:
    case BE_REAL:
    case BE_STRING:
    case BE_LIST:
    case BE_MAP:
        return 1;
    default:
        return 0;
    }
#else
    (void)value;
    return 1;
#endif
}

static bvalue* global_direct_desc(bvm *vm, const char *name)
{
    if (name == NULL) {
        return NULL;
    }
    return be_map_findstr(vm, global(vm).vtab, be_newstr(vm, name));
}

static int global_direct_index(bvalue *desc)
{
    if (desc == NULL) {
        return -1;
    }
    return var_toidx(desc);
}

static bvalue* global_direct_value(bvm *vm, const char *name)
{
    int idx = global_direct_index(global_direct_desc(vm, name));
    if (idx >= 0 && idx < be_global_count(vm)) {
        return be_vector_at(&global(vm).vlist, idx);
    }
    return NULL;
}

static void dump_globals(bvm *vm, bmap *map, bmap *dst)
{
    if (!map || !dst) { return; }   /* protect against potential null pointer */
    bmapnode *node;
    bmapiter iter = be_map_iter();
    int remaining = be_map_count(map);
    while (remaining-- > 0 && (node = be_map_next(map, &iter)) != NULL) {
        if (var_isstr(&node->key)) {
            /* check if the global was not undefined/removed */
            int idx = var_toidx(&node->value);
            if (idx >= 0) {     /* the key is present in global, and the index is valid */
                bvalue *src = be_global_var(vm, idx + be_builtin_count(vm));
                if (global_snapshot_value_supported(src)) {
                    bvalue *entry = be_map_insertstr(vm, dst, var_tostr(&node->key), NULL);
                    if (entry) {
                        var_setval(entry, src);
                    }
                }
            }
        }
    }
}

static int m_globals(bvm *vm)
{
    be_newobject(vm, "map");
    dump_globals(vm, global(vm).vtab, var_toobj(vm->top - 1));
    be_pop(vm, 1); /* map backing store */
    be_return(vm);
}

static int m_contains(bvm *vm)
{
    int top = be_top(vm);
    if (top >= 1 && be_isstring(vm, 1)) {
        const char * name = be_tostring(vm, 1);
        int idx = global_direct_index(global_direct_desc(vm, name));
        be_pushbool(vm, idx >= 0);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int m_findglobal(bvm *vm)
{
    int top = be_top(vm);
    if (top >= 1 && be_isstring(vm, 1)) {
        const char * name = be_tostring(vm, 1);
        bvalue *value = global_direct_value(vm, name);
        if (value != NULL) {
            var_setval(vm->top, value);
            ++vm->top;
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

static int m_setglobal(bvm *vm)
{
    int top = be_top(vm);
    if (top >= 2 && be_isstring(vm, 1)) {
        const char * name = be_tostring(vm, 1);
        be_setglobal(vm, name);
    }
    be_return_nil(vm);
}

/* Remove a global variable from global scope */
/* Internally the global name cannot be removed but it's value is replaced with BE_NONE */
/* and global function pretend that BE_NONE is equivalent to the name being absent */
static int m_undef(bvm *vm)
{
    int top = be_top(vm);
    if (top >= 1 && be_isstring(vm, 1)) {
        bvalue *desc = global_direct_desc(vm, be_tostring(vm, 1));
        int idx = global_direct_index(desc);
        if (idx >= 0 && idx < be_global_count(vm)) {
            var_setint(desc, -idx - 2);
            var_setnil((bvalue *)be_vector_at(&global(vm).vlist, idx));
        }
    }
    be_return_nil(vm);
}

#if defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS
void be_cache_globalmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "global");
    be_newmodule(vm);
    be_setname(vm, -1, "global");
    global_module_set_func(vm, "()", m_globals);
    global_module_set_func(vm, "contains", m_contains);
    global_module_set_func(vm, "member", m_findglobal);
    global_module_set_func(vm, "setmember", m_setglobal);
    global_module_set_func(vm, "undef", m_undef);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
#endif

#if !BE_USE_PRECOMPILED_OBJECT || (defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS)
be_native_module_attr_table(global) {
    be_native_module_function("()", m_globals),
    be_native_module_function("contains", m_contains),
    be_native_module_function("member", m_findglobal),
    be_native_module_function("setmember", m_setglobal),
    be_native_module_function("undef", m_undef),
};

be_define_native_module(global, NULL);
#else
/* @const_object_info_begin
module global (scope: global, depend: BE_USE_GLOBAL_MODULE) {
    (), func(m_globals)
    contains, func(m_contains)
    member, func(m_findglobal)
    setmember, func(m_setglobal)
    undef, func(m_undef)
}
@const_object_info_end */
#include "../generate/be_fixed_global.h"
#endif

#endif /* BE_USE_GLOBAL_MODULE */
