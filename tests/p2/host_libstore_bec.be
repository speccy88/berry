# Host-side regression for libstore .bec metadata and source fallback.
#
# The desktop VM cannot execute P2 bytecode cache files, but it can still verify
# manifest generation, freshness checks, planning, and fallback decisions.

import introspect
import os
import json

var p2 = module("p2")
p2.psram_info = def()
    return {
        "available": false,
        "bytes": 0,
        "access": "none",
        "max_transfer": 0,
        "heap": false
    }
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
introspect.setmodule("p2", p2)

var libstore = run_file("modules/libstore.be")

var root = "tmp/p2_host_bec"
var lib_dir = root + "/lib"
var cache_dir = root + "/cache"
libstore.paths = [lib_dir]
libstore.compiled_paths = [cache_dir]
libstore.compile_cache_probe_path = cache_dir + "/.libstore_emit_probe.bec"

def remove_quiet(path)
    try
        os.remove(path)
    except .. as e, m
    end
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

libstore._ensure_dir(lib_dir)
libstore._ensure_dir(cache_dir)

var name = "host_bec_mod"
var missing_name = "host_bec_missing"
var only_name = "host_bec_only"
var source_path = lib_dir + "/host_bec_mod.be"
var compiled_path = cache_dir + "/host_bec_mod.bec"
var manifest_path = cache_dir + "/host_bec_mod.bec.json"
var only_path = cache_dir + "/host_bec_only.bec"
var only_manifest_path = cache_dir + "/host_bec_only.bec.json"

remove_quiet(source_path)
remove_quiet(compiled_path)
remove_quiet(manifest_path)
remove_quiet(only_path)
remove_quiet(only_manifest_path)

assert(libstore.valid_module_name("host_bec_mod"))
assert(libstore.valid_module_name("host_bec_pkg.mod"))
assert(libstore.module_file("host_bec_pkg.mod", ".be") == "host_bec_pkg/mod.be")
assert(!libstore.valid_module_name(nil))
assert(!libstore.valid_module_name(""))
assert(!libstore.valid_module_name("../host_bec_escape"))
assert(!libstore.valid_module_name("host/bec_escape"))
assert(!libstore.valid_module_name("host_bec_pkg..mod"))
expect_error(def() return libstore.module_file("../host_bec_escape", ".be") end, "value_error")
assert(libstore.source_path("../host_bec_escape") == nil)
assert(libstore.compiled_path("../host_bec_escape") == nil)
assert(libstore.compiled_candidate_path("../host_bec_escape") == nil)
assert(libstore.compiled_manifest_candidate_path("../host_bec_escape") == nil)
assert(libstore.compiled_manifest("../host_bec_escape")["reason"] == "invalid_module_name")
assert(libstore.compiled_manifest_text("../host_bec_escape") == nil)
var invalid_fresh = libstore.compiled_freshness("../host_bec_escape")
assert(invalid_fresh["reason"] == "invalid_module_name")
assert(invalid_fresh["manifest_reason"] == "invalid_module_name")
var invalid_validation = libstore.compiled_validation("../host_bec_escape")
assert(invalid_validation["reason"] == "invalid_module_name")
var invalid_load_plan = libstore.compiled_load_plan("../host_bec_escape")
assert(invalid_load_plan["can_load"] == false)
assert(invalid_load_plan["reason"] == "invalid_module_name")
expect_error(def() return libstore.load_compiled("../host_bec_escape") end, "unsupported_error")
var invalid_resolved = libstore.resolve("../host_bec_escape")
assert(invalid_resolved["source_exists"] == false)
assert(invalid_resolved["compiled_exists"] == false)
assert(invalid_resolved["compiled_freshness_reason"] == "invalid_module_name")
assert(invalid_resolved["compiled_blocked_reason"] == "invalid_module_name")
assert(invalid_resolved["selected_path"] == nil)
assert(invalid_resolved["selected_kind"] == nil)
assert(invalid_resolved["reason"] == "invalid_module_name")
var invalid_plan = libstore.compile_cache_plan("../host_bec_escape")
assert(invalid_plan["can_emit"] == false)
assert(invalid_plan["reason"] == "invalid_module_name")
assert(invalid_plan["emit_blocked_reason"] == "invalid_module_name")
assert(invalid_plan["target_path"] == nil)
assert(invalid_plan["manifest_target_path"] == nil)
assert(invalid_plan["manifest_template_available"] == false)
assert(invalid_plan["manifest_template_reason"] == "invalid_module_name")
expect_error(def() return libstore.compile_cache_emit("../host_bec_escape") end, "value_error")

