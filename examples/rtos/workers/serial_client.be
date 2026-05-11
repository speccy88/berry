import rtos

def serial_client(lock_id)
    var n = 0
    while true
        n += 1
        rtos.lock(lock_id)
        rtos.put("serial_requests", n)
        rtos.unlock(lock_id)
        rtos.sleep_ms(100)
    end
end

