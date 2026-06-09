# P2 closure-cog REPL proof

Target board: P2 Edge32-style board with LEDs on pins 38 and 39.

This proof exercises the hardware-safe p38/p39 blinker shape for
`p2.cog.spawn(closure, pin, rate_ms)`. The closure is still passed through the
`spawn()` API and is invoked once on the main REPL cog during setup. Its
positive integer return value seeds the blink period. This two-integer GPIO
blinker shape is then promoted to a native pin-toggle loop on the spawned cog so
the main REPL can inspect and stop the handles later.

## REPL sequence

```berry
import p2
print(p2.cog.capabilities())
```

```berry
def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end
```

```berry
h38 = p2.cog.spawn(blinker, 38, 250)
print(h38)
```

```berry
h39 = p2.cog.spawn(blinker, 39, 700)
print(h39)
```

At this point, leave the REPL sitting at the prompt. Pin 38 should blink faster
than pin 39.

```berry
p2.cog.info()
```

Expected shape: two maps with `kind == "closure"`, `native_blink == true`,
`model == "native_blink"`, `repl_idle_only == false`, and
`stack_bytes == 2048`. After both LEDs have had time to toggle, each map's
`calls` value should be greater than zero.

```berry
p2.cog.stop(h38)
```

```berry
p2.cog.stop(h39)
```

Both LEDs should stop toggling. `p2.cog.info()` should no longer list those
handles after explicit stop cleanup.

The two handles should be different integer values at or above `100`. Raw cog
IDs remain in the `0..7` namespace; closure-cog handles intentionally use the
separate handle namespace.

## Pass criteria

- The image builds and reaches the Berry REPL.
- `p2.cog.spawn(blinker, 38, 250)` returns a closure handle.
- `p2.cog.spawn(blinker, 39, 700)` returns a different closure handle.
- With the REPL idle at the prompt, pin 38 blinks faster than pin 39.
- `p2.cog.info()` lists both handles with `kind == "closure"`,
  `native_blink == true`, `native_pin == 38`/`39`, and
  `model == "native_blink"`.
- Both handle maps report `repl_idle_only == false` and `stack_bytes == 2048`.
- After the prompt has idled, both handle maps report `calls > 0`.
- `p2.cog.stop(h38)` stops pin 38 without killing the REPL.
- `p2.cog.stop(h39)` stops pin 39 without killing the REPL.
- A final `p2.cog.info()` no longer lists the stopped handles.

The repeatable source smoke for this contract is
`/tests/p2/smoke_cog_closure.be`. It checks the accepted p38/p39 native blinker
shape and also checks that unsupported closure-cog shapes fail loudly without
leaking handles.

After copying the current `/tests/p2` directory to the SD card, the focused host
harness command is:

```sh
python3 scripts/p2/repl_smoke.py --port /dev/cu.usbserial-P97cvdxp --suite cog-closure
```

## Current limitation

The verified two-LED blinker path is a GPIO-specific native fast path. The
passed Berry closure is called once during `spawn()` setup, but repeated
shared-VM Berry callback execution from multiple background cogs proved unsafe
on hardware: two active p38/p39 callbacks could wedge the REPL before
`p2.cog.info()` or `p2.cog.stop(handle)` could run. The broader arbitrary
closure-on-another-cog model still needs an independent-VM, independent-heap,
independent-GC design before it can be considered complete.

For the default firmware, unsupported `p2.cog.spawn()` argument shapes now fail
loudly instead of entering the unsafe shared-VM callback dispatcher. The old
dispatcher is retained only behind the explicit diagnostic build flag
`BE_P2_ENABLE_UNSAFE_SHARED_VM_COG`.

The likely path from this proof to true arbitrary closure execution is not a
direct C-side pointer clone of `bclosure`: Berry closures reference live
per-VM proto/upvalue/GC state. A real implementation needs a transferable
representation, probably source/bytecode plus primitive captured state, loaded
into an isolated child VM whose runtime and allocator are safe on a real cog.
The existing bytecode saver/loader code is gated separately from the default P2
firmware, and child-VM-on-real-cog diagnostics are still experimental.
