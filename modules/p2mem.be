# P2 memory and library-cache diagnostics.
#
# This module is intentionally a reporting layer over the current P2 runtime
# state. It does not claim a complete bytecode/object cache yet; unsupported or
# not-yet-tracked metadata is returned as nil so coverage stays honest.

import libstore
import p2

var p2mem = module("p2mem")

p2mem._gc_allocated = def()
    return 0
end

p2mem._gc_collect = def()
    try
        var status = p2.status_info()
        if type(status) == "map" && status.contains("build")
            var heap = p2.heap_info()
            var used = heap.contains("used") ? heap["used"] : 0
            return {
                "before": used,
                "after": used,
                "freed": 0,
                "collected": false,
                "reason": "p2_gc_collect_deferred"
            }
        end
    except .. as e, m
    end
    try
        var report = p2.gc()
        if type(report) == "map" || type(report) == "instance"
            return {
                "before": report.contains("before") ? report["before"] : 0,
                "after": report.contains("after") ? report["after"] : 0,
                "freed": report.contains("freed") ? report["freed"] : 0,
                "collected": true,
                "reason": nil
            }
        end
    except .. as e, m
    end
    return {
        "before": 0,
        "after": 0,
        "freed": 0,
        "collected": false,
        "reason": "gc_report_unavailable"
    }
end

p2mem._cache_item_for = def(report, name)
    var items = report["items"]
    var i = 0
    while i < items.size()
        var item = items[i]
        if item["name"] == name
            return item
        end
        i += 1
    end
    return nil
end

p2mem._module_name_valid = def(name)
    return type(name) == "string" && size(name) > 0 && libstore.valid_module_name(name)
end

p2mem._module_name_error = def(name)
    if type(name) != "string"
        return "module name must be a string"
    end
    if size(name) == 0
        return "module name must not be empty"
    end
    if !libstore.valid_module_name(name)
        return "module name must not contain path separators or dot-dot segments"
    end
    return nil
end

p2mem.capabilities = def()
    return {
        "stats": true,
        "stats_result": true,
        "modules": true,
        "modules_result": true,
        "module": true,
        "module_result": true,
        "cache": true,
        "cache_result": true,
        "gc": true,
        "gc_result": true,
        "evict": true,
        "memory_pressure_policy": true,
        "memory_pressure_result": true,
        "native_cache": true,
        "native_cache_result_wrappers": true,
        "native_cache_owner_helpers": true,
        "native_module_source_helpers": true,
        "invalid_module_name_diagnostics": true,
        "snapshot_diagnostics": true,
        "audit": true,
        "audit_policy": "metadata_and_name_validation_only_no_cache_mutation"
    }
end

p2mem.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = p2mem.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

p2mem.required_capability_keys = def()
    return [
        "stats",
        "stats_result",
        "modules",
        "modules_result",
        "module",
        "module_result",
        "cache",
        "cache_result",
        "gc",
        "gc_result",
        "evict",
        "memory_pressure_policy",
        "memory_pressure_result",
        "native_cache",
        "native_cache_result_wrappers",
        "native_cache_owner_helpers",
        "native_module_source_helpers",
        "invalid_module_name_diagnostics",
        "snapshot_diagnostics",
        "audit",
        "audit_policy"
    ]
end

