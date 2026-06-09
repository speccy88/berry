print("P2_SMOKE_BEGIN assignment")

class P2AssignBox
    var a
end

var o = P2AssignBox()
o.a = 100
assert(o.a == 100)
o.a += 10
assert(o.a == 110)

var p = P2AssignBox()
p.a = P2AssignBox()
p.a.a = 50
assert(p.a.a == 50)
p.a.a += 10
assert(p.a.a == 60)

def assignment_func()
    var local_o = P2AssignBox()
    local_o.a = 100
    assert(local_o.a == 100)
    local_o.a += 10
    assert(local_o.a == 110)

    var local_p = P2AssignBox()
    local_p.a = P2AssignBox()
    local_p.a.a = 50
    assert(local_p.a.a == 50)
    local_p.a.a += 10
    assert(local_p.a.a == 60)
end

assignment_func()

var m = {"child": P2AssignBox()}
m["child"].a = P2AssignBox()
m["child"].a.a = 21
m["child"].a.a *= 2
assert(m["child"].a.a == 42)
var child_key = "child"
var inner_field = "a"
m[child_key].(inner_field).(inner_field) = 40
m[child_key].(inner_field).(inner_field) += 2
assert(m["child"].a.a == 42)
m["other"] = P2AssignBox()
m["other"].a = P2AssignBox()
m["other"].a.a = 7
child_key = "other"
m[child_key].(inner_field).(inner_field) = 11
assert(m["other"].a.a == 11)
assert(m["child"].a.a == 42)

var field_name = "a"
var q = P2AssignBox()
q.(field_name) = P2AssignBox()
q.(field_name).(field_name) = 40
q.a.(field_name) += 2
assert(q.a.a == 42)
assert(q.(field_name).(field_name) == 42)

print("P2_SMOKE_PASS assignment")
