import rtos

def producer(delay_ms)
    var seq = 0
    while true
        rtos.sleep_ms(delay_ms)
        seq += 1
        rtos.put("events_rx", seq)
        rtos.event_set(1)
    end
end

