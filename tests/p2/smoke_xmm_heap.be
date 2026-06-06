print("P2_SMOKE_BEGIN xmm_heap")

import p2

var info = p2.heap_info()

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
