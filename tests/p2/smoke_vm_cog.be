print("P2_SMOKE_BEGIN vm_cog")

import p2

var slot = 0
var opened = p2.vm_open(slot, p2.heap_info()["vm_partition_bytes"])
assert(opened["partition_ready"] == true)
assert(opened["child_created"] == true || opened["already_active"] == true)

var loaded = p2.vm_eval(slot, "def cog_add(a,b) return a+b end")
assert(loaded["active"] == true)
assert(loaded["run_result"] == 0)

var run = p2.vm_cog_start(slot, "cog_add", 19, 23)
assert(run["started"] == true)
assert(run["status"] == 2)
assert(run["raw_running"] == false)
assert(run["stack_freed"] == true)
assert(run["function_found"] == true)
assert(run["call_result"] == 0)
assert(run["result_type"] == 1)
assert(run["result_int"] == 42)
assert(run["wrong_free_delta"] == 0)
assert(run["wrong_realloc_delta"] == 0)

var closed = p2.vm_close(slot)
assert(closed["active"] == false)
assert(closed["released"] == true)

print("P2_SMOKE_PASS vm_cog")
