print("P2_SMOKE_BEGIN vm_ops")

def neg(x) return -x end
def bitnot(x) return ~x end
def add(a, b) return a + b end
def sub(a, b) return a - b end
def mul(a, b) return a * b end
def div(a, b) return a / b end
def mod(a, b) return a % b end
def shl(a, b) return a << b end
def shr(a, b) return a >> b end
def concat(a, b) return a .. b end

assert(neg(7) == -7)
assert(bitnot(0) == -1)
assert(add(19, 23) == 42)
assert(sub(50, 8) == 42)
assert(mul(6, 7) == 42)
assert(div(84, 2) == 42)
assert(mod(47, 5) == 2)
assert(shl(21, 1) == 42)
assert(shr(84, 1) == 42)
assert(concat("ber", "ry") == "berry")

assert((0x30 | 0x0c) == 0x3c)
assert((0x3f & 0x2a) == 0x2a)
assert((0x3c ^ 0x16) == 0x2a)
assert(42 == 42)
assert(42 != 43)
assert(41 < 42)
assert(42 <= 42)
assert(43 > 42)
assert(42 >= 42)
assert(type(42 == 42) == "bool")
assert(type(41 < 42) == "bool")

var s = "azertyuiop"
assert(s[0] == "a")
assert(s[-1] == "p")
assert(s[0..2] == "aze")
assert(s[-4..-2] == "uio")
assert(s[-10..-1] == "azertyuiop")
assert(s[-2..-4] == "")

var l = [0, 1, 2, 3, 4]
assert(l[0] == 0)
assert(l[-1] == 4)
assert(l[1..3] == [1, 2, 3])
assert(l[-3..-1] == [2, 3, 4])
assert(l[-5..-1] == [0, 1, 2, 3, 4])
assert(l[3..1] == [])

class Vec
    var v
    def init(v)
        self.v = v
    end
    def +(other)
        return Vec(self.v + other.v)
    end
    def -(other)
        return Vec(self.v - other.v)
    end
    def *(other)
        return Vec(self.v * other.v)
    end
    def ==(other)
        return self.v == other.v
    end
end

assert((Vec(19) + Vec(23)).v == 42)
assert((Vec(50) - Vec(8)).v == 42)
assert((Vec(6) * Vec(7)).v == 42)
assert(Vec(42) == Vec(42))
assert(!(Vec(42) == Vec(41)))
assert(Vec(42) != Vec(41))
assert(!(Vec(42) != Vec(42)))

print("P2_SMOKE_PASS vm_ops")
