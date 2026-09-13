# Conservative high-level helpers for P2 smart pins.
#
# This module wraps the raw smart-pin register helpers without hiding the fact
# that unsupported modes still need explicit hardware validation.

import p2 as _p2
import introspect

var p2smart = module("p2smart")

if _p2 == nil
    raise "import_error", "native p2 module not available"
end

var _smart = nil
if introspect.contains(_p2, "smart")
    _smart = _p2.smart
end

if _smart == nil
    _smart = module("p2smart.smart")
    _smart.wrpin = _p2.smartpin_write_mode
    _smart.wxpin = _p2.smartpin_write_x
    _smart.wypin = _p2.smartpin_write_y
    _smart.akpin = _p2.smartpin_ack
    _smart.rdpin = _p2.smartpin_read
    _smart.rqpin = _p2.smartpin_query
    _smart.start = _p2.smartpin_start
    _smart.clear = _p2.smartpin_clear
    _smart.plus1_a = 0x10000000
    _smart.plus2_a = 0x20000000
    _smart.plus3_a = 0x30000000
    _smart.outbit_a = 0x40000000
    _smart.minus3_a = 0x50000000
    _smart.minus2_a = 0x60000000
    _smart.minus1_a = 0x70000000
    _smart.invert_a = -2147483648
    _smart.plus1_b = 0x01000000
    _smart.plus2_b = 0x02000000
    _smart.plus3_b = 0x03000000
    _smart.true_b = 0x00000000
    _smart.invert_b = 0x08000000
    _smart.local_b = 0x00000000
    _smart.outbit_b = 0x04000000
    _smart.minus3_b = 0x05000000
    _smart.minus2_b = 0x06000000
    _smart.minus1_b = 0x07000000
    _smart.and_ab = 0x200000
    _smart.or_ab = 0x400000
    _smart.xor_ab = 0x600000
    _smart.filt0_ab = 0x800000
    _smart.filt1_ab = 0xa00000
    _smart.filt2_ab = 0xc00000
    _smart.filt3_ab = 0xe00000
    _smart.logic_a_fb = 0x20000
    _smart.logic_b_fb = 0x40000
    _smart.schmitt_a = 0x60000
    _smart.schmitt_a_fb = 0x80000
    _smart.schmitt_b_fb = 0xa0000
    _smart.compare_ab = 0xc0000
    _smart.compare_ab_fb = 0xe0000
    _smart.oe = 0x40
    _smart.channel = 0x40
    _smart.bitdac = 0x80
    _smart.sync_io = 0x10000
    _smart.invert_in = 0x8000
    _smart.invert_output = 0x4000
    _smart.high_1k5 = 0x800
    _smart.high_15k = 0x1000
    _smart.high_150k = 0x1800
    _smart.high_1ma = 0x2000
    _smart.high_100ua = 0x2800
    _smart.high_10ua = 0x3000
    _smart.high_float = 0x3800
    _smart.low_1k5 = 0x100
    _smart.low_15k = 0x200
    _smart.low_150k = 0x300
    _smart.low_1ma = 0x400
    _smart.low_100ua = 0x500
    _smart.low_10ua = 0x600
    _smart.low_float = 0x700
    _smart.tt_01 = 0x40
    _smart.tt_10 = 0x80
    _smart.tt_11 = 0xc0
    _smart.normal = 0x00
    _smart.repository = 0x02
    _smart.dac_noise = 0x02
    _smart.dac_dither_rnd = 0x04
    _smart.pulse = 0x08
    _smart.transition = 0x0a
    _smart.nco_freq = 0x0c
    _smart.nco_duty = 0x0e
    _smart.pwm_triangle = 0x10
    _smart.pwm_sawtooth = 0x12
    _smart.pwm_smps = 0x14
    _smart.quadrature = 0x16
    _smart.reg_up = 0x18
    _smart.reg_up_down = 0x1a
    _smart.count_rises = 0x1c
    _smart.count_highs = 0x1e
    _smart.state_ticks = 0x20
    _smart.high_ticks = 0x22
    _smart.events_ticks = 0x24
    _smart.periods_ticks = 0x26
    _smart.periods_highs = 0x28
    _smart.counter_ticks = 0x2a
    _smart.counter_highs = 0x2c
    _smart.counter_periods = 0x2e
    _smart.adc_gio = 0x100000
    _smart.adc_vio = 0x108000
    _smart.adc_float = 0x110000
    _smart.adc_1x = 0x118000
    _smart.adc_3x = 0x120000
    _smart.adc_10x = 0x128000
    _smart.adc_30x = 0x130000
    _smart.adc_100x = 0x138000
    _smart.adc = 0x30
    _smart.adc_ext = 0x32
    _smart.adc_scope = 0x34
    _smart.usb_pair = 0x36
    _smart.dac_dither_pwm = 0x06
    _smart.sync_tx = 0x38
    _smart.sync_rx = 0x3a
    _smart.async_tx = 0x3c
    _smart.async_rx = 0x3e
    _smart.dac_990r_3v = 0x140000
    _smart.dac_600r_2v = 0x150000
    _smart.dac_124r_3v = 0x160000
    _smart.dac_75r_2v = 0x170000
    _smart.level_a = 0x180000
    _smart.level_a_fbn = 0x1a0000
    _smart.level_b_fbp = 0x1c0000
    _smart.level_b_fbn = 0x1e0000
end
p2smart.smart = _smart

var _pin = nil
if introspect.contains(_p2, "pin")
    _pin = _p2.pin
end

if _pin == nil
    _pin = module("p2smart.pin")
    _pin.dir_low = _p2.pin_input
    _pin.dir_high = _p2.pin_output
    _pin.write = _p2.pin_write
    _pin.low = _p2.pin_low
    _pin.high = _p2.pin_high
    _pin.toggle = _p2.pin_toggle
    _pin.float = _p2.pin_float
    _pin.read = _p2.pin_read
end
p2smart.pin = _pin

var _clock = nil
if introspect.contains(_p2, "clock")
    _clock = _p2.clock
end

if _clock == nil
    _clock = module("p2smart.clock")
    _clock.freq = _p2.clock_freq
end
p2smart.clock = _clock

p2smart.waitus = def(us)
    return _p2.waitus(us)
end

p2smart.status_info = def()
    return _p2.status_info()
end

p2smart.DEFAULT_PWM_FRAME = 200
p2smart.DEFAULT_PWM_DUTY = 100
p2smart.DEFAULT_PWM_DIVISOR = 1
p2smart.DEFAULT_NCO_BIT_PERIOD = 16000
p2smart.DEFAULT_NCO_INCREMENT = 0x20000000
p2smart.DEFAULT_NCO_DUTY_PRESCALER = 1
p2smart.DEFAULT_NCO_DUTY_VALUE = 0x40000000
p2smart.DEFAULT_NCO_DUTY = p2smart.DEFAULT_NCO_DUTY_VALUE
p2smart.DEFAULT_PULSE_HIGH = 100
p2smart.DEFAULT_PULSE_LOW = 100
p2smart.DEFAULT_PULSE_COUNT = 8
p2smart.DEFAULT_TRANSITION_WIDTH = 100
p2smart.DEFAULT_TRANSITION_COUNT = 8
p2smart.DEFAULT_SERIAL_BAUD = 115200
p2smart.DEFAULT_SERIAL_BITS = 8
p2smart.DEFAULT_REPOSITORY_VALUE = 0x00c0ffee
p2smart.DEFAULT_ADC_SAMPLE_TICKS = 32
p2smart.DEFAULT_DAC_FRAME = 256
p2smart.DEFAULT_DAC_VALUE = 128
p2smart.DEFAULT_JUMPER_PAIRS = [[0, 1], [2, 3], [4, 5], [6, 7]]
p2smart._statuses = [
    "verified",
    "setup_readback",
    "setup_output",
    "diagnostic",
    "setup_only",
    "staged",
    "unverified",
    "unsupported"
]

p2smart._require_pin = def(pin)
    if type(pin) != "int" || pin < 0 || pin > 63
        raise "value_error", "pin must be an int in range 0..63"
    end
    return pin
end

p2smart._require_non_negative_int = def(value, name)
    if type(value) != "int" || value < 0
        raise "value_error", name + " must be a non-negative int"
    end
    return value
end

p2smart._require_positive_int = def(value, name)
    if type(value) != "int" || value <= 0
        raise "value_error", name + " must be a positive int"
    end
    return value
end

p2smart._require_pwm_frame = def(frame)
    p2smart._require_positive_int(frame, "frame")
    if frame > 32767
        raise "value_error", "frame is too large for signed Berry integer PWM X value"
    end
    return frame
end

p2smart._require_pwm_divisor = def(divisor)
    p2smart._require_positive_int(divisor, "divisor")
    if divisor > 65535
        raise "value_error", "divisor must fit in 16 bits"
    end
    return divisor
end

p2smart._require_pwm_duty = def(duty, frame)
    p2smart._require_non_negative_int(duty, "duty")
    if duty > frame
        raise "value_error", "duty must be between 0 and frame"
    end
    return duty
end

p2smart._pwm_mode = def(name)
    if name == nil || name == "triangle"
        return p2smart.smart.pwm_triangle
    end
    if name == "sawtooth"
        return p2smart.smart.pwm_sawtooth
    end
    if name == "smps"
        return p2smart.smart.pwm_smps
    end
    raise "value_error", "unknown PWM mode"
end

p2smart._counter_mode = def(name)
    if name == nil || name == "count_rises"
        return p2smart.smart.count_rises
    end
    if name == "count_highs"
        return p2smart.smart.count_highs
    end
    if name == "state_ticks"
        return p2smart.smart.state_ticks
    end
    if name == "high_ticks"
        return p2smart.smart.high_ticks
    end
    if name == "events_ticks"
        return p2smart.smart.events_ticks
    end
    if name == "periods_ticks"
        return p2smart.smart.periods_ticks
    end
    if name == "periods_highs"
        return p2smart.smart.periods_highs
    end
    if name == "counter_ticks"
        return p2smart.smart.counter_ticks
    end
    if name == "counter_highs"
        return p2smart.smart.counter_highs
    end
    if name == "counter_periods"
        return p2smart.smart.counter_periods
    end
    if name == "reg_up"
        return p2smart.smart.reg_up
    end
    if name == "reg_up_down"
        return p2smart.smart.reg_up_down
    end
    raise "value_error", "unknown counter mode"
end

p2smart._require_16_bit = def(value, name)
    p2smart._require_positive_int(value, name)
    if value > 65535
        raise "value_error", name + " must fit in 16 bits"
    end
    return value
end

p2smart._require_byte = def(value, name)
    p2smart._require_non_negative_int(value, name)
    if value > 255
        raise "value_error", name + " must fit in 8 bits"
    end
    return value
end

p2smart._dac_resistor_mode = def(name)
    if name == nil || name == "990r_3v"
        return p2smart.smart.dac_990r_3v
    end
    if name == "600r_2v"
        return p2smart.smart.dac_600r_2v
    end
    if name == "124r_3v"
        return p2smart.smart.dac_124r_3v
    end
    if name == "75r_2v"
        return p2smart.smart.dac_75r_2v
    end
    raise "value_error", "unknown DAC resistor mode"
end

p2smart._dac_dither_mode = def(name)
    if name == nil || name == "dither_pwm"
        return p2smart.smart.dac_dither_pwm
    end
    if name == "dither_rnd"
        return p2smart.smart.dac_dither_rnd
    end
    if name == "noise"
        return p2smart.smart.dac_noise
    end
    if name == "plain"
        return 0
    end
    raise "value_error", "unknown DAC dither mode"
end

p2smart._adc_source_mode = def(name)
    if name == nil || name == "1x"
        return p2smart.smart.adc_1x
    end
    if name == "gio"
        return p2smart.smart.adc_gio
    end
    if name == "vio"
        return p2smart.smart.adc_vio
    end
    if name == "float"
        return p2smart.smart.adc_float
    end
    if name == "3x"
        return p2smart.smart.adc_3x
    end
    if name == "10x"
        return p2smart.smart.adc_10x
    end
    if name == "30x"
        return p2smart.smart.adc_30x
    end
    if name == "100x"
        return p2smart.smart.adc_100x
    end
    raise "value_error", "unknown ADC source/gain mode"
end

p2smart._adc_family_mode = def(name)
    if name == nil || name == "adc"
        return p2smart.smart.adc
    end
    if name == "adc_ext"
        return p2smart.smart.adc_ext
    end
    if name == "adc_scope"
        return p2smart.smart.adc_scope
    end
    raise "value_error", "unknown ADC family mode"
end

p2smart.default_jumper_pairs = def()
    var out = []
    for pair : p2smart.DEFAULT_JUMPER_PAIRS
        out.push([pair[0], pair[1]])
    end
    return out
end

p2smart.default_jumper_directions = def()
    var out = []
    for pair : p2smart.DEFAULT_JUMPER_PAIRS
        out.push([pair[0], pair[1]])
        out.push([pair[1], pair[0]])
    end
    return out
end

p2smart.default_clocked_jumper_groups = def()
    return [
        [0, 1, 2, 3],
        [4, 5, 6, 7]
    ]
end

p2smart._require_bit = def(value, name)
    if value == true
        return 1
    end
    if value == false
        return 0
    end
    p2smart._require_non_negative_int(value, name)
    if value > 1
        raise "value_error", name + " must be 0, 1, true, or false"
    end
    return value
end

p2smart._require_serial_bits = def(bits)
    p2smart._require_positive_int(bits, "bits")
    if bits < 1 || bits > 32
        raise "value_error", "bits must be in range 1..32"
    end
    return bits
end

p2smart._serial_x = def(bit_ticks, bits)
    return p2smart._require_16_bit(bit_ticks, "bit_ticks") * 65536 + p2smart._require_serial_bits(bits) - 1
end

p2smart._sync_serial_x = def(bits)
    return (p2smart._require_serial_bits(bits) - 1) | 0x20
end

p2smart._serial_mask = def(bits)
    return (1 << p2smart._require_serial_bits(bits)) - 1
end

p2smart._sync_serial_value = def(raw, bits)
    var width = p2smart._require_serial_bits(bits)
    return (raw >> (32 - width)) & p2smart._serial_mask(width)
end

p2smart.serial_bit_ticks = def(baud)
    p2smart._require_positive_int(baud, "baud")
    var ticks = p2smart.clock.freq() / baud
    if ticks < 3
        raise "value_error", "baud is too high for the current clock"
    end
    return ticks
end

p2smart._neighbor_input_mode = def(tx_pin, rx_pin)
    if tx_pin == rx_pin - 1
        return p2smart.smart.minus1_a
    end
    if tx_pin == rx_pin + 1
        return p2smart.smart.plus1_a
    end
    raise "value_error", "default async RX mode requires adjacent tx/rx pins"
end

