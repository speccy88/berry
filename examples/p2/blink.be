import p2
import rtos

p2.pinmode(56, p2.OUTPUT)

while true
    p2.high(56)
    rtos.sleep_ms(250)
    p2.low(56)
    rtos.sleep_ms(250)
end
