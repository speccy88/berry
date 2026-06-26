print("P2_SMOKE_BEGIN task")

import string
import task
import p2ipc

def has_task_member(name)
    try
        task.(name)
        return true
    except .. as e, m
        return false
    end
end

task.reset()

log = []

if !has_task_member("task_info")
    def native_step(name, state, limit)
        state["runs"] += 1
        log.push(name + str(state["runs"]))
        if state["runs"] >= limit
            return task.done
        end
        return task.again
    end

    a_state = {"runs": 0}
    b_state = {"runs": 0}
    a = task.start(native_step, "a", a_state, 2)
    b = task.start(native_step, "b", b_state, 3)
    assert(a >= 0 && b >= 0 && a != b)
    assert(task.status(a) == "ready")
    var run_count = task.run(8)
    assert(run_count >= 5)
    assert(task.status(a) == "free")
    assert(task.status(b) == "free")
    assert(log == ["a1", "b1", "a2", "b2", "b3"])

    task.reset()
    p_state = {"runs": 0}
    p = task.start(native_step, "p", p_state, 5)
    assert(p >= 0)
    assert(task.pause(p))
    assert(task.status(p) == "paused")
    assert(task.resume(p))
    assert(task.status(p) == "ready")
    assert(task.stop(p))
    assert(task.status(p) == "free")
    assert(!task.stop(p))
    assert(!task.stop(-99))

    task.reset()
    woke = {"event": false, "timeout": false}

    def native_waiter(state)
        if task.woke_by_event("go")
            state["event"] = true
            return task.done
        end
        return task.wait("go", 1000)
    end

    w = task.start(native_waiter, woke)
    assert(task.next() == w)
    assert(task.status(w) == "waiting")
    var listed = task.list()
    assert(size(listed) == 1)
    assert(listed[0]["handle"] == w)
    assert(listed[0]["status"] == "waiting")
    assert(task.signal("go"))
    assert(task.next() == w)
    assert(woke["event"])
    assert(task.status(w) == "free")

    task.reset()

    def native_sleepy(state)
        if task.woke_by_timeout()
            state["timeout"] = true
            return task.done
        end
        return task.sleep(1)
    end

    s = task.start(native_sleepy, woke)
    assert(task.next() == s)
    assert(task.status(s) == "waiting")
    task.run(10, 1)
    assert(woke["timeout"])
    assert(task.status(s) == "free")

    info = task.info()
    assert(info["max_tasks"] == 16)
    assert(info["preemptive"] == false)
    assert(info["stackful"] == false)
    assert(info["backend"] == "p2_native_cooperative")
    assert(info["uses_p2_counter"])
    assert(!info["uses_cog_attention"])
    print(info["backend"], info["uses_p2_counter"], info["uses_cog_attention"])

    print("P2_SMOKE_PASS task")
    return
end

def step(name, limit)
    n = task.task_info(task.current())["runs"]
    log.push(name + str(n))
    if n >= limit
        return task.done
    end
    return task.again
end

a = task.start(step, "a", 2)
b = task.start(step, "b", 3)
assert(a >= 0 && b >= 0 && a != b)
assert(task.status(a) == "ready")
assert(task.run(8) >= 5)
assert(task.status(a) == "free")
assert(task.status(b) == "free")
assert(log == ["a1", "b1", "a2", "b2", "b3"])
bad_start = task.start_result("not_fn")
assert(!bad_start["ok"])
assert(bad_start["error"] == "invalid_function")
too_many_start = task.start_result(step, 1, 2, 3, 4, 5, 6, 7, 8, 9)
assert(!too_many_start["ok"])
assert(too_many_start["error"] == "too_many_args")

task.reset()
started = task.start_result(step, "p", 1)
assert(started["ok"])
p = started["handle"]
paused = task.pause_result(p)
assert(paused["ok"])
assert(paused["status"] == "paused")
assert(task.resume_result(p)["status"] == "ready")
assert(task.chk(p))
assert(task.halt(p))
assert(task.status(p) == "paused")
assert(task.hlt(p))
assert(task.status(p) == "paused")
assert(task.cont(p))
assert(task.status(p) == "ready")
stopped = task.stop_result(p)
assert(stopped["ok"])
assert(stopped["previous_status"] == "ready")
assert(!task.chk(p))
assert(task.id() == -1)
assert(task.stop_result(p)["error"] == "free")
assert(task.stop_result(-99)["error"] == "invalid_handle")

