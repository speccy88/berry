print("P2_SMOKE_BEGIN string_format_extra")

import string

def expect_type_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "type_error")
    end
end

class P2StringToInt
    def toint()
        return 42
    end
end

class P2StringCountingToInt
    var count
    def init()
        self.count = 0
    end
    def toint()
        self.count = self.count + 1
        return self.count + 40
    end
end

class P2StringPlain
end

var as_int = P2StringToInt()
var counting_int = P2StringCountingToInt()
var plain = P2StringPlain()

assert(string.format("%i", as_int) == "42")
assert(string.format("%i", counting_int) == "41")
assert(string.format("%i", counting_int) == "42")
assert(counting_int.count == 2)
assert(string.format("%i", plain) == "")
assert(string.format("%c", as_int) == "*")
assert(string.format("%c", counting_int) == "+")
assert(counting_int.count == 3)
assert(string.format("%.1f", nil) == "")
assert(string.format("%.1f", true) == "")
assert(string.format("%.1f", false) == "")
assert(string.format("%.1f", as_int) == "")
assert(string.format("%q", "\ntest") == "'\\ntest'")

var joined = "a" "b""c"
assert(joined == "abc")

joined = "a" #- comment -# "b" #--# "c"
assert(joined == "abc")

assert("a" * 64 == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
var long_mul = "a" * 100
assert(size(long_mul) == 100)

expect_type_error(def () return "hello" * "world" end)
expect_type_error(def () return "hello" * 3.14 end)
expect_type_error(def () return "hello" * nil end)

assert(("a" * 2) + ("b" * 3) == "aabbb")
assert("x" * (1 + 2) == "xxx")
assert("y" * (true && true) == "y")
assert("z" * (false || false) == "")

print("P2_SMOKE_PASS string_format_extra")
