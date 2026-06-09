print("P2_SMOKE_BEGIN global")

import global

assert(type(global) == "module")
assert(type(global()) == "map")
assert(type(global.contains) == "function")
assert(type(global.undef) == "function")

def has_global(name)
    return global().find(name) != nil
end

global.undef("p2_global_smoke_a")
global.undef("p2_global_smoke_b")
global.undef("p2_global_smoke_c")
global.undef("p2_global_smoke_d")
global.undef("p2_global_smoke_d")
global.undef("p2_global_smoke_e")

assert(!global.contains("p2_global_smoke_a"))
assert(!has_global("p2_global_smoke_a"))
assert(global.p2_global_smoke_a == nil)
assert(global.contains(42) == nil)
assert(global.undef(42) == nil)
assert(global.contains(true) == nil)
assert(global.undef(false) == nil)
assert(global.contains(nil) == nil)
assert(global.undef(nil) == nil)
assert(!global.contains("p2_global_smoke_d"))
assert(!has_global("p2_global_smoke_d"))
assert(!global.contains("p2_global_smoke_e"))
assert(!has_global("p2_global_smoke_e"))

global.p2_global_smoke_a = 20
global.p2_global_smoke_b = "berry"

assert(global.contains("p2_global_smoke_a"))
assert(global.contains("p2_global_smoke_b"))
assert(global.p2_global_smoke_a == 20)
assert(global.p2_global_smoke_b == "berry")
assert(has_global("p2_global_smoke_a"))
assert(has_global("p2_global_smoke_b"))

var compiled = compile("return p2_global_smoke_a + 22")
assert(compiled() == 42)

global.p2_global_smoke_a = 41
assert(compiled() == 63)

global.p2_global_smoke_c = [1, 2]
assert(global.p2_global_smoke_c == [1, 2])
global.p2_global_smoke_c.push(39)
assert(global.p2_global_smoke_c == [1, 2, 39])

global.p2_global_smoke_e = {"answer": 40}
assert(global.p2_global_smoke_e["answer"] == 40)
global.p2_global_smoke_e["extra"] = 2
assert(global.p2_global_smoke_e["answer"] + global.p2_global_smoke_e["extra"] == 42)

global.p2_global_smoke_d = 7
var globals_with_d = global()
assert(globals_with_d.find("p2_global_smoke_d") == 7)
global.undef("p2_global_smoke_d")
assert(!global.contains("p2_global_smoke_d"))
assert(!has_global("p2_global_smoke_d"))
global.undef("p2_global_smoke_d")
assert(global.p2_global_smoke_d == nil)

global.undef("p2_global_smoke_a")
assert(!global.contains("p2_global_smoke_a"))
assert(!has_global("p2_global_smoke_a"))
assert(global.p2_global_smoke_a == nil)

global.p2_global_smoke_a = 42
assert(global.contains("p2_global_smoke_a"))
assert(global.p2_global_smoke_a == 42)

global.undef("p2_global_smoke_a")
global.undef("p2_global_smoke_b")
global.undef("p2_global_smoke_c")
global.undef("p2_global_smoke_d")
global.undef("p2_global_smoke_e")

assert(!global.contains("p2_global_smoke_a"))
assert(!global.contains("p2_global_smoke_b"))
assert(!global.contains("p2_global_smoke_c"))
assert(!global.contains("p2_global_smoke_d"))
assert(!global.contains("p2_global_smoke_e"))
assert(!has_global("p2_global_smoke_a"))
assert(!has_global("p2_global_smoke_b"))
assert(!has_global("p2_global_smoke_c"))
assert(!has_global("p2_global_smoke_d"))
assert(!has_global("p2_global_smoke_e"))

print("P2_SMOKE_PASS global")
