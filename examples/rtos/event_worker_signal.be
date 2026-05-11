import rtos

var PACKET_READY = 0x01

worker_source =
    "import rtos\n" +
    "def producer(delay_ms)\n" +
    "    var seq = 0\n" +
    "    while true\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "        seq += 1\n" +
    "        rtos.put('events_rx', seq)\n" +
    "        rtos.event_set(1)\n" +
    "    end\n" +
    "end\n"

rtos.channel("events_rx")
rtos.load(worker_source)
rtos.spawn("producer", 100)

for i: 1..5
    if rtos.event_wait(PACKET_READY, 500)
        rtos.event_clear(PACKET_READY)
        print("event packet", rtos.get("events_rx", 0))
    end
end

rtos.stop()

