import p2
import worker

# p2.cog_start() is a name-based convenience wrapper over the worker VM.
# The v1 worker has built-in functions named "noop" and "blink".
cog = p2.cog_start("blink", 56, 250)
print(cog)
print(worker.state())

# Stop the blinking cog when you are done experimenting.
# worker.stop()
