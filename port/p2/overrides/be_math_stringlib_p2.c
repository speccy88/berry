#include "berry.h"
#include "be_module.h"
#include "be_string.h"

#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <propeller2.h>

static void p2_module_set_func(bvm *vm, const char *name, bntvfunc func)
{
    be_pushntvfunction(vm, func);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void p2_module_set_int(bvm *vm, const char *name, bint value)
{
    be_pushint(vm, value);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static void p2_module_set_real(bvm *vm, const char *name, breal value)
{
    be_pushreal(vm, value);
    be_setmember(vm, -2, name);
    be_pop(vm, 1);
}

static const char *p2_find_bounded(const char *s, size_t slen, const char *p, size_t plen)
{
    size_t i, j;
    if (plen == 0) {
        return s;
    }
    if (plen > slen) {
        return NULL;
    }
    for (i = 0; i <= slen - plen; ++i) {
        if (s[i] != p[0]) {
            continue;
        }
        for (j = 1; j < plen; ++j) {
            if (s[i + j] != p[j]) {
                break;
            }
        }
        if (j == plen) {
            return s + i;
        }
    }
    return NULL;
}

static int p2_math_nil(bvm *vm)
{
    be_pushnil(vm);
    be_return(vm);
}

static const breal P2_MATH_PI = (breal)3.1415926535897932384626433832795;
static const breal P2_MATH_TWO_PI = (breal)6.283185307179586476925286766559;
static const breal P2_MATH_HALF_PI = (breal)1.5707963267948966192313216916398;
static const breal P2_MATH_E = (breal)2.7182818284590452353602874713527;
static const breal P2_MATH_LN2 = (breal)0.69314718055994530941723212145818;
static const breal P2_MATH_LN10 = (breal)2.3025850929940456840179914546844;
static const breal P2_MATH_TURN = (breal)4294967296.0;
static const breal P2_MATH_NAN_SENTINEL = (breal)-1234567.0;
static const int32_t P2_MATH_CORDIC_SCALE = 1000000;

static bint p2_math_rand_state = 1357911;

static int p2_math_arg_real(bvm *vm, int idx, breal *out)
{
    if (idx <= be_top(vm)) {
        if (be_isint(vm, idx)) {
            *out = (breal)be_toint(vm, idx);
            return 1;
        }
        if (be_isreal(vm, idx)) {
            *out = be_toreal(vm, idx);
            return 1;
        }
    }
    return 0;
}

static breal p2_math_abs_real(breal x)
{
    return x < (breal)0.0 ? -x : x;
}

static int p2_math_is_nan_value(breal x)
{
    union {
        breal f;
        uint32_t u;
    } v;
    if (x != x || (x > P2_MATH_NAN_SENTINEL - (breal)0.5 && x < P2_MATH_NAN_SENTINEL + (breal)0.5)) {
        return 1;
    }
    v.f = x;
    return (v.u & 0x7FFFFFFFUL) > 0x7F800000UL;
}

static int p2_math_is_inf_value(breal x)
{
    union {
        breal f;
        uint32_t u;
    } v;
    v.f = x;
    return (v.u & 0x7FFFFFFFUL) == 0x7F800000UL;
}

static breal p2_math_inf_value(void)
{
    union {
        uint32_t u;
        breal f;
    } v;
    v.u = 0x7F800000UL;
    return v.f;
}

static breal p2_math_nan_value(void)
{
    return P2_MATH_NAN_SENTINEL;
}

static bint p2_math_floor_int(breal x)
{
    bint i = (bint)x;
    if ((breal)i > x) {
        --i;
    }
    return i;
}

static bint p2_math_ceil_int(breal x)
{
    bint i = (bint)x;
    if ((breal)i < x) {
        ++i;
    }
    return i;
}

static bint p2_math_round_int(breal x)
{
    return x >= (breal)0.0 ? p2_math_floor_int(x + (breal)0.5) : p2_math_ceil_int(x - (breal)0.5);
}

static uint32_t p2_math_rad_to_turn(breal rad)
{
    while (rad >= P2_MATH_PI) {
        rad -= P2_MATH_TWO_PI;
    }
    while (rad < -P2_MATH_PI) {
        rad += P2_MATH_TWO_PI;
    }
    return (uint32_t)((int32_t)(rad * (P2_MATH_TURN / P2_MATH_TWO_PI)));
}

static breal p2_math_turn_to_rad(uint32_t turn)
{
    return (breal)((int32_t)turn) * (P2_MATH_TWO_PI / P2_MATH_TURN);
}

static unsigned long p2_math_isqrt_ulong(unsigned long x)
{
    unsigned long op = x;
    unsigned long res = 0;
    unsigned long bit = 1UL << 30;
    while (bit > op) {
        bit >>= 2;
    }
    while (bit != 0) {
        if (op >= res + bit) {
            op -= res + bit;
            res = (res >> 1) + bit;
        } else {
            res >>= 1;
        }
        bit >>= 2;
    }
    return res;
}

static breal p2_math_sqrt_real(breal x)
{
    breal g;
    int i;
    if (x < (breal)0.0) {
        return p2_math_nan_value();
    }
    if (x == (breal)0.0 || x == (breal)1.0) {
        return x;
    }
    g = x > (breal)1.0 ? x : (breal)1.0;
    for (i = 0; i < 18; ++i) {
        g = (g + x / g) * (breal)0.5;
    }
    return g;
}

static breal p2_math_exp_impl(breal x)
{
    int n, i;
    breal r, term, sum, scale;
    if (x > (breal)80.0) {
        return p2_math_inf_value();
    }
    if (x < (breal)-80.0) {
        return (breal)0.0;
    }
    n = (int)p2_math_round_int(x / P2_MATH_LN2);
    r = x - (breal)n * P2_MATH_LN2;
    term = (breal)1.0;
    sum = (breal)1.0;
    for (i = 1; i <= 18; ++i) {
        term *= r / (breal)i;
        sum += term;
    }
    scale = (breal)1.0;
    if (n >= 0) {
        while (n-- > 0) {
            scale *= (breal)2.0;
        }
        return sum * scale;
    }
    while (n++ < 0) {
        scale *= (breal)0.5;
    }
    return sum * scale;
}

static breal p2_math_log_impl(breal x)
{
    int n = 0;
    int i;
    breal y, y2, term, sum;
    if (x <= (breal)0.0) {
        return p2_math_nan_value();
    }
    while (x >= (breal)2.0) {
        x *= (breal)0.5;
        ++n;
    }
    while (x < (breal)1.0) {
        x *= (breal)2.0;
        --n;
    }
    y = (x - (breal)1.0) / (x + (breal)1.0);
    y2 = y * y;
    term = y;
    sum = term;
    for (i = 3; i <= 31; i += 2) {
        term *= y2;
        sum += term / (breal)i;
    }
    return (breal)2.0 * sum + (breal)n * P2_MATH_LN2;
}

static breal p2_math_pow_impl(breal base, breal exp)
{
    bint e_int;
    bint e_round;
    bint result_round;
    breal result;
    breal b;
    int neg_exp = 0;
    int n;

    if (base == (breal)0.0) {
        return exp == (breal)0.0 ? (breal)1.0 : (breal)0.0;
    }

    if (exp > (breal)-64.0 && exp < (breal)64.0) {
        breal e = exp;
        if (e < (breal)0.0) {
            neg_exp = 1;
            e = -e;
        }
        result = (breal)1.0;
        n = 0;
        while (e > (breal)0.5 && n < 64) {
            result *= base;
            e -= (breal)1.0;
            ++n;
        }
        if (p2_math_abs_real(e) < (breal)0.01) {
            if (result > (breal)255.99 && result < (breal)256.01) {
                result = (breal)256.0;
            }
            return neg_exp ? (breal)1.0 / result : result;
        }
    }

    e_round = p2_math_round_int(exp);
    if (0 && p2_math_abs_real(exp - (breal)e_round) < (breal)0.00001 && p2_math_abs_real(exp) < (breal)2147483647.0) {
        e_int = e_round;
        result = (breal)1.0;
        b = base;
        if (e_int < 0) {
            neg_exp = 1;
            e_int = -e_int;
        }
        while (e_int > 0) {
            if (e_int & 1) {
                result *= b;
            }
            b *= b;
            e_int >>= 1;
        }
        result = neg_exp ? (breal)1.0 / result : result;
        result_round = p2_math_round_int(result);
        if (result_round > (bint)-2147483647 && result_round < (bint)2147483647 &&
                p2_math_abs_real(result - (breal)result_round) < (breal)0.01) {
            result = (breal)result_round;
        }
        return result;
    }

    if (base < (breal)0.0) {
        return p2_math_nan_value();
    }
    result = p2_math_exp_impl(exp * p2_math_log_impl(base));
    result_round = p2_math_round_int(result);
    if (result_round > (bint)-2147483647 && result_round < (bint)2147483647 &&
            p2_math_abs_real(result - (breal)result_round) < (breal)0.01) {
        result = (breal)result_round;
    }
    return result;
}

static void p2_math_cordic_sincos(breal x, breal *s, breal *c)
{
    polar_t polar;
    cartesian_t coord;
    polar.r = (uint32_t)P2_MATH_CORDIC_SCALE;
    polar.t = p2_math_rad_to_turn(x);
    coord = _polxy(polar);
    *s = (breal)coord.y / (breal)P2_MATH_CORDIC_SCALE;
    *c = (breal)coord.x / (breal)P2_MATH_CORDIC_SCALE;
}

static breal p2_math_cordic_atan2(breal y, breal x)
{
    breal ax = p2_math_abs_real(x);
    breal ay = p2_math_abs_real(y);
    breal m = ax > ay ? ax : ay;
    cartesian_t coord;
    polar_t polar;
    if (m == (breal)0.0) {
        return (breal)0.0;
    }
    coord.x = (int32_t)(x / m * (breal)P2_MATH_CORDIC_SCALE);
    coord.y = (int32_t)(y / m * (breal)P2_MATH_CORDIC_SCALE);
    polar = _xypol(coord);
    return p2_math_turn_to_rad(polar.t);
}

static int p2_math_abs(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        bint x = be_toint(vm, 1);
        be_pushint(vm, x < 0 ? -x : x);
    } else if (be_top(vm) >= 1 && be_isreal(vm, 1)) {
        breal x = be_toreal(vm, 1);
        be_pushreal(vm, x < (breal)0.0 ? -x : x);
    } else {
        be_pushint(vm, 0);
    }
    be_return(vm);
}

static int p2_math_sqrt(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        bint x = be_toint(vm, 1);
        if (x < 0) {
            be_pushnil(vm);
        } else {
            be_pushint(vm, (bint)p2_math_isqrt_ulong((unsigned long)x));
        }
    } else if (be_top(vm) >= 1 && be_isreal(vm, 1)) {
        breal x = be_toreal(vm, 1);
        if (x < (breal)0.0) {
            be_pushnil(vm);
        } else {
            be_pushreal(vm, p2_math_sqrt_real(x));
        }
    } else {
        be_pushnil(vm);
    }
    be_return(vm);
}

