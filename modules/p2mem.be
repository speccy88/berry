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
        "compiled_path": info["compiled_path"],
        "compiled_exists": info["compiled_exists"],
        "compiled_supported": info["compiled_supported"],
        "compiled_manifest_path": info["compiled_manifest_path"],
        "compiled_manifest_exists": info["compiled_manifest_exists"],
        "compiled_manifest_valid": info["compiled_manifest_valid"],
        "compiled_manifest_reason": info["compiled_manifest_reason"],
        "compiled_fresh": info["compiled_fresh"],
        "compiled_usable": info["compiled_usable"],
        "compiled_freshness_reason": info["compiled_freshness_reason"],
        "compiled_loader_supported": info["compiled_loader_supported"],
        "compiled_bytecode_loader": info["compiled_bytecode_loader"],
        "compiled_validator_supported": info["compiled_validator_supported"],
        "compiled_loader_reason": info["compiled_loader_reason"],
        "compiled_validation_supported": info["compiled_validation_supported"],
        "compiled_validation_valid": info["compiled_validation_valid"],
        "compiled_validation_reason": info["compiled_validation_reason"],
        "compiled_load_can": info["compiled_load_can"],
        "compiled_load_reason": info["compiled_load_reason"],
        "compiled_status_can_load": info["compiled_status_can_load"],
        "compiled_status_can_emit": info["compiled_status_can_emit"],
        "compiled_status_reason": info["compiled_status_reason"],
        "compile_cache_supported": info["compile_cache_supported"],
        "compile_cache_can_emit": info["compile_cache_can_emit"],
        "compile_cache_reason": info["compile_cache_reason"],
        "compile_cache_blocked_reason": info["compile_cache_blocked_reason"],
        "compile_cache_target_path": info["compile_cache_target_path"],
        "compile_cache_manifest_target_path": info["compile_cache_manifest_target_path"],
        "compile_cache_manifest_format": info["compile_cache_manifest_format"],
        "compile_cache_manifest_template_available": info["compile_cache_manifest_template_available"],
        "compile_cache_manifest_template_reason": info["compile_cache_manifest_template_reason"],
        "selected_path": info["selected_path"],
        "selected_kind": info["selected_kind"],
        "resolve_reason": info["resolve_reason"],
        "source_fallback": info["source_fallback"],
        "storage_tier": storage_tier,
        "source_size": info["source_size"],
        "source_hash": info["source_hash"],
        "compiled_size": info["compiled_size"],
        "compiled_hash": info["compiled_hash"],
        "mtime": nil,
        "hub_bytes_used": 0,
        "psram_bytes_used": psram_bytes,
        "cache_hit_count": info["cache_hit_count"],
        "cache_miss_count": info["cache_miss_count"],
        "refcount": nil,
        "pinned": false,
        "last_used": info["last_used"],
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
    if owner == nil
        owner = "p2mem"
    end
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
    if !latest["found"]
        return {
            "ok": false,
            "released": false,
            "error": "owner reservation not found",
            "latest": latest
        }
    end
    var released = p2mem.native_cache_release(latest["index"])
    if !released["released"]
        return {
            "ok": false,
            "released": false,
            "error": "latest owner reservation is not the newest cache entry",
            "latest": latest,
            "release": released
        }
    end
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
        if !latest["found"]
            done = true
        else
            var item = p2mem.native_cache_release_owner(owner)
            if item["released"]
                released.push(item)
            else
                blocked = item
                done = true
            end
        end
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
    if reservation["ok"]
        reservation["write"] = p2mem.native_cache_write(reservation["index"], 0, data)
    end
    return reservation
end

p2mem.native_cache_put_verified = def(owner, data)
    var out = p2mem.native_cache_put(owner, data)
    if !out["ok"]
        out["verified"] = false
        out["verify"] = nil
        return out
    end
    var verify = p2mem.native_cache_verify(out["index"])
    out["verify"] = verify
    out["verified"] = verify["ok"]
    out["ok"] = out["ok"] && verify["ok"]
    return out
end

p2mem.native_cache_get = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"]
        return nil
    end
    var bytes = item.contains("used") ? item["used"] : item["size"]
    return p2mem.native_cache_read(item["index"], 0, bytes)
end

p2mem.native_cache_verify_owner = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner
        }
    end
    var out = p2mem.native_cache_verify(item["index"])
    out["found"] = true
    return out
end

p2mem.native_cache_get_verified = def(owner)
    var item = p2mem.native_cache_find_latest(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "value": nil,
            "verify": nil
        }
    end

    var verify = p2mem.native_cache_verify(item["index"])
    if !verify["ok"]
        return {
            "ok": false,
            "found": true,
            "owner": owner,
            "index": item["index"],
            "value": nil,
            "verify": verify
        }
    end

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
    if !item["found"]
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
    end

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
    if source == nil
        return {
            "ok": false,
            "found": false,
            "module": name,
            "owner": p2mem.native_module_source_owner(name)
        }
    end
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
        if reserved_bytes % 8 != 0
            reserved_bytes += 8 - (reserved_bytes % 8)
        end
        var item = {
            "module": name,
            "owner": p2mem.native_module_source_owner(name),
            "found": found,
            "bytes": bytes,
            "reserved_bytes": reserved_bytes
        }
        items.push(item)
        if found
            found_count += 1
            total_bytes += bytes
            total_reserved_bytes += reserved_bytes
        else
            missing_count += 1
        end
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
        if item["ok"]
            ok_count += 1
        else
            fail_count += 1
        end
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
    if !plan["will_fit"]
        return {
            "ok": false,
            "warmed": false,
            "plan": plan,
            "warm": nil,
            "reason": plan["missing_count"] > 0 ? "missing_source" : "insufficient_native_cache"
        }
    end

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
        if item["ok"]
            ok_count += 1
        else
            missing_count += 1
        end
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
        if item["ok"]
            released_count += item["released_count"]
        else
            fail_count += 1
        end
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

    if latest["found"]
        released = p2mem.native_cache_release_owner(owner)
        if !released["released"]
            return {
                "ok": false,
                "error": "latest owner reservation is not the newest cache entry",
                "latest": latest,
                "release": released
            }
        end
    end

    var out = p2mem.native_cache_put(owner, data)
    out["replaced"] = latest["found"]
    out["release"] = released
    return out
end

p2mem.native_cache_replace_verified = def(owner, data)
    var out = p2mem.native_cache_replace(owner, data)
    if !out["ok"]
        out["verified"] = false
        out["verify"] = nil
        return out
    end
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

p2mem.module = def(name)
    var report = libstore.cache_report()
    var rec = p2mem._module_record(name, report)
    return rec["exists"] ? rec : nil
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
            "source_hash": item["source_hash"],
            "compiled_hash": nil,
            "mtime": nil,
            "hub_bytes_used": 0,
            "psram_bytes_used": item["size"],
            "cache_hit_count": item["cache_hit_count"],
            "cache_miss_count": item["cache_miss_count"],
            "refcount": nil,
            "pinned": false,
            "last_used": item["last_used"],
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
