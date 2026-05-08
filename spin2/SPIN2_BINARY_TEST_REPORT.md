# Spin2 Binary Test Report

Date: 2026-05-08
Board: Propeller 2 Edge, no PSRAM
Berry image: `Berry 1.1.0 (build May 08 2026 10:47:13)`
Runtime SD test path: `/SPT0` through `/SPT3`

## Fixes Applied Before This Run

- Build names are now forced to uppercase DOS 8.3 names by
  `tools/spin2/build_all.py`; `spin2/build` contains only `.BIN` payloads plus
  `MANIFEST.TXT`.
- FlexSpin `.p2asm` listings are moved to `spin2/build/p2asm`.
- `spin2-sd-sync` now transfers uppercase `.BIN` files, uses conservative
  serial pacing, and the RAM loader uses Catalina unmanaged file I/O.
- The mailbox service no longer checks stale Z/C flags after returning from a
  test method. This fixed `MB_04CMP.BIN`, which previously raised
  `runtime_error: spin2 method failed`.

## SD Loader Notes

All 51 binaries were transferred with CRC verification, but Catalina DOSFS
create operations failed after about 13 files in one directory during repeated
loader sessions. To complete the hardware run, the binaries were split into
fresh directories:

- `/SPT0`: first 13 manifest entries
- `/SPT1`: next 13 manifest entries
- `/SPT2`: next 13 manifest entries
- `/SPT3`: final 12 manifest entries

The older `/SPIN2` directory on this SD card also refused new file creation via
the temporary loader. That looks like a card/directory-state or DOSFS limitation,
not an 8.3 naming problem. The runtime tests below use only the freshly written
8.3 files.

## Runtime Results

