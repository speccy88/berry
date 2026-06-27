import introspect
import os

def expect_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
    end
    assert(caught)
end

var p2 = module("p2")
p2.raise_status_info = false
p2.status_info = def()
    if p2.raise_status_info
        raise "value_error", "forced status_info failure"
    end
    return {
        "build": {
            "board": "p2edge32",
            "profile": "xmm",
            "model": "LARGE",
            "board_has_psram": true,
            "reserved_pin_policy": "board_profile_reserved_pins_enforced",
            "bytecode_saver": false,
            "bytecode_loader": false,
            "bytecode_execution": false
        },
        "runtime": {
            "toolchain": "Catalina",
            "memory_profile": "xmm_psram"
        }
    }
end
p2.heap_info = def()
    return {
        "vm_partition_bytes": 32768,
        "vm_partition_capacity": 3,
        "vm_partition_free_capacity": 2,
        "vm_partition_max": 4,
        "vm_partition_created": 1,
        "vm_partition_current": -1
    }
end
introspect.setmodule("p2", p2)

var binary_heap = run_file("modules/binary_heap.be")
var heap_caps = binary_heap.capabilities()
assert(heap_caps["make_heap"])
assert(heap_caps["remove_heap"])
assert(heap_caps["sort"])
assert(heap_caps["in_place_sort"])
assert(heap_caps["heap_copy_commit"])
assert(heap_caps["empty_singleton_sort"])
assert(heap_caps["exception_preserves_input"])
assert(heap_caps["exception_preservation_audit"])
assert(!heap_caps["default_audit_throws"])
assert(heap_caps["comparator_required"])
assert(heap_caps["audit"])
assert(heap_caps["audit_policy"] == "tiny_in_memory_heap_self_check_no_throw")
heap_caps["sort"] = false
assert(binary_heap.capabilities()["sort"])
assert(type(binary_heap.required_capability_keys) == "function")
var heap_required_caps = binary_heap.required_capability_keys()
assert(heap_required_caps.find("sort") >= 0)
assert(heap_required_caps.find("audit_policy") >= 0)
heap_required_caps.push("__host_heap_required_mutation_probe__")
assert(binary_heap.required_capability_keys().find("__host_heap_required_mutation_probe__") == nil)
assert(binary_heap.capability("sort"))
assert(binary_heap.capability("missing") == nil)
assert(binary_heap.capability(nil) == nil)
var heap_audit = binary_heap.audit()
assert(heap_audit["ok"])
assert(heap_audit["problem_count"] == 0)
assert(heap_audit["problems"].size() == 0)
assert(heap_audit["missing_capability_keys"].size() == 0)
assert(heap_audit["audit_policy"] == "tiny_in_memory_heap_self_check_no_throw")
assert(heap_audit["sort"])
assert(heap_audit["make_heap"])
assert(heap_audit["remove_heap"])
assert(heap_audit["heap_copy_commit"])
assert(heap_audit["exception_preserves_input"])
assert(!heap_audit["exception_preservation_checked"])
assert(heap_audit["exception_preservation_audit"])
assert(!heap_audit["default_audit_throws"])
heap_audit["problems"].push("__host_heap_audit_problem_mutation_probe__")
assert(binary_heap.audit_problems().size() == 0)
assert(binary_heap.audit_ok())
var data = [5, 1, 4, 1, 3]
binary_heap.sort(data, /a b -> a < b)
assert(data == [1, 1, 3, 4, 5])
var empty_heap = []
binary_heap.sort(empty_heap, /a b -> a < b)
assert(empty_heap == [])
var single_heap = [7]
binary_heap.sort(single_heap, /a b -> a < b)
assert(single_heap == [7])

var preserved = [5, 1, 4, 2, 3]
var comparisons = {"count": 0}
def raising_cmp(state)
    return def(a, b)
        state["count"] += 1
        if state["count"] > 4
            raise "value_error", "forced heap compare failure"
        end
        return a < b
    end
