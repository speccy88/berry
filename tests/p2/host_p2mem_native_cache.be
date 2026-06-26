# Host-side regression for p2mem's native-cache facade.
#
# The real p2.psram_cache_* implementation is native P2 code. This test uses a
# fake p2 module to cover Berry-level owner, release, verify, and warming logic.

import introspect
import os

var p2 = module("p2")
p2.mem = {}
p2.cache_entries = []
p2.cache_limit = 256
p2.cache_base = 4096
p2.fail_entry_write = false
p2.fail_entry_write_owner = nil
p2.fail_verify_owner = nil
p2.raise_verify_owner = nil
p2.raise_release_owner = nil
p2.raise_find_owner = nil
p2.raise_reset = false
p2.raise_info = false
p2.raise_entries = false
p2.psram = {
    "available": true,
    "bytes": 1024,
    "access": "block",
    "max_transfer": 16,
    "heap": false
}

def checksum(text)
    var raw = bytes().fromstring(text)
    var h = 0
    var i = 0
    while i < raw.size()
        h = (h * 33 + raw[i]) % 2147483647
        i += 1
    end
    return h
end

def reserved_size(n)
    var out = n
    if out % 8 != 0
        out += 8 - (out % 8)
    end
    return out
end

def cache_used()
    var used = 0
    for entry : p2.cache_entries
        used += entry["size"]
    end
    return used
end

def entry_at(index)
    if index < 0 || index >= size(p2.cache_entries)
        return nil
    end
    return p2.cache_entries[index]
end

def entry_or_raise(index)
    var entry = entry_at(index)
    if entry == nil
        raise "value_error", "cache entry index out of range"
    end
    return entry
end

def check_entry_range(entry, offset, n)
    if offset < 0
        raise "value_error", "offset must be >= 0"
    end
    if n < 0
        raise "value_error", "size must be >= 0"
    end
    if offset > entry["size"] || n > entry["size"] - offset
        raise "value_error", "range outside PSRAM cache entry"
    end
end

def entry_public(entry, index)
    if entry == nil
        return {
            "found": false,
            "index": -1
        }
    end
    return {
        "found": true,
        "index": index,
        "owner": entry["owner"],
        "size": entry["size"],
        "used": entry["used"],
        "write_count": entry["write_count"],
        "last_write_checksum": entry["last_write_checksum"]
    }
end

p2.psram_info = def()
    return p2.psram
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
    p2.mem[address] = data
    return {
        "ok": true,
        "size": size(data)
    }
end
p2.psram_read = def(address, n)
    return p2.mem[address]
end
p2.psram_cache_info = def()
    if p2.raise_info
        raise "value_error", "forced cache info exception"
    end
    var used = cache_used()
    return {
        "available": true,
        "base": p2.cache_base,
        "limit": p2.cache_limit,
        "used": used,
        "free": p2.cache_limit - used,
        "entry_count": size(p2.cache_entries),
        "entry_max": 16,
        "libstore_base": 0
    }
end
p2.psram_cache_entries = def()
    if p2.raise_entries
        raise "value_error", "forced cache entries exception"
    end
    var out = []
    var i = 0
    while i < size(p2.cache_entries)
        out.push(entry_public(p2.cache_entries[i], i))
        i += 1
    end
    return out
end
p2.psram_cache_reserve = def(n, owner)
    if type(n) != "int" || n <= 0
        raise "value_error", "cache reservation size must be > 0"
    end
    var reserve = reserved_size(n)
    var info = p2.psram_cache_info()
    if reserve > info["free"]
        return {
            "ok": false,
            "index": -1,
            "owner": owner,
            "size": reserve,
            "used": 0,
            "reason": "insufficient_native_cache"
        }
    end
    var index = size(p2.cache_entries)
    var entry = {
        "owner": owner,
        "size": reserve,
        "used": 0,
        "data": "",
        "write_count": 0,
        "last_write_checksum": 0
    }
    p2.cache_entries.push(entry)
    var out = entry_public(entry, index)
    out["ok"] = true
    return out