task.reset()
spin_state = {"runs": 0}
def spin_step(state, limit)
    state["runs"] += 1
    if state["runs"] >= limit
        return task.done
    end
    return task.again
end
sp = task.spin(-1, spin_step, spin_state, 2)
assert(sp == 0)
assert(task.chk(sp))
assert(task.tasks().size() == 1)
assert(task.run(4) >= 2)
assert(spin_state["runs"] == 2)
assert(!task.chk(sp))
fixed = task.spin(5, spin_step, spin_state, 3)
assert(fixed == 5)
assert(task.spin(5, spin_step, spin_state, 3) == -1)
assert(task.stop(fixed))
assert(task.spin(99, spin_step, spin_state, 3) == -1)
assert(task.spin(-1, "not_fn") == -1)

task.reset()
woke = {"event": false, "timeout": false}

def waiter(state)
    if task.woke_by_event("go")
        state["event"] = true
        return task.done
    end
    return task.wait("go", 1000)
end

w = task.start(waiter, woke)
assert(task.next() == w)
assert(task.status(w) == "waiting")
assert(task.signal("go"))
assert(task.next() == w)
assert(woke["event"])
assert(task.status(w) == "free")

task.reset()
attention_woke = {"event": false}

def attention_waiter(state)
    if task.woke_by_event("attention")
        state["event"] = true
        return task.done
    end
    return task.wait("attention", 1000)
end

atn = task.start(attention_waiter, attention_woke)
assert(task.next() == atn)
assert(task.status(atn) == "waiting")
import p2
p2.cog.attention(1 << p2.cog.id())
assert(task.next() == atn)
assert(attention_woke["event"])
assert(task.status(atn) == "free")

task.reset()
attention_count = {"value": 0}

def attention_counter(state, limit)
    if task.woke_by_event("attention")
        state["value"] += 1
    end
    if state["value"] >= limit
        return task.done
    end
    return task.wait("attention", 1000)
end

atn = task.start(attention_counter, attention_count, 3)
assert(task.next() == atn)
assert(task.status(atn) == "waiting")
cycle = 0
while cycle < 3
    p2.cog.attention(1 << p2.cog.id())
    assert(task.next() == atn)
    cycle += 1
end
assert(attention_count["value"] == 3)
assert(task.status(atn) == "free")

task.reset()
assert(task.events().size() == 0)
assert(task.signal("alpha"))
assert(task.signal("beta"))
events = task.events()
assert(events.size() == 2)
saw_alpha = false
saw_beta = false
for event : events
    if event == "alpha"
        saw_alpha = true
    elif event == "beta"
        saw_beta = true
    end
end
assert(saw_alpha && saw_beta)
events.clear()
assert(task.events().size() == 2)
assert(task.clear("alpha"))
events = task.events()
assert(events.size() == 1)
assert(events[0] == "beta")
assert(task.clear_all())
assert(task.events().size() == 0)

task.reset()

def sleepy(state)
    if task.woke_by_timeout()
        state["timeout"] = true
        return task.done
    end
    return task.sleep(1)
end

s = task.start(sleepy, woke)
assert(task.next() == s)
assert(task.status(s) == "waiting")
task.run(10, 1)
assert(woke["timeout"])
assert(task.status(s) == "free")

sem = task.Semaphore(1)
assert(sem.take())
assert(!sem.take())
assert(sem.give())
assert(sem.value() == 1)
assert(sem.info()["kind"] == "Semaphore")
sem_result = task.Semaphore(1)
sem_take = sem_result.take_result()
assert(sem_take["ok"])
assert(sem_take["count"] == 0)
sem_empty = sem_result.take_result()
assert(!sem_empty["ok"])
assert(sem_empty["error"] == "unavailable")
sem_give = sem_result.give_result()
assert(sem_give["ok"])
assert(sem_give["count"] == 1)

