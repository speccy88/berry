print("P2_SMOKE_BEGIN allocator")

import gc
import p2

gc.collect()
var baseline = p2.heap_info()["main"]
assert(baseline > 0)

var samples = []
var i = 0
while i < 96
    samples.push([i, i + 1, i + 2, "x" * (24 + (i % 8)), {"index": i}])
    i = i + 1
end

var after_alloc = p2.heap_info()["main"]
assert(after_alloc < baseline)
assert(baseline - after_alloc >= 1024)

i = 0
while i < samples.size()
    samples[i] = nil
    i = i + 1
end
samples = nil
gc.collect()

var after_free = p2.heap_info()["main"]
assert(after_free > after_alloc)
assert(after_free >= baseline - 4096)
assert(p2.sbrk() == after_free)

print("P2_SMOKE_PASS allocator")
