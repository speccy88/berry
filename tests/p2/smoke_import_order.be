print("P2_SMOKE_BEGIN import_order")

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

ensure_dir("/modules")
ensure_dir("/berry")
ensure_dir("/berry/lib")
ensure_dir("/berry/app")

var name = "p1_import_order"
var modules_path = "/modules/p1_import_order.be"
var lib_path = "/berry/lib/p1_import_order.be"
var app_path = "/berry/app/p1_import_order.be"
var lib_app_path = "/berry/lib/p1_import_order_lib_app.be"
var app_only_path = "/berry/app/p1_import_order_lib_app.be"

assert(!os.path.exists(modules_path))
assert(!os.path.exists(lib_path))
assert(!os.path.exists(app_path))
assert(!os.path.exists(lib_app_path))
assert(!os.path.exists(app_only_path))

var mf = open(modules_path, "w")
mf.write("var p1_import_order = module('p1_import_order')\n")
mf.write("p1_import_order.origin = 'modules'\n")
mf.write("return p1_import_order\n")
mf.close()

var lf = open(lib_path, "w")
lf.write("var p1_import_order = module('p1_import_order')\n")
lf.write("p1_import_order.origin = 'berry-lib'\n")
lf.write("return p1_import_order\n")
lf.close()

var af = open(app_path, "w")
af.write("var p1_import_order = module('p1_import_order')\n")
af.write("p1_import_order.origin = 'berry-app'\n")
af.write("return p1_import_order\n")
af.close()

var laf = open(lib_app_path, "w")
laf.write("var p1_import_order_lib_app = module('p1_import_order_lib_app')\n")
laf.write("p1_import_order_lib_app.origin = 'berry-lib'\n")
laf.write("return p1_import_order_lib_app\n")
laf.close()

var aof = open(app_only_path, "w")
aof.write("var p1_import_order_lib_app = module('p1_import_order_lib_app')\n")
aof.write("p1_import_order_lib_app.origin = 'berry-app'\n")
aof.write("return p1_import_order_lib_app\n")
aof.close()

import p1_import_order
assert(p1_import_order.origin == "modules")
assert(libstore.source_path("p1_import_order") == modules_path)
var modules_info = libstore.info("p1_import_order")
assert(modules_info["exists"])
assert(modules_info["path"] == modules_path)
assert(modules_info["source_size"] > 0)
p1_import_order.origin = "modules-cached"
import p1_import_order as p1_import_order_again
assert(p1_import_order_again.origin == "modules-cached")

import p1_import_order_lib_app
assert(p1_import_order_lib_app.origin == "berry-lib")
assert(libstore.source_path("p1_import_order_lib_app") == lib_app_path)
var lib_app_info = libstore.info("p1_import_order_lib_app")
assert(lib_app_info["exists"])
assert(lib_app_info["path"] == lib_app_path)
assert(lib_app_info["source_size"] > 0)
p1_import_order_lib_app.origin = "berry-lib-cached"
import p1_import_order_lib_app as p1_import_order_lib_app_again
assert(p1_import_order_lib_app_again.origin == "berry-lib-cached")

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
