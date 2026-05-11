import rtos

worker_source =
    "import rtos\n" +
    "def heartbeat(period_ms)\n" +
    "    var n = 0\n" +
    "    while true\n" +
    "        var timer = rtos.timer_start(period_ms)\n" +
    "        rtos.timer_wait(timer)\n" +
    "        n += 1\n" +
    "        rtos.put('heartbeat', n)\n" +
    "    end\n" +
    "end\n"

rtos.channel("heartbeat")
rtos.load(worker_source)
rtos.spawn("heartbeat", 250)

for i: 1..4
    print("heartbeat", rtos.get("heartbeat", 500))
end

rtos.stop()
