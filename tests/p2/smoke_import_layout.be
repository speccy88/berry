# P2_SD_WRITE_AUDIT max_write_opens=3
print("P2_SMOKE_BEGIN import_layout")

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

ensure_dir("/berry")
ensure_dir("/berry/lib")
ensure_dir("/berry/app")
print("P2_SMOKE_STAGE import_layout dirs")
var made_lib_pkg = false
if !os.path.isdir("/berry/lib/layout_probe_pkg")
    ensure_dir("/berry/lib/layout_probe_pkg")
    made_lib_pkg = true
end

print("P2_SMOKE_STAGE import_layout preflight")
assert(!os.path.exists("/berry/lib/layout_lib_probe.be"))
assert(!os.path.exists("/berry/app/layout_app_probe.be"))
assert(!os.path.exists("/berry/lib/layout_probe_pkg/mod.be"))

print("P2_SMOKE_STAGE import_layout write")
var lf = open("/berry/lib/layout_lib_probe.be", "w")
lf.write("var layout_lib_probe = module('layout_lib_probe')\n")
lf.write("layout_lib_probe.answer = 42\n")
lf.write("return layout_lib_probe\n")
lf.close()

var af = open("/berry/app/layout_app_probe.be", "w")
af.write("var layout_app_probe = module('layout_app_probe')\n")
af.write("layout_app_probe.answer = 84\n")
af.write("return layout_app_probe\n")
af.close()

var pf = open("/berry/lib/layout_probe_pkg/mod.be", "w")
pf.write("var layout_probe_pkg_mod = module('layout_probe_pkg.mod')\n")
pf.write("layout_probe_pkg_mod.answer = 126\n")
pf.write("return layout_probe_pkg_mod\n")
pf.close()

print("P2_SMOKE_STAGE import_layout metadata")
assert(wait_source_path("layout_lib_probe", "/berry/lib/layout_lib_probe.be"))
assert(wait_source_path("layout_app_probe", "/berry/app/layout_app_probe.be"))
assert(wait_source_path("layout_probe_pkg.mod", "/berry/lib/layout_probe_pkg/mod.be"))
var lib_info = wait_info("layout_lib_probe", "/berry/lib/layout_lib_probe.be")
assert(lib_info["exists"])
assert(lib_info["path"] == "/berry/lib/layout_lib_probe.be")
assert(lib_info["source_size"] > 0)
var app_info = wait_info("layout_app_probe", "/berry/app/layout_app_probe.be")
assert(app_info["exists"])
assert(app_info["path"] == "/berry/app/layout_app_probe.be")
assert(app_info["source_size"] > 0)
var pkg_info = wait_info("layout_probe_pkg.mod", "/berry/lib/layout_probe_pkg/mod.be")
assert(pkg_info["exists"])
assert(pkg_info["path"] == "/berry/lib/layout_probe_pkg/mod.be")
assert(pkg_info["source_size"] > 0)

print("P2_SMOKE_STAGE import_layout import")
import layout_lib_probe
assert(layout_lib_probe.answer == 42)

import layout_app_probe
assert(layout_app_probe.answer == 84)

import "layout_probe_pkg.mod" as layout_probe_pkg_alias
assert(layout_probe_pkg_alias.answer == 126)

print("P2_SMOKE_STAGE import_layout cleanup")
try
    os.remove("/berry/lib/layout_lib_probe.be")
except .. as e, m
end
try
    os.remove("/berry/app/layout_app_probe.be")
except .. as e, m
end
try
    os.remove("/berry/lib/layout_probe_pkg/mod.be")
except .. as e, m
end
if made_lib_pkg
    assert(os.remove("/berry/lib/layout_probe_pkg"))
end

print("P2_SMOKE_PASS import_layout")
