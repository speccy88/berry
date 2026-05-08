#!/usr/bin/env python3
"""Generate the Spin2 feature and PASM2 mailbox example suite.

The examples are intentionally small, 8.3-friendly, and comments-heavy.
They are generated from compact templates so broad language coverage can be
kept consistent with the Berry Spin2 mailbox ABI.
"""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPIN2 = ROOT / "spin2"
COMMON = SPIN2 / "common"


COMMON_SERVICE = """\
{{ Berry Spin2 mailbox service include.

   Include this file after a two-entry method table:

     DAT
             long 2
             long berry_mbox_service
             long berry_mbox_method_1
     #include "common/berry_mbox_service.spin2h"

   Berry loads the binary after the method table, so this code is assembled at
   cog address 0.  The table remains in hub RAM for Berry's method-count check.
   The service waits for mailbox state 1, loads argv[0..7] into registers,
   calls berry_mbox_method_1, writes result, and marks the call done.
}}

                org     0

berry_mbox_service
                mov     berry_mbox_mb, ptra
                mov     berry_mbox_state, #0
                wrlong  berry_mbox_state, berry_mbox_mb

berry_mbox_loop
                rdlong  berry_mbox_state, berry_mbox_mb
                cmp     berry_mbox_state, #1 wz
        if_z    call    #berry_mbox_handle_request
                cmp     berry_mbox_state, #5 wz
        if_z    cogid   berry_mbox_state
        if_z    cogstop berry_mbox_state
                waitx   ##2_000
                jmp     #berry_mbox_loop

berry_mbox_handle_request
                mov     berry_mbox_state, #2
                wrlong  berry_mbox_state, berry_mbox_mb

                mov     berry_mbox_ptr, berry_mbox_mb
                add     berry_mbox_ptr, #(1 * 4)
                rdlong  berry_mbox_method, berry_mbox_ptr

                mov     berry_mbox_ptr, berry_mbox_mb
                add     berry_mbox_ptr, #(2 * 4)
                rdlong  berry_mbox_argc, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg0, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg1, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg2, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg3, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg4, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg5, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg6, berry_mbox_ptr
                add     berry_mbox_ptr, #4
                rdlong  arg7, berry_mbox_ptr

                mov     result, #0
                cmp     berry_mbox_method, #1 wz
        if_nz   jmp     #berry_mbox_bad_method
                call    #berry_mbox_method_1

                mov     berry_mbox_ptr, berry_mbox_mb
                add     berry_mbox_ptr, #(11 * 4)
                wrlong  result, berry_mbox_ptr
                mov     berry_mbox_state, #3
                wrlong  berry_mbox_state, berry_mbox_mb
                ret

berry_mbox_bad_method
                neg     result, #1
                mov     berry_mbox_ptr, berry_mbox_mb
                add     berry_mbox_ptr, #(11 * 4)
                wrlong  result, berry_mbox_ptr
                mov     berry_mbox_state, #4
                wrlong  berry_mbox_state, berry_mbox_mb
                ret

"""


COMMON_REGS = """\
{{ Registers shared by the mailbox service and each example method. }}

berry_mbox_mb      res     1
berry_mbox_ptr     res     1
berry_mbox_state   res     1
berry_mbox_method  res     1
berry_mbox_argc    res     1

arg0               res     1
arg1               res     1
arg2               res     1
arg3               res     1
arg4               res     1
arg5               res     1
arg6               res     1
arg7               res     1

result             res     1
temp0              res     1
temp1              res     1
temp2              res     1
temp3              res     1

"""


