import rtos

print("RTOS channel demo on current VM")

rtos.channel("demo")
rtos.put("demo", "hello")
rtos.put("demo", 42)

print(rtos.get("demo", 10))
print(rtos.get("demo", 10))
