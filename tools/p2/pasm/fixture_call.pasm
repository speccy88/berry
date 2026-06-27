{
P2 PASM fixture used by the Berry p2.asm fixture-call bridge.

Mailbox layout in Hub RAM, passed as PTRA by _cogstart_PASM:
  long 0: status, written as 1 when complete
  long 1: operation code, 1 add, 2 sub, 3 xor, 4 and, 5 or
  long 2: arg0
  long 3: arg1
  long 4: result
  long 5: cog id seen by the fixture
}

dat     org     0
entry
        mov     ptr, ptra
        add     ptr, #4
        rdlong  op, ptr
        add     ptr, #4
        rdlong  lhs, ptr
        add     ptr, #4
        rdlong  rhs, ptr

        cmp     op, #2 wz
  if_z  sub     lhs, rhs
        cmp     op, #3 wz
  if_z  xor     lhs, rhs
        cmp     op, #4 wz
  if_z  and     lhs, rhs
        cmp     op, #5 wz
  if_z  or      lhs, rhs
        cmp     op, #1 wz
  if_z  add     lhs, rhs

        add     ptr, #4
        wrlong  lhs, ptr
        cogid   cid
        add     ptr, #4
        wrlong  cid, ptr
        mov     ptr, ptra
        mov     lhs, #1
        wrlong  lhs, ptr
.park   jmp     #.park

ptr     long    0
op      long    0
lhs     long    0
rhs     long    0
cid     long    0
