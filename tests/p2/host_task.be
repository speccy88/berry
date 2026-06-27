import introspect
import string

var task = run_file("modules/task.be")
var p2 = module("p2")
p2.lock = nil
introspect.setmodule("p2", p2)
var p2ipc = run_file("modules/p2ipc.be")

task.reset()

var log = []

def step(name, limit)
    var n = task.task_info(task.current())["runs"]
    log.push(name + str(n))
    return n >= limit ? task.done : task.again
end

var a = task.start(step, "a", 2)
var b = task.start(step, "b", 3)
assert(a >= 0 && b >= 0 && a != b)
assert(task.status(a) == "ready")
assert(task.run(8) >= 5)
assert(task.status(a) == "free")
assert(task.status(b) == "free")
assert(log == ["a1", "b1", "a2", "b2", "b3"])

task.reset()
var idle_step = task.next_result()
assert(!idle_step["ok"])
assert(!idle_step["ran"])
assert(idle_step["handle"] == -1)
assert(idle_step["error"] == "no_ready_task")
assert(idle_step["live_before"] == 0)
assert(idle_step["live_after"] == 0)
var result_task = task.start(step, "r", 2)
var first_step = task.next_result()
assert(first_step["ok"])
assert(first_step["ran"])
assert(first_step["handle"] == result_task)
assert(first_step["status"] == "ready")
assert(first_step["live_before"] == 1)
assert(first_step["live_after"] == 1)
assert(first_step["runs"] == 1)
var run_summary = task.run_result(4, 0)
assert(run_summary["ok"])
assert(run_summary["steps"] >= 1)
assert(run_summary["live_before"] == 1)
assert(run_summary["live_after"] == 0)
assert(run_summary["complete"])
task.reset()
var invalid_start = task.start_result("not_fn")
assert(!invalid_start["ok"])
assert(invalid_start["handle"] == -1)
assert(invalid_start["error"] == "invalid_function")
var too_many_start = task.start_result(step, 1, 2, 3, 4, 5, 6, 7, 8, 9)
assert(!too_many_start["ok"])
assert(too_many_start["error"] == "too_many_args")

task.reset()
var woke = {"value": false}

def waiter(state)
    if task.woke_by_event("go")
        state["value"] = true
        return task.done
    end
    return task.wait("go", 1000)
end

var w = task.start(waiter, woke)
assert(task.next() == w)
assert(task.status(w) == "waiting")
assert(task.signal("go"))
assert(task.next() == w)
assert(woke["value"])
assert(task.status(w) == "free")

task.reset()
var attention_woke = {"value": false}

def attention_waiter(state)
    if task.woke_by_event("attention")
        state["value"] = true
        return task.done
    end
    return task.wait("attention", 1000)
end

var atn = task.start(attention_waiter, attention_woke)
assert(task.next() == atn)
assert(task.status(atn) == "waiting")
assert(task.signal("attention"))
assert(task.next() == atn)
assert(attention_woke["value"])
assert(task.status(atn) == "free")

task.reset()
var attention_count = {"value": 0}

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
var cycle = 0
while cycle < 3
    assert(task.signal("attention"))
    assert(task.next() == atn)
    cycle += 1
end
assert(attention_count["value"] == 3)
assert(task.status(atn) == "free")

task.reset()
assert(task.events().size() == 0)
assert(task.signal("alpha"))
assert(task.signal("beta"))
var events = task.events()
assert(events.size() == 2)
var saw_alpha = false
var saw_beta = false
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

var sem = task.Semaphore(1)
assert(sem.take())
assert(!sem.take())
assert(sem.give())
assert(sem.value() == 1)
assert(sem.info()["kind"] == "Semaphore")
var sem_result = task.Semaphore(1)
var sem_take = sem_result.take_result()
assert(sem_take["ok"])
assert(sem_take["count"] == 0)
assert(sem_take["error"] == nil)
var sem_empty = sem_result.take_result()
assert(!sem_empty["ok"])
assert(sem_empty["count"] == 0)
assert(sem_empty["error"] == "unavailable")
var sem_give = sem_result.give_result()
assert(sem_give["ok"])
assert(sem_give["count"] == 1)
var sem_invalid = task.Semaphore("bad")
assert(sem_invalid.value() == 0)
assert(!sem_invalid.take())
assert(sem_invalid.give())
assert(sem_invalid.value() == 1)
var sem_negative = task.Semaphore(-3)
assert(sem_negative.value() == 0)
assert(!sem_negative.take())

var mutex = task.Mutex()
assert(mutex.lock())
assert(mutex.owner() == -1)
assert(!mutex.lock())
assert(mutex.unlock())
assert(!mutex.is_locked())
var mutex_result = task.Mutex()
var mutex_lock = mutex_result.lock_result()
assert(mutex_lock["ok"])
assert(mutex_lock["locked"])
assert(mutex_lock["owner"] == -1)
var mutex_busy = mutex_result.lock_result()
assert(!mutex_busy["ok"])
assert(mutex_busy["error"] == "busy")
assert(mutex_busy["locked"])
var mutex_unlock = mutex_result.unlock_result()
assert(mutex_unlock["ok"])
assert(!mutex_unlock["locked"])
assert(mutex_unlock["owner"] == -1)
assert(mutex_unlock["previous_owner"] == -1)
var mutex_not_locked = mutex_result.unlock_result()
assert(!mutex_not_locked["ok"])
assert(mutex_not_locked["error"] == "not_locked")

