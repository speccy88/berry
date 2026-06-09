print("P2_SMOKE_BEGIN sys")

import os
import sys
import introspect

assert(type(sys) == "module")
assert(type(sys.path) == "function")

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

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

def has_path(items, path)
    for item : items
        if item == path
            return true
        end
    end
    return false
end

var paths = sys.path()
assert(type(paths) == "list")
assert(size(paths) > 0)
assert(introspect.toptr(paths) != introspect.toptr(sys.path()))
for item : paths
    assert(type(item) == "string")
    assert(size(item) > 0)
end

var sentinel = "/p2/sys/path/list-copy-sentinel"
assert(!has_path(sys.path(), sentinel))
paths.push(sentinel)
assert(has_path(paths, sentinel))
assert(!has_path(sys.path(), sentinel))

var mutate_paths = sys.path()
var first_path = mutate_paths[0]
mutate_paths[0] = sentinel
assert(mutate_paths[0] == sentinel)
assert(sys.path()[0] == first_path)

assert(type(sys.path_add) == "function")
expect_error(def () sys.path_add() end, "type_error")
expect_error(def () sys.path_add(nil) end, "type_error")
expect_error(def () sys.path_add(42) end, "type_error")
expect_error(def () sys.path_add([]) end, "type_error")
expect_error(def () sys.path_add("") end, "value_error")

var root = "/berry/sys_direct"
var name = "p1_sys_direct_probe"
var file = root + "/" + name + ".be"

ensure_dir("/berry")
ensure_dir(root)
assert(!os.path.exists(file))

var f = open(file, "w")
f.write("var p1_sys_direct_probe = module('p1_sys_direct_probe')\n")
f.write("p1_sys_direct_probe.answer = 42\n")
f.write("return p1_sys_direct_probe\n")
f.close()

var before_direct_paths = sys.path()
var before_direct_has_root = has_path(before_direct_paths, root)
var direct_added = sys.path_add(root)
assert(direct_added)
assert(has_path(sys.path(), root))
if !before_direct_has_root
    assert(!has_path(before_direct_paths, root))
end

import p1_sys_direct_probe
assert(p1_sys_direct_probe.answer == 42)

try
    os.remove(file)
except .. as e, m
end

print("P2_SMOKE_PASS sys")
