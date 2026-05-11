import rtos

# rtos.cog_start() is a name-based convenience wrapper over the worker VM.
# The v1 worker has built-in functions named "noop" and "blink".
cog = rtos.cog_start("blink", 56, 250)
print(cog)
print(rtos.state())

# Stop the blinking cog when you are done experimenting.
# rtos.stop()
