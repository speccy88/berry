print("P2_SMOKE_BEGIN json_advanced")

import json

def assert_load(text, expected)
    var loaded = json.load(text)
    assert(loaded == expected)
end

def assert_load_failed(text)
    assert(json.load(text) == nil)
end

assert_load("1E2", 100.0)
assert_load("1E+2", 100.0)
assert_load("1.2e7", 12000000.0)
assert_load('"\\"\\\\\\/\\b\\f\\n\\r\\t"', "\"\\/\b\f\n\r\t")

assert_load('"\\u0048"', "H")
assert_load('"\\u00E9"', "é")
assert_load('"\\u0800"', "ࠀ")

var escaped_key = json.load('{"\\u006B\\u0065\\u0079":"value"}')
assert(escaped_key != nil)
assert(escaped_key["key"] == "value")

var escaped_array = json.load('["\\u0041","\\u00E9","\\u0800"]')
assert(escaped_array != nil)
assert(escaped_array == ["A", "é", "ࠀ"])

var many_unicode = '"'
for i : 0..19
    many_unicode += "\\u0800"
end
many_unicode += '"'

var expanded = json.load('{"test":' + many_unicode + '}')
assert(expanded != nil)
assert(size(expanded["test"]) == 60)

assert_load_failed('"\\uXXXX"')
assert_load_failed('"\\u12XY"')
assert_load_failed('"\\u"')
assert_load_failed('"\\u123"')
assert_load_failed('"\\u123G"')

assert_load_failed('{"test":"hello\x0Aworld"}')
assert_load_failed('{"test":"hello\x09world"}')
assert_load_failed('{"test":"hello\x0Dworld"}')
assert_load_failed('{"test":"hello\x01world"}')

var escaped_newline = json.load('{"test":"hello\\nworld"}')
assert(escaped_newline != nil)
assert(escaped_newline["test"] == "hello\nworld")

var escaped_tab = json.load('{"test":"hello\\tworld"}')
assert(escaped_tab != nil)
assert(escaped_tab["test"] == "hello\tworld")

assert_load_failed('"\\q"')
assert_load_failed('"\\x"')
assert_load_failed('"\\z"')
assert_load_failed('"\\"')

var long_str = '"'
for i : 0..127
    long_str += "a"
end
long_str += '"'

var long_result = json.load('{"test":' + long_str + '}')
assert(long_result != nil)
assert(size(long_result["test"]) == 128)

var mixed = json.load('{"message":"Hello \\u4E16\\u754C! Welcome to \\u0048\\u0065\\u006C\\u006C\\u006F world."}')
assert(mixed != nil)
assert(mixed["message"] == "Hello 世界! Welcome to Hello world.")

var nested = json.load('{"level0":{"unicode":"\\u0800\\u0801\\u0802","level1":{"unicode":"\\u0800\\u0801\\u0802","final":"\\u4E16\\u754C"}}}')
assert(nested != nil)
assert(size(nested["level0"]["unicode"]) == 9)
assert(size(nested["level0"]["level1"]["unicode"]) == 9)
assert(nested["level0"]["level1"]["final"] == "世界")

assert_load_failed('{"test":"unterminated')
assert_load_failed('{"test":"unterminated\\')
assert_load_failed('{"test":"valid"x}')
assert_load_failed('{"test":"\\uXXXX","other":"valid"}')

print("P2_SMOKE_PASS json_advanced")
