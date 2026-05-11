import rtos

rtos.channel("heartbeat")
rtos.load_file("/examples/rtos/workers/heartbeat.be")
rtos.spawn("heartbeat", 250)

for i: 1..4
    print("heartbeat", rtos.get("heartbeat", 500))
end

rtos.stop()
