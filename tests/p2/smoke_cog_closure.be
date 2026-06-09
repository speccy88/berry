print("P2_SMOKE_BEGIN cog_closure")

import p2

var caps = p2.cog.capabilities()
assert(caps["spawn"] == true)
assert(caps["native_blink"] == true)
assert(caps["native_blink_stack"] == 2048)
assert(caps["handle_base"] == 100)
assert(caps["max_handles"] >= 2)
assert(caps["reject_unsupported"] == true)
assert(caps["unsafe_shared_vm"] == false)
assert(caps["isolated_vm_closure"] == false)

# Default firmware supports the hardware-safe p38/p39 closure-spawn shape:
# p2.cog.spawn(closure, pin, rate_ms). The passed closure is invoked once
# during setup and must return a positive delay. The spawned cog then runs the
# native blinker loop and can be inspected/stopped by handle.

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    p2.pin.toggle(pin)
    return rate_ms
end

var h38 = p2.cog.spawn(blinker, 38, 120)
var h39 = p2.cog.spawn(blinker, 39, 250)

assert(h38 >= 100)
assert(h39 >= 100)
assert(h38 != h39)

var i38 = p2.cog.info(h38)
var i39 = p2.cog.info(h39)
var all = p2.cog.info()
var saw38 = false
var saw39 = false

assert(i38["handle"] == h38)
assert(i39["handle"] == h39)
assert(i38["kind"] == "closure")
assert(i39["kind"] == "closure")
assert(i38["model"] == "native_blink")
assert(i39["model"] == "native_blink")
assert(i38["native_blink"] == true)
assert(i39["native_blink"] == true)
assert(i38["repl_idle_only"] == false)
assert(i39["repl_idle_only"] == false)
assert(i38["native_pin"] == 38)
assert(i39["native_pin"] == 39)
assert(i38["period_ms"] == 120)
assert(i39["period_ms"] == 250)
assert(i38["last_result_int"] == 120)
assert(i39["last_result_int"] == 250)
assert(i38["stack_bytes"] == 2048)
assert(i39["stack_bytes"] == 2048)
assert(i38["calls"] > 0)
assert(i39["calls"] > 0)
assert(type(all) == "list")
assert(all.size() >= 2)

for item : all
    if item["handle"] == h38
        saw38 = true
    elif item["handle"] == h39
        saw39 = true
    end
end
assert(saw38)
assert(saw39)

var s38 = p2.cog.stop(h38)
var s39 = p2.cog.stop(h39)
assert(s38["handle"] == h38)
assert(s39["handle"] == h39)
assert(s38["running"] == false)
assert(s39["running"] == false)
assert(s38["raw_running"] == false)
assert(s39["raw_running"] == false)
assert(p2.cog.info().size() == 0)

def tick()
    return 10
end

var rejected = false
try
    p2.cog.spawn(tick)
except .. as e
    rejected = type(e) == "string" || type(e) == "nil" || type(e) == "instance"
end
assert(rejected)
assert(p2.cog.info().size() == 0)

p2.pin.float(38)
p2.pin.float(39)

print("P2_SMOKE_PASS cog_closure")
