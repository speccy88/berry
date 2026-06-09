print("P2_SMOKE_BEGIN strict")

def expect_syntax_error(code)
    var caught = false
    try
        compile(code)
    except .. as e, m
        caught = true
        assert(e == "syntax_error")
    end
    assert(caught)
end

import global
global.undef("p2_strict_known_global")

import strict
assert(type(strict) == "module")

expect_syntax_error("var a,b def f() a b end")
expect_syntax_error("var a,b def f() a end")
expect_syntax_error("return p2_strict_missing_global")

var side_effect_ok = compile("var a,b def f() a := b end return true")
assert(side_effect_ok() == true)

global.p2_strict_known_global = 42
var known_global = compile("return p2_strict_known_global")
assert(known_global() == 42)
var known_global_function = compile("def f() return p2_strict_known_global end return f()")
assert(known_global_function() == 42)
var known_global_method = compile("class P2StrictKnown def value() return p2_strict_known_global end end return P2StrictKnown().value()")
assert(known_global_method() == 42)
var known_global_condition = compile("if p2_strict_known_global return p2_strict_known_global end return 0")
assert(known_global_condition() == 42)
var known_global_loop_condition = compile("while p2_strict_known_global return p2_strict_known_global end return 0")
assert(known_global_loop_condition() == 42)
var known_global_cond_expr = compile("return p2_strict_known_global ? p2_strict_known_global : 0")
assert(known_global_cond_expr() == 42)

global.undef("p2_strict_known_global")
assert(!global.contains("p2_strict_known_global"))
expect_syntax_error("return p2_strict_known_global")
expect_syntax_error("def f() return p2_strict_known_global end return f()")
expect_syntax_error("class P2StrictKnown def value() return p2_strict_known_global end end return P2StrictKnown().value()")
expect_syntax_error("if p2_strict_known_global return 1 end return 0")
expect_syntax_error("while p2_strict_known_global return 1 end return 0")
expect_syntax_error("return p2_strict_known_global ? 1 : 0")

print("P2_SMOKE_PASS strict")
