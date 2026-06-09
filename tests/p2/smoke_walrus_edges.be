print("P2_SMOKE_BEGIN walrus_edges")

def p2_walrus_shadow_builtin()
    print := 1
    assert(print == 1)
    print := print + 41
    assert(print == 42)
end

p2_walrus_shadow_builtin()

import global

def p2_walrus_list_sequence()
    var x
    return [x := 1, x := x + 1, x]
end

assert(p2_walrus_list_sequence() == [1, 2, 2])

def p2_walrus_map_literal()
    var k, v
    var m = {k := "answer": v := 42}
    return [k, v, m["answer"]]
end

assert(p2_walrus_map_literal() == ["answer", 42, 42])

def p2_walrus_concat(a, b, c)
    return str(a) + str(b) + str(c)
end

def p2_walrus_global_args()
    return p2_walrus_concat(
        global.p2_walrus_edges_value := 1,
        global.p2_walrus_edges_value := 42,
        global.p2_walrus_edges_value := 0
    )
end

assert(p2_walrus_global_args() == "1420")
assert(global.p2_walrus_edges_value == 0)

global.p2_walrus_edges_list = [10, 11]
def p2_walrus_index_value()
    return p2_walrus_concat(
        global.p2_walrus_edges_list[0] := 4,
        global.p2_walrus_edges_list[1] := 2,
        global.p2_walrus_edges_list[0] + global.p2_walrus_edges_list[1]
    )
end

assert(p2_walrus_index_value() == "426")
assert(global.p2_walrus_edges_list == [4, 2])

def p2_walrus_local_args()
    var a, b
    return [
        p2_walrus_concat(a := 4, b := 2, a + b),
        a,
        b
    ]
end

assert(p2_walrus_local_args() == ["426", 4, 2])

class P2WalrusMember
    var value
    def init()
        self.value = 2
    end
    def get_value()
        var tmp
        if (tmp := self.value) != nil
            return tmp
        end
    end
    def set_truthy()
        if self.value := 42
            return self
        end
    end
end

var wm = P2WalrusMember()
assert(wm.get_value() == 2)
assert(wm.set_truthy() == wm)
assert(wm.value == 42)

global.undef("p2_walrus_edges_value")
global.undef("p2_walrus_edges_list")

print("P2_SMOKE_PASS walrus_edges")
