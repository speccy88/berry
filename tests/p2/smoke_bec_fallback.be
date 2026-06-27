print("P2_SMOKE_BEGIN bec_fallback")

import os
import json
import libstore
import p2mem

var bytecode_execution = libstore.compiled_execution_probe()
assert(type(bytecode_execution) == "map")
assert(type(bytecode_execution["supported"]) == "bool")
assert(type(bytecode_execution["loader_supported"]) == "bool")
assert(type(bytecode_execution["validator_supported"]) == "bool")
assert(type(bytecode_execution["reason"]) == "string")
assert(type(bytecode_execution["execution_flag"]) == "bool")
assert(bytecode_execution["supported"] == (bytecode_execution["loader_supported"] && bytecode_execution["validator_supported"]))
var bytecode_supported = bytecode_execution["supported"]
bytecode_execution["supported"] = !bytecode_supported
assert(libstore.compiled_execution_probe()["supported"] == bytecode_supported)
bytecode_execution["supported"] = bytecode_supported
print("P2_SMOKE_STAGE bec_fallback execution_probe")

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

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

ensure_dir("/berry")
ensure_dir("/berry/lib")
ensure_dir("/berry/cache")
print("P2_SMOKE_STAGE bec_fallback dirs")

var name = "becfall"
var source_path = "/berry/lib/becfall.be"
var compiled_path = "/berry/cache/becfall.bec"
var manifest_path = "/berry/cache/becfall.jsn"
var legacy_manifest_path = compiled_path + ".json"

try
    os.remove(source_path)
except .. as e, m
end
try
    os.remove(compiled_path)
except .. as e, m
end
try
    os.remove(manifest_path)
except .. as e, m
end
try
    os.remove(legacy_manifest_path)
except .. as e, m
end

var cf = open(compiled_path, "w")
cf.write("dummy unsupported bytecode")
cf.close()
var compiled_text = "dummy unsupported bytecode"

var sf = open(source_path, "w")
sf.write("var becfall = module('becfall')\n")
sf.write("becfall.answer = 42\n")
sf.write("return becfall\n")
sf.close()

assert(libstore.source_path(name) == source_path)
assert(libstore.compiled_path(name) == compiled_path)
assert(libstore.compiled_exists(name))
print("P2_SMOKE_STAGE bec_fallback paths")

var info = libstore.info(name)
assert(info["exists"])
assert(info["compiled_exists"])
assert(info["compiled_path"] == compiled_path)
assert(info["compiled_size"] == size(compiled_text))
assert(info["compiled_hash"] == libstore.hash_text(compiled_text))
print("P2_SMOKE_STAGE bec_fallback info_sizes")
assert(info["compiled_manifest_path"] == nil)
assert(info["compiled_manifest_exists"] == false)
assert(info["compiled_manifest_valid"] == false)
assert(info["compiled_fresh"] == false)
assert(info["compiled_usable"] == false)
assert(info["compiled_freshness_reason"] == "bytecode_freshness_manifest_unavailable")
assert(info["compiled_supported"] == bytecode_execution["supported"])
print("P2_SMOKE_STAGE bec_fallback info_compiled")
assert(info["compile_cache_supported"] == false)
assert(info["compile_cache_can_emit"] == false)
assert(info["compile_cache_reason"] == "bytecode_emit_unavailable")
assert(info["compile_cache_blocked_reason"] == "bytecode_emit_unavailable")
assert(info["compile_cache_target_path"] == compiled_path)
assert(info["compile_cache_manifest_target_path"] == manifest_path)
assert(info["compile_cache_manifest_format"] == libstore.MANIFEST_FORMAT)
assert(info["compile_cache_manifest_template_available"])
assert(info["compile_cache_manifest_template_reason"] == "ok")
print("P2_SMOKE_STAGE bec_fallback info_cache")
assert(info["source_fallback"] == true)
assert(info["selected_path"] == source_path)
assert(info["selected_kind"] == "source")
assert(info["resolve_reason"] == "compiled_unsupported_source_fallback")
print("P2_SMOKE_STAGE bec_fallback initial_info")

