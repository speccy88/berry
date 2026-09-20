TOOLCHAIN ?= flexc
PORT ?=
FLEXPROP_DIR ?= .third_party_cache/flexprop
P2_SILICON ?= latest
P2_BOARD ?= auto
P2_PROFILE ?= full
P2_PORT_ROOT := port/p2
P2_INCLUDE_DIR := $(P2_PORT_ROOT)/include
P2_RUNTIME_DIR := $(P2_PORT_ROOT)/runtime
P2_OVERRIDES_DIR := $(P2_PORT_ROOT)/overrides
P2_PATCH_DIR := $(P2_PORT_ROOT)/patches/optional
P2_TEST_DIR := $(P2_PORT_ROOT)/tests
P2_BUILD_DIR := build/p2/$(TOOLCHAIN)/$(P2_PROFILE)
P2_OBJDIR := $(P2_BUILD_DIR)/obj
P2_BUILD_INFO_HEADER := $(P2_BUILD_DIR)/p2_build_info.h
P2_BUILD_INFO_LOG := $(P2_BUILD_DIR)/p2_build.log
P2_BUILD_INFO_SCRIPT := scripts/gen-p2-build-info.py
P2_IMAGE_SIZE_CHECK := scripts/check-p2-image-size.py
P2_REPL_UPLOAD := scripts/p2/repl_upload.py
P2_BEC_FIXTURE_DIR := build/p2/bec-fixtures
P2_BUILD_CONFIG_STAMP := $(P2_BUILD_DIR)/p2_build_config.stamp
P2_GENERATED_CONFIG := $(P2_BUILD_DIR)/berry_conf_p2_profile.h
P2_HUB_RAM_MAX_BYTES ?= 524288
P2_XMM_IMAGE_MAX_BYTES ?= 16777216
P2_CONFIG_SOURCE := $(P2_INCLUDE_DIR)/berry_conf_p2.h
P2_CONFIG := $(P2_GENERATED_CONFIG)
SPIN2_DIR := spin2
SPIN2_BUILD_DIR := $(SPIN2_DIR)/build
SPIN2_ASM_DIR := $(SPIN2_BUILD_DIR)/p2asm
SPIN2_MANIFEST := $(SPIN2_BUILD_DIR)/MANIFEST.TXT
SPIN2_BUILD_SCRIPT := tools/spin2/build_all.py
SPIN2_SRCS := $(wildcard $(SPIN2_DIR)/*.spin2)
SPIN2_SD_LOADER_SRC := tools/p2/sd_loader/sd_loader.c
SPIN2_SD_HOST := tools/p2/sd_loader/spin2_sdload.py
SPIN2_SD_LOADER_BASE := $(P2_BUILD_DIR)/spin2_sd_loader
SPIN2_SD_LOADER_IMAGE := $(P2_BUILD_DIR)/spin2_sd_loader.binary
SPIN2_SD_DIR ?= /spin2
SPIN2_SD_FILE ?=
SPIN2_SD_NAME ?=
SPIN2_SD_CHUNK ?= 32
SPIN2_SD_LINE_DELAY ?= 0.05
P2_INCFLAGS := -I"$(P2_BUILD_DIR)" -I"$(P2_INCLUDE_DIR)" -I"src" -I"default"
P2_COC_RUN := $(PYTHON) $(COC)
P2_FLASH_FLAGS ?= -SPI
P2_XMM_TOOLS_SCRIPT := tools/p2/loader/build-catalina-xmm-tools.sh
P2_XMM_PAYLOAD_RUNNER := tools/p2/loader/run-catalina-xmm-payload.sh
P2_XMM_HOST_DIR := build/p2/host
P2_XMM_LOADER_DIR := build/p2/catalina/xmm-loader
P2_XMM_PAYLOAD := $(P2_XMM_HOST_DIR)/payload
P2_XMM_LOADER_IMAGE := $(P2_XMM_LOADER_DIR)/XMM_USB.binary
P2_XMM_PAYLOAD_FLAGS ?= -o2 -j -m 10 -n 1000 -f 5000
P2_XMM_FLASH_SCRIPT := tools/p2/loader/build-catalina-xmm-flash-image.sh
P2_XMM_FLASH_IMAGE := $(P2_BUILD_DIR)/berry_p2_xmm_flash.binary
P2_XMM_FLASH_LOADER_ADDR ?= 0x10000
P2_XMM_FLASH_APP_ADDR ?= 0x40000
P2_XMM_FLASH_LOAD_SPEC := @80000000=$(P2_XMM_FLASH_IMAGE)
P2_CONFIG_TOOLCHAIN ?= $(TOOLCHAIN)
P2_CONFIG_PORT ?= $(PORT)
P2_CONFIG_SILICON ?= $(P2_SILICON)
P2_CONFIG_BOARD ?= $(P2_BOARD)
P2_CONFIG_HOST_OS ?= $(HOST_OS)
P2_CONFIG_CATALINA_PLATFORM ?= $(CATALINA_PLATFORM)
P2_CONFIG_CATALINA_MODEL ?= $(CATALINA_MODEL)
P2_CONFIG_CATALINA_CLIB ?= $(CATALINA_CLIB)
P2_CONFIG_CATALINA_SERIAL_LIB ?= $(CATALINA_SERIAL_LIB)
P2_CONFIG_CATALINA_EXTRA_CFLAGS ?= $(CATALINA_EXTRA_CFLAGS)
P2_CONFIG_FLEXPROP_DIR ?= $(FLEXPROP_DIR)
P2_CONFIG_CATALINA_DIR ?= $(CATALINA_DIR)
P2_CONFIG_LOADP2 ?= $(LOADP2)

ifeq ($(P2_PROFILE),minimal)
P2_PROFILE_ID := 1
else ifeq ($(P2_PROFILE),full)
P2_PROFILE_ID := 2
else ifeq ($(P2_PROFILE),edge32)
P2_PROFILE_ID := 3
else ifeq ($(P2_PROFILE),xmm)
P2_PROFILE_ID := 4
else ifeq ($(P2_PROFILE),sddiag)
P2_PROFILE_ID := 5
else
$(error Unsupported P2_PROFILE '$(P2_PROFILE)'; use minimal, full, edge32, xmm, or sddiag)
endif

P2_PROFILE_DEFINE := -DBE_P2_PROFILE=$(P2_PROFILE_ID)
P2_DIRECT_SD_DEFINE ?=

ifeq ($(P2_BOARD),auto)
ifneq ($(filter edge32 xmm sddiag,$(P2_PROFILE)),)
override P2_BOARD := p2edge32
else
override P2_BOARD := p2edge
endif
endif

ifeq ($(P2_BOARD),p2edge)
P2_BOARD_ID := 1
P2_BOARD_NAME := p2edge
P2_BOARD_HAS_PSRAM := 0
P2_LED0_PIN := 56
P2_LED1_PIN := 57
else ifeq ($(P2_BOARD),p2edge32)
P2_BOARD_ID := 2
P2_BOARD_NAME := p2edge32
P2_BOARD_HAS_PSRAM := 1
P2_LED0_PIN := 38
P2_LED1_PIN := 39
else
$(error Unsupported P2_BOARD '$(P2_BOARD)'; use auto, p2edge, or p2edge32)
endif

ifeq ($(P2_SILICON),a)
P2_SILICON_ID := 1
P2_SILICON_NAME := old
else
P2_SILICON_ID := 2
P2_SILICON_NAME := latest
endif

ifeq ($(P2_PROFILE),xmm)
ifneq ($(origin CATALINA_MODEL),command line)
CATALINA_MODEL := LARGE
endif
endif

ifeq ($(P2_PROFILE),xmm)
P2_IMAGE_MAX_BYTES ?= $(P2_XMM_IMAGE_MAX_BYTES)
P2_IMAGE_SIZE_LABEL ?= Catalina P2 XMM image
P2_IMAGE_LIMIT_NAME ?= Catalina P2 XMM load image limit
else
P2_IMAGE_MAX_BYTES ?= $(P2_HUB_RAM_MAX_BYTES)
P2_IMAGE_SIZE_LABEL ?= Catalina P2 image
P2_IMAGE_LIMIT_NAME ?= P2 Hub RAM limit
endif

ifneq ($(filter edge32 xmm sddiag,$(P2_PROFILE)),)
ifneq ($(origin CATALINA_SERIAL_LIB),command line)
CATALINA_SERIAL_LIB := -lpsram
endif
endif

ifeq ($(origin P2_COMPILER),command line)
TOOLCHAIN := $(P2_COMPILER)
endif

ifeq ($(origin P2_PORT),command line)
PORT := $(P2_PORT)
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

ifeq ($(P2_PROFILE),xmm)
ifeq ($(findstring -C PSRAM,$(CATALINA_CONFIG_FLAGS)),)
override CATALINA_CONFIG_FLAGS += -C PSRAM
endif
endif

ifeq ($(TOOLCHAIN),catalina)
CATALINA_PLAIN_SD ?= 0
ifneq ($(CATALINA_PLAIN_SD),1)
P2_DIRECT_SD_DEFINE := -D__BERRY_P2_DIRECT_SD_IO
ifeq ($(findstring -C BERRY_P2_DIRECT_SD_IO,$(CATALINA_CONFIG_FLAGS)),)
override CATALINA_CONFIG_FLAGS += -C BERRY_P2_DIRECT_SD_IO
endif
endif
endif

P2_CFLAGS ?= $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(P2_CODEGEN) -O1 --fcache=0
CATALINA_HEAP_TOP ?=
ifeq ($(P2_PROFILE),xmm)
ifeq ($(CATALINA_HEAP_TOP),)
CATALINA_HEAP_TOP := 16M
endif
endif
P2_COMPILE_ARCHIVED_SPIN2 ?= 0
P2_COMPILE_ARCHIVED_WORKER ?= 0
P2_RUNTIME_SRCS := \
	$(P2_RUNTIME_DIR)/berry_port.c \
	$(P2_RUNTIME_DIR)/main_p2.c \
	$(P2_RUNTIME_DIR)/p2_clock.c \
	$(P2_RUNTIME_DIR)/p2_hub_heap.c \
	$(P2_RUNTIME_DIR)/p2_exception_memory.c \
	$(P2_RUNTIME_DIR)/p2_vm_state.c \
	$(P2_RUNTIME_DIR)/p2_cog_registry.c \
	$(P2_RUNTIME_DIR)/p2_heap.c \
	$(P2_RUNTIME_DIR)/p2_partition.c \
	$(P2_RUNTIME_DIR)/p2_smartserial.c
P2_OVERRIDE_SRCS := \
	$(P2_OVERRIDES_DIR)/be_modtab_p2.c \
	$(P2_OVERRIDES_DIR)/be_libs_p2.c \
	$(P2_OVERRIDES_DIR)/be_introspectlib_p2.c \
	$(P2_OVERRIDES_DIR)/be_math_stringlib_p2.c \
	$(P2_OVERRIDES_DIR)/be_tasklib_p2.c \
	$(P2_OVERRIDES_DIR)/libc_compat.c
ifneq ($(P2_PROFILE),minimal)
ifeq ($(P2_PROFILE),sddiag)
P2_OVERRIDE_SRCS += \
	$(P2_OVERRIDES_DIR)/be_p2lib_p2.c \
	$(P2_OVERRIDES_DIR)/be_prop2lib.c
else
P2_OVERRIDE_SRCS += \
	$(P2_OVERRIDES_DIR)/be_i2clib_p2.c \
	$(P2_OVERRIDES_DIR)/be_p2lib_p2.c \
	$(P2_OVERRIDES_DIR)/be_prop2lib.c \
	$(P2_OVERRIDES_DIR)/be_spilib_p2.c
endif
ifeq ($(P2_COMPILE_ARCHIVED_SPIN2),1)
P2_OVERRIDE_SRCS += $(P2_OVERRIDES_DIR)/be_spin2lib_p2.c
endif
endif
P2_LIB_SRCS := \
	src/be_byteslib.c \
	src/be_debuglib.c \
	src/be_gclib.c \
	src/be_globallib.c \
	src/be_jsonlib.c \
	src/be_listlib.c \
	src/be_maplib.c \
	src/be_mathlib.c \
	src/be_oslib.c \
	src/be_rangelib.c \
	src/be_solidifylib.c \
	src/be_strictlib.c \
	src/be_syslib.c \
	src/be_timelib.c \
	src/be_undefinedlib.c
ifneq ($(P2_PROFILE),minimal)
P2_LIB_SRCS += src/be_filelib.c
endif
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
	src/be_bytecode.c \
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

P2_SRCS := $(P2_FRONT_SRCS) $(P2_CORE_SRCS) $(P2_LIB_SRCS) $(P2_OVERRIDE_SRCS) $(P2_RUNTIME_SRCS)
P2_OBJS := $(patsubst %.c,$(P2_OBJDIR)/%.o,$(P2_SRCS))
P2_SERIAL_PROBE_SRCS := $(P2_TEST_DIR)/serial_probe.c $(P2_RUNTIME_DIR)/berry_port.c $(P2_RUNTIME_DIR)/p2_smartserial.c
P2_SERIAL_PROBE := $(P2_BUILD_DIR)/serial_probe.binary
P2_PREBUILD_DEPS := $(COC) $(P2_CONFIG) $(P2_CONFIG_SOURCE) scripts/prebuild-p2.sh scripts/prebuild-p2.ps1 $(P2_IMAGE_SIZE_CHECK)

.PHONY: p2 p2-minimal p2-full p2-edge32 p2-edge32-ram p2-edge32-flash p2-edge32-xmm p2-xmm p2-xmm-tools p2-edge32-xmm-run p2-xmm-run p2-xmm-load p2-edge32-xmm-flash p2-xmm-flash p2-xmm-flash-run p2-xmm-flash-load p2-catalina-host p2-baseline-guards p2-catalina-build-log-guard-selftest p2-profile-invariants-selftest p2-catalina-xmm-cx-sync-selftest p2-catalina-warning-audit p2-sd-write-smoke-audit p2-docs-audit p2-source-module-metadata-audit p2-example-safety-audit p2-smartpin-constants-audit p2-catalina-path-audit p2-run p2-ram p2-flash p2-flash-run p2-attach p2-smoke p2-smoke-quick p2-smoke-edge32 p2-smoke-examples-quick p2-smoke-examples-bus p2-smoke-examples-serial p2-smoke-examples-smartpin-diagnostics p2-smoke-examples-system p2-smoke-examples-runtime p2-smoke-examples-debug p2-smoke-examples-wifi p2-smoke-examples-p2 p2-smoke-examples-unsupported p2-smoke-examples-core p2-smoke-pasm-layout p2-smoke-pasm-policy-min p2-smoke-p2-api p2-smoke-p2compat p2-smoke-libraries-lazy-min p2-smoke-p2mem-policy-min p2-smoke-p2mem-native-cache-min p2-smoke-bec-fallback-min p2-smoke-core-builtins-min p2-smoke-sd-file-min p2-smoke-sd-file-core-min p2-smoke-stdlib-min p2-smoke-math-perf-min p2-smoke-cog-policy-min p2-smoke-cog-closure p2-smoke-cog-closure-min p2-smoke-task p2-smoke-task-policy-min p2-smoke-ipc p2-smoke-ipc-policy-min p2-smoke-priority1 p2-smoke-priority1-staged p2-smoke-priority2 p2-smoke-priority2-staged p2-smoke-priority3 p2-smoke-priority3-staged p2-smoke-priority4 p2-smoke-priority1-4 p2-smoke-priority1-4-min p2-smoke-priority1-4-min-staged p2-smoke-priority1-4-staged p2-smoke-smartpins p2-smoke-smartpins-focused p2-smoke-smartpins-loopback p2-smoke-smartpins-normal-pin p2-smoke-smartpins-quadrature-static p2-smoke-smartpins-quadrature-motion p2-smoke-smartpins-quadrature-diag p2-smoke-smartpins-counter-modes p2-smoke-smartpins-counter-timer-matrix p2-smoke-smartpins-output-modes p2-smoke-smartpins-adc-dac-native p2-smoke-smartpins-adc-variant-matrix p2-smoke-smartpins-adc-dac-diag p2-smoke-smartpins-nco-duty-diag p2-smoke-smartpins-async-rx p2-smoke-smartpins-async-buffer-boundary p2-smoke-smartpins-sync-diag test-p2 soak-p2 p2-stop p2-clean p2-prebuild p2-tools p2-serial-probe p2-serial-probe-host p2-serial-probe-run p2-sd-modules p2-sd-tests p2-sd-sync p2-sd-core-builtins-min-smoke p2-sd-file-core-min-smoke p2-sd-stdlib-min-smoke p2-sd-math-perf-min-smoke p2-sd-pasm-layout-smoke p2-sd-p2-api-smoke p2-sd-p2compat-smoke p2-sd-bec-fallback-min-smoke p2-sd-examples-quick-smoke p2-sd-examples-bus-smoke p2-sd-examples-serial-smoke p2-sd-examples-smartpin-diagnostics-smoke p2-sd-examples-system-smoke p2-sd-examples-runtime-smoke p2-sd-examples-debug-smoke p2-sd-examples-wifi-smoke p2-sd-examples-p2-smoke p2-sd-examples-unsupported-smoke p2-sd-examples-core-smoke p2-sd-cog-closure-smoke p2-sd-cog-closure-min-smoke p2-sd-task-smoke p2-sd-ipc-smoke p2-sd-berry-dirs p2-sd-berry-lib p2-sd-berry-examples p2-sd-berry-sync spin2 spin2-clean spin2-sd-loader spin2-sd-loader-host spin2-sd-put spin2-sd-sync spin2-load spin2-load-all run configure configure-reset show-config
.PHONY: p2-smoke-debug-capabilities-min

configure:
	$(MSG) [Configure] $(P2_LOCAL_CONFIG)
	$(Q) $(PYTHON) -c "from pathlib import Path; path = Path(r'''$(P2_LOCAL_CONFIG)'''); text = '\n'.join([ \
		'# Auto-generated by make configure.', \
		'# Command-line variables still override these defaults.', \
		'HOST_OS := $(P2_CONFIG_HOST_OS)', \
		'TOOLCHAIN := $(P2_CONFIG_TOOLCHAIN)', \
		'PORT := $(P2_CONFIG_PORT)', \
		'P2_SILICON := $(P2_CONFIG_SILICON)', \
		'P2_BOARD := $(P2_CONFIG_BOARD)', \
		'P2_PROFILE := $(P2_PROFILE)', \
		'CATALINA_PLATFORM := $(P2_CONFIG_CATALINA_PLATFORM)', \
		'CATALINA_MODEL := $(P2_CONFIG_CATALINA_MODEL)', \
		'CATALINA_CLIB := $(P2_CONFIG_CATALINA_CLIB)', \
		'CATALINA_SERIAL_LIB := $(P2_CONFIG_CATALINA_SERIAL_LIB)', \
		'CATALINA_EXTRA_CFLAGS := $(P2_CONFIG_CATALINA_EXTRA_CFLAGS)', \
		'FLEXPROP_DIR := $(P2_CONFIG_FLEXPROP_DIR)', \
		'CATALINA_DIR := $(P2_CONFIG_CATALINA_DIR)', \
		'LOADP2 := $(P2_CONFIG_LOADP2)', \
		'' \
	]); path.write_text(text, encoding='utf-8'); print('saved', path)"
	$(MSG) done

configure-reset:
	$(MSG) [Configure] remove $(P2_LOCAL_CONFIG)
	$(Q) $(call RM_F,$(P2_LOCAL_CONFIG))
	$(MSG) done

show-config:
	@echo "P2 local config: $(P2_LOCAL_CONFIG)"
	@echo "HOST_OS=$(HOST_OS)"
	@echo "TOOLCHAIN=$(TOOLCHAIN)"
	@echo "PORT=$(PORT)"
	@echo "P2_SILICON=$(P2_SILICON)"
	@echo "P2_BOARD=$(P2_BOARD)"
	@echo "P2_BOARD_HAS_PSRAM=$(P2_BOARD_HAS_PSRAM)"
	@echo "P2_LED0_PIN=$(P2_LED0_PIN)"
	@echo "P2_LED1_PIN=$(P2_LED1_PIN)"
	@echo "P2_PROFILE=$(P2_PROFILE)"
	@echo "CATALINA_PLATFORM=$(CATALINA_PLATFORM)"
	@echo "CATALINA_MODEL=$(CATALINA_MODEL)"
	@echo "CATALINA_CLIB=$(CATALINA_CLIB)"
	@echo "CATALINA_SERIAL_LIB=$(CATALINA_SERIAL_LIB)"
	@echo "CATALINA_CONFIG_FLAGS=$(CATALINA_CONFIG_FLAGS)"
	@echo "P2_IMAGE_LIMIT_NAME=$(P2_IMAGE_LIMIT_NAME)"
	@echo "P2_IMAGE_MAX_BYTES=$(P2_IMAGE_MAX_BYTES)"
	@echo "FLEXPROP_DIR=$(FLEXPROP_DIR)"
	@echo "CATALINA_DIR=$(CATALINA_DIR)"
	@echo "LOADP2=$(LOADP2)"

$(P2_GENERATED_CONFIG): FORCE $(P2_CONFIG_SOURCE) | $(P2_BUILD_DIR)
	$(MSG) [Config] P2 profile $(P2_PROFILE), board $(P2_BOARD)
	$(Q) { \
		echo "/* Auto-generated by mk/p2.mk. */"; \
		echo "#ifndef BERRY_CONF_P2_PROFILE_H"; \
		echo "#define BERRY_CONF_P2_PROFILE_H"; \
		echo "#define BE_P2_PROFILE $(P2_PROFILE_ID)"; \
		echo "#define BE_P2_BOARD $(P2_BOARD_ID)"; \
		echo "#define BE_P2_BOARD_NAME \"$(P2_BOARD_NAME)\""; \
		echo "#define BE_P2_BOARD_HAS_PSRAM $(P2_BOARD_HAS_PSRAM)"; \
		echo "#define BE_P2_BOARD_LED0_PIN $(P2_LED0_PIN)"; \
		echo "#define BE_P2_BOARD_LED1_PIN $(P2_LED1_PIN)"; \
		echo "#define BE_P2_SILICON $(P2_SILICON_ID)"; \
		echo "#define BE_P2_SILICON_NAME \"$(P2_SILICON_NAME)\""; \
		echo "#include \"../../../../$(P2_CONFIG_SOURCE)\""; \
		echo "#endif"; \
	} > "$@.tmp"
	$(Q) if ! cmp -s "$@.tmp" "$@"; then mv "$@.tmp" "$@"; else rm -f "$@.tmp"; fi

