import p2

print("PSRAM cache stats:")
var psram = p2.psram_info()
var cache = p2.psram_cache_info()

print("psram available/heap:", psram["available"], psram["heap"])
print("psram bytes/access:", psram["bytes"], psram["access"])
print("block base/bytes:", psram["block_base"], psram["block_bytes"])
print("max transfer:", psram["max_transfer"])

print("cache available:", cache["available"])
print("cache base/limit:", cache["base"], cache["limit"])
print("cache next/used/free:", cache["next"], cache["used"], cache["free"])
print("cache entries/max:", cache["entry_count"], cache["entry_max"])
print("cache alloc count:", cache["alloc_count"])
print("psram cache stats done")
