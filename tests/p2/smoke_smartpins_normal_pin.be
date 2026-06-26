print("P2_SMOKE_BEGIN smartpins_normal_pin")

import p2smart

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL smartpins_normal_pin", label)
    end
    assert(cond)
end

var input = p2smart.normal_pin(1, nil, nil)
var output = p2smart.normal_pin(0, nil, 0)

input.start()
output.start()
check(input.info()["kind"] == "NormalPin", "input_kind")
check(output.info()["kind"] == "NormalPin", "output_kind")
check(input.info()["mode"] == p2smart.smart.normal, "input_mode")
check(output.info()["mode"] == p2smart.smart.normal, "output_mode")

var high = output.write_result(1)
p2smart.waitus(100)
var high_read = input.read_result()
check(high["ok"], "high_write_ok")
check(high["value"] == 1, "high_write_value")
check(high_read["ok"], "high_read_ok")
check(high_read["value"] == 1, "high_read_value")

var low = output.write_result(0)
p2smart.waitus(100)
var low_read = input.read_result()
check(low["ok"], "low_write_ok")
check(low["value"] == 0, "low_write_value")
check(low_read["ok"], "low_read_ok")
check(low_read["value"] == 0, "low_read_value")

output.clear()
input.clear()
check(!output.info()["started"], "output_clear")
check(!input.info()["started"], "input_clear")

print("P2_SMOKE_PASS smartpins_normal_pin")
