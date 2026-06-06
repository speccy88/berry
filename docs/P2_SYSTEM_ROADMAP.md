# P2 Berry System Roadmap

This is the north-star plan for turning the Propeller 2 port into a complete
microcontroller Berry system, not just a REPL that happens to run on P2.

## Vision

Build a P2 Berry environment that can rival serious microcontroller scripting
systems:

- full practical base-Berry language and library coverage
- `.be` programs stored on SD and runnable directly from the REPL
- lazy module loading from SD and, on 32 MB P2 Edge boards, PSRAM-backed module
  storage or cache space
- maximum useful Hub RAM left for the active VM, stacks, buffers, and hardware
  mailboxes
- broad P2 hardware coverage: pins, smart pins, counters, CORDIC, locks,
  cogs, hubexec/PASM helpers, SD, serial, SPI, I2C, timers, and board-specific
  profiles
- Spin2/PASM module loading that can cooperate with Berry code
- multiple Berry VMs across cogs with a clean user model
- a better multicog launch API than the current worker system, ideally allowing
  a Berry closure or function object to be launched on a new cog when it can be
  safely serialized or rebound in that cog's VM

## Current Edge32 Baseline

The `edge32` profile is the first selectable P2 Edge 32 MB RAM path:

```sh
make p2-edge32
make p2-edge32-flash PORT=/dev/cu.usbserial-P97cvdxp
tio -b 230400 /dev/cu.usbserial-P97cvdxp
```

It uses Catalina COMPACT plus `-lpsram`. Catalina exposes PSRAM in this mode
through block transfers (`psram_read()` / `psram_write()`), not as ordinary C
pointer-addressable memory. Because Berry objects are pointer-followed C
structures managed by the GC, the VM heap remains in Hub RAM for now.

Runtime probes:

```berry
import p2
print(p2.psram_info())
print(p2.psram_test())
```

## Memory Strategy

Short term:

- keep active Berry VM heaps in Hub RAM
- keep `.be` source files and examples on SD
- use PSRAM as a large block cache or module store on 32 MB boards
- add lazy source/module loading so rarely used libraries do not permanently
  occupy Hub RAM
- default P2 imports now search `/modules` lazily, with `libstore.be` reporting
  the SD-first model and the future PSRAM cache hook
- keep the image under the 512 KiB Hub RAM guard for `p2-ram`

Medium term:

- add a module cache layer that can store source text, bytecode-like compiled
  artifacts, or solidified tables in PSRAM and copy hot chunks into Hub RAM on
  demand
- identify which base-Berry modules can be enabled without permanent Hub cost
- make SD and PSRAM caches share one loader abstraction
- add cache invalidation and diagnostics through `p2.status()` or a future
  `sys.mem()`-style API

Long term:

- evaluate Catalina `LARGE`/`SMALL` XMM execution for a separate experimental
  image
- evaluate whether a handle-based Berry object arena or moving GC can make
  external RAM practical
- avoid claiming external heap support until object pointers, GC scanning,
  strings, closures, and native calls are all safe across the memory boundary

## Multicog VM Model

The current worker system proves that a second Berry VM can run on another cog,
but it is not the desired end-user API.

Target API direction:

```berry
import rtos

def blink(pin)
  while true
    p2.pin_toggle(pin)
    rtos.sleep_ms(250)
  end
end

cog = rtos.newcog(blink, 56)      # target shape
cog = rtos.newcog("blink", 56)    # current safe named-child-VM shape
```

Design constraints:

- a closure cannot simply share main-VM pointers with another cog
- launch must either serialize/recompile the function in the target VM or prove
  that the captured state is immutable and transferable
- cross-cog communication should use explicit channels, queues, events, locks,
  and shared byte buffers rather than accidental shared VM objects
- errors from child VMs must be inspectable from the parent VM
- each cog needs an explicit heap/stack budget

Current implementation:

- `rtos.newcog("name", ...int_args)` is the preferred process-facing API and is
  backed by the existing second Berry VM/cog.
- `rtos.newcog(function, ...)` raises a deliberate runtime error until function
  transfer semantics are implemented; it must not silently share main-VM
  closure/proto/upvalue pointers with another cog.
- `rtos.process_info()` reports the backend model and current limits so examples
  and tests can detect when true closure launch, multiple process slots, or a
  cog-local task switcher become available.

## Feature Coverage Plan

1. Keep the existing no-PSRAM `full` profile working.
2. Keep `edge32` flash/RAM builds working.
3. Keep expanding the non-destructive `tests/p2/` smoke suite for:
   - arithmetic, strings, lists, maps, ranges
   - `string`, `math`, `json`, `bytes`, `os`, `p2`, `rtos`, `i2c`, `spi`, `spin2`
   - SD read/write/list/remove
   - PSRAM `p2.psram_info()` and `p2.psram_test()` on edge32
4. Expand base-Berry library coverage module by module, measuring image size
   and heap pressure after each step.
5. Add a lazy loader for SD/PSRAM-backed modules.
6. Grow `rtos.newcog(function, ...)` into a real closure/function launch design once
   function transfer semantics are understood.
7. Continue Spin2/PASM loading until Berry can orchestrate native P2 modules
   as first-class companions.

## Non-Goals For Now

- Do not bypass the 512 KiB Hub RAM image guard for `p2-ram`.
- Do not treat Catalina COMPACT PSRAM addresses as normal C pointers.
- Do not hide pin reservations: edge32 reserves pins `40..57`, including pin
  `57` as PSRAM chip-select.
- Do not remove the no-PSRAM P2 Edge path while edge32 evolves.
