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
        "summary": ".bec paths, loader/execution gates, bytecode-header checks, and sidecar freshness manifests are detected; bytecode-capable builds may prefer fresh valid .bec files"
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
        "summary": "libstore exposes .bec load planning plus load_compiled(); unsupported or invalid bytecode raises loudly"
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
        "summary": "libstore exposes a consolidated .bec provisioning plan for cache/upload tooling"
    },
    {
        "name": "bec_manifest",
        "status": p2compat.STAGED,
        "summary": "8.3-safe .jsn sidecars validate format/module/hash metadata; bytecode headers are checked separately before .bec files become loadable"
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
        "name": "video_output",
        "status": p2compat.UNSUPPORTED,
        "summary": "VGA, streamer video, and framebuffer output are not exposed by the current default P2 build"
    },
    {
        "name": "vga_demo",
        "status": p2compat.UNSUPPORTED,
        "summary": "no backed VGA test-pattern demo is shipped yet; examples report this explicitly instead of drawing a fake pattern"
    },
    {
        "name": "usb_hid",
        "status": p2compat.UNSUPPORTED,
        "summary": "USB keyboard, mouse, and HID host/device helpers are not exposed by the current default P2 build"
    },
    {
        "name": "usb_demo",
        "status": p2compat.UNSUPPORTED,
        "summary": "no backed USB keyboard/mouse demo is shipped yet; examples report this explicitly instead of faking input"
    },
    {
        "name": "psram_heap",
        "status": p2compat.PARTIAL,
        "summary": "XMM uses a pointer-safe lower PSRAM heap; upper PSRAM is explicit cache/block storage"
    },
    {
        "name": "board_profile_policy",
        "status": p2compat.SUPPORTED,
        "summary": "build, board, profile, and reserved-pin policy are queryable so unsupported board/profile combinations fail loudly instead of being guessed"
    },
    {
        "name": "child_vm_primitive_transfer",
        "status": p2compat.PARTIAL,
        "summary": "child VM probes copy nil, bool, int, and bounded string values by value across the VM boundary"
    },
    {
        "name": "child_vm_named_closure_bridge",
        "status": p2compat.STAGED,
        "summary": "non-captured parent closures can be used only as validated function-name selectors for child VM calls; closure objects are not transferred"
    },
    {
        "name": "child_vm_captured_closure_transfer",
        "status": p2compat.UNSUPPORTED,
        "summary": "captured closures are rejected because live closure/proto/upvalue/GC state is not serializable across VMs"
    },
    {
        "name": "child_vm_live_object_transfer",
        "status": p2compat.UNSUPPORTED,
        "summary": "list, map, instance, function, native pointer, file handle, and hardware-resource object graphs are not copied across child VM boundaries"
    },
    {
        "name": "child_vm_transfer_policy",
        "status": p2compat.STAGED,
        "summary": "structured child-VM transfer policy reports copyable primitive types, staged closure-name bridge behavior, and rejected live-object categories"
    },
    {
        "name": "child_vm_partition_policy",
        "status": p2compat.STAGED,
        "summary": "p2.heap_info vm_partition_* diagnostics are queryable for runtime-derived child-VM heap sizing; no fixed production partition count is selected yet"
    }
]

p2compat._copy_list = def(values)
    var out = []
    var i = 0
    while i < values.size()
        out.push(values[i])
        i += 1
    end
    return out
end

p2compat._copy_item = def(item)
    return {
        "name": item["name"],
        "status": item["status"],
        "summary": item["summary"]
    }
end

p2compat.items = def()
    var out = []
    var i = 0
    while i < p2compat._items.size()
        out.push(p2compat._copy_item(p2compat._items[i]))
        i += 1
    end
    return out
end

p2compat.build = def()
    var status = p2.status_info()
    if type(status) == "map"
        if status.contains("build") && type(status["build"]) == "map"
            return status["build"]
        end
    end
    return {}
end

p2compat.runtime = def()
    var status = p2.status_info()
    if type(status) == "map"
        if status.contains("runtime") && type(status["runtime"]) == "map"
            return status["runtime"]
        end
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

p2compat._build_value = def(build, name, fallback)
    if build.contains(name)
        return build[name]
    end
    return fallback
end

p2compat._reserved_pin_ranges = def(psram_enabled)
    var ranges = []
    if psram_enabled
        ranges.push({"name": "psram", "first": 40, "last": 57})
    end
    ranges.push({"name": "sd", "first": 58, "last": 61})
    ranges.push({"name": "serial", "first": 62, "last": 63})
    return ranges
end