var source_text = "var host_bec_mod = module('host_bec_mod')\n"
source_text += "host_bec_mod.answer = 42\n"
source_text += "return host_bec_mod\n"
var sf = open(source_path, "w")
sf.write(source_text)
sf.close()

var compiled_text = "dummy unsupported bytecode"
var cf = open(compiled_path, "w")
cf.write(compiled_text)
cf.close()

assert(libstore.source_path(name) == source_path)
assert(libstore.compiled_path(name) == compiled_path)

var execution = libstore.compiled_execution_probe()
assert(execution["supported"] == false)
assert(execution["loader_supported"] == false)
assert(execution["validator_supported"] == false)
assert(execution["reason"] == "bytecode_loader_unavailable")

var info = libstore.info(name)
assert(info["exists"])
assert(info["compiled_exists"])
assert(info["compiled_manifest_exists"] == false)
assert(info["compiled_fresh"] == false)
assert(info["compiled_usable"] == false)
assert(info["compiled_freshness_reason"] == "bytecode_freshness_manifest_unavailable")
assert(info["compile_cache_can_emit"] == false)
assert(info["compile_cache_blocked_reason"] == "bytecode_emit_unavailable")
assert(info["source_fallback"])
assert(info["selected_path"] == source_path)
assert(info["selected_kind"] == "source")
assert(info["resolve_reason"] == "compiled_unsupported_source_fallback")

var plan = libstore.compile_cache_plan(name)
assert(plan["supported"] == false)
assert(plan["can_emit"] == false)
assert(plan["reason"] == "bytecode_emit_unavailable")
assert(plan["emit_blocked_reason"] == "bytecode_emit_unavailable")
assert(plan["manifest_template_available"])
assert(plan["manifest_template_reason"] == "ok")
assert(plan["target_path"] == compiled_path)
assert(plan["manifest_target_path"] == manifest_path)
assert(plan["source_path"] == source_path)
assert(plan["compiled_path"] == compiled_path)
assert(plan["selected_kind"] == "source")

var manifest_text = libstore.compiled_manifest_text(name)
assert(type(manifest_text) == "string")
var manifest_data = json.load(manifest_text)
assert(manifest_data["format"] == libstore.MANIFEST_FORMAT)
assert(manifest_data["module"] == name)
assert(manifest_data["source_hash"] == libstore.hash_text(source_text))
assert(manifest_data["compiled_hash"] == libstore.hash_text(compiled_text))

var mf = open(manifest_path, "w")
mf.write(manifest_text)
mf.close()

var manifest = libstore.compiled_manifest(name)
assert(manifest["exists"])
assert(manifest["valid"])
assert(manifest["reason"] == "ok")

var fresh = libstore.compiled_freshness(name)
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"])
assert(fresh["comparable"])
assert(fresh["fresh"])
assert(fresh["usable"] == false)
assert(fresh["reason"] == "compiled_execution_unavailable")

var validation = libstore.compiled_validation(name)
assert(validation["fresh"])
assert(validation["valid"] == false)
assert(validation["reason"] == "bytecode_validator_unavailable")

var load_plan = libstore.compiled_load_plan(name)
assert(load_plan["compiled_exists"])
assert(load_plan["fresh"])
assert(load_plan["can_load"] == false)
assert(load_plan["reason"] == "bytecode_validator_unavailable")
expect_error(def() return libstore.load_compiled(name) end, "unsupported_error")

var resolved = libstore.resolve(name)
assert(resolved["compiled_preferred"])
assert(resolved["compiled_blocked_reason"] == "compiled_execution_unavailable")
assert(resolved["selected_path"] == source_path)
assert(resolved["selected_kind"] == "source")
assert(resolved["reason"] == "compiled_unsupported_source_fallback")
assert(libstore.load(name).answer == 42)

