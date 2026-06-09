print("P2_SMOKE_BEGIN json_stack")

import json

var object_text = "{"
for i : 0..127
    if i > 0
        object_text += ","
    end
    object_text += "\"k" + str(i) + "\":\"v" + str(i) + "\""
end
object_text += "}"

var parsed = json.load(object_text)
assert(parsed != nil)
assert(parsed.size() == 128)
assert(parsed["k0"] == "v0")
assert(parsed["k42"] == "v42")
assert(parsed["k127"] == "v127")

var wrapped_object = json.load("{\"payload\":" + object_text + ",\"last\":\"ok\"}")
assert(wrapped_object != nil)
assert(wrapped_object["payload"].size() == 128)
assert(wrapped_object["payload"]["k127"] == "v127")
assert(wrapped_object["last"] == "ok")

var nested_text = "["
for i : 0..31
    if i > 0
        nested_text += ","
    end
    nested_text += "{\"i\":" + str(i) + ",\"v\":[\"" + str(i) + "\"]}"
end
nested_text += "]"

var nested = json.load(nested_text)
assert(nested != nil)
assert(nested.size() == 32)
assert(nested[0]["i"] == 0)
assert(nested[0]["v"][0] == "0")
assert(nested[31]["i"] == 31)
assert(nested[31]["v"][0] == "31")

var matrix_text = "["
for row : 0..7
    if row > 0
        matrix_text += ","
    end
    matrix_text += "["
    for col : 0..7
        if col > 0
            matrix_text += ","
        end
        matrix_text += str(row * 10 + col)
    end
    matrix_text += "]"
end
matrix_text += "]"

var matrix = json.load(matrix_text)
assert(matrix != nil)
assert(matrix.size() == 8)
assert(matrix[0].size() == 8)
assert(matrix[0][0] == 0)
assert(matrix[3][4] == 34)
assert(matrix[7][7] == 77)

var mixed = json.load("{\"items\":" + nested_text + ",\"count\":32}")
assert(mixed != nil)
assert(mixed["count"] == 32)
assert(mixed["items"].size() == 32)
assert(mixed["items"][15]["i"] == 15)
assert(mixed["items"][15]["v"][0] == "15")

print("P2_SMOKE_PASS json_stack")
