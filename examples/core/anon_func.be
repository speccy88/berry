# anonymous function and closure
def count(x)
    var arr = []
    var i = 0
    while i <= x
        arr.push(
            def (n) # loop variable cannot be used directly as free variable
                return def ()
                    return n * n
                end
            end(i) # define and call anonymous function
        )
        i += 1
    end
    return arr
end

var closures = count(6)
var i = 0
while i < closures.size()
    print("closure square:", i, closures[i]()) # 0, 1, 4 ... n * n
    i += 1
end

print("anonymous closure demo done")
