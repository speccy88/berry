# PASM and Assembly Integration

## Current safe facade

`p2.asm` currently exposes safe PASM-adjacent intrinsics backed by existing native helpers:

- `p2.asm.getrnd()`
- `p2.asm.getct()`
- `p2.asm.waitx(cycles)`
- `p2.asm.hubset(value)`
- `p2.asm.load(path)`
- `p2.asm.cognew(blob, arg=nil, cog=nil)`
- `p2.asm.cogstop(cog)`
- `p2.asm.cogcheck(cog)`
- `p2.asm.capabilities()`
- `p2.asm.required_capability_keys()`
- `p2.asm.abi()`
- `p2.asm.required_abi_keys()`
- `p2.asm.audit()`
- `p2.asm.audit_problems()`
- `p2.asm.audit_ok()`
- `p2.asm.marker_blob()`
- `p2.asm.launch_probe(target_cog=nil)`
- `p2.asm.launch_loaded_probe(blob, target_cog=nil)`

`p2.asm.load(path)` reads a non-empty 4-byte-aligned PASM blob file into a Berry
`bytes` object. The current focused hardware smoke verifies loading staged
`/berry/pasm/*.bin` bytes from SD.

At the source-module layer, `libstore.pasm_policy()` reports the SD storage
contract for PASM blobs: `/berry/pasm/*.bin` storage and readback are supported,
dotted names map to nested paths, and execution remains deferred to the native
`p2.asm` marker-fixture path. `libstore.pasm_info()` and
`libstore.pasm_load_result()` keep `executable == false` and
`reason == "pasm_execution_deferred"` for staged blobs.

`p2.asm.cognew()` is exposed over the existing native `_cogstart_PASM` path, but
arbitrary SD blob launch is not yet claimed safe. Its queryable policy is
`raw_cognew_policy == "low_level_existing_path_not_public_blob_abi"`. A bad
PASM image can wedge or consume a cog, so supported launch still needs a
documented ABI and broader safe fixture coverage.

`p2.asm.capabilities()` and `p2.asm.abi()` report the current contract in code:
safe intrinsics, SD loading, raw cog controls, and exact marker-fixture launch
are available; arbitrary SD blob launch, function bridges, inline assembler, and
unsafe assembly are reported unsupported with policy/reason metadata.
`p2.asm.audit()` self-checks that the duplicated policy metadata exposed through
`capabilities()` and `abi()` is still consistent. `required_capability_keys()`
and `required_abi_keys()` expose the expected metadata fields, while `audit()`
reports `missing_capability_keys` and `missing_abi_keys`; `audit_problems()` and
`audit_ok()` provide compact status for smoke tooling.

`p2.asm.launch_probe()` is the current safe launch proof. It starts a known-good
mailbox-marker PASM fixture, waits for the marker and child cog id, stops the
child cog, and returns diagnostics confirming the marker and cleanup.

`p2.asm.marker_blob()` returns that fixture as bytes. The supported SD-loaded
launch proof is:

```berry
blob = p2.asm.marker_blob()
f = open("/berry/pasm/pasm_marker.bin", "w")
f.write(blob)
f.close()

loaded = p2.asm.load("/berry/pasm/pasm_marker.bin")
result = p2.asm.launch_loaded_probe(loaded)
assert(result["ok"])
```

`launch_loaded_probe()` intentionally accepts only the exact marker fixture
bytes. Non-matching blobs fail instead of becoming arbitrary PASM execution; the
PASM layout smoke now asserts that a staged dummy blob is rejected.

`examples/pasm_direct.be` demonstrates the same safe surface for users: guarded
intrinsics, policy fields from `capabilities()` / `abi()`, and
`launch_probe()`. It also prints the policy-audit result. It deliberately
reports the unsupported arbitrary-blob and function-bridge policies instead of
trying to execute arbitrary PASM.

## Unsafe assembly policy

`BE_P2_ENABLE_UNSAFE_ASM=0/1` is the documented future gate for arbitrary
assembly text or inline assembler behavior. `p2.asm.capabilities()` and
`p2.asm.abi()` report `unsafe_gate == "BE_P2_ENABLE_UNSAFE_ASM"`,
`unsafe_default == false`, and `unsafe_module == "none"` in the default build.
Raw PASM blob launch must remain explicit and documented; it must not become
silent source execution.