p2-prebuild: $(GENERATE) $(P2_CONFIG)
	$(MSG) [Prebuild] generate P2 resources for $(P2_PROFILE)
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) scripts/prebuild-p2.ps1 -Python "$(PYTHON)" -Coc "$(COC)" -Output "$(GENERATE)" -Config "$(P2_CONFIG)" -SourcePaths "src;$(P2_PORT_ROOT);$(P2_OVERRIDES_DIR)"
else
	$(Q) PYTHON_CMD='$(PYTHON)' bash scripts/prebuild-p2.sh "$(COC)" "$(GENERATE)" "$(P2_CONFIG)" src "$(P2_PORT_ROOT)" "$(P2_OVERRIDES_DIR)"
endif
	$(Q) $(RM) $(HOST_PREBUILD_STAMP)
	$(MSG) done

p2-tools:
ifeq ($(TOOLCHAIN),flexc)
	$(MAKE) p2-tools-flexc TOOLCHAIN=$(TOOLCHAIN) FLEXPROP_DIR=$(FLEXPROP_DIR)
else
	$(MAKE) p2-tools-catalina TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR)
endif

$(P2_BUILD_DIR):
	$(Q) $(call MKDIR_P,$@)

$(SPIN2_BUILD_DIR):
	$(Q) $(call MKDIR_P,$@)

