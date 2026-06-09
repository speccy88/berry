print("P2_SMOKE_BEGIN errors")

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

var normal = false
try
    normal = true
except .. as e, m
    assert(false)
end
assert(normal)

expect_error(def ()
    raise "p2_expected_error", "expected message"
end, "p2_expected_error")

expect_error(def ()
    compile("def broken(")
end, "syntax_error")

expect_error(def ()
    var f = nil
    f()
end, "type_error")

expect_error(def ()
    var b = bytes("334455")
    return b[-4]
end, "index_error")

expect_error(def ()
    var b = bytes("334455")
    b[4] = 0x11
end, "index_error")

expect_error(def ()
    return {"a": 1}["missing"]
end, "key_error")

def p2_raise_from_helper()
    raise "p2_helper_error", "helper message"
end

var helper_propagated = false
try
    p2_raise_from_helper()
except .. as e, m
    assert(e == "p2_helper_error")
    assert(m == "helper message")
    helper_propagated = true
end
assert(helper_propagated)

class P2ErrorCarrier
    def fail()
        raise "p2_method_error", "method message"
    end
end

var method_propagated = false
try
    P2ErrorCarrier().fail()
except .. as e, m
    assert(e == "p2_method_error")
    assert(m == "method message")
    method_propagated = true
end
assert(method_propagated)

var nested = false
try
    try
        raise "p2_nested_error", "nested message"
    except .. as e, m
        assert(e == "p2_nested_error")
        assert(m == "nested message")
        nested = true
    end
except .. as e, m
    assert(false)
end
assert(nested)

var rethrown = false
try
    try
        raise "p2_inner_error", "inner message"
    except .. as e, m
        assert(e == "p2_inner_error")
        raise "p2_outer_error", m
    end
except .. as e, m
    assert(e == "p2_outer_error")
    assert(m == "inner message")
    rethrown = true
end
assert(rethrown)

print("P2_SMOKE_PASS errors")
