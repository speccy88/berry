print("P2_SMOKE_BEGIN bool")

def boom()
    raise "p2_bool_error", "short-circuit branch executed"
end

var side_effects = 0
def mark(v)
    side_effects = side_effects + v
    return true
end

assert(1 != false && 1 != true)
assert(0 != false && 0 != true)
assert(!!1 == true)
assert(!!0 == false)
assert(!!nil == false)

var a = true
var b = false
assert(a && b == false)
assert(!(a && b))
assert(a || b)
assert(!(!a || b))
assert((true && true) == true)
assert((true && false) == false)
assert((false || true) == true)
assert((false || false) == false)

assert((false && boom()) == false)
assert((true || boom()) == true)
assert((false && mark(1)) == false)
assert(side_effects == 0)
assert((true || mark(1)) == true)
assert(side_effects == 0)
assert((true && mark(2)) == true)
assert(side_effects == 2)
assert((false || mark(3)) == true)
assert(side_effects == 5)
assert((true && 42) == true)
assert((false || 42) == true)
assert(("x" && [1]) == true)
assert(("x" || boom()) == true)
assert(([] && boom()) == false)
assert(({} || {"k": 1}) == true)
assert(([] || mark(4)) == true)
assert(side_effects == 9)

def bool_input_preserved(i)
    var j = !i
    return i
end
assert(bool_input_preserved(1) == 1)

assert(bool() == false)
assert(bool(0) == false)
assert(bool(0.0) == false)
assert(bool(false) == false)
assert(bool(nil) == false)
assert(bool(-1) == true)
assert(bool(3.5) == true)
assert(bool("") == false)
assert(bool("a") == true)
assert(bool(list) == true)
assert(bool(list()) == false)
assert(bool([]) == false)
assert(bool([0]) == true)
assert(bool(map()) == false)
assert(bool({}) == false)
assert(bool({false: false}) == true)
assert(bool({nil: nil}) == false)

def issue372()
    var a = false
    var b = true || a
    return a
end
assert(issue372() == false)

print("P2_SMOKE_PASS bool")
