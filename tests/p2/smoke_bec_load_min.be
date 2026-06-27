print("P2_SMOKE_BEGIN bec_abi_min")

import libstore

var name = "becload"
var execution = libstore.compiled_execution_probe()
assert(execution["loader_supported"])
assert(execution["validator_supported"])
assert(execution["supported"])
print("P2_SMOKE_STEP bec_abi_execution")

var header = libstore.compiled_header(name)
assert(!header["valid"])
assert(header["reason"] == "incompatible_bytecode_vm")
assert(header["sizeinfo"] != header["expected_sizeinfo"])

var fresh = libstore.compiled_freshness(name)
assert(fresh["compiled_exists"])
assert(fresh["manifest_exists"])
assert(fresh["manifest_valid"])
assert(fresh["fresh"])
assert(!fresh["usable"])
assert(fresh["reason"] == "incompatible_bytecode_vm")
print("P2_SMOKE_STEP bec_abi_freshness")

var resolved = libstore.resolve(name)
assert(resolved["selected_kind"] == "source")
assert(resolved["selected_path"] == "/berry/lib/becload.be")
assert(resolved["compiled_blocked_reason"] == "incompatible_bytecode_vm")
print("P2_SMOKE_STEP bec_abi_resolve")

var loaded = libstore.load(name)
assert(loaded.answer == 123)
assert(loaded.origin == "source-fallback-fixture")
print("P2_SMOKE_STEP bec_abi_load")

print("P2_SMOKE_PASS bec_abi_min")
