print("P2_SMOKE_BEGIN p2compat")

import p2compat
import p2

assert(p2compat.supported("sd_filesystem"))
assert(p2compat.supported("sd_source_import"))
assert(p2compat.supported("package_import"))
assert(p2compat.supported("sys_module"))
assert(p2compat.status("compiled_bytecode") == p2compat.STAGED)
assert(p2compat.status("bytecode_cache_emit") == p2compat.STAGED)
assert(p2compat.status("bytecode_bulk_emit") == p2compat.STAGED)
assert(p2compat.status("bytecode_bulk_plan_exports") == p2compat.STAGED)
assert(p2compat.status("bytecode_emit_reason_summary") == p2compat.STAGED)
assert(p2compat.status("bytecode_emit_provision_plan") == p2compat.STAGED)
assert(p2compat.status("bytecode_emit_candidate_lists") == p2compat.STAGED)
assert(p2compat.status("bytecode_emit_candidate_exports") == p2compat.STAGED)
assert(p2compat.status("bytecode_validator") == p2compat.STAGED)
assert(p2compat.status("bytecode_load_api") == p2compat.STAGED)
assert(p2compat.status("bytecode_status_api") == p2compat.STAGED)
assert(p2compat.status("bytecode_inventory_api") == p2compat.STAGED)
assert(p2compat.status("bytecode_summary_api") == p2compat.STAGED)
assert(p2compat.status("bytecode_reason_summary") == p2compat.STAGED)
assert(p2compat.status("bytecode_candidate_lists") == p2compat.STAGED)
assert(p2compat.status("bytecode_candidate_exports") == p2compat.STAGED)
assert(p2compat.status("bytecode_provision_plan") == p2compat.STAGED)
assert(p2compat.status("bec_manifest") == p2compat.STAGED)
assert(p2compat.status("sys_path") == p2compat.PARTIAL)
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
assert(p2compat.status("subprocess") == p2compat.UNSUPPORTED)
assert(p2compat.status("network_sockets") == p2compat.UNSUPPORTED)
assert(p2compat.status("native_threads") == p2compat.UNSUPPORTED)
assert(p2compat.status("video_output") == p2compat.UNSUPPORTED)
assert(p2compat.status("vga_demo") == p2compat.UNSUPPORTED)
assert(p2compat.status("usb_hid") == p2compat.UNSUPPORTED)
assert(p2compat.status("usb_demo") == p2compat.UNSUPPORTED)
assert(p2compat.status("child_vm_primitive_transfer") == p2compat.PARTIAL)
assert(p2compat.status("child_vm_named_closure_bridge") == p2compat.STAGED)
assert(p2compat.status("child_vm_captured_closure_transfer") == p2compat.UNSUPPORTED)
assert(p2compat.status("child_vm_live_object_transfer") == p2compat.UNSUPPORTED)
assert(p2compat.status("child_vm_transfer_policy") == p2compat.STAGED)
assert(p2compat.status("no_such_capability") == nil)

var statuses = p2compat.statuses()
assert(size(statuses) == 4)
assert(statuses[0] == p2compat.SUPPORTED)
assert(statuses[1] == p2compat.PARTIAL)
assert(statuses[2] == p2compat.STAGED)
assert(statuses[3] == p2compat.UNSUPPORTED)
assert(p2compat.status_known(p2compat.SUPPORTED))
assert(p2compat.status_known(p2compat.PARTIAL))
assert(p2compat.status_known(p2compat.STAGED))
assert(p2compat.status_known(p2compat.UNSUPPORTED))
assert(!p2compat.status_known("not-a-status"))
statuses.push("p2compat_status_mutation_probe")
assert(!p2compat.status_known("p2compat_status_mutation_probe"))

var names = p2compat.names()
assert(size(names) == size(p2compat.items()))
assert(names.find("sd_filesystem") >= 0)
assert(names.find("environment") >= 0)
names.push("p2compat_name_mutation_probe")
assert(p2compat.find("p2compat_name_mutation_probe") == nil)

var unsupported = p2compat.unsupported()
assert(size(unsupported) >= 4)
var saw_env = false
for item : unsupported
    assert(item["status"] == p2compat.UNSUPPORTED)
    if item["name"] == "environment"
        saw_env = true
    end
end
assert(saw_env)

var package_info = p2compat.find("package_import")
assert(type(package_info) == "map")
assert(package_info["status"] == p2compat.SUPPORTED)
assert(type(package_info["summary"]) == "string")
var package_summary = package_info["summary"]
package_info["summary"] = "mutated package summary"
assert(p2compat.find("package_import")["summary"] == package_summary)

var sys_info = p2compat.find("sys_module")
assert(type(sys_info) == "map")
assert(sys_info["status"] == p2compat.SUPPORTED)
assert(type(sys_info["summary"]) == "string")

