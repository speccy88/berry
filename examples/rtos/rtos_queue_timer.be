import rtos

rtos.channel("sensor")

for i: 1..5
    rtos.put("sensor", i)
end

timer = rtos.timer_start(100)
while !rtos.timer_expired(timer)
    rtos.task_yield()
end

while true
    value = rtos.get("sensor", 0)
    if value == nil
        break
    end
    print("sensor", value)
end

if rtos.event_wait(0x10, 10)
    print("unexpected event")
else
    print("event timeout")
end