end
var sort_failed = false
try
    binary_heap.sort(preserved, raising_cmp(comparisons))
except .. as e, m
    sort_failed = true
    assert(e == "value_error")
end
assert(sort_failed)
assert(preserved == [5, 1, 4, 2, 3])
var exception_audit = binary_heap.exception_preservation_audit()
assert(exception_audit["ok"])
assert(exception_audit["raised"])
assert(exception_audit["preserved"])
assert(exception_audit["input"] == [5, 1, 4, 2, 3])
assert(exception_audit["comparison_count"] > 4)

var heap = [7, 2, 9, 1]
binary_heap.make_heap(heap, /a b -> a > b)
assert(binary_heap.remove_heap(heap, /a b -> a > b) == 9)
assert(binary_heap.remove_heap(heap, /a b -> a > b) == 7)

var spi = module("spi")
spi.init = def(sck, mosi, miso, cs, mode, khz) end
spi.select = def() end
spi.deselect = def() end
spi.transfer = def(raw) return raw end
spi.stop = def() end
introspect.setmodule("spi", spi)

var wifi = run_file("modules/wifi.be")
assert(wifi.capability("transport") == "spi")
assert(wifi.capability("hardware") == "wifinina_airlift")
assert(wifi.capability("hardware_deferred"))
assert(wifi.capability("request_requires_init"))
assert(wifi.capability("import_init_noop"))
assert(wifi.capability("default_config"))
assert(wifi.capability("audit"))
assert(wifi.capability("missing") == nil)
assert(type(wifi.required_capability_keys) == "function")
var wifi_required_caps = wifi.required_capability_keys()
assert(wifi_required_caps.find("transport") >= 0)
assert(wifi_required_caps.find("audit_policy") >= 0)
wifi_required_caps.push("__host_wifi_required_mutation_probe__")
assert(wifi.required_capability_keys().find("__host_wifi_required_mutation_probe__") == nil)
var wifi_cfg = wifi.default_config()
assert(wifi_cfg["sck"] == 16)
assert(wifi_cfg["mosi"] == 17)
assert(wifi_cfg["miso"] == 18)
assert(wifi_cfg["cs"] == 19)
assert(wifi_cfg["busy"] == 20)
assert(wifi_cfg["reset"] == 21)
assert(wifi_cfg["irq"] == 22)
assert(wifi_cfg["khz"] == 1000)
assert(wifi_cfg["mode"] == 0)
wifi_cfg["sck"] = 99
assert(wifi.default_config()["sck"] == 16)
var wifi_import_init = wifi.init(wifi)
assert(type(wifi_import_init) == "module")
var wifi_audit = wifi.audit()
assert(wifi_audit["ok"])
assert(wifi_audit["problem_count"] == 0)
assert(wifi_audit["problems"].size() == 0)
assert(wifi_audit["missing_capability_keys"].size() == 0)
assert(wifi_audit["transport"] == "spi")
assert(wifi_audit["hardware"] == "wifinina_airlift")
assert(wifi_audit["hardware_deferred"])
assert(wifi_audit["request_requires_init"])
assert(wifi_audit["import_init_noop"])
assert(wifi_audit["audit_policy"] == "metadata_only_no_spi_transaction")
wifi_audit["problems"].push("__host_wifi_audit_problem_mutation_probe__")
assert(wifi.audit_problems().size() == 0)
assert(wifi.audit_ok())

