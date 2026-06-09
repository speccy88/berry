print("P2_SMOKE_BEGIN bytes_b64_fixed")

def expect_attribute_error(f)
    try
        f()
        assert(false)
    except .. as e, m
        assert(e == "attribute_error")
    end
end

var b64_api = bytes()
assert(type(b64_api.tob64) == "function")
assert(type(b64_api.fromb64) == "function")

assert(bytes().tob64() == "")
assert(bytes("00").tob64() == "AA==")
assert(bytes("1122").tob64() == "ESI=")
assert(bytes("112233").tob64() == "ESIz")
assert(bytes("11223344").tob64() == "ESIzRA==")
assert(bytes("1122334455").tob64() == "ESIzRFU=")
assert(bytes("112233445566").tob64() == "ESIzRFVm")

assert(bytes().fromb64("") == bytes(""))
assert(bytes().fromb64("AA==") == bytes("00"))
assert(bytes().fromb64("ESI=") == bytes("1122"))
assert(bytes().fromb64("ESIz") == bytes("112233"))
assert(bytes().fromb64("ESIzRA==") == bytes("11223344"))
assert(bytes().fromb64("ESIzRFU=") == bytes("1122334455"))
assert(bytes().fromb64("ESIzRFVm") == bytes("112233445566"))

assert(str(bytes(-1)) == "bytes('00')")
assert(str(bytes(-5)) == "bytes('0000000000')")
assert(str(bytes("11", -1)) == "bytes('11')")
assert(str(bytes("11", -5)) == "bytes('1100000000')")
assert(str(bytes("11223344", -4)) == "bytes('11223344')")
assert(str(bytes(-3).fromb64("RFVm")) == "bytes('445566')")

var b = bytes("11223344", -4)
assert(b.get(0, 2) == 0x2211)
b.set(0, 0x5566, 2)
assert(b.get(0, 2) == 0x5566)
assert(b[0] == 0x66)
b[0] = 12
assert(b[0] == 12)
assert(b.resize(4) == bytes("0C552233"))

b = bytes("112233", -3)
expect_attribute_error(def () b.add(1) end)
expect_attribute_error(def () b.add(2, 2) end)
expect_attribute_error(def () b.resize(4) end)
expect_attribute_error(def () b.fromstring("aaaaa") end)
expect_attribute_error(def () b.fromb64("RFVmdw==") end)
expect_attribute_error(def () b.clear() end)
expect_attribute_error(def () b.bytes() end)
assert(b + b == bytes("112233112233"))

print("P2_SMOKE_PASS bytes_b64_fixed")