end
p2.psram_cache_write_entry = def(index, offset, data)
    var entry = entry_or_raise(index)
    if p2.fail_entry_write || (entry != nil && p2.fail_entry_write_owner == entry["owner"])
        return {
            "ok": false,
            "index": index,
            "written": 0
        }
    end
    check_entry_range(entry, offset, size(data))
    entry["data"] = data
    entry["used"] = offset + size(data)
    entry["write_count"] += 1
    entry["last_write_checksum"] = checksum(data)
    return {
        "ok": true,
        "index": index,
        "written": size(data)
    }
end
p2.psram_cache_read_entry = def(index, offset, n)
    var entry = entry_or_raise(index)
    check_entry_range(entry, offset, n)
    return entry["data"][offset..(offset + n - 1)]
end
p2.psram_cache_verify_entry = def(index)
    var entry = entry_or_raise(index)
    if p2.raise_verify_owner == entry["owner"]
        raise "value_error", "forced verify exception"
    end
    if p2.fail_verify_owner == entry["owner"]
        return {
            "ok": false,
            "index": index,
            "owner": entry["owner"],
            "reason": "forced_verify_failure",
            "checksum": checksum(entry["data"]),
            "expected": entry["last_write_checksum"]
        }
    end
    return {
        "ok": entry["used"] > 0 && checksum(entry["data"]) == entry["last_write_checksum"],
        "index": index,
        "owner": entry["owner"],
        "checksum": checksum(entry["data"]),
        "expected": entry["last_write_checksum"]
    }
end
p2.psram_cache_find = def(owner)
    if p2.raise_find_owner == owner
        raise "value_error", "forced find exception"
    end
    var items = []
    var i = 0
    while i < size(p2.cache_entries)
        if p2.cache_entries[i]["owner"] == owner
            items.push(entry_public(p2.cache_entries[i], i))
        end
        i += 1
    end
    return {
        "owner": owner,
        "found": size(items) > 0,
        "count": size(items),
        "items": items
    }
end
p2.psram_cache_find_latest = def(owner)
    if p2.raise_find_owner == owner
        raise "value_error", "forced latest exception"
    end
    var i = size(p2.cache_entries) - 1
    while i >= 0
        if p2.cache_entries[i]["owner"] == owner
            return entry_public(p2.cache_entries[i], i)
        end
        i -= 1
    end
    return {
        "found": false,
        "index": -1,
        "owner": owner
    }
end
p2.psram_cache_release = def(index)
    var entry = entry_or_raise(index)
    if p2.raise_release_owner == entry["owner"]
        raise "value_error", "forced release exception"
    end
    if index != size(p2.cache_entries) - 1
        return {
            "ok": false,
            "released": false,
            "index": index,
            "reason": "not_latest"
        }
    end
    p2.cache_entries.remove(index)
    return {
        "ok": true,
        "released": true,
        "index": index,
        "owner": entry["owner"],
        "size": entry["size"]
    }
end
p2.psram_cache_reset = def()
    if p2.raise_reset
        raise "value_error", "forced reset exception"
    end
    p2.cache_entries = []
    return p2.psram_cache_info()
end

introspect.setmodule("p2", p2)

var libstore = run_file("modules/libstore.be")
var p2mem = run_file("modules/p2mem.be")

var root = "tmp/p2_host_native_cache"
var lib_dir = root + "/lib"
libstore.paths = [lib_dir]
libstore.compiled_paths = [root + "/cache"]
libstore.cache_limit_requested = 256
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

remove_quiet(lib_dir + "/native_cache_mod.be")
remove_quiet(lib_dir + "/native_cache_fail.be")
libstore._ensure_dir(lib_dir)

var source_text = "var native_cache_mod = module('native_cache_mod')\n"
source_text += "native_cache_mod.answer = 42\n"
source_text += "return native_cache_mod\n"
write_text(lib_dir + "/native_cache_mod.be", source_text)

var fail_source_text = "var native_cache_fail = module('native_cache_fail')\n"
fail_source_text += "native_cache_fail.answer = 99\n"
fail_source_text += "return native_cache_fail\n"
write_text(lib_dir + "/native_cache_fail.be", fail_source_text)

