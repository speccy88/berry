print("P2_SMOKE_BEGIN int_numeric")

class P2IntConvertible
    def toint()
        return 42
    end
end

class P2NegativeIntConvertible
    def toint()
        return -7
    end
end

assert(int(P2IntConvertible()) == 42)
assert(int(P2NegativeIntConvertible()) == -7)

assert(int("0x00") == 0)
assert(int("0X1") == 1)
assert(int("0x000000F") == 15)
assert(int("0xff") == 255)
assert(int("0x1000") == 0x1000)
assert(int("0xFF00FF00") == 0xFF00FF00)

var a = 11
assert((a & 0xFE) == 10)
assert((a | 32) == 43)
assert((a ^ 33) == 42)
assert((11 & 0xFE) == 10)
assert((11 | 32) == 43)
assert((11 ^ 33) == 42)
assert(~a == -12)
assert(~11 == -12)
assert((1 << 5) == 32)
assert((64 >> 2) == 16)
assert((-8 >> 1) == -4)
assert((42 << 0) == 42)
assert((42 >> 0) == 42)
var shift_count = 3
assert((1 << shift_count) == 8)
assert((64 >> shift_count) == 8)
assert(((1 << 6) >> 1) == 32)
assert(((3 | 4) << 1) == 14)

print("P2_SMOKE_PASS int_numeric")