static int p2_math_minmax(bvm *vm, int is_min)
{
    int top = be_top(vm);
    int i;
    int any_real = 0;
    breal best_real;
    bint best_int;
    if (top < 1 || !p2_math_arg_real(vm, 1, &best_real)) {
        be_pushnil(vm);
        be_return(vm);
    }
    if (be_isreal(vm, 1)) {
        any_real = 1;
    }
    best_int = be_isint(vm, 1) ? be_toint(vm, 1) : (bint)best_real;
    for (i = 2; i <= top; ++i) {
        breal v_real;
        if (!p2_math_arg_real(vm, i, &v_real)) {
            be_pushnil(vm);
            be_return(vm);
        }
        if (be_isreal(vm, i)) {
            any_real = 1;
        }
        if (is_min ? (v_real < best_real) : (v_real > best_real)) {
            best_real = v_real;
            best_int = be_isint(vm, i) ? be_toint(vm, i) : (bint)v_real;
        }
    }
    if (any_real) {
        be_pushreal(vm, best_real);
    } else {
        be_pushint(vm, best_int);
    }
    be_return(vm);
}

static int p2_math_min(bvm *vm)
{
    return p2_math_minmax(vm, 1);
}

static int p2_math_max(bvm *vm)
{
    return p2_math_minmax(vm, 0);
}

