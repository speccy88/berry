print("P2_SMOKE_BEGIN member_indirect")

var module_member = module("p2_member_indirect")
module_member.("aa") = 1
module_member.("a" + "b") = 2
var ac_name = "ac"
module_member.(ac_name) = 3
module_member.fn = def (x)
    return x + 1
end

assert(module_member.aa == 1)
assert(module_member.ab == 2)
assert(module_member.ac == 3)
assert(module_member.("a" + "a") == 1)
var module_fn_name = "fn"
assert(module_member.(module_fn_name)(41) == 42)

class P2IndirectStatic
    static a = 1, b = 2
    static s = "foo"
    def f()
        return 0
    end
end

assert(P2IndirectStatic.("a") == 1)
assert(P2IndirectStatic.("b") == 2)
assert(P2IndirectStatic.("s") == "foo")
assert(type(P2IndirectStatic.("f")) == "function")
var static_methods = ["f"]
assert(P2IndirectStatic.(static_methods[0])() == 0)
var static_name = "a"
P2IndirectStatic.(static_name) = 41
assert(P2IndirectStatic.a == 41)
assert(P2IndirectStatic.(static_name) == 41)

class P2IndirectInstance
    var a, b
    static s_a = "a"
    def init(a, b)
        self.(self.("s_a")) = a
        self.("b") = b
    end
    def f(x)
        return x + 1
    end
    def g(a, b)
        return P2IndirectInstance(a, b)
    end
end

var inst = P2IndirectInstance(1, 2)
assert(inst.a == 1)
assert(inst.b == 2)
assert(inst.(P2IndirectInstance.s_a) == 1)
assert(inst.("b") == 2)

inst.("a") = 10
inst.("bb"[0]) = 11
assert(inst.a == 10)
assert(inst.b == 11)

assert(inst.f(1) == 2)
assert(inst.("f")(2) == 3)
assert(inst.("g")(3, 4).("a") == 3)
var method_names = ["f", "g"]
assert(inst.(method_names[0])(41) == 42)
assert(inst.(method_names[1])(5, 6).b == 6)

inst.("a") = inst.g(3, 4)
assert(inst.a.b == 4)
assert(inst.("a").b == 4)
assert(inst.("a").("b") == 4)
assert(inst.a.("b") == 4)

inst.("a").("b") += 1
assert(inst.a.b == 5)

print("P2_SMOKE_PASS member_indirect")