p2smart._neighbor_b_mode = def(pin_a, pin_b)
    if pin_b == pin_a + 1
        return p2smart.smart.plus1_b
    end
    if pin_b == pin_a - 1
        return p2smart.smart.minus1_b
    end
    raise "value_error", "default quadrature mode requires adjacent pins"
end

p2smart._relative_b_mode = def(pin_a, pin_b)
    if pin_b == pin_a + 1
        return p2smart.smart.plus1_b
    end
    if pin_b == pin_a + 2
        return p2smart.smart.plus2_b
    end
    if pin_b == pin_a + 3
        return p2smart.smart.plus3_b
    end
    if pin_b == pin_a - 1
        return p2smart.smart.minus1_b
    end
    if pin_b == pin_a - 2
        return p2smart.smart.minus2_b
    end
    if pin_b == pin_a - 3
        return p2smart.smart.minus3_b
    end
    raise "value_error", "clock pin must be within +/-3 pins for B-input selection"
end

p2smart._require_pulse_high = def(value)
    p2smart._require_positive_int(value, "high_ticks")
    if value > 32767
        raise "value_error", "high_ticks is too large for signed Berry integer pulse X value"
    end
    return value
end

p2smart._require_pulse_low = def(value, high)
    p2smart._require_positive_int(value, "low_ticks")
    if high + value > 65535
        raise "value_error", "high_ticks + low_ticks must fit in 16 bits"
    end
    return value
end

class GPIOInput
    var pin
    var started

    def init(pin)
        self.pin = p2smart._require_pin(pin)
        self.started = false
    end

    def start()
        p2smart.pin.float(self.pin)
        self.started = true
        return self
    end

    def dir_low()
        p2smart.pin.dir_low(self.pin)
        self.started = true
        return self
    end

    def read()
        return p2smart.pin.read(self.pin)
    end

    def read_result()
        var current = self.read()
        return {
            "ok": true,
            "pin": self.pin,
            "value": current,
            "high": current != 0,
            "low": current == 0
        }
    end

    def high()
        return self.read() != 0
    end

    def low()
        return self.read() == 0
    end

    def clear()
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "GPIOInput",
            "pin": self.pin,
            "started": self.started
        }
    end
end

class GPIOOutput
    var pin
    var value
    var started

    def init(pin, value)
        self.pin = p2smart._require_pin(pin)
        self.value = value == nil ? nil : p2smart._require_bit(value, "value")
        self.started = false
    end

    def start()
        p2smart.pin.dir_high(self.pin)
        if self.value != nil
            p2smart.pin.write(self.pin, self.value)
        end
        self.started = true
        return self
    end

    def write(value)
        self.value = p2smart._require_bit(value, "value")
        p2smart.pin.write(self.pin, self.value)
        return self
    end

    def write_result(value)
        var next_value = p2smart._require_bit(value, "value")
        self.write(next_value)
        return {
            "ok": true,
            "pin": self.pin,
            "value": self.value
        }
    end

    def high()
        self.value = 1
        p2smart.pin.high(self.pin)
        return self
    end

    def low()
        self.value = 0
        p2smart.pin.low(self.pin)
        return self
    end

    def toggle()
        p2smart.pin.toggle(self.pin)
        self.value = p2smart.pin.read(self.pin)
        return self
    end

    def toggle_result()
        self.toggle()
        return {
            "ok": true,
            "pin": self.pin,
            "value": self.value
        }
    end

    def read()
        return p2smart.pin.read(self.pin)
    end

    def clear()
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "GPIOOutput",
            "pin": self.pin,
            "value": self.value,
            "started": self.started
        }
    end
end

class NormalPin
    var pin
    var mode
    var value
    var started

    def init(pin, mode, value)
        self.pin = p2smart._require_pin(pin)
        self.mode = mode == nil ? p2smart.smart.normal : p2smart._require_non_negative_int(mode, "mode")
        self.value = value == nil ? nil : p2smart._require_bit(value, "value")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, 0, 0)
        if self.value == nil
            p2smart.pin.float(self.pin)
        else
            p2smart.pin.dir_high(self.pin)
            p2smart.pin.write(self.pin, self.value)
        end
        self.started = true
        return self
    end

    def write(value)
        self.value = p2smart._require_bit(value, "value")
        p2smart.pin.write(self.pin, self.value)
        return self
    end

    def write_result(value)
        var next_value = p2smart._require_bit(value, "value")
        self.write(next_value)
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "value": self.value
        }
    end

    def high()
        self.value = 1
        p2smart.pin.high(self.pin)
        return self
    end

    def low()
        self.value = 0
        p2smart.pin.low(self.pin)
        return self
    end

    def toggle()
        p2smart.pin.toggle(self.pin)
        self.value = p2smart.pin.read(self.pin)
        return self
    end

    def read()
        return p2smart.pin.read(self.pin)
    end

    def read_result()
        var current = self.read()
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "value": current
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "NormalPin",
            "pin": self.pin,
            "mode": self.mode,
            "value": self.value,
            "started": self.started
        }
    end
end

class Counter
    var pin
    var mode
    var started

    def init(pin, mode)
        self.pin = p2smart._require_pin(pin)
        self.mode = mode == nil ? p2smart.smart.count_rises : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, 0, 0)
        p2smart.smart.akpin(self.pin)
        self.started = true
        return self
    end

    def read()
        return p2smart.smart.rdpin(self.pin)
    end

    def query()
        return p2smart.smart.rqpin(self.pin)
    end

    def ack()
        p2smart.smart.akpin(self.pin)
        return self
    end

    def sample_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        var before = self.read()
        if delay > 0
            p2smart.waitus(delay)
        end
        var after = self.read()
        var delta = after - before
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "advanced": delta > 0,
            "wait_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "Counter",
            "pin": self.pin,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class Quadrature
    var pin_a
    var pin_b
    var mode
    var started

    def init(pin_a, pin_b, mode)
        self.pin_a = p2smart._require_pin(pin_a)
        self.pin_b = p2smart._require_pin(pin_b)
        if self.pin_a == self.pin_b
            raise "value_error", "pin_a and pin_b must differ"
        end
        self.mode = p2smart.smart.quadrature + (mode == nil ? p2smart._neighbor_b_mode(self.pin_a, self.pin_b) : p2smart._require_non_negative_int(mode, "mode"))
        self.started = false
    end

    def start()
        p2smart.pin.float(self.pin_a)
        p2smart.pin.float(self.pin_b)
        p2smart.smart.start(self.pin_a, self.mode, 0, 0)
        p2smart.smart.akpin(self.pin_a)
        self.started = true
        return self
    end

    def read()
        return p2smart.smart.rdpin(self.pin_a)
    end

    def position()
        return self.read()
    end

    def query()
        return p2smart.smart.rqpin(self.pin_a)
    end

    def ack()
        p2smart.smart.akpin(self.pin_a)
        return self
    end

    def sample_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        var before = self.position()
        if delay > 0
            p2smart.waitus(delay)
        end
        var after = self.position()
        var delta = after - before
        return {
            "ok": true,
            "pin_a": self.pin_a,
            "pin_b": self.pin_b,
            "mode": self.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "moved": delta != 0,
            "direction": delta > 0 ? 1 : (delta < 0 ? -1 : 0),
            "wait_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin_a)
        p2smart.pin.float(self.pin_a)
        p2smart.pin.float(self.pin_b)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "Quadrature",
            "pin_a": self.pin_a,
            "pin_b": self.pin_b,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class Repository
    var pin
    var mode
    var value
    var started

    def init(pin, value, mode)
        self.pin = p2smart._require_pin(pin)
        self.value = p2smart._require_non_negative_int(value == nil ? p2smart.DEFAULT_REPOSITORY_VALUE : value, "value")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.repository : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.value, 0)
        self.started = true
        return self
    end

    def write(value)
        self.value = p2smart._require_non_negative_int(value, "value")
        p2smart.smart.wxpin(self.pin, self.value)
        return self
    end

    def write_result(value, settle_us)
        var next_value = p2smart._require_non_negative_int(value, "value")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.write(next_value)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "value": self.value,
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def read()
        return p2smart.smart.rdpin(self.pin)
    end

    def read_result()
        var current = self.read()
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "value": self.value,
            "raw": current
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "Repository",
            "pin": self.pin,
            "value": self.value,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class PWM
    var pin
    var frame
    var duty
    var divisor
    var mode
    var started

    def init(pin, frame, duty, divisor, mode)
        self.pin = p2smart._require_pin(pin)
        self.frame = p2smart._require_pwm_frame(frame == nil ? p2smart.DEFAULT_PWM_FRAME : frame)
        self.duty = p2smart._require_pwm_duty(duty == nil ? p2smart.DEFAULT_PWM_DUTY : duty, self.frame)
        self.divisor = p2smart._require_pwm_divisor(divisor == nil ? p2smart.DEFAULT_PWM_DIVISOR : divisor)
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.pwm_triangle : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def x()
        return self.frame * 65536 + self.divisor
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.x(), self.duty)
        self.started = true
        return self
    end

    def set_duty(duty)
        self.duty = p2smart._require_pwm_duty(duty, self.frame)
        p2smart.smart.wypin(self.pin, self.duty)
        return self
    end

    def set_duty_result(duty, settle_us)
        var next_duty = p2smart._require_pwm_duty(duty, self.frame)
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.set_duty(next_duty)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "frame": self.frame,
            "duty": self.duty,
            "divisor": self.divisor,
            "mode": self.mode,
            "x": self.x(),
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "PWM",
            "pin": self.pin,
            "frame": self.frame,
            "duty": self.duty,
            "divisor": self.divisor,
            "mode": self.mode,
            "x": self.x(),
            "started": self.started
        }
    end
end

class NCO
    var pin
    var bit_period
    var increment
    var mode
    var started

    def init(pin, bit_period, increment, mode)
        self.pin = p2smart._require_pin(pin)
        self.bit_period = p2smart._require_positive_int(bit_period == nil ? p2smart.DEFAULT_NCO_BIT_PERIOD : bit_period, "bit_period")
        self.increment = p2smart._require_non_negative_int(increment == nil ? p2smart.DEFAULT_NCO_INCREMENT : increment, "increment")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.nco_freq : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.bit_period, self.increment)
        self.started = true
        return self
    end

    def set_increment(increment)
        self.increment = p2smart._require_non_negative_int(increment, "increment")
        p2smart.smart.wypin(self.pin, self.increment)
        return self
    end

    def set_increment_result(increment, settle_us)
        var next_increment = p2smart._require_non_negative_int(increment, "increment")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.set_increment(next_increment)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "bit_period": self.bit_period,
            "increment": self.increment,
            "mode": self.mode,
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "NCO",
            "pin": self.pin,
            "bit_period": self.bit_period,
            "increment": self.increment,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class NCODuty
    var pin
    var prescaler
    var duty
    var mode
    var started

    def init(pin, prescaler, duty, mode)
        self.pin = p2smart._require_pin(pin)
        self.prescaler = p2smart._require_positive_int(prescaler == nil ? p2smart.DEFAULT_NCO_DUTY_PRESCALER : prescaler, "prescaler")
        self.duty = p2smart._require_non_negative_int(duty == nil ? p2smart.DEFAULT_NCO_DUTY_VALUE : duty, "duty")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.nco_duty : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.prescaler, self.duty)
        self.started = true
        return self
    end

    def set_duty(duty)
        self.duty = p2smart._require_non_negative_int(duty, "duty")
        p2smart.smart.wypin(self.pin, self.duty)
        return self
    end

    def set_duty_result(duty, settle_us)
        var next_duty = p2smart._require_non_negative_int(duty, "duty")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.set_duty(next_duty)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "prescaler": self.prescaler,
            "bit_period": self.prescaler,
            "duty": self.duty,
            "value": self.duty,
            "mode": self.mode,
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "NCODuty",
            "pin": self.pin,
            "prescaler": self.prescaler,
            "bit_period": self.prescaler,
            "duty": self.duty,
            "value": self.duty,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class Pulse
    var pin
    var high_ticks
    var low_ticks
    var count
    var mode
    var started

    def init(pin, high_ticks, low_ticks, count, mode)
        self.pin = p2smart._require_pin(pin)
        self.high_ticks = p2smart._require_pulse_high(high_ticks == nil ? p2smart.DEFAULT_PULSE_HIGH : high_ticks)
        self.low_ticks = p2smart._require_pulse_low(low_ticks == nil ? p2smart.DEFAULT_PULSE_LOW : low_ticks, self.high_ticks)
        self.count = p2smart._require_non_negative_int(count == nil ? p2smart.DEFAULT_PULSE_COUNT : count, "count")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.pulse : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def x()
        return self.high_ticks * 65536 + self.high_ticks + self.low_ticks
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.x(), self.count)
        p2smart.smart.wypin(self.pin, self.count)
        self.started = true
        return self
    end

    def trigger(count)
        self.count = p2smart._require_non_negative_int(count, "count")
        p2smart.smart.wypin(self.pin, self.count)
        return self
    end

    def trigger_result(count, settle_us)
        var next_count = p2smart._require_non_negative_int(count, "count")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.trigger(next_count)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "high_ticks": self.high_ticks,
            "low_ticks": self.low_ticks,
            "count": self.count,
            "mode": self.mode,
            "x": self.x(),
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "Pulse",
            "pin": self.pin,
            "high_ticks": self.high_ticks,
            "low_ticks": self.low_ticks,
            "count": self.count,
            "mode": self.mode,
            "x": self.x(),
            "started": self.started
        }
    end
end

class Transition
    var pin
    var width
    var count
    var mode
    var started

    def init(pin, width, count, mode)
        self.pin = p2smart._require_pin(pin)
        self.width = p2smart._require_16_bit(width == nil ? p2smart.DEFAULT_TRANSITION_WIDTH : width, "width")
        self.count = p2smart._require_non_negative_int(count == nil ? p2smart.DEFAULT_TRANSITION_COUNT : count, "count")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.transition : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.width, self.count)
        p2smart.smart.wypin(self.pin, self.count)
        self.started = true
        return self
    end

    def trigger(count)
        self.count = p2smart._require_non_negative_int(count, "count")
        p2smart.smart.wypin(self.pin, self.count)
        return self
    end

    def trigger_result(count, settle_us)
        var next_count = p2smart._require_non_negative_int(count, "count")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.trigger(next_count)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "width": self.width,
            "count": self.count,
            "mode": self.mode,
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "Transition",
            "pin": self.pin,
            "width": self.width,
            "count": self.count,
            "mode": self.mode,
            "started": self.started
        }
    end
end

