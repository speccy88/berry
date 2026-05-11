import rtos

rtos.channel("counter")
rtos.load_file("/examples/rtos/workers/counter_task.be")
cog = rtos.cog_start("counter_task", 100)
print("worker cog", cog)

for i: 1..5
    print("counter", rtos.get("counter", 500))
end

rtos.stop()
