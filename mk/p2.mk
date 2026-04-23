TOOLCHAIN ?= flexc
PORT ?=
FLEXPROP_DIR ?= .third_party_cache/flexprop
P2_SILICON ?= latest
P2_PORT_ROOT := port/p2
P2_INCLUDE_DIR := $(P2_PORT_ROOT)/include
P2_RUNTIME_DIR := $(P2_PORT_ROOT)/runtime
P2_OVERRIDES_DIR := $(P2_PORT_ROOT)/overrides
P2_PATCH_DIR := $(P2_PORT_ROOT)/patches/optional
P2_TEST_DIR := $(P2_PORT_ROOT)/tests
P2_BUILD_DIR := build/p2/$(TOOLCHAIN)
P2_OBJDIR := $(P2_BUILD_DIR)/obj
P2_CONFIG := $(P2_INCLUDE_DIR)/berry_conf_p2.h
P2_INCFLAGS := -I"$(P2_INCLUDE_DIR)" -I"src"
P2_COC_RUN := $(PYTHON) $(COC)
P2_FLASH_FLAGS ?= -FLASH -t
P2_CATALINA_DOCKER_SCRIPT := scripts/build-p2-catalina-docker.sh

ifeq ($(origin P2_COMPILER),command line)
TOOLCHAIN := $(P2_COMPILER)
endif

ifeq ($(origin P2_PORT),command line)
PORT := $(P2_PORT)
endif

ifeq ($(TOOLCHAIN),catalina)
ifeq ($(HOST_OS),darwin)
CATALINA_USE_DOCKER ?= 1
else
CATALINA_USE_DOCKER ?= 0
endif
endif

ifeq ($(P2_SILICON),a)
P2_CODEGEN := -2a
P2_LOAD_FLAGS ?= -SINGLE -t
else ifeq ($(P2_SILICON),latest)
P2_CODEGEN := -2
P2_LOAD_FLAGS ?= -t
else ifeq ($(P2_SILICON),b)
P2_CODEGEN := -2
P2_LOAD_FLAGS ?= -t
else ifeq ($(P2_SILICON),c)
P2_CODEGEN := -2
P2_LOAD_FLAGS ?= -t
else
$(error Unsupported P2_SILICON '$(P2_SILICON)'; use a, b, c, or latest)
endif

ifeq ($(TOOLCHAIN),flexc)
include mk/toolchain-flexc.mk
else ifeq ($(TOOLCHAIN),catalina)
include mk/toolchain-catalina.mk
else
$(error Unsupported TOOLCHAIN '$(TOOLCHAIN)'; use flexc or catalina)
endif

P2_CFLAGS ?= $(P2_CODEGEN) -O1 --fcache=0
P2_RUNTIME_SRCS := \
	$(P2_RUNTIME_DIR)/berry_port.c \
	$(P2_RUNTIME_DIR)/main_p2.c \
	$(P2_RUNTIME_DIR)/p2_heap.c \
	$(P2_RUNTIME_DIR)/p2_smartserial.c
P2_OVERRIDE_SRCS := \
	$(P2_OVERRIDES_DIR)/be_libs_p2.c \
	$(P2_OVERRIDES_DIR)/be_modtab_p2.c \
	$(P2_OVERRIDES_DIR)/be_prop2lib.c \
	$(P2_OVERRIDES_DIR)/libc_compat.c
P2_FRONT_STANDARD_SRCS := \
	src/be_api.c \
	src/be_baselib.c \
	src/be_class.c \
	src/be_code.c \
	src/be_debug.c \
	src/be_exec.c
P2_FRONT_OPTIONAL_SRCS := \
	$(P2_PATCH_DIR)/be_api_p2.c \
	$(P2_PATCH_DIR)/be_api_isge_p2.c \
	$(P2_PATCH_DIR)/be_baselib_p2.c \
	$(P2_PATCH_DIR)/be_class_p2.c \
	$(P2_PATCH_DIR)/be_class_setmember_p2.c \
	$(P2_PATCH_DIR)/be_code_p2.c \
	$(P2_PATCH_DIR)/be_code_implicit_class_p2.c \
	$(P2_PATCH_DIR)/be_debug_p2.c \
	$(P2_PATCH_DIR)/be_debug_varinfo_p2.c \
	$(P2_PATCH_DIR)/be_exec_p2.c \
	$(P2_PATCH_DIR)/be_save_stacktrace_p2.c
P2_CORE_SRCS := \
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
	src/be_vm.c

ifeq ($(TOOLCHAIN),flexc)
ifeq ($(HOST_OS),windows)
P2_FRONT_SRCS := $(P2_FRONT_OPTIONAL_SRCS)
else
P2_FRONT_SRCS := $(P2_FRONT_STANDARD_SRCS)
endif
else
P2_FRONT_SRCS := $(P2_FRONT_STANDARD_SRCS)
endif

P2_SRCS := $(P2_FRONT_SRCS) $(P2_CORE_SRCS) $(P2_OVERRIDE_SRCS) $(P2_RUNTIME_SRCS)
P2_OBJS := $(patsubst %.c,$(P2_OBJDIR)/%.o,$(P2_SRCS))
P2_SERIAL_PROBE_SRCS := $(P2_TEST_DIR)/serial_probe.c $(P2_RUNTIME_DIR)/berry_port.c $(P2_RUNTIME_DIR)/p2_smartserial.c
P2_SERIAL_PROBE := $(P2_BUILD_DIR)/serial_probe.binary