var q = task.Queue(2)
assert(q.put("a"))
assert(q.put("b"))
assert(!q.put("c"))
assert(q.get() == "a")
assert(q.get() == "b")
assert(q.get() == nil)
var q_full_result_queue = task.Queue(1)
assert(q_full_result_queue.put("x"))
var q_full_result = q_full_result_queue.put_result("y")
assert(!q_full_result["ok"])
assert(q_full_result["error"] == "full")
assert(q_full_result["value"] == "y")
assert(q_full_result["size"] == 1)
assert(q_full_result["free"] == 0)
var q_nil = task.Queue(1)
var q_nil_put = q_nil.put_result(nil)
assert(q_nil_put["ok"])
assert(q_nil_put["size"] == 1)
assert(q_nil_put["free"] == 0)
var q_nil_get = q_nil.get_result()
assert(q_nil_get["ok"])
assert(q_nil_get["value"] == nil)
assert(q_nil_get["size"] == 0)
assert(q_nil_get["free"] == 1)
var q_empty_get = q_nil.get_result()
assert(!q_empty_get["ok"])
assert(q_empty_get["error"] == "empty")
assert(q_empty_get["size"] == 0)
assert(q_empty_get["free"] == 1)
var q_zero = task.Queue(0)
assert(q_zero.size() == 0)
assert(q_zero.free() == 0)
assert(!q_zero.put("x"))
assert(q_zero.get() == nil)
var q_invalid = task.Queue("bad")
assert(q_invalid.size() == 0)
assert(q_invalid.free() == 0)
assert(!q_invalid.put("x"))
var q_negative = task.Queue(-4)
assert(q_negative.size() == 0)
assert(q_negative.free() == 0)
assert(!q_negative.put("x"))

var flags = task.EventFlags()
assert(flags.set(0x03) == 0x03)
assert(flags.ready(0x03, "all"))
assert(flags.clear(0x01) == 0x02)
assert(!flags.ready(0x03, "all"))
var flags_invalid = task.EventFlags("bad")
assert(flags_invalid.value() == 0)
assert(flags_invalid.set("bad") == 0)
assert(flags_invalid.clear("bad") == 0)
assert(!flags_invalid.ready("bad", "all"))
assert(flags_invalid.set(0x02) == 0x02)
assert(flags_invalid.ready(0x02, "any"))
var flags_set = flags_invalid.set_result(0x04)
assert(flags_set["ok"])
assert(flags_set["value"] == 0x06)
assert(flags_set["mask"] == 0x04)
var flags_set_bad = flags_invalid.set_result("bad")
assert(!flags_set_bad["ok"])
assert(flags_set_bad["error"] == "invalid_mask")
assert(flags_set_bad["value"] == 0x06)
var flags_clear = flags_invalid.clear_result(0x04)
assert(flags_clear["ok"])
assert(flags_clear["value"] == 0x02)
var flags_clear_bad = flags_invalid.clear_result("bad")
assert(!flags_clear_bad["ok"])
assert(flags_clear_bad["error"] == "invalid_mask")
assert(flags_clear_bad["value"] == 0x02)
var flags_ready = flags_invalid.ready_result(0x02, "any")
assert(flags_ready["ok"])
assert(flags_ready["ready"])
assert(flags_ready["mode"] == "any")
assert(flags_ready["value"] == 0x02)
var flags_not_ready = flags_invalid.ready_result(0x03, "all")
assert(!flags_not_ready["ok"])
assert(!flags_not_ready["ready"])
assert(flags_not_ready["error"] == "not_ready")
assert(flags_not_ready["mode"] == "all")
var flags_bad_mask = flags_invalid.ready_result("bad", "all")
assert(!flags_bad_mask["ok"])
assert(flags_bad_mask["error"] == "invalid_mask")

var timer = task.Timer(10, false)
assert(!timer.expired())
var timer_remaining = timer.remaining_result()
assert(timer_remaining["ok"])
assert(timer_remaining["active"])
assert(timer_remaining["remaining_ms"] >= 0)
assert(timer_remaining["remaining_ms"] <= 10)
assert(timer.info()["remaining_ms"] >= 0)
var timer_not_expired = timer.expired_result()
assert(!timer_not_expired["ok"])
assert(timer_not_expired["error"] == "not_expired")
assert(timer.cancel())
var timer_cancel = timer.cancel_result()
assert(timer_cancel["ok"])
assert(!timer_cancel["active"])
assert(!timer_cancel["was_active"])
var timer_inactive_remaining = timer.remaining_result()
assert(!timer_inactive_remaining["ok"])
assert(timer_inactive_remaining["error"] == "inactive")
assert(timer_inactive_remaining["remaining_ms"] == 0)
assert(!timer.expired())
assert(timer.restart())
var timer_restart = timer.restart_result()
assert(timer_restart["ok"])
assert(timer_restart["active"])
assert(timer_restart["period_ms"] == 10)
assert(timer.remaining() >= 0)
var timer_invalid = task.Timer("bad", false)
assert(timer_invalid.info()["period_ms"] == 0)
var timer_invalid_expired = timer_invalid.expired_result()
assert(timer_invalid_expired["ok"])
assert(timer_invalid_expired["expired"])
assert(!timer_invalid_expired["active"])
assert(!timer_invalid.expired())
var timer_negative = task.Timer(-10, true)
assert(timer_negative.info()["period_ms"] == 0)
var timer_repeat_expired = timer_negative.expired_result()
assert(timer_repeat_expired["ok"])
assert(timer_repeat_expired["active"])

