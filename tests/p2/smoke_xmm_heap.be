print("P2_SMOKE_BEGIN xmm_heap")

import p2
import json
import introspect
import math

var info = p2.heap_info()
var status = p2.status_info()
var psram = p2.psram_info()
var fs = p2.fs_info("/")

assert(status["build"]["profile"] == "xmm")
assert(status["runtime"]["toolchain"] == "Catalina")
assert(status["memory"]["external_heap"] == true)
assert(status["memory"]["main_heap_total"] >= 15 * 1024 * 1024)
assert(status["psram"]["xmm_bytes"] == 16 * 1024 * 1024)
assert(status["psram"]["block_base"] == 16 * 1024 * 1024)
assert(status["psram"]["block_bytes"] == 16 * 1024 * 1024)
assert(psram["xmm_bytes"] == 16 * 1024 * 1024)
assert(psram["block_base"] == 16 * 1024 * 1024)
assert(psram["block_bytes"] == 16 * 1024 * 1024)
assert(fs["mount_result_name"] == "ok")
assert(fs["partition_start"] == 0 || fs["partition_start"] == 1 || fs["partition_start"] == 32 || fs["partition_start"] == 63 || fs["partition_start"] == 128 || fs["partition_start"] == 256 || fs["partition_start"] == 512 || fs["partition_start"] == 1024 || fs["partition_start"] == 2048 || fs["partition_start"] == 4096 || fs["partition_start"] == 8192 || fs["partition_start"] == 16384 || fs["partition_start"] == 32768 || fs["partition_start"] == 65536)
assert(type(introspect.members(math)) == "list")
assert(math.sqrt(81) == 9)

if info["external_heap"]
    assert(info["main_ready"])
    assert(info["main_segments"] >= 2)
    assert(!info["main_crosses_block_window"])
    assert(info["main_high"] <= 16 * 1024 * 1024)

    var gc_report = p2.gc()
    assert(type(gc_report) == "map")
    var baseline = p2.heap_info()["main"]
    assert(baseline > 8 * 1024 * 1024)

    var batch = []
    var i = 0
    while i < 256
        batch.push({
            "index": i,
            "payload": str(i) + ":" + ("x" * (512 + (i % 5) * 16)),
            "pair": [i, i + 1]
        })
        i += 1
    end

    var after_alloc = p2.heap_info()["main"]
    assert(after_alloc < baseline)
    assert(baseline - after_alloc > 256 * 1024)

    i = 0
    while i < batch.size()
        if i % 2 == 0
            batch[i] = nil
        end
        i += 1
    end
    gc_report = p2.gc()
    assert(type(gc_report) == "map")

    var after_half_free = p2.heap_info()["main"]
    assert(after_half_free > after_alloc)

    i = 0
    while i < 128
        batch.push({
            "index": i + 2000,
            "payload": str(i) + ":" + ("y" * (480 + (i % 7) * 16)),
            "pair": [i + 2000, i + 2001]
        })
        i += 1
    end

    var after_refill = p2.heap_info()["main"]
    assert(after_refill < after_half_free)
    assert(p2.heap_info()["main_crosses_block_window"] == false)

    batch = nil
    gc_report = p2.gc()
    assert(type(gc_report) == "map")

    var after_free = p2.heap_info()["main"]
    assert(after_free > after_refill)
    assert(after_free >= baseline - 256 * 1024)
    assert(p2.heap_info()["main_crosses_block_window"] == false)
end

print("P2_SMOKE_PASS xmm_heap")
