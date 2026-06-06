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

var original_policy = libstore.policy()["name"]
if original_policy != libstore.POLICY_SD_CACHE_PSRAM {
    var set_cache = libstore.set_policy(libstore.POLICY_SD_CACHE_PSRAM, true)
    assert(set_cache["policy"] == libstore.POLICY_SD_CACHE_PSRAM)
}

libstore.cache_reset()
var cached = libstore.cache_source("binary_heap")
assert(cached["name"] == "binary_heap")
assert(cached["path"] == "/modules/binary_heap.be")
assert(cached["size"] == size(open("/modules/binary_heap.be", "r").read()))
assert(cached["chunk_count"] >= 1)
assert(cached["chunks"].size() == cached["chunk_count"])
assert(cached["chunks"][0]["address"] == cached["address"])
assert(libstore.cached_source("binary_heap") == open("/modules/binary_heap.be", "r").read())
assert(libstore.cached("binary_heap"))
assert(libstore.info("binary_heap")["cached"] == true)
assert(libstore.status()["psram_cache_used"] == cached["size"])
assert(libstore.status()["psram_cache_items"] == 1)

var cached_again = libstore.cache_source("binary_heap")
assert(cached_again["address"] == cached["address"])
assert(libstore.status()["psram_cache_items"] == 1)

var math_cached = libstore.cache_source("math")
assert(math_cached["name"] == "math")
assert(math_cached["chunk_count"] >= 1)
assert(libstore.cached_source("math") == open("/modules/math.be", "r").read())
var cached_math = libstore.load("math")
assert(cached_math.sqrt(81) == 9)
assert(cached_math.abs(-42) == 42)

var report = libstore.cache_report()
assert(report["status"]["psram_cache_items"] == 2)
assert(report["items"].size() >= 2)

var all_cached = libstore.cache_all()
assert(all_cached.size() >= libstore.modules().size())
assert(libstore.status()["psram_cache_items"] >= libstore.modules().size())
assert(libstore.cached("binary_heap"))
assert(libstore.cached("libstore"))
assert(libstore.cached("math"))
assert(libstore.cached("taskspin"))
assert(libstore.cached("wifi"))

var switched = libstore.set_policy(libstore.POLICY_SD_LAZY)
assert(switched["policy"] == libstore.POLICY_SD_LAZY)
assert(libstore.status()["psram_cache"] == false)
var math_sd = libstore.load("math")
assert(math_sd.sqrt(81) == 9)
assert(math_sd.abs(-42) == 42)

libstore.set_policy(original_policy)

print("P2_SMOKE_PASS edge32")