mutex = task.Mutex()
assert(mutex.lock())
assert(mutex.owner() == -1)
assert(!mutex.lock())
assert(mutex.unlock())
assert(!mutex.is_locked())
mutex_result = task.Mutex()
mutex_lock = mutex_result.lock_result()
assert(mutex_lock["ok"])
assert(mutex_lock["locked"])
mutex_busy = mutex_result.lock_result()
assert(!mutex_busy["ok"])
assert(mutex_busy["error"] == "busy")
mutex_unlock = mutex_result.unlock_result()
assert(mutex_unlock["ok"])
assert(!mutex_unlock["locked"])
mutex_not_locked = mutex_result.unlock_result()
assert(!mutex_not_locked["ok"])
assert(mutex_not_locked["error"] == "not_locked")

q = task.Queue(2)
assert(q.put("a"))
assert(q.put("b"))
assert(!q.put("c"))
assert(q.get() == "a")
assert(q.get() == "b")
assert(q.get() == nil)
q_full_result_queue = task.Queue(1)
assert(q_full_result_queue.put("x"))
q_full_result = q_full_result_queue.put_result("y")
assert(!q_full_result["ok"])
assert(q_full_result["error"] == "full")
assert(q_full_result["size"] == 1)
assert(q_full_result["free"] == 0)
q_nil = task.Queue(1)
assert(q_nil.put_result(nil)["ok"])
q_nil_get = q_nil.get_result()
assert(q_nil_get["ok"])
assert(q_nil_get["value"] == nil)
assert(q_nil_get["size"] == 0)
assert(q_nil_get["free"] == 1)
q_empty_get = q_nil.get_result()
assert(!q_empty_get["ok"])
assert(q_empty_get["error"] == "empty")

flags = task.EventFlags()
assert(flags.set(0x03) == 0x03)
assert(flags.ready(0x03, "all"))
assert(flags.clear(0x01) == 0x02)
assert(!flags.ready(0x03, "all"))
flags_set = flags.set_result(0x04)
assert(flags_set["ok"])
assert(flags_set["value"] == 0x06)
flags_set_bad = flags.set_result("bad")
assert(!flags_set_bad["ok"])
assert(flags_set_bad["error"] == "invalid_mask")
flags_clear = flags.clear_result(0x04)
assert(flags_clear["ok"])
assert(flags_clear["value"] == 0x02)
flags_clear_bad = flags.clear_result("bad")
assert(!flags_clear_bad["ok"])
assert(flags_clear_bad["error"] == "invalid_mask")
flags_ready = flags.ready_result(0x02, "any")
assert(flags_ready["ok"])
assert(flags_ready["ready"])
flags_not_ready = flags.ready_result(0x03, "all")
assert(!flags_not_ready["ok"])
assert(flags_not_ready["error"] == "not_ready")
flags_bad_mask = flags.ready_result("bad", "all")
assert(!flags_bad_mask["ok"])
assert(flags_bad_mask["error"] == "invalid_mask")

timer = task.Timer(1, false)
timer_remaining = timer.remaining_result()
assert(timer_remaining["ok"])
assert(timer_remaining["remaining_ms"] >= 0)
assert(timer.info()["remaining_ms"] >= 0)
timer_not_expired = timer.expired_result()
assert(!timer_not_expired["ok"])
assert(timer_not_expired["error"] == "not_expired")
assert(timer.cancel())
timer_cancel = timer.cancel_result()
assert(timer_cancel["ok"])
assert(!timer_cancel["active"])
timer_inactive_remaining = timer.remaining_result()
assert(!timer_inactive_remaining["ok"])
assert(timer_inactive_remaining["error"] == "inactive")
assert(timer_inactive_remaining["remaining_ms"] == 0)
assert(!timer.expired())
assert(timer.restart())
timer_restart = timer.restart_result()
assert(timer_restart["ok"])
assert(timer_restart["active"])
assert(timer.remaining() >= 0)
timer_zero = task.Timer(0, false)
timer_zero_expired = timer_zero.expired_result()
assert(timer_zero_expired["ok"])
assert(timer_zero_expired["expired"])
assert(!timer_zero_expired["active"])

