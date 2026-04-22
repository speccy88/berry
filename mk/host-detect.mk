ifeq ($(OS),Windows_NT)
HOST_OS := windows
PYTHON ?= py -3
PWSH ?= powershell -ExecutionPolicy Bypass -File
HOST_PATHSEP := ;
HOST_NULL := NUL
else
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
HOST_OS := linux
else ifeq ($(UNAME_S),Darwin)
HOST_OS := darwin
else
HOST_OS := unix
endif
PYTHON ?= python3
PWSH ?= pwsh -File
HOST_PATHSEP := :
HOST_NULL := /dev/null
endif

define MKDIR_P
$(PYTHON) -c "from pathlib import Path; Path(r'''$1''').mkdir(parents=True, exist_ok=True)"
endef

define RM_RF
$(PYTHON) -c "from pathlib import Path; import shutil; p=Path(r'''$1'''); shutil.rmtree(p, ignore_errors=True) if p.exists() else None"
endef

define RM_F
$(PYTHON) -c "from pathlib import Path; p=Path(r'''$1'''); p.unlink() if p.exists() else None"
endef