var manifest_info = p2compat.find("bec_manifest")
assert(type(manifest_info) == "map")
assert(manifest_info["status"] == p2compat.STAGED)
assert(type(manifest_info["summary"]) == "string")

var bc = p2compat.bytecode()
assert(type(bc) == "map")
assert(type(bc["saver"]) == "bool")
assert(type(bc["loader"]) == "bool")
assert(type(bc["validator"]) == "bool")
assert(bc["cache_emit"] == bc["saver"])
assert(bc["execution"] == (bc["loader"] && bc["validator"]))
assert(bc["default_source_fallback"] == !bc["execution"])
var bc_execution = bc["execution"]
bc["execution"] = !bc_execution
assert(p2compat.bytecode()["execution"] == bc_execution)
bc["execution"] = bc_execution

assert(type(p2compat.child_vm_transfer_policy) == "function")
assert(type(p2compat.required_capability_names) == "function")
assert(type(p2compat.required_child_vm_policy_keys) == "function")
var required_compat_names = p2compat.required_capability_names()
assert(required_compat_names.find("child_vm_primitive_transfer") >= 0)
assert(required_compat_names.find("child_vm_transfer_policy") >= 0)
required_compat_names.push("p2compat_required_name_mutation_probe")
assert(p2compat.required_capability_names().find("p2compat_required_name_mutation_probe") == nil)
var required_child_policy_keys = p2compat.required_child_vm_policy_keys()
assert(required_child_policy_keys.find("closure_name_policy") >= 0)
assert(required_child_policy_keys.find("status_capabilities") >= 0)
required_child_policy_keys.push("p2compat_required_policy_mutation_probe")
assert(p2compat.required_child_vm_policy_keys().find("p2compat_required_policy_mutation_probe") == nil)
var child_policy = p2compat.child_vm_transfer_policy()
assert(child_policy["model"] == "isolated_child_vm_transfer_policy")
assert(child_policy["primitive_copy"] == p2compat.PARTIAL)
assert(child_policy["copyable_types"].find("nil") >= 0)
assert(child_policy["copyable_types"].find("bool") >= 0)
assert(child_policy["copyable_types"].find("int") >= 0)
assert(child_policy["copyable_types"].find("string") >= 0)
assert(child_policy["bounded_string_copy"])
assert(child_policy["string_policy"] == "bounded_copy_by_value")
assert(type(p2compat.child_vm_copyable_type) == "function")
assert(type(p2compat.child_vm_policy) == "function")
assert(p2compat.child_vm_policy("model") == "isolated_child_vm_transfer_policy")
assert(p2compat.child_vm_policy("primitive_copy") == p2compat.PARTIAL)
assert(p2compat.child_vm_policy("bounded_string_copy"))
assert(p2compat.child_vm_policy("closure_name_bridge") == p2compat.STAGED)
assert(p2compat.child_vm_policy("captured_closure_transfer") == p2compat.UNSUPPORTED)
assert(p2compat.child_vm_policy("ownership_transfer") == false)
assert(p2compat.child_vm_policy("missing") == nil)
assert(p2compat.child_vm_policy(nil) == nil)
var policy_copyable = p2compat.child_vm_policy("copyable_types")
assert(policy_copyable.find("string") >= 0)
policy_copyable.push("map")
assert(p2compat.child_vm_policy("copyable_types").find("map") == nil)
var policy_status_caps = p2compat.child_vm_policy("status_capabilities")
assert(policy_status_caps.find("child_vm_primitive_transfer") >= 0)
policy_status_caps.clear()
assert(p2compat.child_vm_policy("status_capabilities").size() > 0)
assert(p2compat.child_vm_copyable_type("nil"))
assert(p2compat.child_vm_copyable_type("bool"))
assert(p2compat.child_vm_copyable_type("int"))
assert(p2compat.child_vm_copyable_type("string"))
assert(!p2compat.child_vm_copyable_type("map"))
assert(!p2compat.child_vm_copyable_type(nil))
assert(child_policy["closure_name_bridge"] == p2compat.STAGED)
assert(child_policy["closure_name_policy"] == "validated_selector_only_no_closure_object_transfer")
assert(child_policy["captured_closure_transfer"] == p2compat.UNSUPPORTED)
assert(child_policy["live_object_transfer"] == p2compat.UNSUPPORTED)
assert(child_policy["rejected_live_types"].find("list") >= 0)
assert(child_policy["rejected_live_types"].find("map") >= 0)
assert(child_policy["rejected_live_types"].find("native_pointer") >= 0)
assert(child_policy["rejected_live_types"].find("hardware_resource") >= 0)
assert(type(p2compat.child_vm_rejected_type) == "function")
assert(p2compat.child_vm_rejected_type("list"))
assert(p2compat.child_vm_rejected_type("map"))
assert(p2compat.child_vm_rejected_type("instance"))
assert(p2compat.child_vm_rejected_type("native_pointer"))
assert(p2compat.child_vm_rejected_type("file_handle"))
assert(p2compat.child_vm_rejected_type("hardware_resource"))
assert(!p2compat.child_vm_rejected_type("int"))
assert(!p2compat.child_vm_rejected_type(nil))
assert(!child_policy["ownership_transfer"])
assert(!child_policy["shared_mutable_state"])
assert(!child_policy["resource_transfer"])
assert(child_policy["default_policy"] == "reject_unlisted_values")
assert(child_policy["status_capabilities"].find("child_vm_primitive_transfer") >= 0)
child_policy["copyable_types"].push("map")
child_policy["rejected_live_types"].clear()
assert(p2compat.child_vm_transfer_policy()["copyable_types"].find("map") == nil)
assert(p2compat.child_vm_transfer_policy()["rejected_live_types"].size() > 0)