var native = p2mem.native_cache()
assert(native["available"])
assert(native["entry_count"] == 0)
assert(native["free"] == 256)
p2.raise_info = true
var native_info_error = p2mem.native_cache()
assert(!native_info_error["available"])
assert(native_info_error["status"] == nil)
assert(native_info_error["entry_count"] == 0)
assert(native_info_error["free"] == 0)
assert(native_info_error["error"] == "value_error")
p2.raise_info = false
p2.raise_entries = true
var native_entries_error = p2mem.native_cache()
p2.raise_entries = false
assert(!native_entries_error["available"])
assert(native_entries_error["status"]["available"])
assert(native_entries_error["entry_count"] == 0)
assert(native_entries_error["free"] == 256)
assert(native_entries_error["error"] == "value_error")
assert(p2mem.native_cache_reset_result()["ok"])
p2.raise_reset = true
var reset_raised = p2mem.native_cache_reset_result()
assert(!reset_raised["ok"])
assert(reset_raised["error"] == "value_error")
p2.raise_reset = false

var alpha = p2mem.native_cache_put_verified("alpha", "abc")
assert(alpha["ok"])
assert(alpha["verified"])
assert(alpha["index"] == 0)
assert(alpha["write"]["ok"])
assert(p2mem.native_cache_get("alpha") == "abc")
assert(p2mem.native_cache_get_result("alpha")["value"] == "abc")
assert(p2mem.native_cache_get_verified("alpha")["value"] == "abc")
assert(p2mem.native_cache_status("alpha")["verified"])
var missing_get = p2mem.native_cache_get_result("missing-owner")
assert(!missing_get["ok"])
assert(!missing_get["found"])
assert(missing_get["error"] == "owner reservation not found")

var alpha2 = p2mem.native_cache_put_verified("alpha", "abcd")
assert(alpha2["ok"])
assert(alpha2["index"] == 1)
assert(p2mem.native_cache_find("alpha")["count"] == 2)
assert(p2mem.native_cache_find_latest("alpha")["index"] == 1)

var beta = p2mem.native_cache_put_verified("beta", "xy")
assert(beta["ok"])
assert(p2mem.native_cache_release_owner("alpha")["released"] == false)
assert(p2mem.native_cache_release_owner("beta")["released"])
var alpha_chain = p2mem.native_cache_release_owner_chain("alpha")
assert(alpha_chain["ok"])
assert(alpha_chain["released_count"] == 2)
assert(!alpha_chain["remaining"]["found"])
assert(p2mem.native_cache()["entry_count"] == 0)

p2.raise_find_owner = "lookup-raise"
var lookup_history = p2mem.native_cache_owner_history("lookup-raise")
assert(!lookup_history["ok"])
assert(!lookup_history["found"])
assert(lookup_history["error"] == "value_error")
var lookup_status = p2mem.native_cache_status("lookup-raise")
assert(!lookup_status["ok"])
assert(!lookup_status["found"])
assert(lookup_status["error"] == "owner lookup failed")
assert(lookup_status["latest"]["error"] == "value_error")
var lookup_get = p2mem.native_cache_get_verified("lookup-raise")
assert(!lookup_get["ok"])
assert(!lookup_get["found"])
assert(lookup_get["error"] == "owner lookup failed")
var lookup_plain_get = p2mem.native_cache_get_result("lookup-raise")
assert(!lookup_plain_get["ok"])
assert(!lookup_plain_get["found"])
assert(lookup_plain_get["error"] == "owner lookup failed")
var lookup_verify = p2mem.native_cache_verify_owner("lookup-raise")
assert(!lookup_verify["ok"])
assert(!lookup_verify["found"])
assert(lookup_verify["error"] == "owner lookup failed")
var lookup_release = p2mem.native_cache_release_owner("lookup-raise")
assert(!lookup_release["ok"])
assert(!lookup_release["released"])
assert(lookup_release["error"] == "owner lookup failed")
var lookup_chain = p2mem.native_cache_release_owner_chain("lookup-raise")
assert(!lookup_chain["ok"])
assert(lookup_chain["released_count"] == 0)
assert(lookup_chain["blocked"]["error"] == "owner lookup failed")
assert(!lookup_chain["remaining"]["ok"])
var lookup_replace = p2mem.native_cache_replace_verified("lookup-raise", "payload")
assert(!lookup_replace["ok"])
assert(!lookup_replace["verified"])
assert(lookup_replace["error"] == "owner lookup failed")
assert(lookup_replace["write"]["reason"] == "owner_lookup_failed")
assert(p2mem.native_cache()["entry_count"] == 0)
p2.raise_find_owner = nil

