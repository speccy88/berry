# Hardware smoke proof that p2.cog.spawn(function, ...) invokes the function
# entity during setup and uses its returned integer as the native blink period.

import p2

def blinker(pin, ms)
    return ms + 11
end

h = p2.cog.spawn(blinker, 38, 250)
info = p2.cog.info(h)
print("setup_return", info["native_pin"], info["period_ms"], info["last_result_int"], info["running"])
stopped = p2.cog.stop(h)
print("stopped", stopped["running"], stopped["raw_running"])
