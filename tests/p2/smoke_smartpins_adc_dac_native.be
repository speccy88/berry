print("P2_SMOKE_BEGIN smartpins_adc_dac_native")

import p2

var smart = p2.smart
var pin = p2.pin
var ADC_SAMPLE_TICKS = 32
var ADC_DELTA_THRESHOLD = 1

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL smartpins_adc_dac_native", label)
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

def sample_adc(in_pin, samples, wait_us)
    var values = []
    var sum = 0
    var minv = nil
    var maxv = nil
    var i = 0
    while i < samples
        if wait_us > 0
            p2.clock.waitus(wait_us)
        end
        var value = smart.rdpin(in_pin)
        smart.akpin(in_pin)
        values.push(value)
        sum += value
        if minv == nil || value < minv
            minv = value
        end
        if maxv == nil || value > maxv
            maxv = value
        end
        i += 1
    end
    return {
        "values": values,
        "avg": sum / samples,
        "min": minv,
        "max": maxv,
        "count": values.size()
    }
end

def adc_dac_case(name, out_pin, in_pin, adc_mode, dac_mode, dac_frame, low_value, high_value, require_delta)
    reset_pair(out_pin, in_pin)
    smart.start(in_pin, adc_mode, ADC_SAMPLE_TICKS, 0)
    smart.start(out_pin, dac_mode, dac_frame, low_value)

    smart.wypin(out_pin, low_value)
    p2.clock.waitus(5000)
    var low = sample_adc(in_pin, 4, 250)

    smart.wypin(out_pin, high_value)
    p2.clock.waitus(5000)
    var high = sample_adc(in_pin, 4, 250)

    var delta = high["avg"] - low["avg"]
    var abs_delta = delta < 0 ? -delta : delta
    var polarity = delta > 0 ? "rising" : (delta < 0 ? "falling" : "flat")

    check(low["count"] == 4, name + "_low_sample_count")
    check(high["count"] == 4, name + "_high_sample_count")
    check(type(low["avg"]) == "int", name + "_low_avg_type")
    check(type(high["avg"]) == "int", name + "_high_avg_type")
    check(type(delta) == "int", name + "_delta_type")
    check(type(abs_delta) == "int", name + "_abs_delta_type")
    print("P2_SMOKE_ADC_DAC_NATIVE", name, true, low["avg"], high["avg"], delta, abs_delta, polarity, ADC_SAMPLE_TICKS)
    if require_delta
        check(abs_delta >= ADC_DELTA_THRESHOLD, name + "_adc_dac_delta")
    end
    reset_pair(out_pin, in_pin)
    return abs_delta
end

var out_pin = 0
var in_pin = 1

var adc_mode = smart.adc_1x + smart.adc
var dac_mode = smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm

adc_dac_case("default", out_pin, in_pin, adc_mode, dac_mode, 256, 0, 255, true)
adc_dac_case("adc_1x_ext_diag", out_pin, in_pin, smart.adc_1x + smart.adc_ext, dac_mode, 256, 0, 255, false)
adc_dac_case("adc_3x_adc_diag", out_pin, in_pin, smart.adc_3x + smart.adc, dac_mode, 256, 0, 255, false)
adc_dac_case("adc_3x_ext_diag", out_pin, in_pin, smart.adc_3x + smart.adc_ext, dac_mode, 256, 0, 255, false)
adc_dac_case("dac_600r_2v_rnd", out_pin, in_pin, adc_mode, smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd, 256, 0, 255, true)

print("P2_SMOKE_PASS smartpins_adc_dac_native")
