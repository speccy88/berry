print("P2_SMOKE_BEGIN introspect_ismethod")

import introspect

assert(introspect.ismethod() == nil)
assert(introspect.ismethod(true) == nil)
assert(introspect.ismethod("a") == nil)
assert(introspect.ismethod([]) == nil)
assert(introspect.ismethod({}) == nil)
assert(introspect.ismethod(introspect) == nil)
assert(introspect.ismethod(introspect.ismethod) == nil)

def p2_plain_function()
end

class P2IsMethodClass
    def f()
    end
    static def g()
    end
    var h
end

class P2IsMethodChild : P2IsMethodClass
end

var instance = P2IsMethodClass()
instance.h = p2_plain_function
var child = P2IsMethodChild()

assert(introspect.ismethod(p2_plain_function) == false)
assert(introspect.ismethod(P2IsMethodClass.f) == true)
assert(introspect.ismethod(P2IsMethodClass.g) == false)
assert(introspect.ismethod(instance.f) == true)
assert(introspect.ismethod(instance.g) == false)
assert(introspect.ismethod(instance.h) == false)
assert(introspect.ismethod(P2IsMethodChild.f) == true)
assert(introspect.ismethod(P2IsMethodChild.g) == false)
assert(introspect.ismethod(child.f) == true)
assert(introspect.ismethod(child.g) == false)

var saved_method = instance.f
var saved_static_method = instance.g
var saved_function_member = instance.h
var saved_child_method = child.f
var saved_child_static_method = child.g
assert(introspect.ismethod(saved_method) == true)
assert(introspect.ismethod(saved_static_method) == false)
assert(introspect.ismethod(saved_function_member) == false)
assert(introspect.ismethod(saved_child_method) == true)
assert(introspect.ismethod(saved_child_static_method) == false)

print("P2_SMOKE_PASS introspect_ismethod")
