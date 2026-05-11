import rtos

def idle_task(delay_ms)
    while true
        rtos.sleep_ms(delay_ms)
    end
end

