import rtos

worker_source =
    "import p2\n" +
    "import rtos\n" +
    "def blink_task(pin, delay_ms)\n" +
    "    p2.pin_output(pin)\n" +
    "    while true\n" +
    "        p2.pin_high(pin)\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "        p2.pin_low(pin)\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "    end\n" +
    "end\n"

rtos.load(worker_source)
rtos.spawn("blink_task", 56, 250)
rtos.sleep_ms(2000)
rtos.stop()
