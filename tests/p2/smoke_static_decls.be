print("P2_SMOKE_BEGIN static_decls")

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

class P2StaticDecls
    static legacy
    static var count, label, ratio
    var instance_value

    def init()
        self.instance_value = 2
    end

    def bump_count(delta)
        P2StaticDecls.count += delta
        return self.count
    end
end

assert(P2StaticDecls.legacy == nil)
assert(P2StaticDecls.count == nil)
assert(P2StaticDecls.label == nil)
assert(P2StaticDecls.ratio == nil)
expect_attribute_error(def () return P2StaticDecls.instance_value end)
expect_attribute_error(def () return P2StaticDecls.missing end)

var obj = P2StaticDecls()
assert(obj.instance_value == 2)
assert(obj.legacy == nil)
assert(obj.count == nil)

P2StaticDecls.legacy = 1
P2StaticDecls.count = 3
P2StaticDecls.label = "edge32"
P2StaticDecls.ratio = 3.5

assert(P2StaticDecls.legacy == 1)
assert(P2StaticDecls.count == 3)
assert(P2StaticDecls.label == "edge32")
assert(P2StaticDecls.ratio == 3.5)
assert(obj.legacy == 1)
assert(obj.count == 3)
assert(obj.label == "edge32")
assert(obj.ratio == 3.5)
assert(obj.bump_count(4) == 7)
assert(P2StaticDecls.count == 7)
assert(obj.count == 7)
var obj2 = P2StaticDecls()
assert(obj2.count == 7)
P2StaticDecls.count += 1
assert(obj.count == 8)
assert(obj2.count == 8)
P2StaticDecls.label = ["edge", "static"]
assert(obj.label == ["edge", "static"])
obj2.label.push("shared")
assert(P2StaticDecls.label == ["edge", "static", "shared"])
assert(obj.label == ["edge", "static", "shared"])
P2StaticDecls.ratio = {"kind": "static"}
assert(obj.ratio == {"kind": "static"})
obj2.ratio["seen"] = true
assert(P2StaticDecls.ratio == {"kind": "static", "seen": true})
assert(obj.ratio == {"kind": "static", "seen": true})

var fn = def (x, y)
    return [x, y]
end

obj.instance_value = fn
P2StaticDecls.legacy = fn
assert(obj.instance_value(1, 2) == [1, 2])
assert(obj.legacy(3, 4) == [3, 4])
assert(P2StaticDecls.legacy(5, 6) == [5, 6])

print("P2_SMOKE_PASS static_decls")
