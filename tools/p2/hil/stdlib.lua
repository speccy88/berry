-- Bounded host-transport harness. Berry assertions execute on the P2 only.
-- This script performs no GPIO/I2C/SPI/storage/cog/sleep operation.
io.stdout:setvbuf("no")
local function read_chunk()
  local data = receive(1024, 500, "")
  if #data > 0 then print("UART_RX_HEX " .. (data:gsub(".", function(c) return string.format("%02x", string.byte(c)) end))) end
  return data
end
local function wait_text(expected, seconds)
  local data = ""
  for _ = 1, seconds * 2 do
    data = data .. read_chunk()
    if data:find(expected, 1, true) then return data end
  end
  error("Expected response missing: " .. expected)
end
local function enter(lines)
  for i, line in ipairs(lines) do
    send(line .. "\r")
    wait_text(i == #lines and "berry> " or "...> ", 15)
  end
end
wait_text("berry> ", 45)

-- Same assertion descriptor as cases/stdlib_safe_v3.be, REPL-safe form.
local stdlib = {
"def __lcv3_stdlib()", "def expect_error(code, kind)", "var caught=false", "try", "compile(code)", "except .. as e, m", "caught=true", "assert(e==kind)", "end", "assert(caught)", "end",
"import string", "assert(string.find('012345','23')==2)", "assert(string.find('012345','',6)==6)", "assert(string.find('012345','23',3)==-1)", "assert(string.count('121314','1')==3)", "assert(string.count('012345','')==7)", "assert(string.split('a b c d',' ',2)==['a','b','c d'])", "assert(string.replace('hello','ll','')=='heo')", "assert(string.startswith('qwerty','QW',true))", "assert(string.endswith('qwerty','TY',true))", "assert(string.format('%i%%%i',12,13)=='12%13')", "print('LCV3_CASE string')",
"import time", "var t0=time.clock()", "assert(type(t0)=='real' && t0>=0)", "var epoch0=time.dump(0)", "assert(epoch0['epoch']==0 && epoch0['month']>=1 && epoch0['month']<=12)", "assert(time.dump()==nil)", "assert(time.dump('bad')==nil)", "assert(type(time.time())=='int')", "print('LCV3_CASE time')",
"import global", "assert(global.contains('LCV3_absent')==false)", "global.LCV3_value=42", "assert(global.member('LCV3_value')==42)", "assert(global().find('LCV3_value')!=nil)", "global.undef('LCV3_value')", "assert(!global.contains('LCV3_value'))", "assert(global.contains(7)==nil)", "print('LCV3_CASE global')",
"import sys", "var p=sys.path()", "var n=p.size()", "assert(sys.path_add('/__lcv3_nonexistent__')==true)", "assert(sys.path().size()==n+1)", "p=sys.path()", "p.pop()", "assert(sys.path().size()==n)", "var sys_bad=false", "try", "sys.path_add(7)", "except 'type_error'", "sys_bad=true", "end", "assert(sys_bad)", "print('LCV3_CASE sys')",
"import introspect", "assert(introspect.contains(string,'format'))", "assert(!introspect.contains(string,'__lcv3_missing__'))", "assert(introspect.get(string,'format')==string.format)", "assert(introspect.get(string,'__lcv3_missing__')==nil)", "assert(introspect.name(string)=='string')", "assert(introspect.module('string')!=nil)", "assert(introspect.toptr(0)!=nil)", "assert(introspect.fromptr(0)==nil)", "print('LCV3_CASE introspect')",
"import undefined", "assert(type(undefined)=='module')", "var undefined_error=false", "try", "undefined.__lcv3_missing__", "except 'attribute_error'", "undefined_error=true", "end", "assert(undefined_error)", "print('LCV3_CASE undefined')",
"import debug", "assert(type(debug.calldepth())=='int')", "assert(debug.calldepth()>=1)", "assert(type(debug.top())=='int')", "assert(debug.caller(99999)==nil)", "assert(debug.gcdebug()==false)", "assert(debug.gcdebug(false)==false)", "print('LCV3_CASE debug')",
"import strict", "assert(strict==nil || type(strict)=='module')", "expect_error('var a,b def f() a b end','syntax_error')", "expect_error('return LCV3_missing_global','syntax_error')", "print('LCV3_CASE strict')", "end" }
enter(stdlib)
send("__lcv3_stdlib(); print(\"LCV3_HIL_OK\", \"stdlib\", 8)\r")
wait_text("LCV3_HIL_OK stdlib 8", 30)

-- P2-only, informational and bounded: no waits, pin/bus, storage, or cog lifecycle.
local p2_info = {"def __lcv3_p2_info()", "import p2", "assert(type(p2.clock.freq())=='int' && p2.clock.freq()>0)", "assert(type(p2.clock.mode())=='int')", "assert(type(p2.clock.cnt())=='int')", "assert(type(p2.clock.cnth())=='int')", "assert(p2.math.isqrt(81)==9)", "assert(type(p2.math.muldiv64(7,6,2))=='int')", "assert(type(p2.math.rev(1))=='int')", "assert(type(p2.math.encod(1))=='int')", "assert(type(p2.rng.rnd())=='int')", "assert(type(p2.cog.id())=='int')", "print('LCV3_CASE p2_info')", "end"}
enter(p2_info)
send("__lcv3_p2_info(); print(\"LCV3_HIL_OK\", \"p2_info\", 1)\r")
wait_text("LCV3_HIL_OK p2_info 1", 30)
print("LCV3_HIL_SUITE_OK 9")
