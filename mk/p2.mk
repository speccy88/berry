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
P2_CATALINA_DOCKER_SCRIPT := scripts/build-p2-catalina-docker.sh
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
else
$(error Unsupported P2_PROFILE '$(P2_PROFILE)'; use minimal, full, edge32, or xmm)
endif

P2_PROFILE_DEFINE := -DBE_P2_PROFILE=$(P2_PROFILE_ID)
P2_DIRECT_SD_DEFINE ?=

ifeq ($(P2_BOARD),auto)
ifneq ($(filter edge32 xmm,$(P2_PROFILE)),)
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

ifneq ($(filter edge32 xmm,$(P2_PROFILE)),)
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

ifeq ($(P2_PROFILE),xmm)
ifeq ($(findstring -C PSRAM,$(CATALINA_CONFIG_FLAGS)),)
override CATALINA_CONFIG_FLAGS += -C PSRAM
endif
endif

ifeq ($(TOOLCHAIN),catalina)
P2_DIRECT_SD_DEFINE := -D__BERRY_P2_DIRECT_SD_IO
ifeq ($(findstring -C BERRY_P2_DIRECT_SD_IO,$(CATALINA_CONFIG_FLAGS)),)
override CATALINA_CONFIG_FLAGS += -C BERRY_P2_DIRECT_SD_IO
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
	$(P2_RUNTIME_DIR)/p2_heap.c \
	$(P2_RUNTIME_DIR)/p2_smartserial.c
P2_OVERRIDE_SRCS := \
	$(P2_OVERRIDES_DIR)/be_modtab_p2.c \
	$(P2_OVERRIDES_DIR)/be_libs_p2.c \
	$(P2_OVERRIDES_DIR)/be_introspectlib_p2.c \
	$(P2_OVERRIDES_DIR)/libc_compat.c
ifneq ($(P2_PROFILE),minimal)
P2_OVERRIDE_SRCS += \
	$(P2_OVERRIDES_DIR)/be_i2clib_p2.c \
	$(P2_OVERRIDES_DIR)/be_p2lib_p2.c \
	$(P2_OVERRIDES_DIR)/be_prop2lib.c \
	$(P2_OVERRIDES_DIR)/be_rtoslib_p2.c \
	$(P2_OVERRIDES_DIR)/be_spilib_p2.c
ifeq ($(P2_COMPILE_ARCHIVED_SPIN2),1)
P2_OVERRIDE_SRCS += $(P2_OVERRIDES_DIR)/be_spin2lib_p2.c
endif
ifeq ($(P2_COMPILE_ARCHIVED_WORKER),1)
P2_OVERRIDE_SRCS += $(P2_OVERRIDES_DIR)/be_workerlib_p2.c
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

.PHONY: p2 p2-minimal p2-full p2-edge32 p2-edge32-ram p2-edge32-flash p2-edge32-xmm p2-xmm p2-xmm-tools p2-edge32-xmm-run p2-xmm-run p2-xmm-load p2-edge32-xmm-flash p2-xmm-flash p2-xmm-flash-run p2-xmm-flash-load p2-catalina-host p2-run p2-ram p2-flash p2-flash-run p2-attach p2-smoke p2-smoke-quick p2-smoke-edge32 test-p2 soak-p2 p2-stop p2-clean p2-prebuild p2-tools p2-serial-probe p2-serial-probe-host p2-serial-probe-run p2-sd-modules p2-sd-tests p2-sd-sync spin2 spin2-clean spin2-sd-loader spin2-sd-loader-host spin2-sd-put spin2-sd-sync spin2-load spin2-load-all run configure configure-reset show-config

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
	@echo "P2_LED0_PIN=$(P2_LED0_PIN)"
	@echo "P2_LED1_PIN=$(P2_LED1_PIN)"
	@echo "P2_PROFILE=$(P2_PROFILE)"
	@echo "CATALINA_PLATFORM=$(CATALINA_PLATFORM)"
	@echo "CATALINA_MODEL=$(CATALINA_MODEL)"
	@echo "CATALINA_CLIB=$(CATALINA_CLIB)"
	@echo "CATALINA_SERIAL_LIB=$(CATALINA_SERIAL_LIB)"
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
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" \
		CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" \
		"$(CATALINA)" -C99 -p2 $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) \
		$(CATALINA_CONFIG_FLAGS) -C SD -o "$(SPIN2_SD_LOADER_BASE)" "$(SPIN2_SD_LOADER_SRC)"
	$(Q) "$(PYTHON)" -c "from pathlib import Path; Path(r'$(SPIN2_SD_LOADER_IMAGE)').write_bytes(Path(r'$(SPIN2_SD_LOADER_BASE).bin').read_bytes())"
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(SPIN2_SD_LOADER_IMAGE)" --max-bytes "$(P2_HUB_RAM_MAX_BYTES)" --label "Spin2 SD loader"
	$(MSG) done

