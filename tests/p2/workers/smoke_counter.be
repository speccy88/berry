import rtos

def p2_smoke_counter(delay_ms)
    var n = 0
    while true
        n += 1
        rtos.put("p2_smoke_worker", n)
        rtos.sleep_ms(delay_ms)
    end
end
