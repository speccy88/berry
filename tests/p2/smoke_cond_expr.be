print("P2_SMOKE_BEGIN cond_expr")

def boom()
    raise "p2_cond_expr_error", "unselected branch executed"
end

var side_effects = 0
def mark(v)
    side_effects += v
    return v
end

var condition_checks = 0
def check_condition(v)
    condition_checks += 1
    return v
end

assert((true ? 1 : 2) == 1)
assert((false ? 1 : 2) == 2)
assert((nil ? 1 : 2) == 2)
assert((0 ? "truthy" : "falsey") == "truthy")
assert(("" ? "truthy" : "falsey") == "truthy")
assert(([] ? "truthy" : "falsey") == "falsey")
assert(([1] ? "truthy" : "falsey") == "truthy")
assert(({} ? "truthy" : "falsey") == "falsey")
assert(({"k": 1} ? "truthy" : "falsey") == "truthy")

var a = 3
var b = 7
assert((a < b ? "lt" : "ge") == "lt")
assert((a > b ? "gt" : "le") == "le")
assert((a == 3 ? b == 7 ? 42 : 0 : -1) == 42)
assert(((a == 4 ? b : a) + 39) == 42)

assert((true ? 42 : boom()) == 42)
assert((false ? boom() : 42) == 42)
assert((true ? mark(2) : mark(100)) == 2)
assert(side_effects == 2)
assert((false ? mark(100) : mark(3)) == 3)
assert(side_effects == 5)
assert((check_condition([]) ? boom() : "empty-list") == "empty-list")
assert(condition_checks == 1)
assert((check_condition([1]) ? "non-empty-list" : boom()) == "non-empty-list")
assert(condition_checks == 2)

var selected = false
if a < b ? true : false
    selected = true
end
assert(selected)

var m = {"name": "berry", "count": 2}
assert((m.contains("name") ? m["name"] : "missing") == "berry")
assert((m.contains("missing") ? m["missing"] : "fallback") == "fallback")

var l = []
for i : 0..5
    l.push(i % 2 == 0 ? i : -i)
end
assert(l == [0, -1, 2, -3, 4, -5])

print("P2_SMOKE_PASS cond_expr")
