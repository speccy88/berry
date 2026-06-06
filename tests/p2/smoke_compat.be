print("P2_SMOKE_BEGIN compat")

print("P2_COMPAT_PRINT_OK")

class CompatBase
    var base_value
    def init(v)
        self.base_value = v
    end
    def value()
        return self.base_value
    end
end

class CompatChild : CompatBase
    var child_value
    def init(a, b)
        super(self).init(a)
        self.child_value = b
    end
    def total()
        return self.value() + self.child_value
    end
end

var child = CompatChild(19, 23)
assert(child.total() == 42)
assert(classname(child) == "CompatChild")
assert(classof(child) == CompatChild)
assert(classof(super(child)) == CompatBase)
assert(super(super(child)) == nil)
assert(issubclass(CompatChild, CompatBase))
assert(!issubclass(CompatBase, CompatChild))
assert(isinstance(child, CompatChild))
assert(isinstance(child, CompatBase))
assert(!isinstance(child, map))

assert(str(42) == "42")
assert(number("42") == 42)
assert(type(number("3.5")) == "real")
assert(int("0x2a") == 42)
assert(int(true) == 1)
assert(real("42.5") == 42.5)
assert(real(42) == 42.0)
assert(bool() == false)
assert(bool(0) == false)
assert(bool(1) == true)
assert(bool("") == false)
assert(bool("x") == true)
assert(type(child) == "instance")
assert(type(CompatChild) == "class")
assert(size("berry") == 5)

var l = list()
l.push(1)
l.push(2)
assert(l == [1, 2])
assert(isinstance(l, list))

var m = map()
m["a"] = 20
m["b"] = 22
assert(m["a"] + m["b"] == 42)
assert(isinstance(m, map))

var rtotal = 0
for i : range(1, 6)
    rtotal += i
end
assert(rtotal == 15)

var by = bytes().fromstring("AB")
assert(by.tohex() == "4142")
assert(by.asstring() == "AB")

var compiled = compile("return 21 + 21")
assert(type(compiled) == "function")
assert(compiled() == 42)

def add3(a, b, c)
    return [a, b, c]
end
assert(call(add3, 1, [2, 3]) == [1, 2, 3])

var compat_mod = module("p2_compat_smoke")
compat_mod.answer = 42
assert(type(compat_mod) == "module")
assert(compat_mod.answer == 42)

import introspect
assert(introspect.name(compat_mod) == "p2_compat_smoke")
assert(type(introspect.toptr(0)) == "ptr")
assert(introspect.contains(compat_mod, "answer"))
assert(introspect.get(compat_mod, "answer") == 42)
introspect.set(compat_mod, "answer", 84)
assert(compat_mod.answer == 84)
assert(introspect.get(compat_mod, "answer") == 84)
assert(introspect.name(introspect.module("json")) == "json")
assert(introspect.module("p2_no_such_module") == nil)
var compat_members = introspect.members(compat_mod)
assert(isinstance(compat_members, list))
var compat_member_seen = false
for name: compat_members
    if name == "answer"
        compat_member_seen = true
    end
end
assert(compat_member_seen)
def compat_function() return 1 end
assert(type(introspect.toptr(compat_function)) == "ptr")
assert(introspect.fromptr(0) == nil)
assert(introspect.solidified(compat_function) == false)
assert(introspect.ismethod(compat_function) == false)

import global
global.p2_compat_value = 42
assert(global.p2_compat_value == 42)
assert(global.contains("p2_compat_value"))
global.undef("p2_compat_value")
assert(!global.contains("p2_compat_value"))

import time
assert(type(time) == "module")

import solidify
assert(type(solidify) == "module")
assert(type(solidify.dump) == "function")
assert(type(solidify.compact) == "function")

import strict
assert(type(strict) == "module")

print("P2_SMOKE_PASS compat")