var source_owner = p2mem.native_source_owner("config")
assert(source_owner == "source:config")
var source_put = p2mem.native_source_put_verified("config", "payload")
assert(source_put["ok"])
assert(p2mem.native_source_status("config")["verified"])
assert(p2mem.native_source_get_verified("config")["value"] == "payload")
assert(p2mem.native_source_release("config")["released_count"] == 1)

var diag = p2mem.native_cache_put_verified("diag", "abcd")
assert(diag["ok"])
assert(p2mem.native_cache_read_result(diag["index"], 1, 2)["value"] == "bc")
assert(p2mem.native_cache_verify_result(diag["index"])["ok"])
var bad_reserve_size = p2mem.native_cache_reserve_result(0, "bad-reserve")
assert(!bad_reserve_size["ok"])
assert(bad_reserve_size["error"] == "value_error")
var bad_reserve_type = p2mem.native_cache_reserve_result("bad", nil)
assert(!bad_reserve_type["ok"])
assert(bad_reserve_type["owner"] == "p2mem")
assert(bad_reserve_type["error"] == "value_error")
var bad_put_payload = p2mem.native_cache_put_verified("bad-put", nil)
assert(!bad_put_payload["ok"])
assert(!bad_put_payload["verified"])
assert(bad_put_payload["index"] == -1)
assert(!bad_put_payload["write"]["ok"])
assert(!bad_put_payload["release"]["released"])
assert(bad_put_payload["release"]["reason"] == "reservation_not_created")
var bad_read_index = p2mem.native_cache_read_result(99, 0, 1)
assert(!bad_read_index["ok"])
assert(bad_read_index["error"] == "value_error")
var bad_read_range = p2mem.native_cache_read_result(diag["index"], -1, 1)
assert(!bad_read_range["ok"])
assert(bad_read_range["error"] == "value_error")
var bad_write_range = p2mem.native_cache_write_result(diag["index"], 7, "xy")
assert(!bad_write_range["ok"])
assert(bad_write_range["error"] == "value_error")
var bad_verify_index = p2mem.native_cache_verify_result(99)
assert(!bad_verify_index["ok"])
assert(bad_verify_index["error"] == "value_error")
var verify_raise_owner = p2mem.native_cache_put_verified("verify-raise-owner", "ok")
assert(verify_raise_owner["ok"])
p2.raise_verify_owner = "verify-raise-owner"
var verify_raise_status = p2mem.native_cache_status("verify-raise-owner")
assert(!verify_raise_status["ok"])
assert(verify_raise_status["verify"]["error"] == "value_error")
var verify_raise_get = p2mem.native_cache_get_verified("verify-raise-owner")
assert(!verify_raise_get["ok"])
assert(verify_raise_get["found"])
assert(verify_raise_get["value"] == nil)
assert(verify_raise_get["verify"]["error"] == "value_error")
p2.raise_verify_owner = nil
assert(p2mem.native_cache_release_result(verify_raise_owner["index"])["released"])
var unreadable_owner = p2mem.native_cache_put_verified("unreadable-owner", "ok")
assert(unreadable_owner["ok"])
p2.cache_entries[unreadable_owner["index"]]["used"] = p2.cache_entries[unreadable_owner["index"]]["size"] + 1
var unreadable_get = p2mem.native_cache_get_verified("unreadable-owner")
assert(!unreadable_get["ok"])
assert(unreadable_get["verify"]["ok"])
assert(!unreadable_get["read"]["ok"])
assert(unreadable_get["read"]["error"] == "value_error")
var unreadable_plain_get = p2mem.native_cache_get_result("unreadable-owner")
assert(!unreadable_plain_get["ok"])
assert(unreadable_plain_get["found"])
assert(unreadable_plain_get["read"]["error"] == "value_error")
p2.cache_entries[unreadable_owner["index"]]["used"] = size("ok")
assert(p2mem.native_cache_release_result(unreadable_owner["index"])["released"])
var bad_release_index = p2mem.native_cache_release_result(99)
assert(!bad_release_index["ok"])
assert(!bad_release_index["released"])
assert(bad_release_index["error"] == "value_error")
assert(p2mem.native_cache_release_result(diag["index"])["released"])

