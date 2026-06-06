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
- a unified VM memory model where Berry code and the Berry GC do not need to
  know whether backing storage is Hub RAM or PSRAM
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
p2.psram_write(29 * 1024 * 1024, "cache")
print(p2.psram_read(29 * 1024 * 1024, 5))
```

## Experimental XMM Unified Memory

The `xmm` profile is the first explicit attempt to make Berry see one larger
memory model on P2 Edge 32 MB RAM:

```sh
make p2-xmm
```

It builds with Catalina `LARGE` plus `-lpsram` and `-C PSRAM`, marks the Berry
heap as an external-memory heap, and increases the Berry heap target to
`512 KiB` without changing Berry's allocator API. This is the clean path if it
boots: Berry keeps calling `p2_heap_malloc()`, while Catalina's XMM memory model
decides how Hub RAM and PSRAM back that C data.

Catalina currently documents the lower `16 MiB` of P2 Edge PSRAM as XMM memory.
Berry therefore treats that lower window as Catalina-owned in the public
`p2.psram_read()` / `p2.psram_write()` API and leaves the upper `16 MiB` for
explicit block/cache use. A future true `32 MiB + Hub RAM` seamless Berry heap
would need an object/handle/cache representation that can move GC-managed
objects without exposing raw PSRAM pointers to the VM.

Current state:

- build verified: `1057120` byte XMM image, under the `16 MiB` experimental XMM
  image limit
- direct `loadp2` transferred the XMM image but produced no REPL banner; local
  Catalina docs say XMM programs need Catalina's XMM loader utilities
- the normal `full` and `edge32` COMPACT images remain the verified paths

## Memory Strategy

Short term:

- keep active Berry VM heaps in Hub RAM
- keep `.be` source files and examples on SD
- use PSRAM as a large block cache or module store on 32 MB boards
- add lazy source/module loading so rarely used libraries do not permanently
  occupy Hub RAM
- default P2 imports now search `/modules` lazily, with `libstore.be` reporting
  the SD-first model, discovering available `.be` modules, and exposing PSRAM
  source-cache hooks including `cache_all()` that follow the safe block window
  on both edge32 and XMM-style profiles
- `taskspin.be` is the first Spin2-shaped concurrency library kept entirely on
  SD: it adds cooperative `TASKSPIN`/`TASKNEXT`/`TASKSTOP`/`TASKHALT`/
  `TASKCONT`/`TASKCHK`/`TASKID`/`TASKHLT` behavior, stack-address metadata, and
  per-task diagnostics without increasing the firmware image
- keep the image under the 512 KiB Hub RAM guard for `p2-ram`

Medium term:

- use `xmm` as the first unified-memory experiment, so the VM does not grow
  Hub/PSRAM-specific object semantics unless Catalina XMM proves unsuitable
- add a module cache layer that can store source text, bytecode-like compiled
  artifacts, or solidified tables in PSRAM and copy hot chunks into Hub RAM on
  demand
- identify which base-Berry modules can be enabled without permanent Hub cost
- make SD and PSRAM caches share one loader abstraction
- add cache invalidation and diagnostics through `p2.status()` or a future
  `sys.mem()`-style API

Long term:

- boot and stress Catalina `LARGE`/`SMALL` XMM execution on hardware
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

source = "import p2\nimport rtos\n" +
         "def blink(pin)\n" +
         "  while true\n" +
         "    p2.pin_toggle(pin)\n" +
         "    rtos.sleep_ms(250)\n" +
         "  end\n" +
         "end\n"

cog = rtos.run(source, blink, 56) # current safe source-backed function shape
cog = rtos.newcog(blink, 56)      # loaded child-VM function-object shape
cog = rtos.newcog("blink", 56)    # explicit loaded child-VM name shape
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
- `rtos.run(source, task, ...int_args)` loads source into the process VM and
  launches a named task in one step. `task` may be a string name or a named
  zero-upvalue function object.
- `rtos.newcog(function, ...)` now supports named zero-upvalue Berry functions
  by launching the same function name in the child VM after that source is
  loaded there. This is the first safe function-object launch path; it does not
  share closure/proto/upvalue pointers across VMs.
- captured closures still raise a deliberate runtime error until function
  transfer semantics are implemented.
- `rtos.process_info()` reports the backend model and current limits so examples
  and tests can detect when true closure launch, multiple process slots, or a
  cog-local task switcher become available.
- `/modules/taskspin.be` provides a same-VM cooperative task scheduler with
  32 task slots and Spin2-style names. It is useful now for cooperative state
  machines and also gives the future cog-local task switcher an API target.

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
