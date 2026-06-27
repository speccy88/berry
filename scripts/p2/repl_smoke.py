#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import time


SUITES = {
    "quick": [
        ("print(6*7)", "42"),
        ('s="abc"; print(s+"def")', "abcdef"),
        ('m={"a":2,"b":5}; print(m["a"]+m["b"])', "7"),
        ("import math; print(math.sqrt(81))", "9"),
    ],
    "full": [
        ('run_file("/tests/p2/smoke_all.be")', "P2_SMOKE_PASS all"),
    ],
    "edge32": [
        ('run_file("/tests/p2/smoke_edge32_all.be")', "P2_SMOKE_PASS edge32_all"),
    ],
    "examples-quick": [
        ('run_file("/berry/examples/blink.be")', "blink done"),
        ('run_file("/berry/examples/gpio_loopback.be")', "gpio loopback done"),
        ('run_file("/berry/examples/pwm_fade.be")', "pwm fade done"),
        ('run_file("/berry/examples/adc_read.be")', "adc done"),
        ('run_file("/berry/examples/dac_write.be")', "dac done"),
        ('run_file("/berry/examples/nco_counter_loopback.be")', "nco counter loopback done"),
        ('run_file("/berry/examples/quadrature_counter.be")', "quadrature counter done"),
    ],
    "examples-bus": [
        ('run_file("/berry/examples/i2c/scan.be")', "i2c scan done"),
        ('run_file("/berry/examples/spi/jedec.be")', "spi jedec done"),
    ],
    "examples-serial": [
        ('run_file("/berry/examples/uart_loopback.be")', "uart loopback done"),
        ('run_file("/berry/examples/sync_serial_loopback.be")', "sync serial loopback done"),
    ],
    "examples-smartpin-diagnostics": [
        ('run_file("/berry/examples/smartpin_diagnostics.be")', "smartpin diagnostics done"),
    ],
    "examples-system": [
        ('run_file("/berry/examples/cordic_demo.be")', "cordic demo done"),
        ('run_file("/berry/examples/psram_cache_stats.be")', "psram cache stats done"),
        ('run_file("/berry/examples/repl_sd.be")', "repl sd helper done"),
        ('run_file("/berry/examples/file_sd.be")', "file sd example done"),
        ('run_file("/berry/examples/json_sd.be")', "json sd example done"),
    ],
    "examples-runtime": [
        ('run_file("/berry/examples/task_scheduler.be")', "task scheduler example done"),
        ('run_file("/berry/examples/task_primitives.be")', "task primitives example done"),
        ('run_file("/berry/examples/cogclo.be")', "cog closure example done"),
        ('run_file("/berry/examples/cogblk.be")', "cog closure blink done"),
        ('run_file("/berry/examples/pasm_direct.be")', "pasm direct done"),
    ],
    "examples-debug": [
        ('run_file("/berry/examples/debug_report.be")', "debug report done"),
    ],
    "examples-wifi": [
        ('run_file("/berry/examples/wifi/detect.be")', "wifi detect done"),
    ],
    "examples-p2": [
        ('run_file("/berry/examples/p2/blink.be")', "p2 blink done"),
        ('run_file("/berry/examples/p2/pin_helpers.be")', "p2 pin helpers done"),
        ('run_file("/berry/examples/p2/smartpin_helpers.be")', "p2 smartpin helpers done"),
        ('run_file("/berry/examples/p2/timing_helpers.be")', "p2 timing helpers done"),
        ('run_file("/berry/examples/p2/hardware_helpers.be")', "p2 hardware helpers done"),
        ('run_file("/berry/examples/p2/closure_blinker.be")', "p2 closure blinker done"),
        ('run_file("/berry/examples/p2/cog_spawn_source_blinker.be")', "p2 source blinker done"),
    ],
    "examples-unsupported": [
        ('run_file("/berry/examples/vga_test_pattern.be")', "vga test pattern done"),
        ('run_file("/berry/examples/usb_keyboard_mouse.be")', "usb keyboard mouse done"),
    ],
    "examples-core": [
        ('run_file("/berry/examples/core/run_file_demo.be")', "run_file demo done"),
        ('run_file("/berry/examples/core/listdir.be")', "listdir demo done"),
        ('run_file("/berry/examples/core/bigloop.be")', "bigloop demo done"),
        ('run_file("/berry/examples/core/fib_rec.be")', "fib recursion demo done"),
        ('run_file("/berry/examples/core/calcpi.be")', "calcpi demo done"),
        ('run_file("/berry/examples/core/json.be")', "json core demo done"),
        ('run_file("/berry/examples/core/anon_func.be")', "anonymous closure demo done"),
        ('run_file("/berry/examples/core/qsort.be")', "qsort demo done"),
        ('run_file("/berry/examples/core/lambda.be")', "lambda demo done"),
        ('run_file("/berry/examples/core/bintree.be")', "bintree demo done"),
        ('run_file("/berry/examples/core/string.be")', "string demo done"),
        ('run_file("/berry/examples/core/strmod.be")', "string format demo done"),
        ('run_file("/berry/examples/core/exception.be")', "exception demo done"),
        (
            'run_file("/berry/examples/core/guess_number.be")',
            "guess number demo done",
            "1: enter the number you guessed:",
            "42",
        ),
        (
            'run_file("/berry/examples/core/repl.be")',
            "repl demo done",
            "> ",
            "quit",
        ),
    ],
    "compat": [
        ('run_file("/tests/p2/smoke_compat.be")', "P2_SMOKE_PASS compat"),
        ('print(input("P2_INPUT_PROMPT"))', "P2_INPUT_VALUE", "P2_INPUT_PROMPT", "P2_INPUT_VALUE"),
    ],
    "cog-closure": [
        ('run_file("/tests/p2/smoke_cog_closure.be")', "P2_SMOKE_PASS cog_closure"),
    ],
    "cog-closure-min": [
        ('run_file("/tests/p2/smoke_cog_closure_min.be")', "P2_SMOKE_PASS cog_closure_min"),
    ],
    "cog-policy-min": [
        ('run_file("/tests/p2/smoke_cog_policy_min.be")', "P2_SMOKE_PASS cog_policy_min"),
    ],
    "task": [
        ('run_file("/tests/p2/smoke_task.be")', "P2_SMOKE_PASS task"),
    ],
    "task-policy-min": [
        (
            'import task; print(task.info()["max_tasks"], task.status(0))',
            "16 free",
        ),
        (
            'import task; c=task.capabilities(); k=task.contract(); print("TASK_NATIVE_META", c["backend"], c["spin2_compatible_names"], task.capability("max_tasks"), k["scheduler_policy"], task.audit_ok())',
            "TASK_NATIVE_META p2_native_cooperative true 16 current_vm_callback_step true",
        ),
        (
            'import task; print("TASK_NATIVE_META_VALUES", task.contract_value("scheduler_policy"), task.attention_policy_value("policy"), task.execution_model_value("backend"), task.capability("contract_value"), task.contract_value("missing") == nil)',
            "TASK_NATIVE_META_VALUES current_vm_callback_step native_attention_event_current_vm_only p2_native_cooperative true true",
        ),
        (
            'import task; c=task.capabilities(); k=task.contract(); print("TASK_NATIVE_RESULTS_META", c["result_diagnostics"], task.capability("reset_result"), k["scheduler_step_result"], k["task_lifecycle_result"])',
            "TASK_NATIVE_RESULTS_META true true true true",
        ),
        (
            'import task; task.reset(); b=task.ready_result("evt"); print("TASK_NATIVE_EVENT_BEFORE", b["ready"], b["error"])',
            "TASK_NATIVE_EVENT_BEFORE false not_ready",
        ),
        (
            'task.signal("evt"); a=task.ready_result("evt"); e=task.events(); print("TASK_NATIVE_EVENT_AFTER", a["ready"], e.size())',
            "TASK_NATIVE_EVENT_AFTER true 1",
        ),
        (
            'w=task.wait("evt"); wr=task.ready_result(w); c=task.clear_all(); d=task.ready_result("evt"); print("TASK_NATIVE_EVENT_CLEAR", wr["ready"], c, d["ready"], task.capability("event_readiness_result"))',
            "TASK_NATIVE_EVENT_CLEAR true true false true",
        ),
        (
            's=task.Semaphore(1); a=s.take_result(); b=s.take_result(); print("TASK_NATIVE_SEM_TAKE", a["ok"], a["count"], b["ok"], b["error"], s.value())',
            "TASK_NATIVE_SEM_TAKE true 0 false unavailable 0",
        ),
        (
            'g=s.give_result(); i=s.info(); print("TASK_NATIVE_SEM_GIVE", g["ok"], g["count"], i["kind"], i["count"], task.capability("native_semaphore"))',
            "TASK_NATIVE_SEM_GIVE true 1 Semaphore 1 true",
        ),
        (
            'm=task.Mutex(); a=m.lock_result(); b=m.lock_result(); print("TASK_NATIVE_MUTEX_LOCK", a["ok"], a["locked"], a["owner"], b["ok"], b["error"], m.is_locked())',
            "TASK_NATIVE_MUTEX_LOCK true true -1 false busy true",
        ),
        (
            'u=m.unlock_result(); e=m.unlock_result(); i=m.info(); print("TASK_NATIVE_MUTEX_UNLOCK", u["ok"], u["previous_owner"], e["ok"], e["error"], i["locked"], i["owner"], task.capability("native_mutex"))',
            "TASK_NATIVE_MUTEX_UNLOCK true -1 false not_locked false -1 true",
        ),
        (
            'f=task.EventFlags(); a=f.set_result(3); print("TASK_NATIVE_FLAGS_SET", a["ok"], a["value"], task.capability("native_event_flags"))',
            "TASK_NATIVE_FLAGS_SET true 3 true",
        ),
        (
            'b=f.ready_result(1); c=f.ready_result(3, "all"); d=f.ready_result(4); print("TASK_NATIVE_FLAGS_READY", b["ready"], c["ready"], d["ok"], d["error"])',
            "TASK_NATIVE_FLAGS_READY true true false not_ready",
        ),
        (
            'cl=f.clear_result(1); bad=f.set_result("bad"); info=f.info(); print("TASK_NATIVE_FLAGS_CLEAR_BAD", cl["ok"], cl["value"], bad["ok"], bad["error"], info["kind"], info["value"], task.capability("event_flags_result_diagnostics"))',
            "TASK_NATIVE_FLAGS_CLEAR_BAD true 2 false invalid_mask EventFlags 2 true",
        ),
        (
            't=task.Timer(1000, false); r=t.remaining_result(); e=t.expired_result(); print("TASK_NATIVE_TIMER_WAIT", r["ok"], r["active"], e["ok"], e["error"], task.capability("native_timer"))',
            "TASK_NATIVE_TIMER_WAIT true true false not_expired true",
        ),
        (
            'z=task.Timer(0, false); e=z.expired_result(); c=z.cancel_result(); rr=z.remaining_result(); print("TASK_NATIVE_TIMER_EXPIRE", e["ok"], e["expired"], e["active"], c["ok"], rr["ok"], rr["error"])',
            "TASK_NATIVE_TIMER_EXPIRE true true false true false inactive",
        ),
        (
            'rt=task.Timer(0, true); e=rt.expired_result(); rs=rt.restart_result(); i=rt.info(); print("TASK_NATIVE_TIMER_REPEAT", e["ok"], e["active"], rs["period_ms"], i["kind"], task.capability("timer_result_diagnostics"))',
            "TASK_NATIVE_TIMER_REPEAT true true 0 Timer true",
        ),
        (
            'rs=task.ready_result(s); s.take(); rz=task.ready_result(s); print("TASK_NATIVE_READY_SEM", rs["ready"], rs["kind"], rz["ready"], rz["error"], task.capability("primitive_readiness_result"))',
            "TASK_NATIVE_READY_SEM true semaphore false not_ready true",
        ),
        (
            'mq=task.Mutex(); rm=task.ready_result(mq); mq.lock(); rb=task.ready_result(mq); print("TASK_NATIVE_READY_MUTEX", rm["ready"], rm["kind"], rb["ready"], rb["locked"])',
            "TASK_NATIVE_READY_MUTEX true mutex false true",
        ),
        (
            'rq=task.Queue(1); eg=task.ready_result(rq); ep=task.ready_result(rq, "put"); rq.put("x"); fg=task.ready_result(rq); fp=task.ready_result(rq, "put"); print("TASK_NATIVE_READY_QUEUE", eg["ready"], ep["ready"], fg["ready"], fp["ready"])',
            "TASK_NATIVE_READY_QUEUE false true true false",
        ),
        (
            'rf=task.EventFlags(); fn=task.ready_result(rf, 1); rf.set(1); fy=task.ready_result(rf, 1, "all"); print("TASK_NATIVE_READY_FLAGS", fn["ready"], fn["error"], fy["ready"], fy["kind"])',
            "TASK_NATIVE_READY_FLAGS false not_ready true flags",
        ),
        (
            'tl=task.Timer(60000, false); tn=task.ready_result(tl); ty=task.ready_result(rt); print("TASK_NATIVE_READY_TIMER", tn["ready"], tn["error"], ty["ready"], ty["kind"])',
            "TASK_NATIVE_READY_TIMER false not_ready true timer",
        ),
        (
            'import p2ipc; ch=p2ipc.channel.new(1); cr=task.ready_result(ch); cs=task.ready_result(ch, "send"); print("TASK_NATIVE_READY_IPC_CH_EMPTY", cr["ready"], cs["ready"], cs["can_send"], task.capability("p2ipc_object_readiness_result"))',
            "TASK_NATIVE_READY_IPC_CH_EMPTY false true true true",
        ),
        (
            'sr=ch.send_result("x"); cr=task.ready_result(ch); cs=task.ready_result(ch, "send"); print("TASK_NATIVE_READY_IPC_CH_FULL", sr["ok"], cr["ready"], cs["ready"], cr["size"], cr["free"])',
            "TASK_NATIVE_READY_IPC_CH_FULL true true false 1 0",
        ),
        (
            'cx=ch.close_result(); cc=task.ready_result(ch); print("TASK_NATIVE_READY_IPC_CH_CLOSED", cx["closed"], cc["ready"], cc["closed"], cc["error"])',
            "TASK_NATIVE_READY_IPC_CH_CLOSED true false true closed",
        ),
        (
            'mb=p2ipc.mailbox.new(); mg=task.ready_result(mb); mp=task.ready_result(mb, "put"); print("TASK_NATIVE_READY_IPC_MB_EMPTY", mg["ready"], mp["ready"], mp["can_put"])',
            "TASK_NATIVE_READY_IPC_MB_EMPTY false true true",
        ),
        (
            'mr=mb.put_result("m"); mg=task.ready_result(mb); mp=task.ready_result(mb, "put"); print("TASK_NATIVE_READY_IPC_MB_FULL", mr["ok"], mg["ready"], mp["ready"], mg["can_get"], mp["can_put"])',
            "TASK_NATIVE_READY_IPC_MB_FULL true true false true false",
        ),
        (
            'mx=mb.close_result(); mc=task.ready_result(mb); print("TASK_NATIVE_READY_IPC_MB_CLOSED", mx["closed"], mc["ready"], mc["closed"], mc["error"])',
            "TASK_NATIVE_READY_IPC_MB_CLOSED true false true closed",
        ),
        ('import task; import p2ipc; task.reset()', ""),
        ('c=p2ipc.channel.new(1); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(c,"recv",1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); c.send_result("x")', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_IPC_CH_RECV", a, task.status(h), task.capability("p2ipc_object_waits")); task.reset()',
            "TASK_NATIVE_WAIT_IPC_CH_RECV waiting free true",
        ),
        ('m=p2ipc.mailbox.new(); m.put_result("full"); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(m,"put",1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); m.get_result()', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_IPC_MB_PUT", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_IPC_MB_PUT waiting free",
        ),
        ('c=p2ipc.channel.new(1); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(c,"recv",1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); c.close_result()', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_IPC_CH_CLOSE", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_IPC_CH_CLOSE waiting free",
        ),
        ('q=task.Queue(1); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(q,"get",1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); q.put("x")', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_PRIM_QUEUE", a, task.status(h), task.capability("primitive_object_waits")); task.reset()',
            "TASK_NATIVE_WAIT_PRIM_QUEUE waiting free true",
        ),
        ('sem=task.Semaphore(0); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(sem,1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); sem.give()', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_PRIM_SEM", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_PRIM_SEM waiting free",
        ),
        ('mx=task.Mutex(); mx.lock(); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(mx,1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); mx.unlock()', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_PRIM_MUTEX", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_PRIM_MUTEX waiting free",
        ),
        ('fl=task.EventFlags(); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(fl,3,"all",1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h); fl.set(3)', ""),
        (
            'task.next(); print("TASK_NATIVE_WAIT_PRIM_FLAGS", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_PRIM_FLAGS waiting free",
        ),
        ('tm=task.Timer(0,false); s={"n":0}', ""),
        ('def f() if s["n"]==0 s["n"]=1; return task.wait(tm,1000) end return task.done end', ""),
        ('h=task.spin(-1,f); task.next(); a=task.status(h)', ""),
        (
            'task.run_result(3,1); print("TASK_NATIVE_WAIT_PRIM_TIMER", a, task.status(h)); task.reset()',
            "TASK_NATIVE_WAIT_PRIM_TIMER waiting free",
        ),
        (
            'q=task.Queue(1); a=q.put_result(nil); b=q.put_result("x"); print("TASK_NATIVE_QUEUE_PUT", a["ok"], a["value"] == nil, a["size"], a["free"], b["ok"], b["error"])',
            "TASK_NATIVE_QUEUE_PUT true true 1 0 false full",
        ),
        (
            'g=q.get_result(); e=q.get_result(); i=q.info(); print("TASK_NATIVE_QUEUE_GET", g["ok"], g["value"] == nil, e["ok"], e["error"], i["size"], i["free"], task.capability("native_queue"))',
            "TASK_NATIVE_QUEUE_GET true true false empty 0 1 true",
        ),
        (
            'import task; task.reset(); def native_task_done() return task.done end; h=task.spin(-1, native_task_done); alive=task.chk(h); ran=task.next(); print("TASK_NATIVE_SPIN", h, alive, ran, task.status(h), task.id()); task.reset()',
            "TASK_NATIVE_SPIN 0 true 0 free -1",
        ),
        (
            'import task; task.reset(); def native_task_pause() return task.done end; h=task.spin(3, native_task_pause); task.halt(h); s1=task.status(h); task.cont(h); s2=task.status(h); task.stop(h); print("TASK_NATIVE_ALIAS", h, s1, s2, task.chk(h)); task.reset()',
            "TASK_NATIVE_ALIAS 3 paused ready false",
        ),
        (
            'import task; task.reset(); def trd() return task.done end; s=task.start_result(trd); print("TASK_NATIVE_START_RESULT", s["ok"], s["handle"])',
            "TASK_NATIVE_START_RESULT true 0",
        ),
        (
            'l=task.lifecycle_result(s["handle"]); print("TASK_NATIVE_LIFECYCLE_RESULT", l["status"], l["allocated"])',
            "TASK_NATIVE_LIFECYCLE_RESULT ready true",
        ),
        (
            'n=task.next_result(); print("TASK_NATIVE_NEXT_RESULT", n["ok"], n["handle"], n["status"], n["live_before"], n["live_after"])',
            "TASK_NATIVE_NEXT_RESULT true 0 free 1 0",
        ),
        (
            'r=task.reset_result(); print("TASK_NATIVE_RESET_RESULT", r["ok"], r["active_after"], r["events_after"])',
            "TASK_NATIVE_RESET_RESULT true 0 0",
        ),
        (
            'task.reset(); def trun() return task.done end; task.spin(-1, trun); rr=task.run_result(3, 0); print("TASK_NATIVE_RUN_RESULT", rr["ok"], rr["steps"], rr["live_before"], rr["live_after"], rr["complete"])',
            "TASK_NATIVE_RUN_RESULT true 1 1 0 true",
        ),
        (
            'import task; task.reset(); def tpd() return task.done end; h=task.spin(2, tpd); p=task.pause_result(h); rs=task.resume_result(h); print("TASK_NATIVE_PAUSE_RESULT", p["ok"], p["status"], rs["ok"], rs["status"])',
            "TASK_NATIVE_PAUSE_RESULT true paused true ready",
        ),
        (
            'st=task.stop_result(h); bad=task.stop_result(h); print("TASK_NATIVE_STOP_RESULT", st["ok"], st["status"], bad["ok"], bad["error"]); task.reset()',
            "TASK_NATIVE_STOP_RESULT true free false free",
        ),
        (
            'print("P2_SMOKE_PASS task_policy_min")',
            "P2_SMOKE_PASS task_policy_min",
        ),
    ],
    "p2ipc": [
        (
            'import p2ipc; c=p2ipc.capabilities(); k=p2ipc.contract(); print("P2_IPC_META", c["payload_result"], k["payload_result"], k["task_wait_integration"])',
            "P2_IPC_META true true true",
        ),
        (
            'import p2ipc; p=p2ipc.payload_result("abc"); q=p2ipc.payload_result([1,2]); print("P2_IPC_PAY", p["cross_vm_copyable"], p["copyable_kind"], q["cross_vm_copyable"], q["copyable_kind"])',
            "P2_IPC_PAY true string false list",
        ),
        (
            'import p2ipc; ch=p2ipc.channel.new(1); print("P2_IPC_CH", ch.ready_result("send")["ready"], ch.send_result(nil)["ok"], ch.ready_result("recv")["ready"], ch.recv_result()["found"], ch.close_result()["closed"])',
            "P2_IPC_CH true true true true true",
        ),
        (
            'import p2ipc; mb=p2ipc.mailbox.new(); print("P2_IPC_MB", mb.ready_result("put")["ready"], mb.put_result("m")["ok"], mb.peek_result()["value"], mb.get_result()["value"], mb.close_result()["closed"])',
            "P2_IPC_MB true true m m true",
        ),
        (
            'import p2ipc; b=p2ipc.shared.Buffer(2); x=b.fill_result(7); y=b.clear_result(); mx=p2ipc.mutex.new(); print("P2_IPC_RES", b.size(), x["ok"], y["ok"], b.read(0), mx.lock_result()["locked"], mx.unlock_result()["unlocked"], mx.close_result()["closed"])',
            "P2_IPC_RES 2 true true 0 true true true",
        ),
        (
            'print("P2_SMOKE_PASS p2ipc")',
            "P2_SMOKE_PASS p2ipc",
        ),
    ],
    "ipc-policy-min": [
        (
            'i=run_file("/modules/p2ipc.be"); print(i.contract_value("model"), i.contract_value("task_wait_integration"), i.attention_policy_value("policy"), i.capability("payload_result"), i.audit_ok())',
            "current_vm_cooperative_ipc true native_bounded_wait_available_not_wired_to_ipc true true",
        ),
        (
            'print("P2_SMOKE_PASS ipc_policy_min")',
            "P2_SMOKE_PASS ipc_policy_min",
        ),
    ],
    "p2compat": [
        (
            'm=run_file("/modules/p2compat.be"); p=m.board_profile_policy(); b0=m.board_pin_policy(0); b58=m.board_pin_policy(58); print("P2_COMPAT_BOARD", p["unsupported_build_policy"], p["normal_catalina_dir"], b0["ok"], b58["reason"], m.audit_ok())',
            "P2_COMPAT_BOARD raise_loud_or_report_unsupported ../Catalina true sd true",
        ),
        (
            'import p2; a=p2.vm_copyable("abc"); b=p2.vm_copyable([1]); print("P2_COMPAT_NATIVE", a["ok"], a["kind"], b["ok"], b["kind"])',
            "P2_COMPAT_NATIVE true string false list",
        ),
        (
            'import p2; a=p2.vm_copyable_args(nil,true,7,"abc"); b=p2.vm_copyable_args(1,[2]); print("P2_COMPAT_ARGS", a["ok"], a["copyable_count"], b["ok"], b["first_rejected_kind"])',
            "P2_COMPAT_ARGS true 4 false list",
        ),
        (
            'import p2; h=p2.heap_info(); i=p2.vm_info(0); print("P2_COMPAT_VM_META", type(h["vm_partition_bytes"]), h["vm_partition_bytes"]>0, h["vm_partition_capacity"]>=1, h["vm_partition_free_capacity"]>=0, h["vm_partition_current"], i["ok"], i["status"])',
            "P2_COMPAT_VM_META int true true true -1 true inactive",
        ),
        (
            'm=run_file("/modules/p2compat.be"); p=m.child_vm_partition_policy(); print("P2_COMPAT_VM_PARTITION_POLICY", p["source"], p["usable_for_child_calls"], p["production_count_selected"], p["retry_policy"], m.child_vm_partition_value("partition_bytes")>0)',
            "P2_COMPAT_VM_PARTITION_POLICY p2.heap_info true false stop_routine_priority_work_until_native_partition_allocator_changes true",
        ),
        (
            'run_file("/tests/p2/smoke_p2compat.be")',
            "P2_SMOKE_PASS p2compat",
        ),
        (
            'run_file("/tests/p2/p2compvm.be")',
            "P2_SMOKE_PASS p2compat_child_vm",
        ),
    ],
    "p2-api": [
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
    ],
    "debug-capabilities-min": [
        ("import p2", "berry>"),
        ("var c=p2.debug.capabilities()", "berry>"),
        (
            'print("P2_DBG_CAP1", c["snapshot"], c["heap"], c["registers"])',
            "P2_DBG_CAP1 true true true",
        ),
        (
            'print("P2_DBG_CAP2", c["breakpoints"], c["trace_controls"])',
            "P2_DBG_CAP2 false false",
        ),
        (
            'print("P2_DBG_CAP3", p2.debug.capability("snapshot"), p2.debug.capability("breakpoints"))',
            "P2_DBG_CAP3 true false",
        ),
        (
            'print("P2_DBG_CAP4", p2.debug.capability("policy"))',
            "P2_DBG_CAP4 query_snapshots_only_no_breakpoints_or_trace_controls",
        ),
        (
            'print("P2_DBG_CAP5", p2.debug.capability("missing"))',
            "P2_DBG_CAP5 nil",
        ),
    ],
    "pasm-policy-min": [
        ('run_file("/tests/p2/pasmpol.be")', "P2_SMOKE_PASS pasm_policy_min"),
    ],
    "import-cache": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
    ],
    "import-churn": [
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
    ],
    "libraries": [
        ('run_file("/tests/p2/smoke_libraries.be")', "P2_SMOKE_PASS libraries"),
    ],
    "libraries-lazy-min": [
        ('run_file("/tests/p2/smoke_libraries_lazy_min.be")', "P2_SMOKE_PASS libraries_lazy_min"),
    ],
    "p2mem-policy-min": [
        (
            'm=run_file("/modules/p2mem.be"); g=m.gc_result(); print(m.capability("stats_result"), m.capability("gc_result"), m.audit_ok(), g["ok"])',
            "true true true true",
        ),
        (
            'print("P2_SMOKE_PASS p2mem_policy_min")',
            "P2_SMOKE_PASS p2mem_policy_min",
        ),
    ],
    "p2mem-native-cache-min": [
        (
            'm=run_file("/modules/p2mem.be"); print(m.native_cache_reset_result()["ok"])',
            "true",
        ),
        (
            'p=m.native_cache_put_verified("min","abc"); print(p["ok"], p["verified"], p["verify"]["ok"], p["write"]["last_write_checksum"])',
            "true true true 294",
        ),
        (
            'g=m.native_cache_get_verified("min"); print(g["ok"], g["verify"]["ok"], g["value"])',
            "true true abc",
        ),
        (
            'print(m.native_cache()["entry_count"])',
            "1",
        ),
        (
            'print("P2_SMOKE_PASS p2mem_native_cache_min")',
            "P2_SMOKE_PASS p2mem_native_cache_min",
        ),
    ],
    "bec-fallback-min": [
        ('run_file("/tests/p2/smoke_bec_fallback_min.be")', "P2_SMOKE_PASS bec_fallback_min"),
    ],
    "bec-abi-min": [
        ('run_file("/tests/p2/smoke_bec_load_min.be")', "P2_SMOKE_PASS bec_abi_min"),
    ],
    "core-builtins-min": [
        ('run_file("/tests/p2/call.be")', "P2_SMOKE_PASS call"),
        ('run_file("/tests/p2/vararg.be")', "P2_SMOKE_PASS vararg"),
        ('run_file("/tests/p2/cmod.be")', "P2_SMOKE_PASS compile_module"),
        ('run_file("/tests/p2/conv.be")', "P2_SMOKE_PASS conversions"),
        ('run_file("/tests/p2/listcore.be")', "P2_SMOKE_PASS list_core"),
        ('run_file("/tests/p2/mapcore.be")', "P2_SMOKE_PASS map_core"),
        ('run_file("/tests/p2/mapkeys.be")', "P2_SMOKE_PASS map_keys"),
        ('run_file("/tests/p2/bytes.be")', "P2_SMOKE_PASS bytes"),
    ],
    "sd-file-min": [
        ('run_file("/tests/p2/smoke_sd.be")', "P2_SMOKE_PASS sd"),
    ],
    "sd-file-core-min": [
        ('run_file("/tests/p2/smoke_sd_min.be")', "P2_SMOKE_PASS sd_file_core_min"),
    ],
    "stdlib-min": [
        ('run_file("/tests/p2/smoke_stdlib_min.be")', "P2_SMOKE_PASS stdlib_min"),
    ],
    "math-perf-min": [
        ('run_file("/tests/p2/mathperf.be")', "P2_SMOKE_PASS math_perf_min"),
    ],
    "priority1": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
        ('run_file("/tests/p2/smoke_libraries.be")', "P2_SMOKE_PASS libraries"),
    ],
    "priority1-min": [
        (
            'b=bytes(); print("P2_P1_BUILTINS", str(6*7), int("9"), real("2.5")>2, type(b), size(b), type([1]), type({"a":1}))',
            "P2_P1_BUILTINS 42 9 true instance 0 list map",
        ),
        (
            'l=[3,1,2]; l[1]=4; m={"a":1}; m["b"]=2; print("P2_P1_COLLECTIONS", l[0], l[1], l.size(), m["a"]+m["b"], size(m.keys())>=2)',
            "P2_P1_COLLECTIONS 3 4 3 3 true",
        ),
        (
            'f=open("/P1MIN.TXT","w"); f.write("ok"); f.close(); f=open("/P1MIN.TXT","r"); s=f.read(); f.close(); import os; os.remove("/P1MIN.TXT"); print("P2_P1_SD", s)',
            "P2_P1_SD ok",
        ),
        (
            'print("P2_SMOKE_PASS priority1_min")',
            "P2_SMOKE_PASS priority1_min",
        ),
    ],
    "priority2": [
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
        ('run_file("/tests/p2/smoke_smartpins_normal_pin.be")', "P2_SMOKE_PASS smartpins_normal_pin"),
        ('run_file("/tests/p2/smoke_smartpins_counter_modes.be")', "P2_SMOKE_PASS smartpins_counter_modes"),
        ('run_file("/tests/p2/smoke_smartpins_output_modes.be")', "P2_SMOKE_PASS smartpins_output_modes"),
        ('run_file("/tests/p2/smoke_smartpins_adc_dac_native.be")', "P2_SMOKE_PASS smartpins_adc_dac_native"),
        ('run_file("/tests/p2/smoke_smartpins_quadrature_motion.be")', "P2_SMOKE_PASS smartpins_quadrature_motion"),
        ('run_file("/tests/p2/smoke_smartpins_async_rx.be")', "P2_SMOKE_PASS smartpins_async_rx"),
        ('run_file("/tests/p2/smoke_smartpins_sync_diag.be")', "P2_SMOKE_PASS smartpins_sync_diag"),
    ],
    "priority3": [
        ('run_file("/tests/p2/pasmly.be")', "P2_SMOKE_PASS pasm_layout"),
        ('run_file("/tests/p2/pasmpol.be")', "P2_SMOKE_PASS pasm_policy_min"),
    ],
    "priority4": [
        (
            'import p2; a=p2.vm_copyable("ok"); b=p2.vm_copyable([1]); print("P2_VM_BOUNDARY", a["ok"], a["kind"], b["ok"], b["kind"])',
            "P2_VM_BOUNDARY true string false list",
        ),
        (
            'run_file("/tests/p2/p2compvm.be")',
            "P2_SMOKE_PASS p2compat_child_vm",
        ),
        ('run_file("/tests/p2/smoke_cog_closure_min.be")', "P2_SMOKE_PASS cog_closure_min"),
        (
            'import task; print(task.info()["max_tasks"], task.status(0))',
            "16 free",
        ),
        (
            'import p2ipc; c=p2ipc.capabilities(); k=p2ipc.contract(); print("P2_IPC_META", c["payload_result"], k["payload_result"], k["task_wait_integration"])',
            "P2_IPC_META true true true",
        ),
        (
            'ch=p2ipc.channel.new(1); ch.send_result(nil); r=ch.recv_result(); ch.close_result(); print("P2_IPC_CH_MIN", r["found"], r["value"]==nil)',
            "P2_IPC_CH_MIN true true",
        ),
        (
            'mb=p2ipc.mailbox.new(); mb.put_result("m"); g=mb.get_result(); mb.close_result(); print("P2_IPC_MB_MIN", g["found"], g["value"])',
            "P2_IPC_MB_MIN true m",
        ),
        (
            'b=p2ipc.shared.Buffer(2); x=b.fill_result(7); y=b.clear_result(); mx=p2ipc.mutex.new(); print("P2_IPC_RES_MIN", b.size(), x["ok"], y["ok"], b.read(0), mx.lock_result()["locked"], mx.unlock_result()["unlocked"], mx.close_result()["closed"])',
            "P2_IPC_RES_MIN 2 true true 0 true true true",
        ),
        (
            'print("P2_SMOKE_PASS p2ipc")',
            "P2_SMOKE_PASS p2ipc",
        ),
    ],
    "priority1-4": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
        ('run_file("/tests/p2/smoke_libraries.be")', "P2_SMOKE_PASS libraries"),
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
        ('run_file("/tests/p2/smoke_smartpins_loopback.be")', "P2_SMOKE_PASS smartpins_loopback"),
        ('run_file("/tests/p2/smoke_smartpins_counter_modes.be")', "P2_SMOKE_PASS smartpins_counter_modes"),
        ('run_file("/tests/p2/smoke_smartpins_async_rx.be")', "P2_SMOKE_PASS smartpins_async_rx"),
        ('run_file("/tests/p2/smoke_smartpins_sync_diag.be")', "P2_SMOKE_PASS smartpins_sync_diag"),
        ('run_file("/tests/p2/pasmly.be")', "P2_SMOKE_PASS pasm_layout"),
        ('run_file("/tests/p2/pasmpol.be")', "P2_SMOKE_PASS pasm_policy_min"),
        (
            'import p2; a=p2.vm_copyable("ok"); b=p2.vm_copyable([1]); print("P2_VM_BOUNDARY", a["ok"], a["kind"], b["ok"], b["kind"])',
            "P2_VM_BOUNDARY true string false list",
        ),
        (
            'run_file("/tests/p2/p2compvm.be")',
            "P2_SMOKE_PASS p2compat_child_vm",
        ),
        ('run_file("/tests/p2/smoke_cog_closure_min.be")', "P2_SMOKE_PASS cog_closure_min"),
        (
            'import task; print(task.info()["max_tasks"], task.status(0))',
            "16 free",
        ),
        (
            'import p2ipc; c=p2ipc.capabilities(); k=p2ipc.contract(); print("P2_IPC_META", c["payload_result"], k["payload_result"], k["task_wait_integration"])',
            "P2_IPC_META true true true",
        ),
        (
            'ch=p2ipc.channel.new(1); ch.send_result(nil); r=ch.recv_result(); ch.close_result(); print("P2_IPC_CH_MIN", r["found"], r["value"]==nil)',
            "P2_IPC_CH_MIN true true",
        ),
        (
            'mb=p2ipc.mailbox.new(); mb.put_result("m"); g=mb.get_result(); mb.close_result(); print("P2_IPC_MB_MIN", g["found"], g["value"])',
            "P2_IPC_MB_MIN true m",
        ),
        (
            'b=p2ipc.shared.Buffer(2); x=b.fill_result(7); y=b.clear_result(); mx=p2ipc.mutex.new(); print("P2_IPC_RES_MIN", b.size(), x["ok"], y["ok"], b.read(0), mx.lock_result()["locked"], mx.unlock_result()["unlocked"], mx.close_result()["closed"])',
            "P2_IPC_RES_MIN 2 true true 0 true true true",
        ),
        (
            'print("P2_SMOKE_PASS p2ipc")',
            "P2_SMOKE_PASS p2ipc",
        ),
    ],
    "priority1-4-min": [
        (
            'print("P2_CORE_MIN", 2+3, [1,2].size(), {"ok":true}["ok"])',
            "P2_CORE_MIN 5 2 true",
        ),
        (
            'run_file("/tests/p2/smoke_sd_min.be")',
            "P2_SMOKE_PASS sd_file_core_min",
        ),
        (
            'run_file("/tests/p2/smoke_stdlib_min.be")',
            "P2_SMOKE_PASS stdlib_min",
        ),
        (
            'run_file("/tests/p2/smoke_libraries_lazy_min.be")',
            "P2_SMOKE_PASS libraries_lazy_min",
        ),
        (
            'import p2; print("P2_API_MIN", type(p2.clock.freq()), type(p2.cog.id()), type(p2.pin.read(0)))',
            "P2_API_MIN int int int",
        ),
        ('mem=p2.heap_info(); ps=p2.psram_info(); ci=p2.psram_cache_info()', ""),
        (
            'print("P2_XMM_MIN", mem["external_heap"], ps["access"], ps["block_bytes"]>0, ci["available"], mem["main_inside_pointer_window"])',
            "P2_XMM_MIN true xmm+block true true true",
        ),
        (
            'import p2; s=p2.smart; p=p2.pin; s.clear(1); p.dir_high(0); p.low(0); s.start(1,s.count_highs,0,0); b=s.rdpin(1); print("P2_SMART_ARM")',
            "P2_SMART_ARM",
        ),
        (
            'p.high(0); p2.waitus(1000); p.low(0); a=s.rdpin(1); s.clear(1); p.float(0); p.float(1); print("P2_SMART_MIN", a>b)',
            "P2_SMART_MIN true",
        ),
        (
            's.clear(0); s.clear(1); s.wrpin(0,0); s.wrpin(1,0); p.float(0); p.float(1)',
            "",
        ),
        (
            's.start(1,s.count_highs,0,0); s.start(0,s.oe+s.pwm_triangle,200*65536+1,100); wb=s.rdpin(1)',
            "",
        ),
        (
            'p2.waitus(2000); wa=s.rdpin(1); s.clear(0); s.clear(1); p.float(0); p.float(1)',
            "",
        ),
        (
            'print("P2_SMART_PWM_MIN", wa>wb)',
            "P2_SMART_PWM_MIN true",
        ),
        (
            's.clear(0); s.clear(1); s.wrpin(0,0); s.wrpin(1,0); p.float(0); p.float(1)',
            "",
        ),
        (
            's.start(1,s.adc_1x+s.adc,32,0); s.start(0,s.oe+s.dac_990r_3v+s.dac_dither_pwm,256,0)',
            "",
        ),
        (
            's.wypin(0,0); p2.waitus(5000); al=s.rdpin(1); s.akpin(1)',
            "",
        ),
        (
            's.wypin(0,255); p2.waitus(5000); ah=s.rdpin(1); s.akpin(1)',
            "",
        ),
        (
            's.clear(0); s.clear(1); p.float(0); p.float(1); print("P2_SMART_ADC_DAC_MIN", ah!=al)',
            "P2_SMART_ADC_DAC_MIN true",
        ),
        (
            'import p2; s=p2.smart; p=p2.pin; c=p2.clock; x=c.freq()/115200*65536+7; tm=s.oe+s.async_tx; rm=s.async_rx',
            "",
        ),
        (
            's.clear(0); s.clear(1); s.wrpin(0,0); s.wrpin(1,0); p.float(0); p.float(1); s.start(0,tm,x,0); s.start(1,rm,x,0)',
            "",
        ),
        (
            's.wypin(0,0x12); s.wypin(0,0x34); c.waitus(5000); r=(s.rdpin(1)>>24)&255',
            "",
        ),
        (
            's.clear(0); s.clear(1); p.float(0); p.float(1); print("P2_SMART_ASYNC_MIN", r)',
            "P2_SMART_ASYNC_MIN 52",
        ),
        (
            'import p2; pa=p2.asm.fixture_add(20,22); print("P2_PASM_MIN", p2.asm.audit_ok(), pa["ok"], pa["result"])',
            "P2_PASM_MIN true true 42",
        ),
        ('ps=p2.asm.fixture_call("sub",50,8)', ""),
        ('px=p2.asm.fixture_call("xor",85,15)', ""),
        ('pb=p2.asm.fixture_call("and",85,15)', ""),
        ('po=p2.asm.fixture_call("or",80,15)', ""),
        (
            'print("P2_PASM_OPS_MIN", ps["ok"], ps["result"], px["ok"], px["result"], pb["ok"], pb["result"], po["ok"], po["result"])',
            "P2_PASM_OPS_MIN true 42 true 90 true 5 true 95",
        ),
        (
            'import p2; a=p2.vm_copyable("ok"); b=p2.vm_copyable([1]); print("P2_VM_MIN", a["ok"], a["kind"], b["ok"], b["kind"])',
            "P2_VM_MIN true string false list",
        ),
        (
            'bad=p2.vm_call_once(0,p2.heap_info()["vm_partition_bytes"],"def f(a) return 1 end","f",[1])',
            "",
        ),
        (
            'print("P2_VM_REJECT_MIN", bad["ok"], bad["status"], bad["first_arg_rejected_kind"], bad["partition_ready"])',
            "P2_VM_REJECT_MIN false args_rejected list false",
        ),
        (
            'v=p2.vm_call_once(0,p2.heap_info()["vm_partition_bytes"],"def f(a,b) return a+b end","f",20,22); print("P2_VM_CALL_MIN", v["ok"], v["result_int"], v["released"])',
            "P2_VM_CALL_MIN true 42 true",
        ),
        (
            'hb=p2.heap_info()["vm_partition_bytes"]; p2.vm_close(1); o=p2.vm_open(1,hb)',
            "",
        ),
        ('e=p2.vm_eval(1,"child_status_value=41")', ""),
        ('g=p2.vm_get(1,"child_status_value")', ""),
        ('cl=p2.vm_close(1); inf=p2.vm_info(1)', ""),
        (
            'print("P2_VM_LIFE_MIN", o["ok"], e["ok"], g["result_int"], cl["released"], inf["status"])',
            "P2_VM_LIFE_MIN true true 41 true inactive",
        ),
        (
            'import task; c=task.capabilities(); print("P2_TASK_MIN", task.info()["max_tasks"], task.status(0), c["spin2_compatible_names"], task.capability("max_tasks"), task.audit_ok())',
            "P2_TASK_MIN 16 free true 16 true",
        ),
        ('tc=task.contract(); te=task.execution_model()', ""),
        (
            'print("P2_TASK_POLICY_MIN", tc["scheduler_policy"], te["backend"], tc["preemptive"], tc["independent_stacks"])',
            "P2_TASK_POLICY_MIN current_vm_callback_step p2_native_cooperative false false",
        ),
        ('task.reset(); def p2_min_task() return task.done end', ""),
        (
            'th=task.spin(-1,p2_min_task); alive=task.chk(th); step=task.next(); print("P2_TASK_RUN_MIN", th, alive, step, task.status(th)); task.reset()',
            "P2_TASK_RUN_MIN 0 true 0 free",
        ),
        ('q=task.Queue(1); a=q.put_result(nil); g=q.get_result()', ""),
        ('sem=task.Semaphore(0); u=sem.take_result(); sem.give(); t=sem.take_result()', ""),
        ('mx=task.Mutex(); ml=mx.lock_result(); mbusy=mx.lock_result(); mu=mx.unlock_result()', ""),
        ('fl=task.EventFlags(); fs=fl.set_result(3); fr=fl.ready_result(3,"all")', ""),
        ('tm=task.Timer(0,false); te=tm.expired_result()', ""),
        (
            'print("P2_TASK_PRIM_MIN", a["ok"], g["value"]==nil, u["error"], t["ok"], ml["locked"], mbusy["error"], mu["ok"], fs["value"], fr["ready"], te["expired"])',
            "P2_TASK_PRIM_MIN true true unavailable true true busy true 3 true true",
        ),
        (
            'import p2ipc; c=p2ipc.capabilities(); k=p2ipc.contract(); print("P2_IPC_MIN", c["payload_result"], k["payload_result"], k["task_wait_integration"], p2ipc.audit_ok())',
            "P2_IPC_MIN true true true true",
        ),
        ('ip=p2ipc.payload_result("abc"); iq=p2ipc.payload_result([1,2])', ""),
        (
            'print("P2_IPC_PAY_MIN", ip["cross_vm_copyable"], ip["copyable_kind"], iq["cross_vm_copyable"], iq["copyable_kind"])',
            "P2_IPC_PAY_MIN true string false list",
        ),
        (
            'ch=p2ipc.channel.new(1); ch.send_result(nil); r=ch.recv_result(); ch.close_result(); print("P2_IPC_CH_MIN", r["found"], r["value"]==nil)',
            "P2_IPC_CH_MIN true true",
        ),
        (
            'mb=p2ipc.mailbox.new(); mb.put_result("m"); g=mb.get_result(); mb.close_result(); print("P2_IPC_MB_MIN", g["found"], g["value"])',
            "P2_IPC_MB_MIN true m",
        ),
        (
            'b=p2ipc.shared.Buffer(2); x=b.fill_result(7); y=b.clear_result(); mx=p2ipc.mutex.new(); print("P2_IPC_RES_MIN", b.size(), x["ok"], y["ok"], b.read(0), mx.lock_result()["locked"], mx.unlock_result()["unlocked"], mx.close_result()["closed"])',
            "P2_IPC_RES_MIN 2 true true 0 true true true",
        ),
        (
            'import p2; print("P2_COG_MIN", p2.cog.capability("handle_model"), p2.cog.audit_ok())',
            "P2_COG_MIN native_blink_info_stop_only true",
        ),
        (
            'cp=p2.cog.capability("isolated_child_vm_cog_policy"); cr=p2.cog.capability("isolated_child_vm_cog_reason")',
            "",
        ),
        (
            'print("P2_COG_ISO_MIN", cp, type(cr))',
            "P2_COG_ISO_MIN unsupported_catalina_xmm_c_cog_runtime_not_safe string",
        ),
        ('import p2; cg=p2.cog.cleanup_result()', ""),
        (
            'print("P2_COG_CLEAN_MIN", cg["registry_empty"], cg["released_handles"], cg["stopped_raw_cogs"])',
            "P2_COG_CLEAN_MIN true 0 0",
        ),
        (
            'def p2_min_blink(pin, rate) p2.pin.dir_high(pin); p2.pin.toggle(pin); return rate end',
            "",
        ),
        ('h=p2.cog.spawn(p2_min_blink,38,90); j=p2.cog.join(h)', ""),
        ('k=p2.cog.kill(h); ok=h>=100; rv=j["result"]; kr=k["slot_released"]', ""),
        (
            'p2.pin.float(38); print("P2_COG_BLINK_MIN", ok, rv, kr, p2.cog.info().size())',
            "P2_COG_BLINK_MIN true 90 true 0",
        ),
        (
            'print("P2_SMOKE_PASS priority1_4_min")',
            "P2_SMOKE_PASS priority1_4_min",
        ),
    ],
    "smartpins-loopback": [
        ('run_file("/tests/p2/smoke_smartpins_loopback.be")', "P2_SMOKE_PASS smartpins_loopback"),
    ],
    "smartpins-normal-pin": [
        ('run_file("/tests/p2/smoke_smartpins_normal_pin.be")', "P2_SMOKE_PASS smartpins_normal_pin"),
    ],
    "smartpins-quadrature-static": [
        ('run_file("/tests/p2/smoke_smartpins_quadrature_static.be")', "P2_SMOKE_PASS smartpins_quadrature_static"),
    ],
    "smartpins-quadrature-motion": [
        ('run_file("/tests/p2/smoke_smartpins_quadrature_motion.be")', "P2_SMOKE_PASS smartpins_quadrature_motion"),
    ],
    "smartpins-quadrature-diag": [
        (
            'm=run_file("/modules/p2smart.be"); p=m.quadrature_sample_probe(0,1,nil,1000)',
            "",
        ),
        (
            'assert(p["pin_a"] == 0); assert(p["pin_b"] == 1); assert(p["mode"] == m.smart.quadrature + m.smart.plus1_b); assert(type(p["sample"]["delta"]) == "int")',
            "",
        ),
        (
            'print("P2_SMOKE_QUADRATURE_DIAG",p["sample"]["before"],p["sample"]["after"],p["sample"]["delta"],p["sample"]["direction"],p["sample"]["moved"],m.status("quadrature"))',
            "P2_SMOKE_QUADRATURE_DIAG",
        ),
        (
            'print("P2_SMOKE_PASS smartpins_quadrature_diag")',
            "P2_SMOKE_PASS smartpins_quadrature_diag",
        ),
    ],
    "smartpins-counter-modes": [
        ('run_file("/tests/p2/smoke_smartpins_counter_modes.be")', "P2_SMOKE_PASS smartpins_counter_modes"),
    ],
    "smartpins-counter-timer-matrix": [
        ('run_file("/tests/p2/smoke_smartpins_counter_timer_matrix.be")', "P2_SMOKE_PASS smartpins_counter_timer_matrix"),
    ],
    "smartpins-output-modes": [
        ('run_file("/tests/p2/smoke_smartpins_output_modes.be")', "P2_SMOKE_PASS smartpins_output_modes"),
    ],
    "smartpins-adc-dac-native": [
        ('run_file("/tests/p2/smoke_smartpins_adc_dac_native.be")', "P2_SMOKE_PASS smartpins_adc_dac_native"),
    ],
    "smartpins-adc-variant-matrix": [
        ('run_file("/tests/p2/smoke_smartpins_adc_variant_matrix.be")', "P2_SMOKE_PASS smartpins_adc_variant_matrix"),
    ],
    "smartpins-adc-dac-diag": [
        (
            'm=run_file("/modules/p2smart.be"); p=m.adc_dac_delta_policy(); print(p["ok"], p["supported"], p["status"], p["safe_claim"])',
            "true false unverified setup_readback_only",
        ),
        (
            'p=m.dac_adc_sampled_probe(0,1,0,255,5000,0,4,250)',
            "",
        ),
        (
            'assert(p["sample_count"] == 4); assert(type(p["delta"]) == "int"); assert(type(p["abs_delta"]) == "int"); assert(!p["polarity_verified"]); assert(!p["calibrated_voltage"])',
            "",
        ),
        (
            'print("P2_SMOKE_ADC_DAC_DIAG",p["ok"],p["low"]["avg"],p["high"]["avg"],p["delta"],p["abs_delta"],p["polarity"])',
            "P2_SMOKE_ADC_DAC_DIAG",
        ),
        (
            'print("P2_SMOKE_PASS smartpins_adc_dac_diag")',
            "P2_SMOKE_PASS smartpins_adc_dac_diag",
        ),
    ],
    "smartpins-nco-duty-diag": [
        (
            'm=run_file("/modules/p2smart.be"); p=m.nco_duty_counter_probe(0,1,1,0x40000000,2000)',
            "",
        ),
        (
            'assert(p["nco_duty"]["prescaler"] == 1); assert(p["nco_duty"]["bit_period"] == 1); assert(p["nco_duty"]["value"] == 0x40000000); assert(p["ok"]); assert(p["counter"]["delta"] > 0)',
            "",
        ),
        (
            'print("P2_SMOKE_NCO_DUTY_DIAG",p["ok"],p["counter"]["before"],p["counter"]["after"],p["counter"]["delta"])',
            "P2_SMOKE_NCO_DUTY_DIAG",
        ),
        (
            'print("P2_SMOKE_PASS smartpins_nco_duty_diag")',
            "P2_SMOKE_PASS smartpins_nco_duty_diag",
        ),
    ],
    "smartpins-async-rx": [
        ('run_file("/tests/p2/smoke_smartpins_async_rx.be")', "P2_SMOKE_PASS smartpins_async_rx"),
    ],
    "smartpins-async-buffer-boundary": [
        ('run_file("/tests/p2/smoke_smartpins_async_buffer_boundary.be")', "P2_SMOKE_PASS smartpins_async_buffer_boundary"),
    ],
    "smartpins-sync-diag": [
        ('run_file("/tests/p2/smoke_smartpins_sync_diag.be")', "P2_SMOKE_PASS smartpins_sync_diag"),
    ],
    "soak": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
        ('run_file("/tests/p2/smoke_libraries.be")', "P2_SMOKE_PASS libraries"),
        ('run_file("/tests/p2/smoke_task.be")', "P2_SMOKE_PASS task"),
        ('run_file("/tests/p2/smoke_cog_closure.be")', "P2_SMOKE_PASS cog_closure"),
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
        ("import p2; print(type(p2.gc), p2.gc())", "function"),
    ],
    "soak-smartpins": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
        ('run_file("/tests/p2/smoke_task.be")', "P2_SMOKE_PASS task"),
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
        ('run_file("/tests/p2/smoke_smartpins_loopback.be")', "P2_SMOKE_PASS smartpins_loopback"),
        ('run_file("/tests/p2/smoke_smartpins_output_modes.be")', "P2_SMOKE_PASS smartpins_output_modes"),
        ('run_file("/tests/p2/smoke_smartpins_adc_dac_native.be")', "P2_SMOKE_PASS smartpins_adc_dac_native"),
        ('run_file("/tests/p2/smoke_smartpins_async_rx.be")', "P2_SMOKE_PASS smartpins_async_rx"),
        ('run_file("/tests/p2/smoke_smartpins_sync_diag.be")', "P2_SMOKE_PASS smartpins_sync_diag"),
        ("import p2; print(type(p2.gc), p2.gc())", "function"),
    ],
    "soak-smartpins-focused": [
        ('run_file("/tests/p2/impcache.be")', "P2_SMOKE_PASS import_cache"),
        ('run_file("/tests/p2/impchurn.be")', "P2_SMOKE_PASS import_churn"),
        ('run_file("/tests/p2/smoke_task.be")', "P2_SMOKE_PASS task"),
        ('run_file("/tests/p2/smoke_p2_api.be")', "P2_SMOKE_PASS p2_api"),
        ('run_file("/tests/p2/smoke_smartpins_normal_pin.be")', "P2_SMOKE_PASS smartpins_normal_pin"),
        ('run_file("/tests/p2/smoke_smartpins_counter_modes.be")', "P2_SMOKE_PASS smartpins_counter_modes"),
        ('run_file("/tests/p2/smoke_smartpins_output_modes.be")', "P2_SMOKE_PASS smartpins_output_modes"),
        ('run_file("/tests/p2/smoke_smartpins_adc_dac_native.be")', "P2_SMOKE_PASS smartpins_adc_dac_native"),
        ('run_file("/tests/p2/smoke_smartpins_quadrature_motion.be")', "P2_SMOKE_PASS smartpins_quadrature_motion"),
        ('run_file("/tests/p2/smoke_smartpins_async_rx.be")', "P2_SMOKE_PASS smartpins_async_rx"),
        ('run_file("/tests/p2/smoke_smartpins_sync_diag.be")', "P2_SMOKE_PASS smartpins_sync_diag"),
        ("import p2; print(type(p2.gc), p2.gc())", "function"),
    ],
    "cog-ping": [
        ("import p2", ""),
        ("ping=p2.vm_cog_ping(41)", ""),
        ('print(ping["started"], ping["status"], ping["result"], ping["raw_running"], ping["stack_freed"], ping["wait_count"])', "true 3 83 false true"),
        ('print(p2.heap_info()["wrong_free_count"])', "0"),
        ('print("P2_SMOKE_PASS cog_ping")', "P2_SMOKE_PASS cog_ping"),
    ],
    "vm-cog": [
        ("import p2", ""),
        ('slot=0', ""),
        ('opened=p2.vm_open(slot,p2.heap_info()["vm_partition_bytes"])', ""),
        ('print(opened["partition_ready"], opened["child_created"] || opened["already_active"])', "true true"),
        ('loaded=p2.vm_eval(slot,"def cog_add(a,b) return a+b end")', ""),
        ('print(loaded["active"], loaded["run_result"])', "true 0"),
        ('run=p2.vm_cog_start(slot,"cog_add",19,23)', ""),
        ('print(run["started"], run["status"], run["raw_running"], run["stack_freed"])', "true 2 false true"),
        ('print(run["function_found"], run["call_result"], run["result_type"], run["result_int"])', "true 0 1 42"),
        ('print(run["wrong_free_delta"], run["wrong_realloc_delta"])', "0 0"),
        ("closed=p2.vm_close(slot)", ""),
        ('print(closed["active"], closed["released"])', "false true"),
        ('print("P2_SMOKE_PASS vm_cog")', "P2_SMOKE_PASS vm_cog"),
    ],
    "vm-cog-once": [
        ("import p2", ""),
        ('src="def cog_add(a,b) return a+b end"', ""),
        ('run=p2.vm_cog_call_once(0,p2.heap_info()["vm_partition_bytes"],src,"cog_add",19,23)', ""),
        ('print(run["started"], run["status"], run["raw_running"], run["stack_freed"], run["released"])', "true 2 false true true"),
        ('print(run["partition_ready"], run["selected"], run["child_created"], run["child_deleted"])', "true true true true"),
        ('print(run["function_found"], run["source_result"], run["call_result"], run["result_type"], run["result_int"])', "true 0 0 1 42"),
        ('print(run["wrong_free_delta"], run["wrong_realloc_delta"], run["current"])', "0 0 -1"),
        ('print("P2_SMOKE_PASS vm_cog_once")', "P2_SMOKE_PASS vm_cog_once"),
    ],
    "xmm-heap": [
        ("import p2", ""),
        ("print(type(p2.gc), p2.gc())", "function"),
        (
            'print(p2.heap_info()["pointer_window_bytes"], p2.heap_info()["psram_block_base"], p2.heap_info()["psram_block_bytes"], p2.heap_info()["main_inside_pointer_window"])',
            "16777216 16777216 16777216 true",
        ),
        ('baseline=p2.heap_info()["main"]', ""),
        ("batch=[]", ""),
        ("i=0", ""),
        (
            'while i<512 batch.push({"index":i,"payload":str(i)+":"+("x"*(384+(i%5)*16)),"pair":[i,i+1]}); i=i+1 end',
            "",
        ),
        ('print(size(batch), baseline-p2.heap_info()["main"], p2.heap_info()["main_crosses_block_window"])', "512"),
        ("batch=nil", ""),
        ("print(p2.gc())", "freed"),
        ('print(p2.heap_info()["main_crosses_block_window"], p2.heap_info()["main"]>=baseline-262144)', "false true"),
    ],
    "xmm-heap-cross": [
        ("import p2", ""),
        ("print(type(p2.gc), p2.gc())", "function"),
        ('baseline=p2.heap_info()["main"]', ""),
        ("batch=[]", ""),
        ("i=0", ""),
        ('while i<1280 batch.push(str(i)+":"+("z"*3584)); i=i+1 end', ""),
        (
            'print(size(batch), baseline-p2.heap_info()["main"]>4194304, p2.heap_info()["main_crosses_block_window"])',
            "1280 true false",
        ),
        ("batch=nil", ""),
        ("print(p2.gc())", "freed"),
        ('print(p2.heap_info()["main_crosses_block_window"], p2.heap_info()["main"]>=baseline-524288)', "false true"),
    ],
    "xmm-vm-probe": [
        ("import p2", ""),
        ("mem=p2.heap_info(); ps=p2.psram_info()", ""),
        (
            'print(mem["pointer_window_bytes"], mem["pointer_heap_limit"], mem["psram_block_base"], mem["psram_block_bytes"], mem["main_inside_pointer_window"])',
            "16777216 16777216 16777216 16777216 true",
        ),
        (
            'print(ps["pointer_window_bytes"], ps["pointer_heap_limit"], ps["cache_base"], ps["cache_bytes"], ps["access"])',
            "16777216 16777216 16777216 16777216 xmm+block",
        ),
        ("rz=p2.psram_cache_reset(); ci=p2.psram_cache_info()", ""),
        ('print(rz["ok"], rz["next"], rz["alloc_count"])', "true 16777216 0"),
        (
            'print(ci["available"], ci["base"], ci["limit"], ci["libstore_base"], ci["limit"]==ci["libstore_base"])',
            "true 16777216 32505856 32505856 true",
        ),
        ('cr=p2.psram_cache_reserve(64,"xmm-vm-probe")', ""),
        (
            'print(cr["ok"], cr["index"], cr["address"]>=ci["base"], cr["address"]+cr["size"]<=ci["limit"], cr["size"], cr["owner"], cr["libstore_base"]==ci["libstore_base"])',
            "true 0 true true 64 xmm-vm-probe true",
        ),
        ('ci2=p2.psram_cache_info(); ce=p2.psram_cache_entries(); cf=p2.psram_cache_find("xmm-vm-probe"); print(ci2["next"]==cr["next"], ci2["used"]>=64, ci2["free"]<ci["free"], ci2["alloc_count"], ci2["entry_count"], size(ce), size(cf))', "true true true 1 1 1 1"),
        ('print(ce[0]["address"]==cr["address"], ce[0]["size"], ce[0]["used"], ce[0]["owner"])', "true 64 0 xmm-vm-probe"),
        ('print(cf[0]["index"], cf[0]["address"]==cr["address"], cf[0]["used"], cf[0]["owner"])', "0 true 0 xmm-vm-probe"),
        ('cfl=p2.psram_cache_find_latest("xmm-vm-probe"); print(cfl["found"], cfl["index"], cfl["owner"])', "true 0 xmm-vm-probe"),
        ('cw=p2.psram_cache_write_entry(cr["index"],0,"cache"); print(cw["ok"], cw["index"], cw["owner"], cw["size"], cw["used"], cw["write_count"], cw["last_write_checksum"], p2.psram_cache_read_entry(cr["index"],0,5))', "true 0 xmm-vm-probe 5 5 1 500 cache"),
        ('cu=p2.psram_cache_entries(); print(cu[0]["used"], cu[0]["write_count"], cu[0]["last_write_offset"], cu[0]["last_write_size"], cu[0]["last_write_checksum"])', "5 1 0 5 500"),
        ('cv=p2.psram_cache_verify_entry(cr["index"]); print(cv["ok"], cv["has_write"], cv["expected"], cv["actual"], cv["owner"])', "true true 500 500 xmm-vm-probe"),
        ('rl=p2.psram_cache_release(cr["index"]); print(rl["released"], rl["next"]==ci["base"], rl["entry_count"])', "true true 0"),
        ('rr=p2.psram_cache_reserve(32,"xmm-vm-probe-reuse"); print(rr["ok"], rr["index"], rr["address"]==ci["base"], rr["size"])', "true 0 true 32"),
        ("lk0=p2.vm_lock_info()", ""),
        ('print(lk0["available"], lk0["failed"], lk0["acquires"], lk0["contentions"])', "true false 0 0"),
        ('probe=p2.vm_probe(0,p2.heap_info()["vm_partition_bytes"],"child_value=6*7")', ""),
        (
            'print(probe["partition_ready"], probe["selected"], probe["child_created"], probe["child_deleted"], probe["child_ran"])',
            "true true true true true",
        ),
        ('print(probe["child_run_result"], probe["child_stack_top"])', "0 0"),
        (
            'print(probe["wrong_free_delta"], probe["wrong_realloc_delta"], probe["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'print(p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_current"], p2.heap_info()["wrong_free_count"], p2.heap_info()["wrong_realloc_count"])',
            "1 -1 0 0",
        ),
        ('many=p2.vm_probe_many(2,p2.heap_info()["vm_partition_bytes"],"child_value=7*8")', ""),
        (
            'print(many["partition_ready_count"], many["selected_count"], many["child_created_count"], many["child_deleted_count"], many["child_ran_count"], many["child_run_ok_count"])',
            "2 2 2 2 2 2",
        ),
        (
            'print(many["child_stack_clean_count"], many["wrong_free_delta"], many["wrong_realloc_delta"], many["vm_partition_current"], many["first_failure_slot"], many["last_run_result"])',
            "2 0 0 -1 -1 0",
        ),
        (
            'print(p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_current"], p2.heap_info()["wrong_free_count"], p2.heap_info()["wrong_realloc_count"])',
            "2 -1 0 0",
        ),
        (
            'call=p2.vm_call_probe(2,p2.heap_info()["vm_partition_bytes"],"def add(a,b) return a+b end","add",19,23)',
            "",
        ),
        (
            'print(call["partition_ready"], call["selected"], call["child_created"], call["child_deleted"], call["function_found"])',
            "true true true true true",
        ),
        (
            'print(call["source_result"], call["call_result"], call["result_type"], call["result_int"])',
            "0 0 1 42",
        ),
        (
            'print(call["wrong_free_delta"], call["wrong_realloc_delta"], call["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'callstr=p2.vm_call_probe(3,p2.heap_info()["vm_partition_bytes"],"def label() return \\"child-ok\\" end","label")',
            "",
        ),
        ('print(callstr["source_result"], callstr["call_result"], callstr["result_type"], callstr["result_string"])', "0 0 4 child-ok"),
        (
            'print(callstr["wrong_free_delta"], callstr["wrong_realloc_delta"], callstr["vm_partition_current"])',
            "0 0 -1",
        ),
        (
            'callargs=p2.vm_call_probe(3,p2.heap_info()["vm_partition_bytes"],"def mix(a,b,c,d) if b && c==nil return a+str(d) end return \\"bad\\" end","mix","child-",true,nil,42)',
            "",
        ),
        (
            'print(callargs["source_result"], callargs["call_result"], callargs["result_type"], callargs["result_string"])',
            "0 0 4 child-42",
        ),
        (
            'print(callargs["arg_string_count"], callargs["arg_bool_count"], callargs["arg_nil_count"], callargs["arg_int_count"])',
            "1 1 1 1",
        ),
        (
            'print(callargs["wrong_free_delta"], callargs["wrong_realloc_delta"], callargs["vm_partition_current"])',
            "0 0 -1",
        ),
        ("info0=p2.vm_partition_info(0); info1=p2.vm_partition_info(1)", ""),
        ('print(info0["ready"], info1["ready"], info0["current"], info1["current"])', "true true -1 -1"),
        ('print(info0["bytes"]>0, info1["bytes"]>0, info0["free"]>0, info1["free"]>0)', "true true true true"),
        (
            'print(p2.heap_info()["vm_partition_capacity"]>=p2.heap_info()["vm_partition_created"], p2.heap_info()["vm_partition_free_capacity"]>=0)',
            "true true",
        ),
        (
            'print(p2.vm_copyable(nil)["ok"], p2.vm_copyable(true)["ok"], p2.vm_copyable(42)["ok"], p2.vm_copyable("ok")["ok"])',
            "true true true true",
        ),
        ("def vm_copyable_test_fn() return 1 end", ""),
        (
            'print(p2.vm_copyable([1])["ok"], p2.vm_copyable({"a":1})["ok"], p2.vm_copyable(vm_copyable_test_fn)["ok"])',
            "false false false",
        ),
        (
            'api=p2.vm_call(0,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",5,37)',
            "",
        ),
        ('print(api["source_result"], api["call_result"], api["result_type"], api["result_int"])', "0 0 1 42"),
        ('print(api["wrong_free_delta"], api["wrong_realloc_delta"], api["vm_partition_current"])', "0 0 -1"),
        ("def bridge_add(a,b) return a+b end", ""),
        (
            'bridge=p2.vm_call(0,p2.heap_info()["vm_partition_bytes"],"def bridge_add(a,b) return a+b end",bridge_add,13,29)',
            "",
        ),
        ('print(bridge["source_result"], bridge["call_result"], bridge["result_type"], bridge["result_int"])', "0 0 1 42"),
        ('print(bridge["wrong_free_delta"], bridge["wrong_realloc_delta"], bridge["vm_partition_current"])', "0 0 -1"),
        ("rel3=p2.vm_partition_release(3)", ""),
        ('print(rel3["released"], rel3["was_ready"], rel3["ready"], rel3["current"])', "true true false -1"),
        (
            'print(rel3["after_created"]<rel3["before_created"], rel3["after_total"]<rel3["before_total"], rel3["after_main"]>rel3["before_main"])',
            "true true true",
        ),
        (
            'again=p2.vm_call(3,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",20,22)',
            "",
        ),
        ('print(again["source_result"], again["call_result"], again["result_type"], again["result_int"])', "0 0 1 42"),
        ("rel3b=p2.vm_partition_release(3)", ""),
        ('print(rel3b["released"], rel3b["was_ready"], rel3b["ready"], rel3b["current"])', "true true false -1"),
        (
            'once=p2.vm_call_once(3,p2.heap_info()["vm_partition_bytes"],"def api_add(a,b) return a+b end","api_add",21,21)',
            "",
        ),
        ('print(once["source_result"], once["call_result"], once["result_type"], once["result_int"])', "0 0 1 42"),
        ('print(once["release_attempted"], once["released"], once["partition_ready_after"], once["vm_partition_current"])', "true true false -1"),
        (
            'print(once["release_after_created"]<once["release_before_created"], once["release_after_total"]<once["release_before_total"], once["release_after_main"]>once["release_before_main"])',
            "true true true",
        ),
        ("h=p2.vm_open(3,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h["partition_ready"], h["selected"], h["child_created"], h["active"], h["current"])', "true true true true -1"),
        ('e1=p2.vm_eval(3,"child_persist=10")', ""),
        ('print(e1["active"], e1["selected"], e1["run_result"], e1["stack_top"], e1["current"])', "true true 0 0 -1"),
        ('e2=p2.vm_eval(3,"child_persist=child_persist+32")', ""),
        ('print(e2["active"], e2["selected"], e2["run_result"], e2["stack_top"], e2["current"])', "true true 0 0 -1"),
        ('g=p2.vm_get(3,"child_persist")', ""),
        ('print(g["active"], g["selected"], g["found"], g["result_type"], g["result_int"], g["current"])', "true true true 1 42 -1"),
        ('efn=p2.vm_eval(3,"def child_add(a,b) return a+b+child_persist end")', ""),
        ('print(efn["active"], efn["selected"], efn["run_result"], efn["stack_top"], efn["current"])', "true true 0 0 -1"),
        ('inv=p2.vm_invoke(3,"child_add",10,20)', ""),
        ('print(inv["active"], inv["selected"], inv["function_found"], inv["call_result"], inv["result_type"], inv["result_int"], inv["current"])', "true true true 0 1 72 -1"),
        ('print(inv["wrong_free_delta"], inv["wrong_realloc_delta"], inv["child_stack_top"])', "0 0 0"),
        ("closed=p2.vm_close(3)", ""),
        ('print(closed["was_active"], closed["child_deleted"], closed["released"], closed["active"], closed["partition_ready_after"], closed["current"])', "true true true false false -1"),
        (
            'print(closed["release_after_created"]<closed["release_before_created"], closed["release_after_total"]<closed["release_before_total"], closed["release_after_main"]>closed["release_before_main"])',
            "true true true",
        ),
        ("h2=p2.vm_open(2,p2.heap_info()[\"vm_partition_bytes\"]); h3=p2.vm_open(3,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h2["active"], h3["active"], h2["current"], h3["current"])', "true true -1 -1"),
        ('m2=p2.vm_eval(2,"child_id=200"); m3=p2.vm_eval(3,"child_id=300")', ""),
        ('print(m2["run_result"], m3["run_result"], m2["current"], m3["current"])', "0 0 -1 -1"),
        ('m2b=p2.vm_eval(2,"child_id=child_id+21"); m3b=p2.vm_eval(3,"child_id=child_id+33")', ""),
        ('print(m2b["run_result"], m3b["run_result"], m2b["current"], m3b["current"])', "0 0 -1 -1"),
        ('f2=p2.vm_eval(2,"def bump(a) child_id=child_id+a return child_id end"); f3=p2.vm_eval(3,"def bump(a) child_id=child_id+a return child_id end")', ""),
        ('i2=p2.vm_invoke(2,"bump",5); i3=p2.vm_invoke(3,"bump",7)', ""),
        ('print(i2["result_int"], i3["result_int"], i2["current"], i3["current"])', "226 340 -1 -1"),
        ('g2=p2.vm_get(2,"child_id"); g3=p2.vm_get(3,"child_id")', ""),
        ('print(g2["result_int"], g3["result_int"], g2["current"], g3["current"])', "226 340 -1 -1"),
        ('print(p2.vm_partition_info(2)["ready"], p2.vm_partition_info(3)["ready"])', "true true"),
        ("c2=p2.vm_close(2); c3=p2.vm_close(3)", ""),
        ('print(c2["child_deleted"], c2["released"], c2["partition_ready_after"], c3["child_deleted"], c3["released"], c3["partition_ready_after"])', "true true false true true false"),
        ("lk1=p2.vm_lock_info()", ""),
        ('print(lk1["available"], lk1["failed"], lk1["acquires"]>0, lk1["contentions"]>=0)', "true false true true"),
    ],
    "xmm-vm-cog": [
        ("import p2", ""),
        ("lk0=p2.vm_lock_info()", ""),
        ('print(lk0["available"], lk0["failed"])', "true false"),
        ("h=p2.vm_open(2,p2.heap_info()[\"vm_partition_bytes\"])", ""),
        ('print(h["partition_ready"], h["selected"], h["child_created"], h["active"], h["current"])', "true true true true -1"),
        ('e=p2.vm_eval(2,"child_id=100; def bump(a) child_id=child_id+a return child_id end")', ""),
        ('print(e["active"], e["selected"], e["run_result"], e["stack_top"], e["current"])', "true true 0 0 -1"),
        ('cs=p2.vm_cog_start(2,"bump",9)', ""),
        ('print(cs["started"], cs["status"], cs["function_found"], cs["call_result"], cs["result_type"], cs["result_int"], cs["current"])', "true 2 true 0 1 109 -1"),
        ('post=p2.vm_get(2,"child_id")', ""),
        ('print(post["active"], post["selected"], post["found"], post["result_type"], post["result_int"], post["current"])', "true true true 1 109 -1"),
        ("closed=p2.vm_close(2)", ""),
        ('print(closed["was_active"], closed["child_deleted"], closed["released"], closed["active"], closed["partition_ready_after"], closed["current"])', "true true true false false -1"),
        ("lk1=p2.vm_lock_info()", ""),
        ('print(lk1["available"], lk1["failed"], lk1["acquires"]>0, lk1["contentions"]>=0)', "true false true true"),
    ],
    "xmm-cog-ping": [
        ("import p2", ""),
        ("ping=p2.vm_cog_ping(41)", ""),
        ('print(ping["started"], ping["status"], ping["result"], ping["raw_running"], ping["stack_freed"], ping["thread_mode"], ping["current"])', "true 2 83 false true true -1"),
        ("print(6*7)", "42"),
    ],
    "xmm-p2mem-native-cache": [
        ("import p2", ""),
        ("import p2mem", ""),
        ("rz=p2mem.native_cache_reset()", ""),
        ('print(rz["ok"], rz["entry_count"], rz["alloc_count"])', "true 0 0"),
        ('before=p2mem.native_cache(); print(before["available"], before["entry_count"], before["free"]>15000000)', "true 0 true"),
        ('r=p2mem.native_cache_reserve(96,"p2mem-smoke")', ""),
        ('print(r["ok"], r["index"], r["size"], r["owner"])', "true 0 96 p2mem-smoke"),
        ('found=p2mem.native_cache_find("p2mem-smoke"); print(size(found), found[0]["index"], found[0]["owner"])', "1 0 p2mem-smoke"),
        ('w=p2mem.native_cache_write(r["index"],8,"p2mem-cache"); print(w["ok"], w["index"], w["offset"], w["owner"], w["size"], w["used"], w["write_count"], w["last_write_checksum"])', "true 0 8 p2mem-smoke 11 19 1 1026"),
        ('print(p2mem.native_cache_read(r["index"],8,11))', "p2mem-cache"),
        ('mid=p2mem.native_cache(); print(mid["entry_count"], mid["used"]>=96, mid["entries"][0]["used"], mid["entries"][0]["write_count"], mid["entries"][0]["last_write_size"], mid["entries"][0]["last_write_checksum"], mid["entries"][0]["owner"])', "1 true 19 1 11 1026 p2mem-smoke"),
        ('stats=p2mem.stats(); cache=p2mem.cache(); print(stats["native_cache_items"], cache["native"]["entry_count"])', "1 1"),
        ('rel=p2mem.native_cache_release(r["index"]); print(rel["released"], rel["entry_count"], rel["next"]==before["base"])', "true 0 true"),
        ('blob=p2mem.native_cache_put("p2mem-blob","blob-data"); print(blob["ok"], blob["index"], blob["write"]["used"], blob["write"]["write_count"], blob["write"]["last_write_checksum"], p2mem.native_cache_get("p2mem-blob"))', "true 0 9 1 870 blob-data"),
        ('bv=p2mem.native_cache_verify_owner("p2mem-blob"); print(bv["ok"], bv["found"], bv["expected"], bv["actual"], bv["owner"])', "true true 870 870 p2mem-blob"),
        ('bg=p2mem.native_cache_get_verified("p2mem-blob"); print(bg["ok"], bg["found"], bg["verify"]["ok"], bg["value"])', "true true true blob-data"),
        ('bs=p2mem.native_cache_status("p2mem-blob"); print(bs["ok"], bs["found"], bs["verified"], bs["used"], bs["last_write_checksum"])', "true true true 9 870"),
        ('bp=p2mem.native_cache_put_verified("p2mem-verified","checked"); print(bp["ok"], bp["verified"], bp["verify"]["ok"], bp["write"]["last_write_checksum"], p2mem.native_cache_get_verified("p2mem-verified")["value"])', "true true true 711 checked"),
        ('blob2=p2mem.native_cache_put("p2mem-blob","new-data"); latest=p2mem.native_cache_find_latest("p2mem-blob"); print(blob2["ok"], latest["found"], latest["index"], latest["used"], p2mem.native_cache_get("p2mem-blob"))', "true true 1 8 new-data"),
        ('rep=p2mem.native_cache_replace("p2mem-blob","final-data"); print(rep["ok"], rep["replaced"], rep["release"]["released"], rep["index"], p2mem.native_cache_get("p2mem-blob"))', "true true true 1 final-data"),
        ('rv=p2mem.native_cache_replace_verified("p2mem-blob","verified-final"); print(rv["ok"], rv["verified"], rv["verify"]["ok"], rv["write"]["last_write_checksum"], p2mem.native_cache_get_verified("p2mem-blob")["value"])', "true true true 1415 verified-final"),
        ('hist=p2mem.native_cache_owner_history("p2mem-blob"); print(size(hist), hist[0]["index"], hist[1]["index"])', "2 0 1"),
        ('drop=p2mem.native_cache_release_owner_chain("p2mem-blob"); print(drop["ok"], drop["released_count"], size(drop["remaining"]))', "true 2 0"),
        ('src=p2mem.native_source_put_verified("demo","print(6*7)"); print(src["ok"], src["verified"], src["write"]["used"], src["write"]["last_write_checksum"])', "true true 10 821"),
        ('ss=p2mem.native_source_status("demo"); print(ss["ok"], ss["found"], ss["verified"], ss["used"], ss["last_write_checksum"])', "true true true 10 821"),
        ('sg=p2mem.native_source_get_verified("demo"); print(sg["ok"], sg["verify"]["ok"], sg["value"])', "true true print(6*7)"),
        ('sr=p2mem.native_source_release("demo"); print(sr["ok"], sr["released_count"], size(sr["remaining"]))', "true 1 0"),
        ('plan=p2mem.native_module_sources_plan(["p2mem"]); print(plan["ok"], plan["requested"], plan["found_count"], plan["missing_count"], plan["total_bytes"]>100, plan["total_reserved_bytes"]>=plan["total_bytes"], plan["cache_free"]>plan["total_reserved_bytes"], plan["will_fit"], plan["items"][0]["owner"])', "true 1 1 0 true true true true module-source:p2mem"),
        ('ms=p2mem.native_module_source_put_verified("p2mem"); print(ms["ok"], ms["found"], ms["verified"], ms["write"]["used"]>100)', "true true true true"),
        ('mt=p2mem.native_module_source_status("p2mem"); print(mt["ok"], mt["found"], mt["verified"], mt["used"]==ms["write"]["used"])', "true true true true"),
        ('mg=p2mem.native_module_source_get_verified("p2mem"); print(mg["ok"], mg["verify"]["ok"], size(mg["value"])==ms["write"]["used"])', "true true true"),
        ('mr=p2mem.native_module_source_release("p2mem"); print(mr["ok"], mr["released_count"], size(mr["remaining"]))', "true 1 0"),
        ('warm=p2mem.native_module_sources_warm_verified(["p2mem"]); print(warm["ok"], warm["requested"], warm["ok_count"], warm["fail_count"], warm["items"][0]["module"])', "true 1 1 0 p2mem"),
        ('wstat=p2mem.native_module_sources_status(["p2mem"]); print(wstat["ok"], wstat["requested"], wstat["ok_count"], wstat["missing_count"], wstat["items"][0]["verified"])', "true 1 1 0 true"),
        ('wr=p2mem.native_module_sources_release(["p2mem"]); print(wr["ok"], wr["requested"], wr["released_count"], wr["fail_count"])', "true 1 1 0"),
        ('wfit=p2mem.native_module_sources_warm_if_fits(["p2mem"]); print(wfit["ok"], wfit["warmed"], wfit["reason"], wfit["plan"]["will_fit"], wfit["warm"]["ok_count"])', "true true ok true 1"),
        ('wfr=p2mem.native_module_sources_release(["p2mem"]); print(wfr["ok"], wfr["released_count"], wfr["fail_count"])', "true 1 0"),
    ],
}

LINE_ENDINGS = {
    "cr": b"\r",
    "lf": b"\n",
    "crlf": b"\r\n",
}


def load_serial_module():
    try:
        import serial  # type: ignore

        return serial
    except ImportError:
        print("error: pyserial is required: python3 -m pip install pyserial", file=sys.stderr)
        raise SystemExit(2)


def decode(data: bytes) -> str:
    return data.decode("utf-8", errors="replace")


def read_until(ser, marker: bytes, timeout: float) -> bytes:
    deadline = time.monotonic() + timeout
    data = bytearray()
    while time.monotonic() < deadline:
        chunk = ser.read(256)
        if chunk:
            data.extend(chunk)
            if marker in data:
                return bytes(data)
        else:
            time.sleep(0.02)
    raise TimeoutError(f"timed out waiting for {marker!r}; saw:\n{decode(bytes(data))}")


BERRY_ERROR_PREFIXES = (
    "assert_failed:",
    "attribute_error:",
    "compile_error:",
    "divzero_error:",
    "index_error:",
    "io_error:",
    "key_error:",
    "memory_error:",
    "syntax_error:",
    "type_error:",
    "unsupported_error:",
    "value_error:",
)


def berry_error_text(text: str) -> str:
    if "stack traceback:" in text:
        return "stack traceback:"
    for line in text.splitlines():
        stripped = line.strip()
        for prefix in BERRY_ERROR_PREFIXES:
            if stripped.startswith(prefix):
                return stripped
    return ""


def run_command(
    ser,
    command: str,
    expected: str,
    line_ending: bytes,
    prompt: bytes,
    timeout: float,
    input_marker: str = "",
    input_text: str = "",
) -> str:
    ser.write(command.encode("utf-8") + line_ending)
    ser.flush()
    prefix = ""
    if input_marker:
        marker_output = read_until(ser, input_marker.encode("utf-8"), timeout)
        prefix = decode(marker_output)
        ser.write(input_text.encode("utf-8") + line_ending)
        ser.flush()
    output = read_until(ser, prompt, timeout)
    text = prefix + decode(output)
    error = berry_error_text(text)
    if error:
        raise RuntimeError(f"Berry command failed ({error}) after {command!r}; saw:\n{text}")
    if expected and expected not in text:
        raise AssertionError(
            f"expected {expected!r} after command {command!r}; saw:\n{text}"
        )
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Berry P2 REPL smoke commands over serial.")
    parser.add_argument("--port", required=True, help="serial device, for example /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=230400, help="serial baud rate")
    parser.add_argument("--suite", choices=sorted(SUITES), default="full")
    parser.add_argument(
        "--command",
        action="append",
        default=[],
        help="custom Berry command to run instead of a built-in suite; repeat for multiple commands",
    )
    parser.add_argument(
        "--expect",
        action="append",
        default=[],
        help="expected output substring for the matching --command; repeat to match commands",
    )
    parser.add_argument(
        "--input-marker",
        action="append",
        default=[],
        help="prompt substring to wait for before sending input for the matching --command",
    )
    parser.add_argument(
        "--input-text",
        action="append",
        default=[],
        help="input text to send after the matching --input-marker for the matching --command",
    )
    parser.add_argument("--repeat", type=int, default=1, help="number of times to run the selected suite")
    parser.add_argument("--duration-sec", type=float, default=0.0, help="repeat the selected suite until at least this many seconds have elapsed")
    parser.add_argument("--sleep-sec", type=float, default=0.0, help="delay between repeated suite runs")
    parser.add_argument("--timeout", type=float, default=20.0, help="seconds to wait for each prompt")
    parser.add_argument("--startup-timeout", type=float, default=20.0, help="seconds to wait for the first prompt")
    parser.add_argument("--line-ending", choices=sorted(LINE_ENDINGS), default="cr")
    parser.add_argument("--prompt", default="berry>")
    parser.add_argument(
        "--no-wait-start",
        action="store_true",
        help="send commands immediately instead of waiting for the initial prompt",
    )
    parser.add_argument(
        "--wake-start",
        action="store_true",
        help="send one line ending before waiting for the initial prompt",
    )
    args = parser.parse_args()

    if args.command:
        positional_options = (
            ("--expect", args.expect),
            ("--input-marker", args.input_marker),
            ("--input-text", args.input_text),
        )
        for option_name, values in positional_options:
            if values and len(values) != len(args.command):
                parser.error(
                    f"{option_name} is positional when --command is repeated; "
                    f"got {len(values)} {option_name} value(s) for {len(args.command)} command(s). "
                    f"Repeat {option_name} with an empty string for commands that do not need it."
                )

    serial = load_serial_module()
    prompt = args.prompt.encode("utf-8")
    line_ending = LINE_ENDINGS[args.line_ending]

    ser = serial.Serial()
    ser.port = args.port
    ser.baudrate = args.baud
    ser.timeout = 0.05
    ser.write_timeout = 2.0
    ser.dtr = False
    ser.rts = False
    with ser:
        ser.reset_input_buffer()
        if not args.no_wait_start:
            if args.wake_start:
                ser.write(line_ending)
                ser.flush()
            print(f"[p2-smoke] waiting for {args.prompt!r} on {args.port} at {args.baud}")
            text = decode(read_until(ser, prompt, args.startup_timeout))
            sys.stdout.write(text)
            if text and not text.endswith("\n"):
                sys.stdout.write("\n")

        repeat = max(1, args.repeat)
        deadline = time.monotonic() + args.duration_sec if args.duration_sec > 0 else None
        iteration = 0

        while True:
            iteration += 1
            if repeat > 1 or deadline is not None:
                print(f"[p2-smoke] iteration {iteration}")

            if args.command:
                commands = []
                for index, command in enumerate(args.command):
                    expected = args.expect[index] if index < len(args.expect) else ""
                    input_marker = args.input_marker[index] if index < len(args.input_marker) else ""
                    input_text = args.input_text[index] if index < len(args.input_text) else ""
                    commands.append((command, expected, input_marker, input_text))
            else:
                commands = SUITES[args.suite]

            for step in commands:
                command = step[0]
                expected = step[1] if len(step) > 1 else ""
                input_marker = step[2] if len(step) > 2 else ""
                input_text = step[3] if len(step) > 3 else ""
                print(f"[p2-smoke] {command}")
                text = run_command(
                    ser,
                    command,
                    expected,
                    line_ending,
                    prompt,
                    args.timeout,
                    input_marker,
                    input_text,
                )
                sys.stdout.write(text)
                if text and not text.endswith("\n"):
                    sys.stdout.write("\n")

            if deadline is not None:
                if time.monotonic() >= deadline:
                    break
            elif iteration >= repeat:
                break

            if args.sleep_sec > 0:
                time.sleep(args.sleep_sec)

    label = "custom" if args.command else args.suite
    print(f"[p2-smoke] PASS {label} iterations={iteration}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
