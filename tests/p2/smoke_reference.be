print("P2_SMOKE_BEGIN reference")

class P2FailableString
    var fail
    def tostring()
        if self.fail
            raise "internal_error", "FAIL"
        end
        return "SUCCESS"
    end
end

var item = P2FailableString()
var l1 = [1, 2, item]
var l2 = ["foo", l1]
l1.push(l1)

assert(str(l2) == "['foo', [1, 2, SUCCESS, [...]]]")
assert(str(l1) == "[1, 2, SUCCESS, [...]]")

var shared_child = ["shared"]
var shared_parent = [shared_child, shared_child]
assert(str(shared_parent) == "[['shared'], ['shared']]")

var m1 = {"item": item}
m1["self"] = m1
assert(str(m1).contains("'item': SUCCESS"))
assert(str(m1).contains("'self': {...}"))

item.fail = true
var caught = false
try
    var rendered = str(l1)
except .. as e, m
    caught = true
    assert(e == "internal_error")
end
assert(caught)

item.fail = false
assert(str(l1) == "[1, 2, SUCCESS, [...]]")
assert(str(l2) == "['foo', [1, 2, SUCCESS, [...]]]")
assert(str(m1).contains("'item': SUCCESS"))
assert(str(m1).contains("'self': {...}"))

print("P2_SMOKE_PASS reference")
