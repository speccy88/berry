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

var name = "p1_bec_fallback"
var source_path = "/berry/lib/p1_bec_fallback.be"
var compiled_path = "/berry/cache/p1_bec_fallback.bec"
var manifest_path = "/berry/cache/p1_bec_fallback.bec.json"

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

var cf = open(compiled_path, "w")
cf.write("dummy unsupported bytecode")
cf.close()
var compiled_text = "dummy unsupported bytecode"

var sf = open(source_path, "w")
sf.write("var p1_bec_fallback = module('p1_bec_fallback')\n")
sf.write("p1_bec_fallback.answer = 42\n")
sf.write("return p1_bec_fallback\n")
sf.close()

assert(libstore.source_path(name) == source_path)
assert(libstore.compiled_path(name) == compiled_path)
assert(libstore.compiled_exists(name))

var info = libstore.info(name)
assert(info["exists"])
assert(info["compiled_exists"])
assert(info["compiled_path"] == compiled_path)
assert(info["compiled_size"] == size(compiled_text))
assert(info["compiled_hash"] == libstore.hash_text(compiled_text))
assert(info["compiled_manifest_path"] == nil)
assert(info["compiled_manifest_exists"] == false)
assert(info["compiled_manifest_valid"] == false)
assert(info["compiled_fresh"] == false)
assert(info["compiled_usable"] == false)
assert(info["compiled_freshness_reason"] == "bytecode_freshness_manifest_unavailable")
assert(info["compiled_supported"] == false)
assert(info["compile_cache_supported"] == false)
assert(info["compile_cache_can_emit"] == false)
assert(info["compile_cache_reason"] == "bytecode_emit_unavailable")
assert(info["compile_cache_blocked_reason"] == "bytecode_emit_unavailable")
assert(info["compile_cache_target_path"] == compiled_path)
assert(info["compile_cache_manifest_target_path"] == manifest_path)
assert(info["compile_cache_manifest_format"] == libstore.MANIFEST_FORMAT)
assert(info["compile_cache_manifest_template_available"])
assert(info["compile_cache_manifest_template_reason"] == "ok")
assert(info["source_fallback"] == true)
assert(info["selected_path"] == source_path)
assert(info["selected_kind"] == "source")
assert(info["resolve_reason"] == "compiled_unsupported_source_fallback")
var source_stats = libstore.source_stats(name)
assert(source_stats["exists"])
assert(source_stats["path"] == source_path)
assert(source_stats["size"] == info["source_size"])
assert(source_stats["hash"] == info["source_hash"])
var compiled_stats = libstore.compiled_stats(name)
assert(compiled_stats["exists"])
assert(compiled_stats["path"] == compiled_path)
assert(compiled_stats["size"] == info["compiled_size"])
assert(compiled_stats["hash"] == info["compiled_hash"])

var resolved = libstore.resolve(name)
assert(resolved["source_path"] == source_path)
assert(resolved["compiled_path"] == compiled_path)
assert(resolved["compiled_size"] == size(compiled_text))
assert(resolved["compiled_hash"] == libstore.hash_text(compiled_text))
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

