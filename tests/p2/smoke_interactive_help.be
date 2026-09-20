# Read-only help against the actual registered P2 module. No pin/bus/SD use.
import p2
import introspect

var root = p2.help()
assert(root["topic"] == "p2")
assert(root["groups"].find("pin") != nil)
var pin = p2.help("pin")
assert(pin["members"].find("read") != nil)
assert(pin["members"].find("high") != nil)
assert(pin["members"].size() == introspect.members(p2.pin).size())
for name : pin["members"]
    assert(introspect.contains(p2.pin, name))
end
assert(p2.help("cog")["capabilities"]["spawn_source"] == p2.cog.capabilities()["spawn_source"])
assert(!p2.help("cog")["capabilities"]["isolated_child_vm_cog"])
def check_capabilities(topic, expected)
    var actual = p2.help(topic)["capabilities"]
    assert(actual.size() == expected.size())
    for key : expected.keys()
        assert(actual.contains(key))
        assert(actual[key] == expected[key])
    end
end
check_capabilities("debug", p2.debug.capabilities())
check_capabilities("asm", p2.asm.capabilities())

def help_error(value, expected)
    var caught = false
    try
        p2.help(value)
    except .. as kind, message
        assert(kind == expected)
        caught = true
    end
    assert(caught)
end
help_error(7, "type_error")
help_error(nil, "type_error")
help_error([], "type_error")
help_error("", "value_error")
help_error("missing_group", "value_error")
help_error("pin.read", "value_error")
help_error("pin\000suffix", "value_error")
var caught = false
try
    p2.help("pin", "extra")
except "type_error"
    caught = true
end
assert(caught)
print("interactive help checks passed")
