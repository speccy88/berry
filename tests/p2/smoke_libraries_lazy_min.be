print("P2_SMOKE_BEGIN libraries_lazy_min")

import p2
import libstore

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL libraries_lazy_min", label)
    end
    assert(cond)
end

var psram = p2.psram_info()
var status = libstore.status()
var policy = libstore.policy()
var strategy = libstore.strategy()

var expected_policy = psram["available"] ? libstore.POLICY_SD_CACHE_PSRAM : libstore.POLICY_SD_LAZY
var expected_heap = psram["heap"] ? "external" : "hub"
var expected_load = psram["available"] ? "lazy_source_or_psram_cache" : "lazy_source"

check(status["lazy"], "status_lazy")
check(status["source"] == "sd", "status_source")
check(status["heap"] == expected_heap, "status_heap")
check(status["policy"] == expected_policy, "status_policy")
check(policy["name"] == expected_policy, "policy_name")
check(policy["uses_psram_cache"] == psram["available"], "policy_uses_cache")
check(status["psram_cache_items"] == 0, "no_eager_cache_items")
check(status["psram_cache_used"] == 0, "no_eager_cache_used")
check(status["psram_cache_free"] == status["psram_cache_limit"], "cache_free_limit")
check(status["library_count"] >= 5, "library_count")

check(strategy["library_home"] == "sd", "strategy_home")
check(strategy["load"] == expected_load, "strategy_load")
check(strategy["heap"] == expected_heap, "strategy_heap")
check(strategy["object_heap"] == psram["heap"], "strategy_object_heap")
check(!strategy["direct_execute_from_psram"], "strategy_no_direct_psram_exec")
check(strategy["module_path"].find("/modules") != nil, "strategy_modules_root")
check(strategy["module_path"].find("/berry/lib") != nil, "strategy_berry_lib")
check(strategy["module_path"].find("/berry/app") != nil, "strategy_berry_app")

status["lazy"] = false
policy["name"] = "caller_mutated"
strategy["load"] = "caller_mutated"

check(libstore.status()["lazy"], "status_snapshot")
check(libstore.policy()["name"] == expected_policy, "policy_snapshot")
check(libstore.strategy()["load"] == expected_load, "strategy_snapshot")

print("P2_SMOKE_PASS libraries_lazy_min")
