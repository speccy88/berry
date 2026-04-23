# P2 Tools

## Policy

This repository does not vendor full compiler distributions and does not use git submodules for P2 toolchains.

Instead:

- use an existing FlexProp or Catalina installation, or
- bootstrap a local cache under `.third_party_cache/`

## Tool Variables

- `FLEXPROP_DIR`
- `CATALINA_DIR`
- `LOADP2`

Examples:

```sh
make p2 TOOLCHAIN=flexc FLEXPROP_DIR=/opt/flexprop
make p2 TOOLCHAIN=catalina CATALINA_DIR=/opt/catalina
make p2-run TOOLCHAIN=flexc PORT=/dev/ttyUSB0 LOADP2=/opt/flexprop/bin/loadp2
```

## Bootstrap Helpers

Linux or macOS:

- `tools/p2/bootstrap/fetch-flexprop-tools.sh`
- `tools/p2/bootstrap/fetch-catalina-tools.sh`

Windows PowerShell:

- `tools/p2/bootstrap/fetch-flexprop-tools.ps1`
- `tools/p2/bootstrap/fetch-catalina-tools.ps1`

Bootstrap expectations:

- FlexProp shell bootstrap fetches into the requested cache directory.
- FlexProp PowerShell bootstrap uses `FLEXPROP_ZIP_URL` if it needs to download a release archive.
- Catalina shell and PowerShell bootstrap helpers use an existing installation when present, or clone from `CATALINA_REPO` when that environment variable is supplied.

## Loader Helpers

- `tools/p2/loader/run-loadp2.sh`
- `tools/p2/loader/run-loadp2.ps1`
- `tools/p2/loader/build-catalina-flash-image.sh`
- `tools/p2/loader/catalina_flash_program.py`

These wrapper scripts keep `make p2-run` simpler and keep loader handling out of the root build logic.

For Catalina `make p2-flash`, the loader flow is intentionally different from FlexC: the build first wraps `berry_p2.binary` with Catalina's `target/p2/flshload.t` flash programmer, then loads that temporary programmer with `loadp2 -t`. This is required for reliable P2 Edge boot-from-flash behavior.
