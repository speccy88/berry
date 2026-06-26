import p2smart

var pin = 1
var adc = p2smart.adc(pin, nil, nil)

print("ADC samples on pin", pin)
adc.start()

for i : 0..3
    var sample = adc.sample_after(20000)
    print("sample", i, "ready", sample["ready"], "event", sample["event"], "raw", sample["raw"], "wait", sample["wait_us"])
    adc.ack()
end

adc.clear()
print("adc done")