def p2compat_check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL p2compat", label)
    end
    assert(cond)
end

p2compat_check(type(p2.vm_copyable) == "function", "vm_copyable_function")
var copy_nil = p2.vm_copyable(nil)
var copy_bool = p2.vm_copyable(true)
var copy_int = p2.vm_copyable(42)
var copy_string = p2.vm_copyable("child-ok")
p2compat_check(copy_nil["ok"] && copy_nil["kind"] == "nil", "vm_copyable_nil")
p2compat_check(copy_bool["ok"] && copy_bool["kind"] == "bool", "vm_copyable_bool")
p2compat_check(copy_int["ok"] && copy_int["kind"] == "int", "vm_copyable_int")
p2compat_check(copy_string["ok"] && copy_string["kind"] == "string", "vm_copyable_string")
p2compat_check(copy_string["reason"] == "bounded copy", "vm_copyable_string_reason")

def p2compat_vm_copyable_fn()
    return 1
end

var reject_list = p2.vm_copyable([1])
var reject_map = p2.vm_copyable({"a": 1})
var reject_fn = p2.vm_copyable(p2compat_vm_copyable_fn)
p2compat_check(!reject_list["ok"] && reject_list["kind"] == "list", "vm_copyable_list")
p2compat_check(!reject_map["ok"] && reject_map["kind"] == "map", "vm_copyable_map")
p2compat_check(!reject_fn["ok"] && reject_fn["kind"] == "function", "vm_copyable_function_rejected")
p2compat_check(type(reject_list["reason"]) == "string", "vm_copyable_list_reason")
p2compat_check(type(reject_map["reason"]) == "string", "vm_copyable_map_reason")
p2compat_check(type(reject_fn["reason"]) == "string", "vm_copyable_function_reason")

var rejected_no_arg = false
try
    p2.vm_copyable()
except .. as e, m
    rejected_no_arg = true
end
p2compat_check(rejected_no_arg, "vm_copyable_no_arg_rejected")

var summary = p2compat.summary()
assert(summary["supported"] >= 2)
assert(summary["staged"] >= 18)
assert(summary["unsupported"] >= 4)
var summary_supported = summary["supported"]
summary["supported"] = -1
assert(p2compat.summary()["supported"] == summary_supported)
summary["supported"] = summary_supported

var items = p2compat.items()
var counted = {
    "supported": 0,
    "partial": 0,
    "staged": 0,
    "unsupported": 0
}
for item : items
    assert(type(item["name"]) == "string")
    assert(type(item["status"]) == "string")
    assert(type(item["summary"]) == "string")
    counted[item["status"]] += 1
end
var first_item_name = items[0]["name"]
var first_item_summary = items[0]["summary"]
items[0]["summary"] = "mutated item summary"
assert(p2compat.find(first_item_name)["summary"] == first_item_summary)
assert(counted["supported"] == summary["supported"])
assert(counted["partial"] == summary["partial"])
assert(counted["staged"] == summary["staged"])
assert(counted["unsupported"] == summary["unsupported"])

items.push({
    "name": "p2compat_mutation_probe",
    "status": p2compat.SUPPORTED,
    "summary": "local list mutation must not alter module metadata"
})
assert(p2compat.find("p2compat_mutation_probe") == nil)

var staged_items = p2compat.items_by_status(p2compat.STAGED)
assert(size(staged_items) == summary["staged"])
for item : staged_items
    assert(item["status"] == p2compat.STAGED)
end
var staged_item_name = staged_items[0]["name"]
var staged_item_summary = staged_items[0]["summary"]
staged_items[0]["summary"] = "mutated staged summary"
assert(p2compat.find(staged_item_name)["summary"] == staged_item_summary)
staged_items.push({
    "name": "p2compat_status_filter_probe",
    "status": p2compat.STAGED,
    "summary": "local filtered-list mutation must not alter module metadata"
})
assert(p2compat.find("p2compat_status_filter_probe") == nil)
assert(size(p2compat.items_by_status("not-a-status")) == 0)

