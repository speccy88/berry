print("P2_SMOKE_BEGIN compiler_parser")

class P2CompilerMemberA
    var a
end

var member_a = P2CompilerMemberA()
member_a.a = ["foo", "bar"]

var captured_member = nil
def capture_member(v)
    captured_member = v
end

class P2CompilerMemberB
    var b, i
    def nok()
        capture_member(self.b.a[self.i])
    end
    def ok()
        var i = self.i
        capture_member(self.b.a[i])
    end
end

var member_b = P2CompilerMemberB()
member_b.i = 0
member_b.b = member_a

member_b.nok()
assert(captured_member == "foo")

member_b.ok()
assert(captured_member == "foo")

def second_arg(a, b)
    return b
end

var items = [1, 2, 3, 4]
assert(second_arg(items[-1], items[-2]) == 3)

def slice_then_loop()
    var line = "1234567890"
    line = line[3..7]
    for n : 1..2 end
    return line
end

assert(slice_then_loop() == "45678")

def ternary_assignment_parse()
    if true
        var a = 1
        a = true ? a + 1 : a + 2
        return a
    end
end

assert(ternary_assignment_parse() == 2)

def nested_map_parse()
    var js = {"a": {"a": 1}}
    var value = js["a"]["a"]

    if value != nil
        for x : 0..1
            return x
        end
    end
end

assert(nested_map_parse() == 0)

def short_circuit_parser_shape()
    1 || assert(false)
end

short_circuit_parser_shape()

def call_argument_suffix_parse(flag)
    var rows = [[10, 20], [30, 40]]
    return second_arg(flag ? rows[0][0] : rows[0][1],
        flag ? rows[1][0] : rows[1][1])
end

assert(call_argument_suffix_parse(true) == 30)
assert(call_argument_suffix_parse(false) == 40)

def ternary_result_suffix_parse(flag)
    var rows = [[10, 20], [30, 40]]
    return (flag ? rows[0] : rows[1])[1]
end

assert(ternary_result_suffix_parse(true) == 20)
assert(ternary_result_suffix_parse(false) == 40)

def make_suffix_rows()
    return [[10, 20], [30, 40]]
end

def call_result_chained_suffix_parse()
    return make_suffix_rows()[1][0]
end

assert(call_result_chained_suffix_parse() == 30)

print("P2_SMOKE_PASS compiler_parser")