ifeq ($(CATALINA_USE_DOCKER),1)
spin2-sd-loader: $(SPIN2_SD_LOADER_SRC) p2-tools | $(P2_BUILD_DIR)
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" \
		CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" \
		CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)" \
		bash "$(P2_CATALINA_DOCKER_SCRIPT)" spin2-sd-loader-host
else
spin2-sd-loader: p2-tools spin2-sd-loader-host
endif
else
spin2-sd-loader spin2-sd-loader-host:
	@echo "error: Spin2 SD loader requires TOOLCHAIN=catalina"
	@exit 1
endif

spin2-sd-put: spin2-sd-loader
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make spin2-sd-put TOOLCHAIN=catalina PORT=/dev/ttyUSB0 SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN"; \
		exit 1; \
	fi
	@if [ -z "$(SPIN2_SD_FILE)" ]; then \
		echo "error: SPIN2_SD_FILE is not set"; \
		echo "usage: make spin2-sd-put TOOLCHAIN=catalina PORT=/dev/ttyUSB0 SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN"; \
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
		echo "usage: make spin2-sd-sync TOOLCHAIN=catalina PORT=/dev/ttyUSB0"; \
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
		echo "usage: make p2-sd-modules TOOLCHAIN=catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/modules" --recursive-directory "modules"

p2-sd-tests:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-sd-tests TOOLCHAIN=catalina PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" "$(P2_REPL_UPLOAD)" --port "$(PORT)" --baud "$(P2_BAUD)" \
		--target-dir "/tests/p2" --recursive-directory "tests/p2"

