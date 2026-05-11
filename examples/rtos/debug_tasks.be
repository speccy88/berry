import rtos

worker_source =
    "import rtos\n" +
    "def idle_task(delay_ms)\n" +
    "    while true\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "    end\n" +
    "end\n"

rtos.load(worker_source)
rtos.spawn("idle_task", 100)
print(rtos.debug_tasks())
print(rtos.debug_regs(rtos.cog_id()))
rtos.stop()

