# Host-side regression for SD-style module roots and import cache behavior.
#
# This uses temporary file-backed module roots with the desktop importer. It
# covers the parts of the P2 SD import contract that do not require hardware.

import introspect
import os
import sys

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
var lib_caps = libstore.capabilities()
assert(lib_caps["lazy_sd_source"])
assert(lib_caps["path_list"])
assert(lib_caps["path_add_remove"])
assert(lib_caps["coverage_metadata"])
assert(lib_caps["inventory"])
assert(lib_caps["info"])
assert(lib_caps["source_stats"])
assert(lib_caps["compiled_stats"])
assert(lib_caps["compiled_manifest"])
assert(lib_caps["compiled_fallback"])
assert(lib_caps["compile_cache_planning"])
assert(lib_caps["psram_source_cache"])
assert(lib_caps["policy_diagnostics"])
assert(lib_caps["status_diagnostics"])
assert(lib_caps["app_paths"])
assert(lib_caps["example_paths"])
assert(lib_caps["pasm_paths"])
assert(lib_caps["valid_module_name"])
assert(lib_caps["audit"])
assert(lib_caps["audit_policy"] == "metadata_only_no_sd_scan_or_cache_mutation")
lib_caps["coverage_metadata"] = false
assert(libstore.capabilities()["coverage_metadata"])
assert(type(libstore.required_capability_keys) == "function")
var lib_required_caps = libstore.required_capability_keys()
assert(lib_required_caps.find("lazy_sd_source") >= 0)
assert(lib_required_caps.find("audit_policy") >= 0)
lib_required_caps.push("__host_libstore_required_mutation_probe__")
assert(libstore.required_capability_keys().find("__host_libstore_required_mutation_probe__") == nil)
assert(libstore.capability("coverage_metadata"))
assert(libstore.capability("missing") == nil)
assert(libstore.capability(nil) == nil)
var lib_audit = libstore.audit()
assert(lib_audit["ok"])
assert(lib_audit["problem_count"] == 0)
assert(lib_audit["problems"].size() == 0)
assert(lib_audit["missing_capability_keys"].size() == 0)
assert(lib_audit["audit_policy"] == "metadata_only_no_sd_scan_or_cache_mutation")
assert(lib_audit["known_count"] == 10)
assert(lib_audit["coverage_count"] >= lib_audit["known_count"])
assert(lib_audit["covered_count"] == 9)
assert(lib_audit["hardware_deferred_count"] == 1)
assert(lib_audit["unknown_coverage_count"] == 0)
assert(lib_audit["lazy_sd_source"])
assert(lib_audit["coverage_metadata"])
assert(lib_audit["compiled_fallback"])
assert(lib_audit["psram_source_cache"])
lib_audit["problems"].push("__host_libstore_audit_problem_mutation_probe__")
assert(libstore.audit_problems().size() == 0)
assert(libstore.audit_ok())

var root = "tmp/p2_host_import"
var modules_dir = root + "/modules"
var lib_dir = root + "/lib"
var app_dir = root + "/app"
var pkg_dir = lib_dir + "/host_import_pkg"
var extra_dir = root + "/extra"

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

def list_has(items, value)
    for item : items
        if item == value
            return true
        end
    end
    return false
end

def inventory_has(items, name)
    for item : items
        if item["name"] == name
            return true
        end
    end
    return false
end

remove_quiet(modules_dir + "/host_import_order.be")
remove_quiet(lib_dir + "/host_import_order.be")
remove_quiet(app_dir + "/host_import_app.be")
remove_quiet(pkg_dir + "/mod.be")
remove_quiet(extra_dir + "/host_import_extra.be")
remove_quiet(modules_dir + "/host_import_recovered.be")

libstore._ensure_dir(modules_dir)
libstore._ensure_dir(lib_dir)
libstore._ensure_dir(app_dir)
libstore._ensure_dir(pkg_dir)
libstore._ensure_dir(extra_dir)

libstore.paths = [modules_dir, lib_dir, app_dir]
libstore.app_paths = [app_dir]
libstore.compiled_paths = [root + "/cache"]
assert(sys.path_add(app_dir))
assert(sys.path_add(lib_dir))
assert(sys.path_add(modules_dir))

write_text(modules_dir + "/host_import_order.be",
    "var host_import_order = module('host_import_order')\n" +
    "host_import_order.origin = 'modules'\n" +
    "return host_import_order\n")
write_text(lib_dir + "/host_import_order.be",
    "var host_import_order = module('host_import_order')\n" +
    "host_import_order.origin = 'lib'\n" +
    "return host_import_order\n")
write_text(app_dir + "/host_import_app.be",
    "var host_import_app = module('host_import_app')\n" +
    "host_import_app.answer = 84\n" +
    "return host_import_app\n")
