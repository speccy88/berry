print("P2_SMOKE_BEGIN divzero")

def expect_divzero(f)
    var caught = false
    try
        f()
        assert(false)
    except .. as e, m
        caught = true
        assert(e == "divzero_error")
        assert(m == "division by zero")
    end
    assert(caught)
end

expect_divzero(def ()
    return 1 / 0
end)

expect_divzero(def ()
    return 1 % 0
end)

expect_divzero(def ()
    return 1.1 / 0.0
end)

expect_divzero(def ()
    return 1.1 % 0.0
end)

def computed_zero()
    return 5 - 5
end

expect_divzero(def ()
    return 10 / computed_zero()
end)

expect_divzero(def ()
    return 10 % computed_zero()
end)

assert(1 / 2 == 0)
assert(1 % 2 == 1)
assert(1.0 / 2.0 == 0.5)
assert(1.0 % 2.0 == 1.0)
assert(-5 / 2 == -2)
assert(-5 % 2 == -1)
assert(4 / 2 == 2)
assert(4 % 2 == 0)

print("P2_SMOKE_PASS divzero")