p2compat._copy_ranges = def(ranges)
    var out = []
    var i = 0
    while i < ranges.size()
        var item = ranges[i]
        out.push({
            "name": item["name"],
            "first": item["first"],
            "last": item["last"]
        })
        i += 1
    end
    return out
end

p2compat.board_profile_policy = def()
    var build = p2compat.build()
    var runtime = p2compat.runtime()
    var profile = p2compat._build_value(build, "profile", "unknown")
    var board = p2compat._build_value(build, "board", "unknown")
    var model = p2compat._build_value(build, "model", "unknown")
    var memory_profile = p2compat._build_value(runtime, "memory_profile", profile)
    var psram_enabled = p2compat._build_value(build, "board_has_psram", profile == "xmm")
    var reserved_pin_policy = p2compat._build_value(build, "reserved_pin_policy", "board_profile_reserved_pins_enforced")
    var reserved_ranges = p2compat._reserved_pin_ranges(psram_enabled)
    return {
        "model": "explicit_board_profile_policy",
        "board": board,
        "profile": profile,
        "catalina_model": model,
        "memory_profile": memory_profile,
        "psram_enabled": psram_enabled,
        "reserved_pin_policy": reserved_pin_policy,
        "unsupported_build_policy": "raise_loud_or_report_unsupported",
        "normal_toolchain": "catalina",
        "normal_catalina_dir": "../Catalina",
        "normal_serial_port": "/dev/ttyUSB0",
        "default_p2_edge_profile": "no_psram_compact_hub_ram",
        "edge32_psram_policy": "explicit_psram_profile_only",
        "xmm_policy": "explicit_xmm_profile_only",
        "reserved_pin_ranges": p2compat._copy_ranges(reserved_ranges),
        "safe_jumper_pins": p2compat._copy_list([0, 1, 2, 3, 4, 5, 6, 7]),
        "status_capabilities": p2compat._copy_list(["board_profile_policy", "psram_heap"])
    }
end

p2compat.child_vm_transfer_policy = def()
    return {
        "model": "isolated_child_vm_transfer_policy",
        "primitive_copy": p2compat.PARTIAL,
        "copyable_types": p2compat._copy_list(["nil", "bool", "int", "string"]),
        "bounded_string_copy": true,
        "string_policy": "bounded_copy_by_value",
        "closure_name_bridge": p2compat.STAGED,
        "closure_name_policy": "validated_selector_only_no_closure_object_transfer",
        "captured_closure_transfer": p2compat.UNSUPPORTED,
        "live_object_transfer": p2compat.UNSUPPORTED,
        "rejected_live_types": p2compat._copy_list(["list", "map", "instance", "function", "native_pointer", "file_handle", "hardware_resource"]),
        "ownership_transfer": false,
        "shared_mutable_state": false,
        "resource_transfer": false,
        "default_policy": "reject_unlisted_values",
        "serialization_policy": "explicit_copy_policy_required",
        "ipc_policy": "use_explicit_p2ipc_primitives_for_sharing",
        "unsupported_helpers": p2compat._copy_list(["child_vm_live_object_transfer"]),
        "status_capabilities": p2compat._copy_list([
            "child_vm_primitive_transfer",
            "child_vm_named_closure_bridge",
            "child_vm_captured_closure_transfer",
            "child_vm_live_object_transfer"
        ])
    }
end

p2compat._heap_value = def(heap, name, fallback)
    if type(heap) == "map" && heap.contains(name)
        return heap[name]
    end
    return fallback
end

p2compat.child_vm_partition_policy = def()
    var heap = {}
    if type(p2.heap_info) == "function"
        heap = p2.heap_info()
    end
    var partition_bytes = p2compat._heap_value(heap, "vm_partition_bytes", 0)
    var capacity = p2compat._heap_value(heap, "vm_partition_capacity", 0)
    var free_capacity = p2compat._heap_value(heap, "vm_partition_free_capacity", 0)
    var max_partitions = p2compat._heap_value(heap, "vm_partition_max", 0)
    var created = p2compat._heap_value(heap, "vm_partition_created", 0)
    var current = p2compat._heap_value(heap, "vm_partition_current", -1)
    return {
        "model": "runtime_heap_info_partition_policy",
        "source": "p2.heap_info",
        "partition_bytes": partition_bytes,
        "capacity": capacity,
        "free_capacity": free_capacity,
        "max_partitions": max_partitions,
        "created": created,
        "current": current,
        "usable_for_child_calls": partition_bytes > 0 && capacity >= 1,
        "sizing_policy": "runtime_derived_no_fixed_production_count",
        "production_count_selected": false,
        "retry_policy": "stop_routine_priority_work_until_native_partition_allocator_changes",
        "real_cog_policy": "unsupported_until_isolated_vm_cog_runtime_safe",
        "status_capabilities": p2compat._copy_list([
            "child_vm_primitive_transfer",
            "child_vm_named_closure_bridge",
            "child_vm_partition_policy"
        ])
    }
