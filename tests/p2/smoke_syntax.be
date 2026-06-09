print("P2_SMOKE_BEGIN syntax")

assert(f"" == "")
assert(f"abc\n\r\t" == "abc\n\r\t")
assert(f"{{a}}" == "{a}")
assert(f"A = {1+1}" == "A = 2")
assert(f"A = {1+1:i}" == "A = 2")
assert(f"A = {1+1:04i}" == "A = 0002")
assert(f"P = {3.1415:.2f}" == "P = 3.14")
var fvalue = "foobar{0}"
assert(f"S = {fvalue}" == "S = foobar{0}")
assert(f"{fvalue=}" == "fvalue=foobar{0}")
var fwidth = 4
assert(f"W = {42:0{fwidth}i}" == "W = 0042")
var fitems = [40, 2]
assert(f"N = {fitems[0] + fitems[1]:04i}" == "N = 0042")
var fmap = {"name": "berry"}
assert(f"Name = {fmap['name']}" == "Name = berry")
var fkey = "name"
assert(f"Name2 = {fmap[fkey]}" == "Name2 = berry")

var a = 1
assert((a := a + 1) == 2)
assert((a := a + 1) == 3)

def walrus_loop()
    var defer = 4
    var out = []
    for i : 0..20
        if (defer := defer - 1) == 0
            out.push(i)
            defer = 4
        end
    end
    return out
end
assert(walrus_loop() == [3, 7, 11, 15, 19])

import global

def identity(x)
    return x
end

def walrus_global()
    return identity(global.p2_syntax_walrus := 42)
end
assert(walrus_global() == 42)
assert(global.p2_syntax_walrus == 42)

global.p2_syntax_list = [10, 11]
def walrus_index()
    return identity(global.p2_syntax_list[0] := 84)
end
assert(walrus_index() == 84)
assert(global.p2_syntax_list == [84, 11])

class WalrusMember
    var value
    def init()
        self.value = 21
    end
    def get()
        var out
        if (out := self.value) != nil
            return out
        end
    end
    def set_flag()
        if self.value := 42
            return self.value
        end
    end
end

var wm = WalrusMember()
assert(wm.get() == 21)
assert(wm.set_flag() == 42)

global.undef("p2_syntax_walrus")
global.undef("p2_syntax_list")

print("P2_SMOKE_PASS syntax")
