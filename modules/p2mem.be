# P2 memory and library-cache diagnostics.
#
# This module is intentionally a reporting layer over the current P2 runtime
# state. It does not claim a complete bytecode/object cache yet; unsupported or
# not-yet-tracked metadata is returned as nil so coverage stays honest.

import gc
import libstore
import p2

var p2mem = module("p2mem")

p2mem._cache_item_for = def(report, name)
    for item : report["items"]
        if item["name"] == name
            return item
        end
    end
    return nil
end

p2mem._module_record = def(name, report)
    var info = libstore.info(name)
    var cached = p2mem._cache_item_for(report, name)
    var psram_bytes = cached == nil ? 0 : cached["size"]
    var storage_tier = cached == nil ? "sd" : "sd+psram_source_cache"

    return {
        "module": name,
        "name": name,
        "source_path": info["path"],
        "compiled_path": nil,
        "storage_tier": storage_tier,
        "source_hash": nil,
        "compiled_hash": nil,
        "mtime": nil,
        "hub_bytes_used": 0,
        "psram_bytes_used": psram_bytes,
        "cache_hit_count": 0,
        "cache_miss_count": 0,
        "refcount": nil,
        "pinned": false,
        "last_used": nil,
        "exists": info["exists"],
        "cached": cached != nil,
        "cache": cached
    }
end

p2mem.native_cache = def()
    var status = nil
    var entries = []

    try
        status = p2.psram_cache_info()
        entries = p2.psram_cache_entries()
    except .. as e, m
        return {
            "available": false,
            "status": nil,
            "entries": [],
            "entry_count": 0,
            "entry_max": 0,
            "used": 0,
            "free": 0,
            "error": e,
            "message": m
        }
    end

    return {
        "available": status["available"],
        "status": status,
        "entries": entries,
        "entry_count": status["entry_count"],
        "entry_max": status["entry_max"],
        "used": status["used"],
        "free": status["free"],
        "base": status["base"],
        "limit": status["limit"],
        "libstore_base": status["libstore_base"]
    }
end

p2mem.native_cache_reserve = def(size, owner)
    if owner == nil {
        owner = "p2mem"
    }
    return p2.psram_cache_reserve(size, owner)
end

p2mem.native_cache_reset = def()
    return p2.psram_cache_reset()
end

p2mem.native_cache_find = def(owner)
    return p2.psram_cache_find(owner)
end

p2mem.native_cache_owner_history = def(owner)
    return p2mem.native_cache_find(owner)
end

p2mem.native_cache_find_latest = def(owner)
    return p2.psram_cache_find_latest(owner)
end

p2mem.native_cache_release = def(index)
    return p2.psram_cache_release(index)
end

p2mem.native_cache_release_owner = def(owner)
    var latest = p2mem.native_cache_find_latest(owner)
    if !latest["found"] {
        return {
            "ok": false,
            "released": false,
            "error": "owner reservation not found",
            "latest": latest
        }
    }
    var released = p2mem.native_cache_release(latest["index"])
    if !released["released"] {
        return {
            "ok": false,
            "released": false,
            "error": "latest owner reservation is not the newest cache entry",
            "latest": latest,
            "release": released
        }
    }
    released["ok"] = true
    released["latest"] = latest
    return released
end

p2mem.native_cache_release_owner_chain = def(owner)
    var released = []
    var blocked = nil
    var done = false

    while !done
        var latest = p2mem.native_cache_find_latest(owner)
        if !latest["found"] {
            done = true
        } else {
            var item = p2mem.native_cache_release_owner(owner)
            if item["released"] {
                released.push(item)
            } else {
                blocked = item
                done = true
            }
        }
    end

    return {
        "ok": blocked == nil,
        "released_count": size(released),
        "released": released,
        "blocked": blocked,
        "remaining": p2mem.native_cache_find(owner)
    }
end

p2mem.native_cache_read = def(index, offset, size)
    return p2.psram_cache_read_entry(index, offset, size)
end

p2mem.native_cache_write = def(index, offset, data)
    return p2.psram_cache_write_entry(index, offset, data)
end

p2mem.native_cache_verify = def(index)
    return p2.psram_cache_verify_entry(index)
end

p2mem.native_cache_put = def(owner, data)
    var reservation = p2mem.native_cache_reserve(size(data), owner)
    if reservation["ok"] {
        reservation["write"] = p2mem.native_cache_write(reservation["index"], 0, data)
    }
    return reservation
end

p2mem.native_cache_put_verified = def(owner, data)
    var out = p2mem.native_cache_put(owner, data)
    if !out["ok"] {
        out["verified"] = false
        out["verify"] = nil
        return out
    }
    var verify = p2mem.native_cache_verify(out["index"])
    out["verify"] = verify
    out["verified"] = verify["ok"]
    out["ok"] = out["ok"] && verify["ok"]
    return out