var info = task.info()
assert(info["max_tasks"] == 32)
assert(info["preemptive"] == false)
assert(info["stackful"] == false)
var caps = task.capabilities()
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
assert(caps["reset_result"])
assert(caps["result_diagnostics"])
assert(caps["task_lifecycle_result"])
assert(caps["scheduler_step_result"])
assert(caps["scheduler_run_result"])
assert(caps["wait_readiness_result"])
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
assert(!caps["bounded_attention_wait"])
assert(!caps["cross_cog_attention_wakeup"])
caps["cooperative"] = false
assert(task.capabilities()["cooperative"])
assert(task.capability("cooperative"))
assert(task.capability("scheduler_policy") == "current_vm_callback_step")
assert(task.capability("contract"))
assert(task.capability("self_test_result"))
assert(task.capability("self_test_policy") == "bounded_current_vm_cleanup_diagnostic")
assert(task.capability("reset_result"))
assert(task.capability("task_lifecycle_result"))
assert(task.capability("scheduler_step_result"))
assert(task.capability("scheduler_run_result"))
assert(task.capability("wait_readiness_result"))
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
var required_caps = task.required_capability_keys()
assert(required_caps.find("scheduler_policy") >= 0)
assert(required_caps.find("spin2_lifecycle_names") >= 0)
assert(required_caps.find("self_test_result") >= 0)
assert(required_caps.find("reset_result") >= 0)
assert(required_caps.find("task_lifecycle_result") >= 0)
assert(required_caps.find("scheduler_step_result") >= 0)
assert(required_caps.find("scheduler_run_result") >= 0)
assert(required_caps.find("wait_readiness_result") >= 0)
assert(required_caps.find("attention_policy") >= 0)
assert(required_caps.find("bounded_attention_wait") >= 0)
assert(required_caps.find("cross_cog_attention_wakeup") >= 0)
required_caps.push("mutated")
assert(task.required_capability_keys().find("mutated") == nil)
var required_attention_policy = task.required_attention_policy_keys()
assert(required_attention_policy.find("policy") >= 0)
assert(required_attention_policy.find("bounded_attention_wait") >= 0)
assert(required_attention_policy.find("cross_cog_wakeup") >= 0)
required_attention_policy.push("mutated")
assert(task.required_attention_policy_keys().find("mutated") == nil)
var primitive_caps = task.primitive_capabilities()
assert(primitive_caps["semaphore_take_result"])
assert(primitive_caps["mutex_lock_result"])
assert(primitive_caps["queue_get_result"])
assert(primitive_caps["p2ipc_channel_wait"])
assert(primitive_caps["p2ipc_mailbox_wait"])
assert(primitive_caps["p2ipc_closed_wait_wakeup"])
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
var required_primitive_caps = task.required_primitive_capability_keys()
assert(required_primitive_caps.find("queue_get_result") >= 0)
assert(required_primitive_caps.find("p2ipc_channel_wait") >= 0)
assert(required_primitive_caps.find("p2ipc_mailbox_wait") >= 0)
assert(required_primitive_caps.find("p2ipc_closed_wait_wakeup") >= 0)
assert(required_primitive_caps.find("timer_remaining_result") >= 0)
required_primitive_caps.push("mutated")
assert(task.required_primitive_capability_keys().find("mutated") == nil)
var model = task.execution_model()
assert(model["model"] == "cooperative_step")
assert(model["backend"] == "host_cooperative")
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
assert(!model["bounded_attention_wait"])
assert(!model["cross_cog_attention_wakeup"])
model["callback_step_scheduler"] = false
assert(task.execution_model()["callback_step_scheduler"])
assert(type(task.execution_model_value) == "function")
assert(task.execution_model_value("model") == "cooperative_step")
assert(task.execution_model_value("backend") == "host_cooperative")
assert(task.execution_model_value("current_vm"))
assert(task.execution_model_value("preemptive") == false)
assert(task.execution_model_value("scheduler_policy") == "current_vm_callback_step")
assert(task.execution_model_value("bounded_attention_wait") == false)
assert(task.execution_model_value("cross_cog_attention_wakeup") == false)
assert(task.execution_model_value("missing") == nil)
assert(task.execution_model_value(nil) == nil)
assert(type(task.contract) == "function")
var contract = task.contract()
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
assert(contract["reset_result"])
assert(contract["result_diagnostics"])
assert(contract["task_lifecycle_result"])
assert(contract["scheduler_step_result"])
assert(contract["scheduler_run_result"])
assert(contract["wait_readiness_result"])
assert(contract["sharing_policy"] == "current_vm_objects_only")
assert(!contract["cross_vm_serialization"])
assert(!contract["cross_cog_wakeup"])
assert(contract["attention_policy"] == "native_attention_event_current_vm_only")
assert(!contract["bounded_attention_wait"])
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
var required_contract = task.required_contract_keys()
assert(required_contract.find("sharing_policy") >= 0)
assert(required_contract.find("reset_result") >= 0)
assert(required_contract.find("task_lifecycle_result") >= 0)
assert(required_contract.find("scheduler_step_result") >= 0)
assert(required_contract.find("scheduler_run_result") >= 0)
assert(required_contract.find("wait_readiness_result") >= 0)
assert(required_contract.find("cross_cog_wakeup") >= 0)
assert(required_contract.find("attention_policy") >= 0)
assert(required_contract.find("bounded_attention_wait") >= 0)
assert(required_contract.find("cross_cog_attention_wakeup") >= 0)
required_contract.push("mutated")
assert(task.required_contract_keys().find("mutated") == nil)
var saw_queue_family = false
for family : contract["primitive_families"]
    if family == "Queue"
        saw_queue_family = true
    end
