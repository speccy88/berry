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