p2-sd-sync:
	$(Q) $(MAKE) p2-sd-modules TOOLCHAIN=catalina PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) $(MAKE) p2-sd-tests TOOLCHAIN=catalina PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"

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
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
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
	$(Q) CMD='CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" "$(CATALINA)" -C99 -p2 $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) $(if $(CATALINA_HEAP_TOP),-H$(CATALINA_HEAP_TOP),) $(CATALINA_EXTRA_CFLAGS) $(CATALINA_CONFIG_FLAGS) -I src -I $(P2_BUILD_DIR) -I $(P2_INCLUDE_DIR) -o "$(P2_CATALINA_BASE)" $(P2_SRCS)'; \
		bash -lc "set -o pipefail; $$CMD 2>&1 | tee '$(P2_BUILD_INFO_LOG)'"
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_CATALINA_BASE).bin" --max-bytes "$(P2_IMAGE_MAX_BYTES)" --label "$(P2_IMAGE_SIZE_LABEL)" --limit-name "$(P2_IMAGE_LIMIT_NAME)"
	$(Q) "$(PYTHON)" "$(P2_BUILD_INFO_SCRIPT)" --log "$(P2_BUILD_INFO_LOG)" --binary "$(P2_CATALINA_BASE).bin" --header "$(P2_BUILD_INFO_HEADER).tmp"
	$(Q) if ! cmp -s "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; then \
		mv "$(P2_BUILD_INFO_HEADER).tmp" "$(P2_BUILD_INFO_HEADER)"; \
		CMD='CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" CATALINA_INCLUDE="$(CATALINA_INCLUDEDIR)" CATALINA_TARGET="$(CATALINA_TARGETDIR)" CATALINA_LIBRARY="$(CATALINA_DIR)" PATH="$(CATALINA_BINDIR)$(HOST_PATHSEP)$$PATH" "$(CATALINA)" -C99 -p2 $(P2_PROFILE_DEFINE) $(P2_DIRECT_SD_DEFINE) $(CATALINA_CLIB) $(CATALINA_SERIAL_LIB) $(CATALINA_MLIB) $(if $(CATALINA_HEAP_TOP),-H$(CATALINA_HEAP_TOP),) $(CATALINA_EXTRA_CFLAGS) $(CATALINA_CONFIG_FLAGS) -I src -I $(P2_BUILD_DIR) -I $(P2_INCLUDE_DIR) -o "$(P2_CATALINA_BASE)" $(P2_SRCS)'; \
		bash -lc "set -o pipefail; $$CMD 2>&1 | tee '$(P2_BUILD_INFO_LOG)'"; \
	else \
		rm -f "$(P2_BUILD_INFO_HEADER).tmp"; \
	fi
	$(Q) "$(PYTHON)" "$(P2_IMAGE_SIZE_CHECK)" --image "$(P2_CATALINA_BASE).bin" --max-bytes "$(P2_IMAGE_MAX_BYTES)" --label "$(P2_IMAGE_SIZE_LABEL)" --limit-name "$(P2_IMAGE_LIMIT_NAME)"
	$(Q) $(PYTHON) -c "from pathlib import Path; Path(r'$(P2_IMAGE)').write_bytes(Path(r'$(P2_CATALINA_BASE).bin').read_bytes())"
	$(MSG) done

ifeq ($(CATALINA_USE_DOCKER),1)
$(P2_IMAGE): $(P2_SRCS) $(P2_PREBUILD_DEPS) $(P2_CATALINA_DOCKER_SCRIPT) $(P2_BUILD_INFO_SCRIPT) $(P2_BUILD_CONFIG_STAMP) | $(P2_BUILD_DIR) p2-tools p2-prebuild
	$(Q) CATALINA_DIR="$(CATALINA_DIR)" FLEXPROP_DIR="$(FLEXPROP_DIR)" \
		CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" \
		CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" \
		P2_PROFILE="$(P2_PROFILE)" \
		CATALINA_HEAP_TOP="$(CATALINA_HEAP_TOP)" \
		CATALINA_EXTRA_CFLAGS="$(CATALINA_EXTRA_CFLAGS)" \
		CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)" \
		bash "$(P2_CATALINA_DOCKER_SCRIPT)" p2-catalina-host
else
$(P2_IMAGE): $(P2_SRCS) $(P2_PREBUILD_DEPS) $(P2_BUILD_INFO_SCRIPT) $(P2_BUILD_CONFIG_STAMP) | $(P2_BUILD_DIR) p2-tools p2-prebuild
	$(Q) $(MAKE) p2-catalina-host TOOLCHAIN=$(TOOLCHAIN) P2_PROFILE=$(P2_PROFILE) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" CATALINA_HEAP_TOP="$(CATALINA_HEAP_TOP)" CATALINA_EXTRA_CFLAGS="$(CATALINA_EXTRA_CFLAGS)" CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)"
endif
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

p2-minimal:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=minimal P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=

p2-full:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=full P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=

p2-edge32:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-edge32-ram:
	$(Q) $(MAKE) p2-ram TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-edge32-flash:
	$(Q) $(MAKE) p2-flash TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-edge32-xmm:
	$(Q) $(MAKE) p2 TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-xmm:
	$(Q) $(MAKE) p2-edge32-xmm

p2-xmm-tools:
	$(MSG) [XMM Tools] Catalina payload and USB serial loader
	$(Q) bash "$(P2_XMM_TOOLS_SCRIPT)" "$(CATALINA_DIR)" "$(P2_XMM_HOST_DIR)" "$(P2_XMM_LOADER_DIR)"
	$(MSG) done

