print("P2_SMOKE_BEGIN cog_policy_min")

import p2
import string

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL cog_policy_min", label)
    end
    assert(cond)
end

check(type(p2.cog.capabilities) == "function", "capabilities_function")
check(type(p2.cog.required_capability_keys) == "function", "required_function")
check(type(p2.cog.audit) == "function", "audit_function")
check(type(p2.cog.audit_ok) == "function", "audit_ok_function")
check(type(p2.cog.audit_problems) == "function", "audit_problems_function")

var caps = p2.cog.capabilities()
var required = p2.cog.required_capability_keys()
check(required.find("handle_model") != nil, "required_handle_model")
check(required.find("handle_cleanup_policy") != nil, "required_cleanup_policy")
check(required.find("isolated_vm_closure") != nil, "required_isolated_vm")
required.push("caller_mutated")
check(p2.cog.required_capability_keys().find("caller_mutated") == nil, "required_snapshot")

check(caps["spawn"], "spawn_available")
check(caps["spawn_task"], "spawn_task_available")
check(caps["native_blink"], "native_blink")
check(caps["native_blink_stack"] == 2048, "native_blink_stack")
check(caps["handle_model"] == "native_blink_info_stop_only", "handle_model")
check(caps["handle_base"] == 100, "handle_base")
check(caps["max_handles"] == 4, "max_handles")
check(caps["handle_id"], "handle_id")
check(caps["handle_info"], "handle_info")
check(caps["handle_status"], "handle_status")
check(caps["handle_join"], "handle_join")
check(caps["handle_stop"], "handle_stop")
check(caps["handle_kill"], "handle_kill")
check(caps["handle_result"], "handle_result")
check(caps["handle_error"], "handle_error")
check(caps["handle_status_policy"] == "status_aliases_info_map", "status_policy")
check(caps["handle_join_policy"] == "nonblocking_status_snapshot", "join_policy")
check(caps["handle_join_result_policy"] == "result_and_error_fields_in_join_snapshot", "join_result_policy")
check(caps["handle_kill_policy"] == "force_stop_cleanup_alias", "kill_policy")
check(caps["handle_cleanup_policy"] == "stop_releases_stack_mailbox_source_slot", "cleanup_policy")
check(caps["handle_result_policy"] == "last_result_value_nonblocking", "result_policy")
check(caps["handle_error_policy"] == "last_error_string_nonblocking", "error_policy")
check(string.find(caps["handle_unsupported_reason"], "blocking result waits") != nil, "unsupported_reason")
check(!caps["unsafe_shared_vm"], "unsafe_shared_vm_false")
check(caps["reject_unsupported"], "reject_unsupported")
check(!caps["berry_closure"], "berry_closure_false")
check(!caps["isolated_child_vm_cog"], "isolated_child_vm_false")
check(!caps["isolated_vm_closure"], "isolated_vm_closure_false")
check(!caps["literal_closure_transfer"], "literal_transfer_false")

var audit = p2.cog.audit()
check(p2.cog.audit_ok(), "audit_ok_helper")
check(p2.cog.audit_problems().size() == 0, "audit_problems_helper")
if type(audit) == "map"
    check(audit["ok"], "audit_ok")
    check(audit["problem_count"] == 0, "audit_problem_count")
    check(audit["missing_capability_keys"].size() == 0, "audit_missing_caps")
    check(audit["handle_model"] == caps["handle_model"], "audit_handle_model")
    check(audit["handle_cleanup_policy"] == caps["handle_cleanup_policy"], "audit_cleanup_policy")
    audit["problems"].push("caller_mutated")
    check(p2.cog.audit()["problems"].size() == 0, "audit_snapshot")
else
    check(type(audit) == "string", "audit_string_compat")
    check(audit == "problems", "audit_string_value")
end

check(p2.cog.info().size() == 0, "no_spawned_cogs")

print("P2_SMOKE_PASS cog_policy_min")
