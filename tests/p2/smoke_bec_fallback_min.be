# P2_SD_WRITE_AUDIT max_write_opens=2
print("P2_SMOKE_BEGIN bec_fallback_min")

import os
import libstore

def check(cond, label)
    if !cond
        print("P2_SMOKE_FAIL bec_fallback_min", label)
    end
    assert(cond)
end

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
ensure_dir("/berry/cache")

var name = "bec_min"
var source_path = "/berry/lib/bec_min.be"
var compiled_path = "/berry/cache/bec_min.bec"

check(!os.path.exists(source_path), "preflight_source_absent")
check(!os.path.exists(compiled_path), "preflight_compiled_absent")
assert(!os.path.exists(source_path))
assert(!os.path.exists(compiled_path))

var sf = open(source_path, "w")
sf.write("var bec_min = module('bec_min')\n")
sf.write("bec_min.answer = 77\n")
sf.write("return bec_min\n")
sf.close()

var compiled_text = "dummy unsupported bytecode"
var cf = open(compiled_path, "w")
cf.write(compiled_text)
cf.close()

check(libstore.source_path(name) == source_path, "source_path")
check(libstore.compiled_path(name) == compiled_path, "compiled_path")
check(libstore.compiled_exists(name), "compiled_exists")

var info = libstore.info(name)
check(info["exists"], "info_exists")
check(info["compiled_exists"], "info_compiled_exists")
check(info["compiled_size"] == size(compiled_text), "info_compiled_size")
check(info["compiled_hash"] == libstore.hash_text(compiled_text), "info_compiled_hash")
check(type(info["compiled_supported"]) == "bool", "info_compiled_supported_bool")
check(info["compiled_usable"] == false, "info_compiled_usable")
check(info["source_fallback"], "info_source_fallback")
check(info["selected_path"] == source_path, "info_selected_path")
check(info["selected_kind"] == "source", "info_selected_kind")
check(info["resolve_reason"] == "compiled_unsupported_source_fallback", "info_resolve_reason")

var resolved = libstore.resolve(name)
check(resolved["selected_path"] == source_path, "resolve_selected_path")
check(resolved["selected_kind"] == "source", "resolve_selected_kind")
check(resolved["compiled_exists"], "resolve_compiled_exists")
check(resolved["compiled_preferred"] == false, "resolve_compiled_preferred")
check(type(resolved["compiled_blocked_reason"]) == "string", "resolve_blocked_reason")
check(resolved["source_fallback"], "resolve_source_fallback")

try
    os.remove(source_path)
except .. as e, m
end
try
    os.remove(compiled_path)
except .. as e, m
end

check(!os.path.exists(source_path), "cleanup_source_absent")
check(!os.path.exists(compiled_path), "cleanup_compiled_absent")

print("P2_SMOKE_PASS bec_fallback_min")