FEATURES: dict[str, str] = {
    "s2_01con.spin2": """\
{{ Feature 01: CON constants.

   Covers decimal, hexadecimal, binary, double-binary, character, floating-point
   constants, underscore separators, and compile-time ROUND().
}}

CON
    dec_value   = 1_234
    hex_value   = $AA55
    bin_value   = %1010_0101
    dbin_value  = %%3210
    char_A      = "A"
    half_pi     = 1.5707963
    rounded     = ROUND(4000.0 / half_pi)

PUB main() : r
    r := dec_value + hex_value + bin_value + dbin_value + char_A + rounded
""",
    "s2_02enum.spin2": """\
{{ Feature 02: enumerated constants.

   The # syntax starts an enumeration and optional [step] values change the
   increment.  This example keeps the math deterministic for compile/run smoke
   testing.
}}

CON
    #0, idle, running, done
    #10[2], even10, even12, even14
    #100
    first_after_reset
    second_after_reset

PUB main() : r
    r := done + even14 + second_after_reset
""",
    "s2_03str.spin2": """\
{Spin2_v52}
{{ Feature 03: string/data methods.

   STRING() produces a zero-terminated byte string.  @"..." is shorthand for a
   string literal pointer, LSTRING() prefixes the byte count, and BYTE/WORD/LONG
   declare literal data blocks that return pointers.
}}

PUB main() : r | p
    p := STRING("abc")
    r := BYTE[p] + BYTE[p][1] + BYTE[p][2]

    p := @"a\\n"
    r += BYTE[p][1]

    p := LSTRING("xyz")
    r += BYTE[p]

    p := BYTE(1, 2, 3, 0)
    r += BYTE[p][2]

    p := WORD($1234, $5678)
    r += WORD[p][1]

    p := LONG($01020304)
    r += LONG[p]
""",
    "s2_04var.spin2": """\
{{ Feature 04: VAR storage.

   Shows BYTE, WORD, and LONG object variables, arrays, and local loop indexes.
   Spin2 zero-initializes VAR storage before the first method runs.
}}

VAR
    BYTE bytes[4], one_byte
    WORD words[2]
    LONG longs[2]

PUB main() : r | i
    REPEAT 4 WITH i
        bytes[i] := i + 1

    one_byte := bytes[0] + bytes[3]
    words[0] := $1234
    words[1] := $00AA
    longs[0] := $01020304
    longs[1] := one_byte

    r := bytes[0] + bytes[1] + bytes[2] + bytes[3]
    r += words[0] + words[1] + longs[1]
""",
    "s2_05bits.spin2": """\
{{ Feature 05: indexed variables and bitfields.

   The .[top..bottom] syntax reads and writes bitfields.  BYTE/WORD/LONG size
   overrides can be combined with indexes when addressing hub variables.
}}

VAR
    LONG value
    BYTE mirror[4]

PUB main() : r
    value := $1234_5678
    r := value.[7..0]
    value.[15..8] := $AB

    mirror[0] := value.BYTE[0]
    mirror[1] := value.BYTE[1]
    mirror[2] := value.BYTE[2]
    mirror[3] := value.BYTE[3]

    r += mirror[1] + value.[31..28]
""",
    "s2_06expr.spin2": """\
{{ Feature 06: integer expressions and operators.

   Covers unary helpers, shifts, rotates, bit operations, min/max forcing,
   logical operators, and the ternary operator.
}}

PUB main() : r | x, y
    x := -123
    y := ABS x
    r := y

    r += ENCOD($8000)
    r += DECOD(3)
    r += BMASK(5)
    r += ONES(%1011_0101)
    r += SQRT(10_000)

    x := $0000_00F0
    r += (x >> 4) + (x << 1)
    r += (x ROR 4) & $FF
    r += (x ROL 4) & $FF
    r += (x REV 7)
    r += ($F0 ZEROX 3)
    r += ($F0 SIGNX 7)

    r += (10 #> 20)
    r += (99 <# 20)
    r += ((1 AND 2) ? 7 : 9)
""",
    "s2_07flow.spin2": """\
{{ Feature 07: IF, IFNOT, ELSEIF, ELSE.

   Indentation defines controlled blocks.  The method returns a small checksum
   that changes if any branch condition is compiled incorrectly.
}}

PUB main() : r | x
    x := 7

    IF x > 10
        r := 100
    ELSEIF x == 7
        r := 7
    ELSE
        r := -1

    IFNOT x == 0
        r += 30
""",
    "s2_08case.spin2": """\
{{ Feature 08: CASE and CASE_FAST.

   CASE handles ranges and OTHER.  CASE_FAST uses a compact jump table when the
   matches are dense constants.
}}

PUB main() : r | x
    x := 5
    CASE x
        0:      r := 10
        1..4:   r := 20
        5, 7:   r := 30
        OTHER:  r := 40

    CASE_FAST x
        0: r += 1
        1: r += 2
        2: r += 3
        3: r += 4
        4: r += 5
        5: r += 6
""",
    "s2_09loop.spin2": """\
{Spin2_v52}
{{ Feature 09: REPEAT forms, NEXT, and QUIT.

   Covers counted loops, WITH index loops, FROM/TO/STEP, WHILE, UNTIL, and
   conditional NEXT/QUIT control transfer.
}}

PUB main() : r | i, guard
    REPEAT 3
        r += 1

    REPEAT 4 WITH i
        r += i

    REPEAT i FROM 2 TO 8 STEP 2
        r += i

    guard := 0
    REPEAT WHILE guard < 3
        guard++
        IF guard == 2
            NEXT
        r += guard

    REPEAT
        guard--
        IF guard == 0
            QUIT
        r += 10
""",
    "s2_10meth.spin2": """\
{{ Feature 10: PUB/PRI methods.

   Public methods are callable from parent objects.  Private methods are local
   helpers.  Parameters, return values, and locals are all hub variables.
}}

PUB main() : r | a, b
    a := 9
    b := 4
    r := area(a, b) + perimeter(a, b)

PRI area(width, height) : value
    value := width * height

PRI perimeter(width, height) : value
    value := (width + height) * 2
""",
    "s2_11multi.spin2": """\
{{ Feature 11: multiple return values and ignored assignments.

   Spin2 methods can return up to 15 values.  The underscore on the left side
   discards a value while keeping the assignment positions aligned.
}}

PUB main() : r | a, b, c
    a, b, c := triple(10)
    _, b := pair(40)
    r := a + b + c

PRI triple(x) : a, b, c
    a := x
    b := x + 1
    c := x + 2

PRI pair(x) : a, b
    a := x
    b := x + 5
""",
    "s2_12send.spin2": """\
{{ Feature 12: SEND method pointer.

   SEND is inherited by called methods and works as a compact output callback.
   This example routes values through a private sink method.
}}

VAR
    LONG total

PUB main() : r
    total := 0
    SEND := @sink
    SEND(1, 2, 3, helper())
    r := total

PRI helper() : x
    SEND(10)
    x := 4

PRI sink(x)
    total += x
""",
    "s2_13recv.spin2": """\
{{ Feature 13: RECV method pointer.

   RECV is the input counterpart to SEND.  It points to a no-argument method
   that returns one value.
}}

VAR
    LONG next_value

PUB main() : r | i
    next_value := 0
    RECV := @source
    REPEAT 4 WITH i
        r += RECV()

PRI source() : x
    next_value++
    x := next_value
""",
    "s2_chld.spin2": """\
{{ Child object for s2_14obj.spin2.

   Parent objects can override CON symbols through OBJ parameters.  This child
   is also buildable as a standalone file for make spin2.
}}

CON
    base = 10
    scale = 2

PUB main() : r
    r := value(1)

PUB value(x) : r
    r := base + (x * scale)
""",
    "s2_14obj.spin2": """\
{{ Feature 14: OBJ child object instantiation.

   The child object is parameterized so its BASE and SCALE constants differ in
   this parent from the child's standalone defaults.
}}

OBJ
    child : "s2_chld" | base = 40, scale = 3

PUB main() : r
    r := child.value(2) + child.base
""",
    "s2_15stru.spin2": """\
{Spin2_v45}
{{ Feature 15: basic STRUCT definitions.

   STRUCT declarations are packed and allocate storage only when instantiated
   in VAR or method headers.
}}

CON
    STRUCT point(BYTE x, BYTE y)

VAR
    point p

PUB main() : r
    p.x := 10
    p.y := 20
    r := SIZEOF(point) + p.x + p.y
""",
    "s2_16nest.spin2": """\
{Spin2_v45}
{{ Feature 16: nested STRUCTs and arrays.

   Nested structure fields are accessed with dotted member syntax.  Arrays can
   be declared at any structure level.
}}

CON
    STRUCT point(BYTE x, BYTE y)
    STRUCT line(point a, point b, BYTE color)

VAR
    line lines[2]

PUB main() : r
    lines[0].a.x := 1
    lines[0].a.y := 2
    lines[0].b.x := 3
    lines[0].b.y := 4
    lines[0].color := 5

    lines[1].a.x := lines[0].b.x
    lines[1].a.y := lines[0].b.y
    lines[1].color := lines[0].color + 1

    r := SIZEOF(line) + lines[1].a.x + lines[1].a.y + lines[1].color
""",
    "s2_17fld.spin2": """\
{Spin2_v46}
{{ Feature 17: field pointers.

   ^@ captures a hub or register variable plus an optional bitfield.  FIELD[p]
   then reads or writes through that encoded pointer.
}}

PUB main() : r | p, packed, i
    packed := 0
    p := ^@packed.[2..0]

    REPEAT 4 WITH i
        FIELD[p][i] := i

    r := packed
""",
    "s2_18mem.spin2": """\
{Spin2_v52}
{{ Feature 18: memory helper methods.

   BYTEFILL/BYTEMOVE and the v44+ compare/swap helpers operate directly on hub
   memory.  ENDIANW/ENDIANL are v52 byte-order helpers.
}}

VAR
    BYTE a[8]
    BYTE b[8]
    WORD w[4]
    LONG l[2]

PUB main() : r
    BYTEFILL(@a, $11, 8)
    BYTEMOVE(@b, @a, 8)
    BYTESWAP(@a, @b, 4)
    r := BYTECOMP(@a, @b, 4)

    WORDFILL(@w, $1234, 4)
    LONGFILL(@l, $01020304, 2)
    r += ENDIANW(w[0]) + ENDIANL(l[0])
""",
    "s2_19fpm.spin2": """\
{Spin2_v52}
{{ Feature 19: floating-point operators.

   Spin2 stores floats as IEEE-754 single-precision longs.  Operators ending in
   dots and LOG/EXP/POW treat their operands as floats.
}}

PUB main() : r | f
    f := 3.0 *. 4.0
    f := f /. 2.0
    f := f +. 1.5
    f := FSQRT(f)
    f := 3.0 POW 4.0
    f := LOG2(257.0)
    f := EXP2(8.0)
    r := ROUND(f)
""",
    "s2_20task.spin2": """\
{Spin2_v47}
{{ Feature 20: cooperative Spin2 tasks.

   TASKSPIN creates a task in the current cog.  Each task must call TASKNEXT or
   stop itself to cooperate with the scheduler.
}}

VAR
    LONG stack[16]
    LONG seen

PUB main() : r | task
    seen := 0
    task := TASKSPIN(NEWTASK, worker(), @stack)
    REPEAT 3
        TASKNEXT()
    r := TASKCHK(task) + seen
    TASKSTOP(task)

PRI worker()
    seen++
    TASKSTOP(THISTASK)
""",
    "s2_21prep.spin2": """\
{{ Feature 21: preprocessor conditionals.

   FlexSpin supports the v48-style #DEFINE/#IFDEF family.  This file makes the
   chosen branch observable through the return checksum.
}}

#define LOCAL_SYMBOL

#ifdef LOCAL_SYMBOL
CON selected = 7
#else
CON selected = 9
#endif

#ifndef MISSING_SYMBOL
CON fallback = 3
#endif

PUB main() : r
    r := selected + fallback
""",
    "s2_22dbg.spin2": """\
{Spin2_v46}
{{ Feature 22: DEBUG gating syntax.

   DEBUG statements compile away in normal builds.  DEBUG_DISABLE and
   DEBUG_MASK show the documented control symbols without opening any debug
   channel during make spin2.
}}

CON
    DEBUG_DISABLE = 1
    DEBUG_MASK = %1

PUB main() : r | i
    REPEAT 3 WITH i
        DEBUG[0](UDEC(i))
        r += i
""",
    "s2_23pin.spin2": """\
{{ Feature 23: pinfields and GPIO helpers.

   The normal P2 Edge profile exposes pins 56 and 57 as LEDs.  This example is
   safe as a short LED pulse if run directly, but is mainly a compile test for
   PINLOW/PINHIGH/PINWRITE/PINREAD and ADDPINS syntax.
}}

CON
    led_base = 56
    led_pair = led_base ADDPINS 1

PUB main() : r
    PINLOW(led_pair)
    PINHIGH(led_base)
    WAITMS(1)
    PINWRITE(led_pair, 0)
    r := PINREAD(led_base)
""",
    "s2_24clk.spin2": """\
{{ Feature 24: counters, clock frequency, and timing helpers.

   GETCT returns the free-running counter.  WAITX waits clock ticks.  MULDIV64
   scales a 64-bit product back to a 32-bit quotient.
}}

PUB main() : r | before, after, elapsed
    before := GETCT()
    WAITX(10)
    after := GETCT()
    elapsed := after - before
    r := MULDIV64(elapsed, 1_000_000, CLKFREQ)
""",
    "s2_25pasm.spin2": """\
{{ Feature 25: inline PASM and CALL(@hubcode).

   ORG inline code runs from cog registers and ORGH inline code runs from hub
   RAM.  CALL(@routine) invokes a DAT PASM routine from Spin2.
}}

PUB main() : r | x
    x := 40

    ORG
        add     x, #1
    END

    ORGH
        add     x, #1
    END

    PR0 := x
    CALL(@add_three)
    r := PR0

DAT
        ORGH
add_three
        add     PR0, #3
 _RET_  ret
""",
    "s2_26dat.spin2": """\
{{ Feature 26: DAT data declarations.

   BYTE/WORD/LONG, BYTEFIT/WORDFIT, ALIGNW, and ALIGNL are represented here.
   The main method reads the data back through hub addresses.
}}

PUB main() : r
    r := BYTE[@text]
    r += WORD[@pattern][1]
    r += LONG[@numbers][1]
    r += BYTE[@checked]

DAT
text        BYTE    "ABC", 0
            ALIGNW
pattern     WORD    $1234, $5678
            ALIGNL
numbers     LONG    1.0, $01020304
checked     BYTEFIT -$80, $FF
            WORDFIT -$8000, $FFFF
""",
    "s2_27dit.spin2": """\
{Spin2_v50}
{{ Feature 27: DAT/PASM DITTO generation.

   DITTO emits repeated assembly lines at compile time.  The special $$ symbol
   is the zero-based generation index.
}}

DAT
        ORG
start   mov     total, #0

gen     DITTO   4
        add     total, #$$
        DITTO   END

        jmp     #$

total   res     1
""",
}


