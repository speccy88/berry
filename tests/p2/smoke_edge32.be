print("P2_SMOKE_BEGIN edge32")

import p2

var info = p2.psram_info()
assert(info["available"] == true)
assert(info["bytes"] == 33554432)
assert(info["access"] == "block")
assert(info["max_transfer"] >= 1024)
assert(info["heap"] == false)
assert(info["reserved_pin_first"] == 40)
assert(info["reserved_pin_last"] == 57)

var smoke = p2.psram_test()
assert(smoke["available"] == true)
assert(smoke["bytes"] == 33554432)
assert(smoke["ok"] == true)
assert(smoke["value"] == "Berry P2 PSRAM smoke")

var address = 29 * 1024 * 1024
var text = "Berry PSRAM cache"
var write = p2.psram_write(address, text)
assert(write["ok"] == true)
assert(write["size"] == size(text))
assert(p2.psram_read(address, size(text)) == text)

import libstore

libstore.cache_reset()
var cached = libstore.cache_source("binary_heap")
assert(cached["name"] == "binary_heap")
assert(cached["path"] == "/modules/binary_heap.be")
assert(cached["size"] == size(open("/modules/binary_heap.be", "r").read()))
assert(libstore.cached_source("binary_heap") == open("/modules/binary_heap.be", "r").read())
assert(libstore.info("binary_heap")["cached"] == true)
assert(libstore.status()["psram_cache_used"] == cached["size"])

print("P2_SMOKE_PASS edge32")
