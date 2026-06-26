import p2smart

var tx = 0
var rx = 1

print("Async serial loopback TX", tx, "RX", rx)
var result = p2smart.async_serial_probe(tx, rx, [65, 66, 67], 5000, 115200, 8)
print("ok", result["ok"], "count", result["count"])
for item : result["results"]
    print("sent", item["sent"], "event", item["event"], "ready", item["ready"])
end
var drained = p2smart.async_serial_drain_probe(tx, rx, 68, 5000, 115200, 8, 4)
print("drain ok", drained["ok"], "matched", drained["matched"], "count", drained["drained"]["count"], "values", drained["drained"]["values"])
print("uart loopback done")
