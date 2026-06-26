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

math.capabilities = def()
    var accel = math.accel_info()
    var nan_inf_supported = math.nan != math.nan && math.inf != 0
    return {
        "finite_fallbacks": true,
        "nan_inf": nan_inf_supported,
        "invalid_domain_nil": true,
        "non_number_zero": true,
        "deterministic_host_rand_zero": true,
        "p2_cordic_available": accel["cordic"],
        "cordic_backend": accel["backend"],
        "cordic_trig": accel["cordic"],
        "cordic_sqrt": false,
        "cordic_exp_log": false,
        "constants": true,
        "rounding": true,
        "minmax": true,
        "angle_conversion": true,
        "audit": true,
        "audit_policy": "finite_metadata_and_tiny_numeric_self_check"
    }
end

math.capability = def(name)
    if type(name) != "string"
        return nil
    end
    var caps = math.capabilities()
    if caps.contains(name)
        return caps[name]
    end
    return nil
end

math.required_capability_keys = def()
    return [
        "finite_fallbacks",
        "nan_inf",
        "invalid_domain_nil",
        "non_number_zero",
        "deterministic_host_rand_zero",
        "p2_cordic_available",
        "cordic_backend",
        "cordic_trig",
        "cordic_sqrt",
        "cordic_exp_log",
        "constants",
        "rounding",
        "minmax",
        "angle_conversion",
        "audit",
        "audit_policy"
    ]
end

math._near = def(a, b, tolerance)
    if !math._is_number(a) || !math._is_number(b)
        return false
    end
    return math.abs(a - b) <= tolerance
end

math.audit = def()
    var caps = math.capabilities()
    var accel = math.accel_info()
    var problems = []
    var missing_capability_keys = []

    for key : math.required_capability_keys()
        if !caps.contains(key)
            missing_capability_keys.push(key)
        end
    end
    if missing_capability_keys.size() != 0
        problems.push("missing_capability_keys")
    end

    if !caps["finite_fallbacks"]
        problems.push("finite_fallbacks_disabled")
    end
    if !caps["invalid_domain_nil"]
        problems.push("invalid_domain_nil_disabled")
    end
    if !caps["non_number_zero"]
        problems.push("non_number_zero_disabled")
    end
    if !caps["constants"]
        problems.push("constants_disabled")
    end
    if !caps["rounding"]
        problems.push("rounding_disabled")
    end
    if !caps["minmax"]
        problems.push("minmax_disabled")
    end
    if !caps["angle_conversion"]
        problems.push("angle_conversion_disabled")
    end
    if !caps["audit"]
        problems.push("audit_capability_disabled")
    end
    if caps["audit_policy"] != "finite_metadata_and_tiny_numeric_self_check"
        problems.push("audit_policy_mismatch")
    end
    if caps["p2_cordic_available"] != accel["cordic"]
        problems.push("cordic_capability_mismatch")
    end
    if caps["cordic_backend"] != accel["backend"]
        problems.push("cordic_backend_mismatch")
    end
    if caps["cordic_sqrt"] || caps["cordic_exp_log"]
        problems.push("unsupported_cordic_capability_claimed")
    end
    if math.capability("finite_fallbacks") != caps["finite_fallbacks"]
        problems.push("finite_fallback_lookup_mismatch")
    end
    if math.capability("missing") != nil
        problems.push("missing_lookup_not_nil")
    end
    if math.capability(nil) != nil
        problems.push("nil_lookup_not_nil")
    end
    if !math._near(math.pi, 3.1415927, 0.000001)
        problems.push("pi_constant_mismatch")
    end
    if !math._near(math.e, 2.7182818, 0.000001)
        problems.push("e_constant_mismatch")
    end
    if caps["nan_inf"] && !math.isnan(math.nan)
        problems.push("nan_check_failed")
    end
    if caps["nan_inf"] && !math.isinf(math.inf)
        problems.push("inf_check_failed")
    end
    if math.sqrt(49) != 7
        problems.push("sqrt_check_failed")
    end
    if math.sqrt(-1) != nil
        problems.push("sqrt_invalid_domain_not_nil")
    end
    if math.abs(-3) != 3 || math.abs("x") != 0
        problems.push("abs_check_failed")
    end
    if math.floor(3.7) != 3 || math.ceil(3.2) != 4
        problems.push("floor_ceil_check_failed")
    end
    if math.round(2.5) != 3 || math.round(-2.5) != -3
        problems.push("round_check_failed")
    end
    if math.min(3, 1, 2) != 1 || math.max(3, 1, 2) != 3
        problems.push("minmax_check_failed")
    end
    if math.pow(2, 3) != 8
        problems.push("pow_int_check_failed")
    end
    if !math._near(math.deg(math.pi), 180.0, 0.001)
        problems.push("deg_check_failed")
    end
    if !math._near(math.rad(180), math.pi, 0.001)
        problems.push("rad_check_failed")
    end
    if math.log(-1) != nil || math.asin(2) != nil || math.acos(2) != nil
        problems.push("invalid_domain_check_failed")
    end
    if math.sin("x") != 0 || math.log("x") != 0
        problems.push("non_number_zero_check_failed")
    end
    if math._p2 == nil && math.rand() != 0
        problems.push("host_rand_zero_check_failed")
    end

    return {
        "ok": problems.size() == 0,
        "problem_count": problems.size(),
        "problems": problems,
        "missing_capability_keys": missing_capability_keys,
        "audit_policy": caps["audit_policy"],
        "backend": accel["backend"],
        "cordic": accel["cordic"],
        "finite_fallbacks": caps["finite_fallbacks"],
        "nan_inf": caps["nan_inf"],
        "invalid_domain_nil": caps["invalid_domain_nil"],
        "non_number_zero": caps["non_number_zero"],
        "constants": caps["constants"],
        "rounding": caps["rounding"],
        "minmax": caps["minmax"],
        "angle_conversion": caps["angle_conversion"]
    }
end

math.audit_problems = def()
    return math.audit()["problems"]
end

math.audit_ok = def()
    return math.audit()["ok"]
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