end

p2mem.native_cache_get = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"] {
        return nil
    }
    var bytes = item.contains("used") ? item["used"] : item["size"]
    return p2mem.native_cache_read(item["index"], 0, bytes)
end

p2mem.native_cache_verify_owner = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"] {
        return {
            "ok": false,
            "found": false,
            "owner": owner
        }
    }
    var out = p2mem.native_cache_verify(item["index"])
    out["found"] = true
    return out
end

p2mem.native_cache_get_verified = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"] {
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "value": nil,
            "verify": nil
        }
    }

    var verify = p2mem.native_cache_verify(item["index"])
    if !verify["ok"] {
        return {
            "ok": false,
            "found": true,
            "owner": owner,
            "index": item["index"],
            "value": nil,
            "verify": verify
        }
    }

    var bytes = item.contains("used") ? item["used"] : item["size"]
    return {
        "ok": true,
        "found": true,
        "owner": owner,
        "index": item["index"],
        "value": p2mem.native_cache_read(item["index"], 0, bytes),
        "verify": verify
    }
end

p2mem.native_cache_status = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"] {
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "index": -1,
            "used": 0,
            "size": 0,
            "verified": false,
            "verify": nil
        }
    }

    var verify = p2mem.native_cache_verify(item["index"])
    return {
        "ok": verify["ok"],
        "found": true,
        "owner": owner,
        "index": item["index"],
        "used": item["used"],
        "size": item["size"],
        "write_count": item["write_count"],
        "last_write_checksum": item["last_write_checksum"],
        "verified": verify["ok"],
        "verify": verify
    }
end

p2mem.native_source_owner = def(name)
    return "source:" + name
end

p2mem.native_source_put_verified = def(name, source)
    return p2mem.native_cache_put_verified(p2mem.native_source_owner(name), source)
end

p2mem.native_source_status = def(name)
    return p2mem.native_cache_status(p2mem.native_source_owner(name))
end

p2mem.native_source_get_verified = def(name)
    return p2mem.native_cache_get_verified(p2mem.native_source_owner(name))
end

p2mem.native_source_release = def(name)
    return p2mem.native_cache_release_owner_chain(p2mem.native_source_owner(name))
end

p2mem.native_module_source_owner = def(name)
    return "module-source:" + name
end

p2mem.native_module_source_put_verified = def(name)
    var source = libstore.cached_source(name)
    if source == nil {
        return {
            "ok": false,
            "found": false,
            "module": name,
            "owner": p2mem.native_module_source_owner(name)
        }
    }
    var out = p2mem.native_cache_put_verified(p2mem.native_module_source_owner(name), source)
    out["found"] = true
    out["module"] = name
    return out
end

p2mem.native_module_source_status = def(name)
    return p2mem.native_cache_status(p2mem.native_module_source_owner(name))
end

p2mem.native_module_source_get_verified = def(name)
    return p2mem.native_cache_get_verified(p2mem.native_module_source_owner(name))
end

p2mem.native_module_source_release = def(name)
    return p2mem.native_cache_release_owner_chain(p2mem.native_module_source_owner(name))
end

p2mem.native_module_sources_plan = def(names)
    var items = []
    var total_bytes = 0
    var total_reserved_bytes = 0
    var found_count = 0
    var missing_count = 0
    var native = p2mem.native_cache()
    var cache_free = native["free"]

    for name : names
        var source = libstore.cached_source(name)
        var found = source != nil
        var bytes = found ? size(source) : 0
        var reserved_bytes = bytes
        if reserved_bytes % 8 != 0 {
            reserved_bytes += 8 - (reserved_bytes % 8)
        }
        var item = {
            "module": name,
            "owner": p2mem.native_module_source_owner(name),
            "found": found,
            "bytes": bytes,
            "reserved_bytes": reserved_bytes
        }
        items.push(item)
        if found {
            found_count += 1
            total_bytes += bytes
            total_reserved_bytes += reserved_bytes
        } else {
            missing_count += 1
        }
    end

    return {
        "ok": missing_count == 0,
        "requested": size(names),
        "found_count": found_count,
        "missing_count": missing_count,
        "total_bytes": total_bytes,
        "total_reserved_bytes": total_reserved_bytes,
        "cache_free": cache_free,
        "will_fit": missing_count == 0 && total_reserved_bytes <= cache_free,
        "items": items
    }
end

p2mem.native_module_sources_warm_verified = def(names)
    var items = []
    var ok_count = 0
    var fail_count = 0

    for name : names
        var item = p2mem.native_module_source_put_verified(name)
        items.push(item)
        if item["ok"] {
            ok_count += 1
        } else {
            fail_count += 1
        }
    end

    return {
        "ok": fail_count == 0,
        "requested": size(names),
        "ok_count": ok_count,
        "fail_count": fail_count,
        "items": items
    }
