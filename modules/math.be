# P2 SD math helper.
#
# The Catalina/P2 native math module stays out of the core Hub image. This
# source module lives on SD and provides the math surface used by P2 smoke tests
# and REPL work. On Propeller 2 it opportunistically uses the native CORDIC
# helpers for trig/polar operations, with pure-Berry finite fallbacks for host
# and non-P2 use.

var math = module("math")

math.pi = 3.1415927
math.e = 2.7182818
math.nan = real("nan")
math.inf = real("inf")
math.imax = 2147483647
math.imin = -2147483647 - 1
math._half_pi = math.pi / 2.0
math._two_pi = math.pi * 2.0
math._log10 = 2.3025851
math._cordic_scale = 1000000
math._cordic_turn = 4294967296.0
math._p2 = nil
math._cordic = false

try
    import p2
    var _probe = p2.polxy(1, 0)
    if type(_probe) == "map"
        math._p2 = p2
        math._cordic = true
    end
except .. as e, m
    math._p2 = nil
    math._cordic = false
end

math._is_number = def(x)
    var t = type(x)
    return t == "int" || t == "real"
end

math._real = def(x)
    return x + 0.0
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

    x = math._real(x)
    var guess = x >= 1 ? x : 1.0
    var i = 0
    while i < 24
        guess = (guess + x / guess) / 2.0
        i += 1
    end
    return guess
end

math._wrap_pi = def(x)
    x = math._real(x)
    while x > math.pi
        x -= math._two_pi
    end
    while x < -math.pi
        x += math._two_pi
    end
    return x
end

math._cordic_angle = def(x)
    x = math._wrap_pi(x)
    if x >= math.pi
        return math.imin
    end
    return int((x / math._two_pi) * math._cordic_turn)
end

math._cordic_to_rad = def(t)
    var v = math._real(t)
    if v < 0
        v += math._cordic_turn
    end
    var a = (v / math._cordic_turn) * math._two_pi
    if a > math.pi
        a -= math._two_pi
    end
    return a
end

math._atan_series = def(x)
    x = math._real(x)
    var term = x
    var sum = x
    var x2 = x * x
    var sign = -1.0
    var n = 3
    while n < 51
        term *= x2
        sum += sign * term / math._real(n)
        sign = -sign
        n += 2
    end
    return sum
end

math.accel_info = def()
    return {
        "p2": math._p2 != nil,
        "cordic": math._cordic,
        "backend": math._cordic ? "p2_cordic" : "berry_fallback",
        "scale": math._cordic_scale,
        "turn": math._cordic_turn,
        "sin": math._cordic,
        "cos": math._cordic,
        "tan": math._cordic,
        "atan2": math._cordic,
        "asin": math._cordic,
        "acos": math._cordic,
        "sqrt": false,
        "exp": false,
        "log": false,
        "reason": math._cordic
            ? "P2 CORDIC is used for compatible scaled trig/polar operations"
            : "P2 CORDIC API unavailable; using pure Berry finite fallbacks"
    }
end

math.exp = def(x)
    if !math._is_number(x)
        return 0
    end
    if x == 0
        return 1
    end
    x = math._real(x)
    if x < 0
        return 1.0 / math.exp(-x)
    end

    var parts = int(x / 0.5) + 1
    var y = x / math._real(parts)
    var term = 1.0
    var sum = 1.0
    var i = 1
    while i < 28
        term = term * y / math._real(i)
        sum += term
        i += 1
    end

    var out = 1.0
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

    x = math._real(x)
    var scale = 0
    while x > 1.5
        x /= math.e
        scale += 1
    end
    while x < 0.75
        x *= math.e
        scale -= 1
    end

    var y = (x - 1.0) / (x + 1.0)
    var y2 = y * y
    var term = y
    var sum = y
    var n = 3
    while n < 81
        term *= y2
        sum += term / math._real(n)
        n += 2
    end
    return 2.0 * sum + math._real(scale)
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
    if math._cordic
        var p = math._p2.polxy(math._cordic_scale, math._cordic_angle(x))
        return math._real(p["y"]) / math._real(math._cordic_scale)
    end

    x = math._wrap_pi(x)
    var term = x
    var sum = x
    var x2 = x * x
    var n = 3
    var sign = -1.0
    while n < 25
        term = term * x2 / math._real((n - 1) * n)
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
    if math._cordic
        var p = math._p2.polxy(math._cordic_scale, math._cordic_angle(x))
        return math._real(p["x"]) / math._real(math._cordic_scale)
    end

    x = math._wrap_pi(x)
    var term = 1.0
    var sum = 1.0
    var x2 = x * x
    var n = 2
    var sign = -1.0
    while n < 26
        term = term * x2 / math._real((n - 1) * n)
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
    x = math._real(x)
    if x == 0
        return 0
    end
    if x < 0
        return -math.atan(-x)
    end
    if x > 1
        return math._half_pi - math.atan(1.0 / x)
    end
    if x > 0.5
        var y = x / (1.0 + math.sqrt(1.0 + x * x))
        return 2.0 * math._atan_series(y)
    end
    return math._atan_series(x)
end

math.atan2 = def(y, x)
    if !math._is_number(y) || !math._is_number(x)
        return 0
    end
    if x == 0 && y == 0
        return 0
    end
    if math._cordic
        var ax = math.abs(x)
        var ay = math.abs(y)
        var div = ax > ay ? ax : ay
        var xi = int((math._real(x) / math._real(div)) * math._cordic_scale)
        var yi = int((math._real(y) / math._real(div)) * math._cordic_scale)
        var p = math._p2.xypol(xi, yi)
        return math._cordic_to_rad(p["t"])
    end
    x = math._real(x)
    y = math._real(y)
    if x > 0
        return math.atan(y / x)
    end
    if x < 0
        return y >= 0 ? math.atan(y / x) + math.pi : math.atan(y / x) - math.pi
    end
    return y > 0 ? math._half_pi : -math._half_pi
end

math.asin = def(x)
    if !math._is_number(x)
        return 0
    end
    x = math._real(x)
    if x > 1 || x < -1
        return nil
    end
    if x == 1
        return math._half_pi
    end
    if x == -1
        return -math._half_pi
    end
    return math.atan2(x, math.sqrt(1.0 - x * x))
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
    return (math.exp(x) - math.exp(-x)) / 2.0
end

math.cosh = def(x)
    if !math._is_number(x)
        return 0
    end
    return (math.exp(x) + math.exp(-x)) / 2.0
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
        var out = 1.0
        var i = 0
        var n = y < 0 ? -y : y
        while i < n
            out *= x
            i += 1
        end
        return y < 0 ? 1.0 / out : out
    end
    if x > 0
        return math.exp(math._real(y) * math.log(x))
    end
    return nil
end

math.deg = def(x)
    return math._is_number(x) ? math._real(x) * 180.0 / math.pi : 0
end

math.rad = def(x)
    return math._is_number(x) ? math._real(x) * math.pi / 180.0 : 0
end

math.isnan = def(x)
    return math._is_number(x) && x != x
end

math.isinf = def(x)
    if !math._is_number(x) || !math._is_number(math.inf)
        return false
    end
    return x == math.inf || x == -math.inf
end

math.srand = def(seed) end

math.rand = def()
    if math._p2 != nil
        return math._p2.random()
    end
    return 0
end

return math
