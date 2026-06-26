print("P2_SMOKE_BEGIN cog_closure")

import p2

assert(type(p2.cog.required_capability_keys) == "function")
assert(type(p2.cog.audit) == "function")
assert(type(p2.cog.audit_problems) == "function")
assert(type(p2.cog.audit_ok) == "function")
var caps = p2.cog.capabilities()
var required_caps = p2.cog.required_capability_keys()
assert(required_caps.find("spawn") >= 0)
assert(required_caps.find("handle_model") >= 0)
assert(required_caps.find("handle_join_result_policy") >= 0)
required_caps.push("mutated")
assert(p2.cog.required_capability_keys().find("mutated") == nil)
assert(caps["spawn"] == true)
assert(caps["native_blink"] == true)
assert(caps["native_blink_stack"] == 2048)
assert(caps["handle_base"] == 100)
assert(caps["max_handles"] >= 2)
assert(caps["handle_model"] == "native_blink_info_stop_only")
assert(caps["handle_id"] == true)
assert(caps["handle_info"] == true)
assert(caps["handle_status"] == true)
assert(caps["handle_stop"] == true)
assert(caps["handle_result"] == true)
assert(caps["handle_error"] == true)
assert(caps["handle_join"] == true)
assert(caps["handle_kill"] == true)
assert(caps["handle_status_policy"] == "status_aliases_info_map")
assert(caps["handle_join_policy"] == "nonblocking_status_snapshot")
assert(caps["handle_join_result_policy"] == "result_and_error_fields_in_join_snapshot")
assert(caps["handle_kill_policy"] == "force_stop_cleanup_alias")
assert(caps["handle_cleanup_policy"] == "stop_releases_stack_mailbox_source_slot")
assert(caps["handle_result_policy"] == "last_result_value_nonblocking")
assert(caps["handle_error_policy"] == "last_error_string_nonblocking")
assert(caps["reject_unsupported"] == true)
assert(caps["unsafe_shared_vm"] == false)
assert(caps["isolated_vm_closure"] == false)
var audit = p2.cog.audit()
assert(audit["ok"])
assert(audit["problem_count"] == 0)
assert(audit["problems"].size() == 0)
assert(audit["missing_capability_keys"].size() == 0)
assert(audit["handle_model"] == caps["handle_model"])
assert(audit["handle_join_policy"] == caps["handle_join_policy"])
assert(audit["handle_cleanup_policy"] == caps["handle_cleanup_policy"])
assert(audit["unsafe_shared_vm"] == caps["unsafe_shared_vm"])
assert(audit["reject_unsupported"] == caps["reject_unsupported"])
assert(p2.cog.audit_ok())
assert(p2.cog.audit_problems().size() == 0)
audit["problems"].push("mutated")
assert(p2.cog.audit()["problems"].size() == 0)

def maplike(value)
    var kind = type(value)
    return kind == "map" || kind == "instance"
end

def listlike(value)
    var kind = type(value)
    return kind == "list" || kind == "instance"
end

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL cog_closure", label)
    end
    assert(cond)
end

# Default firmware supports the hardware-safe p38/p39 closure-spawn shape:
# p2.cog.spawn(closure, pin, rate_ms). The passed closure is invoked once
# during setup and must return a positive delay. The spawned cog then runs the
# native blinker loop and can be inspected/stopped by handle. The reported
# calls count is the native blink-loop counter; when sampled immediately after
# spawn it may still be zero on a slow board/startup path.

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

var h38 = p2.cog.spawn(blinker, 38, 120)
var h39 = p2.cog.spawn(blinker, 39, 250)

check(h38 >= 100, "h38_handle")
check(h39 >= 100, "h39_handle")
check(h38 != h39, "distinct_handles")

var i38 = p2.cog.info(h38)
var i39 = p2.cog.info(h39)
var st38 = p2.cog.status(h38)
var st39 = p2.cog.status(h39)
var j38 = p2.cog.join(h38)
var j39 = p2.cog.join(h39)
var all = p2.cog.info()
var saw38 = false
var saw39 = false

