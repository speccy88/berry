import introspect

var p2 = module("p2")
var smart = module("p2.smart")
var pin = module("p2.pin")
var calls = []

smart.oe = 0x40
smart.channel = 0x40
smart.bitdac = 0x80
smart.sync_io = 0x10000
smart.invert_in = 0x8000
smart.invert_output = 0x4000
smart.pwm_triangle = 0x10
smart.pwm_sawtooth = 0x12
smart.pwm_smps = 0x14
smart.nco_freq = 0x0c
smart.nco_duty = 0x0e
smart.pulse = 0x08
smart.transition = 0x0a
smart.count_rises = 0x1c
smart.count_highs = 0x1e
smart.reg_up = 0x18
smart.reg_up_down = 0x1a
smart.state_ticks = 0x20
smart.high_ticks = 0x22
smart.events_ticks = 0x24
smart.periods_ticks = 0x26
smart.periods_highs = 0x28
smart.counter_ticks = 0x2a
smart.counter_highs = 0x2c
smart.counter_periods = 0x2e
smart.repository = 0x02
smart.dac_noise = 0x02
smart.dac_dither_rnd = 0x04
smart.adc_1x = 0x118000
smart.adc_gio = 0x100000
smart.adc_vio = 0x108000
smart.adc_float = 0x110000
smart.adc_3x = 0x120000
smart.adc_10x = 0x128000
smart.adc_30x = 0x130000
smart.adc_100x = 0x138000
smart.adc = 0x30
smart.adc_ext = 0x32
smart.adc_scope = 0x34
smart.usb_pair = 0x36
smart.dac_990r_3v = 0x140000
smart.dac_600r_2v = 0x150000
smart.dac_124r_3v = 0x160000
smart.dac_75r_2v = 0x170000
smart.dac_dither_pwm = 0x06
smart.sync_tx = 0x38
smart.sync_rx = 0x3a
smart.async_tx = 0x3c
smart.async_rx = 0x3e
smart.plus1_a = 0x10000000
smart.plus2_a = 0x20000000
smart.plus3_a = 0x30000000
smart.outbit_a = 0x40000000
smart.minus3_a = 0x50000000
smart.minus2_a = 0x60000000
smart.minus1_a = 0x70000000
smart.plus1_b = 0x01000000
smart.plus2_b = 0x02000000
smart.plus3_b = 0x03000000
smart.true_b = 0x00000000
smart.invert_b = 0x08000000
smart.local_b = 0x00000000
smart.outbit_b = 0x04000000
smart.minus3_b = 0x05000000
smart.minus2_b = 0x06000000
smart.minus1_b = 0x07000000
smart.and_ab = 0x200000
smart.or_ab = 0x400000
smart.xor_ab = 0x600000
smart.filt0_ab = 0x800000
smart.filt1_ab = 0xa00000
smart.filt2_ab = 0xc00000
smart.filt3_ab = 0xe00000
smart.logic_a_fb = 0x20000
smart.logic_b_fb = 0x40000
smart.schmitt_a = 0x60000
smart.schmitt_a_fb = 0x80000
smart.schmitt_b_fb = 0xa0000
smart.compare_ab = 0xc0000
smart.compare_ab_fb = 0xe0000
smart.high_1k5 = 0x800
smart.high_15k = 0x1000
smart.high_150k = 0x1800
smart.high_1ma = 0x2000
smart.high_100ua = 0x2800
smart.high_10ua = 0x3000
smart.high_float = 0x3800
smart.low_1k5 = 0x100
smart.low_15k = 0x200
smart.low_150k = 0x300
smart.low_1ma = 0x400
smart.low_100ua = 0x500
smart.low_10ua = 0x600
smart.low_float = 0x700
smart.tt_01 = 0x40
smart.tt_10 = 0x80
smart.tt_11 = 0xc0
smart.level_a = 0x180000
smart.level_a_fbn = 0x1a0000
smart.level_b_fbp = 0x1c0000
smart.level_b_fbn = 0x1e0000
smart.normal = 0x00
smart.quadrature = 0x16
smart.rq_value = 0
smart.rd_value = 0
var clock = module("p2.clock")

smart.start = def(pin_no, mode, x, y)
    calls.push(["smart.start", pin_no, mode, x, y])
end
smart.wrpin = def(pin_no, value)
    calls.push(["smart.wrpin", pin_no, value])
end
smart.wypin = def(pin_no, value)
    calls.push(["smart.wypin", pin_no, value])
end
smart.wxpin = def(pin_no, value)
    calls.push(["smart.wxpin", pin_no, value])
end
smart.clear = def(pin_no)
    calls.push(["smart.clear", pin_no])
end
smart.akpin = def(pin_no)
    calls.push(["smart.akpin", pin_no])
end
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    return smart.rq_value
end

pin.dir_high = def(pin_no)
    calls.push(["pin.dir_high", pin_no])
end
pin.dir_low = def(pin_no)
    calls.push(["pin.dir_low", pin_no])
end
pin.write = def(pin_no, value)
    calls.push(["pin.write", pin_no, value])
end
pin.low = def(pin_no)
    calls.push(["pin.low", pin_no])
end
pin.high = def(pin_no)
    calls.push(["pin.high", pin_no])
end
pin.toggle = def(pin_no)
    calls.push(["pin.toggle", pin_no])
end
pin.float = def(pin_no)
    calls.push(["pin.float", pin_no])
end
pin.read_value = 0
pin.read = def(pin_no)
    calls.push(["pin.read", pin_no])
    return pin.read_value
end

p2.smart = smart
p2.pin = pin
p2.clock = clock
p2.waitus = def(us)
    calls.push(["waitus", us])
end
clock.freq = def()
    calls.push(["clock.freq"])
    return 200000000
end
introspect.setmodule("p2", p2)

def reset_calls()
    calls.clear()
end

def expect_error(fn)
    var caught = false
    try
        fn()
    except .. as e, m
        caught = true
    end
    assert(caught)
end

def list_has(items, needle)
    for item : items
        if item == needle
            return true
        end
    end
    return false
end

