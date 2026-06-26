import p2

print("CAPS", type(p2.cog.capabilities()), p2.cog.capabilities())
print("REQ", type(p2.cog.required_capability_keys()), p2.cog.required_capability_keys())

def blinker(pin, rate_ms)
    p2.pin.dir_high(pin)
    return rate_ms
end

var h = p2.cog.spawn(blinker, 38, 120)
print("JOIN", type(p2.cog.join(h)), p2.cog.join(h))
print("RESULT", p2.cog.result(h), p2.cog.error(h))
print("STOP", p2.cog.stop(h))
p2.pin.float(38)
print("P2_COG_PROBE_DONE")
