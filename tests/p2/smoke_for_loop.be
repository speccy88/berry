print("P2_SMOKE_BEGIN for_loop")

var total

total = 0
for i : 0 .. 10
    total += i
end
assert(total == 55)

total = 99
for i : 5 .. 0
    total = 0
end
assert(total == 99)

total = 0
for i : 0 .. 20
    if i > 10
        break
    end
    total += i
end
assert(total == 55)

total = 0
for i : 0 .. 20
    if i > 10
        continue
    end
    total += i
end
assert(total == 55)

assert(def ()
    for i : 0 .. 20
        if i > 10
            return i
        end
    end
end() == 11)

var list_loop = []
for value : [1, 2, 3, 4, 5]
    if value == 2
        continue
    end
    if value == 5
        break
    end
    list_loop.push(value * 10)
end
assert(list_loop == [10, 30, 40])

var nested = []
for outer : 0 .. 2
    for inner : 0 .. 4
        if inner == 1
            continue
        end
        if inner == 3
            break
        end
        nested.push([outer, inner])
    end
end
assert(nested == [[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]])

var outer_break = []
for outer : 0 .. 4
    if outer == 3
        break
    end
    for inner : 0 .. 1
        outer_break.push([outer, inner])
    end
end
assert(outer_break == [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]])

def for_rec(depth)
    for i : 0 .. 10
        if i == 4 && depth < 32
            for_rec(depth + 1)
        end
    end
end

for_rec(0)

print("P2_SMOKE_PASS for_loop")
