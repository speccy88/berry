import worker
import p2

print(worker.start())
worker.exec("blink", 56, 250)
print(worker.state())

# Stop the worker later with:
# worker.stop()
