print("P2_SMOKE_BEGIN vararg")

def f(a, *b)
    return b
end

assert(f() == [])
assert(f(1) == [])
assert(f(1, 2) == [2])
assert(f(1, 2, 3) == [2, 3])
var direct_once = f(1, 2)
direct_once.push(3)
assert(direct_once == [2, 3])
assert(f(1, 2) == [2])

def g(*a)
    return a
end

assert(g() == [])
assert(g("foo") == ["foo"])
assert(g("foo", nil) == ["foo", nil])
assert(g("foo", nil, 2) == ["foo", nil, 2])

def make_vararg(prefix)
    return def (*items)
        return [prefix, items]
    end
end

var packed = make_vararg("p2")
assert(packed() == ["p2", []])
assert(packed(1, 2, 3) == ["p2", [1, 2, 3]])
var packed_once = packed(4, 5)
packed_once[1].push(6)
assert(packed_once == ["p2", [4, 5, 6]])
assert(packed(4, 5) == ["p2", [4, 5]])
assert(packed() == ["p2", []])

def capture_varargs(*items)
    return def ()
        return items
    end
end

var captured_items = capture_varargs("a", "b", 42)
assert(captured_items() == ["a", "b", 42])
captured_items().push("tail")
assert(captured_items() == ["a", "b", 42, "tail"])

class P2VarargMethod
    var base
    def init(base)
        self.base = base
    end
    def collect(a, *rest)
        return [self.base, a, rest]
    end
end

var inst = P2VarargMethod(10)
assert(inst.collect() == [10, nil, []])
assert(inst.collect(1) == [10, 1, []])
assert(inst.collect(1, 2, 3) == [10, 1, [2, 3]])
var method_once = inst.collect(1, 2)
method_once[2].push(3)
assert(method_once == [10, 1, [2, 3]])
assert(inst.collect(1, 2) == [10, 1, [2]])

print("P2_SMOKE_PASS vararg")