end

p2compat.required_capability_names = def()
    return p2compat._copy_list([
        "sd_filesystem",
        "sd_source_import",
        "package_import",
        "sys_module",
        "sd_main",
        "compiled_bytecode",
        "bytecode_cache_emit",
        "bytecode_bulk_emit",
        "bytecode_bulk_plan_exports",
        "bytecode_emit_reason_summary",
        "bytecode_emit_provision_plan",
        "bytecode_emit_candidate_lists",
        "bytecode_emit_candidate_exports",
        "bytecode_validator",
        "bytecode_load_api",
        "bytecode_status_api",
        "bytecode_inventory_api",
        "bytecode_summary_api",
        "bytecode_reason_summary",
        "bytecode_candidate_lists",
        "bytecode_candidate_exports",
        "bytecode_provision_plan",
        "bec_manifest",
        "sys_path",
        "environment",
        "subprocess",
        "network_sockets",
        "native_threads",
        "video_output",
        "vga_demo",
        "usb_hid",
        "usb_demo",
        "psram_heap",
        "board_profile_policy",
        "child_vm_primitive_transfer",
        "child_vm_named_closure_bridge",
        "child_vm_captured_closure_transfer",
        "child_vm_live_object_transfer",
        "child_vm_transfer_policy",
        "child_vm_partition_policy"
    ])
end

p2compat.required_board_profile_policy_keys = def()
    return p2compat._copy_list([
        "model",
        "board",
        "profile",
        "catalina_model",
        "memory_profile",
        "psram_enabled",
        "reserved_pin_policy",
        "unsupported_build_policy",
        "normal_toolchain",
        "normal_catalina_dir",
        "normal_serial_port",
        "default_p2_edge_profile",
        "edge32_psram_policy",
        "xmm_policy",
        "reserved_pin_ranges",
        "safe_jumper_pins",
        "status_capabilities"
    ])
end

p2compat.required_child_vm_policy_keys = def()
    return p2compat._copy_list([
        "model",
        "primitive_copy",
        "copyable_types",
        "bounded_string_copy",
        "string_policy",
        "closure_name_bridge",
        "closure_name_policy",
        "captured_closure_transfer",
        "live_object_transfer",
        "rejected_live_types",
        "ownership_transfer",
        "shared_mutable_state",
        "resource_transfer",
        "default_policy",
        "serialization_policy",
        "ipc_policy",
        "unsupported_helpers",
        "status_capabilities"
    ])
end

p2compat.required_child_vm_partition_policy_keys = def()
    return p2compat._copy_list([
        "model",
        "source",
        "partition_bytes",
        "capacity",
        "free_capacity",
        "max_partitions",
        "created",
        "current",
        "usable_for_child_calls",
        "sizing_policy",
        "production_count_selected",
        "retry_policy",
        "real_cog_policy",
        "status_capabilities"
    ])
end

p2compat.board_profile_value = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = p2compat.board_profile_policy()
    if !policy.contains(name)
        return nil
    end
    var value = policy[name]
    if type(value) == "list"
        if name == "reserved_pin_ranges"
            return p2compat._copy_ranges(value)
        end
        return p2compat._copy_list(value)
    end
    return value
end

p2compat.board_pin_policy = def(pin)
    if type(pin) != "int"
        return {
            "ok": false,
            "pin": pin,
            "reserved": true,
            "reason": "invalid_pin_type"
        }
    end
    if pin < 0 || pin > 63
        return {
            "ok": false,
            "pin": pin,
            "reserved": true,
            "reason": "pin_out_of_range"
        }
    end
    var ranges = p2compat.board_profile_policy()["reserved_pin_ranges"]
    var i = 0
    while i < ranges.size()
        var item = ranges[i]
        if pin >= item["first"] && pin <= item["last"]
            return {
                "ok": false,
                "pin": pin,
                "reserved": true,
                "reason": item["name"]
            }
        end
        i += 1
    end
    return {
        "ok": true,
        "pin": pin,
        "reserved": false,
        "reason": "ok"
    }
end

p2compat.board_pin_allowed = def(pin)
    return p2compat.board_pin_policy(pin)["ok"]
end

p2compat.child_vm_live_object_transfer = def(value)
    raise "unsupported_error", "live object graph transfer across child VM boundaries is not implemented; use child_vm_transfer_policy() for the explicit boundary"