Inline assembler is also explicitly unsupported in the default contract:
`inline_assembler_policy == "unsupported_no_parser_or_safety_contract"`.
The ABI metadata lists the missing parser, code-generation, clobber, label,
relocation, source-mapping, optimizer, and safety rules before inline assembly
can be considered.

## Current marker fixture ABI

The only documented launch ABI today is the built-in marker fixture used by
`launch_probe()` and `launch_loaded_probe()`:

- `status`: `marker_fixture_only`
- Entry path: `_cogstart_PASM(cog, program, mailbox)`
- Argument passing: the fixture receives a hub mailbox pointer in `PTRA`.
- Return value: there is no function-call return ABI. The child writes a marker
  and its cog id into the mailbox; the caller validates both fields.
- Cleanup: the caller stops the child cog after the marker is observed or after
  timeout handling.
- Hub pointer rule: the fixture executes from a copied hub buffer.
- PSRAM pointer rule: no PSRAM pointers are passed to the fixture.
- Cog/LUT rule: no caller-visible cog RAM or LUT state contract exists yet.
- Interrupt rule: no interrupt contract exists yet.
- Stack rule: no stack is provided to the marker fixture.

These fields are queryable from Berry through `p2.asm.abi()`. The hardware
smoke asserts `status == "marker_fixture_only"`, `argument == "mailbox pointer
in PTRA"`, and that both `arbitrary_blob_abi` and `function_bridge_abi` are
false. It also asserts the unsafe assembly gate metadata remains default-off and
that `p2.asm.audit()` reports the policy fields as internally consistent.

## ABI rules still required before arbitrary blobs

Before arbitrary SD-loaded PASM blobs can be called supported, the public ABI
must document and test the areas reported by
`p2.asm.abi()["arbitrary_blob_required"]`. The current
`p2.asm.capabilities()` and `p2.asm.abi()` report
`arbitrary_blob_policy == "unsupported_exact_marker_fixture_only"` because
these rules are not defined:

- Entry address and blob layout.
- Argument passing for integers, hub buffers, and any future structured values.
- Return values and error reporting.
- Clobbered cog registers and any preserved register set.
- Hub pointer ownership, alignment, lifetime, and bounds.
- PSRAM pointer ownership, address-window limits, and whether child cogs may use
  PSRAM pointers directly.
- Cog RAM and LUT ownership rules.
- Interrupt assumptions and whether a blob may alter interrupt state.
- Stack assumptions, including whether a stack is absent, caller-provided, or
  allocated by the launch API.
- Cleanup rules for normal return, timeout, explicit stop, and child failure.

Until this exists, non-fixture blobs should be loaded as data only or launched
only through explicit unsafe/diagnostic work.

## Function bridge status

There is no supported PASM function bridge yet. A future bridge must define a
call shape before exposing helpers such as `load_function(...)`: accepted
argument types, marshalling, return type, timeout behavior, child cog reuse,
resource cleanup, and error propagation. The current `p2.asm.abi()` reports
`function_bridge_abi == false` and
`function_bridge_policy == "unsupported_no_calling_convention"`.
`p2.asm.capabilities()["function_bridge_reason"]` and
`p2.asm.abi()["function_bridge_required"]` list the missing contract areas so
tooling can distinguish this from a hidden or partially enabled bridge.

## Current status

PASM blob loading into `bytes` is implemented through `p2.asm.load()` and
`libstore.pasm_load()`. The known-good launch path is verified through
`p2.asm.launch_probe()` and through an SD-staged exact fixture using
`p2.asm.marker_blob()` plus `p2.asm.launch_loaded_probe()`. The current ABI and
capability state is queryable through `p2.asm.abi()` and
`p2.asm.capabilities()`, with `p2.asm.audit()` available for consistency checks.
Arbitrary SD-loaded PASM launch still needs a public ABI and broader fixture
coverage before it should be called supported. PASM function bridges remain
open.