write_text(pkg_dir + "/mod.be",
    "var host_import_pkg_mod = module('host_import_pkg.mod')\n" +
    "host_import_pkg_mod.answer = 126\n" +
    "return host_import_pkg_mod\n")

assert(libstore.source_path("host_import_order") == modules_dir + "/host_import_order.be")
assert(libstore.source_path("host_import_app") == app_dir + "/host_import_app.be")
assert(libstore.source_path("host_import_pkg.mod") == pkg_dir + "/mod.be")
assert(libstore.info("host_import_order")["selected_path"] == modules_dir + "/host_import_order.be")

import host_import_order
assert(host_import_order.origin == "modules")
host_import_order.origin = "cached-modules"
import host_import_order as host_import_order_again
assert(host_import_order_again.origin == "cached-modules")

import host_import_app
assert(host_import_app.answer == 84)
host_import_app.answer = 85
import host_import_app as host_import_app_again
assert(host_import_app_again.answer == 85)

import "host_import_pkg.mod" as host_import_pkg_alias
assert(host_import_pkg_alias.answer == 126)
host_import_pkg_alias.answer = 127
import "host_import_pkg.mod" as host_import_pkg_alias_again
assert(host_import_pkg_alias_again.answer == 127)

var path_snapshot = libstore.path_list()
var before_extra = path_snapshot.size()
path_snapshot.push("__mutated__")
assert(libstore.path_list().size() == before_extra)
assert(libstore.path_add(extra_dir))
assert(!libstore.path_add(extra_dir))
assert(sys.path_add(extra_dir))
write_text(extra_dir + "/host_import_extra.be",
    "var host_import_extra = module('host_import_extra')\n" +
    "host_import_extra.answer = 168\n" +
    "return host_import_extra\n")
assert(libstore.source_path("host_import_extra") == extra_dir + "/host_import_extra.be")
import host_import_extra
assert(host_import_extra.answer == 168)

var missing_caught = false
try
    import host_import_recovered
except .. as e, m
    missing_caught = true
end
assert(missing_caught)
assert(libstore.source_path("host_import_recovered") == nil)

write_text(modules_dir + "/host_import_recovered.be",
    "var host_import_recovered = module('host_import_recovered')\n" +
    "host_import_recovered.answer = 210\n" +
    "return host_import_recovered\n")
assert(libstore.source_path("host_import_recovered") == modules_dir + "/host_import_recovered.be")
import host_import_recovered
assert(host_import_recovered.answer == 210)

var stats = libstore.source_stats("host_import_order")
assert(stats["exists"])
assert(stats["path"] == modules_dir + "/host_import_order.be")
assert(stats["size"] > 0)
assert(stats["hash"] == libstore.hash_text(open(stats["path"], "r").read()))
stats["path"] = "__mutated_source_stats__"
assert(libstore.source_stats("host_import_order")["path"] == modules_dir + "/host_import_order.be")

var info_snapshot = libstore.info("host_import_app")
assert(info_snapshot["exists"])
assert(info_snapshot["source_size"] > 0)
info_snapshot["path"] = "__mutated_info__"
info_snapshot["coverage_status"] = "__mutated_coverage__"
var info_again = libstore.info("host_import_app")
assert(info_again["path"] == app_dir + "/host_import_app.be")
assert(info_again["coverage_status"] != "__mutated_coverage__")

var scanned = libstore.modules()
assert(list_has(scanned, "host_import_order"))
assert(list_has(scanned, "host_import_app"))
assert(list_has(scanned, "host_import_extra"))

var inventory = libstore.inventory()
assert(inventory_has(inventory, "host_import_order"))
assert(inventory_has(inventory, "host_import_app"))
assert(inventory_has(inventory, "host_import_recovered"))
inventory[0]["name"] = "__mutated_inventory__"
assert(!inventory_has(libstore.inventory(), "__mutated_inventory__"))

assert(libstore.path_remove(extra_dir))
assert(!libstore.path_remove(extra_dir))
assert(libstore.source_path("host_import_extra") == nil)
assert(!list_has(libstore.modules(), "host_import_extra"))

remove_quiet(modules_dir + "/host_import_order.be")
remove_quiet(lib_dir + "/host_import_order.be")
remove_quiet(app_dir + "/host_import_app.be")
remove_quiet(pkg_dir + "/mod.be")
remove_quiet(extra_dir + "/host_import_extra.be")
remove_quiet(modules_dir + "/host_import_recovered.be")
remove_quiet(root + "/cache")
remove_quiet(pkg_dir)
remove_quiet(extra_dir)
remove_quiet(app_dir)
remove_quiet(lib_dir)
remove_quiet(modules_dir)
remove_quiet(root)
remove_quiet("tmp")
