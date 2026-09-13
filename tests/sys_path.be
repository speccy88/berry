# sys.path() is the live, VM-owned search list, not an untracked copy.
import sys
import gc
var paths = sys.path()
var original_size = paths.size()
paths.push('modules')
assert(sys.path().size() == original_size + 1)
assert(sys.path()[original_size] == 'modules')

gc.collect()
assert(sys.path()[original_size] == 'modules')

# Non-string entries are ignored by module lookup, not dereferenced as strings.
paths.push(nil)
paths.push(123)
import binary_heap
assert(type(binary_heap) == 'module')
assert(type(binary_heap.sort) == 'function')
paths.pop()
paths.pop()
paths.pop()
assert(sys.path().size() == original_size)

# Keep the explicit append convenience API and its input validation.
assert(sys.path_add('modules'))
assert(paths.size() == original_size + 1)
paths.pop()
for value : [nil, 0, [], {}]
    try
        sys.path_add(value)
        assert(false, 'accepted a non-string module path')
    except 'type_error'
    end
end
try
    sys.path_add('')
    assert(false, 'accepted an empty module path')
except 'value_error'
end
