print("P2_SMOKE_BEGIN suffix")

var keys = ["key1", "key2", "key3", "key4"]
var pairs = {
    keys[0]: "value1",
    keys[1]: "value2",
    keys[2]: "value3",
    keys[3]: "value4"
}

for i : 0..keys.size() - 1
    assert(pairs[keys[i]] == "value" .. i + 1)
end

var values = []
for i : 1..5
    values..i
end
assert(values == [1, 2, 3, 4, 5])

var nested = []
nested..["a", "b"]
nested..["c"]
assert(nested == [["a", "b"], ["c"]])

class P2SuffixBox
    var l
    def init()
        self.l = []
    end
    def with_values(a, b)
        self.l = [a, b]
        return self
    end
    def values()
        return self.l
    end
end

var box = P2SuffixBox()
box.l = [0, 1, 2]

def slice_member()
    return box.l[0..1]
end

def slice_via_local()
    var local = box.l
    return local[0..1]
end

var suffix_index = 0
def indexed_member()
    return box.l[suffix_index]
end

def indexed_literal()
    return box.l[0]
end

assert(slice_member() == [0, 1])
assert(slice_via_local() == [0, 1])
assert(indexed_member() == 0)
assert(indexed_literal() == 0)

var chained = P2SuffixBox().with_values(41, 42)
assert(chained.values()[1] == 42)
assert(P2SuffixBox().with_values(5, 6).values()[0] == 5)
assert(P2SuffixBox().with_values(9, 10).values()[-1] == 10)
assert(P2SuffixBox().with_values(7, 8).values()[0..1] == [7, 8])

print("P2_SMOKE_PASS suffix")
