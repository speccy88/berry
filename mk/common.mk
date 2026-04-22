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

ifeq ($(HOST_OS),windows)
    CFLAGS += -Wno-format
    LFLAGS += -Wl,--out-implib,berry.lib
    TARGET := $(TARGET).exe
else
    CFLAGS += -DUSE_READLINE_LIB
    LIBS += -lreadline -ldl
    ifeq ($(HOST_OS),linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

.PHONY: all debug test install uninstall prebuild clean clean-host

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
	$(Q) $(COC_RUN) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC_RUN) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(MSG) done

clean-host:
	$(MSG) [Clean host build...]
	$(Q) $(RM) $(OBJS) $(DEPS) berry.lib
	$(Q) $(call RM_F,$(TARGET))
	$(MSG) done

clean: clean-host p2-clean
