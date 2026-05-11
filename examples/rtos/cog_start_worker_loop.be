import rtos

worker_source =
    "import rtos\n" +
    "def counter_task(delay_ms)\n" +
    "    var n = 0\n" +
    "    while true\n" +
    "        n += 1\n" +
    "        rtos.put('counter', n)\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "    end\n" +
    "end\n"

rtos.channel("counter")
rtos.load(worker_source)
cog = rtos.cog_start("counter_task", 100)
print("worker cog", cog)

for i: 1..5
    print("counter", rtos.get("counter", 500))
end

rtos.stop()
