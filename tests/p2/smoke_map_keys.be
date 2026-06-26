print("P2_SMOKE_BEGIN map_keys")

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
print("P2_SMOKE_STAGE map_keys_hash_direct")
print("P2_SMOKE_MAP_HASH_CONTAINS", kh.contains(k1), kh.contains(P2KeyWithHash(10)))
assert(kh.contains(k1))
assert(kh[k1] == "ten")
print("P2_SMOKE_STAGE map_keys_hash_equiv")
assert(kh.size() == 2)
kh[k1] = "TEN"
assert(kh.size() == 2)
assert(kh[k1] == "TEN")
print("P2_SMOKE_STAGE map_keys_hash_replace")
kh.remove(k1)
assert(kh.size() == 1)
assert(!kh.contains(k1))
assert(kh[k2] == "twenty")
print("P2_SMOKE_STAGE map_keys_hash")

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
var kca = P2KeyHashCollision("a")
var kcb = P2KeyHashCollision("b")
kc[kca] = 1
kc[kcb] = 2
assert(kc.size() == 2)
assert(kc[kca] == 1)
assert(kc[kcb] == 2)
assert(!kc.contains(P2KeyHashCollision("c")))
kc[kca] = 11
assert(kc.size() == 2)
assert(kc[kca] == 11)
assert(kc[kcb] == 2)
print("P2_SMOKE_STAGE map_keys_collision")

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
print("P2_SMOKE_STAGE map_keys_nohash")

var real_keys = {}
real_keys[1.5] = "real_key"
assert(real_keys.contains(1.5))
assert(real_keys[1.5] == "real_key")
print("P2_SMOKE_STAGE map_keys_real")

class P2BadHash
    def hash()
        return "not an int"
    end
end

var bad_hash_error = nil
try
    var bad = {}
    bad[P2BadHash()] = 1
except .. as e, m
    bad_hash_error = e
end
print("P2_SMOKE_MAP_BAD_HASH", bad_hash_error == nil ? "accepted" : bad_hash_error)
assert(bad_hash_error == nil || bad_hash_error == "runtime_error")
print("P2_SMOKE_STAGE map_keys_badhash")

print("P2_SMOKE_PASS map_keys")
