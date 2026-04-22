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

P2_TOOLDIR  ?= tools/flexprop/bin
P2_INCLUDEDIR ?= tools/flexprop/include
P2_COMPILER ?= flexc
P2_CATALINA_ROOT ?= tools/catalina
P2_CATALINA_BINDIR ?= $(P2_CATALINA_ROOT)/bin
P2_CATALINA_INCLUDEDIR ?= $(P2_CATALINA_ROOT)/include
P2_CATALINA_TARGETDIR ?= $(P2_CATALINA_ROOT)/target
P2_CATALINA_LIBDIR ?= $(P2_CATALINA_ROOT)/lib
P2_CATALINA_PLATFORM ?= P2_EVAL
P2_CATALINA_CLIB ?= -lci
P2_CATALINA_SERIAL_LIB ?= -lserial2
P2_CATALINA_MLIB ?= -lm
P2_PORT     ?=
P2_SILICON  ?= latest
P2_PORTDIR  = port/p2
P2_BUILDDIR = build
P2_OBJDIR   = $(P2_BUILDDIR)/p2obj
ifeq ($(P2_COMPILER),catalina)
P2_TARGET   = $(P2_BUILDDIR)/berry_p2.bin
else
P2_TARGET   = $(P2_BUILDDIR)/berry_p2.binary
endif
P2_CATALINA_OUTBASE = $(basename $(P2_TARGET))
P2_CONFIG   = $(P2_PORTDIR)/berry_conf_p2.h
P2_INCFLAGS = -I"$(P2_INCLUDEDIR)" -I"$(P2_PORTDIR)" -I"src"

ifeq ($(P2_SILICON),a)
P2_CODEGEN  = -2a
P2_LOAD_FLAGS_DEFAULT = -SINGLE -t
else ifeq ($(P2_SILICON),latest)
P2_CODEGEN  = -2
P2_LOAD_FLAGS_DEFAULT = -t
else ifeq ($(P2_SILICON),b)
P2_CODEGEN  = -2
P2_LOAD_FLAGS_DEFAULT = -t
else ifeq ($(P2_SILICON),c)
P2_CODEGEN  = -2
P2_LOAD_FLAGS_DEFAULT = -t
else
$(error Unsupported P2_SILICON '$(P2_SILICON)'; use a, b, c, or latest)
endif

P2_LOAD_FLAGS ?= $(P2_LOAD_FLAGS_DEFAULT)
P2_CFLAGS   ?= $(P2_CODEGEN) -O1 --fcache=0
ifeq ($(P2_COMPILER),catalina)
P2_BAUD ?= 230400
else
P2_BAUD ?= 115200
endif
P2_WIN_SPLIT_SRCS = \
	$(P2_PORTDIR)/be_api_p2.c \
	$(P2_PORTDIR)/be_baselib_p2.c \
	$(P2_PORTDIR)/be_class_p2.c \
	$(P2_PORTDIR)/be_class_setmember_p2.c \
	$(P2_PORTDIR)/be_api_isge_p2.c \
	$(P2_PORTDIR)/be_code_p2.c \
	$(P2_PORTDIR)/be_code_implicit_class_p2.c \
	$(P2_PORTDIR)/be_debug_p2.c \
	$(P2_PORTDIR)/be_debug_varinfo_p2.c \
	$(P2_PORTDIR)/be_exec_p2.c \
	$(P2_PORTDIR)/be_save_stacktrace_p2.c

P2_STD_SRCS = \
	src/be_api.c \
	src/be_baselib.c \
	src/be_class.c \
	src/be_code.c \
	src/be_debug.c \
	src/be_exec.c

ifeq ($(P2_COMPILER),catalina)
P2_FRONT_SRCS = $(P2_STD_SRCS)
else ifeq ($(OS), Windows_NT)
P2_FRONT_SRCS = $(P2_WIN_SPLIT_SRCS)
else
P2_FRONT_SRCS = $(P2_STD_SRCS)
endif