p2mem.audit = def()
    var caps = p2mem.capabilities()
    var problems = []
    var missing_capability_keys = []

    for name : p2mem.required_capability_keys()
        if !caps.contains(name)
            missing_capability_keys.push(name)
        elif name != "audit_policy" && !caps[name]
            problems.push(name + "_capability_disabled")
        end
    end
    if missing_capability_keys.size() != 0
        problems.push("missing_capability_keys")
    end
    if caps["audit_policy"] != "metadata_and_name_validation_only_no_cache_mutation"
        problems.push("audit_policy_mismatch")
    end
    if p2mem.capability("stats_result") != caps["stats_result"]
        problems.push("stats_result_lookup_mismatch")
    end
    if p2mem.capability("memory_pressure_policy") != caps["memory_pressure_policy"]
        problems.push("memory_pressure_policy_lookup_mismatch")
    end
    if p2mem.capability("missing") != nil
        problems.push("missing_lookup_not_nil")
    end
    if p2mem.capability(nil) != nil
        problems.push("nil_lookup_not_nil")
    end
    if !p2mem._module_name_valid("math")
        problems.push("valid_module_name_rejected")
    end
    if p2mem._module_name_valid("")
        problems.push("empty_module_name_accepted")
    end
    if p2mem._module_name_valid(nil)
        problems.push("nil_module_name_accepted")
    end
    if p2mem._module_name_valid("../escape_mod")
        problems.push("dotdot_module_name_accepted")
    end
    if p2mem._module_name_valid("bad/cache_mod")
        problems.push("slash_module_name_accepted")
    end
    if p2mem._module_name_error(nil) != "module name must be a string"
        problems.push("nil_module_error_mismatch")
    end
    if p2mem._module_name_error("") != "module name must not be empty"
        problems.push("empty_module_error_mismatch")
    end
    if p2mem._module_name_error("../escape_mod") != "module name must not contain path separators or dot-dot segments"
        problems.push("dotdot_module_error_mismatch")
    end
    if p2mem._native_module_name_error("math") != nil
        problems.push("native_valid_module_name_rejected")
    end
    if p2mem._native_module_name_error(nil) != "module name must be a non-empty string"
        problems.push("native_nil_module_error_mismatch")
    end
    if p2mem._native_module_name_error("../escape_mod") != "module name must not contain path separators or dot-dot segments"
        problems.push("native_dotdot_module_error_mismatch")
    end

    return {
        "ok": problems.size() == 0,
        "problem_count": problems.size(),
        "problems": problems,
        "missing_capability_keys": missing_capability_keys,
        "audit_policy": caps["audit_policy"],
        "stats_result": caps["stats_result"],
        "module_result": caps["module_result"],
        "cache_result": caps["cache_result"],
        "gc_result": caps["gc_result"],
        "memory_pressure_policy": caps["memory_pressure_policy"],
        "memory_pressure_result": caps["memory_pressure_result"],
        "native_cache_result_wrappers": caps["native_cache_result_wrappers"],
        "invalid_module_name_diagnostics": caps["invalid_module_name_diagnostics"],
        "snapshot_diagnostics": caps["snapshot_diagnostics"]
    }
end

p2mem.audit_problems = def()
    return p2mem.audit()["problems"]
end

p2mem.audit_ok = def()
    return p2mem.audit()["ok"]
end