spin2: $(SPIN2_SRCS) $(SPIN2_BUILD_SCRIPT) | $(SPIN2_BUILD_DIR) p2-tools
	$(Q) "$(PYTHON)" "$(SPIN2_BUILD_SCRIPT)" --flexspin "$(FLEXSPIN)" \
		--src-dir "$(SPIN2_DIR)" --bin-dir "$(SPIN2_BUILD_DIR)" \
		--asm-dir "$(SPIN2_ASM_DIR)" --manifest "$(SPIN2_MANIFEST)"

spin2-clean:
	$(Q) $(call RM_RF,$(SPIN2_BUILD_DIR))

ifeq ($(TOOLCHAIN),catalina)
spin2-sd-loader-host: $(SPIN2_SD_LOADER_SRC) | $(P2_BUILD_DIR)
	$(MSG) [Spin2 SD Loader] $(SPIN2_SD_LOADER_IMAGE)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" LCCDIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -C SD -o "$(SPIN2_SD_LOADER_BASE)" "$(SPIN2_SD_LOADER_SRC)"
	$(Q) "$(PYTHON)" -c "from pathlib import Path; Path(r'$(SPIN2_SD_LOADER_IMAGE)').write_bytes(Path(r'$(SPIN2_SD_LOADER_BASE).bin').read_bytes())"
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(SPIN2_SD_LOADER_IMAGE)" --max-bytes "$(P2_HUB_RAM_MAX_BYTES)" --label "Spin2 SD loader"
	$(MSG) done

