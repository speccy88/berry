# Regression: escape readers must not consume stale lexer-buffer bytes.
import json

var truncated = [
    "\\u",
    "\\u1",
    "\\u22",
    "\\u333",
    "\\x",
    "\\x1",
    "\\1",
    "\\11",
]
for escape : truncated
    var rejected = false
    try
        # Seed the same lexer buffer with valid digits beyond the next token.
        compile('return "12345678" + "' + escape + '"')
    except "syntax_error" as error, message
        rejected = true
    end
    assert(rejected, "accepted truncated escape: " + escape)
end

# Unicode scalar boundaries must use the shortest valid UTF-8 encoding.
var unicode_cases = [
    ["\\u0000", "00"],
    ["\\u007E", "7E"],
    ["\\u007F", "7F"],
    ["\\u0080", "C280"],
    ["\\u07FE", "DFBE"],
    ["\\u07FF", "DFBF"],
    ["\\u0800", "E0A080"],
    ["\\uFFFF", "EFBFBF"],
]
for case : unicode_cases
    var quoted = '"' + case[0] + '"'
    var literal = compile("return " + quoted)()
    assert(bytes().fromstring(literal).tohex() == case[1])
    assert(bytes().fromstring(json.load(quoted)).tohex() == case[1])
end
