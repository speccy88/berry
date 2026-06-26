print("P2_SMOKE_BEGIN smartpins_quadrature_static")

import p2smart

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL smartpins_quadrature_static", label)
    end
    assert(cond)
end

var quad = p2smart.quadrature(0, 1, nil)
var info = quad.info()
check(info["kind"] == "Quadrature", "kind")
check(info["pin_a"] == 0, "pin_a")
check(info["pin_b"] == 1, "pin_b")
check(info["mode"] == p2smart.smart.quadrature + p2smart.smart.plus1_b, "mode")
check(!info["started"], "not_started")

quad.start()
check(quad.info()["started"], "started")

var sample = quad.sample_after(1000)
check(sample["ok"], "sample_ok")
check(sample["pin_a"] == 0, "sample_pin_a")
check(sample["pin_b"] == 1, "sample_pin_b")
check(sample["mode"] == info["mode"], "sample_mode")
check(type(sample["before"]) == "int", "sample_before_int")
check(type(sample["after"]) == "int", "sample_after_int")
check(type(sample["delta"]) == "int", "sample_delta_int")
check(sample["wait_us"] == 1000, "sample_wait_us")
check(sample["moved"] == (sample["delta"] != 0), "sample_moved_shape")
check(sample["direction"] == (sample["delta"] > 0 ? 1 : (sample["delta"] < 0 ? -1 : 0)), "sample_direction_shape")

quad.ack()
quad.clear()
check(!quad.info()["started"], "cleared")
check(p2smart.status("quadrature") == "setup_only", "status_honest")

print("P2_SMOKE_PASS smartpins_quadrature_static")
