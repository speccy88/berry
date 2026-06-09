print("P2_SMOKE_BEGIN classes")

class CountTo
    var maximum
    def init(maximum)
        self.maximum = maximum
    end
    def iter()
        var i = -1, maximum = self.maximum
        return def ()
            i += 1
            if i > maximum
                raise "stop_iteration"
            end
            return i
        end
    end
end

var total = 0
for i : CountTo(5)
    total += i
end
assert(total == 15)

var counter = CountTo(2)
var iter_a = counter.iter()
var iter_b = counter.iter()
assert(iter_a() == 0)
assert(iter_a() == 1)
assert(iter_b() == 0)
assert(iter_a() == 2)
try
    iter_a()
    assert(false)
except .. as e, m
    assert(e == "stop_iteration")
end
assert(iter_b() == 1)

var class_module = module("p2_class_smoke")
var init_count = 0
class ClassFromMember
    def init()
        init_count += 1
    end
end
class_module.ClassFromMember = ClassFromMember
assert(type(ClassFromMember()) == "instance")
assert(type(class_module.ClassFromMember()) == "instance")
assert(init_count == 2)

class StaticDemo
    static a = 1, b, label = "berry"
    var value
    def init(value)
        self.value = value
    end
    static def pair(x, y)
        return [x, y]
    end
    static mapper = def (x, y)
        return {"x": x, "y": y}
    end
    def describe(prefix)
        return [prefix, self.value, StaticDemo.a, self.label]
    end
end

var demo = StaticDemo(42)
assert(classof(demo) == StaticDemo)
assert(demo.value == 42)
assert(StaticDemo.a == 1)
assert(demo.a == 1)
assert(StaticDemo.b == nil)
assert(demo.label == "berry")
assert(StaticDemo.pair(1, 2) == [1, 2])
assert(demo.pair(3, 4) == [3, 4])
assert(StaticDemo.mapper(5, 6)["y"] == 6)
assert(demo.describe("demo") == ["demo", 42, 1, "berry"])
StaticDemo.a = 2
assert(demo.a == 2)
assert(demo.describe("after") == ["after", 42, 2, "berry"])

class IndirectDemo
    var a, b
    static field = "a"
    def init(a, b)
        self.(IndirectDemo.field) = a
        self.("b") = b
    end
    def inc(x)
        return x + 1
    end
end

var indirect = IndirectDemo(7, 8)
assert(indirect.a == 7)
assert(indirect.("a") == 7)
assert(indirect.(IndirectDemo.field) == 7)
assert(indirect.("b") == 8)
indirect.("a") = 41
assert(indirect.a == 41)
assert(indirect.("inc")(41) == 42)

print("P2_SMOKE_PASS classes")
