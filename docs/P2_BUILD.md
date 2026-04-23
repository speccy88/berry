# P2 Build

## Supported Interface

```sh
make p2 TOOLCHAIN=flexc
make p2 TOOLCHAIN=catalina
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
make p2-run TOOLCHAIN=catalina PORT=COM5
make p2-ram TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-flash TOOLCHAIN=catalina PORT=/dev/ttyUSB0
make p2-clean
make p2-tools TOOLCHAIN=flexc
make p2-tools TOOLCHAIN=catalina
make p2-prebuild
```

## Required Variables

- `TOOLCHAIN=flexc|catalina`
- `PORT=...`
- `FLEXPROP_DIR=...`
- `CATALINA_DIR=...`
- `LOADP2=...`

## Linux

Install:

- `git`
- `make`
- `python3`
- a C compiler for the host build

Examples:

```sh
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=catalina PORT=/dev/ttyUSB0 LOADP2=/opt/flexprop/bin/loadp2
```

Bootstrap-managed cache examples:

```sh
make p2-tools TOOLCHAIN=flexc FLEXPROP_DIR=.third_party_cache/flexprop
make p2-tools TOOLCHAIN=catalina CATALINA_DIR=.third_party_cache/catalina
```

Notes:

- the FlexProp shell bootstrap can fetch a cache directly on Unix-like hosts
- the Catalina shell bootstrap expects either `CATALINA_DIR` to point at an existing installation or `CATALINA_REPO` to be set for a shallow clone

## Windows PowerShell

Install:

- Git for Windows
- Python 3
- GNU Make

Recommended board port for the next session:

- `PORT=COM6`

Examples:

```powershell
make p2 TOOLCHAIN=flexc
make p2-run TOOLCHAIN=flexc PORT=COM6
make p2 TOOLCHAIN=catalina CATALINA_DIR=C:\tools\catalina
make p2-run TOOLCHAIN=catalina PORT=COM6 LOADP2=C:\tools\flexprop\bin\loadp2.exe
```

If you already have external installations, point the Make variables at them. If not, use the bootstrap helpers in `tools/p2/bootstrap/`.

Notes:

- the PowerShell FlexProp bootstrap expects either an existing `FLEXPROP_DIR` or a `FLEXPROP_ZIP_URL`
- the PowerShell Catalina bootstrap expects either an existing `CATALINA_DIR` or `CATALINA_REPO`

## Silicon Selection

Examples:

```sh
make p2 TOOLCHAIN=flexc P2_SILICON=latest
make p2 TOOLCHAIN=flexc P2_SILICON=a
make p2-run TOOLCHAIN=flexc P2_SILICON=latest PORT=COM6
```

## Output Layout

P2 outputs are written under:

```text
build/p2/<toolchain>/
```

Examples:

```text
build/p2/flexc/berry_p2.binary
build/p2/catalina/berry_p2.binary
```