mf = open(manifest_path, "w")
mf.write(json.dump({
    "format": libstore.MANIFEST_FORMAT,
    "module": name,
    "source_size": size(source_text),
    "source_hash": libstore.hash_text(source_text) + 1,
    "compiled_size": size(compiled_text),
    "compiled_hash": libstore.hash_text(compiled_text)
}))
mf.close()

fresh = libstore.compiled_freshness(name)
assert(fresh["manifest_valid"])
assert(fresh["fresh"] == false)
assert(fresh["usable"] == false)
assert(fresh["reason"] == "stale_manifest")
resolved = libstore.resolve(name)
assert(resolved["compiled_preferred"] == false)
assert(resolved["compiled_blocked_reason"] == "stale_manifest")
assert(resolved["selected_path"] == source_path)

var only_text = "dummy bytecode without source"
var of = open(only_path, "w")
of.write(only_text)
of.close()

var only_resolved = libstore.resolve(only_name)
assert(only_resolved["source_exists"] == false)
assert(only_resolved["compiled_exists"])
assert(only_resolved["compiled_freshness_reason"] == "compiled_without_source")
assert(only_resolved["selected_path"] == nil)
assert(only_resolved["selected_kind"] == nil)
assert(only_resolved["reason"] == "compiled_unsupported_no_source")

var only_plan = libstore.compile_cache_plan(only_name)
assert(only_plan["can_emit"] == false)
assert(only_plan["reason"] == "source_missing")
assert(only_plan["emit_blocked_reason"] == "source_missing")
assert(only_plan["manifest_template_available"] == false)
assert(only_plan["manifest_template_reason"] == "source_missing")
assert(libstore.compiled_manifest_text(only_name) == nil)
expect_error(def() return libstore.load_compiled(only_name) end, "unsupported_error")

var missing_resolved = libstore.resolve(missing_name)
assert(missing_resolved["source_exists"] == false)
assert(missing_resolved["compiled_exists"] == false)
assert(missing_resolved["selected_path"] == nil)
assert(missing_resolved["selected_kind"] == nil)
assert(missing_resolved["reason"] == "missing")

var many = libstore.compile_cache_plan_many([name, only_name, missing_name])
assert(many["requested"] == 3)
assert(size(many["items"]) == 3)
assert(many["can_emit"] == 0)
assert(many["blocked"] == 3)
assert(many["reasons"]["bytecode_emit_unavailable"] == 1)
assert(many["reasons"]["source_missing"] == 2)
assert(json.load(libstore.compile_cache_plan_many_text([name, only_name, missing_name]))["requested"] == 3)

var invalid_many = libstore.compile_cache_plan_many([name, "../host_bec_escape"])
assert(invalid_many["requested"] == 2)
assert(invalid_many["can_emit"] == 0)
assert(invalid_many["blocked"] == 2)
assert(invalid_many["reasons"]["bytecode_emit_unavailable"] == 1)
assert(invalid_many["reasons"]["invalid_module_name"] == 1)
assert(json.load(libstore.compile_cache_plan_many_text([name, "../host_bec_escape"]))["reasons"]["invalid_module_name"] == 1)

var provision = libstore.compile_cache_provision_plan([name, only_name, missing_name])
assert(provision["ok"])
assert(provision["recommendation"] == "source_fallback")
assert(provision["default_source_fallback"])
assert(size(libstore.compile_cache_emittable([name, only_name, missing_name])) == 0)
assert(size(libstore.compile_cache_blocked([name, only_name, missing_name])) == 3)

var summary = libstore.compiled_summary()
assert(summary["modules"] == 1)
assert(summary["source_exists"] == 1)
assert(summary["compiled_exists"] == 1)
assert(summary["can_load"] == 0)
assert(summary["can_emit"] == 0)

remove_quiet(source_path)
remove_quiet(compiled_path)
remove_quiet(manifest_path)
remove_quiet(only_path)
remove_quiet(only_manifest_path)
remove_quiet(cache_dir)
remove_quiet(lib_dir)
remove_quiet(root)
remove_quiet("tmp")
