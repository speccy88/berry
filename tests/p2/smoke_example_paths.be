print("P2_SMOKE_BEGIN example_paths")

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
ensure_dir("/berry/examples")

var path = "/berry/examples/p1_example_probe.be"
var nested_dir = "/berry/examples/p1_example_pkg"
var made_nested_dir = false
if !os.path.isdir(nested_dir)
    ensure_dir(nested_dir)
    made_nested_dir = true
end
var nested_path = nested_dir + "/probe.be"

assert(!os.path.exists(path))
assert(!os.path.exists(nested_path))

var f = open(path, "w")
f.write("return 42\n")
f.close()

var nf = open(nested_path, "w")
nf.write("return 84\n")
nf.close()

assert(libstore.example_path("p1_example_probe") == path)
assert(libstore.example_exists("p1_example_probe"))
assert(libstore.run_example("p1_example_probe") == 42)
assert(libstore.example_path("p1_example_pkg.probe") == nested_path)
assert(libstore.example_exists("p1_example_pkg.probe"))
assert(libstore.run_example("p1_example_pkg.probe") == 84)
assert(libstore.example_path("p1_no_such_example") == nil)
assert(!libstore.example_exists("p1_no_such_example"))
assert(libstore.run_example("p1_no_such_example") == nil)

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

print("P2_SMOKE_PASS example_paths")