var p2smart = run_file("modules/p2smart.be")
assert(type(p2smart) == "module")
assert(type(p2smart.GPIOInput) == "class")
assert(type(p2smart.GPIOOutput) == "class")
assert(type(p2smart.NormalPin) == "class")
assert(type(p2smart.Counter) == "class")
assert(type(p2smart.Quadrature) == "class")
assert(type(p2smart.Repository) == "class")
assert(type(p2smart.PWM) == "class")
assert(type(p2smart.NCO) == "class")
assert(type(p2smart.NCODuty) == "class")
assert(type(p2smart.Pulse) == "class")
assert(type(p2smart.Transition) == "class")
assert(type(p2smart.AsyncSerialPair) == "class")
assert(type(p2smart.SyncSerialPair) == "class")
assert(type(p2smart.ADC) == "class")
assert(type(p2smart.DAC) == "class")
assert(p2smart.smart.plus2_a == 0x20000000)
assert(p2smart.smart.minus2_a == 0x60000000)
assert(p2smart.smart.outbit_b == 0x04000000)
assert(p2smart.smart.xor_ab == 0x600000)
assert(p2smart.smart.schmitt_a == 0x60000)
assert(p2smart.smart.high_150k == 0x1800)
assert(p2smart.smart.low_100ua == 0x500)
assert(p2smart.smart.dac_noise == 0x02)
assert(p2smart.smart.dac_dither_rnd == 0x04)
assert(p2smart.smart.nco_duty == 0x0e)
assert(p2smart.smart.pwm_sawtooth == 0x12)
assert(p2smart.smart.pwm_smps == 0x14)
assert(p2smart.smart.reg_up == 0x18)
assert(p2smart.smart.reg_up_down == 0x1a)
assert(p2smart.smart.state_ticks == 0x20)
assert(p2smart.smart.events_ticks == 0x24)
assert(p2smart.smart.counter_periods == 0x2e)
assert(p2smart.smart.adc_gio == 0x100000)
assert(p2smart.smart.adc_ext == 0x32)
assert(p2smart.smart.adc_scope == 0x34)
assert(p2smart.smart.usb_pair == 0x36)
assert(p2smart.smart.dac_600r_2v == 0x150000)
var default_pairs = p2smart.default_jumper_pairs()
assert(default_pairs == [[0, 1], [2, 3], [4, 5], [6, 7]])
default_pairs[0][0] = 99
default_pairs.push([8, 9])
assert(p2smart.default_jumper_pairs() == [[0, 1], [2, 3], [4, 5], [6, 7]])
var default_directions = p2smart.default_jumper_directions()
assert(default_directions == [[0, 1], [1, 0], [2, 3], [3, 2], [4, 5], [5, 4], [6, 7], [7, 6]])
default_directions[0][0] = 99
default_directions.push([8, 9])
assert(p2smart.default_jumper_directions() == [[0, 1], [1, 0], [2, 3], [3, 2], [4, 5], [5, 4], [6, 7], [7, 6]])
var default_clocked_groups = p2smart.default_clocked_jumper_groups()
assert(default_clocked_groups == [[0, 1, 2, 3], [4, 5, 6, 7]])
default_clocked_groups[0][0] = 99
default_clocked_groups.push([8, 9, 10, 11])
assert(p2smart.default_clocked_jumper_groups() == [[0, 1, 2, 3], [4, 5, 6, 7]])
var jumper_checks = p2smart.jumper_pair_checks()
assert(jumper_checks == ["raw_out", "raw_in", "gpio", "high_counter", "pulse_counter", "transition_counter", "async_serial", "async_serial_drain"])
jumper_checks.push("mutated")
assert(!list_has(p2smart.jumper_pair_checks(), "mutated"))
var caps = p2smart.capabilities()
assert(caps["gpio"] == "verified")
assert(caps["gpio_diagnostics"] == "diagnostic")
assert(caps["gpio_loopback_probe"] == "diagnostic")
assert(caps["jumper_pair_probe"] == "diagnostic")
assert(caps["jumper_pair_checks"] == "diagnostic")
assert(caps["jumper_pairs_probe"] == "diagnostic")
assert(caps["default_jumper_pairs"] == "diagnostic")
assert(caps["default_jumper_directions"] == "diagnostic")
assert(caps["default_clocked_jumper_groups"] == "diagnostic")
assert(caps["default_jumper_pairs_probe"] == "diagnostic")
assert(caps["jumper_pairs_bidirectional_probe"] == "diagnostic")
assert(caps["default_jumper_pairs_bidirectional_probe"] == "diagnostic")
assert(caps["normal_pin"] == "verified")
assert(caps["normal_pin_diagnostics"] == "diagnostic")
assert(caps["raw_smartpin_probe"] == "diagnostic")
assert(caps["async_serial_zero_byte"] == "verified")
assert(caps["async_serial_paced_exchange"] == "verified")
assert(caps["async_serial_probe"] == "diagnostic")
assert(caps["async_serial_drain"] == "diagnostic")
assert(caps["async_serial_drain_probe"] == "diagnostic")
assert(caps["async_serial_buffer_policy"] == "diagnostic")
assert(caps["counter_sample_diagnostics"] == "diagnostic")
assert(caps["counter_variant_sample_probe"] == "diagnostic")
assert(caps["counter_variant_drive_probe"] == "diagnostic")
assert(caps["counter_variant_drive_modes_probe"] == "diagnostic")
assert(caps["high_counter_probe"] == "diagnostic")
assert(caps["counter_mode_variants"] == "setup_only")
assert(caps["repository_write_diagnostics"] == "diagnostic")
assert(caps["repository_read_diagnostics"] == "diagnostic")
assert(caps["repository_probe"] == "diagnostic")
assert(caps["pwm_duty_diagnostics"] == "diagnostic")
assert(caps["pwm_counter_probe"] == "diagnostic")
assert(caps["pwm_variant_counter_probe"] == "diagnostic")
assert(caps["pwm_mode_variants"] == "setup_only")
assert(caps["nco_increment_diagnostics"] == "diagnostic")
assert(caps["nco_counter_probe"] == "diagnostic")
assert(caps["nco_duty"] == "setup_only")
assert(caps["nco_duty_diagnostics"] == "diagnostic")
assert(caps["nco_duty_counter_probe"] == "diagnostic")
assert(caps["pulse_trigger_diagnostics"] == "diagnostic")
assert(caps["pulse_counter_probe"] == "diagnostic")
assert(caps["transition_trigger_diagnostics"] == "diagnostic")
assert(caps["transition_counter_probe"] == "diagnostic")
assert(caps["adc_mode_variants"] == "setup_only")
assert(caps["adc_variant_sample_probe"] == "diagnostic")
assert(caps["adc_variant_dac_sampled_probe"] == "verified")
assert(caps["dac_mode_variants"] == "setup_only")
assert(caps["dac_variant_adc_probe"] == "diagnostic")
assert(caps["dac_variant_adc_sampled_probe"] == "verified")
assert(caps["adc_dac_variants_sampled_probe"] == "verified")
assert(caps["adc_dac_delta_policy"] == "diagnostic")
assert(caps["async_serial_buffer"] == "unsupported")
assert(caps["sync_serial_result_diagnostics"] == "staged")
assert(caps["sync_serial_transfer_diagnostics"] == "staged")
assert(caps["sync_serial_probe"] == "staged")
assert(caps["sync_serial_clocked_probe"] == "staged")
assert(caps["sync_serial_clocked_jumper_probes"] == "staged")
assert(caps["sync_serial_default_clocked_probe"] == "staged")
assert(caps["sync_serial_receive_policy"] == "diagnostic")
assert(caps["sync_serial_receive"] == "unverified")
assert(caps["adc_dac_probe"] == "diagnostic")
assert(caps["adc_dac_sampled_probe"] == "verified")
assert(caps["adc_dac_delta"] == "unverified")
assert(caps["quadrature_sample_diagnostics"] == "diagnostic")
assert(caps["quadrature_sample_probe"] == "diagnostic")
assert(caps["adc_sample_diagnostics"] == "diagnostic")
assert(caps["dac_set_diagnostics"] == "diagnostic")
assert(caps["usb_pair"] == "unsupported")
caps["gpio"] = "mutated"
assert(p2smart.capabilities()["gpio"] == "verified")
assert(type(p2smart.required_capability_keys) == "function")
var required_caps = p2smart.required_capability_keys()
assert(list_has(required_caps, "gpio"))
assert(list_has(required_caps, "async_serial_drain_probe"))
assert(list_has(required_caps, "sync_serial_receive_policy"))
assert(list_has(required_caps, "sync_serial_receive"))
assert(list_has(required_caps, "usb_pair"))
required_caps.push("mutated")
assert(!list_has(p2smart.required_capability_keys(), "mutated"))
var status_names = p2smart.statuses()
assert(list_has(status_names, "verified"))
assert(list_has(status_names, "staged"))
assert(list_has(status_names, "unsupported"))
assert(p2smart.status_known("verified"))
assert(p2smart.status_known("setup_readback"))
assert(!p2smart.status_known("missing"))
assert(!p2smart.status_known(nil))
assert(p2smart.status("gpio") == "verified")
assert(p2smart.status("normal_pin") == "verified")
assert(p2smart.status("sync_serial_receive") == "unverified")
assert(p2smart.status("usb_pair") == "unsupported")
assert(p2smart.status("missing") == nil)
assert(p2smart.status(nil) == nil)
status_names.push("mutated")
assert(!list_has(p2smart.statuses(), "mutated"))
var capability_names = p2smart.names()
assert(list_has(capability_names, "gpio"))
assert(list_has(capability_names, "sync_serial_receive"))
assert(list_has(capability_names, "sync_serial_transfer_diagnostics"))
assert(list_has(capability_names, "sync_serial_clocked_jumper_probes"))
assert(list_has(capability_names, "usb_pair"))
capability_names.push("mutated")
assert(!list_has(p2smart.names(), "mutated"))
var verified_items = p2smart.items_by_status("verified")
assert(list_has(verified_items, "gpio"))
assert(list_has(verified_items, "async_serial_paced_exchange"))
assert(!list_has(verified_items, "sync_serial_receive"))
verified_items.push("mutated")
assert(!list_has(p2smart.items_by_status("verified"), "mutated"))
assert(list_has(p2smart.names_by_status("verified"), "gpio"))
assert(list_has(p2smart.names_by_status("unsupported"), "usb_pair"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_result_diagnostics"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_transfer_diagnostics"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_probe"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_clocked_probe"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_clocked_jumper_probes"))
assert(list_has(p2smart.items_by_status("staged"), "sync_serial_default_clocked_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "counter_sample_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "counter_variant_sample_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "counter_variant_drive_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "counter_variant_drive_modes_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "repository_write_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "gpio_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "gpio_loopback_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "jumper_pair_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "jumper_pair_checks"))
assert(list_has(p2smart.items_by_status("diagnostic"), "jumper_pairs_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "default_jumper_pairs"))
assert(list_has(p2smart.items_by_status("diagnostic"), "default_jumper_directions"))
assert(list_has(p2smart.items_by_status("diagnostic"), "default_clocked_jumper_groups"))
assert(list_has(p2smart.items_by_status("diagnostic"), "default_jumper_pairs_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "jumper_pairs_bidirectional_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "default_jumper_pairs_bidirectional_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "normal_pin_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "raw_smartpin_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "quadrature_sample_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "quadrature_sample_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "adc_sample_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "adc_variant_sample_probe"))
assert(list_has(p2smart.items_by_status("verified"), "adc_dac_sampled_probe"))
assert(list_has(p2smart.items_by_status("verified"), "adc_variant_dac_sampled_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "dac_set_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "dac_variant_adc_probe"))
assert(list_has(p2smart.items_by_status("verified"), "dac_variant_adc_sampled_probe"))
assert(list_has(p2smart.items_by_status("verified"), "adc_dac_variants_sampled_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "adc_dac_delta_policy"))
assert(list_has(p2smart.items_by_status("diagnostic"), "pwm_duty_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "high_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "repository_read_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "repository_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "pwm_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "pwm_variant_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "nco_increment_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "nco_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "nco_duty_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "nco_duty_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "pulse_trigger_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "pulse_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "transition_trigger_diagnostics"))
assert(list_has(p2smart.items_by_status("diagnostic"), "transition_counter_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "async_serial_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "async_serial_drain"))
assert(list_has(p2smart.items_by_status("diagnostic"), "async_serial_drain_probe"))
assert(list_has(p2smart.items_by_status("diagnostic"), "async_serial_buffer_policy"))
assert(list_has(p2smart.items_by_status("diagnostic"), "sync_serial_receive_policy"))
assert(list_has(p2smart.items_by_status("verified"), "normal_pin"))
assert(list_has(p2smart.items_by_status("setup_only"), "counter_mode_variants"))
assert(list_has(p2smart.items_by_status("setup_only"), "pwm_mode_variants"))
assert(list_has(p2smart.items_by_status("setup_only"), "nco_duty"))
assert(list_has(p2smart.items_by_status("setup_only"), "adc_mode_variants"))
assert(list_has(p2smart.items_by_status("setup_only"), "dac_mode_variants"))
assert(list_has(p2smart.items_by_status("unverified"), "sync_serial_receive"))
assert(list_has(p2smart.items_by_status("unsupported"), "usb_pair"))
expect_error(def () p2smart.items_by_status(nil) end)
expect_error(def () p2smart.items_by_status("missing") end)
expect_error(def () p2smart.names_by_status("missing") end)
var report = p2smart.status_report()
assert(report["ok"])
assert(report["capabilities"]["sync_serial"] == "setup_only")
assert(list_has(report["verified"], "gpio"))
assert(list_has(report["verified"], "adc_dac_sampled_probe"))
assert(list_has(report["verified"], "adc_variant_dac_sampled_probe"))
assert(list_has(report["verified"], "dac_variant_adc_sampled_probe"))
assert(list_has(report["verified"], "adc_dac_variants_sampled_probe"))
assert(list_has(report["staged"], "gpio_diagnostics"))
assert(list_has(report["staged"], "gpio_loopback_probe"))
assert(list_has(report["staged"], "jumper_pair_probe"))
assert(list_has(report["staged"], "jumper_pair_checks"))
assert(list_has(report["staged"], "jumper_pairs_probe"))
assert(list_has(report["staged"], "default_jumper_pairs"))
assert(list_has(report["staged"], "default_jumper_directions"))
assert(list_has(report["staged"], "default_clocked_jumper_groups"))
assert(list_has(report["staged"], "default_jumper_pairs_probe"))
assert(list_has(report["staged"], "jumper_pairs_bidirectional_probe"))
assert(list_has(report["staged"], "default_jumper_pairs_bidirectional_probe"))
assert(list_has(report["staged"], "counter_sample_diagnostics"))
assert(list_has(report["staged"], "counter_variant_sample_probe"))
assert(list_has(report["staged"], "counter_variant_drive_probe"))
assert(list_has(report["staged"], "counter_variant_drive_modes_probe"))
assert(list_has(report["staged"], "repository_write_diagnostics"))
assert(list_has(report["staged"], "normal_pin_diagnostics"))
assert(list_has(report["staged"], "raw_smartpin_probe"))
assert(list_has(report["staged"], "quadrature_sample_diagnostics"))
assert(list_has(report["staged"], "quadrature_sample_probe"))
assert(list_has(report["staged"], "adc_sample_diagnostics"))
assert(list_has(report["staged"], "adc_variant_sample_probe"))
assert(list_has(report["staged"], "dac_set_diagnostics"))
assert(list_has(report["staged"], "dac_variant_adc_probe"))
assert(list_has(report["staged"], "adc_dac_delta_policy"))
assert(list_has(report["staged"], "pwm_duty_diagnostics"))
assert(list_has(report["staged"], "high_counter_probe"))
assert(list_has(report["staged"], "repository_read_diagnostics"))
assert(list_has(report["staged"], "repository_probe"))
assert(list_has(report["staged"], "pwm_counter_probe"))
assert(list_has(report["staged"], "pwm_variant_counter_probe"))
assert(list_has(report["staged"], "nco_increment_diagnostics"))
assert(list_has(report["staged"], "nco_counter_probe"))
assert(list_has(report["staged"], "nco_duty_diagnostics"))
assert(list_has(report["staged"], "nco_duty_counter_probe"))
assert(list_has(report["staged"], "pulse_trigger_diagnostics"))
assert(list_has(report["staged"], "pulse_counter_probe"))
assert(list_has(report["staged"], "transition_trigger_diagnostics"))
assert(list_has(report["staged"], "transition_counter_probe"))
assert(list_has(report["staged"], "async_serial_probe"))
assert(list_has(report["staged"], "async_serial_drain"))
assert(list_has(report["staged"], "async_serial_drain_probe"))
assert(list_has(report["staged"], "async_serial_buffer_policy"))
assert(list_has(report["staged"], "sync_serial_result_diagnostics"))
assert(list_has(report["staged"], "sync_serial_transfer_diagnostics"))
assert(list_has(report["staged"], "sync_serial_probe"))
assert(list_has(report["staged"], "sync_serial_clocked_probe"))
assert(list_has(report["staged"], "sync_serial_clocked_jumper_probes"))
assert(list_has(report["staged"], "sync_serial_default_clocked_probe"))
assert(list_has(report["staged"], "sync_serial_receive_policy"))
assert(list_has(report["staged"], "counter_mode_variants"))
assert(list_has(report["staged"], "pwm_mode_variants"))
assert(list_has(report["staged"], "nco_duty"))
assert(list_has(report["staged"], "adc_mode_variants"))
assert(list_has(report["staged"], "dac_mode_variants"))
assert(list_has(report["open"], "sync_serial_receive"))
assert(list_has(report["open"], "usb_pair"))
report["verified"].push("mutated")
assert(!list_has(p2smart.status_report()["verified"], "mutated"))
report["capabilities"]["sync_serial"] = "mutated"
assert(p2smart.status_report()["capabilities"]["sync_serial"] == "setup_only")
var audit = p2smart.audit()
assert(audit["ok"])
assert(audit["count"] == p2smart.names().size())
assert(audit["counted"]["verified"] == p2smart.items_by_status("verified").size())
assert(audit["counted"]["unsupported"] == p2smart.items_by_status("unsupported").size())
assert(audit["counts_match"])
assert(audit["duplicates"].size() == 0)
assert(audit["unknown_statuses"].size() == 0)
assert(audit["missing_capability_keys"].size() == 0)
assert(audit["jumper_pair_checks"] == p2smart.jumper_pair_checks())
assert(audit["jumper_pair_checks_ok"])
assert(audit["jumper_pair_check_duplicates"].size() == 0)
assert(audit["jumper_pair_check_missing"].size() == 0)
assert(p2smart.audit_ok())
var audit_problems = p2smart.audit_problems()
assert(audit_problems.size() == 0)
audit_problems.push("mutated")
assert(p2smart.audit_problems().size() == 0)
var buffer_policy = p2smart.async_serial_buffer_policy()
assert(buffer_policy["ok"])
assert(!buffer_policy["supported"])
assert(buffer_policy["capability"] == "async_serial_buffer")
assert(buffer_policy["status"] == "unsupported")
assert(buffer_policy["policy"] == "unsupported_no_fifo_buffer")
assert(buffer_policy["receive_model"] == "single_smartpin_sample")
assert(list_has(buffer_policy["safe_receive_helpers"], "read_result_after"))
assert(list_has(buffer_policy["safe_receive_helpers"], "read_available_results"))
assert(list_has(buffer_policy["safe_receive_helpers"], "read_available"))
assert(buffer_policy["cleanup_required"])
assert(buffer_policy["clear_releases_state"])
buffer_policy["safe_receive_helpers"].push("mutated")
assert(!list_has(p2smart.async_serial_buffer_policy()["safe_receive_helpers"], "mutated"))
var sync_policy = p2smart.sync_serial_receive_policy()
assert(sync_policy["ok"])
assert(!sync_policy["supported"])
assert(sync_policy["capability"] == "sync_serial_receive")
assert(sync_policy["status"] == "unverified")
assert(sync_policy["policy"] == "unverified_no_matched_receive_words")
assert(sync_policy["setup_status"] == "setup_only")
assert(sync_policy["diagnostic_status"] == "diagnostic")
assert(sync_policy["receive_model"] == "smartpin_sync_io_result_sample")
assert(list_has(sync_policy["safe_probe_helpers"], "sync_serial_clocked_probe"))
assert(sync_policy["bounded_clocked_probe"])
assert(sync_policy["unclocked_constant_raw_observed"])
assert(!sync_policy["clocked_ready_observed"])
assert(!sync_policy["matched_receive_words"])
assert(sync_policy["default_clocked_jumper_groups"] == [[0, 1, 2, 3], [4, 5, 6, 7]])
sync_policy["safe_probe_helpers"].push("mutated")
sync_policy["default_clocked_jumper_groups"][0][0] = 99
assert(!list_has(p2smart.sync_serial_receive_policy()["safe_probe_helpers"], "mutated"))
assert(p2smart.sync_serial_receive_policy()["default_clocked_jumper_groups"][0][0] == 0)
var delta_policy = p2smart.adc_dac_delta_policy()
assert(delta_policy["ok"])
assert(!delta_policy["supported"])
assert(delta_policy["capability"] == "adc_dac_delta")
assert(delta_policy["status"] == "unverified")
assert(delta_policy["policy"] == "unverified_no_calibrated_threshold")
assert(delta_policy["setup_probe"] == "dac_adc_probe")
assert(delta_policy["variant_probe"] == "dac_variant_adc_probe")
assert(list_has(delta_policy["measured_fields"], "abs_delta"))
assert(!delta_policy["calibrated_voltage"])
assert(!delta_policy["polarity_verified"])
assert(delta_policy["safe_claim"] == "setup_readback_only")
delta_policy["measured_fields"].push("mutated")
assert(!list_has(p2smart.adc_dac_delta_policy()["measured_fields"], "mutated"))

reset_calls()
var raw_reads = [11, 22]
var raw_queries = [33, 44]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = raw_reads[0]
    raw_reads = raw_reads[1..]
    return value
end
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    var value = raw_queries[0]
    raw_queries = raw_queries[1..]
    return value
end
var raw_probe = p2smart.raw_smartpin_probe(9)
assert(raw_probe["ok"])
assert(raw_probe["pin"] == 9)
assert(raw_probe["mode"] == smart.normal)
assert(raw_probe["initial_read"] == 11)
assert(raw_probe["initial_query"] == 33)
assert(raw_probe["started_read"] == 22)
assert(raw_probe["cleared_query"] == 44)
assert(calls == [
    ["smart.wrpin", 9, 0],
    ["smart.wxpin", 9, 0],
    ["smart.wypin", 9, 0],
    ["smart.akpin", 9],
    ["smart.rdpin", 9],
    ["smart.rqpin", 9],
    ["smart.start", 9, smart.normal, 0, 0],
    ["smart.rdpin", 9],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.rqpin", 9]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    return smart.rq_value
end

reset_calls()
var gpio_in = p2smart.gpio_input(10)
assert(gpio_in.info()["kind"] == "GPIOInput")
gpio_in.start()
assert(calls == [["pin.float", 10]])
pin.read_value = 1
assert(gpio_in.read() == 1)
var gpio_in_read = gpio_in.read_result()
assert(gpio_in_read["ok"])
assert(gpio_in_read["pin"] == 10)
assert(gpio_in_read["value"] == 1)
assert(gpio_in_read["high"])
assert(!gpio_in_read["low"])
assert(gpio_in.high())
pin.read_value = 0
assert(gpio_in.low())
gpio_in_read = gpio_in.read_result()
assert(gpio_in_read["low"])
gpio_in.dir_low()
assert(calls[calls.size() - 1] == ["pin.dir_low", 10])
gpio_in.clear()
assert(calls[calls.size() - 1] == ["pin.float", 10])
assert(!gpio_in.info()["started"])

reset_calls()
var gpio_out = p2smart.gpio_output(11, true)
assert(gpio_out.info()["kind"] == "GPIOOutput")
gpio_out.start()
assert(calls == [
    ["pin.dir_high", 11],
    ["pin.write", 11, 1]
])
gpio_out.low()
assert(calls[calls.size() - 1] == ["pin.low", 11])
assert(gpio_out.info()["value"] == 0)
gpio_out.high()
assert(calls[calls.size() - 1] == ["pin.high", 11])
assert(gpio_out.info()["value"] == 1)
pin.read_value = 0
gpio_out.toggle()
assert(calls[calls.size() - 2] == ["pin.toggle", 11])
assert(calls[calls.size() - 1] == ["pin.read", 11])
assert(gpio_out.info()["value"] == 0)
gpio_out.write(false)
assert(calls[calls.size() - 1] == ["pin.write", 11, 0])
var gpio_out_write = gpio_out.write_result(true)
assert(calls[calls.size() - 1] == ["pin.write", 11, 1])
assert(gpio_out_write["ok"])
assert(gpio_out_write["pin"] == 11)
assert(gpio_out_write["value"] == 1)
pin.read_value = 0
var gpio_out_toggle = gpio_out.toggle_result()
assert(calls[calls.size() - 2] == ["pin.toggle", 11])
assert(calls[calls.size() - 1] == ["pin.read", 11])
assert(gpio_out_toggle["ok"])
assert(gpio_out_toggle["pin"] == 11)
assert(gpio_out_toggle["value"] == 0)
gpio_out.clear()
assert(calls[calls.size() - 1] == ["pin.float", 11])
assert(!gpio_out.info()["started"])

reset_calls()
var saved_pin_read = pin.read
var saved_pin_write = pin.write
var loopback_value = 0
pin.write = def(pin_no, value)
    calls.push(["pin.write", pin_no, value])
    loopback_value = value
end
pin.read = def(pin_no)
    calls.push(["pin.read", pin_no])
    return loopback_value
end
var gpio_probe = p2smart.gpio_loopback_probe(14, 15, [0, 1], 5)
assert(gpio_probe["ok"])
assert(gpio_probe["out_pin"] == 14)
assert(gpio_probe["in_pin"] == 15)
assert(gpio_probe["count"] == 2)
assert(gpio_probe["settle_us"] == 5)
assert(gpio_probe["values"] == [0, 1])
assert(gpio_probe["results"][0]["ok"])
assert(gpio_probe["results"][1]["ok"])
assert(calls == [
    ["pin.dir_high", 14],
    ["pin.float", 15],
    ["pin.write", 14, 0],
    ["waitus", 5],
    ["pin.read", 15],
    ["pin.write", 14, 1],
    ["waitus", 5],
    ["pin.read", 15],
    ["pin.float", 14],
    ["pin.float", 15]
])
pin.read = saved_pin_read
pin.write = saved_pin_write

reset_calls()
var normal_in = p2smart.normal_pin(12, nil, nil)
assert(normal_in.info()["kind"] == "NormalPin")
assert(normal_in.info()["mode"] == smart.normal)
normal_in.start()
assert(calls == [
    ["smart.start", 12, smart.normal, 0, 0],
    ["pin.float", 12]
])
pin.read_value = 1
assert(normal_in.read() == 1)
var normal_read = normal_in.read_result()
assert(normal_read["ok"])
assert(normal_read["pin"] == 12)
assert(normal_read["mode"] == smart.normal)
assert(normal_read["value"] == 1)
normal_in.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 12])
assert(calls[calls.size() - 1] == ["pin.float", 12])
assert(!normal_in.info()["started"])

reset_calls()
var normal_out = p2smart.normal_pin(13, nil, true)
normal_out.start()
assert(calls == [
    ["smart.start", 13, smart.normal, 0, 0],
    ["pin.dir_high", 13],
    ["pin.write", 13, 1]
])
normal_out.low()
assert(calls[calls.size() - 1] == ["pin.low", 13])
normal_out.write(true)
assert(calls[calls.size() - 1] == ["pin.write", 13, 1])
var normal_write = normal_out.write_result(false)
assert(normal_write["ok"])
assert(normal_write["pin"] == 13)
assert(normal_write["mode"] == smart.normal)
assert(normal_write["value"] == 0)
assert(calls[calls.size() - 1] == ["pin.write", 13, 0])
pin.read_value = 0
normal_out.toggle()
assert(calls[calls.size() - 2] == ["pin.toggle", 13])
assert(calls[calls.size() - 1] == ["pin.read", 13])
normal_out.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 13])
assert(calls[calls.size() - 1] == ["pin.float", 13])

reset_calls()
var counter = p2smart.counter(1, nil)
assert(counter.info()["pin"] == 1)
assert(counter.info()["mode"] == smart.count_rises)
counter.start()
assert(calls == [
    ["smart.start", 1, smart.count_rises, 0, 0],
    ["smart.akpin", 1]
])
smart.rd_value = 17
assert(counter.read() == 17)
assert(calls[calls.size() - 1] == ["smart.rdpin", 1])
smart.rq_value = 1
assert(counter.query() == 1)
assert(calls[calls.size() - 1] == ["smart.rqpin", 1])
var counter_reads = [17, 25]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = counter_reads[0]
    counter_reads = counter_reads[1..]
    return value
end
reset_calls()
var counter_sample = counter.sample_after(50)
assert(counter_sample["ok"])
assert(counter_sample["pin"] == 1)
assert(counter_sample["before"] == 17)
assert(counter_sample["after"] == 25)
assert(counter_sample["delta"] == 8)
assert(counter_sample["advanced"])
assert(counter_sample["wait_us"] == 50)
assert(calls == [["smart.rdpin", 1], ["waitus", 50], ["smart.rdpin", 1]])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
counter.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 1])
assert(calls[calls.size() - 1] == ["pin.float", 1])
assert(!counter.info()["started"])

reset_calls()
var high_probe_reads = [5, 11]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = high_probe_reads[0]
    high_probe_reads = high_probe_reads[1..]
    return value
end
var high_probe = p2smart.high_counter_probe(2, 3, 40, 10)
assert(high_probe["ok"])
assert(high_probe["out_pin"] == 2)
assert(high_probe["in_pin"] == 3)
assert(high_probe["high"]["value"] == 1)
assert(high_probe["low"]["value"] == 0)
assert(high_probe["counter"]["mode"] == smart.count_highs)
assert(high_probe["counter"]["before"] == 5)
assert(high_probe["counter"]["after"] == 11)
assert(high_probe["counter"]["delta"] == 6)
assert(high_probe["counter"]["advanced"])
assert(high_probe["high_us"] == 40)
assert(high_probe["settle_us"] == 10)
assert(calls == [
    ["smart.start", 3, smart.count_highs, 0, 0],
    ["smart.akpin", 3],
    ["pin.dir_high", 2],
    ["smart.rdpin", 3],
    ["pin.write", 2, 1],
    ["waitus", 40],
    ["pin.write", 2, 0],
    ["waitus", 10],
    ["smart.rdpin", 3],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["pin.float", 2]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

assert(p2smart.counter_mode(nil) == smart.count_rises)
assert(p2smart.counter_mode("count_rises") == smart.count_rises)
assert(p2smart.counter_mode("count_highs") == smart.count_highs)
assert(p2smart.counter_mode("state_ticks") == smart.state_ticks)
assert(p2smart.counter_mode("high_ticks") == smart.high_ticks)
assert(p2smart.counter_mode("events_ticks") == smart.events_ticks)
assert(p2smart.counter_mode("periods_ticks") == smart.periods_ticks)
assert(p2smart.counter_mode("periods_highs") == smart.periods_highs)
assert(p2smart.counter_mode("counter_ticks") == smart.counter_ticks)
assert(p2smart.counter_mode("counter_highs") == smart.counter_highs)
assert(p2smart.counter_mode("counter_periods") == smart.counter_periods)
assert(p2smart.counter_mode("reg_up") == smart.reg_up)
assert(p2smart.counter_mode("reg_up_down") == smart.reg_up_down)
reset_calls()
var counter_variant = p2smart.counter_variant(1, "periods_ticks")
assert(counter_variant.info()["mode"] == smart.periods_ticks)
counter_variant.start()
assert(calls == [
    ["smart.start", 1, smart.periods_ticks, 0, 0],
    ["smart.akpin", 1]
])
counter_variant.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 1])
assert(calls[calls.size() - 1] == ["pin.float", 1])

reset_calls()
var counter_variant_reads = [20, 27]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = counter_variant_reads[0]
    counter_variant_reads = counter_variant_reads[1..]
    return value
end
var counter_variant_probe = p2smart.counter_variant_sample_probe(1, "periods_ticks", 60)
assert(counter_variant_probe["ok"])
assert(counter_variant_probe["pin"] == 1)
assert(counter_variant_probe["mode_name"] == "periods_ticks")
assert(counter_variant_probe["mode"] == smart.periods_ticks)
assert(counter_variant_probe["wait_us"] == 60)
assert(counter_variant_probe["sample"]["before"] == 20)
assert(counter_variant_probe["sample"]["after"] == 27)
assert(counter_variant_probe["sample"]["delta"] == 7)
assert(counter_variant_probe["sample"]["advanced"])
assert(counter_variant_probe["counter"]["mode"] == smart.periods_ticks)
assert(calls == [
    ["smart.start", 1, smart.periods_ticks, 0, 0],
    ["smart.akpin", 1],
    ["smart.rdpin", 1],
    ["waitus", 60],
    ["smart.rdpin", 1],
    ["smart.clear", 1],
    ["pin.float", 1]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
counter_variant_reads = [3, 12]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = counter_variant_reads[0]
    counter_variant_reads = counter_variant_reads[1..]
    return value
end
var counter_drive_probe = p2smart.counter_variant_drive_probe(2, 3, "count_highs", 45, 8)
assert(counter_drive_probe["ok"])
assert(counter_drive_probe["out_pin"] == 2)
assert(counter_drive_probe["in_pin"] == 3)
assert(counter_drive_probe["mode_name"] == "count_highs")
assert(counter_drive_probe["mode"] == smart.count_highs)
assert(counter_drive_probe["low_before"]["value"] == 0)
assert(counter_drive_probe["high"]["value"] == 1)
assert(counter_drive_probe["low_after"]["value"] == 0)
assert(counter_drive_probe["counter"]["before"] == 3)
assert(counter_drive_probe["counter"]["after"] == 12)
assert(counter_drive_probe["counter"]["delta"] == 9)
assert(counter_drive_probe["counter"]["advanced"])
assert(counter_drive_probe["high_us"] == 45)
assert(counter_drive_probe["settle_us"] == 8)
assert(calls == [
    ["pin.dir_high", 2],
    ["pin.write", 2, 0],
    ["smart.start", 3, smart.count_highs, 0, 0],
    ["smart.akpin", 3],
    ["smart.rdpin", 3],
    ["pin.write", 2, 1],
    ["waitus", 45],
    ["pin.write", 2, 0],
    ["waitus", 8],
    ["smart.rdpin", 3],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["pin.float", 2]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
counter_variant_reads = [2, 7, 1, 4]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = counter_variant_reads[0]
    counter_variant_reads = counter_variant_reads[1..]
    return value
end
var counter_drive_modes = p2smart.counter_variant_drive_modes_probe(2, 3, nil, 30, 6)
assert(counter_drive_modes["ok"])
assert(counter_drive_modes["out_pin"] == 2)
assert(counter_drive_modes["in_pin"] == 3)
assert(counter_drive_modes["modes"] == ["count_highs"])
assert(counter_drive_modes["count"] == 1)
assert(counter_drive_modes["ok_count"] == 1)
assert(counter_drive_modes["failed_count"] == 0)
assert(counter_drive_modes["failed_modes"] == [])
assert(counter_drive_modes["high_us"] == 30)
assert(counter_drive_modes["settle_us"] == 6)
assert(counter_drive_modes["results"][0]["mode_name"] == "count_highs")
assert(counter_drive_modes["results"][0]["counter"]["delta"] == 5)
counter_drive_modes["modes"].push("mutated")
assert(p2smart.counter_variant_drive_modes_probe(2, 3, ["count_rises"], 0, 0)["modes"] == ["count_rises"])
assert(calls == [
    ["pin.dir_high", 2],
    ["pin.write", 2, 0],
    ["smart.start", 3, smart.count_highs, 0, 0],
    ["smart.akpin", 3],
    ["smart.rdpin", 3],
    ["pin.write", 2, 1],
    ["waitus", 30],
    ["pin.write", 2, 0],
    ["waitus", 6],
    ["smart.rdpin", 3],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["pin.float", 2],
    ["pin.dir_high", 2],
    ["pin.write", 2, 0],
    ["smart.start", 3, smart.count_rises, 0, 0],
    ["smart.akpin", 3],
    ["smart.rdpin", 3],
    ["pin.write", 2, 1],
    ["pin.write", 2, 0],
    ["smart.rdpin", 3],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["pin.float", 2]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
expect_error(def () p2smart.counter_variant_drive_modes_probe(0, 1, "bad", 0, 0) end)
expect_error(def () p2smart.counter_variant_drive_modes_probe(0, 1, [], 0, 0) end)

reset_calls()
var quadrature = p2smart.quadrature(4, 5, nil)
assert(quadrature.info()["kind"] == "Quadrature")
assert(quadrature.info()["pin_a"] == 4)
assert(quadrature.info()["pin_b"] == 5)
assert(quadrature.info()["mode"] == smart.quadrature + smart.plus1_b)
quadrature.start()
assert(calls == [
    ["pin.float", 4],
    ["pin.float", 5],
    ["smart.start", 4, smart.quadrature + smart.plus1_b, 0, 0],
    ["smart.akpin", 4]
])
smart.rd_value = 123
assert(quadrature.read() == 123)
assert(calls[calls.size() - 1] == ["smart.rdpin", 4])
smart.rd_value = -7
assert(quadrature.position() == -7)
assert(calls[calls.size() - 1] == ["smart.rdpin", 4])
smart.rq_value = 1
assert(quadrature.query() == 1)
assert(calls[calls.size() - 1] == ["smart.rqpin", 4])
var quadrature_reads = [10, 7]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = quadrature_reads[0]
    quadrature_reads = quadrature_reads[1..]
    return value
end
reset_calls()
var quadrature_sample = quadrature.sample_after(75)
assert(quadrature_sample["ok"])
assert(quadrature_sample["pin_a"] == 4)
assert(quadrature_sample["pin_b"] == 5)
assert(quadrature_sample["before"] == 10)
assert(quadrature_sample["after"] == 7)
assert(quadrature_sample["delta"] == -3)
assert(quadrature_sample["moved"])
assert(quadrature_sample["direction"] == -1)
assert(quadrature_sample["wait_us"] == 75)
assert(calls == [["smart.rdpin", 4], ["waitus", 75], ["smart.rdpin", 4]])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
quadrature.ack()
assert(calls[calls.size() - 1] == ["smart.akpin", 4])
quadrature.clear()
assert(calls[calls.size() - 3] == ["smart.clear", 4])
assert(calls[calls.size() - 2] == ["pin.float", 4])
assert(calls[calls.size() - 1] == ["pin.float", 5])
assert(!quadrature.info()["started"])

reset_calls()
var quadrature_reverse = p2smart.quadrature(5, 4, nil)
assert(quadrature_reverse.info()["mode"] == smart.quadrature + smart.minus1_b)

reset_calls()
var quadrature_custom = p2smart.quadrature(4, 7, smart.plus1_b)
assert(quadrature_custom.info()["mode"] == smart.quadrature + smart.plus1_b)

reset_calls()
var quadrature_probe_reads = [3, 11]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = quadrature_probe_reads[0]
    quadrature_probe_reads = quadrature_probe_reads[1..]
    return value
end
var quadrature_probe = p2smart.quadrature_sample_probe(4, 5, nil, 80)
assert(quadrature_probe["ok"])
assert(quadrature_probe["pin_a"] == 4)
assert(quadrature_probe["pin_b"] == 5)
assert(quadrature_probe["mode"] == smart.quadrature + smart.plus1_b)
assert(quadrature_probe["wait_us"] == 80)
assert(quadrature_probe["sample"]["before"] == 3)
assert(quadrature_probe["sample"]["after"] == 11)
assert(quadrature_probe["sample"]["delta"] == 8)
assert(quadrature_probe["sample"]["moved"])
assert(quadrature_probe["sample"]["direction"] == 1)
assert(quadrature_probe["quadrature"]["mode"] == smart.quadrature + smart.plus1_b)
assert(calls == [
    ["pin.float", 4],
    ["pin.float", 5],
    ["smart.start", 4, smart.quadrature + smart.plus1_b, 0, 0],
    ["smart.akpin", 4],
    ["smart.rdpin", 4],
    ["waitus", 80],
    ["smart.rdpin", 4],
    ["smart.clear", 4],
    ["pin.float", 4],
    ["pin.float", 5]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var repository = p2smart.repository(2, 0x1234, nil)
assert(repository.info()["mode"] == smart.oe + smart.repository)
repository.start()
assert(calls == [
    ["smart.start", 2, smart.oe + smart.repository, 0x1234, 0]
])
repository.write(0x5678)
assert(calls[calls.size() - 1] == ["smart.wxpin", 2, 0x5678])
reset_calls()
var repository_result = repository.write_result(0x9abc, 20)
assert(repository_result["ok"])
assert(repository_result["pin"] == 2)
assert(repository_result["value"] == 0x9abc)
assert(repository_result["settled"])
assert(repository_result["settle_us"] == 20)
assert(calls == [["smart.wxpin", 2, 0x9abc], ["waitus", 20]])
smart.rd_value = 0x5678
assert(repository.read() == 0x5678)
assert(calls[calls.size() - 1] == ["smart.rdpin", 2])
var repository_read = repository.read_result()
assert(repository_read["ok"])
assert(repository_read["pin"] == 2)
assert(repository_read["mode"] == smart.oe + smart.repository)
assert(repository_read["value"] == 0x9abc)
assert(repository_read["raw"] == 0x5678)
repository.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 2])
assert(calls[calls.size() - 1] == ["pin.float", 2])

reset_calls()
var repository_reads = [0x1111, 0x2222]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = repository_reads[0]
    repository_reads = repository_reads[1..]
    return value
end
var repository_probe = p2smart.repository_probe(6, 0x1000, 0x2000, 15)
assert(repository_probe["ok"])
assert(repository_probe["pin"] == 6)
assert(repository_probe["mode"] == smart.oe + smart.repository)
assert(repository_probe["first"]["value"] == 0x1000)
assert(repository_probe["first"]["raw"] == 0x1111)
assert(repository_probe["write"]["value"] == 0x2000)
assert(repository_probe["write"]["settle_us"] == 15)
assert(repository_probe["second"]["value"] == 0x2000)
assert(repository_probe["second"]["raw"] == 0x2222)
assert(repository_probe["settle_us"] == 15)
assert(calls == [
    ["smart.start", 6, smart.oe + smart.repository, 0x1000, 0],
    ["waitus", 15],
    ["smart.rdpin", 6],
    ["smart.wxpin", 6, 0x2000],
    ["waitus", 15],
    ["smart.rdpin", 6],
    ["smart.clear", 6],
    ["pin.float", 6]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var pwm = p2smart.pwm(2, 200, 50, 3, nil)
assert(pwm.x() == 200 * 65536 + 3)
assert(pwm.info()["mode"] == smart.oe + smart.pwm_triangle)
pwm.start()
assert(calls == [
    ["smart.start", 2, smart.oe + smart.pwm_triangle, 200 * 65536 + 3, 50]
])
pwm.set_duty(75)
assert(calls[calls.size() - 1] == ["smart.wypin", 2, 75])
assert(pwm.info()["duty"] == 75)
reset_calls()
var pwm_result = pwm.set_duty_result(125, 40)
assert(pwm_result["ok"])
assert(pwm_result["pin"] == 2)
assert(pwm_result["frame"] == 200)
assert(pwm_result["duty"] == 125)
assert(pwm_result["divisor"] == 3)
assert(pwm_result["settled"])
assert(pwm_result["settle_us"] == 40)
assert(calls == [["smart.wypin", 2, 125], ["waitus", 40]])
pwm.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 2])
assert(calls[calls.size() - 1] == ["pin.float", 2])

assert(p2smart.pwm_mode(nil) == smart.oe + smart.pwm_triangle)
assert(p2smart.pwm_mode("triangle") == smart.oe + smart.pwm_triangle)
assert(p2smart.pwm_mode("sawtooth") == smart.oe + smart.pwm_sawtooth)
assert(p2smart.pwm_mode("smps") == smart.oe + smart.pwm_smps)
reset_calls()
var pwm_variant = p2smart.pwm_variant(2, 200, 25, 4, "sawtooth")
assert(pwm_variant.info()["mode"] == smart.oe + smart.pwm_sawtooth)
pwm_variant.start()
assert(calls == [
    ["smart.start", 2, smart.oe + smart.pwm_sawtooth, 200 * 65536 + 4, 25]
])
pwm_variant.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 2])
assert(calls[calls.size() - 1] == ["pin.float", 2])

reset_calls()
var pwm_probe_reads = [2, 7]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = pwm_probe_reads[0]
    pwm_probe_reads = pwm_probe_reads[1..]
    return value
end
var pwm_probe = p2smart.pwm_counter_probe(2, 3, 200, 100, 1, 20)
assert(pwm_probe["ok"])
assert(pwm_probe["out_pin"] == 2)
assert(pwm_probe["in_pin"] == 3)
assert(pwm_probe["settle_us"] == 20)
assert(pwm_probe["pwm"]["x"] == 200 * 65536 + 1)
assert(pwm_probe["counter"]["before"] == 2)
assert(pwm_probe["counter"]["after"] == 7)
assert(pwm_probe["counter"]["delta"] == 5)
assert(pwm_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 3, smart.count_rises, 0, 0],
    ["smart.akpin", 3],
    ["smart.start", 2, smart.oe + smart.pwm_triangle, 200 * 65536 + 1, 100],
    ["smart.rdpin", 3],
    ["waitus", 20],
    ["smart.rdpin", 3],
    ["smart.clear", 2],
    ["pin.float", 2],
    ["smart.clear", 3],
    ["pin.float", 3]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var pwm_variant_probe_reads = [5, 14]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = pwm_variant_probe_reads[0]
    pwm_variant_probe_reads = pwm_variant_probe_reads[1..]
    return value
end
var pwm_variant_probe = p2smart.pwm_variant_counter_probe(2, 3, 200, 50, 2, "sawtooth", 30)
assert(pwm_variant_probe["ok"])
assert(pwm_variant_probe["out_pin"] == 2)
assert(pwm_variant_probe["in_pin"] == 3)
assert(pwm_variant_probe["mode_name"] == "sawtooth")
assert(pwm_variant_probe["settle_us"] == 30)
assert(pwm_variant_probe["pwm"]["mode"] == smart.oe + smart.pwm_sawtooth)
assert(pwm_variant_probe["pwm"]["x"] == 200 * 65536 + 2)
assert(pwm_variant_probe["counter"]["before"] == 5)
assert(pwm_variant_probe["counter"]["after"] == 14)
assert(pwm_variant_probe["counter"]["delta"] == 9)
assert(pwm_variant_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 3, smart.count_rises, 0, 0],
    ["smart.akpin", 3],
    ["smart.start", 2, smart.oe + smart.pwm_sawtooth, 200 * 65536 + 2, 50],
    ["smart.rdpin", 3],
    ["waitus", 30],
    ["smart.rdpin", 3],
    ["smart.clear", 2],
    ["pin.float", 2],
    ["smart.clear", 3],
    ["pin.float", 3]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var nco = p2smart.nco(3, 16000, 0x20000000, nil)
assert(nco.info()["mode"] == smart.oe + smart.nco_freq)
nco.start()
assert(calls == [
    ["smart.start", 3, smart.oe + smart.nco_freq, 16000, 0x20000000]
])
nco.set_increment(0x10000000)
assert(calls[calls.size() - 1] == ["smart.wypin", 3, 0x10000000])
assert(nco.info()["increment"] == 0x10000000)
reset_calls()
var nco_result = nco.set_increment_result(0x08000000, 25)
assert(nco_result["ok"])
assert(nco_result["pin"] == 3)
assert(nco_result["bit_period"] == 16000)
assert(nco_result["increment"] == 0x08000000)
assert(nco_result["settled"])
assert(nco_result["settle_us"] == 25)
assert(calls == [["smart.wypin", 3, 0x08000000], ["waitus", 25]])
nco.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 3])
assert(calls[calls.size() - 1] == ["pin.float", 3])

reset_calls()
var nco_probe_reads = [4, 9]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = nco_probe_reads[0]
    nco_probe_reads = nco_probe_reads[1..]
    return value
end
var nco_probe = p2smart.nco_counter_probe(3, 4, 16000, 0x20000000, 25)
assert(nco_probe["ok"])
assert(nco_probe["out_pin"] == 3)
assert(nco_probe["in_pin"] == 4)
assert(nco_probe["settle_us"] == 25)
assert(nco_probe["nco"]["bit_period"] == 16000)
assert(nco_probe["nco"]["increment"] == 0x20000000)
assert(nco_probe["counter"]["before"] == 4)
assert(nco_probe["counter"]["after"] == 9)
assert(nco_probe["counter"]["delta"] == 5)
assert(nco_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 4, smart.count_rises, 0, 0],
    ["smart.akpin", 4],
    ["smart.start", 3, smart.oe + smart.nco_freq, 16000, 0x20000000],
    ["smart.rdpin", 4],
    ["waitus", 25],
    ["smart.rdpin", 4],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["smart.clear", 4],
    ["pin.float", 4]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var nco_duty = p2smart.nco_duty(3, 16000, 4000, nil)
assert(nco_duty.info()["kind"] == "NCODuty")
assert(nco_duty.info()["mode"] == smart.oe + smart.nco_duty)
nco_duty.start()
assert(calls == [
    ["smart.start", 3, smart.oe + smart.nco_duty, 16000, 4000]
])
nco_duty.set_duty(8000)
assert(calls[calls.size() - 1] == ["smart.wypin", 3, 8000])
assert(nco_duty.info()["duty"] == 8000)
reset_calls()
var nco_duty_result = nco_duty.set_duty_result(6000, 30)
assert(nco_duty_result["ok"])
assert(nco_duty_result["pin"] == 3)
assert(nco_duty_result["bit_period"] == 16000)
assert(nco_duty_result["duty"] == 6000)
assert(nco_duty_result["settled"])
assert(nco_duty_result["settle_us"] == 30)
assert(calls == [["smart.wypin", 3, 6000], ["waitus", 30]])
nco_duty.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 3])
assert(calls[calls.size() - 1] == ["pin.float", 3])

reset_calls()
var nco_duty_probe_reads = [12, 18]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = nco_duty_probe_reads[0]
    nco_duty_probe_reads = nco_duty_probe_reads[1..]
    return value
end
var nco_duty_probe = p2smart.nco_duty_counter_probe(3, 4, 16000, 4000, 25)
assert(nco_duty_probe["ok"])
assert(nco_duty_probe["out_pin"] == 3)
assert(nco_duty_probe["in_pin"] == 4)
assert(nco_duty_probe["settle_us"] == 25)
assert(nco_duty_probe["nco_duty"]["bit_period"] == 16000)
assert(nco_duty_probe["nco_duty"]["duty"] == 4000)
assert(nco_duty_probe["counter"]["before"] == 12)
assert(nco_duty_probe["counter"]["after"] == 18)
assert(nco_duty_probe["counter"]["delta"] == 6)
assert(nco_duty_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 4, smart.count_rises, 0, 0],
    ["smart.akpin", 4],
    ["smart.start", 3, smart.oe + smart.nco_duty, 16000, 4000],
    ["smart.rdpin", 4],
    ["waitus", 25],
    ["smart.rdpin", 4],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["smart.clear", 4],
    ["pin.float", 4]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var pulse = p2smart.pulse(4, 20, 30, 5, nil)
assert(pulse.x() == 20 * 65536 + 50)
assert(pulse.info()["mode"] == smart.oe + smart.pulse)
pulse.start()
assert(calls == [
    ["smart.start", 4, smart.oe + smart.pulse, 20 * 65536 + 50, 5],
    ["smart.wypin", 4, 5]
])
pulse.trigger(3)
assert(calls[calls.size() - 1] == ["smart.wypin", 4, 3])
assert(pulse.info()["count"] == 3)
reset_calls()
var pulse_result = pulse.trigger_result(2, 35)
assert(pulse_result["ok"])
assert(pulse_result["pin"] == 4)
assert(pulse_result["count"] == 2)
assert(pulse_result["high_ticks"] == 20)
assert(pulse_result["low_ticks"] == 30)
assert(pulse_result["settled"])
assert(pulse_result["settle_us"] == 35)
assert(calls == [["smart.wypin", 4, 2], ["waitus", 35]])
pulse.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 4])
assert(calls[calls.size() - 1] == ["pin.float", 4])

reset_calls()
var pulse_probe_reads = [3, 8]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = pulse_probe_reads[0]
    pulse_probe_reads = pulse_probe_reads[1..]
    return value
end
var pulse_probe = p2smart.pulse_counter_probe(4, 5, 20, 30, 5, 30)
assert(pulse_probe["ok"])
assert(pulse_probe["out_pin"] == 4)
assert(pulse_probe["in_pin"] == 5)
assert(pulse_probe["settle_us"] == 30)
assert(pulse_probe["pulse"]["x"] == 20 * 65536 + 50)
assert(pulse_probe["pulse"]["count"] == 5)
assert(pulse_probe["counter"]["before"] == 3)
assert(pulse_probe["counter"]["after"] == 8)
assert(pulse_probe["counter"]["delta"] == 5)
assert(pulse_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 5, smart.count_rises, 0, 0],
    ["smart.akpin", 5],
    ["smart.start", 4, smart.oe + smart.pulse, 20 * 65536 + 50, 0],
    ["smart.wypin", 4, 0],
    ["smart.rdpin", 5],
    ["smart.wypin", 4, 5],
    ["waitus", 30],
    ["smart.rdpin", 5],
    ["smart.clear", 4],
    ["pin.float", 4],
    ["smart.clear", 5],
    ["pin.float", 5]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var transition = p2smart.transition(5, 80, 6, nil)
assert(transition.info()["mode"] == smart.oe + smart.transition)
transition.start()
assert(calls == [
    ["smart.start", 5, smart.oe + smart.transition, 80, 6],
    ["smart.wypin", 5, 6]
])
transition.trigger(2)
assert(calls[calls.size() - 1] == ["smart.wypin", 5, 2])
assert(transition.info()["count"] == 2)
reset_calls()
var transition_result = transition.trigger_result(4, 45)
assert(transition_result["ok"])
assert(transition_result["pin"] == 5)
assert(transition_result["width"] == 80)
assert(transition_result["count"] == 4)
assert(transition_result["settled"])
assert(transition_result["settle_us"] == 45)
assert(calls == [["smart.wypin", 5, 4], ["waitus", 45]])
transition.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 5])
assert(calls[calls.size() - 1] == ["pin.float", 5])

