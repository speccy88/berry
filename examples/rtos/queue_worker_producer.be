import rtos

worker_source =
    "import rtos\n" +
    "def packet_reader(delay_ms)\n" +
    "    var seq = 0\n" +
    "    while true\n" +
    "        seq += 1\n" +
    "        rtos.put('rx_packets', seq)\n" +
    "        rtos.sleep_ms(delay_ms)\n" +
    "    end\n" +
    "end\n"

rtos.channel("rx_packets")
rtos.load(worker_source)
rtos.spawn("packet_reader", 50)

for i: 1..8
    print("packet", rtos.get("rx_packets", 250))
end

rtos.stop()
