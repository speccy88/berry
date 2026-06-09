print("P2_SMOKE_BEGIN xmm_gc_stress")

import p2

def make_accumulator(seed)
    var state = {"seed": seed, "hits": 0}
    return def(delta)
        state["hits"] += 1
        return state["seed"] + state["hits"] + delta
    end
end

var status = p2.status_info()
var heap = p2.heap_info()
var psram = p2.psram_info()

assert(status["build"]["profile"] == "xmm")
assert(status["memory"]["external_heap"] == true)
assert(heap["external_heap"] == true)
assert(heap["main_ready"])
assert(heap["main_actual"] >= 14 * 1024 * 1024)
assert(heap["main_inside_pointer_window"])
assert(!heap["main_crosses_block_window"])
assert(psram["heap"] == true)
assert(psram["access"] == "xmm+block")
assert(psram["xmm_bytes"] == 16 * 1024 * 1024)
assert(psram["block_base"] == 16 * 1024 * 1024)
print("XMMGC_PREFLIGHT", heap["main_actual"])

p2.gc()
var baseline = p2.heap_info()["main"]
assert(baseline > 8 * 1024 * 1024)
print("XMMGC_BASELINE", baseline)

var survivors = []
var all_records = []
var i = 0
while i < 512
    var rec = {
        "index": i,
        "name": "xmm-survivor-" + str(i),
        "payload": "A" * 1024,
        "nested": [i, i + 1, {"triple": i * 3}],
        "fn": make_accumulator(i)
    }
    all_records.push(rec)
    if i % 4 == 0
        survivors.push(rec)
    end
    i += 1
end

assert(survivors.size() == 128)
var after_alloc = p2.heap_info()["main"]
print("XMMGC_AFTER_ALLOC", after_alloc, baseline - after_alloc)
assert(after_alloc < baseline)
assert(baseline - after_alloc > 512 * 1024)

all_records = nil
p2.gc()
var after_first_gc = p2.heap_info()["main"]
print("XMMGC_AFTER_GC1", after_first_gc, after_first_gc - after_alloc)
assert(after_first_gc > after_alloc)
assert(!p2.heap_info()["main_crosses_block_window"])

i = 0
while i < survivors.size()
    var rec = survivors[i]
    assert(rec["index"] == i * 4)
    assert(rec["nested"][2]["triple"] == rec["index"] * 3)
    assert(rec["payload"][0] == "A")
    assert(rec["payload"][1023] == "A")
    assert(rec["fn"](10) == rec["index"] + 11)
    i += 1
end

var round = 0
while round < 4
    var churn = []
    var j = 0
    while j < 256
        churn.push({
            "round": round,
            "slot": j,
            "payload": "B" * 512,
            "values": [round, j, round + j]
        })
        j += 1
    end
    print("XMMGC_CHURN", round, p2.heap_info()["main"])
    assert(p2.heap_info()["main"] < after_first_gc)
    churn = nil
    p2.gc()
    print("XMMGC_CHURN_GC", round, p2.heap_info()["main"])
    assert(!p2.heap_info()["main_crosses_block_window"])
    round += 1
end

i = 0
while i < survivors.size()
    var rec = survivors[i]
    assert(rec["index"] == i * 4)
    assert(rec["nested"][0] == rec["index"])
    assert(rec["nested"][1] == rec["index"] + 1)
    assert(rec["fn"](20) == rec["index"] + 22)
    i += 1
end

survivors = nil
p2.gc()
var after_free = p2.heap_info()["main"]
print("XMMGC_AFTER_FREE", after_free, baseline - after_free)
assert(after_free > after_first_gc)
assert(after_free >= baseline - 1024 * 1024)
assert(!p2.heap_info()["main_crosses_block_window"])
assert(p2.heap_info()["wrong_free_count"] == 0)
assert(p2.heap_info()["wrong_realloc_count"] == 0)

print("P2_SMOKE_PASS xmm_gc_stress")
