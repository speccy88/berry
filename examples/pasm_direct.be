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
print("arbitrary blob policy:", p2.asm.capability("arbitrary_blob_policy"))
print("fixture call policy:", p2.asm.capability("fixture_call_policy"))
print("function bridge policy:", p2.asm.capability("function_bridge_policy"))
print("inline assembler policy:", caps["inline_assembler_policy"])
print("unsafe gate:", caps["unsafe_gate"], "default:", caps["unsafe_default"])
print("ABI status:", p2.asm.abi_value("status"))
print("ABI argument:", p2.asm.abi_value("argument"))
print("policy audit ok:", p2.asm.audit_ok(), "problems:", p2.asm.audit_problems().size())

var launch = p2.asm.launch_probe()
print("marker fixture ok:", launch["ok"])
print("marker seen:", launch["marker_seen"])
print("cog seen matches:", launch["cog_seen_matches"])
print("stopped:", launch["stopped"])

var fixture = p2.asm.fixture_add(40, 2)
print("fixture add ok:", fixture["ok"])
print("fixture add result:", fixture["result"])
print("fixture cog seen matches:", fixture["cog_seen_matches"])
print("fixture stopped:", fixture["stopped"])

var sub = p2.asm.fixture_call("sub", 50, 8)
print("fixture sub result:", sub["result"])
var xor = p2.asm.fixture_call("xor", 85, 15)
print("fixture xor result:", xor["result"])
print("pasm direct done")