end
assert(saw_queue_family)
contract["primitive_families"].push("mutated")
var saw_mutated_family = false
for family : task.contract()["primitive_families"]
    if family == "mutated"
        saw_mutated_family = true
    end
end
assert(!saw_mutated_family)
assert(type(task.audit) == "function")
assert(type(task.audit_problems) == "function")
assert(type(task.audit_ok) == "function")
var audit = task.audit()
assert(audit["ok"])
assert(audit["problem_count"] == 0)
assert(audit["problems"].size() == 0)
assert(audit["model"] == "cooperative_step")
assert(audit["scheduler_policy"] == "current_vm_callback_step")
assert(audit["cooperative"])
assert(!audit["preemptive"])
assert(!audit["stackful"])
assert(!audit["bounded_attention_wait"])
assert(!audit["cross_cog_attention_wakeup"])
assert(audit["contract"]["reset_result"])
assert(audit["task_lifecycle_result"])
assert(audit["attention_policy"]["policy"] == "native_attention_event_current_vm_only")
assert(!audit["attention_policy"]["bounded_attention_wait"])
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
var audit_problems = task.audit_problems()
assert(audit_problems.size() == 0)
audit_problems.push("mutated")
assert(task.audit_problems().size() == 0)
assert(task.audit_ok())
var attention_policy = task.attention_policy()
assert(attention_policy["policy"] == "native_attention_event_current_vm_only")
assert(attention_policy["event"] == "attention")
assert(!attention_policy["signal_uses_cog_attention"])
assert(!attention_policy["poll_uses_cog_attention"])
assert(!attention_policy["bounded_attention_wait"])
assert(attention_policy["wait_helper"] == "p2.cog.wait_attention_result")
assert(!attention_policy["cross_cog_wakeup"])
assert(attention_policy["current_vm_only"])
assert(type(task.attention_policy_value) == "function")
assert(task.attention_policy_value("policy") == "native_attention_event_current_vm_only")
assert(task.attention_policy_value("event") == "attention")
assert(task.attention_policy_value("signal_uses_cog_attention") == false)
assert(task.attention_policy_value("poll_uses_cog_attention") == false)
assert(task.attention_policy_value("bounded_attention_wait") == false)
assert(task.attention_policy_value("cross_cog_wakeup") == false)
assert(task.attention_policy_value("current_vm_only"))
assert(task.attention_policy_value("missing") == nil)
assert(task.attention_policy_value(nil) == nil)
attention_policy["bounded_attention_wait"] = true
assert(!task.attention_policy()["bounded_attention_wait"])

var task_self_test = task.self_test_result(2)
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
var invalid_self_test = task.self_test_result("bad")
assert(!invalid_self_test["ok"])
assert(invalid_self_test["error"] == "invalid_iterations")
assert(invalid_self_test["policy"] == "bounded_current_vm_cleanup_diagnostic")

task.reset()

def noop()
    return task.again
end

var reset_cleanup_h = task.start(noop)
assert(reset_cleanup_h >= 0)
assert(task.signal("reset_event"))
var reset_report = task.reset_result()
assert(reset_report["ok"])
assert(reset_report["reset"])
assert(reset_report["released_tasks"] == 1)
assert(reset_report["released_events"] == 1)
assert(reset_report["active_before"] == 1)
assert(reset_report["events_before"] == 1)
assert(reset_report["active_after"] == 0)
assert(reset_report["events_after"] == 0)
assert(reset_report["max_tasks"] == task.MAX_TASKS)
assert(task.info()["active"] == 0)
assert(task.events().size() == 0)

var handles = []
for i : 0..task.MAX_TASKS - 1
    var started = task.start_result(noop)
    assert(started["ok"])
    var h = started["handle"]
    assert(h == i)
    handles.push(h)
