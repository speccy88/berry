print("P2_SMOKE_BEGIN edge32")

import p2

var info = p2.psram_info()
assert(info["available"] == true)
assert(info["bytes"] == 33554432)
assert(info["access"] == "block")
assert(info["heap"] == false)
assert(info["reserved_pin_first"] == 40)
assert(info["reserved_pin_last"] == 57)

var smoke = p2.psram_test()
assert(smoke["available"] == true)
assert(smoke["bytes"] == 33554432)
assert(smoke["ok"] == true)
assert(smoke["value"] == "Berry P2 PSRAM smoke")

print("P2_SMOKE_PASS edge32")