var math = run_file("modules/math.be")
assert(math.sqrt(49) == 7)
assert(math.capability("finite_fallbacks"))
assert(type(math.capability("nan_inf")) == "bool")
assert(math.capability("invalid_domain_nil"))
assert(math.capability("non_number_zero"))
assert(math.capability("constants"))
assert(math.capability("rounding"))
assert(math.capability("minmax"))
assert(math.capability("angle_conversion"))
assert(math.capability("audit"))
assert(math.capability("cordic_sqrt") == false)
assert(math.capability("cordic_exp_log") == false)
assert(math.capability("missing") == nil)
assert(type(math.required_capability_keys) == "function")
var math_required_caps = math.required_capability_keys()
assert(math_required_caps.find("finite_fallbacks") >= 0)
assert(math_required_caps.find("p2_cordic_available") >= 0)
assert(math_required_caps.find("audit_policy") >= 0)
math_required_caps.push("__host_math_required_mutation_probe__")
assert(math.required_capability_keys().find("__host_math_required_mutation_probe__") == nil)
var math_audit = math.audit()
assert(math_audit["ok"])
assert(math_audit["problem_count"] == 0)
assert(math_audit["problems"].size() == 0)
assert(math_audit["missing_capability_keys"].size() == 0)
assert(math_audit["audit_policy"] == "finite_metadata_and_tiny_numeric_self_check")
assert(math_audit["backend"] == "berry_fallback")
assert(!math_audit["cordic"])
assert(math_audit["finite_fallbacks"])
assert(math_audit["nan_inf"] == math.capability("nan_inf"))
assert(math_audit["invalid_domain_nil"])
assert(math_audit["non_number_zero"])
assert(math_audit["constants"])
assert(math_audit["rounding"])
assert(math_audit["minmax"])
assert(math_audit["angle_conversion"])
math_audit["problems"].push("__host_math_audit_problem_mutation_probe__")
assert(math.audit_problems().size() == 0)
assert(math.audit_ok())

