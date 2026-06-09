# Spin2 Module Tests

This document records the Spin2/PASM2 example suite added for Berry's P2
`spin2` module. The source reference used for feature selection was the local
`/Users/fred/Downloads/Parallax Spin2 Documentation v54.pdf` file, extracted
with `pdftotext -layout`.

## Toolchain Reality

Berry's `make spin2` path uses FlexSpin 7.6.6 from the FlexProp tool cache.
FlexSpin reports support up to `{Spin2_v52}`, while the supplied document is
v54. The suite therefore keeps committed examples build-clean under FlexSpin and
documents v53/v54-only items as coverage notes rather than uncompilable sources.

Notable v54 document items not compiled by FlexSpin 7.6.6:

- v53 `OFFSETOF(struct.member)`
- v54 byte/word/long structure-member bitfields
- v45 typed pointer declarations such as `VAR ^BYTE p`
- `REGLOAD()` / `REGEXEC()`

The examples still cover field pointers via `^@` and `FIELD[p]`, normal
variable bitfields, structures, tasks, DITTO, DEBUG gating, and the v52
floating-point/log/endian helpers.

## Build Validation

Primary validation command:

```sh
make spin2 TOOLCHAIN=catalina CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

Temporary RAM SD-loader build:

```sh
make spin2-sd-loader TOOLCHAIN=catalina \
 CATALINA_DIR=/Users/fred/Documents/Code/catalina-speccy88
```

Direct hardware transfer requires a connected P2 serial port:

```sh
make spin2-sd-put TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX \
 SPIN2_SD_FILE=spin2/build/MB_01ALU.BIN

