print("P2_SMOKE_BEGIN module_inventory")

import json
import libstore
import p2mem

var modules = libstore.modules()
var inventory = libstore.inventory()
var compiled_inventory = libstore.compiled_inventory()
assert(size(inventory) >= size(modules))
assert(size(compiled_inventory) >= size(modules))

var compiled_text = libstore.compiled_inventory_text()
assert(type(compiled_text) == "string")
var compiled_text_data = json.load(compiled_text)
assert(type(compiled_text_data) == "list")
assert(size(compiled_text_data) == size(compiled_inventory))
var compiled_summary = libstore.compiled_summary()
assert(type(compiled_summary) == "map")
assert(compiled_summary["modules"] == size(compiled_inventory))
assert(type(compiled_summary["source_exists"]) == "int")
assert(type(compiled_summary["compiled_exists"]) == "int")
assert(type(compiled_summary["manifest_exists"]) == "int")
assert(type(compiled_summary["manifest_valid"]) == "int")
assert(type(compiled_summary["fresh"]) == "int")
assert(type(compiled_summary["usable"]) == "int")
assert(type(compiled_summary["can_load"]) == "int")
assert(type(compiled_summary["can_emit"]) == "int")
assert(type(compiled_summary["blocked_load"]) == "int")
assert(type(compiled_summary["blocked_emit"]) == "int")
assert(type(compiled_summary["load_reasons"]) == "map")
assert(type(compiled_summary["emit_reasons"]) == "map")
assert(compiled_summary["can_load"] + compiled_summary["blocked_load"] == compiled_summary["modules"])
assert(compiled_summary["can_emit"] + compiled_summary["blocked_emit"] == compiled_summary["modules"])
var load_reason_total = 0
for reason : compiled_summary["load_reasons"].keys()
    assert(type(reason) == "string")
    assert(type(compiled_summary["load_reasons"][reason]) == "int")
    load_reason_total += compiled_summary["load_reasons"][reason]
end
assert(load_reason_total == compiled_summary["modules"])
var emit_reason_total = 0
for reason : compiled_summary["emit_reasons"].keys()
    assert(type(reason) == "string")
    assert(type(compiled_summary["emit_reasons"][reason]) == "int")
    emit_reason_total += compiled_summary["emit_reasons"][reason]
end
assert(emit_reason_total == compiled_summary["modules"])
var compiled_summary_data = json.load(libstore.compiled_summary_text())
assert(compiled_summary_data["modules"] == compiled_summary["modules"])
assert(compiled_summary_data["can_load"] == compiled_summary["can_load"])
assert(compiled_summary_data["can_emit"] == compiled_summary["can_emit"])
assert(type(compiled_summary_data["load_reasons"]) == "map")
assert(type(compiled_summary_data["emit_reasons"]) == "map")
var summary_modules = compiled_summary["modules"]
compiled_summary["modules"] = -1
assert(libstore.compiled_summary()["modules"] == summary_modules)
compiled_summary["modules"] = summary_modules
assert(size(inventory) > 0)
var isolated_inventory_name = inventory[0]["name"]
inventory[0]["name"] = "__p2_mutated_inventory__"
inventory[0]["coverage_status"] = "__p2_mutated_status__"
var inventory_again = libstore.inventory()
assert(inventory_again[0]["name"] == isolated_inventory_name)
assert(inventory_again[0]["name"] != inventory[0]["name"])
assert(inventory_again[0]["coverage_status"] != "__p2_mutated_status__")
assert(size(compiled_inventory) > 0)
var isolated_compiled_name = compiled_inventory[0]["name"]
compiled_inventory[0]["name"] = "__p2_mutated_compiled__"
var compiled_inventory_again = libstore.compiled_inventory()
assert(compiled_inventory_again[0]["name"] == isolated_compiled_name)
assert(compiled_inventory_again[0]["name"] != compiled_inventory[0]["name"])
var loadable = libstore.compiled_loadable()
var emittable = libstore.compiled_emittable()
var blocked = libstore.compiled_blocked()
var loadable_data = json.load(libstore.compiled_loadable_text())
var emittable_data = json.load(libstore.compiled_emittable_text())
var blocked_data = json.load(libstore.compiled_blocked_text())
assert(size(loadable) == compiled_summary["can_load"])
assert(size(emittable) == compiled_summary["can_emit"])
assert(size(blocked) >= compiled_summary["blocked_load"])
assert(size(blocked) >= compiled_summary["blocked_emit"])
assert(size(loadable_data) == size(loadable))
assert(size(emittable_data) == size(emittable))
assert(size(blocked_data) == size(blocked))
for rec : loadable
    assert(rec["can_load"])
