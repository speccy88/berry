import rtos

rtos.channel("sensor")
rtos.put("sensor", 123)
print(rtos.get("sensor"))

rtos.event_set(0x01)
print(rtos.event_wait(0x01, 10))
rtos.event_clear(0x01)
