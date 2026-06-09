print("P2_SMOKE_BEGIN be_api_edges")

import introspect

def p2_api_function()
    return 1
end
assert(type(p2_api_function) == "function")
assert(classname(p2_api_function) == nil)

var p2_api_map = {"a": 1, "b": 2}
var p2_api_keys = []
for k : p2_api_map
    p2_api_keys.push(k)
end
assert(size(p2_api_keys) == 2)

var p2_api_list = [1, 2, 3]
assert(isinstance(p2_api_list, list))
assert(isinstance(p2_api_map, map))
assert(!isinstance(p2_api_list, map))
assert(!isinstance(p2_api_map, list))

var p2_api_ptr = introspect.toptr(0)
assert(type(p2_api_ptr) == "ptr")

assert(classname(42) == nil)
assert(classname(nil) == nil)
assert(classname(true) == nil)
assert(classname(3.14) == nil)

class P2ApiClass
end
var p2_api_obj = P2ApiClass()
assert(classname(p2_api_obj) == "P2ApiClass")

assert(size("hello") == 5)
assert(size("") == 0)

var p2_api_module = module("p2_be_api_edges_missing")
assert(introspect.get(p2_api_module, "no_such_key") == nil)
p2_api_module.value = 1
introspect.set(p2_api_module, "value", 42)
assert(p2_api_module.value == 42)
assert(introspect.get(p2_api_module, "value") == 42)
introspect.set(42, "x", 1)

var p2_api_orig = [1, 2, 3]
var p2_api_copy = p2_api_orig.copy()
assert(p2_api_copy == [1, 2, 3])
p2_api_copy.push(4)
assert(p2_api_orig == [1, 2, 3])
assert(p2_api_copy == [1, 2, 3, 4])

var p2_api_map_orig = {"a": 1}
var p2_api_map_copy = p2_api_map_orig.copy()
p2_api_map_copy["a"] = 2
p2_api_map_copy["b"] = 3
assert(p2_api_map_orig == {"a": 1})
assert(p2_api_map_copy == {"a": 2, "b": 3})

def p2_make_counter()
    var n = 0
    return def ()
        n += 1
        return n
    end
end
var p2_counter = p2_make_counter()
assert(p2_counter() == 1)
assert(p2_counter() == 2)
assert(p2_counter() == 3)

assert(1 < 2)
assert(!(2 < 1))
assert(1 <= 1)
assert(1 <= 2)
assert(!(2 <= 1))
assert(2 > 1)
assert(!(1 > 2))
assert(2 >= 2)
assert(2 >= 1)
assert(!(1 >= 2))
assert(1.0 < 2.0)
assert(1.0 <= 1.0)
assert(2.0 > 1.0)
assert(2.0 >= 2.0)

class P2ApiBase
    def hello()
        return "base"
    end
end

class P2ApiChild : P2ApiBase
end

var p2_api_child = P2ApiChild()
assert(p2_api_child.hello() == "base")
assert(classname(p2_api_child) == "P2ApiChild")
assert(isinstance(p2_api_child, P2ApiBase))
assert(isinstance(p2_api_child, P2ApiChild))

assert(type(print) == "function")
assert(type(42) != "function")
assert(type(nil) != "function")

print("P2_SMOKE_PASS be_api_edges")
