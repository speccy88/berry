print("P2_SMOKE_BEGIN smartpins_adc_variant_matrix")

import p2

var smart = p2.smart
var pin = p2.pin

def reset_pin(no)
    smart.clear(no)
    smart.wrpin(no, 0)
    smart.wxpin(no, 0)
    smart.wypin(no, 0)
    smart.akpin(no)
    pin.float(no)
end

def sample_adc(in_pin)
    var sum = 0
    var i = 0
    while i < 4
        p2.clock.waitus(250)
        sum += smart.rdpin(in_pin)
        smart.akpin(in_pin)
        i += 1
    end
    return sum / 4
end

def probe_pair(name, out_pin, in_pin, adc_mode, sample_ticks, low_value, high_value)
    reset_pin(out_pin)
    reset_pin(in_pin)
    smart.start(in_pin, adc_mode, sample_ticks, 0)
    smart.start(out_pin, smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm, 256, low_value)
    smart.wypin(out_pin, low_value)
    p2.clock.waitus(5000)
    var low = sample_adc(in_pin)
    smart.wypin(out_pin, high_value)
    p2.clock.waitus(5000)
    var high = sample_adc(in_pin)
    print("P2_SMOKE_ADC_VARIANT", name, out_pin, in_pin, sample_ticks, low_value, high_value, low, high, high - low)
    reset_pin(out_pin)
    reset_pin(in_pin)
    return high - low
end

def probe_range(name, adc_mode, sample_ticks, low_value, high_value)
    return probe_pair(name, 0, 1, adc_mode, sample_ticks, low_value, high_value)
end

def probe(name, adc_mode, sample_ticks)
    return probe_range(name, adc_mode, sample_ticks, 0, 255)
end

var default_delta = probe("1x_adc", smart.adc_1x + smart.adc, 32)
probe("1x_adc_256", smart.adc_1x + smart.adc, 256)
probe("3x_adc", smart.adc_3x + smart.adc, 32)
probe_range("3x_adc_0_64", smart.adc_3x + smart.adc, 32, 0, 64)
probe_range("3x_adc_0_32", smart.adc_3x + smart.adc, 32, 0, 32)
probe_range("3x_adc_32_96", smart.adc_3x + smart.adc, 32, 32, 96)
probe("3x_adc_256", smart.adc_3x + smart.adc, 256)
probe("10x_adc", smart.adc_10x + smart.adc, 32)
probe_range("10x_adc_0_16", smart.adc_10x + smart.adc, 32, 0, 16)
probe_range("10x_adc_0_8", smart.adc_10x + smart.adc, 32, 0, 8)
probe("1x_ext", smart.adc_1x + smart.adc_ext, 32)
probe_pair("1x_ext_rev", 1, 0, smart.adc_1x + smart.adc_ext, 32, 0, 255)
probe("1x_scope", smart.adc_1x + smart.adc_scope, 32)

var default_abs = default_delta < 0 ? -default_delta : default_delta
assert(default_abs > 0)
print("P2_SMOKE_PASS smartpins_adc_variant_matrix")