spin2-sd-loader: p2-tools spin2-sd-loader-host
else
spin2-sd-loader spin2-sd-loader-host:
	@echo "error: Spin2 SD loader requires TOOLCHAIN=catalina"
	@exit 1
endif

spin2-sd-put: spin2-sd-loader
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make spin2-sd-put TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN"; \
		exit 1; \
	fi
	@if [ -z "$(SPIN2_SD_FILE)" ]; then \
		echo "error: SPIN2_SD_FILE is not set"; \
		echo "usage: make spin2-sd-put TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN"; \
		exit 1; \
	fi
	$(Q) NAME_ARG=""; \
	if [ -n "$(SPIN2_SD_NAME)" ]; then NAME_ARG="--target-name $(SPIN2_SD_NAME)"; fi; \
	"$(PYTHON)" "$(SPIN2_SD_HOST)" --loadp2 "$(LOADP2)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--loader "$(SPIN2_SD_LOADER_IMAGE)" --target-dir "$(SPIN2_SD_DIR)" --chunk-size "$(SPIN2_SD_CHUNK)" \
		--line-delay "$(SPIN2_SD_LINE_DELAY)" \
		--file "$(SPIN2_SD_FILE)" $$NAME_ARG

spin2-sd-sync: spin2 spin2-sd-loader
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make spin2-sd-sync TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(SPIN2_SD_HOST)" --loadp2 "$(LOADP2)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--loader "$(SPIN2_SD_LOADER_IMAGE)" --target-dir "$(SPIN2_SD_DIR)" --chunk-size "$(SPIN2_SD_CHUNK)" \
		--line-delay "$(SPIN2_SD_LINE_DELAY)" \
		--directory "$(SPIN2_BUILD_DIR)"

spin2-load: spin2-sd-put

spin2-load-all: spin2-sd-sync

p2-sd-modules:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-modules TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/modules" --recursive-directory "modules"

p2-sd-tests:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-tests TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --recursive-directory "tests/p2"

p2-sd-sync:
	$(Q) $(MAKE) p2-sd-modules TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) $(MAKE) p2-sd-tests TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"

p2-sd-pasm-layout-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-pasm-layout-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --target-file "tests/p2/smoke_pasm_layout.be=pasmly.be"

p2-sd-p2-api-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-p2-api-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_p2_api.be"

p2-sd-p2compat-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-p2compat-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/p2compat.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_p2compat.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/p2compvm.be"

p2-sd-bec-fallback-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-bec-fallback-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_bec_fallback_min.be"

.PHONY: p2-sd-bec-abi-min-smoke p2-smoke-bec-abi-min
p2-sd-bec-abi-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-bec-abi-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/prepare_bec_fixture.py --berry ./berry --source tests/p2/fixtures/becload.be --module becload --out-dir "$(P2_BEC_FIXTURE_DIR)"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/lib" --target-file "tests/p2/fixtures/becload.be=becload.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/berry/cache" --binary-target-file "$(P2_BEC_FIXTURE_DIR)/becload.bec=becload.bec"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/cache" --target-file "$(P2_BEC_FIXTURE_DIR)/becload.jsn=becload.jsn"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_bec_load_min.be"

p2-sd-examples-quick-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-quick-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/blink.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/gpio_loopback.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/pwm_fade.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/adc_read.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/dac_write.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/nco_counter_loopback.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/quadrature_counter.be"

p2-sd-examples-bus-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-bus-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/i2c" --file "examples/i2c/scan.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/spi" --file "examples/spi/jedec.be"

p2-sd-examples-serial-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-serial-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/uart_loopback.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/sync_serial_loopback.be"

p2-sd-examples-smartpin-diagnostics-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-smartpin-diagnostics-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/smartpin_diagnostics.be"

p2-sd-examples-system-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-system-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/cordic_demo.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/psram_cache_stats.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/repl_sd.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/file_sd.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/json_sd.be"

p2-sd-examples-runtime-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-runtime-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/task_scheduler.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/task_primitives.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --target-file "examples/cog_closure.be=cogclo.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --target-file "examples/cog_closure_blink.be=cogblk.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/pasm_direct.be"

p2-sd-examples-debug-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-debug-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/debug_report.be"

p2-sd-examples-wifi-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-wifi-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/wifi.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/wifi" --file "examples/wifi/detect.be"

p2-sd-examples-p2-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-p2-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/blink.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/pin_helpers.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/smartpin_helpers.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/timing_helpers.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/hardware_helpers.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/closure_blinker.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/p2" --file "examples/p2/cog_spawn_source_blinker.be"

p2-sd-examples-unsupported-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-unsupported-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 \
		--target-dir "/modules" --file "modules/p2compat.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/vga_test_pattern.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --file "examples/usb_keyboard_mouse.be"

p2-sd-examples-core-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-examples-core-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples/core" --recursive-directory "examples/core"

p2-sd-cog-closure-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-cog-closure-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_cog_closure.be"

p2-sd-cog-closure-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-cog-closure-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_cog_closure_min.be"

p2-sd-task-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-task-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/modules" --file "modules/task.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/modules" --file "modules/p2ipc.be"
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --file "tests/p2/smoke_task.be"

p2-sd-ipc-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-ipc-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/modules" --file "modules/p2ipc.be"