class AsyncSerialPair
    var tx_pin
    var rx_pin
    var bit_ticks
    var bits
    var tx_mode
    var rx_mode
    var started

    def init(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
        self.tx_pin = p2smart._require_pin(tx_pin)
        self.rx_pin = p2smart._require_pin(rx_pin)
        if self.tx_pin == self.rx_pin
            raise "value_error", "tx_pin and rx_pin must differ"
        end
        self.bit_ticks = p2smart._require_16_bit(bit_ticks == nil ? p2smart.serial_bit_ticks(p2smart.DEFAULT_SERIAL_BAUD) : bit_ticks, "bit_ticks")
        self.bits = p2smart._require_serial_bits(bits == nil ? p2smart.DEFAULT_SERIAL_BITS : bits)
        self.tx_mode = tx_mode == nil ? p2smart.smart.oe + p2smart.smart.async_tx : p2smart._require_non_negative_int(tx_mode, "tx_mode")
        self.rx_mode = rx_mode == nil ? p2smart.smart.async_rx : p2smart._require_non_negative_int(rx_mode, "rx_mode")
        self.started = false
    end

    def x()
        return p2smart._serial_x(self.bit_ticks, self.bits)
    end

    def start()
        var x = self.x()
        p2smart.smart.start(self.tx_pin, self.tx_mode, x, 0)
        p2smart.smart.start(self.rx_pin, self.rx_mode, x, 0)
        self.started = true
        return self
    end

    def send(byte)
        p2smart.smart.wypin(self.tx_pin, p2smart._require_byte(byte, "byte"))
        return self
    end

    def send_bytes(values, inter_byte_us)
        if values == nil
            raise "value_error", "values must be a list of bytes"
        end
        var delay = inter_byte_us == nil ? 0 : p2smart._require_non_negative_int(inter_byte_us, "inter_byte_us")
        var sent = 0
        for value : values
            self.send(value)
            sent += 1
            if delay > 0
                p2smart.waitus(delay)
            end
        end
        return sent
    end

    def available()
        return p2smart.smart.rqpin(self.rx_pin)
    end

    def read_raw()
        return p2smart.smart.rdpin(self.rx_pin)
    end

    def read_byte()
        return (self.read_raw() >> 24) & 255
    end

    def read_result()
        var event = self.available()
        var raw = event != 0 ? self.read_raw() : 0
        return {
            "ready": event != 0,
            "event": event,
            "raw": raw,
            "value": event != 0 ? ((raw >> 24) & 255) : nil
        }
    end

    def read_byte_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        if delay > 0
            p2smart.waitus(delay)
        end
        return self.read_byte()
    end

    def read_result_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        if delay > 0
            p2smart.waitus(delay)
        end
        var raw = self.read_raw()
        return {
            "ready": true,
            "event": nil,
            "raw": raw,
            "value": (raw >> 24) & 255,
            "delayed": delay > 0
        }
    end

    def exchange_bytes_after(values, wait_us)
        if values == nil
            raise "value_error", "values must be a list of bytes"
        end
        var out = []
        for value : values
            self.send(value)
            var result = self.read_result_after(wait_us)
            out.push(result["value"])
        end
        return out
    end

    def exchange_results_after(values, wait_us)
        if values == nil
            raise "value_error", "values must be a list of bytes"
        end
        var out = []
        for value : values
            self.send(value)
            out.push(self.read_result_after(wait_us))
        end
        return out
    end

    def read_available_results(max_count)
        var limit = max_count == nil ? 16 : p2smart._require_non_negative_int(max_count, "max_count")
        var values = []
        var results = []
        var acked = 0
        var stopped = "limit"
        while results.size() < limit
            var event = self.available()
            if event == 0
                stopped = "not_ready"
                break
            end
            var raw = self.read_raw()
            var value = (raw >> 24) & 255
            var result = {
                "ready": true,
                "event": event,
                "raw": raw,
                "value": value
            }
            results.push(result)
            values.push(value)
            self.ack()
            acked += 1
        end
        return {
            "ok": true,
            "values": values,
            "results": results,
            "count": results.size(),
            "limit": limit,
            "acked": acked,
            "stopped_reason": stopped
        }
    end

    def read_available(max_count)
        return self.read_available_results(max_count)["values"]
    end

    def ack()
        p2smart.smart.akpin(self.rx_pin)
        return self
    end

    def clear()
        p2smart.smart.clear(self.tx_pin)
        p2smart.smart.clear(self.rx_pin)
        p2smart.pin.float(self.tx_pin)
        p2smart.pin.float(self.rx_pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "AsyncSerialPair",
            "tx_pin": self.tx_pin,
            "rx_pin": self.rx_pin,
            "bit_ticks": self.bit_ticks,
            "bits": self.bits,
            "tx_mode": self.tx_mode,
            "rx_mode": self.rx_mode,
            "x": self.x(),
            "started": self.started
        }
    end
end

class SyncSerialPair
    var tx_pin
    var rx_pin
    var bit_ticks
    var bits
    var tx_mode
    var rx_mode
    var started

    def init(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
        self.tx_pin = p2smart._require_pin(tx_pin)
        self.rx_pin = p2smart._require_pin(rx_pin)
        if self.tx_pin == self.rx_pin
            raise "value_error", "tx_pin and rx_pin must differ"
        end
        self.bit_ticks = p2smart._require_16_bit(bit_ticks == nil ? p2smart.serial_bit_ticks(p2smart.DEFAULT_SERIAL_BAUD) : bit_ticks, "bit_ticks")
        self.bits = p2smart._require_serial_bits(bits == nil ? p2smart.DEFAULT_SERIAL_BITS : bits)
        self.tx_mode = tx_mode == nil ? p2smart.smart.oe + p2smart.smart.sync_io + p2smart.smart.sync_tx : p2smart._require_non_negative_int(tx_mode, "tx_mode")
        self.rx_mode = rx_mode == nil ? p2smart.smart.sync_io + p2smart.smart.sync_rx : p2smart._require_non_negative_int(rx_mode, "rx_mode")
        self.started = false
    end

    def x()
        return p2smart._sync_serial_x(self.bits)
    end

    def start()
        var x = self.x()
        p2smart.smart.start(self.tx_pin, self.tx_mode, x, 0)
        p2smart.smart.start(self.rx_pin, self.rx_mode, x, 0)
        self.started = true
        return self
    end

    def send(value)
        p2smart.smart.wypin(self.tx_pin, p2smart._require_non_negative_int(value, "value"))
        return self
    end

    def available()
        return p2smart.smart.rqpin(self.rx_pin)
    end

    def read_raw()
        return p2smart.smart.rdpin(self.rx_pin)
    end

    def read_result()
        var event = self.available()
        if event == 0
            return {
                "ok": false,
                "ready": false,
                "event": event,
                "raw": nil,
                "value": nil,
                "error": "not_ready",
                "message": "sync serial receive data is not ready"
            }
        end
        var raw = self.read_raw()
        return {
            "ok": true,
            "ready": true,
            "event": event,
            "raw": raw,
            "value": p2smart._sync_serial_value(raw, self.bits),
            "error": nil,
            "message": nil
        }
    end

    def read_result_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        if delay > 0
            p2smart.waitus(delay)
        end
        var result = self.read_result()
        result["delayed"] = delay > 0
        return result
    end

    def transfer_result(value, wait_us, clock)
        var sent = p2smart._require_non_negative_int(value, "value")
        if sent > p2smart._serial_mask(self.bits)
            raise "value_error", "value must fit in configured sync serial bits"
        end
        self.ack()
        self.send(sent)
        if clock != nil
            clock.trigger(self.bits)
        end
        var result = self.read_result_after(wait_us)
        result["sent"] = sent
        result["matched"] = result["ok"] && result["value"] == sent
        result["clocked"] = clock != nil
        return result
    end

    def transfer_results(values, wait_us, clock)
        if values == nil
            raise "value_error", "values must be a list of sync serial words"
        end
        var out = []
        for value : values
            out.push(self.transfer_result(value, wait_us, clock))
        end
        return out
    end

    def ack()
        p2smart.smart.akpin(self.rx_pin)
        return self
    end

    def clear()
        p2smart.smart.clear(self.tx_pin)
        p2smart.smart.clear(self.rx_pin)
        p2smart.pin.float(self.tx_pin)
        p2smart.pin.float(self.rx_pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "SyncSerialPair",
            "tx_pin": self.tx_pin,
            "rx_pin": self.rx_pin,
            "bit_ticks": self.bit_ticks,
            "bits": self.bits,
            "tx_mode": self.tx_mode,
            "rx_mode": self.rx_mode,
            "x": self.x(),
            "started": self.started
        }
    end
end

p2smart._require_adc_sample_ticks = def(value)
    p2smart._require_positive_int(value, "sample_ticks")
    if value > 65535
        raise "value_error", "sample_ticks must fit in 16 bits"
    end
    return value
end

class ADC
    var pin
    var mode
    var sample_ticks
    var started

    def init(pin, mode, sample_ticks)
        self.pin = p2smart._require_pin(pin)
        self.mode = mode == nil ? p2smart.smart.adc_1x + p2smart.smart.adc : p2smart._require_non_negative_int(mode, "mode")
        self.sample_ticks = p2smart._require_adc_sample_ticks(sample_ticks == nil ? p2smart.DEFAULT_ADC_SAMPLE_TICKS : sample_ticks)
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.sample_ticks, 0)
        p2smart.smart.akpin(self.pin)
        self.started = true
        return self
    end

    def read()
        return p2smart.smart.rdpin(self.pin)
    end

    def query()
        return p2smart.smart.rqpin(self.pin)
    end

    def ack()
        p2smart.smart.akpin(self.pin)
        return self
    end

    def read_result()
        var event = self.query()
        var raw = self.read()
        return {
            "ok": true,
            "ready": event != 0,
            "event": event,
            "raw": raw,
            "value": raw,
            "pin": self.pin,
            "mode": self.mode,
            "sample_ticks": self.sample_ticks
        }
    end

    def sample_after(wait_us)
        var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
        if delay > 0
            p2smart.waitus(delay)
        end
        var result = self.read_result()
        result["delayed"] = delay > 0
        result["wait_us"] = delay
        return result
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "ADC",
            "pin": self.pin,
            "mode": self.mode,
            "sample_ticks": self.sample_ticks,
            "started": self.started
        }
    end
end

class DAC
    var pin
    var mode
    var frame
    var value
    var started

    def init(pin, value, frame, mode)
        self.pin = p2smart._require_pin(pin)
        self.value = p2smart._require_byte(value == nil ? p2smart.DEFAULT_DAC_VALUE : value, "value")
        self.frame = p2smart._require_16_bit(frame == nil ? p2smart.DEFAULT_DAC_FRAME : frame, "frame")
        self.mode = mode == nil ? p2smart.smart.oe + p2smart.smart.dac_990r_3v + p2smart.smart.dac_dither_pwm : p2smart._require_non_negative_int(mode, "mode")
        self.started = false
    end

    def start()
        p2smart.smart.start(self.pin, self.mode, self.frame, self.value)
        self.started = true
        return self
    end

    def set(value)
        self.value = p2smart._require_byte(value, "value")
        p2smart.smart.wypin(self.pin, self.value)
        return self
    end

    def set_result(value, settle_us)
        var written = p2smart._require_byte(value, "value")
        var delay = settle_us == nil ? 0 : p2smart._require_non_negative_int(settle_us, "settle_us")
        self.set(written)
        if delay > 0
            p2smart.waitus(delay)
        end
        return {
            "ok": true,
            "pin": self.pin,
            "mode": self.mode,
            "frame": self.frame,
            "value": self.value,
            "settled": delay > 0,
            "settle_us": delay
        }
    end

    def clear()
        p2smart.smart.clear(self.pin)
        p2smart.pin.float(self.pin)
        self.started = false
        return self
    end

    def info()
        return {
            "kind": "DAC",
            "pin": self.pin,
            "mode": self.mode,
            "frame": self.frame,
            "value": self.value,
            "started": self.started
        }
    end
end

p2smart.Counter = Counter
p2smart.GPIOInput = GPIOInput
p2smart.GPIOOutput = GPIOOutput
p2smart.NormalPin = NormalPin
p2smart.Quadrature = Quadrature
p2smart.Repository = Repository
p2smart.PWM = PWM
p2smart.NCO = NCO
p2smart.NCODuty = NCODuty
p2smart.Pulse = Pulse
p2smart.Transition = Transition
p2smart.AsyncSerialPair = AsyncSerialPair
p2smart.SyncSerialPair = SyncSerialPair
p2smart.ADC = ADC
p2smart.DAC = DAC

p2smart.capabilities = def()
    return {
        "gpio": "verified",
        "gpio_diagnostics": "diagnostic",
        "gpio_loopback_probe": "diagnostic",
        "jumper_pair_probe": "diagnostic",
        "jumper_pair_checks": "diagnostic",
        "jumper_pairs_probe": "diagnostic",
        "default_jumper_pairs": "diagnostic",
        "default_jumper_directions": "diagnostic",
        "default_clocked_jumper_groups": "diagnostic",
        "default_jumper_pairs_probe": "diagnostic",
        "jumper_pairs_bidirectional_probe": "diagnostic",
        "default_jumper_pairs_bidirectional_probe": "diagnostic",
        "normal_pin": "verified",
        "normal_pin_diagnostics": "diagnostic",
        "raw_smartpin": "verified",
        "raw_smartpin_probe": "diagnostic",
        "raw_smartpin_reserved_pin_policy": "diagnostic",
        "raw_smartpin_reserved_pin_rejection": "staged",
        "counter": "verified",
        "counter_sample_diagnostics": "diagnostic",
        "counter_variant_sample_probe": "diagnostic",
        "counter_variant_drive_probe": "diagnostic",
        "counter_variant_drive_modes_probe": "diagnostic",
        "counter_timer_calibration_policy": "diagnostic",
        "counter_timer_calibrated_probe": "unsupported",
        "high_counter_probe": "diagnostic",
        "counter_mode_variants": "setup_only",
        "repository": "verified",
        "repository_write_diagnostics": "diagnostic",
        "repository_read_diagnostics": "diagnostic",
        "repository_probe": "diagnostic",
        "pwm": "verified",
        "pwm_duty_diagnostics": "diagnostic",
        "pwm_counter_probe": "diagnostic",
        "pwm_variant_counter_probe": "diagnostic",
        "pwm_duty_shape_probe": "verified",
        "pwm_mode_variants": "setup_only",
        "nco": "verified",
        "nco_increment_diagnostics": "diagnostic",
        "nco_counter_probe": "diagnostic",
        "nco_duty": "verified",
        "nco_duty_diagnostics": "verified",
        "nco_duty_counter_probe": "verified",
        "nco_duty_waveform_probe": "verified",
        "pulse": "verified",
        "pulse_trigger_diagnostics": "diagnostic",
        "pulse_counter_probe": "diagnostic",
        "transition": "verified",
        "transition_trigger_diagnostics": "diagnostic",
        "transition_counter_probe": "diagnostic",
        "adc": "setup_readback",
        "adc_sample_diagnostics": "diagnostic",
        "adc_variant_sample_probe": "diagnostic",
        "adc_variant_dac_sampled_probe": "diagnostic",
        "adc_mode_variants": "setup_only",
        "dac": "setup_output",
        "dac_set_diagnostics": "diagnostic",
        "dac_mode_variants": "setup_only",
        "adc_dac_probe": "diagnostic",
        "adc_dac_sampled_probe": "verified",
        "dac_variant_adc_probe": "diagnostic",
        "dac_variant_adc_sampled_probe": "verified",
        "adc_dac_variants_sampled_probe": "diagnostic",
        "adc_dac_delta_policy": "diagnostic",
        "adc_dac_delta": "unverified",
        "adc_dac_calibrated_probe": "unsupported",
        "quadrature": "setup_only",
        "quadrature_sample_diagnostics": "diagnostic",
        "quadrature_sample_probe": "diagnostic",
        "quadrature_mechanical_policy": "diagnostic",
        "quadrature_mechanical_encoder": "unsupported",
        "async_serial": "verified",
        "async_serial_zero_byte": "verified",
        "async_serial_paced_exchange": "verified",
        "async_serial_probe": "diagnostic",
        "async_serial_drain": "diagnostic",
        "async_serial_drain_probe": "diagnostic",
        "async_serial_burst_probe": "diagnostic",
        "async_serial_buffer_policy": "diagnostic",
        "async_serial_buffer": "unsupported",
        "async_serial_buffered_pair": "unsupported",
        "sync_serial": "verified",
        "sync_serial_result_diagnostics": "verified",
        "sync_serial_transfer_diagnostics": "verified",
        "sync_serial_probe": "staged",
        "sync_serial_clocked_probe": "verified",
        "sync_serial_clocked_variant_probe": "staged",
        "sync_serial_clocked_jumper_probes": "verified",
        "sync_serial_clocked_jumper_variant_probes": "staged",
        "sync_serial_default_clocked_probe": "verified",
        "sync_serial_default_clocked_variant_probe": "staged",
        "sync_serial_receive_policy": "diagnostic",
        "sync_serial_receive": "verified",
        "usb_pair_policy": "diagnostic",
        "usb_pair": "unsupported",
        "usb_pair_probe": "unsupported"
    }
