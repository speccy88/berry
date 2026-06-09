print("P2_SMOKE_BEGIN module_system")

import introspect
import string
import sys

def has_string(items)
    for item: items
        if type(item) == "string"
            return true
        end
    end
    return false
end

var named = module("p2_module_system_named")
var unnamed = module()
assert(type(named) == "module")
assert(type(unnamed) == "module")
assert(str(named) == "<module: p2_module_system_named>")
assert(introspect.name(named) == "p2_module_system_named")
assert(introspect.name(unnamed) == nil)

var same_name = module("p2_module_system_named")
assert(type(same_name) == "module")
assert(introspect.name(same_name) == "p2_module_system_named")
assert(introspect.toptr(same_name) != introspect.toptr(named))
same_name.value = 7
assert(same_name.value == 7)

named.value = 41
assert(named.value == 41)
named.value += 1
assert(named.value == 42)
assert(same_name.value == 7)
named.fn = def (x)
    return named.value + x
end
assert(named.fn(0) == 42)

var module_path = sys.path()
assert(isinstance(module_path, list))
assert(module_path.size() >= 1)
assert(has_string(module_path))

var injected = module("p2_module_system_injected")
injected.answer = 42
injected.scale = def (x)
    return x * 2
end
introspect.setmodule("p2_module_system_injected", injected)
import p2_module_system_injected
assert(type(p2_module_system_injected) == "module")
assert(introspect.toptr(p2_module_system_injected) == introspect.toptr(injected))
assert(p2_module_system_injected.answer == 42)
assert(p2_module_system_injected.scale(21) == 42)
p2_module_system_injected.answer += 1
import p2_module_system_injected as injected_again
assert(introspect.toptr(injected_again) == introspect.toptr(injected))
assert(injected.answer == 43)
assert(injected_again.answer == 43)

var injected_replacement = module("p2_module_system_injected")
injected_replacement.answer = 99
introspect.setmodule("p2_module_system_injected", injected_replacement)
import p2_module_system_injected as injected_replaced
assert(introspect.toptr(injected_replaced) == introspect.toptr(injected_replacement))
assert(injected_replaced.answer == 99)
assert(injected.answer == 43)

var string_original = string
var string_replacement = module("string")
string_replacement.super = def ()
    return string_original
end
string_replacement.member = def (name)
    return introspect.get(string_original, name, true)
end
string_replacement.codex_probe = def ()
    return "patched"
end

introspect.setmodule("string", string_replacement)
import string as patched_string
assert(type(patched_string) == "module")
assert(introspect.toptr(patched_string) == introspect.toptr(string_replacement))
assert(patched_string.codex_probe() == "patched")
assert(patched_string.tolower("AbC") == "abc")
assert(introspect.toptr(patched_string.super()) == introspect.toptr(string_original))

introspect.setmodule("string", string_original)
import string as restored_string
assert(type(restored_string) == "module")
assert(introspect.toptr(restored_string) == introspect.toptr(string_original))
assert(restored_string.toupper("ab") == "AB")
assert(!introspect.contains(restored_string, "codex_probe"))

print("P2_SMOKE_PASS module_system")