var resolved = libstore.resolve(name)
if resolved["selected_kind"] != nil
    assert(resolved["source_path"] == source_path)
    assert(resolved["compiled_path"] == compiled_path)
    assert(resolved["compiled_size"] == size(compiled_text))
    if resolved["compiled_hash"] != nil
        assert(resolved["compiled_hash"] == libstore.hash_text(compiled_text))
    end
    assert(resolved["compiled_manifest_path"] == nil)
    assert(resolved["compiled_manifest_exists"] == false)
    assert(resolved["compiled_manifest_valid"] == false)
    assert(resolved["compiled_fresh"] == false)
    assert(resolved["compiled_usable"] == false)
    assert(resolved["compiled_freshness_reason"] == "bytecode_freshness_manifest_unavailable")
    assert(resolved["compiled_preferred"] == false)
    assert(resolved["compiled_blocked_reason"] == "bytecode_freshness_manifest_unavailable")
    assert(resolved["selected_path"] == source_path)
    assert(resolved["selected_kind"] == "source")
    assert(resolved["reason"] == "compiled_unsupported_source_fallback")
end
print("P2_SMOKE_STAGE bec_fallback initial_resolve")

var plan = libstore.compile_cache_plan(name)
print("P2_SMOKE_DIAG bec_fallback initial_plan_core", plan["supported"], plan["can_emit"], plan["reason"], plan["emit_blocked_reason"])
print("P2_SMOKE_DIAG bec_fallback initial_plan_manifest", plan["manifest_path"], plan["manifest_exists"], plan["manifest_valid"], plan["manifest_reason"])
print("P2_SMOKE_DIAG bec_fallback initial_plan_select", plan["selected_path"], plan["selected_kind"], plan["resolve_reason"])
assert(plan["supported"] == false)
assert(plan["can_emit"] == false)
assert(plan["reason"] == "bytecode_emit_unavailable" || plan["reason"] == "source_missing")
assert(plan["emit_blocked_reason"] == plan["reason"])
assert(plan["manifest_format"] == libstore.MANIFEST_FORMAT)
assert(plan["manifest_required"])
assert(plan["validator_required"])
assert(plan["execution_required"])
if plan["manifest_template_available"]
    assert(plan["manifest_template_reason"] == "ok")
    assert(type(plan["manifest_template"]) == "map")
    assert(plan["manifest_template"]["format"] == libstore.MANIFEST_FORMAT)
    assert(plan["manifest_template"]["module"] == name)
    if plan["manifest_template"]["source_hash"] != nil
        assert(plan["manifest_template"]["source_hash"] == info["source_hash"])
    end
    if plan["manifest_template"]["compiled_hash"] != nil
        assert(plan["manifest_template"]["compiled_hash"] == libstore.hash_text(compiled_text))
    end
end
var manifest_text = libstore.compiled_manifest_text(name)
if manifest_text != nil
    assert(type(manifest_text) == "string")
    var manifest_text_data = json.load(manifest_text)
    assert(manifest_text_data["format"] == libstore.MANIFEST_FORMAT)
    assert(manifest_text_data["module"] == name)
    if manifest_text_data["source_hash"] != nil
        assert(manifest_text_data["source_hash"] == info["source_hash"])
    end
    if manifest_text_data["compiled_hash"] != nil
        assert(manifest_text_data["compiled_hash"] == libstore.hash_text(compiled_text))
    end
end
assert(plan["target_path"] == compiled_path)
assert(plan["manifest_target_path"] == manifest_path)
if plan["source_exists"]
    assert(plan["source_path"] == source_path)
    assert(plan["source_size"] == info["source_size"])
    if plan["source_hash"] != nil
        assert(plan["source_hash"] == info["source_hash"])
    end
