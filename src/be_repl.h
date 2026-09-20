/********************************************************************
** Copyright (c) 2018-2020 Guan Wenliang
** This file is part of the Berry default interpreter.
** skiars@qq.com, https://github.com/Skiars/berry
** See Copyright Notice in the LICENSE file or at
** https://github.com/Skiars/berry/blob/master/LICENSE
********************************************************************/
#ifndef BE_REPL_H
#define BE_REPL_H

#include "berry.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef char* (*breadline)(const char *prompt);
typedef void (*bfreeline)(char *ptr);

/* A NULL reader result ends this invocation, including an incomplete
 * submission. Each non-NULL line is passed once to freeline (when provided);
 * NULL is never freed. The caller retains ownership of the VM/global state. */
BERRY_API int be_repl(bvm *vm, breadline getline, bfreeline freeline);

#ifdef __cplusplus
}
#endif

#endif