end

p2smart.required_capability_keys = def()
    return [
        "gpio",
        "gpio_diagnostics",
        "gpio_loopback_probe",
        "jumper_pair_probe",
        "jumper_pair_checks",
        "jumper_pairs_probe",
        "default_jumper_pairs",
        "default_jumper_directions",
        "default_clocked_jumper_groups",
        "default_jumper_pairs_probe",
        "jumper_pairs_bidirectional_probe",
        "default_jumper_pairs_bidirectional_probe",
        "normal_pin",
        "normal_pin_diagnostics",
        "raw_smartpin",
        "raw_smartpin_probe",
        "raw_smartpin_reserved_pin_policy",
        "raw_smartpin_reserved_pin_rejection",
        "counter",
        "counter_sample_diagnostics",
        "counter_variant_sample_probe",
        "counter_variant_drive_probe",
        "counter_variant_drive_modes_probe",
        "counter_timer_calibration_policy",
        "counter_timer_calibrated_probe",
        "high_counter_probe",
        "counter_mode_variants",
        "repository",
        "repository_write_diagnostics",
        "repository_read_diagnostics",
        "repository_probe",
        "pwm",
        "pwm_duty_diagnostics",
        "pwm_counter_probe",
        "pwm_variant_counter_probe",
        "pwm_duty_shape_probe",
        "pwm_mode_variants",
        "nco",
        "nco_increment_diagnostics",
        "nco_counter_probe",
        "nco_duty",
        "nco_duty_diagnostics",
        "nco_duty_counter_probe",
        "nco_duty_waveform_probe",
        "pulse",
        "pulse_trigger_diagnostics",
        "pulse_counter_probe",
        "transition",
        "transition_trigger_diagnostics",
        "transition_counter_probe",
        "adc",
        "adc_sample_diagnostics",
        "adc_variant_sample_probe",
        "adc_variant_dac_sampled_probe",
        "adc_mode_variants",
        "dac",
        "dac_set_diagnostics",
        "dac_mode_variants",
        "adc_dac_probe",
        "adc_dac_sampled_probe",
        "dac_variant_adc_probe",
        "dac_variant_adc_sampled_probe",
        "adc_dac_variants_sampled_probe",
        "adc_dac_delta_policy",
        "adc_dac_delta",
        "adc_dac_calibrated_probe",
        "quadrature",
        "quadrature_sample_diagnostics",
        "quadrature_sample_probe",
        "quadrature_mechanical_policy",
        "quadrature_mechanical_encoder",
        "async_serial",
        "async_serial_zero_byte",
        "async_serial_paced_exchange",
        "async_serial_probe",
        "async_serial_drain",
        "async_serial_drain_probe",
        "async_serial_burst_probe",
        "async_serial_buffer_policy",
        "async_serial_buffer",
        "async_serial_buffered_pair",
        "sync_serial",
        "sync_serial_result_diagnostics",
        "sync_serial_transfer_diagnostics",
        "sync_serial_probe",
        "sync_serial_clocked_probe",
        "sync_serial_clocked_variant_probe",
        "sync_serial_clocked_jumper_probes",
        "sync_serial_clocked_jumper_variant_probes",
        "sync_serial_default_clocked_probe",
        "sync_serial_default_clocked_variant_probe",
        "sync_serial_receive_policy",
        "sync_serial_receive",
        "usb_pair_policy",
        "usb_pair",
        "usb_pair_probe"
    ]
end

p2smart.raw_smartpin_reserved_pin_policy = def()
    return {
        "ok": true,
        "capability": "raw_smartpin_reserved_pin_rejection",
        "status": p2smart.status("raw_smartpin_reserved_pin_rejection"),
        "policy": "deferred_current_image_hangs",
        "safe_test_pins": [0, 1, 2, 3, 4, 5, 6, 7],
        "reserved_pin_classes": ["psram", "sd", "serial"],
        "attempted_probe": "/tests/p2/smoke_smartpins_reserved_pins.be",
        "attempt_result": "hung_before_begin_marker",
        "recommendation": "do not include raw p2.smart reserved-pin negative probes in routine first-four priority smokes until isolated"
    }
end

p2smart.usb_pair_policy = def()
    return {
        "ok": true,
        "supported": false,
        "capability": "usb_pair",
        "status": p2smart.status("usb_pair"),
        "policy": "unsupported_no_usb_stack",
        "raw_mode": p2smart.smart.usb_pair,
        "implemented_helpers": [],
        "safe_claim": "raw_constant_only",
        "reason": "the P2 smart-pin USB pair mode constant is exposed for completeness, but Berry does not yet provide USB packet, HID, host, or device stack ownership"
    }
end

p2smart.usb_pair_probe = def(pin_a, pin_b)
    p2smart._require_pin(pin_a)
    p2smart._require_pin(pin_b)
    raise "unsupported_error", "USB smart-pin pair is not implemented; use usb_pair_policy() for the explicit boundary"
end

p2smart.async_serial_buffer_policy = def()
    return {
        "ok": true,
        "supported": false,
        "capability": "async_serial_buffer",
        "status": p2smart.status("async_serial_buffer"),
        "policy": "unsupported_no_fifo_buffer",
        "receive_model": "single_smartpin_sample",
        "safe_receive_helpers": ["read_result", "read_byte", "read_result_after", "read_byte_after", "exchange_results_after", "read_available_results", "read_available", "async_serial_burst_probe"],
        "unsupported_helpers": ["async_serial_buffered_pair"],
        "cleanup_required": true,
        "clear_releases_state": true,
        "reason": "current AsyncSerialPair exposes direct smart-pin samples only; buffered RX/FIFO ownership is not implemented, so unpaced bursts must be treated as latest-sample diagnostics rather than queued bytes"
    }
end

p2smart.async_serial_buffered_pair = def(tx_pin, rx_pin, baud, bits, depth)
    var checked_tx = p2smart._require_pin(tx_pin)
    var checked_rx = p2smart._require_pin(rx_pin)
    if checked_tx == checked_rx
        raise "value_error", "tx_pin and rx_pin must differ"
    end
    if baud != nil
        p2smart.serial_bit_ticks(baud)
    end
    p2smart._require_serial_bits(bits == nil ? p2smart.DEFAULT_SERIAL_BITS : bits)
    p2smart._require_positive_int(depth == nil ? 16 : depth, "depth")
    raise "unsupported_error", "background async serial RX buffering/FIFO is not implemented; use async_serial_buffer_policy() for the explicit boundary"
end

p2smart.sync_serial_receive_policy = def()
    return {
        "ok": true,
        "supported": true,
        "capability": "sync_serial_receive",
        "status": p2smart.status("sync_serial_receive"),
        "policy": "verified_clocked_jumper_receive",
        "setup_status": p2smart.status("sync_serial"),
        "diagnostic_status": p2smart.status("sync_serial_receive_policy"),
        "receive_model": "smartpin_sync_io_left_aligned_word",
        "safe_probe_helpers": ["sync_serial_probe", "sync_serial_clocked_probe", "sync_serial_clocked_variant_probe", "sync_serial_clocked_jumper_probes", "sync_serial_default_clocked_probe", "sync_serial_default_clocked_variant_probe"],
        "bounded_clocked_probe": true,
        "bounded_variant_probe": true,
        "variant_execution_supported": false,
        "deferred_sync_variants": ["normal_clock", "inverted_rx_clock", "inverted_clock_output", "inverted_output_and_rx_clock"],
        "unclocked_constant_raw_observed": true,
        "clocked_ready_observed": true,
        "matched_receive_words": true,
        "default_clocked_jumper_groups": p2smart.default_clocked_jumper_groups(),
        "reason": "clocked jumper probes use sync X=(bits-1)|0x20 and decode left-aligned receive words; phase-variant execution is still reported but not run by the source wrapper because repeated variant execution can wedge the current smart-pin setup"
    }
end

p2smart.adc_dac_delta_policy = def()
    return {
        "ok": true,
        "supported": false,
        "capability": "adc_dac_delta",
        "status": p2smart.status("adc_dac_delta"),
        "policy": "unverified_no_calibrated_threshold",
        "setup_probe": "dac_adc_probe",
        "variant_probe": "dac_variant_adc_probe",
        "measured_fields": ["low_sample", "high_sample", "delta", "abs_delta", "threshold"],
        "calibrated_voltage": false,
        "polarity_verified": false,
        "safe_claim": "setup_readback_only",
        "safe_probe_helpers": ["dac_adc_sampled_probe", "dac_variant_adc_sampled_probe"],
        "unsupported_helpers": ["adc_dac_calibrated_probe"],
        "reason": "DAC output to ADC input can be staged and sampled, but calibrated voltage and polarity thresholds are not yet hardware-validated"
    }
end

p2smart.adc_dac_calibrated_probe = def(out_pin, in_pin, low_value, high_value, min_mv)
    var checked_out = p2smart._require_pin(out_pin)
    var checked_in = p2smart._require_pin(in_pin)
    if checked_out == checked_in
        raise "value_error", "out_pin and in_pin must differ"
    end
    p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    p2smart._require_positive_int(min_mv == nil ? 1 : min_mv, "min_mv")
    raise "unsupported_error", "calibrated ADC/DAC voltage and polarity interpretation is not implemented; use adc_dac_delta_policy() for the explicit boundary"
end

p2smart.counter_timer_calibration_policy = def()
    return {
        "ok": true,
        "supported": false,
        "capability": "counter_timer_calibrated_probe",
        "status": p2smart.status("counter_timer_calibrated_probe"),
        "policy": "unsupported_no_calibrated_timer_scaling",
        "raw_diagnostic_status": p2smart.status("counter_variant_drive_probe"),
        "matrix_target": "p2-smoke-smartpins-counter-timer-matrix",
        "observed_modes": ["state_ticks", "events_ticks", "periods_ticks", "periods_highs", "counter_ticks", "counter_highs", "counter_periods"],
        "verified_raw_claim": "selected-input observations can move and be recorded",
        "unsupported_claims": ["microsecond_scaling", "absolute_frequency", "mode_to_unit_mapping", "jitter_bounds"],
        "safe_probe_helpers": ["counter_variant_sample_probe", "counter_variant_drive_probe", "counter_variant_drive_modes_probe"],
        "unsupported_helpers": ["counter_timer_calibrated_probe"],
        "reason": "current hardware diagnostics show positive selected-input observations but not stable scaling across pulse widths, so calibrated timer/counter interpretation is not implemented"
    }
end

p2smart.counter_timer_calibrated_probe = def(out_pin, in_pin, mode_name, pulse_us, pulses)
    var checked_out = p2smart._require_pin(out_pin)
    var checked_in = p2smart._require_pin(in_pin)
    if checked_out == checked_in
        raise "value_error", "out_pin and in_pin must differ"
    end
    p2smart.counter_mode(mode_name == nil ? "counter_ticks" : mode_name)
    p2smart._require_positive_int(pulse_us == nil ? 100 : pulse_us, "pulse_us")
    p2smart._require_positive_int(pulses == nil ? 4 : pulses, "pulses")
    raise "unsupported_error", "calibrated smart-pin timer/counter interpretation is not implemented; use counter_timer_calibration_policy() for the explicit boundary"
end

p2smart.quadrature_mechanical_policy = def()
    return {
        "ok": true,
        "supported": false,
        "capability": "quadrature_mechanical_encoder",
        "status": p2smart.status("quadrature_mechanical_encoder"),
        "policy": "unsupported_no_mechanical_encoder_validation",
        "setup_status": p2smart.status("quadrature"),
        "synthetic_motion_status": p2smart.status("quadrature_sample_probe"),
        "verified_motion_model": "jumper_driven_synthetic_quadrature",
        "verified_helpers": ["quadrature", "quadrature_sample_probe"],
        "unsupported_helpers": ["quadrature_mechanical_encoder"],
        "unsupported_claims": ["real_encoder_bounce", "detent_direction", "missed_step_bounds", "mechanical_noise_filtering"],
        "reason": "current hardware evidence covers setup and jumper-driven synthetic forward/reverse motion only; no real mechanical encoder debounce/noise/missed-step behavior has been validated"
    }
end

p2smart.quadrature_mechanical_encoder = def(pin_a, pin_b, mode)
    p2smart.quadrature(pin_a, pin_b, mode)
    raise "unsupported_error", "mechanical quadrature encoder behavior is not implemented; use quadrature_mechanical_policy() for the explicit boundary"
end

p2smart.statuses = def()
    var out = []
    for status : p2smart._statuses
        out.push(status)
    end
    return out
end

p2smart.status_known = def(status)
    if type(status) != "string"
        return false
    end
    for item : p2smart._statuses
        if item == status
            return true
        end
    end
    return false
end

p2smart.status = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = p2smart.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

p2smart.names = def()
    var caps = p2smart.capabilities()
    var out = []
    for name : caps.keys()
        out.push(name)
    end
    return out
end

p2smart.items_by_status = def(status)
    if !p2smart.status_known(status)
        raise "value_error", "unknown capability status"
    end
    var caps = p2smart.capabilities()
    var out = []
    for name : caps.keys()
        if caps[name] == status
            out.push(name)
        end
    end
    return out
