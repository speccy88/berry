print("P2_SMOKE_BEGIN json")

import json

assert(type(json) == "module")

assert(type(json.load) == "function")
assert(type(json.dump) == "function")

def assert_load(text, expected)
    var loaded = json.load(text)
    assert(loaded == expected)
end

def assert_load_failed(text)
    assert(json.load(text) == nil)
end

assert_load("null", nil)
assert_load("true", true)
assert_load("false", false)
assert_load(" true ", true)
assert_load(" null ", nil)
assert_load("123", 123)
assert_load("-0.1", -0.1)
assert_load("1e2", 100.0)
assert_load("1e+2", 100.0)
assert_load("1e-2", 0.01)
assert_load('"abc"', "abc")
assert_load('"\\n\\t\\r\\\\\\""', "\n\t\r\\\"")
assert_load('"\\u0048\\u0065\\u006C\\u006C\\u006F"', "Hello")
assert_load("[]", [])
assert_load("{}", {})

assert_load_failed("")
assert_load_failed('"123')
assert_load_failed('"\\q"')
assert_load_failed('"\\u123"')
assert_load_failed('"\\u12XY"')
assert_load_failed("[x]")
assert_load_failed("[1, nil]")
assert_load_failed("[1, null")
assert_load_failed("true false")
assert_load_failed("[1]x")
assert_load_failed('{"key"}')
assert_load_failed('{"key": 1x}')
assert_load_failed('{"key": 1, }')

var obj = json.load('{"key":1,"arr":[2,3],"empty":"","flag":true,"none":null}')
assert(obj["key"] == 1)
assert(obj["arr"] == [2, 3])
assert(obj["empty"] == "")
assert(obj["flag"] == true)
assert(obj["none"] == nil)
assert(obj.size() == 5)

var nested = json.load('{"outer":{"inner":[{"v":42}]}}')
assert(nested["outer"]["inner"][0]["v"] == 42)

var spaced = json.load(' { "key" : 1 , "arr" : [ true , null ] } ')
assert(spaced != nil)
assert(spaced["key"] == 1)
assert(spaced["arr"][0] == true)
assert(spaced["arr"][1] == nil)
var spaced_array = json.load(' [ 1 , true , null , "x" ] ')
assert(spaced_array == [1, true, nil, "x"])

var unicode = json.load('{"u":"\\u0800\\u0801"}')
assert(unicode != nil)
assert(size(unicode["u"]) == 6)

assert(json.dump(nil) == "null")
assert(json.dump(true) == "true")
assert(json.dump(false) == "false")
assert(json.dump(1.23) == "1.23")
assert(json.dump("String") == '"String"')
assert(json.dump([]) == "[]")
assert(json.dump({}) == "{}")
assert(json.dump([1, "x"]) == '[1,"x"]')
assert(json.dump({1: "x"}) == '{"1":"x"}')
assert(json.dump([1, "x"], "format") == '[\n  1,\n  "x"\n]')
assert(json.dump({1: "x"}, "format") == '{\n  "1": "x"\n}')
assert(json.dump([1, [2]], "format") == '[\n  1,\n  [\n    2\n  ]\n]')

class p2_json_map : map
    def init()
        super(self).init()
    end
end
var custom = p2_json_map()
custom["key"] = 1
assert(json.dump(custom) == '{"key":1}')

var round = {"round": [1, "x", true, nil]}
var round_loaded = json.load(json.dump(round))
assert(round_loaded["round"][0] == 1)
assert(round_loaded["round"][1] == "x")
assert(round_loaded["round"][2] == true)
assert(round_loaded["round"][3] == nil)

print("P2_SMOKE_PASS json")
