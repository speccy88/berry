print("P2_SMOKE_BEGIN virtual_setmember")

def expect_attribute_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "attribute_error")
    end
    assert(caught)
end

class P2VirtualSetmember
    var normal, virtual_value, assigned

    def init()
        self.normal = 1
        self.virtual_value = 3
        self.assigned = {}
    end

    def member(name)
        if name == "virtual"
            return self.virtual_value
        end
        if name == "assigned"
            return self.assigned
        end
        if self.assigned.contains(name)
            return self.assigned[name]
        end
        return nil
    end

    def setmember(name, value)
        if name == "virtual"
            self.virtual_value = value
            return true
        end
        if name == "callback"
            self.assigned[name] = value
            return true
        end
        if name == "payload"
            self.assigned[name] = value
            return true
        end
        return false
    end
end

var obj = P2VirtualSetmember()

assert(obj.normal == 1)
assert(obj.virtual == 3)
obj.normal = 10
assert(obj.normal == 10)
assert(obj.virtual == 3)

obj.virtual = 30
assert(obj.virtual == 30)
assert(obj.virtual_value == 30)
var virtual_name = "virtual"
obj.(virtual_name) = 31
assert(obj.virtual == 31)
assert(obj.virtual_value == 31)

obj.payload = ["p2", 42]
assert(obj.payload == ["p2", 42])
assert(obj.assigned["payload"] == ["p2", 42])
obj.payload = ["p2", 43]
assert(obj.payload == ["p2", 43])
assert(obj.assigned["payload"] == ["p2", 43])

var payload_name = "payload"
obj.(payload_name) = ["dynamic", 7]
assert(obj.payload == ["dynamic", 7])
assert(obj.assigned["payload"] == ["dynamic", 7])

var normal_name = "normal"
obj.(normal_name) = 11
assert(obj.normal == 11)
assert(!obj.assigned.contains("normal"))

var callback = def (self_ref, name, value)
    return [self_ref == obj, name, value]
end
obj.callback = callback
assert(obj.assigned["callback"](obj, "edge", 32) == [true, "edge", 32])
assert(obj.callback("xmm", 1) == [true, "xmm", 1])
var callback_name = "callback"
obj.(callback_name) = def (self_ref, name, value)
    return [name, value, self_ref == obj]
end
assert(obj.callback("dynamic", 42) == ["dynamic", 42, true])
assert(obj.assigned["callback"](obj, "stored", 7) == ["stored", 7, true])

expect_attribute_error(def ()
    obj.missing = 0
end)

print("P2_SMOKE_PASS virtual_setmember")
