import worker

print(worker.start())
worker.exec("blink", 56, 250)
print(worker.state())
