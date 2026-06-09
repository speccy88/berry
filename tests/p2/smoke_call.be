print("P2_SMOKE_BEGIN call")

def expect_type_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "type_error")
    end
end

def fixed3(a, b, c)
    return [a, b, c]
end

expect_type_error(def () call(nil) end)
expect_type_error(def () call(42) end)
expect_type_error(def () call([], 1) end)

assert(call(fixed3) == [nil, nil, nil])
assert(call(fixed3, 1) == [1, nil, nil])
assert(call(fixed3, 1, 2) == [1, 2, nil])
assert(call(fixed3, 1, 2, 3, 4) == [1, 2, 3])
assert(call(fixed3, []) == [nil, nil, nil])
assert(call(fixed3, [1]) == [1, nil, nil])
assert(call(fixed3, [1, 2]) == [1, 2, nil])
assert(call(fixed3, [1, 2, 3, 4]) == [1, 2, 3])
assert(call(fixed3, [1, nil, 3]) == [1, nil, 3])
assert(call(fixed3, 1, []) == [1, nil, nil])
assert(call(fixed3, 1, [2]) == [1, 2, nil])
assert(call(fixed3, 1, [2, "foo", 4]) == [1, 2, "foo"])
assert(call(fixed3, 1, [2, 3, 4], "foo") == [1, [2, 3, 4], "foo"])
assert(call(fixed3, [[1, 2], 3, 4]) == [[1, 2], 3, 4])

def varargs(a, *b)
    if size(b) == 0
        return [a, nil, nil]
    elif size(b) == 1
        return [a, b[0], nil]
    else
        return [a, b[0], b[1]]
    end
end

assert(call(varargs) == [nil, nil, nil])
assert(call(varargs, 1) == [1, nil, nil])
assert(call(varargs, 1, 2) == [1, 2, nil])
assert(call(varargs, 1, 2, 3, 4) == [1, 2, 3])
assert(call(varargs, []) == [nil, nil, nil])
assert(call(varargs, [1]) == [1, nil, nil])
assert(call(varargs, [1, 2]) == [1, 2, nil])
assert(call(varargs, [1, 2, 3, 4]) == [1, 2, 3])
assert(call(varargs, [1, nil, 3]) == [1, nil, 3])
assert(call(varargs, 1, []) == [1, nil, nil])
assert(call(varargs, 1, [2]) == [1, 2, nil])
assert(call(varargs, 1, [2, "foo", 4]) == [1, 2, "foo"])
assert(call(varargs, 1, [2, 3, 4], "foo") == [1, [2, 3, 4], "foo"])
assert(call(varargs, [[1, 2], 3, 4]) == [[1, 2], 3])

def varargs_only(*a)
    return size(a)
end

assert(call(varargs_only) == 0)
assert(call(varargs_only, 1) == 1)
assert(call(varargs_only, 1, 2) == 2)
assert(call(varargs_only, 1, 2, 3, 4) == 4)
assert(call(varargs_only, []) == 0)
assert(call(varargs_only, [1]) == 1)
assert(call(varargs_only, [1, 2]) == 2)
assert(call(varargs_only, [1, 2, 3, 4]) == 4)
assert(call(varargs_only, 1, []) == 1)
assert(call(varargs_only, 1, [2]) == 2)
assert(call(varargs_only, 1, [2, "foo", 4]) == 4)
assert(call(varargs_only, 1, [2, 3, 4], "foo") == 3)

def make_adder(base)
    def add(a, b)
        return base + a + b
    end
    return add
end

var add5 = make_adder(5)
assert(call(add5, 17, 20) == 42)
assert(call(add5, [17, 20]) == 42)

import string

assert(call(string.format, "a") == "a")
assert(call(string.format, "%i", 1) == "1")
assert(call(string.format, "%i - %i", 1, 2) == "1 - 2")
assert(call(string.format, "%i - %i", [1, 2]) == "1 - 2")
assert(call(string.format, "%i - %i", [1, 2, 3]) == "1 - 2")
assert(call(string.format, "%i - %i", 1, [1, 2, 3]) == "1 - 1")

var many = []
for i: 1..50
    many.push(i)
end
assert(call(varargs, many) == [1, 2, 3])
assert(call(varargs_only, many) == 50)

class CallSmokeClass
    var value
    def init(x)
        self.value = x
    end
end

var inst = call(CallSmokeClass, 42)
assert(isinstance(inst, CallSmokeClass))
assert(inst.value == 42)
var inst_from_list = call(CallSmokeClass, [43])
assert(isinstance(inst_from_list, CallSmokeClass))
assert(inst_from_list.value == 43)

class CallMethodSmoke
    var base
    def init(base)
        self.base = base
    end
    def add(a, b)
        return self.base + a + b
    end
end

var method_target = CallMethodSmoke(5)
assert(call(method_target.add, 17, 20) == 42)
assert(call(method_target.add, [17, 20]) == 42)

print("P2_SMOKE_PASS call")
