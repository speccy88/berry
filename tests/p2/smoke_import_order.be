# P2_SD_WRITE_AUDIT max_write_opens=5
print("P2_SMOKE_BEGIN import_order")

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

ensure_dir("/modules")
ensure_dir("/berry")
ensure_dir("/berry/lib")
ensure_dir("/berry/app")
print("P2_SMOKE_STAGE import_order dirs")

var name = "iordmod"
var lib_app_name = "iordla"
var modules_path = "/modules/iordmod.be"
var lib_path = "/berry/lib/iordmod.be"
var app_path = "/berry/app/iordmod.be"
var lib_app_path = "/berry/lib/iordla.be"
var app_only_path = "/berry/app/iordla.be"

print("P2_SMOKE_STAGE import_order preflight")
assert(!os.path.exists(modules_path))
assert(!os.path.exists(lib_path))
assert(!os.path.exists(app_path))
assert(!os.path.exists(lib_app_path))
assert(!os.path.exists(app_only_path))

print("P2_SMOKE_STAGE import_order write")
var mf = open(modules_path, "w")
mf.write("var iordmod = module('iordmod')\n")
mf.write("iordmod.origin = 'modules'\n")
mf.write("return iordmod\n")
mf.close()

var lf = open(lib_path, "w")
lf.write("var iordmod = module('iordmod')\n")
lf.write("iordmod.origin = 'berry-lib'\n")
lf.write("return iordmod\n")
lf.close()

var af = open(app_path, "w")
af.write("var iordmod = module('iordmod')\n")
af.write("iordmod.origin = 'berry-app'\n")
af.write("return iordmod\n")
af.close()

var laf = open(lib_app_path, "w")
laf.write("var iordla = module('iordla')\n")
laf.write("iordla.origin = 'berry-lib'\n")
laf.write("return iordla\n")
laf.close()

var aof = open(app_only_path, "w")
aof.write("var iordla = module('iordla')\n")
aof.write("iordla.origin = 'berry-app'\n")
aof.write("return iordla\n")
aof.close()

print("P2_SMOKE_STAGE import_order modules")
import iordmod
assert(iordmod.origin == "modules")
assert(wait_source_path(name, modules_path))
var modules_info = wait_info(name, modules_path)
assert(modules_info["exists"])
assert(modules_info["path"] == modules_path)
assert(modules_info["source_size"] > 0)
iordmod.origin = "modules-cached"
import iordmod as iordmod_again
assert(iordmod_again.origin == "modules-cached")

print("P2_SMOKE_STAGE import_order lib_app")
import iordla
assert(iordla.origin == "berry-lib")
assert(wait_source_path(lib_app_name, lib_app_path))
var lib_app_info = wait_info(lib_app_name, lib_app_path)
assert(lib_app_info["exists"])
assert(lib_app_info["path"] == lib_app_path)
assert(lib_app_info["source_size"] > 0)
iordla.origin = "berry-lib-cached"
import iordla as iordla_again
assert(iordla_again.origin == "berry-lib-cached")

print("P2_SMOKE_STAGE import_order cleanup")
try
    os.remove(modules_path)
except .. as e, m
end
try
    os.remove(lib_path)
except .. as e, m
end
try
    os.remove(app_path)
except .. as e, m
end
try
    os.remove(lib_app_path)
except .. as e, m
end
try
    os.remove(app_only_path)
except .. as e, m
end

print("P2_SMOKE_PASS import_order")
