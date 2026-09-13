# P2 allocator milestone testing

This is an F1/F5 **allocator implementation candidate**, not Berry/P2 port
completion or delivery. Parent review, Catalina target build and hardware proof
remain separate. No serial, flash, PSRAM hardware or interpreter tests ran here.

## Repair and coverage

`tests/native/test_p2_heap.c` includes the actual `port/p2/runtime/p2_heap.c`,
not a copied allocator. Cases run in separate processes with bounded storage.

- Grow-in-place checks physical adjacency and representable capacity before
  mutating the list. Nonadjacent blocks use allocate/copy/free or fail without
  changing the old payload/list. Adjacent multi-segment growth is also tested.
- Checked alignment, header addition, segment address/total/count arithmetic,
  external window ends and partition requests reject overflow before writes.
  Oversized splits are no-ops; shrink remainders coalesce. Capacity diagnostics
  saturate at `INT_MAX` instead of narrowing to negative values.
- Tests cover zero-size behavior, `SIZE_MAX` and its preceding boundary range,
  half-range and `UINT32_MAX` requests, split/coalesce, allocation fallback,
  OOM preservation, partition lifecycle, ownership rejection and OOM isolation.
- Arithmetic review found no runtime count-times-element-size operation in this
  allocator: APIs take bytes and each partition reserves one byte-sized arena.
  Caller-side multiplication must be checked **before** calling this API; an
  already wrapped product cannot be diagnosed here. Free/partition byte sums
  are bounded by the checked backing-arena total for valid allocator state.
  No new ABI, `calloc` interface or interpreter multiplication repair is claimed.

## Executed commands (2026-09-12)

Working directory: `/opt/data/propeller2/berry`.

```sh
/opt/hermes/.venv/bin/python tools/test_p2_heap.py --container propeller2
python3 tools/test_p2_heap.py --container propeller2 --freestanding32 --cflags=-Werror
python3 tools/test_p2_heap.py --cc cc --cflags='-Werror -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -fno-pie -no-pie'
/opt/hermes/.venv/bin/python /opt/data/propeller2/berry-stabilization/gates/allocator_gate.py
```

Each runner command passed **124/124**, zero test/build failures. Counts include
repeated cases across static, static-external, external-chunk and external-window
configurations. The unchanged parent gate passed compilation plus adjacent,
nonadjacent and overflow probes; its nonadjacent probe reported zero changed
out-of-arena bytes and preserved old data. It also ran earlier with `python3`,
without `--expect baseline`.

TDD: before production edits, `python3 tools/test_p2_heap.py --container propeller2`
ran the original allocator at `593846ee57ac54c326dde08e31feb30a3881d725`: **41
passed, 46 failed, 87 total**, exit 1, no build failures. Evidence is retained in
`build/p2-heap-vjo0149g/`. Later tests added capacity-narrowing coverage (three
real failures before its fix), multi-segment growth and external-request checks.
Final green evidence: `build/p2-heap-ej4jiwqj/` (container),
`build/p2-heap-a3e64an8/` (32-bit), `build/p2-heap-ie_fttv3/` (sanitizers).
Every run retains commands, exit codes, logs and source hash in ignored `build/`.

## Reproduction and limits

The runner uses only Python's standard library. Container mode uses
`docker exec --user 10000:10000`, Clang and `/work/propeller2/berry`.
Host mode defaults to `cc`; `--cc` and `--cflags` override it. Missing tools,
compile failures, crashes, timeouts, empty discovery or test failures exit
nonzero. No tests are silently skipped after a compiler failure.

`tests/native/propeller2.h` provides a **host-only `_cogid` seam**: synchronous
arena routing, not concurrent P2 cogs. External backing memory is a host fixture,
not the PSRAM driver. `--freestanding32` executes Linux/i386 code using test-only
libc/syscall headers; compiler-native pointers and `size_t` really are 32-bit.
It requires Linux x86 compatibility, not a P2 emulator or Catalina runtime.

Ordinary `-m32` linking lacked multilib CRT/libc; container Clang sanitizers lacked
runtime libraries. Nothing was installed: freestanding32 and host GCC sanitizers
provided the separate green checks above. Production C also passed strict host
C89 compilation, but this does **not** establish a Catalina build, target ABI,
PSRAM behavior, concurrency safety, whole-project stability or hardware success.
