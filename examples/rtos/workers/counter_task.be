import rtos

def counter_task(delay_ms)
    var n = 0
    while true
        n += 1
        rtos.put("counter", n)
        rtos.sleep_ms(delay_ms)
    end
end

