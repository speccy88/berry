# Hardware smoke for source-backed child-VM cog handles.
# Expected on the current Catalina XMM profile: unsupported fast-fail.

import p2

source = "import p2\n" \
         "def blinker(pin, ms)\n" \
         "  p2.low(pin)\n" \
         "  while true\n" \
         "    p2.toggle(pin)\n" \
         "    p2.waitms(ms)\n" \
         "  end\n" \
         "end\n"

print("cap", p2.cog.capabilities()["spawn_source"], p2.cog.capabilities()["isolated_child_vm_cog"], p2.cog.capabilities()["berry_closure"])
p2.cog.spawn_source(source, "blinker", 38, 250)
