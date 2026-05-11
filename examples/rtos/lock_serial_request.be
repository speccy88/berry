import rtos

worker_source =
    "import rtos\n" +
    "def serial_client(lock_id)\n" +
    "    var n = 0\n" +
    "    while true\n" +
    "        n += 1\n" +
    "        rtos.lock(lock_id)\n" +
    "        rtos.put('serial_requests', n)\n" +
    "        rtos.unlock(lock_id)\n" +
    "        rtos.sleep_ms(100)\n" +
    "    end\n" +
    "end\n"

serial_lock = rtos.new_lock()
rtos.channel("serial_requests")
rtos.load(worker_source)
rtos.spawn("serial_client", serial_lock)

for i: 1..5
    n = rtos.get("serial_requests", 500)
    rtos.lock(serial_lock)
    print("main repl print request", n)
    rtos.unlock(serial_lock)
end

rtos.stop()
rtos.delete_lock(serial_lock)