var plan = libstore.compile_cache_plan(name)
assert(plan["supported"] == false)
assert(plan["can_emit"] == false)
assert(plan["reason"] == "bytecode_emit_unavailable")
assert(plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
assert(plan["manifest_format"] == libstore.MANIFEST_FORMAT)
assert(plan["manifest_required"])
assert(plan["validator_required"])
assert(plan["execution_required"])
assert(plan["manifest_template_available"])
assert(plan["manifest_template_reason"] == "ok")
assert(type(plan["manifest_template"]) == "map")
assert(plan["manifest_template"]["format"] == libstore.MANIFEST_FORMAT)
assert(plan["manifest_template"]["module"] == name)
assert(plan["manifest_template"]["source_hash"] == info["source_hash"])
assert(plan["manifest_template"]["compiled_hash"] == libstore.hash_text(compiled_text))
var manifest_text = libstore.compiled_manifest_text(name)
assert(type(manifest_text) == "string")
var manifest_text_data = json.load(manifest_text)
assert(manifest_text_data["format"] == libstore.MANIFEST_FORMAT)
assert(manifest_text_data["module"] == name)
assert(manifest_text_data["source_hash"] == info["source_hash"])
assert(manifest_text_data["compiled_hash"] == libstore.hash_text(compiled_text))
assert(plan["target_path"] == compiled_path)
assert(plan["manifest_target_path"] == manifest_path)
assert(plan["source_path"] == source_path)
assert(plan["source_exists"])
assert(plan["source_size"] == info["source_size"])
assert(plan["source_hash"] == info["source_hash"])
assert(plan["compiled_path"] == compiled_path)
assert(plan["compiled_exists"])
assert(plan["compiled_size"] == size(compiled_text))
assert(plan["compiled_hash"] == libstore.hash_text(compiled_text))
assert(plan["manifest_path"] == nil)
assert(plan["manifest_exists"] == false)
assert(plan["manifest_valid"] == false)
assert(plan["selected_path"] == source_path)
assert(plan["selected_kind"] == "source")
assert(plan["resolve_reason"] == "compiled_unsupported_source_fallback")

var fresh = libstore.compiled_freshness(name)
assert(fresh["fresh"] == false)
assert(fresh["usable"] == false)
assert(fresh["comparable"] == false)
assert(fresh["reason"] == "bytecode_freshness_manifest_unavailable")
assert(fresh["source_path"] == source_path)
assert(fresh["compiled_path"] == compiled_path)
assert(fresh["manifest_path"] == nil)
assert(fresh["manifest_exists"] == false)
assert(fresh["manifest_valid"] == false)
assert(fresh["source_hash"] == info["source_hash"])
assert(fresh["compiled_hash"] == libstore.hash_text(compiled_text))

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
assert(fresh["manifest_path"] == manifest_path)
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"])
assert(fresh["comparable"])
assert(fresh["fresh"])
assert(fresh["usable"] == bytecode_execution["supported"])
assert(fresh["reason"] == (bytecode_execution["supported"] ? "fresh" : "compiled_execution_unavailable"))
var validation = libstore.compiled_validation(name)
assert(validation["fresh"])
assert(validation["comparable"])
assert(validation["supported"] == bytecode_execution["validator_supported"])
assert(validation["valid"] == (bytecode_execution["validator_supported"] && validation["fresh"]))
assert(validation["reason"] == (bytecode_execution["validator_supported"] ? "ok" : "bytecode_validator_unavailable"))
var load_plan = libstore.compiled_load_plan(name)
assert(load_plan["compiled_exists"])
assert(load_plan["fresh"])
assert(load_plan["usable"] == bytecode_execution["supported"])
assert(load_plan["validation_valid"] == validation["valid"])
assert(load_plan["can_load"] == (bytecode_execution["supported"] && validation["valid"]))
assert(load_plan["reason"] == (load_plan["can_load"] ? "ok" : validation["reason"]))
var status = libstore.compiled_status(name)
assert(status["compiled_exists"])
assert(status["manifest_exists"])
assert(status["manifest_valid"])
assert(status["fresh"])
assert(status["comparable"])
assert(status["usable"] == bytecode_execution["supported"])
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
if !load_plan["can_load"] {
    expect_error(def () libstore.load_compiled(name) end, "unsupported_error")
}

info = libstore.info(name)
assert(info["compiled_manifest_path"] == manifest_path)
assert(info["compiled_manifest_exists"])
assert(info["compiled_manifest_valid"])
assert(info["compiled_fresh"])
assert(info["compiled_usable"] == bytecode_execution["supported"])
assert(info["compiled_freshness_reason"] == (bytecode_execution["supported"] ? "fresh" : "compiled_execution_unavailable"))
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
assert(info["compiled_blocked_reason"] == (bytecode_execution["supported"] ? nil : "compiled_execution_unavailable"))
assert(info["source_fallback"] == !bytecode_execution["supported"])

resolved = libstore.resolve(name)
assert(resolved["compiled_fresh"])
assert(resolved["compiled_usable"] == bytecode_execution["supported"])
assert(resolved["compiled_preferred"])
assert(resolved["compiled_blocked_reason"] == (bytecode_execution["supported"] ? nil : "compiled_execution_unavailable"))
assert(resolved["selected_path"] == (bytecode_execution["supported"] ? compiled_path : source_path))
assert(resolved["selected_kind"] == (bytecode_execution["supported"] ? "compiled" : "source"))

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

var loaded = libstore.load(name)
assert(loaded.answer == 42)

import p1_bec_fallback
assert(p1_bec_fallback.answer == 42)

var mem = p2mem.module(name)
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

var only_name = "p1_bec_only"
var only_path = "/berry/cache/p1_bec_only.bec"
var only_manifest_path = "/berry/cache/p1_bec_only.bec.json"
var only_text = "dummy bytecode without source"
var emit_name = "p1_bec_emit"
var emit_source_path = "/berry/lib/p1_bec_emit.be"
var emit_compiled_path = "/berry/cache/p1_bec_emit.bec"
var emit_manifest_path = "/berry/cache/p1_bec_emit.bec.json"

try
    os.remove(only_path)
except .. as e, m
end
try
    os.remove(only_manifest_path)
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

var of = open(only_path, "w")
of.write(only_text)
of.close()

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

var only_plan = libstore.compile_cache_plan(only_name)
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
assert(libstore.compiled_manifest_text(only_name) == nil)
assert(only_plan["target_path"] == only_path)
assert(only_plan["manifest_target_path"] == only_manifest_path)
assert(only_plan["source_exists"] == false)
assert(only_plan["compiled_exists"] == true)
assert(only_plan["compiled_hash"] == libstore.hash_text(only_text))

var only_fresh = libstore.compiled_freshness(only_name)
assert(only_fresh["usable"] == false)
assert(only_fresh["fresh"] == false)
assert(only_fresh["reason"] == "compiled_without_source")
var only_load_plan = libstore.compiled_load_plan(only_name)
assert(only_load_plan["compiled_exists"])
assert(only_load_plan["can_load"] == false)
assert(only_load_plan["reason"] == "compiled_without_source")
var only_status = libstore.compiled_status(only_name)
assert(only_status["compiled_exists"])
assert(only_status["source_exists"] == false)
assert(only_status["can_load"] == false)
assert(only_status["load_reason"] == "compiled_without_source")
assert(json.load(libstore.compiled_status_text(only_name))["load_reason"] == "compiled_without_source")
expect_error(def () libstore.load_compiled(only_name) end, "unsupported_error")

var emit_source = "var p1_bec_emit = module('p1_bec_emit')\n"
emit_source += "p1_bec_emit.answer = 42\n"
emit_source += "return p1_bec_emit\n"
var esf = open(emit_source_path, "w")
esf.write(emit_source)
esf.close()

var emit_plan = libstore.compile_cache_plan(emit_name)
assert(emit_plan["source_exists"])
assert(emit_plan["target_path"] == emit_compiled_path)
assert(emit_plan["manifest_target_path"] == emit_manifest_path)
assert(emit_plan["can_emit"] == false)
assert(emit_plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
var emit_plan_many = libstore.compile_cache_plan_many([emit_name, only_name, missing_name])
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
var emit_plan_many_text = libstore.compile_cache_plan_many_text([emit_name, only_name, missing_name])
assert(type(emit_plan_many_text) == "string")
var emit_plan_many_data = json.load(emit_plan_many_text)
assert(emit_plan_many_data["requested"] == emit_plan_many["requested"])
assert(size(emit_plan_many_data["items"]) == size(emit_plan_many["items"]))
assert(emit_plan_many_data["can_emit"] == emit_plan_many["can_emit"])
assert(emit_plan_many_data["blocked"] == emit_plan_many["blocked"])
assert(type(emit_plan_many_data["reasons"]) == "map")
var emit_provision = libstore.compile_cache_provision_plan([emit_name, only_name, missing_name])
assert(emit_provision["ok"])
assert(emit_provision["requested"] == emit_plan_many["requested"])
assert(emit_provision["can_emit"] == emit_plan_many["can_emit"])
assert(emit_provision["blocked"] == emit_plan_many["blocked"])
assert(type(emit_provision["recommendation"]) == "string")
assert(emit_provision["default_source_fallback"] == (emit_provision["can_emit"] == 0))
var emit_provision_data = json.load(libstore.compile_cache_provision_plan_text([emit_name, only_name, missing_name]))
assert(emit_provision_data["ok"])
assert(emit_provision_data["recommendation"] == emit_provision["recommendation"])
assert(emit_provision_data["requested"] == emit_provision["requested"])
assert(emit_provision_data["can_emit"] == emit_provision["can_emit"])
assert(emit_provision_data["blocked"] == emit_provision["blocked"])
var emit_candidates = libstore.compile_cache_emittable([emit_name, only_name, missing_name])
var emit_blocked = libstore.compile_cache_blocked([emit_name, only_name, missing_name])
var emit_candidates_data = json.load(libstore.compile_cache_emittable_text([emit_name, only_name, missing_name]))
var emit_blocked_data = json.load(libstore.compile_cache_blocked_text([emit_name, only_name, missing_name]))
assert(size(emit_candidates) == emit_plan_many["can_emit"])
assert(size(emit_blocked) == emit_plan_many["blocked"])
assert(size(emit_candidates_data) == size(emit_candidates))
assert(size(emit_blocked_data) == size(emit_blocked))
for item : emit_candidates
    assert(item["can_emit"])
end
for item : emit_blocked
    assert(!item["can_emit"])
end

var probe = libstore.compile_cache_probe()
assert(type(probe) == "map")
assert(type(probe["supported"]) == "bool")
assert(type(probe["reason"]) == "string")

emit_plan = libstore.compile_cache_plan(emit_name)
var emit_many = libstore.compile_cache_emit_many([emit_name])
assert(emit_many["requested"] == 1)
assert(size(emit_many["items"]) == 1)
if probe["supported"] {
    assert(emit_many["ok_count"] == 1)
    assert(emit_many["fail_count"] == 0)
    assert(emit_many["items"][0]["ok"])
    assert(emit_plan["supported"])
    assert(emit_plan["can_emit"])
    assert(emit_plan["emit_blocked_reason"] == nil)
    var emitted = libstore.compile_cache_emit(emit_name)
    assert(emitted["ok"])
    assert(emitted["compiled_path"] == emit_compiled_path)
    assert(emitted["manifest_path"] == emit_manifest_path)
    assert(emitted["compiled_size"] > 0)
    assert(type(emitted["compiled_hash"]) == "int")
    assert(emitted["manifest_valid"])
    assert(emitted["fresh"])
    assert(emitted["usable"] == bytecode_execution["supported"])
    assert(emitted["reason"] == (bytecode_execution["supported"] ? "fresh" : "compiled_execution_unavailable"))
    assert(os.path.exists(emit_compiled_path))
    assert(os.path.exists(emit_manifest_path))
    var emit_manifest = libstore.compiled_manifest(emit_name)
    assert(emit_manifest["valid"])
    assert(emit_manifest["data"]["module"] == emit_name)
} else {
    assert(emit_many["ok_count"] == 0)
    assert(emit_many["fail_count"] == 1)
    assert(emit_many["items"][0]["ok"] == false)
    assert(emit_many["items"][0]["reason"] == "bytecode_emit_unavailable")
    assert(emit_plan["supported"] == false)
    assert(emit_plan["can_emit"] == false)
    assert(emit_plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
    expect_error(def () libstore.compile_cache_emit(emit_name) end, "unsupported_error")
    assert(!os.path.exists(emit_compiled_path))
    assert(!os.path.exists(emit_manifest_path))
}

var missing_name = "p1_bec_missing"
var missing_resolved = libstore.resolve(missing_name)
assert(missing_resolved["source_exists"] == false)
assert(missing_resolved["compiled_exists"] == false)
assert(missing_resolved["selected_path"] == nil)
assert(missing_resolved["selected_kind"] == nil)
assert(missing_resolved["reason"] == "missing")

var missing_plan = libstore.compile_cache_plan(missing_name)
assert(missing_plan["can_emit"] == false)
assert(missing_plan["reason"] == "source_missing")
assert(missing_plan["emit_blocked_reason"] == "source_missing")
assert(missing_plan["manifest_format"] == libstore.MANIFEST_FORMAT)
assert(missing_plan["manifest_template_available"] == false)
assert(missing_plan["manifest_template_reason"] == "source_missing")
assert(missing_plan["manifest_template"] == nil)
assert(libstore.compiled_manifest_text(missing_name) == nil)
assert(missing_plan["source_exists"] == false)
assert(missing_plan["compiled_exists"] == false)

var missing_fresh = libstore.compiled_freshness(missing_name)
assert(missing_fresh["usable"] == false)
assert(missing_fresh["fresh"] == false)
assert(missing_fresh["reason"] == "missing")
var missing_load_plan = libstore.compiled_load_plan(missing_name)
assert(missing_load_plan["compiled_exists"] == false)
assert(missing_load_plan["can_load"] == false)
assert(missing_load_plan["reason"] == "missing")
var missing_status = libstore.compiled_status(missing_name)
assert(missing_status["source_exists"] == false)
assert(missing_status["compiled_exists"] == false)
assert(missing_status["can_load"] == false)
assert(missing_status["load_reason"] == "missing")
assert(json.load(libstore.compiled_status_text(missing_name))["load_reason"] == "missing")
expect_error(def () libstore.load_compiled(missing_name) end, "unsupported_error")

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
    os.remove(only_path)
except .. as e, m
end
try
    os.remove(only_manifest_path)
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

print("P2_SMOKE_PASS bec_fallback")
