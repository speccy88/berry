print("P2_SMOKE_BEGIN super")

class P2SuperA
    var a
    def init(a)
        self.a = a
    end
    def who()
        return "a"
    end
    def route()
        return self.who()
    end
    def sum(x)
        return self.a + x
    end
end

class P2SuperB : P2SuperA
    var b
    def init(a, b)
        super(self).init(a)
        self.b = b
    end
    def who()
        return "b"
    end
    def route()
        return super(self, P2SuperA).route() + "b"
    end
    def sum(x)
        return super(self).sum(x) + self.b
    end
end

class P2SuperC : P2SuperB
    var c
    def init(a, b, c)
        super(self).init(a, b)
        self.c = c
    end
    def who()
        return "c"
    end
    def route()
        return super(self, P2SuperB).route() + "c"
    end
    def sum(x)
        return super(self).sum(x) + self.c
    end
end

var c = P2SuperC(1, 2, 3)
assert(c.a == 1)
assert(c.b == 2)
assert(c.c == 3)
assert(classof(c) == P2SuperC)
assert(classof(super(c)) == P2SuperB)
assert(classof(super(super(c))) == P2SuperA)
assert(super(super(super(c))) == nil)
assert(super(P2SuperC) == P2SuperB)
assert(super(super(P2SuperC)) == P2SuperA)
assert(super(super(super(P2SuperC))) == nil)
assert(classof(super(c, P2SuperB)) == P2SuperB)
assert(classof(super(c, P2SuperA)) == P2SuperA)
assert(super(c, map) == nil)
assert(c.who() == "c")
assert(c.route() == "cbc")
assert(super(c).who() == "b")
assert(super(super(c)).who() == "a")
assert(super(c).route() == "cb")
assert(super(c, P2SuperA).who() == "a")
assert(super(c, P2SuperA).sum(41) == 42)
assert(c.sum(36) == 42)

class P2SuperNoInitBase
    static a = 1
end

class P2SuperNoInitChild : P2SuperNoInitBase
    var b
    def init(a, b)
        super(self).init(a)
        self.b = b
    end
end

var no_init = P2SuperNoInitChild(7, 8)
assert(no_init.a == 1)
assert(no_init.b == 8)
assert(no_init.init != nil)
no_init.init(9, 10)
assert(no_init.b == 10)

class P2SuperSelectorA
end

class P2SuperSelectorB : P2SuperSelectorA
    def auto_parent()
        return super(self)
    end
    def selected_parent(c)
        return super(self, c)
    end
end

class P2SuperSelectorC : P2SuperSelectorB
end

var b2 = P2SuperSelectorB()
var c2 = P2SuperSelectorC()
assert(classof(b2.auto_parent()) == P2SuperSelectorA)
assert(classof(c2.auto_parent()) == P2SuperSelectorA)
assert(classof(c2.selected_parent(P2SuperSelectorB)) == P2SuperSelectorB)
assert(classof(c2.selected_parent(P2SuperSelectorA)) == P2SuperSelectorA)
assert(classof(c2.selected_parent(nil)) == P2SuperSelectorB)
assert(c2.selected_parent(P2SuperSelectorC) == nil)

print("P2_SMOKE_PASS super")