var lifo_base = p2mem.native_cache_put_verified("lifo-base", "base")
var lifo_top = p2mem.native_cache_put_verified("lifo-top", "top")
assert(lifo_base["ok"])
assert(lifo_top["ok"])
var blocked_release = p2mem.native_cache_release_result(lifo_base["index"])
assert(!blocked_release["ok"])
assert(!blocked_release["released"])
assert(blocked_release["reason"] == "not_latest")
assert(p2mem.native_cache_release_result(lifo_top["index"])["released"])
assert(p2mem.native_cache_release_result(lifo_base["index"])["released"])

var release_raise = p2mem.native_cache_put_verified("release-raise", "rr")
assert(release_raise["ok"])
p2.raise_release_owner = "release-raise"
var release_raise_result = p2mem.native_cache_release_owner("release-raise")
assert(!release_raise_result["ok"])
assert(!release_raise_result["released"])
assert(release_raise_result["release"]["error"] == "value_error")
p2.raise_release_owner = nil
assert(p2mem.native_cache_release_owner("release-raise")["released"])

var chain_raise_a = p2mem.native_cache_put_verified("chain-raise", "a")
var chain_raise_b = p2mem.native_cache_put_verified("chain-raise", "b")
assert(chain_raise_a["ok"])
assert(chain_raise_b["ok"])
p2.raise_release_owner = "chain-raise"
var chain_raise = p2mem.native_cache_release_owner_chain("chain-raise")
assert(!chain_raise["ok"])
assert(chain_raise["released_count"] == 0)
assert(chain_raise["blocked"]["release"]["error"] == "value_error")
assert(chain_raise["remaining"]["found"])
p2.raise_release_owner = nil
var chain_raise_cleanup = p2mem.native_cache_release_owner_chain("chain-raise")
assert(chain_raise_cleanup["ok"])
assert(chain_raise_cleanup["released_count"] == 2)

var replace_first = p2mem.native_cache_replace_verified("replace", "old")
assert(replace_first["ok"])
assert(!replace_first["replaced"])
var replace_second = p2mem.native_cache_replace_verified("replace", "new")
assert(replace_second["ok"])
assert(replace_second["replaced"])
assert(replace_second["previous_retained"])
assert(replace_second["previous"]["found"])
assert(p2mem.native_cache_find("replace")["count"] == 2)
assert(p2mem.native_cache_get("replace") == "new")
var replace_release = p2mem.native_cache_release_owner_chain("replace")
assert(replace_release["released_count"] == 2)
assert(!replace_release["remaining"]["found"])

var blocker = p2mem.native_cache_put_verified("blocker", "b")
var replace_base = p2mem.native_cache_put_verified("replace-blocked", "old")
assert(blocker["ok"])
assert(replace_base["ok"])
var top = p2mem.native_cache_put_verified("top", "t")
assert(top["ok"])
var replace_blocked = p2mem.native_cache_replace_verified("replace-blocked", "new")
assert(replace_blocked["ok"])
assert(replace_blocked["previous_retained"])
assert(p2mem.native_cache_get("replace-blocked") == "new")
assert(p2mem.native_cache_release_owner("replace-blocked")["released"])
assert(p2mem.native_cache_release_owner("top")["released"])
assert(p2mem.native_cache_release_owner("replace-blocked")["released"])
assert(p2mem.native_cache_release_owner("blocker")["released"])

var preserve_base = p2mem.native_cache_put_verified("replace-fail", "old")
assert(preserve_base["ok"])
p2.fail_entry_write_owner = "replace-fail"
var preserve_failed = p2mem.native_cache_replace_verified("replace-fail", "new")
assert(!preserve_failed["ok"])
assert(preserve_failed["replaced"])
assert(preserve_failed["previous_retained"])
assert(preserve_failed["release"]["released"])
assert(p2mem.native_cache_get("replace-fail") == "old")
p2.fail_entry_write_owner = nil
assert(p2mem.native_cache_release_owner("replace-fail")["released"])

