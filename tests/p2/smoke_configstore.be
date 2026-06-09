print("P2_SMOKE_BEGIN configstore")

import configstore

var name = "p2_smoke_config"
assert(!configstore.exists(name))

assert(configstore.ensure() == "/berry/config")
assert(configstore.path(name) == "/berry/config/p2_smoke_config.json")
assert(configstore.name("already.json") == "already.json")
assert(configstore.path("already.json") == "/berry/config/already.json")
assert(configstore.name("Caps.JSON") == "Caps.JSON")
assert(configstore.path("Caps.JSON") == "/berry/config/Caps.JSON")
var missing_fallback = {"missing": true}
var missing_loaded = configstore.load(name, missing_fallback)
assert(missing_loaded["missing"] == true)
missing_loaded["missing"] = false
assert(missing_fallback["missing"] == false)
var missing_name = "p2_smoke_config_missing"
assert(!configstore.exists(missing_name))
assert(!configstore.remove(missing_name))

var saved = configstore.save(name, {
    "answer": 42,
    "name": "berry",
    "items": [1, 2, 3]
})
assert(saved == "/berry/config/p2_smoke_config.json")
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

var saw = false
for entry : configstore.list()
    if entry == "P2_SMOKE_CONFIG.JSON" || entry == "p2_smoke_config.json"
        saw = true
    end
end
assert(saw)

assert(configstore.remove(name))
assert(!configstore.exists(name))

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
