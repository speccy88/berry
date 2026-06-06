import rtos

rtos.channel("rx_packets")
rtos.load_file("/examples/rtos/workers/packet_reader.be")
cog = rtos.newcog("packet_reader", 3)
print("process cog", cog)
print("process info", rtos.process_info())
print("packet", rtos.get("rx_packets", 500))
rtos.stop()