var p2compat = run_file("modules/p2compat.be")
assert(p2compat.supported("sd_filesystem"))
assert(p2compat.status("environment") == p2compat.UNSUPPORTED)
assert(p2compat.status("video_output") == p2compat.UNSUPPORTED)
assert(p2compat.status("vga_demo") == p2compat.UNSUPPORTED)
assert(p2compat.status("usb_hid") == p2compat.UNSUPPORTED)
assert(p2compat.status("usb_demo") == p2compat.UNSUPPORTED)
assert(p2compat.status("compiled_bytecode") == p2compat.STAGED)
assert(p2compat.status("child_vm_primitive_transfer") == p2compat.PARTIAL)
assert(p2compat.status("child_vm_named_closure_bridge") == p2compat.STAGED)
assert(p2compat.status("child_vm_captured_closure_transfer") == p2compat.UNSUPPORTED)
assert(p2compat.status("child_vm_live_object_transfer") == p2compat.UNSUPPORTED)
assert(p2compat.status("child_vm_transfer_policy") == p2compat.STAGED)
assert(p2compat.status("board_profile_policy") == p2compat.SUPPORTED)
assert(p2compat.find("child_vm_primitive_transfer")["summary"] != "")
assert(p2compat.find("board_profile_policy")["summary"] != "")
assert(type(p2compat.child_vm_transfer_policy) == "function")
assert(type(p2compat.required_capability_names) == "function")
assert(type(p2compat.board_profile_policy) == "function")
assert(type(p2compat.board_profile_value) == "function")
assert(type(p2compat.board_pin_policy) == "function")
assert(type(p2compat.board_pin_allowed) == "function")
assert(type(p2compat.required_board_profile_policy_keys) == "function")
assert(type(p2compat.required_child_vm_policy_keys) == "function")
assert(type(p2compat.required_child_vm_partition_policy_keys) == "function")
assert(type(p2compat.child_vm_partition_policy) == "function")
assert(type(p2compat.child_vm_partition_value) == "function")
var required_compat_names = p2compat.required_capability_names()
assert(required_compat_names.find("board_profile_policy") >= 0)
assert(required_compat_names.find("child_vm_primitive_transfer") >= 0)
assert(required_compat_names.find("child_vm_transfer_policy") >= 0)
assert(required_compat_names.find("child_vm_partition_policy") >= 0)
required_compat_names.push("__host_required_name_mutation_probe__")
assert(p2compat.required_capability_names().find("__host_required_name_mutation_probe__") == nil)
var required_board_policy_keys = p2compat.required_board_profile_policy_keys()
assert(required_board_policy_keys.find("normal_catalina_dir") >= 0)
assert(required_board_policy_keys.find("unsupported_build_policy") >= 0)
required_board_policy_keys.push("__host_required_board_policy_mutation_probe__")
assert(p2compat.required_board_profile_policy_keys().find("__host_required_board_policy_mutation_probe__") == nil)
var required_child_policy_keys = p2compat.required_child_vm_policy_keys()
assert(required_child_policy_keys.find("closure_name_policy") >= 0)
assert(required_child_policy_keys.find("status_capabilities") >= 0)
required_child_policy_keys.push("__host_required_policy_mutation_probe__")
assert(p2compat.required_child_vm_policy_keys().find("__host_required_policy_mutation_probe__") == nil)
var required_partition_policy_keys = p2compat.required_child_vm_partition_policy_keys()
assert(required_partition_policy_keys.find("partition_bytes") >= 0)
assert(required_partition_policy_keys.find("retry_policy") >= 0)
required_partition_policy_keys.push("__host_required_partition_policy_mutation_probe__")
assert(p2compat.required_child_vm_partition_policy_keys().find("__host_required_partition_policy_mutation_probe__") == nil)
var board_policy = p2compat.board_profile_policy()
assert(board_policy["model"] == "explicit_board_profile_policy")
assert(board_policy["board"] == "p2edge32")
assert(board_policy["profile"] == "xmm")
assert(board_policy["catalina_model"] == "LARGE")
assert(board_policy["memory_profile"] == "xmm_psram")
assert(board_policy["psram_enabled"])
assert(board_policy["reserved_pin_policy"] == "board_profile_reserved_pins_enforced")
assert(board_policy["unsupported_build_policy"] == "raise_loud_or_report_unsupported")
assert(board_policy["normal_toolchain"] == "catalina")
assert(board_policy["normal_catalina_dir"] == "../Catalina")
assert(board_policy["normal_serial_port"] == "/dev/ttyUSB0")
assert(board_policy["edge32_psram_policy"] == "explicit_psram_profile_only")
assert(board_policy["xmm_policy"] == "explicit_xmm_profile_only")
assert(board_policy["reserved_pin_ranges"].size() == 3)
assert(board_policy["reserved_pin_ranges"][0]["name"] == "psram")
assert(board_policy["reserved_pin_ranges"][0]["first"] == 40)
assert(board_policy["reserved_pin_ranges"][0]["last"] == 57)
assert(board_policy["safe_jumper_pins"].find(7) >= 0)
assert(board_policy["status_capabilities"].find("board_profile_policy") >= 0)
assert(p2compat.board_profile_value("board") == "p2edge32")
assert(p2compat.board_profile_value("profile") == "xmm")
assert(p2compat.board_profile_value("normal_catalina_dir") == "../Catalina")
assert(p2compat.board_profile_value("missing") == nil)
assert(p2compat.board_profile_value(nil) == nil)
var board_ranges = p2compat.board_profile_value("reserved_pin_ranges")
board_ranges[0]["name"] = "mutated"
board_ranges.push({"name": "mutated", "first": 1, "last": 1})
assert(p2compat.board_profile_value("reserved_pin_ranges")[0]["name"] == "psram")
assert(p2compat.board_profile_value("reserved_pin_ranges").size() == 3)
var board_safe_pins = p2compat.board_profile_value("safe_jumper_pins")
board_safe_pins.push(99)
assert(p2compat.board_profile_value("safe_jumper_pins").find(99) == nil)
var pin0_policy = p2compat.board_pin_policy(0)
assert(pin0_policy["ok"])
assert(!pin0_policy["reserved"])
assert(pin0_policy["reason"] == "ok")
assert(p2compat.board_pin_allowed(0))
var pin40_policy = p2compat.board_pin_policy(40)
assert(!pin40_policy["ok"])
assert(pin40_policy["reserved"])
assert(pin40_policy["reason"] == "psram")
assert(!p2compat.board_pin_allowed(40))
var pin58_policy = p2compat.board_pin_policy(58)
assert(!pin58_policy["ok"])
assert(pin58_policy["reason"] == "sd")
var pin63_policy = p2compat.board_pin_policy(63)
assert(!pin63_policy["ok"])
assert(pin63_policy["reason"] == "serial")
var bad_pin_policy = p2compat.board_pin_policy(64)
assert(!bad_pin_policy["ok"])
assert(bad_pin_policy["reason"] == "pin_out_of_range")
var bad_pin_type_policy = p2compat.board_pin_policy("0")
assert(!bad_pin_type_policy["ok"])
assert(bad_pin_type_policy["reason"] == "invalid_pin_type")
var child_policy = p2compat.child_vm_transfer_policy()
assert(child_policy["model"] == "isolated_child_vm_transfer_policy")
assert(child_policy["primitive_copy"] == p2compat.PARTIAL)
assert(child_policy["copyable_types"].find("nil") >= 0)
assert(child_policy["copyable_types"].find("string") >= 0)
assert(child_policy["bounded_string_copy"])
assert(type(p2compat.child_vm_policy) == "function")
assert(type(p2compat.child_vm_live_object_transfer) == "function")
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
var policy_unsupported_helpers = p2compat.child_vm_policy("unsupported_helpers")
assert(policy_unsupported_helpers.find("child_vm_live_object_transfer") >= 0)
policy_unsupported_helpers.clear()
assert(p2compat.child_vm_policy("unsupported_helpers").size() > 0)
assert(p2compat.child_vm_copyable_type("nil"))
assert(p2compat.child_vm_copyable_type("bool"))
assert(p2compat.child_vm_copyable_type("int"))
assert(p2compat.child_vm_copyable_type("string"))
assert(!p2compat.child_vm_copyable_type("map"))
assert(!p2compat.child_vm_copyable_type(nil))
assert(child_policy["closure_name_bridge"] == p2compat.STAGED)
assert(child_policy["captured_closure_transfer"] == p2compat.UNSUPPORTED)
assert(child_policy["live_object_transfer"] == p2compat.UNSUPPORTED)
assert(child_policy["rejected_live_types"].find("native_pointer") >= 0)
assert(child_policy["rejected_live_types"].find("hardware_resource") >= 0)
assert(p2compat.child_vm_rejected_type("list"))
assert(p2compat.child_vm_rejected_type("map"))
assert(p2compat.child_vm_rejected_type("native_pointer"))
assert(p2compat.child_vm_rejected_type("file_handle"))
assert(p2compat.child_vm_rejected_type("hardware_resource"))
assert(!p2compat.child_vm_rejected_type("int"))
assert(!p2compat.child_vm_rejected_type(nil))
assert(!child_policy["ownership_transfer"])
assert(!child_policy["shared_mutable_state"])
assert(!child_policy["resource_transfer"])
assert(child_policy["unsupported_helpers"].find("child_vm_live_object_transfer") >= 0)
expect_error(def() return p2compat.child_vm_live_object_transfer([1]) end)
expect_error(def() return p2compat.child_vm_live_object_transfer({"a": 1}) end)
expect_error(def() return p2compat.child_vm_live_object_transfer(def() return 1 end) end)
child_policy["copyable_types"].push("map")
child_policy["rejected_live_types"].clear()
child_policy["unsupported_helpers"].clear()
assert(p2compat.child_vm_transfer_policy()["copyable_types"].find("map") == nil)
assert(p2compat.child_vm_transfer_policy()["rejected_live_types"].size() > 0)
assert(p2compat.child_vm_transfer_policy()["unsupported_helpers"].size() > 0)
var partition_policy = p2compat.child_vm_partition_policy()
assert(partition_policy["model"] == "runtime_heap_info_partition_policy")
assert(partition_policy["source"] == "p2.heap_info")
assert(partition_policy["partition_bytes"] == 32768)
assert(partition_policy["capacity"] == 3)
assert(partition_policy["free_capacity"] == 2)
assert(partition_policy["max_partitions"] == 4)
assert(partition_policy["created"] == 1)
assert(partition_policy["current"] == -1)
assert(partition_policy["usable_for_child_calls"])
assert(partition_policy["sizing_policy"] == "runtime_derived_no_fixed_production_count")
assert(!partition_policy["production_count_selected"])
assert(partition_policy["retry_policy"] == "stop_routine_priority_work_until_native_partition_allocator_changes")
assert(partition_policy["real_cog_policy"] == "unsupported_until_isolated_vm_cog_runtime_safe")
assert(partition_policy["status_capabilities"].find("child_vm_partition_policy") >= 0)
assert(p2compat.child_vm_partition_value("partition_bytes") == 32768)
assert(p2compat.child_vm_partition_value("retry_policy") == "stop_routine_priority_work_until_native_partition_allocator_changes")
assert(p2compat.child_vm_partition_value("missing") == nil)
assert(p2compat.child_vm_partition_value(nil) == nil)
var partition_status_caps = p2compat.child_vm_partition_value("status_capabilities")
partition_status_caps.clear()
assert(p2compat.child_vm_partition_value("status_capabilities").size() > 0)
assert(p2compat.bytecode()["default_source_fallback"])
assert(p2compat.audit_ok())
var supported_report = p2compat.status_report(p2compat.SUPPORTED)
assert(supported_report["known"])
assert(supported_report["status"] == p2compat.SUPPORTED)
assert(supported_report["count"] == supported_report["names"].size())
assert(supported_report["count"] > 0)
var supported_report_count = supported_report["count"]
supported_report["names"].push("__host_mutation_probe__")
assert(p2compat.status_report(p2compat.SUPPORTED)["count"] == supported_report_count)
var unknown_report = p2compat.status_report("not_a_status")
assert(!unknown_report["known"])
assert(unknown_report["count"] == 0)
assert(unknown_report["names"].size() == 0)
var report = p2compat.report()
var report_name_count = report["names"].size()
report["names"].push("__host_mutation_probe__")
assert(p2compat.report()["names"].size() == report_name_count)
var report_supported_count = report["summary"][p2compat.SUPPORTED]
report["summary"][p2compat.SUPPORTED] = -1
assert(p2compat.report()["summary"][p2compat.SUPPORTED] == report_supported_count)
var report_unsupported_count = report["by_status"][p2compat.UNSUPPORTED].size()
report["by_status"][p2compat.UNSUPPORTED].push("__host_status_mutation_probe__")
assert(p2compat.report()["by_status"][p2compat.UNSUPPORTED].size() == report_unsupported_count)
var report_bytecode_execution = report["bytecode"]["execution"]
report["bytecode"]["execution"] = !report_bytecode_execution
assert(p2compat.report()["bytecode"]["execution"] == report_bytecode_execution)
var report_board_profile = report["board_profile"]["profile"]
report["board_profile"]["profile"] = "mutated"
assert(p2compat.report()["board_profile"]["profile"] == report_board_profile)
var report_partition_bytes = report["child_vm_partition"]["partition_bytes"]
report["child_vm_partition"]["partition_bytes"] = -1
assert(p2compat.report()["child_vm_partition"]["partition_bytes"] == report_partition_bytes)
var primitive_item = p2compat.find("child_vm_primitive_transfer")
primitive_item["status"] = p2compat.SUPPORTED
assert(p2compat.status("child_vm_primitive_transfer") == p2compat.PARTIAL)
var audit = p2compat.audit()
var audit_supported_count = audit["summary"][p2compat.SUPPORTED]
audit["summary"][p2compat.SUPPORTED] = -1
audit["counted"][p2compat.SUPPORTED] = -1
audit["duplicates"].push("__host_audit_duplicate_mutation_probe__")
audit["unknown_statuses"].push("__host_audit_status_mutation_probe__")
var fresh_audit = p2compat.audit()
assert(fresh_audit["summary"][p2compat.SUPPORTED] == audit_supported_count)
assert(fresh_audit["counted"][p2compat.SUPPORTED] == audit_supported_count)
assert(fresh_audit["board_profile_policy_match"])
assert(fresh_audit["child_vm_transfer_policy_match"])
assert(fresh_audit["child_vm_partition_policy_match"])
assert(fresh_audit["missing_capability_names"].size() == 0)
assert(fresh_audit["missing_board_profile_policy_keys"].size() == 0)
assert(fresh_audit["missing_child_vm_policy_keys"].size() == 0)
assert(fresh_audit["missing_child_vm_partition_policy_keys"].size() == 0)
assert(fresh_audit["duplicates"].size() == 0)
assert(fresh_audit["unknown_statuses"].size() == 0)
var audit_problems = p2compat.audit_problems()
audit_problems.push("__host_audit_problem_mutation_probe__")
assert(p2compat.audit_problems().size() == 0)
var unsupported = p2compat.unsupported()
var saw_captured_closure = false
var saw_live_object = false
for item : unsupported
    if item["name"] == "child_vm_captured_closure_transfer"
        saw_captured_closure = true
    elif item["name"] == "child_vm_live_object_transfer"
        saw_live_object = true
    end
