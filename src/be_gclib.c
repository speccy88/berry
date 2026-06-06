/********************************************************************
** Copyright (c) 2018-2020 Guan Wenliang
** This file is part of the Berry default interpreter.
** skiars@qq.com, https://github.com/Skiars/berry
** See Copyright Notice in the LICENSE file or at
** https://github.com/Skiars/berry/blob/master/LICENSE
********************************************************************/
#include "be_object.h"
#include "be_gc.h"

#if defined(BE_P2_TRACE_GC_MODULE) && BE_P2_TRACE_GC_MODULE
extern void p2_serial_puts(const char *s);
#define GC_MODULE_TRACE(_msg) p2_serial_puts(_msg)
#else
#define GC_MODULE_TRACE(_msg) ((void)0)
#endif

#if BE_USE_GC_MODULE

static int m_allocated(bvm *vm)
{
    GC_MODULE_TRACE("[gcmod] allocated entry\n");
    size_t count = be_gc_memcount(vm);
    GC_MODULE_TRACE("[gcmod] allocated count\n");
#if BE_INTGER_TYPE >= 2
    /* bint is 64-bit: can always represent the memory count as int */
    be_pushint(vm, (bint)count);
#else
    /* bint is 32-bit: fall back to real if count >= 2GB */
    if (count < 0x80000000) {
        be_pushint(vm, (bint)count);
    } else {
        be_pushreal(vm, (breal)count);
    }
#endif
    GC_MODULE_TRACE("[gcmod] allocated return\n");
    be_return(vm);
}

static int m_collect(bvm *vm)
{
    GC_MODULE_TRACE("[gcmod] collect start\n");
    be_gc_collect(vm);
    GC_MODULE_TRACE("[gcmod] collect return\n");
    be_return_nil(vm);
}

#if !BE_USE_PRECOMPILED_OBJECT || (defined(BE_P2_CUSTOM_PRECOMPILED_BUILTINS) && BE_P2_CUSTOM_PRECOMPILED_BUILTINS)
be_native_module_attr_table(gc){
    be_native_module_function("allocated", m_allocated),
    be_native_module_function("collect", m_collect)
};

be_define_native_module(gc, NULL);
#else
/* @const_object_info_begin
module gc (scope: global, depend: BE_USE_GC_MODULE) {
    allocated, func(m_allocated)
    collect, func(m_collect)
}
@const_object_info_end */
#include "../generate/be_fixed_gc.h"
#endif

#endif /* BE_USE_SYS_MODULE */
