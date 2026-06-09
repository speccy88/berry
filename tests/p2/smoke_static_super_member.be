print("P2_SMOKE_BEGIN static_super_member")

class P2StaticSuperBase
    static base_value = 17
    def inherited()
        return P2StaticSuperBase.base_value
    end
    def dynamic_static()
        return self.base_value
    end
end

var p2_static_super_module = module("p2_static_super_member")
p2_static_super_module.Base = P2StaticSuperBase

class P2StaticSuperChild : p2_static_super_module.Base
    static aa = 1
    static bb = p2_static_super_module.Base
    static base_value = 23
    def child_value()
        return self.aa + self.inherited()
    end
end

assert(P2StaticSuperChild.aa == 1)
assert(P2StaticSuperChild.bb == P2StaticSuperBase)
assert(P2StaticSuperChild.base_value == 23)
assert(issubclass(P2StaticSuperChild, P2StaticSuperBase))

var child = P2StaticSuperChild()
assert(isinstance(child, P2StaticSuperChild))
assert(isinstance(child, P2StaticSuperBase))
assert(child.aa == 1)
assert(child.bb == P2StaticSuperBase)
assert(child.child_value() == 18)
assert(child.dynamic_static() == 23)
assert(P2StaticSuperBase().dynamic_static() == 17)
P2StaticSuperBase.base_value = 18
assert(child.child_value() == 19)
assert(child.dynamic_static() == 23)
assert(P2StaticSuperBase().dynamic_static() == 18)
P2StaticSuperChild.base_value += 5
assert(child.dynamic_static() == 28)
assert(child.child_value() == 19)
assert(P2StaticSuperBase().dynamic_static() == 18)

print("P2_SMOKE_PASS static_super_member")
