import p2smart

var out_pin = 0
var in_pin = 1

print("GPIO loopback OUT", out_pin, "IN", in_pin)
var result = p2smart.gpio_loopback_probe(out_pin, in_pin, [0, 1, 0, 1], 10000)
print("ok", result["ok"], "count", result["count"])
for item : result["results"]
    print("write", item["write"]["value"], "read", item["read"]["value"], "match", item["ok"])
end
print("gpio loopback done")