.PHONY: p2 p2-catalina-host p2-run p2-ram p2-flash p2-clean p2-prebuild p2-tools p2-serial-probe p2-serial-probe-host p2-serial-probe-run run

p2-prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate P2 resources
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) scripts/prebuild-p2.ps1 -Python "$(PYTHON)" -Coc "$(COC)" -Output "$(GENERATE)" -Config "$(P2_CONFIG)" -SourcePaths "src;$(P2_PORT_ROOT);$(P2_OVERRIDES_DIR)"
else
	$(Q) PYTHON_CMD='$(PYTHON)' bash scripts/prebuild-p2.sh "$(COC)" "$(GENERATE)" "$(P2_CONFIG)" src "$(P2_PORT_ROOT)" "$(P2_OVERRIDES_DIR)"
endif
	$(MSG) done

p2-tools:
ifeq ($(TOOLCHAIN),flexc)
	$(MAKE) p2-tools-flexc TOOLCHAIN=$(TOOLCHAIN) FLEXPROP_DIR=$(FLEXPROP_DIR)
else
	$(MAKE) p2-tools-catalina TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR)
endif

$(P2_BUILD_DIR):
	$(Q) $(call MKDIR_P,$@)

$(P2_OBJDIR):
	$(Q) $(call MKDIR_P,$@)

$(P2_OBJDIR)/%.o: %.c | $(P2_OBJDIR)
	$(MSG) [P2 CC] $<
	$(Q) $(call MKDIR_P,$(dir $@))
ifeq ($(TOOLCHAIN),catalina)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -I src -I $(P2_INCLUDE_DIR) -c $< -o $@
else
	$(Q) "$(FLEXCC)" $(P2_CFLAGS) $(P2_TOOLCHAIN_INCFLAGS) $(P2_INCFLAGS) -c $< -o $@
endif

ifeq ($(TOOLCHAIN),catalina)
p2-catalina-host: $(P2_BUILD_DIR)
	$(MSG) [Build] $(P2_IMAGE)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -I src -I $(P2_INCLUDE_DIR) -o "$(P2_CATALINA_BASE)" $(P2_SRCS)
	$(Q) $(PYTHON) -c "from pathlib import Path; Path(r'$(P2_IMAGE)').write_bytes(Path(r'$(P2_CATALINA_BASE).bin').read_bytes())"
	$(MSG) done

p2: p2-tools p2-prebuild $(P2_BUILD_DIR)
ifeq ($(CATALINA_USE_DOCKER),1)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" \
		bash "$(P2_CATALINA_DOCKER_SCRIPT)" p2-catalina-host
else
	$(Q) $(MAKE) p2-catalina-host TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)"
endif
else
p2: p2-tools p2-prebuild $(P2_BUILD_DIR) $(P2_OBJS)
	$(MSG) [Build] $(P2_IMAGE)
	$(MSG) "[P2 Silicon] $(P2_SILICON) ($(P2_CODEGEN))"
	$(Q) "$(FLEXCC)" $(P2_CFLAGS) -o "$(P2_IMAGE)" $(P2_OBJS)
	$(MSG) done
endif

p2-run: p2
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_LOAD_FLAGS)" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-run TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_LOAD_FLAGS)" "$(P2_IMAGE)"
endif

run: p2-run

p2-ram: p2-run

p2-flash: p2
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_FLASH_FLAGS)" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-flash TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_FLASH_FLAGS)" "$(P2_IMAGE)"
endif

p2-serial-probe-host:
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -I src -I $(P2_INCLUDE_DIR) -o "$(P2_BUILD_DIR)/serial_probe" $(P2_SERIAL_PROBE_SRCS)
	$(Q) $(PYTHON) -c "from pathlib import Path; Path(r'$(P2_SERIAL_PROBE)').write_bytes(Path(r'$(P2_BUILD_DIR)/serial_probe.bin').read_bytes())"

ifeq ($(TOOLCHAIN),catalina)
p2-serial-probe: p2-tools p2-prebuild $(P2_BUILD_DIR)
	$(MSG) [Build] $(P2_SERIAL_PROBE)
ifeq ($(CATALINA_USE_DOCKER),1)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" \
		bash "$(P2_CATALINA_DOCKER_SCRIPT)" p2-serial-probe-host
else
	$(Q) $(MAKE) p2-serial-probe-host TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)"
endif
	$(MSG) done
else
p2-serial-probe: p2-tools $(P2_BUILD_DIR)
	$(MSG) [Build] $(P2_SERIAL_PROBE)
	$(Q) "$(FLEXCC)" $(P2_CFLAGS) $(P2_TOOLCHAIN_INCFLAGS) $(P2_INCFLAGS) -o "$(P2_SERIAL_PROBE)" $(P2_SERIAL_PROBE_SRCS)
	$(MSG) done
endif

p2-serial-probe-run: p2-serial-probe
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_LOAD_FLAGS)" -Image "$(P2_SERIAL_PROBE)"
else
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_LOAD_FLAGS)" "$(P2_SERIAL_PROBE)"
endif

p2-clean:
	$(MSG) [Clean P2 build...]
	$(Q) $(call RM_RF,build/p2)
	$(Q) $(call RM_F,build/berry_p2.binary)
	$(Q) $(call RM_F,build/berry_p2.p2asm)
	$(Q) $(call RM_F,build/serial_probe.binary)
	$(MSG) done
