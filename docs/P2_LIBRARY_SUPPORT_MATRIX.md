# P2 XMM library support and evidence matrix

This matrix describes effective profile 4 registration, not a promise that every
registered operation is implemented or hardware-verified. Full library acceptance
remains incomplete. Hardware results must be tied to their exact image.

## Source-backed inventory

`tools/test_p2_module_config.py` preprocesses the real P2 configuration and native
table, and inventories eager cache calls from `be_libs_p2.c`. Eager preprocessing
suppresses only the generated precompiled string-table dependency; it is a static
registration check, not execution of library behavior.

Effective native modules: 16. Built-in eager aliases: bytes.

Sources: `port/p2/overrides/be_modtab_p2.c`, `be_libs_p2.c`, and
`port/p2/include/berry_conf_p2.h`. Minimal/non-XMM profiles and explicit extended-module
disabling are checked separately; this inventory must not be applied to them.

## Per-module boundaries

### `debug`
Registration: native table.
LCV3: stack introspection, out-of-range caller and GC-debug toggles.

### `gc`
Registration: native table.
Real VM GC/native-finalizer/accounting tests and isolated two-VM diagnostic; board module API coverage remains incomplete.

### `global`
Registration: native table.
LCV3: membership, mutation/removal and invalid argument.

### `i2c`
Registration: eager cache.
Registered, not a device/pin ownership claim. No unidentified peripheral driven; physical behavior unverified.

### `introspect`
Registration: native table.
LCV3: member lookup/name/module and null-pointer boundary; no foreign pointers dereferenced.

### `json`
Registration: native table, eager cache.
Host language suite coverage only where listed in its receipt; fresh board conformance remains incomplete.

### `math`
Registration: eager cache.
Real-VM per-VM RNG callbacks tested; full board math conformance remains incomplete.

### `os`
Registration: native table, eager cache.
Host/P2 semantics differ. Filesystem and environment behavior require board-specific proof; no storage mutation authorized by a test fixture.

### `p2`
Registration: eager cache.
LCV3: read-only clock/cog identification, CORDIC/integer helpers and RNG. No pin/bus/storage writes.

### `spi`
Registration: eager cache.
Registered, not a device/pin ownership claim. No unidentified peripheral driven; physical behavior unverified.

### `strict`
Registration: native table.
LCV3: syntax rejection and undeclared-global rejection.

### `string`
Registration: eager cache.
LCV3: find/count/split/replace/case-insensitive prefix/suffix/format boundaries.

### `sys`
Registration: native table.
LCV3: live import path, add/pop round trip and invalid type.

### `task`
Registration: native table, eager cache.
Real-VM scheduler/RNG native regression runner; public script-wrapper and board behavior need full conformance closure.

### `time`
Registration: native table.
LCV3: clock types, epoch conversion, missing/invalid arguments.

### `undefined`
Registration: native table.
LCV3: import plus missing-attribute exception.

## Fresh board coverage status

The LCV3 descriptor exercises eight standard-library groups and one bounded P2
information group. All eight standard-library groups passed on the fresh cancellation
candidate. The P2 information group timed out and is **not a pass**; a bounded
per-call trace is being used to locate the failing operation. Source declarations
and a successful target build are not behavioral evidence. Earlier single-VM board
receipts remain evidence only for their recorded older images.

The portable host case is `tests/p2_stdlib_portable.be`; the explicit-device
Catalina Lua harness is `tools/p2/hil/stdlib.lua`. Full host CI-body execution also
passed with this new portable case. No GPIO/bus/storage mutation is in either case.

The full host language suite is complementary, not a substitute for the P2 overrides.
Retain normal, error and boundary assertions; do not count imports alone as conformance.

## Practical safe REPL checks

```berry
import math
print(math.sqrt(81))
import json
print(json.dump({"value": 42}))
import sys
print(sys.path())
import p2
print(p2.clock.freq(), p2.cog.id())
```

These examples do not authorize driving I2C/SPI/GPIO or formatting storage.
For cancellation, lifecycle limitations and serial safety, see
[P2_CANCELLATION_STATUS.md](P2_CANCELLATION_STATUS.md).