p2mem._module_record = def(name, report)
    var source_path = libstore.source_path(name)
    var compiled_path = libstore.compiled_path(name)
    var cached = p2mem._cache_item_for(report, name)
    var psram_bytes = cached == nil ? 0 : cached["size"]
    var storage_tier = cached == nil ? "sd" : "sd+psram_source_cache"
    var compiled_exists = compiled_path != nil
    var compile_reason = source_path == nil ? "source_missing" : libstore.compile_cache_reason
    var compiled_reason = compiled_exists ? "unchecked_fast_summary" : "compiled_missing"

    return {
        "module": name,
        "name": name,
        "source_path": source_path,
        "compiled_path": compiled_path,
        "compiled_exists": compiled_exists,
        "compiled_supported": libstore.compiled_supported,
        "compiled_manifest_path": libstore.compiled_manifest_candidate_path(name),
        "compiled_manifest_exists": false,
        "compiled_manifest_valid": false,
        "compiled_manifest_reason": "missing",
        "compiled_fresh": false,
        "compiled_usable": false,
        "compiled_freshness_reason": compiled_reason,
        "compiled_loader_supported": libstore.compiled_loader_supported,
        "compiled_bytecode_loader": libstore.compiled_loader_supported,
        "compiled_validator_supported": libstore.compiled_validator_supported,
        "compiled_loader_reason": libstore.compiled_loader_reason,
        "compiled_validation_supported": libstore.compiled_validator_supported,
        "compiled_validation_valid": false,
        "compiled_validation_reason": compiled_reason,
        "compiled_load_can": false,
        "compiled_load_reason": compiled_reason,
        "compiled_status_can_load": false,
        "compiled_status_can_emit": false,
        "compiled_status_reason": compiled_reason,
        "compile_cache_supported": libstore.compile_cache_supported,
        "compile_cache_can_emit": false,
        "compile_cache_reason": compile_reason,
        "compile_cache_blocked_reason": compile_reason,
        "compile_cache_target_path": libstore.compiled_candidate_path(name),
        "compile_cache_manifest_target_path": libstore.compiled_manifest_candidate_path(name),
        "compile_cache_manifest_format": libstore.MANIFEST_FORMAT,
        "compile_cache_manifest_template_available": compiled_exists && source_path != nil,
        "compile_cache_manifest_template_reason": source_path == nil ? "source_missing" : (compiled_exists ? "ok" : "compiled_missing"),
        "selected_path": source_path,
        "selected_kind": source_path == nil ? nil : "source",
        "resolve_reason": source_path == nil ? "missing" : "source",
        "source_fallback": source_path != nil && compiled_exists,
        "storage_tier": storage_tier,
        "source_size": cached == nil ? 0 : cached["size"],
        "source_hash": cached == nil ? nil : cached["source_hash"],
        "compiled_size": 0,
        "compiled_hash": nil,
        "mtime": nil,
        "hub_bytes_used": 0,
        "psram_bytes_used": psram_bytes,
        "cache_hit_count": libstore.cache_hits_for(name),
        "cache_miss_count": libstore.cache_misses_for(name),
        "refcount": nil,
        "pinned": false,
        "last_used": cached == nil ? nil : cached["last_used"],
        "exists": source_path != nil,
        "cached": cached != nil,
        "cache": cached
    }
end

