# Host-side negative regression for libstore's PSRAM source cache.
#
# This checks host-simulatable error and no-op paths around cache_source()
# without requiring a P2 board.

import introspect
import os

var p2 = module("p2")
p2.mem = {}
p2.fail_write = false
p2.short_write = false
p2.fail_read = false
p2.short_read = false
p2.info = {
    "available": true,
    "bytes": 128,
    "access": "block",
    "max_transfer": 4,
    "heap": false
}
p2.psram_info = def()
    return p2.info
end
p2.heap_info = def()
    return {
        "main": 131072,
        "wrong_free_count": 0,
        "wrong_realloc_count": 0
    }
end
p2.status_info = def()
    return {
        "profile": "host_fake",
        "board": "host_fake",
        "memory": p2.heap_info(),
        "psram": p2.psram_info(),
        "build": {
            "bytecode_saver": false,
            "bytecode_loader": false,
            "bytecode_execution": false
        }
    }
end
p2.psram_write = def(address, data)
    if p2.fail_write
        return {
            "ok": false,
            "size": 0
        }
    end
    if p2.short_write
        return {
            "ok": true,
            "size": size(data) - 1
        }
    end
    p2.mem[address] = data
    return {
        "ok": true,
        "size": size(data)
    }
end
p2.psram_read = def(address, n)
    if p2.fail_read
        return nil
    end
    if p2.short_read
        return p2.mem[address][0..(n - 2)]
    end
    return p2.mem[address]
end
introspect.setmodule("p2", p2)

var libstore = run_file("modules/libstore.be")

var root = "tmp/p2_host_cache_errors"
var lib_dir = root + "/lib"
libstore.paths = [lib_dir]
libstore.compiled_paths = [root + "/cache"]
libstore.cache_limit_requested = 128
libstore.set_policy(libstore.POLICY_SD_CACHE_PSRAM)

def remove_quiet(path)
    try
        os.remove(path)
    except .. as e, m
    end
end

def write_text(path, text)
    libstore._ensure_parent_dir(path)
    var f = open(path, "w")
    f.write(text)
    f.close()
end

def expect_error(f, error_type)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == error_type)
    end
    assert(caught)
end

remove_quiet(lib_dir + "/tiny_mod.be")
remove_quiet(lib_dir + "/large_mod.be")
libstore._ensure_dir(lib_dir)

var tiny_source = "var tiny_mod = module('tiny_mod')\n"
tiny_source += "tiny_mod.answer = 42\n"
tiny_source += "return tiny_mod\n"
write_text(lib_dir + "/tiny_mod.be", tiny_source)

var large_source = "var large_mod = module('large_mod')\n"
large_source += "large_mod.answer = '" + ("0123456789" * 8) + "'\n"
large_source += "return large_mod\n"
write_text(lib_dir + "/large_mod.be", large_source)

var window = libstore.cache_reset()
assert(window["available"])
assert(window["limit"] == 128)
assert(libstore.cache_source("../escape_mod") == nil)
assert(libstore.cached_source("../escape_mod") == nil)
assert(libstore.cache_misses_for("../escape_mod") == 0)
assert(libstore.cache_hits_for("../escape_mod") == 0)
assert(libstore.cache_source("bad/cache_mod") == nil)
assert(libstore.cached_source("bad/cache_mod") == nil)
assert(libstore.cache_misses_for("bad/cache_mod") == 0)
assert(libstore.cache_hits_for("bad/cache_mod") == 0)
assert(libstore.cache_source("missing_mod") == nil)
assert(libstore.cache_misses_for("missing_mod") == 1)
assert(libstore.cached_source("missing_mod") == nil)
assert(libstore.cache_misses_for("missing_mod") == 2)

libstore.set_policy(libstore.POLICY_SD_LAZY)
assert(libstore.cache_source("tiny_mod") == nil)
assert(libstore.cache_misses_for("tiny_mod") == 0)
libstore.set_policy(libstore.POLICY_SD_CACHE_PSRAM)

p2.info["available"] = false
libstore.cache_reset()
assert(libstore.cache_source("tiny_mod") == nil)
assert(libstore.cache_misses_for("tiny_mod") == 0)
p2.info["available"] = true

p2.info["max_transfer"] = 0
libstore.cache_reset()
expect_error(def() return libstore.cache_source("tiny_mod") end, "value_error")
assert(!libstore.cached("tiny_mod"))
assert(libstore.cache_next == libstore.cache_base)
p2.info["max_transfer"] = 4

libstore.cache_reset()
expect_error(def() return libstore.cache_source("large_mod") end, "memory_error")
assert(!libstore.cached("large_mod"))
assert(libstore.cache_next == libstore.cache_base)

libstore.known = ["tiny_mod", "large_mod"]
libstore.cache_reset()
var all_report = libstore.cache_all_report()
assert(!all_report["ok"])
assert(all_report["cached_count"] == 1)
assert(all_report["skipped_count"] == 1)
assert(all_report["items"][0]["name"] == "tiny_mod")
assert(all_report["skipped"][0]["module"] == "large_mod")
assert(all_report["skipped"][0]["error"] == "memory_error")
assert(libstore.cached("tiny_mod"))
assert(!libstore.cached("large_mod"))
assert(libstore.cache_next == libstore.cache_base + size(tiny_source))
var all_items = libstore.cache_all()
assert(all_items.size() == 1)
assert(all_items[0]["name"] == "tiny_mod")
expect_error(def() return libstore.cache_source("large_mod") end, "memory_error")