check(maplike(i38), "i38_maplike")
check(maplike(i39), "i39_maplike")
check(maplike(st38), "st38_maplike")
check(maplike(st39), "st39_maplike")
check(maplike(j38), "j38_maplike")
check(maplike(j39), "j39_maplike")
check(i38["handle"] == h38, "i38_handle")
check(i39["handle"] == h39, "i39_handle")
check(st38["handle"] == h38, "st38_handle")
check(st39["handle"] == h39, "st39_handle")
check(j38["handle"] == h38, "j38_handle")
check(j39["handle"] == h39, "j39_handle")
check(j38["blocking"] == false, "j38_nonblocking")
check(j39["blocking"] == false, "j39_nonblocking")
check(j38["join_policy"] == "nonblocking_status_snapshot", "j38_policy")
check(j39["join_policy"] == "nonblocking_status_snapshot", "j39_policy")
check(j38["result_type_name"] == "int", "j38_result_type")
check(j39["result_type_name"] == "int", "j39_result_type")
check(j38["result"] == 120, "j38_result")
check(j39["result"] == 250, "j39_result")
check(j38["error"] == "", "j38_error")
check(j39["error"] == "", "j39_error")
check(p2.cog.id(h38) == i38["cog"], "h38_cog_id")
check(p2.cog.id(h39) == i39["cog"], "h39_cog_id")
check(i38["kind"] == "closure", "i38_kind")
check(i39["kind"] == "closure", "i39_kind")
check(i38["model"] == "native_blink", "i38_model")
check(i39["model"] == "native_blink", "i39_model")
check(i38["native_blink"] == true, "i38_native_blink")
check(i39["native_blink"] == true, "i39_native_blink")
check(i38["repl_idle_only"] == false, "i38_repl_idle_only")
check(i39["repl_idle_only"] == false, "i39_repl_idle_only")
check(i38["native_pin"] == 38, "i38_native_pin")
check(i39["native_pin"] == 39, "i39_native_pin")
check(i38["period_ms"] == 120, "i38_period_ms")
check(i39["period_ms"] == 250, "i39_period_ms")
check(i38["last_result_int"] == 120, "i38_last_result")
check(i39["last_result_int"] == 250, "i39_last_result")
check(p2.cog.result(h38) == 120, "h38_result")
check(p2.cog.result(h39) == 250, "h39_result")
check(p2.cog.error(h38) == nil, "h38_error")
check(p2.cog.error(h39) == nil, "h39_error")
check(i38["stack_bytes"] == 2048, "i38_stack_bytes")
check(i39["stack_bytes"] == 2048, "i39_stack_bytes")
check(type(i38["calls"]) == "int" && i38["calls"] >= 0, "i38_calls")
check(type(i39["calls"]) == "int" && i39["calls"] >= 0, "i39_calls")
check(listlike(all), "info_list")
check(all.size() >= 2, "info_size")

for item : all
    if item["handle"] == h38
        saw38 = true
    elif item["handle"] == h39
        saw39 = true
    end
end
check(saw38, "saw38")
check(saw39, "saw39")

var s38 = p2.cog.stop(h38)
var s39 = p2.cog.kill(h39)
check(s38["handle"] == h38, "s38_handle")
check(s39["handle"] == h39, "s39_handle")
check(s38["running"] == false, "s38_running")
check(s39["running"] == false, "s39_running")
check(s38["raw_running"] == false, "s38_raw_running")
check(s39["raw_running"] == false, "s39_raw_running")
check(s38["cleanup_attempted"] == true, "s38_cleanup_attempted")
check(s39["cleanup_attempted"] == true, "s39_cleanup_attempted")
check(s38["cleanup_policy"] == "stop_releases_stack_mailbox_source_slot", "s38_cleanup_policy")
check(s39["cleanup_policy"] == "stop_releases_stack_mailbox_source_slot", "s39_cleanup_policy")
check(s38["slot_released"] == true, "s38_slot_released")
check(s39["slot_released"] == true, "s39_slot_released")
check(s38["handle_valid_after_stop"] == false, "s38_handle_invalid_after_stop")
check(s39["handle_valid_after_stop"] == false, "s39_handle_invalid_after_stop")
check(p2.cog.info().size() == 0, "stopped_empty")

def tick()
    return 10
end

var rejected = false
try
    p2.cog.spawn(tick)
except .. as e
    rejected = type(e) == "string" || type(e) == "nil" || type(e) == "instance"
end
check(rejected, "unsupported_rejected")
check(p2.cog.info().size() == 0, "rejected_empty")

p2.pin.float(38)
p2.pin.float(39)

print("P2_SMOKE_PASS cog_closure")