end
assert(task.start(noop) == -1)
var full_start = task.start_result(noop)
assert(!full_start["ok"])
assert(full_start["handle"] == -1)
assert(full_start["error"] == "no_free_slot")
assert(task.list().size() == task.MAX_TASKS)
assert(task.info()["ready"] == task.MAX_TASKS)
for h : handles
    assert(task.stop(h))
    assert(task.status(h) == "free")
end
assert(!task.stop(-99))
var invalid_stop = task.stop_result(-99)
assert(!invalid_stop["ok"])
assert(invalid_stop["error"] == "invalid_handle")
var free_stop = task.stop_result(handles[0])
assert(!free_stop["ok"])
assert(free_stop["error"] == "free")
assert(task.status(999) == "free")

task.reset()
var pause_count = {"value": 0}
def pauser(state)
    state["value"] += 1
    return task.again
end
var paused = task.start(pauser, pause_count)
var pause_report = task.pause_result(paused)
assert(pause_report["ok"])
assert(pause_report["previous_status"] == "ready")
assert(pause_report["status"] == "paused")
assert(task.status(paused) == "paused")
assert(task.next() == -1)
assert(pause_count["value"] == 0)
var pause_again = task.pause_result(paused)
assert(pause_again["ok"])
assert(pause_again["previous_status"] == "paused")
var resume_report = task.resume_result(paused)
assert(resume_report["ok"])
assert(resume_report["previous_status"] == "paused")
assert(resume_report["status"] == "ready")
assert(task.next() == paused)
assert(pause_count["value"] == 1)
assert(task.chk(paused))
assert(task.halt(paused))
assert(task.status(paused) == "paused")
assert(task.hlt(paused))
assert(task.status(paused) == "paused")
assert(task.cont(paused))
assert(task.status(paused) == "ready")
assert(task.stop(paused))
assert(task.status(paused) == "free")
assert(!task.chk(paused))
assert(task.id() == -1)
var resume_free = task.resume_result(paused)
assert(!resume_free["ok"])
assert(resume_free["error"] == "not_paused")
assert(!task.resume(paused))
var pause_free = task.pause_result(paused)
assert(!pause_free["ok"])
assert(pause_free["error"] == "free")

task.reset()
var spin_count = {"value": 0}
def spinner(state, limit)
    state["value"] += 1
    return state["value"] >= limit ? task.done : task.again
end
var first_spin = task.spin(-1, spinner, spin_count, 2)
assert(first_spin == 0)
assert(task.chk(first_spin))
assert(task.tasks().size() == 1)
assert(task.run(4) >= 2)
assert(spin_count["value"] == 2)
assert(!task.chk(first_spin))
var fixed_spin = task.spin(5, spinner, spin_count, 3)
assert(fixed_spin == 5)
assert(task.spin(5, spinner, spin_count, 3) == -1)
assert(task.stop(fixed_spin))
assert(task.spin(99, spinner, spin_count, 3) == -1)
assert(task.spin(-1, "not_fn") == -1)

task.reset()
def boom()
    raise "task_error", "boom"
end
var bad = task.start(boom)
assert(task.next() == bad)
assert(task.status(bad) == "error")
assert(task.info()["errors"] == 1)
assert(task.task_info(bad)["last_error"] != "")
assert(task.stop(bad))
assert(task.status(bad) == "free")

task.reset()
var fake_ms = 0
task._has_p2 = false
task._has_time = true
task.millis = def()
    return fake_ms
end

var timeout_state = {"timed_out": false}
def timeout_waiter(state)
    if task.woke_by_timeout()
        state["timed_out"] = true
        return task.done
    end
    return task.wait("never", 10)
end

var timed = task.start(timeout_waiter, timeout_state)
assert(task.next() == timed)
assert(task.status(timed) == "waiting")
fake_ms = 11
assert(task.next() == timed)
assert(timeout_state["timed_out"])
assert(task.status(timed) == "free")

task.reset()
fake_ms = 0
var queue_timeout = task.Queue(1)
var queue_timeout_state = {"timed_out": false}
def queue_default_timeout_waiter(state, q)
    if task.woke_by_timeout()
        state["timed_out"] = true
        return task.done
    end
    return task.wait(q, 10)
end
var queue_timeout_h = task.start(queue_default_timeout_waiter, queue_timeout_state, queue_timeout)
assert(task.next() == queue_timeout_h)
assert(task.status(queue_timeout_h) == "waiting")
var queue_life = task.lifecycle_result(queue_timeout_h)
assert(queue_life["ok"])
assert(queue_life["allocated"])
assert(queue_life["status"] == "waiting")
assert(queue_life["waiting"])
assert(queue_life["wait"] == "queue_get")
assert(queue_life["wait_target_kind"] == "queue")
assert(queue_life["has_deadline"])
assert(queue_life["remaining_ms"] >= 0)
assert(queue_life["current_vm"])
assert(!queue_life["current"])
fake_ms = 11
assert(task.next() == queue_timeout_h)
assert(queue_timeout_state["timed_out"])
assert(task.status(queue_timeout_h) == "free")
queue_life = task.lifecycle_result(queue_timeout_h)
assert(queue_life["ok"])
assert(!queue_life["allocated"])
assert(queue_life["status"] == "free")
assert(queue_life["error"] == "free")
var invalid_life = task.lifecycle_result(-99)
assert(!invalid_life["ok"])
assert(invalid_life["error"] == "invalid_handle")

