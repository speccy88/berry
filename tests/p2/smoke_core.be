print("P2_SMOKE_BEGIN core")

assert(6 * 7 == 42)
assert("abc" + "def" == "abcdef")

var m = {"a": 2, "b": 5}
assert(m["a"] + m["b"] == 7)

var l = []
l.push(3)
l.push(4)
assert(l.size() == 2)
assert(l[0] + l[1] == 7)

var rsum = 0
for i : 0..5
    rsum += i
end
assert(rsum == 15)

var keys = 0
for k : m.keys()
    if k == "a" || k == "b"
        keys += 1
    end
end
assert(keys == 2)

def add(a, b)
    return a + b
end
assert(add(19, 23) == 42)

def make_adder(a)
    return def (b)
        return a + b
    end
end
var plus_7 = make_adder(7)
assert(plus_7(35) == 42)

print("P2_SMOKE_PASS core")