p2.fail_verify_owner = "verify-fail"
var verify_failed = p2mem.native_cache_put_verified("verify-fail", "payload")
assert(!verify_failed["ok"])
assert(!verify_failed["verified"])
assert(verify_failed["error"] == "native cache verify failed")
assert(verify_failed["verify"]["reason"] == "forced_verify_failure")
assert(verify_failed["release"]["released"])
assert(p2mem.native_cache()["entry_count"] == 0)
p2.fail_verify_owner = nil

p2.raise_verify_owner = "verify-raise-put"
var verify_raise_put = p2mem.native_cache_put_verified("verify-raise-put", "payload")
assert(!verify_raise_put["ok"])
assert(!verify_raise_put["verified"])
assert(verify_raise_put["error"] == "native cache verify failed")
assert(verify_raise_put["verify"]["error"] == "value_error")
assert(verify_raise_put["release"]["released"])
assert(p2mem.native_cache()["entry_count"] == 0)
p2.raise_verify_owner = nil

var verify_owner_base = p2mem.native_cache_put_verified("verify-owner-raise", "payload")
assert(verify_owner_base["ok"])
p2.raise_verify_owner = "verify-owner-raise"
var verify_owner_raised = p2mem.native_cache_verify_owner("verify-owner-raise")
assert(!verify_owner_raised["ok"])
assert(verify_owner_raised["found"])
assert(verify_owner_raised["error"] == "value_error")
p2.raise_verify_owner = nil
assert(p2mem.native_cache_release_result(verify_owner_base["index"])["released"])

var verify_base = p2mem.native_cache_put_verified("replace-verify-fail", "old")
assert(verify_base["ok"])
p2.fail_verify_owner = "replace-verify-fail"
var verify_replace = p2mem.native_cache_replace_verified("replace-verify-fail", "new")
assert(!verify_replace["ok"])
assert(!verify_replace["verified"])
assert(verify_replace["error"] == "native cache verify failed")
assert(verify_replace["replaced"])
assert(verify_replace["previous_retained"])
assert(verify_replace["release"]["released"])
assert(p2mem.native_cache_get("replace-verify-fail") == "old")
p2.fail_verify_owner = nil
assert(p2mem.native_cache_release_owner("replace-verify-fail")["released"])

var verify_raise_base = p2mem.native_cache_put_verified("replace-verify-raise", "old")
assert(verify_raise_base["ok"])
p2.raise_verify_owner = "replace-verify-raise"
var verify_raise_replace = p2mem.native_cache_replace_verified("replace-verify-raise", "new")
assert(!verify_raise_replace["ok"])
assert(!verify_raise_replace["verified"])
assert(verify_raise_replace["error"] == "native cache verify failed")
assert(verify_raise_replace["verify"]["error"] == "value_error")
assert(verify_raise_replace["release"]["released"])
assert(p2mem.native_cache_get("replace-verify-raise") == "old")
p2.raise_verify_owner = nil
assert(p2mem.native_cache_release_owner("replace-verify-raise")["released"])

var too_big = p2mem.native_cache_put_verified("too-big", "0123456789" * 40)
assert(!too_big["ok"])
assert(!too_big["verified"])
assert(too_big["verify"] == nil)

p2.fail_entry_write = true
var failed_write = p2mem.native_cache_put_verified("failed-write", "payload")
assert(!failed_write["ok"])
assert(!failed_write["verified"])
assert(failed_write["error"] == "native cache write failed")
assert(failed_write["write"]["ok"] == false)
assert(failed_write["release"]["released"])
assert(p2mem.native_cache()["entry_count"] == 0)
p2.fail_entry_write = false