MAILBOX_METHODS: dict[str, tuple[str, str]] = {
    "mb_01alu.spin2": (
        "PASM2 arithmetic: MOV, ADD, SUB, ADDS, SUBS, NEG, ABS.",
        """\
berry_mbox_method_1
                mov     result, arg0
                add     result, arg1
                sub     result, #3
                neg     temp0, #10
                abs     temp0
                adds    temp0, #5
                subs    temp0, #2
                add     result, temp0
                neg     temp1, #7
                sub     result, temp1
                ret
""",
    ),
    "mb_02log.spin2": (
        "PASM2 boolean and bitwise operations: AND, OR, XOR, ANDN, NOT.",
        """\
berry_mbox_method_1
                mov     result, arg0
                and     result, arg1
                mov     temp0, arg0
                or      temp0, arg1
                xor     result, temp0
                andn    result, #$0F
                not     temp1, result
                xor     result, temp1
                ret
""",
    ),
    "mb_03shf.spin2": (
        "PASM2 shifts, rotates, REV, ZEROX, and SIGNX.",
        """\
berry_mbox_method_1
                mov     result, #1
                shl     result, #5
                shr     result, #1
                rol     result, #3
                ror     result, #3
                rev     result
                zerox   result, #7
                signx   result, #7
                ret
""",
    ),
    "mb_04cmp.spin2": (
        "PASM2 comparisons and flags: CMP, CMPS, CMPR, CMPM, TEST.",
        """\
berry_mbox_method_1
                mov     result, #0
                cmp     arg0, arg1 wz,wc
        if_z    add     result, #1
        if_c    add     result, #2
                cmps    arg0, arg1 wz,wc
        if_nc   add     result, #4
                cmpr    arg0, arg1 wz
        if_z    add     result, #8
                cmpm    arg0, arg1 wz
        if_nz   add     result, #16
                test    arg0, arg1 wz
        if_nz   add     result, #32
                ret
""",
    ),
    "mb_05bit.spin2": (
        "PASM2 bit operations: BITH, BITL, BITNOT, BITZ, BITNZ.",
        """\
berry_mbox_method_1
                mov     result, #0
                bith    result, #3
                bith    result, #0
                bitl    result, #0
                bitnot  result, #3
                cmp     arg0, #0 wz
                bitz    result, #5
                bitnz   result, #6
                ret
""",
    ),
    "mb_06lane.spin2": (
        "PASM2 byte/word/nibble lane helpers: GETBYTE, SETBYTE, GETWORD, SETWORD, GETNIB.",
        """\
berry_mbox_method_1
                mov     temp0, ##$1122_3344
                getbyte result, temp0, #1
                setbyte result, #$AA, #2
                getword temp1, temp0, #1
                add     result, temp1
                mov     temp3, ##$55AA
                setword result, temp3, #0
                getnib  temp2, temp0, #3
                add     result, temp2
                ret
""",
    ),
    "mb_07mul.spin2": (
        "PASM2 multiply family: MUL, MULS, QMUL, GETQX.",
        """\
berry_mbox_method_1
                mov     result, arg0
                mul     result, arg1
                neg     temp0, #7
                muls    temp0, #3
                add     result, temp0
                qmul    arg0, arg1
                getqx   temp1
                add     result, temp1
                ret
""",
    ),
    "mb_08div.spin2": (
        "PASM2 CORDIC divide/fraction/square-root operations.",
        """\
berry_mbox_method_1
                qdiv    arg0, arg1
                getqx   result
                getqy   temp0
                add     result, temp0
                qfrac   arg0, arg1
                getqx   temp1
                xor     result, temp1
                qsqrt   arg0, #0
                getqx   temp2
                add     result, temp2
                ret
""",
    ),
    "mb_09cord.spin2": (
        "PASM2 CORDIC rotate/vector queue operations.",
        """\
berry_mbox_method_1
                qvector arg0, arg1
                getqx   result
                getqy   temp0
                add     result, temp0
                qrotate arg0, arg1
                getqx   temp1
                xor     result, temp1
                ret
""",
    ),
    "mb_10hub.spin2": (
        "PASM2 hub memory: WRBYTE/RDBYTE, WRWORD/RDWORD, WRLONG/RDLONG.",
        """\
berry_mbox_method_1
                mov     temp0, berry_mbox_mb
                add     temp0, #(24 * 4)
                wrbyte  arg0, temp0
                rdbyte  result, temp0
                add     temp0, #4
                wrword  arg1, temp0
                rdword  temp1, temp0
                add     result, temp1
                add     temp0, #4
                wrlong  arg2, temp0
                rdlong  temp2, temp0
                xor     result, temp2
                ret
""",
    ),
    "mb_11lut.spin2": (
        "PASM2 LUT memory: WRLUT and RDLUT.",
        """\
berry_mbox_method_1
                wrlut   arg0, #0
                rdlut   result, #0
                wrlut   arg1, #1
                rdlut   temp0, #1
                xor     result, temp0
                ret
""",
    ),
    "mb_12stk.spin2": (
        "PASM2 hardware stack: PUSH, POP, CALL, RET.",
        """\
berry_mbox_method_1
                mov     temp0, arg0
                push    temp0
                mov     result, #0
                pop     result
                call    #mb_12_helper
                ret

mb_12_helper
                add     result, #12
                ret
""",
    ),
    "mb_13jmp.spin2": (
        "PASM2 branches and decrement/test jumps: JMP, DJNF, TJZ, TJNZ.",
        """\
berry_mbox_method_1
                mov     result, #0
                mov     temp0, #3
mb_13_loop
                add     result, #2
                djnf    temp0, #mb_13_loop
                tjz     arg0, #mb_13_zero
                add     result, #5
                jmp     #mb_13_done
mb_13_zero
                add     result, #7
mb_13_done
                tjnz    arg1, #mb_13_add
                ret
mb_13_add
                add     result, #11
                ret
""",
    ),
    "mb_14rep.spin2": (
        "PASM2 REP block repetition.",
        """\
berry_mbox_method_1
                mov     result, #0
                rep     #1, #5
                add     result, #3
                ret
""",
    ),
    "mb_15misc.spin2": (
        "PASM2 miscellaneous helpers: ENCOD, DECOD, ONES, MERGEB, SPLITB.",
        """\
berry_mbox_method_1
                mov     temp0, #$80
                encod   result, temp0
                decod   temp1, result
                ones    temp2, temp1
                add     result, temp2
                mov     temp3, ##$0102_0304
                splitb  temp3
                mergeb  temp3
                xor     result, temp3
                ret
""",
    ),
    "mb_16time.spin2": (
        "PASM2 counter and wait operations: GETCT and WAITX.",
        """\
berry_mbox_method_1
                getct   temp0
                waitx   #10
                getct   result
                sub     result, temp0
                ret
""",
    ),
    "mb_17wide.spin2": (
        "PASM2 wide immediates and LOC: ## immediates, AUGS/AUGD expansion, LOC.",
        """\
berry_mbox_method_1
                mov     result, ##$1234_5678
                loc     pa, #mb_17_anchor
                mov     temp0, pa
                xor     result, temp0
                ret

mb_17_anchor
                long    $CAFE_BABE
""",
    ),
    "mb_18pins.spin2": (
        "PASM2 pin instruction syntax smoke test. Runtime method avoids changing pins.",
        """\
berry_mbox_method_1
                mov     result, #18
                jmp     #mb_18_done
mb_18_matrix
                dirl    #56
                dirh    #56
                outl    #56
                outh    #56
                drvl    #56
                drvh    #56
                fltl    #56
mb_18_done
                ret
""",
    ),
    "mb_19lock.spin2": (
        "PASM2 lock instructions: LOCKNEW, LOCKTRY, LOCKREL, LOCKRET.",
        """\
berry_mbox_method_1
                locknew result wc
        if_c    ret
                mov     temp0, result
                locktry temp0 wc
        if_c    lockrel temp0
                lockret temp0
                ret
""",
    ),
    "mb_20pat.spin2": (
        "PASM2 pattern/interrupt setup syntax smoke test. Runtime method leaves events untouched.",
        """\
berry_mbox_method_1
                mov     result, #20
                jmp     #mb_20_done
mb_20_matrix
                setpat  #0, #0
                pollpat wc
                pollatn wc
                waitatn
                setint1 #0
                setint2 #0
                setint3 #0
mb_20_done
                ret
""",
    ),
}


