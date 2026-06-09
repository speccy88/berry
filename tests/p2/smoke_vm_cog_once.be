print("P2_SMOKE_BEGIN vm_cog_once")

import p2

var source = "def cog_add(a,b) return a+b end"
var run = p2.vm_cog_call_once(0, p2.heap_info()["vm_partition_bytes"], source, "cog_add", 19, 23)

assert(run["started"] == true)
assert(run["status"] == 2)
assert(run["raw_running"] == false)
assert(run["stack_freed"] == true)
assert(run["released"] == true)
assert(run["partition_ready"] == true)
assert(run["selected"] == true)
assert(run["child_created"] == true)
assert(run["child_deleted"] == true)
assert(run["function_found"] == true)
assert(run["source_result"] == 0)
assert(run["call_result"] == 0)
assert(run["result_type"] == 1)
assert(run["result_int"] == 42)
assert(run["wrong_free_delta"] == 0)
assert(run["wrong_realloc_delta"] == 0)
assert(run["current"] == -1)

print("P2_SMOKE_PASS vm_cog_once")
