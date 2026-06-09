print("P2_SMOKE_BEGIN import_layout")

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
ensure_dir("/berry/lib")
ensure_dir("/berry/app")
var made_lib_pkg = false
if !os.path.isdir("/berry/lib/p1_layout_pkg")
    ensure_dir("/berry/lib/p1_layout_pkg")
    made_lib_pkg = true
end

assert(!os.path.exists("/berry/lib/p1_layout_lib.be"))
assert(!os.path.exists("/berry/app/p1_layout_app.be"))
assert(!os.path.exists("/berry/lib/p1_layout_pkg/mod.be"))

var lf = open("/berry/lib/p1_layout_lib.be", "w")
lf.write("var p1_layout_lib = module('p1_layout_lib')\n")
lf.write("p1_layout_lib.answer = 42\n")
lf.write("return p1_layout_lib\n")
lf.close()

var af = open("/berry/app/p1_layout_app.be", "w")
af.write("var p1_layout_app = module('p1_layout_app')\n")
af.write("p1_layout_app.answer = 84\n")
af.write("return p1_layout_app\n")
af.close()

var pf = open("/berry/lib/p1_layout_pkg/mod.be", "w")
pf.write("var p1_layout_pkg_mod = module('p1_layout_pkg.mod')\n")
pf.write("p1_layout_pkg_mod.answer = 126\n")
pf.write("return p1_layout_pkg_mod\n")
pf.close()

assert(libstore.source_path("p1_layout_lib") == "/berry/lib/p1_layout_lib.be")
assert(libstore.source_path("p1_layout_app") == "/berry/app/p1_layout_app.be")
assert(libstore.source_path("p1_layout_pkg.mod") == "/berry/lib/p1_layout_pkg/mod.be")
var lib_info = libstore.info("p1_layout_lib")
assert(lib_info["exists"])
assert(lib_info["path"] == "/berry/lib/p1_layout_lib.be")
assert(lib_info["source_size"] > 0)
var app_info = libstore.info("p1_layout_app")
assert(app_info["exists"])
assert(app_info["path"] == "/berry/app/p1_layout_app.be")
assert(app_info["source_size"] > 0)
var pkg_info = libstore.info("p1_layout_pkg.mod")
assert(pkg_info["exists"])
assert(pkg_info["path"] == "/berry/lib/p1_layout_pkg/mod.be")
assert(pkg_info["source_size"] > 0)

import p1_layout_lib
assert(p1_layout_lib.answer == 42)

import p1_layout_app
assert(p1_layout_app.answer == 84)

import "p1_layout_pkg.mod" as p1_layout_pkg_alias
assert(p1_layout_pkg_alias.answer == 126)

try
    os.remove("/berry/lib/p1_layout_lib.be")
except .. as e, m
end
try
    os.remove("/berry/app/p1_layout_app.be")
except .. as e, m
end
try
    os.remove("/berry/lib/p1_layout_pkg/mod.be")
except .. as e, m
end
if made_lib_pkg
    assert(os.remove("/berry/lib/p1_layout_pkg"))
end

print("P2_SMOKE_PASS import_layout")
