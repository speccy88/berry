import rtos

def on_ready()
    rtos.event_set(0x02)
end

print("rtos cog", rtos.cog_id())
print("ticks/ms", rtos.ticks_per_ms())

lock = rtos.new_lock()
assert(rtos.try_lock(lock))
rtos.unlock(lock)
rtos.lock(lock)
rtos.unlock(lock)
rtos.delete_lock(lock)

rtos.channel("smoke")
rtos.put("smoke", 42)
rtos.put("smoke", "ok")
assert(rtos.get("smoke", 10) == 42)
assert(rtos.get("smoke", 10) == "ok")
assert(rtos.get("smoke", 0) == nil)

rtos.irq_enable(0, "on_ready")
rtos.event_set(0x01)
assert(rtos.event_wait(0x01, 100))
assert(rtos.irq_poll() == 1)
assert(rtos.event_wait(0x02, 100))
rtos.event_clear(0x03)
rtos.irq_disable(0)

timer = rtos.timer_start(20)
rtos.timer_wait(timer)
assert(rtos.timer_expired(timer))
rtos.delay_ms(5)
rtos.task_yield()

print(rtos.debug_tasks())
print(rtos.debug_regs(rtos.cog_id()))
print("rtos smoke ok")