end
if plan["compiled_exists"]
    assert(plan["compiled_path"] == compiled_path)
    assert(plan["compiled_size"] == size(compiled_text))
    if plan["compiled_hash"] != nil
        assert(plan["compiled_hash"] == libstore.hash_text(compiled_text))
    end
end
assert(plan["manifest_path"] == nil)
assert(plan["manifest_exists"] == false)
assert(plan["manifest_valid"] == false)
if plan["selected_kind"] != nil
    assert(plan["selected_path"] == source_path)
    assert(plan["selected_kind"] == "source")
    assert(plan["resolve_reason"] == "compiled_unsupported_source_fallback")
end
print("P2_SMOKE_STAGE bec_fallback initial_plan")

var fresh = libstore.compiled_freshness(name)
assert(fresh["fresh"] == false)
assert(fresh["usable"] == false)
assert(fresh["reason"] == "bytecode_freshness_manifest_unavailable" || fresh["reason"] == "source_missing" || fresh["reason"] == "missing")
if fresh["source_path"] != nil
    assert(fresh["source_path"] == source_path)
end
if fresh["compiled_path"] != nil
    assert(fresh["compiled_path"] == compiled_path)
end
if fresh["manifest_path"] != nil
    assert(fresh["manifest_path"] == manifest_path)
end
if fresh["source_hash"] != nil
    assert(fresh["source_hash"] == info["source_hash"])
end
if fresh["compiled_hash"] != nil
    assert(fresh["compiled_hash"] == libstore.hash_text(compiled_text))
end
print("P2_SMOKE_STAGE bec_fallback initial_fresh")

var bad_mf = open(manifest_path, "w")
bad_mf.write("not json")
bad_mf.close()

var bad_manifest = libstore.compiled_manifest(name)
assert(bad_manifest["path"] == manifest_path)
assert(bad_manifest["exists"])
assert(bad_manifest["valid"] == false)
assert(bad_manifest["reason"] == "invalid_manifest")

fresh = libstore.compiled_freshness(name)
assert(fresh["manifest_path"] == manifest_path)
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"] == false)
assert(fresh["fresh"] == false)
assert(fresh["usable"] == false)
assert(fresh["comparable"] == false)
assert(fresh["reason"] == "invalid_manifest")
print("P2_SMOKE_STAGE bec_fallback invalid_manifest")

resolved = libstore.resolve(name)
assert(resolved["compiled_manifest_path"] == manifest_path)
assert(resolved["compiled_manifest_exists"])
assert(resolved["compiled_manifest_valid"] == false)
assert(resolved["compiled_freshness_reason"] == "invalid_manifest")
assert(resolved["selected_path"] == source_path)
assert(resolved["selected_kind"] == "source")
assert(resolved["reason"] == "compiled_unsupported_source_fallback")

plan = libstore.compile_cache_plan(name)
assert(plan["manifest_path"] == manifest_path)
assert(plan["manifest_exists"])
assert(plan["manifest_valid"] == false)
assert(plan["manifest_reason"] == "invalid_manifest")
assert(plan["selected_path"] == source_path)
assert(plan["selected_kind"] == "source")

bad_mf = open(manifest_path, "w")
bad_mf.write(json.dump({
    "format": "wrong-format",
    "module": name,
    "source_hash": info["source_hash"],
    "compiled_hash": libstore.hash_text(compiled_text)
}))
bad_mf.close()
bad_manifest = libstore.compiled_manifest(name)
assert(bad_manifest["exists"])
assert(bad_manifest["valid"] == false)
assert(bad_manifest["reason"] == "invalid_manifest_format")
fresh = libstore.compiled_freshness(name)
assert(fresh["reason"] == "invalid_manifest_format")
assert(fresh["usable"] == false)
assert(fresh["fresh"] == false)
print("P2_SMOKE_STAGE bec_fallback invalid_format")

