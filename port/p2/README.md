# Berry on Propeller 2

First-pass RAM-only Berry port for FlexProp / FlexC.

Build:

```sh
cd berry
make p2
```

Load to RAM:

```sh
../bin/loadp2.mac -p /dev/cu.usbserial-P2EEQZ7 build/berry_p2.binary
```

Serial console:

- Default FlexProp terminal/stdio path
- `115200 8N1` is a sensible starting point for external terminals

Expected startup:

- `Berry on Propeller 2`
- `Berry on P2`
- `berry> `

Current scope:

- RAM-only load/run
- Serial REPL over stdin/stdout
- No readline, dynamic libraries, or host filesystem support
