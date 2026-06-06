# Host-side regression for libstore's chunked PSRAM source cache.
#
# This runs under the desktop Berry binary with a fake p2 module so chunking can
# be tested without a P2 Edge board attached. It is not included by the on-target
# /tests/p2 smoke suite.

var p2 = module("p2")
p2.mem = {}
p2.psram_info = def()
    return {
        "available": true,
        "bytes": 33554432,
        "access": "block",
        "max_transfer": 7,
        "heap": false,
        "reserved_pin_first": 40,
        "reserved_pin_last": 57
    }
end
p2.psram_write = def(address, data)
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
libstore.cache_reset()

var cached = libstore.cache_source("math")
assert(cached["chunk_count"] > 1)
assert(libstore.cached("math"))
assert(libstore.cached_source("math") == open("modules/math.be", "r").read())

var math = libstore.load("math")
assert(math.sqrt(81) == 9)
assert(math.abs(-42) == 42)

var report = libstore.cache_report()
assert(report["status"]["psram_cache_items"] == 1)
assert(report["items"][0]["chunks"] == cached["chunk_count"])