task.reset()
var event_ready = task.ready_result("ready_event")
assert(!event_ready["ok"])
assert(!event_ready["ready"])
assert(event_ready["kind"] == "event")
assert(event_ready["error"] == "not_ready")
assert(task.signal("ready_event"))
event_ready = task.ready_result("ready_event")
assert(event_ready["ok"])
assert(event_ready["ready"])
var ready_queue = task.Queue(1)
var ready_queue_get = task.ready_result(ready_queue)
assert(!ready_queue_get["ready"])
assert(ready_queue_get["wait"] == "queue_get")
assert(ready_queue_get["can_put"])
assert(ready_queue.put_result("q")["ok"])
ready_queue_get = task.ready_result(ready_queue)
assert(ready_queue_get["ready"])
var ready_queue_put = task.ready_result(ready_queue, "put")
assert(!ready_queue_put["ready"])
assert(ready_queue_put["wait"] == "queue_put")
var ready_channel = p2ipc.channel.new(1)
var ready_channel_recv = task.ready_result(ready_channel)
assert(!ready_channel_recv["ready"])
assert(ready_channel_recv["wait"] == "p2ipc_channel_recv")
assert(ready_channel.send_result("c")["ok"])
ready_channel_recv = task.ready_result(ready_channel, "recv")
assert(ready_channel_recv["ready"])
var ready_channel_send = task.ready_result(ready_channel, "send")
assert(!ready_channel_send["ready"])
var ready_mailbox = p2ipc.mailbox.new()
var ready_mailbox_get = task.ready_result(ready_mailbox)
assert(!ready_mailbox_get["ready"])
assert(ready_mailbox_get["wait"] == "p2ipc_mailbox_get")
assert(ready_mailbox.put_result("m")["ok"])
ready_mailbox_get = task.ready_result(ready_mailbox, "get")
assert(ready_mailbox_get["ready"])
var ready_mailbox_put = task.ready_result(ready_mailbox, "put")
assert(!ready_mailbox_put["ready"])
var ready_sem = task.Semaphore(1)
assert(task.ready_result(ready_sem)["ready"])
assert(ready_sem.take_result()["ok"])
assert(!task.ready_result(ready_sem)["ready"])
var ready_mutex = task.Mutex()
assert(task.ready_result(ready_mutex)["ready"])
assert(ready_mutex.lock_result()["ok"])
assert(!task.ready_result(ready_mutex)["ready"])
var ready_flags = task.EventFlags()
assert(!task.ready_result(ready_flags, 1, "any")["ready"])
assert(ready_flags.set_result(1)["ok"])
assert(task.ready_result(ready_flags, 1, "all")["ready"])
var ready_timer = task.Timer(0, false)
assert(task.ready_result(ready_timer)["ready"])

task.reset()
fake_ms = 0
var ipc_channel_timeout = p2ipc.channel.new(1)
var ipc_channel_timeout_state = {"timed_out": false}
def ipc_channel_default_timeout_waiter(state, ch)
    if task.woke_by_timeout()
        state["timed_out"] = true
        return task.done
    end
    return task.wait(ch, 10)
end
var ipc_channel_timeout_h = task.start(ipc_channel_default_timeout_waiter, ipc_channel_timeout_state, ipc_channel_timeout)
assert(task.next() == ipc_channel_timeout_h)
assert(task.status(ipc_channel_timeout_h) == "waiting")
fake_ms = 11
assert(task.next() == ipc_channel_timeout_h)
assert(ipc_channel_timeout_state["timed_out"])
assert(task.status(ipc_channel_timeout_h) == "free")

task.reset()
fake_ms = 0
var ipc_mailbox_timeout = p2ipc.mailbox.new()
var ipc_mailbox_timeout_state = {"timed_out": false}
def ipc_mailbox_default_timeout_waiter(state, mb)
    if task.woke_by_timeout()
        state["timed_out"] = true
        return task.done
    end
    return task.wait(mb, 10)
end
var ipc_mailbox_timeout_h = task.start(ipc_mailbox_default_timeout_waiter, ipc_mailbox_timeout_state, ipc_mailbox_timeout)
assert(task.next() == ipc_mailbox_timeout_h)
assert(task.status(ipc_mailbox_timeout_h) == "waiting")
fake_ms = 11
assert(task.next() == ipc_mailbox_timeout_h)
assert(ipc_mailbox_timeout_state["timed_out"])
assert(task.status(ipc_mailbox_timeout_h) == "free")

task.reset()
var sem_wait = task.Semaphore(0)
var sem_state = {"acquired": false}
def sem_waiter(state, sem)
    if sem.take()
        state["acquired"] = true
        return task.done
    end
    return task.wait(sem, 1000)
end
var sem_h = task.start(sem_waiter, sem_state, sem_wait)
assert(task.next() == sem_h)
assert(task.status(sem_h) == "waiting")
assert(sem_wait.give())
assert(task.next() == sem_h)
assert(sem_state["acquired"])
assert(task.status(sem_h) == "free")

