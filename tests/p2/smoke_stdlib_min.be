print("P2_SMOKE_BEGIN stdlib_min")

import string
import json
import introspect

assert(string.find("012345", "23") == 2)
assert(string.count("121314", "1") == 3)
assert(string.split("a b c", " ") == ["a", "b", "c"])
assert(string.startswith("qwerty", "qw"))
assert(string.endswith("qwerty", "ty"))
assert(string.format("%i%%%i", 12, 13) == "12%13")
assert("az" * 3 == "azazaz")
print("P2_SMOKE_STDLIB_MIN string")

var decoded = json.load('{"key":1,"arr":[2,3]}')
assert(decoded["key"] == 1)
assert(decoded["arr"][1] == 3)
decoded["arr"][1] = 9
var decoded_again = json.load('{"key":1,"arr":[2,3]}')
assert(decoded_again["arr"][1] == 3)
assert(json.load("[1, nil]") == nil)
assert(json.dump([1, "x"]) == '[1,"x"]')
assert(json.load(json.dump({"round": [1, 2, 3]}))["round"][2] == 3)
print("P2_SMOKE_STDLIB_MIN json")

var time_mod = introspect.module("time")
if time_mod == nil
    print("P2_SMOKE_SKIP stdlib_min_time")
else
    var clock0 = time_mod.clock()
    assert(type(clock0) == "real")
    assert(clock0 >= 0)
    var d = time_mod.dump(1609459200)
    assert(isinstance(d, map))
    assert(d["epoch"] == 1609459200)
    assert(type(d["year"]) == "int")
    d["year"] = 9999
    assert(time_mod.dump(1609459200)["year"] != 9999)
    print("P2_SMOKE_STDLIB_MIN time")
end

var global_mod = introspect.module("global")
if global_mod == nil
    print("P2_SMOKE_SKIP stdlib_min_global")
else
    global_mod.p2_stdlib_min_value = 42
    assert(global_mod.p2_stdlib_min_value == 42)
    assert(global_mod.contains("p2_stdlib_min_value"))
    global_mod.undef("p2_stdlib_min_value")
    assert(!global_mod.contains("p2_stdlib_min_value"))
    print("P2_SMOKE_STDLIB_MIN global")
end

var solidify_mod = introspect.module("solidify")
if solidify_mod == nil
    print("P2_SMOKE_SKIP stdlib_min_solidify")
else
    assert(type(solidify_mod.compact) == "function")
    class P2StdlibMinSolidify
        def value()
            return 42
        end
    end
    assert(solidify_mod.compact(P2StdlibMinSolidify) == nil)
    assert(P2StdlibMinSolidify().value() == 42)
    print("P2_SMOKE_STDLIB_MIN solidify")
end

var strict_mod = introspect.module("strict")
if strict_mod == nil
    print("P2_SMOKE_SKIP stdlib_min_strict")
else
    assert(type(strict_mod) == "module")
    print("P2_SMOKE_STDLIB_MIN strict")
end

print("P2_SMOKE_PASS stdlib_min")
