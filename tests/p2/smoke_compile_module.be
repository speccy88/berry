print("P2_SMOKE_BEGIN compile_module")

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

assert(true)
assert(1 + 1 == 2, "assert message should not be evaluated on success")
expect_error(def () assert(false) end, "assert_failed")
expect_error(def () assert(false, "p2 assert smoke") end, "assert_failed")

var fn = compile("return 21 + 21")
assert(type(fn) == "function")
assert(fn() == 42)

var fn2 = compile("def add(a,b) return a + b end return add(19, 23)")
assert(type(fn2) == "function")
assert(fn2() == 42)

var fn_closure = compile("def make(base) def add(x) return base + x end return add end return make(40)")
var compiled_adder = fn_closure()
assert(type(compiled_adder) == "function")
assert(compiled_adder(2) == 42)

var fn_state = compile("def make() var total = 40 def add(x) total += x return total end return add end return make()")
var compiled_counter = fn_state()
assert(compiled_counter(1) == 41)
assert(compiled_counter(1) == 42)

var fn_local_collection = compile("var values = [20, 21] values.push(1) return values[0] + values[1] + values[2]")
assert(fn_local_collection() == 42)

var fn_local_map = compile("var values = {\"a\": 20} values[\"b\"] = 22 return values[\"a\"] + values[\"b\"]")
assert(fn_local_map() == 42)

expect_error(def () compile("var a,b def f() a b end") end, "syntax_error")
expect_error(def () compile("return (1 +") end, "syntax_error")

import global
global.p2_compile_smoke_value = 40
var fn3 = compile("return p2_compile_smoke_value + 2")
assert(fn3() == 42)
global.p2_compile_smoke_value = 41
assert(fn3() == 43)
global.undef("p2_compile_smoke_value")
assert(!global.contains("p2_compile_smoke_value"))

var mod = module("p2_compile_module_smoke")
assert(type(mod) == "module")
mod.answer = 42
mod.name = "berry"
mod.fn = def (x) return x + 1 end
assert(mod.answer == 42)
assert(mod.name == "berry")
assert(mod.fn(41) == 42)

global.p2_compile_module_ref = mod
var compiled_module_update = compile("p2_compile_module_ref.answer += 1 return p2_compile_module_ref.answer")
assert(compiled_module_update() == 43)
assert(mod.answer == 43)
global.undef("p2_compile_module_ref")

import introspect
assert(introspect.name(mod) == "p2_compile_module_smoke")
assert(introspect.contains(mod, "answer"))
assert(introspect.get(mod, "answer") == 43)
introspect.set(mod, "answer", 84)
assert(mod.answer == 84)

var same_name = module("p2_compile_module_smoke")
assert(type(same_name) == "module")
same_name.answer = 21
assert(same_name.answer == 21)
assert(mod.answer == 84)

print("P2_SMOKE_PASS compile_module")
