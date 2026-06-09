# P2 compatibility capability notes.
#
# This module is intentionally declarative. It documents what the bare-metal P2
# port supports, what is staged, and what is intentionally unsupported instead
# of installing host-like stubs that silently lie.

import p2

var p2compat = module("p2compat")

p2compat.SUPPORTED = "supported"
p2compat.PARTIAL = "partial"
p2compat.STAGED = "staged"
p2compat.UNSUPPORTED = "unsupported"

p2compat._statuses = [
    p2compat.SUPPORTED,
    p2compat.PARTIAL,
    p2compat.STAGED,
    p2compat.UNSUPPORTED
]

p2compat._items = [
    {
        "name": "sd_filesystem",
        "status": p2compat.SUPPORTED,
        "summary": "open, file, os, and os.path use the P2 SD filesystem"
    },
    {
        "name": "sd_source_import",
        "status": p2compat.SUPPORTED,
        "summary": "/modules, /berry/lib, and /berry/app are lazy source import roots"
    },
    {
        "name": "package_import",
        "status": p2compat.SUPPORTED,
        "summary": "dotted SD imports map to nested paths, including string, alias, bare, and comma-separated forms"
    },
    {
        "name": "sys_module",
        "status": p2compat.SUPPORTED,
        "summary": "sys.path() and additive sys.path_add() are available for P2 module roots"
    },
    {
        "name": "sd_main",
        "status": p2compat.STAGED,
        "summary": "/berry/main.be is attempted at startup when present, then REPL remains the fallback"
    },
    {
        "name": "compiled_bytecode",
        "status": p2compat.STAGED,
        "summary": ".bec paths, opt-in bytecode loader gate, and sidecar freshness manifests are detected; default builds keep .be source fallback"
    },
    {
        "name": "bytecode_cache_emit",
        "status": p2compat.STAGED,
        "summary": ".be to .bec cache emission is behind BE_P2_ENABLE_BYTECODE_SAVER and remains opt-in"
    },
    {
        "name": "bytecode_bulk_emit",
        "status": p2compat.STAGED,
        "summary": "libstore exposes bulk .bec plan and explicit bulk emit helpers for opt-in provisioning"
    },
    {
        "name": "bytecode_bulk_plan_exports",
        "status": p2compat.STAGED,
        "summary": "libstore exposes JSON exports for bulk .bec dry-run planning"
    },
    {
        "name": "bytecode_emit_reason_summary",
        "status": p2compat.STAGED,
        "summary": "libstore bulk .bec emit planning reports blocker reason histograms"
    },
    {
        "name": "bytecode_emit_provision_plan",
        "status": p2compat.STAGED,
        "summary": "libstore exposes dry-run .be to .bec emit provisioning plans and JSON exports"
    },
    {
        "name": "bytecode_emit_candidate_lists",
        "status": p2compat.STAGED,
        "summary": "libstore exposes dry-run emittable and blocked .bec cache candidate lists"
    },
    {
        "name": "bytecode_emit_candidate_exports",
        "status": p2compat.STAGED,
        "summary": "libstore exposes JSON exports for dry-run .bec cache emit candidate lists"
    },
    {
        "name": "bytecode_validator",
        "status": p2compat.STAGED,
        "summary": "fresh .bec sidecars are checked, and execution policy is behind BE_P2_ENABLE_BYTECODE_EXECUTION"
    },
    {
        "name": "bytecode_load_api",
        "status": p2compat.STAGED,
        "summary": "libstore exposes an explicit .bec load plan and loud-failing load_compiled() hook for future bytecode execution"
    },
    {
        "name": "bytecode_status_api",
        "status": p2compat.STAGED,
        "summary": "libstore exposes consolidated .bec freshness, validation, load, and emit diagnostics"
    },
    {
        "name": "bytecode_inventory_api",
        "status": p2compat.STAGED,
        "summary": "libstore exposes full-module .bec status inventory and JSON export for tooling"
    },
    {
        "name": "bytecode_summary_api",
        "status": p2compat.STAGED,
        "summary": "libstore exposes aggregate .bec readiness counts for diagnostics and provisioning"
    },
    {
        "name": "bytecode_reason_summary",
        "status": p2compat.STAGED,
        "summary": "libstore compiled summary reports load and emit blocker reason histograms"
    },
    {
        "name": "bytecode_candidate_lists",
        "status": p2compat.STAGED,
        "summary": "libstore exposes loadable, emittable, and blocked .bec candidate lists for provisioning"
    },
    {
        "name": "bytecode_candidate_exports",
        "status": p2compat.STAGED,
        "summary": "libstore exposes JSON exports for loadable, emittable, and blocked .bec candidate lists"
    },
    {
        "name": "bytecode_provision_plan",
        "status": p2compat.STAGED,
        "summary": "libstore exposes a consolidated .bec provisioning plan for future cache/upload tooling"
    },
    {
        "name": "bec_manifest",
        "status": p2compat.STAGED,
        "summary": ".bec.json sidecars validate format/module/hash metadata for fallback decisions, but do not enable .bec execution"
    },
    {
        "name": "sys_path",
        "status": p2compat.PARTIAL,
        "summary": "module paths are configured at startup and can be appended with sys.path_add(), but host-like list mutation/removal is unsupported"
    },
    {
        "name": "environment",
        "status": p2compat.UNSUPPORTED,
        "summary": "host process environment variables are not available on bare-metal P2"
    },
    {
        "name": "subprocess",
        "status": p2compat.UNSUPPORTED,
        "summary": "there is no host process model or shell to spawn"
    },
    {
        "name": "network_sockets",
        "status": p2compat.UNSUPPORTED,
        "summary": "generic host sockets are not present; optional WiFi transport is hardware-specific"
    },
    {
        "name": "native_threads",
        "status": p2compat.UNSUPPORTED,
        "summary": "host threads are not exposed; future multicog Berry work must use isolated VM/cog ownership"
    },
    {
        "name": "psram_heap",
        "status": p2compat.PARTIAL,
        "summary": "XMM uses a pointer-safe lower PSRAM heap; upper PSRAM is explicit cache/block storage"
    }
]