var unsupported_names = p2compat.names_by_status(p2compat.UNSUPPORTED)
assert(size(unsupported_names) == summary["unsupported"])
assert(unsupported_names.find("environment") >= 0)
assert(unsupported_names.find("subprocess") >= 0)
assert(unsupported_names.find("network_sockets") >= 0)
assert(unsupported_names.find("native_threads") >= 0)
assert(unsupported_names.find("video_output") >= 0)
assert(unsupported_names.find("vga_demo") >= 0)
assert(unsupported_names.find("usb_hid") >= 0)
assert(unsupported_names.find("usb_demo") >= 0)
unsupported_names.push("p2compat_unsupported_name_mutation_probe")
assert(p2compat.find("p2compat_unsupported_name_mutation_probe") == nil)
assert(size(p2compat.names_by_status("not-a-status")) == 0)

var report = p2compat.report()
p2compat_check(type(report) == "map", "report_type")
p2compat_check(size(report["statuses"]) == 4, "report_statuses")
p2compat_check(size(report["items"]) == size(p2compat.items()), "report_items_size")
p2compat_check(size(report["names"]) == size(p2compat.names()), "report_names_size")
p2compat_check(report["summary"]["supported"] == summary["supported"], "report_summary_supported")
p2compat_check(report["summary"]["partial"] == summary["partial"], "report_summary_partial")
p2compat_check(report["summary"]["staged"] == summary["staged"], "report_summary_staged")
p2compat_check(report["summary"]["unsupported"] == summary["unsupported"], "report_summary_unsupported")
p2compat_check(type(report["by_status"]) == "map", "report_by_status_type")
p2compat_check(size(report["by_status"][p2compat.UNSUPPORTED]) == summary["unsupported"], "report_by_status_unsupported_size")
p2compat_check(report["by_status"][p2compat.UNSUPPORTED].find("environment") >= 0, "report_by_status_environment")
p2compat_check(report["bytecode"]["execution"] == bc["execution"], "report_bytecode_execution")
var report_summary_supported = report["summary"]["supported"]
report["names"].push("p2compat_report_name_mutation_probe")
report["items"].push({
    "name": "p2compat_report_item_mutation_probe",
    "status": p2compat.SUPPORTED,
    "summary": "local report mutation must not alter module metadata"
})
report["summary"]["supported"] = -1
var report_item_name = report["items"][0]["name"]
var report_item_summary = report["items"][0]["summary"]
report["items"][0]["summary"] = "mutated report item summary"
report["by_status"][p2compat.UNSUPPORTED].push("p2compat_report_status_mutation_probe")
assert(p2compat.find("p2compat_report_name_mutation_probe") == nil)
assert(p2compat.find("p2compat_report_item_mutation_probe") == nil)
assert(p2compat.find("p2compat_report_status_mutation_probe") == nil)
assert(p2compat.find(report_item_name)["summary"] == report_item_summary)
assert(p2compat.report()["summary"]["supported"] == report_summary_supported)

var audit = p2compat.audit()
assert(type(audit) == "map")
assert(audit["ok"])
assert(audit["count"] == size(p2compat.items()))
assert(audit["counts_match"])
assert(audit["child_vm_transfer_policy_match"])
assert(size(audit["missing_capability_names"]) == 0)
assert(size(audit["missing_child_vm_policy_keys"]) == 0)
assert(size(audit["duplicates"]) == 0)
assert(size(audit["unknown_statuses"]) == 0)
assert(audit["summary"]["supported"] == summary["supported"])
assert(audit["summary"]["partial"] == summary["partial"])
assert(audit["summary"]["staged"] == summary["staged"])
assert(audit["summary"]["unsupported"] == summary["unsupported"])
assert(audit["counted"]["supported"] == summary["supported"])
assert(audit["counted"]["partial"] == summary["partial"])
assert(audit["counted"]["staged"] == summary["staged"])
assert(audit["counted"]["unsupported"] == summary["unsupported"])
audit["duplicates"].push("p2compat_audit_duplicate_mutation_probe")
audit["unknown_statuses"].push("p2compat_audit_status_mutation_probe")
assert(size(p2compat.audit()["duplicates"]) == 0)
assert(size(p2compat.audit()["unknown_statuses"]) == 0)
assert(size(p2compat.audit()["missing_capability_names"]) == 0)
assert(size(p2compat.audit()["missing_child_vm_policy_keys"]) == 0)
assert(p2compat.audit_ok())
var audit_problems = p2compat.audit_problems()
assert(type(audit_problems) == "list")
assert(size(audit_problems) == 0)
audit_problems.push("p2compat_audit_problem_mutation_probe")
assert(size(p2compat.audit_problems()) == 0)

print("P2_SMOKE_PASS p2compat")
