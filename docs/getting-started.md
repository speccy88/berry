# P2 Getting Started

This guide is the short path for bringing up Berry on a Propeller 2 board from this repository.

## Preferred path

Use Catalina for normal P2 work. FlexC remains in the tree for historical and debugging work, but Catalina is the verified path for this port.

```sh
make p2 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

For the verified P2 Edge 32 MB RAM board path, use the convenience target and the known serial port when available:

```sh
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

For the no-external-RAM P2 Edge profile, keep the default COMPACT Catalina setup with `CATALINA_CLIB=-lcx` and no `-lpsram`.

For the experimental huge-heap PSRAM/XMM profile on the P2 Edge 32 MB board:

```sh
make p2-xmm-flash PORT=/dev/cu.usbserial-P97cvdxp TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

Standalone XMM flash boot currently takes about `25-30` seconds before the Berry prompt. The current verified `p2.status()` output reports `15728640 B` main heap and `Berry heap in PSRAM`.

## First smoke checks

At the Berry prompt:

```berry
print(6 * 7)
import p2
print(p2.status_info())
print(p2.fs_info("/"))
import math
print(math.sqrt(81))
```

Expected current Edge32 SD result: `p2.fs_info("/")["mount_result_name"] == "ok"` and `math.sqrt(81) == 9` after `/modules/math.be` has been provisioned.

## Repeatable test entrypoints

Use these only when hardware is connected and the board is already at a stable `berry>` prompt:

```sh
make test-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32
make soak-p2 PORT=/dev/cu.usbserial-P97cvdxp BOARD=p2edge32 HOURS=1
```

These commands provision `/modules` and `/tests/p2` through the serial uploader before running the selected smoke suite.