INSTRUCTION_MATRIX = """\
{{ PASM2 instruction matrix.

   This compile-only object covers a broad set of PASM2 mnemonics grouped by
   instruction family.  It is not meant to be launched by Berry; the first
   instruction parks the cog before the matrix.  The callable mb_*.spin2 files
   contain deterministic runtime checks for the safe arithmetic/logical/memory
   families.
}}

DAT
        ORG
start   jmp     #start

matrix
        mov     a, #1
        add     a, #2
        addx    a, #0
        neg     b, #1
        adds    a, b
        addsx   a, #0
        sub     a, #1
        subx    a, #0
        neg     b, #1
        subs    a, b
        subsx   a, #0
        subr    a, #10
        cmpsub  a, #3 wc
        neg     b, a
        negc    b, a
        negnc   b, a
        negz    b, a
        negnz   b, a
        abs     b

        and     a, b
        andn    a, b
        or      a, b
        xor     a, b
        not     a
        muxc    a, b
        muxnc   a, b
        muxz    a, b
        muxnz   a, b
        test    a, b wz,wc
        testb   a, #3 wz
        testbn  a, #4 wz

        shl     a, #1
        shr     a, #1
        sar     a, #1
        rol     a, #1
        ror     a, #1
        rev     a
        zerox   a, #7
        signx   a, #7

        cmp     a, b wz,wc
        cmps    a, b wz,wc
        cmpx    a, b wz,wc
        cmpsx   a, b wz,wc
        cmpr    a, b wz
        cmpm    a, b wz

        bitl    a, #0
        bith    a, #1
        bitc    a, #2
        bitnc   a, #3
        bitz    a, #4
        bitnz   a, #5
        bitrnd  a, #6
        bitnot  a, #7

        getnib  c, a, #0
        getbyte c, a, #0
        getword c, a, #0
        setbyte a, #$12, #1
        mov     c, ##$3456
        setword a, c, #1
        rolbyte a, b, #0
        rolword a, b, #0
        setq    #1
        setq2   #1
        setr    a, #0
        setd    a, #0
        sets    a, #0

        alts    a, #0
        altd    a, #0
        altb    a, #0
        altsb   a, #0
        altgb   a, #0
        splitb  a
        mergeb  a
        splitw  a
        mergew  a
        movbyts a, #%00_01_10_11

        mul     a, b
        muls    a, b
        sca     a, b
        scas    a, b
        qmul    a, b
        qdiv    a, b
        qfrac   a, b
        qsqrt   a, b
        qrotate a, b
        qvector a, b
        qlog    a
        qexp    a
        getqx   a
        getqy   b

        rdbyte  a, ptra
        rdword  a, ptra
        rdlong  a, ptra
        wrbyte  a, ptra
        wrword  a, ptra
        wrlong  a, ptra
        rdlut   a, #0
        wrlut   a, #0
        rdfast  #0, ptra
        wrfast  #0, ptra
        rfbyte  a
        rfword  a
        rflong  a
        rfvar   a
        rfvars  a
        wfbyte  a
        wfword  a
        wflong  a
        getptr  a

        push    a
        pop     a
        call    #subroutine
        calla   #subroutine
        callb   #subroutine
        callpa  a, #subroutine
        callpb  a, #subroutine
        jmp     #next_branch
next_branch
        jmprel  #0
        djnf    a, #next_branch
        tjnf    a, #next_branch
        tjz     a, #next_branch
        tjnz    a, #next_branch
        tjs     a, #next_branch
        tjns    a, #next_branch
        tjv     a, #next_branch
        ret

subroutine
        reti1
        reti2
        reti3
        ret

        rep     #1, #1
        nop
        skip    #%1
        skipf   #%1
        execf   a

        getct   a
        waitx   #1
        addct1  a, #1
        addct2  a, #1
        addct3  a, #1
        waitct1
        waitct2
        waitct3
        pollct1 wc
        pollct2 wc
        pollct3 wc

        hubset  #0
        cogid   a
        cogstop a
        coginit a, b wc
        locknew a wc
        lockret a
        locktry a wc
        lockrel a
        cogatn  a
        pollatn wc
        waitatn

        wrpin   a, #56
        wxpin   a, #56
        wypin   a, #56
        akpin   #56
        rdpin   a, #56
        rqpin   a, #56
        testp   #56 wz
        dirl    #56
        dirh    #56
        dirc    #56
        dirnc   #56
        dirz    #56
        dirnz   #56
        dirrnd  #56
        dirnot  #56
        outl    #56
        outh    #56
        outc    #56
        outnc   #56
        outz    #56
        outnz   #56
        outrnd  #56
        outnot  #56
        drvl    #56
        drvh    #56
        drvc    #56
        drvnc   #56
        drvz    #56
        drvnz   #56
        drvrnd  #56
        drvnot  #56
        fltl    #56
        flth    #56
        fltc    #56
        fltnc   #56
        fltz    #56
        fltnz   #56
        fltrnd  #56
        fltnot  #56

        xinit   a, b
        xzero   a, b
        xcont   a, b
        xstop
        waitxmt
        waitxfi
        waitxro
        waitxrl
        pollxmt wc
        pollxfi wc
        pollxro wc
        pollxrl wc

        setpat  a, b
        pollpat wc
        waitpat
        setint1 #0
        setint2 #0
        setint3 #0
        allowi
        stalli
        trgint1
        trgint2
        trgint3
        niksint1
        niksint2
        niksint3

a       res     1
b       res     1
c       res     1
"""


