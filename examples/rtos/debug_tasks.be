import rtos

rtos.load_file("/examples/rtos/workers/idle_task.be")
rtos.spawn("idle_task", 100)
print(rtos.debug_tasks())
print(rtos.debug_regs(rtos.cog_id()))
rtos.stop()
