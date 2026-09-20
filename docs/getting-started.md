# P2 Getting Started

Start with a single Berry VM and a serial prompt. No SD card, extra peripheral,
or flash write is needed for this walkthrough. Use the [port status](P2_PORT_STATUS.md)
for supported/experimental/unavailable boundaries and the [P2 API](p2-api.md)
for signatures; this guide is not a second API reference.

## Build and connect

Use Linux/x86-64 and the pinned Catalina toolchain, including the existing
container when available. The reproducible [build guide](P2_BUILD.md) covers
bootstrap and profiles. FlexC is historical, not the normal validation path.

For a P2 Edge **with 32 MiB PSRAM**, build the LARGE/XMM production image:

```sh
make p2-xmm TOOLCHAIN=catalina CATALINA_DIR=../Catalina
```

Load to volatile memory with `make p2-xmm-run TOOLCHAIN=catalina
CATALINA_DIR=../Catalina PORT=/dev/ttyUSB0`. Use one serial owner and the same
exclusive serial lease as any board automation; never open a second terminal
while the loader owns the port. The normal Catalina console is 230400 baud.
RAM loading does not install firmware in flash. Flashing is optional and needs
board identity, a private verified backup and a recovery plan first.

For an Edge **without external RAM**, use `make p2 TOOLCHAIN=catalina
CATALINA_DIR=../Catalina`: COMPACT, `-lcx`, no `-lpsram`. Do not apply the XMM
profile or assume identical groups on this smaller profile. `p2.help()` discovers
the groups actually registered in your image.

## First prompt: no wiring required

Type these commands exactly, one line at a time, at `berry>`. Do not type the
prompt itself. A non-`nil` expression result prints automatically.

<!-- first-prompt:start -->
```berry
6 * 7
import p2
p2.help()
p2.help("pin")
p2.clock.freq()
p2.cog.id()
p2.debug.snapshot()["runtime"]["memory_profile"]
import introspect
introspect.members(p2.pin)
p2.cog.capabilities()["spawn_source"]
```
<!-- first-prompt:end -->

The arithmetic result is `42`; the XMM memory profile is `xmm+psram-block`;
`spawn_source` is `false` in the production image. Clock/cog values vary by
build and service allocation. Help and member-list order is unspecified.
Help is read-only metadata: it does not drive pins, open buses or access SD.
`p2.debug.snapshot()` reads status; it does not mount media.

[examples/p2/interactive.be](../examples/p2/interactive.be) extends this into
an executable, read-only Berry session with functions, loops and introspection.
The grouped style (`p2.clock.freq()`, `p2.pin.read(pin)`) is preferred here;
existing flat aliases remain compatibility surfaces, not a second API to learn.

## Functions, loops and recovery

Berry uses `def`, `end`, `var`, `for i: range`, and `try` / `except`.
It does not use Python's indentation or `for i in range(...)` syntax.

<!-- multiline:start -->
```berry
var total = 0
def twice(x)
  return x * 2
end
for i: 1..3
  total += twice(i)
end
total
```
<!-- multiline:end -->

The prompt changes from `berry>` to `...>` while a submission is incomplete;
`end` completes the block, and `total` prints `12`. A syntax error such as
`var =` or a runtime error such as `raise "value_error", "demo"` prints the
normal Berry exception and returns to `berry>`; existing globals remain usable.

- Ctrl-C cancels an empty or edited line, or the **entire pending multiline
  submission**, and prints `KeyboardInterrupt`. It also interrupts running
  Berry bytecode through the VM poll hook, returning to the same VM. Completed
  side effects are not rolled back. Long native calls can delay polling.
- Ctrl-D on an **empty input line**, including `...>`, abandons pending source
  and exits the P2 interpreter. The board prints `[Berry interpreter exited]`
  and waits; load/reset explicitly to start a new VM. Ctrl-D on nonempty edited
  input is ignored. While Berry bytecode is running, Ctrl-D retains the legacy
  interrupt behavior (like Ctrl-C), rather than exiting the interpreter.
- A host reader's EOF ends that REPL invocation even during continuation; it
  never becomes source text or a synthetic syntax error. An embedding host may
  start another invocation with the same VM.

## Next steps and safety

Read the [P2 API](p2-api.md) before selecting pins or creating bus objects.
On the PSRAM Edge, pins 40–57 belong to memory, 58–61 are the shared flash/SD
wiring, and 62/63 are the console. In particular, do not reuse 56/57 as LEDs on
this board. Verify your own board and wiring rather than copying pin examples.

SD libraries and hardware smoke suites are optional next steps, not onboarding
prerequisites. Some [testing targets](testing.md) upload files or exercise wired
pins; read their scope first. Historical logs in [DONE.md](../port/p2/DONE.md)
record earlier images and are not current setup instructions.
