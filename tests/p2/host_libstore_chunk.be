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
assert(libstore.module_name("MATH.BE") == "math")
assert(libstore.module_name("notes.txt") == nil)
assert(libstore.modules().size() >= 5)
var window = libstore.cache_reset()
assert(window["base"] == 32505856)
assert(libstore.status()["heap"] == "hub")
assert(libstore.status()["library_count"] >= 5)

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

var all_cached = libstore.cache_all()
assert(all_cached.size() >= 5)
assert(libstore.status()["psram_cache_items"] >= 5)
assert(libstore.cached("binary_heap"))
assert(libstore.cached("taskspin"))
assert(libstore.cached("wifi"))

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
all_cached = libstore.cache_all()
assert(all_cached.size() >= 5)
assert(libstore.status()["psram_cache_items"] >= 5)

p2.mem = {}
var p2mem = run_file("modules/p2mem.be")
var stats = p2mem.stats()
assert(type(stats) == "map")
assert(stats["module_count"] >= 5)
var modules = p2mem.modules()
assert(modules.size() >= 5)
var saw_math = false
for rec : modules
    if rec["module"] == "math"
        saw_math = true
        assert(rec["source_path"] == "modules/math.be")
        assert(rec.contains("compiled_path"))
        assert(rec.contains("source_hash"))
        assert(rec.contains("compiled_hash"))
        assert(rec.contains("cache_hit_count"))
        assert(rec.contains("cache_miss_count"))
        assert(rec.contains("last_used"))
    end
end
assert(saw_math)
var cache = p2mem.cache()
assert(type(cache["items"]) == "list")
var gc_report = p2mem.gc()
assert(type(gc_report["before"]) == "int")
var evicted = p2mem.evict()
assert(evicted["after"]["psram_cache_items"] == 0)
