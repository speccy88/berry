print("P2_SMOKE_BEGIN pasm_policy_min")

import p2
import string

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL pasm_policy_min", label)
    end
    assert(cond)
end

check(type(p2.asm.capabilities) == "function", "capabilities_function")
check(type(p2.asm.abi) == "function", "abi_function")
check(type(p2.asm.audit) == "function", "audit_function")
check(type(p2.asm.required_capability_keys) == "function", "required_caps_function")
check(type(p2.asm.required_abi_keys) == "function", "required_abi_function")

var caps = p2.asm.capabilities()
var required_caps = p2.asm.required_capability_keys()
check(required_caps.find("function_bridge_policy") != nil, "required_function_bridge")
check(required_caps.find("inline_assembler_policy") != nil, "required_inline")
check(required_caps.find("unsafe_gate") != nil, "required_unsafe_gate")
required_caps.push("caller_mutated")
check(p2.asm.required_capability_keys().find("caller_mutated") == nil, "required_caps_snapshot")

check(caps["safe_intrinsics"], "safe_intrinsics")
check(caps["sd_load"], "sd_load")
check(caps["raw_cognew"], "raw_cognew")
check(caps["marker_probe"], "marker_probe")
check(!caps["arbitrary_sd_launch_supported"], "arbitrary_sd_launch_false")
check(caps["arbitrary_blob_policy"] == "unsupported_exact_marker_fixture_only", "arbitrary_blob_policy")
check(!caps["function_bridge"], "function_bridge_false")
check(caps["function_bridge_policy"] == "unsupported_no_calling_convention", "function_bridge_policy")
check(string.find(caps["function_bridge_reason"], "argument marshalling") != nil, "function_bridge_reason")
check(!caps["inline_assembler"], "inline_false")
check(caps["inline_assembler_policy"] == "unsupported_no_parser_or_safety_contract", "inline_policy")
check(string.find(caps["inline_assembler_reason"], "assembly parser") != nil, "inline_reason")
check(!caps["unsafe_asm"], "unsafe_false")
check(caps["unsafe_gate"] == "BE_P2_ENABLE_UNSAFE_ASM", "unsafe_gate")
check(caps["unsafe_default"] == false, "unsafe_default")
check(caps["unsafe_module"] == "none", "unsafe_module")

var abi = p2.asm.abi()
var required_abi = p2.asm.required_abi_keys()
check(required_abi.find("function_bridge_required") != nil, "required_abi_function_bridge")
check(required_abi.find("inline_assembler_required") != nil, "required_abi_inline")
check(required_abi.find("unsafe_gate") != nil, "required_abi_unsafe_gate")
required_abi.push("caller_mutated")
check(p2.asm.required_abi_keys().find("caller_mutated") == nil, "required_abi_snapshot")

check(abi["status"] == "marker_fixture_only", "abi_status")
check(abi["arbitrary_blob_abi"] == false, "abi_arbitrary_false")
check(abi["arbitrary_blob_policy"] == caps["arbitrary_blob_policy"], "abi_arbitrary_policy")
check(abi["function_bridge_abi"] == false, "abi_function_false")
check(abi["function_bridge_policy"] == caps["function_bridge_policy"], "abi_function_policy")
check(string.find(abi["function_bridge_required"], "return values") != nil, "abi_function_required")
check(abi["inline_assembler_abi"] == false, "abi_inline_false")
check(abi["inline_assembler_policy"] == caps["inline_assembler_policy"], "abi_inline_policy")
check(string.find(abi["inline_assembler_required"], "register clobbers") != nil, "abi_inline_required")
check(abi["unsafe_gate"] == caps["unsafe_gate"], "abi_unsafe_gate")
check(abi["unsafe_default"] == false, "abi_unsafe_default")
check(abi["unsafe_module"] == "none", "abi_unsafe_module")

var audit = p2.asm.audit()
check(p2.asm.audit_ok(), "audit_ok_helper")
check(p2.asm.audit_problems().size() == 0, "audit_problems_helper")
if type(audit) == "map"
    check(audit["ok"], "audit_ok")
    check(audit["problem_count"] == 0, "audit_problem_count")
    check(audit["missing_capability_keys"].size() == 0, "audit_missing_caps")
    check(audit["missing_abi_keys"].size() == 0, "audit_missing_abi")
    check(audit["function_bridge_policy_match"], "audit_function_policy_match")
    check(audit["inline_assembler_policy_match"], "audit_inline_policy_match")
    check(audit["unsafe_gate_match"], "audit_unsafe_gate_match")
    audit["problems"].push("caller_mutated")
    check(p2.asm.audit()["problems"].size() == 0, "audit_snapshot")
else
    check(type(audit) == "string", "audit_string_compat")
    check(audit == "missing_capability_keys", "audit_string_value")
end

print("P2_SMOKE_PASS pasm_policy_min")