p2-sd-berry-dirs:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-berry-dirs TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/" \
		--mkdir "/berry" \
		--mkdir "/berry/lib" \
		--mkdir "/berry/app" \
		--mkdir "/berry/cache" \
		--mkdir "/berry/config" \
		--mkdir "/berry/examples" \
		--mkdir "/berry/pasm"

p2-sd-berry-lib:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-berry-lib TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/lib" --recursive-directory "modules"

p2-sd-berry-examples:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-berry-examples TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/berry/examples" --recursive-directory "examples"

p2-sd-berry-sync:
	$(Q) $(MAKE) p2-sd-berry-dirs TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) $(MAKE) p2-sd-berry-lib TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) $(MAKE) p2-sd-berry-examples TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"

$(P2_BUILD_INFO_HEADER): $(P2_BUILD_INFO_SCRIPT) | $(P2_BUILD_DIR)
	$(Q) "$(PYTHON)" "$(P2_BUILD_INFO_SCRIPT)" --log "$(P2_BUILD_INFO_LOG)" --binary "$(P2_IMAGE)" --header "$@"

$(P2_OBJDIR):
	$(Q) $(call MKDIR_P,$@)

FORCE:

$(P2_BUILD_CONFIG_STAMP): FORCE | $(P2_BUILD_DIR)
	$(Q) { \
		echo "TOOLCHAIN=$(TOOLCHAIN)"; \
		echo "P2_SILICON=$(P2_SILICON)"; \
		echo "P2_BOARD=$(P2_BOARD)"; \
		echo "P2_BOARD_ID=$(P2_BOARD_ID)"; \
		echo "P2_BOARD_HAS_PSRAM=$(P2_BOARD_HAS_PSRAM)"; \
		echo "P2_LED0_PIN=$(P2_LED0_PIN)"; \
		echo "P2_LED1_PIN=$(P2_LED1_PIN)"; \
		echo "P2_PROFILE=$(P2_PROFILE)"; \
		echo "P2_PROFILE_ID=$(P2_PROFILE_ID)"; \
		echo "P2_CODEGEN=$(P2_CODEGEN)"; \
		echo "CATALINA_PLATFORM=$(CATALINA_PLATFORM)"; \
		echo "CATALINA_MODEL=$(CATALINA_MODEL)"; \
		echo "CATALINA_CLIB=$(CATALINA_CLIB)"; \
		echo "CATALINA_SERIAL_LIB=$(CATALINA_SERIAL_LIB)"; \
		echo "CATALINA_MLIB=$(CATALINA_MLIB)"; \
		echo "CATALINA_HEAP_TOP=$(CATALINA_HEAP_TOP)"; \
		echo "CATALINA_EXTRA_CFLAGS=$(CATALINA_EXTRA_CFLAGS)"; \
		echo "CATALINA_CONFIG_FLAGS=$(CATALINA_CONFIG_FLAGS)"; \
		echo "P2_HUB_RAM_MAX_BYTES=$(P2_HUB_RAM_MAX_BYTES)"; \
		echo "P2_XMM_IMAGE_MAX_BYTES=$(P2_XMM_IMAGE_MAX_BYTES)"; \
		echo "P2_IMAGE_MAX_BYTES=$(P2_IMAGE_MAX_BYTES)"; \
		echo "P2_IMAGE_SIZE_LABEL=$(P2_IMAGE_SIZE_LABEL)"; \
		echo "P2_IMAGE_LIMIT_NAME=$(P2_IMAGE_LIMIT_NAME)"; \
		echo "P2_PROFILE_DEFINE=$(P2_PROFILE_DEFINE)"; \
		echo "P2_DIRECT_SD_DEFINE=$(P2_DIRECT_SD_DEFINE)"; \
		echo "P2_CFLAGS=$(P2_CFLAGS)"; \
	} > "$@.tmp"
	$(Q) if ! cmp -s "$@.tmp" "$@"; then mv "$@.tmp" "$@"; else rm -f "$@.tmp"; fi

$(P2_OBJDIR)/%.o: %.c | $(P2_OBJDIR)
	$(MSG) [P2 CC] $<
	$(Q) $(call MKDIR_P,$(dir $@))
ifeq ($(TOOLCHAIN),catalina)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" LCCDIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_EXTRA_CFLAGS) $(CATALINA_CONFIG_FLAGS) -I src -I $(P2_INCLUDE_DIR) -c $< -o $@
else
	$(Q) "$(FLEXCC)" $(P2_CFLAGS) $(P2_TOOLCHAIN_INCFLAGS) $(P2_INCFLAGS) -c $< -o $@
endif

ifeq ($(TOOLCHAIN),catalina)
p2-catalina-host: $(P2_BUILD_DIR) $(P2_BUILD_INFO_HEADER)
	$(MSG) [Build] $(P2_IMAGE)
	$(Q) $(call RM_F,$(P2_IMAGE))
	$(Q) $(call RM_F,$(P2_CATALINA_BASE).bin)
	$(Q) CMD='CATALINA_DIR="$(CATALINA_DIR)" LCCDIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" "$(CATALINA)" -C99 -p2 $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) $(if $(CATALINA_HEAP_TOP),-H$(CATALINA_HEAP_TOP),) $(CATALINA_EXTRA_CFLAGS) $(CATALINA_CONFIG_FLAGS) -I src -I $(P2_BUILD_DIR) -I $(P2_INCLUDE_DIR) -o "$(P2_CATALINA_BASE)" $(P2_SRCS)'; \
		bash -lc "set -o pipefail; $$CMD 2>&1 | tee '$(P2_BUILD_INFO_LOG)'"
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_CATALINA_BASE).bin" --max-bytes "$(P2_IMAGE_MAX_BYTES)" --label "$(P2_IMAGE_SIZE_LABEL)" --limit-name "$(P2_IMAGE_LIMIT_NAME)"
	$(Q) "$(PYTHON)" "$(P2_BUILD_INFO_SCRIPT)" --log "$(P2_BUILD_INFO_LOG)" --binary "$(P2_CATALINA_BASE).bin" --header "$(P2_BUILD_INFO_HEADER).tmp" --preserve-timestamp-from "$(P2_BUILD_INFO_HEADER)"
	$(Q) if ! cmp -s "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; then \
		mv "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; \
		CMD='CATALINA_DIR="$(CATALINA_DIR)" LCCDIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" "$(CATALINA)" -C99 -p2 $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) $(if $(CATALINA_HEAP_TOP),-H$(CATALINA_HEAP_TOP),) $(CATALINA_EXTRA_CFLAGS) $(CATALINA_CONFIG_FLAGS) -I src -I $(P2_BUILD_DIR) -I $(P2_INCLUDE_DIR) -o "$(P2_CATALINA_BASE)" $(P2_SRCS)'; \
		bash -lc "set -o pipefail; $$CMD 2>&1 | tee '$(P2_BUILD_INFO_LOG)'"; \
		"$(PYTHON)" "$(P2_BUILD_INFO_SCRIPT)" --log "$(P2_BUILD_INFO_LOG)" --binary "$(P2_CATALINA_BASE).bin" --header "$(P2_BUILD_INFO_HEADER).tmp" --preserve-timestamp-from "$(P2_BUILD_INFO_HEADER)"; \
		if ! cmp -s "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; then \
			mv "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; \
			bash -lc "set -o pipefail; $$CMD 2>&1 | tee '$(P2_BUILD_INFO_LOG)'"; \
			"$(PYTHON)" "$(P2_BUILD_INFO_SCRIPT)" --log "$(P2_BUILD_INFO_LOG)" --binary "$(P2_CATALINA_BASE).bin" --header "$(P2_BUILD_INFO_HEADER).tmp" --preserve-timestamp-from "$(P2_BUILD_INFO_HEADER)"; \
			if ! cmp -s "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; then \
				echo "error: P2 build info did not converge after three Catalina link passes" >&2; \
				exit 1; \
			fi; \
		fi; \
		rm -f "$(P2_BUILD_INFO_HEADER).tmp"; \
	else \
		rm -f "$(P2_BUILD_INFO_HEADER).tmp"; \
	fi
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_CATALINA_BASE).bin" --max-bytes "$(P2_IMAGE_MAX_BYTES)" --label "$(P2_IMAGE_SIZE_LABEL)" --limit-name "$(P2_IMAGE_LIMIT_NAME)"
	$(Q) $(PYTHON) -c "from pathlib import Path; Path(r'$(P2_IMAGE)').write_bytes(Path(r'$(P2_CATALINA_BASE).bin').read_bytes())"
	$(MSG) done

