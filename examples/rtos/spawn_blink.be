import rtos
import worker

# rtos.spawn() uses the same worker VM backend as worker.exec() and p2.cog_start().
# The current worker VM preloads "noop" and "blink"; it cannot see functions
# defined in the main VM script.

cog = rtos.spawn("blink", 56, 250)
print("blink task cog", cog)
print(worker.state())

rtos.sleep_ms(2000)
worker.stop()
print(worker.state())
