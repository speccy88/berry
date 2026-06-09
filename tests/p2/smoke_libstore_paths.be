print("P2_SMOKE_BEGIN libstore_paths")

import os
import libstore

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

var path = "/berry/app/p1paths"
var name = "p1_path_probe"
var file = path + "/" + name + ".be"
var made_path = false

ensure_dir("/berry")
ensure_dir("/berry/app")
if !os.path.isdir(path)
    ensure_dir(path)
    made_path = true
end
assert(!os.path.exists(file))

var before = libstore.path_list()
assert(before[0] == "/modules")
before.push("__libstore_path_list_mutation_probe__")
assert(libstore.path_list().find("__libstore_path_list_mutation_probe__") == nil)

assert(!libstore.path_remove(path))
assert(libstore.source_path(name) == nil)

var f = open(file, "w")
f.write("var p1_path_probe = module('p1_path_probe')\n")
f.write("p1_path_probe.answer = 42\n")
f.write("return p1_path_probe\n")
f.close()

assert(libstore.path_add(path))
assert(!libstore.path_add(path))
assert(libstore.source_path(name) == file)
var info = libstore.info(name)
assert(info["exists"])
assert(info["path"] == file)
assert(info["source_size"] > 0)

var loaded = libstore.load(name)
assert(loaded.answer == 42)

assert(libstore.path_remove(path))
assert(!libstore.path_remove(path))
assert(libstore.source_path(name) == nil)

try
    os.remove(file)
except .. as e, m
end
if made_path
    assert(os.remove(path))
end

print("P2_SMOKE_PASS libstore_paths")