reset_calls()
var transition_probe_reads = [6, 12]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = transition_probe_reads[0]
    transition_probe_reads = transition_probe_reads[1..]
    return value
end
var transition_probe = p2smart.transition_counter_probe(5, 6, 80, 6, 35)
assert(transition_probe["ok"])
assert(transition_probe["out_pin"] == 5)
assert(transition_probe["in_pin"] == 6)
assert(transition_probe["settle_us"] == 35)
assert(transition_probe["transition"]["width"] == 80)
assert(transition_probe["transition"]["count"] == 6)
assert(transition_probe["counter"]["before"] == 6)
assert(transition_probe["counter"]["after"] == 12)
assert(transition_probe["counter"]["delta"] == 6)
assert(transition_probe["counter"]["advanced"])
assert(calls == [
    ["smart.start", 6, smart.count_rises, 0, 0],
    ["smart.akpin", 6],
    ["smart.start", 5, smart.oe + smart.transition, 80, 0],
    ["smart.wypin", 5, 0],
    ["smart.rdpin", 6],
    ["smart.wypin", 5, 6],
    ["waitus", 35],
    ["smart.rdpin", 6],
    ["smart.clear", 5],
    ["pin.float", 5],
    ["smart.clear", 6],
    ["pin.float", 6]
])
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

