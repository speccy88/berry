import rtos

serial_lock = rtos.new_lock()
rtos.channel("serial_requests")
rtos.load_file("/examples/rtos/workers/serial_client.be")
rtos.spawn("serial_client", serial_lock)

for i: 1..5
    n = rtos.get("serial_requests", 500)
    rtos.lock(serial_lock)
    print("main repl print request", n)
    rtos.unlock(serial_lock)
end

rtos.stop()
rtos.delete_lock(serial_lock)