libstore.cache_reset()
var many_report = libstore.cache_many_report("tiny_mod", "large_mod", "missing_mod", "../escape_mod")
assert(!many_report["ok"])
assert(many_report["cached_count"] == 1)
assert(many_report["skipped_count"] == 3)
assert(many_report["items"][0]["name"] == "tiny_mod")
assert(many_report["skipped"][0]["module"] == "large_mod")
assert(many_report["skipped"][0]["error"] == "memory_error")
assert(many_report["skipped"][1]["module"] == "missing_mod")
assert(many_report["skipped"][1]["error"] == "source_missing")
assert(many_report["skipped"][2]["module"] == "../escape_mod")
assert(many_report["skipped"][2]["error"] == "invalid_module_name")
assert(libstore.cached("tiny_mod"))
assert(!libstore.cached("large_mod"))
assert(libstore.cache_misses_for("missing_mod") == 0)
var many_snapshot = many_report["items"][0]["source_hash"]
many_report["items"][0]["source_hash"] = 0
assert(libstore.cache_report()["items"][0]["source_hash"] == many_snapshot)

libstore.known = [
    "binary_heap",
    "configstore",
    "libstore",
    "math",
    "p2compat",
    "p2ipc",
    "p2mem",
    "task",
    "wifi"
]

p2.fail_write = true
libstore.cache_reset()
expect_error(def() return libstore.cache_source("tiny_mod") end, "io_error")
assert(!libstore.cached("tiny_mod"))
assert(libstore.cache_next == libstore.cache_base)
p2.fail_write = false

p2.short_write = true
libstore.cache_reset()
expect_error(def() return libstore.cache_source("tiny_mod") end, "io_error")
assert(!libstore.cached("tiny_mod"))
assert(libstore.cache_next == libstore.cache_base)
p2.short_write = false

p2.mem = {}
libstore.cache_reset()
var cached = libstore.cache_source("tiny_mod")
assert(cached["name"] == "tiny_mod")
assert(cached["chunk_count"] > 1)
assert(cached["cache_miss_count"] == 1)
assert(libstore.cache_misses_for("tiny_mod") == 1)
p2.fail_read = true
expect_error(def() return libstore.cached_source("tiny_mod") end, "io_error")
p2.fail_read = false
p2.short_read = true
expect_error(def() return libstore.cached_source("tiny_mod") end, "io_error")
p2.short_read = false
assert(libstore.cached_source("tiny_mod") == tiny_source)
assert(libstore.cache_hits_for("tiny_mod") >= 1)
var loaded = libstore.load("tiny_mod")
assert(loaded.answer == 42)
var report = libstore.cache_report()
assert(report["status"]["psram_cache_items"] == 1)
assert(report["items"].size() == 1)
assert(report["items"][0]["name"] == "tiny_mod")
var cached_hash = report["items"][0]["source_hash"]
report["items"][0]["source_hash"] = 0
assert(libstore.cache_report()["items"][0]["source_hash"] == cached_hash)
var status_paths_count = libstore.path_list().size()
report["status"]["paths"].push("__caller_mutated_path__")
assert(libstore.path_list().size() == status_paths_count)
var info = libstore.info("tiny_mod")
assert(info["cached"])
assert(info["cache"]["name"] == "tiny_mod")
info["cache"]["name"] = "caller_mutated"
assert(libstore.info("tiny_mod")["cache"]["name"] == "tiny_mod")
var math_info = libstore.info("math")
assert(math_info["coverage_status"] == "covered")
math_info["coverage"]["status"] = "caller_mutated"
assert(libstore.info("math")["coverage_status"] == "covered")
remove_quiet(lib_dir + "/tiny_mod.be")
var stale_report = libstore.cache_report()
assert(stale_report["status"]["psram_cache_items"] == 1)
assert(stale_report["items"].size() == 1)
assert(stale_report["items"][0]["name"] == "tiny_mod")
write_text(lib_dir + "/tiny_mod.be", tiny_source)

var updated_source = "var tiny_mod = module('tiny_mod')\n"
updated_source += "tiny_mod.answer = 43\n"
updated_source += "return tiny_mod\n"
write_text(lib_dir + "/tiny_mod.be", updated_source)
assert(libstore.cached_source("tiny_mod") == tiny_source)
assert(libstore.load("tiny_mod").answer == 42)

var reset_window = libstore.cache_reset()
assert(reset_window["available"])
assert(!libstore.cached("tiny_mod"))
assert(libstore.cache_hits_for("tiny_mod") == 0)
assert(libstore.cache_misses_for("tiny_mod") == 0)
assert(libstore.cache_next == libstore.cache_base)
var recached = libstore.cache_source("tiny_mod")
assert(recached["source_hash"] == libstore.hash_text(updated_source))
assert(recached["cache_miss_count"] == 1)
assert(libstore.cached_source("tiny_mod") == updated_source)
assert(libstore.load("tiny_mod").answer == 43)

remove_quiet(lib_dir + "/tiny_mod.be")
remove_quiet(lib_dir + "/large_mod.be")
remove_quiet(root + "/cache")
remove_quiet(lib_dir)
remove_quiet(root)
remove_quiet("tmp")
