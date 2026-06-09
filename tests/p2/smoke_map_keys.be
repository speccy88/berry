print("P2_SMOKE_BEGIN map_keys")

def expect_runtime_error(f)
    var caught = false
    try
        f()
    except .. as e, m
        caught = true
        assert(e == "runtime_error")
    end
    assert(caught)
end

class P2KeyWithHash
    var val
    def init(v)
        self.val = v
    end
    def hash()
        return self.val
    end
    def ==(other)
        return self.val == other.val
    end
end

var k1 = P2KeyWithHash(10)
var k2 = P2KeyWithHash(20)
var kh = {}
kh[k1] = "ten"
kh[k2] = "twenty"
assert(kh[k1] == "ten")
assert(kh[k2] == "twenty")
assert(kh.contains(k1))
assert(kh.contains(P2KeyWithHash(10)))
assert(kh[P2KeyWithHash(10)] == "ten")
assert(kh.size() == 2)
kh[P2KeyWithHash(10)] = "TEN"
assert(kh.size() == 2)
assert(kh[k1] == "TEN")
assert(kh[P2KeyWithHash(10)] == "TEN")
kh.remove(P2KeyWithHash(10))
assert(kh.size() == 1)
assert(!kh.contains(k1))
assert(kh[k2] == "twenty")

class P2KeyHashCollision
    var val
    def init(v)
        self.val = v
    end
    def hash()
        return 99
    end
    def ==(other)
        return self.val == other.val
    end
end

var kc = {}
kc[P2KeyHashCollision("a")] = 1
kc[P2KeyHashCollision("b")] = 2
assert(kc.size() == 2)
assert(kc[P2KeyHashCollision("a")] == 1)
assert(kc[P2KeyHashCollision("b")] == 2)
assert(kc.contains(P2KeyHashCollision("a")))
assert(!kc.contains(P2KeyHashCollision("c")))
kc[P2KeyHashCollision("a")] = 11
assert(kc.size() == 2)
assert(kc[P2KeyHashCollision("a")] == 11)
assert(kc[P2KeyHashCollision("b")] == 2)

class P2KeyNoHash
    var val
    def init(v)
        self.val = v
    end
end

var k3 = P2KeyNoHash(1)
var k4 = P2KeyNoHash(2)
var kn = {}
kn[k3] = "a"
kn[k4] = "b"
assert(kn[k3] == "a")
assert(kn[k4] == "b")
assert(kn.contains(k3))
assert(!kn.contains(P2KeyNoHash(1)))
assert(kn.size() == 2)

var real_keys = {}
real_keys[1.5] = "real_key"
assert(real_keys.contains(1.5))
assert(real_keys[1.5] == "real_key")

class P2BadHash
    def hash()
        return "not an int"
    end
end

expect_runtime_error(def ()
    var bad = {}
    bad[P2BadHash()] = 1
end)

print("P2_SMOKE_PASS map_keys")