p2-edge32-xmm-run:
	$(Q) $(MAKE) p2-xmm-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-xmm-run: p2-edge32-xmm-run

p2-xmm-load: $(P2_IMAGE) p2-xmm-tools $(P2_XMM_PAYLOAD_RUNNER)
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-xmm-run PORT=/dev/ttyUSB0"; \
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
	$(Q) $(MAKE) p2-xmm-flash-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-xmm-flash: p2-edge32-xmm-flash

p2-xmm-flash-run:
	$(Q) $(MAKE) p2-xmm-flash-load TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=-lpsram

p2-xmm-flash-load: $(P2_XMM_FLASH_IMAGE)
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-xmm-flash PORT=/dev/ttyUSB0"; \
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
		echo "usage: make p2-attach PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(LOADP2)" -p "$(PORT)" -b "$(P2_BAUD)" -xTERM
endif

p2-smoke:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite full

p2-smoke-quick:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-quick PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite quick

p2-smoke-edge32:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make p2-smoke-edge32 PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite edge32

TEST_P2_BOARD ?= $(if $(BOARD),$(BOARD),$(P2_BOARD))
TEST_P2_SUITE ?= $(if $(filter p2edge32,$(TEST_P2_BOARD)),edge32,full)
HOURS ?= 1

test-p2:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make test-p2 PORT=/dev/ttyUSB0 BOARD=p2edge|p2edge32"; \
		exit 1; \
	fi
	$(Q) $(MAKE) p2-sd-sync TOOLCHAIN=catalina PORT="$(PORT)" P2_BAUD="$(P2_BAUD)"
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite "$(TEST_P2_SUITE)"

soak-p2:
	@if [ -z "$(PORT)" ]; then \
		echo "error: PORT is not set"; \
		echo "usage: make soak-p2 PORT=/dev/ttyUSB0 BOARD=p2edge|p2edge32 HOURS=1"; \
		exit 1; \
	fi
	$(Q) "$(PYTHON)" scripts/p2/repl_smoke.py --port "$(PORT)" --baud "$(P2_BAUD)" --suite "$(TEST_P2_SUITE)" --duration-sec "$$("$(PYTHON)" -c 'import sys; print(float(sys.argv[1]) * 3600.0)' "$(HOURS)")"

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
		echo "usage: make p2-flash TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
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
		echo "usage: make p2-flash TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
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
		echo "usage: make p2-flash-run TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
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
		echo "usage: make p2-flash-run TOOLCHAIN=$(TOOLCHAIN) PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_FLASH_FLAGS) -t" "$(P2_IMAGE)" "$(PYTHON)"
endif
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
		CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" \
		CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)" \
		bash "$(P2_CATALINA_DOCKER_SCRIPT)" p2-serial-probe-host
else
	$(Q) $(MAKE) p2-serial-probe-host TOOLCHAIN=$(TOOLCHAIN) CATALINA_DIR=$(CATALINA_DIR) FLEXPROP_DIR=$(FLEXPROP_DIR) CATALINA_PLATFORM="$(CATALINA_PLATFORM)" CATALINA_MODEL="$(CATALINA_MODEL)" CATALINA_CLIB="$(CATALINA_CLIB)" CATALINA_SERIAL_LIB="$(CATALINA_SERIAL_LIB)" CATALINA_MLIB="$(CATALINA_MLIB)" CATALINA_CONFIG_FLAGS="$(CATALINA_CONFIG_FLAGS)"
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
	$(Q) bash tools/p2/loader/run-loadp2.sh "$(LOADP2)" "$(PORT)" "$(P2_BAUD)" "$(P2_LOAD_FLAGS)" "$(P2_SERIAL_PROBE)" "$(PYTHON)"
endif

p2-clean:
	$(MSG) [Clean P2 build...]
	$(Q) $(call RM_RF,build/p2)
	$(Q) $(call RM_F,build/berry_p2.binary)
	$(Q) $(call RM_F,build/berry_p2.p2asm)
	$(Q) $(call RM_F,build/serial_probe.binary)
	$(MSG) done
