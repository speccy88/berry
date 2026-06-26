import wifi

var caps = wifi.capabilities()
var cfg = wifi.default_config()
var audit = wifi.audit()

print("wifi hardware:", caps["hardware"])
print("wifi transport:", caps["transport"])
print("wifi deferred:", caps["hardware_deferred"], "init required:", caps["request_requires_init"])
print("wifi audit:", audit["ok"], audit["problem_count"], audit["audit_policy"])
print("wifi pins:", cfg["sck"], cfg["mosi"], cfg["miso"], cfg["cs"], cfg["busy"], cfg["reset"], cfg["irq"])
print("wifi status names:", wifi.STATUS[3], wifi.STATUS[255])
print("wifi detect done")
