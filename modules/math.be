# P2 SD math helper.
#
# The Catalina/P2 native math module is kept out of the Hub image. This module
# covers the lightweight math surface used by the P2 smoke tests and common REPL
# checks; heavier transcendental functions can be added here as pure Berry code
# or backed by targeted P2/CORDIC helpers later.

var math = module("math")

math.pi = 3.1415927
math.imax = 2147483647
math.imin = -2147483647 - 1

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
    if type(y) == "int" && y > 0
        var out = 1
        var i = 0
        while i < y
            out *= x
            i += 1
        end
        return out
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
