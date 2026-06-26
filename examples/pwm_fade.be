import p2smart

var pin = 0
var frame = 200
var pwm = p2smart.pwm(pin, frame, 0, 1, nil)

print("PWM fade on pin", pin)
pwm.start()

for step : 0..5
    var duty = step * 40
    var result = pwm.set_duty_result(duty, 50000)
    print("duty", result["ok"], "pin", result["pin"], "value", result["duty"], "frame", result["frame"], "divisor", result["divisor"], "settle", result["settle_us"])
end

for step : 5..0
    var duty = step * 40
    var result = pwm.set_duty_result(duty, 50000)
    print("duty", result["ok"], "pin", result["pin"], "value", result["duty"], "frame", result["frame"], "divisor", result["divisor"], "settle", result["settle_us"])
end

pwm.clear()
print("pwm fade done")
