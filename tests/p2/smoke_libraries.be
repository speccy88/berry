print("P2_SMOKE_BEGIN libraries")

def maplike(value)
    var kind = type(value)
    return kind == "map" || kind == "instance"
end

def listlike(value)
    var kind = type(value)
    return kind == "list" || kind == "instance"
end

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL libraries", label)
    end
    assert(cond)
end

import binary_heap
import configstore
import p2
import p2ipc
print("P2_SMOKE_STEP libraries imports")

check(configstore.capability("load_result"), "configstore_capability_load_result")
check(configstore.capability("save_result"), "configstore_capability_save_result")
check(configstore.capability("remove_result"), "configstore_capability_remove_result")
check(configstore.capability("list_result"), "configstore_capability_list_result")
check(configstore.capability("json_null_detection"), "configstore_capability_json_null")
check(configstore.capability("root") == "/berry/config", "configstore_capability_root")
check(configstore.capability("missing") == nil, "configstore_capability_missing")
print("P2_SMOKE_STEP libraries configstore")

var data = [3, 1, 4, 1, 5]
binary_heap.sort(data, /a b -> a < b)
check(data == [1, 1, 3, 4, 5], "binary_heap_sort")
var empty_heap = []
binary_heap.sort(empty_heap, /a b -> a < b)
check(empty_heap == [], "binary_heap_empty")
var single_heap = [7]
binary_heap.sort(single_heap, /a b -> a < b)
check(single_heap == [7], "binary_heap_single")
var preserved_heap = [5, 1, 4, 2, 3]
var compare_state = {"count": 0}
def raising_cmp(a, b)
    compare_state["count"] += 1
    if compare_state["count"] > 4
        raise "value_error", "forced heap compare failure"
    end
    return a < b
end
var sort_failed = false
try
    binary_heap.sort(preserved_heap, raising_cmp)
except .. as e, m
    sort_failed = true
    assert(e == "value_error")
end
check(sort_failed, "binary_heap_forced_error")
check(preserved_heap == [5, 1, 4, 2, 3], "binary_heap_error_preserves_input")
print("P2_SMOKE_STEP libraries binary_heap")

var ipc_ch = p2.channel.new(1)
var ipc_nil_send = ipc_ch.send_result(nil)
check(ipc_nil_send["ok"], "channel_nil_send_ok")
check(ipc_nil_send["sent"], "channel_nil_send_sent")
var ipc_full_send = ipc_ch.send_result("full")
check(!ipc_full_send["ok"], "channel_full_send_not_ok")
check(ipc_full_send["error"] == "full", "channel_full_send_error")
var ipc_nil_recv = ipc_ch.recv_result()
check(ipc_nil_recv["ok"], "channel_nil_recv_ok")
check(ipc_nil_recv["found"], "channel_nil_recv_found")
check(ipc_nil_recv["value"] == nil, "channel_nil_recv_value")
var ipc_empty_recv = ipc_ch.recv_result()
check(ipc_empty_recv["ok"], "channel_empty_recv_ok")
check(!ipc_empty_recv["found"], "channel_empty_recv_not_found")
check(ipc_empty_recv["value"] == nil, "channel_empty_recv_value")
var ipc_ch_close = ipc_ch.close_result()
check(ipc_ch_close["ok"], "channel_close_ok")
check(ipc_ch_close["closed"], "channel_close_closed")
check(!ipc_ch_close["was_closed"], "channel_close_not_previous")
check(ipc_ch.info()["closed"], "channel_info_closed")
check(ipc_ch.send_result("after-close")["error"] == "closed", "channel_send_closed")
check(ipc_ch.recv_result()["error"] == "closed", "channel_recv_closed")
check(ipc_ch.close_result()["was_closed"], "channel_close_again")

