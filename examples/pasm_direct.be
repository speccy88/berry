# Safe PASM-adjacent intrinsic demo for the P2 port.
# This does not enable arbitrary assembly; it uses the guarded p2.asm facade.

import p2

print("counter before:", p2.asm.getct())
p2.asm.waitx(1000)
print("counter after:", p2.asm.getct())
print("random:", p2.asm.getrnd())
print("hubset function exposed:", type(p2.asm.hubset))

var caps = p2.asm.capabilities()
var abi = p2.asm.abi()

print("launch policy:", caps["launch_policy"])
print("raw cognew policy:", caps["raw_cognew_policy"])
print("arbitrary blob policy:", caps["arbitrary_blob_policy"])
print("function bridge policy:", caps["function_bridge_policy"])
print("inline assembler policy:", caps["inline_assembler_policy"])
print("unsafe gate:", caps["unsafe_gate"], "default:", caps["unsafe_default"])
print("ABI status:", abi["status"])
print("ABI argument:", abi["argument"])
print("policy audit ok:", p2.asm.audit_ok(), "problems:", p2.asm.audit_problems().size())

var launch = p2.asm.launch_probe()
print("marker fixture ok:", launch["ok"])
print("marker seen:", launch["marker_seen"])
print("cog seen matches:", launch["cog_seen_matches"])
print("stopped:", launch["stopped"])
print("pasm direct done")