bad_mf = open(manifest_path, "w")
bad_mf.write(json.dump({
    "format": libstore.MANIFEST_FORMAT,
    "module": "wrong_module",
    "source_hash": info["source_hash"],
    "compiled_hash": libstore.hash_text(compiled_text)
}))
bad_mf.close()
bad_manifest = libstore.compiled_manifest(name)
assert(bad_manifest["exists"])
assert(bad_manifest["valid"] == false)
assert(bad_manifest["reason"] == "manifest_module_mismatch")
fresh = libstore.compiled_freshness(name)
assert(fresh["reason"] == "manifest_module_mismatch")
assert(fresh["usable"] == false)
assert(fresh["fresh"] == false)
print("P2_SMOKE_STAGE bec_fallback module_mismatch")

bad_mf = open(manifest_path, "w")
bad_mf.write(json.dump({
    "format": libstore.MANIFEST_FORMAT,
    "module": name
}))
bad_mf.close()
bad_manifest = libstore.compiled_manifest(name)
assert(bad_manifest["exists"])
assert(bad_manifest["valid"] == false)
assert(bad_manifest["reason"] == "manifest_hash_missing")
fresh = libstore.compiled_freshness(name)
assert(fresh["reason"] == "manifest_hash_missing")
assert(fresh["usable"] == false)
assert(fresh["fresh"] == false)
print("P2_SMOKE_STAGE bec_fallback hash_missing")

var mf = open(manifest_path, "w")
mf.write(json.dump({
    "format": libstore.MANIFEST_FORMAT,
    "module": name,
    "source_size": info["source_size"],
    "source_hash": info["source_hash"],
    "compiled_size": size(compiled_text),
    "compiled_hash": libstore.hash_text(compiled_text)
}))
mf.close()

fresh = libstore.compiled_freshness(name)
var dummy_load_reason = bytecode_execution["supported"] ? "invalid_bytecode_header" : "compiled_execution_unavailable"
assert(fresh["manifest_path"] == manifest_path)
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"])
assert(fresh["comparable"])
assert(fresh["fresh"])
assert(fresh["usable"] == false)
assert(fresh["reason"] == dummy_load_reason)
var validation = libstore.compiled_validation(name)
assert(validation["fresh"])
assert(validation["comparable"])
assert(validation["supported"] == bytecode_execution["validator_supported"])
assert(validation["valid"] == false)
assert(validation["reason"] == (bytecode_execution["validator_supported"] ? "invalid_bytecode_header" : "bytecode_validator_unavailable"))
var load_plan = libstore.compiled_load_plan(name)
assert(load_plan["compiled_exists"])
assert(load_plan["fresh"])
assert(load_plan["usable"] == false)
assert(load_plan["validation_valid"] == validation["valid"])
assert(load_plan["can_load"] == false)
assert(load_plan["reason"] == validation["reason"])
var status = libstore.compiled_status(name)
assert(status["compiled_exists"])
assert(status["manifest_exists"])
assert(status["manifest_valid"])
assert(status["fresh"])
assert(status["comparable"])
assert(status["usable"] == false)
assert(status["validation_valid"] == validation["valid"])
assert(status["validation_reason"] == validation["reason"])
assert(status["can_load"] == load_plan["can_load"])
assert(status["load_reason"] == load_plan["reason"])
assert(type(status["load_plan"]) == "map")
assert(type(status["emit_plan"]) == "map")
assert(type(status["validation"]) == "map")
var status_text = libstore.compiled_status_text(name)
assert(type(status_text) == "string")
var status_data = json.load(status_text)
assert(status_data["name"] == name)
assert(status_data["compiled_exists"] == status["compiled_exists"])
assert(status_data["fresh"] == status["fresh"])
assert(status_data["can_load"] == status["can_load"])
assert(status_data["load_reason"] == status["load_reason"])
expect_error(def () libstore.load_compiled(name) end, "unsupported_error")
print("P2_SMOKE_STAGE bec_fallback fresh_manifest")

