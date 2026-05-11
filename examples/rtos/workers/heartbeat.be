import rtos

def heartbeat(period_ms)
    var n = 0
    while true
        var timer = rtos.timer_start(period_ms)
        rtos.timer_wait(timer)
        n += 1
        rtos.put("heartbeat", n)
    end
end

