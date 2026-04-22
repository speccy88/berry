# FlexProp host tools for this fork

This folder is used by the Propeller 2 port build/load flow in this repository.

The binaries are sourced from:
- https://github.com/totalspectrum/flexprop

Populate this folder with:

```sh
./tools/p2/fetch-flexprop-tools.sh
```

The script first tries the latest FlexProp release zip, then falls back to
building from source if required macOS tools are not present.

It installs these tools (when available) into `./bin`:
- `flexcc.mac` / `flexcc.exe`
- `flexspin.mac` / `flexspin.exe`
- `loadp2.mac` / `loadp2.exe`
- `proploader.mac` / `proploader.exe`
- `mac_terminal.sh`

Notes:
- The `.mac` tools are for macOS.
- The `.exe` tools are for Windows.
- The script fails if required macOS tools (`flexcc.mac`, `loadp2.mac`) are missing.
- Downloaded binaries are local bootstrap artifacts and are not required to be committed.