info = libstore.info(name)
assert(info["compiled_manifest_path"] == manifest_path)
assert(info["compiled_manifest_exists"])
assert(info["compiled_manifest_valid"])
assert(info["compiled_fresh"])
assert(info["compiled_usable"] == false)
assert(info["compiled_freshness_reason"] == dummy_load_reason)
assert(info["compiled_loader_supported"] == bytecode_execution["loader_supported"])
assert(info["compiled_bytecode_loader"] == bytecode_execution["loader_supported"])
assert(info["compiled_validator_supported"] == bytecode_execution["validator_supported"])
assert(info["compiled_loader_reason"] == bytecode_execution["reason"])
assert(info["compiled_validation_supported"] == validation["supported"])
assert(info["compiled_validation_valid"] == validation["valid"])
assert(info["compiled_validation_reason"] == validation["reason"])
assert(info["compiled_load_can"] == load_plan["can_load"])
assert(info["compiled_load_reason"] == load_plan["reason"])
assert(info["compiled_status_can_load"] == status["can_load"])
assert(info["compiled_status_can_emit"] == status["can_emit"])
assert(info["compiled_status_reason"] == status["load_reason"])
assert(info["compiled_preferred"])
assert(info["compiled_blocked_reason"] == dummy_load_reason)
assert(info["source_fallback"])

resolved = libstore.resolve(name)
assert(resolved["compiled_fresh"])
assert(resolved["compiled_usable"] == false)
assert(resolved["compiled_preferred"])
assert(resolved["compiled_blocked_reason"] == dummy_load_reason)
assert(resolved["selected_path"] == source_path)
assert(resolved["selected_kind"] == "source")

mf = open(manifest_path, "w")
mf.write(json.dump({
    "format": libstore.MANIFEST_FORMAT,
    "module": name,
    "source_size": info["source_size"],
    "source_hash": info["source_hash"] + 1,
    "compiled_size": size(compiled_text),
    "compiled_hash": libstore.hash_text(compiled_text)
}))
mf.close()

fresh = libstore.compiled_freshness(name)
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"])
assert(fresh["comparable"])
assert(fresh["fresh"] == false)
assert(fresh["usable"] == false)
assert(fresh["reason"] == "stale_manifest")
resolved = libstore.resolve(name)
assert(resolved["compiled_preferred"] == false)
assert(resolved["compiled_blocked_reason"] == "stale_manifest")
print("P2_SMOKE_STAGE bec_fallback stale_manifest")

print("P2_SMOKE_STAGE bec_fallback before_load")
var loaded = libstore.load(name)
print("P2_SMOKE_STAGE bec_fallback after_load")
assert(loaded.answer == 42)

print("P2_SMOKE_STAGE bec_fallback before_import")
import becfall
print("P2_SMOKE_STAGE bec_fallback after_import")
assert(becfall.answer == 42)

print("P2_SMOKE_STAGE bec_fallback before_p2mem")
var mem = p2mem.module(name)
print("P2_SMOKE_STAGE bec_fallback after_p2mem")
assert(mem != nil)
assert(mem["compiled_path"] == compiled_path)
assert(mem["compiled_exists"])
assert(mem["compiled_size"] == size(compiled_text))
assert(mem["compiled_hash"] == libstore.hash_text(compiled_text))
assert(mem["compiled_manifest_path"] == manifest_path)
assert(mem["compiled_manifest_exists"])
assert(mem["compiled_manifest_valid"])
assert(mem["compiled_fresh"] == false)
assert(mem["compiled_usable"] == false)
assert(mem["compiled_freshness_reason"] == "stale_manifest")
assert(mem["source_fallback"])
print("P2_SMOKE_STAGE bec_fallback p2mem_asserts")

var only_name = "beconly"
var only_path = "/berry/cache/beconly.bec"
var only_manifest_path = "/berry/cache/beconly.jsn"
var only_legacy_manifest_path = only_path + ".json"
var only_text = "dummy bytecode without source"
var emit_name = "becemit"
var emit_source_path = "/berry/lib/becemit.be"
var emit_compiled_path = "/berry/cache/becemit.bec"
var emit_manifest_path = "/berry/cache/becemit.jsn"
var emit_legacy_manifest_path = emit_compiled_path + ".json"

