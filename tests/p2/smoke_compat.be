print("P2_SMOKE_BEGIN compat")

print("P2_COMPAT_PRINT_OK")
assert(true)
assert(type(nil) == "nil")
assert(type(true) == "bool")
assert(type(42) == "int")
assert(type(42.5) == "real")
assert(type("berry") == "string")

class CompatBase
    var base_value
    def init(v)
        self.base_value = v
    end
    def value()
        return self.base_value
    end
end

class CompatChild : CompatBase
    var child_value
    def init(a, b)
        super(self).init(a)
        self.child_value = b
    end
    def total()
        return self.value() + self.child_value
    end
end

var child = CompatChild(19, 23)
assert(child.total() == 42)
assert(classname(child) == "CompatChild")
assert(classof(child) == CompatChild)
assert(classof(super(child)) == CompatBase)
assert(super(super(child)) == nil)
assert(issubclass(CompatChild, CompatBase))
assert(!issubclass(CompatBase, CompatChild))
assert(isinstance(child, CompatChild))
assert(isinstance(child, CompatBase))
assert(!isinstance(child, map))

assert(str(42) == "42")
assert(number("42") == 42)
assert(type(number("3.5")) == "real")
assert(int("0x2a") == 42)
assert(int(true) == 1)
assert(real("42.5") == 42.5)
assert(real(42) == 42.0)
assert(bool() == false)
assert(bool(0) == false)
assert(bool(1) == true)
assert(bool("") == false)
assert(bool("x") == true)
assert(type(child) == "instance")
assert(type(CompatChild) == "class")
assert(size("berry") == 5)
assert(size([1, 2, 3]) == 3)
assert(size({"a": 1, "b": 2}) == 2)

var l = list()
l.push(1)
l.push(2)
assert(l == [1, 2])
assert(isinstance(l, list))
assert(size(l) == 2)
assert(l[0] == 1)
assert(l[1] == 2)
l.insert(1, 9)
assert(l == [1, 9, 2])
assert(l.remove(1) == 9)
assert(l == [1, 2])
l.push(3)
l.push(4)
assert(l.find(3) == 2)
assert(l.find(99) == nil)
assert(l.pop() == 4)
assert(l == [1, 2, 3])

var m = map()
m["a"] = 20
m["b"] = 22
assert(m["a"] + m["b"] == 42)
assert(isinstance(m, map))
assert(size(m) == 2)
assert(m.contains("a"))
assert(!m.contains("z"))
m["c"] = 1
assert(m["a"] + m["b"] + m["c"] == 43)
assert(m.remove("c") == 1)
assert(!m.contains("c"))
assert(m.find("a") == 20)
assert(m.find("missing") == nil)
var key_count = 0
for k : m.keys()
    if k == "a" || k == "b"
        key_count += 1
    end
end
assert(key_count == 2)
var compat_values = m.values()
assert(compat_values.find(20) != nil)
assert(compat_values.find(22) != nil)

var rtotal = 0
for i : range(1, 6)
    rtotal += i
end
assert(rtotal == 15)
var rtotal2 = 0
for i : range(0, 5, 2)
    rtotal2 += i
end
assert(rtotal2 == 6)
var rtotal3 = 0
for i : range(5, 0, -2)
    rtotal3 += i
end
assert(rtotal3 == 9)
var literal_range_total = 0
for i : 0..3
    literal_range_total += i
end
assert(literal_range_total == 6)

var by = bytes().fromstring("AB")
assert(by.tohex() == "4142")
assert(by.asstring() == "AB")
assert(size(by) == 2)
assert(bytes("1122").tohex() == "1122")
assert(bytes("1122")[0] == 0x11)
assert(bytes("1122")[1] == 0x22)
assert(str(bytes()) == "bytes('')")
assert(str(bytes("1122AAaaBBbb")) == "bytes('1122AAAABBBB')")
assert(bytes("1122AAaaBBbb").size() == 6)
var by_add = bytes()
by_add.add(0x12345678, 1)
by_add.add(0x12345678, 2)
assert(str(by_add) == "bytes('787856')")
assert(bytes("000102030405").get(1, 2) == 0x0201)
assert(bytes("000102030405").get(1, -2) == 0x0102)
assert(bytes("000102030405").get(1000, 1) == 0)
var by_resize = bytes("112233")
by_resize.resize(2)
assert(str(by_resize) == "bytes('1122')")
by_resize.resize(4)
assert(str(by_resize) == "bytes('11220000')")
var by_copy = by_resize.copy()
by_copy.clear()
assert(str(by_resize) == "bytes('11220000')")
assert(str(by_copy) == "bytes('')")
var by_append = bytes("1122")
assert(str(by_append.append(bytes("334455"))) == "bytes('1122334455')")
assert(str(by_append) == "bytes('1122334455')")
assert(str(bytes("AA") + "01") == "bytes('AA3031')")
var by_item = bytes("334455")
assert(by_item[-1] == 0x55)
assert(str(by_item[0..1]) == "bytes('3344')")
by_item[1] = 0xAA
assert(str(by_item) == "bytes('33AA55')")

