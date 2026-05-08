# Repository Instructions

## Propeller 2 Builds

- Use Catalina as the preferred and verified toolchain for compiling Berry on Propeller 2.
- Default to commands such as `make p2 TOOLCHAIN=catalina` or the configured equivalents `make p2`, `make p2-ram`, and `make p2-flash` after `make configure TOOLCHAIN=catalina ...`.
- Do not spend time trying to compile Berry with FlexC unless the user explicitly asks for FlexC work. The old FlexC build path remains in the tree for historical/debugging purposes, but Catalina is the path that works well and should be used for normal validation.
- Before claiming P2 build success, prefer the Catalina Docker/source-built cache path that is already verified in this repo:

```sh
make p2 TOOLCHAIN=catalina CATALINA_USE_DOCKER=1 CATALINA_DIR=.third_party_cache/catalina-v8.8.9-build
```

- The normal P2 Edge target is the no-PSRAM board profile: `CATALINA_MODEL=COMPACT`, `CATALINA_CLIB=-lcx`, and no `-lpsram`. Pins 56 and 57 are LEDs on that board, and the COMPACT image still fits the `p2-ram` Hub RAM path.
- Only use `CATALINA_MODEL=COMPACT CATALINA_SERIAL_LIB=-lpsram` when the user explicitly wants a PSRAM P2 Edge build; that profile reserves pins 40..57 for the memory interface, including pin 57 as PSRAM chip-select.
- P2 app images are guarded against the 512 KiB Hub RAM limit. If `scripts/check-p2-image-size.py` rejects a build, do not bypass it for `p2-ram`; fix the profile or reduce the image.
