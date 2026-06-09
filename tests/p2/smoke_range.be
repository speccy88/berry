print("P2_SMOKE_BEGIN range")

def expand(iter)
    var out = []
    for i : iter
        out.push(i)
    end
    return out
end

def expect_value_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "value_error")
    end
end

def expect_compiled_value_error(code)
    try
        compile(code)()
        assert(false)
    except .. as e, m
        assert(e == "value_error")
    end
end

assert(expand(0..5) == [0, 1, 2, 3, 4, 5])
assert(expand(0..0) == [0])
assert(expand(5..0) == [])

assert(expand(range(0, 5)) == [0, 1, 2, 3, 4, 5])
assert(expand(range(0, 5, 2)) == [0, 2, 4])
assert(expand(range(0, 5, 12)) == [0])
assert(expand(range(0, 5, -1)) == [])

assert(expand(range(5, 0, -1)) == [5, 4, 3, 2, 1, 0])
assert(expand(range(5, 0, -2)) == [5, 3, 1])
assert(expand(range(5, 5, -2)) == [5])
assert(expand(range(0, 5, -2)) == [])
assert(expand(range(30, 0, -3)) == [30, 27, 24, 21, 18, 15, 12, 9, 6, 3, 0])

var r = range(3, 7)
assert(type(r.lower) == "function")
assert(type(r.upper) == "function")
assert(type(r.incr) == "function")
assert(type(r.iter) == "function")
assert(type(r.setrange) == "function")
assert(r.lower() == 3)
assert(r.upper() == 7)
assert(r.incr() == 1)
assert(str(r) == "(3..7)")

var r2 = range(0, 20, 5)
assert(r2.lower() == 0)
assert(r2.upper() == 20)
assert(r2.incr() == 5)
assert(str(r2) == "range(0, 20, 5)")

var r3 = range(10, 0, -2)
assert(r3.lower() == 10)
assert(r3.upper() == 0)
assert(r3.incr() == -2)
assert(str(range(10, 0, -1)) == "range(10, 0, -1)")

var r4 = range(1, 5)
r4.setrange(10, 20)
assert(r4.lower() == 10)
assert(r4.upper() == 20)
assert(r4.incr() == 1)

r4.setrange(0, 100, 10)
assert(r4.lower() == 0)
assert(r4.upper() == 100)
assert(r4.incr() == 10)

var r5 = range(1, 3)
r5.setrange(5, 9, 2)
assert(expand(r5) == [5, 7, 9])

var r6 = range(0, 0)
r6.setrange(6, 0, -3)
assert(r6.lower() == 6)
assert(r6.upper() == 0)
assert(r6.incr() == -3)
assert(expand(r6) == [6, 3, 0])

var reusable = range(2, 6, 2)
var iter_a = reusable.iter()
var iter_b = reusable.iter()
assert(iter_a() == 2)
assert(iter_a() == 4)
assert(iter_b() == 2)
assert(iter_a() == 6)
assert(iter_b() == 4)
assert(iter_b() == 6)
assert(iter_b() == nil)
assert(expand(reusable) == [2, 4, 6])

var retarget = range(1, 3)
var old_iter = retarget.iter()
assert(old_iter() == 1)
retarget.setrange(10, 14, 2)
assert(old_iter() == 2)
assert(old_iter() == 3)
assert(old_iter() == nil)
assert(expand(retarget) == [10, 12, 14])

var neg_retarget = range(6, 2, -2)
var neg_old_iter = neg_retarget.iter()
assert(neg_old_iter() == 6)
neg_retarget.setrange(1, 3)
assert(neg_old_iter() == 4)
assert(neg_old_iter() == 2)
assert(neg_old_iter() == nil)
assert(expand(neg_retarget) == [1, 2, 3])

expect_compiled_value_error("range(1, 2, 0)")
expect_value_error(def () range(1) end)
expect_value_error(def () range(1, 2.0) end)
expect_value_error(def ()
    var bad = range(1, 5)
    bad.setrange(1)
end)
expect_value_error(def ()
    var bad = range(1, 5)
    bad.setrange(1, "bad")
end)
expect_value_error(def ()
    var bad = range(1, 5)
    bad.setrange(1, 10, 0)
end)

print("P2_SMOKE_PASS range")