info = task.info()
assert(info["max_tasks"] == 32)
assert(info["preemptive"] == false)
assert(info["stackful"] == false)
caps = task.capabilities()
assert(caps["cooperative"])
assert(caps["scheduler_policy"] == "current_vm_callback_step")
assert(string.find(caps["unsupported_reason"], "independent stacks") >= 0)
assert(caps["self_test_result"])
assert(caps["self_test_policy"] == "bounded_current_vm_cleanup_diagnostic")
assert(!caps["preemptive"])
assert(!caps["stackful"])
assert(caps["current_vm"])
assert(!caps["independent_stacks"])
assert(caps["events"])
assert(caps["event_diagnostics"])
assert(caps["clear_all_events"])
assert(caps["result_diagnostics"])
assert(caps["wait_descriptors"])
assert(caps["contract"])
assert(caps["audit"])
assert(caps["spin"])
assert(caps["spin2_lifecycle_names"])
assert(caps["semaphore"])
assert(caps["mutex"])
assert(caps["queue"])
assert(caps["event_flags"])
assert(caps["timer"])
assert(caps["max_tasks"] == 32)
assert(caps["attention_policy"] == "native_attention_event_current_vm_only")
assert(caps["bounded_attention_wait"])
assert(!caps["cross_cog_attention_wakeup"])
caps["cooperative"] = false
assert(task.capabilities()["cooperative"])
assert(task.capability("cooperative"))
assert(task.capability("scheduler_policy") == "current_vm_callback_step")
assert(task.capability("contract"))
assert(task.capability("self_test_result"))
assert(task.capability("self_test_policy") == "bounded_current_vm_cleanup_diagnostic")
assert(task.capability("preemptive") == false)
assert(task.capability("max_tasks") == 32)
assert(task.capability("attention_policy") == "native_attention_event_current_vm_only")
assert(task.capability("missing") == nil)
assert(task.capability(nil) == nil)
assert(type(task.attention_policy) == "function")
assert(type(task.required_capability_keys) == "function")
assert(type(task.required_attention_policy_keys) == "function")
assert(type(task.required_contract_keys) == "function")
assert(type(task.required_primitive_capability_keys) == "function")
required_caps = task.required_capability_keys()
assert(required_caps.find("scheduler_policy") >= 0)
assert(required_caps.find("spin2_lifecycle_names") >= 0)
assert(required_caps.find("self_test_result") >= 0)
assert(required_caps.find("attention_policy") >= 0)
assert(required_caps.find("bounded_attention_wait") >= 0)
assert(required_caps.find("cross_cog_attention_wakeup") >= 0)
required_caps.push("mutated")
assert(task.required_capability_keys().find("mutated") == nil)
required_attention_policy = task.required_attention_policy_keys()
assert(required_attention_policy.find("policy") >= 0)
assert(required_attention_policy.find("bounded_attention_wait") >= 0)
assert(required_attention_policy.find("cross_cog_wakeup") >= 0)
required_attention_policy.push("mutated")
assert(task.required_attention_policy_keys().find("mutated") == nil)
primitive_caps = task.primitive_capabilities()
assert(primitive_caps["semaphore_take_result"])
assert(primitive_caps["mutex_lock_result"])
assert(primitive_caps["queue_get_result"])
assert(primitive_caps["p2ipc_channel_wait"])
assert(primitive_caps["p2ipc_mailbox_wait"])
assert(primitive_caps["event_flags_set_result"])
assert(primitive_caps["event_flags_ready_result"])
assert(primitive_caps["timer_restart_result"])
assert(primitive_caps["timer_remaining_result"])
primitive_caps["timer_restart_result"] = false
assert(task.primitive_capabilities()["timer_restart_result"])
assert(task.primitive_capability("semaphore_take_result"))
assert(task.primitive_capability("timer_restart_result"))
assert(task.primitive_capability("timer_remaining_result"))
assert(task.primitive_capability("missing") == nil)
assert(task.primitive_capability(nil) == nil)
required_primitive_caps = task.required_primitive_capability_keys()
assert(required_primitive_caps.find("queue_get_result") >= 0)
assert(required_primitive_caps.find("p2ipc_channel_wait") >= 0)
assert(required_primitive_caps.find("p2ipc_mailbox_wait") >= 0)
assert(required_primitive_caps.find("timer_remaining_result") >= 0)
required_primitive_caps.push("mutated")
assert(task.required_primitive_capability_keys().find("mutated") == nil)
model = task.execution_model()
assert(model["model"] == "cooperative_step")
assert(model["backend"] == "p2_native_cooperative")
assert(model["current_vm"])
assert(model["cooperative"])
assert(model["callback_step_scheduler"])
assert(model["scheduler_policy"] == "current_vm_callback_step")
assert(string.find(model["unsupported_reason"], "Spin2") >= 0)
assert(!model["preemptive"])
assert(!model["stackful"])
assert(!model["independent_stacks"])
assert(!model["independent_vm_per_task"])
assert(model["spin2_compatible_names"])
assert(!model["true_spin2_task_switching"])
assert(model["max_tasks"] == 32)
assert(model["bounded_attention_wait"])
assert(!model["cross_cog_attention_wakeup"])
model["callback_step_scheduler"] = false
assert(task.execution_model()["callback_step_scheduler"])
assert(type(task.execution_model_value) == "function")
assert(task.execution_model_value("model") == "cooperative_step")
assert(task.execution_model_value("backend") == "p2_native_cooperative")
assert(task.execution_model_value("current_vm"))
assert(task.execution_model_value("preemptive") == false)
assert(task.execution_model_value("scheduler_policy") == "current_vm_callback_step")
assert(task.execution_model_value("bounded_attention_wait"))
assert(task.execution_model_value("cross_cog_attention_wakeup") == false)
assert(task.execution_model_value("missing") == nil)
assert(task.execution_model_value(nil) == nil)
assert(type(task.contract) == "function")
contract = task.contract()
assert(contract["ok"])
assert(contract["model"] == "cooperative_step")
assert(contract["scheduler_policy"] == "current_vm_callback_step")
assert(contract["current_vm"])
assert(contract["cooperative"])
assert(contract["callback_step_scheduler"])
assert(!contract["preemptive"])
assert(!contract["stackful"])
assert(!contract["independent_stacks"])
assert(!contract["independent_vm_per_task"])
assert(!contract["true_spin2_task_switching"])
assert(contract["max_tasks"] == 32)
assert(contract["spin2_compatible_names"])
assert(contract["wait_descriptors"])
assert(contract["result_diagnostics"])
assert(contract["sharing_policy"] == "current_vm_objects_only")
assert(!contract["cross_vm_serialization"])
assert(!contract["cross_cog_wakeup"])
assert(contract["attention_policy"] == "native_attention_event_current_vm_only")
assert(contract["bounded_attention_wait"])
assert(!contract["cross_cog_attention_wakeup"])
assert(type(task.contract_value) == "function")
assert(task.contract_value("model") == "cooperative_step")
assert(task.contract_value("current_vm"))
assert(task.contract_value("preemptive") == false)
assert(task.contract_value("scheduler_policy") == "current_vm_callback_step")
assert(task.contract_value("attention_policy") == "native_attention_event_current_vm_only")
assert(task.contract_value("cross_cog_wakeup") == false)
assert(task.contract_value("missing") == nil)
assert(task.contract_value(nil) == nil)
required_contract = task.required_contract_keys()
assert(required_contract.find("sharing_policy") >= 0)
assert(required_contract.find("cross_cog_wakeup") >= 0)
assert(required_contract.find("attention_policy") >= 0)
assert(required_contract.find("bounded_attention_wait") >= 0)
assert(required_contract.find("cross_cog_attention_wakeup") >= 0)
required_contract.push("mutated")
assert(task.required_contract_keys().find("mutated") == nil)
assert(type(task.audit) == "function")
assert(type(task.audit_problems) == "function")
assert(type(task.audit_ok) == "function")
audit = task.audit()
assert(audit["ok"])
assert(audit["problem_count"] == 0)
assert(audit["problems"].size() == 0)
assert(audit["model"] == "cooperative_step")
assert(audit["scheduler_policy"] == "current_vm_callback_step")
assert(audit["cooperative"])
assert(!audit["preemptive"])
assert(!audit["stackful"])
assert(audit["bounded_attention_wait"])
assert(!audit["cross_cog_attention_wakeup"])
assert(audit["attention_policy"]["policy"] == "native_attention_event_current_vm_only")
assert(audit["attention_policy"]["bounded_attention_wait"])
assert(!audit["attention_policy"]["cross_cog_wakeup"])
assert(audit["contract"]["scheduler_policy"] == "current_vm_callback_step")
assert(audit["contract"]["sharing_policy"] == "current_vm_objects_only")
assert(audit["missing_capability_keys"].size() == 0)
assert(audit["missing_attention_policy_keys"].size() == 0)
assert(audit["missing_primitive_capability_keys"].size() == 0)
assert(audit["missing_contract_keys"].size() == 0)
assert(audit["max_tasks"] == 32)
assert(audit["primitive_families"])
audit["problems"].push("mutated")
assert(task.audit()["problems"].size() == 0)
audit_problems = task.audit_problems()
assert(audit_problems.size() == 0)
audit_problems.push("mutated")
assert(task.audit_problems().size() == 0)
assert(task.audit_ok())
attention_policy = task.attention_policy()
assert(attention_policy["policy"] == "native_attention_event_current_vm_only")
assert(attention_policy["event"] == "attention")
assert(attention_policy["signal_uses_cog_attention"])
assert(attention_policy["poll_uses_cog_attention"])
assert(attention_policy["bounded_attention_wait"])
assert(attention_policy["wait_helper"] == "p2.cog.wait_attention_result")
assert(!attention_policy["cross_cog_wakeup"])
assert(attention_policy["current_vm_only"])
assert(type(task.attention_policy_value) == "function")
assert(task.attention_policy_value("policy") == "native_attention_event_current_vm_only")
assert(task.attention_policy_value("event") == "attention")
assert(task.attention_policy_value("signal_uses_cog_attention"))
assert(task.attention_policy_value("poll_uses_cog_attention"))
assert(task.attention_policy_value("bounded_attention_wait"))
assert(task.attention_policy_value("cross_cog_wakeup") == false)
assert(task.attention_policy_value("current_vm_only"))
assert(task.attention_policy_value("missing") == nil)
assert(task.attention_policy_value(nil) == nil)

