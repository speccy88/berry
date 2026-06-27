print("P2_SMOKE_BEGIN smartpins_output_modes")

import p2

var smart = p2.smart
var pin = p2.pin

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL smartpins_output_modes", label)
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

def reset_pair(out_pin, in_pin)
    reset_pin(out_pin)
    reset_pin(in_pin)
end

def count_output(name, out_pin, in_pin, mode, x, y, settle_us, expect_advance)
    reset_pair(out_pin, in_pin)
    smart.start(in_pin, smart.count_highs, 0, 0)
    smart.start(out_pin, smart.oe + mode, x, y)
    var before = smart.rdpin(in_pin)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    var after = smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_OUTPUT", name, before, after, delta)
    reset_pair(out_pin, in_pin)
    if expect_advance
        check(delta > 0, name)
    end
    return delta
end

def trigger_output(name, out_pin, in_pin, mode, x, trigger, settle_us)
    reset_pair(out_pin, in_pin)
    smart.start(in_pin, smart.count_highs, 0, 0)
    smart.start(out_pin, smart.oe + mode, x, 0)
    var before = smart.rdpin(in_pin)
    smart.wypin(out_pin, trigger)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    var after = smart.rdpin(in_pin)
    var delta = after - before
    print("P2_SMOKE_OUTPUT", name, before, after, delta)
    reset_pair(out_pin, in_pin)
    check(delta > 0, name)
end

def nco_duty_shape(out_pin, in_pin, low_duty, high_duty, sample_us, settle_us)
    reset_pair(out_pin, in_pin)
    smart.start(in_pin, smart.count_highs, 0, 0)
    smart.start(out_pin, smart.oe + smart.nco_duty, 1, low_duty)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    var before = smart.rdpin(in_pin)
    if sample_us > 0
        p2.clock.waitus(sample_us)
    end
    var after = smart.rdpin(in_pin)
    var low_delta = after - before
    smart.wypin(out_pin, high_duty)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    before = smart.rdpin(in_pin)
    if sample_us > 0
        p2.clock.waitus(sample_us)
    end
    after = smart.rdpin(in_pin)
    var high_delta = after - before
    var delta = high_delta - low_delta
    print("P2_SMOKE_NCO_DUTY_SHAPE", low_delta, high_delta, delta)
    reset_pair(out_pin, in_pin)
    check(low_delta > 0, "nco_duty_shape_low")
    check(high_delta > low_delta, "nco_duty_shape_high")
    return delta
end

def pwm_duty_shape(name, out_pin, in_pin, mode, low_duty, high_duty, sample_us, settle_us)
    reset_pair(out_pin, in_pin)
    smart.start(in_pin, smart.count_highs, 0, 0)
    smart.start(out_pin, smart.oe + mode, 200 * 65536 + 1, low_duty)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    var before = smart.rdpin(in_pin)
    if sample_us > 0
        p2.clock.waitus(sample_us)
    end
    var after = smart.rdpin(in_pin)
    var low_delta = after - before
    smart.wypin(out_pin, high_duty)
    if settle_us > 0
        p2.clock.waitus(settle_us)
    end
    before = smart.rdpin(in_pin)
    if sample_us > 0
        p2.clock.waitus(sample_us)
    end
    after = smart.rdpin(in_pin)
    var high_delta = after - before
    var delta = high_delta - low_delta
    print("P2_SMOKE_PWM_DUTY_SHAPE", name, low_delta, high_delta, delta)
    reset_pair(out_pin, in_pin)
    check(low_delta > 0, name + "_shape_low")
    check(high_delta > low_delta, name + "_shape_high")
    return delta
end

var out_pin = 0
var in_pin = 1

check(smart.pwm_triangle == 0x10, "pwm_triangle_const")
check(smart.pwm_sawtooth == 0x12, "pwm_sawtooth_const")
check(smart.pwm_smps == 0x14, "pwm_smps_const")
check(smart.nco_freq == 0x0c, "nco_freq_const")
check(smart.nco_duty == 0x0e, "nco_duty_const")
check(smart.pulse == 0x08, "pulse_const")
check(smart.transition == 0x0a, "transition_const")

count_output("pwm_triangle", out_pin, in_pin, smart.pwm_triangle, 200 * 65536 + 1, 100, 2000, true)
count_output("pwm_sawtooth", out_pin, in_pin, smart.pwm_sawtooth, 200 * 65536 + 1, 100, 2000, true)
count_output("pwm_smps", out_pin, in_pin, smart.pwm_smps, 200 * 65536 + 1, 100, 2000, true)
pwm_duty_shape("pwm_triangle", out_pin, in_pin, smart.pwm_triangle, 50, 150, 5000, 1000)
pwm_duty_shape("pwm_sawtooth", out_pin, in_pin, smart.pwm_sawtooth, 50, 150, 5000, 1000)
pwm_duty_shape("pwm_smps", out_pin, in_pin, smart.pwm_smps, 50, 150, 5000, 1000)
count_output("nco_freq", out_pin, in_pin, smart.nco_freq, 16000, 0x20000000, 2000, true)
var nco_duty_delta = count_output("nco_duty", out_pin, in_pin, smart.nco_duty, 1, 0x40000000, 2000, true)
print("P2_SMOKE_NCO_DUTY_NATIVE", nco_duty_delta)
nco_duty_shape(out_pin, in_pin, 0x20000000, 0x60000000, 5000, 1000)
trigger_output("pulse", out_pin, in_pin, smart.pulse, 100 * 65536 + 200, 8, 2000)
trigger_output("transition", out_pin, in_pin, smart.transition, 100, 8, 2000)

reset_pair(out_pin, in_pin)

print("P2_SMOKE_PASS smartpins_output_modes")