try
    os.remove(only_path)
except .. as e, m
end
try
    os.remove(only_manifest_path)
except .. as e, m
end
try
    os.remove(only_legacy_manifest_path)
except .. as e, m
end
try
    os.remove(emit_source_path)
except .. as e, m
end
try
    os.remove(emit_compiled_path)
except .. as e, m
end
try
    os.remove(emit_manifest_path)
except .. as e, m
end
try
    os.remove(emit_legacy_manifest_path)
except .. as e, m
end
print("P2_SMOKE_STAGE bec_fallback second_cleanup")

var of = open(only_path, "w")
of.write(only_text)
of.close()
print("P2_SMOKE_STAGE bec_fallback only_written")

var only_resolved = libstore.resolve(only_name)
assert(only_resolved["source_exists"] == false)
assert(only_resolved["compiled_exists"] == true)
assert(only_resolved["compiled_path"] == only_path)
assert(only_resolved["compiled_size"] == size(only_text))
assert(only_resolved["compiled_hash"] == libstore.hash_text(only_text))
assert(only_resolved["compiled_fresh"] == false)
assert(only_resolved["compiled_usable"] == false)
assert(only_resolved["compiled_freshness_reason"] == "compiled_without_source")
assert(only_resolved["selected_path"] == nil)
assert(only_resolved["selected_kind"] == nil)
assert(only_resolved["reason"] == "compiled_unsupported_no_source")
print("P2_SMOKE_STAGE bec_fallback only_resolve")

