import rtos

cog = rtos.spawn("blink", 56, 250)
print("blink task cog", cog)
print(rtos.state())

rtos.sleep_ms(2000)
rtos.stop()
print(rtos.state())