P2_SRCS     = \
	$(P2_FRONT_SRCS) \
	src/be_func.c \
	src/be_gc.c \
	src/be_lexer.c \
	src/be_list.c \
	src/be_map.c \
	src/be_mem.c \
	src/be_module.c \
	src/be_object.c \
	src/be_parser.c \
	src/be_repl.c \
	src/be_strlib.c \
	src/be_string.c \
	src/be_var.c \
	src/be_vector.c \
	src/be_vm.c \
	$(P2_PORTDIR)/be_libs_p2.c \
	$(P2_PORTDIR)/be_modtab_p2.c \
	$(P2_PORTDIR)/berry_port.c \
	$(P2_PORTDIR)/p2_heap.c \
	$(P2_PORTDIR)/p2_smartserial.c \
	$(P2_PORTDIR)/main_p2.c
P2_OBJS     = $(patsubst %.c,$(P2_OBJDIR)/%.o,$(P2_SRCS))

ifeq ($(OS), Windows_NT) # Windows
    CFLAGS    += -Wno-format # for "%I64d" warning
    LFLAGS    += -Wl,--out-implib,berry.lib # export symbols lib for dll linked
    TARGET    := $(TARGET).exe
    PYTHON    ?= py -3
    P2_FLEXCC ?= $(P2_TOOLDIR)/flexcc.exe
    P2_LOADP2 ?= $(P2_TOOLDIR)/loadp2.exe
