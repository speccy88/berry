# Host-side regression for libstore's chunked PSRAM source cache.
#
# This runs under the desktop Berry binary with a fake p2 module so chunking can
# be tested without a P2 Edge board attached. It is not included by the on-target
# /tests/p2 smoke suite.

var p2 = module("p2")
p2.mem = {}
p2.info = {
    "available": true,
    "bytes": 33554432,
    "access": "block",
    "max_transfer": 7,
    "heap": false,
    "reserved_pin_first": 40,
    "reserved_pin_last": 57
}
p2.psram_info = def()
    return p2.info
end
p2.psram_write = def(address, data)
    if p2.info.contains("block_base")
        assert(address >= p2.info["block_base"])
        assert(address + size(data) <= p2.info["block_base"] + p2.info["block_bytes"])
    end
    p2.mem[address] = data
    return {
        "ok": true,
        "size": size(data)
    }
end
p2.psram_read = def(address, n)
    return p2.mem[address]
end

var libstore = run_file("modules/libstore.be")
libstore.paths = ["modules"]
var window = libstore.cache_reset()
assert(window["base"] == 32505856)
assert(libstore.status()["heap"] == "hub")

var cached = libstore.cache_source("math")
assert(cached["chunk_count"] > 1)
assert(cached["address"] == 32505856)
assert(libstore.cached("math"))
assert(libstore.cached_source("math") == open("modules/math.be", "r").read())

var math = libstore.load("math")
assert(math.sqrt(81) == 9)
assert(math.abs(-42) == 42)

var report = libstore.cache_report()
assert(report["status"]["psram_cache_items"] == 1)
assert(report["items"][0]["chunks"] == cached["chunk_count"])

p2.mem = {}
p2.info = {
    "available": true,
    "bytes": 33554432,
    "access": "xmm+block",
    "max_transfer": 5,
    "heap": true,
    "xmm_bytes": 16777216,
    "block_base": 16777216,
    "block_bytes": 16777216,
    "reserved_pin_first": 40,
    "reserved_pin_last": 57
}
window = libstore.cache_reset()
assert(window["block_base"] == 16777216)
assert(window["base"] >= window["block_base"])
assert(window["base"] == 32505856)
assert(libstore.strategy()["heap"] == "external")
assert(libstore.strategy()["object_heap"] == true)
assert(libstore.strategy()["psram_role"] == "xmm_heap_and_chunked_source_cache")
assert(libstore.status()["psram_block_base"] == 16777216)
assert(libstore.status()["psram_cache_free"] == libstore.status()["psram_cache_limit"])

cached = libstore.cache_source("math")
assert(cached["chunk_count"] > 1)
assert(cached["address"] >= 16777216)
assert(libstore.cached_source("math") == open("modules/math.be", "r").read())