reset_calls()
var saved_raw_probe = p2smart.raw_smartpin_probe
var saved_gpio_probe = p2smart.gpio_loopback_probe
var saved_high_probe = p2smart.high_counter_probe
var saved_pulse_probe = p2smart.pulse_counter_probe
var saved_transition_probe = p2smart.transition_counter_probe
var saved_async_probe = p2smart.async_serial_probe
var saved_async_drain_probe = p2smart.async_serial_drain_probe
p2smart.raw_smartpin_probe = def(pin_no)
    calls.push(["raw_probe", pin_no])
    return {"ok": true, "pin": pin_no}
end
p2smart.gpio_loopback_probe = def(out_pin, in_pin, values, settle_us)
    calls.push(["gpio_probe", out_pin, in_pin, values, settle_us])
    return {"ok": true, "out_pin": out_pin, "in_pin": in_pin}
end
p2smart.high_counter_probe = def(out_pin, in_pin, high_us, settle_us)
    calls.push(["high_probe", out_pin, in_pin, high_us, settle_us])
    return {"ok": true, "out_pin": out_pin, "in_pin": in_pin}
end
p2smart.pulse_counter_probe = def(out_pin, in_pin, high_ticks, low_ticks, count, settle_us)
    calls.push(["pulse_probe", out_pin, in_pin, high_ticks, low_ticks, count, settle_us])
    raise "probe_error", "pulse failed"