task.reset()
var wait_mutex = task.Mutex()
assert(wait_mutex.lock())
var mutex_state = {"locked": false}
def mutex_waiter(state, mx)
    if mx.lock()
        state["locked"] = true
        mx.unlock()
        return task.done
    end
    return task.wait(mx, 1000)
end
var mutex_h = task.start(mutex_waiter, mutex_state, wait_mutex)
assert(task.next() == mutex_h)
assert(task.status(mutex_h) == "waiting")
assert(wait_mutex.unlock())
assert(task.next() == mutex_h)
assert(mutex_state["locked"])
assert(task.status(mutex_h) == "free")

task.reset()
var q_wait = task.Queue(1)
var q_state = {"value": nil}
def q_waiter(state, q)
    var value = q.get()
    if value != nil
        state["value"] = value
        return task.done
    end
    return task.wait(q, "get", 1000)
end
var qh = task.start(q_waiter, q_state, q_wait)
assert(task.next() == qh)
assert(task.status(qh) == "waiting")
assert(q_wait.put("ready"))
assert(task.next() == qh)
assert(q_state["value"] == "ready")
assert(task.status(qh) == "free")

task.reset()
var full_q = task.Queue(1)
assert(full_q.put("held"))
var put_state = {"put": false}
def q_put_waiter(state, q)
    if q.put("later")
        state["put"] = true
        return task.done
    end
    return task.wait(q, "put", 1000)
end
var put_h = task.start(q_put_waiter, put_state, full_q)
assert(task.next() == put_h)
assert(task.status(put_h) == "waiting")
assert(full_q.get() == "held")
assert(task.next() == put_h)
assert(put_state["put"])
assert(full_q.get() == "later")

task.reset()
var flags_wait = task.EventFlags()
var flags_state = {"ready": false}
def flags_waiter(state, flags)
    if flags.ready(0x04, "all")
        state["ready"] = true
        return task.done
    end
    return task.wait(flags, "all", 1000)
end
var flags_h = task.start(flags_waiter, flags_state, flags_wait)
assert(task.next() == flags_h)
assert(task.status(flags_h) == "waiting")
assert(flags_wait.set(0x04) == 0x04)
assert(task.next() == flags_h)
assert(flags_state["ready"])
assert(task.status(flags_h) == "free")

task.reset()
fake_ms = 0
var timer_wait = task.Timer(5, false)
var timer_state = {"expired": false}
def timer_waiter(state, timer)
    if timer.expired()
        state["expired"] = true
        return task.done
    end
    return task.wait(timer, 1000)
end
var timer_h = task.start(timer_waiter, timer_state, timer_wait)
assert(task.next() == timer_h)
assert(task.status(timer_h) == "waiting")
fake_ms = 6
assert(task.next() == timer_h)
assert(timer_state["expired"])
assert(task.status(timer_h) == "free")

task.reset()
var ipc_ch = p2ipc.channel.new(1)
var ipc_recv_state = {"value": nil}
def ipc_channel_recv_waiter(state, ch)
    var res = ch.recv_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(ch, "recv", 1000)
end
var ipc_recv_h = task.start(ipc_channel_recv_waiter, ipc_recv_state, ipc_ch)
assert(task.next() == ipc_recv_h)
assert(task.status(ipc_recv_h) == "waiting")
assert(ipc_ch.send_result("ipc-ready")["ok"])
assert(task.next() == ipc_recv_h)
assert(ipc_recv_state["value"] == "ipc-ready")
assert(task.status(ipc_recv_h) == "free")

task.reset()
var ipc_full_ch = p2ipc.channel.new(1)
assert(ipc_full_ch.send_result("held")["ok"])
var ipc_send_state = {"sent": false}
def ipc_channel_send_waiter(state, ch)
    var res = ch.send_result("later")
    if res["sent"]
        state["sent"] = true
        return task.done
    end
    return task.wait(ch, "send", 1000)
end
var ipc_send_h = task.start(ipc_channel_send_waiter, ipc_send_state, ipc_full_ch)
assert(task.next() == ipc_send_h)
assert(task.status(ipc_send_h) == "waiting")
assert(ipc_full_ch.recv_result()["value"] == "held")
assert(task.next() == ipc_send_h)
assert(ipc_send_state["sent"])
assert(ipc_full_ch.recv_result()["value"] == "later")
assert(task.status(ipc_send_h) == "free")

task.reset()
var ipc_mb = p2ipc.mailbox.new()
var ipc_mb_get_state = {"value": nil}
def ipc_mailbox_get_waiter(state, mb)
    var res = mb.get_result()
    if res["found"]
        state["value"] = res["value"]
        return task.done
    end
    return task.wait(mb, "get", 1000)
end
var ipc_mb_get_h = task.start(ipc_mailbox_get_waiter, ipc_mb_get_state, ipc_mb)
assert(task.next() == ipc_mb_get_h)
assert(task.status(ipc_mb_get_h) == "waiting")
assert(ipc_mb.put_result("mail-ready")["ok"])
assert(task.next() == ipc_mb_get_h)
assert(ipc_mb_get_state["value"] == "mail-ready")
assert(task.status(ipc_mb_get_h) == "free")

