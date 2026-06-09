print("P2_SMOKE_BEGIN debug")

import debug
import introspect

assert(type(debug) == "module")
assert(type(debug.attrdump) == "function")
assert(type(debug.caller) == "function")
assert(introspect.contains(debug, "attrdump"))
assert(introspect.contains(debug, "caller"))

class P2DebugClass
    static value = 42
    def answer()
        return self.value
    end
end

debug.attrdump(P2DebugClass)
var debug_instance = P2DebugClass()
assert(debug_instance.answer() == 42)
debug.attrdump(debug_instance)
assert(debug_instance.answer() == 42)
assert(!debug.caller(64))

def p2_debug_caller_chain()
    var depth = 1
    var names = []
    assert(introspect.name(debug.caller(0)) == "p2_debug_caller_chain")
    var caller = debug.caller(depth)
    while caller
        names.push(introspect.name(caller))
        depth += 1
        caller = debug.caller(depth)
    end
    return names
end

def p2_debug_named_wrapper()
    return p2_debug_caller_chain()
end

def p2_debug_outer_wrapper()
    return p2_debug_named_wrapper()
end

var direct_chain = p2_debug_caller_chain()
assert(size(direct_chain) >= 1)
assert(direct_chain[0] == "p2_debug_caller_chain")

var wrapped_chain = p2_debug_named_wrapper()
assert(size(wrapped_chain) >= 2)
assert(wrapped_chain[0] == "p2_debug_caller_chain")
assert(wrapped_chain[1] == "p2_debug_named_wrapper")

var outer_chain = p2_debug_outer_wrapper()
assert(size(outer_chain) >= 3)
assert(outer_chain[0] == "p2_debug_caller_chain")
assert(outer_chain[1] == "p2_debug_named_wrapper")
assert(outer_chain[2] == "p2_debug_outer_wrapper")

print("P2_SMOKE_PASS debug")