end
assert(saw_captured_closure)
assert(saw_live_object)

var configstore = run_file("modules/configstore.be")
configstore.root = "tmp/p2_host_config/config"
var name = "host_source_modules"

try
    configstore.remove(name)
except .. as e, m
end

assert(configstore.ensure() == "tmp/p2_host_config/config")
assert(os.path.isdir("tmp"))
assert(os.path.isdir("tmp/p2_host_config"))
assert(os.path.isdir(configstore.root))
var config_caps = configstore.capabilities()
assert(config_caps["json_config_files"])
assert(config_caps["filename_only_validation"])
assert(config_caps["load_result"])
assert(config_caps["save_result"])
assert(config_caps["remove_result"])
assert(config_caps["list_result"])
assert(config_caps["json_null_detection"])
assert(config_caps["fat_jso_listing"])
assert(config_caps["audit"])
assert(config_caps["audit_policy"] == "capability_root_result_helper_consistency")
assert(config_caps["root"] == configstore.root)
config_caps["load_result"] = false
assert(configstore.capabilities()["load_result"])
assert(type(configstore.required_capability_keys) == "function")
var config_required_caps = configstore.required_capability_keys()
assert(config_required_caps.find("load_result") >= 0)
assert(config_required_caps.find("root") >= 0)
config_required_caps.push("__host_config_required_mutation_probe__")
assert(configstore.required_capability_keys().find("__host_config_required_mutation_probe__") == nil)
assert(configstore.capability("load_result"))
assert(configstore.capability("root") == configstore.root)
assert(configstore.capability("missing") == nil)
assert(configstore.capability(nil) == nil)
var config_audit = configstore.audit()
assert(config_audit["ok"])
assert(config_audit["problem_count"] == 0)
assert(config_audit["problems"].size() == 0)
assert(config_audit["missing_capability_keys"].size() == 0)
assert(config_audit["root"] == configstore.root)
assert(config_audit["result_helpers"])
assert(config_audit["json_config_files"])
assert(config_audit["filename_only_validation"])
assert(config_audit["ensure_root"])
assert(config_audit["json_null_detection"])
assert(config_audit["fat_jso_listing"])
assert(config_audit["audit_policy"] == "capability_root_result_helper_consistency")
config_audit["problems"].push("__host_config_audit_problem_mutation_probe__")
assert(configstore.audit_problems().size() == 0)
assert(configstore.audit_ok())
assert(configstore.path(name) == "tmp/p2_host_config/config/host_source_modules.json")

