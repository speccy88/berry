import p2smart

var data_tx = 0
var data_rx = 1
var clock_tx = 2
var clock_rx = 3

print("Synchronous serial probe data", data_tx, data_rx, "clock", clock_tx, clock_rx)
var policy = p2smart.sync_serial_receive_policy()
print("receive policy", policy["status"], policy["policy"], "bounded", policy["bounded_clocked_probe"], "matched", policy["matched_receive_words"])

var probe = p2smart.sync_serial_clocked_probe(data_tx, data_rx, clock_tx, clock_rx, [0x12], 1000, 100000, 8)
print("clocked probe ok", probe["ok"], "count", probe["count"], "ready", probe["ready_count"], "matched", probe["matched_count"], "wait", probe["wait_us"])
var first = probe["results"][0]
print("first word", "sent", first["sent"], "ready", first["ready"], "event", first["event"], "raw", first["raw"], "value", first["value"], "matched", first["matched"], "error", first["error"])

var grouped = p2smart.sync_serial_default_clocked_variant_probe([0x12], 1000, 100000, 8)
print("default variants", "groups", grouped["count"], "failed", grouped["failed_count"], "supported", grouped["execution_supported"], "error", grouped["error"])
print("sync serial probe done")