end
p2smart.transition_counter_probe = def(out_pin, in_pin, width, count, settle_us)
    calls.push(["transition_probe", out_pin, in_pin, width, count, settle_us])
    return {"ok": true, "out_pin": out_pin, "in_pin": in_pin}
end
p2smart.async_serial_probe = def(tx_pin, rx_pin, values, wait_us, baud, bits)
    calls.push(["async_probe", tx_pin, rx_pin, values, wait_us, baud, bits])
    return {"ok": true, "tx_pin": tx_pin, "rx_pin": rx_pin}
end
p2smart.async_serial_drain_probe = def(tx_pin, rx_pin, value, wait_us, baud, bits, max_count)
    calls.push(["async_drain_probe", tx_pin, rx_pin, value, wait_us, baud, bits, max_count])
    return {"ok": true, "tx_pin": tx_pin, "rx_pin": rx_pin, "matched": true}
end
var pair_probe = p2smart.jumper_pair_probe(2, 3)
assert(!pair_probe["ok"])
assert(pair_probe["out_pin"] == 2)
assert(pair_probe["in_pin"] == 3)
assert(pair_probe["count"] == 8)
assert(pair_probe["checks"] == p2smart.jumper_pair_checks())
assert(pair_probe["ok_count"] == 7)
assert(pair_probe["failed_count"] == 1)
assert(pair_probe["failed_checks"] == ["pulse_counter"])
assert(pair_probe["pulse_counter"]["error"] == "probe_error")
assert(pair_probe["pulse_counter"]["cleanup_attempted"])
assert(pair_probe["raw_out"]["pin"] == 2)
assert(pair_probe["raw_in"]["pin"] == 3)
assert(pair_probe["async_serial_drain"]["matched"])
pair_probe["checks"].push("mutated")
assert(!list_has(p2smart.jumper_pair_checks(), "mutated"))
assert(calls == [
    ["raw_probe", 2],
    ["raw_probe", 3],
    ["gpio_probe", 2, 3, [0, 1, 0, 1], 100],
    ["high_probe", 2, 3, 1000, 100],
    ["pulse_probe", 2, 3, 100, 100, 8, 2000],
    ["smart.clear", 2],
    ["pin.float", 2],
    ["smart.clear", 3],
    ["pin.float", 3],
    ["transition_probe", 2, 3, 100, 8, 2000],
    ["async_probe", 2, 3, [0, 0x55, 0xa5, 0xff], 100, 115200, 8],
    ["async_drain_probe", 2, 3, 0x33, 2000, 115200, 8, 4]
])
reset_calls()
var saved_pair_probe = p2smart.jumper_pair_probe
p2smart.jumper_pair_probe = def(out_pin, in_pin)
    calls.push(["pair_probe", out_pin, in_pin])
    return {"ok": out_pin == 0, "out_pin": out_pin, "in_pin": in_pin, "ok_count": out_pin == 0 ? 7 : 6, "failed_count": out_pin == 0 ? 0 : 1, "failed_checks": out_pin == 0 ? [] : ["gpio"]}
end
var pairs_probe = p2smart.jumper_pairs_probe([[0, 1], [2, 3]])
assert(!pairs_probe["ok"])
assert(pairs_probe["count"] == 2)
assert(pairs_probe["ok_count"] == 1)
assert(pairs_probe["failed_count"] == 1)
assert(pairs_probe["failed_pairs"] == [[2, 3]])
assert(pairs_probe["failures"].size() == 1)
assert(pairs_probe["failures"][0]["pair"] == [2, 3])
assert(pairs_probe["failures"][0]["ok_count"] == 6)
assert(pairs_probe["failures"][0]["failed_count"] == 1)
assert(pairs_probe["failures"][0]["failed_checks"] == ["gpio"])
assert(pairs_probe["pairs"] == [[0, 1], [2, 3]])
assert(pairs_probe["results"][0]["out_pin"] == 0)
assert(pairs_probe["results"][1]["in_pin"] == 3)
assert(calls == [["pair_probe", 0, 1], ["pair_probe", 2, 3]])
reset_calls()
p2smart.jumper_pair_probe = def(out_pin, in_pin)
    calls.push(["pair_probe_minimal", out_pin, in_pin])
    return {"ok": false, "out_pin": out_pin, "in_pin": in_pin}
end
var minimal_failure_probe = p2smart.jumper_pairs_probe([[4, 5]])
assert(!minimal_failure_probe["ok"])
assert(minimal_failure_probe["failed_count"] == 1)
assert(minimal_failure_probe["failures"][0]["pair"] == [4, 5])
assert(minimal_failure_probe["failures"][0]["ok_count"] == 0)
assert(minimal_failure_probe["failures"][0]["failed_count"] == 1)
assert(minimal_failure_probe["failures"][0]["failed_checks"] == [])
p2smart.jumper_pair_probe = def(out_pin, in_pin)
    calls.push(["pair_probe", out_pin, in_pin])
    return {"ok": out_pin == 0, "out_pin": out_pin, "in_pin": in_pin, "ok_count": out_pin == 0 ? 7 : 6, "failed_count": out_pin == 0 ? 0 : 1, "failed_checks": out_pin == 0 ? [] : ["gpio"]}
end
reset_calls()
var bidir_probe = p2smart.jumper_pairs_bidirectional_probe([[0, 1], [2, 3]])
assert(!bidir_probe["ok"])
assert(bidir_probe["bidirectional"])
assert(bidir_probe["count"] == 4)
assert(bidir_probe["direction_count"] == 4)
assert(bidir_probe["ok_count"] == 1)
assert(bidir_probe["failed_pairs"] == [[1, 0], [2, 3], [3, 2]])
assert(bidir_probe["failures"][0]["pair"] == [1, 0])
assert(bidir_probe["failures"][0]["ok_count"] == 6)
assert(bidir_probe["failures"][0]["failed_count"] == 1)
assert(bidir_probe["failures"][0]["failed_checks"] == ["gpio"])
assert(bidir_probe["source_pairs"] == [[0, 1], [2, 3]])
assert(bidir_probe["pairs"] == [[0, 1], [1, 0], [2, 3], [3, 2]])
assert(calls == [["pair_probe", 0, 1], ["pair_probe", 1, 0], ["pair_probe", 2, 3], ["pair_probe", 3, 2]])
reset_calls()
var default_bidir_probe = p2smart.default_jumper_pairs_bidirectional_probe()
assert(default_bidir_probe["bidirectional"])
assert(default_bidir_probe["direction_count"] == 8)
assert(default_bidir_probe["source_pairs"] == [[0, 1], [2, 3], [4, 5], [6, 7]])
assert(calls.size() == 8)
expect_error(def () p2smart.jumper_pairs_bidirectional_probe([]) end)
p2smart.jumper_pair_probe = saved_pair_probe
expect_error(def () p2smart.jumper_pairs_probe(nil) end)
expect_error(def () p2smart.jumper_pairs_probe([]) end)
expect_error(def () p2smart.jumper_pairs_probe([[0]]) end)
expect_error(def () p2smart.jumper_pairs_probe([[2, 2]]) end)
expect_error(def () p2smart.jumper_pairs_probe([[0, 64]]) end)
reset_calls()
var saved_pairs_probe = p2smart.jumper_pairs_probe
p2smart.jumper_pairs_probe = def(pairs)
    calls.push(["pairs_probe", pairs])
    return {"ok": true, "pairs": pairs}
end
var default_pairs_probe = p2smart.default_jumper_pairs_probe()
assert(default_pairs_probe["ok"])
assert(default_pairs_probe["pairs"] == [[0, 1], [2, 3], [4, 5], [6, 7]])
assert(calls == [["pairs_probe", [[0, 1], [2, 3], [4, 5], [6, 7]]]])
p2smart.jumper_pairs_probe = saved_pairs_probe
p2smart.raw_smartpin_probe = saved_raw_probe
p2smart.gpio_loopback_probe = saved_gpio_probe
p2smart.high_counter_probe = saved_high_probe
p2smart.pulse_counter_probe = saved_pulse_probe
p2smart.transition_counter_probe = saved_transition_probe
p2smart.async_serial_probe = saved_async_probe
p2smart.async_serial_drain_probe = saved_async_drain_probe
expect_error(def () p2smart.jumper_pair_probe(2, 2) end)

reset_calls()
assert(p2smart.serial_bit_ticks(1000000) == 200)
assert(calls == [["clock.freq"]])

reset_calls()
var serial = p2smart.async_serial_pair_ticks(6, 7, 200, 8, nil, nil)
assert(serial.x() == 200 * 65536 + 7)
assert(serial.info()["tx_mode"] == smart.oe + smart.async_tx)
assert(serial.info()["rx_mode"] == smart.async_rx)
serial.start()
assert(calls == [
    ["smart.start", 6, smart.oe + smart.async_tx, 200 * 65536 + 7, 0],
    ["smart.start", 7, smart.async_rx, 200 * 65536 + 7, 0]
])
serial.send(0x5a)
assert(calls[calls.size() - 1] == ["smart.wypin", 6, 0x5a])
smart.rq_value = 1
assert(serial.available() == 1)
assert(calls[calls.size() - 1] == ["smart.rqpin", 7])
smart.rd_value = 0xa5000000
assert(serial.read_raw() == 0xa5000000)
assert(calls[calls.size() - 1] == ["smart.rdpin", 7])
assert(serial.read_byte() == 0xa5)
reset_calls()
smart.rd_value = 0x5a000000
assert(serial.read_byte_after(25) == 0x5a)
assert(calls == [
    ["waitus", 25],
    ["smart.rdpin", 7]
])
reset_calls()
smart.rq_value = 0
smart.rd_value = 0xff000000
var no_byte = serial.read_result()
assert(!no_byte["ready"])
assert(no_byte["event"] == 0)
assert(no_byte["raw"] == 0)
assert(no_byte["value"] == nil)
assert(calls == [
    ["smart.rqpin", 7]
])
reset_calls()
smart.rq_value = 1
smart.rd_value = 0
var zero_byte = serial.read_result()
assert(zero_byte["ready"])
assert(zero_byte["event"] == 1)
assert(zero_byte["raw"] == 0)
assert(zero_byte["value"] == 0)
assert(calls == [
    ["smart.rqpin", 7],
    ["smart.rdpin", 7]
])
reset_calls()
smart.rq_value = 1
smart.rd_value = 0x7e000000
var delayed = serial.read_result_after(25)
assert(delayed["ready"])
assert(delayed["delayed"])
assert(delayed["event"] == nil)
assert(delayed["value"] == 0x7e)
assert(calls == [
    ["waitus", 25],
    ["smart.rdpin", 7]
])
reset_calls()
smart.rq_value = 0
smart.rd_value = 0
var delayed_zero = serial.read_result_after(25)
assert(delayed_zero["ready"])
assert(delayed_zero["delayed"])
assert(delayed_zero["event"] == nil)
assert(delayed_zero["raw"] == 0)
assert(delayed_zero["value"] == 0)
assert(calls == [
    ["waitus", 25],
    ["smart.rdpin", 7]
])
reset_calls()
assert(serial.send_bytes([0, 0x55, 0xff], 10) == 3)
assert(calls == [
    ["smart.wypin", 6, 0],
    ["waitus", 10],
    ["smart.wypin", 6, 0x55],
    ["waitus", 10],
    ["smart.wypin", 6, 0xff],
    ["waitus", 10]
])
expect_error(def () serial.send_bytes(nil, 0) end)
expect_error(def () serial.send_bytes([256], 0) end)
reset_calls()
smart.rd_value = 0xa5000000
assert(serial.exchange_bytes_after([0x11, 0x22], 25) == [0xa5, 0xa5])
assert(calls == [
    ["smart.wypin", 6, 0x11],
    ["waitus", 25],
    ["smart.rdpin", 7],
    ["smart.wypin", 6, 0x22],
    ["waitus", 25],
    ["smart.rdpin", 7]
])
reset_calls()
smart.rd_value = 0
var exchange_results = serial.exchange_results_after([0], 25)
assert(exchange_results.size() == 1)
assert(exchange_results[0]["ready"])
assert(exchange_results[0]["value"] == 0)
assert(exchange_results[0]["event"] == nil)
expect_error(def () serial.exchange_bytes_after(nil, 0) end)
expect_error(def () serial.exchange_results_after([300], 0) end)
reset_calls()
var drain_events = [1, 1, 0]
var drain_reads = [0x11000000, 0x00000000]
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    var value = drain_events[0]
    drain_events = drain_events[1..]
    return value
end
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = drain_reads[0]
    drain_reads = drain_reads[1..]
    return value