var missing_result = configstore.load_result("missing_host_source_modules", {"fallback": true})
assert(missing_result["ok"])
assert(!missing_result["found"])
assert(missing_result["value"]["fallback"])
missing_result["value"]["fallback"] = false
assert(!configstore.exists("missing_host_source_modules"))

var saved_result = configstore.save_result(name, {"answer": 42, "items": [1, 2, 3]})
assert(saved_result["ok"])
assert(saved_result["error"] == nil)
var saved = saved_result["path"]
assert(saved == "tmp/p2_host_config/config/host_source_modules.json")
assert(configstore.exists(name))
var loaded = configstore.load(name, nil)
assert(loaded["answer"] == 42)
assert(loaded["items"][2] == 3)
loaded["answer"] = 99
assert(configstore.load(name, nil)["answer"] == 42)
var loaded_result = configstore.load_result(name, nil)
assert(loaded_result["ok"])
assert(loaded_result["found"])
assert(loaded_result["path"] == saved)
assert(loaded_result["value"]["answer"] == 42)

var saw = false
for entry : configstore.list()
    if entry == "host_source_modules.json"
        saw = true
    end
end
assert(saw)
var list_result = configstore.list_result()
assert(list_result["ok"])
assert(list_result["found"])
assert(list_result["count"] == list_result["items"].size())
var list_saw = false
for entry : list_result["items"]
    if entry == "host_source_modules.json"
        list_saw = true
    end
