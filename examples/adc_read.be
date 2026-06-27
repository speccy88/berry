import p2

var pin = 1
var mode = p2.smart.adc_1x + p2.smart.adc
var sample_ticks = 32

print("ADC samples on pin", pin)
p2.smart.start(pin, mode, sample_ticks, 0)

var i = 0
while i < 4
    p2.waitus(20000)
    var event = p2.smart.rdpin(pin)
    var raw = p2.smart.rqpin(pin)
    p2.smart.akpin(pin)
    print("sample", i, "event", event, "raw", raw, "ticks", sample_ticks)
    i += 1
end

p2.smart.clear(pin)
p2.pin.float(pin)
print("adc done")
