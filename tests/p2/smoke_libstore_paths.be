# P2_SD_WRITE_AUDIT max_write_opens=1
print("P2_SMOKE_BEGIN libstore_paths")

import os
import libstore
import p2

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

def wait_source_path(name, path)
    var tries = 0
    while tries < 8
        if libstore.source_path(name) == path
            return true
        end
        p2.clock.waitms(10)
        tries += 1
    end
    return false
end

def wait_info(name, path)
    var tries = 0
    while tries < 8
        var info = libstore.info(name)
        if info["exists"] && info["path"] == path && info["source_size"] > 0
            return info
        end
        p2.clock.waitms(10)
        tries += 1
    end
    return libstore.info(name)
end

var path = "/berry/app/p2paths"
var name = "lpathp"
var file = path + "/" + name + ".be"
var made_path = false

ensure_dir("/berry")
ensure_dir("/berry/app")
print("P2_SMOKE_STAGE libstore_paths dirs")
if !os.path.isdir(path)
    ensure_dir(path)
    made_path = true
end
print("P2_SMOKE_STAGE libstore_paths preflight")
assert(!os.path.exists(file))

var before = libstore.path_list()
assert(before[0] == "/modules")
before.push("__libstore_path_list_mutation_probe__")
assert(libstore.path_list().find("__libstore_path_list_mutation_probe__") == nil)

assert(!libstore.path_remove(path))
assert(libstore.source_path(name) == nil)

print("P2_SMOKE_STAGE libstore_paths write")
var f = open(file, "w")
f.write("var lpathp = module('lpathp')\n")
f.write("lpathp.answer = 42\n")
f.write("return lpathp\n")
f.close()

print("P2_SMOKE_STAGE libstore_paths add")
assert(libstore.path_add(path))
assert(!libstore.path_add(path))
assert(wait_source_path(name, file))
var info = wait_info(name, file)
assert(info["exists"])
assert(info["path"] == file)
assert(info["source_size"] > 0)

print("P2_SMOKE_STAGE libstore_paths load")
var loaded = libstore.load(name)
assert(loaded.answer == 42)

print("P2_SMOKE_STAGE libstore_paths remove")
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