end
assert(list_saw)

var removed_result = configstore.remove_result(name)
assert(removed_result["ok"])
assert(removed_result["found"])
assert(removed_result["removed"])
assert(removed_result["path"] == saved)
assert(!configstore.exists(name))
var missing_remove_result = configstore.remove_result(name)
assert(missing_remove_result["ok"])
assert(!missing_remove_result["found"])
assert(!missing_remove_result["removed"])
assert(missing_remove_result["path"] == saved)

var bad_json_name = "bad_host_source_modules"
var bad_path = configstore.path(bad_json_name)
var f = open(bad_path, "w")
f.write("{bad json")
f.close()
var bad_result = configstore.load_result(bad_json_name, {"fallback": 1})
assert(!bad_result["ok"])
assert(bad_result["found"])
assert(bad_result["value"]["fallback"] == 1)
assert(bad_result["error"] != nil)
assert(configstore.remove(bad_json_name))

var null_json_name = "null_host_source_modules"
var null_path = configstore.path(null_json_name)
f = open(null_path, "w")
f.write(" \nnull\t")
f.close()
var null_result = configstore.load_result(null_json_name, {"fallback": true})
assert(null_result["ok"])
assert(null_result["found"])
assert(null_result["path"] == null_path)
assert(null_result["value"] == nil)
assert(null_result["error"] == nil)
assert(null_result["message"] == nil)
assert(configstore.remove(null_json_name))