end

p2mem.native_module_sources_warm_if_fits = def(names)
    var plan = p2mem.native_module_sources_plan(names)
    if !plan["will_fit"] {
        return {
            "ok": false,
            "warmed": false,
            "plan": plan,
            "warm": nil,
            "reason": plan["missing_count"] > 0 ? "missing_source" : "insufficient_native_cache"
        }
    }

    var warm = p2mem.native_module_sources_warm_verified(names)
    return {
        "ok": warm["ok"],
        "warmed": warm["ok"],
        "plan": plan,
        "warm": warm,
        "reason": warm["ok"] ? "ok" : "warm_failed"
    }
end

p2mem.native_module_sources_status = def(names)
    var items = []
    var ok_count = 0
    var missing_count = 0

    for name : names
        var item = p2mem.native_module_source_status(name)
        item["module"] = name
        items.push(item)
        if item["ok"] {
            ok_count += 1
        } else {
            missing_count += 1
        }
    end

    return {
        "ok": missing_count == 0,
        "requested": size(names),
        "ok_count": ok_count,
        "missing_count": missing_count,
        "items": items
    }
end

p2mem.native_module_sources_release = def(names)
    var items = []
    var released_count = 0
    var fail_count = 0
    var i = size(names) - 1

    while i >= 0
        var name = names[i]
        var item = p2mem.native_module_source_release(name)
        item["module"] = name
        items.push(item)
        if item["ok"] {
            released_count += item["released_count"]
        } else {
            fail_count += 1
        }
        i -= 1
    end

    return {
        "ok": fail_count == 0,
        "requested": size(names),
        "released_count": released_count,
        "fail_count": fail_count,
        "items": items
    }
end

p2mem.native_cache_replace = def(owner, data)
    var latest = p2mem.native_cache_find_latest(owner)
    var released = nil

    if latest["found"] {
        released = p2mem.native_cache_release_owner(owner)
        if !released["released"] {
            return {
                "ok": false,
                "error": "latest owner reservation is not the newest cache entry",
                "latest": latest,
                "release": released
            }
        }
    }

    var out = p2mem.native_cache_put(owner, data)
    out["replaced"] = latest["found"]
    out["release"] = released
    return out
end

p2mem.native_cache_replace_verified = def(owner, data)
    var out = p2mem.native_cache_replace(owner, data)
    if !out["ok"] {
        out["verified"] = false
        out["verify"] = nil
        return out
    }
    var verify = p2mem.native_cache_verify(out["index"])
    out["verify"] = verify
    out["verified"] = verify["ok"]
    out["ok"] = out["ok"] && verify["ok"]
    return out
end

p2mem.stats = def()
    var heap = p2.heap_info()
    var status = p2.status_info()
    var store = libstore.status()
    var strategy = libstore.strategy()
    var report = libstore.cache_report()
    var native = p2mem.native_cache()

    return {
        "heap": heap,
        "memory": status["memory"],
        "psram": status["psram"],
        "libstore": store,
        "strategy": strategy,
        "cache": report["status"],
        "native_cache": native,
        "module_count": store["library_count"],
        "cache_items": store["psram_cache_items"],
        "native_cache_items": native["entry_count"],
        "gc_allocated": gc.allocated()
    }
end

p2mem.modules = def()
    var out = []
    var report = libstore.cache_report()

    for name : libstore.modules()
        out.push(p2mem._module_record(name, report))
    end
    return out
end

p2mem.cache = def()
    var report = libstore.cache_report()
    var items = []

    for item : report["items"]
        items.push({
            "module": item["name"],
            "name": item["name"],
            "source_path": item["path"],
            "compiled_path": nil,
            "storage_tier": "psram_source_cache",
            "source_hash": nil,
            "compiled_hash": nil,
            "mtime": nil,
            "hub_bytes_used": 0,
            "psram_bytes_used": item["size"],
            "cache_hit_count": 0,
            "cache_miss_count": 0,
            "refcount": nil,
            "pinned": false,
            "last_used": nil,
            "address": item["address"],
            "chunks": item["chunks"]
        })
    end

    return {
        "status": report["status"],
        "items": items,
        "native": p2mem.native_cache()
    }
end

p2mem.gc = def()
    var before = gc.allocated()
    gc.collect()
    var after = gc.allocated()

    return {
        "before": before,
        "after": after,
        "freed": before >= after ? before - after : 0
    }
end

p2mem.evict = def()
    var before = libstore.cache_report()
    var window = libstore.cache_reset()
    var after = libstore.cache_report()

    return {
        "before": before["status"],
        "window": window,
        "after": after["status"]
    }
end

return p2mem
