# Host-executed safe standard-library coverage. No filesystem, bus, cog, or sleep calls.
def expect_error(code, kind)
    var caught = false
    try
        compile(code)
    except .. as e, m
        caught = true
        assert(e == kind)
    end
    assert(caught)
end

import string
assert(string.find("012345", "23") == 2)
assert(string.find("012345", "", 6) == 6)
assert(string.find("012345", "23", 3) == -1)
assert(string.count("121314", "1") == 3)
assert(string.count("012345", "") == 7)
assert(string.split("a b c d", " ", 2) == ["a", "b", "c d"])
assert(string.replace("hello", "ll", "") == "heo")
assert(string.startswith("qwerty", "QW", true))
assert(string.endswith("qwerty", "TY", true))
assert(string.format("%i%%%i", 12, 13) == "12%13")
print("LCV3_CASE string")

import time
var t0 = time.clock()
assert(type(t0) == "real" && t0 >= 0)
var epoch0 = time.dump(0)
assert(epoch0["epoch"] == 0 && epoch0["month"] >= 1 && epoch0["month"] <= 12)
assert(time.dump() == nil)
assert(time.dump("bad") == nil)
assert(type(time.time()) == "int")
print("LCV3_CASE time")

import global
assert(global.contains("LCV3_absent") == false)
global.LCV3_value = 42
assert(global.member("LCV3_value") == 42)
assert(global().find("LCV3_value") != nil)
global.undef("LCV3_value")
assert(!global.contains("LCV3_value"))
assert(global.contains(7) == nil)
print("LCV3_CASE global")

import sys
var p = sys.path()
var n = p.size()
assert(sys.path_add("/__lcv3_nonexistent__") == true)
assert(sys.path().size() == n + 1)
p = sys.path()
p.pop()
assert(sys.path().size() == n)
var sys_bad = false
try
    sys.path_add(7)
except "type_error"
    sys_bad = true
end
assert(sys_bad)
print("LCV3_CASE sys")

import introspect
assert(introspect.contains(string, "format"))
assert(!introspect.contains(string, "__lcv3_missing__"))
assert(introspect.get(string, "format") == string.format)
assert(introspect.get(string, "__lcv3_missing__") == nil)
assert(introspect.name(string) == "string")
assert(introspect.module("string") != nil)
assert(introspect.toptr(0) != nil)
assert(introspect.fromptr(0) == nil)
print("LCV3_CASE introspect")

import undefined
assert(type(undefined) == "module")
var undefined_error = false
try
    undefined.__lcv3_missing__
except "attribute_error"
    undefined_error = true
end
assert(undefined_error)
print("LCV3_CASE undefined")

import debug
assert(type(debug.calldepth()) == "int")
assert(debug.calldepth() >= 1)
assert(type(debug.top()) == "int")
assert(debug.caller(99999) == nil)
assert(debug.gcdebug() == false)
assert(debug.gcdebug(false) == false)
print("LCV3_CASE debug")

import strict
assert(strict == nil || type(strict) == "module")
expect_error("var a,b def f() a b end", "syntax_error")
expect_error("return LCV3_missing_global", "syntax_error")
print("LCV3_CASE strict")

print("LCV3_HOST_OK 8")