var ipc_mb = p2.mailbox.new()
check(ipc_mb.put_result(nil)["ok"], "mailbox_nil_put_ok")
var ipc_mb_full = ipc_mb.put_result(1)
check(!ipc_mb_full["ok"], "mailbox_full_put_not_ok")
check(ipc_mb_full["error"] == "full", "mailbox_full_put_error")
var ipc_mb_nil = ipc_mb.get_result()
check(ipc_mb_nil["ok"], "mailbox_nil_get_ok")
check(ipc_mb_nil["found"], "mailbox_nil_get_found")
check(ipc_mb_nil["value"] == nil, "mailbox_nil_get_value")
check(ipc_mb.get_result()["found"] == false, "mailbox_empty_get")
var ipc_mb_close = ipc_mb.close_result()
check(ipc_mb_close["ok"], "mailbox_close_ok")
check(ipc_mb_close["closed"], "mailbox_close_closed")
check(!ipc_mb_close["was_closed"], "mailbox_close_not_previous")
check(ipc_mb.info()["closed"], "mailbox_info_closed")
check(ipc_mb.put_result("after-close")["error"] == "closed", "mailbox_put_closed")
check(ipc_mb.get_result()["error"] == "closed", "mailbox_get_closed")
check(ipc_mb.close_result()["was_closed"], "mailbox_close_again")

var ipc_mutex = p2.mutex.new()
check(ipc_mutex.unlock_result()["error"] == "not_locked", "mutex_unlock_not_locked")
check(ipc_mutex.lock_result()["ok"], "mutex_lock_ok")
var ipc_mutex_second_lock = ipc_mutex.lock_result()
var ipc_mutex_second_locked = ipc_mutex_second_lock["ok"]
check(ipc_mutex_second_locked || ipc_mutex_second_lock["error"] == "busy", "mutex_second_lock")
if ipc_mutex_second_locked
    check(ipc_mutex.unlock_result()["ok"], "mutex_unlock_second_ok")
else
    check(ipc_mutex.unlock_result()["ok"], "mutex_unlock_ok")
end
var ipc_mutex_close = ipc_mutex.close_result()
check(ipc_mutex_close["ok"], "mutex_close_ok")
check(ipc_mutex_close["closed"], "mutex_close_closed")
check(ipc_mutex.lock_result()["error"] == "closed", "mutex_lock_closed")
check(ipc_mutex.unlock_result()["error"] == "closed", "mutex_unlock_closed")
check(ipc_mutex.close_result()["was_closed"], "mutex_close_again")

var ipc_buf = p2.shared.Buffer(2)
check(ipc_buf.write_result(0, 44)["ok"], "buffer_write_ok")
check(ipc_buf.read_result(0)["value"] == 44, "buffer_read_value")
check(ipc_buf.write_result(2, 1)["error"] == "offset_out_of_range", "buffer_write_offset_error")
check(ipc_buf.write_result(0, 256)["error"] == "value_out_of_range", "buffer_write_value_error")
check(ipc_buf.fill_result(9)["ok"], "buffer_fill_ok")
check(ipc_buf.aslist() == [9, 9], "buffer_aslist")
print("P2_SMOKE_STEP libraries ipc")

import libstore
print("P2_SMOKE_STEP libraries libstore_import")

print("P2_SMOKE_STEP libraries psram_before")
var psram = p2.psram_info()
print("P2_SMOKE_STEP libraries psram_after")
var expected_policy = psram["available"] ? libstore.POLICY_SD_CACHE_PSRAM : libstore.POLICY_SD_LAZY
var expected_heap = psram["heap"] ? "external" : "hub"
print("P2_SMOKE_STEP libraries status_before")
var status = libstore.status()
print("P2_SMOKE_STEP libraries status_after")
print("P2_SMOKE_STEP libraries policy_before")
var policy = libstore.policy()
print("P2_SMOKE_STEP libraries policy_after")
assert(status["lazy"] == true)
assert(status["source"] == "sd")
assert(status["heap"] == expected_heap)
assert(policy["name"] == expected_policy)
assert(status["psram_cache"] == status["psram_available"])
assert(status["psram_cache_used"] == 0)
assert(status["psram_cache_free"] == status["psram_cache_limit"])
assert(status["psram_cache_items"] == 0)
assert(status["library_count"] >= 5)
assert(status["psram_max_transfer"] >= 0)
print("P2_SMOKE_STEP libraries strategy_before")
var strategy = libstore.strategy()
print("P2_SMOKE_STEP libraries strategy_after")
assert(strategy["library_home"] == "sd")
assert(strategy["object_heap"] == psram["heap"])
assert(strategy["direct_execute_from_psram"] == false)
var expected_strategy_load = "lazy_source"
if psram["available"]
    expected_strategy_load = "lazy_source_or_psram_cache"
