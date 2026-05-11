import rtos

rtos.channel("rx_packets")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
rtos.spawn("packet_reader", 50)

for i: 1..8
    print("packet", rtos.get("rx_packets", 250))
end

rtos.stop()
