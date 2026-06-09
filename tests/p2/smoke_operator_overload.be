print("P2_SMOKE_BEGIN operator_overload")

class P2CallableValue
    var value
    def init(value)
        self.value = value
    end
    def +()
        return self.value
    end
    def ()()
        return self.value
    end
end

var a = P2CallableValue(123)
var b = P2CallableValue(123)
assert(a + b == 246)
assert(a() == 123)
assert(P2CallableValue(42)() == 42)
var callables = [P2CallableValue(9)]
assert(callables[0]() == 9)

class P2BinaryAddValue
    var value
    def init(value)
        self.value = value
    end
    def +(other)
        return P2BinaryAddValue(self.value + other.value)
    end
end

var sum = P2BinaryAddValue(19) + P2BinaryAddValue(23)
assert(type(sum) == "instance")
assert(classof(sum) == P2BinaryAddValue)
assert(sum.value == 42)
var chained_sum = P2BinaryAddValue(5) + P2BinaryAddValue(6) + P2BinaryAddValue(7)
assert(type(chained_sum) == "instance")
assert(classof(chained_sum) == P2BinaryAddValue)
assert(chained_sum.value == 18)

print("P2_SMOKE_PASS operator_overload")
