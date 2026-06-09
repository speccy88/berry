print("P2_SMOKE_BEGIN function_capture")

var p2_escaped_closure

def p2_function_capture_source()
    var captured = "p2-function-captured"
    var number = 400000 + 500
    def inner()
        return [captured, number]
    end
    p2_escaped_closure = inner
    return number
end

assert(p2_function_capture_source() == 400500)
assert(type(p2_escaped_closure) == "function")
assert(p2_escaped_closure() == ["p2-function-captured", 400500])

def p2_function_capture_factory(seed)
    var local = seed
    return def (delta)
        local += delta
        return local
    end
end

var a = p2_function_capture_factory(10)
var b = p2_function_capture_factory(100)
assert(type(a) == "function")
assert(type(b) == "function")
assert(a(1) == 11)
assert(a(2) == 13)
assert(b(5) == 105)
assert(a(0) == 13)

def p2_function_capture_param(base)
    var offset = 2
    return def (x)
        return base + offset + x
    end
end

var param_capture = p2_function_capture_param(30)
assert(param_capture(10) == 42)

def p2_function_capture_pair(seed)
    var shared = seed
    def inc(delta)
        shared += delta
        return shared
    end
    def get()
        return shared
    end
    return [inc, get]
end

var pair_capture = p2_function_capture_pair(20)
assert(pair_capture[1]() == 20)
assert(pair_capture[0](5) == 25)
assert(pair_capture[1]() == 25)
assert(pair_capture[0](17) == 42)
var other_pair_capture = p2_function_capture_pair(1)
assert(other_pair_capture[0](2) == 3)
assert(other_pair_capture[1]() == 3)
assert(pair_capture[1]() == 42)

print("P2_SMOKE_PASS function_capture")
