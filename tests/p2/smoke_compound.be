print("P2_SMOKE_BEGIN compound")

var a = 0
assert(a == 0)
a += 1
assert(a == 1)
a += 10 / 2
assert(a == 6)
a -= 1
assert(a == 5)
a *= 3
assert(a == 15)
a /= 5
assert(a == 3)
a %= 2
assert(a == 1)

class P2CompoundBox
    var a, b
    def init()
        self.a = 1
        self.b = "x"
    end
    def add_half(x)
        self.a += x / 2
    end
end

var box = P2CompoundBox()
assert(box.a == 1)
box.add_half(10)
assert(box.a == 6)
box.a += 36
assert(box.a == 42)
var member_name = "a"
box.(member_name) += 1
assert(box.a == 43)
assert(box.(member_name) == 43)

var values = [1, 2, 3]
values[0] += 4
values[1] *= 5
values[2] -= 1
assert(values == [5, 10, 2])
var value_index = 1
values[value_index] += values[0]
assert(values == [5, 15, 2])

var rec = P2CompoundBox()
rec.a = {"x": 1, "y": 2}
assert(rec.a[rec.b] == 1)
rec.a[rec.b] += 2
assert(rec.a[rec.b] == 3)
rec.a["y"] *= 4
assert(rec.a["y"] == 8)
rec.b = "y"
rec.a[rec.b] += 1
assert(rec.a["y"] == 9)
assert(rec.a["x"] == 3)

var bits = 0x0f
bits <<= 4
assert(bits == 0xf0)
bits >>= 2
assert(bits == 0x3c)
bits &= 0x0f
assert(bits == 0x0c)
bits |= 0x30
assert(bits == 0x3c)
bits ^= 0x0c
assert(bits == 0x30)

print("P2_SMOKE_PASS compound")
