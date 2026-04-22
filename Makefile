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

P2_FLEXCC   = ../bin/flexcc.mac
P2_PORTDIR  = port/p2
P2_BUILDDIR = build
P2_OBJDIR   = $(P2_BUILDDIR)/p2obj
P2_TARGET   = $(P2_BUILDDIR)/berry_p2.binary
P2_CONFIG   = $(P2_PORTDIR)/berry_conf_p2.h
P2_COC      = python3 $(COC)
P2_INCFLAGS = -I"$(P2_PORTDIR)" -I"src"
P2_CFLAGS   = -2 -O1 --fcache=0
P2_SRCS     = \
	src/be_api.c \
	src/be_baselib.c \
	src/be_class.c \
	src/be_code.c \
	src/be_debug.c \
	src/be_exec.c \
	src/be_func.c \
	src/be_gc.c \
	src/be_lexer.c \
	src/be_list.c \
	src/be_listlib.c \
	src/be_map.c \
	src/be_maplib.c \
	src/be_mem.c \
	src/be_module.c \
	src/be_object.c \
	src/be_parser.c \
	src/be_rangelib.c \
	src/be_repl.c \
	src/be_strlib.c \
	src/be_string.c \
	src/be_var.c \
	src/be_vector.c \
	src/be_vm.c \
	$(P2_PORTDIR)/be_libs_p2.c \
	$(P2_PORTDIR)/be_modtab_p2.c \
	$(P2_PORTDIR)/berry_port.c \
	$(P2_PORTDIR)/main_p2.c
P2_OBJS     = $(patsubst %.c,$(P2_OBJDIR)/%.o,$(P2_SRCS))

ifeq ($(OS), Windows_NT) # Windows
    CFLAGS    += -Wno-format # for "%I64d" warning
    LFLAGS    += -Wl,--out-implib,berry.lib # export symbols lib for dll linked
    TARGET    := $(TARGET).exe
    PYTHON    ?= python # only for windows and need python3
    COC       := $(PYTHON) $(COC)
else
    CFLAGS    += -DUSE_READLINE_LIB
    LIBS      += -lreadline -ldl
    OS        := $(shell uname)
    ifeq ($(OS), Linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

ifneq ($(V), 1)
    Q=@
    MSG=@echo
else
    MSG=@true
endif

SRCS     = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.c))
OBJS     = $(patsubst %.c, %.o, $(SRCS))
DEPS     = $(patsubst %.c, %.d, $(SRCS))
INCFLAGS = $(foreach dir, $(INCPATH), -I"$(dir)")

.PHONY : clean
.PHONY : p2_prebuild p2

all: $(TARGET)

debug: CFLAGS += $(DEBUG_FLAGS)
debug: all

test: CFLAGS += $(TEST_FLAGS)
test: LFLAGS += $(TEST_FLAGS)
test: all
	$(MSG) [Run Testcases...]
	$(Q) ./testall.be
	$(Q) $(RM) */*.gcno */*.gcda

$(TARGET): $(OBJS)
	$(MSG) [Linking...]
	$(Q) $(CC) $(OBJS) $(LFLAGS) $(LIBS) -o $@
	$(MSG) done

$(OBJS): %.o: %.c
	$(MSG) [Compile] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

sinclude $(DEPS)

$(OBJS): $(CONST_TAB)

$(CONST_TAB): $(GENERATE) $(SRCS) $(CONFIG)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC)  -o $(GENERATE) $(SRCPATH) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(MSG) done

p2_prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate P2 resources
	$(Q) $(P2_COC) -o $(GENERATE) src $(P2_PORTDIR) -c $(P2_CONFIG)
	$(MSG) done

$(P2_BUILDDIR):
	$(Q) $(MKDIR) $(P2_BUILDDIR)

$(P2_OBJDIR):
	$(Q) $(MKDIR) $(P2_OBJDIR)

$(P2_OBJDIR)/%.o: %.c | $(P2_OBJDIR)
	$(MSG) [P2 CC] $<
	$(Q) mkdir -p $(dir $@)
	$(Q) $(P2_FLEXCC) $(P2_CFLAGS) $(P2_INCFLAGS) -c $< -o $@

p2: p2_prebuild $(P2_BUILDDIR) $(P2_OBJS)
	$(MSG) [Build] $(P2_TARGET)
	$(Q) $(P2_FLEXCC) $(P2_CFLAGS) -o $(P2_TARGET) $(P2_OBJS)
	$(MSG) done
	$(MSG) Link command:
	$(MSG) "  $(P2_FLEXCC) $(P2_CFLAGS) -o $(P2_TARGET) $(P2_OBJS)"

clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* berry.lib $(P2_TARGET)
	$(Q) $(RM) -r $(P2_OBJDIR)
	$(MSG) done