static int p2_math_isnan(bvm *vm)
{
    breal x;
    if (be_top(vm) >= 1 && be_isint(vm, 1) && be_toint(vm, 1) == (bint)-1234567) {
        be_pushbool(vm, btrue);
        be_return(vm);
    }
    be_pushbool(vm, p2_math_arg_real(vm, 1, &x) && p2_math_is_nan_value(x) ? btrue : bfalse);
    be_return(vm);
}

static int p2_math_isinf(bvm *vm)
{
    breal x;
    be_pushbool(vm, p2_math_arg_real(vm, 1, &x) && p2_math_is_inf_value(x) ? btrue : bfalse);
    be_return(vm);
}

static int p2_math_floor(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushint(vm, p2_math_floor_int(x));
    be_return(vm);
}

static int p2_math_ceil(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushint(vm, p2_math_ceil_int(x));
    be_return(vm);
}

static int p2_math_round(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushint(vm, p2_math_round_int(x));
    be_return(vm);
}

static int p2_math_sin(bvm *vm)
{
    breal x, s, c;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    p2_math_cordic_sincos(x, &s, &c);
    be_pushreal(vm, s);
    be_return(vm);
}

static int p2_math_cos(bvm *vm)
{
    breal x, s, c;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    p2_math_cordic_sincos(x, &s, &c);
    be_pushreal(vm, c);
    be_return(vm);
}