$(P2_IMAGE): $(P2_SRCS) $(P2_PREBUILD_DEPS) $(P2_BUILD_INFO_SCRIPT) $(P2_BUILD_CONFIG_STAMP) | $(P2_BUILD_DIR) p2-tools p2-prebuild
	$(Q) $(MAKE) p2-catalina-host TOOLCHAIN=$(TOOLCHAIN) P2_PROFILE=$(P2_PROFILE) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" CATALINA_HEAP_TOP="$(CATALINA_HEAP_TOP)" CATALINA_EXTRA_CFLAGS="$(CATALINA_EXTRA_CFLAGS)" CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)"
p2: $(P2_IMAGE)
else
p2: p2-tools p2-prebuild $(P2_BUILD_DIR) $(P2_OBJS)
	$(MSG) [Build] $(P2_IMAGE)
	$(MSG) "[P2 Silicon] $(P2_SILICON) ($(P2_CODEGEN))"
	$(Q) $(call RM_F,$(P2_IMAGE))
	$(Q) "$(FLEXCC)" $(P2_CFLAGS) -o "$(P2_IMAGE)" $(P2_OBJS)
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_IMAGE)" --max-bytes "$(P2_HUB_RAM_MAX_BYTES)" --label "FlexC P2 image"
	$(MSG) done
endif

p2-baseline-guards: p2-catalina-build-log-guard-selftest p2-profile-invariants-selftest p2-catalina-xmm-cx-sync-selftest p2-catalina-warning-audit p2-sd-write-smoke-audit p2-docs-audit p2-source-module-metadata-audit p2-example-safety-audit p2-smartpin-constants-audit p2-catalina-path-audit
	$(MSG) [Audit] P2 baseline guards complete

p2-catalina-build-log-guard-selftest:
	$(MSG) [Selftest] Catalina build-log guard
	$(Q) bash scripts/p2/check_catalina_build_log_guard.sh "$(P2_BUILD_DIR)/catalina_pipefail_selftest.log"

p2-profile-invariants-selftest:
	$(MSG) [Selftest] P2 profile invariants
	$(Q) bash scripts/p2/check_profile_invariants.sh "$(CURDIR)"

p2-catalina-xmm-cx-sync-selftest:
	$(MSG) [Selftest] Catalina XMM cx sync
	$(Q) "$(PYTHON)" scripts/p2/check_catalina_xmm_cx_sync.py --catalina-dir "$(CATALINA_DIR)"

p2-catalina-warning-audit:
	$(MSG) [Audit] Catalina warnings
	$(Q) "$(PYTHON)" scripts/p2/audit_catalina_warnings.py

p2-sd-write-smoke-audit:
	$(MSG) [Audit] P2 SD write smokes
	$(Q) "$(PYTHON)" scripts/p2/audit_sd_write_smokes.py

p2-docs-audit:
	$(MSG) [Audit] P2 docs
	$(Q) "$(PYTHON)" scripts/p2/audit_p2_docs.py

p2-source-module-metadata-audit:
	$(MSG) [Audit] P2 source module metadata
	$(Q) "$(PYTHON)" scripts/p2/audit_source_module_metadata.py

p2-example-safety-audit:
	$(MSG) [Audit] P2 example safety
	$(Q) "$(PYTHON)" scripts/p2/audit_example_safety.py

p2-smartpin-constants-audit:
	$(MSG) [Audit] P2 smart-pin constants
	$(Q) CATALINA_DIR="$(or $(CATALINA_DIR),../Catalina)" "$(PYTHON)" scripts/p2/audit_smartpin_constants.py

p2-catalina-path-audit:
	$(MSG) [Audit] P2 Catalina paths
	$(Q) "$(PYTHON)" scripts/p2/audit_catalina_paths.py

p2-minimal:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" P2_PROFILE=minimal P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=

p2-full:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" P2_PROFILE=full P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=

p2-edge32:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-edge32-ram:
	$(Q) $(MAKE) p2-ram TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-edge32-flash:
	$(Q) $(MAKE) p2-flash TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-edge32-xmm:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-xmm:
	$(Q) $(MAKE) p2-edge32-xmm

p2-xmm-tools:
	$(MSG) [XMM Tools] Catalina payload and USB serial loader
	$(Q) bash "$(P2_XMM_TOOLS_SCRIPT)" "$(CATALINA_DIR)" "$(P2_XMM_HOST_DIR)" "$(P2_XMM_LOADER_DIR)"
	$(MSG) done

p2-edge32-xmm-run:
	$(Q) $(MAKE) p2-xmm-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-xmm-run: p2-edge32-xmm-run

p2-xmm-load: $(P2_IMAGE) p2-xmm-tools $(P2_XMM_PAYLOAD_RUNNER)
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-xmm-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash "$(P2_XMM_PAYLOAD_RUNNER)" "$(P2_XMM_PAYLOAD)" "$(PORT)" "$(P2_BAUD)" "$(P2_XMM_LOADER_IMAGE)" "$(P2_IMAGE)" $(P2_XMM_PAYLOAD_FLAGS)

ifeq ($(TOOLCHAIN),catalina)
$(P2_XMM_FLASH_IMAGE): $(P2_IMAGE) $(P2_XMM_FLASH_SCRIPT) tools/p2/loader/catalina_xmm_flash_loader.c tools/p2/loader/flshboot_xmm_stage1.t tools/p2/loader/compose-catalina-xmm-flash.py | $(P2_BUILD_DIR)
	$(MSG) [XMM Flash Image] $(P2_XMM_FLASH_IMAGE)
	$(Q) P2_XMM_FLASH_LOADER_ADDR="$(P2_XMM_FLASH_LOADER_ADDR)" \
		P2_XMM_FLASH_APP_ADDR="$(P2_XMM_FLASH_APP_ADDR)" \
		PYTHON="$(PYTHON)" \
		bash "$(P2_XMM_FLASH_SCRIPT)" "$(CATALINA_DIR)" "$(P2_IMAGE)" "$(P2_XMM_FLASH_IMAGE)" "$(P2_BUILD_DIR)/xmm-flash"
	$(MSG) done
endif

p2-edge32-xmm-flash:
	$(Q) $(MAKE) p2-xmm-flash-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-xmm-flash: p2-edge32-xmm-flash

p2-xmm-flash-run:
	$(Q) $(MAKE) p2-xmm-flash-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram CATALINA_DIR="$(CATALINA_DIR)"

p2-xmm-flash-load: $(P2_XMM_FLASH_IMAGE)
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-xmm-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) if "$(LOADP2)" -h 2>&1 | grep -q -- "-FLASHRAW"; then \
		bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "-FLASHRAW" "$(P2_XMM_FLASH_IMAGE)" "$(PYTHON)"; \
	else \
		echo "[Flash] loadp2 lacks -FLASHRAW; using equivalent -HIMEM=flash raw-image path."; \
		bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "-HIMEM=flash" "$(P2_XMM_FLASH_LOAD_SPEC)" "$(PYTHON)"; \
	fi
	$(MSG) "[Flash] XMM image installed for standalone boot from SPI flash."
	$(MSG) "[Flash] For P2 Edge dev boot-from-flash use boot DIP: FLASH=ON, △=OFF, ▽=OFF"
	$(MSG) "[Flash] For P2 Edge fast flash-only boot use boot DIP: FLASH=ON, △=OFF, ▽=ON"
	$(MSG) "[Flash] Attach with: tio -b $(P2_BAUD) $(PORT)"

