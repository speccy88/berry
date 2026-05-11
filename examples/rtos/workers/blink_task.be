import p2
import rtos

def blink_task(pin, delay_ms)
    p2.pin_output(pin)
    while true
        p2.pin_high(pin)
        rtos.sleep_ms(delay_ms)
        p2.pin_low(pin)
        rtos.sleep_ms(delay_ms)
    end
end