def expect_value_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "value_error")
    end
    assert(caught)
end

expect_value_error(def() return configstore.name(nil) end)
expect_value_error(def() return configstore.name("") end)
expect_value_error(def() return configstore.name("bad/name") end)
var invalid_load_result = configstore.load_result("bad/name", {"fallback": true})
assert(!invalid_load_result["ok"])
assert(!invalid_load_result["found"])
assert(invalid_load_result["path"] == nil)
assert(invalid_load_result["value"]["fallback"])
assert(invalid_load_result["error"] == "value_error")
var invalid_save_result = configstore.save_result("bad/name", {})
assert(!invalid_save_result["ok"])
assert(invalid_save_result["path"] == nil)
assert(invalid_save_result["error"] == "value_error")
var invalid_remove_result = configstore.remove_result("bad/name")
assert(!invalid_remove_result["ok"])
assert(!invalid_remove_result["found"])
assert(!invalid_remove_result["removed"])
assert(invalid_remove_result["path"] == nil)
assert(invalid_remove_result["error"] == "value_error")

var existing_root = configstore.root
configstore.root = "tmp/p2_host_config/missing_config_root"
var missing_list_result = configstore.list_result()
assert(missing_list_result["ok"])
assert(!missing_list_result["found"])
assert(missing_list_result["count"] == 0)
assert(missing_list_result["items"].size() == 0)
configstore.root = existing_root

try
    os.remove(configstore.root)
    os.remove("tmp/p2_host_config")
except .. as e, m
end
