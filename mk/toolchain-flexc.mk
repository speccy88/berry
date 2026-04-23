FLEXPROP_DIR ?= .third_party_cache/flexprop
FLEXPROP_BINDIR ?= $(FLEXPROP_DIR)/bin
FLEXPROP_INCLUDEDIR ?= $(FLEXPROP_DIR)/include

ifeq ($(HOST_OS),windows)
FLEXCC ?= $(FLEXPROP_BINDIR)/flexcc.exe
FLEXSPIN ?= $(FLEXPROP_BINDIR)/flexspin.exe
LOADP2 ?= $(FLEXPROP_BINDIR)/loadp2.exe
else
FLEXCC ?= $(FLEXPROP_BINDIR)/flexcc
FLEXSPIN ?= $(FLEXPROP_BINDIR)/flexspin
LOADP2 ?= $(FLEXPROP_BINDIR)/loadp2
endif

P2_IMAGE := $(P2_BUILD_DIR)/berry_p2.binary
P2_TOOLCHAIN_INCFLAGS := -I"$(FLEXPROP_INCLUDEDIR)"
P2_BAUD ?= 115200

.PHONY: p2-tools-flexc

p2-tools-flexc:
	$(MSG) [Tools] FlexProp
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/bootstrap/fetch-flexprop-tools.ps1 -InstallDir "$(FLEXPROP_DIR)"
else
	$(Q) bash tools/p2/bootstrap/fetch-flexprop-tools.sh "$(FLEXPROP_DIR)"
endif
