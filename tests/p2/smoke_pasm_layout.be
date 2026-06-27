# P2_SD_WRITE_AUDIT max_write_opens=3
print("P2_SMOKE_BEGIN pasm_layout")

import os
import libstore
import p2
import string

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

def contains(list_value, wanted)
    return string.find(str(list_value), "'" + wanted + "'") >= 0
end

ensure_dir("/berry")
ensure_dir("/berry/pasm")

var path = "/berry/pasm/pasm_probe.bin"
var marker_path = "/berry/pasm/pasm_marker.bin"
var nested_dir = "/berry/pasm/pasm_probe_pkg"
print("P2_SMOKE_STAGE pasm_layout preflight")
var made_nested_dir = false
if !os.path.isdir(nested_dir)
    ensure_dir(nested_dir)
    made_nested_dir = true
end
var nested_path = nested_dir + "/probe.bin"

assert(!os.path.exists(path))
assert(!os.path.exists(marker_path))
assert(!os.path.exists(nested_path))

print("P2_SMOKE_STAGE pasm_layout write")
var f = open(path, "w")
f.write("PASM")
f.close()

var nf = open(nested_path, "w")
nf.write("nested-dummy-pasm")
nf.close()

var mf = open(marker_path, "w")
mf.write(p2.asm.marker_blob())
mf.close()

print("P2_SMOKE_STAGE pasm_layout paths")
assert(libstore.pasm_path("pasm_probe") == path)
assert(libstore.pasm_exists("pasm_probe"))
assert(libstore.pasm_path("pasm_probe_pkg.probe") == nested_path)
assert(libstore.pasm_exists("pasm_probe_pkg.probe"))
var pasm_policy = libstore.pasm_policy()
assert(pasm_policy["ok"])
assert(pasm_policy["storage_supported"])
assert(pasm_policy["storage_root"] == "/berry/pasm")
assert(pasm_policy["path_pattern"] == "/berry/pasm/*.bin")
assert(pasm_policy["nested_module_names"])
assert(pasm_policy["load_supported"])
assert(pasm_policy["load_result_helper"])
assert(!pasm_policy["executable"])
assert(!pasm_policy["execution_supported"])
assert(pasm_policy["execution_policy"] == "deferred_to_p2_asm_marker_fixture")
assert(pasm_policy["reason"] == "pasm_execution_deferred")
pasm_policy["storage_root"] = "mutated"
assert(libstore.pasm_policy()["storage_root"] == "/berry/pasm")

print("P2_SMOKE_STAGE pasm_layout load")
var info = libstore.pasm_info("pasm_probe")
assert(info["exists"])
assert(info["path"] == path)
assert(info["size"] == size("PASM"))
assert(info["hash"] == libstore.hash_text("PASM"))
assert(info["executable"] == false)
assert(info["reason"] == "pasm_execution_deferred")
assert(libstore.pasm_load("pasm_probe") == "PASM")

var loaded = libstore.pasm_load_result("pasm_probe")
assert(loaded["ok"])
assert(loaded["found"])
assert(loaded["path"] == path)
assert(loaded["data"] == "PASM")
assert(loaded["size"] == size("PASM"))
assert(loaded["hash"] == libstore.hash_text("PASM"))
assert(loaded["executable"] == false)
assert(loaded["reason"] == "pasm_execution_deferred")

var blob = p2.asm.load(path)
assert(isinstance(blob, bytes))
assert(blob.asstring() == "PASM")
assert(type(p2.asm.cognew) == "function")
assert(type(p2.asm.cogstop) == "function")
assert(type(p2.asm.cogcheck) == "function")
assert(type(p2.asm.capabilities) == "function")
assert(type(p2.asm.capability) == "function")
assert(type(p2.asm.required_capability_keys) == "function")
assert(type(p2.asm.abi) == "function")
assert(type(p2.asm.abi_value) == "function")
assert(type(p2.asm.required_abi_keys) == "function")
assert(type(p2.asm.audit) == "function")
assert(type(p2.asm.audit_problems) == "function")
assert(type(p2.asm.audit_ok) == "function")
assert(type(p2.asm.marker_blob) == "function")
assert(type(p2.asm.launch_probe) == "function")
assert(type(p2.asm.launch_loaded_probe) == "function")
var native_marker_blob = p2.asm.marker_blob()
assert(isinstance(native_marker_blob, bytes))
assert(size(native_marker_blob) > 0)
assert(size(native_marker_blob) % 4 == 0)
assert(native_marker_blob == p2.asm.marker_blob())
print("P2_SMOKE_SKIP pasm_layout negative_load_exceptions")