else
    PYTHON    ?= python3
    P2_FLEXCC ?= $(P2_TOOLDIR)/flexcc.mac
    P2_LOADP2 ?= $(P2_TOOLDIR)/loadp2.mac
    CFLAGS    += -DUSE_READLINE_LIB
    LIBS      += -lreadline -ldl
    OS        := $(shell uname)
    ifeq ($(OS), Linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

define P2_MKDIR_RECIPE
$(if $(filter Windows_NT,$(OS)),if not exist "$(subst /,\,$1)" mkdir "$(subst /,\,$1)",mkdir -p "$1")
endef

ifeq ($(OS), Windows_NT)
P2_FLEXCC_CMD = "$(subst /,\,$(P2_FLEXCC))"
P2_LOADP2_CMD = "$(subst /,\,$(P2_LOADP2))"
else
P2_FLEXCC_CMD = $(P2_FLEXCC)
P2_LOADP2_CMD = $(P2_LOADP2)
endif

P2_COC      = $(PYTHON) $(COC)

ifeq ($(P2_COMPILER),catalina)
P2_CATALINA_CMD = "$(subst /,\,$(P2_CATALINA_BINDIR)/catalina.exe)"
 P2_CATALINA_ENV = set "LCCDIR=$(subst /,\,$(abspath $(P2_CATALINA_ROOT)))" && set "CATALINA_INCLUDE=$(subst /,\,$(abspath $(P2_CATALINA_INCLUDEDIR)))" && set "CATALINA_TARGET=$(subst /,\,$(abspath $(P2_CATALINA_TARGETDIR)))" && set "CATALINA_LIBRARY=$(subst /,\,$(abspath $(P2_CATALINA_ROOT)))" && set "PATH=$(subst /,\,$(abspath $(P2_CATALINA_BINDIR)));%PATH%"
P2_CATALINA_FLAGS = -C99 -p2 $(P2_CATALINA_CLIB) $(P2_CATALINA_SERIAL_LIB) $(P2_CATALINA_MLIB) -C $(P2_CATALINA_PLATFORM) -I src -I $(P2_PORTDIR)
P2_SERIAL_PROBE_TARGET = $(P2_BUILDDIR)/serial_probe.bin
P2_SERIAL_PROBE_SOURCES = port/p2/serial_probe.c port/p2/berry_port.c port/p2/p2_smartserial.c
P2_SERIAL_PROBE_BUILD = $(P2_CATALINA_ENV) && $(P2_CATALINA_CMD) $(P2_CATALINA_FLAGS) -o $(basename $(P2_SERIAL_PROBE_TARGET)) $(P2_SERIAL_PROBE_SOURCES)
else
P2_SERIAL_PROBE_TARGET = $(P2_BUILDDIR)/serial_probe.binary
P2_SERIAL_PROBE_SOURCES = port/p2/serial_probe.c port/p2/berry_port.c port/p2/p2_smartserial.c
P2_SERIAL_PROBE_BUILD = $(P2_FLEXCC_CMD) $(P2_CFLAGS) $(P2_INCFLAGS) -o $(P2_SERIAL_PROBE_TARGET) $(P2_SERIAL_PROBE_SOURCES)
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
.PHONY : p2_prebuild p2 p2-tools p2-run run p2-serial-probe p2-serial-probe-run

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
	$(Q) $(call P2_MKDIR_RECIPE,$@)

$(P2_OBJDIR):
	$(Q) $(call P2_MKDIR_RECIPE,$@)

$(P2_OBJDIR)/src/be_mem.o: src/be_mem.c | $(P2_OBJDIR)
	$(MSG) [P2 CC] $<
	$(Q) $(call P2_MKDIR_RECIPE,$(dir $@))
ifeq ($(P2_COMPILER),catalina)
	$(Q) $(P2_CATALINA_ENV) && $(P2_CATALINA_CMD) $(P2_CATALINA_FLAGS) -c $<
else
	$(Q) $(P2_FLEXCC_CMD) $(P2_CODEGEN) -O0 --fcache=0 $(P2_INCFLAGS) -c $< -o $@
endif

$(P2_OBJDIR)/%.o: %.c | $(P2_OBJDIR)
	$(MSG) [P2 CC] $<
	$(Q) $(call P2_MKDIR_RECIPE,$(dir $@))
ifeq ($(P2_COMPILER),catalina)
	$(Q) $(P2_CATALINA_ENV) && $(P2_CATALINA_CMD) $(P2_CATALINA_FLAGS) -c $<
else
	$(Q) $(P2_FLEXCC_CMD) $(P2_CFLAGS) $(P2_INCFLAGS) -c $< -o $@
endif

ifeq ($(P2_COMPILER),catalina)
p2: p2-tools p2_prebuild $(P2_BUILDDIR)
	$(MSG) [Build] $(P2_TARGET)
	$(MSG) "[P2 Compiler] catalina"
	$(Q) $(P2_CATALINA_ENV) && $(P2_CATALINA_CMD) $(P2_CATALINA_FLAGS) -o $(P2_CATALINA_OUTBASE) $(P2_SRCS)
	$(MSG) done
else
p2: p2-tools p2_prebuild $(P2_BUILDDIR) $(P2_OBJS)
	$(MSG) [Build] $(P2_TARGET)
	$(MSG) "[P2 Silicon] $(P2_SILICON) ($(P2_CODEGEN))"
	$(Q) $(P2_FLEXCC_CMD) $(P2_CFLAGS) -o $(P2_TARGET) $(P2_OBJS)
	$(MSG) done
	$(MSG) Link command:
	$(MSG) "  $(P2_FLEXCC) $(P2_CFLAGS) -o $(P2_TARGET) $(P2_OBJS)"
endif

ifeq ($(OS), Windows_NT)
p2-tools:
ifeq ($(P2_COMPILER),catalina)
	$(MSG) [Tools] Windows Catalina toolchain at $(P2_CATALINA_ROOT)
	@if not exist "$(subst /,\,$(P2_CATALINA_BINDIR)\catalina.exe)" ( \
		echo error: missing Catalina compiler in $(P2_CATALINA_BINDIR) & \
		exit /b 1 \
	)
	@if not exist "$(subst /,\,$(P2_CATALINA_INCLUDEDIR)\stddef.h)" ( \
		echo error: missing Catalina headers in $(P2_CATALINA_INCLUDEDIR) & \
		exit /b 1 \
	)
	@if not exist "$(subst /,\,$(P2_CATALINA_TARGETDIR)\p2)" ( \
		echo error: missing Catalina P2 targets in $(P2_CATALINA_TARGETDIR) & \
		exit /b 1 \
	)
	@if not exist "$(subst /,\,$(P2_CATALINA_LIBDIR)\p2)" ( \
		echo error: missing Catalina P2 libraries in $(P2_CATALINA_LIBDIR) & \
		exit /b 1 \
	)
else
	$(MSG) [Tools] Windows PowerShell bootstrap is manual; see README.md
	@if not exist "$(subst /,\,$(P2_TOOLDIR)\flexcc.exe)" ( \
		echo error: missing Windows FlexProp tools in $(P2_TOOLDIR) & \
		echo see README.md for the Windows setup steps & \
		exit /b 1 \
	)
	@if not exist "$(subst /,\,$(P2_TOOLDIR)\loadp2.exe)" ( \
		echo error: missing Windows FlexProp tools in $(P2_TOOLDIR) & \
		echo see README.md for the Windows setup steps & \
		exit /b 1 \
	)
endif
else
p2-tools:
	$(MSG) [Tools] bootstrap FlexProp toolchain
	$(Q) ./tools/p2/fetch-flexprop-tools.sh
endif

p2-run: p2
ifeq ($(OS), Windows_NT)
	@if "$(P2_PORT)"=="" ( \
		echo error: P2_PORT is not set & \
		echo usage: make p2-run P2_PORT^=<serial-port^> & \
		echo examples: & \
		echo   make p2-run P2_PORT^=COM6 & \
		exit /b 1 \
	)
else
	@if [ -z "$(P2_PORT)" ]; then \
		echo "error: P2_PORT is not set"; \
		echo "usage: make p2-run P2_PORT=<serial-port>"; \
		echo "examples:"; \
		echo "  make p2-run P2_PORT=/dev/cu.usbserial-XXXX"; \
		echo "  make p2-run P2_PORT=COM6"; \
		exit 1; \
	fi
endif
	$(MSG) [Load] $(P2_TARGET) -> $(P2_PORT)
	$(Q) $(P2_LOADP2_CMD) -p $(P2_PORT) -b $(P2_BAUD) $(P2_LOAD_FLAGS) $(P2_TARGET)

run: p2-run

p2-serial-probe: p2-tools $(P2_BUILDDIR)
	$(MSG) [Build] $(P2_SERIAL_PROBE_TARGET)
	$(Q) $(P2_SERIAL_PROBE_BUILD)
	$(MSG) done

p2-serial-probe-run: p2-serial-probe
ifeq ($(OS), Windows_NT)
	@if "$(P2_PORT)"=="" ( \
		echo error: P2_PORT is not set & \
		echo usage: make p2-serial-probe-run P2_PORT^=<serial-port^> & \
		echo examples: & \
		echo   make p2-serial-probe-run P2_PORT^=COM6 & \
		exit /b 1 \
	)
else
	@if [ -z "$(P2_PORT)" ]; then \
		echo "error: P2_PORT is not set"; \
		echo "usage: make p2-serial-probe-run P2_PORT=<serial-port>"; \
		exit 1; \
	fi
endif
	$(MSG) [Load] $(P2_SERIAL_PROBE_TARGET) -> $(P2_PORT)
	$(Q) $(P2_LOADP2_CMD) -p $(P2_PORT) -b $(P2_BAUD) $(P2_LOAD_FLAGS) $(P2_SERIAL_PROBE_TARGET)

clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* berry.lib $(P2_TARGET)
	$(Q) $(RM) -r $(P2_OBJDIR)
	$(MSG) done