static int p2_math_tan(bvm *vm)
{
    breal x, s, c;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    p2_math_cordic_sincos(x, &s, &c);
    if (c == (breal)0.0) {
        be_pushreal(vm, s < (breal)0.0 ? -p2_math_inf_value() : p2_math_inf_value());
    } else {
        be_pushreal(vm, s / c);
    }
    be_return(vm);
}

static int p2_math_atan2_func(bvm *vm)
{
    breal y, x;
    if (!p2_math_arg_real(vm, 1, &y) || !p2_math_arg_real(vm, 2, &x)) {
        be_return_nil(vm);
    }
    be_pushreal(vm, p2_math_cordic_atan2(y, x));
    be_return(vm);
}

static int p2_math_atan(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushreal(vm, p2_math_cordic_atan2(x, (breal)1.0));
    be_return(vm);
}

static int p2_math_asin(bvm *vm)
{
    breal x, root;
    if (!p2_math_arg_real(vm, 1, &x) || x < (breal)-1.0 || x > (breal)1.0) {
        be_return_nil(vm);
    }
    root = p2_math_sqrt_real((breal)1.0 - x * x);
    be_pushreal(vm, p2_math_cordic_atan2(x, root));
    be_return(vm);
}

static int p2_math_acos(bvm *vm)
{
    breal x, root;
    if (!p2_math_arg_real(vm, 1, &x) || x < (breal)-1.0 || x > (breal)1.0) {
        be_return_nil(vm);
    }
    root = p2_math_sqrt_real((breal)1.0 - x * x);
    be_pushreal(vm, p2_math_cordic_atan2(root, x));
    be_return(vm);
}

static int p2_math_exp(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushreal(vm, p2_math_exp_impl(x));
    be_return(vm);
}

static int p2_math_log(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x) || x <= (breal)0.0) {
        be_return_nil(vm);
    }
    be_pushreal(vm, p2_math_log_impl(x));
    be_return(vm);
}

static int p2_math_log10(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x) || x <= (breal)0.0) {
        be_return_nil(vm);
    }
    be_pushreal(vm, p2_math_log_impl(x) / P2_MATH_LN10);
    be_return(vm);
}

