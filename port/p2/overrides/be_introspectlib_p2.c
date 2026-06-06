/********************************************************************
** P2-safe native introspect module for Catalina builds.
**
** The upstream introspect module exposes raw pointer conversion helpers
** that currently trip Catalina/P2 code generation and are not a safe
** default for the P2 memory architecture.  Keep reflection and module
** cache helpers, but make pointer resurrection conservative.
********************************************************************/
#include "be_class.h"
#include "be_exec.h"
#include "be_map.h"
#include "be_module.h"
#include "be_object.h"
#include "be_string.h"
#include "be_vm.h"

#if BE_USE_INTROSPECT_MODULE

#define global(vm)      ((vm)->gbldesc.global)

static void p2_dump_map_keys(bvm *vm, bmap *map)
{
    bmapnode *node;
    bmapiter iter;

    if (!map) {
        return;
    }
    iter = be_map_iter();
    while ((node = be_map_next(map, &iter)) != NULL) {
        if (var_isstr(&node->key)) {
            bstring *s = var_tostr(&node->key);
            be_pushstring(vm, str(s));
            be_data_push(vm, -2);
            be_pop(vm, 1);
        }
    }
}

static int m_attrlist(bvm *vm)
{
    int top = be_top(vm);
    be_newobject(vm, "list");
    if (top >= 1) {
        bvalue *v = be_indexof(vm, 1);
        void *obj = var_toobj(v);
        switch (var_type(v)) {
        case BE_NIL:
            p2_dump_map_keys(vm, global(vm).vtab);
            break;
        case BE_MODULE:
            p2_dump_map_keys(vm, ((bmodule*)obj)->table);
            break;
        case BE_CLASS:
            p2_dump_map_keys(vm, ((bclass*)obj)->members);
            break;
        case BE_INSTANCE:
            p2_dump_map_keys(vm, ((binstance*)obj)->_class->members);
            break;
        default:
            break;
        }
    } else {
        p2_dump_map_keys(vm, global(vm).vtab);
    }
    be_pop(vm, 1);
    be_return(vm);
}

static void m_findmember_protected(bvm *vm, void *data)
{
    be_getmember(vm, 1, (const char*)data);
}

static int m_findmember(bvm *vm)
{
    int top = be_top(vm);
    bbool protected = btrue;

    if (top >= 3) {
        protected = !be_tobool(vm, 3);
    }
    if (top >= 2 && be_isstring(vm, 2)) {
        if (protected) {
            if (be_isinstance(vm, 1) || be_ismodule(vm, 1) || be_isclass(vm, 1)) {
                int ret = be_execprotected(vm, &m_findmember_protected, (void*)be_tostring(vm, 2));
                if (ret == BE_OK) {
                    be_return(vm);
                }
            }
            be_return_nil(vm);
        }
        if (be_getmember(vm, 1, be_tostring(vm, 2))) {
            be_return(vm);
        }
        be_getmodule(vm, "undefined");
        be_return(vm);
    }
    be_return_nil(vm);
}

static int m_contains(bvm *vm)
{
    bbool contains = bfalse;
    int top = be_top(vm);

    if (top >= 2 && be_isstring(vm, 2) &&
        (be_isinstance(vm, 1) || be_ismodule(vm, 1) || be_isclass(vm, 1))) {
        if (be_getmember(vm, 1, be_tostring(vm, 2))) {
            contains = btrue;
        }
    }
    be_pushbool(vm, contains);
    be_return(vm);
}

static int m_setmember(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 3 &&
        (be_isinstance(vm, 1) || be_ismodule(vm, 1) || be_isclass(vm, 1)) &&
        be_isstring(vm, 2)) {
        be_setmember(vm, 1, be_tostring(vm, 2));
        be_return(vm);
    }
    be_return_nil(vm);
}

static int m_toptr(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        if ((be_isint(vm, 1) && be_toint(vm, 1) == 0) || be_isnil(vm, 1)) {
            be_pushcomptr(vm, NULL);
            be_return(vm);
        }
        if (be_iscomptr(vm, 1)) {
            be_pushcomptr(vm, be_tocomptr(vm, 1));
            be_return(vm);
        }
        /*
         * Preserve the public shape of introspect.toptr() on P2 without
         * exposing arbitrary object addresses through Catalina's fragile
         * integer/pointer conversion path.
         */
        be_pushcomptr(vm, NULL);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int m_solidified(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        bvalue *v = be_indexof(vm, 1);
        if (var_basetype(v) >= BE_FUNCTION || var_type(v) == BE_COMPTR) {
            be_pushbool(vm, bfalse);
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

static int m_fromptr(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        if (be_iscomptr(vm, 1) && be_tocomptr(vm, 1) == NULL) {
            be_return_nil(vm);
        }
        if (be_isint(vm, 1) && be_toint(vm, 1) == 0) {
            be_return_nil(vm);
        }
        be_raise(vm, "value_error", "pointer object conversion is disabled on P2");
    }
    be_return_nil(vm);
}

static int m_getmodule(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        bvalue *v = be_indexof(vm, 1);
        if (var_isstr(v)) {
            int ret = be_module_load(vm, var_tostr(v));
            if (ret == BE_OK) {
                be_return(vm);
            }
        }
    }
    be_return_nil(vm);
}

static int m_setmodule(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 2) {
        bvalue *v = be_indexof(vm, 1);
        if (var_isstr(v)) {
            be_pushvalue(vm, 2);
            be_cache_module(vm, var_tostr(v));
        }
    }
    be_return_nil(vm);
}

static int m_ismethod(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        bvalue *v = be_indexof(vm, 1);
        if (var_isclosure(v)) {
            bclosure *cl = var_toobj(v);
            bproto *pr = cl->proto;
            be_pushbool(vm, pr->varg & BE_VA_METHOD);
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

static int m_name(bvm *vm)
{
    int top = be_top(vm);

    if (top >= 1) {
        bvalue *v = be_indexof(vm, 1);
        const char *name = NULL;
        switch (var_type(v)) {
        case BE_CLOSURE:
            name = str(((bclosure*)var_toobj(v))->proto->name);
            break;
        case BE_CLASS:
            name = str(((bclass*)var_toobj(v))->name);
            break;
        case BE_MODULE:
            name = be_module_name(var_toobj(v));
            break;
        default:
            break;
        }
        if (name) {
            be_pushstring(vm, name);
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

#if !BE_USE_PRECOMPILED_OBJECT || (defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS)
be_native_module_attr_table(introspect) {
    be_native_module_function("members", m_attrlist),
    be_native_module_function("get", m_findmember),
    be_native_module_function("set", m_setmember),
    be_native_module_function("contains", m_contains),
    be_native_module_function("module", m_getmodule),
    be_native_module_function("setmodule", m_setmodule),
    be_native_module_function("toptr", m_toptr),
    be_native_module_function("fromptr", m_fromptr),
    be_native_module_function("solidified", m_solidified),
    be_native_module_function("name", m_name),
    be_native_module_function("ismethod", m_ismethod),
};

be_define_native_module(introspect, NULL);
#endif

#endif /* BE_USE_INTROSPECT_MODULE */
