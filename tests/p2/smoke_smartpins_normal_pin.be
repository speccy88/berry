print("P2_SMOKE_BEGIN smartpins_normal_pin")

import p2

var smart = p2.smart
var pin = p2.pin

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL smartpins_normal_pin", label)
    end
    assert(cond)
end

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

reset_pin(0)
reset_pin(1)

smart.start(1, smart.normal, 0, 0)
smart.start(0, smart.oe + smart.normal, 0, 0)
pin.dir_high(0)
pin.float(1)

check(smart.normal == 0, "normal_mode")
pin.write(0, 1)
p2.clock.waitus(100)
var high_read = pin.read(1)
check(high_read == 1, "high_read_value")

pin.write(0, 0)
p2.clock.waitus(100)
var low_read = pin.read(1)
check(low_read == 0, "low_read_value")

reset_pin(0)
reset_pin(1)
check(pin.read(1) == 0 || pin.read(1) == 1, "input_readable_after_clear")

print("P2_SMOKE_PASS smartpins_normal_pin")
