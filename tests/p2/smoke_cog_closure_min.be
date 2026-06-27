print("P2_SMOKE_BEGIN cog_closure_min")

import p2

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL cog_closure_min", label)
    end
    assert(cond)
end

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

var caps = p2.cog.capabilities()
check(caps["spawn"], "spawn_capability")
check(caps["native_blink"], "native_blink_capability")
check(caps["handle_model"] == "native_blink_info_stop_only", "handle_model")
check(p2.cog.audit_ok(), "audit_ok")
check(p2.cog.info().size() == 0, "initial_empty")

var handle = p2.cog.spawn(blinker, 38, 120)
check(handle >= 100, "handle_range")

var info = p2.cog.info(handle)
check(info["handle"] == handle, "info_handle")
check(info["kind"] == "closure", "info_kind")
check(info["model"] == "native_blink", "info_model")
check(info["native_blink"], "info_native_blink")
check(info["native_pin"] == 38, "info_pin")
check(info["period_ms"] == 120, "info_period")
check(info["last_result_int"] == 120, "info_result")
check(info["stack_bytes"] == 2048, "info_stack")

var joined = p2.cog.join(handle)
check(joined["handle"] == handle, "join_handle")
check(!joined["blocking"], "join_nonblocking")
check(joined["join_policy"] == "nonblocking_status_snapshot", "join_policy")
check(joined["result_type_name"] == "int", "join_result_type")
check(joined["result"] == 120, "join_result")
check(joined["error"] == "", "join_error")
check(p2.cog.result(handle) == 120, "result_helper")
check(p2.cog.error(handle) == nil, "error_helper")

var cleanup = p2.cog.kill(handle)
check(cleanup["handle"] == handle, "cleanup_handle")
check(cleanup["cleanup_attempted"], "cleanup_attempted")
check(cleanup["slot_released"], "cleanup_slot")
check(!cleanup["handle_valid_after_stop"], "cleanup_invalid")
check(p2.cog.info().size() == 0, "cleanup_empty")

p2.pin.float(38)

print("P2_SMOKE_PASS cog_closure_min")
