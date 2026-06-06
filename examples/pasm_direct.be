# Safe PASM-adjacent intrinsic demo for the P2 port.
# This does not enable arbitrary assembly; it uses the guarded p2.asm facade.

import p2

print("counter before:", p2.asm.getct())
p2.asm.waitx(1000)
print("counter after:", p2.asm.getct())
print("random:", p2.asm.getrnd())
print("hubset function exposed:", type(p2.asm.hubset))