end
var drained = serial.read_available_results(4)
assert(drained["ok"])
assert(drained["values"] == [0x11, 0])
assert(drained["count"] == 2)
assert(drained["limit"] == 4)
assert(drained["acked"] == 2)
assert(drained["stopped_reason"] == "not_ready")
assert(drained["results"][0]["event"] == 1)
assert(drained["results"][0]["raw"] == 0x11000000)
assert(drained["results"][1]["value"] == 0)
assert(calls == [
    ["smart.rqpin", 7],
    ["smart.rdpin", 7],
    ["smart.akpin", 7],
    ["smart.rqpin", 7],
    ["smart.rdpin", 7],
    ["smart.akpin", 7],
    ["smart.rqpin", 7]
])
reset_calls()
drain_events = [1, 1]
drain_reads = [0xaa000000, 0xbb000000]
assert(serial.read_available(2) == [0xaa, 0xbb])
assert(calls == [
    ["smart.rqpin", 7],
    ["smart.rdpin", 7],
    ["smart.akpin", 7],
    ["smart.rqpin", 7],
    ["smart.rdpin", 7],
    ["smart.akpin", 7]
])
reset_calls()
drain_events = [1]
drain_reads = [0xcc000000]
var limited_drain = serial.read_available_results(1)
assert(limited_drain["values"] == [0xcc])
assert(limited_drain["stopped_reason"] == "limit")
expect_error(def () serial.read_available_results(-1) end)
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    return smart.rq_value
end
serial.ack()
assert(calls[calls.size() - 1] == ["smart.akpin", 7])
reset_calls()
serial.clear()
assert(calls == [
    ["smart.clear", 6],
    ["smart.clear", 7],
    ["pin.float", 6],
    ["pin.float", 7]
])
assert(!serial.info()["started"])

reset_calls()
smart.rq_value = 1
var serial_probe = p2smart.async_serial_probe(6, 7, [0, 0xa5], 12, 1000000, 8)
assert(serial_probe["ok"])
assert(serial_probe["tx_pin"] == 6)
assert(serial_probe["rx_pin"] == 7)
assert(serial_probe["values"] == [0, 0xa5])
assert(serial_probe["count"] == 2)
assert(serial_probe["ready_count"] == 2)
assert(serial_probe["wait_us"] == 12)
assert(serial_probe["serial"]["x"] == 200 * 65536 + 7)
assert(serial_probe["results"][0]["sent"] == 0)
assert(serial_probe["results"][0]["event"] == 1)
assert(serial_probe["results"][0]["ready"])
assert(serial_probe["results"][1]["sent"] == 0xa5)
assert(calls == [
    ["clock.freq"],
    ["smart.start", 6, smart.oe + smart.async_tx, 200 * 65536 + 7, 0],
    ["smart.start", 7, smart.async_rx, 200 * 65536 + 7, 0],
    ["smart.wypin", 6, 0],
    ["waitus", 12],
    ["smart.rqpin", 7],
    ["smart.akpin", 7],
    ["smart.wypin", 6, 0xa5],
    ["waitus", 12],
    ["smart.rqpin", 7],
    ["smart.akpin", 7],
    ["smart.clear", 6],
    ["smart.clear", 7],
    ["pin.float", 6],
    ["pin.float", 7]
])

reset_calls()
drain_events = [1, 0]
drain_reads = [0x33000000]
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    var value = drain_events[0]
    drain_events = drain_events[1..]
    return value
end
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = drain_reads[0]
    drain_reads = drain_reads[1..]
    return value
end
var drain_probe = p2smart.async_serial_drain_probe(6, 7, 0x33, 12, 1000000, 8, 4)
assert(drain_probe["ok"])
assert(drain_probe["tx_pin"] == 6)
assert(drain_probe["rx_pin"] == 7)
assert(drain_probe["sent"] == 0x33)
assert(drain_probe["wait_us"] == 12)
assert(drain_probe["max_count"] == 4)
assert(drain_probe["matched"])
assert(drain_probe["drained"]["values"] == [0x33])
assert(drain_probe["drained"]["count"] == 1)
assert(drain_probe["drained"]["acked"] == 1)
assert(drain_probe["drained"]["stopped_reason"] == "not_ready")
assert(!drain_probe["serial"]["started"])
assert(calls == [
    ["clock.freq"],
    ["smart.start", 6, smart.oe + smart.async_tx, 200 * 65536 + 7, 0],
    ["smart.start", 7, smart.async_rx, 200 * 65536 + 7, 0],
    ["smart.wypin", 6, 0x33],
    ["waitus", 12],
    ["smart.rqpin", 7],
    ["smart.rdpin", 7],
    ["smart.akpin", 7],
    ["smart.rqpin", 7],
    ["smart.clear", 6],
    ["smart.clear", 7],
    ["pin.float", 6],
    ["pin.float", 7]
])
expect_error(def () p2smart.async_serial_drain_probe(6, 7, 300, 12, 1000000, 8, 4) end)
expect_error(def () p2smart.async_serial_drain_probe(6, 7, 0x33, 12, 1000000, 8, -1) end)
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end
smart.rqpin = def(pin_no)
    calls.push(["smart.rqpin", pin_no])
    return smart.rq_value
end

reset_calls()
var serial_reverse = p2smart.async_serial_pair_ticks(7, 6, 200, 8, nil, nil)
assert(serial_reverse.info()["rx_mode"] == smart.async_rx)

reset_calls()
var sync = p2smart.sync_serial_pair_ticks(12, 13, 160, 8, nil, nil)
assert(sync.info()["kind"] == "SyncSerialPair")
assert(sync.x() == 160 * 65536 + 7)
assert(sync.info()["tx_mode"] == smart.oe + smart.sync_io + smart.sync_tx)
assert(sync.info()["rx_mode"] == smart.sync_io + smart.sync_rx)
sync.start()
assert(calls == [
    ["smart.start", 12, smart.oe + smart.sync_io + smart.sync_tx, 160 * 65536 + 7, 0],
    ["smart.start", 13, smart.sync_io + smart.sync_rx, 160 * 65536 + 7, 0]
])
sync.send(0x5a)
assert(calls[calls.size() - 1] == ["smart.wypin", 12, 0x5a])
smart.rq_value = 1
assert(sync.available() == 1)
assert(calls[calls.size() - 1] == ["smart.rqpin", 13])
smart.rd_value = 0x005a
assert(sync.read_raw() == 0x005a)
assert(calls[calls.size() - 1] == ["smart.rdpin", 13])
smart.rq_value = 0
reset_calls()
var sync_not_ready = sync.read_result()
assert(!sync_not_ready["ok"])
assert(!sync_not_ready["ready"])
assert(sync_not_ready["event"] == 0)
assert(sync_not_ready["raw"] == nil)
assert(sync_not_ready["value"] == nil)
assert(sync_not_ready["error"] == "not_ready")
assert(calls == [["smart.rqpin", 13]])
smart.rq_value = 1
smart.rd_value = 0x1234
reset_calls()
var sync_ready = sync.read_result()
assert(sync_ready["ok"])
assert(sync_ready["ready"])
assert(sync_ready["event"] == 1)
assert(sync_ready["raw"] == 0x1234)
assert(sync_ready["value"] == 0x1234)
assert(sync_ready["error"] == nil)
assert(calls == [["smart.rqpin", 13], ["smart.rdpin", 13]])
smart.rq_value = 1
smart.rd_value = 0x77
reset_calls()
var sync_after = sync.read_result_after(25)
assert(sync_after["ok"])
assert(sync_after["value"] == 0x77)
assert(sync_after["delayed"])
assert(calls == [["waitus", 25], ["smart.rqpin", 13], ["smart.rdpin", 13]])
smart.rq_value = 1
smart.rd_value = 0x5a
reset_calls()
var sync_transfer = sync.transfer_result(0x5a, 25, nil)
assert(sync_transfer["ok"])
assert(sync_transfer["sent"] == 0x5a)
assert(sync_transfer["value"] == 0x5a)
assert(sync_transfer["matched"])
assert(sync_transfer["delayed"])
assert(!sync_transfer["clocked"])
assert(calls == [["smart.akpin", 13], ["smart.wypin", 12, 0x5a], ["waitus", 25], ["smart.rqpin", 13], ["smart.rdpin", 13]])
smart.rq_value = 1
smart.rd_value = 0x23
reset_calls()
var sync_transfers = sync.transfer_results([0x23], 25, nil)
assert(sync_transfers.size() == 1)
assert(sync_transfers[0]["sent"] == 0x23)
assert(sync_transfers[0]["matched"])
expect_error(def () sync.transfer_result(-1, 0, nil) end)
expect_error(def () sync.transfer_results(nil, 0, nil) end)
sync.ack()
assert(calls[calls.size() - 1] == ["smart.akpin", 13])
sync.clear()
assert(calls[calls.size() - 4] == ["smart.clear", 12])
assert(calls[calls.size() - 3] == ["smart.clear", 13])
assert(calls[calls.size() - 2] == ["pin.float", 12])
assert(calls[calls.size() - 1] == ["pin.float", 13])

reset_calls()
smart.rq_value = 1
smart.rd_value = 0x23
var sync_probe = p2smart.sync_serial_probe(12, 13, [0x23], 25, 1250000, 8)
assert(sync_probe["ok"])
assert(sync_probe["tx_pin"] == 12)
assert(sync_probe["rx_pin"] == 13)
assert(sync_probe["values"] == [0x23])
assert(sync_probe["count"] == 1)
assert(sync_probe["ready_count"] == 1)
assert(sync_probe["matched_count"] == 1)
assert(sync_probe["wait_us"] == 25)
assert(sync_probe["serial"]["x"] == 160 * 65536 + 7)
assert(sync_probe["results"][0]["matched"])
assert(calls == [
    ["clock.freq"],
    ["smart.start", 12, smart.oe + smart.sync_io + smart.sync_tx, 160 * 65536 + 7, 0],
    ["smart.start", 13, smart.sync_io + smart.sync_rx, 160 * 65536 + 7, 0],
    ["smart.akpin", 13],
    ["smart.wypin", 12, 0x23],
    ["waitus", 25],
    ["smart.rqpin", 13],
    ["smart.rdpin", 13],
    ["smart.clear", 12],
    ["smart.clear", 13],
    ["pin.float", 12],
    ["pin.float", 13]
])

reset_calls()
smart.rq_value = 1
smart.rd_value = 0x34
var sync_clocked_probe = p2smart.sync_serial_clocked_probe(0, 1, 2, 3, [0x34], 25, 1250000, 8)
assert(sync_clocked_probe["ok"])
assert(sync_clocked_probe["data_tx_pin"] == 0)
assert(sync_clocked_probe["data_rx_pin"] == 1)
assert(sync_clocked_probe["clock_tx_pin"] == 2)
assert(sync_clocked_probe["clock_rx_pin"] == 3)
assert(sync_clocked_probe["values"] == [0x34])
assert(sync_clocked_probe["count"] == 1)
assert(sync_clocked_probe["ready_count"] == 1)
assert(sync_clocked_probe["matched_count"] == 1)
assert(sync_clocked_probe["results"][0]["matched"])
assert(sync_clocked_probe["results"][0]["clocked"])
assert(sync_clocked_probe["serial"]["tx_mode"] == smart.oe + smart.sync_io + smart.plus2_b + smart.sync_tx)
assert(sync_clocked_probe["serial"]["rx_mode"] == smart.sync_io + smart.plus2_b + smart.sync_rx)
assert(calls == [
    ["clock.freq"],
    ["pin.float", 3],
    ["smart.start", 2, smart.oe + smart.pulse, 1000 * 65536 + 2000, 0],
    ["smart.wypin", 2, 0],
    ["smart.start", 0, smart.oe + smart.sync_io + smart.plus2_b + smart.sync_tx, 160 * 65536 + 7, 0],
    ["smart.start", 1, smart.sync_io + smart.plus2_b + smart.sync_rx, 160 * 65536 + 7, 0],
    ["smart.akpin", 1],
    ["smart.wypin", 0, 0x34],
    ["smart.wypin", 2, 8],
    ["waitus", 25],
    ["smart.rqpin", 1],
    ["smart.rdpin", 1],
    ["smart.clear", 0],
    ["smart.clear", 1],
    ["pin.float", 0],
    ["pin.float", 1],
    ["smart.clear", 2],
    ["pin.float", 2],
    ["pin.float", 3]
])

reset_calls()
var saved_sync_clocked_probe = p2smart.sync_serial_clocked_probe
p2smart.sync_serial_clocked_probe = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    calls.push(["sync_clocked_probe", data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits])
    return {
        "ok": data_tx_pin == 0,
        "data_tx_pin": data_tx_pin,
        "data_rx_pin": data_rx_pin,
        "clock_tx_pin": clock_tx_pin,
        "clock_rx_pin": clock_rx_pin,
        "values": values,
        "ready_count": data_tx_pin == 0 ? 2 : 1,
        "matched_count": data_tx_pin == 0 ? 2 : 0
    }
end
var sync_groups = p2smart.sync_serial_clocked_jumper_probes([[0, 1, 2, 3], [4, 5, 6, 7]], [0x12, 0x34], 50, 1000000, 8)
assert(!sync_groups["ok"])
assert(sync_groups["groups"] == [[0, 1, 2, 3], [4, 5, 6, 7]])
assert(sync_groups["count"] == 2)
assert(sync_groups["ok_count"] == 1)
assert(sync_groups["failed_count"] == 1)
assert(sync_groups["failed_groups"] == [[4, 5, 6, 7]])
assert(sync_groups["failures"].size() == 1)
assert(sync_groups["failures"][0]["group"] == [4, 5, 6, 7])
assert(sync_groups["failures"][0]["ready_count"] == 1)
assert(sync_groups["failures"][0]["matched_count"] == 0)
assert(sync_groups["results"][0]["values"] == [0x12, 0x34])
assert(calls == [
    ["sync_clocked_probe", 0, 1, 2, 3, [0x12, 0x34], 50, 1000000, 8],
    ["sync_clocked_probe", 4, 5, 6, 7, [0x12, 0x34], 50, 1000000, 8]
])
reset_calls()
p2smart.sync_serial_clocked_probe = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    calls.push(["sync_clocked_probe_error", data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin])
    raise "probe_error", "sync failed"
end
var sync_failure = p2smart.sync_serial_clocked_jumper_probes([[0, 1, 2, 3]], [0x12], 50, 1000000, 8)
assert(!sync_failure["ok"])
assert(sync_failure["failed_groups"] == [[0, 1, 2, 3]])
assert(sync_failure["failures"][0]["error"] == "probe_error")
assert(sync_failure["results"][0]["cleanup_attempted"])
assert(calls == [
    ["sync_clocked_probe_error", 0, 1, 2, 3],
    ["smart.clear", 0],
    ["pin.float", 0],
    ["smart.clear", 1],
    ["pin.float", 1],
    ["smart.clear", 2],
    ["pin.float", 2],
    ["smart.clear", 3],
    ["pin.float", 3]
])
reset_calls()
p2smart.sync_serial_clocked_probe = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    calls.push(["sync_clocked_default", data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits])
    return {"ok": true, "ready_count": 1, "matched_count": 1}