p2mem.native_cache = def()
    var status = nil
    var entries = []

    try
        status = p2.psram_cache_info()
    except .. as e, m
        return {
            "available": false,
            "status": nil,
            "entries": [],
            "entry_count": 0,
            "entry_max": 0,
            "used": 0,
            "free": 0,
            "base": 0,
            "limit": 0,
            "libstore_base": 0,
            "error": e,
            "message": m
        }
    end

    try
        entries = p2.psram_cache_entries()
    except .. as e, m
        return {
            "available": false,
            "status": status,
            "entries": [],
            "entry_count": status["entry_count"],
            "entry_max": status["entry_max"],
            "used": status["used"],
            "free": status["free"],
            "base": status["base"],
            "limit": status["limit"],
            "libstore_base": status["libstore_base"],
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

p2mem._map_value = def(m, name, fallback)
    if type(m) == "map" || type(m) == "instance"
        if m.contains(name)
            return m[name]
        end
    end
    return fallback
end

p2mem.memory_pressure_policy = def()
    var heap = p2.heap_info()
    var psram = p2.psram_info()
    var native = p2mem.native_cache()
    var store = libstore.status()

    var heap_total = p2mem._map_value(heap, "total", 0)
    var heap_free = p2mem._map_value(heap, "free", p2mem._map_value(heap, "main", 0))
    var heap_used = p2mem._map_value(heap, "used", heap_total > heap_free ? heap_total - heap_free : 0)
    var psram_bytes = p2mem._map_value(psram, "bytes", 0)
    var psram_heap = p2mem._map_value(psram, "heap", false)
    var psram_block_bytes = p2mem._map_value(psram, "block_bytes", 0)
    var pointer_window_bytes = p2mem._map_value(heap, "pointer_window_bytes", 0)
    var main_inside_window = p2mem._map_value(heap, "main_inside_pointer_window", nil)

    return {
        "model": "p2_memory_pressure_diagnostics",
        "source": "p2.heap_info_p2.psram_info_p2.psram_cache_info_libstore.status",
        "heap_total": heap_total,
        "heap_free": heap_free,
        "heap_used": heap_used,
        "heap_high_water_bytes": nil,
        "heap_high_water_tracking": false,
        "heap_high_water_policy": "not_instrumented_yet",
        "psram_available": p2mem._map_value(psram, "available", false),
        "psram_bytes": psram_bytes,
        "psram_heap": psram_heap,
        "psram_block_bytes": psram_block_bytes,
        "pointer_window_bytes": pointer_window_bytes,
        "main_inside_pointer_window": main_inside_window,
        "native_cache_available": native["available"],
        "native_cache_limit": native["limit"],
        "native_cache_used": native["used"],
        "native_cache_free": native["free"],
        "native_cache_items": native["entry_count"],
        "source_cache_items": store["psram_cache_items"],
        "source_cache_used": store["psram_cache_used"],
        "source_cache_free": store["psram_cache_free"],
        "low_memory_churn_anchor": "tests/p2/smoke_import_churn.be",
        "low_memory_behavior_status": "bounded_import_churn_covered_broader_pressure_soak_open",
        "production_release_gate": false,
        "retry_policy": "stop_routine_priority_work_unless_native_high_water_or_allocator_changes"
    }
end

p2mem.memory_pressure_value = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = p2mem.memory_pressure_policy()
    if policy.contains(name)
        return policy[name]
    end
    return nil
end

p2mem.memory_pressure_result = def()
    try
        return {
            "ok": true,
            "policy": p2mem.memory_pressure_policy(),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "policy": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_reserve = def(size, owner)
    if owner == nil
        owner = "p2mem"
    end
    return p2.psram_cache_reserve(size, owner)
end

p2mem.native_cache_reserve_result = def(size, owner)
    try
        var reserved = p2mem.native_cache_reserve(size, owner)
        reserved["ok"] = reserved.contains("ok") ? reserved["ok"] : false
        return reserved
    except .. as e, m
        return {
            "ok": false,
            "index": -1,
            "owner": owner == nil ? "p2mem" : owner,
            "size": size,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_reset = def()
    return p2.psram_cache_reset()
end

p2mem.native_cache_reset_result = def()
    try
        var reset = p2mem.native_cache_reset()
        reset["ok"] = reset.contains("ok") ? reset["ok"] : true
        return reset
    except .. as e, m
        return {
            "ok": false,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_find = def(owner)
    return p2.psram_cache_find(owner)
end

p2mem.native_cache_find_result = def(owner)
    try
        var found = p2mem.native_cache_find(owner)
        found["ok"] = found.contains("ok") ? found["ok"] : true
        return found
    except .. as e, m
        return {
            "ok": false,
            "owner": owner,
            "found": false,
            "count": 0,
            "items": [],
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_owner_history = def(owner)
    return p2mem.native_cache_find_result(owner)
end

p2mem.native_cache_find_latest = def(owner)
    return p2.psram_cache_find_latest(owner)
end

p2mem.native_cache_find_latest_result = def(owner)
    try
        var found = p2mem.native_cache_find_latest(owner)
        found["ok"] = found.contains("ok") ? found["ok"] : true
        return found
    except .. as e, m
        return {
            "ok": false,
            "found": false,
            "index": -1,
            "owner": owner,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_release = def(index)
    return p2.psram_cache_release(index)
end

p2mem.native_cache_release_result = def(index)
    try
        var released = p2mem.native_cache_release(index)
        released["ok"] = released.contains("ok") ? released["ok"] : released["released"]
        return released
    except .. as e, m
        return {
            "ok": false,
            "released": false,
            "index": index,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_release_owner = def(owner)
    var latest = p2mem.native_cache_find_latest_result(owner)
    if !latest["found"]
        return {
            "ok": false,
            "released": false,
            "error": latest["ok"] ? "owner reservation not found" : "owner lookup failed",
            "latest": latest
        }
    end
    var released = p2mem.native_cache_release_result(latest["index"])
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
        var latest = p2mem.native_cache_find_latest_result(owner)
        if !latest["found"]
            if latest["ok"]
                done = true
            else
                blocked = {
                    "ok": false,
                    "released": false,
                    "error": "owner lookup failed",
                    "latest": latest
                }
                done = true
            end
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
        "remaining": p2mem.native_cache_find_result(owner)
    }
end

p2mem.native_cache_read = def(index, offset, size)
    return p2.psram_cache_read_entry(index, offset, size)
end

p2mem.native_cache_read_result = def(index, offset, size)
    try
        return {
            "ok": true,
            "index": index,
            "offset": offset,
            "size": size,
            "value": p2mem.native_cache_read(index, offset, size)
        }
    except .. as e, m
        return {
            "ok": false,
            "index": index,
            "offset": offset,
            "size": size,
            "value": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_write = def(index, offset, data)
    return p2.psram_cache_write_entry(index, offset, data)
end

p2mem.native_cache_write_result = def(index, offset, data)
    try
        var written = p2mem.native_cache_write(index, offset, data)
        written["ok"] = written.contains("ok") ? written["ok"] : false
        return written
    except .. as e, m
        return {
            "ok": false,
            "index": index,
            "offset": offset,
            "written": 0,
            "error": e,
            "message": m
        }
    end
end

p2mem.native_cache_verify = def(index)
    return p2.psram_cache_verify_entry(index)
end

p2mem.native_cache_verify_result = def(index)
    try
        return p2mem.native_cache_verify(index)
    except .. as e, m
        return {
            "ok": false,
            "index": index,
            "error": e,
            "message": m
        }
    end
end

p2mem._native_cache_write_ok = def(write, expected)
    if write == nil || !write["ok"]
        return false
    end
    if write.contains("size")
        return write["size"] == expected
    end
    if write.contains("written")
        return write["written"] == expected
    end
    return true
end

p2mem._native_cache_release_after_failed_put = def(reservation)
    reservation["release"] = p2mem.native_cache_release_result(reservation["index"])
end

p2mem.native_cache_put = def(owner, data)
    var expected = 0
    try
        expected = size(data)
    except .. as e, m
        return {
            "ok": false,
            "index": -1,
            "owner": owner,
            "size": 0,
            "error": e,
            "message": m,
            "write": {
                "ok": false,
                "error": e,
                "message": m
            },
            "release": {
                "released": false,
                "reason": "reservation_not_created"
            }
        }
    end

    var reservation = p2mem.native_cache_reserve_result(expected, owner)
    if !reservation["ok"]
        reservation["write"] = {
            "ok": false,
            "reason": "reservation_failed"
        }
        reservation["release"] = {
            "released": false,
            "reason": "reservation_not_created"
        }
        return reservation
    end
    if reservation["ok"]
        try
            reservation["write"] = p2mem.native_cache_write(reservation["index"], 0, data)
        except .. as e, m
            reservation["write"] = {
                "ok": false,
                "error": e,
                "message": m
            }
        end
        if !p2mem._native_cache_write_ok(reservation["write"], expected)
            reservation["ok"] = false
            reservation["error"] = "native cache write failed"
            p2mem._native_cache_release_after_failed_put(reservation)
        end
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
    var verify = p2mem.native_cache_verify_result(out["index"])
    out["verify"] = verify
    out["verified"] = verify["ok"]
    if !verify["ok"]
        out["ok"] = false
        out["error"] = "native cache verify failed"
        p2mem._native_cache_release_after_failed_put(out)
    end
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

p2mem.native_cache_get_result = def(owner)
    var item = p2mem.native_cache_find_latest_result(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "value": nil,
            "error": item["ok"] ? "owner reservation not found" : "owner lookup failed",
            "latest": item
        }
    end

    var bytes = item.contains("used") ? item["used"] : item["size"]
    var read = p2mem.native_cache_read_result(item["index"], 0, bytes)
    if !read["ok"]
        return {
            "ok": false,
            "found": true,
            "owner": owner,
            "index": item["index"],
            "value": nil,
            "read": read
        }
    end

    return {
        "ok": true,
        "found": true,
        "owner": owner,
        "index": item["index"],
        "value": read["value"],
        "read": read
    }
end

p2mem.native_cache_verify_owner = def(owner)
    var item = p2mem.native_cache_find_latest_result(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "error": item["ok"] ? "owner reservation not found" : "owner lookup failed",
            "latest": item
        }
    end
    var out = p2mem.native_cache_verify_result(item["index"])
    out["found"] = true
    return out
end

p2mem.native_cache_get_verified = def(owner)
    var item = p2mem.native_cache_find_latest_result(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "value": nil,
            "verify": nil,
            "error": item["ok"] ? "owner reservation not found" : "owner lookup failed",
            "latest": item
        }
    end

    var verify = p2mem.native_cache_verify_result(item["index"])
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
    var read = p2mem.native_cache_read_result(item["index"], 0, bytes)
    if !read["ok"]
        return {
            "ok": false,
            "found": true,
            "owner": owner,
            "index": item["index"],
            "value": nil,
            "verify": verify,
            "read": read
        }
    end

    return {
        "ok": true,
        "found": true,
        "owner": owner,
        "index": item["index"],
        "value": read["value"],
        "verify": verify
    }
end

p2mem.native_cache_status = def(owner)
    var item = p2mem.native_cache_find_latest_result(owner)
    if !item["found"]
        return {
            "ok": false,
            "found": false,
            "owner": owner,
            "index": -1,
            "used": 0,
            "size": 0,
            "verified": false,
            "verify": nil,
            "error": item["ok"] ? "owner reservation not found" : "owner lookup failed",
            "latest": item
        }
    end

    var verify = p2mem.native_cache_verify_result(item["index"])
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

p2mem._native_module_name_error = def(name)
    if type(name) != "string" || size(name) == 0
        return "module name must be a non-empty string"
    end
    if !libstore.valid_module_name(name)
        return "module name must not contain path separators or dot-dot segments"
    end
    return nil
end

p2mem._native_module_name_invalid = def(name)
    return {
        "ok": false,
        "found": false,
        "module": name,
        "owner": nil,
        "error": "invalid_module_name",
        "message": p2mem._native_module_name_error(name)
    }
end

p2mem.native_module_source_put_verified = def(name)
    var name_error = p2mem._native_module_name_error(name)
    if name_error != nil
        return p2mem._native_module_name_invalid(name)
    end

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
    var name_error = p2mem._native_module_name_error(name)
    if name_error != nil
        var invalid = p2mem._native_module_name_invalid(name)
        invalid["index"] = -1
        invalid["used"] = 0
        invalid["size"] = 0
        invalid["verified"] = false
        invalid["verify"] = nil
        return invalid
    end
    return p2mem.native_cache_status(p2mem.native_module_source_owner(name))
end

p2mem.native_module_source_get_verified = def(name)
    var name_error = p2mem._native_module_name_error(name)
    if name_error != nil
        var invalid = p2mem._native_module_name_invalid(name)
        invalid["value"] = nil
        invalid["verify"] = nil
        return invalid
    end
    return p2mem.native_cache_get_verified(p2mem.native_module_source_owner(name))
end

p2mem.native_module_source_release = def(name)
    var name_error = p2mem._native_module_name_error(name)
    if name_error != nil
        var invalid = p2mem._native_module_name_invalid(name)
        invalid["released_count"] = 0
        invalid["released"] = []
        invalid["blocked"] = nil
        invalid["remaining"] = nil
        return invalid
    end
    return p2mem.native_cache_release_owner_chain(p2mem.native_module_source_owner(name))
end

p2mem._native_module_names_error = def(names)
    if classname(names) != "list"
        return "module names must be a list"
    end
    var i = 0
    while i < size(names)
        var name_error = p2mem._native_module_name_error(names[i])
        if name_error != nil
            return name_error
        end
        i += 1
    end
    return nil
end

p2mem._native_module_names_invalid = def(names)
    var message = p2mem._native_module_names_error(names)
    return {
        "ok": false,
        "requested": classname(names) == "list" ? size(names) : 0,
        "error": "invalid_module_names",
        "message": message,
        "items": []
    }
end

p2mem.native_module_sources_plan = def(names)
    var names_error = p2mem._native_module_names_error(names)
    if names_error != nil
        var invalid = p2mem._native_module_names_invalid(names)
        invalid["found_count"] = 0
        invalid["missing_count"] = 0
        invalid["total_bytes"] = 0
        invalid["total_reserved_bytes"] = 0
        invalid["cache_free"] = 0
        invalid["native_available"] = false
        invalid["native_error"] = nil
        invalid["native_message"] = nil
        invalid["blocker"] = "invalid_module_names"
        invalid["will_fit"] = false
        return invalid
    end

    var items = []
    var total_bytes = 0
    var total_reserved_bytes = 0
    var found_count = 0
    var missing_count = 0
    var native = p2mem.native_cache()
    var cache_free = native["free"]
    var native_available = native["available"]
    var blocker = "ok"

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

    if missing_count > 0
        blocker = "missing_source"
    elif !native_available
        blocker = "native_cache_unavailable"
    elif total_reserved_bytes > cache_free
        blocker = "insufficient_native_cache"
    end

    return {
        "ok": blocker == "ok",
        "requested": size(names),
        "found_count": found_count,
        "missing_count": missing_count,
        "total_bytes": total_bytes,
        "total_reserved_bytes": total_reserved_bytes,
        "cache_free": cache_free,
        "native_available": native_available,
        "native_error": native.contains("error") ? native["error"] : nil,
        "native_message": native.contains("message") ? native["message"] : nil,
        "blocker": blocker,
        "will_fit": blocker == "ok",
        "items": items
    }
end

p2mem.native_module_sources_warm_verified = def(names)
    var names_error = p2mem._native_module_names_error(names)
    if names_error != nil
        var invalid = p2mem._native_module_names_invalid(names)
        invalid["ok_count"] = 0
        invalid["fail_count"] = 0
        invalid["rollback"] = nil
        invalid["rolled_back"] = false
        invalid["rollback_ok"] = false
        return invalid
    end

    var items = []
    var warmed_names = []
    var ok_count = 0
    var fail_count = 0
    var rollback = nil
    var done = false

    for name : names
        if !done
            var item = p2mem.native_module_source_put_verified(name)
            items.push(item)
            if item["ok"]
                ok_count += 1
                warmed_names.push(name)
            else
                fail_count += 1
                rollback = p2mem.native_module_sources_release(warmed_names)
                done = true
            end
        end
    end

    return {
        "ok": fail_count == 0,
        "requested": size(names),
        "ok_count": ok_count,
        "fail_count": fail_count,
        "items": items,
        "rollback": rollback,
        "rolled_back": rollback != nil,
        "rollback_ok": rollback == nil || rollback["ok"]
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
            "reason": plan["blocker"]
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
    var names_error = p2mem._native_module_names_error(names)
    if names_error != nil
        var invalid = p2mem._native_module_names_invalid(names)
        invalid["ok_count"] = 0
        invalid["missing_count"] = 0
        return invalid
    end

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
    var names_error = p2mem._native_module_names_error(names)
    if names_error != nil
        var invalid = p2mem._native_module_names_invalid(names)
        invalid["released_count"] = 0
        invalid["fail_count"] = 0
        return invalid
    end

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
    var latest = p2mem.native_cache_find_latest_result(owner)
    if !latest["ok"]
        return {
            "ok": false,
            "index": -1,
            "owner": owner,
            "size": 0,
            "error": "owner lookup failed",
            "latest": latest,
            "replaced": false,
            "previous": latest,
            "previous_retained": false,
            "write": {
                "ok": false,
                "reason": "owner_lookup_failed"
            },
            "release": {
                "released": false,
                "reason": "reservation_not_created"
            }
        }
    end
    var out = p2mem.native_cache_put(owner, data)
    out["replaced"] = latest["found"]
    out["previous"] = latest
    out["previous_retained"] = latest["found"]
    return out
end

p2mem.native_cache_replace_verified = def(owner, data)
    var out = p2mem.native_cache_replace(owner, data)
    if !out["ok"]
        out["verified"] = false
        out["verify"] = nil
        return out
    end
    var verify = p2mem.native_cache_verify_result(out["index"])
    out["verify"] = verify
    out["verified"] = verify["ok"]
    if !verify["ok"]
        out["ok"] = false
        out["error"] = "native cache verify failed"
        p2mem._native_cache_release_after_failed_put(out)
    end
    return out
end

p2mem.stats = def()
    var heap = p2.heap_info()
    var status = p2.status_info()
    var psram = p2.psram_info()
    var store = libstore.status()
    var strategy = libstore.strategy()
    var report = libstore.cache_report()
    var native = p2mem.native_cache()

    var out = {}
    out["heap"] = heap
    out["memory"] = {
        "heap_total": heap.contains("total") ? heap["total"] : 0,
        "heap_free": heap.contains("free") ? heap["free"] : 0,
        "heap_used": heap.contains("used") ? heap["used"] : 0
    }
    out["psram"] = psram
    out["libstore"] = store
    out["strategy"] = strategy
    out["cache"] = report["status"]
    out["native_cache"] = native
    out["module_count"] = store["library_count"]
    out["cache_items"] = store["psram_cache_items"]
    out["native_cache_items"] = native["entry_count"]
    out["gc_allocated"] = p2mem._gc_allocated()
    out["status_profile"] = status.contains("build") ? status["build"]["profile"] : nil
    return out
end

p2mem.stats_result = def()
    try
        return {
            "ok": true,
            "stats": p2mem.stats(),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "stats": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.modules = def()
    var out = []
    var report = libstore.cache_report()

    for name : libstore.modules()
        out.push(p2mem._module_record(name, report))
    end
    return out
end

p2mem.modules_result = def()
    try
        return {
            "ok": true,
            "modules": p2mem.modules(),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "modules": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.module = def(name)
    if !p2mem._module_name_valid(name)
        return nil
    end
    var report = libstore.cache_report()
    var rec = p2mem._module_record(name, report)
    return rec["exists"] ? rec : nil
end

p2mem.module_result = def(name)
    var name_error = p2mem._module_name_error(name)
    if name_error != nil
        return {
            "ok": false,
            "module": nil,
            "found": false,
            "error": "invalid_module_name",
            "message": name_error
        }
    end
    try
        var rec = p2mem.module(name)
        return {
            "ok": rec != nil,
            "module": rec,
            "found": rec != nil,
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "module": nil,
            "found": false,
            "error": e,
            "message": m
        }
    end
end

p2mem.cache = def()
    var report = libstore.cache_report()
    var items = []

    var report_items = report["items"]
    var i = 0
    while i < report_items.size()
        var item = report_items[i]
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
            "chunk_count": item["chunks"],
            "chunks": item["chunks"]
        })
        i += 1
    end

    return {
        "status": report["status"],
        "items": items,
        "native": p2mem.native_cache()
    }
end

p2mem.cache_result = def()
    try
        return {
            "ok": true,
            "cache": p2mem.cache(),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "cache": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.gc = def()
    var report = p2mem._gc_collect()
    var before = report["before"]
    var after = report["after"]

    return {
        "before": before,
        "after": after,
        "freed": report.contains("freed") ? report["freed"] : (before >= after ? before - after : 0),
        "collected": report.contains("collected") ? report["collected"] : true,
        "reason": report.contains("reason") ? report["reason"] : nil
    }
end

p2mem.gc_result = def()
    try
        return {
            "ok": true,
            "gc": p2mem.gc(),
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "gc": nil,
            "error": e,
            "message": m
        }
    end
end

p2mem.evict = def()
    var before = nil
    var window = nil
    var after = nil

    try
        before = libstore.cache_report()
        window = libstore.cache_reset()
        after = libstore.cache_report()
        return {
            "ok": true,
            "before": before["status"],
            "window": window,
            "after": after["status"],
            "error": nil,
            "message": nil
        }
    except .. as e, m
        return {
            "ok": false,
            "before": before == nil ? nil : before["status"],
            "window": window,
            "after": after == nil ? nil : after["status"],
            "error": e,
            "message": m
        }
    end
end

return p2mem
