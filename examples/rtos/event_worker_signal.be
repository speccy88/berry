import rtos

var PACKET_READY = 0x01

rtos.channel("events_rx")
rtos.load_file("/examples/rtos/workers/event_producer.be")
rtos.spawn("producer", 100)

for i: 1..5
    if rtos.event_wait(PACKET_READY, 500)
        rtos.event_clear(PACKET_READY)
        print("event packet", rtos.get("events_rx", 0))
    end
end

rtos.stop()
