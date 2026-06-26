COC_RUN   = $(PYTHON) $(COC)
INCFLAGS  = $(foreach dir,$(INCPATH),-I"$(dir)")
SRCS      = $(foreach dir,$(SRCPATH),$(wildcard $(dir)/*.c))
OBJS      = $(patsubst %.c,%.o,$(SRCS))
DEPS      = $(patsubst %.c,%.d,$(SRCS))

ifneq ($(V),1)
Q=@
MSG=@echo
else
Q=
MSG=@true
endif

USE_READLINE ?= auto

ifeq ($(HOST_OS),windows)
    CFLAGS += -Wno-format
    LFLAGS += -Wl,--out-implib,berry.lib
    TARGET := $(TARGET).exe
else
    ifeq ($(USE_READLINE),auto)
        HAVE_READLINE := $(shell printf '#include <readline/readline.h>\n#include <readline/history.h>\n' | $(CC) -E -x c - >/dev/null 2>&1 && echo 1)
    else
        HAVE_READLINE := $(USE_READLINE)
    endif
    ifeq ($(HAVE_READLINE),1)
        CFLAGS += -DUSE_READLINE_LIB
        LIBS += -lreadline
    endif
    LIBS += -ldl
    ifeq ($(HOST_OS),linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

.PHONY: all debug test test-p2-host test-host install uninstall prebuild clean clean-host

HOST_PREBUILD_STAMP ?= $(GENERATE)/.host-prebuild

all: $(TARGET)

debug: CFLAGS += $(DEBUG_FLAGS)
debug: all

test: CFLAGS += $(TEST_FLAGS)
test: LFLAGS += $(TEST_FLAGS)
test: all
	$(MSG) [Run Testcases...]
	$(Q) TZ=UTC ./testall.be
	$(Q) $(RM) */*.gcno */*.gcda

P2_HOST_TESTS ?= tests/p2/host_libstore_chunk.be tests/p2/host_task.be tests/p2/host_p2ipc.be tests/p2/host_source_modules.be tests/p2/host_libstore_bec.be tests/p2/host_import_cache.be tests/p2/host_libstore_cache_errors.be tests/p2/host_p2mem_native_cache.be tests/p2/host_p2smart.be

test-p2-host: CFLAGS += $(TEST_FLAGS)
test-p2-host: LFLAGS += $(TEST_FLAGS)
test-p2-host: all
	$(MSG) [Run P2 host regressions...]
	$(Q) for t in $(P2_HOST_TESTS); do \
		echo "run p2 host testcase: $$t"; \
		./$(TARGET) "$$t" || exit $$?; \
	done
	$(Q) $(RM) */*.gcno */*.gcda

test-host: test test-p2-host

$(TARGET): $(OBJS)
	$(MSG) [Linking...]
	$(Q) $(CC) $(OBJS) $(LFLAGS) $(LIBS) -o $@
	$(MSG) done

$(OBJS): %.o: %.c
	$(MSG) [Compile] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

sinclude $(DEPS)

$(OBJS): $(CONST_TAB) $(HOST_PREBUILD_STAMP)

$(CONST_TAB) $(HOST_PREBUILD_STAMP): $(GENERATE) $(SRCS) $(CONFIG)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC_RUN) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(Q) touch $(HOST_PREBUILD_STAMP)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

prebuild: $(CONST_TAB) $(HOST_PREBUILD_STAMP)
	$(MSG) done

clean-host:
	$(MSG) [Clean host build...]
	$(Q) $(RM) $(OBJS) $(DEPS) berry.lib
	$(Q) $(call RM_F,$(TARGET))
	$(MSG) done

clean: clean-host p2-clean
