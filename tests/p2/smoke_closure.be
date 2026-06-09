print("P2_SMOKE_BEGIN closure")

def make_counter(start)
    var n = start
    return def ()
        n += 1
        return n
    end
end

var c1 = make_counter(0)
var c2 = make_counter(10)
assert(type(c1) == "function")
assert(type(c2) == "function")
assert(c1() == 1)
assert(c1() == 2)
assert(c2() == 11)
assert(c1() == 3)
assert(c2() == 12)

def make_reader_after_mutation()
    var value = 1
    var reader = def ()
        return value
    end
    value = 42
    return reader
end

var reader = make_reader_after_mutation()
assert(reader() == 42)

var loop_closures = []
def capture_loop_values()
    var start = 100
    for i : 1..3
        loop_closures.push(def ()
            return [i, start]
        end)
    end
end

capture_loop_values()
assert(loop_closures[0]() == [1, 100])
assert(loop_closures[1]() == [2, 100])
assert(loop_closures[2]() == [3, 100])

def make_adder(a)
    return def (b)
        return a + b
    end
end

var add40 = make_adder(40)
assert(add40(2) == 42)

def make_nested(base)
    var outer = base
    def middle(delta)
        var inner = delta
        return def (extra)
            outer += 1
            inner += extra
            return outer + inner
        end
    end
    return middle
end

var nested_factory = make_nested(30)
var nested_closure = nested_factory(5)
assert(nested_closure(6) == 42)
assert(nested_closure(0) == 43)

def compile_closure_shape()
    var nv = 1
    var f = def ()
        nv += 2 * 1
        return nv
    end
    return f
end

var compiled_shape = compile_closure_shape()
assert(compiled_shape() == 3)
assert(compiled_shape() == 5)

def make_list_accumulator()
    var values = []
    return def (value)
        values.push(value)
        return values.copy()
    end
end

var list_accumulator = make_list_accumulator()
var first_snapshot = list_accumulator(7)
assert(first_snapshot == [7])
first_snapshot.push(99)
assert(list_accumulator(8) == [7, 8])
assert(list_accumulator(27) == [7, 8, 27])
var second_accumulator = make_list_accumulator()
assert(second_accumulator(1) == [1])
assert(list_accumulator(0) == [7, 8, 27, 0])
assert(second_accumulator(2) == [1, 2])

print("P2_SMOKE_PASS closure")
