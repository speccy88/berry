print("P2_SMOKE_BEGIN solidify")

import solidify
import introspect

def expect_error(f, error_type)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == error_type)
    end
    assert(caught)
end

assert(type(solidify) == "module")
assert(type(solidify.dump) == "function")
assert(type(solidify.compact) == "function")
assert(introspect.contains(solidify, "dump"))
assert(introspect.contains(solidify, "compact"))

assert(solidify.dump() == nil)
assert(solidify.compact() == nil)
expect_error(def () solidify.dump(42) end, "value_error")
expect_error(def () solidify.dump("not solidifiable") end, "value_error")
expect_error(def () solidify.compact(42) end, "value_error")
expect_error(def () solidify.compact("not compactable") end, "value_error")

class P2SolidifySmoke
    def value()
        return 42
    end
end

assert(solidify.compact(P2SolidifySmoke) == nil)
assert(P2SolidifySmoke().value() == 42)
assert(solidify.compact(P2SolidifySmoke) == nil)
assert(P2SolidifySmoke().value() == 42)

class P2SolidifyBase
    def value()
        return 19
    end
end

class P2SolidifyChild : P2SolidifyBase
    static label = "child"

    static def tag()
        return P2SolidifyChild.label
    end

    def value()
        return super().value() + 23
    end
end

assert(solidify.compact(P2SolidifyChild) == nil)
assert(P2SolidifyChild().value() == 42)
assert(P2SolidifyChild.tag() == "child")
P2SolidifyChild.label = "updated"
assert(P2SolidifyChild.tag() == "updated")
assert(P2SolidifyChild().value() == 42)

if introspect.contains(solidify, "nocompact")
    assert(type(solidify.nocompact) == "function")
    def p2_solidify_function()
        return 42
    end
    assert(solidify.nocompact(p2_solidify_function) == nil)
    assert(p2_solidify_function() == 42)
    expect_error(def () solidify.nocompact(42) end, "value_error")
    expect_error(def () solidify.nocompact("not a function") end, "value_error")
end

print("P2_SMOKE_PASS solidify")