default_queue_wait = task.wait(task.Queue(1), 25)
assert(default_queue_wait["_task_wait"] == "queue_get")
assert(type(default_queue_wait["deadline"]) == "int")
mode_queue_wait = task.wait(task.Queue(1), "put", 25)
assert(mode_queue_wait["_task_wait"] == "queue_put")
assert(type(mode_queue_wait["deadline"]) == "int")
default_channel_wait = task.wait(p2ipc.channel.new(1), 25)
assert(default_channel_wait["_task_wait"] == "p2ipc_channel_recv")
assert(type(default_channel_wait["deadline"]) == "int")
mode_channel_wait = task.wait(p2ipc.channel.new(1), "send", 25)
assert(mode_channel_wait["_task_wait"] == "p2ipc_channel_send")
assert(type(mode_channel_wait["deadline"]) == "int")
default_mailbox_wait = task.wait(p2ipc.mailbox.new(), 25)
assert(default_mailbox_wait["_task_wait"] == "p2ipc_mailbox_get")
assert(type(default_mailbox_wait["deadline"]) == "int")
mode_mailbox_wait = task.wait(p2ipc.mailbox.new(), "put", 25)
assert(mode_mailbox_wait["_task_wait"] == "p2ipc_mailbox_put")
assert(type(mode_mailbox_wait["deadline"]) == "int")