p2.fail_entry_write_owner = "failed-write-release-raise"
p2.raise_release_owner = "failed-write-release-raise"
var failed_write_release = p2mem.native_cache_put_verified("failed-write-release-raise", "payload")
assert(!failed_write_release["ok"])
assert(!failed_write_release["verified"])
assert(failed_write_release["error"] == "native cache write failed")
assert(!failed_write_release["release"]["ok"])
assert(!failed_write_release["release"]["released"])
assert(failed_write_release["release"]["error"] == "value_error")
assert(p2mem.native_cache()["entry_count"] == 1)
p2.fail_entry_write_owner = nil
p2.raise_release_owner = nil
assert(p2mem.native_cache_release_owner("failed-write-release-raise")["released"])
assert(p2mem.native_cache()["entry_count"] == 0)

libstore.cache_reset()
var invalid_plan_type = p2mem.native_module_sources_plan("native_cache_mod")
assert(!invalid_plan_type["ok"])
assert(invalid_plan_type["error"] == "invalid_module_names")
assert(invalid_plan_type["blocker"] == "invalid_module_names")
assert(!invalid_plan_type["will_fit"])
var invalid_plan_name = p2mem.native_module_sources_plan(["native_cache_mod", ""])
assert(!invalid_plan_name["ok"])
assert(invalid_plan_name["requested"] == 2)
assert(invalid_plan_name["error"] == "invalid_module_names")
assert(invalid_plan_name["message"] == "module name must be a non-empty string")
var invalid_plan_escape = p2mem.native_module_sources_plan(["native_cache_mod", "../native_cache_escape"])
assert(!invalid_plan_escape["ok"])
assert(invalid_plan_escape["requested"] == 2)
assert(invalid_plan_escape["error"] == "invalid_module_names")
assert(invalid_plan_escape["message"] == "module name must not contain path separators or dot-dot segments")
assert(invalid_plan_escape["blocker"] == "invalid_module_names")
var invalid_warm_if_fits = p2mem.native_module_sources_warm_if_fits([""])
assert(!invalid_warm_if_fits["ok"])
assert(!invalid_warm_if_fits["warmed"])
assert(invalid_warm_if_fits["reason"] == "invalid_module_names")
var invalid_warm_escape = p2mem.native_module_sources_warm_if_fits(["native/cache_escape"])
assert(!invalid_warm_escape["ok"])
assert(!invalid_warm_escape["warmed"])
assert(invalid_warm_escape["reason"] == "invalid_module_names")
var invalid_warm_verified = p2mem.native_module_sources_warm_verified(["native_cache_mod", nil])
assert(!invalid_warm_verified["ok"])
assert(invalid_warm_verified["fail_count"] == 0)
assert(!invalid_warm_verified["rolled_back"])
var invalid_warm_verified_escape = p2mem.native_module_sources_warm_verified(["native_cache_mod", "native_cache_pkg..mod"])
assert(!invalid_warm_verified_escape["ok"])
assert(invalid_warm_verified_escape["fail_count"] == 0)
assert(!invalid_warm_verified_escape["rolled_back"])
var invalid_status = p2mem.native_module_sources_status([nil])
assert(!invalid_status["ok"])
assert(invalid_status["missing_count"] == 0)
var invalid_status_escape = p2mem.native_module_sources_status(["../native_cache_escape"])
assert(!invalid_status_escape["ok"])
assert(invalid_status_escape["missing_count"] == 0)
var invalid_release = p2mem.native_module_sources_release("native_cache_mod")
assert(!invalid_release["ok"])
assert(invalid_release["released_count"] == 0)
var invalid_release_escape = p2mem.native_module_sources_release(["native/cache_escape"])
assert(!invalid_release_escape["ok"])
assert(invalid_release_escape["released_count"] == 0)