ifeq ($(TOOLCHAIN),catalina)
$(P2_CATALINA_FLASH_IMAGE): $(P2_IMAGE) tools/p2/loader/build-catalina-flash-image.sh | $(P2_BUILD_DIR)
	$(MSG) [Flash Image] $(P2_CATALINA_FLASH_IMAGE)
	$(Q) bash tools/p2/loader/build-catalina-flash-image.sh "$(CATALINA_DIR)" "$(P2_IMAGE)" "$(P2_CATALINA_FLASH_IMAGE)" "$(P2_BUILD_DIR)/flash"
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_CATALINA_FLASH_IMAGE)" --max-bytes "$(P2_HUB_RAM_MAX_BYTES)" --label "Catalina P2 flash-loader image" --limit-name "P2 Hub RAM limit" --hint "reduce the COMPACT profile image; the Catalina flash wrapper must also fit in Hub RAM."
	$(MSG) done
endif

p2-run: p2
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_LOAD_FLAGS)" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_LOAD_FLAGS)" "$(P2_IMAGE)" "$(PYTHON)"
endif

run: p2-run

p2-ram: p2-run

p2-attach:
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "-xTERM" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-attach TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(LOADP2)" -p "$(PORT)" -b "$(P2_BAUD)" -xTERM
endif

p2-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite full

p2-smoke-quick:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite quick

p2-smoke-examples-quick: p2-sd-examples-quick-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-quick TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-quick --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-bus: p2-sd-examples-bus-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-bus TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-bus --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-serial: p2-sd-examples-serial-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-serial TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-serial --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-smartpin-diagnostics: p2-sd-examples-smartpin-diagnostics-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-smartpin-diagnostics TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-smartpin-diagnostics --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-system: p2-sd-examples-system-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-system TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-system --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-runtime: p2-sd-examples-runtime-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-runtime TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-runtime --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-debug: p2-sd-examples-debug-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-debug TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-debug --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-wifi: p2-sd-examples-wifi-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-wifi TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-wifi --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-p2: p2-sd-examples-p2-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-p2 --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-unsupported: p2-sd-examples-unsupported-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-unsupported TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-unsupported --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-examples-core: p2-sd-examples-core-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-examples-core TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite examples-core --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-edge32:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-edge32 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite edge32

P2_FOCUSED_SMOKE_TIMEOUT ?= 300
P2_FOCUSED_SMOKE_STARTUP_TIMEOUT ?= 120

p2-sd-core-builtins-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-core-builtins-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" \
		--target-file "tests/p2/smoke_call.be=call.be" \
		--target-file "tests/p2/smoke_vararg.be=vararg.be" \
		--target-file "tests/p2/smoke_compile_module.be=cmod.be" \
		--target-file "tests/p2/smoke_conversions.be=conv.be" \
		--target-file "tests/p2/smoke_list_core.be=listcore.be" \
		--target-file "tests/p2/smoke_map_core.be=mapcore.be" \
		--target-file "tests/p2/smoke_map_keys.be=mapkeys.be" \
		--target-file "tests/p2/smoke_bytes.be=bytes.be"

p2-smoke-core-builtins-min: p2-sd-core-builtins-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-core-builtins-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite core-builtins-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-sd-file-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-sd-file-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_sd.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite sd-file-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-sd-file-core-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-file-core-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_sd_min.be"

p2-smoke-sd-file-core-min: p2-sd-file-core-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-sd-file-core-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite sd-file-core-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-sd-stdlib-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-stdlib-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_stdlib_min.be"

p2-smoke-stdlib-min: p2-sd-stdlib-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-stdlib-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite stdlib-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-sd-math-perf-min-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-math-perf-min-smoke TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --target-file "tests/p2/smoke_math_perf_min.be=mathperf.be"

p2-smoke-math-perf-min: p2-sd-math-perf-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-math-perf-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite math-perf-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-pasm-layout: p2-sd-pasm-layout-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-pasm-layout TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --command 'run_file("/tests/p2/pasmly.be")' --expect 'P2_SMOKE_PASS pasm_layout' --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-pasm-policy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-pasm-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --target-file "tests/p2/smoke_pasm_policy_min.be=pasmpol.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite pasm-policy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-p2-api: p2-sd-p2-api-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-p2-api TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite p2-api --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-debug-capabilities-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-debug-capabilities-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite debug-capabilities-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-p2compat: p2-sd-p2compat-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-p2compat TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite p2compat --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-libraries-lazy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-libraries-lazy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_libraries_lazy_min.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite libraries-lazy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-p2mem-policy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-p2mem-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2mem.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite p2mem-policy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-p2mem-native-cache-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-p2mem-native-cache-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite p2mem-native-cache-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)" --wake-start

p2-smoke-bec-fallback-min: p2-sd-bec-fallback-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-bec-fallback-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite bec-fallback-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-bec-abi-min: p2-sd-bec-abi-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-bec-abi-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite bec-abi-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-cog-closure: p2-sd-cog-closure-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-cog-closure TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite cog-closure --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-cog-closure-min: p2-sd-cog-closure-min-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-cog-closure-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite cog-closure-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-cog-policy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-cog-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_cog_policy_min.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite cog-policy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-task: p2-sd-task-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-task TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite task --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-task-policy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-task-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2ipc.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite task-policy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-ipc: p2-sd-ipc-smoke
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-ipc TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite p2ipc --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-ipc-policy-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-ipc-policy-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2ipc.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite ipc-policy-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority1:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority1-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-sd-file-core-min TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-stdlib-min TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority1-staged:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority1 --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority2:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-p2-api TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-focused TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority2-staged:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority2-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority2 --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-priority3:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority3 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-pasm-layout TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-pasm-policy-min TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority3-staged:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority3-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority3 --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority4:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority4 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-p2compat TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-cog-closure-min TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-task-policy-min TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-ipc TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority1-4:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1-4 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-priority1 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-priority2 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-priority3 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-priority4 TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority1-4-staged:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1-4-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority1-4 --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-priority1-4-min:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1-4-min TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/libstore.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2ipc.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_sd_min.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_stdlib_min.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_libraries_lazy_min.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority1-4-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-priority1-4-min-staged:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-priority1-4-min-staged TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite priority1-4-min --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

P2_SMARTPINS_TIMEOUT ?= 300
P2_SMARTPINS_STARTUP_TIMEOUT ?= 120

