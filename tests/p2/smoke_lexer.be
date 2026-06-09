print("P2_SMOKE_BEGIN lexer")

def expect_syntax_error(src)
    var caught = false
    try
        compile(src)
    except .. as e, m
        caught = true
        assert(e == "syntax_error")
        assert(type(m) == "string")
    end
    assert(caught)
end

assert(compile("x = 5; 0..x") != nil)
assert(compile("var x = 40 #- ignored -# + 2 return x")() == 42)
assert(compile("var x = 40 # ignored\n + 2 return x")() == 42)
assert("\x5a" == "Z")
assert("\x5A" == "Z")
assert(bytes().fromstring("\x00").tohex() == "00")
assert("\132" == "Z")
assert("\a\b\f\n\r\t\v\\\'\"\?" == "\x07\x08\x0c\x0a\x0d\x09\x0b\x5c\x27\x22\x3f")

assert(.45 == 0.45)
assert(0X10 == 16)
assert(0x10 == 16)
assert(0X1A == 26)
assert(0x1a == 26)
assert(45. == 45)
assert(45.e-1 == 4.5)
assert(45.E-1 == 4.5)
assert(45.1e-1 == 4.51)
assert(45.1e2 == 4510)
assert(45.e2 == 4500)
assert(45.e+2 == 4500)

assert(bytes().fromstring("a").tohex() == "61")
assert(bytes().fromstring("\u0061").tohex() == "61")
assert(bytes().fromstring("\u0088").tohex() == "C288")
assert(bytes().fromstring("\u0288").tohex() == "CA88")
assert(bytes().fromstring("\u1288").tohex() == "E18A88")

expect_syntax_error('"\\u"')
expect_syntax_error('"\\u1"')
expect_syntax_error('"\\u22"')
expect_syntax_error('"\\u333"')
expect_syntax_error("x = 5; 0...x;")
expect_syntax_error("0xg")
expect_syntax_error('"\\x"')
expect_syntax_error('"\\x5"')
expect_syntax_error('"\\x5g"')
expect_syntax_error("0x5g")
expect_syntax_error('"\\779"')
expect_syntax_error('"\n')
expect_syntax_error("45.e-1.")
expect_syntax_error("0x45j")

print("P2_SMOKE_PASS lexer")
