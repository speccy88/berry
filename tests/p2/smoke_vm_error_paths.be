print("P2_SMOKE_BEGIN vm_error_paths")

def expect_error(f, expected)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == expected)
        assert(m == nil || type(m) == "string")
    end
    assert(caught)
end

def neg(x) return -x end
def flip(x) return ~x end
def add(a, b) return a + b end
def sub(a, b) return a - b end
def div(a, b) return a / b end
def mod(a, b) return a % b end
def mul(a, b) return a * b end
def shl(a, b) return a << b end
def shr(a, b) return a >> b end
def conn(a, b) return a .. b end
def call_it(f) return f() end

expect_error(def () neg("hello") end, "type_error")
expect_error(def () flip(1.5) end, "type_error")
expect_error(def () call_it(42) end, "type_error")
expect_error(def () add(true, false) end, "type_error")
expect_error(def () sub("a", "b") end, "type_error")
expect_error(def () div("a", 2) end, "type_error")
expect_error(def () mod("a", 2) end, "type_error")
expect_error(def () conn(1.5, 2.5) end, "type_error")
expect_error(def () mul("abc", 1.5) end, "type_error")
expect_error(def () shl("abc", 1) end, "type_error")
expect_error(def () shr(42, "bad") end, "type_error")

class P2VmVec
    var v
    def init(n)
        self.v = n
    end
    def -(other)
        return P2VmVec(self.v - other.v)
    end
    def -*(other)
        return P2VmVec(-self.v)
    end
    def ~(other)
        return P2VmVec(~self.v)
    end
    def *(other)
        return P2VmVec(self.v * other.v)
    end
    def /(other)
        return P2VmVec(self.v / other.v)
    end
    def %(other)
        return P2VmVec(self.v % other.v)
    end
end

var a = P2VmVec(10)
var b = P2VmVec(3)
assert(sub(a, b).v == 7)
assert(mul(a, b).v == 30)
assert(div(a, b).v == 3)
assert(mod(a, b).v == 1)
assert(neg(a).v == -10)
assert(flip(b).v == ~3)

class P2VmNoTobool
    var x
    def init(n)
        self.x = n
    end
end
assert(bool(P2VmNoTobool(0)) == true)

class P2VmBadEq
    def ==(other)
        return 42
    end
end
expect_error(def ()
    return P2VmBadEq() == P2VmBadEq()
end, "type_error")

class P2VmBadLt
    def <(other)
        return 42
    end
end
expect_error(def ()
    return P2VmBadLt() < P2VmBadLt()
end, "type_error")

class P2VmPlain
    var x
    def init()
        self.x = 1
    end
end
expect_error(def ()
    var p = P2VmPlain()
    return p.nonexistent
end, "attribute_error")
expect_error(def ()
    var p = P2VmPlain()
    p.no_such_method()
end, "attribute_error")

class P2VmStatic
    static x = 10
end
expect_error(def ()
    return P2VmStatic.nonexistent
end, "attribute_error")

import global
global.p2_vm_error_paths_ngbl = 99
assert(global.p2_vm_error_paths_ngbl == 99)
global.p2_vm_error_paths_ngbl = 100
assert(global.p2_vm_error_paths_ngbl == 100)
global.undef("p2_vm_error_paths_ngbl")
assert(!global.contains("p2_vm_error_paths_ngbl"))

print("P2_SMOKE_PASS vm_error_paths")
