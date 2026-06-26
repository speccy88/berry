# Test global module and variable access

def assert_syntax_error(code)
    try
        var f = compile(code)
        assert(false, 'unexpected execution flow')
    except .. as e, m
        assert(e == 'syntax_error')
    end
end

# Set up global variables
global_a = 1
global_b = "bb"
assert(global_a == 1)
assert(global_b == "bb")

assert_syntax_error("c") # Compilation fails because c doesn't exist

import global

if type(global) != "module"
    print("skip global.be: import global did not bind the native module")
    return
end

assert(global.global_a == 1)
assert(global.global_b == "bb")

global.global_c = 3
# Now compilation against 'c' global works
f = compile("return global_c")
assert(f() == 3)

# Check that access to non-existent global returns nil
assert(global.d == nil)

# Check the global snapshot map
assert(isinstance(global(), map))
assert(global().find('global_a') == 1)
assert(global().find('global_b') == "bb")
assert(global().find('global_c') == 3)
assert(global().find('global_d') == nil)

# undef
var a_global_var = 1
assert(global.contains("a_global_var") == true)
assert(global().find("a_global_var") == 1)

global.undef("a_global_var")
assert(global.contains("a_global_var") == false)
assert(global().find("a_global_var") == nil)

global.a_global_var = 1
assert(global.contains("a_global_var") == true)
global.undef("a_global_var")