task.reset()
ipc_ch = p2ipc.channel.new(1)
ipc_recv_state = {"value": nil}
def ipc_channel_recv_waiter(state, ch)
    res = ch.recv_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(ch, "recv", 1000)
end
ipc_recv_h = task.start(ipc_channel_recv_waiter, ipc_recv_state, ipc_ch)
assert(task.next() == ipc_recv_h)
assert(task.status(ipc_recv_h) == "waiting")
assert(ipc_ch.send_result("ipc-ready")["ok"])
assert(task.next() == ipc_recv_h)
assert(ipc_recv_state["value"] == "ipc-ready")
assert(task.status(ipc_recv_h) == "free")

task.reset()
ipc_full_ch = p2ipc.channel.new(1)
assert(ipc_full_ch.send_result("held")["ok"])
ipc_send_state = {"sent": false}
def ipc_channel_send_waiter(state, ch)
    res = ch.send_result("later")
    if res["sent"]
        state["sent"] = true
        return task.done
    end
    return task.wait(ch, "send", 1000)
end
ipc_send_h = task.start(ipc_channel_send_waiter, ipc_send_state, ipc_full_ch)
assert(task.next() == ipc_send_h)
assert(task.status(ipc_send_h) == "waiting")
assert(ipc_full_ch.recv_result()["value"] == "held")
assert(task.next() == ipc_send_h)
assert(ipc_send_state["sent"])
assert(ipc_full_ch.recv_result()["value"] == "later")
assert(task.status(ipc_send_h) == "free")

