print("P2_SMOKE_BEGIN stdlib")

def expect_syntax_error(code)
    var caught = false
    try
        compile(code)
    except .. as e, m
        caught = true
        assert(e == "syntax_error")
    end
    assert(caught)
end

import string

assert(string.find("012345", "23") == 2)
assert(string.find("012345", "", 6) == 6)
assert(string.find("012345", "23", 3) == -1)
assert(string.count("121314", "1") == 3)
assert(string.count("012345", "") == 7)
assert(string.split("a b c", " ") == ["a", "b", "c"])
assert(string.split("a b c d", " ", 2) == ["a", "b", "c d"])
assert(string.escape("A") == '"A"')
assert(string.escape("A", true) == "'A'")
assert(string.format("%i%%%i", 12, 13) == "12%13")
assert(string.format("%.1f", 3) == "3.0")
assert(string.replace("hello", "ll", "xx") == "hexxo")
assert(string.replace("hello", "ll", "") == "heo")
assert(string.tr("A_b", "_", " ") == "A b")
assert(string.tr("qwerty", "qwe", "_") == "_rty")
assert(string.startswith("qwerty", "qw"))
assert(string.startswith("qwerty", "QW", true))
assert(!string.startswith("qwerty", "qW"))
assert(!string.startswith("qwerty", "qz"))
assert(string.endswith("qwerty", "ty"))
assert(string.endswith("qwerty", "TY", true))
assert(!string.endswith("qwerty", "tY"))
assert(!string.endswith("qwerty", "tr"))
assert(format == string.format)
assert(format("%.1f", 3) == "3.0")
assert("aze" * 3 == "azeazeaze")
assert("aze" * 0 == "")
assert("hello" * -1 == "")
assert("x" * 1 == "x")

import json

assert(json.load("null") == nil)
assert(json.load("true") == true)
assert(json.load("false") == false)
assert(json.load("123") == 123)
assert(json.load("-0.1") == -0.1)
assert(json.load("1e2") == 100.0)
assert(json.load('"abc"') == "abc")
assert(json.load('"\\n"') == "\n")
assert(json.load("[1,null]") == [1, nil])
assert(json.load("[1, nil]") == nil)
var decoded = json.load('{"key":1,"arr":[2,3]}')
assert(decoded["key"] == 1)
assert(decoded["arr"][1] == 3)
var decoded_text = '{"key":1,"arr":[2,3]}'
var decoded_isolated = json.load(decoded_text)
decoded_isolated["key"] = 99
decoded_isolated["arr"][1] = 9
var decoded_again = json.load(decoded_text)
assert(decoded_again["key"] == 1)
assert(decoded_again["arr"][1] == 3)
assert(json.load('{"key": ""}')["key"] == "")
assert(json.load('{"key": 1, }') == nil)
assert(json.dump(nil) == "null")
assert(json.dump(true) == "true")
assert(json.dump([1, "x"]) == '[1,"x"]')
assert(json.dump({1: "x"}) == '{"1":"x"}')
assert(json.dump([1, "x"], "format") == '[\n  1,\n  "x"\n]')
var dump_source = {"round": [1, 2, 3]}
dump_source["round"][1] = 42
var dump_text = json.dump(dump_source)
assert(json.load(dump_text)["round"][1] == 42)
assert(dump_source["round"][1] == 42)
assert(json.load(json.dump({"round": [1, 2, 3]}))["round"][2] == 3)

import time

var clock0 = time.clock()
assert(type(clock0) == "real")
assert(clock0 >= 0)
var d = time.dump(1609459200)
assert(isinstance(d, map))
assert(d["year"] == 2021)
assert(d["month"] == 1)
assert(d["epoch"] == 1609459200)
assert(d.contains("hour"))
assert(d.contains("min"))
assert(d.contains("sec"))
assert(d.contains("day"))
assert(d.contains("weekday"))
assert(d["weekday"] >= 0 && d["weekday"] <= 6)
assert(time.dump() == nil)
assert(time.dump("hello") == nil)
assert(time.dump(3.14) == nil)
var d2 = time.dump(946684800)
assert(isinstance(d2, map))
assert(d2["year"] == 2000)
assert(d2["epoch"] == 946684800)
var d0 = time.dump(0)
assert(isinstance(d0, map))
assert(d0["epoch"] == 0)
assert(d0["weekday"] >= 0 && d0["weekday"] <= 6)
var d2_mutated = time.dump(946684800)
d2_mutated["year"] = 1999
assert(time.dump(946684800)["year"] == 2000)

import global

global.p2_stdlib_value = 42
assert(global.p2_stdlib_value == 42)
assert(global.contains("p2_stdlib_value"))
assert(global().find("p2_stdlib_value") != nil)
global.p2_stdlib_compile_value = 7
var compiled_global = compile("return p2_stdlib_compile_value + 35")
assert(compiled_global() == 42)
global.undef("p2_stdlib_value")
global.undef("p2_stdlib_compile_value")
assert(!global.contains("p2_stdlib_value"))
assert(!global.contains("p2_stdlib_compile_value"))

import solidify
assert(type(solidify.dump) == "function")
assert(type(solidify.compact) == "function")

import strict
assert(type(strict) == "module")
expect_syntax_error("var a,b def f() a b end")
expect_syntax_error("var a,b def f() a end")
expect_syntax_error("return p2_strict_missing_global")

print("P2_SMOKE_PASS stdlib")