var invalid_single_put = p2mem.native_module_source_put_verified(nil)
assert(!invalid_single_put["ok"])
assert(invalid_single_put["error"] == "invalid_module_name")
var invalid_single_put_escape = p2mem.native_module_source_put_verified("../native_cache_escape")
assert(!invalid_single_put_escape["ok"])
assert(invalid_single_put_escape["found"] == false)
assert(invalid_single_put_escape["owner"] == nil)
assert(invalid_single_put_escape["error"] == "invalid_module_name")
assert(invalid_single_put_escape["message"] == "module name must not contain path separators or dot-dot segments")
var invalid_single_status = p2mem.native_module_source_status("")
assert(!invalid_single_status["ok"])
assert(invalid_single_status["error"] == "invalid_module_name")
assert(!invalid_single_status["verified"])
var invalid_single_status_escape = p2mem.native_module_source_status("native/cache_escape")
assert(!invalid_single_status_escape["ok"])
assert(invalid_single_status_escape["index"] == -1)
assert(invalid_single_status_escape["error"] == "invalid_module_name")
var invalid_single_get = p2mem.native_module_source_get_verified(nil)
assert(!invalid_single_get["ok"])
assert(invalid_single_get["value"] == nil)
assert(invalid_single_get["error"] == "invalid_module_name")
var invalid_single_get_escape = p2mem.native_module_source_get_verified("native_cache_pkg..mod")
assert(!invalid_single_get_escape["ok"])
assert(invalid_single_get_escape["value"] == nil)
assert(invalid_single_get_escape["error"] == "invalid_module_name")
var invalid_single_release = p2mem.native_module_source_release("")
assert(!invalid_single_release["ok"])
assert(invalid_single_release["released_count"] == 0)
assert(invalid_single_release["error"] == "invalid_module_name")
var invalid_single_release_escape = p2mem.native_module_source_release("../native_cache_escape")
assert(!invalid_single_release_escape["ok"])
assert(invalid_single_release_escape["released_count"] == 0)
assert(invalid_single_release_escape["error"] == "invalid_module_name")

var module_plan = p2mem.native_module_sources_plan(["native_cache_mod"])
assert(module_plan["ok"])
assert(module_plan["found_count"] == 1)
assert(module_plan["missing_count"] == 0)
assert(module_plan["will_fit"])
assert(module_plan["native_available"])
assert(module_plan["blocker"] == "ok")
assert(module_plan["total_bytes"] == size(source_text))

var missing_plan = p2mem.native_module_sources_plan(["native_cache_mod", "missing_native_cache_mod"])
assert(!missing_plan["ok"])
assert(missing_plan["missing_count"] == 1)
assert(missing_plan["blocker"] == "missing_source")
assert(!p2mem.native_module_sources_warm_if_fits(["native_cache_mod", "missing_native_cache_mod"])["warmed"])

p2.raise_info = true
var unavailable_plan = p2mem.native_module_sources_plan(["native_cache_mod"])
assert(!unavailable_plan["ok"])
assert(!unavailable_plan["native_available"])
assert(unavailable_plan["native_error"] == "value_error")
assert(unavailable_plan["blocker"] == "native_cache_unavailable")
assert(!unavailable_plan["will_fit"])
var unavailable_warm = p2mem.native_module_sources_warm_if_fits(["native_cache_mod"])
assert(!unavailable_warm["ok"])
assert(!unavailable_warm["warmed"])
assert(unavailable_warm["reason"] == "native_cache_unavailable")
p2.raise_info = false

p2.fail_entry_write_owner = p2mem.native_module_source_owner("native_cache_fail")
var batch_fail = p2mem.native_module_sources_warm_verified(["native_cache_mod", "native_cache_fail"])
assert(!batch_fail["ok"])
assert(batch_fail["ok_count"] == 1)
assert(batch_fail["fail_count"] == 1)
assert(batch_fail["rolled_back"])
assert(batch_fail["rollback_ok"])
assert(batch_fail["rollback"]["released_count"] == 1)
assert(p2mem.native_cache()["entry_count"] == 0)
p2.fail_entry_write_owner = nil

var warm = p2mem.native_module_sources_warm_if_fits(["native_cache_mod"])
assert(warm["ok"])
assert(warm["warmed"])
var module_status = p2mem.native_module_sources_status(["native_cache_mod"])
assert(module_status["ok"])
assert(module_status["ok_count"] == 1)
assert(p2mem.native_module_source_get_verified("native_cache_mod")["value"] == source_text)
var release_modules = p2mem.native_module_sources_release(["native_cache_mod"])
assert(release_modules["ok"])
assert(release_modules["released_count"] == 1)

remove_quiet(lib_dir + "/native_cache_mod.be")
remove_quiet(lib_dir + "/native_cache_fail.be")
remove_quiet(root + "/cache")
remove_quiet(lib_dir)
remove_quiet(root)
remove_quiet("tmp")