print("P2_SMOKE_STAGE bec_fallback before_only_source_stats")
var only_source_stats = libstore.source_stats(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_source_stats", only_source_stats["exists"])
var only_compiled_stats = libstore.compiled_stats(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_compiled_stats", only_compiled_stats["exists"], only_compiled_stats["size"])
var only_manifest_probe = libstore.compiled_manifest(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_manifest", only_manifest_probe["exists"], only_manifest_probe["reason"])
print("P2_SMOKE_STAGE bec_fallback before_only_plan")
var only_plan = libstore.compile_cache_plan(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_plan")
assert(only_plan["can_emit"] == false)
assert(only_plan["reason"] == "source_missing")
assert(only_plan["emit_blocked_reason"] == "source_missing")
assert(only_plan["manifest_format"] == libstore.MANIFEST_FORMAT)
assert(only_plan["manifest_required"])
assert(only_plan["validator_required"])
assert(only_plan["execution_required"])
assert(only_plan["manifest_template_available"] == false)
assert(only_plan["manifest_template_reason"] == "source_missing")
assert(only_plan["manifest_template"] == nil)
print("P2_SMOKE_STAGE bec_fallback only_plan_basic")
print("P2_SMOKE_STAGE bec_fallback before_only_manifest_text")
assert(libstore.compiled_manifest_text(only_name) == nil)
print("P2_SMOKE_STAGE bec_fallback after_only_manifest_text")
assert(only_plan["target_path"] == only_path)
assert(only_plan["manifest_target_path"] == only_manifest_path)
assert(only_plan["source_exists"] == false)
assert(only_plan["compiled_exists"] == true)
assert(only_plan["compiled_hash"] == libstore.hash_text(only_text))
print("P2_SMOKE_STAGE bec_fallback only_plan_paths")

var only_fresh = libstore.compiled_freshness(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_fresh")
assert(only_fresh["usable"] == false)
assert(only_fresh["fresh"] == false)
assert(only_fresh["reason"] == "compiled_without_source")
print("P2_SMOKE_STAGE bec_fallback before_only_load_plan")
var only_load_plan = libstore.compiled_load_plan(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_load_plan")
assert(only_load_plan["compiled_exists"])
assert(only_load_plan["can_load"] == false)
assert(only_load_plan["reason"] == "compiled_without_source")
print("P2_SMOKE_STAGE bec_fallback before_only_status")
var only_status = libstore.compiled_status(only_name)
print("P2_SMOKE_STAGE bec_fallback after_only_status")
assert(only_status["compiled_exists"])
assert(only_status["source_exists"] == false)
assert(only_status["can_load"] == false)
assert(only_status["load_reason"] == "compiled_without_source")
print("P2_SMOKE_STAGE bec_fallback before_only_status_text")
assert(json.load(libstore.compiled_status_text(only_name))["load_reason"] == "compiled_without_source")
print("P2_SMOKE_STAGE bec_fallback after_only_status_text")
expect_error(def () libstore.load_compiled(only_name) end, "unsupported_error")
print("P2_SMOKE_STAGE bec_fallback only_load_compiled_error")

var emit_source = "var becemit = module('becemit')\n"
emit_source += "becemit.answer = 42\n"
emit_source += "return becemit\n"
var esf = open(emit_source_path, "w")
esf.write(emit_source)
esf.close()
var missing_name = "becmiss"
print("P2_SMOKE_STAGE bec_fallback emit_source_written")

print("P2_SMOKE_STAGE bec_fallback before_emit_plan")
var emit_plan = libstore.compile_cache_plan(emit_name)
print("P2_SMOKE_STAGE bec_fallback after_emit_plan")
assert(emit_plan["source_exists"])
assert(emit_plan["target_path"] == emit_compiled_path)
assert(emit_plan["manifest_target_path"] == emit_manifest_path)
assert(emit_plan["can_emit"] == false)
assert(emit_plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
print("P2_SMOKE_STAGE bec_fallback emit_plan_asserts")
print("P2_SMOKE_STAGE bec_fallback before_emit_plan_many")
var emit_plan_many = libstore.compile_cache_plan_many([emit_name, only_name, missing_name])
print("P2_SMOKE_STAGE bec_fallback after_emit_plan_many")
assert(emit_plan_many["requested"] == 3)
assert(size(emit_plan_many["items"]) == 3)
assert(type(emit_plan_many["can_emit"]) == "int")
assert(type(emit_plan_many["blocked"]) == "int")
assert(type(emit_plan_many["reasons"]) == "map")
assert(emit_plan_many["can_emit"] + emit_plan_many["blocked"] == 3)
var emit_reason_total = 0
for reason : emit_plan_many["reasons"].keys()
    assert(type(reason) == "string")
    assert(type(emit_plan_many["reasons"][reason]) == "int")
    emit_reason_total += emit_plan_many["reasons"][reason]
end
assert(emit_reason_total == emit_plan_many["requested"])
print("P2_SMOKE_STAGE bec_fallback emit_plan_many_basic")

emit_plan = libstore.compile_cache_plan(emit_name)
assert(emit_plan["supported"] == false)
assert(emit_plan["can_emit"] == false)
assert(emit_plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
assert(!os.path.exists(emit_compiled_path))
assert(!os.path.exists(emit_manifest_path))
print("P2_SMOKE_STAGE bec_fallback emit_blocked")

try
    os.remove(source_path)
except .. as e, m
end
try
    os.remove(compiled_path)
except .. as e, m
end
try
    os.remove(manifest_path)
except .. as e, m
end
try
    os.remove(legacy_manifest_path)
except .. as e, m
end
try
    os.remove(only_path)
except .. as e, m
end
try
    os.remove(only_manifest_path)
except .. as e, m
end
try
    os.remove(only_legacy_manifest_path)
except .. as e, m
end
try
    os.remove(emit_source_path)
except .. as e, m
end
try
    os.remove(emit_compiled_path)
except .. as e, m
end
try
    os.remove(emit_manifest_path)
except .. as e, m
end
try
    os.remove(emit_legacy_manifest_path)
except .. as e, m
end

print("P2_SMOKE_PASS bec_fallback")