task.reset()
ipc_mb = p2ipc.mailbox.new()
ipc_mb_get_state = {"value": nil}
def ipc_mailbox_get_waiter(state, mb)
    res = mb.get_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(mb, "get", 1000)
end
ipc_mb_get_h = task.start(ipc_mailbox_get_waiter, ipc_mb_get_state, ipc_mb)
assert(task.next() == ipc_mb_get_h)
assert(task.status(ipc_mb_get_h) == "waiting")
assert(ipc_mb.put_result("mail-ready")["ok"])
assert(task.next() == ipc_mb_get_h)
assert(ipc_mb_get_state["value"] == "mail-ready")
assert(task.status(ipc_mb_get_h) == "free")

task.reset()
ipc_full_mb = p2ipc.mailbox.new()
assert(ipc_full_mb.put_result("held")["ok"])
ipc_mb_put_state = {"stored": false}
def ipc_mailbox_put_waiter(state, mb)
    res = mb.put_result("later")
    if res["stored"]
        state["stored"] = true
        return task.done
    end
    return task.wait(mb, "put", 1000)
end
ipc_mb_put_h = task.start(ipc_mailbox_put_waiter, ipc_mb_put_state, ipc_full_mb)
assert(task.next() == ipc_mb_put_h)
assert(task.status(ipc_mb_put_h) == "waiting")
assert(ipc_full_mb.get_result()["value"] == "held")
assert(task.next() == ipc_mb_put_h)
assert(ipc_mb_put_state["stored"])
assert(ipc_full_mb.get_result()["value"] == "later")
assert(task.status(ipc_mb_put_h) == "free")

task_self_test = task.self_test_result(2)
assert(task_self_test["ok"])
assert(task_self_test["iterations"] == 2)
assert(task_self_test["failure_count"] == 0)
assert(task_self_test["failures"].size() == 0)
assert(task_self_test["checks"] > 0)
assert(task_self_test["policy"] == "bounded_current_vm_cleanup_diagnostic")
assert(task_self_test["cleanup_reset"])
assert(task_self_test["active_after"] == 0)
assert(task_self_test["events_after"] == 0)
assert(task.info()["active"] == 0)
assert(task.info()["events"] == 0)
invalid_self_test = task.self_test_result("bad")
assert(!invalid_self_test["ok"])
assert(invalid_self_test["error"] == "invalid_iterations")
assert(invalid_self_test["policy"] == "bounded_current_vm_cleanup_diagnostic")
print(info["backend"], info["uses_p2_counter"], info["uses_cog_attention"])

print("P2_SMOKE_PASS task")