end

p2smart.names_by_status = def(status)
    return p2smart.items_by_status(status)
end

p2smart.status_report = def()
    var caps = p2smart.capabilities()
    return {
        "ok": true,
        "verified": p2smart.items_by_status("verified"),
        "staged": p2smart.items_by_status("setup_readback") + p2smart.items_by_status("setup_output") + p2smart.items_by_status("diagnostic") + p2smart.items_by_status("setup_only") + p2smart.items_by_status("staged"),
        "open": p2smart.items_by_status("unverified") + p2smart.items_by_status("unsupported"),
        "capabilities": caps
    }
end

p2smart.audit = def()
    var caps = p2smart.capabilities()
    var seen = {}
    var duplicates = []
    var unknown_statuses = []
    var missing_capability_keys = []
    var jumper_check_duplicates = []
    var jumper_check_missing = []
    var counted = {}
    for status : p2smart._statuses
        counted[status] = 0
    end
    for name : caps.keys()
        var status = caps[name]
        if seen.contains(name)
            duplicates.push(name)
        else
            seen[name] = true
        end
        if p2smart.status_known(status)
            counted[status] += 1
        else
            unknown_statuses.push(status)
        end
    end
    for name : p2smart.required_capability_keys()
        if !caps.contains(name)
            missing_capability_keys.push(name)
        end
    end
    var total = 0
    for status : p2smart._statuses
        total += counted[status]
    end
    var jumper_seen = {}
    var jumper_checks = p2smart.jumper_pair_checks()
    for name : jumper_checks
        if jumper_seen.contains(name)
            jumper_check_duplicates.push(name)
        else
            jumper_seen[name] = true
        end
    end
    for required : ["raw_out", "raw_in", "gpio", "high_counter", "pulse_counter", "transition_counter", "async_serial", "async_serial_drain"]
        if !jumper_seen.contains(required)
            jumper_check_missing.push(required)
        end
    end
    var jumper_checks_ok = jumper_check_duplicates.size() == 0 && jumper_check_missing.size() == 0 && jumper_checks.size() == 8
    var counts_match = total == caps.keys().size()
    return {
        "ok": duplicates.size() == 0 && unknown_statuses.size() == 0 && missing_capability_keys.size() == 0 && counts_match && jumper_checks_ok,
        "count": caps.keys().size(),
        "counted": counted,
        "counts_match": counts_match,
        "duplicates": duplicates,
        "unknown_statuses": unknown_statuses,
        "missing_capability_keys": missing_capability_keys,
        "jumper_pair_checks": jumper_checks,
        "jumper_pair_checks_ok": jumper_checks_ok,
        "jumper_pair_check_duplicates": jumper_check_duplicates,
        "jumper_pair_check_missing": jumper_check_missing
    }
end

p2smart.audit_problems = def()
    var audit = p2smart.audit()
    var out = []
    if audit["duplicates"].size() > 0
        out.push("duplicate_capability_names")
    end
    if audit["unknown_statuses"].size() > 0
        out.push("unknown_capability_statuses")
    end
    if audit["missing_capability_keys"].size() > 0
        out.push("missing_capability_keys")
    end
    if !audit["counts_match"]
        out.push("status_count_mismatch")
    end
    if !audit["jumper_pair_checks_ok"]
        out.push("jumper_pair_checks_mismatch")
    end
    return out
end

p2smart.audit_ok = def()
    return p2smart.audit_problems().size() == 0
end

p2smart.raw_smartpin_probe = def(pin)
    var pin_no = p2smart._require_pin(pin)
    p2smart.smart.wrpin(pin_no, 0)
    p2smart.smart.wxpin(pin_no, 0)
    p2smart.smart.wypin(pin_no, 0)
    p2smart.smart.akpin(pin_no)
    var initial_read = p2smart.smart.rdpin(pin_no)
    var initial_query = p2smart.smart.rqpin(pin_no)
    p2smart.smart.start(pin_no, p2smart.smart.normal, 0, 0)
    var started_read = p2smart.smart.rdpin(pin_no)
    p2smart.smart.clear(pin_no)
    p2smart.pin.float(pin_no)
    var cleared_query = p2smart.smart.rqpin(pin_no)
    return {
        "ok": type(initial_read) == "int" && type(initial_query) == "int" && type(started_read) == "int" && type(cleared_query) == "int",
        "pin": pin_no,
        "mode": p2smart.smart.normal,
        "initial_read": initial_read,
        "initial_query": initial_query,
        "started_read": started_read,
        "cleared_query": cleared_query
    }
end

p2smart.gpio_loopback_probe = def(out_pin, in_pin, values, settle_us)
    var settle = settle_us == nil ? 10000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var pattern = values == nil ? [0, 1] : values
    if !isinstance(pattern, list)
        raise "type_error", "values must be a list"
    end
    if pattern.size() == 0
        raise "value_error", "values must not be empty"
    end
    var bits = []
    for value : pattern
        bits.push(p2smart._require_bit(value, "value"))
    end
    var out = p2smart.gpio_output(out_pin, nil)
    var input = p2smart.gpio_input(in_pin)
    out.start()
    input.start()
    var results = []
    var ok = true
    for value : bits
        var written = out.write_result(value)
        if settle > 0
            p2smart.waitus(settle)
        end
        var read = input.read_result()
        var matched = written["value"] == read["value"]
        if !matched
            ok = false
        end
        results.push({
            "ok": matched,
            "write": written,
            "read": read
        })
    end
    out.clear()
    input.clear()
    return {
        "ok": ok,
        "out_pin": out.pin,
        "in_pin": input.pin,
        "values": bits,
        "results": results,
        "count": results.size(),
        "settle_us": settle
    }
end

p2smart.high_counter_probe = def(out_pin, in_pin, high_us, settle_us)
    var high_delay = high_us == nil ? 1000 : p2smart._require_non_negative_int(high_us, "high_us")
    var settle = settle_us == nil ? 100 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, p2smart.smart.count_highs)
    var out = p2smart.gpio_output(out_pin, nil)
    counter.start()
    out.start()
    var before = counter.read()
    var high = out.write_result(1)
    if high_delay > 0
        p2smart.waitus(high_delay)
    end
    var low = out.write_result(0)
    if settle > 0
        p2smart.waitus(settle)
    end
    var after = counter.read()
    var delta = after - before
    counter.clear()
    out.clear()
    return {
        "ok": delta > 0,
        "out_pin": out.pin,
        "in_pin": counter.pin,
        "high": high,
        "low": low,
        "counter": {
            "ok": true,
            "pin": counter.pin,
            "mode": counter.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "advanced": delta > 0,
            "wait_us": high_delay
        },
        "high_us": high_delay,
        "settle_us": settle
    }
end

p2smart.counter_variant_drive_probe = def(out_pin, in_pin, mode_name, high_us, settle_us)
    var high_delay = high_us == nil ? 1000 : p2smart._require_non_negative_int(high_us, "high_us")
    var settle = settle_us == nil ? 100 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter_variant(in_pin, mode_name)
    var out = p2smart.gpio_output(out_pin, nil)
    out.start()
    var low_before = out.write_result(0)
    counter.start()
    var before = counter.read()
    var high = out.write_result(1)
    if high_delay > 0
        p2smart.waitus(high_delay)
    end
    var low_after = out.write_result(0)
    if settle > 0
        p2smart.waitus(settle)
    end
    var after = counter.read()
    var delta = after - before
    counter.clear()
    out.clear()
    return {
        "ok": delta > 0,
        "out_pin": out.pin,
        "in_pin": counter.pin,
        "mode_name": mode_name == nil ? "count_rises" : mode_name,
        "mode": counter.mode,
        "low_before": low_before,
        "high": high,
        "low_after": low_after,
        "counter": {
            "ok": true,
            "pin": counter.pin,
            "mode": counter.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "advanced": delta > 0,
            "wait_us": high_delay
        },
        "high_us": high_delay,
        "settle_us": settle
    }
end

p2smart.counter_variant_drive_modes_probe = def(out_pin, in_pin, modes, high_us, settle_us)
    var names = modes == nil ? ["count_highs"] : modes
    if !isinstance(names, list)
        raise "type_error", "modes must be a list"
    end
    if names.size() == 0
        raise "value_error", "modes must not be empty"
    end
    var results = []
    var ok_count = 0
    var failed_modes = []
    for mode_name : names
        var result = nil
        try
            result = p2smart.counter_variant_drive_probe(out_pin, in_pin, mode_name, high_us, settle_us)
        except .. as e, m
            result = p2smart._probe_error("counter_variant_drive", e, m)
            result["mode_name"] = mode_name
        end
        results.push(result)
        if result["ok"]
            ok_count += 1
        else
            failed_modes.push(mode_name)
        end
    end
    return {
        "ok": ok_count == results.size(),
        "out_pin": p2smart._require_pin(out_pin),
        "in_pin": p2smart._require_pin(in_pin),
        "modes": names.copy(),
        "results": results,
        "count": results.size(),
        "ok_count": ok_count,
        "failed_count": results.size() - ok_count,
        "failed_modes": failed_modes,
        "high_us": high_us == nil ? 1000 : p2smart._require_non_negative_int(high_us, "high_us"),
        "settle_us": settle_us == nil ? 100 : p2smart._require_non_negative_int(settle_us, "settle_us")
    }
end

p2smart.repository_probe = def(pin, first_value, second_value, settle_us)
    var first = p2smart._require_non_negative_int(first_value == nil ? p2smart.DEFAULT_REPOSITORY_VALUE : first_value, "first_value")
    var second = p2smart._require_non_negative_int(second_value == nil ? first : second_value, "second_value")
    var settle = settle_us == nil ? 100 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var repository = p2smart.repository(pin, first, nil)
    repository.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var first_read = repository.read_result()
    var write = repository.write_result(second, settle)
    var second_read = repository.read_result()
    repository.clear()
    return {
        "ok": true,
        "pin": repository.pin,
        "mode": repository.mode,
        "first": first_read,
        "write": write,
        "second": second_read,
        "settle_us": settle
    }
end

p2smart.pwm_counter_probe = def(out_pin, in_pin, frame, duty, divisor, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, nil)
    var pwm = p2smart.pwm(out_pin, frame, duty, divisor, nil)
    counter.start()
    pwm.start()
    var sample = counter.sample_after(settle)
    pwm.clear()
    counter.clear()
    return {
        "ok": sample["advanced"],
        "out_pin": pwm.pin,
        "in_pin": counter.pin,
        "pwm": pwm.info(),
        "counter": sample,
        "settle_us": settle
    }
end

p2smart.pwm_variant_counter_probe = def(out_pin, in_pin, frame, duty, divisor, mode_name, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, nil)
    var pwm = p2smart.pwm_variant(out_pin, frame, duty, divisor, mode_name)
    counter.start()
    pwm.start()
    var sample = counter.sample_after(settle)
    pwm.clear()
    counter.clear()
    return {
        "ok": sample["advanced"],
        "out_pin": pwm.pin,
        "in_pin": counter.pin,
        "mode_name": mode_name == nil ? "triangle" : mode_name,
        "pwm": pwm.info(),
        "counter": sample,
        "settle_us": settle
    }
end