end
assert(strategy["load"] == expected_strategy_load)
print("P2_SMOKE_STEP libraries libstore_core")
assert(libstore.module_name("MATH.BE") == "math")
assert(libstore.module_name("README.TXT") == nil)
assert(libstore.exists("binary_heap"))
assert(libstore.source_path("binary_heap") == "/modules/binary_heap.be")
print("P2_SMOKE_STEP libraries info_before")
var binary_info = libstore.info("binary_heap")
print("P2_SMOKE_STEP libraries info_after")
assert(binary_info["exists"] == true)
assert(binary_info["source"] == "sd")
assert(type(binary_info["compiled_supported"]) == "bool")
assert(binary_info["compiled_exists"] == false)
assert(binary_info["source_fallback"] == false)
assert(binary_info["source_size"] > 0)
assert(type(binary_info["source_hash"]) == "int")
assert(type(binary_info["compiled_size"]) == "int")
assert(binary_info["compiled_fresh"] == false)
assert(binary_info["compiled_usable"] == false)
assert(type(binary_info["compiled_freshness_reason"]) == "string")
var binary_stats = libstore.source_stats("binary_heap")
assert(binary_stats["size"] == binary_info["source_size"])
assert(binary_stats["path"] == "/modules/binary_heap.be")
var binary_compiled_stats = libstore.compiled_stats("binary_heap")
assert(type(binary_compiled_stats["exists"]) == "bool")
assert(type(binary_compiled_stats["size"]) == "int")
import p2mem
print("P2_SMOKE_STEP libraries p2mem_import")

print("P2_SMOKE_STEP libraries p2mem_stats_before")
var mem_stats = p2mem.stats()
print("P2_SMOKE_STEP libraries p2mem_stats_after")
print("P2_SMOKE_STEP libraries p2mem_stats_shape", type(mem_stats), mem_stats["module_count"])
check(maplike(mem_stats), "p2mem_stats_maplike")
check(maplike(mem_stats["heap"]), "p2mem_stats_heap_maplike")
check(maplike(mem_stats["psram"]), "p2mem_stats_psram_maplike")
check(maplike(mem_stats["libstore"]), "p2mem_stats_libstore_maplike")
check(mem_stats["module_count"] >= 5, "p2mem_stats_module_count")
var math_module = p2mem.module("math")
check(math_module != nil, "p2mem_module_math_exists")
check(math_module["source_path"] == "/modules/math.be", "p2mem_module_math_path")
check(math_module["compiled_fresh"] == false, "p2mem_module_math_compiled_fresh")
check(math_module["compiled_usable"] == false, "p2mem_module_math_compiled_usable")

print("P2_SMOKE_STEP libraries p2mem_cache_before")
var mem_cache = p2mem.cache()
print("P2_SMOKE_STEP libraries p2mem_cache_after")
check(maplike(mem_cache), "p2mem_cache_maplike")
check(maplike(mem_cache["status"]), "p2mem_cache_status_maplike")
check(listlike(mem_cache["items"]), "p2mem_cache_items_list")
for item : mem_cache["items"]
    check(item.contains("cache_hit_count"), "p2mem_cache_item_hit_count")
    check(item.contains("cache_miss_count"), "p2mem_cache_item_miss_count")
    check(item.contains("last_used"), "p2mem_cache_item_last_used")
    check(item.contains("chunk_count"), "p2mem_cache_item_chunk_count")
    check(item["chunk_count"] == item["chunks"], "p2mem_cache_item_chunks")
end

print("P2_SMOKE_STEP libraries p2mem_gc_before")
var gc_report = p2mem.gc()
print("P2_SMOKE_STEP libraries p2mem_gc_after")
check(maplike(gc_report), "p2mem_gc_maplike")
check(type(gc_report["before"]) == "int", "p2mem_gc_before_int")
check(type(gc_report["after"]) == "int", "p2mem_gc_after_int")

print("P2_SMOKE_PASS libraries")
