print("P2_SMOKE_BEGIN list_core")

var api = []
assert(type(api.size) == "function")
assert(type(api.iter) == "function")
assert(type(api.copy) == "function")
assert(type(api.insert) == "function")
assert(type(api.remove) == "function")
assert(type(api.reverse) == "function")
assert(type(api.push) == "function")
assert(type(api.pop) == "function")
assert(type(api.find) == "function")
assert(type(api.keys) == "function")
assert(type(api.concat) == "function")

var l = [1, 2, 3, 4, 5]
assert(str(l) == "[1, 2, 3, 4, 5]")

var it = l.iter()
assert(it() == 1)
assert(it() == 2)
assert(it() == 3)
assert(it() == 4)
assert(it() == 5)
assert(it() == nil)

var t = [0, 1, 2, 3]
var copy = t.copy()
t.insert(-2, 4)
assert(copy == [0, 1, 2, 3])
assert(t == [0, 1, 4, 2, 3])
copy[0] = 99
assert(copy == [99, 1, 2, 3])
assert(t[0] == 0)
t.remove(-2)
assert(t == [0, 1, 4, 3])
assert(t.reverse() == [3, 4, 1, 0])
assert(t == [3, 4, 1, 0])
t.reverse()
assert(t == [0, 1, 4, 3])

var appendish = [0]
assert(appendish .. "3" == [0, "3"])
appendish.push(1)
assert(appendish == [0, "3", 1])
assert(appendish.concat() == "031")
appendish.pop()
assert(appendish == [0, "3"])
appendish.pop(0)
assert(appendish == ["3"])

assert([].find() == nil)
assert([1, 2].find() == nil)
assert([1, 1, nil, 2].find(nil) == 2)
assert([1, [1, nil, 2], 3, [3]].find([3]) == 3)
assert([1, [1, nil, 2], 3, [3]].find([1, nil, 2]) == 1)

assert(str(["a", "b", 0].keys()) == "(0..2)")
assert(str([nil].keys()) == "(0..0)")
assert(str([].keys()) == "(0..-1)")

assert(["foo", "bar", 0].concat() == "foobar0")
assert([1, 2, 3].concat() == "123")
assert(["foo", "bar", 0].concat("-") == "foo-bar-0")
assert([].concat("<->") == "")
assert(["foo"].concat("<->") == "foo")
assert(["foo", "bar", 0].concat("<->") == "foo<->bar<->0")
assert(["", "foo", "bar", 0].concat("<->") == "<->foo<->bar<->0")
assert(["", "", 1, "bar", 0].concat("<->") == "<-><->1<->bar<->0")
assert(["", "", 1, "bar", 0].concat("") == "1bar0")
assert(["", 2, 3].concat("-") == "-2-3")

var neg = [1, 2]
neg[-1] = 3
assert(neg == [1, 3])
neg[-1] += 1
assert(neg == [1, 4])
neg[-2] += neg[-1]
assert(neg == [5, 4])

var src = [10, 20, 30, 40, 50]
assert(src[list(1, 3)] == [20, 40])
assert(src[list(2, 0, 2)] == [30, 10, 30])

var selected = src[list(0, 99, -1)]
assert(selected[0] == 10)
assert(selected[1] == nil)
assert(selected[2] == nil)
selected[0] = 99
assert(selected[0] == 99)
assert(src[0] == 10)

print("P2_SMOKE_PASS list_core")