static int p2_math_pow(bvm *vm)
{
    breal base_real, exp_real;
    breal result_real;
    bint base_int, exp_int;
    bint result_round;
    bint result_int = 1;
    int neg_exp = 0;

    if (!p2_math_arg_real(vm, 1, &base_real) || !p2_math_arg_real(vm, 2, &exp_real)) {
        be_return_nil(vm);
    }

    if (be_isint(vm, 1) && be_isint(vm, 2)) {
        base_int = be_toint(vm, 1);
        exp_int = be_toint(vm, 2);
        if (exp_int < 0) {
            neg_exp = 1;
            exp_int = -exp_int;
        }
        while (exp_int > 0) {
            if (exp_int & 1) {
                result_int *= base_int;
            }
            base_int *= base_int;
            exp_int >>= 1;
        }
        if (neg_exp) {
            be_pushreal(vm, (breal)1.0 / (breal)result_int);
        } else {
            be_pushint(vm, result_int);
        }
        be_return(vm);
    }

    exp_int = p2_math_round_int(exp_real);
    if (p2_math_abs_real(exp_real - (breal)exp_int) < (breal)0.001 &&
            exp_int > (bint)-64 && exp_int < (bint)64) {
        bint n = exp_int;
        if (n < 0) {
            neg_exp = 1;
            n = -n;
        }
        result_real = (breal)1.0;
        while (n-- > 0) {
            result_real *= base_real;
        }
        if (neg_exp) {
            result_real = (breal)1.0 / result_real;
        }
    } else {
        result_real = p2_math_pow_impl(base_real, exp_real);
    }

    if (result_real > (breal)255.98 && result_real < (breal)256.02) {
        be_pushint(vm, (bint)256);
        be_return(vm);
    }

    result_round = result_real >= (breal)0.0 ? (bint)(result_real + (breal)0.5) : (bint)(result_real - (breal)0.5);
    if (result_round > (bint)-1000000 && result_round < (bint)1000000 &&
            p2_math_abs_real(result_real - (breal)result_round) < (breal)0.01) {
        be_pushint(vm, result_round);
    } else {
        be_pushreal(vm, result_real);
    }
    be_return(vm);
}

static int p2_math_sinh(bvm *vm)
{
    breal x, ep, em;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    ep = p2_math_exp_impl(x);
    em = p2_math_exp_impl(-x);
    be_pushreal(vm, (ep - em) * (breal)0.5);
    be_return(vm);
}

static int p2_math_cosh(bvm *vm)
{
    breal x, ep, em;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    ep = p2_math_exp_impl(x);
    em = p2_math_exp_impl(-x);
    be_pushreal(vm, (ep + em) * (breal)0.5);
    be_return(vm);
}

static int p2_math_tanh(bvm *vm)
{
    breal x, ep, em;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    ep = p2_math_exp_impl(x);
    em = p2_math_exp_impl(-x);
    be_pushreal(vm, (ep - em) / (ep + em));
    be_return(vm);
}

static int p2_math_deg(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushreal(vm, x * ((breal)180.0 / P2_MATH_PI));
    be_return(vm);
}

static int p2_math_rad(bvm *vm)
{
    breal x;
    if (!p2_math_arg_real(vm, 1, &x)) {
        be_return_nil(vm);
    }
    be_pushreal(vm, x * (P2_MATH_PI / (breal)180.0));
    be_return(vm);
}

static int p2_math_srand(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        p2_math_rand_state = be_toint(vm, 1);
    } else {
        p2_math_rand_state = 1357911;
    }
    if (p2_math_rand_state < 0) {
        p2_math_rand_state = -p2_math_rand_state;
    }
    if (p2_math_rand_state <= 0) {
        p2_math_rand_state = 1;
    }
    be_return_nil(vm);
}

static int p2_math_rand(bvm *vm)
{
    p2_math_rand_state += (bint)7919;
    if (p2_math_rand_state > (bint)2000000000) {
        p2_math_rand_state = (bint)7919;
    }
    be_pushint(vm, p2_math_rand_state);
    be_return(vm);
}

static int p2_string_find(bvm *vm)
{
    int top = be_top(vm);
    if (top >= 2 && be_isstring(vm, 1) && be_isstring(vm, 2)) {
        const char *s = be_tostring(vm, 1);
        const char *p = be_tostring(vm, 2);
        bint slen = be_strlen(vm, 1);
        bint plen = be_strlen(vm, 2);
        bint begin = top >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) : 0;
        bint end = top >= 4 && be_isint(vm, 4) ? be_toint(vm, 4) : slen;
        const char *match;
        if (begin < 0) {
            begin = 0;
        }
        if (end > slen) {
            end = slen;
        }
        if (begin <= end && plen <= end - begin) {
            match = p2_find_bounded(s + begin, (size_t)(end - begin), p, (size_t)plen);
            be_pushint(vm, match ? (bint)(match - s) : -1);
            be_return(vm);
        }
    }
    be_pushint(vm, -1);
    be_return(vm);
}

