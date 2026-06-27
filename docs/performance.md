# P2 Performance Plan

This file defines the benchmark areas required by the TODO list. It does not claim measurements until numbers are captured from a named board/profile/build.

## Required measurements

- Baseline Berry VM speed.
- Import latency from SD.
- Import latency from PSRAM cache.
- Hub RAM high-water mark.
- PSRAM usage.
- GC pause time.
- Cog spawn latency.
- Task switch latency.
- Channel latency.
- Smart-pin wrapper overhead.
- Native/PASM speedup.
- Video/streamer throughput where relevant.
- SD read throughput.
- PSRAM read/write throughput.

## Investigation areas

- LUT RAM tables for Berry bytecode dispatch.
- Hot VM dispatch code in cog RAM.
- P2 custom-bytecode or execution features.
- CORDIC acceleration for Berry math.
- Streamer acceleration for video, audio, or buffer movement.
- Smart pins for timing-heavy protocol offload.

## Reporting format

Every benchmark result should record board, profile, toolchain, git revision, command, sample count, result, and notes about SD card or attached hardware.

Do not add complicated acceleration until benchmarks prove the PSRAM/cache/native path is worth the complexity.

## Captured results

### CORDIC math timing hook

- Board/profile: P2 Edge 32 MB, XMM profile, `/dev/ttyUSB0` board.
- Toolchain: Catalina via `CATALINA_DIR=../Catalina`.
- Captured firmware image: `1165888` bytes, build `Jun 26 2026 06:58:43`.
- Command: `make p2-smoke-math-perf-min PORT=/dev/ttyUSB0 TOOLCHAIN=catalina CATALINA_DIR=../Catalina`.
- Smoke: `/tests/p2/mathperf.be`, staged from `tests/p2/smoke_math_perf_min.be`.
- Sample count: `64` loop iterations.
- Result: `P2_MATH_PERF_MIN p2_cordic 64 5943592 60154344 34037192`.
- Meaning: the active backend reported `p2_cordic`; the three tick values are empty-loop, `sin`/`cos`, and `sqrt` fallback loops. This is a repeatable measurement hook, not yet a statistical speedup claim.
