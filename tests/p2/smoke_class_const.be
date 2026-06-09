print("P2_SMOKE_BEGIN class_const")

def expect_attribute_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "attribute_error")
    end
end

class P2ClassConstA
    static var a, c, s, r
    var b
    def init()
        self.b = 2
    end
end

assert(P2ClassConstA.a == nil)
assert(P2ClassConstA.c == nil)
expect_attribute_error(def () return P2ClassConstA.b end)
expect_attribute_error(def () return P2ClassConstA.d end)

var a = P2ClassConstA()
assert(a.b == 2)
assert(a.a == nil)

P2ClassConstA.a = 1
P2ClassConstA.c = 3
P2ClassConstA.s = "foo"
P2ClassConstA.r = 3.5

import gc
gc.collect()

assert(P2ClassConstA.a == 1)
assert(P2ClassConstA.c == 3)
assert(P2ClassConstA.s == "foo")
assert(P2ClassConstA.r == 3.5)
assert(a.a == 1)
assert(a.c == 3)
assert(a.s == "foo")
assert(a.r == 3.5)
P2ClassConstA.a += 4
assert(P2ClassConstA.a == 5)
assert(a.a == 5)

class P2ClassConstB
    var member
    static fn
    def init()
        self.member = 1
    end
end

var b = P2ClassConstB()
b.member = def (x, y) return [x, y] end
P2ClassConstB.fn = def (x, y) return type(x) end

assert(type(b.member) == "function")
assert(type(b.fn) == "function")
assert(b.member(1, 2) == [1, 2])
assert(b.fn(1, 2) == "int")
assert(P2ClassConstB.fn(1, 2) == "int")
P2ClassConstB.fn = def (x, y) return [type(x), type(y)] end
assert(b.fn(1, "s") == ["int", "string"])
assert(P2ClassConstB.fn(1, "s") == ["int", "string"])

class P2ClassConstC
    static def g(x, y) return [x, y] end
    static h = def (x, y) return [x, y] end
end

var c = P2ClassConstC()
assert(type(c.g) == "function")
assert(type(c.h) == "function")
assert(type(P2ClassConstC.g) == "function")
assert(type(P2ClassConstC.h) == "function")
assert(c.g(1, 2) == [1, 2])
assert(c.h(1, 2) == [1, 2])
assert(P2ClassConstC.g(1, 2) == [1, 2])
assert(P2ClassConstC.h(1, 2) == [1, 2])

class P2ClassConstD
    static a = 1, b, c = 3.5, d = 42, e = "foo", f = [1], g = {}
    var aa
end

var d = P2ClassConstD()
assert(P2ClassConstD.a == 1)
assert(P2ClassConstD.b == nil)
assert(P2ClassConstD.c == 3.5)
assert(P2ClassConstD.d == 42)
assert(P2ClassConstD.e == "foo")
assert(P2ClassConstD.f == [1])
assert(d.a == 1)
assert(d.b == nil)
assert(d.c == 3.5)
assert(d.d == 42)
assert(d.e == "foo")
assert(d.f == [1])
assert(d.g == P2ClassConstD.g)
d.g["seen"] = 42
assert(P2ClassConstD.g["seen"] == 42)
assert(d.g["seen"] == 42)
assert(d.aa == nil)

class P2ClassConstParent
    static a = 1
end

class P2ClassConstChild : P2ClassConstParent
    static a = P2ClassConstParent
    static b = 1
    static c = P2ClassConstParent
end

assert(P2ClassConstParent.a == 1)
assert(P2ClassConstChild.a == P2ClassConstParent)
assert(P2ClassConstChild.b == 1)
assert(P2ClassConstChild.c == P2ClassConstParent)

class P2ClassConstInheritedParent
    static shared = "parent"
end

class P2ClassConstInheritedChild : P2ClassConstInheritedParent
end

var inherited_child = P2ClassConstInheritedChild()
assert(P2ClassConstInheritedChild.shared == "parent")
assert(inherited_child.shared == "parent")
P2ClassConstInheritedParent.shared = "updated"
assert(P2ClassConstInheritedChild.shared == "updated")
assert(inherited_child.shared == "updated")

print("P2_SMOKE_PASS class_const")
