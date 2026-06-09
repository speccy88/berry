print("P2_SMOKE_BEGIN sys_path_add")

import os
import sys
import libstore

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

def has_path(items, path)
    for item : items
        if item == path
            return true
        end
    end
    return false
end

def count_path(items, path)
    var count = 0
    for item : items
        if item == path
            count += 1
        end
    end
    return count
end

var root = "/berry/sys_path"
var name = "p1_sys_path_probe"
var file = root + "/" + name + ".be"

ensure_dir("/berry")
ensure_dir(root)
assert(!os.path.exists(file))

var f = open(file, "w")
f.write("var p1_sys_path_probe = module('p1_sys_path_probe')\n")
f.write("p1_sys_path_probe.answer = 42\n")
f.write("return p1_sys_path_probe\n")
f.close()

var before_count = count_path(sys.path(), root)
var added = libstore.path_add(root)
var after_count = count_path(sys.path(), root)
assert((added && after_count == before_count + 1) || (!added && after_count == before_count))

var added_again = libstore.path_add(root)
var final_count = count_path(sys.path(), root)
assert(!added_again)
assert(final_count == after_count)
assert(has_path(sys.path(), root))
assert(libstore.source_path(name) == file)
var info = libstore.info(name)
assert(info["exists"])
assert(info["path"] == file)
assert(info["source_size"] > 0)

import p1_sys_path_probe
assert(p1_sys_path_probe.answer == 42)

try
    os.remove(file)
except .. as e, m
end

print("P2_SMOKE_PASS sys_path_add")
