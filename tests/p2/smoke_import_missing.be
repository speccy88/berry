print("P2_SMOKE_BEGIN import_missing")

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

var missing_name = "p2_no_such_import_module"
var staged_path = "/berry/app/p2_no_such_import_module.be"
var caught = false

ensure_dir("/berry")
ensure_dir("/berry/app")
assert(!os.path.exists(staged_path))

try
    import p2_no_such_import_module
except .. as e, m
    caught = true
    assert(type(e) == "string")
end
assert(caught)

var caught_again = false
try
    import p2_no_such_import_module
except .. as e, m
    caught_again = true
    assert(type(e) == "string")
end
assert(caught_again)

assert(!libstore.exists(missing_name))
assert(libstore.source_path(missing_name) == nil)
assert(libstore.compiled_path(missing_name) == nil)

var info = libstore.info(missing_name)
assert(info["exists"] == false)
assert(info["source_size"] == 0)
assert(info["source_hash"] == nil)
assert(info["compiled_exists"] == false)
assert(info["compiled_size"] == 0)
assert(info["compiled_hash"] == nil)
assert(info["compiled_fresh"] == false)
assert(info["compiled_usable"] == false)
assert(info["selected_path"] == nil)
assert(info["selected_kind"] == nil)
assert(info["resolve_reason"] == "missing")
assert(info["source_fallback"] == false)
assert(libstore.compiled_status(missing_name) == "missing")

var resolved = libstore.resolve(missing_name)
assert(resolved["source_exists"] == false)
assert(resolved["compiled_exists"] == false)
assert(resolved["selected_path"] == nil)
assert(resolved["selected_kind"] == nil)
assert(resolved["reason"] == "missing")

var f = open(staged_path, "w")
f.write("var p2_no_such_import_module = module('p2_no_such_import_module')\n")
f.write("p2_no_such_import_module.answer = 42\n")
f.write("return p2_no_such_import_module\n")
f.close()

import p2_no_such_import_module
assert(p2_no_such_import_module.answer == 42)
p2_no_such_import_module.answer = 43
import p2_no_such_import_module as recovered_missing_again
assert(recovered_missing_again.answer == 43)
assert(libstore.exists(missing_name))
var recovered_info = libstore.info(missing_name)
assert(recovered_info["selected_kind"] == "source")
assert(recovered_info["selected_path"] == staged_path)
assert(recovered_info["source_size"] > 0)

try
    os.remove(staged_path)
except .. as e, m
end

print("P2_SMOKE_PASS import_missing")
