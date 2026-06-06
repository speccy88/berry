print("P2_SMOKE_BEGIN rtos")

import rtos

def expect_error(f, kind)
    try
        f()
        assert(false, "expected error")
    except .. as e, m
        assert(e == kind)
    end
end

assert(rtos.cog_id() >= 0)
assert(rtos.cog_id() < 8)

rtos.channel("p2_smoke")
rtos.put("p2_smoke", 123)
assert(rtos.get("p2_smoke", 10) == 123)

rtos.event_set(1)
assert(rtos.event_wait(1, 10))
rtos.event_clear(1)
assert(!rtos.event_wait(1, 0))

var timer = rtos.timer_start(5)
rtos.timer_wait(timer)
assert(rtos.timer_expired(timer))

var info = rtos.process_info()
assert(info["backend"] == "single_worker_vm")
assert(info["max_processes"] == 1)
assert(info["closure_launch"] == true)

def local_task()
end
expect_error(def () rtos.newcog(local_task) end, "runtime_error")
rtos.stop()

var captured_task
def make_captured_task()
    var captured = 7
    def inner_task()
        return captured
    end
    captured_task = inner_task
end
make_captured_task()
expect_error(def () rtos.newcog(captured_task) end, "runtime_error")

def p2_smoke_funcobj(delay_ms)
end

rtos.channel("p2_smoke_funcobj")
rtos.load_str("import rtos\n"
    "def p2_smoke_funcobj(delay_ms)\n"
    "    var n = 0\n"
    "    while true\n"
    "        n += 1\n"
    "        rtos.put(\"p2_smoke_funcobj\", n)\n"
    "        rtos.sleep_ms(delay_ms)\n"
    "    end\n"
    "end\n")
var func_cog = rtos.newcog(p2_smoke_funcobj, 10)
assert(func_cog >= 0)
assert(rtos.get("p2_smoke_funcobj", 500) == 1)
assert(rtos.get("p2_smoke_funcobj", 500) == 2)
rtos.stop()

def p2_smoke_run(delay_ms)
end

rtos.channel("p2_smoke_run")
var run_cog = rtos.run("import rtos\n"
    "def p2_smoke_run(delay_ms)\n"
    "    var n = 0\n"
    "    while true\n"
    "        n += 1\n"
    "        rtos.put(\"p2_smoke_run\", n)\n"
    "        rtos.sleep_ms(delay_ms)\n"
    "    end\n"
    "end\n",
    p2_smoke_run, 10)
assert(run_cog >= 0)
assert(rtos.get("p2_smoke_run", 500) == 1)
assert(rtos.get("p2_smoke_run", 500) == 2)
rtos.stop()

rtos.channel("p2_smoke_worker")
rtos.load_file("/tests/p2/workers/smoke_counter.be")
var cog = rtos.newcog("p2_smoke_counter", 10)
assert(cog >= 0)
assert(rtos.get("p2_smoke_worker", 500) == 1)
assert(rtos.get("p2_smoke_worker", 500) == 2)
rtos.stop()

print("P2_SMOKE_PASS rtos")
