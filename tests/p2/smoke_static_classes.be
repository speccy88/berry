print("P2_SMOKE_BEGIN static_classes")

class P2StaticInit
    static a = 1, b, c = 3.5, d = 42, e = "foo", f = [1], g = {}
    var aa, ab
end

assert(P2StaticInit.a == 1)
assert(P2StaticInit.b == nil)
assert(P2StaticInit.c == 3.5)
assert(P2StaticInit.d == 42)
assert(P2StaticInit.e == "foo")
assert(P2StaticInit.f == [1])

var si = P2StaticInit()
assert(si.a == 1)
assert(si.b == nil)
assert(si.c == 3.5)
assert(si.d == 42)
assert(si.e == "foo")
assert(si.f == [1])
assert(si.g == P2StaticInit.g)
assert(si.aa == nil)
assert(si.ab == nil)
P2StaticInit.f.push(2)
assert(P2StaticInit.f == [1, 2])
assert(si.f == [1, 2])

class P2StaticBase
    static a = 1
end

class P2StaticChild : P2StaticBase
    static a = P2StaticBase
    static b = 1
    static c = P2StaticBase
    def f()
        return self.b
    end
end

var sc = P2StaticChild()
assert(P2StaticBase.a == 1)
assert(P2StaticChild.a == P2StaticBase)
assert(P2StaticChild.b == 1)
assert(P2StaticChild.c == P2StaticBase)
assert(sc.a == P2StaticBase)
assert(sc.f() == 1)

class P2StaticClassRef
    static var a = 1
    static var b = _class
    static var c = [_class.a, _class.b]
    static def cls()
        return _class
    end
end

assert(P2StaticClassRef.a == 1)
assert(P2StaticClassRef.b == P2StaticClassRef)
assert(P2StaticClassRef.c == [1, P2StaticClassRef])
assert(P2StaticClassRef.cls() == P2StaticClassRef)

class P2StaticOuter
    static class Inner
        static def f()
            return 1
        end
        def g()
            return 2
        end
    end
end

var outer = P2StaticOuter()
var inner = P2StaticOuter.Inner()
var inner_class = P2StaticOuter.Inner
var inner2 = inner_class()
assert(classname(outer) == "P2StaticOuter")
assert(classname(inner) == "Inner")
assert(inner_class == P2StaticOuter.Inner)
assert(classof(inner2) == P2StaticOuter.Inner)
assert(P2StaticOuter.Inner.f() == 1)
assert(inner.g() == 2)
assert(inner2.g() == 2)
assert(super(P2StaticOuter.Inner) == nil)

print("P2_SMOKE_PASS static_classes")
