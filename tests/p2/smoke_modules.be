print("P2_SMOKE_BEGIN modules")

import string
assert(string.toupper("abc") == "ABC")
assert(string.find("banana", "na") == 2)

import math
assert(math.sqrt(81) == 9)
assert(math.min(5, 2, 9) == 2)
assert(math.max(5, 2, 9) == 9)
assert(math.abs(-42) == 42)

import json
var decoded = json.load('{"a":1,"b":[2,3]}')
assert(decoded["b"][1] == 3)
var encoded = json.dump({"x": 1, "y": [2, 3]})
assert(type(encoded) == "string")
assert(json.load(encoded)["y"][0] == 2)

import bytes
var b = bytes().fromstring("AB")
assert(b.tohex() == "4142")
assert(b.asstring() == "AB")
assert(bytes("1122")[1] == 0x22)

import p2
assert(p2.clock_freq() > 0)
assert(p2.cogid() >= 0)
assert(p2.cogid() < 8)
assert(type(p2.heap_info()) == "map")
assert(type(p2.cog_states()) == "list")
var status = p2.status_info()
assert(type(status) == "map")
assert(status["build"]["profile"] != "")
assert(status["runtime"]["toolchain"] == "Catalina")
assert(status["clock"]["frequency"] > 0)
assert(status["memory"]["hub_total"] == 512 * 1024)
assert(status["memory"]["main_heap_total"] > 0)
assert(status["psram"]["access"] == p2.psram_info()["access"])
assert(type(status["cogs"]) == "list")
assert(status["cogs"].size() == 8)
assert(status["cogs"][p2.cogid()]["current"] == true)
assert(p2.debug_snapshot()["build"]["profile"] == status["build"]["profile"])

print("P2_SMOKE_PASS modules")