end
var default_sync = p2smart.sync_serial_default_clocked_probe([0xa5], 75, 1000000, 8)
assert(default_sync["ok"])
assert(default_sync["groups"] == [[0, 1, 2, 3], [4, 5, 6, 7]])
assert(default_sync["count"] == 2)
assert(default_sync["ok_count"] == 2)
assert(calls == [
    ["sync_clocked_default", 0, 1, 2, 3, [0xa5], 75, 1000000, 8],
    ["sync_clocked_default", 4, 5, 6, 7, [0xa5], 75, 1000000, 8]
])
p2smart.sync_serial_clocked_probe = saved_sync_clocked_probe

reset_calls()
var variants = p2smart.sync_serial_clocked_variants(0, 1, 2, 3)
assert(variants.size() == 4)
assert(variants[0]["name"] == "normal_clock")
assert(variants[0]["tx_mode"] == smart.oe + smart.sync_io + smart.plus2_b + smart.sync_tx)
assert(variants[0]["rx_mode"] == smart.sync_io + smart.plus2_b + smart.sync_rx)
assert(variants[0]["clock_mode"] == smart.oe + smart.pulse)
assert(variants[1]["name"] == "inverted_rx_clock")
assert(variants[1]["rx_mode"] == smart.sync_io + smart.invert_b + smart.plus2_b + smart.sync_rx)
assert(variants[2]["name"] == "inverted_clock_output")
assert(variants[2]["clock_mode"] == smart.oe + smart.invert_output + smart.pulse)
assert(variants[3]["name"] == "inverted_output_and_rx_clock")
assert(variants[3]["rx_mode"] == smart.sync_io + smart.invert_b + smart.plus2_b + smart.sync_rx)
assert(variants[3]["clock_mode"] == smart.oe + smart.invert_output + smart.pulse)

reset_calls()
smart.rq_value = 1
smart.rd_value = 0x56
var variant_probe = p2smart.sync_serial_clocked_variant_probe(0, 1, 2, 3, [0x56], 25, 1250000, 8)
assert(!variant_probe["ok"])
assert(!variant_probe["execution_supported"])
assert(variant_probe["variant_count"] == 4)
assert(variant_probe["selected_variant"] == nil)
assert(variant_probe["selected"] == nil)
assert(variant_probe["error"] == "execution_deferred")
assert(variant_probe["ready_count"] == 0)
assert(variant_probe["matched_count"] == 0)
assert(variant_probe["results"][0]["variant"] == "normal_clock")
assert(variant_probe["results"][0]["error"] == "execution_deferred")
assert(variant_probe["results"][1]["variant"] == "inverted_rx_clock")
assert(variant_probe["results"][1]["rx_mode"] == smart.sync_io + smart.invert_b + smart.plus2_b + smart.sync_rx)
assert(variant_probe["results"][2]["clock_mode"] == smart.oe + smart.invert_output + smart.pulse)

reset_calls()
var default_sync_variants = p2smart.sync_serial_default_clocked_variant_probe([0xa5], 75, 1000000, 8)
assert(!default_sync_variants["ok"])
assert(!default_sync_variants["execution_supported"])
assert(default_sync_variants["error"] == "execution_deferred")
assert(default_sync_variants["groups"] == [[0, 1, 2, 3], [4, 5, 6, 7]])
assert(default_sync_variants["count"] == 2)
assert(default_sync_variants["ok_count"] == 0)
assert(default_sync_variants["failed_count"] == 2)
assert(default_sync_variants["results"][0]["variant_count"] == 4)
assert(default_sync_variants["results"][0]["execution_supported"] == false)
assert(default_sync_variants["results"][0]["error"] == "execution_deferred")
assert(default_sync_variants["failures"][0]["variant_count"] == 4)
expect_error(def () p2smart.sync_serial_clocked_jumper_probes(nil, [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_probes([], [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_probes([[0, 1, 2]], [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_probes([[0, 1, 2, 2]], [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_variant_probes(nil, [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_variant_probes([], [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_variant_probes([[0, 1, 2]], [0], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_jumper_variant_probes([[0, 1, 2, 2]], [0], 0, 1000000, 8) end)

reset_calls()
var adc = p2smart.adc(8, nil, nil)
assert(adc.info()["mode"] == smart.adc_1x + smart.adc)
assert(adc.info()["sample_ticks"] == 256)
adc.start()
assert(calls == [
    ["smart.start", 8, smart.adc_1x + smart.adc, 256, 0],
    ["smart.akpin", 8]
])
smart.rd_value = 12345
assert(adc.read() == 12345)
assert(calls[calls.size() - 1] == ["smart.rdpin", 8])
smart.rq_value = 1
assert(adc.query() == 1)
assert(calls[calls.size() - 1] == ["smart.rqpin", 8])
reset_calls()
smart.rq_value = 1
smart.rd_value = 23456
var adc_result = adc.read_result()
assert(adc_result["ok"])
assert(adc_result["ready"])
assert(adc_result["event"] == 1)
assert(adc_result["raw"] == 23456)
assert(adc_result["value"] == 23456)
assert(adc_result["pin"] == 8)
assert(calls == [["smart.rqpin", 8], ["smart.rdpin", 8]])
reset_calls()
smart.rq_value = 0
smart.rd_value = 34567
var adc_after = adc.sample_after(25)
assert(adc_after["ok"])
assert(!adc_after["ready"])
assert(adc_after["event"] == 0)
assert(adc_after["value"] == 34567)
assert(adc_after["delayed"])
assert(adc_after["wait_us"] == 25)
assert(calls == [["waitus", 25], ["smart.rqpin", 8], ["smart.rdpin", 8]])
adc.ack()
assert(calls[calls.size() - 1] == ["smart.akpin", 8])
adc.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 8])
assert(calls[calls.size() - 1] == ["pin.float", 8])

assert(p2smart.adc_mode(nil, nil) == smart.adc_1x + smart.adc)
assert(p2smart.adc_mode("gio", "adc") == smart.adc_gio + smart.adc)
assert(p2smart.adc_mode("vio", "adc_ext") == smart.adc_vio + smart.adc_ext)
assert(p2smart.adc_mode("float", "adc_scope") == smart.adc_float + smart.adc_scope)
assert(p2smart.adc_mode("3x", nil) == smart.adc_3x + smart.adc)
assert(p2smart.adc_mode("10x", nil) == smart.adc_10x + smart.adc)
assert(p2smart.adc_mode("30x", nil) == smart.adc_30x + smart.adc)
assert(p2smart.adc_mode("100x", nil) == smart.adc_100x + smart.adc)
reset_calls()
var adc_variant = p2smart.adc_variant(8, "vio", "adc_ext", 128)
assert(adc_variant.info()["mode"] == smart.adc_vio + smart.adc_ext)
assert(adc_variant.info()["sample_ticks"] == 128)
adc_variant.start()
assert(calls == [
    ["smart.start", 8, smart.adc_vio + smart.adc_ext, 128, 0],
    ["smart.akpin", 8]
])
adc_variant.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 8])
assert(calls[calls.size() - 1] == ["pin.float", 8])

reset_calls()
smart.rq_value = 1
smart.rd_value = 45678
var adc_variant_probe = p2smart.adc_variant_sample_probe(8, "vio", "adc_ext", 128, 30)
assert(adc_variant_probe["ok"])
assert(adc_variant_probe["pin"] == 8)
assert(adc_variant_probe["source"] == "vio")
assert(adc_variant_probe["family"] == "adc_ext")
assert(adc_variant_probe["mode"] == smart.adc_vio + smart.adc_ext)
assert(adc_variant_probe["sample_ticks"] == 128)
assert(adc_variant_probe["wait_us"] == 30)
assert(adc_variant_probe["sample"]["ready"])
assert(adc_variant_probe["sample"]["event"] == 1)
assert(adc_variant_probe["sample"]["value"] == 45678)
assert(adc_variant_probe["sample"]["delayed"])
assert(adc_variant_probe["adc"]["mode"] == smart.adc_vio + smart.adc_ext)
assert(calls == [
    ["smart.start", 8, smart.adc_vio + smart.adc_ext, 128, 0],
    ["smart.akpin", 8],
    ["waitus", 30],
    ["smart.rqpin", 8],
    ["smart.rdpin", 8],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.adc_variant_sample_probe(0, "bad", nil, 256, 0) end)

reset_calls()
var dac = p2smart.dac(9, 64, 256, nil)
assert(dac.info()["mode"] == smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm)
dac.start()
assert(calls == [
    ["smart.start", 9, smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm, 256, 64]
])
dac.set(192)
assert(calls[calls.size() - 1] == ["smart.wypin", 9, 192])
assert(dac.info()["value"] == 192)
reset_calls()
var dac_result = dac.set_result(128, 15)
assert(dac_result["ok"])
assert(dac_result["pin"] == 9)
assert(dac_result["value"] == 128)
assert(dac_result["frame"] == 256)
assert(dac_result["settled"])
assert(dac_result["settle_us"] == 15)
assert(calls == [["smart.wypin", 9, 128], ["waitus", 15]])
dac.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 9])
assert(calls[calls.size() - 1] == ["pin.float", 9])

assert(p2smart.dac_mode(nil, nil) == smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm)
assert(p2smart.dac_mode("600r_2v", "dither_rnd") == smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd)
assert(p2smart.dac_mode("124r_3v", "noise") == smart.oe + smart.dac_124r_3v + smart.dac_noise)
assert(p2smart.dac_mode("75r_2v", "plain") == smart.oe + smart.dac_75r_2v)
reset_calls()
var dac_variant = p2smart.dac_variant(10, 32, 128, "600r_2v", "dither_rnd")
assert(dac_variant.info()["mode"] == smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd)
dac_variant.start()
assert(calls == [
    ["smart.start", 10, smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd, 128, 32]
])
dac_variant.clear()
assert(calls[calls.size() - 2] == ["smart.clear", 10])
assert(calls[calls.size() - 1] == ["pin.float", 10])

reset_calls()
var probe_reads = [100, 140]
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    var value = probe_reads[0]
    probe_reads = probe_reads[1..]
    return value
end
var probe = p2smart.dac_adc_probe(9, 8, 0, 255, 10, 4)
assert(probe["ok"])
assert(probe["low_raw"] == 100)
assert(probe["high_raw"] == 140)
assert(probe["delta"] == 40)
assert(probe["abs_delta"] == 40)
assert(probe["threshold"] == 4)
assert(calls == [
    ["smart.start", 8, smart.adc_1x + smart.adc, 256, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm, 256, 0],
    ["waitus", 10],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 255],
    ["waitus", 10],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
reset_calls()
probe_reads = [50, 50]
probe = p2smart.dac_adc_probe(9, 8, 0, 255, 0, 1)
assert(!probe["ok"])
assert(probe["reason"] == "delta_below_threshold")
assert(probe["abs_delta"] == 0)
expect_error(def () p2smart.dac_adc_probe(0, 1, -1, 255, 0, 1) end)
expect_error(def () p2smart.dac_adc_probe(0, 1, 0, 256, 0, 1) end)
expect_error(def () p2smart.dac_adc_probe(0, 1, 0, 255, -1, 1) end)

reset_calls()
probe_reads = [100, 102, 104, 140, 142, 144]
var sampled_probe = p2smart.dac_adc_sampled_probe(9, 8, 0, 255, 10, 4, 3, 5)
assert(sampled_probe["ok"])
assert(sampled_probe["low"]["samples"] == [100, 102, 104])
assert(sampled_probe["high"]["samples"] == [140, 142, 144])
assert(sampled_probe["low"]["min"] == 100)
assert(sampled_probe["low"]["max"] == 104)
assert(sampled_probe["low"]["avg"] == 102)
assert(sampled_probe["high"]["min"] == 140)
assert(sampled_probe["high"]["max"] == 144)
assert(sampled_probe["high"]["avg"] == 142)
assert(sampled_probe["delta"] == 40)
assert(sampled_probe["abs_delta"] == 40)
assert(sampled_probe["min_to_max_delta"] == 36)
assert(sampled_probe["max_to_min_delta"] == 44)
assert(sampled_probe["sample_count"] == 3)
assert(sampled_probe["sample_interval_us"] == 5)
assert(sampled_probe["polarity"] == "positive")
assert(!sampled_probe["polarity_verified"])
assert(!sampled_probe["calibrated_voltage"])
assert(calls == [
    ["smart.start", 8, smart.adc_1x + smart.adc, 256, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm, 256, 0],
    ["waitus", 10],
    ["smart.rdpin", 8],
    ["waitus", 5],
    ["smart.rdpin", 8],
    ["waitus", 5],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 255],
    ["waitus", 10],
    ["smart.rdpin", 8],
    ["waitus", 5],
    ["smart.rdpin", 8],
    ["waitus", 5],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.dac_adc_sampled_probe(0, 1, 0, 255, 0, 1, 0, 0) end)
expect_error(def () p2smart.dac_adc_sampled_probe(0, 1, 0, 255, 0, 1, 33, 0) end)
expect_error(def () p2smart.dac_adc_sampled_probe(0, 1, 0, 255, 0, 1, 1, -1) end)

reset_calls()
probe_reads = [90, 135]
var variant_probe = p2smart.dac_variant_adc_probe(9, 8, 5, 200, 128, "600r_2v", "dither_rnd", 12, 10)
assert(variant_probe["ok"])
assert(variant_probe["out_pin"] == 9)
assert(variant_probe["in_pin"] == 8)
assert(variant_probe["low_value"] == 5)
assert(variant_probe["high_value"] == 200)
assert(variant_probe["low_raw"] == 90)
assert(variant_probe["high_raw"] == 135)
assert(variant_probe["delta"] == 45)
assert(variant_probe["abs_delta"] == 45)
assert(variant_probe["threshold"] == 10)
assert(variant_probe["settle_us"] == 12)
assert(variant_probe["resistor"] == "600r_2v")
assert(variant_probe["dither"] == "dither_rnd")
assert(variant_probe["dac"]["mode"] == smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd)
assert(variant_probe["dac"]["frame"] == 128)
assert(variant_probe["adc"]["mode"] == smart.adc_1x + smart.adc)
assert(calls == [
    ["smart.start", 8, smart.adc_1x + smart.adc, 256, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd, 128, 5],
    ["waitus", 12],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 200],
    ["waitus", 12],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.dac_variant_adc_probe(0, 1, 0, 255, 256, "bad", nil, 0, 1) end)

reset_calls()
probe_reads = [10, 12, 14, 30, 32, 34]
var sampled_variant_probe = p2smart.dac_variant_adc_sampled_probe(9, 8, 5, 200, 128, "600r_2v", "dither_rnd", 12, 10, 3, 7)
assert(sampled_variant_probe["ok"])
assert(sampled_variant_probe["out_pin"] == 9)
assert(sampled_variant_probe["in_pin"] == 8)
assert(sampled_variant_probe["low_value"] == 5)
assert(sampled_variant_probe["high_value"] == 200)
assert(sampled_variant_probe["low"]["samples"] == [10, 12, 14])
assert(sampled_variant_probe["high"]["samples"] == [30, 32, 34])
assert(sampled_variant_probe["low"]["min"] == 10)
assert(sampled_variant_probe["low"]["max"] == 14)
assert(sampled_variant_probe["low"]["avg"] == 12)
assert(sampled_variant_probe["high"]["min"] == 30)
assert(sampled_variant_probe["high"]["max"] == 34)
assert(sampled_variant_probe["high"]["avg"] == 32)
assert(sampled_variant_probe["delta"] == 20)
assert(sampled_variant_probe["abs_delta"] == 20)
assert(sampled_variant_probe["min_to_max_delta"] == 16)
assert(sampled_variant_probe["max_to_min_delta"] == 24)
assert(sampled_variant_probe["sample_count"] == 3)
assert(sampled_variant_probe["threshold"] == 10)
assert(sampled_variant_probe["settle_us"] == 12)
assert(sampled_variant_probe["sample_interval_us"] == 7)
assert(sampled_variant_probe["polarity"] == "positive")
assert(!sampled_variant_probe["polarity_verified"])
assert(!sampled_variant_probe["calibrated_voltage"])
assert(sampled_variant_probe["resistor"] == "600r_2v")
assert(sampled_variant_probe["dither"] == "dither_rnd")
assert(sampled_variant_probe["dac"]["mode"] == smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd)
assert(sampled_variant_probe["dac"]["frame"] == 128)
assert(sampled_variant_probe["adc"]["mode"] == smart.adc_1x + smart.adc)
assert(calls == [
    ["smart.start", 8, smart.adc_1x + smart.adc, 256, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_600r_2v + smart.dac_dither_rnd, 128, 5],
    ["waitus", 12],
    ["smart.rdpin", 8],
    ["waitus", 7],
    ["smart.rdpin", 8],
    ["waitus", 7],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 200],
    ["waitus", 12],
    ["smart.rdpin", 8],
    ["waitus", 7],
    ["smart.rdpin", 8],
    ["waitus", 7],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.dac_variant_adc_sampled_probe(0, 1, 0, 255, 256, "bad", nil, 0, 1, 1, 0) end)
expect_error(def () p2smart.dac_variant_adc_sampled_probe(0, 1, 0, 255, 256, nil, nil, 0, 1, 0, 0) end)
expect_error(def () p2smart.dac_variant_adc_sampled_probe(0, 1, 0, 255, 256, nil, nil, 0, 1, 33, 0) end)
expect_error(def () p2smart.dac_variant_adc_sampled_probe(0, 1, 0, 255, 256, nil, nil, 0, 1, 1, -1) end)

reset_calls()
probe_reads = [20, 22, 24, 50, 52, 54]
var sampled_adc_variant_probe = p2smart.adc_variant_dac_sampled_probe(9, 8, 10, 220, "3x", "adc_ext", 128, 11, 8, 3, 6)
assert(sampled_adc_variant_probe["ok"])
assert(sampled_adc_variant_probe["out_pin"] == 9)
assert(sampled_adc_variant_probe["in_pin"] == 8)
assert(sampled_adc_variant_probe["low_value"] == 10)
assert(sampled_adc_variant_probe["high_value"] == 220)
assert(sampled_adc_variant_probe["low"]["samples"] == [20, 22, 24])
assert(sampled_adc_variant_probe["high"]["samples"] == [50, 52, 54])
assert(sampled_adc_variant_probe["low"]["avg"] == 22)
assert(sampled_adc_variant_probe["high"]["avg"] == 52)
assert(sampled_adc_variant_probe["delta"] == 30)
assert(sampled_adc_variant_probe["abs_delta"] == 30)
assert(sampled_adc_variant_probe["min_to_max_delta"] == 26)
assert(sampled_adc_variant_probe["max_to_min_delta"] == 34)
assert(sampled_adc_variant_probe["sample_count"] == 3)
assert(sampled_adc_variant_probe["threshold"] == 8)
assert(sampled_adc_variant_probe["settle_us"] == 11)
assert(sampled_adc_variant_probe["sample_interval_us"] == 6)
assert(sampled_adc_variant_probe["source"] == "3x")
assert(sampled_adc_variant_probe["family"] == "adc_ext")
assert(sampled_adc_variant_probe["sample_ticks"] == 128)
assert(sampled_adc_variant_probe["polarity"] == "positive")
assert(!sampled_adc_variant_probe["polarity_verified"])
assert(!sampled_adc_variant_probe["calibrated_voltage"])
assert(sampled_adc_variant_probe["dac"]["mode"] == smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm)
assert(sampled_adc_variant_probe["adc"]["mode"] == smart.adc_3x + smart.adc_ext)
assert(sampled_adc_variant_probe["adc"]["sample_ticks"] == 128)
assert(calls == [
    ["smart.start", 8, smart.adc_3x + smart.adc_ext, 128, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_990r_3v + smart.dac_dither_pwm, 256, 10],
    ["waitus", 11],
    ["smart.rdpin", 8],
    ["waitus", 6],
    ["smart.rdpin", 8],
    ["waitus", 6],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 220],
    ["waitus", 11],
    ["smart.rdpin", 8],
    ["waitus", 6],
    ["smart.rdpin", 8],
    ["waitus", 6],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.adc_variant_dac_sampled_probe(0, 1, 0, 255, "bad", nil, 256, 0, 1, 1, 0) end)
expect_error(def () p2smart.adc_variant_dac_sampled_probe(0, 1, 0, 255, nil, nil, 0, 0, 1, 1, 0) end)
expect_error(def () p2smart.adc_variant_dac_sampled_probe(0, 1, 0, 255, nil, nil, 256, 0, 1, 0, 0) end)
expect_error(def () p2smart.adc_variant_dac_sampled_probe(0, 1, 0, 255, nil, nil, 256, 0, 1, 33, 0) end)
expect_error(def () p2smart.adc_variant_dac_sampled_probe(0, 1, 0, 255, nil, nil, 256, 0, 1, 1, -1) end)

reset_calls()
probe_reads = [7, 9, 11, 40, 42, 44]
var sampled_both_variant_probe = p2smart.adc_dac_variants_sampled_probe(9, 8, 15, 210, "10x", "adc_scope", 96, 192, "75r_2v", "plain", 13, 9, 3, 4)
assert(sampled_both_variant_probe["ok"])
assert(sampled_both_variant_probe["out_pin"] == 9)
assert(sampled_both_variant_probe["in_pin"] == 8)
assert(sampled_both_variant_probe["low_value"] == 15)
assert(sampled_both_variant_probe["high_value"] == 210)
assert(sampled_both_variant_probe["low"]["samples"] == [7, 9, 11])
assert(sampled_both_variant_probe["high"]["samples"] == [40, 42, 44])
assert(sampled_both_variant_probe["low"]["avg"] == 9)
assert(sampled_both_variant_probe["high"]["avg"] == 42)
assert(sampled_both_variant_probe["delta"] == 33)
assert(sampled_both_variant_probe["abs_delta"] == 33)
assert(sampled_both_variant_probe["min_to_max_delta"] == 29)
assert(sampled_both_variant_probe["max_to_min_delta"] == 37)
assert(sampled_both_variant_probe["sample_count"] == 3)
assert(sampled_both_variant_probe["threshold"] == 9)
assert(sampled_both_variant_probe["settle_us"] == 13)
assert(sampled_both_variant_probe["sample_interval_us"] == 4)
assert(sampled_both_variant_probe["source"] == "10x")
assert(sampled_both_variant_probe["family"] == "adc_scope")
assert(sampled_both_variant_probe["sample_ticks"] == 96)
assert(sampled_both_variant_probe["resistor"] == "75r_2v")
assert(sampled_both_variant_probe["dither"] == "plain")
assert(sampled_both_variant_probe["polarity"] == "positive")
assert(!sampled_both_variant_probe["polarity_verified"])
assert(!sampled_both_variant_probe["calibrated_voltage"])
assert(sampled_both_variant_probe["dac"]["mode"] == smart.oe + smart.dac_75r_2v)
assert(sampled_both_variant_probe["dac"]["frame"] == 192)
assert(sampled_both_variant_probe["adc"]["mode"] == smart.adc_10x + smart.adc_scope)
assert(sampled_both_variant_probe["adc"]["sample_ticks"] == 96)
assert(calls == [
    ["smart.start", 8, smart.adc_10x + smart.adc_scope, 96, 0],
    ["smart.akpin", 8],
    ["smart.start", 9, smart.oe + smart.dac_75r_2v, 192, 15],
    ["waitus", 13],
    ["smart.rdpin", 8],
    ["waitus", 4],
    ["smart.rdpin", 8],
    ["waitus", 4],
    ["smart.rdpin", 8],
    ["smart.wypin", 9, 210],
    ["waitus", 13],
    ["smart.rdpin", 8],
    ["waitus", 4],
    ["smart.rdpin", 8],
    ["waitus", 4],
    ["smart.rdpin", 8],
    ["smart.clear", 9],
    ["pin.float", 9],
    ["smart.clear", 8],
    ["pin.float", 8]
])
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, "bad", nil, 256, 256, nil, nil, 0, 1, 1, 0) end)
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, nil, nil, 0, 256, nil, nil, 0, 1, 1, 0) end)
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, nil, nil, 256, 256, "bad", nil, 0, 1, 1, 0) end)
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, nil, nil, 256, 256, nil, nil, 0, 1, 0, 0) end)
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, nil, nil, 256, 256, nil, nil, 0, 1, 33, 0) end)
expect_error(def () p2smart.adc_dac_variants_sampled_probe(0, 1, 0, 255, nil, nil, 256, 256, nil, nil, 0, 1, 1, -1) end)
smart.rdpin = def(pin_no)
    calls.push(["smart.rdpin", pin_no])
    return smart.rd_value