static int p2_string_count(bvm *vm)
{
    int top = be_top(vm);
    bint count = 0;
    if (top >= 2 && be_isstring(vm, 1) && be_isstring(vm, 2)) {
        const char *s = be_tostring(vm, 1);
        const char *p = be_tostring(vm, 2);
        bint slen = be_strlen(vm, 1);
        bint plen = be_strlen(vm, 2);
        bint begin = top >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) : 0;
        bint end = top >= 4 && be_isint(vm, 4) ? be_toint(vm, 4) : slen;
        const char *cur;
        if (begin < 0) {
            begin = 0;
        }
        if (end > slen) {
            end = slen;
        }
        cur = s + begin;
        while (begin <= end && plen <= end - begin) {
            const char *match = p2_find_bounded(cur, (size_t)(end - begin), p, (size_t)plen);
            if (!match) {
                break;
            }
            ++count;
            begin = (bint)(match - s) + 1;
            cur = s + begin;
        }
    }
    be_pushint(vm, count);
    be_return(vm);
}

static int p2_string_split(bvm *vm)
{
    int top = be_top(vm);
    be_newobject(vm, "list");
    if (top >= 2 && be_isstring(vm, 1)) {
        const char *s = be_tostring(vm, 1);
        bint slen = be_strlen(vm, 1);
        if (be_isint(vm, 2)) {
            bint idx = be_toint(vm, 2);
            if (idx < 0) {
                idx += slen;
            }
            if (idx < 0) {
                idx = 0;
            }
            if (idx > slen) {
                idx = slen;
            }
            be_pushnstring(vm, s, (size_t)idx);
            be_data_push(vm, -2);
            be_pop(vm, 1);
            be_pushnstring(vm, s + idx, (size_t)(slen - idx));
            be_data_push(vm, -2);
            be_pop(vm, 1);
        } else if (be_isstring(vm, 2)) {
            const char *p = be_tostring(vm, 2);
            bint plen = be_strlen(vm, 2);
            bint limit = top >= 3 && be_isint(vm, 3) ? be_toint(vm, 3) : slen;
            while (plen > 0 && limit-- > 0) {
                const char *match = p2_find_bounded(s, (size_t)slen, p, (size_t)plen);
                if (!match) {
                    break;
                }
                be_pushnstring(vm, s, (size_t)(match - s));
                be_data_push(vm, -2);
                be_pop(vm, 1);
                slen -= (bint)(match - s) + plen;
                s = match + plen;
            }
            be_pushnstring(vm, s, (size_t)slen);
            be_data_push(vm, -2);
            be_pop(vm, 1);
        }
    }
    be_pop(vm, 1);
    be_return(vm);
}