p2-smoke-smartpins:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-smartpins-loopback TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-normal-pin TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-counter-modes TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-output-modes TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-adc-dac-native TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-quadrature-motion TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-async-rx TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-sync-diag TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-focused:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-focused TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-smoke-smartpins-normal-pin TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-counter-modes TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-output-modes TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-adc-dac-native TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-quadrature-motion TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_FOCUSED_SMOKE_TIMEOUT="$(P2_FOCUSED_SMOKE_TIMEOUT)" P2_FOCUSED_SMOKE_STARTUP_TIMEOUT="$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-async-rx TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"
	$(Q) $(MAKE) p2-smoke-smartpins-sync-diag TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)" P2_SMARTPINS_TIMEOUT="$(P2_SMARTPINS_TIMEOUT)" P2_SMARTPINS_STARTUP_TIMEOUT="$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-loopback:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-loopback TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_loopback.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-loopback --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-normal-pin:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-normal-pin TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_normal_pin.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-normal-pin --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-quadrature-static:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-quadrature-static TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2smart.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_quadrature_static.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-quadrature-static --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-quadrature-motion:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-quadrature-motion TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_quadrature_motion.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-quadrature-motion --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-quadrature-diag:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-quadrature-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2smart.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-quadrature-diag --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-counter-modes:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-counter-modes TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_counter_modes.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-counter-modes --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-counter-timer-matrix:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-counter-timer-matrix TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_counter_timer_matrix.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-counter-timer-matrix --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-output-modes:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-output-modes TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_output_modes.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-output-modes --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-adc-dac-diag:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-adc-dac-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2smart.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-adc-dac-diag --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-adc-dac-native:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-adc-dac-native TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_adc_dac_native.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-adc-dac-native --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-adc-variant-matrix:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-adc-variant-matrix TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_adc_variant_matrix.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-adc-variant-matrix --timeout "$(P2_FOCUSED_SMOKE_TIMEOUT)" --startup-timeout "$(P2_FOCUSED_SMOKE_STARTUP_TIMEOUT)"

p2-smoke-smartpins-nco-duty-diag:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-nco-duty-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --chunk-body 160 --target-dir "/modules" --file "modules/p2smart.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-nco-duty-diag --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-async-rx:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-async-rx TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_async_rx.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-async-rx --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-async-buffer-boundary:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-async-buffer-boundary TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_async_buffer_boundary.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-async-buffer-boundary --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

p2-smoke-smartpins-sync-diag:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-smartpins-sync-diag TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_upload.py --port "$(PORT)" --baud "$(P2_BAUD)" --target-dir "/tests/p2" --file "tests/p2/smoke_smartpins_sync_diag.be"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite smartpins-sync-diag --timeout "$(P2_SMARTPINS_TIMEOUT)" --startup-timeout "$(P2_SMARTPINS_STARTUP_TIMEOUT)"

TEST_P2_BOARD ?= $(if $(BOARD),$(BOARD),$(P2_BOARD))
TEST_P2_SUITE ?= $(if $(filter p2edge32,$(TEST_P2_BOARD)),edge32,full)
SOAK_P2_SUITE ?= soak
SOAK_P2_TIMEOUT ?= 700
SOAK_P2_STARTUP_TIMEOUT ?= 120
HOURS ?= 1

test-p2:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make test-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge|p2edge32"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-sd-sync TOOLCHAIN=catalina CATALINA_DIR="$(CATALINA_DIR)" PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite "$(TEST_P2_SUITE)"

soak-p2:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make soak-p2 TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0 BOARD=p2edge|p2edge32 HOURS=1 [SOAK_P2_SUITE=soak|soak-smartpins-focused|soak-smartpins]"; \
		exit 1; \
	fi
		$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite "$(SOAK_P2_SUITE)" --duration-sec "$$("$(PYTHON)" -c 'import sys; print(float(sys.argv[1]) * 3600.0)' "$(HOURS)") --timeout "$(SOAK_P2_TIMEOUT)" --startup-timeout "$(SOAK_P2_STARTUP_TIMEOUT)"

p2-stop:
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) -Command "Get-CimInstance Win32_Process | Where-Object { \$_.Name -match 'loadp2' -and \$_.CommandLine -match [regex]::Escape('$(PORT)') } | ForEach-Object { Write-Host ('[Loader] stopping stale loadp2 on $(PORT) (pid ' + \$_.ProcessId + ')'); Stop-Process -Id \$_.ProcessId -Force -ErrorAction SilentlyContinue }"
else
	$(Q) if [ -n "$(PORT)" ]; then \
		PIDS="$$(lsof -t "$(PORT)" 2>/dev/null || true)"; \
		PIDS="$$(printf '%s' "$$PIDS" | tr '\n' ' ')"; \
		for pid in $$PIDS; do \
			cmd="$$(ps -p "$$pid" -o command= 2>/dev/null || true)"; \
			case "$$cmd" in \
				*loadp2*" $(PORT) "*|*loadp2*"$(PORT)"*|*proploader*" $(PORT) "*|*proploader*"$(PORT)"*|*serial_terminal.py*" $(PORT) "*|*serial_terminal.py*"$(PORT)"*|*repl_smoke.py*" $(PORT) "*|*repl_smoke.py*"$(PORT)"*|*tio*" $(PORT) "*|*tio*"$(PORT)"*) \
					echo "[Loader] stopping stale terminal on $(PORT) (pid $$pid)"; \
					kill -CONT "$$pid" 2>/dev/null || true; \
					kill "$$pid" 2>/dev/null || true; \
					;; \
			esac; \
		done; \
	else \
		echo "error: PORT is not set"; \
		exit 1; \
	fi
endif

ifeq ($(TOOLCHAIN),catalina)
p2-flash: $(P2_CATALINA_FLASH_IMAGE)
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "-t" -Image "$(P2_CATALINA_FLASH_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" tools/p2/loader/catalina_flash_program.py --loadp2 "$(LOADP2)" --port "$(PORT)" --baud "$(P2_BAUD)" --image "$(P2_CATALINA_FLASH_IMAGE)"
endif
else
p2-flash: p2
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_FLASH_FLAGS)" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-flash TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_FLASH_FLAGS)" "$(P2_IMAGE)" "$(PYTHON)"
endif
endif
	$(MSG) "[Flash] For P2 Edge dev boot-from-flash use boot DIP: FLASH=ON, △=OFF, ▽=OFF"
	$(MSG) "[Flash] For P2 Edge fast flash-only boot use boot DIP: FLASH=ON, △=OFF, ▽=ON"
	$(MSG) "[Flash] If the image does not appear after serial reset, power-cycle the board before attaching."
	$(MSG) "[Flash] Attach with: tio -b $(P2_BAUD) $(PORT)"

ifeq ($(TOOLCHAIN),catalina)
p2-flash-run: $(P2_CATALINA_FLASH_IMAGE)
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "-t" -Image "$(P2_CATALINA_FLASH_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-flash-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "-t" "$(P2_CATALINA_FLASH_IMAGE)" "$(PYTHON)"
endif
else
p2-flash-run: p2
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/loader/run-loadp2.ps1 -Loadp2 "$(LOADP2)" -Port "$(PORT)" -Baud "$(P2_BAUD)" -Flags "$(P2_FLASH_FLAGS) -t" -Image "$(P2_IMAGE)"
else
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-flash-run TOOLCHAIN=catalina CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_FLASH_FLAGS) -t" "$(P2_IMAGE)" "$(PYTHON)"
endif
endif

p2-serial-probe-host:
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" LCCDIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -I src -I $(P2_INCLUDE_DIR) -o "$(P2_BUILD_DIR)/serial_probe" $(P2_SERIAL_PROBE_SRCS)
	$(Q) $(PYTHON) -c "from pathlib import Path; Path(r'$(P2_SERIAL_PROBE)').write_bytes(Path(r'$(P2_BUILD_DIR)/serial_probe.bin').read_bytes())"

ifeq ($(TOOLCHAIN),catalina)
p2-serial-probe: p2-tools p2-prebuild $(P2_BUILD_DIR)
	$(MSG) [Build] $(P2_SERIAL_PROBE)
	$(Q) $(MAKE) p2-serial-probe-host TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)"
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
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_LOAD_FLAGS)" "$(P2_SERIAL_PROBE)" "$(PYTHON)"
endif

p2-clean:
	$(MSG) [Clean P2 build...]
	$(Q) $(call RM_RF,build/p2)
	$(Q) $(call RM_F,build/berry_p2.binary)
	$(Q) $(call RM_F,build/berry_p2.p2asm)
	$(Q) $(call RM_F,build/serial_probe.binary)
	$(MSG) done
