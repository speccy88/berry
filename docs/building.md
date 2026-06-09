# Building Berry for P2

## Toolchain policy

Catalina is the preferred and verified P2 toolchain. Use FlexC only when the task is explicitly about FlexC.

Known-good validation build:

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

## Profiles

- `P2_PROFILE=minimal`: smallest REPL-oriented profile.
- `P2_PROFILE=full`: no-PSRAM P2 Edge default profile.
- `P2_PROFILE=edge32`: P2 Edge 32 MB RAM profile using Catalina PSRAM block access.
- `P2_PROFILE=xmm`: experimental LARGE/XMM profile using PSRAM as external heap plus an upper explicit block window.

## Board selection

- `P2_BOARD=p2edge`: no-PSRAM P2 Edge pinout, LEDs on pins `56` and `57`.
- `P2_BOARD=p2edge32`: P2 Edge 32 MB RAM pinout, LEDs on pins `38` and `39`, PSRAM reserves pins `40..57`.
- `P2_BOARD=auto`: maps no-RAM profiles to `p2edge` and Edge32/XMM profiles to `p2edge32`.

## Catalina profile rules

No-PSRAM P2 Edge:

```sh
make p2 TOOLCHAIN=catalina P2_PROFILE=full P2_BOARD=p2edge CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx CATALINA_SERIAL_LIB=
```

P2 Edge 32 MB RAM block-cache profile:

```sh
make p2-edge32 TOOLCHAIN=catalina
```

XMM profile:

```sh
make p2-xmm TOOLCHAIN=catalina
```

Standalone XMM flash install uses:

```sh
make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

If the bundled `loadp2` does not support `-FLASHRAW`, the make target uses the equivalent `-HIMEM=flash @80000000=...` raw-image path.

Do not use `-lpsram` on the no-PSRAM board profile. In Catalina PSRAM profiles, pin `57` is PSRAM chip-select and cannot be treated as a user LED.

## Build and feature flags

These P2 flags are documented policy gates. A flag being documented here does not mean the underlying feature is fully implemented.

- `BE_P2_DEBUG=0/1`: reserved debug-build policy flag. Current backed debug diagnostics are available through `p2.debug`; a separate debug build mode remains open.
- `BE_P2_TRACE_IMPORTS=0/1`: reserved import-tracing flag. Import tracing should be silent by default and must not add noisy boot prints unless explicitly enabled.
- `BE_P2_TRACE_GC=0/1`: reserved GC-tracing flag. GC tracing should stay off by default because serial output can perturb memory and timing.
- `BE_P2_TRACE_COGS=0/1`: reserved cog-tracing flag. Cog tracing should report through structured diagnostics where possible.
- `BE_P2_TRACE_TASKS=0/1`: reserved task-tracing flag. Current `task` diagnostics are query based.
- `BE_P2_ENABLE_UNSAFE_ASM=0/1`: unsafe assembly gate. Current `p2.asm` exposes only safe intrinsics; arbitrary assembly text/blob execution must remain absent or fail unless this future flag is deliberately enabled.

## Image-size rule

P2 app images are guarded against the 512 KiB Hub RAM limit. Do not bypass the image-size checker for `p2-ram`; reduce the profile or implementation footprint instead.