var caps = p2.asm.capabilities()
var required_caps = p2.asm.required_capability_keys()
assert(required_caps.find("raw_cognew_policy") >= 0)
assert(required_caps.find("unsupported_reason") >= 0)
required_caps.push("mutated")
assert(p2.asm.required_capability_keys().find("mutated") == nil)
assert(caps["safe_intrinsics"])
assert(caps["sd_load"])
assert(caps["raw_cognew"])
assert(caps["raw_cognew_policy"] == "low_level_existing_path_not_public_blob_abi")
assert(p2.asm.capability("raw_cognew_policy") == caps["raw_cognew_policy"])
assert(string.find(caps["raw_cognew_reason"], "low-level") >= 0)
assert(caps["marker_probe"])
assert(caps["sd_marker_probe"])
assert(caps["fixture_call"])
assert(caps["fixture_call_policy"] == "fixed_named_operation_fixture_mailbox_only")
assert(contains(caps["fixture_call_ops"], "add"))
assert(p2.asm.capability("fixture_call_policy") == caps["fixture_call_policy"])
assert(!caps["arbitrary_sd_launch_supported"])
assert(caps["arbitrary_blob_policy"] == "unsupported_exact_marker_fixture_only")
assert(p2.asm.capability("arbitrary_blob_policy") == caps["arbitrary_blob_policy"])
assert(string.find(caps["arbitrary_blob_reason"], "entry") >= 0)
assert(!caps["function_bridge"])
assert(caps["function_bridge_policy"] == "unsupported_no_calling_convention")
assert(p2.asm.capability("function_bridge_policy") == caps["function_bridge_policy"])
assert(string.find(caps["function_bridge_reason"], "argument marshalling") >= 0)
assert(!caps["inline_assembler"])
assert(caps["inline_assembler_policy"] == "unsupported_no_parser_or_safety_contract")
assert(string.find(caps["inline_assembler_reason"], "assembly parser") >= 0)
assert(!caps["unsafe_asm"])
assert(caps["unsafe_gate"] == "BE_P2_ENABLE_UNSAFE_ASM")
assert(caps["unsafe_default"] == false)
assert(caps["unsafe_module"] == "none")
assert(caps["launch_policy"] == "exact_marker_fixture_only")

var abi = p2.asm.abi()
var required_abi = p2.asm.required_abi_keys()
assert(required_abi.find("status") >= 0)
assert(required_abi.find("fixture_call_policy") >= 0)
assert(required_abi.find("arbitrary_blob_required") >= 0)
required_abi.push("mutated")
assert(p2.asm.required_abi_keys().find("mutated") == nil)
assert(abi["status"] == "marker_and_fixture_call_only")
assert(p2.asm.abi_value("status") == abi["status"])
assert(abi["raw_cognew_policy"] == "low_level_existing_path_not_public_blob_abi")
assert(abi["fixture_call_abi"])
assert(abi["fixture_call_policy"] == caps["fixture_call_policy"])
assert(contains(abi["fixture_call_ops"], "sub"))
assert(abi["arbitrary_blob_abi"] == false)
assert(abi["arbitrary_blob_policy"] == "unsupported_exact_marker_fixture_only")
assert(string.find(abi["arbitrary_blob_required"], "blob layout") >= 0)
assert(abi["function_bridge_abi"] == false)
assert(abi["function_bridge_policy"] == "unsupported_no_calling_convention")
assert(string.find(abi["function_bridge_required"], "return values") >= 0)
assert(abi["inline_assembler_abi"] == false)
assert(abi["inline_assembler_policy"] == "unsupported_no_parser_or_safety_contract")
assert(string.find(abi["inline_assembler_required"], "register clobbers") >= 0)
assert(abi["unsafe_gate"] == "BE_P2_ENABLE_UNSAFE_ASM")
assert(abi["unsafe_default"] == false)
assert(abi["unsafe_module"] == "none")
assert(abi["argument"] == "mailbox pointer in PTRA")

assert(p2.asm.audit_ok())
assert(p2.asm.audit_problems().size() == 0)
var audit_problems = p2.asm.audit_problems()
audit_problems.push("mutated")
assert(p2.asm.audit_problems().size() == 0)

var launch = p2.asm.launch_probe()
assert(launch["ok"])
assert(launch["marker_seen"])
assert(launch["cog_seen_matches"])
assert(launch["stopped"])
assert(launch["cog"] >= 0 && launch["cog"] < 8)
assert(p2.asm.cogcheck(launch["cog"]) == 0)

var marker_blob = p2.asm.load(marker_path)
assert(isinstance(marker_blob, bytes))
assert(size(marker_blob) == size(native_marker_blob))
assert(marker_blob == native_marker_blob)
var loaded_launch = p2.asm.launch_loaded_probe(marker_blob)
assert(loaded_launch["ok"])
assert(loaded_launch["marker_seen"])
assert(loaded_launch["cog_seen_matches"])
assert(loaded_launch["stopped"])
assert(loaded_launch["cog"] >= 0 && loaded_launch["cog"] < 8)
assert(p2.asm.cogcheck(loaded_launch["cog"]) == 0)

print("P2_SMOKE_STAGE pasm_layout reject_non_marker")
print("P2_SMOKE_SKIP pasm_layout negative_launch_exceptions")

print("P2_SMOKE_STAGE pasm_layout nested")
assert(libstore.pasm_path("pasm_probe_pkg.probe") != nil)
assert(libstore.pasm_load("pasm_probe_pkg.probe") == "nested-dummy-pasm")

print("P2_SMOKE_STAGE pasm_layout missing")
print("P2_SMOKE_SKIP pasm_layout missing_diagnostics")

print("P2_SMOKE_SKIP pasm_layout invalid_name_exception")

print("P2_SMOKE_STAGE pasm_layout cleanup")
assert(os.remove(path))
assert(os.remove(marker_path))
assert(os.remove(nested_path))
if made_nested_dir
    assert(os.remove(nested_dir))
end

print("P2_SMOKE_PASS pasm_layout")
