print("P2_SMOKE_BEGIN module_attrs")

import introspect
import undefined

def expect_attribute_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "attribute_error")
    end
end

var dyn = module("p2_dyn_module")
dyn.lookup_count = 0
dyn.member = def (name)
    dyn.lookup_count += 1
    return "val_" + name
end

assert(dyn.foo == "val_foo")
assert(dyn.lookup_count == 1)
assert(dyn.bar == "val_bar")
assert(dyn.lookup_count == 2)
dyn.foo = "real_foo"
assert(dyn.foo == "real_foo")
assert(dyn.lookup_count == 2)
assert(dyn.baz == "val_baz")
assert(dyn.lookup_count == 3)
dyn.baz = "real_baz"
assert(dyn.baz == "real_baz")
assert(dyn.lookup_count == 3)

var callable_dyn = module("p2_callable_dyn_module")
callable_dyn.member = def (name)
    if name == "answer"
        return def (x)
            return x + 1
        end
    end
    return undefined
end
assert(callable_dyn.answer(41) == 42)
expect_attribute_error(def () return callable_dyn.missing end)

var undef_member = module("p2_undef_member")
undef_member.member = def (name)
    return undefined
end

expect_attribute_error(def () return undef_member.nonexistent end)

var noattr = module("p2_noattr")
noattr.foo = 1
assert(noattr.foo == 1)
expect_attribute_error(def () return noattr.bar end)

var string_mod = introspect.module("string")
assert(type(string_mod) == "module")
assert(introspect.name(string_mod) == "string")
assert(type(string_mod.toupper) == "function")

print("P2_SMOKE_PASS module_attrs")
