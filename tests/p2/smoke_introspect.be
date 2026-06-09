print("P2_SMOKE_BEGIN introspect")

import introspect

assert(type(introspect) == "module")
assert(type(introspect.name) == "function")
assert(type(introspect.contains) == "function")
assert(type(introspect.get) == "function")
assert(type(introspect.set) == "function")
assert(type(introspect.members) == "function")
assert(type(introspect.module) == "function")
assert(type(introspect.toptr) == "function")
assert(type(introspect.fromptr) == "function")
assert(type(introspect.solidified) == "function")
assert(type(introspect.ismethod) == "function")

def has_member(items, wanted)
    for item: items
        if item == wanted
            return true
        end
    end
    return false
end

def expect_value_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "value_error")
    end
    assert(caught)
end

var mod = module("p2_introspect_smoke")
mod.answer = 42
mod.fn = def (x) return x + 1 end

assert(introspect.name(mod) == "p2_introspect_smoke")
assert(introspect.contains(mod, "answer"))
assert(!introspect.contains(mod, "missing"))
assert(introspect.get(mod, "answer") == 42)
assert(type(introspect.get(mod, "fn")) == "function")
assert(introspect.get(mod, "missing", "fallback") == "fallback")
introspect.set(mod, "answer", 84)
assert(mod.answer == 84)
assert(introspect.get(mod, "answer") == 84)

var mod_members = introspect.members(mod)
assert(isinstance(mod_members, list))
assert(has_member(mod_members, "answer"))
assert(has_member(mod_members, "fn"))

class P2Intro
    static var static_value
    var value
    def init(v)
        self.value = v
    end
    def inc(n)
        return self.value + n
    end
    static def static_inc(n)
        return n + 1
    end
end

P2Intro.static_value = 7
var obj = P2Intro(35)
assert(introspect.name(P2Intro) == "P2Intro")
assert(introspect.name(P2Intro.inc) == "inc")
assert(introspect.name(P2Intro.static_inc) == "static_inc")
assert(introspect.contains(P2Intro, "value"))
assert(introspect.contains(P2Intro, "inc"))
assert(introspect.contains(obj, "value"))
assert(introspect.contains(obj, "inc"))
assert(!introspect.contains(obj, "nope"))
assert(introspect.get(obj, "value") == 35)
assert(introspect.get(obj, "static_value") == 7)
assert(introspect.get(obj, "inc")(7) == 42)
introspect.set(obj, "value", 41)
assert(obj.inc(1) == 42)

var class_members = introspect.members(P2Intro)
assert(has_member(class_members, "value"))
assert(has_member(class_members, "inc"))
assert(has_member(class_members, "static_value"))
var obj_members = introspect.members(obj)
assert(has_member(obj_members, "value"))
assert(has_member(obj_members, "inc"))

def plain_function()
    return 1
end

assert(introspect.ismethod() == nil)
assert(introspect.ismethod(introspect) == nil)
assert(introspect.ismethod(introspect.ismethod) == nil)
assert(introspect.ismethod(plain_function) == false)
assert(introspect.ismethod(P2Intro.inc) == true)
assert(introspect.ismethod(P2Intro.static_inc) == false)
assert(introspect.ismethod(obj.inc) == true)
assert(introspect.ismethod(obj.static_inc) == false)

assert(type(introspect.toptr("hello")) == "ptr")
assert(type(introspect.toptr(plain_function)) == "ptr")
assert(introspect.toptr() == nil)
expect_value_error(def () introspect.toptr(true) end)
expect_value_error(def () introspect.toptr(1.5) end)

var values = [10, 20, 30]
var ptr = introspect.toptr(values)
assert(type(ptr) == "ptr")
var recovered = introspect.fromptr(ptr)
assert(isinstance(recovered, list))
assert(recovered == [10, 20, 30])
assert(introspect.fromptr() == nil)
assert(introspect.fromptr(0) == nil)

assert(introspect.solidified(plain_function) == false)
assert(introspect.solidified("hello") == false)
assert(introspect.solidified(42) == nil)
assert(introspect.solidified() == nil)
assert(isinstance(introspect.members(), list))
assert(isinstance(introspect.members(nil), list))
assert(introspect.members(42) == [])
assert(introspect.get(42, "x") == nil)
assert(introspect.module("json") != nil)
assert(introspect.module("p2_introspect_no_such_module") == nil)

print("P2_SMOKE_PASS introspect")
