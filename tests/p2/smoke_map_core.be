print("P2_SMOKE_BEGIN map_core")

def expect_key_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "key_error")
    end
end

var api = {}
assert(type(api.find) == "function")
assert(type(api.contains) == "function")
assert(type(api.remove) == "function")
assert(type(api.insert) == "function")
assert(type(api.iter) == "function")
assert(type(api.size) == "function")
assert(type(api.keys) == "function")
assert(type(api.values) == "function")

var m = {"a": 1, "b": 3.5, "c": "foo", 0: 1}
assert(type(m) == "instance")
assert(classname(m) == "map")
assert(m["a"] == 1)
assert(m["b"] == 3.5)
assert(m["c"] == "foo")
assert(m[0] == 1)
assert(m.find("a") == 1)
assert(m.find("z") == nil)
assert(m.find("z", 4) == 4)
assert(m.contains("a"))
assert(m.contains(0))
assert(!m.contains("z"))
assert(!m.contains())

m["y"] = -1
assert(m["y"] == -1)

var remove_map = {1: 2}
remove_map.remove(2)
assert(str(remove_map) == "{1: 2}")
remove_map.remove(1)
assert(str(remove_map) == "{}")

var bool_keys = {true: 10, false: 20}
assert(bool_keys.contains(true))
assert(bool_keys.contains(false))
assert(bool_keys[true] == 10)
assert(bool_keys[false] == 20)

var mixed_keys = {0: "zero", false: "false", "0": "string-zero"}
assert(mixed_keys.size() == 3)
assert(mixed_keys[0] == "zero")
assert(mixed_keys[false] == "false")
assert(mixed_keys["0"] == "string-zero")

var nil_values = {"present": nil}
assert(nil_values.contains("present"))
assert(nil_values.find("present", 42) == nil)
assert(nil_values.find("missing", 42) == 42)

var inserted_nil = {}
assert(inserted_nil.insert("present_nil", nil) == true)
assert(inserted_nil.contains("present_nil"))
assert(inserted_nil.find("present_nil", 42) == nil)
assert(inserted_nil.insert("present_nil", 99) == false)
assert(inserted_nil.find("present_nil", 42) == nil)

expect_key_error(def () return {"a": 1}["missing"] end)

var inserted = {"a": 1, "b": 2}
assert(inserted.insert("c", 3) == true)
assert(inserted["c"] == 3)
assert(inserted.insert("a", 99) == false)
assert(inserted["a"] == 1)
var inserted_keys = inserted.keys()
assert(inserted_keys.size() == 3)
var inserted_values = inserted.values()
assert(inserted_values.size() == 3)
inserted["d"] = 4
assert(inserted.size() == 4)
assert(inserted_keys.size() == 3)
assert(inserted_values.size() == 3)
inserted_values.push(99)
assert(inserted.size() == 4)
assert(inserted["d"] == 4)

import string
var rendered = str({"x": 1, "y": 2})
assert(string.find(rendered, ",") > 0)

var vals = []
for v : {"p": 10}.iter()
    vals .. v
end
assert(vals == [10])

var bulk = {}
for i : 0..19
    bulk[i] = i * 2
end
assert(bulk.size() == 20)
bulk.remove(0)
assert(!bulk.contains(0))
assert(bulk.size() == 19)
for i : 1..19
    bulk.remove(i)
end
assert(bulk.size() == 0)

print("P2_SMOKE_PASS map_core")