p2smart.pwm_duty_shape_probe = def(out_pin, in_pin, frame, low_duty, high_duty, divisor, mode_name, sample_us, settle_us)
    var period = p2smart._require_pwm_frame(frame == nil ? p2smart.DEFAULT_PWM_FRAME : frame)
    var lo = p2smart._require_pwm_duty(low_duty == nil ? period / 4 : low_duty, period)
    var hi = p2smart._require_pwm_duty(high_duty == nil ? (period * 3) / 4 : high_duty, period)
    var div = p2smart._require_pwm_divisor(divisor == nil ? p2smart.DEFAULT_PWM_DIVISOR : divisor)
    var sample = sample_us == nil ? 5000 : p2smart._require_non_negative_int(sample_us, "sample_us")
    var settle = settle_us == nil ? 1000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var name = mode_name == nil ? "triangle" : mode_name
    var counter = p2smart.counter(in_pin, p2smart.smart.count_highs)
    var pwm = p2smart.pwm_variant(out_pin, period, lo, div, name)
    counter.start()
    pwm.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_sample = counter.sample_after(sample)
    pwm.set_duty(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_sample = counter.sample_after(sample)
    pwm.clear()
    counter.clear()
    var delta = high_sample["delta"] - low_sample["delta"]
    return {
        "ok": high_sample["delta"] > low_sample["delta"],
        "out_pin": pwm.pin,
        "in_pin": counter.pin,
        "mode_name": name,
        "frame": period,
        "low_duty": lo,
        "high_duty": hi,
        "divisor": div,
        "low": low_sample,
        "high": high_sample,
        "delta": delta,
        "sample_us": sample,
        "settle_us": settle,
        "pwm": pwm.info()
    }
end

p2smart.nco_counter_probe = def(out_pin, in_pin, bit_period, increment, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, nil)
    var nco = p2smart.nco(out_pin, bit_period, increment, nil)
    counter.start()
    nco.start()
    var sample = counter.sample_after(settle)
    nco.clear()
    counter.clear()
    return {
        "ok": sample["advanced"],
        "out_pin": nco.pin,
        "in_pin": counter.pin,
        "nco": nco.info(),
        "counter": sample,
        "settle_us": settle
    }
end

p2smart.nco_duty_counter_probe = def(out_pin, in_pin, prescaler, duty, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, nil)
    var nco = p2smart.nco_duty(out_pin, prescaler, duty, nil)
    counter.start()
    nco.start()
    var sample = counter.sample_after(settle)
    nco.clear()
    counter.clear()
    return {
        "ok": sample["advanced"],
        "out_pin": nco.pin,
        "in_pin": counter.pin,
        "nco_duty": nco.info(),
        "counter": sample,
        "settle_us": settle
    }
end

p2smart.nco_duty_waveform_probe = def(out_pin, in_pin, prescaler, low_duty, high_duty, sample_us, settle_us)
    var scale = p2smart._require_positive_int(prescaler == nil ? p2smart.DEFAULT_NCO_DUTY_PRESCALER : prescaler, "prescaler")
    var lo = p2smart._require_non_negative_int(low_duty == nil ? 0x20000000 : low_duty, "low_duty")
    var hi = p2smart._require_non_negative_int(high_duty == nil ? 0x60000000 : high_duty, "high_duty")
    var sample = sample_us == nil ? 5000 : p2smart._require_non_negative_int(sample_us, "sample_us")
    var settle = settle_us == nil ? 1000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var counter = p2smart.counter(in_pin, p2smart.smart.count_highs)
    var nco = p2smart.nco_duty(out_pin, scale, lo, nil)
    counter.start()
    nco.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_sample = counter.sample_after(sample)
    nco.set_duty(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_sample = counter.sample_after(sample)
    nco.clear()
    counter.clear()
    var delta = high_sample["delta"] - low_sample["delta"]
    return {
        "ok": high_sample["delta"] > low_sample["delta"],
        "out_pin": nco.pin,
        "in_pin": counter.pin,
        "prescaler": scale,
        "bit_period": scale,
        "low_duty": lo,
        "high_duty": hi,
        "low_value": lo,
        "high_value": hi,
        "low": low_sample,
        "high": high_sample,
        "delta": delta,
        "sample_us": sample,
        "settle_us": settle,
        "nco_duty": nco.info()
    }
end

p2smart.pulse_counter_probe = def(out_pin, in_pin, high_ticks, low_ticks, count, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var trigger_count = p2smart._require_non_negative_int(count == nil ? p2smart.DEFAULT_PULSE_COUNT : count, "count")
    var counter = p2smart.counter(in_pin, nil)
    var pulse = p2smart.pulse(out_pin, high_ticks, low_ticks, 0, nil)
    counter.start()
    pulse.start()
    var before = counter.read()
    pulse.trigger(trigger_count)
    if settle > 0
        p2smart.waitus(settle)
    end
    var after = counter.read()
    var delta = after - before
    pulse.clear()
    counter.clear()
    return {
        "ok": delta > 0,
        "out_pin": pulse.pin,
        "in_pin": counter.pin,
        "pulse": pulse.info(),
        "counter": {
            "ok": true,
            "pin": counter.pin,
            "mode": counter.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "advanced": delta > 0,
            "wait_us": settle
        },
        "settle_us": settle
    }
end

p2smart.transition_counter_probe = def(out_pin, in_pin, width, count, settle_us)
    var settle = settle_us == nil ? 2000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var trigger_count = p2smart._require_non_negative_int(count == nil ? p2smart.DEFAULT_TRANSITION_COUNT : count, "count")
    var counter = p2smart.counter(in_pin, nil)
    var transition = p2smart.transition(out_pin, width, 0, nil)
    counter.start()
    transition.start()
    var before = counter.read()
    transition.trigger(trigger_count)
    if settle > 0
        p2smart.waitus(settle)
    end
    var after = counter.read()
    var delta = after - before
    transition.clear()
    counter.clear()
    return {
        "ok": delta > 0,
        "out_pin": transition.pin,
        "in_pin": counter.pin,
        "transition": transition.info(),
        "counter": {
            "ok": true,
            "pin": counter.pin,
            "mode": counter.mode,
            "before": before,
            "after": after,
            "delta": delta,
            "advanced": delta > 0,
            "wait_us": settle
        },
        "settle_us": settle
    }
end

p2smart._probe_error = def(check, e, m)
    return {
        "ok": false,
        "check": check,
        "error": str(e),
        "message": str(m),
        "cleanup_attempted": true
    }
end

p2smart._probe_cleanup_pin = def(pin_no)
    try
        p2smart.smart.clear(pin_no)
    except .. as e, m
    end
    try
        p2smart.pin.float(pin_no)
    except .. as e, m
    end
end

p2smart._probe_cleanup_pair = def(out_pin, in_pin)
    p2smart._probe_cleanup_pin(out_pin)
    p2smart._probe_cleanup_pin(in_pin)
end

p2smart.jumper_pair_probe = def(out_pin, in_pin)
    var out_no = p2smart._require_pin(out_pin)
    var in_no = p2smart._require_pin(in_pin)
    if out_no == in_no
        raise "value_error", "out_pin and in_pin must differ"
    end
    var raw_out = nil
    try
        raw_out = p2smart.raw_smartpin_probe(out_no)
    except .. as e, m
        raw_out = p2smart._probe_error("raw_out", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var raw_in = nil
    try
        raw_in = p2smart.raw_smartpin_probe(in_no)
    except .. as e, m
        raw_in = p2smart._probe_error("raw_in", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var gpio = nil
    try
        gpio = p2smart.gpio_loopback_probe(out_no, in_no, [0, 1, 0, 1], 100)
    except .. as e, m
        gpio = p2smart._probe_error("gpio", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var high_counter = nil
    try
        high_counter = p2smart.high_counter_probe(out_no, in_no, 1000, 100)
    except .. as e, m
        high_counter = p2smart._probe_error("high_counter", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var pulse_counter = nil
    try
        pulse_counter = p2smart.pulse_counter_probe(out_no, in_no, 100, 100, 8, 2000)
    except .. as e, m
        pulse_counter = p2smart._probe_error("pulse_counter", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var transition_counter = nil
    try
        transition_counter = p2smart.transition_counter_probe(out_no, in_no, 100, 8, 2000)
    except .. as e, m
        transition_counter = p2smart._probe_error("transition_counter", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var serial = nil
    try
        serial = p2smart.async_serial_probe(out_no, in_no, [0x00, 0x55, 0xa5, 0xff], 100, 115200, 8)
    except .. as e, m
        serial = p2smart._probe_error("async_serial", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var serial_drain = nil
    try
        serial_drain = p2smart.async_serial_drain_probe(out_no, in_no, 0x33, 2000, 115200, 8, 4)
    except .. as e, m
        serial_drain = p2smart._probe_error("async_serial_drain", e, m)
        p2smart._probe_cleanup_pair(out_no, in_no)
    end
    var ok_count = 0
    var failed_checks = []
    var check_names = p2smart.jumper_pair_checks()
    var checks = [
        [check_names[0], raw_out],
        [check_names[1], raw_in],
        [check_names[2], gpio],
        [check_names[3], high_counter],
        [check_names[4], pulse_counter],
        [check_names[5], transition_counter],
        [check_names[6], serial],
        [check_names[7], serial_drain]
    ]
    for check : checks
        var item = check[1]
        if item["ok"]
            ok_count += 1
        else
            failed_checks.push(check[0])
        end
    end
    return {
        "ok": ok_count == check_names.size(),
        "out_pin": out_no,
        "in_pin": in_no,
        "count": check_names.size(),
        "checks": check_names,
        "ok_count": ok_count,
        "failed_count": failed_checks.size(),
        "failed_checks": failed_checks,
        "raw_out": raw_out,
        "raw_in": raw_in,
        "gpio": gpio,
        "high_counter": high_counter,
        "pulse_counter": pulse_counter,
        "transition_counter": transition_counter,
        "async_serial": serial,
        "async_serial_drain": serial_drain
    }
end

p2smart.jumper_pairs_probe = def(pairs)
    if pairs == nil
        raise "value_error", "pairs must be a list of two-pin lists"
    end
    if !isinstance(pairs, list)
        raise "type_error", "pairs must be a list"
    end
    if pairs.size() == 0
        raise "value_error", "pairs must not be empty"
    end
    var results = []
    var normalized_pairs = []
    var failed_pairs = []
    var failures = []
    var ok_count = 0
    for pair : pairs
        if !isinstance(pair, list) || pair.size() != 2
            raise "value_error", "each pair must contain exactly two pins"
        end
        var out_no = p2smart._require_pin(pair[0])
        var in_no = p2smart._require_pin(pair[1])
        if out_no == in_no
            raise "value_error", "pair pins must differ"
        end
        normalized_pairs.push([out_no, in_no])
        var result = p2smart.jumper_pair_probe(out_no, in_no)
        if result["ok"]
            ok_count += 1
        else
            failed_pairs.push([out_no, in_no])
            var result_ok_count = result.contains("ok_count") && type(result["ok_count"]) == "int" ? result["ok_count"] : 0
            var result_failed_count = result.contains("failed_count") && type(result["failed_count"]) == "int" ? result["failed_count"] : 1
            var result_failed_checks = result.contains("failed_checks") && isinstance(result["failed_checks"], list) ? result["failed_checks"] : []
            failures.push({
                "pair": [out_no, in_no],
                "ok_count": result_ok_count,
                "failed_count": result_failed_count,
                "failed_checks": result_failed_checks
            })
        end
        results.push(result)
    end
    return {
        "ok": ok_count == results.size(),
        "count": results.size(),
        "ok_count": ok_count,
        "failed_count": failed_pairs.size(),
        "failed_pairs": failed_pairs,
        "failures": failures,
        "pairs": normalized_pairs,
        "results": results
    }
end

p2smart.default_jumper_pairs_probe = def()
    return p2smart.jumper_pairs_probe(p2smart.default_jumper_pairs())
end

p2smart.jumper_pairs_bidirectional_probe = def(pairs)
    if pairs == nil
        raise "value_error", "pairs must be a list of two-pin lists"
    end
    if !isinstance(pairs, list)
        raise "type_error", "pairs must be a list"
    end
    if pairs.size() == 0
        raise "value_error", "pairs must not be empty"
    end
    var directions = []
    var source_pairs = []
    for pair : pairs
        if !isinstance(pair, list) || pair.size() != 2
            raise "value_error", "each pair must contain exactly two pins"
        end
        var a = p2smart._require_pin(pair[0])
        var b = p2smart._require_pin(pair[1])
        if a == b
            raise "value_error", "pair pins must differ"
        end
        source_pairs.push([a, b])
        directions.push([a, b])
        directions.push([b, a])
    end
    var result = p2smart.jumper_pairs_probe(directions)
    result["source_pairs"] = source_pairs
    result["direction_count"] = directions.size()
    result["bidirectional"] = true
    return result
end

p2smart.default_jumper_pairs_bidirectional_probe = def()
    return p2smart.jumper_pairs_bidirectional_probe(p2smart.default_jumper_pairs())
end

p2smart.jumper_pair_checks = def()
    return [
        "raw_out",
        "raw_in",
        "gpio",
        "high_counter",
        "pulse_counter",
        "transition_counter",
        "async_serial",
        "async_serial_drain"
    ]
end

p2smart.async_serial_probe = def(tx_pin, rx_pin, values, wait_us, baud, bits)
    if values == nil
        raise "value_error", "values must be a list of bytes"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    var bytes = []
    for value : values
        bytes.push(p2smart._require_byte(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var serial = p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, nil, nil)
    serial.start()
    var results = []
    var ready_count = 0
    for value : bytes
        serial.send(value)
        if delay > 0
            p2smart.waitus(delay)
        end
        var event = serial.available()
        if event != 0
            ready_count += 1
        end
        serial.ack()
        results.push({
            "ok": true,
            "sent": value,
            "event": event,
            "ready": event != 0
        })
    end
    serial.clear()
    return {
        "ok": true,
        "tx_pin": serial.tx_pin,
        "rx_pin": serial.rx_pin,
        "values": bytes,
        "results": results,
        "count": results.size(),
        "ready_count": ready_count,
        "wait_us": delay,
        "serial": serial.info()
    }
end

p2smart.async_serial_drain_probe = def(tx_pin, rx_pin, value, wait_us, baud, bits, max_count)
    var byte = p2smart._require_byte(value == nil ? 0x55 : value, "value")
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var limit = max_count == nil ? 4 : p2smart._require_non_negative_int(max_count, "max_count")
    var serial = p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, nil, nil)
    serial.start()
    serial.send(byte)
    if delay > 0
        p2smart.waitus(delay)
    end
    var drained = serial.read_available_results(limit)
    serial.clear()
    return {
        "ok": true,
        "tx_pin": serial.tx_pin,
        "rx_pin": serial.rx_pin,
        "sent": byte,
        "wait_us": delay,
        "max_count": limit,
        "drained": drained,
        "matched": drained["values"].size() > 0 && drained["values"][0] == byte,
        "serial": serial.info()
    }
end

p2smart.async_serial_burst_probe = def(tx_pin, rx_pin, values, wait_us, baud, bits)
    if values == nil
        raise "value_error", "values must be a list of bytes"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    var bytes = []
    for value : values
        bytes.push(p2smart._require_byte(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var serial = p2smart.async_serial_pair(tx_pin, rx_pin, baud, bits, nil, nil)
    serial.start()
    for value : bytes
        serial.send(value)
    end
    if delay > 0
        p2smart.waitus(delay)
    end
    var event = serial.available()
    var raw = serial.read_raw()
    var sampled = (raw >> 24) & 255
    var expected = bytes[bytes.size() - 1]
    serial.clear()
    return {
        "ok": sampled == expected,
        "tx_pin": serial.tx_pin,
        "rx_pin": serial.rx_pin,
        "values": bytes,
        "count": bytes.size(),
        "expected_latest": expected,
        "event": event,
        "raw": raw,
        "sampled": sampled,
        "latest_matched": sampled == expected,
        "wait_us": delay,
        "receive_model": "single_smartpin_sample",
        "fifo_buffered": false,
        "serial": serial.info()
    }
end

p2smart.sync_serial_probe = def(tx_pin, rx_pin, values, wait_us, baud, bits)
    if values == nil
        raise "value_error", "values must be a list of sync serial words"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    var words = []
    for value : values
        words.push(p2smart._require_non_negative_int(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var serial = p2smart.sync_serial_pair(tx_pin, rx_pin, baud, bits, nil, nil)
    serial.start()
    var results = serial.transfer_results(words, delay, nil)
    serial.clear()
    var ok = true
    var ready_count = 0
    var matched_count = 0
    for result : results
        if result["ready"]
            ready_count += 1
        end
        if result["matched"]
            matched_count += 1
        end
        if !result["ok"] || !result["matched"]
            ok = false
        end
    end
    return {
        "ok": ok,
        "tx_pin": serial.tx_pin,
        "rx_pin": serial.rx_pin,
        "values": words,
        "results": results,
        "count": results.size(),
        "ready_count": ready_count,
        "matched_count": matched_count,
        "wait_us": delay,
        "serial": serial.info()
    }
end

p2smart._sync_serial_clocked_probe_with_modes = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits, tx_mode, rx_mode, clock_mode)
    var data_tx = p2smart._require_pin(data_tx_pin)
    var data_rx = p2smart._require_pin(data_rx_pin)
    var clock_tx = p2smart._require_pin(clock_tx_pin)
    var clock_rx = p2smart._require_pin(clock_rx_pin)
    if data_tx == data_rx || data_tx == clock_tx || data_tx == clock_rx || data_rx == clock_tx || data_rx == clock_rx || clock_tx == clock_rx
        raise "value_error", "data and clock pins must be distinct"
    end
    if values == nil
        raise "value_error", "values must be a list of sync serial words"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    var words = []
    for value : values
        words.push(p2smart._require_non_negative_int(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var serial = p2smart.sync_serial_pair(data_tx, data_rx, baud, bits, tx_mode, rx_mode)
    var clock = p2smart.pulse(clock_tx, 1000, 1000, 0, clock_mode)
    p2smart.pin.float(clock_rx)
    clock.start()
    serial.start()
    var results = serial.transfer_results(words, delay, clock)
    serial.clear()
    clock.clear()
    p2smart.pin.float(clock_rx)
    var ok = true
    var ready_count = 0
    var matched_count = 0
    for result : results
        if result["ready"]
            ready_count += 1
        end
        if result["matched"]
            matched_count += 1
        end
        if !result["ok"] || !result["matched"]
            ok = false
        end
    end
    return {
        "ok": ok,
        "data_tx_pin": serial.tx_pin,
        "data_rx_pin": serial.rx_pin,
        "clock_tx_pin": clock.pin,
        "clock_rx_pin": clock_rx,
        "tx_mode": tx_mode,
        "rx_mode": rx_mode,
        "clock_mode": clock_mode,
        "values": words,
        "results": results,
        "count": results.size(),
        "ready_count": ready_count,
        "matched_count": matched_count,
        "matched_receive_words": ok,
        "receive_status": p2smart.status("sync_serial_receive"),
        "receive_policy": p2smart.sync_serial_receive_policy()["policy"],
        "execution_supported": true,
        "wait_us": delay,
        "serial": serial.info(),
        "clock": clock.info()
    }
end

p2smart.sync_serial_clocked_probe = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    var data_tx = p2smart._require_pin(data_tx_pin)
    var data_rx = p2smart._require_pin(data_rx_pin)
    var clock_tx = p2smart._require_pin(clock_tx_pin)
    var clock_rx = p2smart._require_pin(clock_rx_pin)
    var tx_mode = p2smart.smart.oe + p2smart.smart.sync_io + p2smart._relative_b_mode(data_tx, clock_tx) + p2smart.smart.sync_tx
    var rx_mode = p2smart.smart.sync_io + p2smart._relative_b_mode(data_rx, clock_rx) + p2smart.smart.sync_rx
    var clock_mode = p2smart.smart.oe + p2smart.smart.pulse
    return p2smart._sync_serial_clocked_probe_with_modes(data_tx, data_rx, clock_tx, clock_rx, values, wait_us, baud, bits, tx_mode, rx_mode, clock_mode)
end

p2smart.sync_serial_clocked_variants = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin)
    var data_tx = p2smart._require_pin(data_tx_pin)
    var data_rx = p2smart._require_pin(data_rx_pin)
    var clock_tx = p2smart._require_pin(clock_tx_pin)
    var clock_rx = p2smart._require_pin(clock_rx_pin)
    var tx_clock = p2smart._relative_b_mode(data_tx, clock_tx)
    var rx_clock = p2smart._relative_b_mode(data_rx, clock_rx)
    return [
        {
            "name": "normal_clock",
            "tx_mode": p2smart.smart.oe + p2smart.smart.sync_io + tx_clock + p2smart.smart.sync_tx,
            "rx_mode": p2smart.smart.sync_io + rx_clock + p2smart.smart.sync_rx,
            "clock_mode": p2smart.smart.oe + p2smart.smart.pulse
        },
        {
            "name": "inverted_rx_clock",
            "tx_mode": p2smart.smart.oe + p2smart.smart.sync_io + tx_clock + p2smart.smart.sync_tx,
            "rx_mode": p2smart.smart.sync_io + p2smart.smart.invert_b + rx_clock + p2smart.smart.sync_rx,
            "clock_mode": p2smart.smart.oe + p2smart.smart.pulse
        },
        {
            "name": "inverted_clock_output",
            "tx_mode": p2smart.smart.oe + p2smart.smart.sync_io + tx_clock + p2smart.smart.sync_tx,
            "rx_mode": p2smart.smart.sync_io + rx_clock + p2smart.smart.sync_rx,
            "clock_mode": p2smart.smart.oe + p2smart.smart.invert_output + p2smart.smart.pulse
        },
        {
            "name": "inverted_output_and_rx_clock",
            "tx_mode": p2smart.smart.oe + p2smart.smart.sync_io + tx_clock + p2smart.smart.sync_tx,
            "rx_mode": p2smart.smart.sync_io + p2smart.smart.invert_b + rx_clock + p2smart.smart.sync_rx,
            "clock_mode": p2smart.smart.oe + p2smart.smart.invert_output + p2smart.smart.pulse
        }
    ]
end

p2smart.sync_serial_clocked_variant_probe = def(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin, values, wait_us, baud, bits)
    var variants = p2smart.sync_serial_clocked_variants(data_tx_pin, data_rx_pin, clock_tx_pin, clock_rx_pin)
    if values == nil
        raise "value_error", "values must be a list of sync serial words"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    var words = []
    for value : values
        words.push(p2smart._require_non_negative_int(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var results = []
    for variant : variants
        var result = {
            "ok": false,
            "data_tx_pin": p2smart._require_pin(data_tx_pin),
            "data_rx_pin": p2smart._require_pin(data_rx_pin),
            "clock_tx_pin": p2smart._require_pin(clock_tx_pin),
            "clock_rx_pin": p2smart._require_pin(clock_rx_pin),
            "values": words,
            "results": [],
            "count": words.size(),
            "ready_count": 0,
            "matched_count": 0,
            "matched_receive_words": false,
            "receive_status": p2smart.status("sync_serial_receive"),
            "receive_policy": p2smart.sync_serial_receive_policy()["policy"],
            "wait_us": delay,
            "serial": nil,
            "clock": nil,
            "executed": false,
            "execution_supported": false,
            "error": "execution_deferred",
            "message": "sync-serial phase variants are reported but not executed because repeated source-wrapper variant execution can wedge the current smart-pin setup"
        }
        result["variant"] = variant["name"]
        result["tx_mode"] = variant["tx_mode"]
        result["rx_mode"] = variant["rx_mode"]
        result["clock_mode"] = variant["clock_mode"]
        results.push(result)
    end
    return {
        "ok": false,
        "data_tx_pin": p2smart._require_pin(data_tx_pin),
        "data_rx_pin": p2smart._require_pin(data_rx_pin),
        "clock_tx_pin": p2smart._require_pin(clock_tx_pin),
        "clock_rx_pin": p2smart._require_pin(clock_rx_pin),
        "values": words,
        "results": results,
        "count": words.size(),
        "ready_count": 0,
        "matched_count": 0,
        "matched_receive_words": false,
        "receive_status": p2smart.status("sync_serial_receive"),
        "receive_policy": p2smart.sync_serial_receive_policy()["policy"],
        "wait_us": delay,
        "variant_count": results.size(),
        "executed_variant_count": 0,
        "deferred_variant_count": results.size(),
        "selected_variant": nil,
        "selected": nil,
        "execution_supported": false,
        "error": "execution_deferred",
        "message": "sync-serial phase variants are reported but not executed because repeated source-wrapper variant execution can wedge the current smart-pin setup"
    }
end

p2smart.sync_serial_clocked_jumper_probes = def(groups, values, wait_us, baud, bits)
    if groups == nil
        raise "value_error", "groups must be a list of four-pin lists"
    end
    if !isinstance(groups, list)
        raise "type_error", "groups must be a list"
    end
    if groups.size() == 0
        raise "value_error", "groups must not be empty"
    end
    var results = []
    var normalized_groups = []
    var failed_groups = []
    var failures = []
    var ok_count = 0
    for group : groups
        if !isinstance(group, list) || group.size() != 4
            raise "value_error", "each sync serial group must contain four pins"
        end
        var data_tx = p2smart._require_pin(group[0])
        var data_rx = p2smart._require_pin(group[1])
        var clock_tx = p2smart._require_pin(group[2])
        var clock_rx = p2smart._require_pin(group[3])
        if data_tx == data_rx || data_tx == clock_tx || data_tx == clock_rx || data_rx == clock_tx || data_rx == clock_rx || clock_tx == clock_rx
            raise "value_error", "sync serial group pins must be distinct"
        end
        var normalized = [data_tx, data_rx, clock_tx, clock_rx]
        normalized_groups.push(normalized)
        var result = nil
        try
            result = p2smart.sync_serial_clocked_probe(data_tx, data_rx, clock_tx, clock_rx, values, wait_us, baud, bits)
        except .. as e, m
            result = p2smart._probe_error("sync_serial_clocked", e, m)
            result["data_tx_pin"] = data_tx
            result["data_rx_pin"] = data_rx
            result["clock_tx_pin"] = clock_tx
            result["clock_rx_pin"] = clock_rx
            p2smart._probe_cleanup_pin(data_tx)
            p2smart._probe_cleanup_pin(data_rx)
            p2smart._probe_cleanup_pin(clock_tx)
            p2smart._probe_cleanup_pin(clock_rx)
        end
        results.push(result)
        if result["ok"]
            ok_count += 1
        else
            failed_groups.push(normalized)
            failures.push({
                "group": normalized,
                "ready_count": result.contains("ready_count") ? result["ready_count"] : 0,
                "matched_count": result.contains("matched_count") ? result["matched_count"] : 0,
                "error": result.contains("error") ? result["error"] : nil,
                "message": result.contains("message") ? result["message"] : nil
            })
        end
    end
    return {
        "ok": ok_count == results.size(),
        "groups": normalized_groups,
        "results": results,
        "count": results.size(),
        "ok_count": ok_count,
        "failed_count": failed_groups.size(),
        "failed_groups": failed_groups,
        "failures": failures
    }
end

p2smart.sync_serial_clocked_jumper_variant_probes = def(groups, values, wait_us, baud, bits)
    if groups == nil
        raise "value_error", "groups must be a list of four-pin lists"
    end
    if !isinstance(groups, list)
        raise "type_error", "groups must be a list"
    end
    if groups.size() == 0
        raise "value_error", "groups must not be empty"
    end
    var results = []
    var normalized_groups = []
    var failed_groups = []
    var failures = []
    var words = []
    var ok_count = 0
    if values == nil
        raise "value_error", "values must be a list of sync serial words"
    end
    if !isinstance(values, list)
        raise "type_error", "values must be a list"
    end
    if values.size() == 0
        raise "value_error", "values must not be empty"
    end
    for value : values
        words.push(p2smart._require_non_negative_int(value, "value"))
    end
    var delay = wait_us == nil ? 100 : p2smart._require_non_negative_int(wait_us, "wait_us")
    for group : groups
        if !isinstance(group, list) || group.size() != 4
            raise "value_error", "each sync serial group must contain four pins"
        end
        var data_tx = p2smart._require_pin(group[0])
        var data_rx = p2smart._require_pin(group[1])
        var clock_tx = p2smart._require_pin(group[2])
        var clock_rx = p2smart._require_pin(group[3])
        if data_tx == data_rx || data_tx == clock_tx || data_tx == clock_rx || data_rx == clock_tx || data_rx == clock_rx || clock_tx == clock_rx
            raise "value_error", "sync serial group pins must be distinct"
        end
        var normalized = [data_tx, data_rx, clock_tx, clock_rx]
        normalized_groups.push(normalized)
        var variants = p2smart.sync_serial_clocked_variants(data_tx, data_rx, clock_tx, clock_rx)
        var result = {
            "ok": false,
            "data_tx_pin": data_tx,
            "data_rx_pin": data_rx,
            "clock_tx_pin": clock_tx,
            "clock_rx_pin": clock_rx,
            "values": words,
            "count": words.size(),
            "ready_count": 0,
            "matched_count": 0,
            "matched_receive_words": false,
            "receive_status": p2smart.status("sync_serial_receive"),
            "receive_policy": p2smart.sync_serial_receive_policy()["policy"],
            "wait_us": delay,
            "variant_count": variants.size(),
            "selected_variant": nil,
            "selected": nil,
            "execution_supported": false,
            "error": "execution_deferred",
            "message": "aggregate sync-serial phase variants are reported but not executed because repeated source-wrapper variant execution can wedge the current smart-pin setup"
        }
        results.push(result)
        if result["ok"]
            ok_count += 1
        else
            failed_groups.push(normalized)
            failures.push({
                "group": normalized,
                "variant_count": result.contains("variant_count") ? result["variant_count"] : 0,
                "selected_variant": result.contains("selected_variant") ? result["selected_variant"] : nil,
                "ready_count": result.contains("ready_count") ? result["ready_count"] : 0,
                "matched_count": result.contains("matched_count") ? result["matched_count"] : 0,
                "error": result.contains("error") ? result["error"] : nil,
                "message": result.contains("message") ? result["message"] : nil
            })
        end
    end
    return {
        "ok": ok_count == results.size(),
        "groups": normalized_groups,
        "results": results,
        "count": results.size(),
        "ok_count": ok_count,
        "failed_count": failed_groups.size(),
        "failed_groups": failed_groups,
        "failures": failures,
        "execution_supported": false,
        "error": "execution_deferred"
    }
end

p2smart.sync_serial_default_clocked_probe = def(values, wait_us, baud, bits)
    return p2smart.sync_serial_clocked_jumper_probes(p2smart.default_clocked_jumper_groups(), values, wait_us, baud, bits)
end

p2smart.sync_serial_default_clocked_variant_probe = def(values, wait_us, baud, bits)
    return p2smart.sync_serial_clocked_jumper_variant_probes(p2smart.default_clocked_jumper_groups(), values, wait_us, baud, bits)
end

p2smart.dac_adc_probe = def(out_pin, in_pin, low_value, high_value, settle_us, threshold)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var adc = p2smart.adc(in_pin, nil, nil)
    var dac = p2smart.dac(out_pin, lo, 256, nil)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_raw = adc.read()
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_raw = adc.read()
    dac.clear()
    adc.clear()
    var delta = high_raw - low_raw
    var abs_delta = delta < 0 ? -delta : delta
    return {
        "ok": abs_delta >= min_delta,
        "reason": abs_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": out_pin,
        "in_pin": in_pin,
        "low_value": lo,
        "high_value": hi,
        "low_raw": low_raw,
        "high_raw": high_raw,
        "delta": delta,
        "abs_delta": abs_delta,
        "threshold": min_delta,
        "settle_us": settle
    }
end

p2smart._adc_sample_stats = def(samples)
    var min_value = nil
    var max_value = nil
    var sum = 0
    for value : samples
        if min_value == nil || value < min_value
            min_value = value
        end
        if max_value == nil || value > max_value
            max_value = value
        end
        sum += value
    end
    return {
        "samples": samples,
        "count": samples.size(),
        "min": min_value,
        "max": max_value,
        "sum": sum,
        "avg": samples.size() == 0 ? nil : sum / samples.size()
    }
end

p2smart.dac_adc_sampled_probe = def(out_pin, in_pin, low_value, high_value, settle_us, threshold, samples, sample_interval_us)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var sample_count = samples == nil ? 4 : p2smart._require_positive_int(samples, "samples")
    var interval = sample_interval_us == nil ? 250 : p2smart._require_non_negative_int(sample_interval_us, "sample_interval_us")
    if sample_count > 32
        raise "value_error", "samples must be <= 32"
    end
    var adc = p2smart.adc(in_pin, nil, nil)
    var dac = p2smart.dac(out_pin, lo, 256, nil)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_samples = []
    var i = 0
    while i < sample_count
        low_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_samples = []
    i = 0
    while i < sample_count
        high_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.clear()
    adc.clear()
    var low_stats = p2smart._adc_sample_stats(low_samples)
    var high_stats = p2smart._adc_sample_stats(high_samples)
    var avg_delta = high_stats["avg"] - low_stats["avg"]
    var abs_avg_delta = avg_delta < 0 ? -avg_delta : avg_delta
    var min_to_max_delta = high_stats["min"] - low_stats["max"]
    var max_to_min_delta = high_stats["max"] - low_stats["min"]
    return {
        "ok": abs_avg_delta >= min_delta,
        "reason": abs_avg_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": dac.pin,
        "in_pin": adc.pin,
        "low_value": lo,
        "high_value": hi,
        "low": low_stats,
        "high": high_stats,
        "delta": avg_delta,
        "abs_delta": abs_avg_delta,
        "min_to_max_delta": min_to_max_delta,
        "max_to_min_delta": max_to_min_delta,
        "sample_count": sample_count,
        "threshold": min_delta,
        "settle_us": settle,
        "sample_interval_us": interval,
        "polarity": avg_delta > 0 ? "positive" : (avg_delta < 0 ? "negative" : "flat"),
        "polarity_verified": false,
        "calibrated_voltage": false,
        "dac": dac.info(),
        "adc": adc.info()
    }
end

p2smart.dac_variant_adc_probe = def(out_pin, in_pin, low_value, high_value, frame, resistor, dither, settle_us, threshold)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var dac_frame = p2smart._require_16_bit(frame == nil ? p2smart.DEFAULT_DAC_FRAME : frame, "frame")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var adc = p2smart.adc(in_pin, nil, nil)
    var dac = p2smart.dac_variant(out_pin, lo, dac_frame, resistor, dither)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_raw = adc.read()
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_raw = adc.read()
    dac.clear()
    adc.clear()
    var delta = high_raw - low_raw
    var abs_delta = delta < 0 ? -delta : delta
    return {
        "ok": abs_delta >= min_delta,
        "reason": abs_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": dac.pin,
        "in_pin": adc.pin,
        "low_value": lo,
        "high_value": hi,
        "low_raw": low_raw,
        "high_raw": high_raw,
        "delta": delta,
        "abs_delta": abs_delta,
        "threshold": min_delta,
        "settle_us": settle,
        "resistor": resistor == nil ? "990r_3v" : resistor,
        "dither": dither == nil ? "dither_pwm" : dither,
        "dac": dac.info(),
        "adc": adc.info()
    }
end

p2smart.dac_variant_adc_sampled_probe = def(out_pin, in_pin, low_value, high_value, frame, resistor, dither, settle_us, threshold, samples, sample_interval_us)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var dac_frame = p2smart._require_16_bit(frame == nil ? p2smart.DEFAULT_DAC_FRAME : frame, "frame")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var sample_count = samples == nil ? 4 : p2smart._require_positive_int(samples, "samples")
    var interval = sample_interval_us == nil ? 250 : p2smart._require_non_negative_int(sample_interval_us, "sample_interval_us")
    if sample_count > 32
        raise "value_error", "samples must be <= 32"
    end
    var adc = p2smart.adc(in_pin, nil, nil)
    var dac = p2smart.dac_variant(out_pin, lo, dac_frame, resistor, dither)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_samples = []
    var i = 0
    while i < sample_count
        low_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_samples = []
    i = 0
    while i < sample_count
        high_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.clear()
    adc.clear()
    var low_stats = p2smart._adc_sample_stats(low_samples)
    var high_stats = p2smart._adc_sample_stats(high_samples)
    var avg_delta = high_stats["avg"] - low_stats["avg"]
    var abs_avg_delta = avg_delta < 0 ? -avg_delta : avg_delta
    var min_to_max_delta = high_stats["min"] - low_stats["max"]
    var max_to_min_delta = high_stats["max"] - low_stats["min"]
    return {
        "ok": abs_avg_delta >= min_delta,
        "reason": abs_avg_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": dac.pin,
        "in_pin": adc.pin,
        "low_value": lo,
        "high_value": hi,
        "low": low_stats,
        "high": high_stats,
        "delta": avg_delta,
        "abs_delta": abs_avg_delta,
        "min_to_max_delta": min_to_max_delta,
        "max_to_min_delta": max_to_min_delta,
        "sample_count": sample_count,
        "threshold": min_delta,
        "settle_us": settle,
        "sample_interval_us": interval,
        "polarity": avg_delta > 0 ? "positive" : (avg_delta < 0 ? "negative" : "flat"),
        "polarity_verified": false,
        "calibrated_voltage": false,
        "resistor": resistor == nil ? "990r_3v" : resistor,
        "dither": dither == nil ? "dither_pwm" : dither,
        "dac": dac.info(),
        "adc": adc.info()
    }
end

p2smart.adc_variant_dac_sampled_probe = def(out_pin, in_pin, low_value, high_value, source, family, sample_ticks, settle_us, threshold, samples, sample_interval_us)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var ticks = sample_ticks == nil ? p2smart.DEFAULT_ADC_SAMPLE_TICKS : p2smart._require_positive_int(sample_ticks, "sample_ticks")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var sample_count = samples == nil ? 4 : p2smart._require_positive_int(samples, "samples")
    var interval = sample_interval_us == nil ? 250 : p2smart._require_non_negative_int(sample_interval_us, "sample_interval_us")
    if sample_count > 32
        raise "value_error", "samples must be <= 32"
    end
    var adc = p2smart.adc_variant(in_pin, source, family, ticks)
    var dac = p2smart.dac(out_pin, lo, 256, nil)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_samples = []
    var i = 0
    while i < sample_count
        low_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_samples = []
    i = 0
    while i < sample_count
        high_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.clear()
    adc.clear()
    var low_stats = p2smart._adc_sample_stats(low_samples)
    var high_stats = p2smart._adc_sample_stats(high_samples)
    var avg_delta = high_stats["avg"] - low_stats["avg"]
    var abs_avg_delta = avg_delta < 0 ? -avg_delta : avg_delta
    var min_to_max_delta = high_stats["min"] - low_stats["max"]
    var max_to_min_delta = high_stats["max"] - low_stats["min"]
    return {
        "ok": abs_avg_delta >= min_delta,
        "reason": abs_avg_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": dac.pin,
        "in_pin": adc.pin,
        "low_value": lo,
        "high_value": hi,
        "low": low_stats,
        "high": high_stats,
        "delta": avg_delta,
        "abs_delta": abs_avg_delta,
        "min_to_max_delta": min_to_max_delta,
        "max_to_min_delta": max_to_min_delta,
        "sample_count": sample_count,
        "threshold": min_delta,
        "settle_us": settle,
        "sample_interval_us": interval,
        "source": source == nil ? "1x" : source,
        "family": family == nil ? "adc" : family,
        "sample_ticks": ticks,
        "polarity": avg_delta > 0 ? "positive" : (avg_delta < 0 ? "negative" : "flat"),
        "polarity_verified": false,
        "calibrated_voltage": false,
        "dac": dac.info(),
        "adc": adc.info()
    }
end

p2smart.adc_dac_variants_sampled_probe = def(out_pin, in_pin, low_value, high_value, source, family, sample_ticks, frame, resistor, dither, settle_us, threshold, samples, sample_interval_us)
    var lo = p2smart._require_byte(low_value == nil ? 0 : low_value, "low_value")
    var hi = p2smart._require_byte(high_value == nil ? 255 : high_value, "high_value")
    var ticks = sample_ticks == nil ? p2smart.DEFAULT_ADC_SAMPLE_TICKS : p2smart._require_positive_int(sample_ticks, "sample_ticks")
    var dac_frame = p2smart._require_16_bit(frame == nil ? p2smart.DEFAULT_DAC_FRAME : frame, "frame")
    var settle = settle_us == nil ? 5000 : p2smart._require_non_negative_int(settle_us, "settle_us")
    var min_delta = threshold == nil ? 1 : p2smart._require_non_negative_int(threshold, "threshold")
    var sample_count = samples == nil ? 4 : p2smart._require_positive_int(samples, "samples")
    var interval = sample_interval_us == nil ? 250 : p2smart._require_non_negative_int(sample_interval_us, "sample_interval_us")
    if sample_count > 32
        raise "value_error", "samples must be <= 32"
    end
    var adc = p2smart.adc_variant(in_pin, source, family, ticks)
    var dac = p2smart.dac_variant(out_pin, lo, dac_frame, resistor, dither)
    adc.start()
    dac.start()
    if settle > 0
        p2smart.waitus(settle)
    end
    var low_samples = []
    var i = 0
    while i < sample_count
        low_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.set(hi)
    if settle > 0
        p2smart.waitus(settle)
    end
    var high_samples = []
    i = 0
    while i < sample_count
        high_samples.push(adc.read())
        if interval > 0 && i + 1 < sample_count
            p2smart.waitus(interval)
        end
        i += 1
    end
    dac.clear()
    adc.clear()
    var low_stats = p2smart._adc_sample_stats(low_samples)
    var high_stats = p2smart._adc_sample_stats(high_samples)
    var avg_delta = high_stats["avg"] - low_stats["avg"]
    var abs_avg_delta = avg_delta < 0 ? -avg_delta : avg_delta
    var min_to_max_delta = high_stats["min"] - low_stats["max"]
    var max_to_min_delta = high_stats["max"] - low_stats["min"]
    return {
        "ok": abs_avg_delta >= min_delta,
        "reason": abs_avg_delta >= min_delta ? nil : "delta_below_threshold",
        "out_pin": dac.pin,
        "in_pin": adc.pin,
        "low_value": lo,
        "high_value": hi,
        "low": low_stats,
        "high": high_stats,
        "delta": avg_delta,
        "abs_delta": abs_avg_delta,
        "min_to_max_delta": min_to_max_delta,
        "max_to_min_delta": max_to_min_delta,
        "sample_count": sample_count,
        "threshold": min_delta,
        "settle_us": settle,
        "sample_interval_us": interval,
        "source": source == nil ? "1x" : source,
        "family": family == nil ? "adc" : family,
        "sample_ticks": ticks,
        "resistor": resistor == nil ? "990r_3v" : resistor,
        "dither": dither == nil ? "dither_pwm" : dither,
        "polarity": avg_delta > 0 ? "positive" : (avg_delta < 0 ? "negative" : "flat"),
        "polarity_verified": false,
        "calibrated_voltage": false,
        "dac": dac.info(),
        "adc": adc.info()
    }
end

p2smart.adc_variant_sample_probe = def(pin, source, family, sample_ticks, wait_us)
    var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var adc = p2smart.adc_variant(pin, source, family, sample_ticks)
    adc.start()
    var sample = adc.sample_after(delay)
    adc.clear()
    return {
        "ok": sample["ok"],
        "pin": adc.pin,
        "source": source == nil ? "1x" : source,
        "family": family == nil ? "adc" : family,
        "mode": adc.mode,
        "sample_ticks": adc.sample_ticks,
        "sample": sample,
        "wait_us": delay,
        "adc": adc.info()
    }
end

p2smart.dac_mode = def(resistor, dither)
    return p2smart.smart.oe + p2smart._dac_resistor_mode(resistor) + p2smart._dac_dither_mode(dither)
end

p2smart.pwm_mode = def(name)
    return p2smart.smart.oe + p2smart._pwm_mode(name)
end

p2smart.adc_mode = def(source, family)
    return p2smart._adc_source_mode(source) + p2smart._adc_family_mode(family)
end

p2smart.counter_mode = def(name)
    return p2smart._counter_mode(name)
end

p2smart.counter = def(pin, mode)
    return Counter(pin, mode)
end

p2smart.counter_variant = def(pin, mode_name)
    return Counter(pin, p2smart.counter_mode(mode_name))
end

p2smart.counter_variant_sample_probe = def(pin, mode_name, wait_us)
    var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var counter = p2smart.counter_variant(pin, mode_name)
    counter.start()
    var sample = counter.sample_after(delay)
    counter.clear()
    return {
        "ok": sample["ok"],
        "pin": counter.pin,
        "mode_name": mode_name == nil ? "count_rises" : mode_name,
        "mode": counter.mode,
        "sample": sample,
        "wait_us": delay,
        "counter": counter.info()
    }
end

p2smart.quadrature = def(pin_a, pin_b, mode)
    return Quadrature(pin_a, pin_b, mode)
end

p2smart.quadrature_sample_probe = def(pin_a, pin_b, mode, wait_us)
    var delay = wait_us == nil ? 0 : p2smart._require_non_negative_int(wait_us, "wait_us")
    var quad = p2smart.quadrature(pin_a, pin_b, mode)
    quad.start()
    var sample = quad.sample_after(delay)
    quad.clear()
    return {
        "ok": sample["ok"],
        "pin_a": quad.pin_a,
        "pin_b": quad.pin_b,
        "mode": quad.mode,
        "sample": sample,
        "wait_us": delay,
        "quadrature": quad.info()
    }
end

p2smart.gpio_input = def(pin)
    return GPIOInput(pin)
end

p2smart.gpio_output = def(pin, value)
    return GPIOOutput(pin, value)
end

p2smart.normal_pin = def(pin, mode, value)
    return NormalPin(pin, mode, value)
end

p2smart.repository = def(pin, value, mode)
    return Repository(pin, value, mode)
end

p2smart.pwm = def(pin, frame, duty, divisor, mode)
    return PWM(pin, frame, duty, divisor, mode)
end

p2smart.pwm_variant = def(pin, frame, duty, divisor, mode_name)
    return PWM(pin, frame, duty, divisor, p2smart.pwm_mode(mode_name))
end

p2smart.nco = def(pin, bit_period, increment, mode)
    return NCO(pin, bit_period, increment, mode)
end

p2smart.nco_duty = def(pin, prescaler, duty, mode)
    return NCODuty(pin, prescaler, duty, mode)
end

p2smart.pulse = def(pin, high_ticks, low_ticks, count, mode)
    return Pulse(pin, high_ticks, low_ticks, count, mode)
end

p2smart.transition = def(pin, width, count, mode)
    return Transition(pin, width, count, mode)
end

p2smart.async_serial_pair = def(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)
    var bit_ticks = baud == nil ? nil : p2smart.serial_bit_ticks(baud)
    return AsyncSerialPair(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
end

p2smart.async_serial_pair_ticks = def(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
    return AsyncSerialPair(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
end

p2smart.sync_serial_pair = def(tx_pin, rx_pin, baud, bits, tx_mode, rx_mode)
    var bit_ticks = baud == nil ? nil : p2smart.serial_bit_ticks(baud)
    return SyncSerialPair(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
end

p2smart.sync_serial_pair_ticks = def(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
    return SyncSerialPair(tx_pin, rx_pin, bit_ticks, bits, tx_mode, rx_mode)
end

p2smart.adc = def(pin, mode, sample_ticks)
    return ADC(pin, mode, sample_ticks)
end

p2smart.adc_variant = def(pin, source, family, sample_ticks)
    return ADC(pin, p2smart.adc_mode(source, family), sample_ticks)
end

p2smart.dac = def(pin, value, frame, mode)
    return DAC(pin, value, frame, mode)
end

p2smart.dac_variant = def(pin, value, frame, resistor, dither)
    return DAC(pin, value, frame, p2smart.dac_mode(resistor, dither))
end

return p2smart