task.reset()
var ipc_full_mb = p2ipc.mailbox.new()
assert(ipc_full_mb.put_result("held")["ok"])
var ipc_mb_put_state = {"stored": false}
def ipc_mailbox_put_waiter(state, mb)
    var res = mb.put_result("later")
    if res["stored"]
        state["stored"] = true
        return task.done
    end
    return task.wait(mb, "put", 1000)
end
var ipc_mb_put_h = task.start(ipc_mailbox_put_waiter, ipc_mb_put_state, ipc_full_mb)
assert(task.next() == ipc_mb_put_h)
assert(task.status(ipc_mb_put_h) == "waiting")
assert(ipc_full_mb.get_result()["value"] == "held")
assert(task.next() == ipc_mb_put_h)
assert(ipc_mb_put_state["stored"])
assert(ipc_full_mb.get_result()["value"] == "later")
assert(task.status(ipc_mb_put_h) == "free")

task.reset()
var closed_ch = p2ipc.channel.new(1)
var closed_recv_state = {"error": nil}
def ipc_channel_closed_recv_waiter(state, ch)
    var res = ch.recv_result()
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(ch, "recv", 1000)
end
var closed_recv_h = task.start(ipc_channel_closed_recv_waiter, closed_recv_state, closed_ch)
assert(task.next() == closed_recv_h)
assert(task.status(closed_recv_h) == "waiting")
assert(closed_ch.close_result()["closed"])
assert(task.next() == closed_recv_h)
assert(closed_recv_state["error"] == "closed")
assert(task.status(closed_recv_h) == "free")

task.reset()
var closed_full_ch = p2ipc.channel.new(1)
assert(closed_full_ch.send_result("held")["ok"])
var closed_send_state = {"error": nil}
def ipc_channel_closed_send_waiter(state, ch)
    var res = ch.send_result("later")
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(ch, "send", 1000)
end
var closed_send_h = task.start(ipc_channel_closed_send_waiter, closed_send_state, closed_full_ch)
assert(task.next() == closed_send_h)
assert(task.status(closed_send_h) == "waiting")
assert(closed_full_ch.close_result()["closed"])
assert(task.next() == closed_send_h)
assert(closed_send_state["error"] == "closed")
assert(task.status(closed_send_h) == "free")

task.reset()
var closed_mb = p2ipc.mailbox.new()
var closed_get_state = {"error": nil}
def ipc_mailbox_closed_get_waiter(state, mb)
    var res = mb.get_result()
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(mb, "get", 1000)
end
var closed_get_h = task.start(ipc_mailbox_closed_get_waiter, closed_get_state, closed_mb)
assert(task.next() == closed_get_h)
assert(task.status(closed_get_h) == "waiting")
assert(closed_mb.close_result()["closed"])
assert(task.next() == closed_get_h)
assert(closed_get_state["error"] == "closed")
assert(task.status(closed_get_h) == "free")

task.reset()
var closed_full_mb = p2ipc.mailbox.new()
assert(closed_full_mb.put_result("held")["ok"])
var closed_put_state = {"error": nil}
def ipc_mailbox_closed_put_waiter(state, mb)
    var res = mb.put_result("later")
    if res["error"] == "closed"
        state["error"] = res["error"]
        return task.done
    end
    return task.wait(mb, "put", 1000)
end
var closed_put_h = task.start(ipc_mailbox_closed_put_waiter, closed_put_state, closed_full_mb)
assert(task.next() == closed_put_h)
assert(task.status(closed_put_h) == "waiting")
assert(closed_full_mb.close_result()["closed"])
assert(task.next() == closed_put_h)
assert(closed_put_state["error"] == "closed")
assert(task.status(closed_put_h) == "free")

task.reset()
def malformed_wait_unknown()
    return {
        "_task_wait": "not_a_wait_kind"
    }
end
var malformed_unknown = task.start(malformed_wait_unknown)
assert(task.next() == malformed_unknown)
assert(task.status(malformed_unknown) == "error")
assert(task.task_info(malformed_unknown)["last_error"] == "value_error:invalid task wait descriptor")

task.reset()
def malformed_wait_missing_object()
    return {
        "_task_wait": "sem"
    }
end
var malformed_object = task.start(malformed_wait_missing_object)
assert(task.next() == malformed_object)
assert(task.status(malformed_object) == "error")
assert(task.task_info(malformed_object)["last_error"] == "value_error:task object wait is missing object")

class BrokenSemaphore
    var _task_kind
    def init()
        self._task_kind = "sem"
    end
    def value()
        raise "value_error", "forced wait-object failure"
    end
end

task.reset()
var broken = BrokenSemaphore()
def broken_wait(obj)
    return task.wait(obj, 1000)
end
var broken_h = task.start(broken_wait, broken)
assert(task.next() == broken_h)
assert(task.status(broken_h) == "waiting")
assert(task.next() == -1)
assert(task.status(broken_h) == "error")
assert(task.task_info(broken_h)["last_error"] == "value_error:forced wait-object failure")
