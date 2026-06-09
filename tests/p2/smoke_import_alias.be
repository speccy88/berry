print("P2_SMOKE_BEGIN import_alias")

import os
import string as s
assert(s.toupper("berry") == "BERRY")
assert(s.find("banana", "na") == 2)

import json as j
assert(j.load('{"ok":true}')["ok"])

import math as m
assert(m.sqrt(49) == 7)
assert(m.min(9, 4, 7) == 4)

import libstore as ls
assert(ls.exists("math"))
assert(ls.source_path("math") != nil)

import p2compat as compat
assert(compat.status("environment") == compat.UNSUPPORTED)

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

var alias_path = "/berry/app/p2_alias_cache.be"
assert(!os.path.exists(alias_path))

var f = open(alias_path, "w")
f.write("var p2_alias_cache = module('p2_alias_cache')\n")
f.write("p2_alias_cache.answer = 42\n")
f.write("return p2_alias_cache\n")
f.close()

import p2_alias_cache as alias_one
assert(alias_one.answer == 42)
assert(ls.source_path("p2_alias_cache") == alias_path)
var alias_info = ls.info("p2_alias_cache")
assert(alias_info["exists"])
assert(alias_info["selected_path"] == alias_path)
assert(alias_info["source_size"] > 0)
alias_one.answer = 43
import p2_alias_cache as alias_two
assert(alias_two.answer == 43)

try
    assert(os.remove(alias_path))
except .. as e, m
end

print("P2_SMOKE_PASS import_alias")