end
for rec : emittable
    assert(rec["can_emit"])
end
for rec : blocked
    assert(!rec["can_load"] || !rec["can_emit"])
end
var provision = libstore.compiled_provision_plan()
assert(type(provision) == "map")
assert(provision["ok"])
assert(type(provision["recommendation"]) == "string")
assert(type(provision["summary"]) == "map")
assert(type(provision["loadable"]) == "list")
assert(type(provision["emittable"]) == "list")
assert(type(provision["blocked"]) == "list")
assert(provision["loadable_count"] == size(loadable))
assert(provision["emittable_count"] == size(emittable))
assert(provision["blocked_count"] == size(blocked))
assert(provision["default_source_fallback"] == (compiled_summary["can_load"] == 0))
var provision_data = json.load(libstore.compiled_provision_plan_text())
assert(provision_data["ok"])
assert(provision_data["recommendation"] == provision["recommendation"])
assert(provision_data["loadable_count"] == provision["loadable_count"])
assert(provision_data["emittable_count"] == provision["emittable_count"])
assert(provision_data["blocked_count"] == provision["blocked_count"])

var expected_names = [
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
var expected = {}
for name : expected_names
    expected[name] = false
end

for rec : inventory
    assert(type(rec) == "map")
    assert(type(rec["name"]) == "string")
    if expected.contains(rec["name"])
        expected[rec["name"]] = true
    end
    assert(rec.contains("path"))
    assert(rec.contains("exists"))
    assert(rec.contains("source_size"))
    assert(rec.contains("source_hash"))
    assert(rec.contains("compiled_path"))
    assert(rec.contains("compiled_exists"))
    assert(rec.contains("compiled_size"))
    assert(rec.contains("compiled_hash"))
    assert(rec.contains("compiled_manifest_path"))
    assert(rec.contains("compiled_manifest_exists"))
    assert(rec.contains("compiled_manifest_valid"))
    assert(rec.contains("compiled_manifest_reason"))
    assert(rec.contains("compiled_fresh"))
    assert(rec.contains("compiled_usable"))
    assert(rec.contains("compiled_freshness_reason"))
    assert(rec.contains("compiled_preferred"))
    assert(rec.contains("compiled_blocked_reason"))
    assert(rec.contains("compiled_supported"))
    assert(rec.contains("compiled_loader_supported"))
    assert(rec.contains("compiled_bytecode_loader"))
    assert(rec.contains("compiled_validator_supported"))
    assert(rec.contains("compiled_loader_reason"))
    assert(rec.contains("compiled_validation_supported"))
    assert(rec.contains("compiled_validation_valid"))
    assert(rec.contains("compiled_validation_reason"))
    assert(rec.contains("compiled_load_can"))
    assert(rec.contains("compiled_load_reason"))
    assert(rec.contains("compiled_status_can_load"))
    assert(rec.contains("compiled_status_can_emit"))
    assert(rec.contains("compiled_status_reason"))
    assert(rec.contains("compile_cache_supported"))
    assert(rec.contains("compile_cache_can_emit"))
    assert(rec.contains("compile_cache_reason"))
    assert(rec.contains("compile_cache_blocked_reason"))
    assert(rec.contains("compile_cache_target_path"))
    assert(rec.contains("compile_cache_manifest_target_path"))
    assert(rec.contains("compile_cache_manifest_format"))
    assert(rec.contains("compile_cache_manifest_template_available"))
    assert(rec.contains("compile_cache_manifest_template_reason"))
    assert(rec.contains("selected_path"))
    assert(rec.contains("selected_kind"))
    assert(rec.contains("resolve_reason"))
    assert(rec.contains("source_fallback"))
    assert(rec.contains("cache_hit_count"))
    assert(rec.contains("cache_miss_count"))
    assert(rec.contains("last_used"))
    assert(rec.contains("coverage"))
    assert(rec.contains("coverage_status"))
    assert(rec.contains("behavior_smoke"))
    assert(rec.contains("sd_import_smoke"))
    assert(rec.contains("repeated_import_smoke"))
    assert(rec.contains("cache_smoke"))
    assert(rec.contains("low_memory_smoke"))
    assert(rec.contains("metadata_smoke"))
    assert(rec.contains("coverage_reason"))
    if rec["exists"]
        assert(rec["path"] != nil)
        assert(rec["source_size"] > 0)
        assert(type(rec["source_hash"]) == "int")
        var stats = libstore.source_stats(rec["name"])
        assert(stats["exists"])
        assert(rec["path"] == stats["path"])
        assert(rec["source_size"] == stats["size"])
        assert(rec["source_hash"] == stats["hash"])
    end
    if expected.contains(rec["name"])
        assert(type(rec["coverage"]) == "map")
        assert(rec["coverage_status"] != "unknown")
        assert(type(rec["sd_import_smoke"]) == "string")
        assert(rec["sd_import_smoke"] == "/tests/p2/smoke_import_all_libs.be")
        assert(type(rec["repeated_import_smoke"]) == "string")
        assert(rec["repeated_import_smoke"] == "/tests/p2/smoke_import_cache.be")
        assert(type(rec["cache_smoke"]) == "string")
        assert(rec["cache_smoke"] == "/tests/p2/smoke_import_cache.be")
        assert(type(rec["low_memory_smoke"]) == "string")
        assert(rec["low_memory_smoke"] == "/tests/p2/smoke_import_churn.be")
        assert(type(rec["metadata_smoke"]) == "string")
        assert(rec["metadata_smoke"] == "/tests/p2/smoke_module_inventory.be")
        assert(type(rec["coverage_reason"]) == "string")
        if rec["coverage_status"] == "covered"
            assert(type(rec["behavior_smoke"]) == "string")
        end
        if rec["name"] == "wifi"
            assert(rec["coverage_status"] == "hardware_deferred")
            assert(rec["behavior_smoke"] == nil)
        end
    end
    if rec["compiled_exists"]
        assert(rec["compiled_path"] != nil)
        assert(rec["compiled_size"] > 0)
        assert(type(rec["compiled_hash"]) == "int")
        assert(type(rec["compiled_fresh"]) == "bool")
        assert(type(rec["compiled_usable"]) == "bool")
        if rec["compiled_usable"] {
            assert(rec["compiled_loader_supported"])
            assert(rec["compiled_fresh"])
        }
        assert(type(rec["compiled_freshness_reason"]) == "string")
    end
    assert(type(rec["compiled_loader_supported"]) == "bool")
    assert(type(rec["compiled_bytecode_loader"]) == "bool")
    assert(type(rec["compiled_validator_supported"]) == "bool")
    assert(type(rec["compiled_validation_supported"]) == "bool")
    assert(type(rec["compiled_validation_valid"]) == "bool")
    assert(type(rec["compiled_validation_reason"]) == "string")
    assert(type(rec["compiled_load_can"]) == "bool")
    assert(type(rec["compiled_load_reason"]) == "string")
    assert(type(rec["compiled_status_can_load"]) == "bool")
    assert(type(rec["compiled_status_can_emit"]) == "bool")
    assert(type(rec["compiled_status_reason"]) == "string")
    assert(rec["compiled_status_can_load"] == rec["compiled_load_can"])
    assert(rec["compiled_validation_supported"] == rec["compiled_validator_supported"])
    if rec["compiled_validation_valid"] {
        assert(rec["compiled_validation_supported"])
    }
    if rec["compiled_load_can"] {
        assert(rec["compiled_validation_valid"])
        assert(rec["compiled_usable"])
    }
    if rec["compiled_loader_supported"] {
        assert(rec["compiled_bytecode_loader"])
    }
    assert(type(rec["compiled_loader_reason"]) == "string")
    assert(type(rec["compile_cache_supported"]) == "bool")
    assert(type(rec["compile_cache_can_emit"]) == "bool")
    assert(type(rec["compile_cache_reason"]) == "string")
    assert(rec["compile_cache_blocked_reason"] == nil || type(rec["compile_cache_blocked_reason"]) == "string")
    assert(type(rec["compile_cache_target_path"]) == "string")
    assert(type(rec["compile_cache_manifest_target_path"]) == "string")
    assert(rec["compile_cache_manifest_format"] == libstore.MANIFEST_FORMAT)
    assert(type(rec["compile_cache_manifest_template_available"]) == "bool")
    assert(type(rec["compile_cache_manifest_template_reason"]) == "string")
    if rec["name"] == "math"
        assert(rec["exists"])
        assert(rec["selected_kind"] == "source")
        assert(rec["resolve_reason"] == "source")
    end
end

for rec : compiled_inventory
    assert(type(rec) == "map")
    assert(type(rec["name"]) == "string")
    assert(rec.contains("source_exists"))
    assert(rec.contains("compiled_exists"))
    assert(rec.contains("manifest_exists"))
    assert(rec.contains("fresh"))
    assert(rec.contains("usable"))
    assert(rec.contains("freshness_reason"))
    assert(rec.contains("validation_valid"))
    assert(rec.contains("validation_reason"))
    assert(rec.contains("can_load"))
    assert(rec.contains("load_reason"))
    assert(rec.contains("can_emit"))
    assert(rec.contains("emit_reason"))
    assert(type(rec["can_load"]) == "bool")
    assert(type(rec["can_emit"]) == "bool")
    assert(type(rec["load_reason"]) == "string")
    assert(type(rec["emit_reason"]) == "string")
end

for name : expected_names
    assert(expected[name])
end

var math_rec = p2mem.module("math")
assert(math_rec != nil)
assert(math_rec["module"] == "math")
assert(math_rec["exists"])
assert(math_rec["source_path"] == libstore.source_path("math"))
assert(math_rec["source_size"] == libstore.info("math")["source_size"])
assert(math_rec["source_hash"] == libstore.info("math")["source_hash"])
assert(math_rec["compiled_size"] == libstore.info("math")["compiled_size"])
assert(math_rec["compiled_hash"] == libstore.info("math")["compiled_hash"])
assert(math_rec["compiled_fresh"] == libstore.info("math")["compiled_fresh"])
assert(math_rec["compiled_usable"] == libstore.info("math")["compiled_usable"])
assert(math_rec["compiled_freshness_reason"] == libstore.info("math")["compiled_freshness_reason"])
assert(math_rec["compiled_validation_supported"] == libstore.info("math")["compiled_validation_supported"])
assert(math_rec["compiled_validation_valid"] == libstore.info("math")["compiled_validation_valid"])
assert(math_rec["compiled_validation_reason"] == libstore.info("math")["compiled_validation_reason"])
assert(math_rec["compiled_load_can"] == libstore.info("math")["compiled_load_can"])
assert(math_rec["compiled_load_reason"] == libstore.info("math")["compiled_load_reason"])
assert(math_rec["compiled_status_can_load"] == libstore.info("math")["compiled_status_can_load"])
assert(math_rec["compiled_status_can_emit"] == libstore.info("math")["compiled_status_can_emit"])
assert(math_rec["compiled_status_reason"] == libstore.info("math")["compiled_status_reason"])
assert(math_rec["selected_kind"] == "source")
assert(math_rec["resolve_reason"] == "source")
assert(p2mem.module("p2_no_such_module") == nil)

print("P2_SMOKE_PASS module_inventory")
