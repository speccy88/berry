print("P2_SMOKE_BEGIN import_native_first")

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
ensure_dir("/berry/lib")
ensure_dir("/berry/app")

var shadows = [
    "/berry/lib/json.be",
    "/berry/app/json.be"
]
var created = []

for shadow : shadows
    assert(!os.path.exists(shadow))
    var f = open(shadow, "w")
    f.write("var json = module('json')\n")
    f.write("json.shadowed = true\n")
    f.write("json.shadow_path = '" + shadow + "'\n")
    f.write("return json\n")
    f.close()
    created.push(shadow)
end

import json
var decoded = json.load('{"native":true}')
assert(decoded["native"])
assert(!json.contains("shadowed"))
var json_ptr = introspect.toptr(json)

import json as json_again
var decoded_again = json_again.load('{"native_again":true}')
assert(decoded_again["native_again"])
assert(!json_again.contains("shadowed"))
assert(introspect.toptr(json_again) == json_ptr)

for shadow : created
    assert(os.remove(shadow))
end

print("P2_SMOKE_PASS import_native_first")