end

p2compat.child_vm_copyable_type = def(name)
    if type(name) != "string"
        return false
    end
    var values = p2compat.child_vm_transfer_policy()["copyable_types"]
    var i = 0
    while i < values.size()
        if values[i] == name
            return true
        end
        i += 1
    end
    return false
end

p2compat.child_vm_rejected_type = def(name)
    if type(name) != "string"
        return false
    end
    var values = p2compat.child_vm_transfer_policy()["rejected_live_types"]
    var i = 0
    while i < values.size()
        if values[i] == name
            return true
        end
        i += 1
    end
    return false
end

p2compat.child_vm_policy = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = p2compat.child_vm_transfer_policy()
    if !policy.contains(name)
        return nil
    end
    var value = policy[name]
    if type(value) == "list"
        return p2compat._copy_list(value)
    end
    return value
end

p2compat.child_vm_partition_value = def(name)
    if type(name) != "string"
        return nil
    end
    var policy = p2compat.child_vm_partition_policy()
    if !policy.contains(name)
        return nil
    end
    var value = policy[name]
    if type(value) == "list"
        return p2compat._copy_list(value)
    end
    return value
end

p2compat.find = def(name)
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
        if item["name"] == name
            return p2compat._copy_item(item)
        end
        i += 1
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
    var i = 0
    while i < p2compat._statuses.size()
        out.push(p2compat._statuses[i])
        i += 1
    end
    return out
end

p2compat.status_known = def(status)
    var i = 0
    while i < p2compat._statuses.size()
        if p2compat._statuses[i] == status
            return true
        end
        i += 1
    end
    return false
end

p2compat.names = def()
    var out = []
    var i = 0
    while i < p2compat._items.size()
        out.push(p2compat._items[i]["name"])
        i += 1
    end
    return out
end

p2compat.names_by_status = def(status)
    var out = []
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
        if item["status"] == status
            out.push(item["name"])
        end
        i += 1
    end
    return out
end

p2compat.status_report = def(status)
    var names = p2compat.names_by_status(status)
    return {
        "status": status,
        "known": p2compat.status_known(status),
        "count": size(names),
        "names": names
    }
end

p2compat.report = def()
    var status_names = p2compat.statuses()
    var by_status = {}
    var i = 0
    while i < status_names.size()
        var status = status_names[i]
        by_status[status] = p2compat.names_by_status(status)
        i += 1
    end
    return {
        "statuses": status_names,
        "summary": p2compat.summary(),
        "names": p2compat.names(),
        "by_status": by_status,
        "items": p2compat.items(),
        "bytecode": p2compat.bytecode(),
        "board_profile": p2compat.board_profile_policy(),
        "child_vm_partition": p2compat.child_vm_partition_policy()
    }
end

