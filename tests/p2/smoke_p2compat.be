print("P2_SMOKE_BEGIN p2compat")

import p2compat

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
unsupported_names.push("p2compat_unsupported_name_mutation_probe")
assert(p2compat.find("p2compat_unsupported_name_mutation_probe") == nil)
assert(size(p2compat.names_by_status("not-a-status")) == 0)

var report = p2compat.report()
assert(type(report) == "map")
assert(size(report["statuses"]) == 4)
assert(size(report["items"]) == size(p2compat.items()))
assert(size(report["names"]) == size(p2compat.names()))
assert(report["summary"]["supported"] == summary["supported"])
assert(report["summary"]["partial"] == summary["partial"])
assert(report["summary"]["staged"] == summary["staged"])
assert(report["summary"]["unsupported"] == summary["unsupported"])
assert(type(report["by_status"]) == "map")
assert(size(report["by_status"][p2compat.UNSUPPORTED]) == summary["unsupported"])
assert(report["by_status"][p2compat.UNSUPPORTED].find("environment") >= 0)
assert(report["bytecode"]["execution"] == bc["execution"])
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
assert(p2compat.audit_ok())
var audit_problems = p2compat.audit_problems()
assert(type(audit_problems) == "list")
assert(size(audit_problems) == 0)
audit_problems.push("p2compat_audit_problem_mutation_probe")
assert(size(p2compat.audit_problems()) == 0)

print("P2_SMOKE_PASS p2compat")
