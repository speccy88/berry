CFLAGS      = -Wall -Wextra -std=c99 -pedantic-errors -O2
DEBUG_FLAGS = -O0 -g -DBE_DEBUG
TEST_FLAGS  = $(DEBUG_FLAGS) --coverage -fno-omit-frame-pointer -fsanitize=address -fsanitize=undefined
LIBS        = -lm
TARGET      = berry
CC          = gcc
MKDIR       = mkdir
LFLAGS      =
PREFIX      = /usr/local
BINDIR      = $(PREFIX)/bin

INCPATH     = src default
SRCPATH     = src default
GENERATE    = generate
CONFIG      = default/berry_conf.h
COC         = tools/coc/coc
CONST_TAB   = $(GENERATE)/be_const_strtab.h

include mk/host-detect.mk
include mk/common.mk
include mk/p2.mk
