print("P2_SMOKE_BEGIN virtual_members")

import introspect
import undefined

def expect_attribute_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "attribute_error")
    end
    assert(caught)
end

assert(type(undefined) == "module")
assert(str(undefined) == "<module: undefined>")
assert(introspect.name(undefined) == "undefined")

class P2VirtualBase
    var a, b
    def init()
        self.a = 1
        self.b = 2
    end
    def f()
        return true
    end
    def g()
        return false
    end
end

var base = P2VirtualBase()
assert(base.a == 1)
assert(base.b == 2)
assert(base.f() == true)
assert(base.g() == false)
expect_attribute_error(def () base.h() end)
expect_attribute_error(def () return base.no_such_field end)

class P2VirtualChild : P2VirtualBase
    def member(name)
        if name == "a"
            return 99
        end
        if name == "f"
            return def ()
                return false
            end
        end
        if name == "f1"
            return def (self_ref)
                return self_ref
            end
        end
        if name == "f2"
            return def ()
                return 4
            end
        end
        if name == "a1"
            return 10
        end
        if name == "combo"
            return self.a + self.b
        end
        if name == "blocked"
            return undefined
        end
    end
end

var child = P2VirtualChild()
assert(child.a == 1)
assert(child.b == 2)
assert(child.f() == true)
assert(child.g() == false)
assert(child.f1() == child)
assert(child.f2() == 4)
assert(child.a1 == 10)
assert(child.combo == 3)
var virtual_name = "combo"
assert(child.(virtual_name) == 3)
assert(child.no_such_virtual == nil)
expect_attribute_error(def () child.blocked() end)
expect_attribute_error(def () return child.blocked end)

var dyn = module("p2_virtual_member_smoke")
dyn.base = 40
dyn.member = def (name)
    if name == "base"
        return 999
    end
    if name == "answer"
        return dyn.base + 2
    end
    if name == "fn"
        return def ()
            return dyn.answer
        end
    end
    if name == "missing"
        return undefined
    end
end

assert(dyn.base == 40)
assert(dyn.answer == 42)
assert(dyn.fn() == 42)
var dyn_virtual_name = "answer"
assert(dyn.(dyn_virtual_name) == 42)
var dyn_fn_name = "fn"
var dyn_fn = dyn.(dyn_fn_name)
assert(dyn_fn() == 42)
assert(dyn.no_response == nil)
expect_attribute_error(def () return dyn.missing end)

var probe = introspect.get(child, "not_present", true)
assert(type(probe) == "module")
assert(introspect.name(probe) == "undefined")
var module_probe = introspect.get(dyn, "missing", true)
assert(type(module_probe) == "module")
assert(introspect.name(module_probe) == "undefined")
assert(introspect.get(child, "not_present", "fallback") == "fallback")

print("P2_SMOKE_PASS virtual_members")
