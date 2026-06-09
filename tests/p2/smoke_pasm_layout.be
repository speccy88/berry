print("P2_SMOKE_BEGIN pasm_layout")

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

ensure_dir("/berry")
ensure_dir("/berry/pasm")

var path = "/berry/pasm/p1_pasm_probe.bin"
var nested_dir = "/berry/pasm/p1_pasm_pkg"
var made_nested_dir = false
if !os.path.isdir(nested_dir)
    ensure_dir(nested_dir)
    made_nested_dir = true
end
var nested_path = nested_dir + "/probe.bin"

assert(!os.path.exists(path))
assert(!os.path.exists(nested_path))

var f = open(path, "w")
f.write("dummy-pasm")
f.close()

var nf = open(nested_path, "w")
nf.write("nested-dummy-pasm")
nf.close()

assert(libstore.pasm_path("p1_pasm_probe") == path)
assert(libstore.pasm_exists("p1_pasm_probe"))
assert(libstore.pasm_path("p1_pasm_pkg.probe") == nested_path)
assert(libstore.pasm_exists("p1_pasm_pkg.probe"))

var info = libstore.pasm_info("p1_pasm_probe")
assert(info["exists"])
assert(info["path"] == path)
assert(info["executable"] == false)
assert(info["reason"] == "pasm_execution_deferred")

var nested_info = libstore.pasm_info("p1_pasm_pkg.probe")
assert(nested_info["exists"])
assert(nested_info["path"] == nested_path)
assert(nested_info["executable"] == false)
assert(nested_info["reason"] == "pasm_execution_deferred")

var missing = libstore.pasm_info("p1_no_such_pasm")
assert(!missing["exists"])
assert(missing["path"] == nil)
assert(missing["executable"] == false)
assert(missing["reason"] == "missing")
assert(libstore.pasm_path("p1_no_such_pasm") == nil)
assert(!libstore.pasm_exists("p1_no_such_pasm"))

try
    os.remove(path)
except .. as e, m
end
try
    os.remove(nested_path)
except .. as e, m
end
if made_nested_dir
    assert(os.remove(nested_dir))
end

print("P2_SMOKE_PASS pasm_layout")