var compiled = compile("return 21 + 21")
assert(type(compiled) == "function")
assert(compiled() == 42)

var p2_closure_capture
def p2_make_capture()
    var captured = "p2-captured"
    def inner()
        return captured
    end
    p2_closure_capture = inner
    return 42
end
assert(p2_make_capture() == 42)
assert(p2_closure_capture() == "p2-captured")

var p2_loop_closures = []
def p2_capture_loop()
    var start = 100
    for i : 1..3
        p2_loop_closures.push(def () return [i, start] end)
    end
end
p2_capture_loop()
assert(p2_loop_closures[0]() == [1, 100])
assert(p2_loop_closures[1]() == [2, 100])
assert(p2_loop_closures[2]() == [3, 100])

var break_total = 0
for i : 0..20
    if i > 10
        break
    end
    break_total += i
end
assert(break_total == 55)

var continue_total = 0
for i : 0..20
    if i > 10
        continue
    end
    continue_total += i
end
assert(continue_total == 55)

def add3(a, b, c)
    return [a, b, c]
end
assert(call(add3, 1, [2, 3]) == [1, 2, 3])
assert(call(add3) == [nil, nil, nil])
assert(call(add3, [1, 2, 3, 4]) == [1, 2, 3])
assert(call(add3, 1, [2, 3, 4], "x") == [1, [2, 3, 4], "x"])

def p2_varargs(a, *b)
    return [a, b]
end
assert(p2_varargs() == [nil, []])
assert(p2_varargs(1) == [1, []])
assert(p2_varargs(1, 2, 3) == [1, [2, 3]])
assert(call(p2_varargs, 1, [2, 3]) == [1, [2, 3]])

def p2_varargs_only(*a)
    return a
end
assert(p2_varargs_only() == [])
assert(p2_varargs_only("foo", nil, 2) == ["foo", nil, 2])
assert(call(p2_varargs_only, 1, [2, 3], "x") == [1, [2, 3], "x"])

var compat_mod = module("p2_compat_smoke")
compat_mod.answer = 42
assert(type(compat_mod) == "module")
assert(compat_mod.answer == 42)

import introspect
assert(introspect.name(compat_mod) == "p2_compat_smoke")
assert(type(introspect.toptr(0)) == "ptr")
assert(introspect.contains(compat_mod, "answer"))
assert(introspect.get(compat_mod, "answer") == 42)
introspect.set(compat_mod, "answer", 84)
assert(compat_mod.answer == 84)
assert(introspect.get(compat_mod, "answer") == 84)
assert(introspect.name(introspect.module("json")) == "json")
assert(introspect.module("p2_no_such_module") == nil)
var compat_members = introspect.members(compat_mod)
assert(isinstance(compat_members, list))
var compat_member_seen = false
for name: compat_members
    if name == "answer"
        compat_member_seen = true
    end
end
assert(compat_member_seen)
def compat_function() return 1 end
assert(type(introspect.toptr(compat_function)) == "ptr")
assert(introspect.fromptr(0) == nil)
assert(introspect.solidified(compat_function) == false)
assert(introspect.ismethod(compat_function) == false)
assert(introspect.get(compat_mod, "missing", true) == true)

import global
global.p2_compat_value = 42
assert(global.p2_compat_value == 42)
assert(global.contains("p2_compat_value"))
global.undef("p2_compat_value")
assert(!global.contains("p2_compat_value"))

import time
assert(type(time) == "module")

import solidify
assert(type(solidify) == "module")
assert(type(solidify.dump) == "function")
assert(type(solidify.compact) == "function")

import strict
assert(type(strict) == "module")

print("P2_SMOKE_PASS compat")
