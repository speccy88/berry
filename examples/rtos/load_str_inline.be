import rtos

source =
    "import rtos\n" +
    "def inline_task(delay_ms)\n" +
    "    var n = 0\n" +
    "    while true\n" +
    "        n += 1\n" +
    "        rtos.put('inline', n)\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "    end\n" +
    "end\n"

rtos.channel("inline")
rtos.load_str(source)
rtos.spawn("inline_task", 100)
print(rtos.get("inline", 500))
rtos.stop()

