print("P2_SMOKE_BEGIN libraries")

import binary_heap

var data = [3, 1, 4, 1, 5]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 1, 3, 4, 5])

import libstore

var status = libstore.status()
assert(status["lazy"] == true)
assert(status["source"] == "sd")
assert(status["heap"] == "hub")
assert(status["psram_cache"] == false)
assert(libstore.exists("binary_heap"))
assert(libstore.source_path("binary_heap") == "/modules/binary_heap.be")

print("P2_SMOKE_PASS libraries")
