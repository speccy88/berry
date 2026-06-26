# P2_SD_WRITE_AUDIT max_write_opens=2
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
print("P2_SMOKE_STAGE import_cwd dirs")

var made_cwd_probe = false
if !os.path.isdir("/berry/app/cwd_probe")
    ensure_dir("/berry/app/cwd_probe")
    made_cwd_probe = true
end

var cwd = os.getcwd()
var path = "/berry/app/cwd_probe/cwd_probe_module.be"
var root_path = "/berry/app/cwd_probe_module.be"

print("P2_SMOKE_STAGE import_cwd preflight")
assert(!os.path.exists(path))
assert(!os.path.exists(root_path))

print("P2_SMOKE_STAGE import_cwd write")
var f = open(path, "w")
f.write("var cwd_probe_module = module('cwd_probe_module')\n")
f.write("cwd_probe_module.answer = 123\n")
f.write("cwd_probe_module.origin = 'cwd'\n")
f.write("return cwd_probe_module\n")
f.close()

var rf = open(root_path, "w")
rf.write("var cwd_probe_module = module('cwd_probe_module')\n")
rf.write("cwd_probe_module.answer = 456\n")
rf.write("cwd_probe_module.origin = 'berry-app'\n")
rf.write("return cwd_probe_module\n")
rf.close()

print("P2_SMOKE_STAGE import_cwd chdir")
assert(os.chdir("/berry/app/cwd_probe"))
assert(os.getcwd() == "/berry/app/cwd_probe")

print("P2_SMOKE_STAGE import_cwd import")
import cwd_probe_module
assert(cwd_probe_module.answer == 123)
assert(cwd_probe_module.origin == "cwd")
var cwd_probe_module_ptr = introspect.toptr(cwd_probe_module)
cwd_probe_module.answer = 124

assert(os.chdir(cwd))
import cwd_probe_module as cwd_probe_module_again
assert(cwd_probe_module_again.answer == 124)
assert(cwd_probe_module_again.origin == "cwd")
assert(introspect.toptr(cwd_probe_module_again) == cwd_probe_module_ptr)
print("P2_SMOKE_STAGE import_cwd cleanup")
assert(os.remove(path))
assert(os.remove(root_path))
if made_cwd_probe
    assert(os.remove("/berry/app/cwd_probe"))
end

print("P2_SMOKE_PASS import_cwd")
