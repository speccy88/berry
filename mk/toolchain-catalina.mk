CATALINA_DIR ?= ../Catalina
CATALINA_BINDIR ?= $(CATALINA_DIR)/bin
CATALINA_INCLUDEDIR ?= $(CATALINA_DIR)/include
CATALINA_TARGETDIR ?= $(CATALINA_DIR)/target
CATALINA_LIBDIR ?= $(CATALINA_DIR)/lib
CATALINA_PLATFORM ?= P2_EDGE
CATALINA_MODEL ?= COMPACT
CATALINA_CLIB ?= -lcx
CATALINA_SERIAL_LIB ?=
CATALINA_MLIB ?= -lm
CATALINA_CONFIG_FLAGS ?= -C $(CATALINA_PLATFORM) -C $(CATALINA_MODEL) -C SIMPLE -C VT100 -C NO_ARGS

ifeq ($(HOST_OS),windows)
CATALINA ?= $(CATALINA_BINDIR)/catalina.exe
CATALINA_LCC ?= $(CATALINA_BINDIR)/lcc.exe
FLEXSPIN ?= $(FLEXPROP_DIR)/bin/flexspin.exe
LOADP2 ?= $(FLEXPROP_DIR)/bin/loadp2.exe
else
CATALINA ?= $(CATALINA_BINDIR)/catalina
CATALINA_LCC ?= $(CATALINA_BINDIR)/lcc
FLEXSPIN ?= $(FLEXPROP_DIR)/bin/flexspin
LOADP2_DEFAULT := $(or $(shell command -v loadp2 2>/dev/null),$(FLEXPROP_DIR)/bin/loadp2)
LOADP2 ?= $(LOADP2_DEFAULT)
endif

P2_IMAGE := $(P2_BUILD_DIR)/berry_p2.binary
P2_CATALINA_BASE := $(P2_BUILD_DIR)/berry_p2
P2_CATALINA_FLASH_IMAGE := $(P2_BUILD_DIR)/berry_p2_flash_loader.binary
P2_TOOLCHAIN_INCFLAGS := -I"$(CATALINA_INCLUDEDIR)"
P2_BAUD ?= 230400

.PHONY: p2-tools-catalina

p2-tools-catalina:
	$(MSG) [Tools] Catalina
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) -Command "foreach ($$p in @('$(CATALINA)', '$(CATALINA_LCC)', '$(CATALINA_INCLUDEDIR)', '$(CATALINA_TARGETDIR)', '$(CATALINA_LIBDIR)')) { if (-not (Test-Path $$p)) { Write-Error \"Catalina component not found at $$p. Set CATALINA_DIR to the sibling Catalina checkout, normally ../Catalina.\" } }"
else
	$(Q) for path in "$(CATALINA)" "$(CATALINA_LCC)" "$(CATALINA_INCLUDEDIR)" "$(CATALINA_TARGETDIR)" "$(CATALINA_LIBDIR)"; do \
		if [ ! -e "$$path" ]; then \
			echo "error: Catalina component not found at $$path" >&2; \
			echo "Set CATALINA_DIR to the sibling Catalina checkout, normally ../Catalina." >&2; \
			exit 1; \
		fi; \
	done
	$(Q) test -x "$(CATALINA)" && test -x "$(CATALINA_LCC)" || { echo "error: Catalina compiler tools are not executable under $(CATALINA_BINDIR)" >&2; exit 1; }
endif
