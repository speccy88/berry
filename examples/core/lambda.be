# simple lambda example
print("lambda result:", (/a b c-> a * b + c)(2, 3, 4))

# Y-Combinator and factorial functions
Y = /f-> (/x-> f(/n-> x(x)(n)))(/x-> f(/n-> x(x)(n)))
F = /f-> /x-> x ? f(x - 1) * x : 1
fact = Y(F)
print("fact(6):", fact(6))
print("lambda demo done")
