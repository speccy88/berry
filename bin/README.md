# FlexProp host tools for this fork (legacy note)

The active toolchain location is now:
- `tools/flexprop/bin`
- `tools/flexprop/include`

The binaries are sourced from:
- https://github.com/totalspectrum/flexprop

Populate this folder with:

```sh
./tools/p2/fetch-flexprop-tools.sh
```

The script installs tool binaries plus matching FlexProp headers. It first tries
the latest FlexProp release zip, then falls back to building from source.

It installs these tools (when available) into `tools/flexprop/bin`:
- `flexcc.mac` / `flexcc.exe`
- `flexspin.mac` / `flexspin.exe`
- `loadp2.mac` / `loadp2.exe`
- `proploader.mac` / `proploader.exe`
- `mac_terminal.sh`

Notes:
- The `.mac` tools are for macOS.
- The `.exe` tools are for Windows.
- The script fails if required macOS tools (`flexcc.mac`, `loadp2.mac`) or
  required headers are missing.
- Downloaded binaries are local bootstrap artifacts and are not required to be committed.
