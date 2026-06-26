# P2_SD_WRITE_AUDIT max_write_opens=1
print("P2_SMOKE_BEGIN configstore")

import configstore

var name = "p2cfg"
print("P2_SMOKE_STAGE configstore preflight")
assert(!configstore.exists(name))

print("P2_SMOKE_STAGE configstore paths")
assert(configstore.ensure() == "/berry/config")
assert(configstore.path(name) == "/berry/config/p2cfg.json")
assert(configstore.name("already.json") == "already.json")
assert(configstore.path("already.json") == "/berry/config/already.json")
assert(configstore.name("Caps.JSON") == "Caps.JSON")
assert(configstore.path("Caps.JSON") == "/berry/config/Caps.JSON")
var caps = configstore.capabilities()
assert(caps["json_config_files"])
assert(caps["filename_only_validation"])
assert(caps["load_result"])
assert(caps["save_result"])
assert(caps["remove_result"])
assert(caps["list_result"])
assert(caps["json_null_detection"])
assert(caps["fat_jso_listing"])
assert(caps["audit"])
assert(caps["audit_policy"] == "capability_root_result_helper_consistency")
assert(caps["root"] == "/berry/config")
caps["load_result"] = false
assert(configstore.capabilities()["load_result"])
assert(type(configstore.required_capability_keys) == "function")
var required_caps = configstore.required_capability_keys()
assert(required_caps.find("load_result") >= 0)
assert(required_caps.find("root") >= 0)
required_caps.push("mutation_probe")
assert(configstore.required_capability_keys().find("mutation_probe") == nil)
assert(configstore.capability("load_result"))
assert(configstore.capability("root") == "/berry/config")
assert(configstore.capability("missing") == nil)
var audit = configstore.audit()
assert(audit["ok"])
assert(audit["problem_count"] == 0)
assert(audit["problems"].size() == 0)
assert(audit["missing_capability_keys"].size() == 0)
assert(audit["root"] == "/berry/config")
assert(audit["result_helpers"])
assert(audit["json_config_files"])
assert(audit["filename_only_validation"])
assert(audit["ensure_root"])
assert(audit["json_null_detection"])
assert(audit["fat_jso_listing"])
assert(audit["audit_policy"] == "capability_root_result_helper_consistency")
audit["problems"].push("mutation_probe")
assert(configstore.audit_problems().size() == 0)
assert(configstore.audit_ok())
var missing_fallback = {"missing": true}
var missing_loaded = configstore.load(name, missing_fallback)
assert(missing_loaded["missing"] == true)
missing_loaded["missing"] = false
assert(missing_fallback["missing"] == false)
var missing_name = "p2miss"
assert(!configstore.exists(missing_name))
assert(!configstore.remove(missing_name))

print("P2_SMOKE_STAGE configstore save")
var saved = configstore.save(name, {
    "answer": 42,
    "name": "berry",
    "items": [1, 2, 3]
})
assert(saved == "/berry/config/p2cfg.json")
assert(configstore.exists(name))

var loaded = configstore.load(name, nil)
assert(loaded["answer"] == 42)
assert(loaded["name"] == "berry")
assert(loaded["items"][2] == 3)
loaded["answer"] = 99
loaded["items"][2] = 9
var loaded_again = configstore.load(name, nil)
assert(loaded_again["answer"] == 42)
assert(loaded_again["items"][2] == 3)

print("P2_SMOKE_STAGE configstore null")
var null_name = "p2null"
assert(!configstore.exists(null_name))
var null_path = configstore.path(null_name)
var null_file = open(null_path, "w")
null_file.write("null")
null_file.close()
var null_result = configstore.load_result(null_name, {"fallback": true})
assert(null_result["ok"])
assert(null_result["found"])
assert(null_result["value"] == nil)
assert(null_result["error"] == nil)
assert(configstore.remove(null_name))

print("P2_SMOKE_STAGE configstore list")
var saw = false
for entry : configstore.list()
    if entry == "P2CFG.JSON" || entry == "p2cfg.json" || entry == "P2CFG.JSO" || entry == "p2cfg.jso"
        saw = true
    end
end
assert(saw)

print("P2_SMOKE_STAGE configstore cleanup")
assert(configstore.remove(name))
assert(!configstore.exists(name))

print("P2_SMOKE_STAGE configstore errors")
def expect_value_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "value_error")
    end
    assert(caught)
end

expect_value_error(def () return configstore.name(nil) end)
expect_value_error(def () return configstore.name("") end)
expect_value_error(def () return configstore.name("bad/name") end)
expect_value_error(def () return configstore.name("bad\\name") end)
expect_value_error(def () return configstore.path("") end)
expect_value_error(def () return configstore.path("bad/name") end)

print("P2_SMOKE_PASS configstore")
