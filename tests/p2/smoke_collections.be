print("P2_SMOKE_BEGIN collections")

def expect_error(f, error_type)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == error_type)
    end
    assert(caught)
end

def expand(iter)
    var out = []
    for i: iter
        out.push(i)
    end
    return out
end

var l = [1, 2, 3, 4, 5]
assert(l[0] == 1)
assert(l[-1] == 5)
assert(l[1..3] == [2, 3, 4])
assert(l[1..-2] == [2, 3, 4])
assert(l[3..2] == [])
assert(str(l.keys()) == "(0..4)")

var it = l.iter()
assert(it() == 1)
assert(it() == 2)
assert(it() == 3)

l.insert(0, 10)
assert(l[0] == 10)
assert(l.size() == 6)
assert(l.remove(0) == 10)
assert(l == [1, 2, 3, 4, 5])
l.setitem(0, 42)
assert(l.item(0) == 42)
assert(l.item(2) == 3)
l.resize(7)
assert(l == [42, 2, 3, 4, 5, nil, nil])
l.resize(3)
assert(l == [42, 2, 3])

var copy = l.copy()
l.insert(-1, 9)
assert(copy == [42, 2, 3])
assert(l == [42, 2, 9, 3])
assert(l.reverse() == [3, 9, 2, 42])
assert(l + [5, 6] == [3, 9, 2, 42, 5, 6])
assert(l.find(9) == 1)
assert(l.find(99) == nil)
assert([1, [2, nil], 3].find([2, nil]) == 1)
assert(["foo", "bar", 0].concat("-") == "foo-bar-0")
assert([1, 2, 3].concat("") == "123")

var lc = [1, 2, 3]
lc.clear()
assert(lc == [])
lc.push(42)
assert(lc == [42])

expect_error(def () return [1, 2, 3][10] end, "index_error")
expect_error(def ()
    var bad = [1, 2, 3]
    bad[10] = 99
end, "index_error")
expect_error(def () return [1, 2] + "not a list" end, "type_error")

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
assert(m.insert("new", 7) == true)
assert(m["new"] == 7)
assert(m.insert("a", 99) == false)
assert(m["a"] == 1)
assert(m.remove("new") == 7)
assert(!m.contains("new"))

var boolmap = {true: 10, false: 20}
assert(boolmap[true] == 10)
assert(boolmap[false] == 20)
assert(boolmap.contains(true))
assert(boolmap.contains(false))

var keys = m.keys()
assert(keys.find("a") != nil)
assert(keys.find("b") != nil)
keys.push("p2_collections_key_probe")
assert(!m.contains("p2_collections_key_probe"))
var map_values = m.values()
assert(map_values.find(1) != nil)
assert(map_values.find(3.5) != nil)
assert(map_values.find("foo") != nil)
assert(map_values.find(-1) != nil)
map_values.push("p2_collections_value_probe")
assert(m.values().find("p2_collections_value_probe") == nil)
var keys_before_late = m.keys()
var values_before_late = m.values()
m["late"] = 1234
assert(keys_before_late.find("late") == nil)
assert(values_before_late.find(1234) == nil)
assert(m.keys().find("late") != nil)
assert(m.values().find(1234) != nil)
var vals = []
for v: {"p": 10}.iter()
    vals.push(v)
end
assert(vals == [10])

var many = {}
for i: 0..9
    many[i] = i * 2
end
assert(many.size() == 10)
many.remove(0)
assert(!many.contains(0))
assert(many.size() == 9)
for i: 1..9
    many.remove(i)
end
assert(many.size() == 0)

expect_error(def () return {"a": 1}["missing"] end, "key_error")

assert(expand(0..5) == [0, 1, 2, 3, 4, 5])
assert(expand(0..0) == [0])
assert(expand(5..0) == [])
assert(expand(range(0, 5)) == [0, 1, 2, 3, 4, 5])
assert(expand(range(0, 5, 2)) == [0, 2, 4])
assert(expand(range(0, 5, 12)) == [0])
assert(expand(range(0, 5, -1)) == [])
assert(expand(range(5, 0, -2)) == [5, 3, 1])

var r = range(3, 7)
assert(r.lower() == 3)
assert(r.upper() == 7)
assert(r.incr() == 1)
assert(str(r) == "(3..7)")
r.setrange(10, 0, -5)
assert(r.lower() == 10)
assert(r.upper() == 0)
assert(r.incr() == -5)
assert(str(r) == "range(10, 0, -5)")
assert(expand(r) == [10, 5, 0])

expect_error(def () range(1, 2, 0) end, "value_error")
expect_error(def () range(1) end, "value_error")
expect_error(def () range(1, 2.0) end, "value_error")
expect_error(def ()
    var bad_range = range(1, 5)
    bad_range.setrange(1, 10, 0)
end, "value_error")

print("P2_SMOKE_PASS collections")
