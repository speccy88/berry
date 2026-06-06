# PASM and Assembly Integration

## Current safe facade

`p2.asm` currently exposes safe PASM-adjacent intrinsics backed by existing native helpers:

- `p2.asm.getrnd()`
- `p2.asm.getct()`
- `p2.asm.waitx(cycles)`
- `p2.asm.hubset(value)`

This is not arbitrary assembly execution.

## Unsafe assembly policy

`BE_P2_ENABLE_UNSAFE_ASM=0/1` is the documented future gate for arbitrary assembly text, PASM blob execution, or inline assembler behavior. With the current implementation, unsafe assembly paths should remain absent or fail clearly.

## ABI rules for future PASM blobs

Future PASM blob loading must document and test:

- Argument passing.
- Return values.
- Clobbered registers.
- Hub pointer rules.
- PSRAM pointer rules.
- Cog RAM and LUT rules.
- Interrupt assumptions.
- Stack assumptions.
- Cleanup rules.

## Current status

PASM blob loading, PASM cog launching, and PASM function bridges remain open. Do not present the safe intrinsic facade as blob support.
