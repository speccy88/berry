# Module imports use the VM's cache, not an old same-named global binding.
import string
import introspect
var original = string
introspect.setmodule('string', 42)
assert(introspect.module('string') == 42)
import string as replacement
assert(replacement == 42)
import string
assert(string == 42)

introspect.setmodule('string', original)
import string
assert(type(string) == 'module')
assert(string.toupper('restored') == 'RESTORED')

var expected = module('cache_identity')
expected.value = 7
introspect.setmodule('cache_identity', expected)
var cache_identity = module('unrelated_global')
import cache_identity
assert(cache_identity.value == 7)
cache_identity.value = 19
assert(expected.value == 19)
