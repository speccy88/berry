# P2 Board Support

## Supported board profiles

| Board | Profile | LEDs | Reserved pins | Notes |
| --- | --- | --- | --- | --- |
| P2 Edge no-PSRAM | `P2_BOARD=p2edge`, `P2_PROFILE=full` | `56`, `57` | SD `58..61`, serial `62..63` | Default normal Catalina path. |
| P2 Edge 32 MB RAM | `P2_BOARD=p2edge32`, `P2_PROFILE=edge32` | `38`, `39` | PSRAM `40..57`, SD `58..61`, serial `62..63` | Uses Catalina `-lpsram` block API. |
| P2 Edge 32 MB XMM | `P2_BOARD=p2edge32`, `P2_PROFILE=xmm` | `38`, `39` | PSRAM `40..57`, SD `58..61`, serial `62..63` | Experimental LARGE/XMM profile. |

## Silicon selection

- `P2_SILICON=latest`, `b`, or `c` selects the current P2 codegen path.
- `P2_SILICON=a` selects the old silicon path.

Board pinout and silicon generation are separate choices. Do not use `P2_SILICON` to imply a board or memory layout.

## Safe default bring-up board

The normal first-validation target is the no-PSRAM P2 Edge Catalina COMPACT profile. Edge32 and XMM work should not break that path.

## Hardware assumptions

- Serial console pins `62..63` are reserved.
- SD card pins `58..61` are reserved.
- PSRAM builds reserve pins `40..57`.
- Hardware tests that touch user pins must state their pin use and skip when the pin is reserved by the selected board profile.
