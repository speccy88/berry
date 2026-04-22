CATALINA_DIR ?= .third_party_cache/catalina
CATALINA_BINDIR ?= $(CATALINA_DIR)/bin
CATALINA_INCLUDEDIR ?= $(CATALINA_DIR)/include
CATALINA_TARGETDIR ?= $(CATALINA_DIR)/target
CATALINA_LIBDIR ?= $(CATALINA_DIR)/lib
CATALINA_PLATFORM ?= P2_EVAL
CATALINA_CLIB ?= -lci
CATALINA_SERIAL_LIB ?= -lserial2
CATALINA_MLIB ?= -lm

ifeq ($(HOST_OS),windows)
CATALINA ?= $(CATALINA_BINDIR)/catalina.exe
LOADP2 ?= $(FLEXPROP_DIR)/bin/loadp2.exe
else
CATALINA ?= $(CATALINA_BINDIR)/catalina
LOADP2 ?= $(FLEXPROP_DIR)/bin/loadp2
endif

P2_IMAGE := $(P2_BUILD_DIR)/berry_p2.binary
P2_CATALINA_BASE := $(P2_BUILD_DIR)/berry_p2
P2_TOOLCHAIN_INCFLAGS := -I"$(CATALINA_INCLUDEDIR)"
P2_BAUD ?= 230400

.PHONY: p2-tools-catalina

p2-tools-catalina:
	$(MSG) [Tools] Catalina
ifeq ($(HOST_OS),windows)
	$(Q) $(PWSH) tools/p2/bootstrap/fetch-catalina-tools.ps1 -InstallDir "$(CATALINA_DIR)"
else
	$(Q) bash tools/p2/bootstrap/fetch-catalina-tools.sh "$(CATALINA_DIR)"
endif
