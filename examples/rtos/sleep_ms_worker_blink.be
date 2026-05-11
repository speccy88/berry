import rtos

rtos.load_file("/examples/rtos/workers/blink_task.be")
rtos.spawn("blink_task", 56, 250)
rtos.sleep_ms(2000)
rtos.stop()
