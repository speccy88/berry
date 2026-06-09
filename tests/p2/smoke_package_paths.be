print("P2_SMOKE_BEGIN package_paths")

import os
import introspect
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
ensure_dir("/berry/app")

var made_pkg = false
if !os.path.isdir("/berry/app/pkg")
    ensure_dir("/berry/app/pkg")
    made_pkg = true
end

var path = "/berry/app/pkg/mod.be"
var other_path = "/berry/app/pkg/other.be"
assert(!os.path.exists(path))
assert(!os.path.exists(other_path))

var f = open(path, "w")
f.write("var pkg_mod = module('pkg.mod')\n")
f.write("pkg_mod.answer = 42\n")
f.write("return pkg_mod\n")
f.close()

var of = open(other_path, "w")
of.write("var pkg_other = module('pkg.other')\n")
of.write("pkg_other.answer = 84\n")
of.write("return pkg_other\n")
of.close()

assert(libstore.module_file("pkg.mod", ".be") == "pkg/mod.be")
assert(libstore.module_file("pkg.other", ".be") == "pkg/other.be")
assert(libstore.source_path("pkg.mod") == path)
assert(libstore.source_path("pkg.other") == other_path)
var info = libstore.info("pkg.mod")
assert(info["exists"])
assert(info["path"] == path)
assert(info["source_size"] > 0)
var other_info = libstore.info("pkg.other")
assert(other_info["exists"])
assert(other_info["path"] == other_path)
assert(other_info["source_size"] > 0)

var loaded = libstore.load("pkg.mod")
assert(loaded.answer == 42)

import "pkg.mod" as native_pkg_mod
assert(native_pkg_mod.answer == 42)
var native_pkg_mod_ptr = introspect.toptr(native_pkg_mod)

import "pkg.mod" as native_pkg_mod_again
assert(native_pkg_mod_again.answer == 42)
assert(introspect.toptr(native_pkg_mod_again) == native_pkg_mod_ptr)

import pkg.mod as dotted_pkg_mod
assert(dotted_pkg_mod.answer == 42)
assert(introspect.toptr(dotted_pkg_mod) == native_pkg_mod_ptr)

import pkg.mod
assert(mod.answer == 42)
assert(introspect.toptr(mod) == native_pkg_mod_ptr)

import pkg.mod, pkg.other
assert(mod.answer == 42)
assert(other.answer == 84)
assert(introspect.toptr(mod) == native_pkg_mod_ptr)

try
    os.remove(path)
except .. as e, m
end
try
    os.remove(other_path)
except .. as e, m
end
if made_pkg
    try
        os.remove("/berry/app/pkg")
    except .. as e, m
    end
end

print("P2_SMOKE_PASS package_paths")
