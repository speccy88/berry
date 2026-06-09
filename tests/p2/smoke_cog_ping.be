print("P2_SMOKE_BEGIN cog_ping")

import p2

var ping = p2.vm_cog_ping(41)

assert(ping["started"] == true)
assert(ping["status"] == 3)
assert(ping["result"] == 83)
assert(ping["raw_running"] == false)
assert(ping["stack_freed"] == true)
assert(ping["wait_count"] < 5200)
assert(ping["stack_bytes"] == 2048)
assert(p2.heap_info()["wrong_free_count"] == 0)

print("P2_SMOKE_PASS cog_ping")
