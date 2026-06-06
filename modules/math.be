# P2 SD math helper.
#
# The Catalina/P2 native math module is kept out of the Hub image. This module
# covers the lightweight math surface used by the P2 smoke tests and common REPL
# checks; heavier transcendental functions can be added here as pure Berry code
# or backed by targeted P2/CORDIC helpers later.

var math = module("math")

math.pi = 3.1415927
math.e = 2.7182818
math.imax = 2147483647
math.imin = -2147483647 - 1
math._half_pi = math.pi / 2
math._two_pi = math.pi * 2
math._log10 = 2.3025851

math._is_number = def(x)
    var t = type(x)
    return t == "int" || t == "real"
end

math.abs = def(x)
    if !math._is_number(x)
        return 0
    end
    return x < 0 ? -x : x
end

math.floor = def(x)
    if !math._is_number(x)
        return 0
    end
    var i = int(x)
    return i > x ? i - 1 : i
end

math.ceil = def(x)
    if !math._is_number(x)
        return 0
    end
    var i = int(x)
    return i < x ? i + 1 : i
end

math.round = def(x)
    if !math._is_number(x)
        return 0
    end
    return x >= 0 ? math.floor(x + 0.5) : math.ceil(x - 0.5)
end

math.sqrt = def(x)
    if !math._is_number(x)
        return 0
    end
    if x < 0
        return nil
    end
    if x == 0
        return 0
    end

    var root = 0
    while root * root < x
        root += 1
    end
    if root * root == x
        return root
    end

    var low = root - 1
    var high = root
    var i = 0
    while i < 24
        var mid = (low + high) / 2
        if mid * mid > x
            high = mid
        else
            low = mid
        end
        i += 1
    end
    return (low + high) / 2
end

math._wrap_pi = def(x)
    while x > math.pi
        x -= math._two_pi
    end
    while x < -math.pi
        x += math._two_pi
    end
    return x
end

math._atan_series = def(x)
    var term = x
    var sum = x
    var x2 = x * x
    var sign = -1
    var n = 3
    while n < 51
        term *= x2
        sum += sign * term / n
        sign = -sign
        n += 2
    end
    return sum
end

math.exp = def(x)
    if !math._is_number(x)
        return 0
    end
    if x == 0
        return 1
    end
    if x < 0
        return 1 / math.exp(-x)
    end

    var parts = int(x / 0.5) + 1
    var y = x / parts
    var term = 1
    var sum = 1
    var i = 1
    while i < 24
        term = term * y / i
        sum += term
        i += 1
    end

    var out = 1
    i = 0
    while i < parts
        out *= sum
        i += 1
    end
    return out
end

math.log = def(x)
    if !math._is_number(x)
        return 0
    end
    if x <= 0
        return nil
    end

    var scale = 0
    while x > 1.5
        x /= math.e
        scale += 1
    end
    while x < 0.75
        x *= math.e
        scale -= 1
    end

    var y = (x - 1) / (x + 1)
    var y2 = y * y
    var term = y
    var sum = y
    var n = 3
    while n < 61
        term *= y2
        sum += term / n
        n += 2
    end
    return 2 * sum + scale
end

math.log10 = def(x)
    if !math._is_number(x)
        return 0
    end
    var v = math.log(x)
    return v == nil ? nil : v / math._log10
end

math.sin = def(x)
    if !math._is_number(x)
        return 0
    end
    x = math._wrap_pi(x)
    var term = x
    var sum = x
    var x2 = x * x
    var n = 3
    var sign = -1
    while n < 23
        term = term * x2 / ((n - 1) * n)
        sum += sign * term
        sign = -sign
        n += 2
    end
    return sum
end

math.cos = def(x)
    if !math._is_number(x)
        return 0
    end
    x = math._wrap_pi(x)
    var term = 1
    var sum = 1
    var x2 = x * x
    var n = 2
    var sign = -1
    while n < 24
        term = term * x2 / ((n - 1) * n)
        sum += sign * term
        sign = -sign
        n += 2
    end
    return sum
end

math.tan = def(x)
    if !math._is_number(x)
        return 0
    end
    var c = math.cos(x)
    return c == 0 ? nil : math.sin(x) / c
end

math.atan = def(x)
    if !math._is_number(x)
        return 0
    end
    if x == 0
        return 0
    end
    if x < 0
        return -math.atan(-x)
    end
    if x > 1
        return math._half_pi - math.atan(1 / x)
    end
    if x > 0.5
        var y = x / (1 + math.sqrt(1 + x * x))
        return 2 * math._atan_series(y)
    end
    return math._atan_series(x)
end

math.atan2 = def(y, x)
    if !math._is_number(y) || !math._is_number(x)
        return 0
    end
    if x > 0
        return math.atan(y / x)
    end
    if x < 0
        return y >= 0 ? math.atan(y / x) + math.pi : math.atan(y / x) - math.pi
    end
    if y > 0
        return math._half_pi
    end
    if y < 0
        return -math._half_pi
    end
    return 0
end

math.asin = def(x)
    if !math._is_number(x)
        return 0
    end
    if x > 1 || x < -1
        return nil
    end
    if x == 1
        return math._half_pi
    end
    if x == -1
        return -math._half_pi
    end
    return math.atan2(x, math.sqrt(1 - x * x))
end

math.acos = def(x)
    if !math._is_number(x)
        return 0
    end
    var v = math.asin(x)
    return v == nil ? nil : math._half_pi - v
end

math.sinh = def(x)
    if !math._is_number(x)
        return 0
    end
    return (math.exp(x) - math.exp(-x)) / 2
end

math.cosh = def(x)
    if !math._is_number(x)
        return 0
    end
    return (math.exp(x) + math.exp(-x)) / 2
end

math.tanh = def(x)
    if !math._is_number(x)
        return 0
    end
    var ep = math.exp(x)
    var en = math.exp(-x)
    return (ep - en) / (ep + en)
end

math._minmax = def(args, want_min)
    if args.size() == 0
        return nil
    end
    var best = args[0]
    if !math._is_number(best)
        raise "type_error", "arguments must be numbers"
    end
    var i = 1
    while i < args.size()
        var x = args[i]
        if !math._is_number(x)
            raise "type_error", "arguments must be numbers"
        end
        if want_min ? x < best : x > best
            best = x
        end
        i += 1
    end
    return best
end

math.min = def(*args)
    return math._minmax(args, true)
end

math.max = def(*args)
    return math._minmax(args, false)
end

math.pow = def(x, y)
    if !math._is_number(x) || !math._is_number(y)
        return 0
    end
    if y == 0
        return 1
    end
    if type(y) == "int"
        var out = 1
        var i = 0
        var n = y < 0 ? -y : y
        while i < n
            out *= x
            i += 1
        end
        return y < 0 ? 1 / out : out
    end
    if x > 0
        return math.exp(y * math.log(x))
    end
    return nil
end

math.deg = def(x)
    return math._is_number(x) ? x * 180 / math.pi : 0
end

math.rad = def(x)
    return math._is_number(x) ? x * math.pi / 180 : 0
end

math.isnan = def(x)
    return math._is_number(x) && x != x
end

math.isinf = def(x)
    return false
end

math.srand = def(seed) end

math.rand = def()
    import p2
    return p2.random()
end

return math
