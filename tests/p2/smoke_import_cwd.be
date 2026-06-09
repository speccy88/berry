print("P2_SMOKE_BEGIN import_cwd")

import os
import introspect

def ensure_dir(path)
    if !os.path.isdir(path)
        try
            os.mkdir(path)
        except .. as e, m
        end
    end
end

ensure_dir("/berry")
ensure_dir("/berry/app")

var made_p1cwd = false
if !os.path.isdir("/berry/app/p1cwd")
    ensure_dir("/berry/app/p1cwd")
    made_p1cwd = true
end

var cwd = os.getcwd()
var path = "/berry/app/p1cwd/p1_cwd_module.be"
var root_path = "/berry/app/p1_cwd_module.be"

assert(!os.path.exists(path))
assert(!os.path.exists(root_path))

var f = open(path, "w")
f.write("var p1_cwd_module = module('p1_cwd_module')\n")
f.write("p1_cwd_module.answer = 123\n")
f.write("p1_cwd_module.origin = 'cwd'\n")
f.write("return p1_cwd_module\n")
f.close()

var rf = open(root_path, "w")
rf.write("var p1_cwd_module = module('p1_cwd_module')\n")
rf.write("p1_cwd_module.answer = 456\n")
rf.write("p1_cwd_module.origin = 'berry-app'\n")
rf.write("return p1_cwd_module\n")
rf.close()

assert(os.chdir("/berry/app/p1cwd"))
assert(os.getcwd() == "/berry/app/p1cwd")

import p1_cwd_module
assert(p1_cwd_module.answer == 123)
assert(p1_cwd_module.origin == "cwd")
var p1_cwd_module_ptr = introspect.toptr(p1_cwd_module)
p1_cwd_module.answer = 124

assert(os.chdir(cwd))
import p1_cwd_module as p1_cwd_module_again
assert(p1_cwd_module_again.answer == 124)
assert(p1_cwd_module_again.origin == "cwd")
assert(introspect.toptr(p1_cwd_module_again) == p1_cwd_module_ptr)
assert(os.remove(path))
assert(os.remove(root_path))
if made_p1cwd
    assert(os.remove("/berry/app/p1cwd"))
end

print("P2_SMOKE_PASS import_cwd")