end

expect_error(def () p2smart.counter(-1, nil) end)
expect_error(def () p2smart.quadrature(-1, 0, nil) end)
expect_error(def () p2smart.quadrature(0, 64, nil) end)
expect_error(def () p2smart.quadrature(0, 0, nil) end)
expect_error(def () p2smart.quadrature(0, 2, nil) end)
expect_error(def () p2smart.quadrature(0, 2, -1) end)
expect_error(def () p2smart.quadrature_sample_probe(0, 2, nil, 0) end)
expect_error(def () p2smart.gpio_input(-1) end)
expect_error(def () p2smart.gpio_output(64, nil) end)
expect_error(def () p2smart.gpio_output(0, 2) end)
expect_error(def () p2smart.gpio_output(0, nil).write(2) end)
expect_error(def () p2smart.gpio_loopback_probe(-1, 1, [0], 0) end)
expect_error(def () p2smart.gpio_loopback_probe(0, 64, [0], 0) end)
expect_error(def () p2smart.gpio_loopback_probe(0, 1, nil, -1) end)
expect_error(def () p2smart.gpio_loopback_probe(0, 1, [], 0) end)
expect_error(def () p2smart.gpio_loopback_probe(0, 1, [2], 0) end)
expect_error(def () p2smart.normal_pin(-1, nil, nil) end)
expect_error(def () p2smart.normal_pin(0, -1, nil) end)
expect_error(def () p2smart.normal_pin(0, nil, 2) end)
expect_error(def () p2smart.normal_pin(0, nil, nil).write(2) end)
expect_error(def () p2smart.counter(64, nil) end)
expect_error(def () p2smart.counter(0, -1) end)
expect_error(def () p2smart.counter_mode("bad") end)
expect_error(def () p2smart.counter_variant(0, "bad") end)
expect_error(def () p2smart.repository(-1, 0, nil) end)
expect_error(def () p2smart.repository(0, -1, nil) end)
expect_error(def () p2smart.pwm(0, 0, 0, 1, nil) end)
expect_error(def () p2smart.pwm(0, 40000, 0, 1, nil) end)
expect_error(def () p2smart.pwm(0, 100, 101, 1, nil) end)
expect_error(def () p2smart.pwm(0, 100, 1, 0, nil) end)
expect_error(def () p2smart.pwm(0, 100, 1, 70000, nil) end)
expect_error(def () p2smart.pwm_mode("bad") end)
expect_error(def () p2smart.pwm_variant(0, 100, 1, 1, "bad") end)
expect_error(def () p2smart.nco(0, 0, 1, nil) end)
expect_error(def () p2smart.nco(0, 1, -1, nil) end)
expect_error(def () p2smart.nco_duty(-1, 16000, 1, nil) end)
expect_error(def () p2smart.nco_duty(0, 0, 1, nil) end)
expect_error(def () p2smart.nco_duty(0, 16000, 0, nil) end)
expect_error(def () p2smart.nco_duty(0, 16000, 16001, nil) end)
expect_error(def () p2smart.nco_duty(0, 16000, 1, nil).set_duty(0) end)
expect_error(def () p2smart.nco_duty(0, 16000, 1, nil).set_duty(16001) end)
expect_error(def () p2smart.pulse(0, 0, 1, 1, nil) end)
expect_error(def () p2smart.pulse(0, 40000, 1, 1, nil) end)
expect_error(def () p2smart.pulse(0, 40000, 30000, 1, nil) end)
expect_error(def () p2smart.pulse(0, 1, 1, -1, nil) end)
expect_error(def () p2smart.transition(0, 0, 1, nil) end)
expect_error(def () p2smart.transition(0, 70000, 1, nil) end)
expect_error(def () p2smart.transition(0, 1, -1, nil) end)
expect_error(def () p2smart.async_serial_pair_ticks(0, 0, 200, 8, nil, nil) end)
expect_error(def () p2smart.async_serial_pair_ticks(0, 1, 0, 8, nil, nil) end)
expect_error(def () p2smart.async_serial_pair_ticks(0, 1, 200, 0, nil, nil) end)
expect_error(def () p2smart.async_serial_pair_ticks(0, 1, 200, 33, nil, nil) end)
expect_error(def () p2smart.async_serial_pair_ticks(0, 1, 200, 8, nil, nil).send(256) end)
expect_error(def () p2smart.async_serial_probe(0, 1, [], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_pair_ticks(0, 0, 200, 8, nil, nil) end)
expect_error(def () p2smart.sync_serial_pair_ticks(0, 1, 0, 8, nil, nil) end)
expect_error(def () p2smart.sync_serial_pair_ticks(0, 1, 200, 0, nil, nil) end)
expect_error(def () p2smart.sync_serial_pair_ticks(0, 1, 200, 33, nil, nil) end)
expect_error(def () p2smart.sync_serial_pair_ticks(0, 1, 200, 8, nil, nil).send(-1) end)
expect_error(def () p2smart.sync_serial_probe(0, 1, [], 0, 1000000, 8) end)
expect_error(def () p2smart.sync_serial_clocked_probe(0, 1, 2, 3, [], 0, 1000000, 8) end)
expect_error(def () p2smart.serial_bit_ticks(0) end)
expect_error(def () p2smart.adc(-1, nil, nil) end)
expect_error(def () p2smart.adc(0, -1, nil) end)
expect_error(def () p2smart.adc(0, nil, 0) end)
expect_error(def () p2smart.adc(0, nil, 70000) end)
expect_error(def () p2smart.adc_mode("bad", nil) end)
expect_error(def () p2smart.adc_mode(nil, "bad") end)
expect_error(def () p2smart.adc_variant(0, "bad", nil, 256) end)
expect_error(def () p2smart.dac(-1, 0, 256, nil) end)
expect_error(def () p2smart.dac(0, -1, 256, nil) end)
expect_error(def () p2smart.dac(0, 256, 256, nil) end)
expect_error(def () p2smart.dac(0, 0, 0, nil) end)
expect_error(def () p2smart.dac(0, 0, 256, -1) end)
expect_error(def () p2smart.dac_mode("bad", nil) end)
expect_error(def () p2smart.dac_mode(nil, "bad") end)
expect_error(def () p2smart.dac_variant(0, 0, 256, "bad", nil) end)