make spin2-sd-sync TOOLCHAIN=catalina PORT=/dev/cu.usbserial-XXXX
```

`make spin2` writes uppercase DOS 8.3 binaries to `spin2/build/*.BIN`, records
the source-to-binary mapping in `spin2/build/MANIFEST.TXT`, and moves FlexSpin
`.p2asm` listings to `spin2/build/p2asm`.

`spin2-sd-sync` transfers every `spin2/build/*.BIN` to `/spin2` and writes
`/spin2/INDEX.TXT`.

## Spin2 Feature Examples

The `s2_*.spin2` files are intentionally small and heavily commented. They are
compiled to prove FlexSpin coverage. Their high-level FlexSpin binaries are not
Berry mailbox services and are not relocatable when loaded from Berry's heap,
because FlexSpin emits absolute Hub-address references for standalone images.
The runtime guard test expects `spin2.start()` to raise `value_error` for those
images instead of launching a cog that can hang the board. The bundled
high-level `S2_*.BIN` examples are refused before file load; the loader also
detects the normal FlexSpin high-level boot layout for other binaries. Raw
standalone PASM images without that boot layout may still run as
`abi == "standalone"` with `PTRA == nil`. These files should not be treated as
`spin2.call()` tests.

```text
s2_01con CON numeric, binary, character, float constants
s2_02enum enumerated constants
s2_03str STRING, @"...", LSTRING, BYTE/WORD/LONG literal data methods
s2_04var BYTE/WORD/LONG VAR arrays
s2_05bits variable indexes, size overrides, bitfields
s2_06expr integer operators, shifts, rotates, ternary
s2_07flow IF/IFNOT/ELSEIF/ELSE
s2_08case CASE and CASE_FAST
s2_09loop REPEAT forms, NEXT, QUIT
s2_10meth PUB/PRI parameters, returns, locals
s2_11multi multiple return values and ignored assignments
s2_12send SEND method pointer
s2_13recv RECV method pointer
s2_14obj OBJ child with parameter overrides
s2_chld child object used by s2_14obj
s2_15stru basic STRUCT and SIZEOF
s2_16nest nested STRUCT arrays
s2_17fld ^@ field pointers and FIELD[p][i]
s2_18mem BYTEFILL/BYTEMOVE/BYTESWAP/BYTECOMP/ENDIANW/ENDIANL
s2_19fpm float dot operators, POW, LOG2, EXP2
s2_20task TASKSPIN/TASKNEXT/TASKCHK/TASKSTOP
s2_21prep #DEFINE/#IFDEF/#IFNDEF
s2_22dbg DEBUG_DISABLE, DEBUG_MASK, DEBUG[bit]
s2_23pin pinfields and GPIO helpers
s2_24clk GETCT, WAITX, CLKFREQ, MULDIV64
s2_25pasm inline ORG, ORGH, CALL(@pasm)
s2_26dat DAT BYTE/WORD/LONG, BYTEFIT/WORDFIT, ALIGNW/ALIGNL
s2_27dit DAT/PASM DITTO generation
```

## PASM2 Mailbox Runtime Tests

The `mb_*.spin2` files are runnable with Berry:

```berry
import spin2

handle = spin2.start("MB_01ALU.BIN")
print(spin2.call(handle, 1, 10, 4, 0))
spin2.stop(handle)
```

Each binary has a two-entry method table. Method 0 is the shared mailbox service
and method 1 is the test. The shared service loads `argv[0..7]` into PASM
registers `arg0..arg7`, calls `berry_mbox_method_1`, and returns `result`.

```text
mb_01alu arithmetic: MOV, ADD, SUB, ADDS, SUBS, NEG, ABS
mb_02log boolean/bitwise: AND, OR, XOR, ANDN, NOT
mb_03shf shifts/rotates: SHL, SHR, ROL, ROR, REV, ZEROX, SIGNX
mb_04cmp comparisons/flags: CMP, CMPS, CMPR, CMPM, TEST
mb_05bit bit ops: BITH, BITL, BITNOT, BITZ, BITNZ
mb_06lane lane ops: GETBYTE, SETBYTE, GETWORD, SETWORD, GETNIB
mb_07mul multiply/CORDIC queue: MUL, MULS, QMUL, GETQX
mb_08div QDIV, QFRAC, QSQRT, GETQX, GETQY
mb_09cord QVECTOR, QROTATE
mb_10hub WRBYTE/RDBYTE, WRWORD/RDWORD, WRLONG/RDLONG
mb_11lut WRLUT/RDLUT
mb_12stk PUSH/POP/CALL/RET
mb_13jmp JMP, DJNF, TJZ, TJNZ
mb_14rep REP
mb_15misc ENCOD, DECOD, ONES, SPLITB, MERGEB
mb_16time GETCT, WAITX
mb_17wide ## wide immediates and LOC
mb_18pins pin instruction syntax matrix, runtime-safe return
mb_19lock LOCKNEW, LOCKTRY, LOCKREL, LOCKRET
mb_20pat event/interrupt syntax matrix, runtime-safe return
```

`examples/spin2/mailbox_suite.be` starts each `MB_*.BIN`, calls method 1 with
sample integer arguments, prints the result, and stops the cog. Hardware results
for the generated binaries are recorded in `spin2/SPIN2_BINARY_TEST_REPORT.md`.

`examples/spin2/standalone_suite.be` checks that high-level `S2_*.BIN`
images are rejected safely with `value_error`, then starts and stops the raw
standalone PASM image without invoking the mailbox call path.

## Compile-Only PASM2 Matrix

`p2instmx.spin2` parks immediately at startup and is not intended to run through
Berry. It exists to make FlexSpin assemble a broad PASM2 mnemonic matrix:

- arithmetic, compare, flag, bit, lane, alternate-source/destination helpers
- multiply, CORDIC queue, FIFO, LUT, hub-memory, stack, branch, REP/SKIP/EXECF
- counter, cog, lock, attention, pin/smart-pin, streamer, pattern, interrupt

The Spin2 language PDF references the separate Propeller 2 instruction document
for the authoritative silicon instruction catalog, so this matrix is broad
assembler coverage rather than a claim that every silicon encoding is exercised
at runtime.

## SD Loader Protocol

`make spin2-sd-put` and `make spin2-sd-sync` build
`tools/p2/sd_loader/sd_loader.c`, load it temporarily to RAM with `loadp2 -t`,
then run `tools/p2/sd_loader/spin2_sdload.py`.

The host sends ASCII-safe frames:

```text
MKDIR /spin2
PUT /spin2/MB_01ALU.BIN 268 A1B2C3D4
:001122...
END
QUIT
```

The loader writes through Catalina DOSFS, computes CRC32, deletes a failed file
on mismatch, and replies with `OK` or `ERR`.