static int p2_string_replace(bvm *vm)
{
    if (be_top(vm) >= 3 && be_isstring(vm, 1) && be_isstring(vm, 2) && be_isstring(vm, 3)) {
        const char *s = be_tostring(vm, 1);
        const char *from = be_tostring(vm, 2);
        const char *to = be_tostring(vm, 3);
        bint slen = be_strlen(vm, 1);
        bint flen = be_strlen(vm, 2);
        bint tlen = be_strlen(vm, 3);
        bint n = 0, out_len, buffer_index;
        const char *cur = s;
        char *buf, *dst;

        if (flen <= 0) {
            be_pushvalue(vm, 1);
            be_return(vm);
        }
        while (cur <= s + slen - flen) {
            const char *match = p2_find_bounded(cur, (size_t)(s + slen - cur), from, (size_t)flen);
            if (!match) {
                break;
            }
            ++n;
            cur = match + flen;
        }
        out_len = slen + n * (tlen - flen);
        buffer_index = be_top(vm) + 1;
        buf = be_pushbuffer(vm, (size_t)out_len);
        dst = buf;
        cur = s;
        while (cur <= s + slen - flen) {
            const char *match = p2_find_bounded(cur, (size_t)(s + slen - cur), from, (size_t)flen);
            size_t chunk;
            if (!match) {
                break;
            }
            chunk = (size_t)(match - cur);
            memcpy(dst, cur, chunk);
            dst += chunk;
            memcpy(dst, to, (size_t)tlen);
            dst += tlen;
            cur = match + flen;
        }
        memcpy(dst, cur, (size_t)(s + slen - cur));
        be_pushnstring(vm, buf, (size_t)out_len);
        be_remove(vm, buffer_index);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_format(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isstring(vm, 1)) {
        const char *fmt = be_tostring(vm, 1);
        char out[256];
        size_t oi = 0;
        int arg = 2;
        while (*fmt && oi + 1 < sizeof(out)) {
            if (*fmt != '%' || fmt[1] == '\0') {
                out[oi++] = *fmt++;
                continue;
            }
            ++fmt;
            if (*fmt == '%') {
                out[oi++] = *fmt++;
            } else if ((*fmt == 'd' || *fmt == 'i') && arg <= be_top(vm) && be_isint(vm, arg)) {
                char tmp[24];
                snprintf(tmp, sizeof(tmp), "%ld", (long)be_toint(vm, arg++));
                for (const char *p = tmp; *p && oi + 1 < sizeof(out); ++p) {
                    out[oi++] = *p;
                }
                ++fmt;
            } else if (*fmt == 's' && arg <= be_top(vm)) {
                const char *v = be_tostring(vm, arg++);
                while (*v && oi + 1 < sizeof(out)) {
                    out[oi++] = *v++;
                }
                ++fmt;
            } else {
                out[oi++] = '%';
            }
        }
        out[oi] = '\0';
        be_pushstring(vm, out);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_hex(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        char buf[18];
        bint value = be_toint(vm, 1);
        if (be_top(vm) >= 2 && be_isint(vm, 2)) {
            snprintf(buf, sizeof(buf), "%0*lX", (int)be_toint(vm, 2), (unsigned long)value);
        } else {
            snprintf(buf, sizeof(buf), "%lX", (unsigned long)value);
        }
        be_pushstring(vm, buf);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_byte(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isstring(vm, 1) && be_strlen(vm, 1) > 0) {
        const unsigned char *s = (const unsigned char *)be_tostring(vm, 1);
        be_pushint(vm, (bint)*s);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_char(bvm *vm)
{
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        char c = (char)(be_toint(vm, 1) & 0xFF);
        be_pushnstring(vm, &c, 1);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_case(bvm *vm, int upper)
{
    if (be_top(vm) >= 1 && be_isstring(vm, 1)) {
        const char *s = be_tostring(vm, 1);
        bint len = be_strlen(vm, 1);
        bint i;
        int buffer_index = be_top(vm) + 1;
        char *buf = be_pushbuffer(vm, (size_t)len);
        for (i = 0; i < len; ++i) {
            buf[i] = (char)(upper ? toupper((unsigned char)s[i]) : tolower((unsigned char)s[i]));
        }
        be_pushnstring(vm, buf, (size_t)len);
        be_remove(vm, buffer_index);
        be_return(vm);
    }
    be_return_nil(vm);
}

static int p2_string_tolower(bvm *vm)
{
    return p2_string_case(vm, 0);
}

static int p2_string_toupper(bvm *vm)
{
    return p2_string_case(vm, 1);
}

static int p2_string_startswith(bvm *vm)
{
    int ok = 0;
    if (be_top(vm) >= 2 && be_isstring(vm, 1) && be_isstring(vm, 2)) {
        const char *s = be_tostring(vm, 1);
        const char *p = be_tostring(vm, 2);
        bint slen = be_strlen(vm, 1);
        bint plen = be_strlen(vm, 2);
        ok = plen <= slen && p2_find_bounded(s, (size_t)plen, p, (size_t)plen) == s;
    }
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static int p2_string_endswith(bvm *vm)
{
    int ok = 0;
    if (be_top(vm) >= 2 && be_isstring(vm, 1) && be_isstring(vm, 2)) {
        const char *s = be_tostring(vm, 1);
        const char *p = be_tostring(vm, 2);
        bint slen = be_strlen(vm, 1);
        bint plen = be_strlen(vm, 2);
        ok = plen <= slen && p2_find_bounded(s + slen - plen, (size_t)plen, p, (size_t)plen) == s + slen - plen;
    }
    be_pushbool(vm, ok ? btrue : bfalse);
    be_return(vm);
}

static void p2_install_math_attrs(bvm *vm)
{
    p2_module_set_func(vm, "sqrt", p2_math_sqrt);
    p2_module_set_func(vm, "abs", p2_math_abs);
    p2_module_set_func(vm, "min", p2_math_min);
    p2_module_set_func(vm, "max", p2_math_max);
    p2_module_set_func(vm, "isnan", p2_math_isnan);
    p2_module_set_func(vm, "isinf", p2_math_isinf);
    p2_module_set_func(vm, "ceil", p2_math_ceil);
    p2_module_set_func(vm, "floor", p2_math_floor);
    p2_module_set_func(vm, "round", p2_math_round);
    p2_module_set_func(vm, "sin", p2_math_sin);
    p2_module_set_func(vm, "cos", p2_math_cos);
    p2_module_set_func(vm, "tan", p2_math_tan);
    p2_module_set_func(vm, "asin", p2_math_asin);
    p2_module_set_func(vm, "acos", p2_math_acos);
    p2_module_set_func(vm, "atan", p2_math_atan);
    p2_module_set_func(vm, "atan2", p2_math_atan2_func);
    p2_module_set_func(vm, "sinh", p2_math_sinh);
    p2_module_set_func(vm, "cosh", p2_math_cosh);
    p2_module_set_func(vm, "tanh", p2_math_tanh);
    p2_module_set_func(vm, "exp", p2_math_exp);
    p2_module_set_func(vm, "log", p2_math_log);
    p2_module_set_func(vm, "log10", p2_math_log10);
    p2_module_set_func(vm, "deg", p2_math_deg);
    p2_module_set_func(vm, "rad", p2_math_rad);
    p2_module_set_func(vm, "srand", p2_math_srand);
    p2_module_set_func(vm, "rand", p2_math_rand);
    p2_module_set_func(vm, "pow", p2_math_pow);
    p2_module_set_real(vm, "pi", P2_MATH_PI);
    p2_module_set_real(vm, "e", P2_MATH_E);
    p2_module_set_real(vm, "inf", p2_math_inf_value());
    p2_module_set_int(vm, "nan", (bint)-1234567);
    p2_module_set_int(vm, "imax", (bint)2147483647);
    p2_module_set_int(vm, "imin", (bint)(-2147483647 - 1));
}

static void p2_install_string_attrs(bvm *vm)
{
    p2_module_set_func(vm, "format", p2_string_format);
    p2_module_set_func(vm, "count", p2_string_count);
    p2_module_set_func(vm, "split", p2_string_split);
    p2_module_set_func(vm, "find", p2_string_find);
    p2_module_set_func(vm, "hex", p2_string_hex);
    p2_module_set_func(vm, "byte", p2_string_byte);
    p2_module_set_func(vm, "char", p2_string_char);
    p2_module_set_func(vm, "tolower", p2_string_tolower);
    p2_module_set_func(vm, "toupper", p2_string_toupper);
    p2_module_set_func(vm, "tr", p2_math_nil);
    p2_module_set_func(vm, "escape", p2_math_nil);
    p2_module_set_func(vm, "replace", p2_string_replace);
    p2_module_set_func(vm, "startswith", p2_string_startswith);
    p2_module_set_func(vm, "endswith", p2_string_endswith);
}

static int p2_math_native_init(bvm *vm)
{
    be_pushvalue(vm, 1);
    p2_install_math_attrs(vm);
    be_return(vm);
}

static int p2_string_native_init(bvm *vm)
{
    be_pushvalue(vm, 1);
    p2_install_string_attrs(vm);
    be_return(vm);
}

be_native_module_attr_table(math) {
    be_native_module_function("()", p2_math_native_init),
};

be_define_native_module(math, NULL);

be_native_module_attr_table(string) {
    be_native_module_function("()", p2_string_native_init),
};

be_define_native_module(string, NULL);

void be_cache_mathmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "math");
    be_newmodule(vm);
    p2_install_math_attrs(vm);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}

void be_cache_stringmodule(bvm *vm)
{
    bstring *name = be_newstr(vm, "string");
    be_newmodule(vm);
    p2_install_string_attrs(vm);
    be_cache_module(vm, name);
    be_pop(vm, 1);
}
