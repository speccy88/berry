import p2
import rtos

var led = 56

p2.pin_output(led)
p2.pin_write(led, 1)
rtos.sleep_ms(250)

p2.pin_low(led)
rtos.sleep_ms(250)

p2.pin_high(led)
rtos.sleep_ms(250)

p2.pin_toggle(led)
print(p2.pin_read(led))
rtos.sleep_ms(250)

p2.pin_randomize(led)
print(p2.pin_read(led))
rtos.sleep_ms(250)

p2.pin_float(led)