| Source | Binary | Runtime test | Result | Status | Notes |
|---|---|---:|---:|---|---|
| `berry_mailbox_demo.spin2` | `MBOXDEMO.BIN` | `call(1,123,0,0)` | `123` | PASS | Echo mailbox demo. |
| `blink.spin2` | `BLINK.BIN` | `start/stop` | handle `0` | PASS | Launches and can be stopped. |
| `mb_01alu.spin2` | `MB_01ALU.BIN` | `call(1,10,4,0)` | `31` | PASS | Arithmetic PASM2 smoke. |
| `mb_02log.spin2` | `MB_02LOG.BIN` | `call(1,90,15,0)` | `-1` | PASS | Logical/bitwise smoke. |
| `mb_03shf.spin2` | `MB_03SHF.BIN` | `call(1,0,0,0)` | `0` | PASS | Shift/rotate/sign-extension smoke. |
| `mb_04cmp.spin2` | `MB_04CMP.BIN` | `call(1,5,5,0)` | `45` | PASS | Fixed by preserving method-dispatch decision before method flags change. |
| `mb_05bit.spin2` | `MB_05BIT.BIN` | `call(1,0,0,0)` | `32` | PASS | Bit instruction smoke. |
| `mb_06lane.spin2` | `MB_06LAN.BIN` | `call(1,0,0,0)` | `11163053` | PASS | Byte/word/nibble lane smoke. |
| `mb_07mul.spin2` | `MB_07MUL.BIN` | `call(1,6,7,0)` | `63` | PASS | Multiply/CORDIC queue smoke. |
| `mb_08div.spin2` | `MB_08DIV.BIN` | `call(1,100,9,0)` | `-78` | PASS | Division/fraction/sqrt queue smoke. |
| `mb_09cord.spin2` | `MB_09COR.BIN` | `call(1,1000,2000,0)` | `756809846` | PASS | CORDIC vector/rotate smoke. |
| `mb_10hub.spin2` | `MB_10HUB.BIN` | `call(1,18,13398,16909060)` | `16922476` | PASS | Hub read/write smoke. |
| `mb_11lut.spin2` | `MB_11LUT.BIN` | `call(1,21930,4660,0)` | `18334` | PASS | LUT read/write smoke. |
| `mb_12stk.spin2` | `MB_12STK.BIN` | `call(1,99,0,0)` | `111` | PASS | PUSH/POP/CALL/RET smoke. |
| `mb_13jmp.spin2` | `MB_13JMP.BIN` | `call(1,1,1,0)` | `24` | PASS | Branch/test-jump smoke. |
| `mb_14rep.spin2` | `MB_14REP.BIN` | `call(1,0,0,0)` | `15` | PASS | REP smoke. |
| `mb_15misc.spin2` | `MB_15MIS.BIN` | `call(1,0,0,0)` | `16909068` | PASS | ENCOD/DECOD/ONES/SPLITB/MERGEB smoke. |
| `mb_16time.spin2` | `MB_16TIM.BIN` | `call(1,0,0,0)` | `14` | PASS | GETCT/WAITX delta; value is timing-dependent but positive. |
| `mb_17wide.spin2` | `MB_17WID.BIN` | `call(1,0,0,0)` | `305419843` | PASS | Wide immediate/LOC smoke. |
| `mb_18pins.spin2` | `MB_18PIN.BIN` | `call(1,0,0,0)` | `18` | PASS | Runtime-safe pin syntax smoke. |
| `mb_19lock.spin2` | `MB_19LOC.BIN` | `call(1,0,0,0)` | `0` | PASS | Hardware lock smoke. |
| `mb_20pat.spin2` | `MB_20PAT.BIN` | `call(1,0,0,0)` | `20` | PASS | Event/pattern syntax smoke. |
| `p2instmx.spin2` | `P2INSTMX.BIN` | `start/stop` | handle `0` | PASS | Compile matrix also launches/stops. |
| `s2_01con.spin2` | `S2_01CON.BIN` | `start/stop` | handle returned | PARTIAL | High-level FlexSpin binary is not mailbox-callable. |
| `s2_02enum.spin2` | `S2_02ENU.BIN` | `start/stop` | handle returned | PARTIAL | High-level FlexSpin binary is not mailbox-callable. |
| `s2_03str.spin2` | `S2_03STR.BIN` | `spin2.start` | hang, rebooted | FAIL | High-level Spin2 image is not a Berry mailbox/PASM service. |
| `s2_04var.spin2` | `S2_04VAR.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_05bits.spin2` | `S2_05BIT.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_06expr.spin2` | `S2_06EXP.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_07flow.spin2` | `S2_07FLO.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_08case.spin2` | `S2_08CAS.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_09loop.spin2` | `S2_09LOO.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_10meth.spin2` | `S2_10MET.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_11multi.spin2` | `S2_11MUL.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_12send.spin2` | `S2_12SEN.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_13recv.spin2` | `S2_13REC.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_14obj.spin2` | `S2_14OBJ.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_15stru.spin2` | `S2_15STR.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_16nest.spin2` | `S2_16NES.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_17fld.spin2` | `S2_17FLD.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_18mem.spin2` | `S2_18MEM.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_19fpm.spin2` | `S2_19FPM.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_20task.spin2` | `S2_20TAS.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_21prep.spin2` | `S2_21PRE.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_22dbg.spin2` | `S2_22DBG.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_23pin.spin2` | `S2_23PIN.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_24clk.spin2` | `S2_24CLK.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_25pasm.spin2` | `S2_25PAS.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_26dat.spin2` | `S2_26DAT.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_27dit.spin2` | `S2_27DIT.BIN` | `spin2.start` | hang, rebooted | FAIL | Same high-level image incompatibility. |
| `s2_chld.spin2` | `S2_CHLD.BIN` | `spin2.start` | hang, rebooted | FAIL | Child object compile artifact, not a mailbox service. |

## Follow-Up From Failures

The `mb_*.BIN` runtime suite is now the hardware-validated test suite for
`spin2.start()` and `spin2.call()`.

The `s2_*.spin2` files remain valuable language feature examples, but their
FlexSpin-generated high-level binaries should be treated as compile artifacts
until the `spin2` module grows support for FlexSpin's full high-level program
startup ABI. Running those images as raw PASM/mailbox services is the wrong
entry convention and can hang the board.