def mailbox_file(name: str, description: str, method: str) -> str:
    return f"""\
{{ {description}

   Callable from Berry with:

     'make spin2' writes an uppercase 8.3 filename to spin2/build/MANIFEST.TXT.
     handle = spin2.start("<manifest binary name>")
     print(spin2.call(handle, 1, arg0, arg1, arg2))
     spin2.stop(handle)

   Method 0 is the mailbox service entry.  Method 1 is the deterministic test
   implemented below.  The shared service loads argv[0..7] into arg0..arg7 and
   writes the result register back to mailbox long 11.
}}

DAT
                long    2
                long    berry_mbox_service
                long    berry_mbox_method_1

#include "common/berry_mbox_service.spin2h"

{method}
#include "common/berry_mbox_regs.spin2h"
"""


def main() -> int:
    def emit(path: Path, text: str) -> None:
        path.write_text(text.rstrip() + "\n", encoding="utf-8")

    COMMON.mkdir(parents=True, exist_ok=True)
    emit(COMMON / "berry_mbox_service.spin2h", COMMON_SERVICE)
    emit(COMMON / "berry_mbox_regs.spin2h", COMMON_REGS)

    for name, text in FEATURES.items():
        emit(SPIN2 / name, text)

    for name, (description, method) in MAILBOX_METHODS.items():
        emit(SPIN2 / name, mailbox_file(name, description, method))

    emit(SPIN2 / "p2instmx.spin2", INSTRUCTION_MATRIX)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
