print("P2_SMOKE_BEGIN conversions")

assert(type(nil) == "nil")
assert(type(true) == "bool")
assert(type(42) == "int")
assert(type(42.5) == "real")
assert(type("berry") == "string")
assert(type([]) == "list")
assert(type({}) == "map")
assert(type(bytes()) == "bytes")
assert(type(range(0, 1)) == "range")

assert(str(nil) == "nil")
assert(str(true) == "true")
assert(str(false) == "false")
assert(str(42) == "42")
assert(str(42.5) == "42.5")
assert(str("berry") == "berry")
assert(str([1, 2]) == "[1, 2]")
assert(str({"a": 1}) == "{'a': 1}" || str({"a": 1}) == '{"a": 1}')

assert(number("42") == 42)
assert(type(number("3.5")) == "real")
assert(number("-12") == -12)
assert(number("1e2") == 100.0)
assert(number("1e-2") == 0.01)
assert(number("not-number") == nil)
assert(number(nil) == nil)
assert(number(42) == 42)
assert(number(3.5) == 3.5)

assert(int("0") == 0)
assert(int("42") == 42)
assert(int("-42") == -42)
assert(int("0x2a") == 42)
assert(int("0X2A") == 42)
assert(int(true) == 1)
assert(int(false) == 0)
assert(int(42.9) == 42)
assert(int(42) == 42)
assert(int("not-int") == nil)
assert(int(nil) == nil)

assert(real("42.5") == 42.5)
assert(real("1e2") == 100.0)
assert(real("-0.5") == -0.5)
assert(real(42) == 42.0)
assert(real(42.5) == 42.5)
assert(real("not-real") == nil)
assert(real(nil) == nil)

class P2Convert
    def tostring()
        return "converted"
    end
    def toint()
        return 123
    end
    def toreal()
        return 12.5
    end
end

var conv = P2Convert()
assert(str(conv) == "converted")
assert(int(conv) == 123)
assert(real(conv) == 12.5)

class P2ConvertEdge
    def tostring()
        return ""
    end
    def toint()
        return -42
    end
    def toreal()
        return -0.5
    end
end

var conv_edge = P2ConvertEdge()
assert(str(conv_edge) == "")
assert(int(conv_edge) == -42)
assert(real(conv_edge) == -0.5)

assert(bool() == false)
assert(bool(nil) == false)
assert(bool(false) == false)
assert(bool(true) == true)
assert(bool(0) == false)
assert(bool(1) == true)
assert(bool(0.0) == false)
assert(bool(0.1) == true)
assert(bool("") == false)
assert(bool("x") == true)
assert(bool([]) == false)
assert(bool([0]) == true)
assert(bool({}) == false)
assert(bool({"x": false}) == true)
assert(bool(bytes()) == false)
assert(bool(bytes("00")) == true)

assert(size("") == 0)
assert(size("berry") == 5)
assert(size([]) == 0)
assert(size([1, 2, 3]) == 3)
assert(size({}) == 0)
assert(size({"a": 1, "b": 2}) == 2)
assert(size(bytes("1122")) == 2)

class P2Base
end

class P2Child : P2Base
end

var child = P2Child()
assert(classname(child) == "P2Child")
assert(classof(child) == P2Child)
assert(classof(super(child)) == P2Base)
assert(super(super(child)) == nil)
assert(issubclass(P2Child, P2Base))
assert(!issubclass(P2Base, P2Child))
assert(isinstance(child, P2Child))
assert(isinstance(child, P2Base))
assert(!isinstance(child, map))

print("P2_SMOKE_PASS conversions")