p2compat._copy_item = def(item)
    return {
        "name": item["name"],
        "status": item["status"],
        "summary": item["summary"]
    }
end

p2compat.items = def()
    var out = []
    for item : p2compat._items
        out.push(p2compat._copy_item(item))
    end
    return out
end

p2compat.build = def()
    try
        var status = p2.status_info()
        if type(status) == "map" && status.contains("build") && type(status["build"]) == "map" {
            return status["build"]
        }
    except .. as e, m
    end
    return {}
end

p2compat.bytecode = def()
    var build = p2compat.build()
    var saver = build.contains("bytecode_saver") && build["bytecode_saver"]
    var loader = build.contains("bytecode_loader") && build["bytecode_loader"]
    var validator = build.contains("bytecode_execution") && build["bytecode_execution"]
    return {
        "saver": saver,
        "loader": loader,
        "validator": validator,
        "cache_emit": saver,
        "execution": loader && validator,
        "default_source_fallback": !(loader && validator)
    }
end

p2compat.find = def(name)
    for item : p2compat._items
        if item["name"] == name
            return p2compat._copy_item(item)
        end
    end
    return nil
end

p2compat.status = def(name)
    var item = p2compat.find(name)
    return item == nil ? nil : item["status"]
end

p2compat.supported = def(name)
    return p2compat.status(name) == p2compat.SUPPORTED
end

p2compat.statuses = def()
    var out = []
    for status : p2compat._statuses
        out.push(status)
    end
    return out
end

p2compat.status_known = def(status)
    for item : p2compat._statuses
        if item == status
            return true
        end
    end
    return false
end

p2compat.names = def()
    var out = []
    for item : p2compat._items
        out.push(item["name"])
    end
    return out
end

p2compat.names_by_status = def(status)
    var out = []
    for item : p2compat._items
        if item["status"] == status
            out.push(item["name"])
        end
    end
    return out
end

p2compat.report = def()
    var status_names = p2compat.statuses()
    var by_status = {}
    for status : status_names
        by_status[status] = p2compat.names_by_status(status)
    end
    return {
        "statuses": status_names,
        "summary": p2compat.summary(),
        "names": p2compat.names(),
        "by_status": by_status,
        "items": p2compat.items(),
        "bytecode": p2compat.bytecode()
    }
end

p2compat.audit = def()
    var seen = {}
    var duplicates = []
    var unknown_statuses = []
    var counted = {
        "supported": 0,
        "partial": 0,
        "staged": 0,
        "unsupported": 0
    }
    for item : p2compat._items
        var name = item["name"]
        var status = item["status"]
        if seen.contains(name)
            duplicates.push(name)
        else
            seen[name] = true
        end
        if p2compat.status_known(status)
            counted[status] += 1
        else
            unknown_statuses.push(status)
        end
    end
    var summary = p2compat.summary()
    var counts_match = (
        counted[p2compat.SUPPORTED] == summary[p2compat.SUPPORTED] &&
        counted[p2compat.PARTIAL] == summary[p2compat.PARTIAL] &&
        counted[p2compat.STAGED] == summary[p2compat.STAGED] &&
        counted[p2compat.UNSUPPORTED] == summary[p2compat.UNSUPPORTED]
    )
    return {
        "ok": size(duplicates) == 0 && size(unknown_statuses) == 0 && counts_match,
        "count": size(p2compat._items),
        "summary": summary,
        "counted": counted,
        "counts_match": counts_match,
        "duplicates": duplicates,
        "unknown_statuses": unknown_statuses
    }
end

p2compat.audit_problems = def()
    var audit = p2compat.audit()
    var out = []
    if size(audit["duplicates"]) > 0
        out.push("duplicate_capability_names")
    end
    if size(audit["unknown_statuses"]) > 0
        out.push("unknown_capability_statuses")
    end
    if !audit["counts_match"]
        out.push("summary_count_mismatch")
    end
    return out
end

p2compat.audit_ok = def()
    return size(p2compat.audit_problems()) == 0
end

p2compat.unsupported = def()
    var out = []
    for item : p2compat._items
        if item["status"] == p2compat.UNSUPPORTED
            out.push(p2compat._copy_item(item))
        end
    end
    return out
end

p2compat.items_by_status = def(status)
    var out = []
    for item : p2compat._items
        if item["status"] == status
            out.push(p2compat._copy_item(item))
        end
    end
    return out
end

p2compat.summary = def()
    var out = {
        "supported": 0,
        "partial": 0,
        "staged": 0,
        "unsupported": 0
    }
    for item : p2compat._items
        var status = item["status"]
        if out.contains(status)
            out[status] += 1
        end
    end
    return out
end

return p2compat
