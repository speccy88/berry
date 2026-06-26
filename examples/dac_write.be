import p2smart

var pin = 0
var dac = p2smart.dac(pin, 0, nil, nil)

print("DAC stepped output on pin", pin)
dac.start()

for value : [0, 64, 128, 192, 255, 0]
    var result = dac.set_result(value, 60000)
    print("dac", result["ok"], "pin", result["pin"], "value", result["value"], "frame", result["frame"], "settle", result["settle_us"])
end

dac.clear()
print("dac done")