p2compat.audit = def()
    var seen = {}
    var duplicates = []
    var unknown_statuses = []
    var missing_capability_names = []
    var missing_board_profile_policy_keys = []
    var missing_child_vm_policy_keys = []
    var missing_child_vm_partition_policy_keys = []
    var counted = {
        "supported": 0,
        "partial": 0,
        "staged": 0,
        "unsupported": 0
    }
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
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
        i += 1
    end
    var required_names = p2compat.required_capability_names()
    i = 0
    while i < required_names.size()
        var name = required_names[i]
        if !seen.contains(name)
            missing_capability_names.push(name)
        end
        i += 1
    end
    var summary = p2compat.summary()
    var counts_match = counted[p2compat.SUPPORTED] == summary[p2compat.SUPPORTED]
    counts_match = counts_match && counted[p2compat.PARTIAL] == summary[p2compat.PARTIAL]
    counts_match = counts_match && counted[p2compat.STAGED] == summary[p2compat.STAGED]
    counts_match = counts_match && counted[p2compat.UNSUPPORTED] == summary[p2compat.UNSUPPORTED]
    var board_policy = p2compat.board_profile_policy()
    var board_keys = p2compat.required_board_profile_policy_keys()
    i = 0
    while i < board_keys.size()
        var key = board_keys[i]
        if !board_policy.contains(key)
            missing_board_profile_policy_keys.push(key)
        end
        i += 1
    end
    var board_policy_match = board_policy["model"] == "explicit_board_profile_policy"
    board_policy_match = board_policy_match && board_policy["unsupported_build_policy"] == "raise_loud_or_report_unsupported"
    board_policy_match = board_policy_match && board_policy["normal_toolchain"] == "catalina"
    board_policy_match = board_policy_match && board_policy["normal_catalina_dir"] == "../Catalina"
    board_policy_match = board_policy_match && board_policy["normal_serial_port"] == "/dev/ttyUSB0"
    board_policy_match = board_policy_match && board_policy["reserved_pin_ranges"].size() >= 2
    board_policy_match = board_policy_match && board_policy["status_capabilities"].find("board_profile_policy") >= 0
    var child_policy = p2compat.child_vm_transfer_policy()
    var child_keys = p2compat.required_child_vm_policy_keys()
    i = 0
    while i < child_keys.size()
        var key = child_keys[i]
        if !child_policy.contains(key)
            missing_child_vm_policy_keys.push(key)
        end
        i += 1
    end
    var child_policy_match = child_policy["primitive_copy"] == p2compat.status("child_vm_primitive_transfer")
    child_policy_match = child_policy_match && child_policy["closure_name_bridge"] == p2compat.status("child_vm_named_closure_bridge")
    child_policy_match = child_policy_match && child_policy["captured_closure_transfer"] == p2compat.status("child_vm_captured_closure_transfer")
    child_policy_match = child_policy_match && child_policy["live_object_transfer"] == p2compat.status("child_vm_live_object_transfer")
    child_policy_match = child_policy_match && !child_policy["ownership_transfer"]
    child_policy_match = child_policy_match && !child_policy["shared_mutable_state"]
    child_policy_match = child_policy_match && !child_policy["resource_transfer"]
    var partition_policy = p2compat.child_vm_partition_policy()
    var partition_keys = p2compat.required_child_vm_partition_policy_keys()
    i = 0
    while i < partition_keys.size()
        var key = partition_keys[i]
        if !partition_policy.contains(key)
            missing_child_vm_partition_policy_keys.push(key)
        end
        i += 1
    end
    var partition_policy_match = partition_policy["model"] == "runtime_heap_info_partition_policy"
    partition_policy_match = partition_policy_match && partition_policy["source"] == "p2.heap_info"
    partition_policy_match = partition_policy_match && !partition_policy["production_count_selected"]
    partition_policy_match = partition_policy_match && partition_policy["retry_policy"] == "stop_routine_priority_work_until_native_partition_allocator_changes"
    return {
        "ok": size(duplicates) == 0 && size(unknown_statuses) == 0 && size(missing_capability_names) == 0 && size(missing_board_profile_policy_keys) == 0 && size(missing_child_vm_policy_keys) == 0 && size(missing_child_vm_partition_policy_keys) == 0 && counts_match && board_policy_match && child_policy_match && partition_policy_match,
        "count": size(p2compat._items),
        "summary": summary,
        "counted": counted,
        "counts_match": counts_match,
        "board_profile_policy_match": board_policy_match,
        "child_vm_transfer_policy_match": child_policy_match,
        "child_vm_partition_policy_match": partition_policy_match,
        "missing_capability_names": missing_capability_names,
        "missing_board_profile_policy_keys": missing_board_profile_policy_keys,
        "missing_child_vm_policy_keys": missing_child_vm_policy_keys,
        "missing_child_vm_partition_policy_keys": missing_child_vm_partition_policy_keys,
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
    if size(audit["missing_capability_names"]) > 0
        out.push("missing_capability_names")
    end
    if size(audit["missing_board_profile_policy_keys"]) > 0
        out.push("missing_board_profile_policy_keys")
    end
    if size(audit["missing_child_vm_policy_keys"]) > 0
        out.push("missing_child_vm_policy_keys")
    end
    if size(audit["missing_child_vm_partition_policy_keys"]) > 0
        out.push("missing_child_vm_partition_policy_keys")
    end
    if !audit["counts_match"]
        out.push("summary_count_mismatch")
    end
    if !audit["child_vm_transfer_policy_match"]
        out.push("child_vm_transfer_policy_mismatch")
    end
    if !audit["board_profile_policy_match"]
        out.push("board_profile_policy_mismatch")
    end
    if !audit["child_vm_partition_policy_match"]
        out.push("child_vm_partition_policy_mismatch")
    end
    return out
end

p2compat.audit_ok = def()
    return size(p2compat.audit_problems()) == 0
end

p2compat.unsupported = def()
    var out = []
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
        if item["status"] == p2compat.UNSUPPORTED
            out.push(p2compat._copy_item(item))
        end
        i += 1
    end
    return out
end

p2compat.items_by_status = def(status)
    var out = []
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
        if item["status"] == status
            out.push(p2compat._copy_item(item))
        end
        i += 1
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
    var i = 0
    while i < p2compat._items.size()
        var item = p2compat._items[i]
        var status = item["status"]
        if out.contains(status)
            out[status] += 1
        end
        i += 1
    end
    return out
end

return p2compat
