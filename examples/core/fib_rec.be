def fib(x)
    if x <= 2
        return 1
    end
    return fib(x - 1) + fib(x - 2)
end

var n = 10
print("fib:", n, fib(n))
print("fib recursion demo done")
