print("P2_SMOKE_BEGIN exception_assert")

def p2_assert_pass()
    assert(true, "should not fail")
    return 42
end

def p2_assert_fail(msg)
    assert(false, msg)
end

try
    for k : 0..1
        assert({"a": 1}.contains("b"), "failure")
    end
    assert(false)
except .. as e, m
    assert(e == "assert_failed")
    assert(m == "failure")
end

assert(p2_assert_pass() == 42)

var caught_default_assert = false
try
    assert(false)
except .. as ed, md
    caught_default_assert = true
    assert(ed == "assert_failed")
    assert(md == nil || type(md) == "string")
end
assert(caught_default_assert)

caught_call_assert = false
try
    p2_assert_fail("call failure")
except .. as e2, m2
    caught_call_assert = true
    assert(e2 == "assert_failed")
    assert(m2 == "call failure")
end
assert(caught_call_assert)

def p2_make_assert_closure(msg)
    return def ()
        assert(false, msg)
    end
end

var caught_closure_assert = false
try
    var closure_assert = p2_make_assert_closure("closure failure")
    closure_assert()
except .. as e3, m3
    caught_closure_assert = true
    assert(e3 == "assert_failed")
    assert(m3 == "closure failure")
end
assert(caught_closure_assert)

class P2AssertCarrier
    def fail(msg)
        assert(false, msg)
    end
end

var caught_method_assert = false
try
    P2AssertCarrier().fail("method failure")
except .. as e4, m4
    caught_method_assert = true
    assert(e4 == "assert_failed")
    assert(m4 == "method failure")
end
assert(caught_method_assert)

print("P2_SMOKE_PASS exception_assert")
